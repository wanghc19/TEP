function result = selftest_i32v2_boundary()
%SELFTEST_I32V2_BOUNDARY Run manufactured v2 kernel and boundary checks.
% Purpose:
%   Validate rectangular/off-grid Kress weights, one-sided table
%   interpolation, the MFS-only 6/6/0/0 construction ledger, and small
%   same-density circle/wall module executions without a formal certificate.
% Output:
%   result - Compact pass/defect/runtime record.  No files are written.
% Main algorithm:
%   Use analytic Fourier/log identities and a small manufactured response
%   certificate.  Scientific production levels and thresholds are untouched.
% Notes:
%   This function is a manufactured selftest only.  It must never call
%   check_e_cap_v2 or create output/ecap-v2-a1.

  timer=tic;
  result=struct('available',false,'pass',false,'first_blocker','', ...
    'kress',struct(),'interpolation',struct(),'gqp',struct(), ...
    'tdiff',struct(),'circle',struct(),'wall',struct(), ...
    'partial_checkpoint',struct(),'elapsed_s',NaN);
  try
    % --- stage 1: aligned and off-grid Kress identities ---
    n=64; s=2*pi*(0:n-1)'/n; R=i32v2_rect_kress_weights(s,s);
    rvec=quad.quad_kress_rvec(n);
    offsets=mod((0:n-1)-(0:n-1).',n)+1; reference=rvec(offsets);
    aligned=norm(R-reference,'fro')/max(norm(reference,'fro'),realmin);
    targets=2*pi*((0:16)'+1/3)/17; Rt=i32v2_rect_kress_weights(s,targets);
    modes=(-16:16).'; modes(modes==0)=[]; offgrid=0;
    for ell=modes.'
      actual=Rt*exp(1i*ell*s);
      exact=-2*pi/abs(ell)*exp(1i*ell*targets);
      offgrid=max(offgrid,norm(actual-exact)/max(norm(exact),realmin));
    end
    assert(aligned<=1e-14&&offgrid<=5e-13,'Kress oracle failed.');
    result.kress=struct('aligned_relative',aligned,'offgrid_relative',offgrid);

    % --- stage 2: exact cubic table interpolation ---
    x=linspace(-0.5,0.5,17); y=linspace(-1,1,19); [X,Y]=meshgrid(x,y);
    table=complex(zeros(19,17,6));
    for f=1:6, table(:,:,f)=f+(1+1i*f)*X.^3+(2-f*1i)*Y.^2+X.*Y; end
    xq=[-0.5;-0.371;0.119;0.5]; yq=[-1;-0.62;0.47;1];
    [actual,ia]=i32v2_gqp_interp(table,x,y,xq,yq); exact=zeros(4,6);
    for f=1:6
      exact(:,f)=f+(1+1i*f)*xq.^3+(2-f*1i)*yq.^2+xq.*yq;
    end
    interp=norm(actual-exact,'fro')/max(norm(exact,'fro'),realmin);
    assert(interp<=2e-13&&ia.endpoint_wrap_count==0,'Interpolation oracle failed.');
    result.interpolation=struct('relative',interp,'audit',ia);

    % --- stage 3: actual circle T_out-T_in Fourier-mode oracle ---
    result.tdiff=LOCAL_tdiff_oracle();
    assert(result.tdiff.relative<=1e-12,'T-difference oracle failed.');

    % --- stage 4: small six-proxy MFS construction ---
    cfg=i32v2_config();
    cfg.gqp_production=[40 40 16 8];
    cfg.gqp_variants=[32 32 12 6;40 32 12 6;32 40 12 6;32 32 16 6;32 32 12 8];
    cfg.gqp_interp_oracle_tol=1;
    cfg.circle_levels=[16 32 64]; cfg.wall_levels=[16 32 64];
    cfg.levels.circle_source=cfg.circle_levels; cfg.levels.circle_target=cfg.circle_levels;
    cfg.levels.wall_source=cfg.wall_levels; cfg.levels.wall_target=cfg.wall_levels;
    cfg.levels.riccati=[32 64 128]; cfg.boundary_target_panel=16;
    cfg.boundary_source_panel=16; cfg.gqp_direct_block=512;
    cert=LOCAL_certificate(cfg); resource=struct('start_tic',tic, ...
      'soft_s',600,'hard_s',900,'memory_mib_max',2048);
    g=i32v2_gqp_module(cert,cfg,resource);
    assert(g.available,'I32V2:SelftestGQPBlocked', ...
      'Manufactured GQP module blocker: %s',g.first_blocker);
    ledger=[g.counters.precomp_proxy,g.counters.lsqminnorm_selected, ...
      g.counters.pinv_fallback,g.counters.mfs_outer_plane_wave_evaluator];
    assert(isequal(ledger,[6 6 0 0]),'The GQP ledger is not 6/6/0/0.');
    result.gqp=struct('ledger',ledger,'oracles',g.audit.oracles, ...
      'retained_mib',g.memory.retained_mib);

    % --- stage 5: small same-density circle and wall modules ---
    circle=i32v2_circle_module(cert,g,cfg,resource);
    assert(circle.available,'I32V2:SelftestCircleBlocked', ...
      'Manufactured circle module blocker: %s',circle.first_blocker);
    wall=i32v2_wall_module(cert,g,cfg,resource,circle);
    assert(wall.available,'I32V2:SelftestWallBlocked', ...
      'Manufactured wall module blocker: %s: %s',wall.first_blocker, ...
      LOCAL_exception_message(wall));
    compact_g=i32v2_return_audit(g,{});
    compact_c=i32v2_return_audit(circle,{});
    compact_w=i32v2_return_audit(wall,{});
    assert(compact_g.pass&&compact_c.pass&&compact_w.pass, ...
      'A returned module retained a forbidden dense reference.');
    assert(isequal(size(circle.data.finest.normal_plus),[64 3]), ...
      'Circle normal shape mismatch.');
    assert(isequal(size(circle.data.finest.value_plus),[64 3]), ...
      'Circle value shape mismatch.');
    assert(isequal(size(wall.data.finest.internal_plus),[64 3]), ...
      'Wall normal shape mismatch.');
    assert(isequal(size(wall.data.finest.value_left_plus),[64 3]), ...
      'Wall value shape mismatch.');
    assert(all([circle.counters.density_resolve_count, ...
      wall.counters.density_resolve_count,circle.counters.image_sum_calls, ...
      wall.counters.image_sum_calls]==0),'Forbidden counter is nonzero.');
    assert(wall.audit.wall_split_recombination<=cfg.threshold.recombination, ...
      'Wall split recombination oracle failed.');
    LOCAL_metric_schema(circle,wall,3);
    result.circle=struct('status',circle.status,'compact_return',compact_c.pass,'normal_size', ...
      size(circle.data.finest.normal_plus),'value_size',size(circle.data.finest.value_plus), ...
      'riccati_levels',numel(circle.data.axis_metrics.riccati.normal_plus.level));
    result.wall=struct('status',wall.status,'compact_return',compact_w.pass,'normal_size', ...
      size(wall.data.finest.internal_plus),'value_size', ...
      size(wall.data.finest.value_left_plus),'split_recombination', ...
      wall.audit.wall_split_recombination);

    % --- stage 6: deterministic late GQP failure preserves completed Grams ---
    g_bad=g;
    g_bad.data=rmfield(g_bad.data,'variant_delta_n129');
    blocked_circle=i32v2_circle_module(cert,g_bad,cfg,resource);
    blocked_wall=i32v2_wall_module(cert,g_bad,cfg,resource,circle);
    compact_bc=i32v2_return_audit(blocked_circle,{});
    compact_bw=i32v2_return_audit(blocked_wall,{});
    assert(~blocked_circle.available&&~blocked_wall.available, ...
      'Late GQP failure injection did not block both boundary modules.');
    assert(isfield(blocked_circle.data,'partial_metrics')&& ...
      isfield(blocked_wall.data,'partial_metrics')&& ...
      isfield(blocked_circle.data.partial_metrics,'axis_metrics')&& ...
      isfield(blocked_wall.data.partial_metrics,'axis_metrics'), ...
      'A late blocker lost completed compact axis metrics.');
    assert(~isfield(blocked_circle.data,'finest')&& ...
      ~isfield(blocked_wall.data,'finest')&& ...
      compact_bc.pass&&compact_bw.pass, ...
      'A late blocker retained a forbidden dense boundary object.');
    result.partial_checkpoint=struct( ...
      'circle_blocker',blocked_circle.first_blocker, ...
      'wall_blocker',blocked_wall.first_blocker, ...
      'circle_compact',compact_bc.pass,'wall_compact',compact_bw.pass, ...
      'completed_axis_metrics_retained',true, ...
      'incomplete_dense_returned',false);
    result.available=true; result.pass=true;
  catch err
    result.first_blocker=err.identifier;
    result.exception_message=err.message;
  end
  result.elapsed_s=toc(timer);
end

%% ==================== Compact metric schema oracle ====================
% Shapes certify that no level map is needed after its Gram is formed.

function LOCAL_metric_schema(circle,wall,K)
  expected=[K K 5]; scale_expected=[K K 3]; level_expected=[K K 3];
  modules={circle,wall};
  for j=1:2
    module=modules{j};
    for field={'gqp_metrics','value_gqp_metrics'}
      metric=module.data.(field{1});
      assert(isequal(size(metric.proxy.delta_plus_grams),expected), ...
        'Proxy plus-Gram schema mismatch.');
      assert(isequal(size(metric.proxy.delta_minus_grams),expected), ...
        'Proxy minus-Gram schema mismatch.');
      assert(isequal(size(metric.proxy.singleton_squared),[5 1]), ...
        'Proxy singleton schema mismatch.');
      assert(isequal(size(metric.scale_diag.piece_plus_grams),scale_expected), ...
        'Diagnostic separated-scale schema mismatch.');
      assert(isequal(size(metric.scale_fine.piece_minus_grams),scale_expected), ...
        'Fine separated-scale schema mismatch.');
      assert(isequal(size(metric.scale_fine.piece_singleton_norms),[3 1]), ...
        'Separated singleton-scale schema mismatch.');
    end
    for axis={'target','source'}
      for kind={'normal','value'}
        metric=module.data.axis_metrics.(axis{1}).(kind{1});
        assert(isequal(size(metric.level_plus_gram),level_expected), ...
          'Axis plus-Gram schema mismatch.');
        assert(isequal(size(metric.level_minus_gram),level_expected), ...
          'Axis minus-Gram schema mismatch.');
        assert(isequal(size(metric.singleton_squared),[3 1]), ...
          'Axis singleton schema mismatch.');
        assert(isequal(size(metric.delta01_plus_gram),[K K])&& ...
          isequal(size(metric.delta12_minus_gram),[K K]), ...
          'Axis difference-Gram schema mismatch.');
      end
    end
  end
  riccati=circle.data.axis_metrics.riccati;
  assert(numel(riccati.normal_plus.level)==3&& ...
    numel(riccati.normal_plus.difference)==2&& ...
    numel(riccati.normal_minus.level)==3&& ...
    numel(riccati.normal_minus.difference)==2, ...
    'Riccati axis schema mismatch.');
  assert(isequal(size(wall.data.center_first_left_flux),[64 1])&& ...
    isequal(size(wall.data.center_first_right_flux),[64 1])&& ...
    ~isfield(wall.data,'center_first_left_value')&& ...
    ~isfield(wall.data,'center_first_right_value'), ...
    'Center/first singleton shape mismatch.');
end

%% ==================== Circle hypersingular-difference oracle ====================
% The actual circle module is driven by exact Fourier density samples while
% every smooth proxy table and wall density is zero.  Its recovered normal
% coefficients must therefore equal the analytic free-space T_o-T_i modes.

function result=LOCAL_tdiff_oracle()
  cfg=i32v2_config();
  cfg.circle_levels=[16 32 64]; cfg.wall_levels=[16 32 64];
  cfg.levels.circle_source=cfg.circle_levels; cfg.levels.circle_target=cfg.circle_levels;
  cfg.levels.wall_source=cfg.wall_levels; cfg.levels.wall_target=cfg.wall_levels;
  cfg.levels.riccati=[32 64 128]; cfg.boundary_target_panel=16;
  cfg.boundary_source_panel=16;

  modes=(-3:3).'; K=numel(modes); state=2*K; native=16;
  theta=2*pi*(0:native-1)'/native;
  tau=exp(1i*theta*modes.');
  zeta=complex(zeros(native,state));
  eta=complex(zeros(2*native,state));
  eta(1:native,1:K)=tau;
  eta(native+1:end,:)=zeta;
  z=struct('khat',1.832770289108157,'mu_h',3.359046932637597, ...
    'gamma',3.359046932637597, ...
    'rho_disk',17,'R',0.2,'d',1,'beta',0.5,'X_L',-0.5,'X_R',0.5, ...
    'delta_c',0.04,'eta_unit_256',eta, ...
    'xi_left_unit_512',complex(zeros(native,state)), ...
    'xi_right_unit_512',complex(zeros(native,state)), ...
    'Gplus',[eye(K);zeros(K)],'Gminus',complex(zeros(state,K)));
  cert=struct('certificate',z);

  g=struct('available',true,'data',struct());
  g.data.d=z.d; g.data.beta=z.beta; g.data.k=z.khat;
  for n=[65 129 257]
    g.data.(sprintf('production_n%d',n))=complex(zeros(n,n,6));
  end
  g.data.variant_delta_n129=complex(zeros(129,129,6,5));
  resource=struct('start_tic',tic,'soft_s',120,'hard_s',180, ...
    'memory_mib_max',2048);
  circle=i32v2_circle_module(cert,g,cfg,resource);
  assert(circle.available,'I32V2:SelftestTdiffCircleBlocked', ...
    'T-difference circle module blocker: %s',circle.first_blocker);

  weight=LOCAL_circle_trace_weight(z,64,cfg.levels.riccati(end));
  actual=bsxfun(@times,circle.data.finest.normal_plus,sqrt(weight));
  orders=(-32:31).';
  reference=complex(zeros(size(actual)));
  ko=z.khat; ki=z.khat*sqrt(z.rho_disk);
  for j=1:K
    ell=modes(j); row=find(orders==ell,1);
    reference(row,j)=sqrt(2*pi*z.R)*(LOCAL_tmode(ell,ko,z.R)- ...
      LOCAL_tmode(ell,ki,z.R));
  end
  defect=norm(actual-reference,'fro')/max(norm(reference,'fro'),realmin);
  result=struct('relative',defect,'modes',modes.', ...
    'oracle','analytic free-space T_out-T_in Fourier multiplier', ...
    'actual_module_path',true);
end

function value=LOCAL_tmode(ell,k,R)
  z=k*R;
  jp=(besselj(ell-1,z)-besselj(ell+1,z))/2;
  hp=(besselh(ell-1,1,z)-besselh(ell+1,1,z))/2;
  value=1i*pi*k^2*R*jp*hp/2;
end

function weight=LOCAL_circle_trace_weight(z,n,steps)
  orders=(-n/2:n/2-1).';
  inside=LOCAL_riccati(zeros(size(orders)),log(z.R-z.delta_c), ...
    log(z.R),steps,orders,z.gamma*z.rho_disk);
  outside=LOCAL_riccati(zeros(size(orders)),log(z.R+z.delta_c), ...
    log(z.R),steps,orders,z.gamma);
  weight=(inside-outside)/z.R;
end

function p=LOCAL_riccati(p,t0,t1,steps,orders,alpha)
  h=(t1-t0)/steps; t=t0;
  for j=1:steps
    k1=orders.^2+alpha*exp(2*t)-p.^2;
    q=p+h*k1/2; k2=orders.^2+alpha*exp(2*(t+h/2))-q.^2;
    q=p+h*k2/2; k3=orders.^2+alpha*exp(2*(t+h/2))-q.^2;
    q=p+h*k3; k4=orders.^2+alpha*exp(2*(t+h))-q.^2;
    p=p+h*(k1+2*k2+2*k3+k4)/6; t=t+h;
  end
end

function message=LOCAL_exception_message(module)
  message='';
  if isfield(module,'audit')&&isfield(module.audit,'exception_message')
    message=module.audit.exception_message;
  end
end

%% ==================== Manufactured compact certificate ====================
% The object has the same algebraic roles but deliberately small dimensions.

function cert=LOCAL_certificate(cfg)
  rng(17,'twister'); K=3; state=2*K; nc=16; nw=16;
  z=struct('khat',1.832770289108157,'mu_h',3.359046932637597, ...
    'gamma',3.359046932637597,'beta',cfg.physics.beta,'d',cfg.physics.d, ...
    'R',cfg.physics.R,'rho_disk',cfg.physics.rho_disk,'X_L',-0.5,'X_R',0.5, ...
    'M',1,'K',K,'delta_c',0.04,'delta_w',0.04);
  z.Gplus=0.1*(randn(state,K)+1i*randn(state,K));
  z.Gminus=0.1*(randn(state,K)+1i*randn(state,K));
  z.Pplus=diag([0.31,0.24,0.17]); z.Pminus=diag([0.29,0.21,0.16]);
  z.cplus=[1;0.2i;-0.1]; z.cminus=[0.8;-0.1i;0.2];
  z.eta_unit_256=1e-2*(randn(2*nc,state)+1i*randn(2*nc,state));
  z.xi_left_unit_512=1e-2*(randn(nw,state)+1i*randn(nw,state));
  z.xi_right_unit_512=1e-2*(randn(nw,state)+1i*randn(nw,state));
  zero=complex(zeros(nw,1));
  z.center_wall_jumps=struct('center_left_global_dx',zero, ...
    'center_right_global_dx',zero,'actual_left_trace',zero, ...
    'actual_right_trace',zero);
  cert=struct('certificate',z);
end
