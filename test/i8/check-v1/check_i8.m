function [result,evidence] = check_i8(k0,halfwidth)
%CHECK_I8 Evaluate the frozen I8 candidate on five discretizations.
% Purpose:
%   Recompute the corrected-density star-center candidate at the two fixed
%   shoulders k0 +/- halfwidth and at k0 for five prescribed (ntot,M) pairs.
% Input:
%   k0        - Finite real candidate wavenumber.
%   halfwidth - Positive finite shoulder half-width.
% Output:
%   result   - Compact point, endpoint-count, and same-mode diagnostics.
%   evidence - Full matching matrices, spectra, QZ data, and mode vectors.
% Main algorithm:
%   At every point independently assemble Adef and N0-L*T, form H=Adef/T
%   and Hsym=(H+H')/2, and form Aphys=Dr*Adef*Dc. Compare the endpoint
%   Hsym modes and center Aphys modes only at the same k, after zero-filling
%   the two physical wall-trace blocks by their exact Fourier labels.
% Based on:
%   test/i7/refine-v1/check_i7_refinement.m and
%   test/i8/flow-v1/run_i8.m and test/i8/locate-v1/locate_i8.m.
% Main changes:
%   Use the equal-area six-row-scaled star center, five frozen I8.2
%   configurations, and caller-supplied k0 and shoulder half-width.
% Numerical goal:
%   Determine whether endpoint sign counts and the same physical modes are
%   stable under the prescribed single-axis discretization refinements.

  if nargin ~= 2 || ~isscalar(k0) || ~isreal(k0) || ~isfinite(k0) || ...
      ~isscalar(halfwidth) || ~isreal(halfwidth) || ...
      ~isfinite(halfwidth) || halfwidth <= 0
    error('i82:Arguments','Expected finite real k0 and positive halfwidth.');
  end
  kvals = [k0-halfwidth,k0,k0+halfwidth];
  if any(~isfinite(kvals)) || any(diff(kvals) <= 0) || ...
      numel(unique(kvals)) ~= 3
    error('i82:Grid','The three binary64 wavenumbers must be distinct.');
  end

  timer = tic;
  model = struct('beta',0.5,'d',1,'R',0.2,'rho_center',2, ...
    'rho_lead',17,'X_L',-0.5,'X_R',0.5,'H',1.1, ...
    'proxy_dist',0.2,'star_scale',sqrt(0.04/0.0618));
  configs = LOCAL_configs();
  labels = {'L','C','R'};
  points = repmat(LOCAL_empty_point(),numel(configs),3);
  config_results = repmat(LOCAL_empty_config(),numel(configs),1);
  evidence = cell(numel(configs),3);

  % --- stage 1: evaluate all five configurations at all three points ---
  for ic = 1:numel(configs)
    for ik = 1:3
      point_timer = tic;
      [points(ic,ik),evidence{ic,ik}] = LOCAL_safe_point( ...
        kvals(ik),labels{ik},model,configs(ic));
      points(ic,ik).elapsed_seconds = toc(point_timer);
      LOCAL_print(points(ic,ik));
    end
    config_results(ic) = LOCAL_config_result(configs(ic),points(ic,:));
  end

  % --- stage 2: compare the same object along each refinement axis ---
  edges = [1,2;2,3;1,4;4,5];
  objects = {'H_LEFT','APHYS_CENTER','H_RIGHT'};
  comparisons = repmat(LOCAL_empty_comparison(),size(edges,1),3);
  for ie = 1:size(edges,1)
    for ik = 1:3
      comparisons(ie,ik) = LOCAL_compare(evidence{edges(ie,1),ik}, ...
        evidence{edges(ie,2),ik},objects{ik},64,ie);
    end
  end
  baseline_edges = [1,2;1,3;1,4;1,5];
  baseline_comparisons = repmat( ...
    LOCAL_empty_comparison(),size(baseline_edges,1),1);
  for ie = 1:size(baseline_edges,1)
    baseline_comparisons(ie) = LOCAL_compare( ...
      evidence{baseline_edges(ie,1),2}, ...
      evidence{baseline_edges(ie,2),2},'APHYS_CENTER',64,ie);
  end
  oracle = LOCAL_comparison_oracle();

  execution_pass = all([points.valid]);
  object_gate_pass = execution_pass && all([points.diagnostic_pass]);
  endpoint = LOCAL_endpoint_gate(config_results);
  mode_identity_pass = oracle.pass && all([comparisons.pass]);
  center_unresolved = reshape([points(:,2).unresolved_100],[],1);
  center_band_stable = strcmp({points(:,2).band_sensitivity},'STABLE').';
  center_status = LOCAL_center_status(points(:,2));
  if ~execution_pass
    scientific_outcome = 'EXECUTION_FAILED';
  elseif object_gate_pass && endpoint.pass && mode_identity_pass
    scientific_outcome = 'STABLE_SAME_MODE';
  else
    scientific_outcome = 'NUMERICAL_STABILITY_UNRESOLVED';
  end

  result = struct('experiment_id','I8-CHECK-V1', ...
    'execution_pass',execution_pass, ...
    'invalid_point_count',sum(~[points.valid]), ...
    'scientific_outcome',scientific_outcome, ...
    'object_gate_pass',object_gate_pass, ...
    'endpoint_gate_pass',endpoint.pass, ...
    'endpoint_jump_present',endpoint.jump_present, ...
    'endpoint_consistency',endpoint, ...
    'mode_identity_pass',mode_identity_pass, ...
    'center_status',center_status, ...
    'center_unresolved_100',center_unresolved, ...
    'center_band_stable',center_band_stable, ...
    'beta',model.beta,'k0',k0,'halfwidth',halfwidth, ...
    'k_values',kvals,'point_labels',{labels}, ...
    'fixed_proxy_config',[160,160,80,32], ...
    'lead_epsrel',model.rho_lead,'center_epsrel',model.rho_center, ...
    'star_scale',model.star_scale,'configs',configs, ...
    'config_results',config_results,'points',points, ...
    'edges',edges,'edge_objects',{objects},'comparisons',comparisons, ...
    'baseline_edges',baseline_edges, ...
    'baseline_comparisons',baseline_comparisons, ...
    'comparison_oracle',oracle,'runtime',toc(timer), ...
    'surrogate_sign_count_available',true, ...
    'raw_inertia_available',false,'continuous_eigenvalue_claim',false, ...
    'error_bound_claim',false);
end

%% ==================== Frozen configurations ====================
% These values are the sole five I8.2 discretization configurations.

function configs = LOCAL_configs()
  ntot = [256,384,512,256,256];
  M = [48,48,48,56,64];
  ids = {'B','N384','N512','M56','M64'};
  configs = repmat(struct('id','','ntot',0,'nside',160,'ntop',160, ...
    'nproxy',80,'mpw',32,'M',0,'K',0),numel(ntot),1);
  for j = 1:numel(ntot)
    configs(j) = struct('id',ids{j},'ntot',ntot(j), ...
      'nside',160,'ntop',160,'nproxy',80,'mpw',32, ...
      'M',M(j),'K',2*M(j)+1);
  end
end

%% ==================== Point evaluation ====================
% These helpers form the independent matching, Hermitian, and SVD objects.

function [out,evidence] = LOCAL_safe_point(k,label,model,cfg)
  try
    [out,evidence] = LOCAL_point(k,label,model,cfg);
  catch ME
    if ~LOCAL_expected_failure(ME)
      rethrow(ME);
    end
    out = LOCAL_empty_point();
    out.config_id = cfg.id;
    out.label = label;
    out.k = k;
    out.ntot = cfg.ntot;
    out.M = cfg.M;
    out.K = cfg.K;
    out.dimension = 2*cfg.K;
    out.error_id = ME.identifier;
    out.error_message = ME.message;
    evidence = struct('valid',false,'model',model,'config',cfg, ...
      'label',label,'k',k, ...
      'error_id',ME.identifier,'error_message',ME.message);
  end
end

function yes = LOCAL_expected_failure(ME)
  id = ME.identifier;
  controlled = {'i8:QZScale','i8:QZClassification', ...
    'i82:ChannelCount','i82:FourierLabels','i82:NonfiniteMatrix', ...
    'i82:SurrogateSpectrum','i82:EigensystemResidual', ...
    'i82:CountPartition','i82:SVD','i82:SVDResidual', ...
    'MATLAB:singularMatrix','MATLAB:nearlySingularMatrix', ...
    'MATLAB:illConditionedMatrix','MATLAB:rankDeficientMatrix'};
  yes = any(strcmp(id,controlled)) || startsWith(id,'MATLAB:qz:') || ...
    startsWith(id,'MATLAB:eig:') || startsWith(id,'MATLAB:svd:');
end

function [out,evidence] = LOCAL_point(k,label,model,cfg)
  local_model = model;
  local_model.khat = k;
  construction_guard = LOCAL_solver_warning_guard(); %#ok<NASGU>
  [lead,Zp,Zm,pencil,beta_m,gamma,phase,qz] = ...
    LOCAL_lead(local_model,cfg);
  [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma);
  center = LOCAL_center(local_model,cfg);
  clear construction_guard;

  K = numel(gamma);
  if K ~= cfg.K
    error('i82:ChannelCount','Configuration %s returned K=%d.',cfg.id,K);
  end
  m = (-cfg.M:cfg.M).';
  expected_beta = model.beta+2*pi*m/model.d;
  if ~isequal(beta_m,expected_beta)
    error('i82:FourierLabels', ...
      'Configuration %s returned unexpected Fourier labels.',cfg.id);
  end
  I = eye(K);
  G = diag(gamma);
  T = [I+center.R_L,center.T_RL;center.T_LR,I+center.R_R];
  N0 = [1i*G*(center.R_L-I),1i*G*center.T_RL; ...
    1i*G*center.T_LR,1i*G*(center.R_R-I)];
  L = blkdiag(Lm,Lp);
  Adef = [(1i*G-Lm)*center.R_L-(1i*G+Lm), ...
    (1i*G-Lm)*center.T_RL; ...
    (1i*G-Lp)*center.T_LR, ...
    (1i*G-Lp)*center.R_R-(1i*G+Lp)];
  n = size(Adef,1);
  identity_tolerance = 1000*n*eps;
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
  multipliers = [50,100,200];
  eta = distance_2+multipliers*n*eps*max(1,scale_2);
  finite_matrices = all(isfinite(Adef(:))) && all(isfinite(T(:))) && ...
    all(isfinite(N0(:))) && all(isfinite(L(:))) && ...
    all(isfinite(H(:))) && all(isfinite(Hsym(:)));
  if ~finite_matrices || ~isfinite(scale_2) || ~isfinite(distance_2)
    error('i82:NonfiniteMatrix', ...
      'Configuration %s point %s produced a nonfinite matrix.',cfg.id,label);
  end

  [Hsym_vectors,D] = eig(Hsym,'vector');
  imaginary_leakage = max(abs(imag(D)));
  leakage_tolerance = 100*n*eps*max(1,scale_2);
  if any(~isfinite(D)) || any(~isfinite(Hsym_vectors(:))) || ...
      imaginary_leakage > leakage_tolerance
    error('i82:SurrogateSpectrum', ...
      'Configuration %s point %s has an unavailable Hsym spectrum.', ...
      cfg.id,label);
  end
  eigenvalues = real(D);
  eig_residual = norm(Hsym*Hsym_vectors- ...
    Hsym_vectors*diag(eigenvalues),'fro')/max(1,norm(Hsym,'fro'));
  if ~isfinite(eig_residual) || eig_residual > identity_tolerance
    error('i82:EigensystemResidual', ...
      'Configuration %s point %s failed the eigensystem residual gate.', ...
      cfg.id,label);
  end
  counts = zeros(3,3);
  for j = 1:3
    counts(j,:) = [sum(eigenvalues>eta(j)), ...
      sum(eigenvalues<-eta(j)),sum(abs(eigenvalues)<=eta(j))];
  end
  if ~all(sum(counts,2) == n)
    error('i82:CountPartition', ...
      'Configuration %s point %s failed the sign-count partition.', ...
      cfg.id,label);
  end
  [magnitude,near_order] = sort(abs(eigenvalues),'ascend');
  near_index = near_order(1:min(4,n));
  cluster_delta = 1000*n*eps*max(1,scale_2);
  cluster_index = find(abs(abs(eigenvalues)-magnitude(1)) <= cluster_delta);
  competitor_index = near_order(find(~ismember(near_order,cluster_index),1));
  if isempty(competitor_index)
    error('i82:SurrogateSpectrum','No Hsym competitor is available.');
  end
  near_abs_margin = magnitude(2)-magnitude(1);
  near_abs_ratio = magnitude(1)/max(realmin,magnitude(2));
  signed_gap = min(abs(eigenvalues(near_order(2:end))- ...
    eigenvalues(near_order(1))));

  T_rcond = rcond(T);
  object_gate = T_rcond >= 1e-8 && ...
    assembly_error <= identity_tolerance && ...
    solve_error <= identity_tolerance;
  diagnostic_pass = object_gate && isempty(solve_warning_message);
  diagnostic_reason = LOCAL_diagnostic_reason(T_rcond,assembly_error, ...
    solve_error,identity_tolerance,solve_warning_message);
  if isequal(counts(1,:),counts(2,:)) && isequal(counts(2,:),counts(3,:))
    band_sensitivity = 'STABLE';
  else
    band_sensitivity = 'UNSTABLE';
  end
  svd_data = LOCAL_svd_data(Adef,T,beta_m,gamma);

  out = struct('config_id',cfg.id,'label',label,'k',k, ...
    'valid',true,'error_id','','error_message','', ...
    'ntot',cfg.ntot,'M',cfg.M,'K',K,'dimension',n, ...
    'T_rcond',T_rcond,'assembly_error',assembly_error, ...
    'solve_error',solve_error,'identity_tolerance',identity_tolerance, ...
    'scale_2',scale_2,'distance_2',distance_2, ...
    'relative_distance_2',distance_2/max(1,scale_2), ...
    'eta_50',eta(1),'eta_100',eta(2),'eta_200',eta(3), ...
    'imaginary_leakage',imaginary_leakage, ...
    'eig_residual',eig_residual,'min_eigenvalue',min(eigenvalues), ...
    'max_eigenvalue',max(eigenvalues), ...
    'min_abs_eigenvalue',magnitude(1), ...
    'nearest_signed_eigenvalue',eigenvalues(near_order(1)), ...
    'near_eigenvalues',eigenvalues(near_index).', ...
    'near_abs_margin',near_abs_margin,'near_abs_ratio',near_abs_ratio, ...
    'signed_spectral_separation',signed_gap, ...
    'Hsym_cluster_delta',cluster_delta, ...
    'Hsym_cluster_rank',numel(cluster_index), ...
    'positive_50',counts(1,1),'negative_50',counts(1,2), ...
    'unresolved_50',counts(1,3),'positive_100',counts(2,1), ...
    'negative_100',counts(2,2),'unresolved_100',counts(2,3), ...
    'positive_200',counts(3,1),'negative_200',counts(3,2), ...
    'unresolved_200',counts(3,3), ...
    'band_sensitivity',band_sensitivity,'object_gate',object_gate, ...
    'diagnostic_pass',diagnostic_pass, ...
    'diagnostic_reason',diagnostic_reason, ...
    'solve_warning_id',solve_warning_id, ...
    'solve_warning_message',solve_warning_message, ...
    'adef_sigma',svd_data.adef_sigma, ...
    'adef_ratio',svd_data.adef_ratio, ...
    'aphys_sigma',svd_data.aphys_sigma, ...
    'aphys_ratio',svd_data.aphys_ratio, ...
    'aphys_target_gap',svd_data.target_gap, ...
    'aphys_target_ratio',svd_data.target_ratio, ...
    'aphys_cluster_rank',svd_data.cluster_rank, ...
    'adef_svd_residual',svd_data.adef_residual, ...
    'aphys_svd_residual',svd_data.aphys_residual, ...
    'qz_plus_stable',qz.plus.stable, ...
    'qz_plus_unstable',qz.plus.unstable, ...
    'qz_plus_neutral',qz.plus.neutral, ...
    'qz_plus_indeterminate',qz.plus.indeterminate, ...
    'qz_minus_stable',qz.minus.stable, ...
    'qz_minus_unstable',qz.minus.unstable, ...
    'qz_minus_neutral',qz.minus.neutral, ...
    'qz_minus_indeterminate',qz.minus.indeterminate, ...
    'elapsed_seconds',NaN);
  evidence = struct('valid',true,'model',local_model, ...
    'config',cfg,'label',label,'k',k, ...
    'm',m,'beta_m',beta_m,'gamma',gamma,'phase',phase, ...
    'lead_blocks',LOCAL_blocks(lead),'center_blocks',LOCAL_blocks(center), ...
    'pencil',pencil,'Zplus',Zp,'Zminus',Zm,'Lp',Lp,'Lm',Lm, ...
    'Adef',Adef,'T',T,'N0',N0,'L',L,'H',H,'Hsym',Hsym, ...
    'Hsym_eigenvalues',eigenvalues,'Hsym_vectors',Hsym_vectors, ...
    'near_index',near_index,'cluster_delta',cluster_delta, ...
    'cluster_index',cluster_index,'competitor_index',competitor_index, ...
    'band_multipliers',multipliers,'band_etas',eta, ...
    'band_counts',counts,'qz',qz,'svd',svd_data);
end

function data = LOCAL_svd_data(Adef,T,beta_m,gamma)
  b = sqrt(1+abs(beta_m(:)).^2);
  rowwt = repmat(sqrt(1./b),2,1);
  ampwt = b+abs(gamma(:)).^2./b;
  colwt = repmat(1./sqrt(ampwt),2,1);
  Aphys = rowwt.*Adef.*colwt.';
  [Udef,Sdef,Vdef] = svd(Adef,'econ');
  [Uphys,Sphys,Vphys] = svd(Aphys,'econ');
  sdef = diag(Sdef);
  sphys = diag(Sphys);
  sdef_value = svd(Adef,'econ');
  sphys_value = svd(Aphys,'econ');
  if numel(sphys) < 2 || any(~isfinite( ...
      [sdef;sphys;sdef_value;sphys_value])) || ...
      sdef_value(1) <= 0 || sphys_value(1) <= 0
    error('i82:SVD','A singular spectrum is unavailable.');
  end
  target_index = numel(sphys);
  competitor_index = target_index-1;
  delta = 1000*numel(sphys)*eps*max(1,sphys(1));
  cluster_index = find(abs(sphys-sphys(end)) <= delta);
  q = colwt.*Vphys;
  trace = T*q;
  adef_residual = max(norm(Adef*Vdef-Udef*Sdef,'fro'), ...
    norm(Adef'*Udef-Vdef*Sdef,'fro'))/max(1,norm(Adef,'fro'));
  aphys_residual = max(norm(Aphys*Vphys-Uphys*Sphys,'fro'), ...
    norm(Aphys'*Uphys-Vphys*Sphys,'fro'))/max(1,norm(Aphys,'fro'));
  residual = max(adef_residual,aphys_residual);
  residual_tolerance = 1000*numel(sphys)*eps;
  if ~isfinite(residual) || residual > residual_tolerance
    error('i82:SVDResidual','The Aphys SVD residual gate failed.');
  end
  data = struct('Aphys',Aphys,'row_weight',rowwt, ...
    'column_weight',colwt,'adef_singular_values_descending',sdef, ...
    'aphys_singular_values_descending',sphys, ...
    'adef_value_only_singular_values',sdef_value, ...
    'aphys_value_only_singular_values',sphys_value, ...
    'adef_sigma',sdef_value(end), ...
    'adef_ratio',sdef_value(end)/sdef_value(1), ...
    'aphys_sigma',sphys_value(end), ...
    'aphys_ratio',sphys_value(end)/sphys_value(1), ...
    'target_gap',sphys(end-1)-sphys(end), ...
    'target_ratio',sphys(end)/max(realmin,sphys(end-1)), ...
    'cluster_delta',delta,'cluster_rank',numel(cluster_index), ...
    'cluster_index',cluster_index,'target_index',target_index, ...
    'competitor_index',competitor_index, ...
    'adef_residual',adef_residual,'aphys_residual',aphys_residual, ...
    'residual',residual,'residual_tolerance',residual_tolerance, ...
    'adef_left_vectors',Udef,'adef_right_vectors',Vdef, ...
    'aphys_left_vectors',Uphys,'aphys_right_vectors',Vphys, ...
    'raw_port_vectors',q,'physical_trace_vectors',trace);
end

function text = LOCAL_diagnostic_reason(T_rcond,assembly_error, ...
    solve_error,tolerance,warning_message)
  if T_rcond < 1e-8
    text = 'T_RCOND';
  elseif assembly_error > tolerance
    text = 'ASSEMBLY_IDENTITY';
  elseif solve_error > tolerance
    text = 'RIGHT_SOLVE_RESIDUAL';
  elseif ~isempty(warning_message)
    text = 'RIGHT_SOLVE_WARNING';
  else
    text = 'PASS';
  end
end

function blocks = LOCAL_blocks(cellmap)
  blocks = struct('R_L',cellmap.R_L,'T_RL',cellmap.T_RL, ...
    'T_LR',cellmap.T_LR,'R_R',cellmap.R_R, ...
    'solve_relative_residual_norm',cellmap.solve_relative_residual_norm);
end

function LOCAL_print(point)
  if point.valid
    fprintf(1,['config=%s ntot=%d M=%d point=%s k=%.17g ' ...
      'neg=%d unres=%d ratio=%.6e sec=%.3f\n'], ...
      point.config_id,point.ntot,point.M,point.label,point.k, ...
      point.negative_100,point.unresolved_100,point.aphys_ratio, ...
      point.elapsed_seconds);
  else
    fprintf(1,['config=%s ntot=%d M=%d point=%s k=%.17g ' ...
      'INVALID=%s sec=%.3f\n'],point.config_id,point.ntot,point.M, ...
      point.label,point.k,point.error_id,point.elapsed_seconds);
  end
end

%% ==================== Endpoint summaries ====================
% These helpers separate endpoint count evidence from center diagnostics.

function out = LOCAL_config_result(cfg,points)
  out = LOCAL_empty_config();
  out.config_id = cfg.id;
  out.ntot = cfg.ntot;
  out.M = cfg.M;
  out.K = cfg.K;
  if ~all([points.valid])
    out.endpoint_outcome = 'EXECUTION_UNAVAILABLE';
    return;
  end
  left = points(1);
  right = points(3);
  out.left_negative = [left.negative_50,left.negative_100,left.negative_200];
  out.right_negative = ...
    [right.negative_50,right.negative_100,right.negative_200];
  out.left_positive = [left.positive_50,left.positive_100,left.positive_200];
  out.right_positive = ...
    [right.positive_50,right.positive_100,right.positive_200];
  out.left_unresolved = ...
    [left.unresolved_50,left.unresolved_100,left.unresolved_200];
  out.right_unresolved = ...
    [right.unresolved_50,right.unresolved_100,right.unresolved_200];
  out.delta_negative = out.right_negative-out.left_negative;
  out.delta_positive = out.right_positive-out.left_positive;
  out.delta_unresolved = out.right_unresolved-out.left_unresolved;
  out.endpoint_band_stable = strcmp(left.band_sensitivity,'STABLE') && ...
    strcmp(right.band_sensitivity,'STABLE');
  out.endpoint_qualified = left.diagnostic_pass && ...
    right.diagnostic_pass && out.endpoint_band_stable && ...
    all([out.left_unresolved,out.right_unresolved] == 0);
  if ~out.endpoint_qualified
    out.endpoint_outcome = 'UNRESOLVED';
  elseif all(out.delta_negative == 0)
    out.endpoint_outcome = 'NO_JUMP';
  else
    out.endpoint_outcome = 'JUMP';
  end
  out.center_diagnostic_pass = points(2).diagnostic_pass;
  out.center_band_stable = strcmp(points(2).band_sensitivity,'STABLE');
  out.center_unresolved = ...
    [points(2).unresolved_50,points(2).unresolved_100, ...
    points(2).unresolved_200];
  out.center_adef_sigma = points(2).adef_sigma;
  out.center_adef_ratio = points(2).adef_ratio;
  out.center_aphys_sigma = points(2).aphys_sigma;
  out.center_aphys_ratio = points(2).aphys_ratio;
end

function out = LOCAL_endpoint_gate(configs)
  qualified = all([configs.endpoint_qualified]);
  if qualified
    left = vertcat(configs.left_negative);
    right = vertcat(configs.right_negative);
    dneg = vertcat(configs.delta_negative);
    dpos = vertcat(configs.delta_positive);
    dunresolved = vertcat(configs.delta_unresolved);
    consistent = all(all(left == left(1,:))) && ...
      all(all(right == right(1,:))) && ...
      all(all(dneg == dneg(1,:))) && all(all(dpos == dpos(1,:))) && ...
      all(all(dunresolved == dunresolved(1,:)));
    jump = all(any(dneg ~= 0,2));
  else
    consistent = false;
    jump = false;
  end
  out = struct('pass',qualified && consistent, ...
    'all_qualified',qualified,'cross_config_consistent',consistent, ...
    'jump_present',jump);
end

function text = LOCAL_center_status(points)
  if ~all([points.valid])
    text = 'EXECUTION_UNAVAILABLE';
  elseif ~all([points.diagnostic_pass])
    text = 'OBJECT_GATE_UNRESOLVED';
  elseif all(strcmp({points.band_sensitivity},'STABLE')) && ...
      all([points.unresolved_100] == 0)
    text = 'STABLE_RESOLVED';
  else
    text = 'SURROGATE_SIGN_UNRESOLVED';
  end
end

%% ==================== Same-mode comparisons ====================
% These helpers compare physical traces by exact Fourier labels.

function out = LOCAL_compare(a,b,object,Mmax,edge_index)
  out = LOCAL_empty_comparison();
  out.edge_index = edge_index;
  out.object = object;
  if ~isfield(a,'config') || ~isfield(b,'config')
    out.status = 'EVALUATION_UNAVAILABLE';
    return;
  end
  out.config_a = a.config.id;
  out.config_b = b.config.id;
  out.k = a.k;
  if ~a.valid || ~b.valid || a.k ~= b.k
    out.status = 'EVALUATION_UNAVAILABLE';
    return;
  end
  va = LOCAL_object_view(a,object);
  vb = LOCAL_object_view(b,object);
  out.rank_a = numel(va.cluster_index);
  out.rank_b = numel(vb.cluster_index);
  out.gap_a = va.gap;
  out.gap_b = vb.gap;
  out.ratio_a = va.ratio;
  out.ratio_b = vb.ratio;
  out.delta_a = va.delta;
  out.delta_b = vb.delta;
  out.signed_gap_a = va.signed_gap;
  out.signed_gap_b = vb.signed_gap;
  Xa = LOCAL_embed_trace(va.trace_vectors,a.m,Mmax);
  Xb = LOCAL_embed_trace(vb.trace_vectors,b.m,Mmax);
  [Qa,ok_a] = LOCAL_trace_basis(Xa(:,va.cluster_index));
  [Qb,ok_b] = LOCAL_trace_basis(Xb(:,vb.cluster_index));
  cutoff = min(a.config.M,b.config.M);
  out.tail_a_edge = LOCAL_tail_fractions(Qa,Mmax,cutoff);
  out.tail_b_edge = LOCAL_tail_fractions(Qb,Mmax,cutoff);
  out.tail_a_above_48 = LOCAL_tail_fractions(Qa,Mmax,48);
  out.tail_b_above_48 = LOCAL_tail_fractions(Qb,Mmax,48);
  if ~(ok_a && ok_b)
    out.status = 'MODE_IDENTITY_UNRESOLVED';
    return;
  end
  if out.rank_a == 1 && out.rank_b == 1
    [out.primary_overlap,primary_ok] = LOCAL_overlap( ...
      Xa(:,va.primary_index),Xb(:,vb.primary_index));
    [out.common_overlap,common_ok] = LOCAL_common_overlap( ...
      Xa(:,va.primary_index),Xb(:,vb.primary_index),Mmax,cutoff);
    [out.cross_a_primary_b_competitor,cross_ab] = LOCAL_overlap( ...
      Xa(:,va.primary_index),Xb(:,vb.competitor_index));
    [out.cross_a_competitor_b_primary,cross_ba] = LOCAL_overlap( ...
      Xa(:,va.competitor_index),Xb(:,vb.primary_index));
    out.cross_max = max(out.cross_a_primary_b_competitor, ...
      out.cross_a_competitor_b_primary);
    out.method = 'SIMPLE_VECTOR';
    out.pass = primary_ok && common_ok && cross_ab && cross_ba && ...
      out.primary_overlap >= 0.99 && out.cross_max <= 0.5;
    if out.pass
      out.status = 'SAME_MODE';
    elseif cross_ab && cross_ba && out.cross_max > 0.5
      out.status = 'MODE_SWITCH';
    else
      out.status = 'MODE_IDENTITY_UNRESOLVED';
    end
  elseif out.rank_a == out.rank_b
    out.subspace_overlap = min(svd(Qa'*Qb,'econ'));
    out.projection_a_to_b = norm(Qb'*Qa,'fro')^2/out.rank_a;
    out.projection_b_to_a = norm(Qa'*Qb,'fro')^2/out.rank_b;
    out.common_overlap = LOCAL_common_subspace_overlap( ...
      Qa,Qb,Mmax,cutoff);
    out.method = 'CLUSTER_SUBSPACE';
    out.pass = isfinite(out.subspace_overlap) && ...
      out.subspace_overlap >= 0.99;
    if out.pass
      out.status = 'SAME_MODE';
    else
      out.status = 'MODE_IDENTITY_UNRESOLVED';
    end
  else
    out.method = 'CLUSTER_RANK_MISMATCH';
    out.projection_a_to_b = norm(Qb'*Qa,'fro')^2/out.rank_a;
    out.projection_b_to_a = norm(Qa'*Qb,'fro')^2/out.rank_b;
    out.status = 'MODE_IDENTITY_UNRESOLVED';
  end
end

function view = LOCAL_object_view(evidence,object)
  if strcmp(object,'APHYS_CENTER')
    spectrum = evidence.svd.aphys_singular_values_descending;
    primary = numel(spectrum);
    view = struct('trace_vectors',evidence.svd.physical_trace_vectors, ...
      'primary_index',primary,'competitor_index',primary-1, ...
      'cluster_index',evidence.svd.cluster_index, ...
      'gap',spectrum(end-1)-spectrum(end), ...
      'ratio',spectrum(end)/max(realmin,spectrum(end-1)), ...
      'delta',evidence.svd.cluster_delta,'signed_gap',NaN);
  else
    spectrum = evidence.Hsym_eigenvalues;
    [magnitude,order] = sort(abs(spectrum),'ascend');
    primary = order(1);
    cluster = find(abs(abs(spectrum)-magnitude(1)) <= ...
      evidence.cluster_delta);
    view = struct('trace_vectors',evidence.Hsym_vectors, ...
      'primary_index',primary,'competitor_index',order(2), ...
      'cluster_index',cluster,'gap',magnitude(2)-magnitude(1), ...
      'ratio',magnitude(1)/max(realmin,magnitude(2)), ...
      'delta',evidence.cluster_delta, ...
      'signed_gap',min(abs(spectrum(order(2:end))-spectrum(primary))));
  end
end

function embedded = LOCAL_embed_trace(trace,m,Mmax)
  m = m(:);
  K = numel(m);
  if size(trace,1) ~= 2*K || numel(unique(m)) ~= K || ...
      any(m ~= fix(m)) || any(abs(m) > Mmax)
    error('i82:TraceEmbedding','A trace cannot be embedded by its m labels.');
  end
  Kmax = 2*Mmax+1;
  index = m+Mmax+1;
  embedded = zeros(2*Kmax,size(trace,2),'like',trace);
  embedded(index,:) = trace(1:K,:);
  embedded(Kmax+index,:) = trace(K+1:end,:);
end

function [Q,available] = LOCAL_trace_basis(X)
  Q = zeros(size(X),'like',X);
  available = ~isempty(X) && all(isfinite(X(:)));
  if ~available
    return;
  end
  singular = svd(X,'econ');
  tolerance = 1000*max(size(X))*eps*max(1,singular(1));
  available = numel(singular) == size(X,2) && all(singular > tolerance);
  if available
    [Q,~] = qr(X,0);
  end
end

function [rho,available] = LOCAL_overlap(x,y)
  nx = norm(x);
  ny = norm(y);
  available = all(isfinite(x(:))) && all(isfinite(y(:))) && ...
    isfinite(nx) && isfinite(ny) && nx > realmin && ny > realmin;
  if available
    rho = min(1,abs(x(:)'*y(:))/(nx*ny));
  else
    rho = NaN;
  end
end

function [rho,available] = LOCAL_common_overlap(x,y,Mmax,Mcut)
  [rho,available] = LOCAL_overlap( ...
    x(LOCAL_trace_mask(Mmax,Mcut)),y(LOCAL_trace_mask(Mmax,Mcut)));
end

function rho = LOCAL_common_subspace_overlap(Qa,Qb,Mmax,Mcut)
  mask = LOCAL_trace_mask(Mmax,Mcut);
  [Pa,oka] = LOCAL_trace_basis(Qa(mask,:));
  [Pb,okb] = LOCAL_trace_basis(Qb(mask,:));
  if oka && okb && size(Pa,2) == size(Pb,2)
    rho = min(svd(Pa'*Pb,'econ'));
  else
    rho = NaN;
  end
end

function mask = LOCAL_trace_mask(Mmax,Mcut)
  one = abs((-Mmax:Mmax).') <= Mcut;
  mask = [one;one];
end

function out = LOCAL_tail_fractions(Q,Mmax,Mcut)
  Kmax = 2*Mmax+1;
  tail = abs((-Mmax:Mmax).') > Mcut;
  left = Q(1:Kmax,:);
  right = Q(Kmax+1:end,:);
  out = struct('cutoff',Mcut, ...
    'total',sum(abs([left(tail,:);right(tail,:)]).^2,'all')/ ...
    max(realmin,sum(abs(Q).^2,'all')), ...
    'left',sum(abs(left(tail,:)).^2,'all')/ ...
    max(realmin,sum(abs(left).^2,'all')), ...
    'right',sum(abs(right(tail,:)).^2,'all')/ ...
    max(realmin,sum(abs(right).^2,'all')));
  out.common = 1-out.total;
end

function oracle = LOCAL_comparison_oracle()
  x = (1:6).';
  [scaled,scaled_ok] = LOCAL_overlap(x,1e8*exp(1i*pi/7)*x);
  [orthogonal,orthogonal_ok] = LOCAL_overlap([1;0],[0;1]);
  [~,zero_ok] = LOCAL_overlap([0;0],[1;0]);
  [~,finite_ok] = LOCAL_overlap([1;NaN],[1;0]);
  embedded = LOCAL_embed_trace(x,(-1:1).',2);
  expected = zeros(10,1);
  expected([2,3,4,7,8,9]) = x;
  Qa = [1,0;0,1;0,0];
  angle = pi/7;
  Qb = Qa*[cos(angle),sin(angle);-sin(angle),cos(angle)];
  subspace = min(svd(Qa'*Qb,'econ'));
  tail = LOCAL_tail_fractions(eye(10,1),2,1);
  pass = scaled_ok && abs(scaled-1) <= 10*eps && orthogonal_ok && ...
    orthogonal <= 10*eps && ~zero_ok && ~finite_ok && ...
    isequal(embedded,expected) && abs(subspace-1) <= 10*eps && ...
    abs(tail.total-1) <= 10*eps && abs(tail.left-1) <= 10*eps && ...
    abs(tail.right) <= 10*eps;
  oracle = struct('pass',pass,'scaled_overlap',scaled, ...
    'orthogonal_overlap',orthogonal,'zero_available',zero_ok, ...
    'nonfinite_available',finite_ok,'embedding_pass', ...
    isequal(embedded,expected),'rotated_subspace_overlap',subspace, ...
    'tail_expected',abs(tail.total-1) <= 10*eps && ...
    abs(tail.left-1) <= 10*eps && abs(tail.right) <= 10*eps);
end

%% ==================== Star and lead construction ====================
% These helpers preserve the corrected-density public scattering interface.

function [lead,Zp,Zm,pencil,beta_m,gamma,phase,diagnostic] = ...
    LOCAL_lead(model,cfg)
  [lead,chans] = LOCAL_cellmap('circle',model.R,model.rho_lead,model,cfg);
  K = chans.K;
  A = [-lead.R_L,eye(K);lead.T_LR,zeros(K)];
  B = [zeros(K),lead.T_RL;eye(K),-lead.R_R];
  [Zp,plus] = LOCAL_qzsub(A,B,K);
  [Zm,minus] = LOCAL_qzsub(B,A,K);
  pencil = struct('A',A,'B',B);
  beta_m = chans.beta_m(:);
  gamma = chans.gamma_m(:);
  phase = chans.phase(:);
  diagnostic = struct('plus',plus,'minus',minus);
end

function center = LOCAL_center(model,cfg)
  center = LOCAL_cellmap('star',model.star_scale, ...
    model.rho_center,model,cfg);
end

function [cellmap,chans] = LOCAL_cellmap(flag_geom,shape_arg,rho,model,cfg)
  pars = struct('k',model.khat,'beta',model.beta,'d',model.d, ...
    'periodic_axis','y','h2d_evaluator',@LOCAL_h2d_chunked_public);
  chans = bloch.rayleigh_channels(model.khat,model.beta,model.d, ...
    cfg.M,model.X_R-model.X_L);
  if strcmp(flag_geom,'circle')
    [C,curvelen] = geom.construct_cont( ...
      cfg.ntot,'circle',0,0,shape_arg);
  elseif strcmp(flag_geom,'star')
    [C,curvelen] = geom.construct_cont(cfg.ntot,'star',0,0);
    C = shape_arg*C;
  else
    error('i82:Shape','Unsupported shape %s.',flag_geom);
  end
  mfscfg = struct('H',model.H,'proxy_dist',model.proxy_dist, ...
    'N_side',cfg.nside,'N_top',cfg.ntop, ...
    'N_proxy_edge',cfg.nproxy,'M_pw',cfg.mpw);
  proxy = kernel.precomp_proxy(pars,mfscfg);
  cellmap = bloch.construct_S(C,model.khat,sqrt(rho)*model.khat, ...
    pars,proxy,curvelen,chans,model.X_L,model.X_R);
end

function [Zs,diagnostic] = LOCAL_qzsub(A,B,K)
  rho = hypot(norm(A,'fro'),norm(B,'fro'));
  if ~isfinite(rho) || rho == 0
    error('i8:QZScale','The QZ pencil scale is zero or nonfinite.');
  end
  A = A/rho;
  B = B/rho;
  [S,T,Q,Z] = qz(A,B,'complex');
  residual = hypot(norm(A-Q'*S*Z','fro'),norm(B-Q'*T*Z','fro'));
  tolerance = max(100*eps,10*residual);
  alpha = diag(S);
  theta = diag(T);
  scale = hypot(abs(alpha),abs(theta));
  indeterminate = scale <= tolerance;
  scale(indeterminate) = 1;
  an = abs(alpha)./scale;
  tn = abs(theta)./scale;
  infinite = ~indeterminate & tn <= tolerance & an > tolerance;
  neutral = ~indeterminate & ~infinite & ...
    abs(an-tn) <= tolerance;
  stable = ~indeterminate & ~infinite & ~neutral & ...
    an < tn-tolerance;
  unstable = infinite | (~indeterminate & ~neutral & ...
    an > tn+tolerance);
  if sum(stable) ~= K || sum(unstable) ~= K || ...
      any(indeterminate) || any(neutral)
    error('i8:QZClassification', ...
      'stable=%d unstable=%d neutral=%d indet=%d expected=%d.', ...
      sum(stable),sum(unstable),sum(neutral),sum(indeterminate),K);
  end
  [~,~,~,Zo] = ordqz(S,T,Q,Z,stable);
  Zs = Zo(:,1:K);
  diagnostic = struct('stable',sum(stable),'unstable',sum(unstable), ...
    'neutral',sum(neutral),'indeterminate',sum(indeterminate), ...
    'residual',residual,'tolerance',tolerance, ...
    'pencil_order',size(A,1));
end

function [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma)
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

%% ==================== Schemas and low-level helpers ====================
% These helpers define stable saved schemas and bounded kernel allocations.

function out = LOCAL_empty_point()
  out = struct('config_id','','label','','k',NaN,'valid',false, ...
    'error_id','','error_message','','ntot',0,'M',0,'K',0, ...
    'dimension',0,'T_rcond',NaN,'assembly_error',NaN, ...
    'solve_error',NaN,'identity_tolerance',NaN,'scale_2',NaN, ...
    'distance_2',NaN,'relative_distance_2',NaN, ...
    'eta_50',NaN,'eta_100',NaN,'eta_200',NaN, ...
    'imaginary_leakage',NaN,'eig_residual',NaN, ...
    'min_eigenvalue',NaN,'max_eigenvalue',NaN, ...
    'min_abs_eigenvalue',NaN,'nearest_signed_eigenvalue',NaN, ...
    'near_eigenvalues',NaN(1,4),'near_abs_margin',NaN, ...
    'near_abs_ratio',NaN,'signed_spectral_separation',NaN, ...
    'Hsym_cluster_delta',NaN,'Hsym_cluster_rank',0, ...
    'positive_50',0,'negative_50',0,'unresolved_50',0, ...
    'positive_100',0,'negative_100',0,'unresolved_100',0, ...
    'positive_200',0,'negative_200',0,'unresolved_200',0, ...
    'band_sensitivity','UNAVAILABLE','object_gate',false, ...
    'diagnostic_pass',false,'diagnostic_reason','UNAVAILABLE', ...
    'solve_warning_id','','solve_warning_message','', ...
    'adef_sigma',NaN,'adef_ratio',NaN,'aphys_sigma',NaN, ...
    'aphys_ratio',NaN,'aphys_target_gap',NaN, ...
    'aphys_target_ratio',NaN,'aphys_cluster_rank',0, ...
    'adef_svd_residual',NaN,'aphys_svd_residual',NaN, ...
    'qz_plus_stable',0, ...
    'qz_plus_unstable',0,'qz_plus_neutral',0, ...
    'qz_plus_indeterminate',0,'qz_minus_stable',0, ...
    'qz_minus_unstable',0,'qz_minus_neutral',0, ...
    'qz_minus_indeterminate',0,'elapsed_seconds',NaN);
end

function out = LOCAL_empty_config()
  out = struct('config_id','','ntot',0,'M',0,'K',0, ...
    'endpoint_qualified',false,'endpoint_outcome','UNAVAILABLE', ...
    'endpoint_band_stable',false,'left_negative',NaN(1,3), ...
    'right_negative',NaN(1,3),'left_positive',NaN(1,3), ...
    'right_positive',NaN(1,3),'left_unresolved',NaN(1,3), ...
    'right_unresolved',NaN(1,3),'delta_negative',NaN(1,3), ...
    'delta_positive',NaN(1,3),'delta_unresolved',NaN(1,3), ...
    'center_diagnostic_pass',false, ...
    'center_band_stable',false,'center_unresolved',NaN(1,3), ...
    'center_adef_sigma',NaN,'center_adef_ratio',NaN, ...
    'center_aphys_sigma',NaN,'center_aphys_ratio',NaN);
end

function out = LOCAL_empty_comparison()
  tail = struct('cutoff',NaN,'total',NaN,'left',NaN, ...
    'right',NaN,'common',NaN);
  out = struct('edge_index',0,'config_a','','config_b','', ...
    'object','','k',NaN,'method','','status','','pass',false, ...
    'rank_a',0,'rank_b',0,'gap_a',NaN,'gap_b',NaN, ...
    'ratio_a',NaN,'ratio_b',NaN,'delta_a',NaN,'delta_b',NaN, ...
    'signed_gap_a',NaN,'signed_gap_b',NaN, ...
    'primary_overlap',NaN,'common_overlap',NaN, ...
    'cross_a_primary_b_competitor',NaN, ...
    'cross_a_competitor_b_primary',NaN,'cross_max',NaN, ...
    'subspace_overlap',NaN,'projection_a_to_b',NaN, ...
    'projection_b_to_a',NaN,'tail_a_edge',tail,'tail_b_edge',tail, ...
    'tail_a_above_48',tail,'tail_b_above_48',tail);
end

function [pot,grad,hess] = LOCAL_h2d_chunked_public( ...
    wavek,sources,charge,targ)
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
  state = warning;
  cleanup = onCleanup(@() warning(state));
  warning('error','MATLAB:singularMatrix');
  warning('error','MATLAB:nearlySingularMatrix');
  warning('error','MATLAB:illConditionedMatrix');
  warning('error','MATLAB:rankDeficientMatrix');
end
