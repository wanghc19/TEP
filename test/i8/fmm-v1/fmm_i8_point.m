function point = fmm_i8_point(k,method,fmm_eps,capture_fields)
%FMM_I8_POINT Evaluate one frozen I8.1 point with direct or FMM proxy fields.
% Purpose:
%   Reproduce the locate_i8 single-point calculation while returning the two
%   matching matrices and optionally capturing the two actual smooth-proxy
%   callback inputs and FMM outputs.
% Input:
%   k              - Positive finite scalar wavenumber.
%   method         - 'direct' for the original 512-target batching or 'fmm'.
%   fmm_eps        - Requested FMM2D tolerance for method 'fmm'; NaN otherwise.
%   capture_fields - Logical scalar controlling raw callback capture.
% Output:
%   point          - Timed result, matrices, metrics, and FMM call records.
% Main algorithm:
%   Use the frozen locate_i8 model and operation order.  The only numerical
%   switch is the pars.h2d_evaluator callback used for smooth proxy fields.
% Based on:
%   test/i8/locate-v1/locate_i8.m at commit
%   3d20a4e39fe37dbfd99d517543f0e38aa5c8c89f.
% Main changes:
%   Select the direct or FMM2D callback and return Adef/Aphys plus timing.
% Numerical goal:
%   Compare FMM2D with the original smooth-proxy direct sum without changing
%   the model, BIE, QZ/DtN, matching, weighting, or singular-value formulas.

  if nargin ~= 4 || ~isscalar(k) || ~isreal(k) || ~isfinite(k) || k <= 0
    error('i8fmm:Arguments','Pass k, method, fmm_eps, and capture_fields.');
  end
  if isstring(method) && isscalar(method)
    method = char(method);
  end
  if ~ischar(method) || (~strcmp(method,'direct') && ~strcmp(method,'fmm'))
    error('i8fmm:Method','method must be ''direct'' or ''fmm''.');
  end
  if ~isscalar(capture_fields) || ...
      ~(islogical(capture_fields) || isnumeric(capture_fields))
    error('i8fmm:Capture','capture_fields must be a logical scalar.');
  end
  capture_fields = logical(capture_fields);
  if strcmp(method,'fmm')
    if ~isscalar(fmm_eps) || ~isreal(fmm_eps) || ...
        ~isfinite(fmm_eps) || fmm_eps <= 0
      error('i8fmm:Tolerance','fmm_eps must be a positive finite scalar.');
    end
    if isempty(which('hfmm2d')) || isempty(which('fmm2d'))
      error('i8fmm:MissingFMM2D','hfmm2d and fmm2d must be on the MATLAB path.');
    end
  else
    fmm_eps = NaN;
  end

  beta = 0.5;
  model = struct('beta',beta,'d',1,'R',0.2,'epsrel',17, ...
    'epsrel_center',2,'XL',-0.5,'XR',0.5,'H',1.1,'pdist',0.2, ...
    'flag_geom','star','star_scale',sqrt(0.04/0.0618));
  cfg = struct('ntot',256,'nside',160,'ntop',160, ...
    'nproxy',80,'mpw',32);
  M = 48;

  LOCAL_capture('reset');
  if strcmp(method,'direct')
    evaluator = @(wavek,sources,charge,targ) ...
      LOCAL_h2d_direct_capture( ...
      wavek,sources,charge,targ,capture_fields);
  else
    evaluator = @(wavek,sources,charge,targ) ...
      LOCAL_h2d_fmm(wavek,sources,charge,targ,fmm_eps,capture_fields);
  end

  warning_guard = LOCAL_solver_warning_guard();
  lastwarn('');
  point_timer = tic;
  LOCAL_capture('label','lead');
  [Zp,Zm,bm,gamma] = LOCAL_cellsub(k,M,model,cfg,evaluator);
  [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma);
  LOCAL_capture('label','center');
  cellmap = LOCAL_center(k,M,model,cfg,evaluator);
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

  adef_sval = sort(svd(Adef,'econ'),'ascend');
  aphys_sval = sort(svd(Aphys,'econ'),'ascend');
  metrics = struct( ...
    'adef_sigma',adef_sval(1), ...
    'adef_sigma_max',adef_sval(end), ...
    'adef_ratio',adef_sval(1)/adef_sval(end), ...
    'aphys_sigma',aphys_sval(1), ...
    'aphys_sigma_max',aphys_sval(end), ...
    'aphys_ratio',aphys_sval(1)/aphys_sval(end));
  point_seconds = toc(point_timer);
  [warn_message,warn_id] = lastwarn;
  clear warning_guard;
  if ~isempty(warn_message)
    error('i8fmm:PointWarning','k=%.17g warning %s: %s', ...
      k,warn_id,warn_message);
  end
  metric_values = cell2mat(struct2cell(metrics)).';
  if any(~isfinite(metric_values)) || any(~isfinite(Adef),'all') || ...
      any(~isfinite(Aphys),'all')
    error('i8fmm:NonfinitePoint','k=%.17g produced a nonfinite result.',k);
  end

  proxy_calls = LOCAL_capture('get');
  if numel(proxy_calls) ~= 2 || ...
      ~isequal({proxy_calls.cell_id},{'lead','center'})
    error('i8fmm:ProxyCallCount', ...
      'Expected one lead and one center smooth-proxy callback.');
  end

  point = struct('k',k,'beta',beta,'method',method, ...
    'requested_eps',fmm_eps,'capture_fields',capture_fields, ...
    'point_seconds',point_seconds,'metrics',metrics, ...
    'Adef',Adef,'Aphys',Aphys,'proxy_calls',proxy_calls, ...
    'matrix_size',size(Adef));
end

%% ==================== Point construction ====================
% These helpers preserve the frozen locate_i8 cell and matching operations.

function cellmap = LOCAL_center(k,M,model,cfg,evaluator)
  pars = struct('k',k,'beta',model.beta,'d',model.d, ...
    'periodic_axis','y','h2d_evaluator',evaluator);
  chans = bloch.rayleigh_channels( ...
    k,model.beta,model.d,M,model.XR-model.XL);
  [C,curvelen] = geom.construct_cont(cfg.ntot,model.flag_geom,0,0);
  C = model.star_scale*C;
  mfscfg = struct('H',model.H,'proxy_dist',model.pdist, ...
    'N_side',cfg.nside,'N_top',cfg.ntop, ...
    'N_proxy_edge',cfg.nproxy,'M_pw',cfg.mpw);
  proxy = kernel.precomp_proxy(pars,mfscfg);
  kint = sqrt(model.epsrel_center)*k;
  cellmap = bloch.construct_S(C,k,kint,pars,proxy,curvelen,chans, ...
    model.XL,model.XR);
end

function [Zp,Zm,bm,gamma] = LOCAL_cellsub(k,M,model,cfg,evaluator)
  pars = struct('k',k,'beta',model.beta,'d',model.d, ...
    'periodic_axis','y','h2d_evaluator',evaluator);
  chans = bloch.rayleigh_channels( ...
    k,model.beta,model.d,M,model.XR-model.XL);
  [C,curvelen] = geom.construct_cont(cfg.ntot,'circle',0,0,model.R);
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
end

function Zs = LOCAL_qzsub(A,B,K)
  rho = hypot(norm(A,'fro'),norm(B,'fro'));
  if ~isfinite(rho) || rho == 0
    error('i8fmm:QZScale','The QZ pencil scale is zero or nonfinite.');
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
    error('i8fmm:QZClassification', ...
      'stable=%d unstable=%d neutral=%d indet=%d expected=%d.', ...
      sum(stable),sum(unstable),sum(neutral),sum(indet),K);
  end
  [~,~,~,Zo] = ordqz(S,T,Q,Z,stable);
  Zs = Zo(:,1:K);
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

%% ==================== Direct and FMM evaluators ====================
% These helpers differ only in the smooth proxy-source field evaluation.

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

function [pot,grad,hess] = LOCAL_h2d_direct_capture( ...
    wavek,sources,charge,targ,capture_fields)
  eval_timer = tic;
  [pot,grad,hess] = LOCAL_h2d_chunked_public( ...
    wavek,sources,charge,targ);
  evaluator_seconds = toc(eval_timer);
  record = LOCAL_empty_fmm_call();
  record.method = 'direct';
  record.wavek = wavek;
  record.ns = size(sources,2);
  record.nt = size(targ,2);
  record.evaluator_seconds = evaluator_seconds;
  if capture_fields
    record.sources = sources;
    record.charge = reshape(charge,1,[]);
    record.target = targ;
    record.pot = pot;
    record.grad = grad;
    record.hess = hess;
  end
  LOCAL_capture('append',record);
end

function [pot,grad,hess] = LOCAL_h2d_fmm( ...
    wavek,sources,charge,targ,fmm_eps,capture_fields)
  eval_timer = tic;
  ns = size(sources,2);
  nt = size(targ,2);
  if size(sources,1) ~= 2 || size(targ,1) ~= 2 || numel(charge) ~= ns
    error('i8fmm:FMMInputShape','Unexpected source, target, or charge shape.');
  end
  srcinfo = struct('sources',sources, ...
    'charges',reshape(charge,1,[]));
  [U,ier,timeinfo] = hfmm2d(fmm_eps,wavek,srcinfo,0,targ,3);
  if ~isscalar(ier) || ier ~= 0
    error('i8fmm:FMMError','FMM2D returned ier=%g.',ier);
  end
  pot = reshape(U.pottarg,1,nt);
  grad = reshape(U.gradtarg,2,nt);
  hess = reshape(U.hesstarg,3,nt);
  if any(~isfinite(pot),'all') || any(~isfinite(grad),'all') || ...
      any(~isfinite(hess),'all')
    error('i8fmm:FMMNonfinite','FMM2D returned a nonfinite field.');
  end
  evaluator_seconds = toc(eval_timer);

  record = LOCAL_empty_fmm_call();
  record.method = 'fmm';
  record.wavek = wavek;
  record.requested_eps = fmm_eps;
  record.ns = ns;
  record.nt = nt;
  record.ier = ier;
  record.timeinfo = timeinfo;
  record.evaluator_seconds = evaluator_seconds;
  if capture_fields
    record.sources = sources;
    record.charge = reshape(charge,1,[]);
    record.target = targ;
    record.pot = pot;
    record.grad = grad;
    record.hess = hess;
  end
  LOCAL_capture('append',record);
end

function record = LOCAL_empty_fmm_call()
  record = struct('cell_id','','method','','wavek',NaN,'requested_eps',NaN, ...
    'ns',0,'nt',0,'ier',NaN,'timeinfo',[], ...
    'evaluator_seconds',NaN,'sources',[],'charge',[], ...
    'target',[],'pot',[],'grad',[],'hess',[]);
end

function value = LOCAL_capture(action,varargin)
  persistent records current_label
  value = [];
  switch action
    case 'reset'
      records = repmat(LOCAL_empty_fmm_call(),0,1);
      current_label = '';
    case 'label'
      current_label = varargin{1};
    case 'append'
      record = varargin{1};
      record.cell_id = current_label;
      records(end+1,1) = record;
    case 'get'
      value = records;
    otherwise
      error('i8fmm:CaptureAction','Unknown capture action %s.',action);
  end
end

%% ==================== Warning helper ====================
% This helper preserves locate_i8 solver-warning behavior.

function cleanup = LOCAL_solver_warning_guard()
  state = warning;
  cleanup = onCleanup(@() warning(state));
  warning('error','MATLAB:singularMatrix');
  warning('error','MATLAB:nearlySingularMatrix');
  warning('error','MATLAB:illConditionedMatrix');
  warning('error','MATLAB:rankDeficientMatrix');
end
