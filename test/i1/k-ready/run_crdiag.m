function result = run_crdiag()
%RUN_CRDIAG Run the out-of-protocol I1.4 center CR diagnostic.
% Purpose:
%   Distinguish finite-difference cancellation from unresolved nonanalyticity
%   after the immutable three-attempt V3 failure.
% Output:
%   result - Compact evidence saved under output/cr-diag/.
% Main algorithm:
%   Rebuild the frozen V3 frame, evaluate four shifts at h=r0, and compare
%   full unbalanced AdefD/AdefG central derivatives on both spatial levels.
% Based on:
%   run_full.m and full_core.m.
% Numerical goal:
%   Test the preregistered cancellation prediction without changing verdicts.

  if exist('OCTAVE_VERSION','builtin') ~= 0 || isempty(which('lsqminnorm'))
    error('crdiag:MATLABRequired','MATLAB with lsqminnorm is required.');
  end
  here = fileparts(mfilename('fullpath'));
  repo = fileparts(fileparts(fileparts(here)));
  addpath(repo); addpath(here); addpath(fullfile(repo,'test','i1','k-scan'));
  output = fullfile(here,'output','cr-diag');
  if exist(output,'dir') || exist(output,'file')
    error('crdiag:OutputExists','output/cr-diag already exists.');
  end
  mkdir(output); diary(fullfile(output,'run.log'));
  cleanup = onCleanup(@() diary('off')); timer = tic;
  c = full_cfg();
  parent_path = fullfile(repo,'test','i1','k-scan','output','zoom2','result.mat');
  loaded = load(parent_path,'result'); parent = loaded.result;
  if ~parent.pass || ~strcmp(parent.lineage.token,c.parent_token)
    error('crdiag:Parent','Frozen I1.3 parent failed lineage checks.');
  end
  rows = struct('plus',parent.frame_rows_plus,'minus',parent.frame_rows_minus);
  [~,frame] = eval_k_v3('seed',c,rows);
  h = c.r0; points = c.kstar+[h,-h,1i*h,-1i*h];
  levels = {'coarse','fine'}; objects = {'AdefD','AdefG'};
  matrices = cell(4,2,2); shifted_pass = true;
  compare_max = 0;
  for p = 1:4
    node = eval_k_v3('point',points(p),c,frame);
    metric = full_core('compare',node,c);
    shifted_pass = shifted_pass && metric.pass;
    compare_max = max(compare_max,LOCAL_metric_max(metric));
    for l = 1:2
      for o = 1:2
        matrices{p,l,o} = node.(levels{l}).(objects{o});
      end
    end
    clear node;
  end
  rows_out = struct('level',{},'object',{},'h',{},'cr_defect',{}, ...
    'threshold',{},'shifted_pass',{},'compare_max',{},'pass',{});
  for l = 1:2
    for o = 1:2
      Dx = (matrices{1,l,o}-matrices{2,l,o})/(2*h);
      Dy = (matrices{3,l,o}-matrices{4,l,o})/(2i*h);
      defect = norm(Dx-Dy,'fro')/max([1,norm(Dx,'fro'),norm(Dy,'fro')]);
      rows_out(end+1) = struct('level',levels{l},'object',objects{o}, ...
        'h',h,'cr_defect',defect,'threshold',c.cr_tol, ...
        'shifted_pass',shifted_pass,'compare_max',compare_max, ...
        'pass',shifted_pass && defect <= c.cr_tol); %#ok<AGROW>
    end
  end
  pass = all([rows_out.pass]); elapsed = toc(timer);
  if pass
    diagnosis = 'CANCELLATION_DOMINATED';
  else
    diagnosis = 'MIXED_OR_UNRESOLVED';
  end
  result = struct('schema','TEP_I1_CR_DIAG_V1','pass',pass, ...
    'diagnosis',diagnosis,'h',h,'rows',rows_out, ...
    'elapsed_seconds',elapsed,'frozen_v3_verdict','I1_4_FAIL_UNCHANGED', ...
    'locator_calls',0,'contour_calls',0,'root_calls',0, ...
    'estimator_calls',0,'source_hashes',LOCAL_sources(here));
  save(fullfile(output,'result.mat'),'result','-v7.3');
  LOCAL_csv(fullfile(output,'cr.csv'),rows_out);
  LOCAL_csv(fullfile(output,'source-manifest.csv'),result.source_hashes);
  LOCAL_report(fullfile(output,'report.md'),result);
  fprintf('I1_CR_DIAG status=%s pass=%d seconds=%.6g\n', ...
    diagnosis,pass,elapsed);
end

%% ==================== Diagnostic utilities ====================
% These helpers compute compact metrics and append-only evidence.

function value = LOCAL_metric_max(m)
  value = max([m.block_abs,m.block_action,m.pencil_action, ...
    m.subspace_plus,m.subspace_minus,m.cauchy_plus,m.cauchy_minus, ...
    m.dtn_plus,m.dtn_minus,m.adefD_action,m.adefG_action]);
end

function rows = LOCAL_sources(here)
  names = {'cr-diag.md','run_crdiag.m','full_cfg.m','full_core.m', ...
    'cfg_v3.m','eval_k_v3.m','cfg_v2.m','eval_k_v2.m','kproxy_v2.m'};
  rows = struct('name',{},'sha256',{});
  for j = 1:numel(names)
    rows(end+1) = struct('name',names{j}, ...
      'sha256',LOCAL_hash(fullfile(here,names{j}))); %#ok<AGROW>
  end
end

function value = LOCAL_hash(path)
  fid = fopen(path,'r');
  if fid < 0, error('crdiag:Hash','Cannot read %s.',path); end
  cleanup = onCleanup(@() fclose(fid)); bytes = fread(fid,Inf,'*uint8');
  digest = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
  digest.update(typecast(bytes(:),'int8')); raw = typecast(digest.digest(),'uint8');
  value = lower(reshape(dec2hex(raw,2).',1,[])); clear cleanup;
end

function LOCAL_csv(path,rows)
  fid = fopen(path,'w'); cleanup = onCleanup(@() fclose(fid));
  fields = fieldnames(rows); fprintf(fid,'%s\n',strjoin(fields.',','));
  for i = 1:numel(rows)
    values = cell(1,numel(fields));
    for j = 1:numel(fields)
      x = rows(i).(fields{j});
      if ischar(x), values{j} = ['"',strrep(x,'"','""'),'"'];
      else, values{j} = sprintf('%.17g',x); end
    end
    fprintf(fid,'%s\n',strjoin(values,','));
  end
  clear cleanup;
end

function LOCAL_report(path,r)
  fid = fopen(path,'w'); cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'# I1.4 center CR diagnostic\n\n');
  fprintf(fid,'- Diagnosis: `%s`; pass: `%d`.\n',r.diagnosis,r.pass);
  fprintf(fid,'- Step: `%.17g`; seconds: `%.17g`.\n',r.h,r.elapsed_seconds);
  fprintf(fid,'- Frozen V3 verdict: `%s`.\n',r.frozen_v3_verdict);
  fprintf(fid,'- Locator/contour/root/estimator calls: `0/0/0/0`.\n');
  fprintf(fid,'\nThis causal diagnostic cannot alter the frozen I1.4 verdict.\n');
  clear cleanup;
end
