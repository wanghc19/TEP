function result = run_reconstruct_i93(output_dir)
%RUN_RECONSTRUCT_I93 Save one fixed-FEM-frequency BIE reconstructed estimate.
% Purpose: Run only reconstruct_i93 and retain raw field and jump evidence.
% Based on: I9.2 serialization convention; this is a new minimal one-run wrapper.
% Main changes: no setup mode, old driver, FEM solver or historical input.
% Input: output_dir is a fresh path supplied by the monitored local launcher.
% Output: evidence.mat, result/config/environment JSON and full failure context.
  assert(~isfile(fullfile(output_dir,'evidence.mat')), ...
    'i93bie:ExistingRun','Refusing to overwrite raw reconstruction evidence.');
  if ~isfolder(output_dir), mkdir(output_dir); end
  config=reconstruct_i93_config();
  maxNumCompThreads(config.backend.threads);
  environment=struct('version',version,'platform',computer, ...
    'threads',maxNumCompThreads,'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS'), ...
    'OMP_DYNAMIC',getenv('OMP_DYNAMIC'),'hfmm2d',which('hfmm2d'), ...
    'construct_S',which('bloch.construct_S'),'review_type','MAIN_AGENT_SELF_CHECK_ONLY');
  LOCAL_json(fullfile(output_dir,'config.json'),config);
  LOCAL_json(fullfile(output_dir,'environment.json'),environment);
  timer=tic;
  try
    [result,evidence]=reconstruct_i93();
    save_timer=tic;
    evidence=LOCAL_serializable(evidence);
    save(fullfile(output_dir,'evidence.mat'),'result','evidence','config','environment','-v7');
    result.export_seconds=toc(save_timer);
    result.matlab_driver_seconds=toc(timer);
    LOCAL_json(fullfile(output_dir,'result.json'),result);
    fprintf('RESULT %s k=%.17g mu=%.17g C=%.17g epsilon=%.17g U=%.17g Q=%.17g denominator=%.17g R=%.17g\n', ...
      result.status,result.k0,result.mu_num,result.C_num,result.epsilon_num, ...
      result.U_num,result.Q_num,result.denominator,result.R_num);
  catch err
    failure=struct('identifier',err.identifier,'message',err.message, ...
      'stack',err.stack,'report',getReport(err,'extended','hyperlinks','off'), ...
      'stage','see preceding stage marker','k',config.k0,'config',config, ...
      'elapsed_seconds',toc(timer));
    if ~isempty(err.stack), failure.stage=err.stack(1).name; end
    LOCAL_json(fullfile(output_dir,'failure.json'),failure);
    rethrow(err);
  end
end

%% ==================== Evidence export ====================
% Replace callbacks only after computation; all numerical arrays are retained.
function out=LOCAL_serializable(value)
  if isa(value,'function_handle'), out=func2str(value);
  elseif isstruct(value)
    out=value; names=fieldnames(value);
    for j=1:numel(value)
      for n=1:numel(names), out(j).(names{n})=LOCAL_serializable(value(j).(names{n})); end
    end
  elseif iscell(value)
    out=cellfun(@LOCAL_serializable,value,'UniformOutput',false);
  else, out=value;
  end
end

function LOCAL_json(path,value)
  fid=fopen(path,'w');
  assert(fid>=0,'i93bie:Output','Cannot write %s.',path);
  guard=onCleanup(@()fclose(fid)); %#ok<NASGU>
  fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end
