function result = check_b_resid(attempt)
%CHECK_B_RESID Compute the I3.1 BIE-collar continuous weak residual.
% Purpose:
%   Reconstruct the saved candidate in both infinite leads, repair the BIE
%   field into a conforming Q1 companion, and evaluate an RT0 majorant.
% Input:
%   attempt - The sole V3 Revision B tag, 'bie-a3'.
% Output:
%   result  - Append-only diagnostics, first-failure semantics, and costs.
% Main algorithm:
%   Qualify frozen branches and whole-subspace propagation; rebuild the BIE
%   response; qualify one-sided traces and safe evaluations; form two Q1--RT0
%   levels; and contract both nonnormal infinite tails without P inverse.
% Based on:
%   research/projects/eig-apost/implementation/i3/design-3-1d.md.
% Main changes:
%   Uses true incoming BIE fields and explicit circle/wall collars instead of
%   a Helmholtz cell extension or a near-boundary strong-residual fit.
% Numerical goal:
%   Produce an ordinary-double estimator candidate, never a certified bound.

  if nargin~=1 || ~strcmp(char(attempt),'bie-a3')
    error('i31b:Attempt','The frozen V3 Revision B attempt name is bie-a3.');
  end
  here=fileparts(mfilename('fullpath'));
  output=fullfile(here,'output',char(attempt));
  if exist(output,'dir') || exist(output,'file')
    error('i31b:OutputExists','Output already exists: %s.',output);
  end
  if exist('OCTAVE_VERSION','builtin')~=0
    error('i31b:MATLABRequired','This experiment requires MATLAB.');
  end

  timer=tic; c=LOCAL_config(); result=LOCAL_empty_result(char(attempt),c);
  peak_mib=0;
  try
    % --- stage 1: frozen candidate and outgoing branch ---
    rows=LOCAL_selectors();
    eval_cfg=c; eval_cfg.kstar=eval_cfg.kseed;
    [seed,frame]=eval_i21('seed',eval_cfg,rows); LOCAL_seed_gate(seed,frame,c);
    node=eval_i21('point',c.khat,eval_cfg,frame); LOCAL_point_gate(node,frame,c);
    finite=LOCAL_finite_input(node,c); result.finite_input=finite;
    branch=LOCAL_branch(node,frame,c); result.branch=branch;
    if ~branch.pass
      error('i31b:BranchWood','The outgoing branch or Wood-distance gate failed.');
    end
    peak_mib=max(peak_mib,LOCAL_mib({seed,frame,node,finite}));
    LOCAL_resource_gate(timer,peak_mib,c);

    % --- stage 2: frozen full-subspace propagation ---
    prop=LOCAL_propagation(node,c); result.propagation=prop.record;
    if ~prop.record.pass
      error('i31b:Propagation','A propagation or scattering-closure gate failed.');
    end
    coords=LOCAL_coordinates(node,finite.q,prop,c); result.coordinates=coords;
    actual=LOCAL_actual_closure(node,prop,coords,c);
    result.propagation.actual_state_closure=actual;
    if ~actual.pass
      error('i31b:Propagation','An actual-state scattering closure failed.');
    end
    peak_mib=max(peak_mib,LOCAL_mib({seed,frame,node,finite,prop,coords}));
    LOCAL_resource_gate(timer,peak_mib,c);
    LOCAL_soft_gate(timer,c,'BIE density reconstruction');

    % --- stage 3: BIE density, surface trace, and safe-field qualification ---
    density=i31_bie_cell('density',c,node,frame,prop);
    result.bie_density=density.record;
    if ~density.record.pass
      error('i31b:BieDensity','The BIE density/object-identity gate failed.');
    end
    surface=i31_bie_cell('surface',c,node,density,prop);
    result.surface_trace=surface.record;
    if ~surface.record.pass
      error('i31b:SurfaceTrace','The one-sided surface-trace gate failed.');
    end
    safe=i31_bie_cell('safe',c,node,surface,prop,coords);
    result.safe_evaluation=safe.record;
    if ~safe.record.pass
      error('i31b:SafeEvaluation','The safe-ring or wall-evaluation gate failed.');
    end
    peak_mib=max(peak_mib,LOCAL_mib({seed,frame,node,finite,prop,coords, ...
      density,surface,safe}));
    LOCAL_resource_gate(timer,peak_mib,c);
    LOCAL_soft_gate(timer,c,'two Q1--RT0 levels');

    % --- stage 4: two complete conforming Q1--RT0 levels ---
    levels=repmat(LOCAL_empty_level(),numel(c.fe_levels),1);
    for j=1:numel(c.fe_levels)
      if j>1, LOCAL_soft_gate(timer,c,'fine Q1--RT0 level'); end
      maps=i31_fe_cell('level',c,node,safe,prop,coords,c.fe_levels(j));
      levels(j).name=c.fe_levels(j).name;
      levels(j).reconstruction=maps.record;
      if ~maps.record.pass
        result.levels=levels(1:j);
        error('i31b:FormConformity','The Q1 companion-conformity gate failed.');
      end
      fe=i31_fe_cell('majorant',c,node,prop,coords,maps,c.fe_levels(j));
      levels(j).majorant=fe;
      result.levels=levels(1:j);
      LOCAL_majorant_gates(fe,c);
      tm=LOCAL_tail(prop.Pminus,fe.tail.minus,coords.cminus,c);
      tp=LOCAL_tail(prop.Pplus,fe.tail.plus,coords.cplus,c);
      levels(j).tail=struct('minus',tm.record,'plus',tp.record);
      result.levels=levels(1:j);
      if ~(tm.record.pass&&tp.record.pass)
        error('i31b:InfiniteTail','A full-matrix tail gate failed.');
      end
      levels(j).total=LOCAL_total(fe,tm,tp,coords,c,1);
      if ~levels(j).total.valid
        error('i31b:MajorantQuadrature','A global majorant value is invalid.');
      end
      result.levels=levels(1:j);
      peak_mib=max(peak_mib,LOCAL_mib({seed,frame,node,finite,prop,coords, ...
        density,surface,safe,levels})+maps.peak_local_workspace_mib+ ...
        fe.peak_local_workspace_mib+max(tm.active_mib,tp.active_mib));
      LOCAL_resource_gate(timer,peak_mib,c);
    end

    % --- stage 5: final-coordinate scale, refinement, and resolution ---
    LOCAL_soft_gate(timer,c,'scale and refinement');
    fine=levels(end).total;
    scale=LOCAL_scale_check(levels(end).majorant,prop,coords,c);
    result.phase_scale=scale;
    if ~scale.tail_pass
      error('i31b:InfiniteTail','The scaled/base full-matrix tail repeat failed.');
    end
    refinement=LOCAL_refinement(levels(1).total,fine,scale,c);
    result.refinement=refinement;
    result.estimator=LOCAL_estimator(fine,c);
    if ~scale.pass || ~refinement.pass
      error('i31b:MeshResolution','The scale or two-level resolution gate failed.');
    end
    result.coverage=LOCAL_coverage();
    result.continuous_form_residual_computed=true;
    result.functional_majorant_formula_applied=true;
    intervals=levels(1).total.interval_defined&&fine.interval_defined&& ...
      isfinite(levels(1).total.nominal_k_width)&&isfinite(fine.nominal_k_width);
    if ~intervals || fine.nominal_k_width>c.tau_k_pre
      error('i31b:WeakResidual','The nominal interval lacks the frozen resolution.');
    end
    result.execution_pass=true; result.indicator_available=true;
    result.status='I3_1_COMPUTED_CONTINUOUS_WEAK_RESIDUAL_ESTIMATOR_CANDIDATE';
    result.scientific_outcome= ...
      'COMPUTED_CONTINUOUS_WEAK_RESIDUAL_ESTIMATOR_CANDIDATE';
    result.first_failure=LOCAL_failure('RELIABLE_SPECTRAL_INTERVAL_UNAVAILABLE', ...
      'RELIABILITY','Ordinary-double quantities are not outward-enclosed.', ...
      'i31b:Reliability');
  catch ME
    result=LOCAL_fail(result,ME);
  end

  result.elapsed_seconds=toc(timer); result.peak_active_mib=peak_mib;
  result.soft_time_exceeded=result.elapsed_seconds>c.soft_seconds;
  if result.elapsed_seconds>c.hard_seconds || peak_mib>c.memory_mib_max
    result.execution_pass=false; result.indicator_available=false;
    if isstruct(result.estimator), result.estimator.available=false; end
    result.status='I3_1_EXECUTION_UNAVAILABLE'; result.scientific_outcome='UNAVAILABLE';
    result.first_failure=LOCAL_failure('EXECUTION_UNAVAILABLE','RESOURCE', ...
      'The hard time or active-object memory limit was exceeded.','i31b:Resource');
  end
  if exist(output,'dir') || exist(output,'file')
    error('i31b:OutputExists','Output appeared during the run: %s.',output);
  end
  mkdir(output); save(fullfile(output,'result.mat'),'result','-v7');
  LOCAL_report(fullfile(output,'report.md'),result);
end

%% ==================== Frozen runtime contract ====================
% Every scientific parameter and threshold is fixed in executable source.

function c=LOCAL_config()
  c=struct('schema','TEP_I3_1_BIE_COLLAR_WEAK_RESIDUAL_V3_REV_B', ...
    'beta',0.5,'d',1.0,'R',0.2,'s',1.0,'rho_disk',17, ...
    'X_L',-0.5,'X_R',0.5,'H',1.1,'proxy_dist',0.2, ...
    'M',48,'K',97,'kseed',1.8327703475952146, ...
    'khat',1.832770289108157,'tau_k_pre',1e-6, ...
    'wood_distance_min',1e-6,'branch_relative_max',1e-12, ...
    'action_rcond_min',1e-8,'action_residual_max',1e-10, ...
    'scattering_closure_max',1e-10,'block_identity_max',1e-12, ...
    'bie_rcond_min',1e-8,'bie_residual_max',1e-10, ...
    'surface_identity_max',1e-10,'manufactured_trace_max',1e-10, ...
    'source_refinement_max',1e-6,'delta_c',0.04,'delta_w',0.04, ...
    'wall_samples',512,'source_base',256,'source_refined',512, ...
    'form_defect_max',1e-12,'hdiv_defect_max',1e-12, ...
    'flux_rcond_min',1e-10,'flux_solve_residual_max',1e-10, ...
    'disk_area_tol',1e-12,'gram_hermitian_max',1e-12, ...
    'gram_psd_scale',1e-12,'component_relative_max',0.20, ...
    'scale_oracle',1e8*exp(1i*pi/7),'scale_relative_max',1e-11, ...
    'tail_share_max',1e-6,'tail_max_power',12, ...
    'soft_seconds',900,'hard_seconds',1800,'memory_mib_max',512, ...
    'target_batch',1024,'qp_pair_batch',4096);
  c.mu_h=c.khat^2; c.gamma=c.mu_h;
  c.fe_levels=[struct('name','coarse','Nx',64,'Ny',128,'Nr',32, ...
    'Ntheta',128),struct('name','fine','Nx',96,'Ny',192,'Nr',48, ...
    'Ntheta',192)];
  c.level=struct('name','fine','ntot',256,'N_side',160,'N_top',160, ...
    'N_proxy_edge',80,'M_pw',32);
  c.expected=struct('proxy_rank',260,'bie_order',512,'pencil_order',194, ...
    'graph_order',388);
  c.proxy_rank_ratio=1e-8; c.proxy_rank_gap_min=2;
  c.proxy_projector_repeat_tol=1e-10; c.proxy_rcond_min=1e-8;
  c.proxy_projected_tol=1e-11; c.proxy_full_residual_max=1e-5;
  c.proxy_shifted_residual_max=1e-5; c.proxy_seed_identity_tol=1e-12;
  c.branch_tol=1e-12; c.qz_residual_tol=1e-10; c.qz_overlap_min=0.9;
  c.cross_cluster_margin_min=100*c.K*eps; c.chart_margin_min=100*c.K*eps;
  c.chart_condition_eps_tol=1e-9; c.small_solve_residual_tol=1e3*c.K*eps;
  c.bie_residual_tol=1e-10; c.schur_tol=1e3*c.K*eps;
  c.dirichlet_rcond_min=1e-8; c.participation_min=1e-3;
  c.lift_residual_tol=1e-10;
  c.command="matlab -batch ""addpath(fullfile(pwd,'test','i3','b-resid'),"+ ...
    "fullfile(pwd,'test','i2','k-count')); check_b_resid('bie-a3');""";
end

function rows=LOCAL_selectors()
  rows.plus=[89 41 35 71 92 12 16 10 66 70 93 33 9 69 79 30 36 ...
    62 64 84 95 40 18 91 94 58 61 13 85 90 24 32 42 60 28 74 21 ...
    97 22 55 77 96 38 14 17 2 20 1 67 75 37 43 72 5 80 81 82 7 ...
    68 39 25 19 78 29 6 76 86 59 8 4 65 83 23 31 3 73 57 63 56 ...
    26 88 27 11 87 15 34 54 44 53 45 52 46 51 47 50 48 49];
  rows.minus=[162 132 117 174 103 124 134 140 173 194 101 172 186 ...
    120 167 168 170 178 189 100 153 180 192 110 118 121 125 169 175 ...
    176 185 119 160 164 179 108 113 114 131 165 171 183 193 111 128 ...
    133 139 159 181 190 191 106 129 157 163 135 116 127 155 177 102 ...
    104 126 130 137 156 184 109 138 187 115 136 154 161 166 158 123 ...
    98 122 105 188 112 152 99 182 107 151 141 150 142 149 143 148 ...
    144 147 145 146];
end

%% ==================== Frozen finite input ====================
% These helpers recover the I2 object without changing its evaluator.

function LOCAL_seed_gate(seed,frame,c)
  ok=seed.k==c.kseed&&seed.pass&&all([seed.factors.pass])&& ...
    isequal(size(seed.Aqp),[512,512])&&isequal(size(seed.AdefD),[194,194])&& ...
    isequal(size(frame.Z0_plus),[194,97])&& ...
    isequal(size(frame.Z0_minus),[194,97])&&frame.proxy_chart.r==260;
  if ~ok, error('i31b:FiniteInput','The frozen seed/frame gate failed.'); end
end

function LOCAL_point_gate(node,frame,c)
  ok=node.k==c.khat&&strcmp(node.name,'fine')&&node.spec.ntot==256&& ...
    node.pass&&node.plus.pass&&node.minus.pass&&node.cp.safe&&node.cm.safe&& ...
    all([node.factors.pass])&&isequal(node.H_plus_rows,frame.rows_plus)&& ...
    isequal(node.H_minus_rows,frame.rows_minus)&& ...
    isequal(size(node.AdefD),[194,194])&&isequal(size(node.AdefG),[388,388])&& ...
    all(isfinite(node.beta_m))&&all(isfinite(node.gamma));
  if ~ok, error('i31b:FiniteInput','The saved-candidate gate failed.'); end
end

function out=LOCAL_finite_input(node,c)
  b=sqrt(1+abs(node.beta_m(:)).^2);
  wr=repmat(sqrt(1./b),2,1);
  wc=repmat(1./sqrt(b+abs(node.gamma(:)).^2./b),2,1);
  A=wr.*node.AdefD.*wc.'; [~,S,V]=svd(A,'econ'); sv=diag(S);
  qraw=wc.*V(:,end);
  if any(~isfinite(qraw)) || norm(qraw)==0
    error('i31b:FiniteInput','The physical near-null vector is unavailable.');
  end
  q=qraw/norm(qraw);
  out=struct('pass',true,'q',q,'score',sv(end)/sv(1), ...
    'near_null_ratio',sv(end)/sv(end-1),'raw_residual',norm(node.AdefD*q), ...
    'raw_backward',norm(node.AdefD*q)/max(realmin,norm(node.AdefD,2)), ...
    'minimum_factor_rcond',min([node.factors.rcond]), ...
    'maximum_factor_residual',max([node.factors.residual]));
end

function out=LOCAL_branch(node,frame,c)
  port=LOCAL_branch_list(node.beta_m(:),node.gamma(:),c);
  a=frame.proxy_chart.anchor; delta=node.k-a.kc;
  proxy_gamma=a.gamma_seed.*exp(0.5*log(1+delta./(a.kc-a.beta_m))+ ...
    0.5*log(1+delta./(a.kc+a.beta_m)));
  proxy=LOCAL_branch_list(a.beta_m(:),proxy_gamma(:),c);
  wood=min(abs(node.gamma(:))./max([ones(c.K,1), ...
    abs(c.khat)*ones(c.K,1),abs(node.beta_m(:))],[],2));
  audits=[node.branch_port.algebra,node.branch_port.roundtrip, ...
    node.branch_proxy.algebra,node.branch_proxy.roundtrip];
  out=struct('pass',port.pass&&proxy.pass&&wood>=c.wood_distance_min&& ...
    all(isfinite(audits))&&max(audits)<=c.branch_relative_max, ...
    'wood_distance',wood,'wood_minimum',c.wood_distance_min, ...
    'port',port,'proxy',proxy,'algebra_roundtrip_defects',audits);
end

function out=LOCAL_branch_list(beta,gamma,c)
  t=c.khat^2-beta.^2; s=max([ones(size(beta)),abs(c.khat)*ones(size(beta)), ...
    abs(beta)],[],2); ref=complex(zeros(size(beta)));
  prop=t>0; evan=t<0; ref(prop)=sqrt(t(prop)); ref(evan)=1i*sqrt(-t(evan));
  rel=abs(gamma-ref)./s;
  signpass=(~prop|real(gamma)>0)&(~evan|imag(gamma)>0);
  axispass=(~prop|abs(imag(gamma))./s<=c.branch_relative_max)& ...
    (~evan|abs(real(gamma))./s<=c.branch_relative_max);
  classification=repmat("UNRESOLVED",numel(beta),1);
  classification(prop)="PROPAGATING"; classification(evan)="EVANESCENT";
  out=struct('pass',all(prop|evan)&&all(signpass)&&all(axispass)&& ...
    all(rel<=c.branch_relative_max),'beta_m',beta,'gamma_m',gamma, ...
    't_m',t,'scale_m',s,'classification',classification, ...
    'propagating_mask',prop,'evanescent_mask',evan, ...
    'outgoing_reference',ref,'outgoing_relative_defects',rel, ...
    'outgoing_sign_pass',signpass,'axis_pass',axispass, ...
    'propagating',sum(prop),'evanescent',sum(evan), ...
    'maximum_outgoing_relative_defect',max(rel));
end

%% ==================== Whole-subspace propagation ====================
% Full matrix actions and scattering closures retain nonnormal coupling.

function out=LOCAL_propagation(node,c)
  plus=LOCAL_action(node.pair.A,node.pair.B,node.Zp,false,c);
  minus=LOCAL_action(node.pair.A,node.pair.B,node.Zm,true,c);
  K=c.K; Ap=node.Zp(1:K,:); Bp=node.Zp(K+1:end,:);
  Am=node.Zm(1:K,:); Bm=node.Zm(K+1:end,:);
  blocks=node.blocks; Pp=plus.P; Pm=minus.P;
  cp={Bp-blocks.R_L*Ap-blocks.T_RL*Bp*Pp, ...
    Ap*Pp-blocks.T_LR*Ap-blocks.R_R*Bp*Pp, ...
    Bm*Pm-blocks.R_L*Am*Pm-blocks.T_RL*Bm, ...
    Am-blocks.T_LR*Am*Pm-blocks.R_R*Bm};
  unit=zeros(1,4);
  % Normalize closures against their non-cancelled scattering sides.
  unit(1)=norm(cp{1},'fro')/max(1,norm(Bp,'fro'));
  unit(2)=norm(cp{2},'fro')/max(1,norm(Ap*Pp,'fro'));
  unit(3)=norm(cp{3},'fro')/max(1,norm(Bm*Pm,'fro'));
  unit(4)=norm(cp{4},'fro')/max(1,norm(Am,'fro'));
  states={eye(K),Pp,eye(K),Pm}; scales={Bp,Ap*Pp,Bm*Pm,Am};
  actual=zeros(1,8); pos=0;
  for side=1:2
    if side==1, residuals=cp(1:2); refs=scales(1:2); vectors=states(1:2);
    else, residuals=cp(3:4); refs=scales(3:4); vectors=states(3:4); end
    for j=1:2
      for k=1:2
        pos=pos+1; v=vectors{k};
        actual(pos)=norm(residuals{j}*v,'fro')/ ...
          max(1,norm(refs{j}*v,'fro'));
      end
    end
  end
  out=struct('Pplus',Pp,'Pminus',Pm,'Ap',Ap,'Bp',Bp,'Am',Am,'Bm',Bm, ...
    'Dplus',Ap+Bp,'Dminus',Am+Bm,'Gplus',1i*diag(node.gamma)*(Ap-Bp), ...
    'Gminus',1i*diag(node.gamma)*(Am-Bm),'record',struct( ...
    'pass',plus.pass&&minus.pass&&max(unit)<=c.scattering_closure_max&& ...
    max(actual)<=c.scattering_closure_max,'plus',LOCAL_drop(plus,{'P'}), ...
    'minus',LOCAL_drop(minus,{'P'}),'unit_closure_defects',unit, ...
    'unit_one_step_map_closure_defects',actual));
end

function out=LOCAL_action(A,B,Z,reversed,c)
  if reversed, C=A*Z; rhs=B*Z; else, C=B*Z; rhs=A*Z; end
  [~,R]=qr(C,0); rk=rank(R); rc=rcond(R);
  if ~isfinite(rc)||rk~=c.K||rc<c.action_rcond_min
    error('i31b:Propagation','A propagation action factor is rank deficient.');
  end
  try, P=C\rhs; catch ME
    error('i31b:Propagation','A propagation action solve failed: %s',ME.message);
  end
  solve=norm(C*P-rhs,'fro')/max([1,norm(C,'fro')*norm(P,2)+norm(rhs,'fro')]);
  if reversed, defect=norm(B*Z-A*Z*P,'fro')/ ...
      max([1,norm(B*Z,'fro')+norm(A*Z,'fro')*norm(P,2)]);
  else, defect=norm(A*Z-B*Z*P,'fro')/ ...
      max([1,norm(A*Z,'fro')+norm(B*Z,'fro')*norm(P,2)]); end
  finite=all(isfinite(P),'all')&&all(isfinite([rc,solve,defect]));
  out=struct('P',P,'rank',rk,'thin_qr_rcond',rc,'solve_residual',solve, ...
    'invariant_residual',defect,'pass',finite&&rk==c.K&& ...
    rc>=c.action_rcond_min&&max(solve,defect)<=c.action_residual_max);
end

function out=LOCAL_coordinates(node,q,prop,c)
  K=c.K; I=eye(K); E=diag(node.phase(:));
  cm=node.Dm\([I,E]*q); cp=node.Dp\([E,I]*q);
  rm=norm(node.Dm*cm-[I,E]*q)/max(1,norm([I,E]*q));
  rp=norm(node.Dp*cp-[E,I]*q)/max(1,norm([E,I]*q));
  if any(~isfinite([cm;cp])) || max(rm,rp)>c.action_residual_max
    error('i31b:Propagation','The frozen coordinate solve failed.');
  end
  out=struct('q',q,'cminus',cm,'cplus',cp,'q_norm',norm(q), ...
    'cminus_norm',norm(cm),'cplus_norm',norm(cp), ...
    'minus_solve_residual',rm,'plus_solve_residual',rp, ...
    'Pminus_norm',norm(prop.Pminus,2),'Pplus_norm',norm(prop.Pplus,2));
end

function out=LOCAL_actual_closure(node,prop,coords,c)
  b=node.blocks; Pp=prop.Pplus; Pm=prop.Pminus;
  rp={prop.Bp-b.R_L*prop.Ap-b.T_RL*prop.Bp*Pp, ...
    prop.Ap*Pp-b.T_LR*prop.Ap-b.R_R*prop.Bp*Pp};
  rm={prop.Bm*Pm-b.R_L*prop.Am*Pm-b.T_RL*prop.Bm, ...
    prop.Am-b.T_LR*prop.Am*Pm-b.R_R*prop.Bm};
  sp={prop.Bp,prop.Ap*Pp}; sm={prop.Bm*Pm,prop.Am};
  states={coords.cplus,Pp*coords.cplus,coords.cminus,Pm*coords.cminus};
  defects=zeros(1,8); p=0;
  for j=1:2
    for k=1:2, p=p+1; defects(p)=norm(rp{j}*states{k})/ ...
        max(1,norm(sp{j}*states{k})); end
  end
  for j=1:2
    for k=3:4, p=p+1; defects(p)=norm(rm{j}*states{k})/ ...
        max(1,norm(sm{j}*states{k})); end
  end
  out=struct('defects',defects,'states', ...
    {{'cplus','Pplus_cplus','cminus','Pminus_cminus'}}, ...
    'pass',all(isfinite(defects))&&max(defects)<=c.scattering_closure_max);
end

%% ==================== Majorant and tail gates ====================
% The scientific failure order follows design-3-1d exactly.

function LOCAL_majorant_gates(fe,c)
  if ~fe.form.pass || fe.form.maximum_defect>c.form_defect_max
    error('i31b:FormConformity','The global Q1 conformity gate failed.');
  end
  if ~fe.hdiv.pass || fe.hdiv.maximum_defect>c.hdiv_defect_max
    error('i31b:HdivFlux','The global RT0 continuity gate failed.');
  end
  if ~fe.factor.pass
    error('i31b:HdivFlux','The constrained RT0 factor/solve gate failed.');
  end
  if ~fe.integration_pass || ~fe.finite_pass || ~fe.gram_pass
    error('i31b:MajorantQuadrature','A true-circle or Gram gate failed.');
  end
end

function out=LOCAL_tail(P,grams,c0,c)
  names={'N','A','B','M'}; base={grams.N,grams.A,grams.B, ...
    grams.A+grams.B/c.gamma}; WL=base; WR=base; pN=P;
  start=P*c0; powers=cell(c.tail_max_power+1,1);
  rows=repmat(LOCAL_empty_tail_row(),c.tail_max_power+1,1);
  selected=NaN; active_mib=0;
  for j=0:c.tail_max_power
    N=2^j; powers{j+1}=pN; alternate=LOCAL_alternate_power(P,powers,j);
    association=norm(pN-alternate,2); pscale=max([1,norm(pN,2),norm(alternate,2)]);
    power_allowance=association+100*c.K*eps*pscale;
    ahi=norm(pN,2)+power_allowance; sums=zeros(1,4); omega=zeros(1,4);
    allowance=Inf(1,4); shares=Inf(1,4);
    for k=1:4
      wscale=max([1,norm(WL{k},2),norm(WR{k},2)]);
      omega(k)=norm(WL{k}-WR{k},2)+100*c.K*eps*wscale;
      sums(k)=real(start'*WL{k}*start);
      if isfinite(ahi)&&ahi<1
        allowance(k)=ahi^2/(1-ahi^2)*(norm(WL{k},2)+omega(k))*norm(start)^2;
        shares(k)=allowance(k)/max(realmin,sums(k));
      end
    end
    finite=all(isfinite([ahi,sums,omega,allowance,shares]));
    pass=finite&&ahi<1&&all(sums>=0)&&all(shares<=c.tail_share_max);
    rows(j+1)=struct('N',N,'starts_at_cell',1,'power_norm',norm(pN,2), ...
      'power_association_defect',association,'power_allowance',power_allowance, ...
      'a_hi',ahi,'finite_sums',sums,'gram_allowances',omega, ...
      'tail_allowances',allowance,'tail_shares',shares,'pass',pass);
    info=whos; active_mib=max(active_mib,sum([info.bytes])/2^20);
    if pass&&isnan(selected), selected=j+1; end
    if j==c.tail_max_power, break; end
    oldP=pN; pN=oldP*oldP;
    for k=1:4
      WL{k}=WL{k}+(oldP'*WL{k})*oldP;
      WR{k}=WR{k}+oldP'*(WR{k}*oldP);
    end
  end
  if isnan(selected), chosen=rows(end); pass=false;
  else, chosen=rows(selected); pass=true; end
  out=struct('chosen',chosen,'active_mib',active_mib,'record',struct( ...
    'pass',pass,'gram_names',{names},'levels',rows,'selected_index',selected, ...
    'selected_N',chosen.N,'starts_at_cell',1, ...
    'peak_local_workspace_mib',active_mib,'tail_diagnostic_certified',false));
end

function alternate=LOCAL_alternate_power(P,powers,j)
  if j<3
    count=2^j; alternate=P; for k=2:count, alternate=alternate*P; end
  else
    base=powers{j-2}; alternate=base; for k=2:8, alternate=alternate*base; end
  end
end

function row=LOCAL_empty_tail_row()
  row=struct('N',NaN,'starts_at_cell',1,'power_norm',NaN, ...
    'power_association_defect',NaN,'power_allowance',NaN,'a_hi',NaN, ...
    'finite_sums',NaN(1,4),'gram_allowances',NaN(1,4), ...
    'tail_allowances',NaN(1,4),'tail_shares',NaN(1,4),'pass',false);
end

function out=LOCAL_total(fe,tm,tp,coords,c,scale)
  a2=abs(scale)^2;
  center=a2*[fe.center.N,fe.center.A,fe.center.B];
  cm=scale*coords.cminus; cp=scale*coords.cplus;
  first=[real(cm'*fe.tail.minus.N*cm)+real(cp'*fe.tail.plus.N*cp), ...
    real(cm'*fe.tail.minus.A*cm)+real(cp'*fe.tail.plus.A*cp), ...
    real(cm'*fe.tail.minus.B*cm)+real(cp'*fe.tail.plus.B*cp)];
  tails=tm.chosen.finite_sums(1:3)+tp.chosen.finite_sums(1:3);
  values=real(center+first+tails); N=values(1); A=values(2); B=values(3);
  M2=A+B/c.gamma; valid=all(isfinite([N,A,B,M2]))&&N>0&& ...
    A>=0&&B>=0&&M2>=0; q=NaN;
  if valid, q=sqrt(M2/N); end
  defined=isfinite(q)&&q<1; li=[NaN,NaN]; ki=li; width=NaN;
  if defined
    li=[max(0,(c.mu_h-q*c.gamma)/(1+q)),(c.mu_h+q*c.gamma)/(1-q)];
    ki=sqrt(li); width=diff(ki);
  end
  out=struct('valid',valid,'N2',N,'A2',A,'B2',B,'M2',M2,'q',q, ...
    'interval_defined',defined,'nominal_lambda_interval',li, ...
    'nominal_k_interval',ki,'nominal_k_width',width, ...
    'first_cell_index',0,'tail_start_index',1, ...
    'tail_share_names',{{'N','A','B','M'}}, ...
    'tail_minus_shares',tm.chosen.tail_shares, ...
    'tail_plus_shares',tp.chosen.tail_shares);
end

function out=LOCAL_scale_check(fe,prop,coords,c)
  tm=LOCAL_tail(prop.Pminus,fe.tail.minus,c.scale_oracle*coords.cminus,c);
  tp=LOCAL_tail(prop.Pplus,fe.tail.plus,c.scale_oracle*coords.cplus,c);
  scaled=LOCAL_total(fe,tm,tp,coords,c,c.scale_oracle);
  tm0=LOCAL_tail(prop.Pminus,fe.tail.minus,coords.cminus,c);
  tp0=LOCAL_tail(prop.Pplus,fe.tail.plus,coords.cplus,c);
  base=LOCAL_total(fe,tm0,tp0,coords,c,1); a2=abs(c.scale_oracle)^2;
  tail_pass=tm.record.pass&&tp.record.pass&&tm0.record.pass&&tp0.record.pass;
  components=[abs(scaled.N2/a2-base.N2)/max(realmin,base.N2), ...
    abs(scaled.A2/a2-base.A2)/max(realmin,base.A2), ...
    abs(scaled.B2/a2-base.B2)/max(realmin,base.B2), ...
    abs(scaled.M2/a2-base.M2)/max(realmin,base.M2), ...
    abs(scaled.q-base.q)/max(realmin,base.q)];
  same_definition=scaled.interval_defined==base.interval_defined;
  interval_defects=NaN(1,5);
  if scaled.interval_defined&&base.interval_defined
    x=[scaled.nominal_lambda_interval,scaled.nominal_k_interval, ...
      scaled.nominal_k_width];
    y=[base.nominal_lambda_interval,base.nominal_k_interval, ...
      base.nominal_k_width];
    interval_defects=abs(x-y)./max([ones(size(x));abs(x);abs(y)],[],1);
  end
  interval_pass=same_definition&&(~base.interval_defined|| ...
    all(isfinite(interval_defects))&&max(interval_defects)<=c.scale_relative_max);
  out=struct('multiplier',c.scale_oracle,'relative_defects',components, ...
    'interval_relative_defects',interval_defects, ...
    'interval_check_applied',base.interval_defined, ...
    'tail_pass',tail_pass,'tail_selected_N', ...
    [tm0.record.selected_N,tp0.record.selected_N, ...
    tm.record.selected_N,tp.record.selected_N], ...
    'tail_selected_shares', ...
    [tm0.chosen.tail_shares;tp0.chosen.tail_shares; ...
    tm.chosen.tail_shares;tp.chosen.tail_shares], ...
    'pass',tail_pass&&all(isfinite(components))&& ...
    max(components)<=c.scale_relative_max&&interval_pass);
end

function out=LOCAL_refinement(coarse,fine,scale,c)
  denom=max([coarse.M2,fine.M2,realmin]);
  changes=[abs(fine.A2-coarse.A2)/denom, ...
    abs(fine.B2/c.gamma-coarse.B2/c.gamma)/denom, ...
    abs(fine.N2-coarse.N2)/max([fine.N2,coarse.N2,realmin])];
  if coarse.interval_defined&&fine.interval_defined
    width_status='APPLIED'; width_change=abs(fine.nominal_k_width-coarse.nominal_k_width);
    width_limit=max(0.20*fine.nominal_k_width,0.10*c.tau_k_pre);
    width_pass=isfinite(width_change)&&width_change<=width_limit;
  else
    width_status='NOT_APPLICABLE'; width_change=NaN; width_limit=NaN; width_pass=true;
  end
  component_pass=all(isfinite(changes))&&all(changes<=c.component_relative_max);
  out=struct('component_changes',changes,'component_pass',component_pass, ...
    'width_status',width_status,'width_change',width_change, ...
    'width_limit',width_limit,'width_pass',width_pass,'phase_scale_pass',scale.pass, ...
    'pass',component_pass&&width_pass&&scale.pass);
end

function out=LOCAL_estimator(fine,c)
  out=struct('available',fine.valid,'computed_q',fine.q, ...
    'computed_field_norm',sqrt(max(0,fine.N2)), ...
    'computed_majorant',sqrt(max(0,fine.M2)), ...
    'computed_A_component',sqrt(max(0,fine.A2)), ...
    'computed_B_component',sqrt(max(0,fine.B2)), ...
    'nominal_lambda_interval',fine.nominal_lambda_interval, ...
    'nominal_k_interval',fine.nominal_k_interval, ...
    'nominal_k_width',fine.nominal_k_width, ...
    'absolute_resolution_pass',fine.interval_defined&&fine.nominal_k_width<=c.tau_k_pre, ...
    'residual_upper_bound_certified',false,'field_lower_bound_certified',false, ...
    'tail_diagnostic_certified',false,'projected_gap_established',false, ...
    'reliability_status','RELIABLE_SPECTRAL_INTERVAL_UNAVAILABLE', ...
    'continuous_discrete_eigenvalue_existence',false,'continuous_error_bound',false, ...
    'shared_model_bias_present',true,'i3_2_independent_reference_eligible',false);
end

%% ==================== Result and failure semantics ====================
% The first scientific failure preserves all earlier small diagnostics.

function out=LOCAL_coverage()
  out=struct('global_conforming_trial',true,'sharp_material_volume',true, ...
    'cell_walls',true,'y_quasiperiodicity',true,'infinite_tail',true, ...
    'reliable_numerical_enclosure',false,'projected_gap',false, ...
    'unique_target',false,'continuous_error_upper_bound',false);
end

function out=LOCAL_empty_coverage()
  out=struct('global_conforming_trial',false,'sharp_material_volume',false, ...
    'cell_walls',false,'y_quasiperiodicity',false,'infinite_tail',false, ...
    'reliable_numerical_enclosure',false,'projected_gap',false, ...
    'unique_target',false,'continuous_error_upper_bound',false);
end

function level=LOCAL_empty_level()
  level=struct('name','','reconstruction',struct(),'majorant',struct(), ...
    'tail',struct(),'total',struct());
end

function result=LOCAL_empty_result(attempt,c)
  prior1=struct('attempt','bie-a1','shell_exit_code',0, ...
    'producer_outcome','EXECUTION_UNAVAILABLE', ...
    'identifier','MATLAB:nonExistentField', ...
    'message','Unrecognized field name "kstar".', ...
    'elapsed_seconds',0.04598954166666667,'peak_active_mib',0, ...
    'scientific_stage_entered',false,'last_completed_gate','NONE', ...
    'q1_and_later_status','NOT_REACHED','output_created',true, ...
    'artifacts',{{'result.mat','report.md'}});
  message2=sprintf(['File: /Users/whc/Documents/Work/epost/test/i3/b-resid/', ...
    'i31_fe_cell.m Line: 131 Column: 29\n', ...
    'Invalid expression. When calling a function or indexing a variable, ', ...
    'use parentheses. Otherwise, check for mismatched delimiters.']);
  prior2=struct('attempt','bie-a2','shell_exit_code',0, ...
    'producer_outcome','EXECUTION_UNAVAILABLE', ...
    'identifier','MATLAB:m_improper_grouping','message',message2, ...
    'elapsed_seconds',222.9809575416667, ...
    'peak_active_mib',89.65762805938721,'scientific_stage_entered',true, ...
    'last_completed_gate','SAFE_FIELD_EVALUATION', ...
    'q1_and_later_status','NOT_REACHED','output_created',true, ...
    'artifacts',{{'result.mat','report.md'}});
  prior=[prior1,prior2];
  adapter=struct('scope','two eval_i21 calls only', ...
    'source_field','kseed','legacy_field','kstar', ...
    'persisted_in_result_config',false);
  result=struct('schema',c.schema,'attempt',attempt,'candidate',c.khat, ...
    'mu_h',c.mu_h,'config',c,'command',c.command,'execution_pass',false, ...
    'evaluator_adapter',adapter,'prior_failed_attempt_count',2, ...
    'prior_attempt_history',prior, ...
    'indicator_available',false,'status','I3_1_NOT_RUN', ...
    'scientific_outcome','UNAVAILABLE','finite_input',struct(), ...
    'branch',struct(),'propagation',struct(),'coordinates',struct(), ...
    'bie_density',struct(),'surface_trace',struct(),'safe_evaluation',struct(), ...
    'levels',struct([]),'phase_scale',struct(),'refinement',struct(), ...
    'estimator',struct('available',false),'coverage',LOCAL_empty_coverage(), ...
    'continuous_form_residual_computed',false, ...
    'functional_majorant_formula_applied',false, ...
    'first_failure',LOCAL_failure('NOT_RUN','STARTUP','No computation has completed.',''), ...
    'elapsed_seconds',NaN,'peak_active_mib',NaN,'soft_time_exceeded',false, ...
    'retry_count',0,'retry_history',strings(0,1));
end

function result=LOCAL_fail(result,ME)
  [code,category]=LOCAL_failure_code(ME.identifier);
  result.first_failure=LOCAL_failure(code,category,ME.message,ME.identifier);
  result.scientific_outcome=code; result.status=['I3_1_',code];
  result.execution_pass=~strcmp(code,'EXECUTION_UNAVAILABLE');
  result.indicator_available=strcmp(code,'WEAK_RESIDUAL_RESOLUTION_INSUFFICIENT')&& ...
    isfield(result.estimator,'computed_q')&&isfinite(result.estimator.computed_q);
  if ~result.indicator_available, result.estimator.available=false; end
end

function [code,category]=LOCAL_failure_code(id)
  if startsWith(id,'i31b:FiniteInput')
    code='FINITE_DISCRETE_INPUT_UNAVAILABLE'; category='FINITE_INPUT';
  elseif startsWith(id,'i31b:BranchWood')
    code='BRANCH_OR_WOOD_UNRESOLVED'; category='BRANCH_WOOD';
  elseif startsWith(id,'i31b:Propagation')
    code='PROPAGATION_ACTION_UNRESOLVED'; category='PROPAGATION';
  elseif startsWith(id,'i31b:BieDensity')
    code='BIE_DENSITY_UNRESOLVED'; category='BIE_DENSITY';
  elseif startsWith(id,'i31b:SurfaceTrace')
    code='SURFACE_TRACE_UNRESOLVED'; category='SURFACE_TRACE';
  elseif startsWith(id,'i31b:SafeEvaluation')
    code='SAFE_FIELD_EVALUATION_UNRESOLVED'; category='SAFE_EVALUATION';
  elseif startsWith(id,'i31b:FormConformity')
    code='FORM_CONFORMITY_UNRESOLVED'; category='FORM_CONFORMITY';
  elseif startsWith(id,'i31b:HdivFlux')
    code='HDIV_FLUX_UNRESOLVED'; category='HDIV_FLUX';
  elseif startsWith(id,'i31b:MajorantQuadrature')
    code='MAJORANT_QUADRATURE_UNRESOLVED'; category='MAJORANT_QUADRATURE';
  elseif startsWith(id,'i31b:InfiniteTail')
    code='INFINITE_TAIL_UNRESOLVED'; category='INFINITE_TAIL';
  elseif startsWith(id,'i31b:MeshResolution')
    code='MESH_RESOLUTION_UNRESOLVED'; category='MESH_RESOLUTION';
  elseif startsWith(id,'i31b:WeakResidual')
    code='WEAK_RESIDUAL_RESOLUTION_INSUFFICIENT'; category='RESOLUTION';
  else
    code='EXECUTION_UNAVAILABLE'; category='EXECUTION';
  end
end

function out=LOCAL_failure(code,category,message,identifier)
  out=struct('code',code,'category',category,'message',message, ...
    'identifier',identifier);
end

function LOCAL_soft_gate(timer,c,next_stage)
  if toc(timer)>c.soft_seconds
    error('i31b:Resource','Soft time reached before %s.',next_stage);
  end
end

function LOCAL_resource_gate(timer,peak,c)
  if toc(timer)>c.hard_seconds || peak>c.memory_mib_max
    error('i31b:Resource','The hard time or active-object memory limit was exceeded.');
  end
end

function mib=LOCAL_mib(values)
  mib=0; for j=1:numel(values), item=values{j}; info=whos('item'); ...
      mib=mib+info.bytes/2^20; end
end

function out=LOCAL_drop(in,names)
  out=in; for j=1:numel(names), if isfield(out,names{j}), ...
      out=rmfield(out,names{j}); end, end
end

function LOCAL_report(path,r)
  fid=fopen(path,'w');
  if fid<0, error('i31b:Report','Cannot open report.md.'); end
  cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid,'# I3.1 BIE-collar weak residual\n\n');
  fprintf(fid,'- Attempt: %s\n- Status: %s\n',r.attempt,r.status);
  fprintf(fid,'- Attempt-local retry count: %d\n',r.retry_count);
  fprintf(fid,'- Prior failed attempt count: %d\n',r.prior_failed_attempt_count);
  for j=1:numel(r.prior_attempt_history)
    prior=r.prior_attempt_history(j);
    fprintf(fid,['- Prior attempt: %s; outcome: %s; identifier: %s; ', ...
      'elapsed seconds: %.17g; peak MiB: %.17g; last gate: %s\n'], ...
      prior.attempt,prior.producer_outcome,prior.identifier, ...
      prior.elapsed_seconds,prior.peak_active_mib,prior.last_completed_gate);
  end
  fprintf(fid,'- First unavailable condition: %s\n',r.first_failure.code);
  fprintf(fid,'- Saved candidate: %.15f\n',r.candidate);
  fprintf(fid,'- Elapsed seconds: %.6f\n- Peak active-object MiB: %.6f\n', ...
    r.elapsed_seconds,r.peak_active_mib);
  if isfield(r.estimator,'computed_q')
    fprintf(fid,'- Computed shifted residual ratio: %.17g\n',r.estimator.computed_q);
    fprintf(fid,'- Computed majorant: %.17g\n',r.estimator.computed_majorant);
    if all(isfinite(r.estimator.nominal_k_interval))
      fprintf(fid,'- Nominal k interval: [%.17g, %.17g]\n', ...
        r.estimator.nominal_k_interval);
      fprintf(fid,'- Nominal k width: %.17g\n',r.estimator.nominal_k_width);
    end
  end
  fprintf(fid,['\nThe result uses one BIE-informed conforming companion and ', ...
    'ordinary-double quadrature. It is not an outward bound, a projected-gap ', ...
    'existence proof, a unique-mode identity, or an I3.2 independent reference.\n']);
end
