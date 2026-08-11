function results = i4_fliss_experiment(profile)
% I4_FLISS_EXPERIMENT Execute and package the isolated dual-track study.
%
% Purpose:
%   Run Track A first, then the separate Track B diagnostic, enforce the
%   10,800-second in-process deadline, and write deterministic-schema MAT,
%   CSV, log, configuration, and Markdown outputs.
%
% Input:
%   profile - Optional 'pilot' or 'baseline'; default is 'pilot'.
%
% Output:
%   results - Combined result struct with model-separation and integrity gates.
%
% Main algorithm:
%   Freeze configuration, start a diary, execute the exact sparse FD control,
%   execute the sharp-disk BIE diagnostic, combine negative controls, then
%   write one profile-specific evidence bundle.
%
% Based on:
%   The experiment-output conventions in test/hg-map and the dual-track I4
%   design frozen from method.pdf and Fliss 2013.
%
% Main changes:
%   Keep exact-profile and BIE-surrogate evidence in distinct model_id
%   namespaces and make all artifact names profile-stable.
%
% Numerical goal:
%   Produce a reproducible minimum experiment without changing package code.

  if nargin < 1 || isempty(profile)
    profile = 'pilot';
  end

  % --- stage 1: freeze configuration and start deterministic logging ---

  here = fileparts(mfilename('fullpath'));
  repo_root = fileparts(fileparts(here));
  addpath(repo_root);
  addpath(here);
  config = i4_fliss_config(profile);
  config.experiment_dir = here;
  config.repo_root = repo_root;
  config.output_dir = fullfile(here, 'output', config.profile);
  config.command = sprintf(config.command, here);
  if exist(config.output_dir, 'dir') ~= 7
    mkdir(config.output_dir);
  end

  rng(config.random_seed, 'twister');
  log_file = fullfile(config.output_dir, 'run.log');
  diary('off');
  if exist(log_file, 'file') == 2
    delete(log_file);
  end
  diary(log_file);
  diary_cleanup = onCleanup(@() diary('off')); %#ok<NASGU>

  runtime.start_token = tic;
  runtime.max_seconds = config.max_runtime_seconds;
  fprintf('I4 Fliss 2013 dual-track experiment\n');
  fprintf('Profile: %s\n', config.profile);
  fprintf('Track A model_id: %s\n', config.exact.model_id);
  fprintf('Track B model_id: %s\n', config.bie.model_id);
  fprintf('Comparison scope: %s\n', config.comparison_scope);
  fprintf('Hard runtime cap: %d seconds\n', config.max_runtime_seconds);

  results = struct();
  results.config = config;
  results.track_a = [];
  results.track_b = [];
  results.negative_cases = [];
  results.failure = struct('identifier', '', 'message', '');
  results.completed = false;

  % --- stage 2: execute Track A before the separate Track B diagnostic ---

  try
    fprintf('\n--- Track A: exact smooth finite-difference control ---\n');
    [results.track_a, negative_a] = i4_fd_track(config, runtime);
    fprintf('Track A completed in %.3f seconds.\n', toc(runtime.start_token));

    fprintf('\n--- Track B: sharp-disk BIE diagnostic ---\n');
    [results.track_b, negative_b] = i4_bie_track(config, runtime);
    fprintf('Track B completed in %.3f seconds.\n', toc(runtime.start_token));
    results.negative_cases = [negative_a; negative_b];
    results.completed = true;
  catch ME
    results.failure.identifier = ME.identifier;
    results.failure.message = strrep(ME.message, sprintf('\n'), ' ');
    fprintf('\nEXPERIMENT FAILURE: %s: %s\n', ...
      results.failure.identifier, results.failure.message);
    if exist('negative_a', 'var')
      results.negative_cases = negative_a;
    end
  end

  % --- stage 3: apply integrity gates and write the evidence bundle ---

  results.elapsed_seconds = toc(runtime.start_token);
  results.model_ids_distinct = LOCAL_model_ids_distinct(results);
  results.no_bie_root_claim = LOCAL_no_bie_root_claim(results);
  results.output_scope_pass = strcmp(config.comparison_scope, ...
    'side-by-side-only');
  results.integrity_pass = results.completed && ...
    results.model_ids_distinct && results.no_bie_root_claim && ...
    results.output_scope_pass;
  results.scientific_pass = LOCAL_scientific_pass(results);
  results.bie_scientific_decision = LOCAL_bie_decision(results);

  LOCAL_write_config(results, config.output_dir);
  LOCAL_write_exact_bands(results, config.output_dir);
  LOCAL_write_exact_modes(results, config.output_dir);
  LOCAL_write_exact_tail(results, config.output_dir);
  LOCAL_write_bie_samples(results, config.output_dir);
  LOCAL_write_bie_summary(results, config.output_dir);
  LOCAL_write_negative_cases(results, config.output_dir);
  LOCAL_write_report(results, config.output_dir);
  save(fullfile(config.output_dir, 'results.mat'), 'results');

  fprintf('\nElapsed seconds: %.6f\n', results.elapsed_seconds);
  fprintf('Integrity pass: %d\n', results.integrity_pass);
  fprintf('Scientific positive-control pass: %d\n', results.scientific_pass);
  fprintf('BIE scientific decision: %s\n', results.bie_scientific_decision);
  fprintf('Evidence bundle: %s\n', config.output_dir);
end

%% ==================== Integrity gates ====================
% These helpers prevent cross-model claims and distinguish scientific gates.

function pass = LOCAL_model_ids_distinct(results)
  pass = isstruct(results.track_a) && isstruct(results.track_b) && ...
    isfield(results.track_a, 'model_id') && ...
    isfield(results.track_b, 'model_id') && ...
    ~strcmp(results.track_a.model_id, results.track_b.model_id);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pass = LOCAL_no_bie_root_claim(results)
  pass = isstruct(results.track_b) && ...
    isfield(results.track_b, 'root_claim_allowed') && ...
    ~results.track_b.root_claim_allowed;
  if ~pass || ~isfield(results.track_b, 'cases')
    return;
  end
  for icase = 1:length(results.track_b.cases)
    cont = results.track_b.cases(icase).continuation;
    if any([cont.root_claim])
      pass = false;
      return;
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pass = LOCAL_scientific_pass(results)
  pass = false;
  if isstruct(results.track_a) && isfield(results.track_a, 'scientific_pass')
    pass = results.track_a.scientific_pass;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function decision = LOCAL_bie_decision(results)
  decision = 'BIE_NOT_COMPLETED';
  if isstruct(results.track_b) && ...
      isfield(results.track_b, 'scientific_decision')
    decision = results.track_b.scientific_decision;
  end
end

%% ==================== Configuration output ====================
% This helper writes the frozen parameters and exact launch command.

function LOCAL_write_config(results, output_dir)
  path = fullfile(output_dir, 'config.txt');
  fid = LOCAL_open(path);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  cfg = results.config;
  fprintf(fid, 'experiment_id=%s\n', cfg.experiment_id);
  fprintf(fid, 'schema_version=%d\n', cfg.schema_version);
  fprintf(fid, 'profile=%s\n', cfg.profile);
  fprintf(fid, 'max_runtime_seconds=%d\n', cfg.max_runtime_seconds);
  fprintf(fid, 'command=%s\n', cfg.command);
  fprintf(fid, 'comparison_scope=%s\n', cfg.comparison_scope);
  fprintf(fid, 'track_a_model_id=%s\n', cfg.exact.model_id);
  fprintf(fid, 'track_a_points_per_cell=%d\n', cfg.exact.points_per_cell);
  fprintf(fid, 'track_a_theta_count=%d\n', cfg.exact.theta_count);
  if isfield(cfg.exact, 'spatial_coarse_points_per_cell')
    fprintf(fid, 'track_a_spatial_coarse_points_per_cell=%d\n', ...
      cfg.exact.spatial_coarse_points_per_cell);
  else
    fprintf(fid, 'track_a_spatial_coarse_points_per_cell=unavailable\n');
  end
  fprintf(fid, 'track_a_num_bands=%d\n', cfg.exact.num_bands);
  fprintf(fid, 'track_a_strip_nev=%d\n', cfg.exact.strip_nev);
  fprintf(fid, 'track_a_tail_cells=%s\n', ...
    mat2str(cfg.exact.tail_cells_each_side));
  fprintf(fid, 'track_a_beta=%s\n', mat2str(cfg.exact.beta, 17));
  fprintf(fid, 'track_a_reference_omega2=%s\n', ...
    mat2str(cfg.exact.reference_omega2, 17));
  fprintf(fid, 'track_a_control_role=%s|%s\n', ...
    cfg.exact.control_role{1}, cfg.exact.control_role{2});
  fprintf(fid, 'track_a_contrast_continuation_run=%d\n', ...
    cfg.exact.contrast_continuation_run);
  fprintf(fid, 'track_a_maximum_adjacent_edge_uncertainty=%.17g\n', ...
    cfg.exact.maximum_adjacent_edge_uncertainty);
  fprintf(fid, 'track_a_minimum_gap_uncertainty_factor=%.17g\n', ...
    cfg.exact.minimum_gap_uncertainty_factor);
  fprintf(fid, 'track_a_minimum_margin_uncertainty_factor=%.17g\n', ...
    cfg.exact.minimum_margin_uncertainty_factor);
  fprintf(fid, 'track_a_primary_tail_relative_shift_tolerance=%.17g\n', ...
    cfg.exact.primary_tail_relative_shift_tolerance);
  fprintf(fid, 'track_b_model_id=%s\n', cfg.bie.model_id);
  fprintf(fid, 'track_b_claim_scope=%s\n', cfg.bie.claim_scope);
  fprintf(fid, 'track_b_radius=%.17g\n', cfg.bie.radius);
  fprintf(fid, 'track_b_s_values=%s\n', mat2str(cfg.bie.s_values, 17));
  fprintf(fid, 'track_b_ntot=%d\n', cfg.bie.ntot);
  fprintf(fid, 'track_b_M=%d\n', cfg.bie.M);
  fprintf(fid, 'track_b_num_k=%d\n', cfg.bie.num_k);
  fprintf(fid, 'track_b_num_refine=%d\n', cfg.bie.num_refine);
  fprintf(fid, 'track_b_root_claim_allowed=%d\n', ...
    cfg.bie.root_claim_allowed);
end

%% ==================== Exact-track CSV outputs ====================
% These helpers write band, mode, and tail-comparison tables.

function LOCAL_write_exact_bands(results, output_dir)
  path = fullfile(output_dir, 'exact-bands.csv');
  fid = LOCAL_open(path);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['model_id,case_id,case_name,control_role,beta,band_index,', ...
    'lower,upper,standard_lower,standard_upper,shifted_lower,', ...
    'shifted_upper,spatial_coarse_lower,spatial_coarse_upper,', ...
    'lower_uncertainty,upper_uncertainty,edge_gate_available,', ...
    'max_normalized_residual,', ...
    'reference_omega2,in_expanded_band,gap_lower,gap_upper,gap_margin,', ...
    'gap_width,max_adjacent_edge_uncertainty,edge_uncertainty_pass,', ...
    'width_pass,margin_pass,baseline_gap_gate_pass\n']);
  if ~isstruct(results.track_a) || ~isfield(results.track_a, 'cases')
    return;
  end
  for icase = 1:length(results.track_a.cases)
    one = results.track_a.cases(icase);
    band = one.band;
    for j = 1:length(band.lower)
      fprintf(fid, '%s,%d,%s,%s,%.17g,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%d,%.17g,%.17g,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%d,%d,%d,%d\n', ...
        results.track_a.model_id, one.case_id, one.case_name, ...
        one.control_role, one.beta, j, band.lower(j), band.upper(j), ...
        band.standard_lower(j), band.standard_upper(j), ...
        band.shifted_lower(j), band.shifted_upper(j), ...
        band.spatial_coarse_lower(j), band.spatial_coarse_upper(j), ...
        band.lower_uncertainty(j), band.upper_uncertainty(j), ...
        band.edge_gate_available, max(band.normalized_residual(:, j)), ...
        one.reference_omega2, band.gap.in_expanded_band, ...
        band.gap.lower_edge, band.gap.upper_edge, band.gap.margin, ...
        band.gap.width, band.gap.maximum_adjacent_edge_uncertainty, ...
        band.gap.edge_uncertainty_pass, band.gap.width_pass, ...
        band.gap.margin_pass, band.gap.baseline_gate_pass);
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_exact_modes(results, output_dir)
  path = fullfile(output_dir, 'exact-strip-modes.csv');
  fid = LOCAL_open(path);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['model_id,case_id,case_name,beta,tail_cells,has_defect,', ...
    'num_unknowns,mode_index,omega2,reference_omega2,normalized_residual,', ...
    'center_fraction,end_fraction,center_end_ratio,selected\n']);
  if ~isstruct(results.track_a) || ~isfield(results.track_a, 'cases')
    return;
  end
  for icase = 1:length(results.track_a.cases)
    one = results.track_a.cases(icase);
    for itail = 1:length(one.strips)
      strip = one.strips(itail);
      for j = 1:length(strip.modes)
        mode = strip.modes(j);
        fprintf(fid, '%s,%d,%s,%.17g,%d,%d,%d,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%d\n', ...
          results.track_a.model_id, one.case_id, one.case_name, one.beta, ...
          strip.tail_cells_each_side, strip.has_defect, strip.num_unknowns, ...
          mode.mode_index, mode.omega2, one.reference_omega2, ...
          mode.normalized_residual, mode.center_fraction, mode.end_fraction, ...
          mode.center_end_ratio, j == strip.selected_index);
      end
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_exact_tail(results, output_dir)
  path = fullfile(output_dir, 'exact-tail-comparison.csv');
  fid = LOCAL_open(path);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['model_id,case_id,case_name,beta,reference_omega2,', ...
    'tail_coarse,tail_fine,omega2_shift,absolute_shift,', ...
    'relative_shift,relative_shift_tolerance,relative_shift_gate_available,', ...
    'relative_shift_pass,', ...
    'center_fraction_change,end_fraction_change,mass_vector_overlap,', ...
    'mass_vector_overlap_tolerance,mass_vector_overlap_pass,tail_pass,', ...
    'positive_control_pass,band_edge_uncertainty\n']);
  if ~isstruct(results.track_a) || ~isfield(results.track_a, 'cases')
    return;
  end
  for icase = 1:length(results.track_a.cases)
    one = results.track_a.cases(icase);
    cmp = one.tail_comparison;
    fprintf(fid, '%s,%d,%s,%.17g,%.17g,%d,%d,%.17g,%.17g,%.17g,%.17g,%d,%d,%.17g,%.17g,%.17g,%.17g,%d,%d,%d,%.17g\n', ...
      results.track_a.model_id, one.case_id, one.case_name, one.beta, ...
      one.reference_omega2, cmp.tail_coarse, cmp.tail_fine, ...
      cmp.omega2_shift, cmp.absolute_shift, cmp.relative_shift, ...
      cmp.relative_shift_tolerance, cmp.relative_shift_gate_available, ...
      cmp.relative_shift_pass, cmp.center_fraction_change, ...
      cmp.end_fraction_change, cmp.mass_vector_overlap, ...
      cmp.mass_vector_overlap_tolerance, cmp.mass_vector_overlap_pass, ...
      cmp.pass, one.positive_control.pass, ...
      one.band.gap.maximum_adjacent_edge_uncertainty);
  end
end

%% ==================== BIE CSV outputs ====================
% These helpers write all real-axis samples and continuation summaries.

function LOCAL_write_bie_samples(results, output_dir)
  path = fullfile(output_dir, 'bie-samples.csv');
  fid = LOCAL_open(path);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['model_id,case_id,case_name,beta,s,refractive_index,k_real,', ...
    'stage,status,K,num_modes,count_unit,min_unit_distance,', ...
    'count_right_decay,', ...
    'count_left_decay,raw_sigma,normalized_sigma,matrix_norm_2,', ...
    'cell_solve_residual,bloch_evp_residual,minimum_abs_gamma,root_claim\n']);
  if ~isstruct(results.track_b) || ~isfield(results.track_b, 'cases')
    return;
  end
  for icase = 1:length(results.track_b.cases)
    one = results.track_b.cases(icase);
    for is = 1:length(one.continuation)
      cont = one.continuation(is);
      samples = [cont.coarse; cont.refined];
      for j = 1:length(samples)
        s = samples(j);
        fprintf(fid, '%s,%d,%s,%.17g,%.17g,%.17g,%.17g,%s,%s,%g,%g,%g,%.17g,%g,%g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%d\n', ...
          results.track_b.model_id, one.case_id, one.case_name, one.beta, ...
          s.s, s.refractive_index, s.k_real, s.stage, s.status, s.K, ...
          s.num_modes, s.count_unit, s.min_unit_distance, s.count_right_decay, ...
          s.count_left_decay, s.raw_sigma, s.normalized_sigma, ...
          s.matrix_norm_2, s.cell_solve_residual, s.bloch_evp_residual, ...
          s.minimum_abs_gamma, s.root_claim);
      end
    end
  end
  if isfield(results.track_b, 'homogeneous_negative_samples')
    samples = results.track_b.homogeneous_negative_samples;
    for j = 1:length(samples)
      s = samples(j);
      fprintf(fid, '%s,%d,%s,%.17g,%.17g,%.17g,%.17g,%s,%s,%g,%g,%g,%.17g,%g,%g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%d\n', ...
        results.track_b.model_id, s.case_id, 'homogeneous-control', ...
        s.beta, s.s, s.refractive_index, s.k_real, s.stage, s.status, ...
        s.K, s.num_modes, s.count_unit, s.min_unit_distance, ...
        s.count_right_decay, ...
        s.count_left_decay, s.raw_sigma, s.normalized_sigma, ...
        s.matrix_norm_2, s.cell_solve_residual, s.bloch_evp_residual, ...
        s.minimum_abs_gamma, s.root_claim);
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_bie_summary(results, output_dir)
  path = fullfile(output_dir, 'bie-summary.csv');
  fid = LOCAL_open(path);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['model_id,case_id,case_name,beta,reference_k,s,', ...
    'refractive_index,k_left,k_right,num_successful,num_failed,', ...
    'num_bad_count,projected_gap_candidate_count,usable_gap_samples,', ...
    'num_incomplete_modes,num_incomplete_samples,', ...
    'best_dip_k,best_normalized_sigma,', ...
    'best_raw_sigma,maximum_bloch_residual,bloch_residual_pass,', ...
    'dip_warning,classification,completeness_decision,root_claim\n']);
  if ~isstruct(results.track_b) || ~isfield(results.track_b, 'cases')
    return;
  end
  for icase = 1:length(results.track_b.cases)
    one = results.track_b.cases(icase);
    for is = 1:length(one.continuation)
      cont = one.continuation(is);
      fprintf(fid, '%s,%d,%s,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%d,%d,%d,%d,%d,%d,%d,%.17g,%.17g,%.17g,%.17g,%d,%d,%s,%s,%d\n', ...
        results.track_b.model_id, one.case_id, one.case_name, one.beta, ...
        one.reference_k, cont.s, cont.refractive_index, cont.k_window(1), ...
        cont.k_window(2), cont.num_successful, cont.num_failed, ...
        cont.num_bad_count, cont.projected_gap_candidate_count, ...
        cont.usable_gap_samples, cont.num_incomplete_modes, ...
        cont.num_incomplete_samples, cont.best_dip_k, ...
        cont.best_normalized_sigma, ...
        cont.best_raw_sigma, cont.maximum_bloch_residual, ...
        cont.bloch_residual_pass, cont.dip_warning, cont.classification, ...
        cont.completeness_decision, cont.root_claim);
    end
  end
end

%% ==================== Controls and report ====================
% These helpers write the negative-control table and human-readable report.

function LOCAL_write_negative_cases(results, output_dir)
  path = fullfile(output_dir, 'negative-controls.csv');
  fid = LOCAL_open(path);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, 'track,name,value,threshold,pass,detail\n');
  for j = 1:length(results.negative_cases)
    row = results.negative_cases(j);
    fprintf(fid, '%s,%s,%.17g,%.17g,%d,%s\n', row.track, row.name, ...
      row.value, row.threshold, row.pass, LOCAL_csv_quote(row.detail));
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_report(results, output_dir)
  path = fullfile(output_dir, 'report.md');
  fid = LOCAL_open(path);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, '# I4 Fliss 2013 dual-track experiment\n\n');
  fprintf(fid, '- Profile: `%s`\n', results.config.profile);
  fprintf(fid, '- Runtime cap: %d seconds\n', ...
    results.config.max_runtime_seconds);
  fprintf(fid, '- Elapsed time: %.6f seconds\n', results.elapsed_seconds);
  fprintf(fid, '- Integrity pass: `%d`\n', results.integrity_pass);
  fprintf(fid, '- Scientific positive-control pass: `%d`\n', ...
    results.scientific_pass);
  fprintf(fid, '- BIE scientific decision: `%s`\n', ...
    results.bie_scientific_decision);
  fprintf(fid, '- Exact command: `%s`\n\n', results.config.command);

  fprintf(fid, '## Interpretation boundary\n\n');
  fprintf(fid, ['Track A (`%s`) discretizes the exact smooth Fliss profile. ', ...
    'Track B (`%s`) uses a radius-0.2 sharp homogeneous disk. The outputs ', ...
    'are side-by-side diagnostics and must not be pooled as one model. ', ...
    'A Track B singular-value dip is not reported as a root or eigenvalue.\n\n'], ...
    results.config.exact.model_id, results.config.bie.model_id);

  fprintf(fid, '## Track A: exact smooth finite-difference control\n\n');
  if isstruct(results.track_a) && isfield(results.track_a, 'cases')
    for icase = 1:length(results.track_a.cases)
      one = results.track_a.cases(icase);
      fine = one.strips(end).selected;
      fprintf(fid, ['- %s: beta=%.17g, reference omega^2=%.17g, ', ...
        'role=`%s`, ', ...
        'tail-%d omega^2=%.17g, normalized residual=%.3e, ', ...
        'center fraction=%.3e, end fraction=%.3e, ', ...
        '8/12 relative shift=%.3e, mass-vector overlap=%.6f, ', ...
        'edge gate available=%d, expanded-band membership=%d, ', ...
        'gap gate pass=%d, pass=%d.\n'], ...
        one.case_name, one.beta, one.reference_omega2, one.control_role, ...
        one.strips(end).tail_cells_each_side, fine.omega2, ...
        fine.normalized_residual, fine.center_fraction, fine.end_fraction, ...
        one.tail_comparison.relative_shift, ...
        one.tail_comparison.mass_vector_overlap, one.band.edge_gate_available, ...
        one.band.gap.in_expanded_band, one.band.gap.baseline_gate_pass, ...
        one.positive_control.pass);
    end
    fprintf(fid, ['\nBand-edge uncertainty method: %s. It is explicit ', ...
      'but is not a rigorous error bound.\n\n'], ...
      results.track_a.cases(1).band.edge_uncertainty_method);
    fprintf(fid, ['Track A contrast continuation status: `%s`. %s\n\n'], ...
      results.track_a.contrast_continuation.status, ...
      results.track_a.contrast_continuation.reason);
  else
    fprintf(fid, 'Track A did not complete.\n\n');
  end

  fprintf(fid, '## Track B: sharp-disk BIE diagnostic\n\n');
  if isstruct(results.track_b) && isfield(results.track_b, 'cases')
    for icase = 1:length(results.track_b.cases)
      one = results.track_b.cases(icase);
      for is = 1:length(one.continuation)
        cont = one.continuation(is);
        fprintf(fid, ['- %s, s=%.17g, n=%.17g: projected-gap ', ...
          'candidates=%d, usable gap samples=%d, bad-count samples=%d, ', ...
          'missing modes=%d, ', ...
          'best real-axis dip k=%.17g, normalized sigma=%.3e, ', ...
          'maximum Bloch residual=%.3e, completeness=`%s`, ', ...
          'classification=`%s`, ', ...
          'root claim=%d.\n'], one.case_name, cont.s, ...
          cont.refractive_index, cont.projected_gap_candidate_count, ...
          cont.usable_gap_samples, cont.num_bad_count, ...
          cont.num_incomplete_modes, cont.best_dip_k, ...
          cont.best_normalized_sigma, cont.maximum_bloch_residual, ...
          cont.completeness_decision, cont.classification, cont.root_claim);
      end
    end
    fprintf(fid, '\nContinuation order starts at s=1 as required.\n\n');
  else
    fprintf(fid, 'Track B did not complete.\n\n');
  end

  fprintf(fid, '## Negative controls\n\n');
  for j = 1:length(results.negative_cases)
    row = results.negative_cases(j);
    fprintf(fid, '- Track %s `%s`: value=%.17g, threshold=%.17g, pass=%d. %s\n', ...
      row.track, row.name, row.value, row.threshold, row.pass, row.detail);
  end

  if ~isempty(results.failure.identifier)
    fprintf(fid, '\n## Failure\n\n`%s`: %s\n', ...
      results.failure.identifier, results.failure.message);
  end
end

%% ==================== File utilities ====================
% These helpers provide checked deterministic text output.

function fid = LOCAL_open(path)
  fid = fopen(path, 'w');
  if fid < 0
    error('i4_fliss_experiment:OutputOpen', ...
      'Could not open output file %s.', path);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function value = LOCAL_csv_quote(value)
  value = strrep(value, '"', '""');
  value = ['"', value, '"'];
end
