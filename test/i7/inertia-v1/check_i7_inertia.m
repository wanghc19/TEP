function [result,evidence] = check_i7_inertia()
%CHECK_I7_INERTIA Diagnose Hermitian-part sign counts at two I7 endpoints.
% Purpose:
%   Evaluate the frozen I7 ellipse-center model at two fixed wavenumbers,
%   form the center-trace operator H=Adef/T, and count signs of Hsym.
% Output:
%   result   - Compact endpoint diagnostics and jump classification.
%   evidence - Matrices and eigenvalues needed to audit both endpoints.
% Main algorithm:
%   Independently assemble Adef and N0-L*T, right-solve H=Adef/T, then
%   count eigenvalues of Hsym=(H+H')/2 outside three uncertainty bands.
% Based on:
%   test/i7/scan-v1/locate_i7.m and test/i2/h-inertia/check_h_inertia.m.
% Main changes:
%   Replace singular-value scoring by the I7.2 endpoint diagnostic while
%   preserving the frozen model, fine spatial configuration, and M=48.
% Numerical goal:
%   Report JUMP, NO_JUMP, or UNRESOLVED without claiming raw-H inertia.

  timer = tic;
  beta = 0.5;
  model = struct('beta',beta,'d',1,'R',0.2,'epsrel',17, ...
    'epsrel_center',2,'XL',-0.5,'XR',0.5,'H',1.1,'pdist',0.2, ...
    'flag_geom','ellipse','ellipse_axes',[0.25,0.16]);
  cfg = struct('ntot',256,'nside',160,'ntop',160, ...
    'nproxy',80,'mpw',32);
  M = 48;
  kvals = [1.753125,1.75625];
  labels = {'L','R'};
  endpoints = repmat(LOCAL_empty_endpoint(),2,1);
  evidence = struct();

  for j = 1:2
    point_timer = tic;
    [endpoints(j),point_evidence] = ...
      LOCAL_endpoint(kvals(j),labels{j},M,model,cfg);
    evidence.(lower(labels{j})) = point_evidence;
    fprintf(1,['endpoint=%s k=%.17g rcondT=%.6e assembly=%.6e ' ...
      'solve=%.6e negative=%d unresolved=%d seconds=%.3f\n'], ...
      labels{j},kvals(j),endpoints(j).T_rcond, ...
      endpoints(j).assembly_error,endpoints(j).solve_error, ...
      endpoints(j).negative_100,endpoints(j).unresolved_100, ...
      toc(point_timer));
  end

  delta_negative = endpoints(2).negative_100-endpoints(1).negative_100;
  delta_positive = endpoints(2).positive_100-endpoints(1).positive_100;
  stable = all(strcmp({endpoints.band_sensitivity},'STABLE'));
  diagnostic_pass = all([endpoints.diagnostic_pass]);
  if ~diagnostic_pass || ~stable || any([endpoints.unresolved_100] > 0)
    scientific_outcome = 'UNRESOLVED';
    jump_kind = 'UNRESOLVED';
  elseif delta_negative == 0
    scientific_outcome = 'NO_JUMP';
    jump_kind = 'NO_JUMP';
  elseif abs(delta_negative) == 1
    scientific_outcome = 'JUMP';
    jump_kind = 'SINGLE_JUMP';
  else
    scientific_outcome = 'JUMP';
    jump_kind = 'MULTIPLE_JUMP';
  end

  result = struct('experiment_id','I7-H-INERTIA-SURROGATE-V1', ...
    'execution_pass',true,'scientific_outcome',scientific_outcome, ...
    'jump_kind',jump_kind,'delta_negative',delta_negative, ...
    'delta_positive',delta_positive,'band_sensitivity', ...
    LOCAL_overall_sensitivity(endpoints),'diagnostic_pass', ...
    diagnostic_pass,'raw_inertia_available',false, ...
    'surrogate_sign_count_available',true, ...
    'raw_real_zero_claim',false,'continuous_eigenvalue_claim',false, ...
    'surrogate_method','HERMITIAN_PART_SIGN_COUNT', ...
    'raw_H_definition','Adef/T', ...
    'Hsym_definition','(H+H'')/2', ...
    'trace_order','[left;right]','amplitude_order','[aL;bR]', ...
    'center_outward_normals','[-dx;+dx]', ...
    'matching_residual','[nL-Lm*dL;nR-Lp*dR]', ...
    'beta',beta,'M',M,'spatial_config',[cfg.ntot,cfg.nside, ...
    cfg.ntop,cfg.nproxy,cfg.mpw],'lead_epsrel',model.epsrel, ...
    'center_epsrel',model.epsrel_center, ...
    'runtime',toc(timer),'endpoints',endpoints);
end

%% ==================== Endpoint diagnostic ====================
% This helper assembles the frozen I7 blocks and performs the sign count.

function [out,evidence] = LOCAL_endpoint(k,label,M,model,cfg)
%LOCAL_ENDPOINT Form Adef, T, N0, L, H, and the Hsym sign counts.

  warning_guard = LOCAL_solver_warning_guard();
  [Zp,Zm,~,gamma] = LOCAL_cellsub(k,M,model,cfg);
  [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma);
  cellmap = LOCAL_center(k,M,model,cfg);
  clear warning_guard;

  K = numel(gamma);
  I = eye(K);
  G = diag(gamma);
  T = [I+cellmap.R_L,cellmap.T_RL; ...
    cellmap.T_LR,I+cellmap.R_R];
  N0 = [1i*G*(cellmap.R_L-I),1i*G*cellmap.T_RL; ...
    1i*G*cellmap.T_LR,1i*G*(cellmap.R_R-I)];
  L = blkdiag(Lm,Lp);
  Adef = [(1i*G-Lm)*cellmap.R_L-(1i*G+Lm), ...
    (1i*G-Lm)*cellmap.T_RL; ...
    (1i*G-Lp)*cellmap.T_LR, ...
    (1i*G-Lp)*cellmap.R_R-(1i*G+Lp)];

  n = size(Adef,1);
  assembly_error = norm(Adef-(N0-L*T),'fro')/max(1, ...
    norm(Adef,'fro')+norm(N0,'fro')+norm(L,'fro')*norm(T,'fro'));
  solve_warning_state = warning;
  solve_warning_cleanup = onCleanup(@() warning(solve_warning_state));
  warning('on','MATLAB:singularMatrix');
  warning('on','MATLAB:nearlySingularMatrix');
  warning('on','MATLAB:illConditionedMatrix');
  warning('on','MATLAB:rankDeficientMatrix');
  lastwarn('');
  H = Adef/T;
  [solve_warning_message,solve_warning_id] = lastwarn;
  clear solve_warning_cleanup;
  solve_error = norm(Adef-H*T,'fro')/max(1, ...
    norm(Adef,'fro')+norm(H,'fro')*norm(T,'fro'));
  Hsym = (H+H')/2;
  scale_2 = norm(Hsym,2);
  distance_2 = norm(H-Hsym,2);
  unit = n*eps*max(1,scale_2);
  multipliers = [50,100,200];
  eta = distance_2+multipliers*unit;

  finite_matrices = all(isfinite(Adef(:))) && all(isfinite(T(:))) && ...
    all(isfinite(N0(:))) && all(isfinite(L(:))) && ...
    all(isfinite(H(:))) && all(isfinite(Hsym(:)));
  if ~finite_matrices || ~isfinite(scale_2) || ~isfinite(distance_2)
    error('i72:NonfiniteMatrix', ...
      'Endpoint %s at k=%.17g produced a nonfinite matrix.',label,k);
  end
  eigenvalues = eig(Hsym,'vector');
  imaginary_leakage = max(abs(imag(eigenvalues)));
  if any(~isfinite(eigenvalues)) || imaginary_leakage > 100*unit
    error('i72:SurrogateSpectrum', ...
      'Endpoint %s at k=%.17g has an unavailable Hsym spectrum.',label,k);
  end
  counts = zeros(3,3);
  lambda = real(eigenvalues);
  for q = 1:3
    counts(q,:) = [sum(lambda>eta(q)),sum(lambda<-eta(q)), ...
      sum(abs(lambda)<=eta(q))];
  end
  count_partition = all(sum(counts,2) == n);
  if ~count_partition
    error('i72:CountPartition', ...
      'Endpoint %s at k=%.17g failed the sign-count partition.',label,k);
  end
  spectrum_pass = true;

  identity_tolerance = 1000*n*eps;
  object_gate = rcond(T) >= 1e-8 && ...
    assembly_error <= identity_tolerance && ...
    solve_error <= identity_tolerance;
  diagnostic_pass = object_gate && spectrum_pass && count_partition && ...
    isempty(solve_warning_message);
  if isequal(counts(1,:),counts(2,:)) && ...
      isequal(counts(2,:),counts(3,:)) && spectrum_pass
    band_sensitivity = 'STABLE';
  else
    band_sensitivity = 'UNSTABLE';
  end
  if rcond(T) < 1e-8
    diagnostic_reason = 'T_RCOND';
  elseif assembly_error > identity_tolerance
    diagnostic_reason = 'ASSEMBLY_IDENTITY';
  elseif solve_error > identity_tolerance
    diagnostic_reason = 'RIGHT_SOLVE_RESIDUAL';
  elseif ~isempty(solve_warning_message)
    diagnostic_reason = 'RIGHT_SOLVE_WARNING';
  else
    diagnostic_reason = 'PASS';
  end

  min_eigenvalue = min(lambda);
  max_eigenvalue = max(lambda);
  min_abs_eigenvalue = min(abs(lambda));

  out = struct('label',label,'k',k,'dimension',n, ...
    'T_rcond',rcond(T),'assembly_error',assembly_error, ...
    'solve_error',solve_error,'identity_tolerance',identity_tolerance, ...
    'scale_2',scale_2,'distance_2',distance_2, ...
    'relative_distance_2',distance_2/max(1,scale_2), ...
    'eta_50',eta(1),'eta_100',eta(2),'eta_200',eta(3), ...
    'relative_eta_100',eta(2)/max(1,scale_2), ...
    'imaginary_leakage',imaginary_leakage, ...
    'min_eigenvalue',min_eigenvalue,'max_eigenvalue',max_eigenvalue, ...
    'min_abs_eigenvalue',min_abs_eigenvalue, ...
    'positive_50',counts(1,1),'negative_50',counts(1,2), ...
    'unresolved_50',counts(1,3),'positive_100',counts(2,1), ...
    'negative_100',counts(2,2),'unresolved_100',counts(2,3), ...
    'positive_200',counts(3,1),'negative_200',counts(3,2), ...
    'unresolved_200',counts(3,3), ...
    'band_sensitivity',band_sensitivity,'object_gate',object_gate, ...
    'spectrum_pass',spectrum_pass,'count_partition',count_partition, ...
    'diagnostic_pass',diagnostic_pass, ...
    'diagnostic_reason',diagnostic_reason, ...
    'solve_warning_id',solve_warning_id, ...
    'solve_warning_message',solve_warning_message);
  evidence = struct('k',k,'Adef',Adef,'T',T,'N0',N0,'L',L, ...
    'H',H,'Hsym',Hsym,'eigenvalues',eigenvalues, ...
    'band_multipliers',multipliers,'band_etas',eta, ...
    'band_counts',counts);
end

function out = LOCAL_empty_endpoint()
%LOCAL_EMPTY_ENDPOINT Define the compact endpoint result schema.

  out = struct('label','','k',NaN,'dimension',0,'T_rcond',NaN, ...
    'assembly_error',NaN,'solve_error',NaN,'identity_tolerance',NaN, ...
    'scale_2',NaN,'distance_2',NaN,'relative_distance_2',NaN, ...
    'eta_50',NaN,'eta_100',NaN,'eta_200',NaN, ...
    'relative_eta_100',NaN,'imaginary_leakage',NaN, ...
    'min_eigenvalue',NaN,'max_eigenvalue',NaN, ...
    'min_abs_eigenvalue',NaN,'positive_50',0,'negative_50',0, ...
    'unresolved_50',0,'positive_100',0,'negative_100',0, ...
    'unresolved_100',0,'positive_200',0,'negative_200',0, ...
    'unresolved_200',0,'band_sensitivity','','object_gate',false, ...
    'spectrum_pass',false,'count_partition',false, ...
    'diagnostic_pass',false,'diagnostic_reason','', ...
    'solve_warning_id','', ...
    'solve_warning_message','');
end

function text = LOCAL_overall_sensitivity(endpoints)
%LOCAL_OVERALL_SENSITIVITY Summarize the two endpoint band checks.

  if all(strcmp({endpoints.band_sensitivity},'STABLE'))
    text = 'STABLE';
  else
    text = 'UNSTABLE';
  end
end

%% ==================== Center construction ====================
% This helper retains the frozen ellipse-center scattering construction.

function cellmap = LOCAL_center(k,M,model,cfg)
%LOCAL_CENTER Construct the epsrel=2 elliptical center scattering matrix.

  pars = struct('k',k,'beta',model.beta,'d',model.d, ...
    'periodic_axis','y','h2d_evaluator',@LOCAL_h2d_chunked_public);
  chans = bloch.rayleigh_channels( ...
    k,model.beta,model.d,M,model.XR-model.XL);
  [C,curvelen] = geom.construct_cont(cfg.ntot,model.flag_geom,0,0, ...
    model.ellipse_axes);
  mfscfg = struct('H',model.H,'proxy_dist',model.pdist, ...
    'N_side',cfg.nside,'N_top',cfg.ntop, ...
    'N_proxy_edge',cfg.nproxy,'M_pw',cfg.mpw);
  proxy = kernel.precomp_proxy(pars,mfscfg);
  kint = sqrt(model.epsrel_center)*k;
  cellmap = bloch.construct_S(C,k,kint,pars,proxy,curvelen,chans, ...
    model.XL,model.XR);
end

%% ==================== Half-guide construction ====================
% These helpers retain the circular lead, ordered QZ, and DtN conventions.

function [Zp,Zm,bm,gamma,phase] = LOCAL_cellsub(k,M,model,cfg)
%LOCAL_CELLSUB Build the unchanged circular half-guide subspaces.

  pars = struct('k',k,'beta',model.beta,'d',model.d, ...
    'periodic_axis','y','h2d_evaluator',@LOCAL_h2d_chunked_public);
  chans = bloch.rayleigh_channels( ...
    k,model.beta,model.d,M,model.XR-model.XL);
  flag_geom = 'circle';
  [C,curvelen] = geom.construct_cont(cfg.ntot,flag_geom,0,0,model.R);
  mfscfg = struct('H',model.H,'proxy_dist',model.pdist, ...
    'N_side',cfg.nside,'N_top',cfg.ntop, ...
    'N_proxy_edge',cfg.nproxy,'M_pw',cfg.mpw);
  proxy = kernel.precomp_proxy(pars,mfscfg);
  kint = sqrt(model.epsrel)*k;
  cellmap = bloch.construct_S(C,k,kint,pars,proxy,curvelen,chans, ...
    model.XL,model.XR);

  K = chans.K;
  A = [-cellmap.R_L,eye(K);cellmap.T_LR,zeros(K)];
  B = [zeros(K),cellmap.T_RL;eye(K),-cellmap.R_R];
  Zp = LOCAL_qzsub(A,B,K);
  Zm = LOCAL_qzsub(B,A,K);
  bm = chans.beta_m(:);
  gamma = chans.gamma_m(:);
  phase = chans.phase(:);
end

function Zs = LOCAL_qzsub(A,B,K)
%LOCAL_QZSUB Extract a qualified strictly stable generalized-Schur subspace.

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

  if sum(stable) ~= K || sum(unstable) ~= K || ...
      any(indet) || any(neutral)
    error('i7:QZClassification', ...
      'stable=%d unstable=%d neutral=%d indet=%d expected stable=unstable=%d.', ...
      sum(stable),sum(unstable),sum(neutral),sum(indet),K);
  end
  [~,~,~,Zo] = ordqz(S,T,Q,Z,stable);
  Zs = Zo(:,1:K);
end

function [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma)
%LOCAL_DTN Convert the two qualified half-guide subspaces to DtN maps.

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

%% ==================== Kernel and warning helpers ====================
% These helpers bound proxy-source allocations and qualify construction solves.

function [pot,grad,hess] = LOCAL_h2d_chunked_public( ...
    wavek,sources,charge,targ)
%LOCAL_H2D_CHUNKED_PUBLIC Call the public kernel on contiguous target batches.

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
