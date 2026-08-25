function result = run_pilot()
%RUN_PILOT Run the bounded two-node I1.4 analytic-readiness pilot.
% Purpose:
%   Validate lineage, frozen parent rows, real-anchor parity, one complex
%   cluster-continuation node, factor/branch ledgers, and streamed full cost.
% Output:
%   result - Compact pilot result saved under output/pilot/result.mat.
% Main algorithm:
%   Build the seed-frozen analytic evaluator at kstar, evaluate kstar+i*r0,
%   retain only compact rows after each node, and fail closed on every hard
%   representation gate. No full disk, CR stencil, negative suite, locator,
%   contour, root, derivative, or estimator is run.

  if exist('OCTAVE_VERSION','builtin') ~= 0
    error('kready:MATLABRequired','The readiness pilot requires MATLAB.');
  end
  here = fileparts(mfilename('fullpath'));
  repo = fileparts(fileparts(fileparts(here)));
  addpath(repo); addpath(here); addpath(fullfile(repo,'test','i1','k-scan'));
  c = cfg();
  if numel(c.nodes) > c.pilot_node_limit
    error('kready:NodeLimit','Pilot node count exceeds the frozen limit.');
  end
  parent_path = fullfile(repo,'test','i1','k-scan','output','zoom2','result.mat');
  loaded = load(parent_path,'result'); parent = loaded.result;
  LOCAL_parent_gate(parent,c);
  rows = struct('plus',parent.frame_rows_plus,'minus',parent.frame_rows_minus);
  output = LOCAL_attempt_dir(fullfile(here,'output'));
  mkdir(output);
  diary_path = fullfile(output,'run.log');
  diary(diary_path); cleanup = onCleanup(@() diary('off')); %#ok<NASGU>
  all_timer = tic;

  % --- stage 1: freeze the positive representation and test the anchor ---
  [seed,frame] = eval_k('seed',c,rows);
  seed_seconds = toc(all_timer);
  parity = LOCAL_parity(seed,parent,c);
  seed_pass = seed.pass && parity.pass;
  retained_seed_mib = LOCAL_bytes(seed,frame)/2^20;
  if ~seed_pass
    complex = struct([]); complex_seconds = NaN;
  else
    % --- stage 2: evaluate one prescribed complex cardinal node ---
    point_timer = tic;
    complex = eval_k('point',c.nodes(2),c,frame);
    complex_seconds = toc(point_timer);
  end

  elapsed = toc(all_timer);
  compact = [LOCAL_node_rows(seed,1);LOCAL_node_rows(complex,2)];
  factors = [LOCAL_factor_rows(seed,1);LOCAL_factor_rows(complex,2)];
  branches = [LOCAL_branch_rows(seed,1);LOCAL_branch_rows(complex,2)];
  qz_rows = [LOCAL_qz_rows(seed,1);LOCAL_qz_rows(complex,2)];
  max_memory_mib = max(retained_seed_mib,LOCAL_bytes(complex,frame)/2^20);
  engineering_pass = elapsed <= c.pilot_seconds_max && ...
    max_memory_mib <= c.pilot_memory_mib && numel(c.nodes) <= c.pilot_node_limit;
  scientific_pass = seed_pass && ~isempty(complex) && complex.pass && ...
    all([factors.pass]) && all([branches.pass]) && all([qz_rows.pass]);
  pass = scientific_pass && engineering_pass;
  if pass, status = 'I1_4_PILOT_PASS'; else, status = 'I1_4_PILOT_FAIL'; end

  estimate = LOCAL_estimate(c,seed_seconds,complex_seconds,max_memory_mib);
  provenance = LOCAL_provenance(here,repo,parent_path);
  result = struct('schema',c.schema,'experiment_id',c.experiment_id, ...
    'status',status,'pass',pass,'scientific_pass',scientific_pass, ...
    'engineering_pass',engineering_pass,'elapsed_seconds',elapsed, ...
    'node_count',1+double(~isempty(complex)),'nodes',compact, ...
    'factors',factors,'branches',branches,'qz',qz_rows,'parity',parity, ...
    'proxy_charts',LOCAL_chart_rows(frame,c), ...
    'max_active_state_mib',max_memory_mib,'full_estimate',estimate, ...
    'parent_token',c.parent_token,'provenance',provenance, ...
    'claim_boundary',c.claim_boundary,'full_authorized',false, ...
    'locator_authorized',false,'contour_authorized',false, ...
    'root_authorized',false,'derivative_authorized',false, ...
    'estimator_authorized',false, ...
    'production_separation','NOT_EVALUATED_CAVEAT', ...
    'qualified_half_guide_graph',false);
  save(fullfile(output,'result.mat'),'result','-v7.3');
  LOCAL_write_csv(fullfile(output,'nodes.csv'),compact);
  LOCAL_write_csv(fullfile(output,'factors.csv'),factors);
  LOCAL_write_csv(fullfile(output,'branches.csv'),branches);
  LOCAL_write_csv(fullfile(output,'qz.csv'),qz_rows);
  LOCAL_write_csv(fullfile(output,'proxy-charts.csv'),result.proxy_charts);
  LOCAL_write_manifest(fullfile(output,'source-manifest.csv'),provenance.sources);
  LOCAL_write_estimate(fullfile(output,'estimate.txt'),estimate);
  LOCAL_write_report(fullfile(output,'report.md'),result,c);
  fprintf('I1_K_READY_PILOT STATUS=%s pass=%d seconds=%.6g memory_mib=%.6g\n', ...
    status,pass,elapsed,max_memory_mib);
end

%% ==================== Parent and parity gates ====================
% These helpers bind the pilot to the frozen I1.3 artifact.

function LOCAL_parent_gate(parent,c)
  required = {'lineage','candidate','frame_rows_plus','frame_rows_minus'};
  if ~all(isfield(parent,required)) || ...
      ~strcmp(parent.lineage.token,c.parent_token) || ~parent.pass
    error('kready:Parent','Frozen zoom2 parent lineage is unavailable.');
  end
  if parent.candidate.k ~= c.kstar || numel(parent.frame_rows_plus) ~= c.K || ...
      numel(parent.frame_rows_minus) ~= c.K || ...
      numel(unique(parent.frame_rows_plus)) ~= c.K || ...
      numel(unique(parent.frame_rows_minus)) ~= c.K
    error('kready:ParentContract','Frozen parent candidate or rows drifted.');
  end
end

function p = LOCAL_parity(seed,parent,c)
  names = c.level_names; p = struct(); p.pass = true;
  p.block_abs = 0; p.block_action = 0; p.pencil_action = 0;
  p.adef_action = 0; p.score_abs = 0; p.left_overlap = 1; p.right_overlap = 1;
  oldcfg = zoom2_cfg();
  oldframe = struct('rows_plus',parent.frame_rows_plus, ...
    'rows_minus',parent.frame_rows_minus, ...
    'coarse_scale',parent.coarse_seed_scale, ...
    'fine_scale',parent.fine_seed_scale);
  oldnode = zoom_core('point',c.kstar,oldcfg,oldframe);
  for j = 1:2
    current = seed.(names{j}); old = parent.candidate.(names{j});
    oldlevel = oldnode.(names{j});
    block_names = {'R_L','T_RL','T_LR','R_R'};
    for b = 1:4
      A = current.blocks.(block_names{b}); B = oldlevel.blocks.(block_names{b});
      p.block_abs = max(p.block_abs,max(abs(A-B),[],'all'));
      p.block_action = max(p.block_action,LOCAL_weighted_block(A,B, ...
        current.beta_m));
    end
    p.pencil_action = max(p.pencil_action,LOCAL_weighted_pair( ...
      current.pair,oldlevel.pair,current.beta_m));
    current_phys = old.physical_row_weight.*current.AdefD.* ...
      old.physical_column_weight.';
    old_phys = old.physical_row_weight.*old.Adef_D_unbalanced.* ...
      old.physical_column_weight.';
    p.adef_action = max(p.adef_action,LOCAL_rel(current_phys,old_phys));
    [Aphys,score,left,right] = LOCAL_physical(current.AdefD, ...
      current.beta_m,current.gamma,old.seed_scale); %#ok<ASGLU>
    p.score_abs = max(p.score_abs,abs(score-old.s1));
    p.left_overlap = min(p.left_overlap,abs(left'*old.normalized_min_left_singular_vector));
    p.right_overlap = min(p.right_overlap,abs(right'*old.normalized_min_right_singular_vector));
  end
  p.pass = p.block_abs <= c.block_abs_tol && ...
    p.block_action <= c.action_tol && p.pencil_action <= c.action_tol && ...
    p.adef_action <= c.action_tol && p.score_abs <= c.score_abs_tol && ...
    p.left_overlap >= c.vector_overlap_min && ...
    p.right_overlap >= c.vector_overlap_min;
end

function [Aphys,score,left,right] = LOCAL_physical(A,beta_m,gamma,scale)
  b = sqrt(1+abs(beta_m(:)).^2);
  row = repmat(sqrt(1./b),2,1);
  amp = b+abs(gamma(:)).^2./b;
  column = repmat(1./sqrt(amp),2,1);
  Aphys = row.*A.*column.';
  [U,S,V] = svd(Aphys/scale,'econ'); values = diag(S);
  score = values(end)/values(1); left = U(:,end); right = V(:,end);
end

%% ==================== Compact ledgers ====================
% These helpers stream dense nodes into small audit rows.

function rows = LOCAL_node_rows(node,index)
  rows = LOCAL_empty_nodes();
  if isempty(node), return; end
  names = {'coarse','fine'};
  for j = 1:2
    x = node.(names{j});
    rows(end+1) = struct('node_index',index,'level',names{j}, ...
      'k_real',real(node.k),'k_imag',imag(node.k),'pass',x.pass, ...
      'reason',x.reason,'seconds',x.elapsed_seconds,'schur',x.schur, ...
      'center_participation',x.participation.center, ...
      'graph_participation',x.participation.graph, ...
      'lift_residual',x.participation.residual); %#ok<AGROW>
  end
end

function rows = LOCAL_factor_rows(node,index)
  rows = LOCAL_empty_factors();
  if isempty(node), return; end
  names = {'coarse','fine'};
  for j = 1:2
    current = node.(names{j}).factors;
    for f = 1:numel(current)
      rows(end+1) = struct('node_index',index,'level',names{j}, ...
        'name',current(f).name,'rcond',current(f).rcond, ...
        'residual',current(f).residual,'available',current(f).available, ...
        'rcond_min',current(f).rcond_min, ...
        'residual_max',current(f).residual_max,'pass',current(f).pass); %#ok<AGROW>
    end
  end
end

function rows = LOCAL_branch_rows(node,index)
  rows = LOCAL_empty_branches();
  if isempty(node), return; end
  names = {'coarse','fine'}; consumers = {'port','proxy'};
  for j = 1:2
    for b = 1:2
      a = node.(names{j}).(['branch_',consumers{b}]);
      rows(end+1) = struct('node_index',index,'level',names{j}, ...
        'consumer',consumers{b},'algebra',a.algebra, ...
        'roundtrip',a.roundtrip,'fingerprint',a.fingerprint,'pass',a.pass); %#ok<AGROW>
    end
  end
end

function rows = LOCAL_qz_rows(node,index)
  rows = LOCAL_empty_qz();
  if isempty(node), return; end
  names = {'coarse','fine'}; sides = {'plus','minus'};
  for j = 1:2
    for s = 1:2
      q = node.(names{j}).(sides{s});
      if isfield(q,'overlap'), overlap = q.overlap; else, overlap = 1; end
      if isfield(q,'cluster_tau'), tau = q.cluster_tau; else, tau = 0; end
      rows(end+1) = struct('node_index',index,'level',names{j}, ...
        'side',sides{s},'plane',q.plane,'raw_residual',q.raw_residual, ...
        'residual',q.residual,'stable_diagnostic',q.stable_diagnostic, ...
        'unstable_diagnostic',q.unstable_diagnostic, ...
        'neutral_count',q.neutral_count,'infinite_count',q.infinite_count, ...
        'indeterminate_count',q.indeterminate_count,'score_gap',q.score_gap, ...
        'classification_gap',LOCAL_field(q,'classification_gap',Inf), ...
        'chordal_separation',q.chordal_separation,'cluster_tau',tau, ...
        'overlap',overlap,'pass',q.pass); %#ok<AGROW>
    end
  end
end

function rows = LOCAL_chart_rows(frame,c)
  rows = struct('level',{},'rows',{},'columns',{},'rank',{}, ...
    'gap',{},'projector_repeat',{},'rank_pass',{},'fingerprint',{});
  for j = 1:2
    x = frame.proxy_chart{j}; spec = c.levels(j);
    rows(end+1) = struct('level',spec.name,'rows',size(x.U,1), ...
      'columns',size(x.V,1),'rank',x.rank,'gap',x.gap, ...
      'projector_repeat',x.projector_repeat,'rank_pass',x.rank_pass, ...
      'fingerprint',x.fingerprint); %#ok<AGROW>
  end
end

function out = LOCAL_empty_nodes()
  out = struct('node_index',{},'level',{},'k_real',{},'k_imag',{}, ...
    'pass',{},'reason',{},'seconds',{},'schur',{}, ...
    'center_participation',{},'graph_participation',{},'lift_residual',{});
end

function out = LOCAL_empty_factors()
  out = struct('node_index',{},'level',{},'name',{},'rcond',{}, ...
    'residual',{},'available',{},'rcond_min',{},'residual_max',{},'pass',{});
end

function out = LOCAL_empty_branches()
  out = struct('node_index',{},'level',{},'consumer',{},'algebra',{}, ...
    'roundtrip',{},'fingerprint',{},'pass',{});
end

function out = LOCAL_empty_qz()
  out = struct('node_index',{},'level',{},'side',{},'plane',{}, ...
    'raw_residual',{},'residual',{},'stable_diagnostic',{}, ...
    'unstable_diagnostic',{},'neutral_count',{},'infinite_count',{}, ...
    'indeterminate_count',{},'score_gap',{},'classification_gap',{}, ...
    'chordal_separation',{}, ...
    'cluster_tau',{},'overlap',{},'pass',{});
end

%% ==================== Engineering and artifacts ====================
% These helpers estimate full work and write compact reproducible evidence.

function estimate = LOCAL_estimate(c,seed_seconds,point_seconds,memory_mib)
  if ~isfinite(point_seconds), point_seconds = seed_seconds; end
  eval_seconds = max(point_seconds,eps);
  per_attempt = c.full_sample_nodes_per_attempt+c.full_cr_evaluations_per_attempt;
  worst_evals = c.full_attempt_limit*per_attempt+c.full_negative_evaluation_allowance;
  estimate = struct('seed_seconds',seed_seconds, ...
    'complex_node_seconds',point_seconds,'estimated_evaluation_seconds',eval_seconds, ...
    'evaluations_per_attempt',per_attempt,'worst_case_evaluations',worst_evals, ...
    'estimated_full_seconds',seed_seconds+worst_evals*eval_seconds, ...
    'budget_seconds',c.full_seconds_budget,'estimated_peak_mib',memory_mib, ...
    'streaming_policy','ONE_DENSE_NODE_PLUS_FROZEN_FRAME');
  estimate.within_budget = estimate.estimated_full_seconds <= c.full_seconds_budget;
end

function bytes = LOCAL_bytes(varargin)
  bytes = 0;
  for j = 1:nargin
    if isempty(varargin{j}), continue; end
    probe = varargin{j}; info = whos('probe'); bytes = bytes+info.bytes;
  end
end

function p = LOCAL_provenance(here,repo,parent_path)
  names = {'README.md','plan.md','estimate.txt','cfg.m','eval_k.m','run_pilot.m', ...
    'kchan.m','kproxy.m','kgreen.m','kbie.m'};
  sources = struct('name',{},'path',{},'sha256',{});
  for j = 1:numel(names)
    path = fullfile(here,names{j});
    sources(end+1) = struct('name',names{j},'path',path, ...
      'sha256',LOCAL_hash(path)); %#ok<AGROW>
  end
  packages = {'+bloch/incident_rhs.m','+bloch/farfield_extractors.m', ...
    '+geom/construct_cont.m','+kernel/h2d_directch.m', ...
    '+kernel/kress_l_splits.m','+kernel/kress_mn_splits.m', ...
    '+quad/quad_kress_rvec.m','+utils/triginterp.m', ...
    'test/i1/k-scan/zoom_core.m','test/i1/k-scan/zoom2_cfg.m', ...
    'test/i1/k-scan/scan_cfg.m'};
  for j = 1:numel(packages)
    path = fullfile(repo,packages{j});
    sources(end+1) = struct('name',packages{j},'path',path, ...
      'sha256',LOCAL_hash(path)); %#ok<AGROW>
  end
  sources(end+1) = struct('name','zoom2_parent','path',parent_path, ...
    'sha256',LOCAL_hash(parent_path));
  [status,sha] = system(sprintf('git -C "%s" rev-parse HEAD',repo));
  if status ~= 0, error('kready:Git','Cannot record Git SHA.'); end
  p = struct('runtime','MATLAB','version',version,'git_sha',strtrim(sha), ...
    'fallbacks',0,'offseed_proxy_svd',0,'offseed_lsqminnorm',0, ...
    'offseed_modulus_selection',0,'chart_switches',0,'repivots',0, ...
    'locator_calls',0,'contour_calls',0,'root_calls',0,'sources',sources);
end

function value = LOCAL_hash(path)
  fid = fopen(path,'r');
  if fid < 0, error('kready:Hash','Cannot read %s.',path); end
  cleanup = onCleanup(@() fclose(fid)); bytes = fread(fid,Inf,'*uint8');
  digest = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
  digest.update(typecast(bytes(:),'int8')); raw = typecast(digest.digest(),'uint8');
  value = lower(reshape(dec2hex(raw,2).',1,[])); clear cleanup;
end

function LOCAL_write_csv(path,rows)
  fid = fopen(path,'w');
  if fid < 0, error('kready:Artifact','Cannot write %s.',path); end
  cleanup = onCleanup(@() fclose(fid)); fields = fieldnames(rows);
  fprintf(fid,'%s\n',strjoin(fields.',','));
  for i = 1:numel(rows)
    values = cell(1,numel(fields));
    for j = 1:numel(fields), values{j} = LOCAL_csv_value(rows(i).(fields{j})); end
    fprintf(fid,'%s\n',strjoin(values,','));
  end
  clear cleanup;
end

function value = LOCAL_csv_value(x)
  if ischar(x)
    value = ['"',strrep(x,'"','""'),'"'];
  elseif islogical(x) || (isnumeric(x) && isscalar(x))
    value = sprintf('%.17g',x);
  else
    value = ['"',strrep(mat2str(x),'"','""'),'"'];
  end
end

function LOCAL_write_manifest(path,rows)
  LOCAL_write_csv(path,rows);
end

function LOCAL_write_estimate(path,e)
  fid = fopen(path,'w'); cleanup = onCleanup(@() fclose(fid));
  fields = fieldnames(e);
  for j = 1:numel(fields), fprintf(fid,'%s=%s\n',fields{j}, ...
      LOCAL_csv_value(e.(fields{j}))); end
  clear cleanup;
end

function LOCAL_write_report(path,r,c)
  fid = fopen(path,'w'); cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'# I1-K-READY-PILOT-V1 report\n\n');
  fprintf(fid,'- Status: `%s`\n- Pass: `%d`\n',r.status,r.pass);
  fprintf(fid,'- Claim boundary: `%s`\n',r.claim_boundary);
  fprintf(fid,'- Nodes evaluated: `%d` / `%d`\n',r.node_count,c.pilot_node_limit);
  fprintf(fid,'- Wall time: `%.17g s` / `%.17g s`\n', ...
    r.elapsed_seconds,c.pilot_seconds_max);
  fprintf(fid,'- Peak retained state: `%.17g MiB` / `%.17g MiB`\n', ...
    r.max_active_state_mib,c.pilot_memory_mib);
  fprintf(fid,'- Parity block/action/pencil/Adef: `%.17g / %.17g / %.17g / %.17g`\n', ...
    r.parity.block_abs,r.parity.block_action,r.parity.pencil_action, ...
    r.parity.adef_action);
  fprintf(fid,'- Parity score/left/right: `%.17g / %.17g / %.17g`\n', ...
    r.parity.score_abs,r.parity.left_overlap,r.parity.right_overlap);
  fprintf(fid,'- Full-run streamed estimate: `%.17g s`; within 3 h: `%d`\n', ...
    r.full_estimate.estimated_full_seconds,r.full_estimate.within_budget);
  fprintf(fid,'- Locator/contour/root/derivative/estimator: `0/0/0/0/0`\n');
  fprintf(fid,'\nThe pilot does not execute the full disk, CR stencil, or negatives.\n');
  clear cleanup;
end

function value = LOCAL_rel(A,B)
  value = norm(A-B,'fro')/max(1,norm(B,'fro'));
end

function value = LOCAL_weighted_block(A,B,beta_m)
  W = diag((1+abs(beta_m(:)).^2).^(1/4));
  Aw = (W.'\(W*A).').'; Bw = (W.'\(W*B).').';
  value = norm(Aw-Bw,2)/max(1,norm(Bw,2));
end

function value = LOCAL_weighted_pair(A,B,beta_m)
  W = diag((1+abs(beta_m(:)).^2).^(1/4)); W = blkdiag(W,W);
  Aa = (W.'\(W*A.A).').'; Ab = (W.'\(W*A.B).').';
  Ba = (W.'\(W*B.A).').'; Bb = (W.'\(W*B.B).').';
  value = hypot(norm(Aa-Ba,'fro'),norm(Ab-Bb,'fro'))/ ...
    max(1,hypot(norm(Ba,'fro'),norm(Bb,'fro')));
end

function value = LOCAL_field(s,name,fallback)
  if isfield(s,name), value = s.(name); else, value = fallback; end
end

function path = LOCAL_attempt_dir(root)
  if ~exist(root,'dir'), mkdir(root); end
  for index = 1:99
    path = fullfile(root,sprintf('pilot-a%d',index));
    if ~exist(path,'dir'), return; end
  end
  error('kready:Attempts','No free pilot attempt directory remains.');
end
