function out = i32_wall_module(c,staged,lift_private,timer,retained_before_mib)
%I32_WALL_MODULE Evaluate the frozen artificial-wall action ladder.
% Purpose:
%   Apply the fixed staged density to the three wall output grids, form
%   compact wall and wall-volume signatures, and retain only finest factors.
% Input:
%   c, staged, lift_private, timer - Frozen contract and same-trial inputs.
%   retained_before_mib            - Caller active-object proxy.
% Output:
%   out                            - Typed total module result.
% Main algorithm:
%   Evaluate the exact modal circle-to-wall action, repair it with the same
%   shared total Dirichlet trace, project by G/P, and immediately replace
%   coarse maps by endpoint/pair signatures on the I_4096 row ordering.
% Based on:
%   i32_same_eval.m LOCAL_wall_ladders and i32_cap_tail.m component factors.
% Main changes:
%   Coarse/native maps die after their registered nested difference; only
%   finest projected factors, compact signatures, and metrics are returned.
% Numerical goal:
%   Preserve the frozen wall science with bounded retained memory.

  warnings=LOCAL_empty_warnings(); calls=LOCAL_zero_counters(); peak=0;
  first=LOCAL_condition('NONE','The wall action ladder is available.');
  available=false; public=struct(); finest=struct(); signatures=struct();
  input_alias=LOCAL_value_mib(staged)+LOCAL_value_mib(lift_private);
  peak=max(peak,LOCAL_workspace_mib());
  try
    z=staged.certificate; density=LOCAL_density_coefficients(z);
    Nfinal=max(c.wall_levels); bw=lift_private.wall_trace;
    wv_final=lift_private.wall_lift_weights{end}/z.gamma;
    wv_joint=lift_private.wall_lift_weights{2}/z.gamma;
    LOCAL_weight_gate(bw,wv_final,wv_joint,Nfinal);
    endpoint=cell(1,3); pair=cell(1,2); refinement=cell(1,2);
    previous=struct(); previous_native=struct(); joint=struct();
    joint_factors=struct();
    repair=struct(); final_level_summary=struct();
    for level_index=1:3
      LOCAL_hard_time(timer,c,'wall output ladder');
      N=c.wall_levels(level_index); orders=(-N/2:N/2-1).';
      [FL,FR]=LOCAL_circle_to_wall(z,density,orders);
      [xiL,xiR,gL,gR]=LOCAL_wall_pad(z,N);
      beta=z.beta+2*pi*orders/z.d; gamma=LOCAL_outgoing(z.khat,beta);
      E=exp(1i*gamma*(z.X_R-z.X_L)); s0=1i./(2*gamma);
      rawL=s0.*(xiL+E.*xiR)+FL; rawR=s0.*(E.*xiL+xiR)+FR;
      fluxL=.5*(xiL-E.*xiR)+1i*gamma.*FL;
      fluxR=.5*(-E.*xiL+xiR)+1i*gamma.*FR;
      defectL=gL-rawL; defectR=gR-rawR;
      finite=all(isfinite([rawL(:);rawR(:);fluxL(:);fluxR(:)]));
      calls.harmonic_action_calls=calls.harmonic_action_calls+1;
      native=struct('N',N,'raw_left',rawL,'raw_right',rawR, ...
        'flux_left',fluxL,'flux_right',fluxR);
      if level_index>1
        refinement{level_index-1}=LOCAL_refinement_pair( ...
          c,previous_native,native);
        clear previous_native;
      end
      previous_native=native;

      level=struct('N',Nfinal,'actual_output_N',N, ...
        'orders',(-Nfinal/2:Nfinal/2-1).', ...
        'defect_left',LOCAL_pad_orders(defectL,N,Nfinal), ...
        'defect_right',LOCAL_pad_orders(defectR,N,Nfinal), ...
        'flux_left',LOCAL_pad_orders(fluxL,N,Nfinal), ...
        'flux_right',LOCAL_pad_orders(fluxR,N,Nfinal));
      factors=LOCAL_factors(staged,level,bw,wv_final);
      factors.wall.endpoint_id=sprintf('wall-output-%d-wall',N);
      factors.volume.endpoint_id=sprintf('wall-output-%d-volume-wall',N);
      wall_endpoint=LOCAL_endpoint_signature(c, ...
        factors.wall.endpoint_id,'wall',factors.wall_minus, ...
        factors.wall_plus,z,factors.center_wall,32);
      volume_endpoint=LOCAL_endpoint_signature(c, ...
        factors.volume.endpoint_id,'volume-wall', ...
        factors.volume_minus,factors.volume_plus,z, ...
        factors.center_volume,32);
      endpoint{level_index}=struct('wall',wall_endpoint, ...
        'volume_wall',volume_endpoint,'actual_output_N',N);
      if level_index>1
        pair{level_index-1}=struct( ...
          'wall',LOCAL_pair_signature(c,previous.wall,factors.wall, ...
            z,32,32), ...
          'volume_wall',LOCAL_pair_signature(c,previous.volume,factors.volume, ...
            z,32,32));
        clear previous;
      end
      previous=struct('wall',factors.wall,'volume',factors.volume);

      if level_index==2
        joint_factors=LOCAL_factors(staged,level,bw,wv_joint);
        joint_factors.wall.endpoint_id='joint-wall-wall';
        joint_factors.volume.endpoint_id='joint-wall-volume-wall';
        joint=struct( ...
          'wall',LOCAL_endpoint_signature(c,'joint-wall-wall','wall', ...
            joint_factors.wall_minus,joint_factors.wall_plus,z, ...
            joint_factors.center_wall,16), ...
          'volume_wall',LOCAL_endpoint_signature(c, ...
            'joint-wall-volume-wall','volume-wall', ...
            joint_factors.volume_minus,joint_factors.volume_plus,z, ...
            joint_factors.center_volume,16), ...
          'actual_output_N',N,'gauss_level',c.gauss_levels(2), ...
          'selected_full_p_N',16);
      end
      if level_index==3
        joint.pair_to_final=struct( ...
          'wall',LOCAL_pair_signature(c,joint_factors.wall,factors.wall, ...
            z,16,32), ...
          'volume_wall',LOCAL_pair_signature(c,joint_factors.volume, ...
            factors.volume,z,16,32));
        clear joint_factors;
        repair=LOCAL_metric_record([rawL+defectL;rawR+defectR], ...
          [gL;gR],c.identity_tol);
        finest=struct('normal_minus',factors.wall_minus_unweighted, ...
          'normal_plus',factors.wall_plus_unweighted, ...
          'defect_left_minus',factors.defect_left_minus, ...
          'defect_left_plus',factors.defect_left_plus, ...
          'defect_right_minus',factors.defect_right_minus, ...
          'defect_right_plus',factors.defect_right_plus, ...
          'center_wall',factors.center_wall_unweighted);
        final_level_summary=struct('N',N,'order_min',orders(1), ...
          'order_max',orders(end),'finite',finite, ...
          'raw_left_norm',norm(rawL,'fro'),'raw_right_norm',norm(rawR,'fro'), ...
          'flux_left_norm',norm(fluxL,'fro'), ...
          'flux_right_norm',norm(fluxR,'fro'), ...
          'defect_left_norm',norm(defectL,'fro'), ...
          'defect_right_norm',norm(defectR,'fro'));
      end
      peak=max(peak,LOCAL_workspace_mib());
      clear FL FR xiL xiR gL gR rawL rawR fluxL fluxR defectL defectR;
      clear level factors native;
    end
    clear previous previous_native density;
    signatures=struct('output',{endpoint},'output_pairs',{pair}, ...
      'joint',joint,'common_row_order','I_4096 negative Nyquist retained', ...
      'producer_parity_required',true);
    refinement=[refinement{:}];
    flux_ratio=max(refinement(2).flux_left.ratio, ...
      refinement(2).flux_right.ratio);
    if flux_ratio>c.action_ratio_max
      warnings(end+1)=LOCAL_warning('WALL_ACTION_QUALIFICATION_WARNING', ...
        flux_ratio); %#ok<AGROW>
    end
    parity=LOCAL_collect_parity(signatures);
    available=all([final_level_summary.finite]);
    if ~available
      first=LOCAL_condition('WALL_ACTION_UNAVAILABLE', ...
        'A required fixed-density wall action is nonfinite.');
    end
    public=struct('levels',c.wall_levels,'source_orders',512, ...
      'source_coefficients_fixed',true,'final',final_level_summary, ...
      'refinement',refinement,'repaired_value_metric',repair, ...
      'producer_signature_parity',parity, ...
      'repaired_value_qualified',repair.pass, ...
      'dense_native_ladders_returned',false);
    calls.n_op_signature_parity=parity.total_operations;
  catch ME
    available=false; first=LOCAL_condition(ME.identifier,ME.message);
    finest=struct(); signatures=struct();
  end
  peak=max(peak,LOCAL_workspace_mib());
  clear staged lift_private timer z density endpoint pair refinement;
  clear previous previous_native joint joint_factors repair final_level_summary;
  audit=struct('returned_field_inventory',{{}}, ...
    'returned_numeric_shape_inventory',{{}},'prohibited_field_count',NaN, ...
    'prohibited_shape_count',NaN,'last_use_clear_ledger', ...
      LOCAL_liveness_ledger(), ...
    'post_clear_local_owner_inventory',{LOCAL_owner_inventory()}, ...
    'finest_factor_whitelist',{{ ...
      'finest_factors.normal_minus','finest_factors.normal_plus', ...
      'finest_factors.defect_left_minus','finest_factors.defect_left_plus', ...
      'finest_factors.defect_right_minus','finest_factors.defect_right_plus', ...
      'finest_factors.center_wall'}}, ...
    'compact_signature_whitelist',{{'cap_signatures.output', ...
      'cap_signatures.output_pairs','cap_signatures.joint'}}, ...
    'signature_parity_coverage',LOCAL_collect_parity(signatures), ...
    'common_row_order','I_4096 negative Nyquist retained', ...
    'raw_native_maps_returned',false);
  payload=struct('available',available,'first_unavailable',first, ...
    'public_metrics',public,'finest_factors',finest, ...
    'cap_signatures',signatures,'audit_summary',audit,'warnings',warnings, ...
    'call_counters',calls,'resource_record',struct());
  payload.resource_record=LOCAL_resource_record(retained_before_mib, ...
    input_alias,peak,LOCAL_value_mib(payload),c);
  out=payload;
end

%% ==================== Frozen wall action ====================
% The phase, normal, and output Fourier ordering match Revision E.

function out=LOCAL_density_coefficients(z)
  N=256; eta=z.eta_unit_256;
  out=struct('orders',(-N/2:N/2-1).', ...
    'tau',fftshift(fft(eta(1:N,:),[],1),1)/N, ...
    'zeta',fftshift(fft(eta(N+1:end,:),[],1),1)/N);
  if any(~isfinite([out.tau(:);out.zeta(:)]))
    error('i32f:DensityTransform','The fixed density FFT is nonfinite.');
  end
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
    error('i32f:CircleWallAction','The circle-to-wall action is nonfinite.');
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

function [logvalue,phase]=LOCAL_log_difference(la,pa,lb,pb,subtract_log)
  scale=max(la,lb); value=exp(la-scale+1i*pa)-exp(lb-scale+1i*pb);
  logvalue=scale+log(abs(value))-subtract_log; phase=angle(value);
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
  flip=imag(gamma)<0|(imag(gamma)==0&real(gamma)<0); gamma(flip)=-gamma(flip);
  if any(~isfinite(gamma))||any(gamma==0)
    error('i32f:BranchUnavailable','A required outgoing branch is unavailable.');
  end
end

%% ==================== Canonical wall factors ====================
% Volume row order is [right defect; left defect times P] on plus.

function out=LOCAL_factors(staged,level,bw,wv)
  z=staged.certificate; Gp=z.Gplus; Gm=z.Gminus;
  QLp=level.flux_left*Gp; QRp=level.flux_right*Gp;
  QLm=level.flux_left*Gm; QRm=level.flux_right*Gm;
  Jp=QRp+QLp*z.Pplus; Jm=QLm+QRm*z.Pminus;
  Hwp=LOCAL_weight_rows(Jp,1./sqrt(bw));
  Hwm=LOCAL_weight_rows(Jm,1./sqrt(bw));
  DLp=level.defect_left*Gp; DRp=level.defect_right*Gp;
  DLm=level.defect_left*Gm; DRm=level.defect_right*Gm;
  LVLp=LOCAL_weight_rows(DLp,sqrt(wv));
  LVRp=LOCAL_weight_rows(DRp,sqrt(wv));
  LVLm=LOCAL_weight_rows(DLm,sqrt(wv));
  LVRm=LOCAL_weight_rows(DRm,sqrt(wv));
  Hvp=[LVRp;LVLp*z.Pplus]; Hvm=[LVLm;LVRm*z.Pminus];
  [center_left,center_right]=LOCAL_fresh_center_wall(staged,level);
  center_wall=[center_left./sqrt(bw);center_right./sqrt(bw)];
  left=LOCAL_pad_orders(z.center_left_value_mismatch,512,numel(wv));
  right=LOCAL_pad_orders(z.center_right_value_mismatch,512,numel(wv));
  center_volume=[sqrt(wv).*left;sqrt(wv).*right; ...
    LVLp*z.cplus;LVRm*z.cminus];
  out=struct('wall_minus',Hwm,'wall_plus',Hwp, ...
    'wall_minus_unweighted',Jm,'wall_plus_unweighted',Jp, ...
    'defect_left_minus',DLm,'defect_left_plus',DLp, ...
    'defect_right_minus',DRm,'defect_right_plus',DRp, ...
    'volume_minus',Hvm,'volume_plus',Hvp, ...
    'center_wall',center_wall,'center_wall_unweighted', ...
      struct('left',center_left,'right',center_right), ...
    'center_volume',center_volume, ...
    'wall',struct('minus',Hwm,'plus',Hwp,'center',center_wall), ...
    'volume',struct('minus',Hvm,'plus',Hvp,'center',center_volume));
end

function [left,right]=LOCAL_fresh_center_wall(staged,wall)
  z=staged.certificate; q=z.q_center; K=z.K;
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
  if ~all(tf), error('i32f:RetainedEmbedding','A retained mode is missing.'); end
  value(at,:)=X;
end

function value=LOCAL_weight_rows(A,w)
  if size(A,1)~=numel(w)
    error('i32f:FactorDimensions','A factor weight dimension is wrong.');
  end
  value=bsxfun(@times,A,w);
end

function LOCAL_weight_gate(bw,wv_final,wv_joint,N)
  if numel(bw)~=N||numel(wv_final)~=N||numel(wv_joint)~=N|| ...
      any(~isfinite([bw;wv_final;wv_joint]))||any(bw<=0)|| ...
      any(wv_final<0)||any(wv_joint<0)
    error('i32f:ComponentWeight','A required wall component weight is invalid.');
  end
end

%% ==================== Compact endpoint and pair signatures ====================
% Direct action blocks are transient and die inside these helpers.

function out=LOCAL_endpoint_signature(c,label,component,Hm,Hp,z,center,N)
  [minus,block_m]=LOCAL_side_endpoint(c,Hm,z.Pminus,z.cminus,N);
  [plus,block_p]=LOCAL_side_endpoint(c,Hp,z.Pplus,z.cplus,N);
  center_squared=norm(center)^2;
  long=norm([center(:);block_m;block_p]);
  reconstructed=sqrt(center_squared+sum(minus.direct_squared_terms(1:N))+ ...
    sum(plus.direct_squared_terms(1:N)));
  nops=4*(numel(center)+numel(block_m)+numel(block_p))+16;
  parity=LOCAL_parity_record(label,'producer_endpoint_direct', ...
    long,reconstructed,nops);
  clear block_m block_p long reconstructed;
  out=struct('endpoint_id',label,'component',component, ...
    'row_order','canonical wall row blocks','Nminus',N,'Nplus',N, ...
    'center_squared',center_squared,'minus',minus,'plus',plus, ...
    'finite',minus.finite&&plus.finite&&isfinite(center_squared), ...
    'signature_parity',parity);
end

function [out,long_block]=LOCAL_side_endpoint(c,H,P,c0,N)
  Nmax=max(c.full_p_levels); terms=zeros(1,Nmax); state=c0;
  rows=size(H,1); long_block=zeros(rows*Nmax,1,'like',H*c0);
  for n=1:Nmax
    action=H*state; terms(n)=norm(action)^2;
    if n<=N, long_block((n-1)*rows+(1:rows))=action; end
    state=P*state;
  end
  W=H'*H;
  out=struct('W',W,'direct_squared_terms',terms, ...
    'tail_input_audit',struct('rows',rows,'state_dimension',size(P,1)), ...
    'finite',all(isfinite([W(:);terms(:)])));
end

function out=LOCAL_pair_signature(c,a,b,z,Na,Nb)
  [dm,block_m]=LOCAL_side_pair(c,a.minus,b.minus,z.Pminus,z.cminus,Na,Nb);
  [dp,block_p]=LOCAL_side_pair(c,a.plus,b.plus,z.Pplus,z.cplus,Na,Nb);
  dc=norm(b.center-a.center)^2;
  long=norm([b.center(:)-a.center(:);block_m;block_p]);
  reconstructed=sqrt(dc+sum(dm)+sum(dp));
  nops=4*(numel(a.center)+numel(block_m)+numel(block_p))+24;
  label=[a.endpoint_id,'->',b.endpoint_id];
  parity=LOCAL_parity_record(label,'producer_pair_direct', ...
    long,reconstructed,nops);
  out=struct('left_endpoint_id',a.endpoint_id, ...
    'right_endpoint_id',b.endpoint_id, ...
    'center_difference_squared',dc, ...
    'minus_direct_difference_squared_terms',dm, ...
    'plus_direct_difference_squared_terms',dp, ...
    'left_norm_scale',LOCAL_direct_scale(a,z,Na), ...
    'right_norm_scale',LOCAL_direct_scale(b,z,Nb), ...
    'finite',all(isfinite([dc,dm,dp])),'signature_parity',parity);
  clear block_m block_p long reconstructed;
end

function [terms,long_block]=LOCAL_side_pair(c,Ha,Hb,P,c0,Na,Nb)
  Nmax=max(c.full_p_levels); rows=size(Ha,1);
  if size(Hb,1)~=rows
    error('i32f:SignatureRows','A wall pair row order is inconsistent.');
  end
  terms=zeros(1,Nmax); long_block=zeros(rows*Nmax,1,'like',Ha*c0); state=c0;
  for n=1:Nmax
    da=zeros(rows,1,'like',Ha*c0); db=da;
    if n<=Na, da=Ha*state; end
    if n<=Nb, db=Hb*state; end
    difference=db-da; terms(n)=norm(difference)^2;
    long_block((n-1)*rows+(1:rows))=difference; state=P*state;
  end
end

function value=LOCAL_direct_scale(factors,z,N)
  value=norm(factors.center)^2; state=z.cminus;
  for n=1:N, value=value+norm(factors.minus*state)^2; state=z.Pminus*state; end
  state=z.cplus;
  for n=1:N, value=value+norm(factors.plus*state)^2; state=z.Pplus*state; end
  value=sqrt(value);
end

function out=LOCAL_parity_record(label,class_name,long,sig,nops)
  scale=max([realmin,abs(long),abs(sig)]); allowance=100*nops*eps*scale;
  numerator=abs(long-sig);
  out=struct('label',label,'coverage_class',class_name,'actual',true, ...
    'representative',false,'long_value',long,'signature_value',sig, ...
    'n_op',nops,'scale',scale,'allowance',allowance, ...
    'numerator',numerator,'ratio',numerator/max(realmin,allowance), ...
    'pass',isfinite(numerator)&&numerator<=allowance);
end

function out=LOCAL_collect_parity(signatures)
  records=struct([]);
  if isstruct(signatures)&&isfield(signatures,'output')
    for j=1:numel(signatures.output)
      e=signatures.output{j};
      records=LOCAL_append(records,e.wall.signature_parity); %#ok<AGROW>
      records=LOCAL_append(records,e.volume_wall.signature_parity); %#ok<AGROW>
    end
    for j=1:numel(signatures.output_pairs)
      p=signatures.output_pairs{j};
      records=LOCAL_append(records,p.wall.signature_parity); %#ok<AGROW>
      records=LOCAL_append(records,p.volume_wall.signature_parity); %#ok<AGROW>
    end
    if isfield(signatures,'joint')&&isfield(signatures.joint,'wall')
      records=LOCAL_append(records,signatures.joint.wall.signature_parity); %#ok<AGROW>
      records=LOCAL_append(records, ...
        signatures.joint.volume_wall.signature_parity); %#ok<AGROW>
      records=LOCAL_append(records, ...
        signatures.joint.pair_to_final.wall.signature_parity); %#ok<AGROW>
      records=LOCAL_append(records, ...
        signatures.joint.pair_to_final.volume_wall.signature_parity); %#ok<AGROW>
    end
  end
  coverage=LOCAL_validate_parity_coverage(records,LOCAL_expected_parity());
  if isempty(records)
    out=struct('records',records,'required_count',coverage.required_count, ...
      'pass',false,'total_operations',0,'coverage',coverage); return;
  end
  out=struct('records',records,'required_count',coverage.required_count, ...
    'pass',all([records.pass])&&coverage.pass, ...
    'total_operations',sum([records.n_op]),'coverage',coverage);
end

function expected=LOCAL_expected_parity()
  rows={ ...
    'wall-output-1024-wall','producer_endpoint_direct',true,false; ...
    'wall-output-1024-volume-wall','producer_endpoint_direct',true,false; ...
    'wall-output-2048-wall','producer_endpoint_direct',true,false; ...
    'wall-output-2048-volume-wall','producer_endpoint_direct',true,false; ...
    'wall-output-4096-wall','producer_endpoint_direct',true,false; ...
    'wall-output-4096-volume-wall','producer_endpoint_direct',true,false; ...
    'joint-wall-wall','producer_endpoint_direct',true,false; ...
    'joint-wall-volume-wall','producer_endpoint_direct',true,false; ...
    'wall-output-1024-wall->wall-output-2048-wall', ...
      'producer_pair_direct',true,false; ...
    'wall-output-1024-volume-wall->wall-output-2048-volume-wall', ...
      'producer_pair_direct',true,false; ...
    'wall-output-2048-wall->wall-output-4096-wall', ...
      'producer_pair_direct',true,false; ...
    'wall-output-2048-volume-wall->wall-output-4096-volume-wall', ...
      'producer_pair_direct',true,false; ...
    'joint-wall-wall->wall-output-4096-wall', ...
      'producer_pair_direct',true,false; ...
    'joint-wall-volume-wall->wall-output-4096-volume-wall', ...
      'producer_pair_direct',true,false};
  expected=cell2struct(rows, ...
    {'label','coverage_class','actual','representative'},2);
end

function out=LOCAL_validate_parity_coverage(records,expected)
  observed=false(numel(expected),1); duplicates=false(numel(expected),1);
  expected_record=false(1,numel(records));
  for j=1:numel(expected)
    hit=find(strcmp({records.label},expected(j).label)& ...
      strcmp({records.coverage_class},expected(j).coverage_class)& ...
      [records.actual]==expected(j).actual& ...
      [records.representative]==expected(j).representative);
    observed(j)=numel(hit)==1; duplicates(j)=numel(hit)>1;
    expected_record(hit)=true;
  end
  out=struct('expected',expected,'required_count',numel(expected), ...
    'observed_exactly_once',observed,'duplicate_expected',duplicates, ...
    'missing_count',sum(~observed),'duplicate_count',sum(duplicates), ...
    'unexpected_count',sum(~expected_record),'empty_records',isempty(records), ...
    'pass',~isempty(records)&&all(observed)&&~any(duplicates)&& ...
      all(expected_record)&&numel(records)==numel(expected));
end

function value=LOCAL_append(value,item)
  if isempty(value), value=item; else, value(end+1)=item; end
end

%% ==================== Refinement and module audit ====================
% Nested metrics are formed before the coarse native maps are cleared.

function out=LOCAL_refinement_pair(c,a,b)
  N0=a.N; N1=b.N;
  out=struct('from_orders',N0,'to_orders',N1, ...
    'raw_left',LOCAL_metric_record(LOCAL_pad_orders(a.raw_left,N0,N1), ...
      b.raw_left,c.action_ratio_max), ...
    'raw_right',LOCAL_metric_record(LOCAL_pad_orders(a.raw_right,N0,N1), ...
      b.raw_right,c.action_ratio_max), ...
    'flux_left',LOCAL_metric_record(LOCAL_pad_orders(a.flux_left,N0,N1), ...
      b.flux_left,c.action_ratio_max), ...
    'flux_right',LOCAL_metric_record(LOCAL_pad_orders(a.flux_right,N0,N1), ...
      b.flux_right,c.action_ratio_max));
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
  paths={'finest_factors.normal_minus','finest_factors.normal_plus', ...
    'finest_factors.defect_left_minus','finest_factors.defect_left_plus', ...
    'finest_factors.defect_right_minus','finest_factors.defect_right_plus', ...
    'finest_factors.center_wall', ...
    'cap_signatures.output','cap_signatures.output_pairs', ...
    'cap_signatures.joint'};
  out=repmat(struct('field_path','','consumer_set',{{'fullp_cap'}}, ...
    'unique_last_consumer','fullp_cap','death','after fullp_cap'),numel(paths),1);
  for j=1:numel(paths), out(j).field_path=paths{j}; end
end

function LOCAL_hard_time(timer,c,stage)
  if toc(timer)>c.hard_seconds
    error('i32f:HardTime','The hard limit was reached in %s.',stage);
  end
end

function Y=LOCAL_pad_orders(X,N,Nout)
  if N==Nout, Y=X; return; end
  if N>Nout||mod(N,2)||mod(Nout,2)
    error('i32f:OrderPadding','Invalid Fourier order padding.');
  end
  Y=zeros(Nout,size(X,2),'like',X); source=(-N/2:N/2-1).';
  target=(-Nout/2:Nout/2-1).'; [tf,at]=ismember(source,target);
  if ~all(tf), error('i32f:OrderPadding','A source order is not nested.'); end
  Y(at,:)=X;
end

function out=LOCAL_resource_record(before,input_alias,peak,returned,c)
  exclusive=max(0,peak-input_alias);
  out=struct('retained_before_mib',before,'input_alias_nominal_mib',input_alias, ...
    'local_workspace_peak_mib',peak,'module_exclusive_peak_mib',exclusive, ...
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
