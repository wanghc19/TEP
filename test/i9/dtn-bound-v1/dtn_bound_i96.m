function result = dtn_bound_i96(config,native,output_dir)
%DTN_BOUND_I96 I9.6a positive-definite source-reconstruction spectral-distance estimate.
% Purpose: For the frozen I9.5b fine-Q12 FEM+DtN candidate k, evaluate the
%   design-9-6a bound dist(mu,sigma(A(beta))) <= R_mu (mu = k^2, shift s = mu,
%   s-dtn-bound Theorem 2) on the control and main rectangle/Fourier levels,
%   run the first-batch reliable-integration gate, and deliver R_mu, R_k,
%   every term, the numerical identity and the complete cost.
% Input: config = dtn_bound_i96_config(mode); native = [] (fixed-frequency
%   reconstruction by the adapter in this file, identity
%   FIXED_FREQUENCY_RECONSTRUCTION) or an explicit native struct of the same
%   schema (identity EXPLICIT_SAVED_FIELD); output_dir = new run directory.
% Output: result.json, integration.json, native.mat, modes.csv, cells.csv,
%   levels.csv, gate.csv, progress.json, figures/*.png and the result struct.
% Main algorithm:
%   1. adapter: I9.5b joint mesh and three templates, one complete DtN/centre
%      response at the frozen k, the centre branch closest to zero, recovery of
%      the centre and 16 lead cells per side (inner/outer walls P^(j-1)g, P^j g),
%      I9.5b qualification gates, unweighted L2 normalisation, P^j g tails,
%      eq. (27), 33-point curve deviations and the raw QZ blocks;
%   2. per level, first-batch gate: reference-triangle bisection of the batch
%      elements, Bernstein control-net boxes, analytic chord tube of the true
%      curve, interval widths of source/field moments and direct defects per
%      depth, tightening fit and closure prediction against b = 1e-8 U0,
%      2e6 leaves per template, depth 30 and the soft limit;
%   3. per level, ordinary integration: exact Sutherland-Hodgman clipping of
%      straight triangles by the rectangle grid (3x3 Gauss on full rectangles,
%      Dunavant degree 8 on fan pieces), signed chord->arc slivers of curved P2
%      elements and signed P2-edge->true-curve material slivers; per x-strip Q1
%      source and Q2 field moments of all cells of one template, direct
%      |f-f_R|^2, |u-v_R|^2, analytic single-rectangle y-Fourier factors with
%      the FFT as summation, Parseval column tails;
%      (steps 3-4 run in Fourier-mode blocks; each block repeats the
%      deterministic projection and keeps only its modes' arrays);
%   4. per mode a_m^2 = s+q_m^2: exact Yukawa sweeps of -w''+a_m^2 w = f_m for
%      piecewise affine sources, closed-form interior values, 12-point Gauss
%      norms, exterior tails; assembly of eps0, delta_u, E_v, D0, R_mu, R_k.
% Based on: test/i9/fem-dtn-v1/fem_dtn_i95b.m (curve, joint mesh and repair,
%   templates, cell elimination, QZ/DtN, one-frequency response, recovery
%   checks, P2 algebra, JSON/RSS helpers copied; LOCAL_dtn additionally
%   returns the raw ordered QZ blocks).
% Main changes: no root finding; 16 lead cells per side; new source
%   reconstruction integration, gate, Fourier-Yukawa evaluation and assembly.
% Numerical goal: R_mu, R_k of s-dtn-bound eqs. (18a)/(25) per level;
%   ORDINARY_ESTIMATE always, EXACT_ARITHMETIC_UPPER_BOUND only if the gate
%   supports closure of every evaluation-uncertainty budget.
  if nargin < 2, native = []; end
  entry_utc = char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSSSSSXXX'));
  started = tic;
  if ~isfolder(output_dir), mkdir(output_dir); end
  if ~isfolder(fullfile(output_dir,'figures')), mkdir(fullfile(output_dir,'figures')); end
  maxNumCompThreads(config.resources.threads);
  ctx = struct('output_dir',output_dir,'started',started,'config',config, ...
    'progress_path',fullfile(output_dir,'progress.json'));
  ledger = LOCAL_ledger();
  LOCAL_json(fullfile(output_dir,'config.json'),config);
  environment = struct('matlab_version',version,'platform',computer, ...
    'max_threads',maxNumCompThreads,'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS'), ...
    'entry_utc',entry_utc,'pid',feature('getpid'));
  fprintf('ENTRY %s mode=%s threads=%d\n',entry_utc,config.mode,maxNumCompThreads);
  result = struct('schema',config.schema,'mode',config.mode,'k',config.k,'mu',config.k^2, ...
    'final_status','','final_reason','','input_identity','','native',struct(), ...
    'constants',struct(),'selftest',struct(),'levels',struct([]),'environment',environment);
  stage = 'selftest'; levels = struct([]); gates = struct([]); modes_all = struct([]);
  cells_all = struct([]); integration = struct('levels',struct([]));
  try
    % --- stage 0: deterministic self-tests of the new quadrature/recursion code ---
    timer = tic;
    result.selftest = LOCAL_selftest(config);
    ledger.selftest = toc(timer);
    fprintf('STAGE selftest pass=%d (%.2fs)\n',result.selftest.pass,ledger.selftest);
    assert(result.selftest.pass,'i96:SelfTest','Self-test failed: %s',result.selftest.reason);
    % --- stage 1: native field (fixed-frequency adapter or explicit input) ---
    stage = 'native'; LOCAL_progress(ctx,'native',NaN);
    timer = tic;
    if isempty(native)
      native = LOCAL_adapter(config);
    else
      native = LOCAL_explicit_native(config,native);
    end
    ledger.native_adapter = toc(timer);
    result.native = native.summary; result.input_identity = native.identity;
    fprintf('STAGE native %s qualified=%d lambda=%.3e centre_residual=%.3e cells=%d (%.2fs)\n', ...
      native.identity,native.qualified,native.summary.lambda,native.summary.center_residual, ...
      numel(native.cells),ledger.native_adapter);
    timer = tic; LOCAL_save_native(output_dir,native); ledger.save = ledger.save+toc(timer);
    % the raw recovery/QZ blocks are saved; drop them before the level arrays
    native.recovery = struct(); native.qz = struct();
    if ~native.qualified && ~config.continue_on_mismatch
      result.final_status = 'NATIVE_FIELD_MISMATCH'; result.final_reason = native.summary.reason;
      result.timing = LOCAL_ledger_close(ledger,toc(started));
      LOCAL_json(fullfile(output_dir,'result.json'),result);
      LOCAL_progress(ctx,'done',0);
      fprintf('COMPLETE %s: %s\n',result.final_status,result.final_reason);
      return
    end
    common = LOCAL_constants(config,native);
    result.constants = common;
    level_seconds = NaN;
    for L = 1:numel(config.levels)
      lev = config.levels(L);
      % --- stage 2: first-batch reliable-integration gate of this level ---
      stage = ['gate:',lev.name];
      LOCAL_progress(ctx,stage,LOCAL_remaining(config,L,level_seconds,0));
      timer = tic;
      gate = LOCAL_gate(ctx,native,lev,common);
      ledger.gate = ledger.gate+toc(timer);
      gates = LOCAL_append(gates,gate);
      fprintf('STAGE gate %s: closure_supported=%d (%s) %.2fs\n',lev.name, ...
        gate.closure_supported,gate.reason,toc(timer));
      % soft-limit prediction before a further full level (design 6)
      predicted = LOCAL_remaining(config,L,level_seconds,1);
      if L>1 && toc(started)+predicted>config.resources.soft_seconds
        level = LOCAL_skipped_level(lev,common,gate,sprintf( ...
          'PREDICTED_SOFT_LIMIT: elapsed %.0fs + predicted %.0fs > %.0fs',toc(started), ...
          predicted,config.resources.soft_seconds));
        levels = LOCAL_append(levels,level);
        continue
      end
      if ~gate.closure_supported && ~config.ordinary_after_gate_failure
        levels = LOCAL_append(levels,LOCAL_skipped_level(lev,common,gate,'GATE_FAILED_NO_ORDINARY'));
        continue
      end
      level_timer = tic;
      % --- stage 3+4: ordinary projection and Fourier moments, then Yukawa
      % sweeps and norms, in Fourier-mode blocks (memory) ---
      stage = ['projection+yukawa:',lev.name];
      LOCAL_progress(ctx,stage,predicted);
      [proj,norms,mode_table,cell_norms] = LOCAL_level(ctx,native,lev,common);
      ledger.projection = ledger.projection+proj.seconds;
      ledger.yukawa_norms = ledger.yukawa_norms+norms.seconds;
      fprintf('STAGE level %s: %d points/pass, %d mode blocks, mass %.15f, projection %.2fs, yukawa %.2fs\n', ...
        lev.name,proj.checks.points,lev.mode_blocks,proj.totals.mass,proj.seconds,norms.seconds);
      timer = tic;
      level = LOCAL_combine(config,lev,common,proj,norms,gate);
      level.seconds = toc(level_timer);
      levels = LOCAL_append(levels,level);
      modes_all = LOCAL_append(modes_all,struct('level',lev.name,'table',mode_table));
      cells_all = LOCAL_append(cells_all,struct('level',lev.name, ...
        'table',LOCAL_cell_table(native,proj,cell_norms)));
      integration.levels = LOCAL_append(integration.levels,struct('name',lev.name, ...
        'checks',proj.checks,'templates',proj.templates,'negative',level.negative_records));
      ledger.assembly = ledger.assembly+toc(timer);
      level_seconds = level.seconds;
      fprintf(['LEVEL %s: D0=%.6e delta_u=%.3e E_v=%.3e eps0=%.3e (cR*ER=%.3e Ey/bM=%.3e) ', ...
        'R_mu=%.3e R_k=%.3e [%s]\n'],lev.name,level.ordinary.D0,level.ordinary.delta_u, ...
        level.ordinary.E_v,level.ordinary.eps0,level.ordinary.c_R_E_R,level.ordinary.E_y_over_b_M, ...
        level.ordinary.R_mu,level.ordinary.R_k,level.ordinary.resolution_status);
      clear proj
      timer = tic; LOCAL_partial(ctx,levels,gates,ledger); ledger.save = ledger.save+toc(timer);
    end
    % --- stage 5: final status ---
    stage = 'final_status';
    result.levels = levels; result.gates = LOCAL_gate_summaries(gates);
    [result.final_status,result.final_reason,result.status_detail] = LOCAL_final(config,native,levels,gates);
    % --- stage 6: figures (MATLAB native export) ---
    stage = 'figures'; LOCAL_progress(ctx,stage,config.resources.save_estimate_seconds);
    timer = tic;
    result.figures = LOCAL_figures(ctx,native,levels,gates,modes_all);
    ledger.figures = toc(timer);
    % --- stage 7: machine outputs ---
    stage = 'save'; timer = tic;
    LOCAL_write_modes(fullfile(output_dir,'modes.csv'),modes_all);
    LOCAL_write_cells(fullfile(output_dir,'cells.csv'),cells_all);
    LOCAL_write_levels(fullfile(output_dir,'levels.csv'),levels);
    LOCAL_write_gate(fullfile(output_dir,'gate.csv'),gates);
    integration.gates = gates; integration.budget_relative = config.budget_relative;
    integration.U0 = common.U0; integration.b = common.b;
    LOCAL_json(fullfile(output_dir,'integration.json'),integration);
    ledger.save = ledger.save+toc(timer);
    result.timing = LOCAL_ledger_close(ledger,toc(started));
    result.peak_rss_matlab_bytes = LOCAL_rss();
    LOCAL_json(fullfile(output_dir,'result.json'),result);
    LOCAL_progress(ctx,'done',0);
    fprintf('COMPLETE %s matlab %.2fs\n',result.final_status,toc(started));
  catch error_object
    status = 'EXCEPTION';
    if strcmp(error_object.identifier,'i96:ResourceStop'), status = 'RESOURCE_OR_INTEGRATION_UNRESOLVED'; end
    failure = struct('stage',stage,'status',status,'identifier',error_object.identifier, ...
      'message',error_object.message,'report',getReport(error_object,'extended','hyperlinks','off'), ...
      'elapsed_seconds',toc(started),'timing',LOCAL_ledger_close(ledger,toc(started)));
    failure.stack = error_object.stack;
    LOCAL_json(fullfile(output_dir,'failure.json'),failure);
    LOCAL_partial(ctx,levels,gates,ledger);
    rethrow(error_object);
  end
end

%% ==================== Fixed-frequency native field adapter ====================
% Same-configuration reconstruction at the frozen k: no root search, no new N.
function native = LOCAL_adapter(config)
  cfg = config.native; k = config.k; mu = k^2; nc = config.field.cells_per_side;
  native = struct('identity','FIXED_FREQUENCY_RECONSTRUCTION','k',k,'mu',mu, ...
    'qualified',false,'templates',struct(),'cells',struct([]),'summary',struct(), ...
    'U0',NaN,'scale',NaN,'phase',NaN,'recovery',struct(),'qz',struct(),'tails',struct(), ...
    'curve_deviation',struct(),'times',struct());
  summary = struct('reason','','geometry_status','','lambda',NaN,'center_residual',NaN);
  timer = tic;
  [mesh,geometry] = LOCAL_mesh(config,cfg);
  native.times.mesh = toc(timer);
  summary.geometry_status = geometry.status; summary.triangles = size(mesh.triangles,1);
  summary.p2_nodes = size(mesh.p2_points,1); summary.det_min = geometry.det_min;
  summary.det_ratio_max = geometry.det_ratio_max; summary.curved_elements = geometry.curved_elements;
  summary.mesh_structural_checks_pass = geometry.mesh_structural_checks_pass;
  if ~strcmp(geometry.status,'PASS')
    summary.reason = ['GEOMETRY: ',geometry.reason]; native.summary = summary; return
  end
  timer = tic;
  templates = LOCAL_templates(config,cfg,mesh);
  native.times.assembly = toc(timer);
  summary.matrix_checks_pass = templates.checks.pass;
  summary.dimensions = templates.dimensions;
  % --- one complete response at the frozen k (raw QZ blocks kept) ---
  timer = tic;
  [res,ext] = LOCAL_evaluate(config,templates,k,true);
  native.times.response = toc(timer);
  summary.response_valid = res.valid;
  summary.reasons = {res.reason_left,res.reason_right,res.reason_center};
  if ~res.valid
    summary.reason = ['RESPONSE: ',strjoin(summary.reasons,' | ')]; native.summary = summary; return
  end
  [~,index] = min(abs(res.lambda));
  summary.branch_index = index; summary.lambda = res.lambda(index);
  summary.target_gap = LOCAL_gap(res.lambda,index); summary.H_norm = res.H_norm;
  [~,near] = sort(abs(res.lambda)); summary.nearest_lambda = res.lambda(near(1:min(5,end)))';
  summary.dtn = struct('left',res.dtn.left,'right',res.dtn.right);
  summary.cell = res.cell;
  % --- recovery: centre, then 16 lead cells per side (I9.5b LOCAL_recover) ---
  timer = tic;
  n = templates.n; beta = templates.beta; dl = config.delivery;
  y = res.V(:,index); g = templates.wall_chol\y;
  c = templates.center; Ec = ext.center.E;
  u = complex(zeros(numel(c.free),1)); u(c.wall) = g; u(c.interior) = Ec*g;
  Ac = c.K-mu*c.M; Ku = c.K*u; Mu = c.M*u; gl = g(1:n); gr = g(n+1:end);
  DL = ext.left.D; DR = ext.right.D;
  r = Ku-mu*Mu; r(c.wall) = r(c.wall)+[DL*gl;DR*gr];
  denominator = norm(Ku)+abs(mu)*norm(Mu)+norm(DL*gl)+norm(DR*gr);
  summary.center_residual = norm(r)/denominator;
  summary.center_recovery_residual = norm(Ac(c.interior,:)*u)/(norm(Ac(c.interior,c.interior)* ...
    u(c.interior))+norm(Ac(c.interior,c.wall)*g));
  full_c = c.Qqp*u;
  summary.center_qp = norm(full_c(c.top)-exp(1i*beta)*full_c(c.bottom))/norm(full_c);
  center_load = Ac(c.wall,:)*u;
  cells = struct('index',0,'template','center','offset',0,'coef',full_c);
  sides = struct([]); traces_all = struct();
  for side = {'left','right'}
    name = side{1}; t = templates.(name); Lx = ext.(name);
    if strcmp(name,'left'), g0 = gl; wall_load = center_load(1:n); sgn = -1;
    else, g0 = gr; wall_load = center_load(n+1:end); sgn = 1; end
    At = t.K-mu*t.M; S00 = Lx.S(1:n,1:n); S01 = Lx.S(1:n,n+1:end);
    S10 = Lx.S(n+1:end,1:n); S11 = Lx.S(n+1:end,n+1:end);
    traces = complex(zeros(n,nc+1)); traces(:,1) = g0;
    for j = 1:nc, traces(:,j+1) = Lx.Pout*traces(:,j); end
    recovery = zeros(1,nc); balance = zeros(1,nc); continuity = zeros(1,nc); qp = zeros(1,nc);
    fields = cell(1,nc);
    x1 = t.xy(:,1); wall0 = sgn*0.5; wall1 = wall0+sgn;
    p = find(abs(x1-wall1)<1e-11); q = find(abs(x1-wall0)<1e-11);
    [~,ap] = sort(t.xy(p,2)); [~,aq] = sort(t.xy(q,2));
    cw_nodes = find(abs(c.xy(:,1)-wall0)<1e-11); [~,acw] = sort(c.xy(cw_nodes,2));
    for j = 1:nc
      v = complex(zeros(numel(t.free),1)); v(t.wall) = [traces(:,j);traces(:,j+1)];
      v(t.interior) = Lx.E*[traces(:,j);traces(:,j+1)];
      recovery(j) = norm(At(t.interior,:)*v)/(norm(At(t.interior,t.interior)*v(t.interior))+ ...
        norm(At(t.interior,t.wall)*v(t.wall)));
      fields{j} = t.Qqp*v;
      qp(j) = norm(fields{j}(t.top)-exp(1i*beta)*fields{j}(t.bottom))/max(norm(fields{j}),realmin);
      if j==1
        lead_load = S00*traces(:,1)+S01*traces(:,2);
        balance(j) = norm(wall_load+lead_load)/(norm(wall_load)+norm(lead_load));
        continuity(j) = norm(full_c(cw_nodes(acw))-fields{1}(q(aq)))/max(norm(full_c(cw_nodes(acw))),realmin);
      else
        prev = S10*traces(:,j-1)+S11*traces(:,j); next = S00*traces(:,j)+S01*traces(:,j+1);
        balance(j) = norm(prev+next)/(norm(prev)+norm(next));
        continuity(j) = norm(fields{j-1}(p(ap))-fields{j}(q(aq)))/max(norm(fields{j-1}(p(ap))),realmin);
      end
      cells(end+1) = struct('index',sgn*j,'template',name,'offset',sgn*(j-1), ...
        'coef',fields{j}); %#ok<AGROW>
    end
    sides = LOCAL_append(sides,struct('side',name,'recovery_residual',recovery, ...
      'load_balance',balance,'value_continuity',continuity,'qp_defect',qp, ...
      'spectral_radius',max(abs(Lx.multipliers)),'unit_gap_min',res.dtn.(name).unit_gap_min, ...
      'stable_count',res.dtn.(name).stable_count,'z0_rcond',res.dtn.(name).z0_rcond, ...
      'riccati',res.dtn.(name).riccati,'invariance',res.dtn.(name).invariance, ...
      'dtn_hermitian_defect',res.dtn.(name).hermitian_defect));
    traces_all.(name) = traces;
  end
  summary.sides = sides;
  % --- unweighted L2 normalisation over the (2N+1)-cell box and phase ---
  names = {'left','center','right'}; M1 = struct(); inclusion = struct();
  for j = 1:3
    t = templates.(names{j});
    [~,M1.(names{j})] = LOCAL_assemble(t.xy,t.tri6,ones(size(t.tri6,1),1),templates.quadrature_order);
  end
  mass = zeros(1,numel(cells));
  for j = 1:numel(cells)
    mass(j) = real(cells(j).coef'*M1.(cells(j).template)*cells(j).coef);
  end
  scale = 1/sqrt(sum(mass));
  [~,at] = max(abs(full_c)); phase = conj(full_c(at))/abs(full_c(at));
  for j = 1:numel(cells), cells(j).coef = cells(j).coef*scale*phase; end
  mass = mass*scale^2;
  native.scale = scale; native.phase = phase; native.cells = cells;
  native.U0 = sqrt(sum(mass))*(1-1e-12);
  summary.cell_index = [cells.index]; summary.cell_mass = mass;
  % --- qualification (I9.5b root/delivery gates, all 16 cells per side) ---
  gates = struct('dtn_valid',res.valid, ...
    'stable_count_complete',sides(1).stable_count==n && sides(2).stable_count==n, ...
    'eig_abs',abs(summary.lambda)<=config.root.eig_abs, ...
    'isolated_gap',summary.target_gap>=config.root.gap_factor*max(1,res.H_norm), ...
    'center_residual',summary.center_residual<=config.root.center_residual, ...
    'center_recovery',summary.center_recovery_residual<=dl.recovery_residual, ...
    'center_qp',summary.center_qp<=dl.qp, ...
    'wall_order',templates.checks.left.wall_pairing && templates.checks.center.wall_pairing && ...
      templates.checks.right.wall_pairing, ...
    'matrix_checks',templates.checks.pass);
  for j = 1:2
    s = sides(j);
    gates.([s.side,'_recovery']) = max(s.recovery_residual)<=dl.recovery_residual;
    gates.([s.side,'_continuity']) = max(s.value_continuity)<=dl.continuity;
    gates.([s.side,'_qp']) = max(s.qp_defect)<=dl.qp;
    gates.([s.side,'_balance']) = max(s.load_balance)<=dl.load_balance;
  end
  ref = config.native_reference;
  summary.identity_diagnostics = struct('lambda_reference',ref.lambda, ...
    'lambda_difference',summary.lambda-ref.lambda, ...
    'dims_match_reference',isequal(templates.dimensions.free_dofs,ref.free_dofs) && ...
      templates.n==ref.wall_dofs && summary.triangles==ref.triangles && summary.p2_nodes==ref.p2_nodes);
  summary.gates = gates;
  values = struct2cell(gates); native.qualified = all([values{:}]);
  if ~native.qualified
    f = fieldnames(gates); summary.reason = ['QUALIFICATION: ',strjoin(f(~[values{:}])',',')];
  end
  % --- tails: P^j g norms, cell masses, eq. (27) with Euclidean 2-norms ---
  for j = 1:2
    name = sides(j).side; t = templates.(name); Lx = ext.(name);
    traces = traces_all.(name)*scale*phase;
    nI = numel(t.interior); Bc = complex(zeros(numel(t.free),2*n));
    Bc(t.wall,:) = eye(2*n); Bc(t.interior,:) = Lx.E;
    Bfull = t.Qqp*Bc; Gcell = Bfull'*(M1.(name)*Bfull); Gcell = (Gcell+Gcell')/2;
    Pn = Lx.Pout; Gs = [eye(n);Pn]'*Gcell*[eye(n);Pn]; Gs = (Gs+Gs')/2;
    power = eye(n); norms_r = zeros(1,config.field.tail_power_max+1); gamma = NaN; np = NaN;
    for r = 0:config.field.tail_power_max
      norms_r(r+1) = norm(power);
      if r>0 && norms_r(r+1)<1, gamma = norms_r(r+1); np = r; break, end
      power = Pn*power;
    end
    tail27 = NaN;
    if ~isnan(gamma)
      tail27 = norm(Gs)*sum(norms_r(1:np).^2)/(1-gamma^2)*norm(traces(:,nc+1))^2;
    end
    side_mass = mass([cells.index]==0 | sign([cells.index])==2*j-3);
    idx = abs([cells.index]); sel = sign([cells.index])==2*j-3;
    [~,order] = sort(idx(sel)); lead_mass = mass(sel); lead_mass = lead_mass(order);
    native.tails.(name) = struct('trace_norms',vecnorm(traces),'cell_mass',lead_mass, ...
      'last_two_mass',sum(lead_mass(end-1:end)),'power_norms',norms_r(1:max(1,min(end,np+1))), ...
      'gamma',gamma,'n_power',np,'G_norm',norm(Gs),'eq27_bound',tail27, ...
      'spectral_radius',max(abs(Lx.multipliers)),'side_mass_with_center',sum(side_mass));
  end
  summary.tails = native.tails;
  % --- templates for integration (geometry, material, interface edges) ---
  nv = size(mesh.points,1); exact = LOCAL_exact_areas(config);
  for j = 1:3
    name = names{j}; t = templates.(name); cc = j-2;
    kk = find(mesh.interface_cell==cc); gid = nv+mesh.interface_edges(kk);
    [ok,loc] = ismember(gid,t.nodes);
    assert(all(ok),'i96:Interface','Interface midpoint missing in template %s.',name);
    nt = size(t.tri6,1); nn = size(t.xy,1);
    Inc = sparse(t.tri6(:,4:6),repmat((1:nt)',1,3),repmat(1:3,nt,1),nn,nt);
    inner = zeros(numel(loc),1); outer = inner; qin = inner; qout = inner;
    for e = 1:numel(loc)
      [~,els,qq] = find(Inc(loc(e),:));
      assert(numel(els)==2,'i96:Interface','Interface edge without two owners.');
      if t.material(els(1))~=config.model.rho_background, a = 1; b = 2; else, a = 2; b = 1; end
      inner(e) = els(a); outer(e) = els(b); qin(e) = qq(a); qout(e) = qq(b);
    end
    interface = struct('mid',loc,'theta',mesh.interface_theta(kk), ...
      'dtheta',2*pi/cfg.interface_segments,'inner',inner,'outer',outer,'q_inner',qin,'q_outer',qout);
    native.templates.(name) = struct('name',name,'cell',cc,'xy',t.xy,'tri6',t.tri6, ...
      'material',t.material,'M1',M1.(name),'Qqp',t.Qqp,'K',t.K,'M',t.M,'free',t.free, ...
      'wall',t.wall,'interior',t.interior,'top',t.top,'bottom',t.bottom, ...
      'inclusion_area',t.inclusion_area,'exact_area',exact(j),'interface',interface, ...
      'rho_in',max(t.material));
  end
  % --- 33-point curve deviation of every interface segment (diagnostic) ---
  native.curve_deviation = LOCAL_curve_deviation(config,mesh,cfg);
  summary.curve_deviation = rmfield(native.curve_deviation,'per_segment');
  % --- raw recovery data and QZ blocks for read-only audit ---
  native.recovery = struct('g',g*scale*phase,'traces_left',traces_all.left*scale*phase, ...
    'traces_right',traces_all.right*scale*phase,'E_center',Ec,'E_left',ext.left.E, ...
    'E_right',ext.right.E,'S_left',ext.left.S,'S_right',ext.right.S,'S_center',ext.center.S, ...
    'D_left',ext.left.D,'D_right',ext.right.D,'Pout_left',ext.left.Pout, ...
    'Pout_right',ext.right.Pout,'H',ext.center.H,'lambda_all',res.lambda,'y',y, ...
    'wall_mass',templates.wall_mass);
  native.qz = struct('left',ext.left.qz,'right',ext.right.qz);
  native.times.recovery = toc(timer);
  summary.scale = scale; summary.phase = phase; summary.U0 = native.U0;
  summary.times = native.times;
  native.summary = summary;
end

function native = LOCAL_explicit_native(config,native)
  % Explicit numeric input of the adapter schema; loading/validation is the
  % caller's, this only checks the fields and records the identity.
  required = {'k','templates','cells','U0','qualified','summary'};
  for f = required
    assert(isfield(native,f{1}),'i96:Native','Explicit native input lacks field %s.',f{1});
  end
  native.identity = 'EXPLICIT_SAVED_FIELD';
  if native.k~=config.k
    native.qualified = false; native.summary.reason = 'EXPLICIT_K_DIFFERS_FROM_CONFIG';
  end
end

function dev = LOCAL_curve_deviation(config,mesh,cfg)
  % p(t) (P2 interface edge, theta increasing) against c(theta_k+t*dtheta)
  % at curve_samples points; the parameter-matched distance bounds the
  % geometric deviation. Diagnostic only, not a material classification.
  ns = config.delivery.curve_samples; ng = cfg.interface_segments; t = linspace(0,1,ns)';
  nv = size(mesh.points,1); per = zeros(numel(mesh.interface_edges),1); endpoint = per;
  for e = 1:numel(mesh.interface_edges)
    c = mesh.interface_cell(e); th = mesh.interface_theta(e);
    A = LOCAL_curve(config,c,th); B = LOCAL_curve(config,c,th+2*pi/ng);
    Mid = mesh.p2_points(nv+mesh.interface_edges(e),:);
    ends = mesh.points(mesh.edges(mesh.interface_edges(e),:),:);
    endpoint(e) = min(norm(ends(1,:)-A)+norm(ends(2,:)-B),norm(ends(1,:)-B)+norm(ends(2,:)-A));
    p = A.*(1-t).*(1-2*t)+Mid.*4.*t.*(1-t)+B.*t.*(2*t-1);
    per(e) = max(vecnorm(p-LOCAL_curve(config,c,th+t*2*pi/ng),2,2));
  end
  dev = struct('samples',ns,'max',max(per),'mean',mean(per), ...
    'max_by_cell',[max(per(mesh.interface_cell==-1)),max(per(mesh.interface_cell==0)), ...
    max(per(mesh.interface_cell==1))],'endpoint_mismatch_max',max(endpoint),'per_segment',per);
end

function LOCAL_save_native(output_dir,native)
  % native.mat: templates, cells (normalised full P2 coefficients), E, P, S,
  % D, wall values, QZ blocks, curve deviations (read-only audit input).
  save(fullfile(output_dir,'native.mat'),'native','-v7');
end

%% ==================== Constants of the bound ====================
% C_rho, the eq. (18a) Green constant, budget b and L2-projection Lebesgue constants.
function common = LOCAL_constants(config,native)
  k = native.k; mu = k^2; s = mu; beta = config.model.beta;
  rho = [config.model.rho_background,config.model.rho_center,config.model.rho_negative, ...
    config.model.rho_positive];
  C_rho = max((mu*rho+s)./sqrt(rho));
  K = 32; b_beta = abs(beta)/(2*pi); m = (-K:K)'; a = sqrt(s+(beta+2*pi*m).^2);
  CG2 = sum(1./(4*a.^3))+1/(4*(2*pi)^3*(K-b_beta)^2);
  q_star = min(abs(beta+2*pi*(-2:2)));
  [L1,L2] = LOCAL_lebesgue(config.gate.lebesgue_samples);
  common = struct('k',k,'mu',mu,'s',s,'beta',beta,'C_rho',C_rho,'CG_squared',CG2, ...
    'CG',sqrt(CG2),'shift_floor',s+q_star^2,'U0',native.U0, ...
    'b',config.budget_relative*native.U0,'rho_max',max(rho),'rho_background', ...
    config.model.rho_background,'lebesgue_q1_1d',L1,'lebesgue_q2_1d',L2, ...
    'resolution_target_k',config.resolution_target_k);
end

function [L1,L2] = LOCAL_lebesgue(ns)
  % 1D L2-projection Lebesgue constants on [-1,1] for P1/P2: max_x int |K_n(x,t)| dt
  % (composite fine-grid estimate plus a 1e-6 margin; used only in gate widths).
  % (blocks of 64 x-samples keep the kernel tables below 50 MB)
  x = linspace(-1,1,ns); t = linspace(-1,1,20*ns+1)'; dt = t(2)-t(1);
  P = [ones(size(t)),t,(3*t.^2-1)/2]; w = dt*ones(size(t)); w([1,end]) = dt/2;
  L1 = 0; L2 = 0;
  for i = 1:64:ns
    xb = x(i:min(i+63,ns)); Px = [ones(size(xb));xb;(3*xb.^2-1)/2];
    K1 = P(:,1)*Px(1,:)/2+3*P(:,2)*Px(2,:)/2; K2 = K1+5*P(:,3)*Px(3,:)/2;
    L1 = max(L1,max(w'*abs(K1))); L2 = max(L2,max(w'*abs(K2)));
  end
  L1 = L1+1e-6; L2 = L2+1e-6;
end

%% ==================== First-batch reliable-integration gate ====================
% Design 4.1/6: measured bisection tightening on material- and rectangle-cut pieces.
function gate = LOCAL_gate(ctx,native,lev,common)
  config = ctx.config; G = config.gate; names = {'left','center','right'};
  gate = struct('level',lev.name,'N',lev.N,'b',common.b,'templates',struct([]), ...
    'closure_supported',false,'reason','','seconds',0);
  timer = tic;
  for j = 1:3
    t = native.templates.(names{j});
    sel = find(strcmp({native.cells.template},names{j}));
    % field of the template's largest-amplitude cell near the batch
    anchor = LOCAL_curve(config,t.cell,0);
    X6 = reshape(t.xy(t.tri6,1),[],6); Y6 = reshape(t.xy(t.tri6,2),[],6);
    batch = find(min(hypot(X6-anchor(1),Y6-anchor(2)),[],2)<=G.batch_radius);
    amp = zeros(1,numel(sel));
    for q = 1:numel(sel), amp(q) = max(abs(native.cells(sel(q)).coef(t.tri6(batch,:))),[],'all'); end
    [~,pick] = max(amp); coef = native.cells(sel(pick)).coef;
    record = LOCAL_gate_template(config,t,batch,coef,lev,common);
    record.cell_index = native.cells(sel(pick)).index;
    record = LOCAL_gate_predict(config,native,t,record,common,lev,toc(ctx.started));
    gate.templates = LOCAL_append(gate.templates,record);
    fprintf(['  GATE %s %s: %d elements, depth %d, last width/b=%.3e, slope/level=%.3f, ', ...
      'need depth %.1f, leaves %.3e, %.3es: %s\n'],lev.name,names{j},numel(batch), ...
      record.rows(end).depth,record.rows(end).ratio_all,record.slope_all, ...
      record.depth_needed_all,record.leaves_needed_all,record.seconds_needed_all,record.verdict);
  end
  gate.seconds = toc(timer);
  ok = arrayfun(@(r)r.closure_supported,gate.templates);
  gate.closure_supported = all(ok);
  if gate.closure_supported
    gate.reason = 'all templates predict closure within leaf, depth and time limits';
  else
    gate.reason = strjoin(arrayfun(@(r)sprintf('%s: %s',r.template,r.verdict),gate.templates(~ok), ...
      'UniformOutput',false),'; ');
  end
end

function rec = LOCAL_gate_template(config,t,batch,coef,lev,common)
  % Reference bisection of batch elements. A leaf is classified when its
  % Bernstein control-net box lies in one rectangle and outside the analytic
  % chord tube of the true curve (side by winding of the closed polygon).
  % Unclassified leaves keep interval widths: source moments
  % e = coef*Umax*A*||l_ab||_inf per candidate rectangle, Q2 moments, direct
  % |u-v_R|^2 and |f-f_R|^2 widths; norms use the square-root conversion.
  G = config.gate; h = 1/lev.N; N = lev.N; x0 = t.cell-0.5; mu = common.mu; s = common.s;
  rho_in = t.rho_in; rho_out = common.rho_background;
  alpha_max = mu*max(rho_in,rho_out)+s;
  nb = numel(batch); T6 = t.tri6(batch,:);
  X6 = reshape(t.xy(T6,1),nb,6); Y6 = reshape(t.xy(T6,2),nb,6); U6 = reshape(coef(T6),nb,6);
  c_R = sqrt(2)*h^2/pi^2; L1 = common.lebesgue_q1_1d^2; L2 = common.lebesgue_q2_1d^2;
  [xq,wq] = LOCAL_quadrature(G.integration_order);
  leaves = [(1:nb)',repmat([0,0,1,0,0,1],nb,1)];
  rows = struct([]); start = tic; Ubatch = NaN; checksum = 0; refinements = 0;
  tube = LOCAL_tube_setup(config,t.cell);
  rec = struct('template',t.name,'level',lev.name,'elements',nb, ...
    'curved_elements',0,'rows',[],'checksum',0,'tube_window',tube.window_ok);
  for d = 0:G.max_depth
    lt = tic;
    e = leaves(:,1); R = leaves(:,2:7);
    rx = [R(:,1),R(:,3),R(:,5),(R(:,1)+R(:,3))/2,(R(:,3)+R(:,5))/2,(R(:,5)+R(:,1))/2];
    ry = [R(:,2),R(:,4),R(:,6),(R(:,2)+R(:,4))/2,(R(:,4)+R(:,6))/2,(R(:,6)+R(:,2))/2];
    [Xv,Yv,Uv,Dv] = LOCAL_eval_p2(X6(e,:),Y6(e,:),U6(e,:),rx,ry);
    CX = LOCAL_control(Xv); CY = LOCAL_control(Yv); CU = LOCAL_control(Uv);
    xmin = min(CX,[],2); xmax = max(CX,[],2); ymin = min(CY,[],2); ymax = max(CY,[],2);
    Umax = max(abs(CU),[],2);
    if d==0
      Ubatch = max(Umax);
      rec.curved_elements = nnz(max(abs(CX(:,4:6)-Xv(:,4:6))+abs(CY(:,4:6)-Yv(:,4:6)),[],2)>1e-14);
    end
    ref_area = abs((R(:,3)-R(:,1)).*(R(:,6)-R(:,2))-(R(:,5)-R(:,1)).*(R(:,4)-R(:,2)))/2;
    A = ref_area.*mean(Dv(:,4:6),2);                 % det is quadratic: edge-midpoint rule exact
    c1 = min(max(floor((xmin-x0)/h),0),N-1); c2 = min(max(floor((xmax-x0)/h),0),N-1);
    r1 = min(max(floor((ymin+0.5)/h),0),N-1); r2 = min(max(floor((ymax+0.5)/h),0),N-1);
    rect_known = c1==c2 & r1==r2;
    centre = [(xmin+xmax)/2,(ymin+ymax)/2]; half = hypot(xmax-xmin,ymax-ymin)/2;
    [mat_known,inside,tube] = LOCAL_tube_classify(tube,centre,half,G.tube_fraction);
    classified = rect_known & mat_known;
    % exact polynomial integration of classified leaves (Q1/Q2 moments, |u|^2)
    checksum = checksum+LOCAL_leaf_integrals(X6(e(classified),:),Y6(e(classified),:), ...
      U6(e(classified),:),R(classified,:),xq,wq,x0,h,c1(classified),r1(classified));
    % interval widths of the unclassified set (all, and material-uncertain only)
    un = ~classified; mat_un = un & ~mat_known;
    alpha_known = mu*(rho_out+(rho_in-rho_out)*inside)+s;
    e_src = zeros(size(A));
    e_src(un & ~rect_known & mat_known) = alpha_known(un & ~rect_known & mat_known);
    e_src(un & rect_known & ~mat_known) = mu*(rho_in-rho_out)/2;
    e_src(un & ~rect_known & ~mat_known) = alpha_max;
    e_src = e_src.*Umax.*A;
    w_all = LOCAL_gate_widths(un,e_src,Umax,A,rect_known,c1,c2,r1,r2,N,h,Ubatch,alpha_max, ...
      L1,L2,c_R,common);
    w_mat = LOCAL_gate_widths(mat_un,e_src,Umax,A,rect_known,c1,c2,r1,r2,N,h,Ubatch,alpha_max, ...
      L1,L2,c_R,common);
    row = struct('depth',d,'leaves',numel(e),'classified',nnz(classified), ...
      'unclassified',nnz(un),'rect_only',nnz(un & mat_known),'material_only',nnz(un & rect_known & ~mat_known), ...
      'both',nnz(un & ~rect_known & ~mat_known),'unclassified_area',sum(A(un)), ...
      'material_unclassified_area',sum(A(mat_un)),'leaf_diameter_max',2*max(half), ...
      'tube_delta',tube.delta,'tube_segments',tube.segments, ...
      'delta_c',w_all.delta_c,'delta_1',w_all.delta_1,'moment_term',w_all.moment_term, ...
      'ER_width',w_all.ER,'eps0_width',w_all.eps0,'du_width',w_all.du,'Ev_width',w_all.Ev, ...
      'ratio_all',w_all.ratio,'ratio_material',w_mat.ratio,'eps0_width_material',w_mat.eps0, ...
      'seconds',0,'cumulative_seconds',0);
    if ~any(un)
      row.seconds = toc(lt); row.cumulative_seconds = toc(start); rows = LOCAL_append(rows,row); break
    end
    % bisect the unclassified leaves along their longest physical chord
    leaves = LOCAL_bisect(leaves(un,:),Xv(un,1:3),Yv(un,1:3));
    row.seconds = toc(lt); row.cumulative_seconds = toc(start);
    rows = LOCAL_append(rows,row); refinements = refinements+1;
    if refinements>=G.min_refinements+G.fit_levels-1 && toc(start)>G.seconds_cap, break, end
  end
  rec.rows = rows; rec.checksum = checksum; rec.Ubatch = Ubatch;
  rec.refinements = refinements; rec.seconds = toc(start);
end

function w = LOCAL_gate_widths(set,e_src,Umax,A,rect_known,c1,c2,r1,r2,N,h,Ubatch,alpha_max,L1,L2,c_R,common)
  % Sum per candidate rectangle (Q1 source and Q2 field allocation widths).
  idx = find(set);
  if isempty(idx)
    w = struct('delta_c',0,'delta_1',0,'moment_term',0,'ER',0,'eps0',0,'du',0,'Ev',0,'ratio',0); return
  end
  nc = c2(idx)-c1(idx)+1; nr = r2(idx)-r1(idx)+1; cnt = nc.*nr;
  owner = LOCAL_rep((1:numel(idx))',cnt); off = (1:sum(cnt))'-LOCAL_rep(cumsum(cnt)-cnt,cnt)-1;
  cc = c1(idx(owner))+floor(off./nr(owner)); rr = r1(idx(owner))+mod(off,nr(owner));
  key = rr+N*cc+1;
  [ukey,~,pos] = unique(key);
  S1 = accumarray(pos,e_src(idx(owner)),[numel(ukey),1]);
  q2 = ~rect_known(idx(owner));
  S2 = accumarray(pos,q2.*Umax(idx(owner)).*A(idx(owner)),[numel(ukey),1]);
  delta_c = sqrt(sum(S1.^2)*16/h^2); delta_1 = 6.25*sum(S1);
  moment_term = min(delta_c/common.shift_floor,common.CG*delta_1);
  dv = sqrt(sum(S2.^2)*81/h^2);
  rk = ~rect_known(idx);
  du2 = sum((Umax(idx(rk))+L2*Ubatch).^2.*A(idx(rk)));
  ER2 = sum((alpha_max*Umax(idx)+L1*alpha_max*Ubatch).^2.*A(idx));
  ER = sqrt(ER2)+delta_c;
  w = struct('delta_c',delta_c,'delta_1',delta_1,'moment_term',moment_term,'ER',ER, ...
    'eps0',c_R*ER+moment_term,'du',sqrt(du2)+dv,'Ev',dv,'ratio',0);
  w.ratio = max([w.eps0,w.du,w.Ev])/common.b;
end

function record = LOCAL_gate_predict(config,native,t,record,common,lev,elapsed)
  % Fit log(width/b) and log(unclassified leaves) over the last fit_levels
  % rows; predict the depth, terminal leaves and seconds needed to bring the
  % widths to b, for the batch and scaled to the template's whole curve.
  G = config.gate; rows = record.rows; use = find([rows.unclassified]>0);
  use = use(max(1,end-G.fit_levels+1):end);
  record.fit_rows = [rows(use).depth];
  record.closure_supported = false; record.verdict = '';
  fields = {'all','material'};
  % scale: whole template curve length / batch curve length (leaves), and
  % sum over cells of (curve length * amplitude) / batch (widths)
  ifc = t.interface; seg = vecnorm(t.xy(t.tri6(sub2ind(size(t.tri6),ifc.inner, ...
    mod(ifc.q_inner,3)+1)),:)-t.xy(t.tri6(sub2ind(size(t.tri6),ifc.inner,ifc.q_inner)),:),2,2);
  anchor = LOCAL_curve(config,t.cell,0); midxy = t.xy(ifc.mid,:);
  in_batch = hypot(midxy(:,1)-anchor(1),midxy(:,2)-anchor(2))<=config.gate.batch_radius;
  L_batch = max(sum(seg(in_batch)),eps); L_template = sum(seg);
  amp = zeros(1,numel(native.cells)); len = zeros(1,numel(native.cells));
  for q = 1:numel(native.cells)
    tq = native.templates.(native.cells(q).template);
    amp(q) = max(abs(native.cells(q).coef(tq.interface.mid)));
    len(q) = sum(vecnorm(diff(LOCAL_curve(config,tq.cell,linspace(0,2*pi,2049)')),2,2));
  end
  bcell = [native.cells.index]==record.cell_index;
  record.scale_leaves = L_template/L_batch;
  record.scale_width = sum(len.*amp)/(L_batch*amp(bcell));
  record.L_batch = L_batch; record.L_template = L_template;
  remaining = config.resources.soft_seconds-elapsed;
  for f = fields
    ratio = [rows(use).(['ratio_',f{1}])]; depth = [rows(use).depth];
    nun = [rows(use).unclassified]; secs = [rows(use).seconds]; nl = [rows(use).leaves];
    if numel(use)<3 || any(ratio<=0)
      slope = NaN; growth = NaN;
    else
      p = polyfit(depth,log(ratio),1); slope = p(1);
      p = polyfit(depth,log(nun),1); growth = exp(p(1));
    end
    per_leaf = secs(end)/max(nl(end),1);
    ratio_full = ratio(end)*record.scale_width;
    if isnan(slope) || slope>=0
      need = Inf; leaves_needed = Inf; seconds_needed = Inf;
    elseif ratio_full<=1
      need = depth(end); leaves_needed = sum([rows.leaves])*record.scale_leaves;
      seconds_needed = sum([rows.seconds])*record.scale_leaves;
    else
      steps = log(ratio_full)/(-slope); need = depth(end)+steps;
      % cumulative leaves: n_last * sum_{j=1..steps} growth^j (in logs)
      if growth>1
        leaves_needed = record.scale_leaves*nun(end)*growth*(growth^steps-1)/(growth-1);
      else
        leaves_needed = record.scale_leaves*nun(end)*steps;
      end
      seconds_needed = leaves_needed*per_leaf;
    end
    record.(['slope_',f{1}]) = slope; record.(['growth_',f{1}]) = growth;
    record.(['depth_needed_',f{1}]) = need; record.(['leaves_needed_',f{1}]) = leaves_needed;
    record.(['seconds_needed_',f{1}]) = seconds_needed; record.(['ratio_full_',f{1}]) = ratio_full;
    record.(['per_leaf_seconds_',f{1}]) = per_leaf;
  end
  reasons = {};
  if numel(use)<3, reasons{end+1} = 'fewer than three fitted refinements'; end
  if ~(record.slope_all<0), reasons{end+1} = 'no tightening'; end
  if record.depth_needed_all>G.depth_limit
    reasons{end+1} = sprintf('depth %.1f > %d',record.depth_needed_all,G.depth_limit);
  end
  if record.leaves_needed_all>G.leaf_limit
    reasons{end+1} = sprintf('leaves %.3e > %.0e',record.leaves_needed_all,G.leaf_limit);
  end
  if record.seconds_needed_all>remaining
    reasons{end+1} = sprintf('time %.3es > remaining soft %.0fs',record.seconds_needed_all,remaining);
  end
  if isempty(reasons)
    record.closure_supported = true; record.verdict = 'closure supported';
  else
    record.verdict = strjoin(reasons,', ');
  end
  record.level = lev.name;
end

function tube = LOCAL_tube_setup(config,cell_index)
  % Analytic chord tube: |c(theta)-chord| <= M2*dtheta^2/8 with
  % M2 >= max|c''| (centre: hypot(1.86,1.76)*star_scale; leads: sqrt(2)R'(1+10a)).
  if cell_index==0
    M2 = hypot(1.86,1.76)*config.model.star_scale;
  else
    a = config.model.a_negative; if cell_index>0, a = config.model.a_positive; end
    M2 = sqrt(2)*config.model.radius/sqrt(1+a^2/2)*(1+10*a);
  end
  w = config.gate.theta_window;
  coarse = LOCAL_curve(config,cell_index,linspace(w,2*pi-w,512)');
  near = LOCAL_curve(config,cell_index,0);
  window_gap = min(hypot(coarse(:,1)-near(1),coarse(:,2)-near(2)));
  tube = struct('cell',cell_index,'M2',M2,'window',w,'coarse',coarse,'delta',NaN, ...
    'segments',0,'A',zeros(0,2),'B',zeros(0,2),'poly',zeros(0,2), ...
    'window_ok',window_gap>config.gate.batch_radius+0.05,'config',config);
end

function [known,inside,tube] = LOCAL_tube_classify(tube,centre,half,fraction)
  % Refine the window polyline so that delta <= fraction * median box radius;
  % a box is material-classified iff dist(centre,polyline) - half > delta.
  target = fraction*median(half);
  dth = sqrt(8*target/tube.M2); ns = min(max(ceil(2*tube.window/dth),64),400000);
  if ns~=tube.segments
    th = linspace(-tube.window,tube.window,ns+1)';
    pts = LOCAL_curve(tube.config,tube.cell,th);
    tube.A = pts(1:end-1,:); tube.B = pts(2:end,:); tube.segments = ns;
    tube.delta = tube.M2*(2*tube.window/ns)^2/8;
    % closed polygon for the side test: fine window part + coarse remainder
    tube.poly = [pts;tube.coarse];
  end
  dist = LOCAL_segment_distance(centre,tube.A,tube.B);
  known = dist-half>tube.delta;
  inside = false(size(known));
  inside(known) = inpolygon(centre(known,1),centre(known,2),tube.poly(:,1),tube.poly(:,2));
end

function dist = LOCAL_segment_distance(points,A,B)
  % Distance from points to the open polyline segments A(i)->B(i), blocked.
  dist = inf(size(points,1),1); bp = 4096; bs = 256;
  for i = 1:bp:size(points,1)
    I = i:min(i+bp-1,size(points,1)); px = points(I,1); py = points(I,2); best = inf(numel(I),1);
    for j = 1:bs:size(A,1)
      J = j:min(j+bs-1,size(A,1));
      ax = A(J,1)'; ay = A(J,2)'; dx = B(J,1)'-ax; dy = B(J,2)'-ay;
      t = ((px-ax).*dx+(py-ay).*dy)./(dx.^2+dy.^2); t = min(max(t,0),1);
      best = min(best,min(hypot(px-ax-t.*dx,py-ay-t.*dy),[],2));
    end
    dist(I) = best;
  end
end

function value = LOCAL_leaf_integrals(X6,Y6,U6,R,xq,wq,x0,h,col,row)
  % Exact (degree-18 Duffy rule) Q1/Q2 moments and |u|^2 of classified leaves;
  % only a checksum is kept (the batch measures throughput and widths).
  value = 0;
  if isempty(R), return, end
  ref_area = abs((R(:,3)-R(:,1)).*(R(:,6)-R(:,2))-(R(:,5)-R(:,1)).*(R(:,4)-R(:,2)))/2;
  px = R(:,1)+(R(:,3)-R(:,1))*xq(:,2)'+(R(:,5)-R(:,1))*xq(:,3)';
  py = R(:,2)+(R(:,4)-R(:,2))*xq(:,2)'+(R(:,6)-R(:,2))*xq(:,3)';
  [X,Y,U,D] = LOCAL_eval_p2(X6,Y6,U6,px,py);
  W = 2*ref_area.*D.*wq';
  xi = 2*(X-(x0+(col+0.5)*h))/h; eta = 2*(Y-(-0.5+(row+0.5)*h))/h;
  Px = {ones(size(xi)),xi,(3*xi.^2-1)/2}; Py = {ones(size(eta)),eta,(3*eta.^2-1)/2};
  for a = 1:3
    for b = 1:3
      value = value+abs(sum(W.*U.*Px{a}.*Py{b},'all'));
    end
  end
  value = value+sum(W.*abs(U).^2,'all');
end

function leaves = LOCAL_bisect(leaves,Xv,Yv)
  % Split every leaf at the midpoint of its longest physical vertex chord.
  R = leaves(:,2:7);
  l = [hypot(Xv(:,2)-Xv(:,1),Yv(:,2)-Yv(:,1)),hypot(Xv(:,3)-Xv(:,2),Yv(:,3)-Yv(:,2)), ...
    hypot(Xv(:,1)-Xv(:,3),Yv(:,1)-Yv(:,3))];
  [~,longest] = max(l,[],2);
  V = {R(:,1:2),R(:,3:4),R(:,5:6)};
  a = zeros(size(R,1),2); b = a; c = a;
  for q = 1:3
    k = longest==q; i1 = q; i2 = mod(q,3)+1; i3 = mod(q+1,3)+1;
    a(k,:) = V{i1}(k,:); b(k,:) = V{i2}(k,:); c(k,:) = V{i3}(k,:);
  end
  m = (a+b)/2;
  leaves = [leaves(:,1),a,m,c;leaves(:,1),m,b,c];
end

function C = LOCAL_control(V)
  % Quadratic Bernstein control net on a sub-triangle from values at the
  % vertices (1:3) and edge midpoints (4: 1-2, 5: 2-3, 6: 3-1).
  C = [V(:,1:3),2*V(:,4)-(V(:,1)+V(:,2))/2,2*V(:,5)-(V(:,2)+V(:,3))/2,2*V(:,6)-(V(:,3)+V(:,1))/2];
end

function [X,Y,U,D] = LOCAL_eval_p2(X6,Y6,U6,xi,eta)
  % P2 map, field and Jacobian determinant at reference points (rows = elements).
  [N,Nx,Ny] = LOCAL_p2_basis(xi,eta);
  X = 0; Y = 0; U = 0; Xx = 0; Xy = 0; Yx = 0; Yy = 0;
  for i = 1:6
    X = X+N{i}.*X6(:,i); Y = Y+N{i}.*Y6(:,i); U = U+N{i}.*U6(:,i);
    Xx = Xx+Nx{i}.*X6(:,i); Xy = Xy+Ny{i}.*X6(:,i);
    Yx = Yx+Nx{i}.*Y6(:,i); Yy = Yy+Ny{i}.*Y6(:,i);
  end
  D = Xx.*Yy-Xy.*Yx;
end

function [N,Nx,Ny] = LOCAL_p2_basis(xi,eta)
  % P2 Lagrange basis (vertices 1-3, midpoints 4: 1-2, 5: 2-3, 6: 3-1) and
  % reference derivatives, element-wise on arrays.
  l1 = 1-xi-eta; l2 = xi; l3 = eta;
  N = {l1.*(2*l1-1),l2.*(2*l2-1),l3.*(2*l3-1),4*l1.*l2,4*l2.*l3,4*l3.*l1};
  z = zeros(size(xi));
  Nx = {-(4*l1-1),4*l2-1,z,4*(l1-l2),4*l3,-4*l3};
  Ny = {-(4*l1-1),z,4*l3-1,-4*l2,4*l2,4*(l1-l3)};
end

%% ==================== Ordinary integration: geometry decomposition ====================
% Straight-triangle clipping + signed chord->arc and true-material slivers.
function geo = LOCAL_template_geometry(config,t,common,lev)
  % Element data, curved-edge chord->arc slivers and true-material slivers
  % (rectangle splits depend on the level, so this is built per level).
  I = config.integration; h = 1/lev.N; x0 = t.cell-0.5; mu = common.mu; s = common.s;
  nt = size(t.tri6,1);
  X6 = reshape(t.xy(t.tri6,1),nt,6); Y6 = reshape(t.xy(t.tri6,2),nt,6);
  P1 = [X6(:,1),Y6(:,1)]; E1 = [X6(:,2),Y6(:,2)]-P1; E2 = [X6(:,3),Y6(:,3)]-P1;
  detJ = E1(:,1).*E2(:,2)-E1(:,2).*E2(:,1);
  inv = [E2(:,2),-E2(:,1),-E1(:,2),E1(:,1)]./detJ;     % [xi;eta] = [i1 i2; i3 i4]*(x-P1)
  mids = [(X6(:,1)+X6(:,2))/2,(X6(:,2)+X6(:,3))/2,(X6(:,3)+X6(:,1))/2];
  midy = [(Y6(:,1)+Y6(:,2))/2,(Y6(:,2)+Y6(:,3))/2,(Y6(:,3)+Y6(:,1))/2];
  bend = hypot(X6(:,4:6)-mids,Y6(:,4:6)-midy);
  curved_edge = bend>1e-14;
  geo = struct('nt',nt,'X6',X6,'Y6',Y6,'P1',P1,'inv',inv,'detJ',detJ, ...
    'xmin',min(X6(:,1:3),[],2),'xmax',max(X6(:,1:3),[],2), ...
    'ymin',min(Y6(:,1:3),[],2),'ymax',max(Y6(:,1:3),[],2), ...
    'curved',any(curved_edge,2),'material',t.material,'alpha',mu*t.material+s,'x0',x0,'h',h);
  % --- chord->arc slivers: P(t,tau) = A + t(B-A) + tau*D*t(1-t), det = cr*t(1-t) ---
  [tg,wg] = LOCAL_gauss01(I.sliver_t); [sg,ws] = LOCAL_gauss01(I.sliver_tau);
  [ee,qq] = find(curved_edge); chunks = cell(numel(ee),1);
  for k = 1:numel(ee)
    e = ee(k); q = qq(k); i1 = q; i2 = mod(q,3)+1;
    A = [X6(e,i1),Y6(e,i1)]; B = [X6(e,i2),Y6(e,i2)]; Mid = [X6(e,3+q),Y6(e,3+q)];
    D = 4*Mid-2*(A+B); cr = (B(1)-A(1))*D(2)-(B(2)-A(2))*D(1);
    rows = cell(numel(sg),1);
    for j = 1:numel(sg)
      tau = sg(j); c0 = A; c1 = (B-A)+tau*D; c2 = -tau*D;
      brk = LOCAL_quadratic_breaks(c0,c1,c2,x0,h);
      [tt,wt,tm,seg] = LOCAL_split_rule(brk,tg,wg);
      P = c0+c1.*tt+c2.*tt.^2; Pm = c0+c1.*tm(seg)+c2.*tm(seg).^2;
      w = -cr*tt.*(1-tt).*wt*ws(j);
      rows{j} = [P,w,Pm];
    end
    data = vertcat(rows{:});
    chunks{k} = [data(:,1:3),repmat(e,size(data,1),1),data(:,4:5)];
  end
  sl = vertcat(chunks{:});
  if isempty(sl), sl = zeros(0,6); end
  [col,row] = LOCAL_rect_of(sl(:,5),sl(:,6),x0,h,lev.N);
  a1 = geo.alpha(sl(:,4));
  geo.sliver = struct('x',sl(:,1),'y',sl(:,2),'w',sl(:,3),'elem',sl(:,4),'col',col,'row',row, ...
    'a1',a1,'a0',zeros(size(a1)),'z',zeros(size(a1)),'wu',sl(:,3),'wf',sl(:,3),'we',sl(:,3));
  % --- true-material slivers: Q = p(t) + tau(c(theta(t)) - p(t)) ---
  ifc = t.interface; [tg,wg] = LOCAL_gauss01(I.true_t); [sg,ws] = LOCAL_gauss01(I.true_tau);
  rho_in = t.rho_in; rho_out = common.rho_background; chunks = cell(numel(ifc.mid),1);
  side_change = 0;
  for k = 1:numel(ifc.mid)
    th = ifc.theta(k); dth = ifc.dtheta;
    A = LOCAL_curve(config,t.cell,th); B = LOCAL_curve(config,t.cell,th+dth); Mid = t.xy(ifc.mid(k),:);
    p1 = -3*A-B+4*Mid; p2 = 2*A+2*B-4*Mid;
    brk = unique([LOCAL_quadratic_breaks(A,p1,p2,x0,h);0.5]);
    [tt,wt,tm,seg] = LOCAL_split_rule(brk,tg,wg);
    % side of each sub-interval: c to the left of p' => region inside p => inner element
    pm = A+p1.*tm+p2.*tm.^2; dpm = p1+2*p2.*tm; cm = LOCAL_curve(config,t.cell,th+tm*dth);
    left = dpm(:,1).*(cm(:,2)-pm(:,2))-dpm(:,2).*(cm(:,1)-pm(:,1))>0;
    side_change = side_change+nnz(diff(left));
    p = A+p1.*tt+p2.*tt.^2; dp = p1+2*p2.*tt;
    c = LOCAL_curve(config,t.cell,th+tt*dth); dc = LOCAL_curve_derivative(config,t.cell,th+tt*dth)*dth;
    rows = cell(numel(sg),1);
    for j = 1:numel(sg)
      tau = sg(j); Q = p+tau*(c-p); Qt = dp+tau*(dc-dp); Qs = c-p;
      det = Qt(:,1).*Qs(:,2)-Qt(:,2).*Qs(:,1);
      w = -det.*wt*ws(j);
      el = ifc.outer(k)*ones(numel(tt),1); el(left(seg)) = ifc.inner(k);
      rows{j} = [Q,w,el,pm(seg,:)];
    end
    chunks{k} = vertcat(rows{:});
  end
  ts = vertcat(chunks{:});
  [col,row] = LOCAL_rect_of(ts(:,5),ts(:,6),x0,h,lev.N);
  n = size(ts,1);
  geo.true_sliver = struct('x',ts(:,1),'y',ts(:,2),'w',ts(:,3),'elem',ts(:,4),'col',col,'row',row, ...
    'a1',(mu*rho_in+s)*ones(n,1),'a0',(mu*rho_out+s)*ones(n,1),'z',ones(n,1), ...
    'wu',zeros(n,1),'wf',ts(:,3),'we',ts(:,3));
  geo.true_sliver_side_changes = side_change;
end

function [col,row] = LOCAL_rect_of(x,y,x0,h,N)
  col = min(max(floor((x-x0)/h),0),N-1); row = min(max(floor((y+0.5)/h),0),N-1);
end

function brk = LOCAL_quadratic_breaks(c0,c1,c2,x0,h)
  % Parameters t in (0,1) where c0+c1 t+c2 t^2 crosses grid lines x0+k h
  % (first component) or -1/2+k h (second); returns [0; sorted roots; 1].
  brk = [0;1];
  origin = [x0,-0.5];
  for d = 1:2
    tt = linspace(0,1,9)'; vals = c0(d)+c1(d)*tt+c2(d)*tt.^2;
    lo = ceil((min(vals)-origin(d))/h-1); hi = floor((max(vals)-origin(d))/h+1);
    for kk = lo:hi
      g = origin(d)+kk*h; a = c2(d); b = c1(d); c = c0(d)-g;
      if abs(a)<=1e-14*(abs(b)+abs(c))
        if b~=0, r = -c/b; else, r = []; end
      else
        disc = b^2-4*a*c;
        if disc<0, r = []; else
          sq = sqrt(disc); qv = -0.5*(b+sign(b+(b==0))*sq);
          r = [qv/a;c/qv]; r = r(isfinite(r));
        end
      end
      brk = [brk;r(r>0 & r<1)]; %#ok<AGROW>
    end
  end
  brk = unique(brk);
end

function [tt,wt,tm,seg] = LOCAL_split_rule(brk,tg,wg)
  % Gauss rule (tg,wg on [0,1]) on every sub-interval of the break list.
  a = brk(1:end-1); b = brk(2:end); keep = b-a>0; a = a(keep); b = b(keep);
  tt = a+(b-a).*tg'; wt = (b-a).*wg'; tm = (a+b)/2;
  seg = repmat((1:numel(a))',1,numel(tg));
  tt = reshape(tt',[],1); wt = reshape(wt',[],1); seg = reshape(seg',[],1);
end

function pts = LOCAL_strip_points(config,geo,lev,cols,dun)
  % Exact clipping of the straight triangles by the rectangles of the strip
  % columns; full rectangles get 3x3 Gauss, other pieces a Dunavant-8 fan.
  h = geo.h; x0 = geo.x0; N = lev.N; j0 = cols(1); j1 = cols(end)+1; ncs = numel(cols);
  xa = x0+j0*h; xb = x0+j1*h;
  sel = find(geo.xmax>xa & geo.xmin<xb);
  clo = max(floor((geo.xmin(sel)-x0)/h),j0); chi = min(ceil((geo.xmax(sel)-x0)/h)-1,j1-1);
  cnt = max(chi-clo+1,0);
  tri = LOCAL_rep(sel,cnt); col = LOCAL_rep(clo,cnt)+((1:sum(cnt))'-LOCAL_rep(cumsum(cnt)-cnt,cnt)-1);
  PX = [geo.X6(tri,1:3),nan(numel(tri),6)]; PY = [geo.Y6(tri,1:3),nan(numel(tri),6)];
  pn = 3*ones(numel(tri),1);
  [PX,PY,pn] = LOCAL_clip(PX,PY,pn,1,x0+col*h,1);
  [PX,PY,pn] = LOCAL_clip(PX,PY,pn,1,x0+(col+1)*h,-1);
  keep = pn>=3; PX = PX(keep,:); PY = PY(keep,:); pn = pn(keep); tri = tri(keep); col = col(keep);
  ymin = min(PY,[],2); ymax = max(PY,[],2);
  rlo = max(floor((ymin+0.5)/h),0); rhi = min(ceil((ymax+0.5)/h)-1,N-1);
  cnt = max(rhi-rlo+1,0);
  own = LOCAL_rep((1:numel(tri))',cnt); row = LOCAL_rep(rlo,cnt)+((1:sum(cnt))'-LOCAL_rep(cumsum(cnt)-cnt,cnt)-1);
  PX = PX(own,:); PY = PY(own,:); pn = pn(own); tri = tri(own); col = col(own);
  [PX,PY,pn] = LOCAL_clip(PX,PY,pn,2,-0.5+row*h,1);
  [PX,PY,pn] = LOCAL_clip(PX,PY,pn,2,-0.5+(row+1)*h,-1);
  area = LOCAL_poly_area(PX,PY,pn);
  keep = pn>=3 & area>config.integration.min_piece_area_fraction*h^2;
  PX = PX(keep,:); PY = PY(keep,:); pn = pn(keep); tri = tri(keep); col = col(keep);
  row = row(keep); area = area(keep);
  full = pn==4 & abs(area-h^2)<=1e-12*h^2;
  % full rectangles: 3x3 Gauss-Legendre
  g = [-sqrt(3/5),0,sqrt(3/5)]; gw = [5,8,5]/9; [gx,gy] = ndgrid(g,g); gww = gw'*gw;
  xc = x0+(col(full)+0.5)*h; yc = -0.5+(row(full)+0.5)*h;
  fx = xc+h/2*gx(:)'; fy = yc+h/2*gy(:)'; fw = repmat(h^2/4*gww(:)',numel(xc),1);
  ft = repmat(tri(full),1,9); fr = repmat(row(full)+N*(col(full)-j0)+1,1,9);
  % cut pieces: fan triangles with the Dunavant rule
  cut = find(~full); ox = {}; oy = {}; ow = {}; ot = {}; orr = {};
  for k = 2:max([pn(cut);2])-1
    s = cut(pn(cut)>=k+1);
    if isempty(s), continue, end
    v1x = PX(s,1); v1y = PY(s,1); v2x = PX(s,k); v2y = PY(s,k); v3x = PX(s,k+1); v3y = PY(s,k+1);
    ta = ((v2x-v1x).*(v3y-v1y)-(v3x-v1x).*(v2y-v1y))/2;
    ox{end+1} = v1x*dun.l(:,1)'+v2x*dun.l(:,2)'+v3x*dun.l(:,3)'; %#ok<AGROW>
    oy{end+1} = v1y*dun.l(:,1)'+v2y*dun.l(:,2)'+v3y*dun.l(:,3)'; %#ok<AGROW>
    ow{end+1} = ta*dun.w'; %#ok<AGROW>
    ot{end+1} = repmat(tri(s),1,numel(dun.w)); %#ok<AGROW>
    orr{end+1} = repmat(row(s)+N*(col(s)-j0)+1,1,numel(dun.w)); %#ok<AGROW>
  end
  cat1 = @(a,b)[a(:);cell2mat(cellfun(@(c)c(:),b(:),'UniformOutput',false))];
  x = cat1(fx,ox); y = cat1(fy,oy); w = cat1(fw,ow); elem = cat1(ft,ot); rect = cat1(fr,orr);
  n = numel(x); alpha = geo.alpha(elem);
  pts = struct('x',x,'y',y,'w',w,'elem',elem,'rect',rect,'a1',alpha,'a0',zeros(n,1), ...
    'z',zeros(n,1),'wu',w,'wf',w,'we',w);
  pts.stats = struct('pieces',numel(pn),'full',nnz(full),'cut',nnz(~full), ...
    'area',sum(area),'ncs',ncs);
end

function [QX,QY,qn] = LOCAL_clip(PX,PY,pn,dim,value,sgn)
  % Sutherland-Hodgman clip of NaN-padded convex polygons (rows) to the
  % half-plane sgn*(coordinate - value) >= 0; value is one number per row.
  np = size(PX,1); width = size(PX,2); QX = nan(np,width+2); QY = QX; qn = zeros(np,1);
  if np==0, QX = QX(:,1:width); QY = QY(:,1:width); return, end
  value = value(:).*ones(np,1);
  if dim==1, C = PX; else, C = PY; end
  D = sgn*(C-value); rows = (1:np)';
  for i = 1:max(pn)
    act = pn>=i; nxt = (i+1)*ones(np,1); nxt(pn==i) = 1; nxt = min(nxt,width);
    ci = rows+np*(i-1); cj = rows+np*(nxt-1);
    xi = PX(ci); yi = PY(ci); di = D(ci); xj = PX(cj); yj = PY(cj); dj = D(cj);
    k = find(act & di>=0);
    qn(k) = qn(k)+1; idx = k+np*(qn(k)-1); QX(idx) = xi(k); QY(idx) = yi(k);
    k = find(act & ((di>=0)~=(dj>=0)));
    tt = di(k)./(di(k)-dj(k));
    nx = xi(k)+tt.*(xj(k)-xi(k)); ny = yi(k)+tt.*(yj(k)-yi(k));
    if dim==1, nx = value(k); else, ny = value(k); end
    qn(k) = qn(k)+1; idx = k+np*(qn(k)-1); QX(idx) = nx; QY(idx) = ny;
  end
  used = max([qn;3]); QX = QX(:,1:max(used,width)); QY = QY(:,1:max(used,width));
end

function area = LOCAL_poly_area(PX,PY,pn)
  np = size(PX,1); area = zeros(np,1); rows = (1:np)';
  for i = 1:max([pn;0])
    act = pn>=i; nxt = (i+1)*ones(np,1); nxt(pn==i) = 1; nxt = min(nxt,size(PX,2));
    ci = rows+np*(i-1); cj = rows+np*(nxt-1);
    term = PX(ci).*PY(cj)-PX(cj).*PY(ci); area(act) = area(act)+term(act);
  end
  area = area/2;
end

function pts = LOCAL_add_slivers(pts,geo,cols,N)
  % Append the chord->arc and true-material sliver points of the strip columns.
  j0 = cols(1); j1 = cols(end);
  for name = {'sliver','true_sliver'}
    S = geo.(name{1}); k = S.col>=j0 & S.col<=j1;
    pts.x = [pts.x;S.x(k)]; pts.y = [pts.y;S.y(k)]; pts.w = [pts.w;S.w(k)];
    pts.elem = [pts.elem;S.elem(k)]; pts.rect = [pts.rect;S.row(k)+N*(S.col(k)-j0)+1];
    pts.a1 = [pts.a1;S.a1(k)]; pts.a0 = [pts.a0;S.a0(k)]; pts.z = [pts.z;S.z(k)];
    pts.wu = [pts.wu;S.wu(k)]; pts.wf = [pts.wf;S.wf(k)]; pts.we = [pts.we;S.we(k)];
  end
end

function [xi,eta,residual] = LOCAL_reference_coordinates(config,geo,pts)
  % Affine inverse for straight elements; Newton on the P2 map for curved ones
  % (points of the chord/arc and true slivers may lie just outside T-hat).
  e = pts.elem; dx = pts.x-geo.P1(e,1); dy = pts.y-geo.P1(e,2);
  xi = geo.inv(e,1).*dx+geo.inv(e,2).*dy; eta = geo.inv(e,3).*dx+geo.inv(e,4).*dy;
  residual = 0;
  c = find(geo.curved(e));
  if isempty(c), return, end
  X6 = geo.X6(e(c),:); Y6 = geo.Y6(e(c),:); a = xi(c); b = eta(c);
  for it = 1:config.integration.newton_iterations
    [N,Nx,Ny] = LOCAL_p2_basis(a,b);
    Fx = -pts.x(c); Fy = -pts.y(c); Jxx = 0; Jxy = 0; Jyx = 0; Jyy = 0;
    for i = 1:6
      Fx = Fx+N{i}.*X6(:,i); Fy = Fy+N{i}.*Y6(:,i);
      Jxx = Jxx+Nx{i}.*X6(:,i); Jxy = Jxy+Ny{i}.*X6(:,i);
      Jyx = Jyx+Nx{i}.*Y6(:,i); Jyy = Jyy+Ny{i}.*Y6(:,i);
    end
    dd = Jxx.*Jyy-Jxy.*Jyx;
    a = a-(Jyy.*Fx-Jxy.*Fy)./dd; b = b-(-Jyx.*Fx+Jxx.*Fy)./dd;
    residual = max(hypot(Fx,Fy));
    if residual<=config.integration.newton_tolerance, break, end
  end
  [N,~,~] = LOCAL_p2_basis(a,b); Fx = -pts.x(c); Fy = -pts.y(c);
  for i = 1:6, Fx = Fx+N{i}.*X6(:,i); Fy = Fy+N{i}.*Y6(:,i); end
  residual = max(hypot(Fx,Fy));
  xi(c) = a; eta(c) = b;
end

%% ==================== Ordinary integration: projections and Fourier moments ====================
% Per template and x-strip; Q1 source / Q2 field moments for all cells of the template.
function proj = LOCAL_project(ctx,native,lev,common,mvec)
  % One pass for the Fourier modes mvec (a block of -M..M). Column energies
  % colE* (all modes) and block mode energies blk* give the Parseval tails
  % after all blocks: tail = colE - sum over blocks of blk.
  config = ctx.config; N = lev.N; M = lev.M; h = 1/N; nc = config.field.cells_per_side;
  ncols = (2*nc+1)*N; nm = numel(mvec); ncell = numel(native.cells);
  LOCAL_memory_gate(config,'mode arrays',5*nm*ncols*16+2*nm*(ncols+1)*16);
  F = zeros(nm,ncols,2,'like',1i); V = zeros(nm,ncols,3,'like',1i);
  colEF = zeros(ncols,1); colEV = colEF; blkF = colEF; blkV = colEF;
  cellstat = struct('index',[native.cells.index],'mass',zeros(1,ncell),'ER2',zeros(1,ncell), ...
    'du2',zeros(1,ncell),'source_energy',zeros(1,ncell),'field_energy',zeros(1,ncell), ...
    'colEF',zeros(1,ncell),'colEV',zeros(1,ncell),'blkF',zeros(1,ncell),'blkV',zeros(1,ncell), ...
    'mass_matrix',zeros(1,ncell));
  q = common.beta+2*pi*mvec; kappa = q*h/2;
  J = zeros(nm,3);
  for b = 0:2, J(:,b+1) = sqrt(h)*sqrt(2*b+1)*(-1i)^b*LOCAL_sph_bessel(b,kappa); end
  shift = exp(1i*pi*mvec*(1-h)); fidx = mod(mvec,N)+1;
  yj = -0.5+((0:N-1)'+0.5)*h; ybeta = exp(-1i*common.beta*yj);
  dun = LOCAL_dunavant();
  names = {'center','left','right'}; tpl = struct([]); total_points = 0; newton_max = 0;
  chunk = 4;
  for jt = 1:3
    name = names{jt}; t = native.templates.(name);
    sel = find(strcmp({native.cells.template},name));
    Coef = [native.cells(sel).coef]; gcol0 = ([native.cells(sel).index]+nc)*N;
    for q2 = 1:numel(sel)
      cellstat.mass_matrix(sel(q2)) = real(Coef(:,q2)'*t.M1*Coef(:,q2));
    end
    tt = tic;
    geo = LOCAL_template_geometry(config,t,common,lev);
    geo_seconds = toc(tt);
    areas = struct('total',0,'inclusion_p2',0,'true_sliver',0,'sliver',0);
    pieces = 0; full = 0; npts_t = 0;
    for j0 = 0:lev.strip_columns:N-1
      cols = j0:min(j0+lev.strip_columns,N)-1; ncs = numel(cols); nr = N*ncs;
      pts = LOCAL_strip_points(config,geo,lev,cols,dun);
      pieces = pieces+pts.stats.pieces; full = full+pts.stats.full;
      areas.total = areas.total+sum(pts.w); areas.inclusion_p2 = areas.inclusion_p2+ ...
        sum(pts.w(geo.material(pts.elem)~=common.rho_background));
      nbase = numel(pts.w);
      pts = LOCAL_add_slivers(pts,geo,cols,N);
      k = (nbase+1):numel(pts.w);
      areas.sliver = areas.sliver+sum(pts.wu(k));
      areas.total = areas.total+sum(pts.wu(k));
      areas.inclusion_p2 = areas.inclusion_p2+sum(pts.wu(k(geo.material(pts.elem(k))~=common.rho_background)));
      areas.true_sliver = areas.true_sliver+sum(pts.wf(pts.z==1));
      [xi,eta,res] = LOCAL_reference_coordinates(config,geo,pts);
      newton_max = max(newton_max,res);
      np = numel(pts.w); npts_t = npts_t+np;
      % P2 evaluation matrix and Legendre moment matrix (13 blocks of nr)
      [Nb,~,~] = LOCAL_p2_basis(xi,eta);
      Phi = sparse(repmat((1:np)',1,6),t.tri6(pts.elem,:),[Nb{:}],np,size(t.xy,1));
      lc = floor((pts.rect-1)/N); lr = pts.rect-1-N*lc;
      sx = 2*(pts.x-(geo.x0+(cols(1)+lc+0.5)*h))/h; sy = 2*(pts.y-(-0.5+(lr+0.5)*h))/h;
      Px = [ones(np,1),sx,(3*sx.^2-1)/2]; Py = [ones(np,1),sy,(3*sy.^2-1)/2];
      bi = zeros(np,13); bv = bi; kk = 0;
      for b = 0:1
        for a = 0:1
          kk = kk+1; bi(:,kk) = pts.rect+(kk-1)*nr; bv(:,kk) = sqrt((2*a+1)*(2*b+1))/h*Px(:,a+1).*Py(:,b+1);
        end
      end
      for b = 0:2
        for a = 0:2
          kk = kk+1; bi(:,kk) = pts.rect+(kk-1)*nr; bv(:,kk) = sqrt((2*a+1)*(2*b+1))/h*Px(:,a+1).*Py(:,b+1);
        end
      end
      Bf = sparse(repmat((1:np)',1,4),bi(:,1:4),bv(:,1:4),np,4*nr);
      Bv = sparse(repmat((1:np)',1,9),bi(:,5:13)-4*nr,bv(:,5:13),np,9*nr);
      Bft = Bf.'; Bvt = Bv.';
      cf = pts.wf.*(pts.a1-pts.z.*pts.a0);
      for c0 = 1:chunk:numel(sel)
        cc = c0:min(c0+chunk-1,numel(sel)); nch = numel(cc);
        U = Phi*Coef(:,cc);
        % pass 1: moments
        Fm = Bft*(cf.*U); Vm = Bvt*(pts.wu.*U);
        % pass 2: direct squared defects and |u|^2
        ft = Bf*Fm; vt = Bv*Vm;
        ER2 = sum(pts.we.*(abs(pts.a1.*U-ft).^2-pts.z.*abs(pts.a0.*U-ft).^2),1);
        du2 = sum(pts.wu.*abs(U-vt).^2,1); mass = sum(pts.wu.*abs(U).^2,1);
        cellstat.ER2(sel(cc)) = cellstat.ER2(sel(cc))+ER2;
        cellstat.du2(sel(cc)) = cellstat.du2(sel(cc))+du2;
        cellstat.mass(sel(cc)) = cellstat.mass(sel(cc))+mass;
        cellstat.source_energy(sel(cc)) = cellstat.source_energy(sel(cc))+sum(abs(Fm).^2,1);
        cellstat.field_energy(sel(cc)) = cellstat.field_energy(sel(cc))+sum(abs(Vm).^2,1);
        % analytic y-Fourier moments: FFT sums the per-rectangle factors
        Fm = reshape(Fm,N,ncs,4,nch); Vm = reshape(Vm,N,ncs,9,nch);
        GF = fft(Fm.*ybeta,[],1); GF = GF(fidx,:,:,:).*shift;
        GV = fft(Vm.*ybeta,[],1); GV = GV(fidx,:,:,:).*shift;
        for q2 = 1:nch
          gc = gcol0(cc(q2))+cols+1; ci = sel(cc(q2));
          for a = 0:1
            Fa = J(:,1).*GF(:,:,1+a,q2)+J(:,2).*GF(:,:,3+a,q2);
            F(:,gc,a+1) = Fa;
            col_energy = squeeze(sum(abs(Fm(:,:,1+a,q2)).^2,1)+sum(abs(Fm(:,:,3+a,q2)).^2,1));
            mode_energy = sum(abs(Fa).^2,1)';
            colEF(gc) = colEF(gc)+col_energy(:); blkF(gc) = blkF(gc)+mode_energy;
            cellstat.colEF(ci) = cellstat.colEF(ci)+sum(col_energy);
            cellstat.blkF(ci) = cellstat.blkF(ci)+sum(mode_energy);
          end
          for a = 0:2
            Va = J(:,1).*GV(:,:,1+a,q2)+J(:,2).*GV(:,:,4+a,q2)+J(:,3).*GV(:,:,7+a,q2);
            V(:,gc,a+1) = Va;
            col_energy = squeeze(sum(abs(Vm(:,:,1+a,q2)).^2,1)+sum(abs(Vm(:,:,4+a,q2)).^2,1)+ ...
              sum(abs(Vm(:,:,7+a,q2)).^2,1));
            mode_energy = sum(abs(Va).^2,1)';
            colEV(gc) = colEV(gc)+col_energy(:); blkV(gc) = blkV(gc)+mode_energy;
            cellstat.colEV(ci) = cellstat.colEV(ci)+sum(col_energy);
            cellstat.blkV(ci) = cellstat.blkV(ci)+sum(mode_energy);
          end
        end
      end
      clear Phi Bf Bv Bft Bvt U ft vt GF GV pts
    end
    total_points = total_points+npts_t;
    tpl = LOCAL_append(tpl,struct('template',name,'cells',numel(sel),'points',npts_t, ...
      'pieces',pieces,'full_rectangles',full,'sliver_points',numel(geo.sliver.w), ...
      'true_sliver_points',numel(geo.true_sliver.w),'true_sliver_side_changes', ...
      geo.true_sliver_side_changes,'area_total',areas.total,'area_defect',areas.total-1, ...
      'inclusion_area_pieces',areas.inclusion_p2,'inclusion_area_p2',t.inclusion_area, ...
      'inclusion_area_defect',areas.inclusion_p2-t.inclusion_area, ...
      'true_sliver_area',areas.true_sliver,'true_area_exact',t.exact_area, ...
      'true_area_defect',areas.inclusion_p2+areas.true_sliver-t.exact_area, ...
      'chord_arc_sliver_area',areas.sliver,'geometry_seconds',geo_seconds,'seconds',toc(tt)));
    fprintf('  PROJ %s %s: %d points, area defect %.2e, P2 incl defect %.2e, true defect %.2e, %.2fs\n', ...
      lev.name,name,npts_t,areas.total-1,areas.inclusion_p2-t.inclusion_area, ...
      areas.inclusion_p2+areas.true_sliver-t.exact_area,toc(tt));
  end
  mass_rel = abs(sum(cellstat.mass)-sum(cellstat.mass_matrix))/sum(cellstat.mass_matrix);
  proj = struct('F',F,'V',V,'colEF',colEF,'colEV',colEV,'blkF',blkF,'blkV',blkV, ...
    'cellstat',cellstat,'templates',tpl,'q',q,'mvec',mvec,'h',h,'N',N,'M',M,'ncols',ncols);
  proj.totals = struct('mass',sum(cellstat.mass),'mass_matrix',sum(cellstat.mass_matrix), ...
    'ER2',sum(cellstat.ER2),'du2',sum(cellstat.du2),'Ey2_raw',NaN,'Tv2_raw',NaN);
  proj.checks = struct('points',total_points,'newton_residual_max',newton_max, ...
    'mass_relative_defect',mass_rel,'area_defect_max',max(abs([tpl.area_defect])), ...
    'inclusion_area_defect_max',max(abs([tpl.inclusion_area_defect])), ...
    'true_area_defect_max',max(abs([tpl.true_area_defect])), ...
    'negative_column_tailF',NaN,'negative_column_tailV',NaN, ...
    'min_column_tailF',NaN,'min_column_tailV',NaN,'mode_blocks',NaN);
end

function [proj,norms,table,cell_norms] = LOCAL_level(ctx,native,lev,common)
  % Mode-block driver: every block re-runs the (cheap, deterministic) strip
  % projection and keeps only its modes' F, V, L, R (memory); geometry, cell
  % statistics and direct defects are identical in every pass (first kept).
  config = ctx.config; M = lev.M; allm = (-M:M)'; nb = lev.mode_blocks;
  edges = round(linspace(0,2*M+1,nb+1)); proj_seconds = 0; yukawa_seconds = 0;
  for b = 1:nb
    mvec = allm(edges(b)+1:edges(b+1));
    timer = tic; p = LOCAL_project(ctx,native,lev,common,mvec); proj_seconds = proj_seconds+toc(timer);
    timer = tic; [nrm,tab,cn] = LOCAL_yukawa(config,lev,common,p); yukawa_seconds = yukawa_seconds+toc(timer);
    if b==1
      proj = rmfield(p,{'F','V'}); norms = nrm; table = tab; cell_norms = cn;
    else
      proj.blkF = proj.blkF+p.blkF; proj.blkV = proj.blkV+p.blkV;
      proj.cellstat.blkF = proj.cellstat.blkF+p.cellstat.blkF;
      proj.cellstat.blkV = proj.cellstat.blkV+p.cellstat.blkV;
      for f = {'w2_in_box','Td2','vw2_in_box'}, norms.(f{1}) = norms.(f{1})+nrm.(f{1}); end
      norms.node_consistency = max(norms.node_consistency,nrm.node_consistency);
      for f = fieldnames(table)', table.(f{1}) = [table.(f{1});tab.(f{1})]; end
      cell_norms.w2 = cell_norms.w2+cn.w2; cell_norms.vw2 = cell_norms.vw2+cn.vw2;
    end
    fprintf('  BLOCK %s %d/%d: modes %d..%d, projection %.2fs, yukawa %.2fs\n',lev.name,b,nb, ...
      mvec(1),mvec(end),proj_seconds,yukawa_seconds);
    clear p
  end
  tailF = proj.colEF-proj.blkF; tailV = proj.colEV-proj.blkV;
  proj.tailF = tailF; proj.tailV = tailV; proj.q = common.beta+2*pi*allm; proj.mvec = allm;
  proj.cellstat.tailF = proj.cellstat.colEF-proj.cellstat.blkF;
  proj.cellstat.tailV = proj.cellstat.colEV-proj.cellstat.blkV;
  proj.totals.Ey2_raw = sum(tailF); proj.totals.Tv2_raw = sum(tailV);
  proj.checks.negative_column_tailF = nnz(tailF<0); proj.checks.negative_column_tailV = nnz(tailV<0);
  proj.checks.min_column_tailF = min(tailF); proj.checks.min_column_tailV = min(tailV);
  proj.checks.mode_blocks = nb;
  proj.seconds = proj_seconds;
  norms.Ey2_raw = proj.totals.Ey2_raw; norms.Tv2_raw = proj.totals.Tv2_raw;
  norms.D0 = sqrt(norms.w2_in_box+norms.Td2); norms.seconds = yukawa_seconds;
  nc = config.field.cells_per_side; ncell = 2*nc+1;
  owner = floor((0:proj.ncols-1)'/proj.N)-nc;
  cell_norms.tailF_cols = accumarray(owner+nc+1,tailF,[ncell,1])';
  cell_norms.tailV_cols = accumarray(owner+nc+1,tailV,[ncell,1])';
end

%% ==================== Exact per-mode Yukawa evaluation and norms ====================
% -w''+a^2 w = f (affine per interval); w = (L+R)/(2a) with stable sweeps.
function [norms,table,cell_norms] = LOCAL_yukawa(config,lev,common,proj)
  h = proj.h; q = proj.q; a = sqrt(common.s+q.^2); z = a*h; E = exp(-z); nm = numel(q);
  ncols = proj.ncols; [g0,g1] = LOCAL_gamma01(z); F = proj.F; V = proj.V;
  sh = sqrt(h); r3 = sqrt(3);
  Lnode = zeros(nm,ncols+1,'like',1i); Rnode = Lnode;
  for i = 1:ncols
    P0 = (F(:,i,1)-r3*F(:,i,2))/sh; P1 = 2*r3*F(:,i,2)/h^1.5;
    Lnode(:,i+1) = E.*Lnode(:,i)+(P0+P1*h)*h.*g0-P1*h^2.*g1;
  end
  for i = ncols:-1:1
    P0 = (F(:,i,1)-r3*F(:,i,2))/sh; P1 = 2*r3*F(:,i,2)/h^1.5;
    Rnode(:,i) = E.*Rnode(:,i+1)+P0*h.*g0+P1*h^2.*g1;
  end
  w_left = Rnode(:,1)./(2*a); w_right = Lnode(:,end)./(2*a);
  Td2_mode = (abs(w_left).^2+abs(w_right).^2)./(2*a);
  % 12-point Gauss norms with closed-form interior values (no cancellation)
  [xg,wg] = LOCAL_gauss01(config.integration.norm_gauss); ng = numel(xg); tau = h*xg';
  eL = exp(-a*tau); eR = exp(-a*(h-tau)); [gL0,gL1] = LOCAL_gamma01(a*tau); [gR0,gR1] = LOCAL_gamma01(a*(h-tau));
  xt = 2*xg-1; l0 = 1/sh*ones(ng,1); l1 = sqrt(3/h)*xt; l2 = sqrt(5/h)*(3*xt.^2-1)/2;
  w2_mode = zeros(nm,1); d2_mode = zeros(nm,1); w2_col = zeros(ncols,1); d2_col = zeros(ncols,1);
  fE_mode = zeros(nm,1); vE_mode = zeros(nm,1);
  for i0 = 1:config.integration.norm_block_columns:ncols
    I = i0:min(i0+config.integration.norm_block_columns-1,ncols);
    P0 = (F(:,I,1)-r3*F(:,I,2))/sh; P1 = 2*r3*F(:,I,2)/h^1.5;
    Li = Lnode(:,I); Rn = Rnode(:,I+1); wn = zeros(nm,numel(I)); dv = wn;
    for g = 1:ng
      t = tau(g);
      IL = t*((P0+P1*t).*gL0(:,g)-P1*t.*gL1(:,g));
      IR = (h-t)*((P0+P1*t).*gR0(:,g)+P1*(h-t).*gR1(:,g));
      w = (eL(:,g).*Li+IL+eR(:,g).*Rn+IR)./(2*a);
      v = V(:,I,1)*l0(g)+V(:,I,2)*l1(g)+V(:,I,3)*l2(g);
      wn = wn+wg(g)*h*abs(w).^2; dv = dv+wg(g)*h*abs(v-w).^2;
    end
    w2_mode = w2_mode+sum(wn,2); d2_mode = d2_mode+sum(dv,2);
    w2_col(I) = sum(wn,1)'; d2_col(I) = sum(dv,1)';
    fE_mode = fE_mode+sum(abs(F(:,I,1)).^2+abs(F(:,I,2)).^2,2);
    vE_mode = vE_mode+sum(abs(V(:,I,1)).^2+abs(V(:,I,2)).^2+abs(V(:,I,3)).^2,2);
  end
  % consistency of the two sweeps at sampled interior nodes: node value from
  % (L_i+R_i)/(2a) versus the interior Green formula of interval i-1 at tau = h
  I = 1:max(1,floor((ncols-1)/64)):ncols-1;
  P0 = (F(:,I,1)-r3*F(:,I,2))/sh; P1 = 2*r3*F(:,I,2)/h^1.5;
  wl = (Lnode(:,I+1)+Rnode(:,I+1))./(2*a);
  wr = (E.*Lnode(:,I)+h*((P0+P1*h).*g0-P1*h.*g1)+Rnode(:,I+1))./(2*a);
  jump = max(abs(wl-wr),[],'all'); jump_den = max(abs(wl),[],'all');
  norms = struct('w2_in_box',sum(w2_mode),'Td2',sum(Td2_mode),'vw2_in_box',sum(d2_mode), ...
    'node_consistency',jump/max(jump_den,realmin));
  table = struct('m',proj.mvec,'q',q,'a',a,'source_energy',fE_mode,'field_energy',vE_mode, ...
    'w2_in_box',w2_mode,'Td2',Td2_mode,'vw2_in_box',d2_mode);
  nc = config.field.cells_per_side; ncell = 2*nc+1;
  owner = floor((0:ncols-1)'/proj.N)-nc;
  cell_norms = struct('index',(-nc:nc),'w2',accumarray(owner+nc+1,w2_col,[ncell,1])', ...
    'vw2',accumarray(owner+nc+1,d2_col,[ncell,1])');
end

function [g0,g1] = LOCAL_gamma01(z)
  % gamma_r(z) = int_0^1 s^r exp(-z s) ds, r = 0,1 (series for z < 1/2).
  g0 = zeros(size(z)); g1 = g0; small = z<0.5; zs = z(small);
  term = ones(size(zs)); s0 = zeros(size(zs)); s1 = s0;
  for k = 0:24
    s0 = s0+term/(k+1); s1 = s1+term/(k+2); term = term.*(-zs)/(k+1);
  end
  g0(small) = s0; g1(small) = s1;
  zl = z(~small);
  g0(~small) = -expm1(-zl)./zl; g1(~small) = (1-exp(-zl).*(1+zl))./zl.^2;
end

function j = LOCAL_sph_bessel(n,x)
  % Spherical Bessel j_n, n = 0..2 (power series for |x| < 1, closed form else).
  j = zeros(size(x)); small = abs(x)<1; xs = x(small); xl = x(~small);
  term = xs.^n/prod(1:2:2*n+1); acc = term;
  for k = 1:16
    term = term.*(-xs.^2/2)/(k*(2*n+2*k+1)); acc = acc+term;
  end
  j(small) = acc; s = sin(xl); c = cos(xl);
  switch n
    case 0, j(~small) = s./xl;
    case 1, j(~small) = s./xl.^2-c./xl;
    case 2, j(~small) = (3./xl.^2-1).*s./xl-3*c./xl.^2;
  end
end

%% ==================== Bound assembly and status ====================
% eps0 = c_R E_R + min{delta_c/(s+beta^2), C_G delta_1} + E_y/b_M (18a); R_mu, R_k.
function level = LOCAL_combine(config,lev,common,proj,norms,gate)
  h = proj.h; M = proj.M; c_R = sqrt(h^4+h^4)/pi^2;
  b_M = common.s+(2*pi*(M+1)-abs(common.beta))^2;
  negative = struct('ER2',proj.totals.ER2,'du2',proj.totals.du2,'Ey2_raw',norms.Ey2_raw, ...
    'Tv2_raw',norms.Tv2_raw,'any_negative',any([proj.totals.ER2,proj.totals.du2, ...
    norms.Ey2_raw,norms.Tv2_raw]<0),'negative_column_tailF',proj.checks.negative_column_tailF, ...
    'negative_column_tailV',proj.checks.negative_column_tailV);
  sqrtp = @(x)sqrt(max(x,0));
  E_R = sqrtp(proj.totals.ER2); E_y = sqrtp(norms.Ey2_raw); T_v = sqrtp(norms.Tv2_raw);
  delta_u = sqrtp(proj.totals.du2);
  E_v = sqrt(norms.vw2_in_box+norms.Td2+max(norms.Tv2_raw,0));
  eps0 = c_R*E_R+E_y/b_M;                    % ordinary: moment-error term not bounded
  D0 = norms.D0; den = D0-eps0;
  o = struct('identity','ORDINARY_ESTIMATE','integration_status','INTEGRATION_CONTROL_UNRESOLVED', ...
    'D0',D0,'delta_u',delta_u,'E_v',E_v,'eps0',eps0,'E_R',E_R,'c_R',c_R,'c_R_E_R',c_R*E_R, ...
    'E_y',E_y,'E_y_squared_raw',norms.Ey2_raw,'b_M',b_M,'E_y_over_b_M',E_y/b_M, ...
    'T_d',sqrt(norms.Td2),'T_v',T_v,'T_v_squared_raw',norms.Tv2_raw, ...
    'w2_in_box',norms.w2_in_box,'vw2_in_box',norms.vw2_in_box, ...
    'delta_c',NaN,'delta_1',NaN,'CG',common.CG,'moment_term',NaN, ...
    'moment_term_note','ordinary quadrature: source-moment error bounds not closed (gate)', ...
    'denominator',den,'denominator_positive',den>0,'R_mu',NaN,'R_k',NaN, ...
    'resolution_status','','node_consistency',norms.node_consistency);
  if den>0
    o.R_mu = common.C_rho*(delta_u+E_v+eps0)/den;
    o.R_k = LOCAL_rk(common.k,common.mu,o.R_mu);
    if o.R_k<=common.resolution_target_k
      o.resolution_status = 'ORDINARY_R_K_BELOW_TARGET';
    else
      o.resolution_status = 'ORDINARY_R_K_ABOVE_TARGET';
    end
    scale = common.C_rho/den;
    o.contributions = struct('fixed_field_vs_reconstruction_E_v',scale*E_v, ...
      'q2_proxy_delta_u',scale*delta_u,'source_q1_c_R_E_R',scale*c_R*E_R, ...
      'mode_truncation_E_y_over_b_M',scale*E_y/b_M,'integration_coefficient_evaluation',NaN);
  else
    o.resolution_status = 'DENOMINATOR_NOT_POSITIVE';
    o.contributions = struct();
  end
  x = struct('identity','EXACT_ARITHMETIC_UPPER_BOUND','status','RESOURCE_OR_INTEGRATION_UNRESOLVED', ...
    'R_mu',NaN,'R_k',NaN,'reason',gate.reason);
  if gate.closure_supported
    x.status = 'NOT_IMPLEMENTED_AFTER_SUPPORTED_GATE';
    x.reason = 'gate predicted closure; full reliable integration is not implemented in this run';
  end
  level = struct('name',lev.name,'N',lev.N,'M',M,'h',h,'hx',h,'hy',h,'modes',2*M+1, ...
    'x_intervals',proj.ncols,'mu',common.mu,'k',common.k,'s',common.s,'C_rho',common.C_rho, ...
    'U0',common.U0,'b',common.b,'ordinary',o,'exact',x,'gate_closure_supported',gate.closure_supported, ...
    'checks',proj.checks,'totals',proj.totals,'negative_records',negative,'skipped',false, ...
    'skip_reason','','seconds',NaN,'projection_seconds',proj.seconds,'yukawa_seconds',norms.seconds);
end

function rk = LOCAL_rk(k,mu,R)
  % Largest distance from k to sqrt of the interval [max(0,mu-R), mu+R].
  rk = max(k-sqrt(max(0,mu-R)),sqrt(mu+R)-k);
end

function level = LOCAL_skipped_level(lev,common,gate,reason)
  nanord = struct('identity','ORDINARY_ESTIMATE','integration_status','NOT_EVALUATED', ...
    'D0',NaN,'delta_u',NaN,'E_v',NaN,'eps0',NaN,'E_R',NaN,'c_R',NaN,'c_R_E_R',NaN,'E_y',NaN, ...
    'E_y_squared_raw',NaN,'b_M',NaN,'E_y_over_b_M',NaN,'T_d',NaN,'T_v',NaN,'T_v_squared_raw',NaN, ...
    'w2_in_box',NaN,'vw2_in_box',NaN,'delta_c',NaN,'delta_1',NaN,'CG',common.CG,'moment_term',NaN, ...
    'moment_term_note','','denominator',NaN,'denominator_positive',false,'R_mu',NaN,'R_k',NaN, ...
    'resolution_status','NOT_EVALUATED','node_consistency',NaN,'contributions',struct());
  level = struct('name',lev.name,'N',lev.N,'M',lev.M,'h',1/lev.N,'hx',1/lev.N,'hy',1/lev.N, ...
    'modes',2*lev.M+1,'x_intervals',NaN,'mu',common.mu,'k',common.k,'s',common.s, ...
    'C_rho',common.C_rho,'U0',common.U0,'b',common.b,'ordinary',nanord, ...
    'exact',struct('identity','EXACT_ARITHMETIC_UPPER_BOUND','status', ...
    'RESOURCE_OR_INTEGRATION_UNRESOLVED','R_mu',NaN,'R_k',NaN,'reason',reason), ...
    'gate_closure_supported',gate.closure_supported,'checks',struct(),'totals',struct(), ...
    'negative_records',struct(),'skipped',true,'skip_reason',reason,'seconds',NaN, ...
    'projection_seconds',NaN,'yukawa_seconds',NaN);
end

function [status,reason,detail] = LOCAL_final(config,native,levels,gates)
  detail = struct('input_identity',native.identity,'native_qualified',native.qualified, ...
    'gate_closure_supported',arrayfun(@(g)g.closure_supported,gates), ...
    'exact_status',{arrayfun(@(l)l.exact.status,levels,'UniformOutput',false)}, ...
    'ordinary_status',{arrayfun(@(l)l.ordinary.resolution_status,levels,'UniformOutput',false)}, ...
    'ordinary_integration_status','INTEGRATION_CONTROL_UNRESOLVED');
  if ~native.qualified
    status = 'NATIVE_FIELD_MISMATCH'; reason = native.summary.reason;
    if config.continue_on_mismatch, reason = [reason,' (smoke probe continued)']; end
    return
  end
  if any(~detail.gate_closure_supported) || any(strcmp(detail.exact_status,'RESOURCE_OR_INTEGRATION_UNRESOLVED'))
    status = 'RESOURCE_OR_INTEGRATION_UNRESOLVED';
    reason = 'reliable integration gate did not support closure of the 1e-8 U0 budgets; ordinary diagnostics only';
  elseif any(~arrayfun(@(l)l.ordinary.denominator_positive,levels))
    status = 'DENOMINATOR_NOT_POSITIVE'; reason = 'D0 <= eps0 on a level';
  else
    status = 'NOT_IMPLEMENTED_AFTER_SUPPORTED_GATE'; reason = 'see levels';
  end
end

function value = LOCAL_remaining(config,L,level_seconds,after_gate)
  % Predicted remaining MATLAB seconds for progress.json (launcher grace rule):
  % a further level costs about 4.5x the previous one; NaN before any level.
  if isnan(level_seconds), value = NaN; return, end
  value = (numel(config.levels)-L+1)*4.5*level_seconds+(1-after_gate)*60+ ...
    config.resources.save_estimate_seconds;
end

%% ==================== Self-tests of the new numerical building blocks ====================
% Dunavant exactness, clip areas, spherical Bessel continuity, Yukawa sweep vs quadrature.
function st = LOCAL_selftest(config)
  st = struct('pass',true,'reason','');
  dun = LOCAL_dunavant(); err = 0;
  for i = 0:8
    for j = 0:8-i
      val = 0.5*sum(dun.w.*dun.l(:,2).^i.*dun.l(:,3).^j);
      exact = factorial(i)*factorial(j)/factorial(i+j+2);
      err = max(err,abs(val-exact)/exact);
    end
  end
  st.dunavant_degree8_relative_error = err;
  % clipping: random triangles over a grid; piece areas sum to triangle areas
  rng(7); T = rand(50,6); area_err = 0; h = 1/7;
  for k = 1:50
    P = reshape(T(k,:),2,3)'; o = (P(2,1)-P(1,1))*(P(3,2)-P(1,2))-(P(3,1)-P(1,1))*(P(2,2)-P(1,2));
    if o<0, P = P([1,3,2],:); end
    geo = struct('X6',[P(:,1)',zeros(1,3)],'Y6',[P(:,2)'-0.5,zeros(1,3)],'xmin',min(P(:,1)), ...
      'xmax',max(P(:,1)),'h',h,'x0',0,'alpha',1);
    pts = LOCAL_strip_points(config,geo,struct('N',7),0:6,dun);
    area_err = max(area_err,abs(sum(pts.w)-abs(o)/2));
  end
  st.clip_area_error = area_err;
  % spherical Bessel: series/closed-form agreement at the switch point
  x = [1-1e-14,1+1e-14]; bj = zeros(1,3);
  for n = 0:2, v = LOCAL_sph_bessel(n,x); bj(n+1) = abs(diff(v)); end
  st.sph_bessel_switch_jump = max(bj);
  % Yukawa sweep vs direct Green quadrature for one mode and random affine data
  a = 2.3; h = 0.05; n = 40; rng(11); f0 = randn(n,1)+1i*randn(n,1); f1 = randn(n,1);
  z = a*h; E = exp(-z); [g0,g1] = LOCAL_gamma01(z);
  P0 = f0; P1 = f1/h; Ln = zeros(n+1,1); Rn = Ln;
  for i = 1:n, Ln(i+1) = E*Ln(i)+(P0(i)+P1(i)*h)*h*g0-P1(i)*h^2*g1; end
  for i = n:-1:1, Rn(i) = E*Rn(i+1)+P0(i)*h*g0+P1(i)*h^2*g1; end
  xs = 0.37*h*n; at = @(t)min(floor(t/h)+1,n);
  fun = @(t)(reshape(P0(at(t)),size(t))+reshape(P1(at(t)),size(t)).*(t-h*(at(t)-1))) ...
    .*exp(-a*abs(xs-t))/(2*a);
  direct = integral(fun,0,h*n,'Waypoints',h*(1:n-1),'AbsTol',1e-14,'RelTol',1e-13);
  i = floor(xs/h)+1; t = xs-h*(i-1);
  [gL0,gL1] = LOCAL_gamma01(a*t); [gR0,gR1] = LOCAL_gamma01(a*(h-t));
  IL = t*((P0(i)+P1(i)*t)*gL0-P1(i)*t*gL1); IR = (h-t)*((P0(i)+P1(i)*t)*gR0+P1(i)*(h-t)*gR1);
  rec = (exp(-a*t)*Ln(i)+IL+exp(-a*(h-t))*Rn(i+1)+IR)/(2*a);
  st.yukawa_relative_error = abs(rec-direct)/abs(direct);
  checks = [st.dunavant_degree8_relative_error<1e-12,st.clip_area_error<1e-14, ...
    st.sph_bessel_switch_jump<1e-13,st.yukawa_relative_error<1e-10];
  names = {'dunavant','clip','sph_bessel','yukawa'};
  st.pass = all(checks);
  if ~st.pass, st.reason = strjoin(names(~checks),','); end
end

function dun = LOCAL_dunavant()
  % Dunavant degree-8 16-point rule: barycentric points, weights summing to 1.
  a = [0.459292588292723,0.170569307751760,0.050547228317031];
  wa = [0.095091634267285,0.103217370534718,0.032458497623198];
  l = [1/3,1/3,1/3]; w = 0.144315607677787;
  for j = 1:3
    l = [l;a(j),a(j),1-2*a(j);a(j),1-2*a(j),a(j);1-2*a(j),a(j),a(j)]; %#ok<AGROW>
    w = [w;wa(j)*ones(3,1)]; %#ok<AGROW>
  end
  p = [0.008394777409958,0.263112829634638,0.728492392955404];
  l = [l;perms(p)]; w = [w;0.027230314174435*ones(6,1)];
  dun = struct('l',l,'w',w);
end

function [x,w] = LOCAL_gauss01(n)
  j = (1:n-1)'; b = j./sqrt(4*j.^2-1); [Vv,D] = eig(diag(b,1)+diag(b,-1));
  [x,idx] = sort(diag(D)); w = Vv(1,idx)'.^2; x = (x+1)/2;
end

function dc = LOCAL_curve_derivative(config,cell_index,theta)
  theta = theta(:);
  if cell_index==0
    sc = config.model.star_scale*0.2; c5 = cos(5*theta); s5 = sin(5*theta);
    dc = sc*[-1.5*s5.*cos(theta)-(1.5+0.3*c5).*sin(theta),-1.5*s5.*sin(theta)+(1+0.3*c5).*cos(theta)];
  else
    a = config.model.a_negative; if cell_index>0, a = config.model.a_positive; end
    R = config.model.radius/sqrt(1+a^2/2);
    r = R*(1+a*cos(3*theta)); dr = -3*a*R*sin(3*theta);
    dc = [dr.*cos(theta)-r.*sin(theta),dr.*sin(theta)+r.*cos(theta)];
  end
end

%% ==================== Tables, figures, progress and ledger ====================
% Machine tables (CSV), MATLAB-native figures and mutually exclusive timers.
function table = LOCAL_cell_table(native,proj,cell_norms)
  cs = proj.cellstat; n = numel(cs.index);
  table = struct('index',num2cell(cs.index),'template',{native.cells.template}, ...
    'mass_pieces',num2cell(cs.mass),'mass_matrix',num2cell(cs.mass_matrix), ...
    'ER2',num2cell(cs.ER2),'du2',num2cell(cs.du2),'source_energy',num2cell(cs.source_energy), ...
    'field_energy',num2cell(cs.field_energy),'tailF',num2cell(cs.tailF),'tailV',num2cell(cs.tailV), ...
    'w2',num2cell(zeros(1,n)),'vw2',num2cell(zeros(1,n)));
  for j = 1:n
    k = find(cell_norms.index==cs.index(j));
    table(j).w2 = cell_norms.w2(k); table(j).vw2 = cell_norms.vw2(k);
  end
end

function LOCAL_write_modes(path,modes_all)
  fid = fopen(path,'w'); assert(fid>=0,'i96:IO','Cannot create modes.csv.');
  fprintf(fid,'level,m,q,a,source_energy,field_energy,w2_in_box,Td2,vw2_in_box\n');
  for L = 1:numel(modes_all)
    T = modes_all(L).table;
    for j = 1:numel(T.m)
      fprintf(fid,'%s,%d,%.17g,%.17g,%.10e,%.10e,%.10e,%.10e,%.10e\n',modes_all(L).level,T.m(j), ...
        T.q(j),T.a(j),T.source_energy(j),T.field_energy(j),T.w2_in_box(j),T.Td2(j),T.vw2_in_box(j));
    end
  end
  fclose(fid);
end

function LOCAL_write_cells(path,cells_all)
  fid = fopen(path,'w'); assert(fid>=0,'i96:IO','Cannot create cells.csv.');
  fprintf(fid,'level,cell,template,mass_pieces,mass_matrix,ER2,du2,source_energy,field_energy,tailF,tailV,w2,vw2\n');
  for L = 1:numel(cells_all)
    T = cells_all(L).table;
    for j = 1:numel(T)
      r = T(j);
      fprintf(fid,'%s,%d,%s,%.15e,%.15e,%.10e,%.10e,%.10e,%.10e,%.10e,%.10e,%.10e,%.10e\n', ...
        cells_all(L).level,r.index,r.template,r.mass_pieces,r.mass_matrix,r.ER2,r.du2, ...
        r.source_energy,r.field_energy,r.tailF,r.tailV,r.w2,r.vw2);
    end
  end
  fclose(fid);
end

function LOCAL_write_levels(path,levels)
  fid = fopen(path,'w'); assert(fid>=0,'i96:IO','Cannot create levels.csv.');
  fprintf(fid,['level,N,M,h,skipped,D0,delta_u,E_v,eps0,c_R_E_R,E_y_over_b_M,T_d,T_v,', ...
    'denominator,R_mu,R_k,ordinary_status,exact_status,projection_s,yukawa_s\n']);
  for L = 1:numel(levels)
    l = levels(L); o = l.ordinary;
    fprintf(fid,'%s,%d,%d,%.10g,%d,%.15e,%.10e,%.10e,%.10e,%.10e,%.10e,%.10e,%.10e,%.15e,%.10e,%.10e,%s,%s,%.3f,%.3f\n', ...
      l.name,l.N,l.M,l.h,l.skipped,o.D0,o.delta_u,o.E_v,o.eps0,o.c_R_E_R,o.E_y_over_b_M,o.T_d,o.T_v, ...
      o.denominator,o.R_mu,o.R_k,o.resolution_status,l.exact.status,l.projection_seconds,l.yukawa_seconds);
  end
  fclose(fid);
end

function LOCAL_write_gate(path,gates)
  fid = fopen(path,'w'); assert(fid>=0,'i96:IO','Cannot create gate.csv.');
  fprintf(fid,['level,template,depth,leaves,classified,unclassified,rect_only,material_only,both,', ...
    'unclassified_area,material_unclassified_area,leaf_diameter_max,tube_delta,tube_segments,', ...
    'delta_c,delta_1,moment_term,ER_width,eps0_width,du_width,Ev_width,ratio_all,ratio_material,', ...
    'seconds,cumulative_seconds\n']);
  for L = 1:numel(gates)
    for j = 1:numel(gates(L).templates)
      t = gates(L).templates(j);
      for r = t.rows(:)'
        fprintf(fid,'%s,%s,%d,%d,%d,%d,%d,%d,%d,%.6e,%.6e,%.6e,%.6e,%d,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.4f,%.4f\n', ...
          gates(L).level,t.template,r.depth,r.leaves,r.classified,r.unclassified,r.rect_only, ...
          r.material_only,r.both,r.unclassified_area,r.material_unclassified_area,r.leaf_diameter_max, ...
          r.tube_delta,r.tube_segments,r.delta_c,r.delta_1,r.moment_term,r.ER_width,r.eps0_width, ...
          r.du_width,r.Ev_width,r.ratio_all,r.ratio_material,r.seconds,r.cumulative_seconds);
      end
    end
  end
  fclose(fid);
end

function summaries = LOCAL_gate_summaries(gates)
  summaries = struct([]);
  for L = 1:numel(gates)
    g = gates(L); t = rmfield(g.templates,'rows');
    summaries = LOCAL_append(summaries,struct('level',g.level,'N',g.N,'b',g.b, ...
      'closure_supported',g.closure_supported,'reason',g.reason,'seconds',g.seconds,'templates',t));
  end
end

function status = LOCAL_figures(ctx,native,levels,gates,modes_all)
  status = struct('files',{{}},'errors',{{}});
  dir = fullfile(ctx.output_dir,'figures');
  % 1. cell masses and P^j g norms
  try
    f = figure('Visible','off','Position',[100,100,900,380]);
    subplot(1,2,1);
    idx = native.summary.cell_index; m = native.summary.cell_mass; [idx,o] = sort(idx);
    semilogy(idx,max(m(o),realmin),'o-'); grid on; xlabel('cell index'); ylabel('unweighted cell mass');
    title('normalised source-field cell masses');
    subplot(1,2,2); hold on;
    for side = {'left','right'}
      tn = native.tails.(side{1}).trace_norms; semilogy(0:numel(tn)-1,max(tn,realmin),'o-');
    end
    set(gca,'YScale','log'); grid on; xlabel('j'); ylabel('||P^j g||_2'); legend('left','right');
    title('lead wall states');
    LOCAL_export(f,fullfile(dir,'cells.png')); status.files{end+1} = 'cells.png';
  catch e, status.errors{end+1} = ['cells: ',e.message]; end
  % 2. mode energies
  try
    f = figure('Visible','off','Position',[100,100,900,380]);
    for L = 1:numel(modes_all)
      subplot(1,numel(modes_all),L); T = modes_all(L).table;
      semilogy(T.m,max(T.source_energy,realmin),'.',T.m,max(T.field_energy,realmin),'.', ...
        T.m,max(T.w2_in_box,realmin),'.',T.m,max(T.vw2_in_box,realmin),'.');
      grid on; xlabel('m'); title(sprintf('%s level',modes_all(L).level));
      legend('source |f_m|^2','field |v_m|^2','||w_m||^2','||v_m-w_m||^2','Location','southoutside');
    end
    LOCAL_export(f,fullfile(dir,'modes.png')); status.files{end+1} = 'modes.png';
  catch e, status.errors{end+1} = ['modes: ',e.message]; end
  % 3. gate tightening
  try
    f = figure('Visible','off','Position',[100,100,900,380]);
    for L = 1:numel(gates)
      subplot(1,numel(gates),L); hold on;
      for j = 1:numel(gates(L).templates)
        r = gates(L).templates(j).rows;
        semilogy([r.depth],max([r.ratio_all],realmin),'o-','DisplayName',[gates(L).templates(j).template,' all']);
        semilogy([r.depth],max([r.ratio_material],realmin),'x--','DisplayName',[gates(L).templates(j).template,' material']);
      end
      set(gca,'YScale','log'); yline(1,'k-','DisplayName','budget b'); grid on;
      xlabel('bisection depth'); ylabel('max width / b'); title(sprintf('gate %s',gates(L).level));
      legend('Location','southoutside','NumColumns',2);
    end
    LOCAL_export(f,fullfile(dir,'gate.png')); status.files{end+1} = 'gate.png';
  catch e, status.errors{end+1} = ['gate: ',e.message]; end
  % 4. field modulus on the centre and two cells per side
  try
    f = figure('Visible','off','Position',[100,100,1000,330]); hold on;
    for j = 1:numel(native.cells)
      c = native.cells(j);
      if abs(c.index)>2, continue, end
      t = native.templates.(c.template); xy = t.xy; xy(:,1) = xy(:,1)+c.offset;
      tri = t.tri6(:,1:3);
      patch('Faces',tri,'Vertices',xy,'FaceVertexCData',abs(c.coef),'FaceColor','interp','EdgeColor','none');
    end
    axis equal tight; colorbar; xlabel('x'); ylabel('y'); title('|u| (normalised source field), cells -2..2');
    LOCAL_export(f,fullfile(dir,'field.png')); status.files{end+1} = 'field.png';
  catch e, status.errors{end+1} = ['field: ',e.message]; end
  % 5. bound contributions per level
  try
    f = figure('Visible','off','Position',[100,100,800,380]);
    labels = {'\delta_u','E_v','c_R E_R','E_y/b_M','\epsilon_0','R_\mu','R_k'};
    vals = nan(numel(levels),numel(labels));
    for L = 1:numel(levels)
      o = levels(L).ordinary;
      vals(L,:) = [o.delta_u,o.E_v,o.c_R_E_R,o.E_y_over_b_M,o.eps0,o.R_mu,o.R_k];
    end
    bar(max(vals',realmin)); set(gca,'YScale','log','XTickLabel',labels); grid on;
    legend({levels.name},'Location','northwest'); title('ordinary terms (INTEGRATION\_CONTROL\_UNRESOLVED)');
    LOCAL_export(f,fullfile(dir,'terms.png')); status.files{end+1} = 'terms.png';
  catch e, status.errors{end+1} = ['terms: ',e.message]; end
end

function LOCAL_export(f,path)
  exportgraphics(f,path,'Resolution',150); close(f);
end

function ledger = LOCAL_ledger()
  ledger = struct('selftest',0,'native_adapter',0,'gate',0,'projection',0,'yukawa_norms',0, ...
    'assembly',0,'figures',0,'save',0);
end

function timing = LOCAL_ledger_close(ledger,total)
  timing = ledger; values = struct2cell(ledger);
  timing.attributed_seconds = sum([values{:}]);
  timing.matlab_function_seconds = total;
  timing.matlab_unattributed_seconds = total-timing.attributed_seconds;
end

function LOCAL_progress(ctx,phase,predicted)
  value = struct('matlab_elapsed',toc(ctx.started),'phase',phase, ...
    'predicted_remaining_seconds',predicted, ...
    'save_estimate_seconds',ctx.config.resources.save_estimate_seconds,'rss_bytes',LOCAL_rss());
  temporary = [ctx.progress_path,'.tmp'];
  LOCAL_json(temporary,value); movefile(temporary,ctx.progress_path,'f');
end

function LOCAL_partial(ctx,levels,gates,ledger)
  LOCAL_json(fullfile(ctx.output_dir,'partial-result.json'),struct('levels',levels, ...
    'gates',LOCAL_gate_summaries(gates),'timing',LOCAL_ledger_close(ledger,toc(ctx.started))));
end

%% ==================== Copied I9.5b helpers (test/i9/fem-dtn-v1/fem_dtn_i95b.m) ====================
% Verbatim copies except: LOCAL_dtn/LOCAL_evaluate also return the raw ordered
% QZ blocks; LOCAL_memory_gate raises i96:ResourceStop.
function list = LOCAL_append(list,item)
  if isempty(list), list = item; else, list(end+1) = item; end
end

%% ==================== Geometry, joint mesh and deterministic repair ====================
% One three-cell mesh on (-3/2,3/2)x(-1/2,1/2); walls/top/bottom/curves/rings fixed.
function xy = LOCAL_curve(config,cell_index,theta)
  theta = theta(:);
  if cell_index == 0
    xy = config.model.star_scale*0.2*[(1.5+0.3*cos(5*theta)).*cos(theta), ...
      (1+0.3*cos(5*theta)).*sin(theta)];
  else
    a = config.model.a_negative;
    if cell_index>0, a = config.model.a_positive; end
    radius = config.model.radius*(1+a*cos(3*theta))/sqrt(1+a^2/2);
    xy = [radius.*cos(theta),radius.*sin(theta)];
  end
  xy(:,1) = xy(:,1)+cell_index*config.model.L;
end

function [mesh,geometry] = LOCAL_mesh(config,cfg)
  % Design 5 steps 1-5: clearance deletion, constrained Delaunay with fixed
  % curve/ring/wall nodes, up to 3 deletion rounds, then (D2) bounded local
  % edge flips of interface-adjacent bad elements and the final full-mesh gates.
  % geometry.failure_kind is NONE, JACOBIAN_QUALITY_UNRESOLVED,
  % LOCAL_REPAIR_LIMIT or STRUCTURAL_CHECK_FAILED; mesh_structural_checks_pass
  % reports the completed constraint/material/incidence/pairing/coverage checks.
  rules = config.mesh_rules; s = cfg.subdivisions; ng = cfg.interface_segments; h = 1/s;
  tol = rules.coordinate_tolerance;
  [ix,iy] = ndgrid(0:3*s,0:s);
  grid = [-1.5+ix(:)*h,-0.5+iy(:)*h];
  fixed = mod(ix(:),s)==0 | iy(:)==0 | iy(:)==s;      % walls, top, bottom
  theta = 2*pi*(0:ng-1)'/ng;
  curves = cell(3,1); rings = cell(3,2); clearance = false(size(grid,1),1);
  for c = -1:1
    curve = LOCAL_curve(config,c,theta); curves{c+2} = curve;
    relative = curve-[c,0];
    rings{c+2,1} = [c,0]+(1-rules.ring_scale)*relative;
    rings{c+2,2} = [c,0]+(1+rules.ring_scale)*relative;
    clearance = clearance | LOCAL_polyline_distance(grid,curve) < rules.interface_clearance_fraction*h;
    for r = 1:2
      clearance = clearance | LOCAL_polyline_distance(grid,rings{c+2,r}) < rules.ring_clearance_fraction*h;
    end
  end
  background = grid(~clearance | fixed,:);
  deletable = ~fixed(~clearance | fixed);
  rounds = struct('round',{},'deleted',{},'deleted_points',{},'bad_elements',{}, ...
    'worst_ratio',{},'worst_det_min',{},'seconds',{});
  geometry = struct('status','PASS','reason','','failure_kind','NONE', ...
    'mesh_structural_checks_pass',false,'structural_checks_completed',false, ...
    'initial_clearance_deleted',nnz(clearance & ~fixed),'deletion_outcome','', ...
    'flip_stage_entered',false,'flip',struct(),'repair_seconds',0, ...
    'repair_seconds_limit',rules.repair_seconds);
  repair_timer = [];                                  % starts at the first bad element
  for round = 0:rules.repair_rounds
    timer = tic;
    [mesh,checks,base] = LOCAL_triangulate(config,cfg,background,deletable,curves,rings,theta);
    bad = LOCAL_bad(checks,rules);
    [worst_ratio,worst] = max(checks.det_ratio);
    record = struct('round',round,'deleted',0,'deleted_points',zeros(0,2), ...
      'bad_elements',numel(bad),'worst_ratio',worst_ratio,'worst_det_min',checks.det_min(worst), ...
      'seconds',0);
    if isempty(bad)
      geometry.deletion_outcome = sprintf('no bad elements after %d deletion rounds',round);
      record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
      break
    end
    if isempty(repair_timer), repair_timer = timer; end
    if round == rules.repair_rounds
      geometry.deletion_outcome = sprintf('%d bad elements after %d deletion rounds',numel(bad),round);
      record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
      break
    end
    % delete all deletable free background vertices of the bad elements
    vertices = unique(mesh.triangles(bad,:));
    remove = vertices(vertices<=size(background,1));
    remove = remove(deletable(remove));
    if isempty(remove)
      geometry.deletion_outcome = sprintf('%d bad elements without deletable background vertices', ...
        numel(bad));
      record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
      break
    end
    record.deleted = numel(remove); record.deleted_points = background(remove,:);
    keep = true(size(background,1),1); keep(remove) = false;
    background = background(keep,:); deletable = deletable(keep);
    record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
  end
  geometry.repair_rounds = rounds;
  % --- D2 step 4: bounded local edge flips when deletion left bad elements ---
  if ~isempty(bad)
    geometry.flip_stage_entered = true;
    [mesh,checks,geometry.flip] = LOCAL_flip_repair(config,cfg,base,mesh,checks,repair_timer);
    bad = LOCAL_bad(checks,rules);
  end
  if ~isempty(repair_timer), geometry.repair_seconds = toc(repair_timer); end
  % --- step 5: final full-mesh gates on the last rebuilt mesh ---
  geometry.structural_checks_completed = true;
  geometry.mesh_structural_checks_pass = checks.pass;
  geometry.bad_elements = numel(bad);
  geometry.checks = rmfield(checks,{'det_min','det_max','det_ratio','quality','min_angle'});
  geometry.det_min = min(checks.det_min); geometry.det_ratio_max = max(checks.det_ratio);
  geometry.curved_elements = nnz(checks.det_ratio>1+1e-12);
  q = sort(checks.quality); a = sort(checks.min_angle);
  pick = @(v,p)v(max(1,ceil(p*numel(v))));
  geometry.shape_quality = struct('min',q(1),'p01',pick(q,0.01),'p05',pick(q,0.05), ...
    'median',pick(q,0.5),'histogram_edges',0:0.1:1,'histogram',histcounts(q,0:0.1:1));
  geometry.min_angle_degrees = struct('min',a(1),'p01',pick(a,0.01),'p05',pick(a,0.05), ...
    'median',pick(a,0.5));
  if ~checks.pass
    geometry.status = 'GEOMETRY_FAILED'; geometry.failure_kind = 'STRUCTURAL_CHECK_FAILED';
    geometry.reason = ['structural checks: ',checks.reason];
  elseif ~isempty(bad) || geometry.repair_seconds>rules.repair_seconds
    geometry.status = 'GEOMETRY_FAILED';
    flip_limit = geometry.flip_stage_entered && geometry.flip.limit_hit;
    if flip_limit || geometry.repair_seconds>rules.repair_seconds
      geometry.failure_kind = 'LOCAL_REPAIR_LIMIT';
    else
      geometry.failure_kind = 'JACOBIAN_QUALITY_UNRESOLVED';
    end
    geometry.reason = sprintf('%d bad elements; deletion: %s',numel(bad),geometry.deletion_outcome);
    if geometry.flip_stage_entered
      geometry.reason = sprintf('%s; flip: %s',geometry.reason,geometry.flip.outcome);
    end
    if geometry.repair_seconds>rules.repair_seconds
      geometry.reason = sprintf('%s; repair %.2fs > %.0fs',geometry.reason, ...
        geometry.repair_seconds,rules.repair_seconds);
    end
  end
  mesh.det_min = checks.det_min; mesh.det_ratio = checks.det_ratio;
  mesh.quality = checks.quality; mesh.min_angle = checks.min_angle;
  mesh.subdivisions = s; mesh.interface_segments = ng; mesh.h = h;
  mesh.curves = curves; mesh.rings = rings;
  assert(all(abs(mesh.points(:))<2) && tol>0,'i96:Mesh','Mesh points escaped the three-cell box.');
end

function bad = LOCAL_bad(checks,rules)
  bad = find(checks.det_min<=0 | checks.det_ratio>rules.det_ratio_max);
end

function distance = LOCAL_polyline_distance(points,poly)
  a = poly; b = poly([2:end,1],:); distance = inf(size(points,1),1);
  block = 256;
  for j = 1:block:size(a,1)
    J = j:min(j+block-1,size(a,1));
    ax = a(J,1)'; ay = a(J,2)'; dx = b(J,1)'-ax; dy = b(J,2)'-ay;
    t = ((points(:,1)-ax).*dx+(points(:,2)-ay).*dy)./(dx.^2+dy.^2);
    t = min(max(t,0),1);
    d = hypot(points(:,1)-ax-t.*dx,points(:,2)-ay-t.*dy);
    distance = min(distance,min(d,[],2));
  end
end

function [mesh,checks,base] = LOCAL_triangulate(config,cfg,background,deletable,curves,rings,theta)
  % Constrained Delaunay of background + analytic curve/ring nodes, centroid
  % material/cell labels, then the shared P2/check build (LOCAL_mesh_build).
  tol = config.mesh_rules.coordinate_tolerance; ng = cfg.interface_segments;
  points = background; constraints = []; raw_interfaces = []; midpoint_values = [];
  for c = -1:1
    ids = size(points,1)+(1:ng)';
    points = [points;curves{c+2}]; %#ok<AGROW>
    edge = [ids,ids([2:end,1])]; constraints = [constraints;edge]; %#ok<AGROW>
    raw_interfaces = [raw_interfaces;edge]; %#ok<AGROW>
    midpoint_values = [midpoint_values;LOCAL_curve(config,c,theta+pi/ng)]; %#ok<AGROW>
    points = [points;rings{c+2,1};rings{c+2,2}]; %#ok<AGROW>
  end
  [~,first,map] = unique(round(points/tol),'rows','stable');
  assert(numel(first)==size(points,1),'i96:Duplicate','Mesh input contains duplicate points.');
  points = points(first,:); constraints = map(constraints); raw_interfaces = map(raw_interfaces);
  for x = -1.5:1:1.5
    ids = find(abs(points(:,1)-x)<tol);
    [~,order] = sort(points(ids,2)); ids = ids(order);
    constraints = [constraints;[ids(1:end-1),ids(2:end)]]; %#ok<AGROW>
  end
  for y = [-0.5,0.5]
    ids = find(abs(points(:,2)-y)<tol);
    [~,order] = sort(points(ids,1)); ids = ids(order);
    constraints = [constraints;[ids(1:end-1),ids(2:end)]]; %#ok<AGROW>
  end
  constraints = unique(sort(constraints,2),'rows');
  dt = delaunayTriangulation(points,constraints);
  assert(size(dt.Points,1)==size(points,1),'i96:Steiner','Triangulation inserted points.');
  points = dt.Points; triangles = dt.ConnectivityList;
  a = points(triangles(:,2),:)-points(triangles(:,1),:);
  b = points(triangles(:,3),:)-points(triangles(:,1),:);
  orientation = a(:,1).*b(:,2)-a(:,2).*b(:,1);
  triangles(orientation<0,[2,3]) = triangles(orientation<0,[3,2]);
  nt = size(triangles,1);
  centroids = (points(triangles(:,1),:)+points(triangles(:,2),:)+points(triangles(:,3),:))/3;
  cell_id = floor(centroids(:,1)+0.5); material = ones(nt,1)*config.model.rho_background;
  for c = -1:1
    curve = curves{c+2}; inside = inpolygon(centroids(:,1),centroids(:,2),curve(:,1),curve(:,2));
    rho = config.model.rho_center;
    if c<0, rho = config.model.rho_negative; elseif c>0, rho = config.model.rho_positive; end
    material(inside) = rho;
  end
  on_boundary = any(abs(points(:,1)-(-1.5:1:1.5))<tol,2) | abs(abs(points(:,2))-0.5)<tol;
  base = struct('points',points,'constraints',constraints,'raw_interfaces',raw_interfaces, ...
    'midpoint_values',midpoint_values,'theta',theta,'on_boundary',on_boundary, ...
    'background_points',size(background,1),'deletable_points',nnz(deletable));
  [mesh,checks] = LOCAL_mesh_build(config,cfg,base,triangles,material,cell_id);
end

function [mesh,checks] = LOCAL_mesh_build(config,cfg,base,triangles,material,cell_id)
  % Rebuild edges and shared P2 numbering from a connectivity (no Delaunay):
  % interface-edge midpoints take the analytic curve values, all other edges
  % the arithmetic midpoint; then structural checks and curved det extrema.
  tol = config.mesh_rules.coordinate_tolerance; points = base.points;
  constraints = base.constraints; raw_interfaces = base.raw_interfaces;
  nt = size(triangles,1); nv = size(points,1);
  a = points(triangles(:,2),:)-points(triangles(:,1),:);
  b = points(triangles(:,3),:)-points(triangles(:,1),:);
  orientation = a(:,1).*b(:,2)-a(:,2).*b(:,1);
  [edges,~,edge_ids] = unique(sort([triangles(:,[1,2]);triangles(:,[2,3]);triangles(:,[3,1])],2),'rows');
  [found,interface_edges] = ismember(sort(raw_interfaces,2),edges,'rows');
  checks = struct('pass',true,'reason','');
  checks.interface_edges_found = all(found);
  checks.constraints_found = all(ismember(constraints,edges,'rows'));
  incidence = accumarray(edge_ids,1);
  checks.interface_incidence_two = all(found) && all(incidence(interface_edges(found))==2);
  % every edge has one or two owners; one-owner edges lie on the outer box
  outer = @(p)abs(abs(p(:,1))-1.5)<tol | abs(abs(p(:,2))-0.5)<tol;
  single = incidence==1; e1 = points(edges(single,1),:); e2 = points(edges(single,2),:);
  checks.edge_incidence = all(incidence<=2) && all(outer(e1) & outer(e2) & ...
    (abs(e1(:,1)-e2(:,1))<tol | abs(e1(:,2)-e2(:,2))<tol));
  % positive orientation and per-cell coverage of the unit cell area
  cell_area = accumarray(cell_id+2,orientation/2,[3,1]);
  checks.positive_orientation = all(orientation>0);
  checks.cell_coverage = all(abs(cell_area-1)<1e-10) && all(ismember(cell_id,-1:1));
  checks.cell_affine_area = cell_area';
  midpoints = (points(edges(:,1),:)+points(edges(:,2),:))/2;
  midpoints(interface_edges(found),:) = base.midpoint_values(found,:);
  p2_points = [points;midpoints]; triangle_p2 = [triangles,nv+reshape(edge_ids,nt,3)];
  occurrence = repmat((1:nt)',3,1); sides_ok = true; owner_cells_ok = true;
  for e = interface_edges(found)'
    owners = occurrence(edge_ids==e);
    sides_ok = sides_ok && numel(owners)==2 && material(owners(1))~=material(owners(2));
    owner_cells_ok = owner_cells_ok && numel(owners)==2 && cell_id(owners(1))==cell_id(owners(2));
  end
  checks.material_sides = sides_ok; checks.interface_single_cell = owner_cells_ok;
  % element Jacobian determinant extrema on the full reference triangle
  det_min = zeros(nt,1); det_max = zeros(nt,1);
  for t = 1:nt
    coefficients = LOCAL_det_coefficients(LOCAL_map_coefficients(p2_points(triangle_p2(t,:),:)));
    [det_min(t),det_max(t)] = LOCAL_quadratic_triangle_extrema(coefficients);
  end
  det_ratio = det_max./det_min; det_ratio(det_min<=0) = Inf;
  % affine shape quality 4*sqrt(3)*A/sum(l^2) and minimum angle
  P1 = points(triangles(:,1),:); P2 = points(triangles(:,2),:); P3 = points(triangles(:,3),:);
  l1 = sum((P2-P3).^2,2); l2 = sum((P3-P1).^2,2); l3 = sum((P1-P2).^2,2);
  area = abs(orientation)/2;
  quality = 4*sqrt(3)*area./(l1+l2+l3);
  angle = @(opp,u,v)acosd(min(1,max(-1,(u+v-opp)./(2*sqrt(u.*v)))));
  min_angle = min([angle(l1,l2,l3),angle(l2,l3,l1),angle(l3,l1,l2)],[],2);
  % top/bottom pairing and wall translation pairing on P2 nodes
  top = find(abs(p2_points(:,2)-0.5)<tol); bottom = find(abs(p2_points(:,2)+0.5)<tol);
  checks.top_bottom_pairing = numel(top)==numel(bottom) && ...
    max(abs(sort(p2_points(top,1))-sort(p2_points(bottom,1))))<tol;
  walls = cell(4,1); wall_ok = true;
  for w = 1:4
    ids = abs(p2_points(:,1)-(w-2.5))<tol; walls{w} = sort(p2_points(ids,2));
    wall_ok = wall_ok && numel(walls{w})==2*cfg.subdivisions+1 && ...
      max(abs(walls{w}-(-0.5+(0:2*cfg.subdivisions)'/(2*cfg.subdivisions))))<1e-12;
  end
  checks.wall_translation_pairing = wall_ok;
  checks.only_grid_vertices_on_walls = wall_ok;
  checks.background_points = base.background_points; checks.deletable_points = base.deletable_points;
  checks.vertices = nv; checks.triangles = nt; checks.p2_nodes = size(p2_points,1);
  fields = {'interface_edges_found','constraints_found','interface_incidence_two', ...
    'edge_incidence','positive_orientation','cell_coverage', ...
    'material_sides','interface_single_cell','top_bottom_pairing','wall_translation_pairing'};
  for f = fields
    if ~checks.(f{1})
      checks.pass = false; checks.reason = [checks.reason,f{1},' failed; '];
    end
  end
  checks.det_min = det_min; checks.det_max = det_max; checks.det_ratio = det_ratio;
  checks.quality = quality; checks.min_angle = min_angle;
  mesh = struct('points',points,'triangles',triangles,'p2_points',p2_points, ...
    'triangle_p2',triangle_p2,'edges',edges,'interface_edges',interface_edges, ...
    'interface_theta',repmat(base.theta,3,1), ...
    'interface_cell',kron((-1:1)',ones(cfg.interface_segments,1)), ...
    'material',material,'cell_id',cell_id);
end

%% ==================== D2 bounded local edge flip ====================
% Design 5 step 4: flip one straight chord of an interface-adjacent bad element.
function [mesh,checks,flip] = LOCAL_flip_repair(config,cfg,base,mesh,checks,repair_timer)
  % For a bad element abc containing an interface edge and a non-constrained
  % interior edge ac shared with acd (same material and cell, patch off the
  % walls/top/bottom), replace abc, acd by abd, bcd if abcd is strictly convex,
  % the straight new edge bd meets no actual P2 patch edge except at shared
  % endpoints, and both new curved elements satisfy det_min > 0 and
  % det_max/det_min <= 20. Vertices and outer P2 midpoints are kept; bd gets
  % the arithmetic midpoint. Limits: 32 candidate checks, 16 accepted flips,
  % 30 s for all deletion/flip repair and re-checks of the level.
  rules = config.mesh_rules; L = rules.flip;
  flip = struct('checked',0,'accepted',0,'limit_hit',false,'outcome','', ...
    'trials',struct([]),'recheck_seconds',[]);
  constraint_keys = sort(base.constraints,2); interface_keys = sort(base.raw_interfaces,2);
  recheck_cost = 0; trial_cost = 0; stop = false;
  while ~stop
    bad = LOCAL_bad(checks,rules);
    if isempty(bad), flip.outcome = 'all bad elements removed'; break, end
    [~,order] = sortrows([mesh.cell_id(bad),bad]); bad = bad(order);
    progressed = false;
    for t = bad'
      tri = mesh.triangles(t,:); keys = sort([tri([1,2]);tri([2,3]);tri([3,1])],2);
      if ~any(ismember(keys,interface_keys,'rows')), continue, end
      candidates = find(~ismember(keys,constraint_keys,'rows'));
      [~,order] = sortrows(keys(candidates,:)); candidates = candidates(order)';
      for e = candidates
        % limits are checked before every operation (design 5, D2)
        elapsed = toc(repair_timer);
        if flip.checked>=L.max_checks || flip.accepted>=L.max_flips || ...
            elapsed+trial_cost+recheck_cost>rules.repair_seconds
          flip.limit_hit = true; stop = true;
          flip.outcome = sprintf(['limit reached before the next operation: %d checks, ', ...
            '%d flips, %.2fs elapsed (+%.2fs predicted)'],flip.checked,flip.accepted, ...
            elapsed,trial_cost+recheck_cost);
          break
        end
        timer = tic; flip.checked = flip.checked+1;
        [trial,new] = LOCAL_flip_trial(config,base,mesh,checks,t,e);
        if trial.accepted
          triangles = mesh.triangles; triangles(t,:) = new.tri(1,:); triangles(new.neighbor,:) = new.tri(2,:);
          rebuild = tic;
          [mesh_new,checks_new] = LOCAL_mesh_build(config,cfg,base,triangles,mesh.material,mesh.cell_id);
          recheck_cost = toc(rebuild); flip.recheck_seconds(end+1) = recheck_cost;
          bad_new = LOCAL_bad(checks_new,rules);
          patch_ok = ~any(ismember([t;new.neighbor],bad_new)) && isempty(setdiff(bad_new,bad));
          trial.gates.post_rebuild_structural = checks_new.pass;
          trial.gates.post_rebuild_no_new_bad = patch_ok;
          if checks_new.pass && patch_ok
            trial.after_p2 = mesh_new.p2_points(mesh_new.triangle_p2([t,new.neighbor],:),:);
            trial.bad_after = numel(bad_new);
            mesh = mesh_new; checks = checks_new; flip.accepted = flip.accepted+1; progressed = true;
          else
            trial.accepted = false;
            trial.reason = ['post-rebuild check failed: ',checks_new.reason];
          end
        end
        trial.seconds = toc(timer);
        trial_cost = max(trial_cost,trial.seconds-trial.accepted*recheck_cost);
        flip.trials = LOCAL_append(flip.trials,trial);
        fprintf('  FLIP check %d element %d edge [%d %d]: %s %s (%.3fs)\n',flip.checked,t, ...
          trial.edge,LOCAL_tf(trial.accepted),trial.reason,trial.seconds);
        if trial.accepted, break, end
      end
      if progressed || stop, break, end
    end
    if ~progressed && ~stop
      flip.outcome = sprintf('no admissible flip for %d remaining bad elements',numel(bad)); break
    end
  end
end

function [trial,new] = LOCAL_flip_trial(config,base,mesh,checks,t,e)
  % One candidate patch: bad element t = (a,b,c) counter-clockwise with the
  % candidate chord e = ac opposite b, neighbour (a,c,d); proposal abd, bcd.
  rules = config.mesh_rules; L = rules.flip; pts = base.points; nv = size(pts,1);
  tri = mesh.triangles(t,:); k = mod(e+1,3)+1;        % position of b (opposite edge e)
  b = tri(k); c = tri(mod(k,3)+1); a = tri(mod(k+1,3)+1);
  new = struct('tri',[],'neighbor',NaN);
  gates = struct('interior_two_owners',false,'not_constraint',true,'distinct_vertices',false, ...
    'same_material',false,'same_cell',false,'off_walls_top_bottom',false,'strictly_convex',false, ...
    'new_edge_absent',false,'no_curved_crossing',false,'new_det_positive',false, ...
    'new_det_ratio',false);
  trial = struct('element',t,'neighbor',NaN,'edge',sort([a,c]),'vertices',[a,b,c,NaN], ...
    'coordinates',[],'old_p2',[],'new_p2',[],'after_p2',[],'material',mesh.material(t), ...
    'cell',mesh.cell_id(t),'old_det',[checks.det_min(t),checks.det_max(t),checks.det_ratio(t)], ...
    'new_det',[],'gates',gates,'accepted',false,'reason','','bad_after',NaN,'seconds',0, ...
    'crossing',struct([]));
  owners = find(any(mesh.triangles==a,2) & any(mesh.triangles==c,2));
  gates.interior_two_owners = numel(owners)==2;
  if ~gates.interior_two_owners
    trial.gates = gates; trial.reason = 'chord is not shared by exactly two elements'; return
  end
  m = setdiff(owners,t); d = setdiff(mesh.triangles(m,:),[a,c]);
  trial.neighbor = m; trial.vertices = [a,b,c,d];
  gates.distinct_vertices = numel(d)==1 && numel(unique([a,b,c,d]))==4;
  gates.same_material = mesh.material(m)==mesh.material(t);
  gates.same_cell = mesh.cell_id(m)==mesh.cell_id(t);
  if gates.distinct_vertices, gates.off_walls_top_bottom = ~any(base.on_boundary([a,b,c,d])); end
  if ~(gates.distinct_vertices && gates.same_material && gates.same_cell && gates.off_walls_top_bottom)
    trial.gates = gates; trial.reason = 'patch not same-material/same-cell interior'; return
  end
  P = pts([a,b,c,d],:); trial.coordinates = P;
  edge_mid = @(u,v)mesh.p2_points(nv+find(ismember(mesh.edges,sort([u,v]),'rows')),:);
  trial.old_p2 = [mesh.p2_points(mesh.triangle_p2(t,:),:);mesh.p2_points(mesh.triangle_p2(m,:),:)];
  % strict convexity of abcd (either orientation), relative to the patch diameter
  pairs = nchoosek(1:4,2); ell = max(vecnorm(P(pairs(:,1),:)-P(pairs(:,2),:),2,2)); turn = zeros(4,1);
  for i = 1:4
    u = P(i,:)-P(mod(i-2,4)+1,:); v = P(mod(i,4)+1,:)-P(i,:); turn(i) = u(1)*v(2)-u(2)*v(1);
  end
  gates.strictly_convex = all(turn>L.convex_factor*ell^2) || all(turn<-L.convex_factor*ell^2);
  gates.new_edge_absent = ~ismember(sort([b,d]),mesh.edges,'rows');
  if ~(gates.strictly_convex && gates.new_edge_absent)
    trial.gates = gates; trial.reason = 'patch not strictly convex or bd already exists'; return
  end
  % the straight new edge bd against the actual P2 outer patch edges
  outer = [a,b;b,c;c,d;d,a]; clear_all = true; crossing = struct([]);
  for i = 1:4
    u = outer(i,1); v = outer(i,2); shared = u; other = v;
    if ~any(u==[b,d]), shared = v; other = u; end
    [ok,why] = LOCAL_segment_curve_clear(pts(shared,:),edge_mid(u,v),pts(other,:), ...
      pts(b,:),pts(d,:),L.crossing_tolerance);
    crossing = LOCAL_append(crossing,struct('edge',[u,v],'clear',ok,'why',why));
    clear_all = clear_all && ok;
  end
  trial.crossing = crossing; gates.no_curved_crossing = clear_all;
  if ~clear_all
    trial.gates = gates; trial.reason = 'new edge meets a curved patch edge or is undecidable'; return
  end
  % proposal abd, bcd (positively reoriented) and their full-element det extrema
  T = [a,b,d;b,c,d]; nodes = cell(2,1); new_det = zeros(2,3);
  bd_mid = (pts(b,:)+pts(d,:))/2;
  for j = 1:2
    r = T(j,:); o = pts(r,:); s = (o(2,1)-o(1,1))*(o(3,2)-o(1,2))-(o(2,2)-o(1,2))*(o(3,1)-o(1,1));
    if s<0, r = r([1,3,2]); T(j,:) = r; end
    mids = zeros(3,2);
    for q = 1:3
      u = r(q); v = r(mod(q,3)+1);
      if isequal(sort([u,v]),sort([b,d])), mids(q,:) = bd_mid; else, mids(q,:) = edge_mid(u,v); end
    end
    nodes{j} = [pts(r,:);mids];
    [dmin,dmax] = LOCAL_quadratic_triangle_extrema(LOCAL_det_coefficients(LOCAL_map_coefficients(nodes{j})));
    new_det(j,:) = [dmin,dmax,dmax/dmin];
  end
  trial.new_p2 = [nodes{1};nodes{2}]; trial.new_det = new_det;
  gates.new_det_positive = all(new_det(:,1)>0);
  gates.new_det_ratio = gates.new_det_positive && all(new_det(:,3)<=rules.det_ratio_max);
  trial.gates = gates;
  if ~(gates.new_det_positive && gates.new_det_ratio)
    trial.reason = sprintf('new elements det ratio [%.4g %.4g]',new_det(1,3),new_det(2,3)); return
  end
  trial.accepted = true; trial.reason = sprintf('new elements det ratio [%.4g %.4g]', ...
    new_det(1,3),new_det(2,3));
  new = struct('tri',T,'neighbor',m);
end

function [clear,why] = LOCAL_segment_curve_clear(P,M,Q,b,d,tol)
  % Curved P2 edge q(t) = P + t v1 + t^2 v2, t in [0,1], with P in {b,d}:
  % v1 = 4M-3P-Q, v2 = 2P+2Q-4M. Its meetings with the line through b,d solve
  % f(t) = det(q(t)-b, d-b) = t (c1 + c2 t); t = 0 is the shared endpoint and
  % the only other root is t* = -c1/c2. Near-double roots, collinearity or a
  % meeting within tolerance of the segment ends are rejected as undecidable.
  v1 = 4*M-3*P-Q; v2 = 2*P+2*Q-4*M; w = d-b;
  cr = @(u,v)u(1)*v(2)-u(2)*v(1);
  c1 = cr(v1,w); c2 = cr(v2,w); scale = norm(w)*(norm(v1)+norm(v2));
  clear = false;
  if abs(c1)<=tol*scale, why = 'tangent or collinear at the shared endpoint'; return, end
  if abs(c2)<=tol*scale, clear = true; why = 'no second root'; return, end
  ts = -c1/c2;
  if ts<-tol || ts>1+tol, clear = true; why = sprintf('second root t=%.6g outside [0,1]',ts); return, end
  if abs(ts)<=tol || abs(ts-1)<=tol, why = sprintf('second root t=%.6g at an edge end',ts); return, end
  q = P+ts*v1+ts^2*v2; sd = dot(q-b,w)/dot(w,w);
  if sd<-tol || sd>1+tol
    clear = true; why = sprintf('meets the line at s=%.6g outside segment bd',sd); return
  end
  if abs(sd)<=tol || abs(sd-1)<=tol, why = sprintf('meeting at s=%.6g undecidable',sd); return, end
  why = sprintf('curved edge crosses bd at t=%.6g, s=%.6g',ts,sd);
end

function text = LOCAL_tf(value)
  if value, text = 'ACCEPT'; else, text = 'reject'; end
end


function templates = LOCAL_templates(config,cfg,mesh)
  tol = config.mesh_rules.coordinate_tolerance; beta = config.model.beta*config.model.d;
  s = cfg.subdivisions; n = 2*s; checks = struct('pass',true,'reason','');
  names = {'left','center','right'}; walls_x = {[-0.5,-1.5],[-0.5,0.5],[0.5,1.5]};
  templates = struct('n',n,'beta',beta,'quadrature_order',cfg.quadrature_order);
  free_dofs = zeros(1,3);
  for c = -1:1
    name = names{c+2}; ids = find(mesh.cell_id==c);
    [nodes,~,local] = unique(mesh.triangle_p2(ids,:)); tri = reshape(local,[],6);
    xy = mesh.p2_points(nodes,:); material = mesh.material(ids);
    [K_full,M_full,area,inclusion_area] = LOCAL_assemble(xy,tri,material,cfg.quadrature_order);
    nn = size(xy,1);
    top = find(abs(xy(:,2)-0.5)<tol); bottom = find(abs(xy(:,2)+0.5)<tol);
    [~,a] = sort(xy(top,1)); top = top(a); [~,a] = sort(xy(bottom,1)); bottom = bottom(a);
    pairing = numel(top)==numel(bottom) && max(abs(xy(top,1)-xy(bottom,1)))<tol;
    master = (1:nn)'; master(top) = bottom; free = setdiff((1:nn)',top);
    [~,col] = ismember(master,free); phase = ones(nn,1); phase(top) = exp(1i*beta);
    Qqp = sparse(1:nn,col,phase,nn,numel(free));
    qp_defect = norm(Qqp(top,:)-exp(1i*beta)*Qqp(bottom,:),'fro');
    Kraw = Qqp'*K_full*Qqp; Mraw = Qqp'*M_full*Qqp;
    kdef = norm(Kraw-Kraw','fro')/norm(Kraw,'fro'); mdef = norm(Mraw-Mraw','fro')/norm(Mraw,'fro');
    K = (Kraw+Kraw')/2; M = (Mraw+Mraw')/2;
    [~,mflag] = chol(M(symamd(M),symamd(M)));
    fx = xy(free,1); fy = xy(free,2); wall = cell(1,2);
    for w = 1:2
      list = find(abs(fx-walls_x{c+2}(w))<tol); [~,a] = sort(fy(list)); wall{w} = list(a);
    end
    wall_y = [fy(wall{1}),fy(wall{2})];
    expected = -0.5+(0:n-1)'/n;
    wall_ok = numel(wall{1})==n && numel(wall{2})==n && max(abs(wall_y(:)-[expected;expected]))<1e-12;
    W = [wall{1};wall{2}]; I = setdiff((1:numel(free))',W);
    template = struct('name',name,'cell',c,'xy',xy,'tri6',tri,'material',material, ...
      'nodes',nodes,'element_ids',ids,'K_full',K_full,'M_full',M_full,'Qqp',Qqp,'K',K,'M',M, ...
      'free',free,'wall',W,'interior',I,'wall_y',expected,'top',top,'bottom',bottom, ...
      'area',area,'inclusion_area',inclusion_area);
    % fixed sparsity: AMD order for the centre Cholesky and symbolic fill for memory estimate
    pattern = spones(K(I,I))+spones(M(I,I));
    template.amd = amd(pattern);
    template.symbolic_nnz = sum(symbfact(pattern(template.amd,template.amd)));
    templates.(name) = template;
    free_dofs(c+2) = numel(free);
    check = struct('cell',c,'stiffness_hermitian_defect',kdef,'mass_hermitian_defect',mdef, ...
      'mass_chol_flag',mflag,'qp_defect',qp_defect,'top_bottom_pairing',pairing, ...
      'wall_pairing',wall_ok,'area',area,'area_defect',abs(area-1), ...
      'inclusion_area',inclusion_area,'interior_dofs',numel(I),'free_dofs',numel(free), ...
      'symbolic_chol_nnz',template.symbolic_nnz);
    pass = kdef<=config.gates.matrix_hermitian && mdef<=config.gates.matrix_hermitian && ...
      mflag==0 && qp_defect<=config.gates.qp_defect && pairing && wall_ok && abs(area-1)<1e-10;
    check.pass = pass; checks.(name) = check;
    if ~pass, checks.pass = false; checks.reason = [checks.reason,name,' matrix check failed; ']; end
  end
  % exact inclusion areas versus the curved-P2 approximation
  exact = LOCAL_exact_areas(config);
  checks.inclusion_area_exact = exact;
  checks.inclusion_area_defect = [templates.left.inclusion_area-exact(1), ...
    templates.center.inclusion_area-exact(2),templates.right.inclusion_area-exact(3)];
  % wall trace mass: 1D P2 mass with the quasi-periodic closure, per wall
  Wwall = LOCAL_wall_mass(s,beta);
  templates.wall_mass_single = Wwall;
  templates.wall_mass = blkdiag(Wwall,Wwall);
  templates.wall_chol = chol(templates.wall_mass);
  checks.wall_mass_hermitian_defect = norm(Wwall-Wwall','fro')/norm(Wwall,'fro');
  templates.checks = checks;
  templates.dimensions = struct('wall_dofs',n,'small_order',2*n,'free_dofs',free_dofs, ...
    'interior_dofs',[numel(templates.left.interior),numel(templates.center.interior), ...
    numel(templates.right.interior)],'p2_nodes',[size(templates.left.xy,1), ...
    size(templates.center.xy,1),size(templates.right.xy,1)]);
end

function W = LOCAL_wall_mass(s,beta)
  n = 2*s; h = 1/s; local = h/30*[4,2,-1;2,16,2;-1,2,4];
  rows = zeros(9*s,1); cols = rows; vals = rows; q = 0;
  for m = 0:s-1
    ids = [2*m,2*m+1,2*m+2];
    for a = 1:3
      for b = 1:3
        q = q+1; rows(q) = ids(a)+1; cols(q) = ids(b)+1; vals(q) = local(a,b);
      end
    end
  end
  Mfull = sparse(rows,cols,vals,n+1,n+1);
  Qw = sparse([1:n,n+1],[1:n,1],[ones(1,n),exp(1i*beta)],n+1,n);
  W = full(Qw'*Mfull*Qw); W = (W+W')/2;
end

function exact = LOCAL_exact_areas(config)
  theta = 2*pi*(0:8191)'/8192; exact = zeros(1,3);
  for c = -1:1
    xy = LOCAL_curve(config,c,theta); xy(:,1) = xy(:,1)-c*config.model.L;
    d = 2*pi/8192; dx = LOCAL_spectral_derivative(xy(:,1))/d; dy = LOCAL_spectral_derivative(xy(:,2))/d;
    exact(c+2) = 0.5*sum(xy(:,1).*dy-xy(:,2).*dx)*d;
  end
end

function dv = LOCAL_spectral_derivative(v)
  n = numel(v); k = [0:n/2-1,0,-n/2+1:-1]'*2*pi/n;
  dv = real(ifft(1i*k.*fft(v)));
end

function [K,M,area,inclusion_area] = LOCAL_assemble(xy,tri,material,order)
  nt = size(tri,1); nd = size(xy,1); X = reshape(xy(tri,1),nt,6); Y = reshape(xy(tri,2),nt,6);
  [lambda,weights] = LOCAL_quadrature(order); kval = zeros(nt,36); mval = zeros(nt,36);
  areas = zeros(nt,1);
  for q = 1:numel(weights)
    [basis,G] = LOCAL_basis(lambda(q,:));
    j11 = X*G(1,:)'; j12 = X*G(2,:)'; j21 = Y*G(1,:)'; j22 = Y*G(2,:)';
    d = j11.*j22-j12.*j21; w = weights(q)*d;
    dx = (j22.*G(1,:)-j21.*G(2,:))./d; dy = (-j12.*G(1,:)+j11.*G(2,:))./d;
    for b = 1:6
      for a = 1:6
        v = a+6*(b-1); kval(:,v) = kval(:,v)+w.*(dx(:,a).*dx(:,b)+dy(:,a).*dy(:,b));
        mval(:,v) = mval(:,v)+material.*w*basis(a)*basis(b);
      end
    end
    areas = areas+w;
  end
  rows = zeros(nt,36); cols = rows;
  for b = 1:6, for a = 1:6, v = a+6*(b-1); rows(:,v) = tri(:,a); cols(:,v) = tri(:,b); end, end
  K = sparse(rows(:),cols(:),kval(:),nd,nd); M = sparse(rows(:),cols(:),mval(:),nd,nd);
  area = sum(areas); inclusion_area = sum(areas(material~=1));
end


function [S,E,info] = LOCAL_eliminate(config,template,mu,method,want_extension)
  A = template.K-mu*template.M; I = template.interior; W = template.wall;
  AII = A(I,I); AIW = A(I,W); nI = numel(I); nW = numel(W);
  info = struct('valid',true,'reason','','backward',NaN,'backward_num',NaN, ...
    'backward_den',NaN,'condest',NaN,'chol_flag',NaN);
  E = [];
  rs = full(sum(abs(AII),2));
  if any(rs==0), info.valid = false; info.reason = 'ZERO_ROW'; S = []; return, end
  T = spdiags(1./sqrt(rs),0,nI,nI); B = T*AII*T;
  try
    if strcmp(method,'chol')
      p = template.amd; [Rc,flag] = chol(B(p,p)); info.chol_flag = flag;
      if flag ~= 0, info.valid = false; info.reason = 'CENTER_CHOLESKY_FAILED'; S = []; return, end
      solve = @(c)LOCAL_chol_solve(Rc,p,c); solve_h = solve;
    else
      [L,U,P,Q,R] = lu(B);
      solve = @(c)Q*(U\(L\(P*(R\c))));
      solve_h = @(c)R\(P'*(L'\(U'\(Q'*c))));
    end
  catch error_object
    info.valid = false; info.reason = ['FACTORIZATION_EXCEPTION: ',error_object.message]; S = []; return
  end
  block = config.solver.rhs_block; E = complex(zeros(nI,nW));
  norm_A = norm(AII,1); worst = 0; worst_num = 0; worst_den = 1;
  for j = 1:block:nW
    J = j:min(j+block-1,nW);
    rhs = full(-AIW(:,J)); X = T*solve(T*rhs);
    r = AII*X-rhs;
    num = sum(abs(r),1); den = norm_A*sum(abs(X),1)+sum(abs(rhs),1);
    [value,at] = max(num./max(den,realmin));
    if value>worst, worst = value; worst_num = num(at); worst_den = den(at); end
    E(:,J) = X;
  end
  info.backward = worst; info.backward_num = worst_num; info.backward_den = worst_den;
  afun = @(flag,X)LOCAL_normest_handle(flag,X,nI,solve,solve_h);
  info.condest = norm(B,1)*normest1(afun);
  S = full(A(W,W)+A(W,I)*E);
  if ~(info.backward<=config.gates.cell_backward)
    info.valid = false; info.reason = sprintf('CELL_BACKWARD %.3e',info.backward);
  elseif ~(info.condest<=config.gates.cell_condest)
    info.valid = false; info.reason = sprintf('CELL_CONDEST %.3e',info.condest);
  end
  if ~want_extension, E = []; end
end

function x = LOCAL_chol_solve(Rc,p,c)
  x = zeros(size(c),'like',complex(c)); x(p,:) = Rc\(Rc'\c(p,:));
end

function y = LOCAL_normest_handle(flag,X,n,solve,solve_h)
  switch flag
    case 'dim', y = n;
    case 'real', y = false;
    case 'notransp', y = solve(X);
    case 'transp', y = solve_h(X);
  end
end

function [D,Pout,info,qzb] = LOCAL_dtn(config,S,n)
  % I9.6 change: qzb returns the raw pencil, the complex QZ factors and the
  % ordered (stable-first) blocks for read-only audit.
  g = config.gates;
  S00 = S(1:n,1:n); S01 = S(1:n,n+1:end); S10 = S(n+1:end,1:n); S11 = S(n+1:end,n+1:end);
  Acal = [-(S11+S00),-S10;eye(n),zeros(n)]; Bcal = [S01,zeros(n);zeros(n),eye(n)];
  [AA,BB,Qz,Zz] = qz(Acal,Bcal,'complex');
  qzb = struct('Acal',Acal,'Bcal',Bcal,'AA',AA,'BB',BB,'AAs',[],'BBs',[],'Zs',[]);
  alpha = diag(AA); gamma = diag(BB);
  scale = norm(Acal,'fro')+norm(Bcal,'fro');
  magnitude = abs(alpha)+abs(gamma);
  degenerate = magnitude <= g.qz_degenerate_factor*2*n*eps*scale;
  gap = abs(abs(alpha)-abs(gamma))./magnitude;
  stable = abs(alpha)<abs(gamma);
  info = struct('valid',true,'reason','','stable_count',nnz(stable), ...
    'degenerate_count',nnz(degenerate),'min_magnitude_relative',min(magnitude)/scale, ...
    'unit_gap_min',min(gap),'z0_rcond',NaN,'invariance',NaN,'lower_block',NaN, ...
    'riccati',NaN,'riccati_num',NaN,'riccati_den',NaN,'hermitian_defect',NaN, ...
    'consistency',NaN,'consistency_rcond',NaN,'pairing_max',NaN,'pairing_count',0, ...
    'spectral_radius',NaN,'stable_abs',[],'stable_multipliers',[]);
  D = []; Pout = [];
  reasons = {};
  if any(degenerate), reasons{end+1} = sprintf('QZ_DEGENERATE %d',nnz(degenerate)); end
  if any(gap<=g.unit_gap), reasons{end+1} = sprintf('UNIT_CIRCLE_GAP %.3e',min(gap)); end
  if nnz(stable)~=n, reasons{end+1} = sprintf('STABLE_COUNT %d~=%d',nnz(stable),n); end
  % reciprocal-conjugate pairing diagnostic of finite nonzero multipliers
  finite = abs(alpha)>eps*scale & abs(gamma)>eps*scale;
  zeta = alpha(finite)./gamma(finite);
  band = abs(zeta)<g.pairing_band & abs(zeta)>1/g.pairing_band; zb = zeta(band);
  if ~isempty(zb)
    mismatch = zeros(numel(zb),1);
    for j = 1:numel(zb)
      target = 1/conj(zb(j)); mismatch(j) = min(abs(zeta-target))/abs(target);
    end
    info.pairing_max = max(mismatch); info.pairing_count = numel(zb);
  end
  if ~isempty(reasons)
    info.valid = false; info.reason = strjoin(reasons,'; '); return
  end
  [AAs,BBs,Qs,Zs] = ordqz(AA,BB,Qz,Zz,stable);
  qzb.AAs = AAs; qzb.BBs = BBs; qzb.Zs = Zs;
  Z = Zs(:,1:n); Z1 = Z(1:n,:); Z0 = Z(n+1:end,:); Y = Qs(1:n,:)';
  info.z0_rcond = rcond(Z0);
  normA = norm(Acal,'fro'); normB = norm(Bcal,'fro');
  info.invariance = (norm(Acal*Z-Y*AAs(1:n,1:n),'fro')+norm(Bcal*Z-Y*BBs(1:n,1:n),'fro'))/ ...
    ((normA+normB)*norm(Z,'fro'));
  Ts = BBs(1:n,1:n)\AAs(1:n,1:n);
  info.lower_block = norm(Z1-Z0*Ts,'fro')/max(norm(Z1,'fro'),norm(Z0*Ts,'fro'));
  alpha_s = diag(AAs(1:n,1:n)); gamma_s = diag(BBs(1:n,1:n));
  info.stable_multipliers = alpha_s./gamma_s; info.stable_abs = sort(abs(info.stable_multipliers),'descend');
  info.spectral_radius = info.stable_abs(1);
  if ~(info.z0_rcond>g.z0_rcond)
    info.valid = false; info.reason = sprintf('Z0_RCOND %.3e',info.z0_rcond); return
  end
  Pout = Z1/Z0;
  residual = S01*Pout^2+(S11+S00)*Pout+S10;
  info.riccati_num = norm(residual,'fro');
  info.riccati_den = norm(S01,'fro')*norm(Pout,'fro')^2+norm(S11+S00,'fro')*norm(Pout,'fro')+norm(S10,'fro');
  info.riccati = info.riccati_num/info.riccati_den;
  D = S00+S01*Pout;
  info.hermitian_defect = norm(D-D','fro')/max(1,norm(D,'fro'));
  info.consistency_rcond = rcond(S11+D);
  if info.consistency_rcond>g.consistency_rcond
    Dc = S00-S01*((S11+D)\S10);
    info.consistency = norm(D-Dc,'fro')/max(norm(D,'fro'),realmin);
  end
  reasons = {};
  if ~(info.invariance<=g.invariance), reasons{end+1} = sprintf('INVARIANCE %.3e',info.invariance); end
  if ~(info.riccati<=g.riccati), reasons{end+1} = sprintf('RICCATI %.3e',info.riccati); end
  if ~(info.hermitian_defect<=g.dtn_hermitian), reasons{end+1} = sprintf('DTN_HERMITIAN %.3e',info.hermitian_defect); end
  if ~isnan(info.consistency) && ~(info.consistency<=g.dtn_consistency)
    reasons{end+1} = sprintf('DTN_CONSISTENCY %.3e',info.consistency);
  end
  if ~isempty(reasons), info.valid = false; info.reason = strjoin(reasons,'; '); end
end

%% ==================== One frequency response ====================
% Both leads, then the centre; every frequency rebuilds the DtN from scratch.
function [res,ext] = LOCAL_evaluate(config,templates,k,want_extension)
  mu = k^2; n = templates.n;
  res = struct('k',k,'mu',mu,'valid',true,'reason_left','','reason_right','', ...
    'reason_center','','times',struct('lead_elimination',0,'qz_dtn',0,'center_small',0), ...
    'cell',struct(),'dtn',struct(),'lambda',[],'V',[],'H_norm',NaN, ...
    'H_hermitian_defect',NaN,'F_hermitian_defect',NaN,'rss_bytes',NaN);
  ext = struct();
  res.rss_bytes = LOCAL_rss();
  for side = {'left','right'}
    name = side{1}; t = templates.(name);
    LOCAL_memory_gate(config,['lead ',name],LOCAL_cell_bytes(config,t,want_extension),res.rss_bytes);
    timer = tic;
    [S,E,info] = LOCAL_eliminate(config,t,mu,'lu',want_extension);
    res.times.lead_elimination = res.times.lead_elimination+toc(timer);
    res.cell.(name) = info;
    if ~info.valid
      res.valid = false; res.(['reason_',name]) = info.reason;
      res.dtn.(name) = struct(); continue
    end
    timer = tic;
    [D,Pout,dinfo,qzb] = LOCAL_dtn(config,S,n);
    res.times.qz_dtn = res.times.qz_dtn+toc(timer);
    res.dtn.(name) = rmfield(dinfo,{'stable_multipliers'});
    if ~dinfo.valid
      res.valid = false; res.(['reason_',name]) = dinfo.reason; continue
    end
    res.(['D_',name]) = D;
    if want_extension
      ext.(name) = struct('S',S,'E',E,'D',D,'Pout',Pout,'multipliers',dinfo.stable_multipliers, ...
        'qz',qzb);
    end
  end
  if ~res.valid, return, end
  t = templates.center;
  LOCAL_memory_gate(config,'center',LOCAL_cell_bytes(config,t,want_extension),res.rss_bytes);
  timer = tic;
  [Sc,Ec,info] = LOCAL_eliminate(config,t,mu,'chol',want_extension);
  res.cell.center = info;
  if ~info.valid
    res.valid = false; res.reason_center = info.reason;
    res.times.center_small = res.times.center_small+toc(timer); return
  end
  F = Sc+blkdiag(res.D_left,res.D_right);
  Rw = templates.wall_chol;
  H = (Rw')\F/Rw;
  res.F_hermitian_defect = norm(F-F','fro')/max(1,norm(F,'fro'));
  res.H_hermitian_defect = norm(H-H','fro')/max(1,norm(H,'fro'));
  if ~(res.H_hermitian_defect<=config.gates.h_hermitian)
    res.valid = false; res.reason_center = sprintf('H_HERMITIAN %.3e',res.H_hermitian_defect);
    res.times.center_small = res.times.center_small+toc(timer); return
  end
  Hs = (H+H')/2;
  [V,L] = eig(Hs); [lambda,order] = sort(real(diag(L))); V = V(:,order);
  res.lambda = lambda; res.V = V; res.H_norm = max(abs(lambda));
  res.times.center_small = res.times.center_small+toc(timer);
  if want_extension
    ext.center = struct('S',Sc,'E',Ec,'F',F,'H',H);
  end
  res = rmfield(res,intersect(fieldnames(res),{'D_left','D_right'}));
end

function bytes = LOCAL_cell_bytes(config,t,want_extension)
  nI = numel(t.interior); nW = numel(t.wall);
  factor = config.solver.lu_fill_allowance*2*16*t.symbolic_nnz;   % L and U, complex
  bytes = factor+16*nI*nW*(1+want_extension)+3*16*nnz(t.K);
end


function gap = LOCAL_gap(lambda,index)
  others = lambda; others(index) = []; gap = min(abs(others-lambda(index)));
end


function rss = LOCAL_rss()
  [flag,text] = system(sprintf('ps -o rss= -p %d',feature('getpid')));
  rss = NaN;
  if flag==0, rss = 1024*str2double(strtrim(text)); end
end

function LOCAL_memory_gate(config,label,bytes,rss)
  if nargin<4, rss = LOCAL_rss(); end
  if rss+bytes>config.resources.internal_gate_bytes
    error('i96:ResourceStop','Predicted %s memory %.0f + RSS %.0f exceeds %.0f bytes.', ...
      label,bytes,rss,config.resources.internal_gate_bytes);
  end
end


function LOCAL_json(path,value)
  text = jsonencode(LOCAL_jsonable(value),'PrettyPrint',true);
  fid = fopen(path,'w'); assert(fid>=0,'i96:IO','Cannot open JSON output.');
  cleanup = onCleanup(@()fclose(fid)); fprintf(fid,'%s\n',text);
end

function value = LOCAL_jsonable(value)
  % complex arrays become {real, imag}; structs and cells are visited recursively
  if isstruct(value)
    fields = fieldnames(value);
    for j = 1:numel(value)
      for f = 1:numel(fields), value(j).(fields{f}) = LOCAL_jsonable(value(j).(fields{f})); end
    end
  elseif iscell(value)
    value = cellfun(@LOCAL_jsonable,value,'UniformOutput',false);
  elseif isnumeric(value) && ~isreal(value)
    value = struct('real',real(value),'imag',imag(value));
  elseif issparse(value)
    value = full(value);
  end
end

%% ==================== P2 reference algebra (from I9.3/I4.1c) ====================
% Basis, Duffy quadrature and full-triangle Jacobian determinant extrema.
function [basis,G] = LOCAL_basis(l)
  gl = [-1,1,0;-1,0,1]; basis = [l.*(2*l-1),4*l(1)*l(2),4*l(2)*l(3),4*l(3)*l(1)];
  G = zeros(2,6);
  for j = 1:3, G(:,j) = (4*l(j)-1)*gl(:,j); end
  G(:,4) = 4*(l(1)*gl(:,2)+l(2)*gl(:,1));
  G(:,5) = 4*(l(2)*gl(:,3)+l(3)*gl(:,2));
  G(:,6) = 4*(l(3)*gl(:,1)+l(1)*gl(:,3));
end

function [lambda,weights] = LOCAL_quadrature(order)
  j = (1:order-1)'; b = j./sqrt(4*j.^2-1); [V,D] = eig(diag(b,1)+diag(b,-1));
  [x,idx] = sort(diag(D)); w = V(1,idx)'.^2; x = (x+1)/2;
  [r,s] = ndgrid(x,x); [wr,ws] = ndgrid(w,w); xi = r(:); eta = (1-xi).*s(:);
  lambda = [1-xi-eta,xi,eta]; weights = wr(:).*ws(:).*(1-xi);
end

function coefficients = LOCAL_map_coefficients(nodes)
  coefficients = [nodes(1,:);-3*nodes(1,:)-nodes(2,:)+4*nodes(4,:); ...
    -3*nodes(1,:)-nodes(3,:)+4*nodes(6,:);2*nodes(1,:)+2*nodes(2,:)-4*nodes(4,:); ...
    4*nodes(1,:)-4*nodes(4,:)+4*nodes(5,:)-4*nodes(6,:);2*nodes(1,:)+2*nodes(3,:)-4*nodes(6,:)];
end

function c = LOCAL_det_coefficients(map)
  a = map(2,:); b = map(3,:); d = map(4,:); e = map(5,:); f = map(6,:);
  cross2 = @(x,y)x(1)*y(2)-x(2)*y(1);
  c = [cross2(a,b),cross2(2*d,b)+cross2(a,e),cross2(e,b)+cross2(a,2*f), ...
    cross2(2*d,e),4*cross2(d,f),cross2(e,2*f)];
end

function value = LOCAL_q(c,x,y)
  value = c(1)+c(2)*x+c(3)*y+c(4)*x.^2+c(5)*x.*y+c(6)*y.^2;
end

function [minimum,maximum] = LOCAL_quadratic_triangle_extrema(c)
  % vertices, edge stationary points and the interior stationary point
  candidates = [0,0;1,0;0,1]; edges = [c(4),c(2);c(6),c(3);c(4)-c(5)+c(6),c(2)-c(3)+c(5)-2*c(6)];
  for j = 1:3
    if abs(edges(j,1))>eps*max(1,norm(edges(j,:),1))
      t = -edges(j,2)/(2*edges(j,1));
      if t>0 && t<1
        if j==1, p = [t,0]; elseif j==2, p = [0,t]; else, p = [t,1-t]; end
        candidates(end+1,:) = p; %#ok<AGROW>
      end
    end
  end
  H = [2*c(4),c(5);c(5),2*c(6)];
  if rcond(H)>64*eps
    p = -H\c(2:3)';
    if all(p>0) && sum(p)<1, candidates(end+1,:) = p'; end
  end
  values = LOCAL_q(c,candidates(:,1),candidates(:,2));
  minimum = min(values); maximum = max(values);
end

function y = LOCAL_rep(x,counts)
  % Column-vector repelem (MATLAB returns a row for a scalar input).
  y = reshape(repelem(x(:),counts(:)),[],1);
end
