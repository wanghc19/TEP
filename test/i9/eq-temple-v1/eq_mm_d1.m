function eq_mm_d1(native_path,derived_path,output_dir,mode)
%EQ_MM_D1 Fixed-tail RT2 projection diagnostic and direct Theorem-B MM flux.
% Purpose: Execute plan D.1 (research/.../fem-bound/p-next.md Sections 4-6) on
%   the frozen I9.5 run-03 finite-tail field: reuse the historical
%   unweighted_s0.5 RT2 flux p0, report one pure L2 projection diagnostic, run
%   at most three smoothed majorize-minimize (MM) steps on the Theorem-B
%   objective, and evaluate p0 and the single selected flux directly with Q10
%   and Q8 two-pass true-material integration.
% Input: native_path = I9.3 compare-v1 run-02 evidence.mat (native FEM field);
%   derived_path = I9.5 eq-temple-v1 run-03 evidence.mat (tail field, leaves,
%   historical fluxes); output_dir = run folder; mode = 'formal' or 'smoke'.
%   The entry only loads these explicit files; every scientific helper below
%   receives explicit structs/arrays and eq_mm_d1_config parameters.
% Output: evidence.mat (all candidate coefficients, per-element metrics, MM
%   records, direct evaluations) and result.json; failure.json on error.
% Main algorithm:
%   1. rebuild the run-03 finite Floquet tail once from the native field and
%      check mapx/mapy/mapu, field, leaves and geometry against the saved
%      object; freeze the saved arrays;
%   2. one Q10 reference-leaf cache with pointwise true material, centred at
%      p0 (all forms in Delta c = c - c0, residuals combined before squaring):
%        eps_K^2 = ||(grad u - p0) - Psi dc||_K^2,  R = (div p0 + m rho u) + div Psi dc;
%      separate left/right end Grams;
%   3. direct Q10 two-pass evaluation of p0 (history and cache consistency);
%   4. pure L2 projection min ||grad u - p||, same leaf rule (diagnostic);
%   5. MM: smoothed F_delta (p-next (D3)), frozen branches, Young weights and
%      Cauchy-Schwarz weights give the Hermitian majorant Q_n (D4); at most
%      three solves, backtracking 1,1/2,1/4,1/8 with Q_n(new)<=Q_n(old);
%   6. select min unsmoothed F among p0 and accepted iterates; direct Q10 and
%      Q8 paired evaluation; C3 transfer, linear radius, conditional Temple.
% Based on: test/i9/eq-temple-v1/eq_temple_i95.m (input restoration, RT2
%   space, partition, two-pass evaluation, ends and bound assembly are copied
%   unchanged; their error identifiers keep the i95: prefix).
% Main changes: same-leaf Q10 local quadratic cache, projection diagnostic,
%   smoothed MM on the Theorem-B objective and paired Q10/Q8 comparison.
% Numerical goal: ordinary-arithmetic estimates
%   (UNCERTIFIED_ORDINARY_ARITHMETIC_ESTIMATE), not certified bounds.
  if nargin<4,mode='formal';end
  config=eq_mm_d1_config(mode);maxNumCompThreads(config.threads);
  if ~isfolder(output_dir),mkdir(output_dir);end
  started=tic;lap=tic;stage='input_load';timings=struct();
  try
    % --- stage 1: explicit input loading (the only file reads) ---
    native=load(native_path,'mesh','config','modes','eigenvectors','constraint','forms');
    derived=load(derived_path,'config','reduced','full_field','mapx','mapy','mapu','geo', ...
      'leaves','fluxes','result');
    [timings,lap]=LOCAL_lap(timings,'input_load',lap);

    % --- stage 2: rebuild the finite tail once and freeze the saved object ---
    stage='tail_recovery';
    [rebuilt,recovery]=LOCAL_rebuild(native,derived,config);clear native
    [timings,lap]=LOCAL_lap(timings,'tail_recovery',lap);
    stage='recovery_checks';
    [mesh,frozen,recovery]=LOCAL_freeze(rebuilt,derived,recovery,config);
    mx=frozen.mapx;my=frozen.mapy;mu=frozen.mapu;nt=size(mx,1);
    base=frozen.baseline;c0=base.coeff;
    [timings,lap]=LOCAL_lap(timings,'recovery_checks',lap);
    fprintf('STAGE recovery: %d cells, field diff %.3g, map diff %.3g/%.3g/%.3g\n',nt, ...
      recovery.field_relative_difference,recovery.mapx_difference,recovery.mapy_difference, ...
      recovery.mapu_relative_difference);

    % --- stage 3: true-material leaves (recomputed and compared) ---
    stage='partition';
    [leaves,classification]=LOCAL_partition(mesh,mx,my,config);
    [timings,lap]=LOCAL_lap(timings,'partition',lap);
    stage='partition_check';
    recovery.leaves=LOCAL_leafcheck(leaves,derived.leaves,config);
    saved_geo=derived.geo;history=LOCAL_history(derived,config);clear derived
    [timings,lap]=LOCAL_lap(timings,'partition_check',lap);
    fprintf('STAGE partition: %d leaves, %d unresolved, identical=%d\n',size(leaves,1), ...
      sum(leaves(:,8)==0),recovery.leaves.identical);

    % --- stage 4: geometry, RT2 space and baseline-flux checks ---
    stage='geometry_space';
    geo=LOCAL_geometry(mx,my);
    [D,basis_checks]=LOCAL_dual();Dinv=D\eye(15);
    [~,E]=LOCAL_average(mesh,complex(zeros(nt,15)),config.beta);
    [g,phi,ndof,dofinfo]=LOCAL_dofs(mesh,E,nt,config.beta);
    assert(ndof==config.expected_ndof,'d1:Dofs','RT2 dimension %d differs from %d.',ndof,config.expected_ndof);
    [timings,lap]=LOCAL_lap(timings,'geometry_space',lap);
    stage='baseline_space_checks';
    recovery.geometry=struct('CP_max_difference',max(abs(geo.CP-saved_geo.CP)), ...
      'dmin_max_difference',max(abs(geo.dmin-saved_geo.dmin)),'jmax_max_difference',max(abs(geo.jmax-saved_geo.jmax)));
    assert(recovery.geometry.CP_max_difference<=config.geometry_tolerance,'d1:Geometry', ...
      'Recomputed curved Poincare constants differ from run-03.');
    checks.baseline_trace=LOCAL_trace_check(mesh,mx,my,c0,E);
    checks.baseline_moments=LOCAL_moment_check(c0,D,g,phi,ndof);
    [timings,lap]=LOCAL_lap(timings,'baseline_space_checks',lap);

    % --- stage 5: one same-leaf Q10 cache and separate end Grams ---
    stage='cache_volume';
    cache=LOCAL_cache(leaves,mesh,mx,my,mu,c0,config.m_residual,config.cache_order,config.cache_batch);
    [timings,lap]=LOCAL_lap(timings,'cache_volume',lap);
    stage='cache_ends';
    [ends,checks.ends]=LOCAL_endcache(mesh,mx,my,c0,E,config.end_order);
    [timings,lap]=LOCAL_lap(timings,'cache_ends',lap);
    fprintf('STAGE cache: %.1fs volume, mass %.17g grad2 %.17g\n',timings.cache_volume, ...
      sum(cache.mass),sum(cache.grad2));

    % --- stage 6: direct Q10 baseline (history and cache consistency) ---
    stage='direct_q10_baseline';
    direct.q10_baseline=LOCAL_direct(leaves,mesh,mx,my,mu,c0,geo,E,config, ...
      config.evaluation_order,config.end_order);
    [timings,lap]=LOCAL_lap(timings,'direct_q10_baseline',lap);
    stage='baseline_consistency';
    checks.history=LOCAL_history_check(direct.q10_baseline,history,config);
    zero=complex(zeros(nt,15));st0=LOCAL_state(cache,ends,zero,geo,config,[]);
    checks.cache_vs_direct_baseline=LOCAL_cache_check(st0,direct.q10_baseline);
    % A cache that disagrees with the direct pass is not used (no clamping).
    assert(checks.cache_vs_direct_baseline.consistent,'d1:Cache', ...
      'Q10 cache disagrees with direct Q10 at p0 (rel %.3g); comparison stopped.', ...
      checks.cache_vs_direct_baseline.F_relative);
    [timings,lap]=LOCAL_lap(timings,'baseline_consistency',lap);
    fprintf('STAGE baseline: etaB direct %.16g history %.16g cache %.16g\n', ...
      direct.q10_baseline.bound.etaB,history.etaB,st0.F);

    % --- stage 7: pure L2 projection diagnostic (same leaf rule) ---
    stage='projection';
    projection=LOCAL_projection(cache,ends,geo,config,g,phi,ndof,Dinv,st0);
    projection.trace=LOCAL_trace_check(mesh,mx,my,c0+projection.dc,E);
    [timings,lap]=LOCAL_lap(timings,'projection',lap);
    fprintf('STAGE projection: sqrt(J_P)=%.10g (baseline eps %.10g) relres %.3g\n', ...
      projection.sqrt_JP,sqrt(sum(st0.eps2)),projection.relative_residual);

    % --- stage 8: at most three smoothed MM steps ---
    stage='mm';
    [mm,iterates]=LOCAL_mm(cache,ends,geo,config,g,phi,ndof,Dinv,st0);
    [timings,lap]=LOCAL_lap(timings,'mm',lap);
    stage='mm_trace_checks';
    for j=2:numel(iterates),iterates(j).trace=LOCAL_trace_check(mesh,mx,my,c0+iterates(j).dc,E);end
    iterates(1).trace=checks.baseline_trace;
    [timings,lap]=LOCAL_lap(timings,'mm_trace_checks',lap);
    [~,best]=min([iterates.F]);selected=iterates(best);
    fprintf('STAGE mm: %d accepted steps, F %.10g -> selected %s F %.10g\n',numel(iterates)-1, ...
      iterates(1).F,selected.name,selected.F);

    % --- stage 9: paired direct evaluation of p0 and the selected flux ---
    c_sel=c0+selected.dc;same=best==1;
    if ~same
      stage='direct_q10_selected';
      direct.q10_selected=LOCAL_direct(leaves,mesh,mx,my,mu,c_sel,geo,E,config, ...
        config.evaluation_order,config.end_order);
      [timings,lap]=LOCAL_lap(timings,'direct_q10_selected',lap);
    else
      direct.q10_selected=direct.q10_baseline;
    end
    stage='direct_q8_baseline';
    direct.q8_baseline=LOCAL_direct(leaves,mesh,mx,my,mu,c0,geo,E,config, ...
      config.check_order,config.check_end_order);
    [timings,lap]=LOCAL_lap(timings,'direct_q8_baseline',lap);
    if ~same
      stage='direct_q8_selected';
      direct.q8_selected=LOCAL_direct(leaves,mesh,mx,my,mu,c_sel,geo,E,config, ...
        config.check_order,config.check_end_order);
      [timings,lap]=LOCAL_lap(timings,'direct_q8_selected',lap);
    else
      direct.q8_selected=direct.q8_baseline;
    end
    stage='comparison';
    checks.cache_vs_direct_selected=LOCAL_cache_check(selected.state,direct.q10_selected);
    comparison=LOCAL_compare(direct,same,config);
    [timings,lap]=LOCAL_lap(timings,'comparison',lap);
    fprintf('STAGE compare: %s; R_linear Q10 %.10g -> %.10g; Q8 %.10g -> %.10g\n', ...
      comparison.classification,direct.q10_baseline.final.R_linear_mu_h, ...
      direct.q10_selected.final.R_linear_mu_h,direct.q8_baseline.final.R_linear_mu_h, ...
      direct.q8_selected.final.R_linear_mu_h);

    % --- stage 10: save and export ---
    stage='save';
    summary=struct('status',config.status,'mode',mode,'config',config, ...
      'inputs',struct('native_path',native_path,'derived_path',derived_path), ...
      'recovery',recovery,'basis_checks',basis_checks,'classification',classification, ...
      'dofs',dofinfo,'checks',checks,'history',rmfield(history,'etaK2'), ...
      'smoothing',mm.smoothing,'projection',rmfield(projection,{'dc','z','element'}), ...
      'mm_steps',mm.steps,'mm_stop',mm.stop,'candidates',LOCAL_candidates(iterates), ...
      'selected',struct('name',selected.name,'index',best,'is_baseline',same), ...
      'direct',LOCAL_direct_summary(direct),'comparison',comparison, ...
      'geometry',struct('CP_max',max(geo.CP),'CP_median',median(geo.CP)), ...
      'environment',struct('version',version,'platform',computer,'threads',maxNumCompThreads, ...
      'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS')));
    coefficients=struct('baseline',c0,'selected',c_sel,'projection',c0+projection.dc, ...
      'iterates',{arrayfun(@(it)c0+it.dc,iterates,'UniformOutput',false)},'iterate_names',{{iterates.name}});
    global_moments=struct('projection_dz',projection.z,'iterate_dz',{{iterates.z}});
    element=struct('CP',geo.CP,'states',{arrayfun(@(it)it.state.element,iterates,'UniformOutput',false)}, ...
      'projection',projection.element, ...
      'direct',LOCAL_direct_elements(direct));
    save(fullfile(output_dir,'evidence.mat'),'config','summary','coefficients','global_moments', ...
      'element','mm','-v7');
    [timings,~]=LOCAL_lap(timings,'save',lap);
    timings.matlab_function_seconds=toc(started);
    timings.unattributed_seconds=timings.matlab_function_seconds-LOCAL_stage_sum(timings);
    summary.timings=timings;
    LOCAL_json(fullfile(output_dir,'result.json'),summary);
    fprintf('COMPLETE time=%.1fs\n',toc(started));
  catch err
    LOCAL_json(fullfile(output_dir,'failure.json'),struct('stage',stage,'identifier',err.identifier, ...
      'message',err.message,'report',getReport(err,'extended','hyperlinks','off'), ...
      'elapsed_seconds',toc(started),'timings',timings));
    rethrow(err);
  end
end

%% ==================== Timing and bookkeeping ====================
% Mutually exclusive stage laps; nested MM sub-timers live only inside mm_steps.
function [t,lap]=LOCAL_lap(t,name,lap)
  % Stage time, then a log line with this MATLAB process RSS (launcher keeps the tree peak).
  t.(name)=toc(lap);[~,r]=system(sprintf('ps -o rss= -p %d',feature('getpid')));
  fprintf('LAP %-24s %9.2fs  rss %7.0f MB\n',name,t.(name),str2double(r)/1024);lap=tic;
end
function total=LOCAL_stage_sum(t)
  names=setdiff(fieldnames(t),{'matlab_function_seconds','unattributed_seconds'});total=0;
  for j=1:numel(names),total=total+t.(names{j});end
end
function list=LOCAL_candidates(iterates)
  list=struct('name',{iterates.name},'F',{iterates.F},'F_delta',{iterates.F_delta}, ...
    'trace',{iterates.trace});
end
function out=LOCAL_direct_summary(direct)
  names=fieldnames(direct);out=struct();
  for j=1:numel(names)
    d=direct.(names{j});out.(names{j})=struct('order',d.order,'end_order',d.end_order, ...
      'totals',rmfield(d.bound,'element'),'final',d.final);
  end
end
function out=LOCAL_direct_elements(direct)
  names=fieldnames(direct);out=struct();
  for j=1:numel(names),out.(names{j})=direct.(names{j}).bound.element;end
end

%% ==================== Frozen input recovery ====================
% Rebuild the run-03 tail from the native field once; compare, then freeze.
function [rebuilt,recovery]=LOCAL_rebuild(native,derived,config)
  mesh=native.mesh;source=native.config;
  assert(isequal(source.model,struct('beta',.5,'d',1,'L',1,'star_scale',1, ...
    'rho_center',4,'rho_negative',17,'rho_positive',17,'rho_background',1, ...
    'a_negative',.12,'a_positive',.20,'radius',.2)),'d1:Model','Frozen model mismatch.');
  assert(source.mesh.half_cells==6&&source.mesh.subdivisions==12&& ...
    source.mesh.interface_segments==80,'d1:Mesh','Frozen FEM mesh mismatch.');
  id=config.candidate_index;assert(native.modes(id).candidate&&native.modes(id).k==config.k_h, ...
    'd1:Candidate','Input candidate differs.');
  dc=derived.config;
  assert(isequal(dc.tail,config.tail)&&strcmp(dc.mode,'formal')&&dc.k_h==config.k_h&& ...
    dc.beta==config.beta&&dc.curve_segments==8192&&dc.maximum_subdivision==6&& ...
    dc.evaluation_order==10&&dc.end_order==20,'d1:Derived','Derived run configuration differs.');
  reduced=native.eigenvectors(:,id);P=LOCAL_constraint(mesh,config.beta);u=P*reduced;
  recovery.native_input=LOCAL_input(mesh,P,u,native);
  recovery.reduced_difference=max(abs(reduced-derived.reduced));
  [ext,info]=eq_tail_build_i95(mesh,u,config.mu_h,config.beta,config.tail(1),config.tail(2));
  info.field_checks=LOCAL_tailcheck(ext,ext.field,config.beta);
  nt=size(ext.triangles,1);nodes=reshape(ext.p2_points(ext.triangle_p2(:),:),nt,6,2);
  rebuilt=struct('mesh',ext,'mapx',LOCAL_poly(nodes(:,:,1)),'mapy',LOCAL_poly(nodes(:,:,2)), ...
    'mapu',LOCAL_poly(reshape(ext.field(ext.triangle_p2),nt,6)),'tail',info);
  recovery.tail=info;
end
function [mesh,frozen,recovery]=LOCAL_freeze(rebuilt,derived,recovery,config)
  mesh=rebuilt.mesh;nt=size(mesh.triangles,1);
  scale=max(abs(derived.full_field));
  recovery.elements=nt;recovery.p2_nodes=size(mesh.p2_points,1);
  recovery.field_relative_difference=max(abs(mesh.field-derived.full_field))/scale;
  recovery.mapx_difference=max(abs(rebuilt.mapx-derived.mapx),[],'all');
  recovery.mapy_difference=max(abs(rebuilt.mapy-derived.mapy),[],'all');
  recovery.mapu_relative_difference=max(abs(rebuilt.mapu-derived.mapu),[],'all')/max(abs(derived.mapu),[],'all');
  st=derived.result.tail;
  recovery.saved_tail=struct('elements',st.elements,'p2_nodes',st.p2_nodes, ...
    'zeta_abs_max',[st.sides.zeta_abs_max],'closing',[st.sides.closing_relative_amplitude]);
  recovery.zeta_abs_max_difference=max(abs([rebuilt.tail.sides.zeta_abs_max]-[st.sides.zeta_abs_max]));
  recovery.closing_difference=max(abs([rebuilt.tail.sides.closing_relative_amplitude]-[st.sides.closing_relative_amplitude]));
  ok=nt==config.expected_elements&&nt==st.elements&&recovery.p2_nodes==st.p2_nodes&& ...
    recovery.reduced_difference==0&&recovery.field_relative_difference<=config.field_tolerance&& ...
    recovery.mapx_difference<=config.geometry_tolerance&&recovery.mapy_difference<=config.geometry_tolerance&& ...
    recovery.mapu_relative_difference<=config.field_tolerance;
  recovery.identity_passed=ok;
  assert(ok,'d1:Recovery','Rebuilt tail differs from run-03 beyond ordinary roundoff; comparison stopped.');
  % Freeze: saved run-03 field arrays, rebuilt (identical) mesh topology.
  mesh.field=derived.full_field;
  k=find(strcmp({derived.fluxes.name},config.baseline_name));
  assert(isscalar(k),'d1:Baseline','Baseline flux not unique.');
  b=derived.fluxes(k);
  assert(b.s==config.s&&b.mu_residual==config.m_residual&&isequal(size(b.coeff),[nt,15]), ...
    'd1:BaselineConfig','Baseline flux shift, residual parameter or size differs.');
  frozen=struct('mapx',derived.mapx,'mapy',derived.mapy,'mapu',derived.mapu, ...
    'baseline',struct('name',b.name,'coeff',b.coeff));
end
function check=LOCAL_leafcheck(leaves,saved,config)
  check=struct('count',size(leaves,1),'saved_count',size(saved,1),'identical',false,'max_difference',NaN);
  if isequal(size(leaves),size(saved))
    check.max_difference=max(abs(leaves-saved),[],'all');check.identical=check.max_difference==0;
  end
  if strcmp(config.mode,'formal')
    assert(check.max_difference<=config.geometry_tolerance,'d1:Leaves', ...
      'Recomputed material leaves differ from run-03.');
  end
end
function h=LOCAL_history(derived,config)
  k=strcmp({derived.fluxes.name},config.baseline_name);b=derived.fluxes(k);
  h=struct('name',b.name,'etaB',b.bound.etaB,'eta9',b.bound.eta9,'bulkB',b.bound.bulkB, ...
    'end_norms',b.bound.end_norms,'eps2_total',b.bound.eps2_total,'mu_R',derived.result.mu_R, ...
    'U',derived.result.U,'R_linear_mu_h',b.scalars.R_linear_mu_h,'x_T',b.scalars.x_T(1), ...
    'dist_mu_h_conditional',b.scalars.dist_mu_h_conditional(1), ...
    'solve_relative_residual',b.solve.relative_residual,'solve_seconds',b.solve.solve_seconds, ...
    'evaluation_seconds',b.solve.evaluation_seconds,'etaK2',b.bound.element.etaK2, ...
    'unresolved_area',b.bound.unresolved_area);
end
function check=LOCAL_history_check(d,h,config)
  el=d.bound.element;
  check=struct('etaB_relative',abs(d.bound.etaB-h.etaB)/h.etaB, ...
    'eta9_relative',abs(d.bound.eta9-h.eta9)/h.eta9, ...
    'mu_R_difference',d.final.mu_R-h.mu_R,'U_difference',d.final.U-h.U, ...
    'mu_R_minus_m',d.final.mu_R-config.m_residual, ...
    'end_norm_difference',max(abs(d.bound.end_norms-h.end_norms)), ...
    'etaK2_max_relative',max(abs(el.etaK2-h.etaK2))/max(h.etaK2), ...
    'unresolved_area_difference',d.bound.unresolved_area-h.unresolved_area);
  if strcmp(config.mode,'formal')
    assert(check.etaB_relative<=config.history_tolerance&& ...
      abs(check.mu_R_minus_m)<=config.history_tolerance*config.m_residual,'d1:History', ...
      'Direct Q10 baseline does not reproduce run-03 (rel %.3g); comparison stopped.',check.etaB_relative);
  end
end
function check=LOCAL_moment_check(c,D,g,phi,ndof)
  % Shared global moments implied by the local coefficients must be single valued.
  mloc=c*D.';z=conj(phi).*mloc;
  re=accumarray(g(:),real(z(:)),[ndof,1],@max)-accumarray(g(:),real(z(:)),[ndof,1],@min);
  im=accumarray(g(:),imag(z(:)),[ndof,1],@max)-accumarray(g(:),imag(z(:)),[ndof,1],@min);
  check=struct('moment_spread',max(hypot(re,im)),'moment_scale',max(abs(z(:))));
end

%% ==================== Same-leaf Q10 quadratic cache ====================
% Per element, forms in dc=c-c0 with residuals of p0 combined pointwise first:
%   eps2 = dc'G0 dc - 2Re(dc'f) + E0,  int|R|^2 = dc'Gd dc + 2Re(dc'h) + R0,
%   int rho^{-1}|R|^2 = dc'Gdr dc + 2Re(dc'hr) + Rr0,  int R = m.dc + S0.
function cache=LOCAL_cache(leaves,mesh,mx,my,mu,c0,m,order,batch)
  nt=size(mx,1);nl=size(leaves,1);[qx,qy,qw]=LOCAL_duffy(order);nq=numel(qw);
  G0=zeros(nt,225);Gd=G0;Gdr=G0;f=complex(zeros(nt,15));h=f;hr=f;mm=zeros(nt,15);
  sc=zeros(nt,9);S0=complex(zeros(nt,1));
  for start=1:batch:nl
    ids=start:min(start+batch-1,nl);leaf=leaves(ids,:);t=leaf(:,1);n=numel(ids);
    va=leaf(:,2:3);ab=leaf(:,4:5)-va;ac=leaf(:,6:7)-va;scale=ab(:,1).*ac(:,2)-ab(:,2).*ac(:,1);
    assert(all(scale>0),'d1:Leaf','Reference leaf orientation failed.');
    un=leaf(:,8)==0;ct=c0(t,:);
    Ax=zeros(n,15,nq);Ay=Ax;Ad=Ax;Ar=Ax;
    af=complex(zeros(n,15));ah=af;ahr=af;am=zeros(n,15);as=zeros(n,9);aS=complex(zeros(n,1));
    for q=1:nq
      xx=va(:,1)+qx(q)*ab(:,1)+qy(q)*ac(:,1);yy=va(:,2)+qx(q)*ab(:,2)+qy(q)*ac(:,2);
      [u,gx,gy,~,J,d,pxy]=LOCAL_field(mx(t,:),my(t,:),mu(t,:),xx,yy);[vx,vy,dv]=LOCAL_rt(xx,yy);
      px=(J(:,1).*vx+J(:,2).*vy)./d;py=(J(:,3).*vx+J(:,4).*vy)./d;dvd=dv./d;
      rho=leaf(:,8);rho(un)=LOCAL_rho(pxy(un,1),pxy(un,2),mesh.cell_id(t(un)));
      w=qw(q)*scale.*d;
      % Physical residuals of p0, combined before any squaring.
      rgx=gx-sum(px.*ct,2);rgy=gy-sum(py.*ct,2);rd=sum(dvd.*ct,2)+m*rho.*u;
      sw=sqrt(w);Ax(:,:,q)=sw.*px;Ay(:,:,q)=sw.*py;Ad(:,:,q)=sw.*dvd;Ar(:,:,q)=(sw./sqrt(rho)).*dvd;
      af=af+(w.*rgx).*px+(w.*rgy).*py;ah=ah+(w.*rd).*dvd;ahr=ahr+(w.*rd./rho).*dvd;am=am+w.*dvd;
      ar2=abs(rd).^2;
      as=as+[w,w.*(abs(rgx).^2+abs(rgy).^2),w.*ar2,w.*ar2./rho,w./rho,w.*rho.*abs(u).^2, ...
        w.*(abs(gx).^2+abs(gy).^2),w.*un,w.*rho];
      aS=aS+w.*rd;
    end
    [tu,~,loc]=unique(t);Sl=sparse(loc,1:n,1,numel(tu),n);
    G0(tu,:)=G0(tu,:)+Sl*(LOCAL_gram(Ax)+LOCAL_gram(Ay));Gd(tu,:)=Gd(tu,:)+Sl*LOCAL_gram(Ad);
    Gdr(tu,:)=Gdr(tu,:)+Sl*LOCAL_gram(Ar);clear Ax Ay Ad Ar
    f(tu,:)=f(tu,:)+Sl*af;h(tu,:)=h(tu,:)+Sl*ah;hr(tu,:)=hr(tu,:)+Sl*ahr;mm(tu,:)=mm(tu,:)+Sl*am;
    sc(tu,:)=sc(tu,:)+Sl*as;S0(tu)=S0(tu)+Sl*aS;
  end
  sym=@(G)LOCAL_sym(reshape(G.',15,15,nt));
  cache=struct('G0',sym(G0),'Gd',sym(Gd),'Gdr',sym(Gdr),'f',f,'h',h,'hr',hr,'m',mm, ...
    'area',sc(:,1),'E0',sc(:,2),'R0',sc(:,3),'Rr0',sc(:,4),'rinv',sc(:,5),'mass',sc(:,6), ...
    'grad2',sc(:,7),'unres_area',sc(:,8),'rho_integral',sc(:,9),'S0',S0,'order',order);
end
function G=LOCAL_gram(A)
  % A is n x 15 x nq weighted samples; returns n x 225 per-leaf Grams A_l^T A_l.
  P=permute(A,[2,3,1]);G=pagemtimes(P,'none',P,'transpose');G=reshape(G,225,[]).';
end
function G=LOCAL_sym(G)
  G=(G+permute(G,[2,1,3]))/2;
end
function [ends,check]=LOCAL_endcache(mesh,mx,my,c0,E,order)
  % Left (side 1) and right (side 2) artificial-end Grams kept separately:
  %   ||g||^2 = sum_j dc_j'G_j dc_j + 2Re(dc_j'e_j) + g0_j.
  [z,w]=LOCAL_gauss(order);check=struct('side',{},'edges',{},'length',{},'x',{},'g0',{});
  for side=1:2
    loc=mesh.xmin;if side==2,loc=mesh.xmax;end
    edges=find(abs(E.midpoints(:,1)-loc)<1e-12);[ti,le]=find(ismember(E.ids,edges));
    k=numel(ti);G=zeros(15,15,k);e=complex(zeros(k,15));g0=zeros(k,1);len=0;xs=zeros(k,1);
    for j=1:k
      t=ti(j);ee=le(j);[x,y,n]=LOCAL_edge(ee,z);[vx,vy]=LOCAL_rt(x,y);
      [~,~,~,~,J,~,pxy]=LOCAL_field(repmat(mx(t,:),order,1),repmat(my(t,:),order,1),zeros(order,6),x,y);
      if ee==1,tx=J(:,1);ty=J(:,3);elseif ee==2,tx=-J(:,1)+J(:,2);ty=-J(:,3)+J(:,4);else,tx=-J(:,2);ty=-J(:,4);end
      hn=vx*n(1)+vy*n(2);wt=w./hypot(tx,ty);h0=hn*c0(t,:).';
      G(:,:,j)=hn'*(wt.*hn);e(j,:)=(hn'*(wt.*h0)).';g0(j)=sum(wt.*abs(h0).^2);
      len=len+sum(w.*hypot(tx,ty));xs(j)=max(abs(pxy(:,1)-loc));
    end
    ends(side)=struct('elements',ti,'G',(G+permute(G,[2,1,3]))/2,'e',e,'g0',g0); %#ok<AGROW>
    check(side)=struct('side',side,'edges',numel(edges),'length',len,'x',max(xs),'g0',sum(g0)); %#ok<AGROW>
  end
  assert(all(abs([check.length]-1)<1e-12)&&all([check.x]<1e-12),'d1:Ends','End wall Grams failed.');
end

%% ==================== Cache evaluation of Theorem B and F_delta ====================
% x=eps_K, y=C_P omega_K, z^2=varpi_K^2/s; A_delta, B_K and the end norms.
function v=LOCAL_quad(G,dc)
  xr=permute(real(dc),[2,3,1]);xi=permute(imag(dc),[2,3,1]);
  v=sum(xr.*pagemtimes(G,xr)+xi.*pagemtimes(G,xi),1);v=v(:);
end
function st=LOCAL_state(cache,ends,dc,geo,config,delta)
  s=config.s;Cend=(2*sqrt(s*config.rho_min))^(-.5);
  if isempty(delta),delta=struct('K',0,'zero',0,'minus',0,'plus',0);end
  lin=@(v)real(sum(conj(dc).*v,2));
  eps2=LOCAL_quad(cache.G0,dc)-2*lin(cache.f)+cache.E0;
  R2=LOCAL_quad(cache.Gd,dc)+2*lin(cache.h)+cache.R0;
  Rr2=LOCAL_quad(cache.Gdr,dc)+2*lin(cache.hr)+cache.Rr0;
  intR=sum(dc.*cache.m,2)+cache.S0;
  osc2=R2-abs(intR).^2./cache.area;varpi2=abs(intR).^2./cache.area.^2.*cache.rinv;
  g2=zeros(1,2);
  for side=1:2
    en=ends(side);t=en.elements;d=dc(t,:);
    g2(side)=sum(LOCAL_quad(en.G,d)+2*real(sum(conj(d).*en.e,2))+en.g0);
  end
  pos=@(v)max(v,0);
  b2=eps2+Rr2/s;b1=(sqrt(pos(eps2))+geo.CP.*sqrt(pos(osc2))).^2+varpi2/s;
  etaK2=min(b1,b2);endn=sqrt(pos(g2));F=sqrt(sum(etaK2))+Cend*sum(endn);
  x2=eps2;y2=geo.CP.^2.*osc2;z2=varpi2/s;dK=delta.K;
  Ad=(sqrt(pos(x2+dK^2))+sqrt(pos(y2+dK^2))).^2+z2;Bk=b2;branch1=Ad<Bk;
  T=sum(min(Ad,Bk));a=[sqrt(pos(T+delta.zero^2)),sqrt(pos(Cend^2*g2(1)+delta.minus^2)), ...
    sqrt(pos(Cend^2*g2(2)+delta.plus^2))];
  % Cancellation diagnostics: raw cache values below zero are never clamped silently.
  negative=struct('eps2',sum(eps2<0),'osc2',sum(osc2<0),'Rr2',sum(Rr2<0),'R2',sum(R2<0), ...
    'ends',sum(g2<0),'min_eps2',min(eps2),'min_osc2',min(osc2),'min_Rr2',min(Rr2));
  st=struct('F',F,'F_delta',sum(a),'a',a,'T_delta',T,'bulk',sqrt(sum(etaK2)),'end_norms',endn, ...
    'C_end',Cend,'end_contribution',Cend*sum(endn),'eps2_total',sum(eps2), ...
    'osc2_total',sum(osc2),'weighted_osc_total',sum(y2),'mean_part_over_s',sum(z2), ...
    'body_weighted_total',sum(Rr2),'branch1_elements',sum(b1<b2), ...
    'delta_branch1_elements',sum(branch1),'negative',negative, ...
    'eps2',eps2,'osc2',osc2,'varpi2',varpi2,'Rr2',Rr2,'R2',R2,'g2',g2,'x2',x2,'y2',y2,'z2',z2, ...
    'Ad',Ad,'Bk',Bk,'branch1',branch1, ...
    'element',struct('etaK2',etaK2,'branch1',b1,'branch2',b2,'eps2',eps2,'osc2',osc2, ...
    'varpi2',varpi2,'Rr2',Rr2));
end
function check=LOCAL_cache_check(st,d)
  el=d.bound.element;rel=@(a,b,sc)max(abs(a-b))/max(sc);
  check=struct('F_cache',st.F,'F_direct',d.bound.etaB,'F_relative',abs(st.F-d.bound.etaB)/d.bound.etaB, ...
    'eps2_max_relative',rel(st.eps2,el.eps2,el.eps2),'osc2_max_relative',rel(st.osc2,el.osc2,el.osc2), ...
    'varpi2_max_relative',rel(st.varpi2,el.varpi2,el.varpi2+eps), ...
    'etaK2_max_relative',rel(st.element.etaK2,el.etaK2,el.etaK2), ...
    'branch_agreement',mean((st.element.branch1<st.element.branch2)==(el.branch1<el.branch2)), ...
    'end_norm_difference',max(abs(st.end_norms-d.bound.end_norms)),'negative',st.negative);
  check.consistent=check.F_relative<=1e-8;
end

%% ==================== Pure L2 projection diagnostic ====================
% min_p ||grad u - p||^2 over X_h with the same leaf rule: G0 dz = f (in dc).
function out=LOCAL_projection(cache,ends,geo,config,g,phi,ndof,Dinv,st0)
  nt=size(g,1);q=-cache.f;
  [z,info,A,rhs]=LOCAL_solve_global(cache.G0,q,g,phi,ndof,Dinv);
  dc=LOCAL_local(z,g,phi,Dinv);st=LOCAL_state(cache,ends,dc,geo,config,[]);
  r=-(A*z+rhs);tcorr=tic;corr=real(r'*(A\r));info.correction_solve_seconds=toc(tcorr);
  JP=sum(st.eps2);
  out=struct('J_P',JP,'sqrt_JP',sqrt(JP),'relative_residual',info.relative_residual, ...
    'residual_norm',norm(r),'rhs_norm',norm(rhs),'ordinary_correction',corr, ...
    'corrected_ordinary_estimate',sqrt(max(JP-corr,0)),'baseline_eps',sqrt(sum(st0.eps2)), ...
    'baseline_F',st0.F,'projection_F_cache_not_eligible',st.F,'projection_end_norms',st.end_norms, ...
    'negative_eps2',st.negative.eps2,'solve',info,'elements',nt, ...
    'label','ORDINARY_PROJECTION_DIAGNOSTIC_NOT_A_CERTIFIED_FLOOR', ...
    'dc',dc,'z',z,'element',struct('eps2',st.eps2));
end

%% ==================== Smoothed majorize-minimize steps ====================
% p-next (D3)-(D4): frozen branches, Young weights theta_K, outer weights w_j.
function [mm,iterates]=LOCAL_mm(cache,ends,geo,config,g,phi,ndof,Dinv,st0)
  nt=size(g,1);epsm=config.smoothing_factor*max(st0.F,1e-12);
  delta=struct('K',epsm/(8*sqrt(nt)),'zero',epsm/4,'minus',epsm/4,'plus',epsm/4);
  mm.smoothing=struct('F_p0_cache',st0.F,'eps_sm',epsm,'delta_K',delta.K,'delta_0',delta.zero, ...
    'delta_end',delta.minus,'nT',nt);
  dc=complex(zeros(nt,15));z=complex(zeros(ndof,1));st=LOCAL_state(cache,ends,dc,geo,config,delta);
  iterates=LOCAL_iterate('baseline',dc,z,st);steps=struct([]);mm.stop='max_solves_reached';
  mm.proposals={};   % full-step majorant minimizers, kept even when rejected
  for n=1:config.mm_max_solves
    tstep=tic;fr=LOCAL_freeze_branches(st,delta);Qold=LOCAL_Q(fr,st,config,delta);
    [H,q]=LOCAL_majorant(cache,ends,geo,fr,config);tbuild=toc(tstep);
    [znew,info]=LOCAL_solve_global(H,q,g,phi,ndof,Dinv);clear H q
    dcnew=LOCAL_local(znew,g,phi,Dinv);mm.proposals{end+1}=dcnew;teval=tic;accepted=false;tried=[];
    for t=config.backtrack
      dct=dc+t*(dcnew-dc);stt=LOCAL_state(cache,ends,dct,geo,config,delta);Qt=LOCAL_Q(fr,stt,config,delta);
      tried(end+1,:)=[t,Qt,stt.F_delta,stt.F]; %#ok<AGROW>
      if Qt<=Qold,accepted=true;break,end
    end
    rec=struct('step',n,'Q_old',Qold,'F_delta_old',st.F_delta,'F_delta_old_squared',st.F_delta^2, ...
      'majorant_identity_relative',abs(Qold-st.F_delta^2)/st.F_delta^2,'F_old',st.F, ...
      'branch1_elements_frozen',sum(fr.branch1),'branch2_elements_frozen',sum(~fr.branch1), ...
      'theta_min',min(fr.theta(fr.branch1)),'theta_max',max(fr.theta(fr.branch1)), ...
      'weights',fr.w,'tried',tried,'accepted',accepted,'step_length',NaN,'Q_new',NaN, ...
      'F_delta_new',NaN,'F_new',NaN,'solve',info,'build_seconds',tbuild, ...
      'evaluation_seconds',0,'eps2_total_new',NaN,'end_norms_new',[NaN,NaN], ...
      'branch1_elements_new',NaN,'negative_new',[]);
    if accepted
      dc=dct;z=z+t*(znew-z);st=stt;
      rec.step_length=t;rec.Q_new=Qt;rec.F_delta_new=st.F_delta;rec.F_new=st.F;
      rec.eps2_total_new=st.eps2_total;rec.end_norms_new=st.end_norms;
      rec.branch1_elements_new=st.branch1_elements;rec.negative_new=st.negative;
      iterates(end+1)=LOCAL_iterate(sprintf('mm_step%d',n),dc,z,st); %#ok<AGROW>
    end
    rec.evaluation_seconds=toc(teval);rec.step_seconds=toc(tstep);
    if isempty(steps),steps=rec;else,steps(end+1)=rec;end %#ok<AGROW>
    fprintf('STAGE mm%d: Q %.12g -> %.12g (t=%g) F %.10g -> %.10g relres %.2g\n',n,Qold, ...
      rec.Q_new,rec.step_length,rec.F_old,rec.F_new,info.relative_residual);
    if ~accepted,mm.stop='no_Q_decrease_after_backtracking';break,end
  end
  mm.steps=steps;
end
function it=LOCAL_iterate(name,dc,z,st)
  it=struct('name',name,'dc',dc,'z',z,'F',st.F,'F_delta',st.F_delta,'state',st,'trace',[]);
end
function fr=LOCAL_freeze_branches(st,delta)
  fr.branch1=st.branch1;
  fr.theta=sqrt(max(st.y2+delta.K^2,0))./sqrt(max(st.x2+delta.K^2,0));
  fr.w=st.a/st.F_delta;
end
function Q=LOCAL_Q(fr,st,config,delta)
  s=config.s;Cend=st.C_end;dK2=delta.K^2;th=fr.theta;
  L=st.eps2+st.Rr2/s;b=fr.branch1;
  L(b)=(1+th(b)).*(st.x2(b)+dK2)+(1+1./th(b)).*(st.y2(b)+dK2)+st.z2(b);
  Q=(sum(L)+delta.zero^2)/fr.w(1)+(Cend^2*st.g2(1)+delta.minus^2)/fr.w(2)+ ...
    (Cend^2*st.g2(2)+delta.plus^2)/fr.w(3);
end
function [H,q]=LOCAL_majorant(cache,ends,geo,fr,config)
  % Element Hermitian quadratic coefficients of Q_n in dc (constants omitted).
  s=config.s;Cend=(2*sqrt(s*config.rho_min))^(-.5);nt=size(cache.f,1);
  b=fr.branch1;th=fr.theta;a=cache.area;
  c1=ones(nt,1);c2=zeros(nt,1);c3=zeros(nt,1);
  c1(b)=1+th(b);c2(b)=(1+1./th(b)).*geo.CP(b).^2;c3(b)=cache.rinv(b)./(s*a(b).^2);
  page=@(v)reshape(v,1,1,nt);mt=reshape(cache.m.',15,1,nt);M=mt.*permute(mt,[2,1,3]);
  % Branch 1: (1+th)eps2+(1+1/th)C_P^2 osc2+varpi2/s; branch 2: eps2+int rho^{-1}|R|^2/s.
  H=page(c1).*cache.G0+page(c2).*(cache.Gd-M./page(a))+page(c3).*M;
  H(:,:,~b)=H(:,:,~b)+cache.Gdr(:,:,~b)/s;
  ms=cache.m.*cache.S0;
  q=-c1.*cache.f+c2.*(cache.h-ms./a)+c3.*ms;q(~b,:)=q(~b,:)+cache.hr(~b,:)/s;
  H=H/fr.w(1);q=q/fr.w(1);
  for side=1:2
    en=ends(side);cw=Cend^2/fr.w(side+1);
    for j=1:numel(en.elements)
      t=en.elements(j);H(:,:,t)=H(:,:,t)+cw*en.G(:,:,j);q(t,:)=q(t,:)+cw*en.e(j,:);
    end
  end
end

%% ==================== Global RT2 assembly and solve ====================
% Same moment space, signs and quasi-periodic phases as I9.5 LOCAL_solve.
function [z,info,A,rhs]=LOCAL_solve_global(H,q,g,phi,ndof,Dinv)
  nt=size(g,1);tasm=tic;
  Hm=pagemtimes(pagemtimes(Dinv.',H),Dinv);qm=Dinv.'*q.';
  pt=phi.';gt=g.';V=conj(reshape(pt,15,1,nt)).*Hm.*reshape(pt,1,15,nt);
  I=repmat(reshape(gt,15,1,nt),1,15,1);J=repmat(reshape(gt,1,15,nt),15,1,1);
  A=sparse(I(:),J(:),V(:),ndof,ndof);clear I J V Hm
  A=(A+A')/2;   % exact Hermitian storage so the sparse solver takes the Cholesky path
  rhs=full(sparse(gt(:),1,conj(pt(:)).*qm(:),ndof,1));tasm=toc(tasm);
  tsol=tic;z=-(A\rhs);tsol=toc(tsol);res=norm(A*z+rhs)/norm(rhs);
  info=struct('relative_residual',res,'nnz',nnz(A),'ndof',ndof,'assembly_seconds',tasm, ...
    'solve_seconds',tsol);
  assert(isfinite(res)&&res<1e-8,'d1:Solve','Quadratic solve failed (relative residual %.3g).',res);
  if nargout<3,clear A,end
end
function dc=LOCAL_local(z,g,phi,Dinv)
  dc=(phi.*z(g))*Dinv.';
end

%% ==================== Direct evaluation and final formulas ====================
% Two-pass leaf integration at residual parameter m, then C3, B.1 (15), (11).
function out=LOCAL_direct(leaves,mesh,mx,my,mu,c,geo,E,config,order,end_order)
  t0=tic;
  [ev1,ev2]=LOCAL_twopass(leaves,mesh,mx,my,mu,c,config.m_residual,order,config.batch_size);
  endsq=LOCAL_ends(mesh,mx,my,mu,c,E,end_order);
  bound=LOCAL_bound(ev1,ev2,geo,config.s,config,endsq);
  bound.element.Rr2=ev1.rinvR2;
  final=LOCAL_final(bound,ev1,config);
  out=struct('order',order,'end_order',end_order,'bound',bound,'final',final,'seconds',toc(t0));
end
function f=LOCAL_final(b,ev1,config)
  s=config.s;mu_h=config.mu_h;k_h=config.k_h;m=config.m_residual;
  mass=sum(ev1.mass);U=sqrt(mass);muR=sum(ev1.grad2)/mass;
  transfer_m=abs(muR-m)*U/sqrt(s);etaR=b.etaB+transfer_m;tauR=etaR/U;
  shift_h=abs(mu_h-muR)/sqrt(s);tauh=tauR+shift_h;
  lin=@(t,mm)t/2*(t+sqrt(t^2+4*(mm+s)));R=lin(tauh,mu_h);
  lp=config.lambda_plus;xT=(lp+s)*tauR^2/((lp-muR)+(lp+s)*tauR^2/(muR+s));
  Rc=max(abs(mu_h-(muR-xT)),abs(mu_h-muR));
  klin=[sqrt(max(mu_h-R,0)),sqrt(mu_h+R)];kcond=[sqrt(max(muR-xT,0)),sqrt(max(muR,0))];
  f=struct('status',config.status,'m_residual',m,'mu_R',muR,'U',U,'mass',mass, ...
    'grad2',sum(ev1.grad2),'mu_R_minus_m',muR-m,'mu_R_minus_mu_h',muR-mu_h, ...
    'eta_m',b.etaB,'transfer_m_to_mu_R',transfer_m,'eta_R',etaR,'tau_R',tauR, ...
    'transfer_mu_R_to_mu_h_in_tau',shift_h,'tau_h',tauh,'R_linear_mu_h',R, ...
    'R_linear_mu_R',lin(tauR,muR),'mu_interval_linear',[mu_h-R,mu_h+R], ...
    'k_interval_linear',klin,'k_halfwidth_linear_direct',max(abs(klin-k_h)), ...
    'k_halfwidth_linear_first_order',R/(2*k_h),'lambda_plus',lp, ...
    'factor_F',(lp+s)/(lp-muR),'x_T',xT,'mu_interval_conditional',[muR-xT,muR], ...
    'R_conditional_mu_h',Rc,'k_interval_conditional',kcond, ...
    'k_distance_conditional_direct',max(abs(kcond-k_h)), ...
    'k_halfwidth_conditional_first_order',Rc/(2*k_h), ...
    'gradient_difference',sqrt(b.eps2_total),'H_plus','UNVERIFIED_ASSUMPTION', ...
    'R_linear_over_reference',R./config.radius_reference, ...
    'R_conditional_over_reference',Rc./config.radius_reference);
end
function c=LOCAL_compare(direct,same,config)
  q10b=direct.q10_baseline.final;q10s=direct.q10_selected.final;
  q8b=direct.q8_baseline.final;q8s=direct.q8_selected.final;
  names={'eta_m','eta_R','R_linear_mu_h','x_T','R_conditional_mu_h','gradient_difference'};
  c=struct('rule',config.classification_rule,'quantities',struct());
  for j=1:numel(names)
    nm=names{j};d10=q10s.(nm)-q10b.(nm);d8=q8s.(nm)-q8b.(nm);
    sens=max(abs(q10b.(nm)-q8b.(nm)),abs(q10s.(nm)-q8s.(nm)));
    c.quantities.(nm)=struct('baseline_q10',q10b.(nm),'selected_q10',q10s.(nm), ...
      'baseline_q8',q8b.(nm),'selected_q8',q8s.(nm),'change_q10',d10,'change_q8',d8, ...
      'relative_change_q10',d10/q10b.(nm),'relative_change_q8',d8/q8b.(nm), ...
      'q10_q8_sensitivity',sens);
  end
  r=c.quantities.R_linear_mu_h;
  if same
    c.classification='NO_CHANGE_BASELINE_SELECTED';
  elseif r.change_q10<-r.q10_q8_sensitivity&&r.change_q8<-r.q10_q8_sensitivity
    c.classification='IMPROVED_RESOLVED';
  elseif r.change_q10>r.q10_q8_sensitivity&&r.change_q8>r.q10_q8_sensitivity
    c.classification='WORSE_RESOLVED';
  else
    c.classification='UNRESOLVED';
  end
end

%% ==================== Copied unchanged from eq_temple_i95.m ====================
% Theorem-B bound assembly, RT2 dofs, geometry, two-pass evaluation, input
% restoration, RT2 reference space, ends, partition, field and quadrature.
function out=LOCAL_bound(ev1,ev2,geo,s,config,endsq)
  Cend=(2*sqrt(s*config.rho_min))^(-.5);
  Rbar2=(ev1.ReR.^2+ev1.ImR.^2)./ev1.area.^2;varpi2=Rbar2.*ev1.rinv;
  b2=ev1.eps2+ev1.rinvR2/s;b1=(sqrt(ev1.eps2)+geo.CP.*sqrt(max(ev2.osc2,0))).^2+varpi2/s;
  b1(~isfinite(b1))=Inf;etaK2=min(b1,b2);endn=sqrt(endsq);
  out=struct('etaB',sqrt(sum(etaK2))+Cend*sum(endn),'eta9',sqrt(sum(b2))+Cend*sum(endn), ...
    'bulkB',sqrt(sum(etaK2)),'bulk9',sqrt(sum(b2)),'end_norms',endn,'C_end',Cend, ...
    'end_contribution',Cend*sum(endn),'branch1_elements',sum(b1<b2), ...
    'eps2_total',sum(ev1.eps2),'body_weighted_total',sum(ev1.rinvR2), ...
    'osc2_total',sum(ev2.osc2),'varpi2_total',sum(varpi2), ...
    'weighted_osc_total',sum(geo.CP.^2.*ev2.osc2),'mean_part_over_s',sum(varpi2)/s, ...
    'unresolved_area',sum(ev1.unres_area),'unresolved_body_width',sum(ev1.unres_body_max-ev1.unres_body_min), ...
    'unresolved_mass_width',sum(ev1.unres_mass_max-ev1.unres_mass_min), ...
    'unresolved_osc2',sum(ev2.osc2_unresolved), ...
    'element',struct('etaK2',etaK2,'branch1',b1,'branch2',b2,'eps2',ev1.eps2,'osc2',ev2.osc2,'varpi2',varpi2));
end
function [g,phi,ndof,info]=LOCAL_dofs(mesh,E,nt,beta)
  ne=size(mesh.edges,1);bottom=E.periodic(:,1);top=E.periodic(:,2);
  master=(1:ne)';master(top)=bottom;ephase=ones(ne,1);ephase(top)=exp(1i*beta);
  independent=true(ne,1);independent(top)=false;pos=zeros(ne,1);
  nind=nnz(independent);pos(independent)=1:nind;
  g=zeros(nt,15);phi=complex(zeros(nt,15));
  for e=1:3
    edge=E.ids(:,e);
    for m=1:3
      l=(e-1)*3+m;g(:,l)=3*(pos(master(edge))-1)+m;phi(:,l)=E.signs(:,e,m).*ephase(edge);
    end
  end
  g(:,10:15)=3*nind+6*((1:nt)'-1)+(1:6);phi(:,10:15)=1;ndof=3*nind+6*nt;
  info=struct('edges',ne,'independent_edges',nind,'edge_dofs',3*nind,'interior_dofs',6*nt,'ndof',ndof);
end
function geo=LOCAL_geometry(mx,my)
  nt=size(mx,1);V=[0,0;1,0;0,1];jmax=zeros(nt,1);dmin=zeros(nt,1);dmax=zeros(nt,1);
  for v=1:3
    x=V(v,1);y=V(v,2);
    j11=mx(:,2)+2*mx(:,4)*x+mx(:,5)*y;j12=mx(:,3)+mx(:,5)*x+2*mx(:,6)*y;
    j21=my(:,2)+2*my(:,4)*x+my(:,5)*y;j22=my(:,3)+my(:,5)*x+2*my(:,6)*y;
    f=j11.^2+j12.^2+j21.^2+j22.^2;dt=j11.*j22-j12.*j21;
    jmax=max(jmax,sqrt((f+sqrt(max(f.^2-4*dt.^2,0)))/2));
  end
  ax=mx;ay=my;
  dc=[ax(:,2).*ay(:,3)-ax(:,3).*ay(:,2), ...
    2*ax(:,4).*ay(:,3)+ax(:,2).*ay(:,5)-ax(:,5).*ay(:,2)-2*ax(:,3).*ay(:,4), ...
    ax(:,5).*ay(:,3)+2*ax(:,2).*ay(:,6)-2*ax(:,6).*ay(:,2)-ax(:,3).*ay(:,5), ...
    2*ax(:,4).*ay(:,5)-2*ax(:,5).*ay(:,4), ...
    4*(ax(:,4).*ay(:,6)-ax(:,6).*ay(:,4)),2*ax(:,5).*ay(:,6)-2*ax(:,6).*ay(:,5)];
  for t=1:nt,dmin(t)=LOCAL_detmin(dc(t,:));dmax(t)=-LOCAL_detmin(-dc(t,:));end
  assert(all(dmin>0),'i95:Jacobian','Nonpositive Jacobian.');
  CP=jmax/pi.*sqrt(dmax./dmin);
  geo=struct('jmax',jmax,'dmin',dmin,'dmax',dmax,'CP',CP);
end

%% ==================== Direct two-pass evaluation ====================
% Pass 1 forms element sums of differences; pass 2 the mean-free oscillation.
function [ev1,ev2]=LOCAL_twopass(leaves,mesh,mx,my,mu,c,muv,order,batch)
  ev1=LOCAL_evaluate(leaves,mesh,mx,my,mu,c,muv,order,batch,[]);
  Rbar=complex(ev1.ReR,ev1.ImR)./ev1.area;
  ev2=LOCAL_evaluate(leaves,mesh,mx,my,mu,c,muv,order,batch,Rbar);
end
function out=LOCAL_evaluate(leaves,mesh,mx,my,mu,c,muv,order,batch,Rbar)
  nt=size(mx,1);nl=size(leaves,1);[qx,qy,qw]=LOCAL_duffy(order);pass1=isempty(Rbar);
  cand=[1,4,17];ncol=14;if ~pass1,ncol=2;end;total=zeros(nt,ncol);
  for start=1:batch:nl
    ids=start:min(start+batch-1,nl);leaf=leaves(ids,:);t=leaf(:,1);n=numel(ids);
    va=leaf(:,2:3);ab=leaf(:,4:5)-va;ac=leaf(:,6:7)-va;scale=ab(:,1).*ac(:,2)-ab(:,2).*ac(:,1);
    assert(all(scale>0),'i95:Leaf','Reference leaf orientation failed.');
    un=leaf(:,8)==0;acc=zeros(n,ncol);ct=c(t,:);
    for q=1:numel(qw)
      xx=va(:,1)+qx(q)*ab(:,1)+qy(q)*ac(:,1);yy=va(:,2)+qx(q)*ab(:,2)+qy(q)*ac(:,2);
      [u,gx,gy,~,J,d,pxy]=LOCAL_field(mx(t,:),my(t,:),mu(t,:),xx,yy);[vx,vy,dv]=LOCAL_rt(xx,yy);
      hx=sum(vx.*ct,2);hy=sum(vy.*ct,2);dp=sum(dv.*ct,2)./d;
      px=(J(:,1).*hx+J(:,2).*hy)./d;py=(J(:,3).*hx+J(:,4).*hy)./d;
      rho=leaf(:,8);rho(un)=LOCAL_rho(pxy(un,1),pxy(un,2),mesh.cell_id(t(un)));
      R=dp+muv*rho.*u;w=qw(q)*scale.*d;
      if pass1
        a2=abs(R).^2;
        acc(:,1:10)=acc(:,1:10)+[w,w.*(abs(gx-px).^2+abs(gy-py).^2),w.*real(R),w.*imag(R), ...
          w.*a2,w.*a2./rho,w./rho,w.*rho.*abs(u).^2,w.*(abs(gx).^2+abs(gy).^2),w.*un];
        if any(un)
          Rc=dp(un)+muv*u(un).*cand;body=abs(Rc).^2./cand;mass=abs(u(un)).^2.*cand;wu=w(un);
          % Pointwise candidate-material envelope, as in I9.4 (not interval arithmetic).
          acc(un,11)=acc(un,11)+wu.*min(body,[],2);acc(un,12)=acc(un,12)+wu.*max(body,[],2);
          acc(un,13)=acc(un,13)+wu.*min(mass,[],2);acc(un,14)=acc(un,14)+wu.*max(mass,[],2);
        end
      else
        o=w.*abs(R-Rbar(t)).^2;acc=acc+[o,o.*un];
      end
    end
    total=total+sparse(t,1:n,1,nt,n)*acc;
  end
  if pass1
    names={'area','eps2','ReR','ImR','R2','rinvR2','rinv','mass','grad2','unres_area', ...
      'unres_body_min','unres_body_max','unres_mass_min','unres_mass_max'};
  else
    names={'osc2','osc2_unresolved'};
  end
  out=cell2struct(num2cell(total,1),names,2);
end
function check=LOCAL_trace_check(mesh,mx,my,c,E)
  % Physical Piola normal continuity, including reversal, at five points per edge.
  nt=size(c,1);[z,~]=LOCAL_gauss(5);ne=size(mesh.edges,1);L=zeros(nt,15);Vv=complex(zeros(nt,15));
  for e=1:3
    [x,y,n]=LOCAL_edge(e,z);k=E.kappa(:,e);sg=E.epsilon(:,e);
    for q=1:5
      [vx,vy]=LOCAL_rt(x(q),y(q));[~,~,~,~,J]=LOCAL_field(mx,my,zeros(size(mx)),x(q),y(q));
      if e==1,tx=J(:,1);ty=J(:,3);elseif e==2,tx=-J(:,1)+J(:,2);ty=-J(:,3)+J(:,4);else,tx=-J(:,2);ty=-J(:,4);end
      qq=repmat(q,nt,1);qq(k<0)=6-q;col=(e-1)*5+q;
      L(:,col)=sub2ind([ne,5],E.ids(:,e),qq);Vv(:,col)=((c*vx')*n(1)+(c*vy')*n(2))./hypot(tx,ty).*sg;
    end
  end
  % Every (edge, point) group must carry one physical normal trace value.
  L=L(:);Vv=Vv(:);rmax=accumarray(L,real(Vv),[ne*5,1],@max,NaN);rmin=accumarray(L,real(Vv),[ne*5,1],@min,NaN);
  imax=accumarray(L,imag(Vv),[ne*5,1],@max,NaN);imin=accumarray(L,imag(Vv),[ne*5,1],@min,NaN);
  jump=max(hypot(rmax-rmin,imax-imin),[],'omitnan');trace=reshape(complex(rmax,imax),ne,5);
  qp=max(abs(trace(E.periodic(:,2),:)-exp(.5i)*trace(E.periodic(:,1),:)),[],'all');
  scale=max(abs(trace),[],'all','omitnan');
  check=struct('internal_normal_jump',jump,'qp_normal_jump',qp,'trace_scale',scale);
  assert(max(jump,qp)<1e-8*max(1,scale),'i95:PiolaTrace','Physical Piola normal continuity failed.');
end

%% ==================== Frozen native input (from I9.4) ====================
% Restore exactly the saved reduced coordinates with the declared beta phase.
function check=LOCAL_tailcheck(mesh,u,beta)
  p=mesh.p2_points;tol=1e-9;top=find(abs(p(:,2)-.5)<tol);bot=find(abs(p(:,2)+.5)<tol);
  [~,a]=sort(p(top,1));top=top(a);[~,a]=sort(p(bot,1));bot=bot(a);
  ends=abs(p(:,1)-mesh.xmin)<tol|abs(p(:,1)-mesh.xmax)<tol;
  check=struct('qp_field_defect',max(abs(u(top)-exp(1i*beta)*u(bot))),'end_value_defect',max(abs(u(ends))), ...
    'elements',size(mesh.triangles,1),'xmin',mesh.xmin,'xmax',mesh.xmax);
  assert(numel(top)==numel(bot)&&check.qp_field_defect<1e-12*max(abs(u))&&check.end_value_defect==0, ...
    'i95:TailField','Tail field violates quasi-periodicity or the zero outer wall.');
end
% Restore exactly the saved reduced coordinates with the declared beta phase.
function P=LOCAL_constraint(mesh,beta)
  p=mesh.p2_points;n=size(p,1);tol=1e-11;
  top=find(abs(p(:,2)-.5)<tol);bot=find(abs(p(:,2)+.5)<tol);
  [~,a]=sort(p(top,1));top=top(a);[~,a]=sort(p(bot,1));bot=bot(a);
  dir=find(abs(p(:,1)-mesh.xmin)<tol|abs(p(:,1)-mesh.xmax)<tol);
  master=(1:n)';master(top)=bot;active=true(n,1);active(dir)=false;
  masters=unique(master(active));[found,index]=ismember(master,masters);
  phase=ones(n,1);phase(top)=exp(1i*beta);ids=find(active&found);
  P=sparse(ids,index(ids),phase(ids),n,numel(masters));
end
function check=LOCAL_input(mesh,P,u,data)
  tr=mesh.triangles;nt=size(tr,1);nv=size(mesh.points,1);ne=size(mesh.edges,1);
  [edges,~,ix]=unique(sort([tr(:,[1,2]);tr(:,[2,3]);tr(:,[3,1])],2),'rows');
  incidence=accumarray(ix,1);assert(isequal(edges,mesh.edges)&&all(incidence<=2), ...
    'i95:Topology','Shared edge topology is inconsistent.');
  assert(isequal(mesh.triangle_p2(:,4:6),nv+reshape(ix,nt,3)),'i95:P2','Six-node geometry is not edge-shared.');
  assert(nv-ne+nt==1,'i95:Coverage','Disk topology failed.');
  ct=data.constraint;phase=exp(.5i);
  check=struct('triangles',nt,'vertices',nv,'edges',ne,'boundary_edges',sum(incidence==1), ...
    'restored_P_difference',norm(P-ct.prolongation,'fro'), ...
    'qp_field_defect',max(abs(u(ct.top)-phase*u(ct.bottom))), ...
    'end_value_defect',max(abs(u(ct.dirichlet))),'original_weighted_mass',real(u'*data.forms.mass_full*u));
  assert(check.restored_P_difference<1e-13&&check.qp_field_defect<1e-13&&check.end_value_defect==0, ...
    'i95:Field','Native phase or Dirichlet identity failed.');
end
function c=LOCAL_poly(v)
  c=[v(:,1),-3*v(:,1)-v(:,2)+4*v(:,4),-3*v(:,1)-v(:,3)+4*v(:,6), ...
    2*v(:,1)+2*v(:,2)-4*v(:,4),4*v(:,1)-4*v(:,4)+4*v(:,5)-4*v(:,6), ...
    2*v(:,1)+2*v(:,3)-4*v(:,6)];
end
function minimum=LOCAL_detmin(c)
  pts=[0,0;1,0;0,1];e=[c(4),c(2);c(6),c(3);c(4)-c(5)+c(6),c(2)-c(3)+c(5)-2*c(6)];
  for j=1:3
    if abs(e(j,1))>eps*max(1,norm(e(j,:),1))
      t=-e(j,2)/(2*e(j,1));
      if t>0&&t<1
        if j==1,pts(end+1,:)=[t,0];elseif j==2,pts(end+1,:)=[0,t];else,pts(end+1,:)=[t,1-t];end %#ok<AGROW>
      end
    end
  end
  H=[2*c(4),c(5);c(5),2*c(6)];
  if rcond(H)>64*eps,p=-H\c(2:3)';if all(p>0)&&sum(p)<1,pts(end+1,:)=p';end,end
  x=pts(:,1);y=pts(:,2);minimum=min(c(1)+c(2)*x+c(3)*y+c(4)*x.^2+c(5)*x.*y+c(6)*y.^2);
end

%% ==================== RT2 reference space and I9.4 witness ====================
% Reference moments use CCW edges and shifted Legendre polynomials, B.1 (23)-(26).
function [D,checks]=LOCAL_dual()
  [z,w]=LOCAL_gauss(6);D=zeros(15);
  for e=1:3
    [x,y,n]=LOCAL_edge(e,z);[vx,vy]=LOCAL_rt(x,y);L=[ones(size(z)),2*z-1,6*z.^2-6*z+1];
    D((e-1)*3+(1:3),:)=L'*(w.*(n(1)*vx+n(2)*vy));
  end
  [x,y,w]=LOCAL_duffy(5);[vx,vy]=LOCAL_rt(x,y);q=[ones(size(x)),x,y];
  D(10:12,:)=q'*(w.*vx);D(13:15,:)=q'*(w.*vy);
  [num,den]=rat(D,1e-13);D=num./den;
  err=norm(D*(D\eye(15))-eye(15),'inf');
  checks=struct('dual_identity',err,'condition_number',cond(D),'rank',rank(D));
  assert(err<1e-10&&rank(D)==15,'i95:RTBasis','RT2 reference dual basis failed.');
end
function [vx,vy,div]=LOCAL_rt(x,y)
  x=x(:);y=y(:);o=ones(size(x));z=zeros(numel(x),6);p=[o,x,y,x.^2,x.*y,y.^2];
  vx=[p,z,x.^3,x.^2.*y,x.*y.^2];vy=[z,p,x.^2.*y,x.*y.^2,y.^3];
  div=[0*x,o,0*x,2*x,y,0*x,0*x,0*x,o,0*x,x,2*y,4*x.^2,4*x.*y,4*y.^2];
end
function [moments,E]=LOCAL_average(mesh,m0,beta)
  tr=mesh.triangles;nt=size(tr,1);ne=size(mesh.edges,1);
  starts=[tr(:,1);tr(:,2);tr(:,3)];ends=[tr(:,2);tr(:,3);tr(:,1)];
  [~,eid]=ismember(sort([starts,ends],2),mesh.edges,'rows');ids=reshape(eid,nt,3);
  pa=mesh.points(starts,:);pb=mesh.points(ends,:);
  kappa=ones(3*nt,1);kappa(pa(:,1)>pb(:,1)|(pa(:,1)==pb(:,1)&pa(:,2)>pb(:,2)))=-1;
  epsilon=kappa;mid=(pa+pb)/2;seam=abs(mid(:,2)-.5)<1e-12|abs(mid(:,2)+.5)<1e-12;
  epsilon(seam)=-epsilon(seam);left=abs(mid(:,1)-mesh.xmin)<1e-12;epsilon(left)=-epsilon(left);
  signs=epsilon.*kappa.^(0:2);raw=reshape(permute(reshape(m0(:,1:9),nt,3,3),[1,3,2]),3*nt,3);
  canonical=raw.*signs;inc=accumarray(eid,1);global_moments=complex(zeros(ne,3));
  for m=1:3,global_moments(:,m)=accumarray(eid,canonical(:,m))./inc;end
  emid=(mesh.points(mesh.edges(:,1),:)+mesh.points(mesh.edges(:,2),:))/2;
  top=find(abs(emid(:,2)-.5)<1e-12);bottom=find(abs(emid(:,2)+.5)<1e-12);
  [~,a]=sort(emid(top,1));top=top(a);[~,a]=sort(emid(bottom,1));bottom=bottom(a);
  assert(numel(top)==numel(bottom)&&max(abs(emid(top,1)-emid(bottom,1)))<1e-12,'i95:QPEdge','Periodic edge pairing failed.');
  phase=exp(1i*beta);average=(global_moments(bottom,:)+conj(phase)*global_moments(top,:))/2;
  global_moments(bottom,:)=average;global_moments(top,:)=phase*average;
  local=global_moments(eid,:).*signs;moments=m0;
  moments(:,1:9)=reshape(permute(reshape(local,nt,3,3),[1,3,2]),nt,9);
  E=struct('ids',ids,'epsilon',reshape(epsilon,nt,3),'kappa',reshape(kappa,nt,3), ...
    'signs',reshape(signs,nt,3,3),'global_moments',global_moments,'periodic',[bottom,top], ...
    'incidence',inc,'midpoints',emid);
end
function [x,y,n]=LOCAL_edge(e,t)
  if e==1,x=t;y=0*t;n=[0,-1];elseif e==2,x=1-t;y=t;n=[1,1];else,x=0*t;y=1-t;n=[-1,0];end
end
function squared=LOCAL_ends(mesh,mx,my,mu,c,E,order)
  [z,w]=LOCAL_gauss(order);squared=[0,0];
  for side=1:2
    loc=mesh.xmin;if side==2,loc=mesh.xmax;end
    edges=find(abs(E.midpoints(:,1)-loc)<1e-12);[ti,le]=find(ismember(E.ids,edges));
    for j=1:numel(ti)
      t=ti(j);e=le(j);[x,y,n]=LOCAL_edge(e,z);[vx,vy]=LOCAL_rt(x,y);
      [~,~,~,~,J]=LOCAL_field(repmat(mx(t,:),order,1),repmat(my(t,:),order,1),repmat(mu(t,:),order,1),x,y);
      if e==1,tx=J(:,1);ty=J(:,3);elseif e==2,tx=-J(:,1)+J(:,2);ty=-J(:,3)+J(:,4);else,tx=-J(:,2);ty=-J(:,4);end
      hn=(vx*c(t,:)')*n(1)+(vy*c(t,:)')*n(2);squared(side)=squared(side)+sum(w.*abs(hn).^2./hypot(tx,ty));
    end
  end
end

%% ==================== Local true-material subdivision (from I9.4) ====================
% Bernstein image boxes and analytic second-derivative tubes classify each leaf.
function [leaves,info]=LOCAL_partition(mesh,mx,my,config)
  ng=config.curve_segments;t=(0:ng)'*2*pi/ng;cmin=min(mesh.cell_id);cmax=max(mesh.cell_id);
  curves=cell(cmax-cmin+1,1);
  for cell_id=cmin:cmax
    if cell_id==0
      x=.3*cos(t)+.03*cos(6*t)+.03*cos(4*t);y=.2*sin(t)+.03*sin(6*t)-.03*sin(4*t);M2=hypot(1.86,1.76);
    else
      a=.12;if cell_id>0,a=.20;end
      R=.2/sqrt(1+a*a/2);r=R*(1+a*cos(3*t));x=r.*cos(t);y=r.*sin(t);M2=sqrt(2)*R*(1+10*a);
    end
    radius=M2*(2*pi/ng)^2/8+64*eps;
    curves{cell_id-cmin+1}=struct('radius',radius,'box',[min(x(1:end-1),x(2:end))+cell_id-radius, ...
      max(x(1:end-1),x(2:end))+cell_id+radius,min(y(1:end-1),y(2:end))-radius,max(y(1:end-1),y(2:end))+radius]);
  end
  nt=size(mx,1);parts=cell(nt,1);
  for k=1:nt
    c=mesh.cell_id(k);parts{k}=LOCAL_split(k,[0,0;1,0;0,1],0,(1:ng)',mx(k,:),my(k,:),c,curves{c-cmin+1},config.maximum_subdivision);
  end
  leaves=vertcat(parts{:});
  info=struct('leaves',size(leaves,1),'unresolved_leaves',sum(leaves(:,8)==0),'max_depth',max(leaves(:,9)), ...
    'curve_segments',ng,'maximum_subdivision',config.maximum_subdivision);
end
function rows=LOCAL_split(k,v,level,candidates,mx,my,c,curve,maxdepth)
  ref=[v;(v(1,:)+v(2,:))/2;(v(2,:)+v(3,:))/2;(v(3,:)+v(1,:))/2];
  b=LOCAL_monomial(ref(:,1),ref(:,2));xy=[b*mx',b*my'];
  bern=[xy(1:3,:);2*xy(4,:)-(xy(1,:)+xy(2,:))/2;2*xy(5,:)-(xy(2,:)+xy(3,:))/2;2*xy(6,:)-(xy(3,:)+xy(1,:))/2];
  lo=min(bern,[],1)-64*eps;hi=max(bern,[],1)+64*eps;box=curve.box(candidates,:);
  keep=box(:,1)<=hi(1)&box(:,2)>=lo(1)&box(:,3)<=hi(2)&box(:,4)>=lo(2);candidates=candidates(keep);
  if isempty(candidates)
    p=mean(v,1);b=LOCAL_monomial(p(1),p(2));rows=[k,reshape(v',1,6),LOCAL_rho(b*mx',b*my',c),level];return
  end
  if level==maxdepth,rows=[k,reshape(v',1,6),0,level];return,end
  a=(v(1,:)+v(2,:))/2;b=(v(2,:)+v(3,:))/2;d=(v(3,:)+v(1,:))/2;
  child={[v(1,:);a;d],[a;v(2,:);b],[d;b;v(3,:)],[a;b;d]};out=cell(4,1);
  for j=1:4,out{j}=LOCAL_split(k,child{j},level+1,candidates,mx,my,c,curve,maxdepth);end
  rows=vertcat(out{:});
end
function rho=LOCAL_rho(x,y,c)
  x=x(:);y=y(:);if isscalar(c),c=repmat(c,size(x));end
  xx=x-c;rho=ones(size(x));lead=c~=0;
  a=.12*ones(size(x));a(c>0)=.2;theta=atan2(y,xx);r=.2*(1+a.*cos(3*theta))./sqrt(1+a.^2/2);
  rho(lead&hypot(xx,y)<r)=17;ids=find(~lead);
  if ~isempty(ids)
    xp=xx(ids);yp=y(ids);t=atan2(yp/.2,xp/.3);
    for it=1:12
      [cx,cy,dx,dy]=LOCAL_star(t);f=cx.*yp-cy.*xp;df=dx.*yp-dy.*xp;
      step=zeros(size(t));nz=abs(df)>1e-30;step(nz)=f(nz)./df(nz);t=t-max(-.2,min(.2,step));
    end
    [cx,cy]=LOCAL_star(t);inside=hypot(xp,yp)<hypot(cx,cy);rho(ids(inside))=4;
  end
end
function [x,y,dx,dy]=LOCAL_star(t)
  x=.3*cos(t)+.03*cos(6*t)+.03*cos(4*t);y=.2*sin(t)+.03*sin(6*t)-.03*sin(4*t);
  dx=-.3*sin(t)-.18*sin(6*t)-.12*sin(4*t);dy=.2*cos(t)+.18*cos(6*t)-.12*cos(4*t);
end

%% ==================== Curved P2 field and quadrature ====================
% Field values, physical gradient, Laplacian and Jacobian at reference points.
function [u,gx,gy,lap,J,d,physical]=LOCAL_field(mx,my,mu,x,y)
  n=size(mx,1);if isscalar(x),x=repmat(x,n,1);y=repmat(y,n,1);end
  x=x(:);y=y(:);b=LOCAL_monomial(x,y);u=sum(b.*mu,2);
  ux=mu(:,2)+2*mu(:,4).*x+mu(:,5).*y;uy=mu(:,3)+mu(:,5).*x+2*mu(:,6).*y;
  j11=mx(:,2)+2*mx(:,4).*x+mx(:,5).*y;j12=mx(:,3)+mx(:,5).*x+2*mx(:,6).*y;
  j21=my(:,2)+2*my(:,4).*x+my(:,5).*y;j22=my(:,3)+my(:,5).*x+2*my(:,6).*y;
  d=j11.*j22-j12.*j21;J=[j11,j12,j21,j22];
  gx=(j22.*ux-j21.*uy)./d;gy=(-j12.*ux+j11.*uy)./d;
  h11=2*(mu(:,4)-gx.*mx(:,4)-gy.*my(:,4));h12=mu(:,5)-gx.*mx(:,5)-gy.*my(:,5);
  h22=2*(mu(:,6)-gx.*mx(:,6)-gy.*my(:,6));
  lap=(h11.*(j22.^2+j12.^2)-2*h12.*(j22.*j21+j12.*j11)+h22.*(j21.^2+j11.^2))./d.^2;
  if nargout>6,physical=[sum(b.*mx,2),sum(b.*my,2)];end
end
function b=LOCAL_monomial(x,y)
  b=[ones(size(x)),x,y,x.^2,x.*y,y.^2];
end
function [x,w]=LOCAL_gauss(n)
  j=(1:n-1)';b=j./sqrt(4*j.^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));
  [x,ix]=sort(diag(D));x=(x+1)/2;w=V(1,ix)'.^2;
end
function [x,y,w]=LOCAL_duffy(n)
  [z,v]=LOCAL_gauss(n);[r,s]=ndgrid(z,z);[a,b]=ndgrid(v,v);x=r(:);y=(1-x).*s(:);w=a(:).*b(:).*(1-x);
end
function LOCAL_json(path,value)
  fid=fopen(path,'w');assert(fid>=0,'i95:Export','Cannot write %s.',path);clean=onCleanup(@()fclose(fid));
  fwrite(fid,jsonencode(value,PrettyPrint=true),'char');
end
