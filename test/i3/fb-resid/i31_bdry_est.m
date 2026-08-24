function out = i31_bdry_est(c,node,prop,coords,finite,cellmap,timer)
%I31_BDRY_EST Assemble boundary factors and full-matrix tail candidates.
% Purpose:
%   Convert refined full-boundary maps into wall, circle, value-lift, field,
%   and state Grams, then contract every required full-P tail.
% Input:
%   c,node,prop,coords,finite,cellmap,timer - Frozen fbie-a1 objects and
%     the entry timer used only to enforce the stage-start soft limit.
% Output:
%   out - Boundary estimator maps, two tail records, total q, and scale test.
% Main algorithm:
%   Build only positive-factor Grams, retain full nonnormal propagation
%   matrices, and use scale-covariant doubling without diagonalization.
% Based on:
%   research/projects/eig-apost/implementation/i3/design-3-1f.md.
% Numerical goal:
%   Isolate the boundary-residual/full-P scientific module from the entry.

  est=LOCAL_boundary_estimator(c,node,prop,coords,finite,cellmap);
  empty=struct('record',struct('available',false),'chosen',struct(), ...
    'active_mib',0);
  tm=empty; tp=empty; total=struct(); repeat=struct();
  if est.record.q_objects_available
    if toc(timer)>c.soft_seconds
      error('i31f:SoftTime', ...
        'The soft limit forbids starting full-P infinite tails.');
    end
    tm=LOCAL_tail(prop.Pminus,est.minus,coords.cminus,c,'minus');
    tp=LOCAL_tail(prop.Pplus,est.plus,coords.cplus,c,'plus');
    if tm.record.available&&tp.record.available
      total=LOCAL_total(c,est,tm,tp,1);
      repeat=LOCAL_scale_repeat(c,coords,est,prop,total);
    end
  end
  out=struct('estimator',est,'minus_tail',tm,'plus_tail',tp, ...
    'total',total,'phase_scale',repeat, ...
    'peak_active_mib',max(tm.active_mib,tp.active_mib));
end


function out=LOCAL_boundary_estimator(c,node,prop,coords,finite,cellmap)
  Gp=[prop.Dplus;prop.Dplus*prop.Pplus];
  Gm=[prop.Dminus*prop.Pminus;prop.Dminus];
  delta=cellmap.circle_delta_unit; jump=cellmap.circle_jump_unit;
  delta_p=delta*Gp; delta_m=delta*Gm;
  jump_p=jump*Gp; jump_m=jump*Gm;

  wall_orders=cellmap.official.orders;
  QL=cellmap.official.flux_left; QR=cellmap.official.flux_right;
  QLp=QL*Gp; QRp=QR*Gp; QLm=QL*Gm; QRm=QR*Gm;
  Jp=QRp+QLp*prop.Pplus; Jm=QLm+QRm*prop.Pminus;
  center=LOCAL_center_jumps(c,node,prop,coords,cellmap);
  beta_all=c.beta+2*pi*wall_orders/c.d;
  kappa=sqrt(beta_all.^2+c.gamma);
  bwall=2*kappa.*tanh(kappa/2);
  wall_available=all(isfinite(bwall))&&all(bwall>0);
  retained=abs(wall_orders)<=c.M; bret=bwall(retained);
  center.wall_residual_squared=sum(abs(center.left_coefficients).^2./bwall)+ ...
    sum(abs(center.right_coefficients).^2./bwall);
  center.field_lower_uses_shared_trace=true;
  center.field_squared=sum(bret.*abs(prop.Dplus*coords.cplus).^2)+ ...
    sum(bret.*abs(prop.Dminus*coords.cminus).^2);
  Fwp=bsxfun(@times,Jp,1./sqrt(bwall));
  Fwm=bsxfun(@times,Jm,1./sqrt(bwall));
  Ffp=bsxfun(@times,prop.Dplus*prop.Pplus,sqrt(bret));
  Ffm=bsxfun(@times,prop.Dminus*prop.Pminus,sqrt(bret));

  [ell,Cfft]=LOCAL_circle_transform(c);
  Dc_p=Cfft*delta_p; Dc_m=Cfft*delta_m;
  Jc_p=Cfft*jump_p; Jc_m=Cfft*jump_m;
  circle=LOCAL_circle_weights(c,ell);
  collar0=LOCAL_collar_weights(c,ell,c.radial_gauss_coarse);
  collar1=LOCAL_collar_weights(c,ell,c.radial_gauss);
  wall0=LOCAL_wall_lift_weights(c,beta_all,c.radial_gauss_coarse);
  wall1=LOCAL_wall_lift_weights(c,beta_all,c.radial_gauss);
  collar_change=max(abs(collar1-collar0)./max([realmin*ones(size(collar1)), ...
    abs(collar1),abs(collar0)],[],2));
  wall_lift_change=max(abs(wall1-wall0)./max([realmin*ones(size(wall1)), ...
    abs(wall1),abs(wall0)],[],2));
  available=wall_available&&circle.available&&all(isfinite(collar1))&& ...
    all(collar1>=0)&&all(isfinite(wall1))&&all(wall1>=0);
  if available
    Fcp=bsxfun(@times,Jc_p,1./sqrt(circle.weight));
    Fcm=bsxfun(@times,Jc_m,1./sqrt(circle.weight));
    Cvp=bsxfun(@times,Dc_p,sqrt(collar1/c.gamma));
    Cvm=bsxfun(@times,Dc_m,sqrt(collar1/c.gamma));
    LLp=bsxfun(@times,cellmap.official.defect_left*Gp,sqrt(wall1/c.gamma));
    LRp=bsxfun(@times,cellmap.official.defect_right*Gp,sqrt(wall1/c.gamma));
    LLm=bsxfun(@times,cellmap.official.defect_left*Gm,sqrt(wall1/c.gamma));
    LRm=bsxfun(@times,cellmap.official.defect_right*Gm,sqrt(wall1/c.gamma));
    Fvp=[Cvp;LRp;LLp*prop.Pplus];
    Fvm=[Cvm;LLm;LRm*prop.Pminus];
    center.lead_plus_volume_squared=norm(LLp*coords.cplus)^2;
    center.lead_minus_volume_squared=norm(LRm*coords.cminus)^2;
    center.left_value_lift_source=sqrt(wall1/c.gamma).* ...
      center.left_value_mismatch;
    center.right_value_lift_source=sqrt(wall1/c.gamma).* ...
      center.right_value_mismatch;
    center.center_left_volume_squared=norm(center.left_value_lift_source)^2;
    center.center_right_volume_squared=norm(center.right_value_lift_source)^2;
    center.lead_side_volume_squared=center.lead_plus_volume_squared+ ...
      center.lead_minus_volume_squared;
    center.center_side_volume_squared=center.center_left_volume_squared+ ...
      center.center_right_volume_squared;
    center.volume_squared=center.lead_side_volume_squared+ ...
      center.center_side_volume_squared;
  else
    Fcp=[]; Fcm=[]; Fvp=[]; Fvm=[];
    LLp=[]; LRp=[]; LLm=[]; LRm=[];
    center.lead_plus_volume_squared=NaN;
    center.lead_minus_volume_squared=NaN;
    center.left_value_lift_source=[];
    center.right_value_lift_source=[];
    center.center_left_volume_squared=NaN;
    center.center_right_volume_squared=NaN;
    center.lead_side_volume_squared=NaN;
    center.center_side_volume_squared=NaN;
    center.volume_squared=NaN;
  end

  plus=LOCAL_factor_grams(Fwp,Fcp,Fvp,Ffp,c);
  minus=LOCAL_factor_grams(Fwm,Fcm,Fvm,Ffm,c);
  available=available&&plus.available&&minus.available;
  outside=abs(ell)>c.M;
  weighted_jump=bsxfun(@times,[Jc_p,Jc_m],1./sqrt(circle.weight));
  [circle_energy,outside_record]=LOCAL_outside_energy(weighted_jump,outside);
  wall_defect=[cellmap.official.defect_left;cellmap.official.defect_right];
  wall_repair=norm((cellmap.official.g-wall_defect)+wall_defect- ...
    cellmap.official.g,'fro')/max(realmin,norm(cellmap.official.g,'fro'));
  circle_repair=norm(delta_p-delta_p/2-delta_p/2,'fro')/ ...
    max(realmin,norm(delta_p,'fro'));
  center_repair=max([norm(center.actual_left_trace+ ...
    center.left_value_mismatch-center.shared_left_trace), ...
    norm(center.actual_right_trace+center.right_value_mismatch- ...
    center.shared_right_trace)])/max([realmin,norm(center.shared_left_trace), ...
    norm(center.shared_right_trace)]);
  safe_value=abs(1-3+2); safe_derivative=abs(-6+6);
  warnings=struct('code',{},'value',{},'blocking',{});
  if circle.relative_change>c.circle_weight_change_warning
    warnings(end+1)=LOCAL_warning('CIRCLE_WEIGHT_REFINEMENT_WARNING', ...
      circle.relative_change);
  end
  if ~isfinite(circle.record.low_order_bessel_relative_defect) || ...
      circle.record.low_order_bessel_relative_defect>c.refinement_warning
    warnings(end+1)=LOCAL_warning('CIRCLE_BESSEL_ORACLE_WARNING', ...
      circle.record.low_order_bessel_relative_defect);
  end
  energy_defect=max(circle.record.discrete_energy_identity_defect);
  if ~isfinite(energy_defect) || energy_defect>c.refinement_warning
    warnings(end+1)=LOCAL_warning('CIRCLE_ENERGY_IDENTITY_WARNING',energy_defect);
  end
  if collar_change>c.refinement_warning
    warnings(end+1)=LOCAL_warning('COLLAR_QUADRATURE_WARNING',collar_change);
  end
  if wall_lift_change>c.refinement_warning
    warnings(end+1)=LOCAL_warning('WALL_LIFT_QUADRATURE_WARNING',wall_lift_change);
  end
  conformity=max([wall_repair,center_repair,circle_repair, ...
    safe_value,safe_derivative]);
  if ~isfinite(conformity) || conformity>c.scale_relative_warning
    warnings(end+1)=LOCAL_warning('VALUE_LIFT_CONFORMITY_WARNING',conformity);
  end
  first='';
  if ~wall_available, first='A wall trace weight is nonfinite or nonpositive.';
  elseif ~circle.available, first='Circle trace weights are nonfinite or nonpositive.';
  elseif any(~isfinite(collar1))||any(collar1<0), first='A collar weight is invalid.';
  elseif any(~isfinite(wall1))||any(wall1<0), first='A wall value-lift weight is invalid.';
  elseif ~plus.available||~minus.available, first='A positive-factor Gram is invalid.'; end
  record=struct('q_objects_available',available, ...
    'first_unavailable_message',first,'circle_weights',circle.record, ...
    'collar_16_to_32_relative_change',collar_change, ...
    'wall_lift_16_to_32_relative_change',wall_lift_change, ...
    'circle_outside_retained_band_share',circle_energy, ...
    'circle_outside_retained_band_metric',outside_record, ...
    'plus_grams',plus.record,'minus_grams',minus.record,'warnings',warnings, ...
    'wall_orders',wall_orders,'circle_orders',ell, ...
    'normal_orientation','global +r on the circle; cell outward on walls', ...
    'numerical_512_value_jump_frobenius_norms', ...
    [norm(delta_p,'fro'),norm(delta_m,'fro')], ...
    'numerical_512_normal_jump_frobenius_norms', ...
    [norm(jump_p,'fro'),norm(jump_m,'fro')], ...
    'mathematical_circle_value_collar_definition_used',true, ...
    'numerical_circle_continuity_enclosed',false, ...
    'shared_wall_repaired_value_defect',wall_repair, ...
    'center_shared_repaired_value_defect',center_repair, ...
    'repaired_circle_value_jump_defect',circle_repair, ...
    'safe_rim_value_defect',safe_value, ...
    'safe_rim_derivative_defect',safe_derivative, ...
    'wall_total_trace_shared_by_explicit_value_lift',true, ...
    'field_lower_uses_shared_wall_trace',true, ...
    'wall_quasiperiodic_basis_used',true, ...
    'triangle_sum_required',true,'reliability_certified',false);
  audit=struct('Pplus',prop.Pplus,'Pminus',prop.Pminus, ...
    'Ap',prop.Ap,'Bp',prop.Bp,'Am',prop.Am,'Bm',prop.Bm, ...
    'Dplus',prop.Dplus,'Dminus',prop.Dminus, ...
    'Gplus',Gp,'Gminus',Gm,'QLplus',QLp,'QRplus',QRp, ...
    'QLminus',QLm,'QRminus',QRm,'Jplus',Jp,'Jminus',Jm, ...
    'delta_plus',Dc_p,'delta_minus',Dc_m, ...
    'circle_jump_plus',Jc_p,'circle_jump_minus',Jc_m, ...
    'center_plus_wall_lift_factor',LLp, ...
    'center_minus_wall_lift_factor',LRm, ...
    'center_actual_left_trace',center.actual_left_trace, ...
    'center_actual_right_trace',center.actual_right_trace, ...
    'center_shared_left_trace',center.shared_left_trace, ...
    'center_shared_right_trace',center.shared_right_trace, ...
    'center_left_value_mismatch',center.left_value_mismatch, ...
    'center_right_value_mismatch',center.right_value_mismatch, ...
    'center_left_value_lift_source',center.left_value_lift_source, ...
    'center_right_value_lift_source',center.right_value_lift_source, ...
    'lead_volume_factor_plus',Fvp,'lead_volume_factor_minus',Fvm, ...
    'lead_wall_factor_plus',Fwp,'lead_wall_factor_minus',Fwm, ...
    'lead_circle_factor_plus',Fcp,'lead_circle_factor_minus',Fcm, ...
    'lead_field_factor_plus',Ffp,'lead_field_factor_minus',Ffm, ...
    'center_wall_jumps',center,'weighted_q',finite.q, ...
    'physical_unit_density',cellmap.official.eta, ...
    'circle_delta_D_unit_wall_512',delta, ...
    'circle_j_Gamma_unit_wall_512',jump, ...
    'circle_theta_512',cellmap.circle_theta, ...
    'wall_flux_left_unit_512',QL,'wall_flux_right_unit_512',QR, ...
    'wall_orders_512',wall_orders,'full_boundary_maps',cellmap.audit, ...
    'density_coordinate','[tau;zeta], zeta=-sigma');
  out=struct('plus',plus.grams,'minus',minus.grams,'center',center, ...
    'record',record,'audit',audit);
end

function [ell,T]=LOCAL_circle_transform(c)
  N=c.circle_action_nodes; theta=(0:N-1)*2*pi/N; ell=(-N/2:N/2-1).';
  T=sqrt(2*pi*c.R)/N*exp(-1i*ell*theta);
end

function out=LOCAL_center_jumps(c,node,prop,coords,cellmap)
  q=coords.q; qL=q(1:c.K); qR=q(c.K+1:end); E=diag(node.phase(:));
  I=eye(c.K);
  dxL=1i*diag(node.gamma)*(qL-E*qR);
  dxR=1i*diag(node.gamma)*(E*qL-qR);
  N=c.wall_order_official; embed=zeros(N,c.K); retained=(-c.M:c.M).';
  allorders=(-N/2:N/2-1).';
  for j=1:c.K, embed(allorders==retained(j),j)=1; end
  dxLall=embed*dxL; dxRall=embed*dxR;
  Gp=[prop.Dplus;prop.Dplus*prop.Pplus];
  Gm=[prop.Dminus*prop.Pminus;prop.Dminus];
  QL=cellmap.official.flux_left; QR=cellmap.official.flux_right;
  right=dxRall+QL*Gp*coords.cplus;
  left=QR*Gm*coords.cminus-dxLall;
  actual_left=embed*[I,E]*q; actual_right=embed*[E,I]*q;
  shared_left=embed*prop.Dminus*coords.cminus;
  shared_right=embed*prop.Dplus*coords.cplus;
  out=struct('left_coefficients',left,'right_coefficients',right, ...
    'center_left_global_dx',dxLall,'center_right_global_dx',dxRall, ...
    'actual_left_trace',actual_left,'actual_right_trace',actual_right, ...
    'shared_left_trace',shared_left,'shared_right_trace',shared_right, ...
    'left_value_mismatch',shared_left-actual_left, ...
    'right_value_mismatch',shared_right-actual_right);
end
%% ==================== Circle and collar weights ====================
% Riccati and radial quadrature avoid a two-dimensional volume mesh.

function out=LOCAL_circle_weights(c,ell)
  p0=LOCAL_riccati(c,ell,c.riccati_steps_coarse);
  p1=LOCAL_riccati(c,ell,c.riccati_steps);
  weight=(p1.pin-p1.pout)/c.R;
  change=max(abs(weight-(p0.pin-p0.pout)/c.R)./ ...
    max([realmin*ones(size(weight)),abs(weight), ...
    abs((p0.pin-p0.pout)/c.R)],[],2));
  positive=isfinite(weight)&weight>0;
  low=abs(ell)<=8; bessel=NaN(size(ell));
  try
    bessel(low)=LOCAL_bessel_weights(c,ell(low));
    bessel_defect=max(abs(weight(low)-bessel(low))./ ...
      max([realmin*ones(sum(low),1),abs(weight(low)), ...
      abs(bessel(low))],[],2));
  catch
    bessel_defect=NaN;
  end
  out=struct('available',all(positive),'weight',weight, ...
    'relative_change',change,'record',struct('orders',ell, ...
    'official_steps',c.riccati_steps,'coarse_steps',c.riccati_steps_coarse, ...
    'p_in',p1.pin,'p_out',p1.pout,'weights',weight, ...
    'discrete_energy_identity_defect',p1.energy_identity_defect, ...
    'low_order_bessel_weights',bessel, ...
    'low_order_bessel_relative_defect',bessel_defect, ...
    'positive_mask',positive,'relative_change',change, ...
    'basis','exp(i*l*theta)/sqrt(2*pi*R)', ...
    'weight_formula','(p_in-p_out)/R','outward_certified',false));
end

function weight=LOCAL_bessel_weights(c,ell)
  kin=sqrt(c.gamma*c.rho_disk); kout=sqrt(c.gamma);
  pin=LOCAL_annulus_logder(ell,kin,c.R-c.delta_c,c.R);
  pout=LOCAL_annulus_logder(ell,kout,c.R+c.delta_c,c.R);
  weight=(pin-pout)/c.R;
end

function p=LOCAL_annulus_logder(ell,kappa,rnatural,reval)
  p=zeros(size(ell));
  for j=1:numel(ell)
    l=abs(ell(j)); za=kappa*rnatural; zr=kappa*reval;
    [Ia,Ipa,Ka,Kpa]=LOCAL_bessel_values(l,za);
    [Ir,Ipr,Kr,Kpr]=LOCAL_bessel_values(l,zr);
    v=Kpa*Ir-Ipa*Kr; vr=kappa*(Kpa*Ipr-Ipa*Kpr);
    p(j)=reval*vr/v;
  end
end

function [I,Ip,K,Kp]=LOCAL_bessel_values(l,z)
  I=besseli(l,z,1)*exp(z); K=besselk(l,z,1)*exp(-z);
  if l==0
    Im=besseli(1,z,1)*exp(z); Km=besselk(1,z,1)*exp(-z);
  else
    Im=besseli(l-1,z,1)*exp(z); Km=besselk(l-1,z,1)*exp(-z);
  end
  Iq=besseli(l+1,z,1)*exp(z); Kq=besselk(l+1,z,1)*exp(-z);
  Ip=(Im+Iq)/2; Kp=-(Km+Kq)/2;
end

function out=LOCAL_riccati(c,ell,steps)
  tin=log(c.R-c.delta_c); t0=log(c.R); tout=log(c.R+c.delta_c);
  pin=zeros(size(ell)); pout=pin;
  [pin,din]=LOCAL_rk4(pin,tin,t0,steps,ell,c.gamma*c.rho_disk);
  [pout,dout]=LOCAL_rk4(pout,tout,t0,steps,ell,c.gamma);
  out=struct('pin',pin,'pout',pout, ...
    'energy_identity_defect',max([din;dout],[],1).');
end

function [p,defect]=LOCAL_rk4(p,t0,t1,steps,ell,alpha)
  h=(t1-t0)/steps; t=t0; v=ones(size(p)); energy=zeros(size(p));
  for j=1:steps
    s=[p,v,energy]; k1=LOCAL_riccati_rhs(s,t,ell,alpha);
    k2=LOCAL_riccati_rhs(s+h*k1/2,t+h/2,ell,alpha);
    k3=LOCAL_riccati_rhs(s+h*k2/2,t+h/2,ell,alpha);
    k4=LOCAL_riccati_rhs(s+h*k3,t+h,ell,alpha);
    s=s+h*(k1+2*k2+2*k3+k4)/6; p=s(:,1); v=s(:,2); energy=s(:,3); t=t+h;
    if any(~isfinite(s),'all'), defect=Inf(size(p)); return; end
  end
  endpoint=p.*v.^2;
  defect=abs(energy-endpoint)./max([realmin*ones(size(p)), ...
    abs(energy),abs(endpoint)],[],2);
end

function value=LOCAL_riccati_rhs(s,t,ell,alpha)
  p=s(:,1); v=s(:,2); q=ell.^2+alpha*exp(2*t);
  value=[q-p.^2,p.*v,(p.^2+q).*v.^2];
end

function weight=LOCAL_collar_weights(c,ell,nq)
  [x,w]=LOCAL_gauss(nq); weight=zeros(size(ell));
  for side=[-1,1]
    if side<0, rho=c.rho_disk; r0=c.R-c.delta_c; r1=c.R;
    else, rho=1; r0=c.R; r1=c.R+c.delta_c; end
    r=(r0+r1)/2+(r1-r0)/2*x; wr=(r1-r0)/2*w;
    if side<0, t=(c.R-r)/c.delta_c; drsign=-1;
    else, t=(r-c.R)/c.delta_c; drsign=1; end
    chi=1-3*t.^2+2*t.^3; chip=-6*t+6*t.^2; chipp=-6+12*t;
    amp=-side/2;
    for j=1:numel(ell)
      radial=amp*(-chipp/c.delta_c^2- ...
        drsign*chip./(r*c.delta_c)+(ell(j)^2./r.^2-c.mu_h*rho).*chi);
      % e_l is normalized in ds at r=R, so the area Jacobian is r/R.
      weight(j)=weight(j)+sum(wr.*(r/c.R).*(abs(radial).^2/rho));
    end
  end
end

function weight=LOCAL_wall_lift_weights(c,beta,nq)
  [x,w]=LOCAL_gauss(nq);
  t=(x+1)/2; wx=c.delta_w*w/2;
  chi=1-3*t.^2+2*t.^3; chipp=-6+12*t;
  weight=zeros(size(beta));
  for j=1:numel(beta)
    source=-chipp/c.delta_w^2+(beta(j)^2-c.mu_h)*chi;
    weight(j)=sum(wx.*abs(source).^2);
  end
end

function [x,w]=LOCAL_gauss(n)
  j=(1:n-1).'; beta=j./sqrt(4*j.^2-1);
  [V,D]=eig(diag(beta,1)+diag(beta,-1));
  [x,order]=sort(diag(D)); V=V(:,order); w=2*(V(1,:).^2).';
end

function out=LOCAL_factor_grams(Fw,Fc,Fv,Ff,c)
  factors={Fw,Fc,Fv,Ff,eye(c.K)};
  names={'wall','circle','volume','field','state'};
  grams=struct(); empty=struct('name','','available',false, ...
    'factor_size',[0,0],'hermitian_defect',NaN, ...
    'minimum_eigenvalue',NaN,'scale',NaN,'pass',false);
  records=repmat(empty,1,numel(names)); available=true;
  for j=1:numel(names)
    F=factors{j};
    if isempty(F) || any(~isfinite(F),'all')
      W=NaN(c.K); rec=struct('name',names{j},'available',false, ...
        'factor_size',size(F),'hermitian_defect',NaN,'minimum_eigenvalue',NaN, ...
        'scale',NaN,'pass',false);
    else
      W=F'*F; scale=norm(W,2); tolscale=max(realmin,scale);
      herm=norm(W-W','fro')/tolscale; mineig=min(real(eig((W+W')/2)));
      pass=all(isfinite(W),'all')&&herm<=c.gram_scale&& ...
        mineig>=-c.gram_scale*tolscale;
      rec=struct('name',names{j},'available',true,'factor_size',size(F), ...
        'hermitian_defect',herm,'minimum_eigenvalue',mineig, ...
        'scale',scale,'pass',pass);
    end
    grams.(names{j})=W; records(j)=rec; available=available&&rec.pass;
  end
  out=struct('grams',grams,'record',records,'available',available);
end

function [value,record]=LOCAL_outside_energy(A,mask)
  numerator=norm(A(mask,:),'fro')^2; total=norm(A,'fro')^2;
  zero=total==0; value=numerator/max(realmin,total);
  record=struct('numerator',numerator,'denominator',total, ...
    'zero_component',zero,'ratio',value, ...
    'computed_modes_all_in_residual',true);
end
%% ==================== Full-matrix tails ====================
% Doubling retains all nonnormal coupling and records two associations.

function out=LOCAL_tail(P,grams,c0,c,side)
  names={'wall','circle','volume','field','state'};
  Wleft=cell(size(names)); Wright=Wleft;
  for k=1:numel(names), Wleft{k}=grams.(names{k}); Wright{k}=Wleft{k}; end
  first_states=zeros(c.K,4); first_quadratics=zeros(4,numel(names));
  state=c0;
  for j=1:4
    first_states(:,j)=state;
    for k=1:numel(names)
      first_quadratics(j,k)=real(state'*grams.(names{k})*state);
    end
    state=P*state;
  end
  pleft=P; powers=cell(c.tail_max_power+1,1);
  rows=repmat(LOCAL_empty_tail_row(numel(names)),c.tail_max_power+1,1);
  selected=NaN; active_mib=0; available_indices=[];
  for j=0:c.tail_max_power
    N=2^j; powers{j+1}=pleft; pright=LOCAL_alternate_power(P,powers,j);
    eN=norm(pleft-pright,2); pscale=max([1,norm(pleft,2),norm(pright,2)]);
    ahi=norm(pleft,2)+eN+100*c.K*eps*pscale;
    sums=zeros(1,numel(names)); raw_sums=sums; sum_tolerances=sums;
    roundoff_negative=false(size(sums)); omega=sums; allowance=Inf(size(sums));
    shares=allowance;
    for k=1:numel(names)
      wscale=max(norm(Wleft{k},2),norm(Wright{k},2));
      omega(k)=norm(Wleft{k}-Wright{k},2);
      if wscale>0, omega(k)=omega(k)+100*c.K*eps*wscale; end
      raw_sums(k)=real(c0'*Wleft{k}*c0);
      sum_tolerances(k)=100*c.K*eps*norm(Wleft{k},2)*norm(c0)^2;
      sums(k)=raw_sums(k);
      if sums(k)<0 && sums(k)>=-sum_tolerances(k)
        sums(k)=0; roundoff_negative(k)=true;
      end
      if isfinite(ahi)&&ahi<1
        allowance(k)=ahi^2/(1-ahi^2)*(norm(Wleft{k},2)+omega(k))*norm(c0)^2;
        shares(k)=allowance(k)/max(realmin,sums(k));
      end
    end
    available=all(isfinite([ahi,sums,omega,allowance]))&&ahi<1&& ...
      all(sums>=0);
    qualified=available&&all(shares<=c.tail_share_max);
    rows(j+1)=struct('N',N,'power_left_norm',norm(pleft,2), ...
      'power_association_defect',eN,'a_hi',ahi,'finite_sums',sums, ...
      'raw_finite_sums',raw_sums,'sum_roundoff_tolerances',sum_tolerances, ...
      'roundoff_negative_mask',roundoff_negative, ...
      'gram_allowances',omega,'tail_allowances',allowance, ...
      'tail_shares',shares,'available',available,'qualification_pass',qualified);
    info=whos; active_mib=max(active_mib,sum([info.bytes])/2^20);
    if available, available_indices(end+1)=j+1; end %#ok<AGROW>
    if qualified&&isnan(selected), selected=j+1; end
    if j==c.tail_max_power, break; end
    old=pleft; oldr=pright; pleft=old*old;
    for k=1:numel(names)
      L=Wleft{k}; R=Wright{k};
      Wleft{k}=L+(old'*L)*old;
      Wright{k}=R+oldr'*(R*oldr);
    end
  end
  qualified=~isnan(selected);
  if isnan(selected)&&~isempty(available_indices)
    scores=zeros(size(available_indices));
    for k=1:numel(available_indices)
      scores(k)=max(rows(available_indices(k)).tail_shares);
    end
    [~,best]=min(scores); selected=available_indices(best);
  end
  available=~isnan(selected);
  if available, chosen=rows(selected); else, chosen=rows(end); end
  out=struct('chosen',chosen,'active_mib',active_mib,'record',struct( ...
    'available',available,'qualification_pass',qualified,'side',side, ...
    'gram_names',{names},'levels',rows, ...
    'selected_index',selected,'selected_N',chosen.N, ...
    'first_four_states',first_states, ...
    'first_four_quadratic_actions',first_quadratics, ...
    'physical_start_indices',[0,0,0,1,0], ...
    'tail_diagnostic_certified',false));
end

function alternate=LOCAL_alternate_power(P,powers,j)
  if j<3
    count=2^j; alternate=P; for k=2:count, alternate=alternate*P; end
  else
    base=powers{j-2}; alternate=base;
    for k=2:8, alternate=alternate*base; end
  end
end

function row=LOCAL_empty_tail_row(n)
  row=struct('N',NaN,'power_left_norm',NaN,'power_association_defect',NaN, ...
    'a_hi',NaN,'finite_sums',NaN(1,n),'raw_finite_sums',NaN(1,n), ...
    'sum_roundoff_tolerances',NaN(1,n), ...
    'roundoff_negative_mask',false(1,n), ...
    'gram_allowances',NaN(1,n), ...
    'tail_allowances',NaN(1,n),'tail_shares',NaN(1,n), ...
    'available',false,'qualification_pass',false);
end
%% ==================== Indicator and scale repeat ====================
% The numerator is a triangle sum; the denominator never receives a tail allowance.

function out=LOCAL_total(c,est,tm,tp,amplitude)
  a2=abs(amplitude)^2; imap=struct('wall',1,'circle',2,'volume',3, ...
    'field',4,'state',5);
  upper=tm.chosen.finite_sums+tm.chosen.tail_allowances+ ...
    tp.chosen.finite_sums+tp.chosen.tail_allowances;
  finite_lower=tm.chosen.finite_sums+tp.chosen.finite_sums;
  wall2=a2*est.center.wall_residual_squared+upper(imap.wall);
  circle2=upper(imap.circle);
  volume2=a2*est.center.volume_squared+upper(imap.volume);
  field2=a2*est.center.field_squared+finite_lower(imap.field);
  M=sqrt(wall2)+sqrt(circle2)+sqrt(volume2);
  q=M/sqrt(field2); available=all(isfinite([wall2,circle2,volume2,field2,M,q]))&& ...
    all([wall2,circle2,volume2]>=0)&&field2>0;
  lambda=[NaN,NaN]; kval=lambda; width=NaN; message='';
  if ~available
    message='A residual component or the field lower candidate is invalid.';
  elseif q<1
    lambda=[max(0,(c.mu_h-q*c.gamma)/(1+q)), ...
      (c.mu_h+q*c.gamma)/(1-q)];
    kval=sqrt(lambda); width=diff(kval);
  end
  out=struct('available',available,'wall_squared',wall2, ...
    'circle_squared',circle2,'collar_volume_squared',volume2, ...
    'wall_component',sqrt(wall2),'circle_component',sqrt(circle2), ...
    'collar_volume_component',sqrt(volume2),'triangle_majorant',M, ...
    'field_lower_squared',field2,'field_lower',sqrt(field2),'q',q, ...
    'interval_defined',available&&q<1,'nominal_lambda_interval',lambda, ...
    'nominal_k_interval',kval,'nominal_k_width',width, ...
    'preregistered_k_resolution',c.tau_k_pre, ...
    'resolution_pass',available&&q<1&&width<=c.tau_k_pre, ...
    'message',message,'qualification','UNQUALIFIED', ...
    'outward_residual_upper',false,'outward_field_lower',false, ...
    'certified_tail',false,'outward_wall_tail',false, ...
    'outward_circle_tail',false,'certified_projected_gap',false, ...
    'independent_reference',false,'reliable_spectral_interval',false, ...
    'continuous_eigenvalue_exists',false);
end

function out=LOCAL_scale_repeat(c,coords,est,prop,base)
  z=c.scale_oracle; cm=z*coords.cminus; cp=z*coords.cplus;
  tm=LOCAL_tail(prop.Pminus,est.minus,cm,c,'minus-scaled');
  tp=LOCAL_tail(prop.Pplus,est.plus,cp,c,'plus-scaled');
  if tm.record.available&&tp.record.available
    scaled=LOCAL_total(c,est,tm,tp,z); a2=abs(z)^2;
    values0=[base.wall_squared,base.circle_squared,base.collar_volume_squared, ...
      base.field_lower_squared,base.q];
    values1=[scaled.wall_squared/a2,scaled.circle_squared/a2, ...
      scaled.collar_volume_squared/a2,scaled.field_lower_squared/a2,scaled.q];
    defects=abs(values1-values0)./max([realmin*ones(size(values0)); ...
      abs(values0);abs(values1)],[],1);
  else
    defects=Inf(1,5);
  end
  out=struct('multiplier',z,'tail_pass',tm.record.available&&tp.record.available, ...
    'relative_defects',defects,'maximum_relative_defect',max(defects), ...
    'pass',all(isfinite(defects))&&max(defects)<=c.scale_relative_warning, ...
    'certified',false);
end
%% ==================== Warnings and result semantics ====================
% Numerical warnings do not suppress a finite q or its unqualified transform.

function out=LOCAL_warning(code,value)
  out=struct('code',code,'value',value,'blocking',false);
end
