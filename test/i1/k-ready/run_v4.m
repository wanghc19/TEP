function result = run_v4()
%RUN_V4 Run the sole source-frozen I1.4 V4 readiness experiment.
% Purpose:
%   Re-run the largest V3 disk with the separately frozen CR step repair.
% Output:
%   result - Compact evidence under output/v4-a1/.
% Main algorithm:
%   Gate the frozen parent and V3 pilot, stream the complete disk and closure
%   checks, apply V4 CR at nine centers, then run every required negative.
% Numerical goal:
%   Decide sampled fixed-M root readiness without locator or root isolation.

  if exist('OCTAVE_VERSION','builtin') ~= 0 || isempty(which('lsqminnorm'))
    error('kreadyv4:MATLABRequired','MATLAB with lsqminnorm is required.');
  end
  here = fileparts(mfilename('fullpath'));
  repo = fileparts(fileparts(fileparts(here)));
  addpath(repo); addpath(here); addpath(fullfile(repo,'test','i1','k-scan'));
  c = cfg_v4();
  if ~c.v4_branch_domain_pass
    error('kreadyv4:BranchDomain','The enlarged CR stencil is not safe.');
  end
  output = fullfile(here,c.output_relative);
  if exist(output,'dir') || exist(output,'file')
    error('kreadyv4:OutputExists','output/v4-a1 already exists.');
  end
  mkdir(output); diary(fullfile(output,'run.log'));
  cleanup = onCleanup(@() diary('off')); timer = tic;
  provenance = LOCAL_provenance(here,repo);
  LOCAL_csv(fullfile(output,'source-manifest.csv'),provenance.sources);

  parent_path = fullfile(repo,'test','i1','k-scan','output','zoom2','result.mat');
  loaded = load(parent_path,'result'); parent = loaded.result;
  LOCAL_parent(parent,c);
  pilot = LOCAL_pilot(fullfile(here,'output','pilot-a3','result.mat'),here,c);
  selectors = struct('plus',parent.frame_rows_plus, ...
    'minus',parent.frame_rows_minus);
  [seed,frame] = eval_k_v3('seed',c,selectors);
  metric = full_core('compare',seed,c);
  nodes = full_core('node_rows',seed,1,'center',metric,0); nodes(:) = [];
  factors = full_core('factor_rows',seed,1); factors(:) = [];
  branches = full_core('branch_rows',seed,1); branches(:) = [];
  qz_rows = full_core('qz_rows',seed,1); qz_rows(:) = [];
  closures = LOCAL_empty_closure(); cr_rows = LOCAL_empty_cr();
  negatives = LOCAL_empty_neg(); negative_cr = LOCAL_empty_negcr();
  failure = '';

  % --- stage 1: complete largest-disk star ---
  [nodes,factors,branches,qz_rows,ok] = LOCAL_append(seed,1,'center',0,c, ...
    nodes,factors,branches,qz_rows);
  if ~ok, failure = 'CENTER_GATE'; end
  radius = c.v4_radius;
  boundary_plus = cell(2,4); boundary_minus = cell(2,4);
  if isempty(failure)
    offsets = [0.5*radius*exp(1i*c.half_angles), ...
      radius*exp(1i*c.boundary_angles)];
    kinds = [repmat({'half'},1,8),repmat({'boundary'},1,32)];
    for j = 1:numel(offsets)
      LOCAL_time(timer,c);
      node = eval_k_v3('point',c.kstar+offsets(j),c,frame);
      bindex = max(0,j-8);
      [nodes,factors,branches,qz_rows,ok] = LOCAL_append(node,j+1, ...
        kinds{j},bindex,c,nodes,factors,branches,qz_rows);
      if j > 8
        slot = find(c.cardinal_indices == j-8,1);
        if ~isempty(slot)
          boundary_plus{1,slot} = node.coarse.plus.Z;
          boundary_plus{2,slot} = node.fine.plus.Z;
          boundary_minus{1,slot} = node.coarse.minus.Z;
          boundary_minus{2,slot} = node.fine.minus.Z;
        end
      end
      clear node;
      if ~ok, failure = sprintf('SAMPLED_NODE_%d',j+1); break; end
    end
  end

  % --- stage 2: alternate-parent closure ---
  if isempty(failure)
    levels = {'coarse','fine'};
    for j = 1:4
      direct = c.cardinal_indices(j);
      parent_index = c.alternate_parent_indices(j);
      parent_slot = find(c.cardinal_indices == parent_index,1);
      alternate = frame;
      alternate.seed_Z_plus = boundary_plus(:,parent_slot).';
      alternate.seed_Z_minus = boundary_minus(:,parent_slot).';
      node = eval_k_v3('point',c.kstar+radius* ...
        exp(1i*c.boundary_angles(direct)),c,alternate);
      cm = full_core('compare',node,c);
      for l = 1:2
        [op,~] = full_core('overlap',boundary_plus{l,j}, ...
          node.(levels{l}).plus.Z);
        [om,~] = full_core('overlap',boundary_minus{l,j}, ...
          node.(levels{l}).minus.Z);
        current = cm.pass && node.(levels{l}).pass && ...
          min(op,om) >= c.qz_overlap_min;
        closures(end+1) = struct('cardinal_index',direct, ...
          'alternate_parent_index',parent_index,'level',levels{l}, ...
          'plus_overlap',op,'minus_overlap',om,'comparison_pass',cm.pass, ...
          'comparison_max',LOCAL_metric_max(cm),'threshold',c.qz_overlap_min, ...
          'pass',current); %#ok<AGROW>
        if ~current && isempty(failure), failure = 'LOOP_CLOSURE'; end
      end
      clear node;
      if ~isempty(failure), break; end
    end
  end

  % --- stage 3: V4 CR on center and all half-radius nodes ---
  if isempty(failure)
    centers = [c.kstar,c.kstar+0.5*radius*exp(1i*c.half_angles)];
    for j = 1:numel(centers)
      LOCAL_time(timer,c);
      current = core_v4(centers(j),frame,c);
      for q = 1:numel(current)
        current(q).node_index = j;
        current(q).k_real = real(centers(j));
        current(q).k_imag = imag(centers(j));
      end
      cr_rows = [cr_rows;current(:)]; %#ok<AGROW>
      if ~all([current.pass]), failure = sprintf('V4_CR_NODE_%d',j); break; end
    end
  end

  % --- stage 4: all required negatives ---
  if isempty(failure)
    good_cr = max([cr_rows.cr4,cr_rows.cr2,cr_rows.cr1]);
    [negatives,negative_cr] = neg_v4(seed,frame,c,good_cr);
    if numel(negatives) ~= numel(c.negative_names) || ...
        ~isequal({negatives.name},c.negative_names) || ...
        ~all([negatives.pass]) || ~all([negative_cr.pass])
      failure = 'NEGATIVE_SUITE';
    end
  end
  elapsed = toc(timer); engineering_pass = elapsed <= c.hard_seconds_per_run;
  if ~engineering_pass, failure = 'HARD_TIME'; end
  pass = isempty(failure) && engineering_pass;
  if pass, status = 'I1_4_V4_PASS_WITH_CONDITIONS'; ...
  else, status = 'I1_4_V4_FAIL'; end
  result = struct('schema',c.schema,'experiment_id',c.experiment_id, ...
    'status',status,'pass',pass,'first_failure',failure,'radius',radius, ...
    'elapsed_seconds',elapsed,'engineering_pass',engineering_pass, ...
    'nodes',nodes,'factors',factors,'branches',branches,'qz',qz_rows, ...
    'closures',closures,'cr',cr_rows,'negatives',negatives, ...
    'negative_cr',negative_cr,'pilot_a3',pilot,'provenance',provenance, ...
    'branch_distance',c.v4_branch_distance,'max_shift',c.v4_max_shift, ...
    'claim_boundary',c.claim_boundary,'v3_verdict','I1_4_FAIL_UNCHANGED', ...
    'locator_calls',0,'contour_calls',0,'root_calls',0, ...
    'derivative_qualified',false,'estimator_calls',0, ...
    'max_matrix_order',512,'peak_memory_bound_mib',512);
  save(fullfile(output,'result.mat'),'result','-v7.3');
  LOCAL_csv(fullfile(output,'nodes.csv'),nodes);
  LOCAL_csv(fullfile(output,'factors.csv'),factors);
  LOCAL_csv(fullfile(output,'branches.csv'),branches);
  LOCAL_csv(fullfile(output,'qz.csv'),qz_rows);
  LOCAL_csv(fullfile(output,'closures.csv'),closures);
  LOCAL_csv(fullfile(output,'cr.csv'),cr_rows);
  LOCAL_csv(fullfile(output,'negatives.csv'),negatives);
  LOCAL_csv(fullfile(output,'negative-cr.csv'),negative_cr);
  LOCAL_report(fullfile(output,'report.md'),result);
  fprintf('I1_K_READY_V4 status=%s pass=%d seconds=%.6g\n', ...
    status,pass,elapsed);
end

%% ==================== Stream and source gates ====================
% These helpers preserve the V3 evaluator and append-only evidence contract.

function [nr,fr,br,qr,pass] = ...
    LOCAL_append(node,index,kind,bindex,c,nr,fr,br,qr)
  metric = full_core('compare',node,c);
  nr = [nr;full_core('node_rows',node,index,kind,metric,bindex)];
  fr = [fr;full_core('factor_rows',node,index)];
  br = [br;full_core('branch_rows',node,index)];
  qr = [qr;full_core('qz_rows',node,index)];
  pass = metric.pass && all([node.coarse.factors.pass]) && ...
    all([node.fine.factors.pass]);
end

function LOCAL_time(timer,c)
  if toc(timer) > c.hard_seconds_per_run
    error('kreadyv4:HardTime','The 30-minute hard limit expired.');
  end
end

function LOCAL_parent(parent,c)
  if ~parent.pass || ~strcmp(parent.lineage.token,c.parent_token) || ...
      parent.candidate.k ~= c.kstar
    error('kreadyv4:Parent','The frozen I1.3 parent failed.');
  end
end

function audit = LOCAL_pilot(path,here,c)
  loaded = load(path,'result'); pilot = loaded.result;
  if ~pilot.pass || ~pilot.parity.pass || ...
      pilot.anchor_identity > c.proxy_seed_identity_tol
    error('kreadyv4:Pilot','The frozen V3 pilot failed.');
  end
  required = {'plan-v3.md','cfg_v3.m','eval_k_v3.m','run_pilot_v3.m', ...
    'plan-v2.md','cfg_v2.m','eval_k_v2.m','kproxy_v2.m'};
  for j = 1:numel(required)
    index = find(strcmp({pilot.provenance.sources.name},required{j}),1);
    if isempty(index) || ~strcmp(pilot.provenance.sources(index).sha256, ...
        LOCAL_hash(fullfile(here,required{j})))
      error('kreadyv4:PilotSource','Pilot source drifted: %s.',required{j});
    end
  end
  audit = struct('status',pilot.status,'pass',pilot.pass, ...
    'parity_pass',pilot.parity.pass,'anchor_identity',pilot.anchor_identity, ...
    'source_match',true);
end

function value = LOCAL_metric_max(m)
  value = max([m.block_abs,m.block_action,m.pencil_action, ...
    m.subspace_plus,m.subspace_minus,m.cauchy_plus,m.cauchy_minus, ...
    m.dtn_plus,m.dtn_minus,m.adefD_action,m.adefG_action]);
end

%% ==================== V4 artifacts ====================
% These helpers record sources and compact Markdown/CSV outputs.

function p = LOCAL_provenance(here,repo)
  names = {'plan-v4.md','cfg_v4.m','core_v4.m','neg_v4.m','run_v4.m', ...
    'est-v4.md','plan-v3.md','cfg_v3.m','eval_k_v3.m','plan-v2.md', ...
    'cfg_v2.m','eval_k_v2.m','kproxy_v2.m','full_core.m','full_neg.m', ...
    'kproxy.m','kchan.m','kgreen.m','kbie.m'};
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
    'test/i1/k-scan/scan_cfg.m','test/i1/k-scan/output/zoom2/result.mat'};
  for j = 1:numel(deps)
    path = fullfile(repo,deps{j});
    sources(end+1) = struct('name',deps{j},'path',path, ...
      'sha256',LOCAL_hash(path)); %#ok<AGROW>
  end
  [code,sha] = system(sprintf('git -C "%s" rev-parse HEAD',repo));
  if code ~= 0, error('kreadyv4:Git','Cannot record Git SHA.'); end
  p = struct('runtime','MATLAB','version',version,'git_sha',strtrim(sha), ...
    'seed_lsqminnorm',2,'offseed_lsqminnorm',0,'offseed_proxy_svd',0, ...
    'pinv_calls',0,'fallbacks',0,'rank_changes',0,'chart_switches',0, ...
    'offseed_modulus_selection',0,'sources',sources);
end

function value = LOCAL_hash(path)
  fid = fopen(path,'r');
  if fid < 0, error('kreadyv4:Hash','Cannot read %s.',path); end
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
  fprintf(fid,'# I1.4 V4 readiness report\n\n');
  fprintf(fid,'- Status: `%s`; pass: `%d`.\n',r.status,r.pass);
  fprintf(fid,'- First failure: `%s`; seconds: `%.17g`.\n', ...
    r.first_failure,r.elapsed_seconds);
  fprintf(fid,'- Radius / branch distance / max stencil shift: ');
  fprintf(fid,'`%.17g / %.17g / %.17g`.\n',r.radius, ...
    r.branch_distance,r.max_shift);
  fprintf(fid,'- Rows nodes/factors/branches/QZ/closures/CR/negatives: ');
  fprintf(fid,'`%d/%d/%d/%d/%d/%d/%d`.\n',numel(r.nodes), ...
    numel(r.factors),numel(r.branches),numel(r.qz),numel(r.closures), ...
    numel(r.cr),numel(r.negatives));
  fprintf(fid,'- Frozen V3 verdict: `%s`.\n',r.v3_verdict);
  fprintf(fid,'- Locator/contour/root/estimator calls: `0/0/0/0`.\n');
  fprintf(fid,'\nA pass is sampled fixed-M readiness, not a root or eigenvalue.\n');
  clear cleanup;
end

function rows = LOCAL_empty_closure()
  rows = struct('cardinal_index',{},'alternate_parent_index',{}, ...
    'level',{},'plus_overlap',{},'minus_overlap',{}, ...
    'comparison_pass',{},'comparison_max',{},'threshold',{},'pass',{});
end

function rows = LOCAL_empty_cr()
  rows = struct('level',{},'object',{},'h4',{},'h2',{},'h1',{}, ...
    'cr4',{},'cr2',{},'cr1',{},'dx42',{},'dx21',{},'dy42',{}, ...
    'dy21',{},'shift_pass',{},'compare_max',{},'domain_pass',{}, ...
    'pass',{},'node_index',{},'k_real',{},'k_imag',{});
end

function rows = LOCAL_empty_neg()
  rows = struct('name',{},'value',{},'threshold',{},'direction',{}, ...
    'checker',{},'pass',{},'status',{});
end

function rows = LOCAL_empty_negcr()
  rows = struct('name',{},'h',{},'defect',{},'threshold',{}, ...
    'base_pass',{},'compare_max',{},'pass',{});
end
