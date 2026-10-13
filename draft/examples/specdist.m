function out = specdist()
%SPECDIST Estimate the fixed-beta spectral distance numerically.
% Under the exact-field interface estimate, with mu = k^2,
%
%   dist(mu,sigma(A(beta))) <= 2*mu*C*eps_bd/(U-C*eps_bd).
%
% Here U is the full weighted field norm and
%
%   eps_bd^2 = sum_Gamma (||j_Gamma||_L2^2
%              + ell^(-2)*||a_Gamma||_L2^2),
%
% where a_Gamma and j_Gamma are the value and ordinary-normal jumps.
% The trace constant C is explicit. Here h is the collar half-width,
% kappa_max is the curvature bound, N_ov is the maximum collar overlap,
% rho_min/rho_max bound the material, ell is the reference length,
% theta = 1-h*kappa_max, c0 = N_ov/(theta*h), and
% c1 = N_ov*h/(2*theta):
%
%   C^2 = c0/(rho_min*mu^2) + (c1+ell^2*c0)/(4*mu)
%         + ell^2*c1*rho_max.
%
% This example evaluates the right-hand side in ordinary double precision
% for a fixed guided-mode candidate. An independent circle action estimates
% the material jumps, a wider finite Rayleigh expansion estimates the
% vertical-wall jumps, and full propagation matrices retain the infinite
% lead tails. The center mass U0 satisfies U0 <= U and is used conservatively
% in place of U; the displayed value requires U0 > C*eps_bd. The result is a
% numerical formula evaluation, not a certified upper bound.
%
% INPUT:
%   None.
%
% OUTPUT:
%   out - Struct containing the numerical spectral-distance estimate:
%     beta     - Fixed y-quasiperiodic parameter.
%     k        - Fixed guided-mode candidate wavenumber.
%     C        - Explicit trace constant evaluated at mu = k^2.
%     epsjump  - Numerical estimate of the combined weighted jump norm.
%     mass     - L2 norm of the same field in the empty center cell.
%     dist     - Numerical value of 2*mu*C*epsjump/(mass-C*epsjump).
%     runtime  - Total elapsed time in seconds.

  tstart = tic;

  % Fixed physical model and candidate.
  beta = 0.5;
  k = 1.832770289108157;
  d = 1;
  R = 0.2;
  epsrel = 17;
  XL = -0.5;
  XR = 0.5;

  % MFS and Rayleigh discretization used to reconstruct the field.
  ntot = 256;
  H = 1.1;
  pdist = 0.2;
  nside = 160;
  ntop = 160;
  nproxy = 80;
  mpw = 32;
  M = 48;
  mfscfg = struct('H',H,'proxy_dist',pdist,'N_side',nside, ...
    'N_top',ntop,'N_proxy_edge',nproxy,'M_pw',mpw);

  [Csrc,curvelen] = geom.construct_cont(ntot,'circle',0,0,R);
  pars = struct('k',k,'beta',beta,'d',d,'periodic_axis','y');
  proxy = kernel.precomp_proxy(pars,mfscfg);
  chans = bloch.rayleigh_channels(k,beta,d,M,XR-XL);
  kint = sqrt(epsrel)*k;
  [RL,TLR,TRL,RR,HL,HR] = LOCAL_construct_S(Csrc,k,kint,proxy, ...
    curvelen,chans,XL,XR);

  % Ordered QZ subspaces and their full propagation matrices.
  K = chans.K;
  A = [-RL,eye(K);TLR,zeros(K)];
  B = [zeros(K),TRL;eye(K),-RR];
  [Zp,Pp] = LOCAL_qzsub(A,B,K);
  [Zm,Pm] = LOCAL_qzsub(B,A,K);
  Ap = Zp(1:K,:);
  Bp = Zp(K+1:end,:);
  Am = Zm(1:K,:);
  Bm = Zm(K+1:end,:);
  Dp = Ap+Bp;
  Dm = Am+Bm;

  % Physical near-null vector and half-guide coordinates.
  gamma = chans.gamma_m(:);
  phase = chans.phase(:);
  [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma);
  G = diag(gamma);
  E = diag(phase);
  Adef = [-(1i*G+Lm),(1i*G-Lm)*E; ...
    (1i*G-Lp)*E,-(1i*G+Lp)];
  bm = chans.beta_m(:);
  b = sqrt(1+abs(bm).^2);
  rowwt = repmat(sqrt(1./b),2,1);
  ampwt = b+abs(gamma).^2./b;
  colwt = repmat(1./sqrt(ampwt),2,1);
  Aphys = rowwt.*Adef.*colwt.';
  [~,~,V] = svd(Aphys,'econ');
  q = colwt.*V(:,end);
  q = q/norm(q);
  qL = q(1:K);
  qR = q(K+1:end);
  cm = Dm\([eye(K),E]*q);
  cp = Dp\([E,eye(K)]*q);

  % Incoming Rayleigh amplitudes and boundary densities for one lead cell.
  incp = [Ap;Bp*Pp];
  incm = [Am*Pm;Bm];
  Hmap = [HL,HR];
  etap = Hmap*incp;
  etam = Hmap*incm;

  % Independent circle action, wider wall expansion, and lead tail.
  nact = 512;
  mwall = 192;
  jdepth = 32;
  [Cact,actlen] = geom.construct_cont(nact,'circle',0,0,R);
  Aact = LOCAL_construct_A_QP(Cact,k,kint,proxy,actlen);
  [BL,BR] = bloch.incident_rhs(Cact,chans,XL,XR);
  Bact = [BL,BR];
  etap = LOCAL_trigint(etap,nact);
  etam = LOCAL_trigint(etam,nact);
  rp = Aact*etap+Bact*incp;
  rm = Aact*etam+Bact*incm;
  ds = 2*pi*R/nact;
  Fmp = sqrt(ds)*[rp(1:nact,:)/d;rp(nact+1:end,:)];
  Fmm = sqrt(ds)*[rm(1:nact,:)/d;rm(nact+1:end,:)];
  mat2 = LOCAL_seqsum(Fmp,Fmm,Pp,Pm,cp,cm,jdepth);

  [Fwp,Fwm,wall0] = LOCAL_wallfac(Cact,actlen,etap,etam, ...
    incp,incm,Pp,Pm,cp,cm,qL,qR,chans,mwall,XL,XR,d);
  wall2 = wall0+LOCAL_seqsum(Fwp,Fwm,Pp,Pm,cp,cm,jdepth);
  epsjump = sqrt(mat2+wall2);

  % Empty-center mass of the same normalized field.
  mass = LOCAL_mass(qL,qR,bm,k,XR-XL);

  % Explicit trace constant for h = 0.04 and one disjoint collar family.
  mu = k^2;
  h = 0.04;
  ell = d;
  rho_min = 1;
  rho_max = epsrel;
  nov = 1;
  kappa_max = 1/R;
  theta = 1-h*kappa_max;
  c0 = nov/(theta*h);
  c1 = nov*h/(2*theta);
  C = sqrt(c0/(rho_min*mu^2)+(c1+ell^2*c0)/(4*mu)+ ...
    ell^2*c1*rho_max);
  denom = mass-C*epsjump;
  if denom > 0
    dist = 2*mu*C*epsjump/denom;
  else
    dist = Inf;
  end

  runtime = toc(tstart);
  out = struct('beta',beta,'k',k,'C',C,'epsjump',epsjump, ...
    'mass',mass,'dist',dist,'runtime',runtime);
end

%% ==================== Guided field ====================
% These helpers recover the full decaying subspaces and their DtN maps.

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

%% ==================== Interface defects ====================
% These helpers estimate material and wall jumps for the complete field.

function vals = LOCAL_trigint(vals,nout)
%LOCAL_TRIGINT Local trigonometric interpolation.
% Interpolate both density components without splitting the Nyquist mode.

  nin = size(vals,1)/2;
  orders = (-nin/2:nin/2-1).';
  phase = exp(1i*(0:nout-1).'*2*pi/nout*orders.');
  top = fftshift(fft(vals(1:nin,:),[],1),1)/nin;
  bot = fftshift(fft(vals(nin+1:end,:),[],1),1)/nin;
  vals = [phase*top;phase*bot];
end

function [Fp,Fm,single2] = LOCAL_wallfac(Csrc,curvelen,etap,etam, ...
    incp,incm,Pp,Pm,cp,cm,qL,qR,chans,Mw,XL,XR,d)
%LOCAL_WALLFAC Local vertical-wall factors.
% Use a wider Rayleigh basis for both internal walls and center-first walls.

  wide = bloch.rayleigh_channels(chans.k,chans.beta,d,Mw,XR-XL);
  [FL,FR] = bloch.farfield_extractors(Csrc,wide,XL,XR,curvelen);
  Kw = wide.K;
  K = chans.K;
  embed = zeros(Kw,K);
  rows = Mw-chans.M+(1:K);
  embed(rows,:) = eye(K);
  [vLp,dLp,vRp,dRp] = LOCAL_wallmap(FL,FR,wide,embed,etap,incp);
  [vLm,dLm,vRm,dRm] = LOCAL_wallmap(FL,FR,wide,embed,etam,incm);

  Fp = [(vRp-vLp*Pp)/d;dRp-dLp*Pp];
  Fm = [(vLm-vRm*Pm)/d;dLm-dRm*Pm];

  E = diag(chans.phase(:));
  G = 1i*diag(chans.gamma_m(:));
  ucL = embed*(qL+E*qR);
  ucR = embed*(E*qL+qR);
  dcL = embed*G*(qL-E*qR);
  dcR = embed*G*(E*qL-qR);
  jump = [(ucR-vLp*cp)/d;dcR-dLp*cp; ...
    (vRm*cm-ucL)/d;dRm*cm-dcL];
  single2 = norm(jump)^2;
end

function [vL,dL,vR,dR] = LOCAL_wallmap(FL,FR,wide,embed,eta,inc)
%LOCAL_WALLMAP Local wall field maps.
% Combine direct incident waves and scattered Rayleigh coefficients.

  K = size(embed,2);
  a = embed*inc(1:K,:);
  b = embed*inc(K+1:end,:);
  E = diag(wide.phase(:));
  iG = 1i*diag(wide.gamma_m(:));
  sL = FL*eta;
  sR = FR*eta;
  vL = a+E*b+sL;
  vR = E*a+b+sR;
  dL = iG*(a-E*b-sL);
  dR = iG*(E*a-b+sR);
end

function total = LOCAL_seqsum(Fp,Fm,Pp,Pm,cp,cm,J)
%LOCAL_SEQSUM Local infinite-sequence sum.
% Sum J cells and contract the remaining full propagation actions.

  total = 0;
  xp = cp;
  xm = cm;
  for j = 1:J
    total = total+norm(Fp*xp)^2+norm(Fm*xm)^2;
    xp = Pp*xp;
    xm = Pm*xm;
  end
  rp = norm(Pp,'fro');
  rm = norm(Pm,'fro');
  total = total+norm(Fp,'fro')^2*norm(xp)^2/(1-rp^2)+ ...
    norm(Fm,'fro')^2*norm(xm)^2/(1-rm^2);
end

%% ==================== Center mass ====================
% This helper integrates the Rayleigh field over the empty center cell.

function mass = LOCAL_mass(qL,qR,bm,k,L)
%LOCAL_MASS Local center-cell mass.
% Evaluate the analytic Rayleigh Gram integral mode by mode.

  nm = numel(bm);
  avec = zeros(nm,1);
  bvec = zeros(nm,1);
  prop = k^2-bm.^2 > 0;
  gamma = sqrt(k^2-bm(prop).^2);
  avec(prop) = L;
  bvec(prop) = sin(gamma*L)./gamma;
  kappa = sqrt(bm(~prop).^2-k^2);
  avec(~prop) = (1-exp(-2*kappa*L))./(2*kappa);
  bvec(~prop) = L*exp(-kappa*L);
  mass2 = 0.5*sum((avec+bvec).*abs(qL+qR).^2+ ...
    (avec-bvec).*abs(qL-qR).^2);
  mass = sqrt(real(mass2));
end
