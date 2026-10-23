function result = estimate_i9_run(output_dir,mode)
%ESTIMATE_I9_RUN Export one fresh I9.2 estimate and its raw fixed-field evidence.
% Based on: I8 pipeline batch export and I9.1 monitored serial execution.
% Inputs: output_dir is a new run directory; mode is 'run' or 'config'.
% No historical result, document, Git state or repository layout is read.
  if nargin<2, mode='run'; end
  config=estimate_i9_config();
  if ~exist(output_dir,'dir'), mkdir(output_dir); end
  maxNumCompThreads(config.backend.threads);
  LOCAL_json(fullfile(output_dir,'config.json'),config);
  environment=struct('version',version,'platform',computer,'threads',maxNumCompThreads, ...
    'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS'),'OMP_DYNAMIC',getenv('OMP_DYNAMIC'), ...
    'hfmm2d',which('hfmm2d'),'construct_S',which('bloch.construct_S'));
  LOCAL_json(fullfile(output_dir,'environment.json'),environment);
  if strcmp(mode,'config'), result=config; return; end
  assert(strcmp(mode,'run'),'i92:Mode','Unknown mode %s.',mode);
  assert(~exist(fullfile(output_dir,'evidence.mat'),'file'),'i92:ExistingRun','Raw evidence already exists.');
  timer=tic;
  try
    [result,evidence]=estimate_i9_numeric();
    save_timer=tic;
    evidence=LOCAL_serializable(evidence);
    save(fullfile(output_dir,'evidence.mat'),'result','evidence','config','environment','-v7');
    result.export_seconds=toc(save_timer);
    result.matlab_driver_seconds=toc(timer);
    LOCAL_json(fullfile(output_dir,'result.json'),result);
    fprintf('RESULT %s k=%.17g C=%.17g epsilon=%.17g U=%.17g Q=%.17g denominator=%.17g R=%.17g\n', ...
      result.status,result.k0,result.C_num,result.epsilon_num,result.U_num,result.Q_num,result.denominator,result.R_num);
  catch error
    failure=struct('identifier',error.identifier,'message',error.message,'stack',error.stack, ...
      'report',getReport(error,'extended','hyperlinks','off'),'k',config.k0,'config',config, ...
      'stage','see first stack frame and preceding stage marker','elapsed_seconds',toc(timer));
    if ~isempty(error.stack), failure.stage=error.stack(1).name; end
    LOCAL_json(fullfile(output_dir,'failure.json'),failure); rethrow(error);
  end
end

function out=LOCAL_serializable(value)
% Remove callbacks only after all numerical evaluations, retaining their names.
  if isa(value,'function_handle'), out=func2str(value);
  elseif isstruct(value)
    out=value; names=fieldnames(value);
    for j=1:numel(value)
      for n=1:numel(names), out(j).(names{n})=LOCAL_serializable(value(j).(names{n})); end
    end
  elseif iscell(value)
    out=cellfun(@LOCAL_serializable,value,'UniformOutput',false);
  else, out=value; end
end

function LOCAL_json(filename,value)
  fid=fopen(filename,'w');
  assert(fid>=0,'i92:Output','Cannot write %s.',filename);
  cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end
