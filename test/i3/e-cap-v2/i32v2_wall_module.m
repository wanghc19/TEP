function out = i32v2_wall_module(view,g,cfg,resource,circle)
%I32V2_WALL_MODULE Evaluate wall values, outward fluxes, and shared jumps.
% Purpose:
%   Recompute artificial-wall boundary actions of the same frozen all-boundary
%   layer trial, including quotient-wall Kress self action, circle cross
%   action, internal lead jumps, and center/first-lead singletons.
% Input:
%   view     - Authenticated i32v2_computation_view return.
%   g        - Compact MFS table return.
%   cfg      - Preregistered v2 numerical configuration.
%   resource - Resource gate.
%   circle   - Compact circle return, used only for interface/audit linkage.
% Output:
%   out.data.finest - Finest internal jump and four value-defect factors.
%   out.data.center_first_*_flux - Recomputed first-lead flux singletons.
%   out.data.axis_metrics/gqp_metrics/ordinary_weights - Compact diagnostics.
% Main algorithm:
%   Evaluate fixed wall coefficients in the periodic gauge, use a dedicated
%   straight quotient-wall Kress split for self value, add the explicit
%   +1/2 interior outward normal jump, and stream all separated cross actions.
% Based on:
%   design-3-2d wall split and the frozen Gplus/Gminus associations.
% Notes:
%   i32v2_gqp_pair is the sole periodic-kernel gateway.

  timer=tic; out=LOCAL_empty(); local_peak_mib=0;
  partial_metrics=struct();
  progress=LOCAL_progress('wall');
  target=cell(1,3); source=cell(1,3); proxy=cell(1,6); interp=cell(1,3);
  out.audit.symbol_ledger=struct( ...
    'raw_left','left-wall total trace response of one material cell', ...
    'flux_left','left-wall cell-interior outward normal response', ...
    'internal_plus','QR*Gplus+QL*Gplus*Pplus', ...
    'internal_minus','QL*Gminus+QR*Gminus*Pminus', ...
    'D_X','augmented full-P difference through N=32 with endpoint tails', ...
    'operation_ledger','typed executed complex multiply-add/comparison counts', ...
    'center_first_left_flux','analytic center-left outward plus first-minus QR', ...
    'center_first_right_flux','analytic center-right outward plus first-plus QL', ...
    'cutoff','design-3-2d smooth wall quotient cutoff chi(|w|)', ...
    'q','design-3-2d smooth periodic wall coordinate q(t-s)', ...
    'source_axis_counts','paired circle/wall source counts at fixed finest targets', ...
    'progress_checkpoint','publication-safe compact boundary-action progress');
  try
    view_audit=i32v2_validate_computation_view(view,cfg,'wall');
    z=LOCAL_inputs(view,g,cfg,resource,circle); levels=double(cfg.wall_levels(:).');
    out.audit.computation_view=view_audit;
    circle_levels=double(cfg.circle_levels(:).');
    out.audit.source_axis_counts=[circle_levels(:),levels(:)];
    progress.source_axis_counts=out.audit.source_axis_counts;
    nf=levels(end); circle_source=circle_levels(end);
    weight_fine=LOCAL_wall_weight(z,nf);
    level=struct('n',257,'include_primary',false);
    for j=1:3
      LOCAL_resource(resource,0);
      [target{j},action_progress,action_error]=LOCAL_action( ...
        z,g,cfg,resource,nf,circle_source,levels(j),level,0,nf,j==3);
      progress=LOCAL_absorb_action(progress,action_progress,'target',j);
      local_peak_mib=max(local_peak_mib,action_progress.local_peak_mib);
      if ~isempty(action_error), rethrow(action_error); end
      [source{j},action_progress,action_error]=LOCAL_action( ...
        z,g,cfg,resource,levels(j),circle_levels(j),nf,level,0,nf,false);
      progress=LOCAL_absorb_action(progress,action_progress,'source',j);
      local_peak_mib=max(local_peak_mib,action_progress.local_peak_mib);
      if ~isempty(action_error), rethrow(action_error); end
      outer=whos('target','source');
      local_peak_mib=max(local_peak_mib,sum([outer.bytes])/2^20+ ...
        max(target{j}.audit.local_peak_mib,source{j}.audit.local_peak_mib));
    end
    final=target{3}; finest_all=LOCAL_finest(final,z,weight_fine);
    data.finest=struct('internal_plus',finest_all.internal_plus, ...
      'internal_minus',finest_all.internal_minus, ...
      'value_left_plus',finest_all.value_left_plus, ...
      'value_right_plus',finest_all.value_right_plus, ...
      'value_left_minus',finest_all.value_left_minus, ...
      'value_right_minus',finest_all.value_right_minus);
    [data.center_first_left_flux,data.center_first_right_flux,~,~]= ...
      LOCAL_center_singletons(final,z,nf,weight_fine);
    data.axis_metrics=struct('target',LOCAL_axis(target,z,weight_fine), ...
      'source',LOCAL_axis(source,z,weight_fine));
    clear target source
    data.ordinary_weights=struct('family','wall physical Bloch Fourier', ...
      'order_min',-nf/2,'order_max',nf/2-1,'order_count',nf, ...
      'period',z.d,'trace_weight_min',min(weight_fine), ...
      'trace_weight_max',max(weight_fine), ...
      'all_retained_modes_enter_residual',true);
    partial_metrics=struct('stage','axis metrics complete', ...
      'axis_metrics',data.axis_metrics, ...
      'ordinary_weights',data.ordinary_weights);
    out.data.partial_metrics=partial_metrics;
    diag_n=double(cfg.wall_levels(1)); circle_diag=double(cfg.circle_levels(1));
    weight_diag=LOCAL_wall_weight(z,diag_n);
    for v=0:5
      [action,action_progress,action_error]=LOCAL_action( ...
        z,g,cfg,resource,diag_n,circle_diag,diag_n, ...
        struct('n',129,'include_primary',false),v,diag_n,true);
      progress=LOCAL_absorb_action(progress,action_progress,'proxy',v+1);
      local_peak_mib=max(local_peak_mib,action_progress.local_peak_mib);
      if ~isempty(action_error), rethrow(action_error); end
      proxy{v+1}=LOCAL_gqp_diagnostic(action,z,weight_diag,diag_n);
      local_peak_mib=max(local_peak_mib,action.audit.local_peak_mib);
      outer=whos('data','proxy','action');
      local_peak_mib=max(local_peak_mib,sum([outer.bytes])/2^20+ ...
        action.audit.local_peak_mib);
      clear action
    end
    for j=1:3
      [action,action_progress,action_error]=LOCAL_action( ...
        z,g,cfg,resource,diag_n,circle_diag,diag_n, ...
        struct('n',cfg.gqp_interp_levels(j),'include_primary',false),0,diag_n,true);
      progress=LOCAL_absorb_action(progress,action_progress,'interpolation',j);
      local_peak_mib=max(local_peak_mib,action_progress.local_peak_mib);
      if ~isempty(action_error), rethrow(action_error); end
      interp{j}=LOCAL_gqp_diagnostic(action,z,weight_diag,diag_n);
      local_peak_mib=max(local_peak_mib,action.audit.local_peak_mib);
      outer=whos('data','proxy','interp','action');
      local_peak_mib=max(local_peak_mib,sum([outer.bytes])/2^20+ ...
        action.audit.local_peak_mib);
      clear action
    end
    fine_gqp=LOCAL_gqp_diagnostic(final,z,weight_fine,nf);
    data.gqp_metrics=LOCAL_gqp_metrics(proxy,interp,fine_gqp,'normal');
    data.value_gqp_metrics=LOCAL_gqp_metrics(proxy,interp,fine_gqp,'value');
    clear proxy interp fine_gqp
    data.gqp_metrics.diagnostic_wall_nodes=diag_n;
    data.gqp_metrics.diagnostic_circle_nodes=circle_diag;
    data.gqp_metrics.mapping_label= ...
      'GQP_COARSE_TO_FINE_COMPONENT_MAPPING_EMPIRICAL';
    data.value_gqp_metrics.diagnostic_wall_nodes=diag_n;
    data.value_gqp_metrics.diagnostic_circle_nodes=circle_diag;
    data.value_gqp_metrics.mapping_label= ...
      'GQP_COARSE_TO_FINE_COMPONENT_MAPPING_EMPIRICAL';
    data.value_gqp_metrics.component_destination='V_AFTER_FROZEN_LIFT_ONLY';
    partial_metrics.stage='GQP metrics complete';
    partial_metrics.gqp_metrics=data.gqp_metrics;
    partial_metrics.value_gqp_metrics=data.value_gqp_metrics;
    out.data.partial_metrics=partial_metrics;
    out.data=data; out.available=true; out.status='COMPLETE';
    out.audit.fixed_trial=true; out.audit.density_resolve_count=0;
    out.audit.wall_periodic_gauge=true; out.audit.explicit_normal_jump=0.5;
    out.audit.self_quadrature=[ ...
      'Straight quotient-wall rectangular Kress split with smooth chi/w/q; ', ...
      'MFS-only target-normal correction and explicit +1/2 interior jump.'];
    out.audit.wall_split_recombination=final.wall_split_recombination;
    out.audit.wall_split_recombination_threshold=cfg.threshold.recombination;
    if final.wall_split_recombination>cfg.threshold.recombination
      out.warnings{end+1}='WALL_SPLIT_RECOMBINATION_WARNING';
    end
    out.audit.finest_semantics=struct( ...
      'value','unweighted shared-minus-raw physical Bloch midpoint samples', ...
      'normal','physical Bloch coefficients divided by sqrt(wall trace weight)', ...
      'center_flux','trace-weighted aligned Fourier singleton', ...
      'value_gqp_destination','V after frozen lifting only', ...
      'normal_gqp_destination','W only');
    out.audit.image_sum_code_path_zero=true; out.audit.rayleigh_trial_code_path_zero=true;
    out.audit.source_axis_semantics= ...
      'paired full-boundary circle/wall source refinement at finest wall targets';
    progress.stage='complete'; progress.complete=true;
    out.audit.progress_checkpoint=progress;
    out.counters=LOCAL_counters();
    out.counters.boundary_operation_count=data.gqp_metrics.operation_ledger.total;
    out.memory=LOCAL_memory(data,resource,local_peak_mib);
    clear final
  catch err
    out.available=false; out.status='BLOCKED'; out.first_blocker=LOCAL_identifier(err);
    out.audit.exception_message=err.message;
    progress.stage='blocked'; progress.first_blocker=out.first_blocker;
    progress.local_peak_mib=max(progress.local_peak_mib,local_peak_mib);
    progress.incomplete_dense_returned=false;
    out.audit.progress_checkpoint=progress;
    out.data=struct();
    if ~isempty(fieldnames(partial_metrics))
      out.data.partial_metrics=partial_metrics;
    end
    clear target source proxy interp action final data finest_all
  end
  if ~isfield(out.memory,'proxy_mib')
    out.memory=LOCAL_partial_memory(out,resource,local_peak_mib);
  end
  out.audit.elapsed_s=toc(timer);
end

%% ==================== Complete wall action ====================
% Raw side maps are transformed to the finest physical Bloch coefficient set.

function [a,checkpoint,action_error]=LOCAL_action( ...
    z,g,cfg,resource,ns,nc,nt,field_level,variant,ncommon,collect_gqp)
  action_error=[]; local_peak_bytes=0;
  operation_ledger=LOCAL_count_zero();
  checkpoint=LOCAL_action_checkpoint(nc,ns,nt,field_level,variant,collect_gqp);
  try
  ns=double(ns); nc=double(nc); nt=double(nt); ncommon=double(ncommon);
  yt=-z.d/2+z.d*((0:nt-1)'+0.5)/nt;
  [xiL,ys,~,~,density_left_audit]= ...
    i32v2_wall_density_grid(z.xi_left_unit_512,z,ns);
  [xiR,ys_right,~,~,density_right_audit]= ...
    i32v2_wall_density_grid(z.xi_right_unit_512,z,ns);
  if ~isequal(ys,ys_right)
    error('I32V2:WallDensityGridMismatch', ...
      'The two frozen wall densities do not share one source grid.');
  end
  rawL=complex(zeros(nt,size(xiL,2))); rawR=rawL; qL=rawL; qR=rawL;
  recombination=0;
  operation_ledger.boundary_factor_cma= ...
    operation_ledger.boundary_factor_cma+ ...
    density_left_audit.complex_multiply_add_count+ ...
    density_right_audit.complex_multiply_add_count;
  if collect_gqp
    names={'wall','double','single'};
    for q=1:numel(names)
      gqp.(names{q}).value_left=rawL; gqp.(names{q}).value_right=rawL;
      gqp.(names{q}).flux_left=rawL; gqp.(names{q}).flux_right=rawL;
    end
  end
  tp=cfg.boundary_target_panel;
  for first=1:tp:nt
    last=min(nt,first+tp-1); ids=first:last;
    LOCAL_resource(resource,LOCAL_bytes(rawL)+ ...
      40*numel(ids)*cfg.boundary_source_panel*16);
    [rawL(ids,:),qL(ids,:),pieceL,splitL,left_ledger]=LOCAL_target_side(z,g,cfg,ys,yt(ids),xiL,xiR, ...
      nc,-1,field_level,variant);
    [rawR(ids,:),qR(ids,:),pieceR,splitR,right_ledger]=LOCAL_target_side(z,g,cfg,ys,yt(ids),xiL,xiR, ...
      nc,+1,field_level,variant);
    operation_ledger=LOCAL_count_add(operation_ledger,left_ledger);
    operation_ledger=LOCAL_count_add(operation_ledger,right_ledger);
    recombination=max([recombination,splitL,splitR]);
    if collect_gqp
      for q=1:numel(names)
        name=names{q};
        gqp.(name).value_left(ids,:)=pieceL.(name).value;
        gqp.(name).value_right(ids,:)=pieceR.(name).value;
        gqp.(name).flux_left(ids,:)=pieceL.(name).flux;
        gqp.(name).flux_right(ids,:)=pieceR.(name).flux;
      end
    end
    probe=whos('ys','yt','xiL','xiR','rawL','rawR','qL','qR','gqp', ...
      'pieceL','pieceR');
    local_peak_bytes=max(local_peak_bytes,sum([probe.bytes]));
    checkpoint.completed_panels=checkpoint.completed_panels+1;
    checkpoint.completed_rows=last;
    checkpoint.local_peak_mib=local_peak_bytes/2^20;
    checkpoint.value_fro_squared=checkpoint.value_fro_squared+ ...
      norm(rawL(ids,:),'fro')^2+norm(rawR(ids,:),'fro')^2;
    checkpoint.normal_fro_squared=checkpoint.normal_fro_squared+ ...
      norm(qL(ids,:),'fro')^2+norm(qR(ids,:),'fro')^2;
    checkpoint.operation_ledger=operation_ledger;
    LOCAL_resource(resource,local_peak_bytes);
  end
  a=struct('raw_left_samples',rawL,'raw_right_samples',rawR, ...
    'flux_left_samples',qL,'flux_right_samples',qR, ...
    'raw_left',LOCAL_wall_coeff(rawL,z,ncommon), ...
    'raw_right',LOCAL_wall_coeff(rawR,z,ncommon), ...
    'flux_left',LOCAL_wall_coeff(qL,z,ncommon), ...
    'flux_right',LOCAL_wall_coeff(qR,z,ncommon), ...
    'wall_split_recombination',recombination);
  if collect_gqp
    a.gqp_piece=LOCAL_wall_gqp_pieces(gqp,z,ncommon);
  end
  operation_ledger.total=operation_ledger.interpolation_cma+ ...
    operation_ledger.kernel_phase_multiply+ ...
    operation_ledger.boundary_factor_cma+operation_ledger.factor_comparison+ ...
    operation_ledger.scalar_arithmetic;
  probe=whos('rawL','rawR','qL','qR','gqp','a');
  local_peak_bytes=max(local_peak_bytes,sum([probe.bytes]));
  a.operation_ledger=operation_ledger;
  a.audit=struct('local_peak_mib',local_peak_bytes/2^20, ...
    'cleared_at_return',{{'source/target panels','raw GQP piece samples'}});
  checkpoint.complete=true;
  checkpoint.local_peak_mib=local_peak_bytes/2^20;
  checkpoint.operation_ledger=operation_ledger;
  checkpoint.scalar_norms=struct('raw_left',norm(a.raw_left,'fro'), ...
    'raw_right',norm(a.raw_right,'fro'), ...
    'flux_left',norm(a.flux_left,'fro'), ...
    'flux_right',norm(a.flux_right,'fro'), ...
    'recombination',recombination);
  catch err
    action_error=err; a=struct();
    checkpoint.first_blocker=LOCAL_identifier(err);
    checkpoint.local_peak_mib=max(checkpoint.local_peak_mib,local_peak_bytes/2^20);
    checkpoint.operation_ledger=operation_ledger;
    checkpoint.incomplete_dense_returned=false;
    clear ys yt xiL xiR rawL rawR qL qR gqp pieceL pieceR
  end
end

function [value,flux,piece,recombination,ledger]=LOCAL_target_side(z,g,cfg,ys,yt,xiL,xiR,nc,side,level,variant)
  nt=numel(yt); nstate=size(xiL,2); value=complex(zeros(nt,nstate)); flux=value;
  if side<0, xt=z.X_L; self=xiL; other=xiR; xo=z.X_R; normal=-1;
  else, xt=z.X_R; self=xiR; other=xiL; xo=z.X_L; normal=1; end
  [vs,qs,qskernel,recombination]=i32v2_wall_self_action( ...
    z,g,ys,yt,self,xt,normal,level,variant,cfg.boundary_source_panel);
  ledger=LOCAL_count_zero();
  ledger.interpolation_cma=31*6*nt*numel(ys);
  ledger.kernel_phase_multiply=6*nt*numel(ys);
  ledger.boundary_factor_cma=3*nt*numel(ys)*nstate;
  value=value+vs; flux=flux+qs; ds=z.d/numel(ys);
  piece.wall=struct('value',vs,'flux',qskernel);
  src=[xo*ones(1,numel(ys));ys.']; trg=[xt*ones(1,nt);yt.'];
  for first=1:cfg.boundary_source_panel:numel(ys)
    last=min(numel(ys),first+cfg.boundary_source_panel-1); ids=first:last;
    full=level; full.include_primary=true;
    [p,gx,~,~,~,~,pair_audit]=i32v2_gqp_pair(g,src(:,ids),trg,full,variant);
    dv=ds*p*other(ids,:); dq=ds*normal*gx*other(ids,:);
    value=value+dv; flux=flux+dq;
    piece.wall.value=piece.wall.value+dv; piece.wall.flux=piece.wall.flux+dq;
    ledger.interpolation_cma=ledger.interpolation_cma+ ...
      pair_audit.interpolation.all_field_complex_operation_count;
    ledger.kernel_phase_multiply=ledger.kernel_phase_multiply+ ...
      pair_audit.bloch_phase_multiply_count;
    ledger.boundary_factor_cma=ledger.boundary_factor_cma+ ...
      2*nt*numel(ids)*nstate;
  end
  [vc,qc,circle_piece,circle_ledger]=LOCAL_circle_to_wall(z,g,cfg,trg,normal,nc,level,variant);
  ledger=LOCAL_count_add(ledger,circle_ledger);
  value=value+vc; flux=flux+qc;
  piece.double=circle_piece.double; piece.single=circle_piece.single;
  ledger.total=ledger.interpolation_cma+ledger.kernel_phase_multiply+ ...
    ledger.boundary_factor_cma;
end

function [value,flux,piece,ledger]=LOCAL_circle_to_wall(z,g,cfg,trg,normal,nc,level,variant)
  nc=double(nc);
  [tau,zeta,~,theta,density_audit]=i32v2_circle_density_grid(z,nc);
  src=z.R*[cos(theta).';sin(theta).']; nsn=[cos(theta).';sin(theta).'];
  value=complex(zeros(size(trg,2),size(tau,2))); flux=value; ds=2*pi*z.R/nc;
  piece.double=struct('value',value,'flux',value);
  piece.single=struct('value',value,'flux',value);
  ledger=LOCAL_count_zero();
  ledger.boundary_factor_cma=density_audit.complex_multiply_add_count;
  for first=1:cfg.boundary_source_panel:nc
    last=min(nc,first+cfg.boundary_source_panel-1); ids=first:last;
    full=level; full.include_primary=true;
    [p,gx,gy,hxx,hxy,~,pair_audit]=i32v2_gqp_pair(g,src(:,ids),trg,full,variant);
    sx=nsn(1,ids); sy=nsn(2,ids);
    D=-bsxfun(@times,gx,sx)-bsxfun(@times,gy,sy);
    Dt=-normal*(bsxfun(@times,hxx,sx)+bsxfun(@times,hxy,sy));
    Sn=normal*gx;
    vd=ds*D*tau(ids,:); vs=-ds*p*zeta(ids,:);
    qd=ds*Dt*tau(ids,:); qs=-ds*Sn*zeta(ids,:);
    value=value+vd+vs; flux=flux+qd+qs;
    piece.double.value=piece.double.value+vd;
    piece.single.value=piece.single.value+vs;
    piece.double.flux=piece.double.flux+qd;
    piece.single.flux=piece.single.flux+qs;
    ledger.interpolation_cma=ledger.interpolation_cma+ ...
      pair_audit.interpolation.all_field_complex_operation_count;
    ledger.kernel_phase_multiply=ledger.kernel_phase_multiply+ ...
      pair_audit.bloch_phase_multiply_count;
    ledger.boundary_factor_cma=ledger.boundary_factor_cma+ ...
      4*size(trg,2)*numel(ids)*size(tau,2);
  end
  ledger.total=ledger.interpolation_cma+ledger.kernel_phase_multiply+ ...
    ledger.boundary_factor_cma;
end

function out=LOCAL_wall_gqp_pieces(samples,z,ncommon)
  names={'wall','double','single'}; out=struct();
  for j=1:numel(names)
    name=names{j}; p=samples.(name);
    out.(name)=struct( ...
      'value_left',LOCAL_wall_coeff(p.value_left,z,ncommon), ...
      'value_right',LOCAL_wall_coeff(p.value_right,z,ncommon), ...
      'flux_left',LOCAL_wall_coeff(p.flux_left,z,ncommon), ...
      'flux_right',LOCAL_wall_coeff(p.flux_right,z,ncommon));
  end
end

%% ==================== Lead associations and singletons ====================
% Full matrices preserve nonnormal/Jordan coupling for the later tail module.

function f=LOCAL_finest(a,z,weight)
  [QL,QR,VL,VR]=LOCAL_state_maps(a,z);
  QL=bsxfun(@times,QL,1./sqrt(weight));
  QR=bsxfun(@times,QR,1./sqrt(weight));
  [VLs,VRs]=LOCAL_state_sample_maps(a,z);
  f=struct( ...
    'internal_plus',QR*z.Gplus+QL*z.Gplus*z.Pplus, ...
    'internal_minus',QL*z.Gminus+QR*z.Gminus*z.Pminus, ...
    'value_left_plus',VLs*z.Gplus,'value_right_plus',VRs*z.Gplus, ...
    'value_left_minus',VLs*z.Gminus,'value_right_minus',VRs*z.Gminus, ...
    'value_aligned_left_plus',VL*z.Gplus,'value_aligned_right_plus',VR*z.Gplus, ...
    'value_aligned_left_minus',VL*z.Gminus,'value_aligned_right_minus',VR*z.Gminus);
end

function [left_flux,right_flux,left_value,right_value]=LOCAL_center_singletons(a,z,n,weight)
  center=z.center_wall_jumps;
  dxL=LOCAL_pad(center.center_left_global_dx,n);
  dxR=LOCAL_pad(center.center_right_global_dx,n);
  gL=LOCAL_pad(center.actual_left_trace,n); gR=LOCAL_pad(center.actual_right_trace,n);
  left_flux=bsxfun(@times,-dxL+a.flux_right*z.Gminus*z.cminus,1./sqrt(weight));
  right_flux=bsxfun(@times,dxR+a.flux_left*z.Gplus*z.cplus,1./sqrt(weight));
  y=-z.d/2+z.d*((0:n-1)'+0.5)/n;
  gLs=LOCAL_coeff_samples(gL,z,y); gRs=LOCAL_coeff_samples(gR,z,y);
  raw_right_samples=LOCAL_coeff_samples(LOCAL_pad(a.raw_right,n),z,y);
  raw_left_samples=LOCAL_coeff_samples(LOCAL_pad(a.raw_left,n),z,y);
  left_value=gLs-raw_right_samples*z.Gminus*z.cminus;
  right_value=gRs-raw_left_samples*z.Gplus*z.cplus;
end

function [QL,QR,VL,VR]=LOCAL_state_maps(a,z)
  n=size(a.raw_left,1); K=size(z.Gplus,2); embed=complex(zeros(n,K));
  all=(-n/2:n/2-1).'; retained=(-z.M:z.M).'; [ok,at]=ismember(retained,all);
  if ~all(ok), error('I32V2:WallInputBandwidth','Wall output omits a retained input mode.'); end
  embed(at,:)=eye(K); inputL=[embed,zeros(n,K)]; inputR=[zeros(n,K),embed];
  QL=a.flux_left; QR=a.flux_right; VL=inputL-a.raw_left; VR=inputR-a.raw_right;
end

function [VL,VR]=LOCAL_state_sample_maps(a,z)
  n=size(a.raw_left_samples,1); K=size(z.Gplus,2);
  y=-z.d/2+z.d*((0:n-1)'+0.5)/n; retained=(-z.M:z.M).';
  E=exp(1i*y*(z.beta+2*pi*retained/z.d).')/sqrt(z.d);
  inputL=[E,zeros(n,K)]; inputR=[zeros(n,K),E];
  VL=inputL-a.raw_left_samples; VR=inputR-a.raw_right_samples;
end

%% ==================== Density and physical Fourier maps ====================
% All transforms include the midpoint origin and Bloch gauge explicitly.

function coeff=LOCAL_wall_coeff(samples,z,ncommon)
  n=size(samples,1); orders=(-n/2:n/2-1).';
  y=-z.d/2+z.d*((0:n-1)'+0.5)/n;
  gauge=bsxfun(@times,exp(-1i*z.beta*y),samples);
  coeff=fftshift(fft(gauge,[],1),1)/n;
  origin=-0.5+0.5/n;
  coeff=bsxfun(@times,sqrt(z.d)*exp(-1i*2*pi*orders*origin),coeff);
  if n~=ncommon
    padded=complex(zeros(ncommon,size(coeff,2))); all=(-ncommon/2:ncommon/2-1).';
    [ok,at]=ismember(orders,all); padded(at(ok),:)=coeff(ok,:); coeff=padded;
  end
end

function samples=LOCAL_coeff_samples(coeff,z,y)
  orders=(-size(coeff,1)/2:size(coeff,1)/2-1).';
  samples=exp(1i*y(:)*(z.beta+2*pi*orders/z.d).')*coeff/sqrt(z.d);
end

function weight=LOCAL_wall_weight(z,n)
  orders=(-n/2:n/2-1).'; beta=z.beta+2*pi*orders/z.d;
  kappa=sqrt(beta.^2+z.gamma); weight=2*kappa.*tanh(kappa/2);
  if any(~isfinite(weight)|weight<=0)
    error('I32V2:WallWeight','A required wall trace weight is invalid.');
  end
end

function value=LOCAL_pad(value,n)
  old=size(value,1); if old==n, return; end
  out=complex(zeros(n,size(value,2))); a=(-old/2:old/2-1).'; b=(-n/2:n/2-1).';
  [ok,at]=ismember(a,b); out(at(ok),:)=value(ok,:); value=out;
end

%% ==================== Compact metrics ====================
% Metrics retain only 97-by-97 Grams for each registered axis.

function out=LOCAL_axis(levels,z,weight)
  factors=cell(1,numel(levels));
  for q=1:numel(levels), factors{q}=LOCAL_finest(levels{q},z,weight); end
  names={'internal_plus','internal_minus','value_aligned_left_plus', ...
    'value_aligned_right_plus','value_aligned_left_minus','value_aligned_right_minus'};
  out=struct();
  for j=1:numel(names)
    name=names{j};
    for q=1:3, out.(name).level{q}=factors{q}.(name)'*factors{q}.(name); end
    for q=1:2
      delta=factors{q+1}.(name)-factors{q}.(name); out.(name).difference{q}=delta'*delta;
    end
  end
  n=size(levels{1}.raw_left,1); normal=cell(1,3); value=cell(1,3);
  lift_weight=i32v2_lift_mode_weights('wall',n,128,z);
  for j=1:3
    [left_flux,right_flux]=LOCAL_center_singletons(levels{j},z,n,weight);
    normal{j}=struct('plus',factors{j}.internal_plus, ...
      'minus',factors{j}.internal_minus,'singleton',[left_flux;right_flux]);
    normal{j}.operation_ledger=LOCAL_count_add(levels{j}.operation_ledger, ...
      LOCAL_wall_association_ledger(n,size(z.Gplus,1),size(z.Gplus,2),'normal'));
    [vp,vm,vs]=LOCAL_volume_value_factor(factors{j},lift_weight,z);
    value{j}=struct('plus',vp,'minus',vm,'singleton',vs);
    value{j}.operation_ledger=LOCAL_count_add(levels{j}.operation_ledger, ...
      LOCAL_wall_association_ledger(n,size(z.Gplus,1),size(z.Gplus,2),'value'));
  end
  out.normal=LOCAL_factor_axis(normal);
  out.value=LOCAL_factor_axis(value);
end

function out=LOCAL_factor_axis(levels)
  K=size(levels{1}.plus,2);
  out.level_plus_gram=complex(zeros(K,K,3));
  out.level_minus_gram=complex(zeros(K,K,3));
  out.singleton_squared=zeros(3,1);
  for j=1:3
    out.level_plus_gram(:,:,j)=levels{j}.plus'*levels{j}.plus;
    out.level_minus_gram(:,:,j)=levels{j}.minus'*levels{j}.minus;
    out.singleton_squared(j)=real(levels{j}.singleton'*levels{j}.singleton);
  end
  for j=1:2
    dp=levels{j+1}.plus-levels{j}.plus;
    dm=levels{j+1}.minus-levels{j}.minus;
    ds=levels{j+1}.singleton-levels{j}.singleton;
    out.(sprintf('delta%d%d_plus_gram',j-1,j))=dp'*dp;
    out.(sprintf('delta%d%d_minus_gram',j-1,j))=dm'*dm;
    out.(sprintf('delta%d%d_singleton_squared',j-1,j))=real(ds'*ds);
  end
  out.operation_ledger=LOCAL_axis_operation_ledger(levels,K);
end

function diagnostic=LOCAL_gqp_diagnostic(action,z,trace_weight,n)
  if ~isfield(action,'gqp_piece')
    error('I32V2:WallGQPPieces','A registered wall GQP action omitted its pieces.');
  end
  f=LOCAL_finest(action,z,trace_weight);
  [left_flux,right_flux]=LOCAL_center_singletons(action,z,n,trace_weight);
  lift_weight=i32v2_lift_mode_weights('wall',n,128,z);
  diagnostic.total.normal=struct('plus',f.internal_plus, ...
    'minus',f.internal_minus,'singleton',[left_flux;right_flux]);
  [vp,vm,vs]=LOCAL_volume_value_factor(f,lift_weight,z);
  diagnostic.total.value=struct('plus',vp,'minus',vm,'singleton',vs);
  names={'wall','double','single'};
  for j=1:numel(names)
    name=names{j}; p=action.gqp_piece.(name);
    ql=bsxfun(@times,p.flux_left,1./sqrt(trace_weight));
    qr=bsxfun(@times,p.flux_right,1./sqrt(trace_weight));
    diagnostic.piece.normal.(name)=struct( ...
      'plus',qr*z.Gplus+ql*z.Gplus*z.Pplus, ...
      'minus',ql*z.Gminus+qr*z.Gminus*z.Pminus, ...
      'singleton',[qr*z.Gminus*z.cminus;ql*z.Gplus*z.cplus]);
    v.value_aligned_left_plus=-p.value_left*z.Gplus;
    v.value_aligned_right_plus=-p.value_right*z.Gplus;
    v.value_aligned_left_minus=-p.value_left*z.Gminus;
    v.value_aligned_right_minus=-p.value_right*z.Gminus;
    [vp,vm,vs]=LOCAL_volume_value_factor(v,lift_weight,z);
    diagnostic.piece.value.(name)=struct('plus',vp,'minus',vm,'singleton',vs);
  end
  normal_ledger=LOCAL_wall_association_ledger(n,size(z.Gplus,1),size(z.Gplus,2),'normal');
  value_ledger=LOCAL_wall_association_ledger(n,size(z.Gplus,1),size(z.Gplus,2),'value');
  diagnostic.operation_ledger=LOCAL_count_add(action.operation_ledger,normal_ledger);
  diagnostic.operation_ledger=LOCAL_count_add(diagnostic.operation_ledger,value_ledger);
end

function [plus,minus,singleton]=LOCAL_volume_value_factor(f,weight,z)
  left_plus=bsxfun(@times,f.value_aligned_left_plus,weight);
  right_plus=bsxfun(@times,f.value_aligned_right_plus,weight);
  left_minus=bsxfun(@times,f.value_aligned_left_minus,weight);
  right_minus=bsxfun(@times,f.value_aligned_right_minus,weight);
  plus=[right_plus;left_plus*z.Pplus];
  minus=[left_minus;right_minus*z.Pminus];
  singleton=[left_plus*z.cplus;right_minus*z.cminus];
end

function out=LOCAL_gqp_metrics(proxy,interp,fine,kind)
  high=proxy{1}.total.(kind); out=struct('cap',NaN, ...
    'relative_envelope',NaN,'scale',NaN);
  K=size(high.plus,2);
  out.proxy.delta_plus_grams=complex(zeros(K,K,5));
  out.proxy.delta_minus_grams=complex(zeros(K,K,5));
  out.proxy.singleton_squared=zeros(5,1);
  out.proxy.high_plus_gram=high.plus'*high.plus;
  out.proxy.high_minus_gram=high.minus'*high.minus;
  out.proxy.high_singleton_squared=real(high.singleton'*high.singleton);
  out.proxy.variant_plus_grams=complex(zeros(K,K,5));
  out.proxy.variant_minus_grams=complex(zeros(K,K,5));
  out.proxy.variant_singleton_squared=zeros(5,1);
  for j=1:5
    endpoint=proxy{j+1}.total.(kind);
    dp=endpoint.plus-high.plus;
    dm=endpoint.minus-high.minus;
    ds=endpoint.singleton-high.singleton;
    out.proxy.delta_plus_grams(:,:,j)=dp'*dp;
    out.proxy.delta_minus_grams(:,:,j)=dm'*dm;
    out.proxy.singleton_squared(j)=real(ds'*ds);
    out.proxy.variant_plus_grams(:,:,j)=endpoint.plus'*endpoint.plus;
    out.proxy.variant_minus_grams(:,:,j)=endpoint.minus'*endpoint.minus;
    out.proxy.variant_singleton_squared(j)=real(endpoint.singleton'*endpoint.singleton);
  end
  out.interp.level_plus_grams=complex(zeros(K,K,3));
  out.interp.level_minus_grams=complex(zeros(K,K,3));
  out.interp.singleton_squared=zeros(3,1);
  for j=1:3
    endpoint=interp{j}.total.(kind);
    out.interp.level_plus_grams(:,:,j)=endpoint.plus'*endpoint.plus;
    out.interp.level_minus_grams(:,:,j)=endpoint.minus'*endpoint.minus;
    out.interp.singleton_squared(j)=real(endpoint.singleton'*endpoint.singleton);
  end
  d01p=interp{2}.total.(kind).plus-interp{1}.total.(kind).plus;
  d01m=interp{2}.total.(kind).minus-interp{1}.total.(kind).minus;
  d01s=interp{2}.total.(kind).singleton-interp{1}.total.(kind).singleton;
  d12p=interp{3}.total.(kind).plus-interp{2}.total.(kind).plus;
  d12m=interp{3}.total.(kind).minus-interp{2}.total.(kind).minus;
  d12s=interp{3}.total.(kind).singleton-interp{2}.total.(kind).singleton;
  out.interp.delta01_plus_gram=d01p'*d01p;
  out.interp.delta01_minus_gram=d01m'*d01m;
  out.interp.delta01_singleton_squared=real(d01s'*d01s);
  out.interp.delta12_plus_gram=d12p'*d12p;
  out.interp.delta12_minus_gram=d12m'*d12m;
  out.interp.delta12_singleton_squared=real(d12s'*d12s);
  names={'wall','double','single'}; P=numel(names);
  out.scale_diag.piece_plus_grams=complex(zeros(K,K,P));
  out.scale_diag.piece_minus_grams=complex(zeros(K,K,P));
  out.scale_diag.piece_singleton_norms=zeros(P,1);
  out.scale_fine=out.scale_diag;
  for j=1:P
    name=names{j}; pd=proxy{1}.piece.(kind).(name);
    pf=fine.piece.(kind).(name);
    out.scale_diag.piece_plus_grams(:,:,j)=pd.plus'*pd.plus;
    out.scale_diag.piece_minus_grams(:,:,j)=pd.minus'*pd.minus;
    out.scale_diag.piece_singleton_norms(j)=norm(pd.singleton);
    out.scale_fine.piece_plus_grams(:,:,j)=pf.plus'*pf.plus;
    out.scale_fine.piece_minus_grams(:,:,j)=pf.minus'*pf.minus;
    out.scale_fine.piece_singleton_norms(j)=norm(pf.singleton);
  end
  out.scale_diag.piece_names=names; out.scale_fine.piece_names=names;
  out.operation_ledger=LOCAL_gqp_operation_ledger(proxy,interp,fine,K,kind);
  out.audit=struct('lift_weighted',strcmp(kind,'value'), ...
    'wall_volume_association_applied',strcmp(kind,'value'), ...
    'fullp_association_pending',true, ...
    'endpoint_tail_coordinates_retained_as_grams',true, ...
    'raw_difference_maps_retained',false);
end

function ledger=LOCAL_wall_association_ledger(rows,state_rows,K,kind)
  ledger=LOCAL_count_zero();
  if strcmp(kind,'normal')
    ledger.boundary_factor_cma=4*rows*state_rows*K+ ...
      2*rows*K^2+2*rows*state_rows*K+2*rows*K;
  elseif strcmp(kind,'value')
    ledger.boundary_factor_cma=4*rows*state_rows*K+ ...
      2*rows*K^2+2*rows*K;
  else
    error('I32V2:WallOperationLedger','Unknown wall association kind.');
  end
  ledger.total=ledger.boundary_factor_cma;
end

function ledger=LOCAL_axis_operation_ledger(levels,K)
  ledger=LOCAL_count_zero();
  for j=1:3
    ledger=LOCAL_count_add(ledger,levels{j}.operation_ledger);
  end
  rows_plus=size(levels{1}.plus,1); rows_minus=size(levels{1}.minus,1);
  singleton_rows=numel(levels{1}.singleton);
  ledger.gram_cma=ledger.gram_cma+ ...
    5*(rows_plus+rows_minus)*K^2;
  ledger.factor_comparison=ledger.factor_comparison+ ...
    2*(rows_plus+rows_minus)*K+2*singleton_rows;
  ledger.total=ledger.interpolation_cma+ledger.kernel_phase_multiply+ ...
    ledger.boundary_factor_cma+ledger.gram_cma+ ...
    ledger.factor_comparison+ledger.scalar_arithmetic;
end

function ledger=LOCAL_gqp_operation_ledger(proxy,interp,fine,K,kind)
  ledger=LOCAL_count_zero(); all_diagnostics=[proxy,interp,{fine}];
  for j=1:numel(all_diagnostics)
    ledger=LOCAL_count_add(ledger,all_diagnostics{j}.operation_ledger);
  end
  high=proxy{1}.total.(kind); rows=size(high.plus,1);
  singleton_rows=numel(high.singleton);
  gram_count=2+5*4+3*2+2*2;
  ledger.gram_cma=ledger.gram_cma+gram_count*rows*K^2;
  ledger.factor_comparison=ledger.factor_comparison+ ...
    5*(2*rows*K+singleton_rows)+2*(2*rows*K+singleton_rows);
  piece_names={'wall','double','single'};
  for j=1:numel(piece_names)
    diagnostic_piece=proxy{1}.piece.(kind).(piece_names{j});
    fine_piece=fine.piece.(kind).(piece_names{j});
    ledger.gram_cma=ledger.gram_cma+ ...
      2*size(diagnostic_piece.plus,1)*K^2+2*size(fine_piece.plus,1)*K^2;
  end
  ledger.total=ledger.interpolation_cma+ledger.kernel_phase_multiply+ ...
    ledger.boundary_factor_cma+ledger.gram_cma+ ...
    ledger.factor_comparison+ledger.scalar_arithmetic;
end

function ledger=LOCAL_count_zero()
  ledger=struct('interpolation_cma',0,'boundary_factor_cma',0,'gram_cma',0, ...
    'kernel_phase_multiply',0,'factor_comparison',0, ...
    'scalar_arithmetic',0,'total',0);
end

function out=LOCAL_count_add(out,value)
  names={'interpolation_cma','kernel_phase_multiply','boundary_factor_cma', ...
    'gram_cma', ...
    'factor_comparison','scalar_arithmetic'};
  for j=1:numel(names)
    name=names{j};
    if isfield(value,name), out.(name)=out.(name)+double(value.(name)); end
  end
  out.total=out.interpolation_cma+out.kernel_phase_multiply+ ...
    out.boundary_factor_cma+out.gram_cma+ ...
    out.factor_comparison+out.scalar_arithmetic;
end

%% ==================== Contracts and resources ====================
% No missing scientific parameter receives an implementation default.

function z=LOCAL_inputs(view,g,cfg,resource,circle)
  if ~isstruct(view)||~isfield(view,'data')|| ...
      ~isfield(view.data,'certificate')||~isstruct(g)||~g.available|| ...
      ~isstruct(circle)||~circle.available
    error('I32V2:WallInterface','Certificate, GQP, or circle input is unavailable.');
  end
  z=view.data.certificate;
  required={'khat','R','d','beta','X_L','X_R','M','eta_unit_256', ...
    'xi_left_unit_512','xi_right_unit_512','Gplus','Gminus','Pplus','Pminus', ...
    'cplus','cminus','center_wall_jumps','gamma'};
  if ~all(isfield(z,required))||~all(isfield(cfg,{'wall_levels','circle_levels', ...
      'gqp_interp_levels','boundary_target_panel','boundary_source_panel'}))|| ...
      ~all(isfield(resource,{'start_tic','hard_s','memory_mib_max'}))
    error('I32V2:WallInterface','Required wall interface fields are missing.');
  end
  if any(mod([cfg.wall_levels,cfg.circle_levels],2))||numel(cfg.wall_levels)~=3
    error('I32V2:WallLevels','Wall/circle levels must be registered even triples.');
  end
end

function LOCAL_resource(resource,bytes)
  if toc(resource.start_tic)>resource.hard_s
    error('I32V2:HardTimeLimit','The hard wall time limit was reached.');
  end
  proxy=LOCAL_resource_field(resource,'retained_mib',0)+bytes/2^20+ ...
    LOCAL_resource_field(resource,'cow_mib',0)+ ...
    LOCAL_resource_field(resource,'publication_mib',64);
  if proxy>resource.memory_mib_max
    error('I32V2:HardMemoryLimit','The wall memory proxy exceeded its hard limit.');
  end
end

function value=LOCAL_resource_field(resource,name,fallback)
  value=fallback;
  if isstruct(resource)&&isfield(resource,name)&& ...
      isnumeric(resource.(name))&&isscalar(resource.(name))&& ...
      isfinite(resource.(name))
    value=double(resource.(name));
  end
end

function n=LOCAL_bytes(value), count=numel(value); info=whos('value'); n=info.bytes+0*count; end

function counters=LOCAL_counters()
  counters=struct('density_resolve_count',0,'source_quadrature_refinement_count',6, ...
    'image_sum_calls',0,'rayleigh_trial_eval_calls',0,'old_ecap_calls',0, ...
    'interpft_calls',0);
end

function progress=LOCAL_progress(family)
  progress=struct('family',family,'stage','initialized', ...
    'completed_actions',0,'completed_panels',0,'completed_rows',0, ...
    'completed_target_levels',zeros(1,0), ...
    'completed_source_levels',zeros(1,0), ...
    'completed_action_summaries',{{}},'local_peak_mib',0, ...
    'operation_ledger',LOCAL_count_zero(),'complete',false, ...
    'first_blocker','','incomplete_dense_returned',false);
end

function checkpoint=LOCAL_action_checkpoint(ns_circle,ns_wall,nt, ...
    field_level,variant,collect_gqp)
  checkpoint=struct('circle_source_count',ns_circle, ...
    'wall_source_count',ns_wall,'target_count',nt, ...
    'field_level',field_level.n,'variant_id',variant, ...
    'collect_gqp',logical(collect_gqp),'completed_panels',0, ...
    'completed_rows',0,'local_peak_mib',0,'value_fro_squared',0, ...
    'normal_fro_squared',0,'operation_ledger',LOCAL_count_zero(), ...
    'scalar_norms',struct('raw_left',NaN,'raw_right',NaN, ...
    'flux_left',NaN,'flux_right',NaN,'recombination',NaN), ...
    'complete',false,'first_blocker','', ...
    'incomplete_dense_returned',false);
end

function progress=LOCAL_absorb_action(progress,checkpoint,axis_name,level_index)
  summary=checkpoint;
  summary.axis=axis_name;
  summary.level_index=level_index;
  progress.stage=[axis_name,' action'];
  progress.completed_panels=progress.completed_panels+checkpoint.completed_panels;
  progress.completed_rows=progress.completed_rows+checkpoint.completed_rows;
  progress.local_peak_mib=max(progress.local_peak_mib,checkpoint.local_peak_mib);
  progress.operation_ledger=LOCAL_count_add(progress.operation_ledger, ...
    checkpoint.operation_ledger);
  progress.completed_action_summaries{end+1}=summary;
  if checkpoint.complete
    progress.completed_actions=progress.completed_actions+1;
    if strcmp(axis_name,'target')
      progress.completed_target_levels(end+1)=level_index;
    elseif strcmp(axis_name,'source')
      progress.completed_source_levels(end+1)=level_index;
    end
  end
end

function memory=LOCAL_memory(data,resource,measured_local_peak_mib)
  count=numel(data); info=whos('data'); mib=(info.bytes+0*count)/2^20;
  panel_mib=40*128*256*16/2^20;
  entry=LOCAL_resource_field(resource,'retained_mib',0);
  cow=LOCAL_resource_field(resource,'cow_mib',0);
  publication=LOCAL_resource_field(resource,'publication_mib',64);
  local_peak=max([mib,measured_local_peak_mib,mib+panel_mib]);
  memory=struct('entry_mib',entry,'local_peak_mib',local_peak, ...
    'retained_mib',mib, ...
    'cow_mib',cow,'publication_mib',publication, ...
    'proxy_mib',entry+local_peak+cow+publication, ...
    'largest_object','finest wall factor','cleared_objects', ...
    {{'raw wall target samples after Fourier alignment', ...
    'source/target panels after each streamed product', ...
    'coarse/common-grid aligned factors after endpoint Grams', ...
    'proxy/interpolation raw actions after compact GQP ledgers'}});
end

function memory=LOCAL_partial_memory(out,resource,measured_local_peak_mib)
  count=numel(out); info=whos('out'); retained=(info.bytes+0*count)/2^20;
  entry=LOCAL_resource_field(resource,'retained_mib',0);
  cow=LOCAL_resource_field(resource,'cow_mib',0);
  publication=LOCAL_resource_field(resource,'publication_mib',64);
  local_peak=max(retained,measured_local_peak_mib);
  memory=struct('entry_mib',entry,'local_peak_mib',local_peak, ...
    'retained_mib',retained,'cow_mib',cow, ...
    'publication_mib',publication, ...
    'proxy_mib',entry+local_peak+cow+publication, ...
    'largest_object','compact wall progress checkpoint', ...
    'cleared_objects',{{'incomplete wall action', ...
    'incomplete source/target panels','raw GQP piece samples'}});
end

function out=LOCAL_empty()
  out=struct('schema','I32V2_WALL_MODULE_V1','status','INITIALIZED', ...
    'available',false,'warnings',{{}},'first_blocker','', ...
    'audit',struct(),'counters',LOCAL_counters(),'memory',struct(),'data',struct());
end

function id=LOCAL_identifier(err)
  id=err.identifier; if isempty(id), id='I32V2:UNIDENTIFIED_BLOCKER'; end
end
