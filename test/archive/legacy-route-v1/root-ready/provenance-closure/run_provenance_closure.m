function results = run_provenance_closure(run_label)
% RUN_PROVENANCE_CLOSURE Run one preserved provenance-closure phase.
%
% Purpose:
%   Execute either the frozen baseline or the unchanged-source repeat while
%   recording a phase-local log under output.inprogress/baseline or repeat.
%
% Input:
%   run_label - Exactly 'baseline' or 'repeat'.
%
% Output:
%   results - Complete provenance-closure result struct.
%
% Numerical goal:
%   Preserve two independent runs without touching historical root-ready
%   output or authorizing any complex-root or estimator calculation.

  if nargin ~= 1 || ...
      ~(strcmp(run_label, 'baseline') || strcmp(run_label, 'repeat'))
    error('run_provenance_closure:RunLabel', ...
      'run_label must be exactly baseline or repeat.');
  end

  here = fileparts(mfilename('fullpath'));
  final_root = fullfile(here, 'output');
  staging_root = fullfile(here, 'output.inprogress');
  output_dir = fullfile(staging_root, run_label);
  if exist(final_root, 'dir') == 7
    error('run_provenance_closure:FinalTreeExists', ...
      'Refusing to overwrite published tree %s.', final_root);
  end
  if strcmp(run_label, 'baseline')
    if exist(staging_root, 'dir') == 7
      error('run_provenance_closure:StagingTreeExists', ...
        'Refusing to overwrite in-progress tree %s.', staging_root);
    end
    mkdir(output_dir);
  else
    marker_path = fullfile(staging_root, 'baseline', ...
      'completion.marker');
    if exist(marker_path, 'file') ~= 2
      error('run_provenance_closure:MissingBaselineMarker', ...
        'Repeat requires baseline marker %s.', marker_path);
    end
    if ~LOCAL_valid_baseline_marker(staging_root)
      error('run_provenance_closure:InvalidBaselineMarker', ...
        'Baseline completion marker or a recorded hash is invalid.');
    end
    if exist(output_dir, 'dir') == 7
      error('run_provenance_closure:RepeatTreeExists', ...
        'Refusing to overwrite in-progress repeat %s.', output_dir);
    end
    mkdir(output_dir);
  end
  log_path = fullfile(output_dir, 'run.log');
  if exist(log_path, 'file') == 2
    error('run_provenance_closure:PreserveLog', ...
      'Refusing to overwrite preserved log %s.', log_path);
  end

  diary(log_path);
  cleanup = onCleanup(@() diary('off')); %#ok<NASGU>
  fprintf('Provenance-closure run: %s\n', run_label);
  results = provenance_closure_diagnostic(run_label);
end

%% ==================== Transaction verification ====================
% This helper validates the staged baseline before a repeat directory exists.

function pass = LOCAL_valid_baseline_marker(staging_root)
  baseline_dir = fullfile(staging_root, 'baseline');
  result_path = fullfile(baseline_dir, 'results.mat');
  marker_path = fullfile(baseline_dir, 'completion.marker');
  try
    loaded = load(result_path);
    results = loaded.results;
  catch
    pass = false;
    return;
  end
  filenames = { ...
    'config.txt', 'source-copy.csv', 'shared-system.csv', ...
    'solver-comparison.csv', 'off-collocation.csv', ...
    'projector-fingerprint.csv', 'historical-projector.csv', ...
    'resolution.csv', 'downstream-mismatch.csv', 'gate.csv', ...
    'report.md', 'results.mat', 'run.log'};
  expected = sprintf('version=%s\n', results.cfg.version);
  expected = [expected, 'run_label=baseline', sprintf('\n')];
  expected = [expected, 'artifact_bundle_complete=1', sprintf('\n')];
  expected = [expected, sprintf('operational_label=%s\n', ...
    results.operational_label)];
  expected = [expected, sprintf('artifact_count=%d\n', ...
    length(filenames))];
  for idx = 1:length(filenames)
    path = fullfile(baseline_dir, filenames{idx});
    expected = [expected, sprintf('artifact.%03d.path=baseline/%s\n', ...
      idx, filenames{idx})]; %#ok<AGROW>
    expected = [expected, sprintf('artifact.%03d.sha256=%s\n', ...
      idx, LOCAL_file_sha256(path))]; %#ok<AGROW>
  end
  expected = [expected, 'marker_written_last=1', sprintf('\n')];
  pass = strcmp(fileread(marker_path), expected);
end

function value = LOCAL_file_sha256(path)
  command = sprintf('shasum -a 256 "%s"', strrep(path, '"', '\"'));
  [status, output] = system(command);
  if status ~= 0
    value = 'HASH_FAILED';
    return;
  end
  parts = strsplit(strtrim(output));
  value = parts{1};
end
