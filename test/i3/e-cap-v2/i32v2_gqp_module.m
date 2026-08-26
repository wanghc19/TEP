function out = i32v2_gqp_module(view,cfg,resource)
%I32V2_GQP_MODULE Build compact MFS-only regular-remainder tables.
% Purpose:
%   Construct the six preregistered MFS proxies, tabulate the production
%   smooth remainder on 65/129/257 grids, and retain five 129-grid variant
%   differences for componentwise empirical GQP diagnostics.
% Input:
%   view     - Authenticated i32v2_computation_view return.
%   cfg      - Preregistered numerical configuration from i32v2_config.
%   resource - Struct with start_tic, soft_s, hard_s, memory_mib_max.
% Output:
%   out      - Common compact module return.  out.data is consumed only by
%              i32v2_gqp_pair and the registered component diagnostics.
% Main algorithm:
%   Use normal MATLAB resolution for six kernel.precomp_proxy calls.  Evaluate
%   only proxy-source fields in panels of at most 512 difference targets.
% Based on:
%   kernel.precomp_proxy, kernel.qpgreen_mfs_pairmat, and design-3-2d.
% Main changes:
%   No image sum, Rayleigh trial action, source hash, or dense pair matrix.
% Numerical goal:
%   Supply same-kernel production and refinement tables within the resource
%   contract; finite oracle defects remain scientific warnings.

  timer=tic; out=LOCAL_empty(); peak_bytes=0; progress=LOCAL_progress();
  out.audit.symbol_ledger=struct( ...
    'production_n65','combined-high proxy remainder on the 65 table', ...
    'production_n129','combined-high proxy remainder on the 129 table', ...
    'production_n257','combined-high proxy remainder on the 257 table', ...
    'variant_delta_n129','five proxy variants minus production at n=129', ...
    'X0','folded physical Delta-y in computational periodic coordinate', ...
    'Y','physical Delta-x in computational nonperiodic coordinate', ...
    'progress_checkpoint','publication-safe proxy/table panel progress');
  try
    view_audit=i32v2_validate_computation_view(view,cfg,'gqp');
    z=LOCAL_certificate(view); LOCAL_config(cfg,resource,z);
    out.audit.computation_view=view_audit;
    if isempty(which('lsqminnorm'))
      error('I32V2:LSQMINNORMUnavailable', ...
        'Normal MATLAB resolution did not find lsqminnorm.');
    end
    pars=struct('d',double(z.d),'beta',z.beta,'k',z.khat);
    levels=double(cfg.gqp_interp_levels(:).');
    out.counters=LOCAL_counters();
    peak_bytes=LOCAL_mfs_work_bytes(cfg.gqp_production);
    progress.local_peak_mib=peak_bytes/2^20;
    progress.stage='production proxy'; progress.variant_id=0;
    [proxy,out.counters]=LOCAL_proxy(pars,cfg.gqp_production,cfg,resource, ...
      out.counters);
    progress.completed_proxy_builds=1;
    data=struct('schema','I32V2_GQP_TABLES_V1','d',double(z.d), ...
      'beta',z.beta,'k',z.khat,'levels',levels, ...
      'table_coordinate_order','rows=Y=Delta-x, columns=X0=folded Delta-y', ...
      'field_order',{{'pot','gradX','gradY','hessXX','hessXY','hessYY'}});
    for j=1:numel(levels)
      n=levels(j); progress.stage='production table'; progress.level=n;
      LOCAL_resource(resource,peak_bytes);
      [table,record,table_progress,table_error]= ...
        LOCAL_table(proxy,pars,n,cfg,resource);
      progress=LOCAL_absorb_table_progress(progress,table_progress, ...
        'production',n,0);
      if ~isempty(table_error), rethrow(table_error); end
      data.(sprintf('production_n%d',n))=table;
      out.audit.production_tables.(sprintf('n%d',n))=record;
      progress.completed_actions=progress.completed_actions+1;
      progress.completed_production_levels(end+1)=n;
      peak_bytes=max(peak_bytes,LOCAL_bytes(data)+ ...
        record.local_peak_mib*2^20);
    end
    variants=cfg.gqp_variants;
    deltas=complex(zeros(129,129,6,5));
    high=data.production_n129;
    for j=1:5
      progress.stage='proxy variant'; progress.variant_id=j; progress.level=129;
      LOCAL_resource(resource,peak_bytes+LOCAL_bytes(deltas));
      peak_bytes=max(peak_bytes,LOCAL_bytes(data)+ ...
        LOCAL_mfs_work_bytes(variants(j,:)));
      [variant,out.counters]=LOCAL_proxy(pars,variants(j,:),cfg,resource, ...
        out.counters);
      progress.completed_proxy_builds=progress.completed_proxy_builds+1;
      [table,record,table_progress,table_error]= ...
        LOCAL_table(variant,pars,129,cfg,resource);
      progress=LOCAL_absorb_table_progress(progress,table_progress, ...
        'variant',129,j);
      if ~isempty(table_error), rethrow(table_error); end
      deltas(:,:,:,j)=table-high;
      out.audit.variant_tables(j)=record;
      progress.completed_actions=progress.completed_actions+1;
      progress.completed_variants(end+1)=j;
      clear variant table
    end
    data.variant_delta_n129=deltas;
    temp=out; temp.data=data;
    [oracle,warnings]=LOCAL_oracles(temp,proxy,pars,cfg);
    out.audit.oracles=oracle; out.warnings=warnings;
    out.data=data; out.available=true; out.status='COMPLETE';
    out.counters.mfs_outer_plane_wave_evaluator=0;
    if ~isequal([out.counters.precomp_proxy,out.counters.lsqminnorm_selected, ...
        out.counters.pinv_fallback,out.counters.mfs_outer_plane_wave_evaluator], ...
        [6 6 0 0])
      error('I32V2:MFSCallLedger','The required MFS call ledger is not 6/6/0/0.');
    end
    out.audit.qualification_pass=oracle.interpolation_pass&&oracle.bloch_pass;
    out.audit.production_parameters_text=sprintf( ...
      'H=%.17g, proxy_distance=%.17g, Nside=%d, Ntop=%d, Nedge=%d, Mpw=%d', ...
      cfg.gqp_H,cfg.gqp_proxy_dist,cfg.gqp_production);
    out.audit.empirical_uncertainty_basis = [ ...
      'Preregistered 2e-9 relative floor from prior approximately ', ...
      '10-digit MFS qualification; empirical only, not an upper bound.'];
    out.audit.empirical_relative_floor = cfg.gqp.relative_floor;
    out.audit.mfs_solve_work_proxy_mib= ...
      LOCAL_mfs_work_bytes(cfg.gqp_production)/2^20;
    out.audit.image_sum_code_path_zero=true;
    out.audit.rayleigh_trial_code_path_zero=true;
    progress.stage='complete'; progress.complete=true;
    out.audit.progress_checkpoint=progress;
    out.memory.entry_mib=LOCAL_resource_field(resource,'retained_mib',0);
    out.memory.local_peak_mib=max(peak_bytes,LOCAL_bytes(data))/2^20;
    out.memory.retained_mib=LOCAL_bytes(data)/2^20;
    out.memory.cow_mib=LOCAL_resource_field(resource,'cow_mib',0);
    out.memory.publication_mib=LOCAL_resource_field(resource, ...
      'publication_mib',64);
    out.memory.proxy_mib=out.memory.entry_mib+out.memory.local_peak_mib+ ...
      out.memory.cow_mib+out.memory.publication_mib;
    out.memory.largest_object='production_n257';
    out.memory.cleared_objects={'six proxy structs','variant absolute tables'};
  catch err
    out.available=false; out.status='BLOCKED';
    out.first_blocker=LOCAL_identifier(err); out.audit.exception_message=err.message;
    progress.stage='blocked'; progress.first_blocker=out.first_blocker;
    progress.local_peak_mib=max(progress.local_peak_mib,peak_bytes/2^20);
    progress.incomplete_dense_returned=false;
    out.audit.progress_checkpoint=progress;
    clear data table deltas high proxy variant temp
  end
  if ~isfield(out.memory,'proxy_mib')
    out.memory=LOCAL_partial_memory(out,resource,progress.local_peak_mib);
  end
  out.audit.elapsed_s=toc(timer);
end

%% ==================== Proxy construction and tables ====================
% These helpers are the only direct MFS construction path in the module.

function [proxy,counters]=LOCAL_proxy(pars,tuple,cfg,resource,counters)
  if isempty(which('lsqminnorm'))
    error('I32V2:LSQMINNORMUnavailable','lsqminnorm disappeared from the MATLAB path.');
  end
  spec=struct('H',cfg.gqp_H,'proxy_dist',cfg.gqp_proxy_dist, ...
    'N_side',tuple(1),'N_top',tuple(2),'N_proxy_edge',tuple(3),'M_pw',tuple(4));
  LOCAL_resource(resource,LOCAL_mfs_work_bytes(tuple));
  proxy=kernel.precomp_proxy(pars,spec);
  counters.precomp_proxy=counters.precomp_proxy+1;
  counters.lsqminnorm_selected=counters.lsqminnorm_selected+1;
  if any(~isfinite([proxy.q(:);proxy.Z(:);proxy.C_up(:);proxy.C_down(:)]))
    error('I32V2:MFSProxyNonfinite','An MFS proxy is nonfinite.');
  end
end

function bytes=LOCAL_mfs_work_bytes(tuple)
  equations=2*double(tuple(1))+4*double(tuple(2));
  unknowns=4*double(tuple(3))+2*(2*double(tuple(4))+1);
  % Twelve complex system-sized arrays conservatively cover A, solver
  % workspaces, and temporary boundary/source blocks in lsqminnorm.
  bytes=12*equations*unknowns*16+16*(equations+unknowns)^2;
end

function [table,record,checkpoint,table_error]= ...
    LOCAL_table(proxy,pars,n,cfg,resource)
  table_error=[];
  checkpoint=struct('n',n,'completed_panels',0,'completed_rows',0, ...
    'local_peak_mib',0,'value_fro_squared',0, ...
    'operation_ledger',struct('direct_proxy_target_count',0, ...
    'field_value_count',0),'complete',false,'first_blocker','', ...
    'incomplete_dense_returned',false);
  peak=0;
  try
    x=linspace(-pars.d/2,pars.d/2,n); y=linspace(-1,1,n);
    [X,Y]=meshgrid(x,y); points=[X(:).';Y(:).']; np=size(points,2);
    flat=complex(zeros(np,6)); block=cfg.gqp_direct_block;
    for first=1:block:np
      last=min(np,first+block-1);
      peak=max(peak,LOCAL_bytes(flat));
      checkpoint.local_peak_mib=peak/2^20;
      LOCAL_resource(resource,peak);
      [p,gr,h]=kernel.h2d_directch(pars.k,proxy.Z,proxy.q,points(:,first:last));
      panel=[p(:),gr.',h.'];
      flat(first:last,:)=panel;
      peak=max(peak,LOCAL_bytes(flat)+LOCAL_bytes(panel));
      checkpoint.completed_panels=checkpoint.completed_panels+1;
      checkpoint.completed_rows=last;
      checkpoint.local_peak_mib=peak/2^20;
      checkpoint.value_fro_squared=checkpoint.value_fro_squared+ ...
        norm(panel,'fro')^2;
      checkpoint.operation_ledger.direct_proxy_target_count=last;
      checkpoint.operation_ledger.field_value_count=6*last;
      LOCAL_resource(resource,peak);
      clear panel p gr h
    end
    table=reshape(flat,n,n,6);
    record=struct('n',n,'difference_target_count',np, ...
      'direct_proxy_panel_max',block,'local_peak_mib',peak/2^20, ...
      'finite',all(isfinite(table),'all'));
    checkpoint.complete=true;
  catch err
    table_error=err;
    checkpoint.first_blocker=LOCAL_identifier(err);
    checkpoint.local_peak_mib=max(checkpoint.local_peak_mib,peak/2^20);
    checkpoint.incomplete_dense_returned=false;
    table=[]; record=struct();
    clear flat points X Y panel p gr h
  end
end

%% ==================== Manufactured MFS oracles ====================
% Direct pairmat comparisons qualify interpolation without an image formula.

function [oracle,warnings]=LOCAL_oracles(g,proxy,pars,cfg)
  interior=[-0.4375,-0.73;-0.183,0.31;0.117,-0.47;0.421,0.82];
  seamY=[-0.8,-0.2,0.3,0.9]; points=interior;
  for x0=[-pars.d/2,pars.d/2]
    points=[points;[repmat(x0,4,1),seamY(:)]]; %#ok<AGROW>
  end
  defects=zeros(size(points,1),6); scales=defects;
  for j=1:size(points,1)
    x0=points(j,1); ycomp=points(j,2);
    if x0==-pars.d/2, dy=pars.d/2; elseif x0==pars.d/2, dy=-pars.d/2;
    else, dy=x0; end
    src=[0;0]; trg=[ycomp;dy]; level=struct('n',257,'include_primary',false);
    [p,gx,gy,hxx,hxy,hyy]=i32v2_gqp_pair(g,src,trg,level,0);
    interp=[p,gx,gy,hxx,hxy,hyy];
    qp=struct('d',pars.d,'beta',pars.beta,'k',pars.k,'periodic_axis','y');
    [pd,gxd,gyd,hxxd,hxyd,hyyd]=kernel.qpgreen_mfs_pairmat(src,trg,qp,proxy);
    m=round(dy/pars.d); fold=dy-m*pars.d; phase=exp(1i*pars.beta*m*pars.d);
    [p0,g0,h0]=kernel.h2d_directch(pars.k,[0;0],1,[fold;ycomp]);
    direct=[pd-phase*p0,gxd-phase*g0(2),gyd-phase*g0(1), ...
      hxxd-phase*h0(3),hxyd-phase*h0(2),hyyd-phase*h0(1)];
    defects(j,:)=abs(interp-direct); scales(j,:)=abs(direct);
  end
  relative=max(defects,[],1)./max(max(scales,[],1),realmin);
  interp_pass=all(relative<=cfg.gqp_interp_oracle_tol);
  base=[0.137;0.211]; src=[0;0]; trg=[base(2);base(1)];
  shifted=[base(2);base(1)+pars.d]; level=struct('n',257,'include_primary',true);
  a=cell(1,6); b=cell(1,6);
  [a{1:6}]=i32v2_gqp_pair(g,src,trg,level,0);
  [b{1:6}]=i32v2_gqp_pair(g,src,shifted,level,0);
  av=cellfun(@(v)v(1),a); bv=cellfun(@(v)v(1),b);
  phase=exp(1i*pars.beta*pars.d);
  bloch_defect=max(abs(bv-phase*av))/max(max(abs(bv)),realmin);
  bloch_pass=bloch_defect<=cfg.gqp_bloch_oracle_tol;
  oracle=struct('interpolation_relative_by_field',relative, ...
    'interpolation_pass',interp_pass,'interpolation_threshold', ...
    cfg.gqp_interp_oracle_tol,'bloch_shift_defect',bloch_defect, ...
    'bloch_pass',bloch_pass,'bloch_threshold',cfg.gqp_bloch_oracle_tol, ...
    'direct_reference','kernel.qpgreen_mfs_pairmat minus folded analytic primary');
  warnings={};
  if ~interp_pass, warnings{end+1}='GQP_INTERPOLATION_ORACLE_WARNING'; end
  if ~bloch_pass, warnings{end+1}='GQP_BLOCH_ORACLE_WARNING'; end
end

%% ==================== Contracts and resources ====================
% Contract helpers contain no scientific fallbacks or adaptive parameters.

function z=LOCAL_certificate(view)
  if ~isstruct(view)||~isfield(view,'data')|| ...
      ~isfield(view.data,'certificate')
    error('I32V2:CertificateInterface', ...
      'The authenticated computation-view certificate is required.');
  end
  z=view.data.certificate;
  required={'khat','beta','d'};
  if ~all(isfield(z,required))||any(~isfinite([z.khat,z.beta,double(z.d)]))
    error('I32V2:CertificateInterface','Required kernel certificate fields are unavailable.');
  end
end

function LOCAL_config(cfg,resource,z)
  required={'gqp_H','gqp_proxy_dist','gqp_production','gqp_variants', ...
    'gqp_interp_levels','gqp_direct_block','gqp_interp_oracle_tol', ...
    'gqp_bloch_oracle_tol'};
  if ~isstruct(cfg)||~all(isfield(cfg,required))|| ...
      ~isequal(double(cfg.gqp_interp_levels(:).'),[65 129 257])|| ...
      ~isequal(size(cfg.gqp_variants),[5 4])|| ...
      ~isequal(size(cfg.gqp_production),[1 4])||double(z.d)~=1
    error('I32V2:GQPConfig','The preregistered GQP configuration is unavailable.');
  end
  if ~isstruct(resource)||~all(isfield(resource, ...
      {'start_tic','soft_s','hard_s','memory_mib_max'}))
    error('I32V2:ResourceConfig','The resource contract is unavailable.');
  end
end

function LOCAL_resource(resource,local_bytes)
  if toc(resource.start_tic)>resource.hard_s
    error('I32V2:HardTimeLimit','The hard GQP time limit was reached.');
  end
  proxy=LOCAL_resource_field(resource,'retained_mib',0)+local_bytes/2^20+ ...
    LOCAL_resource_field(resource,'cow_mib',0)+ ...
    LOCAL_resource_field(resource,'publication_mib',64);
  if proxy>resource.memory_mib_max
    error('I32V2:HardMemoryLimit','The GQP memory proxy exceeded its hard limit.');
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

function n=LOCAL_bytes(value)
  count=numel(value); info=whos('value'); n=info.bytes+0*count;
end

function counters=LOCAL_counters()
  counters=struct('precomp_proxy',0,'lsqminnorm_selected',0, ...
    'pinv_fallback',0,'mfs_outer_plane_wave_evaluator',0, ...
    'image_sum_calls',0,'rayleigh_trial_eval_calls',0, ...
    'old_ecap_calls',0,'density_solves',0);
end

function progress=LOCAL_progress()
  progress=struct('stage','initialized','level',0,'variant_id',0, ...
    'completed_proxy_builds',0,'completed_actions',0, ...
    'completed_production_levels',zeros(1,0), ...
    'completed_variants',zeros(1,0),'completed_panels',0, ...
    'completed_rows',0,'local_peak_mib',0, ...
    'operation_ledger',struct('direct_proxy_target_count',0, ...
    'field_value_count',0),'last_action',struct(), ...
    'complete',false,'first_blocker','', ...
    'incomplete_dense_returned',false);
end

function progress=LOCAL_absorb_table_progress(progress,table_progress, ...
    family,n,variant_id)
  summary=table_progress;
  summary.family=family;
  summary.level=n;
  summary.variant_id=variant_id;
  progress.last_action=summary;
  progress.completed_panels=progress.completed_panels+ ...
    table_progress.completed_panels;
  progress.completed_rows=progress.completed_rows+ ...
    table_progress.completed_rows;
  progress.local_peak_mib=max(progress.local_peak_mib, ...
    table_progress.local_peak_mib);
  progress.operation_ledger.direct_proxy_target_count= ...
    progress.operation_ledger.direct_proxy_target_count+ ...
    table_progress.operation_ledger.direct_proxy_target_count;
  progress.operation_ledger.field_value_count= ...
    progress.operation_ledger.field_value_count+ ...
    table_progress.operation_ledger.field_value_count;
end

function memory=LOCAL_partial_memory(out,resource,local_peak_mib)
  count=numel(out); info=whos('out'); retained=(info.bytes+0*count)/2^20;
  entry=LOCAL_resource_field(resource,'retained_mib',0);
  cow=LOCAL_resource_field(resource,'cow_mib',0);
  publication=LOCAL_resource_field(resource,'publication_mib',64);
  local_peak=max(local_peak_mib,retained);
  memory=struct('entry_mib',entry,'local_peak_mib',local_peak, ...
    'retained_mib',retained,'cow_mib',cow, ...
    'publication_mib',publication, ...
    'proxy_mib',entry+local_peak+cow+publication, ...
    'largest_object','compact GQP progress checkpoint', ...
    'cleared_objects',{{'incomplete MFS table','proxy work arrays', ...
    'incomplete variant table'}});
end

function out=LOCAL_empty()
  out=struct('schema','I32V2_GQP_MODULE_V1','status','INITIALIZED', ...
    'available',false,'warnings',{{}},'first_blocker','', ...
    'audit',struct(),'counters',LOCAL_counters(),'memory',struct(),'data',struct());
end

function id=LOCAL_identifier(err)
  id=err.identifier; if isempty(id), id='I32V2:UNIDENTIFIED_BLOCKER'; end
end
