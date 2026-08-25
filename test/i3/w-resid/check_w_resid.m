function result = check_w_resid(attempt)
%CHECK_W_RESID Compute the I3.1 conforming Q1--RT0 weak residual.
% Purpose:
%   Reconstruct a conforming whole-waveguide trial from the saved I2
%   candidate and compute an ordinary-double functional-majorant candidate.
% Input:
%   attempt - New append-only tag; the reviewed V2 tag is 'weak-a1'.
% Output:
%   result  - Finite input, Q1/RT0, full-P tail, estimator, resource, and
%             fail-close diagnostics saved beside a short Markdown report.
% Main algorithm:
%   Recover frozen stable-subspace actions, solve physical Q1 Dirichlet cell
%   problems, reconstruct a global RT0 flux, sum both infinite leads by
%   whole-matrix doubling, and form the shifted weak-residual majorant.
% Based on:
%   research/projects/eig-apost/implementation/i3/design-3-1b.md.
% Main changes:
%   Replaces BIE close evaluation by a conforming finite-element trial and
%   keeps outward enclosure and projected-gap claims explicitly unavailable.
% Numerical goal:
%   Decide whether the computed nominal interval reaches the preregistered
%   resolution; no finite root or continuous eigenvalue identity is claimed.

  if nargin ~= 1 || ~strcmp(char(attempt),'weak-a1')
    error('i31w:Attempt','The reviewed V2 attempt name is weak-a1.');
  end
  here = fileparts(mfilename('fullpath'));
  output = fullfile(here,'output',char(attempt));
  if exist(output,'dir') || exist(output,'file')
    error('i31w:OutputExists','Output already exists: %s.',output);
  end
  if exist('OCTAVE_VERSION','builtin') ~= 0
    error('i31w:MATLABRequired','This experiment requires MATLAB.');
  end

  timer = tic;
  c = LOCAL_config();
  result = LOCAL_empty_result(char(attempt),c);
  peak_mib = 0;
  try
    % --- stage 1: frozen finite-dimensional input ---
    rows = LOCAL_selectors();
    [seed,frame] = eval_i21('seed',c,rows);
    LOCAL_seed_gate(seed,frame,c);
    node = eval_i21('point',c.khat,c,frame);
    LOCAL_point_gate(node,frame,c);
    finite = LOCAL_finite_input(node,c);
    result.finite_input = finite;
    peak_mib = max(peak_mib,LOCAL_mib({seed,frame,node,finite}));
    LOCAL_resource_gate(timer,peak_mib,c);

    % --- stage 2: frozen whole-subspace propagation ---
    prop = LOCAL_propagation(node,c);
    result.propagation = prop.record;
    if ~prop.record.pass
      error('i31w:Propagation','The frozen whole-subspace action gate failed.');
    end
    coords = LOCAL_coordinates(node,finite.q,prop,c);
    result.coordinates = coords;
    peak_mib = max(peak_mib,LOCAL_mib({seed,frame,node,finite,prop,coords}));
    LOCAL_resource_gate(timer,peak_mib,c);
    LOCAL_soft_gate(timer,c,'Q1/RT0 reconstruction');

    % --- stage 3: two complete Q1--RT0 levels ---
    computed = repmat(LOCAL_empty_level(),numel(c.fe_levels),1);
    for j = 1:numel(c.fe_levels)
      fe = i31_fe_cell(c,node,coords,prop,c.fe_levels(j),1);
      computed(j).name = c.fe_levels(j).name;
      computed(j).finite_element = fe;
      result.levels = computed(1:j);
      LOCAL_fe_gates(fe,c);
      tm = LOCAL_tail(prop.Pminus,fe.tail.minus,coords.cminus,c);
      tp = LOCAL_tail(prop.Pplus,fe.tail.plus,coords.cplus,c);
      computed(j).tail = struct('minus',tm.record,'plus',tp.record);
      result.levels = computed(1:j);
      if ~(tm.record.pass&&tp.record.pass)
        error('i31w:InfiniteTail','A base-level full-matrix tail gate failed.');
      end
      total = LOCAL_total(fe,tm,tp,c);
      if ~total.valid
        error('i31w:MajorantQuadrature','A global majorant or field norm is invalid.');
      end
      computed(j).total = total;
      result.levels = computed(1:j);
      peak_mib = max(peak_mib,LOCAL_mib({seed,frame,node,finite,prop,coords, ...
        computed})+fe.peak_local_workspace_mib+max(tm.active_mib,tp.active_mib));
      LOCAL_resource_gate(timer,peak_mib,c);
    end
    result.levels = computed;
    LOCAL_soft_gate(timer,c,'phase/scale repeat');

    % --- stage 4: independent phase/scale recomputation ---
    scaled_fe = i31_fe_cell(c,node,coords,prop,c.fe_levels(end),c.scale_oracle);
    result.phase_scale = struct('pass',false,'finite_element',scaled_fe);
    LOCAL_fe_gates(scaled_fe,c);
    scaled_tm = LOCAL_tail(prop.Pminus,scaled_fe.tail.minus, ...
      c.scale_oracle*coords.cminus,c);
    scaled_tp = LOCAL_tail(prop.Pplus,scaled_fe.tail.plus, ...
      c.scale_oracle*coords.cplus,c);
    result.phase_scale.tail_minus = scaled_tm.record;
    result.phase_scale.tail_plus = scaled_tp.record;
    if ~(scaled_tm.record.pass&&scaled_tp.record.pass)
      error('i31w:InfiniteTail','The phase/scale full-matrix tail gate failed.');
    end
    scaled_total = LOCAL_total(scaled_fe,scaled_tm,scaled_tp,c);
    if ~scaled_total.valid
      error('i31w:MajorantQuadrature','The phase/scale majorant is invalid.');
    end
    fine = computed(end).total;
    phase_defect = abs(scaled_total.q-fine.q)/max(realmin,abs(fine.q));
    result.phase_scale = struct('multiplier',c.scale_oracle, ...
      'computed_q',scaled_total.q,'relative_defect',phase_defect, ...
      'pass',isfinite(phase_defect)&&phase_defect<=c.scale_relative_max, ...
      'tail_minus',scaled_tm.record,'tail_plus',scaled_tp.record);
    peak_mib = max(peak_mib,LOCAL_mib({seed,frame,node,finite,prop,coords, ...
      computed,scaled_fe})+scaled_fe.peak_local_workspace_mib+ ...
      max(scaled_tm.active_mib,scaled_tp.active_mib));
    LOCAL_resource_gate(timer,peak_mib,c);

    % --- stage 5: refinement, tail, and resolution semantics ---
    refinement = LOCAL_refinement(computed(1).total,computed(2).total, ...
      [computed.finite_element],result.phase_scale,c);
    result.refinement = refinement;
    result.estimator = LOCAL_estimator(fine,c);
    if ~refinement.pass
      error('i31w:MeshResolution','The frozen mesh/refinement gate failed.');
    end
    result.coverage = LOCAL_coverage();
    result.continuous_form_residual_computed = true;
    result.functional_majorant_formula_applied = true;
    coarse = computed(1).total;
    intervals_available = coarse.interval_defined&&fine.interval_defined&& ...
      isfinite(coarse.nominal_k_width)&&isfinite(fine.nominal_k_width);
    if ~intervals_available || fine.nominal_k_width>c.tau_k_pre
      error('i31w:WeakResidual','The computed nominal interval lacks the frozen resolution.');
    end
    result.execution_pass = true;
    result.indicator_available = true;
    result.status = 'I3_1_COMPUTED_CONTINUOUS_WEAK_RESIDUAL_ESTIMATOR_CANDIDATE';
    result.scientific_outcome = ...
      'COMPUTED_CONTINUOUS_WEAK_RESIDUAL_ESTIMATOR_CANDIDATE';
    result.first_failure = LOCAL_failure('RELIABLE_SPECTRAL_INTERVAL_UNAVAILABLE', ...
      'RELIABILITY','Ordinary-double residual, field norm, and tail are not outward-enclosed.', ...
      'i31w:Reliability');
  catch ME
    result = LOCAL_fail(result,ME);
  end

  result.elapsed_seconds = toc(timer);
  result.peak_active_mib = peak_mib;
  result.soft_time_exceeded = result.elapsed_seconds>c.soft_seconds;
  if result.elapsed_seconds>c.hard_seconds || peak_mib>c.memory_mib_max
    result.execution_pass = false;
    result.indicator_available = false;
    if isstruct(result.estimator), result.estimator.available = false; end
    result.status = 'I3_1_EXECUTION_UNAVAILABLE';
    result.scientific_outcome = 'UNAVAILABLE';
    result.first_failure = LOCAL_failure('EXECUTION_UNAVAILABLE','RESOURCE', ...
      'The hard time or active-object memory limit was exceeded.','i31w:Resource');
  end
  if exist(output,'dir') || exist(output,'file')
    error('i31w:OutputExists','Output appeared during the run: %s.',output);
  end
  mkdir(output);
  save(fullfile(output,'result.mat'),'result','-v7');
  LOCAL_report(fullfile(output,'report.md'),result);
end

%% ==================== Frozen runtime contract ====================
% Every scientific parameter needed by the producer lives in MATLAB source.

function c = LOCAL_config()
  c = struct('schema','TEP_I3_1_Q1_RT0_WEAK_RESIDUAL_V2', ...
    'beta',0.5,'d',1.0,'R',0.2,'s',1.0,'rho_disk',17, ...
    'X_L',-0.5,'X_R',0.5,'H',1.1,'proxy_dist',0.2, ...
    'M',48,'K',97,'kstar',1.8327703475952146, ...
    'khat',1.832770289108157,'tau_k_pre',1e-6,'rho_G_pre',0.1, ...
    'cell_rcond_min',1e-10,'cell_solve_residual_max',1e-10, ...
    'action_rcond_min',1e-8,'action_residual_max',1e-10, ...
    'form_defect_max',1e-12,'hdiv_defect_max',1e-12, ...
    'disk_area_tol',1e-12,'gram_hermitian_max',1e-12, ...
    'gram_psd_scale',1e-12,'component_relative_max',0.20, ...
    'scale_oracle',1e8*exp(1i*pi/7),'scale_relative_max',1e-11, ...
    'tail_share_max',1e-6,'tail_max_power',12, ...
    'soft_seconds',900,'hard_seconds',1800,'memory_mib_max',512);
  c.mu_h = c.khat^2; c.gamma = c.mu_h;
  c.fe_levels = [struct('name','coarse','Nx',64,'Ny',128,'Nr',32, ...
    'Ntheta',128),struct('name','fine','Nx',96,'Ny',192,'Nr',48, ...
    'Ntheta',192)];
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
  c.command = ...
    "matlab -batch ""addpath(fullfile(pwd,'test','i3','w-resid'),fullfile(pwd,'test','i2','k-count')); check_w_resid('weak-a1');""";
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
% These checks reproduce the minimum I2 object without changing its evaluator.

function LOCAL_seed_gate(seed,frame,c)
  ok = seed.k==c.kstar && seed.pass && all([seed.factors.pass]) && ...
    isequal(size(seed.Aqp),[512,512]) && isequal(size(seed.AdefD),[194,194]) && ...
    isequal(size(frame.Z0_plus),[194,97]) && ...
    isequal(size(frame.Z0_minus),[194,97]) && frame.proxy_chart.r==260;
  if ~ok
    error('i31w:FiniteInput','The frozen seed/frame gate failed.');
  end
end

function LOCAL_point_gate(node,frame,c)
  ok = node.k==c.khat && strcmp(node.name,'fine') && ...
    node.spec.ntot==256 && node.pass && node.plus.pass && node.minus.pass && ...
    node.branch_port.pass && node.branch_proxy.pass && node.cp.safe && ...
    node.cm.safe && all([node.factors.pass]) && ...
    isequal(node.H_plus_rows,frame.rows_plus) && ...
    isequal(node.H_minus_rows,frame.rows_minus) && ...
    isequal(size(node.AdefD),[194,194]) && ...
    isequal(size(node.AdefG),[388,388]) && all(isfinite(node.beta_m)) && ...
    all(isfinite(node.gamma));
  if ~ok
    error('i31w:FiniteInput','The saved-candidate point gate failed.');
  end
end

function out = LOCAL_finite_input(node,c)
  beta = node.beta_m(:); gamma = node.gamma(:);
  b = sqrt(1+abs(beta).^2);
  wr = repmat(sqrt(1./b),2,1);
  wc = repmat(1./sqrt(b+abs(gamma).^2./b),2,1);
  B = wr.*node.AdefD.*wc.';
  [~,S,V] = svd(B,'econ'); singular = diag(S);
  qraw = wc.*V(:,end);
  if any(~isfinite(qraw)) || norm(qraw)==0
    error('i31w:FiniteInput','The physical near-null vector is unavailable.');
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

%% ==================== Whole-subspace propagation ====================
% Recover P-plus and P-minus without recomputing or diagonalizing the QZ basis.

function out = LOCAL_propagation(node,c)
  plus = LOCAL_action(node.pair.A,node.pair.B,node.Zp,false,c);
  minus = LOCAL_action(node.pair.A,node.pair.B,node.Zm,true,c);
  K = c.K;
  Ap = node.Zp(1:K,:); Bp = node.Zp(K+1:end,:);
  Am = node.Zm(1:K,:); Bm = node.Zm(K+1:end,:);
  Dplus = Ap+Bp; Dminus = Am+Bm;
  map_defects = [norm(Dplus-node.Dp,'fro')/max(1,norm(node.Dp,'fro')), ...
    norm(Dminus-node.Dm,'fro')/max(1,norm(node.Dm,'fro'))];
  left_global_dx = norm(1i*diag(node.gamma(:))*(Am-Bm)+node.Nm,'fro')/ ...
    max(1,norm(node.Nm,'fro'));
  out = struct('Pplus',plus.P,'Pminus',minus.P, ...
    'Dplus',Dplus,'Dminus',Dminus,'record',struct('pass', ...
    plus.pass&&minus.pass&&max(map_defects)<=1e-13&&left_global_dx<=1e-13, ...
    'plus',LOCAL_drop(plus,{'P'}),'minus',LOCAL_drop(minus,{'P'}), ...
    'trace_map_defects',map_defects,'left_global_dx_defect',left_global_dx));
end

function out = LOCAL_action(A,B,Z,reversed,c)
  if reversed, C=A*Z; rhs=B*Z; else, C=B*Z; rhs=A*Z; end
  [~,R] = qr(C,0); r = rank(R); rc = rcond(R); P = C\rhs;
  solve_residual = norm(C*P-rhs,'fro')/ ...
    max([1,norm(C,'fro')*norm(P,2)+norm(rhs,'fro')]);
  if reversed
    invariant = norm(B*Z-A*Z*P,'fro')/ ...
      max([1,norm(B*Z,'fro')+norm(A*Z,'fro')*norm(P,2)]);
  else
    invariant = norm(A*Z-B*Z*P,'fro')/ ...
      max([1,norm(A*Z,'fro')+norm(B*Z,'fro')*norm(P,2)]);
  end
  finite = all(isfinite(P),'all')&&all(isfinite([rc,solve_residual,invariant]));
  out = struct('P',P,'rank',r,'thin_qr_rcond',rc, ...
    'solve_residual',solve_residual,'invariant_residual',invariant, ...
    'pass',finite&&r==c.K&&rc>=c.action_rcond_min&& ...
    solve_residual<=c.action_residual_max&&invariant<=c.action_residual_max);
end

function out = LOCAL_coordinates(node,q,prop,c)
  K = c.K; I = eye(K); E = diag(node.phase(:));
  cm = node.Dm\([I,E]*q); cp = node.Dp\([E,I]*q);
  rm = norm(node.Dm*cm-[I,E]*q)/max(1,norm([I,E]*q));
  rp = norm(node.Dp*cp-[E,I]*q)/max(1,norm([E,I]*q));
  if any(~isfinite([cm;cp])) || max(rm,rp)>c.action_residual_max
    error('i31w:Propagation','The frozen coordinate solve failed.');
  end
  out = struct('q',q,'cminus',cm,'cplus',cp,'q_norm',norm(q), ...
    'cminus_norm',norm(cm),'cplus_norm',norm(cp), ...
    'minus_solve_residual',rm,'plus_solve_residual',rp, ...
    'Pminus_norm',norm(prop.Pminus,2),'Pplus_norm',norm(prop.Pplus,2));
end

%% ==================== Q1--RT0 gates ====================
% Gate ordering follows the reviewed failure precedence exactly.

function LOCAL_fe_gates(fe,c)
  factors = [fe.factor.lead.pass,fe.factor.center.pass, ...
    fe.factor.plus_solve.pass,fe.factor.minus_solve.pass, ...
    fe.factor.center_solve.pass,fe.integration.lead.disk_object_pass, ...
    fe.integration.center.disk_object_pass];
  if ~all(factors)
    error('i31w:CellExtension','A physical Q1 cell-extension gate failed.');
  end
  if ~fe.form.pass || fe.form.maximum_defect>c.form_defect_max
    error('i31w:FormConformity','The global Q1 form-conformity gate failed.');
  end
  if ~fe.hdiv.pass || fe.hdiv.maximum_defect>c.hdiv_defect_max
    error('i31w:HdivFlux','The global RT0 normal-continuity gate failed.');
  end
  if ~fe.finite_pass
    error('i31w:MajorantQuadrature','A majorant or field-norm integral is nonfinite.');
  end
  if ~fe.gram_pass
    error('i31w:MajorantQuadrature','A per-cell Gram Hermitian/PSD gate failed.');
  end
end

%% ==================== Full-matrix infinite tails ====================
% Association repeats retain nonnormal and Jordan effects in ordinary double.

function out = LOCAL_tail(P,grams,c0,c)
  names = {'N','A','B','M'};
  base = {grams.N,grams.A,grams.B,grams.A+grams.B/c.gamma};
  WL = base; WR = base; pN = P; powers = cell(c.tail_max_power+1,1);
  rows = repmat(LOCAL_empty_tail_row(),c.tail_max_power+1,1);
  selected = NaN; active_mib = 0;
  for j = 0:c.tail_max_power
    N = 2^j; powers{j+1} = pN;
    alternate = LOCAL_alternate_power(P,powers,j);
    association = norm(pN-alternate,2);
    pscale = max([1,norm(pN,2),norm(alternate,2)]);
    power_allowance = association+100*c.K*eps*pscale;
    ahi = norm(pN,2)+power_allowance;
    sums = zeros(1,4); omega = zeros(1,4);
    allowance = Inf(1,4); shares = Inf(1,4);
    for k = 1:4
      wscale = max([1,norm(WL{k},2),norm(WR{k},2)]);
      omega(k) = norm(WL{k}-WR{k},2)+100*c.K*eps*wscale;
      sums(k) = real(c0'*WL{k}*c0);
      if isfinite(ahi)&&ahi<1
        allowance(k) = ahi^2/(1-ahi^2)*(norm(WL{k},2)+omega(k))*norm(c0)^2;
        shares(k) = allowance(k)/max(realmin,sums(k));
      end
    end
    finite = all(isfinite([ahi,sums,omega,allowance,shares]));
    pass = finite&&ahi<1&&all(sums([1,4])>0)&& ...
      all(shares([1,4])<=c.tail_share_max);
    rows(j+1) = struct('N',N,'power_norm',norm(pN,2), ...
      'power_association_defect',association,'power_allowance',power_allowance, ...
      'a_hi',ahi,'finite_sums',sums,'gram_allowances',omega, ...
      'tail_allowances',allowance,'tail_shares',shares,'pass',pass);
    info = whos; active_mib = max(active_mib,sum([info.bytes])/2^20);
    if pass&&isnan(selected), selected=j+1; end
    if j==c.tail_max_power, break; end
    oldP = pN; pN = oldP*oldP;
    for k = 1:4
      WL{k} = WL{k}+(oldP'*WL{k})*oldP;
      WR{k} = WR{k}+oldP'*(WR{k}*oldP);
    end
  end
  if isnan(selected), chosen = rows(end); pass = false;
  else, chosen = rows(selected); pass = true; end
  out = struct('chosen',chosen,'active_mib',active_mib,'record',struct( ...
    'pass',pass,'gram_names',{names},'levels',rows, ...
    'selected_index',selected,'selected_N',chosen.N, ...
    'peak_local_workspace_mib',active_mib,'tail_diagnostic_certified',false));
end

function alternate = LOCAL_alternate_power(P,powers,j)
  if j<3
    count = 2^j; alternate = P;
    for k = 2:count, alternate = alternate*P; end
  else
    base = powers{j-2}; alternate = base;
    for k = 2:8, alternate = alternate*base; end
  end
end

function row = LOCAL_empty_tail_row()
  row = struct('N',NaN,'power_norm',NaN,'power_association_defect',NaN, ...
    'power_allowance',NaN,'a_hi',NaN,'finite_sums',NaN(1,4), ...
    'gram_allowances',NaN(1,4),'tail_allowances',NaN(1,4), ...
    'tail_shares',NaN(1,4),'pass',false);
end

%% ==================== Estimator and refinement ====================
% Nominal intervals use the theorem's asymmetric inverse but remain uncertified.

function out = LOCAL_total(fe,tm,tp,c)
  base = [fe.center.N+fe.first.minus.N+fe.first.plus.N, ...
    fe.center.A+fe.first.minus.A+fe.first.plus.A, ...
    fe.center.B+fe.first.minus.B+fe.first.plus.B];
  tail = tm.chosen.finite_sums(1:3)+tp.chosen.finite_sums(1:3);
  values = real(base+tail); N = values(1); A = values(2); B = values(3);
  M2 = A+B/c.gamma;
  valid = all(isfinite([N,A,B,M2]))&&N>0&&A>=0&&B>=0&&M2>=0;
  q = NaN;
  if valid, q = sqrt(M2/N); end
  interval_defined = isfinite(q)&&q<1;
  lambda_interval = [NaN,NaN]; k_interval = [NaN,NaN]; width = NaN;
  if interval_defined
    lambda_interval = [max(0,(c.mu_h-q*c.gamma)/(1+q)), ...
      (c.mu_h+q*c.gamma)/(1-q)];
    k_interval = sqrt(lambda_interval); width = diff(k_interval);
  end
  out = struct('valid',valid,'N2',N,'A2',A,'B2',B,'M2',M2,'q',q, ...
    'interval_defined',interval_defined,'nominal_lambda_interval', ...
    lambda_interval,'nominal_k_interval',k_interval, ...
    'nominal_k_width',width,'tail_minus_N_M_shares', ...
    tm.chosen.tail_shares([1,4]),'tail_plus_N_M_shares', ...
    tp.chosen.tail_shares([1,4]));
end

function out = LOCAL_refinement(coarse,fine,fe,phase,c)
  denom = max([coarse.M2,fine.M2,realmin]);
  changes = [abs(fine.A2-coarse.A2)/denom, ...
    abs(fine.B2/c.gamma-coarse.B2/c.gamma)/denom, ...
    abs(fine.N2-coarse.N2)/max([fine.N2,coarse.N2,realmin])];
  if coarse.interval_defined&&fine.interval_defined
    width_status = 'APPLIED';
    width_change = abs(fine.nominal_k_width-coarse.nominal_k_width);
    width_limit = max(0.20*fine.nominal_k_width,0.10*c.tau_k_pre);
    width_pass = isfinite(width_change)&&width_change<=width_limit;
  else
    width_status = 'NOT_APPLICABLE'; width_change = NaN;
    width_limit = NaN; width_pass = true;
  end
  gram_pass = all([fe.gram_pass]);
  component_pass = all(isfinite(changes))&&all(changes<=c.component_relative_max);
  out = struct('component_changes',changes,'component_pass',component_pass, ...
    'width_status',width_status,'width_change',width_change, ...
    'width_limit',width_limit,'width_pass',width_pass, ...
    'gram_pass',gram_pass,'phase_scale_pass',phase.pass, ...
    'pass',component_pass&&width_pass&&gram_pass&&phase.pass);
end

function out = LOCAL_estimator(fine,c)
  out = struct('available',fine.valid,'computed_q',fine.q, ...
    'computed_field_norm',sqrt(max(0,fine.N2)), ...
    'computed_majorant',sqrt(max(0,fine.M2)), ...
    'computed_A_component',sqrt(max(0,fine.A2)), ...
    'computed_B_component',sqrt(max(0,fine.B2)), ...
    'nominal_lambda_interval',fine.nominal_lambda_interval, ...
    'nominal_k_interval',fine.nominal_k_interval, ...
    'nominal_k_width',fine.nominal_k_width, ...
    'absolute_resolution_pass',fine.interval_defined&& ...
    fine.nominal_k_width<=c.tau_k_pre, ...
    'residual_upper_bound_certified',false, ...
    'field_lower_bound_certified',false,'tail_diagnostic_certified',false, ...
    'projected_gap_established',false, ...
    'reliability_status','RELIABLE_SPECTRAL_INTERVAL_UNAVAILABLE', ...
    'projected_gap_status','PROJECTED_GAP_NOT_ESTABLISHED', ...
    'continuous_discrete_eigenvalue_existence',false, ...
    'continuous_error_bound',false);
end

function out = LOCAL_coverage()
  out = struct('global_conforming_trial',true,'sharp_material_volume',true, ...
    'cell_walls',true,'y_quasiperiodicity',true,'infinite_tail',true, ...
    'reliable_numerical_enclosure',false,'projected_gap',false, ...
    'unique_target',false,'continuous_error_upper_bound',false);
end

function out = LOCAL_empty_level()
  out = struct('name','','finite_element',struct(),'tail',struct(), ...
    'total',struct());
end

%% ==================== Result and failure semantics ====================
% The first failure preserves every diagnostic computed before that gate.

function result = LOCAL_empty_result(attempt,c)
  result = struct('schema',c.schema,'attempt',attempt,'candidate',c.khat, ...
    'mu_h',c.mu_h,'config',c,'command',c.command,'execution_pass',false, ...
    'indicator_available',false,'status','I3_1_NOT_RUN', ...
    'scientific_outcome','UNAVAILABLE','finite_input',struct(), ...
    'propagation',struct(),'coordinates',struct(),'levels',struct([]), ...
    'phase_scale',struct(),'refinement',struct(), ...
    'estimator',struct('available',false),'coverage',LOCAL_empty_coverage(), ...
    'continuous_form_residual_computed',false, ...
    'functional_majorant_formula_applied',false, ...
    'first_failure',LOCAL_failure('NOT_RUN','STARTUP', ...
    'No computation has completed.',''),'elapsed_seconds',NaN, ...
    'peak_active_mib',NaN,'soft_time_exceeded',false,'retry_count',0, ...
    'retry_history',strings(0,1));
end

function out = LOCAL_empty_coverage()
  out = struct('global_conforming_trial',false,'sharp_material_volume',false, ...
    'cell_walls',false,'y_quasiperiodicity',false,'infinite_tail',false, ...
    'reliable_numerical_enclosure',false,'projected_gap',false, ...
    'unique_target',false,'continuous_error_upper_bound',false);
end

function result = LOCAL_fail(result,ME)
  [code,category] = LOCAL_failure_code(ME.identifier);
  result.first_failure = LOCAL_failure(code,category,ME.message,ME.identifier);
  result.scientific_outcome = code; result.status = ['I3_1_',code];
  result.execution_pass = ~strcmp(code,'EXECUTION_UNAVAILABLE');
  if strcmp(code,'FINITE_DISCRETE_INPUT_UNAVAILABLE') || ...
      strcmp(code,'PROPAGATION_ACTION_UNRESOLVED') || ...
      strcmp(code,'CELL_EXTENSION_UNRESOLVED') || ...
      strcmp(code,'FORM_CONFORMITY_UNRESOLVED') || ...
      strcmp(code,'HDIV_FLUX_UNRESOLVED') || ...
      strcmp(code,'MAJORANT_QUADRATURE_UNRESOLVED') || ...
      strcmp(code,'MESH_RESOLUTION_UNRESOLVED') || ...
      strcmp(code,'INFINITE_TAIL_UNRESOLVED')
    result.indicator_available = false;
    result.estimator.available = false;
  elseif strcmp(code,'WEAK_RESIDUAL_RESOLUTION_INSUFFICIENT')
    result.indicator_available = isfield(result.estimator,'computed_q') && ...
      isfinite(result.estimator.computed_q);
  else
    result.indicator_available = false;
    result.estimator.available = false;
  end
end

function [code,category] = LOCAL_failure_code(id)
  if startsWith(id,'i31w:FiniteInput')
    code='FINITE_DISCRETE_INPUT_UNAVAILABLE'; category='FINITE_INPUT';
  elseif startsWith(id,'i31w:Propagation')
    code='PROPAGATION_ACTION_UNRESOLVED'; category='PROPAGATION';
  elseif startsWith(id,'i31w:CellExtension')
    code='CELL_EXTENSION_UNRESOLVED'; category='CELL_EXTENSION';
  elseif startsWith(id,'i31w:FormConformity')
    code='FORM_CONFORMITY_UNRESOLVED'; category='FORM_CONFORMITY';
  elseif startsWith(id,'i31w:HdivFlux')
    code='HDIV_FLUX_UNRESOLVED'; category='HDIV_FLUX';
  elseif startsWith(id,'i31w:MajorantQuadrature')
    code='MAJORANT_QUADRATURE_UNRESOLVED'; category='MAJORANT_QUADRATURE';
  elseif startsWith(id,'i31w:MeshResolution')
    code='MESH_RESOLUTION_UNRESOLVED'; category='MESH_RESOLUTION';
  elseif startsWith(id,'i31w:InfiniteTail')
    code='INFINITE_TAIL_UNRESOLVED'; category='INFINITE_TAIL';
  elseif startsWith(id,'i31w:WeakResidual')
    code='WEAK_RESIDUAL_RESOLUTION_INSUFFICIENT'; category='RESOLUTION';
  else
    code='EXECUTION_UNAVAILABLE'; category='EXECUTION';
  end
end

function out = LOCAL_failure(code,category,message,identifier)
  out = struct('code',code,'category',category,'message',message, ...
    'identifier',identifier);
end

function LOCAL_soft_gate(timer,c,next_stage)
  if toc(timer)>c.soft_seconds
    error('i31w:Resource','Soft time reached before %s.',next_stage);
  end
end

function LOCAL_resource_gate(timer,peak_mib,c)
  if toc(timer)>c.hard_seconds || peak_mib>c.memory_mib_max
    error('i31w:Resource','The hard time or active-object memory limit was exceeded.');
  end
end

function mib = LOCAL_mib(values)
  mib = 0;
  for j = 1:numel(values)
    item = values{j}; info = whos('item'); mib = mib+info.bytes/2^20;
  end
end

function out = LOCAL_drop(in,names)
  out = in;
  for j = 1:numel(names)
    if isfield(out,names{j}), out = rmfield(out,names{j}); end
  end
end

function LOCAL_report(path,r)
  fid = fopen(path,'w');
  if fid<0, error('i31w:Report','Cannot open report.md.'); end
  cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid,'# I3.1 conforming weak residual\n\n');
  fprintf(fid,'- Attempt: %s\n',r.attempt);
  fprintf(fid,'- Status: %s\n',r.status);
  fprintf(fid,'- First unavailable condition: %s\n',r.first_failure.code);
  fprintf(fid,'- Saved candidate: %.15f\n',r.candidate);
  fprintf(fid,'- Elapsed seconds: %.6f\n',r.elapsed_seconds);
  fprintf(fid,'- Peak active-object MiB: %.6f\n',r.peak_active_mib);
  if isfield(r.estimator,'computed_q')
    fprintf(fid,'- Computed shifted residual ratio: %.17g\n',r.estimator.computed_q);
    fprintf(fid,'- Computed majorant: %.17g\n',r.estimator.computed_majorant);
    if all(isfinite(r.estimator.nominal_k_interval))
      fprintf(fid,'- Nominal k interval: [%.17g, %.17g]\n', ...
        r.estimator.nominal_k_interval);
      fprintf(fid,'- Nominal k width: %.17g\n',r.estimator.nominal_k_width);
    end
  end
  fprintf(fid,'\nThe Q1 field and RT0 flux target the continuous weak residual. ');
  fprintf(fid,['All quadrature, factor, and tail values use ordinary double ', ...
    'precision; they are not outward bounds. No projected gap, continuous ', ...
    'discrete-eigenvalue existence, unique mode identity, or continuous ', ...
    'error upper bound is claimed.\n']);
end
