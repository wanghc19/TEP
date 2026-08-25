function result = run_v5()
%RUN_V5 Run the one-shot I1.4 V5 negative-closure oracle.
% Purpose:
%   Close the non-identifiable symmetric transmission-swap negative using an
%   independently identifiable manufactured assembly fixture.
% Output:
%   result - Source-closed audit under output/v5-a1/.
% Main algorithm:
%   Hash and import immutable V4 evidence, require its exact failure pattern,
%   then re-execute and record an asymmetric K=3 cell-pencil swap oracle.
% Based on:
%   test/i1/hg-adef/run_hg_adef.m manufactured fixture.
% Numerical goal:
%   Test T_RL/T_LR ordering without changing the symmetric physical model.

  here = fileparts(mfilename('fullpath'));
  output = fullfile(here,'output','v5-a1');
  if exist(output,'dir') || exist(output,'file')
    error('kreadyv5:OutputExists','output/v5-a1 already exists.');
  end
  mkdir(output); diary(fullfile(output,'run.log'));
  cleanup = onCleanup(@() diary('off')); timer = tic;
  v4 = fullfile(here,'output','v4-a1');

  % --- stage 1: fixed artifact and source-closure audit ---
  locked = { ...
    'result.mat','c4730ba11fb6b8bee5ff72513279b1db0869e752953be86a79694a42c3a1ab34'; ...
    'source-manifest.csv','ab2c1bf51b84592cac77b910a84492216b0b7cc2785a2b2c15d42a4bedf178e6'; ...
    'nodes.csv','cb572d8e9eca0866391ab43c7a3234ce9b00b7b0b45473dde8d3cdb403aae8a1'; ...
    'cr.csv','8bea1cf20e629dc182c414192bfa924e5571d3743eb1954c11679d25c5af697d'; ...
    'closures.csv','7ade96d66bdbbb14e4e1baf7ceaa5e89c949660c68c086d0b2da32988fd878c4'; ...
    'negatives.csv','83ad07fd0aa13a6f76030ec4118173d4df33bcae8a5e4392ccf2cb50b06db1b3'; ...
    'negative-cr.csv','e8e5274d327416325c851554d350d38e62aa59530cc9afe4c08c9bb35e7dc5bb'};
  artifact_rows = struct('name',{},'expected',{},'actual',{},'pass',{});
  for j = 1:size(locked,1)
    actual = LOCAL_hash(fullfile(v4,locked{j,1}));
    artifact_rows(end+1) = struct('name',locked{j,1}, ...
      'expected',locked{j,2},'actual',actual, ...
      'pass',strcmp(actual,locked{j,2})); %#ok<AGROW>
  end
  manifest_path = fullfile(v4,'source-manifest.csv');
  table_in = readtable(manifest_path,'TextType','string');
  source_rows = struct('name',{},'path',{},'expected',{},'actual',{},'pass',{});
  for j = 1:height(table_in)
    path = char(table_in.path(j)); expected = char(table_in.sha256(j));
    actual = LOCAL_hash(path);
    source_rows(end+1) = struct('name',char(table_in.name(j)), ...
      'path',path,'expected',expected,'actual',actual, ...
      'pass',strcmp(actual,expected)); %#ok<AGROW>
  end
  loaded = load(fullfile(v4,'result.mat'),'result'); v4_result = loaded.result;
  failed = find(~[v4_result.negatives.pass]);
  positive_pass = v4_result.engineering_pass && ...
    all([v4_result.nodes.level_pass]) && ...
    all([v4_result.nodes.comparison_pass]) && ...
    all([v4_result.factors.pass]) && all([v4_result.branches.pass]) && ...
    all([v4_result.qz.pass]) && all([v4_result.closures.pass]) && ...
    all([v4_result.cr.pass]) && all([v4_result.negative_cr.pass]);
  failure_pattern = strcmp(v4_result.first_failure,'NEGATIVE_SUITE') && ...
    numel(failed) == 1 && ...
    strcmp(v4_result.negatives(failed).name,'transmission_swap') && ...
    sum([v4_result.negatives.pass]) == 15;
  zero_calls = v4_result.locator_calls == 0 && ...
    v4_result.contour_calls == 0 && v4_result.root_calls == 0 && ...
    v4_result.estimator_calls == 0;
  import_pass = all([artifact_rows.pass]) && all([source_rows.pass]) && ...
    positive_pass && failure_pattern && zero_calls;

  % --- stage 2: re-execute the identifiable K=3 ordering oracle ---
  S = LOCAL_fixture(); K = 3; I = eye(K); Z = zeros(K);
  pair = LOCAL_pair(S);
  expected_A = zeros(2*K); expected_B = zeros(2*K);
  expected_A(1:K,1:K) = -S.R_L;
  expected_A(1:K,K+1:2*K) = I;
  expected_A(K+1:2*K,1:K) = S.T_LR;
  expected_B(1:K,K+1:2*K) = S.T_RL;
  expected_B(K+1:2*K,1:K) = I;
  expected_B(K+1:2*K,K+1:2*K) = -S.R_R;
  formula_error = norm([pair.A,pair.B]-[expected_A,expected_B],'fro');
  identifiability = norm(S.T_RL-S.T_LR,'fro')/max(1,norm(S.T_RL,'fro'));
  swapped = S; swapped.T_RL = S.T_LR; swapped.T_LR = S.T_RL;
  bad = LOCAL_pair(swapped);
  swap_change = norm([pair.A,pair.B]-[bad.A,bad.B],'fro') / ...
    max(1,norm([pair.A,pair.B],'fro'));
  source = fileread(fullfile(here,'eval_k_v2.m'));
  live_A = contains(source, ...
    "'A',[-blocks.R_L,eye(K);blocks.T_LR,zeros(K)]");
  live_B = contains(source, ...
    "'B',[zeros(K),blocks.T_RL;eye(K),-blocks.R_R]");
  oracle = struct('K',K,'identifiability',identifiability, ...
    'identifiability_min',1e-2,'formula_error',formula_error, ...
    'formula_tol',1e-12,'swap_change',swap_change,'swap_min',1e-8, ...
    'live_A_formula',live_A,'live_B_formula',live_B, ...
    'unused_zero_shape',size(Z),'pass',identifiability > 1e-2 && ...
    formula_error <= 1e-12 && swap_change > 1e-8 && live_A && live_B);
  pass = import_pass && oracle.pass;
  if pass
    status = 'I1_4_V5_PASS_WITH_CONDITIONS';
  else
    status = 'I1_4_V5_FAIL';
  end
  result = struct('schema','TEP_I1_K_READY_V5','status',status, ...
    'pass',pass,'v4_import_pass',import_pass,'positive_pass',positive_pass, ...
    'failure_pattern_pass',failure_pattern,'zero_calls',zero_calls, ...
    'artifact_rows',artifact_rows,'source_rows',source_rows,'oracle',oracle, ...
    'physical_swap_status','INAPPLICABLE_BY_SYMMETRY_NOT_PASS', ...
    'v3_verdict','I1_4_FAIL_UNCHANGED', ...
    'v4_verdict','I1_4_V4_FAIL_UNCHANGED', ...
    'elapsed_seconds',toc(timer),'locator_calls',0,'contour_calls',0, ...
    'root_calls',0,'estimator_calls',0);
  save(fullfile(output,'result.mat'),'result');
  LOCAL_csv(fullfile(output,'artifacts.csv'),artifact_rows);
  LOCAL_csv(fullfile(output,'sources.csv'),source_rows);
  LOCAL_csv(fullfile(output,'oracle.csv'),oracle);
  LOCAL_report(fullfile(output,'report.md'),result);
  fprintf('I1_K_READY_V5 status=%s pass=%d seconds=%.6g\n', ...
    status,pass,result.elapsed_seconds);
end

%% ==================== Manufactured ordering oracle ====================
% These helpers reproduce the frozen asymmetric I1.2 fixture locally.

function S = LOCAL_fixture()
  S.R_L = [0.11i,0.03,-0.02;0.01,-0.07i,0.04;0,0.02,0.09i];
  S.T_RL = [0.82,0.06i,0.01;-0.03,0.74,0.05i;0.02i,0,0.68];
  S.T_LR = [0.61,-0.02,0.07i;0.05i,0.79,-0.01;0.03,0.04i,0.57];
  S.R_R = [-0.05i,0.01,0.03;-0.02i,0.13i,0;0.04,-0.01,0.06i];
end

function pair = LOCAL_pair(S)
  K = size(S.R_L,1);
  pair.A = [-S.R_L,eye(K);S.T_LR,zeros(K)];
  pair.B = [zeros(K),S.T_RL;eye(K),-S.R_R];
end

%% ==================== V5 evidence ====================
% These helpers hash and write the compact closure artifact.

function value = LOCAL_hash(path)
  fid = fopen(path,'r');
  if fid < 0, error('kreadyv5:Hash','Cannot read %s.',path); end
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
  fprintf(fid,'# I1.4 V5 negative-closure report\n\n');
  fprintf(fid,'- Status: `%s`; pass: `%d`.\n',r.status,r.pass);
  fprintf(fid,'- V4 import / positives / exact failure pattern: `%d/%d/%d`.\n', ...
    r.v4_import_pass,r.positive_pass,r.failure_pattern_pass);
  fprintf(fid,'- Manufactured identifiability / formula error / swap change: ');
  fprintf(fid,'`%.17g / %.17g / %.17g`.\n',r.oracle.identifiability, ...
    r.oracle.formula_error,r.oracle.swap_change);
  fprintf(fid,'- Live A/B formula locks: `%d/%d`.\n', ...
    r.oracle.live_A_formula,r.oracle.live_B_formula);
  fprintf(fid,'- Physical swap row: `%s`.\n',r.physical_swap_status);
  fprintf(fid,'- V3/V4 verdicts: `%s / %s`.\n',r.v3_verdict,r.v4_verdict);
  fprintf(fid,'- Locator/contour/root/estimator calls: `0/0/0/0`.\n');
  fprintf(fid,'\nA pass closes an assembly negative; it does not compute a root.\n');
  clear cleanup;
end
