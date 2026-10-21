function out = i32v2_circle_module(view,g,cfg,resource)
%I32V2_CIRCLE_MODULE Evaluate the frozen trial on the material circle.
% Purpose:
%   Recompute circle value and normal transmission defects for the same
%   finite Nystrom densities using rectangular Kress self action and the
%   MFS-only GQP gateway.
% Input:
%   view     - Authenticated i32v2_computation_view return.
%   g        - Compact i32v2_gqp_module return.
%   cfg      - Preregistered v2 configuration.
%   resource - Resource gate with start_tic/soft_s/hard_s/memory_mib_max.
% Output:
%   out.data.finest - normal/value plus/minus factors at the finest circle
%                     target bandwidth.
%   out.data.axis_metrics - Compact target/source Gram diagnostics.
%   out.data.gqp_metrics  - Compact proxy/interpolation diagnostic Grams.
% Main algorithm:
%   Prolong the same endpoint-grid circle density and frozen wall density by
%   direct trigonometric evaluation.  Apply literal rectangular Kress
%   Muller differences for the free primary, add the smooth MFS remainder,
%   and stream positive-distance wall-to-circle actions.
% Notes:
%   No density solve, image sum, Rayleigh field, modal Green multiplier, or
%   old e-cap evaluator is called.

  timer=tic; out=LOCAL_empty(); local_peak_mib=0;
  partial_metrics=struct();
  progress=LOCAL_progress('circle');
  target=cell(1,3); source=cell(1,3); proxy=cell(1,6); interp=cell(1,3);
  out.audit.symbol_ledger=struct( ...
    'tau','frozen circle double-layer density', ...
    'zeta','frozen circle coordinate zeta=-sigma', ...
    'value_defect','exterior minus interior Dirichlet trace', ...
    'normal_defect','exterior minus interior material-normal trace', ...
    'D_X','augmented full-P difference through N=32 with endpoint tails', ...
    'operation_ledger','typed executed complex multiply-add/comparison counts', ...
    'normal_plus','normal defect composed with Gplus', ...
    'normal_minus','normal defect composed with Gminus', ...
    'source_axis_counts','paired circle/wall source counts at fixed finest targets', ...
    'progress_checkpoint','publication-safe compact boundary-action progress');
  try
    view_audit=i32v2_validate_computation_view(view,cfg,'circle');
    z=LOCAL_inputs(view,g,cfg,resource); levels=double(cfg.circle_levels(:).');
    out.audit.computation_view=view_audit;
    wall_levels=double(cfg.wall_levels(:).');
    out.audit.source_axis_counts=[levels(:),wall_levels(:)];
    progress.source_axis_counts=out.audit.source_axis_counts;
    nf=levels(end); wall_source=wall_levels(end);
    weight_fine=LOCAL_circle_weight(z,nf,cfg.levels.riccati(end));
    level=struct('n',257,'include_primary',false);
    for j=1:3
      LOCAL_resource(resource,0);
      [target{j},action_progress,action_error]=LOCAL_action( ...
        z,g,cfg,resource,nf,wall_source,levels(j),level,0,nf, ...
        weight_fine,j==3);
      progress=LOCAL_absorb_action(progress,action_progress,'target',j);
      local_peak_mib=max(local_peak_mib,action_progress.local_peak_mib);
      if ~isempty(action_error), rethrow(action_error); end
      [source{j},action_progress,action_error]=LOCAL_action( ...
        z,g,cfg,resource,levels(j),wall_levels(j),nf,level,0,nf, ...
        weight_fine,false);
      progress=LOCAL_absorb_action(progress,action_progress,'source',j);
      local_peak_mib=max(local_peak_mib,action_progress.local_peak_mib);
      if ~isempty(action_error), rethrow(action_error); end
      outer=whos('target','source');
      local_peak_mib=max(local_peak_mib,sum([outer.bytes])/2^20+ ...
        max(target{j}.audit.local_peak_mib,source{j}.audit.local_peak_mib));
    end
    final=target{3};
    data.finest=struct('normal_plus',final.normal_plus, ...
      'normal_minus',final.normal_minus,'value_plus',final.value_plus, ...
      'value_minus',final.value_minus);
    data.axis_metrics=struct('target',LOCAL_axis(target,z,nf), ...
      'source',LOCAL_axis(source,z,nf));
    data.axis_metrics.riccati=LOCAL_riccati_axis(final,z,cfg,nf);
    clear target source
    data.ordinary_weights=struct('family','circle shifted-trace Fourier', ...
      'order_min',-nf/2,'order_max',nf/2-1,'order_count',nf, ...
      'radius',z.R,'trace_weight_min',min(weight_fine), ...
      'trace_weight_max',max(weight_fine), ...
      'all_retained_modes_enter_residual',true);
    partial_metrics=struct('stage','axis metrics complete', ...
      'axis_metrics',data.axis_metrics, ...
      'ordinary_weights',data.ordinary_weights);
    out.data.partial_metrics=partial_metrics;
    diag_n=double(cfg.circle_levels(1)); wall_diag=double(cfg.wall_levels(1));
    weight_diag=LOCAL_circle_weight(z,diag_n,cfg.levels.riccati(end));
    for v=0:5
      [action,action_progress,action_error]=LOCAL_action( ...
        z,g,cfg,resource,diag_n,wall_diag,diag_n, ...
        struct('n',129,'include_primary',false),v,diag_n,weight_diag,true);
      progress=LOCAL_absorb_action(progress,action_progress,'proxy',v+1);
      local_peak_mib=max(local_peak_mib,action_progress.local_peak_mib);
      if ~isempty(action_error), rethrow(action_error); end
      proxy{v+1}=LOCAL_gqp_diagnostic(action,z,diag_n);
      local_peak_mib=max(local_peak_mib,action.audit.local_peak_mib);
      outer=whos('data','proxy','action');
      local_peak_mib=max(local_peak_mib,sum([outer.bytes])/2^20+ ...
        action.audit.local_peak_mib);
      clear action
    end
    for j=1:3
      [action,action_progress,action_error]=LOCAL_action( ...
        z,g,cfg,resource,diag_n,wall_diag,diag_n, ...
        struct('n',cfg.gqp_interp_levels(j),'include_primary',false), ...
        0,diag_n,weight_diag,true);
      progress=LOCAL_absorb_action(progress,action_progress,'interpolation',j);
      local_peak_mib=max(local_peak_mib,action_progress.local_peak_mib);
      if ~isempty(action_error), rethrow(action_error); end
      interp{j}=LOCAL_gqp_diagnostic(action,z,diag_n);
      local_peak_mib=max(local_peak_mib,action.audit.local_peak_mib);
      outer=whos('data','proxy','interp','action');
      local_peak_mib=max(local_peak_mib,sum([outer.bytes])/2^20+ ...
        action.audit.local_peak_mib);
      clear action
    end
    fine_gqp=LOCAL_gqp_diagnostic(final,z,nf);
    data.gqp_metrics=LOCAL_gqp_metrics(proxy,interp,fine_gqp,'normal');
    data.value_gqp_metrics=LOCAL_gqp_metrics(proxy,interp,fine_gqp,'value');
    clear proxy interp fine_gqp
    data.gqp_metrics.diagnostic_circle_nodes=diag_n;
    data.gqp_metrics.diagnostic_wall_nodes=wall_diag;
    data.gqp_metrics.mapping_label= ...
      'GQP_COARSE_TO_FINE_COMPONENT_MAPPING_EMPIRICAL';
    data.value_gqp_metrics.diagnostic_circle_nodes=diag_n;
    data.value_gqp_metrics.diagnostic_wall_nodes=wall_diag;
    data.value_gqp_metrics.mapping_label= ...
      'GQP_COARSE_TO_FINE_COMPONENT_MAPPING_EMPIRICAL';
    data.value_gqp_metrics.component_destination='V_AFTER_FROZEN_LIFT_ONLY';
    partial_metrics.stage='GQP metrics complete';
    partial_metrics.gqp_metrics=data.gqp_metrics;
    partial_metrics.value_gqp_metrics=data.value_gqp_metrics;
    out.data.partial_metrics=partial_metrics;
    out.data=data; out.available=true; out.status='COMPLETE';
    out.audit.fixed_trial=true; out.audit.density_resolve_count=0;
    out.audit.finest_semantics=struct( ...
      'value','unweighted exterior-minus-interior physical midpoint samples', ...
      'normal','L2(ds) Fourier coefficients divided by sqrt(circle trace weight)', ...
      'value_gqp_destination','V after frozen lifting only', ...
      'normal_gqp_destination','Gamma only');
    out.audit.image_sum_code_path_zero=true;
    out.audit.rayleigh_trial_code_path_zero=true;
    out.audit.source_axis_semantics= ...
      'paired full-boundary circle/wall source refinement at finest circle targets';
    progress.stage='complete'; progress.complete=true;
    out.audit.progress_checkpoint=progress;
    out.audit.self_quadrature=[ ...
      'Rectangular/off-grid Kress split for free S,D,D*,T_out-T_in; ', ...
      'smooth MFS remainder by streamed trapezoid action with explicit jumps.'];
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
    clear target source proxy interp action final data
  end
  if ~isfield(out.memory,'proxy_mib')
    out.memory=LOCAL_partial_memory(out,resource,local_peak_mib);
  end
  out.audit.elapsed_s=toc(timer);
end

%% ==================== Complete circle action ====================
% The action returns only modal factors aligned to the requested common size.

function [a,checkpoint,action_error]=LOCAL_action( ...
    z,g,cfg,resource,ns,nw,nt,field_level,variant,ncommon,weight,collect_gqp)
  action_error=[]; local_peak_bytes=0;
  operation_ledger=LOCAL_count_zero();
  checkpoint=LOCAL_action_checkpoint(ns,nw,nt,field_level,variant,collect_gqp);
  try
  ns=double(ns); nw=double(nw); nt=double(nt); ncommon=double(ncommon);
  [tau,zeta,tau_s,theta_s,source_density_audit]= ...
    i32v2_circle_density_grid(z,ns);
  [tau_t,zeta_t,~,theta_t,target_density_audit]= ...
    i32v2_circle_density_grid(z,nt);
  operation_ledger.boundary_factor_cma= ...
    operation_ledger.boundary_factor_cma+ ...
    source_density_audit.complex_multiply_add_count+ ...
    target_density_audit.complex_multiply_add_count;
  src=z.R*[cos(theta_s).';sin(theta_s).'];
  trg=z.R*[cos(theta_t).';sin(theta_t).'];
  nsn=[cos(theta_s).';sin(theta_s).']; ntn=[cos(theta_t).';sin(theta_t).'];
  value=tau_t; normal=zeta_t; tp=cfg.boundary_target_panel;
  if collect_gqp
    names={'wall','double','single'};
    for q=1:numel(names)
      gqp_value.(names{q})=complex(zeros(nt,size(tau,2)));
      gqp_normal.(names{q})=complex(zeros(nt,size(tau,2)));
    end
  end
  for first=1:tp:nt
    last=min(nt,first+tp-1); ids=first:last;
    LOCAL_resource(resource,LOCAL_bytes(value)+ ...
      40*numel(ids)*cfg.boundary_source_panel*16);
    vf=complex(zeros(numel(ids),size(tau,2))); nf=vf;
    free_piece=struct('value_double',vf,'value_single',vf, ...
      'normal_double',vf,'normal_single',vf);
    for source_first=1:cfg.boundary_source_panel:ns
      source_last=min(ns,source_first+cfg.boundary_source_panel-1);
      source_ids=source_first:source_last;
      Rw=i32v2_rect_kress_weights(theta_s(source_ids),theta_t(ids), ...
        ns,source_ids);
      [vf_block,nf_block,piece_block]=i32v2_circle_free_action(z.khat, ...
        z.khat*sqrt(double(z.rho_disk)),z.R,theta_s(source_ids), ...
        theta_t(ids),Rw,tau(source_ids,:),zeta(source_ids,:), ...
        tau_s(source_ids,:),ns);
      vf=vf+vf_block; nf=nf+nf_block;
      free_piece.value_double=free_piece.value_double+piece_block.value_double;
      free_piece.value_single=free_piece.value_single+piece_block.value_single;
      free_piece.normal_double=free_piece.normal_double+piece_block.normal_double;
      free_piece.normal_single=free_piece.normal_single+piece_block.normal_single;
      operation_ledger.boundary_factor_cma= ...
        operation_ledger.boundary_factor_cma+ ...
        10*numel(ids)*numel(source_ids)*size(tau,2);
    end
    [vq,nq,proxy_piece]=i32v2_circle_proxy_action(g,src,trg(:,ids), ...
      nsn,ntn(:,ids),tau,zeta,z.R*2*pi/ns,field_level,variant, ...
      cfg.boundary_source_panel);
    operation_ledger=LOCAL_count_add(operation_ledger,proxy_piece.audit.operation_ledger);
    [vw,nwq,wall_ledger]=i32v2_circle_wall_action( ...
      z,g,cfg,trg(:,ids),ntn(:,ids),nw,field_level,variant);
    operation_ledger=LOCAL_count_add(operation_ledger,wall_ledger);
    value(ids,:)=value(ids,:)+vf+vq+vw;
    normal(ids,:)=normal(ids,:)+nf+nq+nwq;
    if collect_gqp
      gqp_value.double(ids,:)=free_piece.value_double+proxy_piece.value_double;
      gqp_value.single(ids,:)=free_piece.value_single+proxy_piece.value_single;
      gqp_value.wall(ids,:)=vw;
      gqp_normal.double(ids,:)=free_piece.normal_double+proxy_piece.normal_double;
      gqp_normal.single(ids,:)=free_piece.normal_single+proxy_piece.normal_single;
      gqp_normal.wall(ids,:)=nwq;
    end
    probe=whos('tau','zeta','tau_s','tau_t','zeta_t','theta_s','theta_t', ...
      'src','trg','nsn','ntn','value','normal','gqp_value','gqp_normal', ...
      'vf','nf','free_piece','Rw','vf_block','nf_block','piece_block', ...
      'vq','nq','proxy_piece','vw','nwq');
    local_peak_bytes=max(local_peak_bytes,sum([probe.bytes]));
    checkpoint.completed_panels=checkpoint.completed_panels+1;
    checkpoint.completed_rows=last;
    checkpoint.local_peak_mib=local_peak_bytes/2^20;
    checkpoint.value_fro_squared=checkpoint.value_fro_squared+norm(value(ids,:),'fro')^2;
    checkpoint.normal_fro_squared=checkpoint.normal_fro_squared+norm(normal(ids,:),'fro')^2;
    checkpoint.operation_ledger=operation_ledger;
    LOCAL_resource(resource,local_peak_bytes);
  end
  vc=LOCAL_circle_coeff(value,z.R,ncommon); nc=LOCAL_circle_coeff(normal,z.R,ncommon);
  weighted=bsxfun(@times,nc,1./sqrt(weight));
  a=struct('value_plus',value*z.Gplus,'value_minus',value*z.Gminus, ...
    'value_aligned_plus',vc*z.Gplus,'value_aligned_minus',vc*z.Gminus, ...
    'normal_aligned_plus',nc*z.Gplus,'normal_aligned_minus',nc*z.Gminus, ...
    'normal_plus',weighted*z.Gplus,'normal_minus',weighted*z.Gminus);
  K=size(z.Gplus,2); state_rows=size(z.Gplus,1);
  operation_ledger.boundary_factor_cma=operation_ledger.boundary_factor_cma+ ...
    2*(size(value,1)+size(vc,1)+size(nc,1)+size(weighted,1))*state_rows*K;
  if collect_gqp
    for q=1:numel(names)
      name=names{q}; vc_piece=LOCAL_circle_coeff(gqp_value.(name),z.R,ncommon);
      nc_piece=LOCAL_circle_coeff(gqp_normal.(name),z.R,ncommon);
      nc_piece=bsxfun(@times,nc_piece,1./sqrt(weight));
      a.gqp_piece.value.(name)=struct('plus',vc_piece*z.Gplus, ...
        'minus',vc_piece*z.Gminus);
      a.gqp_piece.normal.(name)=struct('plus',nc_piece*z.Gplus, ...
        'minus',nc_piece*z.Gminus);
      operation_ledger.boundary_factor_cma=operation_ledger.boundary_factor_cma+ ...
        2*(size(vc_piece,1)+size(nc_piece,1))*state_rows*K;
    end
  end
  operation_ledger.total=operation_ledger.interpolation_cma+ ...
    operation_ledger.kernel_phase_multiply+ ...
    operation_ledger.boundary_factor_cma+operation_ledger.factor_comparison+ ...
    operation_ledger.scalar_arithmetic;
  probe=whos('value','normal','vc','nc','weighted','gqp_value','gqp_normal','a');
  local_peak_bytes=max(local_peak_bytes,sum([probe.bytes]));
  a.operation_ledger=operation_ledger;
  a.audit=struct('local_peak_mib',local_peak_bytes/2^20, ...
    'cleared_at_return',{{'source/target panels','raw GQP piece samples'}});
  checkpoint.complete=true;
  checkpoint.local_peak_mib=local_peak_bytes/2^20;
  checkpoint.operation_ledger=operation_ledger;
  checkpoint.scalar_norms=struct('value_plus',norm(a.value_plus,'fro'), ...
    'value_minus',norm(a.value_minus,'fro'), ...
    'normal_plus',norm(a.normal_plus,'fro'), ...
    'normal_minus',norm(a.normal_minus,'fro'));
  catch err
    action_error=err; a=struct();
    checkpoint.first_blocker=LOCAL_identifier(err);
    checkpoint.local_peak_mib=max(checkpoint.local_peak_mib,local_peak_bytes/2^20);
    checkpoint.operation_ledger=operation_ledger;
    checkpoint.incomplete_dense_returned=false;
    clear tau zeta tau_s tau_t zeta_t value normal gqp_value gqp_normal
    clear vf nf free_piece Rw vf_block nf_block piece_block vq nq proxy_piece vw nwq
  end
end

%% ==================== Density and Fourier maps ====================
% Trigonometric prolongation changes only source quadrature, never density.

function coeff=LOCAL_circle_coeff(samples,R,ncommon)
  n=size(samples,1); ell=(-n/2:n/2-1).';
  coeff=fftshift(fft(samples,[],1),1)/n;
  coeff=bsxfun(@times,sqrt(2*pi*R)*exp(-1i*ell*pi/n),coeff);
  if n~=ncommon
    padded=complex(zeros(ncommon,size(coeff,2))); all=(-ncommon/2:ncommon/2-1).';
    [ok,at]=ismember(ell,all); padded(at(ok),:)=coeff(ok,:); coeff=padded;
  end
end

%% ==================== Compact metrics ====================
% Only finest factors and 97-by-97 Gram records survive module return.

function out=LOCAL_axis(levels,z,n)
  names={'normal_plus','normal_minus','value_aligned_plus','value_aligned_minus'}; out=struct();
  for j=1:numel(names)
    name=names{j};
    for q=1:3, out.(name).level{q}=levels{q}.(name)'*levels{q}.(name); end
    for q=1:2
      delta=levels{q+1}.(name)-levels{q}.(name);
      out.(name).difference{q}=delta'*delta;
    end
  end
  out.normal=LOCAL_normal_axis(levels);
  lift_weight=i32v2_lift_mode_weights('circle',n,128,z);
  value=cell(1,3);
  for j=1:3
    value{j}.plus=bsxfun(@times,levels{j}.value_aligned_plus,lift_weight);
    value{j}.minus=bsxfun(@times,levels{j}.value_aligned_minus,lift_weight);
    value{j}.operation_ledger=levels{j}.operation_ledger;
  end
  out.value=LOCAL_factor_axis(value);
end

function out=LOCAL_normal_axis(levels)
  K=size(levels{1}.normal_plus,2);
  out.level_plus_gram=complex(zeros(K,K,3));
  out.level_minus_gram=complex(zeros(K,K,3));
  out.singleton_squared=zeros(3,1);
  for j=1:3
    out.level_plus_gram(:,:,j)=levels{j}.normal_plus'*levels{j}.normal_plus;
    out.level_minus_gram(:,:,j)=levels{j}.normal_minus'*levels{j}.normal_minus;
  end
  for j=1:2
    dp=levels{j+1}.normal_plus-levels{j}.normal_plus;
    dm=levels{j+1}.normal_minus-levels{j}.normal_minus;
    out.(sprintf('delta%d%d_plus_gram',j-1,j))=dp'*dp;
    out.(sprintf('delta%d%d_minus_gram',j-1,j))=dm'*dm;
    out.(sprintf('delta%d%d_singleton_squared',j-1,j))=0;
  end
  out.operation_ledger=LOCAL_axis_operation_ledger(levels, ...
    size(levels{1}.normal_plus,1),K,false);
end

function out=LOCAL_factor_axis(levels)
  K=size(levels{1}.plus,2);
  out.level_plus_gram=complex(zeros(K,K,3));
  out.level_minus_gram=complex(zeros(K,K,3));
  out.singleton_squared=zeros(3,1);
  for j=1:3
    out.level_plus_gram(:,:,j)=levels{j}.plus'*levels{j}.plus;
    out.level_minus_gram(:,:,j)=levels{j}.minus'*levels{j}.minus;
  end
  for j=1:2
    dp=levels{j+1}.plus-levels{j}.plus;
    dm=levels{j+1}.minus-levels{j}.minus;
    out.(sprintf('delta%d%d_plus_gram',j-1,j))=dp'*dp;
    out.(sprintf('delta%d%d_minus_gram',j-1,j))=dm'*dm;
    out.(sprintf('delta%d%d_singleton_squared',j-1,j))=0;
  end
  out.operation_ledger=LOCAL_axis_operation_ledger(levels, ...
    size(levels{1}.plus,1),K,false);
end

function out=LOCAL_riccati_axis(action,z,cfg,n)
  steps=double(cfg.levels.riccati(:).'); factors=cell(1,3);
  for j=1:3
    weight=LOCAL_circle_weight(z,n,steps(j));
    factors{j}.plus=bsxfun(@times,action.normal_aligned_plus,1./sqrt(weight));
    factors{j}.minus=bsxfun(@times,action.normal_aligned_minus,1./sqrt(weight));
  end
  names={'plus','minus'}; out=struct('steps',steps);
  for q=1:2
    name=names{q};
    for j=1:3
      out.(['normal_',name]).level{j}=factors{j}.(name)'*factors{j}.(name);
    end
    for j=1:2
      delta=factors{j+1}.(name)-factors{j}.(name);
      out.(['normal_',name]).difference{j}=delta'*delta;
    end
  end
  factors{1}.operation_ledger=action.operation_ledger;
  factors{2}.operation_ledger=action.operation_ledger;
  factors{3}.operation_ledger=action.operation_ledger;
  out.operation_ledger=LOCAL_axis_operation_ledger(factors,n,size(z.Gplus,2),false);
end

function diagnostic=LOCAL_gqp_diagnostic(action,z,n)
  if ~isfield(action,'gqp_piece')
    error('I32V2:CircleGQPPieces','A registered circle GQP action omitted its pieces.');
  end
  lift_weight=i32v2_lift_mode_weights('circle',n,128,z);
  diagnostic.total.normal=struct('plus',action.normal_plus, ...
    'minus',action.normal_minus);
  diagnostic.total.value=struct( ...
    'plus',bsxfun(@times,action.value_aligned_plus,lift_weight), ...
    'minus',bsxfun(@times,action.value_aligned_minus,lift_weight));
  names={'wall','double','single'};
  for j=1:numel(names)
    name=names{j};
    diagnostic.piece.normal.(name)=action.gqp_piece.normal.(name);
    diagnostic.piece.value.(name)=struct( ...
      'plus',bsxfun(@times,action.gqp_piece.value.(name).plus,lift_weight), ...
      'minus',bsxfun(@times,action.gqp_piece.value.(name).minus,lift_weight));
  end
  diagnostic.operation_ledger=action.operation_ledger;
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
  out.proxy.high_singleton_squared=0;
  out.proxy.variant_plus_grams=complex(zeros(K,K,5));
  out.proxy.variant_minus_grams=complex(zeros(K,K,5));
  out.proxy.variant_singleton_squared=zeros(5,1);
  for j=1:5
    variant=proxy{j+1}.total.(kind);
    dp=variant.plus-high.plus;
    dm=variant.minus-high.minus;
    out.proxy.delta_plus_grams(:,:,j)=dp'*dp;
    out.proxy.delta_minus_grams(:,:,j)=dm'*dm;
    out.proxy.variant_plus_grams(:,:,j)=variant.plus'*variant.plus;
    out.proxy.variant_minus_grams(:,:,j)=variant.minus'*variant.minus;
  end
  out.interp.level_plus_grams=complex(zeros(K,K,3));
  out.interp.level_minus_grams=complex(zeros(K,K,3));
  out.interp.singleton_squared=zeros(3,1);
  for j=1:3
    endpoint=interp{j}.total.(kind);
    out.interp.level_plus_grams(:,:,j)=endpoint.plus'*endpoint.plus;
    out.interp.level_minus_grams(:,:,j)=endpoint.minus'*endpoint.minus;
  end
  d01p=interp{2}.total.(kind).plus-interp{1}.total.(kind).plus;
  d01m=interp{2}.total.(kind).minus-interp{1}.total.(kind).minus;
  d12p=interp{3}.total.(kind).plus-interp{2}.total.(kind).plus;
  d12m=interp{3}.total.(kind).minus-interp{2}.total.(kind).minus;
  out.interp.delta01_plus_gram=d01p'*d01p;
  out.interp.delta01_minus_gram=d01m'*d01m;
  out.interp.delta01_singleton_squared=0;
  out.interp.delta12_plus_gram=d12p'*d12p;
  out.interp.delta12_minus_gram=d12m'*d12m;
  out.interp.delta12_singleton_squared=0;
  names={'wall','double','single'}; P=numel(names);
  out.scale_diag.piece_plus_grams=complex(zeros(K,K,P));
  out.scale_diag.piece_minus_grams=complex(zeros(K,K,P));
  out.scale_diag.piece_singleton_norms=zeros(P,1);
  out.scale_fine=out.scale_diag;
  for j=1:P
    name=names{j};
    pd=proxy{1}.piece.(kind).(name);
    pf=fine.piece.(kind).(name);
    out.scale_diag.piece_plus_grams(:,:,j)=pd.plus'*pd.plus;
    out.scale_diag.piece_minus_grams(:,:,j)=pd.minus'*pd.minus;
    out.scale_fine.piece_plus_grams(:,:,j)=pf.plus'*pf.plus;
    out.scale_fine.piece_minus_grams(:,:,j)=pf.minus'*pf.minus;
  end
  out.scale_diag.piece_names=names;
  out.scale_fine.piece_names=names;
  out.operation_ledger=LOCAL_gqp_operation_ledger(proxy,interp,fine,K,kind);
  out.audit=struct('lift_weighted',strcmp(kind,'value'), ...
    'fullp_association_pending',true,'singleton_identically_zero',true, ...
    'endpoint_tail_coordinates_retained_as_grams',true, ...
    'raw_difference_maps_retained',false);
end

function ledger=LOCAL_axis_operation_ledger(levels,rows,K,has_singleton)
  ledger=LOCAL_count_zero();
  for j=1:3
    ledger=LOCAL_count_add(ledger,levels{j}.operation_ledger);
  end
  ledger.gram_cma=ledger.gram_cma+10*rows*K^2;
  ledger.factor_comparison=ledger.factor_comparison+4*rows*K;
  if has_singleton
    singleton_rows=numel(levels{1}.singleton);
    ledger.factor_comparison=ledger.factor_comparison+2*singleton_rows;
  end
  ledger.total=ledger.interpolation_cma+ledger.kernel_phase_multiply+ ...
    ledger.boundary_factor_cma+ledger.gram_cma+ ...
    ledger.factor_comparison+ledger.scalar_arithmetic;
end

function ledger=LOCAL_gqp_operation_ledger(proxy,interp,fine,K,kind)
  ledger=LOCAL_count_zero();
  all_diagnostics=[proxy,interp,{fine}];
  for j=1:numel(all_diagnostics)
    ledger=LOCAL_count_add(ledger,all_diagnostics{j}.operation_ledger);
  end
  high=proxy{1}.total.(kind); rows=size(high.plus,1);
  gram_count=2+5*4+3*2+2*2;
  comparison_count=5*2*rows*K+2*2*rows*K;
  piece_names={'wall','double','single'};
  for j=1:numel(piece_names)
    diagnostic_piece=proxy{1}.piece.(kind).(piece_names{j});
    fine_piece=fine.piece.(kind).(piece_names{j});
    ledger.gram_cma=ledger.gram_cma+ ...
      2*size(diagnostic_piece.plus,1)*K^2+2*size(fine_piece.plus,1)*K^2;
  end
  ledger.gram_cma=ledger.gram_cma+gram_count*rows*K^2;
  ledger.factor_comparison=ledger.factor_comparison+comparison_count;
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

function weight=LOCAL_circle_weight(z,n,steps)
  if ~(isscalar(steps)&&isfinite(steps)&&steps>=1&&steps==round(steps))
    error('I32V2:CircleWeightConfig','A positive Riccati step count is required.');
  end
  ell=(-n/2:n/2-1).';
  tin=log(z.R-z.delta_c); t0=log(z.R); tout=log(z.R+z.delta_c);
  pin=LOCAL_rk4(zeros(size(ell)),tin,t0,steps,ell,z.gamma*z.rho_disk);
  pout=LOCAL_rk4(zeros(size(ell)),tout,t0,steps,ell,z.gamma);
  weight=(pin-pout)/z.R;
  if any(~isfinite(weight)|weight<=0)
    error('I32V2:CircleWeight','A required circle trace weight is invalid.');
  end
end

function p=LOCAL_rk4(p,t0,t1,steps,ell,alpha)
  h=(t1-t0)/steps; t=t0;
  for j=1:steps
    k1=ell.^2+alpha*exp(2*t)-p.^2;
    q=p+h*k1/2; k2=ell.^2+alpha*exp(2*(t+h/2))-q.^2;
    q=p+h*k2/2; k3=ell.^2+alpha*exp(2*(t+h/2))-q.^2;
    q=p+h*k3; k4=ell.^2+alpha*exp(2*(t+h))-q.^2;
    p=p+h*(k1+2*k2+2*k3+k4)/6; t=t+h;
  end
end

%% ==================== Contracts and resources ====================
% These helpers reject interface drift and keep all forbidden counters zero.

function z=LOCAL_inputs(view,g,cfg,resource)
  if ~isstruct(view)||~isfield(view,'data')|| ...
      ~isfield(view.data,'certificate')||~isstruct(g)||~g.available
    error('I32V2:CircleInterface','Certificate or GQP input is unavailable.');
  end
  z=view.data.certificate;
  required={'khat','gamma','rho_disk','R','d','beta','X_L','X_R','delta_c','eta_unit_256', ...
    'xi_left_unit_512','xi_right_unit_512','Gplus','Gminus'};
  if ~all(isfield(z,required))||~all(isfield(cfg,{'circle_levels','wall_levels', ...
      'gqp_interp_levels','boundary_target_panel','boundary_source_panel'}))|| ...
      ~all(isfield(resource,{'start_tic','hard_s','memory_mib_max'}))
    error('I32V2:CircleInterface','Required circle interface fields are missing.');
  end
  if any(mod([cfg.circle_levels,cfg.wall_levels],2))||numel(cfg.circle_levels)~=3
    error('I32V2:CircleLevels','Circle/wall levels must be the registered even triples.');
  end
end

function LOCAL_resource(resource,bytes)
  if toc(resource.start_tic)>resource.hard_s
    error('I32V2:HardTimeLimit','The hard circle time limit was reached.');
  end
  proxy=LOCAL_resource_field(resource,'retained_mib',0)+bytes/2^20+ ...
    LOCAL_resource_field(resource,'cow_mib',0)+ ...
    LOCAL_resource_field(resource,'publication_mib',64);
  if proxy>resource.memory_mib_max
    error('I32V2:HardMemoryLimit','The circle memory proxy exceeded its hard limit.');
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
    'scalar_norms',struct('value_plus',NaN,'value_minus',NaN, ...
    'normal_plus',NaN,'normal_minus',NaN),'complete',false, ...
    'first_blocker','','incomplete_dense_returned',false);
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
    'largest_object','finest circle factor','cleared_objects', ...
    {{'raw circle target samples after Fourier alignment', ...
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
    'largest_object','compact circle progress checkpoint', ...
    'cleared_objects',{{'incomplete circle action', ...
    'incomplete source/target panels','raw GQP piece samples'}});
end

function out=LOCAL_empty()
  out=struct('schema','I32V2_CIRCLE_MODULE_V1','status','INITIALIZED', ...
    'available',false,'warnings',{{}},'first_blocker','', ...
    'audit',struct(),'counters',LOCAL_counters(),'memory',struct(),'data',struct());
end

function id=LOCAL_identifier(err)
  id=err.identifier; if isempty(id), id='I32V2:UNIDENTIFIED_BLOCKER'; end
end
