function data = make_prod(kind)
%MAKE_PROD Generate direct M=12 pilot or M=48 production one-cell maps.
% Purpose:
%   Construct coarse/fine scattering blocks with MATLAB lsqminnorm while
%   preserving direct output bandwidth; no central restriction is used.
% Input:
%   kind - 'pilot' for M=12 or 'full' for M=48.
% Output:
%   data - frozen maps, timings, physical snapshot, and source provenance.

  if nargin < 1
    kind = 'pilot';
  end
  if exist('OCTAVE_VERSION','builtin') ~= 0
    error('make_prod:MATLABRequired','MATLAB is required.');
  end
  solver = which('lsqminnorm');
  if isempty(solver)
    error('make_prod:LsqminnormRequired','lsqminnorm is required.');
  end
  cfg = prod_cfg();
  if strcmp(kind,'pilot')
    M = cfg.pilot_M;
    filename = 'prod12.mat';
  elseif strcmp(kind,'full')
    M = cfg.prod_M;
    filename = 'prod48.mat';
  else
    error('make_prod:Kind','kind must be pilot or full.');
  end
  here = fileparts(mfilename('fullpath'));
  repo = fileparts(fileparts(fileparts(here)));
  addpath(repo);
  pars = struct('k',cfg.k,'beta',cfg.beta,'d',cfg.d,'periodic_axis','y');
  channels = bloch.rayleigh_channels(cfg.k,cfg.beta,cfg.d,M,cfg.X_R-cfg.X_L);
  kint = sqrt(1+16*cfg.s)*cfg.k;
  all_timer = tic;
  coarse = LOCAL_level(cfg.coarse,cfg,pars,channels,kint);
  fine = LOCAL_level(cfg.fine,cfg,pars,channels,kint);

  provenance = LOCAL_provenance(here,repo,solver);
  physical = struct('k',cfg.k,'beta',cfg.beta,'d',cfg.d,'R',cfg.R, ...
    'X_L',cfg.X_L,'X_R',cfg.X_R,'s',cfg.s,'proxy_dist',cfg.proxy_dist, ...
    'H',cfg.H,'M',M,'K',2*M+1);
  data = struct('schema','HG_ADEF_PROD_V1','kind',kind,'physical',physical, ...
    'wall_labels',{{'LEFT_CELL_WALL','RIGHT_CELL_WALL'}}, ...
    'coarse',coarse,'fine',fine,'provenance',provenance, ...
    'total_seconds',toc(all_timer));
  input_dir = fullfile(here,'input');
  if ~exist(input_dir,'dir')
    mkdir(input_dir);
  end
  save(fullfile(input_dir,filename),'data','-v7.3');
  fprintf('MAKE_PROD_KIND=%s M=%d seconds=%.6g\n',kind,M,data.total_seconds);
end

%% ==================== Direct cell construction ====================
% These helpers build one level and immutable provenance.

function level = LOCAL_level(spec,cfg,pars,channels,kint)
  timer = tic;
  [C,curvelen] = geom.construct_cont(spec.ntot,'circle',0,0,cfg.R);
  proxy_spec = struct('H',cfg.H,'proxy_dist',cfg.proxy_dist, ...
    'N_side',spec.N_side,'N_top',spec.N_top, ...
    'N_proxy_edge',spec.N_proxy_edge,'M_pw',spec.M_pw);
  proxy = kernel.precomp_proxy(pars,proxy_spec);
  cell_result = bloch.construct_S(C,cfg.k,kint,pars,proxy,curvelen, ...
    channels,cfg.X_L,cfg.X_R);
  K = channels.K;
  blocks = struct('R_L',cell_result.R_L,'T_RL',cell_result.T_RL, ...
    'T_LR',cell_result.T_LR,'R_R',cell_result.R_R);
  blocks.A_sc = [-blocks.R_L,eye(K);blocks.T_LR,zeros(K)];
  blocks.B_sc = [zeros(K),blocks.T_RL;eye(K),-blocks.R_R];
  level = struct('spec',spec,'proxy',proxy_spec,'modes',channels, ...
    'blocks',blocks,'wall_labels',{{'LEFT_CELL_WALL','RIGHT_CELL_WALL'}}, ...
    'solve_residual',cell_result.solve_relative_residual_norm, ...
    'seconds',toc(timer));
end

function p = LOCAL_provenance(here,repo,solver)
  [status,sha] = system(sprintf('git -C "%s" rev-parse HEAD',repo));
  if status ~= 0
    error('make_prod:Git','Cannot record Git SHA.');
  end
  paths = struct('make_prod',LOCAL_source_path(mfilename('fullpath')), ...
    'prod_cfg',fullfile(here,'prod_cfg.m'), ...
    'run_prod',fullfile(here,'run_prod.m'), ...
    'precomp_proxy',which('kernel.precomp_proxy'), ...
    'construct_S',which('bloch.construct_S'));
  names = fieldnames(paths);
  hashes = struct();
  for j = 1:numel(names)
    hashes.(names{j}) = LOCAL_hash(paths.(names{j}));
  end
  p = struct('runtime','MATLAB','version',version,'solver','lsqminnorm', ...
    'solver_path',solver,'git_sha',strtrim(sha),'source_paths',paths, ...
    'source_hashes',hashes,'fallbacks',0,'silent_rank_changes',0, ...
    'generated_utc',char(datetime('now','TimeZone','UTC', ...
    'Format','yyyy-MM-dd''T''HH:mm:ss''Z''')));
end

function value = LOCAL_hash(path)
  fid = fopen(path,'r');
  if fid < 0
    error('make_prod:Hash','Cannot read %s.',path);
  end
  cleanup = onCleanup(@() fclose(fid));
  bytes = fread(fid,Inf,'*uint8');
  digest = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
  digest.update(typecast(bytes(:),'int8'));
  raw = typecast(digest.digest(),'uint8');
  value = lower(reshape(dec2hex(raw,2).',1,[]));
  clear cleanup;
end

function path = LOCAL_source_path(path)
  if ~isfile(path) && isfile([path,'.m'])
    path = [path,'.m'];
  end
  if ~isfile(path)
    error('make_prod:Source','Cannot resolve %s.',path);
  end
end
