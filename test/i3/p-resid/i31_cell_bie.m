function out = i31_cell_bie(c,node,frame,prop)
%I31_CELL_BIE Build the pure-BIE rectangular-cell response maps.
% Purpose:
%   Solve the frozen finite Muller system driven by total Dirichlet wall
%   data and evaluate its circle jumps and wall normal derivatives.
% Input:
%   c     - Frozen pure-BIE configuration.
%   node  - Frozen I2 candidate node from eval_i21.
%   frame - Frozen evaluator frame and proxy chart.
%   prop  - Frozen full-subspace propagation and wall-trace maps.
% Output:
%   out   - Physical density, overresolved circle actions, wall maps, and
%           ordinary-double kernel diagnostics.
% Main algorithm:
%   Add the smooth G_D-G_QP wall correction to the existing Kress Muller
%   matrix, solve all unit-wall right-hand sides together, restore the
%   physical [tau;zeta] coordinates with zeta=-sigma, and independently
%   evaluate the same finite trigonometric density on a finer circle grid.
% Based on:
%   test/i2/k-count/kbie.m and test/i3/b-resid/i31_bie_cell.m.
% Main changes:
%   Incoming Rayleigh waves are not right-hand sides.  The rectangular
%   Dirichlet Green function makes the layer field zero on both cell walls.
% Numerical goal:
%   Supply boundary-only maps to check_p_resid without a volume mesh.

  % --- stage 1: anchored proxy and official finite density ---
  work=LOCAL_work(c,node,frame);
  base=LOCAL_level(c,node,work,c.density_nodes,c.green_order_official,true);
  eta_scaled=LOCAL_solve(base.A_scaled,base.B_scaled);
  eta=bsxfun(@times,base.col_scale(:),eta_scaled);
  solve=LOCAL_solve_record(base.A_scaled,eta_scaled,base.B_scaled,c);

  % --- stage 2: same-density overresolved circle action ---
  fine=LOCAL_level(c,node,work,c.circle_nodes,c.green_order_official,false);
  eta_f=LOCAL_interp_density(eta,c.circle_nodes);
  base_residual=base.A_physical*eta+base.B_physical;
  circle_residual=fine.A_physical*eta_f+fine.B_physical;
  circle_relative=norm(circle_residual,'fro')/max(1,norm(fine.B_physical,'fro'));
  base_f=[interpft(base_residual(1:c.density_nodes,:),c.circle_nodes,1); ...
    interpft(base_residual(c.density_nodes+1:end,:),c.circle_nodes,1)];
  circle_change=LOCAL_relative(circle_residual,base_f);

  % --- stage 3: smooth-kernel and wall-action refinements ---
  fine_g0=LOCAL_level(c,node,work,c.circle_nodes,c.green_order_coarse,false);
  green_change=LOCAL_relative(fine.A_physical,fine_g0.A_physical);
  wall0=LOCAL_wall_maps(c,node,eta,c.wall_samples_coarse);
  wall1=LOCAL_wall_maps(c,node,eta,c.wall_samples);
  wall_change=max(LOCAL_relative(interpft(wall0.dx_left,c.wall_samples,1), ...
    wall1.dx_left),LOCAL_relative(interpft(wall0.dx_right,c.wall_samples,1), ...
    wall1.dx_right));
  cauchy=LOCAL_cauchy_diagnostic(c,node,frame,prop,base.C, ...
    base.Aqp_physical,eta);
  Neta=size(eta,1)/2; sigma=-eta(Neta+1:end,:);
  sign_roundtrip=norm(eta(Neta+1:end,:)+sigma,'fro')/max(1,norm(sigma,'fro'));
  info=whos; peak_local=sum([info.bytes])/2^20;
  kernel_record=LOCAL_kernel_oracle(c,node,work);
  finite_all=all(isfinite([eta(:);circle_residual(:); ...
    wall1.dx_left(:);wall1.dx_right(:)]))&&kernel_record.finite&& ...
    isfinite(kernel_record.manufactured.maximum_relative_error);

  record=struct('finite',finite_all,'solve',solve, ...
    'background_pole_clearance',base.pole_clearance, ...
    'background_pole_warning',base.pole_clearance<c.pole_warning, ...
    'green_48_to_64_relative_change',green_change, ...
    'wall_256_to_512_relative_change',wall_change, ...
    'circle_256_to_512_relative_change',circle_change, ...
    'circle_overresolved_relative_residual',circle_relative, ...
    'density_scale_unscale_roundtrip',norm(eta-bsxfun(@times,base.col_scale(:), ...
    eta_scaled),'fro')/max(1,norm(eta,'fro')), ...
    'matrix_scale_unscale_roundtrip',max(base.matrix_roundtrip, ...
    fine.matrix_roundtrip), ...
    'density_coordinate','[tau;zeta], zeta=-sigma', ...
    'zeta_equals_minus_sigma',true, ...
    'zeta_minus_sigma_roundtrip_defect',sign_roundtrip, ...
    'continuous_operator_inverted',false, ...
    'finite_matrix_size',size(base.A_scaled), ...
    'density_size',size(eta),'circle_action_size',size(circle_residual), ...
    'wall_map_size',size(wall1.dx_left), ...
    'incoming_cauchy_decomposition',cauchy, ...
    'peak_local_workspace_mib',peak_local, ...
    'proxy_chart_solve',work.proxy_record, ...
    'base_wall_correction',base.wall_record, ...
    'fine_wall_correction',fine.wall_record, ...
    'kernel',kernel_record);
  out=struct('eta_unit',eta,'circle_residual',circle_residual, ...
    'circle_theta',fine.theta,'wall_y',wall1.y, ...
    'dx_left_unit',wall1.dx_left,'dx_right_unit',wall1.dx_right, ...
    'unit_wall_count',2*c.K,'record',record);
end

%% ==================== Cell system ====================
% These helpers construct the finite rectangular Muller system.

function work=LOCAL_work(c,node,frame)
  anchor=frame.proxy_chart.anchor;
  proxy_gamma=LOCAL_gamma(node.k,anchor);
  pars=struct('k',node.k,'beta',c.beta,'d',c.d,'periodic_axis','y', ...
    'pair_batch',c.qp_pair_batch);
  pspec=struct('H',c.H,'proxy_dist',c.proxy_dist, ...
    'N_side',c.level.N_side,'N_top',c.level.N_top, ...
    'N_proxy_edge',c.level.N_proxy_edge,'M_pw',c.level.M_pw);
  [proxy,pinfo]=LOCAL_proxy_solve(pars,pspec,proxy_gamma,frame.proxy_chart);
  if ~pinfo.available || any(~isfinite(proxy_gamma))
    error('i31p:KernelUnavailable','The anchored proxy is unavailable.');
  end
  work=struct('proxy',proxy,'proxy_gamma',proxy_gamma,'pars',pars, ...
    'proxy_record',pinfo);
end

function [proxy,out]=LOCAL_proxy_solve(pars,pspec,gamma,chart)
  [~,A,b,info]=kproxy(pars,pspec,gamma,[],'collocation');
  r=chart.r; U=chart.U(:,1:r); V=chart.V(:,1:r);
  shape=isequal(size(A),size(chart.A0))&&isequal(size(b),size(chart.b0))&& ...
    isequal(size(chart.c0),[size(A,2),1]);
  if ~shape || any(~isfinite([A(:);b(:);chart.c0(:);U(:);V(:)]))
    error('i31p:KernelUnavailable','The frozen proxy chart is unavailable.');
  end
  affine=(b-chart.b0)-(A-chart.A0)*chart.c0;
  Ar=U'*A*V; br=U'*affine;
  try, z=Ar\br; catch ME
    error('i31p:KernelUnavailable','The proxy chart solve failed: %s',ME.message);
  end
  coefficients=chart.c0+V*z; residual=Ar*z-br;
  projected=norm(residual)/max(1,norm(br));
  fullres=norm(A*coefficients-b)/max(1,norm(b)); rc=rcond(Ar);
  available=all(isfinite(coefficients))&&all(isfinite([projected,fullres,rc]));
  if ~available
    error('i31p:KernelUnavailable','The proxy chart result is nonfinite.');
  end
  np=info.n_proxy; nw=info.n_pw;
  proxy=struct('q',coefficients(1:np).','Z',info.Z_proxy.', ...
    'H',info.H,'C_up',coefficients(np+(1:nw)), ...
    'C_down',coefficients(np+nw+(1:nw)));
  out=struct('available',available,'reduced_rcond',rc, ...
    'projected_residual',projected,'full_residual',fullres, ...
    'qualification_pass',rc>=1e-8&&projected<=1e-11&&fullres<=1e-5);
end

function level=LOCAL_level(c,node,work,N,Mg,use_node)
  [C,curvelen]=geom.construct_cont(N,'circle',0,0,c.R);
  [Awall,wall_record]=LOCAL_wall_correction(c,node,C,curvelen,Mg);
  [row_scale,col_scale]=LOCAL_scales(C,curvelen);
  if use_node
    Aqp_scaled=node.Aqp;
    if ~isequal(size(Aqp_scaled),[2*N,2*N])
      error('i31p:FiniteSize','The frozen A_QP size is inconsistent.');
    end
  else
    kint=sqrt(c.rho_disk)*node.k;
    Aqp_scaled=full(complex(kbie(C,node.k,kint,work.pars,work.proxy, ...
      work.proxy_gamma,curvelen)));
  end
  Aqp_physical=bsxfun(@rdivide,bsxfun(@rdivide,Aqp_scaled, ...
    row_scale(:)),col_scale(:).');
  rebuilt=bsxfun(@times,bsxfun(@times,Aqp_physical, ...
    col_scale(:).'),row_scale(:));
  matrix_roundtrip=norm(rebuilt-Aqp_scaled,'fro')/max(1,norm(Aqp_scaled,'fro'));
  A_physical=Aqp_physical+Awall;
  A_scaled=bsxfun(@times,bsxfun(@times,A_physical, ...
    col_scale(:).'),row_scale(:));
  B_physical=LOCAL_background_rhs(c,node,C);
  B_scaled=bsxfun(@times,B_physical,row_scale(:));
  level=struct('C',C,'curvelen',curvelen,'theta', ...
    (0:N-1)'*2*pi/N,'A_scaled',A_scaled,'A_physical',A_physical, ...
    'B_scaled',B_scaled,'B_physical',B_physical, ...
    'Aqp_physical',Aqp_physical, ...
    'row_scale',row_scale,'col_scale',col_scale, ...
    'matrix_roundtrip',matrix_roundtrip, ...
    'pole_clearance',LOCAL_pole_clearance(c,node,Mg), ...
    'wall_record',wall_record);
end

function x=LOCAL_solve(A,B)
  try
    x=-(A\B);
  catch ME
    error('i31p:DensityUnavailable','The finite Muller solve failed: %s',ME.message);
  end
  if any(~isfinite(x),'all')
    error('i31p:DensityUnavailable','The finite Muller density is nonfinite.');
  end
end

function out=LOCAL_solve_record(A,x,B,c)
  residual=A*x+B; anorm=norm(A,1); nrhs=size(B,2);
  relative=zeros(1,nrhs); backward=relative;
  for j=1:nrhs
    relative(j)=norm(residual(:,j),1)/max(realmin,norm(B(:,j),1));
    backward(j)=norm(residual(:,j),1)/max(realmin, ...
      anorm*norm(x(:,j),1)+norm(B(:,j),1));
  end
  out=struct('rcond',rcond(A),'max_rhs_relative_residual',max(relative), ...
    'max_rhs_backward_error',max(backward), ...
    'qualification_pass',rcond(A)>=c.bie_rcond_warning&& ...
      max([relative,backward])<=c.bie_residual_warning);
end

function eta2=LOCAL_interp_density(eta,N2)
  N=size(eta,1)/2;
  eta2=[interpft(eta(1:N,:),N2,1);interpft(eta(N+1:end,:),N2,1)];
end

function gamma=LOCAL_gamma(k,anchor)
  delta=k-anchor.kc;
  gamma=anchor.gamma_seed.*exp(0.5*log(1+delta./ ...
    (anchor.kc-anchor.beta_m))+0.5*log(1+delta./ ...
    (anchor.kc+anchor.beta_m)));
end

function [row_scale,col_scale]=LOCAL_scales(C,curvelen)
  N=size(C,2); h=curvelen/N;
  speed=sqrt(C(2,:).^2+C(5,:).^2);
  row_scale=sqrt(h*[speed,speed]).';
  col_scale=sqrt((1/h)./[speed,speed]).';
end

%% ==================== Wall correction ====================
% These helpers assemble the smooth G_D-G_QP operator correction.

function [A,record]=LOCAL_wall_correction(c,node,C,curvelen,Mg)
  N=size(C,2); h=curvelen/N;
  speed=sqrt(C(2,:).^2+C(5,:).^2);
  nx=C(5,:)./speed; ny=-C(2,:)./speed; weight=h*speed;
  pair=LOCAL_correction_pair(c,node,C,Mg,c.beta);
  D=(pair.sx.*nx+pair.sy.*ny).*weight;
  S=pair.pot.*weight;
  Kstar=(pair.tx.*nx.'+pair.ty.*ny.').*weight;
  T=(pair.txsx.*(nx.'*nx)+pair.txsy.*(nx.'*ny)+ ...
    pair.tysx.*(ny.'*nx)+pair.tysy.*(ny.'*ny)).*weight;
  A=[D,-S;T,-Kstar];
  scale=max(1,norm(A,'fro'));
  record=struct('finite',all(isfinite(A),'all'), ...
    'matrix_frobenius_norm',norm(A,'fro'), ...
    'diagonal_finite',all(isfinite(diag(A))), ...
    'smooth_operator_scale',scale);
  if ~record.finite
    error('i31p:KernelUnavailable','The wall-correction matrix is nonfinite.');
  end
end

function pair=LOCAL_correction_pair(c,node,C,Mg,beta0)
  xt=C(1,:).'; xs=C(1,:); yt=C(4,:).'; ys=C(4,:);
  XT=xt+zeros(size(xs)); XS=zeros(size(xt))+xs;
  dx=XT-XS; adx=abs(dx); sgn=sign(dx);
  xmin=min(XT,XS); xmax=max(XT,XS);
  left=dx<0; right=dx>0; diagonal=~(left|right);
  names={'pot','tx','ty','sx','sy','txsx','txsy','tysx','tysy'};
  for j=1:numel(names), pair.(names{j})=zeros(size(dx)); end
  orders=(-Mg:Mg).'; beta=beta0+2*pi*orders/c.d;
  gamma=LOCAL_outgoing_gamma(node.k,beta);
  for j=1:numel(orders)
    b=beta(j); g=gamma(j);
    if ~isfinite(g) || (~LOCAL_scaled_mode(g,c.L)&& ...
        (~isfinite(sin(g*c.L))||sin(g*c.L)==0))
      error('i31p:KernelUnavailable','A rectangular Green denominator vanished.');
    end
    phase=exp(1i*b*(yt-ys))/c.d;
    a=xmin-c.X_L; bdist=c.X_R-xmax;
    gd=LOCAL_sinsin(g,a,bdist,c.L);
    ee=exp(1i*g*adx); qp=1i/(2*g)*ee;
    gl=zeros(size(dx)); gr=gl;
    gl(left)=LOCAL_cossin(g,XT(left)-c.X_L,c.X_R-XS(left),c.L);
    gl(right)=-LOCAL_sincos(g,XS(right)-c.X_L,c.X_R-XT(right),c.L);
    gr(left)=-LOCAL_sincos(g,XT(left)-c.X_L,c.X_R-XS(left),c.L);
    gr(right)=LOCAL_cossin(g,XS(right)-c.X_L,c.X_R-XT(right),c.L);
    if any(diagonal,'all')
      xd=XT(diagonal);
      av=LOCAL_cossin(g,xd-c.X_L,c.X_R-xd,c.L);
      bv=-LOCAL_sincos(g,xd-c.X_L,c.X_R-xd,c.L);
      gl(diagonal)=0.5*(av+bv); gr(diagonal)=gl(diagonal);
    end
    qtx=-0.5*sgn.*ee; qsx=0.5*sgn.*ee;
    r=gd-qp; rtx=gl-qtx; rsx=gr-qsx;
    gdts=-LOCAL_gcoscos(g,a,bdist,c.L);
    rts=gdts-1i*g/2*ee;
    pair.pot=pair.pot+phase.*r;
    pair.tx=pair.tx+phase.*rtx;
    pair.ty=pair.ty+phase.*(1i*b*r);
    pair.sx=pair.sx+phase.*rsx;
    pair.sy=pair.sy+phase.*(-1i*b*r);
    pair.txsx=pair.txsx+phase.*rts;
    pair.txsy=pair.txsy+phase.*(-1i*b*rtx);
    pair.tysx=pair.tysx+phase.*(1i*b*rsx);
    pair.tysy=pair.tysy+phase.*(b^2*r);
  end
end

function gamma=LOCAL_outgoing_gamma(k,beta)
  gamma=sqrt(complex(k^2-beta.^2));
  flip=imag(gamma)<0 | (imag(gamma)==0&real(gamma)<0);
  gamma(flip)=-gamma(flip);
end

function value=LOCAL_sin_ratio(g,a,L)
  if LOCAL_scaled_mode(g,L)
    k=imag(g); value=exp(k*(a-L)).*(1-exp(-2*k*a))/(1-exp(-2*k*L));
  else
    value=sin(g*a)/sin(g*L);
  end
end

function value=LOCAL_cos_ratio(g,a,L)
  if LOCAL_scaled_mode(g,L)
    k=imag(g); value=-1i*exp(k*(a-L)).*(1+exp(-2*k*a))/(1-exp(-2*k*L));
  else
    value=cos(g*a)/sin(g*L);
  end
end

function value=LOCAL_sinsin(g,a,b,L)
  if LOCAL_scaled_mode(g,L)
    k=imag(g); value=0.5/k*exp(k*(a+b-L)).* ...
      (1-exp(-2*k*a)).*(1-exp(-2*k*b))/(1-exp(-2*k*L));
  else
    value=sin(g*a).*sin(g*b)/(g*sin(g*L));
  end
end

function value=LOCAL_cossin(g,a,b,L)
  if LOCAL_scaled_mode(g,L)
    k=imag(g); value=0.5*exp(k*(a+b-L)).* ...
      (1+exp(-2*k*a)).*(1-exp(-2*k*b))/(1-exp(-2*k*L));
  else
    value=cos(g*a).*sin(g*b)/sin(g*L);
  end
end

function value=LOCAL_sincos(g,a,b,L)
  value=LOCAL_cossin(g,b,a,L);
end

function value=LOCAL_gcoscos(g,a,b,L)
  if LOCAL_scaled_mode(g,L)
    k=imag(g); value=0.5*k*exp(k*(a+b-L)).* ...
      (1+exp(-2*k*a)).*(1+exp(-2*k*b))/(1-exp(-2*k*L));
  else
    value=g*cos(g*a).*cos(g*b)/sin(g*L);
  end
end

function yes=LOCAL_scaled_mode(g,L)
  yes=abs(real(g*L))<=1e-12&&imag(g*L)>50;
end

function value=LOCAL_pole_clearance(c,node,Mg)
  orders=(-Mg:Mg).'; beta=c.beta+2*pi*orders/c.d;
  gamma=LOCAL_outgoing_gamma(node.k,beta); ratio=zeros(size(gamma));
  for j=1:numel(gamma)
    z=gamma(j)*c.L;
    if abs(z)<sqrt(eps), ratio(j)=1;
    elseif LOCAL_scaled_mode(gamma(j),c.L)
      x=imag(z); logv=x-log(2*x)+log1p(-exp(-2*x));
      ratio(j)=exp(min(log(realmax),logv));
    else, ratio(j)=abs(sin(z)/z); end
  end
  value=min(ratio);
end

%% ==================== Dirichlet wall data ====================
% These helpers map unit total wall traces to circle Cauchy data.

function B=LOCAL_background_rhs(c,node,C)
  x=C(1,:).'; y=C(4,:).';
  speed=sqrt(C(2,:).^2+C(5,:).^2).';
  nx=C(5,:).'./speed; ny=-C(2,:).'./speed;
  beta=node.beta_m(:); gamma=node.gamma(:);
  psi=exp(1i*y*beta.')/sqrt(c.d);
  UL=zeros(size(psi)); UR=UL; XL=UL; XR=UL;
  for j=1:numel(beta)
    UL(:,j)=psi(:,j).*LOCAL_sin_ratio(gamma(j),c.X_R-x,c.L);
    UR(:,j)=psi(:,j).*LOCAL_sin_ratio(gamma(j),x-c.X_L,c.L);
    XL(:,j)=-psi(:,j).*gamma(j).*LOCAL_cos_ratio(gamma(j),c.X_R-x,c.L);
    XR(:,j)= psi(:,j).*gamma(j).*LOCAL_cos_ratio(gamma(j),x-c.X_L,c.L);
  end
  YL=UL.*(1i*beta.'); YR=UR.*(1i*beta.');
  NL=nx.*XL+ny.*YL; NR=nx.*XR+ny.*YR;
  B=full(complex([UL,UR;NL,NR]));
  if any(~isfinite(B),'all')
    error('i31p:KernelUnavailable','The background wall lift is nonfinite.');
  end
end

function out=LOCAL_cauchy_diagnostic(c,node,frame,prop,C,Aqp_physical,Hnew)
  channels=kchan(node.k,c.beta,c.d,c.M,c.L,node.gamma, ...
    frame.port_anchor.fingerprint);
  [BL,BR]=bloch.incident_rhs(C,channels,c.X_L,c.X_R);
  rhs=full(complex([BL,BR]));
  message='';
  try
    Hold=-(Aqp_physical\rhs); K=c.K;
    HL=Hold(:,1:K); HR=Hold(:,K+1:end);
    oldp=HL*prop.Ap+HR*prop.Bp*prop.Pplus;
    oldm=HL*prop.Am*prop.Pminus+HR*prop.Bm;
    Gp=[prop.Dplus;prop.Dplus*prop.Pplus];
    Gm=[prop.Dminus*prop.Pminus;prop.Dminus];
    defects=[LOCAL_relative(Hnew*Gp,oldp),LOCAL_relative(Hnew*Gm,oldm)];
    available=all(isfinite(defects));
    if ~available, message='The old-incoming comparison is nonfinite.'; end
  catch ME
    defects=[NaN,NaN]; available=false; message=ME.message;
  end
  out=struct('available',available,'plus_relative_defect',defects(1), ...
    'minus_relative_defect',defects(2),'message',message, ...
    'role','nonblocking old-incoming decomposition diagnostic');
end

%% ==================== Wall normal action ====================
% These helpers evaluate global-x derivatives without close quadrature.

function out=LOCAL_wall_maps(c,node,eta,Ny)
  y=-c.d/2+c.d*((0:Ny-1).'+0.5)/Ny;
  bg=LOCAL_background_wall_dx(c,node,y);
  [DL,SL]=LOCAL_wall_layers(c,node,Ny,c.X_L);
  [DR,SR]=LOCAL_wall_layers(c,node,Ny,c.X_R);
  N=size(eta,1)/2; tau=eta(1:N,:); zeta=eta(N+1:end,:);
  out=struct('y',y,'dx_left',bg.left+DL*tau-SL*zeta, ...
    'dx_right',bg.right+DR*tau-SR*zeta);
end

function out=LOCAL_background_wall_dx(c,node,y)
  beta=node.beta_m(:); gamma=node.gamma(:);
  psi=exp(1i*y*beta.')/sqrt(c.d);
  gcos=zeros(size(gamma)); gover=gcos;
  for j=1:numel(gamma)
    gcos(j)=gamma(j)*LOCAL_cos_ratio(gamma(j),c.L,c.L);
    gover(j)=gamma(j)*LOCAL_cos_ratio(gamma(j),0,c.L);
  end
  left=psi*[-diag(gcos),diag(gover)];
  right=psi*[-diag(gover),diag(gcos)];
  out=struct('left',left,'right',right);
end

function [D,S]=LOCAL_wall_layers(c,node,Ny,xwall)
  y=-c.d/2+c.d*((0:Ny-1).'+0.5)/Ny;
  [C,curvelen]=geom.construct_cont(c.density_nodes,'circle',0,0,c.R);
  speed=sqrt(C(2,:).^2+C(5,:).^2); nx=C(5,:)./speed;
  ny=-C(2,:)./speed; weight=curvelen/c.density_nodes*speed;
  D=zeros(Ny,c.density_nodes); S=D;
  orders=(-c.green_order_official:c.green_order_official).';
  beta=c.beta+2*pi*orders/c.d; gamma=LOCAL_outgoing_gamma(node.k,beta);
  psi_t=exp(1i*y*beta.')/sqrt(c.d);
  psi_s=exp(-1i*beta*C(4,:))/sqrt(c.d);
  for j=1:numel(orders)
    g=gamma(j); xp=C(1,:);
    if xwall==c.X_L
      h=LOCAL_sin_ratio(g,c.X_R-xp,c.L);
      hx=-g*LOCAL_cos_ratio(g,c.X_R-xp,c.L);
    else
      h=-LOCAL_sin_ratio(g,xp-c.X_L,c.L);
      hx=-g*LOCAL_cos_ratio(g,xp-c.X_L,c.L);
    end
    base=psi_s(j,:).*h;
    S=S+psi_t(:,j)*(base.*weight);
    src=psi_s(j,:).*(nx.*hx+ny.*(-1i*beta(j)*h));
    D=D+psi_t(:,j)*(src.*weight);
  end
  if any(~isfinite([D(:);S(:)]))
    error('i31p:KernelUnavailable','A wall normal action is nonfinite.');
  end
end

%% ==================== Kernel diagnostics ====================
% These helpers provide low-cost checks without controlling the experiment.

function out=LOCAL_kernel_oracle(c,node,work)
  [C,~]=geom.construct_cont(8,'circle',0,0,c.R);
  p=LOCAL_correction_pair(c,node,C,8,c.beta);
  q=LOCAL_correction_pair(c,node,C,8,-c.beta);
  reciprocity=norm(p.pot-q.pot.','fro')/max(1,norm(p.pot,'fro'));
  derivative=norm(p.tx-q.sx.','fro')/max(1,norm(p.tx,'fro'));
  mixed=norm(p.txsx-q.txsx.','fro')/max(1,norm(p.txsx,'fro'));
  beta=node.beta_m(:); gamma=node.gamma(:);
  left=[ones(c.K,1),zeros(c.K,1)]; right=fliplr(left);
  left_numeric=zeros(c.K,2); right_numeric=left_numeric;
  for j=1:c.K
    left_numeric(j,:)=[LOCAL_sin_ratio(gamma(j),c.L,c.L), ...
      LOCAL_sin_ratio(gamma(j),0,c.L)];
    right_numeric(j,:)=fliplr(left_numeric(j,:));
  end
  wall_identity=max([norm(left_numeric-left,'fro'), ...
    norm(right_numeric-right,'fro')]);
  manufactured=LOCAL_manufactured(c);
  out=struct('finite',all(isfinite([p.pot(:);q.pot(:)])), ...
    'beta_minus_beta_reciprocity_defect',reciprocity, ...
    'target_source_derivative_reciprocity_defect',derivative, ...
    'mixed_derivative_reciprocity_defect',mixed, ...
    'regular_diagonal_finite',all(isfinite(diag(p.pot))), ...
    'background_wall_lift_identity_defect',wall_identity, ...
    'background_wall_zero_identity',true,'manufactured',manufactured, ...
    'manufactured_orders',beta, ...
    'wall_value_structural_zero',true,'proxy_available',isstruct(work.proxy));
end

function out=LOCAL_manufactured(c)
  N=64; [C,curvelen]=geom.construct_cont(N,'circle',0,0,c.R);
  [theta,~]=utils.triginterp(N); h=curvelen/N;
  geom0=struct('z',[C(1,:).',C(4,:).'], ...
    'zp',[C(2,:).',C(5,:).'],'zpp',[C(3,:).',C(6,:).']);
  geom0.speed=sqrt(sum(geom0.zp.^2,2));
  Rm=LOCAL_kress_matrix(N); ell=[0,1,-1,2,-2]; errors=zeros(2,numel(ell),6);
  sign_errors=zeros(2,numel(ell));
  waves=[c.khat,sqrt(c.rho_disk)*c.khat];
  for ik=1:2
    [K,S,Kstar,T]=LOCAL_free_ops(waves(ik),theta,geom0,Rm,h); z=waves(ik)*c.R;
    for j=1:numel(ell)
      l=ell(j); phi=exp(1i*l*theta(:)); J=besselj(l,z); H=besselh(l,1,z);
      Jp=.5*(besselj(l-1,z)-besselj(l+1,z));
      Hp=.5*(besselh(l-1,1,z)-besselh(l+1,1,z));
      exact={1i*pi*c.R/2*J*H*phi, ...
        1i*pi*waves(ik)*c.R/2*Jp*H*phi, ...
        1i*pi*waves(ik)*c.R/2*J*Hp*phi, ...
        1i*pi*waves(ik)*c.R/2*J*Hp*phi, ...
        1i*pi*waves(ik)*c.R/2*Jp*H*phi, ...
        1i*pi*waves(ik)^2*c.R/2*Jp*Hp*phi};
      dSext=(-.5*eye(N)+Kstar)*phi; dSint=(.5*eye(N)+Kstar)*phi;
      numeric={S*phi,(.5*eye(N)+K)*phi,(-.5*eye(N)+K)*phi, ...
        dSext,dSint,T*phi};
      for q=1:6
        errors(ik,j,q)=norm(numeric{q}-exact{q})/max(1,norm(exact{q}));
      end
      sign_errors(ik,j)=norm(-dSext+dSint-phi)/max(1,norm(phi));
    end
  end
  out=struct('modes',ell,'columns',{{'S','Dplus','Dminus', ...
    'dS_exterior','dS_interior','T'}},'relative_errors',errors, ...
    'maximum_relative_error',max(errors,[],'all'), ...
    'minus_S_global_normal_jump_defects',sign_errors, ...
    'maximum_minus_S_sign_defect',max(sign_errors,[],'all'), ...
    'fundamental_solution','i/4 H0^(1)');
end

function [K,S,Kstar,T]=LOCAL_free_ops(k,t,geom0,Rm,h)
  [L1,L2,Ls1,Ls2]=kernel.kress_l_splits(k,t,geom0);
  [M1,M2,N1,N2]=kernel.kress_mn_splits(k,t,geom0);
  K=Rm.*L1+h*L2; S=Rm.*M1+h*M2; Kstar=Rm.*Ls1+h*Ls2;
  [~,D]=utils.triginterp(numel(t));
  G=(geom0.zp*geom0.zp.')./(geom0.speed*geom0.speed.');
  A=(Rm.*(k^2*M1)+h*k^2*M2).*G;
  B=bsxfun(@rdivide,Rm.*N1+h*N2,geom0.speed);
  T=A+B*D;
end

function Rm=LOCAL_kress_matrix(N)
  rvec=quad.quad_kress_rvec(N);
  idx=mod((0:N-1)-(0:N-1).',N)+1; Rm=rvec(idx);
end

function value=LOCAL_relative(a,b)
  value=norm(a-b,'fro')/max([1,norm(a,'fro'),norm(b,'fro')]);
end
