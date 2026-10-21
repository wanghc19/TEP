function [result,evidence] = check_i7_refinement(checkpoint_dir,mode)
%CHECK_I7_REFINEMENT Evaluate the frozen I7 model on six discretizations.
% Purpose:
%   Recompute the I7.2 endpoint diagnostic and the I7.1 singular-vector
%   mode at three fixed wavenumbers for six prescribed (ntot,M) pairs.
%   Local mode instead scans the same six configurations on one fixed grid.
% Input:
%   checkpoint_dir - Existing directory for unique per-point checkpoints.
%   mode           - Optional 'fixed' (default) or authorized 'local'.
% Output:
%   result   - Compact per-point diagnostics and endpoint count changes.
%   evidence - Full matrices, spectra, and physical mode coordinates.
%   With mode='local', result contains the authorized 11-point local grid
%   and evidence retains compact traces plus each configuration's winner.
% Main algorithm:
%   For each configuration, evaluate kL, k0, and kR serially; independently
%   assemble Adef and N0-L*T, form H=Adef/T and Hsym, and at k0 form the
%   raw and weighted singular-vector data with q=Dc*v and t=T*q.
%   Local mode evaluates only k0+(-5:5)*1e-5 and selects by Aphys ratio.
% Based on:
%   test/i7/inertia-v1/check_i7_inertia.m and
%   test/i7/scan-v1/locate_i7.m.
% Main changes:
%   Parameterize only ntot and Rayleigh order M and retain actual Fourier
%   labels and complete physical-trace coordinates for later comparisons.
% Numerical goal:
%   Test fixed-point stability and whether the common local grid resolves
%   configuration-dependent movement of the sampled candidate.

  if nargin == 0
    checkpoint_dir = '';
    mode = 'fixed';
  elseif nargin == 1
    mode = 'fixed';
  elseif nargin ~= 2
    error('i73:Arguments','Expected checkpoint_dir and optional mode.');
  end
  if ~(ischar(checkpoint_dir) || ...
      (isstring(checkpoint_dir) && isscalar(checkpoint_dir)))
    error('i73:Arguments','checkpoint_dir must be a character vector or string.');
  end
  if ~(ischar(mode) || (isstring(mode) && isscalar(mode)))
    error('i73:Arguments','mode must be fixed or local.');
  end
  checkpoint_dir = char(checkpoint_dir);
  mode = lower(char(mode));
  if ~ismember(mode,{'fixed','local'})
    error('i73:Arguments','mode must be fixed or local.');
  end
  if ~isempty(checkpoint_dir) && ~isfolder(checkpoint_dir)
    error('i73:CheckpointDirectory', ...
      'The explicit checkpoint directory does not exist.');
  end

  timer = tic;
  beta = 0.5;
  model = struct('beta',beta,'d',1,'R',0.2,'epsrel',17, ...
    'epsrel_center',2,'XL',-0.5,'XR',0.5,'H',1.1,'pdist',0.2, ...
    'flag_geom','ellipse','ellipse_axes',[0.25,0.16]);
  configs = LOCAL_configs();
  k0 = 1.755995740875;
  if strcmp(mode,'local')
    [result,evidence] = LOCAL_local_scan( ...
      timer,beta,model,configs,checkpoint_dir,k0);
    return;
  end
  kvals = [1.753125,k0,1.75625];
  labels = {'L','C','R'};
  point_rows = repmat(LOCAL_empty_point(),numel(configs),numel(kvals));
  config_rows = repmat(LOCAL_empty_config_result(),numel(configs),1);
  evidence = cell(numel(configs),numel(kvals));

  for ic = 1:numel(configs)
    cfg = configs(ic);
    for ik = 1:numel(kvals)
      point_timer = tic;
      [point_rows(ic,ik),evidence{ic,ik}] = ...
        LOCAL_safe_point(kvals(ik),labels{ik},model,cfg);
      point_rows(ic,ik).elapsed_seconds = toc(point_timer);
      if ~isempty(checkpoint_dir)
        checkpoint = struct('config',cfg,'point',point_rows(ic,ik), ...
          'evidence',evidence{ic,ik}); %#ok<NASGU>
        checkpoint_file = fullfile(checkpoint_dir,sprintf( ...
          'checkpoint-%02d-%02d.mat',ic,ik));
        if isfile(checkpoint_file) || isfolder(checkpoint_file)
          error('i73:CheckpointExists', ...
            'Refusing to overwrite checkpoint: %s.',checkpoint_file);
        end
        save(checkpoint_file,'checkpoint','-v7.3');
      end
      if point_rows(ic,ik).valid
        fprintf(1,['config=%s ntot=%d M=%d point=%s k=%.17g ' ...
          'negative=%d unresolved=%d seconds=%.3f\n'], ...
          cfg.id,cfg.ntot,cfg.M,labels{ik},kvals(ik), ...
          point_rows(ic,ik).negative_100, ...
          point_rows(ic,ik).unresolved_100, ...
          point_rows(ic,ik).elapsed_seconds);
      else
        fprintf(1,['config=%s ntot=%d M=%d point=%s k=%.17g ' ...
          'invalid=%s seconds=%.3f\n'],cfg.id,cfg.ntot,cfg.M, ...
          labels{ik},kvals(ik),point_rows(ic,ik).error_id, ...
          point_rows(ic,ik).elapsed_seconds);
      end
    end
    config_rows(ic) = LOCAL_config_result(cfg,point_rows(ic,:));
  end

  execution_pass = all([point_rows.valid]);
  edges = [1,2;2,3;1,4;4,5;3,6;5,6];
  object_labels = {'H_LEFT','APHYS_CENTER','H_RIGHT'};
  comparison_oracle = LOCAL_comparison_oracle();
  comparisons = repmat(LOCAL_empty_comparison(),size(edges,1),3);
  for ie = 1:size(edges,1)
    for ik = 1:3
      comparisons(ie,ik) = LOCAL_compare(evidence{edges(ie,1),ik}, ...
        evidence{edges(ie,2),ik},object_labels{ik},64,ie);
    end
  end
  baseline_joint_summary = repmat(LOCAL_empty_comparison(),1,3);
  for ik = 1:3
    baseline_joint_summary(ik) = LOCAL_compare( ...
      evidence{1,ik},evidence{6,ik},object_labels{ik},64,0);
  end
  identity_pass = comparison_oracle.pass && all([comparisons.pass]);
  count_pass = LOCAL_count_gate(point_rows);
  object_pass = execution_pass && all([point_rows.diagnostic_pass]);
  if ~execution_pass
    scientific_outcome = 'EXECUTION_FAILED';
  elseif object_pass && count_pass && identity_pass
    scientific_outcome = 'STABLE_SAME_MODE';
  else
    scientific_outcome = 'NUMERICAL_STABILITY_UNRESOLVED';
  end
  first_failure = LOCAL_first_failure(point_rows,comparisons, ...
    count_pass,comparison_oracle.pass);
  result = struct('experiment_id','I7-REFINEMENT-V1', ...
    'execution_pass',execution_pass, ...
    'invalid_point_count',sum(~[point_rows.valid]), ...
    'scientific_outcome',scientific_outcome, ...
    'object_gate_pass',object_pass,'count_stability_pass',count_pass, ...
    'mode_identity_pass',identity_pass, ...
    'beta',beta,'k_values',kvals,'point_labels',{labels}, ...
    'fixed_proxy_config',[160,160,80,32], ...
    'lead_epsrel',model.epsrel,'center_epsrel',model.epsrel_center, ...
    'configs',configs,'config_results',config_rows, ...
    'points',point_rows,'edges',edges,'edge_objects',{object_labels}, ...
    'comparisons',comparisons,'comparison_oracle',comparison_oracle, ...
    'baseline_joint_summary',baseline_joint_summary, ...
    'first_failure',first_failure, ...
    'runtime',toc(timer), ...
    'raw_inertia_available',false,'continuous_eigenvalue_claim',false, ...
    'error_bound_claim',false);
end

%% ==================== Frozen configurations ====================
% These values define the sole six prescribed discretization configurations.

function configs = LOCAL_configs()
%LOCAL_CONFIGS Return the fixed (ntot,M) pairs and common proxy parameters.

  ntot = [256,256,256,384,512,512];
  M = [48,56,64,48,48,64];
  ids = {'B','M56','M64','N384','N512','J'};
  configs = repmat(struct('id','','ntot',0,'nside',160,'ntop',160, ...
    'nproxy',80,'mpw',32,'M',0,'K',0),numel(ntot),1);
  for j = 1:numel(ntot)
    configs(j) = struct('id',ids{j},'ntot',ntot(j), ...
      'nside',160,'ntop',160,'nproxy',80,'mpw',32, ...
      'M',M(j),'K',2*M(j)+1);
  end
end

%% ==================== Local fixed-grid scan ====================
% This mode retains compact traces per point and full evidence only at winners.

function [result,evidence] = LOCAL_local_scan( ...
    timer,beta,model,configs,checkpoint_dir,k0)
%LOCAL_LOCAL_SCAN Evaluate the authorized six-configuration 11-point grid.

  spacing = 1e-5;
  kvals = k0+(-5:5)*spacing;
  rows = repmat(LOCAL_empty_local_point(),numel(configs),numel(kvals));
  point_modes = cell(numel(configs),numel(kvals));
  best_full = cell(numel(configs),1);
  best_score = Inf(numel(configs),1);
  best_index = zeros(numel(configs),1);

  for ic = 1:numel(configs)
    cfg = configs(ic);
    for ik = 1:numel(kvals)
      point_timer = tic;
      [point,full] = LOCAL_safe_point(kvals(ik),'C',model,cfg);
      elapsed = toc(point_timer);
      rows(ic,ik) = LOCAL_local_point(point,ik,elapsed);
      point_modes{ic,ik} = LOCAL_compact_center_evidence(full,point);
      if point.valid && isfinite(point.aphys_ratio) && ...
          point.aphys_ratio < best_score(ic)
        best_score(ic) = point.aphys_ratio;
        best_index(ic) = ik;
        best_full{ic} = full;
      end
      if ~isempty(checkpoint_dir)
        point_checkpoint = struct('config',cfg,'point',rows(ic,ik), ...
          'mode',point_modes{ic,ik}); %#ok<NASGU>
        checkpoint_file = fullfile(checkpoint_dir,sprintf( ...
          'local-checkpoint-%02d-%02d.mat',ic,ik));
        if isfile(checkpoint_file) || isfolder(checkpoint_file)
          error('i73:CheckpointExists', ...
            'Refusing to overwrite checkpoint: %s.',checkpoint_file);
        end
        save(checkpoint_file,'point_checkpoint');
      end
      if point.valid
        fprintf(1,['local config=%s point=%02d k=%.17g ' ...
          'aphys_ratio=%.17g seconds=%.3f\n'],cfg.id,ik,kvals(ik), ...
          point.aphys_ratio,elapsed);
      else
        fprintf(1,['local config=%s point=%02d k=%.17g ' ...
          'invalid=%s seconds=%.3f\n'],cfg.id,ik,kvals(ik), ...
          point.error_id,elapsed);
      end
      clear full;
    end
  end

  best = repmat(LOCAL_empty_local_best(),numel(configs),1);
  for ic = 1:numel(configs)
    best(ic).config_id = configs(ic).id;
    index = best_index(ic);
    if index == 0
      continue;
    end
    row = rows(ic,index);
    best(ic).valid = true;
    best(ic).grid_index = index;
    best(ic).k = row.k;
    best(ic).adef_sigma = row.adef_sigma;
    best(ic).adef_ratio = row.adef_ratio;
    best(ic).aphys_sigma = row.aphys_sigma;
    best(ic).aphys_ratio = row.aphys_ratio;
    best(ic).boundary_limited = index == 1 || index == numel(kvals);
    if ~best(ic).boundary_limited
      best(ic).bracket = [kvals(index-1),kvals(index+1)];
      best(ic).full_neighbor_spacing = kvals(index+1)-kvals(index-1);
      best(ic).left_ratio_gap = rows(ic,index-1).aphys_ratio-row.aphys_ratio;
      best(ic).right_ratio_gap = rows(ic,index+1).aphys_ratio-row.aphys_ratio;
      best(ic).bracket_valid = rows(ic,index-1).valid && ...
        rows(ic,index+1).valid && isfinite(best(ic).left_ratio_gap) && ...
        isfinite(best(ic).right_ratio_gap) && ...
        best(ic).left_ratio_gap > 0 && best(ic).right_ratio_gap > 0;
    end
  end

  edges = [1,2;2,3;1,4;4,5;3,6;5,6];
  grid_comparisons = repmat(LOCAL_empty_comparison(), ...
    size(edges,1),numel(kvals));
  for ie = 1:size(edges,1)
    for ik = 1:numel(kvals)
      grid_comparisons(ie,ik) = LOCAL_local_same_k_compare( ...
        point_modes{edges(ie,1),ik},point_modes{edges(ie,2),ik},ie);
    end
  end
  center_index = 6;
  best_to_center = repmat(LOCAL_empty_local_relation(),numel(configs),1);
  best_to_baseline = repmat(LOCAL_empty_local_relation(),numel(configs),1);
  for ic = 1:numel(configs)
    if best_index(ic) > 0
      best_to_center(ic) = LOCAL_local_relation( ...
        point_modes{ic,best_index(ic)},point_modes{ic,center_index},0);
    end
    if best_index(1) > 0 && best_index(ic) > 0
      best_to_baseline(ic) = LOCAL_local_relation( ...
        point_modes{1,best_index(1)},point_modes{ic,best_index(ic)},ic);
    end
  end

  all_valid = all([rows.valid]);
  all_diagnostics_pass = all([rows.diagnostic_pass]);
  common_winner = all([best.valid]) && ...
    all([best.grid_index] == best(1).grid_index);
  if ~all_valid
    location_status = 'UNAVAILABLE_DUE_TO_INVALID_POINTS';
  elseif common_winner && all([best.bracket_valid])
    location_status = 'NO_DRIFT_RESOLVED_AT_SPACING_1E-5';
  elseif any([best.boundary_limited])
    location_status = 'BOUNDARY_LIMITED';
  elseif common_winner
    location_status = 'COMMON_SAMPLED_WINNER_LOCATION_UNRESOLVED';
  else
    location_status = 'DIFFERENT_SAMPLED_WINNERS';
  end
  if ~all_valid
    outcome = 'LOCAL_GRID_PARTIAL';
  elseif ~all_diagnostics_pass
    outcome = 'NUMERICAL_STABILITY_UNRESOLVED';
  else
    outcome = 'LOCAL_GRID_COMPLETED';
  end
  result = struct('experiment_id','I7-REFINEMENT-V1-LOCAL', ...
    'mode','LOCAL','execution_pass',all_valid, ...
    'diagnostic_pass',all_diagnostics_pass, ...
    'invalid_point_count',sum(~[rows.valid]), ...
    'scientific_outcome',outcome,'beta',beta,'k0',k0, ...
    'k_values',kvals,'spacing',spacing,'configs',configs, ...
    'points',rows,'best',best,'edges',edges, ...
    'grid_comparisons',grid_comparisons, ...
    'same_k_mode_identity_pass',all([grid_comparisons.pass]), ...
    'best_to_center',best_to_center, ...
    'best_to_baseline',best_to_baseline, ...
    'common_sampled_winner',common_winner, ...
    'location_status',location_status,'runtime',toc(timer), ...
    'continuous_eigenvalue_claim',false,'error_bound_claim',false);
  evidence = struct('point_modes',{point_modes}, ...
    'best_full',{best_full});
end

function row = LOCAL_local_point(point,index,elapsed)
%LOCAL_LOCAL_POINT Retain only the requested scalar scan record.

  row = struct('config_id',point.config_id,'grid_index',index, ...
    'k',point.k,'valid',point.valid,'error_id',point.error_id, ...
    'error_message',point.error_message, ...
    'diagnostic_pass',point.diagnostic_pass, ...
    'diagnostic_reason',point.diagnostic_reason, ...
    'adef_sigma',point.adef_sigma,'adef_ratio',point.adef_ratio, ...
    'aphys_sigma',point.aphys_sigma,'aphys_ratio',point.aphys_ratio, ...
    'elapsed_seconds',elapsed);
end

function row = LOCAL_empty_local_point()
%LOCAL_EMPTY_LOCAL_POINT Define the compact local-grid row schema.

  row = struct('config_id','','grid_index',0,'k',NaN,'valid',false, ...
    'error_id','','error_message','','diagnostic_pass',false, ...
    'diagnostic_reason','','adef_sigma',NaN, ...
    'adef_ratio',NaN,'aphys_sigma',NaN,'aphys_ratio',NaN, ...
    'elapsed_seconds',NaN);
end

function best = LOCAL_empty_local_best()
%LOCAL_EMPTY_LOCAL_BEST Define one configuration's sampled winner.

  best = struct('config_id','','valid',false,'grid_index',0,'k',NaN, ...
    'adef_sigma',NaN,'adef_ratio',NaN,'aphys_sigma',NaN, ...
    'aphys_ratio',NaN,'boundary_limited',false,'bracket',[NaN,NaN], ...
    'bracket_valid',false,'full_neighbor_spacing',NaN, ...
    'left_ratio_gap',NaN, ...
    'right_ratio_gap',NaN);
end

function compact = LOCAL_compact_center_evidence(full,point)
%LOCAL_COMPACT_CENTER_EVIDENCE Keep primary and competitor physical traces.

  if ~point.valid
    compact = struct('valid',false,'config',full.config,'k',point.k, ...
      'm',[],'comparison_available',false,'cluster_rank',0, ...
      'error_id',point.error_id);
    return;
  end
  singular = full.svd.aphys_singular_values_descending;
  traces = full.svd.physical_trace_vectors;
  primary = numel(singular);
  competitor = primary-1;
  K = numel(full.m);
  cluster_rank = numel(full.svd.cluster_index);
  selected = [competitor,primary];
  compact_svd = struct( ...
    'aphys_singular_values_descending',singular(selected), ...
    'physical_trace_vectors',traces(:,selected), ...
    'cluster_index',2,'cluster_delta',full.svd.cluster_delta);
  compact = struct('valid',true,'config',full.config,'k',full.k, ...
    'm',full.m,'comparison_available',cluster_rank == 1, ...
    'cluster_rank',cluster_rank,'error_id','', ...
    'primary_trace',traces(:,primary), ...
    'competitor_trace',traces(:,competitor), ...
    'primary_left',traces(1:K,primary), ...
    'primary_right',traces(K+1:end,primary), ...
    'competitor_left',traces(1:K,competitor), ...
    'competitor_right',traces(K+1:end,competitor), ...
    'svd',compact_svd);
end

function out = LOCAL_local_same_k_compare(a,b,edge_index)
%LOCAL_LOCAL_SAME_K_COMPARE Reuse the frozen comparison only at equal k.

  if ~isfield(a,'valid') || ~isfield(b,'valid') || ...
      ~a.valid || ~b.valid || a.k ~= b.k
    out = LOCAL_empty_comparison();
    out.edge_index = edge_index;
    out.object = 'APHYS_CENTER';
    out.status = 'EVALUATION_UNAVAILABLE';
  elseif ~(a.comparison_available && b.comparison_available)
    out = LOCAL_empty_comparison();
    out.edge_index = edge_index;
    out.config_a = a.config.id;
    out.config_b = b.config.id;
    out.object = 'APHYS_CENTER';
    out.k = a.k;
    out.status = 'MODE_IDENTITY_UNRESOLVED';
  else
    out = LOCAL_compare(a,b,'APHYS_CENTER',64,edge_index);
  end
end

function relation = LOCAL_local_relation(a,b,edge_index)
%LOCAL_LOCAL_RELATION Distinguish equal-k comparison from different-k data.

  relation = LOCAL_empty_local_relation();
  if ~isfield(a,'valid') || ~isfield(b,'valid') || ~a.valid || ~b.valid
    relation.status = 'EVALUATION_UNAVAILABLE';
    return;
  end
  relation.config_a = a.config.id;
  relation.config_b = b.config.id;
  relation.k_a = a.k;
  relation.k_b = b.k;
  relation.delta_k = b.k-a.k;
  relation.same_k = a.k == b.k;
  if ~relation.same_k
    relation.status = 'DIFFERENT_K_NOT_COMPARABLE';
    return;
  end
  relation.comparison = LOCAL_local_same_k_compare(a,b,edge_index);
  relation.status = relation.comparison.status;
end

function relation = LOCAL_empty_local_relation()
%LOCAL_EMPTY_LOCAL_RELATION Define one local-mode identity relation.

  relation = struct('config_a','','config_b','','k_a',NaN,'k_b',NaN, ...
    'delta_k',NaN,'same_k',false,'status','', ...
    'comparison',LOCAL_empty_comparison());
end

%% ==================== Point evaluation ====================
% These helpers build the matching objects, diagnostic spectrum, and mode.

function [out,evidence] = LOCAL_safe_point(k,label,model,cfg)
%LOCAL_SAFE_POINT Preserve one invalid record and continue later evaluations.

  try
    [out,evidence] = LOCAL_point(k,label,model,cfg);
  catch ME
    if ~LOCAL_expected_point_failure(ME)
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
    evidence = struct('valid',false,'config',cfg,'label',label,'k',k, ...
      'error_id',ME.identifier,'error_message',ME.message);
  end
end

function yes = LOCAL_expected_point_failure(ME)
%LOCAL_EXPECTED_POINT_FAILURE Classify fail-closed numerical point failures.

  id = ME.identifier;
  controlled = {'i7:QZScale','i7:QZClassification', ...
    'i73:ChannelCount','i73:FourierLabels','i73:NonfiniteMatrix', ...
    'i73:SurrogateSpectrum','i73:EigensystemResidual', ...
    'i73:CountPartition','i73:SVD','i73:SVDResidual', ...
    'MATLAB:singularMatrix','MATLAB:nearlySingularMatrix', ...
    'MATLAB:illConditionedMatrix','MATLAB:rankDeficientMatrix'};
  yes = any(strcmp(id,controlled)) || startsWith(id,'MATLAB:qz:') || ...
    startsWith(id,'MATLAB:eig:') || startsWith(id,'MATLAB:svd:');
end

function [out,evidence] = LOCAL_point(k,label,model,cfg)
%LOCAL_POINT Evaluate one fixed wavenumber and discretization configuration.

  warning_guard = LOCAL_solver_warning_guard();
  [Zp,Zm,beta_m,gamma,phase,qz_diagnostic] = ...
    LOCAL_cellsub(k,cfg.M,model,cfg);
  [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma);
  cellmap = LOCAL_center(k,cfg.M,model,cfg);
  clear warning_guard;

  K = numel(gamma);
  if K ~= cfg.K
    error('i73:ChannelCount','Configuration %s returned K=%d.',cfg.id,K);
  end
  m = (-cfg.M:cfg.M).';
  expected_beta = model.beta+2*pi*m/model.d;
  if ~isequal(beta_m,expected_beta)
    error('i73:FourierLabels', ...
      'Configuration %s returned unexpected Fourier labels.',cfg.id);
  end
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
    error('i73:NonfiniteMatrix', ...
      'Configuration %s point %s produced a nonfinite matrix.',cfg.id,label);
  end
  [Hsym_vectors,D] = eig(Hsym,'vector');
  imaginary_leakage = max(abs(imag(D)));
  if any(~isfinite(D)) || any(~isfinite(Hsym_vectors(:))) || ...
      imaginary_leakage > 100*unit
    error('i73:SurrogateSpectrum', ...
      'Configuration %s point %s has an unavailable Hsym spectrum.', ...
      cfg.id,label);
  end
  eigenvalues = real(D);
  eig_residual = norm(Hsym*Hsym_vectors- ...
    Hsym_vectors*diag(eigenvalues),'fro')/max(1,norm(Hsym,'fro'));
  eig_residual_tolerance = 1000*n*eps;
  if ~isfinite(eig_residual) || eig_residual > eig_residual_tolerance
    error('i73:EigensystemResidual', ...
      'Configuration %s point %s failed the eigensystem residual gate.', ...
      cfg.id,label);
  end
  counts = zeros(3,3);
  for qindex = 1:3
    counts(qindex,:) = [sum(eigenvalues>eta(qindex)), ...
      sum(eigenvalues<-eta(qindex)), ...
      sum(abs(eigenvalues)<=eta(qindex))];
  end
  if ~all(sum(counts,2) == n)
    error('i73:CountPartition', ...
      'Configuration %s point %s failed the sign-count partition.', ...
      cfg.id,label);
  end

  [~,near_order] = sort(abs(eigenvalues),'ascend');
  near_count = min(4,n);
  near_index = near_order(1:near_count);
  near_values = eigenvalues(near_index);
  cluster_delta = 1000*n*eps*max(1,scale_2);
  cluster_index = find(abs(eigenvalues) <= ...
    abs(eigenvalues(near_order(1)))+cluster_delta);
  competitor_index = near_order(find(~ismember(near_order,cluster_index),1));
  if n > 1
    near_abs_margin = abs(eigenvalues(near_order(2)))- ...
      abs(eigenvalues(near_order(1)));
    near_abs_ratio = abs(eigenvalues(near_order(1)))/ ...
      max(realmin,abs(eigenvalues(near_order(2))));
    other = near_order(2:end);
    signed_spectral_separation = min(abs( ...
      eigenvalues(other)-eigenvalues(near_order(1))));
  else
    near_abs_margin = NaN;
    near_abs_ratio = NaN;
    signed_spectral_separation = NaN;
  end

  identity_tolerance = 1000*n*eps;
  T_rcond = rcond(T);
  object_gate = T_rcond >= 1e-8 && ...
    assembly_error <= identity_tolerance && ...
    solve_error <= identity_tolerance;
  diagnostic_pass = object_gate && isempty(solve_warning_message);
  if isequal(counts(1,:),counts(2,:)) && isequal(counts(2,:),counts(3,:))
    band_sensitivity = 'STABLE';
  else
    band_sensitivity = 'UNSTABLE';
  end
  diagnostic_reason = LOCAL_diagnostic_reason(T_rcond,assembly_error, ...
    solve_error,identity_tolerance,solve_warning_message);

  svd_data = struct();
  if strcmp(label,'C')
    svd_data = LOCAL_svd_data(Adef,T,beta_m,gamma);
  end

  out = struct('config_id',cfg.id,'label',label,'k',k, ...
    'valid',true,'error_id','','error_message','', ...
    'ntot',cfg.ntot,'M',cfg.M,'K',K,'dimension',n, ...
    'T_rcond',T_rcond,'assembly_error',assembly_error, ...
    'solve_error',solve_error,'identity_tolerance',identity_tolerance, ...
    'scale_2',scale_2,'distance_2',distance_2, ...
    'relative_distance_2',distance_2/max(1,scale_2), ...
    'eta_50',eta(1),'eta_100',eta(2),'eta_200',eta(3), ...
    'relative_eta_100',eta(2)/max(1,scale_2), ...
    'imaginary_leakage',imaginary_leakage, ...
    'eig_residual',eig_residual, ...
    'eig_residual_tolerance',eig_residual_tolerance, ...
    'min_eigenvalue',min(eigenvalues), ...
    'max_eigenvalue',max(eigenvalues), ...
    'min_abs_eigenvalue',min(abs(eigenvalues)), ...
    'near_eigenvalues',near_values(:).', ...
    'near_abs_margin',near_abs_margin,'near_abs_ratio',near_abs_ratio, ...
    'signed_spectral_separation',signed_spectral_separation, ...
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
    'adef_sigma',LOCAL_field(svd_data,'adef_sigma',NaN), ...
    'adef_ratio',LOCAL_field(svd_data,'adef_ratio',NaN), ...
    'aphys_sigma',LOCAL_field(svd_data,'aphys_sigma',NaN), ...
    'aphys_ratio',LOCAL_field(svd_data,'aphys_ratio',NaN), ...
    'aphys_target_gap',LOCAL_field(svd_data,'target_gap',NaN), ...
    'aphys_target_ratio',LOCAL_field(svd_data,'target_ratio',NaN), ...
    'aphys_cluster_rank',LOCAL_field(svd_data,'cluster_rank',0), ...
    'aphys_svd_residual',LOCAL_field(svd_data,'residual',NaN), ...
    'qz_plus_stable',qz_diagnostic.plus.stable, ...
    'qz_plus_unstable',qz_diagnostic.plus.unstable, ...
    'qz_plus_neutral',qz_diagnostic.plus.neutral, ...
    'qz_plus_indeterminate',qz_diagnostic.plus.indeterminate, ...
    'qz_minus_stable',qz_diagnostic.minus.stable, ...
    'qz_minus_unstable',qz_diagnostic.minus.unstable, ...
    'qz_minus_neutral',qz_diagnostic.minus.neutral, ...
    'qz_minus_indeterminate',qz_diagnostic.minus.indeterminate, ...
    'Adef_rows',size(Adef,1),'T_rows',size(T,1), ...
    'elapsed_seconds',NaN);
  evidence = struct('valid',true,'config',cfg,'label',label,'k',k,'m',m, ...
    'beta_m',beta_m,'gamma',gamma,'phase',phase,'Adef',Adef, ...
    'T',T,'N0',N0,'L',L,'H',H,'Hsym',Hsym, ...
    'Hsym_eigenvalues',eigenvalues,'Hsym_vectors',Hsym_vectors, ...
    'near_index',near_index,'cluster_delta',cluster_delta, ...
    'cluster_index',cluster_index,'competitor_index',competitor_index, ...
    'band_multipliers',multipliers, ...
    'band_etas',eta,'band_counts',counts,'qz',qz_diagnostic, ...
    'svd',svd_data);
end

function data = LOCAL_svd_data(Adef,T,beta_m,gamma)
%LOCAL_SVD_DATA Form the four I7 metrics and physical primary/secondary modes.

  b = sqrt(1+abs(beta_m(:)).^2);
  rowwt = repmat(sqrt(1./b),2,1);
  ampwt = b+abs(gamma(:)).^2./b;
  colwt = repmat(1./sqrt(ampwt),2,1);
  Aphys = rowwt.*Adef.*colwt.';
  [Udef,Sdef,Vdef] = svd(Adef,'econ');
  [Uphys,Sphys,Vphys] = svd(Aphys,'econ');
  sdef = diag(Sdef);
  sphys = diag(Sphys);
  if numel(sphys) < 2 || any(~isfinite([sdef;sphys])) || ...
      sdef(1) <= 0 || sphys(1) <= 0
    error('i73:SVD','A singular spectrum is unavailable.');
  end
  target_index = numel(sphys);
  competitor_index = target_index-1;
  delta = 1000*numel(sphys)*eps*max(1,sphys(1));
  cluster_index = find(sphys <= sphys(end)+delta);
  q = colwt.*Vphys;
  trace = T*q;
  K = numel(beta_m);
  residual = max(norm(Aphys*Vphys-Uphys*Sphys,'fro'), ...
    norm(Aphys'*Uphys-Vphys*Sphys,'fro'))/max(1,norm(Aphys,'fro'));
  residual_tolerance = 1000*numel(sphys)*eps;
  if ~isfinite(residual) || residual > residual_tolerance
    error('i73:SVDResidual','The Aphys SVD residual gate failed.');
  end
  data = struct('Aphys',Aphys,'row_weight',rowwt, ...
    'column_weight',colwt,'adef_singular_values_descending',sdef, ...
    'aphys_singular_values_descending',sphys, ...
    'adef_sigma',sdef(end),'adef_ratio',sdef(end)/sdef(1), ...
    'aphys_sigma',sphys(end),'aphys_ratio',sphys(end)/sphys(1), ...
    'target_gap',sphys(end-1)-sphys(end), ...
    'target_ratio',sphys(end)/max(realmin,sphys(end-1)), ...
    'cluster_delta',delta,'cluster_rank',numel(cluster_index), ...
    'cluster_index',cluster_index,'target_index',target_index, ...
    'competitor_index',competitor_index, ...
    'residual',residual,'residual_tolerance',residual_tolerance, ...
    'adef_left_vectors',Udef,'adef_right_vectors',Vdef, ...
    'aphys_left_vectors',Uphys,'aphys_right_vectors',Vphys, ...
    'raw_port_vectors',q,'physical_trace_vectors',trace, ...
    'wall_left_vectors',trace(1:K,:), ...
    'wall_right_vectors',trace(K+1:end,:));
end

function text = LOCAL_diagnostic_reason(T_rcond,assembly_error, ...
    solve_error,tolerance,warning_message)
%LOCAL_DIAGNOSTIC_REASON Return the first failed finite-object reliability gate.

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

function out = LOCAL_config_result(cfg,points)
%LOCAL_CONFIG_RESULT Summarize the fixed endpoint sign-count change.

  left = points(1);
  right = points(3);
  if ~all([points.valid])
    out = struct('config_id',cfg.id,'ntot',cfg.ntot,'M',cfg.M, ...
      'K',cfg.K,'all_point_diagnostics_pass',false, ...
      'endpoint_outcome','EXECUTION_UNAVAILABLE','delta_negative',NaN, ...
      'delta_positive',NaN,'endpoint_band_sensitivity','UNAVAILABLE', ...
      'center_adef_sigma',points(2).adef_sigma, ...
      'center_adef_ratio',points(2).adef_ratio, ...
      'center_aphys_sigma',points(2).aphys_sigma, ...
      'center_aphys_ratio',points(2).aphys_ratio);
    return;
  end
  delta_negative = right.negative_100-left.negative_100;
  delta_positive = right.positive_100-left.positive_100;
  stable = all(strcmp({left.band_sensitivity,right.band_sensitivity}, ...
    'STABLE'));
  endpoints_pass = left.diagnostic_pass && right.diagnostic_pass;
  if ~endpoints_pass || ~stable || ...
      left.unresolved_100 > 0 || right.unresolved_100 > 0
    endpoint_outcome = 'UNRESOLVED';
  elseif delta_negative == 0
    endpoint_outcome = 'NO_JUMP';
  else
    endpoint_outcome = 'JUMP';
  end
  out = struct('config_id',cfg.id,'ntot',cfg.ntot,'M',cfg.M, ...
    'K',cfg.K,'all_point_diagnostics_pass',all([points.diagnostic_pass]), ...
    'endpoint_outcome',endpoint_outcome, ...
    'delta_negative',delta_negative,'delta_positive',delta_positive, ...
    'endpoint_band_sensitivity',LOCAL_stability(stable), ...
    'center_adef_sigma',points(2).adef_sigma, ...
    'center_adef_ratio',points(2).adef_ratio, ...
    'center_aphys_sigma',points(2).aphys_sigma, ...
    'center_aphys_ratio',points(2).aphys_ratio);
end

function text = LOCAL_stability(stable)
  if stable
    text = 'STABLE';
  else
    text = 'UNSTABLE';
  end
end

function value = LOCAL_field(data,name,fallback)
  if isfield(data,name)
    value = data.(name);
  else
    value = fallback;
  end
end

function out = LOCAL_empty_point()
%LOCAL_EMPTY_POINT Define the compact per-point result schema.

  out = struct('config_id','','label','','k',NaN,'valid',false, ...
    'error_id','','error_message','','ntot',0,'M',0, ...
    'K',0,'dimension',0,'T_rcond',NaN,'assembly_error',NaN, ...
    'solve_error',NaN,'identity_tolerance',NaN,'scale_2',NaN, ...
    'distance_2',NaN,'relative_distance_2',NaN,'eta_50',NaN, ...
    'eta_100',NaN,'eta_200',NaN,'relative_eta_100',NaN, ...
    'imaginary_leakage',NaN,'eig_residual',NaN, ...
    'eig_residual_tolerance',NaN,'min_eigenvalue',NaN, ...
    'max_eigenvalue',NaN,'min_abs_eigenvalue',NaN, ...
    'near_eigenvalues',NaN(1,4),'near_abs_margin',NaN, ...
    'near_abs_ratio',NaN,'signed_spectral_separation',NaN, ...
    'Hsym_cluster_delta',NaN, ...
    'Hsym_cluster_rank',0, ...
    'positive_50',0,'negative_50',0,'unresolved_50',0, ...
    'positive_100',0,'negative_100',0,'unresolved_100',0, ...
    'positive_200',0,'negative_200',0,'unresolved_200',0, ...
    'band_sensitivity','','object_gate',false, ...
    'diagnostic_pass',false,'diagnostic_reason','', ...
    'solve_warning_id','','solve_warning_message','', ...
    'adef_sigma',NaN,'adef_ratio',NaN, ...
    'aphys_sigma',NaN,'aphys_ratio',NaN,'aphys_target_gap',NaN, ...
    'aphys_target_ratio',NaN,'aphys_cluster_rank',0, ...
    'aphys_svd_residual',NaN,'qz_plus_stable',0, ...
    'qz_plus_unstable',0,'qz_plus_neutral',0, ...
    'qz_plus_indeterminate',0,'qz_minus_stable',0, ...
    'qz_minus_unstable',0,'qz_minus_neutral',0, ...
    'qz_minus_indeterminate',0,'Adef_rows',0,'T_rows',0, ...
    'elapsed_seconds',NaN);
end

function out = LOCAL_empty_config_result()
%LOCAL_EMPTY_CONFIG_RESULT Define the compact per-configuration schema.

  out = struct('config_id','','ntot',0,'M',0,'K',0, ...
    'all_point_diagnostics_pass',false,'endpoint_outcome','', ...
    'delta_negative',0,'delta_positive',0, ...
    'endpoint_band_sensitivity','', ...
    'center_adef_sigma',NaN,'center_adef_ratio',NaN, ...
    'center_aphys_sigma',NaN,'center_aphys_ratio',NaN);
end

%% ==================== Same-mode comparison ====================
% These helpers compare frozen objects in common physical trace coordinates.

function out = LOCAL_compare(a,b,object,Mmax,edge_index)
%LOCAL_COMPARE Apply the frozen simple-mode or cluster identity rule.

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
  out.tail_a_edge = LOCAL_tail_fractions(Qa,Mmax,min(a.config.M,b.config.M));
  out.tail_b_edge = LOCAL_tail_fractions(Qb,Mmax,min(a.config.M,b.config.M));
  out.tail_a_above_48 = LOCAL_tail_fractions(Qa,Mmax,48);
  out.tail_b_above_48 = LOCAL_tail_fractions(Qb,Mmax,48);
  if ~(ok_a && ok_b)
    out.status = 'MODE_IDENTITY_UNRESOLVED';
    return;
  end

  common_cutoff = min(a.config.M,b.config.M);
  if out.rank_a == 1 && out.rank_b == 1
    [out.primary_overlap,primary_available] = LOCAL_overlap( ...
      Xa(:,va.primary_index),Xb(:,vb.primary_index));
    [out.common_overlap,common_available] = LOCAL_common_overlap( ...
      Xa(:,va.primary_index),Xb(:,vb.primary_index),Mmax,common_cutoff);
    [out.cross_a_primary_b_competitor,cross_ab] = LOCAL_overlap( ...
      Xa(:,va.primary_index),Xb(:,vb.competitor_index));
    [out.cross_a_competitor_b_primary,cross_ba] = LOCAL_overlap( ...
      Xa(:,va.competitor_index),Xb(:,vb.primary_index));
    out.cross_max = max(out.cross_a_primary_b_competitor, ...
      out.cross_a_competitor_b_primary);
    out.method = 'SIMPLE_VECTOR';
    out.pass = primary_available && common_available && cross_ab && cross_ba && ...
      out.primary_overlap >= 0.99 && out.cross_max <= 0.5;
    if out.pass
      out.status = 'SAME_MODE';
    elseif cross_ab && cross_ba && out.cross_max > 0.5
      out.status = 'MODE_SWITCH';
    else
      out.status = 'MODE_IDENTITY_UNRESOLVED';
    end
  elseif out.rank_a == out.rank_b
    values = svd(Qa'*Qb,'econ');
    out.subspace_overlap = min(values);
    out.projection_a_to_b = norm(Qb'*Qa,'fro')^2/out.rank_a;
    out.projection_b_to_a = norm(Qa'*Qb,'fro')^2/out.rank_b;
    out.common_overlap = LOCAL_common_subspace_overlap( ...
      Qa,Qb,Mmax,common_cutoff);
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
%LOCAL_OBJECT_VIEW Select one same-k physical trace eigenspace or SVD space.

  if strcmp(object,'APHYS_CENTER')
    spectrum = evidence.svd.aphys_singular_values_descending;
    primary = numel(spectrum);
    competitor = primary-1;
    view = struct('trace_vectors',evidence.svd.physical_trace_vectors, ...
      'primary_index',primary,'competitor_index',competitor, ...
      'cluster_index',evidence.svd.cluster_index, ...
      'gap',spectrum(end-1)-spectrum(end), ...
      'ratio',spectrum(end)/max(realmin,spectrum(end-1)), ...
      'delta',evidence.svd.cluster_delta,'signed_gap',NaN);
  else
    spectrum = evidence.Hsym_eigenvalues;
    [magnitude,order] = sort(abs(spectrum),'ascend');
    primary = order(1);
    competitor = order(2);
    cluster = find(abs(abs(spectrum)-magnitude(1)) <= ...
      evidence.cluster_delta);
    others = order(2:end);
    view = struct('trace_vectors',evidence.Hsym_vectors, ...
      'primary_index',primary,'competitor_index',competitor, ...
      'cluster_index',cluster,'gap',magnitude(2)-magnitude(1), ...
      'ratio',magnitude(1)/max(realmin,magnitude(2)), ...
      'delta',evidence.cluster_delta, ...
      'signed_gap',min(abs(spectrum(others)-spectrum(primary))));
  end
end

function embedded = LOCAL_embed_trace(trace,m,Mmax)
%LOCAL_EMBED_TRACE Zero-fill left/right blocks by exact Fourier labels.

  m = m(:);
  K = numel(m);
  if size(trace,1) ~= 2*K || numel(unique(m)) ~= K || ...
      any(m ~= fix(m)) || any(abs(m) > Mmax)
    error('i73:TraceEmbedding','A trace cannot be embedded by its m labels.');
  end
  Kmax = 2*Mmax+1;
  index = m+Mmax+1;
  embedded = zeros(2*Kmax,size(trace,2),'like',trace);
  embedded(index,:) = trace(1:K,:);
  embedded(Kmax+index,:) = trace(K+1:end,:);
end

function [Q,available] = LOCAL_trace_basis(X)
%LOCAL_TRACE_BASIS Orthonormalize one mapped physical-trace cluster.

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
%LOCAL_OVERLAP Return phase/scale-invariant overlap of two nonzero vectors.

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
%LOCAL_COMMON_OVERLAP Compare normalized projections onto shared m labels.

  mask = LOCAL_trace_mask(Mmax,Mcut);
  [rho,available] = LOCAL_overlap(x(mask),y(mask));
end

function rho = LOCAL_common_subspace_overlap(Qa,Qb,Mmax,Mcut)
%LOCAL_COMMON_SUBSPACE_OVERLAP Compare projected cluster subspaces.

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
%LOCAL_TRACE_MASK Select both wall blocks for absolute order at most Mcut.

  one = abs((-Mmax:Mmax).') <= Mcut;
  mask = [one;one];
end

function out = LOCAL_tail_fractions(Q,Mmax,Mcut)
%LOCAL_TAIL_FRACTIONS Report squared tail energy in total and each wall.

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

function pass = LOCAL_count_gate(points)
%LOCAL_COUNT_GATE Check the frozen endpoint triples for all configurations.

  pass = true;
  for j = 1:size(points,1)
    left = points(j,1);
    right = points(j,3);
    pass = pass && left.valid && right.valid && ...
      left.diagnostic_pass && right.diagnostic_pass && ...
      strcmp(left.band_sensitivity,'STABLE') && ...
      strcmp(right.band_sensitivity,'STABLE') && ...
      all([left.negative_50,left.negative_100,left.negative_200] == 0) && ...
      all([right.negative_50,right.negative_100,right.negative_200] == 1) && ...
      all([left.unresolved_50,left.unresolved_100,left.unresolved_200, ...
      right.unresolved_50,right.unresolved_100,right.unresolved_200] == 0);
  end
end

function oracle = LOCAL_comparison_oracle()
%LOCAL_COMPARISON_ORACLE Check scale, embedding, tail, and subspace invariance.

  x = (1:6).';
  y = 1e8*exp(1i*pi/7)*x;
  [scaled,scaled_ok] = LOCAL_overlap(x,y);
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

function out = LOCAL_empty_comparison()
%LOCAL_EMPTY_COMPARISON Define the fixed edge/object comparison schema.

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

function out = LOCAL_first_failure(points,comparisons,count_pass,oracle_pass)
%LOCAL_FIRST_FAILURE Return the first failed evaluation or stability gate.

  out = struct('code','NONE','config_id','','point','','edge',0, ...
    'object','','message','');
  for j = 1:numel(points)
    if ~points(j).valid
      out = struct('code',points(j).error_id, ...
        'config_id',points(j).config_id,'point',points(j).label, ...
        'edge',0,'object','','message',points(j).error_message);
      return;
    elseif ~points(j).diagnostic_pass
      out = struct('code',points(j).diagnostic_reason, ...
        'config_id',points(j).config_id,'point',points(j).label, ...
        'edge',0,'object','', ...
        'message','A finite-object reliability gate failed.');
      return;
    end
  end
  if ~count_pass
    out.code = 'COUNT_STABILITY';
    out.message = 'A frozen endpoint count or band gate failed.';
    return;
  end
  if ~oracle_pass
    out.code = 'COMPARISON_ORACLE';
    out.message = 'The comparison oracle failed.';
    return;
  end
  for j = 1:numel(comparisons)
    if ~comparisons(j).pass
      out = struct('code',comparisons(j).status, ...
        'config_id',comparisons(j).config_a,'point','', ...
        'edge',comparisons(j).edge_index, ...
        'object',comparisons(j).object, ...
        'message','A frozen same-mode edge failed.');
      return;
    end
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

function [Zp,Zm,bm,gamma,phase,qz_diagnostic] = ...
    LOCAL_cellsub(k,M,model,cfg)
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
  [Zp,qz_plus] = LOCAL_qzsub(A,B,K);
  [Zm,qz_minus] = LOCAL_qzsub(B,A,K);
  bm = chans.beta_m(:);
  gamma = chans.gamma_m(:);
  phase = chans.phase(:);
  qz_diagnostic = struct('plus',qz_plus,'minus',qz_minus);
end

function [Zs,diagnostic] = LOCAL_qzsub(A,B,K)
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
  diagnostic = struct('stable',sum(stable),'unstable',sum(unstable), ...
    'neutral',sum(neutral),'indeterminate',sum(indet), ...
    'residual',res,'tolerance',tol,'pencil_order',size(A,1));
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
% These helpers bound proxy allocations and qualify construction solves.

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
