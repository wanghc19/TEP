function out = i32_cap_tail(c,s,evaluation,timer)
%I32_CAP_TAIL Assemble canonical factors and empirical evaluation caps.
% Purpose:
%   Convert fixed-density nested actions into wall, circle, and value-lift
%   component vectors, contract full nonnormal P tails, and apply the frozen
%   empirical remainder ledger without duplicate observed shifts.
% Input:
%   c          - Frozen ecap-a1 contract.
%   s          - Staged immutable certificate and ordinary anchors.
%   evaluation - Same-trial action/weight ladders from i32_same_eval.
%   timer      - Entry timer used only for hard resource enforcement.
% Output:
%   out        - Component ledgers, numerator/denominator caps, q_emp,
%                nominal transform, warnings, tails, and audit objects.
% Main algorithm:
%   Build positive factors, embed all direct actions at Nmax=32, keep a
%   separate nonnegative tail slot per side, compare artifact/fresh vectors,
%   and combine preregistered axis remainders by the component triangle sum.
% Numerical goal:
%   An ordinary empirical same-trial evaluation cap; no directed enclosure.

  warnings=struct('code',{},'value',{},'blocking',{});
  calls=LOCAL_counters(); peak=c.worst_transient_mib;
  first=LOCAL_condition('NONE','All empirical cap components are available.');
  try
    final_choice=LOCAL_choice(c,7,3,3,3,3,3);
    final=LOCAL_build_components(c,s,evaluation,final_choice);
    calls.full_p_contraction_calls=calls.full_p_contraction_calls+6;
    warnings=[warnings,LOCAL_tail_warnings(c,final)];
    state_tail=LOCAL_state_tail(c,s.certificate);
    calls.full_p_contraction_calls=calls.full_p_contraction_calls+6;
    warnings=[warnings,state_tail.warnings];
    artifact=LOCAL_artifact_components(c,s,evaluation);
    calls.full_p_contraction_calls=calls.full_p_contraction_calls+6;
    [anchors,assoc_warnings]=LOCAL_anchor_ledgers(c,s,artifact,final);
    warnings=[warnings,assoc_warnings];

    [axes,axis_warnings,calls]=LOCAL_axes(c,s,evaluation,final,calls,timer);
    warnings=[warnings,axis_warnings];
    shells=LOCAL_shells(c,s,evaluation,final);
    calls.full_p_contraction_calls=calls.full_p_contraction_calls+16;
    [arithmetic,arith_warnings]=LOCAL_arithmetic(c,final);
    warnings=[warnings,arith_warnings];
    components=LOCAL_component_caps(anchors,axes,shells,arithmetic);
    kernel_ok=evaluation.record.kernel_oracles_available&& ...
      evaluation.record.kernel_qualified&& ...
      evaluation.record.conformity_qualified&& ...
      evaluation.record.actual_T_action_qualified&& ...
      evaluation.record.finite_image_Bloch_qualified;
    numerator_available=components.wall.available&& ...
      components.circle.available&&components.volume.available&& ...
      axes.interaction.pass&&state_tail.available&&kernel_ok;
    if ~numerator_available
      first=LOCAL_first_numerator_unavailable(evaluation,anchors,axes, ...
        shells,arithmetic,state_tail);
    end

    [field,field_warnings,calls]=LOCAL_field_cap(c,s,calls);
    warnings=[warnings,field_warnings];
    denominator_available=field.available;
    if numerator_available&&~denominator_available
      first=LOCAL_condition('FIELD_PARTIAL_EMPIRICALLY_UNRESOLVED', ...
        'The same finite field partial did not form a one-sided empirical cap.');
    end
    caps=LOCAL_caps(s,components,field,numerator_available,denominator_available);
    estimator=LOCAL_estimator(s,c,caps,numerator_available,denominator_available);
    all_modes=all([evaluation.circle.angular_levels.finite])&& ...
      all([evaluation.wall.levels.finite]);
    peak=max(peak,LOCAL_mib({final,artifact,axes,shells,components,field}));
    audit=struct('final_vectors',LOCAL_public_vectors(final), ...
      'artifact_vectors',LOCAL_public_vectors(artifact), ...
      'artifact_raw_common_maps',artifact.common_reconstruction, ...
      'anchor_association',anchors,'field_same_partial',field, ...
      'component_axis_incidence',LOCAL_incidence(), ...
      'full_p_counter_audit',struct( ...
        'unit','one side-specific tail/partial contraction sequence', ...
        'recorded',calls.full_p_contraction_calls,'expected',292, ...
        'pass',calls.full_p_contraction_calls==292), ...
      'raw_value_enters_volume_only',true, ...
      'raw_wall_normal_enters_wall_only',true, ...
      'raw_circle_normal_enters_circle_only',true, ...
      'uncomputed_tails_outward_enclosed',false);
    unresolved=LOCAL_unresolved_axes( ...
      axes,shells,arithmetic,state_tail,evaluation.record);
    out=struct('components',components,'caps',caps,'estimator',estimator, ...
      'tails',struct('components',final.tail_records,'state',state_tail), ...
      'axis_metrics',struct('axes',axes,'shells',shells), ...
      'arithmetic',arithmetic,'audit',audit,'warnings',warnings, ...
      'numerator_available',numerator_available, ...
      'denominator_available',denominator_available, ...
      'all_modes_included',all_modes,'first_unavailable',first, ...
      'unresolved_axes',{unresolved}, ...
      'call_counters',calls,'peak_local_workspace_mib',peak);
  catch ME
    scientific={'i32e:ComponentWeight','i32e:ComponentGram'};
    if ~any(strcmp(ME.identifier,scientific)), rethrow(ME); end
    out=struct('components',struct(),'caps',struct(), ...
      'estimator',struct('interval_available',false), ...
      'tails',struct(),'axis_metrics',struct(),'arithmetic',struct(), ...
      'audit',struct(),'warnings',warnings,'numerator_available',false, ...
      'denominator_available',false,'all_modes_included',false, ...
      'unresolved_axes',{{'EXECUTION_UNAVAILABLE'}}, ...
      'first_unavailable',LOCAL_condition(ME.identifier,ME.message), ...
      'call_counters',calls,'peak_local_workspace_mib',peak);
  end
end

function out=LOCAL_first_numerator_unavailable(evaluation,anchors,axes, ...
    shells,arithmetic,state)
  if ~evaluation.record.kernel_oracles_available
    out=LOCAL_condition('KERNEL_ORACLE_UNAVAILABLE', ...
      'A required analytic kernel oracle is numerically unavailable.'); return;
  end
  if ~evaluation.record.kernel_qualified
    out=LOCAL_condition('KERNEL_ORACLE_EMPIRICALLY_UNRESOLVED', ...
      'A preregistered analytic kernel oracle failed qualification.'); return;
  end
  if ~evaluation.record.conformity_qualified
    out=LOCAL_condition('SAME_TRIAL_CONFORMITY_EMPIRICALLY_UNRESOLVED', ...
      'A preregistered repaired-trace identity failed qualification.'); return;
  end
  if ~evaluation.record.actual_T_action_qualified
    out=LOCAL_condition('ACTUAL_DELTA_T_ACTION_EMPIRICALLY_UNRESOLVED', ...
      'The fixed-density QP Delta-T action ladder failed qualification.'); return;
  end
  if ~evaluation.record.finite_image_Bloch_qualified
    out=LOCAL_condition('FINITE_IMAGE_BLOCH_EMPIRICALLY_UNRESOLVED', ...
      'The fixed-density finite-image Bloch action failed qualification.'); return;
  end
  components={'wall','circle','volume'};
  for j=1:numel(components)
    name=components{j};
    if ~anchors.(name).available
      out=LOCAL_condition('ANCHOR_ASSOCIATION_EMPIRICALLY_UNRESOLVED', ...
        ['The ',name,' artifact-to-fresh association is unresolved.']); return;
    end
  end
  axis_order={'image_circle','image_volume','angular_circle', ...
    'angular_volume','wall_wall','wall_volume','riccati_circle', ...
    'gauss_volume','fullp_wall','fullp_circle','fullp_volume'};
  for j=1:numel(axis_order)
    name=axis_order{j};
    if ~axes.(name).available
      out=LOCAL_condition(LOCAL_axis_code(name), ...
        ['The ',name,' axis is empirically unresolved.']); return;
    end
  end
  if ~axes.interaction.pass
    out=LOCAL_condition('AXIS_INTERACTION_EMPIRICALLY_UNRESOLVED', ...
      'The preregistered joint holdout exceeds the final-leg ledger.'); return;
  end
  shell_order={'circle_circle','circle_volume','wall_wall','wall_volume'};
  for j=1:numel(shell_order)
    name=shell_order{j};
    if ~shells.(name).available
      out=LOCAL_condition('FOURIER_TAIL_EMPIRICALLY_UNRESOLVED', ...
        ['The ',name,' Fourier shell is empirically unresolved.']); return;
    end
  end
  for j=1:numel(components)
    name=components{j};
    if ~arithmetic.(name).available
      out=LOCAL_condition('COMPONENT_ARITHMETIC_EMPIRICALLY_UNRESOLVED', ...
        ['The ',name,' arithmetic paths are unresolved.']); return;
    end
  end
  if ~state.available
    out=LOCAL_condition('MANDATORY_STATE_TAIL_UNAVAILABLE', ...
      'The mandatory W=I full-P state tail is unavailable.'); return;
  end
  out=LOCAL_condition('EMPIRICAL_CAP_UNRESOLVED', ...
    'A required numerator ledger is unresolved.');
end

function out=LOCAL_unresolved_axes(axes,shells,arithmetic,state,qualification)
  out={}; names=fieldnames(axes);
  for j=1:numel(names)
    item=axes.(names{j});
    if isfield(item,'available'), pass=item.available; else, pass=item.pass; end
    if ~pass, out{end+1}=names{j}; end %#ok<AGROW>
  end
  names=fieldnames(shells);
  for j=1:numel(names)
    if ~shells.(names{j}).available
      out{end+1}=['shell_',names{j}]; %#ok<AGROW>
    end
  end
  names=fieldnames(arithmetic);
  for j=1:numel(names)
    if ~arithmetic.(names{j}).available
      out{end+1}=['arithmetic_',names{j}]; %#ok<AGROW>
    end
  end
  if ~state.available, out{end+1}='mandatory_state_tail'; end
  if ~qualification.actual_T_action_qualified
    out{end+1}='actual_DeltaT_action';
  end
  if ~qualification.finite_image_Bloch_qualified
    out{end+1}='finite_image_Bloch';
  end
end

%% ==================== Canonical component construction ====================
% Every axis changes one coordinate while all other coordinates stay final.

function choice=LOCAL_choice(c,image,angular,wall,riccati,gauss,fullp)
  choice=struct('image',image,'angular',angular,'wall',wall, ...
    'riccati',riccati,'gauss',gauss,'fullp',fullp, ...
    'N',c.full_p_levels(fullp),'circle_source','angular');
end

function out=LOCAL_build_components(c,s,e,choice)
  z=s.certificate;
  if strcmp(choice.circle_source,'image')
    circle=e.circle.image_levels(choice.image);
    if choice.angular<3
      circle=LOCAL_restrict_circle(circle,c.circle_levels(choice.angular), ...
        z.R,max(c.circle_levels));
    end
  else
    circle=e.circle.angular_levels(choice.angular);
  end
  wall=LOCAL_expand_wall(e.wall.levels(choice.wall),max(c.wall_levels));
  bw=e.weights.wall_trace;
  bc=e.weights.circle(choice.riccati).weight;
  cv=e.weights.collar(choice.gauss).weight/z.gamma;
  wv=e.weights.wall_lift(choice.gauss).weight/z.gamma;
  if any(~isfinite([bw;bc;cv;wv]))||any(bw<=0)||any(bc<=0)|| ...
      any(cv<0)||any(wv<0)
    error('i32e:ComponentWeight','A required component weight is invalid.');
  end
  Gp=z.Gplus; Gm=z.Gminus; Pp=z.Pplus; Pm=z.Pminus;

  QLp=wall.flux_left*Gp; QRp=wall.flux_right*Gp;
  QLm=wall.flux_left*Gm; QRm=wall.flux_right*Gm;
  Jp=QRp+QLp*Pp; Jm=QLm+QRm*Pm;
  Hwp=LOCAL_weight_rows(Jp,1./sqrt(bw));
  Hwm=LOCAL_weight_rows(Jm,1./sqrt(bw));

  Jcp=circle.jump_coeff*Gp; Jcm=circle.jump_coeff*Gm;
  Hcp=LOCAL_weight_rows(Jcp,1./sqrt(bc));
  Hcm=LOCAL_weight_rows(Jcm,1./sqrt(bc));

  Dcp=circle.delta_coeff*Gp; Dcm=circle.delta_coeff*Gm;
  Cvp=LOCAL_weight_rows(Dcp,sqrt(cv));
  Cvm=LOCAL_weight_rows(Dcm,sqrt(cv));
  DLp=wall.defect_left*Gp; DRp=wall.defect_right*Gp;
  DLm=wall.defect_left*Gm; DRm=wall.defect_right*Gm;
  LVLp=LOCAL_weight_rows(DLp,sqrt(wv));
  LVRp=LOCAL_weight_rows(DRp,sqrt(wv));
  LVLm=LOCAL_weight_rows(DLm,sqrt(wv));
  LVRm=LOCAL_weight_rows(DRm,sqrt(wv));
  Hvp=[Cvp;LVRp;LVLp*Pp];
  Hvm=[Cvm;LVLm;LVRm*Pm];

  centerW=LOCAL_center_wall(s,bw,wall);
  centerV=LOCAL_center_volume(s,z,wv,LVLp,LVRm);
  [wall_vector,wall_tail]=LOCAL_augmented(c,Hwm,Hwp,Pm,Pp, ...
    z.cminus,z.cplus,choice.N,centerW,'wall');
  [circle_vector,circle_tail]=LOCAL_augmented(c,Hcm,Hcp,Pm,Pp, ...
    z.cminus,z.cplus,choice.N,zeros(0,1),'circle');
  [volume_vector,volume_tail]=LOCAL_augmented(c,Hvm,Hvp,Pm,Pp, ...
    z.cminus,z.cplus,choice.N,centerV,'volume');
  out=struct( ...
    'wall',LOCAL_component(wall_vector,Hwm,Hwp,wall_tail), ...
    'circle',LOCAL_component(circle_vector,Hcm,Hcp,circle_tail), ...
    'volume',LOCAL_component(volume_vector,Hvm,Hvp,volume_tail), ...
    'choice',choice,'tail_records',struct('wall',wall_tail, ...
      'circle',circle_tail,'volume',volume_tail));
end

function out=LOCAL_component(vector,~,~,tail)
  out=struct('vector',vector,'B',norm(vector), ...
    'tail',tail,'finite',all(isfinite(vector))&&tail.available);
end

function value=LOCAL_weight_rows(A,w)
  if size(A,1)~=numel(w)
    error('i32e:FactorDimensions','A factor weight dimension is wrong.');
  end
  value=bsxfun(@times,A,w);
end

function out=LOCAL_expand_wall(level,Nfinal)
  % Compare every wall ladder in the fixed I_4096 coefficient space. The
  % density remains in I_512; only evaluated output maps are zero-padded.
  N=level.N;
  if ~ismember(N,[1024,2048,4096])||Nfinal~=4096
    error('i32e:WallCommonEmbedding','The frozen wall output ladder is wrong.');
  end
  out=level;
  names={'defect_left','defect_right','flux_left','flux_right'};
  for j=1:numel(names)
    out.(names{j})=LOCAL_pad_orders(level.(names{j}),N,Nfinal);
  end
  out.actual_output_N=N;
  out.N=Nfinal;
  out.orders=(-Nfinal/2:Nfinal/2-1).';
  out.common_embedding='zero-padded Fourier coefficients in I_4096';
end

function value=LOCAL_center_wall(s,bwall,wall)
  if isempty(wall)
    center=s.certificate.center_wall_jumps;
    left=LOCAL_pad_orders(center.left_coefficients,512,numel(bwall));
    right=LOCAL_pad_orders(center.right_coefficients,512,numel(bwall));
  else
    [left,right]=LOCAL_fresh_center_wall(s,wall);
  end
  value=[left./sqrt(bwall);right./sqrt(bwall)];
end

function [left,right]=LOCAL_fresh_center_wall(s,wall)
  z=s.certificate; q=z.q_center; K=z.K;
  qL=q(1:K); qR=q(K+1:end); gamma=z.branch_port.gamma_m(:);
  E=exp(1i*gamma*z.L);
  dxL=1i*gamma.*(qL-E.*qR); dxR=1i*gamma.*(E.*qL-qR);
  dxL=LOCAL_embed_retained(dxL,z.M,wall.N);
  dxR=LOCAL_embed_retained(dxR,z.M,wall.N);
  right=dxR+wall.flux_left*z.Gplus*z.cplus;
  left=wall.flux_right*z.Gminus*z.cminus-dxL;
end

function value=LOCAL_embed_retained(X,M,Nout)
  source=(-M:M).'; target=(-Nout/2:Nout/2-1).';
  value=zeros(Nout,size(X,2),'like',X); [tf,at]=ismember(source,target);
  if ~all(tf), error('i32e:RetainedEmbedding','A retained mode is missing.'); end
  value(at,:)=X;
end

function value=LOCAL_center_volume(s,z,wv,LVLp,LVRm)
  left=LOCAL_pad_orders(s.certificate.center_left_value_mismatch,512,numel(wv));
  right=LOCAL_pad_orders(s.certificate.center_right_value_mismatch,512,numel(wv));
  center_left=sqrt(wv).*left; center_right=sqrt(wv).*right;
  lead_plus=LVLp*z.cplus; lead_minus=LVRm*z.cminus;
  value=[center_left;center_right;lead_plus;lead_minus];
end

function [vector,record]=LOCAL_augmented(c,Hm,Hp,Pm,Pp,cm,cp,N,center,label)
  if isscalar(N), Nm=N; Np=N; else, Nm=N(1); Np=N(2); end
  Nmax=max(c.full_p_levels); nm=size(Hm,1); np=size(Hp,1);
  if any([Nm,Np]<0)||any([Nm,Np]>Nmax)||any([Nm,Np]~=round([Nm,Np]))
    error('i32e:TailAssociation','A selected artifact N is outside Nmax=32.');
  end
  [Rm,gram_m]=LOCAL_psd_root(Hm); [Rp,gram_p]=LOCAL_psd_root(Hp);
  direct_m=zeros(nm*Nmax,1); direct_p=zeros(np*Nmax,1);
  terms_m=zeros(Nm,1); terms_p=zeros(Np,1); state=cm;
  for j=1:Nm
    action=Rm*state; direct_m((j-1)*nm+(1:nm))=action;
    terms_m(j)=norm(action)^2; state=Pm*state;
  end
  state=cp;
  for j=1:Np
    action=Rp*state; direct_p((j-1)*np+(1:np))=action;
    terms_p(j)=norm(action)^2; state=Pp*state;
  end
  tm=LOCAL_tail_slot(Pm,gram_m,cm,Nm,c);
  tp=LOCAL_tail_slot(Pp,gram_p,cp,Np,c);
  vector=[center(:);direct_m;sqrt(tm.value);direct_p;sqrt(tp.value)];
  first_four=NaN(4,3); first_four(:,1)=(0:3).';
  first_four(1:min(4,Nm),2)=terms_m(1:min(4,Nm));
  first_four(1:min(4,Np),3)=terms_p(1:min(4,Np));
  record=struct('label',label,'Nminus',Nm,'Nplus',Np, ...
    'minus',tm,'plus',tp, ...
    'Nmax',Nmax,'direct_rows_zero_padded',true, ...
    'center_squared',norm(center)^2, ...
    'direct_minus_squares',terms_m,'direct_plus_squares',terms_p, ...
    'first_four_direct_quadratic_actions',first_four, ...
    'tail_slots_separate',true,'available',tm.available&&tp.available&& ...
      all(isfinite(vector)));
end

function [root,W]=LOCAL_psd_root(H)
  W=H'*H; scale=norm(W,2); herm=norm(W-W','fro')/max(realmin,scale);
  [V,D]=eig((W+W')/2); eigen=real(diag(D)); tol=100*eps*max(realmin,scale);
  if any(~isfinite(W),'all')||herm>1e-10||min(eigen)<-tol
    error('i32e:ComponentGram','A squared-norm Gram is invalid.');
  end
  % H itself is the frozen positive factor in canonical raw coordinates.
  % The eigendecomposition above is diagnostic only; no eigenvalue is clipped.
  root=H;
end

function out=LOCAL_tail_slot(P,W,c0,N,c)
  PN=eye(size(P)); WN=zeros(size(W)); state=c0; direct=0;
  for j=1:N
    direct=direct+real(state'*W*state); WN=WN+PN'*W*PN;
    state=P*state; PN=P*PN;
  end
  alternate=LOCAL_binary_power(P,N); defect=norm(PN-alternate,2);
  [Walternate,Pcheck]=LOCAL_gram_doubling(W,P,N);
  gram_defect=norm(WN-Walternate,2);
  defect=max(defect,norm(PN-Pcheck,2));
  pscale=max([1,norm(PN,2),norm(alternate,2)]);
  ahi=norm(PN,2)+defect+100*numel(c0)*eps*pscale;
  left_scale=norm(WN,2); association_scale=max(left_scale,norm(Walternate,2));
  omega=gram_defect;
  if association_scale>0
    omega=omega+100*numel(c0)*eps*association_scale;
  end
  if ahi<1&&isfinite(ahi)
    tail=ahi^2/(1-ahi^2)*(left_scale+omega)*norm(c0)^2;
  else
    tail=Inf;
  end
  tolerance=100*numel(c0)*eps*norm(W,2)*norm(c0)^2;
  if direct<0&&direct>=-tolerance, direct=0; end
  out=struct('value',tail,'finite_partial',direct,'a_hi',ahi, ...
    'power_association_defect',defect,'roundoff_allowance',omega, ...
    'gram_association_defect',gram_defect,'left_WN_norm',left_scale, ...
    'alternate_WN_norm',norm(Walternate,2), ...
    'tail_share',tail/max(realmin,direct),'available', ...
    isfinite(tail)&&tail>=0&&isfinite(direct)&&direct>=0, ...
    'certified',false);
end

function [WN,PN]=LOCAL_gram_doubling(W,P,N)
  if N<1||N~=2^round(log2(N))
    WN=zeros(size(W)); PN=eye(size(P)); state=eye(size(P));
    for j=1:N, WN=WN+state'*W*state; state=P*state; end
    PN=state; return;
  end
  WN=W; PN=P; count=1;
  while count<N
    WN=WN+PN'*WN*PN; PN=PN*PN; count=2*count;
  end
end

function value=LOCAL_binary_power(P,N)
  if N==0, value=eye(size(P)); return; end
  value=eye(size(P)); base=P; count=N;
  while count>0
    if mod(count,2)==1, value=value*base; end
    count=floor(count/2);
    if count>0, base=base*base; end
  end
end

function warnings=LOCAL_tail_warnings(c,value)
  warnings=struct('code',{},'value',{},'blocking',{});
  names={'wall','circle','volume'};
  for j=1:numel(names)
    record=value.(names{j}).tail;
    share=max(record.minus.tail_share,record.plus.tail_share);
    if isfinite(share)&&share>c.tail_share_warning
      warnings(end+1)=LOCAL_warning('FULL_P_TAIL_SHARE_WARNING',share);
    end
  end
end

function out=LOCAL_state_tail(c,z)
  template=struct('N',0,'minus',struct(),'plus',struct(), ...
    'available',false,'maximum_share',Inf);
  levels=repmat(template,1,numel(c.full_p_levels));
  warnings=struct('code',{},'value',{},'blocking',{});
  selected=NaN;
  for j=1:numel(c.full_p_levels)
    N=c.full_p_levels(j);
    tm=LOCAL_tail_slot(z.Pminus,eye(c.K),z.cminus,N,c);
    tp=LOCAL_tail_slot(z.Pplus,eye(c.K),z.cplus,N,c);
    share=max(tm.tail_share,tp.tail_share);
    levels(j)=struct('N',N,'minus',tm,'plus',tp, ...
      'available',tm.available&&tp.available,'maximum_share',share);
    if isnan(selected)&&levels(j).available, selected=j; end
  end
  available=~isnan(selected);
  if available&&isfinite(levels(selected).maximum_share)&& ...
      levels(selected).maximum_share>c.tail_share_warning
    warnings(end+1)=LOCAL_warning('FULL_P_STATE_TAIL_SHARE_WARNING', ...
      levels(selected).maximum_share);
  end
  out=struct('available',available,'selected_index',selected, ...
    'selected_N',LOCAL_selected_N(levels,selected),'levels',levels, ...
    'warnings',warnings,'ordinary_candidate',true,'certified',false);
end

function value=LOCAL_selected_N(levels,index)
  if isnan(index), value=NaN; else, value=levels(index).N; end
end

%% ==================== Artifact common-coordinate reconstruction ====================
% Raw historical maps are remapped; old low-row factors are audit anchors only.

function out=LOCAL_artifact_components(c,s,e)
  z=s.certificate; a=s.raw_maps; Nw=4096; Nc=2048;
  bw=e.weights.wall_trace; bc=e.weights.circle_final;
  cv=e.weights.collar_final/z.gamma; wv=e.weights.wall_lift_final/z.gamma;
  Jp=LOCAL_pad_orders(a.Jplus,512,Nw); Jm=LOCAL_pad_orders(a.Jminus,512,Nw);
  Hwp=LOCAL_weight_rows(Jp,1./sqrt(bw)); Hwm=LOCAL_weight_rows(Jm,1./sqrt(bw));
  Jcp=LOCAL_pad_orders(a.circle_jump_plus,512,Nc);
  Jcm=LOCAL_pad_orders(a.circle_jump_minus,512,Nc);
  Hcp=LOCAL_weight_rows(Jcp,1./sqrt(bc)); Hcm=LOCAL_weight_rows(Jcm,1./sqrt(bc));
  Dcp=LOCAL_pad_orders(a.delta_plus,512,Nc);
  Dcm=LOCAL_pad_orders(a.delta_minus,512,Nc);
  Cvp=LOCAL_weight_rows(Dcp,sqrt(cv)); Cvm=LOCAL_weight_rows(Dcm,sqrt(cv));
  [defL,defR,wall_common]=LOCAL_artifact_wall_defects(s,Nw);
  DLp=defL*z.Gplus; DRp=defR*z.Gplus;
  DLm=defL*z.Gminus; DRm=defR*z.Gminus;
  LVLp=LOCAL_weight_rows(DLp,sqrt(wv)); LVRp=LOCAL_weight_rows(DRp,sqrt(wv));
  LVLm=LOCAL_weight_rows(DLm,sqrt(wv)); LVRm=LOCAL_weight_rows(DRm,sqrt(wv));
  Hvp=[Cvp;LVRp;LVLp*z.Pplus]; Hvm=[Cvm;LVLm;LVRm*z.Pminus];
  centerW=LOCAL_center_wall(s,bw,[]);
  centerV=LOCAL_center_volume(s,z,wv,LVLp,LVRm);
  Nm=round(s.ordinary_anchor.tail_minus.selected_N);
  Np=round(s.ordinary_anchor.tail_plus.selected_N);
  [vw,tw]=LOCAL_augmented(c,Hwm,Hwp,z.Pminus,z.Pplus, ...
    z.cminus,z.cplus,[Nm,Np],centerW,'artifact-wall');
  [vc,tc]=LOCAL_augmented(c,Hcm,Hcp,z.Pminus,z.Pplus, ...
    z.cminus,z.cplus,[Nm,Np],zeros(0,1),'artifact-circle');
  [vv,tv]=LOCAL_augmented(c,Hvm,Hvp,z.Pminus,z.Pplus, ...
    z.cminus,z.cplus,[Nm,Np],centerV,'artifact-volume');
  out=struct('wall',LOCAL_component(vw,Hwm,Hwp,tw), ...
    'circle',LOCAL_component(vc,Hcm,Hcp,tc), ...
    'volume',LOCAL_component(vv,Hvm,Hvp,tv), ...
    'common_reconstruction',struct('wall',wall_common, ...
      'circle_delta_plus_512',a.delta_plus, ...
      'circle_delta_minus_512',a.delta_minus, ...
      'circle_jump_plus_512',a.circle_jump_plus, ...
      'circle_jump_minus_512',a.circle_jump_minus, ...
      'wall_jump_plus_512',a.Jplus,'wall_jump_minus_512',a.Jminus, ...
      'circle_delta_unit_wall_512',a.circle_delta_D_unit_wall_512, ...
      'circle_jump_unit_wall_512',a.circle_j_Gamma_unit_wall_512, ...
      'center_left_value_lift_source', ...
        s.ordinary_anchor.center_left_value_lift_source, ...
      'center_right_value_lift_source', ...
        s.ordinary_anchor.center_right_value_lift_source, ...
      'circle_native_orders',(-256:255).', ...
      'wall_native_orders',(-512:511).', ...
      'canonical_circle_orders',(-1024:1023).', ...
      'canonical_wall_orders',(-2048:2047).'), ...
    'tail_records',struct('wall',tw,'circle',tc,'volume',tv));
end

function [defL,defR,record]=LOCAL_artifact_wall_defects(s,Nout)
  a=s.raw_maps; y=a.wall_common_y_1024(:); beta=s.certificate.beta;
  values=a.wall_common_value_1024; N=numel(y);
  if size(values,1)~=2*N
    error('i32e:ArtifactWallMap','The artifact common wall map has wrong size.');
  end
  rawL=LOCAL_physical_coeff(values(1:N,:),y,beta,s.certificate.d);
  rawR=LOCAL_physical_coeff(values(N+1:end,:),y,beta,s.certificate.d);
  input=a.wall_input_unit_512;
  gL=LOCAL_pad_orders(input(1:512,:),512,N);
  gR=LOCAL_pad_orders(input(513:end,:),512,N);
  nativeL=gL-rawL; nativeR=gR-rawR;
  defL=LOCAL_pad_orders(nativeL,N,Nout);
  defR=LOCAL_pad_orders(nativeR,N,Nout);
  record=struct('grid_nodes',N,'native_orders',(-N/2:N/2-1).', ...
    'defect_left_1024',nativeL,'defect_right_1024',nativeR, ...
    'raw_left_norm',norm(rawL,'fro'),'raw_right_norm',norm(rawR,'fro'), ...
    'shared_left_norm',norm(gL,'fro'),'shared_right_norm',norm(gR,'fro'), ...
    'canonical_output_orders',Nout,'Fourier_evaluation_not_nearest_node',true);
end

function coeff=LOCAL_physical_coeff(values,y,beta,d)
  N=numel(y); gauge=bsxfun(@times,values,exp(-1i*beta*y));
  shift=exp(-1i*2*pi*(-N/2:N/2-1).'*y(1)/d);
  coeff=sqrt(d)*fftshift(fft(gauge,[],1),1)/N;
  coeff=bsxfun(@times,coeff,shift);
end

%% ==================== Axis remainders and Fourier shells ====================
% Coarse levels estimate only true-minus-final remainder, never anchor shift.

function [out,warnings,calls]=LOCAL_axes(c,s,e,final,calls,timer)
  warnings=struct('code',{},'value',{},'blocking',{});
  out=struct();
  % Image axis: circle and circle-volume coordinates only.
  image_circle=cell(1,7); image_volume=cell(1,7);
  for j=1:7
    q=LOCAL_choice(c,j,3,3,3,3,3); q.circle_source='image';
    value=LOCAL_build_components(c,s,e,q);
    image_circle{j}=value.circle; image_volume{j}=value.volume;
  end
  out.image_circle=LOCAL_image_axis(c,image_circle,'circle');
  out.image_volume=LOCAL_image_axis(c,image_volume,'volume');

  % Three-level axes with all other coordinates at fresh-final values.
  out.angular_circle=LOCAL_three_axis(c,s,e,'angular','circle');
  out.angular_volume=LOCAL_three_axis(c,s,e,'angular','volume');
  out.wall_wall=LOCAL_three_axis(c,s,e,'wall','wall');
  out.wall_volume=LOCAL_three_axis(c,s,e,'wall','volume');
  out.riccati_circle=LOCAL_three_axis(c,s,e,'riccati','circle');
  out.gauss_volume=LOCAL_three_axis(c,s,e,'gauss','volume');
  out.fullp_wall=LOCAL_three_axis(c,s,e,'fullp','wall');
  out.fullp_circle=LOCAL_three_axis(c,s,e,'fullp','circle');
  out.fullp_volume=LOCAL_three_axis(c,s,e,'fullp','volume');
  image_builds=numel(c.image_levels);
  three_axis_builds=9*numel(c.full_p_levels);
  interaction_builds=1+6;
  calls.full_p_contraction_calls=calls.full_p_contraction_calls+ ...
    6*(image_builds+three_axis_builds+interaction_builds);
  names=fieldnames(out);
  for j=1:numel(names)
    if ~out.(names{j}).available
      warnings(end+1)=LOCAL_warning(LOCAL_axis_code(names{j}), ...
        out.(names{j}).maximum_ratio);
    end
  end
  out.interaction=LOCAL_interaction(c,s,e,final);
  if ~out.interaction.pass
    warnings(end+1)=LOCAL_warning('AXIS_INTERACTION_EMPIRICALLY_UNRESOLVED', ...
      out.interaction.ratio);
  end
  if toc(timer)>c.hard_seconds
    error('i32e:HardTime','The hard limit was reached in cap axes.');
  end
end

function out=LOCAL_three_axis(c,s,e,axis,component)
  values=cell(1,3);
  for j=1:3
    q=LOCAL_choice(c,7,3,3,3,3,3);
    q.(axis)=j; q.N=c.full_p_levels(q.fullp);
    value=LOCAL_build_components(c,s,e,q); values{j}=value.(component);
  end
  a=values{1}; b=values{2}; d=values{3};
  m1=LOCAL_difference(a,b); m2=LOCAL_difference(b,d);
  scale=max([realmin,a.B,b.B,d.B]); omega=100*numel(d.vector)*eps*scale;
  m1.threshold=Inf; m1.absolute_threshold=Inf;
  m1.pass=isfinite(m1.numerator);
  m2.threshold=c.spectral_ratio_max;
  m2.absolute_threshold=max(c.spectral_ratio_max*m1.numerator,omega);
  m2.pass=isfinite(m2.numerator)&&m2.numerator<=m2.absolute_threshold;
  near=m1.value<=omega&&m2.value<=omega;
  contract=m2.value<=max(c.spectral_ratio_max*m1.value,omega);
  available=all(isfinite([m1.value,m2.value,omega]))&&(near||contract);
  if available, remainder=c.spectral_remainder_factor*max(m2.value,omega);
  else, remainder=NaN; end
  out=struct('axis',axis,'component',component,'d1',m1,'d2',m2, ...
    'omega',omega,'near_zero',near,'contraction_pass',contract, ...
    'numerator',m2.value,'scale',max(realmin,m1.value), ...
    'ratio',m2.value/max(realmin,m1.value), ...
    'threshold',c.spectral_ratio_max,'pass',available, ...
    'maximum_ratio', ...
    m2.value/max(realmin,m1.value),'remainder',remainder,'available',available);
end

function out=LOCAL_image_axis(c,values,component)
  pairs=[3,5;5,7;2,4;4,6;6,7]; labels={ ...
    '64_to_128','128_to_256','48_to_96','96_to_192','192_to_256'};
  template=struct('scalar_shift',NaN,'factor_shift',NaN, ...
    'left_norm',NaN,'right_norm',NaN,'zero_component',false, ...
    'value',NaN,'numerator',NaN,'scale',NaN,'ratio',NaN, ...
    'threshold',NaN,'absolute_threshold',NaN,'pass',false,'label','');
  metrics=repmat(template,1,5);
  for j=1:5
    item=LOCAL_difference(values{pairs(j,1)},values{pairs(j,2)});
    item.label=labels{j};
    metrics(j)=item;
  end
  scale=realmin;
  for j=1:numel(values), scale=max(scale,values{j}.B); end
  omega=100*numel(values{end}.vector)*eps*scale;
  metrics(1).threshold=Inf; metrics(1).absolute_threshold=Inf;
  metrics(3).threshold=Inf; metrics(3).absolute_threshold=Inf;
  metrics(5).threshold=Inf; metrics(5).absolute_threshold=Inf;
  metrics(2).threshold=c.image_ratio_max;
  metrics(2).absolute_threshold=max( ...
    c.image_ratio_max*metrics(1).numerator,omega);
  metrics(4).threshold=c.image_ratio_max;
  metrics(4).absolute_threshold=max( ...
    c.image_ratio_max*metrics(3).numerator,omega);
  for j=1:5
    metrics(j).pass=isfinite(metrics(j).numerator)&& ...
      metrics(j).numerator<=metrics(j).absolute_threshold;
  end
  dyadic_near=metrics(1).value<=omega&&metrics(2).value<=omega;
  staggered_near=metrics(3).value<=omega&&metrics(4).value<=omega;
  dyadic=dyadic_near||metrics(2).value<=max(c.image_ratio_max*metrics(1).value,omega);
  staggered=staggered_near||metrics(4).value<= ...
    max(c.image_ratio_max*metrics(3).value,omega);
  available=dyadic&&staggered&&all(isfinite([metrics.value,omega]));
  if available
    remainder=c.image_remainder_factor*max([metrics(2).value, ...
      metrics(4).value,metrics(5).value,omega]);
  else
    remainder=NaN;
  end
  out=struct('axis','image','component',component,'differences',metrics, ...
    'omega',omega,'dyadic_pass',dyadic,'staggered_pass',staggered, ...
    'cross_finite',isfinite(metrics(5).value), ...
    'numerator',max(metrics(2).value,metrics(4).value), ...
    'scale',max([realmin,metrics(1).value,metrics(3).value]), ...
    'ratio',max(metrics(2).value/max(realmin,metrics(1).value), ...
      metrics(4).value/max(realmin,metrics(3).value)), ...
    'threshold',c.image_ratio_max,'pass',available,'maximum_ratio',max( ...
      metrics(2).value/max(realmin,metrics(1).value), ...
      metrics(4).value/max(realmin,metrics(3).value)), ...
    'remainder',remainder,'available',available);
end

function out=LOCAL_difference(a,b)
  scalar=abs(b.B-a.B); factor=norm(b.vector-a.vector);
  numerator=max(scalar,factor); scale=max([realmin,a.B,b.B]);
  out=struct('scalar_shift',scalar,'factor_shift',factor, ...
    'left_norm',a.B,'right_norm',b.B,'zero_component',a.B==0&&b.B==0, ...
    'value',numerator,'numerator',numerator,'scale',scale, ...
    'ratio',numerator/scale,'threshold',NaN,'absolute_threshold',NaN, ...
    'pass',isfinite(numerator));
end

function out=LOCAL_scalar_metric(numerator,scale,threshold,pass)
  out=struct('numerator',numerator,'left_norm',0,'right_norm',numerator, ...
    'zero_component',numerator==0,'scale',scale, ...
    'ratio',numerator/max(realmin,scale),'threshold',threshold, ...
    'pass',logical(pass));
end

function out=LOCAL_shells(c,s,e,~)
  out=struct();
  out.circle_circle=LOCAL_shell_family(c,s,e,'circle','circle');
  out.circle_volume=LOCAL_shell_family(c,s,e,'circle','volume');
  out.wall_wall=LOCAL_shell_family(c,s,e,'wall','wall');
  out.wall_volume=LOCAL_shell_family(c,s,e,'wall','volume');
end

function out=LOCAL_shell_family(c,s,e,family,component)
  if strcmp(family,'circle')
    one=LOCAL_shell_component(c,s,e,family,component,512,1024);
    two=LOCAL_shell_component(c,s,e,family,component,1024,2048);
  else
    one=LOCAL_shell_component(c,s,e,family,component,1024,2048);
    two=LOCAL_shell_component(c,s,e,family,component,2048,4096);
  end
  S1=one.B; S2=two.B; scale=max([realmin,S1,S2]);
  omega=100*(numel(one.vector)+numel(two.vector))*eps*scale;
  near=S1<=omega&&S2<=omega; pass=near||S2<=max(.5*S1,omega);
  if pass, allowance=2*max(S2,omega); else, allowance=NaN; end
  out=struct('family',family,'component',component,'shell_1',S1, ...
    'shell_2',S2,'omega',omega,'near_zero',near,'contraction_pass',pass, ...
    'shell_1_metric',LOCAL_scalar_metric(S1,realmin,Inf,isfinite(S1)), ...
    'shell_2_metric',LOCAL_scalar_metric( ...
      S2,max(realmin,S1),.5,pass), ...
    'numerator',S2,'scale',max(realmin,S1), ...
    'ratio',S2/max(realmin,S1),'threshold',.5,'pass',pass, ...
    'allowance',allowance,'available',pass, ...
    'center_QZ_value_mismatch_shell_structural_zero', ...
      strcmp(family,'wall')&&strcmp(component,'volume'), ...
    'center_QZ_source_bandwidth','I_512 contained in I_1024');
end

function out=LOCAL_shell_component(c,s,e,family,component,innerN,outerN)
  z=s.certificate; N=max(c.full_p_levels); center=zeros(0,1);
  if strcmp(family,'circle')
    orders=e.circle.orders; mask=LOCAL_shell_mask(orders,innerN,outerN);
    if strcmp(component,'circle')
      map=e.circle.final.jump_coeff(mask,:);
      weight=e.weights.circle_final(mask);
      Hp=LOCAL_weight_rows(map*z.Gplus,1./sqrt(weight));
      Hm=LOCAL_weight_rows(map*z.Gminus,1./sqrt(weight));
    else
      map=e.circle.final.delta_coeff(mask,:);
      weight=e.weights.collar_final(mask)/z.gamma;
      Hp=LOCAL_weight_rows(map*z.Gplus,sqrt(weight));
      Hm=LOCAL_weight_rows(map*z.Gminus,sqrt(weight));
    end
  else
    wall=e.wall.final; orders=wall.orders;
    mask=LOCAL_shell_mask(orders,innerN,outerN);
    if strcmp(component,'wall')
      Lp=wall.flux_left(mask,:)*z.Gplus;
      Rp=wall.flux_right(mask,:)*z.Gplus;
      Lm=wall.flux_left(mask,:)*z.Gminus;
      Rm=wall.flux_right(mask,:)*z.Gminus;
      weight=e.weights.wall_trace(mask);
      Hp=LOCAL_weight_rows(Rp+Lp*z.Pplus,1./sqrt(weight));
      Hm=LOCAL_weight_rows(Lm+Rm*z.Pminus,1./sqrt(weight));
      [center_left,center_right]=LOCAL_fresh_center_wall(s,wall);
      center=[center_left(mask)./sqrt(weight); ...
        center_right(mask)./sqrt(weight)];
    else
      DLp=wall.defect_left(mask,:)*z.Gplus;
      DRp=wall.defect_right(mask,:)*z.Gplus;
      DLm=wall.defect_left(mask,:)*z.Gminus;
      DRm=wall.defect_right(mask,:)*z.Gminus;
      weight=e.weights.wall_lift_final(mask)/z.gamma;
      Hp=[LOCAL_weight_rows(DRp,sqrt(weight)); ...
        LOCAL_weight_rows(DLp*z.Pplus,sqrt(weight))];
      Hm=[LOCAL_weight_rows(DLm,sqrt(weight)); ...
        LOCAL_weight_rows(DRm*z.Pminus,sqrt(weight))];
      center=[LOCAL_weight_rows(DLp,sqrt(weight))*z.cplus; ...
        LOCAL_weight_rows(DRm,sqrt(weight))*z.cminus];
    end
  end
  [vector,tail]=LOCAL_augmented(c,Hm,Hp,z.Pminus,z.Pplus, ...
    z.cminus,z.cplus,N,center,['shell-',family,'-',component]);
  out=LOCAL_component(vector,Hm,Hp,tail);
end

function mask=LOCAL_shell_mask(orders,innerN,outerN)
  outer=orders>=-outerN/2&orders<=outerN/2-1;
  inner=orders>=-innerN/2&orders<=innerN/2-1;
  mask=outer&~inner;
  if ~any(mask), error('i32e:FourierShell','A required Fourier shell is empty.'); end
end

function out=LOCAL_interaction(c,s,e,final)
  q=LOCAL_choice(c,6,2,2,2,2,2); q.circle_source='image';
  joint=LOCAL_build_components(c,s,e,q); names={'wall','circle','volume'};
  lhs=0; scale=realmin;
  for j=1:3
    lhs=lhs+norm(final.(names{j}).vector-joint.(names{j}).vector);
    scale=max(scale,final.(names{j}).B);
  end
  finallegs=0;
  settings={{'image',6,'image',{'circle','volume'}}, ...
    {'angular',2,'angular',{'circle','volume'}}, ...
    {'wall',2,'angular',{'wall','volume'}}, ...
    {'riccati',2,'angular',{'circle'}}, ...
    {'gauss',2,'angular',{'volume'}}, ...
    {'fullp',2,'angular',{'wall','circle','volume'}}};
  for a=1:numel(settings)
    item=settings{a}; q1=LOCAL_choice(c,7,3,3,3,3,3);
    q1.(item{1})=item{2}; q1.circle_source=item{3};
    q1.N=c.full_p_levels(q1.fullp); one=LOCAL_build_components(c,s,e,q1);
    affected=item{4};
    for j=1:numel(affected)
      finallegs=finallegs+norm(final.(affected{j}).vector- ...
        one.(affected{j}).vector);
    end
  end
  omega=100*(numel(final.wall.vector)+numel(final.circle.vector)+ ...
    numel(final.volume.vector))*eps*scale;
  out=struct('joint_shift',lhs,'official_final_leg_sum',finallegs, ...
    'omega',omega,'numerator',lhs,'scale',max(realmin,finallegs+omega), ...
    'ratio',lhs/max(realmin,finallegs+omega),'threshold',1, ...
    'pass',isfinite(lhs)&&lhs<=finallegs+omega);
end

function out=LOCAL_restrict_circle(level,N,R,Nfinal)
  stride=size(level.delta_samples,1)/N;
  if stride~=round(stride)
    error('i32e:CircleRestriction','The circle target grids are not nested.');
  end
  index=1:round(stride):size(level.delta_samples,1);
  delta=level.delta_samples(index,:); jump=level.jump_samples(index,:);
  dc=sqrt(2*pi*R)*fftshift(fft(delta,[],1),1)/N;
  jc=sqrt(2*pi*R)*fftshift(fft(jump,[],1),1)/N;
  out=level; out.target_nodes=N; out.delta_samples=delta; out.jump_samples=jump;
  out.delta_coeff=LOCAL_pad_orders(dc,N,Nfinal);
  out.jump_coeff=LOCAL_pad_orders(jc,N,Nfinal);
end

%% ==================== Anchor, arithmetic, and cap ledgers ====================
% Artifact-to-final movement is included once; future remainder is separate.

function [out,warnings]=LOCAL_anchor_ledgers(c,s,artifact,final)
  warnings=struct('code',{},'value',{},'blocking',{});
  names={'wall','circle','volume'}; fields={'B_wall','B_circle','B_volume'};
  for j=1:3
    a=artifact.(names{j}); f=final.(names{j}); anchor=s.ordinary_anchor.(fields{j});
    scalar=abs(f.B-anchor); factor=norm(f.vector-a.vector);
    scale=max([realmin,anchor,f.B,a.B]); nops=2*numel(f.vector)+8;
    omega=100*nops*eps*scale; observed=max(scalar,factor);
    association=abs(f.B-a.B)<=factor+omega;
    out.(names{j})=struct('artifact_scalar',anchor, ...
      'artifact_common_factor_norm',a.B,'fresh_final',f.B, ...
      'scalar_shift',scalar,'factor_shift',factor, ...
      'observed_shift',observed,'comparison_operations',nops, ...
      'comparison_omega',omega,'A',observed+omega, ...
      'numerator',abs(f.B-a.B),'scale',max(realmin,factor+omega), ...
      'ratio',abs(f.B-a.B)/max(realmin,factor+omega), ...
      'threshold',1,'pass',association, ...
      'reverse_triangle_pass',association,'available', ...
      a.finite&&f.finite&&association&&isfinite(observed+omega));
    if ~out.(names{j}).available
      warnings(end+1)=LOCAL_warning('COMPONENT_NORM_ASSOCIATION_UNRESOLVED', ...
        abs(f.B-a.B)/max(realmin,factor+omega));
    end
  end
end

function [out,warnings]=LOCAL_arithmetic(c,final)
  warnings=struct('code',{},'value',{},'blocking',{});
  names={'wall','circle','volume'};
  for j=1:3
    v=final.(names{j}).vector;
    tail=final.(names{j}).tail;
    gram_squared=tail.center_squared+tail.minus.finite_partial+ ...
      tail.plus.finite_partial+tail.minus.value+tail.plus.value;
    scale_squared=max([realmin,norm(v)^2,abs(gram_squared)]);
    significant=gram_squared<-100*eps*scale_squared;
    if gram_squared<0&&~significant, gram_squared=0; end
    terms=[tail.center_squared; ...
      tail.direct_minus_squares;tail.minus.value; ...
      tail.direct_plus_squares;tail.plus.value];
    compensated_squared=LOCAL_compensated_sum(terms);
    compensated_tolerance=100*eps*max([realmin,abs(terms(:).')]);
    compensated_negative=compensated_squared< -compensated_tolerance;
    if compensated_squared<0&&~compensated_negative, compensated_squared=0; end
    paths=[norm(v),sqrt(gram_squared),sqrt(compensated_squared)];
    spread=max(paths)-min(paths); scale=max([realmin,paths]);
    nops=4*numel(v)+16; omega=100*nops*eps*scale;
    pass=~significant&&~compensated_negative&&all(isfinite(paths))&& ...
      isreal(paths)&&spread<=omega;
    out.(names{j})=struct('paths',paths,'maximum_pairwise_spread',spread, ...
      'operations',nops,'component_scale',scale,'omega',omega, ...
      'numerator',spread,'scale',max(realmin,omega), ...
      'ratio',spread/max(realmin,omega), ...
      'threshold',1,'pass',pass, ...
      'compensated_squared',compensated_squared, ...
      'compensated_negative_significant',compensated_negative, ...
      'remainder',2*max(spread,omega),'available',pass);
    if ~pass
      warnings(end+1)=LOCAL_warning( ...
        'COMPONENT_ARITHMETIC_EMPIRICALLY_UNRESOLVED',spread/max(realmin,omega));
    end
  end
end

function value=LOCAL_compensated_sum(terms)
  value=0; correction=0;
  for j=1:numel(terms)
    y=terms(j)-correction; updated=value+y;
    correction=(updated-value)-y; value=updated;
  end
end

function out=LOCAL_component_caps(anchor,axes,shells,arith)
  out.wall=LOCAL_one_cap(anchor.wall,{axes.wall_wall,axes.fullp_wall}, ...
    shells.wall_wall,arith.wall);
  out.circle=LOCAL_one_cap(anchor.circle,{axes.image_circle, ...
    axes.angular_circle,axes.riccati_circle,axes.fullp_circle}, ...
    shells.circle_circle,arith.circle);
  volume_shell=struct('available',shells.circle_volume.available&& ...
    shells.wall_volume.available,'allowance', ...
    shells.circle_volume.allowance+shells.wall_volume.allowance);
  out.volume=LOCAL_one_cap(anchor.volume,{axes.image_volume, ...
    axes.angular_volume,axes.wall_volume,axes.gauss_volume,axes.fullp_volume}, ...
    volume_shell,arith.volume);
end

function out=LOCAL_one_cap(anchor,axes,shell,arith)
  axis_sum=0; available=anchor.available&&shell.available&&arith.available;
  axis_records=cell(1,numel(axes));
  for j=1:numel(axes)
    axis_records{j}=axes{j}; available=available&&axes{j}.available;
    if axes{j}.available, axis_sum=axis_sum+axes{j}.remainder; end
  end
  if available
    epsilon=anchor.A+axis_sum+shell.allowance+arith.remainder;
  else
    epsilon=NaN;
  end
  out=struct('available',available,'anchor',anchor,'axes',{axis_records}, ...
    'axis_remainder_sum',axis_sum,'fourier_tail_allowance',shell.allowance, ...
    'arithmetic_remainder',arith.remainder,'epsilon_emp',epsilon);
end

%% ==================== Same finite field partial ====================
% Positive omitted field tail is diagnostic only and never a downward cap.

function [out,warnings,calls]=LOCAL_field_cap(c,s,calls)
  warnings=struct('code',{},'value',{},'blocking',{}); z=s.certificate;
  bm=z.beta+2*pi*(-256:255).'/z.d; kappa=sqrt(bm.^2+z.gamma);
  bw=2*kappa.*tanh(kappa/2); retained=abs((-256:255).')<=z.M;
  center=sum(bw(retained).*abs(z.center_shared_left_trace(retained,:)).^2,'all')+ ...
    sum(bw(retained).*abs(z.center_shared_right_trace(retained,:)).^2,'all');
  Hm=s.ordinary_anchor.lead_field_factor_minus;
  Hp=s.ordinary_anchor.lead_field_factor_plus;
  Nm=round(s.ordinary_anchor.tail_minus.selected_N);
  Np=round(s.ordinary_anchor.tail_plus.selected_N);
  same=center+LOCAL_partial(Hm,z.Pminus,z.cminus,Nm)+ ...
    LOCAL_partial(Hp,z.Pplus,z.cplus,Np);
  anchor=s.ordinary_anchor.N_tilde; observed=max(0,anchor-same);
  absolute=abs(anchor-same); ncmp=4*(numel(Hm)+numel(Hp))+64;
  omega_cmp=100*ncmp*eps*max([realmin,abs(anchor),abs(same)]);
  paths=[same,LOCAL_field_gram(center,Hm,Hp,z,Nm,Np), ...
    LOCAL_field_compensated(center,Hm,Hp,z,Nm,Np)];
  spread=max(paths)-min(paths); nops=4*(numel(Hm)+numel(Hp))+64;
  omega=100*nops*eps*max([realmin,abs(paths)]); arithmetic=spread<=omega;
  epsilon=observed+omega_cmp+2*max(spread,omega);
  growth=zeros(1,3);
  for j=1:3
    N=c.full_p_levels(j); growth(j)=center+LOCAL_partial(Hm,z.Pminus,z.cminus,N)+ ...
      LOCAL_partial(Hp,z.Pplus,z.cplus,N);
  end
  tolerance=100*z.K*eps*max([realmin,abs(growth)]);
  increments=diff(growth);
  direction=all(increments>=-tolerance);
  available=all(isfinite([same,paths,epsilon,growth]))&&arithmetic&&direction&& ...
    anchor-epsilon>0;
  if ~arithmetic
    warnings(end+1)=LOCAL_warning('FIELD_ARITHMETIC_EMPIRICALLY_UNRESOLVED', ...
      spread/max(realmin,omega));
  end
  if ~direction
    warnings(end+1)=LOCAL_warning('FIELD_PARTIAL_DIRECTION_UNRESOLVED', ...
      max(-increments/max(realmin,tolerance)));
  end
  % Direct, Gram, compensated, and three growth levels each contract both sides.
  calls.full_p_contraction_calls=calls.full_p_contraction_calls+12;
  out=struct('available',available,'artifact_N_tilde',anchor, ...
    'same_partial',same,'absolute_discrepancy',absolute, ...
    'downward_observed',observed,'comparison_operations',ncmp, ...
    'comparison_omega',omega_cmp,'arithmetic_paths',paths, ...
    'arithmetic_spread',spread,'arithmetic_operations',nops, ...
    'arithmetic_omega',omega,'R_N',2*max(spread,omega), ...
    'epsilon_N_emp',epsilon,'growth_N',[8,16,32], ...
    'growth_values',growth,'growth_increments',increments, ...
    'growth_roundoff_tolerance',tolerance, ...
    'growth_is_diagnostic_only',true, ...
    'omitted_positive_tail_added_to_cap',false, ...
    'dependency_audit',struct( ...
      'consumed_objects',{{'staged shared left/right traces', ...
        'staged lead field factors Hminus/Hplus','frozen Pminus/Pplus', ...
        'frozen cminus/cplus','artifact selected Nminus/Nplus'}}, ...
      'excluded_evaluator_objects',{{'circle actions','wall actions', ...
        'image ladder','Riccati ladder','lift Gauss ladder'}}, ...
      'formula','center + sum_{n=0}^{Nminus-1}||Hm Pm^n cm||^2 + sum_{n=0}^{Nplus-1}||Hp Pp^n cp||^2', ...
      'same_partial_only',true,'structural_zero_axes_proved',true));
end

function value=LOCAL_partial(H,P,c0,N)
  value=0; state=c0;
  for j=1:N, value=value+norm(H*state)^2; state=P*state; end
end

function value=LOCAL_field_gram(center,Hm,Hp,z,Nm,Np)
  value=center+LOCAL_quadratic_sum(Hm'*Hm,z.Pminus,z.cminus,Nm)+ ...
    LOCAL_quadratic_sum(Hp'*Hp,z.Pplus,z.cplus,Np);
end

function value=LOCAL_quadratic_sum(W,P,c0,N)
  value=0; state=c0;
  for j=1:N, value=value+real(state'*W*state); state=P*state; end
end

function value=LOCAL_field_compensated(center,Hm,Hp,z,Nm,Np)
  terms=center; state=z.cminus;
  for j=1:Nm, terms(end+1)=norm(Hm*state)^2; state=z.Pminus*state; end %#ok<AGROW>
  state=z.cplus;
  for j=1:Np, terms(end+1)=norm(Hp*state)^2; state=z.Pplus*state; end %#ok<AGROW>
  total=0; correction=0;
  for j=1:numel(terms)
    y=terms(j)-correction; t=total+y; correction=(t-total)-y; total=t;
  end
  value=total;
end

%% ==================== Final caps and nominal transform ====================
% Empirical quantities never populate strict or reliable theorem fields.

function out=LOCAL_caps(s,components,field,numok,denok)
  if numok
    eW=components.wall.epsilon_emp; eG=components.circle.epsilon_emp;
    eV=components.volume.epsilon_emp; eM=eW+eG+eV;
  else
    eW=NaN; eG=NaN; eV=NaN; eM=NaN;
  end
  if denok, eN=field.epsilon_N_emp; else, eN=NaN; end
  out=struct('M_tilde',s.ordinary_anchor.M_tilde, ...
    'N_tilde',s.ordinary_anchor.N_tilde,'epsilon_W_emp',eW, ...
    'epsilon_Gamma_emp',eG,'epsilon_V_emp',eV, ...
    'epsilon_M_emp',eM,'epsilon_N_emp',eN, ...
    'numerator_triangle_combination',true, ...
    'same_trial_evaluation_cap',numok&&denok, ...
    'rigorous_cap',false,'directed_rounding',false);
end

function out=LOCAL_estimator(s,c,caps,numok,denok)
  q=NaN; lambda=[NaN,NaN]; kval=lambda; width=NaN;
  available=numok&&denok&&isfinite(caps.epsilon_M_emp)&& ...
    isfinite(caps.epsilon_N_emp)&&caps.N_tilde-caps.epsilon_N_emp>0;
  if available
    q=(caps.M_tilde+caps.epsilon_M_emp)/ ...
      sqrt(caps.N_tilde-caps.epsilon_N_emp);
    if q<1
      mu=s.certificate.mu_h; gamma=s.certificate.gamma;
      lambda=[max(0,(mu-q*gamma)/(1+q)),(mu+q*gamma)/(1-q)];
      kval=sqrt(lambda); width=diff(kval);
    end
  end
  out=struct('available',available,'q_emp',q, ...
    'interval_available',available&&q<1,'lambda_lower',lambda(1), ...
    'lambda_upper',lambda(2),'k_lower',kval(1),'k_upper',kval(2), ...
    'width',width,'width_target',c.width_target, ...
    'resolution_pass',available&&q<1&&width<=c.width_target, ...
    'label','EMPIRICAL_NOMINAL_TRANSFORM','ordinary_double',true, ...
    'strict_conditional_theorem_triggered',false,'reliable',false);
end

%% ==================== Small utilities and schema projections ====================
% Utility helpers preserve scale-covariant zeros and compact audit objects.

function out=LOCAL_public_vectors(value)
  out=struct('wall_norm',value.wall.B,'circle_norm',value.circle.B, ...
    'volume_norm',value.volume.B,'wall_length',numel(value.wall.vector), ...
    'circle_length',numel(value.circle.vector), ...
    'volume_length',numel(value.volume.vector), ...
    'tail_records',value.tail_records);
end

function out=LOCAL_incidence()
  out=struct('image',{{'circle','volume-circle'}}, ...
    'circle_angular',{{'circle','volume-circle'}}, ...
    'wall_output',{{'wall','volume-wall'}}, ...
    'riccati',{{'circle'}},'gauss',{{'volume-circle','volume-wall'}}, ...
    'full_P',{{'wall','circle','volume','mandatory-state'}}, ...
    'circle_shell',{{'circle','volume-circle'}}, ...
    'wall_shell',{{'wall','volume-wall'}});
end

function code=LOCAL_axis_code(name)
  if startsWith(name,'image')
    code='IMAGE_TAIL_EMPIRICALLY_UNRESOLVED';
  else
    code='EMPIRICAL_AXIS_UNRESOLVED';
  end
end

function out=LOCAL_warning(code,value)
  out=struct('code',char(code),'value',double(value),'blocking',false);
end

function out=LOCAL_condition(code,message)
  out=struct('code',char(code),'message',char(message));
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

function value=LOCAL_mib(items)
  value=0;
  for j=1:numel(items)
    item=items{j}; info=whos('item'); value=value+info.bytes/2^20;
  end
end

function Y=LOCAL_pad_orders(X,N,Nout)
  if N==Nout, Y=X; return; end
  if N>Nout||mod(N,2)||mod(Nout,2)
    error('i32e:OrderPadding','Invalid Fourier order padding.');
  end
  Y=zeros(Nout,size(X,2),'like',X); source=(-N/2:N/2-1).';
  target=(-Nout/2:Nout/2-1).'; [tf,at]=ismember(source,target);
  if ~all(tf), error('i32e:OrderPadding','A source order is not nested.'); end
  Y(at,:)=X;
end
