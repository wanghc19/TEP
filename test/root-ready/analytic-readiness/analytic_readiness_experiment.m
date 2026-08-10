function results = analytic_readiness_experiment(action, varargin)
% ANALYTIC_READINESS_EXPERIMENT Run or self-test the frozen I4 evaluator.
%
% Purpose:
%   Implement the reviewed full analytic complex-wavenumber root-readiness
%   experiment without performing root isolation or estimator calculations.
%
% Main algorithm:
%   Freeze the locator and proxy charts, evaluate four chart variants on the
%   three predeclared disks, record all factors and full-matrix CR defects,
%   execute N1--N11, and emit a deterministic evidence bundle.
%
% Based on:
%   research/projects/eig-apost/implementation/i4-readiness.md, version 1.0.
%
% Main changes:
%   This is the first source-derived branch-injected test evaluator.
%
% Numerical goal:
%   Emit at most ROOT_READINESS_SAMPLED_DISCRETE_GO while preserving
%   PHYSICAL_ROOT_READY=STOP.

  if nargin < 1
    error('analytic_readiness:MissingAction', 'An action is required.');
  end
  if strcmp(action, 'selftest')
    results = LOCAL_selftest();
    return;
  end
  if strcmp(action, 'source_manifest')
    here = fileparts(mfilename('fullpath'));
    repo_root = fileparts(fileparts(fileparts(here)));
    cfg = LOCAL_config(repo_root, here);
    results = cfg.source_manifest;
    return;
  end
  if strcmp(action, 'run')
    if length(varargin) ~= 4
      error('analytic_readiness:RunArguments', ...
        'run requires run_label, output_dir, baseline_results, and lock.');
    end
    results = LOCAL_run(varargin{1}, varargin{2}, varargin{3}, varargin{4});
    return;
  end
  if strcmp(action, 'finalize')
    if length(varargin) ~= 3
      error('analytic_readiness:FinalizeArguments', ...
        'finalize requires results, output_dir, and baseline_results.');
    end
    results = LOCAL_finalize(varargin{1}, varargin{2}, varargin{3});
    return;
  end
  error('analytic_readiness:UnknownAction', 'Unknown action %s.', action);
end

%% ==================== Experiment control ====================
% These helpers execute the frozen stages and preserve every failure.

function results = LOCAL_run(run_label, output_dir, baseline_results, lock)
  here = fileparts(mfilename('fullpath'));
  repo_root = fileparts(fileparts(fileparts(here)));
  cfg = LOCAL_config(repo_root, here);
  results.cfg = cfg;
  results.run_label = run_label;
  results.runtime_lock = lock;
  results.locator = LOCAL_empty_locator();
  results.charts = LOCAL_empty_charts();
  results.disks = LOCAL_empty_disks();
  results.sampled = LOCAL_empty_sampled();
  results.factors = LOCAL_empty_factors();
  results.cr = LOCAL_empty_cr();
  results.negatives = LOCAL_empty_negatives();
  results.branch_rows = LOCAL_empty_branch_rows();
  results.gates = LOCAL_empty_gates();
  results.selected_disk = 'NONE';
  results.branch_fingerprint = 'UNAVAILABLE';
  results.projector_fingerprints = {};
  results.proxy_charts = struct([]);
  results.negative_raw = struct();
  results.artifact_bundle_complete = false;

  fprintf('Stage 1/6: real locator\n');
  [results.locator, seed, locator_status] = LOCAL_run_locator(cfg);
  if strcmp(locator_status, 'PASS')
    fprintf('Stage 2/6: seed-frozen proxy charts\n');
    [results.charts, charts, chart_status] = LOCAL_build_charts(cfg, seed);
  else
    charts = struct([]);
    chart_status = locator_status;
  end

  if strcmp(chart_status, 'PASS')
    fprintf('Stage 3/6: deterministic chart refinement\n');
    [results.charts, charts, candidate, refine_status] = ...
      LOCAL_refine_charts(cfg, results.charts, charts, seed);
  else
    candidate = NaN;
    refine_status = chart_status;
  end

  if strcmp(refine_status, 'PASS')
    results.proxy_charts = charts;
    fprintf('Stage 4/6: nested sampled disks and factor ledger\n');
    [results, sample_status] = LOCAL_run_disks(results, cfg, charts, candidate);
  else
    sample_status = refine_status;
  end

  fprintf('Stage 5/6: negative controls\n');
  [results.negatives, results.negative_raw] = ...
    LOCAL_run_negatives(results, cfg, sample_status);
  fprintf('Stage 6/6: gates and preliminary evidence\n');
  results = LOCAL_classify(results, baseline_results);
  LOCAL_write_outputs(results, output_dir);
end

function results = LOCAL_finalize(results, output_dir, baseline_results)
  results = LOCAL_classify(results, baseline_results);
  LOCAL_write_gate_csv(results.gates, fullfile(output_dir, 'gate.csv'));
  LOCAL_write_report(results, fullfile(output_dir, 'report.md'));
end

%% ==================== Frozen configuration ====================
% These helpers define thresholds, geometry, artifacts, and source hashes.

function cfg = LOCAL_config(repo_root, here)
  cfg.version = 'eig-apost-i4-readiness-v1.0';
  cfg.representation = 'SOURCE_DERIVED_BRANCH_INJECTED_TEST_EVALUATOR';
  cfg.repo_root = repo_root;
  cfg.here = here;
  cfg.beta = 0.8;
  cfg.scan = [0.04, 0.18];
  cfg.scan_points = 29;
  cfg.nref = 3;
  cfg.defect_axes = [0.28, 0.21];
  cfg.bulk_axes = [0.40, 0.30];
  cfg.walls = [-1, 1];
  cfg.L = 2;
  cfg.d = 2 * pi;
  cfg.M = 7;
  cfg.p = 15;
  cfg.ntot = 60;
  cfg.locator_level = 3;
  cfg.levels = [0, 3, 4];
  cfg.cr_levels = [0, 4];
  cfg.proxy(1) = struct('label', 'base', 'H', 1.8, ...
    'proxy_dist', 0.7, 'N_side', 40, 'N_top', 40, ...
    'N_proxy_edge', 24, 'M_pw', 8);
  cfg.proxy(2) = struct('label', 'refined', 'H', 1.8, ...
    'proxy_dist', 0.7, 'N_side', 48, 'N_top', 48, ...
    'N_proxy_edge', 28, 'M_pw', 10);
  cfg.rank_ratio = 1e-8;
  cfg.rank_gap = 2;
  cfg.projector_repeat_tol = 1e-10;
  cfg.proxy_rcond_min = 1e-8;
  cfg.proxy_projected_tol = 1e-11;
  cfg.proxy_full_tol = 1e-5;
  cfg.bie_rcond_min = 1e-6;
  cfg.bie_residual_tol = 1e-9;
  cfg.factor_rcond_min = 1e-8;
  cfg.factor_residual_tol = 1e-9;
  cfg.aug_boundary_sep_min = 1e-8;
  cfg.nested_change_max = 0.5;
  cfg.branch_tol = 1e-12;
  cfg.cr_tol = 1e-6;
  cfg.locator_dip_max = 1e-3;
  cfg.locator_neighbor_ratio = 1.5;
  cfg.participation_min = 1e-3;
  cfg.refinement_overlap_min = 0.9;
  cfg.real_axis_mismatch_tol = 1e-5;
  cfg.reproducibility_tol = 1e-13;
  cfg.commands.baseline = [ ...
    'perl -e ''alarm shift; exec @ARGV'' 3600 conda run -n octave ', ...
    'octave --quiet --no-gui --eval "addpath(''test/root-ready/', ...
    'analytic-readiness''); run_analytic_readiness(''baseline'');"'];
  cfg.commands.repeat = [ ...
    'perl -e ''alarm shift; exec @ARGV'' 3600 conda run -n octave ', ...
    'octave --quiet --no-gui --eval "addpath(''test/root-ready/', ...
    'analytic-readiness''); run_analytic_readiness(''repeat'');"'];
  cfg.required_artifacts = {'config.txt', 'source-manifest.csv', ...
    'branch-ledger.csv', 'locator.csv', 'chart-ledger.csv', ...
    'sampled-domain.csv', 'factor-ledger.csv', 'cr.csv', ...
    'negative-cases.csv', 'gate.csv', 'results.mat', 'run.log', ...
    'report.md', 'completion.marker'};
  source_paths = { ...
    fullfile(repo_root, 'research', 'projects', 'eig-apost', ...
      'implementation', 'i4-readiness.md'), ...
    fullfile(repo_root, 'research', 'projects', 'eig-apost', ...
      'implementation', 'SYMBOL.md'), ...
    fullfile(repo_root, '+bloch', 'incident_rhs.m'), ...
    fullfile(repo_root, '+bloch', 'farfield_extractors.m'), ...
    fullfile(repo_root, '+geom', 'construct_cont.m'), ...
    fullfile(repo_root, '+kernel', 'precomp_proxy.m'), ...
    fullfile(repo_root, '+kernel', 'qpgreen_mfs_pairmat.m'), ...
    fullfile(repo_root, '+kernel', 'h2d_directch.m'), ...
    fullfile(repo_root, '+kernel', 'kress_l_splits.m'), ...
    fullfile(repo_root, '+kernel', 'kress_mn_splits.m'), ...
    fullfile(repo_root, '+op', 'construct_A_QP.m'), ...
    fullfile(repo_root, '+quad', 'quad_kress_rvec.m'), ...
    fullfile(repo_root, '+utils', 'triginterp.m'), ...
    fullfile(here, 'LOCAL_anchored_rayleigh_channels.m'), ...
    fullfile(here, 'LOCAL_precomp_proxy_anchored.m'), ...
    fullfile(here, 'LOCAL_qpgreen_mfs_pairmat_anchored.m'), ...
    fullfile(here, 'LOCAL_construct_A_QP_anchored.m'), ...
    fullfile(here, 'analytic_readiness_experiment.m'), ...
    fullfile(here, 'run_analytic_readiness.m')};
  source_names = {'design', 'SYMBOL', 'incident_rhs', ...
    'farfield_extractors', 'construct_cont', 'locator_precomp_proxy', ...
    'locator_qpgreen', 'h2d_directch', 'kress_l_splits', ...
    'kress_mn_splits', 'locator_construct_A_QP', 'quad_kress_rvec', ...
    'triginterp', 'anchored_channels', 'anchored_proxy', ...
    'anchored_green', 'anchored_bie', 'experiment', 'wrapper'};
  cfg.source_manifest = struct('scope', {}, 'name', {}, 'path', {}, ...
    'sha256', {});
  for idx = 1:length(source_paths)
    cfg.source_manifest(end + 1) = struct( ...
      'scope', 'DIRECT_PROJECT_CALLS_ONLY', 'name', source_names{idx}, ...
      'path', source_paths{idx}, ...
      'sha256', LOCAL_source_hash(source_paths{idx})); %#ok<AGROW>
  end
end

%% ==================== Real locator ====================
% This stage uses the authorized pointwise package proxy only on the real scan.

function [rows, seed, status] = LOCAL_run_locator(cfg)
  rows = LOCAL_empty_locator();
  k_nodes = linspace(cfg.scan(1), cfg.scan(2), cfg.scan_points);
  values = NaN(size(k_nodes));
  for idx = 1:length(k_nodes)
    k = k_nodes(idx);
    try
      [ev, ~] = LOCAL_evaluate_pointwise(k, cfg.locator_level, cfg);
      values(idx) = ev.s;
      available = ev.available;
      reason = ev.reason;
    catch exception
      available = false;
      reason = LOCAL_exception_reason(exception);
    end
    rows(end + 1) = struct('stage', 'coarse_29', 'chart', ...
      'package_pointwise_locator_only', 'iteration', 0, 'index', idx, ...
      'k', k, 's', values(idx), 'available', available, ...
      'selected', false, 'reason', reason); %#ok<AGROW>
  end
  if any(~[rows.available])
    seed = NaN;
    status = 'LOCATOR_POINT_UNAVAILABLE';
    return;
  end
  candidates = [];
  for idx = 2:length(values) - 1
    qualifies = values(idx) < values(idx - 1) && ...
      values(idx) < values(idx + 1) && ...
      values(idx) <= cfg.locator_dip_max && ...
      values(idx - 1) >= cfg.locator_neighbor_ratio * values(idx) && ...
      values(idx + 1) >= cfg.locator_neighbor_ratio * values(idx);
    if qualifies
      candidates(end + 1) = idx; %#ok<AGROW>
    end
  end
  if isempty(candidates)
    seed = NaN;
    status = 'NO_SCREENED_DIP';
    return;
  end
  [~, best_local] = min(values(candidates));
  selected = candidates(best_local);
  rows(selected).selected = true;
  seed = k_nodes(selected);
  status = 'PASS';
end

function [ev, factors] = LOCAL_evaluate_pointwise(k, level, cfg, proxy_index)
  if nargin < 4
    proxy_index = 1;
  end
  pars1 = LOCAL_pars1(k, cfg);
  pars2 = LOCAL_pars2(cfg.proxy(proxy_index));
  proxy = kernel.precomp_proxy(pars1, pars2);
  gamma = LOCAL_physical_gamma(k, cfg.M, cfg);
  channels = LOCAL_anchored_rayleigh_channels( ...
    k, cfg.beta, cfg.d, cfg.M, cfg.L, gamma, 'LOCATOR_POINTWISE');
  [center, center_factor] = LOCAL_build_object( ...
    k, cfg.defect_axes, pars1, proxy, gamma, channels, cfg, false);
  [lead, lead_factor] = LOCAL_build_object( ...
    k, cfg.bulk_axes, pars1, proxy, gamma, channels, cfg, false);
  lead = LOCAL_scattering_from_center(lead);
  factors = [center_factor, lead_factor];
  for step = 1:level
    [lead, double_factors] = LOCAL_star(lead, lead);
    factors = [factors, double_factors]; %#ok<AGROW>
  end
  [F, assembly_factors] = LOCAL_assemble_and_factors(center, lead, lead, cfg);
  factors = [factors, assembly_factors];
  ev = LOCAL_augmented_metrics(F, cfg);
  ev.available = ev.available && LOCAL_factor_gate(factors, cfg);
  if ~ev.available
    ev.reason = 'LOCATOR_FACTOR_UNAVAILABLE';
  end
end

%% ==================== Anchored branch chart ====================
% These helpers create and audit the single logarithmic continuation chart.

function anchor = LOCAL_branch_anchor(kc, M, cfg, label)
  anchor.kc = kc;
  anchor.orders = (-M:M).';
  anchor.beta_m = cfg.beta + 2 * pi * anchor.orders / cfg.d;
  anchor.gamma_seed = LOCAL_physical_gamma(kc, M, cfg);
  anchor.label = label;
  raw = [real(anchor.orders(:)); real(anchor.gamma_seed(:)); ...
    imag(anchor.gamma_seed(:))];
  anchor.fingerprint = LOCAL_raw_fingerprint(raw);
end

function gamma = LOCAL_branch_values(k, anchor)
  delta = k - anchor.kc;
  left = 1 + delta ./ (anchor.kc - anchor.beta_m);
  right = 1 + delta ./ (anchor.kc + anchor.beta_m);
  gamma = anchor.gamma_seed .* exp(0.5 * log(left) + 0.5 * log(right));
end

function gamma = LOCAL_physical_gamma(k, M, cfg)
  orders = (-M:M).';
  beta_m = cfg.beta + 2 * pi * orders / cfg.d;
  gamma = sqrt(complex(k^2 - beta_m.^2));
  flip = imag(gamma) < 0 | (imag(gamma) == 0 & real(gamma) < 0);
  gamma(flip) = -gamma(flip);
end

function row = LOCAL_branch_audit(k, anchor, cfg, consumer)
  gamma = LOCAL_branch_values(k, anchor);
  target = k^2 - anchor.beta_m.^2;
  algebra = max(abs(gamma.^2 - target) ./ max(1, abs(target)));
  delta = k - anchor.kc;
  reverse = gamma .* exp( ...
    0.5 * log(1 - delta ./ (k - anchor.beta_m)) + ...
    0.5 * log(1 - delta ./ (k + anchor.beta_m)));
  roundtrip = max(abs(reverse - anchor.gamma_seed) ./ ...
    max(1, abs(anchor.gamma_seed)));
  row = struct('attempt', NaN, 'consumer', consumer, 'k_real', real(k), ...
    'k_imag', imag(k), 'order_min', anchor.orders(1), ...
    'order_max', anchor.orders(end), 'fingerprint', anchor.fingerprint, ...
    'algebra_error', algebra, 'roundtrip_error', roundtrip, ...
    'pass', algebra <= cfg.branch_tol && roundtrip <= cfg.branch_tol, ...
    'status', LOCAL_pass_status( ...
      algebra <= cfg.branch_tol && roundtrip <= cfg.branch_tol));
end

%% ==================== Fixed proxy charts ====================
% These stages select seed ranks once and refine candidate locations in place.

function [rows, charts, status] = LOCAL_build_charts(cfg, seed)
  rows = LOCAL_empty_charts();
  charts = struct('label', {}, 'proxy_index', {}, 'rank', {}, ...
    'U', {}, 'V', {}, 'singular_values', {}, 'fingerprint', {}, ...
    'anchor', {});
  for proxy_index = 1:2
    pcfg = cfg.proxy(proxy_index);
    anchor = LOCAL_branch_anchor(seed, pcfg.M_pw, cfg, ...
      ['proxy_', pcfg.label]);
    pars1 = LOCAL_pars1(seed, cfg);
    pars2 = LOCAL_pars2(pcfg);
    gamma = LOCAL_branch_values(seed, anchor);
    [~, A, ~, ~] = LOCAL_precomp_proxy_anchored( ...
      pars1, pars2, gamma, [], 'collocation');
    [U, S, V] = svd(A, 'econ');
    singular_values = diag(S);
    rank_seed = sum(singular_values / singular_values(1) >= cfg.rank_ratio);
    if proxy_index == 1
      ranks = rank_seed + [-2, -1, 0];
      labels = {'base_rminus2', 'base_rminus1', 'base_r'};
    else
      ranks = rank_seed;
      labels = {'refined_r'};
    end
    for idx = 1:length(ranks)
      rank_value = ranks(idx);
      if rank_value < 1
        rows(end + 1) = LOCAL_chart_row(labels{idx}, pcfg.label, ...
          rank_value, NaN, NaN, NaN, NaN, NaN, NaN(1, 6), false, ...
          'NONPOSITIVE_PROXY_RANK'); %#ok<AGROW>
        status = 'NONPOSITIVE_PROXY_RANK';
        return;
      end
      chart.label = labels{idx};
      chart.proxy_index = proxy_index;
      chart.rank = rank_value;
      chart.U = U(:, 1:rank_value);
      chart.V = V(:, 1:rank_value);
      chart.singular_values = singular_values;
      chart.anchor = anchor;
      chart.fingerprint = LOCAL_raw_fingerprint( ...
        [real(chart.U(:)); imag(chart.U(:)); ...
        real(chart.V(:)); imag(chart.V(:))]);
      [~, ~, ~, info] = LOCAL_precomp_proxy_anchored( ...
        pars1, pars2, gamma, chart, 'collocation');
      [~, off_A, off_b, off_info] = LOCAL_precomp_proxy_anchored( ...
        pars1, pars2, gamma, [], 'shifted');
      coeffs = info.proxy_coefficients;
      off_residual = norm(off_A * coeffs - off_b, 2) / ...
        max(1, norm(off_b, 2));
      off_block_residuals = NaN(1, 6);
      for block_index = 1:6
        block_rows = off_info.indices{block_index};
        off_block_residuals(block_index) = norm( ...
          off_A(block_rows, :) * coeffs - off_b(block_rows), 2) / ...
          max(1, norm(off_b(block_rows), 2));
      end
      if rank_value < length(singular_values)
        gap = singular_values(rank_value) / ...
          max(realmin, singular_values(rank_value + 1));
      else
        gap = Inf;
      end
      pass = info.available && ...
        singular_values(rank_value) / singular_values(1) >= cfg.rank_ratio && ...
        info.proxy_factor_rcond >= cfg.proxy_rcond_min && ...
        info.proxy_projected_residual <= cfg.proxy_projected_tol && ...
        info.proxy_projected_backward <= cfg.proxy_projected_tol && ...
        info.proxy_full_residual <= cfg.proxy_full_tol && ...
        off_residual <= cfg.proxy_full_tol && ...
        all(off_block_residuals <= cfg.proxy_full_tol) && ...
        isfinite(norm(coeffs));
      rows(end + 1) = LOCAL_chart_row(labels{idx}, pcfg.label, ...
        rank_value, singular_values(rank_value) / singular_values(1), ...
        gap, info.proxy_factor_rcond, info.proxy_projected_residual, ...
        max(info.proxy_full_residual, off_residual), ...
        off_block_residuals, pass, ...
        LOCAL_pass_status(pass)); %#ok<AGROW>
      port_anchor = LOCAL_branch_anchor(seed, cfg.M, cfg, 'real_axis_anchor');
      [anchor_ev, ~, ~] = LOCAL_evaluate_anchored(seed, ...
        cfg.locator_level, cfg, chart, port_anchor, 'real_axis_anchor');
      try
        if anchor_ev.available
          mismatch = LOCAL_real_axis_mismatch( ...
            seed, cfg.locator_level, cfg, chart, port_anchor, anchor_ev.F);
        else
          mismatch = struct('green', Inf, 'full_F', Inf, 'pass', false);
        end
      catch
        mismatch = struct('green', Inf, 'full_F', Inf, 'pass', false);
      end
      rows(end).anchor_green_mismatch = mismatch.green;
      rows(end).anchor_F_mismatch = mismatch.full_F;
      rows(end).real_axis_mismatch_pass = mismatch.pass;
      rows(end).pass = rows(end).pass && mismatch.pass;
      if ~rows(end).pass
        rows(end).status = 'REAL_AXIS_ANCHOR_MISMATCH';
      end
      charts(end + 1) = chart; %#ok<AGROW>
    end
  end
  status = 'PASS';
  if ~all([rows.pass])
    status = 'PROXY_CHART_GATE_FAILED';
  end
end

function row = LOCAL_chart_row(chart, proxy, rank_value, selected_ratio, ...
    gap, factor_rcond, projected, full_off, off_blocks, pass, status)
  row = struct('chart', chart, 'proxy', proxy, 'rank', rank_value, ...
    'selected_ratio', selected_ratio, 'gap', gap, ...
    'factor_rcond', factor_rcond, 'projected_residual', projected, ...
    'full_off_residual', full_off, 'off_block_residuals', off_blocks, ...
    'refined_k', NaN, 'locator_value', NaN, ...
    'anchor_green_mismatch', NaN, 'anchor_F_mismatch', NaN, ...
    'refinement_green_mismatch', NaN, 'refinement_F_mismatch', NaN, ...
    'real_axis_mismatch_pass', false, ...
    'overlap', NaN, 'participation', NaN, 'pass', pass, 'status', status);
end

%% ==================== Anchored physical evaluator ====================
% These helpers build the corrected scaled center and doubled bulk leads.

function [ev, factors, branch_rows] = LOCAL_evaluate_anchored( ...
    k, level, cfg, chart, disk_anchor, node_label)
  pcfg = cfg.proxy(chart.proxy_index);
  proxy_anchor = LOCAL_reanchor(disk_anchor, pcfg.M_pw, cfg, ...
    ['proxy_', pcfg.label]);
  port_anchor = LOCAL_reanchor(disk_anchor, cfg.M, cfg, 'port');
  proxy_gamma = LOCAL_branch_values(k, proxy_anchor);
  port_gamma = LOCAL_branch_values(k, port_anchor);
  pars1 = LOCAL_pars1(k, cfg);
  pars2 = LOCAL_pars2(pcfg);
  [representation_pass, representation_status, representation_error] = ...
    LOCAL_representation_checker(chart, chart);
  if ~representation_pass
    ev = LOCAL_unavailable_evaluation(representation_status);
    factors = LOCAL_factor_row(chart.label, node_label, k, level, ...
      'representation_chart', 1, representation_error, false, ...
      representation_status);
    branch_rows = LOCAL_empty_branch_rows();
    return;
  end
  [proxy, ~, ~, proxy_info] = LOCAL_precomp_proxy_anchored( ...
    pars1, pars2, proxy_gamma, chart, 'collocation');
  factors = LOCAL_factor_row(chart.label, node_label, k, level, ...
    'proxy_reduced_factor', proxy_info.proxy_factor_rcond, ...
    max(proxy_info.proxy_projected_residual, ...
    proxy_info.proxy_projected_backward), proxy_info.available, ...
    proxy_info.failure_reason);
  factors(end + 1) = LOCAL_factor_row(chart.label, node_label, k, level, ...
    'representation_chart', 1, representation_error, true, ...
    representation_status);
  if ~proxy_info.available
    ev = LOCAL_unavailable_evaluation(proxy_info.failure_reason);
    branch_rows = [LOCAL_branch_audit(k, port_anchor, cfg, 'port'), ...
      LOCAL_branch_audit(k, proxy_anchor, cfg, 'proxy')];
    return;
  end
  [~, off_A, off_b, ~] = LOCAL_precomp_proxy_anchored( ...
    pars1, pars2, proxy_gamma, [], 'shifted');
  off_residual = norm(off_A * proxy_info.proxy_coefficients - off_b, 2) / ...
    max(1, norm(off_b, 2));
  factors(end + 1) = LOCAL_factor_row(chart.label, node_label, k, level, ...
    'proxy_full_off_residual', proxy_info.proxy_factor_rcond, ...
    max(proxy_info.proxy_full_residual, off_residual), ...
    isfinite(off_residual), LOCAL_pass_status(isfinite(off_residual)));
  channels = LOCAL_anchored_rayleigh_channels( ...
    k, cfg.beta, cfg.d, cfg.M, cfg.L, port_gamma, ...
    disk_anchor.fingerprint);
  [center, center_factor] = LOCAL_build_object( ...
    k, cfg.defect_axes, pars1, proxy, proxy_gamma, channels, cfg, true);
  [bulk, bulk_factor] = LOCAL_build_object( ...
    k, cfg.bulk_axes, pars1, proxy, proxy_gamma, channels, cfg, true);
  factors = [factors, LOCAL_relabel_factors(center_factor, ...
    chart.label, node_label, k, level), ...
    LOCAL_relabel_factors(bulk_factor, chart.label, node_label, k, level)];
  lead = LOCAL_scattering_from_center(bulk);
  for step = 1:level
    [lead, double_factors] = LOCAL_star(lead, lead);
    factors = [factors, LOCAL_relabel_factors(double_factors, ...
      chart.label, node_label, k, level)]; %#ok<AGROW>
  end
  [F, assembly_factors] = LOCAL_assemble_and_factors(center, lead, lead, cfg);
  factors = [factors, LOCAL_relabel_factors(assembly_factors, ...
    chart.label, node_label, k, level)];
  ev = LOCAL_augmented_metrics(F, cfg);
  ev.available = ev.available && LOCAL_factor_gate(factors, cfg);
  if ~ev.available
    ev.reason = 'FACTOR_UNAVAILABLE';
  end
  ev.proxy_info = proxy_info;
  branch_rows = [LOCAL_branch_audit(k, port_anchor, cfg, 'port'), ...
    LOCAL_branch_audit(k, proxy_anchor, cfg, 'proxy')];
end

function anchor = LOCAL_reanchor(disk_anchor, M, cfg, label)
  anchor = LOCAL_branch_anchor(disk_anchor.kc, M, cfg, label);
end

function [pass, status, projector_error] = ...
    LOCAL_representation_checker(expected, observed)
  required = {'rank', 'U', 'V', 'fingerprint', 'label', 'proxy_index'};
  pass = all(isfield(expected, required)) && all(isfield(observed, required));
  projector_error = Inf;
  if pass
    dimensions_equal = isequal(size(expected.U), size(observed.U)) && ...
      isequal(size(expected.V), size(observed.V));
    if dimensions_equal
      projector_error = max( ...
        LOCAL_relmat(expected.U * expected.U', observed.U * observed.U'), ...
        LOCAL_relmat(expected.V * expected.V', observed.V * observed.V'));
    end
    observed_fingerprint = LOCAL_raw_fingerprint( ...
      [real(observed.U(:)); imag(observed.U(:)); ...
      real(observed.V(:)); imag(observed.V(:))]);
    pass = dimensions_equal && expected.rank == observed.rank && ...
      strcmp(expected.label, observed.label) && ...
      expected.proxy_index == observed.proxy_index && ...
      strcmp(expected.fingerprint, observed_fingerprint) && ...
      projector_error <= 1e-13;
  end
  status = LOCAL_cond_status(pass, 'REPRESENTATION_ACCEPTED', ...
    'REPRESENTATION_DRIFT');
end

function mismatch = LOCAL_real_axis_mismatch( ...
    k, level, cfg, chart, branch_anchor, anchored_F)
  if imag(k) ~= 0
    error('analytic_readiness:PackageComplexCallForbidden', ...
      'Package comparison is permitted on the real axis only.');
  end
  [pointwise_ev, ~] = LOCAL_evaluate_pointwise( ...
    k, level, cfg, chart.proxy_index);
  pcfg = cfg.proxy(chart.proxy_index);
  pars1 = LOCAL_pars1(k, cfg);
  pars2 = LOCAL_pars2(pcfg);
  package_proxy = kernel.precomp_proxy(pars1, pars2);
  proxy_anchor = LOCAL_branch_anchor( ...
    branch_anchor.kc, pcfg.M_pw, cfg, 'real_axis_proxy');
  proxy_gamma = LOCAL_branch_values(k, proxy_anchor);
  [anchored_proxy, ~, ~, proxy_info] = LOCAL_precomp_proxy_anchored( ...
    pars1, pars2, proxy_gamma, chart, 'collocation');
  src = [0.07, -0.13; 0.11, -0.09];
  trg = [2.2, -2.1; 0.17, -0.21];
  package_green = LOCAL_green_stack( ...
    src, trg, pars1, package_proxy, [], false);
  anchored_green = LOCAL_green_stack( ...
    src, trg, pars1, anchored_proxy, proxy_gamma, true);
  mismatch.green = LOCAL_relmat(package_green, anchored_green);
  mismatch.full_F = LOCAL_relmat(pointwise_ev.F, anchored_F);
  mismatch.pass = pointwise_ev.available && proxy_info.available && ...
    mismatch.green <= cfg.real_axis_mismatch_tol && ...
    mismatch.full_F <= cfg.real_axis_mismatch_tol;
end

function values = LOCAL_green_stack(src, trg, pars1, proxy, gamma, anchored)
  if anchored
    [a, b, c, d, e, f] = LOCAL_qpgreen_mfs_pairmat_anchored( ...
      src, trg, pars1, proxy, gamma);
  else
    [a, b, c, d, e, f] = kernel.qpgreen_mfs_pairmat( ...
      src, trg, pars1, proxy);
  end
  values = [a(:); b(:); c(:); d(:); e(:); f(:)];
end

function [object, factors] = LOCAL_build_object( ...
    k, axes_value, pars1, proxy, proxy_gamma, channels, cfg, anchored)
  if ischar(axes_value) && strcmp(axes_value, 'circle')
    [geom_data, curvelen] = geom.construct_cont( ...
      cfg.ntot, 'circle', 0, 0, cfg.bulk_axes(1));
    name = 'circle_bulk_BIE';
  else
    [geom_data, curvelen] = geom.construct_cont( ...
      cfg.ntot, 'ellipse', 0, 0, axes_value);
    name = 'defect_BIE';
    if axes_value(1) == cfg.bulk_axes(1)
      name = 'bulk_BIE';
    end
  end
  if anchored
    A = full(complex(LOCAL_construct_A_QP_anchored( ...
      geom_data, k, cfg.nref * k, pars1, proxy, proxy_gamma, curvelen)));
  else
    A = full(complex(op.construct_A_QP( ...
      geom_data, k, cfg.nref * k, pars1, proxy, curvelen)));
  end
  [B_L_physical, B_R_physical] = bloch.incident_rhs( ...
    geom_data, channels, cfg.walls(1), cfg.walls(2));
  [E_L_physical, E_R_physical] = bloch.farfield_extractors( ...
    geom_data, channels, cfg.walls(1), cfg.walls(2), curvelen);
  h = curvelen / size(geom_data, 2);
  speed = sqrt(geom_data(2, :).^2 + geom_data(5, :).^2);
  density_scale = sqrt(h * [speed, speed]).';
  B_L = bsxfun(@times, B_L_physical, density_scale);
  B_R = bsxfun(@times, B_R_physical, density_scale);
  E_L = bsxfun(@rdivide, E_L_physical, density_scale.');
  E_R = bsxfun(@rdivide, E_R_physical, density_scale.');
  rhs = -[B_L, B_R];
  factor_rcond = rcond(A);
  if isfinite(factor_rcond) && factor_rcond > 0
    H = A \ rhs;
    residual = LOCAL_relres(A, H, rhs);
    available = all(isfinite(H(:)));
  else
    H = NaN(size(rhs));
    residual = Inf;
    available = false;
  end
  phase = diag(channels.phase(:));
  J = [zeros(cfg.p), phase; phase, zeros(cfg.p)];
  S = J + [E_L; E_R] * H;
  object.A_c = A;
  object.B_L = B_L;
  object.B_R = B_R;
  object.E_L = E_L;
  object.E_R = E_R;
  object.J_LL = zeros(cfg.p);
  object.J_LR = phase;
  object.J_RL = phase;
  object.J_RR = zeros(cfg.p);
  object.S = S;
  object.H = H;
  object.density_scale = density_scale;
  object.D_fingerprint = LOCAL_raw_fingerprint(density_scale);
  object.scaling_B_error = LOCAL_relmat(B_L, ...
    bsxfun(@times, B_L_physical, density_scale));
  object.scaling_E_error = LOCAL_relmat(E_L, ...
    bsxfun(@rdivide, E_L_physical, density_scale.'));
  factors = LOCAL_factor_row('', '', k, -1, name, ...
    factor_rcond, residual, available, LOCAL_pass_status(available));
end

function lead = LOCAL_scattering_from_center(object)
  S = object.S;
  p = size(S, 1) / 2;
  lead.R_L = S(1:p, 1:p);
  lead.T_RL = S(1:p, p + 1:end);
  lead.T_LR = S(p + 1:end, 1:p);
  lead.R_R = S(p + 1:end, p + 1:end);
end

function [AB, factors] = LOCAL_star(A, B)
  p = size(A.R_L, 1);
  I = eye(p);
  G_A = I - A.R_R * B.R_L;
  G_B = I - B.R_L * A.R_R;
  rcond_A = rcond(G_A);
  rcond_B = rcond(G_B);
  if rcond_A > 0 && rcond_B > 0
    X_LR = G_A \ A.T_LR;
    X_RR = G_A \ (A.R_R * B.T_RL);
    X_RL = G_B \ B.T_RL;
    AB.R_L = A.R_L + A.T_RL * B.R_L * X_LR;
    AB.T_LR = B.T_LR * X_LR;
    AB.T_RL = A.T_RL * X_RL;
    AB.R_R = B.R_R + B.T_LR * X_RR;
    residual_A = max(LOCAL_relres(G_A, X_LR, A.T_LR), ...
      LOCAL_relres(G_A, X_RR, A.R_R * B.T_RL));
    residual_B = LOCAL_relres(G_B, X_RL, B.T_RL);
  else
    AB.R_L = NaN(p);
    AB.T_LR = NaN(p);
    AB.T_RL = NaN(p);
    AB.R_R = NaN(p);
    residual_A = Inf;
    residual_B = Inf;
  end
  factors = [LOCAL_factor_row('', '', NaN, -1, 'doubling_G_A', ...
    rcond_A, residual_A, isfinite(rcond_A), LOCAL_pass_status(isfinite(rcond_A))), ...
    LOCAL_factor_row('', '', NaN, -1, 'doubling_G_B', ...
    rcond_B, residual_B, isfinite(rcond_B), LOCAL_pass_status(isfinite(rcond_B)))];
end

function [F, factors] = LOCAL_assemble_and_factors(center, minus, plus, cfg)
  n = size(center.A_c, 1);
  p = cfg.p;
  layout = LOCAL_layout(n, p);
  F = zeros(layout.total);
  c = layout.col;
  r = layout.row;
  I = eye(p);
  F(r.g1, c.xi) = center.A_c;
  F(r.g1, c.ac_minus) = center.B_L;
  F(r.g1, c.bc_plus) = center.B_R;
  F(r.g2, c.xi) = -center.E_L;
  F(r.g2, c.ac_minus) = -center.J_LL;
  F(r.g2, c.bc_plus) = -center.J_LR;
  F(r.g2, c.bc_minus) = I;
  F(r.g3, c.xi) = -center.E_R;
  F(r.g3, c.ac_minus) = -center.J_RL;
  F(r.g3, c.bc_plus) = -center.J_RR;
  F(r.g3, c.ac_plus) = I;
  F(r.g4, c.bc_minus) = -minus.T_RL;
  F(r.g4, c.af_minus) = -minus.R_L;
  F(r.g4, c.bf_minus) = I;
  F(r.g5, c.ac_minus) = I;
  F(r.g5, c.bc_minus) = -minus.R_R;
  F(r.g5, c.af_minus) = -minus.T_LR;
  F(r.g6, c.af_minus) = I;
  F(r.g6, c.bf_minus) = I;
  F(r.g7, c.bc_plus) = I;
  F(r.g7, c.ac_plus) = -plus.R_L;
  F(r.g7, c.bf_plus) = -plus.T_RL;
  F(r.g8, c.ac_plus) = -plus.T_LR;
  F(r.g8, c.bf_plus) = -plus.R_R;
  F(r.g8, c.af_plus) = I;
  F(r.g9, c.bf_plus) = I;
  F(r.g9, c.af_plus) = I;
  terminal_minus = eye(p) + minus.R_L;
  terminal_plus = eye(p) + plus.R_R;
  retained_cols = [c.ac_minus, c.bc_plus];
  retained_rows = [r.g5, r.g7];
  eliminated_cols = setdiff(1:layout.total, retained_cols, 'stable');
  eliminated_rows = setdiff(1:layout.total, retained_rows, 'stable');
  K_ee = F(eliminated_rows, eliminated_cols);
  K_er = F(eliminated_rows, retained_cols);
  if rcond(K_ee) > 0
    response = K_ee \ K_er;
    kee_residual = LOCAL_relres(K_ee, response, K_er);
  else
    kee_residual = Inf;
  end
  factors = [ ...
    LOCAL_factor_row('', '', NaN, -1, 'far_minus', ...
      rcond([-minus.R_L, eye(p); eye(p), eye(p)]), 0, true, 'COMPUTED'), ...
    LOCAL_factor_row('', '', NaN, -1, 'far_plus', ...
      rcond([-plus.R_R, eye(p); eye(p), eye(p)]), 0, true, 'COMPUTED'), ...
    LOCAL_factor_row('', '', NaN, -1, 'terminal_minus', ...
      rcond(terminal_minus), 0, true, 'COMPUTED'), ...
    LOCAL_factor_row('', '', NaN, -1, 'terminal_plus', ...
      rcond(terminal_plus), 0, true, 'COMPUTED'), ...
    LOCAL_factor_row('', '', NaN, -1, 'K_ee', ...
      rcond(K_ee), kee_residual, isfinite(kee_residual), ...
      LOCAL_pass_status(isfinite(kee_residual)))];
end

function layout = LOCAL_layout(n, p)
  layout.total = n + 8 * p;
  layout.col.xi = 1:n;
  names = {'ac_minus', 'bc_plus', 'bc_minus', 'ac_plus', ...
    'af_minus', 'bf_minus', 'bf_plus', 'af_plus'};
  for idx = 1:8
    layout.col.(names{idx}) = n + (idx - 1) * p + (1:p);
  end
  layout.row.g1 = 1:n;
  for idx = 2:9
    layout.row.(['g', num2str(idx)]) = n + (idx - 2) * p + (1:p);
  end
end

function ev = LOCAL_augmented_metrics(F, cfg)
  [~, S, V] = svd(F, 'econ');
  singular_values = diag(S);
  direction = V(:, end);
  n = size(F, 1) - 8 * cfg.p;
  ev.available = all(isfinite(F(:)));
  ev.reason = LOCAL_pass_status(ev.available);
  ev.F = F;
  ev.sigma_min = singular_values(end);
  ev.norm_F = singular_values(1);
  ev.s = ev.sigma_min / max(1, ev.norm_F);
  ev.direction = direction;
  ev.participation = norm(direction(1:n), 2) / max(realmin, norm(direction, 2));
  ev.residual = norm(F * direction, 2) / max(1, norm(F, 2));
end

function ev = LOCAL_unavailable_evaluation(reason)
  ev.available = false;
  ev.reason = reason;
  ev.F = [];
  ev.sigma_min = NaN;
  ev.norm_F = NaN;
  ev.s = NaN;
  ev.direction = [];
  ev.participation = NaN;
  ev.residual = NaN;
  ev.proxy_info = struct();
end

function rows = LOCAL_relabel_factors(rows, chart, node, k, level)
  for idx = 1:length(rows)
    rows(idx).chart = chart;
    rows(idx).node = node;
    rows(idx).k_real = real(k);
    rows(idx).k_imag = imag(k);
    rows(idx).level = level;
  end
end

%% ==================== Locator refinement ====================
% Each chart uses two fixed nine-point grids with no rank reselection.

function [rows, charts, candidate, status] = ...
    LOCAL_refine_charts(cfg, rows, charts, seed)
  coarse_step = diff(cfg.scan) / (cfg.scan_points - 1);
  for chart_index = 1:length(charts)
    chart = charts(chart_index);
    left = seed - coarse_step;
    right = seed + coarse_step;
    previous_direction = [];
    first_position = NaN;
    final_step = NaN;
    final_position = NaN;
    final_overlap = NaN;
    final_participation = NaN;
    refinement_green_mismatch = 0;
    refinement_F_mismatch = 0;
    for iteration = 1:2
      grid = linspace(left, right, 9);
      grid_values = NaN(1, 9);
      grid_ev = cell(1, 9);
      anchor = LOCAL_branch_anchor(seed, cfg.M, cfg, 'refinement');
      for idx = 1:9
        try
          [ev, ~, ~] = LOCAL_evaluate_anchored( ...
            grid(idx), cfg.locator_level, cfg, chart, anchor, ...
            sprintf('refine_%d_%d', iteration, idx));
        catch exception
          ev = LOCAL_unavailable_evaluation(LOCAL_exception_reason(exception));
        end
        grid_ev{idx} = ev;
        grid_values(idx) = ev.s;
        if ev.available
          try
            mismatch = LOCAL_real_axis_mismatch(grid(idx), ...
              cfg.locator_level, cfg, chart, anchor, ev.F);
            refinement_green_mismatch = max( ...
              refinement_green_mismatch, mismatch.green);
            refinement_F_mismatch = max( ...
              refinement_F_mismatch, mismatch.full_F);
          catch
            refinement_green_mismatch = Inf;
            refinement_F_mismatch = Inf;
          end
        else
          refinement_green_mismatch = Inf;
          refinement_F_mismatch = Inf;
        end
      end
      if any(~cellfun(@(x) x.available, grid_ev))
        candidate = NaN;
        status = 'REFINEMENT_NODE_UNAVAILABLE';
        return;
      end
      [~, selected] = min(grid_values);
      if selected == 1 || selected == 9 || ...
          ~(grid_values(selected) < grid_values(selected - 1) && ...
          grid_values(selected) < grid_values(selected + 1))
        candidate = NaN;
        status = 'REFINEMENT_NOT_STRICT_INTERIOR';
        return;
      end
      direction = grid_ev{selected}.direction;
      if isempty(previous_direction)
        overlap = 1;
        first_position = grid(selected);
      else
        overlap = abs(previous_direction' * direction) / ...
          max(realmin, norm(previous_direction) * norm(direction));
      end
      previous_direction = direction;
      final_overlap = overlap;
      final_participation = grid_ev{selected}.participation;
      final_position = grid(selected);
      final_step = grid(2) - grid(1);
      left = grid(selected - 1);
      right = grid(selected + 1);
    end
    row_index = find(strcmp({rows.chart}, chart.label), 1);
    rows(row_index).refined_k = final_position;
    rows(row_index).overlap = final_overlap;
    rows(row_index).participation = final_participation;
    rows(row_index).refinement_green_mismatch = refinement_green_mismatch;
    rows(row_index).refinement_F_mismatch = refinement_F_mismatch;
    rows(row_index).real_axis_mismatch_pass = ...
      rows(row_index).real_axis_mismatch_pass && ...
      refinement_green_mismatch <= cfg.real_axis_mismatch_tol && ...
      refinement_F_mismatch <= cfg.real_axis_mismatch_tol;
    refinement_pass = abs(first_position - final_position) <= ...
      2 * final_step && final_overlap >= cfg.refinement_overlap_min && ...
      final_participation >= cfg.participation_min && ...
      rows(row_index).real_axis_mismatch_pass;
    rows(row_index).pass = rows(row_index).pass && refinement_pass;
    if ~refinement_pass
      rows(row_index).status = 'REFINEMENT_GATE_FAILED';
    end
    charts(chart_index).final_k = final_position;
    charts(chart_index).final_step = final_step;
    charts(chart_index).final_direction = previous_direction;
  end
  final_positions = [charts.final_k];
  base_index = find(strcmp({charts.label}, 'base_r'), 1);
  candidate = charts(base_index).final_k;
  base_step = charts(base_index).final_step;
  position_pass = max(abs(final_positions - candidate)) <= 2 * base_step;
  overlap_pass = true;
  for idx = 1:length(charts)
    overlap = abs(charts(idx).final_direction' * ...
      charts(base_index).final_direction) / max(realmin, ...
      norm(charts(idx).final_direction) * ...
      norm(charts(base_index).final_direction));
    overlap_pass = overlap_pass && overlap >= cfg.refinement_overlap_min;
  end
  common_values = NaN(1, length(charts));
  common_matrices = cell(1, length(charts));
  common_anchor = LOCAL_branch_anchor(seed, cfg.M, cfg, 'refinement');
  for idx = 1:length(charts)
    [ev, ~, ~] = LOCAL_evaluate_anchored(candidate, ...
      cfg.locator_level, cfg, charts(idx), common_anchor, ...
      'common_locator_spread');
    common_values(idx) = ev.s;
    common_matrices{idx} = ev.F;
    row_index = find(strcmp({rows.chart}, charts(idx).label), 1);
    rows(row_index).locator_value = ev.s;
  end
  if any(cellfun(@isempty, common_matrices)) || any(~isfinite(common_values))
    status = 'COMMON_LOCATOR_NODE_UNAVAILABLE';
    for idx = 1:length(rows)
      rows(idx).pass = false;
      rows(idx).status = status;
    end
    return;
  end
  locator_spread = 0;
  for left_index = 1:length(charts)
    for right_index = left_index + 1:length(charts)
      locator_spread = max(locator_spread, LOCAL_relmat( ...
        common_matrices{left_index}, common_matrices{right_index}));
    end
  end
  locator_spread_pass = locator_spread <= 0.1 * min(common_values);
  status = 'PASS';
  if ~all([rows.pass]) || ~position_pass || ~overlap_pass || ...
      ~locator_spread_pass
    status = 'CHART_SENSITIVITY_FAILED';
    for idx = 1:length(rows)
      rows(idx).pass = false;
      rows(idx).status = status;
    end
  end
end

%% ==================== Candidate disks ====================
% These helpers retain all permitted attempts and stop after the first pass.

function [results, status] = LOCAL_run_disks(results, cfg, charts, candidate)
  orders = unique([(-cfg.M:cfg.M), ...
    (-cfg.proxy(1).M_pw:cfg.proxy(1).M_pw), ...
    (-cfg.proxy(2).M_pw:cfg.proxy(2).M_pw)]);
  branch_points = [0, cfg.beta + 2 * pi * orders / cfg.d, ...
    -(cfg.beta + 2 * pi * orders / cfg.d)];
  branch_distance = min(abs(candidate - branch_points));
  base_index = find(strcmp({charts.label}, 'base_r'), 1);
  r0 = min(2 * charts(base_index).final_step, branch_distance / 4);
  status = 'ALL_DISK_ATTEMPTS_FAILED';
  for attempt = 1:3
    radius = r0 / 2 ^ (attempt - 1);
    fprintf('  disk attempt %d, radius %.17g\n', attempt, radius);
    [attempt_result, sampled, factors, branch_rows] = ...
      LOCAL_sample_attempt(cfg, charts, candidate, radius, attempt);
    results.disks(end + 1) = attempt_result; %#ok<AGROW>
    results.sampled = [results.sampled, sampled]; %#ok<AGROW>
    results.factors = [results.factors, factors]; %#ok<AGROW>
    results.branch_rows = [results.branch_rows, branch_rows]; %#ok<AGROW>
    if attempt_result.sample_pass
      [cr_rows, cr_pass] = LOCAL_run_cr( ...
        cfg, charts, candidate, radius, attempt);
      results.cr = [results.cr, cr_rows]; %#ok<AGROW>
      results.disks(end).cr_pass = cr_pass;
      results.disks(end).pass = attempt_result.sample_pass && cr_pass;
    else
      results.disks(end).cr_pass = false;
      results.disks(end).pass = false;
    end
    if results.disks(end).pass
      results.selected_disk = sprintf('attempt_%d', attempt);
      disk_anchor = LOCAL_branch_anchor(candidate, cfg.M, cfg, 'disk');
      results.branch_fingerprint = disk_anchor.fingerprint;
      results.projector_fingerprints = {charts.fingerprint};
      status = 'PASS';
      return;
    end
  end
end

function [disk, sampled, factors, branch_rows] = ...
    LOCAL_sample_attempt(cfg, charts, center, radius, attempt)
  sampled = LOCAL_empty_sampled();
  factors = LOCAL_empty_factors();
  branch_rows = LOCAL_empty_branch_rows();
  angles32 = 2 * pi * (0:31) / 32;
  boundary = center + radius * exp(1i * angles32);
  half = center + 0.5 * radius * exp(1i * 2 * pi * (0:7) / 8);
  nodes = [boundary, center, half];
  labels = [arrayfun(@(x) sprintf('boundary32_%02d', x), ...
    1:32, 'UniformOutput', false), {'center'}, ...
    arrayfun(@(x) sprintf('half_%02d', x), 1:8, 'UniformOutput', false)];
  all_available = true;
  factor_pass = true;
  branch_pass = true;
  n_levels = length(cfg.levels);
  boundary_min = Inf(length(charts), n_levels);
  boundary_min16 = Inf(length(charts), n_levels);
  boundary_values = NaN(length(charts), 32, n_levels);
  boundary_available = false(length(charts), 32, n_levels);
  boundary_matrices = cell(length(charts), 32, n_levels);
  disk_anchor = LOCAL_branch_anchor(center, cfg.M, cfg, 'disk');
  for chart_index = 1:length(charts)
    chart = charts(chart_index);
    for node_index = 1:length(nodes)
      for level_index = 1:n_levels
        level = cfg.levels(level_index);
        node_label = labels{node_index};
        try
          [ev, one_factors, one_branch] = LOCAL_evaluate_anchored( ...
            nodes(node_index), level, cfg, chart, disk_anchor, node_label);
        catch exception
          ev = LOCAL_unavailable_evaluation(LOCAL_exception_reason(exception));
          one_factors = LOCAL_factor_row(chart.label, node_label, ...
            nodes(node_index), level, 'evaluation_exception', 0, Inf, ...
            false, ev.reason);
          one_branch = LOCAL_empty_branch_rows();
        end
        one_factors = LOCAL_set_attempt(one_factors, attempt);
        one_branch = LOCAL_set_attempt(one_branch, attempt);
        factors = [factors, one_factors]; %#ok<AGROW>
        branch_rows = [branch_rows, one_branch]; %#ok<AGROW>
        factors_ok = LOCAL_factor_gate(one_factors, cfg);
        branches_ok = isempty(one_branch) || all([one_branch.pass]);
        sampled(end + 1) = struct('attempt', attempt, ...
          'chart', chart.label, 'node', node_label, 'level', level, ...
          'k_real', real(nodes(node_index)), ...
          'k_imag', imag(nodes(node_index)), 's', ev.s, ...
          'sigma_min', ev.sigma_min, 'participation', ev.participation, ...
          'available', ev.available && factors_ok && branches_ok, ...
          'status', ev.reason); %#ok<AGROW>
        all_available = all_available && ev.available;
        factor_pass = factor_pass && factors_ok;
        branch_pass = branch_pass && branches_ok;
        if node_index <= 32
          boundary_values(chart_index, node_index, level_index) = ev.s;
          boundary_available(chart_index, node_index, level_index) = ...
            ev.available && factors_ok && branches_ok;
          boundary_matrices{chart_index, node_index, level_index} = ev.F;
        end
      end
    end
    for level_index = 1:n_levels
      values_one = boundary_values(chart_index, :, level_index);
      boundary_min(chart_index, level_index) = min(values_one(:));
      boundary_min16(chart_index, level_index) = min(values_one(1:2:32));
    end
  end
  nested_ratio = abs(boundary_min16 - boundary_min) ./ ...
    max(realmin, boundary_min);
  nested_change = max(nested_ratio(:));
  separation_pass = all(boundary_min(:) >= cfg.aug_boundary_sep_min);
  nested_pass = nested_change <= cfg.nested_change_max;
  availability16 = squeeze(all(boundary_available(:, 1:2:32, :), 2));
  availability32 = squeeze(all(boundary_available, 2));
  availability_nested_pass = isequal(availability16, availability32);
  chart_separation_change = 0;
  for left_chart = 1:length(charts)
    for right_chart = left_chart + 1:length(charts)
      difference = abs(boundary_min(left_chart, :) - ...
        boundary_min(right_chart, :)) ./ max(realmin, max( ...
        abs(boundary_min(left_chart, :)), ...
        abs(boundary_min(right_chart, :))));
      chart_separation_change = max(chart_separation_change, max(difference));
    end
  end
  chart_separation_pass = chart_separation_change <= cfg.nested_change_max;
  if any(cellfun(@isempty, boundary_matrices(:)))
    chart_boundary_spread = Inf;
  else
    chart_boundary_spread = 0;
    for left_chart = 1:length(charts)
      for right_chart = left_chart + 1:length(charts)
        for node_index = 1:32
          for level_index = 1:n_levels
            chart_boundary_spread = max(chart_boundary_spread, LOCAL_relmat( ...
              boundary_matrices{left_chart, node_index, level_index}, ...
              boundary_matrices{right_chart, node_index, level_index}));
          end
        end
      end
    end
  end
  positive_sep = min(boundary_values(boundary_values > 0));
  if isempty(positive_sep)
    positive_sep = NaN;
  end
  chart_spread_pass = chart_boundary_spread <= 0.1 * positive_sep;
  disk = struct('attempt', attempt, 'center', center, 'radius', radius, ...
    'branch_distance', min(abs(center - [0, cfg.beta + ...
    2 * pi * (-cfg.proxy(2).M_pw:cfg.proxy(2).M_pw) / cfg.d, ...
    -(cfg.beta + 2 * pi * (-cfg.proxy(2).M_pw:cfg.proxy(2).M_pw) / cfg.d)])), ...
    'boundary_min', min(boundary_min(:)), ...
    'boundary_min_by_level', min(boundary_min, [], 1), ...
    'nested_change', nested_change, ...
    'availability16', availability16, ...
    'availability32', availability32, ...
    'chart_separation_change', chart_separation_change, ...
    'chart_boundary_spread', chart_boundary_spread, ...
    'sample_pass', all_available && factor_pass && branch_pass && ...
    separation_pass && nested_pass && availability_nested_pass && ...
    chart_separation_pass && ...
    chart_spread_pass, ...
    'cr_pass', false, 'pass', false, 'status', 'SAMPLED_ATTEMPT_FAILED');
  if disk.sample_pass
    disk.status = 'SAMPLED_DOMAIN_AVAILABLE';
  end
end

function pass = LOCAL_factor_gate(rows, cfg)
  pass = ~isempty(rows);
  for idx = 1:length(rows)
    row = rows(idx);
    if strcmp(row.name, 'proxy_reduced_factor')
      rcond_min = cfg.proxy_rcond_min;
      residual_max = cfg.proxy_projected_tol;
    elseif strcmp(row.name, 'proxy_full_off_residual')
      rcond_min = cfg.proxy_rcond_min;
      residual_max = cfg.proxy_full_tol;
    elseif strcmp(row.name, 'defect_BIE') || strcmp(row.name, 'bulk_BIE') || ...
        strcmp(row.name, 'circle_bulk_BIE')
      rcond_min = cfg.bie_rcond_min;
      residual_max = cfg.bie_residual_tol;
    else
      rcond_min = cfg.factor_rcond_min;
      residual_max = cfg.factor_residual_tol;
    end
    pass = pass && row.available && row.rcond >= rcond_min && ...
      row.residual <= residual_max;
  end
end

%% ==================== Full-matrix CR gate ====================
% The same full evaluator is differentiated in both complex directions.

function [rows, pass] = LOCAL_run_cr(cfg, charts, center, radius, attempt)
  rows = LOCAL_empty_cr();
  nodes = [center, center + 0.5 * radius * ...
    exp(1i * 2 * pi * (0:7) / 8)];
  disk_anchor = LOCAL_branch_anchor(center, cfg.M, cfg, 'disk');
  h0 = min(radius / 32, 1e-4 * max(1, abs(center)));
  pass = true;
  for chart_index = 1:length(charts)
    chart = charts(chart_index);
    for node_index = 1:length(nodes)
      for level = cfg.cr_levels
        eval_fun = @(z) LOCAL_cr_positive_eval( ...
          z, level, cfg, chart, disk_anchor, node_index);
        check = LOCAL_full_F_cr_checker(eval_fun, nodes(node_index), h0, cfg);
        rows(end + 1) = struct('attempt', attempt, ...
          'chart', chart.label, 'node_index', node_index, 'level', level, ...
          'h0', h0, 'cr_h0', check.cr(1), 'cr_h1', check.cr(2), ...
          'cr_h2', check.cr(3), 'spread_x', check.spread_x, ...
          'spread_y', check.spread_y, 'trend_pass', check.trend_pass, ...
          'pass', check.pass, 'status', check.status); %#ok<AGROW>
        pass = pass && check.pass;
      end
    end
  end
end

function [F, available] = LOCAL_cr_positive_eval( ...
    k, level, cfg, chart, disk_anchor, node_index)
  try
    [ev, ~, ~] = LOCAL_evaluate_anchored(k, level, cfg, chart, ...
      disk_anchor, sprintf('cr_%d', node_index));
    F = ev.F;
    available = ev.available && ~isempty(F);
  catch
    F = [];
    available = false;
  end
end

function check = LOCAL_full_F_cr_checker(eval_fun, k, h0, cfg)
  Dx = cell(1, 3);
  Dy = cell(1, 3);
  check.cr = NaN(1, 3);
  check.available = true;
  for h_index = 1:3
    h = h0 / 2 ^ (h_index - 1);
    shifts = [h, -h, 1i * h, -1i * h];
    matrices = cell(1, 4);
    for shift_index = 1:4
      [matrices{shift_index}, one_available] = ...
        eval_fun(k + shifts(shift_index));
      check.available = check.available && one_available;
    end
    if check.available
      Dx{h_index} = (matrices{1} - matrices{2}) / (2 * h);
      Dy{h_index} = (matrices{3} - matrices{4}) / (2i * h);
      check.cr(h_index) = norm(Dx{h_index} - Dy{h_index}, 'fro') / ...
        max([1, norm(Dx{h_index}, 'fro'), norm(Dy{h_index}, 'fro')]);
    end
  end
  if check.available
    check.spread_x = LOCAL_relmat(Dx{3}, Dx{2});
    check.spread_y = LOCAL_relmat(Dy{3}, Dy{2});
    x_floor = norm(Dx{3} - Dx{2}, 'fro') <= 100 * eps * ...
      max([1, norm(Dx{3}, 'fro'), norm(Dx{2}, 'fro')]);
    y_floor = norm(Dy{3} - Dy{2}, 'fro') <= 100 * eps * ...
      max([1, norm(Dy{3}, 'fro'), norm(Dy{2}, 'fro')]);
    rounding_floor = max(check.cr(2:3)) <= 100 * eps && ...
      check.spread_x <= 100 * eps && check.spread_y <= 100 * eps && ...
      x_floor && y_floor;
    check.trend_pass = check.cr(3) <= check.cr(2) || rounding_floor;
    check.pass = check.cr(3) <= cfg.cr_tol && ...
      check.spread_x <= cfg.cr_tol && check.spread_y <= cfg.cr_tol && ...
      check.trend_pass;
  else
    check.spread_x = NaN;
    check.spread_y = NaN;
    check.trend_pass = false;
    check.pass = false;
  end
  check.status = LOCAL_cond_status(check.pass, 'PASS', 'FULL_F_CR_DEFECT');
end

%% ==================== Mandatory falsification matrix ====================
% These controls use the same CR, fingerprint, rank, and availability rules.

function [rows, negative_raw] = ...
    LOCAL_run_negatives(results, cfg, upstream_status)
  rows = LOCAL_empty_negatives();
  negative_raw = struct();
  selected = find([results.disks.pass], 1);
  if isempty(selected)
    good_cr = 0;
  else
    selected_attempt = results.disks(selected).attempt;
    selected_cr = results.cr([results.cr.attempt] == selected_attempt);
    finite_cr = [selected_cr.cr_h2];
    finite_cr = finite_cr(isfinite(finite_cr));
    if isempty(finite_cr)
      good_cr = 0;
    else
      good_cr = max(finite_cr);
    end
  end
  cr_reject = max(1e-3, 100 * good_cr);

  pointwise = @(z) LOCAL_outgoing_sqrt(z.^2 - 0.8^2);
  n1_value = LOCAL_scalar_cr(pointwise, 1.0, 1e-6);
  rows(end + 1) = LOCAL_negative_row('N1', ...
    'POINTWISE_SQRT_CR_REJECTION', n1_value, cr_reject, ...
    n1_value > cr_reject, 'FULL_F_CR_DEFECT');

  adaptive = @(z) ([1; z]' * [0; 1]) / ([1; z]' * [1; z]);
  n2_value = LOCAL_scalar_cr(adaptive, 0.1 + 0.02i, 1e-6);
  rows(end + 1) = LOCAL_negative_row('N2', ...
    'ADAPTIVE_PINV_CR_REJECTION', n2_value, cr_reject, ...
    n2_value > cr_reject, 'FULL_F_CR_DEFECT');

  dependent_ids = {'N3', 'N4', 'N6', 'N7', 'N8', 'N9'};
  dependent_names = {'ADAPTIVE_RECOMPRESSION_REJECTED', ...
    'OUTER_GREEN_PRINCIPAL_ROOT_REJECTED', ...
    'FULL_240_ANTI_ANALYTIC_MUTATION_REJECTED', ...
    'FORCED_PROXY_FACTOR_POLE', 'HIDDEN_INTERIOR_POLE_DISCLOSED', ...
    'ZERO_FIELD_REPRESENTATION_DETECTED'};
  dependent = repmat(LOCAL_negative_row('', '', NaN, NaN, false, ...
    'NOT_RUN_UPSTREAM_STOP'), 1, length(dependent_ids));
  for idx = 1:length(dependent)
    dependent(idx).id = dependent_ids{idx};
    dependent(idx).name = dependent_names{idx};
  end
  if strcmp(upstream_status, 'PASS')
    try
      context = LOCAL_selected_context(results, cfg);
    catch exception
      context = [];
      for idx = 1:length(dependent)
        dependent(idx).status = ['FIXTURE_EXCEPTION:', ...
          LOCAL_exception_reason(exception)];
      end
    end
    if ~isempty(context)
      fixture_functions = { ...
        @() LOCAL_negative_N3(context, cfg), ...
        @() LOCAL_negative_N4(context, cfg, cr_reject), ...
        @() LOCAL_negative_N6(context, cfg, cr_reject), ...
        @() LOCAL_negative_N7(context, cfg), ...
        @() LOCAL_negative_N8(results, context, cfg)};
      for idx = 1:length(fixture_functions)
        try
          dependent(idx) = fixture_functions{idx}();
        catch exception
          dependent(idx).status = ['FIXTURE_EXCEPTION:', ...
            LOCAL_exception_reason(exception)];
        end
      end
      try
        [dependent(6), negative_raw.N9] = LOCAL_negative_N9(context, cfg);
      catch exception
        dependent(6).status = ['FIXTURE_EXCEPTION:', ...
          LOCAL_exception_reason(exception)];
      end
    end
  end
  rows(end + 1) = dependent(1);
  rows(end + 1) = dependent(2);

  seed_anchor = LOCAL_branch_anchor(0.1, cfg.M, cfg, 'fingerprint_fixture');
  mutated = seed_anchor.gamma_seed;
  mutated(1) = -mutated(1);
  mutated_fingerprint = LOCAL_raw_fingerprint([real(seed_anchor.orders(:)); ...
    real(mutated(:)); imag(mutated(:))]);
  n5_detected = ~strcmp(seed_anchor.fingerprint, mutated_fingerprint);
  rows(end + 1) = LOCAL_negative_row('N5', ...
    'FLIPPED_GAMMA_FINGERPRINT_REJECTED', double(n5_detected), 1, ...
    n5_detected, 'BRANCH_FINGERPRINT_MISMATCH');

  rows(end + 1) = dependent(3);
  rows(end + 1) = dependent(4);
  rows(end + 1) = dependent(5);
  rows(end + 1) = dependent(6);

  sweep = [10 * cfg.factor_rcond_min, ...
    cfg.factor_rcond_min, 0.1 * cfg.factor_rcond_min];
  availability = sweep >= cfg.factor_rcond_min;
  n10_detected = isequal(availability, [true, true, false]);
  rows(end + 1) = LOCAL_negative_row('N10', ...
    'RCOND_AVAILABILITY_TRANSITION', double(n10_detected), 1, ...
    n10_detected, 'DETERMINISTIC_AVAILABILITY_TRANSITION');

  if strcmp(upstream_status, 'PASS')
    try
      n11_detected = LOCAL_circle_smoke(results, cfg);
      n11_status = LOCAL_cond_status(n11_detected, ...
        'CIRCLE_LEAD_INTERFACE_SMOKE', 'CIRCLE_SMOKE_FAILED');
    catch
      n11_detected = false;
      n11_status = 'CIRCLE_SMOKE_EXCEPTION';
    end
  else
    n11_detected = false;
    n11_status = 'NOT_RUN_UPSTREAM_STOP';
  end
  rows(end + 1) = LOCAL_negative_row('N11', ...
    'CIRCLE_BULK_TARGET_GO_FORBIDDEN', double(n11_detected), 1, ...
    n11_detected, n11_status);
end

function context = LOCAL_selected_context(results, cfg)
  selected = find([results.disks.pass], 1);
  base_index = find(strcmp({results.proxy_charts.label}, 'base_r'), 1);
  if isempty(selected) || isempty(base_index)
    error('analytic_readiness:MissingSelectedFixture', ...
      'Negative fixtures require one selected disk and base_r chart.');
  end
  context.chart = results.proxy_charts(base_index);
  context.attempt = results.disks(selected).attempt;
  context.kc = results.disks(selected).center;
  context.radius = results.disks(selected).radius;
  context.anchor = LOCAL_branch_anchor(context.kc, cfg.M, cfg, ...
    'negative_fixture');
end

function row = LOCAL_negative_N3(context, cfg)
  k = context.kc + 0.5 * context.radius * exp(1i * 2 * pi * 2 / 8);
  chart = context.chart;
  pcfg = cfg.proxy(chart.proxy_index);
  proxy_anchor = LOCAL_branch_anchor(context.kc, pcfg.M_pw, cfg, ...
    'N3_proxy');
  pars1 = LOCAL_pars1(k, cfg);
  pars2 = LOCAL_pars2(pcfg);
  gamma = LOCAL_branch_values(k, proxy_anchor);
  [~, A, ~, ~] = LOCAL_precomp_proxy_anchored( ...
    pars1, pars2, gamma, [], 'collocation');
  [U_now, S_now, V_now] = svd(A, 'econ');
  singular_values = diag(S_now);
  rank_now = sum(singular_values / singular_values(1) >= cfg.rank_ratio);
  observed = chart;
  observed.rank = rank_now;
  observed.U = U_now(:, 1:rank_now);
  observed.V = V_now(:, 1:rank_now);
  observed.fingerprint = LOCAL_raw_fingerprint( ...
    [real(observed.U(:)); imag(observed.U(:)); ...
    real(observed.V(:)); imag(observed.V(:))]);
  [accepted, status, projector_difference] = ...
    LOCAL_representation_checker(chart, observed);
  pass = ~accepted && strcmp(status, 'REPRESENTATION_DRIFT');
  row = LOCAL_negative_row('N3', 'ADAPTIVE_RECOMPRESSION_REJECTED', ...
    projector_difference, 0, pass, status);
  row.fixture_k_real = real(k);
  row.fixture_k_imag = imag(k);
  row.projector_difference = projector_difference;
  row.projector_left_hash = LOCAL_raw_fingerprint( ...
    [real(observed.U * observed.U'); imag(observed.U * observed.U')]);
  row.projector_right_hash = LOCAL_raw_fingerprint( ...
    [real(observed.V * observed.V'); imag(observed.V * observed.V')]);
  row.downstream_available = accepted;
  row.checker = 'LOCAL_representation_checker';
end

function row = LOCAL_negative_N4(context, cfg, threshold)
  k_mu = 0.25;
  fixture_anchor = LOCAL_branch_anchor(k_mu, cfg.M, cfg, 'N4_propagating');
  pcfg = cfg.proxy(context.chart.proxy_index);
  proxy_anchor = LOCAL_branch_anchor(k_mu, pcfg.M_pw, cfg, 'N4_proxy_seed');
  pars1 = LOCAL_pars1(k_mu, cfg);
  pars2 = LOCAL_pars2(pcfg);
  gamma = LOCAL_branch_values(k_mu, proxy_anchor);
  [~, A_seed, ~, ~] = LOCAL_precomp_proxy_anchored( ...
    pars1, pars2, gamma, [], 'collocation');
  [U_seed, S_seed, V_seed] = svd(A_seed, 'econ');
  singular_values = diag(S_seed);
  fixture_rank = sum(singular_values / singular_values(1) >= cfg.rank_ratio);
  fixture_chart = context.chart;
  fixture_chart.rank = fixture_rank;
  fixture_chart.U = U_seed(:, 1:fixture_rank);
  fixture_chart.V = V_seed(:, 1:fixture_rank);
  fixture_chart.fingerprint = LOCAL_raw_fingerprint( ...
    [real(fixture_chart.U(:)); imag(fixture_chart.U(:)); ...
    real(fixture_chart.V(:)); imag(fixture_chart.V(:))]);
  h0 = 1e-4;
  good_fun = @(z) LOCAL_offbox_green_eval( ...
    z, cfg, fixture_chart, fixture_anchor, false);
  bad_fun = @(z) LOCAL_offbox_green_eval( ...
    z, cfg, fixture_chart, fixture_anchor, true);
  good = LOCAL_full_F_cr_checker(good_fun, k_mu, h0, cfg);
  bad = LOCAL_full_F_cr_checker(bad_fun, k_mu, h0, cfg);
  pass = good.pass && bad.available && bad.cr(3) > threshold;
  row = LOCAL_negative_row('N4', ...
    'OUTER_GREEN_PRINCIPAL_ROOT_REJECTED', bad.cr(3), threshold, ...
    pass, LOCAL_cond_status(pass, 'OUTER_GREEN_BRANCH_CR_DEFECT', ...
    'OUTER_GREEN_MUTATION_NOT_REJECTED'));
  row.fixture_k_real = k_mu;
  row.fixture_k_imag = 0;
  row.checker = [ ...
    'LOCAL_full_F_cr_checker:OFF_BOX_SIX_COMPONENTS:beta_m=-0.2'];
end

function [values, available] = LOCAL_offbox_green_eval( ...
    k, cfg, chart, anchor, mutated)
  pcfg = cfg.proxy(chart.proxy_index);
  proxy_anchor = LOCAL_branch_anchor(anchor.kc, pcfg.M_pw, cfg, 'N4_proxy');
  pars1 = LOCAL_pars1(k, cfg);
  pars2 = LOCAL_pars2(pcfg);
  gamma = LOCAL_branch_values(k, proxy_anchor);
  [proxy, ~, ~, info] = LOCAL_precomp_proxy_anchored( ...
    pars1, pars2, gamma, chart, 'collocation');
  src = [0.07, -0.13; 0.11, -0.09];
  trg = [2.2, -2.1; 0.17, -0.21];
  values = LOCAL_green_stack(src, trg, pars1, proxy, gamma, ~mutated);
  available = info.available && all(isfinite(values));
end

function row = LOCAL_negative_N6(context, cfg, threshold)
  h0 = min(context.radius / 32, 1e-4 * max(1, abs(context.kc)));
  bad_fun = @(z) LOCAL_anti_analytic_F_eval(z, cfg, context);
  bad = LOCAL_full_F_cr_checker(bad_fun, context.kc, h0, cfg);
  [F_center, center_available] = LOCAL_positive_F_eval( ...
    context.kc, 0, cfg, context);
  dimension_ok = center_available && isequal(size(F_center), [240, 240]);
  pass = dimension_ok && bad.available && bad.cr(3) > threshold;
  row = LOCAL_negative_row('N6', ...
    'FULL_240_ANTI_ANALYTIC_MUTATION_REJECTED', bad.cr(3), threshold, ...
    pass, LOCAL_cond_status(pass, 'FULL_F_CR_DEFECT', ...
    'FULL_F_MUTATION_NOT_REJECTED'));
  row.fixture_k_real = real(context.kc);
  row.fixture_k_imag = imag(context.kc);
  row.fixture_dimension = size(F_center, 1);
  row.raw_F_fingerprint = LOCAL_matrix_fingerprint(F_center);
  row.raw_F_preserved = true;
  row.checker = 'LOCAL_full_F_cr_checker:ACTUAL_240_F';
end

function [F, available] = LOCAL_anti_analytic_F_eval(k, cfg, context)
  [F, available] = LOCAL_positive_F_eval(k, 0, cfg, context);
  if available && isequal(size(F), [240, 240])
    F(1, 1) = F(1, 1) + 1e3 * conj(k);
  else
    available = false;
  end
end

function row = LOCAL_negative_N7(context, cfg)
  chart = context.chart;
  pcfg = cfg.proxy(chart.proxy_index);
  proxy_anchor = LOCAL_branch_anchor(context.kc, pcfg.M_pw, cfg, 'N7_proxy');
  pars1 = LOCAL_pars1(context.kc, cfg);
  pars2 = LOCAL_pars2(pcfg);
  gamma = LOCAL_branch_values(context.kc, proxy_anchor);
  [~, A, ~, ~] = LOCAL_precomp_proxy_anchored( ...
    pars1, pars2, gamma, [], 'collocation');
  U = chart.U(:, 1:chart.rank);
  V = chart.V(:, 1:chart.rank);
  G = U' * A * V;
  e_q = zeros(chart.rank, 1);
  e_q(end) = 1;
  A_bad = A - U * (G * e_q) * e_q' * V';
  G_bad = U' * A_bad * V;
  factor_rcond = rcond(G_bad);
  downstream_available = factor_rcond >= cfg.proxy_rcond_min;
  pass = ~downstream_available && factor_rcond < cfg.proxy_rcond_min;
  row = LOCAL_negative_row('N7', 'FORCED_PROXY_FACTOR_POLE', ...
    factor_rcond, cfg.proxy_rcond_min, pass, ...
    LOCAL_cond_status(pass, 'PROXY_COMPRESSION_POLE', ...
    'SINGULAR_FACTOR_NOT_REJECTED'));
  row.fixture_k_real = real(context.kc);
  row.fixture_k_imag = imag(context.kc);
  row.downstream_available = downstream_available;
  row.checker = 'FROZEN_REDUCED_FACTOR_RCOND_NO_SOLVE';
end

function row = LOCAL_negative_N8(results, context, cfg)
  kp = context.kc + 0.37i * context.radius;
  sampled = results.sampled([results.sampled.attempt] == context.attempt);
  cr_rows = results.cr([results.cr.attempt] == context.attempt);
  sampled_points = [sampled.k_real] + 1i * [sampled.k_imag];
  scalar_values = (context.kc - kp) ./ (sampled_points - kp);
  sampled_available = ~isempty(sampled) && all([sampled.available]) && ...
    all(isfinite(scalar_values));
  stencil_available = ~isempty(cr_rows) && all([cr_rows.pass]);
  [F_center, center_available] = LOCAL_positive_F_eval( ...
    context.kc, 0, cfg, context);
  pass = sampled_available && stencil_available && center_available && ...
    abs(kp - context.kc) < context.radius;
  row = LOCAL_negative_row('N8', 'HIDDEN_INTERIOR_POLE_DISCLOSED', ...
    min(abs(sampled_points - kp)), 0, pass, ...
    LOCAL_cond_status(pass, ...
    'SAMPLED_DOMAIN_AVAILABLE;HIDDEN_INTERIOR_POLE_UNEXCLUDED', ...
    'HIDDEN_POLE_FIXTURE_FAILED'));
  row.pole_k_real = real(kp);
  row.pole_k_imag = imag(kp);
  row.sampled_domain_status = LOCAL_cond_status(sampled_available, ...
    'SAMPLED_DOMAIN_AVAILABLE', 'SAMPLED_DOMAIN_UNAVAILABLE');
  row.pole_free_claim = 'UNAVAILABLE';
  row.raw_F_fingerprint = LOCAL_matrix_fingerprint(F_center);
  row.raw_F_preserved = true;
  row.downstream_available = sampled_available;
  row.checker = 'ACTUAL_F_TIMES_FROZEN_SCALAR_POLE';
end

function [row, raw] = LOCAL_negative_N9(context, cfg)
  components = LOCAL_build_components( ...
    context.kc, 0, cfg, context.chart, context.anchor);
  q = 2 * cfg.ntot;
  center_bad = components.center;
  center_bad.A_c(:, q) = 0;
  center_bad.E_L(:, q) = 0;
  center_bad.E_R(:, q) = 0;
  [F_bad, ~] = LOCAL_assemble_and_factors( ...
    center_bad, components.lead, components.lead, cfg);
  common_vector = zeros(size(F_bad, 2), 1);
  common_vector(q) = 1;
  null_residual = norm(F_bad * common_vector, 2) / ...
    max(1, norm(F_bad, 2));
  rank_loss = rank(F_bad, 1e-10 * max(1, norm(F_bad, 2))) < size(F_bad, 2);
  pass = components.available && isequal(size(F_bad), [240, 240]) && ...
    rank_loss && null_residual <= 1e-12;
  raw.F_bad = F_bad;
  raw.common_vector = common_vector;
  raw.q = q;
  raw.mutation = 'ZERO_COLUMN_A_c_E_L_E_R';
  raw.primitive_blocks = {'A_c', 'E_L', 'E_R'};
  raw.fingerprint = LOCAL_matrix_fingerprint(F_bad);
  raw.null_residual = null_residual;
  raw.saved = isequal(size(raw.F_bad), [240, 240]) && ...
    length(raw.common_vector) == 240 && raw.q == 120 && ...
    strcmp(raw.fingerprint, LOCAL_matrix_fingerprint(raw.F_bad));
  pass = pass && raw.saved;
  row = LOCAL_negative_row('N9', ...
    'ZERO_FIELD_REPRESENTATION_DETECTED', null_residual, 1e-12, ...
    pass, LOCAL_cond_status(pass, 'ZERO_FIELD_REPRESENTATION', ...
    'ZERO_FIELD_FIXTURE_NOT_DETECTED'));
  row.fixture_dimension = size(F_bad, 1);
  row.raw_F_fingerprint = raw.fingerprint;
  row.raw_F_preserved = raw.saved;
  row.physical_interpretation_available = false;
  row.downstream_available = false;
  row.checker = 'ACTUAL_CENTER_COMMON_NULLVECTOR';
end

function [F, available] = LOCAL_positive_F_eval(k, level, cfg, context)
  try
    [ev, ~, ~] = LOCAL_evaluate_anchored(k, level, cfg, ...
      context.chart, context.anchor, 'negative_positive_F');
    F = ev.F;
    available = ev.available && ~isempty(F);
  catch
    F = [];
    available = false;
  end
end

function components = LOCAL_build_components(k, level, cfg, chart, anchor)
  pcfg = cfg.proxy(chart.proxy_index);
  proxy_anchor = LOCAL_branch_anchor(anchor.kc, pcfg.M_pw, cfg, ...
    'components_proxy');
  port_anchor = LOCAL_branch_anchor(anchor.kc, cfg.M, cfg, ...
    'components_port');
  proxy_gamma = LOCAL_branch_values(k, proxy_anchor);
  port_gamma = LOCAL_branch_values(k, port_anchor);
  pars1 = LOCAL_pars1(k, cfg);
  pars2 = LOCAL_pars2(pcfg);
  [proxy, ~, ~, proxy_info] = LOCAL_precomp_proxy_anchored( ...
    pars1, pars2, proxy_gamma, chart, 'collocation');
  channels = LOCAL_anchored_rayleigh_channels( ...
    k, cfg.beta, cfg.d, cfg.M, cfg.L, port_gamma, anchor.fingerprint);
  [center, center_factor] = LOCAL_build_object( ...
    k, cfg.defect_axes, pars1, proxy, proxy_gamma, channels, cfg, true);
  [bulk, bulk_factor] = LOCAL_build_object( ...
    k, cfg.bulk_axes, pars1, proxy, proxy_gamma, channels, cfg, true);
  lead = LOCAL_scattering_from_center(bulk);
  double_factors = LOCAL_empty_factors();
  for idx = 1:level
    [lead, one_factor] = LOCAL_star(lead, lead);
    double_factors = [double_factors, one_factor]; %#ok<AGROW>
  end
  [F, assembly_factors] = LOCAL_assemble_and_factors(center, lead, lead, cfg);
  all_factors = [center_factor, bulk_factor, double_factors, assembly_factors];
  components.center = center;
  components.bulk = bulk;
  components.lead = lead;
  components.F = F;
  components.available = proxy_info.available && ...
    LOCAL_factor_gate(all_factors, cfg) && all(isfinite(F(:)));
end

function value = LOCAL_matrix_fingerprint(matrix)
  if isempty(matrix)
    value = 'UNAVAILABLE';
  else
    value = LOCAL_raw_fingerprint( ...
      [real(matrix(:)); imag(matrix(:))]);
  end
end

function pass = LOCAL_circle_smoke(results, cfg)
  base_index = find(strcmp({results.proxy_charts.label}, 'base_r'), 1);
  chart = results.proxy_charts(base_index);
  selected = find([results.disks.pass], 1);
  center_k = results.disks(selected).center;
  pcfg = cfg.proxy(chart.proxy_index);
  disk_anchor = LOCAL_branch_anchor(center_k, cfg.M, cfg, 'circle_smoke');
  proxy_anchor = LOCAL_branch_anchor(center_k, pcfg.M_pw, cfg, ...
    'circle_smoke_proxy');
  port_gamma = LOCAL_branch_values(center_k, disk_anchor);
  proxy_gamma = LOCAL_branch_values(center_k, proxy_anchor);
  pars1 = LOCAL_pars1(center_k, cfg);
  pars2 = LOCAL_pars2(pcfg);
  [proxy, ~, ~, info] = LOCAL_precomp_proxy_anchored( ...
    pars1, pars2, proxy_gamma, chart, 'collocation');
  channels = LOCAL_anchored_rayleigh_channels( ...
    center_k, cfg.beta, cfg.d, cfg.M, cfg.L, port_gamma, ...
    disk_anchor.fingerprint);
  [center_object, center_factor] = LOCAL_build_object( ...
    center_k, cfg.defect_axes, pars1, proxy, proxy_gamma, ...
    channels, cfg, true);
  [circle_object, circle_factor] = LOCAL_build_object( ...
    center_k, 'circle', pars1, proxy, proxy_gamma, channels, cfg, true);
  circle_lead = LOCAL_scattering_from_center(circle_object);
  [F, assembly_factors] = LOCAL_assemble_and_factors( ...
    center_object, circle_lead, circle_lead, cfg);
  ev = LOCAL_augmented_metrics(F, cfg);
  pass = info.available && ev.available && ...
    LOCAL_factor_gate([center_factor, circle_factor, assembly_factors], cfg);
end

function value = LOCAL_outgoing_sqrt(value)
  value = sqrt(complex(value));
  flip = imag(value) < 0 | (imag(value) == 0 & real(value) < 0);
  value(flip) = -value(flip);
end

function value = LOCAL_scalar_cr(fun, k, h)
  Dx = (fun(k + h) - fun(k - h)) / (2 * h);
  Dy = (fun(k + 1i * h) - fun(k - 1i * h)) / (2i * h);
  value = abs(Dx - Dy) / max([1, abs(Dx), abs(Dy)]);
end

function row = LOCAL_negative_row(id, name, measured, threshold, pass, status)
  row = struct('id', id, 'name', name, 'measured', measured, ...
    'threshold', threshold, 'detected', pass, 'raw_F_preserved', false, ...
    'physical_interpretation_available', false, ...
    'fixture_k_real', NaN, 'fixture_k_imag', NaN, ...
    'fixture_dimension', NaN, 'projector_left_hash', '', ...
    'projector_right_hash', '', 'projector_difference', NaN, ...
    'raw_F_fingerprint', '', 'pole_k_real', NaN, 'pole_k_imag', NaN, ...
    'sampled_domain_status', '', 'pole_free_claim', '', ...
    'downstream_available', false, 'checker', '', ...
    'pass', pass, 'status', status);
end

%% ==================== Gates and reproducibility ====================
% These helpers produce the fail-closed maximum claim.

function results = LOCAL_classify(results, baseline_results)
  cfg = results.cfg;
  locator_pass = ~isempty(results.locator) && ...
    any([results.locator.selected]) && all([results.locator.available]);
  chart_pass = length(results.charts) == 4 && all([results.charts.pass]);
  selected_index = find([results.disks.pass], 1);
  sample_pass = ~isempty(selected_index) && ...
    ~strcmp(results.selected_disk, 'NONE');
  if sample_pass
    selected_attempt = results.disks(selected_index).attempt;
    selected_branch = results.branch_rows( ...
      [results.branch_rows.attempt] == selected_attempt);
    selected_factors = results.factors( ...
      [results.factors.attempt] == selected_attempt);
    selected_cr = results.cr([results.cr.attempt] == selected_attempt);
    selected_sampled = results.sampled( ...
      [results.sampled.attempt] == selected_attempt);
    branch_pass = ~isempty(selected_branch) && all([selected_branch.pass]);
    factor_pass = ~isempty(selected_factors) && ...
      LOCAL_factor_gate(selected_factors, cfg);
    cr_pass = ~isempty(selected_cr) && all([selected_cr.pass]);
    sample_pass = sample_pass && ~isempty(selected_sampled) && ...
      all([selected_sampled.available]);
  else
    branch_pass = false;
    factor_pass = false;
    cr_pass = false;
  end
  negative_ids = {results.negatives.id};
  negative_pass = length(results.negatives) == 11 && ...
    isequal(negative_ids, arrayfun(@(x) sprintf('N%d', x), ...
    1:11, 'UniformOutput', false)) && all([results.negatives.pass]);

  rows = LOCAL_empty_gates();
  rows(end + 1) = LOCAL_gate_row('G1_LOCATOR', locator_pass, ...
    'strict 29-point interior dip and complete scan');
  rows(end + 1) = LOCAL_gate_row('G2_FIXED_CHARTS', chart_pass, ...
    'four seed-frozen proxy charts and refinement sensitivity');
  rows(end + 1) = LOCAL_gate_row('G3_SAMPLED_DOMAIN', sample_pass, ...
    'first complete nested sampled disk');
  rows(end + 1) = LOCAL_gate_row('G4_BRANCH', branch_pass, ...
    'anchored algebra and continuation fingerprints');
  rows(end + 1) = LOCAL_gate_row('G5_FACTORS', factor_pass, ...
    'all raw and interpretation factors available');
  rows(end + 1) = LOCAL_gate_row('G6_FULL_F_CR', cr_pass, ...
    'full augmented CR and derivative refinement');
  rows(end + 1) = LOCAL_gate_row('G7_NEGATIVES', negative_pass, ...
    'mandatory N1--N11 falsification matrix');
  rows(end + 1) = LOCAL_gate_row('G8_ARTIFACT_BUNDLE', ...
    results.artifact_bundle_complete, 'all pre-marker artifacts present');
  results.gates = rows;
  results.reproducibility = LOCAL_reproducibility( ...
    results, baseline_results);
  rows(end + 1) = LOCAL_gate_row('G9_REPRODUCIBILITY', ...
    results.reproducibility.pass, 'baseline/repeat exact-class reproduction');
  results.gates = rows;
  all_pass = all([rows.pass]);
  if all_pass && strcmp(results.run_label, 'repeat')
    results.root_readiness = 'ROOT_READINESS_SAMPLED_DISCRETE_GO';
  elseif all_pass
    results.root_readiness = 'ROOT_READINESS_BASELINE_COMPLETE_REPEAT_PENDING';
  else
    results.root_readiness = 'ROOT_READINESS_SAMPLED_DISCRETE_STOP';
  end
  results.physical_root_ready = 'STOP';
  results.hidden_interior_pole = 'HIDDEN_INTERIOR_POLE_UNEXCLUDED';
  results.pole_free_claim = 'UNAVAILABLE';
end

function row = LOCAL_gate_row(name, pass, note)
  row = struct('gate', name, 'pass', pass, ...
    'status', LOCAL_pass_status(pass), 'note', note);
end

function repro = LOCAL_reproducibility(results, baseline)
  if isempty(baseline)
    repro.status = 'BASELINE_RECORDED_REPEAT_PENDING';
    repro.pass = true;
    repro.numeric_relative_difference = 0;
    repro.manifest_equal = true;
    repro.branch_fingerprints_equal = true;
    repro.chart_projectors_equal = true;
    repro.selected_disk_equal = true;
    repro.gate_classifications_equal = true;
    repro.sampled_equal = true;
    repro.factors_equal = true;
    repro.branches_equal = true;
    repro.cr_equal = true;
    repro.charts_equal = true;
    repro.locator_equal = true;
    repro.disks_equal = true;
    repro.negatives_equal = true;
    return;
  end
  repro.manifest_equal = LOCAL_manifest_equal( ...
    results.cfg.source_manifest, baseline.cfg.source_manifest);
  repro.branch_fingerprints_equal = strcmp( ...
    results.branch_fingerprint, baseline.branch_fingerprint);
  repro.chart_projectors_equal = isequal( ...
    results.projector_fingerprints, baseline.projector_fingerprints);
  repro.selected_disk_equal = strcmp( ...
    results.selected_disk, baseline.selected_disk);
  compare_count = min([7, length(results.gates), length(baseline.gates)]);
  current_gates = {results.gates(1:compare_count).gate};
  baseline_gates = {baseline.gates(1:compare_count).gate};
  current_pass = [results.gates(1:compare_count).pass];
  baseline_pass = [baseline.gates(1:compare_count).pass];
  repro.gate_classifications_equal = isequal(current_gates, baseline_gates) && ...
    isequal(current_pass, baseline_pass) && compare_count == 7;
  tolerance = results.cfg.reproducibility_tol;
  [repro.sampled_equal, sampled_difference] = LOCAL_compare_tables( ...
    results.sampled, baseline.sampled, tolerance);
  [repro.factors_equal, factor_difference] = LOCAL_compare_tables( ...
    results.factors, baseline.factors, tolerance);
  [repro.branches_equal, branch_difference] = LOCAL_compare_tables( ...
    results.branch_rows, baseline.branch_rows, tolerance);
  [repro.cr_equal, cr_difference] = LOCAL_compare_tables( ...
    results.cr, baseline.cr, tolerance);
  [repro.charts_equal, chart_difference] = LOCAL_compare_tables( ...
    results.charts, baseline.charts, tolerance);
  [repro.locator_equal, locator_difference] = LOCAL_compare_tables( ...
    results.locator, baseline.locator, tolerance);
  [repro.disks_equal, disk_difference] = LOCAL_compare_tables( ...
    results.disks, baseline.disks, tolerance);
  [repro.negatives_equal, negative_difference] = LOCAL_compare_tables( ...
    results.negatives, baseline.negatives, tolerance);
  repro.numeric_relative_difference = max([sampled_difference, ...
    factor_difference, branch_difference, cr_difference, chart_difference, ...
    locator_difference, disk_difference, negative_difference]);
  repro.pass = repro.manifest_equal && ...
    repro.branch_fingerprints_equal && repro.chart_projectors_equal && ...
    repro.selected_disk_equal && repro.gate_classifications_equal && ...
    repro.sampled_equal && repro.factors_equal && repro.branches_equal && ...
    repro.cr_equal && repro.charts_equal && repro.locator_equal && ...
    repro.disks_equal && repro.negatives_equal && ...
    repro.numeric_relative_difference <= tolerance;
  repro.status = LOCAL_cond_status(repro.pass, 'REPRODUCED', ...
    'REPRODUCIBILITY_FAILURE');
end

function equal = LOCAL_manifest_equal(a, b)
  equal = length(a) == length(b);
  if ~equal
    return;
  end
  for idx = 1:length(a)
    equal = equal && strcmp(a(idx).scope, b(idx).scope) && ...
      strcmp(a(idx).name, b(idx).name) && ...
      strcmp(a(idx).sha256, b(idx).sha256);
  end
end

function [equal, max_difference] = LOCAL_compare_tables(a, b, tolerance)
  equal = length(a) == length(b) && isequal(fieldnames(a), fieldnames(b));
  max_difference = 0;
  if ~equal
    max_difference = Inf;
    return;
  end
  fields = fieldnames(a);
  for row_index = 1:length(a)
    for field_index = 1:length(fields)
      x = a(row_index).(fields{field_index});
      y = b(row_index).(fields{field_index});
      if isnumeric(x) && isnumeric(y)
        if ~strcmp(class(x), class(y)) || ~isequal(size(x), size(y)) || ...
            ~isequal(isnan(x), isnan(y)) || ~isequal(isinf(x), isinf(y))
          equal = false;
          max_difference = Inf;
          return;
        end
        finite = isfinite(x);
        if any(sign(x(isinf(x))) ~= sign(y(isinf(y))))
          equal = false;
          max_difference = Inf;
          return;
        end
        if any(finite(:))
          denominator = max(1, max(abs(x(finite)), abs(y(finite))));
          difference = abs(x(finite) - y(finite)) ./ denominator;
          max_difference = max(max_difference, max(difference(:)));
          equal = equal && all(difference(:) <= tolerance);
        end
      elseif islogical(x) && islogical(y)
        equal = equal && isequal(x, y);
      elseif ischar(x) && ischar(y)
        equal = equal && strcmp(x, y);
      else
        equal = false;
      end
      if ~equal
        max_difference = Inf;
        return;
      end
    end
  end
end

%% ==================== Evidence writers ====================
% These helpers write deterministic text tables without hiding unavailable rows.

function LOCAL_write_outputs(results, output_dir)
  LOCAL_write_config(results, fullfile(output_dir, 'config.txt'));
  LOCAL_write_struct_csv(results.cfg.source_manifest, ...
    fullfile(output_dir, 'source-manifest.csv'));
  LOCAL_write_struct_csv(results.branch_rows, ...
    fullfile(output_dir, 'branch-ledger.csv'));
  LOCAL_write_struct_csv(results.locator, fullfile(output_dir, 'locator.csv'));
  LOCAL_write_struct_csv(results.charts, ...
    fullfile(output_dir, 'chart-ledger.csv'));
  LOCAL_write_struct_csv(results.sampled, ...
    fullfile(output_dir, 'sampled-domain.csv'));
  LOCAL_write_struct_csv(results.factors, ...
    fullfile(output_dir, 'factor-ledger.csv'));
  LOCAL_write_struct_csv(results.cr, fullfile(output_dir, 'cr.csv'));
  LOCAL_write_struct_csv(results.negatives, ...
    fullfile(output_dir, 'negative-cases.csv'));
  LOCAL_write_gate_csv(results.gates, fullfile(output_dir, 'gate.csv'));
  LOCAL_write_report(results, fullfile(output_dir, 'report.md'));
end

function LOCAL_write_config(results, path)
  fid = LOCAL_open_write(path);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  cfg = results.cfg;
  fprintf(fid, 'version=%s\n', cfg.version);
  fprintf(fid, 'representation=%s\n', cfg.representation);
  fprintf(fid, 'run_label=%s\n', results.run_label);
  fprintf(fid, 'beta=%.17g\n', cfg.beta);
  fprintf(fid, 'scan=[%.17g,%.17g]\n', cfg.scan(1), cfg.scan(2));
  fprintf(fid, 'scan_points=%d\n', cfg.scan_points);
  fprintf(fid, 'nref=%d\n', cfg.nref);
  fprintf(fid, 'defect_axes=[%.17g,%.17g]\n', cfg.defect_axes);
  fprintf(fid, 'bulk_axes=[%.17g,%.17g]\n', cfg.bulk_axes);
  fprintf(fid, 'walls=[%.17g,%.17g]\n', cfg.walls);
  fprintf(fid, 'cell_length=%.17g\n', cfg.L);
  fprintf(fid, 'period=%.17g\n', cfg.d);
  fprintf(fid, 'port_order=%d\n', cfg.M);
  fprintf(fid, 'port_dimension=%d\n', cfg.p);
  fprintf(fid, 'boundary_nodes=%d\n', cfg.ntot);
  fprintf(fid, 'locator_level=%d\n', cfg.locator_level);
  fprintf(fid, 'levels=0,3,4\n');
  fprintf(fid, 'cr_levels=0,4\n');
  fprintf(fid, 'terminal_closure=DIRICHLET_FAR_END\n');
  fprintf(fid, 'physical_root_ready=STOP\n');
  fprintf(fid, 'threshold.rank_ratio=%.17g\n', cfg.rank_ratio);
  fprintf(fid, 'threshold.rank_gap=%.17g\n', cfg.rank_gap);
  fprintf(fid, 'threshold.projector_repeat=%.17g\n', ...
    cfg.projector_repeat_tol);
  fprintf(fid, 'threshold.proxy_rcond_min=%.17g\n', cfg.proxy_rcond_min);
  fprintf(fid, 'threshold.proxy_projected=%.17g\n', ...
    cfg.proxy_projected_tol);
  fprintf(fid, 'threshold.proxy_full=%.17g\n', cfg.proxy_full_tol);
  fprintf(fid, 'threshold.bie_rcond_min=%.17g\n', cfg.bie_rcond_min);
  fprintf(fid, 'threshold.bie_residual=%.17g\n', cfg.bie_residual_tol);
  fprintf(fid, 'threshold.factor_rcond_min=%.17g\n', cfg.factor_rcond_min);
  fprintf(fid, 'threshold.factor_residual=%.17g\n', cfg.factor_residual_tol);
  fprintf(fid, 'threshold.boundary_separation=%.17g\n', ...
    cfg.aug_boundary_sep_min);
  fprintf(fid, 'threshold.nested_change=%.17g\n', cfg.nested_change_max);
  fprintf(fid, 'threshold.branch=%.17g\n', cfg.branch_tol);
  fprintf(fid, 'threshold.cr=%.17g\n', cfg.cr_tol);
  fprintf(fid, 'threshold.locator_dip=%.17g\n', cfg.locator_dip_max);
  fprintf(fid, 'threshold.locator_neighbor_ratio=%.17g\n', ...
    cfg.locator_neighbor_ratio);
  fprintf(fid, 'threshold.participation=%.17g\n', cfg.participation_min);
  fprintf(fid, 'threshold.refinement_overlap=%.17g\n', ...
    cfg.refinement_overlap_min);
  fprintf(fid, 'threshold.real_axis_mismatch=%.17g\n', ...
    cfg.real_axis_mismatch_tol);
  fprintf(fid, 'threshold.reproducibility=%.17g\n', ...
    cfg.reproducibility_tol);
  fprintf(fid, 'command.baseline=%s\n', cfg.commands.baseline);
  fprintf(fid, 'command.repeat=%s\n', cfg.commands.repeat);
  for proxy_index = 1:length(cfg.proxy)
    proxy = cfg.proxy(proxy_index);
    prefix = sprintf('proxy.%s', proxy.label);
    fprintf(fid, '%s.H=%.17g\n', prefix, proxy.H);
    fprintf(fid, '%s.proxy_dist=%.17g\n', prefix, proxy.proxy_dist);
    fprintf(fid, '%s.N_side=%d\n', prefix, proxy.N_side);
    fprintf(fid, '%s.N_top=%d\n', prefix, proxy.N_top);
    fprintf(fid, '%s.N_proxy_edge=%d\n', prefix, proxy.N_proxy_edge);
    fprintf(fid, '%s.M_pw=%d\n', prefix, proxy.M_pw);
  end
  fprintf(fid, ['representation.row_ids=', ...
    'g1,g2,g3,g4,g5,g6,g7,g8,g9\n']);
  fprintf(fid, ['representation.column_ids=', ...
    'xi,ac_minus,bc_plus,bc_minus,ac_plus,', ...
    'af_minus,bf_minus,bf_plus,af_plus\n']);
  for idx = 1:length(cfg.required_artifacts)
    fprintf(fid, 'required_artifact.%03d=%s\n', idx, ...
      cfg.required_artifacts{idx});
  end
  row_names = {'source_manifest', 'branch', 'locator', 'chart', ...
    'sampled', 'factor', 'cr', 'negative', 'gate'};
  row_values = [length(cfg.source_manifest), length(results.branch_rows), ...
    length(results.locator), length(results.charts), ...
    length(results.sampled), length(results.factors), length(results.cr), ...
    length(results.negatives), length(results.gates)];
  for idx = 1:length(row_names)
    fprintf(fid, 'actual_stage_rows.%s=%d\n', ...
      row_names{idx}, row_values(idx));
  end
  for idx = 1:length(cfg.source_manifest)
    fprintf(fid, 'source.%03d.scope=%s\n', idx, ...
      cfg.source_manifest(idx).scope);
    fprintf(fid, 'source.%03d.path=%s\n', idx, ...
      cfg.source_manifest(idx).path);
    fprintf(fid, 'source.%03d.sha256=%s\n', idx, ...
      cfg.source_manifest(idx).sha256);
  end
end

function LOCAL_write_gate_csv(rows, path)
  LOCAL_write_struct_csv(rows, path);
end

function LOCAL_write_report(results, path)
  fid = LOCAL_open_write(path);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, '# I4 analytic-readiness report\n\n');
  fprintf(fid, '- Version: `%s`\n', results.cfg.version);
  fprintf(fid, '- Run: `%s`\n', results.run_label);
  fprintf(fid, '- Representation: `%s`\n', results.cfg.representation);
  fprintf(fid, '- Decision: `%s`\n', results.root_readiness);
  fprintf(fid, '- `PHYSICAL_ROOT_READY=STOP`\n');
  fprintf(fid, '- `%s`\n', results.hidden_interior_pole);
  fprintf(fid, '- Pole-free claim: `%s`\n', results.pole_free_claim);
  fprintf(fid, '- Selected disk: `%s`\n\n', results.selected_disk);
  fprintf(fid, '## Gate ledger\n\n');
  fprintf(fid, '| Gate | Pass | Status |\n');
  fprintf(fid, '|---|---:|---|\n');
  for idx = 1:length(results.gates)
    fprintf(fid, '| `%s` | %d | `%s` |\n', results.gates(idx).gate, ...
      results.gates(idx).pass, results.gates(idx).status);
  end
  fprintf(fid, '\nThis experiment performs no root count, root solve, estimator, ');
  fprintf(fid, 'effectivity calculation, or certification.\n');
end

function LOCAL_write_struct_csv(rows, path)
  fid = LOCAL_open_write(path);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fields = fieldnames(rows);
  fprintf(fid, '%s\n', strjoin(fields.', ','));
  for row_index = 1:length(rows)
    values = cell(1, length(fields));
    for field_index = 1:length(fields)
      value = rows(row_index).(fields{field_index});
      values{field_index} = LOCAL_csv_value(value);
    end
    fprintf(fid, '%s\n', strjoin(values, ','));
  end
end

function value = LOCAL_csv_value(input)
  if ischar(input)
    value = ['"', strrep(input, '"', '""'), '"'];
  elseif isstring(input)
    value = ['"', strrep(char(input), '"', '""'), '"'];
  elseif islogical(input) && isscalar(input)
    value = sprintf('%d', input);
  elseif isnumeric(input) && isscalar(input)
    if isreal(input)
      value = sprintf('%.17g', input);
    else
      value = sprintf('%.17g%+.17gi', real(input), imag(input));
    end
  elseif isnumeric(input)
    value = ['"', mat2str(input, 17), '"'];
  elseif iscell(input)
    value = ['"', strjoin(input, ';'), '"'];
  else
    value = '"STRUCT_DATA_IN_RESULTS_MAT"';
  end
end

function fid = LOCAL_open_write(path)
  fid = fopen(path, 'w');
  if fid < 0
    error('analytic_readiness:EvidenceOpen', 'Could not write %s.', path);
  end
end

%% ==================== Row schemas ====================
% Empty schemas keep every CSV header stable even after an upstream stop.

function rows = LOCAL_empty_locator()
  rows = struct('stage', {}, 'chart', {}, 'iteration', {}, 'index', {}, ...
    'k', {}, 's', {}, 'available', {}, 'selected', {}, 'reason', {});
end

function rows = LOCAL_empty_charts()
  rows = struct('chart', {}, 'proxy', {}, 'rank', {}, ...
    'selected_ratio', {}, 'gap', {}, 'factor_rcond', {}, ...
    'projected_residual', {}, 'full_off_residual', {}, ...
    'off_block_residuals', {}, ...
    'refined_k', {}, 'locator_value', {}, ...
    'anchor_green_mismatch', {}, 'anchor_F_mismatch', {}, ...
    'refinement_green_mismatch', {}, 'refinement_F_mismatch', {}, ...
    'real_axis_mismatch_pass', {}, ...
    'overlap', {}, 'participation', {}, ...
    'pass', {}, 'status', {});
end

function rows = LOCAL_empty_disks()
  rows = struct('attempt', {}, 'center', {}, 'radius', {}, ...
    'branch_distance', {}, 'boundary_min', {}, 'boundary_min_by_level', {}, ...
    'nested_change', {}, 'availability16', {}, 'availability32', {}, ...
    'chart_separation_change', {}, 'chart_boundary_spread', {}, ...
    'sample_pass', {}, 'cr_pass', {}, ...
    'pass', {}, 'status', {});
end

function rows = LOCAL_empty_sampled()
  rows = struct('attempt', {}, 'chart', {}, 'node', {}, 'level', {}, ...
    'k_real', {}, 'k_imag', {}, 's', {}, 'sigma_min', {}, ...
    'participation', {}, 'available', {}, 'status', {});
end

function rows = LOCAL_empty_factors()
  rows = struct('attempt', {}, 'chart', {}, 'node', {}, ...
    'k_real', {}, 'k_imag', {}, ...
    'level', {}, 'name', {}, 'factor_role', {}, 'raw_inverted', {}, ...
    'rcond', {}, 'residual', {}, 'available', {}, 'failure_reason', {});
end

function row = LOCAL_factor_row(chart, node, k, level, name, ...
    rcond_value, residual, available, reason)
  raw_inverted = strcmp(name, 'proxy_reduced_factor') || ...
    strcmp(name, 'bulk_BIE') || strncmp(name, 'doubling_', 9);
  factor_role = 'INTERPRETATION_FACTOR';
  if raw_inverted
    factor_role = 'RAW_EVALUATOR_FACTOR';
  end
  row = struct('attempt', NaN, 'chart', chart, 'node', node, ...
    'k_real', real(k), ...
    'k_imag', imag(k), 'level', level, 'name', name, ...
    'factor_role', factor_role, 'raw_inverted', raw_inverted, ...
    'rcond', rcond_value, 'residual', residual, 'available', available, ...
    'failure_reason', reason);
end

function rows = LOCAL_empty_cr()
  rows = struct('attempt', {}, 'chart', {}, 'node_index', {}, ...
    'level', {}, 'h0', {}, 'cr_h0', {}, 'cr_h1', {}, 'cr_h2', {}, ...
    'spread_x', {}, 'spread_y', {}, 'trend_pass', {}, 'pass', {}, ...
    'status', {});
end

function rows = LOCAL_empty_negatives()
  rows = struct('id', {}, 'name', {}, 'measured', {}, 'threshold', {}, ...
    'detected', {}, 'raw_F_preserved', {}, ...
    'physical_interpretation_available', {}, 'fixture_k_real', {}, ...
    'fixture_k_imag', {}, 'fixture_dimension', {}, ...
    'projector_left_hash', {}, 'projector_right_hash', {}, ...
    'projector_difference', {}, 'raw_F_fingerprint', {}, ...
    'pole_k_real', {}, 'pole_k_imag', {}, 'sampled_domain_status', {}, ...
    'pole_free_claim', {}, 'downstream_available', {}, 'checker', {}, ...
    'pass', {}, 'status', {});
end

function rows = LOCAL_empty_branch_rows()
  rows = struct('attempt', {}, 'consumer', {}, 'k_real', {}, 'k_imag', {}, ...
    'order_min', {}, 'order_max', {}, 'fingerprint', {}, ...
    'algebra_error', {}, 'roundtrip_error', {}, 'pass', {}, 'status', {});
end

function rows = LOCAL_empty_gates()
  rows = struct('gate', {}, 'pass', {}, 'status', {}, 'note', {});
end

%% ==================== Numerical utilities ====================
% These helpers provide consistent parsers, residuals, hashes, and statuses.

function pars1 = LOCAL_pars1(k, cfg)
  pars1.k = k;
  pars1.beta = cfg.beta;
  pars1.d = cfg.d;
  pars1.periodic_axis = 'y';
end

function pars2 = LOCAL_pars2(pcfg)
  pars2.H = pcfg.H;
  pars2.proxy_dist = pcfg.proxy_dist;
  pars2.N_side = pcfg.N_side;
  pars2.N_top = pcfg.N_top;
  pars2.N_proxy_edge = pcfg.N_proxy_edge;
  pars2.M_pw = pcfg.M_pw;
end

function value = LOCAL_relres(A, X, B)
  value = norm(A * X - B, 'fro') / ...
    max(1, norm(A, 2) * norm(X, 'fro') + norm(B, 'fro'));
end

function value = LOCAL_relmat(A, B)
  value = norm(A - B, 'fro') / max([1, norm(A, 'fro'), norm(B, 'fro')]);
end

function value = LOCAL_source_hash(path)
  [status, output] = system(sprintf('shasum -a 256 "%s"', ...
    strrep(path, '"', '\"')));
  if status ~= 0
    error('analytic_readiness:SourceHash', 'Could not hash %s.', path);
  end
  parts = strsplit(strtrim(output));
  value = parts{1};
end

function value = LOCAL_raw_fingerprint(data)
  payload = sprintf('%.17g,', double(data(:)));
  value = hash('sha256', payload);
end

function status = LOCAL_pass_status(pass)
  status = LOCAL_cond_status(pass, 'PASS', 'FAIL');
end

function value = LOCAL_cond_status(condition, yes_value, no_value)
  if condition
    value = yes_value;
  else
    value = no_value;
  end
end

function reason = LOCAL_exception_reason(exception)
  reason = exception.identifier;
  if isempty(reason)
    reason = 'NUMERICAL_EXCEPTION';
  end
end

function rows = LOCAL_set_attempt(rows, attempt)
  for idx = 1:length(rows)
    rows(idx).attempt = attempt;
  end
end

%% ==================== Cheap self-test ====================
% This helper exercises branch algebra only and writes no artifacts.

function results = LOCAL_selftest()
  beta = 0.8;
  d = 2 * pi;
  M = 7;
  k = 0.1;
  m = (-M:M).';
  beta_m = beta + 2 * pi * m / d;
  gamma = sqrt(complex(k^2 - beta_m.^2));
  flip = imag(gamma) < 0;
  gamma(flip) = -gamma(flip);
  channels = LOCAL_anchored_rayleigh_channels( ...
    k, beta, d, M, 2, gamma, 'SELFTEST');
  algebra = max(abs(channels.gamma_m.^2 - (k^2 - beta_m.^2)));
  cfg.beta = beta;
  cfg.d = d;
  cfg.branch_tol = 1e-12;
  anchor = LOCAL_branch_anchor(k, M, cfg, 'selftest');
  audit = LOCAL_branch_audit(k + 1e-4i, anchor, cfg, 'selftest');
  n1 = LOCAL_scalar_cr(@(z) LOCAL_outgoing_sqrt(z.^2 - beta^2), ...
    1.0, 1e-6);
  n4_sanity = LOCAL_scalar_cr( ...
    @(z) LOCAL_outgoing_sqrt(z.^2 - (-0.2)^2), 0.25, 1e-6);
  cfg.cr_tol = 1e-6;
  good = LOCAL_full_F_cr_checker( ...
    @(z) LOCAL_selftest_matrix_eval(z, false), 0.1 + 0.02i, 1e-4, cfg);
  bad = LOCAL_full_F_cr_checker( ...
    @(z) LOCAL_selftest_matrix_eval(z, true), 0.1 + 0.02i, 1e-4, cfg);
  identity_two = eye(2);
  identity_fingerprint = LOCAL_raw_fingerprint( ...
    [identity_two(:); zeros(4, 1); identity_two(:); zeros(4, 1)]);
  chart = struct('rank', 2, 'U', identity_two, 'V', identity_two, ...
    'fingerprint', identity_fingerprint, 'label', 'selftest', ...
    'proxy_index', 1);
  [representation_pass, ~, ~] = LOCAL_representation_checker(chart, chart);
  table_fixture = struct('value', {1, NaN}, 'status', {'PASS', 'STOP'});
  [table_equal, table_difference] = LOCAL_compare_tables( ...
    table_fixture, table_fixture, 1e-13);
  results.pass = algebra <= 1e-12 && channels.K == 15 && ...
    audit.pass && n1 > 1e-3 && n4_sanity > 0.5 && ...
    length(anchor.fingerprint) == 64 && ...
    good.pass && bad.cr(3) > 1e-3 && representation_pass && ...
    table_equal && table_difference == 0;
  results.branch_algebra = algebra;
  results.branch_roundtrip = audit.roundtrip_error;
  results.pointwise_negative_cr = n1;
  results.propagating_fixture_cr = n4_sanity;
end

function [F, available] = LOCAL_selftest_matrix_eval(k, mutated)
  F = [k, k^2; exp(k), 1];
  if mutated
    F(1, 1) = F(1, 1) + 1e3 * conj(k);
  end
  available = true;
end
