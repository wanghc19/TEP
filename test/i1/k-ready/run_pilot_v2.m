function result = run_pilot_v2()
%RUN_PILOT_V2 Run the bounded I1.4 V2 affine-proxy pilot.
% Purpose:
%   Validate the frozen parent, affine seed identity, real-anchor parity,
%   and one prescribed complex node without modifying the completed V1 run.
% Output:
%   result - Compact evidence saved only under output/pilot-a2/result.mat.
% Main algorithm:
%   Freeze A0,b0,c0,U,V,r with two seed lsqminnorm calls, evaluate the seed
%   and kstar+i*r0, compact the hard-gate ledgers, and preserve output a2.
% Numerical goal:
%   Test the V2 proxy anchor only; no full disk, CR, locator, or root work.

  if exist('OCTAVE_VERSION','builtin') ~= 0 || isempty(which('lsqminnorm'))
    error('kreadyv2:MATLABRequired','MATLAB with lsqminnorm is required.');
  end
  here = fileparts(mfilename('fullpath'));
  repo = fileparts(fileparts(fileparts(here)));
  addpath(repo); addpath(here); addpath(fullfile(repo,'test','i1','k-scan'));
  c = cfg_v2();
  if numel(c.nodes) ~= 2 || numel(c.nodes) > c.pilot_node_limit
    error('kreadyv2:NodeLimit','V2 requires exactly the two frozen nodes.');
  end
  output = fullfile(here,'output','pilot-a2');
  if exist(output,'dir') || exist(output,'file')
    error('kreadyv2:OutputExists','output/pilot-a2 already exists.');
  end
  parent_path = fullfile(repo,'test','i1','k-scan','output','zoom2','result.mat');
  loaded = load(parent_path,'result'); parent = loaded.result;
  LOCAL_parent_gate(parent,c);
  mkdir(output);
  diary(fullfile(output,'run.log'));
  cleanup = onCleanup(@() diary('off'));
  timer = tic;

  % --- stage 1: freeze the affine chart and verify its anchoring identity ---
  rows = struct('plus',parent.frame_rows_plus,'minus',parent.frame_rows_minus);
  [seed,frame] = eval_k_v2('seed',c,rows);
  parity = LOCAL_parity(seed,parent,c);
  anchor_identity = max([seed.coarse.proxy_seed_identity, ...
    seed.fine.proxy_seed_identity]);
  seed_pass = seed.pass && parity.pass && ...
    anchor_identity <= c.proxy_seed_identity_tol;
  seed_seconds = toc(timer);

  % --- stage 2: evaluate the sole prescribed off-seed node ---
  if seed_pass
    point_timer = tic;
    complex_node = eval_k_v2('point',c.nodes(2),c,frame);
    point_seconds = toc(point_timer);
  else
    complex_node = struct([]); point_seconds = NaN;
  end
  elapsed = toc(timer);
  nodes = [LOCAL_node_rows(seed,1);LOCAL_node_rows(complex_node,2)];
  factors = [LOCAL_factor_rows(seed,1);LOCAL_factor_rows(complex_node,2)];
  branches = [LOCAL_branch_rows(seed,1);LOCAL_branch_rows(complex_node,2)];
  qz_rows = [LOCAL_qz_rows(seed,1);LOCAL_qz_rows(complex_node,2)];
  charts = LOCAL_chart_rows(frame,c);
  retained_mib = max(LOCAL_bytes(seed,frame), ...
    LOCAL_bytes(complex_node,frame))/2^20;
  engineering_pass = elapsed <= c.pilot_seconds_max && ...
    retained_mib <= c.pilot_memory_mib;
  scientific_pass = seed_pass && ~isempty(complex_node) && ...
    complex_node.pass && all([factors.pass]) && ...
    all([branches.pass]) && all([qz_rows.pass]);
  pass = scientific_pass && engineering_pass;
  if pass
    status = 'I1_4_PILOT_V2_PASS';
  else
    status = 'I1_4_PILOT_V2_FAIL';
  end
  provenance = LOCAL_provenance(here,repo,parent_path);
  estimate = LOCAL_estimate(c,seed_seconds,point_seconds,retained_mib);
  result = struct('schema',c.schema,'experiment_id',c.experiment_id, ...
    'status',status,'pass',pass,'scientific_pass',scientific_pass, ...
    'engineering_pass',engineering_pass,'elapsed_seconds',elapsed, ...
    'node_count',1+double(~isempty(complex_node)),'nodes',nodes, ...
    'factors',factors,'branches',branches,'qz',qz_rows,'parity',parity, ...
    'anchor_identity',anchor_identity,'proxy_charts',charts, ...
    'max_active_state_mib',retained_mib,'full_estimate',estimate, ...
    'parent_token',c.parent_token,'provenance',provenance, ...
    'claim_boundary',c.claim_boundary,'full_authorized',false, ...
    'locator_authorized',false,'contour_authorized',false, ...
    'root_authorized',false,'derivative_authorized',false, ...
    'estimator_authorized',false,'qualified_half_guide_graph',false);
  save(fullfile(output,'result.mat'),'result','-v7.3');
  LOCAL_write_csv(fullfile(output,'nodes.csv'),nodes);
  LOCAL_write_csv(fullfile(output,'factors.csv'),factors);
  LOCAL_write_csv(fullfile(output,'branches.csv'),branches);
  LOCAL_write_csv(fullfile(output,'qz.csv'),qz_rows);
  LOCAL_write_csv(fullfile(output,'proxy-charts.csv'),charts);
  LOCAL_write_csv(fullfile(output,'source-manifest.csv'),provenance.sources);
  LOCAL_write_report(fullfile(output,'report.md'),result,c);
  fprintf('I1_K_READY_PILOT_V2 STATUS=%s pass=%d seconds=%.6g memory_mib=%.6g\n', ...
    status,pass,elapsed,retained_mib);
end

%% ==================== Parent and parity ====================
% These helpers bind V2 to the frozen I1.3 oracle without changing V1.

function LOCAL_parent_gate(parent,c)
  required = {'lineage','candidate','frame_rows_plus','frame_rows_minus'};
  if ~all(isfield(parent,required)) || ...
      ~strcmp(parent.lineage.token,c.parent_token) || ~parent.pass
    error('kreadyv2:Parent','Frozen zoom2 parent lineage is unavailable.');
  end
  if parent.candidate.k ~= c.kstar || ...
      numel(parent.frame_rows_plus) ~= c.K || ...
      numel(parent.frame_rows_minus) ~= c.K
    error('kreadyv2:ParentContract','Frozen parent candidate or rows drifted.');
  end
end

function p = LOCAL_parity(seed,parent,c)
  names = c.level_names;
  p = struct('identity','AFFINE_ANCHORING_IDENTITY', ...
    'block_abs',0,'block_action',0,'pencil_action',0,'adef_action',0, ...
    'score_abs',0,'left_overlap',1,'right_overlap',1,'pass',false);
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
    [score,left,right] = LOCAL_physical(current.AdefD,current.beta_m, ...
      current.gamma,old.seed_scale);
    p.score_abs = max(p.score_abs,abs(score-old.s1));
    p.left_overlap = min(p.left_overlap, ...
      abs(left'*old.normalized_min_left_singular_vector));
    p.right_overlap = min(p.right_overlap, ...
      abs(right'*old.normalized_min_right_singular_vector));
  end
  p.pass = p.block_abs <= c.block_abs_tol && ...
    p.block_action <= c.action_tol && p.pencil_action <= c.action_tol && ...
    p.adef_action <= c.action_tol && p.score_abs <= c.score_abs_tol && ...
    p.left_overlap >= c.vector_overlap_min && ...
    p.right_overlap >= c.vector_overlap_min;
end

function [score,left,right] = LOCAL_physical(A,beta_m,gamma,scale)
  b = sqrt(1+abs(beta_m(:)).^2);
  row = repmat(sqrt(1./b),2,1);
  amp = b+abs(gamma(:)).^2./b;
  column = repmat(1./sqrt(amp),2,1);
  [U,S,V] = svd((row.*A.*column.')/scale,'econ');
  values = diag(S); score = values(end)/values(1);
  left = U(:,end); right = V(:,end);
end

%% ==================== Compact evidence ====================
% These helpers retain only scalar ledgers after each dense node.

function rows = LOCAL_node_rows(node,index)
  rows = struct('node_index',{},'level',{},'k_real',{},'k_imag',{}, ...
    'pass',{},'reason',{},'seconds',{},'proxy_seed_identity',{}, ...
    'proxy_full_residual',{},'proxy_shifted_residual',{},'schur',{}, ...
    'center_participation',{},'graph_participation',{},'lift_residual',{});
  if isempty(node), return; end
  names = {'coarse','fine'};
  for j = 1:2
    x = node.(names{j});
    rows(end+1) = struct('node_index',index,'level',names{j}, ...
      'k_real',real(node.k),'k_imag',imag(node.k),'pass',x.pass, ...
      'reason',x.reason,'seconds',x.elapsed_seconds, ...
      'proxy_seed_identity',x.proxy_seed_identity, ...
      'proxy_full_residual',x.proxy_full_residual, ...
      'proxy_shifted_residual',x.proxy_off_residual,'schur',x.schur, ...
      'center_participation',x.participation.center, ...
      'graph_participation',x.participation.graph, ...
      'lift_residual',x.participation.residual); %#ok<AGROW>
  end
end

function rows = LOCAL_factor_rows(node,index)
  rows = struct('node_index',{},'level',{},'name',{},'rcond',{}, ...
    'residual',{},'available',{},'rcond_min',{},'residual_max',{},'pass',{});
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
  rows = struct('node_index',{},'level',{},'consumer',{},'algebra',{}, ...
    'roundtrip',{},'fingerprint',{},'pass',{});
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
  rows = struct('node_index',{},'level',{},'side',{},'plane',{}, ...
    'raw_residual',{},'residual',{},'stable_diagnostic',{}, ...
    'unstable_diagnostic',{},'neutral_count',{},'indeterminate_count',{}, ...
    'score_gap',{},'classification_gap',{},'chordal_separation',{}, ...
    'cluster_tau',{},'overlap',{},'pass',{});
  if isempty(node), return; end
  names = {'coarse','fine'}; sides = {'plus','minus'};
  for j = 1:2
    for s = 1:2
      q = node.(names{j}).(sides{s});
      rows(end+1) = struct('node_index',index,'level',names{j}, ...
        'side',sides{s},'plane',q.plane,'raw_residual',q.raw_residual, ...
        'residual',q.residual,'stable_diagnostic',q.stable_diagnostic, ...
        'unstable_diagnostic',q.unstable_diagnostic, ...
        'neutral_count',q.neutral_count, ...
        'indeterminate_count',q.indeterminate_count,'score_gap',q.score_gap, ...
        'classification_gap',q.classification_gap, ...
        'chordal_separation',q.chordal_separation, ...
        'cluster_tau',q.cluster_tau,'overlap',LOCAL_field(q,'overlap',1), ...
        'pass',q.pass); %#ok<AGROW>
    end
  end
end

function rows = LOCAL_chart_rows(frame,c)
  rows = struct('level',{},'rows',{},'columns',{},'rank',{},'gap',{}, ...
    'projector_repeat',{},'frozen_complement_norm',{}, ...
    'frozen_complement_relative',{},'seed_residual_complement_norm',{}, ...
    'rank_pass',{},'hash',{});
  for j = 1:2
    x = frame.proxy_chart{j};
    rows(end+1) = struct('level',c.levels(j).name,'rows',size(x.A0,1), ...
      'columns',size(x.A0,2),'rank',x.r,'gap',x.gap, ...
      'projector_repeat',x.projector_repeat, ...
      'frozen_complement_norm',x.frozen_complement_norm, ...
      'frozen_complement_relative',x.frozen_complement_relative, ...
      'seed_residual_complement_norm',x.seed_residual_complement_norm, ...
      'rank_pass',x.rank_pass,'hash',x.hash); %#ok<AGROW>
  end
end

%% ==================== Artifacts and provenance ====================
% These helpers write compact, source-closed, append-only V2 evidence.

function p = LOCAL_provenance(here,repo,parent_path)
  names = {'plan-v2.md','cfg_v2.m','eval_k_v2.m','kproxy_v2.m', ...
    'run_pilot_v2.m','kproxy.m','kchan.m','kgreen.m','kbie.m'};
  sources = struct('name',{},'path',{},'sha256',{});
  for j = 1:numel(names)
    path = fullfile(here,names{j});
    sources(end+1) = struct('name',names{j},'path',path, ...
      'sha256',LOCAL_hash(path)); %#ok<AGROW>
  end
  dependencies = {'+bloch/incident_rhs.m','+bloch/farfield_extractors.m', ...
    '+geom/construct_cont.m','+kernel/h2d_directch.m', ...
    '+kernel/kress_l_splits.m','+kernel/kress_mn_splits.m', ...
    '+quad/quad_kress_rvec.m','+utils/triginterp.m', ...
    'test/i1/k-scan/zoom_core.m','test/i1/k-scan/zoom2_cfg.m', ...
    'test/i1/k-scan/scan_cfg.m'};
  for j = 1:numel(dependencies)
    path = fullfile(repo,dependencies{j});
    sources(end+1) = struct('name',dependencies{j},'path',path, ...
      'sha256',LOCAL_hash(path)); %#ok<AGROW>
  end
  sources(end+1) = struct('name','zoom2_parent','path',parent_path, ...
    'sha256',LOCAL_hash(parent_path));
  [status,sha] = system(sprintf('git -C "%s" rev-parse HEAD',repo));
  if status ~= 0, error('kreadyv2:Git','Cannot record Git SHA.'); end
  p = struct('runtime','MATLAB','version',version,'git_sha',strtrim(sha), ...
    'seed_lsqminnorm',2,'offseed_lsqminnorm',0,'offseed_proxy_svd',0, ...
    'pinv_calls',0,'fallbacks',0,'rank_changes',0,'chart_switches',0, ...
    'offseed_modulus_selection',0,'locator_calls',0,'contour_calls',0, ...
    'root_calls',0,'sources',sources);
end

function estimate = LOCAL_estimate(c,seed_seconds,point_seconds,memory_mib)
  if ~isfinite(point_seconds), point_seconds = seed_seconds; end
  evaluations = c.full_attempt_limit*(c.full_sample_nodes_per_attempt+ ...
    c.full_cr_evaluations_per_attempt)+c.full_negative_evaluation_allowance;
  estimate = struct('seed_seconds',seed_seconds, ...
    'complex_node_seconds',point_seconds,'worst_case_evaluations',evaluations, ...
    'estimated_full_seconds',seed_seconds+evaluations*point_seconds, ...
    'budget_seconds',c.full_seconds_budget,'estimated_peak_mib',memory_mib);
  estimate.within_budget = estimate.estimated_full_seconds <= c.full_seconds_budget;
end

function bytes = LOCAL_bytes(varargin)
  bytes = 0;
  for j = 1:nargin
    if isempty(varargin{j}), continue; end
    probe = varargin{j}; %#ok<NASGU>
    info = whos('probe'); bytes = bytes+info.bytes;
  end
end

function value = LOCAL_hash(path)
  fid = fopen(path,'r');
  if fid < 0, error('kreadyv2:Hash','Cannot read %s.',path); end
  cleanup = onCleanup(@() fclose(fid)); bytes = fread(fid,Inf,'*uint8');
  digest = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
  digest.update(typecast(bytes(:),'int8')); raw = typecast(digest.digest(),'uint8');
  value = lower(reshape(dec2hex(raw,2).',1,[])); clear cleanup;
end

function LOCAL_write_csv(path,rows)
  fid = fopen(path,'w');
  if fid < 0, error('kreadyv2:Artifact','Cannot write %s.',path); end
  cleanup = onCleanup(@() fclose(fid)); fields = fieldnames(rows);
  fprintf(fid,'%s\n',strjoin(fields.',','));
  for i = 1:numel(rows)
    values = cell(1,numel(fields));
    for j = 1:numel(fields)
      values{j} = LOCAL_csv_value(rows(i).(fields{j}));
    end
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

function LOCAL_write_report(path,r,c)
  fid = fopen(path,'w'); cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'# I1-K-READY-PILOT-V2 report\n\n');
  fprintf(fid,'- Status: `%s`\n- Pass: `%d`\n',r.status,r.pass);
  fprintf(fid,'- Affine anchoring identity: `%.17g` / `%.17g`\n', ...
    r.anchor_identity,c.proxy_seed_identity_tol);
  fprintf(fid,'- Independent block/action/pencil/Adef parity: ');
  fprintf(fid,'`%.17g / %.17g / %.17g / %.17g`\n',r.parity.block_abs, ...
    r.parity.block_action,r.parity.pencil_action,r.parity.adef_action);
  fprintf(fid,'- Anchor score parity: `%.17g` / `%.17g`\n', ...
    r.parity.score_abs,c.score_abs_tol);
  fprintf(fid,'- Seed/off-seed lsqminnorm: `2/0`; off-seed SVD: `0`\n');
  fprintf(fid,'- Nodes: `%d`; seconds: `%.17g`; retained MiB: `%.17g`\n', ...
    r.node_count,r.elapsed_seconds,r.max_active_state_mib);
  fprintf(fid,'\nNo full disk, CR stencil, negative suite, locator, or root ran.\n');
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
