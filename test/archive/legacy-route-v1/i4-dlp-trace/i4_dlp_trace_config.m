function config = i4_dlp_trace_config()
%I4_DLP_TRACE_CONFIG Return frozen DLP and physical trace settings.
%
% Purpose:
%   Centralize the sequential DLP-D, DLP-N, and four-action M_trace test.
%
% Output:
%   config - Immutable physical, numerical, provenance, and gate settings.
%
% Based on:
%   test/i4-three-path-derivatives/i4_three_path_derivatives_config.m and
%   test/i4-proxy-rule/i4_proxy_rule_config.m.
%
% Numerical goal:
%   Qualify DLP actions at proxy_dist/d=0.2 before certifying M_trace=48.

  here = fileparts(mfilename('fullpath'));
  config.here = here;
  config.repo_root = fileparts(fileparts(here));
  config.output_root = fullfile(here, 'output');
  config.k = 1.8603695988;
  config.beta = 0.5;
  config.d = 1;
  config.R = 0.2;
  config.X_L = -0.5;
  config.X_R = 0.5;
  config.H = 1.1;
  config.proxy_dist = 0.2;
  config.project_sign = -1;

  config.density(1).label = 'canonical';
  config.density(1).ell = [0; 1; 3];
  config.density(1).coeff = [1; -0.35 + 0.20i; 0.20 - 0.15i];
  config.density(2).label = 'phase_holdout';
  config.density(2).ell = [-2; 0; 1; 3];
  config.density(2).coeff = [0.13 + 0.09i; 0.72 - 0.11i; ...
    -0.24 + 0.31i; 0.08 - 0.19i];

  config.point(1) = LOCAL_point('holdout_B_negative', -0.217, 0.287);
  config.point(2) = LOCAL_point('holdout_B_positive', 0.217, 0.287);
  config.point(3) = LOCAL_point('holdout_A', 0.263, 0.173);

  common = struct('H', config.H, 'proxy_dist', config.proxy_dist);
  config.proxy.base = LOCAL_proxy(common, 120, 120, 64, 24);
  config.proxy.Nedge = LOCAL_proxy(common, 120, 120, 80, 24);
  config.proxy.Nside = LOCAL_proxy(common, 160, 120, 64, 24);
  config.proxy.Ntop = LOCAL_proxy(common, 120, 160, 64, 24);
  config.proxy.Mpw = LOCAL_proxy(common, 120, 120, 64, 32);
  config.proxy.labels = {'base', 'Nedge', 'Nside', 'Ntop', 'Mpw'};
  config.proxy.expected_rank = [302, 328, 302, 302, 330];

  config.ewald.base = struct('a', 2, 'M1', 26, 'M2', 18, 'N', 28);
  config.ewald.M1 = struct('a', 2, 'M1', 34, 'M2', 18, 'N', 28);
  config.ewald.M2 = struct('a', 2, 'M1', 26, 'M2', 24, 'N', 28);
  config.ewald.N = struct('a', 2, 'M1', 26, 'M2', 18, 'N', 36);
  config.ewald.authority = struct('a', 2, 'M1', 34, 'M2', 24, 'N', 36);
  config.ewald.refinement_labels = {'M1', 'M2', 'N'};

  config.ntot = 256;
  config.Ny = 512;
  config.M_values = [12, 24, 48, 64, 96];
  config.M_candidate = 48;
  config.M_reference = 96;
  config.M_bands = [12, 24; 24, 48; 48, 64; 64, 96];
  config.actions = {'SLP-D', 'SLP-N', 'DLP-D', 'DLP-N'};
  config.dlp_actions = {'DLP-D', 'DLP-N'};
  config.chunk_size = 4096;
  config.fd_h = config.d * 2 .^ (-(7:10));

  config.gate.coefficient = 1e-8;
  config.gate.point = 2e-9;
  config.gate.self = 2e-9;
  config.gate.reconstruction = 2e-9;
  config.gate.tail = 2e-9;
  config.gate.sign = 2e-9;
  config.relative_floor = 1e-14;
  config.q_duplicate_factor = 100;

  config.package.precomp_hash = ...
    '3a16825064e5762f3486373fee702e94c34fa3cfdfb3b774f78f3b27eb2f9a60';
  config.package.pairmat_hash = ...
    'ed37808e707d679aa5dc43197a043107b176c7bb6a7c909741371b505e095f0d';
  config.package.farfield_hash = ...
    '5cde80636d1237d11d69657e6f500f02d631686e80ec4f9ff279c5394c4e4ff2';
  config.slp_prerequisite = fullfile(config.repo_root, 'test', ...
    'i4-proxy-rule', 'output', 'canonical', 'results.mat');
  config.slp_prerequisite_hash = ...
    '3eca19a89d927da36af232c817f72bbd1554bf6a84d6695301b80494a7a3c013';
  config.slp_report = fullfile(config.repo_root, 'test', 'i4-proxy-rule', ...
    'output', 'canonical', 'report.md');
  config.slp_report_hash = ...
    '3a236682f0edb4db652ad2f5393b73836729dd4df8bdcda2e17863ffa87d0781';
  derivative_root = fullfile(config.repo_root, 'test', ...
    'i4-three-path-derivatives');
  config.derivative_point_oracle = fullfile(derivative_root, 'output', ...
    'canonical', 'point-oracle.csv');
  config.derivative_point_oracle_hash = ...
    '625cb3e220e0d4d09d02649d8b55d831e382d1c10e062587664461a1199cc48f';
  config.derivative_derivation = fullfile(derivative_root, 'derivation.md');
  config.derivative_derivation_hash = ...
    '46957c63d436614afeecf0d5a06da508ce0ca78fe652c3dd62481d09fb17e4db';
  config.runtime.low_seconds = 90;
  config.runtime.high_seconds = 180;
end

function point = LOCAL_point(label, X, Y)
  point = struct('label', label, 'X', X, 'Y', Y);
end

function level = LOCAL_proxy(common, Nside, Ntop, Nedge, Mpw)
  level = common;
  level.N_side = Nside;
  level.N_top = Ntop;
  level.N_proxy_edge = Nedge;
  level.M_pw = Mpw;
end
