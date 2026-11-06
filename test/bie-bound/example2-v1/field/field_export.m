% B1 source copy: test/bie-bound/pipeline-v1/field/field_export.m; local adaptations described in README.
function result=field_export(out,k,resolution,example)
% FIELD_EXPORT Rebuild densities, exact binary64 export and cell-kernel B fit.
% Input
%   out: same-run stage directory; k: frequency returned by determinant search.
% Output
%   fixed-input.json, coefficients.json and disjoint stage times.
% Numerical helpers copied from matrel-v1/export_fixed.m; B fit from cellfit-v1.
  if nargin<3,resolution='reference';end
  maxNumCompThreads(11);timer=tic;config=pilot_config(k,resolution);if nargin>=4,config=example_field_config(example,config);end
  model=config.model;model.khat=k;
  cfg=config.discretization;K=cfg.K;
  LOCAL_proxy_ledger('reset');LOCAL_backend('set',struct('method','fmm','tolerance',config.backend.fmm_eps));
  guard=LOCAL_solver_warning_guard();
  negative=LOCAL_cellmap('trilobe',model.a_negative,model.rho_lead,cfg.ntot_negative,LOCAL_side(model,'negative'),config);
  positive=LOCAL_cellmap('trilobe',model.a_positive,model.rho_lead,cfg.ntot_positive,LOCAL_side(model,'positive'),config);
  negative=LOCAL_lead(negative,'negative',config);positive=LOCAL_lead(positive,'positive',config);
  if isfield(model,'empty_center') && model.empty_center
    center=LOCAL_cellmap('none',0,1,0,model,config);
  else
    center=LOCAL_cellmap('star',model.star_scale,model.rho_center,cfg.ntot_center,model,config);
  end
  [matching,q]=LOCAL_matching(center,positive.Z,negative.Z,center.channels.beta_m(:),center.channels.gamma_m(:));
  prop=LOCAL_propagation(negative,positive,q,matching.T,K,config);density=[center.H_L,center.H_R]*q;clear guard
  result.field_seconds=toc(timer);stage=tic;
  if isfield(model,'empty_center') && model.empty_center,data.disks=LOCAL_pack([1,0,0,.2,1;1,0,.33,.12,1;1,0,-.33,.12,1]);else,data.disks=LOCAL_pack(disk_geometry());end
  if nargin>=4,data.example=example;end
  data.cell_widths=LOCAL_pack([model.X_R-model.X_L,negative.channels.L,positive.channels.L]);data.incident=LOCAL_pack(q);data.rayleigh_modes=center.channels.m;
  data.schema='EXACT_BINARY64_MATERIAL_V1';data.k=LOCAL_pack(k);data.beta=LOCAL_pack(model.beta);data.d=LOCAL_pack(model.d);
  data.H=LOCAL_pack(model.H);data.phase=LOCAL_pack(exp(1i*model.beta*model.d));data.phase_minus=LOCAL_pack(exp(-1i*model.beta*model.d));
  data.proxy_Z=LOCAL_pack(center.i9_proxy.Z);data.proxy_c=LOCAL_pack(center.i9_proxy.q);
  data.curve_parameters=LOCAL_pack([.2,.3,1.5,1,model.star_scale,model.a_negative,model.a_positive,model.R]);
  cells={center,negative,positive};names={'center','negative','positive'};
  for j=1:3
    cm=cells{j};item=struct('name',names{j},'shape',cm.i9_shape,'arg',LOCAL_pack(cm.i9_arg),'native_nodes',cm.i9_ntot);
    if j==1,H=density;else,H=[cm.H_L,cm.H_R];end
    [ct,mm]=LOCAL_fourier(H(1:cm.i9_ntot,:));[cz,~]=LOCAL_fourier(H(cm.i9_ntot+1:end,:));
    item.tau_coeff=LOCAL_pack(ct);item.zeta_coeff=LOCAL_pack(cz);item.modes=mm;
    if j==2,item.G=LOCAL_pack(prop.Gminus);item.P=LOCAL_pack(prop.Pminus);item.c=LOCAL_pack(prop.cminus);end
    if j==3,item.G=LOCAL_pack(prop.Gplus);item.P=LOCAL_pack(prop.Pplus);item.c=LOCAL_pack(prop.cplus);end
    item.proxy_Z=LOCAL_pack(cm.i9_proxy.Z);item.proxy_c=LOCAL_pack(cm.i9_proxy.q);
    item.proxy_equal=isequal(cm.i9_proxy.Z,center.i9_proxy.Z)&&isequal(cm.i9_proxy.q,center.i9_proxy.q);
    data.pieces{j}=item;
  end
  LOCAL_json(fullfile(out,'fixed-input.json'),data);result.export_seconds=toc(stage);stage=tic;
  result.propagation=struct('negative_fro',norm(prop.Pminus,'fro'),'positive_fro',norm(prop.Pplus,'fro'),'negative_spectral',norm(prop.Pminus,2),'positive_spectral',norm(prop.Pplus,2));
  result.singular_values=matching.singular_values(end-1:end);
  % Positions only: identical to cell_fit; the A coefficients are not needed.
  n=120;margin=.35;H=1.1;d=model.d;
  tx=linspace(-d-margin,d+margin,n+1).';tx(end)=[];
  ty=linspace(-H-margin,H+margin,n+1).';ty(end)=[];
  Z=[tx,(-H-margin)*ones(n,1);(d+margin)*ones(n,1),ty;flipud(tx),(H+margin)*ones(n,1);(-d-margin)*ones(n,1),flipud(ty)].';
  [BC,fit]=field_fit(cells,{q,prop.Gminus,prop.Gplus},model,Z);
  result.fit_seconds=toc(stage);stage=tic;
  coefficients=struct('Z',LOCAL_pack(Z),'B_center',LOCAL_pack(BC{1}),'B_negative',LOCAL_pack(BC{2}),'B_positive',LOCAL_pack(BC{3}));
  LOCAL_json(fullfile(out,'coefficients.json'),coefficients);result.fit_output_seconds=toc(stage);
  result.config=config;result.fit=fit;result.k=k;result.k_hex=num2hex(k);result.matching=matching.summary;result.assembly_defect=matching.assembly_defect;
  result.total_seconds=toc(timer);result.status='COMPLETE';result.environment=struct('version',version,'threads',maxNumCompThreads,'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS'));
  LOCAL_json(fullfile(out,'result.json'),result);
end
function p=LOCAL_pack(x)
  % Input: finite binary64 array. Output: column-major exact IEEE hexadecimal data.
  assert(all(isfinite(x(:))));p=struct('shape',size(x),'real',{cellstr(num2hex(real(x(:))))},'imag',{cellstr(num2hex(imag(x(:))))});
end
function [c,m]=LOCAL_fourier(v)
  % Input: even periodic samples. Output: interpft-compatible Fourier coefficients.
  n=size(v,1);if n==0,c=v;m=[];return;end
  c=fft(v,[],1)/n;c(n/2+1,:)=c(n/2+1,:)/2;c=[c;c(n/2+1,:)];m=[0:n/2,-n/2+1:-1,-n/2];
end
function cellmap=LOCAL_cellmap(shape,arg,rho,ntot,model,config)
  cfg=config.discretization;
  if strcmp(shape,'none')
    C=zeros(6,0);curvelen=2*pi;
  elseif strcmp(shape,'star')
    [C,curvelen]=geom.construct_cont(ntot,'star',0,0); C=arg*C;
  else
    [C,curvelen]=pilot_geometry(ntot,arg,model.R,model);
  end
  if isfield(model,'angle') && model.angle~=0
    co=cos(model.angle);si=sin(model.angle);D=C;C(1:3,:)=co*D(1:3,:)-si*D(4:6,:);C(4:6,:)=si*D(1:3,:)+co*D(4:6,:);
    assert(max(abs(C(1,:)))<model.L/2 && max(abs(C(4,:)))<model.d/2);
  end
  pars=struct('k',model.khat,'beta',model.beta,'d',model.d,'periodic_axis','y', ...
    'h2d_evaluator',@LOCAL_h2d_switch);
  chans=bloch.rayleigh_channels(model.khat,model.beta,model.d,cfg.M,model.X_R-model.X_L);
  mfscfg=struct('H',model.H,'proxy_dist',model.proxy_dist,'N_side',cfg.nside, ...
    'N_top',cfg.ntop,'N_proxy_edge',cfg.nproxy,'M_pw',cfg.mpw);
  proxy=kernel.precomp_proxy(pars,mfscfg);
  if strcmp(shape,'none')
    cellmap=struct('R_L',zeros(chans.K),'R_R',zeros(chans.K),'T_LR',diag(chans.phase),'T_RL',diag(chans.phase),'H_L',zeros(0,chans.K),'H_R',zeros(0,chans.K),'channels',chans,'solve_relative_residual_norm',0);
  else
  cellmap=bloch.construct_S(C,model.khat,sqrt(rho)*model.khat,pars,proxy,curvelen,chans,model.X_L,model.X_R);
  end
  assert(cellmap.solve_relative_residual_norm<=config.qualification.bie_residual_max, ...
    'i92:BIESolve','%s ntot=%d BIE residual %.17g exceeds %.17g.',shape,ntot, ...
    cellmap.solve_relative_residual_norm,config.qualification.bie_residual_max);
  cellmap.i9_angle=0;if isfield(model,'angle'),cellmap.i9_angle=model.angle;end;cellmap.i9_L=model.X_R-model.X_L;cellmap.i9_geometry=C; cellmap.i9_pars=pars; cellmap.i9_proxy=proxy;
  cellmap.i9_shape=shape; cellmap.i9_arg=arg; cellmap.i9_ntot=ntot;
  cellmap.rho=rho; cellmap.kext=model.khat; cellmap.kint=sqrt(rho)*model.khat;
end

function lead=LOCAL_lead(lead,direction,config)
  K=config.discretization.K;
  lead.A=[-lead.R_L,eye(K);lead.T_LR,zeros(K)];
  lead.B=[zeros(K),lead.T_RL;eye(K),-lead.R_R];
  [Zforward,lead.qz]=LOCAL_qz(lead.A,lead.B,K,config);
  assert(strcmp(lead.qz.status,'GAP'),'i92:CommonGap','%s lead is %s.',direction,lead.qz.status);
  if strcmp(direction,'negative')
    [lead.Z,lead.reverse_qz]=LOCAL_qz(lead.B,lead.A,K,config);
    assert(strcmp(lead.reverse_qz.status,'GAP'),'i92:ReverseGap','Negative inverse pencil is not GAP.');
  else
    lead.Z=Zforward;
  end
end

function [Zs,diagnostic]=LOCAL_qz(A,B,K,config)
  rho=hypot(norm(A,'fro'),norm(B,'fro'));
  assert(isfinite(rho)&&rho>0,'i92:QZScale','QZ scale must be positive and finite.');
  A=A/rho; B=B/rho; [S,T,Q,Z]=qz(A,B,'complex');
  residual=hypot(norm(A-Q'*S*Z','fro'),norm(B-Q'*T*Z','fro'));
  diagnostic=pilot_classify(diag(S),diag(T),residual,K,config); Zs=[];
  if strcmp(diagnostic.status,'GAP')
    [~,~,~,Zo]=ordqz(S,T,Q,Z,diagnostic.stable_mask); Zs=Zo(:,1:K);
  end
end

function out=LOCAL_propagation(negative,positive,q,center_trace,K,config)
  Zp=positive.Z; Zm=negative.Z;
  plus=LOCAL_action(positive.A,positive.B,Zp,false,K,config);
  minus=LOCAL_action(negative.A,negative.B,Zm,true,K,config);
  Ap=Zp(1:K,:); Bp=Zp(K+1:end,:); Am=Zm(1:K,:); Bm=Zm(K+1:end,:);
  Dplus=Ap+Bp; Dminus=Am+Bm; trace=center_trace*q;
  cplus=Dplus\trace(K+1:end); cminus=Dminus\trace(1:K);
  out=struct('Pplus',plus.P,'Pminus',minus.P,'Dplus',Dplus,'Dminus',Dminus, ...
    'Gplus',[Ap;Bp*plus.P],'Gminus',[Am*minus.P;Bm],'cplus',cplus,'cminus',cminus, ...
    'plus_coordinate_residual',norm(Dplus*cplus-trace(K+1:end))/max(1,norm(trace(K+1:end))), ...
    'minus_coordinate_residual',norm(Dminus*cminus-trace(1:K))/max(1,norm(trace(1:K))), ...
    'plus_diagnostic',rmfield(plus,'P'),'minus_diagnostic',rmfield(minus,'P'));
end

%% ==================== Separate finite prefixes and numerical tails ====================
% Each side has its own action, propagated coefficients and observed tail ratio.
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

function out = LOCAL_action(A,B,Z,reversed,K,config)
  if reversed, C=A*Z; rhs=B*Z; else, C=B*Z; rhs=A*Z; end
  [~,R] = qr(C,0); rc = rcond(R); P = C\rhs;
  residual = norm(C*P-rhs,'fro')/max(1, ...
    norm(C,'fro')*norm(P,2)+norm(rhs,'fro'));
  if rank(R) ~= K || rc < config.evaluation.propagation_rcond_min || ...
      residual > config.evaluation.propagation_residual_max
    error('i92:Propagation','A lead propagation map failed qualification.');
  end
  out = struct('P',P,'thin_qr_rcond',rc,'solve_residual',residual, ...
    'frobenius_norm',norm(P,'fro'),'spectral_norm',norm(P,2));
end

function [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma)
  K = numel(gamma); G = diag(gamma);
  Ap = Zp(1:K,:); Bp = Zp(K+1:end,:);
  Am = Zm(1:K,:); Bm = Zm(K+1:end,:);
  Dp = Ap+Bp; Np = 1i*G*(Ap-Bp);
  Dm = Am+Bm; Nm = -1i*G*(Am-Bm);
  Lp = (Dp.'\Np.').'; Lm = (Dm.'\Nm.').';
end

function cleanup = LOCAL_solver_warning_guard()
  state = warning; cleanup = onCleanup(@() warning(state));
  warning('error','MATLAB:singularMatrix');
  warning('error','MATLAB:nearlySingularMatrix');
  warning('error','MATLAB:illConditionedMatrix');
  warning('error','MATLAB:rankDeficientMatrix');
end

function [pot,grad,hess] = LOCAL_h2d_switch(wavek,sources,charge,targ)
  % Switch only the evaluation algorithm; proxy charges and sources are fixed.
  timer=tic;backend=LOCAL_backend('get');nt=size(targ,2);
  pot=complex(zeros(1,nt));grad=complex(zeros(2,nt));hess=complex(zeros(3,nt));batches=0;
  if strcmp(backend.method,'direct'),batch=512;
  elseif nt>700000,batch=196608;
  else,batch=nt;end
  for first=1:batch:nt
    ids=first:min(first+batch-1,nt);batches=batches+1;
    if strcmp(backend.method,'direct')
      [pot(:,ids),grad(:,ids),hess(:,ids)]=kernel.h2d_directch(wavek,sources,charge,targ(:,ids));
    else
      srcinfo=struct('sources',sources,'charges',reshape(charge,1,[]));
      [U,ier]=hfmm2d(backend.tolerance,wavek,srcinfo,0,targ(:,ids),3);
      assert(isscalar(ier)&&ier==0,'pilot:FMM','FMM2D ier=%g',ier);
      pot(:,ids)=reshape(U.pottarg,1,[]);grad(:,ids)=reshape(U.gradtarg,2,[]);hess(:,ids)=reshape(U.hesstarg,3,[]);
    end
  end
  assert(all(isfinite(pot),'all')&&all(isfinite(grad),'all')&&all(isfinite(hess),'all'),'pilot:Nonfinite','Nonfinite evaluation');
  LOCAL_proxy_ledger('append',struct('method',backend.method,'ns',size(sources,2),'nt',nt,'batches',batches,'ier',0,'seconds',toc(timer)));
end
function out=LOCAL_backend(action,varargin)
  persistent data
  if strcmp(action,'set'),data=varargin{1};end
  out=data;
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

function LOCAL_json(path,data)
  f=fopen(path,'w');assert(f>=0);cleanup=onCleanup(@() fclose(f));fprintf(f,'%s\n',jsonencode(data));
end

function m=LOCAL_side(m,side)
% Input: model and side. Output: local coordinates for that lead.
  if isfield(m,['L_',side])
    m.L=m.(['L_',side]);m.X_L=-m.L/2;m.X_R=m.L/2;m.angle=m.(['angle_',side]);
  end
end
