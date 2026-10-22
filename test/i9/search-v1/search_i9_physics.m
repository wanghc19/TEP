function [value,evidence] = search_i9_physics(action,k,resolution_id,config,lead_data)
%SEARCH_I9_PHYSICS Independent asymmetric lead classification and matching.
% Purpose: Evaluate physics only; never choose a grid, interval or candidate.
% Based on: I8.5 scan_i8_point, retaining scattering, scaling, DtN and weights.
% Main changes: two analytic trilobe leads, homogeneous Bloch classification,
%   compact reusable lead data, and an explicit leads/match action interface.
% Output: lead bundle or four-metric point; evidence contains raw QZ/matrices.
  if nargin<5, lead_data=[]; end
  model=config.model; model.khat=k; cfg=config.common;
  resolution=config.resolutions.(resolution_id);
  cfg.ntot_center=resolution.center_ntot; cfg.id=resolution_id;
  timer=tic; guard=LOCAL_solver_warning_guard(); %#ok<NASGU>
  LOCAL_proxy_ledger('reset'); LOCAL_proxy_ledger('stage',action);
  evidence=[];
  switch action
    case 'leads'
      negative_cfg=cfg; negative_cfg.ntot=resolution.negative_ntot;
      positive_cfg=cfg; positive_cfg.ntot=resolution.positive_ntot;
      [negative,~,chans]=LOCAL_cellmap('trilobe',model.a_negative, ...
        model.rho_lead,model,negative_cfg,config);
      positive=LOCAL_cellmap('trilobe',model.a_positive, ...
        model.rho_lead,model,positive_cfg,config);
      [negative,negative_diag]=LOCAL_lead_classify(negative,chans.K,config,'negative');
      [positive,positive_diag]=LOCAL_lead_classify(positive,chans.K,config,'positive');
      value=struct('negative',negative,'positive',positive,'channels',chans, ...
        'negative_diagnostic',negative_diag,'positive_diagnostic',positive_diag, ...
        'common_gap',strcmp(negative_diag.status,'GAP') && strcmp(positive_diag.status,'GAP'), ...
        'k',k,'resolution_id',resolution_id,'seconds',toc(timer));
    case 'match'
      assert(~isempty(lead_data) && lead_data.k==k && ...
        strcmp(lead_data.resolution_id,resolution_id),'i91:LeadIdentity','Lead identity does not match the requested k and resolution.');
      assert(lead_data.common_gap,'i91:NotCommonGap','Both leads must have qualified common-gap classification.');
      center=LOCAL_center(model,cfg,config);
      [matching,q]=LOCAL_matching(center,lead_data.positive.Z,lead_data.negative.Z, ...
        lead_data.channels.beta_m(:),lead_data.channels.gamma_m(:));
      value=matching.summary; value.k=k; value.resolution_id=resolution_id;
      value.seconds=toc(timer); value.valid=true; value.status='SUCCESS';
      value.negative_classification=lead_data.negative_diagnostic.status;
      value.positive_classification=lead_data.positive_diagnostic.status;
      value.assembly_defect=matching.assembly_defect;
      evidence=struct('model',model,'config',cfg,'resolution',resolution, ...
        'leads',lead_data,'center',center,'matching',matching,'q',q);
    case 'equal_validation'
      assert(~isempty(lead_data) && lead_data.common_gap);
      center=LOCAL_center(model,cfg,config);
      negative=lead_data.negative;
      A=[-negative.R_L,eye(cfg.K);negative.T_LR,zeros(cfg.K)];
      B=[zeros(cfg.K),negative.T_RL;eye(cfg.K),-negative.R_R];
      [Zp,diagp]=LOCAL_qzsub(A,B,cfg.K,config);
      assert(strcmp(diagp.status,'GAP'));
      [reference,~]=LOCAL_matching(center,Zp,negative.Z, ...
        lead_data.channels.beta_m(:),lead_data.channels.gamma_m(:));
      equal_config=config; equal_config.model.a_positive=config.model.a_negative;
      equal_leads=search_i9_physics('leads',k,resolution_id,equal_config);
      [independent,~]=LOCAL_matching(center,equal_leads.positive.Z,equal_leads.negative.Z, ...
        lead_data.channels.beta_m(:),lead_data.channels.gamma_m(:));
      value=struct('k',k,'resolution_id',resolution_id, ...
        'Adef_absolute',norm(reference.Adef-independent.Adef,'fro'), ...
        'Aphys_absolute',norm(reference.Aphys-independent.Aphys,'fro'), ...
        'negative_positive_S_difference',norm([negative.R_L,negative.T_RL;negative.T_LR,negative.R_R]- ...
          [lead_data.positive.R_L,lead_data.positive.T_RL;lead_data.positive.T_LR,lead_data.positive.R_R],'fro'), ...
        'same_lead_RL_difference',norm(equal_leads.negative.R_L-equal_leads.positive.R_L,'fro'), ...
        'seconds',toc(timer));
      evidence=struct('reference',reference,'independent',independent,'equal_leads',equal_leads);
    case 'classification_selftest'
      value=LOCAL_classification_selftest(config);
    otherwise
      error('i91:Action','Unknown physics action.');
  end
  value.proxy_calls=LOCAL_proxy_ledger('get');
end

%% ==================== Independent Bloch pencils ====================
% Positive decay uses (A,B); negative decay uses the reciprocal (B,A) pencil.
function [lead,diagnostic]=LOCAL_lead_classify(lead,K,config,direction)
  A=[-lead.R_L,eye(K);lead.T_LR,zeros(K)];
  B=[zeros(K),lead.T_RL;eye(K),-lead.R_R];
  [Zforward,diagnostic]=LOCAL_qzsub(A,B,K,config);
  lead.Z=[];
  if strcmp(direction,'negative')
    [Zreverse,reverse]=LOCAL_qzsub(B,A,K,config);
    diagnostic.reverse=reverse;
    if ~strcmp(reverse.status,diagnostic.status)
      diagnostic.status='UNCERTAIN_DIRECTION_CLASSIFICATION';
    end
    if strcmp(diagnostic.status,'GAP'), lead.Z=Zreverse; end
  elseif strcmp(diagnostic.status,'GAP')
    lead.Z=Zforward;
  end
end

function [Zs,diagnostic]=LOCAL_qzsub(A,B,K,config)
  rho=hypot(norm(A,'fro'),norm(B,'fro'));
  assert(isfinite(rho) && rho>0,'i91:QZScale','The QZ pencil scale must be finite and positive.');
  A=A/rho; B=B/rho; [S,T,Q,Z]=qz(A,B,'complex');
  residual=hypot(norm(A-Q'*S*Z','fro'),norm(B-Q'*T*Z','fro'));
  alpha=diag(S); theta=diag(T);
  diagnostic=search_i9_classify(alpha,theta,residual,K,config);
  Zs=[];
  if strcmp(diagnostic.status,'GAP')
    [~,~,~,Zo]=ordqz(S,T,Q,Z,diagnostic.stable_mask);
    Zs=Zo(:,1:K);
  end
end

function report=LOCAL_classification_selftest(config)
  pairs={ [0.5;2],ones(2,1); [1;1],ones(2,1); ...
    [1+2e-7;0.5],ones(2,1); [0;1],[1;0]; [0;1],[0;1] };
  expected={'GAP','NEAR_UNIT_PROPAGATING','UNCERTAIN','GAP','INDETERMINATE'};
  for j=1:size(pairs,1)
    result=search_i9_classify(pairs{j,1},pairs{j,2},1e-15,1,config);
    assert(strcmp(result.status,expected{j}));
  end
  unbalanced=search_i9_classify([.5;.6],ones(2,1),1e-15,1,config);
  assert(strcmp(unbalanced.status,'UNBALANCED'));
  bad=search_i9_classify([.5;2],ones(2,1),1e-5,1,config);
  assert(strcmp(bad.status,'UNQUALIFIED'));
  for delta=[0.9e-8,1.1e-8,0.9e-6,1.1e-6]
    a=(sqrt(2-delta^2)+delta)/2; b=(sqrt(2-delta^2)-delta)/2;
    ring=search_i9_classify([a;b],[b;a],1e-15,1,config);
    if delta<1e-8, label='NEAR_UNIT_PROPAGATING';
    elseif delta<=1e-6, label='UNCERTAIN'; else, label='GAP'; end
    assert(strcmp(ring.status,label));
  end
  report=struct('status','PASS','checks',{expected},'extra', ...
    'unbalanced, bad residual, inner/outer ring flanks');
end

%% ==================== Scattering and matching ====================
% These formulas are unchanged from the reviewed I8.5 physical point path.
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
  if strcmp(flag_geom,'trilobe')
    [C,curvelen] = search_i9_geometry(cfg.ntot,shape_arg,model.R,model);
  elseif strcmp(flag_geom,'circle')
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
  kext=model.khat; kint=sqrt(rho)*kext;
  cellmap = bloch.construct_S(C,kext,kint, ...
    pars,proxy,curvelen,chans,model.X_L,model.X_R);
  assert(cellmap.solve_relative_residual_norm<=config.qualification.bie_residual_max, ...
    'i91:BIESolveResidual', ...
    '%s BIE ntot=%d k=%.17g rho=%.17g relative_residual=%.17g exceeds limit %.17g.', ...
    flag_geom,cfg.ntot,model.khat,rho,cellmap.solve_relative_residual_norm,config.qualification.bie_residual_max);
  cellmap = struct('rho',rho,'kext',kext,'kint',kint, ...
    'solve_relative_residual',cellmap.solve_relative_residual_norm,'R_L',cellmap.R_L,'R_R',cellmap.R_R, ...
    'T_LR',cellmap.T_LR,'T_RL',cellmap.T_RL,'geometry',C, ...
    'shape',flag_geom,'shape_arg',shape_arg,'ntot',cfg.ntot);
end

function [out,q] = LOCAL_matching(cellmap,Zp,Zm,beta_m,gamma)
  K = numel(gamma); G = diag(gamma); I = eye(K);
  [Lp,Lm,dtn_diagnostic] = LOCAL_dtn(Zp,Zm,gamma);
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
    'N0',N0,'L',L,'dtn_diagnostic',dtn_diagnostic,'assembly_defect',assembly_defect, ...
    'row_weight',rowwt,'column_weight',colwt, ...
    'singular_values',singular,'adef_metric_values',adef_metric, ...
    'aphys_metric_values',aphys_metric, ...
    'residual',residual,'summary',summary,'m',m, ...
    'trace_primary',T*q,'trace_competitor',T*q2, ...
    'target_gap',singular(end-1)-singular(end));
end

function [Lp,Lm,dtn_diagnostic] = LOCAL_dtn(Zp,Zm,gamma)
  K = numel(gamma); G = diag(gamma);
  Ap = Zp(1:K,:); Bp = Zp(K+1:end,:);
  Am = Zm(1:K,:); Bm = Zm(K+1:end,:);
  Dp = Ap+Bp; Np = 1i*G*(Ap-Bp);
  Dm = Am+Bm; Nm = -1i*G*(Am-Bm);
  Lp = (Dp.'\Np.').'; Lm = (Dm.'\Nm.').';
  dtn_diagnostic=struct('positive_rcond',rcond(Dp),'negative_rcond',rcond(Dm), ...
    'positive_residual',norm(Lp*Dp-Np,'fro')/max(1,norm(Np,'fro')), ...
    'negative_residual',norm(Lm*Dm-Nm,'fro')/max(1,norm(Nm,'fro')));
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
    error('i91:FMMError','FMM2D returned ier=%g.',ier);
  end
  pot = reshape(U.pottarg,1,nt);
  grad = reshape(U.gradtarg,2,nt);
  hess = reshape(U.hesstarg,3,nt);
  if any(~isfinite(pot),'all') || any(~isfinite(grad),'all') || any(~isfinite(hess),'all')
    error('i91:FMMNonfinite','FMM2D returned nonfinite smooth-proxy fields.');
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

