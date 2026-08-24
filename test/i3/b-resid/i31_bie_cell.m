function out = i31_bie_cell(action,c,node,varargin)
%I31_BIE_CELL Reconstruct qualified BIE traces and safe-target fields.
% Purpose:
%   Recover true incoming BIE responses, build one-sided circle traces, and
%   qualify field evaluation outside the frozen circle and wall collars.
% Input:
%   action - 'density', 'surface', 'safe', or 'sample'.
% Output:
%   out    - Work data, a gate record, or safe-target field samples.
% Main algorithm:
%   Rebuild the anchored one-cell response once; assemble individual Kress
%   Dirichlet actions; use direct layer potentials only outside fixed collars;
%   and evaluate the resulting layer potentials only at qualified targets.
% Based on:
%   test/i3/g-resid/i31_bie_fit.m and
%   research/projects/eig-apost/implementation/i3/design-3-1d.md.
% Main changes:
%   Densities are never called traces and close targets are never evaluated
%   directly; Q1 conformity is handled by i31_fe_cell.
% Numerical goal:
%   Supply qualified BIE-informed data to i31_fe_cell, not a strong residual.

  action=lower(char(action));
  if strcmp(action,'density')
    out=LOCAL_density(c,node,varargin{1},varargin{2});
  elseif strcmp(action,'surface')
    out=LOCAL_surface(c,node,varargin{1},varargin{2});
  elseif strcmp(action,'safe')
    out=LOCAL_safe(c,node,varargin{1},varargin{2},varargin{3});
  elseif strcmp(action,'sample')
    out=LOCAL_raw_map(c,node,varargin{1},varargin{2},varargin{3},varargin{4});
  else
    error('i31b:Execution','Unknown i31_bie_cell action.');
  end
end

%% ==================== Density response ====================
% Rebuild one anchored BIE response and the actual lead density maps.

function out=LOCAL_density(c,node,frame,prop)
  anchor=frame.proxy_chart.anchor; proxy_gamma=LOCAL_gamma(node.k,anchor);
  pars=struct('k',node.k,'beta',c.beta,'d',c.d,'periodic_axis','y', ...
    'pair_batch',c.qp_pair_batch);
  pspec=struct('H',c.H,'proxy_dist',c.proxy_dist,'N_side',c.level.N_side, ...
    'N_top',c.level.N_top,'N_proxy_edge',c.level.N_proxy_edge, ...
    'M_pw',c.level.M_pw);
  [proxy,~,~,pinfo]=i21_kproxy(pars,pspec,proxy_gamma, ...
    frame.proxy_chart,'collocation');
  channels=kchan(node.k,c.beta,c.d,c.M,c.X_R-c.X_L,node.gamma, ...
    frame.port_anchor.fingerprint);
  [C,curvelen]=geom.construct_cont(c.source_base,'circle',0,0,c.R);
  [BL,BR]=bloch.incident_rhs(C,channels,c.X_L,c.X_R);
  [FL,FR]=bloch.farfield_extractors(C,channels,c.X_L,c.X_R,curvelen);
  rhs=full(complex([BL,BR])); Aqp=node.Aqp; rc=rcond(Aqp);
  if ~pinfo.available||~isfinite(rc)||rc<c.bie_rcond_min
    error('i31b:BieDensity','The anchored proxy or BIE factor is unavailable.');
  end
  try, H=-(Aqp\rhs); catch ME
    error('i31b:BieDensity','The BIE density solve failed: %s',ME.message);
  end
  residual=Aqp*H+rhs;
  relative=zeros(1,size(rhs,2)); backward=relative; anorm=norm(Aqp,1);
  for j=1:size(rhs,2)
    relative(j)=norm(residual(:,j),1)/max(realmin,norm(rhs(:,j),1));
    backward(j)=norm(residual(:,j),1)/max(realmin, ...
      anorm*norm(H(:,j),1)+norm(rhs(:,j),1));
  end
  HL=H(:,1:c.K); HR=H(:,c.K+1:end);
  rebuilt=struct('R_L',FL*HL,'T_RL',diag(node.phase)+FL*HR, ...
    'T_LR',diag(node.phase)+FR*HL,'R_R',FR*HR);
  names={'R_L','T_RL','T_LR','R_R'}; block=zeros(1,4);
  for j=1:4
    block(j)=norm(rebuilt.(names{j})-node.blocks.(names{j}),'fro')/ ...
      max(1,norm(node.blocks.(names{j}),'fro'));
  end
  speed=sqrt(C(2,:).^2+C(5,:).^2); h=curvelen/c.source_base;
  scale=sqrt(h*speed).*sqrt((1/h)./speed);
  speed_defect=max(abs(speed-mean(speed)))/max(realmin,mean(speed));
  scale_defect=max(abs(scale-1));
  Hplus=HL*prop.Ap+HR*prop.Bp*prop.Pplus;
  Hminus=HL*prop.Am*prop.Pminus+HR*prop.Bm;
  pass=pinfo.available&&isfinite(rc)&&rc>=c.bie_rcond_min&& ...
    all(isfinite(H),'all')&&max([relative,backward])<=c.bie_residual_max&& ...
    max(block)<=c.block_identity_max&&speed_defect<=1e-13&&scale_defect<=1e-13;
  record=struct('pass',pass,'Aqp_rcond',rc, ...
    'max_rhs_relative_residual',max(relative), ...
    'max_rhs_backward_error',max(backward),'rebuilt_block_defects',block, ...
    'circle_speed_defect',speed_defect,'circle_scale_product_defect',scale_defect, ...
    'density_order','[tau;zeta], zeta=-sigma', ...
    'zeta_equals_minus_sigma',true,'response_size',size(H), ...
    'H_plus_size',size(Hplus),'H_minus_size',size(Hminus));
  out=struct('C',C,'curvelen',curvelen,'proxy',proxy,'pars',pars, ...
    'proxy_gamma',proxy_gamma,'channels',channels,'rhs',rhs, ...
    'H_L',HL,'H_R',HR,'H_plus',Hplus,'H_minus',Hminus,'record',record);
end

function gamma=LOCAL_gamma(k,anchor)
  delta=k-anchor.kc;
  gamma=anchor.gamma_seed.*exp(0.5*log(1+delta./(anchor.kc-anchor.beta_m))+ ...
    0.5*log(1+delta./(anchor.kc+anchor.beta_m)));
end

%% ==================== One-sided circle traces ====================
% Individual free-space and QP Dirichlet actions use Kress product quadrature.

function out=LOCAL_surface(c,node,density,prop)
  base=LOCAL_surface_level(c,node,density,c.source_base,prop);
  refined=LOCAL_surface_level(c,node,density,c.source_refined,prop);
  names={'plus','minus'}; changes=zeros(2,3);
  trace_norms=zeros(2,4);
  for j=1:2
    fields={'exterior','interior','common'};
    for k=1:3
      a=interpft(base.trace.(names{j}).(fields{k}),c.source_refined,1);
      b=refined.trace.(names{j}).(fields{k});
      changes(j,k)=LOCAL_relative(a,b);
    end
    trace_norms(j,:)=[norm(base.trace.(names{j}).exterior,'fro'), ...
      norm(base.trace.(names{j}).interior,'fro'), ...
      norm(refined.trace.(names{j}).exterior,'fro'), ...
      norm(refined.trace.(names{j}).interior,'fro')];
  end
  jump=base.trace.all.exterior-base.trace.all.interior;
  algebra=(node.Aqp*[density.H_L,density.H_R]+density.rhs);
  identity=LOCAL_relative(jump,algebra(1:c.source_base,:));
  oracle=LOCAL_manufactured(base.ops,c);
  pass=all(isfinite(changes),'all')&&max(changes,[],'all')<= ...
    c.source_refinement_max&& ...
    identity<=c.surface_identity_max&&oracle.pass;
  out=density; out.density_record=density.record;
  out.trace=struct();
  for j=1:2
    name=names{j};
    out.trace.(name)=interpft(base.trace.(name).common,c.source_refined,1);
  end
  out.trace_theta=(0:c.source_refined-1)'*2*pi/c.source_refined;
  out.record=struct('pass',pass,'value_jump_identity_defect',identity, ...
    'trace_refinement_columns',{{'exterior','interior','common'}}, ...
    'trace_256_to_512_changes',changes,'manufactured',oracle, ...
    'one_sided_trace_norm_columns', ...
    {{'base_exterior','base_interior','refined_exterior','refined_interior'}}, ...
    'one_sided_trace_norms',trace_norms, ...
    'source_refinement_scope','trace_safe_wall_only', ...
    'individual_normal_traces_computed',false, ...
    'individual_normal_trace_status','INDIVIDUAL_NORMAL_TRACES_NOT_COMPUTED', ...
    'raw_discrete_normal_jump_residual', ...
    norm(algebra(c.source_base+1:end,:),'fro')/max(1,norm(density.rhs,'fro')));
end

function out=LOCAL_surface_level(c,node,density,N,prop)
  if N==c.source_base
    C=density.C; curvelen=density.curvelen;
    eta=struct('plus',density.H_plus,'minus',density.H_minus, ...
      'all',[density.H_L,density.H_R]);
  else
    [C,curvelen]=geom.construct_cont(N,'circle',0,0,c.R);
    eta=struct('plus',LOCAL_interp_density(density.H_plus,N), ...
      'minus',LOCAL_interp_density(density.H_minus,N), ...
      'all',LOCAL_interp_density([density.H_L,density.H_R],N));
  end
  [BL,BR]=bloch.incident_rhs(C,density.channels,c.X_L,c.X_R);
  incall=full(complex([BL,BR])); ops=LOCAL_trace_ops(c,C,curvelen,density);
  incoming=struct('plus',[prop.Ap;prop.Bp*prop.Pplus], ...
    'minus',[prop.Am*prop.Pminus;prop.Bm],'all',eye(2*c.K));
  names={'plus','minus','all'}; trace=struct();
  for j=1:3
    name=names{j}; inc=incall(1:N,:)*incoming.(name);
    trace.(name)=LOCAL_trace_set(ops,eta.(name),inc,N);
  end
  out=struct('C',C,'curvelen',curvelen,'ops',ops,'eta',eta, ...
    'incoming',incoming,'trace',trace);
end

function eta2=LOCAL_interp_density(eta,N2)
  N=size(eta,1)/2;
  eta2=[interpft(eta(1:N,:),N2,1);interpft(eta(N+1:end,:),N2,1)];
end

function out=LOCAL_trace_set(ops,eta,incident,N)
  tau=eta(1:N,:); zeta=eta(N+1:end,:);
  exterior=incident+(.5*eye(N)+ops.Kqp)*tau-ops.Sqp*zeta;
  interior=(-.5*eye(N)+ops.Ki)*tau-ops.Si*zeta;
  out=struct('exterior',exterior,'interior',interior, ...
    'common',.5*(exterior+interior));
end

function ops=LOCAL_trace_ops(c,C,curvelen,density)
  N=size(C,2); h=curvelen/N; [t,~]=utils.triginterp(N);
  geom=struct('z',[C(1,:).',C(4,:).'],'zp',[C(2,:).',C(5,:).'], ...
    'zpp',[C(3,:).',C(6,:).']); geom.speed=sqrt(sum(geom.zp.^2,2));
  Rm=LOCAL_kress_matrix(N);
  [Kext,Sext]=LOCAL_free_ops(c.khat,t,geom,Rm,h);
  [Kint,Sint]=LOCAL_free_ops(sqrt(c.rho_disk)*c.khat,t,geom,Rm,h);
  [pot,gx,gy]=LOCAL_qp_vg([C(1,:);C(4,:)],[C(1,:);C(4,:)], ...
    density.pars,density.proxy,density.proxy_gamma);
  [Rdiag,Gdiag]=LOCAL_regular_diag(density.pars,density.proxy);
  [pf,gxf,gyf]=LOCAL_free_value_gradient(c.khat,C);
  off=~eye(N); potproxy=zeros(N); gxproxy=zeros(N); gyproxy=zeros(N);
  potproxy(off)=pot(off)-pf(off); gxproxy(off)=gx(off)-gxf(off);
  gyproxy(off)=gy(off)-gyf(off);
  potproxy(1:N+1:end)=Rdiag; gxproxy(1:N+1:end)=Gdiag(1);
  gyproxy(1:N+1:end)=Gdiag(2);
  speed=geom.speed.'; nx=C(5,:)./speed; ny=-C(2,:)./speed;
  Kproxy=-((gxproxy.*nx)+(gyproxy.*ny)).*(h*speed);
  Sproxy=potproxy.*(h*speed);
  ops=struct('Kqp',Kext+Kproxy,'Sqp',Sext+Sproxy, ...
    'Ki',Kint,'Si',Sint,'Kext_free',Kext,'Sext_free',Sext, ...
    'Kint_free',Kint,'Sint_free',Sint,'theta',t(:));
end

function [K,S]=LOCAL_free_ops(k,t,geom,Rm,h)
  [L1,L2]=kernel.kress_l_splits(k,t,geom);
  [M1,M2]=kernel.kress_mn_splits(k,t,geom);
  K=Rm.*L1+h*L2; S=Rm.*M1+h*M2;
end

function R=LOCAL_kress_matrix(N)
  rvec=quad.quad_kress_rvec(N);
  idx=mod((0:N-1)-(0:N-1).',N)+1; R=rvec(idx);
end

function [Rdiag,Gdiag]=LOCAL_regular_diag(pars,proxy)
  [Rdiag,Gdiag]=kernel.h2d_directch(pars.k,proxy.Z,proxy.q,[0;0]);
  Rdiag=Rdiag(1); Gdiag=Gdiag([2 1],1).';
end

function [pot,gx,gy]=LOCAL_free_value_gradient(k,C)
  x=C(1,:).'-C(1,:); y=C(4,:).'-C(4,:); r=hypot(x,y);
  off=~eye(size(C,2)); r(~off)=1; z=k*r;
  pot=1i/4*besselh(0,1,z); coeff=-1i*k/4*besselh(1,1,z)./r;
  gx=coeff.*x; gy=coeff.*y; pot(~off)=0; gx(~off)=0; gy(~off)=0;
end

function out=LOCAL_manufactured(ops,c)
  ell=[0 1 -1 2 -2]; theta=ops.theta; errors=zeros(numel(ell),6);
  waves=[c.khat,sqrt(c.rho_disk)*c.khat];
  Kop={ops.Kext_free,ops.Kint_free}; Sop={ops.Sext_free,ops.Sint_free};
  for ik=1:2
    k=waves(ik); z=k*c.R;
    for j=1:numel(ell)
      l=ell(j); phi=exp(1i*l*theta);
      J=besselj(l,z); H=besselh(l,1,z);
      Jp=.5*(besselj(l-1,z)-besselj(l+1,z));
      Hp=.5*(besselh(l-1,1,z)-besselh(l+1,1,z));
      scoef=1i*pi*c.R/2*J*H;
      dpcoef=1i*pi*k*c.R/2*Jp*H;
      dmcoef=1i*pi*k*c.R/2*J*Hp;
      numS=Sop{ik}*phi; numDp=(.5*eye(numel(phi))+Kop{ik})*phi;
      numDm=(-.5*eye(numel(phi))+Kop{ik})*phi;
      col=(ik-1)*3;
      errors(j,col+1)=norm(numS-scoef*phi)/max(1,norm(scoef*phi));
      errors(j,col+2)=norm(numDp-dpcoef*phi)/max(1,norm(dpcoef*phi));
      errors(j,col+3)=norm(numDm-dmcoef*phi)/max(1,norm(dmcoef*phi));
    end
  end
  out=struct('modes',ell,'columns',{{'S_ext','Dplus_ext','Dminus_ext', ...
    'S_int','Dplus_int','Dminus_int'}},'relative_errors',errors, ...
    'maximum_relative_error',max(errors,[],'all'), ...
    'pass',all(isfinite(errors),'all')&&max(errors,[],'all')<= ...
    c.manufactured_trace_max,'fundamental_solution','i/4 H0^(1)');
end

%% ==================== Safe rings and wall diagnostics ====================
% The refined source order is restricted to surface, ring, and wall targets.

function out=LOCAL_safe(c,node,surface,prop,coords)
  theta=surface.trace_theta; Tinner=[(c.R-c.delta_c)*cos(theta).'; ...
    (c.R-c.delta_c)*sin(theta).'];
  Touter=[(c.R+c.delta_c)*cos(theta).'; ...
    (c.R+c.delta_c)*sin(theta).'];
  y=-.5+(0:c.wall_samples-1)'/c.wall_samples;
  xwall=[-.5,-.5+c.delta_w,.5-c.delta_w,.5];
  sides=LOCAL_side_data(surface,prop);
  states=struct('plus',{{coords.cplus,prop.Pplus*coords.cplus}}, ...
    'minus',{{coords.cminus,prop.Pminus*coords.cminus}});
  names={'plus','minus'}; change_ring=zeros(1,4); change_ring_actual=[];
  refined=LOCAL_refined_source(surface,c);
  work=struct(); p=0;
  for j=1:2
    name=names{j}; side=sides.(name);
    base_inner=LOCAL_raw_map(c,node,surface,side.eta,side.incoming,Tinner);
    base_outer=LOCAL_raw_map(c,node,surface,side.eta,side.incoming,Touter);
    eta2=LOCAL_interp_density(side.eta,c.source_refined);
    ref_inner=LOCAL_raw_map(c,node,refined,eta2,side.incoming,Tinner);
    ref_outer=LOCAL_raw_map(c,node,refined,eta2,side.incoming,Touter);
    p=p+1; change_ring(p)=LOCAL_relative(base_inner,ref_inner);
    p=p+1; change_ring(p)=LOCAL_relative(base_outer,ref_outer);
    for is=1:2
      v=states.(name){is};
      change_ring_actual=[change_ring_actual, ...
        LOCAL_relative(base_inner*v,ref_inner*v), ...
        LOCAL_relative(base_outer*v,ref_outer*v)]; %#ok<AGROW>
    end
    work.(name)=side; work.(name).ring_inner=base_inner;
    work.(name).ring_outer=base_outer;
  end
  wall_change=[]; wall_change_actual=[]; wall_base=struct();
  for j=1:2
    name=names{j}; side=sides.(name);
    eta2=LOCAL_interp_density(side.eta,c.source_refined);
    for ix=1:4
      T=[xwall(ix)*ones(1,numel(y));y.'];
      a=LOCAL_raw_map(c,node,surface,side.eta,side.incoming,T);
      b=LOCAL_raw_map(c,node,refined,eta2,side.incoming,T);
      wall_base.(name){ix}=a; %#ok<AGROW>
      wall_change(end+1)=LOCAL_relative(a,b); %#ok<AGROW>
      for is=1:2
        v=states.(name){is};
        wall_change_actual(end+1)=LOCAL_relative(a*v,b*v); %#ok<AGROW>
      end
    end
    work.(name).wall_left=wall_base.(name){2};
    work.(name).wall_right=wall_base.(name){3};
  end
  diagnostics=LOCAL_wall_diagnostics(c,node,sides,wall_base,prop,coords,y,surface);
  seam=LOCAL_raw_seam(c,node,surface,sides,states);
  qualification=[change_ring,change_ring_actual,wall_change,wall_change_actual];
  pass=all(isfinite(qualification))&& ...
    max(qualification)<=c.source_refinement_max&&seam.finite;
  out=surface; out.surface_record=surface.record; out.safe=work;
  out.wall_y=y; out.record=struct('pass',pass, ...
    'safe_ring_256_to_512_changes',change_ring, ...
    'safe_ring_actual_state_changes',change_ring_actual, ...
    'wall_256_to_512_changes',wall_change, ...
    'wall_actual_state_changes',wall_change_actual,'raw_wall',diagnostics, ...
    'raw_bloch',seam,'source_refinement_scope','trace_safe_wall_only');
end

function sides=LOCAL_side_data(surface,prop)
  sides.plus=struct('eta',surface.H_plus, ...
    'incoming',[prop.Ap;prop.Bp*prop.Pplus], ...
    'dleft',prop.Dplus,'dright',prop.Dplus*prop.Pplus, ...
    'common',surface.trace.plus);
  sides.minus=struct('eta',surface.H_minus, ...
    'incoming',[prop.Am*prop.Pminus;prop.Bm], ...
    'dleft',prop.Dminus*prop.Pminus,'dright',prop.Dminus, ...
    'common',surface.trace.minus);
end

function refined=LOCAL_refined_source(surface,c)
  [C,curvelen]=geom.construct_cont(c.source_refined,'circle',0,0,c.R);
  refined=surface; refined.C=C; refined.curvelen=curvelen;
end

function out=LOCAL_wall_diagnostics(c,node,sides,wall,prop,coords,y,surface)
  names={'plus','minus'}; shared=[]; shared_actual=[]; outside=[]; outside_actual=[];
  states=struct('plus',{{coords.cplus,prop.Pplus*coords.cplus}}, ...
    'minus',{{coords.cminus,prop.Pminus*coords.cminus}});
  for j=1:2
    name=names{j}; side=sides.(name);
    dl=LOCAL_fourier(node,side.dleft,y,c); dr=LOCAL_fourier(node,side.dright,y,c);
    shared=[shared,LOCAL_relative(wall.(name){1},dl), ...
      LOCAL_relative(wall.(name){4},dr)]; %#ok<AGROW>
    outside=[outside,LOCAL_outside_energy(wall.(name){1},y,c), ...
      LOCAL_outside_energy(wall.(name){4},y,c)]; %#ok<AGROW>
    for is=1:2
      v=states.(name){is};
      shared_actual=[shared_actual,LOCAL_relative(wall.(name){1}*v,dl*v), ...
        LOCAL_relative(wall.(name){4}*v,dr*v)]; %#ok<AGROW>
      outside_actual=[outside_actual, ...
        LOCAL_outside_energy(wall.(name){1}*v,y,c), ...
        LOCAL_outside_energy(wall.(name){4}*v,y,c)]; %#ok<AGROW>
    end
  end
  adjacent=[LOCAL_relative(wall.plus{4},wall.plus{1}*prop.Pplus), ...
    LOCAL_relative(wall.minus{1},wall.minus{4}*prop.Pminus)];
  adjacent_actual=[LOCAL_relative(wall.plus{4}*coords.cplus, ...
    wall.plus{1}*(prop.Pplus*coords.cplus)), ...
    LOCAL_relative(wall.minus{1}*coords.cminus, ...
    wall.minus{4}*(prop.Pminus*coords.cminus))];
  yc=y; q=coords.q; center_left=LOCAL_center_raw(c,node,q,[-.5*ones(1,numel(yc));yc.']);
  center_right=LOCAL_center_raw(c,node,q,[.5*ones(1,numel(yc));yc.']);
  center=[LOCAL_relative(center_left,wall.minus{4}*coords.cminus), ...
    LOCAL_relative(center_right,wall.plus{1}*coords.cplus)];
  out=struct('raw_to_shared_trace_defects',shared, ...
    'raw_to_shared_actual_state_defects',shared_actual, ...
    'adjacent_raw_direct_defects',adjacent, ...
    'adjacent_raw_actual_state_defects',adjacent_actual, ...
    'center_first_raw_defects',center,'outside_M_energy_ratios',outside, ...
    'outside_M_actual_state_energy_ratios',outside_actual, ...
    'amplitude_hard_gate_applied',false, ...
    'sample_count',numel(y),'trace_source_order',c.source_base, ...
    'normal_jump_status',surface.record.individual_normal_trace_status);
end

function ratio=LOCAL_outside_energy(values,y,c)
  gauge=values.*exp(-1i*c.beta*y);
  F=fft(gauge,[],1); modes=[0:c.wall_samples/2-1,-c.wall_samples/2:-1];
  keep=abs(modes)<=c.M;
  ratio=sum(abs(F(~keep,:)).^2,'all')/max(realmin,sum(abs(F).^2,'all'));
end

function out=LOCAL_raw_seam(c,node,surface,sides,states)
  x=linspace(-.46,.46,65); defects=zeros(1,4); actual=[];
  names={'plus','minus'};
  for j=1:2
    side=sides.(names{j}); top=[x;.5*ones(size(x))]; bottom=[x;-.5*ones(size(x))];
    ut=LOCAL_raw_map(c,node,surface,side.eta,side.incoming,top);
    ub=LOCAL_raw_map(c,node,surface,side.eta,side.incoming,bottom);
    defects(2*j-1)=LOCAL_relative(ut,exp(1i*c.beta*c.d)*ub);
    defects(2*j)=LOCAL_relative(ut.*exp(-1i*c.beta/2), ...
      ub.*exp(1i*c.beta/2));
    for is=1:2
      v=states.(names{j}){is};
      actual=[actual,LOCAL_relative(ut*v,exp(1i*c.beta*c.d)*(ub*v)), ...
        LOCAL_relative((ut*v)*exp(-1i*c.beta/2), ...
        (ub*v)*exp(1i*c.beta/2))]; %#ok<AGROW>
    end
  end
  out=struct('physical_and_gauge_defects',defects, ...
    'actual_state_physical_and_gauge_defects',actual, ...
    'finite',all(isfinite([defects,actual])),'amplitude_hard_gate_applied',false);
end

%% ==================== Direct field evaluation ====================
% Batched pair matrices are released immediately after density contraction.

function value=LOCAL_raw_map(c,node,work,eta,incoming,T)
  nt=size(T,2); value=complex(zeros(nt,size(eta,2))); N=size(work.C,2);
  inside=hypot(T(1,:),T(2,:))<c.R;
  for first=1:c.target_batch:nt
    idx=first:min(nt,first+c.target_batch-1); in=inside(idx);
    if any(in)
      pair=LOCAL_pair('free',sqrt(c.rho_disk)*c.khat,work.C,T(:,idx(in)),work);
      L=LOCAL_layers(pair,work.C,work.curvelen);
      value(idx(in),:)=L.D*eta(1:N,:)+L.minusS*eta(N+1:end,:);
    end
    if any(~in)
      pair=LOCAL_pair('qp',c.khat,work.C,T(:,idx(~in)),work);
      L=LOCAL_layers(pair,work.C,work.curvelen);
      inc=LOCAL_incident(node,incoming,T(:,idx(~in)),c);
      value(idx(~in),:)=inc+L.D*eta(1:N,:)+L.minusS*eta(N+1:end,:);
    end
  end
end

function value=LOCAL_center_raw(c,node,q,T)
  qL=q(1:c.K,:); qR=q(c.K+1:end,:);
  psi=exp(1i*T(2,:).'*node.beta_m(:).')/sqrt(c.d);
  er=exp(1i*(T(1,:).'-c.X_L)*node.gamma(:).');
  el=exp(-1i*(T(1,:).'-c.X_R)*node.gamma(:).');
  value=(psi.*er)*qL+(psi.*el)*qR;
end

function value=LOCAL_fourier(node,coeff,y,c)
  value=exp(1i*y(:)*node.beta_m(:).')/sqrt(c.d)*coeff;
end

function value=LOCAL_incident(node,incoming,T,c)
  a=incoming(1:c.K,:); b=incoming(c.K+1:end,:);
  psi=exp(1i*T(2,:).'*node.beta_m(:).')/sqrt(c.d);
  er=exp(1i*(T(1,:).'-c.X_L)*node.gamma(:).');
  el=exp(-1i*(T(1,:).'-c.X_R)*node.gamma(:).');
  value=(psi.*er)*a+(psi.*el)*b;
end

function L=LOCAL_layers(pair,C,curvelen)
  N=size(C,2); h=curvelen/N; speed=sqrt(C(2,:).^2+C(5,:).^2);
  nx=C(5,:)./speed; ny=-C(2,:)./speed; weight=h*speed;
  L=struct('D',-(pair.gx.*nx+pair.gy.*ny).*weight, ...
    'minusS',-pair.pot.*weight);
end

function out=LOCAL_pair(kind,k,C,T,work)
  src=[C(1,:);C(4,:)];
  if strcmp(kind,'qp')
    [pot,gx,gy]=LOCAL_qp_vg(src,T,work.pars,work.proxy,work.proxy_gamma);
  else
    x=T(1,:).'-src(1,:); y=T(2,:).'-src(2,:); r=hypot(x,y); z=k*r;
    pot=1i/4*besselh(0,1,z); coeff=-1i*k/4*besselh(1,1,z)./r;
    gx=coeff.*x; gy=coeff.*y;
  end
  out=struct('pot',pot,'gx',gx,'gy',gy);
end

function value=LOCAL_relative(a,b)
  value=norm(a-b,'fro')/max([1,norm(a,'fro'),norm(b,'fro')]);
end

%% ==================== Quasiperiodic kernel ====================
% This value/first-gradient evaluator omits unused Hessian arrays.

function [pot,gx,gy]=LOCAL_qp_vg(src,trg,pars,proxy,branch_gamma)
  src_comp=src([2 1],:); trg_comp=trg([2 1],:);
  [pot,gperiodic,gnonperiodic]=LOCAL_xperiodic( ...
    src_comp,trg_comp,pars,proxy,branch_gamma);
  gx=gnonperiodic; gy=gperiodic;
end

function [pot,gx,gy]=LOCAL_xperiodic(src,trg,pars,proxy,branch_gamma)
  d=pars.d; beta=pars.beta; k=pars.k; q=proxy.q; Z=proxy.Z;
  H=proxy.H; Cup=proxy.C_up(:); Cdown=proxy.C_down(:);
  ns=size(src,2); nt=size(trg,2);
  X=trg(1,:).'-src(1,:); Y=trg(2,:).'-src(2,:);
  shift=round(X/d); X0=X-shift*d; phase=exp(1i*beta*shift*d);
  pot=complex(zeros(nt,ns)); gx=pot; gy=pot;
  central=abs(Y)<=H; upper=Y>H; lower=Y<-H;
  if any(central,'all')
    index=find(central);
    for first=1:pars.pair_batch:numel(index)
      take=index(first:min(numel(index),first+pars.pair_batch-1));
      T=[X0(take).';Y(take).'];
      [p0,g0]=LOCAL_free_vg(k,[0;0],1,T);
      [pp,gp]=LOCAL_free_vg(k,Z,q,T); ph=phase(take).';
      pot(take)=(p0+pp).*ph;
      gx(take)=(g0(1,:)+gp(1,:)).*ph;
      gy(take)=(g0(2,:)+gp(2,:)).*ph;
    end
  end
  if any(upper|lower,'all')
    np=numel(Cup); m=(-(np-1)/2:(np-1)/2).';
    beta_m=beta+2*pi*m/d; branch_gamma=branch_gamma(:);
    if numel(branch_gamma)~=np||any(~isfinite(branch_gamma))
      error('i31b:SafeEvaluation','The anchored proxy branch has the wrong size.');
    end
    if any(upper,'all')
      xu=X0(upper).'; yu=Y(upper).';
      basis=exp(1i*beta_m*xu).*exp(1i*branch_gamma*(yu-H));
      ph=phase(upper).';
      pot(upper)=sum(Cup.*basis,1).*ph;
      gx(upper)=sum(Cup.*basis.*(1i*beta_m),1).*ph;
      gy(upper)=sum(Cup.*basis.*(1i*branch_gamma),1).*ph;
    end
    if any(lower,'all')
      xd=X0(lower).'; yd=Y(lower).';
      basis=exp(1i*beta_m*xd).*exp(-1i*branch_gamma*(yd+H));
      ph=phase(lower).';
      pot(lower)=sum(Cdown.*basis,1).*ph;
      gx(lower)=sum(Cdown.*basis.*(1i*beta_m),1).*ph;
      gy(lower)=sum(Cdown.*basis.*(-1i*branch_gamma),1).*ph;
    end
  end
end

function [pot,grad]=LOCAL_free_vg(k,sources,charge,target)
  charge=reshape(charge,1,[]);
  x=target(1,:).'-sources(1,:); y=target(2,:).'-sources(2,:);
  r=hypot(x,y); coincident=r==0; r(coincident)=1; z=k*r;
  h0=besselh(0,1,z); coeff=-1i*k/4*besselh(1,1,z)./r;
  h0(coincident)=0; coeff(coincident)=0;
  pot=(1i/4*sum(h0.*charge,2)).';
  grad=[sum(coeff.*x.*charge,2).';sum(coeff.*y.*charge,2).'];
end
