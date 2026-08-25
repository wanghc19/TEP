function result = check_g_resid(attempt)
%CHECK_G_RESID Compute the I3.1 lead-aware continuous strong residual.
% Purpose:
%   Build one BIE-informed, globally conforming Fourier--Hermite trial at
%   the saved I2 candidate and compute its full-waveguide residual ratio.
% Input:
%   attempt - New append-only tag; Revision B reviews 'lead-a3'.
% Output:
%   result  - Reconstruction, quadrature, tail, resource, and fail-close
%             diagnostics saved beside a short Markdown report.
% Main algorithm:
%   Recover whole stable-subspace propagation from frozen QZ bases, fit one
%   smooth per-cell trial to BIE data, integrate the continuous residual,
%   and sum both infinite leads by nonnormal matrix doubling.
% Based on:
%   research/projects/eig-apost/implementation/i3/design-3-1b.md.
% Main changes:
%   Replaces the compact center cutoff by a conforming center-plus-leads
%   trial; BIE sampling and fitting live in i31_bie_fit.m.
% Numerical goal:
%   Produce a computed estimator candidate, not a certified enclosure.

  if nargin ~= 1 || ~strcmp(char(attempt),'lead-a3')
    error('i31g:Attempt','The reviewed attempt name is lead-a3.');
  end
  here = fileparts(mfilename('fullpath'));
  output = fullfile(here,'output',char(attempt));
  if exist(output,'dir') || exist(output,'file')
    error('i31g:OutputExists','Output already exists: %s.',output);
  end
  if exist('OCTAVE_VERSION','builtin') ~= 0
    error('i31g:MATLABRequired','This experiment requires MATLAB.');
  end

  timer = tic;
  c = LOCAL_config();
  result = LOCAL_empty_result(char(attempt),c);
  peak_mib = 0;
  try
    rows = LOCAL_selectors();
    [seed,frame] = eval_i21('seed',c,rows);
    LOCAL_seed_gate(seed,frame,c);
    node = eval_i21('point',c.khat,c,frame);
    LOCAL_point_gate(node,frame,c);
    finite = LOCAL_finite_input(node,c);
    result.finite_input = finite;
    peak_mib = max(peak_mib,LOCAL_mib({seed,frame,node,finite}));
    LOCAL_resource_gate(timer,peak_mib,c);
    LOCAL_soft_gate(timer,c,'density reconstruction');

    density = i31_bie_fit('density',c,node,frame);
    result.density = density.record;
    if ~density.record.pass
      error('i31g:DensityRepresentation','The density representation gate failed.');
    end
    peak_mib = max(peak_mib,LOCAL_mib({seed,frame,node,finite,density}));
    LOCAL_resource_gate(timer,peak_mib,c);

    prop = LOCAL_propagation(node,c);
    result.propagation = prop.record;
    if ~prop.record.pass
      error('i31g:PropagationAction','The frozen-subspace action gate failed.');
    end
    coords = LOCAL_coordinates(node,finite.q,prop,c);
    result.coordinates = coords;
    LOCAL_soft_gate(timer,c,'BIE-informed fit');

    fit = i31_bie_fit('fit',c,node,density,prop.sides,coords);
    result.fit = fit.record;
    result.fit.trials = fit.trials;
    if ~fit.record.pass
      error('i31g:ConformingReconstruction','The fixed BIE-informed fit failed.');
    end
    peak_mib = max(peak_mib,LOCAL_mib({seed,frame,node,finite,density,prop,fit}));
    LOCAL_resource_gate(timer,peak_mib,c);

    center = LOCAL_center_levels(node,coords,c,1);
    result.center = center.record;
    if ~center.record.pass
      error('i31g:ConformingReconstruction','The center correction gate failed.');
    end
    LOCAL_soft_gate(timer,c,'continuous quadrature');

    grams = LOCAL_all_grams(fit.trials,node,coords,center,c);
    result.quadrature = grams.record;
    if ~grams.record.pass
      error('i31g:ContinuousResidual','The continuous Gram/quadrature gate failed.');
    end
    peak_mib=max(peak_mib, ...
      LOCAL_mib({seed,frame,node,finite,density,prop,fit,grams}));
    LOCAL_resource_gate(timer,peak_mib,c);
    LOCAL_soft_gate(timer,c,'infinite-tail doubling');

    tail_minus = LOCAL_tail(prop.Pminus,grams.official.minus,coords.cminus,c);
    tail_plus = LOCAL_tail(prop.Pplus,grams.official.plus,coords.cplus,c);
    result.tail = struct('minus',tail_minus.record,'plus',tail_plus.record);
    caller_mib=LOCAL_mib({seed,frame,node,finite,density,prop,fit,grams, ...
      tail_minus,tail_plus});
    peak_mib=max(peak_mib,caller_mib+ ...
      max(tail_minus.active_mib,tail_plus.active_mib));
    LOCAL_resource_gate(timer,peak_mib,c);
    if ~(tail_minus.record.pass && tail_plus.record.pass)
      error('i31g:InfiniteTail','The computed infinite-tail gate failed.');
    end

    refinement=LOCAL_global_refinement(grams,prop,coords,center, ...
      tail_minus,tail_plus,c);
    result.quadrature.refinement=refinement.record;
    caller_mib=LOCAL_mib({seed,frame,node,finite,density,prop,fit,grams, ...
      tail_minus,tail_plus,refinement});
    peak_mib=max(peak_mib,caller_mib+refinement.active_mib);
    LOCAL_resource_gate(timer,peak_mib,c);
    if ~refinement.record.quadrature_pass
      error('i31g:ContinuousResidual', ...
        'The full-waveguide quadrature or bubble gate failed.');
    end
    if ~refinement.record.auxiliary_tail_pass
      error('i31g:InfiniteTail', ...
        'An auxiliary coarse/J4 computed tail gate failed.');
    end
    official_diag=LOCAL_tail_diagnostic(center,tail_minus,tail_plus, ...
      coords.cminus,coords.cplus);
    if ~official_diag.valid
      error('i31g:InfiniteTail', ...
        'The computed field/residual tail diagnostic is invalid.');
    end
    scaled_center=LOCAL_center_levels(node,coords,c,c.scale_oracle);
    scaled_minus=LOCAL_tail(prop.Pminus,grams.official.minus, ...
      c.scale_oracle*coords.cminus,c);
    scaled_plus=LOCAL_tail(prop.Pplus,grams.official.plus, ...
      c.scale_oracle*coords.cplus,c);
    scaled_diag=LOCAL_tail_diagnostic(scaled_center,scaled_minus,scaled_plus, ...
      c.scale_oracle*coords.cminus,c.scale_oracle*coords.cplus);
    caller_mib=LOCAL_mib({seed,frame,node,finite,density,prop,fit,grams, ...
      tail_minus,tail_plus,refinement,scaled_center,scaled_minus,scaled_plus});
    peak_mib=max(peak_mib,caller_mib+ ...
      max(scaled_minus.active_mib,scaled_plus.active_mib));
    LOCAL_resource_gate(timer,peak_mib,c);
    if ~(scaled_center.record.pass&&scaled_minus.record.pass&& ...
        scaled_plus.record.pass&&scaled_diag.valid)
      error('i31g:ContinuousResidual','The phase/scale repeat failed.');
    end
    result.phase_scale_defect=abs(scaled_diag.eta-official_diag.eta)/ ...
      max(realmin,abs(official_diag.eta));
    if ~isfinite(result.phase_scale_defect)|| ...
        result.phase_scale_defect>c.scale_relative_max
      error('i31g:ContinuousResidual','The phase/scale gate failed.');
    end
    result=LOCAL_finish(result,official_diag,tail_minus,tail_plus,refinement,c);
  catch ME
    result = LOCAL_fail(result,ME);
  end

  result.elapsed_seconds = toc(timer);
  result.peak_active_mib = peak_mib;
  result.soft_time_exceeded = result.elapsed_seconds > c.soft_seconds;
  if result.elapsed_seconds > c.hard_seconds || peak_mib > c.memory_mib_max
    result.execution_pass = false;
    result.estimator.available = false;
    result.status = 'I3_1_EXECUTION_UNAVAILABLE';
    result.scientific_outcome = 'UNAVAILABLE';
    result.first_failure = LOCAL_failure('EXECUTION_UNAVAILABLE','RESOURCE', ...
      'The hard time or active-object memory limit was exceeded.','i31g:Resource');
  end
  if exist(output,'dir') || exist(output,'file')
    error('i31g:OutputExists','Output appeared during the run: %s.',output);
  end
  mkdir(output);
  save(fullfile(output,'result.mat'),'result','-v7');
  LOCAL_report(fullfile(output,'report.md'),result);
end

%% ==================== Frozen inputs ====================
% These values reproduce the fine M=48 I2 point and reviewed I3.1-B gates.

function c = LOCAL_config()
  c = struct('schema','TEP_I3_1_BIE_INFORMED_GLOBAL_RESID_V1_REV_B', ...
    'beta',0.5,'d',1.0,'R',0.2,'s',1.0,'rho_disk',17, ...
    'X_L',-0.5,'X_R',0.5,'H',1.1,'proxy_dist',0.2, ...
    'M',48,'K',97,'kstar',1.8327703475952146, ...
    'khat',1.832770289108157,'bubble_orders',[4,8], ...
    'quad_x',[64,128],'quad_r',[32,64],'quad_theta',[128,256], ...
    'fit_holdout_max',0.20,'fit_rcond_min',1e-10, ...
    'center_correction_max',0.10,'quad_relative_max',1e-5, ...
    'bubble_relative_max',0.10,'gram_hermitian_max',1e-12, ...
    'gram_psd_scale',1e-12,'scale_oracle',1e8*exp(1i*pi/7), ...
    'scale_relative_max',1e-11,'tail_share_max',1e-6, ...
    'tail_max_power',12,'tau_k_pre',1e-6,'rho_G_pre',0.1, ...
    'soft_seconds',900,'hard_seconds',1800,'memory_mib_max',512);
  c.level = struct('name','fine','ntot',256,'N_side',160, ...
    'N_top',160,'N_proxy_edge',80,'M_pw',32);
  c.expected = struct('proxy_rows',960,'proxy_columns',450, ...
    'proxy_shifted_rows',1920,'proxy_shifted_columns',450, ...
    'proxy_rank',260,'bie_order',512,'pencil_order',194, ...
    'chart_order',97,'adef_order',194,'graph_order',388);
  c.proxy_rank_ratio=1e-8; c.proxy_rank_gap_min=2;
  c.proxy_projector_repeat_tol=1e-10; c.proxy_rcond_min=1e-8;
  c.proxy_projected_tol=1e-11; c.proxy_full_residual_max=1e-5;
  c.proxy_shifted_residual_max=1e-5; c.proxy_seed_identity_tol=1e-12;
  c.branch_tol=1e-12; c.qz_residual_tol=1e-10; c.qz_overlap_min=0.9;
  c.cross_cluster_margin_min=100*c.K*eps; c.chart_margin_min=100*c.K*eps;
  c.chart_condition_eps_tol=1e-9; c.small_solve_residual_tol=1e3*c.K*eps;
  c.bie_rcond_min=1e-8; c.bie_residual_tol=1e-10;
  c.schur_tol=1e3*c.K*eps; c.dirichlet_rcond_min=1e-8;
  c.participation_min=1e-3; c.lift_residual_tol=1e-10;
  c.action_rcond_min=1e-8; c.action_residual_max=1e-10;
end

function rows = LOCAL_selectors()
  rows.plus = [89 41 35 71 92 12 16 10 66 70 93 33 9 69 79 30 36 ...
    62 64 84 95 40 18 91 94 58 61 13 85 90 24 32 42 60 28 74 21 ...
    97 22 55 77 96 38 14 17 2 20 1 67 75 37 43 72 5 80 81 82 7 ...
    68 39 25 19 78 29 6 76 86 59 8 4 65 83 23 31 3 73 57 63 56 ...
    26 88 27 11 87 15 34 54 44 53 45 52 46 51 47 50 48 49];
  rows.minus = [162 132 117 174 103 124 134 140 173 194 101 172 186 ...
    120 167 168 170 178 189 100 153 180 192 110 118 121 125 169 175 ...
    176 185 119 160 164 179 108 113 114 131 165 171 183 193 111 128 ...
    133 139 159 181 190 191 106 129 157 163 135 116 127 155 177 102 ...
    104 126 130 137 156 184 109 138 187 115 136 154 161 166 158 123 ...
    98 122 105 188 112 152 99 182 107 151 141 150 142 149 143 148 ...
    144 147 145 146];
end

%% ==================== Frozen finite input ====================
% These checks reproduce the minimum I2 point without changing its evaluator.

function LOCAL_seed_gate(seed,frame,c)
  ok = seed.k == c.kstar && seed.pass && all([seed.factors.pass]) && ...
    isequal(size(seed.Aqp),[512,512]) && ...
    isequal(size(seed.AdefD),[194,194]) && ...
    isequal(size(frame.Z0_plus),[194,97]) && ...
    isequal(size(frame.Z0_minus),[194,97]) && frame.proxy_chart.r == 260;
  if ~ok
    error('i31g:FiniteInput','The frozen seed/frame gate failed.');
  end
end

function LOCAL_point_gate(node,frame,c)
  ok = node.k == c.khat && strcmp(node.name,'fine') && ...
    node.spec.ntot == 256 && node.pass && node.plus.pass && ...
    node.minus.pass && node.branch_port.pass && node.branch_proxy.pass && ...
    node.cp.safe && node.cm.safe && all([node.factors.pass]) && ...
    isequal(node.H_plus_rows,frame.rows_plus) && ...
    isequal(node.H_minus_rows,frame.rows_minus) && ...
    isequal(size(node.AdefD),[194,194]) && ...
    isequal(size(node.AdefG),[388,388]) && ...
    all(isfinite(node.beta_m)) && all(isfinite(node.gamma));
  if ~ok
    error('i31g:FiniteInput','The saved-candidate point gate failed.');
  end
end

function out = LOCAL_finite_input(node,c)
  beta = node.beta_m(:); gamma = node.gamma(:);
  b = sqrt(1+abs(beta).^2);
  wr = repmat(sqrt(1./b),2,1);
  wc = repmat(1./sqrt(b+abs(gamma).^2./b),2,1);
  B = wr.*node.AdefD.*wc.';
  [~,S,V] = svd(B,'econ');
  singular = diag(S);
  qraw = wc.*V(:,end);
  if any(~isfinite(qraw)) || norm(qraw) == 0
    error('i31g:FiniteInput','The physical near-null vector is unavailable.');
  end
  q = qraw/norm(qraw);
  out = struct('pass',true,'q',q,'score',singular(end)/singular(1), ...
    'near_null_ratio',singular(end)/singular(end-1), ...
    'raw_residual',norm(node.AdefD*q), ...
    'raw_backward',norm(node.AdefD*q)/ ...
      max(realmin,norm(node.AdefD,2)*norm(q)), ...
    'minimum_factor_rcond',min([node.factors.rcond]), ...
    'maximum_factor_residual',max([node.factors.residual]));
end

%% ==================== Frozen whole-subspace propagation ====================
% Recover P-plus and P-minus without recomputing a QZ basis.

function out = LOCAL_propagation(node,c)
  plus = LOCAL_action(node.pair.A,node.pair.B,node.Zp,false,c);
  minus = LOCAL_action(node.pair.A,node.pair.B,node.Zm,true,c);
  K = c.K; G = diag(node.gamma(:));
  Ap = node.Zp(1:K,:); Bp = node.Zp(K+1:end,:);
  Am = node.Zm(1:K,:); Bm = node.Zm(K+1:end,:);
  sides.plus = struct('name','plus','P',plus.P, ...
    'd0',Ap+Bp,'g0',1i*G*(Ap-Bp), ...
    'd1',(Ap+Bp)*plus.P,'g1',1i*G*(Ap-Bp)*plus.P, ...
    'incoming',[Ap;Bp*plus.P]);
  sides.minus = struct('name','minus','P',minus.P, ...
    'd0',(Am+Bm)*minus.P,'g0',1i*G*(Am-Bm)*minus.P, ...
    'd1',Am+Bm,'g1',1i*G*(Am-Bm), ...
    'incoming',[Am*minus.P;Bm]);
  left_sign = norm(sides.minus.g1+node.Nm,'fro')/max(1,norm(node.Nm,'fro'));
  pass = plus.pass && minus.pass && left_sign <= 1e-13;
  out = struct('Pplus',plus.P,'Pminus',minus.P,'sides',sides, ...
    'record',struct('pass',pass,'plus',LOCAL_drop(plus,{'P'}), ...
    'minus',LOCAL_drop(minus,{'P'}),'left_global_dx_defect',left_sign));
end

function out = LOCAL_action(A,B,Z,reversed,c)
  if reversed, C=A*Z; Rhs=B*Z; else, C=B*Z; Rhs=A*Z; end
  [~,R] = qr(C,0);
  r = rank(R); rc = rcond(R); P = C\Rhs;
  if reversed
    defect=norm(B*Z-A*Z*P,'fro')/ ...
      max([1,norm(B*Z,'fro')+norm(A*Z,'fro')*norm(P,2)]);
  else
    defect=norm(A*Z-B*Z*P,'fro')/ ...
      max([1,norm(A*Z,'fro')+norm(B*Z,'fro')*norm(P,2)]);
  end
  finite=all(isfinite(P),'all')&&isfinite(rc)&&isfinite(defect);
  out=struct('P',P,'rank',r,'rcond',rc,'invariant_residual',defect, ...
    'pass',finite&&r==c.K&&rc>=c.action_rcond_min&& ...
    defect<=c.action_residual_max);
end

function out = LOCAL_coordinates(node,q,prop,c)
  K=c.K; I=eye(K); E=diag(node.phase(:));
  cm=node.Dm\([I,E]*q); cp=node.Dp\([E,I]*q);
  out=struct('q',q,'cminus',cm,'cplus',cp,'q_norm',norm(q), ...
    'cminus_norm',norm(cm),'cplus_norm',norm(cp), ...
    'minus_solve_residual',norm(node.Dm*cm-[I,E]*q)/max(1,norm([I,E]*q)), ...
    'plus_solve_residual',norm(node.Dp*cp-[E,I]*q)/max(1,norm([E,I]*q)), ...
    'Pminus_norm',norm(prop.Pminus,2),'Pplus_norm',norm(prop.Pplus,2));
end

%% ==================== Center field and correction ====================
% The stored-double Rayleigh dispersion remains in the total residual.

function out = LOCAL_center_levels(node,coords,c,scale)
  level_cells=cell(2,1);
  for j=1:2
    level_cells{j}=LOCAL_center(node,coords,c,c.quad_x(j),scale);
  end
  levels=vertcat(level_cells{:});
  fine=levels(2);
  correction_ratio=sqrt(fine.correction_h2/max(realmin,fine.raw_h2));
  rel=LOCAL_norm_changes(levels(1),levels(2));
  pass=all(isfinite([correction_ratio,rel]))&& ...
    correction_ratio<=c.center_correction_max;
  out=struct('levels',levels,'fine',fine,'record', ...
    struct('pass',pass,'correction_h2_ratio',correction_ratio, ...
    'component_relative_changes_diagnostic',rel, ...
    'refinement_gate','DEFERRED_TO_FULL_WAVEGUIDE_SCALE', ...
    'raw_dispersion_norm',sqrt(fine.raw_residual), ...
    'correction_residual_norm',sqrt(fine.correction_residual), ...
    'total_residual_norm',sqrt(fine.R),'levels',levels));
end

function out = LOCAL_center(node,coords,c,nx,scale)
  [x,w]=LOCAL_gauss(nx,c.X_L,c.X_R);
  beta=node.beta_m(:); gamma=node.gamma(:); mu=c.khat^2;
  q=scale*coords.q; cm=scale*coords.cminus; cp=scale*coords.cplus;
  K=c.K; qL=q(1:K); qR=q(K+1:end);
  rawL=qL+node.phase(:).*qR; rawR=node.phase(:).*qL+qR;
  rawgL=1i*gamma.*(qL-node.phase(:).*qR);
  rawgR=1i*gamma.*(node.phase(:).*qL-qR);
  dc0=node.Dm*cm-rawL; dc1=node.Dp*cp-rawR;
  dg0=-node.Nm*cm-rawgL; dg1=node.Np*cp-rawgR;
  U=0; R=0; Q=0; rawQ=0; corrQ=0; rawR2=0; corrR2=0;
  delta=beta.^2+gamma.^2-mu;
  for j=1:nx
    t=(x(j)-c.X_L)/(c.X_R-c.X_L);
    [h,hx,hxx]=LOCAL_hermite(t,c.X_R-c.X_L);
    corr=h(1)*dc0+h(2)*dg0+h(3)*dc1+h(4)*dg1;
    corrx=hx(1)*dc0+hx(2)*dg0+hx(3)*dc1+hx(4)*dg1;
    corrxx=hxx(1)*dc0+hxx(2)*dg0+hxx(3)*dc1+hxx(4)*dg1;
    ep=exp(1i*gamma*(x(j)-c.X_L));
    em=exp(-1i*gamma*(x(j)-c.X_R));
    raw=qL.*ep+qR.*em;
    rawx=1i*gamma.*(qL.*ep-qR.*em);
    rawxx=-gamma.^2.*raw;
    u=raw+corr; ux=rawx+corrx; uxx=rawxx+corrxx;
    uy=1i*beta.*u; uxy=1i*beta.*ux; uyy=-beta.^2.*u;
    rraw=delta.*raw;
    rcorr=-corrxx+(beta.^2-mu).*corr;
    r=rraw+rcorr;
    U=U+w(j)*sum(abs(u).^2);
    R=R+w(j)*sum(abs(r).^2);
    Q=Q+w(j)*sum(abs(u).^2+abs(ux).^2+abs(uy).^2+ ...
      abs(uxx).^2+2*abs(uxy).^2+abs(uyy).^2);
    rawQ=rawQ+w(j)*sum(abs(raw).^2+abs(rawx).^2+ ...
      abs(1i*beta.*raw).^2+abs(rawxx).^2+ ...
      2*abs(1i*beta.*rawx).^2+abs(-beta.^2.*raw).^2);
    corrQ=corrQ+w(j)*sum(abs(corr).^2+abs(corrx).^2+ ...
      abs(1i*beta.*corr).^2+abs(corrxx).^2+ ...
      2*abs(1i*beta.*corrx).^2+abs(-beta.^2.*corr).^2);
    rawR2=rawR2+w(j)*sum(abs(rraw).^2);
    corrR2=corrR2+w(j)*sum(abs(rcorr).^2);
  end
  out=struct('Nx',nx,'U',real(U),'R',real(R),'Q',real(Q), ...
    'raw_h2',real(rawQ),'correction_h2',real(corrQ), ...
    'raw_residual',real(rawR2),'correction_residual',real(corrR2));
end

function changes = LOCAL_norm_changes(a,b)
  changes=[abs(b.U-a.U)/max(realmin,b.U), ...
    abs(b.R-a.R)/max(realmin,b.R),abs(b.Q-a.Q)/max(realmin,b.Q)];
end

%% ==================== Continuous lead Grams ====================
% Fourier orthogonality plus polar disk corrections integrate the true rho.

function out = LOCAL_all_grams(trials,node,coords,center,c)
  store=cell(2,2);
  for jb=1:2
    for jq=1:2
      store{jb,jq}.minus=LOCAL_grams(trials(jb).minus,node,c, ...
        c.quad_x(jq),c.quad_r(jq),c.quad_theta(jq));
      store{jb,jq}.plus=LOCAL_grams(trials(jb).plus,node,c, ...
        c.quad_x(jq),c.quad_r(jq),c.quad_theta(jq));
    end
  end
  official=store{2,2};
  d=[];
  for jb=1:2
    for jq=1:2
      d=[d,store{jb,jq}.minus.diagnostics, ...
        store{jb,jq}.plus.diagnostics]; %#ok<AGROW>
    end
  end
  pass=all([d.pass]);
  out=struct('official',official,'all',{store},'record', ...
    struct('pass',pass,'levels',{store}));
end

function out = LOCAL_grams(trial,node,c,nx,nr,ntheta)
  K=c.K; mu=c.khat^2; M=zeros(K); G=zeros(K); Q=zeros(K);
  [x,w]=LOCAL_gauss(nx,c.X_L,c.X_R);
  beta=node.beta_m(:);
  for j=1:nx
    [U,Ux,Uxx]=LOCAL_fourier_maps(trial,x(j),c);
    Uy=1i*beta.*U; Uxy=1i*beta.*Ux; Uyy=-beta.^2.*U;
    R1=-Uxx+(beta.^2-mu).*U;
    M=M+w(j)*(U'*U); G=G+w(j)*(R1'*R1);
    Q=Q+w(j)*(U'*U+Ux'*Ux+Uy'*Uy+Uxx'*Uxx+ ...
      2*(Uxy'*Uxy)+Uyy'*Uyy);
  end
  [rr,wr]=LOCAL_gauss(nr,0,c.R);
  theta=(0:ntheta-1)'*(2*pi/ntheta); wt=2*pi/ntheta;
  for j=1:nr
    tx=rr(j)*cos(theta); ty=rr(j)*sin(theta);
    [Phi,~,PhiXX,PhiYY]=LOCAL_trial_points(trial,tx,ty,c);
    R1=-PhiXX-PhiYY-mu*Phi;
    R17=-PhiXX-PhiYY-mu*c.rho_disk*Phi;
    weight=wr(j)*rr(j)*wt;
    M=M+weight*(c.rho_disk-1)*(Phi'*Phi);
    G=G+weight*((R17'*R17)/c.rho_disk-R1'*R1);
  end
  diag=LOCAL_gram_diagnostics(M,G,Q,c);
  out=struct('M',(M+M')/2,'G',(G+G')/2,'Q',(Q+Q')/2, ...
    'Nx',nx,'Nr',nr,'Ntheta',ntheta,'diagnostics',diag);
end

function out = LOCAL_gram_diagnostics(M,G,Q,c)
  mats={M,G,Q}; names={'M','G','Q'};
  out=repmat(struct('name','','hermitian_defect',NaN, ...
    'minimum_eigenvalue',NaN,'pass',false),3,1);
  for j=1:3
    A=mats{j}; scale=max(realmin,norm(A,2));
    hd=norm(A-A','fro')/max(realmin,norm(A,'fro'));
    mine=min(real(eig((A+A')/2)));
    out(j)=struct('name',names{j},'hermitian_defect',hd, ...
      'minimum_eigenvalue',mine,'pass',isfinite(hd)&&isfinite(mine)&& ...
      hd<=c.gram_hermitian_max&&mine>=-c.gram_psd_scale*scale);
  end
end

%% ==================== Infinite-tail doubling ====================
% Whole matrices retain Jordan and nonnormal transient effects.

function out = LOCAL_tail(P,grams,c0,c)
  names={'M','G','Q'}; W={grams.M,grams.G,grams.Q};
  omega=zeros(1,3); pN=P; err=0; powers=cell(c.tail_max_power+1,1);
  proto=struct('N',NaN,'power_norm',NaN,'power_error',NaN, ...
    'repeat_defect',NaN,'a_hi',NaN,'finite_sums',[], ...
    'accumulation_allowances',[],'tail_allowances',[], ...
    'tail_shares',[],'pass',false);
  rows=repmat(proto,c.tail_max_power+1,1); active_mib=0;
  selected=NaN; gammaK=c.K*eps/(1-c.K*eps);
  for j=0:c.tail_max_power
    N=2^j; powers{j+1}=pN; repeat_defect=0;
    if N>=4
      A=powers{j-1}; repeat=((A*A)*A)*A;
      repeat_defect=norm(repeat-pN,2);
    end
    pn=norm(pN,2);
    ahi=pn+err+10*repeat_defect;
    s=zeros(1,3); t=Inf(1,3); share=Inf(1,3);
    for k=1:3
      s(k)=real(c0'*W{k}*c0);
      if isfinite(ahi)&&ahi<1
        t(k)=ahi^2/(1-ahi^2)*(norm(W{k},2)+omega(k))*norm(c0)^2;
        share(k)=t(k)/max(realmin,s(k));
      end
    end
    pass=isfinite(ahi)&&ahi<1&&all(isfinite([s,t,share,omega]))&& ...
      all(s>0)&&all(share<=c.tail_share_max);
    rows(j+1)=struct('N',N,'power_norm',pn,'power_error',err, ...
      'repeat_defect',repeat_defect,'a_hi',ahi,'finite_sums',s, ...
      'accumulation_allowances',omega,'tail_allowances',t, ...
      'tail_shares',share,'pass',pass);
    info=whos; active_mib=max(active_mib,sum([info.bytes])/2^20);
    if pass&&isnan(selected), selected=j+1; end
    if j==c.tail_max_power, break; end
    p2=pN*pN;
    err2=2*pn*err+err^2+100*gammaK*pn^2;
    for k=1:3
      primary=W{k}+pN'*(W{k}*pN);
      alternate=W{k}+(pN'*W{k})*pN;
      omega(k)=(1+(pn+err)^2)*omega(k)+ ...
        (2*pn*err+err^2)*norm(W{k},2)+ ...
        100*gammaK*(1+pn^2)*norm(W{k},2)+ ...
        10*norm(alternate-primary,2);
      W{k}=primary;
    end
    pN=p2; err=err2;
  end
  if isnan(selected), chosen=rows(end); pass=false;
  else, chosen=rows(selected); pass=true; end
  out=struct('chosen',chosen,'active_mib',active_mib,'record',struct('pass',pass, ...
    'gram_names',{names},'levels',rows,'selected_index',selected, ...
    'selected_N',chosen.N,'peak_local_workspace_mib',active_mib, ...
    'tail_diagnostic_certified',false));
end

function out = LOCAL_global_refinement(grams,prop,coords,center,tm,tp,c)
  coarse_m=LOCAL_tail(prop.Pminus,grams.all{2,1}.minus,coords.cminus,c);
  coarse_p=LOCAL_tail(prop.Pplus,grams.all{2,1}.plus,coords.cplus,c);
  j4_m=LOCAL_tail(prop.Pminus,grams.all{1,2}.minus,coords.cminus,c);
  j4_p=LOCAL_tail(prop.Pplus,grams.all{1,2}.plus,coords.cplus,c);
  auxiliary_tail_pass=coarse_m.record.pass&&coarse_p.record.pass&& ...
    j4_m.record.pass&&j4_p.record.pass;
  official=LOCAL_global_values(tm,tp,center,1);
  coarse=LOCAL_global_values(coarse_m,coarse_p, ...
    struct('fine',center.levels(1)),1);
  j4=LOCAL_global_values(j4_m,j4_p,center,1);
  changes=[abs(sqrt(coarse.U)-sqrt(official.U))/max(realmin,sqrt(official.U)), ...
    abs(sqrt(coarse.R)-sqrt(official.R))/max(realmin,sqrt(official.R)), ...
    abs(coarse.ratio-official.ratio)/max(realmin,abs(official.ratio)), ...
    abs(sqrt(coarse.Q)-sqrt(official.Q))/max(realmin,sqrt(official.Q))];
  center_scale=[abs(center.levels(2).U-center.levels(1).U)/ ...
    max(realmin,official.U),abs(center.levels(2).R-center.levels(1).R)/ ...
    max(realmin,official.R),abs(center.levels(2).Q-center.levels(1).Q)/ ...
    max(realmin,official.Q)];
  bubble_change=abs(j4.ratio-official.ratio)/ ...
    max(realmin,abs(official.ratio));
  finite=all(isfinite([changes,center_scale,bubble_change, ...
    official.U,official.R,official.Q]));
  quadrature_pass=finite&&max(changes)<=c.quad_relative_max&& ...
    max(center_scale)<=c.quad_relative_max&& ...
    bubble_change<=c.bubble_relative_max;
  pass=quadrature_pass&&auxiliary_tail_pass;
  record=struct('pass',pass,'quadrature_pass',quadrature_pass, ...
    'auxiliary_tail_pass',auxiliary_tail_pass, ...
    'field_residual_ratio_H2_changes',changes, ...
    'center_changes_scaled_by_full_waveguide',center_scale, ...
    'bubble_ratio_change',bubble_change,'official',official, ...
    'coarse_quadrature',coarse,'J4_fine_quadrature',j4, ...
    'coarse_tail_minus',coarse_m.record,'coarse_tail_plus',coarse_p.record, ...
    'J4_tail_minus',j4_m.record,'J4_tail_plus',j4_p.record);
  info=whos;
  active_mib=max([sum([info.bytes])/2^20,coarse_m.active_mib, ...
    coarse_p.active_mib,j4_m.active_mib,j4_p.active_mib]);
  record.peak_local_workspace_mib=active_mib;
  out=struct('record',record,'official',official,'active_mib',active_mib);
end

function out = LOCAL_global_values(tm,tp,center,scale2)
  m=tm.chosen; p=tp.chosen;
  U=center.fine.U+scale2*(m.finite_sums(1)+p.finite_sums(1));
  R=center.fine.R+scale2*(m.finite_sums(2)+p.finite_sums(2));
  Q=center.fine.Q+scale2*(m.finite_sums(3)+p.finite_sums(3));
  out=struct('U',real(U),'R',real(R),'Q',real(Q), ...
    'ratio',sqrt(max(0,real(R))/max(realmin,real(U))));
end

function out = LOCAL_tail_diagnostic(center,tm,tp,cminus,cplus)
  cm=tm.chosen; cp=tp.chosen;
  om=cm.accumulation_allowances; op=cp.accumulation_allowances;
  Udiag=center.fine.U+cm.finite_sums(1)+cp.finite_sums(1)- ...
    norm(cminus)^2*om(1)-norm(cplus)^2*op(1);
  Rdiag=center.fine.R+cm.finite_sums(2)+cp.finite_sums(2)+ ...
    norm(cminus)^2*om(2)+norm(cplus)^2*op(2)+ ...
    cm.tail_allowances(2)+cp.tail_allowances(2);
  valid=all(isfinite([Udiag,Rdiag]))&&Udiag>0&&Rdiag>=0;
  eta=NaN;
  if valid, eta=sqrt(Rdiag/Udiag); end
  out=struct('valid',valid,'Udiag',Udiag,'Rdiag',Rdiag,'eta',eta);
end

function result = LOCAL_finish(result,diagnostic,tm,tp,refinement,c)
  cm=tm.chosen; cp=tp.chosen;
  eta=diagnostic.eta; Udiag=diagnostic.Udiag; Rdiag=diagnostic.Rdiag;
  mu=c.khat^2;
  interval=[sqrt(max(0,mu-eta)),sqrt(mu+eta)]; width=diff(interval);
  result.execution_pass=true;
  result.indicator_available=isfinite(eta)&&Udiag>0;
  result.estimator=struct('available',result.indicator_available, ...
    'computed_lambda_ratio',eta,'field_diag_lower',Udiag, ...
    'residual_diag_upper',Rdiag,'nominal_k_interval',interval, ...
    'nominal_k_width',width,'absolute_resolution_pass', ...
    mu>eta&&width<=c.tau_k_pre,'tail_diagnostic_certified',false, ...
    'nominal_field_squared',refinement.official.U, ...
    'nominal_residual_squared',refinement.official.R, ...
    'nominal_H2_squared',refinement.official.Q, ...
    'minus_H2_tail_allowance',cm.tail_allowances(3), ...
    'plus_H2_tail_allowance',cp.tail_allowances(3), ...
    'field_lower_bound_certified',false,'residual_upper_bound_certified',false, ...
    'projected_gap_available',false,'projected_gap_gate','NOT_REACHED');
  result.coverage=struct('global_conforming_trial',true, ...
    'material_volume',true,'cell_walls',true,'y_quasiperiodicity',true, ...
    'infinite_tail',true,'reliable_numerical_enclosure',false, ...
    'projected_gap',false,'unique_target',false,'upper_bound',false);
  if ~result.estimator.absolute_resolution_pass
    result.status='I3_1_BIE_INFORMED_RESOLUTION_INSUFFICIENT';
    result.scientific_outcome='BIE_INFORMED_RESOLUTION_INSUFFICIENT';
    result.first_failure=LOCAL_failure( ...
      'BIE_INFORMED_RESOLUTION_INSUFFICIENT','RESOLUTION', ...
      'The computed nominal interval misses the preregistered resolution.', ...
      'i31g:Resolution');
  else
    result.status= ...
      'I3_1_BIE_INFORMED_CONTINUOUS_STRONG_RESIDUAL_ESTIMATOR_CANDIDATE';
    result.scientific_outcome= ...
      'BIE_INFORMED_CONTINUOUS_STRONG_RESIDUAL_ESTIMATOR_CANDIDATE';
    result.first_failure=LOCAL_failure( ...
      'RELIABLE_NUMERICAL_ENCLOSURE_UNAVAILABLE','ENCLOSURE', ...
      'Ordinary-double quadrature and tail diagnostics are not certified.', ...
      'i31g:Enclosure');
  end
end

%% ==================== Trial evaluation and quadrature ====================
% Explicit polynomial/Fourier formulas are shared by all continuous integrals.

function [U,Ux,Uxx] = LOCAL_fourier_maps(trial,x,c)
  t=(x-c.X_L)/(c.X_R-c.X_L);
  [h,hx,hxx]=LOCAL_hermite(t,c.X_R-c.X_L);
  U=h(1)*trial.d0+h(2)*trial.g0+h(3)*trial.d1+h(4)*trial.g1;
  Ux=hx(1)*trial.d0+hx(2)*trial.g0+hx(3)*trial.d1+hx(4)*trial.g1;
  Uxx=hxx(1)*trial.d0+hxx(2)*trial.g0+hxx(3)*trial.d1+hxx(4)*trial.g1;
  [b,bx,bxx]=LOCAL_bubbles(t,trial.J,c.X_R-c.X_L);
  for j=1:trial.J
    Cj=squeeze(trial.C(j,:,:));
    U=U+b(j)*Cj; Ux=Ux+bx(j)*Cj; Uxx=Uxx+bxx(j)*Cj;
  end
end

function [Phi,PhiX,PhiXX,PhiYY] = LOCAL_trial_points(trial,x,y,c)
  L=c.X_R-c.X_L; t=(x(:)-c.X_L)/L; n=numel(t); K=c.K;
  h=[2*t.^3-3*t.^2+1,L*(t.^3-2*t.^2+t), ...
    -2*t.^3+3*t.^2,L*(t.^3-t.^2)];
  hx=[(6*t.^2-6*t)/L,3*t.^2-4*t+1, ...
    (-6*t.^2+6*t)/L,3*t.^2-2*t];
  hxx=[(12*t-6)/L^2,(6*t-4)/L, ...
    (-12*t+6)/L^2,(6*t-2)/L];
  psi=exp(1i*y(:)*trial.beta(:).')/sqrt(c.d);
  psiyy=psi.*(-trial.beta(:).'.^2);
  base={trial.d0,trial.g0,trial.d1,trial.g1};
  Phi=zeros(n,K); PhiX=Phi; PhiXX=Phi; PhiYY=Phi;
  for j=1:4
    value=psi*base{j}; yy=psiyy*base{j};
    Phi=Phi+h(:,j).*value;
    PhiX=PhiX+hx(:,j).*value;
    PhiXX=PhiXX+hxx(:,j).*value;
    PhiYY=PhiYY+h(:,j).*yy;
  end
  B=zeros(n,trial.J); Bx=B; Bxx=B;
  for p=1:n
    [b,bx,bxx]=LOCAL_bubbles(t(p),trial.J,L);
    B(p,:)=b; Bx(p,:)=bx; Bxx(p,:)=bxx;
  end
  for j=1:trial.J
    Cj=squeeze(trial.C(j,:,:));
    value=psi*Cj; yy=psiyy*Cj;
    Phi=Phi+B(:,j).*value;
    PhiX=PhiX+Bx(:,j).*value;
    PhiXX=PhiXX+Bxx(:,j).*value;
    PhiYY=PhiYY+B(:,j).*yy;
  end
end

function [h,hx,hxx] = LOCAL_hermite(t,L)
  h=[2*t^3-3*t^2+1,L*(t^3-2*t^2+t), ...
    -2*t^3+3*t^2,L*(t^3-t^2)];
  ht=[6*t^2-6*t,L*(3*t^2-4*t+1), ...
    -6*t^2+6*t,L*(3*t^2-2*t)];
  htt=[12*t-6,L*(6*t-4),-12*t+6,L*(6*t-2)];
  hx=ht/L; hxx=htt/L^2;
end

function [b,bx,bxx] = LOCAL_bubbles(t,J,L)
  z=2*t-1; [P,Pt,Ptt]=LOCAL_legendre(z,J-1);
  f=t^2*(1-t)^2; ft=2*t-6*t^2+4*t^3; ftt=2-12*t+12*t^2;
  b=f*P; bt=ft*P+2*f*Pt; btt=ftt*P+4*ft*Pt+4*f*Ptt;
  bx=bt/L; bxx=btt/L^2;
end

function [P,Pz,Pzz] = LOCAL_legendre(z,nmax)
  P=zeros(1,nmax+1); Pz=P; Pzz=P; P(1)=1;
  if nmax==0, return; end
  P(2)=z; Pz(2)=1;
  for n=1:nmax-1
    P(n+2)=((2*n+1)*z*P(n+1)-n*P(n))/(n+1);
    Pz(n+2)=((2*n+1)*(P(n+1)+z*Pz(n+1))-n*Pz(n))/(n+1);
    Pzz(n+2)=((2*n+1)*(2*Pz(n+1)+z*Pzz(n+1))-n*Pzz(n))/(n+1);
  end
end

function [x,w] = LOCAL_gauss(n,a,b)
  j=(1:n-1)'; v=j./sqrt(4*j.^2-1);
  [V,D]=eig(diag(v,1)+diag(v,-1));
  x0=diag(D); [x0,idx]=sort(x0); V=V(:,idx);
  w0=2*(V(1,:)'.^2);
  x=(a+b)/2+(b-a)*x0/2; w=(b-a)*w0/2;
end

%% ==================== Failure, resources, and output ====================
% One top-level catch preserves partial diagnostics without a provenance layer.

function result = LOCAL_empty_result(attempt,c)
  prior_stderr=sprintf([ ...
    '2026-08-16 22:14:20.956 MATLAB_maca64[1211:15409342] XType: Using static font registry.\n', ...
    'Could not create on-disk crash report: failed opening file: Operation not permitted: unspecified iostream_category error\n\n', ...
    'MATLAB is exiting because of fatal error']);
  prior_a1=struct('attempt','lead-a1','classification', ...
    'STARTUP_PREFLIGHT_CONSUMED','stage','MATLAB_STARTUP', ...
    'elapsed_seconds',3.3,'elapsed_basis','OUTER_EXEC_WALL_TIME', ...
    'exit_code',137,'terminal_output',prior_stderr,'code_entered',false, ...
    'runner_calls',0,'evaluator_calls',0,'evaluator_calls_basis', ...
    'DIRECT_STARTUP_EVIDENCE','finite_input_gate','NOT_REACHED', ...
    'density_gate','NOT_REACHED','downstream_gates','NOT_REACHED', ...
    'output_created',false,'artifact_names','NONE', ...
    'producer_status','NOT_AVAILABLE','producer_failure_code','NOT_AVAILABLE', ...
    'producer_message','NOT_AVAILABLE','producer_identifier','NOT_AVAILABLE', ...
    'peak_active_mib',NaN,'retry_count',0,'crash_path','NOT_AVAILABLE', ...
    'matlab_version','NOT_AVAILABLE');
  prior_a2=struct('attempt','lead-a2','classification', ...
    'IMPLEMENTATION_NAMING_FAILURE_CONSUMED','stage','DENSITY_ORACLE', ...
    'elapsed_seconds',17.421279875,'elapsed_basis','PRODUCER_RESULT_FIELD', ...
    'exit_code',0,'terminal_output','NOT_AVAILABLE','code_entered',true, ...
    'runner_calls',1,'evaluator_calls',2,'evaluator_calls_basis', ...
    'CONTROL_FLOW_RECONSTRUCTION_FROM_FINITE_INPUT_PASS_NOT_PRODUCER_FIELD', ...
    'finite_input_gate','PASS','density_gate','NOT_DETERMINED', ...
    'downstream_gates','NOT_REACHED','output_created',true, ...
    'artifact_names','result.mat;report.md', ...
    'producer_status','I3_1_EXECUTION_UNAVAILABLE', ...
    'producer_failure_code','EXECUTION_UNAVAILABLE', ...
    'producer_message','Unrecognized function or variable ''pi''.', ...
    'producer_identifier','MATLAB:UndefinedFunction', ...
    'peak_active_mib',61.1546688079834,'retry_count',0, ...
    'crash_path','NOT_APPLICABLE','matlab_version','NOT_AVAILABLE');
  prior=[prior_a1,prior_a2];
  smoke=struct('scope','STARTUP_ONLY','sandbox','OUTSIDE', ...
    'command','/Applications/MATLAB_R2023b.app/bin/matlab -batch "disp(version);"', ...
    'elapsed_seconds',17.470671,'exit_code',0, ...
    'matlab_version','R2023b 23.2.0.2365128');
  result=struct('schema',c.schema,'attempt',attempt,'candidate',c.khat, ...
    'mu_h',c.khat^2,'config',c,'execution_pass',false, ...
    'indicator_available',false,'status','I3_1_NOT_RUN', ...
    'scientific_outcome','UNAVAILABLE','finite_input',struct(), ...
    'density',struct(),'propagation',struct(),'coordinates',struct(), ...
    'fit',struct(),'center',struct(),'quadrature',struct(),'tail',struct(), ...
    'phase_scale_defect',NaN,'estimator',struct('available',false), ...
    'coverage',struct(),'first_failure',LOCAL_failure('NOT_RUN','STARTUP', ...
    'No computation has completed.',''),'elapsed_seconds',NaN, ...
    'peak_active_mib',NaN,'soft_time_exceeded',false, ...
    'prior_failed_attempt_count',2,'prior_failed_attempts',prior, ...
    'startup_environment_check',smoke,'retry_count',0, ...
    'retry_history',strings(0,1),'command', ...
    "matlab -batch ""addpath(fullfile(pwd,'test','i3','g-resid'),fullfile(pwd,'test','i2','k-count')); check_g_resid('lead-a3');""");
end

function result = LOCAL_fail(result,ME)
  [code,category]=LOCAL_failure_code(ME.identifier);
  result.first_failure=LOCAL_failure(code,category,ME.message,ME.identifier);
  result.scientific_outcome=code; result.status=['I3_1_',code];
  result.execution_pass=~strcmp(code,'EXECUTION_UNAVAILABLE');
  result.indicator_available=false; result.estimator.available=false;
end

function [code,category] = LOCAL_failure_code(id)
  if startsWith(id,'i31g:FiniteInput')
    code='FINITE_DISCRETE_INPUT_UNAVAILABLE'; category='FINITE_INPUT';
  elseif startsWith(id,'i31g:Density')
    code='DENSITY_REPRESENTATION_UNRESOLVED'; category='DENSITY';
  elseif startsWith(id,'i31g:Propagation')
    code='PROPAGATION_ACTION_UNRESOLVED'; category='PROPAGATION';
  elseif startsWith(id,'i31g:Conforming')
    code='CONFORMING_RECONSTRUCTION_UNRESOLVED'; category='RECONSTRUCTION';
  elseif startsWith(id,'i31g:Continuous')
    code='CONTINUOUS_STRONG_RESIDUAL_UNRESOLVED'; category='QUADRATURE';
  elseif startsWith(id,'i31g:Infinite')
    code='INFINITE_TAIL_UNRESOLVED'; category='TAIL';
  else
    code='EXECUTION_UNAVAILABLE'; category='EXECUTION';
  end
end

function out = LOCAL_failure(code,category,message,identifier)
  out=struct('code',code,'category',category,'message',message, ...
    'identifier',identifier);
end

function LOCAL_soft_gate(timer,c,next_stage)
  if toc(timer)>c.soft_seconds
    error('i31g:SoftTime','Soft time reached before %s.',next_stage);
  end
end

function LOCAL_resource_gate(timer,peak_mib,c)
  if toc(timer)>c.hard_seconds || peak_mib>c.memory_mib_max
    error('i31g:Resource','The hard time or active-object memory limit was exceeded.');
  end
end

function mib = LOCAL_mib(values)
  mib=0;
  for j=1:numel(values)
    item=values{j}; info=whos('item'); mib=mib+info.bytes/2^20;
  end
end

function out = LOCAL_drop(in,names)
  out=in;
  for j=1:numel(names)
    if isfield(out,names{j}), out=rmfield(out,names{j}); end
  end
end

function LOCAL_report(path,result)
  fid=fopen(path,'w');
  if fid<0, error('i31g:Report','Cannot open report.md.'); end
  cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid,'# I3.1 lead-aware continuous residual\n\n');
  fprintf(fid,'- Attempt: %s\n',result.attempt);
  fprintf(fid,'- Status: %s\n',result.status);
  fprintf(fid,'- First unavailable condition: %s\n',result.first_failure.code);
  fprintf(fid,'- Saved candidate: %.15f\n',result.candidate);
  fprintf(fid,'- Elapsed seconds: %.6f\n',result.elapsed_seconds);
  fprintf(fid,'- Peak active-object MiB: %.6f\n',result.peak_active_mib);
  if isfield(result.estimator,'computed_lambda_ratio')
    fprintf(fid,'- Computed lambda-scale ratio: %.17g\n', ...
      result.estimator.computed_lambda_ratio);
    fprintf(fid,'- Nominal k interval: [%.17g, %.17g]\n', ...
      result.estimator.nominal_k_interval);
  end
  fprintf(fid,'\nWhen its reconstruction gates pass, the trial is BIE-informed ');
  fprintf(fid,['and conforming by construction. Ordinary-double quadrature ', ...
    'and tail values are not certified ', ...
    'bounds, and no projected-gap claim is made.\n']);
end
