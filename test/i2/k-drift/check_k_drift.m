function result = check_k_drift(attempt)
%CHECK_K_DRIFT Run the frozen I2.3 single-axis candidate-drift experiment.
% Purpose:
%   Compare the same real-axis candidate at ntot = 160, 208, and 256 while
%   every trace, proxy, solver, branch, frame, row, and scoring choice stays
%   fixed.
% Input:
%   attempt - New append-only output tag. The reviewed tag is 'drift-a1'.
% Output:
%   result  - Compact locator, candidate, identity, repeat, and drift data.
% Main algorithm:
%   Build one ntot-256 eval_i21 seed frame, run an independent bounded
%   five-point dyadic locator at each ntot, qualify the mapped physical mode,
%   repeat each terminal point once, and compare the three candidates.
% Based on:
%   research/projects/eig-apost/implementation/i2/design-2-3.md and the
%   test/i2/k-count/eval_i21.m seed/point interface.
% Main changes:
%   Refine only boundary Nystrom order, use the I1.3 physical AdefD score,
%   and add compact raw, field, boundary, repeat, and mode-identity evidence.
% Numerical goal:
%   Decide whether two adjacent same-mode candidate drifts exceed their
%   combined terminal grid uncertainties. This is not a root or error bound.

  if nargin ~= 1 || ~strcmp(char(attempt),'drift-a1')
    error('i23:Attempt','The reviewed attempt name is drift-a1.');
  end
  here = fileparts(mfilename('fullpath'));
  output = fullfile(here,'output',char(attempt));
  if exist(output,'dir') || exist(output,'file')
    error('i23:OutputExists','Output already exists: %s.',output);
  end

  timer = tic;
  c = LOCAL_config();
  rows = LOCAL_selectors();
  runtime = struct(); oracle = struct(); seed_summary = struct();
  locators = cell(1,3); candidates = cell(1,3);
  repeats = cell(1,3); identities = cell(1,3); drifts = cell(1,3);
  first_failure = LOCAL_failure('NONE','NONE',NaN,NaN,'','');
  peak_mib = 0; execution_pass = false;
  scientific_outcome = 'UNAVAILABLE'; trend = 'UNAVAILABLE';
  hierarchy_qualified = false; i3_may_proceed = false;
  i3_status = 'STOP_EXECUTION_UNAVAILABLE';

  try
    LOCAL_config_gate(c,rows);
    runtime = LOCAL_runtime();
    oracle = LOCAL_identity_oracle(c);
    if ~oracle.pass
      error('i23:IdentityOracle','The phase/scale identity oracle failed.');
    end

    % --- stage 1: create the sole fine seed and common continuation frame ---
    c256 = LOCAL_level_config(c,256);
    [seed,frame] = eval_i21('seed',c256,rows);
    LOCAL_node_gate(seed,c.kstar,256,frame,c);
    seed_summary = LOCAL_node_summary(seed,256,LOCAL_score(seed));
    peak_mib = max(peak_mib,LOCAL_mib(seed,frame,candidates));
    LOCAL_resource_gate(timer,peak_mib,c);

    % --- stage 2: run three independent bounded real-axis locators ---
    for j = 1:numel(c.ntot_levels)
      ntot = c.ntot_levels(j);
      [locators{j},candidates{j},level_peak] = ...
        LOCAL_locate(ntot,c,frame,seed,timer,candidates);
      peak_mib = max(peak_mib,level_peak);
      if ~locators{j}.pass
        scientific_outcome = 'CANDIDATE_UNRESOLVED';
        first_failure = locators{j}.first_failure;
        break;
      end
    end

    % --- stage 3: repeat fixed candidates without claiming rank stability ---
    if strcmp(scientific_outcome,'UNAVAILABLE')
      for j = 1:3
        [repeats{j},repeat_peak] = LOCAL_repeat( ...
          candidates{j},c,frame,seed,timer,candidates);
        peak_mib = max(peak_mib,repeat_peak);
        if ~repeats{j}.pass
          scientific_outcome = 'CANDIDATE_UNRESOLVED';
          first_failure = repeats{j}.first_failure;
          break;
        end
      end
    end

    % --- stage 4: compare common wall traces and fixed physical probes ---
    if strcmp(scientific_outcome,'UNAVAILABLE')
      identities{1} = LOCAL_identity(candidates{1},candidates{2},c,true);
      identities{2} = LOCAL_identity(candidates{2},candidates{3},c,true);
      identities{3} = LOCAL_identity(candidates{1},candidates{3},c,false);
      if ~(identities{1}.pass && identities{2}.pass)
        if strcmp(identities{1}.status,'MODE_SWITCH') || ...
            strcmp(identities{2}.status,'MODE_SWITCH')
          scientific_outcome = 'MODE_SWITCH';
          first_failure = LOCAL_failure('MODE_SWITCH','MODE_IDENTITY',NaN,NaN, ...
            'An adjacent primary-secondary cross-overlap exceeded 0.5.','');
        else
          scientific_outcome = 'MODE_IDENTITY_UNRESOLVED';
          first_failure = LOCAL_failure('MODE_IDENTITY_UNRESOLVED', ...
            'MODE_IDENTITY',NaN,NaN,'An adjacent physical identity gate failed.','');
        end
      end
    end

    % --- stage 5: classify signed drift against combined grid uncertainty ---
    if strcmp(scientific_outcome,'UNAVAILABLE')
      drifts{1} = LOCAL_drift(candidates{1},candidates{2},c);
      drifts{2} = LOCAL_drift(candidates{2},candidates{3},c);
      drifts{3} = LOCAL_drift(candidates{1},candidates{3},c);
      trend = LOCAL_trend(drifts{1},drifts{2});
      hierarchy_qualified = drifts{1}.resolved && drifts{2}.resolved;
      i3_may_proceed = hierarchy_qualified;
      if hierarchy_qualified
        scientific_outcome = 'DRIFT_RESOLVED';
        if any(cellfun(@(x) strcmp(x.classification, ...
            'DRIFT_RESOLVED_SEVERE'),drifts))
          i3_status = 'MAY_PROCEED_WITH_SEVERE_DRIFT_LIMITATION';
        else
          i3_status = 'MAY_PROCEED_WITH_RESOLVED_HIERARCHY';
        end
      else
        scientific_outcome = 'DRIFT_UNRESOLVED';
        i3_status = 'STOP_DRIFT_UNRESOLVED';
        first_failure = LOCAL_failure('DRIFT_UNRESOLVED','DRIFT',NaN,NaN, ...
          'An adjacent drift did not exceed combined localization uncertainty.','');
      end
    end
    execution_pass = true;
  catch ME
    [code,stage] = LOCAL_exception_class(ME);
    scientific_outcome = 'EXECUTION_UNAVAILABLE';
    first_failure = LOCAL_failure(code,stage,NaN,NaN,ME.message,ME.identifier);
    trend = 'UNAVAILABLE'; hierarchy_qualified = false;
    i3_may_proceed = false; i3_status = 'STOP_EXECUTION_UNAVAILABLE';
  end

  elapsed = toc(timer);
  if execution_pass && elapsed > c.hard_seconds
    execution_pass = false; scientific_outcome = 'EXECUTION_UNAVAILABLE';
    hierarchy_qualified = false; i3_may_proceed = false;
    i3_status = 'STOP_HARD_TIME';
    first_failure = LOCAL_failure('HARD_TIME','RESOURCE',NaN,NaN, ...
      'The runner exceeded its hard wall-time limit.','i23:HARD_TIME');
  end
  status = ['I2_3_',scientific_outcome];
  result = LOCAL_result(char(attempt),status,execution_pass, ...
    scientific_outcome,hierarchy_qualified,i3_may_proceed,i3_status, ...
    trend,elapsed,peak_mib,c,rows,runtime,oracle,seed_summary,locators, ...
    candidates,repeats,identities,drifts,first_failure);

  if exist(output,'dir') || exist(output,'file')
    error('i23:OutputExists','Output appeared during the run: %s.',output);
  end
  mkdir(output);
  save(fullfile(output,'result.mat'),'result','-v7');
  LOCAL_report(fullfile(output,'report.md'),result);
end

%% ==================== Frozen configuration ====================
% These helpers contain the reviewed model, sole axis, selectors, and gates.

function c = LOCAL_config()
  c = struct('schema','TEP_I2_3_NTOT_DRIFT_V1', ...
    'experiment_id','I2-NTOT-DRIFT-V1', ...
    'design_id','I2.3-NTOT-DRIFT-V1', ...
    'claim_boundary','CONDITIONAL_EMPIRICAL_THREE_LEVEL_DISCRETE_CANDIDATE_DRIFT', ...
    'axis','BOUNDARY_NYSTROM_NTOT_AT_FIXED_FINE_PROXY_M48', ...
    'beta',0.5,'d',1.0,'R',0.2,'s',1.0,'X_L',-0.5,'X_R',0.5, ...
    'H',1.1,'proxy_dist',0.2,'M',48,'K',97, ...
    'kstar',1.8327703475952146, ...
    'r0',3.8146972647368216e-7, ...
    'ntot_levels',[160,208,256], ...
    'locator_max_layer',11,'locator_spacing_max',1e-10, ...
    'score_tie_min',1e-12,'score_max',1e-3,'r12_max',0.1, ...
    'raw_backward_max',1e-8,'identity_overlap_min',0.99, ...
    'competitor_overlap_max',0.5,'participation_min',1e-3, ...
    'repeat_matrix_max',1e-12,'repeat_score_max',1e-12, ...
    'repeat_overlap_min',1-1e-10,'severity_scale',1e-6, ...
    'target_seconds',900,'hard_seconds',1800,'memory_mib_max',512);
  c.level = struct('name','fine','ntot',256,'N_side',160, ...
    'N_top',160,'N_proxy_edge',80,'M_pw',32);
  c.expected = struct('proxy_rank',260);
  [px,py] = ndgrid([-0.25,0,0.25],[-0.25,0,0.25]);
  c.probe_x = px(:); c.probe_y = py(:);

  % Unchanged eval_i21 representation and solve gates.
  c.proxy_rank_ratio=1e-8; c.proxy_rank_gap_min=2;
  c.proxy_projector_repeat_tol=1e-10; c.proxy_rcond_min=1e-8;
  c.proxy_projected_tol=1e-11; c.proxy_full_residual_max=1e-5;
  c.proxy_shifted_residual_max=1e-5; c.proxy_seed_identity_tol=1e-12;
  c.branch_tol=1e-12; c.qz_residual_tol=1e-10; c.qz_overlap_min=0.9;
  c.cross_cluster_margin_min=100*c.K*eps; c.chart_margin_min=100*c.K*eps;
  c.chart_condition_eps_tol=1e-9; c.small_solve_residual_tol=1e3*c.K*eps;
  c.bie_rcond_min=1e-8; c.bie_residual_tol=1e-10;
  c.schur_tol=1e3*c.K*eps; c.dirichlet_rcond_min=1e-8;
  c.lift_residual_tol=1e-10;
  c.svd_residual_max=1e3*(2*c.K)*eps;
end

function rows = LOCAL_selectors()
  rows.plus = [89 41 35 71 92 12 16 10 66 70 93 33 9 69 79 30 36 ...
    62 64 84 95 40 18 91 94 58 61 13 85 90 24 32 42 60 28 74 21 ...
    97 22 55 77 96 38 14 17 2 20 1 67 75 37 43 72 5 80 81 82 7 ...
    68 39 25 19 78 29 6 76 86 59 8 4 65 83 23 31 3 73 57 63 56 ...
    26 88 27 11 87 15 34 54 44 53 45 52 46 51 47 50 48 49];
  rows.minus = [162 132 117 174 103 124 134 140 173 194 101 172 186 ...
    120 167 168 170 178 189 100 153 180 192 110 118 121 125 169 175 ...
    176 185 119 160 164 179 108 113 114 131 165 171 183 193 111 128 ...
    133 139 159 181 190 191 106 129 157 163 135 116 127 155 177 102 ...
    104 126 130 137 156 184 109 138 187 115 136 154 161 166 158 123 ...
    98 122 105 188 112 152 99 182 107 151 141 150 142 149 143 148 ...
    144 147 145 146];
end

function out = LOCAL_level_config(c,ntot)
  out = c;
  out.level.ntot = ntot;
end

function LOCAL_config_gate(c,rows)
  h11 = c.r0/2/2^11;
  ok = isequal(c.ntot_levels,[160,208,256]) && c.M == 48 && c.K == 97 && ...
    strcmp(c.level.name,'fine') && c.level.N_side == 160 && ...
    c.level.N_top == 160 && c.level.N_proxy_edge == 80 && ...
    c.level.M_pw == 32 && c.locator_max_layer == 11 && ...
    h11 <= c.locator_spacing_max && c.r0/2/2^10 > c.locator_spacing_max && ...
    isequal(sort(rows.plus),1:97) && isequal(sort(rows.minus),98:194) && ...
    numel(c.probe_x) == 9 && numel(c.probe_y) == 9;
  if ~ok
    error('i23:Config','The frozen configuration or selector gate failed.');
  end
end

function runtime = LOCAL_runtime()
  names = {'eval_i21','i21_kproxy','kproxy','kchan','kgreen','kbie', ...
    'geom.construct_cont','bloch.incident_rhs','bloch.farfield_extractors'};
  names = [names,{'kernel.h2d_directch','kernel.kress_l_splits', ...
    'kernel.kress_mn_splits','utils.triginterp','quad.quad_kress_rvec'}];
  resolved = repmat(struct('name','','path',''),numel(names),1);
  for j = 1:numel(names)
    matches = which(names{j},'-all');
    if ischar(matches), matches = cellstr(matches); end
    if numel(matches) ~= 1
      error('i23:Runtime','Exactly one %s must be on the MATLAB path.',names{j});
    end
    resolved(j) = struct('name',names{j},'path',matches{1});
  end
  solver = which('lsqminnorm');
  if exist('OCTAVE_VERSION','builtin') ~= 0 || isempty(solver) || ...
      ~startsWith(solver,matlabroot) || ~strcmp(class(1.0),'double')
    error('i23:Runtime','Public MATLAB lsqminnorm and double precision are required.');
  end
  runtime = struct('kind','MATLAB','version',version, ...
    'solver','lsqminnorm','solver_path',solver,'resolved_functions',resolved, ...
    'precision','double','pinv_calls',0,'fallbacks',0, ...
    'silent_rank_truncations',0,'method_switches',0, ...
    'reads_git_docs_history_or_hashes',false);
end

function oracle = LOCAL_identity_oracle(c)
  e1 = [1;0]; e2 = [0;1];
  big = 1e8*exp(1i*pi/7)*e1;
  small = 1e-8*exp(-1i*pi/7)*e1;
  [rho_big,a_big] = LOCAL_overlap(e1,big,0,0);
  [rho_small,a_small] = LOCAL_overlap(e1,small,0,0);
  [rho_orth,a_orth] = LOCAL_overlap(e1,e2,0,0);
  [~,a_zero] = LOCAL_overlap(e1,zeros(2,1),0,0);
  [~,a_nonfinite] = LOCAL_overlap(e1,[Inf;0],0,0);
  [~,a_under] = LOCAL_overlap(e1,1e-4*e1,0,c.participation_min);
  pass = a_big && a_small && a_orth && abs(rho_big-1) <= 1e-14 && ...
    abs(rho_small-1) <= 1e-14 && rho_orth <= 1e-14 && ...
    ~a_zero && ~a_nonfinite && ~a_under;
  oracle = struct('scale_large',1e8,'theta_large',pi/7, ...
    'scale_small',1e-8,'theta_small',-pi/7, ...
    'large_overlap',rho_big,'small_overlap',rho_small, ...
    'orthogonal_overlap',rho_orth,'zero_available',a_zero, ...
    'nonfinite_available',a_nonfinite,'under_threshold_available',a_under, ...
    'pass',pass);
end

%% ==================== Bounded locator ====================
% These helpers evaluate at most five dense nodes and retain compact ledgers.

function [locator,candidate,peak_mib] = ...
    LOCAL_locate(ntot,c,frame,seed,timer,retained)
  lc = LOCAL_level_config(c,ntot);
  cache = struct('k',{},'node',{},'score',{});
  node_rows = struct('ntot',{},'k',{},'s1',{},'r12',{},'node_pass',{}, ...
    'singular_values',{},'factor_pass',{},'plus_overlap',{}, ...
    'minus_overlap',{},'elapsed_seconds',{});
  factor_rows = LOCAL_empty_factor_rows();
  layers = struct('layer',{},'interval',{},'spacing',{},'k_values',{}, ...
    'scores',{},'winner_index',{},'runner_up_index',{}, ...
    'winner_score',{},'runner_up_score',{},'runner_up_gap',{},'state',{});
  first_failure = LOCAL_failure('NONE','NONE',ntot,NaN,'','');
  candidate = []; peak_mib = 0;

  if ntot == 256
    score = LOCAL_score(seed);
    cache(1) = struct('k',seed.k,'node',seed,'score',score);
    node_rows(end+1) = LOCAL_node_summary(seed,ntot,score); %#ok<AGROW>
    factor_rows = [factor_rows;LOCAL_factor_rows(seed,ntot)]; %#ok<AGROW>
  end
  interval = [c.kstar-c.r0,c.kstar+c.r0];

  for layer = 0:c.locator_max_layer
    LOCAL_resource_gate(timer,peak_mib,c);
    h = (interval(2)-interval(1))/4;
    kvals = [interval(1),interval(1)+h,interval(1)+2*h, ...
      interval(1)+3*h,interval(2)];
    entries = repmat(struct('k',NaN,'node',struct(),'score',struct()),1,5);
    for j = 1:5
      index = LOCAL_cache_index(cache,kvals(j));
      if isempty(index)
        try
          node = eval_i21('point',kvals(j),lc,frame);
          LOCAL_node_gate(node,kvals(j),ntot,frame,c);
        catch ME
          if LOCAL_scientific_exception(ME)
            first_failure = LOCAL_failure('SCIENTIFIC_NODE_GATE','LOCATOR', ...
              ntot,kvals(j),ME.message,ME.identifier);
            locator = LOCAL_locator_result(false,ntot,interval,h,node_rows, ...
              factor_rows,layers,first_failure,NaN,NaN,NaN,NaN);
            return;
          end
          rethrow(ME);
        end
        score = LOCAL_score(node);
        cache(end+1) = struct('k',node.k,'node',node,'score',score); %#ok<AGROW>
        index = numel(cache);
        node_rows(end+1) = LOCAL_node_summary(node,ntot,score); %#ok<AGROW>
        factor_rows = [factor_rows;LOCAL_factor_rows(node,ntot)]; %#ok<AGROW>
        peak_mib = max(peak_mib,LOCAL_mib(frame,seed,cache,retained));
        LOCAL_resource_gate(timer,peak_mib,c);
      end
      entries(j) = cache(index);
    end

    values = arrayfun(@(x) x.score.s1,entries);
    [ordered,order] = sort(values,'ascend');
    winner = order(1); runner = order(2); gap = ordered(2)-ordered(1);
    if gap <= c.score_tie_min
      state = 'TIE';
    elseif winner == 1 || winner == 5
      state = 'ENDPOINT';
    else
      state = 'INTERIOR';
    end
    layers(end+1) = struct('layer',layer,'interval',interval, ...
      'spacing',h,'k_values',kvals,'scores',values, ...
      'winner_index',winner,'runner_up_index',runner, ...
      'winner_score',ordered(1),'runner_up_score',ordered(2), ...
      'runner_up_gap',gap,'state',state); %#ok<AGROW>

    if strcmp(state,'TIE')
      first_failure = LOCAL_failure('CANDIDATE_TIE','LOCATOR',ntot, ...
        entries(winner).k,'The score runner-up gap was at most 1e-12.','');
      locator = LOCAL_locator_result(false,ntot,interval,h,node_rows, ...
        factor_rows,layers,first_failure,winner,runner,ordered(1),gap);
      return;
    elseif strcmp(state,'ENDPOINT')
      first_failure = LOCAL_failure('CANDIDATE_ENDPOINT','LOCATOR',ntot, ...
        entries(winner).k,'The grid minimum reached a frozen window endpoint.','');
      locator = LOCAL_locator_result(false,ntot,interval,h,node_rows, ...
        factor_rows,layers,first_failure,winner,runner,ordered(1),gap);
      return;
    end

    next_interval = [entries(winner-1).k,entries(winner+1).k];
    if h <= c.locator_spacing_max
      [candidate,code,message] = LOCAL_candidate(entries(winner).node, ...
        ntot,next_interval,h,layer,ordered(1),ordered(2),gap,c);
      if ~candidate.pass
        first_failure = LOCAL_failure(code,'CANDIDATE',ntot,candidate.k,message,'');
        locator = LOCAL_locator_result(false,ntot,next_interval,h,node_rows, ...
          factor_rows,layers,first_failure,winner,runner,ordered(1),gap);
        return;
      end
      if numel(node_rows) ~= 27
        first_failure = LOCAL_failure('CANDIDATE_UNRESOLVED','LOCATOR',ntot, ...
          candidate.k,'The locator did not evaluate exactly 27 unique nodes.','');
        locator = LOCAL_locator_result(false,ntot,next_interval,h,node_rows, ...
          factor_rows,layers,first_failure,winner,runner,ordered(1),gap);
        return;
      end
      locator = LOCAL_locator_result(true,ntot,next_interval,h,node_rows, ...
        factor_rows,layers,first_failure,winner,runner,ordered(1),gap);
      return;
    end
    interval = next_interval;
    cache = entries(winner-1:winner+1);
  end

  first_failure = LOCAL_failure('CANDIDATE_UNRESOLVED','LOCATOR',ntot,NaN, ...
    'The locator did not reach the frozen terminal spacing.','');
  locator = LOCAL_locator_result(false,ntot,interval,NaN,node_rows, ...
    factor_rows,layers,first_failure,NaN,NaN,NaN,NaN);
end

function index = LOCAL_cache_index(cache,k)
  index = [];
  if isempty(cache), return; end
  distances = abs([cache.k]-k);
  found = find(distances <= 10*eps(max(1,abs(k))),1);
  if ~isempty(found), index = found; end
end

function out = LOCAL_locator_result(pass,ntot,interval,h,node_rows, ...
    factor_rows,layers,failure,winner,runner,winner_score,gap)
  runner_score = NaN;
  if ~isempty(layers), runner_score = layers(end).runner_up_score; end
  out = struct('pass',logical(pass),'ntot',ntot,'terminal_interval',interval, ...
    'localization_uncertainty',h,'unique_node_count',numel(node_rows), ...
    'node_rows',node_rows,'factor_rows',factor_rows,'layers',layers, ...
    'terminal_winner_index',winner,'terminal_runner_up_index',runner, ...
    'terminal_winner_score',winner_score, ...
    'terminal_runner_up_score',runner_score,'terminal_runner_up_gap',gap, ...
    'first_failure',failure);
end

function score = LOCAL_score(node)
  B = LOCAL_physical_matrix(node);
  physical = svd(B,'econ');
  if numel(physical) < 2 || any(~isfinite(physical)) || ...
      physical(1) <= 0 || physical(end-1) <= 0
    error('i23:ScientificNodeGate', ...
      'The physical singular spectrum is unavailable or nonfinite.');
  end
  score = struct('s1',physical(end)/physical(1), ...
    'r12',physical(end)/physical(end-1), ...
    'sigma1',physical(end),'sigma2',physical(end-1), ...
    'sigmamax',physical(1),'singular_values',flipud(physical));
end

function [B,wr,wc] = LOCAL_physical_matrix(node)
  b = sqrt(1+abs(node.beta_m(:)).^2);
  wr = repmat(sqrt(1./b),2,1);
  wc = repmat(1./sqrt(b+abs(node.gamma(:)).^2./b),2,1);
  B = wr.*node.AdefD.*wc.';
end

function row = LOCAL_node_summary(node,ntot,score)
  row = struct('ntot',ntot,'k',node.k,'s1',score.s1,'r12',score.r12, ...
    'node_pass',logical(node.pass),'singular_values',score.singular_values, ...
    'factor_pass',all([node.factors.pass]), ...
    'plus_overlap',LOCAL_field(node.plus,'overlap',1), ...
    'minus_overlap',LOCAL_field(node.minus,'overlap',1), ...
    'elapsed_seconds',node.elapsed_seconds);
end

function rows = LOCAL_empty_factor_rows()
  rows = struct('ntot',{},'k',{},'name',{},'rcond',{},'residual',{}, ...
    'available',{},'rcond_min',{},'residual_max',{},'pass',{});
end

function rows = LOCAL_factor_rows(node,ntot)
  rows = LOCAL_empty_factor_rows();
  for j = 1:numel(node.factors)
    f = node.factors(j);
    rows(end+1,1) = struct('ntot',ntot,'k',node.k,'name',f.name, ...
      'rcond',f.rcond,'residual',f.residual,'available',f.available, ...
      'rcond_min',f.rcond_min,'residual_max',f.residual_max,'pass',f.pass); %#ok<AGROW>
  end
end

function LOCAL_node_gate(node,k,ntot,frame,c)
  ok = node.k == k && strcmp(node.name,'fine') && node.spec.ntot == ntot && ...
    node.spec.N_side == 160 && node.spec.N_top == 160 && ...
    node.spec.N_proxy_edge == 80 && node.spec.M_pw == 32 && node.pass && ...
    node.plus.pass && node.minus.pass && node.branch_port.pass && ...
    node.branch_proxy.pass && node.cp.safe && node.cm.safe && ...
    all([node.factors.available]) && all([node.factors.pass]) && ...
    isequal(node.proxy_shape,[960,450]) && ...
    isequal(node.proxy_shifted_shape,[1920,450]) && ...
    isequal(size(node.R),[260,260]) && ...
    isequal(size(node.Aqp),[2*ntot,2*ntot]) && ...
    isequal(size(node.pair.A),[194,194]) && ...
    isequal(size(node.AdefD),[194,194]) && ...
    isequal(size(node.AdefG),[388,388]) && ...
    isequal(node.H_plus_rows,frame.rows_plus) && ...
    isequal(node.H_minus_rows,frame.rows_minus) && ...
    isequal(size(frame.seed_Z_plus),[194,97]) && ...
    isequal(size(frame.seed_Z_minus),[194,97]) && ...
    isequal(size(frame.Z0_plus),[194,97]) && ...
    isequal(size(frame.Z0_minus),[194,97]) && ...
    frame.proxy_chart.r == 260 && ...
    strcmp(node.plus.plane,'LEFT_CELL_WALL') && ...
    strcmp(node.minus.plane,'RIGHT_CELL_WALL') && ...
    strcmp(node.branch_port.fingerprint,frame.port_anchor.fingerprint) && ...
    strcmp(node.branch_proxy.fingerprint,frame.proxy_chart.anchor.fingerprint) && ...
    strcmp(node.proxy_chart.fingerprint,frame.proxy_chart.fingerprint) && ...
    all(isfinite(node.AdefD(:))) && all(isfinite(node.AdefG(:)));
  if ~ok
    error('i23:ScientificNodeGate', ...
      'The frozen node/object gate failed at ntot=%d, k=%.17g.',ntot,k);
  end
  if c.expected.proxy_rank ~= frame.proxy_chart.r
    error('i23:ScientificNodeGate','The frozen proxy rank changed.');
  end
end

function yes = LOCAL_scientific_exception(ME)
  id = ME.identifier;
  yes = startsWith(id,'i21:') || startsWith(id,'kready:') || ...
    startsWith(id,'kreadyv2:') || strcmp(id,'i23:ScientificNodeGate');
end

%% ==================== Candidate diagnostics ====================
% These helpers map the physical singular vector back to raw port coordinates.

function [candidate,code,message] = LOCAL_candidate(node,ntot,interval,u_loc, ...
    layer,winner_score,runner_score,runner_gap,c)
  [B,wr,wc] = LOCAL_physical_matrix(node);
  [U,S,V] = svd(B,'econ'); singular = diag(S);
  u1 = U(:,end); v1 = V(:,end); v2 = V(:,end-1);
  sigma1 = singular(end); sigma2 = singular(end-1); sigmamax = singular(1);
  A = node.AdefD; q = wc.*v1; ell = wr.*u1;
  right_abs = norm(A*q,2); left_abs = norm(ell'*A,2);
  anorm = max(realmin,norm(A,2));
  right_backward = right_abs/max(realmin,anorm*norm(q,2));
  left_backward = left_abs/max(realmin,anorm*norm(ell,2));
  svd_residual = max(norm(B*v1-sigma1*u1,2), ...
    norm(B'*u1-sigma1*v1,2))/max(realmin,sigmamax);

  K = c.K; I = eye(K); E = diag(node.phase(:));
  cminus = node.Dm\([I,E]*q); cplus = node.Dp\([E,I]*q);
  z = [q;cminus;cplus];
  drow = [1:K,2*K+1:3*K]; nrow = [K+1:2*K,3*K+1:4*K];
  Gd = node.AdefG(drow,:); Gn = node.AdefG(nrow,:);
  dirichlet = norm(Gd*z,2)/max(1,norm(Gd,2)*norm(z,2));
  neumann = norm(Gn*z-A*q,2)/max(1, ...
    norm(Gn,2)*norm(z,2)+anorm*norm(q,2));
  kernel = norm(node.AdefG*z,2)/max(1,norm(node.AdefG,'fro')*norm(z,2));
  center = min(norm(q(1:K)),norm(q(K+1:end)))/max(realmin,norm(q));
  graph = min(norm(cminus),norm(cplus))/max(realmin,norm(z));
  mode1 = LOCAL_mode(q,node,c); mode2 = LOCAL_mode(wc.*v2,node,c);

  score_pass = winner_score <= c.score_max && sigma1/sigma2 <= c.r12_max;
  raw_pass = isfinite(right_backward) && isfinite(left_backward) && ...
    right_backward <= c.raw_backward_max && left_backward <= c.raw_backward_max;
  triplet_pass = isfinite(svd_residual) && svd_residual <= c.svd_residual_max;
  field_pass = mode1.available && center >= c.participation_min && ...
    graph >= c.participation_min && dirichlet <= c.lift_residual_tol && ...
    neumann <= c.lift_residual_tol;
  pass = score_pass && raw_pass && triplet_pass && field_pass;
  code = 'NONE'; message = '';
  if ~(score_pass && raw_pass && triplet_pass)
    code = 'CANDIDATE_NEAR_NULL';
    message = 'A score, separation, SVD, or raw backward gate failed.';
  elseif ~field_pass
    code = 'CANDIDATE_FIELD_BOUNDARY';
    message = 'A physical participation or graph-boundary gate failed.';
  end

  candidate = struct('pass',pass,'ntot',ntot,'k',node.k, ...
    'terminal_layer',layer,'localization_interval',interval, ...
    'localization_uncertainty',u_loc,'winner_score',winner_score, ...
    'runner_up_score',runner_score,'runner_up_gap',runner_gap, ...
    'AdefD',A,'AdefG',node.AdefG,'Aphys',B, ...
    'beta_m',node.beta_m,'gamma',node.gamma,'phase',node.phase, ...
    'row_weight',wr,'column_weight',wc, ...
    'sigma1',sigma1,'sigma2',sigma2,'sigmamax',sigmamax, ...
    'singular_values',flipud(singular), ...
    's1',sigma1/sigmamax,'r12',sigma1/sigma2, ...
    'u1',u1,'v1',v1,'v2',v2,'q',q,'left_covector',ell, ...
    'raw_right_residual',right_abs,'raw_left_residual',left_abs, ...
    'raw_right_backward',right_backward,'raw_left_backward',left_backward, ...
    'svd_triplet_residual',svd_residual,'cminus',cminus,'cplus',cplus, ...
    'lift',z,'center_participation',center,'graph_participation',graph, ...
    'dirichlet_defect',dirichlet,'neumann_defect',neumann, ...
    'kernel_defect',kernel,'mode1',mode1,'mode2',mode2, ...
    'factors',node.factors,'row',node.row,'signature',LOCAL_signature(node));
end

function mode = LOCAL_mode(q,node,c)
  K = c.K; qL = q(1:K); qR = q(K+1:end);
  b = sqrt(1+abs(node.beta_m(:)).^2);
  dL = qL+node.phase(:).*qR; dR = node.phase(:).*qL+qR;
  trace = [sqrt(b).*dL;sqrt(b).*dR];
  probes = zeros(numel(c.probe_x),1);
  for j = 1:numel(probes)
    x = c.probe_x(j); y = c.probe_y(j);
    basis = exp(1i*node.beta_m(:)*y)/sqrt(c.d);
    right = exp(1i*node.gamma(:)*(x-c.X_L));
    left = exp(-1i*node.gamma(:)*(x-c.X_R));
    probes(j) = sum((qL.*right+qR.*left).*basis);
  end
  qnorm = norm(q,2);
  trace_ratio = norm(trace,2)/max(realmin,qnorm);
  probe_ratio = norm(probes,2)/max(realmin,qnorm);
  available = qnorm > realmin && all(isfinite(q)) && ...
    all(isfinite(trace)) && all(isfinite(probes)) && ...
    trace_ratio >= c.participation_min && probe_ratio >= c.participation_min;
  mode = struct('q',q,'wall_left',dL,'wall_right',dR, ...
    'weighted_wall_trace',trace,'probe_x',c.probe_x,'probe_y',c.probe_y, ...
    'probe_field',probes,'trace_ratio',trace_ratio, ...
    'probe_ratio',probe_ratio,'available',available);
end

function out = LOCAL_signature(node)
  out = struct('spec',node.spec,'proxy_shape',node.proxy_shape, ...
    'proxy_shifted_shape',node.proxy_shifted_shape,'Aqp_shape',node.Aqp_shape, ...
    'pair_shape',size(node.pair.A),'AdefD_shape',size(node.AdefD), ...
    'AdefG_shape',size(node.AdefG),'rows_plus',node.H_plus_rows, ...
    'rows_minus',node.H_minus_rows, ...
    'port_fingerprint',node.branch_port.fingerprint, ...
    'proxy_branch_fingerprint',node.branch_proxy.fingerprint, ...
    'proxy_chart_fingerprint',node.proxy_chart.fingerprint);
end

function [repeat,peak_mib] = ...
    LOCAL_repeat(candidate,c,frame,seed,timer,retained)
  ntot = candidate.ntot; lc = LOCAL_level_config(c,ntot); peak_mib = 0;
  try
    node = eval_i21('point',candidate.k,lc,frame);
    LOCAL_node_gate(node,candidate.k,ntot,frame,c);
  catch ME
    if LOCAL_scientific_exception(ME)
      failure = LOCAL_failure('CANDIDATE_REPEAT','REPEAT',ntot, ...
        candidate.k,ME.message,ME.identifier);
      repeat = struct('pass',false,'ntot',ntot,'k',candidate.k, ...
        'matrix_relative_difference',Inf,'score_difference',Inf, ...
        'q_overlap',NaN,'factor_pattern_same',false, ...
        'ranking_stability_claim',false,'first_failure',failure);
      return;
    end
    rethrow(ME);
  end
  score = LOCAL_score(node);
  [other,~,~] = LOCAL_candidate(node,ntot,candidate.localization_interval, ...
    candidate.localization_uncertainty,candidate.terminal_layer,score.s1, ...
    candidate.runner_up_score,candidate.runner_up_gap,c);
  matrix_difference = norm(other.AdefD-candidate.AdefD,'fro')/ ...
    max(1,norm(candidate.AdefD,'fro'));
  score_difference = abs(other.s1-candidate.s1);
  [q_overlap,q_available] = LOCAL_overlap(candidate.q,other.q,0,0);
  pattern_same = LOCAL_factor_pattern(candidate.factors,other.factors) && ...
    isequal(candidate.signature,other.signature);
  pass = other.pass && matrix_difference <= c.repeat_matrix_max && ...
    score_difference <= c.repeat_score_max && q_available && ...
    q_overlap >= c.repeat_overlap_min && pattern_same;
  failure = LOCAL_failure('NONE','NONE',ntot,candidate.k,'','');
  if ~pass
    failure = LOCAL_failure('CANDIDATE_REPEAT','REPEAT',ntot,candidate.k, ...
      'A fixed-candidate repeat gate failed.','');
  end
  repeat = struct('pass',pass,'ntot',ntot,'k',candidate.k, ...
    'AdefD',other.AdefD,'matrix_relative_difference',matrix_difference, ...
    's1',other.s1,'score_difference',score_difference, ...
    'q',other.q,'q_overlap',q_overlap,'factor_pattern_same',pattern_same, ...
    'factors',other.factors,'ranking_stability_claim',false, ...
    'repeat_scope','FIXED_CANDIDATE_ONLY_NOT_RANKING_STABILITY', ...
    'first_failure',failure);
  peak_mib = LOCAL_mib(frame,seed,retained,repeat);
  LOCAL_resource_gate(timer,peak_mib,c);
end

function same = LOCAL_factor_pattern(a,b)
  same = numel(a) == numel(b);
  if ~same, return; end
  same = isequal({a.name},{b.name}) && ...
    isequal(logical([a.available]),logical([b.available])) && ...
    isequal(logical([a.pass]),logical([b.pass]));
end

%% ==================== Mode identity and drift ====================
% These helpers compare only common physical representations and uncertainties.

function out = LOCAL_identity(a,b,c,hard_gate)
  ma = a.mode1; mb = b.mode1; sa = a.mode2; sb = b.mode2;
  [trace_overlap,trace_available] = LOCAL_overlap( ...
    ma.weighted_wall_trace,mb.weighted_wall_trace,0,0);
  [probe_overlap,probe_available] = LOCAL_overlap( ...
    ma.probe_field,mb.probe_field,0,0);
  [q_overlap,q_available] = LOCAL_overlap(ma.q,mb.q,0,0);
  second_available = sa.available && sb.available;
  switch_values = NaN(1,4);
  switch_available = false;
  if second_available
    [switch_values(1),a1] = LOCAL_overlap( ...
      ma.weighted_wall_trace,sb.weighted_wall_trace,0,0);
    [switch_values(2),a2] = LOCAL_overlap( ...
      sa.weighted_wall_trace,mb.weighted_wall_trace,0,0);
    [switch_values(3),a3] = LOCAL_overlap(ma.probe_field,sb.probe_field,0,0);
    [switch_values(4),a4] = LOCAL_overlap(sa.probe_field,mb.probe_field,0,0);
    switch_available = a1 && a2 && a3 && a4;
  end
  if switch_available, switch_overlap = max(switch_values);
  else, switch_overlap = 1; end
  primary_pass = trace_available && probe_available && ...
    trace_overlap >= c.identity_overlap_min && ...
    probe_overlap >= c.identity_overlap_min;
  pass = primary_pass && second_available && switch_available && ...
    switch_overlap <= c.competitor_overlap_max;

  inner = ma.weighted_wall_trace'*mb.weighted_wall_trace;
  if isfinite(inner) && abs(inner) > realmin
    phase = conj(inner)/abs(inner);
  else
    phase = NaN;
  end
  if pass
    status = 'SAME_MODE';
  elseif second_available && switch_available && ...
      switch_overlap > c.competitor_overlap_max
    status = 'MODE_SWITCH';
  else
    status = 'MODE_IDENTITY_UNRESOLVED';
  end
  out = struct('ntot_low',a.ntot,'ntot_high',b.ntot, ...
    'hard_gate',logical(hard_gate),'status',status,'pass',pass, ...
    'trace_overlap',trace_overlap,'probe_overlap',probe_overlap, ...
    'q_overlap',q_overlap,'q_overlap_available',q_available, ...
    'second_low_available',sa.available,'second_high_available',sb.available, ...
    'switch_overlaps',switch_values,'switch_overlap',switch_overlap, ...
    'phase_alignment',phase,'aligned_high_q',phase*mb.q, ...
    'aligned_high_trace',phase*mb.weighted_wall_trace, ...
    'aligned_high_probe_field',phase*mb.probe_field);
end

function [rho,available] = LOCAL_overlap(x,y,min_x,min_y)
  nx = norm(x,2); ny = norm(y,2);
  available = all(isfinite(x(:))) && all(isfinite(y(:))) && ...
    isfinite(nx) && isfinite(ny) && nx >= max(realmin,min_x) && ...
    ny >= max(realmin,min_y);
  if available, rho = abs(x(:)'*y(:))/(nx*ny); else, rho = NaN; end
end

function out = LOCAL_drift(a,b,c)
  delta = b.k-a.k; magnitude = abs(delta);
  uncertainty = a.localization_uncertainty+b.localization_uncertainty;
  ratio = magnitude/max(realmin,uncertainty);
  if magnitude <= uncertainty
    classification = 'DRIFT_UNRESOLVED'; resolved = false; direction = 'UNRESOLVED';
  elseif magnitude <= c.severity_scale
    classification = 'DRIFT_RESOLVED_SUBTARGET'; resolved = true;
    direction = LOCAL_direction(delta);
  else
    classification = 'DRIFT_RESOLVED_SEVERE'; resolved = true;
    direction = LOCAL_direction(delta);
  end
  out = struct('ntot_low',a.ntot,'ntot_high',b.ntot,'delta',delta, ...
    'magnitude',magnitude,'combined_uncertainty',uncertainty, ...
    'signed_interval',[delta-uncertainty,delta+uncertainty], ...
    'magnitude_to_uncertainty',ratio,'classification',classification, ...
    'resolved',resolved,'direction',direction);
end

function out = LOCAL_direction(delta)
  if delta > 0, out = 'POSITIVE'; elseif delta < 0, out = 'NEGATIVE';
  else, out = 'ZERO'; end
end

function trend = LOCAL_trend(a,b)
  if ~(a.resolved && b.resolved)
    trend = 'TREND_UNRESOLVED';
  elseif sign(a.delta) == sign(b.delta)
    trend = 'MONOTONE';
  else
    trend = 'NONMONOTONE';
  end
end

%% ==================== Result, resources, and report ====================
% These helpers publish one compact append-only MAT/report pair.

function result = LOCAL_result(attempt,status,execution_pass,outcome, ...
    hierarchy,i3_may,i3_status,trend,elapsed,peak,c,rows,runtime,oracle, ...
    seed,locators,candidates,repeats,identities,drifts,failure)
  count_context = struct('status','CONDITIONAL_EMPIRICAL_COUNT_ONE', ...
    'applies_only_ntot',256,'ntot160','NOT_ESTABLISHED', ...
    'ntot208','NOT_ESTABLISHED','ntot256','ATTACHED_FROM_I2_1', ...
    'transferred_to_other_levels',false);
  command = ['matlab -batch "addpath(fullfile(pwd,''test'',''i2'',' ...
    '''k-drift''),fullfile(pwd,''test'',''i2'',''k-count'')); ' ...
    'check_k_drift(''drift-a1'');"'];
  result = struct('schema',c.schema,'experiment_id',c.experiment_id, ...
    'design_id',c.design_id,'attempt',attempt,'status',status, ...
    'execution_pass',logical(execution_pass),'scientific_outcome',outcome, ...
    'hierarchy_qualified',logical(hierarchy), ...
    'i3_may_proceed',logical(i3_may),'i3_status',i3_status,'trend',trend, ...
    'claim_boundary',c.claim_boundary,'axis',c.axis, ...
    'finite_root_claim',false,'continuous_mode_claim',false, ...
    'convergence_order_claim',false,'error_bound_claim',false, ...
    'elapsed_seconds',elapsed,'peak_active_mib',peak, ...
    'target_seconds',c.target_seconds,'hard_seconds',c.hard_seconds, ...
    'memory_mib_max',c.memory_mib_max,'config',c,'selectors',rows, ...
    'runtime',runtime,'identity_oracle',oracle,'seed_summary',seed, ...
    'i21_count_context',count_context,'locators',{locators}, ...
    'candidates',{candidates},'repeats',{repeats}, ...
    'identities',{identities},'drifts',{drifts}, ...
    'first_failure',failure,'command',command, ...
    'output_files',{{'result.mat','report.md'}}, ...
    'runtime_reads_git_docs_history_or_hashes',false);
end

function [code,stage] = LOCAL_exception_class(ME)
  if LOCAL_scientific_exception(ME)
    code = 'SCIENTIFIC_NODE_GATE'; stage = 'SEED';
  elseif strcmp(ME.identifier,'i23:HARD_TIME')
    code = 'HARD_TIME'; stage = 'RESOURCE';
  elseif strcmp(ME.identifier,'i23:MEMORY')
    code = 'MEMORY'; stage = 'RESOURCE';
  elseif strcmp(ME.identifier,'i23:IdentityOracle')
    code = 'IDENTITY_ORACLE_FAIL'; stage = 'ORACLE';
  elseif startsWith(ME.identifier,'i23:Runtime') || ...
      startsWith(ME.identifier,'i23:Config')
    code = 'RUNTIME_OR_CONFIG_FAIL'; stage = 'PREFLIGHT';
  else
    code = 'IMPLEMENTATION_ERROR'; stage = 'UNLISTED';
  end
end

function out = LOCAL_failure(code,stage,ntot,k,message,identifier)
  out = struct('code',code,'stage',stage,'ntot',ntot,'k',k, ...
    'message',message,'identifier',identifier);
end

function LOCAL_resource_gate(timer,peak_mib,c)
  if toc(timer) > c.hard_seconds
    error('i23:HARD_TIME','The frozen 1800 second hard limit was exceeded.');
  end
  if peak_mib > c.memory_mib_max
    error('i23:MEMORY','The frozen 512 MiB active-object limit was exceeded.');
  end
end

function mib = LOCAL_mib(varargin)
  bytes = 0;
  for j = 1:nargin
    item = varargin{j}; %#ok<NASGU>
    info = whos('item');
    bytes = bytes+info.bytes;
  end
  mib = bytes/2^20;
end

function value = LOCAL_field(s,name,fallback)
  if isstruct(s) && isfield(s,name), value = s.(name); else, value = fallback; end
end

function LOCAL_report(path,r)
  fid = fopen(path,'w');
  if fid < 0, error('i23:Report','Cannot open report.md.'); end
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid,'# I2.3 boundary-Nystrom candidate drift\n\n');
  fprintf(fid,'- Status: `%s`\n',r.status);
  fprintf(fid,'- Execution pass: `%d`\n',r.execution_pass);
  fprintf(fid,'- Scientific outcome: `%s`\n',r.scientific_outcome);
  fprintf(fid,'- Hierarchy qualified / I3 may proceed: `%d / %d`\n', ...
    r.hierarchy_qualified,r.i3_may_proceed);
  fprintf(fid,'- I3 status: `%s`\n',r.i3_status);
  fprintf(fid,'- Trend: `%s`\n',r.trend);
  fprintf(fid,'- Wall time / peak active snapshot: `%.6g s / %.6g MiB`\n', ...
    r.elapsed_seconds,r.peak_active_mib);
  fprintf(fid,'- Axis: `%s`\n',r.axis);
  fprintf(fid,'- Claim boundary: `%s`\n\n',r.claim_boundary);

  fprintf(fid,'## Runtime and fixed context\n\n');
  fprintf(fid,'The runner did not read or hash Git, documentation, history, or old output.\n\n');
  if isfield(r.runtime,'kind')
    fprintf(fid,'- Runtime / solver / precision: `%s / %s / %s`\n', ...
      r.runtime.kind,r.runtime.solver,r.runtime.precision);
  end
  fprintf(fid,['- I2.1 count one attaches only to `ntot=256`; ', ...
    '`ntot=160/208` counts are `NOT_ESTABLISHED`.\n']);
  fprintf(fid,'- Locator window: `[%.17g, %.17g]`\n', ...
    r.config.kstar-r.config.r0,r.config.kstar+r.config.r0);
  fprintf(fid,'- Fixed candidate score: `sigma_min(Aphys)/sigma_max(Aphys)`\n\n');

  fprintf(fid,'## Level results\n\n');
  fprintf(fid,'| ntot | locator | k | u_loc | s1 | r12 | terminal runner-up gap | repeat |\n');
  fprintf(fid,'|---:|---|---:|---:|---:|---:|---:|---|\n');
  for j = 1:3
    loc = r.locators{j}; cand = r.candidates{j}; rep = r.repeats{j};
    if isempty(loc), continue; end
    if isempty(cand)
      fprintf(fid,'| %d | FAIL | NaN | %.6g | NaN | NaN | %.6g | -- |\n', ...
        loc.ntot,loc.localization_uncertainty,loc.terminal_runner_up_gap);
    else
      repeat_text = '--'; if ~isempty(rep), repeat_text = LOCAL_pass_text(rep.pass); end
      fprintf(fid,'| %d | %s | %.17g | %.6g | %.6g | %.6g | %.6g | %s |\n', ...
        cand.ntot,LOCAL_pass_text(loc.pass),cand.k,cand.localization_uncertainty, ...
        cand.s1,cand.r12,cand.runner_up_gap,repeat_text);
    end
  end
  fprintf(fid,['\nRepeats test the fixed terminal candidate only; they do not ', ...
    'claim that the winner/runner-up ranking is stable.\n\n']);

  fprintf(fid,'## Mode identity\n\n');
  fprintf(fid,'| levels | status | wall overlap | probe overlap | competitor overlap | hard gate |\n');
  fprintf(fid,'|---|---|---:|---:|---:|---:|\n');
  for j = 1:3
    x = r.identities{j}; if isempty(x), continue; end
    fprintf(fid,'| %d--%d | %s | %.6g | %.6g | %.6g | %d |\n', ...
      x.ntot_low,x.ntot_high,x.status,x.trace_overlap,x.probe_overlap, ...
      x.switch_overlap,x.hard_gate);
  end

  fprintf(fid,'\n## Drift\n\n');
  fprintf(fid,'| levels | delta | abs(delta) | U | abs(delta)/U | classification |\n');
  fprintf(fid,'|---|---:|---:|---:|---:|---|\n');
  for j = 1:3
    x = r.drifts{j}; if isempty(x), continue; end
    fprintf(fid,'| %d--%d | %.17g | %.6g | %.6g | %.6g | %s |\n', ...
      x.ntot_low,x.ntot_high,x.delta,x.magnitude,x.combined_uncertainty, ...
      x.magnitude_to_uncertainty,x.classification);
  end

  fprintf(fid,'\n## First failure\n\n');
  fprintf(fid,'- Code / stage: `%s / %s`\n', ...
    r.first_failure.code,r.first_failure.stage);
  if ~isempty(r.first_failure.message)
    fprintf(fid,'- Message: `%s`\n',strrep(r.first_failure.message,'`',''''));
  end
  fprintf(fid,'\n## Interpretation boundary\n\n');
  fprintf(fid,['This report concerns three conditional finite-dimensional ', ...
    'real-axis candidates under one boundary-Nystrom axis. It does not establish ', ...
    'an exact finite root, a continuous guided mode, convergence order, error ', ...
    'attribution, an estimator, or an upper bound. `DRIFT_UNRESOLVED` leaves ', ...
    'the hierarchy unqualified and stops I3.\n\n']);
  fprintf(fid,'Registered command:\n\n```sh\n%s\n```\n',r.command);
end

function text = LOCAL_pass_text(pass)
  if pass, text = 'PASS'; else, text = 'FAIL'; end
end
