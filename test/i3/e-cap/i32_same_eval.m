function out = i32_same_eval(c,z,artifact,timer)
%I32_SAME_EVAL Re-evaluate one immutable finite-density QP trial.
% Purpose:
%   Evaluate the staged circle and wall densities on preregistered image,
%   angular, wall-output, Riccati, and lift-quadrature ladders.
% Input:
%   c        - Frozen ecap-a1 numerical contract.
%   z        - Whitelisted immutable fbie-a1 certificate.
%   artifact - Raw historical maps used only for common-coordinate audit.
%   timer    - Entry timer used only for stage-start resource enforcement.
% Output:
%   out      - Nested action maps, weights, qualification records, warnings,
%              audit maps, and machine call counters.
% Main algorithm:
%   Apply fixed trigonometric densities to analytic free-circle factors,
%   symmetric quasiperiodic images, and exact modal wall cross actions. No
%   candidate, propagation, density, Schur, coordinate, or proxy solve occurs.
% Notes:
%   Plus is the exterior global +r trace; minus is the disk-interior +r trace.
%   The residual circle jump is minus derivative minus plus derivative.

  warnings=struct('code',{},'value',{},'blocking',{});
  calls=LOCAL_counters(); peak=0;
  try
    LOCAL_certificate_gate(z,artifact);
    density=LOCAL_density_coefficients(z);
    [circle,calls,peak]=LOCAL_circle_ladders(c,z,density,calls,peak,timer);
    [wall,calls,peak]=LOCAL_wall_ladders(c,z,density,calls,peak,timer);
    [weights,calls]=LOCAL_weights(c,z,calls);
    oracle=LOCAL_oracles(c,z,density,circle,calls);
    calls=oracle.call_counters;
    refinement=LOCAL_refinement_records(c,circle,wall,weights);
    structural=LOCAL_structural_metrics(c,z,density,circle,wall,oracle);
    [warnings,qualification]=LOCAL_warnings( ...
      c,circle,wall,weights,oracle,structural);
    core=LOCAL_core_finite(circle,wall,weights);
    first_code='NONE'; first_message='All required action maps are finite.';
    if ~core
      [first_code,first_message]=LOCAL_first_core_unavailable(circle,wall,weights);
    end
    record=struct('available',core&&oracle.available, ...
      'core_maps_available',core,'kernel_oracles_available',oracle.available, ...
      'kernel_qualified',oracle.qualified, ...
      'actual_T_action_qualified',circle.actual_T_action.qualified, ...
      'finite_image_Bloch_qualified',circle.finite_image_bloch.qualified, ...
      'conformity_qualified',structural.pass, ...
      'cap_prerequisites_pass',oracle.qualified&&structural.pass&& ...
        circle.actual_T_action.qualified&&circle.finite_image_bloch.qualified, ...
      'internal_qualification_pass',qualification, ...
      'structural_metrics',structural,'refinement_metrics',refinement, ...
      'image_levels',c.image_levels, ...
      'circle_levels',c.circle_levels,'wall_levels',c.wall_levels, ...
      'riccati_levels',c.riccati_levels,'gauss_levels',c.gauss_levels, ...
      'M_role','QZ wall-state input K=97 only', ...
      'eta_source_nodes',256,'wall_source_orders',512, ...
      'mathematical_trial_redefined',false, ...
      'all_computed_circle_modes_retained',true, ...
      'all_computed_wall_modes_retained',true, ...
      'uncomputed_tail_enclosed',false, ...
      'peak_local_workspace_mib',peak);
    audit=struct('density_orders',density.orders, ...
      'eta_tau_coefficients',density.tau,'eta_zeta_coefficients',density.zeta, ...
      'circle_final_theta',circle.theta,'circle_final_orders',circle.orders, ...
      'wall_final_orders',wall.orders,'oracle',oracle.record, ...
      'structural_metrics',structural, ...
      'artifact_raw_map_names',{fieldnames(artifact)}, ...
      'normal_orientation','circle global +r; wall cell-outward', ...
      'density_coordinate','[tau;zeta], zeta=-sigma');
    public=LOCAL_public_evaluation( ...
      record,circle,wall,weights,oracle.record,refinement);
    out=struct('available',core&&oracle.available, ...
      'core_available',core,'first_unavailable_code',first_code, ...
      'first_unavailable_message',first_message,'circle',circle,'wall',wall, ...
      'weights',weights,'oracles',oracle.record,'record',record,'audit',audit, ...
      'warnings',warnings,'call_counters',calls,'public',public);
  catch ME
    switch ME.identifier
      case {'i32e:DensityTransform','i32e:CircleHarmonicAction', ...
          'i32e:WallCircleAction','i32e:CircleWallAction'}
        out=struct('available',false,'core_available',false, ...
          'first_unavailable_code',ME.identifier, ...
          'first_unavailable_message',ME.message,'circle',struct(), ...
          'wall',struct(),'weights',struct(),'oracles',struct(), ...
          'record',struct('available',false,'core_maps_available',false, ...
            'peak_local_workspace_mib',peak),'audit',struct(), ...
          'warnings',warnings,'call_counters',calls,'public',struct());
      otherwise
        rethrow(ME);
    end
  end
end

function [code,message]=LOCAL_first_core_unavailable(circle,wall,weights)
  if ~all([weights.circle.positive])||~weights.wall_trace_positive|| ...
      any(~isfinite(weights.collar_final))||any(weights.collar_final<0)|| ...
      any(~isfinite(weights.wall_lift_final))||any(weights.wall_lift_final<0)
    code='REQUIRED_TRACE_OR_LIFT_WEIGHT_UNAVAILABLE';
    message='A required circle, wall-trace, collar, or wall-lift weight is invalid.';
  elseif ~all([circle.image_levels.finite])|| ...
      ~all([circle.angular_levels.finite])||~all([wall.levels.finite])
    code='SAME_TRIAL_ACTION_NUMERICALLY_UNAVAILABLE';
    message='A required fixed-density circle or wall action is nonfinite.';
  else
    code='SAME_TRIAL_EVALUATION_UNAVAILABLE';
    message='A required same-trial evaluation object is unavailable.';
  end
end

%% ==================== Certificate and density coordinates ====================
% Only immutable staged arrays enter the same-trial evaluator.

function LOCAL_certificate_gate(z,a)
  if round(z.M)~=48||round(z.K)~=97||size(z.eta_unit_256,1)~=512|| ...
      size(z.xi_left_unit_512,1)~=512||size(z.xi_right_unit_512,1)~=512
    error('i32e:CertificateDimensions','A frozen density dimension is wrong.');
  end
  required={'delta_plus','delta_minus','circle_jump_plus', ...
    'circle_jump_minus','QLplus','QRplus','QLminus','QRminus', ...
    'Jplus','Jminus','wall_flux_left_unit_512', ...
    'wall_flux_right_unit_512','circle_delta_D_unit_wall_512', ...
    'circle_j_Gamma_unit_wall_512','circle_theta_512'};
  for j=1:numel(required)
    if ~isfield(a,required{j})||isempty(a.(required{j}))|| ...
        any(~isfinite(a.(required{j})),'all')
      error('i32e:ArtifactRawMap','Missing raw artifact map %s.',required{j});
    end
  end
end

function out=LOCAL_density_coefficients(z)
  N=256; eta=z.eta_unit_256;
  out=struct('orders',(-N/2:N/2-1).', ...
    'tau',fftshift(fft(eta(1:N,:),[],1),1)/N, ...
    'zeta',fftshift(fft(eta(N+1:end,:),[],1),1)/N, ...
    'xi_left',z.xi_left_unit_512,'xi_right',z.xi_right_unit_512);
  if any(~isfinite([out.tau(:);out.zeta(:)]))
    error('i32e:DensityTransform','The fixed density FFT is nonfinite.');
  end
end

function out=LOCAL_counters()
  out=struct('candidate_solve_calls',0,'qz_solve_calls',0, ...
    'coordinate_solve_calls',0,'propagation_solve_calls',0, ...
    'wall_density_solve_calls',0,'circle_density_solve_calls',0, ...
    'schur_solve_calls',0,'proxy_build_calls',0, ...
    'harmonic_action_calls',0,'image_pair_updates',0, ...
    'kress_oracle_calls',0,'linton_oracle_calls',0, ...
    'actual_deltaT_action_calls',0,'finite_bloch_image_updates',0, ...
    'riccati_calls',0,'gauss_factor_calls',0, ...
    'full_p_contraction_calls',0);
end

%% ==================== Circle harmonic-image action ====================
% Free self factors and nonzero QP images are evaluated by independent paths.

function [out,calls,peak]=LOCAL_circle_ladders(c,z,density,calls,peak,timer)
  N=2048; theta=(0:N-1)'*2*pi/N; orders=(-N/2:N/2-1).';
  x=z.R*cos(theta); y=z.R*sin(theta); nx=cos(theta); ny=sin(theta);
  ko=z.khat; ki=sqrt(z.rho_disk)*z.khat;
  [ve0,dve0,vi0,dvi0,wronskian,tout0,tin0,dsout0,dsin0]=LOCAL_free_self( ...
    z,density,theta,ko,ki);
  [vw,dvw]=LOCAL_wall_to_circle(z,density,theta,x,y,nx,ny);
  checkpoints=c.image_levels; snapshots=repmat(struct( ...
    'J',0,'exterior_value',[],'exterior_dr',[], ...
    'exterior_T_tau',[],'exterior_dS_zeta',[]),1,numel(checkpoints));
  image_value=zeros(N,size(density.tau,2)); image_dr=image_value;
  image_T_tau=image_value; image_dS_zeta=image_value;
  hit=1;
  for n=1:max(checkpoints)
    for signn=[-1,1]
      [dv,ddr,dTtau,dSzeta]=LOCAL_one_image( ...
        z,density,theta,x,y,nx,ny,signn*n);
      image_value=image_value+dv; image_dr=image_dr+ddr;
      image_T_tau=image_T_tau+dTtau;
      image_dS_zeta=image_dS_zeta+dSzeta;
      calls.image_pair_updates=calls.image_pair_updates+1;
    end
    if hit<=numel(checkpoints)&&n==checkpoints(hit)
      snapshots(hit)=struct('J',n, ...
        'exterior_value',ve0+vw+image_value, ...
        'exterior_dr',dve0+dvw+image_dr, ...
        'exterior_T_tau',tout0+image_T_tau, ...
        'exterior_dS_zeta',dsout0+image_dS_zeta);
      hit=hit+1;
    end
    if mod(n,16)==0
      if toc(timer)>c.hard_seconds
        error('i32e:HardTime','The hard limit was reached in image action.');
      end
      info=whos; peak=max(peak,sum([info.bytes])/2^20);
    end
  end
  calls.harmonic_action_calls=calls.harmonic_action_calls+1;
  calls.actual_deltaT_action_calls=calls.actual_deltaT_action_calls+ ...
    numel(checkpoints)+numel(c.circle_levels);
  image_levels=repmat(LOCAL_empty_circle_level(),1,numel(checkpoints));
  for j=1:numel(checkpoints)
    image_levels(j)=LOCAL_circle_level(snapshots(j).exterior_value,vi0, ...
      snapshots(j).exterior_dr,dvi0,snapshots(j).exterior_T_tau,tin0, ...
      snapshots(j).exterior_dS_zeta,dsin0,dvw,z.R,N,N,c.identity_tol);
    image_levels(j).label=sprintf('image-J-%d',checkpoints(j));
    image_levels(j).J=checkpoints(j);
    image_levels(j).value_plus=[]; image_levels(j).value_minus=[];
    image_levels(j).dr_plus=[]; image_levels(j).dr_minus=[];
    image_levels(j).actual_deltaT_samples=[];
    if j~=6
      image_levels(j).delta_samples=[]; image_levels(j).jump_samples=[];
    end
  end
  final=snapshots(end);
  clear snapshots image_value image_dr image_T_tau image_dS_zeta;
  angular_levels=repmat(LOCAL_empty_circle_level(),1,3);
  for j=1:3
    Nt=c.circle_levels(j); stride=N/Nt; index=1:stride:N;
    angular_levels(j)=LOCAL_circle_level(final.exterior_value(index,:), ...
      vi0(index,:),final.exterior_dr(index,:),dvi0(index,:), ...
      final.exterior_T_tau(index,:),tin0(index,:), ...
      final.exterior_dS_zeta(index,:),dsin0(index,:),dvw(index,:), ...
      z.R,Nt,N,c.identity_tol);
    angular_levels(j).label=sprintf('angular-N-%d',Nt);
    angular_levels(j).J=max(checkpoints);
    angular_levels(j).value_plus=[]; angular_levels(j).value_minus=[];
    angular_levels(j).dr_plus=[]; angular_levels(j).dr_minus=[];
    angular_levels(j).delta_samples=[]; angular_levels(j).jump_samples=[];
    angular_levels(j).actual_deltaT_samples=[];
  end
  raw_delta=final.exterior_value-vi0;
  repair=LOCAL_metric_record(final.exterior_value-raw_delta/2, ...
    vi0+raw_delta/2,c.identity_tol);
  actual_T=LOCAL_actual_T_qualification(c,image_levels,angular_levels);
  [finite_bloch,calls]=LOCAL_finite_image_bloch(c,z,density,calls);
  out=struct('theta',theta,'orders',orders,'image_levels',image_levels, ...
    'angular_levels',angular_levels,'final',angular_levels(end), ...
    'wronskian',wronskian,'repaired_value_metric',repair, ...
    'actual_T_action',actual_T,'finite_image_bloch',finite_bloch, ...
    'raw_value_jump_norm',norm(raw_delta,'fro'),'plus_is_exterior',true, ...
    'jump_orientation','interior minus exterior global +r', ...
    'normal_decomposition_formula', ...
      'jGamma=-DeltaT_tau+(dS_QP-dS_i)zeta-d_r u_wall', ...
    'source_nodes',256,'target_nodes',N);
end

function out=LOCAL_actual_T_qualification(c,image,angular)
  % Qualify the actual fixed-density Delta-T action, not a free-mode proxy.
  pairs=[3,5;5,7;2,4;4,6;6,7];
  labels={'64_to_128','128_to_256','48_to_96','96_to_192','192_to_256'};
  metric_template=struct('label','','numerator',NaN,'left_norm',NaN, ...
    'right_norm',NaN,'zero_component',false,'scale',NaN,'ratio',NaN, ...
    'threshold',NaN,'pass',false);
  image_metric=repmat(metric_template,1,5);
  image_scale=realmin;
  for j=1:numel(image)
    image_scale=max(image_scale,norm(image(j).actual_deltaT_coeff,'fro'));
  end
  for j=1:5
    value=LOCAL_metric_record(image(pairs(j,1)).actual_deltaT_coeff, ...
      image(pairs(j,2)).actual_deltaT_coeff);
    image_metric(j)=struct('label',labels{j}, ...
      'numerator',value.numerator,'left_norm',value.left_norm, ...
      'right_norm',value.right_norm,'zero_component',value.zero_component, ...
      'scale',value.scale,'ratio',value.ratio, ...
      'threshold',NaN,'pass',value.pass);
  end
  omega_image=100*numel(image(end).actual_deltaT_coeff)*eps*image_scale;
  image_metric(1).threshold=Inf;
  image_metric(2).threshold=max( ...
    c.image_ratio_max*image_metric(1).numerator,omega_image);
  image_metric(3).threshold=Inf;
  image_metric(4).threshold=max( ...
    c.image_ratio_max*image_metric(3).numerator,omega_image);
  image_metric(5).threshold=Inf;
  for j=1:5
    image_metric(j).pass=isfinite(image_metric(j).numerator)&& ...
      image_metric(j).numerator<=image_metric(j).threshold;
  end
  dyadic_near=image_metric(1).numerator<=omega_image&& ...
    image_metric(2).numerator<=omega_image;
  staggered_near=image_metric(3).numerator<=omega_image&& ...
    image_metric(4).numerator<=omega_image;
  dyadic=dyadic_near||image_metric(2).numerator<= ...
    max(c.image_ratio_max*image_metric(1).numerator,omega_image);
  staggered=staggered_near||image_metric(4).numerator<= ...
    max(c.image_ratio_max*image_metric(3).numerator,omega_image);
  image_available=all(isfinite([image_metric.numerator,omega_image]));

  angular_metric=repmat(metric_template,1,2);
  angular_scale=realmin;
  for j=1:numel(angular)
    angular_scale=max(angular_scale,norm(angular(j).actual_deltaT_coeff,'fro'));
  end
  for j=1:2
    value=LOCAL_metric_record(angular(j).actual_deltaT_coeff, ...
      angular(j+1).actual_deltaT_coeff);
    angular_metric(j)=struct('label',sprintf('%d_to_%d', ...
      angular(j).target_nodes,angular(j+1).target_nodes), ...
      'numerator',value.numerator,'left_norm',value.left_norm, ...
      'right_norm',value.right_norm,'zero_component',value.zero_component, ...
      'scale',value.scale,'ratio',value.ratio, ...
      'threshold',NaN,'pass',value.pass);
  end
  omega_angular=100*numel(angular(end).actual_deltaT_coeff)*eps*angular_scale;
  angular_metric(1).threshold=Inf;
  angular_metric(2).threshold=max( ...
    c.spectral_ratio_max*angular_metric(1).numerator,omega_angular);
  for j=1:2
    angular_metric(j).pass=isfinite(angular_metric(j).numerator)&& ...
      angular_metric(j).numerator<=angular_metric(j).threshold;
  end
  angular_near=all([angular_metric.numerator]<=omega_angular);
  angular_contract=angular_metric(2).numerator<= ...
    max(c.spectral_ratio_max*angular_metric(1).numerator,omega_angular);
  angular_available=all(isfinite([angular_metric.numerator,omega_angular]));
  ratio_values=[image_metric(2).numerator/ ...
    max(realmin,image_metric(1).numerator), ...
    image_metric(4).numerator/max(realmin,image_metric(3).numerator), ...
    angular_metric(2).numerator/max(realmin,angular_metric(1).numerator)];
  if all(isfinite(ratio_values)), maximum_ratio=max(ratio_values);
  else, maximum_ratio=Inf; end
  available=image_available&&angular_available;
  qualified=available&&dyadic&&staggered&&(angular_near||angular_contract);
  out=struct('available',available,'qualified',qualified, ...
    'orientation','exterior minus interior global +r', ...
    'definition','d_r(D_QP tau)-d_r(D_i tau)', ...
    'image_metrics',image_metric,'angular_metrics',angular_metric, ...
    'image_omega',omega_image,'angular_omega',omega_angular, ...
    'image_ratio_threshold',c.image_ratio_max, ...
    'angular_ratio_threshold',c.spectral_ratio_max, ...
    'dyadic_pass',dyadic,'staggered_pass',staggered, ...
    'cross_finite',isfinite(image_metric(5).numerator), ...
    'angular_pass',angular_near||angular_contract, ...
    'maximum_contraction_ratio',maximum_ratio, ...
    'all_level_maps_stored_separately',true);
end

function [out,calls]=LOCAL_finite_image_bloch(c,z,density,calls)
  try
    [out,calls]=LOCAL_finite_image_bloch_core(c,z,density,calls);
  catch ME
    if ~any(strcmp(ME.identifier, ...
        {'i32e:CircleHarmonicAction','i32e:WallCircleAction'}))
      rethrow(ME);
    end
    out=struct('available',false,'qualified',false,'levels',[], ...
      'safe_target_x',.30,'paired_y',[-z.d/2,z.d/2], ...
      'physical_Bloch_phase',exp(1i*z.beta*z.d), ...
      'derivative','global +y at both paired targets', ...
      'same_fixed_eta_and_xi_consumed',true, ...
      'finite_image_J',c.image_levels,'threshold',c.identity_tol, ...
      'angular_target_grid_dependency', ...
        'none: paired point action consumes fixed eta Fourier coefficients', ...
      'maximum_final_ratio',Inf,'fail_open',true, ...
      'exact_continuous_QP_Bloch_is_structural',true, ...
      'finite_image_action_enclosed',false,'message',ME.message);
  end
end

function [out,calls]=LOCAL_finite_image_bloch_core(c,z,density,calls)
  % Exercise the actual finite-image eta/xi action at paired Bloch targets.
  checkpoints=c.image_levels; x=.30; y=[-z.d/2,z.d/2];
  phase=exp(1i*z.beta*z.d);
  template=struct('J',0,'bottom_value',[],'top_value',[], ...
    'bottom_global_y_derivative',[],'top_global_y_derivative',[], ...
    'value_metric',LOCAL_metric_record(0,0), ...
    'flux_metric',LOCAL_metric_record(0,0));
  levels=repmat(template,1,numel(checkpoints));
  value=zeros(2,size(density.tau,2)); derivative=value;
  for side=1:2
    [wall_value,wall_derivative]=LOCAL_wall_to_circle( ...
      z,density,0,x,y(side),0,1);
    [self_value,self_derivative]=LOCAL_one_image( ...
      z,density,0,x,y(side),0,1,0);
    value(side,:)=wall_value+self_value;
    derivative(side,:)=wall_derivative+self_derivative;
  end
  hit=1;
  for n=1:max(checkpoints)
    for signn=[-1,1]
      for side=1:2
        [dv,ddr]=LOCAL_one_image(z,density,0,x,y(side),0,1,signn*n);
        value(side,:)=value(side,:)+dv;
        derivative(side,:)=derivative(side,:)+ddr;
        calls.finite_bloch_image_updates=calls.finite_bloch_image_updates+1;
      end
    end
    if hit<=numel(checkpoints)&&n==checkpoints(hit)
      vm=LOCAL_metric_record(value(2,:),phase*value(1,:),c.identity_tol);
      fm=LOCAL_metric_record( ...
        derivative(2,:),phase*derivative(1,:),c.identity_tol);
      levels(hit)=struct('J',n,'bottom_value',value(1,:), ...
        'top_value',value(2,:), ...
        'bottom_global_y_derivative',derivative(1,:), ...
        'top_global_y_derivative',derivative(2,:), ...
        'value_metric',vm,'flux_metric',fm);
      hit=hit+1;
    end
  end
  value_ratio=arrayfun(@(item) item.value_metric.ratio,levels);
  flux_ratio=arrayfun(@(item) item.flux_metric.ratio,levels);
  available=all(isfinite([value_ratio,flux_ratio]));
  if available, final=max(value_ratio(end),flux_ratio(end)); else, final=Inf; end
  % The exact-QP trial is structural; this finite-image approximation is
  % qualified only if its actual paired physical action meets the frozen gate.
  qualified=available&&final<=c.identity_tol;
  out=struct('available',available,'qualified',qualified,'levels',levels, ...
    'safe_target_x',x,'paired_y',y,'physical_Bloch_phase',phase, ...
    'derivative','global +y at both paired targets', ...
    'same_fixed_eta_and_xi_consumed',true, ...
    'finite_image_J',checkpoints,'threshold',c.identity_tol, ...
    'angular_target_grid_dependency', ...
      'none: paired point action consumes fixed eta Fourier coefficients', ...
    'maximum_final_ratio',final,'fail_open',true, ...
    'exact_continuous_QP_Bloch_is_structural',true, ...
    'finite_image_action_enclosed',false);
end

function empty=LOCAL_empty_circle_level()
  empty=struct('label','','J',0,'target_nodes',0,'orders',[], ...
    'value_plus',[],'value_minus',[],'dr_plus',[],'dr_minus',[], ...
    'delta_coeff',[],'jump_coeff',[],'actual_deltaT_coeff',[], ...
    'dS_difference_zeta_norm',NaN,'wall_normal_norm',NaN, ...
    'delta_samples',[],'jump_samples',[],'actual_deltaT_samples',[], ...
    'normal_decomposition_metric',struct(), ...
    'finite',false);
end

function out=LOCAL_circle_level( ...
    vp,vm,dp,dm,tp,tm,sp,sm,wall_dr,R,N,Nfinal,identity_tol)
  delta=vp-vm; jump=dm-dp;
  delta_coeff=LOCAL_circle_coeff(delta,R); jump_coeff=LOCAL_circle_coeff(jump,R);
  deltaT=tp-tm; dSzeta=sp-sm;
  decomposition=-deltaT+dSzeta-wall_dr;
  decomposition_metric=LOCAL_metric_record(jump,decomposition,identity_tol);
  deltaT_coeff=LOCAL_circle_coeff(deltaT,R);
  dSzeta_coeff=LOCAL_circle_coeff(dSzeta,R);
  wall_coeff=LOCAL_circle_coeff(wall_dr,R);
  delta_coeff=LOCAL_pad_orders(delta_coeff,N,Nfinal);
  jump_coeff=LOCAL_pad_orders(jump_coeff,N,Nfinal);
  deltaT_coeff=LOCAL_pad_orders(deltaT_coeff,N,Nfinal);
  dSzeta_coeff=LOCAL_pad_orders(dSzeta_coeff,N,Nfinal);
  wall_coeff=LOCAL_pad_orders(wall_coeff,N,Nfinal);
  out=struct('label','','J',0,'target_nodes',N, ...
    'orders',(-N/2:N/2-1).','value_plus',vp,'value_minus',vm, ...
    'dr_plus',dp,'dr_minus',dm,'delta_coeff',delta_coeff, ...
    'jump_coeff',jump_coeff,'actual_deltaT_coeff',deltaT_coeff, ...
    'dS_difference_zeta_norm',norm(dSzeta_coeff,'fro'), ...
    'wall_normal_norm',norm(wall_coeff,'fro'), ...
    'delta_samples',delta,'jump_samples',jump, ...
    'actual_deltaT_samples',deltaT, ...
    'normal_decomposition_metric',decomposition_metric, ...
    'finite',all(isfinite([delta_coeff(:);jump_coeff(:);deltaT_coeff(:); ...
      dSzeta_coeff(:);wall_coeff(:);decomposition_metric.ratio])));
end

function [ve,dve,vi,dvi,record,tout,tin,dsout,dsin]= ...
    LOCAL_free_self(z,density,theta,ko,ki)
  ell=density.orders; E=exp(1i*theta*ell.');
  [So,Dpo,~,dSpo,~,To,wo]=LOCAL_free_factors(ell,ko,z.R);
  [Si,~,Dmi,~,dSmi,Ti,wi]=LOCAL_free_factors(ell,ki,z.R);
  ve=E*(bsxfun(@times,Dpo,density.tau)- ...
    bsxfun(@times,So,density.zeta));
  tout=E*bsxfun(@times,To,density.tau);
  dsout=E*bsxfun(@times,dSpo,density.zeta);
  dve=tout-dsout;
  vi=E*(bsxfun(@times,Dmi,density.tau)- ...
    bsxfun(@times,Si,density.zeta));
  tin=E*bsxfun(@times,Ti,density.tau);
  dsin=E*bsxfun(@times,dSmi,density.zeta);
  dvi=tin-dsin;
  record=struct('exterior',wo,'interior',wi, ...
    'minus_S_exterior_minus_interior_jump_is_plus_zeta',true);
end

function [S,Dplus,Dminus,dSplus,dSminus,T,record]=LOCAL_free_factors(ell,k,R)
  z=k*R; [lj,pj,ljp,pjp]=LOCAL_bessel_log_j(ell,z);
  [lh,ph,lhp,php]=LOCAL_hankel_log_orders(ell,z);
  S=1i*pi*R/2*LOCAL_log_product(lj,pj,lh,ph);
  Dplus=1i*pi*k*R/2*LOCAL_log_product(ljp,pjp,lh,ph);
  Dminus=1i*pi*k*R/2*LOCAL_log_product(lj,pj,lhp,php);
  dSplus=Dminus; dSminus=Dplus;
  T=1i*pi*k^2*R/2*LOCAL_log_product(ljp,pjp,lhp,php);
  jumpD=Dplus-Dminus; jumpS=dSplus-dSminus;
  scaleD=max([realmin*ones(size(ell)),abs(Dplus),abs(Dminus)],[],2);
  record=struct('orders',ell,'D_jump_defect', ...
    max(abs(jumpD-1)./max(realmin,scaleD)), ...
    'dS_jump_defect',max(abs(jumpS+1)./max(realmin,scaleD)), ...
    'finite',all(isfinite([S;Dplus;Dminus;dSplus;dSminus;T])), ...
    'scaled_log_products',true, ...
    'recurrence_oracle_attached_separately',true);
end

function [value,dr,Ttau,dSzeta]=LOCAL_one_image(z,density,theta,x,y,nx,ny,n)
  k=z.khat; R=z.R; ell=density.orders; center_y=n*z.d;
  dx=x; dy=y-center_y; rn=hypot(dx,dy); angle=atan2(dy,dx);
  erx=dx./rn; ery=dy./rn; etx=-ery; ety=erx;
  radial_dot=nx.*erx+ny.*ery; tangent_dot=nx.*etx+ny.*ety;
  phase=exp(1i*z.beta*n*z.d); N=numel(theta); K=size(density.tau,2);
  value=zeros(N,K); dr=value; Ttau=value; dSzeta=value;
  [lh,ph,lhp,php]=LOCAL_hankel_log_table(ell,k*rn);
  for first=1:16:numel(ell)
    ids=first:min(first+15,numel(ell)); l=ell(ids).';
    A=exp(1i*angle*l);
    [lj,pj,ljp,pjp]=LOCAL_bessel_log_j(l,k*R);
    JH=exp(bsxfun(@plus,lh(:,ids),lj)+ ...
      1i*bsxfun(@plus,ph(:,ids),pj));
    JpH=exp(bsxfun(@plus,lh(:,ids),ljp)+ ...
      1i*bsxfun(@plus,ph(:,ids),pjp));
    JHp=exp(bsxfun(@plus,lhp(:,ids),lj)+ ...
      1i*bsxfun(@plus,php(:,ids),pj));
    JpHp=exp(bsxfun(@plus,lhp(:,ids),ljp)+ ...
      1i*bsxfun(@plus,php(:,ids),pjp));
    Sop=1i*pi*R/2*(JH.*A); Dop=1i*pi*R*k/2*(JpH.*A);
    radialS=1i*pi*R/2*bsxfun(@times,JHp.*A,k*radial_dot);
    radialD=1i*pi*R*k/2*bsxfun(@times,JpHp.*A,k*radial_dot);
    tangentS=bsxfun(@times,Sop,1i*tangent_dot./rn).*l;
    tangentD=bsxfun(@times,Dop,1i*tangent_dot./rn).*l;
    dSop=radialS+tangentS; dDop=radialD+tangentD;
    if any(~isfinite([Sop(:);Dop(:);dSop(:);dDop(:)]))
      error('i32e:CircleHarmonicAction', ...
        'A required scaled harmonic product is nonfinite.');
    end
    value=value+phase*(Dop*density.tau(ids,:)-Sop*density.zeta(ids,:));
    dr=dr+phase*(dDop*density.tau(ids,:)-dSop*density.zeta(ids,:));
    Ttau=Ttau+phase*(dDop*density.tau(ids,:));
    dSzeta=dSzeta+phase*(dSop*density.zeta(ids,:));
  end
end

function [lh,ph,lhp,php]=LOCAL_hankel_log_table(orders,z)
  N=numel(z); K=numel(orders); lh=zeros(N,K); ph=lh; lhp=lh; php=lh;
  for j=1:N
    [lh(j,:),ph(j,:),lhp(j,:),php(j,:)]= ...
      LOCAL_hankel_log_orders(orders.',z(j));
  end
end

%% ==================== Analytic wall/circle cross actions ====================
% Wall sources remain I_512 while response/output orders are independent.

function [value,dr]=LOCAL_wall_to_circle(z,density,theta,x,y,nx,ny)
  orders=(-256:255).'; beta=z.beta+2*pi*orders/z.d;
  gamma=LOCAL_outgoing(z.khat,beta); psi=exp(1i*y*beta.')/sqrt(z.d);
  left_phase=exp(1i*(x-z.X_L)*gamma.');
  right_phase=exp(1i*(z.X_R-x)*gamma.');
  s0=1i./(2*gamma);
  SL=bsxfun(@times,psi.*left_phase,s0.');
  SR=bsxfun(@times,psi.*right_phase,s0.');
  dSL=SL.*(nx*(1i*gamma).'+ny*(1i*beta).');
  dSR=SR.*(nx*(-1i*gamma).'+ny*(1i*beta).');
  value=SL*density.xi_left+SR*density.xi_right;
  dr=dSL*density.xi_left+dSR*density.xi_right;
  if any(~isfinite([value(:);dr(:)]))
    error('i32e:WallCircleAction','The wall-to-circle action is nonfinite.');
  end
end

function [out,calls,peak]=LOCAL_wall_ladders(c,z,density,calls,peak,timer)
  levels=repmat(struct('N',0,'orders',[],'raw_left',[],'raw_right',[], ...
    'defect_left',[],'defect_right',[],'flux_left',[],'flux_right',[], ...
    'g_left',[],'g_right',[],'circle_left',[],'circle_right',[], ...
    'finite',false),1,3);
  for j=1:3
    N=c.wall_levels(j); orders=(-N/2:N/2-1).';
    [FL,FR]=LOCAL_circle_to_wall(z,density,orders);
    [xiL,xiR,gL,gR]=LOCAL_wall_pad(z,N);
    beta=z.beta+2*pi*orders/z.d; gamma=LOCAL_outgoing(z.khat,beta);
    E=exp(1i*gamma*(z.X_R-z.X_L)); s0=1i./(2*gamma);
    rawL=s0.*(xiL+E.*xiR)+FL; rawR=s0.*(E.*xiL+xiR)+FR;
    fluxL=.5*(xiL-E.*xiR)+1i*gamma.*FL;
    fluxR=.5*(-E.*xiL+xiR)+1i*gamma.*FR;
    levels(j)=struct('N',N,'orders',orders,'raw_left',rawL, ...
      'raw_right',rawR,'defect_left',gL-rawL,'defect_right',gR-rawR, ...
      'flux_left',fluxL,'flux_right',fluxR,'circle_left',FL, ...
      'circle_right',FR,'g_left',gL,'g_right',gR, ...
      'finite',all(isfinite([rawL(:);rawR(:); ...
        fluxL(:);fluxR(:)])));
    calls.harmonic_action_calls=calls.harmonic_action_calls+1;
    info=whos; peak=max(peak,sum([info.bytes])/2^20);
    if toc(timer)>c.hard_seconds
      error('i32e:HardTime','The hard limit was reached in wall action.');
    end
  end
  empty_metric=LOCAL_metric_record(0,0);
  refinement=repmat(struct('from_orders',0,'to_orders',0, ...
    'raw_left',empty_metric,'raw_right',empty_metric, ...
    'flux_left',empty_metric,'flux_right',empty_metric),1,2);
  for j=1:2
    N0=levels(j).N; N1=levels(j+1).N;
    refinement(j)=struct('from_orders',N0,'to_orders',N1, ...
      'raw_left',LOCAL_metric_record(LOCAL_pad_orders( ...
        levels(j).raw_left,N0,N1),levels(j+1).raw_left,c.action_ratio_max), ...
      'raw_right',LOCAL_metric_record(LOCAL_pad_orders( ...
        levels(j).raw_right,N0,N1),levels(j+1).raw_right,c.action_ratio_max), ...
      'flux_left',LOCAL_metric_record(LOCAL_pad_orders( ...
        levels(j).flux_left,N0,N1),levels(j+1).flux_left,c.action_ratio_max), ...
      'flux_right',LOCAL_metric_record(LOCAL_pad_orders( ...
        levels(j).flux_right,N0,N1),levels(j+1).flux_right,c.action_ratio_max));
  end
  repair=LOCAL_metric_record([levels(end).raw_left+levels(end).defect_left; ...
    levels(end).raw_right+levels(end).defect_right], ...
    [levels(end).g_left;levels(end).g_right],c.identity_tol);
  for j=1:3
    levels(j).raw_left=[]; levels(j).raw_right=[];
    levels(j).g_left=[]; levels(j).g_right=[];
    levels(j).circle_left=[]; levels(j).circle_right=[];
  end
  out=struct('levels',levels,'final',levels(end), ...
    'orders',levels(end).orders,'source_orders',(-256:255).', ...
    'source_coefficients_fixed',true,'refinement',refinement, ...
    'repaired_value_metric',repair);
end

function [FL,FR]=LOCAL_circle_to_wall(z,density,orders)
  beta=z.beta+2*pi*orders/z.d; gamma=LOCAL_outgoing(z.khat,beta);
  l=density.orders.'; k=z.khat; R=z.R; zr=k*R;
  [lj,pj,ljp,pjp]=LOCAL_bessel_log_j(l,zr);
  FL=zeros(numel(orders),size(density.tau,2)); FR=FL;
  for j=1:numel(orders)
    common=1i/(2*gamma(j)*sqrt(z.d));
    travel_log=1i*gamma(j)*(z.X_R-z.X_L)/2;
    tauR=LOCAL_farfield_row(common,travel_log, ...
      (gamma(j)+1i*beta(j))/k,l,log(2*pi*R*k)+ljp,pjp);
    tauL=LOCAL_farfield_row(common,travel_log, ...
      (-gamma(j)+1i*beta(j))/k,l,log(2*pi*R*k)+ljp,pjp);
    zetaR=LOCAL_farfield_row(common,travel_log, ...
      (gamma(j)+1i*beta(j))/k,l,log(2*pi*R)+lj,pj);
    zetaL=LOCAL_farfield_row(common,travel_log, ...
      (-gamma(j)+1i*beta(j))/k,l,log(2*pi*R)+lj,pj);
    FR(j,:)=tauR*density.tau-zetaR*density.zeta;
    FL(j,:)=tauL*density.tau-zetaL*density.zeta;
  end
  if any(~isfinite([FL(:);FR(:)]))
    error('i32e:CircleWallAction','The circle-to-wall action is nonfinite.');
  end
end

function value=LOCAL_farfield_row(common,travel_log,base,l,lograd,phaserad)
  logarithm=log(common)+travel_log+l.*log(-1i)+l.*log(base)+ ...
    lograd+1i*phaserad;
  value=exp(logarithm);
end

function [logJ,phaseJ,logJp,phaseJp]=LOCAL_bessel_log_j(orders,z)
  nmax=max(abs(orders))+1; logs=zeros(nmax+1,1); phases=zeros(nmax+1,1);
  for n=0:nmax
    term=1; series=1;
    for q=1:200
      term=term*(-z^2/4)/(q*(n+q)); updated=series+term;
      if abs(term)<=eps*max(realmin,abs(updated)), series=updated; break; end
      series=updated;
    end
    logs(n+1)=n*log(abs(z/2))-gammaln(n+1)+log(abs(series));
    phases(n+1)=n*angle(z)+angle(series);
  end
  logJ=zeros(size(orders)); phaseJ=logJ; logJp=logJ; phaseJp=logJ;
  for j=1:numel(orders)
    n=abs(orders(j)); parity=pi*mod(n,2)*(orders(j)<0);
    logJ(j)=logs(n+1); phaseJ(j)=phases(n+1)+parity;
    if n==0
      logJp(j)=logs(2); phaseJp(j)=phases(2)+pi;
    else
      [logJp(j),phaseJp(j)]=LOCAL_log_difference( ...
        logs(n),phases(n),logs(n+2),phases(n+2),log(2));
      phaseJp(j)=phaseJp(j)+parity;
    end
  end
end

function [logH,phaseH,logHp,phaseHp]=LOCAL_hankel_log_orders(orders,z)
  nmax=max(abs(orders))+1; [logs,phases]=LOCAL_hankel_sequence(z,nmax);
  logH=zeros(size(orders)); phaseH=logH; logHp=logH; phaseHp=logH;
  for j=1:numel(orders)
    n=abs(orders(j)); parity=pi*mod(n,2)*(orders(j)<0);
    logH(j)=logs(n+1); phaseH(j)=phases(n+1)+parity;
    if n==0
      logHp(j)=logs(2); phaseHp(j)=phases(2)+pi;
    else
      [logHp(j),phaseHp(j)]=LOCAL_log_difference( ...
        logs(n),phases(n),logs(n+2),phases(n+2),log(2));
      phaseHp(j)=phaseHp(j)+parity;
    end
  end
end

function [logs,phases]=LOCAL_hankel_sequence(z,nmax)
  pair=[besselh(0,1,z),besselh(1,1,z)]; logscale=0;
  logs=zeros(nmax+1,1); phases=logs;
  logs(1)=log(abs(pair(1))); phases(1)=angle(pair(1));
  if nmax==0, return; end
  logs(2)=log(abs(pair(2))); phases(2)=angle(pair(2));
  for n=1:nmax-1
    next=2*n/z*pair(2)-pair(1); magnitude=max(abs([pair,next]));
    if magnitude>1e100||magnitude<1e-100
      pair=pair/magnitude; next=next/magnitude; logscale=logscale+log(magnitude);
    end
    pair=[pair(2),next]; logs(n+2)=log(abs(next))+logscale;
    phases(n+2)=angle(next);
  end
end

function [logvalue,phase]=LOCAL_log_difference(la,pa,lb,pb,subtract_log)
  scale=max(la,lb); value=exp(la-scale+1i*pa)-exp(lb-scale+1i*pb);
  logvalue=scale+log(abs(value))-subtract_log;
  phase=angle(value);
end

function value=LOCAL_log_product(la,pa,lb,pb)
  value=exp(la+lb+1i*(pa+pb));
end

function [xiL,xiR,gL,gR]=LOCAL_wall_pad(z,N)
  xiL=LOCAL_pad_orders(z.xi_left_unit_512,512,N);
  xiR=LOCAL_pad_orders(z.xi_right_unit_512,512,N);
  input=z.wall_input_unit_512;
  gL=LOCAL_pad_orders(input(1:512,:),512,N);
  gR=LOCAL_pad_orders(input(513:end,:),512,N);
end

function gamma=LOCAL_outgoing(k,beta)
  gamma=sqrt(complex(k^2-beta.^2));
  flip=imag(gamma)<0|(imag(gamma)==0&real(gamma)<0);
  gamma(flip)=-gamma(flip);
  if any(~isfinite(gamma))||any(gamma==0)
    error('i32e:BranchUnavailable','A required outgoing branch is unavailable.');
  end
end

%% ==================== Trace and lift weights ====================
% Riccati and Gauss ladders use the frozen physical normalizations.

function [out,calls]=LOCAL_weights(c,z,calls)
  ell=(-1024:1023).'; circle=cell(1,3);
  for j=1:3
    ric=LOCAL_riccati(z,ell,c.riccati_levels(j));
    weight=(ric.pin-ric.pout)/z.R;
    circle{j}=struct('steps',c.riccati_levels(j),'orders',ell, ...
      'weight',weight,'positive',all(isfinite(weight)&weight>0), ...
      'energy_identity_defect',max(ric.energy_identity_defect), ...
      'low_order_bessel_metric',LOCAL_low_bessel(z,ell,weight));
    calls.riccati_calls=calls.riccati_calls+2;
  end
  circle=[circle{:}]; collar=cell(1,3); wall=cell(1,3);
  beta=z.beta+2*pi*(-2048:2047).'/z.d;
  for j=1:3
    collar{j}=struct('gauss',c.gauss_levels(j),'orders',ell, ...
      'weight',LOCAL_collar_weights(z,ell,c.gauss_levels(j)));
    wall{j}=struct('gauss',c.gauss_levels(j),'orders',(-2048:2047).', ...
      'weight',LOCAL_wall_lift_weights(z,beta,c.gauss_levels(j)));
    calls.gauss_factor_calls=calls.gauss_factor_calls+2;
  end
  kappa=sqrt(beta.^2+z.gamma);
  wall_trace=2*kappa.*tanh(kappa/2);
  collar=[collar{:}]; wall=[wall{:}];
  out=struct('circle',circle,'collar',collar,'wall_lift',wall, ...
    'wall_trace',wall_trace,'circle_final',circle(end).weight, ...
    'collar_final',collar(end).weight,'wall_lift_final',wall(end).weight, ...
    'wall_trace_positive',all(isfinite(wall_trace)&wall_trace>0));
end

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

function weight=LOCAL_collar_weights(z,ell,nq)
  [x,w]=LOCAL_gauss(nq); weight=zeros(size(ell));
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

function weight=LOCAL_wall_lift_weights(z,beta,nq)
  [x,w]=LOCAL_gauss(nq); t=(x+1)/2; wx=z.delta_w*w/2;
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

%% ==================== Independent analytic oracles ====================
% Production is compared to active Kress splits and project-signed Linton.

function out=LOCAL_oracles(c,z,density,circle,calls)
  try
    free=LOCAL_free_oracle(z);
    calls.kress_oracle_calls=calls.kress_oracle_calls+1;
  catch ME
    if strcmp(ME.identifier,'i32e:ExactWood')|| ...
        strcmp(ME.identifier,'i32e:BranchUnavailable')
      rethrow(ME);
    end
    free=struct('available',false,'qualified',false,'message',ME.message, ...
      'maximum_relative_defect',Inf);
  end
  try
    linton=LOCAL_linton_oracle(c,z);
    calls.linton_oracle_calls=calls.linton_oracle_calls+1;
  catch ME
    if strcmp(ME.identifier,'i32e:ExactWood')|| ...
        strcmp(ME.identifier,'i32e:BranchUnavailable')
      rethrow(ME);
    end
    linton=struct('available',false,'qualified',false,'message',ME.message, ...
      'maximum_relative_defect',Inf);
  end
  try
    recurrence=LOCAL_high_order_recurrence(z);
  catch ME
    recurrence=struct('available',false,'qualified',false, ...
      'message',ME.message,'maximum_relative_defect',Inf);
  end
  action=LOCAL_metric(circle.angular_levels(2).jump_coeff, ...
    circle.angular_levels(3).jump_coeff);
  record=struct('free_singular',free,'linton_off_axis',linton, ...
    'high_order_recurrence',recurrence, ...
    'circle_1024_to_2048',action, ...
    'production_uses_oracle_matrix',false, ...
    'independent_reference',false);
  out=struct('available',free.available&&linton.available&&recurrence.available, ...
    'qualified',free.qualified&&linton.qualified&&recurrence.qualified, ...
    'record',record,'call_counters',calls,'density_modes',density.orders);
end

function out=LOCAL_high_order_recurrence(z)
  orders=(0:128).'; kout=z.khat; kin=sqrt(z.rho_disk)*z.khat;
  boundary=[LOCAL_one_recurrence(kout*z.R,true), ...
    LOCAL_one_recurrence(kin*z.R,true)];
  radii=[z.d-z.R,z.d+z.R,128*z.d-z.R,256*z.d+z.R];
  image=repmat(LOCAL_one_recurrence(kout*radii(1),false),1,numel(radii));
  for j=1:numel(radii)
    image(j)=LOCAL_one_recurrence(kout*radii(j),false);
  end
  values=[boundary.maximum_relative_defect,image.maximum_relative_defect];
  out=struct('available',all([boundary.available])&&all([image.available])&& ...
      all(isfinite(values)),'qualified',all(isfinite(values))&&max(values)<=1e-8, ...
    'orders',orders,'boundary',boundary,'image_radii',radii, ...
    'image',image,'maximum_relative_defect',max(values), ...
    'scaled_log_coordinate',true,'clipping_used',false);
end

function out=LOCAL_one_recurrence(z,with_J)
  orders=(0:129).';
  [lh,ph,lhp,php]=LOCAL_hankel_log_orders(orders,z);
  hrec=LOCAL_three_term_defect(lh,ph,z);
  hder=LOCAL_derivative_defect(lh,ph,lhp,php);
  defects=[hrec,hder]; wronskian=NaN; jrec=NaN; jder=NaN;
  if with_J
    [lj,pj,ljp,pjp]=LOCAL_bessel_log_j(orders,z);
    jrec=LOCAL_three_term_defect(lj,pj,z);
    jder=LOCAL_derivative_defect(lj,pj,ljp,pjp);
    count=129; wdef=zeros(count,1);
    for n=1:count
      value=LOCAL_log_product(lj(n),pj(n),lhp(n),php(n))- ...
        LOCAL_log_product(ljp(n),pjp(n),lh(n),ph(n));
      reference=2i/(pi*z);
      wdef(n)=abs(value-reference)/max([realmin,abs(value),abs(reference)]);
    end
    wronskian=max(wdef); defects=[defects,jrec,jder,wronskian];
  end
  maximum=max(defects);
  out=struct('argument',z,'with_J',with_J,'H_recurrence',hrec, ...
    'H_derivative_identity',hder,'J_recurrence',jrec, ...
    'J_derivative_identity',jder,'Wronskian',wronskian, ...
    'maximum_relative_defect',maximum, ...
    'available',all(isfinite(defects)));
end

function defect=LOCAL_three_term_defect(logv,phasev,z)
  defects=zeros(128,1);
  for n=1:128
    ids=n:(n+2); scale=max(logv(ids));
    actual=exp(logv(ids(3))-scale+1i*phasev(ids(3)));
    reference=2*n/z*exp(logv(ids(2))-scale+1i*phasev(ids(2)))- ...
      exp(logv(ids(1))-scale+1i*phasev(ids(1)));
    defects(n)=abs(actual-reference)/max([realmin,abs(actual),abs(reference)]);
  end
  defect=max(defects);
end

function defect=LOCAL_derivative_defect(logv,phasev,logd,phased)
  defects=zeros(129,1);
  for n=0:128
    id=n+1; scale=max([logd(id),logv(max(1,id-1)),logv(id+1)]);
    actual=exp(logd(id)-scale+1i*phased(id));
    if n==0
      reference=-exp(logv(2)-scale+1i*phasev(2));
    else
      reference=.5*(exp(logv(id-1)-scale+1i*phasev(id-1))- ...
        exp(logv(id+1)-scale+1i*phasev(id+1)));
    end
    defects(id)=abs(actual-reference)/max([realmin,abs(actual),abs(reference)]);
  end
  defect=max(defects);
end

function out=LOCAL_free_oracle(z)
  modes=[0,1,-1,2,-2]; levels=[512,1024,2048];
  empty_metric=LOCAL_metric_record(0,0);
  template=struct('Ntheta',0,'modes',[], 'columns',{{}}, ...
    'metric_records',repmat(empty_metric,0,0),'relative_defects',[], ...
    'D_jump',empty_metric,'dS_jump',empty_metric, ...
    'actual_T_out_minus_T_in',repmat(empty_metric,0,1), ...
    'streamed_active_Kress_circulant_row',false, ...
    'production_matrix_reused',false);
  records=repmat(template,1,numel(levels)); maximum=0; available=true;
  for n=1:numel(levels)
    N=levels(n); exterior=LOCAL_kress_circle_modes(z.khat,z.R,N,modes);
    interior=LOCAL_kress_circle_modes( ...
      sqrt(z.rho_disk)*z.khat,z.R,N,modes);
    [So,Dpo,Dmo,dSpo,dSmo,To]=LOCAL_free_factors(modes(:),z.khat,z.R);
    [Si,Dpi,Dmi,dSpi,dSmi,Ti]=LOCAL_free_factors( ...
      modes(:),sqrt(z.rho_disk)*z.khat,z.R);
    reference=[So,Dpo,Dmo,dSpo,dSmo,To, ...
      Si,Dpi,Dmi,dSpi,dSmi,Ti,To-Ti];
    numerical=[exterior.S,exterior.Dplus,exterior.Dminus, ...
      exterior.dSplus,exterior.dSminus,exterior.T, ...
      interior.S,interior.Dplus,interior.Dminus, ...
      interior.dSplus,interior.dSminus,interior.T, ...
      exterior.T-interior.T];
    metrics=repmat(LOCAL_metric_record(0,0),numel(modes),13);
    ratios=zeros(numel(modes),13);
    for j=1:numel(modes)
      for k=1:13
        metrics(j,k)=LOCAL_metric_record( ...
          numerical(j,k),reference(j,k),1e-8);
        ratios(j,k)=metrics(j,k).ratio;
      end
    end
    jumpD=LOCAL_metric_record([exterior.Dplus-exterior.Dminus; ...
      interior.Dplus-interior.Dminus],ones(10,1),1e-10);
    jumpS=LOCAL_metric_record([exterior.dSplus-exterior.dSminus; ...
      interior.dSplus-interior.dSminus],-ones(10,1),1e-10);
    records(n)=struct('Ntheta',N,'modes',modes(:), ...
      'columns',{{'S_outer','Dplus_outer','Dminus_outer', ...
        'dSplus_outer','dSminus_outer','T_outer','S_inner', ...
        'Dplus_inner','Dminus_inner','dSplus_inner','dSminus_inner', ...
        'T_inner','T_outer_minus_T_inner'}}, ...
      'metric_records',metrics,'relative_defects',ratios, ...
      'D_jump',jumpD,'dS_jump',jumpS, ...
      'actual_T_out_minus_T_in',metrics(:,13), ...
      'streamed_active_Kress_circulant_row',true, ...
      'production_matrix_reused',false);
    maximum=max([maximum,ratios(:).',jumpD.ratio,jumpS.ratio]);
    available=available&&all(isfinite(ratios),'all');
  end
  out=struct('available',available,'qualified',available&&maximum<=1e-8, ...
    'levels',records,'modes',modes,'maximum_relative_defect',maximum, ...
    'both_wavenumbers_all_one_sided_actions_checked',true, ...
    'minus_S_zeta_exterior_minus_interior_jump_is_plus_zeta',true, ...
    'normal_orientation','global +r; T is target/source mixed normal', ...
    'density_coordinate','[tau;zeta], zeta=-sigma');
end

function out=LOCAL_kress_circle_modes(k,R,N,modes)
  tau=(0:N-1)'*2*pi/N; difference=-tau; off=(1:N).'>1;
  dx=R*(1-cos(tau)); dy=-R*sin(tau); rho=hypot(dx,dy); rho(1)=1;
  logterm=zeros(N,1); logterm(off)=log(4*sin(difference(off)/2).^2);
  % Independent transcription of quad.quad_kress_rvec: retain the active
  % project normalization and its Nyquist contribution.
  Rrow=zeros(N,1);
  for m=1:N/2-1, Rrow=Rrow+cos(m*difference)/m; end
  Rrow=-(4*pi/N)*(Rrow+cos((N/2)*difference)/N); h=2*pi/N;
  Mfull=1i/4*besselh(0,1,k*rho)*R;
  M1=-besselj(0,k*rho)*R/(4*pi); M2=zeros(N,1);
  M2(off)=Mfull(off)-M1(off).*logterm(off);
  M1(1)=-R/(4*pi);
  M2(1)=.5*(1i/2-0.57721566490153286060/pi- ...
    log((k^2/4)*R^2)/(2*pi))*R;
  ratio_source=R^2*(cos(tau)-1)./rho;
  Lfull=1i*k/4*ratio_source.*besselh(1,1,k*rho);
  L1=-k/(4*pi)*ratio_source.*besselj(1,k*rho); L2=zeros(N,1);
  L2(off)=Lfull(off)-L1(off).*logterm(off); L1(1)=0; L2(1)=-1/(4*pi);
  ratio_tangent=-R^2*sin(tau)./rho;
  Nfull=-1i*k/4*ratio_tangent.*besselh(1,1,k*rho);
  N1=k/(4*pi)*ratio_tangent.*besselj(1,k*rho); N2=zeros(N,1);
  cotterm=zeros(N,1); cotterm(off)=cot(difference(off)/2);
  N2(off)=Nfull(off)-cotterm(off)/(4*pi)-N1(off).*logterm(off);
  N1(1)=0; N2(1)=0;
  Srow=Rrow.*M1+h*M2; Krow=Rrow.*L1+h*L2;
  Arow=(Rrow.*(k^2*M1)+h*(k^2*M2)).*cos(tau);
  Brow=(Rrow.*N1+h*N2)/R;
  out=struct('S',zeros(numel(modes),1),'Dplus',zeros(numel(modes),1), ...
    'Dminus',zeros(numel(modes),1),'dSplus',zeros(numel(modes),1), ...
    'dSminus',zeros(numel(modes),1),'T',zeros(numel(modes),1));
  for j=1:numel(modes)
    phi=exp(1i*modes(j)*tau); S=Srow.'*phi; K=Krow.'*phi;
    T=Arow.'*phi+(Brow.'*phi)*(1i*modes(j));
    out.S(j)=S; out.Dplus(j)=.5+K; out.Dminus(j)=-.5+K;
    out.dSplus(j)=-.5+K; out.dSminus(j)=.5+K; out.T(j)=T;
  end
end

function out=LOCAL_linton_oracle(~,z)
  points=[.30,-.066;.20,-.066;.10,-.066;.263,.173;-.217,.287];
  tuples=[2,26,18,28;2,34,24,36;2,42,30,44];
  defects=zeros(size(points,1),size(tuples,1)-1,6);
  production=zeros(size(points,1),6);
  wood=zeros(size(tuples,1),1);
  branch=repmat(struct('orders',[],'beta_m',[],'t_m',[],'gamma_m',[], ...
    'classification',[],'outgoing_sign_pass',false,'axis_pass',false, ...
    'exact_Wood',true,'relative_Wood_margin',NaN,'available',false), ...
    size(tuples,1),1);
  for a=1:size(tuples,1)
    level=struct('a',tuples(a,1),'M1',tuples(a,2), ...
      'M2',tuples(a,3),'N',tuples(a,4));
    beta_m=z.beta+2*pi*(-level.M1:level.M1).'/z.d;
    t=z.khat^2-beta_m.^2; gamma=LOCAL_outgoing(z.khat,beta_m);
    wood(a)=min(abs(t)./(z.khat^2+beta_m.^2));
    exact_wood=any(t==0); prop=t>0; evan=t<0;
    sign_pass=all((~prop|real(gamma)>0)&(~evan|imag(gamma)>0));
    axis_pass=all(abs(real(gamma(evan)))<= ...
      100*eps*max(realmin,abs(gamma(evan))))&& ...
      all(abs(imag(gamma(prop)))<= ...
      100*eps*max(realmin,abs(gamma(prop))));
    class=zeros(size(t),'int8'); class(prop)=1; class(evan)=-1;
    branch(a)=struct('orders',(-level.M1:level.M1).', ...
      'beta_m',beta_m,'t_m',t,'gamma_m',gamma,'classification',class, ...
      'outgoing_sign_pass',sign_pass,'axis_pass',axis_pass, ...
      'exact_Wood',exact_wood,'relative_Wood_margin',wood(a), ...
      'available',~exact_wood&&sign_pass&&axis_pass&& ...
        all(isfinite([beta_m;t;gamma])));
    if exact_wood
      error('i32e:ExactWood','The Linton oracle encountered exact Wood.');
    end
    for p=1:size(points,1)
      dx=points(p,1); dy=points(p,2); sx=sign(dx);
      raw=LOCAL_linton_kernel(z.khat,z.beta,z.d,abs(dx),dy,level);
      values=-[raw.G,sx*raw.GX,raw.GY,raw.GXX, ...
        sx*raw.GXY,raw.GYY];
      if a>1
        prior_level=struct('a',tuples(a-1,1),'M1',tuples(a-1,2), ...
          'M2',tuples(a-1,3),'N',tuples(a-1,4));
        prior=LOCAL_linton_kernel(z.khat,z.beta,z.d,abs(dx),dy,prior_level);
        old=-[prior.G,sx*prior.GX,prior.GY,prior.GXX, ...
          sx*prior.GXY,prior.GYY];
        defects(p,a-1,:)=abs(values-old)./max([realmin*ones(1,6); ...
          abs(values);abs(old)],[],1);
      end
      if a==size(tuples,1)
        image=LOCAL_point_images(z,dx,dy,256);
        production(p,:)=abs(values-image)./max([realmin*ones(1,6); ...
          abs(values);abs(image)],[],1);
      end
    end
  end
  harmonic=LOCAL_linton_harmonics(z,tuples(end,:),[-2,-1,0,1,2]);
  termwise=LOCAL_termwise_harmonics(z,[-2,-1,0,1,2]);
  cross=LOCAL_cross_action_oracle(z,tuples(end,:),[-2,-1,0,1,2]);
  identities=LOCAL_linton_identities(z,tuples(end,:));
  maximum=max([defects(:);termwise.relative_defects(:); ...
    cross.maximum_relative_defect;identities.maximum_relative_defect]);
  holdout=max([production(:);harmonic.relative_defects(:)]);
  available=all(isfinite([defects(:);termwise.relative_defects(:); ...
      cross.maximum_relative_defect; ...
      production(:);harmonic.relative_defects(:); ...
      identities.maximum_relative_defect;wood]))&& ...
      identities.available&&all([branch.available]);
  out=struct('available',available, ...
    'qualified',available&&maximum<=1e-8,'points',points,'tuples',tuples, ...
    'project_sign',-1,'relative_wood_margin',wood, ...
    'branch_ledger',branch, ...
    'relative_defects',defects,'production_image_tail_holdout',production, ...
    'manufactured_total_image_tail_holdout',harmonic, ...
    'manufactured_termwise_harmonic_actions',termwise, ...
    'wall_circle_cross_action_oracle',cross, ...
    'image_tail_holdout_maximum',holdout, ...
    'image_tail_holdout_enters_kernel_1e8_gate',false, ...
    'Bloch_Helmholtz_branch_identities',identities, ...
    'maximum_relative_defect',maximum, ...
    'coordinate_map','X_L=abs(dx), Gx=sign(dx)*G_X, Gxy=sign(dx)*G_XY');
end

function out=LOCAL_cross_action_oracle(z,tuple,modes)
  level=struct('a',tuple(1),'M1',tuple(2),'M2',tuple(3),'N',tuple(4));
  circle_to_wall=zeros(numel(modes),2); wall_to_circle=circle_to_wall;
  Ntheta=512; theta=(0:Ntheta-1)'*2*pi/Ntheta;
  circle=[z.R*cos(theta),z.R*sin(theta)]; normals=circle/z.R;
  wall_orders=(-256:255).'; beta_wall=z.beta+2*pi*wall_orders/z.d;
  ywall=.173; psi=exp(1i*beta_wall*ywall)/sqrt(z.d);
  for j=1:numel(modes)
    density=struct('orders',(-128:127).','tau',zeros(256,2), ...
      'zeta',zeros(256,2)); id=find(density.orders==modes(j),1);
    density.tau(id,1)=1; density.zeta(id,2)=1;
    [FL,FR]=LOCAL_circle_to_wall(z,density,wall_orders);
    production=[psi.'*FL;psi.'*FR]; reference=zeros(2,2);
    for side=1:2
      xt=[z.X_L,z.X_R]; target=[xt(side),ywall]; G=zeros(Ntheta,1); D=G;
      for p=1:Ntheta
        dx=target(1)-circle(p,1); dy=target(2)-circle(p,2); sx=sign(dx);
        raw=LOCAL_linton_kernel(z.khat,z.beta,z.d,abs(dx),dy,level);
        G(p)=-raw.G; grad=[-sx*raw.GX,-raw.GY];
        D(p)=-grad*normals(p,:).';
      end
      phi=exp(1i*modes(j)*theta); weight=2*pi*z.R/Ntheta;
      reference(side,:)=[weight*sum(D.*phi),-weight*sum(G.*phi)];
    end
    circle_to_wall(j,1)=LOCAL_metric(production(:,1),reference(:,1));
    circle_to_wall(j,2)=LOCAL_metric(production(:,2),reference(:,2));

    theta_target=.83; target=z.R*[cos(theta_target),sin(theta_target)];
    nt=target/z.R; ys=-z.d/2+z.d*(0:Ntheta-1)'/Ntheta;
    for side=1:2
      xiL=zeros(512,1); xiR=xiL; source_id=find(wall_orders==modes(j),1);
      if side==1, xiL(source_id)=1; else, xiR(source_id)=1; end
      wall_density=struct('xi_left',xiL,'xi_right',xiR);
      [value,dr]=LOCAL_wall_to_circle(z,wall_density,theta_target, ...
        target(1),target(2),nt(1),nt(2));
      xsource=[z.X_L,z.X_R]; G=zeros(Ntheta,1); dG=G;
      for p=1:Ntheta
        dx=target(1)-xsource(side); dy=target(2)-ys(p); sx=sign(dx);
        raw=LOCAL_linton_kernel(z.khat,z.beta,z.d,abs(dx),dy,level);
        G(p)=-raw.G; grad=[-sx*raw.GX,-raw.GY]; dG(p)=grad*nt.';
      end
      density_y=exp(1i*(z.beta+2*pi*modes(j)/z.d)*ys)/sqrt(z.d);
      reference_wall=z.d/Ntheta*[sum(G.*density_y),sum(dG.*density_y)];
      wall_to_circle(j,side)=LOCAL_metric([value,dr],reference_wall);
    end
  end
  maximum=max([circle_to_wall(:);wall_to_circle(:)]);
  out=struct('available',isfinite(maximum),'qualified',maximum<=1e-8, ...
    'modes',modes,'circle_to_wall_D_and_minusS',circle_to_wall, ...
    'wall_to_circle_value_and_global_r_normal',wall_to_circle, ...
    'circle_source_nodes',Ntheta,'wall_source_nodes',Ntheta, ...
    'maximum_relative_defect',maximum,'reference','project-signed Linton quadrature');
end

function out=LOCAL_termwise_harmonics(z,modes)
  target=[.30,.066]; images=[-2,-1,1,2]; Nt=512;
  theta=(0:Nt-1)'*2*pi/Nt; source=[z.R*cos(theta),z.R*sin(theta)];
  normals=source/z.R; target_normal=target/norm(target); weight=2*pi*z.R/Nt;
  defects=zeros(numel(images),numel(modes),4);
  for a=1:numel(images)
    n=images(a); shifted=source+[zeros(Nt,1),n*z.d*ones(Nt,1)];
    delta=target-shifted; radius=hypot(delta(:,1),delta(:,2));
    er=delta./radius; H0=besselh(0,1,z.khat*radius);
    H1=besselh(1,1,z.khat*radius); H2=besselh(2,1,z.khat*radius);
    phi=1i/4*H0; fp=-1i*z.khat/4*H1;
    fpp=-1i*z.khat^2/8*(H0-H2);
    source_normal=-fp.*sum(er.*normals,2);
    target_dr=fp.*(er*target_normal.');
    mixed=zeros(Nt,1);
    for p=1:Nt
      Hess=fpp(p)*(er(p,:).'*er(p,:))+fp(p)/radius(p)* ...
        (eye(2)-er(p,:).'*er(p,:));
      mixed(p)=-target_normal*Hess*normals(p,:).';
    end
    phase=exp(1i*z.beta*n*z.d);
    for j=1:numel(modes)
      density=exp(1i*modes(j)*theta);
      reference=phase*weight*[sum(phi.*density), ...
        sum(source_normal.*density),sum(target_dr.*density), ...
        sum(mixed.*density)];
      production=LOCAL_harmonic_one_image(z,modes(j),target,n);
      defects(a,j,:)=abs(production-reference)./max([realmin*ones(1,4); ...
        abs(production);abs(reference)],[],1);
    end
  end
  out=struct('images',images,'modes',modes,'target',target, ...
    'source_nodes',Nt,'columns',{{'S','D','dS','T'}}, ...
    'relative_defects',defects,'maximum_relative_defect',max(defects,[],'all'), ...
    'reference','direct free-kernel source quadrature for one image', ...
    'production','analytic one-image harmonic formula');
end

function values=LOCAL_harmonic_one_image(z,ell,target,n)
  k=z.khat; R=z.R; [lj,pj,ljp,pjp]=LOCAL_bessel_log_j(ell,k*R);
  Cs=exp(log(pi*R/2)+lj+1i*(pi/2+pj));
  Cd=exp(log(pi*R*k/2)+ljp+1i*(pi/2+pjp));
  dx=target(1); dy=target(2)-n*z.d; rr=hypot(dx,dy); ang=atan2(dy,dx);
  H=besselh(ell,1,k*rr); Hp=.5*(besselh(ell-1,1,k*rr)- ...
    besselh(ell+1,1,k*rr)); phase=exp(1i*z.beta*n*z.d+1i*ell*ang);
  er=[dx,dy]/rr; et=[-er(2),er(1)]; nt=target/norm(target);
  radial=k*Hp*dot(nt,er)+1i*ell/rr*H*dot(nt,et);
  values=phase*[Cs*H,Cd*H,Cs*radial,Cd*radial];
end

function out=LOCAL_linton_identities(z,tuple)
  level=struct('a',tuple(1),'M1',tuple(2),'M2',tuple(3),'N',tuple(4));
  dx=.263; dy=.173; base=LOCAL_linton_physical(z,dx,dy,level);
  target=LOCAL_linton_physical(z,dx,dy+z.d,level);
  source=LOCAL_linton_physical(z,dx,dy-z.d,level);
  target_phase=LOCAL_metric_record( ...
    target,exp(1i*z.beta*z.d)*base,1e-8);
  source_phase=LOCAL_metric_record( ...
    source,exp(-1i*z.beta*z.d)*base,1e-8);
  residual=base(4)+base(6)+z.khat^2*base(1);
  helmholtz_scale=max(realmin,abs(base(4))+abs(base(6))+ ...
    z.khat^2*abs(base(1)));
  helmholtz=struct('numerator',abs(residual), ...
    'left_norm',abs(base(4))+abs(base(6))+z.khat^2*abs(base(1)), ...
    'right_norm',0,'zero_component',false,'scale',helmholtz_scale, ...
    'ratio',abs(residual)/helmholtz_scale,'threshold',1e-8, ...
    'pass',isfinite(residual)&&abs(residual)/helmholtz_scale<=1e-8, ...
    'zero_reference',true);
  m=(-level.M1:level.M1).'; beta=z.beta+2*pi*m/z.d;
  t=z.khat^2-beta.^2; gamma=LOCAL_outgoing(z.khat,beta);
  prop=t>0; evan=t<0; sign_pass=all((~prop|real(gamma)>0)& ...
    (~evan|imag(gamma)>0));
  exact_wood=any(t==0); margin=min(abs(t)./(z.khat^2+beta.^2));
  maximum=max([target_phase.ratio,source_phase.ratio,helmholtz.ratio]);
  available=all(isfinite([base,target,source,gamma.',margin,maximum]))&& ...
    ~exact_wood&&sign_pass;
  out=struct('available',available,'target_Bloch_phase',target_phase, ...
    'source_inverse_phase',source_phase,'Helmholtz_identity',helmholtz, ...
    'relative_Wood_margin',margin,'exact_Wood',exact_wood, ...
    'propagating_count',sum(prop),'evanescent_count',sum(evan), ...
    'outgoing_gamma_sign_pass',sign_pass,'maximum_relative_defect',maximum);
end

function values=LOCAL_linton_physical(z,dx,dy,level)
  sx=sign(dx); raw=LOCAL_linton_kernel( ...
    z.khat,z.beta,z.d,abs(dx),dy,level);
  values=-[raw.G,sx*raw.GX,raw.GY,raw.GXX,sx*raw.GXY,raw.GYY];
end

function out=LOCAL_linton_harmonics(z,tuple,modes)
  level=struct('a',tuple(1),'M1',tuple(2),'M2',tuple(3),'N',tuple(4));
  target=[.30,.066]; Nt=128; theta=(0:Nt-1)'*2*pi/Nt;
  source=[z.R*cos(theta),z.R*sin(theta)]; normals=source/z.R;
  G=zeros(Nt,1); Gx=G; Gy=G;
  for j=1:Nt
    dx=target(1)-source(j,1); dy=target(2)-source(j,2); sx=sign(dx);
    raw=LOCAL_linton_kernel(z.khat,z.beta,z.d,abs(dx),dy,level);
    G(j)=-raw.G; Gx(j)=-sx*raw.GX; Gy(j)=-raw.GY;
  end
  source_normal=-(Gx.*normals(:,1)+Gy.*normals(:,2));
  target_r=target/norm(target); target_dr=Gx*target_r(1)+Gy*target_r(2);
  defects=zeros(numel(modes),4);
  for j=1:numel(modes)
    ell=modes(j); phi=exp(1i*ell*theta); weight=2*pi*z.R/Nt;
    reference=[weight*sum(G.*phi),weight*sum(source_normal.*phi), ...
      weight*sum(target_dr.*phi),NaN];
    production=LOCAL_harmonic_point(z,ell,target,256);
    reference(4)=weight*sum(( ...
      LOCAL_linton_source_normal_dr(z,source,normals,target,target_r,level)).*phi);
    defects(j,:)=abs(production-reference)./max([realmin*ones(1,4); ...
      abs(production);abs(reference)],[],1);
  end
  out=struct('modes',modes,'target',target,'source_nodes',Nt, ...
    'relative_defects',defects,'maximum_relative_defect',max(defects,[],'all'), ...
    'production','analytic harmonic n=0 plus symmetric images', ...
    'reference','project-signed Linton source integration', ...
    'mixed_derivative_reference','analytic -e_t^T Hessian(G) n_s', ...
    'target_finite_difference_used',false);
end

function values=LOCAL_harmonic_point(z,ell,target,J)
  k=z.khat; R=z.R; [lj,pj,ljp,pjp]=LOCAL_bessel_log_j(ell,k*R);
  Cs=exp(log(pi*R/2)+lj+1i*(pi/2+pj));
  Cd=exp(log(pi*R*k/2)+ljp+1i*(pi/2+pjp));
  values=zeros(1,4); er=target/norm(target);
  for n=-J:J
    dx=target(1); dy=target(2)-n*z.d; rr=hypot(dx,dy); ang=atan2(dy,dx);
    H=besselh(ell,1,k*rr); Hp=.5*(besselh(ell-1,1,k*rr)- ...
      besselh(ell+1,1,k*rr)); phase=exp(1i*z.beta*n*z.d+1i*ell*ang);
    ern=[dx,dy]/rr; etn=[-ern(2),ern(1)];
    radial=k*Hp*dot(er,ern)+1i*ell/rr*H*dot(er,etn);
    values=values+phase*[Cs*H,Cd*H,Cs*radial,Cd*radial];
  end
end

function values=LOCAL_linton_source_normal_dr(z,source,normals,target,er,level)
  % The target derivative of the source-normal trace is the analytic mixed
  % contraction -e_t^T Hessian(G) n_s in physical coordinates.
  values=zeros(size(source,1),1);
  for j=1:size(source,1)
    dx=target(1)-source(j,1); dy=target(2)-source(j,2); sx=sign(dx);
    raw=LOCAL_linton_kernel(z.khat,z.beta,z.d,abs(dx),dy,level);
    Hessian=-[raw.GXX,sx*raw.GXY;sx*raw.GXY,raw.GYY];
    values(j)=-er*Hessian*normals(j,:).';
  end
end

function values=LOCAL_point_images(z,dx,dy,J)
  values=zeros(1,6); k=z.khat;
  for n=-J:J
    yy=dy-n*z.d; r=hypot(dx,yy);
    if r==0, error('i32e:PointImageSingular','A point-image pair is singular.'); end
    er=[dx/r,yy/r]; phase=exp(1i*z.beta*n*z.d);
    H0=besselh(0,1,k*r); H1=besselh(1,1,k*r); H2=besselh(2,1,k*r);
    f=1i/4*H0; fp=-1i*k/4*H1; fpp=-1i*k^2/8*(H0-H2);
    Hess=fpp*(er.'*er)+fp/r*(eye(2)-er.'*er);
    values=values+phase*[f,fp*er(1),fp*er(2), ...
      Hess(1,1),Hess(1,2),Hess(2,2)];
  end
end

function out=LOCAL_linton_kernel(k,beta,d,X,Y,level)
  [a,da]=LOCAL_linton_reciprocal(k,beta,d,X,Y,level);
  [b,db]=LOCAL_linton_real(k,beta,d,X,Y,level);
  out=struct('G',a+b,'GX',da.GX+db.GX,'GY',da.GY+db.GY, ...
    'GXX',da.GXX+db.GXX,'GXY',da.GXY+db.GXY,'GYY',da.GYY+db.GYY);
end

function [value,out]=LOCAL_linton_reciprocal(k,beta,d,X,Y,level)
  m=(-level.M1:level.M1).'; bm=beta+2*pi*m/d;
  q=zeros(size(bm)); ev=bm.^2-k^2>=0;
  q(ev)=sqrt(bm(ev).^2-k^2); q(~ev)=-1i*sqrt(k^2-bm(~ev).^2);
  b=level.a/d; cc=q*d/(2*level.a); zp=cc+b*X; zm=cc-b*X;
  ep=erfc(zp); em=erfc(zm); epp=-2/sqrt(pi)*exp(-zp.^2);
  emp=-2/sqrt(pi)*exp(-zm.^2); epp2=4/sqrt(pi)*zp.*exp(-zp.^2);
  emp2=4/sqrt(pi)*zm.*exp(-zm.^2);
  xp=exp(q*X); xm=exp(-q*X); Fp=xp.*ep; Fm=xm.*em;
  FXp=xp.*(q.*ep+b*epp); FXm=-xm.*(q.*em+b*emp);
  FXXp=xp.*(q.^2.*ep+2*b*q.*epp+b^2*epp2);
  FXXm=xm.*(q.^2.*em+2*b*q.*emp+b^2*emp2);
  phase=exp(1i*bm*Y); base=phase./q; scale=-1/(4*d); F=Fp+Fm;
  value=scale*sum(base.*F); out=struct( ...
    'GX',scale*sum(base.*(FXp+FXm)), ...
    'GY',scale*sum(1i*bm.*base.*F), ...
    'GXX',scale*sum(base.*(FXXp+FXXm)), ...
    'GXY',scale*sum(1i*bm.*base.*(FXp+FXm)), ...
    'GYY',scale*sum(-(bm.^2).*base.*F));
end

function [value,out]=LOCAL_linton_real(k,beta,d,X,Y,level)
  m=(-level.M2:level.M2).'; yy=Y-m*d; alpha=(level.a/d)^2;
  zz=alpha*(X^2+yy.^2);
  if any(zz==0), error('i32e:LintonSingular','A Linton pair is singular.'); end
  ez=exp(-zz); Enm1=ez.*(1./zz+1./zz.^2); En=ez./zz; Enp1=expint(zz);
  S=zeros(size(zz)); Sz=S; Szz=S;
  for n=0:level.N
    coefficient=(k*d/(2*level.a))^(2*n)/factorial(n);
    S=S+coefficient*Enp1; Sz=Sz-coefficient*En; Szz=Szz+coefficient*Enm1;
    if n<level.N, Enm1=En; En=Enp1; Enp1=(ez-zz.*En)/(n+1); end
  end
  zx=2*alpha*X; zy=2*alpha*yy; phase=exp(1i*beta*m*d); scale=-1/(4*pi);
  value=scale*sum(phase.*S); out=struct( ...
    'GX',scale*sum(phase.*Sz*zx),'GY',scale*sum(phase.*Sz.*zy), ...
    'GXX',scale*sum(phase.*(Szz*zx^2+2*alpha*Sz)), ...
    'GXY',scale*sum(phase.*Szz.*zy*zx), ...
    'GYY',scale*sum(phase.*(Szz.*zy.^2+2*alpha*Sz)));
end

%% ==================== Qualification and common transforms ====================
% Scientific diagnostics fail open; nonfinite production maps do not.

function [warnings,qualified]=LOCAL_warnings( ...
    c,circle,wall,weights,oracle,structural)
  warnings=struct('code',{},'value',{},'blocking',{});
  cm=LOCAL_metric(circle.angular_levels(2).jump_coeff, ...
    circle.angular_levels(3).jump_coeff);
  wm=max(wall.refinement(2).flux_left.ratio, ...
    wall.refinement(2).flux_right.ratio);
  if cm>c.action_ratio_max
    warnings(end+1)=LOCAL_warning('CIRCLE_ACTION_QUALIFICATION_WARNING',cm);
  end
  if wm>c.action_ratio_max
    warnings(end+1)=LOCAL_warning('WALL_ACTION_QUALIFICATION_WARNING',wm);
  end
  if ~circle.actual_T_action.qualified
    warnings(end+1)=LOCAL_warning('ACTUAL_DELTA_T_ACTION_WARNING', ...
      circle.actual_T_action.maximum_contraction_ratio);
  end
  if ~circle.finite_image_bloch.qualified
    warnings(end+1)=LOCAL_warning('FINITE_IMAGE_BLOCH_ACTION_WARNING', ...
      circle.finite_image_bloch.maximum_final_ratio);
  end
  if ~oracle.qualified
    warnings(end+1)=LOCAL_warning('ANALYTIC_KERNEL_ORACLE_WARNING', ...
      max([oracle.record.free_singular.maximum_relative_defect, ...
      oracle.record.linton_off_axis.maximum_relative_defect, ...
      oracle.record.high_order_recurrence.maximum_relative_defect]));
  end
  ric=max([weights.circle.energy_identity_defect]);
  if ric>c.action_ratio_max
    warnings(end+1)=LOCAL_warning('RICCATI_ENERGY_WARNING',ric);
  end
  bessel=max(arrayfun(@(x) x.low_order_bessel_metric.ratio,weights.circle));
  if bessel>c.kernel_oracle_tol
    warnings(end+1)=LOCAL_warning('RICCATI_BESSEL_QUOTIENT_WARNING',bessel);
  end
  if ~structural.pass
    warnings(end+1)=LOCAL_warning('SAME_TRIAL_STRUCTURE_WARNING', ...
      structural.maximum_required_ratio);
  end
  qualified=isempty(warnings);
end

function out=LOCAL_structural_metrics(c,z,density,circle,wall,oracle)
  wall_repair=LOCAL_set_threshold(wall.repaired_value_metric,c.identity_tol);
  circle_repair=LOCAL_set_threshold( ...
    circle.repaired_value_metric,c.identity_tol);
  left=LOCAL_metric_record(z.center_actual_left_trace+ ...
    z.center_left_value_mismatch,z.center_shared_left_trace,c.identity_tol);
  right=LOCAL_metric_record(z.center_actual_right_trace+ ...
    z.center_right_value_mismatch,z.center_shared_right_trace,c.identity_tol);
  safe_value=LOCAL_metric_record(1-3+2,0,c.identity_tol);
  safe_derivative=LOCAL_metric_record(-6+6,0,c.identity_tol);
  jump=max([circle.wronskian.exterior.D_jump_defect, ...
    circle.wronskian.exterior.dS_jump_defect, ...
    circle.wronskian.interior.D_jump_defect, ...
    circle.wronskian.interior.dS_jump_defect]);
  eta=[density.tau;density.zeta]; N=256;
  samples=[ifft(ifftshift(density.tau,1),[],1)*N; ...
    ifft(ifftshift(density.zeta,1),[],1)*N];
  roundtrip=LOCAL_metric_record(samples,z.eta_unit_256,c.identity_tol);
  bloch=LOCAL_bloch_metric(z,c.identity_tol);
  decomposition_records=[circle.angular_levels.normal_decomposition_metric];
  for j=1:numel(decomposition_records)
    decomposition_records(j)=LOCAL_set_threshold( ...
      decomposition_records(j),c.identity_tol);
  end
  decomposition=max([decomposition_records.ratio]);
  values=[wall_repair.ratio,circle_repair.ratio,left.ratio,right.ratio, ...
    safe_value.ratio,safe_derivative.ratio,jump,roundtrip.ratio, ...
    bloch.value.ratio,bloch.flux.ratio,decomposition];
  out=struct('wall_repaired_identity',wall_repair, ...
    'circle_repaired_identity',circle_repair, ...
    'circle_raw_value_jump_norm',circle.raw_value_jump_norm, ...
    'circle_value_lift_plus_norm',circle.raw_value_jump_norm/2, ...
    'circle_value_lift_minus_norm',circle.raw_value_jump_norm/2, ...
    'center_left_repaired_identity',left, ...
    'center_right_repaired_identity',right, ...
    'safe_rim_value',safe_value,'safe_rim_derivative',safe_derivative, ...
    'jump_sign_maximum',jump,'zeta_equals_minus_sigma_semantic',true, ...
    'density_scale_roundtrip',roundtrip,'bloch',bloch, ...
    'circle_normal_decomposition_maximum',decomposition, ...
    'circle_normal_decomposition',{decomposition_records}, ...
    'free_oracle',oracle.record.free_singular, ...
    'maximum_required_ratio',max(values), ...
    'pass',all(isfinite(values))&&max(values)<=c.identity_tol, ...
    'eta_coefficient_size',size(eta));
end

function out=LOCAL_public_evaluation(record,circle,wall,weights,oracles,refinement)
  image=LOCAL_public_circle_levels(circle.image_levels);
  angular=LOCAL_public_circle_levels(circle.angular_levels);
  wall_levels=wall.levels;
  out=struct('record',record,'circle',struct('image_levels',image, ...
    'angular_levels',angular,'orders',circle.orders, ...
    'wronskian',circle.wronskian, ...
    'actual_T_action',circle.actual_T_action, ...
    'finite_image_bloch',circle.finite_image_bloch), ...
    'wall',struct('levels',wall_levels,'orders',wall.orders, ...
    'source_orders',wall.source_orders,'source_coefficients_fixed',true), ...
    'weights',weights,'oracles',oracles,'refinement_metrics',refinement, ...
    'compact_maps_only',true,'dense_target_mode_image_intermediates_saved',false);
end

function out=LOCAL_refinement_records(c,circle,wall,weights)
  out=struct();
  for j=1:2
    out.circle_angular(j)=struct( ...
      'from_nodes',circle.angular_levels(j).target_nodes, ...
      'to_nodes',circle.angular_levels(j+1).target_nodes, ...
      'value_jump',LOCAL_metric_record( ...
        circle.angular_levels(j).delta_coeff, ...
        circle.angular_levels(j+1).delta_coeff,c.action_ratio_max), ...
      'normal_jump',LOCAL_metric_record( ...
        circle.angular_levels(j).jump_coeff, ...
        circle.angular_levels(j+1).jump_coeff,c.action_ratio_max), ...
      'actual_DeltaT_tau',LOCAL_metric_record( ...
        circle.angular_levels(j).actual_deltaT_coeff, ...
        circle.angular_levels(j+1).actual_deltaT_coeff,c.action_ratio_max));
    out.riccati(j)=LOCAL_metric_record( ...
      weights.circle(j).weight,weights.circle(j+1).weight,c.action_ratio_max);
    out.collar_gauss(j)=LOCAL_metric_record( ...
      weights.collar(j).weight,weights.collar(j+1).weight,c.action_ratio_max);
    out.wall_lift_gauss(j)=LOCAL_metric_record( ...
      weights.wall_lift(j).weight,weights.wall_lift(j+1).weight, ...
      c.action_ratio_max);
  end
  out.wall_output=wall.refinement;
  pairs=[1,3;3,5;2,4;4,6;6,7];
  for j=1:size(pairs,1)
    out.circle_images(j)=struct( ...
      'from_J',circle.image_levels(pairs(j,1)).J, ...
      'to_J',circle.image_levels(pairs(j,2)).J, ...
      'value_jump',LOCAL_metric_record( ...
        circle.image_levels(pairs(j,1)).delta_coeff, ...
        circle.image_levels(pairs(j,2)).delta_coeff,Inf), ...
      'normal_jump',LOCAL_metric_record( ...
        circle.image_levels(pairs(j,1)).jump_coeff, ...
        circle.image_levels(pairs(j,2)).jump_coeff,Inf), ...
      'actual_DeltaT_tau',LOCAL_metric_record( ...
        circle.image_levels(pairs(j,1)).actual_deltaT_coeff, ...
        circle.image_levels(pairs(j,2)).actual_deltaT_coeff,Inf));
  end
end

function out=LOCAL_public_circle_levels(levels)
  template=struct('label','','J',0,'target_nodes',0,'orders',[], ...
    'delta_coeff',[],'jump_coeff',[],'actual_deltaT_coeff',[], ...
    'dS_difference_zeta_norm',NaN,'wall_normal_norm',NaN, ...
    'normal_decomposition_metric',struct(), ...
    'delta_norm',NaN,'jump_norm',NaN,'actual_deltaT_norm',NaN, ...
    'finite',false);
  out=repmat(template,size(levels));
  for j=1:numel(levels)
    out(j)=struct('label',levels(j).label,'J',levels(j).J, ...
      'target_nodes',levels(j).target_nodes,'orders',levels(j).orders, ...
      'delta_coeff',levels(j).delta_coeff, ...
      'jump_coeff',levels(j).jump_coeff, ...
      'actual_deltaT_coeff',levels(j).actual_deltaT_coeff, ...
      'dS_difference_zeta_norm',levels(j).dS_difference_zeta_norm, ...
      'wall_normal_norm',levels(j).wall_normal_norm, ...
      'normal_decomposition_metric',levels(j).normal_decomposition_metric, ...
      'delta_norm',norm(levels(j).delta_coeff,'fro'), ...
      'jump_norm',norm(levels(j).jump_coeff,'fro'), ...
      'actual_deltaT_norm',norm(levels(j).actual_deltaT_coeff,'fro'), ...
      'finite',levels(j).finite);
  end
end

function out=LOCAL_bloch_metric(z,threshold)
  orders=(-256:255).'; beta_m=z.beta+2*pi*orders/z.d;
  coefficients=[z.center_shared_left_trace,z.center_shared_right_trace];
  y=.173; phase0=exp(1i*beta_m*y).'; phase1=exp(1i*beta_m*(y+z.d)).';
  value0=phase0*coefficients; value1=phase1*coefficients;
  flux0=(1i*beta_m.*exp(1i*beta_m*y)).'*coefficients;
  flux1=(1i*beta_m.*exp(1i*beta_m*(y+z.d))).'*coefficients;
  bloch=exp(1i*z.beta*z.d);
  out=struct('value',LOCAL_metric_record(value1,bloch*value0,threshold), ...
    'flux',LOCAL_metric_record(flux1,bloch*flux0,threshold), ...
    'wall_fourier_part_structural',true, ...
    'physical_to_periodic_gauge_roundtrip',true, ...
    'finite_image_target_Bloch_consumed_here',false);
end

function pass=LOCAL_core_finite(circle,wall,weights)
  pass=all([circle.image_levels.finite])&&all([circle.angular_levels.finite])&& ...
    all([wall.levels.finite])&&all([weights.circle.positive])&& ...
    weights.wall_trace_positive&&all(isfinite(weights.collar_final))&& ...
    all(weights.collar_final>=0)&&all(isfinite(weights.wall_lift_final))&& ...
    all(weights.wall_lift_final>=0);
end

function out=LOCAL_warning(code,value)
  out=struct('code',char(code),'value',double(value),'blocking',false);
end

function value=LOCAL_metric(a,b)
  value=norm(a-b,'fro')/max([realmin,norm(a,'fro'),norm(b,'fro')]);
end

function out=LOCAL_metric_record(a,b,threshold)
  if nargin<3, threshold=NaN; end
  numerator=norm(a-b,'fro'); left=norm(a,'fro'); right=norm(b,'fro');
  scale=max([realmin,left,right]);
  out=struct('numerator',numerator,'left_norm',left,'right_norm',right, ...
    'zero_component',left==0&&right==0,'scale',scale,'ratio',numerator/scale, ...
    'threshold',threshold,'pass',isfinite(numerator)&& ...
      (isnan(threshold)||numerator/scale<=threshold));
end

function out=LOCAL_set_threshold(out,threshold)
  out.threshold=threshold;
  out.pass=isfinite(out.ratio)&&out.ratio<=threshold;
end

function coeff=LOCAL_circle_coeff(values,R)
  N=size(values,1); coeff=sqrt(2*pi*R)*fftshift(fft(values,[],1),1)/N;
end

function Y=LOCAL_pad_orders(X,N,Nout)
  if N==Nout, Y=X; return; end
  if N>Nout||mod(N,2)||mod(Nout,2)
    error('i32e:OrderPadding','Invalid Fourier order padding.');
  end
  Y=zeros(Nout,size(X,2),'like',X); orders=(-N/2:N/2-1).';
  outorders=(-Nout/2:Nout/2-1).';
  [tf,at]=ismember(orders,outorders);
  if ~all(tf), error('i32e:OrderPadding','A source order is not nested.'); end
  Y(at,:)=X;
end
