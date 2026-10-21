function result = profile_i8(output_dir)
%PROFILE_I8 Time and profile the original I8 single-point locator.
% Purpose:
%   Measure fresh-call, warmed unprofiled, and MATLAB-profiler timings for
%   two frozen I8.1 points without changing the locator computation.
% Input:
%   output_dir - Existing or new directory for machine-readable artifacts.
% Output:
%   result     - Environment, call ledger, repeat summaries, and comparisons.
% Main algorithm:
%   Call locate_i8(k,1,1) exactly as published.  Record one fresh call at
%   k0, explicitly warm each point, take three unprofiled repeats per point,
%   and profile one final call per point in separate profiler sessions.
% Based on:
%   test/i8/locate-v1/locate_i8.m and its frozen I8.1 configuration.
% Main changes:
%   No numerical change.  This wrapper only adds timing, profiler export,
%   environment capture, and repeat-consistency diagnostics.
% Numerical goal:
%   Attribute the cost of one baseline I8.1 evaluation while reproducing
%   the four original singular-value metrics at each representative point.

  if nargin ~= 1 || ~(ischar(output_dir) || ...
      (isstring(output_dir) && isscalar(output_dir)))
    error('i8profile:Arguments','Pass one scalar output directory path.');
  end
  output_dir = char(output_dir);
  if ~isfolder(output_dir)
    mkdir(output_dir);
  end
  required = {'locate_i8','profile'};
  for j = 1:numel(required)
    if isempty(which(required{j}))
      error('i8profile:MissingDependency', ...
        'Required function %s is not on the MATLAB path.',required{j});
    end
  end

  % --- stage 1: freeze points and record the MATLAB environment ---
  k_values = [1.7562818500073463, 1.7562818560000002];
  point_ids = {'k0','k1'};
  repeat_count = 3;
  environment = LOCAL_environment();
  environment.k_values = k_values;
  environment.point_ids = point_ids;
  environment.repeat_count = repeat_count;
  LOCAL_write_json(fullfile(output_dir,'environment.json'),environment);

  calls = repmat(LOCAL_empty_call(),0,1);
  fprintf(1,'I8 profile protocol: fresh call, warmups, repeats, profiles.\n');

  % --- stage 2: fresh call, explicit warmups, and unprofiled repeats ---
  [call,~,~] = LOCAL_call('first',point_ids{1},0,k_values(1));
  calls(end+1,1) = call;
  for p = 1:numel(k_values)
    [call,~,~] = LOCAL_call('warmup',point_ids{p},0,k_values(p));
    calls(end+1,1) = call;
    for r = 1:repeat_count
      [call,~,~] = LOCAL_call('repeat',point_ids{p},r,k_values(p));
      calls(end+1,1) = call;
    end
  end

  % --- stage 3: profile one original evaluation at each point ---
  profile_meta = cell(numel(k_values),1);
  for p = 1:numel(k_values)
    profile clear;
    profile on;
    active_status = profile('status');
    [call,profiled_out,profiled_scan] = ...
      LOCAL_call('profile',point_ids{p},0,k_values(p));
    profile off;
    profile_info = profile('info');
    calls(end+1,1) = call;
    profile_meta{p} = LOCAL_export_profile(output_dir,point_ids{p}, ...
      k_values(p),call,active_status,profile_info, ...
      profiled_out,profiled_scan);
  end
  profile clear;
  profile_meta = vertcat(profile_meta{:});

  % --- stage 4: summarize timing and numerical repeat consistency ---
  summaries = LOCAL_summaries(calls,point_ids,k_values,repeat_count);
  comparisons = LOCAL_comparisons(calls,point_ids);
  result = struct('environment',environment,'calls',calls, ...
    'summaries',summaries,'comparisons',comparisons, ...
    'profile_meta',profile_meta);
  save(fullfile(output_dir,'result.mat'),'result');
  LOCAL_write_json(fullfile(output_dir,'result.json'),result);
  LOCAL_write_calls(fullfile(output_dir,'calls.csv'),calls);
  LOCAL_write_summaries(fullfile(output_dir,'summaries.csv'),summaries);
  LOCAL_write_comparisons(fullfile(output_dir,'comparisons.csv'),comparisons);
  fprintf(1,'I8 profiling artifacts written to %s\n',output_dir);
end

%% ==================== Measurement helpers ====================
% These helpers call the untouched locator and retain both outer and entry time.

function [record,out,scan] = LOCAL_call(phase,point_id,call_index,k)
  outer_timer = tic;
  [out,scan] = locate_i8(k,1,1);
  outer_seconds = toc(outer_timer);
  record = LOCAL_empty_call();
  record.phase = phase;
  record.point_id = point_id;
  record.call_index = call_index;
  record.k = k;
  record.outer_seconds = outer_seconds;
  record.entry_seconds = out.runtime;
  record.wrapper_seconds = outer_seconds-out.runtime;
  record.adef_sigma = scan.adef_sigma(1);
  record.adef_ratio = scan.adef_ratio(1);
  record.aphys_sigma = scan.aphys_sigma(1);
  record.aphys_ratio = scan.aphys_ratio(1);
  fprintf(1,['phase=%s point=%s index=%d k=%.17g outer=%.6f ', ...
    'entry=%.6f aphys_ratio=%.17g\n'],phase,point_id,call_index,k, ...
    outer_seconds,out.runtime,record.aphys_ratio);
end

function record = LOCAL_empty_call()
  record = struct('phase','','point_id','','call_index',0,'k',NaN, ...
    'outer_seconds',NaN,'entry_seconds',NaN,'wrapper_seconds',NaN, ...
    'adef_sigma',NaN,'adef_ratio',NaN, ...
    'aphys_sigma',NaN,'aphys_ratio',NaN);
end

function summaries = LOCAL_summaries(calls,point_ids,k_values,repeat_count)
  summaries = repmat(struct('point_id','','k',NaN,'repeat_count',0, ...
    'outer_min_seconds',NaN,'outer_median_seconds',NaN, ...
    'outer_max_seconds',NaN,'entry_min_seconds',NaN, ...
    'entry_median_seconds',NaN,'entry_max_seconds',NaN, ...
    'adef_sigma',NaN,'adef_ratio',NaN, ...
    'aphys_sigma',NaN,'aphys_ratio',NaN),numel(point_ids),1);
  for p = 1:numel(point_ids)
    use = strcmp({calls.phase},'repeat') & ...
      strcmp({calls.point_id},point_ids{p});
    selected = calls(use);
    if numel(selected) ~= repeat_count
      error('i8profile:RepeatCount', ...
        'Point %s has %d repeats, expected %d.', ...
        point_ids{p},numel(selected),repeat_count);
    end
    outer = [selected.outer_seconds];
    entry = [selected.entry_seconds];
    summaries(p).point_id = point_ids{p};
    summaries(p).k = k_values(p);
    summaries(p).repeat_count = repeat_count;
    summaries(p).outer_min_seconds = min(outer);
    summaries(p).outer_median_seconds = median(outer);
    summaries(p).outer_max_seconds = max(outer);
    summaries(p).entry_min_seconds = min(entry);
    summaries(p).entry_median_seconds = median(entry);
    summaries(p).entry_max_seconds = max(entry);
    summaries(p).adef_sigma = selected(1).adef_sigma;
    summaries(p).adef_ratio = selected(1).adef_ratio;
    summaries(p).aphys_sigma = selected(1).aphys_sigma;
    summaries(p).aphys_ratio = selected(1).aphys_ratio;
  end
end

function comparisons = LOCAL_comparisons(calls,point_ids)
  names = {'adef_sigma','adef_ratio','aphys_sigma','aphys_ratio'};
  template = struct('point_id','','phase','','call_index',0, ...
    'metric','','reference',NaN,'value',NaN, ...
    'absolute_difference',NaN,'relative_difference',NaN);
  comparisons = repmat(template,0,1);
  for p = 1:numel(point_ids)
    reference_index = find(strcmp({calls.phase},'repeat') & ...
      strcmp({calls.point_id},point_ids{p}),1,'first');
    selected_indices = find(strcmp({calls.point_id},point_ids{p}));
    for i = selected_indices
      for m = 1:numel(names)
        row = template;
        row.point_id = point_ids{p};
        row.phase = calls(i).phase;
        row.call_index = calls(i).call_index;
        row.metric = names{m};
        row.reference = calls(reference_index).(names{m});
        row.value = calls(i).(names{m});
        row.absolute_difference = abs(row.value-row.reference);
        if row.reference == 0
          row.relative_difference = NaN;
        else
          row.relative_difference = row.absolute_difference/abs(row.reference);
        end
        comparisons(end+1,1) = row;
      end
    end
  end
end

%% ==================== Profiler export ====================
% These helpers preserve raw data and expose inclusive, child, and derived self time.

function meta = LOCAL_export_profile(output_dir,point_id,k,call,status, ...
    profile_info,profiled_out,profiled_scan)
  prefix = fullfile(output_dir,['profile-' point_id]);
  save([prefix '.mat'],'profile_info','status','call', ...
    'profiled_out','profiled_scan');
  function_rows = LOCAL_function_rows(profile_info.FunctionTable);
  LOCAL_write_function_rows([prefix '-functions.csv'],function_rows);
  LOCAL_write_line_rows([prefix '-lines.csv'],profile_info.FunctionTable);
  LOCAL_write_edge_rows([prefix '-edges.csv'],profile_info.FunctionTable);
  LOCAL_write_json([prefix '-functions.json'],function_rows);
  meta = struct('point_id',point_id,'k',k, ...
    'profile_outer_seconds',call.outer_seconds, ...
    'profile_entry_seconds',call.entry_seconds, ...
    'function_count',numel(profile_info.FunctionTable), ...
    'status',status);
end

function rows = LOCAL_function_rows(function_table)
  template = struct('index',0,'complete_name','','file_name','', ...
    'type','','num_calls',0,'inclusive_seconds',0, ...
    'child_edge_seconds',0,'derived_self_seconds',0, ...
    'parent_count',0,'child_count',0);
  rows = repmat(template,numel(function_table),1);
  for i = 1:numel(function_table)
    child_seconds = LOCAL_child_seconds(function_table(i));
    rows(i).index = i;
    rows(i).complete_name = function_table(i).CompleteName;
    rows(i).file_name = function_table(i).FileName;
    rows(i).type = function_table(i).Type;
    rows(i).num_calls = function_table(i).NumCalls;
    rows(i).inclusive_seconds = function_table(i).TotalTime;
    rows(i).child_edge_seconds = child_seconds;
    rows(i).derived_self_seconds = ...
      function_table(i).TotalTime-child_seconds;
    rows(i).parent_count = numel(function_table(i).Parents);
    rows(i).child_count = numel(function_table(i).Children);
  end
end

function seconds = LOCAL_child_seconds(function_row)
  seconds = 0;
  for j = 1:numel(function_row.Children)
    seconds = seconds+function_row.Children(j).TotalTime;
  end
end

function LOCAL_write_line_rows(path,function_table)
  stream = LOCAL_open(path);
  cleanup = onCleanup(@() fclose(stream));
  fprintf(stream,['function_index,complete_name,line_number,num_calls,', ...
    'inclusive_line_seconds\n']);
  for i = 1:numel(function_table)
    lines = function_table(i).ExecutedLines;
    for j = 1:size(lines,1)
      fprintf(stream,'%d,%s,%d,%.17g,%.17g\n',i, ...
        LOCAL_csv_text(function_table(i).CompleteName),lines(j,1), ...
        lines(j,2),lines(j,3));
    end
  end
  clear cleanup;
end

function LOCAL_write_edge_rows(path,function_table)
  stream = LOCAL_open(path);
  cleanup = onCleanup(@() fclose(stream));
  fprintf(stream,['parent_index,parent_name,child_index,child_name,', ...
    'num_calls,inclusive_edge_seconds\n']);
  for i = 1:numel(function_table)
    children = function_table(i).Children;
    for j = 1:numel(children)
      child_index = children(j).Index;
      child_name = '';
      if child_index >= 1 && child_index <= numel(function_table)
        child_name = function_table(child_index).CompleteName;
      end
      fprintf(stream,'%d,%s,%d,%s,%.17g,%.17g\n',i, ...
        LOCAL_csv_text(function_table(i).CompleteName),child_index, ...
        LOCAL_csv_text(child_name),children(j).NumCalls, ...
        children(j).TotalTime);
    end
  end
  clear cleanup;
end

%% ==================== Environment and artifact writers ====================
% These helpers write portable machine-readable records without reading metadata.

function environment = LOCAL_environment()
  environment = struct();
  environment.matlab_version = version;
  environment.matlab_release = version('-release');
  environment.computer = computer;
  environment.architecture = computer('arch');
  environment.process_id = feature('getpid');
  environment.max_computational_threads = maxNumCompThreads;
  try
    environment.detected_cores = feature('numcores');
  catch error_info
    environment.detected_cores = NaN;
    environment.detected_cores_error = error_info.message;
  end
  environment.OMP_NUM_THREADS = getenv('OMP_NUM_THREADS');
  environment.MKL_NUM_THREADS = getenv('MKL_NUM_THREADS');
  environment.VECLIB_MAXIMUM_THREADS = getenv('VECLIB_MAXIMUM_THREADS');
  environment.locate_i8_path = which('locate_i8');
  environment.profile_i8_path = which('profile_i8');
  environment.started_utc = ...
    char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ssXXX'));
end

function LOCAL_write_calls(path,calls)
  stream = LOCAL_open(path);
  cleanup = onCleanup(@() fclose(stream));
  fprintf(stream,['phase,point_id,call_index,k,outer_seconds,entry_seconds,', ...
    'wrapper_seconds,adef_sigma,adef_ratio,aphys_sigma,aphys_ratio\n']);
  for i = 1:numel(calls)
    fprintf(stream,'%s,%s,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g\n', ...
      LOCAL_csv_text(calls(i).phase),LOCAL_csv_text(calls(i).point_id), ...
      calls(i).call_index,calls(i).k,calls(i).outer_seconds, ...
      calls(i).entry_seconds,calls(i).wrapper_seconds, ...
      calls(i).adef_sigma,calls(i).adef_ratio, ...
      calls(i).aphys_sigma,calls(i).aphys_ratio);
  end
  clear cleanup;
end

function LOCAL_write_summaries(path,summaries)
  stream = LOCAL_open(path);
  cleanup = onCleanup(@() fclose(stream));
  fprintf(stream,['point_id,k,repeat_count,outer_min_seconds,', ...
    'outer_median_seconds,outer_max_seconds,entry_min_seconds,', ...
    'entry_median_seconds,entry_max_seconds,adef_sigma,adef_ratio,', ...
    'aphys_sigma,aphys_ratio\n']);
  for i = 1:numel(summaries)
    row = summaries(i);
    fprintf(stream,['%s,%.17g,%d,%.17g,%.17g,%.17g,%.17g,%.17g,', ...
      '%.17g,%.17g,%.17g,%.17g,%.17g\n'], ...
      LOCAL_csv_text(row.point_id),row.k,row.repeat_count, ...
      row.outer_min_seconds,row.outer_median_seconds,row.outer_max_seconds, ...
      row.entry_min_seconds,row.entry_median_seconds,row.entry_max_seconds, ...
      row.adef_sigma,row.adef_ratio,row.aphys_sigma,row.aphys_ratio);
  end
  clear cleanup;
end

function LOCAL_write_comparisons(path,comparisons)
  stream = LOCAL_open(path);
  cleanup = onCleanup(@() fclose(stream));
  fprintf(stream,['point_id,phase,call_index,metric,reference,value,', ...
    'absolute_difference,relative_difference\n']);
  for i = 1:numel(comparisons)
    row = comparisons(i);
    fprintf(stream,'%s,%s,%d,%s,%.17g,%.17g,%.17g,%.17g\n', ...
      LOCAL_csv_text(row.point_id),LOCAL_csv_text(row.phase), ...
      row.call_index,LOCAL_csv_text(row.metric),row.reference,row.value, ...
      row.absolute_difference,row.relative_difference);
  end
  clear cleanup;
end

function LOCAL_write_function_rows(path,rows)
  stream = LOCAL_open(path);
  cleanup = onCleanup(@() fclose(stream));
  fprintf(stream,['index,complete_name,file_name,type,num_calls,', ...
    'inclusive_seconds,child_edge_seconds,derived_self_seconds,', ...
    'parent_count,child_count\n']);
  for i = 1:numel(rows)
    row = rows(i);
    fprintf(stream,'%d,%s,%s,%s,%.17g,%.17g,%.17g,%.17g,%d,%d\n', ...
      row.index,LOCAL_csv_text(row.complete_name), ...
      LOCAL_csv_text(row.file_name),LOCAL_csv_text(row.type), ...
      row.num_calls,row.inclusive_seconds,row.child_edge_seconds, ...
      row.derived_self_seconds,row.parent_count,row.child_count);
  end
  clear cleanup;
end

function LOCAL_write_json(path,value)
  stream = LOCAL_open(path);
  cleanup = onCleanup(@() fclose(stream));
  fprintf(stream,'%s',jsonencode(value,'PrettyPrint',true));
  clear cleanup;
end

function stream = LOCAL_open(path)
  if isfile(path)
    error('i8profile:OutputExists','Refusing to overwrite %s.',path);
  end
  stream = fopen(path,'w');
  if stream < 0
    error('i8profile:OutputOpen','Unable to open %s.',path);
  end
end

function text = LOCAL_csv_text(value)
  value = char(value);
  value = strrep(value,'"','""');
  text = ['"' value '"'];
end
