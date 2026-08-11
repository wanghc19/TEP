function results = run_analytic_readiness(run_label)
% RUN_ANALYTIC_READINESS Run one preserved I4 evidence phase.
%
% Purpose:
%   Execute exactly one baseline or repeat transaction under
%   output.inprogress, refusing to overwrite any existing evidence.
%
% Input:
%   run_label - Exactly 'baseline' or 'repeat'.
%
% Output:
%   results - Complete I4 result struct.
%
% Numerical goal:
%   Publish output only after a complete reproducible repeat.

  if nargin ~= 1 || ...
      ~(strcmp(run_label, 'baseline') || strcmp(run_label, 'repeat'))
    error('analytic_readiness:RunLabel', ...
      'run_label must be exactly baseline or repeat.');
  end

  here = fileparts(mfilename('fullpath'));
  repo_root = fileparts(fileparts(fileparts(here)));
  final_root = fullfile(here, 'output');
  staging_root = fullfile(here, 'output.inprogress');
  output_dir = fullfile(staging_root, run_label);
  if exist(final_root, 'dir') == 7
    error('analytic_readiness:FinalTreeExists', ...
      'Refusing to overwrite published tree %s.', final_root);
  end

  lock = LOCAL_capture_lock(repo_root, here);
  lock.source_manifest = analytic_readiness_experiment('source_manifest');
  lock.source_manifest_fingerprint = ...
    LOCAL_manifest_fingerprint(lock.source_manifest);
  baseline_results = [];
  if strcmp(run_label, 'baseline')
    if exist(staging_root, 'dir') == 7
      error('analytic_readiness:StagingTreeExists', ...
        'Refusing to overwrite in-progress tree %s.', staging_root);
    end
    mkdir(output_dir);
  else
    baseline_dir = fullfile(staging_root, 'baseline');
    marker_path = fullfile(baseline_dir, 'completion.marker');
    result_path = fullfile(baseline_dir, 'results.mat');
    if exist(marker_path, 'file') ~= 2 || exist(result_path, 'file') ~= 2
      error('analytic_readiness:MissingBaseline', ...
        'Repeat requires a complete staged baseline.');
    end
    loaded = load(result_path);
    baseline_results = loaded.results;
    if ~LOCAL_valid_marker(baseline_dir, baseline_results)
      error('analytic_readiness:InvalidBaselineMarker', ...
        'The baseline completion marker or one of its hashes is invalid.');
    end
    if ~LOCAL_lock_equal(lock, baseline_results.runtime_lock)
      error('analytic_readiness:ReproLockDrift', ...
        'Commit, dirty path set, or design hash changed before repeat.');
    end
    if exist(output_dir, 'dir') == 7
      error('analytic_readiness:RepeatTreeExists', ...
        'Refusing to overwrite in-progress repeat tree %s.', output_dir);
    end
    mkdir(output_dir);
  end

  log_path = fullfile(output_dir, 'run.log');
  if exist(log_path, 'file') == 2
    error('analytic_readiness:PreserveLog', ...
      'Refusing to overwrite preserved log %s.', log_path);
  end
  diary(log_path);
  diary_cleanup = onCleanup(@() diary('off')); %#ok<NASGU>
  fprintf('I4 analytic-readiness run: %s\n', run_label);
  results = analytic_readiness_experiment( ...
    'run', run_label, output_dir, baseline_results, lock);
  diary('off');

  results.artifact_bundle_complete = ...
    LOCAL_validate_prebundle(output_dir, results.cfg);
  results = analytic_readiness_experiment( ...
    'finalize', results, output_dir, baseline_results);
  save(fullfile(output_dir, 'results.mat'), 'results', '-v7');
  if ~LOCAL_validate_bundle(output_dir, results)
    error('analytic_readiness:ArtifactBundleIncomplete', ...
      'The closed artifact bundle failed validation; no marker was written.');
  end
  LOCAL_write_marker(output_dir, results);
  if ~LOCAL_valid_marker(output_dir, results)
    error('analytic_readiness:MarkerValidation', ...
      'The just-written completion marker failed validation.');
  end

  if strcmp(run_label, 'repeat')
    LOCAL_write_reproducibility( ...
      fullfile(staging_root, 'reproducibility.txt'), results);
    if ~results.reproducibility.pass
      error('analytic_readiness:ReproducibilityFailure', ...
        'Repeat evidence did not reproduce; staging was preserved.');
    end
    if exist(final_root, 'dir') == 7
      error('analytic_readiness:FinalTreeExists', ...
        'Final tree appeared before publication.');
    end
    [moved, message] = movefile(staging_root, final_root);
    if ~moved
      error('analytic_readiness:AtomicPublish', ...
        'Could not publish the completed tree: %s', message);
    end
  end
end

%% ==================== Worktree lock ====================
% These helpers freeze commit, design, and the authorized dirty path set.

function lock = LOCAL_capture_lock(repo_root, here)
  [status, commit] = system(sprintf( ...
    'git -C "%s" rev-parse HEAD', strrep(repo_root, '"', '\"')));
  if status ~= 0
    error('analytic_readiness:GitCommit', ...
      'Could not record the current commit.');
  end
  [status, porcelain] = system(sprintf( ...
    'git -C "%s" status --porcelain', strrep(repo_root, '"', '\"')));
  if status ~= 0
    error('analytic_readiness:GitStatus', ...
      'Could not record the worktree status.');
  end
  dirty_paths = LOCAL_dirty_paths(porcelain);
  allowed_exact = { ...
    'research/projects/eig-apost/implementation/i4-readiness.md', ...
    'research/projects/eig-apost/implementation/SYMBOL.md'};
  allowed_prefix = 'test/root-ready/analytic-readiness/';
  for idx = 1:length(dirty_paths)
    path = dirty_paths{idx};
    allowed = any(strcmp(path, allowed_exact)) || ...
      strncmp(path, allowed_prefix, length(allowed_prefix));
    if ~allowed
      error('analytic_readiness:UnauthorizedDirtyPath', ...
        'Unrelated dirty path blocks the frozen run: %s', path);
    end
  end
  design_path = fullfile(repo_root, 'research', 'projects', 'eig-apost', ...
    'implementation', 'i4-readiness.md');
  symbol_path = fullfile(repo_root, 'research', 'projects', 'eig-apost', ...
    'implementation', 'SYMBOL.md');
  lock.commit = strtrim(commit);
  lock.dirty_paths = sort(dirty_paths(:));
  lock.design_sha256 = LOCAL_file_sha256(design_path);
  lock.symbol_sha256 = LOCAL_file_sha256(symbol_path);
  lock.experiment_path = here;
end

function paths = LOCAL_dirty_paths(porcelain)
  lines = strsplit(porcelain, sprintf('\n'));
  paths = {};
  for idx = 1:length(lines)
    line = lines{idx};
    if isempty(line)
      continue;
    end
    path = strtrim(line(4:end));
    arrow = strfind(path, ' -> ');
    if ~isempty(arrow)
      path = strtrim(path(arrow(end) + 4:end));
    end
    if length(path) >= 2 && path(1) == '"' && path(end) == '"'
      path = path(2:end - 1);
    end
    paths{end + 1} = path; %#ok<AGROW>
  end
end

function equal = LOCAL_lock_equal(a, b)
  equal = strcmp(a.commit, b.commit) && ...
    strcmp(a.design_sha256, b.design_sha256) && ...
    strcmp(a.symbol_sha256, b.symbol_sha256) && ...
    strcmp(a.source_manifest_fingerprint, ...
      b.source_manifest_fingerprint) && ...
    isequal(a.source_manifest, b.source_manifest) && ...
    isequal(a.dirty_paths(:), b.dirty_paths(:));
end

function value = LOCAL_manifest_fingerprint(manifest)
  payload = '';
  for idx = 1:length(manifest)
    payload = [payload, manifest(idx).scope, '|', manifest(idx).name, '|', ...
      manifest(idx).path, '|', manifest(idx).sha256, sprintf('\n')]; %#ok<AGROW>
  end
  value = hash('sha256', payload);
end

%% ==================== Artifact transaction ====================
% These helpers validate bundles and write the authoritative marker last.

function pass = LOCAL_validate_prebundle(output_dir, cfg)
  names = setdiff(cfg.required_artifacts, ...
    {'results.mat', 'run.log', 'completion.marker'}, 'stable');
  pass = true;
  for idx = 1:length(names)
    info = dir(fullfile(output_dir, names{idx}));
    pass = pass && length(info) == 1 && ~info.isdir && info.bytes > 0;
  end
  log_info = dir(fullfile(output_dir, 'run.log'));
  pass = pass && length(log_info) == 1 && log_info.bytes > 0;
end

function pass = LOCAL_validate_bundle(output_dir, results)
  names = setdiff(results.cfg.required_artifacts, ...
    {'completion.marker'}, 'stable');
  pass = results.artifact_bundle_complete;
  for idx = 1:length(names)
    info = dir(fullfile(output_dir, names{idx}));
    pass = pass && length(info) == 1 && ~info.isdir && info.bytes > 0;
  end
  try
    loaded = load(fullfile(output_dir, 'results.mat'));
    pass = pass && isfield(loaded, 'results') && ...
      strcmp(loaded.results.cfg.version, results.cfg.version) && ...
      strcmp(loaded.results.run_label, results.run_label);
    pass = pass && LOCAL_validate_negative_raw(loaded.results);
  catch
    pass = false;
  end
  pass = pass && LOCAL_validate_evidence_contract(output_dir, results);
end

function pass = LOCAL_validate_negative_raw(results)
  n9_index = find(strcmp({results.negatives.id}, 'N9'), 1);
  if isempty(n9_index)
    pass = false;
    return;
  end
  row = results.negatives(n9_index);
  required = row.pass || row.raw_F_preserved;
  if ~required
    pass = ~row.raw_F_preserved;
    return;
  end
  pass = isfield(results, 'negative_raw') && ...
    isfield(results.negative_raw, 'N9');
  if ~pass
    return;
  end
  raw = results.negative_raw.N9;
  fields = {'F_bad', 'common_vector', 'q', 'mutation', ...
    'primitive_blocks', 'fingerprint', 'null_residual', 'saved'};
  pass = all(isfield(raw, fields)) && raw.saved && ...
    isequal(size(raw.F_bad), [240, 240]) && ...
    isequal(size(raw.common_vector), [240, 1]) && raw.q == 120 && ...
    strcmp(raw.mutation, 'ZERO_COLUMN_A_c_E_L_E_R') && ...
    isequal(raw.primitive_blocks, {'A_c', 'E_L', 'E_R'}) && ...
    strcmp(raw.fingerprint, LOCAL_numeric_fingerprint(raw.F_bad)) && ...
    strcmp(raw.fingerprint, row.raw_F_fingerprint);
  if pass
    residual = norm(raw.F_bad * raw.common_vector, 2) / ...
      max(1, norm(raw.F_bad, 2));
    pass = residual <= 1e-12 && abs(residual - raw.null_residual) <= 1e-15;
  end
end

function value = LOCAL_numeric_fingerprint(matrix)
  data = [real(matrix(:)); imag(matrix(:))];
  payload = sprintf('%.17g,', double(data));
  value = hash('sha256', payload);
end

function pass = LOCAL_validate_evidence_contract(output_dir, results)
  tables = { ...
    'source-manifest.csv', results.cfg.source_manifest; ...
    'branch-ledger.csv', results.branch_rows; ...
    'locator.csv', results.locator; ...
    'chart-ledger.csv', results.charts; ...
    'sampled-domain.csv', results.sampled; ...
    'factor-ledger.csv', results.factors; ...
    'cr.csv', results.cr; ...
    'negative-cases.csv', results.negatives; ...
    'gate.csv', results.gates};
  pass = true;
  for idx = 1:size(tables, 1)
    pass = pass && LOCAL_validate_csv_schema( ...
      fullfile(output_dir, tables{idx, 1}), tables{idx, 2});
  end
  manifest = results.cfg.source_manifest;
  pass = pass && ~isempty(manifest) && ...
    all(strcmp({manifest.scope}, 'DIRECT_PROJECT_CALLS_ONLY'));
  manifest_text = fileread(fullfile(output_dir, 'source-manifest.csv'));
  pass = pass && length(strfind(manifest_text, ...
    'DIRECT_PROJECT_CALLS_ONLY')) == length(manifest);
  gate_text = fileread(fullfile(output_dir, 'gate.csv'));
  for idx = 1:length(results.gates)
    needle = sprintf('"%s",%d,"%s"', results.gates(idx).gate, ...
      results.gates(idx).pass, results.gates(idx).status);
    pass = pass && ~isempty(strfind(gate_text, needle));
  end
  config_text = fileread(fullfile(output_dir, 'config.txt'));
  pass = pass && ~isempty(strfind(config_text, ...
    ['version=', results.cfg.version])) && ...
    ~isempty(strfind(config_text, ...
    ['representation=', results.cfg.representation])) && ...
    ~isempty(strfind(config_text, 'threshold.reproducibility=1e-13')) && ...
    ~isempty(strfind(config_text, 'command.baseline=')) && ...
    ~isempty(strfind(config_text, 'command.repeat='));
  row_names = {'source_manifest', 'branch', 'locator', 'chart', ...
    'sampled', 'factor', 'cr', 'negative', 'gate'};
  row_values = [length(manifest), length(results.branch_rows), ...
    length(results.locator), length(results.charts), ...
    length(results.sampled), length(results.factors), length(results.cr), ...
    length(results.negatives), length(results.gates)];
  for idx = 1:length(row_names)
    needle = sprintf('actual_stage_rows.%s=%d', ...
      row_names{idx}, row_values(idx));
    pass = pass && ~isempty(strfind(config_text, needle));
  end
  report_text = fileread(fullfile(output_dir, 'report.md'));
  pass = pass && ~isempty(strfind(report_text, results.root_readiness)) && ...
    ~isempty(strfind(report_text, 'PHYSICAL_ROOT_READY=STOP'));
end

function pass = LOCAL_validate_csv_schema(path, rows)
  text_value = fileread(path);
  lines = strsplit(text_value, sprintf('\n'));
  if ~isempty(lines) && isempty(lines{end})
    lines(end) = [];
  end
  expected_header = strjoin(fieldnames(rows).', ',');
  pass = length(lines) == length(rows) + 1 && ...
    ~isempty(lines) && strcmp(lines{1}, expected_header);
end

function LOCAL_write_marker(output_dir, results)
  marker_path = fullfile(output_dir, 'completion.marker');
  if exist(marker_path, 'file') == 2
    error('analytic_readiness:PreserveMarker', ...
      'Refusing to overwrite completion.marker.');
  end
  names = setdiff(results.cfg.required_artifacts, ...
    {'completion.marker'}, 'stable');
  fid = fopen(marker_path, 'w');
  if fid < 0
    error('analytic_readiness:MarkerOpen', 'Could not write completion marker.');
  end
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, 'version=%s\n', results.cfg.version);
  fprintf(fid, 'run_label=%s\n', results.run_label);
  fprintf(fid, 'artifact_bundle_complete=1\n');
  fprintf(fid, 'final_label=%s\n', results.root_readiness);
  fprintf(fid, 'artifact_count=%d\n', length(names));
  for idx = 1:length(names)
    fprintf(fid, 'artifact.%03d.path=%s\n', idx, names{idx});
    fprintf(fid, 'artifact.%03d.sha256=%s\n', idx, ...
      LOCAL_file_sha256(fullfile(output_dir, names{idx})));
  end
  fprintf(fid, 'marker_written_last=1\n');
end

function pass = LOCAL_valid_marker(output_dir, results)
  marker_path = fullfile(output_dir, 'completion.marker');
  if exist(marker_path, 'file') ~= 2
    pass = false;
    return;
  end
  names = setdiff(results.cfg.required_artifacts, ...
    {'completion.marker'}, 'stable');
  expected = sprintf('version=%s\n', results.cfg.version);
  expected = [expected, sprintf('run_label=%s\n', results.run_label)];
  expected = [expected, 'artifact_bundle_complete=1', sprintf('\n')];
  expected = [expected, sprintf('final_label=%s\n', results.root_readiness)];
  expected = [expected, sprintf('artifact_count=%d\n', length(names))];
  for idx = 1:length(names)
    expected = [expected, sprintf('artifact.%03d.path=%s\n', ...
      idx, names{idx})]; %#ok<AGROW>
    expected = [expected, sprintf('artifact.%03d.sha256=%s\n', ...
      idx, LOCAL_file_sha256(fullfile(output_dir, names{idx})))]; %#ok<AGROW>
  end
  expected = [expected, 'marker_written_last=1', sprintf('\n')];
  pass = strcmp(fileread(marker_path), expected);
end

function LOCAL_write_reproducibility(path, results)
  fid = fopen(path, 'w');
  if fid < 0
    error('analytic_readiness:ReproOpen', ...
      'Could not write reproducibility.txt.');
  end
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  r = results.reproducibility;
  fprintf(fid, 'status=%s\n', r.status);
  fprintf(fid, 'pass=%d\n', r.pass);
  fprintf(fid, 'numeric_relative_difference=%.17g\n', ...
    r.numeric_relative_difference);
  fprintf(fid, 'manifest_equal=%d\n', r.manifest_equal);
  fprintf(fid, 'branch_fingerprints_equal=%d\n', ...
    r.branch_fingerprints_equal);
  fprintf(fid, 'chart_projectors_equal=%d\n', ...
    r.chart_projectors_equal);
  fprintf(fid, 'selected_disk_equal=%d\n', r.selected_disk_equal);
  fprintf(fid, 'gate_classifications_equal=%d\n', ...
    r.gate_classifications_equal);
  fprintf(fid, 'sampled_equal=%d\n', r.sampled_equal);
  fprintf(fid, 'factors_equal=%d\n', r.factors_equal);
  fprintf(fid, 'branches_equal=%d\n', r.branches_equal);
  fprintf(fid, 'cr_equal=%d\n', r.cr_equal);
  fprintf(fid, 'charts_equal=%d\n', r.charts_equal);
  fprintf(fid, 'locator_equal=%d\n', r.locator_equal);
  fprintf(fid, 'disks_equal=%d\n', r.disks_equal);
  fprintf(fid, 'negatives_equal=%d\n', r.negatives_equal);
end

%% ==================== File hashing ====================
% This helper computes raw-file SHA-256 values through the system utility.

function value = LOCAL_file_sha256(path)
  command = sprintf('shasum -a 256 "%s"', strrep(path, '"', '\"'));
  [status, output] = system(command);
  if status ~= 0
    error('analytic_readiness:HashFailure', ...
      'Could not hash %s.', path);
  end
  parts = strsplit(strtrim(output));
  value = parts{1};
end
