function out = betagmode()
%BETAGMODE Scan a fixed local k interval for a beta-formulation guided mode.
% For each k, ordered QZ subspaces give the half-guide DtN maps Lambda_+
% and Lambda_-. The script forms
%
%   A_def = [-(i*Gamma+Lambda_-), (i*Gamma-Lambda_-)*E;
%            (i*Gamma-Lambda_+)*E, -(i*Gamma+Lambda_+)]
%
% and its physically weighted form A_phys = D_r*A_def*D_c. The reported k
% minimizes sigma_min(A_phys)/sigma_max(A_phys) on the fine discretization.
%
% INPUT:
%   None.
%
% OUTPUT:
%   out - Struct containing the local guided-mode candidate:
%     beta          - Fixed y-quasiperiodic parameter.
%     k             - Wavenumber attaining the smallest fine A_phys ratio.
%     adef_sigma    - 1-by-2 coarse/fine sigma_min(A_def) values.
%     adef_ratio    - 1-by-2 coarse/fine sigma_min/sigma_max for A_def.
%     aphys_sigma   - 1-by-2 coarse/fine sigma_min(A_phys) values.
%     aphys_ratio   - 1-by-2 coarse/fine sigma_min/sigma_max for A_phys.
%     runtime       - Total elapsed time in seconds.

  tstart = tic;
  beta = 0.5;
  model = struct('beta',beta,'d',1,'R',0.2,'epsrel',17, ...
    'XL',-0.5,'XR',0.5,'H',1.1,'pdist',0.2);

  % MFS boundary and proxy discretizations.
  coarse = struct('ntot',160,'nside',120,'ntop',120, ...
    'nproxy',64,'mpw',24);
  fine = struct('ntot',256,'nside',160,'ntop',160, ...
    'nproxy',80,'mpw',32);

  % Fixed Rayleigh order and uniform local scan.
  M = 48;
  kmin = 1.8327690124511717;
  dk = 1.9073486328125e-7;
  kvals = kmin+(0:10)*dk;

  nk = numel(kvals);
  asig = zeros(nk,2);
  arat = zeros(nk,2);
  psig = zeros(nk,2);
  prat = zeros(nk,2);
  for j = 1:nk
    [asig(j,1),arat(j,1),psig(j,1),prat(j,1)] = ...
      LOCAL_point(kvals(j),M,model,coarse);
    [asig(j,2),arat(j,2),psig(j,2),prat(j,2)] = ...
      LOCAL_point(kvals(j),M,model,fine);
  end

  [~,jmin] = min(prat(:,2));
  runtime = toc(tstart);
  out = struct('beta',beta,'k',kvals(jmin), ...
    'adef_sigma',asig(jmin,:),'adef_ratio',arat(jmin,:), ...
    'aphys_sigma',psig(jmin,:),'aphys_ratio',prat(jmin,:), ...
    'runtime',runtime);
end

%% ==================== Point evaluation ====================
% These helpers build and score the two defect matrices at one wavenumber.

function [asig,arat,psig,prat] = LOCAL_point(k,M,model,cfg)
%LOCAL_POINT Local guided-mode point evaluation.
% Build A_def and A_phys, then return both minimum singular values and ratios.

  [Zp,Zm,bm,gamma,phase] = LOCAL_cellsub(k,M,model,cfg);
  [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma);
  G = diag(gamma);
  E = diag(phase);
  Adef = [-(1i*G+Lm),(1i*G-Lm)*E; ...
    (1i*G-Lp)*E,-(1i*G+Lp)];

  b = sqrt(1+abs(bm).^2);
  rowwt = repmat(sqrt(1./b),2,1);
  ampwt = b+abs(gamma).^2./b;
  colwt = repmat(1./sqrt(ampwt),2,1);
  Aphys = rowwt.*Adef.*colwt.';

  % 'econ' requests economy-size SVD; 'ascend' orders values from min to max.
  sval = sort(svd(Adef,'econ'),'ascend');
  asig = sval(1);
  arat = sval(1)/sval(end);
  sval = sort(svd(Aphys,'econ'),'ascend');
  psig = sval(1);
  prat = sval(1)/sval(end);
end

%% ==================== Half-guide construction ====================
% These helpers extract decaying subspaces and form their DtN maps.

function [Zp,Zm,bm,gamma,phase] = LOCAL_cellsub(k,M,model,cfg)
%LOCAL_CELLSUB Local cell scattering subspaces.
% Build the cell pencil and extract decaying subspaces in both directions.

  pars = struct('k',k,'beta',model.beta,'d',model.d, ...
    'periodic_axis','y');
  chans = bloch.rayleigh_channels( ...
    k,model.beta,model.d,M,model.XR-model.XL);
  [C,curvelen] = geom.construct_cont(cfg.ntot,'circle',0,0,model.R);
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
%LOCAL_QZSUB Local generalized-Schur subspace extraction.
% Order projective QZ pairs strictly inside the unit circle.

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

  [~,~,~,Zo] = ordqz(S,T,Q,Z,stable);
  Zs = Zo(:,1:K); % TODO: check if #stable == K?
end

function [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma)
%LOCAL_DTN Local Dirichlet-to-Neumann map construction.
% Convert the two decaying QZ subspaces directly into half-guide DtN maps.

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
