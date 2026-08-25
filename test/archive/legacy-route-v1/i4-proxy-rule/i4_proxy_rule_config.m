function config = i4_proxy_rule_config()
%I4_PROXY_RULE_CONFIG Return the preregistered proxy-rule experiment.
%
% Purpose:
%   Freeze one theory-motivated proxy source distance, one base level, four
%   single-variable refinements, physical geometry, diagnostics, gates, and
%   immutable input authorities for the I4 SLP-D/SLP-N repair experiment.
%
% Output:
%   config - Struct containing every experiment setting.
%
% Based on:
%   test/i4-three-path-derivatives/i4_three_path_derivatives_config.m.
%
% Main changes:
%   Replaces the old proxy_dist/d=0.7 by the sole prospective candidate 0.2,
%   fixes the refinement order Nedge, Nside, Ntop, Mpw, and excludes DLP.
%
% Numerical goal:
%   Test whether singularity-aware proxy placement closes the SLP-N package
%   wall-action self-convergence gate without changing the public solver.

  here = fileparts(mfilename('fullpath'));
  config.here = here;
  config.repo_root = fileparts(fileparts(here));
  config.output_root = fullfile(here, 'output');

  % Physical geometry and manufactured densities are frozen from I4.
  config.k = 1.8603695988;
  config.beta = 0.5;
  config.d = 1.0;
  config.R = 0.2;
  config.X_L = -0.5;
  config.X_R = 0.5;
  config.wall_clearance = 0.3;
  config.H = 1.1;
  config.proxy_dist = 0.2;
  config.nearest_image_singularity_x = config.d;
  config.proxy_vertical_edge_x = config.d / 2 + config.proxy_dist;
  config.singularity_margin = config.d / 2 - config.proxy_dist;
  config.wood_distance = min(abs(config.k - abs(config.beta + ...
    2 * pi * (-4:4) / config.d)));

  config.density(1).label = 'canonical';
  config.density(1).ell = [0; 1; 3];
  config.density(1).coeff = [1; -0.35 + 0.20i; 0.20 - 0.15i];
  config.density(2).label = 'phase_holdout';
  config.density(2).ell = [-2; 0; 1; 3];
  config.density(2).coeff = [0.13 + 0.09i; 0.72 - 0.11i; ...
    -0.24 + 0.31i; 0.08 - 0.19i];

  % Frozen point oracle. References are read from the qualified diagnostic.
  config.point(1) = LOCAL_point('holdout_B_negative', -0.217, 0.287);
  config.point(2) = LOCAL_point('holdout_B_positive', 0.217, 0.287);

  % Sole source-placement candidate and the preregistered one-axis order.
  common = struct('H', config.H, 'proxy_dist', config.proxy_dist);
  config.proxy.base = LOCAL_level(common, 120, 120, 64, 24);
  config.proxy.Nedge = LOCAL_level(common, 120, 120, 80, 24);
  config.proxy.Nside = LOCAL_level(common, 160, 120, 64, 24);
  config.proxy.Ntop = LOCAL_level(common, 120, 160, 64, 24);
  config.proxy.Mpw = LOCAL_level(common, 120, 120, 64, 32);
  config.level_order = {'base', 'Nedge', 'Nside', 'Ntop', 'Mpw'};

  % Full wall action settings. M_trace is unrelated to the internal M_pw.
  config.ntot = 256;
  config.Ny = 512;
  config.M_trace = 48;
  config.output_tail_cutoff = 24;
  config.internal_pw_tail_width = 4;
  config.proxy_edge_tail_fraction = 0.25;
  config.actions = {'SLP-D', 'SLP-N'};

  % Public scientific gates are inherited unchanged.
  config.gate.point = 2e-9;
  config.gate.coefficient = 1e-8;
  config.gate.self = 2e-9;
  config.gate.output_tail = 2e-9;
  config.relative_floor = 1e-14;

  % Immutable prior authorities; the experiment aborts if either changes.
  prior = fullfile(config.repo_root, 'test', ...
    'i4-three-path-derivatives', 'output');
  config.authority.coefficient_csv = fullfile(prior, 'canonical', ...
    'coefficient-comparison.csv');
  config.authority.coefficient_sha256 = ...
    '31a383c0467b9dd107ea443c1e86b239216801a36024a78028f58e03eda05e47';
  config.authority.point_csv = fullfile(prior, ...
    'package-point-diagnostic', 'diagnostic.csv');
  config.authority.point_sha256 = ...
    '3c8df6f3bf77b93919792393c54a5f3d183cc05d0a918e6b5ab6860f2dd50ddd';
  config.package.precomp_proxy_sha256 = ...
    '3a16825064e5762f3486373fee702e94c34fa3cfdfb3b774f78f3b27eb2f9a60';
  config.package.pairmat_sha256 = ...
    'ed37808e707d679aa5dc43197a043107b176c7bb6a7c909741371b505e095f0d';

  % Historical timing is used only to estimate wall cost before full mode.
  config.runtime.low_seconds = 75;
  config.runtime.high_seconds = 120;
  config.runtime.stop_rule = ...
    'Stop after base failure or the first failed one-axis self gate.';
end

function point = LOCAL_point(label, X, Y)
  point = struct('label', label, 'X', X, 'Y', Y);
end

function level = LOCAL_level(common, Nside, Ntop, Nedge, Mpw)
  level = common;
  level.N_side = Nside;
  level.N_top = Ntop;
  level.N_proxy_edge = Nedge;
  level.M_pw = Mpw;
end
