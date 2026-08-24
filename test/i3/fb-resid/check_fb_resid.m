function result = check_fb_resid(attempt)
%CHECK_FB_RESID Compute the I3.1 full-boundary cell-BIE residual indicator.
% Purpose:
%   Build the frozen full-boundary finite-density trial from shared wall
%   traces and evaluate wall, circle, and value-lift residual candidates.
% Input:
%   attempt - The sole frozen tag, 'fbie-a1'.
% Output:
%   result  - Append-only diagnostics, tail rows, indicator, and costs.
% Main algorithm:
%   Recover the saved weighted state; eliminate two wall single-layer
%   densities mode by mode; solve the circle Muller Schur system; assemble
%   positive residual Grams; and contract complete matrix-power tails.
% Based on:
%   research/projects/eig-apost/implementation/i3/design-3-1f.md.
% Main changes:
%   Uses explicit full-order wall densities.  Value-only wall strips and a
%   circle collar repair the finite trial without a two-dimensional mesh.
% Numerical goal:
%   Produce an ordinary-double indicator candidate, never a certified bound.
  if nargin~=1 || ~strcmp(char(attempt),'fbie-a1')
    error('i31f:Attempt','The frozen attempt name is fbie-a1.');
  end
  here=fileparts(mfilename('fullpath'));
  output=fullfile(here,'output',char(attempt));
  if exist(output,'dir') || exist(output,'file')
    error('i31f:OutputExists','Output already exists: %s.',output);
  end
  if exist('OCTAVE_VERSION','builtin')~=0
    error('i31f:MATLABRequired','This experiment requires MATLAB.');
  end

  timer=tic; c=LOCAL_config(); result=LOCAL_empty_result(char(attempt),c);
  peak_mib=0;
  try
    % --- stage 1: frozen candidate, branch, and propagation ---
    rows=LOCAL_selectors(); eval_cfg=c; eval_cfg.kstar=eval_cfg.kseed;
    [seed,frame]=eval_i21('seed',eval_cfg,rows); LOCAL_seed_gate(seed,frame,c);
    node=eval_i21('point',c.khat,eval_cfg,frame); LOCAL_point_gate(node,frame,c);
    finite=LOCAL_finite_input(node,c); result.candidate=finite;
    inputq=LOCAL_input_qualification(seed,node); result.candidate.input=inputq;
    branch=LOCAL_branch(node,frame,c); result.branch=branch;
    prop=LOCAL_propagation(node,c); result.propagation=prop.record;
    coords=LOCAL_coordinates(node,finite.q,prop,c); result.coordinates=coords;
    closure=LOCAL_actual_closure(node,prop,coords,c);
    result.propagation.actual_state_closure=closure;
    if ~(branch.available&&prop.record.available&&coords.available&&closure.available)
      error('i31f:PropagationUnavailable', ...
        'A branch, propagation, or scattering-closure object is unavailable.');
    end
    result.nonblocking_warnings=LOCAL_finite_warnings( ...
      inputq,branch,prop,coords,closure);
    peak_mib=max(peak_mib,LOCAL_mib({seed,frame,node,finite,prop,coords}));
    LOCAL_resource_gate(timer,peak_mib,c); LOCAL_soft_gate(timer,c,'cell BIE');

    % --- stage 2: full-boundary density and exact-kernel actions ---
    cellmap=i31_full_bie(c,node,frame); result.cell_bie=cellmap.record;
    if ~cellmap.record.finite
      error('i31f:KernelUnavailable','The cell BIE returned nonfinite maps.');
    end
    result.nonblocking_warnings=[result.nonblocking_warnings, ...
      LOCAL_cell_warnings(cellmap.record,c)];
    caller_mib=LOCAL_mib({seed,frame,node,finite,prop,coords});
    peak_mib=max(peak_mib,max(caller_mib+cellmap.record.peak_local_workspace_mib, ...
      caller_mib+LOCAL_mib({cellmap})));
    LOCAL_resource_gate(timer,peak_mib,c); LOCAL_soft_gate(timer,c,'boundary Grams');

    % --- stage 3: wall, circle, value-lift, and field factors ---
    bundle=i31_bdry_est(c,node,prop,coords,finite,cellmap,timer);
    est=bundle.estimator;
    result.boundary=est.record; result.small_maps=est.audit;
    result.coverage.mathematical_full_boundary_exact_kernel_trial_defined=true;
    result.coverage.numerical_boundary_actions_computed=true;
    result.coverage.mathematical_value_lifts_defined=true;
    result.coverage.numerical_artificial_wall_jump_component_computed=true;
    result.coverage.numerical_circle_normal_jump_component_computed=true;
    result.coverage.numerical_collar_volume_component_computed=true;
    result.coverage.numerical_field_lower_component_computed=true;
    result.first_nonblocking_failure=LOCAL_first_warning( ...
      result.nonblocking_warnings,est.record.warnings);
    result.nonblocking_warnings=[result.nonblocking_warnings,est.record.warnings];
    if ~est.record.q_objects_available
      result.first_q_unavailable_condition=LOCAL_condition( ...
        'BOUNDARY_OBJECT_NUMERICALLY_UNAVAILABLE', ...
        est.record.first_unavailable_message);
      result.status='I3_1_FULL_BOUNDARY_BIE_INDICATOR_UNAVAILABLE';
      result.scientific_outcome='FULL_BOUNDARY_BIE_INDICATOR_UNAVAILABLE';
    else
      % --- stage 4: full-matrix tails and ordinary-double indicator ---
      tm=bundle.minus_tail; tp=bundle.plus_tail;
      result.tails=struct('minus',tm.record,'plus',tp.record);
      peak_mib=max(peak_mib,LOCAL_mib({seed,frame,node,finite,prop,coords, ...
        cellmap,est})+bundle.peak_active_mib);
      LOCAL_resource_gate(timer,peak_mib,c);
      if ~(tm.record.available&&tp.record.available)
        result.first_q_unavailable_condition=LOCAL_condition( ...
          'INFINITE_TAIL_NUMERICALLY_UNAVAILABLE', ...
          'A required full-matrix or state tail did not close.');
        result.status='I3_1_FULL_BOUNDARY_BIE_INDICATOR_UNAVAILABLE';
        result.scientific_outcome='FULL_BOUNDARY_BIE_INDICATOR_UNAVAILABLE';
      else
        result.coverage.ordinary_double_full_matrix_tail_candidate_computed=true;
        if ~(tm.record.qualification_pass&&tp.record.qualification_pass)
          result.nonblocking_warnings(end+1)=LOCAL_warning( ...
            'TAIL_SHARE_QUALIFICATION_WARNING', ...
            max([tm.chosen.tail_shares,tp.chosen.tail_shares]));
          result.first_nonblocking_failure=LOCAL_first_warning( ...
            result.nonblocking_warnings, ...
            struct('code',{},'value',{},'blocking',{}));
        end
        total=bundle.total;
        if isempty(result.nonblocking_warnings)
          total.qualification='UNQUALIFIED';
        else
          total.qualification='NUMERICALLY_UNQUALIFIED';
        end
        result.estimator=total;
        repeat=bundle.phase_scale;
        result.phase_scale=repeat;
        if ~repeat.pass
          result.nonblocking_warnings(end+1)=LOCAL_warning( ...
            'PHASE_SCALE_DIAGNOSTIC_FAILED',repeat.maximum_relative_defect);
          result.first_nonblocking_failure=LOCAL_first_warning( ...
            result.nonblocking_warnings, ...
            struct('code',{},'value',{},'blocking',{}));
          result.estimator.qualification='NUMERICALLY_UNQUALIFIED';
        end
        if ~total.available
          result.first_q_unavailable_condition=LOCAL_condition( ...
            'FIELD_OR_RESIDUAL_NUMERICALLY_UNAVAILABLE',total.message);
          result.status='I3_1_FULL_BOUNDARY_BIE_INDICATOR_UNAVAILABLE';
          result.scientific_outcome='FULL_BOUNDARY_BIE_INDICATOR_UNAVAILABLE';
        elseif total.q>=1
          result.status='I3_1_FULL_BOUNDARY_BIE_RESOLUTION_INSUFFICIENT';
          result.scientific_outcome='FULL_BOUNDARY_BIE_RESOLUTION_INSUFFICIENT';
        elseif isempty(result.nonblocking_warnings)
          result.estimator.qualification='INTERNALLY_QUALIFIED_I3_1';
          result.status= ...
            'I3_1_INTERNALLY_QUALIFIED_FULL_BOUNDARY_BIE_ESTIMATOR_CANDIDATE';
          result.scientific_outcome= ...
            'INTERNALLY_QUALIFIED_FULL_BOUNDARY_BIE_ESTIMATOR_CANDIDATE_I3_2_READY';
        else
          result.estimator.qualification='NUMERICALLY_UNQUALIFIED';
          result.status= ...
            'I3_1_COMPUTED_NUMERICALLY_UNQUALIFIED_FULL_BOUNDARY_BIE_INDICATOR';
          result.scientific_outcome= ...
            'COMPUTED_NUMERICALLY_UNQUALIFIED_FULL_BOUNDARY_BIE_INDICATOR';
        end
        if total.available
          result.first_q_unavailable_condition=LOCAL_condition( ...
            'NONE','The ordinary-double q candidate is available.');
        end
      end
    end
    result.execution_pass=true;
  catch ME
    result=LOCAL_execution_fail(result,ME);
  end

  result.elapsed_seconds=toc(timer); result.peak_active_mib=peak_mib;
  result.soft_time_exceeded=result.elapsed_seconds>c.soft_seconds;
  if result.elapsed_seconds>c.hard_seconds || peak_mib>c.memory_mib_max
    result.execution_pass=false; result.status='I3_1_EXECUTION_UNAVAILABLE';
    result.scientific_outcome='UNAVAILABLE';
    result.first_execution_blocker=LOCAL_condition('RESOURCE_LIMIT_EXCEEDED', ...
      'The hard time or active-object memory budget was exceeded.');
  end
  if exist(output,'dir') || exist(output,'file')
    error('i31f:OutputExists','Output appeared during the run: %s.',output);
  end
  mkdir(output); save(fullfile(output,'result.mat'),'result','-v7');
  LOCAL_report(fullfile(output,'report.md'),result);
end
%% ==================== Frozen runtime contract ====================
% Every scientific parameter and threshold is fixed in executable source.

function c=LOCAL_config()
  c=struct('schema','TEP_I3_1_FULL_BOUNDARY_CELL_BIE_RESIDUAL_V1', ...
    'beta',0.5,'d',1.0,'R',0.2,'s',1.0,'rho_disk',17, ...
    'X_L',-0.5,'X_R',0.5,'L',1.0,'H',1.1,'proxy_dist',0.2, ...
    'M',48,'K',97,'kseed',1.8327703475952146, ...
    'khat',1.832770289108157,'tau_k_pre',1e-6, ...
    'delta_c',0.04,'delta_w',0.04, ...
    'circle_density_nodes',256,'circle_action_nodes',512, ...
    'wall_order_coarse',256,'wall_order_official',512, ...
    'wall_common_nodes',1024,'delta_t_modes',(-8:8).', ...
    'radial_gauss_coarse',16,'radial_gauss',32, ...
    'riccati_steps_coarse',256,'riccati_steps',512, ...
    'pole_warning',1e-8,'bie_rcond_min',1e-8,'bie_rcond_warning',1e-8, ...
    'bie_residual_warning',1e-10,'refinement_warning',0.20, ...
    'circle_weight_change_warning',1e-8, ...
    'gram_scale',1e-12,'scale_oracle',1e8*exp(1i*pi/7), ...
    'scale_relative_warning',1e-10,'tail_share_max',1e-6, ...
    'tail_max_power',12,'soft_seconds',900,'hard_seconds',1800, ...
    'memory_mib_max',640,'qp_pair_batch',4096);
  c.mu_h=c.khat^2; c.gamma=c.mu_h;
  c.level=struct('name','fine','ntot',256,'N_side',160,'N_top',160, ...
    'N_proxy_edge',80,'M_pw',32);
  c.expected=struct('proxy_rank',260,'bie_order',512, ...
    'pencil_order',194,'graph_order',388);
  c.proxy_rank_ratio=1e-8; c.proxy_rank_gap_min=2;
  c.proxy_projector_repeat_tol=1e-10; c.proxy_rcond_min=1e-8;
  c.proxy_projected_tol=1e-11; c.proxy_full_residual_max=1e-5;
  c.proxy_shifted_residual_max=1e-5; c.proxy_seed_identity_tol=1e-12;
  c.branch_tol=1e-12; c.branch_relative_max=1e-12;
  c.qz_residual_tol=1e-10; c.qz_overlap_min=0.9;
  c.cross_cluster_margin_min=100*c.K*eps; c.chart_margin_min=100*c.K*eps;
  c.chart_condition_eps_tol=1e-9; c.small_solve_residual_tol=1e3*c.K*eps;
  c.bie_residual_tol=1e-10; c.schur_tol=1e3*c.K*eps;
  c.dirichlet_rcond_min=1e-8; c.participation_min=1e-3;
  c.lift_residual_tol=1e-10; c.action_rcond_min=1e-8;
  c.action_residual_max=1e-10; c.scattering_closure_max=1e-10;
  c.wood_distance_min=1e-6;
  c.command="matlab -batch ""addpath(fullfile(pwd,'test','i3','fb-resid'),"+ ...
    "fullfile(pwd,'test','i2','k-count')); check_fb_resid('fbie-a1');""";
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
  ok=seed.k==c.kseed&& ...
    isequal(size(seed.Aqp),[512,512])&&isequal(size(seed.AdefD),[194,194])&& ...
    isequal(size(frame.Z0_plus),[194,97])&& ...
    isequal(size(frame.Z0_minus),[194,97])&&frame.proxy_chart.r==260&& ...
    all(isfinite(seed.Aqp),'all')&&all(isfinite(seed.AdefD),'all');
  if ~ok, error('i31f:FiniteInput','The frozen seed/frame gate failed.'); end
end
function LOCAL_point_gate(node,frame,c)
  ok=node.k==c.khat&&strcmp(node.name,'fine')&&node.spec.ntot==256&& ...
    isequal(node.H_plus_rows,frame.rows_plus)&& ...
    isequal(node.H_minus_rows,frame.rows_minus)&& ...
    isequal(size(node.AdefD),[194,194])&&isequal(size(node.AdefG),[388,388])&& ...
    all(isfinite(node.beta_m))&&all(isfinite(node.gamma))&& ...
    all(isfinite(node.AdefD),'all')&&all(isfinite(node.AdefG),'all');
  if ~ok, error('i31f:FiniteInput','The saved-candidate gate failed.'); end
end
function out=LOCAL_input_qualification(seed,node)
  values=[seed.pass,node.pass,node.plus.pass,node.minus.pass,node.cp.safe, ...
    node.cm.safe,all([seed.factors.pass]),all([node.factors.pass])];
  out=struct('checks',logical(values),'pass',all(values));
end
function out=LOCAL_finite_input(node,c)
  b=sqrt(1+abs(node.beta_m(:)).^2);
  wr=repmat(sqrt(1./b),2,1);
  wc=repmat(1./sqrt(b+abs(node.gamma(:)).^2./b),2,1);
  A=wr.*node.AdefD.*wc.'; [~,S,V]=svd(A,'econ'); sv=diag(S);
  qraw=wc.*V(:,end);
  if any(~isfinite(qraw)) || norm(qraw)==0
    error('i31f:FiniteInput','The physical near-null vector is unavailable.');
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
    'available',port.available&&proxy.available&&isfinite(wood)&& ...
    all(isfinite(audits)),'wood_distance',wood,'port',port,'proxy',proxy, ...
    'algebra_roundtrip_defects',audits);
end
function out=LOCAL_branch_list(beta,gamma,c)
  t=c.khat^2-beta.^2; s=max([ones(size(beta)),abs(c.khat)*ones(size(beta)), ...
    abs(beta)],[],2); ref=complex(zeros(size(beta)));
  prop=t>0; evan=t<0; ref(prop)=sqrt(t(prop)); ref(evan)=1i*sqrt(-t(evan));
  rel=abs(gamma-ref)./s;
  signpass=(~prop|real(gamma)>0)&(~evan|imag(gamma)>0);
  axispass=(~prop|abs(imag(gamma))./s<=c.branch_relative_max)& ...
    (~evan|abs(real(gamma))./s<=c.branch_relative_max);
  class=repmat("UNRESOLVED",numel(beta),1);
  class(prop)="PROPAGATING"; class(evan)="EVANESCENT";
  available=all(isfinite([beta;gamma;t;s;ref;rel]))&&all(prop|evan);
  out=struct('available',available,'pass',available&&all(signpass)&&all(axispass)&& ...
    all(rel<=c.branch_relative_max),'beta_m',beta,'gamma_m',gamma, ...
    't_m',t,'classification',class,'outgoing_reference',ref, ...
    'outgoing_relative_defects',rel,'outgoing_sign_pass',signpass, ...
    'axis_pass',axispass);
end
%% ==================== Whole-subspace propagation ====================
% Full matrix actions retain nonnormal and Jordan coupling.

function out=LOCAL_propagation(node,c)
  plus=LOCAL_action(node.pair.A,node.pair.B,node.Zp,false,c);
  minus=LOCAL_action(node.pair.A,node.pair.B,node.Zm,true,c);
  K=c.K; Ap=node.Zp(1:K,:); Bp=node.Zp(K+1:end,:);
  Am=node.Zm(1:K,:); Bm=node.Zm(K+1:end,:);
  b=node.blocks; Pp=plus.P; Pm=minus.P;
  residuals={Bp-b.R_L*Ap-b.T_RL*Bp*Pp, ...
    Ap*Pp-b.T_LR*Ap-b.R_R*Bp*Pp, ...
    Bm*Pm-b.R_L*Am*Pm-b.T_RL*Bm, ...
    Am-b.T_LR*Am*Pm-b.R_R*Bm};
  refs={Bp,Ap*Pp,Bm*Pm,Am}; defects=zeros(1,4);
  for j=1:4
    defects(j)=norm(residuals{j},'fro')/max(1,norm(refs{j},'fro'));
  end
  out=struct('Pplus',Pp,'Pminus',Pm,'Ap',Ap,'Bp',Bp,'Am',Am,'Bm',Bm, ...
    'Dplus',Ap+Bp,'Dminus',Am+Bm,'record',struct( ...
    'available',plus.available&&minus.available&&all(isfinite(defects)), ...
    'pass',plus.pass&&minus.pass&&max(defects)<=c.scattering_closure_max, ...
    'plus',LOCAL_drop(plus,{'P'}),'minus',LOCAL_drop(minus,{'P'}), ...
    'unit_scattering_closure_defects',defects));
end
function out=LOCAL_action(A,B,Z,reversed,c)
  if reversed, C=A*Z; rhs=B*Z; else, C=B*Z; rhs=A*Z; end
  [~,R]=qr(C,0); rk=rank(R); rc=rcond(R);
  try, P=C\rhs; catch ME
    error('i31f:PropagationUnavailable','A propagation solve failed: %s',ME.message);
  end
  solve=norm(C*P-rhs,'fro')/max([1,norm(C,'fro')*norm(P,2)+norm(rhs,'fro')]);
  if reversed
    defect=norm(B*Z-A*Z*P,'fro')/max([1,norm(B*Z,'fro')+ ...
      norm(A*Z,'fro')*norm(P,2)]);
  else
    defect=norm(A*Z-B*Z*P,'fro')/max([1,norm(A*Z,'fro')+ ...
      norm(B*Z,'fro')*norm(P,2)]);
  end
  finite=all(isfinite(P),'all')&&all(isfinite([rc,solve,defect]));
  out=struct('P',P,'available',finite,'rank',rk,'thin_qr_rcond',rc, ...
    'solve_residual',solve,'invariant_residual',defect,'pass',finite&& ...
    rk==c.K&&rc>=c.action_rcond_min&& ...
    max(solve,defect)<=c.action_residual_max);
end
function out=LOCAL_coordinates(node,q,prop,c)
  I=eye(c.K); E=diag(node.phase(:));
  try
    cm=node.Dm\([I,E]*q); cp=node.Dp\([E,I]*q);
  catch ME
    error('i31f:PropagationUnavailable','A coordinate solve failed: %s',ME.message);
  end
  rm=norm(node.Dm*cm-[I,E]*q)/max(1,norm([I,E]*q));
  rp=norm(node.Dp*cp-[E,I]*q)/max(1,norm([E,I]*q));
  if any(~isfinite([cm;cp])) || any(~isfinite([rm,rp]))
    error('i31f:PropagationUnavailable','A coordinate solve is unavailable.');
  end
  out=struct('q',q,'cminus',cm,'cplus',cp, ...
    'available',true,'qualification_pass',max(rm,rp)<=c.action_residual_max, ...
    'minus_solve_residual',rm,'plus_solve_residual',rp);
end
function out=LOCAL_actual_closure(node,prop,coords,c)
  b=node.blocks; Pp=prop.Pplus; Pm=prop.Pminus;
  rp={prop.Bp-b.R_L*prop.Ap-b.T_RL*prop.Bp*Pp, ...
    prop.Ap*Pp-b.T_LR*prop.Ap-b.R_R*prop.Bp*Pp};
  rm={prop.Bm*Pm-b.R_L*prop.Am*Pm-b.T_RL*prop.Bm, ...
    prop.Am-b.T_LR*prop.Am*Pm-b.R_R*prop.Bm};
  sp={prop.Bp,prop.Ap*Pp}; sm={prop.Bm*Pm,prop.Am}; defects=zeros(1,8); p=0;
  statesp={coords.cplus,Pp*coords.cplus}; statesm={coords.cminus,Pm*coords.cminus};
  for j=1:2
    for k=1:2
      p=p+1; defects(p)=norm(rp{j}*statesp{k})/max(1,norm(sp{j}*statesp{k}));
    end
  end
  for j=1:2
    for k=1:2
      p=p+1; defects(p)=norm(rm{j}*statesm{k})/max(1,norm(sm{j}*statesm{k}));
    end
  end
  out=struct('available',all(isfinite(defects)),'defects',defects, ...
    'pass',all(isfinite(defects))&& ...
    max(defects)<=c.scattering_closure_max);
end
%% ==================== Warnings and result semantics ====================
% Numerical warnings do not suppress a finite q or its unqualified transform.

function warnings=LOCAL_cell_warnings(record,c)
  warnings=struct('code',{},'value',{},'blocking',{});
  proxy=record.proxy_chart_solve;
  if proxy.reduced_rcond<c.proxy_rcond_min
    warnings(end+1)=LOCAL_warning('PROXY_CHART_RCOND_WARNING', ...
      proxy.reduced_rcond);
  end
  proxy_residual=max(proxy.projected_residual,proxy.full_residual);
  if proxy.projected_residual>c.proxy_projected_tol || ...
      proxy.full_residual>c.proxy_full_residual_max
    warnings(end+1)=LOCAL_warning('PROXY_CHART_RESIDUAL_WARNING', ...
      proxy_residual);
  end
  solve=max([record.coarse.maximum_rhs_relative_residual, ...
    record.coarse.maximum_rhs_backward_error, ...
    record.official.maximum_rhs_relative_residual, ...
    record.official.maximum_rhs_backward_error]);
  if ~record.coarse.qualification_pass || ~record.official.qualification_pass
    warnings(end+1)=LOCAL_warning('FULL_BOUNDARY_SOLVE_WARNING',solve);
  end
  changes=[record.fixed_density_action_change, ...
    record.resolved_source_change,record.circle_action_change, ...
    record.circle_angular_tail_change,record.common_wall_value_defect];
  names={'WALL_FIXED_DENSITY_ACTION_WARNING', ...
    'WALL_RESOLVED_SOURCE_WARNING','CIRCLE_ACTION_WARNING', ...
    'CIRCLE_ANGULAR_TAIL_WARNING','RAW_COMMON_WALL_VALUE_WARNING'};
  for j=1:numel(changes)
    if ~isfinite(changes(j)) || changes(j)>c.refinement_warning
      warnings(end+1)=LOCAL_warning(names{j},changes(j));
    end
  end
  dt=max([record.actual_delta_t.maximum_normalized_defect, ...
    record.actual_delta_t.maximum_reference_change]);
  if ~record.actual_delta_t.available || dt>c.refinement_warning
    warnings(end+1)=LOCAL_warning('ACTUAL_DELTA_T_ORACLE_WARNING',dt);
  end
  structure=max([record.common_wall_gauge_defect, ...
    record.scaled_physical_roundtrip, ...
    record.zeta_minus_sigma_roundtrip_defect, ...
    record.bloch_kernel_oracle.value_defect, ...
    record.bloch_kernel_oracle.global_y_derivative_defect, ...
    record.wall_modal_oracle.maximum_value_inverse_defect, ...
    record.wall_modal_oracle.maximum_flux_sign_defect, ...
    record.manufactured.maximum_minus_S_jump_defect]);
  if ~record.bloch_kernel_oracle.available || ~isfinite(structure) || ...
      structure>c.scale_relative_warning
    warnings(end+1)=LOCAL_warning('BOUNDARY_STRUCTURE_WARNING',structure);
  end
  if ~record.manufactured.available || ...
      ~isfinite(record.manufactured.maximum_relative_error) || ...
      record.manufactured.maximum_relative_error>c.refinement_warning
    warnings(end+1)=LOCAL_warning('ONE_SIDED_KERNEL_ORACLE_WARNING', ...
      record.manufactured.maximum_relative_error);
  end
  if ~record.cross_action.available || ...
      ~isfinite(record.cross_action.refinement_change) || ...
      record.cross_action.refinement_change>c.refinement_warning
    warnings(end+1)=LOCAL_warning('CROSS_ACTION_REFINEMENT_WARNING', ...
      record.cross_action.refinement_change);
  end
end

function warnings=LOCAL_finite_warnings(inputq,branch,prop,coords,closure)
  warnings=struct('code',{},'value',{},'blocking',{});
  if ~inputq.pass
    warnings(end+1)=LOCAL_warning('FROZEN_INPUT_QUALIFICATION_WARNING', ...
      sum(~inputq.checks));
  end
  if ~branch.pass
    warnings(end+1)=LOCAL_warning('BRANCH_OR_WOOD_QUALIFICATION_WARNING', ...
      branch.wood_distance);
  end
  if ~prop.record.pass
    value=max([prop.record.plus.solve_residual, ...
      prop.record.plus.invariant_residual,prop.record.minus.solve_residual, ...
      prop.record.minus.invariant_residual, ...
      prop.record.unit_scattering_closure_defects]);
    warnings(end+1)=LOCAL_warning('PROPAGATION_QUALIFICATION_WARNING',value);
  end
  if ~coords.qualification_pass
    warnings(end+1)=LOCAL_warning('COORDINATE_SOLVE_QUALIFICATION_WARNING', ...
      max(coords.minus_solve_residual,coords.plus_solve_residual));
  end
  if ~closure.pass
    warnings(end+1)=LOCAL_warning('ACTUAL_CLOSURE_QUALIFICATION_WARNING', ...
      max(closure.defects));
  end
end
function out=LOCAL_warning(code,value)
  out=struct('code',code,'value',value,'blocking',false);
end
function out=LOCAL_first_warning(a,b)
  all=[a,b];
  if isempty(all), out=LOCAL_condition('NONE','No nonblocking warning was recorded.');
  else, out=LOCAL_condition(all(1).code,sprintf('Recorded value %.17g.',all(1).value)); end
end
function out=LOCAL_condition(code,message)
  out=struct('code',code,'message',message);
end
function result=LOCAL_empty_result(attempt,c)
  prior=struct('attempt',{},'shell_exit_code',{},'producer_outcome',{}, ...
    'identifier',{},'message',{},'elapsed_seconds',{}, ...
    'peak_active_mib',{},'scientific_stage_entered',{}, ...
    'last_completed_gate',{},'output_created',{},'artifact_names',{}, ...
    'artifact_sha256',{});
  result=struct('schema',c.schema,'attempt',attempt,'retry_count',0, ...
    'prior_failed_attempt_count',0,'prior_attempt_history',prior, ...
    'command',c.command,'config',c, ...
    'status','I3_1_EXECUTION_UNAVAILABLE','scientific_outcome','UNAVAILABLE', ...
    'execution_pass',false,'candidate',struct(),'branch',struct(), ...
    'propagation',struct(),'coordinates',struct(),'cell_bie',struct(), ...
    'boundary',struct(),'small_maps',struct(),'tails',struct(), ...
    'phase_scale',struct(),'estimator',struct(), ...
    'nonblocking_warnings',struct('code',{},'value',{},'blocking',{}), ...
    'first_nonblocking_failure',LOCAL_condition('NOT_REACHED','Not reached.'), ...
    'first_q_unavailable_condition',LOCAL_condition('NOT_REACHED','Not reached.'), ...
    'first_execution_blocker',LOCAL_condition('NONE','No execution blocker.'), ...
    'coverage',struct('mathematical_full_boundary_exact_kernel_trial_defined',false, ...
    'numerical_boundary_actions_computed',false, ...
    'mathematical_value_lifts_defined',false, ...
    'numerical_artificial_wall_jump_component_computed',false, ...
    'numerical_circle_normal_jump_component_computed',false, ...
    'numerical_collar_volume_component_computed',false, ...
    'numerical_field_lower_component_computed',false, ...
    'ordinary_double_full_matrix_tail_candidate_computed',false, ...
    'continuous_H1_numerically_enclosed',false, ...
    'continuous_jump_enclosed',false,'projected_gap',false), ...
    'reliability',struct('outward_residual_upper',false, ...
    'outward_field_lower',false,'certified_tail',false, ...
    'outward_wall_tail',false,'outward_circle_tail',false, ...
    'certified_projected_gap',false,'independent_reference',false, ...
    'reliable_spectral_interval',false, ...
    'continuous_eigenvalue_exists',false), ...
    'elapsed_seconds',NaN,'peak_active_mib',NaN,'soft_time_exceeded',false);
end

function result=LOCAL_execution_fail(result,ME)
  result.execution_pass=false; result.status='I3_1_EXECUTION_UNAVAILABLE';
  result.scientific_outcome='UNAVAILABLE';
  result.first_execution_blocker=LOCAL_condition(ME.identifier,ME.message);
end
%% ==================== Resource and report helpers ====================
% These helpers enforce the frozen budget and write a compact text artifact.

function LOCAL_soft_gate(timer,c,next_stage)
  if toc(timer)>c.soft_seconds
    error('i31f:SoftTime','The soft limit forbids starting %s.',next_stage);
  end
end

function LOCAL_resource_gate(timer,peak,c)
  if toc(timer)>c.hard_seconds || peak>c.memory_mib_max
    error('i31f:Resource','The hard time or memory limit was exceeded.');
  end
end

function value=LOCAL_mib(items)
  value=0;
  for j=1:numel(items)
    x=items{j}; info=whos('x'); value=value+info.bytes/2^20;
  end
end

function out=LOCAL_drop(in,names)
  out=in;
  for j=1:numel(names), if isfield(out,names{j}), out=rmfield(out,names{j}); end, end
end

function LOCAL_report(path,result)
  fid=fopen(path,'w');
  if fid<0, error('i31f:Report','Could not create the report.'); end
  cleaner=onCleanup(@() fclose(fid));
  fprintf(fid,'# I3.1 full-boundary cell-BIE residual: `%s`\n\n',result.attempt);
  fprintf(fid,'- Status: `%s`\n',result.status);
  fprintf(fid,'- Scientific outcome: `%s`\n',result.scientific_outcome);
  fprintf(fid,'- Attempt-local retry count: `%d`\n',result.retry_count);
  fprintf(fid,'- Prior failed attempt count: `%d`\n', ...
    result.prior_failed_attempt_count);
  for j=1:numel(result.prior_attempt_history)
    p=result.prior_attempt_history(j);
    fprintf(fid,['- Prior attempt: `%s`; outcome: `%s`; identifier: `%s`; ', ...
      'elapsed seconds: `%.17g`; peak MiB: `%.17g`; last gate: `%s`\n'], ...
      p.attempt,p.producer_outcome,p.identifier,p.elapsed_seconds, ...
      p.peak_active_mib,p.last_completed_gate);
  end
  fprintf(fid,'- Elapsed seconds: `%.17g`\n',result.elapsed_seconds);
  fprintf(fid,'- Peak active-object MiB: `%.17g`\n',result.peak_active_mib);
  fprintf(fid,'- First execution blocker: `%s`\n', ...
    result.first_execution_blocker.code);
  fprintf(fid,'- First q-unavailable condition: `%s`\n', ...
    result.first_q_unavailable_condition.code);
  fprintf(fid,'- First nonblocking warning: `%s`\n', ...
    result.first_nonblocking_failure.code);
  fprintf(fid,'- Cell BIE right-hand sides: `shared total traces Gminus/Gplus`\n');
  fprintf(fid,'- M=48 role: `input wall traces only`\n');
  fprintf(fid,'- Full wall response orders: `256/512`; common grid: `1024`\n');
  fprintf(fid,'- Incoming/outgoing decomposition: `diagnostic only`\n');
  fprintf(fid,'- 512-point traces enclose the continuous jump: `false`\n');
  fprintf(fid,'- Continuous H1 companion numerically enclosed: `false`\n');
  if isfield(result.cell_bie,'actual_delta_t')
    fprintf(fid,'- Actual Delta-T maximum normalized defect: `%.17g`\n', ...
      result.cell_bie.actual_delta_t.maximum_normalized_defect);
    fprintf(fid,'- Wall fixed-action change: `%.17g`\n', ...
      result.cell_bie.fixed_density_action_change);
    fprintf(fid,'- Wall re-solved-source change: `%.17g`\n', ...
      result.cell_bie.resolved_source_change);
    fprintf(fid,'- Circle angular-tail change: `%.17g`\n', ...
      result.cell_bie.circle_angular_tail_change);
  end
  if isfield(result.propagation,'actual_state_closure')
    fprintf(fid,'- Maximum actual-state closure defect: `%.17g`\n', ...
      max(result.propagation.actual_state_closure.defects));
  end
  if isstruct(result.estimator)&&isfield(result.estimator,'q')
    fprintf(fid,'- Wall residual component: `%.17g`\n', ...
      result.estimator.wall_component);
    fprintf(fid,'- Circle residual component: `%.17g`\n', ...
      result.estimator.circle_component);
    fprintf(fid,'- Collar volume component: `%.17g`\n', ...
      result.estimator.collar_volume_component);
    fprintf(fid,'- Field lower candidate: `%.17g`\n', ...
      result.estimator.field_lower);
    fprintf(fid,'- q: `%.17g`\n',result.estimator.q);
    fprintf(fid,'- Nominal k interval: `[%.17g, %.17g]`\n', ...
      result.estimator.nominal_k_interval);
    fprintf(fid,'- Qualification: `%s`\n',result.estimator.qualification);
    fprintf(fid,'- Preregistered width pass: `%d`\n', ...
      result.estimator.resolution_pass);
  end
  names=fieldnames(result.reliability);
  fprintf(fid,'\n## Nonblocking warnings\n\n');
  for j=1:numel(result.nonblocking_warnings)
    w=result.nonblocking_warnings(j);
    fprintf(fid,'- `%s`: `%.17g`\n',w.code,w.value);
  end
  fprintf(fid,'\n## Reliability flags\n\n');
  for j=1:numel(names)
    fprintf(fid,'- `%s`: `%d`\n',names{j},result.reliability.(names{j}));
  end
  fprintf(fid,['\nAll numerical intervals are ordinary-double and are not ', ...
    'reliable or certified spectral intervals.\n']);
  clear cleaner;
end
