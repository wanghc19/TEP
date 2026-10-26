function fem_dtn_i95b(output_dir,mode)
%FEM_DTN_I95B I9.5b FEM+DtN candidate: three cell templates and exact discrete leads.
% Purpose: Deliver the fixed-beta line-defect candidate of design-9-5b (D2):
%   a single centre cell coupled to both infinite periodic leads through the
%   complete discrete stable-subspace DtN, solved as a local nonlinear root of
%   the centre wall Schur complement; coarse, fine-Q10, fine-Q12 (and a
%   conditional fine-Q16) chains with stability and same-mode evidence.
% Input: output_dir is a new run directory; mode is 'formal', 'smoke' or
%   'meshcheck' (formal mesh levels and repair only, no solves).
% Output: config.json, result.json, candidates.csv, iterations.csv,
%   evidence.mat, progress.json, figures/*.png (BIE never enters this code).
% Main algorithm:
%   1. joint three-cell curved-P2 mesh with deterministic repair; extract the
%      left/centre/right templates, assemble K, M and eliminate only top/bottom
%      quasi-periodic slaves (Qqp); 1D P2 wall mass W = R'*R;
%   2. per frequency: lead interior LU/multi-RHS -> S, complex ordered QZ of
%      [-(S11+S00) -S10; I 0] - zeta [S01 0; 0 I] -> Pout = Z1/Z0,
%      D = S00 + S01*Pout; centre Cholesky -> S_c; F = S_c + diag(D-,D+),
%      H = R'^{-1} F R^{-1} and its real eigen-branches;
%   3. branch selection/tracking, fixed half-width bracketing, Brent root;
%   4. recovery, delivery checks, display cells, figures and machine output.
% Based on: test/i9/compare-v1/fem_i9_run.m (curve, mesh, P2 basis, Duffy
%   quadrature, curved determinant extrema) and test/i9/eq-temple-v1/
%   eq_tail_build_i95.m (reference cell, top/bottom phase, wall sorting, Schur).
% Main changes: no x-end Dirichlet elimination, QZ deflating subspace instead of
%   polyeig eigenvector inversion, DtN enters the centre equation directly,
%   det-ratio mesh repair, mutually exclusive timers and internal memory gate.
%   D2: bounded local edge flip after the deletion rounds (no Delaunay re-run,
%   no new vertices/dofs), structured geometry failure_kind and structural
%   booleans, fine-q10 independent entry from k0 only after a pure-geometry
%   coarse failure, effective required chain and recorded missing control.
% Numerical goal: candidate k with bracket <= 1e-10, |lambda(H)| <= 1e-10 and
%   uncondensed centre residual <= 1e-9; ordinary floating-point evidence only.
  if nargin < 2, mode = 'formal'; end
  entry_utc = char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSSSSSXXX'));
  started = tic;
  config = fem_dtn_i95b_config(mode);
  if ~isfolder(output_dir), mkdir(output_dir); end
  if ~isfolder(fullfile(output_dir,'figures')), mkdir(fullfile(output_dir,'figures')); end
  maxNumCompThreads(config.resources.threads);
  ctx = struct('output_dir',output_dir,'started',started,'config',config, ...
    'iterations_path',fullfile(output_dir,'iterations.csv'), ...
    'progress_path',fullfile(output_dir,'progress.json'),'remaining_required',{{}}, ...
    'effective_required',{{'coarse','fine-q10','fine-q12'}},'coarse_control_unavailable',false);
  ledger = LOCAL_ledger();
  LOCAL_json(fullfile(output_dir,'config.json'),config);
  environment = struct('matlab_version',version,'platform',computer, ...
    'max_threads',maxNumCompThreads,'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS'), ...
    'entry_utc',entry_utc,'pid',feature('getpid'));
  if strcmp(mode,'meshcheck')
    LOCAL_mesh_check(config,output_dir); return    % diagnostic only, no solves
  end
  LOCAL_iteration_header(ctx.iterations_path);
  fprintf('ENTRY %s mode=%s threads=%d\n',entry_utc,mode,maxNumCompThreads);
  chains = struct([]); meshes = struct('key',{},'mesh',{},'geometry',{});
  current_mesh_key = ''; mesh = []; geometry = [];
  stage = 'configuration'; final_candidate_elapsed = NaN;
  evidence = struct('configurations',struct([]));
  try
    for j = 1:numel(config.configurations)
      cfg = config.configurations(j);
      later = config.configurations(j+1:end);
      ctx.remaining_required = {later(~[later.conditional]).name};
      item = LOCAL_chain_stub(cfg);
      % --- stage 0: dependency and conditional trigger ---
      [run_it,parent,why,init] = LOCAL_should_run(cfg,chains,config,toc(started));
      item.initialization_source = init.source; item.fine_entry = init.fine_entry;
      item.coarse_control_unavailable = init.coarse_control_unavailable;
      if init.coarse_control_unavailable
        % D2 effective required chain: coarse dropped, its failure time kept
        ctx.coarse_control_unavailable = true;
        ctx.effective_required = {'fine-q10','fine-q12'};
        if isfield(init.fine_entry,'admitted')
          fprintf('CHAIN %s independent entry from k0: %s\n',cfg.name,init.source);
        end
      end
      if ~run_it
        item.status = 'NOT_RUN'; item.reason = why; item.initialization_source = 'NONE';
        chains = LOCAL_append(chains,item);
        fprintf('CHAIN %s not run: %s\n',cfg.name,why);
        continue
      end
      % --- stage 1: mesh and repair (shared by configurations with one key) ---
      LOCAL_progress(ctx,cfg.name,'mesh',struct());
      if ~strcmp(cfg.mesh_key,current_mesh_key)
        stage = ['mesh:',cfg.name]; timer = tic;
        mesh = []; geometry = []; %#ok<NASGU> release the previous level
        [mesh,geometry] = LOCAL_mesh(config,cfg);
        dt = toc(timer); ledger.mesh_repair = ledger.mesh_repair + dt;
        item.precompute_seconds = item.precompute_seconds + dt;
        current_mesh_key = cfg.mesh_key;
        meshes(end+1) = struct('key',cfg.mesh_key,'mesh',mesh,'geometry',geometry); %#ok<AGROW>
        fprintf('STAGE mesh %s: %d triangles, %d P2 nodes, status %s, %.2fs\n',cfg.mesh_key, ...
          size(mesh.triangles,1),size(mesh.p2_points,1),geometry.status,dt);
      end
      item.mesh_key = cfg.mesh_key; item.geometry_status = geometry.status;
      item.geometry_failure_kind = geometry.failure_kind;
      item.mesh_structural_checks_pass = geometry.mesh_structural_checks_pass;
      item.flip_stage_entered = geometry.flip_stage_entered;
      if ~strcmp(geometry.status,'PASS')
        item.status = 'GEOMETRY_FAILED'; item.reason = geometry.reason;
        chains = LOCAL_append(chains,item);
        LOCAL_partial(ctx,chains,ledger);
        continue
      end
      % --- stage 2: templates, Qqp, K/M, wall mass ---
      stage = ['assembly:',cfg.name]; timer = tic; item.assembly_started = true;
      LOCAL_progress(ctx,cfg.name,'assembly',struct());
      templates = LOCAL_templates(config,cfg,mesh);
      dt = toc(timer); ledger.assembly = ledger.assembly + dt;
      item.precompute_seconds = item.precompute_seconds + dt;
      item.dimensions = templates.dimensions; item.matrix_checks = templates.checks;
      fprintf('STAGE assembly %s Q%d: wall n=%d, free dofs [%d %d %d], %.2fs\n',cfg.name, ...
        cfg.quadrature_order,templates.n,templates.dimensions.free_dofs,dt);
      if ~templates.checks.pass
        item.status = 'CELL_OR_DTN_EXCEPTION'; item.reason = 'MATRIX_CHECK_FAILED';
        chains = LOCAL_append(chains,item);
        LOCAL_partial(ctx,chains,ledger);
        continue
      end
      % --- stage 3: local branch chain and bracketed root ---
      stage = ['root:',cfg.name]; timer = tic;
      reference = LOCAL_reference(parent,templates);
      [item,sub] = LOCAL_chain(ctx,item,cfg,templates,parent,reference);
      chain_total = toc(timer);
      ledger.lead_elimination = ledger.lead_elimination + sub.lead_elimination;
      ledger.qz_dtn = ledger.qz_dtn + sub.qz_dtn;
      ledger.center_small = ledger.center_small + sub.center_small;
      ledger.root_control = ledger.root_control + chain_total - sub.total;
      item.root_seconds = chain_total;
      % --- stage 4: recovery and delivery checks at the root ---
      if strcmp(item.status,'ROOT_FOUND')
        stage = ['recovery:',cfg.name]; timer = tic;
        LOCAL_progress(ctx,cfg.name,'recovery',struct('slowest_eval_seconds',item.slowest_eval_seconds));
        [item,record,sub] = LOCAL_recover(ctx,item,cfg,templates);
        dt = toc(timer);
        ledger.lead_elimination = ledger.lead_elimination + sub.lead_elimination;
        ledger.qz_dtn = ledger.qz_dtn + sub.qz_dtn;
        ledger.center_small = ledger.center_small + sub.center_small;
        ledger.recovery_checks = ledger.recovery_checks + dt - sub.total;
        item.recovery_seconds = dt;
        if ~isempty(record)
          evidence.configurations = LOCAL_append(evidence.configurations,record);
        end
      end
      item.matlab_elapsed_at_completion = toc(started);
      chains = LOCAL_append(chains,item);
      fprintf('CHAIN %s status %s k=%.16g evals=%d root %.2fs recovery %.2fs\n',cfg.name, ...
        item.status,item.k,item.frequency_count,item.root_seconds,item.recovery_seconds);
      % store assembled forms (real K_full/M_full, Qqp) for re-checking
      evidence.forms.(strrep(cfg.name,'-','_')) = LOCAL_forms_record(templates);
      timer = tic; LOCAL_partial(ctx,chains,ledger); ledger.save = ledger.save + toc(timer);
      clear templates
    end
    % --- stage 5: same-mode evidence, final status and candidate ---
    stage = 'final_status'; timer = tic;
    [result,chains] = LOCAL_final(config,chains,evidence);
    if result.final_candidate_index > 0
      final_candidate_elapsed = chains(result.final_candidate_index).matlab_elapsed_at_completion;
    end
    result.matlab_elapsed_at_final_candidate = final_candidate_elapsed;
    ledger.recovery_checks = ledger.recovery_checks + toc(timer);
    % --- stage 6: figures (MATLAB native) ---
    stage = 'figures'; timer = tic;
    LOCAL_progress(ctx,'all','figures',struct('all_required_converged',result.all_required_converged));
    figure_status = LOCAL_figures(ctx,config,chains,evidence,meshes,ledger,result);
    ledger.summary_figures = ledger.summary_figures + toc(timer);
    % --- stage 7: save machine outputs ---
    stage = 'save'; timer = tic;
    LOCAL_progress(ctx,'all','save',struct('all_required_converged',result.all_required_converged));
    info = whos('evidence','meshes','chains');
    estimate_bytes = sum([info.bytes]);
    LOCAL_memory_gate(config,'export',2*estimate_bytes);
    result.environment = environment; result.figures = figure_status;
    result.chains = chains; result.mode = mode;
    LOCAL_write_candidates(fullfile(output_dir,'candidates.csv'),chains);
    save(fullfile(output_dir,'evidence.mat'),'config','chains','evidence','meshes','result','-v7');
    ledger.save = ledger.save + toc(timer);
    result.timing = LOCAL_ledger_close(ledger,toc(started));
    result.export_estimate_bytes = estimate_bytes;
    LOCAL_json(fullfile(output_dir,'result.json'),result);
    LOCAL_progress(ctx,'all','done',struct('all_required_converged',result.all_required_converged));
    fprintf('COMPLETE %s final_k=%.16g matlab %.2fs\n',result.final_status, ...
      result.final_k,toc(started));
  catch error_object
    status = 'CELL_OR_DTN_EXCEPTION';
    if strcmp(error_object.identifier,'i95b:ResourceStop'), status = 'RESOURCE_STOP'; end
    failure = struct('stage',stage,'status',status,'identifier',error_object.identifier, ...
      'message',error_object.message,'report',getReport(error_object,'extended','hyperlinks','off'), ...
      'elapsed_seconds',toc(started),'timing',LOCAL_ledger_close(ledger,toc(started)));
    failure.stack = error_object.stack;
    LOCAL_json(fullfile(output_dir,'failure.json'),failure);
    LOCAL_partial(ctx,chains,ledger);
    rethrow(error_object);
  end
end

%% ==================== Dependency control and chain records ====================
% Fixed initial-value sources and the single conditional Q16 trigger.
function item = LOCAL_chain_stub(cfg)
  item = struct('name',cfg.name,'subdivisions',cfg.subdivisions, ...
    'interface_segments',cfg.interface_segments,'quadrature_order',cfg.quadrature_order, ...
    'mesh_key',cfg.mesh_key,'parent',cfg.parent,'status','PENDING','reason','', ...
    'k_init',NaN,'k',NaN,'mu',NaN,'bracket_low',NaN,'bracket_high',NaN,'bracket_width',NaN, ...
    'lambda',NaN,'lambda_scaled',NaN,'branch_index',NaN,'qualified',false, ...
    'center_residual',NaN,'frequency_count',0,'cache_hits',0,'halvings',0, ...
    'slowest_eval_seconds',0,'precompute_seconds',0,'root_seconds',0,'recovery_seconds',0, ...
    'matlab_elapsed_at_completion',NaN,'geometry_status','','dimensions',struct(), ...
    'matrix_checks',struct(),'selection',struct(),'root',struct(),'dtn',struct(), ...
    'delivery',struct(),'same_mode',struct(),'initialization_source','', ...
    'coarse_control_unavailable',false,'fine_entry',struct(),'geometry_failure_kind','', ...
    'mesh_structural_checks_pass',false,'flip_stage_entered',false,'assembly_started',false);
end

function [run_it,parent,why,init] = LOCAL_should_run(cfg,chains,config,elapsed)
  % Usual sources: coarse <- k0, fine-q10 <- coarse root, fine-q12 <- fine-q10,
  % triggered fine-q16 <- fine-q12. D2 sole exception (design 4.2): fine-q10
  % starts from the explicit scalar k0 when LOCAL_fine_entry admits the coarse
  % failure; every other dependency failure still stops the later chains.
  run_it = true; parent = []; why = '';
  init = struct('source','E2_K0','coarse_control_unavailable',false,'fine_entry',struct());
  if isempty(cfg.parent), return, end
  names = arrayfun(@(c)c.name,chains,'UniformOutput',false);
  p = find(strcmp(names,cfg.parent),1);
  if isempty(p) || ~chains(p).qualified
    run_it = false; why = sprintf('parent %s has no qualified root',cfg.parent);
    if ~isempty(p) && strcmp(cfg.name,config.fine_entry.chain) && ...
        strcmp(cfg.parent,config.fine_entry.coarse)
      entry = LOCAL_fine_entry(chains(p),config,elapsed);
      init.fine_entry = entry;
      if entry.admitted
        run_it = true; why = '';
        init.source = config.fine_entry.initialization_source;
        init.coarse_control_unavailable = true;
      else
        why = sprintf('%s; fine independent entry refused: %s',why,entry.reason);
      end
    end
    return
  end
  parent = chains(p); init.source = ['PARENT_ROOT:',parent.name];
  init.coarse_control_unavailable = parent.coarse_control_unavailable;
  if cfg.conditional
    g = find(strcmp(names,parent.parent),1);
    if isempty(g) || ~chains(g).qualified
      run_it = false; why = 'grandparent not qualified'; return
    end
    difference = abs(parent.k-chains(g).k);
    if difference <= config.q_trigger
      run_it = false; why = sprintf('|k(%s)-k(%s)|=%.3e <= %.0e',parent.name,chains(g).name, ...
        difference,config.q_trigger);
    end
  end
end

function entry = LOCAL_fine_entry(coarse,config,elapsed)
  % Admission of the fine independent entry from structured coarse records
  % only (never from status strings alone or historical diagnostics).
  rule = config.fine_entry;
  entry = struct('admitted',false,'reason','', ...
    'coarse_status',coarse.status,'coarse_reason',coarse.reason, ...
    'coarse_failure_kind',coarse.geometry_failure_kind, ...
    'coarse_failure_kind_whitelisted',any(strcmp(coarse.geometry_failure_kind,rule.failure_kinds)), ...
    'coarse_mesh_structural_checks_pass',coarse.mesh_structural_checks_pass, ...
    'coarse_flip_stage_entered',coarse.flip_stage_entered, ...
    'coarse_assembly_started',coarse.assembly_started, ...
    'coarse_frequency_count',coarse.frequency_count, ...
    'elapsed_seconds',elapsed,'remaining_estimate_seconds',rule.remaining_estimate_seconds, ...
    'soft_seconds',config.resources.soft_seconds, ...
    'budget_sufficient',elapsed+rule.remaining_estimate_seconds<=config.resources.soft_seconds);
  tests = {strcmp(coarse.status,'GEOMETRY_FAILED'),'coarse status is not GEOMETRY_FAILED'; ...
    entry.coarse_failure_kind_whitelisted,'coarse failure_kind not whitelisted'; ...
    coarse.mesh_structural_checks_pass,'coarse structural checks not passed'; ...
    coarse.flip_stage_entered,'coarse local repair (flip stage) not executed'; ...
    ~coarse.assembly_started && coarse.frequency_count==0,'coarse assembly/evaluation started'; ...
    entry.budget_sufficient,'remaining budget insufficient for the fine chains'};
  failed = find(~cellfun(@logical,tests(:,1)),1);
  if isempty(failed)
    entry.admitted = true; entry.reason = 'pure-geometry coarse failure; all entry conditions met';
  else
    entry.reason = tests{failed,2};
  end
end

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
  assert(all(abs(mesh.points(:))<2) && tol>0,'i95b:Mesh','Mesh points escaped the three-cell box.');
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
  assert(numel(first)==size(points,1),'i95b:Duplicate','Mesh input contains duplicate points.');
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
  assert(size(dt.Points,1)==size(points,1),'i95b:Steiner','Triangulation inserted points.');
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

function LOCAL_mesh_check(config,output_dir)
  % Mesh/repair diagnostic of each distinct frozen mesh level; the bad elements
  % are listed with the role of each vertex (wall/top-bottom grid, free grid,
  % interface curve, inner/outer ring). No assembly, DtN or root solve.
  keys = unique({config.configurations.mesh_key},'stable'); report = struct([]);
  for key = keys
    cfg = config.configurations(find(strcmp({config.configurations.mesh_key},key{1}),1));
    timer = tic; [mesh,geometry] = LOCAL_mesh(config,cfg); seconds = toc(timer);
    bad = find(mesh.det_min<=0 | mesh.det_ratio>config.mesh_rules.det_ratio_max);
    tol = 1e-12; elements = struct([]);
    for t = bad'
      vertices = mesh.points(mesh.triangles(t,:),:); role = cell(1,3);
      for v = 1:3
        role{v} = 'free_grid';
        p = vertices(v,:);
        for c = 1:3
          if min(vecnorm(mesh.curves{c}-p,2,2))<tol, role{v} = 'interface_curve'; end
          if min(vecnorm(mesh.rings{c,1}-p,2,2))<tol, role{v} = 'inner_ring'; end
          if min(vecnorm(mesh.rings{c,2}-p,2,2))<tol, role{v} = 'outer_ring'; end
        end
        if abs(abs(p(2))-0.5)<tol || abs(mod(p(1)+0.5,1))<tol || abs(mod(p(1)+0.5,1)-1)<tol
          role{v} = 'wall_or_top_bottom';
        end
      end
      item = struct('element',t,'det_min',mesh.det_min(t),'det_ratio',mesh.det_ratio(t), ...
        'cell',mesh.cell_id(t),'material',mesh.material(t),'vertices',vertices,'roles',{role});
      elements = LOCAL_append(elements,item);
    end
    entry = struct('mesh_key',key{1},'subdivisions',cfg.subdivisions, ...
      'interface_segments',cfg.interface_segments,'status',geometry.status, ...
      'reason',geometry.reason,'failure_kind',geometry.failure_kind, ...
      'mesh_structural_checks_pass',geometry.mesh_structural_checks_pass, ...
      'flip_stage_entered',geometry.flip_stage_entered,'flip',geometry.flip, ...
      'repair_seconds',geometry.repair_seconds,'seconds',seconds,'triangles',size(mesh.triangles,1), ...
      'p2_nodes',size(mesh.p2_points,1),'det_ratio_max',geometry.det_ratio_max, ...
      'bad_elements',{elements},'repair_rounds',geometry.repair_rounds, ...
      'shape_quality',geometry.shape_quality,'min_angle_degrees',geometry.min_angle_degrees);
    report = LOCAL_append(report,entry);
    fprintf('MESHCHECK %s: %s, %d bad elements, max det ratio %.4g, %.2fs\n',key{1}, ...
      geometry.status,numel(bad),geometry.det_ratio_max,seconds);
  end
  LOCAL_json(fullfile(output_dir,'mesh-check.json'),struct('status','MESH_DIAGNOSTIC_ONLY', ...
    'levels',report));
end

%% ==================== Template assembly and quasi-periodic reduction ====================
% Each cell template keeps both vertical walls; only y=+1/2 slaves are eliminated.
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

function record = LOCAL_forms_record(templates)
  record = struct();
  for name = {'left','center','right'}
    t = templates.(name{1});
    record.(name{1}) = struct('xy',t.xy,'tri6',t.tri6,'material',t.material,'nodes',t.nodes, ...
      'K_full',t.K_full,'M_full',t.M_full,'Qqp',t.Qqp,'free',t.free,'wall',t.wall, ...
      'interior',t.interior,'wall_y',t.wall_y);
  end
  record.wall_mass = templates.wall_mass; record.quadrature_order = templates.quadrature_order;
end

%% ==================== Cell elimination and discrete DtN ====================
% Weak outward wall load S = A_WW + A_WI E_I; ordered complex QZ stable subspace.
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

function [D,Pout,info] = LOCAL_dtn(config,S,n)
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
    [D,Pout,dinfo] = LOCAL_dtn(config,S,n);
    res.times.qz_dtn = res.times.qz_dtn+toc(timer);
    res.dtn.(name) = rmfield(dinfo,{'stable_multipliers'});
    if ~dinfo.valid
      res.valid = false; res.(['reason_',name]) = dinfo.reason; continue
    end
    res.(['D_',name]) = D;
    if want_extension
      ext.(name) = struct('S',S,'E',E,'D',D,'Pout',Pout,'multipliers',dinfo.stable_multipliers);
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

%% ==================== Branch tracking and bracketed root ====================
% Fixed algebraic index, half-width bracketing around the chain start, Brent.
function reference = LOCAL_reference(parent,templates)
  reference = struct('type','smallest','y',[],'g_transfer',[]);
  if isempty(parent), return, end
  g = LOCAL_transfer(parent.delivery.g,parent.subdivisions,templates.center.wall_y, ...
    templates.beta);
  y = templates.wall_chol*g; y = y/norm(y);
  reference = struct('type','transfer','y',y,'g_transfer',g);
end

function [item,sub] = LOCAL_chain(ctx,item,cfg,templates,parent,reference)
  config = ctx.config; R = config.root;
  if isempty(parent), k_init = config.k0; else, k_init = parent.k; end
  item.k_init = k_init;
  state = struct('ks',[],'results',{{}},'count',0,'hits',0,'sub', ...
    struct('lead_elimination',0,'qz_dtn',0,'center_small',0,'total',0),'slowest',0, ...
    'index',NaN,'accepted_k',[],'accepted_y',{{}},'accepted_lambda',[],'halvings',0);
  % --- branch selection at the chain start ---
  [r0,state] = LOCAL_eval_cached(ctx,templates,cfg,state,k_init,'init');
  if ~r0.valid
    item.status = 'CELL_OR_DTN_EXCEPTION';
    item.reason = sprintf('invalid initial point: L[%s] R[%s] C[%s]',r0.reason_left, ...
      r0.reason_right,r0.reason_center);
    for side = [-1,1]
      [~,state] = LOCAL_eval_cached(ctx,templates,cfg,state, ...
        LOCAL_clip(config,k_init+side*R.half_widths(1)),'diagnostic');
    end
    [item,sub] = LOCAL_chain_close(item,state); return
  end
  [~,near] = sort(abs(r0.lambda)); near = near(1:min(R.nearest_count,numel(near)));
  selection = struct('type',reference.type,'nearest_indices',near', ...
    'nearest_lambda',r0.lambda(near)','correlations',[],'index',NaN,'gap',NaN, ...
    'gap_threshold',R.gap_factor*max(1,r0.H_norm),'H_norm',r0.H_norm, ...
    'transfer_correlation','NOT_APPLICABLE_FIRST_CHAIN');
  if strcmp(reference.type,'transfer'), selection.transfer_correlation = 'APPLIED'; end
  if strcmp(reference.type,'smallest')
    index = near(1);
  else
    corr = abs(r0.V(:,near)'*reference.y)';
    selection.correlations = corr;
    hits = find(corr>=R.select_corr_min);
    if numel(hits)~=1
      item.status = 'MODE_AMBIGUOUS';
      item.reason = sprintf('%d of 5 nearest eigenvectors reach correlation %.2f (max %.4f)', ...
        numel(hits),R.select_corr_min,max(corr));
      item.selection = selection; [item,sub] = LOCAL_chain_close(item,state); return
    end
    index = near(hits);
  end
  selection.index = index; selection.gap = LOCAL_gap(r0.lambda,index);
  item.selection = selection; item.branch_index = index; state.index = index;
  if ~(selection.gap>=selection.gap_threshold)
    item.status = 'MODE_AMBIGUOUS';
    item.reason = sprintf('target gap %.3e below %.3e',selection.gap,selection.gap_threshold);
    [item,sub] = LOCAL_chain_close(item,state); return
  end
  start = LOCAL_point(r0,index);
  LOCAL_iteration_row(ctx,cfg,state,r0,'selection',true,0);   % init row with the chosen branch
  fprintf('  chain %s start k=%.16g index %d lambda %.3e gap %.3e\n',cfg.name,k_init, ...
    index,start.lambda,selection.gap);
  % --- fixed half-width bracketing around the chain start ---
  last = {start,start}; blocked = [false,false]; bracket = [];
  if start.lambda==0, bracket = [start,start]; end
  for hw = R.half_widths
    if ~isempty(bracket), break, end
    for side = 1:2
      if blocked(side) || ~isempty(bracket), continue, end
      target = LOCAL_clip(config,k_init+(2*side-3)*hw);
      if target==last{side}.k, continue, end
      [state,path,ok,why] = LOCAL_advance(ctx,templates,cfg,state,last{side},target);
      for j = 1:numel(path)-1
        if sign(path(j).lambda)~=sign(path(j+1).lambda)
          bracket = path(j:j+1); break
        end
      end
      if ~isempty(path), last{side} = path(end); end
      if ~ok
        if strcmp(why,'BRANCH_UNRESOLVED')
          item.status = 'MODE_AMBIGUOUS';
          item.reason = 'branch overlap/gap unresolved after 8 step halvings';
          [item,sub] = LOCAL_chain_close(item,state); return
        elseif strcmp(why,'FREQUENCY_LIMIT')
          item.status = 'NO_LOCAL_BRACKET'; item.reason = 'frequency limit before bracket';
          [item,sub] = LOCAL_chain_close(item,state); return
        end
        blocked(side) = true;
        item.reason = [item.reason,sprintf('side %d blocked: %s; ',side,why)];
      end
    end
  end
  if isempty(bracket)
    item.status = 'NO_LOCAL_BRACKET';
    item.reason = [item.reason,'no valid same-branch sign change within the fixed window'];
    [item,sub] = LOCAL_chain_close(item,state); return
  end
  % --- Brent root on the signed branch eigenvalue ---
  [item,state] = LOCAL_brent(ctx,templates,cfg,state,item,bracket);
  [item,sub] = LOCAL_chain_close(item,state);
end

function [item,sub] = LOCAL_chain_close(item,state)
  item.frequency_count = state.count; item.cache_hits = state.hits;
  item.slowest_eval_seconds = state.slowest; item.halvings = state.halvings;
  sub = state.sub;
end

function k = LOCAL_clip(config,k)
  k = min(max(k,config.window(1)),config.window(2));
end

function gap = LOCAL_gap(lambda,index)
  others = lambda; others(index) = []; gap = min(abs(others-lambda(index)));
end

function point = LOCAL_point(res,index)
  point = struct('k',res.k,'lambda',res.lambda(index),'y',res.V(:,index), ...
    'gap',LOCAL_gap(res.lambda,index),'H_norm',res.H_norm);
end

function [state,path,ok,why] = LOCAL_advance(ctx,templates,cfg,state,from,target)
  % Continue the fixed branch from an accepted point to target with step halving.
  R = ctx.config.root; path = from; ok = true; why = ''; current = from; pending = target;
  halvings = 0;
  while current.k ~= target
    if state.count>=R.max_frequencies && ~LOCAL_cached(state,pending)
      ok = false; why = 'FREQUENCY_LIMIT'; return
    end
    [res,state] = LOCAL_eval_cached(ctx,templates,cfg,state,pending,'bracket');
    if ~res.valid
      ok = false; why = sprintf('invalid at k=%.16g: L[%s] R[%s] C[%s]',pending, ...
        res.reason_left,res.reason_right,res.reason_center); return
    end
    point = LOCAL_point(res,state.index);
    overlap = abs(current.y'*point.y);
    if overlap>=R.overlap_min && point.gap>=R.gap_factor*max(1,point.H_norm)
      path(end+1) = point; current = point; pending = target; %#ok<AGROW>
      state = LOCAL_accept(state,point);
      if sign(path(end-1).lambda)~=sign(point.lambda), return, end
    else
      halvings = halvings+1; state.halvings = state.halvings+1;
      if halvings>R.max_halvings, ok = false; why = 'BRANCH_UNRESOLVED'; return, end
      pending = (current.k+pending)/2;
    end
  end
end

function state = LOCAL_accept(state,point)
  state.accepted_k(end+1) = point.k; state.accepted_y{end+1} = point.y;
  state.accepted_lambda(end+1) = point.lambda;
end

function [item,state] = LOCAL_brent(ctx,templates,cfg,state,item,bracket)
  config = ctx.config; R = config.root; tol = R.bracket_width/4;
  a = bracket(1).k; fa = bracket(1).lambda; b = bracket(2).k; fb = bracket(2).lambda;
  c = a; fc = fa; d = b-a; e = d; converged = false; reason = '';
  item.root = struct('initial_bracket',sort([a,b]),'iterations',0,'bisections',0, ...
    'branch_fallbacks',0);
  bisect_only = false;
  while true
    if sign(fb)==sign(fc) && fb~=0, c = a; fc = fa; d = b-a; e = d; end
    if abs(fc)<abs(fb), a = b; b = c; c = a; fa = fb; fb = fc; fc = fa; end
    tol1 = 2*eps*abs(b)+0.5*tol; xm = 0.5*(c-b);
    LOCAL_progress(ctx,cfg.name,'root',struct('bracket_width',abs(c-b), ...
      'slowest_eval_seconds',state.slowest,'frequency_count',state.count));
    if (abs(c-b)<=R.bracket_width && abs(fb)<=R.eig_abs) || fb==0
      converged = true; break
    end
    if abs(c-b)<=R.bracket_width, bisect_only = true; end
    if abs(c-b)<=8*eps*abs(b)
      reason = 'bracket reached floating-point resolution before |lambda| gate'; break
    end
    if ~bisect_only && abs(e)>=tol1 && abs(fa)>abs(fb)
      s = fb/fa;
      if a==c
        p = 2*xm*s; q = 1-s;
      else
        q = fa/fc; r = fb/fc;
        p = s*(2*xm*q*(q-r)-(b-a)*(r-1)); q = (q-1)*(r-1)*(s-1);
      end
      if p>0, q = -q; else, p = -p; end
      if 2*p<min(3*xm*q-abs(tol1*q),abs(e*q))
        e = d; d = p/q;
      else
        d = xm; e = d; item.root.bisections = item.root.bisections+1;
      end
    else
      d = xm; e = d; item.root.bisections = item.root.bisections+1;
    end
    if bisect_only, d = xm; end
    a = b; fa = fb;
    if abs(d)>tol1, trial = b+d; else, trial = b+sign(xm)*tol1; end
    % evaluate with branch protection; failing trials fall back to bisection
    fallback = 0;
    while true
      if state.count>=R.max_frequencies && ~LOCAL_cached(state,trial)
        reason = 'frequency limit reached'; break
      end
      [res,state] = LOCAL_eval_cached(ctx,templates,cfg,state,trial,'root');
      item.root.iterations = item.root.iterations+1;
      if ~res.valid
        item.status = 'CELL_OR_DTN_EXCEPTION';
        item.reason = sprintf('invalid point inside bracket k=%.16g: L[%s] R[%s] C[%s]', ...
          trial,res.reason_left,res.reason_right,res.reason_center);
        return
      end
      point = LOCAL_point(res,state.index);
      [~,nearest] = min(abs(state.accepted_k-trial));
      overlap = abs(state.accepted_y{nearest}'*point.y);
      if overlap>=R.overlap_min && point.gap>=R.gap_factor*max(1,point.H_norm)
        state = LOCAL_accept(state,point); break
      end
      fallback = fallback+1; state.halvings = state.halvings+1;
      item.root.branch_fallbacks = item.root.branch_fallbacks+1;
      if fallback>R.max_halvings
        item.status = 'MODE_AMBIGUOUS';
        item.reason = 'branch overlap/gap unresolved inside root bracket'; return
      end
      trial = (trial+a)/2;     % move toward the last accepted iterate (bisection)
    end
    if ~isempty(reason), break, end
    b = trial; fb = point.lambda;
  end
  item.k = b; item.mu = b^2; item.lambda = fb;
  item.bracket_low = min(b,c); item.bracket_high = max(b,c); item.bracket_width = abs(c-b);
  [~,nearest] = min(abs(state.ks-b)); res = state.results{nearest};
  item.lambda_scaled = abs(fb)/max(1,res.H_norm);
  if converged
    item.status = 'ROOT_FOUND';
  else
    item.status = 'ROOT_NOT_CONVERGED'; item.reason = reason;
  end
end

function hit = LOCAL_cached(state,k)
  hit = any(state.ks==k);
end

function [res,state] = LOCAL_eval_cached(ctx,templates,cfg,state,k,purpose)
  j = find(state.ks==k,1);
  if ~isempty(j)
    res = state.results{j}; state.hits = state.hits+1;
    LOCAL_iteration_row(ctx,cfg,state,res,purpose,true,0);
    return
  end
  timer = tic;
  res = LOCAL_evaluate(ctx.config,templates,k,false);
  elapsed = toc(timer);
  state.count = state.count+1;
  state.sub.lead_elimination = state.sub.lead_elimination+res.times.lead_elimination;
  state.sub.qz_dtn = state.sub.qz_dtn+res.times.qz_dtn;
  state.sub.center_small = state.sub.center_small+res.times.center_small;
  state.sub.total = state.sub.total+res.times.lead_elimination+res.times.qz_dtn+res.times.center_small;
  state.slowest = max(state.slowest,elapsed);
  % frequency history keeps only small matrices, scalars and branch vectors
  state.ks(end+1) = k; state.results{end+1} = res;
  LOCAL_iteration_row(ctx,cfg,state,res,purpose,false,elapsed);
  if ~strcmp(purpose,'root')
    LOCAL_progress(ctx,cfg.name,purpose,struct('slowest_eval_seconds',state.slowest, ...
      'frequency_count',state.count));
  end
end

%% ==================== Recovery and delivery checks ====================
% Uncondensed centre residual with raw D, display cells and load balance.
function [item,record,sub] = LOCAL_recover(ctx,item,cfg,templates)
  config = ctx.config; dl = config.delivery; n = templates.n; k = item.k; mu = k^2;
  [res,ext] = LOCAL_evaluate(config,templates,k,true);
  sub = struct('lead_elimination',res.times.lead_elimination,'qz_dtn',res.times.qz_dtn, ...
    'center_small',res.times.center_small);
  sub.total = sub.lead_elimination+sub.qz_dtn+sub.center_small;
  record = [];
  index = item.branch_index;
  LOCAL_iteration_row(ctx,cfg,struct('count',item.frequency_count,'index',index),res, ...
    'recovery',false,sub.total);
  if ~res.valid
    item.status = 'CELL_OR_DTN_EXCEPTION'; item.reason = 'root response invalid on recovery';
    return
  end
  record = struct('name',cfg.name);
  y = res.V(:,index); g = templates.wall_chol\y;
  c = templates.center; Ec = ext.center.E;
  u = complex(zeros(numel(c.free),1)); u(c.wall) = g; u(c.interior) = Ec*g;
  scale = 1/sqrt(real(u'*c.M*u)); u = u*scale; g = g*scale;
  full_u = c.Qqp*u; [~,at] = max(abs(full_u)); phase = conj(full_u(at))/abs(full_u(at));
  u = u*phase; g = g*phase; full_u = full_u*phase;
  % uncondensed centre residual with raw (unaveraged) D-/D+
  Ac = c.K-mu*c.M;
  Ku = c.K*u; Mu = c.M*u; gl = g(1:n); gr = g(n+1:end);
  DL = ext.left.D; DR = ext.right.D;
  r = Ku-mu*Mu; r(c.wall) = r(c.wall)+[DL*gl;DR*gr];
  denominator = norm(Ku)+abs(mu)*norm(Mu)+norm(DL*gl)+norm(DR*gr);
  center_residual = norm(r)/denominator;
  interior_res = norm(Ac(c.interior,:)*u)/(norm(Ac(c.interior,c.interior)*u(c.interior))+ ...
    norm(Ac(c.interior,c.wall)*g));
  delivery = struct('center_residual',center_residual,'center_residual_num',norm(r), ...
    'center_residual_den',denominator,'center_recovery_residual',interior_res, ...
    'lambda',res.lambda(index),'g',g,'wall_l2',sqrt(real(g'*templates.wall_mass*g)), ...
    'nearest_lambda',[],'center_mass',real(u'*c.M*u), ...
    'qp_defect',norm(full_u(c.top)-exp(1i*templates.beta)*full_u(c.bottom))/norm(full_u));
  [~,near] = sort(abs(res.lambda)); delivery.nearest_lambda = res.lambda(near(1:min(5,end)))';
  delivery.target_gap = LOCAL_gap(res.lambda,index);
  % lead display cells, flux continuity and weak-load balance
  sides = struct([]); display = struct('center',full_u);
  center_load = Ac(c.wall,:)*u;
  for side = {'left','right'}
    name = side{1}; t = templates.(name); L = ext.(name);
    if strcmp(name,'left'), g0 = gl; wall_load = center_load(1:n);
    else, g0 = gr; wall_load = center_load(n+1:end); end
    At = t.K-mu*t.M; S00 = L.S(1:n,1:n); S01 = L.S(1:n,n+1:end);
    S10 = L.S(n+1:end,1:n); S11 = L.S(n+1:end,n+1:end);
    cells = dl.display_cells; traces = zeros(n,cells+1); traces(:,1) = g0;
    for j = 1:cells, traces(:,j+1) = L.Pout*traces(:,j); end
    mass = zeros(1,cells); recovery = zeros(1,cells); balance = zeros(1,cells);
    continuity = zeros(1,cells); fields = cell(1,cells);
    for j = 1:cells
      v = complex(zeros(numel(t.free),1)); v(t.wall) = [traces(:,j);traces(:,j+1)];
      v(t.interior) = L.E*[traces(:,j);traces(:,j+1)];
      mass(j) = real(v'*t.M*v);
      recovery(j) = norm(At(t.interior,:)*v)/(norm(At(t.interior,t.interior)*v(t.interior))+ ...
        norm(At(t.interior,t.wall)*v(t.wall)));
      fields{j} = t.Qqp*v;
      if j==1
        % centre/lead wall: values coincide by construction; loads must cancel
        lead_load = S00*traces(:,1)+S01*traces(:,2);
        balance(j) = norm(wall_load+lead_load)/(norm(wall_load)+norm(lead_load));
        full_lead = fields{1};
        cw_nodes = find(abs(c.xy(:,1)-(-0.5+strcmp(name,'right')))<1e-11);
        tw_nodes = find(abs(t.xy(:,1)-(-0.5+strcmp(name,'right')))<1e-11);
        [~,a] = sort(c.xy(cw_nodes,2)); [~,b] = sort(t.xy(tw_nodes,2));
        continuity(j) = norm(full_u(cw_nodes(a))-full_lead(tw_nodes(b)))/max(norm(full_u(cw_nodes(a))),realmin);
      else
        prev = S10*traces(:,j-1)+S11*traces(:,j); next = S00*traces(:,j)+S01*traces(:,j+1);
        balance(j) = norm(prev+next)/(norm(prev)+norm(next));
        outer_prev = fields{j-1}; inner_next = fields{j};
        x1 = t.xy(:,1); wall0 = strcmp(name,'left')*(-0.5)+strcmp(name,'right')*0.5;
        wall1 = wall0+(2*strcmp(name,'right')-1);
        p = find(abs(x1-wall1)<1e-11); q = find(abs(x1-wall0)<1e-11);
        [~,a] = sort(t.xy(p,2)); [~,b] = sort(t.xy(q,2));
        continuity(j) = norm(outer_prev(p(a))-inner_next(q(b)))/max(norm(outer_prev(p(a))),realmin);
      end
    end
    trace_norms = vecnorm(traces); wall_norms = zeros(1,cells+1);
    for j = 1:cells+1, wall_norms(j) = sqrt(real(traces(:,j)'*templates.wall_mass_single*traces(:,j))); end
    qp = 0;
    for j = 1:cells
      qp = max(qp,norm(fields{j}(t.top)-exp(1i*templates.beta)*fields{j}(t.bottom))/max(norm(fields{j}),realmin));
    end
    item_side = struct('side',name,'cell_mass',mass,'trace_norms',trace_norms, ...
      'wall_l2_norms',wall_norms,'recovery_residual',recovery,'load_balance',balance, ...
      'value_continuity',continuity,'qp_defect',qp,'spectral_radius',max(abs(L.multipliers)), ...
      'multipliers_abs',sort(abs(L.multipliers),'descend')', ...
      'unit_gap_min',res.dtn.(name).unit_gap_min,'z0_rcond',res.dtn.(name).z0_rcond, ...
      'riccati',res.dtn.(name).riccati,'invariance',res.dtn.(name).invariance, ...
      'dtn_hermitian_defect',res.dtn.(name).hermitian_defect, ...
      'dtn_consistency',res.dtn.(name).consistency,'pairing_max',res.dtn.(name).pairing_max, ...
      'cell_condest',res.cell.(name).condest,'cell_backward',res.cell.(name).backward);
    sides = LOCAL_append(sides,item_side);
    display.(name) = fields;
    record.(name) = struct('S',L.S,'D_raw',L.D,'Pout',L.Pout,'multipliers',L.multipliers);
  end
  delivery.sides = sides;
  gates = [center_residual<=config.root.center_residual, ...
    interior_res<=dl.recovery_residual, delivery.qp_defect<=dl.qp];
  for j = 1:2
    s = sides(j);
    gates(end+1) = max(s.recovery_residual)<=dl.recovery_residual; %#ok<AGROW>
    gates(end+1) = max(s.value_continuity)<=dl.continuity; %#ok<AGROW>
    gates(end+1) = s.qp_defect<=dl.qp; %#ok<AGROW>
    gates(end+1) = max(s.load_balance)<=dl.load_balance; %#ok<AGROW>
  end
  delivery.gates = gates;
  delivery.gate_names = {'center_residual','center_recovery','center_qp', ...
    'left_recovery','left_continuity','left_qp','left_balance', ...
    'right_recovery','right_continuity','right_qp','right_balance'};
  item.delivery = delivery; item.center_residual = center_residual;
  item.dtn = struct('left',res.dtn.left,'right',res.dtn.right,'cell',res.cell);
  item.qualified = all(gates) && abs(item.lambda)<=config.root.eig_abs && ...
    item.bracket_width<=config.root.bracket_width;
  if item.qualified
    item.status = 'ROOT_QUALIFIED';
  else
    bad = delivery.gate_names(~gates);
    item.status = 'CELL_OR_DTN_EXCEPTION';
    if center_residual>config.root.center_residual, item.status = 'ROOT_NOT_CONVERGED'; end
    item.reason = ['delivery gates failed: ',strjoin(bad,',')];
  end
  record.center = struct('S',ext.center.S,'F_raw',ext.center.F,'H_raw',ext.center.H, ...
    'u',u,'g',g,'y',y,'lambda_all',res.lambda);
  record.display = display; record.k = k; record.delivery = rmfield(delivery,'sides');
  record.wall_y = templates.center.wall_y;
end

%% ==================== Wall traces, transfer and same-mode evidence ====================
% Physical 1D P2 wall traces on uniform wall nodes with quasi-periodic closure.
function values = LOCAL_wall_eval(g,s,beta,yq)
  n = 2*s; h = 1/s; yq = yq(:);
  m = min(floor((yq+0.5)/h),s-1); t = (yq+0.5)/h-m;
  ext = [g(:);exp(1i*beta)*g(1)];
  values = ext(2*m+1).*(1-t).*(1-2*t)+ext(2*m+2).*4.*t.*(1-t)+ext(2*m+3).*t.*(2*t-1);
  assert(numel(g)==n);
end

function g = LOCAL_transfer(g_parent,s_parent,y_target,beta)
  n = numel(g_parent)/2; g = zeros(2*numel(y_target),1);
  for w = 1:2
    part = g_parent((w-1)*n+(1:n));
    g((w-1)*numel(y_target)+(1:numel(y_target))) = LOCAL_wall_eval(part,s_parent,beta,y_target);
  end
end

function [result,chains] = LOCAL_final(config,chains,evidence)
  % Same-mode wall-trace correlations, deltas and the final status over the
  % effective required chain: [coarse, fine-q10, fine-q12] normally, or
  % [fine-q10, fine-q12] after the D2 fine independent entry (design 4.2/6);
  % a triggered fine-q16 is handled by the Q16 rule below. A missing coarse
  % control is recorded as UNAVAILABLE_COARSE_GEOMETRY, never as 0 or a pass.
  names = {chains.name}; get = @(name)find(strcmp(names,name),1);
  yq = linspace(-0.5,0.5,config.delivery.trace_points)';
  beta = config.model.beta*config.model.d;
  traces = struct();
  for j = 1:numel(chains)
    if chains(j).qualified
      g = chains(j).delivery.g; n = numel(g)/2; s = chains(j).subdivisions;
      traces.(strrep(chains(j).name,'-','_')) = [LOCAL_wall_eval(g(1:n),s,beta,yq); ...
        LOCAL_wall_eval(g(n+1:end),s,beta,yq)];
    end
  end
  ic = get('coarse'); i10 = get('fine-q10'); i12 = get('fine-q12'); i16 = get('fine-q16');
  unavailable = chains(i10).coarse_control_unavailable;
  pairs = {'coarse','fine-q10';'fine-q10','fine-q12';'fine-q12','fine-q16'};
  correlations = struct('pair',{},'correlation',{},'pass',{},'status',{});
  for p = 1:3
    a = strrep(pairs{p,1},'-','_'); b = strrep(pairs{p,2},'-','_');
    entry = struct('pair',[pairs{p,1},'/',pairs{p,2}],'correlation',NaN,'pass',false, ...
      'status','NOT_EVALUATED');
    if p==1 && unavailable
      entry.status = 'UNAVAILABLE_COARSE_GEOMETRY';
    elseif isfield(traces,a) && isfield(traces,b)
      ta = traces.(a); tb = traces.(b);
      entry.correlation = abs(ta'*tb)/(norm(ta)*norm(tb));
      entry.pass = entry.correlation>=config.delivery.same_mode_corr;
      entry.status = 'FAIL'; if entry.pass, entry.status = 'PASS'; end
    end
    correlations(end+1) = entry; %#ok<AGROW>
    jb = get(pairs{p,2}); chains(jb).same_mode = entry;
  end
  if unavailable
    required = [i10,i12]; comparison = 'UNAVAILABLE_COARSE_GEOMETRY';
  else
    required = [ic,i10,i12]; comparison = correlations(1).status;
  end
  result = struct('schema',config.schema,'final_status','','final_reason','', ...
    'final_candidate','','final_candidate_index',0,'final_k',NaN,'final_mu',NaN, ...
    'all_required_converged',false,'effective_required_chains',{names(required)}, ...
    'coarse_control_unavailable',unavailable,'coarse_fine_comparison_status',comparison, ...
    'fine_q10_initialization_source',chains(i10).initialization_source, ...
    'coarse_failure',struct('status',chains(ic).status,'reason',chains(ic).reason, ...
      'failure_kind',chains(ic).geometry_failure_kind, ...
      'mesh_structural_checks_pass',chains(ic).mesh_structural_checks_pass), ...
    'fine_entry',chains(i10).fine_entry,'two_level_sensitivity_available',false, ...
    'delta_h',NaN,'delta_h_status','NOT_EVALUATED','delta_Q',NaN,'delta_Q16',NaN, ...
    'q16_triggered',false,'same_mode',correlations,'wall_trace_y',yq, ...
    'wall_traces',traces,'configurations',[]);
  if unavailable
    result.delta_h_status = 'UNAVAILABLE_COARSE_GEOMETRY';
  elseif chains(ic).qualified && chains(i10).qualified
    result.delta_h = abs(chains(i10).k-chains(ic).k); result.delta_h_status = 'AVAILABLE';
  end
  % two-level evidence exists only with a qualified coarse root and a passing correlation
  result.two_level_sensitivity_available = ~unavailable && strcmp(comparison,'PASS');
  if chains(i10).qualified && chains(i12).qualified
    result.delta_Q = abs(chains(i12).k-chains(i10).k);
  end
  result.q16_triggered = ~any(strcmp(chains(i16).status,{'NOT_RUN','PENDING'})) || ...
    (~isnan(result.delta_Q) && result.delta_Q>config.q_trigger);
  if result.q16_triggered, result.effective_required_chains{end+1} = 'fine-q16'; end
  if chains(i16).qualified, result.delta_Q16 = abs(chains(i16).k-chains(i12).k); end
  failed = required(~[chains(required).qualified]);
  result.all_required_converged = isempty(failed);
  if ~isempty(failed)
    first = failed(1); status = chains(first).status;
    if any(strcmp(status,{'ROOT_FOUND','ROOT_QUALIFIED','PENDING'})), status = 'ROOT_NOT_CONVERGED'; end
    result.final_status = status;
    result.final_reason = sprintf('%s: %s',chains(first).name,chains(first).reason);
    return
  end
  final = i12;
  if result.q16_triggered
    if chains(i16).qualified
      final = i16;
      if result.delta_Q16>config.q_trigger
        result.final_status = 'QUADRATURE_UNRESOLVED';
        result.final_reason = sprintf('|k16-k12| = %.3e > %.0e',result.delta_Q16,config.q_trigger);
      end
    else
      result.final_status = 'QUADRATURE_UNRESOLVED';
      result.final_reason = sprintf('Q16 triggered but %s (%s); Q12 kept',chains(i16).status,chains(i16).reason);
    end
  end
  bad = correlations(strcmp({correlations.status},'FAIL'));
  if ~isempty(bad)
    result.final_status = 'MODE_AMBIGUOUS';
    result.final_reason = sprintf('same-mode correlation %s = %.6f < %.2f',bad(1).pair, ...
      bad(1).correlation,config.delivery.same_mode_corr);
  end
  if isempty(result.final_status), result.final_status = 'CANDIDATE_DELIVERED'; end
  if unavailable
    result.final_reason = strtrim([result.final_reason, ...
      ' NO COARSE/FINE CONTROL (coarse GEOMETRY_FAILED); spatial stability not checked.']);
  end
  result.final_candidate = chains(final).name; result.final_candidate_index = final;
  result.final_k = chains(final).k; result.final_mu = chains(final).mu;
  assert(numel(evidence.configurations)>=1);
end

%% ==================== Figures (MATLAB native export) ====================
% Field amplitude over centre + 4 cells per side, mode evidence, cost breakdown.
function status = LOCAL_figures(ctx,config,chains,evidence,meshes,ledger,result)
  status = struct('field','','modes','','cost','');
  folder = fullfile(ctx.output_dir,'figures');
  try
    if result.final_candidate_index>0
      name = chains(result.final_candidate_index).name;
      records = evidence.configurations; j = find(strcmp({records.name},name),1);
      forms = evidence.forms.(strrep(name,'-','_'));
      fig = figure('Visible','off','Position',[0,0,1600,320]); hold on
      sub = [1,4,6;4,2,5;6,5,3;4,5,6];
      LOCAL_patch(forms.center.xy,forms.center.tri6,records(j).display.center,0,sub);
      for side = {'left','right'}
        sgn = 2*strcmp(side{1},'right')-1; fields = records(j).display.(side{1});
        for c = 1:numel(fields)
          LOCAL_patch(forms.(side{1}).xy,forms.(side{1}).tri6,fields{c},sgn*(c-1),sub);
        end
      end
      m = meshes(strcmp({meshes.key},chains(result.final_candidate_index).mesh_key)).mesh;
      for c = 1:3
        curve = m.curves{c}; plot([curve(:,1);curve(1,1)],[curve(:,2);curve(1,2)],'w-','LineWidth',0.5);
        if c~=2
          for r = 2:config.delivery.display_cells
            sh = (2*(c==3)-1)*(r-1);
            plot([curve(:,1);curve(1,1)]+sh,[curve(:,2);curve(1,2)],'w-','LineWidth',0.5);
          end
        end
      end
      axis equal tight; colorbar; xlabel('x'); ylabel('y');
      title(sprintf('|u|, %s, k = %.12f (centre + %d cells per side, display only)',name, ...
        chains(result.final_candidate_index).k,config.delivery.display_cells));
      status.field = fullfile(folder,'field-amplitude.png');
      exportgraphics(fig,status.field,'Resolution',150); close(fig);
    end
    fig = figure('Visible','off','Position',[0,0,1300,420]);
    subplot(1,3,1); hold on
    % only qualified chains are plotted; others are labelled, never drawn as 0
    q = find([chains.qualified]);
    if ~isempty(q), errorbar(q,[chains(q).k]-config.k0,[chains(q).bracket_width],'o-'); end
    labels = {chains.name};
    for j = find(~[chains.qualified])
      labels{j} = sprintf('%s\\newline(%s)',chains(j).name,strrep(chains(j).status,'_','\_'));
    end
    set(gca,'XTick',1:numel(chains),'XTickLabel',labels); xlim([0.5,numel(chains)+0.5]);
    ylabel('k - k_0 (E.2 start)'); grid on
    if result.coarse_control_unavailable
      title({'Frequency drift','NO coarse/fine control (coarse GEOMETRY\_FAILED)',''});
    else
      title('Frequency drift');
    end
    subplot(1,3,2); hold on
    yq = result.wall_trace_y; names = fieldnames(result.wall_traces);
    for j = 1:numel(names)
      tr = result.wall_traces.(names{j});
      plot([yq-0.6;yq+0.6],abs(tr),'DisplayName',strrep(names{j},'_','-'));
    end
    legend('Location','best'); xlabel('left wall (y-0.6) | right wall (y+0.6)'); ylabel('|g|');
    title('Centre wall traces'); grid on
    subplot(1,3,3);
    if ~isempty(result.same_mode)
      % unavailable/not-evaluated pairs have no bar (NaN) and carry their status label
      values = 1-[result.same_mode.correlation];          % NaN stays NaN (max would drop it)
      evaluated = ~isnan(values); values(evaluated) = max(values(evaluated),eps);
      if any(evaluated), bar(find(evaluated),values(evaluated)); end
      set(gca,'YScale','log'); hold on
      yline(1-config.delivery.same_mode_corr,'r--','gate 1-0.99');
      labels = {result.same_mode.pair};
      for j = find(~evaluated)
        labels{j} = sprintf('%s\\newline(%s)',labels{j},strrep(result.same_mode(j).status,'_','\_'));
      end
      set(gca,'XTick',1:numel(result.same_mode),'XTickLabel',labels); xlim([0.5,numel(labels)+0.5]);
      ylabel('1 - correlation (floored at eps)'); title('Same-mode wall-trace correlation'); grid on
    end
    status.modes = fullfile(folder,'mode-correlation-drift.png');
    exportgraphics(fig,status.modes,'Resolution',150); close(fig);
    fig = figure('Visible','off','Position',[0,0,900,420]);
    categories = {'mesh_repair','assembly','lead_elimination','qz_dtn','center_small', ...
      'root_control','recovery_checks','save'};
    values = cellfun(@(c)ledger.(c),categories);
    bar(values); set(gca,'XTick',1:numel(categories),'XTickLabel',strrep(categories,'_','\_'));
    xtickangle(30); ylabel('seconds'); grid on
    title(sprintf('MATLAB internal exclusive timers before figures/save (sum %.1f s)',sum(values)));
    status.cost = fullfile(folder,'cost-breakdown.png');
    exportgraphics(fig,status.cost,'Resolution',150); close(fig);
  catch error_object
    status.error = getReport(error_object,'basic','hyperlinks','off');
    fprintf('FIGURE failure: %s\n',error_object.message);
  end
end

function LOCAL_patch(xy,tri6,values,shift,sub)
  faces = [tri6(:,sub(1,:));tri6(:,sub(2,:));tri6(:,sub(3,:));tri6(:,sub(4,:))];
  patch('Faces',faces,'Vertices',xy+[shift,0],'FaceVertexCData',abs(values), ...
    'FaceColor','interp','EdgeColor','none');
end

%% ==================== Ledger, progress, memory and I/O ====================
% Mutually exclusive MATLAB timers; launcher reads progress.json for grace decisions.
function ledger = LOCAL_ledger()
  ledger = struct('mesh_repair',0,'assembly',0,'lead_elimination',0,'qz_dtn',0, ...
    'center_small',0,'root_control',0,'recovery_checks',0,'save',0,'summary_figures',0);
end

function timing = LOCAL_ledger_close(ledger,total)
  timing = ledger; values = struct2cell(ledger);
  timing.attributed_seconds = sum([values{:}]);
  timing.matlab_function_seconds = total;
  timing.matlab_unattributed_seconds = total-timing.attributed_seconds;
end

function LOCAL_progress(ctx,name,phase,extra)
  value = struct('matlab_elapsed',toc(ctx.started),'config',name,'phase',phase, ...
    'bracket_width',NaN,'slowest_eval_seconds',NaN,'frequency_count',NaN, ...
    'all_required_converged',false,'save_estimate_seconds',ctx.config.resources.save_estimate_seconds);
  for f = fieldnames(extra)', value.(f{1}) = extra.(f{1}); end
  temporary = [ctx.progress_path,'.tmp'];
  value.remaining_required = ctx.remaining_required;     % later required chains (effective set)
  value.effective_required_chains = ctx.effective_required;
  value.coarse_control_unavailable = ctx.coarse_control_unavailable;
  LOCAL_json(temporary,value); movefile(temporary,ctx.progress_path,'f');
end

function LOCAL_partial(ctx,chains,ledger)
  if isempty(chains), return, end
  slim = rmfield(chains,{'delivery','dtn'});
  LOCAL_json(fullfile(ctx.output_dir,'partial-result.json'), ...
    struct('chains',slim,'timing',LOCAL_ledger_close(ledger,toc(ctx.started))));
end

function rss = LOCAL_rss()
  [flag,text] = system(sprintf('ps -o rss= -p %d',feature('getpid')));
  rss = NaN;
  if flag==0, rss = 1024*str2double(strtrim(text)); end
end

function LOCAL_memory_gate(config,label,bytes,rss)
  if nargin<4, rss = LOCAL_rss(); end
  if rss+bytes>config.resources.internal_gate_bytes
    error('i95b:ResourceStop','Predicted %s memory %.0f + RSS %.0f exceeds %.0f bytes.', ...
      label,bytes,rss,config.resources.internal_gate_bytes);
  end
end

function LOCAL_iteration_header(path)
  fid = fopen(path,'w'); assert(fid>=0,'i95b:IO','Cannot create iterations.csv.');
  fprintf(fid,['config,eval_count,k,mu,purpose,cache_hit,valid,reason_left,reason_right,', ...
    'reason_center,branch_index,lambda_target,lambda_scaled,target_gap,nearest5,', ...
    'left_backward,right_backward,center_backward,left_condest,right_condest,center_condest,', ...
    'left_unit_gap,right_unit_gap,left_z0_rcond,right_z0_rcond,left_riccati,right_riccati,', ...
    'left_dtn_herm,right_dtn_herm,left_consistency,right_consistency,H_herm,H_norm,', ...
    'lead_elimination_s,qz_dtn_s,center_small_s,response_s,rss_bytes\n']);
  fclose(fid);
end

function LOCAL_iteration_row(ctx,cfg,state,res,purpose,hit,elapsed)
  get = @(s,a,b)LOCAL_field(s,a,b);
  if ~isnan(state.index) && ~isempty(res.lambda)
    lam = res.lambda(state.index); gap = LOCAL_gap(res.lambda,state.index);
  else
    lam = NaN; gap = NaN;
  end
  if ~isempty(res.lambda)
    [~,near] = sort(abs(res.lambda)); near5 = strjoin(arrayfun(@(v)sprintf('%.6e',v), ...
      res.lambda(near(1:min(5,end))),'UniformOutput',false),' ');
  else
    near5 = '';
  end
  clean = @(t)strrep(strrep(t,',',';'),newline,' ');
  fid = fopen(ctx.iterations_path,'a');
  fprintf(fid,'%s,%d,%.17g,%.17g,%s,%d,%d,"%s","%s","%s",%g,%.17g,%.6e,%.6e,%s,', ...
    cfg.name,state.count,res.k,res.mu,purpose,hit,res.valid,clean(res.reason_left), ...
    clean(res.reason_right),clean(res.reason_center),state.index,lam, ...
    abs(lam)/max(1,res.H_norm),gap,near5);
  fprintf(fid,'%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,', ...
    get(res.cell,'left','backward'),get(res.cell,'right','backward'),get(res.cell,'center','backward'), ...
    get(res.cell,'left','condest'),get(res.cell,'right','condest'),get(res.cell,'center','condest'), ...
    get(res.dtn,'left','unit_gap_min'),get(res.dtn,'right','unit_gap_min'), ...
    get(res.dtn,'left','z0_rcond'),get(res.dtn,'right','z0_rcond'), ...
    get(res.dtn,'left','riccati'),get(res.dtn,'right','riccati'), ...
    get(res.dtn,'left','hermitian_defect'),get(res.dtn,'right','hermitian_defect'), ...
    get(res.dtn,'left','consistency'),get(res.dtn,'right','consistency'), ...
    res.H_hermitian_defect,res.H_norm);
  if hit, times = [0,0,0]; else, times = [res.times.lead_elimination,res.times.qz_dtn,res.times.center_small]; end
  fprintf(fid,'%.6f,%.6f,%.6f,%.6f,%.0f\n',times,elapsed,res.rss_bytes);
  fclose(fid);
end

function value = LOCAL_field(s,a,b)
  value = NaN;
  if isfield(s,a) && isfield(s.(a),b) && ~isempty(s.(a).(b)), value = double(s.(a).(b)); end
end

function LOCAL_write_candidates(path,chains)
  fid = fopen(path,'w'); assert(fid>=0,'i95b:IO','Cannot create candidates.csv.');
  fprintf(fid,['config,status,qualified,s,interface_segments,quadrature_order,k_init,k,mu,', ...
    'bracket_low,bracket_high,bracket_width,lambda,lambda_scaled,center_residual,branch_index,', ...
    'wall_dofs,small_order,frequency_count,cache_hits,precompute_s,root_s,recovery_s,', ...
    'left_unit_gap,right_unit_gap,left_z0_rcond,right_z0_rcond,left_riccati,right_riccati,', ...
    'same_mode_corr,initialization_source,geometry_failure_kind,reason\n']);
  for j = 1:numel(chains)
    c = chains(j); n = NaN; order = NaN;
    if isfield(c.dimensions,'wall_dofs'), n = c.dimensions.wall_dofs; order = 2*n; end
    corr = NaN; if isfield(c.same_mode,'correlation'), corr = c.same_mode.correlation; end
    fprintf(fid,'%s,%s,%d,%d,%d,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.6e,%.6e,%.6e,%.6e,%g,%g,%g,%d,%d,%.4f,%.4f,%.4f,', ...
      c.name,c.status,c.qualified,c.subdivisions,c.interface_segments,c.quadrature_order, ...
      c.k_init,c.k,c.mu,c.bracket_low,c.bracket_high,c.bracket_width,c.lambda,c.lambda_scaled, ...
      c.center_residual,c.branch_index,n,order,c.frequency_count,c.cache_hits, ...
      c.precompute_seconds,c.root_seconds,c.recovery_seconds);
    fprintf(fid,'%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.8f,%s,%s,"%s"\n', ...
      LOCAL_field(c.dtn,'left','unit_gap_min'),LOCAL_field(c.dtn,'right','unit_gap_min'), ...
      LOCAL_field(c.dtn,'left','z0_rcond'),LOCAL_field(c.dtn,'right','z0_rcond'), ...
      LOCAL_field(c.dtn,'left','riccati'),LOCAL_field(c.dtn,'right','riccati'),corr, ...
      c.initialization_source,c.geometry_failure_kind,strrep(c.reason,'"',''''));
  end
  fclose(fid);
end

function LOCAL_json(path,value)
  text = jsonencode(LOCAL_jsonable(value),'PrettyPrint',true);
  fid = fopen(path,'w'); assert(fid>=0,'i95b:IO','Cannot open JSON output.');
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
