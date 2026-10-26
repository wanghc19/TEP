function eq_temple_i95(input_path,output_dir,mode,tail,reference_path)
%EQ_TEMPLE_I95 Weighted RT2 flux, localized bound and resolvent-Temple estimate.
% Purpose: Evaluate research/.../fem-bound/s-eq-temple.md steps 0-1 on the
%   frozen I9.3 native curved-P2 field: Theorem B, B.1 (9), Corollaries C1-C3.
% Input: input_path names the I9.3 FEM evidence.mat (never BIE data);
%   output_dir is the run folder; mode is 'formal' (default) or 'smoke'; optional
%   tail=[glue_cell,tail_cells] replaces both ends by a finite discrete Floquet
%   tail built by eq_tail_build_i95 (s-eq-temple Section 5, finite variant).
% Output: evidence.mat with every flux and per-element term; result.json.
% Main algorithm:
%   1. restore the native field; rebuild the I9.4 averaged RT2 witness (step 0);
%   2. smooth element Grams, true-material leaf data, curved Poincare constants;
%   3. per shift s, minimize the weighted functional J_theta, s-eq-temple (6),
%      over the global quasi-periodic RT2 space; unweighted B.1 (28) comparator;
%   4. two-pass direct evaluation of Theorem B (4)-(5), Rayleigh quotient,
%      linear B.1 (15) and Temple radii (11), with the C3 transfer (12).
% Based on: test/i9/fem-bound-v1/fem_bound_i94.m (input, RT2, partition, ends).
% Main changes: optimized fluxes, Poincare-weighted localized evaluation and
%   the one-sided-gap quadratic bound; no FEM solve, search or mesh change.
% Numerical goal: ordinary-arithmetic estimates, not certified bounds.
% E.2 (design-9-5a Section 6): modes 'e2'/'e2smoke' take a NEW compare-v1 e2 FEM
%   evidence.mat, select the unique gated root near k_old, build the finite tail at
%   the new mu_h, solve one unweighted RT2 least-squares flux at m=mu_h, s=m/2 with
%   element-interior condensation, and evaluate Theorem B directly in Q10 and Q8.
%   Optional reference_path (old I9.3 evidence) feeds only a wall-trace similarity.
  if nargin<3,mode='formal';end
  if nargin<4,tail=[];end
  if nargin<5,reference_path='';end
  if startsWith(mode,'e2'),LOCAL_e2(input_path,output_dir,mode,tail,reference_path);return,end
  config=eq_temple_i95_config(mode);maxNumCompThreads(config.threads);
  if ~isempty(tail),config.s_factors=config.s_factors(config.s_factors<=1);config.tail=tail;end
  if ~isfolder(output_dir),mkdir(output_dir);end
  started=tic;stage='input';timings=struct();
  try
    % --- stage 1: frozen native field and I9.4 witness ---
    timer=tic;data=load(input_path);mesh=data.mesh;source_config=data.config;
    assert(isequal(source_config.model,struct('beta',.5,'d',1,'L',1,'star_scale',1, ...
      'rho_center',4,'rho_negative',17,'rho_positive',17,'rho_background',1, ...
      'a_negative',.12,'a_positive',.20,'radius',.2)),'i95:Model','Frozen model mismatch.');
    assert(source_config.mesh.half_cells==6&&source_config.mesh.subdivisions==12&& ...
      source_config.mesh.interface_segments==80,'i95:Mesh','Frozen FEM mesh mismatch.');
    id=config.candidate_index;assert(data.modes(id).candidate&&data.modes(id).k==config.k_h, ...
      'i95:Candidate','Input candidate differs.');
    reduced=data.eigenvectors(:,id);P=LOCAL_constraint(mesh,config.beta);
    full_field=P*reduced;input_checks=LOCAL_input(mesh,P,full_field,data);tail_info=struct();
    if ~isempty(tail)
      [mesh,tail_info]=eq_tail_build_i95(mesh,full_field,config.mu_h,config.beta,tail(1),tail(2));
      full_field=mesh.field;tail_info.field_checks=LOCAL_tailcheck(mesh,full_field,config.beta);
      fprintf('STAGE tail: glue %d, %d cells, zeta max %.4g/%.4g, match %.2g, closing %.2g\n',tail(1),tail(2), ...
        tail_info.sides(1).zeta_abs_max,tail_info.sides(2).zeta_abs_max,max([tail_info.sides.match_residual]), ...
        max([tail_info.sides.closing_relative_amplitude]));
    end
    nt=size(mesh.triangles,1);nodes=reshape(mesh.p2_points(mesh.triangle_p2(:),:),nt,6,2);
    mapx=LOCAL_poly(nodes(:,:,1));mapy=LOCAL_poly(nodes(:,:,2));
    mapu=LOCAL_poly(reshape(full_field(mesh.triangle_p2),nt,6));clear data P
    [D,basis_checks]=LOCAL_dual();Dinv=D\eye(15);
    moments0=LOCAL_moments(mapx,mapy,mapu,config.edge_moment_order,config.volume_moment_order);
    [moments_avg,E]=LOCAL_average(mesh,moments0,config.beta);coeff_avg=moments_avg/D.';
    timings.input_and_witness_seconds=toc(timer);
    fprintf('STAGE input: %d cells, k=%.17g, mode=%s\n',nt,config.k_h,mode);

    % --- stage 2: material leaves, geometry and element data ---
    stage='element_data';timer=tic;
    [leaves,classification]=LOCAL_partition(mesh,mapx,mapy,config);
    timings.partition_seconds=toc(timer);timer=tic;
    geo=LOCAL_geometry(mapx,mapy);
    el=LOCAL_element(mapx,mapy,mapu,config.element_order);
    leaf_rho=leaves(:,8);leaf_rho(leaf_rho==0)=max(config.material_candidates);
    rhomax=accumarray(leaves(:,1),leaf_rho,[nt,1],@max);
    lf=LOCAL_leafdata(leaves,mesh,mapx,mapy,mapu,config.assembly_leaf_order,config.batch_size);
    Gend=LOCAL_endgram(mesh,mapx,mapy,E,config.end_order);
    [g,phi,ndof,dofinfo]=LOCAL_dofs(mesh,E,nt,config.beta);
    timings.element_data_seconds=toc(timer);
    fprintf('STAGE element data: %d leaves, %d unresolved, ndof=%d, CP max %.3g\n', ...
      size(leaves,1),sum(leaves(:,8)==0),ndof,max(geo.CP));

    % --- stage 3: step 0, I9.4 witness under Theorem B at mu_h ---
    stage='step0';timer=tic;fluxes=struct([]);
    s=config.mu_h;[ev1,ev2]=LOCAL_twopass(leaves,mesh,mapx,mapy,mapu,coeff_avg,config.mu_h, ...
      config.evaluation_order,config.batch_size);
    endsq=LOCAL_ends(mesh,mapx,mapy,mapu,coeff_avg,E,config.end_order);
    mass=sum(ev1.mass);U=sqrt(mass);muR=sum(ev1.grad2)/mass;
    bound=LOCAL_bound(ev1,ev2,geo,s,config,endsq);
    fluxes=LOCAL_record(fluxes,'i94_average_witness',coeff_avg,s,config.mu_h,bound, ...
      LOCAL_scalars(bound,U,muR,config.mu_h,s,config,true),struct());
    timings.step0_seconds=toc(timer);
    fprintf('STAGE step0: eta9=%.10g etaB=%.10g muR=%.17g U=%.17g\n',bound.eta9,bound.etaB,muR,U);

    % --- stage 4: weighted and unweighted least-squares fluxes at mu_R ---
    % Both fluxes are valid inputs to Theorem B; each shift uses both designs.
    plan=[kron(config.s_factors(:),[1;1]),repmat([1;0],numel(config.s_factors),1)];
    for j=1:size(plan,1)
      s=plan(j,1)*config.mu_h;weighted=plan(j,2)==1;
      name=sprintf('%s_s%.2g',LOCAL_ifelse(weighted,'weighted','unweighted'),plan(j,1));
      stage=['solve_',name];timer=tic;
      [coeff,solve]=LOCAL_solve(el,lf,geo,rhomax,Gend,g,phi,ndof,Dinv,s,muR,weighted,config);
      tsolve=toc(timer);stage=['evaluate_',name];timer=tic;
      trace=LOCAL_trace_check(mesh,mapx,mapy,coeff,E);
      [ev1,ev2]=LOCAL_twopass(leaves,mesh,mapx,mapy,mapu,coeff,muR,config.evaluation_order,config.batch_size);
      endsq=LOCAL_ends(mesh,mapx,mapy,mapu,coeff,E,config.end_order);
      bound=LOCAL_bound(ev1,ev2,geo,s,config,endsq);
      solve.solve_seconds=tsolve;solve.evaluation_seconds=toc(timer);solve.trace=trace;
      fluxes=LOCAL_record(fluxes,name,coeff,s,muR,bound,LOCAL_scalars(bound,U,muR,config.mu_h,s,config,false),solve);
      fprintf('STAGE %s: etaB=%.6g eta9=%.6g tauR=%.6g xT=%.4g Rlin=%.4g (solve %.1fs eval %.1fs)\n',name, ...
        bound.etaB,bound.eta9,fluxes(end).scalars.tau_R,fluxes(end).scalars.x_T(1), ...
        fluxes(end).scalars.R_linear_mu_h,tsolve,solve.evaluation_seconds);
    end

    % --- stage 5: quadrature diagnostic of the main weighted flux ---
    stage='quadrature_check';timer=tic;check=struct([]);
    for main=find(ismember({fluxes.name},{'weighted_s1','unweighted_s1'}))
      if ~strcmp(mode,'formal')||~isempty(tail),break,end
      [c1,c2]=LOCAL_twopass(leaves,mesh,mapx,mapy,mapu,fluxes(main).coeff,muR,config.check_order,config.batch_size);
      cb=LOCAL_bound(c1,c2,geo,fluxes(main).s,config,LOCAL_ends(mesh,mapx,mapy,mapu,fluxes(main).coeff,E,16));
      item=struct('flux',fluxes(main).name,'order',config.check_order,'etaB',cb.etaB,'eta9',cb.eta9, ...
        'etaB_change',abs(cb.etaB-fluxes(main).bound.etaB),'eta9_change',abs(cb.eta9-fluxes(main).bound.eta9), ...
        'mass_change',abs(sum(c1.mass)-mass),'grad2_change',abs(sum(c1.grad2)-sum(ev1.grad2)));
      if isempty(check),check=item;else,check(end+1)=item;end %#ok<AGROW>
    end
    timings.quadrature_check_seconds=toc(timer);

    % --- stage 6: save and export ---
    stage='save';timer=tic;
    summary=rmfield(fluxes,{'coeff','bound'});
    for j=1:numel(fluxes),summary(j).totals=rmfield(fluxes(j).bound,{'element'});end
    result=struct('status',config.status,'config',config,'input',input_checks, ...
      'basis_checks',basis_checks,'classification',classification, ...
      'geometry',struct('CP_max',max(geo.CP),'CP_median',median(geo.CP),'dmin',min(geo.dmin), ...
      'ratio_max',max(geo.dmax./geo.dmin)),'dofs',dofinfo,'mu_R',muR,'U',U, ...
      'mu_R_minus_mu_h',muR-config.mu_h,'tail',tail_info,'fluxes',summary,'quadrature_check',check,'timings',timings, ...
      'environment',struct('version',version,'platform',computer,'threads',maxNumCompThreads, ...
      'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS')));
    save(fullfile(output_dir,'evidence.mat'),'config','reduced','full_field','mapx','mapy','mapu', ...
      'D','coeff_avg','geo','rhomax','leaves','fluxes','result','-v7');
    result.timings.save_seconds=toc(timer);result.timings.matlab_function_seconds=toc(started);
    LOCAL_json(fullfile(output_dir,'result.json'),result);
    fprintf('COMPLETE time=%.1fs\n',toc(started));
  catch err
    LOCAL_json(fullfile(output_dir,'failure.json'),struct('stage',stage,'identifier',err.identifier, ...
      'message',err.message,'report',getReport(err,'extended','hyperlinks','off'), ...
      'elapsed_seconds',toc(started)));
    rethrow(err);
  end
end

%% ==================== E.2 joint-refinement chain (design-9-5a Section 6) ====================
% New candidate -> new-frequency finite tail -> one condensed unweighted RT2 flux
% -> direct Q10/Q8 Theorem B at m=mu_h^new. Element data live in blocks only.
function LOCAL_e2(input_path,output_dir,mode,tail,reference_path)
  config=eq_temple_i95_config(mode);maxNumCompThreads(config.threads);
  if ~isempty(tail),config.tail=tail;end
  if ~isfolder(output_dir),mkdir(output_dir);end
  started=tic;lap=tic;stage='candidate_input';timings=struct();rss=struct();checks=struct();
  try
    % --- stage 1: new FEM candidate, unique gated root near k_old ---
    data=load(input_path,'config','mesh','modes','eigenvectors','constraint','forms','validation','solve_records');
    source=data.config;
    assert(isequal(source.model,struct('beta',.5,'d',1,'L',1,'star_scale',1, ...
      'rho_center',4,'rho_negative',17,'rho_positive',17,'rho_background',1, ...
      'a_negative',.12,'a_positive',.20,'radius',.2)),'e2:Model','Frozen model mismatch.');
    assert(source.mesh.half_cells==config.fem.half_cells&&source.mesh.subdivisions==config.fem.subdivisions&& ...
      source.mesh.interface_segments==config.fem.interface_segments&&source.mesh.quadrature_order==8, ...
      'e2:Mesh','FEM mesh configuration differs from E.2.');
    sv=source.solver;
    assert(isequal(sv.shifts_mu,config.k_old^2+.01)&&sv.requested==3&&sv.subspace==20&&sv.seed==193&& ...
      sv.tolerance==1e-10&&sv.max_iterations==1000,'e2:Solver','FEM solver configuration differs from E.2.');
    modes=data.modes;gated=find([modes.candidate]);
    near=gated(abs([modes(gated).k]-config.k_old)<=config.candidate_k_window);
    selection=struct('returned',numel(modes),'gated',gated,'near_k_old',near, ...
      'window',config.candidate_k_window,'solver_flags',[data.solve_records.flag]);
    fem_checks=data.validation;
    if numel(near)~=1
      % No root is picked by BIE or by extra shifts; every returned root is kept.
      result=struct('status','UNRESOLVED_LOCAL_CONTINUATION','pipeline','INCOMPLETE_FULL_PIPELINE', ...
        'config',config,'selection',selection,'modes',modes,'fem_validation',fem_checks);
      LOCAL_json(fullfile(output_dir,'result.json'),result);
      fprintf('UNRESOLVED: %d gated roots within %.3g of k_old\n',numel(near),config.candidate_k_window);return
    end
    id=near;mesh=data.mesh;reduced=data.eigenvectors(:,id);P=LOCAL_constraint(mesh,config.beta);
    native_field=P*reduced;checks.native=LOCAL_input(mesh,P,native_field,data);
    m=modes(id);mu_h=m.mu_real;k_h=m.k;s=config.s_factors*mu_h;
    config.k_h=k_h;config.mu_h=mu_h;config.m_residual=mu_h;config.s=s;
    checks.native.mass_normalization_defect=abs(checks.native.original_weighted_mass-1);
    checks.native.fem_residual=m.residual;checks.native.mu_imag=m.mu_imag;
    assert(m.solver_flag==0&&m.residual<=1e-8&&abs(m.mu_imag)<=1e-10&&mu_h>0&& ...
      checks.native.mass_normalization_defect<=1e-10&&fem_checks.mass_cholesky_flag==0&& ...
      fem_checks.determinant_minimum>0&&max(fem_checks.stiffness_hermitian_defect, ...
      fem_checks.mass_hermitian_defect)<1e-12,'e2:Candidate','New candidate failed algebraic gates.');
    native_mesh_counts=struct('triangles',size(mesh.triangles,1),'p2_nodes',size(mesh.p2_points,1), ...
      'interface_edges',mesh.interface_edge_count,'full_dof',size(P,1),'reduced_dof',size(P,2));
    clear data P
    fprintf('STAGE candidate: id %d of %d, k=%.17g (drift %.3g), mu=%.17g, %d triangles\n', ...
      id,numel(modes),k_h,k_h-config.k_old,mu_h,native_mesh_counts.triangles);
    [timings,rss,lap]=LOCAL_lap(timings,rss,'candidate_input',lap);

    % --- stage 2 (diagnostic only): old/new wall-trace similarity ---
    similarity=struct();
    if ~isempty(reference_path)
      stage='reference_similarity';similarity=LOCAL_similarity(reference_path,mesh,native_field,config);
      fprintf('STAGE similarity: %.12f on %d common wall nodes\n',similarity.total,similarity.common_nodes);
      [timings,rss,lap]=LOCAL_lap(timings,rss,'reference_similarity',lap);
    end

    % --- stage 3: new-frequency finite tail (no fallback to the old tail) ---
    stage='tail';
    [mesh,tail_info]=eq_tail_build_i95(mesh,native_field,mu_h,config.beta,config.tail(1),config.tail(2));
    u=mesh.field;tail_info.field_checks=LOCAL_tailcheck(mesh,u,config.beta);
    tail_info.topology=LOCAL_topology(mesh);scale=max(abs(u));
    tail_info.gates=struct('match_max',max([tail_info.sides.match_residual]), ...
      'merge_scaled',tail_info.merge_value_defect/scale,'qp_scaled',tail_info.field_checks.qp_field_defect/scale, ...
      'wall_dofs',[tail_info.sides.wall_dofs],'zeta_max',max([tail_info.sides.zeta_abs_max]), ...
      'unit_circle_gap_min',min([tail_info.sides.unit_circle_gap]));
    assert(tail_info.gates.match_max<=config.tail_tolerance&&tail_info.gates.merge_scaled<=config.tail_tolerance&& ...
      tail_info.gates.qp_scaled<=config.tail_tolerance&&tail_info.gates.zeta_max<1&& ...
      tail_info.sides(1).wall_dofs==tail_info.sides(2).wall_dofs,'e2:Tail','Finite tail gates failed.');
    fprintf('STAGE tail: %d cells, wall dofs %d/%d, zeta max %.4g/%.4g, match %.2g, closing %.2g, nt=%d\n', ...
      config.tail(2),tail_info.sides(1).wall_dofs,tail_info.sides(2).wall_dofs,tail_info.sides(1).zeta_abs_max, ...
      tail_info.sides(2).zeta_abs_max,tail_info.gates.match_max,max([tail_info.sides.closing_relative_amplitude]),tail_info.elements);
    [timings,rss,lap]=LOCAL_lap(timings,rss,'tail',lap);

    % --- stage 4: maps, geometry constants, RT2 space ---
    stage='geometry_space';
    nt=size(mesh.triangles,1);nodes=reshape(mesh.p2_points(mesh.triangle_p2(:),:),nt,6,2);
    mapx=LOCAL_poly(nodes(:,:,1));mapy=LOCAL_poly(nodes(:,:,2));
    mapu=LOCAL_poly(reshape(u(mesh.triangle_p2),nt,6));clear nodes
    [D,basis_checks]=LOCAL_dual();Dinv=D\eye(15);
    [~,E]=LOCAL_average(mesh,complex(zeros(nt,15)),config.beta);
    geo=LOCAL_geometry(mapx,mapy);[g,phi,ndof,dofinfo]=LOCAL_dofs(mesh,E,nt,config.beta);
    ends=LOCAL_endlist(mesh,mapx,mapy,E,config.end_order);
    bs=config.element_block;blocks=arrayfun(@(b)(b-1)*bs+1:min(b*bs,nt),1:ceil(nt/bs),'UniformOutput',false);
    fprintf('STAGE space: nt=%d, ndof=%d (edge %d), CP max %.3g, %d blocks\n',nt,ndof,dofinfo.edge_dofs, ...
      max(geo.CP),numel(blocks));
    [timings,rss,lap]=LOCAL_lap(timings,rss,'geometry_space',lap);

    % --- stage 5: true-material leaves, one numeric table per element block ---
    stage='partition';[leafblocks,counts,classification]=LOCAL_partition_blocks(mesh,mapx,mapy,blocks,config);
    fprintf('STAGE partition: %d leaves, %d unresolved, max depth %d\n',classification.leaves, ...
      classification.unresolved_leaves,classification.max_depth);
    [timings,rss,lap]=LOCAL_lap(timings,rss,'partition',lap);

    % --- stage 6: unweighted LS flux with element-interior condensation ---
    stage='ls_condense';Cend=(2*sqrt(s*config.rho_min))^(-.5);gamma=config.gamma_factor*Cend^2;
    form=@(b)LOCAL_blockform(blocks{b},leafblocks{b},mesh,mapx,mapy,mapu,ends,s,mu_h,gamma,Dinv,config);
    nE=dofinfo.edge_dofs;A=sparse(nE,nE);rhs=zeros(nE,1);Y=zeros(6,9,nt);r=complex(zeros(6,nt));
    hii=struct('min_eig',Inf,'min_ratio',Inf);
    for b=1:numel(blocks)
      ids=blocks{b};nb=numel(ids);[Hm,qm]=form(b);
      Hii=Hm(10:15,10:15,:);Hie=Hm(10:15,1:9,:);lam=real(pageeig(Hii));
      hii.min_eig=min(hii.min_eig,min(lam,[],'all'));hii.min_ratio=min(hii.min_ratio,min(min(lam,[],1)./max(lam,[],1),[],'all'));
      assert(all(lam>0,'all'),'e2:Hii','Interior block H_ii is not positive definite (no regularization).');
      Yb=pagemldivide(Hii,Hie);rb=pagemldivide(Hii,complex(reshape(qm(10:15,:),6,1,nb)));
      S=Hm(1:9,1:9,:)-pagemtimes(Hie,'transpose',Yb,'none');S=(S+pagetranspose(S))/2;
      qt=reshape(qm(1:9,:),9,1,nb)-pagemtimes(Hie,'transpose',rb,'none');
      Y(:,:,ids)=Yb;r(:,ids)=reshape(rb,6,nb);
      pe=phi(ids,1:9).';ge=g(ids,1:9).';V=conj(reshape(pe,9,1,nb)).*S.*reshape(pe,1,9,nb);
      I=repmat(reshape(ge,9,1,nb),1,9,1);J=repmat(reshape(ge,1,9,nb),9,1,1);
      A=A+sparse(I(:),J(:),V(:),nE,nE);rhs=rhs+full(sparse(ge(:),1,conj(pe(:)).*reshape(qt,[],1),nE,1));
      clear Hm qm Hii Hie Yb rb S qt V I J
    end
    A=(A+A')/2;
    [timings,rss,lap]=LOCAL_lap(timings,rss,'ls_assembly_condense',lap);
    stage='ls_factor_solve';
    % Peak model: RSS + 40 B per symbolic nnz(L) + 48 B per nnz(A) (A(p,p) copy and
    % workspace); a debug probe measured ~28 B per nnz(L) for complex sparse chol.
    p=amd(A);count=symbfact(A(p,p));nnzL=sum(count);now_rss=LOCAL_rss();
    factor=struct('edge_dofs',nE,'nnz_A',nnz(A),'nnz_L_symbolic',nnzL,'rss_before_bytes',now_rss, ...
      'estimated_peak_bytes',now_rss+40*nnzL+48*nnz(A),'bytes_per_nnzL_model',40);
    fprintf('STAGE factor estimate: nnz(A)=%d nnz(L)=%d rss %.0f MB est peak %.0f MB\n',nnz(A),nnzL, ...
      now_rss/2^20,factor.estimated_peak_bytes/2^20);
    assert(factor.estimated_peak_bytes<=config.rss_warning_bytes,'e2:Resource', ...
      'Estimated factorization peak %.3g bytes exceeds %.3g.',factor.estimated_peak_bytes,config.rss_warning_bytes);
    Ap=A(p,p);[R,flag]=chol(Ap);clear Ap
    assert(flag==0,'e2:Cholesky','Condensed edge matrix is not positive definite.');
    factor.nnz_R=nnz(R);z=zeros(nE,1);z(p)=-(R\(R'\rhs(p)));clear R
    factor.condensed_relative_residual=norm(A*z+rhs)/norm(rhs);factor.rss_after_bytes=LOCAL_rss();
    assert(factor.condensed_relative_residual<=config.condensed_tolerance,'e2:Solve', ...
      'Condensed relative residual %.3g.',factor.condensed_relative_residual);
    clear A rhs
    [timings,rss,lap]=LOCAL_lap(timings,rss,'ls_factor_solve',lap);
    stage='ls_recovery';
    ye=phi(:,1:9).*z(g(:,1:9));yi=-reshape(pagemtimes(Y,reshape(ye.',9,1,nt)),6,nt)-r;
    yloc=[ye,yi.'];coeff=yloc*Dinv.';clear Y r yi
    [timings,rss,lap]=LOCAL_lap(timings,rss,'ls_recovery',lap);

    % --- stage 7: rebuilt local blocks, uncondensed residual (global edge assembly) ---
    stage='ls_residual_rebuild';
    [residual,full_check]=LOCAL_uncondensed(form,blocks,yloc,g,phi,ndof,nE,Dinv,coeff,config);
    solve_info=struct('s',s,'m',mu_h,'gamma',gamma,'C_end',Cend,'hii',hii,'factor',factor, ...
      'uncondensed',residual,'condense_check',full_check,'ndof',ndof,'edge_dofs',nE, ...
      'flux_norm_coefficients',norm(coeff,'fro'));
    assert(residual.relative<=config.condensed_tolerance&&residual.interior_relative<=config.condensed_tolerance, ...
      'e2:Residual','Recovered uncondensed residual %.3g / interior %.3g.',residual.relative,residual.interior_relative);
    fprintf('STAGE LS: condensed res %.3g, uncondensed %.3g (interior %.3g, edge %.3g), Hii min eig %.3g\n', ...
      factor.condensed_relative_residual,residual.relative,residual.interior_relative,residual.edge_relative,hii.min_eig);
    [timings,rss,lap]=LOCAL_lap(timings,rss,'ls_residual_rebuild',lap);

    % --- stage 8: physical normal traces and artificial ends ---
    stage='trace_checks';trace=LOCAL_trace_check(mesh,mapx,mapy,coeff,E);
    trace.internal_scaled=trace.internal_normal_jump/trace.trace_scale;trace.qp_scaled=trace.qp_normal_jump/trace.trace_scale;
    trace.end_lengths=ends.lengths;
    assert(max(trace.internal_scaled,trace.qp_scaled)<=config.trace_tolerance,'e2:Trace', ...
      'Scaled normal trace defect %.3g / %.3g.',trace.internal_scaled,trace.qp_scaled);
    [timings,rss,lap]=LOCAL_lap(timings,rss,'trace_checks',lap);

    % --- stage 9: final direct two-pass evaluations, same u, p, m ---
    stage='direct_q10';
    direct.q10=LOCAL_e2_direct(leafblocks,blocks,mesh,mapx,mapy,mapu,coeff,geo,E,config, ...
      config.evaluation_order,config.end_order);
    LOCAL_e2_print(direct.q10);[timings,rss,lap]=LOCAL_lap(timings,rss,'direct_q10',lap);
    stage='direct_q8';
    direct.q8=LOCAL_e2_direct(leafblocks,blocks,mesh,mapx,mapy,mapu,coeff,geo,E,config, ...
      config.check_order,config.check_end_order);
    LOCAL_e2_print(direct.q8);[timings,rss,lap]=LOCAL_lap(timings,rss,'direct_q8',lap);

    % --- stage 10: frozen comparison rule against the historical baselines ---
    stage='comparison';comparison=LOCAL_e2_compare(direct,config);
    fprintf('CLASSIFICATION %s (vs MM), %s (vs LS)\n',comparison.mm.classification,comparison.ls.classification);
    [timings,rss,lap]=LOCAL_lap(timings,rss,'comparison',lap);

    % --- stage 11: save evidence ---
    stage='save';status='UNCERTIFIED_ORDINARY_ARITHMETIC_ESTIMATE';
    if strcmp(mode,'e2smoke'),status='IMPLEMENTATION_SMOKE_ONLY';end
    summary=struct('q10',LOCAL_e2_summary(direct.q10),'q8',LOCAL_e2_summary(direct.q8));
    result=struct('status',status,'pipeline','FULL_PIPELINE_COMPLETED','config',config, ...
      'candidate',struct('id',id,'k_h',k_h,'mu_h',mu_h,'drift_k',k_h-config.k_old, ...
      'drift_mu',mu_h-config.k_old^2,'fem_residual',m.residual,'center_mass',m.center_mass, ...
      'core_mass',m.core_mass,'end_mass',m.end_mass),'selection',selection,'modes',modes, ...
      'native_mesh',native_mesh_counts,'fem_validation',fem_checks,'checks',checks,'similarity',similarity, ...
      'tail',tail_info,'basis_checks',basis_checks,'dofs',dofinfo,'classification',classification, ...
      'geometry',struct('CP_max',max(geo.CP),'CP_median',median(geo.CP),'dmin',min(geo.dmin), ...
      'ratio_max',max(geo.dmax./geo.dmin)),'solve',solve_info,'trace',trace,'direct',summary, ...
      'comparison',comparison,'environment',struct('version',version,'platform',computer, ...
      'threads',maxNumCompThreads,'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS')));
    tail_mesh=rmfield(mesh,'field');tail_field=u;
    save(fullfile(output_dir,'evidence.mat'),'config','reduced','native_field','tail_mesh','tail_field', ...
      'mapx','mapy','mapu','D','coeff','z','geo','counts','direct','result','-v7');
    [timings,rss]=LOCAL_lap(timings,rss,'save',lap);
    timings.matlab_function_seconds=toc(started);
    timings.unattributed_seconds=timings.matlab_function_seconds-sum(cellfun(@(f)timings.(f), ...
      setdiff(fieldnames(timings),{'matlab_function_seconds'})));
    result.timings=timings;result.rss_bytes_at_lap=rss;
    LOCAL_json(fullfile(output_dir,'result.json'),result);
    fprintf('COMPLETE %s time=%.1fs\n',status,toc(started));
  catch err
    LOCAL_json(fullfile(output_dir,'failure.json'),struct('stage',stage,'identifier',err.identifier, ...
      'message',err.message,'report',getReport(err,'extended','hyperlinks','off'), ...
      'elapsed_seconds',toc(started),'timings',timings,'rss_bytes_at_lap',rss));
    keep={'config','selection','checks','similarity','tail_info','dofinfo','classification','factor', ...
      'hii','residual','full_check','trace','direct','coeff','z','counts'};
    keep=keep(cellfun(@(v)exist(v,'var')==1,keep));
    if ~isempty(keep),save(fullfile(output_dir,'failure_evidence.mat'),keep{:},'-v7');end
    rethrow(err);
  end
end
function [t,rss,lap]=LOCAL_lap(t,rss,name,lap)
  % Exclusive stage time plus this MATLAB process RSS (launcher keeps the tree peak).
  t.(name)=toc(lap);rss.(name)=LOCAL_rss();
  fprintf('LAP %-24s %9.2fs  rss %7.0f MB\n',name,t.(name),rss.(name)/2^20);lap=tic;
end
function b=LOCAL_rss()
  [~,out]=system(sprintf('ps -o rss= -p %d',feature('getpid')));b=1024*str2double(out);
end
function check=LOCAL_topology(mesh)
  % Shared-edge P2 numbering and disk coverage of the merged tail mesh.
  tr=mesh.triangles;nt=size(tr,1);nv=size(mesh.points,1);ne=size(mesh.edges,1);
  [edges,~,ix]=unique(sort([tr(:,[1,2]);tr(:,[2,3]);tr(:,[3,1])],2),'rows');incidence=accumarray(ix,1);
  check=struct('triangles',nt,'vertices',nv,'edges',ne,'boundary_edges',sum(incidence==1),'euler',nv-ne+nt);
  assert(isequal(edges,mesh.edges)&&all(incidence<=2)&&isequal(mesh.triangle_p2(:,4:6),nv+reshape(ix,nt,3)) ...
    &&check.euler==1,'e2:Topology','Tail mesh topology failed.');
end
function out=LOCAL_similarity(path,mesh,u,config)
  % Normalized complex trace similarity on common core vertical-wall P2 nodes.
  old=load(path,'mesh','eigenvectors','constraint','modes');
  assert(old.modes(1).candidate&&old.modes(1).k==config.k_old,'e2:Reference','Old reference candidate differs.');
  uo=old.constraint.prolongation*old.eigenvectors(:,1);tol=1e-9;walls=[-1.5,-.5,.5,1.5];
  a=[];b=[];per=zeros(size(walls));count=zeros(size(walls));
  for j=1:numel(walls)
    io=find(abs(old.mesh.p2_points(:,1)-walls(j))<tol);
    [found,in]=ismember(round(old.mesh.p2_points(io,:)/tol),round(mesh.p2_points/tol),'rows');
    x=uo(io(found));y=u(in(found));per(j)=abs(x'*y)/(norm(x)*norm(y));count(j)=nnz(found);
    a=[a;x];b=[b;y]; %#ok<AGROW>
  end
  out=struct('walls',walls,'per_wall',per,'nodes_per_wall',count,'common_nodes',numel(a), ...
    'total',abs(a'*b)/(norm(a)*norm(b)),'label','DIAGNOSTIC_ONLY_NOT_IDENTITY_PROOF');
end
function ends=LOCAL_endlist(mesh,mx,my,E,order)
  % Artificial-end Grams only for elements carrying an x=xmin or x=xmax edge.
  [z,w]=LOCAL_gauss(order);el=[];G=zeros(15,15,0);len=[0,0];
  for side=1:2
    loc=mesh.xmin;if side==2,loc=mesh.xmax;end
    edges=find(abs(E.midpoints(:,1)-loc)<1e-12);[ti,le]=find(ismember(E.ids,edges));
    for j=1:numel(ti)
      t=ti(j);e=le(j);[x,y,n]=LOCAL_edge(e,z);[vx,vy]=LOCAL_rt(x,y);
      [~,~,~,~,J]=LOCAL_field(repmat(mx(t,:),order,1),repmat(my(t,:),order,1),zeros(order,6),x,y);
      if e==1,tx=J(:,1);ty=J(:,3);elseif e==2,tx=-J(:,1)+J(:,2);ty=-J(:,3)+J(:,4);else,tx=-J(:,2);ty=-J(:,4);end
      hn=vx*n(1)+vy*n(2);G(:,:,end+1)=hn'*((w./hypot(tx,ty)).*hn); %#ok<AGROW>
      el(end+1,1)=t;len(side)=len(side)+sum(w.*hypot(tx,ty)); %#ok<AGROW>
    end
  end
  assert(numel(unique(el))==numel(el)&&all(abs(len-1)<1e-12),'e2:Ends','End wall Grams failed.');
  ends=struct('elements',el,'G',(G+permute(G,[2,1,3]))/2,'lengths',len);
end
function [leafblocks,counts,info]=LOCAL_partition_blocks(mesh,mx,my,blocks,config)
  % Same recursive classification as LOCAL_partition; leaves of each element block
  % are compressed at once into one numeric table with block-local element ids.
  ng=config.curve_segments;cmin=min(mesh.cell_id);curves=LOCAL_curves(mesh,ng);
  nt=size(mx,1);counts=zeros(nt,1);leafblocks=cell(numel(blocks),1);
  for b=1:numel(blocks)
    ids=blocks{b};parts=cell(numel(ids),1);
    for j=1:numel(ids)
      k=ids(j);c=mesh.cell_id(k);
      parts{j}=LOCAL_split(j,[0,0;1,0;0,1],0,(1:ng)',mx(k,:),my(k,:),c,curves{c-cmin+1},config.maximum_subdivision);
      counts(k)=size(parts{j},1);
    end
    leafblocks{b}=vertcat(parts{:});clear parts
  end
  total=sum(counts);unres=sum(cellfun(@(L)sum(L(:,8)==0),leafblocks));depth=max(cellfun(@(L)max(L(:,9)),leafblocks));
  info=struct('leaves',total,'unresolved_leaves',unres,'max_depth',depth,'curve_segments',ng, ...
    'maximum_subdivision',config.maximum_subdivision,'element_block',config.element_block, ...
    'leaf_table_bytes',8*9*total);
end
function [Hm,qm]=LOCAL_blockform(ids,leaf,mesh,mx,my,mu,ends,s,m,gamma,Dinv,config)
  % Unweighted J_m in local moments: H=G0+Gdr/s+gamma*Gend, q=-f0+(m/s)gu (no rho in the cross term).
  nb=numel(ids);mb=struct('cell_id',mesh.cell_id(ids));
  el=LOCAL_element(mx(ids,:),my(ids,:),mu(ids,:),config.element_order);
  lf=LOCAL_leafdata(leaf,mb,mx(ids,:),my(ids,:),mu(ids,:),config.assembly_leaf_order,config.batch_size);
  H=permute(el.G0,[2,3,1])+permute(reshape(lf.Gdr,nb,15,15),[2,3,1])/s;
  [hit,loc]=ismember(ends.elements,ids);H(:,:,loc(hit))=H(:,:,loc(hit))+gamma*ends.G(:,:,hit);
  q=-el.f0.'+(m/s)*el.gu.';
  Hm=pagemtimes(pagemtimes(Dinv.',H),Dinv);Hm=(Hm+pagetranspose(Hm))/2;qm=Dinv.'*q;
end
function [res,fc]=LOCAL_uncondensed(form,blocks,yloc,g,phi,ndof,nE,Dinv,coeff,config)
  % Rebuild each local block; interior equations per element, edge equations only
  % after signed/phased global assembly. Optional uncondensed solve (smoke only).
  edge=zeros(nE,1);redge=zeros(nE,1);int2=0;rint2=0;Jval=0;fc=struct('performed',false);
  if config.condense_check,Iall=[];Jall=[];Vall=[];rall=complex(zeros(ndof,1));end
  for b=1:numel(blocks)
    ids=blocks{b};nb=numel(ids);[Hm,qm]=form(b);y=yloc(ids,:).';
    grad=reshape(pagemtimes(Hm,reshape(y,15,1,nb)),15,nb)+qm;
    Jval=Jval+real(sum(conj(y).*(grad+qm),'all'));
    int2=int2+sum(abs(grad(10:15,:)).^2,'all');rint2=rint2+sum(abs(qm(10:15,:)).^2,'all');
    pe=phi(ids,1:9).';ge=g(ids,1:9).';
    edge=edge+full(sparse(ge(:),1,conj(pe(:)).*reshape(grad(1:9,:),[],1),nE,1));
    redge=redge+full(sparse(ge(:),1,conj(pe(:)).*reshape(qm(1:9,:),[],1),nE,1));
    if config.condense_check
      pt=phi(ids,:).';gt=g(ids,:).';V=conj(reshape(pt,15,1,nb)).*Hm.*reshape(pt,1,15,nb);
      Iall=[Iall;reshape(repmat(reshape(gt,15,1,nb),1,15,1),[],1)]; %#ok<AGROW>
      Jall=[Jall;reshape(repmat(reshape(gt,1,15,nb),15,1,1),[],1)];Vall=[Vall;V(:)]; %#ok<AGROW>
      rall=rall+full(sparse(gt(:),1,conj(pt(:)).*qm(:),ndof,1));
    end
  end
  den=sqrt(sum(abs(redge).^2)+rint2);
  res=struct('relative',sqrt(sum(abs(edge).^2)+int2)/den,'edge_relative',norm(edge)/den, ...
    'interior_relative',sqrt(int2)/den,'objective_quadratic_part',Jval);
  if config.condense_check
    Af=sparse(Iall,Jall,Vall,ndof,ndof);Af=(Af+Af')/2;zf=-(Af\rall);
    cf=(phi.*zf(g))*Dinv.';
    fc=struct('performed',true,'ndof',ndof,'relative_residual',norm(Af*zf+rall)/norm(rall), ...
      'coefficient_difference',max(abs(cf-coeff),[],'all')/max(abs(cf),[],'all'), ...
      'objective_full',real(zf'*Af*zf+2*real(zf'*rall)),'objective_condensed',Jval);
    fc.objective_relative_difference=abs(fc.objective_full-Jval)/abs(fc.objective_full);
    assert(fc.coefficient_difference<1e-8,'e2:CondenseCheck','Condensed and full solutions differ (%.3g).', ...
      fc.coefficient_difference);
  end
end
function out=LOCAL_e2_direct(leafblocks,blocks,mesh,mx,my,mu,c,geo,E,config,order,end_order)
  % Theorem B two-pass direct evaluation, per element block (element-local passes).
  t0=tic;nt=size(mx,1);ev1=struct();ev2=struct();
  for b=1:numel(blocks)
    ids=blocks{b};mb=struct('cell_id',mesh.cell_id(ids));
    [a1,a2]=LOCAL_twopass(leafblocks{b},mb,mx(ids,:),my(ids,:),mu(ids,:),c(ids,:),config.m_residual,order,config.batch_size);
    ev1=LOCAL_place(ev1,a1,ids,nt);ev2=LOCAL_place(ev2,a2,ids,nt);
  end
  endsq=LOCAL_ends(mesh,mx,my,mu,c,E,end_order);s=config.s;m=config.m_residual;
  bound=LOCAL_bound(ev1,ev2,geo,s,config,endsq);mass=sum(ev1.mass);U=sqrt(mass);muR=sum(ev1.grad2)/mass;
  sc=LOCAL_scalars(bound,U,muR,m,s,config,true);R=sc.R_linear_mu_h;
  applicable=muR<config.lambda_plus;muc=[muR-sc.x_T(1),muR];
  final=struct('eta_m',bound.etaB,'U',U,'mass',mass,'mu_R',muR,'mu_R_minus_m',muR-m, ...
    'tau_h',bound.etaB/U,'R',R,'mu_interval',[m-R,m+R],'k_interval',[sqrt(max(m-R,0)),sqrt(m+R)], ...
    'k_halfwidth_direct',max(abs([sqrt(max(m-R,0)),sqrt(m+R)]-sqrt(m))),'k_halfwidth_first_order',R/(2*sqrt(m)), ...
    'gradient_difference',sqrt(bound.eps2_total),'mean_part_over_s',bound.mean_part_over_s, ...
    'osc2_total',bound.osc2_total,'weighted_osc_total',bound.weighted_osc_total,'branch1_elements',bound.branch1_elements, ...
    'end_norms',bound.end_norms,'end_contributions',bound.C_end*bound.end_norms,'bulk',bound.bulkB, ...
    'unresolved_area',bound.unresolved_area,'eta9',bound.eta9,'R_eta9',sc.R_linear_mu_h_eta9, ...
    'conditional',struct('label','CONDITIONAL_H_PLUS_UNVERIFIED','applicable_mu_R_below_lambda_plus',applicable, ...
    'tau_R',sc.tau_R,'x_T',sc.x_T(1),'mu_interval',muc,'k_interval',sqrt(max(muc,0)), ...
    'distance_mu',sc.dist_mu_h_conditional,'k_distance_direct',max(abs(sqrt(max(muc,0))-sqrt(m))), ...
    'lambda_plus',config.lambda_plus),'status','UNCERTIFIED_ORDINARY_ARITHMETIC_ESTIMATE');
  out=struct('order',order,'end_order',end_order,'bound',bound,'final',final,'scalars',sc,'seconds',toc(t0));
end
function ev=LOCAL_place(ev,part,ids,nt)
  names=fieldnames(part);
  for j=1:numel(names)
    if ~isfield(ev,names{j}),ev.(names{j})=zeros(nt,1);end
    ev.(names{j})(ids)=part.(names{j});
  end
end
function out=LOCAL_e2_summary(d)
  out=d.final;out.order=d.order;out.end_order=d.end_order;out.seconds=d.seconds;
  out.totals=rmfield(d.bound,'element');
end
function LOCAL_e2_print(d)
  f=d.final;fprintf(['STAGE direct Q%d: eta=%.10g U=%.10g muR=%.12g R=%.12g grad=%.6g ends=[%.4g %.4g] ' ...
    'unres=%.4g xT=%.4g (%.1fs)\n'],d.order,f.eta_m,f.U,f.mu_R,f.R,f.gradient_difference,f.end_contributions, ...
    f.unresolved_area,f.conditional.x_T,d.seconds);
end
function c=LOCAL_e2_compare(direct,config)
  % Frozen rule: both orders decrease and the smaller decrease exceeds the larger
  % Q-order difference of the new and old fields (a sensitivity comparison only).
  h=config.history;new=[direct.q10.final.R,direct.q8.final.R];dq=abs(new(1)-new(2));
  c=struct('mm',LOCAL_rule(new,[h.R_mm_q10,h.R_mm_q8],dq),'ls',LOCAL_rule(new,[h.R_ls_q10,h.R_ls_q8],dq), ...
    'new_R',new,'new_q_difference',dq,'unresolved_area_q_difference', ...
    abs(direct.q10.final.unresolved_area-direct.q8.final.unresolved_area), ...
    'k_new',config.k_h,'k_old',config.k_old,'drift_k',config.k_h-config.k_old, ...
    'bie',struct('label','CONDITIONAL_WORKING_ASSUMPTION','k_bie',h.k_bie,'k_new_minus_bie',config.k_h-h.k_bie, ...
    'k_old_minus_bie',config.k_old-h.k_bie,'mu_new_minus_bie',config.mu_h-h.k_bie^2, ...
    'inside_q10_k_interval',h.k_bie>=direct.q10.final.k_interval(1)&&h.k_bie<=direct.q10.final.k_interval(2)));
end
function r=LOCAL_rule(new,old,dq)
  drop=old-new;threshold=max(dq,abs(old(1)-old(2)));
  cls='FLAT_OR_UNRESOLVED';
  if all(drop>0)&&min(drop)>threshold
    cls='RESOLVED_IMPROVEMENT_ORDINARY_ARITHMETIC';
  elseif all(drop<0)&&min(-drop)>threshold
    cls='RESOLVED_WORSE_ORDINARY_ARITHMETIC';
  end
  r=struct('old_R',old,'ratio',new./old,'absolute_drop',drop,'relative_drop',drop./old, ...
    'threshold_max_q_difference',threshold,'old_q_difference',abs(old(1)-old(2)), ...
    'sensitivity_over_drop',threshold./abs(drop),'classification',cls);
end

%% ==================== Bound assembly and scalar outputs ====================
% Theorem B per element, B.1 (9) by the second branch, then (15), (11), (12).
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
function sc=LOCAL_scalars(b,U,muR,mu_h,s,config,at_mu_h)
  % Residual evaluated at mu_h (step 0) or mu_R; transfer by C3 (12).
  shift=abs(muR-mu_h)*U/sqrt(s);
  if at_mu_h,eta_h=b.etaB;eta_R=b.etaB+shift;else,eta_R=b.etaB;eta_h=b.etaB+shift;end
  tauR=eta_R/U;tauh=eta_h/U;
  lin=@(t,m)t/2*(t+sqrt(t^2+4*(m+s)));
  lp=config.lambda_plus;xT=(lp+s)*tauR^2./((lp-muR)+(lp+s)*tauR^2/(muR+s));
  lm=config.lambda_minus;delta=(muR-lm)-(lm+s)*tauR^2/(muR+s);
  y=NaN;if delta>0,y=(lm+s)*tauR^2/delta;end
  far=max(abs(mu_h-(muR-xT)),abs(mu_h-muR));
  sc=struct('eta_R',eta_R,'eta_h',eta_h,'tau_R',tauR,'tau_h',tauh,'transfer_shift',shift, ...
    'R_linear_mu_h',lin(tauh,mu_h),'R_linear_mu_R',lin(tauR,muR), ...
    'R_linear_mu_h_eta9',lin(LOCAL_ifelse(at_mu_h,b.eta9,b.eta9+shift)/U,mu_h), ...
    'lambda_plus',lp,'x_T',xT,'factor_F',(lp+s)./(lp-muR),'lambda_minus',lm,'y_lower',y, ...
    'dist_mu_h_conditional',far,'k_halfwidth_conditional',far/(2*sqrt(mu_h)), ...
    'R_linear_over_reference',lin(tauh,mu_h)./config.radius_reference, ...
    'x_T_over_reference',xT(1)./config.radius_reference);
end
function fluxes=LOCAL_record(fluxes,name,coeff,s,muv,bound,sc,solve)
  item=struct('name',name,'s',s,'mu_residual',muv,'coeff',coeff,'bound',bound,'scalars',sc,'solve',solve);
  if isempty(fluxes),fluxes=item;else,fluxes(end+1)=item;end
end
function v=LOCAL_ifelse(c,a,b)
  if c,v=a;else,v=b;end
end

%% ==================== Weighted least-squares RT2 flux ====================
% Element quadratic forms of s-eq-temple (6) in RT2 generator coefficients,
% mapped to shared edge/interior moments with signs and quasi-periodic phases.
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
function [coeff,info]=LOCAL_solve(el,lf,geo,rhomax,Gend,g,phi,ndof,Dinv,s,mu,weighted,config)
  nt=size(g,1);theta=config.theta;Cend=(2*sqrt(s*config.rho_min))^(-.5);
  gamma=config.gamma_factor*Cend^2;
  G0=permute(el.G0,[2,3,1]);Gd=permute(el.Gd,[2,3,1]);Gdr=permute(reshape(lf.Gdr,nt,15,15),[2,3,1]);
  mm=el.m'*el.m;r0=mu*lf.rhou;fd=mu*lf.fdr;fdr=mu*el.gu;
  branch1=isfinite(geo.CP)&geo.CP.*sqrt(s*rhomax)<=1;if ~weighted,branch1=false(nt,1);end
  b1=(1+1/theta)*geo.CP.^2;b2=lf.rinv./(s*el.area.^2);
  H=zeros(15,15,nt);q=complex(zeros(15,nt));
  for t=1:nt
    if branch1(t)
      H(:,:,t)=(1+theta)*G0(:,:,t)+b1(t)*(Gd(:,:,t)-mm/el.area(t))+b2(t)*mm;
      q(:,t)=-(1+theta)*el.f0(t,:).'+b1(t)*(fd(t,:).'-el.m.'*r0(t)/el.area(t))+b2(t)*el.m.'*r0(t);
    else
      H(:,:,t)=G0(:,:,t)+Gdr(:,:,t)/s;q(:,t)=-el.f0(t,:).'+fdr(t,:).'/s;
    end
  end
  H=H+gamma*permute(Gend,[2,3,1]);
  Hm=pagemtimes(pagemtimes(Dinv.',H),Dinv);qm=Dinv.'*q;
  pt=phi.';gt=g.';V=conj(reshape(pt,15,1,nt)).*Hm.*reshape(pt,1,15,nt);
  I=repmat(reshape(gt,15,1,nt),1,15,1);J=repmat(reshape(gt,1,15,nt),15,1,1);
  A=sparse(I(:),J(:),V(:),ndof,ndof);A=(A+A')/2;
  rhs=sparse(gt(:),1,conj(pt(:)).*qm(:),ndof,1);rhs=full(rhs);
  z=-(A\rhs);res=norm(A*z+rhs)/norm(rhs);
  mloc=phi.*z(g);coeff=mloc/(Dinv\eye(15)).';
  info=struct('weighted',weighted,'branch1_elements',nnz(branch1),'gamma',gamma, ...
    'relative_residual',res,'nnz',nnz(A),'ndof',ndof,'flux_norm_coefficients',norm(coeff,'fro'));
  assert(isfinite(res)&&res<1e-8,'i95:Solve','Least-squares flux solve failed (residual %.3g).',res);
end

%% ==================== Element and leaf data ====================
% Smooth Grams use whole curved elements; rho-dependent data use material leaves.
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
function el=LOCAL_element(mx,my,mu,order)
  nt=size(mx,1);[qx,qy,qw]=LOCAL_duffy(order);
  G0=zeros(nt,15,15);Gd=zeros(nt,15,15);f0=complex(zeros(nt,15));gu=complex(zeros(nt,15));
  area=zeros(nt,1);grad2=zeros(nt,1);m=zeros(1,15);
  for q=1:numel(qw)
    [u,gx,gy,~,J,d]=LOCAL_field(mx,my,mu,qx(q),qy(q));[vx,vy,dv]=LOCAL_rt(qx(q),qy(q));
    px=(J(:,1).*vx+J(:,2).*vy)./d;py=(J(:,3).*vx+J(:,4).*vy)./d;w=qw(q)*d;
    G0=G0+w.*(reshape(px,nt,15,1).*reshape(px,nt,1,15)+reshape(py,nt,15,1).*reshape(py,nt,1,15));
    Gd=Gd+(qw(q)./d).*reshape(dv'*dv,1,15,15);
    f0=f0+w.*(gx.*px+gy.*py);gu=gu+qw(q)*u.*dv;
    area=area+w;grad2=grad2+w.*(abs(gx).^2+abs(gy).^2);m=m+qw(q)*dv;
  end
  [num,den]=rat(m,1e-13);m=num./den;
  el=struct('G0',G0,'Gd',Gd,'f0',f0,'gu',gu,'area',area,'grad2',grad2,'m',m);
end
function lf=LOCAL_leafdata(leaves,mesh,mx,my,mu,order,batch)
  nt=size(mx,1);nl=size(leaves,1);[qx,qy,qw]=LOCAL_duffy(order);
  rhou=complex(zeros(nt,1));rinv=zeros(nt,1);fdr=complex(zeros(nt,15));Gdr=zeros(nt,225);
  for start=1:batch:nl
    ids=start:min(start+batch-1,nl);leaf=leaves(ids,:);t=leaf(:,1);n=numel(ids);
    va=leaf(:,2:3);ab=leaf(:,4:5)-va;ac=leaf(:,6:7)-va;scale=ab(:,1).*ac(:,2)-ab(:,2).*ac(:,1);
    un=leaf(:,8)==0;a1=complex(zeros(n,1));a2=zeros(n,1);a3=complex(zeros(n,15));a4=zeros(n,225);
    for q=1:numel(qw)
      xx=va(:,1)+qx(q)*ab(:,1)+qy(q)*ac(:,1);yy=va(:,2)+qx(q)*ab(:,2)+qy(q)*ac(:,2);
      [u,~,~,~,~,d,pxy]=LOCAL_field(mx(t,:),my(t,:),mu(t,:),xx,yy);[~,~,dv]=LOCAL_rt(xx,yy);
      rho=leaf(:,8);rho(un)=LOCAL_rho(pxy(un,1),pxy(un,2),mesh.cell_id(t(un)));w=qw(q)*scale;
      a1=a1+w.*d.*rho.*u;a2=a2+w.*d./rho;a3=a3+(w.*rho.*u).*dv;
      a4=a4+(w./(rho.*d)).*reshape(reshape(dv,n,15,1).*reshape(dv,n,1,15),n,225);
    end
    S=sparse(t,1:n,1,nt,n);rhou=rhou+S*a1;rinv=rinv+S*a2;fdr=fdr+S*a3;Gdr=Gdr+S*a4;
  end
  lf=struct('rhou',rhou,'rinv',rinv,'fdr',fdr,'Gdr',Gdr);
end
function G=LOCAL_endgram(mesh,mx,my,E,order)
  nt=size(mx,1);G=zeros(nt,15,15);[z,w]=LOCAL_gauss(order);
  for side=1:2
    loc=mesh.xmin;if side==2,loc=mesh.xmax;end
    edges=find(abs(E.midpoints(:,1)-loc)<1e-12);[ti,le]=find(ismember(E.ids,edges));
    for j=1:numel(ti)
      t=ti(j);e=le(j);[x,y,n]=LOCAL_edge(e,z);[vx,vy]=LOCAL_rt(x,y);
      [~,~,~,~,J]=LOCAL_field(repmat(mx(t,:),order,1),repmat(my(t,:),order,1),zeros(order,6),x,y);
      if e==1,tx=J(:,1);ty=J(:,3);elseif e==2,tx=-J(:,1)+J(:,2);ty=-J(:,3)+J(:,4);else,tx=-J(:,2);ty=-J(:,4);end
      hn=vx*n(1)+vy*n(2);G(t,:,:)=G(t,:,:)+reshape(hn'*((w./hypot(tx,ty)).*hn),1,15,15);
    end
  end
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
function m=LOCAL_moments(mx,my,mu,ne,nv)
  nt=size(mx,1);m=complex(zeros(nt,15));[z,w]=LOCAL_gauss(ne);
  for e=1:3
    [x,y,n]=LOCAL_edge(e,z);L=[ones(size(z)),2*z-1,6*z.^2-6*z+1];
    for q=1:numel(z)
      [~,gx,gy,~,J]=LOCAL_field(mx,my,mu,x(q),y(q));
      qx=J(:,4).*gx-J(:,2).*gy;qy=-J(:,3).*gx+J(:,1).*gy;
      m(:,(e-1)*3+(1:3))=m(:,(e-1)*3+(1:3))+w(q)*(qx*n(1)+qy*n(2))*L(q,:);
    end
  end
  [x,y,w]=LOCAL_duffy(nv);
  for q=1:numel(w)
    [~,gx,gy,~,J]=LOCAL_field(mx,my,mu,x(q),y(q));
    qx=J(:,4).*gx-J(:,2).*gy;qy=-J(:,3).*gx+J(:,1).*gy;
    m(:,10:12)=m(:,10:12)+w(q)*qx*[1,x(q),y(q)];
    m(:,13:15)=m(:,13:15)+w(q)*qy*[1,x(q),y(q)];
  end
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
  ng=config.curve_segments;cmin=min(mesh.cell_id);curves=LOCAL_curves(mesh,ng);
  nt=size(mx,1);parts=cell(nt,1);
  for k=1:nt
    c=mesh.cell_id(k);parts{k}=LOCAL_split(k,[0,0;1,0;0,1],0,(1:ng)',mx(k,:),my(k,:),c,curves{c-cmin+1},config.maximum_subdivision);
  end
  leaves=vertcat(parts{:});
  info=struct('leaves',size(leaves,1),'unresolved_leaves',sum(leaves(:,8)==0),'max_depth',max(leaves(:,9)), ...
    'curve_segments',ng,'maximum_subdivision',config.maximum_subdivision);
end
function curves=LOCAL_curves(mesh,ng)
  % Segment boxes of the analytic interface, enlarged by the chord-to-arc tube.
  t=(0:ng)'*2*pi/ng;cmin=min(mesh.cell_id);cmax=max(mesh.cell_id);
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
