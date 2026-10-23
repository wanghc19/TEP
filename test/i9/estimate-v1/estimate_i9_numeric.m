function [result,evidence] = estimate_i9_numeric()
%ESTIMATE_I9_NUMERIC One freshly reconstructed asymmetric I9.2 field.
% Purpose: Evaluate the I6-I8 resolvent direct-jump numerical formula.
% Based on: I8 pipeline_i8_numeric and I9 search_i9_physics/classify.
% Main changes: independent negative/positive leads and tails; actual geometry;
%   one fixed candidate, one 768 grid, and the relocated local mass disk.
% Output: UNCERTIFIED_RNUM scalars and raw fixed-field/reassembly evidence.
  config=estimate_i9_config(); model=config.model; model.khat=config.k0;
  cfg=config.discretization; K=cfg.K; N=config.evaluation.material_nodes;
  LOCAL_proxy_ledger('reset'); LOCAL_proxy_ledger('stage','field');
  timer=tic; stage=tic;
  fprintf('I9.2 field k=%.17g\n',config.k0);
  guard=LOCAL_solver_warning_guard();
  negative=LOCAL_cellmap('trilobe',model.a_negative,model.rho_lead, ...
    cfg.ntot_negative,model,config);
  positive=LOCAL_cellmap('trilobe',model.a_positive,model.rho_lead, ...
    cfg.ntot_positive,model,config);
  negative=LOCAL_lead(negative,'negative',config);
  positive=LOCAL_lead(positive,'positive',config);
  center=LOCAL_cellmap('star',model.star_scale,model.rho_center, ...
    cfg.ntot_center,model,config);
  beta_m=center.channels.beta_m(:); gamma=center.channels.gamma_m(:);
  [matching,q]=LOCAL_matching(center,positive.Z,negative.Z,beta_m,gamma);
  propagation=LOCAL_propagation(negative,positive,q,matching.T,K);
  center_density=[center.H_L,center.H_R]*q;
  lead_plus=[positive.H_L,positive.H_R]*propagation.Gplus;
  lead_minus=[negative.H_L,negative.H_R]*propagation.Gminus;
  clear guard;
  base=struct('model',model,'config',cfg,'center',center,'negative',negative, ...
    'positive',positive,'matching',matching,'q',q,'beta_m',beta_m,'gamma',gamma);
  timing.field=toc(stage);

  % --- stage 1: same physical densities on the sole evaluation grid ---
  fprintf('I9.2 material jumps\n'); stage=tic; LOCAL_proxy_ledger('stage','material');
  center_action=LOCAL_center_action(center,center_density,q,sqrt(model.rho_center)*config.k0,model,N);
  negative_action=LOCAL_material_action(negative,'trilobe',model.a_negative, ...
    sqrt(model.rho_lead)*config.k0,model,N);
  positive_action=LOCAL_material_action(positive,'trilobe',model.a_positive, ...
    sqrt(model.rho_lead)*config.k0,model,N);
  negative_sum=LOCAL_series(negative_action,propagation.Gminus,propagation.Pminus, ...
    propagation.cminus,config.evaluation.lead_cells);
  positive_sum=LOCAL_series(positive_action,propagation.Gplus,propagation.Pplus, ...
    propagation.cplus,config.evaluation.lead_cells);
  timing.material=toc(stage);

  % --- stage 2: longitudinal walls, with independent finite and tail terms ---
  fprintf('I9.2 longitudinal walls\n'); stage=tic; LOCAL_proxy_ledger('stage','walls');
  center_maps=LOCAL_center_wall(center,center_density,q,model,N,config.evaluation.wall_nodes);
  negative_maps=LOCAL_cell_wall_maps(negative,model,N,config.evaluation.wall_nodes);
  positive_maps=LOCAL_cell_wall_maps(positive,model,N,config.evaluation.wall_nodes);
  walls=LOCAL_walls(center_maps,negative_maps,positive_maps,propagation,model,config.evaluation.lead_cells);
  timing.walls=toc(stage);

  % --- stage 3: periodic seam is an exact-QP identity, diagnosed separately ---
  fprintf('I9.2 periodic seam consistency\n'); stage=tic; LOCAL_proxy_ledger('stage','periodic');
  periodic.center_action=LOCAL_periodic(center,model,N,config.evaluation.wall_nodes);
  periodic.negative_action=LOCAL_periodic(negative,model,N,config.evaluation.wall_nodes);
  periodic.positive_action=LOCAL_periodic(positive,model,N,config.evaluation.wall_nodes);
  periodic.center=LOCAL_apply_jump(periodic.center_action,q);
  periodic.negative=LOCAL_series(periodic.negative_action,propagation.Gminus, ...
    propagation.Pminus,propagation.cminus,config.evaluation.lead_cells);
  periodic.positive=LOCAL_series(periodic.positive_action,propagation.Gplus, ...
    propagation.Pplus,propagation.cplus,config.evaluation.lead_cells);
  periodic.included_in_epsilon=false;
  periodic.exact_qp_theoretical_value_squared=0;
  periodic.exact_qp_theoretical_normal_squared=0;
  timing.periodic_diagnostic=toc(stage);

  % --- stage 4: local background disk mass of this same field ---
  fprintf('I9.2 local mass\n'); stage=tic; LOCAL_proxy_ledger('stage','mass');
  mass=LOCAL_mass_diagnostic(center,center_density,q,beta_m,gamma,model, ...
    config.evaluation.disk_grid(1),config.evaluation.disk_grid(2),N,config.evaluation.disk_shift);
  timing.mass=toc(stage);
  fprintf('I9.2 geometry and scalar assembly\n'); stage=tic;
  geometry=LOCAL_geometry(model);
  components=LOCAL_components(center_action.jump,negative_sum,positive_sum,walls);
  mu_num=config.k0*config.k0;
  rho_min=min([model.rho_exterior,model.rho_center,model.rho_lead]);
  rho_max=max([model.rho_exterior,model.rho_center,model.rho_lead]);
  c0=model.overlap_count/(geometry.theta*model.collar_h);
  c1=model.overlap_count*model.collar_h/(2*geometry.theta);
  C_num=sqrt(c0/(rho_min*mu_num^2)+(c1+c0)/(4*mu_num)+c1*rho_max);
  epsilon_num=sqrt(components.normal_squared+components.value_squared/model.d^2);
  U_num=mass.quadrature_norm; Q_num=C_num*epsilon_num; denominator=U_num-Q_num;
  R_num=NaN; status='NO_FINITE_RNUM';
  if geometry.pass && components.complete && isfinite(denominator) && denominator>0
    R_num=2*mu_num*Q_num/denominator; status='UNCERTIFIED_RNUM';
  end
  audit=LOCAL_audit(base,propagation,center_density,lead_plus,lead_minus, ...
    center_action,negative_action,positive_action,components,config);
  if ~audit.pass, status='AUDIT_FAILED'; R_num=NaN; end
  result=struct('schema','I92_ESTIMATE_V1','status',status,'certified',false, ...
    'config',config,'k0',config.k0,'mu_num',mu_num,'point',matching.summary, ...
    'C_num',C_num,'epsilon_num',epsilon_num,'U_num',U_num,'Q_num',Q_num, ...
    'denominator',denominator,'R_num',R_num,'components',components, ...
    'trace_inputs',struct('c0',c0,'c1',c1,'rho_min',rho_min,'rho_max',rho_max), ...
    'geometry',geometry,'audit',audit,'negative_classification',negative.qz, ...
    'positive_classification',positive.qz);
  evidence=struct('base',base,'propagation',propagation,'center_density',center_density, ...
    'lead_plus',lead_plus,'lead_minus',lead_minus,'center_action',center_action, ...
    'negative_action',negative_action,'positive_action',positive_action, ...
    'negative_sum',negative_sum,'positive_sum',positive_sum,'center_maps',center_maps, ...
    'negative_maps',negative_maps,'positive_maps',positive_maps,'walls',walls, ...
    'periodic',periodic,'mass',mass);
  timing.geometry_scalar=toc(stage); result.timing=timing; result.runtime=toc(timer);
  result.proxy_calls=LOCAL_proxy_ledger('get');
end

%% ==================== Independent physical field ====================
% The I9.1 lead pencils and density coordinates are preserved exactly.
function cellmap=LOCAL_cellmap(shape,arg,rho,ntot,model,config)
  cfg=config.discretization;
  if strcmp(shape,'star')
    [C,curvelen]=geom.construct_cont(ntot,'star',0,0); C=arg*C;
  else
    [C,curvelen]=estimate_i9_geometry(ntot,arg,model.R,model);
  end
  pars=struct('k',model.khat,'beta',model.beta,'d',model.d,'periodic_axis','y', ...
    'h2d_evaluator',@LOCAL_h2d_fmm);
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
  diagnostic=estimate_i9_classify(diag(S),diag(T),residual,K,config); Zs=[];
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
function out=LOCAL_series(action,G,P,c,max_cells)
  rows=repmat(struct('index',0,'coordinate_norm',0,'value_squared',0,'normal_squared',0),max_cells,1);
  for n=0:max_cells-1
    jump=LOCAL_apply_jump(action,G*c);
    rows(n+1)=struct('index',n,'coordinate_norm',norm(c), ...
      'value_squared',jump.value_squared,'normal_squared',jump.normal_squared);
    c=P*c;
  end
  next=LOCAL_apply_jump(action,G*c);
  vr=next.value_squared/max(realmin,rows(end).value_squared);
  nr=next.normal_squared/max(realmin,rows(end).normal_squared);
  [vt,va]=LOCAL_geometric_tail(next.value_squared,vr);
  [nt,na]=LOCAL_geometric_tail(next.normal_squared,nr);
  fv=sum([rows.value_squared]); fn=sum([rows.normal_squared]);
  out=struct('cells',rows,'next',next,'next_coordinate',c, ...
    'finite_value_squared',fv,'finite_normal_squared',fn, ...
    'tail_value_squared_candidate',vt,'tail_normal_squared_candidate',nt, ...
    'tail_value_ratio',vr,'tail_normal_ratio',nr,'value_squared',fv+vt, ...
    'normal_squared',fn+nt,'tail_candidate_available',va&&na,'tail_certified',false);
end

function out=LOCAL_walls(center,negative,positive,prop,model,count)
  weight=model.d/center.nodes;
  xm=prop.Gminus*prop.cminus; xp=prop.Gplus*prop.cplus;
  left=struct('value',negative.right_value*xm-center.left_value, ...
    'normal',negative.right_dx*xm-center.left_dx);
  right=struct('value',positive.left_value*xp-center.right_value, ...
    'normal',center.right_dx-positive.left_dx*xp);
  left.value_squared=weight*sum(abs(left.value).^2); left.normal_squared=weight*sum(abs(left.normal).^2);
  right.value_squared=weight*sum(abs(right.value).^2); right.normal_squared=weight*sum(abs(right.normal).^2);
  neg=struct('weights',weight*ones(center.nodes,1), ...
    'signed_value_action',negative.right_value*prop.Gminus*prop.Pminus-negative.left_value*prop.Gminus, ...
    'signed_normal_action',negative.right_dx*prop.Gminus*prop.Pminus-negative.left_dx*prop.Gminus);
  pos=struct('weights',weight*ones(center.nodes,1), ...
    'signed_value_action',positive.left_value*prop.Gplus*prop.Pplus-positive.right_value*prop.Gplus, ...
    'signed_normal_action',positive.right_dx*prop.Gplus-positive.left_dx*prop.Gplus*prop.Pplus);
  out=struct('left',left,'right',right,'negative_action',neg,'positive_action',pos, ...
    'negative',LOCAL_series(neg,eye(size(prop.Pminus)),prop.Pminus,prop.cminus,count), ...
    'positive',LOCAL_series(pos,eye(size(prop.Pplus)),prop.Pplus,prop.cplus,count));
end

function out=LOCAL_periodic(cellmap,model,Nsource,Ntarget)
  source=LOCAL_curve(cellmap.i9_shape,cellmap.i9_arg,Nsource);
  H=LOCAL_interp_density_map([cellmap.H_L,cellmap.H_R],Nsource);
  x=model.X_L+(0:Ntarget-1)'*(model.X_R-model.X_L)/Ntarget;
  bottom=struct('x',x,'y',-model.d/2*ones(Ntarget,1),'nx',zeros(Ntarget,1),'ny',ones(Ntarget,1));
  top=bottom; top.y=-bottom.y;
  lb=LOCAL_qp_layer(source,bottom,cellmap.i9_pars,cellmap.i9_proxy);
  lt=LOCAL_qp_layer(source,top,cellmap.i9_pars,cellmap.i9_proxy);
  [bl,br]=bloch.incident_rhs(bottom,cellmap.channels,model.X_L,model.X_R); B=[bl,br];
  [tl,tr]=bloch.incident_rhs(top,cellmap.channels,model.X_L,model.X_R); T=[tl,tr];
  phase=exp(1i*model.beta*model.d);
  out=struct('weights',ones(Ntarget,1)*(model.X_R-model.X_L)/Ntarget, ...
    'signed_value_action',T(1:Ntarget,:)+lt.value*H-phase*(B(1:Ntarget,:)+lb.value*H), ...
    'signed_normal_action',T(Ntarget+1:end,:)+lt.normal*H-phase*(B(Ntarget+1:end,:)+lb.normal*H), ...
    'phase',phase,'x',x,'interpretation','exact-QP zero; evaluator consistency only');
end

function out=LOCAL_components(center,negative,positive,walls)
  out=struct('center',rmfield(center,{'value','normal'}), ...
    'negative_material',rmfield(negative,{'cells','next','next_coordinate'}), ...
    'positive_material',rmfield(positive,{'cells','next','next_coordinate'}), ...
    'left_junction',rmfield(walls.left,{'value','normal'}), ...
    'right_junction',rmfield(walls.right,{'value','normal'}), ...
    'negative_walls',rmfield(walls.negative,{'cells','next','next_coordinate'}), ...
    'positive_walls',rmfield(walls.positive,{'cells','next','next_coordinate'}));
  out.value_squared=center.value_squared+negative.value_squared+positive.value_squared+ ...
    walls.left.value_squared+walls.right.value_squared+walls.negative.value_squared+walls.positive.value_squared;
  out.normal_squared=center.normal_squared+negative.normal_squared+positive.normal_squared+ ...
    walls.left.normal_squared+walls.right.normal_squared+walls.negative.normal_squared+walls.positive.normal_squared;
  out.complete=negative.tail_candidate_available&&positive.tail_candidate_available&& ...
    walls.negative.tail_candidate_available&&walls.positive.tail_candidate_available;
end

%% ==================== Actual geometry and frozen-field audit ====================
% Three independent curves determine the sampled collar and global trace inputs.
function out=LOCAL_geometry(model)
  names={'center','negative','positive'}; shapes={'star','trilobe','trilobe'};
  args=[model.star_scale,model.a_negative,model.a_positive];
  expected=[0.0618*pi*model.star_scale^2,pi*model.R^2,pi*model.R^2];
  for j=1:3
    for level=1:numel(model.geometry_nodes)
      levels(level)=LOCAL_geom_level(model,shapes{j},args(j),expected(j),model.geometry_nodes(level)); %#ok<AGROW>
    end
    out.(names{j})=struct('levels',levels,'pass',all([levels.pass]), ...
      'curvature_max',max([levels.curvature_max]),'theta',min([levels.theta]));
  end
  centers=[-model.L,0,model.L]; order={'negative','center','positive'};
  boxes=zeros(3,4);
  for j=1:3
    a=out.(order{j}).levels(end); boxes(j,:)=[a.xmin+centers(j),a.xmax+centers(j),a.ymin,a.ymax];
  end
  adjacent_gap=[boxes(2,1)-boxes(1,2),boxes(3,1)-boxes(2,2)];
  disk_wall=min([model.disk_center(1)-model.X_L,model.X_R-model.disk_center(1), ...
    model.d/2-abs(model.disk_center(2))])-model.disk_radius;
  disk_curve=out.center.levels(end).mass_disk_clearance;
  disk_conservative_y=model.disk_center(2)-model.disk_radius-out.center.levels(end).ymax;
  out.adjacent_inclusion_horizontal_clearances=adjacent_gap;
  out.disk_wall_clearance=disk_wall; out.disk_curve_clearance=disk_curve;
  out.disk_conservative_vertical_clearance=disk_conservative_y;
  out.curvature_max=max([out.center.curvature_max,out.negative.curvature_max,out.positive.curvature_max]);
  out.theta=min([out.center.theta,out.negative.theta,out.positive.theta]);
  out.pass=out.center.pass&&out.negative.pass&&out.positive.pass&& ...
    all(adjacent_gap>2*model.collar_h)&&disk_wall>2*model.collar_h&&disk_conservative_y>2*model.collar_h;
  out.certified=false;
end

function out=LOCAL_geom_level(model,shape,arg,expected,N)
  if strcmp(shape,'star')
    [C0,~]=geom.construct_cont(N,'star',0,0); C=arg*C0;
  else
    [C,~]=estimate_i9_geometry(N,arg,model.R,model); C0=C;
  end
  dt=2*pi/N; speed=hypot(C(2,:),C(5,:));
  curvature=(C(2,:).*C(6,:)-C(5,:).*C(3,:))./speed.^3;
  segment=dt*speed; total=sum(segment); cs=[0,cumsum([segment,segment])];
  z=C(1,:)+1i*C(4,:); normal=(C(5,:)-1i*C(2,:))./speed;
  zp=z+model.collar_h*normal; zm=z-model.collar_h*normal;
  far_min=inf; offset_min=inf; index=1:N;
  for offset=1:floor(N/2)
    forward=cs(index+offset)-cs(index); mask=min(forward,total-forward)>=model.arc_band;
    if any(mask)
      other=mod(index+offset-1,N)+1;
      distance=abs(z(other)-z(index)); far_min=min(far_min,min(distance(mask)));
      distance=min([abs(zp(other)-zp(index));abs(zp(other)-zm(index)); ...
        abs(zm(other)-zp(index));abs(zm(other)-zm(index))],[],1);
      offset_min=min(offset_min,min(distance(mask)));
    end
  end
  K=max(abs(curvature)); theta=1-model.collar_h*K;
  local_factor=K*(model.arc_band/2+model.collar_h);
  wall_clear=min(model.X_R-max(C(1,:)),min(C(1,:))-model.X_L);
  periodic_boundary_clear=model.d/2-max(abs(C(4,:)));
  copy_y=model.d-(max(C(4,:))-min(C(4,:)));
  disk_gap=min(hypot(C(1,:)-model.disk_center(1),C(4,:)-model.disk_center(2)))-model.disk_radius;
  area=0.5*dt*sum(C(1,:).*C(5,:)-C(4,:).*C(2,:));
  scale_defect=0;
  if strcmp(shape,'star'), scale_defect=norm(C-model.star_scale*C0,'fro'); end
  pass=min(speed)>0&&theta>0&&local_factor<1&&far_min>2*model.collar_h&& ...
    offset_min>0&&wall_clear>2*model.collar_h&&copy_y>2*model.collar_h&& ...
    periodic_boundary_clear>2*model.collar_h&&abs(area-expected)<=model.area_tolerance&& ...
    scale_defect<=model.scale_eps_factor*eps*max(1,norm(C,'fro'));
  out=struct('sample_nodes',N,'shape',shape,'shape_arg',arg,'area',area, ...
    'expected_area',expected,'area_defect',abs(area-expected),'six_row_scale_defect',scale_defect, ...
    'xmin',min(C(1,:)),'xmax',max(C(1,:)),'ymin',min(C(4,:)),'ymax',max(C(4,:)), ...
    'speed_min',min(speed),'speed_max',max(speed),'curvature_max',K, ...
    'collar_h',model.collar_h,'arc_band',model.arc_band,'theta',theta, ...
    'local_factor',local_factor,'far_chord_min',far_min,'offset_pair_min',offset_min, ...
    'wall_clearance',wall_clear,'periodic_y_clearance',copy_y, ...
    'periodic_boundary_clearance',periodic_boundary_clear,'mass_disk_clearance',disk_gap,'pass',pass);
end

function out=LOCAL_audit(base,prop,density,lead_plus,lead_minus,ca,na,pa,components,config)
  q=base.q;
  defects=struct('q_norm',abs(norm(q)-1), ...
    'center_density',LOCAL_relative(density,[base.center.H_L,base.center.H_R]*q), ...
    'negative_density_map',LOCAL_relative(lead_minus,[base.negative.H_L,base.negative.H_R]*prop.Gminus), ...
    'positive_density_map',LOCAL_relative(lead_plus,[base.positive.H_L,base.positive.H_R]*prop.Gplus), ...
    'center_BIE',LOCAL_density_residual(base.center), ...
    'negative_BIE',LOCAL_density_residual(base.negative),'positive_BIE',LOCAL_density_residual(base.positive), ...
    'plus_trace',prop.plus_coordinate_residual,'minus_trace',prop.minus_coordinate_residual, ...
    'plus_recurrence',prop.plus_diagnostic.solve_residual,'minus_recurrence',prop.minus_diagnostic.solve_residual, ...
    'center_scale',ca.scale_roundtrip_defect,'negative_scale',na.scale_roundtrip_defect, ...
    'positive_scale',pa.scale_roundtrip_defect,'negative_raw',na.raw_matrix_identity_defect, ...
    'positive_raw',pa.raw_matrix_identity_defect,'matching',base.matching.assembly_defect);
  values=cell2mat(struct2cell(defects));
  out=struct('defects',defects,'maximum_defect',max(values), ...
    'tolerance',config.evaluation.audit_tolerance,'pass',all(isfinite(values))&& ...
    max(values)<=config.evaluation.audit_tolerance&&components.complete);
end

%% ==================== Reviewed matching and evaluation helpers ====================
% The following formulas retain I8 density, Kress, incident-wave and FMM conventions.
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
  config = estimate_i9_config();
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

function out = LOCAL_material_action(cellmap,flag_geom,shape_arg,kint,model,N)
  if strcmp(flag_geom,'trilobe')
    config = estimate_i9_config();
    [C,curvelen] = estimate_i9_geometry(N,shape_arg,config.model.R,config.model);
  elseif strcmp(flag_geom,'circle')
    [C,curvelen] = geom.construct_cont(N,'circle',0,0,shape_arg);
  elseif strcmp(flag_geom,'star')
    [C,curvelen] = geom.construct_cont(N,'star',0,0);
    C = shape_arg*C;
  else
    error('i92:Shape','Unsupported shape %s.',flag_geom);
  end
  curve = LOCAL_curve(flag_geom,shape_arg,N);
  boundary_speed = hypot(C(2,:),C(5,:)).';
  boundary_weights = (curvelen/N)*boundary_speed;
  original_density_map = [cellmap.H_L,cellmap.H_R];
  density_map = LOCAL_interp_density_map(original_density_map,N);
  A_scaled = op.construct_A_QP(C,model.khat,kint, ...
    cellmap.i9_pars,cellmap.i9_proxy,curvelen);
  [B_L,B_R] = bloch.incident_rhs(C,cellmap.channels, ...
    model.X_L,model.X_R);
  B = [B_L,B_R];
  density_scale = sqrt(repmat(boundary_weights,2,1));
  scaled_density_map = density_scale.*density_map;
  scaled_residual_action = A_scaled*scaled_density_map+density_scale.*B;
  raw_residual_action = scaled_residual_action./density_scale;
  A_raw = (A_scaled.*density_scale.')./density_scale;
  raw_from_matrix = A_raw*density_map+B;
  signed_value_action = raw_residual_action(1:N,:);
  signed_normal_action = -raw_residual_action(N+1:end,:);
  out = struct('shape',flag_geom,'shape_arg',shape_arg,'source_nodes',N, ...
    'target_nodes',N,'original_nodes',size(original_density_map,1)/2, ...
    'native_grid',N==size(original_density_map,1)/2, ...
    'weights',boundary_weights, ...
    'signed_value_action',signed_value_action, ...
    'signed_normal_action',signed_normal_action, ...
    'density_map',density_map,'density_scale',density_scale, ...
    'A_scaled',A_scaled,'B',B, ...
    'scale_roundtrip_defect',norm( ...
      scaled_density_map./density_scale-density_map,'fro')/ ...
      max(1,norm(density_map,'fro')), ...
    'raw_matrix_identity_defect',norm( ...
      raw_from_matrix-raw_residual_action,'fro')/ ...
      max(1,norm(raw_residual_action,'fro')), ...
    'normalized_action_frobenius',norm(raw_residual_action,'fro')/ ...
      max(1,norm(B,'fro')+norm(A_raw,'fro')*norm(density_map,'fro')), ...
    'interpolation_roundtrip_defect',norm( ...
      LOCAL_interp_density_map(density_map,size(original_density_map,1)/2)- ...
      original_density_map,'fro')/max(1,norm(original_density_map,'fro')), ...
    'physical_arclength_sum',sum(boundary_weights), ...
    'normal_unit_defect',max(abs(hypot(curve.nx,curve.ny)-1)));
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
    'A_scaled',A_scaled,'Bq',Bq,'density_scale',scale, ...
    'density',eta,'raw_action',raw, ...
    'scale_roundtrip_defect',norm((scale.*eta)./scale-eta)/ ...
      max(1,norm(eta)), ...
    'normal_unit_defect',max(abs(hypot(curve.nx,curve.ny)-1)));
end

function out = LOCAL_apply_jump(action,state)
  value = action.signed_value_action*state;
  normal = action.signed_normal_action*state;
  out = struct('value',value,'normal',normal, ...
    'value_squared',real(sum(action.weights.*abs(value).^2)), ...
    'normal_squared',real(sum(action.weights.*abs(normal).^2)));
end

function [value,available] = LOCAL_geometric_tail(next_term,ratio)
  if isfinite(next_term) && isfinite(ratio) && ratio >= 0 && ratio < 1
    value = next_term/(1-ratio);
    available = true;
  else
    value = NaN;
    available = false;
  end
end

function layer = LOCAL_qp_layer(source,target,pars,proxy)
  nt = numel(target.x); ns = numel(source.x);
  value = zeros(nt,2*ns); normal = zeros(nt,2*ns);
  config = estimate_i9_config(); batch = config.evaluation.wall_batch;
  src = [source.x.';source.y.'];
  for first = 1:batch:nt
    index = first:min(first+batch-1,nt);
    trg = [target.x(index).';target.y(index).'];
    [P,Gx,Gy,Hxx,Hxy,Hyy] = ...
      kernel.qpgreen_mfs_pairmat(src,trg,pars,proxy);
    wt = source.weights.'; sx = source.nx.'; sy = source.ny.';
    D = -(LOCAL_row_scale(Gx,sx)+LOCAL_row_scale(Gy,sy)).*wt;
    S = -P.*wt;
    nx = target.nx(index); ny = target.ny(index);
    Ttau = -(nx.*(Hxx.*sx+Hxy.*sy)+ ...
      ny.*(Hxy.*sx+Hyy.*sy)).*wt;
    Nzeta = -(nx.*Gx+ny.*Gy).*wt;
    value(index,:) = [D,S];
    normal(index,:) = [Ttau,Nzeta];
  end
  layer = struct('value',value,'normal',normal);
end

function out = LOCAL_row_scale(matrix,row)
  out = matrix.*row;
end

function curve = LOCAL_curve(flag_geom,shape_arg,N)
  if strcmp(flag_geom,'trilobe')
    config = estimate_i9_config();
    [C,curvelen] = estimate_i9_geometry(N,shape_arg,config.model.R,config.model);
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

function out = LOCAL_cell_wall_maps(cellmap,model,Nsource,Ntarget)
  shape = cellmap.i9_shape; shape_arg = cellmap.i9_arg;
  source = LOCAL_curve(shape,shape_arg,Nsource);
  H = LOCAL_interp_density_map([cellmap.H_L,cellmap.H_R],Nsource);
  y = -model.d/2+(0:Ntarget-1)'*model.d/Ntarget;
  left = struct('x',model.X_L*ones(Ntarget,1),'y',y, ...
    'nx',ones(Ntarget,1),'ny',zeros(Ntarget,1));
  right = struct('x',model.X_R*ones(Ntarget,1),'y',y, ...
    'nx',ones(Ntarget,1),'ny',zeros(Ntarget,1));
  layer_left = LOCAL_qp_layer(source,left,cellmap.i9_pars,cellmap.i9_proxy);
  layer_right = LOCAL_qp_layer(source,right,cellmap.i9_pars,cellmap.i9_proxy);
  geometry_left = struct('x',left.x,'y',left.y,'nx',left.nx,'ny',left.ny);
  geometry_right = struct('x',right.x,'y',right.y, ...
    'nx',right.nx,'ny',right.ny);
  [BLL,BLR] = bloch.incident_rhs(geometry_left,cellmap.channels, ...
    model.X_L,model.X_R);
  [BRL,BRR] = bloch.incident_rhs(geometry_right,cellmap.channels, ...
    model.X_L,model.X_R);
  Bleft = [BLL,BLR]; Bright = [BRL,BRR];
  out = struct('nodes',Ntarget,'y',y, ...
    'left_value',Bleft(1:Ntarget,:)+layer_left.value*H, ...
    'left_dx',Bleft(Ntarget+1:end,:)+layer_left.normal*H, ...
    'right_value',Bright(1:Ntarget,:)+layer_right.value*H, ...
    'right_dx',Bright(Ntarget+1:end,:)+layer_right.normal*H);
end

function out = LOCAL_center_wall(cellmap,density,q,model,Nsource,Ntarget)
%LOCAL_CENTER_WALL Evaluate the same stored center density on both walls.

  source = LOCAL_curve('star',model.star_scale,Nsource);
  eta = LOCAL_interp_density_map(density,Nsource);
  y = -model.d/2+(0:Ntarget-1)'*model.d/Ntarget;
  left = struct('x',model.X_L*ones(Ntarget,1),'y',y, ...
    'nx',ones(Ntarget,1),'ny',zeros(Ntarget,1));
  right = struct('x',model.X_R*ones(Ntarget,1),'y',y, ...
    'nx',ones(Ntarget,1),'ny',zeros(Ntarget,1));
  layer_left = LOCAL_qp_layer(source,left,cellmap.i9_pars,cellmap.i9_proxy);
  layer_right = LOCAL_qp_layer(source,right,cellmap.i9_pars,cellmap.i9_proxy);
  [BLL,BLR] = bloch.incident_rhs(left,cellmap.channels,model.X_L,model.X_R);
  [BRL,BRR] = bloch.incident_rhs(right,cellmap.channels,model.X_L,model.X_R);
  Bleft=[BLL,BLR]*q; Bright=[BRL,BRR]*q;
  out=struct('nodes',Ntarget,'y',y, ...
    'left_value',Bleft(1:Ntarget)+layer_left.value*eta, ...
    'left_dx',Bleft(Ntarget+1:end)+layer_left.normal*eta, ...
    'right_value',Bright(1:Ntarget)+layer_right.value*eta, ...
    'right_dx',Bright(Ntarget+1:end)+layer_right.normal*eta);
end

function out = LOCAL_mass_diagnostic(center,density,q,beta_m,gamma, ...
    model,Nr,Ntheta,Nsource,theta_shift)
  disk_center = model.disk_center; radius = model.disk_radius;
  radial = radius*sqrt(((1:Nr)-0.5)/Nr);
  theta = ((0:Ntheta-1)+theta_shift)*2*pi/Ntheta;
  [rr,tt] = ndgrid(radial,theta);
  targets = disk_center+[rr(:).'.*cos(tt(:).');rr(:).'.*sin(tt(:).')];
  [value,grad] = LOCAL_center_field(center,density,q,beta_m,gamma, ...
    model,targets,Nsource);
  area = pi*radius^2;
  quadrature_norm = sqrt(area*mean(abs(value).^2));
  center_target = disk_center;
  [value_center,~] = LOCAL_center_field(center,density,q,beta_m,gamma, ...
    model,center_target,Nsource);
  gradient_samples = sqrt(sum(abs(grad).^2,1));
  sampled_gradient_max = max(gradient_samples);
  cone_point_margin = max(abs(value_center)-radius*sampled_gradient_max,0);
  cone_candidate = sqrt(pi)*radius*cone_point_margin;
  out = struct('center',disk_center,'radius',radius, ...
    'radial_nodes',Nr,'angular_nodes',Ntheta, ...
    'angular_shift',theta_shift, ...
    'quadrature_norm',quadrature_norm, ...
    'center_value_abs',abs(value_center), ...
    'sampled_gradient_max',sampled_gradient_max, ...
    'cone_point_margin',cone_point_margin, ...
    'cone_candidate',cone_candidate, ...
    'one_sided_certified',false,'sample_values',value, ...
    'sample_gradient',grad);
end

function [value,grad] = LOCAL_center_field(center,density,q,beta_m,gamma, ...
    model,targets,Nsource)
  source = LOCAL_curve('star',model.star_scale,Nsource);
  n0 = numel(density)/2;
  eta = [interpft(density(1:n0),Nsource); ...
    interpft(density(n0+1:end),Nsource)];
  tau = eta(1:Nsource); zeta = eta(Nsource+1:end);
  value = zeros(1,size(targets,2)); grad = zeros(2,size(targets,2));
  config = estimate_i9_config(); batch = config.evaluation.mass_batch;
  src = [source.x.';source.y.'];
  for first = 1:batch:size(targets,2)
    index = first:min(first+batch-1,size(targets,2));
    trg = targets(:,index);
    % The public pair matrix assumes a non-vector target-by-source array.
    % Duplicate a singleton physical target to avoid its logical-index shape
    % degeneration, then retain its first identical row for both backends.
    pair_targets = trg;
    if size(trg,2) == 1, pair_targets = [trg,trg]; end
    [P,Gx,Gy,Hxx,Hxy,Hyy] = ...
      kernel.qpgreen_mfs_pairmat(src,pair_targets,center.i9_pars,center.i9_proxy);
    if size(trg,2) == 1
      P = P(1,:); Gx = Gx(1,:); Gy = Gy(1,:);
      Hxx = Hxx(1,:); Hxy = Hxy(1,:); Hyy = Hyy(1,:);
    end
    wt = source.weights; nx = source.nx; ny = source.ny;
    charge_x = nx.*wt.*tau; charge_y = ny.*wt.*tau;
    charge_z = wt.*zeta;
    layer_value = -(Gx*charge_x+Gy*charge_y)-P*charge_z;
    layer_x = -(Hxx*charge_x+Hxy*charge_y)-Gx*charge_z;
    layer_y = -(Hxy*charge_x+Hyy*charge_y)-Gy*charge_z;
    [incident,incident_grad] = LOCAL_incident(q,beta_m,gamma,model,trg);
    value(index) = incident+layer_value.';
    grad(:,index) = incident_grad+[layer_x.';layer_y.'];
  end
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

function value = LOCAL_density_residual(cellmap)
  scale = sqrt(repmat(cellmap.far_aux.weights(:),2,1));
  H = [cellmap.H_L,cellmap.H_R];
  B = [cellmap.B_L,cellmap.B_R];
  value = norm(cellmap.A_QP*(scale.*H)+scale.*B,'fro')/ ...
    max(1,norm(scale.*B,'fro'));
end

function value = LOCAL_relative(a,b)
  value=norm(a-b,'fro')/max(1,norm(b,'fro'));
end

function value = LOCAL_rel(a,b)
  value=abs(a-b)/max([realmin,abs(a),abs(b)]);
end

function cleanup = LOCAL_solver_warning_guard()
  state = warning; cleanup = onCleanup(@() warning(state));
  warning('error','MATLAB:singularMatrix');
  warning('error','MATLAB:nearlySingularMatrix');
  warning('error','MATLAB:illConditionedMatrix');
  warning('error','MATLAB:rankDeficientMatrix');
end

function [pot,grad,hess] = LOCAL_h2d_fmm(wavek,sources,charge,targ)
%LOCAL_H2D_FMM The reviewed fmm-v1 charge-only proxy convention, unchanged.
  callback_timer = tic; nt = size(targ,2);
  srcinfo = struct('sources',sources,'charges',reshape(charge,1,[]));
  config = estimate_i9_config();
  [U,ier] = hfmm2d(config.backend.fmm_eps,wavek,srcinfo,0,targ,3);
  if ~isscalar(ier) || ier ~= 0
    error('i92:FMMError','FMM2D returned ier=%g.',ier);
  end
  pot = reshape(U.pottarg,1,nt);
  grad = reshape(U.gradtarg,2,nt);
  hess = reshape(U.hesstarg,3,nt);
  if any(~isfinite(pot),'all') || any(~isfinite(grad),'all') || any(~isfinite(hess),'all')
    error('i92:FMMNonfinite','FMM2D returned nonfinite smooth-proxy fields.');
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
