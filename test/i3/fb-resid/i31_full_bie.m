function out = i31_full_bie(c,node,frame)
%I31_FULL_BIE Build full-boundary quotient-cell response maps.
% Purpose:
%   Solve wall-single-layer/circle-Muller systems driven only by shared
%   total Dirichlet wall traces, then expose residual and audit maps.
% Input:
%   c     - Frozen fbie-a1 configuration.
%   node  - Frozen I2 candidate evaluator node.
%   frame - Frozen evaluator frame and proxy chart.
% Output:
%   out   - Coarse/official unit maps and ordinary-double diagnostics.
% Main algorithm:
%   Eliminate the two wall densities mode by mode, solve the physical
%   circle Schur complement, and evaluate the same finite density on
%   independent circle and wall grids.
% Based on:
%   test/i2/k-count/kbie.m and test/i3/p-resid/i31_cell_bie.m.
% Main changes:
%   Artificial walls are explicit single-layer unknowns.  M=48 enters only
%   through prescribed total traces; wall response uses independent orders.
% Numerical goal:
%   Supply maps for an ordinary-double weak-residual indicator.

  work=LOCAL_work(c,node,frame);
  circle=LOCAL_circle(c,node,work,c.circle_density_nodes,true);
  circle_fine=LOCAL_circle(c,node,work,c.circle_action_nodes,false);
  coarse=LOCAL_level(c,node,circle,c.wall_order_coarse);
  official=LOCAL_level(c,node,circle,c.wall_order_official);
  coarse0=LOCAL_action(c,coarse,circle);
  coarse1=LOCAL_action(c,coarse,circle_fine);
  action0=LOCAL_action(c,official,circle);
  action1=LOCAL_action(c,official,circle_fine);
  coarse=LOCAL_attach_refined(coarse,coarse0,coarse1);
  official=LOCAL_attach_refined(official,action0,action1);
  common=LOCAL_common(c,coarse,official);
  baseline_info=whos; baseline_mib=sum([baseline_info.bytes])/2^20;
  oracle=LOCAL_oracles(c,node,work,circle,official,common);
  padded=LOCAL_interp_pair(action0.residual,c.circle_action_nodes);
  circle_metric=LOCAL_metric_record(action1.residual,padded);
  circle_change=circle_metric.ratio;
  angular=LOCAL_angular_tail(action1.residual, ...
    c.circle_density_nodes,c.circle_action_nodes);
  angular_tail=angular.ratio; angular_zero=angular.zero_component;
  Nc=c.circle_density_nodes; zeta=official.eta(Nc+1:end,:);
  sigma=-zeta;
  zeta_sign=norm(zeta+sigma,'fro')/max(realmin,norm(zeta,'fro'));
  finite=all(isfinite([coarse.eta(:);coarse.xi(:);official.eta(:); ...
    official.xi(:);action1.residual(:)]));
  info=whos; peak_local=max(sum([info.bytes])/2^20, ...
    baseline_mib+oracle.actual_delta_t.peak_workspace_mib);

  record=struct('finite',finite, ...
    'mathematical_exact_kernel_trial_defined',true, ...
    'numerical_actions_outward_enclosed',false, ...
    'circle_density_nodes',c.circle_density_nodes, ...
    'circle_action_nodes',c.circle_action_nodes, ...
    'wall_order_sets',struct('coarse',coarse.orders, ...
      'official',official.orders), ...
    'coarse',coarse.record,'official',official.record, ...
    'proxy_chart_solve',work.proxy_record, ...
    'fixed_density_action_change',common.fixed_density_action_change, ...
    'resolved_source_change',common.resolved_source_change, ...
    'wall_refinement_metrics',common.metrics, ...
    'common_wall_value_defect',common.shared_value_defect, ...
    'common_wall_gauge_defect',common.gauge_defect, ...
    'circle_action_change',circle_change, ...
    'circle_action_metric',circle_metric, ...
    'circle_angular_tail_change',angular_tail, ...
    'circle_angular_tail_zero_component',angular_zero, ...
    'circle_angular_tail_metric',angular, ...
    'actual_delta_t',oracle.actual_delta_t, ...
    'manufactured',oracle.manufactured, ...
    'wall_modal_oracle',oracle.wall_modal, ...
    'bloch_kernel_oracle',oracle.bloch, ...
    'cross_action',oracle.cross_action, ...
    'all_oracles_available',oracle.available, ...
    'scaled_physical_roundtrip',max(circle.roundtrip, ...
      official.record.schur_scale_roundtrip), ...
    'zeta_equals_minus_sigma',true, ...
    'zeta_minus_sigma_roundtrip_defect',zeta_sign, ...
    'independent_reference',false, ...
    'peak_local_workspace_mib',peak_local);
  out=struct('official',LOCAL_public(official), ...
    'coarse',LOCAL_public(coarse), ...
    'circle_delta_unit',action1.residual(1:c.circle_action_nodes,:), ...
    'circle_jump_unit',-action1.residual(c.circle_action_nodes+1:end,:), ...
    'circle_theta',(0:c.circle_action_nodes-1)'*2*pi/c.circle_action_nodes, ...
    'common',common,'record',record, ...
    'audit',struct('eta_unit',official.eta, ...
      'xi_left_unit',official.xi_left,'xi_right_unit',official.xi_right, ...
      'coarse_eta_unit',coarse.eta, ...
      'coarse_xi_left_unit',coarse.xi_left, ...
      'coarse_xi_right_unit',coarse.xi_right, ...
      'wall_input_unit',official.g, ...
      'wall_flux_left_unit',official.flux_left, ...
      'wall_flux_right_unit',official.flux_right, ...
      'circle_value_residual_unit', ...
        action1.residual(1:c.circle_action_nodes,:), ...
      'circle_normal_residual_unit', ...
        action1.residual(c.circle_action_nodes+1:end,:), ...
      'official_schur_physical',official.schur_physical, ...
      'official_schur_scaled',official.schur_scaled, ...
      'common_y',common.y,'common_value_official',common.value_official, ...
      'common_flux_official',common.flux_official));
end

%% ==================== Anchored circle operators ====================
% Physical and scaled density coordinates remain explicit.

function work=LOCAL_work(c,node,frame)
  anchor=frame.proxy_chart.anchor;
  proxy_gamma=LOCAL_gamma(node.k,anchor);
  pars=struct('k',node.k,'beta',c.beta,'d',c.d, ...
    'periodic_axis','y','pair_batch',c.qp_pair_batch);
  pspec=struct('H',c.H,'proxy_dist',c.proxy_dist, ...
    'N_side',c.level.N_side,'N_top',c.level.N_top, ...
    'N_proxy_edge',c.level.N_proxy_edge,'M_pw',c.level.M_pw);
  [~,A,b,info]=kproxy(pars,pspec,proxy_gamma,[],'collocation');
  chart=frame.proxy_chart; r=chart.r; U=chart.U(:,1:r); V=chart.V(:,1:r);
  if ~isequal(size(A),size(chart.A0)) || any(~isfinite([A(:);b(:)]))
    error('i31f:KernelUnavailable','The frozen proxy chart is unavailable.');
  end
  affine=(b-chart.b0)-(A-chart.A0)*chart.c0;
  Ar=U'*A*V; br=U'*affine;
  rc=rcond(Ar);
  if r==0 || any(~isfinite([Ar(:);br(:);rc])) || rc==0
    error('i31f:KernelUnavailable','The required reduced proxy factor is unavailable.');
  end
  try
    z=Ar\br;
  catch ME
    error('i31f:KernelUnavailable','The proxy solve failed: %s',ME.message);
  end
  coefficients=chart.c0+V*z;
  if any(~isfinite(coefficients))
    error('i31f:KernelUnavailable','The proxy coefficients are nonfinite.');
  end
  np=info.n_proxy; nw=info.n_pw;
  projected=norm(Ar*z-br)/max(realmin,norm(br));
  fullres=norm(A*coefficients-b)/max(realmin,norm(b));
  if any(~isfinite([projected,fullres]))
    error('i31f:KernelUnavailable','A required proxy residual is nonfinite.');
  end
  proxy=struct('q',coefficients(1:np).','Z',info.Z_proxy.', ...
    'H',info.H,'C_up',coefficients(np+(1:nw)), ...
    'C_down',coefficients(np+nw+(1:nw)));
  work=struct('proxy',proxy,'proxy_gamma',proxy_gamma,'pars',pars, ...
    'proxy_record',struct('available',true,'reduced_rcond',rc, ...
    'projected_residual',projected,'full_residual',fullres, ...
    'qualification_pass',rc>=c.proxy_rcond_min&& ...
      projected<=c.proxy_projected_tol&&fullres<=c.proxy_full_residual_max));
end

function level=LOCAL_circle(c,node,work,N,use_node)
  [C,curvelen]=geom.construct_cont(N,'circle',0,0,c.R);
  [row_scale,col_scale]=LOCAL_scales(C,curvelen);
  if use_node
    scaled=node.Aqp;
  else
    kint=sqrt(c.rho_disk)*node.k;
    scaled=full(complex(kbie(C,node.k,kint,work.pars,work.proxy, ...
      work.proxy_gamma,curvelen)));
  end
  physical=bsxfun(@rdivide,bsxfun(@rdivide,scaled,row_scale),col_scale.');
  rebuilt=bsxfun(@times,bsxfun(@times,physical,col_scale.'),row_scale);
  level=struct('C',C,'curvelen',curvelen,'Acc',physical, ...
    'row_scale',row_scale,'col_scale',col_scale, ...
    'roundtrip',norm(rebuilt-scaled,'fro')/max(realmin,norm(scaled,'fro')));
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

%% ==================== Modal wall Schur systems ====================
% The two wall blocks are inverted independently for every Fourier order.

function level=LOCAL_level(c,node,circle,Nw)
  orders=(-Nw/2:Nw/2-1).';
  beta=c.beta+2*pi*orders/c.d;
  gamma=LOCAL_outgoing(node.k,beta);
  E=exp(1i*gamma*c.L); s0=1i./(2*gamma);
  clearance=abs(1-E.^2)./(1+abs(E).^2);
  if any(~isfinite([beta;gamma;E;s0;clearance])) || ...
      any(gamma==0) || any(clearance==0)
    error('i31f:WallModalUnavailable','A wall modal block is unavailable.');
  end
  chan=struct('beta_m',beta,'gamma_m',gamma,'d',c.d,'K',Nw);
  [BL,BR]=bloch.incident_rhs(circle.C,chan,c.X_L,c.X_R);
  Acw=[bsxfun(@times,BL,s0.'),bsxfun(@times,BR,s0.')];
  [FL,FR]=bloch.farfield_extractors(circle.C,chan,c.X_L,c.X_R, ...
    circle.curvelen);
  Awc=[FL;FR]; G=LOCAL_input_map(c,orders);
  H=LOCAL_wall_inverse(Awc,s0,E); Y=LOCAL_wall_inverse(G,s0,E);
  Schur=circle.Acc-Acw*H; rhs=-Acw*Y;
  As=bsxfun(@times,bsxfun(@times,Schur,circle.col_scale.'), ...
    circle.row_scale);
  Bs=bsxfun(@times,rhs,circle.row_scale);
  Schur_back=bsxfun(@rdivide,bsxfun(@rdivide,As, ...
    circle.row_scale),circle.col_scale.');
  if any(~isfinite([As(:);Bs(:)]))
    error('i31f:DensityUnavailable','The circle Schur factor is nonfinite.');
  end
  schur_rc=rcond(As);
  if ~isfinite(schur_rc) || schur_rc==0
    error('i31f:DensityUnavailable','The required circle Schur factor is unavailable.');
  end
  try
    eta_scaled=As\Bs;
  catch ME
    error('i31f:DensityUnavailable','The circle Schur solve failed: %s',ME.message);
  end
  eta=bsxfun(@times,circle.col_scale,eta_scaled);
  xi=Y-H*eta;
  if any(~isfinite([eta(:);xi(:)]))
    error('i31f:DensityUnavailable','A full-boundary density is nonfinite.');
  end
  xi_left=xi(1:Nw,:); xi_right=xi(Nw+1:end,:);
  raw=LOCAL_wall_apply(xi,s0,E)+Awc*eta; defect=G-raw;
  flux_left=.5*(xi_left-bsxfun(@times,E,xi_right))+ ...
    bsxfun(@times,1i*gamma,FL*eta);
  flux_right=.5*(-bsxfun(@times,E,xi_left)+xi_right)+ ...
    bsxfun(@times,1i*gamma,FR*eta);
  residual=As*eta_scaled-Bs; rel=zeros(1,size(Bs,2)); back=rel;
  anorm=norm(As,1);
  for j=1:numel(rel)
    rel(j)=norm(residual(:,j),1)/max(realmin,norm(Bs(:,j),1));
    back(j)=norm(residual(:,j),1)/max(realmin, ...
      anorm*norm(eta_scaled(:,j),1)+norm(Bs(:,j),1));
  end
  record=struct('available',true,'minimum_abs_gamma',min(abs(gamma)), ...
    'minimum_pole_clearance',min(clearance), ...
    'pole_warning',min(clearance)<c.pole_warning, ...
    'schur_rcond',schur_rc,'maximum_rhs_relative_residual',max(rel), ...
    'maximum_rhs_backward_error',max(back), ...
    'qualification_pass',schur_rc>=c.bie_rcond_warning&& ...
      max([rel,back])<=c.bie_residual_warning&& ...
      min(clearance)>=c.pole_warning, ...
    'wall_value_defect',LOCAL_metric(raw,G), ...
    'schur_scale_roundtrip',LOCAL_metric(Schur_back,Schur), ...
    'wall_modal_block_size',[2*Nw,2*Nw], ...
    'circle_schur_size',size(As));
  level=struct('orders',orders,'beta',beta,'gamma',gamma,'E',E,'s0',s0, ...
    'eta',eta,'xi',xi,'xi_left',xi_left,'xi_right',xi_right,'g',G, ...
    'Acw',Acw,'Awc',Awc,'FL',FL,'FR',FR, ...
    'schur_physical',Schur,'schur_scaled',As,'rhs_scaled',Bs, ...
    'flux_left',flux_left,'flux_right',flux_right, ...
    'raw_left',raw(1:Nw,:),'raw_right',raw(Nw+1:end,:), ...
    'defect_left',defect(1:Nw,:),'defect_right',defect(Nw+1:end,:), ...
    'record',record);
end

function G=LOCAL_input_map(c,orders)
  N=numel(orders); Q=zeros(N,c.K);
  for j=1:c.K
    at=find(orders==j-c.M-1,1);
    if isempty(at)
      error('i31f:FiniteSize','The wall order set omits an input mode.');
    end
    Q(at,j)=1;
  end
  G=[Q,zeros(N,c.K);zeros(N,c.K),Q];
end

function X=LOCAL_wall_inverse(B,s0,E)
  N=numel(E); L=B(1:N,:); R=B(N+1:end,:);
  den=s0.*(1-E.^2);
  X=[bsxfun(@rdivide,L-bsxfun(@times,E,R),den); ...
    bsxfun(@rdivide,R-bsxfun(@times,E,L),den)];
end

function Y=LOCAL_wall_apply(X,s0,E)
  N=numel(E); L=X(1:N,:); R=X(N+1:end,:);
  Y=[bsxfun(@times,s0,L+bsxfun(@times,E,R)); ...
    bsxfun(@times,s0,bsxfun(@times,E,L)+R)];
end

function gamma=LOCAL_outgoing(k,beta)
  gamma=sqrt(complex(k^2-beta.^2));
  flip=imag(gamma)<0 | (imag(gamma)==0&real(gamma)<0);
  gamma(flip)=-gamma(flip);
end

%% ==================== Refined boundary actions ====================
% Common grids use exact Fourier evaluation, never nearest-node matching.

function out=LOCAL_action(c,level,circle)
  N=size(circle.C,2);
  eta=LOCAL_interp_pair(level.eta,N);
  chan=struct('beta_m',level.beta,'gamma_m',level.gamma, ...
    'd',c.d,'K',numel(level.orders));
  [BL,BR]=bloch.incident_rhs(circle.C,chan,c.X_L,c.X_R);
  Acw=[bsxfun(@times,BL,level.s0.'),bsxfun(@times,BR,level.s0.')];
  [FL,FR]=bloch.farfield_extractors(circle.C,chan,c.X_L,c.X_R, ...
    circle.curvelen);
  raw=LOCAL_wall_apply(level.xi,level.s0,level.E)+[FL;FR]*eta;
  Nw=numel(level.orders);
  flux_left=.5*(level.xi_left-bsxfun(@times,level.E,level.xi_right))+ ...
    bsxfun(@times,1i*level.gamma,FL*eta);
  flux_right=.5*(-bsxfun(@times,level.E,level.xi_left)+level.xi_right)+ ...
    bsxfun(@times,1i*level.gamma,FR*eta);
  out=struct('residual',circle.Acc*eta+Acw*level.xi,'eta',eta, ...
    'raw_left',raw(1:Nw,:),'raw_right',raw(Nw+1:end,:), ...
    'defect_left',level.g(1:Nw,:)-raw(1:Nw,:), ...
    'defect_right',level.g(Nw+1:end,:)-raw(Nw+1:end,:), ...
    'flux_left',flux_left,'flux_right',flux_right, ...
    'source_nodes',N);
end

function level=LOCAL_attach_refined(level,base,fine)
  level.solve_raw_left=level.raw_left; level.solve_raw_right=level.raw_right;
  level.solve_flux_left=level.flux_left; level.solve_flux_right=level.flux_right;
  level.action_base=base;
  level.raw_left=fine.raw_left; level.raw_right=fine.raw_right;
  level.defect_left=fine.defect_left; level.defect_right=fine.defect_right;
  level.flux_left=fine.flux_left; level.flux_right=fine.flux_right;
  level.record.fixed_density_cross_action_change=max([ ...
    LOCAL_metric(base.raw_left,fine.raw_left), ...
    LOCAL_metric(base.raw_right,fine.raw_right), ...
    LOCAL_metric(base.flux_left,fine.flux_left), ...
    LOCAL_metric(base.flux_right,fine.flux_right)]);
end

function X2=LOCAL_interp_pair(X,N2)
  N=size(X,1)/2;
  X2=[LOCAL_trig_eval(X(1:N,:),N2);LOCAL_trig_eval(X(N+1:end,:),N2)];
end

function Y=LOCAL_trig_eval(X,N2)
  N=size(X,1); orders=(-N/2:N/2-1).';
  coefficients=fftshift(fft(X,[],1),1)/N;
  theta=(0:N2-1)'*2*pi/N2;
  Y=exp(1i*theta*orders.')*coefficients;
end

function out=LOCAL_common(c,coarse,official)
  y=-c.d/2+c.d*(0:c.wall_common_nodes-1)'/c.wall_common_nodes;
  Ec=LOCAL_fourier(y,coarse.orders,c); Ef=LOCAL_fourier(y,official.orders,c);
  Nc=numel(coarse.orders); Nf=numel(official.orders);
  vc=[Ec*coarse.raw_left;Ec*coarse.raw_right];
  vf=[Ef*official.raw_left;Ef*official.raw_right];
  vc0=[Ec*coarse.action_base.raw_left; ...
    Ec*coarse.action_base.raw_right];
  gc=[Ec*coarse.g(1:Nc,:);Ec*coarse.g(Nc+1:end,:)];
  gf=[Ef*official.g(1:Nf,:);Ef*official.g(Nf+1:end,:)];
  fc0=[Ec*coarse.action_base.flux_left;Ec*coarse.action_base.flux_right];
  fc=[Ec*coarse.flux_left;Ec*coarse.flux_right];
  ff=[Ef*official.flux_left;Ef*official.flux_right];
  fixed_value=LOCAL_metric_record(vc0,vc);
  fixed_flux=LOCAL_metric_record(fc0,fc);
  resolved_value=LOCAL_metric_record(vc,vf);
  resolved_flux=LOCAL_metric_record(fc,ff);
  out=struct('y',y,'value_coarse',vc,'value_official',vf, ...
    'prescribed_value_coarse',gc,'prescribed_value_official',gf, ...
    'flux_coarse',fc,'flux_official',ff, ...
    'fixed_density_flux_base',fc0, ...
    'fixed_density_flux_official',fc, ...
    'fixed_density_action_change',max(fixed_value.ratio,fixed_flux.ratio), ...
    'resolved_source_value_change',resolved_value.ratio, ...
    'resolved_source_flux_change',resolved_flux.ratio, ...
    'resolved_source_change',max(resolved_value.ratio,resolved_flux.ratio), ...
    'metrics',struct('fixed_density_value',fixed_value, ...
      'fixed_density_flux',fixed_flux,'resolved_source_value',resolved_value, ...
      'resolved_source_flux',resolved_flux), ...
    'shared_value_defect',max(LOCAL_metric(vc,gc),LOCAL_metric(vf,gf)), ...
    'prescribed_value_level_defect',LOCAL_metric(gc,gf), ...
    'gauge_defect',max([LOCAL_gauge(c,y,official.raw_left,official.orders), ...
      LOCAL_gauge(c,y,official.raw_right,official.orders), ...
      LOCAL_gauge(c,y,official.flux_left,official.orders), ...
      LOCAL_gauge(c,y,official.flux_right,official.orders)]));
end

function E=LOCAL_fourier(y,orders,c)
  beta=c.beta+2*pi*orders/c.d;
  E=exp(1i*y*beta.')/sqrt(c.d);
end

function value=LOCAL_gauge(c,y,coefficients,orders)
  u0=LOCAL_fourier(y,orders,c)*coefficients;
  u1=LOCAL_fourier(y+c.d,orders,c)*coefficients;
  value=norm(u1-exp(1i*c.beta*c.d)*u0,'fro')/ ...
    max([realmin,norm(u0,'fro'),norm(u1,'fro')]);
end

function public=LOCAL_public(level)
  public=rmfield(level,{'Acw','Awc','FL','FR'});
end

%% ==================== Independent operator oracles ====================
% Delta-T reference contracts proxy Hessians and never reads assembled A21.

function out=LOCAL_oracles(c,node,work,circle,official,common)
  try
    dt=LOCAL_delta_t(c,node,work,circle);
  catch ME
    dt=struct('available',false,'maximum_normalized_defect',Inf, ...
      'maximum_reference_change',Inf,'message',ME.message, ...
      'peak_workspace_mib',0);
  end
  try
    manufactured=LOCAL_manufactured(c);
  catch ME
    manufactured=struct('available',false,'maximum_relative_error',Inf, ...
      'maximum_minus_S_jump_defect',Inf,'message',ME.message);
  end
  try
    wall=LOCAL_wall_oracle(official);
  catch ME
    wall=struct('available',false,'maximum_value_inverse_defect',Inf, ...
      'maximum_flux_sign_defect',Inf,'message',ME.message);
  end
  try
    bloch=LOCAL_bloch_oracle(c,node,work,official);
  catch ME
    bloch=struct('available',false,'value_defect',Inf, ...
      'global_y_derivative_defect',Inf,'message',ME.message);
  end
  out=struct('actual_delta_t',dt, ...
    'manufactured',manufactured,'wall_modal',wall, ...
    'bloch',bloch, ...
    'cross_action',struct('available', ...
      isfinite(common.fixed_density_action_change), ...
      'minimum_separation',0.3, ...
      'refinement_change',common.fixed_density_action_change, ...
      'component_metrics',common.metrics));
  out.available=dt.available&&manufactured.available&&wall.available&& ...
    bloch.available;
end

function out=LOCAL_bloch_oracle(c,node,work,level)
  N=c.circle_action_nodes;
  [C,curvelen]=geom.construct_cont(N,'circle',0,0,c.R);
  eta=LOCAL_interp_pair(level.eta,N); tau=eta(1:N,:); zeta=eta(N+1:end,:);
  speed=sqrt(C(2,:).^2+C(5,:).^2); nx=C(5,:)./speed;
  ny=-C(2,:)./speed; weights=curvelen/N*speed;
  x=linspace(-0.45,0.45,64);
  targets=[x,x;-0.5*ones(size(x)),0.5*ones(size(x))];
  [pot,gx,gy,~,hxy,hyy]=kgreen([C(1,:);C(4,:)],targets, ...
    work.pars,work.proxy,work.proxy_gamma);
  D=-bsxfun(@times,gx,nx)-bsxfun(@times,gy,ny);
  Dy=-bsxfun(@times,hxy,nx)-bsxfun(@times,hyy,ny);
  S=pot; Sy=gy;
  V=[bsxfun(@times,D,weights),-bsxfun(@times,S,weights)]*eta;
  Vy=[bsxfun(@times,Dy,weights),-bsxfun(@times,Sy,weights)]*eta;
  bottom=1:numel(x); top=numel(x)+(1:numel(x));
  phase=exp(1i*c.beta*c.d);
  value=norm(V(top,:)-phase*V(bottom,:),'fro')/ ...
    max([realmin,norm(V(top,:),'fro'),norm(V(bottom,:),'fro')]);
  derivative=norm(Vy(top,:)-phase*Vy(bottom,:),'fro')/ ...
    max([realmin,norm(Vy(top,:),'fro'),norm(Vy(bottom,:),'fro')]);
  out=struct('available',all(isfinite([value,derivative])), ...
    'value_defect',value,'global_y_derivative_defect',derivative, ...
    'target_x',x,'bottom_y',-0.5,'top_y',0.5, ...
    'wall_single_layer_part_structural_by_fourier',true);
end

function out=LOCAL_delta_t(c,node,work,circle)
  N=c.circle_density_nodes; A21=circle.Acc(N+1:end,1:N);
  modes=c.delta_t_modes(:); defect=zeros(size(modes)); change=defect;
  absolute=defect; scales=defect;
  [R256,peak256]=LOCAL_delta_remainder(c,node,work,N);
  [R512,peak512]=LOCAL_delta_remainder(c,node,work,2*N);
  for j=1:numel(modes)
    ell=modes(j); phi=exp(1i*ell*(0:N-1)'*2*pi/N)/sqrt(2*pi*c.R);
    prod=A21*phi;
    [ref,scales(j)]=LOCAL_delta_ref(c,node,ell,N,R256);
    fine_full=LOCAL_delta_ref(c,node,ell,2*N,R512);
    fine=fine_full(1:2:end);
    absolute(j)=LOCAL_l2ds(prod-ref,c.R,N);
    defect(j)=absolute(j)/max(realmin,scales(j));
    change(j)=LOCAL_l2ds(fine-ref,c.R,N)/max([realmin, ...
      LOCAL_l2ds(fine_full,c.R,2*N),LOCAL_l2ds(ref,c.R,N)]);
  end
  out=struct('available',all(isfinite([defect;change;absolute;scales])), ...
    'modes',modes,'normalized_defects',defect, ...
    'absolute_defects',absolute,'constituent_scales',scales, ...
    'reference_changes',change,'maximum_normalized_defect',max(defect), ...
    'maximum_reference_change',max(change), ...
    'production_path','physical A21 from Kress/proxy assembly', ...
    'reference_path','direct proxy mixed-derivative contraction', ...
    'shared_assembled_matrix',false,'weighted_L2_ds',true, ...
    'peak_workspace_mib',max(peak256,peak512));
end

function [value,scale]=LOCAL_delta_ref(c,node,ell,N,remainder)
  theta=(0:N-1)'*2*pi/N;
  phi=exp(1i*ell*theta)/sqrt(2*pi*c.R);
  reg=remainder*phi;
  ko=node.k; ki=sqrt(c.rho_disk)*node.k;
  to=LOCAL_t(ell,ko,c.R); ti=LOCAL_t(ell,ki,c.R);
  value=(to-ti)*phi+reg;
  scale=abs(to)+abs(ti)+LOCAL_l2ds(reg,c.R,N);
end

function [remainder,peak]=LOCAL_delta_remainder(c,node,work,N)
  [C,curvelen]=geom.construct_cont(N,'circle',0,0,c.R);
  x=C(1,:); y=C(4,:); speed=sqrt(C(2,:).^2+C(5,:).^2);
  nx=C(5,:)./speed; ny=-C(2,:)./speed;
  X=x.'-x; Y=y.'-y; npair=N*N;
  hxx=zeros(npair,1); hxy=hxx; hyy=hxx;
  peak=0;
  for first=1:c.qp_pair_batch:npair
    last=min(npair,first+c.qp_pair_batch-1);
    target=[Y(first:last).';X(first:last).'];
    [~,~,h]=kernel.h2d_directch(node.k,work.proxy.Z,work.proxy.q,target);
    hxx(first:last)=h(3,:).'; hxy(first:last)=h(2,:).';
    hyy(first:last)=h(1,:).';
    info=whos; peak=max(peak,sum([info.bytes])/2^20);
  end
  hxx=reshape(hxx,N,N); hxy=reshape(hxy,N,N);
  hyy=reshape(hyy,N,N);
  mixed=-(nx.'.*hxx).*nx-(nx.'.*hxy).*ny- ...
    (ny.'.*hxy).*nx-(ny.'.*hyy).*ny;
  remainder=bsxfun(@times,mixed,curvelen/N*speed.');
  info=whos; peak=max(peak,sum([info.bytes])/2^20);
end

function value=LOCAL_t(ell,k,R)
  z=k*R; Jp=.5*(besselj(ell-1,z)-besselj(ell+1,z));
  Hp=.5*(besselh(ell-1,1,z)-besselh(ell+1,1,z));
  value=1i*pi*k^2*R/2*Jp*Hp;
end

function out=LOCAL_manufactured(c)
  N=64; [C,curvelen]=geom.construct_cont(N,'circle',0,0,c.R);
  [theta,~]=utils.triginterp(N); h=curvelen/N;
  geom0=struct('z',[C(1,:).',C(4,:).'], ...
    'zp',[C(2,:).',C(5,:).'],'zpp',[C(3,:).',C(6,:).']);
  geom0.speed=sqrt(sum(geom0.zp.^2,2));
  Rm=LOCAL_kress_matrix(N); modes=[0,1,-1,2,-2];
  errors=zeros(2,numel(modes),5); signerr=zeros(2,numel(modes));
  waves=[c.khat,sqrt(c.rho_disk)*c.khat];
  for a=1:2
    [K,S,Kstar]=LOCAL_free_ops(waves(a),theta,geom0,Rm,h);
    z=waves(a)*c.R;
    for j=1:numel(modes)
      ell=modes(j); phi=exp(1i*ell*theta(:));
      J=besselj(ell,z); H=besselh(ell,1,z);
      Jp=.5*(besselj(ell-1,z)-besselj(ell+1,z));
      Hp=.5*(besselh(ell-1,1,z)-besselh(ell+1,1,z));
      exact={1i*pi*c.R/2*J*H*phi, ...
        1i*pi*waves(a)*c.R/2*Jp*H*phi, ...
        1i*pi*waves(a)*c.R/2*J*Hp*phi, ...
        1i*pi*waves(a)*c.R/2*J*Hp*phi, ...
        1i*pi*waves(a)*c.R/2*Jp*H*phi};
      dSe=(-.5*eye(N)+Kstar)*phi; dSi=(.5*eye(N)+Kstar)*phi;
      num={S*phi,(.5*eye(N)+K)*phi,(-.5*eye(N)+K)*phi,dSe,dSi};
      for q=1:5
        errors(a,j,q)=norm(num{q}-exact{q})/max(realmin,norm(exact{q}));
      end
      signerr(a,j)=norm(-dSe+dSi-phi)/max(realmin,norm(phi));
    end
  end
  out=struct('available',all(isfinite([errors(:);signerr(:)])), ...
    'modes',modes,'relative_errors',errors, ...
    'maximum_relative_error',max(errors,[],'all'), ...
    'minus_S_jump_defects',signerr, ...
    'maximum_minus_S_jump_defect',max(signerr,[],'all'), ...
    'zeta_equals_minus_sigma',true);
end

function [K,S,Kstar]=LOCAL_free_ops(k,t,geom0,Rm,h)
  [L1,L2,Ls1,Ls2]=kernel.kress_l_splits(k,t,geom0);
  [M1,M2]=kernel.kress_mn_splits(k,t,geom0);
  K=Rm.*L1+h*L2; S=Rm.*M1+h*M2;
  Kstar=Rm.*Ls1+h*Ls2;
end

function out=LOCAL_wall_oracle(level)
  N=numel(level.orders); errs=zeros(N,2);
  for j=1:N
    A=level.s0(j)*[1,level.E(j);level.E(j),1];
    Q=.5*[1,-level.E(j);-level.E(j),1]; X=A\eye(2);
    errs(j,1)=norm(A*X-eye(2),'fro')/norm(eye(2),'fro');
    g=level.gamma(j); s=level.s0(j); e=level.E(j);
    global_dx=[1i*g*s,-1i*g*s*e;1i*g*s*e,-1i*g*s];
    outward=[-global_dx(1,:);global_dx(2,:)];
    errs(j,2)=norm(Q-outward,'fro')/max(realmin,norm(outward,'fro'));
  end
  out=struct('available',all(isfinite(errs),'all'), ...
    'maximum_value_inverse_defect',max(errs(:,1)), ...
    'maximum_flux_sign_defect',max(errs(:,2)),'errors',errs);
end

function Rm=LOCAL_kress_matrix(N)
  rvec=quad.quad_kress_rvec(N);
  idx=mod((0:N-1)-(0:N-1).',N)+1; Rm=rvec(idx);
end

%% ==================== Scalar diagnostics ====================
% Metrics are scale covariant and preserve exact-zero components.

function value=LOCAL_l2ds(x,R,N)
  value=sqrt(2*pi*R/N)*norm(x);
end

function value=LOCAL_metric(a,b)
  value=norm(a-b,'fro')/max([realmin,norm(a,'fro'),norm(b,'fro')]);
end

function out=LOCAL_metric_record(a,b)
  numerator=norm(a-b,'fro'); na=norm(a,'fro'); nb=norm(b,'fro');
  zero=na==0&&nb==0;
  out=struct('numerator',numerator,'left_norm',na,'right_norm',nb, ...
    'zero_component',zero,'ratio',numerator/max([realmin,na,nb]));
end

function out=LOCAL_angular_tail(residual,N0,N1)
  A=fftshift(fft(residual(1:N1,:),[],1),1)/sqrt(N1);
  B=fftshift(fft(residual(N1+1:end,:),[],1),1)/sqrt(N1);
  orders=(-N1/2:N1/2-1).';
  mask=orders<-N0/2 | orders>=N0/2;
  total=norm([A;B],'fro')^2;
  numerator=norm([A(mask,:);B(mask,:)],'fro')^2;
  zero=total==0;
  out=struct('numerator',numerator,'denominator',total, ...
    'zero_component',zero,'ratio',numerator/max(realmin,total));
end
