function r = run_prod(kind)
%RUN_PROD Run the separation-free direct M=48 static I1.2 validation.
% Purpose:
%   Qualify the frozen-k one-cell, ordered-QZ, Cauchy graph, algebraic DtN,
%   and empty-center A-def chain at the actual M=48 trace bandwidth.
% Input:
%   kind - must be 'full'; the old M=12 pilot is non-authoritative history.
% Output:
%   r - result struct saved below output/prod-full/.
% Main algorithm:
%   Check direct coarse/fine cell maps, run independent original/reversed QZ
%   passes, compare stable subspaces, form weighted Cauchy charts, and verify
%   graph-to-DtN Schur equivalence without a Sylvester separation operator.
% Based on:
%   implementation/i1/design.md and the reviewed empirical I1.2 scope.
% Main changes:
%   Removes explicit and matrix-free production separation from the gate.
% Numerical goal:
%   Return I1_2_M48_PASS_WITH_CONDITIONS only when every frozen static gate
%   passes. No derivative, locator, root isolation, or estimator is present.

  if nargin < 1 || isempty(kind)
    kind = 'full';
  end
  if ~strcmp(kind,'full')
    error('run_prod:FullOnly', ...
      'Only full is authoritative; the old M=12 pilot is non-authoritative.');
  end
  if exist('OCTAVE_VERSION','builtin') ~= 0
    error('run_prod:MATLABRequired','The authoritative run requires MATLAB.');
  end

  cfg = prod_cfg();
  here = fileparts(mfilename('fullpath'));
  repo = fileparts(fileparts(fileparts(here)));
  addpath(repo);
  M = cfg.prod_M;
  K = 2*M+1;
  input_path = fullfile(here,'input','prod48.mat');
  output_dir = fullfile(here,'output','prod-full');
  if ~exist(output_dir,'dir')
    mkdir(output_dir);
  end

  t_all = tic;
  gates = cell(0,7);
  blocks = cell(0,8);
  qz_rows = cell(0,21);
  level_rows = cell(0,11);
  chart_rows = cell(0,9);
  adef_rows = cell(0,10);
  scope_rows = {
    'production_separation','NOT_EVALUATED_CAVEAT','IMPORTANT CAVEAT', ...
    'No dense or matrix-free Sylvester operator is formed or applied.';
    'locator_root','NOT_AUTHORIZED','BLOCKER', ...
    'Static I1.2 does not run a locator, contour, root isolation, or estimator.'};
  first_failure = '';
  data = struct();

  % --- stage 1: direct input and solver provenance ---
  [input_ok,input_note,data] = LOCAL_input(input_path,cfg,here,repo);
  input_value = NaN;
  if input_ok
    input_value = max(data.coarse.solve_residual,data.fine.solve_residual);
  end
  gates(end+1,:) = LOCAL_gate('input','direct_m48_maps', ...
    LOCAL_status(input_ok),input_ok,input_value,cfg.qz_tol,input_note);
  if ~input_ok
    first_failure = 'DIRECT_M48_INPUT_FAIL';
    r = LOCAL_finish('I1_2_M48_NOT_READY');
    return;
  end

  % --- stage 2: adjacent one-cell block and pencil stability ---
  [blocks,block_abs_ok,block_action_ok,max_abs,max_action] = ...
    LOCAL_blocks(data,cfg);
  gates(end+1,:) = LOCAL_gate('cell','block_coefficients', ...
    LOCAL_status(block_abs_ok),block_abs_ok,max_abs,cfg.coeff_tol, ...
    'maximum entrywise absolute coarse/fine block change');
  gates(end+1,:) = LOCAL_gate('cell','block_actions', ...
    LOCAL_status(block_action_ok),block_action_ok,max_action,cfg.self_tol, ...
    'weighted block operator/action change');
  if ~(block_abs_ok && block_action_ok)
    first_failure = 'DIRECT_M48_CELL_LEVEL_FAIL';
    r = LOCAL_finish('I1_2_M48_NOT_READY');
    return;
  end
  coarse = LOCAL_pair(data.coarse,M);
  fine = LOCAL_pair(data.fine,M);
  pair_change = LOCAL_pair_change(coarse.pair,fine.pair);
  pair_ok = pair_change <= cfg.self_tol;
  gates(end+1,:) = LOCAL_gate('cell','full_pencil_change', ...
    LOCAL_status(pair_ok),pair_ok,pair_change,cfg.self_tol, ...
    'normalized full generalized-pencil change');
  if ~pair_ok
    first_failure = 'DIRECT_M48_PENCIL_LEVEL_FAIL';
    r = LOCAL_finish('I1_2_M48_NOT_READY');
    return;
  end

  % --- stage 3: independent original/reversed projective QZ ---
  coarse.plus = LOCAL_qz(coarse.pair.A,coarse.pair.B,M,cfg, ...
    coarse.blocks,'plus','LEFT_CELL_WALL');
  coarse.minus = LOCAL_qz(coarse.pair.B,coarse.pair.A,M,cfg, ...
    coarse.blocks,'minus','RIGHT_CELL_WALL');
  fine.plus = LOCAL_qz(fine.pair.A,fine.pair.B,M,cfg, ...
    fine.blocks,'plus','LEFT_CELL_WALL');
  fine.minus = LOCAL_qz(fine.pair.B,fine.pair.A,M,cfg, ...
    fine.blocks,'minus','RIGHT_CELL_WALL');
  qz_rows = LOCAL_qz_rows(M,coarse,fine);
  qz_ok = coarse.plus.pass && coarse.minus.pass && ...
    fine.plus.pass && fine.minus.pass;
  qz_max = max([coarse.plus.raw_residual,coarse.plus.residual, ...
    coarse.minus.raw_residual,coarse.minus.residual, ...
    fine.plus.raw_residual,fine.plus.residual, ...
    fine.minus.raw_residual,fine.minus.residual]);
  gates(end+1,:) = LOCAL_gate('qz','direction_count_residual', ...
    LOCAL_status(qz_ok),qz_ok,qz_max,cfg.qz_tol, ...
    'original/reversed counts, reference planes, and QZ residuals');
  if ~qz_ok
    first_failure = 'DIRECT_M48_QZ_FAIL';
    r = LOCAL_finish('I1_2_M48_NOT_READY');
    return;
  end

  % --- stage 4: coarse/fine amplitude and Cauchy subspaces ---
  proj_plus = LOCAL_projector(coarse.plus.Z,fine.plus.Z);
  proj_minus = LOCAL_projector(coarse.minus.Z,fine.minus.Z);
  [coarse.Dp,coarse.Np,coarse.Dm,coarse.Nm] = LOCAL_cauchy(coarse);
  [fine.Dp,fine.Np,fine.Dm,fine.Nm] = LOCAL_cauchy(fine);
  graph_plus = LOCAL_graph_change(coarse.Dp,coarse.Np, ...
    fine.Dp,fine.Np,fine.beta_m);
  graph_minus = LOCAL_graph_change(coarse.Dm,coarse.Nm, ...
    fine.Dm,fine.Nm,fine.beta_m);
  projector_ok = max([proj_plus,proj_minus,graph_plus,graph_minus]) <= ...
    cfg.projector_tol;
  gates(end+1,:) = LOCAL_gate('graph','coarse_fine_projectors', ...
    LOCAL_status(projector_ok),projector_ok, ...
    max([proj_plus,proj_minus,graph_plus,graph_minus]), ...
    cfg.projector_tol,'amplitude and weighted Cauchy graph projectors');
  level_rows(end+1,:) = {M,pair_change,proj_plus,proj_minus, ...
    graph_plus,graph_minus,NaN,NaN,NaN,NaN,projector_ok};
  if ~projector_ok
    first_failure = 'DIRECT_M48_SUBSPACE_LEVEL_FAIL';
    r = LOCAL_finish('I1_2_M48_NOT_READY');
    return;
  end

  % --- stage 5: algebraic Dirichlet charts and DtN actions ---
  coarse.cp = LOCAL_chart(coarse.Dp,coarse.Np,coarse.beta_m,cfg);
  coarse.cm = LOCAL_chart(coarse.Dm,coarse.Nm,coarse.beta_m,cfg);
  fine.cp = LOCAL_chart(fine.Dp,fine.Np,fine.beta_m,cfg);
  fine.cm = LOCAL_chart(fine.Dm,fine.Nm,fine.beta_m,cfg);
  chart_rows = LOCAL_chart_rows(M,coarse,fine);
  chart_ok = coarse.cp.safe && coarse.cm.safe && fine.cp.safe && fine.cm.safe;
  gates(end+1,:) = LOCAL_gate('chart','algebraic_dirichlet', ...
    LOCAL_status(chart_ok),chart_ok,double(chart_ok),1, ...
    'weighted margin, condition, and right-solve residual; no sep claim');
  if ~chart_ok
    first_failure = 'DIRECT_M48_DIRICHLET_CHART_FAIL';
    r = LOCAL_finish('I1_2_M48_GRAPH_ONLY_CONDITIONAL');
    return;
  end
  dtn_plus = LOCAL_rel(coarse.cp.Lambda,fine.cp.Lambda);
  dtn_minus = LOCAL_rel(coarse.cm.Lambda,fine.cm.Lambda);
  dtn_ok = max(dtn_plus,dtn_minus) <= cfg.self_tol;
  gates(end+1,:) = LOCAL_gate('dtn','coarse_fine_actions', ...
    LOCAL_status(dtn_ok),dtn_ok,max(dtn_plus,dtn_minus),cfg.self_tol, ...
    'basis-invariant coarse/fine DtN action change');
  level_rows{1,7} = dtn_plus;
  level_rows{1,8} = dtn_minus;
  if ~dtn_ok
    first_failure = 'DIRECT_M48_DTN_LEVEL_FAIL';
    r = LOCAL_finish('I1_2_M48_NOT_READY');
    return;
  end

  % --- stage 6: empty-center graph/DtN A-def equivalence ---
  [adef_c,metric_c] = LOCAL_adef(coarse,M);
  [adef_f,metric_f] = LOCAL_adef(fine,M);
  schur_tol = 1e3*K*eps;
  adef_change = LOCAL_rel(adef_c.D,adef_f.D);
  finite_ok = all(isfinite(adef_c.D(:))) && all(isfinite(adef_c.G(:))) && ...
    all(isfinite(adef_f.D(:))) && all(isfinite(adef_f.G(:)));
  dims_ok = isequal(size(adef_c.D),[2*K,2*K]) && ...
    isequal(size(adef_f.D),[2*K,2*K]) && ...
    isequal(size(adef_c.G),[4*K,4*K]) && ...
    isequal(size(adef_f.G),[4*K,4*K]);
  adef_ok = dims_ok && finite_ok && ...
    max(metric_c.schur,metric_f.schur) <= schur_tol && ...
    adef_change <= cfg.self_tol;
  adef_rows = {
    M,'coarse',size(adef_c.D,1),size(adef_c.G,1),metric_c.schur, ...
    schur_tol,metric_c.smin,metric_c.cond,finite_ok, ...
    metric_c.schur <= schur_tol;
    M,'fine',size(adef_f.D,1),size(adef_f.G,1),metric_f.schur, ...
    schur_tol,metric_f.smin,metric_f.cond,finite_ok, ...
    metric_f.schur <= schur_tol};
  schur_ok = dims_ok && finite_ok && ...
    max(metric_c.schur,metric_f.schur) <= schur_tol;
  adef_action_ok = adef_change <= cfg.self_tol;
  gates(end+1,:) = LOCAL_gate('adef','graph_dtn_schur', ...
    LOCAL_status(schur_ok),schur_ok,max(metric_c.schur,metric_f.schur), ...
    schur_tol,'194/388 dimensions, finite entries, and Schur identity');
  gates(end+1,:) = LOCAL_gate('adef','coarse_fine_action', ...
    LOCAL_status(adef_action_ok),adef_action_ok,adef_change,cfg.self_tol, ...
    'basis-invariant safe-DtN A-def action change');
  level_rows{1,9} = adef_change;
  level_rows{1,10} = max(metric_c.schur,metric_f.schur);
  level_rows{1,11} = adef_ok;
  if ~adef_ok
    first_failure = 'DIRECT_M48_ADEF_FAIL';
    r = LOCAL_finish('I1_2_M48_NOT_READY');
    return;
  end

  r = LOCAL_finish('I1_2_M48_PASS_WITH_CONDITIONS');

  %% ==================== Artifact closure ====================
  % This nested helper preserves every partial ledger on fail-closed exits.
  function result = LOCAL_finish(status)
    elapsed = toc(t_all);
    empirical_ready = strcmp(status,'I1_2_M48_PASS_WITH_CONDITIONS');
    timing_rows = {
      'coarse_map',LOCAL_field(data,'coarse','seconds'), ...
      'recorded by make_prod';
      'fine_map',LOCAL_field(data,'fine','seconds'), ...
      'recorded by make_prod';
      'map_total',LOCAL_field(data,'','total_seconds'), ...
      'complete make_prod wall time';
      'static_validation',elapsed,'run_prod wall time'};
    result = struct('status',status,'first_failure',first_failure, ...
      'M',M,'K',K,'elapsed_seconds',elapsed, ...
      'i1_2_empirical_ready',empirical_ready, ...
      'production_separation','NOT_EVALUATED_CAVEAT', ...
      'theorem_conditioning_claim',false, ...
      'locator_authorized',false,'root_isolation_authorized',false, ...
      'gates',{gates},'blocks',{blocks},'qz_rows',{qz_rows}, ...
      'level_rows',{level_rows},'chart_rows',{chart_rows}, ...
      'adef_rows',{adef_rows},'scope_rows',{scope_rows}, ...
      'timing_rows',{timing_rows},'config',cfg,'input_path',input_path);
    LOCAL_csv(fullfile(output_dir,'gates.csv'), ...
      {'group','gate','status','pass','value','tolerance','note'},gates);
    LOCAL_csv(fullfile(output_dir,'blocks.csv'), ...
      {'block','abs_max','floor_relative','weighted_action', ...
      'abs_tolerance','action_tolerance','floor','pass'},blocks);
    LOCAL_csv(fullfile(output_dir,'qz.csv'), ...
      {'M','level','side','plane','stable','unstable','neutral','infinite', ...
      'indeterminate','unit_gap','tau_proj','raw_residual','residual', ...
      'ref_available','ref_rcond_D','ref_rcond_F','ref_residual', ...
      'count_pass','residual_pass','reference_pass','pass'},qz_rows);
    LOCAL_csv(fullfile(output_dir,'levels.csv'), ...
      {'M','pair_change','projector_plus','projector_minus', ...
      'cauchy_plus','cauchy_minus','dtn_plus','dtn_minus', ...
      'adef_change','schur_max','pass'},level_rows);
    LOCAL_csv(fullfile(output_dir,'chart.csv'), ...
      {'M','level','side','margin','condition','condition_eps', ...
      'solve_residual','safe','claim'},chart_rows);
    LOCAL_csv(fullfile(output_dir,'adef.csv'), ...
      {'M','level','dtn_rows','graph_rows','schur_error','schur_tolerance', ...
      'smin_metadata','condition_metadata','finite','pass'},adef_rows);
    LOCAL_csv(fullfile(output_dir,'scope.csv'), ...
      {'object','status','category','note'},scope_rows);
    LOCAL_csv(fullfile(output_dir,'timing.csv'), ...
      {'stage','seconds','note'},timing_rows);
    save(fullfile(output_dir,'result.mat'),'result','-v7.3');
    LOCAL_report(fullfile(output_dir,'report.md'),result);
    LOCAL_log(fullfile(output_dir,'run.log'),result);
    fprintf('RUN_PROD_STATUS=%s M=%d seconds=%.6g\n',status,M,elapsed);
  end
end

%% ==================== Input and cell maps ====================
% These helpers validate immutable direct-map inputs and adjacent levels.

function [ok,note,data] = LOCAL_input(path,cfg,here,repo)
  data = struct();
  if ~isfile(path)
    ok = false; note = 'input/prod48.mat is absent'; return;
  end
  loaded = load(path,'data');
  if ~isfield(loaded,'data') || ~isstruct(loaded.data)
    ok = false; note = 'missing data struct'; return;
  end
  data = loaded.data;
  required = {'schema','kind','physical','wall_labels','coarse','fine','provenance'};
  if ~all(isfield(data,required)) || ...
      ~strcmp(data.schema,'HG_ADEF_PROD_V1') || ~strcmp(data.kind,'full')
    ok = false; note = 'schema or kind mismatch'; return;
  end
  p = data.physical;
  values = [p.k-cfg.k,p.beta-cfg.beta,p.d-cfg.d,p.R-cfg.R, ...
    p.X_L-cfg.X_L,p.X_R-cfg.X_R,p.s-cfg.s, ...
    p.proxy_dist-cfg.proxy_dist,p.H-cfg.H,p.M-cfg.prod_M,p.K-(2*cfg.prod_M+1)];
  physical_ok = max(abs(values)) <= 1e3*eps;
  labels_ok = isequal(data.wall_labels,{'LEFT_CELL_WALL','RIGHT_CELL_WALL'});
  [coarse_ok,coarse_note] = LOCAL_level_ok(data.coarse,cfg.coarse,cfg);
  [fine_ok,fine_note] = LOCAL_level_ok(data.fine,cfg.fine,cfg);
  provenance_ok = LOCAL_provenance(data.provenance,here,repo);
  ok = physical_ok && labels_ok && coarse_ok && fine_ok && provenance_ok;
  if ok
    note = 'direct M48 MATLAB lsqminnorm maps and source hashes verified';
  elseif ~coarse_ok
    note = ['coarse level: ',coarse_note];
  elseif ~fine_ok
    note = ['fine level: ',fine_note];
  elseif ~provenance_ok
    note = 'solver, Git, source hash, or zero-fallback provenance mismatch';
  else
    note = 'physical parameters or wall labels mismatch';
  end
end

function [ok,note] = LOCAL_level_ok(level,spec,cfg)
  required = {'spec','proxy','modes','blocks','wall_labels','solve_residual','seconds'};
  if ~isstruct(level) || ~all(isfield(level,required))
    ok = false; note = 'missing level fields'; return;
  end
  K = 2*cfg.prod_M+1;
  names = {'R_L','T_RL','T_LR','R_R'};
  dims_ok = true;
  for j = 1:numel(names)
    dims_ok = dims_ok && isfield(level.blocks,names{j}) && ...
      isequal(size(level.blocks.(names{j})),[K,K]);
  end
  dims_ok = dims_ok && isfield(level.blocks,'A_sc') && ...
    isfield(level.blocks,'B_sc') && ...
    isequal(size(level.blocks.A_sc),[2*K,2*K]) && ...
    isequal(size(level.blocks.B_sc),[2*K,2*K]);
  A = [-level.blocks.R_L,eye(K);level.blocks.T_LR,zeros(K)];
  B = [zeros(K),level.blocks.T_RL;eye(K),-level.blocks.R_R];
  formula_ok = norm(level.blocks.A_sc-A,'fro') <= 1e3*K*eps && ...
    norm(level.blocks.B_sc-B,'fro') <= 1e3*K*eps;
  proxy_ok = level.spec.ntot == spec.ntot && ...
    level.proxy.N_side == spec.N_side && level.proxy.N_top == spec.N_top && ...
    level.proxy.N_proxy_edge == spec.N_proxy_edge && ...
    level.proxy.M_pw == spec.M_pw && ...
    abs(level.proxy.proxy_dist-cfg.proxy_dist) <= 1e3*eps && ...
    abs(level.proxy.H-cfg.H) <= 1e3*eps;
  modes_ok = level.modes.M == cfg.prod_M && level.modes.K == K && ...
    isequal(level.modes.m(:),(-cfg.prod_M:cfg.prod_M).');
  residual_ok = isfinite(level.solve_residual) && ...
    level.solve_residual <= cfg.qz_tol;
  ok = dims_ok && formula_ok && proxy_ok && modes_ok && residual_ok && ...
    isequal(level.wall_labels,{'LEFT_CELL_WALL','RIGHT_CELL_WALL'});
  if ok, note = 'PASS'; else, note = 'dimension/formula/proxy/mode/residual mismatch'; end
end

function ok = LOCAL_provenance(p,here,repo)
  required = {'runtime','version','solver','solver_path','git_sha', ...
    'source_paths','source_hashes','fallbacks','silent_rank_changes','generated_utc'};
  if ~isstruct(p) || ~all(isfield(p,required))
    ok = false; return;
  end
  [status,git_sha] = system(sprintf('git -C "%s" rev-parse HEAD',repo));
  ok = status == 0 && strcmp(p.runtime,'MATLAB') && ...
    strcmp(p.solver,'lsqminnorm') && ~isempty(p.solver_path) && ...
    p.fallbacks == 0 && p.silent_rank_changes == 0 && ...
    strcmp(p.git_sha,strtrim(git_sha));
  names = {'make_prod','prod_cfg','run_prod','precomp_proxy','construct_S'};
  ok = ok && isstruct(p.source_paths) && isstruct(p.source_hashes) && ...
    all(isfield(p.source_paths,names)) && all(isfield(p.source_hashes,names));
  if ~ok, return; end
  expected = struct('make_prod',fullfile(here,'make_prod.m'), ...
    'prod_cfg',fullfile(here,'prod_cfg.m'), ...
    'run_prod',fullfile(here,'run_prod.m'), ...
    'precomp_proxy',which('kernel.precomp_proxy'), ...
    'construct_S',which('bloch.construct_S'));
  for j = 1:numel(names)
    ok = ok && strcmp(p.source_paths.(names{j}),expected.(names{j})) && ...
      strcmp(p.source_hashes.(names{j}),LOCAL_hash(expected.(names{j})));
  end
end

function [rows,abs_ok,action_ok,max_abs,max_action] = LOCAL_blocks(data,cfg)
  rows = cell(0,8); abs_ok = true; action_ok = true;
  max_abs = 0; max_action = 0;
  beta_m = data.fine.modes.beta_m(:);
  W = diag((1+abs(beta_m).^2).^(1/4));
  names = {'R_L','T_RL','T_LR','R_R'};
  for j = 1:numel(names)
    A = data.coarse.blocks.(names{j});
    B = data.fine.blocks.(names{j});
    delta = abs(A-B);
    abs_value = max(delta(:));
    denominator = max(max(abs(A),abs(B)),cfg.rel_floor);
    rel_value = max(delta(:)./denominator(:));
    Aw = LOCAL_right(W*A,W);
    Bw = LOCAL_right(W*B,W);
    action = norm(Aw-Bw,2)/max(1,norm(Bw,2));
    pass = abs_value <= cfg.coeff_tol && action <= cfg.self_tol;
    rows(end+1,:) = {names{j},abs_value,rel_value,action, ...
      cfg.coeff_tol,cfg.self_tol,cfg.rel_floor,pass};
    max_abs = max(max_abs,abs_value); max_action = max(max_action,action);
    abs_ok = abs_ok && abs_value <= cfg.coeff_tol;
    action_ok = action_ok && action <= cfg.self_tol;
  end
end

function level = LOCAL_pair(input,M)
  K = 2*M+1;
  level.blocks = input.blocks;
  level.pair.A = [-input.blocks.R_L,eye(K);input.blocks.T_LR,zeros(K)];
  level.pair.B = [zeros(K),input.blocks.T_RL;eye(K),-input.blocks.R_R];
  level.gamma = input.modes.gamma_m(:);
  level.beta_m = input.modes.beta_m(:);
  level.phase = input.modes.phase(:);
end

%% ==================== Ordered QZ and Cauchy graphs ====================
% These helpers check direction, counts, residuals, and adjacent subspaces.

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
    'count_pass',false,'residual_pass',false,'reference_pass',false,'pass',false);
  q.count_pass = q.stable_count == K && q.unstable_count == K && ...
    q.neutral_count == 0 && q.indeterminate_count == 0;
  if ~q.count_pass, return; end
  [Uo,Vo,Qo,Zo] = ordqz(U,V,Q,Z,stable);
  Qleft = Qo'; Zs = Zo(:,1:K); Qs = Qleft(:,1:K);
  q.residual = max([norm(A-Qleft*Uo*Zo','fro'), ...
    norm(B-Qleft*Vo*Zo','fro'), ...
    norm(A*Zs-Qs*Uo(1:K,1:K),'fro'), ...
    norm(B*Zs-Qs*Vo(1:K,1:K),'fro')]);
  q.Z = Zs;
  [q.ref_available,q.ref_rcond_D,q.ref_rcond_F,q.ref_residual] = ...
    LOCAL_reference(S,Zs,side);
  q.residual_pass = raw <= cfg.qz_tol && q.residual <= cfg.qz_tol;
  q.reference_pass = ~q.ref_available || q.ref_residual <= cfg.qz_tol;
  q.pass = q.count_pass && q.residual_pass && q.reference_pass;
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

function rows = LOCAL_qz_rows(M,coarse,fine)
  rows = cell(0,21); levels = {'coarse','fine'}; sides = {'plus','minus'};
  objects = {coarse,fine};
  for j = 1:2
    for s = 1:2
      q = objects{j}.(sides{s});
      rows(end+1,:) = {M,levels{j},sides{s},q.plane,q.stable_count, ...
        q.unstable_count,q.neutral_count,q.infinite_count, ...
        q.indeterminate_count,q.unit_gap,q.tau_proj,q.raw_residual, ...
        q.residual,q.ref_available,q.ref_rcond_D,q.ref_rcond_F, ...
        q.ref_residual,q.count_pass,q.residual_pass,q.reference_pass,q.pass};
    end
  end
end

function [Dp,Np,Dm,Nm] = LOCAL_cauchy(level)
  K = numel(level.gamma); Gamma = diag(level.gamma);
  Ap = level.plus.Z(1:K,:); Bp = level.plus.Z(K+1:end,:);
  Am = level.minus.Z(1:K,:); Bm = level.minus.Z(K+1:end,:);
  Dp = Ap+Bp; Np = 1i*Gamma*(Ap-Bp);
  Dm = Am+Bm; Nm = -1i*Gamma*(Am-Bm);
end

function value = LOCAL_graph_change(D1,N1,D2,N2,beta_m)
  b = sqrt(1+abs(beta_m(:)).^2);
  C1 = [diag(sqrt(b))*D1;diag(1./sqrt(b))*N1];
  C2 = [diag(sqrt(b))*D2;diag(1./sqrt(b))*N2];
  [Q1,~] = qr(C1,0); [Q2,~] = qr(C2,0);
  value = LOCAL_projector(Q1,Q2);
end

%% ==================== Algebraic charts and A-def ====================
% These helpers form only algebraically safe charts and empty-center matrices.

function c = LOCAL_chart(D,N,beta_m,cfg)
  K = size(D,1); b = sqrt(1+abs(beta_m(:)).^2);
  GDh = diag(sqrt(b)); GD = diag(b); GN = diag(1./b);
  gram = (D'*GD*D+N'*GN*N);
  gram = (gram+gram')/2;
  [V,L] = eig(gram); values = max(real(diag(L)),0);
  c = struct('margin',0,'condition',Inf,'condition_eps',Inf, ...
    'solve_residual',NaN,'safe',false,'Lambda',[]);
  if min(values) <= 0, return; end
  half = V*diag(sqrt(values))*V';
  Dbar = (half.'\(GDh*D).').';
  singular = svd(Dbar);
  c.margin = min(singular); c.condition = max(singular)/c.margin;
  c.condition_eps = c.condition*eps;
  c.safe = c.margin > 100*K*eps && c.condition_eps <= cfg.chart_tol;
  if c.safe
    c.Lambda = LOCAL_right(N,D);
    c.solve_residual = LOCAL_rel(N,c.Lambda*D);
    c.safe = c.solve_residual <= 1e3*K*eps;
    if ~c.safe, c.Lambda = []; end
  end
end

function rows = LOCAL_chart_rows(M,coarse,fine)
  rows = cell(0,9); levels = {'coarse','fine'}; sides = {'plus','minus'};
  objects = {coarse,fine}; charts = {'cp','cm'};
  for j = 1:2
    for s = 1:2
      c = objects{j}.(charts{s});
      rows(end+1,:) = {M,levels{j},sides{s},c.margin,c.condition, ...
        c.condition_eps,c.solve_residual,c.safe,'ALGEBRAIC_NOT_SEP_CERTIFIED'};
    end
  end
end

function [out,metric] = LOCAL_adef(level,M)
  K = 2*M+1; Gamma = diag(level.gamma); E = diag(level.phase);
  Lp = level.cp.Lambda; Lm = level.cm.Lambda;
  D = [-(1i*Gamma+Lm),(1i*Gamma-Lm)*E; ...
    (1i*Gamma-Lp)*E,-(1i*Gamma+Lp)];
  Z = zeros(K); I = eye(K);
  G = [I,E,-level.Dm,Z;-1i*Gamma,1i*Gamma*E,-level.Nm,Z; ...
    E,I,Z,-level.Dp;1i*Gamma*E,-1i*Gamma,Z,-level.Np];
  drow = [1:K,2*K+1:3*K]; nrow = [K+1:2*K,3*K+1:4*K];
  qcol = 1:2*K; ccol = 2*K+1:4*K;
  schur = G(nrow,qcol)-G(nrow,ccol)*(G(drow,ccol)\G(drow,qcol));
  singular = svd(D,'econ');
  metric.schur = LOCAL_rel(D,schur);
  metric.smin = min(singular);
  metric.cond = max(singular)/max(metric.smin,realmin);
  out = struct('D',D,'G',G);
end

%% ==================== Metrics and artifacts ====================
% These helpers provide basis-invariant metrics and compact durable outputs.

function value = LOCAL_pair_change(a,b)
  value = hypot(norm(a.A-b.A,'fro'),norm(a.B-b.B,'fro')) / ...
    max(realmin,hypot(norm(b.A,'fro'),norm(b.B,'fro')));
end

function value = LOCAL_projector(A,B)
  value = norm(A*A'-B*B','fro')/max(1,norm(B*B','fro'));
end

function X = LOCAL_right(N,D)
  X = (D.'\N.').';
end

function value = LOCAL_rel(A,B)
  value = norm(A-B,'fro')/max(1,norm(A,'fro'));
end

function row = LOCAL_gate(group,name,status,pass,value,tolerance,note)
  row = {group,name,status,logical(pass),value,tolerance,note};
end

function status = LOCAL_status(pass)
  if pass, status = 'PASS'; else, status = 'FAIL'; end
end

function value = LOCAL_field(data,level,name)
  value = NaN;
  if isempty(level) && isstruct(data) && isfield(data,name)
    value = data.(name);
  elseif isstruct(data) && isfield(data,level) && isfield(data.(level),name)
    value = data.(level).(name);
  end
end

function value = LOCAL_hash(path)
  fid = fopen(path,'r');
  if fid < 0, value = 'UNAVAILABLE'; return; end
  cleanup = onCleanup(@() fclose(fid));
  bytes = fread(fid,Inf,'*uint8');
  digest = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
  digest.update(typecast(bytes(:),'int8'));
  raw = typecast(digest.digest(),'uint8');
  value = lower(reshape(dec2hex(raw,2).',1,[]));
  clear cleanup;
end

function LOCAL_csv(path,headers,rows)
  fid = fopen(path,'w');
  if fid < 0, error('run_prod:Artifact','Cannot open %s.',path); end
  cleanup = onCleanup(@() fclose(fid));
  LOCAL_csv_row(fid,headers);
  for j = 1:size(rows,1), LOCAL_csv_row(fid,rows(j,:)); end
  clear cleanup;
end

function LOCAL_csv_row(fid,row)
  text = cell(1,numel(row));
  for j = 1:numel(row)
    v = row{j};
    if islogical(v)
      s = sprintf('%d',v);
    elseif isnumeric(v)
      s = sprintf('%.17g',v);
    else
      s = char(v);
    end
    text{j} = ['"',strrep(s,'"','""'),'"'];
  end
  fprintf(fid,'%s\n',strjoin(text,','));
end

function LOCAL_report(path,r)
  fid = fopen(path,'w'); cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'# M48 static half-guide to A-def report\n\n');
  fprintf(fid,'- Status: `%s`\n',r.status);
  fprintf(fid,'- M/K: `%d/%d`\n',r.M,r.K);
  fprintf(fid,'- Static validation time: `%.6g s`\n',r.elapsed_seconds);
  fprintf(fid,'- First failure: `%s`\n',r.first_failure);
  fprintf(fid,'- I1.2 empirical ready: `%d`\n',r.i1_2_empirical_ready);
  fprintf(fid,'- Production separation: `%s`\n',r.production_separation);
  fprintf(fid,'- Theorem conditioning claim: `%d`\n',r.theorem_conditioning_claim);
  fprintf(fid,'- Locator/root isolation authorized: `%d/%d`\n\n', ...
    r.locator_authorized,r.root_isolation_authorized);
  fprintf(fid,'## Gates\n\n');
  fprintf(fid,'| Group | Gate | Status | Value | Tolerance |\n');
  fprintf(fid,'|---|---|---|---:|---:|\n');
  for j = 1:size(r.gates,1)
    fprintf(fid,'| %s | %s | %s | %.6g | %.6g |\n',r.gates{j,1}, ...
      r.gates{j,2},r.gates{j,3},r.gates{j,5},r.gates{j,6});
  end
  fprintf(fid,'\nThe chart verdict is algebraic, not separation-certified. ');
  fprintf(fid,'No Sylvester/Kronecker separation operator was formed or applied.\n\n');
  fprintf(fid,'Single-point A-def singular values are metadata only and are not root evidence.\n');
  clear cleanup;
end

function LOCAL_log(path,r)
  fid = fopen(path,'w'); cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'status=%s\nM=%d\nK=%d\nelapsed=%.17g\n', ...
    r.status,r.M,r.K,r.elapsed_seconds);
  fprintf(fid,'first_failure=%s\nproduction_separation=%s\n', ...
    r.first_failure,r.production_separation);
  fprintf(fid,'locator_authorized=%d\nroot_isolation_authorized=%d\n', ...
    r.locator_authorized,r.root_isolation_authorized);
  clear cleanup;
end
