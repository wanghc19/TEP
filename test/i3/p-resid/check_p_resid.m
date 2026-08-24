function result = check_p_resid(attempt)
%CHECK_P_RESID Compute the I3.1 pure-BIE boundary residual indicator.
% Purpose:
%   Build the frozen finite-density exact-kernel trial from shared wall
%   traces and evaluate wall, circle, and collar residual candidates.
% Input:
%   attempt - The sole frozen tag, 'pbie-a2'.
% Output:
%   result  - Append-only diagnostics, tail rows, indicator, and costs.
% Main algorithm:
%   Recover the saved weighted candidate state; form full propagation
%   matrices; solve one rectangular Dirichlet-Green Muller map; assemble
%   positive-factor boundary Grams; and contract complete matrix-power
%   tails without diagonalizing the propagation matrices.
% Based on:
%   research/projects/eig-apost/implementation/i3/design-3-1e.md.
% Main changes:
%   Uses no Q1, RT0, or two-dimensional volume mesh.  A radial collar fixes
%   only the circle value jump; its volume source is integrated by radius.
% Numerical goal:
%   Produce an ordinary-double indicator candidate, never a certified bound.
  if nargin~=1 || ~strcmp(char(attempt),'pbie-a2')
    error('i31p:Attempt','The frozen attempt name is pbie-a2.');
  end
  here=fileparts(mfilename('fullpath'));
  output=fullfile(here,'output',char(attempt));
  if exist(output,'dir') || exist(output,'file')
    error('i31p:OutputExists','Output already exists: %s.',output);
  end
  if exist('OCTAVE_VERSION','builtin')~=0
    error('i31p:MATLABRequired','This experiment requires MATLAB.');
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
      error('i31p:PropagationUnavailable', ...
        'A branch, propagation, or scattering-closure object is unavailable.');
    end
    result.nonblocking_warnings=LOCAL_finite_warnings( ...
      inputq,branch,prop,coords,closure);
    peak_mib=max(peak_mib,LOCAL_mib({seed,frame,node,finite,prop,coords}));
    LOCAL_resource_gate(timer,peak_mib,c); LOCAL_soft_gate(timer,c,'cell BIE');

    % --- stage 2: finite density and exact-kernel boundary actions ---
    cellmap=i31_cell_bie(c,node,frame,prop); result.cell_bie=cellmap.record;
    if ~cellmap.record.finite
      error('i31p:KernelUnavailable','The cell BIE returned nonfinite maps.');
    end
    result.nonblocking_warnings=[result.nonblocking_warnings, ...
      LOCAL_cell_warnings(cellmap.record,c)];
    caller_mib=LOCAL_mib({seed,frame,node,finite,prop,coords});
    peak_mib=max(peak_mib,max(caller_mib+cellmap.record.peak_local_workspace_mib, ...
      caller_mib+LOCAL_mib({cellmap})));
    LOCAL_resource_gate(timer,peak_mib,c); LOCAL_soft_gate(timer,c,'boundary Grams');

    % --- stage 3: wall, circle, collar, and field factors ---
    est=LOCAL_boundary_estimator(c,node,prop,coords,finite,cellmap);
    result.boundary=est.record; result.small_maps=est.audit;
    result.coverage.mathematical_finite_density_exact_kernel_trial_defined=true;
    result.coverage.numerical_512_trace_approximation_computed=true;
    result.coverage.mathematical_circle_value_collar_defined=true;
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
      result.status='I3_1_PURE_BIE_INDICATOR_UNAVAILABLE';
      result.scientific_outcome='PURE_BIE_INDICATOR_UNAVAILABLE';
    else
      LOCAL_soft_gate(timer,c,'full-P infinite tails');

      % --- stage 4: full-matrix tails and ordinary-double indicator ---
      tm=LOCAL_tail(prop.Pminus,est.minus,coords.cminus,c,'minus');
      tp=LOCAL_tail(prop.Pplus,est.plus,coords.cplus,c,'plus');
      result.tails=struct('minus',tm.record,'plus',tp.record);
      peak_mib=max(peak_mib,LOCAL_mib({seed,frame,node,finite,prop,coords, ...
        cellmap,est})+max(tm.active_mib,tp.active_mib));
      LOCAL_resource_gate(timer,peak_mib,c);
      if ~(tm.record.available&&tp.record.available)
        result.first_q_unavailable_condition=LOCAL_condition( ...
          'INFINITE_TAIL_NUMERICALLY_UNAVAILABLE', ...
          'A required full-matrix or state tail did not close.');
        result.status='I3_1_PURE_BIE_INDICATOR_UNAVAILABLE';
        result.scientific_outcome='PURE_BIE_INDICATOR_UNAVAILABLE';
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
        total=LOCAL_total(c,est,tm,tp,1);
        if isempty(result.nonblocking_warnings)
          total.qualification='UNQUALIFIED';
        else
          total.qualification='NUMERICALLY_UNQUALIFIED';
        end
        result.estimator=total;
        repeat=LOCAL_scale_repeat(c,coords,est,prop,total);
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
          result.status='I3_1_PURE_BIE_INDICATOR_UNAVAILABLE';
          result.scientific_outcome='PURE_BIE_INDICATOR_UNAVAILABLE';
        elseif total.q>=1 || total.nominal_k_width>c.tau_k_pre
          result.status='I3_1_PURE_BIE_RESOLUTION_INSUFFICIENT';
          result.scientific_outcome='PURE_BIE_RESOLUTION_INSUFFICIENT';
        else
          result.status='I3_1_COMPUTED_PURE_BIE_CONTINUOUS_RESIDUAL_INDICATOR_CANDIDATE';
          result.scientific_outcome= ...
            'COMPUTED_PURE_BIE_CONTINUOUS_RESIDUAL_INDICATOR_CANDIDATE';
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
    error('i31p:OutputExists','Output appeared during the run: %s.',output);
  end
  mkdir(output); save(fullfile(output,'result.mat'),'result','-v7');
  LOCAL_report(fullfile(output,'report.md'),result);
end
%% ==================== Frozen runtime contract ====================
% Every scientific parameter and threshold is fixed in executable source.

function c=LOCAL_config()
  c=struct('schema','TEP_I3_1_PURE_BIE_BOUNDARY_RESIDUAL_V1_REV_A', ...
    'beta',0.5,'d',1.0,'R',0.2,'s',1.0,'rho_disk',17, ...
    'X_L',-0.5,'X_R',0.5,'L',1.0,'H',1.1,'proxy_dist',0.2, ...
    'M',48,'K',97,'kseed',1.8327703475952146, ...
    'khat',1.832770289108157,'tau_k_pre',1e-6,'delta_c',0.04, ...
    'density_nodes',256,'circle_nodes',512, ...
    'green_order_coarse',48,'green_order_official',64, ...
    'wall_samples_coarse',256,'wall_samples',512, ...
    'radial_gauss_coarse',16,'radial_gauss',32, ...
    'riccati_steps_coarse',256,'riccati_steps',512, ...
    'pole_warning',1e-8,'bie_rcond_min',1e-8,'bie_rcond_warning',1e-8, ...
    'bie_residual_warning',1e-10,'refinement_warning',0.20, ...
    'circle_weight_change_warning',1e-8, ...
    'gram_scale',1e-12,'scale_oracle',1e8*exp(1i*pi/7), ...
    'scale_relative_warning',1e-10,'tail_share_max',1e-6, ...
    'tail_max_power',12,'soft_seconds',900,'hard_seconds',1800, ...
    'memory_mib_max',512,'qp_pair_batch',4096);
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
  c.command="matlab -batch ""addpath(fullfile(pwd,'test','i3','p-resid'),"+ ...
    "fullfile(pwd,'test','i2','k-count')); check_p_resid('pbie-a2');""";
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
  if ~ok, error('i31p:FiniteInput','The frozen seed/frame gate failed.'); end
end
function LOCAL_point_gate(node,frame,c)
  ok=node.k==c.khat&&strcmp(node.name,'fine')&&node.spec.ntot==256&& ...
    isequal(node.H_plus_rows,frame.rows_plus)&& ...
    isequal(node.H_minus_rows,frame.rows_minus)&& ...
    isequal(size(node.AdefD),[194,194])&&isequal(size(node.AdefG),[388,388])&& ...
    all(isfinite(node.beta_m))&&all(isfinite(node.gamma))&& ...
    all(isfinite(node.AdefD),'all')&&all(isfinite(node.AdefG),'all');
  if ~ok, error('i31p:FiniteInput','The saved-candidate gate failed.'); end
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
    error('i31p:FiniteInput','The physical near-null vector is unavailable.');
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
    error('i31p:PropagationUnavailable','A propagation solve failed: %s',ME.message);
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
    error('i31p:PropagationUnavailable','A coordinate solve failed: %s',ME.message);
  end
  rm=norm(node.Dm*cm-[I,E]*q)/max(1,norm([I,E]*q));
  rp=norm(node.Dp*cp-[E,I]*q)/max(1,norm([E,I]*q));
  if any(~isfinite([cm;cp])) || any(~isfinite([rm,rp]))
    error('i31p:PropagationUnavailable','A coordinate solve is unavailable.');
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
%% ==================== Boundary factors ====================
% These helpers assemble every squared quantity as F'*F.

function out=LOCAL_boundary_estimator(c,node,prop,coords,finite,cellmap)
  Gp=[prop.Dplus;prop.Dplus*prop.Pplus];
  Gm=[prop.Dminus*prop.Pminus;prop.Dminus];
  delta=cellmap.circle_residual(1:c.circle_nodes,:);
  jump=cellmap.circle_residual(c.circle_nodes+1:end,:);
  delta_p=delta*Gp; delta_m=delta*Gm;
  jump_p=jump*Gp; jump_m=jump*Gm;

  [wall_orders,Wfft]=LOCAL_wall_transform(c,cellmap.wall_y);
  QL=-Wfft*cellmap.dx_left_unit; QR=Wfft*cellmap.dx_right_unit;
  QLp=QL*Gp; QRp=QR*Gp; QLm=QL*Gm; QRm=QR*Gm;
  Jp=QRp+QLp*prop.Pplus; Jm=QLm+QRm*prop.Pminus;
  center=LOCAL_center_jumps(c,node,prop,coords,Wfft,cellmap);
  beta_all=c.beta+2*pi*wall_orders/c.d;
  kappa=sqrt(beta_all.^2+c.gamma);
  bwall=2*kappa.*tanh(kappa/2);
  wall_available=all(isfinite(bwall))&&all(bwall>0);
  retained=abs(wall_orders)<=c.M; bret=bwall(retained);
  center.wall_residual_squared=sum(abs(center.left_coefficients).^2./bwall)+ ...
    sum(abs(center.right_coefficients).^2./bwall);
  center.field_squared=sum(bret.*abs(prop.Dplus*coords.cplus).^2)+ ...
    sum(bret.*abs(prop.Dminus*coords.cminus).^2);
  Fwp=bsxfun(@times,Jp,1./sqrt(bwall));
  Fwm=bsxfun(@times,Jm,1./sqrt(bwall));
  Ffp=bsxfun(@times,prop.Dplus*prop.Pplus,sqrt(bret));
  Ffm=bsxfun(@times,prop.Dminus*prop.Pminus,sqrt(bret));

  [ell,Cfft]=LOCAL_circle_transform(c);
  Dc_p=Cfft*delta_p; Dc_m=Cfft*delta_m;
  Jc_p=Cfft*jump_p; Jc_m=Cfft*jump_m;
  circle=LOCAL_circle_weights(c,ell);
  collar0=LOCAL_collar_weights(c,ell,c.radial_gauss_coarse);
  collar1=LOCAL_collar_weights(c,ell,c.radial_gauss);
  collar_change=max(abs(collar1-collar0)./max([ones(size(collar1)), ...
    abs(collar1),abs(collar0)],[],2));
  available=wall_available&&circle.available&&all(isfinite(collar1))&& ...
    all(collar1>=0);
  if available
    Fcp=bsxfun(@times,Jc_p,1./sqrt(circle.weight));
    Fcm=bsxfun(@times,Jc_m,1./sqrt(circle.weight));
    Fvp=bsxfun(@times,Dc_p,sqrt(collar1/c.gamma));
    Fvm=bsxfun(@times,Dc_m,sqrt(collar1/c.gamma));
  else
    Fcp=[]; Fcm=[]; Fvp=[]; Fvm=[];
  end

  plus=LOCAL_factor_grams(Fwp,Fcp,Fvp,Ffp,c);
  minus=LOCAL_factor_grams(Fwm,Fcm,Fvm,Ffm,c);
  available=available&&plus.available&&minus.available;
  outside=abs(ell)>c.M;
  circle_energy=LOCAL_outside_energy([Dc_p,Dc_m,Jc_p,Jc_m],outside);
  warnings=struct('code',{},'value',{},'blocking',{});
  if circle.relative_change>c.circle_weight_change_warning
    warnings(end+1)=LOCAL_warning('CIRCLE_WEIGHT_REFINEMENT_WARNING', ...
      circle.relative_change);
  end
  if ~isfinite(circle.record.low_order_bessel_relative_defect) || ...
      circle.record.low_order_bessel_relative_defect>c.refinement_warning
    warnings(end+1)=LOCAL_warning('CIRCLE_BESSEL_ORACLE_WARNING', ...
      circle.record.low_order_bessel_relative_defect);
  end
  energy_defect=max(circle.record.discrete_energy_identity_defect);
  if ~isfinite(energy_defect) || energy_defect>c.refinement_warning
    warnings(end+1)=LOCAL_warning('CIRCLE_ENERGY_IDENTITY_WARNING',energy_defect);
  end
  if collar_change>c.refinement_warning
    warnings(end+1)=LOCAL_warning('COLLAR_QUADRATURE_WARNING',collar_change);
  end
  if circle_energy>c.refinement_warning
    warnings(end+1)=LOCAL_warning('CIRCLE_OUTSIDE_RETAINED_BAND_WARNING',circle_energy);
  end
  first='';
  if ~wall_available, first='A wall trace weight is nonfinite or nonpositive.';
  elseif ~circle.available, first='Circle trace weights are nonfinite or nonpositive.';
  elseif ~plus.available||~minus.available, first='A positive-factor Gram is invalid.';
  elseif any(~isfinite(collar1))||any(collar1<0), first='A collar weight is invalid.'; end
  record=struct('q_objects_available',available, ...
    'first_unavailable_message',first,'circle_weights',circle.record, ...
    'collar_16_to_32_relative_change',collar_change, ...
    'circle_outside_retained_band_share',circle_energy, ...
    'plus_grams',plus.record,'minus_grams',minus.record,'warnings',warnings, ...
    'wall_orders',wall_orders,'circle_orders',ell, ...
    'normal_orientation','global +r on the circle; cell outward on walls', ...
    'numerical_512_value_jump_frobenius_norms', ...
    [norm(delta_p,'fro'),norm(delta_m,'fro')], ...
    'numerical_512_normal_jump_frobenius_norms', ...
    [norm(jump_p,'fro'),norm(jump_m,'fro')], ...
    'mathematical_circle_value_collar_definition_used',true, ...
    'numerical_circle_continuity_enclosed',false, ...
    'safe_rim_value_and_radial_derivative_zero_by_formula',true, ...
    'wall_total_trace_shared_by_GD_zero_identity',true, ...
    'wall_quasiperiodic_basis_used',true, ...
    'triangle_sum_required',true,'reliability_certified',false);
  audit=struct('Pplus',prop.Pplus,'Pminus',prop.Pminus, ...
    'Ap',prop.Ap,'Bp',prop.Bp,'Am',prop.Am,'Bm',prop.Bm, ...
    'Dplus',prop.Dplus,'Dminus',prop.Dminus, ...
    'Gplus',Gp,'Gminus',Gm,'QLplus',QLp,'QRplus',QRp, ...
    'QLminus',QLm,'QRminus',QRm,'Jplus',Jp,'Jminus',Jm, ...
    'delta_plus',Dc_p,'delta_minus',Dc_m, ...
    'circle_jump_plus',Jc_p,'circle_jump_minus',Jc_m, ...
    'center_wall_jumps',center,'weighted_q',finite.q, ...
    'physical_unit_density',cellmap.eta_unit, ...
    'circle_delta_D_unit_wall_512',delta, ...
    'circle_j_Gamma_unit_wall_512',jump, ...
    'circle_theta_512',cellmap.circle_theta, ...
    'wall_dx_left_unit_512',cellmap.dx_left_unit, ...
    'wall_dx_right_unit_512',cellmap.dx_right_unit, ...
    'wall_y_512',cellmap.wall_y, ...
    'density_coordinate',cellmap.record.density_coordinate);
  out=struct('plus',plus.grams,'minus',minus.grams,'center',center, ...
    'record',record,'audit',audit);
end

function [orders,T]=LOCAL_wall_transform(c,y)
  N=numel(y); orders=(-N/2:N/2-1).'; beta=c.beta+2*pi*orders/c.d;
  T=c.d/N*exp(-1i*beta*y.')/sqrt(c.d);
end

function [ell,T]=LOCAL_circle_transform(c)
  N=c.circle_nodes; theta=(0:N-1)*2*pi/N; ell=(-N/2:N/2-1).';
  T=sqrt(2*pi*c.R)/N*exp(-1i*ell*theta);
end

function out=LOCAL_center_jumps(c,node,prop,coords,Wfft,cellmap)
  q=coords.q; qL=q(1:c.K); qR=q(c.K+1:end); E=diag(node.phase(:));
  dxL=1i*diag(node.gamma)*(qL-E*qR);
  dxR=1i*diag(node.gamma)*(E*qL-qR);
  embed=zeros(c.wall_samples,c.K); retained=(-c.M:c.M).';
  allorders=(-c.wall_samples/2:c.wall_samples/2-1).';
  for j=1:c.K, embed(allorders==retained(j),j)=1; end
  dxLall=embed*dxL; dxRall=embed*dxR;
  Gp=[prop.Dplus;prop.Dplus*prop.Pplus];
  Gm=[prop.Dminus*prop.Pminus;prop.Dminus];
  QL=-Wfft*cellmap.dx_left_unit; QR=Wfft*cellmap.dx_right_unit;
  right=dxRall+QL*Gp*coords.cplus;
  left=QR*Gm*coords.cminus-dxLall;
  out=struct('left_coefficients',left,'right_coefficients',right);
end
%% ==================== Circle and collar weights ====================
% Riccati and radial quadrature avoid a two-dimensional volume mesh.

function out=LOCAL_circle_weights(c,ell)
  p0=LOCAL_riccati(c,ell,c.riccati_steps_coarse);
  p1=LOCAL_riccati(c,ell,c.riccati_steps);
  weight=(p1.pin-p1.pout)/c.R;
  change=max(abs(weight-(p0.pin-p0.pout)/c.R)./ ...
    max([ones(size(weight)),abs(weight)],[],2));
  positive=isfinite(weight)&weight>0;
  low=abs(ell)<=8; bessel=NaN(size(ell));
  try
    bessel(low)=LOCAL_bessel_weights(c,ell(low));
    bessel_defect=max(abs(weight(low)-bessel(low))./ ...
      max([ones(sum(low),1),abs(bessel(low))],[],2));
  catch
    bessel_defect=NaN;
  end
  out=struct('available',all(positive),'weight',weight, ...
    'relative_change',change,'record',struct('orders',ell, ...
    'official_steps',c.riccati_steps,'coarse_steps',c.riccati_steps_coarse, ...
    'p_in',p1.pin,'p_out',p1.pout,'weights',weight, ...
    'discrete_energy_identity_defect',p1.energy_identity_defect, ...
    'low_order_bessel_weights',bessel, ...
    'low_order_bessel_relative_defect',bessel_defect, ...
    'positive_mask',positive,'relative_change',change, ...
    'basis','exp(i*l*theta)/sqrt(2*pi*R)', ...
    'weight_formula','(p_in-p_out)/R','outward_certified',false));
end

function weight=LOCAL_bessel_weights(c,ell)
  kin=sqrt(c.gamma*c.rho_disk); kout=sqrt(c.gamma);
  pin=LOCAL_annulus_logder(ell,kin,c.R-c.delta_c,c.R);
  pout=LOCAL_annulus_logder(ell,kout,c.R+c.delta_c,c.R);
  weight=(pin-pout)/c.R;
end

function p=LOCAL_annulus_logder(ell,kappa,rnatural,reval)
  p=zeros(size(ell));
  for j=1:numel(ell)
    l=abs(ell(j)); za=kappa*rnatural; zr=kappa*reval;
    [Ia,Ipa,Ka,Kpa]=LOCAL_bessel_values(l,za);
    [Ir,Ipr,Kr,Kpr]=LOCAL_bessel_values(l,zr);
    v=Kpa*Ir-Ipa*Kr; vr=kappa*(Kpa*Ipr-Ipa*Kpr);
    p(j)=reval*vr/v;
  end
end

function [I,Ip,K,Kp]=LOCAL_bessel_values(l,z)
  I=besseli(l,z,1)*exp(z); K=besselk(l,z,1)*exp(-z);
  if l==0
    Im=besseli(1,z,1)*exp(z); Km=besselk(1,z,1)*exp(-z);
  else
    Im=besseli(l-1,z,1)*exp(z); Km=besselk(l-1,z,1)*exp(-z);
  end
  Iq=besseli(l+1,z,1)*exp(z); Kq=besselk(l+1,z,1)*exp(-z);
  Ip=(Im+Iq)/2; Kp=-(Km+Kq)/2;
end

function out=LOCAL_riccati(c,ell,steps)
  tin=log(c.R-c.delta_c); t0=log(c.R); tout=log(c.R+c.delta_c);
  pin=zeros(size(ell)); pout=pin;
  [pin,din]=LOCAL_rk4(pin,tin,t0,steps,ell,c.gamma*c.rho_disk);
  [pout,dout]=LOCAL_rk4(pout,tout,t0,steps,ell,c.gamma);
  out=struct('pin',pin,'pout',pout, ...
    'energy_identity_defect',max([din;dout],[],1).');
end

function [p,defect]=LOCAL_rk4(p,t0,t1,steps,ell,alpha)
  h=(t1-t0)/steps; t=t0; v=ones(size(p)); energy=zeros(size(p));
  for j=1:steps
    s=[p,v,energy]; k1=LOCAL_riccati_rhs(s,t,ell,alpha);
    k2=LOCAL_riccati_rhs(s+h*k1/2,t+h/2,ell,alpha);
    k3=LOCAL_riccati_rhs(s+h*k2/2,t+h/2,ell,alpha);
    k4=LOCAL_riccati_rhs(s+h*k3,t+h,ell,alpha);
    s=s+h*(k1+2*k2+2*k3+k4)/6; p=s(:,1); v=s(:,2); energy=s(:,3); t=t+h;
    if any(~isfinite(s),'all'), defect=Inf(size(p)); return; end
  end
  endpoint=p.*v.^2;
  defect=abs(energy-endpoint)./max([ones(size(p)),abs(energy),abs(endpoint)],[],2);
end

function value=LOCAL_riccati_rhs(s,t,ell,alpha)
  p=s(:,1); v=s(:,2); q=ell.^2+alpha*exp(2*t);
  value=[q-p.^2,p.*v,(p.^2+q).*v.^2];
end

function weight=LOCAL_collar_weights(c,ell,nq)
  [x,w]=LOCAL_gauss(nq); weight=zeros(size(ell));
  for side=[-1,1]
    if side<0, rho=c.rho_disk; r0=c.R-c.delta_c; r1=c.R;
    else, rho=1; r0=c.R; r1=c.R+c.delta_c; end
    r=(r0+r1)/2+(r1-r0)/2*x; wr=(r1-r0)/2*w;
    if side<0, t=(c.R-r)/c.delta_c; drsign=-1;
    else, t=(r-c.R)/c.delta_c; drsign=1; end
    chi=1-3*t.^2+2*t.^3; chip=-6*t+6*t.^2; chipp=-6+12*t;
    amp=-side/2;
    for j=1:numel(ell)
      radial=amp*(-chipp/c.delta_c^2- ...
        drsign*chip./(r*c.delta_c)+(ell(j)^2./r.^2-c.mu_h*rho).*chi);
      % e_l is normalized in ds at r=R, so the area Jacobian is r/R.
      weight(j)=weight(j)+sum(wr.*(r/c.R).*(abs(radial).^2/rho));
    end
  end
end

function [x,w]=LOCAL_gauss(n)
  j=(1:n-1).'; beta=j./sqrt(4*j.^2-1);
  [V,D]=eig(diag(beta,1)+diag(beta,-1));
  [x,order]=sort(diag(D)); V=V(:,order); w=2*(V(1,:).^2).';
end

function out=LOCAL_factor_grams(Fw,Fc,Fv,Ff,c)
  factors={Fw,Fc,Fv,Ff,eye(c.K)};
  names={'wall','circle','volume','field','state'};
  grams=struct(); empty=struct('name','','available',false, ...
    'factor_size',[0,0],'hermitian_defect',NaN, ...
    'minimum_eigenvalue',NaN,'scale',NaN,'pass',false);
  records=repmat(empty,1,numel(names)); available=true;
  for j=1:numel(names)
    F=factors{j};
    if isempty(F) || any(~isfinite(F),'all')
      W=NaN(c.K); rec=struct('name',names{j},'available',false, ...
        'factor_size',size(F),'hermitian_defect',NaN,'minimum_eigenvalue',NaN, ...
        'scale',NaN,'pass',false);
    else
      W=F'*F; scale=norm(W,2); tolscale=max(realmin,scale);
      herm=norm(W-W','fro')/tolscale; mineig=min(real(eig((W+W')/2)));
      pass=all(isfinite(W),'all')&&herm<=c.gram_scale&& ...
        mineig>=-c.gram_scale*tolscale;
      rec=struct('name',names{j},'available',true,'factor_size',size(F), ...
        'hermitian_defect',herm,'minimum_eigenvalue',mineig, ...
        'scale',scale,'pass',pass);
    end
    grams.(names{j})=W; records(j)=rec; available=available&&rec.pass;
  end
  out=struct('grams',grams,'record',records,'available',available);
end

function value=LOCAL_outside_energy(A,mask)
  total=norm(A,'fro')^2;
  value=norm(A(mask,:),'fro')^2/max(realmin,total);
end
%% ==================== Full-matrix tails ====================
% Doubling retains all nonnormal coupling and records two associations.

function out=LOCAL_tail(P,grams,c0,c,side)
  names={'wall','circle','volume','field','state'};
  Wleft=cell(size(names)); Wright=Wleft;
  for k=1:numel(names), Wleft{k}=grams.(names{k}); Wright{k}=Wleft{k}; end
  pleft=P; powers=cell(c.tail_max_power+1,1);
  rows=repmat(LOCAL_empty_tail_row(numel(names)),c.tail_max_power+1,1);
  selected=NaN; active_mib=0; available_indices=[];
  for j=0:c.tail_max_power
    N=2^j; powers{j+1}=pleft; pright=LOCAL_alternate_power(P,powers,j);
    eN=norm(pleft-pright,2); pscale=max([1,norm(pleft,2),norm(pright,2)]);
    ahi=norm(pleft,2)+eN+100*c.K*eps*pscale;
    sums=zeros(1,numel(names)); omega=sums; allowance=Inf(size(sums));
    shares=allowance;
    for k=1:numel(names)
      wscale=max(norm(Wleft{k},2),norm(Wright{k},2));
      omega(k)=norm(Wleft{k}-Wright{k},2);
      if wscale>0, omega(k)=omega(k)+100*c.K*eps*wscale; end
      sums(k)=real(c0'*Wleft{k}*c0);
      if isfinite(ahi)&&ahi<1
        allowance(k)=ahi^2/(1-ahi^2)*(norm(Wleft{k},2)+omega(k))*norm(c0)^2;
        shares(k)=allowance(k)/max(realmin,sums(k));
      end
    end
    available=all(isfinite([ahi,sums,omega,allowance]))&&ahi<1&& ...
      all(sums>=0);
    qualified=available&&all(shares<=c.tail_share_max);
    rows(j+1)=struct('N',N,'power_left_norm',norm(pleft,2), ...
      'power_association_defect',eN,'a_hi',ahi,'finite_sums',sums, ...
      'gram_allowances',omega,'tail_allowances',allowance, ...
      'tail_shares',shares,'available',available,'qualification_pass',qualified);
    info=whos; active_mib=max(active_mib,sum([info.bytes])/2^20);
    if available, available_indices(end+1)=j+1; end %#ok<AGROW>
    if qualified&&isnan(selected), selected=j+1; end
    if j==c.tail_max_power, break; end
    old=pleft; oldr=pright; pleft=old*old;
    for k=1:numel(names)
      L=Wleft{k}; R=Wright{k};
      Wleft{k}=L+(old'*L)*old;
      Wright{k}=R+oldr'*(R*oldr);
    end
  end
  qualified=~isnan(selected);
  if isnan(selected)&&~isempty(available_indices)
    scores=zeros(size(available_indices));
    for k=1:numel(available_indices)
      scores(k)=max(rows(available_indices(k)).tail_shares);
    end
    [~,best]=min(scores); selected=available_indices(best);
  end
  available=~isnan(selected);
  if available, chosen=rows(selected); else, chosen=rows(end); end
  out=struct('chosen',chosen,'active_mib',active_mib,'record',struct( ...
    'available',available,'qualification_pass',qualified,'side',side, ...
    'gram_names',{names},'levels',rows, ...
    'selected_index',selected,'selected_N',chosen.N, ...
    'starts_at_cell',0,'tail_diagnostic_certified',false));
end

function alternate=LOCAL_alternate_power(P,powers,j)
  if j<3
    count=2^j; alternate=P; for k=2:count, alternate=alternate*P; end
  else
    base=powers{j-2}; alternate=base;
    for k=2:8, alternate=alternate*base; end
  end
end

function row=LOCAL_empty_tail_row(n)
  row=struct('N',NaN,'power_left_norm',NaN,'power_association_defect',NaN, ...
    'a_hi',NaN,'finite_sums',NaN(1,n),'gram_allowances',NaN(1,n), ...
    'tail_allowances',NaN(1,n),'tail_shares',NaN(1,n), ...
    'available',false,'qualification_pass',false);
end
%% ==================== Indicator and scale repeat ====================
% The numerator is a triangle sum; the denominator never receives a tail allowance.

function out=LOCAL_total(c,est,tm,tp,amplitude)
  a2=abs(amplitude)^2; imap=struct('wall',1,'circle',2,'volume',3, ...
    'field',4,'state',5);
  upper=tm.chosen.finite_sums+tm.chosen.tail_allowances+ ...
    tp.chosen.finite_sums+tp.chosen.tail_allowances;
  finite_lower=tm.chosen.finite_sums+tp.chosen.finite_sums;
  wall2=a2*est.center.wall_residual_squared+upper(imap.wall);
  circle2=upper(imap.circle); volume2=upper(imap.volume);
  field2=a2*est.center.field_squared+finite_lower(imap.field);
  M=sqrt(wall2)+sqrt(circle2)+sqrt(volume2);
  q=M/sqrt(field2); available=all(isfinite([wall2,circle2,volume2,field2,M,q]))&& ...
    all([wall2,circle2,volume2]>=0)&&field2>0;
  lambda=[NaN,NaN]; kval=lambda; width=NaN; message='';
  if ~available
    message='A residual component or the field lower candidate is invalid.';
  elseif q<1
    lambda=[max(0,(c.mu_h-q*c.gamma)/(1+q)), ...
      (c.mu_h+q*c.gamma)/(1-q)];
    kval=sqrt(lambda); width=diff(kval);
  end
  out=struct('available',available,'wall_squared',wall2, ...
    'circle_squared',circle2,'collar_volume_squared',volume2, ...
    'wall_component',sqrt(wall2),'circle_component',sqrt(circle2), ...
    'collar_volume_component',sqrt(volume2),'triangle_majorant',M, ...
    'field_lower_squared',field2,'field_lower',sqrt(field2),'q',q, ...
    'interval_defined',available&&q<1,'nominal_lambda_interval',lambda, ...
    'nominal_k_interval',kval,'nominal_k_width',width, ...
    'preregistered_k_resolution',c.tau_k_pre, ...
    'resolution_pass',available&&q<1&&width<=c.tau_k_pre, ...
    'message',message,'qualification','UNQUALIFIED', ...
    'outward_residual_upper',false,'outward_field_lower',false, ...
    'certified_tail',false,'certified_projected_gap',false, ...
    'independent_reference',false,'reliable_spectral_interval',false);
end

function out=LOCAL_scale_repeat(c,coords,est,prop,base)
  z=c.scale_oracle; cm=z*coords.cminus; cp=z*coords.cplus;
  tm=LOCAL_tail(prop.Pminus,est.minus,cm,c,'minus-scaled');
  tp=LOCAL_tail(prop.Pplus,est.plus,cp,c,'plus-scaled');
  if tm.record.available&&tp.record.available
    scaled=LOCAL_total(c,est,tm,tp,z); a2=abs(z)^2;
    values0=[base.wall_squared,base.circle_squared,base.collar_volume_squared, ...
      base.field_lower_squared,base.q];
    values1=[scaled.wall_squared/a2,scaled.circle_squared/a2, ...
      scaled.collar_volume_squared/a2,scaled.field_lower_squared/a2,scaled.q];
    defects=abs(values1-values0)./max([realmin*ones(size(values0)); ...
      abs(values0);abs(values1)],[],1);
  else
    defects=Inf(1,5);
  end
  out=struct('multiplier',z,'tail_pass',tm.record.available&&tp.record.available, ...
    'relative_defects',defects,'maximum_relative_defect',max(defects), ...
    'pass',all(isfinite(defects))&&max(defects)<=c.scale_relative_warning, ...
    'certified',false);
end
%% ==================== Warnings and result semantics ====================
% Numerical warnings do not suppress a finite q or its unqualified transform.

function warnings=LOCAL_cell_warnings(record,c)
  warnings=struct('code',{},'value',{},'blocking',{});
  if ~record.proxy_chart_solve.qualification_pass
    warnings(end+1)=LOCAL_warning('PROXY_CHART_QUALIFICATION_WARNING', ...
      max([record.proxy_chart_solve.projected_residual, ...
      record.proxy_chart_solve.full_residual, ...
      1e-8/max(realmin,record.proxy_chart_solve.reduced_rcond)]));
  end
  if record.solve.rcond<c.bie_rcond_warning || ...
      record.solve.max_rhs_relative_residual>c.bie_residual_warning || ...
      record.solve.max_rhs_backward_error>c.bie_residual_warning
    warnings(end+1)=LOCAL_warning('FINITE_DENSITY_QUALIFICATION_WARNING', ...
      max([record.solve.max_rhs_relative_residual, ...
      record.solve.max_rhs_backward_error]));
  end
  if record.background_pole_warning
    warnings(end+1)=LOCAL_warning('BACKGROUND_POLE_CLEARANCE_WARNING', ...
      record.background_pole_clearance);
  end
  if record.green_48_to_64_relative_change>c.refinement_warning
    warnings(end+1)=LOCAL_warning('GREEN_ORDER_REFINEMENT_WARNING', ...
      record.green_48_to_64_relative_change);
  end
  if record.wall_256_to_512_relative_change>c.refinement_warning
    warnings(end+1)=LOCAL_warning('WALL_ACTION_REFINEMENT_WARNING', ...
      record.wall_256_to_512_relative_change);
  end
  if record.circle_overresolved_relative_residual>c.refinement_warning
    warnings(end+1)=LOCAL_warning('CIRCLE_ACTION_RESIDUAL_WARNING', ...
      record.circle_overresolved_relative_residual);
  end
  if record.circle_256_to_512_relative_change>c.refinement_warning
    warnings(end+1)=LOCAL_warning('CIRCLE_ACTION_REFINEMENT_WARNING', ...
      record.circle_256_to_512_relative_change);
  end
  checks=[record.density_scale_unscale_roundtrip, ...
    record.matrix_scale_unscale_roundtrip, ...
    record.zeta_minus_sigma_roundtrip_defect, ...
    record.kernel.beta_minus_beta_reciprocity_defect, ...
    record.kernel.target_source_derivative_reciprocity_defect, ...
    record.kernel.mixed_derivative_reciprocity_defect, ...
    record.kernel.background_wall_lift_identity_defect, ...
    record.kernel.manufactured.maximum_relative_error, ...
    record.kernel.manufactured.maximum_minus_S_sign_defect];
  if any(~isfinite(checks)) || max(checks)>c.refinement_warning
    warnings(end+1)=LOCAL_warning('KERNEL_IDENTITY_QUALIFICATION_WARNING', ...
      max(checks));
  end
  cauchy=record.incoming_cauchy_decomposition;
  cauchy_value=max(cauchy.plus_relative_defect,cauchy.minus_relative_defect);
  if ~cauchy.available || ~isfinite(cauchy_value) || ...
      cauchy_value>c.refinement_warning
    warnings(end+1)=LOCAL_warning('OLD_INCOMING_DECOMPOSITION_WARNING',cauchy_value);
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
  prior=struct('attempt','pbie-a1','shell_exit_code',0, ...
    'producer_outcome','EXECUTION_UNAVAILABLE', ...
    'identifier','MATLAB:heterogeneousStrucAssignment', ...
    'message','Subscripted assignment between dissimilar structures.', ...
    'elapsed_seconds',133.37207583333333, ...
    'peak_active_mib',62.314550399780273,'scientific_stage_entered',true, ...
    'last_completed_gate','FINITE_DENSITY_EXACT_KERNEL_ACTION', ...
    'boundary_grams_and_later_status','NOT_REACHED','output_created',true, ...
    'artifact_names',{{'result.mat','report.md'}}, ...
    'artifact_sha256',{{'473a6809b5e8910c8e8daa82be5dd68c39da24f0edfa6c187abecba1629a7c51', ...
    '925132cd91bdf6ed29e3a4a7aed7a4661014427f84a42734825b616f717c9ecb'}});
  result=struct('schema',c.schema,'attempt',attempt,'retry_count',0, ...
    'prior_failed_attempt_count',1,'prior_attempt_history',prior, ...
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
    'coverage',struct('mathematical_finite_density_exact_kernel_trial_defined',false, ...
    'numerical_512_trace_approximation_computed',false, ...
    'mathematical_circle_value_collar_defined',false, ...
    'numerical_artificial_wall_jump_component_computed',false, ...
    'numerical_circle_normal_jump_component_computed',false, ...
    'numerical_collar_volume_component_computed',false, ...
    'numerical_field_lower_component_computed',false, ...
    'ordinary_double_full_matrix_tail_candidate_computed',false, ...
    'continuous_H1_numerically_enclosed',false, ...
    'continuous_jump_enclosed',false,'projected_gap',false), ...
    'reliability',struct('outward_residual_upper',false, ...
    'outward_field_lower',false,'certified_tail',false, ...
    'certified_projected_gap',false,'independent_reference',false, ...
    'reliable_spectral_interval',false), ...
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
    error('i31p:SoftTime','The soft limit forbids starting %s.',next_stage);
  end
end

function LOCAL_resource_gate(timer,peak,c)
  if toc(timer)>c.hard_seconds || peak>c.memory_mib_max
    error('i31p:Resource','The hard time or memory limit was exceeded.');
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
  if fid<0, error('i31p:Report','Could not create the report.'); end
  cleaner=onCleanup(@() fclose(fid));
  fprintf(fid,'# I3.1 pure-BIE boundary residual: `%s`\n\n',result.attempt);
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
  fprintf(fid,'- Incoming/outgoing decomposition: `diagnostic only`\n');
  fprintf(fid,'- 512-point traces enclose the continuous jump: `false`\n');
  fprintf(fid,'- Continuous H1 companion numerically enclosed: `false`\n');
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
  fprintf(fid,'\n## Reliability flags\n\n');
  for j=1:numel(names)
    fprintf(fid,'- `%s`: `%d`\n',names{j},result.reliability.(names{j}));
  end
  fprintf(fid,'\nAll numerical intervals are ordinary-double and unqualified.\n');
  clear cleaner;
end
