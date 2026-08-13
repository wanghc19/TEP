function result = run_i21(mode)
%RUN_I21 Run the frozen I2.1 Method 1B smoke or full campaign.
% Purpose:
%   Preserve append-only evidence while qualifying the frozen fine-M48
%   evaluator, every inverse factor, the Riesz fixed-chart screen, and the
%   determinant winding required for one conditional empirical root count.
% Input:
%   mode - 'smoke' or 'full'.  Full is a separate invocation after review.
% Output:
%   result - Compact ledgers and verdict saved under the frozen output tag.
% Main algorithm:
%   Run non-circular manufactured oracles through the production cores,
%   verify immutable parents, stream the physical contour, apply two-axis
%   Riesz guards, then evaluate nested factor and AdefD windings.
% Based on:
%   test/i1/k-ready/run_v4.m, run_v5.m, and the reviewed I2.1 design.
% Main changes:
%   MATLAB-only fine-level count with explicit zero/pole separation, no
%   locator, root refinement, derivative, or estimator.
% Numerical goal:
%   Decide whether the registered disk contains exactly one determinant zero.

  if nargin ~= 1, error('i21:Mode','run_i21 requires smoke or full.'); end
  c = cfg_i21(mode);
  if strcmp(c.mode,'full') && ~c.full_authorized
    error('i21:FullNotAuthorized', ...
      'Full has no reviewed output tag or accepted smoke-a2 parent hash.');
  end
  here = fileparts(mfilename('fullpath'));
  repo = fileparts(fileparts(fileparts(here)));
  addpath(repo); addpath(here);
  output = fullfile(here,c.output_relative);
  if exist(output,'dir') || exist(output,'file')
    error('i21:OutputExists','Append-only output already exists: %s.',output);
  end
  mkdir(output);
  diary(fullfile(output,'run.log'));
  diary_cleanup = onCleanup(@() diary('off')); %#ok<NASGU>
  fprintf('Command context: run_i21(''%s'')\n',c.mode);
  fprintf('Output relative path: %s\n',c.output_relative);
  campaign_timer = tic;

  ledgers = LOCAL_empty_ledgers();
  config_rows = LOCAL_config_rows(c);
  source_rows = LOCAL_empty_sources();
  provenance_rows = LOCAL_empty_key_values();
  lineage_rows = LOCAL_empty_lineage();
  first_failure = '';
  caught = [];
  status = 'I2_1_INCOMPLETE';
  pass = false;
  scientific_count = NaN;
  projected_full_seconds = NaN;
  projected_fixed_seconds = NaN;
  projected_node_seconds = NaN;
  projected_edge_seconds = NaN;
  smoke_edge_probe_seconds = NaN;
  smoke_edge_probe_count = 0;
  peak_active_mib = NaN;
  checkpoint_count = 0;
  formal_parent_seconds = 0;
  formal_external_startup_seconds = 0;
  formal_failed_smoke_seconds = 0;
  formal_accepted_smoke_seconds = 0;
  source_digest = '';
  if strcmp(c.mode,'full')
    formal_external_startup_seconds = c.external_startup_seconds;
    formal_failed_smoke_seconds = c.failed_smoke_seconds;
    formal_accepted_smoke_seconds = c.accepted_smoke_seconds;
    formal_parent_seconds = c.formal_prior_seconds;
  end

  try
    % --- stage 1: runtime, source, and non-circular core oracles ---
    [source_rows,provenance_rows,source_digest] = ...
      LOCAL_provenance(here,repo,c);
    fprintf('Source digest: %s\n',source_digest);
    LOCAL_csv(fullfile(output,'source-manifest.csv'),source_rows);
    solver_path = which('lsqminnorm');
    if exist('OCTAVE_VERSION','builtin') ~= 0 || isempty(solver_path) || ...
        ~startsWith(solver_path,matlabroot)
      error('i21:MATLABRequired','MATLAB with public lsqminnorm is required.');
    end
    ledgers.objects = LOCAL_expected_object_rows(c);
    object_config_pass = all([ledgers.objects.pass]);
    ledgers.gates(end+1) = LOCAL_gate(1,'RUNTIME_SOURCE_SOLVER',true,1,1, ...
      'MATLAB, public lsqminnorm, source manifest, and configuration recorded');
    ledgers.gates(end+1) = LOCAL_gate(1,'FROZEN_OBJECT_LEDGER', ...
      object_config_pass,sum([ledgers.objects.pass]),numel(ledgers.objects), ...
      'fine-M48 matrix roles and dimensions are registered before oracles');
    if ~object_config_pass
      error('i21:DimensionDrift','Frozen configuration object ledger failed.');
    end
    [ledgers.oracles,oracle_edges,oracle_pass] = LOCAL_oracles(c);
    ledgers.phase_edges = [ledgers.phase_edges;oracle_edges];
    for j = 1:numel(ledgers.oracles)
      oracle = ledgers.oracles(j);
      name = sprintf('ORACLE_%s_N%d',oracle.name,oracle.grid);
      ledgers.gates(end+1) = LOCAL_gate(2,name,oracle.pass, ...
        oracle.error,oracle.tolerance,'analytic answer through production core'); %#ok<AGROW>
    end
    ledgers.gates(end+1) = LOCAL_gate(2,'MANUFACTURED_CORE_ORACLES', ...
      oracle_pass,double(oracle_pass),1,'all analytic cases use production cores');
    if ~oracle_pass
      error('i21:CoreOracle','A manufactured core oracle failed.');
    end

    % --- stage 2: exact frozen lineage and seed frame ---
    [parents,lineage_rows] = LOCAL_parents(repo,c);
    ledgers.gates(end+1) = LOCAL_gate(3,'FROZEN_PARENT_LINEAGE', ...
      all([lineage_rows.pass]),sum([lineage_rows.pass]),numel(lineage_rows), ...
      'all four frozen parent hashes and content gates match');
    if strcmp(c.mode,'full')
      [smoke,smoke_lineage] = LOCAL_smoke_parent(here,c);
      lineage_rows(end+1) = smoke_lineage;
      ledgers.gates(end+1) = LOCAL_gate(3,'ACCEPTED_SMOKE_PARENT',true,1,1, ...
        'artifact hash, producer digest, readiness, resources, and zero-call policy match');
      projected_full_seconds = smoke.projected_full_seconds;
    end
    selectors = struct('plus',parents.zoom.frame_rows_plus, ...
      'minus',parents.zoom.frame_rows_minus);
    [seed,frame] = eval_i21('seed',c,selectors);
    LOCAL_dimensions(seed,frame,c);
    actual_objects = LOCAL_object_rows(seed,frame,c);
    if ~all([actual_objects.pass]) || ...
        ~isequal({actual_objects.object},{ledgers.objects.object}) || ...
        ~isequal([actual_objects.rows],[ledgers.objects.rows]) || ...
        ~isequal([actual_objects.columns],[ledgers.objects.columns])
      error('i21:DimensionDrift','Runtime object ledger differs from configuration.');
    end
    ledgers.objects = actual_objects;
    ledgers.nodes(end+1) = LOCAL_node_row(seed,0,true);
    ledgers.health = [ledgers.health;LOCAL_health_rows(seed,0)];
    [seed_structural_pass,seed_failure] = LOCAL_seed_structural_pass(seed,c);
    if ~seed_structural_pass
      error(seed_failure,'The frozen fine seed failed a structural gate.');
    end
    seed_riesz = riesz_core('point',seed,frame,c,0);
    seed_riesz.resolvents = LOCAL_prefix_objects(seed_riesz.resolvents,'seed_');
    ledgers.resolvents = [ledgers.resolvents;seed_riesz.resolvents];
    seed_zeta_arcs = LOCAL_prefix_zeta_sides(seed_riesz.zeta_arcs,'seed_');
    ledgers.zeta_arcs = [ledgers.zeta_arcs;seed_zeta_arcs];
    seed_projectors = LOCAL_prefix_projector_sides( ...
      seed_riesz.projectors,'seed_');
    ledgers.projectors = [ledgers.projectors;seed_projectors];
    if ~seed_riesz.resolvent_pass
      error('i21:RieszSeed','The seed Riesz resolvent screen failed.');
    elseif ~seed_riesz.chart_pass
      error('i21:RieszChartSeed','The seed Riesz chart screen failed.');
    end
    seed_adef_rcond = rcond(seed.AdefD);
    [seed_det,~] = LOCAL_factor_rows(seed,seed_riesz,0,c);
    seed_det = LOCAL_prefix_objects(seed_det,'seed_');
    ledgers.factors = [ledgers.factors;seed_det];
    seed_required = ~strcmp({seed_det.object},'seed_AdefD');
    if ~all([seed_det(seed_required).available])
      error('i21:SeedFactor','A required seed factor failed.');
    end
    ledgers.gates(end+1) = LOCAL_gate(3,'SEED_ADEF_DIAGNOSTIC',true, ...
      seed_adef_rcond,NaN, ...
      'interior candidate matrix is recorded but never used as a separation gate');
    peak_active_mib = LOCAL_resource_checkpoint(campaign_timer,c, ...
      peak_active_mib,{seed,frame,seed_riesz,ledgers});
    checkpoint_count = checkpoint_count+1;
    ledgers.gates(end+1) = LOCAL_gate(3,'SEED_OBJECT_AND_FRAME',true,1,1, ...
      'fine dimensions, fixed rows, branch/QZ frame, and required seed factors pass');
    clear seed_riesz;

    % --- stage 3: stream registered physical nodes and adjacent edges ---
    previous_state = []; first_state = [];
    prephysical_seconds = toc(campaign_timer);
    physical_timer = tic;
    for q = 1:numel(c.physical_indices)
      LOCAL_time(campaign_timer,c);
      index = c.physical_indices(q);
      node = eval_i21('point',c.k_nodes(index),c,frame);
      ledgers.nodes(end+1) = LOCAL_node_row(node,index,false); %#ok<AGROW>
      ledgers.health = [ledgers.health;LOCAL_health_rows(node,index)]; %#ok<AGROW>
      peak_active_mib = LOCAL_resource_checkpoint(campaign_timer,c, ...
        peak_active_mib,{node,frame,previous_state,first_state,ledgers});
      checkpoint_count = checkpoint_count+1;
      if ~node.pass
        error('i21:BranchQZChartDrift', ...
          'Physical node %d failed inherited branch/QZ/chart gates.',index);
      end
      rz = riesz_core('point',node,frame,c,index);
      ledgers.resolvents = [ledgers.resolvents;rz.resolvents]; %#ok<AGROW>
      ledgers.zeta_arcs = [ledgers.zeta_arcs;rz.zeta_arcs]; %#ok<AGROW>
      ledgers.projectors = [ledgers.projectors;rz.projectors]; %#ok<AGROW>
      [factor_rows,~] = LOCAL_factor_rows(node,rz,index,c);
      ledgers.factors = [ledgers.factors;factor_rows]; %#ok<AGROW>
      peak_active_mib = LOCAL_resource_checkpoint(campaign_timer,c, ...
        peak_active_mib,{node,rz,previous_state,first_state,ledgers});
      checkpoint_count = checkpoint_count+1;
      if isempty(first_state), first_state = rz.state; end
      if strcmp(c.mode,'full') && ~isempty(previous_state)
        edge_rows = riesz_core('edge',previous_state,rz.state,c);
        ledgers.k_arcs = [ledgers.k_arcs;edge_rows]; %#ok<AGROW>
        peak_active_mib = LOCAL_resource_checkpoint(campaign_timer,c, ...
          peak_active_mib,{node,rz.state,previous_state,first_state, ...
          edge_rows,ledgers});
        checkpoint_count = checkpoint_count+1;
      elseif strcmp(c.mode,'smoke') && ~isempty(previous_state)
        edge_timer = tic;
        edge_rows = riesz_core('edge',previous_state,rz.state,c);
        edge_elapsed = toc(edge_timer);
        smoke_edge_probe_seconds = LOCAL_accumulate_time( ...
          smoke_edge_probe_seconds,edge_elapsed);
        smoke_edge_probe_count = smoke_edge_probe_count+1;
        edge_interface_pass = LOCAL_edge_interface_pass(edge_rows,c);
        ledgers.gates(end+1) = LOCAL_gate(2, ...
          sprintf('SMOKE_EDGE_WORKLOAD_PROBE_%02d',smoke_edge_probe_count), ...
          edge_interface_pass,edge_elapsed,NaN, ...
          'timing-only cardinal edge; no k-arc rows or 0.25 verdict');
        peak_active_mib = LOCAL_resource_checkpoint(campaign_timer,c, ...
          peak_active_mib,{node,rz.state,previous_state,first_state, ...
          edge_rows,ledgers});
        checkpoint_count = checkpoint_count+1;
        if ~edge_interface_pass
          error('i21:SmokeEdgeProbe', ...
            'A timing-only production edge interface failed.');
        end
      end
      previous_state = rz.state;
      clear node rz factor_rows;
    end
    if strcmp(c.mode,'full') && ~isempty(previous_state)
      edge_rows = riesz_core('edge',previous_state,first_state,c);
      ledgers.k_arcs = [ledgers.k_arcs;edge_rows];
      peak_active_mib = LOCAL_resource_checkpoint(campaign_timer,c, ...
        peak_active_mib,{previous_state,first_state,edge_rows,ledgers});
      checkpoint_count = checkpoint_count+1;
    elseif strcmp(c.mode,'smoke') && ~isempty(previous_state)
      % These four cardinal edges exercise only the production edge workload.
      % They never enter the scientific k-arc ledger, and their non-adjacent
      % Neumann ratios are never interpreted as guards.
      edge_timer = tic;
      edge_rows = riesz_core('edge',previous_state,first_state,c);
      edge_elapsed = toc(edge_timer);
      smoke_edge_probe_seconds = LOCAL_accumulate_time( ...
        smoke_edge_probe_seconds,edge_elapsed);
      smoke_edge_probe_count = smoke_edge_probe_count+1;
      edge_interface_pass = LOCAL_edge_interface_pass(edge_rows,c);
      ledgers.gates(end+1) = LOCAL_gate(2, ...
        sprintf('SMOKE_EDGE_WORKLOAD_PROBE_%02d',smoke_edge_probe_count), ...
        edge_interface_pass,edge_elapsed,NaN, ...
        'timing-only cardinal closure; no k-arc rows or 0.25 verdict');
      peak_active_mib = LOCAL_resource_checkpoint(campaign_timer,c, ...
        peak_active_mib,{previous_state,first_state,edge_rows,ledgers});
      checkpoint_count = checkpoint_count+1;
      if ~edge_interface_pass
        error('i21:SmokeEdgeProbe', ...
          'The timing-only production edge interface failed.');
      end
    end
    physical_seconds = toc(physical_timer);
    clear previous_state first_state edge_rows;
    physical_nodes = ledgers.nodes(~[ledgers.nodes.is_seed]);
    evaluator_pass = numel(physical_nodes) == numel(c.physical_indices) && ...
      all([physical_nodes.level_pass]);
    ledgers.gates(end+1) = LOCAL_gate(4,'PHYSICAL_EVALUATOR_NODES', ...
      evaluator_pass,numel(physical_nodes),numel(c.physical_indices), ...
      'all registered physical nodes preserve the inherited evaluator contract');
    if ~evaluator_pass
      error('i21:EvaluatorNodes','The physical evaluator ledger is incomplete.');
    end

    % --- stage 4: smoke timing stop or complete nested winding verdict ---
    if strcmp(c.mode,'smoke')
      workload_pass = smoke_edge_probe_count == c.smoke_edge_probe_count && ...
        isfinite(smoke_edge_probe_seconds) && smoke_edge_probe_seconds >= 0;
      ledgers.gates(end+1) = LOCAL_gate(2,'SMOKE_EDGE_WORKLOAD_COMPLETE', ...
        workload_pass,smoke_edge_probe_count,c.smoke_edge_probe_count, ...
        'four timing-only cardinal edges completed outside scientific k-arcs');
      if ~workload_pass
        error('i21:SmokeEdgeProbe', ...
          'The timing-only edge workload sample is incomplete.');
      end
      [smoke_pass,smoke_failure,smoke_gates] = LOCAL_smoke_gates(ledgers,c);
      ledgers.gates = [ledgers.gates(:);smoke_gates(:)];
      if ~smoke_pass
        error(['i21:',smoke_failure], ...
          'Smoke interface qualification failed: %s.',smoke_failure);
      end
      sampled_node_seconds = max(0,physical_seconds-smoke_edge_probe_seconds);
      projected_fixed_seconds = prephysical_seconds;
      projected_node_seconds = sampled_node_seconds* ...
        c.Nk_full/max(1,numel(c.physical_indices));
      projected_edge_seconds = smoke_edge_probe_seconds*c.full_edge_count/ ...
        max(1,smoke_edge_probe_count);
      projected_full_seconds = projected_fixed_seconds+ ...
        projected_node_seconds+projected_edge_seconds;
      timing_pass = projected_full_seconds <= c.full_projection_stop_seconds;
      ledgers.gates(end+1) = LOCAL_gate(2,'SMOKE_FULL_TIME_PROJECTION', ...
        timing_pass,projected_full_seconds,c.full_projection_stop_seconds, ...
        'fixed cost plus four-node and four-edge timing scaled to 64 nodes/edges');
      if ~timing_pass
        error('i21:ProjectedTime','Smoke projects full above the frozen stop.');
      end
      status = 'I2_1_M1B_SMOKE_PASS';
      pass = true;
    else
      LOCAL_time(campaign_timer,c);
      [ledgers.windings,winding_edges,scientific_count,wind_pass,wind_failure, ...
        winding_gates] = ...
        LOCAL_windings(ledgers,c);
      LOCAL_time(campaign_timer,c);
      ledgers.phase_edges = [ledgers.phase_edges;winding_edges];
      ledgers.gates = [ledgers.gates(:);winding_gates(:)];
      if ~wind_pass
        error(['i21:',wind_failure], ...
          'Nested factor/root winding gate failed: %s.',wind_failure);
      end
      if scientific_count == 1
        ledgers.gates(end+1) = LOCAL_gate(10,'FINAL_COUNT_ONE',true, ...
          scientific_count,1,'qualified finite-dimensional algebraic count');
        status = 'I2_1_PASS_WITH_CONDITIONS'; pass = true;
      elseif scientific_count == 0
        ledgers.gates(end+1) = LOCAL_gate(10,'FINAL_COUNT_ONE',false, ...
          scientific_count,1,'qualified zero count is a scientific result');
        error('i21:ZeroCount','The qualified scientific count is zero.');
      else
        ledgers.gates(end+1) = LOCAL_gate(10,'FINAL_COUNT_ONE',false, ...
          scientific_count,1,'qualified multiple count is a scientific result');
        error('i21:MultipleCount', ...
          'The qualified scientific count is %d.',scientific_count);
      end
    end
  catch exception
    caught = exception;
    first_failure = LOCAL_failure(exception.identifier);
    if strcmp(first_failure,'TIMEOUT_OR_RESOURCE_STOP')
      status = 'I2_1_RESOURCE_STOP';
    elseif strcmp(first_failure,'ZERO_COUNT')
      status = 'I2_1_ZERO_COUNT';
    elseif strcmp(first_failure,'MULTIPLE_COUNT')
      status = 'I2_1_MULTIPLE_COUNT';
    else
      status = 'I2_1_M1B_FAIL';
    end
    ledgers.failures(end+1) = struct('first_failure',first_failure, ...
      'identifier',exception.identifier,'message',exception.message, ...
      'elapsed_seconds',toc(campaign_timer));
  end

  % --- stage 5: mechanical finalization, including partial failures ---
  elapsed_seconds = toc(campaign_timer);
  if elapsed_seconds > c.hard_seconds && isempty(first_failure)
    pass = false; status = 'I2_1_RESOURCE_STOP';
    first_failure = 'TIMEOUT_OR_RESOURCE_STOP';
    ledgers.failures(end+1) = struct('first_failure',first_failure, ...
      'identifier','i21:HardTime','message','Hard time exceeded at finalization.', ...
      'elapsed_seconds',elapsed_seconds);
  end
  if formal_parent_seconds+elapsed_seconds > c.total_formal_seconds && ...
      isempty(first_failure)
    pass = false; status = 'I2_1_RESOURCE_STOP';
    first_failure = 'TIMEOUT_OR_RESOURCE_STOP';
    ledgers.failures(end+1) = struct('first_failure',first_failure, ...
      'identifier','i21:TotalFormalTime', ...
      'message','The frozen cumulative formal-run budget was exceeded.', ...
      'elapsed_seconds',elapsed_seconds);
  end
  try
    LOCAL_finalize_log(fullfile(output,'run.log'),c,source_digest, ...
      first_failure,caught);
  catch log_exception
    if isempty(first_failure)
      first_failure = 'NUMERICAL_INSTABILITY';
      status = 'I2_1_M1B_FAIL'; pass = false; scientific_count = NaN;
    end
    ledgers.failures(end+1) = struct('first_failure',first_failure, ...
      'identifier',log_exception.identifier,'message',log_exception.message, ...
      'elapsed_seconds',toc(campaign_timer));
    if isempty(caught), caught = log_exception; end
  end
  result = struct('schema',c.schema,'experiment_id',c.experiment_id, ...
    'design_id',c.design_id,'mode',c.mode,'status',status,'pass',pass, ...
    'first_failure',first_failure,'scientific_count',scientific_count, ...
    'elapsed_seconds',elapsed_seconds, ...
    'projected_full_seconds',projected_full_seconds, ...
    'projected_fixed_seconds',projected_fixed_seconds, ...
    'projected_node_seconds',projected_node_seconds, ...
    'projected_edge_seconds',projected_edge_seconds, ...
    'smoke_edge_probe_seconds',smoke_edge_probe_seconds, ...
    'smoke_edge_probe_count',smoke_edge_probe_count, ...
    'claim_boundary',c.claim_boundary,'oracles',ledgers.oracles, ...
    'nodes',ledgers.nodes,'health',ledgers.health, ...
    'factors',ledgers.factors,'resolvents',ledgers.resolvents, ...
    'zeta_arcs',ledgers.zeta_arcs,'k_arcs',ledgers.k_arcs, ...
    'projectors',ledgers.projectors,'windings',ledgers.windings, ...
    'phase_edges',ledgers.phase_edges,'gates',ledgers.gates, ...
    'failures',ledgers.failures,'lineage',lineage_rows, ...
    'provenance',provenance_rows,'configuration',config_rows, ...
    'objects',ledgers.objects,'source_digest',LOCAL_digest(source_rows), ...
    'implementation_digest',LOCAL_code_digest(source_rows), ...
    'locator_calls',0,'root_solver_calls',0,'derivative_calls',0, ...
    'estimator_calls',0,'pinv_calls',0,'fallbacks',0, ...
    'silent_rank_truncations',0,'rank_changes',0,'chart_switches',0, ...
    'branch_switches',0,'pointwise_modulus_reselections',0, ...
    'method_switches',0,'maximum_square_order',c.maximum_square_order, ...
    'maximum_rectangular_shape',c.maximum_rectangular_shape, ...
    'memory_mib_bound',c.memory_mib_max,'peak_active_mib',peak_active_mib, ...
    'checkpoint_count',checkpoint_count, ...
    'formal_external_startup_seconds',formal_external_startup_seconds, ...
    'formal_failed_smoke_seconds',formal_failed_smoke_seconds, ...
    'formal_accepted_smoke_seconds',formal_accepted_smoke_seconds, ...
    'formal_parent_seconds',formal_parent_seconds, ...
    'formal_seconds_including_parent',formal_parent_seconds+elapsed_seconds);
  try
    LOCAL_write_evidence(output,result,source_rows);
  catch evidence_exception
    if isempty(first_failure)
      first_failure = 'NUMERICAL_INSTABILITY';
    end
    status = 'I2_1_M1B_FAIL';
    pass = false;
    ledgers.failures(end+1) = struct('first_failure',first_failure, ...
      'identifier',evidence_exception.identifier, ...
      'message',evidence_exception.message,'elapsed_seconds',toc(campaign_timer));
    result.pass = false; result.status = status;
    result.first_failure = first_failure; result.failures = ledgers.failures;
    result.scientific_count = NaN;
    LOCAL_write_minimal_failure(output,result,evidence_exception);
    if isempty(caught), caught = evidence_exception; end
  end
  if ~isempty(caught), rethrow(caught); end
end

%% ==================== Parent and runtime gates ====================
% These helpers freeze source/runtime identity before scientific evaluation.

function [sources,rows,digest] = LOCAL_provenance(here,repo,c)
  names = {'cfg_i21.m','count_core.m','riesz_core.m','eval_i21.m', ...
    'i21_kproxy.m','run_i21.m','kproxy.m','kchan.m','kgreen.m','kbie.m', ...
    'README.md'};
  sources = LOCAL_empty_sources();
  for j = 1:numel(names)
    path = fullfile(here,names{j});
    sources(end+1) = struct('name',names{j},'path',path, ...
      'sha256',LOCAL_hash(path)); %#ok<AGROW>
  end
  deps = {'AGENTS.md','research/AGENTS.md','test/AGENTS.md', ...
    'research/projects/eig-apost/implementation/i2/design.md', ...
    '+bloch/incident_rhs.m','+bloch/farfield_extractors.m', ...
    '+geom/construct_cont.m','+kernel/h2d_directch.m', ...
    '+kernel/kress_l_splits.m','+kernel/kress_mn_splits.m', ...
    '+quad/quad_kress_rvec.m','+utils/triginterp.m'};
  for j = 1:numel(deps)
    path = fullfile(repo,deps{j});
    sources(end+1) = struct('name',deps{j},'path',path, ...
      'sha256',LOCAL_hash(path)); %#ok<AGROW>
  end
  for j = 1:numel(c.parents)
    path = fullfile(repo,c.parents(j).relative_path);
    sources(end+1) = struct('name',c.parents(j).relative_path, ...
      'path',path,'sha256',LOCAL_hash(path)); %#ok<AGROW>
  end
  [code,sha] = system(sprintf('git -C "%s" rev-parse HEAD',repo));
  if code ~= 0, error('i21:Git','Cannot record Git SHA.'); end
  [~,dirty] = system(sprintf('git -C "%s" status --short',repo));
  solver_path = which('lsqminnorm');
  rows = LOCAL_empty_key_values();
  rows(end+1) = LOCAL_key('runtime_kind','MATLAB');
  rows(end+1) = LOCAL_key('matlab_version',version);
  rows(end+1) = LOCAL_key('lsqminnorm_path',solver_path);
  rows(end+1) = LOCAL_key('git_sha',strtrim(sha));
  rows(end+1) = LOCAL_key('dirty_status',strtrim(dirty));
  rows(end+1) = LOCAL_key('generated_utc', ...
    char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ssXXX')));
  rows(end+1) = LOCAL_key('spatial_level','fine');
  rows(end+1) = LOCAL_key('M','48');
  rows(end+1) = LOCAL_key('K','97');
  rows(end+1) = LOCAL_key('runtime_solver','lsqminnorm');
  rows(end+1) = LOCAL_key('pinv_calls','0');
  rows(end+1) = LOCAL_key('fallbacks','0');
  rows(end+1) = LOCAL_key('silent_rank_truncations','0');
  rows(end+1) = LOCAL_key('method_switches','0');
  digest = LOCAL_code_digest(sources);
end

function [out,rows] = LOCAL_parents(repo,c)
  rows = LOCAL_empty_lineage(); out = struct();
  for j = 1:numel(c.parents)
    p = c.parents(j); path = fullfile(repo,p.relative_path);
    actual = LOCAL_hash(path); ok = strcmp(actual,p.sha256);
    rows(end+1) = struct('role',p.role,'path',path,'expected',p.sha256, ...
      'actual',actual,'pass',ok); %#ok<AGROW>
    if ~ok, error('i21:ParentHash','Frozen parent hash mismatch: %s.',p.role); end
    loaded = load(path,'result'); value = loaded.result;
    if j == 1
      if ~value.pass || ~strcmp(value.lineage.token,c.parent_token) || ...
          value.candidate.k ~= c.kstar
        error('i21:ParentContent','I1.3 parent content failed.');
      end
      out.zoom = value;
    elseif j == 2
      if ~value.pass, error('i21:ParentContent','I1.4 pilot failed.'); end
      out.pilot = value;
    elseif j == 3
      positives = value.engineering_pass && all([value.nodes.level_pass]) && ...
        all([value.nodes.comparison_pass]) && all([value.factors.pass]) && ...
        all([value.branches.pass]) && all([value.qz.pass]) && ...
        all([value.closures.pass]) && all([value.cr.pass]);
      if ~positives, error('i21:ParentContent','I1.4 positive parent failed.'); end
      out.v4 = value;
    else
      if ~value.pass || ~value.v4_import_pass
        error('i21:ParentContent','I1.4 closure parent failed.');
      end
      out.v5 = value;
    end
  end
end

function [smoke,lineage] = LOCAL_smoke_parent(here,c)
  path = fullfile(here,c.smoke_parent_relative);
  if isempty(c.smoke_parent_sha256) || ...
      isempty(c.smoke_parent_implementation_digest)
    error('i21:SmokeParent', ...
      'The reviewed smoke-a2 artifact and producer identities are not registered.');
  end
  if ~isfile(path)
    error('i21:SmokeParent','The registered smoke-a2 result is missing.');
  end
  actual_hash = LOCAL_hash(path);
  if ~strcmp(actual_hash,c.smoke_parent_sha256)
    error('i21:SmokeParent','The registered smoke-a2 result hash does not match.');
  end
  loaded = load(path,'result'); smoke = loaded.result;
  lineage = struct('role','I2_1_ACCEPTED_SMOKE_A2','path',path, ...
    'expected',c.smoke_parent_sha256,'actual',actual_hash,'pass',true);
  timing_fields = {'projected_fixed_seconds','projected_node_seconds', ...
    'projected_edge_seconds','smoke_edge_probe_seconds', ...
    'smoke_edge_probe_count','elapsed_seconds'};
  resource_fields = {'peak_active_mib','checkpoint_count','memory_mib_bound', ...
    'maximum_square_order','maximum_rectangular_shape'};
  zero_fields = {'locator_calls','root_solver_calls','derivative_calls', ...
    'estimator_calls','pinv_calls','fallbacks','silent_rank_truncations', ...
    'rank_changes','chart_switches','branch_switches', ...
    'pointwise_modulus_reselections','method_switches'};
  identity_fields = {'schema','design_id','mode','status','pass', ...
    'first_failure','scientific_count','implementation_digest','configuration'};
  timing_schema_pass = all(isfield(smoke,timing_fields));
  if timing_schema_pass
    timing_values = [smoke.projected_fixed_seconds, ...
      smoke.projected_node_seconds,smoke.projected_edge_seconds, ...
      smoke.smoke_edge_probe_seconds,smoke.elapsed_seconds];
    timing_schema_pass = all(isfinite(timing_values)) && ...
      all(timing_values >= 0) && ...
      smoke.smoke_edge_probe_count == c.smoke_edge_probe_count && ...
      abs(smoke.projected_full_seconds-sum(timing_values(1:3))) <= ...
      100*eps*max(1,abs(smoke.projected_full_seconds)) && ...
      isequal(smoke.elapsed_seconds,c.accepted_smoke_seconds);
  end
  resource_pass = all(isfield(smoke,resource_fields));
  if resource_pass
    resource_pass = isfinite(smoke.peak_active_mib) && ...
      smoke.peak_active_mib <= c.memory_mib_max && ...
      smoke.checkpoint_count > 0 && ...
      smoke.memory_mib_bound == c.memory_mib_max && ...
      smoke.maximum_square_order == c.maximum_square_order && ...
      isequal(smoke.maximum_rectangular_shape,c.maximum_rectangular_shape);
  end
  zero_pass = all(isfield(smoke,zero_fields));
  if zero_pass
    for j = 1:numel(zero_fields)
      zero_pass = zero_pass && isequal(smoke.(zero_fields{j}),0);
    end
  end
  identity_pass = all(isfield(smoke,identity_fields));
  if identity_pass
    config_keys = {smoke.configuration.key};
    revision_index = find(strcmp(config_keys,'revision_id'));
    revision_pass = numel(revision_index) == 1 && ...
      strcmp(smoke.configuration(revision_index).value, ...
        c.smoke_parent_revision_id);
    identity_pass = strcmp(smoke.schema,c.smoke_parent_schema) && ...
      strcmp(smoke.design_id,c.smoke_parent_design_id) && ...
      revision_pass && ...
      strcmp(smoke.mode,'smoke') && smoke.pass && ...
      strcmp(smoke.status,c.smoke_parent_status) && ...
      isempty(smoke.first_failure) && isnan(smoke.scientific_count) && ...
      strcmp(smoke.implementation_digest, ...
        c.smoke_parent_implementation_digest);
  end
  budget_sum = c.external_startup_seconds+c.failed_smoke_seconds+ ...
    c.accepted_smoke_seconds;
  budget_pass = abs(c.formal_prior_seconds-budget_sum) <= ...
    100*eps*max(1,abs(c.formal_prior_seconds));
  if ~timing_schema_pass || ~resource_pass || ~zero_pass || ...
      ~identity_pass || ~budget_pass || ...
      smoke.projected_full_seconds > c.full_projection_stop_seconds || ...
      smoke.elapsed_seconds ~= c.accepted_smoke_seconds
    error('i21:SmokeParent', ...
      'Smoke parent identity/readiness/resource/budget gate failed.');
  end
end

function LOCAL_dimensions(seed,frame,c)
  checks = [isequal(size(seed.R),[c.expected.proxy_rank,c.expected.proxy_rank]), ...
    isequal(seed.proxy_shape,[c.expected.proxy_rows,c.expected.proxy_columns]), ...
    isequal(seed.proxy_shifted_shape, ...
      [c.expected.proxy_shifted_rows,c.expected.proxy_shifted_columns]), ...
    isequal(size(seed.Aqp),[c.expected.bie_order,c.expected.bie_order]), ...
    isequal(size(seed.pair.A),[c.expected.pencil_order,c.expected.pencil_order]), ...
    isequal(size(seed.pair.B),[c.expected.pencil_order,c.expected.pencil_order]), ...
    isequal(size(seed.Dp),[c.expected.chart_order,c.expected.chart_order]), ...
    isequal(size(seed.Dm),[c.expected.chart_order,c.expected.chart_order]), ...
    isequal(size(seed.AdefD),[c.expected.adef_order,c.expected.adef_order]), ...
    numel(frame.rows_plus) == c.K,numel(frame.rows_minus) == c.K, ...
    frame.proxy_chart.r == c.expected.proxy_rank];
  if ~all(checks), error('i21:DimensionDrift','Frozen object dimensions drifted.'); end
end

function rows = LOCAL_config_rows(c)
  rows = LOCAL_empty_key_values();
  names = fieldnames(c);
  for j = 1:numel(names)
    rows = LOCAL_flatten_config(rows,names{j},c.(names{j}));
  end
end

function rows = LOCAL_flatten_config(rows,prefix,value)
  if isstruct(value)
    names = fieldnames(value);
    for q = 1:numel(value)
      stem = prefix;
      if numel(value) > 1, stem = sprintf('%s(%d)',prefix,q); end
      for j = 1:numel(names)
        rows = LOCAL_flatten_config(rows,[stem,'.',names{j}], ...
          value(q).(names{j}));
      end
    end
  else
    rows(end+1) = LOCAL_key(prefix,LOCAL_plain(value));
  end
end

function rows = LOCAL_object_rows(seed,frame,c)
  rows = LOCAL_empty_objects();
  data = {'proxy_reduced',size(seed.R),c.expected.proxy_rank, ...
      c.expected.proxy_rank, ...
      'affine proxy inverse factor'; ...
    'proxy_collocation_diagnostic',seed.proxy_shape, ...
      c.expected.proxy_rows,c.expected.proxy_columns, ...
      'diagnostic-only collocation proxy residual matrix'; ...
    'proxy_shifted_diagnostic',seed.proxy_shifted_shape, ...
      c.expected.proxy_shifted_rows,c.expected.proxy_shifted_columns, ...
      'diagnostic-only shifted proxy residual matrix'; ...
    'bie_A_QP',size(seed.Aqp),c.expected.bie_order,c.expected.bie_order, ...
      'BIE inverse factor'; ...
    'pencil_original_A',size(seed.pair.A),c.expected.pencil_order, ...
      c.expected.pencil_order, ...
      'fine anchored original pencil'; ...
    'pencil_original_B',size(seed.pair.B),c.expected.pencil_order, ...
      c.expected.pencil_order, ...
      'fine anchored original pencil'; ...
    'fixed_section_plus',size(frame.Z0_plus),c.expected.pencil_order,c.K, ...
      'I1 fixed-H normalized section'; ...
    'fixed_section_minus',size(frame.Z0_minus),c.expected.pencil_order,c.K, ...
      'I1 fixed-H normalized reversed section'; ...
    'Dhat_plus',size(seed.Dp),c.expected.chart_order,c.expected.chart_order, ...
      'safe-DtN inverse factor'; ...
    'Dhat_minus',size(seed.Dm),c.expected.chart_order,c.expected.chart_order, ...
      'safe-DtN inverse factor'; ...
    'AdefD',size(seed.AdefD),c.expected.adef_order,c.expected.adef_order, ...
      'unbalanced frozen scientific matrix'};
  for j = 1:size(data,1)
    shape = data{j,2};
    rows(end+1) = struct('object',data{j,1},'rows',shape(1), ...
      'columns',shape(2),'expected_rows',data{j,3}, ...
      'expected_columns',data{j,4}, ...
      'spatial_level','fine','M',c.M,'K',c.K, ...
      'role',data{j,5},'pass',isequal(shape,[data{j,3},data{j,4}])); %#ok<AGROW>
  end
end

function [pass,identifier] = LOCAL_seed_structural_pass(seed,c)
  identifier = 'i21:SeedGate';
  branch_chart = seed.plus.pass && seed.minus.pass && ...
    seed.branch_port.pass && seed.branch_proxy.pass && seed.cp.safe && seed.cm.safe;
  fixed_rows = seed.row.plus_margin > c.chart_margin_min && ...
    seed.row.minus_margin > c.chart_margin_min && ...
    seed.row.plus_condition*eps <= c.chart_condition_eps_tol && ...
    seed.row.minus_condition*eps <= c.chart_condition_eps_tol;
  % seed.pass is the inherited I1.4 level contract: it also retains the
  % graph-Schur, participation, and lift-residual diagnostics.  It contains
  % no AdefD determinant-separation gate, so using it cannot circularly
  % qualify the I2.1 count.
  if ~(branch_chart && fixed_rows)
    pass = false;
    return;
  end
  if ~(all([seed.factors.pass]) && seed.pass)
    pass = false;
    identifier = 'i21:SeedFactor';
    return;
  end
  pass = true;
end

function pass = LOCAL_edge_interface_pass(rows,c)
  pass = numel(rows) == 2*c.Nzeta_full && ...
    all(isfinite([rows.forward_ratio])) && ...
    all(isfinite([rows.backward_ratio])) && ...
    all(isfinite([rows.forward_residual])) && ...
    all(isfinite([rows.backward_residual])) && ...
    all([rows.forward_residual] <= c.resolvent_solve_residual_max) && ...
    all([rows.backward_residual] <= c.resolvent_solve_residual_max);
end

function total = LOCAL_accumulate_time(total,value)
  if isnan(total), total = 0; end
  total = total+value;
end

function rows = LOCAL_expected_object_rows(c)
  rows = LOCAL_empty_objects();
  data = {'proxy_reduced',c.expected.proxy_rank,c.expected.proxy_rank, ...
      'affine proxy inverse factor'; ...
    'proxy_collocation_diagnostic',c.expected.proxy_rows, ...
      c.expected.proxy_columns, ...
      'diagnostic-only collocation proxy residual matrix'; ...
    'proxy_shifted_diagnostic',c.expected.proxy_shifted_rows, ...
      c.expected.proxy_shifted_columns, ...
      'diagnostic-only shifted proxy residual matrix'; ...
    'bie_A_QP',c.expected.bie_order,c.expected.bie_order, ...
      'BIE inverse factor'; ...
    'pencil_original_A',c.expected.pencil_order,c.expected.pencil_order, ...
      'fine anchored original pencil'; ...
    'pencil_original_B',c.expected.pencil_order,c.expected.pencil_order, ...
      'fine anchored original pencil'; ...
    'fixed_section_plus',c.expected.pencil_order,c.K, ...
      'I1 fixed-H normalized section'; ...
    'fixed_section_minus',c.expected.pencil_order,c.K, ...
      'I1 fixed-H normalized reversed section'; ...
    'Dhat_plus',c.expected.chart_order,c.expected.chart_order, ...
      'safe-DtN inverse factor'; ...
    'Dhat_minus',c.expected.chart_order,c.expected.chart_order, ...
      'safe-DtN inverse factor'; ...
    'AdefD',c.expected.adef_order,c.expected.adef_order, ...
      'unbalanced frozen scientific matrix'};
  for j = 1:size(data,1)
    rows(end+1) = struct('object',data{j,1},'rows',data{j,2}, ...
      'columns',data{j,3},'expected_rows',data{j,2}, ...
      'expected_columns',data{j,3},'spatial_level','fine', ...
      'M',c.M,'K',c.K,'role',data{j,4},'pass',true); %#ok<AGROW>
  end
end

%% ==================== Manufactured core oracles ====================
% These helpers provide answers independent of the physical expected count.

function [rows,edges,pass] = LOCAL_oracles(c)
  rows = LOCAL_empty_oracles(); edges = LOCAL_empty_phase_edges();
  a = 0.2+0.1i; Q = [0,1;1,0];
  cases = {'COUNT_ZERO','COUNT_ONE_ORIENTATION_PARITY','COUNT_TWO_MULTIPLICITY'};
  expected = [0,1,2];
  for ci = 1:3
    points = exp(2i*pi*(0:c.Nk_full-1)/c.Nk_full);
    detrows = LOCAL_empty_factor_rows(); phase_errors = zeros(c.Nk_full,1);
    log_errors = zeros(c.Nk_full,1);
    for j = 1:c.Nk_full
      s = points(j);
      if ci == 1
        F = diag([2,3]); analytic = 6;
      elseif ci == 2
        F = Q*diag([s-a,2]); analytic = -2*(s-a);
      else
        F = diag([(s-a)^2,3]); analytic = 3*(s-a)^2;
      end
      [r,~] = count_core('lu',F,cases{ci},j,0,c);
      detrows(end+1) = r; %#ok<AGROW>
      phase_errors(j) = abs(angle(exp(1i*(r.phase-angle(analytic)))));
      log_errors(j) = abs(r.logabsdet-log(abs(analytic)));
    end
    for N = [c.Nk_nested,c.Nk_full]
      if N == c.Nk_nested, use = c.k_nested_indices; else, use = 1:c.Nk_full; end
      phase_error = max(phase_errors(use)); log_error = max(log_errors(use));
      [w,e] = count_core('winding',detrows,use,cases{ci},c);
      edges = [edges;e(:)]; %#ok<AGROW>
      ok = w.pass && w.rounded_count == expected(ci) && ...
        w.integer_residual <= c.oracle_tol && phase_error <= c.oracle_tol && ...
        log_error <= c.oracle_tol;
      row = LOCAL_oracle_row(cases{ci},N,expected(ci),w.raw_count, ...
        c.oracle_tol,max([w.integer_residual,phase_error,log_error]),ok, ...
        min([detrows(use).rcond]),max([detrows(use).lu_residual]),NaN);
      rows(end+1) = row; %#ok<AGROW>
      if ci == 2
        reversed = use(end:-1:1);
        [wr,er] = count_core('winding',detrows,reversed, ...
          'COUNT_ONE_REVERSED',c);
        edges = [edges;er(:)]; %#ok<AGROW>
        rok = wr.pass && wr.rounded_count == -1 && ...
          wr.integer_residual <= c.oracle_tol;
        row = LOCAL_oracle_row('COUNT_ONE_REVERSED',N,-1, ...
          wr.raw_count,c.oracle_tol,wr.integer_residual,rok, ...
          min([detrows(use).rcond]),max([detrows(use).lu_residual]),NaN);
        rows(end+1) = row; %#ok<AGROW>
      end
    end
  end

  boundary = LOCAL_empty_factor_rows();
  boundary_points = exp(2i*pi*(0:c.Nk_full-1)/c.Nk_full);
  for j = 1:c.Nk_full
    s = boundary_points(j); F = diag([s-1,2]);
    [r,~] = count_core('lu',F,'BOUNDARY_SINGULAR_FAIL',j,0,c);
    boundary(end+1) = r; %#ok<AGROW>
  end
  [wb,eb] = count_core('winding',boundary,1:c.Nk_full, ...
    'BOUNDARY_SINGULAR_FAIL',c);
  edges = [edges;eb(:)];
  bok = ~wb.pass && ~all([boundary.available]) && isnan(wb.raw_count);
  row = LOCAL_oracle_row('BOUNDARY_SINGULAR_FAIL',c.Nk_full, ...
    NaN,wb.raw_count,0,double(all([boundary.available])),bok, ...
    min([boundary.rcond]),max([boundary.lu_residual]),NaN);
  rows(end+1) = row;

  Ao = diag([0.1,10]); Bo = eye(2); rz = riesz_core('oracle',Ao,Bo,c);
  exact_plus = diag([1,0]); exact_minus = diag([0,1]);
  projector_rows = [rz.plus_projectors;rz.minus_projectors];
  for N = [16,32]
    plus = rz.(['plus',num2str(N)]); minus = rz.(['minus',num2str(N)]);
    pe = norm(plus-exact_plus,'fro'); me = norm(minus-exact_minus,'fro');
    idem = max(norm(plus*plus-plus,'fro'),norm(minus*minus-minus,'fro'));
    use = projector_rows([projector_rows.Nzeta] == N);
    same_core_pass = numel(use) == 2 && all([use.pass]);
    ok = rz.solve_pass && same_core_pass && ...
      max([pe,me,idem]) <= c.oracle_tol;
    row = LOCAL_oracle_row('RIESZ_WEIGHT_AND_REVERSED',N,0, ...
      max([pe,me,idem]),c.oracle_tol,max([pe,me,idem]),ok, ...
      min([rz.resolvents.rcond]),max([rz.resolvents.lu_residual]), ...
      max([rz.resolvents.solve_residual]));
    rows(end+1) = row; %#ok<AGROW>
  end
  negative_error = norm(rz.no_weight32-exact_plus,'fro');
  nok = negative_error >= c.oracle_negative_min;
  row = LOCAL_oracle_row('RIESZ_OMITTED_WEIGHT_NEGATIVE',32, ...
    c.oracle_negative_min,negative_error,c.oracle_negative_min,negative_error, ...
    nok,min([rz.resolvents.rcond]),max([rz.resolvents.lu_residual]), ...
    max([rz.resolvents.solve_residual]));
  rows(end+1) = row;
  pass = all([rows.pass]);
end

%% ==================== Physical ledgers and count chain ====================
% These helpers reduce dense point objects to compact, auditable evidence.

function row = LOCAL_node_row(node,index,is_seed)
  row = struct('node_index',index,'is_seed',is_seed,'k_real',real(node.k), ...
    'k_imag',imag(node.k),'level',node.name,'level_pass',node.pass, ...
    'elapsed_seconds',node.elapsed_seconds,'schur',node.schur, ...
    'plus_overlap',LOCAL_field(node.plus,'overlap',1), ...
    'minus_overlap',LOCAL_field(node.minus,'overlap',1), ...
    'plus_stable',node.plus.stable_diagnostic, ...
    'minus_stable',node.minus.stable_diagnostic, ...
    'plus_unstable',node.plus.unstable_diagnostic, ...
    'minus_unstable',node.minus.unstable_diagnostic, ...
    'plus_neutral',node.plus.neutral_count, ...
    'minus_neutral',node.minus.neutral_count, ...
    'plus_indeterminate',node.plus.indeterminate_count, ...
    'minus_indeterminate',node.minus.indeterminate_count, ...
    'plus_unit_gap',node.plus.unit_gap,'minus_unit_gap',node.minus.unit_gap, ...
    'plus_score_gap',node.plus.score_gap,'minus_score_gap',node.minus.score_gap, ...
    'plus_classification_gap',node.plus.classification_gap, ...
    'minus_classification_gap',node.minus.classification_gap, ...
    'plus_chordal_separation',node.plus.chordal_separation, ...
    'minus_chordal_separation',node.minus.chordal_separation, ...
    'plus_cluster_tau',node.plus.cluster_tau, ...
    'minus_cluster_tau',node.minus.cluster_tau, ...
    'plus_raw_qz_residual',node.plus.raw_residual, ...
    'minus_raw_qz_residual',node.minus.raw_residual, ...
    'plus_qz_residual',node.plus.residual, ...
    'minus_qz_residual',node.minus.residual, ...
    'plus_match_pass',node.plus.match_pass, ...
    'minus_match_pass',node.minus.match_pass, ...
    'branch_port_pass',node.branch_port.pass, ...
    'branch_proxy_pass',node.branch_proxy.pass, ...
    'port_branch_fingerprint',node.branch_port.fingerprint, ...
    'proxy_branch_fingerprint',node.branch_proxy.fingerprint, ...
    'row_fingerprint',LOCAL_hash_vector([node.H_plus_rows(:); ...
      node.H_minus_rows(:)]), ...
    'proxy_chart_fingerprint',node.proxy_chart.fingerprint, ...
    'row_plus_margin',node.row.plus_margin, ...
    'row_minus_margin',node.row.minus_margin, ...
    'row_plus_condition',node.row.plus_condition, ...
    'row_minus_condition',node.row.minus_condition, ...
    'row_plus_residual',node.row.plus_residual, ...
    'row_minus_residual',node.row.minus_residual, ...
    'participation_center',node.participation.center, ...
    'participation_graph',node.participation.graph, ...
    'kernel_defect',node.participation.kernel_defect);
end

function rows = LOCAL_health_rows(node,index)
  rows = LOCAL_empty_health();
  for j = 1:numel(node.factors)
    x = node.factors(j);
    rows(end+1) = struct('node_index',index,'name',x.name, ...
      'rcond',x.rcond,'residual',x.residual,'available',x.available, ...
      'rcond_min',x.rcond_min,'residual_max',x.residual_max,'pass',x.pass); %#ok<AGROW>
  end
end

function [rows,pass] = LOCAL_factor_rows(node,rz,index,c)
  rows = LOCAL_empty_factor_rows();
  data = {node.R,'proxy_reduced',c.factor_rcond_min; ...
    node.Aqp,'bie_A_QP',c.factor_rcond_min; ...
    node.Dp,'Dhat_plus',c.factor_rcond_min; ...
    node.Dm,'Dhat_minus',c.factor_rcond_min; ...
    node.AdefD,'AdefD',c.adef_rcond_min};
  for j = 1:size(data,1)
    [r,~] = count_core('lu',data{j,1},data{j,2},index,data{j,3},c);
    rows(end+1) = r; %#ok<AGROW>
  end
  rows(end+1) = rz.plus.C16_det;
  rows(end+1) = rz.plus.C32_det;
  rows(end+1) = rz.minus.C16_det;
  rows(end+1) = rz.minus.C32_det;
  pass = all([rows.available]);
end

function [pass,failure,gates] = LOCAL_smoke_gates(ledgers,c)
  gates = LOCAL_empty_gates(); pass = true; failure = '';
  indices = c.physical_indices;
  resolvents = ledgers.resolvents(ismember([ledgers.resolvents.node_index],indices));
  projectors = ledgers.projectors(ismember([ledgers.projectors.node_index],indices));
  factors = ledgers.factors(ismember([ledgers.factors.node_index],indices));
  expected_resolvents = 2*numel(indices)*c.Nzeta_full;
  resolvent_pass = numel(resolvents) == expected_resolvents && ...
    all([resolvents.available]);
  arc_rows = ledgers.zeta_arcs(ismember([ledgers.zeta_arcs.node_index],indices));
  zeta_pass = numel(arc_rows) == expected_resolvents && all([arc_rows.pass]);
  gates(end+1) = LOCAL_gate(6,'SMOKE_RESOLVENT_ZETA_INTERFACE', ...
    resolvent_pass && zeta_pass,double(resolvent_pass && zeta_pass),1, ...
    'cardinal nodes exercise the production resolvent and zeta-arc path');
  if ~(resolvent_pass && zeta_pass)
    pass = false; failure = 'RESOLVENT_SCREEN_UNAVAILABLE'; return;
  end
  chart_pass = numel(projectors) == 4*numel(indices) && ...
    all([projectors.pass]);
  gates(end+1) = LOCAL_gate(7,'SMOKE_RIESZ_CHART_INTERFACE', ...
    chart_pass,double(chart_pass),1, ...
    'cardinal nodes exercise nested projector and fixed-section gates');
  if ~chart_pass
    pass = false; failure = 'RIESZ_CHART_QUALIFICATION_FAILURE'; return;
  end
  required = {'proxy_reduced','bie_A_QP','Dhat_plus','Dhat_minus', ...
    'C_plus_16','C_plus_32','C_minus_16','C_minus_32'};
  factor_pass = true;
  for j = 1:numel(required)
    selected = factors(strcmp({factors.object},required{j}));
    factor_pass = factor_pass && numel(selected) == numel(indices) && ...
      all([selected.available]);
  end
  gates(end+1) = LOCAL_gate(8,'SMOKE_FACTOR_INTERFACE',factor_pass, ...
    double(factor_pass),1, ...
    'cardinal nodes expose every non-scientific inverse factor; AdefD is diagnostic only');
  if ~factor_pass
    pass = false; failure = 'PHASE_UNRESOLVED';
  end
end

function [summaries,edges,count,pass,failure,gates] = LOCAL_windings(ledgers,c)
  summaries = LOCAL_empty_windings(); edges = LOCAL_empty_phase_edges();
  gates = LOCAL_empty_gates(); count = NaN; pass = true; failure = '';
  [summaries,edges,ok,why] = LOCAL_factor_winding_stage( ...
    ledgers,summaries,edges,{'proxy_reduced','bie_A_QP'}, ...
    'PROXY_OR_BIE_FACTOR_COUNT',c);
  gates(end+1) = LOCAL_gate(5,'PROXY_AND_BIE_ZERO_COUNTS',ok, ...
    double(ok),1,'R and A_QP have reliable nested zero winding');
  if ~ok, pass = false; failure = why; return; end
  resolvent_pass = true;
  sides = {'plus','minus'};
  for s = 1:2
    for z = 0:c.Nzeta_full-1
      name = sprintf('resolvent_%s_zeta_%02d',sides{s},z);
      rows = ledgers.resolvents(strcmp({ledgers.resolvents.object},name) & ...
        [ledgers.resolvents.node_index] > 0);
      [rows,ok_order] = LOCAL_order_records(rows,c);
      if ok_order
        [w32,e32] = count_core('winding',rows,1:2:c.Nk_full,name,c);
        [w64,e64] = count_core('winding',rows,1:c.Nk_full,name,c);
      else
        w32 = LOCAL_unavailable_winding(name,c.Nk_nested,c);
        w64 = LOCAL_unavailable_winding(name,c.Nk_full,c);
        e32 = LOCAL_empty_phase_edges(); e64 = LOCAL_empty_phase_edges();
      end
      w32.grid = 32; w64.grid = 64;
      summaries = [summaries;w32;w64];
      edges = [edges;e32(:);e64(:)]; %#ok<AGROW>
      resolvent_pass = resolvent_pass && w32.pass && w64.pass && ...
        w32.rounded_count == 0 && w64.rounded_count == 0;
    end
  end
  physical_zeta = ledgers.zeta_arcs([ledgers.zeta_arcs.node_index] > 0);
  zeta_pass = numel(physical_zeta) == ...
    2*c.Nk_full*c.Nzeta_full && all([physical_zeta.pass]);
  k_pass = numel(ledgers.k_arcs) == 2*c.Nk_full*c.Nzeta_full && ...
    all([ledgers.k_arcs.pass]);
  screens_pass = resolvent_pass && zeta_pass && k_pass;
  gates(end+1) = LOCAL_gate(6,'RESOLVENT_ZERO_COUNTS_AND_ARCS', ...
    screens_pass,double(screens_pass),1, ...
    'all resolvent nested zero counts and both sampled arc screens pass');
  if ~screens_pass
    pass = false; failure = 'RESOLVENT_SCREEN_UNAVAILABLE'; return;
  end
  physical_projectors = ledgers.projectors([ledgers.projectors.node_index] > 0);
  projector_pass = numel(physical_projectors) == 4*c.Nk_full && ...
    all([physical_projectors.pass]);
  if ~projector_pass
    gates(end+1) = LOCAL_gate(7,'RIESZ_PROJECTOR_AND_CHART',false,0,1, ...
      'nested action, idempotence, fixed-row, or QZ parity failed');
    pass = false; failure = 'RIESZ_CHART_QUALIFICATION_FAILURE'; return;
  end
  [summaries,edges,ok,why] = LOCAL_factor_winding_stage( ...
    ledgers,summaries,edges, ...
    {'C_plus_16','C_plus_32','C_minus_16','C_minus_32'}, ...
    'RIESZ_CHART_QUALIFICATION_FAILURE',c);
  gates(end+1) = LOCAL_gate(7,'RIESZ_PROJECTOR_AND_CHART',ok, ...
    double(ok),1,'projector qualifications and all C nested zero counts pass');
  if ~ok, pass = false; failure = why; return; end
  [summaries,edges,ok,why] = LOCAL_factor_winding_stage( ...
    ledgers,summaries,edges,{'Dhat_plus','Dhat_minus'}, ...
    'DIRICHLET_POLE_OR_FACTOR_COUNT',c);
  gates(end+1) = LOCAL_gate(8,'DIRICHLET_FACTOR_ZERO_COUNTS',ok, ...
    double(ok),1,'both normalized Dirichlet factors have nested zero winding');
  if ~ok, pass = false; failure = why; return; end
  [summaries,edges,ok,why,last] = LOCAL_factor_winding_stage( ...
    ledgers,summaries,edges,{'AdefD'},'',c);
  gates(end+1) = LOCAL_gate(9,'ADEF_BOUNDARY_AND_NESTED_COUNT',ok, ...
    double(ok),1,'AdefD boundary separation, phase, closure, and nested counts agree');
  if ~ok, pass = false; failure = why; return; end
  count = last.rounded_count;
end

function [summaries,edges,pass,failure,last] = LOCAL_factor_winding_stage( ...
    ledgers,summaries,edges,names,count_failure,c)
  pass = true; failure = ''; last = struct();
  for j = 1:numel(names)
    name = names{j}; rows = ledgers.factors( ...
      strcmp({ledgers.factors.object},name) & [ledgers.factors.node_index] > 0);
    [rows,ok_order] = LOCAL_order_records(rows,c);
    if ~ok_order
      s32 = LOCAL_unavailable_winding(name,c.Nk_nested,c);
      s64 = LOCAL_unavailable_winding(name,c.Nk_full,c);
      s32.grid = 32; s64.grid = 64;
      summaries = [summaries;s32;s64]; %#ok<AGROW>
      if strcmp(name,'AdefD')
        failure = 'BOUNDARY_TOO_CLOSE';
      else
        failure = 'PHASE_UNRESOLVED';
      end
      pass = false; return;
    end
    [s32,e32] = count_core('winding',rows,1:2:c.Nk_full,name,c);
    [s64,e64] = count_core('winding',rows,1:c.Nk_full,name,c);
    s32.grid = 32; s64.grid = 64; last = s64;
    summaries = [summaries;s32;s64]; %#ok<AGROW>
    edges = [edges;e32(:);e64(:)]; %#ok<AGROW>
    reliable = s32.pass && s64.pass && s32.rounded_count == s64.rounded_count;
    if ~reliable
      if strcmp(name,'AdefD') && any(~[rows.available])
        failure = 'BOUNDARY_TOO_CLOSE';
      else
        failure = 'PHASE_UNRESOLVED';
      end
      pass = false; return;
    end
    if ~strcmp(name,'AdefD') && s64.rounded_count ~= 0
      pass = false; failure = count_failure; return;
    end
  end
end

function row = LOCAL_unavailable_winding(object,node_count,c)
  row = struct('object',object,'node_count',node_count, ...
    'raw_count',NaN,'rounded_count',NaN,'integer_residual',NaN, ...
    'integer_residual_max',c.integer_residual_max,'max_edge_guard',Inf, ...
    'edge_guard_max',c.edge_phase_guard,'available',false,'pass',false);
end

function [rows,pass] = LOCAL_order_records(rows,c)
  if numel(rows) ~= c.Nk_full, pass = false; return; end
  [~,order] = sort([rows.node_index]); rows = rows(order);
  pass = isequal([rows.node_index],1:c.Nk_full);
end

function rows = LOCAL_prefix_objects(rows,prefix)
  for j = 1:numel(rows)
    rows(j).object = [prefix,rows(j).object];
  end
end

function rows = LOCAL_prefix_projector_sides(rows,prefix)
  for j = 1:numel(rows)
    rows(j).side = [prefix,rows(j).side];
  end
end

function rows = LOCAL_prefix_zeta_sides(rows,prefix)
  for j = 1:numel(rows)
    rows(j).side = [prefix,rows(j).side];
  end
end

%% ==================== Evidence finalization ====================
% These helpers mechanically serialize every complete or partial ledger.

function LOCAL_write_evidence(output,r,sources)
  LOCAL_csv(fullfile(output,'oracles.csv'),r.oracles);
  LOCAL_csv(fullfile(output,'nodes.csv'),r.nodes);
  LOCAL_csv(fullfile(output,'factor-health.csv'),r.health);
  LOCAL_csv(fullfile(output,'factors.csv'),r.factors);
  LOCAL_csv(fullfile(output,'resolvents.csv'),r.resolvents);
  LOCAL_csv(fullfile(output,'zeta-arcs.csv'),r.zeta_arcs);
  LOCAL_csv(fullfile(output,'k-arcs.csv'),r.k_arcs);
  LOCAL_csv(fullfile(output,'projectors.csv'),r.projectors);
  LOCAL_csv(fullfile(output,'windings.csv'),r.windings);
  LOCAL_csv(fullfile(output,'phase-edges.csv'),r.phase_edges);
  LOCAL_csv(fullfile(output,'gates.csv'),r.gates);
  LOCAL_csv(fullfile(output,'failures.csv'),r.failures);
  LOCAL_csv(fullfile(output,'provenance.csv'),r.provenance);
  LOCAL_csv(fullfile(output,'configuration.csv'),r.configuration);
  LOCAL_csv(fullfile(output,'objects.csv'),r.objects);
  LOCAL_csv(fullfile(output,'lineage.csv'),r.lineage);
  LOCAL_csv(fullfile(output,'source-manifest.csv'),sources);
  if ~r.pass
    LOCAL_abort(fullfile(output,'abort.md'),r);
  end
  result = r; %#ok<NASGU>
  save(fullfile(output,'result.mat'),'result','-v7.3');
  % The official report is the final publication action.  No fallible write
  % follows its same-filesystem rename, so a PASS report cannot outlive a
  % failed result/ledger finalization.
  LOCAL_publish_report(output,r);
end

function LOCAL_write_minimal_failure(output,result,exception)
  published = fullfile(output,'report.md');
  pending = fullfile(output,'report.pending.md');
  % A report may already have been atomically published only if a future edit
  % adds a fallible action after publication.  Quarantine it before creating
  % any finalization-failure evidence so no official PASS report can remain.
  if isfile(published)
    quarantine = fullfile(output,'report.invalidated.md');
    try
      [moved,~] = movefile(published,quarantine);
      if ~moved
        LOCAL_overwrite_failed_report(published,result,exception);
      end
    catch
      try
        LOCAL_overwrite_failed_report(published,result,exception);
      catch
      end
    end
  end
  if isfile(pending)
    quarantine = fullfile(output,'report.invalidated.pending.md');
    try
      [moved,~] = movefile(pending,quarantine);
      if ~moved
        return;
      end
    catch
      return;
    end
  end
  canonical_result = false;
  try
    save(fullfile(output,'result.mat'),'result');
    canonical_result = true;
  catch
    try
      save(fullfile(output,'result-failure.mat'),'result');
    catch
    end
  end
  abort_saved = false;
  try
    LOCAL_finalization_abort(fullfile(output,'abort.md'),result,exception);
    abort_saved = true;
  catch
  end
  if canonical_result && abort_saved
    try
      LOCAL_publish_report(output,result);
    catch
      % No official report is published when the failure record is incomplete.
    end
  end
end

function LOCAL_overwrite_failed_report(path,result,exception)
  fid = fopen(path,'w');
  if fid < 0, error('i21:EvidenceWrite','Cannot invalidate %s.',path); end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'# I2.1 invalidated report\n\n');
  fprintf(fid,'- Status: `%s`; pass: `0`.\n',result.status);
  fprintf(fid,'- First failure: `%s`.\n',result.first_failure);
  fprintf(fid,'- Evidence writer identifier: `%s`.\n',exception.identifier);
  fprintf(fid,'\nNo scientific verdict is accepted from this attempt.\n');
  clear cleanup;
end

function LOCAL_abort(path,r)
  fid = fopen(path,'w');
  if fid < 0, error('i21:EvidenceWrite','Cannot write %s.',path); end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'# I2.1 preserved stop\n\n- Status: `%s`.\n',r.status);
  fprintf(fid,'- First failure: `%s`.\n',r.first_failure);
  fprintf(fid,'- Elapsed seconds: `%.17g`.\n',r.elapsed_seconds);
  fprintf(fid,'\nNo failed output may be overwritten or reinterpreted as a root.\n');
  clear cleanup;
end

function LOCAL_finalization_abort(path,result,exception)
  fid = fopen(path,'w');
  if fid < 0, error('i21:EvidenceWrite','Cannot write %s.',path); end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'# I2.1 evidence finalization failure\n\n');
  fprintf(fid,'- Status: `%s`.\n',result.status);
  fprintf(fid,'- First failure: `%s`.\n',result.first_failure);
  fprintf(fid,'- Evidence writer identifier: `%s`.\n',exception.identifier);
  fprintf(fid,'- Evidence writer message: `%s`.\n', ...
    strrep(exception.message,'`',''''));
  fprintf(fid,'\nThe append-only attempt is failed and must not be reused.\n');
  clear cleanup;
end

function LOCAL_publish_report(output,r)
  pending = fullfile(output,'report.pending.md');
  published = fullfile(output,'report.md');
  if isfile(pending) || isfile(published)
    error('i21:EvidenceWrite','Report publication target already exists.');
  end
  LOCAL_report(pending,r);
  content = fileread(pending);
  marker = sprintf('- Status: `%s`; pass: `%d`.',r.status,r.pass);
  if ~contains(content,marker)
    error('i21:EvidenceWrite','Pending report failed its status validation.');
  end
  [moved,message] = movefile(pending,published);
  if ~moved
    error('i21:EvidenceWrite','Cannot publish report: %s.',message);
  end
end

function LOCAL_report(path,r)
  fid = fopen(path,'w');
  if fid < 0, error('i21:EvidenceWrite','Cannot write %s.',path); end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'# I2.1 Method 1B report\n\n');
  fprintf(fid,'- Status: `%s`; pass: `%d`.\n',r.status,r.pass);
  fprintf(fid,'- Mode / first failure: `%s / %s`.\n',r.mode,r.first_failure);
  fprintf(fid,'- Scientific count: `%.17g`.\n',r.scientific_count);
  fprintf(fid,'- Elapsed / projected full seconds: `%.17g / %.17g`.\n', ...
    r.elapsed_seconds,r.projected_full_seconds);
  fprintf(fid,['- Measured active-state peak / checkpoints / frozen bound MiB: ' ...
    '`%.17g / %d / %.17g`.\n'],r.peak_active_mib,r.checkpoint_count, ...
    r.memory_mib_bound);
  fprintf(fid,'- Formal seconds including prior campaign: `%.17g / 7200`.\n', ...
    r.formal_seconds_including_parent);
  fprintf(fid,['- Prior formal seconds startup/failed smoke/accepted smoke: ' ...
    '`%.17g/%.17g/%.17g`.\n'],r.formal_external_startup_seconds, ...
    r.formal_failed_smoke_seconds,r.formal_accepted_smoke_seconds);
  fprintf(fid,'- Rows oracle/node/health/factor/resolvent/projector/k-arc/winding: ');
  fprintf(fid,'`%d/%d/%d/%d/%d/%d/%d/%d`.\n',numel(r.oracles), ...
    numel(r.nodes),numel(r.health),numel(r.factors),numel(r.resolvents), ...
    numel(r.projectors),numel(r.k_arcs),numel(r.windings));
  fprintf(fid,'- Frozen configuration/object rows: `%d/%d`.', ...
    numel(r.configuration),numel(r.objects));
  fprintf(fid,' All object rows pass: `%d`.\n', ...
    ~isempty(r.objects) && all([r.objects.pass]));
  fprintf(fid,'- Locator/root/derivative/estimator calls: `0/0/0/0`.\n');
  fprintf(fid,'- pinv/fallback/rank/chart/branch/method switches: `0/0/0/0/0/0`.\n');
  fprintf(fid,'\nClaim boundary: `%s`.\n\n',r.claim_boundary);
  if strcmp(r.mode,'smoke')
    fprintf(fid,'A smoke pass supports readiness of the frozen implementation only; ');
    fprintf(fid,'it produces no root count or physical conclusion.\n');
  elseif r.pass
    fprintf(fid,'A qualified full pass supports only a conditional empirical root count ');
    fprintf(fid,'for the frozen fine-M48 finite-dimensional family. It is not a root ');
    fprintf(fid,'location, simple root, continuous physical eigenvalue, or posterior estimator.\n');
  else
    fprintf(fid,'A failed or stopped full attempt supports no positive root-count claim.\n');
  end
  clear cleanup;
end

function LOCAL_csv(path,rows)
  fid = fopen(path,'w');
  if fid < 0, error('i21:EvidenceWrite','Cannot write %s.',path); end
  cleanup = onCleanup(@() fclose(fid)); fields = fieldnames(rows);
  fprintf(fid,'%s\n',strjoin(fields.',','));
  for i = 1:numel(rows)
    values = cell(1,numel(fields));
    for j = 1:numel(fields), values{j} = LOCAL_value(rows(i).(fields{j})); end
    fprintf(fid,'%s\n',strjoin(values,','));
  end
  clear cleanup;
end

function value = LOCAL_value(x)
  if ischar(x) || (isstring(x) && isscalar(x))
    value = ['"',strrep(char(x),'"','""'),'"'];
  elseif islogical(x) || (isnumeric(x) && isscalar(x))
    value = sprintf('%.17g',x);
  elseif isnumeric(x) || islogical(x)
    value = ['"',strrep(mat2str(x,17),'"','""'),'"'];
  else
    error('i21:EvidenceValue','Unsupported CSV ledger value.');
  end
end

function value = LOCAL_plain(x)
  if ischar(x) || (isstring(x) && isscalar(x))
    value = char(x);
  elseif iscell(x)
    pieces = cell(size(x));
    for j = 1:numel(x), pieces{j} = LOCAL_plain(x{j}); end
    value = ['{',strjoin(pieces(:).',';'),'}'];
  elseif isnumeric(x) || islogical(x)
    value = mat2str(x,17);
  else
    error('i21:EvidenceValue','Unsupported configuration ledger value.');
  end
end

function value = LOCAL_hash(path)
  fid = fopen(path,'r');
  if fid < 0, error('i21:Hash','Cannot read %s.',path); end
  cleanup = onCleanup(@() fclose(fid)); bytes = fread(fid,Inf,'*uint8');
  digest = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
  digest.update(typecast(bytes(:),'int8')); raw = typecast(digest.digest(),'uint8');
  value = lower(reshape(dec2hex(raw,2).',1,[])); clear cleanup;
end

function value = LOCAL_digest(rows)
  payload = '';
  for j = 1:numel(rows), payload = [payload,rows(j).sha256]; end %#ok<AGROW>
  digest = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
  digest.update(typecast(uint8(payload),'int8')); raw = typecast(digest.digest(),'uint8');
  value = lower(reshape(dec2hex(raw,2).',1,[]));
end

function value = LOCAL_code_digest(rows)
  names = {rows.name};
  keep = ~strcmp(names,'AGENTS.md') & ~strcmp(names,'research/AGENTS.md') & ...
    ~strcmp(names,'test/AGENTS.md') & ~strcmp(names,'README.md');
  value = LOCAL_digest(rows(keep));
end

function LOCAL_time(timer,c)
  if toc(timer) > c.hard_seconds
    error('i21:HardTime','The frozen per-run hard time expired.');
  end
end

function peak = LOCAL_resource_checkpoint(timer,c,peak,payload)
  LOCAL_time(timer,c);
  info = whos('payload');
  active_mib = info.bytes/(1024^2);
  if isnan(peak), peak = active_mib; else, peak = max(peak,active_mib); end
  if active_mib > c.memory_mib_max
    error('i21:MemoryStop', ...
      'Measured conservative active state %.6g MiB exceeds %.6g MiB.', ...
      active_mib,c.memory_mib_max);
  end
end

function LOCAL_finalize_log(path,c,source_digest,first_failure,caught)
  if isempty(source_digest), source_digest = 'UNAVAILABLE'; end
  fprintf('Final mode: %s\n',c.mode);
  fprintf('Final source digest: %s\n',source_digest);
  if isempty(first_failure)
    fprintf('First failure: NONE\n');
  else
    fprintf('First failure: %s\n',first_failure);
  end
  if ~isempty(caught)
    fprintf('First failure identifier: %s\n',caught.identifier);
    fprintf('First failure message: %s\n',caught.message);
    fprintf('%s\n',getReport(caught,'extended','hyperlinks','off'));
  end
  diary('off');
  info = dir(path);
  if isempty(info) || info.bytes == 0
    error('i21:EvidenceWrite','run.log was not flushed as nonempty evidence.');
  end
end

function label = LOCAL_failure(identifier)
  switch char(identifier)
    case {'i21:ProjectedTime','i21:HardTime','i21:MemoryStop', ...
        'i21:TotalFormalTime','i21:TIMEOUT_OR_RESOURCE_STOP'}
      label = 'TIMEOUT_OR_RESOURCE_STOP';
    case 'i21:CoreOracle'
      label = 'CORE_ORACLE_FAILURE';
    case 'i21:MATLABRequired'
      label = 'MATLAB_OR_SOLVER_FAILURE';
    case {'i21:Mode','i21:ConfigMode','i21:FullNotAuthorized', ...
        'i21:OutputExists', ...
        'i21:DimensionDrift','i21:ParentContent','i21:ParentHash', ...
        'i21:SmokeParent','i21:Git','i21:Hash', ...
        'kready:InvalidPeriodicAxis','kready:OddBoundaryCount', ...
        'kready:InvalidChannelParameters','kready:InvalidRayleighOrder', ...
        'kready:InvalidWavenumber'}
      label = 'PARENT_OR_PROVENANCE_FAILURE';
    case {'i21:RieszSeed','i21:SmokeEdgeProbe', ...
        'i21:RESOLVENT_SCREEN_UNAVAILABLE'}
      label = 'RESOLVENT_SCREEN_UNAVAILABLE';
    case {'i21:RieszChartSeed','i21:RIESZ_CHART_QUALIFICATION_FAILURE'}
      label = 'RIESZ_CHART_QUALIFICATION_FAILURE';
    case 'i21:PROXY_OR_BIE_FACTOR_COUNT'
      label = 'PROXY_OR_BIE_FACTOR_COUNT';
    case 'i21:DIRICHLET_POLE_OR_FACTOR_COUNT'
      label = 'DIRICHLET_POLE_OR_FACTOR_COUNT';
    case 'i21:PHASE_UNRESOLVED'
      label = 'PHASE_UNRESOLVED';
    case 'i21:BOUNDARY_TOO_CLOSE'
      label = 'BOUNDARY_TOO_CLOSE';
    case {'i21:SeedGate','i21:BranchQZChartDrift','i21:FixedRows', ...
        'kreadyv2:SeedCount','kreadyv2:DirichletChart', ...
        'kready:InvalidAnchoredBranch','kready:MissingBranchFingerprint', ...
        'kready:OuterBranchSize','kready:ProxyBranchSize'}
      label = 'BRANCH_QZ_CHART_DRIFT';
    case {'i21:EvaluatorNodes','i21:SeedFactor','i21:BIEFactor', ...
        'i21:BIESolve','i21:ProxyGate','i21:EvaluatorAction', ...
        'i21:InvalidProxyChart','i21:ShiftedSolveForbidden', ...
        'kreadyv2:GraphFactor','kready:InvalidProxyChart', ...
        'kready:InvalidProxyPointSet','kready:ShiftedSolveForbidden'}
      label = 'EVALUATOR_FAILURE';
    case 'i21:ZeroCount'
      label = 'ZERO_COUNT';
    case 'i21:MultipleCount'
      label = 'MULTIPLE_COUNT';
    case {'i21:CountCoreAction','i21:NonSquareFactor', ...
        'i21:RieszCoreAction','i21:EvidenceWrite','i21:EvidenceValue', ...
        'i21:NUMERICAL_INSTABILITY'}
      label = 'NUMERICAL_INSTABILITY';
    otherwise
      % Unknown dependency/runtime identifiers fail closed while the raw
      % identifier remains in failures.csv for an explicit mapping revision.
      label = 'NUMERICAL_INSTABILITY';
  end
end

function value = LOCAL_field(s,name,fallback)
  if isfield(s,name), value = s.(name); else, value = fallback; end
end

function value = LOCAL_hash_vector(data)
  payload = sprintf('%.17g,',double(data(:)));
  digest = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
  digest.update(typecast(uint8(payload),'int8'));
  raw = typecast(digest.digest(),'uint8');
  value = lower(reshape(dec2hex(raw,2).',1,[]));
end

%% ==================== Empty row schemas ====================
% These schemas let failed campaigns retain parseable zero-row CSV files.

function x = LOCAL_empty_ledgers()
  x = struct('oracles',LOCAL_empty_oracles(),'nodes',LOCAL_empty_nodes(), ...
    'health',LOCAL_empty_health(),'factors',LOCAL_empty_factor_rows(), ...
    'resolvents',LOCAL_empty_resolvents(),'zeta_arcs',LOCAL_empty_zeta_arcs(), ...
    'k_arcs',LOCAL_empty_k_arcs(),'projectors',LOCAL_empty_projectors(), ...
    'windings',LOCAL_empty_windings(),'phase_edges',LOCAL_empty_phase_edges(), ...
    'gates',LOCAL_empty_gates(),'failures',LOCAL_empty_failures(), ...
    'objects',LOCAL_empty_objects());
end

function x = LOCAL_empty_oracles()
  x = struct('name',{},'grid',{},'expected',{},'observed',{}, ...
    'tolerance',{},'error',{},'min_rcond',{},'max_lu_residual',{}, ...
    'max_solve_residual',{},'pass',{});
end
function x = LOCAL_empty_nodes()
  x = struct('node_index',{},'is_seed',{},'k_real',{},'k_imag',{}, ...
    'level',{},'level_pass',{},'elapsed_seconds',{},'schur',{}, ...
    'plus_overlap',{},'minus_overlap',{},'plus_stable',{}, ...
    'minus_stable',{},'plus_unstable',{},'minus_unstable',{}, ...
    'plus_neutral',{},'minus_neutral',{},'plus_indeterminate',{}, ...
    'minus_indeterminate',{},'plus_unit_gap',{},'minus_unit_gap',{}, ...
    'plus_score_gap',{},'minus_score_gap',{},'plus_classification_gap',{}, ...
    'minus_classification_gap',{},'plus_chordal_separation',{}, ...
    'minus_chordal_separation',{},'plus_cluster_tau',{}, ...
    'minus_cluster_tau',{},'plus_raw_qz_residual',{}, ...
    'minus_raw_qz_residual',{},'plus_qz_residual',{}, ...
    'minus_qz_residual',{},'plus_match_pass',{},'minus_match_pass',{}, ...
    'branch_port_pass',{},'branch_proxy_pass',{}, ...
    'port_branch_fingerprint',{},'proxy_branch_fingerprint',{}, ...
    'row_fingerprint',{},'proxy_chart_fingerprint',{}, ...
    'row_plus_margin',{},'row_minus_margin',{}, ...
    'row_plus_condition',{},'row_minus_condition',{}, ...
    'row_plus_residual',{},'row_minus_residual',{},'participation_center',{}, ...
    'participation_graph',{},'kernel_defect',{});
end
function x = LOCAL_empty_health()
  x = struct('node_index',{},'name',{},'rcond',{},'residual',{}, ...
    'available',{},'rcond_min',{},'residual_max',{},'pass',{});
end
function x = LOCAL_empty_factor_rows()
  x = struct('node_index',{},'object',{},'order',{},'rcond',{}, ...
    'rcond_min',{},'lu_residual',{},'relative_pivot',{}, ...
    'permutation_parity',{},'logabsdet',{},'phase',{}, ...
    'phase_uncertainty',{},'finite',{},'available',{});
end
function x = LOCAL_empty_resolvents()
  x = struct('node_index',{},'side',{},'zeta_index',{},'zeta_real',{}, ...
    'zeta_imag',{},'object',{},'order',{},'rcond',{},'rcond_min',{}, ...
    'lu_residual',{},'solve_residual',{},'solve_residual_max',{}, ...
    'relative_pivot',{},'permutation_parity',{},'logabsdet',{},'phase',{}, ...
    'phase_uncertainty',{},'finite',{},'available',{});
end
function x = LOCAL_empty_zeta_arcs()
  x = struct('node_index',{},'side',{},'zeta_index',{},'zeta_real',{}, ...
    'zeta_imag',{},'guard_value',{},'guard_max',{},'pass',{});
end
function x = LOCAL_empty_k_arcs()
  x = struct('from_node',{},'to_node',{},'side',{},'zeta_index',{}, ...
    'forward_ratio',{},'backward_ratio',{},'forward_residual',{}, ...
    'backward_residual',{},'guard_max',{},'pass',{});
end
function x = LOCAL_empty_projectors()
  x = struct('node_index',{},'side',{},'Nzeta',{}, ...
    'restricted_idempotence',{},'section_invariance',{}, ...
    'qz_difference',{},'range_difference',{},'fixed_row_residual',{}, ...
    'action_nested_difference',{},'section_nested_difference',{}, ...
    'c_relative_difference',{},'common_pass',{},'pass',{});
end
function x = LOCAL_empty_windings()
  x = struct('object',{},'node_count',{},'raw_count',{}, ...
    'rounded_count',{},'integer_residual',{},'integer_residual_max',{}, ...
    'max_edge_guard',{},'edge_guard_max',{},'available',{},'pass',{},'grid',{});
end
function x = LOCAL_empty_phase_edges()
  x = struct('object',{},'from_node',{},'to_node',{}, ...
    'phase_increment',{},'uncertainty_sum',{},'guard_value',{}, ...
    'guard_max',{},'pass',{});
end
function x = LOCAL_empty_gates()
  x = struct('order',{},'name',{},'pass',{},'value',{},'limit',{},'detail',{});
end
function x = LOCAL_empty_failures()
  x = struct('first_failure',{},'identifier',{},'message',{},'elapsed_seconds',{});
end
function x = LOCAL_empty_sources()
  x = struct('name',{},'path',{},'sha256',{});
end
function x = LOCAL_empty_key_values()
  x = struct('key',{},'value',{});
end
function x = LOCAL_empty_lineage()
  x = struct('role',{},'path',{},'expected',{},'actual',{},'pass',{});
end
function x = LOCAL_empty_objects()
  x = struct('object',{},'rows',{},'columns',{},'expected_rows',{}, ...
    'expected_columns',{},'spatial_level',{},'M',{},'K',{},'role',{},'pass',{});
end

function row = LOCAL_oracle_row(name,grid,expected,observed,tolerance, ...
    error_value,pass,min_rcond,max_lu_residual,max_solve_residual)
  row = struct('name',name,'grid',grid,'expected',expected, ...
    'observed',observed,'tolerance',tolerance,'error',error_value, ...
    'min_rcond',min_rcond,'max_lu_residual',max_lu_residual, ...
    'max_solve_residual',max_solve_residual,'pass',pass);
end
function row = LOCAL_gate(order,name,pass,value,limit,detail)
  row = struct('order',order,'name',name,'pass',pass,'value',value, ...
    'limit',limit,'detail',detail);
end
function row = LOCAL_key(key,value)
  row = struct('key',key,'value',value);
end
