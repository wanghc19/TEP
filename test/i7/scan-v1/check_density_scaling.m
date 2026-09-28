function result = check_density_scaling(output,phase_label,k_values)
%CHECK_DENSITY_SCALING Compare legacy and physical-density BIE solves.
% Purpose:
%   Measure the I7.1 effect of applying the square-root quadrature density
%   coordinate consistently in bloch.construct_S.
% Input:
%   output      - Explicit monitored-run directory for point evidence.
%   phase_label - Short label, normally 'before' or 'after'.
%   k_values    - Optional finite real row vector.  The default retains the
%                 three frozen comparison points.
% Output:
%   result      - Compact circle control and finite-point comparison data.
% Main algorithm:
%   Compare the currently resolved public solve with the correctly scaled
%   solve and an independent raw-coordinate physical-density solve.  Compare
%   physical scattering blocks, left/right outgoing wall coefficients, the
%   four I7.1 matching metrics, and dH=norm(Hmatch-Hsym,2).
% Based on:
%   test/i7/scan-v1/locate_i7.m and test/i7/inertia-v1/check_i7_inertia.m.
% Numerical goal:
%   Preserve a before/after diagnostic independent of the public solve path.

  if nargin < 2 || nargin > 3 || ~isfolder(output)
    error('i7:DensityArguments', ...
      'Pass an existing output directory and a phase label.');
  end
  phase_label = char(phase_label);
  if isempty(phase_label)
    error('i7:DensityPhase','phase_label must be nonempty.');
  end
  if nargin < 3
    k_values = [1.753125,1.7545053299700002,1.75625];
  end
  if isempty(k_values) || ~isvector(k_values) || ~isreal(k_values) || ...
      any(~isfinite(k_values))
    error('i7:DensityWavenumbers', ...
      'k_values must be a nonempty finite real vector.');
  end
  k_values = k_values(:).';

  model = struct('beta',0.5,'d',1,'R',0.2,'epsrel',17, ...
    'epsrel_center',2,'XL',-0.5,'XR',0.5,'H',1.1,'pdist',0.2, ...
    'flag_geom','ellipse','ellipse_axes',[0.25,0.16]);
  cfg = struct('ntot',256,'nside',160,'ntop',160, ...
    'nproxy',80,'mpw',32);
  M = 48;
  warning_guard = LOCAL_solver_warning_guard();
  tstart = tic;

  result = struct('phase_label',phase_label,'model',model,'cfg',cfg, ...
    'M',M,'k_values',k_values,'circle_control',struct(), ...
    'points',repmat(LOCAL_empty_point(),numel(k_values),1), ...
    'runtime',NaN);

  for j = 1:numel(k_values)
    point_timer = tic;
    k = k_values(j);
    [lead_public,chans,bm,gamma] = LOCAL_cellmap(k,M,model,cfg,'circle');
    lead_correct = LOCAL_resolve_physical(lead_public);
    center_public = LOCAL_cellmap(k,M,model,cfg,'ellipse');
    center_correct = LOCAL_resolve_physical(center_public);

    public_point = LOCAL_matching(lead_public,center_public,bm,gamma);
    correct_point = LOCAL_matching(lead_correct,center_correct,bm,gamma);
    point = LOCAL_empty_point();
    point.k = k;
    point.public_metrics = public_point.metrics;
    point.correct_metrics = correct_point.metrics;
    point.public_dH = public_point.dH;
    point.correct_dH = correct_point.dH;
    point.public_eta = public_point.eta;
    point.correct_eta = correct_point.eta;
    point.public_counts = public_point.counts;
    point.correct_counts = correct_point.counts;
    point.center_defects = LOCAL_cellmap_defects(center_public,center_correct);
    point.lead_defects = LOCAL_cellmap_defects(lead_public,lead_correct);
    point.metric_max_abs_difference = max(abs( ...
      public_point.metrics-correct_point.metrics));
    point.dH_abs_difference = abs(public_point.dH-correct_point.dH);
    point.seconds = toc(point_timer);
    result.points(j) = point;

    evidence = struct('k',k,'lead_public',lead_public, ...
      'lead_correct',lead_correct,'center_public',center_public, ...
      'center_correct',center_correct,'public_matching',public_point, ...
      'correct_matching',correct_point);
    save(fullfile(output,sprintf('density-point-%02d.mat',j)), ...
      'evidence','-v7.3');
    fprintf(1,['density-%s k=%.17g Sdefect=%.6e metricdefect=%.6e ', ...
      'dHpublic=%.6e dHcorrect=%.6e seconds=%.3f\n'], ...
      phase_label,k,point.center_defects.S_relative, ...
      point.metric_max_abs_difference,point.public_dH, ...
      point.correct_dH,point.seconds);

    if j == min(2,numel(k_values))
      result.circle_control = point.lead_defects;
      result.circle_control.k = k;
      save(fullfile(output,'circle-control.mat'),'lead_public', ...
        'lead_correct','-v7.3');
    end
  end

  clear warning_guard;
  result.runtime = toc(tstart);
  result.coordinate_tolerance = 1000*(2*cfg.ntot)*eps;
  result.validation_tolerance = 1e-11;
  result.max_circle_defect = max([result.circle_control.S_relative, ...
    result.circle_control.left_wall_relative, ...
    result.circle_control.right_wall_relative, ...
    result.circle_control.density_relative]);
  result.max_ellipse_S_defect = max(arrayfun( ...
    @(point) point.center_defects.S_relative,result.points));
  result.max_independent_defect = max(arrayfun(@(point) max([ ...
    point.center_defects.independent_S_relative, ...
    point.center_defects.independent_left_wall_relative, ...
    point.center_defects.independent_right_wall_relative, ...
    point.center_defects.independent_density_relative, ...
    point.lead_defects.independent_S_relative, ...
    point.lead_defects.independent_left_wall_relative, ...
    point.lead_defects.independent_right_wall_relative, ...
    point.lead_defects.independent_density_relative]),result.points));
  result.max_metric_difference = max([result.points.metric_max_abs_difference]);
  result.max_dH_difference = max([result.points.dH_abs_difference]);
  result.max_coordinate_residual = max(arrayfun(@(point) max([ ...
    point.center_defects.correct_scaled_residual, ...
    point.center_defects.correct_physical_residual, ...
    point.center_defects.correct_roundtrip, ...
    point.lead_defects.correct_scaled_residual, ...
    point.lead_defects.correct_physical_residual, ...
    point.lead_defects.correct_roundtrip]),result.points));
  public_defects = arrayfun(@(point) max([ ...
    point.center_defects.S_relative, ...
    point.center_defects.left_wall_relative, ...
    point.center_defects.right_wall_relative, ...
    point.center_defects.density_relative, ...
    point.lead_defects.S_relative, ...
    point.lead_defects.left_wall_relative, ...
    point.lead_defects.right_wall_relative, ...
    point.lead_defects.density_relative, ...
    point.metric_max_abs_difference,point.dH_abs_difference]),result.points);
  result.max_public_correct_defect = max(public_defects);
  result.circle_control_pass = result.max_circle_defect <= ...
    result.validation_tolerance && abs(result.circle_control.scale_ratio-1) ...
    <= result.validation_tolerance;
  result.independent_physical_pass = result.max_independent_defect <= ...
    result.validation_tolerance;
  result.coordinate_residual_pass = result.max_coordinate_residual <= ...
    result.validation_tolerance;
  result.ellipse_sensitivity_visible = max(arrayfun(@(point) max([ ...
    point.center_defects.S_relative, ...
    point.center_defects.left_wall_relative, ...
    point.center_defects.right_wall_relative]),result.points)) > ...
    100*result.coordinate_tolerance;
  result.public_matches_correct = result.max_public_correct_defect <= ...
    result.validation_tolerance;
end

%% ==================== Cell construction ====================
% These helpers isolate the legacy and physical-density scattering solves.

function [cellmap,chans,bm,gamma] = LOCAL_cellmap(k,M,model,cfg,shape)
%LOCAL_CELLMAP Construct one unchanged circular or elliptical cell.

  pars = struct('k',k,'beta',model.beta,'d',model.d, ...
    'periodic_axis','y','h2d_evaluator',@LOCAL_h2d_chunked_public);
  chans = bloch.rayleigh_channels( ...
    k,model.beta,model.d,M,model.XR-model.XL);
  if strcmp(shape,'circle')
    flag_geom = 'circle';
    shape_pars = model.R;
    epsrel = model.epsrel;
  elseif strcmp(shape,'ellipse')
    flag_geom = model.flag_geom;
    shape_pars = model.ellipse_axes;
    epsrel = model.epsrel_center;
  else
    error('i7:DensityShape','Unknown cell shape %s.',shape);
  end
  [C,curvelen] = geom.construct_cont( ...
    cfg.ntot,flag_geom,0,0,shape_pars);
  mfscfg = struct('H',model.H,'proxy_dist',model.pdist, ...
    'N_side',cfg.nside,'N_top',cfg.ntop, ...
    'N_proxy_edge',cfg.nproxy,'M_pw',cfg.mpw);
  proxy = kernel.precomp_proxy(pars,mfscfg);
  cellmap = bloch.construct_S(C,k,sqrt(epsrel)*k,pars,proxy, ...
    curvelen,chans,model.XL,model.XR);
  bm = chans.beta_m(:);
  gamma = chans.gamma_m(:);
end

function cellmap = LOCAL_resolve_physical(cellmap)
%LOCAL_RESOLVE_PHYSICAL Solve in scaled coordinates and return raw density.

  density_scale = sqrt(repmat(cellmap.far_aux.weights(:),2,1));
  rhs_physical = [cellmap.B_L,cellmap.B_R];
  rhs_scaled = density_scale.*rhs_physical;
  density_scaled = -(cellmap.A_QP\rhs_scaled);
  density_physical = density_scaled./density_scale;
  A_raw = (cellmap.A_QP.*density_scale.') ./ density_scale;
  density_independent = -(A_raw\rhs_physical);
  K = cellmap.K;
  H_L = density_physical(:,1:K);
  H_R = density_physical(:,K+1:2*K);
  E = cellmap.E;

  cellmap.H_L = H_L;
  cellmap.H_R = H_R;
  cellmap.R_L = full(complex(cellmap.F_L*H_L));
  cellmap.T_LR = full(complex(E+cellmap.F_R*H_L));
  cellmap.T_RL = full(complex(E+cellmap.F_L*H_R));
  cellmap.R_R = full(complex(cellmap.F_R*H_R));
  cellmap.S = full(complex([cellmap.R_L,cellmap.T_RL; ...
    cellmap.T_LR,cellmap.R_R]));
  cellmap.density_scale = density_scale;
  cellmap.H_scaled = density_scaled;
  cellmap.rhs_scaled = rhs_scaled;
  cellmap.A_raw = A_raw;
  cellmap.H_independent = density_independent;
  residual_scaled = cellmap.A_QP*density_scaled+rhs_scaled;
  residual_physical = residual_scaled./density_scale;
  cellmap.scaled_solve_relative_residual = norm(residual_scaled,'fro')/ ...
    max(1,norm(rhs_scaled,'fro'));
  cellmap.physical_solve_relative_residual = norm(residual_physical,'fro')/ ...
    max(1,norm(rhs_physical,'fro'));
  roundtrip = density_scale.*density_physical-density_scaled;
  cellmap.density_roundtrip_relative = norm(roundtrip,'fro')/ ...
    max(1,norm(density_scaled,'fro'));
  independent_L = density_independent(:,1:K);
  independent_R = density_independent(:,K+1:2*K);
  cellmap.independent_R_L = full(complex(cellmap.F_L*independent_L));
  cellmap.independent_T_LR = full(complex(E+cellmap.F_R*independent_L));
  cellmap.independent_T_RL = full(complex(E+cellmap.F_L*independent_R));
  cellmap.independent_R_R = full(complex(cellmap.F_R*independent_R));
  cellmap.independent_S = full(complex([cellmap.independent_R_L, ...
    cellmap.independent_T_RL;cellmap.independent_T_LR, ...
    cellmap.independent_R_R]));
end

function defects = LOCAL_cellmap_defects(public,correct)
%LOCAL_CELLMAP_DEFECTS Compare physical scattering and wall outputs.

  public_left = [public.F_L*public.H_L,public.F_L*public.H_R];
  public_right = [public.F_R*public.H_L,public.F_R*public.H_R];
  correct_left = [correct.F_L*correct.H_L,correct.F_L*correct.H_R];
  correct_right = [correct.F_R*correct.H_L,correct.F_R*correct.H_R];
  public_density = [public.H_L,public.H_R];
  correct_density = [correct.H_L,correct.H_R];
  independent_left = [correct.independent_R_L, ...
    correct.independent_T_RL-correct.E];
  independent_right = [correct.independent_T_LR-correct.E, ...
    correct.independent_R_R];
  defects = struct( ...
    'S_relative',LOCAL_relative(public.S,correct.S), ...
    'left_wall_relative',LOCAL_relative(public_left,correct_left), ...
    'right_wall_relative',LOCAL_relative(public_right,correct_right), ...
    'density_relative',LOCAL_relative(public_density,correct_density), ...
    'independent_S_relative', ...
      LOCAL_relative(correct.independent_S,correct.S), ...
    'independent_left_wall_relative', ...
      LOCAL_relative(independent_left,correct_left), ...
    'independent_right_wall_relative', ...
      LOCAL_relative(independent_right,correct_right), ...
    'independent_density_relative', ...
      LOCAL_relative(correct.H_independent,correct_density), ...
    'correct_scaled_residual',correct.scaled_solve_relative_residual, ...
    'correct_physical_residual',correct.physical_solve_relative_residual, ...
    'correct_roundtrip',correct.density_roundtrip_relative, ...
    'scale_ratio',max(correct.density_scale)/min(correct.density_scale));
end

%% ==================== Matching diagnostics ====================
% These helpers retain the approved QZ, DtN, and center matching formulas.

function point = LOCAL_matching(lead,center,bm,gamma)
%LOCAL_MATCHING Form the four I7.1 metrics and Hmatch non-Hermiticity.

  K = numel(gamma);
  A = [-lead.R_L,eye(K);lead.T_LR,zeros(K)];
  B = [zeros(K),lead.T_RL;eye(K),-lead.R_R];
  Zp = LOCAL_qzsub(A,B,K);
  Zm = LOCAL_qzsub(B,A,K);
  [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma);
  G = diag(gamma);
  Adef = [(1i*G-Lm)*center.R_L-(1i*G+Lm), ...
    (1i*G-Lm)*center.T_RL; ...
    (1i*G-Lp)*center.T_LR, ...
    (1i*G-Lp)*center.R_R-(1i*G+Lp)];
  Ttrace = [eye(K)+center.R_L,center.T_RL; ...
    center.T_LR,eye(K)+center.R_R];
  Hmatch = Adef/Ttrace;
  Hsym = (Hmatch+Hmatch')/2;
  Hscale = norm(Hsym,2);
  dH = norm(Hmatch-Hsym,2);
  eta = dH+100*size(Hsym,1)*eps*max(1,Hscale);
  eigenvalues = eig(Hsym,'vector');
  counts = [sum(eigenvalues > eta),sum(eigenvalues < -eta), ...
    sum(abs(eigenvalues) <= eta)];

  b = sqrt(1+abs(bm).^2);
  rowwt = repmat(sqrt(1./b),2,1);
  ampwt = b+abs(gamma).^2./b;
  colwt = repmat(1./sqrt(ampwt),2,1);
  Aphys = rowwt.*Adef.*colwt.';
  adef_svals = sort(svd(Adef,'econ'),'ascend');
  aphys_svals = sort(svd(Aphys,'econ'),'ascend');
  point = struct('metrics',[adef_svals(1), ...
    adef_svals(1)/adef_svals(end),aphys_svals(1), ...
    aphys_svals(1)/aphys_svals(end)], ...
    'dH',dH,'eta',eta,'counts',counts,'eigenvalues',eigenvalues, ...
    'T_rcond',rcond(Ttrace),'right_solve_residual', ...
    norm(Adef-Hmatch*Ttrace,'fro')/max(1,norm(Adef,'fro')), ...
    'Adef',Adef,'Aphys',Aphys,'T',Ttrace,'Hmatch',Hmatch, ...
    'Hsym',Hsym,'Lp',Lp,'Lm',Lm);
end

function Zs = LOCAL_qzsub(A,B,K)
%LOCAL_QZSUB Extract one qualified strictly stable generalized-Schur space.

  rho = hypot(norm(A,'fro'),norm(B,'fro'));
  if ~isfinite(rho) || rho == 0
    error('i7:QZScale','The QZ pencil scale is zero or nonfinite.');
  end
  A = A/rho;
  B = B/rho;
  [S,T,Q,Z] = qz(A,B,'complex');
  res = hypot(norm(A-Q'*S*Z','fro'),norm(B-Q'*T*Z','fro'));
  tol = max(100*eps,10*res);
  alpha = diag(S);
  theta = diag(T);
  scale = hypot(abs(alpha),abs(theta));
  indet = scale <= tol;
  scale(indet) = 1;
  an = abs(alpha)./scale;
  tn = abs(theta)./scale;
  infinite = ~indet & tn <= tol & an > tol;
  neutral = ~indet & ~infinite & abs(an-tn) <= tol;
  stable = ~indet & ~infinite & ~neutral & an < tn-tol;
  unstable = infinite | (~indet & ~neutral & an > tn+tol);
  if sum(stable) ~= K || sum(unstable) ~= K || any(indet) || any(neutral)
    error('i7:QZClassification', ...
      'stable=%d unstable=%d neutral=%d indet=%d expected=%d.', ...
      sum(stable),sum(unstable),sum(neutral),sum(indet),K);
  end
  [~,~,~,Zo] = ordqz(S,T,Q,Z,stable);
  Zs = Zo(:,1:K);
end

function [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma)
%LOCAL_DTN Convert the qualified half-guide subspaces to DtN maps.

  K = numel(gamma);
  G = diag(gamma);
  Ap = Zp(1:K,:);
  Bp = Zp(K+1:end,:);
  Am = Zm(1:K,:);
  Bm = Zm(K+1:end,:);
  Dp = Ap+Bp;
  Np = 1i*G*(Ap-Bp);
  Dm = Am+Bm;
  Nm = -1i*G*(Am-Bm);
  Lp = (Dp.'\Np.').';
  Lm = (Dm.'\Nm.').';
end

function point = LOCAL_empty_point()
%LOCAL_EMPTY_POINT Define the compact comparison schema.

  empty_defects = struct('S_relative',NaN,'left_wall_relative',NaN, ...
    'right_wall_relative',NaN,'density_relative',NaN, ...
    'independent_S_relative',NaN, ...
    'independent_left_wall_relative',NaN, ...
    'independent_right_wall_relative',NaN, ...
    'independent_density_relative',NaN, ...
    'correct_scaled_residual',NaN,'correct_physical_residual',NaN, ...
    'correct_roundtrip',NaN,'scale_ratio',NaN);
  point = struct('k',NaN,'public_metrics',nan(1,4), ...
    'correct_metrics',nan(1,4),'public_dH',NaN,'correct_dH',NaN, ...
    'public_eta',NaN,'correct_eta',NaN,'public_counts',zeros(1,3), ...
    'correct_counts',zeros(1,3), ...
    'center_defects',empty_defects,'lead_defects',empty_defects, ...
    'metric_max_abs_difference',NaN,'dH_abs_difference',NaN, ...
    'seconds',NaN);
end

function value = LOCAL_relative(actual,reference)
%LOCAL_RELATIVE Return a Frobenius relative defect with a unit scale floor.

  value = norm(actual-reference,'fro')/max(1,norm(reference,'fro'));
end

%% ==================== Kernel and warning helpers ====================
% These helpers preserve the bounded public-kernel and warning behavior.

function [pot,grad,hess] = LOCAL_h2d_chunked_public( ...
    wavek,sources,charge,targ)
%LOCAL_H2D_CHUNKED_PUBLIC Call the public kernel on target batches.

  nt = size(targ,2);
  pot = zeros(1,nt);
  grad = zeros(2,nt);
  hess = zeros(3,nt);
  target_batch = 512;
  for first = 1:target_batch:nt
    index = first:min(first+target_batch-1,nt);
    [pot(:,index),grad(:,index),hess(:,index)] = ...
      kernel.h2d_directch(wavek,sources,charge,targ(:,index));
  end
end

function cleanup = LOCAL_solver_warning_guard()
%LOCAL_SOLVER_WARNING_GUARD Reject qualified construction-solve warnings.

  state = warning;
  cleanup = onCleanup(@() warning(state));
  warning('error','MATLAB:singularMatrix');
  warning('error','MATLAB:nearlySingularMatrix');
  warning('error','MATLAB:illConditionedMatrix');
  warning('error','MATLAB:rankDeficientMatrix');
end
