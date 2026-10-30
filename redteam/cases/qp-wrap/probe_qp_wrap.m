function result = probe_qp_wrap(output_dir)
%PROBE_QP_WRAP Inspect the actual I9 proxy kernel across its wrapping line.
% Purpose:
%   Compare unwrapped kernel traces with forced quasiperiodic repetition.
% Based on:
%   I9.2 k, beta and proxy settings; this is a new diagnostic, not a copied
%   field reconstruction or an independent quasi-periodic Green solver.
% Main algorithm:
%   Evaluate one direct Helmholtz source plus the saved-form proxy sources at
%   opposite edges, then compare actual pairmat values across a wrapping line.
% Input:
%   output_dir: explicit directory receiving all numerical output.
% Output:
%   result: ordinary floating-point diagnostics; no spectral error bound.
% Dependencies:
%   kernel.precomp_proxy, kernel.h2d_directch, kernel.qpgreen_mfs_pairmat.
% Numerical goal:
%   Expose whether an external seam identity can hide an internal wrap defect.
%   No BIE field, FEM field, candidate search or FMM call is performed.

  if ~exist(output_dir,'dir'), mkdir(output_dir); end
  timer = tic;
  % Frozen I9.2 physical and proxy parameters; grids are diagnostic only.
  pars = struct('k',1.5584378941820909,'beta',0.5,'d',1,'periodic_axis','y');
  cfg = struct('H',1.1,'proxy_dist',0.2,'N_side',160, ...
    'N_top',160,'N_proxy_edge',80,'M_pw',32);
  grids = [79,157];
  delta = 2.^[-20,-28,-36];
  % Screening thresholds are resolution tests, not certified rounding bounds.
  thresholds = struct('value',1e-11,'gradient',1e-10,'hessian',1e-8);
  phase = exp(1i*pars.beta*pars.d);
  source = [0;-0.137];
  wrap_y = source(2)+pars.d/2;

  % --- stage 1: one proxy least-squares solve with actual I9.2 settings ---
  proxy = kernel.precomp_proxy(pars,cfg);
  result = struct('schema','REDTEAM_QP_WRAP_V1','certified',false, ...
    'parameters',pars,'proxy_parameters',cfg,'grid_sizes',grids, ...
    'screening_thresholds',thresholds,'delta',delta,'source',source, ...
    'wrap_y',wrap_y,'fmm_used',false,'levels',struct());
  evidence = struct('proxy',proxy,'levels',struct());
  for j = 1:numel(grids)
    n = grids(j);
    % Midpoint grids avoid the original side collocation nodes and endpoints.
    x = -1.08+2.16*((0:n-1)+0.5)/n;
    left = [-pars.d/2*ones(1,n);x];
    right = [pars.d/2*ones(1,n);x];

    % --- stage 2: unwrapped computational-coordinate trace discrepancy ---
    [pl,gl,hl] = LOCAL_raw(pars.k,proxy,left);
    [pr,gr,hr] = LOCAL_raw(pars.k,proxy,right);
    raw = struct('value',pr-phase*pl,'gradient',gr-phase*gl, ...
      'hessian',hr-phase*hl);
    raw_summary = LOCAL_summary(raw.value,raw.gradient,raw.hessian);
    raw_summary.value_scale = max(abs([pr,pl]),[],'all');
    raw_summary.gradient_scale = max(abs([gr,gl]),[],'all');
    raw_summary.hessian_scale = max(abs([hr,hl]),[],'all');
    raw_summary.above_screen = struct( ...
      'value',raw_summary.value_max>thresholds.value, ...
      'gradient',raw_summary.gradient_max>thresholds.gradient, ...
      'hessian',raw_summary.hessian_max>thresholds.hessian);

    % --- stage 3: physical top/bottom repetition at a non-tie source ---
    top = [x;0.5*ones(1,n)]; bottom = [x;-0.5*ones(1,n)];
    [pt,gt,ht] = LOCAL_pair(pars,proxy,source,top);
    [pb,gb,hb] = LOCAL_pair(pars,proxy,source,bottom);
    seam = struct('value',pt-phase*pb,'gradient',gt-phase*gb, ...
      'hessian',ht-phase*hb);

    % --- stage 4: actual pairmat limits on the internal physical wrap line ---
    wrapped = repmat(struct(),numel(delta),1);
    wrapped_raw = repmat(struct('value_jump',[],'gradient_jump',[]),numel(delta),1);
    % Computational x maps to physical y; computational y maps to physical x.
    predicted_value_jump = -raw.value;
    predicted_gradient_jump = -raw.gradient([2,1],:);
    for h = 1:numel(delta)
      step = delta(h);
      below = [x;(wrap_y-step)*ones(1,n)];
      above = [x;(wrap_y+step)*ones(1,n)];
      [pa,ga,ha] = LOCAL_pair(pars,proxy,source,above);
      [pz,gz,hz] = LOCAL_pair(pars,proxy,source,below);
      value_jump = pa-pz-step*(ga(2,:)+gz(2,:));
      gradient_jump = ga-gz-step*([ha(2,:);ha(3,:)]+[hz(2,:);hz(3,:)]);
      wrapped(h).delta = step;
      wrapped(h).value_jump_max = max(abs(value_jump),[],'all');
      wrapped(h).gradient_jump_max = max(abs(gradient_jump),[],'all');
      wrapped(h).predicted_value_difference = max(abs(value_jump-predicted_value_jump),[],'all');
      wrapped(h).predicted_gradient_difference = max(abs(gradient_jump-predicted_gradient_jump),[],'all');
      wrapped_raw(h) = struct('value_jump',value_jump,'gradient_jump',gradient_jump);
    end
    result.levels(j).nodes = n;
    result.levels(j).unwrapped = raw_summary;
    result.levels(j).physical_seam = LOCAL_summary(seam.value,seam.gradient,seam.hessian);
    result.levels(j).wrapped = wrapped;
    evidence.levels(j).x = x;
    evidence.levels(j).raw = raw;
    evidence.levels(j).seam = seam;
    evidence.levels(j).wrapped = wrapped_raw;
  end
  result.runtime_seconds = toc(timer);
  result.interpretation = ['A small physical seam mismatch is an enforced ', ...
    'periodization identity. An unwrapped mismatch concerns this numerical ', ...
    'kernel, not the exact-kernel trial or the candidate spectral error.'];
  save(fullfile(output_dir,'evidence.mat'),'result','evidence','-v7');
  fid = fopen(fullfile(output_dir,'result.json'),'w');
  assert(fid>=0,'redteam:Output','Cannot open result output.');
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid,'%s\n',jsonencode(result,'PrettyPrint',true));
  fprintf('QP_WRAP seconds=%.6f grids=%d,%d no_FMM=1\n',result.runtime_seconds,grids);
end

%% ==================== Direct kernel diagnostics ====================
% These helpers preserve physical and computational derivative coordinates.
function [p,g,h] = LOCAL_raw(k,proxy,target)
  [p0,g0,h0] = kernel.h2d_directch(k,[0;0],1,target);
  [pp,gp,hp] = kernel.h2d_directch(k,proxy.Z,proxy.q,target);
  p = p0+pp; g = g0+gp; h = h0+hp;
end

function [p,g,h] = LOCAL_pair(pars,proxy,source,target)
  [p,gx,gy,hxx,hxy,hyy] = kernel.qpgreen_mfs_pairmat(source,target,pars,proxy);
  p = p.'; g = [gx.';gy.']; h = [hxx.';hxy.';hyy.'];
end

function out = LOCAL_summary(p,g,h)
  out = struct('value_max',max(abs(p),[],'all'), ...
    'gradient_max',max(abs(g),[],'all'),'hessian_max',max(abs(h),[],'all'));
end
