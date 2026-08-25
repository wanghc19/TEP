function result = tep_mc_scan(stage)
%TEP_MC_SCAN Run staged real-wavenumber tests for the missing-column model.
% Purpose:
%   Execute the empirical I1.3 preflight/pilot and M=48 parameter-continuity
%   experiment without changing package code or making a spectral claim.
% Input:
%   stage - 'pilot', 'continuity', 'screen', 'refine24', 'confirm48', or
%   'full'. The full entry runs the authorized candidate stages in order.
% Output:
%   result - fail-closed stage result also saved under output/<stage>/.
% Main algorithm:
%   Build direct coarse/fine one-cell maps, run original and reversed ordered
%   QZ passes, freeze one seed row selector, assemble graph/DtN forms, compare
%   QR-basis overlaps, and test centered finite differences and mutations.
% Based on:
%   research/projects/eig-apost/implementation/i1/design.md and the direct
%   M=48 I1.2 implementation in test/i1/hg-adef/.
% Main changes:
%   Extends the frozen-k checks to a seven-point real-k stencil and labels the
%   resulting derivative as empirical finite-difference evidence only.
% Numerical goal:
%   Pass every frozen continuity gate before any later reconnaissance stage.

  if nargin < 1 || isempty(stage)
    stage = 'pilot';
  end
  if exist('OCTAVE_VERSION','builtin') ~= 0
    error('tep_mc_scan:MATLABRequired','MATLAB is required.');
  end
  if isempty(which('lsqminnorm'))
    error('tep_mc_scan:LsqminnormRequired','MATLAB lsqminnorm is required.');
  end

  cfg = scan_cfg();
  here = fileparts(mfilename('fullpath'));
  repo = fileparts(fileparts(fileparts(here)));
  addpath(repo);
  stage = lower(char(stage));
  switch stage
    case 'pilot'
      result = LOCAL_pilot(cfg,here,repo);
    case 'continuity'
      result = LOCAL_continuity(cfg,here,repo);
    case 'screen'
      result = LOCAL_candidate_stage('screen',cfg,here,repo);
    case 'refine24'
      result = LOCAL_candidate_stage('refine24',cfg,here,repo);
    case 'confirm48'
      result = LOCAL_candidate_stage('confirm48',cfg,here,repo);
    case 'full'
      result = LOCAL_full(cfg,here,repo);
    otherwise
      error('tep_mc_scan:Stage','Unknown stage %s.',stage);
  end
end

%% ==================== Stage drivers ====================
% These helpers execute pilot and continuity with fail-closed artifacts.

function result = LOCAL_pilot(cfg,here,repo)
  output_dir = fullfile(here,'output','pilot');
  LOCAL_mkdir(output_dir);
  timer = tic;
  first_failure = '';
  gates = cell(0,7);
  provenance = LOCAL_provenance(here,repo);

  % --- stage 1: runtime and minimum-norm sanity ---
  A = [1,1;2,2]; b = [1;2]; x = lsqminnorm(A,b);
  lsq_residual = norm(A*x-b)/norm(b);
  lsq_solution = norm(x-[0.5;0.5]);
  solver_ok = strcmp(provenance.runtime,'MATLAB') && ...
    ~isempty(provenance.solver_path) && lsq_residual <= cfg.solve_tol && ...
    lsq_solution <= cfg.solve_tol;
  gates(end+1,:) = LOCAL_gate('preflight','matlab_lsqminnorm',solver_ok, ...
    max(lsq_residual,lsq_solution),cfg.solve_tol, ...
    'MATLAB public solver path and duplicate-column minimum-norm sanity');

  % --- stage 2: declared sizes and serial budget ---
  orders = [12,24,48];
  dims = cell(numel(orders),8);
  for j = 1:numel(orders)
    M = orders(j); K = 2*M+1; graph_n = 4*K;
    graph_mib = 16*graph_n^2/2^20;
    dims(j,:) = {M,K,2*K,2*K,4*K,2*cfg.coarse.ntot, ...
      2*cfg.fine.ntot,graph_mib};
  end
  max_graph_mib = dims{end,8};
  dims_ok = isequal(cell2mat(dims(:,3:5)), ...
    [50,50,100;98,98,196;194,194,388]) && ...
    isequal(cell2mat(dims(:,6:7)),[320,512;320,512;320,512]) && ...
    max_graph_mib <= 2.30 && cfg.serial_memory_mib == 512 && ...
    cfg.full_time_minutes == 30;
  gates(end+1,:) = LOCAL_gate('preflight','dimensions_and_budget',dims_ok, ...
    max_graph_mib,2.30,'declared pencil/A-def, BIE density, graph, memory, and time sizes');

  % --- stage 3: one inexpensive direct point ---
  point = struct();
  try
    point = LOCAL_make_level(cfg.k0,cfg.pilot_M,cfg.coarse,cfg);
    pair = LOCAL_pair(point,cfg.pilot_M);
    qp = LOCAL_qz(pair.A,pair.B,cfg.pilot_M,cfg,point.blocks, ...
      'plus','LEFT_CELL_WALL');
    qm = LOCAL_qz(pair.B,pair.A,cfg.pilot_M,cfg,point.blocks, ...
      'minus','RIGHT_CELL_WALL');
    K = 2*cfg.pilot_M+1;
    point_ok = point.solve_residual <= cfg.solve_tol && ...
      isequal(size(pair.A),[2*K,2*K]) && qp.pass && qm.pass && ...
      point.gamma_identity <= cfg.solve_tol && point.branch_ok && ...
      point.wood_distance > 100*eps;
    point_value = max([point.solve_residual,qp.raw_residual,qp.residual, ...
      qm.raw_residual,qm.residual,point.gamma_identity]);
  catch ME
    point_ok = false;
    point_value = Inf;
    point = struct('error_identifier',ME.identifier,'error_message',ME.message);
  end
  gates(end+1,:) = LOCAL_gate('pilot','m12_coarse_point',point_ok, ...
    point_value,cfg.solve_tol,'one direct M12 coarse point with two QZ directions');

  pass = all(cell2mat(gates(:,4)));
  if ~solver_ok
    first_failure = 'MATLAB_LSQMINNORM_FAIL';
  elseif ~dims_ok
    first_failure = 'PREFLIGHT_DIMENSION_BUDGET_FAIL';
  elseif ~point_ok
    first_failure = 'PILOT_M12_POINT_FAIL';
  end
  if pass
    status = 'I1_3_PILOT_PASS';
  else
    status = 'I1_3_PILOT_FAIL';
  end
  if isfield(point,'solve_residual')
    point_summary = struct('k',cfg.k0,'M',cfg.pilot_M,'K',point.K, ...
      'system_rows',point.system_rows,'solve_residual',point.solve_residual, ...
      'wood_distance',point.wood_distance, ...
      'gamma_identity',point.gamma_identity,'branch_ok',point.branch_ok);
  else
    point_summary = point;
  end
  lineage = LOCAL_lineage('pilot',status,'ROOT',provenance,cfg);
  result = struct('schema',cfg.schema,'experiment_id',cfg.experiment_id, ...
    'stage','pilot','status',status,'pass',pass, ...
    'first_failure',first_failure,'elapsed_seconds',toc(timer), ...
    'gates',{gates},'dimensions',{dims},'point',point_summary, ...
    'provenance',provenance,'lineage',lineage,'config',cfg, ...
    'all_gates_pass',pass,'pass_with_conditions',false, ...
    'pass_semantics','ALL_PILOT_GATES', ...
    'claim_boundary','EMPIRICAL_PREFLIGHT_ONLY');
  LOCAL_csv(fullfile(output_dir,'gates.csv'), ...
    {'group','gate','status','pass','value','tolerance','note'},gates);
  LOCAL_csv(fullfile(output_dir,'dimensions.csv'), ...
    {'M','K','pencil','adef_d','adef_g','bie_coarse','bie_fine','graph_mib'},dims);
  LOCAL_write_pilot_point(fullfile(output_dir,'point.csv'),point,cfg);
  LOCAL_write_provenance(fullfile(output_dir,'provenance.csv'),provenance);
  LOCAL_write_lineage(fullfile(output_dir,'lineage.csv'),lineage);
  LOCAL_estimate(fullfile(output_dir,'estimate.md'),cfg,dims);
  save(fullfile(output_dir,'result.mat'),'result','-v7');
  LOCAL_report(fullfile(output_dir,'report.md'),result);
  LOCAL_log(fullfile(output_dir,'run.log'),result);
  fprintf('TEP_MC_SCAN_STAGE=pilot STATUS=%s seconds=%.6g\n', ...
    result.status,result.elapsed_seconds);
end

function result = LOCAL_continuity(cfg,here,repo)
  output_dir = fullfile(here,'output','continuity');
  LOCAL_mkdir(output_dir);
  timer = tic;
  first_failure = '';
  gates = cell(0,7);
  provenance = LOCAL_provenance(here,repo);
  pilot_path = fullfile(here,'output','pilot','result.mat');

  % --- stage 1: pilot prerequisite ---
  [pilot_ok,pilot_result,pilot_note] = LOCAL_prerequisite( ...
    pilot_path,'pass','pilot',cfg,provenance);
  parent_token = '';
  if pilot_ok, parent_token = pilot_result.lineage.token; end
  gates(end+1,:) = LOCAL_gate('preflight','pilot_prerequisite',pilot_ok, ...
    double(pilot_ok),1,pilot_note);
  if ~pilot_ok
    first_failure = 'PILOT_PREREQUISITE_FAIL';
    result = LOCAL_continuity_finish('I1_3_CONTINUITY_FAIL',false,first_failure, ...
      timer,gates,struct([]),cell(0,17),cell(0,23),cell(0,12), ...
      cell(0,15),cell(0,8),cell(0,10),cell(0,8),cell(0,13),cell(0,9), ...
      provenance,cfg,output_dir,false,false,false,cfg.fd_h,parent_token, ...
      struct());
    return;
  end

  % --- stage 2: direct seven-node construction and QZ ---
  M = cfg.continuity_M; K = 2*M+1;
  kvals = cfg.continuity_k(:).';
  seed_index = find(abs(kvals-cfg.k0) <= 10*eps*max(1,abs(cfg.k0)),1);
  nodes = repmat(struct(),1,numel(kvals));
  construction_ok = true;
  construction_value = 0;
  for j = 1:numel(kvals)
    try
      nodes(j).k = kvals(j);
      nodes(j).coarse = LOCAL_prepare(kvals(j),M,cfg.coarse,cfg);
      nodes(j).fine = LOCAL_prepare(kvals(j),M,cfg.fine,cfg);
      construction_value = max([construction_value, ...
        nodes(j).coarse.solve_residual,nodes(j).fine.solve_residual]);
      construction_ok = construction_ok && ...
        nodes(j).coarse.solve_residual <= cfg.solve_tol && ...
        nodes(j).fine.solve_residual <= cfg.solve_tol;
    catch ME
      construction_ok = false;
      nodes(j).error_identifier = ME.identifier;
      nodes(j).error_message = ME.message;
      break;
    end
  end
  gates(end+1,:) = LOCAL_gate('input','seven_direct_nodes',construction_ok, ...
    construction_value,cfg.solve_tol,'ascending M48 coarse/fine direct maps');
  if ~construction_ok
    first_failure = 'DIRECT_NODE_CONSTRUCTION_FAIL';
    result = LOCAL_continuity_finish('I1_3_CONTINUITY_FAIL',false,first_failure, ...
      timer,gates,nodes,cell(0,17),cell(0,23),cell(0,12), ...
      cell(0,15),cell(0,8),cell(0,10),cell(0,8),cell(0,13),cell(0,9), ...
      provenance,cfg,output_dir,false,false,false,cfg.fd_h,parent_token, ...
      struct());
    return;
  end

  % --- stage 3: one seed pivot and fixed-row normalization ---
  rows_plus = LOCAL_rows(nodes(seed_index).fine.plus.Z,K);
  rows_minus = LOCAL_rows(nodes(seed_index).fine.minus.Z,K);
  for j = 1:numel(nodes)
    nodes(j).coarse = LOCAL_complete(nodes(j).coarse,rows_plus,rows_minus,cfg);
    nodes(j).fine = LOCAL_complete(nodes(j).fine,rows_plus,rows_minus,cfg);
  end
  seed_scale_coarse = norm(nodes(seed_index).coarse.Aphys,'fro');
  seed_scale_fine = norm(nodes(seed_index).fine.Aphys,'fro');
  for j = 1:numel(nodes)
    nodes(j).coarse = LOCAL_set_score(nodes(j).coarse,seed_scale_coarse,cfg);
    nodes(j).fine = LOCAL_set_score(nodes(j).fine,seed_scale_fine,cfg);
  end

  % --- stage 4: sequential finite-difference stencil expansion ---
  fd_h_used = cfg.fd_h;
  [~,fd_ready_preview,~,~] = LOCAL_fd(nodes,seed_index,cfg,fd_h_used);
  expansion_ok = true;
  for e = 1:numel(cfg.fd_h_extra)
    if fd_ready_preview, break; end
    h = cfg.fd_h_extra(e);
    new_nodes = repmat(struct(),1,2);
    new_k = [cfg.k0-h,cfg.k0+h];
    for p = 1:2
      try
        new_nodes(p).k = new_k(p);
        new_nodes(p).coarse = LOCAL_prepare(new_k(p),M,cfg.coarse,cfg);
        new_nodes(p).fine = LOCAL_prepare(new_k(p),M,cfg.fine,cfg);
        new_nodes(p).coarse = LOCAL_complete(new_nodes(p).coarse, ...
          rows_plus,rows_minus,cfg);
        new_nodes(p).fine = LOCAL_complete(new_nodes(p).fine, ...
          rows_plus,rows_minus,cfg);
        new_nodes(p).coarse = LOCAL_set_score(new_nodes(p).coarse, ...
          seed_scale_coarse,cfg);
        new_nodes(p).fine = LOCAL_set_score(new_nodes(p).fine, ...
          seed_scale_fine,cfg);
        [~,new_ok] = LOCAL_level_metrics(new_nodes(p),cfg);
        expansion_ok = expansion_ok && new_ok;
      catch ME
        expansion_ok = false;
        new_nodes(p).error_identifier = ME.identifier;
        new_nodes(p).error_message = ME.message;
      end
    end
    nodes = [nodes,new_nodes]; %#ok<AGROW>
    [~,order] = sort([nodes.k]); nodes = nodes(order);
    seed_index = find(abs([nodes.k]-cfg.k0) <= 1e-12,1);
    fd_h_used(end+1) = h; %#ok<AGROW>
    if ~expansion_ok, break; end
    [~,fd_ready_preview,~,~] = LOCAL_fd(nodes,seed_index,cfg,fd_h_used);
  end
  gates(end+1,:) = LOCAL_gate('input','expanded_fd_nodes',expansion_ok, ...
    min(fd_h_used),min(cfg.fd_h_extra), ...
    'each added pair must pass point, QZ, chart, level, and transport gates');

  % --- stage 5: pointwise I1.2 gates and coarse/fine actions ---
  node_rows = cell(0,17); qz_rows = cell(0,23); chart_rows = cell(0,12);
  level_rows = cell(0,15); mutation_rows = cell(0,8); score_rows = cell(0,13);
  pointwise_ok = true; pointwise_max = 0;
  for j = 1:numel(nodes)
    [level_metric,level_ok] = LOCAL_level_metrics(nodes(j),cfg);
    nodes(j).level_metric = level_metric;
    base = {nodes(j).k,nodes(j).coarse.solve_residual, ...
      nodes(j).fine.solve_residual,nodes(j).coarse.wood_distance, ...
      nodes(j).coarse.gamma_identity,nodes(j).coarse.branch_ok, ...
      nodes(j).coarse.plus.unit_gap,nodes(j).coarse.minus.unit_gap, ...
      nodes(j).fine.plus.unit_gap,nodes(j).fine.minus.unit_gap, ...
      nodes(j).coarse.plus.infinite_count,nodes(j).coarse.minus.infinite_count, ...
      nodes(j).fine.plus.infinite_count,nodes(j).fine.minus.infinite_count, ...
      level_metric.schur_max,level_ok, ...
      'EMPIRICAL_FD_DERIVATIVE'};
    node_rows(end+1,:) = base;
    qz_rows = [qz_rows;LOCAL_qz_rows(nodes(j),M)]; %#ok<AGROW>
    chart_rows = [chart_rows;LOCAL_chart_rows(nodes(j),M)]; %#ok<AGROW>
    level_rows(end+1,:) = {nodes(j).k,level_metric.block_abs, ...
      level_metric.block_action,level_metric.pencil_action, ...
      level_metric.subspace_plus,level_metric.subspace_minus, ...
      level_metric.cauchy_plus,level_metric.cauchy_minus, ...
      level_metric.dtn_plus,level_metric.dtn_minus, ...
      level_metric.adef_action,level_metric.schur_max, ...
      level_metric.row_solve_max,level_metric.wall_ok,level_ok};
    mutation_rows(end+1,:) = {nodes(j).k, ...
      nodes(j).coarse.mutation.lambda,nodes(j).coarse.mutation.adef, ...
      nodes(j).fine.mutation.lambda,nodes(j).fine.mutation.adef, ...
      max(nodes(j).coarse.mutation.score,nodes(j).fine.mutation.score), ...
      cfg.basis_mutation_tol,nodes(j).coarse.mutation.pass && ...
      nodes(j).fine.mutation.pass};
    score_rows = [score_rows;LOCAL_score_rows(nodes(j))]; %#ok<AGROW>
    pointwise_ok = pointwise_ok && level_ok;
    pointwise_max = max([pointwise_max,level_metric.block_abs, ...
      level_metric.block_action,level_metric.pencil_action, ...
      level_metric.subspace_plus,level_metric.subspace_minus, ...
      level_metric.cauchy_plus,level_metric.cauchy_minus, ...
      level_metric.dtn_plus,level_metric.dtn_minus, ...
      level_metric.adef_action,level_metric.schur_max]);
  end
  gates(end+1,:) = LOCAL_gate('continuity','pointwise_i1_2_contract', ...
    pointwise_ok,pointwise_max,max([cfg.block_abs_tol,cfg.subspace_tol]), ...
    'individual metrics use their dedicated tolerances in levels.csv');

  % --- stage 6: neighboring principal overlaps ---
  [neighbor_rows,neighbor_ok,neighbor_min] = LOCAL_neighbors(nodes,cfg);
  gates(end+1,:) = LOCAL_gate('continuity','neighbor_principal_overlap', ...
    neighbor_ok,neighbor_min,cfg.neighbor_overlap_min, ...
    'smallest singular value of adjacent QR-basis overlaps');

  [subspace_rows,subspace_ok,subspace_ratio] = ...
    LOCAL_seed_subspaces(nodes,seed_index,cfg,fd_h_used);
  gates(end+1,:) = LOCAL_gate('continuity','seed_subspace_halving', ...
    subspace_ok,subspace_ratio,cfg.subspace_half_ratio_tol, ...
    'distance to k0 must decrease and scale by at most the frozen half ratio');

  % --- stage 7: centered empirical finite differences ---
  [fd_rows,fd_ok,fd_max,fd_mutation,fd_final_h] = ...
    LOCAL_fd(nodes,seed_index,cfg,fd_h_used);
  gates(end+1,:) = LOCAL_gate('derivative','empirical_centered_fd',fd_ok, ...
    fd_max,1, ...
    'last change, convergence ratio, and coarse/fine derivative action');

  % --- stage 8: deterministic mutations ---
  basis_point_ok = all(cell2mat(mutation_rows(:,8)));
  basis_point_value = max(cell2mat(mutation_rows(:,2:6)),[],'all');
  gates(end+1,:) = LOCAL_gate('mutation','pointwise_graph_basis', ...
    basis_point_ok,basis_point_value,cfg.basis_mutation_tol, ...
    'pointwise Lambda, A-def, and score invariance');
  fd_mutation_ok = fd_mutation <= cfg.basis_mutation_tol;
  gates(end+1,:) = LOCAL_gate('mutation','fd_graph_basis', ...
    fd_mutation_ok,fd_mutation,cfg.basis_mutation_tol, ...
    'diagnostic finite-difference gauge invariance');
  scalar_value = max(cell2mat(score_rows(:,12)));
  scalar_ok = scalar_value <= cfg.score_mutation_tol;
  gates(end+1,:) = LOCAL_gate('mutation','global_scalar_score',scalar_ok, ...
    scalar_value,cfg.score_mutation_tol, ...
    '1e-8, exp(0.37i), and 1e8 score invariance with frozen scale');

  continuity_ready = expansion_ok && pointwise_ok && neighbor_ok && ...
    subspace_ok && basis_point_ok && scalar_ok;
  fd_derivative_ready = continuity_ready && fd_ok && fd_mutation_ok;
  candidate_screen_authorized = continuity_ready;
  pass = continuity_ready;
  if ~expansion_ok
    first_failure = 'EXPANDED_FD_NODE_SCIENTIFIC_GATE_FAIL';
  elseif ~pointwise_ok
    first_failure = 'CONTINUITY_POINTWISE_GATE_FAIL';
  elseif ~neighbor_ok
    first_failure = 'CONTINUITY_NEIGHBOR_OVERLAP_FAIL';
  elseif ~subspace_ok
    first_failure = 'CONTINUITY_SEED_SUBSPACE_SCALING_FAIL';
  elseif ~basis_point_ok
    first_failure = 'CONTINUITY_POINTWISE_GRAPH_BASIS_FAIL';
  elseif ~scalar_ok
    first_failure = 'CONTINUITY_SCALAR_MUTATION_FAIL';
  elseif ~fd_ok
    first_failure = 'EMPIRICAL_FD_NOT_READY';
  elseif ~fd_mutation_ok
    first_failure = 'EMPIRICAL_FD_MUTATION_INVARIANCE_FAIL';
  end
  if continuity_ready && fd_derivative_ready
    status = 'I1_3_CONTINUITY_AND_FD_PASS_CANDIDATE_SCREEN_READY';
  elseif continuity_ready
    status = ['I1_3_CONTINUITY_PASS_WITH_CONDITIONS_', ...
      'FD_MUTATION_FAIL_CANDIDATE_SCREEN_READY'];
  else
    status = 'I1_3_CONTINUITY_FAIL';
  end
  result = LOCAL_continuity_finish(status,pass,first_failure,timer,gates, ...
    nodes,node_rows,qz_rows,chart_rows,level_rows,neighbor_rows,fd_rows, ...
    mutation_rows,score_rows,subspace_rows,provenance,cfg,output_dir, ...
    continuity_ready,fd_derivative_ready,candidate_screen_authorized, ...
    fd_h_used,parent_token,fd_final_h);
end

function result = LOCAL_continuity_finish(status,pass,first_failure,timer, ...
    gates,~,node_rows,qz_rows,chart_rows,level_rows,neighbor_rows, ...
    fd_rows,mutation_rows,score_rows,subspace_rows,provenance,cfg,output_dir, ...
    continuity_ready,fd_derivative_ready,candidate_screen_authorized, ...
    fd_h_used,parent_token,fd_final_h)
  all_gates_pass = ~isempty(gates) && all(cell2mat(gates(:,4)));
  pass_with_conditions = pass && ~all_gates_pass;
  lineage = LOCAL_lineage('continuity',status,parent_token,provenance,cfg);
  result = struct('schema',cfg.schema,'experiment_id',cfg.experiment_id, ...
    'stage','continuity','status',status,'pass',pass, ...
    'first_failure',first_failure,'elapsed_seconds',toc(timer), ...
    'gates',{gates},'node_rows',{node_rows}, ...
    'qz_rows',{qz_rows},'chart_rows',{chart_rows}, ...
    'level_rows',{level_rows},'neighbor_rows',{neighbor_rows}, ...
    'fd_rows',{fd_rows},'mutation_rows',{mutation_rows}, ...
    'score_rows',{score_rows},'subspace_rows',{subspace_rows}, ...
    'fd_final_h',fd_final_h, ...
    'provenance',provenance,'lineage',lineage,'config',cfg, ...
    'all_gates_pass',all_gates_pass, ...
    'pass_with_conditions',pass_with_conditions, ...
    'pass_semantics','CONTINUITY_AND_CANDIDATE_TRACK_ONLY', ...
    'derivative_available',false, ...
    'derivative_label','EMPIRICAL_FD_DERIVATIVE', ...
    'continuity_ready',continuity_ready, ...
    'fd_derivative_ready',fd_derivative_ready, ...
    'candidate_screen_authorized',candidate_screen_authorized, ...
    'fd_h_used',fd_h_used, ...
    'production_separation','NOT_EVALUATED_CAVEAT', ...
    'locator_authorized',false,'root_isolation_authorized',false, ...
    'claim_boundary','DISCRETE_REAL_AXIS_CONTINUITY_ONLY');
  LOCAL_csv(fullfile(output_dir,'gates.csv'), ...
    {'group','gate','status','pass','value','tolerance','note'},gates);
  LOCAL_csv(fullfile(output_dir,'nodes.csv'), ...
    {'k','solve_coarse','solve_fine','wood_distance','gamma_identity', ...
    'branch_ok','unit_gap_cp','unit_gap_cm','unit_gap_fp','unit_gap_fm', ...
    'infinite_cp','infinite_cm','infinite_fp','infinite_fm','schur_max', ...
    'pass','derivative_label'},node_rows);
  LOCAL_csv(fullfile(output_dir,'qz.csv'), ...
    {'k','M','level','side','plane','stable','unstable','neutral','infinite', ...
    'indeterminate','unit_gap','tau_proj','raw_residual','residual', ...
    'ref_available','ref_rcond_d','ref_rcond_f','ref_residual', ...
    'row_margin','row_condition','row_solve','regular_infinity','pass'},qz_rows);
  LOCAL_csv(fullfile(output_dir,'charts.csv'), ...
    {'k','M','level','side','margin','condition','condition_eps', ...
    'solve_residual','safe','schur_error','schur_tolerance','claim'},chart_rows);
  LOCAL_csv(fullfile(output_dir,'levels.csv'), ...
    {'k','block_abs','block_action','pencil_action','subspace_plus', ...
    'subspace_minus','cauchy_plus','cauchy_minus','dtn_plus','dtn_minus', ...
    'adef_action','schur_max','row_solve_max','wall_ok','pass'},level_rows);
  LOCAL_csv(fullfile(output_dir,'neighbors.csv'), ...
    {'k_left','k_right','level','side','sigma_min','minimum','threshold','pass'}, ...
    neighbor_rows);
  LOCAL_csv(fullfile(output_dir,'fd.csv'), ...
    {'object','h','coarse_norm','fine_norm','coarse_fine_action', ...
    'successive_change_coarse','successive_change_fine', ...
    'ratio_coarse','ratio_fine','mutation_change'},fd_rows);
  LOCAL_csv(fullfile(output_dir,'mutations.csv'), ...
    {'k','lambda_coarse','adef_coarse','lambda_fine','adef_fine', ...
    'score_max','tolerance','pass'},mutation_rows);
  LOCAL_csv(fullfile(output_dir,'scores.csv'), ...
    {'k','level','raw_sigma1','raw_sigma2','raw_sigmamax','sigma1', ...
    'sigma2','sigmamax','s1','r12','g12','scalar_mutation','seed_scale'},score_rows);
  LOCAL_csv(fullfile(output_dir,'subspaces.csv'), ...
    {'h','level','side','direction','distance','previous_distance', ...
    'half_ratio','monotone','pass'},subspace_rows);
  LOCAL_write_provenance(fullfile(output_dir,'provenance.csv'),provenance);
  LOCAL_write_lineage(fullfile(output_dir,'lineage.csv'),lineage);
  save(fullfile(output_dir,'result.mat'),'result','-v7');
  LOCAL_report(fullfile(output_dir,'report.md'),result);
  LOCAL_log(fullfile(output_dir,'run.log'),result);
  fprintf('TEP_MC_SCAN_STAGE=continuity STATUS=%s seconds=%.6g\n', ...
    result.status,result.elapsed_seconds);
end

function result = LOCAL_candidate_stage(stage,cfg,here,repo)
  output_dir = fullfile(here,'output',stage); LOCAL_mkdir(output_dir);
  timer = tic; provenance = LOCAL_provenance(here,repo);
  gates = cell(0,7); scans = struct([]); candidates = struct([]);
  diagnostics = struct([]);
  first_failure = ''; supplemental = false;
  if strcmp(stage,'screen')
    prerequisite_path = fullfile(here,'output','continuity','result.mat');
    prerequisite_field = 'candidate_screen_authorized';
    prerequisite_stage = 'continuity';
    M = cfg.screen_M; use_fine = false;
  elseif strcmp(stage,'refine24')
    prerequisite_path = fullfile(here,'output','screen','result.mat');
    prerequisite_field = 'next_authorized';
    prerequisite_stage = 'screen';
    M = cfg.refine_M; use_fine = true;
  else
    prerequisite_path = fullfile(here,'output','refine24','result.mat');
    prerequisite_field = 'next_authorized';
    prerequisite_stage = 'refine24';
    M = cfg.confirm_M; use_fine = true;
  end
  [prerequisite_ok,prior,prerequisite_note] = LOCAL_prerequisite( ...
    prerequisite_path,prerequisite_field,prerequisite_stage,cfg,provenance);
  parent_token = '';
  if prerequisite_ok, parent_token = prior.lineage.token; end
  gates(end+1,:) = LOCAL_gate('preflight','prior_stage_authorization', ...
    prerequisite_ok,double(prerequisite_ok),1,prerequisite_note);
  if ~prerequisite_ok
    first_failure = 'PRIOR_STAGE_NOT_AUTHORIZED';
    result = LOCAL_candidate_finish(stage,false,false,first_failure,timer,gates, ...
      scans,candidates,diagnostics,supplemental,provenance,cfg,output_dir, ...
      [upper(stage),'_FAIL'],cell(0,7),parent_token);
    return;
  end

  if strcmp(stage,'screen')
    scans = LOCAL_scan_group('screen-main',M,cfg.screen_k,cfg.k0, ...
      use_fine,cfg);
    [initial,~] = LOCAL_candidates(scans,cfg);
    screen_nodes = [scans.nodes];
    coarse_nodes = [screen_nodes.coarse];
    scores = [coarse_nodes.score];
    [~,best_index] = min([scores.s1]);
    supplemental = isempty(initial) || best_index == 1 || ...
      best_index == numel(scores);
    if supplemental
      all_k = sort(unique([cfg.screen_extra_k,cfg.screen_k]));
      scans = LOCAL_scan_group('screen-extended',M,all_k,cfg.k0, ...
        use_fine,cfg);
    end
    [candidates,diagnostics] = LOCAL_candidates(scans,cfg);
    if numel(candidates) > cfg.max_refine_candidates
      candidates = candidates(1:cfg.max_refine_candidates);
    end
  elseif strcmp(stage,'refine24')
    count = min(cfg.max_refine_candidates,numel(prior.candidates));
    scans = struct([]);
    all_candidates = struct([]);
    all_diagnostics = struct([]);
    for j = 1:count
      center = prior.candidates(j).k;
      group = LOCAL_scan_group(sprintf('candidate-%d',j),M, ...
        center+cfg.refine_offsets,center,use_fine,cfg);
      scans = [scans,group]; %#ok<AGROW>
      [found,checked] = LOCAL_candidates(group,cfg);
      all_candidates = [all_candidates,found]; %#ok<AGROW>
      all_diagnostics = [all_diagnostics,checked]; %#ok<AGROW>
    end
    candidates = LOCAL_sort_candidates(all_candidates);
    diagnostics = all_diagnostics;
  else
    center = prior.candidates(1).k;
    scans = LOCAL_scan_group('best-candidate',M, ...
      center+cfg.confirm_offsets,center,use_fine,cfg);
    [candidates,diagnostics] = LOCAL_candidates(scans,cfg);
  end

  scan_ok = ~isempty(scans) && all([scans.pass]);
  gates(end+1,:) = LOCAL_gate('scan','all_scientific_points',scan_ok, ...
    double(scan_ok),1,'every point is fail-closed under its stage contract');
  scalar_max = LOCAL_scan_scalar_max(scans);
  scalar_ok = scalar_max <= cfg.score_mutation_tol;
  gates(end+1,:) = LOCAL_gate('score','global_scalar_invariance',scalar_ok, ...
    scalar_max,cfg.score_mutation_tol,'authoritative score uses one seed scale');
  [balance_rows,balance_ok,balance_value] = LOCAL_balance_locations(scans);
  gates(end+1,:) = LOCAL_gate('score','raw_physical_minimum_location', ...
    balance_ok,balance_value,1, ...
    'raw-unbalanced and frozen-physical minima differ by at most one grid point');
  next_authorized = scan_ok && scalar_ok && balance_ok && ~isempty(candidates);
  pass = scan_ok && scalar_ok && balance_ok;
  if ~scan_ok
    first_failure = 'CANDIDATE_STAGE_SCIENTIFIC_GATE_FAIL';
  elseif ~scalar_ok
    first_failure = 'CANDIDATE_SCORE_SCALAR_INVARIANCE_FAIL';
  elseif ~balance_ok
    first_failure = 'RAW_PHYSICAL_MINIMUM_LOCATION_FAIL';
  end
  if ~pass
    status = [upper(stage),'_FAIL'];
  elseif isempty(candidates)
    status = [upper(stage),'_NO_STRICT_INTERIOR_CANDIDATE'];
  elseif strcmp(stage,'screen')
    status = 'M12_SCREEN_DISCRETE_DIPS_READY_FOR_M24';
  elseif strcmp(stage,'refine24')
    status = 'M24_DISCRETE_REAL_AXIS_CANDIDATE_READY_FOR_M48';
  else
    status = 'M48_DISCRETE_REAL_AXIS_CANDIDATE_RECORDED';
  end
  result = LOCAL_candidate_finish(stage,pass,next_authorized,first_failure, ...
    timer,gates,scans,candidates,diagnostics,supplemental,provenance,cfg, ...
    output_dir,status,balance_rows,parent_token);
end

function result = LOCAL_candidate_finish(stage,pass,next_authorized, ...
    first_failure,timer,gates,scans,candidates,diagnostics,supplemental, ...
    provenance,cfg,output_dir,status,balance_rows,parent_token)
  if nargin < 14
    status = [upper(stage),'_FAIL'];
  end
  if nargin < 15
    balance_rows = cell(0,7);
  end
  if nargin < 16
    parent_token = '';
  end
  if strcmp(stage,'screen')
    claim = 'M12_SCREEN_ONLY';
  else
    claim = [upper(stage),'_DISCRETE_REAL_AXIS_CANDIDATE_ONLY'];
  end
  [point_rows,score_rows] = LOCAL_scan_rows(scans);
  candidate_rows = LOCAL_candidate_rows(diagnostics);
  candidate_audit = struct([]);
  if strcmp(stage,'confirm48') && ~isempty(candidates)
    candidate_audit = LOCAL_candidate_audit(scans,candidates);
  end
  lineage = LOCAL_lineage(stage,status,parent_token,provenance,cfg);
  all_gates_pass = ~isempty(gates) && all(cell2mat(gates(:,4)));
  result = struct('schema',cfg.schema,'experiment_id',cfg.experiment_id, ...
    'stage',stage,'status',status,'pass',pass,'next_authorized',next_authorized, ...
    'first_failure',first_failure,'elapsed_seconds',toc(timer), ...
    'gates',{gates},'candidates',{candidates}, ...
    'candidate_diagnostics',{diagnostics}, ...
    'candidate_audit',{candidate_audit}, ...
    'point_rows',{point_rows},'score_rows',{score_rows}, ...
    'balance_rows',{balance_rows},'supplemental_used',supplemental, ...
    'provenance',provenance,'lineage',lineage,'config',cfg, ...
    'all_gates_pass',all_gates_pass,'pass_with_conditions',false, ...
    'pass_semantics','CANDIDATE_STAGE_GATES', ...
    'locator_authorized',false,'root_isolation_authorized',false, ...
    'claim_boundary',claim);
  LOCAL_csv(fullfile(output_dir,'gates.csv'), ...
    {'group','gate','status','pass','value','tolerance','note'},gates);
  LOCAL_csv(fullfile(output_dir,'points.csv'), ...
    {'group','k','M','use_fine','solve_max','wood_distance','unit_gap', ...
    'schur_max','scientific_pass'},point_rows);
  LOCAL_csv(fullfile(output_dir,'scores.csv'), ...
    {'group','k','level','raw_sigma1','raw_sigma2','raw_sigmamax', ...
    'sigma1','sigma2','sigmamax','s1','r12','g12','scalar_mutation', ...
    'seed_scale'},score_rows);
  LOCAL_csv(fullfile(output_dir,'candidates.csv'), ...
    {'rank','k','k2_metadata','s1','r12','g12','prominence','left_overlap', ...
    'right_overlap','vector_pass','clear','strict_interior','eligible', ...
    'claim'},candidate_rows);
  LOCAL_csv(fullfile(output_dir,'balance.csv'), ...
    {'group','level','raw_min_k','physical_min_k','index_difference', ...
    'tolerance','pass'},balance_rows);
  LOCAL_write_provenance(fullfile(output_dir,'provenance.csv'),provenance);
  LOCAL_write_lineage(fullfile(output_dir,'lineage.csv'),lineage);
  save(fullfile(output_dir,'result.mat'),'result','-v7');
  LOCAL_report(fullfile(output_dir,'report.md'),result);
  LOCAL_log(fullfile(output_dir,'run.log'),result);
  fprintf('TEP_MC_SCAN_STAGE=%s STATUS=%s candidates=%d seconds=%.6g\n', ...
    stage,status,numel(candidates),result.elapsed_seconds);
end

function result = LOCAL_full(cfg,here,repo)
  output_dir = fullfile(here,'output','full'); LOCAL_mkdir(output_dir);
  timer = tic; gates = cell(0,7); provenance = LOCAL_provenance(here,repo);
  screen = LOCAL_candidate_stage('screen',cfg,here,repo);
  gates(end+1,:) = LOCAL_gate('full','screen',screen.pass, ...
    double(screen.pass),1,screen.status);
  refine = struct(); confirm = struct();
  if screen.next_authorized
    refine = LOCAL_candidate_stage('refine24',cfg,here,repo);
    gates(end+1,:) = LOCAL_gate('full','refine24',refine.pass, ...
      double(refine.pass),1,refine.status);
  end
  if isstruct(refine) && isfield(refine,'next_authorized') && refine.next_authorized
    confirm = LOCAL_candidate_stage('confirm48',cfg,here,repo);
    gates(end+1,:) = LOCAL_gate('full','confirm48',confirm.pass, ...
      double(confirm.pass),1,confirm.status);
  end
  pass = all(cell2mat(gates(:,4)));
  if ~pass
    status = 'I1_3_CANDIDATE_PIPELINE_FAIL'; first_failure = 'STAGE_GATE_FAIL';
  elseif isfield(confirm,'status')
    status = confirm.status; first_failure = '';
  elseif isfield(refine,'status')
    status = refine.status; first_failure = '';
  else
    status = screen.status; first_failure = '';
  end
  parent_token = screen.lineage.token;
  child_lineage = struct('screen',screen.lineage.token, ...
    'refine24','','confirm48','');
  final_candidates = screen.candidates;
  refine_status = 'NOT_RUN'; confirm_status = 'NOT_RUN';
  if isfield(refine,'status')
    refine_status = refine.status; parent_token = refine.lineage.token;
    child_lineage.refine24 = refine.lineage.token;
    final_candidates = refine.candidates;
  end
  if isfield(confirm,'status')
    confirm_status = confirm.status; parent_token = confirm.lineage.token;
    child_lineage.confirm48 = confirm.lineage.token;
    final_candidates = confirm.candidates;
  end
  lineage = LOCAL_lineage('full',status,parent_token,provenance,cfg);
  all_gates_pass = ~isempty(gates) && all(cell2mat(gates(:,4)));
  result = struct('schema',cfg.schema,'experiment_id',cfg.experiment_id, ...
    'stage','full','status',status,'pass',pass,'first_failure',first_failure, ...
    'elapsed_seconds',toc(timer),'gates',{gates}, ...
    'screen_status',screen.status,'refine24_status',refine_status, ...
    'confirm48_status',confirm_status,'final_candidates',{final_candidates}, ...
    'child_lineage',child_lineage,'provenance',provenance, ...
    'lineage',lineage,'config',cfg,'all_gates_pass',all_gates_pass, ...
    'pass_with_conditions',false,'pass_semantics','CANDIDATE_PIPELINE_GATES', ...
    'claim_boundary','DISCRETE_REAL_AXIS_CANDIDATES_ONLY');
  LOCAL_csv(fullfile(output_dir,'gates.csv'), ...
    {'group','gate','status','pass','value','tolerance','note'},gates);
  LOCAL_write_provenance(fullfile(output_dir,'provenance.csv'),provenance);
  LOCAL_write_lineage(fullfile(output_dir,'lineage.csv'),lineage);
  save(fullfile(output_dir,'result.mat'),'result','-v7');
  LOCAL_report(fullfile(output_dir,'report.md'),result);
  LOCAL_log(fullfile(output_dir,'run.log'),result);
  fprintf('TEP_MC_SCAN_STAGE=full STATUS=%s seconds=%.6g\n', ...
    status,result.elapsed_seconds);
end

function [ok,prior,note] = LOCAL_prerequisite(path,field,expected_stage,cfg,p)
  ok = false;
  prior = struct();
  note = 'prerequisite result missing';
  if ~isfile(path), return; end
  loaded = load(path,'result');
  if ~isfield(loaded,'result')
    note = 'prerequisite MAT has no result variable';
    return;
  end
  prior = loaded.result;
  [lineage_ok,lineage_note] = LOCAL_lineage_ok(prior,expected_stage,p,cfg);
  field_ok = isfield(prior,field) && isscalar(prior.(field)) && ...
    (islogical(prior.(field)) || isnumeric(prior.(field))) && ...
    logical(prior.(field));
  ok = lineage_ok && field_ok;
  if ~lineage_ok
    note = lineage_note;
  elseif ~field_ok
    note = sprintf('verified lineage but authorization field %s is false',field);
  else
    note = sprintf('%s; authorization field %s is true',lineage_note,field);
  end
end

function scan = LOCAL_scan_group(label,M,kvals,seed_k,use_fine,cfg)
  kvals = sort(unique(kvals(:).'));
  nodes = repmat(struct(),1,numel(kvals));
  for j = 1:numel(kvals)
    nodes(j).k = kvals(j);
    nodes(j).coarse = LOCAL_prepare(kvals(j),M,cfg.coarse,cfg);
    if use_fine
      nodes(j).fine = LOCAL_prepare(kvals(j),M,cfg.fine,cfg);
    end
  end
  seed_index = find(abs(kvals-seed_k) <= 1e-12,1);
  if isempty(seed_index)
    seed = struct('coarse',LOCAL_prepare(seed_k,M,cfg.coarse,cfg));
    if use_fine, seed.fine = LOCAL_prepare(seed_k,M,cfg.fine,cfg); end
  else
    seed = nodes(seed_index);
  end
  if use_fine, pivot_level = seed.fine; else, pivot_level = seed.coarse; end
  rows_plus = LOCAL_rows(pivot_level.plus.Z,2*M+1);
  rows_minus = LOCAL_rows(pivot_level.minus.Z,2*M+1);
  seed.coarse = LOCAL_complete(seed.coarse,rows_plus,rows_minus,cfg);
  coarse_scale = norm(seed.coarse.Aphys,'fro');
  if use_fine
    seed.fine = LOCAL_complete(seed.fine,rows_plus,rows_minus,cfg);
    fine_scale = norm(seed.fine.Aphys,'fro');
  end
  pass = true;
  for j = 1:numel(nodes)
    nodes(j).coarse = LOCAL_complete(nodes(j).coarse,rows_plus,rows_minus,cfg);
    nodes(j).coarse = LOCAL_set_score(nodes(j).coarse,coarse_scale,cfg);
    if use_fine
      nodes(j).fine = LOCAL_complete(nodes(j).fine,rows_plus,rows_minus,cfg);
      nodes(j).fine = LOCAL_set_score(nodes(j).fine,fine_scale,cfg);
      [nodes(j).metric,nodes(j).pass] = LOCAL_level_metrics(nodes(j),cfg);
      nodes(j).pass = nodes(j).pass && nodes(j).coarse.mutation.pass && ...
        nodes(j).fine.mutation.pass && ...
        nodes(j).coarse.score.scalar_mutation <= cfg.score_mutation_tol && ...
        nodes(j).fine.score.scalar_mutation <= cfg.score_mutation_tol;
    else
      nodes(j).metric = struct('schur_max',nodes(j).coarse.schur);
      nodes(j).pass = LOCAL_single_ok(nodes(j).coarse,cfg);
    end
    pass = pass && nodes(j).pass;
  end
  [neighbor_rows,neighbor_ok,neighbor_min] = LOCAL_neighbors_scan(nodes,use_fine,cfg);
  scan = struct('label',label,'M',M,'seed_k',seed_k,'use_fine',use_fine, ...
    'nodes',{nodes},'neighbor_rows',{neighbor_rows}, ...
    'neighbor_min',neighbor_min,'pass',pass && neighbor_ok);
end

function ok = LOCAL_single_ok(level,cfg)
  K = level.K; schur_tol = 1e3*K*eps;
  rows_ok = min([level.plus.row_margin,level.minus.row_margin]) > 100*K*eps && ...
    max([level.plus.row_condition,level.minus.row_condition])*eps <= ...
    cfg.chart_condition_eps_tol && ...
    max(level.plus.row_solve,level.minus.row_solve) <= schur_tol;
  ok = level.solve_residual <= cfg.solve_tol && level.plus.pass && ...
    level.minus.pass && level.cp.safe && level.cm.safe && rows_ok && ...
    level.schur <= schur_tol && level.branch_ok && ...
    level.gamma_identity <= cfg.solve_tol && level.wood_distance > 100*eps && ...
    isequal(level.wall_labels,{'LEFT_CELL_WALL','RIGHT_CELL_WALL'}) && ...
    level.mutation.pass && ...
    level.score.scalar_mutation <= cfg.score_mutation_tol;
end

function [rows,pass,min_value] = LOCAL_neighbors_scan(nodes,use_fine,cfg)
  rows = cell(0,8); pass = true; min_value = 1;
  if use_fine, levels = {'coarse','fine'}; else, levels = {'coarse'}; end
  sides = {'plus','minus'};
  for j = 1:numel(nodes)-1
    for l = 1:numel(levels)
      for s = 1:2
        [value,~] = LOCAL_overlap(nodes(j).(levels{l}).(sides{s}).Z, ...
          nodes(j+1).(levels{l}).(sides{s}).Z);
        ok = value >= cfg.neighbor_overlap_min;
        rows(end+1,:) = {nodes(j).k,nodes(j+1).k,levels{l},sides{s}, ...
          value,value,cfg.neighbor_overlap_min,ok}; %#ok<AGROW>
        pass = pass && ok; min_value = min(min_value,value);
      end
    end
  end
end

function [candidates,diagnostics] = LOCAL_candidates(scan,cfg)
  nodes = scan.nodes;
  if scan.use_fine, level = 'fine'; else, level = 'coarse'; end
  candidates = struct([]); diagnostics = struct([]);
  for j = 2:numel(nodes)-1
    left = nodes(j-1).(level).score.s1;
    center = nodes(j).(level).score.s1;
    right = nodes(j+1).(level).score.s1;
    strict = center < left && center < right;
    prominence = min(left,right)/max(center,realmin);
    r12 = nodes(j).(level).score.r12;
    score_eligible = strict && prominence >= cfg.prominence_min && ...
      r12 <= cfg.r12_max;
    if score_eligible
      if scan.use_fine
        [left_overlap,right_overlap] = LOCAL_singular_vector_overlap(nodes(j));
        vector_pass = left_overlap >= cfg.neighbor_overlap_min && ...
          right_overlap >= cfg.neighbor_overlap_min;
      else
        left_overlap = NaN; right_overlap = NaN; vector_pass = true;
      end
      eligible = score_eligible && vector_pass;
      clear = prominence >= cfg.clear_prominence && r12 <= cfg.clear_r12;
      item = struct('k',nodes(j).k,'s1',center,'r12',r12, ...
        'k2_metadata',nodes(j).k^2, ...
        'g12',nodes(j).(level).score.g12,'prominence',prominence, ...
        'left_overlap',left_overlap,'right_overlap',right_overlap, ...
        'vector_pass',vector_pass,'clear',clear, ...
        'strict_interior',strict,'eligible',eligible, ...
        'claim','DISCRETE_REAL_AXIS_CANDIDATE');
      diagnostics = [diagnostics,item]; %#ok<AGROW>
      if eligible, candidates = [candidates,item]; end %#ok<AGROW>
    end
  end
  candidates = LOCAL_sort_candidates(candidates);
end

function [left_overlap,right_overlap] = LOCAL_singular_vector_overlap(node)
  [Uc,~,Vc] = svd(node.coarse.Aphys/node.coarse.score.seed_scale,'econ');
  [Uf,~,Vf] = svd(node.fine.Aphys/node.fine.score.seed_scale,'econ');
  left_overlap = abs(Uc(:,end)'*Uf(:,end));
  right_overlap = abs(Vc(:,end)'*Vf(:,end));
end

function candidates = LOCAL_sort_candidates(candidates)
  if isempty(candidates), return; end
  [~,order] = sort([candidates.s1]); candidates = candidates(order);
end

function value = LOCAL_scan_scalar_max(scans)
  value = 0;
  for g = 1:numel(scans)
    for j = 1:numel(scans(g).nodes)
      value = max(value,scans(g).nodes(j).coarse.score.scalar_mutation);
      if scans(g).use_fine
        value = max(value,scans(g).nodes(j).fine.score.scalar_mutation);
      end
    end
  end
end

function [rows,pass,max_difference] = LOCAL_balance_locations(scans)
  rows = cell(0,7); pass = true; max_difference = 0;
  for g = 1:numel(scans)
    if scans(g).use_fine, level = 'fine'; else, level = 'coarse'; end
    nodes = scans(g).nodes; raw = zeros(1,numel(nodes)); physical = raw;
    for j = 1:numel(nodes)
      score = nodes(j).(level).score;
      raw(j) = score.raw_sigma1/score.raw_sigmamax;
      physical(j) = score.s1;
    end
    [~,raw_index] = min(raw); [~,physical_index] = min(physical);
    difference = abs(raw_index-physical_index); ok = difference <= 1;
    rows(end+1,:) = {scans(g).label,level,nodes(raw_index).k, ...
      nodes(physical_index).k,difference,1,ok}; %#ok<AGROW>
    pass = pass && ok; max_difference = max(max_difference,difference);
  end
end

function [point_rows,score_rows] = LOCAL_scan_rows(scans)
  point_rows = cell(0,9); score_rows = cell(0,14);
  for g = 1:numel(scans)
    for j = 1:numel(scans(g).nodes)
      n = scans(g).nodes(j);
      solve_max = n.coarse.solve_residual;
      unit_gap = min(n.coarse.plus.unit_gap,n.coarse.minus.unit_gap);
      schur_max = n.coarse.schur;
      if scans(g).use_fine
        solve_max = max(solve_max,n.fine.solve_residual);
        unit_gap = min([unit_gap,n.fine.plus.unit_gap,n.fine.minus.unit_gap]);
        schur_max = max(schur_max,n.fine.schur);
      end
      point_rows(end+1,:) = {scans(g).label,n.k,scans(g).M, ...
        scans(g).use_fine,solve_max,n.coarse.wood_distance,unit_gap, ...
        schur_max,n.pass}; %#ok<AGROW>
      score_rows(end+1,:) = LOCAL_flat_score(scans(g).label,n.k, ...
        'coarse',n.coarse.score); %#ok<AGROW>
      if scans(g).use_fine
        score_rows(end+1,:) = LOCAL_flat_score(scans(g).label,n.k, ...
          'fine',n.fine.score); %#ok<AGROW>
      end
    end
  end
end

function row = LOCAL_flat_score(group,k,level,s)
  row = {group,k,level,s.raw_sigma1,s.raw_sigma2,s.raw_sigmamax, ...
    s.sigma1,s.sigma2,s.sigmamax,s.s1,s.r12,s.g12, ...
    s.scalar_mutation,s.seed_scale};
end

function rows = LOCAL_candidate_rows(candidates)
  rows = cell(0,14);
  for j = 1:numel(candidates)
    c = candidates(j);
    rows(end+1,:) = {j,c.k,c.k2_metadata,c.s1,c.r12,c.g12,c.prominence, ...
      c.left_overlap,c.right_overlap,c.vector_pass,c.clear, ...
      c.strict_interior,c.eligible,c.claim}; %#ok<AGROW>
  end
end

function audit = LOCAL_candidate_audit(scans,candidates)
  audit = repmat(struct('k',[],'k2_metadata',[],'coarse',[], ...
    'fine',[]),1,numel(candidates));
  for j = 1:numel(candidates)
    found = false;
    for g = 1:numel(scans)
      index = find(abs([scans(g).nodes.k]-candidates(j).k) <= 1e-12,1);
      if isempty(index), continue; end
      node = scans(g).nodes(index);
      audit(j) = struct('k',candidates(j).k, ...
        'k2_metadata',candidates(j).k2_metadata, ...
        'coarse',LOCAL_candidate_level_audit(node.coarse), ...
        'fine',LOCAL_candidate_level_audit(node.fine));
      found = true;
      break;
    end
    if ~found
      error('tep_mc_scan:CandidateAudit', ...
        'Cannot resolve confirm48 candidate %.17g.',candidates(j).k);
    end
  end
end

function audit = LOCAL_candidate_level_audit(level)
  scaled = level.Aphys/level.score.seed_scale;
  [U,~,V] = svd(scaled,'econ');
  left = U(:,end); left = left/norm(left);
  right = V(:,end); right = right/norm(right);
  [row_weight,column_weight] = ...
    LOCAL_physical_weights(level.beta_m,level.gamma);
  audit = struct('Adef_D_unbalanced',level.Adef.D, ...
    'normalized_min_left_singular_vector',left, ...
    'normalized_min_right_singular_vector',right, ...
    'physical_row_weight',row_weight, ...
    'physical_column_weight',column_weight, ...
    'seed_scale',level.score.seed_scale);
end

%% ==================== Cell maps and ordered QZ ====================
% These helpers build direct levels and retain projective diagnostics.

function level = LOCAL_prepare(k,M,spec,cfg)
  level = LOCAL_make_level(k,M,spec,cfg);
  pair = LOCAL_pair(level,M);
  level.pair = pair;
  level.plus = LOCAL_qz(pair.A,pair.B,M,cfg,level.blocks, ...
    'plus','LEFT_CELL_WALL');
  level.minus = LOCAL_qz(pair.B,pair.A,M,cfg,level.blocks, ...
    'minus','RIGHT_CELL_WALL');
end

function level = LOCAL_make_level(k,M,spec,cfg)
  timer = tic;
  pars = struct('k',k,'beta',cfg.beta,'d',cfg.d,'periodic_axis','y');
  channels = bloch.rayleigh_channels(k,cfg.beta,cfg.d,M,cfg.X_R-cfg.X_L);
  [C,curvelen] = geom.construct_cont(spec.ntot,'circle',0,0,cfg.R);
  proxy_spec = struct('H',cfg.H,'proxy_dist',cfg.proxy_dist, ...
    'N_side',spec.N_side,'N_top',spec.N_top, ...
    'N_proxy_edge',spec.N_proxy_edge,'M_pw',spec.M_pw);
  proxy = kernel.precomp_proxy(pars,proxy_spec);
  kint = sqrt(1+16*cfg.s)*k;
  cell_result = bloch.construct_S(C,k,kint,pars,proxy,curvelen, ...
    channels,cfg.X_L,cfg.X_R);
  K = channels.K;
  blocks = struct('R_L',cell_result.R_L,'T_RL',cell_result.T_RL, ...
    'T_LR',cell_result.T_LR,'R_R',cell_result.R_R);
  blocks.A_sc = [-blocks.R_L,eye(K);blocks.T_LR,zeros(K)];
  blocks.B_sc = [zeros(K),blocks.T_RL;eye(K),-blocks.R_R];
  beta_m = channels.beta_m(:); gamma = channels.gamma_m(:);
  gamma_identity = max(abs(gamma.^2-(k^2-beta_m.^2))) / ...
    max(1,max(abs(k^2-beta_m.^2)));
  branch_tol = 1e3*eps*max(1,max(abs(gamma)));
  propagating = abs(imag(gamma)) <= branch_tol;
  branch_ok = all(real(gamma(propagating)) >= -branch_tol) && ...
    all(imag(gamma(~propagating)) >= -branch_tol);
  wood_distance = min(abs(k-abs(beta_m)));
  level = struct('k',k,'M',M,'K',K,'spec',spec,'proxy',proxy_spec, ...
    'modes',channels,'gamma',gamma,'beta_m',beta_m, ...
    'phase',channels.phase(:),'blocks',blocks, ...
    'wall_labels',{{'LEFT_CELL_WALL','RIGHT_CELL_WALL'}}, ...
    'solve_residual',cell_result.solve_relative_residual_norm, ...
    'system_rows',size(cell_result.A_QP,1), ...
    'gamma_identity',gamma_identity,'branch_ok',branch_ok, ...
    'wood_distance',wood_distance,'seconds',toc(timer));
end

function pair = LOCAL_pair(level,M)
  K = 2*M+1;
  pair.A = [-level.blocks.R_L,eye(K);level.blocks.T_LR,zeros(K)];
  pair.B = [zeros(K),level.blocks.T_RL;eye(K),-level.blocks.R_R];
end

function q = LOCAL_qz(A,B,M,cfg,S,side,plane)
  K = 2*M+1;
  rho = hypot(norm(A,'fro'),norm(B,'fro'));
  A = A/rho; B = B/rho;
  [U,V,Q,Z] = qz(A,B,'complex');
  raw = hypot(norm(A-Q'*U*Z','fro'),norm(B-Q'*V*Z','fro'));
  tau = max(100*eps,10*raw);
  alpha = diag(U); theta = diag(V); scale = hypot(abs(alpha),abs(theta));
  indeterminate = scale <= tau; scale(indeterminate) = 1;
  an = abs(alpha)./scale; tn = abs(theta)./scale;
  infinite = ~indeterminate & tn <= tau & an > tau;
  neutral = ~indeterminate & ~infinite & abs(an-tn) <= tau;
  stable = ~indeterminate & ~infinite & ~neutral & an < tn-tau;
  unstable = infinite | (~indeterminate & ~neutral & an > tn+tau);
  finite_gap = abs(an(~indeterminate)-tn(~indeterminate));
  if isempty(finite_gap), unit_gap = 0; else, unit_gap = min(finite_gap); end
  q = struct('plane',plane,'stable_count',sum(stable), ...
    'unstable_count',sum(unstable),'neutral_count',sum(neutral), ...
    'infinite_count',sum(infinite),'indeterminate_count',sum(indeterminate), ...
    'unit_gap',unit_gap,'tau_proj',tau,'raw_residual',raw, ...
    'residual',Inf,'Z',zeros(2*K,K),'ref_available',false, ...
    'ref_rcond_D',0,'ref_rcond_F',0,'ref_residual',NaN, ...
    'regular_infinity',false,'pass',false);
  counts_ok = q.stable_count == K && q.unstable_count == K && ...
    q.neutral_count == 0 && q.indeterminate_count == 0;
  if ~counts_ok, return; end
  [Uo,Vo,Qo,Zo] = ordqz(U,V,Q,Z,stable);
  Qleft = Qo'; Zs = Zo(:,1:K); Qs = Qleft(:,1:K);
  q.residual = max([norm(A-Qleft*Uo*Zo','fro'), ...
    norm(B-Qleft*Vo*Zo','fro'), ...
    norm(A*Zs-Qs*Uo(1:K,1:K),'fro'), ...
    norm(B*Zs-Qs*Vo(1:K,1:K),'fro')]);
  q.Z = Zs;
  [q.ref_available,q.ref_rcond_D,q.ref_rcond_F,q.ref_residual] = ...
    LOCAL_reference(S,Zs,side);
  ref_ok = ~q.ref_available || q.ref_residual <= cfg.solve_tol;
  q.regular_infinity = q.indeterminate_count == 0 && ...
    q.infinite_count <= q.unstable_count;
  q.pass = raw <= cfg.solve_tol && q.residual <= cfg.solve_tol && ...
    ref_ok && q.regular_infinity && strcmp(q.plane,plane);
end

function [available,rcond_D,rcond_F,residual] = LOCAL_reference(S,Z,side)
  K = size(S.R_L,1); I = eye(K);
  A = Z(1:K,:); B = Z(K+1:end,:);
  if strcmp(side,'plus'), D = A; N = B; else, D = B; N = A; end
  rcond_D = rcond(D); rcond_F = 0; residual = NaN;
  available = rcond_D > 100*K*eps;
  if ~available, return; end
  R = LOCAL_right(N,D);
  if strcmp(side,'plus')
    F = I-R*S.R_R; rcond_F = rcond(F);
    available = rcond_F > 100*K*eps;
    if available
      x = F\(R*S.T_LR);
      residual = max(LOCAL_rel(B,R*A),LOCAL_rel(R,S.R_L+S.T_RL*x));
    end
  else
    F = I-R*S.R_L; rcond_F = rcond(F);
    available = rcond_F > 100*K*eps;
    if available
      x = F\(R*S.T_RL);
      residual = max(LOCAL_rel(A,R*B),LOCAL_rel(R,S.R_R+S.T_LR*x));
    end
  end
end

%% ==================== Fixed frames, charts, and assembly ====================
% These helpers normalize once-selected rows and assemble gauge-invariant maps.

function rows = LOCAL_rows(Z,K)
  [~,~,pivot] = qr(Z','vector');
  rows = pivot(1:K);
end

function level = LOCAL_complete(level,rows_plus,rows_minus,cfg)
  [level.plus.Zhat,level.plus.row_margin,level.plus.row_condition, ...
    level.plus.row_solve] = LOCAL_normalize(level.plus.Z,rows_plus);
  [level.minus.Zhat,level.minus.row_margin,level.minus.row_condition, ...
    level.minus.row_solve] = LOCAL_normalize(level.minus.Z,rows_minus);
  [level.Dp,level.Np,level.Dm,level.Nm] = LOCAL_cauchy(level, ...
    level.plus.Zhat,level.minus.Zhat);
  level.cp = LOCAL_chart(level.Dp,level.Np,level.beta_m,cfg);
  level.cm = LOCAL_chart(level.Dm,level.Nm,level.beta_m,cfg);
  [level.Adef,level.schur] = LOCAL_adef(level);
  level.Aphys = LOCAL_physical(level.Adef.D,level.beta_m,level.gamma);

  T = LOCAL_mutator(level.K);
  Zpm = level.plus.Z*T; Zmm = level.minus.Z*T;
  [Zph,~,~,~] = LOCAL_normalize(Zpm,rows_plus);
  [Zmh,~,~,~] = LOCAL_normalize(Zmm,rows_minus);
  [Dp,Np,Dm,Nm] = LOCAL_cauchy(level,Zph,Zmh);
  cp = LOCAL_chart(Dp,Np,level.beta_m,cfg);
  cm = LOCAL_chart(Dm,Nm,level.beta_m,cfg);
  mutated = level;
  mutated.Dp = Dp; mutated.Np = Np; mutated.Dm = Dm; mutated.Nm = Nm;
  mutated.cp = cp; mutated.cm = cm;
  [mutated.Adef,~] = LOCAL_adef(mutated);
  mutated.Aphys = LOCAL_physical(mutated.Adef.D,level.beta_m,level.gamma);
  level.Adef_mutated = mutated.Adef;
  level.Aphys_mutated = mutated.Aphys;
  level.Lambda_mutated = struct('plus',cp.Lambda,'minus',cm.Lambda);
  level.mutation.lambda = max(LOCAL_rel(level.cp.Lambda,cp.Lambda), ...
    LOCAL_rel(level.cm.Lambda,cm.Lambda));
  level.mutation.adef = LOCAL_rel(level.Adef.D,mutated.Adef.D);
  level.mutation.score = 0;
  level.mutation.pass = level.mutation.lambda <= cfg.basis_mutation_tol && ...
    level.mutation.adef <= cfg.basis_mutation_tol;
end

function [Zhat,margin,condition,solve_residual] = LOCAL_normalize(Z,rows)
  HZ = Z(rows,:);
  values = svd(HZ,'econ');
  margin = min(values);
  condition = max(values)/max(margin,realmin);
  Zhat = LOCAL_right(Z,HZ);
  solve_residual = LOCAL_rel(Zhat(rows,:),eye(size(HZ,1)));
end

function T = LOCAL_mutator(K)
  powers = mod((0:K-1).',3)-1;
  T = diag(2.^powers);
end

function [Dp,Np,Dm,Nm] = LOCAL_cauchy(level,Zp,Zm)
  K = level.K; Gamma = diag(level.gamma);
  Ap = Zp(1:K,:); Bp = Zp(K+1:end,:);
  Am = Zm(1:K,:); Bm = Zm(K+1:end,:);
  Dp = Ap+Bp; Np = 1i*Gamma*(Ap-Bp);
  Dm = Am+Bm; Nm = -1i*Gamma*(Am-Bm);
end

function c = LOCAL_chart(D,N,beta_m,cfg)
  K = size(D,1); b = sqrt(1+abs(beta_m(:)).^2);
  GDh = diag(sqrt(b)); GD = diag(b); GN = diag(1./b);
  gram = D'*GD*D+N'*GN*N; gram = (gram+gram')/2;
  [V,L] = eig(gram); values = max(real(diag(L)),0);
  c = struct('margin',0,'condition',Inf,'condition_eps',Inf, ...
    'solve_residual',NaN,'safe',false,'Lambda',[]);
  if min(values) <= 0, return; end
  half = V*diag(sqrt(values))*V';
  Dbar = (half.'\(GDh*D).').';
  singular = svd(Dbar,'econ');
  c.margin = min(singular);
  c.condition = max(singular)/max(c.margin,realmin);
  c.condition_eps = c.condition*eps;
  c.safe = c.margin > 100*K*eps && ...
    c.condition_eps <= cfg.chart_condition_eps_tol;
  if c.safe
    c.Lambda = LOCAL_right(N,D);
    c.solve_residual = LOCAL_rel(N,c.Lambda*D);
    c.safe = c.solve_residual <= 1e3*K*eps;
    if ~c.safe, c.Lambda = []; end
  end
end

function [out,schur_error] = LOCAL_adef(level)
  K = level.K; Gamma = diag(level.gamma); E = diag(level.phase);
  Lp = level.cp.Lambda; Lm = level.cm.Lambda;
  D = [-(1i*Gamma+Lm),(1i*Gamma-Lm)*E; ...
    (1i*Gamma-Lp)*E,-(1i*Gamma+Lp)];
  Z = zeros(K); I = eye(K);
  G = [I,E,-level.Dm,Z;-1i*Gamma,1i*Gamma*E,-level.Nm,Z; ...
    E,I,Z,-level.Dp;1i*Gamma*E,-1i*Gamma,Z,-level.Np];
  drow = [1:K,2*K+1:3*K]; nrow = [K+1:2*K,3*K+1:4*K];
  qcol = 1:2*K; ccol = 2*K+1:4*K;
  reduced = G(nrow,qcol)-G(nrow,ccol)*(G(drow,ccol)\G(drow,qcol));
  schur_error = LOCAL_rel(D,reduced);
  out = struct('D',D,'G',G);
end

function Aphys = LOCAL_physical(A,beta_m,gamma)
  [row_weight,column_weight] = LOCAL_physical_weights(beta_m,gamma);
  Aphys = row_weight.*A.*column_weight.';
end

function [row_weight,column_weight] = LOCAL_physical_weights(beta_m,gamma)
  b = sqrt(1+abs(beta_m(:)).^2);
  row_weight = repmat(sqrt(1./b),2,1);
  amplitude_weight = b+abs(gamma(:)).^2./b;
  column_weight = repmat(1./sqrt(amplitude_weight),2,1);
end

function score = LOCAL_score(Araw,Aphys,seed_scale,cfg)
  raw = sort(svd(Araw,'econ'),'ascend');
  singular = sort(svd(Aphys/seed_scale,'econ'),'ascend');
  score = struct('raw_sigma1',raw(1),'raw_sigma2',raw(2), ...
    'raw_sigmamax',raw(end),'sigma1',singular(1), ...
    'sigma2',singular(2),'sigmamax',singular(end), ...
    's1',singular(1)/singular(end), ...
    'r12',singular(1)/singular(2), ...
    'g12',(singular(2)-singular(1))/singular(end), ...
    'seed_scale',seed_scale,'scalar_mutation',0);
  base = [score.s1,score.r12,score.g12];
  for j = 1:numel(cfg.scalar_mutations)
    changed = sort(svd(cfg.scalar_mutations(j)*Aphys/seed_scale,'econ'),'ascend');
    current = [changed(1)/changed(end),changed(1)/changed(2), ...
      (changed(2)-changed(1))/changed(end)];
    score.scalar_mutation = max(score.scalar_mutation,max(abs(current-base)));
  end
end

function value = LOCAL_score_change(a,b)
  va = [a.s1,a.r12,a.g12];
  vb = [b.s1,b.r12,b.g12];
  value = max(abs(va-vb));
end

function level = LOCAL_set_score(level,seed_scale,cfg)
  level.score = LOCAL_score(level.Adef.D,level.Aphys,seed_scale,cfg);
  changed = LOCAL_score(level.Adef_mutated.D,level.Aphys_mutated, ...
    seed_scale,cfg);
  level.mutation.score = LOCAL_score_change(level.score,changed);
  level.mutation.pass = level.mutation.pass && ...
    level.mutation.score <= cfg.basis_mutation_tol;
end

%% ==================== Continuity metrics ====================
% These helpers evaluate adjacent levels, overlaps, differences, and mutations.

function [metric,pass] = LOCAL_level_metrics(node,cfg)
  a = node.coarse; b = node.fine;
  [metric.block_abs,metric.block_action] = LOCAL_block_change(a,b,cfg);
  metric.pencil_action = LOCAL_pair_change(a.pair,b.pair);
  [~,metric.subspace_plus] = LOCAL_overlap(a.plus.Z,b.plus.Z);
  [~,metric.subspace_minus] = LOCAL_overlap(a.minus.Z,b.minus.Z);
  [~,metric.cauchy_plus] = LOCAL_overlap(LOCAL_weighted(a.Dp,a.Np,a.beta_m), ...
    LOCAL_weighted(b.Dp,b.Np,b.beta_m));
  [~,metric.cauchy_minus] = LOCAL_overlap(LOCAL_weighted(a.Dm,a.Nm,a.beta_m), ...
    LOCAL_weighted(b.Dm,b.Nm,b.beta_m));
  metric.dtn_plus = LOCAL_rel(a.cp.Lambda,b.cp.Lambda);
  metric.dtn_minus = LOCAL_rel(a.cm.Lambda,b.cm.Lambda);
  metric.adef_action = LOCAL_rel(a.Adef.D,b.Adef.D);
  metric.schur_max = max(a.schur,b.schur);
  metric.row_solve_max = max([a.plus.row_solve,a.minus.row_solve, ...
    b.plus.row_solve,b.minus.row_solve]);
  metric.wall_ok = isequal(a.wall_labels,{'LEFT_CELL_WALL','RIGHT_CELL_WALL'}) && ...
    isequal(b.wall_labels,{'LEFT_CELL_WALL','RIGHT_CELL_WALL'}) && ...
    strcmp(a.plus.plane,'LEFT_CELL_WALL') && ...
    strcmp(a.minus.plane,'RIGHT_CELL_WALL') && ...
    strcmp(b.plus.plane,'LEFT_CELL_WALL') && ...
    strcmp(b.minus.plane,'RIGHT_CELL_WALL');
  charts_ok = a.cp.safe && a.cm.safe && b.cp.safe && b.cm.safe;
  rows_ok = min([a.plus.row_margin,a.minus.row_margin,b.plus.row_margin, ...
    b.minus.row_margin]) > 100*a.K*eps && ...
    max([a.plus.row_condition,a.minus.row_condition,b.plus.row_condition, ...
    b.minus.row_condition])*eps <= cfg.chart_condition_eps_tol && ...
    metric.row_solve_max <= 1e3*a.K*eps;
  qz_ok = a.plus.pass && a.minus.pass && b.plus.pass && b.minus.pass;
  branch_ok = a.branch_ok && b.branch_ok && ...
    max(a.gamma_identity,b.gamma_identity) <= cfg.solve_tol && ...
    min(a.wood_distance,b.wood_distance) > 100*eps;
  schur_tol = 1e3*a.K*eps;
  pass = max(a.solve_residual,b.solve_residual) <= cfg.solve_tol && ...
    metric.block_abs <= cfg.block_abs_tol && ...
    metric.block_action <= cfg.action_tol && ...
    metric.pencil_action <= cfg.action_tol && ...
    max([metric.subspace_plus,metric.subspace_minus, ...
    metric.cauchy_plus,metric.cauchy_minus]) <= cfg.subspace_tol && ...
    max(metric.dtn_plus,metric.dtn_minus) <= cfg.action_tol && ...
    metric.adef_action <= cfg.action_tol && metric.schur_max <= schur_tol && ...
    qz_ok && charts_ok && rows_ok && branch_ok && metric.wall_ok;
end

function [abs_max,action_max] = LOCAL_block_change(a,b,cfg)
  names = {'R_L','T_RL','T_LR','R_R'};
  weights = diag((1+abs(b.beta_m).^2).^(1/4));
  abs_max = 0; action_max = 0;
  for j = 1:numel(names)
    A = a.blocks.(names{j}); B = b.blocks.(names{j});
    abs_max = max(abs_max,max(abs(A-B),[],'all'));
    Aw = LOCAL_right(weights*A,weights);
    Bw = LOCAL_right(weights*B,weights);
    action = norm(Aw-Bw,2)/max(1,norm(Bw,2));
    action_max = max(action_max,action);
  end
  if ~isfinite(abs_max), abs_max = 1/cfg.rel_floor; end
end

function value = LOCAL_pair_change(a,b)
  value = hypot(norm(a.A-b.A,'fro'),norm(a.B-b.B,'fro')) / ...
    max(realmin,hypot(norm(b.A,'fro'),norm(b.B,'fro')));
end

function C = LOCAL_weighted(D,N,beta_m)
  b = sqrt(1+abs(beta_m(:)).^2);
  C = [sqrt(b).*D;(1./sqrt(b)).*N];
end

function [sigma_min,distance] = LOCAL_overlap(A,B)
  [Qa,~] = qr(A,0); [Qb,~] = qr(B,0);
  singular = svd(Qa'*Qb,'econ');
  sigma_min = min(singular);
  distance = sqrt(max(0,1-sigma_min^2));
end

function [rows,pass,min_value] = LOCAL_neighbors(nodes,cfg)
  rows = cell(0,8); pass = true; min_value = 1;
  levels = {'coarse','fine'}; sides = {'plus','minus'};
  for j = 1:numel(nodes)-1
    for l = 1:2
      for s = 1:2
        A = nodes(j).(levels{l}).(sides{s}).Z;
        B = nodes(j+1).(levels{l}).(sides{s}).Z;
        [value,~] = LOCAL_overlap(A,B);
        ok = value >= cfg.neighbor_overlap_min;
        rows(end+1,:) = {nodes(j).k,nodes(j+1).k,levels{l},sides{s}, ...
          value,value,cfg.neighbor_overlap_min,ok};
        pass = pass && ok; min_value = min(min_value,value);
      end
    end
  end
end

function [rows,pass,max_value,mutation_max,final_h] = ...
    LOCAL_fd(nodes,seed_index,cfg,hs)
  rows = cell(0,10); derivative = struct(); changed = struct();
  labels = {'coarse','fine'}; sides = {'plus','minus'};
  n_h = numel(hs);
  for l = 1:2
    label = labels{l};
    for j = 1:n_h
      h = hs(j);
      left = find(abs([nodes.k]-(cfg.k0-h)) <= 1e-12,1);
      right = find(abs([nodes.k]-(cfg.k0+h)) <= 1e-12,1);
      derivative.adef.(label){j} = ...
        (nodes(right).(label).Adef.D-nodes(left).(label).Adef.D)/(2*h);
      changed.adef.(label){j} = ...
        (nodes(right).(label).Adef_mutated.D- ...
        nodes(left).(label).Adef_mutated.D)/(2*h);
      for s = 1:2
        side = sides{s}; chart = ['c',side(1)];
        derivative.(side).(label){j} = ...
          (nodes(right).(label).(chart).Lambda- ...
          nodes(left).(label).(chart).Lambda)/(2*h);
        changed.(side).(label){j} = ...
          (nodes(right).(label).Lambda_mutated.(side)- ...
          nodes(left).(label).Lambda_mutated.(side))/(2*h);
      end
    end
  end
  last = n_h;
  final_h = struct('h',hs(last), ...
    'Adef',struct('coarse',derivative.adef.coarse{last}, ...
      'fine',derivative.adef.fine{last}), ...
    'Lambda_plus',struct('coarse',derivative.plus.coarse{last}, ...
      'fine',derivative.plus.fine{last}), ...
    'Lambda_minus',struct('coarse',derivative.minus.coarse{last}, ...
      'fine',derivative.minus.fine{last}));

  adef_change = zeros(n_h-1,2); adef_ratio = NaN(n_h,2);
  for l = 1:2
    label = labels{l};
    for j = 2:n_h
      adef_change(j-1,l) = LOCAL_rel(derivative.adef.(label){j-1}, ...
        derivative.adef.(label){j});
      if j >= 3
        adef_ratio(j,l) = adef_change(j-1,l) / ...
          max(adef_change(j-2,l),realmin);
      end
    end
  end

  level_action = zeros(1,n_h); dtn_action = zeros(2,n_h);
  mutation = zeros(6,n_h);
  for j = 1:n_h
    level_action(j) = LOCAL_rel(derivative.adef.coarse{j}, ...
      derivative.adef.fine{j});
    mutation(1,j) = LOCAL_rel(derivative.adef.coarse{j}, ...
      changed.adef.coarse{j});
    mutation(2,j) = LOCAL_rel(derivative.adef.fine{j}, ...
      changed.adef.fine{j});
    rows(end+1,:) = {'Adef',hs(j),norm(derivative.adef.coarse{j},'fro'), ...
      norm(derivative.adef.fine{j},'fro'),level_action(j), ...
      LOCAL_change_value(adef_change,1,j), ...
      LOCAL_change_value(adef_change,2,j), ...
      adef_ratio(j,1),adef_ratio(j,2),max(mutation(1:2,j))};
    for s = 1:2
      side = sides{s};
      dtn_action(s,j) = LOCAL_rel(derivative.(side).coarse{j}, ...
        derivative.(side).fine{j});
      mutation(2+s,j) = LOCAL_rel(derivative.(side).coarse{j}, ...
        changed.(side).coarse{j});
      mutation(4+s,j) = LOCAL_rel(derivative.(side).fine{j}, ...
        changed.(side).fine{j});
      rows(end+1,:) = {['Lambda_',side],hs(j), ...
        norm(derivative.(side).coarse{j},'fro'), ...
        norm(derivative.(side).fine{j},'fro'),dtn_action(s,j), ...
        NaN,NaN,NaN,NaN,max(mutation([2+s,4+s],j))};
    end
  end
  last_change = max(adef_change(end,:));
  last_ratio = max(adef_ratio(end,:));
  last_level = level_action(end);
  last_dtn = max(dtn_action(:,end));
  mutation_max = max(mutation,[],'all');
  pass = last_change <= cfg.fd_change_tol && ...
    last_ratio <= cfg.fd_ratio_tol && last_level <= cfg.fd_level_tol && ...
    last_dtn <= cfg.fd_level_tol;
  max_value = max([last_change/cfg.fd_change_tol, ...
    last_ratio/cfg.fd_ratio_tol,last_level/cfg.fd_level_tol, ...
    last_dtn/cfg.fd_level_tol]);
  if isempty(seed_index) || n_h < 3, pass = false; end
end

function value = LOCAL_change_value(change,column,j)
  if j == 1, value = NaN; else, value = change(j-1,column); end
end

function [rows,pass,max_ratio] = LOCAL_seed_subspaces(nodes,seed_index,cfg,hs)
  rows = cell(0,9); pass = true; max_ratio = 0;
  levels = {'coarse','fine'}; sides = {'plus','minus'};
  directions = [-1,1]; direction_labels = {'minus','plus'};
  previous = NaN(2,2,2);
  for j = 1:numel(hs)
    h = hs(j);
    for l = 1:2
      for s = 1:2
        for d = 1:2
          index = find(abs([nodes.k]-(cfg.k0+directions(d)*h)) <= 1e-12,1);
          [~,distance] = LOCAL_overlap(nodes(seed_index).(levels{l}).(sides{s}).Z, ...
            nodes(index).(levels{l}).(sides{s}).Z);
          prior = previous(l,s,d);
          if isnan(prior)
            ratio = NaN; monotone = true; ok = true;
          else
            ratio = distance/max(prior,realmin);
            monotone = distance <= prior*(1+1e-10);
            ok = monotone && ratio <= cfg.subspace_half_ratio_tol;
            max_ratio = max(max_ratio,ratio);
          end
          rows(end+1,:) = {h,levels{l},sides{s},direction_labels{d}, ...
            distance,prior,ratio,monotone,ok};
          previous(l,s,d) = distance;
          pass = pass && ok;
        end
      end
    end
  end
end

%% ==================== Tabular rows and provenance ====================
% These helpers flatten diagnostics and write durable stage artifacts.

function rows = LOCAL_qz_rows(node,M)
  rows = cell(0,23); levels = {'coarse','fine'}; sides = {'plus','minus'};
  for l = 1:2
    for s = 1:2
      q = node.(levels{l}).(sides{s});
      rows(end+1,:) = {node.k,M,levels{l},sides{s},q.plane, ...
        q.stable_count,q.unstable_count,q.neutral_count,q.infinite_count, ...
        q.indeterminate_count,q.unit_gap,q.tau_proj,q.raw_residual,q.residual, ...
        q.ref_available,q.ref_rcond_D,q.ref_rcond_F,q.ref_residual, ...
        q.row_margin,q.row_condition,q.row_solve,q.regular_infinity,q.pass};
    end
  end
end

function rows = LOCAL_chart_rows(node,M)
  rows = cell(0,12); levels = {'coarse','fine'}; sides = {'plus','minus'};
  charts = {'cp','cm'};
  for l = 1:2
    for s = 1:2
      c = node.(levels{l}).(charts{s});
      schur_tol = 1e3*node.(levels{l}).K*eps;
      rows(end+1,:) = {node.k,M,levels{l},sides{s},c.margin,c.condition, ...
        c.condition_eps,c.solve_residual,c.safe,node.(levels{l}).schur, ...
        schur_tol,'ALGEBRAIC_NOT_SEP_CERTIFIED'};
    end
  end
end

function rows = LOCAL_score_rows(node)
  rows = cell(0,13); levels = {'coarse','fine'};
  for l = 1:2
    score = node.(levels{l}).score;
    rows(end+1,:) = {node.k,levels{l},score.raw_sigma1,score.raw_sigma2, ...
      score.raw_sigmamax,score.sigma1,score.sigma2,score.sigmamax, ...
      score.s1,score.r12,score.g12,score.scalar_mutation,score.seed_scale};
  end
end

function p = LOCAL_provenance(here,repo)
  [status,sha] = system(sprintf('git -C "%s" rev-parse HEAD',repo));
  if status ~= 0, error('tep_mc_scan:Git','Cannot record Git SHA.'); end
  paths = struct('tep_mc_scan',LOCAL_source_path(mfilename('fullpath')), ...
    'scan_cfg',fullfile(here,'scan_cfg.m'), ...
    'precomp_proxy',which('kernel.precomp_proxy'), ...
    'construct_S',which('bloch.construct_S'), ...
    'construct_A_QP',which('op.construct_A_QP'), ...
    'rayleigh_channels',which('bloch.rayleigh_channels'), ...
    'construct_cont',which('geom.construct_cont'));
  names = fieldnames(paths); hashes = struct();
  for j = 1:numel(names), hashes.(names{j}) = LOCAL_hash(paths.(names{j})); end
  p = struct('runtime','MATLAB','version',version,'solver','lsqminnorm', ...
    'solver_path',which('lsqminnorm'),'git_sha',strtrim(sha), ...
    'source_paths',paths,'source_hashes',hashes,'fallbacks',0, ...
    'silent_rank_changes',0,'generated_utc',char(datetime('now', ...
    'TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss''Z''')));
end

function lineage = LOCAL_lineage(stage,status,parent_token,p,cfg)
  config_fingerprint = p.source_hashes.scan_cfg;
  source_hash = p.source_hashes.tep_mc_scan;
  payload = strjoin({cfg.schema,cfg.experiment_id,stage,status, ...
    parent_token,config_fingerprint,source_hash},'|');
  lineage = struct('stage',stage,'parent_token',parent_token, ...
    'config_fingerprint',config_fingerprint,'source_hash',source_hash, ...
    'token',LOCAL_text_hash(payload));
end

function [ok,note] = LOCAL_lineage_ok(prior,expected_stage,p,cfg)
  ok = isstruct(prior) && isfield(prior,'schema') && ...
    strcmp(prior.schema,cfg.schema) && isfield(prior,'experiment_id') && ...
    strcmp(prior.experiment_id,cfg.experiment_id) && ...
    isfield(prior,'stage') && strcmp(prior.stage,expected_stage) && ...
    isfield(prior,'status') && isfield(prior,'lineage') && ...
    isstruct(prior.lineage);
  if ~ok, note = 'schema, experiment, stage, status, or lineage missing'; return; end
  needed = {'stage','parent_token','config_fingerprint','source_hash','token'};
  ok = all(isfield(prior.lineage,needed));
  if ~ok, note = 'lineage fields missing'; return; end
  expected = LOCAL_lineage(prior.stage,prior.status, ...
    prior.lineage.parent_token,p,cfg);
  ok = strcmp(prior.lineage.stage,prior.stage) && ...
    strcmp(prior.lineage.config_fingerprint,p.source_hashes.scan_cfg) && ...
    strcmp(prior.lineage.source_hash,p.source_hashes.tep_mc_scan) && ...
    strcmp(prior.lineage.token,expected.token);
  if ok, note = 'schema, experiment, config, source, and lineage token verified'; ...
  else, note = 'config fingerprint, source hash, or lineage token mismatch'; end
end

function value = LOCAL_text_hash(payload)
  digest = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
  digest.update(typecast(uint8(payload(:)),'int8'));
  raw = typecast(digest.digest(),'uint8');
  value = lower(reshape(dec2hex(raw,2).',1,[]));
end

function path = LOCAL_source_path(path)
  if ~isfile(path) && isfile([path,'.m']), path = [path,'.m']; end
  if ~isfile(path), error('tep_mc_scan:Source','Cannot resolve %s.',path); end
end

function value = LOCAL_hash(path)
  fid = fopen(path,'r');
  if fid < 0, error('tep_mc_scan:Hash','Cannot read %s.',path); end
  cleanup = onCleanup(@() fclose(fid));
  bytes = fread(fid,Inf,'*uint8');
  digest = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
  digest.update(typecast(bytes(:),'int8'));
  raw = typecast(digest.digest(),'uint8');
  value = lower(reshape(dec2hex(raw,2).',1,[]));
  clear cleanup;
end

function LOCAL_write_provenance(path,p)
  names = fieldnames(p.source_paths); rows = cell(numel(names)+4,4);
  rows(1,:) = {'runtime',p.runtime,p.version,p.solver_path};
  rows(2,:) = {'generated_utc',p.generated_utc,'',''};
  rows(3,:) = {'fallbacks',p.fallbacks,'',''};
  rows(4,:) = {'silent_rank_changes',p.silent_rank_changes,'',''};
  for j = 1:numel(names)
    rows(j+4,:) = {names{j},p.source_paths.(names{j}), ...
      p.source_hashes.(names{j}),p.git_sha};
  end
  LOCAL_csv(path,{'object','path_or_runtime','hash_or_version','git_or_solver'},rows);
end

function LOCAL_write_lineage(path,lineage)
  rows = {
    'stage',lineage.stage;
    'parent_token',lineage.parent_token;
    'config_fingerprint',lineage.config_fingerprint;
    'source_hash',lineage.source_hash;
    'token',lineage.token};
  LOCAL_csv(path,{'field','value'},rows);
end

function LOCAL_write_pilot_point(path,point,cfg)
  if isfield(point,'solve_residual')
    rows = {cfg.k0,cfg.pilot_M,point.K,point.system_rows, ...
      point.solve_residual,point.wood_distance,point.gamma_identity,point.branch_ok};
  else
    rows = {cfg.k0,cfg.pilot_M,NaN,NaN,Inf,NaN,Inf,false};
  end
  LOCAL_csv(path,{'k','M','K','system_rows','solve_residual', ...
    'wood_distance','gamma_identity','branch_ok'},rows);
end

function LOCAL_estimate(path,cfg,dims)
  fid = fopen(path,'w'); cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'# I1.3 pilot runtime and memory estimate\n\n');
  fprintf(fid,'- M12: pencil/AdefD/AdefG = `50/50/100`.\n');
  fprintf(fid,'- M24: pencil/AdefD/AdefG = `98/98/196`.\n');
  fprintf(fid,'- M48: pencil/AdefD/AdefG = `194/194/388`.\n');
  fprintf(fid,'- Coarse/fine BIE density sizes: `320/512`.\n');
  fprintf(fid,'- Largest complex graph matrix: `%.2f MiB`.\n',dims{end,8});
  fprintf(fid,'- Serial engineering memory budget: `%d MiB`.\n',cfg.serial_memory_mib);
  fprintf(fid,'- Expected complete staged wall time: `<= %d min`.\n\n', ...
    cfg.full_time_minutes);
  fprintf(fid,'The calculation retains small dense A-def singular-value diagnostics ');
  fprintf(fid,'and excludes large separation diagnostics.\n');
  clear cleanup;
end

function row = LOCAL_gate(group,name,pass,value,tolerance,note)
  if pass, status = 'PASS'; else, status = 'FAIL'; end
  row = {group,name,status,logical(pass),value,tolerance,note};
end

function X = LOCAL_right(N,D)
  X = (D.'\N.').';
end

function value = LOCAL_rel(A,B)
  value = norm(A-B,'fro')/max(1,norm(A,'fro'));
end

function LOCAL_mkdir(path)
  if ~exist(path,'dir'), mkdir(path); end
end

function LOCAL_csv(path,headers,rows)
  fid = fopen(path,'w');
  if fid < 0, error('tep_mc_scan:Artifact','Cannot open %s.',path); end
  cleanup = onCleanup(@() fclose(fid));
  LOCAL_csv_row(fid,headers);
  for j = 1:size(rows,1), LOCAL_csv_row(fid,rows(j,:)); end
  clear cleanup;
end

function LOCAL_csv_row(fid,row)
  fields = cell(1,numel(row));
  for j = 1:numel(row)
    value = row{j};
    if islogical(value)
      item = sprintf('%d',value);
    elseif isnumeric(value)
      if isempty(value), item = ''; else, item = sprintf('%.17g',value); end
    else
      item = char(value);
    end
    fields{j} = ['"',strrep(item,'"','""'),'"'];
  end
  fprintf(fid,'%s\n',strjoin(fields,','));
end

function LOCAL_report(path,r)
  fid = fopen(path,'w'); cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'# I1.3 TEP Missing-Column %s Report\n\n',r.stage);
  fprintf(fid,'## ARS Material Passport\n\n');
  fprintf(fid,'- Experiment ID: `%s`\n',r.experiment_id);
  fprintf(fid,'- Type: `staged MATLAB numerical experiment`\n');
  fprintf(fid,'- Status: `%s`\n',r.status);
  fprintf(fid,'- Command: `tep_mc_scan(''%s'')`\n',r.stage);
  fprintf(fid,'- Outputs: stage-local CSV, MAT, Markdown, and log artifacts\n');
  fprintf(fid,'- Claim boundary: `%s`\n\n',r.claim_boundary);
  fprintf(fid,'- Stage-track pass: `%d`\n',r.pass);
  fprintf(fid,'- All gates pass: `%d`\n',r.all_gates_pass);
  fprintf(fid,'- Pass semantics: `%s`\n',r.pass_semantics);
  if isfield(r,'pass_with_conditions') && r.pass_with_conditions
    fprintf(fid,'- Verdict: `PASS WITH CONDITIONS`\n');
  elseif r.pass
    fprintf(fid,'- Verdict: `PASS`\n');
  else
    fprintf(fid,'- Verdict: `FAIL`\n');
  end
  fprintf(fid,'- First failure: `%s`\n',r.first_failure);
  fprintf(fid,'- Wall time: `%.6g s`\n',r.elapsed_seconds);
  fprintf(fid,'- Parent lineage token: `%s`\n',r.lineage.parent_token);
  fprintf(fid,'- Lineage token: `%s`\n',r.lineage.token);
  fprintf(fid,'- Config fingerprint: `%s`\n', ...
    r.lineage.config_fingerprint);
  fprintf(fid,'- Source hash: `%s`\n',r.lineage.source_hash);
  if isfield(r,'next_authorized')
    fprintf(fid,'- Next candidate stage authorized: `%d`\n',r.next_authorized);
    fprintf(fid,'- Candidate count: `%d`\n',numel(r.candidates));
    for j = 1:numel(r.candidates)
      fprintf(fid,'- Candidate %d metadata: `k=%.17g`, `k^2=%.17g`\n', ...
        j,r.candidates(j).k,r.candidates(j).k2_metadata);
    end
  end
  if isfield(r,'final_candidates')
    fprintf(fid,'- Final candidate count: `%d`\n',numel(r.final_candidates));
    for j = 1:numel(r.final_candidates)
      fprintf(fid,'- Final candidate %d metadata: `k=%.17g`, `k^2=%.17g`\n', ...
        j,r.final_candidates(j).k,r.final_candidates(j).k2_metadata);
    end
  end
  if strcmp(r.stage,'continuity')
    fprintf(fid,'- Derivative label: `%s`\n',r.derivative_label);
    fprintf(fid,'- Production derivative available: `%d`\n',r.derivative_available);
    fprintf(fid,'- Continuity ready: `%d`\n',r.continuity_ready);
    fprintf(fid,'- Empirical FD derivative ready: `%d`\n',r.fd_derivative_ready);
    fprintf(fid,'- Candidate screen authorized: `%d`\n', ...
      r.candidate_screen_authorized);
    fprintf(fid,'- FD half-steps used: `%s`\n',mat2str(r.fd_h_used,8));
    fprintf(fid,'- Locator/root isolation authorized: `%d/%d`\n', ...
      r.locator_authorized,r.root_isolation_authorized);
    fprintf(fid,['- Conditional verdict meaning: continuity and candidate ', ...
      'tracking pass; the retained FD graph-basis mutation gate fails, ', ...
      'so `fd_derivative_ready=0`.\n']);
  end
  fprintf(fid,'\n## Gates\n\n');
  fprintf(fid,'| Group | Gate | Status | Value | Tolerance |\n');
  fprintf(fid,'|---|---|---|---:|---:|\n');
  for j = 1:size(r.gates,1)
    fprintf(fid,'| %s | %s | %s | %.6g | %.6g |\n',r.gates{j,1}, ...
      r.gates{j,2},r.gates{j,3},r.gates{j,5},r.gates{j,6});
  end
  fprintf(fid,['\nThe stage-track verdict and every individual gate above are ', ...
    'reported separately. All conclusions are finite-dimensional and ', ...
    'empirical.\n']);
  clear cleanup;
end

function LOCAL_log(path,r)
  fid = fopen(path,'w'); cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'experiment_id=%s\nstage=%s\nstatus=%s\npass=%d\n', ...
    r.experiment_id,r.stage,r.status,r.pass);
  fprintf(fid,'first_failure=%s\nelapsed_seconds=%.17g\n', ...
    r.first_failure,r.elapsed_seconds);
  fprintf(fid,'all_gates_pass=%d\npass_with_conditions=%d\n', ...
    r.all_gates_pass,r.pass_with_conditions);
  fprintf(fid,'pass_semantics=%s\n',r.pass_semantics);
  fprintf(fid,'parent_lineage_token=%s\nlineage_token=%s\n', ...
    r.lineage.parent_token,r.lineage.token);
  fprintf(fid,'config_fingerprint=%s\nsource_hash=%s\n', ...
    r.lineage.config_fingerprint,r.lineage.source_hash);
  fprintf(fid,'claim_boundary=%s\n',r.claim_boundary);
  clear cleanup;
end
