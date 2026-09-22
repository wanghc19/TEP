function out = projgap()
%PROJGAP Scan the fixed-beta perfect cell for EMPIRICAL projected-gap intervals.
% For each real wavenumber k, form the generalized eigenvalue problem
%
%   A*z = lambda*B*z,
%   A = [-R_L, I; T_LR, 0],  B = [0, T_RL; I, -R_R].
%
% The QZ decomposition represents each Bloch multiplier as a pair
% (alpha_j,theta_j), where lambda_j = alpha_j/theta_j. A sampled k is
% in a numerical projected gap when no multiplier satisfies |lambda_j| = 1
% and exactly K multipliers decay in each x direction.
%
% INPUT:
%   None.
%
% OUTPUT:
%   out - Struct containing the sampled projected-gap result:
%     beta    - Fixed y-quasiperiodic parameter.
%     k       - 1-by-N row vector of sampled real wavenumbers.
%     gap     - G-by-2 array of sampled gap windows. Interior endpoints are
%               midpoints between adjacent gap and non-gap samples. An
%               endpoint equal to the scan limit is not a computed band edge.

  % Physical model and lead cell.
  beta = 0.5;
  d = 1;
  R = 0.2;
  epsrel = 17;
  XL = -0.5;
  XR = 0.5;

  % MFS boundary and proxy discretization.
  ntot = 160;
  H = 1.1;
  pdist = 0.2;
  nside = 120;
  ntop = 120;
  nproxy = 64;
  mpw = 24;
  mfscfg = struct('H',H,'proxy_dist',pdist,'N_side',nside, ...
    'N_top',ntop,'N_proxy_edge',nproxy,'M_pw',mpw);

  % Projected-gap sampling.
  M = 12; % order of Rayleigh expansion on artificial walls
  kvals = 1.45:0.05:2.25;

  [C,curvelen] = geom.construct_cont(ntot,'circle',0,0,R);
  nk = numel(kvals);
  ingap = false(1,nk);

  for j = 1:nk
    k = kvals(j);
    pars = struct('k',k,'beta',beta,'d',d,'periodic_axis','y');
    proxy = kernel.precomp_proxy(pars,mfscfg);
    chans = bloch.rayleigh_channels(k,beta,d,M,XR-XL);
    kint = sqrt(epsrel)*k;
    cellmap = bloch.construct_S(C,k,kint,pars,proxy,curvelen,chans,XL,XR);
    K = chans.K;
    A = [-cellmap.R_L,eye(K);cellmap.T_LR,zeros(K)];
    B = [zeros(K),cellmap.T_RL;eye(K),-cellmap.R_R];
    ingap(j) = LOCAL_ingap(A,B,K);
  end

  gap = LOCAL_gapwins(kvals,ingap);
  out = struct('beta',beta,'k',kvals,'gap',gap);
end

%% ==================== Classification helpers ====================
% These helpers classify projective QZ pairs and collect sampled gaps.

function ingap = LOCAL_ingap(A,B,K)
%LOCAL_INGAP Local projected-gap membership test.
% Classify generalized-Schur (QZ) pairs and return the sampled gap flag.

  rho = hypot(norm(A,'fro'),norm(B,'fro'));
  A = A/rho;
  B = B/rho;
  [S,T,Q,Z] = qz(A,B,'complex');
  res = hypot(norm(A-Q'*S*Z','fro'),norm(B-Q'*T*Z','fro'));
  tol = max(100*eps,10*res);

  alpha = diag(S);
  theta = diag(T);
  scale = hypot(abs(alpha),abs(theta));
  indet = scale <= tol;  % 0/0, indeterminate
  scale(indet) = 1;
  an = abs(alpha)./scale;
  tn = abs(theta)./scale;
  infinite = ~indet & tn <= tol & an > tol;
  neutral = ~indet & ~infinite & abs(an-tn) <= tol;
  stable = ~indet & ~infinite & ~neutral & an < tn-tol;
  unstable = infinite | (~indet & ~neutral & an > tn+tol);

  ingap = ~any(neutral) && ~any(indet) && ...
    sum(stable) == K && sum(unstable) == K;
end

function gap = LOCAL_gapwins(kvals,ingap)
%LOCAL_GAPWINS Local projected-gap window construction.
% Group consecutive gap samples and estimate their interval endpoints.

  edge = diff([false,ingap,false]);
  first = find(edge == 1);
  last = find(edge == -1)-1;
  ngap = numel(first);
  gap = zeros(ngap,2);

  for j = 1:ngap
    if first(j) == 1
      gap(j,1) = kvals(1);
    else
      gap(j,1) = 0.5*(kvals(first(j)-1)+kvals(first(j)));
    end
    if last(j) == numel(kvals)
      gap(j,2) = kvals(end);
    else
      gap(j,2) = 0.5*(kvals(last(j))+kvals(last(j)+1));
    end
  end
end
