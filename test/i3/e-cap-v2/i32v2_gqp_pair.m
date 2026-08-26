function [pot,gx,gy,hxx,hxy,hyy,audit] = ...
    i32v2_gqp_pair(g,src,trg,field_level,variant_id)
%I32V2_GQP_PAIR Sole boundary gateway for the v2 quasiperiodic kernel.
% Purpose:
%   Evaluate the MFS-only quasiperiodic Green function, or only its smooth
%   proxy remainder, for one streamed target/source panel.
% Input:
%   g           - Compact return from i32v2_gqp_module.
%   src,trg     - Physical coordinates, each 2-by-n.
%   field_level - Struct with fields n and include_primary.
%   variant_id  - 0 for production; 1:5 for a 129-grid proxy variant.
% Output:
%   pot,gx,gy,hxx,hxy,hyy - nt-by-ns physical target derivatives.
%   audit                  - Fold, phase, interpolation, and path counters.
% Main algorithm:
%   Fold physical Delta-y with MATLAB round, interpolate the computational
%   proxy remainder, apply the Bloch phase, remap derivatives, and optionally
%   add the exactly folded analytic free-space primary.
% Notes:
%   Circle and wall modules must call no periodic-kernel package routine
%   directly.  Self interactions request include_primary=false and add the
%   primary through their registered Kress split.

  LOCAL_validate(g,src,trg,field_level,variant_id);
  n=field_level.n; include_primary=logical(field_level.include_primary);
  [table,xgrid,ygrid]=LOCAL_table(g.data,n,variant_id);
  d=g.data.d; beta=g.data.beta; k=g.data.k;
  dx=trg(1,:).'-src(1,:); dy=trg(2,:).'-src(2,:);
  shift=round(dy/d); x0=dy-shift*d; ycomp=dx;
  [vals,ia]=i32v2_gqp_interp(table,xgrid,ygrid,x0,ycomp);
  phase=exp(1i*beta*d*shift(:)); vals=vals.*phase;
  nt=size(trg,2); ns=size(src,2);
  pot=reshape(vals(:,1),nt,ns);
  gx=reshape(vals(:,3),nt,ns);
  gy=reshape(vals(:,2),nt,ns);
  hxx=reshape(vals(:,6),nt,ns);
  hxy=reshape(vals(:,5),nt,ns);
  hyy=reshape(vals(:,4),nt,ns);
  primary_calls=0;
  if include_primary
    points=[x0(:).';ycomp(:).'];
    if any(sum(abs(points).^2,1)==0)
      error('i32v2:GQPSingularPrimary', ...
        'A complete-kernel request contains a coincident pair.');
    end
    [p0,g0,h0]=kernel.h2d_directch(k,[0;0],1,points);
    p0=p0(:).*phase;
    g0=bsxfun(@times,g0,phase.');
    h0=bsxfun(@times,h0,phase.');
    pot=pot+reshape(p0,nt,ns);
    gx=gx+reshape(g0(2,:),nt,ns);
    gy=gy+reshape(g0(1,:),nt,ns);
    hxx=hxx+reshape(h0(3,:),nt,ns);
    hxy=hxy+reshape(h0(2,:),nt,ns);
    hyy=hyy+reshape(h0(1,:),nt,ns);
    primary_calls=1;
  end
  finite=all(isfinite([pot(:);gx(:);gy(:);hxx(:);hxy(:);hyy(:)]));
  audit=struct('pair_count',nt*ns,'field_level',n, ...
    'variant_id',variant_id,'include_primary',include_primary, ...
    'round_fold_count',nt*ns,'half_tie_count',sum(abs(abs(x0(:))-d/2)<=8*eps(d)), ...
    'bloch_phase_multiply_count',6*nt*ns, ...
    'analytic_primary_call_count',primary_calls, ...
    'image_sum_calls',0,'rayleigh_trial_eval_calls',0, ...
    'outer_plane_wave_eval_count',0,'interpolation',ia,'finite',finite);
  audit.operation_ledger=struct( ...
    'interpolation_cma',ia.all_field_complex_operation_count, ...
    'bloch_phase_multiply',6*nt*ns, ...
    'analytic_primary_pairs',primary_calls*nt*ns, ...
    'total',ia.all_field_complex_operation_count+6*nt*ns);
end

function LOCAL_validate(g,src,trg,field_level,variant_id)
  if ~isstruct(g)||~isfield(g,'data')||~isfield(g.data,'production_n257')
    error('i32v2:GQPState','The compact GQP state is unavailable.');
  end
  if size(src,1)~=2||size(trg,1)~=2||isempty(src)||isempty(trg)|| ...
      any(~isfinite([src(:);trg(:)]))
    error('i32v2:GQPPairShape','Sources and targets must be finite 2-by-n arrays.');
  end
  if ~isstruct(field_level)||~isfield(field_level,'n')|| ...
      ~isfield(field_level,'include_primary')
    error('i32v2:GQPFieldLevel','field_level must contain n and include_primary.');
  end
  if ~isscalar(variant_id)||variant_id<0||variant_id>5||variant_id~=round(variant_id)
    error('i32v2:GQPVariant','variant_id must be an integer from zero through five.');
  end
end

function [table,xgrid,ygrid]=LOCAL_table(data,n,variant_id)
  name=sprintf('production_n%d',n);
  if ~isfield(data,name)
    error('i32v2:GQPFieldLevel','The requested production table is unavailable.');
  end
  table=data.(name);
  if variant_id~=0
    if n~=129||~isfield(data,'variant_delta_n129')
      error('i32v2:GQPVariantLevel','Proxy variants are registered only at n=129.');
    end
    table=table+data.variant_delta_n129(:,:,:,variant_id);
  end
  xgrid=linspace(-data.d/2,data.d/2,n);
  ygrid=linspace(-1,1,n);
end
