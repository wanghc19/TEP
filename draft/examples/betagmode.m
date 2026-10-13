function out = betagmode()
%BETAGMODE Scan a fixed local k interval for a beta-formulation guided mode.
% For each k, ordered QZ subspaces give the half-guide DtN maps Lambda_+
% and Lambda_-. The script forms
%
%   A_def = [-(i*Gamma+Lambda_-), (i*Gamma-Lambda_-)*E;
%            (i*Gamma-Lambda_+)*E, -(i*Gamma+Lambda_+)]
%
% and its physically weighted form A_phys = D_r*A_def*D_c. The reported k
% minimizes sigma_min(A_phys)/sigma_max(A_phys) over this sampled grid on
% the fine discretization. Proxy kernels are evaluated in target batches.
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
  kmin = 1.8327702889218924;
  dk = 9.3132279666008344e-11;
  kvals = kmin+(0:4)*dk;

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
  [RL,TLR,TRL,RR] = LOCAL_construct_S(C,k,kint,proxy, ...
    curvelen,chans,model.XL,model.XR);

  K = chans.K;
  A = [-RL,eye(K);TLR,zeros(K)];
  B = [zeros(K),TRL;eye(K),-RR];
  Zp = LOCAL_qzsub(A,B,K);
  Zm = LOCAL_qzsub(B,A,K);
  bm = chans.beta_m(:);
  gamma = chans.gamma_m(:);
  phase = chans.phase(:);
end

function [Zs,P] = LOCAL_qzsub(A,B,K)
%LOCAL_QZSUB Local generalized-Schur subspace extraction.
% Order decaying QZ pairs and optionally return their full propagation matrix.

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

  [So,To,~,Zo] = ordqz(S,T,Q,Z,stable);
  Zs = Zo(:,1:K); % TODO: check if #stable == K?
  if nargout > 1
    P = To(1:K,1:K)\So(1:K,1:K);
  end
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

%% ==================== Circle cell ====================
% These helpers construct cell scattering blocks with bounded proxy batches.

function [RL,TLR,TRL,RR,HL,HR] = LOCAL_construct_S( ...
    C,kout,kin,proxy,curvelen,chans,XL,XR)
%LOCAL_CONSTRUCT_S Local cell scattering matrix construction.
% Script-local counterpart of bloch.construct_S; return four scattering blocks
% and, when requested, the two density maps needed for field reconstruction.

  Aq = LOCAL_construct_A_QP(C,kout,kin,proxy,curvelen);
  [BL,BR] = bloch.incident_rhs(C,chans,XL,XR);
  [FL,FR] = bloch.farfield_extractors(C,chans,XL,XR,curvelen);
  Hall = -(Aq\[BL,BR]);
  K = chans.K;
  HL = Hall(:,1:K);
  HR = Hall(:,K+1:end);
  E = diag(chans.phase(:));
  RL = FL*HL;
  TLR = E+FR*HL;
  TRL = E+FL*HR;
  RR = FR*HR;
end

function Aq = LOCAL_construct_A_QP(C,kout,kin,proxy,curvelen)
%LOCAL_CONSTRUCT_A_QP Local quasi-periodic Muller matrix construction.
% Script-local counterpart of op.construct_A_QP, valid only for this example's
% fixed geometry and parameters. Combine Kress differences with proxy kernels.

  N = size(C,2);
  hq = curvelen/N;
  x = C(1,:);
  y = C(4,:);
  xt = C(2,:);
  yt = C(5,:);
  speed = sqrt(xt.^2+yt.^2).';
  nx = (yt./speed.').';
  ny = (-xt./speed.').';
  gd = struct('z',[x.',y.'],'zp',[xt.',yt.'], ...
    'zpp',[C(3,:).',C(6,:).'],'speed',speed);
  [t,D] = utils.triginterp(N);
  rvec = quad.quad_kress_rvec(N);
  ridx = mod((0:N-1)-(0:N-1).',N)+1;
  Rk = rvec(ridx);

  % Here 2*R = 0.4 < d/2 = 0.5 and H = 1.1, so every displacement
  % lies in the central proxy strip without periodic folding or phase.
  dx = x.'-x;
  dy = y.'-y;
  [pot,gc,hc] = LOCAL_h2d_directch(kout,proxy.Z,proxy.q,[dy(:).';dx(:).']);
  gx = reshape(gc(2,:),N,N);
  gy = reshape(gc(1,:),N,N);
  hxx = reshape(hc(3,:),N,N);
  hxy = reshape(hc(2,:),N,N);
  hyy = reshape(hc(1,:),N,N);
  wt = hq*speed.';
  P11 = -(gx.*nx.'+gy.*ny.').*wt;
  P22 = -(gx.*nx+gy.*ny).*wt;
  P12 = -reshape(pot,N,N).*wt;
  P21 = -(hxx.*(nx*nx.')+hxy.*(nx*ny.'+ny*nx.')+ ...
    hyy.*(ny*ny.')).*wt;

  [Li1,Li2,Lsi1,Lsi2] = kernel.kress_l_splits(kin,t,gd);
  [Lo1,Lo2,Lso1,Lso2] = kernel.kress_l_splits(kout,t,gd);
  A11 = Rk.*(Lo1-Li1)+hq*(Lo2-Li2)+P11;
  A22 = Rk.*(Lsi1-Lso1)+hq*(Lsi2-Lso2)+P22;
  clear Li1 Li2 Lsi1 Lsi2 Lo1 Lo2 Lso1 Lso2 P11 P22

  [Mi1,Mi2,Ni1,Ni2] = kernel.kress_mn_splits(kin,t,gd);
  [Mo1,Mo2,No1,No2] = kernel.kress_mn_splits(kout,t,gd);
  A12 = Rk.*(Mi1-Mo1)+hq*(Mi2-Mo2)+P12;
  tang = (gd.zp*gd.zp.')./(speed*speed.');
  T0 = (Rk.*(kout^2*Mo1-kin^2*Mi1)+ ...
    hq*(kout^2*Mo2-kin^2*Mi2)).*tang;
  Tb = Rk.*(No1-Ni1)+hq*(No2-Ni2);
  A21 = T0+bsxfun(@rdivide,Tb,speed)*D+P21;
  Aq = [eye(N)+A11,A12;A21,eye(N)+A22];
  sr = sqrt(hq*[speed;speed]);
  sc = sqrt((1/hq)./[speed;speed]);
  Aq = sr.*Aq.*sc.';
end

function [pot,grad,hess] = LOCAL_h2d_directch(wavek,sources,charge,targ)
%LOCAL_H2D_DIRECTCH Local two-dimensional Helmholtz direct charge evaluation.
% Batch target points while retaining the public kernel's full source sum.

  nt = size(targ,2);
  pot = complex(zeros(1,nt));
  grad = complex(zeros(2,nt));
  hess = complex(zeros(3,nt));
  batch = 512;
  for first = 1:batch:nt
    ids = first:min(first+batch-1,nt);
    [pot(:,ids),grad(:,ids),hess(:,ids)] = ...
      kernel.h2d_directch(wavek,sources,charge,targ(:,ids));
  end
end
