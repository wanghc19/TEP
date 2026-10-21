function [out,scan] = locate_i7(kmin,dk,nk)
%LOCATE_I7 Evaluate one uniform fine-config grid for the I7 local minimum.
% Purpose:
%   Evaluate the frozen I7 center-ellipse model on exactly
%   kmin+(0:nk-1)*dk and return the grid minimum of aphys_ratio.
% Input:
%   kmin - First wavenumber.
%   dk   - Positive uniform grid spacing.
%   nk   - Positive integer number of grid points.
% Output:
%   out  - Seven scalar result fields matching scan_i7.
%   scan - Table with k and the four singular-value metrics at every point.
% Main algorithm:
%   Use only the frozen fine spatial configuration and M=48 at every point.
% Based on:
%   test/i7/scan-v1/scan_i7.m and draft/examples/betagmode.m on main.
% Main changes:
%   Remove gap classification, screening, caching, and adaptive refinement.
% Numerical goal:
%   Provide a reproducible local uniform-grid locator without hidden work.

  if nargin ~= 3 || ~isscalar(kmin) || ~isreal(kmin) || ~isfinite(kmin) || ...
      ~isscalar(dk) || ~isreal(dk) || ~isfinite(dk) || dk <= 0 || ...
      ~isscalar(nk) || ~isreal(nk) || ~isfinite(nk) || ...
      nk < 1 || nk ~= fix(nk)
    error('i7:Arguments', ...
      'Pass finite real scalar kmin, positive dk, and positive integer nk.');
  end

  tstart = tic;
  beta = 0.5;
  model = struct('beta',beta,'d',1,'R',0.2,'epsrel',17, ...
    'epsrel_center',2,'XL',-0.5,'XR',0.5,'H',1.1,'pdist',0.2, ...
    'flag_geom','ellipse','ellipse_axes',[0.25,0.16]);
  cfg = struct('ntot',256,'nside',160,'ntop',160, ...
    'nproxy',80,'mpw',32);
  M = 48;
  k = kmin+(0:nk-1)'*dk;
  adef_sigma = zeros(nk,1);
  adef_ratio = zeros(nk,1);
  aphys_sigma = zeros(nk,1);
  aphys_ratio = zeros(nk,1);
  warning_guard = LOCAL_solver_warning_guard();

  for j = 1:nk
    point_timer = tic;
    lastwarn('');
    [adef_sigma(j),adef_ratio(j),aphys_sigma(j),aphys_ratio(j)] = ...
      LOCAL_point(k(j),M,model,cfg);
    [warn_message,warn_id] = lastwarn;
    if ~isempty(warn_message)
      error('i7:PointWarning','k=%.17g warning %s: %s', ...
        k(j),warn_id,warn_message);
    end
    if ~all(isfinite([adef_sigma(j),adef_ratio(j), ...
        aphys_sigma(j),aphys_ratio(j)]))
      error('i7:NonfiniteMetric','k=%.17g produced a nonfinite metric.',k(j));
    end
    fprintf(1,'k=%.17g aphys_ratio=%.17g seconds=%.3f\n', ...
      k(j),aphys_ratio(j),toc(point_timer));
  end
  clear warning_guard;

  scan = table(k,adef_sigma,adef_ratio,aphys_sigma,aphys_ratio);
  [~,jmin] = min(aphys_ratio);
  runtime = toc(tstart);
  out = struct('beta',beta,'k',k(jmin), ...
    'adef_sigma',adef_sigma(jmin),'adef_ratio',adef_ratio(jmin), ...
    'aphys_sigma',aphys_sigma(jmin),'aphys_ratio',aphys_ratio(jmin), ...
    'runtime',runtime);
end

%% ==================== Point evaluation ====================
% These helpers construct and score the lead-center matching matrix.

function [asig,arat,psig,prat] = LOCAL_point(k,M,model,cfg)
%LOCAL_POINT Evaluate four singular-value metrics at one configuration.

  [Zp,Zm,bm,gamma] = LOCAL_cellsub(k,M,model,cfg);
  [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma);
  cellmap = LOCAL_center(k,M,model,cfg);
  G = diag(gamma);
  Adef = [(1i*G-Lm)*cellmap.R_L-(1i*G+Lm), ...
    (1i*G-Lm)*cellmap.T_RL; ...
    (1i*G-Lp)*cellmap.T_LR, ...
    (1i*G-Lp)*cellmap.R_R-(1i*G+Lp)];

  b = sqrt(1+abs(bm).^2);
  rowwt = repmat(sqrt(1./b),2,1);
  ampwt = b+abs(gamma).^2./b;
  colwt = repmat(1./sqrt(ampwt),2,1);
  Aphys = rowwt.*Adef.*colwt.';

  sval = sort(svd(Adef,'econ'),'ascend');
  asig = sval(1);
  arat = sval(1)/sval(end);
  sval = sort(svd(Aphys,'econ'),'ascend');
  psig = sval(1);
  prat = sval(1)/sval(end);
end

function cellmap = LOCAL_center(k,M,model,cfg)
%LOCAL_CENTER Construct the epsrel=2 elliptical center scattering matrix.

  pars = struct('k',k,'beta',model.beta,'d',model.d, ...
    'periodic_axis','y','h2d_evaluator',@LOCAL_h2d_chunked_public);
  chans = bloch.rayleigh_channels( ...
    k,model.beta,model.d,M,model.XR-model.XL);
  [C,curvelen] = geom.construct_cont(cfg.ntot,model.flag_geom,0,0, ...
    model.ellipse_axes);
  mfscfg = struct('H',model.H,'proxy_dist',model.pdist, ...
    'N_side',cfg.nside,'N_top',cfg.ntop, ...
    'N_proxy_edge',cfg.nproxy,'M_pw',cfg.mpw);
  proxy = kernel.precomp_proxy(pars,mfscfg);
  kint = sqrt(model.epsrel_center)*k;
  cellmap = bloch.construct_S(C,k,kint,pars,proxy,curvelen,chans, ...
    model.XL,model.XR);
end

%% ==================== Half-guide construction ====================
% These helpers retain the circular lead, ordered QZ, and DtN conventions.

function [Zp,Zm,bm,gamma,phase] = LOCAL_cellsub(k,M,model,cfg)
%LOCAL_CELLSUB Build the unchanged circular half-guide subspaces.

  pars = struct('k',k,'beta',model.beta,'d',model.d, ...
    'periodic_axis','y','h2d_evaluator',@LOCAL_h2d_chunked_public);
  chans = bloch.rayleigh_channels( ...
    k,model.beta,model.d,M,model.XR-model.XL);
  flag_geom = 'circle';
  [C,curvelen] = geom.construct_cont(cfg.ntot,flag_geom,0,0,model.R);
  mfscfg = struct('H',model.H,'proxy_dist',model.pdist, ...
    'N_side',cfg.nside,'N_top',cfg.ntop, ...
    'N_proxy_edge',cfg.nproxy,'M_pw',cfg.mpw);
  proxy = kernel.precomp_proxy(pars,mfscfg);
  kint = sqrt(model.epsrel)*k;
  cellmap = bloch.construct_S(C,k,kint,pars,proxy,curvelen,chans, ...
    model.XL,model.XR);

  K = chans.K;
  A = [-cellmap.R_L,eye(K);cellmap.T_LR,zeros(K)];
  B = [zeros(K),cellmap.T_RL;eye(K),-cellmap.R_R];
  Zp = LOCAL_qzsub(A,B,K);
  Zm = LOCAL_qzsub(B,A,K);
  bm = chans.beta_m(:);
  gamma = chans.gamma_m(:);
  phase = chans.phase(:);
end

function Zs = LOCAL_qzsub(A,B,K)
%LOCAL_QZSUB Extract a qualified strictly stable generalized-Schur subspace.

  rho = hypot(norm(A,'fro'),norm(B,'fro'));
  if ~isfinite(rho) || rho == 0
    error('i7:QZScale','The QZ pencil scale is zero or nonfinite.');
  end
  A = A/rho;
  B = B/rho;
  [S,T,Q,Z] = qz(A,B,'complex');
  res = hypot(norm(A-Q'*S*Z','fro'),norm(B-Q'*T*Z','fro'));
  tol = max(100*eps,10*res);

  alpha = diag(S);
  theta = diag(T);
  scale = hypot(abs(alpha),abs(theta));
  indet = scale <= tol;
  scale(indet) = 1;
  an = abs(alpha)./scale;
  tn = abs(theta)./scale;
  infinite = ~indet & tn <= tol & an > tol;
  neutral = ~indet & ~infinite & abs(an-tn) <= tol;
  stable = ~indet & ~infinite & ~neutral & an < tn-tol;
  unstable = infinite | (~indet & ~neutral & an > tn+tol);

  if sum(stable) ~= K || sum(unstable) ~= K || ...
      any(indet) || any(neutral)
    error('i7:QZClassification', ...
      'stable=%d unstable=%d neutral=%d indet=%d expected stable=unstable=%d.', ...
      sum(stable),sum(unstable),sum(neutral),sum(indet),K);
  end
  [~,~,~,Zo] = ordqz(S,T,Q,Z,stable);
  Zs = Zo(:,1:K);
end

function [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma)
%LOCAL_DTN Convert the two qualified half-guide subspaces to DtN maps.

  K = numel(gamma);
  G = diag(gamma);
  Ap = Zp(1:K,:);
  Bp = Zp(K+1:end,:);
  Am = Zm(1:K,:);
  Bm = Zm(K+1:end,:);
  Dp = Ap+Bp;
  Np = 1i*G*(Ap-Bp);
  Dm = Am+Bm;
  Nm = -1i*G*(Am-Bm);
  Lp = (Dp.'\Np.').';
  Lm = (Dm.'\Nm.').';
end

%% ==================== Kernel and warning helpers ====================
% These helpers bound proxy-source allocations and reject solver warnings.

function [pot,grad,hess] = LOCAL_h2d_chunked_public( ...
    wavek,sources,charge,targ)
%LOCAL_H2D_CHUNKED_PUBLIC Call the public kernel on contiguous target batches.
% Passing too many targets at once creates large target-by-source temporary
% arrays in the public kernel and can consume substantial memory.

  nt = size(targ,2);
  pot = zeros(1,nt);
  grad = zeros(2,nt);
  hess = zeros(3,nt);
  target_batch = 512;
  for first = 1:target_batch:nt
    index = first:min(first+target_batch-1,nt);
    [pot(:,index),grad(:,index),hess(:,index)] = ...
      kernel.h2d_directch(wavek,sources,charge,targ(:,index));
  end
end

function cleanup = LOCAL_solver_warning_guard()
  state = warning;
  cleanup = onCleanup(@() warning(state));
  warning('error','MATLAB:singularMatrix');
  warning('error','MATLAB:nearlySingularMatrix');
  warning('error','MATLAB:illConditionedMatrix');
  warning('error','MATLAB:rankDeficientMatrix');
end
