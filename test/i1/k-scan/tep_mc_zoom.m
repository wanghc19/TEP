function result = tep_mc_zoom(stage)
%TEP_MC_ZOOM Run the frozen M=48 nested dyadic grid experiment.
% Purpose:
%   Refine the confirmed real-axis grid candidate without modifying or
%   overwriting the parent I1-K-SCAN-V1 implementation and artifacts.
% Input:
%   stage - 'pilot' validates lineage and recomputes the pivot seed; 'full'
%   runs at most eleven nested levels and stops immediately on any failure.
% Output:
%   result - compact stage result written below output/zoom[-pilot]/.
% Main algorithm:
%   Verify the parent lineage, freeze one M=48 frame at k=1.8375, cache unique
%   coarse/fine points, and update only through strict five-point grid minima.
% Based on:
%   test/i1/k-scan/tep_mc_scan.m and its confirm48 artifacts.
% Main changes:
%   Adds a bounded nested grid; no fit, interpolation, derivative, or locator.
% Numerical goal:
%   Record a discrete M=48 near-zero grid candidate under unchanged gates.

  if nargin < 1 || isempty(stage), stage = 'pilot'; end
  if exist('OCTAVE_VERSION','builtin') ~= 0
    error('tep_mc_zoom:MATLABRequired','MATLAB is required.');
  end
  if isempty(which('lsqminnorm'))
    error('tep_mc_zoom:LsqminnormRequired','MATLAB lsqminnorm is required.');
  end
  here = fileparts(mfilename('fullpath'));
  repo = fileparts(fileparts(fileparts(here)));
  addpath(repo);
  cfg = zoom_cfg();
  provenance = LOCAL_provenance(here,repo);
  [parent,parent_note] = LOCAL_parent(here,cfg,provenance);
  stage = lower(char(stage));
  if strcmp(stage,'pilot')
    result = LOCAL_pilot(cfg,here,parent,parent_note,provenance);
  elseif strcmp(stage,'full')
    LOCAL_pilot_prerequisite(here,cfg,provenance,parent);
    result = LOCAL_full(cfg,here,parent,parent_note,provenance);
  else
    error('tep_mc_zoom:Stage','Unknown stage %s.',stage);
  end
end

function LOCAL_pilot_prerequisite(here,cfg,p,parent)
  path = fullfile(here,'output','zoom-pilot','result.mat');
  if ~isfile(path), error('tep_mc_zoom:Pilot','Missing zoom pilot result.'); end
  loaded = load(path,'result'); prior = loaded.result;
  fields = {'schema','experiment_id','stage','status','pass', ...
    'all_gates_pass','lineage','parent_lineage_token'};
  if ~all(isfield(prior,fields))
    error('tep_mc_zoom:Pilot','Zoom pilot fields missing.');
  end
  expected = LOCAL_lineage('zoom-pilot',prior.status, ...
    parent.lineage.token,p,cfg);
  ok = strcmp(prior.schema,cfg.zoom_schema) && ...
    strcmp(prior.experiment_id,cfg.zoom_experiment_id) && ...
    strcmp(prior.stage,'zoom-pilot') && strcmp(prior.status,'ZOOM_PILOT_PASS') && ...
    prior.pass && prior.all_gates_pass && ...
    strcmp(prior.parent_lineage_token,parent.lineage.token) && ...
    strcmp(prior.lineage.token,expected.token);
  if ~ok
    error('tep_mc_zoom:Pilot','Zoom pilot schema, source, or lineage failed.');
  end
end

%% ==================== Stage drivers ====================
% These helpers execute the pilot and fail-closed nested grid.

function result = LOCAL_pilot(cfg,here,parent,parent_note,provenance)
  output_dir = fullfile(here,'output','zoom-pilot'); LOCAL_mkdir(output_dir);
  timer = tic;
  [seed,frame] = zoom_core('seed',cfg);
  reference = LOCAL_parent_score(here,cfg.pivot_seed_k);
  match = LOCAL_score_match(seed,reference,cfg.score_match_tol);
  pass = seed.pass && match.pass;
  gates = [LOCAL_gate(0,'parent_lineage',true,1,1,parent_note); ...
    LOCAL_gate(0,'pivot_seed_scientific',seed.pass,double(seed.pass),1, ...
    'recomputed M48 coarse/fine pivot with one shared row selector'); ...
    LOCAL_gate(0,'parent_score_roundoff',match.pass,match.value, ...
    cfg.score_match_tol,'recomputed pivot score versus parent scores.csv')];
  if pass, status = 'ZOOM_PILOT_PASS'; else, status = 'ZOOM_PILOT_FAIL'; end
  lineage = LOCAL_lineage('zoom-pilot',status,parent.lineage.token, ...
    provenance,cfg);
  point_rows = LOCAL_point_rows(seed,0);
  score_rows = LOCAL_score_rows(seed,0);
  result = LOCAL_result(cfg,'zoom-pilot',status,pass,toc(timer),gates, ...
    point_rows,score_rows,LOCAL_level_rows(seed,0),LOCAL_qz_rows(seed,0), ...
    LOCAL_chart_rows(seed,0),cell(0,9),cell(0,18),provenance,lineage, ...
    parent,struct([]),frame,match,'PIVOT_RECOMPUTATION_ONLY');
  LOCAL_write(output_dir,result);
  fprintf('TEP_MC_ZOOM_STAGE=pilot STATUS=%s seconds=%.6g\n', ...
    status,result.elapsed_seconds);
end

function result = LOCAL_full(cfg,here,parent,parent_note,provenance)
  output_dir = fullfile(here,'output','zoom'); LOCAL_mkdir(output_dir);
  timer = tic;
  [seed,frame] = zoom_core('seed',cfg);
  cache = seed;
  bracket = cfg.initial_bracket;
  gates = LOCAL_gate(0,'parent_lineage',true,1,1,parent_note);
  point_rows = cell(0,10); score_rows = cell(0,15); level_rows = cell(0,17);
  qz_rows = cell(0,17); chart_rows = cell(0,13); transport_rows = cell(0,9);
  layer_rows = cell(0,18); q_history = [];
  consecutive = 0; status = 'ZOOM_MAX_LEVEL_FAIL'; pass = false;
  stop_code = 'MAX_LEVEL_WITHOUT_TWO_NEAR_ZERO_LEVELS'; final_node = struct([]);
  parent_match = struct('pass',true,'value',0);

  % --- stage 1: recompute the parent bracket under the frozen seed frame ---
  for j = 1:numel(bracket)
    if toc(timer) >= cfg.hard_seconds
      status = 'ZOOM_HARD_TIME_FAIL'; stop_code = 'HARD_TIME_LIMIT';
      result = LOCAL_finish_full(); return;
    end
    [cache,node] = LOCAL_cached(cache,bracket(j),cfg,frame,timer);
    [point_rows,score_rows,level_rows,qz_rows,chart_rows] = ...
      LOCAL_append_ledgers(point_rows,score_rows,level_rows,qz_rows, ...
      chart_rows,node,0);
    if ~node.pass
      gates(end+1,:) = LOCAL_gate(0,'initial_point_scientific',false,0,1, ...
        'initial bracket point failed unchanged scientific gates');
      status = 'ZOOM_SCIENTIFIC_GATE_FAIL'; stop_code = 'POINT_SCIENTIFIC_GATE';
      result = LOCAL_finish_full(); return;
    end
  end
  parent_match = LOCAL_bracket_match(cache,here,cfg);
  gates(end+1,:) = LOCAL_gate(0,'parent_bracket_roundoff', ...
    parent_match.pass,parent_match.value,cfg.score_match_tol, ...
    'initial bracket recomputed with the parent pivot frame');
  if ~parent_match.pass
    status = 'ZOOM_PARENT_BRACKET_MISMATCH_FAIL';
    stop_code = 'PARENT_BRACKET_SCORE_MISMATCH';
    result = LOCAL_finish_full(); return;
  end

  % --- stage 2: dyadic five-point levels ---
  for layer = 1:cfg.max_levels
    if toc(timer) >= cfg.hard_seconds
      status = 'ZOOM_HARD_TIME_FAIL'; stop_code = 'HARD_TIME_LIMIT'; break;
    end
    h = (bracket(3)-bracket(1))/2;
    center = bracket(2);
    kvals = center+[-h,-h/2,0,h/2,h];
    for j = [2,4]
      if toc(timer) >= cfg.hard_seconds
        status = 'ZOOM_HARD_TIME_FAIL'; stop_code = 'HARD_TIME_LIMIT';
        result = LOCAL_finish_full(); return;
      end
      [cache,node] = LOCAL_cached(cache,kvals(j),cfg,frame,timer);
      [point_rows,score_rows,level_rows,qz_rows,chart_rows] = ...
        LOCAL_append_ledgers(point_rows,score_rows,level_rows,qz_rows, ...
        chart_rows,node,layer);
      if ~node.pass
        gates(end+1,:) = LOCAL_gate(layer,'new_point_scientific',false,0,1, ...
          'new half-step point failed unchanged scientific gates');
        status = 'ZOOM_SCIENTIFIC_GATE_FAIL';
        stop_code = 'POINT_SCIENTIFIC_GATE';
        result = LOCAL_finish_full(); return;
      end
    end
    nodes = LOCAL_select(cache,kvals);
    assessment = LOCAL_assess(nodes,layer,h,cfg);
    layer_rows(end+1,:) = assessment.row; %#ok<AGROW>
    transport_rows = [transport_rows;assessment.transport_rows]; %#ok<AGROW>
    gates = [gates;assessment.gates]; %#ok<AGROW>
    q_history(end+1) = assessment.q; %#ok<AGROW>
    if ~assessment.pass
      status = assessment.status; stop_code = assessment.stop_code; break;
    end
    if numel(q_history) >= 2 && ...
        q_history(end) > q_history(end-1)*(1+cfg.nonmonotone_relative_tol)
      status = 'ZOOM_NONMONOTONE_FAIL';
      stop_code = 'Q_NONMONOTONE_RELATIVE_EXCESS'; break;
    end
    if LOCAL_plateau(q_history,cfg)
      status = 'ZOOM_PLATEAU_FAIL'; stop_code = 'THREE_LEVEL_PLATEAU'; break;
    end
    if assessment.q < cfg.near_zero_tol
      consecutive = consecutive+1;
    else
      consecutive = 0;
    end
    final_node = nodes(assessment.fine_index);
    if consecutive >= 2
      pass = true; status = 'ZOOM_M48_DISCRETE_NEAR_ZERO_GRID_CANDIDATE';
      stop_code = 'TWO_CONSECUTIVE_NEAR_ZERO_LEVELS'; break;
    end
    m = assessment.fine_index;
    bracket = kvals(m-1:m+1);
  end
  result = LOCAL_finish_full();

  function out = LOCAL_finish_full()
    if pass
      candidate = LOCAL_candidate(final_node,layer,q_history(end),cfg);
    else
      candidate = struct([]);
    end
    lineage = LOCAL_lineage('zoom',status,parent.lineage.token,provenance,cfg);
    out = LOCAL_result(cfg,'zoom',status,pass,toc(timer),gates,point_rows, ...
      score_rows,level_rows,qz_rows,chart_rows,transport_rows,layer_rows, ...
      provenance,lineage,parent,candidate,frame,parent_match, ...
      'M48_DISCRETE_NEAR_ZERO_GRID_CANDIDATE_ONLY');
    out.stop_code = stop_code;
    out.levels_completed = size(layer_rows,1);
    out.q_history = q_history;
    out.ideal_metadata = pass && candidate.q < cfg.ideal_tol;
    LOCAL_write(output_dir,out);
    fprintf('TEP_MC_ZOOM_STAGE=full STATUS=%s stop=%s seconds=%.6g\n', ...
      status,stop_code,out.elapsed_seconds);
  end
end

%% ==================== Cache and level assessment ====================
% These helpers reuse points and enforce every nested-grid stopping rule.

function [cache,node] = LOCAL_cached(cache,k,cfg,frame,timer)
  index = find(abs([cache.k]-k) <= 1e-13,1);
  if isempty(index)
    if toc(timer) >= cfg.hard_seconds, error('tep_mc_zoom:HardTime', ...
        'Hard time limit reached before point.'); end
    node = zoom_core('point',k,cfg,frame);
    cache(end+1) = node;
  else
    node = cache(index);
  end
end

function nodes = LOCAL_select(cache,kvals)
  nodes = repmat(cache(1),1,numel(kvals));
  for j = 1:numel(kvals)
    index = find(abs([cache.k]-kvals(j)) <= 1e-13,1);
    if isempty(index), error('tep_mc_zoom:Cache','Missing cached point.'); end
    nodes(j) = cache(index);
  end
end

function a = LOCAL_assess(nodes,layer,h,cfg)
  coarse = arrayfun(@(n) n.coarse.score.s1,nodes);
  fine = arrayfun(@(n) n.fine.score.s1,nodes);
  [ci,cunique] = LOCAL_unique_interior(coarse);
  [fi,funique] = LOCAL_unique_interior(fine);
  point_ok = all([nodes.pass]);
  [transport_rows,transport_ok,transport_min] = ...
    LOCAL_transports(nodes,layer,cfg);
  interior_ok = cunique && funique;
  if interior_ok
    drift_index = abs(ci-fi); drift = abs(nodes(ci).k-nodes(fi).k);
    drift_ok = drift_index <= 1 && drift <= h+10*eps;
    ratio = max(coarse(ci),fine(fi))/max(min(coarse(ci),fine(fi)),realmin);
    ratio_ok = ratio <= cfg.score_ratio_max;
    [left_overlap,right_overlap] = LOCAL_vector_overlap( ...
      nodes(ci).coarse,nodes(fi).fine);
    vector_ok = min(left_overlap,right_overlap) >= cfg.neighbor_overlap_min;
    raw_coarse = arrayfun(@(n) n.coarse.score.raw_sigma1 / ...
      n.coarse.score.raw_sigmamax,nodes);
    raw_fine = arrayfun(@(n) n.fine.score.raw_sigma1 / ...
      n.fine.score.raw_sigmamax,nodes);
    [~,rc] = min(raw_coarse); [~,rf] = min(raw_fine);
    raw_diff = max(abs(rc-ci),abs(rf-fi)); raw_ok = raw_diff <= 1;
    prominence_c = min(coarse(ci-1),coarse(ci+1))/max(coarse(ci),realmin);
    prominence_f = min(fine(fi-1),fine(fi+1))/max(fine(fi),realmin);
    prominence = min(prominence_c,prominence_f);
    prominence_ok = prominence >= cfg.prominence_min;
    r12 = max(nodes(ci).coarse.score.r12,nodes(fi).fine.score.r12);
    r12_ok = r12 <= cfg.r12_zoom_max;
    q = max(coarse(ci),fine(fi));
  else
    ci = 0; fi = 0; drift_index = Inf; drift = Inf; ratio = Inf;
    left_overlap = 0; right_overlap = 0; raw_diff = Inf;
    prominence = 0; r12 = Inf; q = Inf;
    drift_ok = false; ratio_ok = false; vector_ok = false;
    raw_ok = false; prominence_ok = false; r12_ok = false;
  end
  gates = [ ...
    LOCAL_gate(layer,'all_point_scientific',point_ok,double(point_ok),1, ...
      'all five points pass unchanged point gates'); ...
    LOCAL_gate(layer,'neighbor_transport',transport_ok,transport_min, ...
      cfg.neighbor_overlap_min,'adjacent plus/minus overlaps at both levels'); ...
    LOCAL_gate(layer,'unique_strict_interior_minima',interior_ok, ...
      double(interior_ok),1,'exactly one strict interior minimum per level'); ...
    LOCAL_gate(layer,'coarse_fine_minimum_drift',drift_ok,drift,h, ...
      'position difference <= current h and index difference <= 1'); ...
    LOCAL_gate(layer,'coarse_fine_score_ratio',ratio_ok,ratio, ...
      cfg.score_ratio_max,'ratio of coarse/fine minimum physical s1'); ...
    LOCAL_gate(layer,'minimum_vector_overlap',vector_ok, ...
      min(left_overlap,right_overlap),cfg.neighbor_overlap_min, ...
      'minimum left/right singular-vector overlaps'); ...
    LOCAL_gate(layer,'raw_physical_minimum_index',raw_ok,raw_diff,1, ...
      'raw and physical minimum indices differ by at most one'); ...
    LOCAL_gate(layer,'minimum_prominence',prominence_ok,prominence, ...
      cfg.prominence_min,'coarse/fine strict-dip prominence'); ...
    LOCAL_gate(layer,'minimum_r12',r12_ok,r12,cfg.r12_zoom_max, ...
      'coarse/fine minimum r12')];
  pass = all(cell2mat(gates(:,4)));
  status = ''; stop_code = '';
  if ~point_ok
    status = 'ZOOM_SCIENTIFIC_GATE_FAIL'; stop_code = 'POINT_SCIENTIFIC_GATE';
  elseif ~transport_ok
    status = 'ZOOM_TRANSPORT_GATE_FAIL'; stop_code = 'NEIGHBOR_TRANSPORT_GATE';
  elseif ~interior_ok
    status = 'ZOOM_INTERIOR_MINIMUM_FAIL';
    stop_code = 'ENDPOINT_OR_NONUNIQUE_STRICT_MINIMUM';
  elseif ~drift_ok
    status = 'ZOOM_COARSE_FINE_DRIFT_FAIL'; stop_code = 'COARSE_FINE_DRIFT';
  elseif ~(ratio_ok && vector_ok && raw_ok && prominence_ok && r12_ok)
    status = 'ZOOM_SCORE_GATE_FAIL'; stop_code = 'NESTED_SCORE_GATE';
  end
  a = struct('pass',pass,'status',status,'stop_code',stop_code,'q',q, ...
    'coarse_index',ci,'fine_index',fi,'transport_rows',{transport_rows}, ...
    'gates',{gates},'row',{{layer,h,nodes(1).k,nodes(end).k,ci,fi, ...
    drift_index,drift,coarse(max(ci,1)),fine(max(fi,1)),q,ratio, ...
    prominence,r12,left_overlap,right_overlap,raw_diff,pass}});
end

function [index,unique] = LOCAL_unique_interior(values)
  minimum = min(values);
  found = find(values == minimum);
  unique = numel(found) == 1 && found > 1 && found < numel(values) && ...
    values(found) < values(found-1) && values(found) < values(found+1);
  if unique, index = found; else, index = 0; end
end

function [rows,pass,min_value] = LOCAL_transports(nodes,layer,cfg)
  rows = cell(0,9); pass = true; min_value = 1;
  levels = {'coarse','fine'}; sides = {'plus','minus'};
  for j = 1:numel(nodes)-1
    for l = 1:2
      for s = 1:2
        [value,~] = LOCAL_overlap(nodes(j).(levels{l}).(sides{s}).Z, ...
          nodes(j+1).(levels{l}).(sides{s}).Z);
        ok = value >= cfg.neighbor_overlap_min;
        rows(end+1,:) = {layer,nodes(j).k,nodes(j+1).k,levels{l}, ...
          sides{s},value,cfg.neighbor_overlap_min,ok,'ADJACENT_QR_OVERLAP'}; %#ok<AGROW>
        pass = pass && ok; min_value = min(min_value,value);
      end
    end
  end
end

function [left,right] = LOCAL_vector_overlap(coarse,fine)
  [Uc,~,Vc] = svd(coarse.Aphys/coarse.score.seed_scale,'econ');
  [Uf,~,Vf] = svd(fine.Aphys/fine.score.seed_scale,'econ');
  left = abs(Uc(:,end)'*Uf(:,end));
  right = abs(Vc(:,end)'*Vf(:,end));
end

function yes = LOCAL_plateau(q,cfg)
  yes = false;
  if numel(q) < 3 || any(q(end-2:end) <= cfg.near_zero_tol), return; end
  improve1 = (q(end-2)-q(end-1))/q(end-2);
  improve2 = (q(end-1)-q(end))/q(end-1);
  yes = improve1 <= cfg.plateau_improvement_max && ...
    improve2 <= cfg.plateau_improvement_max;
end

%% ==================== Parent checks and compact artifacts ====================
% These helpers verify lineage and flatten all retained numerical evidence.

function [parent,note] = LOCAL_parent(here,cfg,p)
  path = fullfile(here,'output','confirm48','result.mat');
  if ~isfile(path), error('tep_mc_zoom:Parent','Missing parent result.'); end
  loaded = load(path,'result'); parent = loaded.result;
  fields = {'schema','experiment_id','stage','status','pass', ...
    'next_authorized','all_gates_pass','candidates','lineage'};
  if ~all(isfield(parent,fields))
    error('tep_mc_zoom:Parent','Parent fields missing.');
  end
  basic = strcmp(parent.schema,cfg.schema) && ...
    strcmp(parent.experiment_id,cfg.experiment_id) && ...
    strcmp(parent.stage,cfg.parent_stage) && ...
    strcmp(parent.status,cfg.parent_status) && parent.pass && ...
    parent.next_authorized && parent.all_gates_pass && ...
    numel(parent.candidates) == 1 && ...
    abs(parent.candidates(1).k-cfg.parent_candidate_k) <= 1e-14 && ...
    abs(parent.candidates(1).k2_metadata-parent.candidates(1).k^2) <= 1e-14;
  old_source = LOCAL_hash(fullfile(here,'tep_mc_scan.m'));
  old_config = LOCAL_hash(fullfile(here,'scan_cfg.m'));
  token = LOCAL_old_token(parent.schema,parent.experiment_id,parent.stage, ...
    parent.status,parent.lineage.parent_token,old_config,old_source);
  lineage_ok = strcmp(parent.lineage.stage,parent.stage) && ...
    strcmp(parent.lineage.source_hash,old_source) && ...
    strcmp(parent.lineage.config_fingerprint,old_config) && ...
    strcmp(parent.lineage.token,token) && ...
    strcmp(p.source_hashes.tep_mc_scan,old_source) && ...
    strcmp(p.source_hashes.scan_cfg,old_config);
  if ~(basic && lineage_ok)
    error('tep_mc_zoom:Parent','Parent schema, candidate, hash, or lineage failed.');
  end
  note = 'confirm48 schema/status/authorization/candidate/hash/token verified';
end

function reference = LOCAL_parent_score(here,k)
  table = readtable(fullfile(here,'output','confirm48','scores.csv'), ...
    'TextType','string');
  rows = abs(table.k-k) <= 1e-13;
  reference = table(rows,:);
  if height(reference) ~= 2
    error('tep_mc_zoom:ParentCSV','Parent pivot score rows missing.');
  end
end

function match = LOCAL_score_match(node,reference,tol)
  names = {'coarse','fine'}; value = 0;
  fields = {'raw_sigma1','raw_sigmamax','sigma1','sigmamax','s1'};
  for j = 1:2
    row = reference(reference.level == names{j},:);
    if height(row) ~= 1, value = Inf; break; end
    for f = 1:numel(fields)
      a = node.(names{j}).score.(fields{f}); b = row.(fields{f});
      value = max(value,abs(a-b)/max(1,abs(b)));
    end
  end
  match = struct('pass',value <= tol,'value',value);
end

function match = LOCAL_bracket_match(cache,here,cfg)
  reference = readtable(fullfile(here,'output','confirm48','scores.csv'), ...
    'TextType','string');
  value = 0;
  for j = 1:numel(cfg.initial_bracket)
    node = LOCAL_select(cache,cfg.initial_bracket(j));
    current = LOCAL_score_match(node,reference(abs(reference.k-node.k)<=1e-13,:), ...
      cfg.score_match_tol);
    value = max(value,current.value);
  end
  match = struct('pass',value <= cfg.score_match_tol,'value',value);
end

function candidate = LOCAL_candidate(node,layer,q,cfg)
  candidate = struct('k',node.k,'k2_metadata',node.k^2,'layer',layer, ...
    'q',q,'ideal_metadata',q < cfg.ideal_tol, ...
    'claim','M48_DISCRETE_NEAR_ZERO_GRID_CANDIDATE', ...
    'coarse',LOCAL_audit(node.coarse),'fine',LOCAL_audit(node.fine));
end

function audit = LOCAL_audit(level)
  [U,~,V] = svd(level.Aphys/level.score.seed_scale,'econ');
  b = sqrt(1+abs(level.beta_m(:)).^2);
  audit = struct('Adef_D_unbalanced',level.Adef.D, ...
    'normalized_min_left_singular_vector',U(:,end)/norm(U(:,end)), ...
    'normalized_min_right_singular_vector',V(:,end)/norm(V(:,end)), ...
    'physical_row_weight',repmat(sqrt(1./b),2,1), ...
    'physical_column_weight',repmat(1./sqrt(b+abs(level.gamma).^2./b),2,1), ...
    'seed_scale',level.score.seed_scale,'s1',level.score.s1, ...
    'r12',level.score.r12);
end

function result = LOCAL_result(cfg,stage,status,pass,elapsed,gates,point_rows, ...
    score_rows,level_rows,qz_rows,chart_rows,transport_rows,layer_rows, ...
    provenance,lineage,parent,candidate,frame,parent_match,claim)
  result = struct('schema',cfg.zoom_schema, ...
    'experiment_id',cfg.zoom_experiment_id,'stage',stage,'status',status, ...
    'pass',pass,'all_gates_pass',~isempty(gates) && all(cell2mat(gates(:,4))), ...
    'elapsed_seconds',elapsed,'gates',{gates},'point_rows',{point_rows}, ...
    'score_rows',{score_rows},'level_rows',{level_rows},'qz_rows',{qz_rows}, ...
    'chart_rows',{chart_rows},'transport_rows',{transport_rows}, ...
    'layer_rows',{layer_rows},'provenance',provenance,'lineage',lineage, ...
    'parent_stage',parent.stage,'parent_status',parent.status, ...
    'parent_lineage_token',parent.lineage.token, ...
    'candidate',{candidate},'frame_rows_plus',frame.rows_plus, ...
    'frame_rows_minus',frame.rows_minus,'coarse_seed_scale',frame.coarse_scale, ...
    'fine_seed_scale',frame.fine_scale,'parent_score_match',parent_match, ...
    'claim_boundary',claim,'locator_authorized',false, ...
    'root_isolation_authorized',false,'derivative_authorized',false, ...
    'estimator_authorized',false,'config',cfg);
end

function [p,s,l,q,c] = LOCAL_append_ledgers(p,s,l,q,c,node,layer)
  p = [p;LOCAL_point_rows(node,layer)];
  s = [s;LOCAL_score_rows(node,layer)];
  l = [l;LOCAL_level_rows(node,layer)];
  q = [q;LOCAL_qz_rows(node,layer)];
  c = [c;LOCAL_chart_rows(node,layer)];
end

function rows = LOCAL_point_rows(n,layer)
  rows = {layer,n.k,n.pass,max(n.coarse.solve_residual,n.fine.solve_residual), ...
    min(n.coarse.wood_distance,n.fine.wood_distance), ...
    max(n.coarse.gamma_identity,n.fine.gamma_identity), ...
    n.coarse.branch_ok && n.fine.branch_ok,n.metric.block_abs, ...
    n.metric.block_action,n.metric.pencil_action};
end

function rows = LOCAL_score_rows(n,layer)
  rows = cell(2,15); names = {'coarse','fine'};
  for j = 1:2
    x = n.(names{j}).score;
    rows(j,:) = {layer,n.k,names{j},x.raw_sigma1,x.raw_sigmamax, ...
      x.sigma1,x.sigmamax,x.s1,x.r12,x.g12,x.scalar_mutation, ...
      x.seed_scale,n.(names{j}).mutation.lambda, ...
      n.(names{j}).mutation.adef,n.(names{j}).mutation.score};
  end
end

function rows = LOCAL_level_rows(n,layer)
  m = n.metric;
  rows = {layer,n.k,m.block_abs,m.block_action,m.pencil_action, ...
    m.subspace_plus,m.subspace_minus,m.cauchy_plus,m.cauchy_minus, ...
    m.dtn_plus,m.dtn_minus,m.adef_action,m.schur_max,m.row_solve_max, ...
    m.wall_ok,n.pass,'M48_COARSE_FINE'};
end

function rows = LOCAL_qz_rows(n,layer)
  rows = cell(4,17); levels = {'coarse','fine'}; sides = {'plus','minus'};
  r = 0;
  for l = 1:2
    for s = 1:2
      r = r+1; x = n.(levels{l}).(sides{s});
      rows(r,:) = {layer,n.k,levels{l},sides{s},x.stable_count, ...
        x.unstable_count,x.neutral_count,x.infinite_count, ...
        x.indeterminate_count,x.raw_residual,x.residual,x.unit_gap, ...
        x.row_margin,x.row_condition,x.row_solve,x.regular_infinity,x.pass};
    end
  end
end

function rows = LOCAL_chart_rows(n,layer)
  rows = cell(4,13); levels = {'coarse','fine'}; sides = {'plus','minus'};
  charts = {'cp','cm'}; r = 0;
  for l = 1:2
    for s = 1:2
      r = r+1; q = n.(levels{l}).(sides{s}); x = n.(levels{l}).(charts{s});
      rows(r,:) = {layer,n.k,levels{l},sides{s},q.row_margin, ...
        q.row_condition,q.row_condition*eps,q.row_solve,x.margin, ...
        x.condition,x.condition_eps,x.solve_residual,x.safe};
    end
  end
end

function row = LOCAL_gate(layer,name,pass,value,tolerance,note)
  if pass, status = 'PASS'; else, status = 'FAIL'; end
  row = {layer,name,status,logical(pass),value,tolerance,note};
end

function LOCAL_write(output_dir,r)
  LOCAL_csv(fullfile(output_dir,'points.csv'), ...
    {'layer','k','pass','solve_max','wood_distance','gamma_identity', ...
    'branch_ok','block_abs','block_action','pencil_action'},r.point_rows);
  LOCAL_csv(fullfile(output_dir,'scores.csv'), ...
    {'layer','k','level','raw_sigma1','raw_sigmamax','sigma1','sigmamax', ...
    's1','r12','g12','scalar_mutation','seed_scale','basis_lambda', ...
    'basis_adef','basis_score'},r.score_rows);
  LOCAL_csv(fullfile(output_dir,'levels.csv'), ...
    {'layer','k','block_abs','block_action','pencil_action','subspace_plus', ...
    'subspace_minus','cauchy_plus','cauchy_minus','dtn_plus','dtn_minus', ...
    'adef_action','schur_max','row_solve_max','wall_ok','pass','claim'}, ...
    r.level_rows);
  LOCAL_csv(fullfile(output_dir,'qz.csv'), ...
    {'layer','k','level','side','stable','unstable','neutral','infinite', ...
    'indeterminate','raw_residual','residual','unit_gap','row_margin', ...
    'row_condition','row_solve','regular_infinity','pass'},r.qz_rows);
  LOCAL_csv(fullfile(output_dir,'charts.csv'), ...
    {'layer','k','level','side','row_margin','row_condition', ...
    'row_condition_eps','row_solve','chart_margin','chart_condition', ...
    'chart_condition_eps','chart_solve','safe'},r.chart_rows);
  LOCAL_csv(fullfile(output_dir,'transports.csv'), ...
    {'layer','k_left','k_right','level','side','overlap','threshold', ...
    'pass','claim'},r.transport_rows);
  LOCAL_csv(fullfile(output_dir,'gates.csv'), ...
    {'layer','gate','status','pass','value','tolerance','note'},r.gates);
  LOCAL_csv(fullfile(output_dir,'layers.csv'), ...
    {'layer','h','k_left','k_right','coarse_index','fine_index', ...
    'index_drift','k_drift','coarse_min_s1','fine_min_s1','q','score_ratio', ...
    'prominence','r12','left_overlap','right_overlap','raw_index_diff', ...
    'pass'},r.layer_rows);
  LOCAL_write_provenance(fullfile(output_dir,'provenance.csv'),r.provenance);
  LOCAL_csv(fullfile(output_dir,'lineage.csv'),{'field','value'}, { ...
    'stage',r.lineage.stage;'parent_token',r.lineage.parent_token; ...
    'config_fingerprint',r.lineage.config_fingerprint; ...
    'source_hash',r.lineage.source_hash; ...
    'grid_fingerprint',r.lineage.grid_fingerprint; ...
    'token',r.lineage.token});
  result = r; save(fullfile(output_dir,'result.mat'),'result','-v7');
  LOCAL_report(fullfile(output_dir,'report.md'),r);
  LOCAL_log(fullfile(output_dir,'run.log'),r);
end

function p = LOCAL_provenance(here,repo)
  [status,sha] = system(sprintf('git -C "%s" rev-parse HEAD',repo));
  if status ~= 0, error('tep_mc_zoom:Git','Cannot record Git SHA.'); end
  paths = struct('tep_mc_zoom',LOCAL_source_path(mfilename('fullpath')), ...
    'zoom_core',fullfile(here,'zoom_core.m'), ...
    'zoom_cfg',fullfile(here,'zoom_cfg.m'), ...
    'tep_mc_scan',fullfile(here,'tep_mc_scan.m'), ...
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
  config_fingerprint = p.source_hashes.zoom_cfg;
  source_hash = LOCAL_text_hash(strjoin({p.source_hashes.tep_mc_zoom, ...
    p.source_hashes.zoom_core},'|'));
  grid = sprintf('M=%d|h=%.17g|max=%d|seed=%.17g',cfg.zoom_M, ...
    cfg.initial_h,cfg.max_levels,cfg.pivot_seed_k);
  payload = strjoin({cfg.zoom_schema,cfg.zoom_experiment_id,stage,status, ...
    parent_token,config_fingerprint,source_hash,grid},'|');
  lineage = struct('stage',stage,'parent_token',parent_token, ...
    'config_fingerprint',config_fingerprint,'source_hash',source_hash, ...
    'grid_fingerprint',LOCAL_text_hash(grid),'token',LOCAL_text_hash(payload));
end

function token = LOCAL_old_token(schema,experiment,stage,status,parent,config,source)
  token = LOCAL_text_hash(strjoin({schema,experiment,stage,status,parent, ...
    config,source},'|'));
end

function value = LOCAL_hash(path)
  fid = fopen(path,'r');
  if fid < 0, error('tep_mc_zoom:Hash','Cannot read %s.',path); end
  cleanup = onCleanup(@() fclose(fid)); bytes = fread(fid,Inf,'*uint8');
  digest = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
  digest.update(typecast(bytes(:),'int8')); raw = typecast(digest.digest(),'uint8');
  value = lower(reshape(dec2hex(raw,2).',1,[])); clear cleanup;
end

function path = LOCAL_source_path(path)
  if ~isfile(path) && isfile([path,'.m']), path = [path,'.m']; end
  if ~isfile(path)
    error('tep_mc_zoom:Source','Cannot resolve source %s.',path);
  end
end

function value = LOCAL_text_hash(payload)
  digest = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
  digest.update(typecast(uint8(payload(:)),'int8'));
  raw = typecast(digest.digest(),'uint8');
  value = lower(reshape(dec2hex(raw,2).',1,[]));
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

function LOCAL_report(path,r)
  fid = fopen(path,'w'); cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'# M48 Nested Grid %s Report\n\n',r.stage);
  fprintf(fid,'- Experiment ID: `%s`\n',r.experiment_id);
  fprintf(fid,'- Status: `%s`\n- Pass: `%d`\n',r.status,r.pass);
  if isfield(r,'stop_code'), fprintf(fid,'- Stop code: `%s`\n',r.stop_code); end
  fprintf(fid,'- Wall time: `%.6g s`\n',r.elapsed_seconds);
  fprintf(fid,'- Parent stage/status: `%s` / `%s`\n',r.parent_stage,r.parent_status);
  fprintf(fid,'- Parent lineage token: `%s`\n',r.parent_lineage_token);
  fprintf(fid,'- Lineage token: `%s`\n',r.lineage.token);
  fprintf(fid,'- Claim boundary: `%s`\n',r.claim_boundary);
  fprintf(fid,'- Locator/root/derivative/estimator authorized: `0/0/0/0`\n');
  if ~isempty(r.candidate)
    fprintf(fid,'- Candidate metadata: `k=%.17g`, `k^2=%.17g`, `q=%.17g`\n', ...
      r.candidate.k,r.candidate.k2_metadata,r.candidate.q);
  end
  fprintf(fid,'\nAll claims are discrete M48 grid claims.\n'); clear cleanup;
end

function LOCAL_log(path,r)
  fid = fopen(path,'w'); cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'experiment_id=%s\nstage=%s\nstatus=%s\npass=%d\n', ...
    r.experiment_id,r.stage,r.status,r.pass);
  if isfield(r,'stop_code'), fprintf(fid,'stop_code=%s\n',r.stop_code); end
  fprintf(fid,'elapsed_seconds=%.17g\nparent_lineage_token=%s\n', ...
    r.elapsed_seconds,r.parent_lineage_token);
  fprintf(fid,'lineage_token=%s\nclaim_boundary=%s\n', ...
    r.lineage.token,r.claim_boundary); clear cleanup;
end

function LOCAL_mkdir(path)
  if ~exist(path,'dir'), mkdir(path); end
end

function LOCAL_csv(path,headers,rows)
  fid = fopen(path,'w');
  if fid < 0, error('tep_mc_zoom:Artifact','Cannot open %s.',path); end
  cleanup = onCleanup(@() fclose(fid)); LOCAL_csv_row(fid,headers);
  for j = 1:size(rows,1), LOCAL_csv_row(fid,rows(j,:)); end
  clear cleanup;
end

function LOCAL_csv_row(fid,row)
  fields = cell(1,numel(row));
  for j = 1:numel(row)
    value = row{j};
    if islogical(value), item = sprintf('%d',value);
    elseif isnumeric(value)
      if isempty(value), item = ''; else, item = sprintf('%.17g',value); end
    else, item = char(value);
    end
    fields{j} = ['"',strrep(item,'"','""'),'"'];
  end
  fprintf(fid,'%s\n',strjoin(fields,','));
end

function [sigma_min,distance] = LOCAL_overlap(A,B)
  [Qa,~] = qr(A,0); [Qb,~] = qr(B,0);
  singular = svd(Qa'*Qb,'econ'); sigma_min = min(singular);
  distance = sqrt(max(0,1-sigma_min^2));
end
