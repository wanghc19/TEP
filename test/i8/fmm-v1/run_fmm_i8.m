function result = run_fmm_i8(output_dir)
%RUN_FMM_I8 Execute the frozen five-point direct/FMM2D comparison.
% Purpose:
%   Compare the original I8.1 locator, a traceable direct diagnostic copy,
%   and FMM2D smooth-proxy callbacks at fixed points and tolerances.
% Input:
%   output_dir - New or existing directory for raw and summary artifacts.
% Output:
%   result     - Environment, validation, trigger, and performance summaries.
% Main algorithm:
%   Evaluate five fixed points with original/direct/FMM roles, compare raw
%   smooth fields after each timed FMM point, apply the preregistered eps=1e-14
%   trigger, then collect warmup plus three-repeat timing at k0 and k1.
% Based on:
%   research/projects/eig-apost/implementation/i8/p-fmm.md.
% Main changes:
%   This is orchestration and evidence export; fmm_i8_point owns the only
%   change to the frozen numerical point calculation.
% Numerical goal:
%   Determine whether FMM2D preserves the five-point numerical structure and
%   reduces complete warmed point time at the candidate and one neighbor.

  if nargin ~= 1 || ~(ischar(output_dir) || ...
      (isstring(output_dir) && isscalar(output_dir)))
    error('i8fmm:Arguments','Pass one scalar output directory path.');
  end
  output_dir = char(output_dir);
  if ~isfolder(output_dir)
    mkdir(output_dir);
  end
  raw_dir = fullfile(output_dir,'raw');
  if ~isfolder(raw_dir)
    mkdir(raw_dir);
  end
  required = {'locate_i8','fmm_i8_point','hfmm2d','fmm2d'};
  for j = 1:numel(required)
    if isempty(which(required{j}))
      error('i8fmm:MissingDependency', ...
        'Required function %s is not on the MATLAB path.',required{j});
    end
  end

  % --- stage 1: freeze inputs and record the runtime environment ---
  k_values = [1.7562800000000001, 1.7562818432000002, ...
    1.7562818500073463, 1.7562818560000002, 1.7562832000000002];
  point_ids = {'far_left','near_left','k0','k1','far_right'};
  base_eps_values = [1e-10,1e-12];
  repeat_point_indices = [3,4];
  environment = LOCAL_environment(k_values,point_ids,base_eps_values);
  LOCAL_write_json(fullfile(output_dir,'environment.json'),environment);

  validation_rows = repmat(LOCAL_empty_validation_row(),0,1);
  field_rows = repmat(LOCAL_empty_field_row(),0,1);
  originals = repmat(struct('point_id','','k',NaN,'outer_seconds',NaN, ...
    'entry_seconds',NaN,'metrics',struct()),numel(k_values),1);
  directs = cell(numel(k_values),1);

  % --- stage 2: original and diagnostic-direct values at all five points ---
  for p = 1:numel(k_values)
    k = k_values(p);
    point_id = point_ids{p};
    outer_timer = tic;
    [original_out,original_scan] = locate_i8(k,1,1);
    outer_seconds = toc(outer_timer);
    original_metrics = LOCAL_scan_metrics(original_scan);
    originals(p) = struct('point_id',point_id,'k',k, ...
      'outer_seconds',outer_seconds,'entry_seconds',original_out.runtime, ...
      'metrics',original_metrics);
    save(fullfile(raw_dir,['original-' point_id '.mat']), ...
      'original_out','original_scan','outer_seconds');
    validation_rows(end+1,1) = LOCAL_original_row( ...
      point_id,k,outer_seconds,original_out.runtime,original_metrics);

    outer_timer = tic;
    direct_point = fmm_i8_point(k,'direct',NaN,true);
    direct_outer_seconds = toc(outer_timer);
    save(fullfile(raw_dir,['direct-' point_id '.mat']), ...
      'direct_point','direct_outer_seconds');
    directs{p} = direct_point;
    directs{p}.proxy_calls = LOCAL_strip_fields(direct_point.proxy_calls);
    validation_rows(end+1,1) = LOCAL_direct_row( ...
      point_id,direct_point,direct_outer_seconds,original_metrics);
    fprintf(1,['validation method=direct point=%s k=%.17g outer=%.6f ', ...
      'aphys_ratio=%.17g\n'],point_id,k,direct_outer_seconds, ...
      direct_point.metrics.aphys_ratio);
  end

  % --- stage 3: two preregistered FMM tolerances at all five points ---
  for e = 1:numel(base_eps_values)
    requested_eps = base_eps_values(e);
    [new_validation,new_fields] = LOCAL_validation_tier( ...
      raw_dir,k_values,point_ids,directs,requested_eps);
    validation_rows = [validation_rows;new_validation]; %#ok<AGROW>
    field_rows = [field_rows;new_fields]; %#ok<AGROW>
  end

  % --- stage 4: apply the fixed third-tier trigger, without tuning ---
  trigger = LOCAL_third_tier_trigger(validation_rows);
  fmm_eps_values = base_eps_values;
  if trigger.triggered
    requested_eps = 1e-14;
    fmm_eps_values(end+1) = requested_eps;
    [new_validation,new_fields] = LOCAL_validation_tier( ...
      raw_dir,k_values,point_ids,directs,requested_eps);
    validation_rows = [validation_rows;new_validation]; %#ok<AGROW>
    field_rows = [field_rows;new_fields]; %#ok<AGROW>
  end
  LOCAL_write_json(fullfile(output_dir,'third-tier-trigger.json'),trigger);

  % --- stage 5: fixed warmed timing protocol at k0 and k1 ---
  performance_rows = repmat(LOCAL_empty_performance_row(),0,1);
  for p = repeat_point_indices
    point_id = point_ids{p};
    k = k_values(p);
    method_specs = LOCAL_method_specs(fmm_eps_values);
    for m = 1:numel(method_specs)
      performance_rows(end+1,1) = LOCAL_performance_call( ...
        point_id,k,'warmup',0,method_specs(m)); %#ok<AGROW>
    end
    orders = LOCAL_repeat_orders(numel(method_specs));
    for round_index = 1:3
      for position = 1:size(orders,2)
        m = orders(round_index,position);
        performance_rows(end+1,1) = LOCAL_performance_call( ...
          point_id,k,'repeat',round_index,method_specs(m)); %#ok<AGROW>
      end
    end
  end

  % --- stage 6: export summaries after all timed evaluations ---
  performance_summary = LOCAL_performance_summary( ...
    performance_rows,point_ids(repeat_point_indices));
  result = struct('environment',environment, ...
    'validation_rows',validation_rows,'field_rows',field_rows, ...
    'third_tier_trigger',trigger,'fmm_eps_values',fmm_eps_values, ...
    'performance_rows',performance_rows, ...
    'performance_summary',performance_summary);
  save(fullfile(output_dir,'result.mat'),'result');
  LOCAL_write_json(fullfile(output_dir,'result.json'),result);
  writetable(struct2table(validation_rows), ...
    fullfile(output_dir,'validation.csv'));
  writetable(struct2table(field_rows),fullfile(output_dir,'field-errors.csv'));
  writetable(struct2table(performance_rows), ...
    fullfile(output_dir,'performance-calls.csv'));
  writetable(struct2table(performance_summary), ...
    fullfile(output_dir,'performance-summary.csv'));
  fprintf(1,'I8 FMM2D artifacts written to %s\n',output_dir);
end

%% ==================== Validation orchestration ====================
% These helpers run one FMM tolerance and compare it with the saved direct point.

function [validation_rows,field_rows] = LOCAL_validation_tier( ...
    raw_dir,k_values,point_ids,directs,requested_eps)
  validation_rows = repmat(LOCAL_empty_validation_row(),0,1);
  field_rows = repmat(LOCAL_empty_field_row(),0,1);
  eps_id = LOCAL_eps_id(requested_eps);
  for p = 1:numel(k_values)
    outer_timer = tic;
    fmm_point = fmm_i8_point(k_values(p),'fmm',requested_eps,true);
    fmm_outer_seconds = toc(outer_timer);
    direct_raw = load(fullfile(raw_dir,['direct-' point_ids{p} '.mat']), ...
      'direct_point');
    [field_evidence,new_field_rows,comparison_seconds] = ...
      LOCAL_field_evidence(point_ids{p}, ...
      direct_raw.direct_point.proxy_calls,fmm_point.proxy_calls,requested_eps);
    matrix_comparison = struct( ...
      'Adef',LOCAL_matrix_comparison(fmm_point.Adef,directs{p}.Adef), ...
      'Aphys',LOCAL_matrix_comparison(fmm_point.Aphys,directs{p}.Aphys));
    metric_comparison = LOCAL_metric_comparison( ...
      fmm_point.metrics,directs{p}.metrics,matrix_comparison);
    proxy_calls = LOCAL_strip_fields(fmm_point.proxy_calls);
    fmm_point.proxy_calls = proxy_calls;
    save(fullfile(raw_dir,['fmm-' eps_id '-' point_ids{p} '.mat']), ...
      'fmm_point','fmm_outer_seconds','comparison_seconds', ...
      'field_evidence','matrix_comparison','metric_comparison');
    validation_rows(end+1,1) = LOCAL_fmm_row( ...
      point_ids{p},fmm_point,fmm_outer_seconds,comparison_seconds, ...
      matrix_comparison,metric_comparison,new_field_rows); %#ok<AGROW>
    field_rows = [field_rows;new_field_rows]; %#ok<AGROW>
    fprintf(1,['validation method=fmm point=%s eps=%.0e outer=%.6f ', ...
      'comparison=%.6f aphys_ratio=%.17g\n'],point_ids{p}, ...
      requested_eps,fmm_outer_seconds,comparison_seconds, ...
      fmm_point.metrics.aphys_ratio);
  end
end

function [evidence,rows,total_seconds] = LOCAL_field_evidence( ...
    point_id,direct_calls,fmm_calls,requested_eps)
  evidence = repmat(struct('cell_id','','sources',[],'charge',[], ...
    'target',[],'direct_pot',[],'direct_grad',[],'direct_hess',[], ...
    'fmm_pot',[],'fmm_grad',[],'fmm_hess',[], ...
    'minimum_distance',NaN,'direct_seconds',NaN,'summary',[]), ...
    numel(fmm_calls),1);
  rows = repmat(LOCAL_empty_field_row(),0,1);
  total_timer = tic;
  if numel(direct_calls) ~= 2 || numel(fmm_calls) ~= 2
    error('i8fmm:CapturedCallCount','Expected two calls from each method.');
  end
  for c = 1:numel(fmm_calls)
    direct_call = direct_calls(c);
    fmm_call = fmm_calls(c);
    if fmm_call.ns ~= 320 || fmm_call.nt ~= 65536 || fmm_call.ier ~= 0 || ...
        ~isequal(size(fmm_call.sources),[2,fmm_call.ns]) || ...
        ~isequal(size(fmm_call.charge),[1,fmm_call.ns]) || ...
        ~isequal(size(fmm_call.target),[2,fmm_call.nt]) || ...
        ~isequal(size(fmm_call.pot),[1,fmm_call.nt]) || ...
        ~isequal(size(fmm_call.grad),[2,fmm_call.nt]) || ...
        ~isequal(size(fmm_call.hess),[3,fmm_call.nt]) || ...
        ~isequal(size(direct_call.pot),[1,fmm_call.nt]) || ...
        ~isequal(size(direct_call.grad),[2,fmm_call.nt]) || ...
        ~isequal(size(direct_call.hess),[3,fmm_call.nt])
      error('i8fmm:CapturedShape','Captured FMM call has an unexpected shape.');
    end
    inputs_equal = strcmp(direct_call.cell_id,fmm_call.cell_id) && ...
      isequaln(direct_call.wavek,fmm_call.wavek) && ...
      isequaln(direct_call.sources,fmm_call.sources) && ...
      isequaln(direct_call.charge,fmm_call.charge) && ...
      isequaln(direct_call.target,fmm_call.target);
    if ~inputs_equal
      error('i8fmm:CallbackInputMismatch', ...
        'Direct and FMM callback inputs differ at %s.',fmm_call.cell_id);
    end
    minimum_distance = LOCAL_minimum_distance( ...
      fmm_call.sources,fmm_call.target);
    summary = [ ...
      LOCAL_field_component('pot',direct_call.pot,fmm_call.pot); ...
      LOCAL_field_component('grad_x',direct_call.grad(1,:),fmm_call.grad(1,:)); ...
      LOCAL_field_component('grad_y',direct_call.grad(2,:),fmm_call.grad(2,:)); ...
      LOCAL_field_component('hess_xx',direct_call.hess(1,:),fmm_call.hess(1,:)); ...
      LOCAL_field_component('hess_xy',direct_call.hess(2,:),fmm_call.hess(2,:)); ...
      LOCAL_field_component('hess_yy',direct_call.hess(3,:),fmm_call.hess(3,:))];
    for s = 1:numel(summary)
      row = LOCAL_empty_field_row();
      row.point_id = point_id;
      row.k = fmm_call.wavek;
      row.requested_eps = requested_eps;
      row.cell_id = fmm_call.cell_id;
      row.component = summary(s).component;
      row.ns = fmm_call.ns;
      row.nt = fmm_call.nt;
      row.ier = fmm_call.ier;
      row.minimum_distance = minimum_distance;
      row.direct_norm = summary(s).direct_norm;
      row.fmm_norm = summary(s).fmm_norm;
      row.direct_maxabs = summary(s).direct_maxabs;
      row.fmm_maxabs = summary(s).fmm_maxabs;
      row.maxabs_difference = summary(s).maxabs_difference;
      row.fro_difference = summary(s).fro_difference;
      row.scaled_infinity_error = summary(s).scaled_infinity_error;
      row.scaled_fro_error = summary(s).scaled_fro_error;
      row.engineering_gate = max(row.scaled_infinity_error, ...
        row.scaled_fro_error) <= 1000*requested_eps;
      row.evaluator_seconds = fmm_call.evaluator_seconds;
      row.direct_reference_seconds = direct_call.evaluator_seconds;
      rows(end+1,1) = row; %#ok<AGROW>
    end
    evidence(c) = struct('cell_id',fmm_call.cell_id, ...
      'sources',fmm_call.sources,'charge',fmm_call.charge, ...
      'target',fmm_call.target, ...
      'direct_pot',direct_call.pot,'direct_grad',direct_call.grad, ...
      'direct_hess',direct_call.hess,'fmm_pot',fmm_call.pot, ...
      'fmm_grad',fmm_call.grad,'fmm_hess',fmm_call.hess, ...
      'minimum_distance',minimum_distance, ...
      'direct_seconds',direct_call.evaluator_seconds,'summary',summary);
  end
  total_seconds = toc(total_timer);
end

function summary = LOCAL_field_component(component,direct_value,fmm_value)
  difference = fmm_value-direct_value;
  summary = struct('component',component, ...
    'direct_norm',norm(direct_value,'fro'), ...
    'fmm_norm',norm(fmm_value,'fro'), ...
    'direct_maxabs',max(abs(direct_value),[],'all'), ...
    'fmm_maxabs',max(abs(fmm_value),[],'all'), ...
    'maxabs_difference',max(abs(difference),[],'all'), ...
    'fro_difference',norm(difference,'fro'), ...
    'scaled_infinity_error',max(abs(difference),[],'all') / ...
      max(1,max(abs(direct_value),[],'all')), ...
    'scaled_fro_error',norm(difference,'fro') / ...
      max(1,norm(direct_value,'fro')));
end

function minimum_distance = LOCAL_minimum_distance(sources,target)
  minimum_distance = Inf;
  target_batch = 512;
  for first = 1:target_batch:size(target,2)
    index = first:min(first+target_batch-1,size(target,2));
    dx = target(1,index).'-sources(1,:);
    dy = target(2,index).'-sources(2,:);
    minimum_distance = min(minimum_distance, ...
      min(hypot(dx,dy),[],'all'));
  end
end

function comparison = LOCAL_matrix_comparison(value,reference)
  difference = value-reference;
  reference_fro = norm(reference,'fro');
  reference_spectral = norm(reference,2);
  comparison = struct( ...
    'maxabs',max(abs(difference),[],'all'), ...
    'frobenius_absolute',norm(difference,'fro'), ...
    'frobenius_relative',norm(difference,'fro')/max(1,reference_fro), ...
    'spectral_absolute',norm(difference,2), ...
    'spectral_relative',norm(difference,2)/max(1,reference_spectral), ...
    'reference_frobenius',reference_fro, ...
    'reference_spectral',reference_spectral);
end

function comparison = LOCAL_metric_comparison(value,reference,matrix_comparison)
  names = {'adef_sigma','adef_ratio','aphys_sigma','aphys_ratio'};
  comparison = struct();
  for j = 1:numel(names)
    name = names{j};
    absolute = abs(value.(name)-reference.(name));
    relative = absolute/abs(reference.(name));
    comparison.(name) = struct('value',value.(name), ...
      'reference',reference.(name),'absolute',absolute,'relative',relative);
  end
  comparison.adef_weyl = comparison.adef_sigma.absolute <= ...
    matrix_comparison.Adef.spectral_absolute + ...
    100*eps(max(1,matrix_comparison.Adef.reference_spectral));
  comparison.aphys_weyl = comparison.aphys_sigma.absolute <= ...
    matrix_comparison.Aphys.spectral_absolute + ...
    100*eps(max(1,matrix_comparison.Aphys.reference_spectral));
end

%% ==================== Trigger and performance ====================
% These helpers implement the preregistered third tier and timing order.

function trigger = LOCAL_third_tier_trigger(rows)
  fmm10 = rows(strcmp({rows.method},'fmm') & [rows.requested_eps] == 1e-10);
  fmm12 = rows(strcmp({rows.method},'fmm') & [rows.requested_eps] == 1e-12);
  direct = rows(strcmp({rows.method},'direct'));
  if numel(fmm10) ~= 5 || numel(fmm12) ~= 5 || numel(direct) ~= 5
    error('i8fmm:TriggerInputs','Third-tier trigger requires five rows per role.');
  end
  candidate_index = find(strcmp({fmm12.point_id},'k0'),1);
  direct_candidate_index = find(strcmp({direct.point_id},'k0'),1);
  criterion_1 = fmm12(candidate_index).aphys_sigma > ...
    3*direct(direct_candidate_index).aphys_sigma && ...
    fmm12(candidate_index).aphys_spectral_absolute > ...
    direct(direct_candidate_index).aphys_sigma;
  errors10 = [[fmm10.adef_frobenius_relative], ...
    [fmm10.aphys_frobenius_relative]];
  errors12 = [[fmm12.adef_frobenius_relative], ...
    [fmm12.aphys_frobenius_relative]];
  contraction = errors10./errors12;
  criterion_2a = median(contraction) < 5;
  criterion_2b = any(errors12 > 2*errors10);
  trigger = struct('criterion_1_candidate_floor',criterion_1, ...
    'criterion_2a_median_contraction',criterion_2a, ...
    'criterion_2b_any_degradation',criterion_2b, ...
    'median_contraction_factor',median(contraction), ...
    'minimum_contraction_factor',min(contraction), ...
    'maximum_contraction_factor',max(contraction), ...
    'triggered',criterion_1 || criterion_2a || criterion_2b, ...
    'third_eps',1e-14);
end

function specs = LOCAL_method_specs(fmm_eps_values)
  specs = repmat(struct('method','','requested_eps',NaN), ...
    1,1+numel(fmm_eps_values));
  specs(1) = struct('method','direct','requested_eps',NaN);
  for j = 1:numel(fmm_eps_values)
    specs(j+1) = struct('method','fmm', ...
      'requested_eps',fmm_eps_values(j));
  end
end

function orders = LOCAL_repeat_orders(method_count)
  if method_count == 3
    orders = [1,2,3;2,3,1;3,1,2];
  elseif method_count == 4
    orders = [1,2,3,4;2,3,4,1;3,4,1,2];
  else
    error('i8fmm:MethodCount','Expected three or four performance methods.');
  end
end

function row = LOCAL_performance_call(point_id,k,phase,round_index,spec)
  outer_timer = tic;
  point = fmm_i8_point(k,spec.method,spec.requested_eps,false);
  outer_seconds = toc(outer_timer);
  row = LOCAL_empty_performance_row();
  row.point_id = point_id;
  row.k = k;
  row.phase = phase;
  row.round_index = round_index;
  row.method = spec.method;
  row.requested_eps = spec.requested_eps;
  row.outer_seconds = outer_seconds;
  row.point_seconds = point.point_seconds;
  row.wrapper_seconds = outer_seconds-point.point_seconds;
  row.adef_sigma = point.metrics.adef_sigma;
  row.adef_ratio = point.metrics.adef_ratio;
  row.aphys_sigma = point.metrics.aphys_sigma;
  row.aphys_ratio = point.metrics.aphys_ratio;
  if strcmp(spec.method,'fmm')
    row.fmm_evaluator_seconds = sum([point.proxy_calls.evaluator_seconds]);
    row.fmm_call_count = numel(point.proxy_calls);
  end
  fprintf(1,['performance phase=%s round=%d method=%s eps=%.0e ', ...
    'point=%s outer=%.6f aphys_ratio=%.17g\n'],phase,round_index, ...
    spec.method,spec.requested_eps,point_id,outer_seconds, ...
    point.metrics.aphys_ratio);
end

function summary = LOCAL_performance_summary(rows,point_ids)
  repeat_rows = rows(strcmp({rows.phase},'repeat'));
  keys = unique(strcat({repeat_rows.method},'_', ...
    cellfun(@(x) sprintf('%.0e',x),num2cell([repeat_rows.requested_eps]), ...
      'UniformOutput',false)),'stable');
  template = struct('point_id','','method','','requested_eps',NaN, ...
    'repeat_count',0,'outer_min_seconds',NaN, ...
    'outer_median_seconds',NaN,'outer_max_seconds',NaN, ...
    'point_min_seconds',NaN,'point_median_seconds',NaN, ...
    'point_max_seconds',NaN,'adef_sigma',NaN,'adef_ratio',NaN, ...
    'aphys_sigma',NaN,'aphys_ratio',NaN);
  summary = repmat(template,0,1);
  for p = 1:numel(point_ids)
    for key_index = 1:numel(keys)
      point_rows = repeat_rows(strcmp({repeat_rows.point_id},point_ids{p}));
      row_keys = strcat({point_rows.method},'_', ...
        cellfun(@(x) sprintf('%.0e',x), ...
          num2cell([point_rows.requested_eps]),'UniformOutput',false));
      selected = point_rows(strcmp(row_keys,keys{key_index}));
      if isempty(selected)
        continue;
      end
      if numel(selected) ~= 3
        error('i8fmm:RepeatCount','Each performance method needs 3 repeats.');
      end
      outer = [selected.outer_seconds];
      inner = [selected.point_seconds];
      row = template;
      row.point_id = point_ids{p};
      row.method = selected(1).method;
      row.requested_eps = selected(1).requested_eps;
      row.repeat_count = numel(selected);
      row.outer_min_seconds = min(outer);
      row.outer_median_seconds = median(outer);
      row.outer_max_seconds = max(outer);
      row.point_min_seconds = min(inner);
      row.point_median_seconds = median(inner);
      row.point_max_seconds = max(inner);
      row.adef_sigma = selected(1).adef_sigma;
      row.adef_ratio = selected(1).adef_ratio;
      row.aphys_sigma = selected(1).aphys_sigma;
      row.aphys_ratio = selected(1).aphys_ratio;
      summary(end+1,1) = row; %#ok<AGROW>
    end
  end
end

%% ==================== Row construction and export ====================
% These helpers keep machine-readable records compact and non-overlapping.

function row = LOCAL_original_row(point_id,k,outer_seconds,entry_seconds,metrics)
  row = LOCAL_empty_validation_row();
  row.point_id = point_id;
  row.k = k;
  row.method = 'original';
  row.outer_seconds = outer_seconds;
  row.point_seconds = entry_seconds;
  row.wrapper_seconds = outer_seconds-entry_seconds;
  row = LOCAL_copy_metrics(row,metrics);
end

function row = LOCAL_direct_row(point_id,point,outer_seconds,original_metrics)
  row = LOCAL_empty_validation_row();
  row.point_id = point_id;
  row.k = point.k;
  row.method = 'direct';
  row.outer_seconds = outer_seconds;
  row.point_seconds = point.point_seconds;
  row.wrapper_seconds = outer_seconds-point.point_seconds;
  row = LOCAL_copy_metrics(row,point.metrics);
  differences = abs(LOCAL_metric_vector(point.metrics) - ...
    LOCAL_metric_vector(original_metrics));
  row.original_metric_maxabs = max(differences);
  row.original_metrics_bitwise_equal = ...
    isequaln(LOCAL_metric_vector(point.metrics), ...
    LOCAL_metric_vector(original_metrics));
end

function row = LOCAL_fmm_row(point_id,point,outer_seconds, ...
    comparison_seconds,matrix_comparison,metric_comparison,field_rows)
  row = LOCAL_empty_validation_row();
  row.point_id = point_id;
  row.k = point.k;
  row.method = 'fmm';
  row.requested_eps = point.requested_eps;
  row.outer_seconds = outer_seconds;
  row.point_seconds = point.point_seconds;
  row.wrapper_seconds = outer_seconds-point.point_seconds;
  row.comparison_seconds = comparison_seconds;
  row = LOCAL_copy_metrics(row,point.metrics);
  row.adef_maxabs = matrix_comparison.Adef.maxabs;
  row.adef_frobenius_absolute = ...
    matrix_comparison.Adef.frobenius_absolute;
  row.adef_frobenius_relative = ...
    matrix_comparison.Adef.frobenius_relative;
  row.adef_spectral_absolute = ...
    matrix_comparison.Adef.spectral_absolute;
  row.adef_spectral_relative = ...
    matrix_comparison.Adef.spectral_relative;
  row.aphys_maxabs = matrix_comparison.Aphys.maxabs;
  row.aphys_frobenius_absolute = ...
    matrix_comparison.Aphys.frobenius_absolute;
  row.aphys_frobenius_relative = ...
    matrix_comparison.Aphys.frobenius_relative;
  row.aphys_spectral_absolute = ...
    matrix_comparison.Aphys.spectral_absolute;
  row.aphys_spectral_relative = ...
    matrix_comparison.Aphys.spectral_relative;
  row.adef_sigma_absolute_difference = ...
    metric_comparison.adef_sigma.absolute;
  row.adef_ratio_absolute_difference = ...
    metric_comparison.adef_ratio.absolute;
  row.aphys_sigma_absolute_difference = ...
    metric_comparison.aphys_sigma.absolute;
  row.aphys_ratio_absolute_difference = ...
    metric_comparison.aphys_ratio.absolute;
  row.adef_weyl = metric_comparison.adef_weyl;
  row.aphys_weyl = metric_comparison.aphys_weyl;
  row.field_engineering_gate = all([field_rows.engineering_gate]);
  row.matrix_engineering_gate = ...
    row.adef_frobenius_relative <= 1000*point.requested_eps && ...
    row.aphys_frobenius_relative <= 1000*point.requested_eps;
  row.fmm_call_count = numel(point.proxy_calls);
  row.fmm_evaluator_seconds = sum([point.proxy_calls.evaluator_seconds]);
  row.fmm_ier_max = max([point.proxy_calls.ier]);
end

function row = LOCAL_copy_metrics(row,metrics)
  row.adef_sigma = metrics.adef_sigma;
  row.adef_sigma_max = metrics.adef_sigma_max;
  row.adef_ratio = metrics.adef_ratio;
  row.aphys_sigma = metrics.aphys_sigma;
  row.aphys_sigma_max = metrics.aphys_sigma_max;
  row.aphys_ratio = metrics.aphys_ratio;
end

function metrics = LOCAL_scan_metrics(scan)
  metrics = struct('adef_sigma',scan.adef_sigma(1), ...
    'adef_sigma_max',NaN,'adef_ratio',scan.adef_ratio(1), ...
    'aphys_sigma',scan.aphys_sigma(1), ...
    'aphys_sigma_max',NaN,'aphys_ratio',scan.aphys_ratio(1));
end

function values = LOCAL_metric_vector(metrics)
  values = [metrics.adef_sigma,metrics.adef_ratio, ...
    metrics.aphys_sigma,metrics.aphys_ratio];
end

function row = LOCAL_empty_validation_row()
  row = struct('point_id','','k',NaN,'method','', ...
    'requested_eps',NaN,'outer_seconds',NaN,'point_seconds',NaN, ...
    'wrapper_seconds',NaN,'comparison_seconds',NaN, ...
    'adef_sigma',NaN,'adef_sigma_max',NaN,'adef_ratio',NaN, ...
    'aphys_sigma',NaN,'aphys_sigma_max',NaN,'aphys_ratio',NaN, ...
    'original_metric_maxabs',NaN,'original_metrics_bitwise_equal',false, ...
    'adef_maxabs',NaN,'adef_frobenius_absolute',NaN, ...
    'adef_frobenius_relative',NaN,'adef_spectral_absolute',NaN, ...
    'adef_spectral_relative',NaN,'aphys_maxabs',NaN, ...
    'aphys_frobenius_absolute',NaN,'aphys_frobenius_relative',NaN, ...
    'aphys_spectral_absolute',NaN,'aphys_spectral_relative',NaN, ...
    'adef_sigma_absolute_difference',NaN, ...
    'adef_ratio_absolute_difference',NaN, ...
    'aphys_sigma_absolute_difference',NaN, ...
    'aphys_ratio_absolute_difference',NaN, ...
    'adef_weyl',false,'aphys_weyl',false, ...
    'field_engineering_gate',false,'matrix_engineering_gate',false, ...
    'fmm_call_count',0,'fmm_evaluator_seconds',NaN,'fmm_ier_max',NaN);
end

function row = LOCAL_empty_field_row()
  row = struct('point_id','','k',NaN,'requested_eps',NaN, ...
    'cell_id','','component','','ns',0,'nt',0,'ier',NaN, ...
    'minimum_distance',NaN,'direct_norm',NaN,'fmm_norm',NaN, ...
    'direct_maxabs',NaN,'fmm_maxabs',NaN, ...
    'maxabs_difference',NaN,'fro_difference',NaN, ...
    'scaled_infinity_error',NaN,'scaled_fro_error',NaN, ...
    'engineering_gate',false,'evaluator_seconds',NaN, ...
    'direct_reference_seconds',NaN);
end

function row = LOCAL_empty_performance_row()
  row = struct('point_id','','k',NaN,'phase','','round_index',0, ...
    'method','','requested_eps',NaN,'outer_seconds',NaN, ...
    'point_seconds',NaN,'wrapper_seconds',NaN, ...
    'adef_sigma',NaN,'adef_ratio',NaN, ...
    'aphys_sigma',NaN,'aphys_ratio',NaN, ...
    'fmm_evaluator_seconds',NaN,'fmm_call_count',0);
end

function calls = LOCAL_strip_fields(calls)
  for j = 1:numel(calls)
    calls(j).sources = [];
    calls(j).charge = [];
    calls(j).target = [];
    calls(j).pot = [];
    calls(j).grad = [];
    calls(j).hess = [];
  end
end

function eps_id = LOCAL_eps_id(requested_eps)
  eps_id = strrep(sprintf('eps%.0e',requested_eps),'-','m');
end

function environment = LOCAL_environment(k_values,point_ids,eps_values)
  thread_limit = NaN;
  try
    thread_limit = maxNumCompThreads;
  catch
  end
  environment = struct( ...
    'generated_utc',char(datetime('now','TimeZone','UTC', ...
      'Format','yyyy-MM-dd''T''HH:mm:ss''Z''')), ...
    'matlab_version',version,'matlab_release',version('-release'), ...
    'computer',computer,'computer_arch',computer('arch'), ...
    'max_num_comp_threads',thread_limit, ...
    'omp_num_threads',getenv('OMP_NUM_THREADS'), ...
    'omp_dynamic',getenv('OMP_DYNAMIC'), ...
    'omp_proc_bind',getenv('OMP_PROC_BIND'), ...
    'hfmm2d_path',which('hfmm2d'),'fmm2d_path',which('fmm2d'), ...
    'locate_i8_path',which('locate_i8'), ...
    'fmm_i8_point_path',which('fmm_i8_point'), ...
    'k_values',k_values,'point_ids',{point_ids}, ...
    'base_eps_values',eps_values, ...
    'frozen_config',struct('ntot',256,'nside',160,'ntop',160, ...
      'nproxy',80,'mpw',32,'M',48));
end

function LOCAL_write_json(path,value)
  stream = fopen(path,'w');
  if stream < 0
    error('i8fmm:Output','Could not open %s for writing.',path);
  end
  cleanup = onCleanup(@() fclose(stream));
  fwrite(stream,jsonencode(value,'PrettyPrint',true),'char');
  fwrite(stream,newline,'char');
  clear cleanup;
end
