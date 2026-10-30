function result = endpoint_inertia(output_dir,p)
%ENDPOINT_INERTIA Ordinary full-core endpoint inertia for a periodic waveguide.
% Purpose: Evaluate only mu=2.40 and 2.46 for g12/P2 or an explicit P3 check.
% Main algorithm: true-material FEM assembly; two independent lead QZ/DtN
%   responses; T=Kc-mu*Mc+Ew'*diag(Dminus,Dplus)*Ew; sparse Hermitian LDL;
%   check nminus(T)=nminus(AII)+nminus(F) whenever center elimination succeeds.
% Based on: test/i10/refine-v1/refine_i102.m geometry, spaces, thin-band mass,
%   cell elimination and DtN helpers (copied below; see provenance.csv).
% Main changes: retain ALL constrained center DOFs; no root search, field
%   reconstruction or Stein sum. A center Dirichlet pole is not a lead gate.
% Numerical goal: a reproducible ORDINARY_DISCRETE_INERTIA_DIFFERENCE.
%   Neither an interval bulk gap nor absence of lead poles is certified.
% Input: output_dir is explicit; p=2 or 3. All parameters are in endpoint_config.
% Output: P2 results.mat; P3 results-p3.mat; per-order CSV/JSON/text summaries.
%   No documents, historical results, manifests or Git state are read.
  if nargin<2, p=2; end
  config = endpoint_config(p); started = tic;
  if ~isfolder(output_dir), mkdir(output_dir); end
  maxNumCompThreads(config.resources.threads);
  LOCAL_ledger('reset');
  ctx = struct('output_dir',output_dir,'started',started,'config',config, ...
    'progress_path',fullfile(output_dir,sprintf('progress-p%d.json',p)));
  result = struct('config',config,'environment',struct('matlab',version, ...
    'platform',computer,'pid',feature('getpid'),'threads',maxNumCompThreads), ...
    'status','RUNNING','rules',{{}},'elapsed_seconds',NaN);
  fprintf('ENTRY g12 P%d mu=[%.2f,%.2f], threads=%d\n',p,config.mu,maxNumCompThreads);
  try
    % --- stage 1: verify block inertia, geometry and conforming spaces ---
    result.selftest = LOCAL_inertia_selftest(config);
    LOCAL_progress(ctx,'mesh',struct('p',p));
    [mesh,geometry] = LOCAL_mesh(config); result.geometry = geometry;
    assert(strcmp(geometry.status,'PASS'),'endpoint:Geometry','%s',geometry.reason);
    spaces = cell(1,p); spaces{p} = LOCAL_space(config,mesh,p); sp = spaces{p};
    result.basis_checks = LOCAL_basis_checks(p);
    result.edge_checks = LOCAL_edge_traces(config,mesh,spaces);
    assert(all([result.basis_checks.pass]) && result.edge_checks.pass,'endpoint:Space','Basis/edge check failed.');
    names = {'left','center','right'};
    for j=1:3
      result.space_checks.(names{j}) = sp.(names{j}).checks;
      assert(sp.(names{j}).checks.pass,'endpoint:QP','QP/wall map failed.');
    end
    fprintf('MESH triangles=%d center_dofs=%d wall_per_side=%d\n', ...
      size(mesh.triangles,1),numel(sp.center.free),sp.n);
    % --- stage 2: two quadrature rules and exactly two endpoints per rule ---
    for r=1:numel(config.rules)
      rule = config.rules(r); LOCAL_progress(ctx,'location',struct('p',p,'rule',rule.name));
      band = LOCAL_band_locate(config,mesh,rule,spaces);
      assert(band.total_failures==0,'endpoint:Location','Thin-band ownership failed.');
      ops = LOCAL_operators(ctx,sp,band,rule,false,true);
      item = struct('name',rule.name,'assembly_checks',ops.checks,'band_checks', ...
        struct('total_points',band.total_points,'failures',band.total_failures, ...
        'tolerance_owners',band.total_tolerance_owner),'endpoints',{{}});
      c = ops.center;
      item.center = struct('K',c.K,'M',c.M,'M_h',c.M_nominal,'dM',c.M-c.M_nominal, ...
        'wall',c.wall,'interior',c.interior,'Qqp',c.Qqp);
      clear band
      for e=1:2
        mu = config.mu(e);
        LOCAL_progress(ctx,'endpoint',struct('p',p,'rule',rule.name,'endpoint',e,'mu',mu));
        ep = LOCAL_endpoint(config,ops,mu);
        item.endpoints{e}=ep;
        fprintf('ENDPOINT P%d %s mu=%.2f full=[%d,%d,%d] center=[%d,%d,%d] wall=[%d,%d,%d] Schur=%s\n', ...
          p,rule.name,mu,ep.full.counts,ep.center.counts,ep.wall.counts,ep.schur_status);
      end
      a=item.endpoints{1}; b=item.endpoints{2};
      item.N = b.full.counts(1)-a.full.counts(1);
      item.N_interval = [b.full.counts(1)-a.full.counts(1)-a.full.counts(2), ...
        b.full.counts(1)+b.full.counts(2)-a.full.counts(1)];
      item.status = 'ORDINARY_DISCRETE_INERTIA_DIFFERENCE';
      if any([a.full.counts(2),b.full.counts(2)]) || ~a.full.valid || ~b.full.valid
        item.status='UNRESOLVED';
      end
      difference = (b.T-a.T); difference=(difference+difference')/2;
      order=symamd(difference); [~,flag]=chol(-difference(order,order));
      item.monotonicity=struct('negative_definite_chol_flag',flag, ...
        'status','ORDINARY_TWO_ENDPOINT_DIFFERENCE_ONLY');
      result.rules{r}=item;
      fprintf('RULE P%d %s N=%d interval=[%d,%d] negative_difference_chol=%d\n', ...
        p,rule.name,item.N,item.N_interval,flag);
      clear ops item a b difference
    end
    % --- stage 3: rule sensitivity and reproducible output ---
    result.rule_sensitivity=LOCAL_rule_comparison(result.rules);
    result.status='ORDINARY_DISCRETE_INERTIA_DIFFERENCE';
    if any(cellfun(@(x)strcmp(x.status,'UNRESOLVED'),result.rules)), result.status='UNRESOLVED'; end
    schur_pass=all(cellfun(@(r)all(cellfun(@(e)strcmp(e.schur_status,'PASS'),r.endpoints)),result.rules));
    applicable_pass=all(cellfun(@(r)all(cellfun(@(e)~e.schur_applicable || ...
      strcmp(e.schur_status,'PASS'),r.endpoints)),result.rules));
    rule_pass=result.rule_sensitivity.N_equal && ...
      all(cellfun(@(e)e.full_inertia_equal,result.rule_sensitivity.endpoints));
    result.acceptance=struct('schur_all_pass',schur_pass,'schur_all_applicable_pass',applicable_pass, ...
      'quadrature_inertia_agrees',rule_pass, ...
      'pass',applicable_pass && rule_pass && ~strcmp(result.status,'UNRESOLVED'));
    if ~result.acceptance.pass, result.status='DIAGNOSTIC_ACCEPTANCE_FAILED'; end
    result.projected_gap_status='PROJECTED_GAP_UNCERTIFIED';
    result.lead_pole_status='LEAD_DIRICHLET_POLE_FREE_UNVERIFIED';
    result.continuous_count_status='NOT_CERTIFIED';
    result.elapsed_seconds=toc(started); result.timing=LOCAL_ledger('snapshot');
    LOCAL_progress(ctx,'save',struct('p',p,'all_endpoints_done',true));
    LOCAL_save_results(output_dir,p,result);
    LOCAL_progress(ctx,'done',struct('p',p,'all_endpoints_done',true));
    fprintf('DONE P%d status=%s matlab_seconds=%.3f\n',p,result.status,toc(started));
  catch problem
    result.status='FAILED'; result.failure=struct('identifier',problem.identifier,'message',problem.message);
    result.elapsed_seconds=toc(started);
    save(fullfile(output_dir,sprintf('failed-p%d.mat',p)),'result','-v7.3');
    rethrow(problem)
  end
end

%% ==================== Full center endpoint and inertia ====================
% New counting logic retains all center DOFs and treats center Schur data as a check.
function ep = LOCAL_endpoint(config,ops,mu)
  lead_names={'left','right'}; D=cell(1,2); leads=cell(1,2);
  for j=1:2
    t=ops.(lead_names{j});
    LOCAL_memory_gate(config,['lead ',lead_names{j}],LOCAL_cell_bytes(config,t,false,ops.n));
    [S,cell_info]=LOCAL_eliminate(config,t,mu,'lu');
    assert(cell_info.valid,'endpoint:LeadCell','%s: %s',lead_names{j},cell_info.reason);
    [D{j},P,dtn]=LOCAL_dtn(config,S,ops.n);
    if isnan(dtn.consistency), dtn.consistency_status='NOT_EVALUATED'; else, dtn.consistency_status='EVALUATED'; end
    assert(dtn.valid,'endpoint:LeadDtN','%s: %s',lead_names{j},dtn.reason);
    leads{j}=struct('side',lead_names{j},'cell',cell_info,'dtn',dtn,'P',P);
  end
  c=ops.center; A=c.K-mu*c.M; W=c.wall; I=c.interior;
  T=A; T(W,W)=T(W,W)+blkdiag(D{:});
  ep=struct('mu',mu,'D',{D},'leads',{leads},'T',T,'full',LOCAL_inertia(config,T), ...
    'center',LOCAL_inertia(config,A(I,I)),'wall',struct('counts',[NaN,NaN,NaN]), ...
    'schur_status','NOT_EVALUATED','schur_applicable',false);
  [Sc,info]=LOCAL_eliminate(config,c,mu,'lu'); ep.center_elimination=info;
  if info.valid
    F=Sc+blkdiag(D{:}); ep.F=F; ep.wall=LOCAL_inertia(config,sparse(F));
    if ep.full.valid && ep.center.valid && ep.wall.valid && ...
        all([ep.full.counts(2),ep.center.counts(2),ep.wall.counts(2)]==0)
      ep.schur_applicable=true;
      ep.schur_identity=isequal(ep.full.counts,ep.center.counts+ep.wall.counts);
      if ep.schur_identity, ep.schur_status='PASS'; else, ep.schur_status='FAIL'; end
    else
      ep.schur_identity=false; ep.schur_status='UNRESOLVED';
    end
  end
  % Small generalized eigenvalues are diagnostics in G=Kc+Mc, not C1 constants.
  ep.near_zero=LOCAL_near_zero(config,T,c.K+c.M);
end

function info = LOCAL_inertia(config,A)
  n=size(A,1); H=(A+A')/2;
  rows=full(sum(abs(H),2)); scale=1./sqrt(max(rows,realmin));
  C=spdiags(scale,0,n,n); B=C*H*C;
  info=struct('dimension',n,'nnz',nnz(A),'hermitian_defect', ...
    norm(A-A','fro')/max(norm(A,'fro'),realmin), ...
    'symmetrization_relative',norm(H-A,'fro')/max(norm(A,'fro'),realmin), ...
    'method','SPARSE_HERMITIAN_LDL','scale',scale);
  % Realification is an exact congruence representation of a complex form;
  % its positive/negative/null counts are twice the complex Hermitian counts.
  % MATLAB releases without sparse complex LDL use this equivalent sparse form.
  multiplicity=1; factor_input=B;
  pattern=spones(B); order=symamd(pattern);
  symbolic=sum(symbfact(pattern(order,order)));
  LOCAL_memory_gate(config,'full sparse LDL',16*symbolic*40+128*n);
  try
    [L,D,perm]=ldl(factor_input,'vector');
  catch problem
    if isreal(B) || ~contains(lower(problem.message),'complex'), rethrow(problem), end
    factor_input=[real(B),-imag(B);imag(B),real(B)]; multiplicity=2;
    info.method='REALIFIED_SPARSE_HERMITIAN_LDL'; info.native_exception=problem.message;
    pattern=spones(factor_input); order=symamd(pattern);
    symbolic=sum(symbfact(pattern(order,order)));
    LOCAL_memory_gate(config,'realified sparse LDL',16*symbolic*40+256*n);
    [L,D,perm]=ldl(factor_input,'vector');
  end
  threshold=config.inertia.pivot_relative*max(1,norm(D,inf));
  [counts,values,blocks]=LOCAL_pivot_counts(D,threshold);
  info.factor_counts=counts; info.counts=counts/multiplicity;
  info.pivot_threshold=threshold; info.min_abs_pivot=min(abs(values));
  info.pivot_values=values; info.pivot_block_sizes=blocks;
  info.two_by_two_blocks=nnz(blocks==2); info.factor_dimension=size(D,1);
  info.permutation=perm; info.symbolic_nnz=symbolic; info.factor_nnz=nnz(L)+nnz(D);
  info.factor_relative_residual=norm(factor_input(perm,perm)-L*D*L','fro')/max(norm(factor_input,'fro'),realmin);
  info.solve_backward=NaN;
  if counts(2)==0
    rhs=sin((1:size(D,1))'); x=zeros(size(rhs)); x(perm)=L'\(D\(L\rhs(perm)));
    info.solve_backward=norm(factor_input*x-rhs,1)/(norm(factor_input,1)*norm(x,1)+norm(rhs,1));
  end
  info.valid=all(mod(counts,multiplicity)==0) && ...
    info.factor_relative_residual<=config.inertia.factor_residual && ...
    info.hermitian_defect<=config.gates.h_hermitian;
end

function [counts,values,blocks] = LOCAL_pivot_counts(D,tolerance)
  n=size(D,1); values=zeros(n,1); blocks=[]; j=1;
  while j<=n
    if j<n && D(j+1,j)~=0
      block=full(D(j:j+1,j:j+1)); values(j:j+1)=real(eig((block+block')/2));
      blocks(end+1)=2; j=j+2; %#ok<AGROW>
    else
      values(j)=real(D(j,j)); blocks(end+1)=1; j=j+1; %#ok<AGROW>
    end
  end
  counts=[nnz(values < -tolerance),nnz(abs(values)<=tolerance),nnz(values>tolerance)];
end

function check = LOCAL_inertia_selftest(config)
  [c,~,b]=LOCAL_pivot_counts(sparse([0,1,0;1,0,0;0,0,0]),1e-12);
  assert(isequal(c,[1,1,1]) && any(b==2),'endpoint:PivotTest','2x2 pivot count failed.');
  test=LOCAL_inertia(config,sparse([0,1i;-1i,0]));
  assert(test.valid && isequal(test.counts,[1,0,1]),'endpoint:ComplexTest','Complex Hermitian inertia failed.');
  check=struct('pass',true,'block_test_counts',c,'complex_test',test);
end

function out = LOCAL_near_zero(config,T,G)
  n=size(T,1); H=(T+T')/2; k=min(config.inertia.near_eigenvalues,n-2);
  options=struct('tol',config.inertia.eigs_tol,'maxit',config.inertia.eigs_maxit, ...
    'disp',0,'v0',ones(n,1));
  try
    [V,D,flag]=eigs(H,G,k,0,options); values=real(diag(D));
    residual=vecnorm(H*V-G*V*D)./max(vecnorm(H*V)+vecnorm(G*V*D),realmin);
    [~,q]=sort(abs(values));
    out=struct('status','ORDINARY_G_NORMALIZED_DIAGNOSTIC','G','Kc+Mc', ...
      'values',values(q),'flag',flag,'relative_residuals',residual(q), ...
      'min_abs',min(abs(values)));
  catch problem
    out=struct('status','NOT_EVALUATED','message',problem.message,'min_abs',NaN);
  end
end

function out = LOCAL_rule_comparison(rules)
  a=rules{1}; b=rules{2};
  out=struct('mass_relative',norm(a.center.M-b.center.M,'fro')/norm(b.center.M,'fro'), ...
    'stiffness_relative',norm(a.center.K-b.center.K,'fro')/norm(b.center.K,'fro'), ...
    'N_equal',a.N==b.N,'endpoints',{{}});
  for e=1:2
    x=a.endpoints{e}; y=b.endpoints{e};
    out.endpoints{e}=struct('mu',x.mu,'full_inertia_equal',isequal(x.full.counts,y.full.counts), ...
      'T_relative',norm(x.T-y.T,'fro')/norm(y.T,'fro'), ...
      'D_left_relative',norm(x.D{1}-y.D{1},'fro')/norm(y.D{1},'fro'), ...
      'D_right_relative',norm(x.D{2}-y.D{2},'fro')/norm(y.D{2},'fro'));
  end
end

%% ==================== Output and resource status ====================
% All artifacts are written to the explicitly supplied output directory.
function LOCAL_save_results(output_dir,p,result)
  name='results.mat'; if p==3, name='results-p3.mat'; end
  save(fullfile(output_dir,name),'result','-v7.3');
  inertia_rows={}; lead_rows={};
  report=fopen(fullfile(output_dir,sprintf('report-p%d.txt',p)),'w'); cleaner=onCleanup(@()fclose(report));
  fprintf(report,'g12 P%d mu=[2.40,2.46]\n%s\nMatlab seconds: %.6f\n',p,result.status,result.elapsed_seconds);
  fprintf(report,'Continuous bulk gap: uncertified. Interval lead pole absence: unverified.\n');
  fprintf(report,'Counts are [negative, unresolved, positive]; unresolved does not mean exact zero.\n');
  fprintf(report,'Acceptance: Schur all PASS=%d, quadrature inertia agrees=%d, overall=%d\n', ...
    result.acceptance.schur_all_pass,result.acceptance.quadrature_inertia_agrees,result.acceptance.pass);
  for r=1:2
    item=result.rules{r}; fprintf(report,'\nRule %s N=%g interval=[%g,%g], -deltaT chol flag=%d\n', ...
      item.name,item.N,item.N_interval,item.monotonicity.negative_definite_chol_flag);
    for e=1:2
      ep=item.endpoints{e};
      for name={'full','center','wall'}
        q=ep.(name{1});
        if ~isfield(q,'valid'), continue, end
        inertia_rows(end+1,:)={p,item.name,ep.mu,name{1},q.dimension,q.counts(1),q.counts(2),q.counts(3), ...
          q.min_abs_pivot,q.pivot_threshold,q.two_by_two_blocks,q.factor_relative_residual, ...
          q.solve_backward,q.hermitian_defect,q.symmetrization_relative,q.valid,q.method}; %#ok<AGROW>
      end
      fprintf(report,'mu %.2f full %s center %s wall %s Schur %s; G-near-zero |lambda|min %.6e\n', ...
        ep.mu,mat2str(ep.full.counts),mat2str(ep.center.counts),mat2str(ep.wall.counts),ep.schur_status,ep.near_zero.min_abs);
      for j=1:2
        q=ep.leads{j}; d=q.dtn; c=q.cell;
        lead_rows(end+1,:)={p,item.name,ep.mu,q.side,c.valid,c.backward,c.condest,d.valid, ...
          d.stable_count,d.unit_gap_min,d.z0_rcond,d.invariance,d.riccati,d.hermitian_defect, ...
          d.consistency,d.consistency_status,d.consistency_rcond,d.spectral_radius}; %#ok<AGROW>
        fprintf(report,'  %s: unit gap %.3e Z0 rcond %.3e cell condest %.3e backward %.3e Riccati %.3e Hermitian %.3e consistency %.3e %s\n', ...
          q.side,d.unit_gap_min,d.z0_rcond,c.condest,c.backward,d.riccati,d.hermitian_defect,d.consistency,d.consistency_status);
      end
    end
  end
  writetable(cell2table(inertia_rows,'VariableNames',{'p','rule','mu','matrix','dimension','negative', ...
    'unresolved','positive','min_abs_pivot','pivot_threshold','two_by_two_blocks','factor_residual', ...
    'solve_backward','hermitian_defect','symmetrization_relative','valid','method'}), ...
    fullfile(output_dir,sprintf('inertia-p%d.csv',p)));
  writetable(cell2table(lead_rows,'VariableNames',{'p','rule','mu','side','cell_valid','cell_backward', ...
    'cell_condest','dtn_valid','stable_count','unit_gap_min','z0_rcond','invariance','riccati', ...
    'hermitian_defect','consistency','consistency_status','consistency_rcond','spectral_radius'}), ...
    fullfile(output_dir,sprintf('lead-p%d.csv',p)));
  summary=struct('p',p,'mu',result.config.mu,'status',result.status,'elapsed_seconds',result.elapsed_seconds, ...
    'N',cellfun(@(r)r.N,result.rules),'acceptance',result.acceptance,'rule_sensitivity',result.rule_sensitivity, ...
    'projected_gap_status',result.projected_gap_status,'lead_pole_status',result.lead_pole_status, ...
    'continuous_count_status',result.continuous_count_status);
  LOCAL_json(fullfile(output_dir,sprintf('summary-p%d.json',p)),summary);
end

function LOCAL_progress(ctx,phase,extra)
  value=struct('phase',phase,'elapsed_seconds',toc(ctx.started),'all_endpoints_done',false);
  for f=fieldnames(extra)', value.(f{1})=extra.(f{1}); end
  LOCAL_json(ctx.progress_path,value);
end

function LOCAL_json(path,value)
  fid=fopen(path,'w'); assert(fid>=0,'endpoint:Output','Cannot open %s',path);
  closer=onCleanup(@()fclose(fid)); fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end

%% ==================== Copied FEM geometry and lead helpers ====================
% These local helpers retain the I10.2 mathematical operations unchanged.

% Source: refine_i102.m lines 190-196, LOCAL_append.
function list = LOCAL_append(list,item)
  if isempty(item), return, end
  if isempty(list), list = item; else, list = [list,item]; end %#ok<AGROW>
end

%% ==================== Layer orchestration ====================
% One field order: primary root, check root (+ prediction at P3), conditional extra, recovery.

% Source: refine_i102.m lines 676-689, LOCAL_curve.
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


% Source: refine_i102.m lines 690-705, LOCAL_curve_derivative.
function dxy = LOCAL_curve_derivative(config,cell_index,theta)
  % Analytic d/dtheta of LOCAL_curve (same formulas, CCW orientation).
  theta = theta(:);
  if cell_index == 0
    c = config.model.star_scale*0.2;
    dxy = c*[-1.5*sin(5*theta).*cos(theta)-(1.5+0.3*cos(5*theta)).*sin(theta), ...
      -1.5*sin(5*theta).*sin(theta)+(1+0.3*cos(5*theta)).*cos(theta)];
  else
    a = config.model.a_negative;
    if cell_index>0, a = config.model.a_positive; end
    scale = config.model.radius/sqrt(1+a^2/2);
    r = scale*(1+a*cos(3*theta)); dr = -3*a*scale*sin(3*theta);
    dxy = [dr.*cos(theta)-r.*sin(theta),dr.*sin(theta)+r.*cos(theta)];
  end
end


% Source: refine_i102.m lines 706-824, LOCAL_mesh.
function [mesh,geometry] = LOCAL_mesh(config)
  % Ported unchanged from I9.5b (fem_dtn_i95b.m::LOCAL_mesh, D2) for design-10-2a 2.2;
  % cfg is the explicit group mesh configuration.
  cfg = config.mesh;
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
  assert(all(abs(mesh.points(:))<2) && tol>0,'i102:Mesh','Mesh points escaped the three-cell box.');
end


% Source: refine_i102.m lines 825-828, LOCAL_bad.
function bad = LOCAL_bad(checks,rules)
  bad = find(checks.det_min<=0 | checks.det_ratio>rules.det_ratio_max);
end


% Source: refine_i102.m lines 829-841, LOCAL_polyline_distance.
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


% Source: refine_i102.m lines 842-891, LOCAL_triangulate.
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
  assert(numel(first)==size(points,1),'i102:Duplicate','Mesh input contains duplicate points.');
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
  assert(size(dt.Points,1)==size(points,1),'i102:Steiner','Triangulation inserted points.');
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


% Source: refine_i102.m lines 892-969, LOCAL_mesh_build.
function [mesh,checks] = LOCAL_mesh_build(config,cfg,base,triangles,material,cell_id)
  % Edges and shared P2 numbering: interface-edge midpoints take the analytic
  % curve values, all other edges the arithmetic midpoint; structural checks
  % and curved Jacobian determinant extrema (I9.5b, unchanged).
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
  outer = @(p)abs(abs(p(:,1))-1.5)<tol | abs(abs(p(:,2))-0.5)<tol;
  single = incidence==1; e1 = points(edges(single,1),:); e2 = points(edges(single,2),:);
  checks.edge_incidence = all(incidence<=2) && all(outer(e1) & outer(e2) & ...
    (abs(e1(:,1)-e2(:,1))<tol | abs(e1(:,2)-e2(:,2))<tol));
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
  det_min = zeros(nt,1); det_max = zeros(nt,1);
  for t = 1:nt
    coefficients = LOCAL_det_coefficients(LOCAL_map_coefficients(p2_points(triangle_p2(t,:),:)));
    [det_min(t),det_max(t)] = LOCAL_quadratic_triangle_extrema(coefficients);
  end
  det_ratio = det_max./det_min; det_ratio(det_min<=0) = Inf;
  P1 = points(triangles(:,1),:); P2 = points(triangles(:,2),:); P3 = points(triangles(:,3),:);
  l1 = sum((P2-P3).^2,2); l2 = sum((P3-P1).^2,2); l3 = sum((P1-P2).^2,2);
  area = abs(orientation)/2;
  quality = 4*sqrt(3)*area./(l1+l2+l3);
  angle = @(opp,u,v)acosd(min(1,max(-1,(u+v-opp)./(2*sqrt(u.*v)))));
  min_angle = min([angle(l1,l2,l3),angle(l2,l3,l1),angle(l3,l1,l2)],[],2);
  top = find(abs(p2_points(:,2)-0.5)<tol); bottom = find(abs(p2_points(:,2)+0.5)<tol);
  checks.top_bottom_pairing = numel(top)==numel(bottom) && ...
    max(abs(sort(p2_points(top,1))-sort(p2_points(bottom,1))))<tol;
  wall_ok = true;
  for w = 1:4
    ids = abs(p2_points(:,1)-(w-2.5))<tol; values = sort(p2_points(ids,2));
    wall_ok = wall_ok && numel(values)==2*cfg.subdivisions+1 && ...
      max(abs(values-(-0.5+(0:2*cfg.subdivisions)'/(2*cfg.subdivisions))))<1e-12;
  end
  checks.wall_translation_pairing = wall_ok;
  checks.vertices = nv; checks.triangles = nt; checks.p2_nodes = size(p2_points,1);
  checks.background_points = base.background_points; checks.deletable_points = base.deletable_points;
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

%% ==================== Bounded local edge flip (ported from I9.5b D2) ====================
% Design 5 step 4: flip one straight chord of an interface-adjacent bad element.

% Source: refine_i102.m lines 970-1039, LOCAL_flip_repair.
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


% Source: refine_i102.m lines 1040-1123, LOCAL_flip_trial.
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


% Source: refine_i102.m lines 1124-1146, LOCAL_segment_curve_clear.
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


% Source: refine_i102.m lines 1147-1151, LOCAL_tf.
function text = LOCAL_tf(value)
  if value, text = 'ACCEPT'; else, text = 'reject'; end
end



% Source: refine_i102.m lines 1169-1180, LOCAL_lattice.
function alpha = LOCAL_lattice(p)
  % Local node order: v1 v2 v3, edge12 (p-j,j,0), edge23 (0,p-j,j),
  % edge31 (j,0,p-j) for j = 1..p-1, then interior nodes (P2: I9.5b order).
  j = (1:p-1)'; z = 0*j;
  alpha = [p,0,0;0,p,0;0,0,p;p-j,j,z;z,p-j,j;j,z,p-j];
  for a2 = 1:p-2
    for a3 = 1:p-1-a2
      alpha(end+1,:) = [p-a2-a3,a2,a3]; %#ok<AGROW>
    end
  end
end


% Source: refine_i102.m lines 1181-1202, LOCAL_lagrange.
function [N,Nxi,Neta] = LOCAL_lagrange(p,alpha,pts)
  % N_alpha(lambda) = prod_i (1/alpha_i!) prod_{j<alpha_i} (p lambda_i - j),
  % lambda = (1-xi-eta, xi, eta); d/dxi = d/dl2 - d/dl1, d/deta = d/dl3 - d/dl1.
  xi = pts(:,1); eta = pts(:,2); L = [1-xi-eta,xi,eta]; np = numel(xi);
  F = cell(p+1,1); dF = cell(p+1,1);
  for m = 0:p
    f = ones(np,3); df = zeros(np,3);
    for j = 0:m-1
      df = df.*(p*L-j)+f*p; f = f.*(p*L-j);
    end
    F{m+1} = f/factorial(m); dF{m+1} = df/factorial(m);
  end
  nb = size(alpha,1); N = zeros(np,nb); Nxi = N; Neta = N;
  for a = 1:nb
    f1 = F{alpha(a,1)+1}(:,1); f2 = F{alpha(a,2)+1}(:,2); f3 = F{alpha(a,3)+1}(:,3);
    d1 = dF{alpha(a,1)+1}(:,1); d2 = dF{alpha(a,2)+1}(:,2); d3 = dF{alpha(a,3)+1}(:,3);
    N(:,a) = f1.*f2.*f3;
    g1 = d1.*f2.*f3;
    Nxi(:,a) = f1.*d2.*f3-g1; Neta(:,a) = f1.*f2.*d3-g1;
  end
end


% Source: refine_i102.m lines 1203-1263, LOCAL_space.
function sp = LOCAL_space(config,mesh,p)
  % Template dofs: template vertices, then (p-1) nodes per template edge
  % ordered from the smaller global vertex id, then (p-1)(p-2)/2 interior
  % nodes per element. Top (y=+1/2) dofs are QP slaves u_+ = e^{i beta} u_-.
  tol = config.mesh_rules.coordinate_tolerance; beta = config.model.beta*config.model.d;
  s = mesh.subdivisions; n = s*p; alpha = LOCAL_lattice(p); nb = size(alpha,1);
  sp = struct('p',p,'s',s,'n',n,'beta',beta,'alpha',alpha,'nb',nb);
  names = {'left','center','right'}; walls_x = {[-0.5,-1.5],[-0.5,0.5],[0.5,1.5]};
  nv_global = size(mesh.points,1);
  lat = alpha(:,2:3)/p; Ng = zeros(nb,6);
  for a = 1:nb, Ng(a,:) = LOCAL_basis([1-lat(a,1)-lat(a,2),lat(a,1),lat(a,2)]); end
  pairs = [1,2;2,3;3,1]; nint = (p-1)*(p-2)/2;
  for c = -1:1
    ids = find(mesh.cell_id==c); nt = numel(ids);
    tri = mesh.triangles(ids,:); eg = mesh.triangle_p2(ids,4:6)-nv_global;
    [verts,~,vloc] = unique(tri); vloc = reshape(vloc,nt,3); nV = numel(verts);
    [edges,~,eloc] = unique(eg); eloc = reshape(eloc,nt,3); nE = numel(edges);
    tri_dofs = zeros(nt,nb); tri_dofs(:,1:3) = vloc;
    for le = 1:3
      forward = tri(:,pairs(le,1)) < tri(:,pairs(le,2));
      for j = 1:p-1
        jj = j*forward+(p-j)*(~forward);
        tri_dofs(:,3+(le-1)*(p-1)+j) = nV+(eloc(:,le)-1)*(p-1)+jj;
      end
    end
    if nint > 0
      tri_dofs(:,3+3*(p-1)+(1:nint)) = nV+nE*(p-1)+(0:nt-1)'*nint+(1:nint);
    end
    nd = nV+nE*(p-1)+nt*nint;
    X = reshape(mesh.p2_points(mesh.triangle_p2(ids,:),1),nt,6);
    Y = reshape(mesh.p2_points(mesh.triangle_p2(ids,:),2),nt,6);
    PX = X*Ng'; PY = Y*Ng';
    dof_xy = zeros(nd,2); dof_xy(tri_dofs(:),1) = PX(:); dof_xy(tri_dofs(:),2) = PY(:);
    consistency = max([abs(dof_xy(tri_dofs,1)-PX(:));abs(dof_xy(tri_dofs,2)-PY(:))]);
    top = find(abs(dof_xy(:,2)-0.5)<tol); bottom = find(abs(dof_xy(:,2)+0.5)<tol);
    [~,a] = sort(dof_xy(top,1)); top = top(a); [~,a] = sort(dof_xy(bottom,1)); bottom = bottom(a);
    pairing = numel(top)==numel(bottom) && max(abs(dof_xy(top,1)-dof_xy(bottom,1)))<tol;
    assert(pairing,'i102:Pairing','Top/bottom P%d dofs do not pair in cell %d.',p,c);
    master = (1:nd)'; master(top) = bottom; free = setdiff((1:nd)',top);
    [~,col] = ismember(master,free); phase = ones(nd,1); phase(top) = exp(1i*beta);
    Qqp = sparse(1:nd,col,phase,nd,numel(free));
    qp_defect = norm(Qqp(top,:)-exp(1i*beta)*Qqp(bottom,:),'fro');
    fx = dof_xy(free,1); fy = dof_xy(free,2); wall = cell(1,2);
    for w = 1:2
      list = find(abs(fx-walls_x{c+2}(w))<tol); [~,a] = sort(fy(list)); wall{w} = list(a);
    end
    expected = -0.5+(0:n-1)'/n;
    wall_ok = numel(wall{1})==n && numel(wall{2})==n && ...
      max(abs([fy(wall{1});fy(wall{2})]-[expected;expected]))<1e-12;
    W = [wall{1};wall{2}]; I = setdiff((1:numel(free))',W);
    sp.(names{c+2}) = struct('name',names{c+2},'cell',c,'element_ids',ids,'X',X,'Y',Y, ...
      'material',mesh.material(ids),'tri_dofs',tri_dofs,'ndof',nd,'dof_xy',dof_xy, ...
      'Qqp',Qqp,'free',free,'top',top,'bottom',bottom,'wall',W,'interior',I, ...
      'wall_y',expected,'counts',[nV,nE,nt], ...
      'checks',struct('dof_formula',nd==nV+(p-1)*nE+nint*nt,'shared_node_coordinate_defect', ...
      consistency,'top_bottom_pairing',pairing,'qp_defect',qp_defect,'wall_pairing',wall_ok, ...
      'pass',wall_ok && pairing && consistency<1e-12 && qp_defect<=config.gates.qp_defect));
  end
  sp.wall_mass_single = LOCAL_wall_mass(s,p,beta);
end


% Source: refine_i102.m lines 1264-1303, LOCAL_basis_checks.
function checks = LOCAL_basis_checks(orders)
  % Reference-element checks: nodal Kronecker property, partition of unity,
  % gradient sums, degree-p reproduction, analytic vs central-difference
  % derivative and local P_p -> P_{p+1} embedding at interior test points.
  k = (1:64)'; u = mod(k*0.6180339887498949,1); v = mod(k*0.4142135623730951,1);
  flip = u+v>1; u(flip) = 1-u(flip); v(flip) = 1-v(flip);
  pts = 0.02+0.96*[u,v]; pts = pts.*(sum(pts,2)<0.98)+0.49*pts.*(sum(pts,2)>=0.98);
  checks = struct([]);
  for p = orders
    alpha = LOCAL_lattice(p); nb = size(alpha,1);
    Nn = LOCAL_lagrange(p,alpha,alpha(:,2:3)/p);
    [N,Nx,Ne] = LOCAL_lagrange(p,alpha,pts);
    repro = 0;
    for a = 0:p
      for b = 0:p-a
        f = @(x)x(:,1).^a.*x(:,2).^b;
        repro = max(repro,max(abs(N*f(alpha(:,2:3)/p)-f(pts))));
      end
    end
    h = 1e-6;
    Np = LOCAL_lagrange(p,alpha,pts+[h,0]); Nm = LOCAL_lagrange(p,alpha,pts-[h,0]);
    fd = max(max(abs((Np-Nm)/(2*h)-Nx)))/max(max(abs(Nx)));
    embed = NaN;
    if p < max(orders)
      alpha2 = LOCAL_lattice(p+1);
      Jloc = LOCAL_lagrange(p,alpha,alpha2(:,2:3)/(p+1));
      N2 = LOCAL_lagrange(p+1,alpha2,pts);
      embed = max(max(abs(N2*Jloc-N)));
    end
    item = struct('p',p,'local_dofs',nb,'kronecker',max(max(abs(Nn-eye(nb)))), ...
      'partition_of_unity',max(abs(sum(N,2)-1)),'gradient_sum', ...
      max([abs(sum(Nx,2));abs(sum(Ne,2))]),'reproduction',repro, ...
      'derivative_fd_relative',fd,'local_embedding',embed);
    item.pass = item.kronecker<1e-12 && item.partition_of_unity<1e-12 && ...
      item.gradient_sum<1e-10 && item.reproduction<1e-12 && item.derivative_fd_relative<1e-7 && ...
      (isnan(embed) || embed<1e-12);
    checks = LOCAL_append(checks,item);
  end
end


% Source: refine_i102.m lines 1348-1385, LOCAL_edge_traces.
function out = LOCAL_edge_traces(config,mesh,spaces)
  % D2 3.2 shared-edge check: on every P2 edge shared by two elements of one
  % template, at edge parameters 0,1/4,1/2,3/4,1 measured from the smaller
  % global vertex, map to each element's own reference coordinates and compare
  % the P2 geometry position and the full global P_p basis rows (p = 2,3,4).
  % A difference above edge_tol is a real structural (DOF/orientation) error.
  tol = config.edge_tol; spar = [0,0.25,0.5,0.75,1]; nsp = numel(spar);
  nv = size(mesh.points,1); pairs = [1,2;2,3;3,1];
  a2 = LOCAL_lattice(2);
  out = struct('parameters',spar,'tolerance',tol,'pass',true,'templates',struct([]));
  for name = {'left','center','right'}
    t2 = spaces{config.orders(1)}.(name{1}); ids = t2.element_ids; nt = numel(ids);
    tri = mesh.triangles(ids,:); eg = mesh.triangle_p2(ids,4:6)-nv;
    list = [eg(:),repmat((1:nt)',3,1),repelem((1:3)',nt)];
    list = sortrows(list,[1,2]); dup = find(list(1:end-1,1)==list(2:end,1));
    A = list(dup,2:3); B = list(dup+1,2:3); ne = numel(dup);
    item = struct('template',name{1},'shared_edges',ne,'geometry_defect',0, ...
      'trace_defect',zeros(1,numel(config.orders)),'pass',true);
    refA = LOCAL_edge_reference(tri,A,pairs,spar); refB = LOCAL_edge_reference(tri,B,pairs,spar);
    rows = repmat((1:ne)',nsp,1); eA = repmat(A(:,1),nsp,1); eB = repmat(B(:,1),nsp,1);
    G = LOCAL_lagrange(2,a2,refA); xA = [sum(t2.X(eA,:).*G,2),sum(t2.Y(eA,:).*G,2)];
    G = LOCAL_lagrange(2,a2,refB); xB = [sum(t2.X(eB,:).*G,2),sum(t2.Y(eB,:).*G,2)];
    item.geometry_defect = max([0;vecnorm(xA-xB,2,2)]);
    for q = 1:numel(config.orders)
      sp = spaces{config.orders(q)}; t = sp.(name{1});
      NA = LOCAL_lagrange(sp.p,sp.alpha,refA); NB = LOCAL_lagrange(sp.p,sp.alpha,refB);
      r = repmat((1:ne*nsp)',1,sp.nb);
      SA = sparse(r(:),reshape(t.tri_dofs(eA,:),[],1),NA(:),ne*nsp,t.ndof);
      SB = sparse(r(:),reshape(t.tri_dofs(eB,:),[],1),NB(:),ne*nsp,t.ndof);
      item.trace_defect(q) = full(max([0;max(abs(SA-SB),[],2)]));
    end
    assert(numel(rows)==ne*nsp);
    item.pass = item.geometry_defect<=tol && all(item.trace_defect<=tol);
    out.pass = out.pass && item.pass;
    out.templates = LOCAL_append(out.templates,item);
  end
end


% Source: refine_i102.m lines 1386-1400, LOCAL_edge_reference.
function ref = LOCAL_edge_reference(tri,side,pairs,spar)
  % Reference (xi,eta) of edge parameter s (from the smaller global vertex)
  % on local edge le: e12 -> (t,0), e23 -> (1-t,t), e31 -> (0,1-t).
  ne = size(side,1); e = side(:,1); le = side(:,2);
  v1 = tri(sub2ind(size(tri),e,pairs(le,1))); v2 = tri(sub2ind(size(tri),e,pairs(le,2)));
  forward = v1<v2; ref = zeros(ne*numel(spar),2);
  for j = 1:numel(spar)
    t = spar(j)*forward+(1-spar(j))*(~forward); xi = zeros(ne,1); eta = xi;
    xi(le==1) = t(le==1); eta(le==1) = 0;
    xi(le==2) = 1-t(le==2); eta(le==2) = t(le==2);
    xi(le==3) = 0; eta(le==3) = 1-t(le==3);
    ref((j-1)*ne+(1:ne),:) = [xi,eta];
  end
end


% Source: refine_i102.m lines 1426-1443, LOCAL_wall_mass.
function W = LOCAL_wall_mass(s,p,beta)
  % Exact 1D P_p mass (p+2 Gauss points per segment), then the QP closure.
  n = s*p; h = 1/s; [x,w] = LOCAL_gauss1d(p+2);
  B = LOCAL_lagrange_1d(p,x); local = h*(B'*(w.*B));
  rows = zeros((p+1)^2*s,1); cols = rows; values = rows; q = 0;
  for m = 0:s-1
    ids = m*p+(0:p)+1;
    for a = 1:p+1
      for b = 1:p+1
        q = q+1; rows(q) = ids(a); cols(q) = ids(b); values(q) = local(a,b);
      end
    end
  end
  Mfull = sparse(rows,cols,values,n+1,n+1);
  Qw = sparse([1:n,n+1],[1:n,1],[ones(1,n),exp(1i*beta)],n+1,n);
  W = full(Qw'*Mfull*Qw); W = (W+W')/2;
end


% Source: refine_i102.m lines 1444-1452, LOCAL_lagrange_1d.
function B = LOCAL_lagrange_1d(p,t)
  t = t(:); nodes = (0:p)/p; B = ones(numel(t),p+1);
  for j = 1:p+1
    for m = 1:p+1
      if m ~= j, B(:,j) = B(:,j).*(t-nodes(m))/(nodes(j)-nodes(m)); end
    end
  end
end


% Source: refine_i102.m lines 1453-1457, LOCAL_gauss1d.
function [x,w] = LOCAL_gauss1d(m)
  j = (1:m-1)'; b = j./sqrt(4*j.^2-1); [V,D] = eig(diag(b,1)+diag(b,-1));
  [x,idx] = sort(diag(D)); w = V(1,idx)'.^2; x = (x+1)/2;
end


% Source: refine_i102.m lines 1476-1587, LOCAL_band_locate.
function band = LOCAL_band_locate(config,mesh,rule,spaces)
  loc = config.location; ng = mesh.interface_segments; dtheta = 2*pi/ng;
  timer = tic;
  [tg,tw] = LOCAL_gauss1d(rule.band_points); m = rule.band_subsegments;
  t = reshape(tg+(0:m-1),[],1)/m; wt = repmat(tw,m,1)/m;     % t in [0,1], equal subsegments
  [T,TAU] = ndgrid(t,tg); [WT,WTAU] = ndgrid(wt,tw);
  T = T(:)'; TAU = TAU(:)'; WQ = WT(:)'.*WTAU(:)'; nps = numel(T);
  % element geometry: P2 map coefficients, scales, adjacency and AABB
  nt = size(mesh.triangles,1); nv = size(mesh.points,1);
  nodes = cell(1,6);
  for a = 1:6, nodes{a} = mesh.p2_points(mesh.triangle_p2(:,a),:); end
  Cx = LOCAL_map_rows(nodes,1); Cy = LOCAL_map_rows(nodes,2);
  V = mesh.points;
  scale = max([vecnorm(V(mesh.triangles(:,1),:)-V(mesh.triangles(:,2),:),2,2), ...
    vecnorm(V(mesh.triangles(:,2),:)-V(mesh.triangles(:,3),:),2,2), ...
    vecnorm(V(mesh.triangles(:,3),:)-V(mesh.triangles(:,1),:),2,2)],[],2);
  control = [nodes{1};nodes{2};nodes{3};2*nodes{4}-(nodes{1}+nodes{2})/2; ...
    2*nodes{5}-(nodes{2}+nodes{3})/2;2*nodes{6}-(nodes{3}+nodes{1})/2];
  cx = reshape(control(:,1),nt,6); cy = reshape(control(:,2),nt,6);
  box = [min(cx,[],2)-loc.aabb_pad,max(cx,[],2)+loc.aabb_pad, ...
    min(cy,[],2)-loc.aabb_pad,max(cy,[],2)+loc.aabb_pad];
  edge_of_tri = mesh.triangle_p2(:,4:6)-nv;
  E2T = sparse(edge_of_tri(:),repmat((1:nt)',3,1),1,size(mesh.edges,1),nt);
  V2T = sparse(mesh.triangles(:),repmat((1:nt)',3,1),1,nv,nt);
  names = {'left','center','right'}; rho = [config.model.rho_negative,config.model.rho_center, ...
    config.model.rho_positive];
  band = struct('rule',rule.name,'points_per_segment',nps,'total_points',0,'total_failures',0, ...
    'total_dual',0,'total_tolerance_owner',0,'seconds',0,'failures',struct([]));
  for c = -1:1
    name = names{c+2}; seg = (c+1)*ng+(1:ng)';
    theta0 = mesh.interface_theta(seg); theta1 = theta0([2:end,1]);
    P0 = LOCAL_curve(config,c,theta0); Pm = LOCAL_curve(config,c,theta0+pi/ng);
    P1 = LOCAL_curve(config,c,theta1);
    th = theta0+dtheta*T;                                     % ng x nps
    G = LOCAL_curve(config,c,th(:)); dG = dtheta*LOCAL_curve_derivative(config,c,th(:));
    t1 = repmat(T,ng,1); t1 = t1(:); tau = repmat(TAU,ng,1); tau = tau(:);
    sid = repmat((1:ng)',1,nps); sid = sid(:);
    b0 = (1-t1).*(1-2*t1); bm = 4*t1.*(1-t1); b1 = t1.*(2*t1-1);
    Gh = P0(sid,:).*b0+Pm(sid,:).*bm+P1(sid,:).*b1;
    dGh = P0(sid,:).*(4*t1-3)+Pm(sid,:).*(4-8*t1)+P1(sid,:).*(4*t1-1);
    Htau = G-Gh; Ht = dGh+tau.*(dG-dGh); H = Gh+tau.*Htau;
    JH = Htau(:,1).*Ht(:,2)-Htau(:,2).*Ht(:,1);              % signed, never abs
    weight = repmat(WQ,ng,1); weight = weight(:).*JH;
    np = size(H,1);
    % --- D2 owner state: lexicographic (-b_K, r_K/h_K, global element id) ---
    S = LOCAL_owner_init(np);
    owners = zeros(ng,2);
    for j = 1:ng, owners(j,:) = find(E2T(mesh.interface_edges(seg(j)),:)); end
    % --- stage A: the two owners of the interface edge ---
    S = LOCAL_try(config,spaces,Cx,Cy,scale,H,(1:np)',owners(sid,:),S,1);
    % --- stage B: vertex neighbours, once, for points without owner or with best b_K < 0 ---
    todo = find(S.element==0 | S.b<0); neighbours = cell(ng,1);
    for j = unique(sid(todo))'
      list = find(any(V2T(mesh.triangles(owners(j,:),:),:),1));
      neighbours{j} = setdiff(list,owners(j,:));
    end
    if ~isempty(todo)
      S = LOCAL_try(config,spaces,Cx,Cy,scale,H,todo,LOCAL_pad(neighbours(sid(todo))),S,2);
    end
    % --- stage C: Bernstein-box candidates not tried before, once ---
    todo = find(S.element==0 | S.b<0);
    if ~isempty(todo)
      lists = cell(numel(todo),1);
      for i = 1:numel(todo)
        x = H(todo(i),:); j = sid(todo(i));
        list = find(box(:,1)<=x(1) & box(:,2)>=x(1) & box(:,3)<=x(2) & box(:,4)>=x(2))';
        lists{i} = setdiff(list,[owners(j,:),neighbours{j}]);
      end
      S = LOCAL_try(config,spaces,Cx,Cy,scale,H,todo,LOCAL_pad(lists),S,3);
    end
    element = S.element; xi = S.xi; eta = S.eta;
    failed = find(element==0);
    for i = failed'
      band.failures = LOCAL_append(band.failures,struct('cell',c,'segment',sid(i), ...
        't',t1(i),'tau',tau(i),'x',H(i,1),'y',H(i,2), ...
        'reason','POINT_LOCATION_FAILED: NO_ACCEPTED_INVERSE'));
    end
    % up to 20 largest recorded dual differences (diagnostic only, never a veto)
    dual = S.nacc>1; dlist = find(dual & ~isnan(S.defect));
    [~,o] = sort(S.defect(dlist),'descend'); dlist = dlist(o(1:min(20,end)));
    samples = struct([]);
    for i = dlist'
      samples = LOCAL_append(samples,struct('point',i,'segment',sid(i),'t',t1(i),'tau',tau(i), ...
        'x',H(i,1),'y',H(i,2),'weight',weight(i),'defect',S.defect(i), ...
        'owner_element',S.element(i),'owner_b',S.b(i),'owner_r_over_h',S.rh(i), ...
        'alt_element',S.alt_element(i),'alt_b',S.alt_b(i),'alt_r_over_h',S.alt_rh(i)));
    end
    % template-local element index (same element_ids for every order)
    local = zeros(nt,1); ids = spaces{config.orders(1)}.(name).element_ids;
    local(ids) = 1:numel(ids);
    in_cell = element>0; wrong_cell = nnz(in_cell & local(max(element,1))==0);
    template_element = zeros(np,1); template_element(in_cell) = local(element(in_cell));
    band.(name) = struct('element',template_element,'xi',xi,'eta',eta,'weight',weight, ...
      'rho_minus_one',rho(c+2)-1,'signed_area',sum(weight),'points',np, ...
      'failures',numel(failed),'dual',nnz(dual),'tolerance_owner',nnz(element>0 & S.b<0), ...
      'dual_defect_max',max([0;S.defect(dual & ~isnan(S.defect))]), ...
      'owner_r_over_h_max',max([0;S.rh(element>0)]),'owner_b_min',min([Inf;S.b(element>0)]), ...
      'dual_samples',samples, ...
      'wrong_cell',wrong_cell,'stage_counts',[nnz(S.stage==1),nnz(S.stage==2),nnz(S.stage==3)], ...
      'negative_J',nnz(JH<0),'J_min',min(JH),'J_max',max(JH), ...
      'max_offset',max(vecnorm(Htau,2,2)));
    band.total_points = band.total_points+np; band.total_failures = band.total_failures+numel(failed);
    band.total_dual = band.total_dual+nnz(dual);
    band.total_tolerance_owner = band.total_tolerance_owner+nnz(element>0 & S.b<0);
    if wrong_cell > 0
      band.total_failures = band.total_failures+wrong_cell;
      band.(name).element(template_element==0 & in_cell) = 0;
    end
  end
  band.seconds = toc(timer);
end


% Source: refine_i102.m lines 1588-1594, LOCAL_map_rows.
function C = LOCAL_map_rows(nodes,k)
  % Rows of P2 map coefficients c1..c6 (I9.5b LOCAL_map_coefficients), coordinate k.
  n = cellfun(@(v)v(:,k),nodes,'UniformOutput',false);
  C = [n{1},-3*n{1}-n{2}+4*n{4},-3*n{1}-n{3}+4*n{6},2*n{1}+2*n{2}-4*n{4}, ...
    4*n{1}-4*n{4}+4*n{5}-4*n{6},2*n{1}+2*n{3}-4*n{6}];
end


% Source: refine_i102.m lines 1595-1600, LOCAL_owner_init.
function S = LOCAL_owner_init(np)
  S = struct('element',zeros(np,1),'xi',NaN(np,1),'eta',NaN(np,1),'b',-Inf(np,1), ...
    'rh',Inf(np,1),'stage',zeros(np,1),'nacc',zeros(np,1),'defect',NaN(np,1), ...
    'alt_element',zeros(np,1),'alt_b',NaN(np,1),'alt_rh',NaN(np,1));
end


% Source: refine_i102.m lines 1601-1605, LOCAL_pad.
function cand = LOCAL_pad(lists)
  width = max(1,max(cellfun(@numel,lists))); cand = zeros(numel(lists),width);
  for i = 1:numel(lists), cand(i,1:numel(lists{i})) = lists{i}; end
end


% Source: refine_i102.m lines 1606-1644, LOCAL_try.
function S = LOCAL_try(config,spaces,Cx,Cy,scale,H,points,cand,S,stage_id)
  % Inverse-map every (point, candidate) pair inside the acceptance window
  % r_K/h_K <= 1e-12, b_K >= -1e-10 and keep one owner per point by the D2
  % lexicographic order (-b_K, r_K/h_K, global element id), merged with an
  % owner from an earlier stage. Several accepted inverses are a recorded
  % dual: the largest global-basis difference (all orders) to the owner is
  % stored as a diagnostic only; it never clears the owner.
  loc = config.location; nc = size(cand,2);
  P = repelem(points,nc); E = reshape(cand',[],1); keep = E>0; P = P(keep); E = E(keep);
  if isempty(P), return, end
  [s,r,ok,bmin] = LOCAL_inverse_map(Cx(E,:),Cy(E,:),H(P,:),scale(E),loc);
  rh = r./scale(E); acc = find(ok);
  if isempty(acc), return, end
  [~,order] = sortrows([P(acc),-bmin(acc),rh(acc),E(acc)]); acc = acc(order);
  starts = find([true;diff(P(acc))~=0]); lengths = diff([starts;numel(acc)+1]);
  best = acc(starts); k = P(best); had = S.element(k)>0;
  % single new acceptance and no earlier owner: assign directly
  direct = ~had & lengths==1; kd = k(direct); bd = best(direct);
  S.element(kd) = E(bd); S.xi(kd) = s(bd,1); S.eta(kd) = s(bd,2); S.b(kd) = bmin(bd);
  S.rh(kd) = rh(bd); S.stage(kd) = stage_id; S.nacc(kd) = 1;
  % several acceptances (this stage and/or an earlier owner): order, assign, record
  for j = find(~direct)'
    rows = acc(starts(j)+(0:lengths(j)-1)); kk = P(rows(1));
    el = E(rows); ss = s(rows,:); bs = bmin(rows); rs = rh(rows); st = repmat(stage_id,numel(rows),1);
    if S.element(kk)>0
      el = [S.element(kk);el]; ss = [S.xi(kk),S.eta(kk);ss]; bs = [S.b(kk);bs]; %#ok<AGROW>
      rs = [S.rh(kk);rs]; st = [S.stage(kk);st]; %#ok<AGROW>
    end
    [~,o] = sortrows([-bs,rs,el]); el = el(o); ss = ss(o,:); bs = bs(o); rs = rs(o); st = st(o);
    S.element(kk) = el(1); S.xi(kk) = ss(1,1); S.eta(kk) = ss(1,2); S.b(kk) = bs(1);
    S.rh(kk) = rs(1); S.stage(kk) = st(1); S.nacc(kk) = S.nacc(kk)+numel(rows);
    if numel(el)>1
      d = LOCAL_dual_mismatch(config,spaces,el,ss);
      S.defect(kk) = max([S.defect(kk),d],[],'omitnan');
      S.alt_element(kk) = el(2); S.alt_b(kk) = bs(2); S.alt_rh(kk) = rs(2);
    end
  end
end


% Source: refine_i102.m lines 1645-1680, LOCAL_inverse_map.
function [s,r,ok,bmin] = LOCAL_inverse_map(Cx,Cy,X,scale,loc)
  % Newton with backtracking for the P2 map F(xi,eta) = X: at most
  % newton_steps steps, at most `halvings` step halvings per step.
  n = size(X,1); s = ones(n,2)/3;
  f = @(C,s)C(:,1)+C(:,2).*s(:,1)+C(:,3).*s(:,2)+C(:,4).*s(:,1).^2+ ...
    C(:,5).*s(:,1).*s(:,2)+C(:,6).*s(:,2).^2;
  rx = f(Cx,s)-X(:,1); ry = f(Cy,s)-X(:,2); r = hypot(rx,ry);
  active = r > 1e-3*loc.residual*scale;
  for step = 1:loc.newton_steps
    A = find(active);
    if isempty(A), break, end
    a = s(A,:); cx = Cx(A,:); cy = Cy(A,:);
    j11 = cx(:,2)+2*cx(:,4).*a(:,1)+cx(:,5).*a(:,2); j12 = cx(:,3)+cx(:,5).*a(:,1)+2*cx(:,6).*a(:,2);
    j21 = cy(:,2)+2*cy(:,4).*a(:,1)+cy(:,5).*a(:,2); j22 = cy(:,3)+cy(:,5).*a(:,1)+2*cy(:,6).*a(:,2);
    d = j11.*j22-j12.*j21;
    ds = -[(j22.*rx(A)-j12.*ry(A))./d,(-j21.*rx(A)+j11.*ry(A))./d];
    lam = ones(numel(A),1); done = false(numel(A),1);
    trial = a; trx = rx(A); try_ = ry(A); tr = r(A);
    for h = 0:loc.halvings
      J = find(~done);
      if isempty(J), break, end
      cand = a(J,:)+lam(J).*ds(J,:);
      cr_x = f(cx(J,:),cand)-X(A(J),1); cr_y = f(cy(J,:),cand)-X(A(J),2); cr = hypot(cr_x,cr_y);
      good = isfinite(cr) & cr < r(A(J));
      trial(J(good),:) = cand(good,:); trx(J(good)) = cr_x(good); try_(J(good)) = cr_y(good);
      tr(J(good)) = cr(good); done(J(good)) = true; lam(J(~good)) = lam(J(~good))/2;
    end
    s(A,:) = trial; rx(A) = trx; ry(A) = try_; r(A) = tr;
    active(A(~done)) = false;                                   % stalled
    active(A) = active(A) & r(A) > 1e-3*loc.residual*scale(A);
    if any(~isfinite(d)), active(A(~isfinite(d))) = false; end
  end
  bmin = min([1-s(:,1)-s(:,2),s],[],2);
  ok = r <= loc.residual*scale & bmin >= loc.barycentric_min;
end


% Source: refine_i102.m lines 1681-1705, LOCAL_dual_mismatch.
function defect = LOCAL_dual_mismatch(config,spaces,elements,s)
  % Diagnostic only (D2): largest difference of the global basis values
  % reached from the owner and the other accepted inverses (all orders); Inf
  % if the candidates belong to different templates. Never a veto.
  defect = 0;
  for p = config.orders
    sp = spaces{p};
    for name = {'left','center','right'}
      t = sp.(name{1}); [in,local] = ismember(elements,t.element_ids);
      if ~all(in)
        if any(in), defect = Inf; return, end
        continue
      end
      N = LOCAL_lagrange(p,sp.alpha,s);
      base = sparse(1,t.tri_dofs(local(1),:),N(1,:),1,t.ndof);
      for j = 2:numel(elements)
        other = sparse(1,t.tri_dofs(local(j),:),N(j,:),1,t.ndof);
        defect = max(defect,full(max(abs(base-other))));
      end
    end
  end
end

%% ==================== Volume and band assembly, operators and nested checks ====================
% K, M_{p,h} by Gauss-Duffy; dM_p by the oriented band; Qqp constraint; checks.

% Source: refine_i102.m lines 1706-1727, LOCAL_assemble_p.
function [K,M,area,inclusion_area] = LOCAL_assemble_p(t,p,alpha,order)
  nt = size(t.tri_dofs,1); nb = size(alpha,1); X = t.X; Y = t.Y; material = t.material;
  [lambda,weights] = LOCAL_quadrature(order);
  [Nq,Nxq,Neq] = LOCAL_lagrange(p,alpha,lambda(:,2:3));
  ia = repmat(1:nb,1,nb); ib = repelem(1:nb,nb);
  kval = zeros(nt,nb*nb); mval = kval; areas = zeros(nt,1);
  for q = 1:numel(weights)
    [~,G] = LOCAL_basis(lambda(q,:));
    j11 = X*G(1,:)'; j12 = X*G(2,:)'; j21 = Y*G(1,:)'; j22 = Y*G(2,:)';
    d = j11.*j22-j12.*j21; w = weights(q)*d;
    dx = (j22.*Nxq(q,:)-j21.*Neq(q,:))./d; dy = (-j12.*Nxq(q,:)+j11.*Neq(q,:))./d;
    wdx = w.*dx; wdy = w.*dy;
    kval = kval+wdx(:,ia).*dx(:,ib)+wdy(:,ia).*dy(:,ib);
    mval = mval+(material.*w).*(Nq(q,ia).*Nq(q,ib));
    areas = areas+w;
  end
  rows = t.tri_dofs(:,ia); cols = t.tri_dofs(:,ib);
  K = sparse(rows(:),cols(:),kval(:),t.ndof,t.ndof);
  M = sparse(rows(:),cols(:),mval(:),t.ndof,t.ndof);
  area = sum(areas); inclusion_area = sum(areas(material~=1));
end


% Source: refine_i102.m lines 1728-1742, LOCAL_band_matrix.
function dM = LOCAL_band_matrix(t,b,p,alpha,batch)
  % dM = (rho_in-1) sum_points w J_H Psi(H) Psi(H)^T, at most nb^2 local
  % entries per point, accumulated in batches (no dense dof x point array).
  nb = size(alpha,1); ia = repmat((1:nb)',nb,1); ib = repelem((1:nb)',nb);
  dM = sparse(t.ndof,t.ndof); n = numel(b.xi);
  for j = 1:batch:n
    J = j:min(j+batch-1,n);
    N = LOCAL_lagrange(p,alpha,[b.xi(J),b.eta(J)]);
    dofs = t.tri_dofs(b.element(J),:);
    vals = (b.rho_minus_one*b.weight(J)).*N(:,ia).*N(:,ib);
    rows = dofs(:,ia); cols = dofs(:,ib);
    dM = dM+sparse(rows(:),cols(:),vals(:),t.ndof,t.ndof);
  end
end


% Source: refine_i102.m lines 1743-1807, LOCAL_operators.
function ops = LOCAL_operators(ctx,sp,band,rule,want_raw,want_nominal)
  config = ctx.config; p = sp.p; names = {'left','center','right'};
  LOCAL_progress(ctx,'assembly',struct('p',p,'rule',rule.name));
  ops = struct('p',p,'rule',rule.name,'n',sp.n,'beta',sp.beta,'raw',[]);
  checks = struct('pass',true,'reason','','rule',rule.name,'p',p,'seconds_volume',0, ...
    'seconds_band',0,'seconds_checks',0);
  exact = LOCAL_exact_areas(config);
  rho = [config.model.rho_negative,config.model.rho_center,config.model.rho_positive];
  for j = 1:3
    name = names{j}; t = sp.(name); nt = size(t.tri_dofs,1);
    LOCAL_memory_gate(config,['assembly ',name],8*nt*sp.nb^2*10);
    timer = tic;
    [Kf,Mhf,area,inclusion] = LOCAL_assemble_p(t,p,sp.alpha,rule.volume_order);
    dt = toc(timer); checks.seconds_volume = checks.seconds_volume+dt;
    LOCAL_ledger('add',['assembly_volume_',rule.name],dt);
    timer = tic;
    dMf = LOCAL_band_matrix(t,band.(name),p,sp.alpha,config.location.batch);
    dt = toc(timer); checks.seconds_band = checks.seconds_band+dt;
    LOCAL_ledger('add',['assembly_band_',rule.name],dt);
    timer = tic;
    constant = full(sum(dMf(:))); expected = (rho(j)-1)*(exact(j)-inclusion);
    Q = t.Qqp;
    Kraw = Q'*Kf*Q; Mhraw = Q'*Mhf*Q; dMraw = Q'*dMf*Q;
    herm = @(A)norm(A-A','fro')/max(norm(A,'fro'),realmin);
    kdef = herm(Kraw); mdef = herm(Mhraw); ddef = herm(dMraw);
    K = (Kraw+Kraw')/2; Mh = (Mhraw+Mhraw')/2; dM = (dMraw+dMraw')/2; M = Mh+dM;
    order = symamd(M); [~,mflag] = chol(M(order,order));
    I = t.interior;
    pattern = spones(K(I,I))+spones(M(I,I));
    tmpl = struct('name',name,'K',K,'M',M,'wall',t.wall,'interior',I,'free',t.free, ...
      'Qqp',Q,'top',t.top,'bottom',t.bottom,'tri_dofs',t.tri_dofs,'dof_xy',t.dof_xy, ...
      'amd',amd(pattern),'symbolic_nnz',NaN,'M_nominal',[]);
    tmpl.symbolic_nnz = sum(symbfact(pattern(tmpl.amd,tmpl.amd)));
    if want_nominal, tmpl.M_nominal = Mh; end
    if want_raw
      ops.raw.(name) = struct('K_full',Kf,'M_h_full',Mhf,'dM_full',dMf);
    end
    ops.(name) = tmpl;
    check = struct('area',area,'area_defect',abs(area-1),'inclusion_area_h',inclusion, ...
      'inclusion_area_exact',exact(j),'inclusion_area_defect',inclusion-exact(j), ...
      'band_constant',constant,'band_constant_expected',expected, ...
      'band_constant_defect',constant-expected,'band_signed_area',band.(name).signed_area, ...
      'dM_fro',norm(dM,'fro'),'dM_relative_to_Mh',norm(dM,'fro')/norm(Mh,'fro'), ...
      'stiffness_hermitian_defect',kdef,'mass_h_hermitian_defect',mdef, ...
      'band_hermitian_defect',ddef,'mass_chol_flag',mflag,'nnz_K',nnz(K), ...
      'free_dofs',numel(t.free),'interior_dofs',numel(I),'symbolic_chol_nnz',tmpl.symbolic_nnz);
    pass = kdef<=config.gates.matrix_hermitian && mdef<=config.gates.matrix_hermitian && ...
      ddef<=config.gates.matrix_hermitian && mflag==0 && abs(area-1)<1e-10;
    check.pass = pass; checks.(name) = check;
    if ~pass, checks.pass = false; checks.reason = [checks.reason,name,' matrix check failed; ']; end
    checks.seconds_checks = checks.seconds_checks+toc(timer);
    LOCAL_ledger('add',['assembly_checks_',rule.name],toc(timer));
    clear Kf Mhf dMf Kraw Mhraw dMraw
  end
  ops.wall_mass = blkdiag(sp.wall_mass_single,sp.wall_mass_single);
  ops.wall_chol = chol(ops.wall_mass);
  checks.wall_mass_hermitian_defect = norm(sp.wall_mass_single-sp.wall_mass_single','fro');
  ops.checks = checks;
  fprintf('STAGE assembly P%d %s: volume %.2fs band %.2fs checks %.2fs pass %d\n',p,rule.name, ...
    checks.seconds_volume,checks.seconds_band,checks.seconds_checks,checks.pass);
  if ~checks.pass && ~strcmp(ctx.config.mode,'sizing')
    error('i102:MatrixCheck','P%d %s matrix checks failed: %s',p,rule.name,checks.reason);
  end
end


% Source: refine_i102.m lines 1842-1850, LOCAL_exact_areas.
function exact = LOCAL_exact_areas(config)
  theta = 2*pi*(0:8191)'/8192; exact = zeros(1,3);
  for c = -1:1
    xy = LOCAL_curve(config,c,theta); xy(:,1) = xy(:,1)-c*config.model.L;
    d = 2*pi/8192; dx = LOCAL_spectral_derivative(xy(:,1))/d; dy = LOCAL_spectral_derivative(xy(:,2))/d;
    exact(c+2) = 0.5*sum(xy(:,1).*dy-xy(:,2).*dx)*d;
  end
end


% Source: refine_i102.m lines 1851-1858, LOCAL_spectral_derivative.
function dv = LOCAL_spectral_derivative(v)
  n = numel(v); k = [0:n/2-1,0,-n/2+1:-1]'*2*pi/n;
  dv = real(ifft(1i*k.*fft(v)));
end

%% ==================== Cell elimination, discrete DtN and near-wall extension ====================
% Weak outward wall load S = A_WW + A_WI A_II^{-1}(-A_IW), assembled in 32-column
% blocks without storing the full extension E; ordered complex QZ stable subspace.

% Source: refine_i102.m lines 1859-1903, LOCAL_eliminate.
function [S,info,fac] = LOCAL_eliminate(config,t,mu,method)
  A = t.K-mu*t.M; I = t.interior; W = t.wall;
  AII = A(I,I); AIW = A(I,W); AWI = A(W,I); nI = numel(I); nW = numel(W);
  info = struct('valid',true,'reason','','method',method,'backward',NaN,'backward_num',NaN, ...
    'backward_den',NaN,'condest',NaN,'chol_flag',NaN);
  fac = struct('apply',[]); S = [];
  rs = full(sum(abs(AII),2));
  if any(rs==0), info.valid = false; info.reason = 'ZERO_ROW'; return, end
  T = spdiags(1./sqrt(rs),0,nI,nI); B = T*AII*T;
  try
    if strcmp(method,'chol')
      p = t.amd; [Rc,flag] = chol(B(p,p)); info.chol_flag = flag;
      if flag ~= 0, info.valid = false; info.reason = 'CENTER_CHOLESKY_FAILED'; return, end
      solve = @(c)LOCAL_chol_solve(Rc,p,c); solve_h = solve;
    else
      [L,U,P,Q,R] = lu(B);
      solve = @(c)Q*(U\(L\(P*(R\c))));
      solve_h = @(c)R\(P'*(L'\(U'\(Q'*c))));
    end
  catch error_object
    info.valid = false; info.reason = ['FACTORIZATION_EXCEPTION: ',error_object.message]; return
  end
  apply = @(rhs)T*solve(T*rhs);
  block = config.solver.rhs_block; S = full(A(W,W));
  norm_A = norm(AII,1); worst = 0; worst_num = 0; worst_den = 1;
  for j = 1:block:nW
    J = j:min(j+block-1,nW);
    rhs = full(-AIW(:,J)); X = apply(rhs);
    r = AII*X-rhs;
    num = sum(abs(r),1); den = norm_A*sum(abs(X),1)+sum(abs(rhs),1);
    [value,at] = max(num./max(den,realmin));
    if value>worst, worst = value; worst_num = num(at); worst_den = den(at); end
    S(:,J) = S(:,J)+AWI*X;
  end
  info.backward = worst; info.backward_num = worst_num; info.backward_den = worst_den;
  afun = @(flag,X)LOCAL_normest_handle(flag,X,nI,solve,solve_h);
  info.condest = norm(B,1)*normest1(afun);
  if ~(info.backward<=config.gates.cell_backward)
    info.valid = false; info.reason = sprintf('CELL_BACKWARD %.3e',info.backward);
  elseif ~(info.condest<=config.gates.cell_condest)
    info.valid = false; info.reason = sprintf('CELL_CONDEST %.3e',info.condest);
  end
  fac = struct('apply',apply,'AII',AII,'norm_A',norm_A);
end


% Source: refine_i102.m lines 1904-1907, LOCAL_chol_solve.
function x = LOCAL_chol_solve(Rc,p,c)
  x = zeros(size(c),'like',complex(c)); x(p,:) = Rc\(Rc'\c(p,:));
end


% Source: refine_i102.m lines 1908-1916, LOCAL_normest_handle.
function y = LOCAL_normest_handle(flag,X,n,solve,solve_h)
  switch flag
    case 'dim', y = n;
    case 'real', y = false;
    case 'notransp', y = solve(X);
    case 'transp', y = solve_h(X);
  end
end


% Source: refine_i102.m lines 1917-1988, LOCAL_dtn.
function [D,Pout,info] = LOCAL_dtn(config,S,n)
  % Copied from I9.5b: ordered complex QZ, Pout = Z1/Z0, D = S00 + S01 Pout.
  g = config.gates;
  S00 = S(1:n,1:n); S01 = S(1:n,n+1:end); S10 = S(n+1:end,1:n); S11 = S(n+1:end,n+1:end);
  Acal = [-(S11+S00),-S10;eye(n),zeros(n)]; Bcal = [S01,zeros(n);zeros(n),eye(n)];
  [AA,BB,Qz,Zz] = qz(Acal,Bcal,'complex');
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
    'spectral_radius',NaN,'stable_multipliers',[]);
  D = []; Pout = [];
  reasons = {};
  if any(degenerate), reasons{end+1} = sprintf('QZ_DEGENERATE %d',nnz(degenerate)); end
  if any(gap<=g.unit_gap), reasons{end+1} = sprintf('UNIT_CIRCLE_GAP %.3e',min(gap)); end
  if nnz(stable)~=n, reasons{end+1} = sprintf('STABLE_COUNT %d~=%d',nnz(stable),n); end
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
  Z = Zs(:,1:n); Z1 = Z(1:n,:); Z0 = Z(n+1:end,:); Y = Qs(1:n,:)';
  info.z0_rcond = rcond(Z0);
  normA = norm(Acal,'fro'); normB = norm(Bcal,'fro');
  info.invariance = (norm(Acal*Z-Y*AAs(1:n,1:n),'fro')+norm(Bcal*Z-Y*BBs(1:n,1:n),'fro'))/ ...
    ((normA+normB)*norm(Z,'fro'));
  Ts = BBs(1:n,1:n)\AAs(1:n,1:n);
  info.lower_block = norm(Z1-Z0*Ts,'fro')/max(norm(Z1,'fro'),norm(Z0*Ts,'fro'));
  alpha_s = diag(AAs(1:n,1:n)); gamma_s = diag(BBs(1:n,1:n));
  info.stable_multipliers = alpha_s./gamma_s;
  info.spectral_radius = max(abs(info.stable_multipliers));
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


% Source: refine_i102.m lines 2013-2020, LOCAL_cell_bytes.
function bytes = LOCAL_cell_bytes(config,t,want_extension,n)
  nI = numel(t.interior); nfree = numel(t.free);
  bytes = config.solver.lu_fill_allowance*2*16*t.symbolic_nnz+16*nI*config.solver.rhs_block*4 + ...
    3*24*nnz(t.K)+want_extension*(2*16*nI*n+16*nfree*config.solver.rhs_block);
end

%% ==================== One frequency response ====================
% Both leads, then the centre; selection, wall trace g (g^* W g = 1), centre field.

% Source: refine_i102.m lines 2639-2658, LOCAL_ledger.
function out = LOCAL_ledger(action,name,value)
  persistent ledger total
  if isempty(ledger), ledger = struct(); total = 0; end
  out = [];
  switch action
    case 'reset'
      ledger = struct(); total = 0;
    case 'add'
      if ~isfield(ledger,name), ledger.(name) = 0; end
      ledger.(name) = ledger.(name)+value; total = total+value;
    case 'total'
      out = total;
    case 'snapshot'
      out = ledger;
    case 'close'
      out = struct('categories',ledger,'attributed_seconds',total, ...
        'matlab_function_seconds',name,'matlab_unattributed_seconds',name-total);
  end
end


% Source: refine_i102.m lines 2682-2687, LOCAL_rss.
function rss = LOCAL_rss()
  [flag,text] = system(sprintf('ps -o rss= -p %d',feature('getpid')));
  rss = NaN;
  if flag==0, rss = 1024*str2double(strtrim(text)); end
end


% Source: refine_i102.m lines 2688-2695, LOCAL_memory_gate.
function LOCAL_memory_gate(config,label,bytes,rss)
  if nargin<4, rss = LOCAL_rss(); end
  if rss+bytes>config.resources.internal_gate_bytes
    error('i102:ResourceStop','Predicted %s memory %.0f + RSS %.0f exceeds %.0f bytes.', ...
      label,bytes,rss,config.resources.internal_gate_bytes);
  end
end


% Source: refine_i102.m lines 2822-2830, LOCAL_basis.
function [basis,G] = LOCAL_basis(l)
  gl = [-1,1,0;-1,0,1]; basis = [l.*(2*l-1),4*l(1)*l(2),4*l(2)*l(3),4*l(3)*l(1)];
  G = zeros(2,6);
  for j = 1:3, G(:,j) = (4*l(j)-1)*gl(:,j); end
  G(:,4) = 4*(l(1)*gl(:,2)+l(2)*gl(:,1));
  G(:,5) = 4*(l(2)*gl(:,3)+l(3)*gl(:,2));
  G(:,6) = 4*(l(3)*gl(:,1)+l(1)*gl(:,3));
end


% Source: refine_i102.m lines 2831-2837, LOCAL_quadrature.
function [lambda,weights] = LOCAL_quadrature(order)
  j = (1:order-1)'; b = j./sqrt(4*j.^2-1); [V,D] = eig(diag(b,1)+diag(b,-1));
  [x,idx] = sort(diag(D)); w = V(1,idx)'.^2; x = (x+1)/2;
  [r,s] = ndgrid(x,x); [wr,ws] = ndgrid(w,w); xi = r(:); eta = (1-xi).*s(:);
  lambda = [1-xi-eta,xi,eta]; weights = wr(:).*ws(:).*(1-xi);
end


% Source: refine_i102.m lines 2838-2843, LOCAL_map_coefficients.
function coefficients = LOCAL_map_coefficients(nodes)
  coefficients = [nodes(1,:);-3*nodes(1,:)-nodes(2,:)+4*nodes(4,:); ...
    -3*nodes(1,:)-nodes(3,:)+4*nodes(6,:);2*nodes(1,:)+2*nodes(2,:)-4*nodes(4,:); ...
    4*nodes(1,:)-4*nodes(4,:)+4*nodes(5,:)-4*nodes(6,:);2*nodes(1,:)+2*nodes(3,:)-4*nodes(6,:)];
end


% Source: refine_i102.m lines 2844-2850, LOCAL_det_coefficients.
function c = LOCAL_det_coefficients(map)
  a = map(2,:); b = map(3,:); d = map(4,:); e = map(5,:); f = map(6,:);
  cross2 = @(x,y)x(1)*y(2)-x(2)*y(1);
  c = [cross2(a,b),cross2(2*d,b)+cross2(a,e),cross2(e,b)+cross2(a,2*f), ...
    cross2(2*d,e),4*cross2(d,f),cross2(e,2*f)];
end


% Source: refine_i102.m lines 2851-2854, LOCAL_q.
function value = LOCAL_q(c,x,y)
  value = c(1)+c(2)*x+c(3)*y+c(4)*x.^2+c(5)*x.*y+c(6)*y.^2;
end


% Source: refine_i102.m lines 2855-2874, LOCAL_quadratic_triangle_extrema.
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
