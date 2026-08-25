function record = i32_result_output(action,result,c,output,retained_before_mib,cumulative_mib)
%I32_RESULT_OUTPUT Consume and publish one append-only ecap-a3 attempt.
% Purpose:
%   Consume the tag before science dispatch, then publish the final compact
%   result and report into that already-consumed directory exactly once.
% Input:
%   action                  - Exactly 'consume' or 'publish'.
%   result, c, output       - Compact result, contract, and directory.
%   retained_before_mib    - Caller active-object proxy before publication.
%   cumulative_mib         - Prior sequential maximum proxy.
% Output:
%   record                 - Compact publication resource record only.
% Main algorithm:
%   The consume phase creates only the absent directory.  The publish phase
%   requires that directory to remain empty, inserts the publication ledger
%   into the saved result, and serializes result.mat before report.md.
% Notes:
%   A created directory or partial publication is permanent and is never
%   removed, retried, or backfilled.

  action=char(action);
  if strcmp(action,'consume')
    record=LOCAL_consume(result,c,output,retained_before_mib,cumulative_mib);
  elseif strcmp(action,'publish')
    record=LOCAL_publish(result,c,output,retained_before_mib,cumulative_mib);
  else
    error('i32f:PublicationAction','Action must be consume or publish.');
  end
end

%% ==================== Append-only publication ====================
% These helpers consume the attempt tag and serialize one compact result.

function record=LOCAL_consume(result,c,output,retained_before_mib,cumulative_mib)
  if exist(output,'file')||exist(output,'dir')
    error('i32f:OutputExists','The append-only attempt directory already exists.');
  end
  input_alias=LOCAL_value_mib(result); peak=LOCAL_workspace_mib();
  exclusive=max(0,peak-input_alias);
  concurrent=retained_before_mib+max(c.worst_transient_mib,exclusive);
  record=LOCAL_record('attempt_consumption',retained_before_mib,input_alias, ...
    peak,exclusive,concurrent,cumulative_mib,c.worst_transient_mib,false,true);
  [made,message]=mkdir(output);
  if ~made
    error('i32f:PublicationDirectory', ...
      'Attempt directory creation failed while consuming the tag: %s.',message);
  end
  record.directory_created=true;
  record.retained_after_publication_proxy_mib=LOCAL_value_mib(result);
  record.cumulative_peak_candidate_mib=max([cumulative_mib,concurrent, ...
    record.retained_after_publication_proxy_mib]);
end

function record=LOCAL_publish(result,c,output,retained_before_mib,cumulative_mib)
  if ~isfolder(output)
    error('i32f:PublicationDirectory', ...
      'The consumed append-only attempt directory is absent.');
  end
  entries=dir(output); names={entries.name};
  names=names(~ismember(names,{'.','..'}));
  if ~isempty(names)
    error('i32f:PartialPublicationExists', ...
      'The consumed directory is not empty and cannot be retried or backfilled.');
  end
  input_alias=LOCAL_value_mib(result); peak=LOCAL_workspace_mib();
  exclusive=max(0,peak-input_alias);
  concurrent=retained_before_mib+max(c.worst_transient_mib,exclusive);
  record=LOCAL_record('publication',retained_before_mib,input_alias,peak, ...
    exclusive,concurrent,cumulative_mib,c.worst_transient_mib,true,false);
  result.resources.modules.result_output=record;
  after=LOCAL_value_mib(result);
  record.retained_after_publication_proxy_mib=after;
  record.cumulative_peak_candidate_mib=max([cumulative_mib,concurrent,after]);
  result.resources.modules.result_output=record;
  if record.cumulative_peak_candidate_mib>c.memory_mib_max
    result.execution_pass=false;
    if strcmp(result.first_execution_blocker.code,'NONE')
      result.first_execution_blocker=struct( ...
        'code','RESOURCE_LIMIT_EXCEEDED_DURING_PUBLICATION', ...
        'message','The publication active-object proxy exceeded 640 MiB.');
    end
    result.status='I3_2_RESOURCE_BUDGET_UNAVAILABLE';
    result.scientific_outcome='RESOURCE_BUDGET_UNAVAILABLE';
    result.resources.actual.hard_limits_respected=false;
  end
  % Stabilize the record after the publication gate has updated compact status.
  recorded_after=LOCAL_value_mib(result);
  record.retained_after_publication_proxy_mib=recorded_after;
  record.cumulative_peak_candidate_mib=max([cumulative_mib,concurrent,recorded_after]);
  result.resources.modules.result_output=record;
  result.resources.actual.cumulative_peak_candidate_mib= ...
    record.cumulative_peak_candidate_mib;
  result.peak_active_mib=max(result.peak_active_mib, ...
    record.cumulative_peak_candidate_mib);
  % The two scalar updates above preserve the active byte count.
  record.retained_after_publication_proxy_mib=LOCAL_value_mib(result);
  result.resources.modules.result_output=record;

  save(fullfile(output,'result.mat'),'result','-v7.3');
  LOCAL_report(fullfile(output,'report.md'),result);
  after_write=LOCAL_value_mib(result);
  if after_write~=record.retained_after_publication_proxy_mib
    error('i32f:PublicationMemoryLedger', ...
      'The post-write active-object proxy differs from its saved record.');
  end
end

function record=LOCAL_record(phase,retained_before,input_alias,peak,exclusive, ...
    concurrent,cumulative,streaming_floor,consumed_on_entry,absent_on_entry)
  record=struct('phase',phase,'retained_before_mib',retained_before, ...
    'input_alias_nominal_mib',input_alias, ...
    'local_workspace_peak_mib',peak,'module_exclusive_peak_mib',exclusive, ...
    'frozen_streaming_transient_mib',streaming_floor, ...
    'concurrent_peak_candidate_mib',concurrent, ...
    'retained_after_publication_proxy_mib',NaN, ...
    'cumulative_peak_candidate_mib',max(cumulative,concurrent), ...
    'directory_consumed_on_entry',consumed_on_entry, ...
    'directory_absent_on_entry',absent_on_entry, ...
    'directory_creation_consumes_tag',true,'directory_created',false, ...
    'partial_publication_retry_permitted',false, ...
    'proxy_semantics',[ ...
      'deterministic active-object proxy; not RSS, allocator high-water, ', ...
      'reference-count, or copy-on-write proof']);
end

%% ==================== Report and memory proxies ====================
% These helpers render the audit summary and measure active MATLAB values.

function LOCAL_report(path,r)
  fid=fopen(path,'w');
  if fid<0
    error('i32f:ReportOpen','The consumed attempt report could not be opened.');
  end
  cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid,'# I3.2 same-trial empirical cap: ecap-a3\n\n');
  fprintf(fid,'- schema: `%s`\n',r.schema);
  fprintf(fid,'- status: `%s`\n',r.status);
  fprintf(fid,'- scientific outcome: `%s`\n',r.scientific_outcome);
  fprintf(fid,'- execution pass: `%d`\n',r.execution_pass);
  fprintf(fid,'- cap status: `%s`\n',r.cap_status);
  fprintf(fid,'- first execution blocker: `%s`\n', ...
    r.first_execution_blocker.code);
  fprintf(fid,'- first empirical unavailable: `%s`\n', ...
    r.first_empirical_unavailable.code);
  fprintf(fid,'- elapsed seconds: `%.17g`\n',r.elapsed_seconds);
  fprintf(fid,'- peak active proxy MiB: `%.17g`\n\n',r.peak_active_mib);
  fprintf(fid,'## Frozen role and claims\n\n');
  fprintf(fid,'- M=48 role: artificial-wall total Dirichlet trace order only.\n');
  fprintf(fid,'- strict theorem triggered: false.\n');
  fprintf(fid,'- reliable/certified/existence claims: false.\n');
  fprintf(fid,'- independent effectivity reference: false.\n\n');
  if isfield(r,'caps')&&isfield(r.caps,'epsilon_M_emp')
    fprintf(fid,'## Empirical cap\n\n');
    fprintf(fid,'- epsilon_W_emp: `%.17g`\n',r.caps.epsilon_W_emp);
    fprintf(fid,'- epsilon_Gamma_emp: `%.17g`\n',r.caps.epsilon_Gamma_emp);
    fprintf(fid,'- epsilon_V_emp: `%.17g`\n',r.caps.epsilon_V_emp);
    fprintf(fid,'- epsilon_M_emp: `%.17g`\n',r.caps.epsilon_M_emp);
    fprintf(fid,'- epsilon_N_emp: `%.17g`\n',r.caps.epsilon_N_emp);
  end
  if isfield(r,'estimator')&&isfield(r.estimator,'q_emp')
    fprintf(fid,'- q_emp: `%.17g`\n',r.estimator.q_emp);
    fprintf(fid,'- nominal k lower: `%.17g`\n',r.estimator.k_lower);
    fprintf(fid,'- nominal k upper: `%.17g`\n',r.estimator.k_upper);
    fprintf(fid,'- nominal k width: `%.17g`\n',r.estimator.width);
    fprintf(fid,'- width <= 1e-6: `%d`\n',r.estimator.resolution_pass);
  end
  fprintf(fid,'\n## Audit\n\n');
  fprintf(fid,'- full-P contraction count: `%g` (expected 292)\n', ...
    r.call_counters.full_p_contraction_calls);
  fprintf(fid,'- small-Gram eig count: `%g` (expected 274)\n', ...
    r.call_counters.small_hermitian_gram_diagnostic_eig_calls);
  fprintf(fid,'- Gauss eig count: `%g` (expected 6)\n', ...
    r.call_counters.gauss_golub_welsch_eig_calls);
  fprintf(fid,'- total allowlisted eig count: `%g` (expected 280)\n', ...
    r.audit.allowlisted_eig.total);
  fprintf(fid,'- all eight NO_RESOLVE counters zero: `%d`\n', ...
    r.audit.no_resolve.pass);
  fprintf(fid,'- compact final result: true.\n');
  fprintf(fid,'\n## Active-object memory ledger\n\n');
  fprintf(fid,'- attempt directory consumed before science dispatch: `%d`\n\n', ...
    r.resources.attempt_consumption.directory_created);
  fprintf(fid,['| module | retained before MiB | local peak MiB | ', ...
    'exclusive peak MiB | retained after MiB | concurrent candidate MiB |\n']);
  fprintf(fid,'|---|---:|---:|---:|---:|---:|\n');
  names={'certificate','lifting','wall','circle','fullp_cap','result_output'};
  for j=1:numel(names)
    name=names{j};
    if ~isfield(r.resources.modules,name)
      fprintf(fid,'| %s | NaN | NaN | NaN | NaN | NaN |\n',name);
      continue;
    end
    rec=r.resources.modules.(name);
    if isfield(rec,'retained_after_mib')
      retained_after=rec.retained_after_mib;
    else
      retained_after=rec.retained_after_publication_proxy_mib;
    end
    fprintf(fid,'| %s | %.17g | %.17g | %.17g | %.17g | %.17g |\n', ...
      name,rec.retained_before_mib,rec.local_workspace_peak_mib, ...
      rec.module_exclusive_peak_mib,retained_after, ...
      rec.concurrent_peak_candidate_mib);
  end
  fprintf(fid,'\nEvery concurrent candidate applies the frozen 360 MiB floor.\n');
end

function value=LOCAL_workspace_mib()
  info=evalin('caller','whos'); value=sum([info.bytes])/2^20;
end

function value=LOCAL_value_mib(item)
  info=whos('item'); value=info.bytes/2^20;
end
