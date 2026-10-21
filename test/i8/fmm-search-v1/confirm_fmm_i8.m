function confirmation = confirm_fmm_i8(k,output_dir)
%CONFIRM_FMM_I8 Recompute one explicit I8.4 FMM candidate in a fresh process.
% Purpose:
%   Confirm the search winner from an explicitly supplied 17-digit literal.
% Input:
%   k          - Positive finite scalar literal supplied by the launcher.
%   output_dir - Directory for confirmation artifacts.
% Output:
%   confirmation - Complete-call timing and the four frozen point metrics.
% Main algorithm:
%   Call fmm_i8_point once with method 'fmm', eps=1e-12, and no field capture.
% Notes:
%   This function does not load search output, historical output, Markdown,
%   Git metadata, or any prior candidate value.

  if nargin ~= 2 || ~isscalar(k) || ~isreal(k) || ~isfinite(k) || k <= 0 || ...
      ~(ischar(output_dir) || (isstring(output_dir) && isscalar(output_dir)))
    error('i8fmmsearch:ConfirmArguments', ...
      'Pass a positive finite scalar k and one output directory path.');
  end
  output_dir = char(output_dir);
  if ~isfolder(output_dir)
    mkdir(output_dir);
  end
  required = {'fmm_i8_point','hfmm2d','fmm2d'};
  for j = 1:numel(required)
    if isempty(which(required{j}))
      error('i8fmmsearch:MissingDependency', ...
        'Required function %s is not on the MATLAB path.',required{j});
    end
  end

  requested_eps = 1e-12;
  outer_timer = tic;
  point = fmm_i8_point(k,'fmm',requested_eps,false);
  outer_seconds = toc(outer_timer);
  confirmation = struct('k',point.k,'requested_eps',requested_eps, ...
    'outer_seconds',outer_seconds,'point_seconds',point.point_seconds, ...
    'adef_sigma',point.metrics.adef_sigma, ...
    'adef_ratio',point.metrics.adef_ratio, ...
    'aphys_sigma',point.metrics.aphys_sigma, ...
    'aphys_ratio',point.metrics.aphys_ratio, ...
    'matlab_version',version,'matlab_release',version('-release'), ...
    'computer',computer,'omp_num_threads',getenv('OMP_NUM_THREADS'));
  save(fullfile(output_dir,'confirmation.mat'),'confirmation','point','-v7.3');
  LOCAL_write_json(fullfile(output_dir,'confirmation.json'),confirmation);
  stream = fopen(fullfile(output_dir,'confirmation.csv'),'w');
  if stream < 0
    error('i8fmmsearch:Output','Could not open confirmation.csv.');
  end
  cleanup = onCleanup(@() fclose(stream));
  fprintf(stream,['k,requested_eps,outer_seconds,point_seconds,adef_sigma,', ...
    'adef_ratio,aphys_sigma,aphys_ratio\n']);
  fprintf(stream,'%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g\n', ...
    confirmation.k,confirmation.requested_eps,confirmation.outer_seconds, ...
    confirmation.point_seconds,confirmation.adef_sigma, ...
    confirmation.adef_ratio,confirmation.aphys_sigma, ...
    confirmation.aphys_ratio);
  clear cleanup;
  fprintf(1,'CONFIRMED_K_LITERAL=%.17g\n',confirmation.k);
  fprintf(1,'CONFIRMED_ADEF_SIGMA=%.17g\n',confirmation.adef_sigma);
  fprintf(1,'CONFIRMED_ADEF_RATIO=%.17g\n',confirmation.adef_ratio);
  fprintf(1,'CONFIRMED_APHYS_SIGMA=%.17g\n',confirmation.aphys_sigma);
  fprintf(1,'CONFIRMED_APHYS_RATIO=%.17g\n',confirmation.aphys_ratio);
end

function LOCAL_write_json(path,value)
  stream = fopen(path,'w');
  if stream < 0
    error('i8fmmsearch:Output','Could not open %s.',path);
  end
  cleanup = onCleanup(@() fclose(stream));
  fwrite(stream,jsonencode(value,'PrettyPrint',true),'char');
  fwrite(stream,newline,'char');
  clear cleanup;
end
