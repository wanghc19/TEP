function out = i31_bie_fit(action,c,node,varargin)
%I31_BIE_FIT Build BIE sample maps and one fixed smooth cell fit.
% Purpose:
%   Reconstruct the circle-density response at the saved candidate, verify
%   the D/-S sign convention, and fit Fourier--Hermite bubble coefficients
%   to independent BIE value/global-x data.
% Input:
%   action - 'density' uses node,frame; 'fit' uses node,density,sides,coords.
% Output:
%   density returns the reusable BIE response and oracle record; fit returns
%   J=4/8 smooth trial maps and training/holdout diagnostics.
% Main algorithm:
%   Rebuild the frozen proxy and A_QP, apply free-space or quasiperiodic
%   layer potentials according to the target material, Fourier-project the
%   samples, and solve one column-scaled multi-right-hand-side QR fit.
% Based on:
%   research/projects/eig-apost/implementation/i3/design-3-1b.md.
% Main changes:
%   BIE fields provide shape data only; the returned trial uses one smooth
%   formula across the disk and never splices interior/exterior potentials.
% Numerical goal:
%   Supply the only scientifically meaningful helper used by check_g_resid.

  action=lower(char(action));
  if strcmp(action,'density')
    out=LOCAL_density(c,node,varargin{1});
  elseif strcmp(action,'fit')
    out=LOCAL_fit(c,node,varargin{1},varargin{2},varargin{3});
  else
    error('i31g:DensityRepresentation','Unknown i31_bie_fit action.');
  end
end

%% ==================== Density response and object identity ====================
% This group reproduces the point proxy and circle-only physical scaling.

function out = LOCAL_density(c,node,frame)
  anchor=frame.proxy_chart.anchor;
  proxy_gamma=LOCAL_gamma(node.k,anchor);
  pars=struct('k',node.k,'beta',c.beta,'d',c.d,'periodic_axis','y');
  pspec=struct('H',c.H,'proxy_dist',c.proxy_dist, ...
    'N_side',c.level.N_side,'N_top',c.level.N_top, ...
    'N_proxy_edge',c.level.N_proxy_edge,'M_pw',c.level.M_pw);
  [proxy,~,~,pinfo]=i21_kproxy(pars,pspec,proxy_gamma, ...
    frame.proxy_chart,'collocation');
  channels=kchan(node.k,c.beta,c.d,c.M,c.X_R-c.X_L,node.gamma, ...
    frame.port_anchor.fingerprint);
  [C,curvelen]=geom.construct_cont(c.level.ntot,'circle',0,0,c.R);
  Aqp=full(complex(kbie(C,node.k,sqrt(c.rho_disk)*node.k, ...
    pars,proxy,proxy_gamma,curvelen)));
  object_defect=norm(Aqp-node.Aqp,'fro')/max(1,norm(node.Aqp,'fro'));
  [BL,BR]=bloch.incident_rhs(C,channels,c.X_L,c.X_R);
  rhs=full(complex([BL,BR])); rc=rcond(Aqp);
  H=-(Aqp\rhs);
  solve_defect=norm(Aqp*H+rhs,'fro')/max(1,norm(rhs,'fro'));
  speed=sqrt(C(2,:).^2+C(5,:).^2);
  speed_defect=max(abs(speed-mean(speed)))/max(mean(speed),realmin);
  h=curvelen/c.level.ntot;
  scale_product=sqrt(h*speed).*sqrt((1/h)./speed);
  scale_defect=max(abs(scale_product-1));
  oracle=LOCAL_oracle(c,C,curvelen,pars,proxy,proxy_gamma);
  pass=pinfo.available&&all(isfinite(H),'all')&&isfinite(rc)&& ...
    rc>=c.bie_rcond_min&&solve_defect<=c.bie_residual_tol&& ...
    object_defect<=1e-13&&speed_defect<=1e-13&&scale_defect<=1e-13&& ...
    oracle.pass;
  work=struct('C',C,'curvelen',curvelen,'proxy',proxy,'pars',pars, ...
    'proxy_gamma',proxy_gamma,'channels',channels,'H_L',H(:,1:c.K), ...
    'H_R',H(:,c.K+1:end));
  record=struct('pass',pass,'density_order','[tau;zeta]=[tau;-sigma]', ...
    'Aqp_relative_defect',object_defect,'Aqp_rcond',rc, ...
    'Aqp_solve_residual',solve_defect,'circle_speed_defect',speed_defect, ...
    'circle_scale_product_defect',scale_defect,'oracle',oracle);
  out=work; out.record=record;
end

function gamma = LOCAL_gamma(k,anchor)
  delta=k-anchor.kc;
  gamma=anchor.gamma_seed.*exp(0.5*log(1+delta./ ...
    (anchor.kc-anchor.beta_m))+0.5*log(1+delta./ ...
    (anchor.kc+anchor.beta_m)));
end

%% ==================== Manufactured D/-S oracle ====================
% Free-space interior and QP exterior paths are tested separately.

function out = LOCAL_oracle(c,C,curvelen,pars,proxy,proxy_gamma)
  ns=size(C,2); theta_s=atan2(C(4,:),C(1,:));
  tau=exp(2i*theta_s).'; zeta=exp(-1i*theta_s).';
  theta=(0:63)'*2*pi/64+pi/64; target_tau=exp(2i*theta);
  target_zeta=exp(-1i*theta); offsets=[0.04,0.02,0.01];
  errors=zeros(3,4);
  for j=1:3
    Tout=[(c.R+offsets(j))*cos(theta).'; ...
      (c.R+offsets(j))*sin(theta).'];
    Tin=[(c.R-offsets(j))*cos(theta).'; ...
      (c.R-offsets(j))*sin(theta).'];
    for kind=1:2
      if kind==1
        po=LOCAL_pair('free',sqrt(c.rho_disk)*c.khat,C,Tout, ...
          pars,proxy,proxy_gamma);
        pair_in=LOCAL_pair('free',sqrt(c.rho_disk)*c.khat,C,Tin, ...
          pars,proxy,proxy_gamma);
      else
        po=LOCAL_pair('qp',c.khat,C,Tout,pars,proxy,proxy_gamma);
        pair_in=LOCAL_pair('qp',c.khat,C,Tin,pars,proxy,proxy_gamma);
      end
      Lo=LOCAL_layers(po,C,curvelen); Li=LOCAL_layers(pair_in,C,curvelen);
      Djump=Lo.D*tau-Li.D*tau;
      nxo=cos(theta); nyo=sin(theta);
      Snout=nxo.*(Lo.minusSx*zeta)+nyo.*(Lo.minusSy*zeta);
      Snin=nxo.*(Li.minusSx*zeta)+nyo.*(Li.minusSy*zeta);
      errors(j,2*kind-1)=norm(Djump-target_tau)/norm(target_tau);
      errors(j,2*kind)=norm(Snout-Snin-target_zeta)/norm(target_zeta);
    end
  end
  xvals=[-0.35,-0.25,0.25,0.35];
  yvals=[-0.35,-0.10,0.10,0.35];
  [xx,yy]=ndgrid(xvals,yvals); T=[xx(:).';yy(:).']; step=1e-5;
  dx_errors=zeros(1,4);
  for kind=1:2
    if kind==1, label='free'; wave=sqrt(c.rho_disk)*c.khat;
    else, label='qp'; wave=c.khat; end
    pair=LOCAL_pair(label,wave,C,T,pars,proxy,proxy_gamma);
    plus=LOCAL_pair(label,wave,C,T+[step;0],pars,proxy,proxy_gamma);
    minus=LOCAL_pair(label,wave,C,T-[step;0],pars,proxy,proxy_gamma);
    L=LOCAL_layers(pair,C,curvelen);
    Lp=LOCAL_layers(plus,C,curvelen);
    Lm=LOCAL_layers(minus,C,curvelen);
    dx_errors(2*kind-1)=norm(L.Dx*tau-(Lp.D*tau-Lm.D*tau)/(2*step))/ ...
      max(realmin,norm(L.Dx*tau));
    dx_errors(2*kind)=norm(L.minusSx*zeta- ...
      (Lp.minusS*zeta-Lm.minusS*zeta)/(2*step))/ ...
      max(realmin,norm(L.minusSx*zeta));
  end
  finest=errors(3,:); trend=finest./max(errors(1,:),realmin);
  pass=all(isfinite([errors(:);dx_errors(:)]))&& ...
    all(finest<=0.25)&&all(trend<=0.75)&&all(dx_errors<=1e-5);
  out=struct('pass',pass,'source_count',ns,'offsets',offsets, ...
    'errors_D_free_minusS_free_D_qp_minusS_qp',errors, ...
    'finest_to_coarsest',trend,'global_x_errors',dx_errors);
end

%% ==================== Fixed BIE-informed fit ====================
% Training and holdout data are separate from continuous-residual nodes.

function out = LOCAL_fit(c,node,density,sides,coords)
  ttrain=(1-cos(((2*(1:24)-1)*pi/48)))/2;
  thold=(1-cos((1:24)*pi/25))/2;
  ytrain=-c.d/2+c.d*((0:255)+0.5)/256;
  yhold=-c.d/2+c.d*((0:255)+0.75)/256;
  [gx,~]=LOCAL_gauss(c.quad_x(2),0,1);
  polar_train=LOCAL_polar_distance(ttrain,ytrain,c);
  polar_hold=LOCAL_polar_distance(thold,yhold,c);
  separation=min([LOCAL_cross_distance(ttrain,thold), ...
    LOCAL_cross_distance(ttrain,gx.'),LOCAL_cross_distance(thold,gx.'), ...
    polar_train,polar_hold]);
  grid_pass=isfinite(separation)&&separation>0;
  trials=repmat(struct('minus',struct(),'plus',struct()),2,1);
  rec_sides=struct();
  names={'minus','plus'};
  for iside=1:2
    name=names{iside}; side=sides.(name);
    eta=density.H_L*side.incoming(1:c.K,:)+ ...
      density.H_R*side.incoming(c.K+1:end,:);
    train=LOCAL_fourier_data(c,node,density,side,eta,ttrain,ytrain);
    trial_side=cell(2,1); factor_side=cell(2,1);
    for jb=1:2
      J=c.bubble_orders(jb);
      [trial_side{jb},factor_side{jb}]= ...
        LOCAL_solve_fit(c,node,side,train,ttrain,J);
      trials(jb).(name)=trial_side{jb};
    end
    hold=LOCAL_holdout_errors(c,node,density,side,eta, ...
      trial_side,thold,yhold);
    levelcells=cell(2,1);
    for jb=1:2
      J=c.bubble_orders(jb); factor=factor_side{jb}; err=hold.errors(jb);
      levelcells{jb}=struct('J',J,'factor_rcond',factor.rcond, ...
        'rank',factor.rank,'column_scales',factor.column_scales, ...
        'minimum_training_circle_distance',train.minimum_circle_distance, ...
        'holdout_error',err,'minimum_holdout_circle_distance', ...
        hold.minimum_circle_distance,'pass',factor.input_data_pass&& ...
        hold.pass&&factor.rank==J&&factor.rcond>=c.fit_rcond_min&&isfinite(err));
    end
    levelrec=vertcat(levelcells{:});
    actual=LOCAL_actual_diagnostics(c,node,density,side,eta, ...
      coords.(['c',name]));
    fine_ok=levelrec(2).pass&&levelrec(2).holdout_error<=c.fit_holdout_max;
    trend_ok=levelrec(2).holdout_error<=levelrec(1).holdout_error;
    rec_sides.(name)=struct('levels',levelrec,'actual',actual, ...
      'pass',fine_ok&&trend_ok&&actual.finite);
  end
  pass=grid_pass&&rec_sides.minus.pass&&rec_sides.plus.pass;
  record=struct('pass',pass,'train_t',ttrain,'train_y_offset',0.5, ...
    'train_y_count',numel(ytrain),'holdout_t',thold, ...
    'holdout_y_offset',0.75,'holdout_y_count',numel(yhold), ...
    'residual_rectangle_x',gx,'residual_polar_counts', ...
    [c.quad_r(2),c.quad_theta(2)], ...
    'minimum_grid_separation',separation, ...
    'grid_separation_pass',grid_pass,'minus',rec_sides.minus, ...
    'plus',rec_sides.plus);
  out=struct('trials',trials,'record',record);
end

function d = LOCAL_cross_distance(a,b)
  d=min(abs(a(:)-b(:).'),[],'all');
end

function d = LOCAL_polar_distance(tgrid,ygrid,c)
  [rr,~]=LOCAL_gauss(c.quad_r(2),0,c.R);
  angles=(0:c.quad_theta(2)-1)'*2*pi/c.quad_theta(2);
  d=Inf;
  for jt=1:numel(tgrid)
    x=c.X_L+(c.X_R-c.X_L)*tgrid(jt);
    r0=hypot(x,ygrid);
    a0=atan2(ygrid,x);
    da=abs(mod(a0(:)-angles.'+pi,2*pi)-pi);
    da=min(da,[],2);
    for jr=1:numel(rr)
      dist=sqrt(max(0,r0(:).^2+rr(jr)^2- ...
        2*r0(:)*rr(jr).*cos(da)));
      d=min(d,min(dist));
    end
  end
end

function data = LOCAL_fourier_data(c,node,density,side,eta,tgrid,ygrid)
  K=c.K; nt=numel(tgrid); U=zeros(nt,K,K); Ux=U;
  psi=exp(1i*ygrid(:)*node.beta_m(:).')/sqrt(c.d);
  F=(c.d/numel(ygrid))*conj(psi).';
  circle_distance=Inf;
  for j=1:nt
    x=c.X_L+(c.X_R-c.X_L)*tgrid(j);
    T=[x*ones(1,numel(ygrid));ygrid];
    circle_distance=min(circle_distance,min(abs(hypot(T(1,:),T(2,:))-c.R)));
    [value,dx]=LOCAL_bie_map(c,node,density,side,eta,T);
    U(j,:,:)=reshape(F*value,[1,K,K]);
    Ux(j,:,:)=reshape(F*dx,[1,K,K]);
  end
  data=struct('U',U,'Ux',Ux,'minimum_circle_distance',circle_distance, ...
    'pass',circle_distance>1e-8&&all(isfinite(U),'all')&&all(isfinite(Ux),'all'));
end

function [trial,factor] = LOCAL_solve_fit(c,node,side,data,tgrid,J)
  nt=numel(tgrid); L=c.X_R-c.X_L; B=zeros(nt,J); Bx=B;
  for l=1:nt
    [b,bx]=LOCAL_bubbles(tgrid(l),J,L); B(l,:)=b; Bx(l,:)=bx;
  end
  A=[B;L*Bx]; scales=sqrt(sum(abs(A).^2,1));
  As=A./scales; [~,R]=qr(As,0); rc=rcond(R); rk=rank(R);
  C=zeros(J,c.K,c.K);
  for m=1:c.K
    [base,basex]=LOCAL_base(side,tgrid,m,L);
    rhs=[squeeze(data.U(:,m,:))-base; ...
      L*(squeeze(data.Ux(:,m,:))-basex)];
    sol=As\rhs;
    C(:,m,:)=reshape(sol./scales.',[J,1,c.K]);
  end
  trial=struct('J',J,'C',C,'d0',side.d0,'g0',side.g0, ...
    'd1',side.d1,'g1',side.g1,'beta',node.beta_m(:));
  factor=struct('rcond',rc,'rank',rk,'column_scales',scales, ...
    'input_data_pass',data.pass);
end

function [base,basex] = LOCAL_base(side,tgrid,m,L)
  n=numel(tgrid); K=size(side.d0,2); base=zeros(n,K); basex=base;
  for j=1:n
    [h,hx]=LOCAL_hermite(tgrid(j),L);
    base(j,:)=h(1)*side.d0(m,:)+h(2)*side.g0(m,:)+ ...
      h(3)*side.d1(m,:)+h(4)*side.g1(m,:);
    basex(j,:)=hx(1)*side.d0(m,:)+hx(2)*side.g0(m,:)+ ...
      hx(3)*side.d1(m,:)+hx(4)*side.g1(m,:);
  end
end

function out = LOCAL_holdout_errors(c,node,density,side,eta,trials,tgrid,ygrid)
  num=zeros(2,1); den=0; L=c.X_R-c.X_L; circle_distance=Inf;
  for j=1:numel(tgrid)
    x=c.X_L+L*tgrid(j);
    T=[x*ones(1,numel(ygrid));ygrid];
    circle_distance=min(circle_distance,min(abs(hypot(T(1,:),T(2,:))-c.R)));
    [value,dx]=LOCAL_bie_map(c,node,density,side,eta,T);
    den=den+norm(value,'fro')^2+L^2*norm(dx,'fro')^2;
    for jb=1:2
      [U,Ux]=LOCAL_trial_values(trials{jb},tgrid(j),ygrid,c);
      num(jb)=num(jb)+norm(U-value,'fro')^2+L^2*norm(Ux-dx,'fro')^2;
    end
  end
  errors=sqrt(num/max(realmin,den));
  out=struct('errors',errors,'minimum_circle_distance',circle_distance, ...
    'pass',circle_distance>1e-8&&all(isfinite(errors)));
end

function [value,dx] = LOCAL_trial_values(trial,t,y,c)
  [h,hx]=LOCAL_hermite(t,c.X_R-c.X_L);
  U=h(1)*trial.d0+h(2)*trial.g0+h(3)*trial.d1+h(4)*trial.g1;
  Ux=hx(1)*trial.d0+hx(2)*trial.g0+hx(3)*trial.d1+hx(4)*trial.g1;
  [b,bx]=LOCAL_bubbles(t,trial.J,c.X_R-c.X_L);
  for j=1:trial.J
    Cj=squeeze(trial.C(j,:,:)); U=U+b(j)*Cj; Ux=Ux+bx(j)*Cj;
  end
  psi=exp(1i*y(:)*trial.beta(:).')/sqrt(c.d);
  value=psi*U; dx=psi*Ux;
end

%% ==================== BIE field maps and diagnostics ====================
% Piecewise potentials are fit data only and never define the conforming trial.

function [value,dx] = LOCAL_bie_map(c,node,density,side,eta,T)
  n=size(T,2); K=c.K; ns=size(density.C,2); value=zeros(n,K); dx=value;
  inside=hypot(T(1,:),T(2,:))<c.R;
  if any(inside)
    pair=LOCAL_pair('free',sqrt(c.rho_disk)*c.khat,density.C, ...
      T(:,inside),density.pars,density.proxy,density.proxy_gamma);
    L=LOCAL_layers(pair,density.C,density.curvelen);
    value(inside,:)=L.D*eta(1:ns,:)+L.minusS*eta(ns+1:end,:);
    dx(inside,:)=L.Dx*eta(1:ns,:)+L.minusSx*eta(ns+1:end,:);
  end
  if any(~inside)
    pair=LOCAL_pair('qp',c.khat,density.C,T(:,~inside), ...
      density.pars,density.proxy,density.proxy_gamma);
    L=LOCAL_layers(pair,density.C,density.curvelen);
    inc=LOCAL_incident(node,side.incoming,T(:,~inside),c);
    value(~inside,:)=inc.value+L.D*eta(1:ns,:)+ ...
      L.minusS*eta(ns+1:end,:);
    dx(~inside,:)=inc.dx+L.Dx*eta(1:ns,:)+ ...
      L.minusSx*eta(ns+1:end,:);
  end
end

function out = LOCAL_incident(node,incoming,T,c)
  a=incoming(1:c.K,:); b=incoming(c.K+1:end,:);
  psi=exp(1i*T(2,:).'*node.beta_m(:).')/sqrt(c.d);
  er=exp(1i*(T(1,:).'-c.X_L)*node.gamma(:).');
  el=exp(-1i*(T(1,:).'-c.X_R)*node.gamma(:).');
  right=psi.*er; left=psi.*el;
  out=struct('value',right*a+left*b, ...
    'dx',(right.*(1i*node.gamma(:).'))*a+ ...
      (left.*(-1i*node.gamma(:).'))*b);
end

function out = LOCAL_actual_diagnostics(c,node,density,side,eta,cstate)
  theta=(0:63)'*2*pi/64+pi/64; epsr=0.01;
  Tout=[(c.R+epsr)*cos(theta).';(c.R+epsr)*sin(theta).'];
  Tin=[(c.R-epsr)*cos(theta).';(c.R-epsr)*sin(theta).'];
  eta0=eta*cstate; incoming=side.incoming*cstate;
  [uo,gxo,gyo]=LOCAL_physical_actual(c,node,density,eta0,incoming,Tout,false);
  [ui,gxi,gyi]=LOCAL_physical_actual(c,node,density,eta0,incoming,Tin,true);
  nx=cos(theta); ny=sin(theta);
  value_jump=norm(uo-ui)/max(realmin,sqrt(norm(uo)*norm(ui)));
  flux_jump=norm(nx.*(gxo-gxi)+ny.*(gyo-gyi))/ ...
    max(realmin,sqrt(norm(nx.*gxo+ny.*gyo)*norm(nx.*gxi+ny.*gyi)));
  y=(-c.d/2+c.d*((0:127)+0.5)/128);
  TL=[c.X_L*ones(1,128);y]; TR=[c.X_R*ones(1,128);y];
  [vl,dxl]=LOCAL_bie_map(c,node,density,side,eta,TL);
  [vr,dxr]=LOCAL_bie_map(c,node,density,side,eta,TR);
  psi=exp(1i*y(:)*node.beta_m(:).')/sqrt(c.d);
  wall=[norm(vl*cstate-psi*(side.d0*cstate)); ...
    norm(dxl*cstate-psi*(side.g0*cstate)); ...
    norm(vr*cstate-psi*(side.d1*cstate)); ...
    norm(dxr*cstate-psi*(side.g1*cstate))];
  wall=wall/max(realmin,norm([vl*cstate;dxl*cstate;vr*cstate;dxr*cstate]));
  xs=linspace(c.X_L+0.05,c.X_R-0.05,8);
  Tup=[xs;c.d/2*ones(1,8)]; Tdn=[xs;-c.d/2*ones(1,8)];
  [up,upx]=LOCAL_bie_map(c,node,density,side,eta,Tup);
  [dn,dnx]=LOCAL_bie_map(c,node,density,side,eta,Tdn);
  phase=exp(1i*c.beta*c.d);
  seam=[norm(up*cstate-phase*dn*cstate); ...
    norm(upx*cstate-phase*dnx*cstate)]/ ...
    max(realmin,norm([up*cstate;upx*cstate]));
  values=[value_jump,flux_jump,wall(:).',seam(:).'];
  out=struct('finite',all(isfinite(values)),'circle_value_jump',value_jump, ...
    'circle_normal_jump',flux_jump,'wall_value_dx_defects',wall, ...
    'y_seam_value_dx_defects',seam);
end

function [u,gx,gy] = LOCAL_physical_actual(c,node,density,eta,incoming,T,inside)
  if inside
    pair=LOCAL_pair('free',sqrt(c.rho_disk)*c.khat,density.C,T, ...
      density.pars,density.proxy,density.proxy_gamma);
    L=LOCAL_layers(pair,density.C,density.curvelen);
    clear pair
    Ly=LOCAL_y_layers('free',sqrt(c.rho_disk)*c.khat,density.C,T, ...
      density.curvelen,density.pars,density.proxy,density.proxy_gamma);
    incu=zeros(size(T,2),1); incx=incu; incy=incu;
  else
    pair=LOCAL_pair('qp',c.khat,density.C,T, ...
      density.pars,density.proxy,density.proxy_gamma);
    L=LOCAL_layers(pair,density.C,density.curvelen);
    clear pair
    Ly=LOCAL_y_layers('qp',c.khat,density.C,T,density.curvelen, ...
      density.pars,density.proxy,density.proxy_gamma);
    inc=LOCAL_incident_all(node,incoming,T,c);
    incu=inc.value; incx=inc.dx; incy=inc.dy;
  end
  ns=size(density.C,2); tau=eta(1:ns); zeta=eta(ns+1:end);
  u=incu+L.D*tau+L.minusS*zeta;
  gx=incx+L.Dx*tau+L.minusSx*zeta;
  gy=incy+Ly.Dy*tau+Ly.minusSy*zeta;
end

function out = LOCAL_incident_all(node,incoming,T,c)
  a=incoming(1:c.K); b=incoming(c.K+1:end);
  psi=exp(1i*T(2,:).'*node.beta_m(:).')/sqrt(c.d);
  er=exp(1i*(T(1,:).'-c.X_L)*node.gamma(:).');
  el=exp(-1i*(T(1,:).'-c.X_R)*node.gamma(:).');
  right=psi.*er; left=psi.*el;
  out=struct('value',right*a+left*b, ...
    'dx',(right.*(1i*node.gamma(:).'))*a+ ...
      (left.*(-1i*node.gamma(:).'))*b, ...
    'dy',(right.*(1i*node.beta_m(:).'))*a+ ...
      (left.*(1i*node.beta_m(:).'))*b);
end

%% ==================== Layer-potential kernels ====================
% Source-normal signs are explicit: D=-grad_target(G).normal_source.

function L = LOCAL_layers(pair,C,curvelen)
  ns=size(C,2); h=curvelen/ns;
  speed=sqrt(C(2,:).^2+C(5,:).^2);
  nx=C(5,:)./speed; ny=-C(2,:)./speed; weight=h*speed;
  L.D=-(pair.gx.*nx+pair.gy.*ny).*weight;
  L.Dx=-(pair.hxx.*nx+pair.hxy.*ny).*weight;
  L.minusS=-pair.pot.*weight;
  L.minusSx=-pair.gx.*weight;
  L.minusSy=-pair.gy.*weight;
end

function L = LOCAL_y_layers(kind,wave,C,T,curvelen,pars,proxy,proxy_gamma)
  src=[C(1,:);C(4,:)];
  if strcmp(kind,'qp')
    [~,~,gy,~,hxy,hyy]=kgreen(src,T,pars,proxy,proxy_gamma);
  else
    [gy,hxy,hyy]=LOCAL_free_y(wave,src,T);
  end
  ns=size(C,2); h=curvelen/ns;
  speed=sqrt(C(2,:).^2+C(5,:).^2);
  nx=C(5,:)./speed; ny=-C(2,:)./speed; weight=h*speed;
  L.Dy=-(hxy.*nx+hyy.*ny).*weight;
  L.minusSy=-gy.*weight;
end

function out = LOCAL_pair(kind,wave,C,T,pars,proxy,proxy_gamma)
  src=[C(1,:);C(4,:)];
  if strcmp(kind,'qp')
    [p,gx,gy,hxx,hxy]=kgreen(src,T,pars,proxy,proxy_gamma);
  else
    [p,gx,gy,hxx,hxy]=LOCAL_free_pair(wave,src,T);
  end
  out=struct('pot',p,'gx',gx,'gy',gy,'hxx',hxx,'hxy',hxy);
end

function [pot,gx,gy,hxx,hxy] = LOCAL_free_pair(k,src,T)
  x=T(1,:).'-src(1,:); y=T(2,:).'-src(2,:);
  rr=x.^2+y.^2; r=sqrt(rr); z=k*r;
  h0=besselh(0,1,z); h1=besselh(1,1,z);
  pot=1i/4*h0;
  coeff=-1i*k/4*h1./r;
  gx=coeff.*x; gy=coeff.*y;
  c2=(1i*k/4./r)./rr; h2z=-z.*h0+2*h1;
  hxx=c2.*(h2z.*x.^2-rr.*h1);
  hxy=c2.*(h2z.*x.*y);
end

function [gy,hxy,hyy] = LOCAL_free_y(k,src,T)
  x=T(1,:).'-src(1,:); y=T(2,:).'-src(2,:);
  rr=x.^2+y.^2; r=sqrt(rr); z=k*r;
  h0=besselh(0,1,z); h1=besselh(1,1,z);
  coeff=-1i*k/4*h1./r; gy=coeff.*y;
  c2=(1i*k/4./r)./rr; h2z=-z.*h0+2*h1;
  hxy=c2.*(h2z.*x.*y);
  hyy=c2.*(h2z.*y.^2-rr.*h1);
end

%% ==================== Fit basis helpers ====================
% The same explicit basis formulas appear in the main continuous integrator.

function [h,hx] = LOCAL_hermite(t,L)
  h=[2*t^3-3*t^2+1,L*(t^3-2*t^2+t), ...
    -2*t^3+3*t^2,L*(t^3-t^2)];
  ht=[6*t^2-6*t,L*(3*t^2-4*t+1), ...
    -6*t^2+6*t,L*(3*t^2-2*t)];
  hx=ht/L;
end

function [b,bx] = LOCAL_bubbles(t,J,L)
  z=2*t-1; [P,Pz]=LOCAL_legendre(z,J-1);
  f=t^2*(1-t)^2; ft=2*t-6*t^2+4*t^3;
  b=f*P; bx=(ft*P+2*f*Pz)/L;
end

function [P,Pz] = LOCAL_legendre(z,nmax)
  P=zeros(1,nmax+1); Pz=P; P(1)=1;
  if nmax==0, return; end
  P(2)=z; Pz(2)=1;
  for n=1:nmax-1
    P(n+2)=((2*n+1)*z*P(n+1)-n*P(n))/(n+1);
    Pz(n+2)=((2*n+1)*(P(n+1)+z*Pz(n+1))-n*Pz(n))/(n+1);
  end
end

function [x,w] = LOCAL_gauss(n,a,b)
  j=(1:n-1)'; v=j./sqrt(4*j.^2-1);
  [V,D]=eig(diag(v,1)+diag(v,-1));
  x0=diag(D); [x0,idx]=sort(x0); V=V(:,idx);
  w0=2*(V(1,:)'.^2);
  x=(a+b)/2+(b-a)*x0/2; w=(b-a)*w0/2;
end
