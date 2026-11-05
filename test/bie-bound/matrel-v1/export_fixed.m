function result=export_fixed(out,config,input)
  % EXPORT_FIXED Export exact binary64 defining data for the fixed BIE field.
  % Input
  %   out: explicit output directory; config: scientific pilot configuration.
  %   input: optional same-run hexadecimal export for floating comparison.
  % Output
  %   Binary64 hexadecimal arrays and field-build checks in JSON files.
  maxNumCompThreads(11);
  if nargin==3
    result=LOCAL_reference(out,config,input);
    return;
  end
  timer=tic;model=config.model;model.khat=config.k0;
  cfg=config.discretization;K=cfg.K;
  LOCAL_proxy_ledger('reset');LOCAL_backend('set',struct('method','fmm','tolerance',config.backend.fmm_eps));
  guard=LOCAL_solver_warning_guard();
  negative=LOCAL_cellmap('trilobe',model.a_negative,model.rho_lead,cfg.ntot_negative,model,config);
  positive=LOCAL_cellmap('trilobe',model.a_positive,model.rho_lead,cfg.ntot_positive,model,config);
  negative=LOCAL_lead(negative,'negative',config);positive=LOCAL_lead(positive,'positive',config);
  center=LOCAL_cellmap('star',model.star_scale,model.rho_center,cfg.ntot_center,model,config);
  [matching,q]=LOCAL_matching(center,positive.Z,negative.Z,center.channels.beta_m(:),center.channels.gamma_m(:));
  prop=LOCAL_propagation(negative,positive,q,matching.T,K);density=[center.H_L,center.H_R]*q;clear guard
  result.field_seconds=toc(timer);
  value=LOCAL_piece_field(center,density,q,model,model.disk_center,false,1536);
  z=model.khat*model.disk_radius;Q5=sqrt(pi*model.disk_radius^2*(besselj(0,z)^2+besselj(1,z)^2)*abs(value)^2);
  result.Q5=Q5;result.Q5_reference=.12339611507515838;result.Q5_relative=abs(Q5/result.Q5_reference-1);
  assert(result.Q5_relative<1e-9,'export:Baseline','Fixed-field Q5 check failed.');
  stage=tic;
  ca=LOCAL_center_action(center,density,q,2*model.khat,model,1536);
  result.floating=struct('nodes',1536,'value_squared',ca.jump.value_squared,'normal_squared',ca.jump.normal_squared, ...
    'epsilon',sqrt(ca.jump.value_squared+ca.jump.normal_squared),'seconds',toc(stage));
  LOCAL_float_samples(out,ca.jump.value,ca.jump.normal,ca.weights);
  disks=LOCAL_disks(center,negative,positive,density,q,prop,model,1536,out);
  data.disks=LOCAL_pack(disks(disks(:,5)>1,1:5)); data.incident=LOCAL_pack(q);data.rayleigh_modes=center.channels.m;
  data.schema='EXACT_BINARY64_MATERIAL_V1';data.k=LOCAL_pack(model.khat);data.beta=LOCAL_pack(model.beta);data.d=LOCAL_pack(model.d);
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
    % Each kernel is exported and checked; the three exterior kernels coincide.
    item.proxy_Z=LOCAL_pack(cm.i9_proxy.Z);item.proxy_c=LOCAL_pack(cm.i9_proxy.q);
    item.proxy_equal=isequal(cm.i9_proxy.Z,center.i9_proxy.Z)&&isequal(cm.i9_proxy.q,center.i9_proxy.q);
    data.pieces{j}=item;
  end
  LOCAL_json(fullfile(out,'fixed-input.json'),data);
  result.total_seconds=toc(timer);result.status='EXPORTED';LOCAL_json(fullfile(out,'export-summary.json'),result);
  fprintf('EXPORT Q5 %.17g relative %.3g, seconds %.3f\n',Q5,result.Q5_relative,result.total_seconds);
end
function p=LOCAL_pack(x)
  % Input: finite binary64 array. Output: column-major exact IEEE hexadecimal data.
  assert(all(isfinite(x(:))));p=struct('shape',size(x),'real',{cellstr(num2hex(real(x(:))))},'imag',{cellstr(num2hex(imag(x(:))))});
end
function [c,m]=LOCAL_fourier(v)
  % Input: even periodic samples. Output: interpft-compatible Fourier coefficients.
  n=size(v,1);c=fft(v,[],1)/n;c(n/2+1,:)=c(n/2+1,:)/2;c=[c;c(n/2+1,:)];m=[0:n/2,-n/2+1:-1,-n/2];
end
function cellmap=LOCAL_cellmap(shape,arg,rho,ntot,model,config)
  cfg=config.discretization;
  if strcmp(shape,'star')
    [C,curvelen]=geom.construct_cont(ntot,'star',0,0); C=arg*C;
  else
    [C,curvelen]=pilot_geometry(ntot,arg,model.R,model);
  end
  pars=struct('k',model.khat,'beta',model.beta,'d',model.d,'periodic_axis','y', ...
    'h2d_evaluator',@LOCAL_h2d_switch);
  chans=bloch.rayleigh_channels(model.khat,model.beta,model.d,cfg.M,model.X_R-model.X_L);
  mfscfg=struct('H',model.H,'proxy_dist',model.proxy_dist,'N_side',cfg.nside, ...
    'N_top',cfg.ntop,'N_proxy_edge',cfg.nproxy,'M_pw',cfg.mpw);
  proxy=kernel.precomp_proxy(pars,mfscfg);
  cellmap=bloch.construct_S(C,model.khat,sqrt(rho)*model.khat,pars,proxy,curvelen,chans,model.X_L,model.X_R);
  assert(cellmap.solve_relative_residual_norm<=config.qualification.bie_residual_max, ...
    'i92:BIESolve','%s ntot=%d BIE residual %.17g exceeds %.17g.',shape,ntot, ...
    cellmap.solve_relative_residual_norm,config.qualification.bie_residual_max);
  cellmap.i9_geometry=C; cellmap.i9_pars=pars; cellmap.i9_proxy=proxy;
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

function out=LOCAL_propagation(negative,positive,q,center_trace,K)
  Zp=positive.Z; Zm=negative.Z;
  plus=LOCAL_action(positive.A,positive.B,Zp,false,K);
  minus=LOCAL_action(negative.A,negative.B,Zm,true,K);
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

function out = LOCAL_action(A,B,Z,reversed,K)
  if reversed, C=A*Z; rhs=B*Z; else, C=B*Z; rhs=A*Z; end
  [~,R] = qr(C,0); rc = rcond(R); P = C\rhs;
  residual = norm(C*P-rhs,'fro')/max(1, ...
    norm(C,'fro')*norm(P,2)+norm(rhs,'fro'));
  config = pilot_config();
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

function out = LOCAL_center_action(cellmap,density,q,kint,model,N)
%LOCAL_CENTER_ACTION Apply the raw operator to the frozen stored density.

  [C,curvelen] = geom.construct_cont(N,'star',0,0);
  C = model.star_scale*C;
  curve = LOCAL_curve('star',model.star_scale,N);
  weights = (curvelen/N)*hypot(C(2,:),C(5,:)).';
  eta = LOCAL_interp_density_map(density,N);
  A_scaled = op.construct_A_QP(C,model.khat,kint, ...
    cellmap.i9_pars,cellmap.i9_proxy,curvelen);
  [B_L,B_R] = bloch.incident_rhs(C,cellmap.channels, ...
    model.X_L,model.X_R);
  Bq = [B_L,B_R]*q;
  scale = sqrt(repmat(weights,2,1));
  raw = (A_scaled*(scale.*eta))./scale+Bq;
  value = raw(1:N); normal = -raw(N+1:end);
  jump = struct('value',value,'normal',normal, ...
    'value_squared',real(sum(weights.*abs(value).^2)), ...
    'normal_squared',real(sum(weights.*abs(normal).^2)));
  out = struct('shape','star','source_nodes',N,'weights',weights, ...
    'original_nodes',numel(density)/2, ...
    'native_grid',N==numel(density)/2, ...
    'signed_value',value,'signed_normal',normal,'jump',jump, ...
    'Bq',Bq,'density_scale',scale, ...
    'density',eta,'raw_action',raw, ...
    'scale_roundtrip_defect',norm((scale.*eta)./scale-eta)/ ...
      max(1,norm(eta)), ...
    'normal_unit_defect',max(abs(hypot(curve.nx,curve.ny)-1)));
end

function curve = LOCAL_curve(flag_geom,shape_arg,N)
  if strcmp(flag_geom,'trilobe')
    config = pilot_config();
    [C,curvelen] = pilot_geometry(N,shape_arg,config.model.R,config.model);
  elseif strcmp(flag_geom,'circle')
    [C,~] = geom.construct_cont(N,'circle',0,0,shape_arg);
  elseif strcmp(flag_geom,'star')
    [C,~] = geom.construct_cont(N,'star',0,0);
    C = shape_arg*C;
  else
    error('i92:Shape','Unsupported shape %s.',flag_geom);
  end
  t = (0:N-1)'*2*pi/N;
  x=C(1,:).'; y=C(4,:).'; xt=C(2,:).'; yt=C(5,:).';
  speed = hypot(xt,yt);
  nx = yt./speed; ny = -xt./speed;
  weights = (2*pi/N)*speed;
  curve = struct('t',t,'x',x,'y',y,'xt',xt,'yt',yt, ...
    'speed',speed,'nx',nx,'ny',ny,'weights',weights);
end

function H = LOCAL_interp_density_map(H0,N)
  n0 = size(H0,1)/2;
  H = [interpft(H0(1:n0,:),N,1);interpft(H0(n0+1:end,:),N,1)];
end

function [value,grad] = LOCAL_incident(q,beta_m,gamma,model,target)
  K = numel(gamma); qL = q(1:K); qR = q(K+1:end);
  x = target(1,:).'; y = target(2,:).';
  psi = exp(1i*y*beta_m.')/sqrt(model.d);
  left = exp(1i*(x-model.X_L)*gamma.').*psi;
  right = exp(-1i*(x-model.X_R)*gamma.').*psi;
  value = (left*qL+right*qR).';
  gradx = (left*(1i*gamma.*qL)+right*(-1i*gamma.*qR)).';
  grady = ((left+0).* (1i*beta_m.'))*qL+ ...
    ((right+0).* (1i*beta_m.'))*qR;
  grad = [gradx;grady.'];
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

function value=LOCAL_piece_field(cm,den,state,model,target,inside,Nsource)
  if isscalar(inside),inside=repmat(inside,1,size(target,2));end
  source=LOCAL_curve(cm.i9_shape,cm.i9_arg,Nsource); eta=LOCAL_interp_density_map(den,Nsource);
  value=zeros(1,size(target,2));
  for side=[false,true]
    idx=find(inside==side);
    for first=1:32:numel(idx)
      ii=idx(first:min(first+31,numel(idx)));xy=target(:,ii); n=numel(ii); if n==1,xy=[xy,xy];end
      if side
        src=[source.x.';source.y.']; X=xy(1,:).'-src(1,:);Y=xy(2,:).'-src(2,:);rr=hypot(X,Y); k=cm.kint;
        P=1i/4*besselh(0,1,k*rr); h=-1i*k/4*besselh(1,1,k*rr)./rr;Gx=h.*X;Gy=h.*Y;
      else
        [P,Gx,Gy]=kernel.qpgreen_mfs_pairmat([source.x.';source.y.'],xy,cm.i9_pars,cm.i9_proxy);
      end
      u=-(Gx*(source.nx.*source.weights.*eta(1:Nsource))+Gy*(source.ny.*source.weights.*eta(1:Nsource)))-P*(source.weights.*eta(Nsource+1:end));
      if ~side
        incident=LOCAL_incident(state,cm.channels.beta_m(:),cm.channels.gamma_m(:),model,xy);u=u+incident.';
      end
      value(ii)=u(1:n).';
    end
  end
end

function LOCAL_json(path,data)
  f=fopen(path,'w');assert(f>=0);cleanup=onCleanup(@() fclose(f));fprintf(f,'%s\n',jsonencode(data));
end
function selected=LOCAL_disks(center,negative,positive,density,q,prop,model,Nsource,out)
% Select at most twelve disjoint homogeneous disks in the three central cells.
  cells={center,negative,positive}; states={q,prop.Gminus*prop.cminus,prop.Gplus*prop.cplus}; shifts=[0,-1,1];
  candidates=[]; sample=linspace(-.46,.46,23); [xx,yy]=ndgrid(sample,sample); pts=[xx(:).';yy(:).'];
  for j=1:3
    cm=cells{j}; den=[cm.H_L,cm.H_R]*states{j}; cv=LOCAL_curve(cm.i9_shape,cm.i9_arg,4096);
    inside=inpolygon(pts(1,:),pts(2,:),cv.x,cv.y);
    dist=zeros(1,size(pts,2));
    for i=1:numel(dist),dist(i)=min(hypot(pts(1,i)-cv.x,pts(2,i)-cv.y));end
    radii=.96*min([dist;.5-abs(pts(1,:));.5-abs(pts(2,:));.20*ones(size(dist))],[],1);
    keep=radii>.012; pos=pts(:,keep); radii=radii(keep); ins=inside(keep);
    val=LOCAL_piece_field(cm,den,states{j},model,pos,ins,Nsource);
    rho=ones(size(radii));rho(ins)=cm.rho;kr=model.khat*sqrt(rho).*radii;
    v5=rho.*pi.*radii.^2.*(besselj(0,kr).^2+besselj(1,kr).^2).*abs(val).^2;
    candidates=[candidates;[j*ones(numel(radii),1),pos.',radii.',rho.',real(val).',imag(val).',v5.']]; %#ok<AGROW>
  end
  [~,ord]=sort(candidates(:,8),'descend'); selected=[];
  for i=ord.'
    c=candidates(i,2:3)+[shifts(candidates(i,1)),0];
    if isempty(selected),ok=true;else
      old=selected(:,2:3)+[shifts(selected(:,1)).',zeros(size(selected,1),1)];
      ok=all(hypot(old(:,1)-c(1),old(:,2)-c(2))>=selected(:,4)+candidates(i,4));
    end
    if ok,selected=[selected;candidates(i,:)];end %#ok<AGROW>
    if size(selected,1)==12,break;end
  end
end

function result=LOCAL_reference(out,config,input)
  % Input: same-run fixed hexadecimal export and numerical configuration.
  % Output: ordinary 1536-point jump samples, without rebuilding a field.
  timer=tic;d=jsondecode(fileread(input));
  if iscell(d.pieces),center=d.pieces{1};else,center=d.pieces(1);end
  k=real(LOCAL_unpack(d.k));beta=real(LOCAL_unpack(d.beta));period=real(LOCAL_unpack(d.d));H=real(LOCAL_unpack(d.H));
  proxy=struct('q',LOCAL_unpack(d.proxy_c),'Z',real(LOCAL_unpack(d.proxy_Z)),'H',H,'C_up',[],'C_down',[]);
  pars=struct('k',k,'beta',beta,'d',period,'periodic_axis','y','h2d_evaluator',@LOCAL_h2d_switch);
  LOCAL_proxy_ledger('reset');LOCAL_backend('set',struct('method','fmm','tolerance',config.backend.fmm_eps));
  N=1536;[C,L]=geom.construct_cont(N,'star',0,0);
  assert(max(C(1,:))-min(C(1,:))<H && max(C(4,:))-min(C(4,:))<period/2);
  weights=(L/N)*hypot(C(2,:),C(5,:)).';scale=sqrt([weights;weights]);
  co=[LOCAL_unpack(center.tau_coeff),LOCAL_unpack(center.zeta_coeff)];
  hat=zeros(N,2);hat(mod(center.modes(:),N)+1,:)=co;
  native=ifft(hat,[],1)*N;eta=native(:);
  mat=op.construct_A_QP(C,k,2*k,pars,proxy,L);
  chans=bloch.rayleigh_channels(k,beta,period,48,1);
  [BL,BR]=bloch.incident_rhs(C,chans,-.5,.5);
  raw=(mat*(scale.*eta))./scale+[BL,BR]*LOCAL_unpack(d.incident);
  LOCAL_float_samples(out,raw(1:N),-raw(N+1:end),weights);
  result=struct('epsilon',sqrt(sum(weights.*(abs(raw(1:N)).^2+abs(raw(N+1:end)).^2))),'seconds',toc(timer));
  LOCAL_json(fullfile(out,'reference.json'),result);
end
function x=LOCAL_unpack(p)
  % Input: hexadecimal column-major real/imaginary arrays. Output: binary64 array.
  x=reshape(complex(hex2num(char(p.real)),hex2num(char(p.imag))),p.shape(:).');
end
function LOCAL_float_samples(out,value,normal,weights)
  % Input: signed jumps and physical weights. Output: ordinary comparison CSV.
  N=numel(weights);s=(0:N-1)'*2*pi/N;
  fid=fopen(fullfile(out,'floating-samples.csv'),'w');guard=onCleanup(@()fclose(fid));
  fprintf(fid,'theta,weight,J0_re,J0_im,J1_re,J1_im\n');
  fprintf(fid,'%.17g,%.17g,%.17g,%.17g,%.17g,%.17g\n',[s,weights,real(value),imag(value),real(normal),imag(normal)].');
end
