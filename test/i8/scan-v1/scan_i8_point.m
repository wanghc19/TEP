function [point,evidence] = scan_i8_point(k,resolution_id,config)
%SCAN_I8_POINT Evaluate the four unchanged I8 matching metrics at one k.
% Purpose: A pure FMM point evaluator; no grid, cache or selection decisions.
% Input: finite scalar k, coarse/fine resolution_id, scan_i8_config structure.
% Output: point metrics/status/timing and optional matching-field evidence.
% Based on: pipeline-v1/pipeline_i8_numeric.m LOCAL_full_point and its helpers.
% Main changes: explicit two-resolution configuration; FMM-only; no estimate.
% Numerical goal: preserve Adef/Aphys, QZ/DtN and physical density conventions.
  assert(isscalar(k) && isfinite(k));
  assert(isfield(config.resolutions,resolution_id));
  model = config.model; model.khat = k;
  cfg = config.common; resolution = config.resolutions.(resolution_id);
  cfg.ntot_center = resolution.center_ntot;
  cfg.ntot_lead = resolution.lead_ntot; cfg.id = resolution_id;
  cfg.backend = 'fmm';
  LOCAL_proxy_ledger('reset'); LOCAL_proxy_ledger('stage','field');
  [point,evidence] = LOCAL_full_point(k,model,cfg,config);
  point.proxy_calls = LOCAL_proxy_ledger('get');
  metrics = [point.adef_sigma,point.adef_ratio,point.aphys_sigma,point.aphys_ratio];
  assert(all(isfinite(metrics)) && all(metrics>=0),'i85:NonfiniteMetrics');
  point.resolution_id = resolution_id; point.status = 'SUCCESS';
end

%% ==================== Matching field construction ====================
% These helpers retain the reviewed I8 scattering and weighted matching formulas.
function [point,evidence] = LOCAL_full_point(k,model,cfg,config)
  model.khat=k; cfg.K=2*cfg.M+1; timer=tic;
  guard=LOCAL_solver_warning_guard(); %#ok<NASGU>
  [lead,Zplus,Zminus,pencil,beta_m,gamma,phase,qz] = ...
    LOCAL_lead(model,cfg,config);
  center=LOCAL_center(model,cfg,config);
  [matching,q]=LOCAL_matching(center,Zplus,Zminus,beta_m,gamma);
  clear guard;
  point=matching.summary; point.k=k; point.config=cfg.id;
  point.seconds=toc(timer); point.valid=true;
  evidence=struct('model',model,'config',cfg,'lead',lead,'center',center, ...
    'Zplus',Zplus,'Zminus',Zminus,'pencil',pencil,'beta_m',beta_m, ...
    'gamma',gamma,'phase',phase,'qz',qz,'matching',matching,'q',q);
end

function [lead,Zp,Zm,pencil,beta_m,gamma,phase,diagnostic] = ...
    LOCAL_lead(model,cfg,config)
  lead_cfg = cfg;
  lead_cfg.ntot = cfg.ntot_lead;
  [lead,~,chans] = LOCAL_cellmap('circle',model.R, ...
    model.rho_lead,model,lead_cfg,config);
  K = chans.K;
  A = [-lead.R_L,eye(K);lead.T_LR,zeros(K)];
  B = [zeros(K),lead.T_RL;eye(K),-lead.R_R];
  [Zp,plus] = LOCAL_qzsub(A,B,K,config);
  [Zm,minus] = LOCAL_qzsub(B,A,K,config);
  pencil = struct('A',A,'B',B);
  beta_m = chans.beta_m(:);
  gamma = chans.gamma_m(:);
  phase = chans.phase(:);
  diagnostic = struct('plus',plus,'minus',minus);
end

function center = LOCAL_center(model,cfg,config)
  center_cfg = cfg;
  center_cfg.ntot = cfg.ntot_center;
  center = LOCAL_cellmap('star',model.star_scale, ...
    model.rho_center,model,center_cfg,config);
end

function [cellmap,C,chans,pars,proxy] = ...
    LOCAL_cellmap(flag_geom,shape_arg,rho,model,cfg,config)
  pars = struct('k',model.khat,'beta',model.beta,'d',model.d, ...
    'periodic_axis','y');
  pars.h2d_evaluator = @(wavek,sources,charge,targ) ...
    LOCAL_h2d_fmm(wavek,sources,charge,targ,config.backend.fmm_eps);
  chans = bloch.rayleigh_channels(model.khat,model.beta,model.d, ...
    cfg.M,model.X_R-model.X_L);
  if strcmp(flag_geom,'circle')
    [C,curvelen] = geom.construct_cont( ...
      cfg.ntot,'circle',0,0,shape_arg);
  elseif strcmp(flag_geom,'star')
    [C,curvelen] = geom.construct_cont(cfg.ntot,'star',0,0);
    C = shape_arg*C;
  else
    error('i8:Shape','Unsupported shape %s.',flag_geom);
  end
  mfscfg = struct('H',model.H,'proxy_dist',model.proxy_dist, ...
    'N_side',cfg.nside,'N_top',cfg.ntop, ...
    'N_proxy_edge',cfg.nproxy,'M_pw',cfg.mpw);
  proxy = kernel.precomp_proxy(pars,mfscfg);
  cellmap = bloch.construct_S(C,model.khat,sqrt(rho)*model.khat, ...
    pars,proxy,curvelen,chans,model.X_L,model.X_R);
  cellmap.i8_geometry = C;
  cellmap.i8_pars = pars;
  cellmap.i8_proxy = proxy;
  cellmap.i8_shape = flag_geom;
  cellmap.i8_arg = shape_arg;
  cellmap.i8_ntot = cfg.ntot;
end

function [out,q] = LOCAL_matching(cellmap,Zp,Zm,beta_m,gamma)
  K = numel(gamma); G = diag(gamma); I = eye(K);
  [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma);
  T = [I+cellmap.R_L,cellmap.T_RL;cellmap.T_LR,I+cellmap.R_R];
  N0 = [1i*G*(cellmap.R_L-I),1i*G*cellmap.T_RL; ...
    1i*G*cellmap.T_LR,1i*G*(cellmap.R_R-I)];
  L = blkdiag(Lm,Lp);
  Adef = [(1i*G-Lm)*cellmap.R_L-(1i*G+Lm), ...
    (1i*G-Lm)*cellmap.T_RL; ...
    (1i*G-Lp)*cellmap.T_LR, ...
    (1i*G-Lp)*cellmap.R_R-(1i*G+Lp)];
  b = sqrt(1+abs(beta_m).^2);
  rowwt = repmat(sqrt(1./b),2,1);
  ampwt = b+abs(gamma).^2./b;
  colwt = repmat(1./sqrt(ampwt),2,1);
  Aphys = rowwt.*Adef.*colwt.';
  [~,S,V] = svd(Aphys,'econ'); singular = diag(S);
  adef_metric = svd(Adef,'econ');
  aphys_metric = svd(Aphys,'econ');
  q = colwt.*V(:,end); q = q/norm(q);
  [~,phase_anchor] = max(abs(q));
  q = q*exp(-1i*angle(q(phase_anchor)));
  if real(q(phase_anchor)) < 0, q = -q; end
  residual = Adef*q;
  q2 = colwt.*V(:,end-1); q2 = q2/norm(q2);
  m = (-(numel(gamma)-1)/2:(numel(gamma)-1)/2).';
  assembly_defect=norm(Adef-(N0-L*T),'fro')/max(1, ...
    norm(Adef,'fro')+norm(N0,'fro')+norm(L,'fro')*norm(T,'fro'));
  summary = struct('adef_sigma',adef_metric(end), ...
    'adef_ratio',adef_metric(end)/adef_metric(1), ...
    'aphys_sigma',aphys_metric(end), ...
    'aphys_ratio',aphys_metric(end)/aphys_metric(1), ...
    'q_norm',norm(q),'phase_anchor_index',phase_anchor, ...
    'phase_anchor_value',real(q(phase_anchor)), ...
    'residual_norm',norm(residual));
  out = struct('Adef',Adef,'Aphys',Aphys,'T',T,'Lp',Lp,'Lm',Lm, ...
    'N0',N0,'L',L,'assembly_defect',assembly_defect, ...
    'row_weight',rowwt,'column_weight',colwt, ...
    'singular_values',singular,'adef_metric_values',adef_metric, ...
    'aphys_metric_values',aphys_metric, ...
    'residual',residual,'summary',summary,'m',m, ...
    'trace_primary',T*q,'trace_competitor',T*q2, ...
    'target_gap',singular(end-1)-singular(end));
end

function [Zs,diagnostic] = LOCAL_qzsub(A,B,K,config)
  rho = hypot(norm(A,'fro'),norm(B,'fro'));
  if ~isfinite(rho) || rho == 0
    error('i8:QZScale','The QZ pencil scale is zero or nonfinite.');
  end
  A = A/rho; B = B/rho;
  [S,T,Q,Z] = qz(A,B,'complex');
  res = hypot(norm(A-Q'*S*Z','fro'),norm(B-Q'*T*Z','fro'));
  tol = max(config.qualification.qz_eps_factor*eps, ...
    config.qualification.qz_residual_factor*res);
  alpha = diag(S); theta = diag(T); scale = hypot(abs(alpha),abs(theta));
  indet = scale <= tol; scale(indet) = 1;
  an = abs(alpha)./scale; tn = abs(theta)./scale;
  infinite = ~indet & tn <= tol & an > tol;
  neutral = ~indet & ~infinite & abs(an-tn) <= tol;
  stable = ~indet & ~infinite & ~neutral & an < tn-tol;
  unstable = infinite | (~indet & ~neutral & an > tn+tol);
  if sum(stable) ~= K || sum(unstable) ~= K || any(indet) || any(neutral)
    error('i8:QZClassification', ...
      'stable=%d unstable=%d neutral=%d indet=%d expected=%d.', ...
      sum(stable),sum(unstable),sum(neutral),sum(indet),K);
  end
  [~,~,~,Zo] = ordqz(S,T,Q,Z,stable); Zs = Zo(:,1:K);
  diagnostic = struct('stable',sum(stable),'unstable',sum(unstable), ...
    'neutral',sum(neutral),'indeterminate',sum(indet), ...
    'residual',res,'tolerance',tol);
end

function [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma)
  K = numel(gamma); G = diag(gamma);
  Ap = Zp(1:K,:); Bp = Zp(K+1:end,:);
  Am = Zm(1:K,:); Bm = Zm(K+1:end,:);
  Dp = Ap+Bp; Np = 1i*G*(Ap-Bp);
  Dm = Am+Bm; Nm = -1i*G*(Am-Bm);
  Lp = (Dp.'\Np.').'; Lm = (Dm.'\Nm.').';
end

%% ==================== Solver and FMM safeguards ====================
% The charge-only potential/gradient/Hessian mapping is unchanged.

function cleanup = LOCAL_solver_warning_guard()
  state = warning; cleanup = onCleanup(@() warning(state));
  warning('error','MATLAB:singularMatrix');
  warning('error','MATLAB:nearlySingularMatrix');
  warning('error','MATLAB:illConditionedMatrix');
  warning('error','MATLAB:rankDeficientMatrix');
end


%% ==================== Smooth proxy evaluation and ledger ====================
% These helpers assemble identical scalar formulas and record smooth-proxy use.

function [pot,grad,hess] = LOCAL_h2d_fmm(wavek,sources,charge,targ,fmm_eps)
%LOCAL_H2D_FMM The reviewed fmm-v1 charge-only proxy convention, unchanged.
  callback_timer = tic; nt = size(targ,2);
  srcinfo = struct('sources',sources,'charges',reshape(charge,1,[]));
  [U,ier] = hfmm2d(fmm_eps,wavek,srcinfo,0,targ,3);
  if ~isscalar(ier) || ier ~= 0
    error('i85:FMMError','FMM2D returned ier=%g.',ier);
  end
  pot = reshape(U.pottarg,1,nt);
  grad = reshape(U.gradtarg,2,nt);
  hess = reshape(U.hesstarg,3,nt);
  if any(~isfinite(pot),'all') || any(~isfinite(grad),'all') || any(~isfinite(hess),'all')
    error('i85:FMMNonfinite','FMM2D returned nonfinite smooth-proxy fields.');
  end
  LOCAL_proxy_ledger('append',struct('method','fmm','ns',size(sources,2), ...
    'nt',nt,'batches',1,'ier',ier,'seconds',toc(callback_timer)));
end

function value = LOCAL_proxy_ledger(action,varargin)
  persistent records stage
  value = [];
  switch action
    case 'reset'
      records = struct('method',{},'ns',{},'nt',{},'batches',{}, ...
        'ier',{},'seconds',{},'stage',{}); stage = '';
    case 'stage'
      stage = varargin{1};
    case 'append'
      record = varargin{1}; record.stage = stage;
      records(end+1,1) = record;
    case 'get'
      value = records;
  end
end

