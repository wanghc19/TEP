function out = scan_i7(output)
%SCAN_I7 Adaptively scan an elliptical center cell for a guided-mode dip.
% Purpose:
%   Locate the best valid I7.1 center-ellipse candidate inside the numerical
%   projected gaps of the unchanged circular half-guides.
% Input:
%   output   - Explicit run output directory created by the monitored launcher.
% Output:
%   out      - Seven scalar fields beta, k, adef_sigma, adef_ratio,
%              aphys_sigma, aphys_ratio, and runtime.
% Main algorithm:
%   Classify the lead gaps on the projgap grid, screen the center ellipse on
%   a 0.025 grid, and refine at most two candidates with one fixed final
%   spatial discretization and M=48. Invalid evaluations are logged and
%   excluded; repeated final nodes are served by a fixed-configuration cache.
% Based on:
%   draft/examples/projgap.m and draft/examples/betagmode.m on main.
% Main changes:
%   Replace the empty center transfer by the scattering matrix of one
%   epsrel=2 ellipse with semi-axes 0.25 and 0.16, and use a bounded
%   gap-aware adaptive scan. Bound the public direct-kernel allocation by
%   passing a target-batched evaluator to the proxy-source term.
% Numerical goal:
%   Deliver the valid final-configuration point with minimum aphys_ratio;
%   the result is a current scan best and does not certify an eigenvalue.

  if nargin ~= 1
    error('i7:Arguments','Pass one explicit output directory.');
  end
  output = char(output);
  if ~exist(output,'dir')
    error('i7:OutputMissing','The monitored launcher must create %s.',output);
  end
  if isfile(fullfile(output,'out.mat'))
    error('i7:OutputExists','out.mat already exists in %s.',output);
  end

  tstart = tic;
  beta = 0.5;
  % Keep the circular leads at epsrel=17; vary only the center material.
  model = struct('beta',beta,'d',1,'R',0.2,'epsrel',17, ...
    'epsrel_center',2, ...
    'XL',-0.5,'XR',0.5,'H',1.1,'pdist',0.2, ...
    'flag_geom','ellipse','ellipse_axes',[0.25,0.16]);
  coarse = struct('name','coarse','ntot',160,'nside',120,'ntop',120, ...
    'nproxy',64,'mpw',24);
  final = struct('name','final','ntot',256,'nside',160,'ntop',160, ...
    'nproxy',80,'mpw',32);
  scan = struct('model',model,'coarse',coarse,'final',final,'gap_M',12, ...
    'screen_M',24,'final_M',48,'gap_step',0.05, ...
    'screen_step',0.025,'candidate_halfwidth',0.025, ...
    'max_candidates',2,'max_refine_levels',7, ...
    'interval_tolerance',1e-4,'soft_seconds',1500);
  kernel_check = LOCAL_kernel_check();
  scan.kernel_check = kernel_check;
  save(fullfile(output,'kernel-checkpoint.mat'),'kernel_check','-v7');
  scan.empty_center_regression = LOCAL_empty_center_regression();
  if scan.empty_center_regression > 1e-14
    error('i7:EmptyCenterRegression', ...
      'The center formula does not reduce to the approved empty-cell matrix.');
  end
  history = repmat(LOCAL_record('', '',NaN,NaN,false, ...
    NaN,NaN,NaN,NaN,'',NaN),0,1);

  % --- stage 1: classify the circular-lead projected gaps ---
  gap_k = 1.45:scan.gap_step:2.25;
  gap_valid = false(size(gap_k));
  for j = 1:numel(gap_k)
    timer = tic;
    warning_guard = LOCAL_solver_warning_guard();
    lastwarn('');
    try
      LOCAL_cellsub(gap_k(j),scan.gap_M,model,coarse);
      gap_valid(j) = true;
      reason = '';
    catch ME
      reason = LOCAL_reason(ME);
    end
    clear warning_guard;
    [warn_message,warn_id] = lastwarn;
    if gap_valid(j) && ~isempty(warn_message)
      reason = sprintf('warning %s: %s',warn_id,warn_message);
    end
    history(end+1) = LOCAL_record('gap','coarse',scan.gap_M, ...
      gap_k(j),gap_valid(j),NaN,NaN,NaN,NaN,reason,toc(timer));
    LOCAL_print_record(history(end));
  end
  gap_windows = LOCAL_gapwins(gap_k,gap_valid);
  if isempty(gap_windows)
    scan.stop_reason = 'no valid sampled projected gap';
    LOCAL_save_failure(output,history,scan);
    error('i7:NoGap','No valid sampled projected gap was found.');
  end

  % Evaluate one deterministic final point before optional low-order work.
  cache = struct('k',zeros(0,1),'record',repmat(LOCAL_record('', '', ...
    NaN,NaN,false,NaN,NaN,NaN,NaN,'',NaN),0,1));
  gap_width = diff(gap_windows,1,2);
  [~,widest_gap] = max(gap_width);
  pilot_k = mean(gap_windows(widest_gap,:));
  [cache,pilot,~] = LOCAL_cached_point(cache,pilot_k, ...
    scan.final_M,model,final);
  pilot.stage = 'final-pilot';
  history(end+1) = pilot;
  LOCAL_print_record(pilot);
  save(fullfile(output,'pilot-checkpoint.mat'),'pilot','gap_k', ...
    'gap_valid','gap_windows','scan','-v7');

  % --- stage 2: screen the ellipse on a wider low-order grid ---
  screen_all = 1.45:scan.screen_step:2.25;
  screen_k = screen_all(LOCAL_inwindows(screen_all,gap_windows));
  screen = repmat(LOCAL_record('', '',NaN,NaN,false, ...
    NaN,NaN,NaN,NaN,'',NaN),numel(screen_k),1);
  for j = 1:numel(screen_k)
    screen(j) = LOCAL_safe_point('screen','coarse',screen_k(j), ...
      scan.screen_M,model,coarse);
    history(end+1) = screen(j);
    LOCAL_print_record(screen(j));
  end
  candidate_k = LOCAL_candidates(screen,scan.max_candidates,scan.screen_step);

  % --- stage 3: evaluate and refine candidates only at the final config ---
  cache_hits = 0;
  candidate_stop = cell(numel(candidate_k),1);
  level_trace = repmat(struct('candidate',NaN,'level',NaN, ...
    'interval',[NaN,NaN],'k',[],'valid',[],'aphys_ratio',[], ...
    'cache_hit',[],'blocked_k',[],'stop',''),0,1);
  for c = 1:numel(candidate_k)
    window = LOCAL_seed_window(candidate_k(c),gap_windows, ...
      scan.candidate_halfwidth);
    interval = window;
    candidate_stop{c} = 'maximum refinement levels reached';
    for level = 0:scan.max_refine_levels
      if toc(tstart) >= scan.soft_seconds
        candidate_stop{c} = '1500-second internal scan stop';
        break;
      end
      if interval(2) == interval(1)
        level_k = interval(1);
      else
        level_k = linspace(interval(1),interval(2),5);
      end
      level_record = repmat(LOCAL_record('', '',NaN,NaN,false, ...
        NaN,NaN,NaN,NaN,'',NaN),numel(level_k),1);
      level_hit = false(size(level_k));
      for j = 1:numel(level_k)
        [cache,level_record(j),hit] = LOCAL_cached_point(cache,level_k(j), ...
          scan.final_M,model,final);
        level_hit(j) = hit;
        cache_hits = cache_hits+hit;
        if ~hit
          level_record(j).stage = sprintf('final-c%d-l%d',c,level);
          history(end+1) = level_record(j);
          LOCAL_print_record(level_record(j));
        end
      end
      valid = [level_record.valid];
      level_stop = '';
      blocked_k = [];
      if ~any(valid)
        level_stop = 'all points invalid at current final level';
      else
        valid_index = find(valid);
        [~,valid_min] = min([level_record(valid_index).aphys_ratio]);
        jmin = valid_index(valid_min);
        if numel(level_k) == 1 || jmin == 1 || jmin == numel(level_k)
          level_stop = ['current final minimum lies on scan boundary; ', ...
            'low-order basin not confirmed'];
        elseif ~(valid(jmin-1) && valid(jmin+1))
          level_stop = 'invalid point blocks a valid refinement bracket';
        else
          next_interval = level_k(jmin+[-1,1]);
          cache_invalid = ~[cache.record.valid];
          invalid_k = cache.k(cache_invalid);
          blocked_k = invalid_k(invalid_k > next_interval(1)+1e-13 & ...
            invalid_k < next_interval(2)-1e-13);
          if ~isempty(blocked_k)
            level_stop = 'known final-invalid point blocks refinement bracket';
          elseif diff(next_interval) <= scan.interval_tolerance
            level_stop = 'refinement interval tolerance reached';
          elseif level == scan.max_refine_levels
            level_stop = 'maximum refinement levels reached';
          else
            interval = next_interval;
          end
        end
      end
      level_trace(end+1) = struct('candidate',c,'level',level, ...
        'interval',[level_k(1),level_k(end)],'k',level_k, ...
        'valid',valid,'aphys_ratio',[level_record.aphys_ratio], ...
        'cache_hit',level_hit,'blocked_k',blocked_k,'stop',level_stop);
      if ~isempty(level_stop)
        candidate_stop{c} = level_stop;
        break;
      end
    end
  end

  % --- stage 4: select one valid final point and save the audit trail ---
  final_records = cache.record;
  valid = [final_records.valid];
  if ~any(valid)
    scan.stop_reason = 'no valid final-configuration evaluation';
    scan.gap_k = gap_k;
    scan.gap_valid = gap_valid;
    scan.gap_windows = gap_windows;
    scan.pilot_k = pilot_k;
    scan.screen_k = screen_k;
    scan.candidate_k = candidate_k;
    scan.candidate_stop = candidate_stop;
    scan.level_trace = level_trace;
    scan.screen_valid_count = sum([screen.valid]);
    scan.cache_hits = cache_hits;
    LOCAL_save_failure(output,history,scan);
    error('i7:NoFinalPoint','No final-configuration point was valid.');
  end
  valid_index = find(valid);
  [~,valid_min] = min([final_records(valid_index).aphys_ratio]);
  jbest = valid_index(valid_min);
  best = final_records(jbest);
  repeat = LOCAL_safe_point('final-repeat','final',best.k, ...
    scan.final_M,model,final);
  history(end+1) = repeat;
  LOCAL_print_record(repeat);
  if ~repeat.valid
    scan.stop_reason = 'final winner repeat was invalid';
    LOCAL_save_failure(output,history,scan);
    error('i7:FinalRepeat','The selected final point failed its repeat evaluation.');
  end
  original_metrics = [best.adef_sigma,best.adef_ratio, ...
    best.aphys_sigma,best.aphys_ratio];
  repeat_metrics = [repeat.adef_sigma,repeat.adef_ratio, ...
    repeat.aphys_sigma,repeat.aphys_ratio];
  scan.final_repeat_defect = norm(repeat_metrics-original_metrics) / ...
    max(1,norm(original_metrics));
  if scan.final_repeat_defect > 1e-11
    scan.stop_reason = 'final winner repeat did not reproduce';
    LOCAL_save_failure(output,history,scan);
    error('i7:FinalRepeat','The selected final metrics did not reproduce.');
  end
  runtime = toc(tstart);
  out = struct('beta',beta,'k',best.k,'adef_sigma',best.adef_sigma, ...
    'adef_ratio',best.adef_ratio,'aphys_sigma',best.aphys_sigma, ...
    'aphys_ratio',best.aphys_ratio,'runtime',runtime);

  scan.gap_k = gap_k;
  scan.gap_valid = gap_valid;
  scan.gap_windows = gap_windows;
  scan.pilot_k = pilot_k;
  scan.screen_k = screen_k;
  scan.candidate_k = candidate_k;
  scan.candidate_stop = candidate_stop;
  scan.level_trace = level_trace;
  scan.screen_valid_count = sum([screen.valid]);
  scan.cache_hits = cache_hits;
  scan.final_unique_evaluations = numel(cache.k);
  if isempty(candidate_k)
    scan.stop_reason = 'final pilot delivered; no valid screening candidate';
  else
    scan.stop_reason = 'bounded adaptive scan completed';
  end
  save(fullfile(output,'out.mat'),'out','-v7');
  save(fullfile(output,'scan.mat'),'history','scan','-v7');
  writetable(struct2table(history),fullfile(output,'history.csv'));
  LOCAL_summary(fullfile(output,'summary.txt'),out,scan,history);
end

%% ==================== Search helpers ====================
% These helpers define bounded gap windows, candidates, caching, and records.

function record = LOCAL_safe_point(stage,config,k,M,model,cfg)
  timer = tic;
  warning_guard = LOCAL_solver_warning_guard();
  lastwarn('');
  try
    [asig,arat,psig,prat] = LOCAL_point(k,M,model,cfg);
    valid = all(isfinite([asig,arat,psig,prat]));
    if valid
      reason = '';
    else
      reason = 'nonfinite singular-value metric';
    end
  catch ME
    asig = NaN; arat = NaN; psig = NaN; prat = NaN;
    valid = false; reason = LOCAL_reason(ME);
  end
  clear warning_guard;
  [warn_message,warn_id] = lastwarn;
  if valid && ~isempty(warn_message)
    reason = sprintf('warning %s: %s',warn_id,warn_message);
  end
  record = LOCAL_record(stage,config,M,k,valid,asig,arat,psig,prat, ...
    reason,toc(timer));
end

function [cache,record,hit] = LOCAL_cached_point(cache,k,M,model,cfg)
  match = find(abs(cache.k-k) <= 1e-13,1);
  hit = ~isempty(match);
  if hit
    record = cache.record(match);
    return;
  end
  record = LOCAL_safe_point('final',cfg.name,k,M,model,cfg);
  cache.k(end+1,1) = k;
  cache.record(end+1,1) = record;
end

function candidate_k = LOCAL_candidates(screen,max_candidates,step)
  valid = [screen.valid];
  if ~any(valid)
    candidate_k = [];
    return;
  end
  valid_index = find(valid);
  [~,valid_min] = min([screen(valid_index).aphys_ratio]);
  global_min = valid_index(valid_min);
  selected = global_min;
  local = [];
  for j = 2:numel(screen)-1
    adjacent = abs(screen(j).k-screen(j-1).k-step) <= 1e-12 && ...
      abs(screen(j+1).k-screen(j).k-step) <= 1e-12;
    if adjacent && valid(j-1) && valid(j) && valid(j+1) && ...
        screen(j).aphys_ratio < screen(j-1).aphys_ratio && ...
        screen(j).aphys_ratio < screen(j+1).aphys_ratio
      local(end+1) = j; %#ok<AGROW>
    end
  end
  if ~isempty(local)
    [~,order] = sort([screen(local).aphys_ratio],'ascend');
    local = local(order);
    for j = 1:numel(local)
      if ~ismember(local(j),selected)
        selected(end+1) = local(j); %#ok<AGROW>
      end
      if numel(selected) == max_candidates
        break;
      end
    end
  end
  candidate_k = [screen(selected).k];
end

function interval = LOCAL_seed_window(seed,windows,halfwidth)
  match = find(seed >= windows(:,1)-1e-13 & ...
    seed <= windows(:,2)+1e-13,1);
  if isempty(match)
    error('i7:SeedOutsideGap','A screening seed lies outside all gap windows.');
  end
  interval = [max(windows(match,1),seed-halfwidth), ...
    min(windows(match,2),seed+halfwidth)];
end

%% ==================== Kernel adaptation ====================
% These helpers bound proxy-source allocations and verify the public hook.

function report = LOCAL_kernel_check()
%LOCAL_KERNEL_CHECK Compare public and target-batched direct-kernel paths.

  wavek = 1.7;
  source_angle = 2*pi*(0:16)/17;
  sources = [0.14*cos(source_angle);0.11*sin(source_angle)];
  charge = exp(1i*(0:16)/7);
  target_parameter = linspace(0,1,777);
  targ = [-0.43+0.86*target_parameter; ...
    0.31+0.09*sin(2*pi*target_parameter)];
  [pot0,grad0,hess0] = kernel.h2d_directch( ...
    wavek,sources,charge,targ);
  [pot1,grad1,hess1] = LOCAL_h2d_chunked_public( ...
    wavek,sources,charge,targ);
  direct_relative = [LOCAL_relative(pot1,pot0), ...
    LOCAL_relative(grad1,grad0),LOCAL_relative(hess1,hess0)];

  pars = struct('k',wavek,'beta',0.5,'d',1,'periodic_axis','y');
  mfscfg = struct('H',0.7,'proxy_dist',0.2,'N_side',16, ...
    'N_top',16,'N_proxy_edge',12,'M_pw',8);
  proxy = kernel.precomp_proxy(pars,mfscfg);
  src = [-0.21,-0.07,0.09,0.23;-0.18,0.04,0.17,-0.09];
  trg_parameter = linspace(0,1,137);
  trg = [-0.34+0.68*trg_parameter; ...
    0.29+0.13*cos(2*pi*trg_parameter)];
  qp_default = cell(1,6);
  qp_public = cell(1,6);
  qp_chunked = cell(1,6);
  [qp_default{:}] = kernel.qpgreen_mfs_pairmat(src,trg,pars,proxy);
  pars.h2d_evaluator = @kernel.h2d_directch;
  [qp_public{:}] = kernel.qpgreen_mfs_pairmat(src,trg,pars,proxy);
  pars.h2d_evaluator = @LOCAL_h2d_chunked_public;
  [qp_chunked{:}] = kernel.qpgreen_mfs_pairmat(src,trg,pars,proxy);
  qp_public_relative = zeros(1,6);
  qp_chunked_relative = zeros(1,6);
  for j = 1:6
    qp_public_relative(j) = LOCAL_relative(qp_public{j},qp_default{j});
    qp_chunked_relative(j) = LOCAL_relative(qp_chunked{j},qp_default{j});
  end

  tolerance = 5e-14;
  report = struct('public_h2d_file',which('kernel.h2d_directch'), ...
    'public_h2d_all',{which('kernel.h2d_directch','-all')}, ...
    'qpgreen_file',which('kernel.qpgreen_mfs_pairmat'), ...
    'direct_target_count',size(targ,2), ...
    'qpgreen_pair_count',size(src,2)*size(trg,2), ...
    'target_batch',512,'direct_relative',direct_relative, ...
    'qpgreen_public_relative',qp_public_relative, ...
    'qpgreen_chunked_relative',qp_chunked_relative, ...
    'tolerance',tolerance);
  report.pass = max([direct_relative,qp_public_relative, ...
    qp_chunked_relative]) <= tolerance;
  fprintf(1,['kernel-check direct=[%.3e %.3e %.3e] ', ...
    'qp-public-max=%.3e qp-chunked-max=%.3e pass=%d\n'], ...
    direct_relative,max(qp_public_relative), ...
    max(qp_chunked_relative),report.pass);
  if ~report.pass
    error('i7:KernelRegression','The public kernel-hook regression failed.');
  end
end

function [pot,grad,hess] = LOCAL_h2d_chunked_public( ...
    wavek,sources,charge,targ)
%LOCAL_H2D_CHUNKED_PUBLIC Call the public kernel on contiguous target batches.
% Passing too many targets at once creates large target-by-source temporary
% arrays in the public kernel and can consume substantial memory.

  nt = size(targ,2);
  pot = zeros(1,nt);
  grad = zeros(2,nt);
  hess = zeros(3,nt);
  target_batch = 512; % Adjust the number of target points processed per batch.
  for first = 1:target_batch:nt
    index = first:min(first+target_batch-1,nt);
    [pot(:,index),grad(:,index),hess(:,index)] = ...
      kernel.h2d_directch(wavek,sources,charge,targ(:,index));
  end
end

function relative = LOCAL_relative(actual,reference)
  relative = norm(actual(:)-reference(:))/max(1,norm(reference(:)));
end

function inside = LOCAL_inwindows(kvals,windows)
  inside = false(size(kvals));
  for j = 1:size(windows,1)
    inside = inside | (kvals >= windows(j,1)-1e-13 & ...
      kvals <= windows(j,2)+1e-13);
  end
end

function windows = LOCAL_gapwins(kvals,ingap)
  edge = diff([false,ingap,false]);
  first = find(edge == 1);
  last = find(edge == -1)-1;
  windows = zeros(numel(first),2);
  for j = 1:numel(first)
    if first(j) == 1
      windows(j,1) = kvals(1);
    else
      windows(j,1) = 0.5*(kvals(first(j)-1)+kvals(first(j)));
    end
    if last(j) == numel(kvals)
      windows(j,2) = kvals(end);
    else
      windows(j,2) = 0.5*(kvals(last(j))+kvals(last(j)+1));
    end
  end
end

function record = LOCAL_record(stage,config,M,k,valid,asig,arat, ...
    psig,prat,reason,seconds)
  record = struct('stage',stage,'config',config,'M',M,'k',k, ...
    'valid',logical(valid),'adef_sigma',asig,'adef_ratio',arat, ...
    'aphys_sigma',psig,'aphys_ratio',prat,'reason',reason, ...
    'seconds',seconds);
end

function reason = LOCAL_reason(ME)
  reason = sprintf('%s: %s',ME.identifier,ME.message);
  reason = regexprep(reason,'[\r\n]+',' ');
end

function cleanup = LOCAL_solver_warning_guard()
  state = warning;
  cleanup = onCleanup(@() warning(state));
  warning('error','MATLAB:singularMatrix');
  warning('error','MATLAB:nearlySingularMatrix');
  warning('error','MATLAB:illConditionedMatrix');
  warning('error','MATLAB:rankDeficientMatrix');
end

function LOCAL_print_record(record)
  if record.valid && isfinite(record.aphys_ratio)
    fprintf(1,'%s k=%.12g valid=1 aphys_ratio=%.6e seconds=%.3f\n', ...
      record.stage,record.k,record.aphys_ratio,record.seconds);
  elseif record.valid
    fprintf(1,'%s k=%.12g valid=1 seconds=%.3f\n', ...
      record.stage,record.k,record.seconds);
  else
    fprintf(1,'%s k=%.12g valid=0 seconds=%.3f reason=%s\n', ...
      record.stage,record.k,record.seconds,record.reason);
  end
end

%% ==================== Point evaluation ====================
% These helpers construct and score the lead-center matching matrix.

function [asig,arat,psig,prat] = LOCAL_point(k,M,model,cfg)
%LOCAL_POINT Evaluate four singular-value metrics at one configuration.

  [Zp,Zm,bm,gamma] = LOCAL_cellsub(k,M,model,cfg);
  [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma);
  cellmap = LOCAL_center(k,M,model,cfg);
  G = diag(gamma);
  Adef = [(1i*G-Lm)*cellmap.R_L-(1i*G+Lm), ...
    (1i*G-Lm)*cellmap.T_RL; ...
    (1i*G-Lp)*cellmap.T_LR, ...
    (1i*G-Lp)*cellmap.R_R-(1i*G+Lp)];

  b = sqrt(1+abs(bm).^2);
  rowwt = repmat(sqrt(1./b),2,1);
  ampwt = b+abs(gamma).^2./b;
  colwt = repmat(1./sqrt(ampwt),2,1);
  Aphys = rowwt.*Adef.*colwt.';

  sval = sort(svd(Adef,'econ'),'ascend');
  asig = sval(1);
  arat = sval(1)/sval(end);
  sval = sort(svd(Aphys,'econ'),'ascend');
  psig = sval(1);
  prat = sval(1)/sval(end);
end

function defect = LOCAL_empty_center_regression()
%LOCAL_EMPTY_CENTER_REGRESSION Verify the approved empty-cell reduction.

  K = 3;
  gamma = [0.7;1.1i;2.3i];
  G = diag(gamma);
  phase = exp(1i*gamma);
  E = diag(phase);
  Lp = reshape((1:9)+1i*(9:-1:1),K,K)/17;
  Lm = reshape((9:-1:1)-1i*(1:9),K,K)/19;
  R = zeros(K);
  Acenter = [(1i*G-Lm)*R-(1i*G+Lm),(1i*G-Lm)*E; ...
    (1i*G-Lp)*E,(1i*G-Lp)*R-(1i*G+Lp)];
  Aempty = [-(1i*G+Lm),(1i*G-Lm)*E; ...
    (1i*G-Lp)*E,-(1i*G+Lp)];
  defect = norm(Acenter-Aempty,'fro')/max(1,norm(Aempty,'fro'));
end

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

%% ==================== Output helpers ====================
% These helpers save failure evidence and the compact successful summary.

function LOCAL_save_failure(output,history,scan)
  save(fullfile(output,'scan-failure.mat'),'history','scan','-v7');
  writetable(struct2table(history),fullfile(output,'history.csv'));
end

function LOCAL_summary(path,out,scan,history)
  fid = fopen(path,'w');
  if fid < 0
    error('i7:SummaryOpen','Cannot open %s.',path);
  end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'I7.1 current scan best\n');
  fprintf(fid,'k=%.17g\naphys_ratio=%.17g\n',out.k,out.aphys_ratio);
  fprintf(fid,'adef_sigma=%.17g\nadef_ratio=%.17g\n', ...
    out.adef_sigma,out.adef_ratio);
  fprintf(fid,'aphys_sigma=%.17g\nruntime_seconds=%.9f\n', ...
    out.aphys_sigma,out.runtime);
  fprintf(fid,'gap_windows=');
  fprintf(fid,' [%.9g,%.9g]',scan.gap_windows.');
  fprintf(fid,'\nfinal_unique_evaluations=%d\ncache_hits=%d\n', ...
    scan.final_unique_evaluations,scan.cache_hits);
  fprintf(fid,'invalid_evaluations=%d\nstop_reason=%s\n', ...
    sum(~[history.valid]),scan.stop_reason);
  for j = 1:numel(scan.candidate_stop)
    fprintf(fid,'candidate_%d_stop=%s\n',j,scan.candidate_stop{j});
  end
  clear cleanup;
end
