function out = i32_lifting_quadrature(c,staged,timer,retained_before_mib)
%I32_LIFTING_QUADRATURE Evaluate frozen trace and lifting weights.
% Purpose:
%   Form the preregistered Riccati, collar Gauss, wall-lift Gauss, and wall
%   trace weight ladders for the unchanged same trial.
% Input:
%   c, staged, timer     - Frozen contract, pruned staged input, and timer.
%   retained_before_mib - Caller active-object proxy before this call.
% Output:
%   out                  - Typed total result with private weight vectors
%                          and compact refinement/oracle diagnostics.
% Main algorithm:
%   Integrate the frozen Riccati equations and value-only lift energies on
%   the fixed 512/1024/2048 and 32/64/128 ladders.
% Based on:
%   i32_same_eval.m Revision E LOCAL_weights and its helper functions.
% Main changes:
%   Separates weight ownership and explicitly audits six Golub-Welsch eig
%   calls; no weight vector is copied into public metrics.
% Numerical goal:
%   Supply the unchanged one-dimensional boundary-lifting factors.

  warnings=LOCAL_empty_warnings(); calls=LOCAL_zero_counters(); peak=0;
  first=LOCAL_condition('NONE','All lifting and quadrature weights are available.');
  private=struct(); public=struct(); available=false;
  input_alias=LOCAL_value_mib(staged); peak=max(peak,LOCAL_workspace_mib());
  try
    z=staged.certificate; ell=(-1024:1023).';
    circle=cell(1,3); collar=cell(1,3); wall=cell(1,3);
    gauss_category=struct('n32',0,'n64',0,'n128',0);
    for j=1:3
      LOCAL_hard_time(timer,c,'Riccati ladder');
      ric=LOCAL_riccati(z,ell,c.riccati_levels(j));
      weight=(ric.pin-ric.pout)/z.R;
      circle{j}=weight;
      circle_public(j)=struct('steps',c.riccati_levels(j), ... %#ok<AGROW>
        'order_min',ell(1),'order_max',ell(end),'count',numel(ell), ...
        'positive',all(isfinite(weight)&weight>0), ...
        'minimum',min(weight),'maximum',max(weight), ...
        'norm',norm(weight),'energy_identity_defect', ...
          max(ric.energy_identity_defect), ...
        'low_order_bessel_metric',LOCAL_low_bessel(z,ell,weight));
      calls.riccati_calls=calls.riccati_calls+2;
      peak=max(peak,LOCAL_workspace_mib());
      clear ric weight;
    end
    beta=z.beta+2*pi*(-2048:2047).'/z.d;
    for j=1:3
      LOCAL_hard_time(timer,c,'Gauss lifting ladder');
      nq=c.gauss_levels(j);
      [collar{j},collar_eig]=LOCAL_collar_weights(z,ell,nq);
      [wall{j},wall_eig]=LOCAL_wall_lift_weights(z,beta,nq);
      calls.gauss_factor_calls=calls.gauss_factor_calls+2;
      calls.gauss_golub_welsch_eig_calls= ...
        calls.gauss_golub_welsch_eig_calls+collar_eig+wall_eig;
      field=sprintf('n%d',nq);
      gauss_category.(field)=gauss_category.(field)+collar_eig+wall_eig;
      collar_public(j)=LOCAL_weight_summary(collar{j},nq,ell); %#ok<AGROW>
      wall_public(j)=LOCAL_weight_summary( ... %#ok<AGROW>
        wall{j},nq,(-2048:2047).');
      peak=max(peak,LOCAL_workspace_mib());
    end
    kappa=sqrt(beta.^2+z.gamma);
    wall_trace=2*kappa.*tanh(kappa/2);
    eig_pass=calls.gauss_golub_welsch_eig_calls==6&& ...
      gauss_category.n32==2&&gauss_category.n64==2&&gauss_category.n128==2;
    weight_pass=all([circle_public.positive])&& ...
      all(cellfun(@(x) all(isfinite(x)&x>=0),collar))&& ...
      all(cellfun(@(x) all(isfinite(x)&x>=0),wall))&& ...
      all(isfinite(wall_trace)&wall_trace>0);
    available=weight_pass&&eig_pass;
    if ~eig_pass
      first=LOCAL_condition('GAUSS_EIG_CALL_IDENTITY_UNAVAILABLE', ...
        'The Golub-Welsch eig call lattice is not {32:2,64:2,128:2}.');
    elseif ~weight_pass
      first=LOCAL_condition('REQUIRED_TRACE_OR_LIFT_WEIGHT_UNAVAILABLE', ...
        'A required trace or lifting weight is invalid.');
    end
    refinement=LOCAL_refinement(c,circle,collar,wall);
    if max([circle_public.energy_identity_defect])>c.action_ratio_max
      warnings(end+1)=LOCAL_warning('RICCATI_ENERGY_WARNING', ...
        max([circle_public.energy_identity_defect])); %#ok<AGROW>
    end
    bessel=max(arrayfun(@(x) x.low_order_bessel_metric.ratio,circle_public));
    if bessel>c.kernel_oracle_tol
      warnings(end+1)=LOCAL_warning('RICCATI_BESSEL_QUOTIENT_WARNING',bessel); %#ok<AGROW>
    end
    private=struct('circle_weights',{circle},'collar_weights',{collar}, ...
      'wall_lift_weights',{wall},'wall_trace',wall_trace);
    public=struct('circle',circle_public,'collar',collar_public, ...
      'wall_lift',wall_public,'wall_trace',LOCAL_vector_summary(wall_trace), ...
      'refinement',refinement,'gauss_eig_category',gauss_category, ...
      'gauss_golub_welsch_eig_calls', ...
        calls.gauss_golub_welsch_eig_calls, ...
      'gauss_eig_identity_pass',eig_pass,'weights_available',weight_pass);
  catch ME
    available=false; first=LOCAL_condition(ME.identifier,ME.message);
    private=struct();
  end
  peak=max(peak,LOCAL_workspace_mib());
  clear staged timer z ell beta circle collar wall wall_trace;
  clear circle_public collar_public wall_public refinement gauss_category;
  audit=struct('returned_field_inventory',{{}}, ...
    'returned_numeric_shape_inventory',{{}},'prohibited_field_count',NaN, ...
    'prohibited_shape_count',NaN,'last_use_clear_ledger', ...
      LOCAL_liveness_ledger(), ...
    'post_clear_local_owner_inventory',{LOCAL_owner_inventory()}, ...
    'finest_factor_whitelist',{{ ...
      'finest_factors.circle_weights','finest_factors.collar_weights', ...
      'finest_factors.wall_lift_weights','finest_factors.wall_trace'}}, ...
    'compact_signature_whitelist',{{}},'signature_parity_coverage',struct(), ...
    'golub_welsch_expression', ...
      '[V,D]=eig(diag(beta,1)+diag(beta,-1))', ...
    'golub_welsch_parenthesization_frozen',true);
  payload=struct('available',available,'first_unavailable',first, ...
    'public_metrics',public,'finest_factors',private, ...
    'cap_signatures',struct(),'audit_summary',audit,'warnings',warnings, ...
    'call_counters',calls,'resource_record',struct());
  payload.resource_record=LOCAL_resource_record(retained_before_mib, ...
    input_alias,peak,LOCAL_value_mib(payload),c);
  out=payload;
end

%% ==================== Riccati trace weights ====================
% These helpers preserve the Revision E differential equations and RK4.

function metric=LOCAL_low_bessel(z,ell,weight)
  use=abs(ell)<=8; selected=ell(use); kin=sqrt(z.gamma*z.rho_disk);
  pin=LOCAL_annulus_logder(selected,kin,z.R-z.delta_c,z.R);
  pout=LOCAL_annulus_logder(selected,sqrt(z.gamma),z.R+z.delta_c,z.R);
  reference=(pin-pout)/z.R;
  metric=LOCAL_metric_record(weight(use),reference,1e-8);
end

function p=LOCAL_annulus_logder(ell,k,rnatural,reval)
  p=zeros(size(ell));
  for j=1:numel(ell)
    l=abs(ell(j)); za=k*rnatural; zr=k*reval;
    [Ia,Ipa,Ka,Kpa]=LOCAL_bessel_values(l,za);
    [Ir,Ipr,Kr,Kpr]=LOCAL_bessel_values(l,zr);
    v=Kpa*Ir-Ipa*Kr; vr=k*(Kpa*Ipr-Ipa*Kpr); p(j)=reval*vr/v;
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

function out=LOCAL_riccati(z,ell,steps)
  tin=log(z.R-z.delta_c); t0=log(z.R); tout=log(z.R+z.delta_c);
  [pin,din]=LOCAL_rk4(zeros(size(ell)),tin,t0,steps,ell,z.gamma*z.rho_disk);
  [pout,dout]=LOCAL_rk4(zeros(size(ell)),tout,t0,steps,ell,z.gamma);
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
    s=s+h*(k1+2*k2+2*k3+k4)/6;
    p=s(:,1); v=s(:,2); energy=s(:,3); t=t+h;
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

%% ==================== Frozen Gauss lifting weights ====================
% Each lift invokes the exact Golub-Welsch construction independently.

function [weight,eig_calls]=LOCAL_collar_weights(z,ell,nq)
  [x,w]=LOCAL_gauss(nq); eig_calls=1; weight=zeros(size(ell));
  for side=[-1,1]
    if side<0, rho=z.rho_disk; r0=z.R-z.delta_c; r1=z.R;
    else, rho=1; r0=z.R; r1=z.R+z.delta_c; end
    r=(r0+r1)/2+(r1-r0)/2*x; wr=(r1-r0)/2*w;
    if side<0, t=(z.R-r)/z.delta_c; drsign=-1;
    else, t=(r-z.R)/z.delta_c; drsign=1; end
    chi=1-3*t.^2+2*t.^3; chip=-6*t+6*t.^2; chipp=-6+12*t;
    amp=-side/2;
    for j=1:numel(ell)
      radial=amp*(-chipp/z.delta_c^2-drsign*chip./(r*z.delta_c)+ ...
        (ell(j)^2./r.^2-z.mu_h*rho).*chi);
      weight(j)=weight(j)+sum(wr.*(r/z.R).*abs(radial).^2/rho);
    end
  end
end

function [weight,eig_calls]=LOCAL_wall_lift_weights(z,beta,nq)
  [x,w]=LOCAL_gauss(nq); eig_calls=1; t=(x+1)/2; wx=z.delta_w*w/2;
  chi=1-3*t.^2+2*t.^3; chipp=-6+12*t; weight=zeros(size(beta));
  for j=1:numel(beta)
    source=-chipp/z.delta_w^2+(beta(j)^2-z.mu_h)*chi;
    weight(j)=sum(wx.*abs(source).^2);
  end
end

function [x,w]=LOCAL_gauss(n)
  j=(1:n-1).'; beta=j./sqrt(4*j.^2-1);
  [V,D]=eig(diag(beta,1)+diag(beta,-1));
  [x,order]=sort(diag(D)); V=V(:,order); w=2*(V(1,:).^2).';
end

%% ==================== Compact diagnostics and typed result ====================
% Public projections contain no dense weight ladders.

function out=LOCAL_refinement(c,circle,collar,wall)
  out=struct();
  for j=1:2
    out.riccati(j)=LOCAL_metric_record( ...
      circle{j},circle{j+1},c.action_ratio_max);
    out.collar_gauss(j)=LOCAL_metric_record( ...
      collar{j},collar{j+1},c.action_ratio_max);
    out.wall_lift_gauss(j)=LOCAL_metric_record( ...
      wall{j},wall{j+1},c.action_ratio_max);
  end
end

function out=LOCAL_weight_summary(weight,nq,orders)
  out=struct('gauss',nq,'order_min',orders(1),'order_max',orders(end), ...
    'count',numel(weight),'finite',all(isfinite(weight)), ...
    'nonnegative',all(weight>=0),'minimum',min(weight), ...
    'maximum',max(weight),'norm',norm(weight));
end

function out=LOCAL_vector_summary(value)
  out=struct('count',numel(value),'finite',all(isfinite(value)), ...
    'positive',all(value>0),'minimum',min(value),'maximum',max(value), ...
    'norm',norm(value));
end

function out=LOCAL_metric_record(a,b,threshold)
  numerator=norm(a-b,'fro'); left=norm(a,'fro'); right=norm(b,'fro');
  scale=max([realmin,left,right]);
  out=struct('numerator',numerator,'left_norm',left,'right_norm',right, ...
    'zero_component',left==0&&right==0,'scale',scale,'ratio',numerator/scale, ...
    'threshold',threshold,'pass',isfinite(numerator)&& ...
      numerator/scale<=threshold);
end

function out=LOCAL_liveness_ledger()
  out=struct( ...
    'field_path',{'finest_factors.circle_weights', ...
      'finest_factors.collar_weights','finest_factors.wall_lift_weights', ...
      'finest_factors.wall_trace'}, ...
    'consumer_set',{{'circle','fullp_cap'},{'circle','fullp_cap'}, ...
      {'wall','fullp_cap'},{'wall','fullp_cap'}}, ...
    'unique_last_consumer',{'fullp_cap','fullp_cap','fullp_cap','fullp_cap'}, ...
    'death',{'after fullp_cap','after fullp_cap', ...
      'after fullp_cap','after fullp_cap'});
end

function LOCAL_hard_time(timer,c,stage)
  if toc(timer)>c.hard_seconds
    error('i32f:HardTime','The hard limit was reached in %s.',stage);
  end
end

function out=LOCAL_resource_record(before,input_alias,peak,returned,c)
  exclusive=max(0,peak-input_alias);
  out=struct('retained_before_mib',before, ...
    'input_alias_nominal_mib',input_alias,'local_workspace_peak_mib',peak, ...
    'module_exclusive_peak_mib',exclusive, ...
    'frozen_streaming_transient_mib',c.worst_transient_mib, ...
    'concurrent_peak_candidate_mib', ...
      before+max(c.worst_transient_mib,exclusive), ...
    'return_payload_mib',returned,'retained_after_mib',NaN, ...
    'cumulative_peak_candidate_mib',NaN, ...
    'proxy_semantics',[ ...
      'deterministic active-object proxy; not RSS, allocator high-water, ', ...
      'reference-count, or copy-on-write proof']);
end

function out=LOCAL_zero_counters()
  out=struct('candidate_solve_calls',0,'qz_solve_calls',0, ...
    'coordinate_solve_calls',0,'propagation_solve_calls',0, ...
    'wall_density_solve_calls',0,'circle_density_solve_calls',0, ...
    'schur_solve_calls',0,'proxy_build_calls',0, ...
    'harmonic_action_calls',0,'image_pair_updates',0, ...
    'kress_oracle_calls',0,'linton_oracle_calls',0, ...
    'actual_deltaT_action_calls',0,'finite_bloch_image_updates',0, ...
    'riccati_calls',0,'gauss_factor_calls',0, ...
    'full_p_contraction_calls',0, ...
    'small_hermitian_gram_diagnostic_eig_calls',0, ...
    'gauss_golub_welsch_eig_calls',0, ...
    'n_op_signature_parity',0,'n_op_combined_gram_parity',0);
end

function out=LOCAL_empty_warnings()
  out=struct('code',{},'value',{},'blocking',{});
end

function out=LOCAL_warning(code,value)
  out=struct('code',char(code),'value',double(value),'blocking',false);
end

function out=LOCAL_condition(code,message)
  out=struct('code',char(code),'message',char(message));
end

function value=LOCAL_workspace_mib()
  info=evalin('caller','whos'); value=sum([info.bytes])/2^20;
end

function value=LOCAL_value_mib(item)
  info=whos('item'); value=info.bytes/2^20;
end

function out=LOCAL_owner_inventory()
  info=evalin('caller','whos'); out=cell(numel(info),1);
  for j=1:numel(info)
    out{j}=struct('name',info(j).name,'class',info(j).class, ...
      'size',info(j).size,'bytes',info(j).bytes);
  end
end
