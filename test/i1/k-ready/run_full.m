function result = run_full(attempt)
%RUN_FULL Run one radius of the full I1.4 V3 readiness experiment.
% Purpose:
%   Execute exactly one preregistered disk attempt with streamed sampling,
%   loop closure, full-matrix CR checks, and required negative controls.
% Input:
%   attempt - Integer 1, 2, or 3 selecting r0, r0/2, or r0/4.
% Output:
%   result - Compact result under output/full-a1/attempt-N/result.mat.
% Main algorithm:
%   Freeze one center frame, evaluate a center-rooted star over 8 half-radius
%   and 32 boundary nodes, test four alternate-parent closures, run CR at the
%   center and eight half nodes, then run negatives only after a passing disk.
% Numerical goal:
%   Establish sampled discrete readiness only; no locator or root work occurs.

  if nargin ~= 1 || ~isscalar(attempt) || attempt ~= floor(attempt)
    error('kreadyfull:Attempt','Pass exactly one integer attempt in 1:3.');
  end
  if exist('OCTAVE_VERSION','builtin') ~= 0 || isempty(which('lsqminnorm'))
    error('kreadyfull:MATLABRequired','MATLAB with lsqminnorm is required.');
  end
  here = fileparts(mfilename('fullpath'));
  repo = fileparts(fileparts(fileparts(here)));
  addpath(repo); addpath(here); addpath(fullfile(repo,'test','i1','k-scan'));
  c = full_cfg();
  if ~ismember(attempt,c.attempt_ids) || ~c.run_one_attempt_per_invocation || ...
      c.auto_cascade
    error('kreadyfull:Attempt','Attempt contract is not one radius per run.');
  end
  radius = c.radii(attempt);
  root = fullfile(here,c.output_relative);
  output = fullfile(root,sprintf(c.attempt_output_pattern,attempt));
  if exist(output,'dir') || exist(output,'file')
    error('kreadyfull:OutputExists','Attempt output already exists.');
  end
  if ~exist(root,'dir'), mkdir(root); end
  mkdir(output);
  diary(fullfile(output,'run.log'));
  cleanup = onCleanup(@() diary('off'));
  timer = tic;
  provenance = LOCAL_provenance(here,repo);
  LOCAL_csv(fullfile(output,'source-manifest.csv'),provenance.sources);

  parent_path = fullfile(repo,'test','i1','k-scan','output','zoom2','result.mat');
  pilot_path = fullfile(here,'output','pilot-a3','result.mat');
  loaded = load(parent_path,'result'); parent = loaded.result;
  LOCAL_parent_gate(parent,c);
  pilot = LOCAL_pilot_gate(pilot_path,here,c);
  rows = struct('plus',parent.frame_rows_plus,'minus',parent.frame_rows_minus);
  [seed,frame] = eval_k_v3('seed',c,rows);
  node_rows = full_core('node_rows',seed,1,'center', ...
    full_core('compare',seed,c),0); node_rows(:) = [];
  factor_rows = full_core('factor_rows',seed,1); factor_rows(:) = [];
  branch_rows = full_core('branch_rows',seed,1); branch_rows(:) = [];
  qz_rows = full_core('qz_rows',seed,1); qz_rows(:) = [];
  closure_rows = LOCAL_empty_closure(); cr_rows = LOCAL_empty_cr();
  negatives = LOCAL_empty_negatives();
  failure = '';

  % --- stage 1: center and centre-rooted star sampling ---
  [node_rows,factor_rows,branch_rows,qz_rows,center_pass] = ...
    LOCAL_append(seed,1,'center',0,c,node_rows,factor_rows,branch_rows,qz_rows);
  if ~center_pass, failure = 'CENTER_GATE'; end
  boundary_plus = cell(2,numel(c.cardinal_indices));
  boundary_minus = cell(2,numel(c.cardinal_indices));
  node_index = 1;
  if isempty(failure)
    samples = [0.5*radius*exp(1i*c.half_angles), ...
      radius*exp(1i*c.boundary_angles)];
    kinds = [repmat({'half'},1,8),repmat({'boundary'},1,32)];
    for j = 1:numel(samples)
      LOCAL_time_gate(timer,c);
      node_index = node_index+1;
      node = eval_k_v3('point',c.kstar+samples(j),c,frame);
      boundary_index = max(0,j-8);
      [node_rows,factor_rows,branch_rows,qz_rows,ok] = ...
        LOCAL_append(node,node_index,kinds{j},boundary_index,c,node_rows, ...
        factor_rows,branch_rows,qz_rows);
      if j > 8
        bindex = j-8;
        slot = find(c.cardinal_indices == bindex,1);
        if ~isempty(slot)
          boundary_plus{1,slot} = node.coarse.plus.Z;
          boundary_plus{2,slot} = node.fine.plus.Z;
          boundary_minus{1,slot} = node.coarse.minus.Z;
          boundary_minus{2,slot} = node.fine.minus.Z;
        end
      end
      clear node;
      if ~ok, failure = sprintf('SAMPLED_NODE_%d',node_index); break; end
    end
  end

  % --- stage 2: four fixed alternate-parent loop closures ---
  if isempty(failure)
    levels = {'coarse','fine'};
    for j = 1:4
      direct = c.cardinal_indices(j); parent_index = c.alternate_parent_indices(j);
      parent_slot = find(c.cardinal_indices == parent_index,1);
      alt = frame;
      alt.seed_Z_plus = boundary_plus(:,parent_slot).';
      alt.seed_Z_minus = boundary_minus(:,parent_slot).';
      node = eval_k_v3('point',c.kstar+radius* ...
        exp(1i*c.boundary_angles(direct)),c,alt);
      closure_metric = full_core('compare',node,c);
      for l = 1:2
        [op,~] = full_core('overlap',boundary_plus{l,j},node.(levels{l}).plus.Z);
        [om,~] = full_core('overlap',boundary_minus{l,j},node.(levels{l}).minus.Z);
        ok = closure_metric.pass && node.(levels{l}).pass && ...
          min(op,om) >= c.qz_overlap_min;
        closure_rows(end+1) = struct('cardinal_index',direct, ...
          'alternate_parent_index',parent_index,'level',levels{l}, ...
          'plus_overlap',op,'minus_overlap',om, ...
          'comparison_pass',closure_metric.pass, ...
          'comparison_max',LOCAL_metric_max(closure_metric), ...
          'threshold',c.qz_overlap_min,'pass',ok); %#ok<AGROW>
        if ~ok && isempty(failure), failure = 'LOOP_CLOSURE'; end
      end
      clear node;
      if ~isempty(failure), break; end
    end
  end

  % --- stage 3: CR of full unbalanced D and G matrices ---
  if isempty(failure)
    cr_nodes = [c.kstar,c.kstar+0.5*radius*exp(1i*c.half_angles)];
    h0 = min(radius/c.cr_radius_divisor, ...
      c.cr_relative_cap*max(1,abs(c.kstar)));
    for j = 1:numel(cr_nodes)
      LOCAL_time_gate(timer,c);
      rows_j = full_core('cr',cr_nodes(j),frame,c,h0);
      for n = 1:numel(rows_j)
        rows_j(n).node_index = j;
        rows_j(n).k_real = real(cr_nodes(j));
        rows_j(n).k_imag = imag(cr_nodes(j));
      end
      cr_rows = [cr_rows;rows_j(:)]; %#ok<AGROW>
      if ~all([rows_j.pass]), failure = sprintf('CR_NODE_%d',j); break; end
    end
  end

  % --- stage 4: negatives only after a passing sampled disk ---
  disk_pass = isempty(failure);
  if disk_pass
    good_cr = max([cr_rows.cr_h2]);
    negatives = full_neg(seed,frame,c,good_cr);
    if numel(negatives) ~= numel(c.negative_names) || ...
        ~isequal({negatives.name},c.negative_names) || ~all([negatives.pass])
      failure = 'NEGATIVE_SUITE';
    end
  end
  elapsed = toc(timer);
  engineering_pass = elapsed <= c.hard_seconds_per_run;
  pass = isempty(failure) && engineering_pass;
  if pass, status = 'I1_4_FULL_V3_PASS'; ...
  else, status = 'I1_4_FULL_V3_FAIL'; end
  if ~engineering_pass, failure = 'HARD_TIME'; end
  result = struct('schema',c.schema,'experiment_id',c.experiment_id, ...
    'attempt',attempt,'radius',radius,'status',status,'pass',pass, ...
    'first_failure',failure,'disk_pass_before_negatives',disk_pass, ...
    'elapsed_seconds',elapsed,'target_seconds',c.target_seconds_per_attempt, ...
    'hard_seconds',c.hard_seconds_per_run,'nodes',node_rows, ...
    'estimate',LOCAL_estimate(c), ...
    'factors',factor_rows,'branches',branch_rows,'qz',qz_rows, ...
    'closures',closure_rows,'cr',cr_rows,'negatives',negatives, ...
    'pilot_a3',pilot,'provenance',provenance, ...
    'claim_boundary',c.claim_boundary, ...
    'locator_calls',0,'contour_calls',0,'root_calls',0, ...
    'derivative_qualified',false,'estimator_calls',0, ...
    'run_one_attempt_per_invocation',true);
  save(fullfile(output,'result.mat'),'result','-v7.3');
  LOCAL_csv(fullfile(output,'nodes.csv'),node_rows);
  LOCAL_csv(fullfile(output,'factors.csv'),factor_rows);
  LOCAL_csv(fullfile(output,'branches.csv'),branch_rows);
  LOCAL_csv(fullfile(output,'qz.csv'),qz_rows);
  LOCAL_csv(fullfile(output,'closures.csv'),closure_rows);
  LOCAL_csv(fullfile(output,'cr.csv'),cr_rows);
  LOCAL_csv(fullfile(output,'negatives.csv'),negatives);
  LOCAL_report(fullfile(output,'report.md'),result);
  fprintf('I1_K_READY_FULL_V3 attempt=%d status=%s pass=%d seconds=%.6g\n', ...
    attempt,status,pass,elapsed);
end

%% ==================== Stream orchestration ====================
% These helpers append compact evidence and enforce the one-run hard limit.

function [nr,fr,br,qr,pass] = ...
    LOCAL_append(node,index,kind,boundary_index,c,nr,fr,br,qr)
  metric = full_core('compare',node,c);
  nr = [nr;full_core('node_rows',node,index,kind,metric,boundary_index)];
  fr = [fr;full_core('factor_rows',node,index)];
  br = [br;full_core('branch_rows',node,index)];
  qr = [qr;full_core('qz_rows',node,index)];
  pass = metric.pass && all([node.coarse.factors.pass]) && ...
    all([node.fine.factors.pass]);
end

function LOCAL_time_gate(timer,c)
  if toc(timer) > c.hard_seconds_per_run
    error('kreadyfull:HardTime','The single-attempt 30-minute limit expired.');
  end
end

function value = LOCAL_metric_max(m)
  value = max([m.block_abs,m.block_action,m.pencil_action, ...
    m.subspace_plus,m.subspace_minus,m.cauchy_plus,m.cauchy_minus, ...
    m.dtn_plus,m.dtn_minus,m.adefD_action,m.adefG_action]);
end

function estimate = LOCAL_estimate(c)
  estimate = struct('evaluator_calls_max',161,'seconds_low',20*60, ...
    'seconds_high',23*60,'target_seconds',c.target_seconds_per_attempt, ...
    'hard_seconds',c.hard_seconds_per_run,'peak_mib_max',c.pilot_memory_mib, ...
    'source','full-est.md');
end

function LOCAL_parent_gate(parent,c)
  if ~isfield(parent,'lineage') || ...
      ~strcmp(parent.lineage.token,c.parent_token) || ~parent.pass || ...
      parent.candidate.k ~= c.kstar
    error('kreadyfull:Parent','Frozen zoom2 parent failed lineage checks.');
  end
end

function audit = LOCAL_pilot_gate(path,here,c)
  if ~isfile(path)
    error('kreadyfull:Pilot','The source-closed pilot-a3 result is absent.');
  end
  loaded = load(path,'result'); pilot = loaded.result;
  if ~pilot.pass || ~strcmp(pilot.schema,'TEP_I1_K_READY_PILOT_V3') || ...
      pilot.anchor_identity > c.proxy_seed_identity_tol || ~pilot.parity.pass
    error('kreadyfull:Pilot','pilot-a3 did not pass its frozen gates.');
  end
  required = {'plan-v3.md','cfg_v3.m','eval_k_v3.m','run_pilot_v3.m', ...
    'plan-v2.md','cfg_v2.m','eval_k_v2.m','kproxy_v2.m'};
  sources = pilot.provenance.sources;
  for j = 1:numel(required)
    index = find(strcmp({sources.name},required{j}),1);
    current = LOCAL_hash(fullfile(here,required{j}));
    if isempty(index) || ~strcmp(sources(index).sha256,current)
      error('kreadyfull:PilotSource','pilot-a3 source hash drifted: %s.', ...
        required{j});
    end
  end
  audit = struct('path',path,'status',pilot.status,'pass',pilot.pass, ...
    'anchor_identity',pilot.anchor_identity,'parity',pilot.parity, ...
    'source_match',true);
end

%% ==================== Artifact helpers ====================
% These helpers record source-closed, append-only evidence.

function p = LOCAL_provenance(here,repo)
  names = {'plan.md','plan-v2.md','plan-v3.md','full-est.md', ...
    'full_cfg.m','run_full.m', ...
    'full_core.m','full_neg.m','cfg_v3.m','eval_k_v3.m','cfg_v2.m', ...
    'eval_k_v2.m','kproxy_v2.m','kproxy.m','kchan.m','kgreen.m','kbie.m'};
  sources = struct('name',{},'path',{},'sha256',{});
  for j = 1:numel(names)
    path = fullfile(here,names{j});
    sources(end+1) = struct('name',names{j},'path',path, ...
      'sha256',LOCAL_hash(path)); %#ok<AGROW>
  end
  deps = {'+bloch/incident_rhs.m','+bloch/farfield_extractors.m', ...
    '+geom/construct_cont.m','+kernel/h2d_directch.m', ...
    '+kernel/kress_l_splits.m','+kernel/kress_mn_splits.m', ...
    '+quad/quad_kress_rvec.m','+utils/triginterp.m', ...
    'test/i1/k-scan/zoom_core.m','test/i1/k-scan/zoom2_cfg.m', ...
    'test/i1/k-scan/scan_cfg.m', ...
    'test/i1/k-scan/output/zoom2/result.mat'};
  for j = 1:numel(deps)
    path = fullfile(repo,deps{j});
    sources(end+1) = struct('name',deps{j},'path',path, ...
      'sha256',LOCAL_hash(path)); %#ok<AGROW>
  end
  [code,sha] = system(sprintf('git -C "%s" rev-parse HEAD',repo));
  if code ~= 0, error('kreadyfull:Git','Cannot record Git SHA.'); end
  p = struct('runtime','MATLAB','version',version,'git_sha',strtrim(sha), ...
    'seed_lsqminnorm',2,'offseed_lsqminnorm',0,'offseed_proxy_svd',0, ...
    'pinv_calls',0,'fallbacks',0,'rank_changes',0,'chart_switches',0, ...
    'offseed_modulus_selection',0,'sources',sources);
end

function value = LOCAL_hash(path)
  fid = fopen(path,'r');
  if fid < 0, error('kreadyfull:Hash','Cannot read %s.',path); end
  cleanup = onCleanup(@() fclose(fid)); bytes = fread(fid,Inf,'*uint8');
  digest = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
  digest.update(typecast(bytes(:),'int8')); raw = typecast(digest.digest(),'uint8');
  value = lower(reshape(dec2hex(raw,2).',1,[])); clear cleanup;
end

function LOCAL_csv(path,rows)
  fid = fopen(path,'w');
  if fid < 0, error('kreadyfull:Artifact','Cannot write %s.',path); end
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
  if ischar(x)
    value = ['"',strrep(x,'"','""'),'"'];
  elseif islogical(x) || (isnumeric(x) && isscalar(x))
    value = sprintf('%.17g',x);
  else
    value = ['"',strrep(mat2str(x),'"','""'),'"'];
  end
end

function LOCAL_report(path,r)
  fid = fopen(path,'w'); cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'# I1.4 V3 full attempt %d\n\n',r.attempt);
  fprintf(fid,'- Status: `%s`; pass: `%d`\n',r.status,r.pass);
  fprintf(fid,'- Radius: `%.17g`; seconds: `%.17g`\n',r.radius,r.elapsed_seconds);
  fprintf(fid,'- First failure: `%s`\n',r.first_failure);
  fprintf(fid,'- Pilot-a3 source match / parity / anchor identity: ');
  fprintf(fid,'`%d / %d / %.17g`\n',r.pilot_a3.source_match, ...
    r.pilot_a3.parity.pass,r.pilot_a3.anchor_identity);
  fprintf(fid,'- Sample rows / CR rows / negatives: `%d / %d / %d`\n', ...
    numel(r.nodes),numel(r.cr),numel(r.negatives));
  fprintf(fid,'- One radius per invocation: `1`\n');
  fprintf(fid,'- Locator/contour/root/estimator calls: `0/0/0/0`\n');
  fprintf(fid,'\nThis is sampled discrete readiness, not a root or theorem.\n');
  clear cleanup;
end

function rows = LOCAL_empty_closure()
  rows = struct('cardinal_index',{},'alternate_parent_index',{}, ...
    'level',{},'plus_overlap',{},'minus_overlap',{}, ...
    'comparison_pass',{},'comparison_max',{},'threshold',{},'pass',{});
end

function rows = LOCAL_empty_cr()
  rows = struct('level',{},'object',{},'h0',{},'cr_h0',{},'cr_h1',{}, ...
    'cr_h2',{},'spread_x',{},'spread_y',{},'trend_pass',{}, ...
    'shift_compare_pass',{},'shift_compare_max',{},'pass',{}, ...
    'node_index',{},'k_real',{},'k_imag',{});
end

function rows = LOCAL_empty_negatives()
  rows = struct('name',{},'value',{},'threshold',{},'direction',{}, ...
    'checker',{},'pass',{},'status',{});
end
