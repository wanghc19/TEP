function cell_data = make_cell()
%MAKE_CELL Generate the frozen MATLAB-only two-level cell artifact.
% Purpose:
%   Build low/high one-cell scattering blocks for the I1.2 real preflight.
% Input:
%   None. All physical and discretization parameters are frozen in config.m.
% Output:
%   cell_data - full low/high blocks, modes, labels, residuals, and provenance;
%               also saved to input/cell.mat.
% Main algorithm:
%   For each level, use package precomp_proxy and construct_S on the frozen
%   circle, then record the exact scattering pencil and audit metadata.
% Notes:
%   This generator is MATLAB-only and must never select a fallback solver.

  if exist('OCTAVE_VERSION', 'builtin') ~= 0
    error('make_cell:MATLABRequired', 'make_cell must run in MATLAB, not Octave.');
  end
  solver_path = which('lsqminnorm');
  if isempty(solver_path)
    error('make_cell:LsqminnormRequired', ...
      'The public MATLAB lsqminnorm implementation is required.');
  end

  cfg = config();
  here = fileparts(mfilename('fullpath'));
  repo_root = fileparts(fileparts(fileparts(here)));
  addpath(repo_root);
  channels = bloch.rayleigh_channels(cfg.real.k, cfg.real.beta, ...
    cfg.real.d, cfg.real.M_master, cfg.real.X_R - cfg.real.X_L);

  pars1 = struct('k', cfg.real.k, 'beta', cfg.real.beta, ...
    'd', cfg.real.d, 'periodic_axis', 'y');
  kint = sqrt(1 + 16*cfg.real.s) * cfg.real.k;
  low = LOCAL_build_level(cfg.real.low, cfg, pars1, channels, kint);
  high = LOCAL_build_level(cfg.real.high, cfg, pars1, channels, kint);

  [git_status, git_sha] = system(sprintf( ...
    'git -C "%s" rev-parse HEAD', repo_root));
  if git_status ~= 0
    error('make_cell:GitShaUnavailable', 'Cannot record the repository Git SHA.');
  end
  source_paths = struct();
  source_paths.make_cell = LOCAL_source_path(mfilename('fullpath'));
  source_paths.precomp_proxy = LOCAL_source_path(which('kernel.precomp_proxy'));
  source_paths.construct_S = LOCAL_source_path(which('bloch.construct_S'));
  source_paths.construct_A_QP = LOCAL_source_path(which('op.construct_A_QP'));
  source_hashes = struct();
  names = fieldnames(source_paths);
  for j = 1:numel(names)
    source_hashes.(names{j}) = LOCAL_sha256(source_paths.(names{j}));
  end

  provenance = struct();
  provenance.runtime_kind = 'MATLAB';
  provenance.matlab_version = version;
  provenance.solver_name = 'lsqminnorm';
  provenance.lsqminnorm_path = solver_path;
  provenance.git_sha = strtrim(git_sha);
  provenance.source_paths = source_paths;
  provenance.source_hashes = source_hashes;
  provenance.pinv_calls = 0;
  provenance.fallbacks = 0;
  provenance.silent_rank_truncations = 0;
  provenance.generated_utc = char(datetime('now', 'TimeZone', 'UTC', ...
    'Format', 'yyyy-MM-dd''T''HH:mm:ss''Z'''));

  physical = rmfield(cfg.real, {'schema', 'low', 'high', ...
    'solve_residual_max', 'wall_labels'});
  physical.refractive_index = sqrt(1 + 16*cfg.real.s);
  cell_data = struct('schema', cfg.real.schema, 'physical', physical, ...
    'available_M', cfg.real.available_M, 'master_M', cfg.real.M_master, ...
    'level_kind', cfg.real.level_kind, ...
    'wall_labels', {cfg.real.wall_labels}, 'low', low, 'high', high, ...
    'provenance', provenance);

  input_dir = fullfile(here, 'input');
  if ~exist(input_dir, 'dir')
    mkdir(input_dir);
  end
  save(fullfile(input_dir, 'cell.mat'), 'cell_data', 'provenance', '-v7');
end

%% ==================== Cell generation helpers ====================
% These helpers construct one frozen level and its deterministic metadata.

function level = LOCAL_build_level(spec, cfg, pars1, channels, kint)
  [C, curvelen] = geom.construct_cont(spec.ntot, 'circle', 0, 0, cfg.real.R);
  proxy_spec = struct('H', cfg.real.proxy_H, ...
    'proxy_dist', cfg.real.proxy_dist, 'N_side', spec.N_side, ...
    'N_top', spec.N_top, 'N_proxy_edge', spec.N_proxy_edge, ...
    'M_pw', spec.M_pw);
  proxy = kernel.precomp_proxy(pars1, proxy_spec);
  cell_result = bloch.construct_S(C, cfg.real.k, kint, pars1, proxy, ...
    curvelen, channels, cfg.real.X_L, cfg.real.X_R);
  K = channels.K;
  blocks = struct();
  blocks.R_L = cell_result.R_L;
  blocks.T_RL = cell_result.T_RL;
  blocks.T_LR = cell_result.T_LR;
  blocks.R_R = cell_result.R_R;
  blocks.S = cell_result.S;
  blocks.A_sc = [-blocks.R_L, eye(K); blocks.T_LR, zeros(K)];
  blocks.B_sc = [zeros(K), blocks.T_RL; eye(K), -blocks.R_R];
  level = struct('ntot', spec.ntot, 'proxy', proxy_spec, ...
    'blocks', blocks, 'modes', channels, ...
    'wall_labels', {cfg.real.wall_labels}, ...
    'bie_residual', cell_result.solve_residual_norm, ...
    'bie_relative_residual', cell_result.solve_relative_residual_norm);
end

function value = LOCAL_sha256(path)
  fid = fopen(path, 'r');
  if fid < 0
    error('make_cell:HashReadFailure', 'Cannot read source file %s.', path);
  end
  cleanup = onCleanup(@() fclose(fid));
  bytes = fread(fid, Inf, '*uint8');
  digest = javaMethod('getInstance', ...
    'java.security.MessageDigest', 'SHA-256');
  digest.update(typecast(bytes(:), 'int8'));
  raw = typecast(digest.digest(), 'uint8');
  value = lower(reshape(dec2hex(raw, 2).', 1, []));
  clear cleanup;
end

function path = LOCAL_source_path(path)
  if ~isfile(path) && isfile([path, '.m'])
    path = [path, '.m'];
  end
  if ~isfile(path)
    error('make_cell:SourcePathFailure', ...
      'Cannot resolve source file %s.', path);
  end
end
