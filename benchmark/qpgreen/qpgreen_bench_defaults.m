function opts = qpgreen_bench_defaults(varargin)
% QPGREEN_BENCH_DEFAULTS Build shared options for qpgreen benchmarks.
%
% Purpose:
%   Collects user-adjustable parameters used by the benchmark entry points
%   that compare the augmented-MFS quasi-periodic Green function with an
%   Ewald implementation.
%
% Main algorithm:
%   Starts from conservative defaults, then applies case-insensitive
%   name-value overrides.  The options are kept in one struct so that MFS
%   proxy parameters, Ewald truncations, grid sizes, and output paths are
%   not hidden inside deeper helper functions.
%
% Based on:
%   Existing project usage of kernel.precomp_proxy and kernel.qpgreen_mfs.
%
% Main changes:
%   This is a benchmark-only helper.  It does not change the mathematical
%   model or any package function interface.
%
% Numerical goal:
%   Provide reproducible default settings for checking MFS values against
%   Ewald values in x-periodic coordinates.

  opts.k = 2;
  opts.beta = sqrt(2);
  opts.d = 1;

  % H is the half-height of the x-periodic computational cell in the
  % transverse y direction; MFS plane waves are attached at y = +/-H.
  opts.H = 0.5;

  % M is the Rayleigh half-truncation.  The outgoing expansions use
  % beta_m = beta + 2*pi*m/d for -M <= m <= M.
  opts.M = 25;

  % Nproxy is the total requested proxy-source count on the enclosing box.
  % kernel.precomp_proxy uses sources per edge, so this value is rounded up
  % internally to 4*N_proxy_edge.
  opts.Nproxy = 320;

  % ProxyDist is the distance from the cell box [-d/2,d/2] x [-H,H] to the
  % enclosing proxy-source box used by the augmented MFS solve.
  opts.ProxyDist = 0.2;

  % Optional collocation counts on side and top/bottom walls.  Empty values
  % trigger an automatic overdetermined least-squares density.
  opts.NSide = [];
  opts.NTop = [];

  % Ewald parameters follow Linton's notation: a balances spectral/spatial
  % sums, M1 truncates spectral modes, M2 truncates spatial images, and N
  % truncates the Taylor/exponential-integral expansion.
  opts.EwaldA = 2;
  opts.EwaldM1 = 3;
  opts.EwaldM2 = 2;
  opts.EwaldN = 7;
  opts.UseTableEwaldParams = true;

  % Grid benchmark controls.
  opts.Nx = 101;
  opts.Ny = 81;
  opts.xs = 0;
  opts.ys = 0;
  opts.SourceExclusionRadius = [];
  opts.RelFloor = 1e-14;

  % Diagnostic tolerance for grazing/cutoff Rayleigh modes.
  opts.GrazingTolerance = 1e-12;

  % OutputRoot stores .mat summaries and optional text/figure outputs.
  bench_dir = fileparts(mfilename('fullpath'));
  opts.OutputRoot = fullfile(bench_dir, 'output');

  % Grid report storage controls.  By default the grid benchmark writes only
  % a compact Markdown report; set SaveMat or GenerateFigures to true when
  % full numerical arrays or contour figures are needed.
  opts.SaveMat = false;
  opts.GenerateFigures = false;

  opts = LOCAL_apply_name_value(opts, varargin{:});
end

%% ==================== Name-value parsing helper ====================
% This helper applies compact case-insensitive option overrides.

function opts = LOCAL_apply_name_value(opts, varargin)
  if mod(numel(varargin), 2) ~= 0
    error('qpgreen_bench_defaults:InvalidInput', ...
      'Options must be supplied as name-value pairs.');
  end

  for j = 1:2:numel(varargin)
    name = varargin{j};
    value = varargin{j + 1};
    if isstring(name)
      name = char(name);
    end
    if ~ischar(name)
      error('qpgreen_bench_defaults:InvalidName', ...
        'Option names must be character vectors or strings.');
    end

    field = LOCAL_normalize_option_name(name);
    if ~isfield(opts, field)
      error('qpgreen_bench_defaults:UnknownOption', ...
        'Unknown qpgreen benchmark option ''%s''.', name);
    end
    opts.(field) = value;
  end
end

function field = LOCAL_normalize_option_name(name)
  key = lower(strrep(strrep(strtrim(name), '_', ''), '-', ''));
  switch key
    case 'k'
      field = 'k';
    case 'beta'
      field = 'beta';
    case 'd'
      field = 'd';
    case 'h'
      field = 'H';
    case 'm'
      field = 'M';
    case {'nproxy', 'nproxytotal'}
      field = 'Nproxy';
    case {'proxydist', 'proxydistance'}
      field = 'ProxyDist';
    case {'nside', 'ncollocationside'}
      field = 'NSide';
    case {'ntop', 'ncollocationtop'}
      field = 'NTop';
    case {'ewalda', 'a'}
      field = 'EwaldA';
    case {'ewaldm1', 'm1'}
      field = 'EwaldM1';
    case {'ewaldm2', 'm2'}
      field = 'EwaldM2';
    case {'ewaldn', 'n'}
      field = 'EwaldN';
    case {'usetableewaldparams', 'usetableewaldparameters'}
      field = 'UseTableEwaldParams';
    case 'nx'
      field = 'Nx';
    case 'ny'
      field = 'Ny';
    case {'xs', 'sourcex'}
      field = 'xs';
    case {'ys', 'sourcey'}
      field = 'ys';
    case {'sourceexclusionradius', 'exclusionradius'}
      field = 'SourceExclusionRadius';
    case {'relfloor', 'relativefloor'}
      field = 'RelFloor';
    case {'grazingtolerance', 'cutofftolerance'}
      field = 'GrazingTolerance';
    case {'outputroot', 'outputdir', 'outputdirectory'}
      field = 'OutputRoot';
    case {'savemat', 'keepmat', 'saveresults', 'keepnumericresults'}
      field = 'SaveMat';
    case {'generatefigures', 'savefigures', 'makefigures'}
      field = 'GenerateFigures';
    otherwise
      field = name;
  end
end
