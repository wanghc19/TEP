function result=switch_run(out,config,settings)
  % SWITCH_RUN Measure the wrapped MFS (method of fundamental solutions) defect.
  % Input
  %   Explicit output directory, fixed pilot configuration and probe settings.
  % Output
  %   Compact JSON/CSV diagnostics; the fixed field is built once in memory.
  assert(isfolder(out));maxNumCompThreads(11);timer=tic;result=struct('status','STARTED','config',config,'settings',settings,'times',struct());
  try
    model=config.model;model.khat=config.k0;cfg=config.discretization;K=cfg.K;
    LOCAL_proxy_ledger('reset');LOCAL_backend('set',struct('method','fmm','tolerance',config.backend.fmm_eps));
    LOCAL_part(out,'field');stage=tic;guard=LOCAL_solver_warning_guard();
    negative=LOCAL_cellmap('trilobe',model.a_negative,model.rho_lead,cfg.ntot_negative,model,config);
    positive=LOCAL_cellmap('trilobe',model.a_positive,model.rho_lead,cfg.ntot_positive,model,config);
    negative=LOCAL_lead(negative,'negative',config);positive=LOCAL_lead(positive,'positive',config);
    center=LOCAL_cellmap('star',model.star_scale,model.rho_center,cfg.ntot_center,model,config);
    beta_m=center.channels.beta_m(:);gamma=center.channels.gamma_m(:);
    [matching,q]=LOCAL_matching(center,positive.Z,negative.Z,beta_m,gamma);
    prop=LOCAL_propagation(negative,positive,q,matching.T,K);density=[center.H_L,center.H_R]*q;clear guard
    result.times.field=toc(stage);result.build_count=1;
    frozen={q,density,prop,center.i9_proxy.q,negative.i9_proxy.q,positive.i9_proxy.q};
    cells={center,negative,positive};names={'center','negative','positive'};
    stage=tic;value=LOCAL_piece_field(center,density,q,model,model.disk_center,false,1536);
    z=model.khat*model.disk_radius;
    Q5=sqrt(pi*model.disk_radius^2*(besselj(0,z)^2+besselj(1,z)^2)*abs(value)^2);
    result.baseline=struct('Q5',Q5,'reference',settings.reference_Q5,'relative',abs(Q5/settings.reference_Q5-1),'q_norm',norm(q));
    result.times.baseline=toc(stage);LOCAL_json(fullfile(out,'result.json'),result);
    assert(result.baseline.relative<settings.reference_tolerance,'switch:Baseline','Fixed-field Q5 reproduction failed.');
    LOCAL_part(out,'geometry');stage=tic;geometry=struct([]);
    for t=1:3
      cm=cells{t};z=LOCAL_curve(cm.i9_shape,cm.i9_arg,settings.geometry_samples);dt=2*pi/numel(z.x);ex=zeros(1,4);
      for k=1:4
        axis=1+(k>2);sgn=1;if mod(k,2)==0,sgn=-1;end
        vals=z.x;if axis==2,vals=z.y;end
        [~,ii]=min(sgn*vals);f=@(theta)sgn*LOCAL_coordinate(cm,model,theta,axis);
        [~,v]=fminbnd(f,z.t(ii)-dt,z.t(ii)+dt,optimset('TolX',1e-14));ex(k)=sgn*v;
      end
      item=struct('piece',names{t},'x_extent',ex(1:2),'y_extent',ex(3:4),'switch_inclusion_clearance',model.d/2-diff(ex(3:4)), ...
        'Y_range',[model.X_L-ex(2),model.X_R-ex(1)],'material_pair_max_Y',diff(ex(1:2)), ...
        'actual_interior_kernel','free-space','interior_switch_integral',0);
      assert(item.switch_inclusion_clearance>0,'switch:Clip','Switch lines intersect the inclusion; clipping implementation is required.');
      if t==1,geometry=item;else,geometry(t)=item;end
    end
    ymax=max(abs([geometry.Y_range]));assert(ymax<model.H,'switch:PlaneWave','Plane-wave branch is reached; vertical-cut integration is required.');
    result.geometry=geometry;result.max_abs_Y=ymax;result.plane_wave_reached=false;result.times.geometry=toc(stage);
    LOCAL_part(out,'kernel');stage=tic;
    Y=linspace(-ymax,ymax,settings.jump_grid).';
    J=switch_jumps(Y,center.i9_pars,center.i9_proxy,settings.kernel_block);
    LOCAL_jump_csv(fullfile(out,'kernel-jumps.csv'),Y,J);
    [Ycheck,offsets]=LOCAL_kernel_checks(center,model,settings,ymax);
    result.kernel=offsets;
    % Hypothetical wrapped interior proxies diagnose the manager's kernel test;
    % they are absent from the interior field and do not enter Q_sw.
    for rho=[model.rho_center,model.rho_lead]
      pars=center.i9_pars;pars.k=sqrt(rho)*model.khat;
      pc=struct('H',model.H,'proxy_dist',model.proxy_dist,'N_side',cfg.nside,'N_top',cfg.ntop,'N_proxy_edge',cfg.nproxy,'M_pw',cfg.mpw);
      pr=kernel.precomp_proxy(pars,pc);cc=center;cc.i9_pars=pars;cc.i9_proxy=pr;
      [~,check]=LOCAL_kernel_checks(cc,model,settings,ymax);check.rho=rho;check.used_in_field=false;result.kernel(end+1)=check;
    end
    [jr,lo,up]=switch_jumps(Ycheck,center.i9_pars,center.i9_proxy,settings.kernel_block);
    interpolated=interp1(Y,J,Ycheck,'spline');
    result.kernel_interpolation=struct('offgrid_points',numel(Ycheck),'max_absolute',max(abs(interpolated-jr),[],1), ...
      'relative_to_jump_max',max(abs(interpolated-jr),[],1)./max(abs(jr),[],1),'branch_scale',max(abs([lo;up]),[],1));
    result.times.kernel=toc(stage);LOCAL_json(fullfile(out,'result.json'),result);
    LOCAL_part(out,'source-integrals');stage=tic;result.levels=struct([]);
    for N=settings.source_counts
      level=LOCAL_switch_level(cells,names,density,prop,model,config,settings,N,Y(1:2:end),J(1:2:end,:),settings.line_order,out,sprintf('n%d-q%d-coarse',N,settings.line_order));
      if isempty(result.levels),result.levels=level;else,result.levels(end+1)=level;end
      LOCAL_json(fullfile(out,'result.json'),result);
    end
    result.refined_kernel=LOCAL_switch_level(cells,names,density,prop,model,config,settings,settings.source_counts(end),Y,J,settings.line_order,out,'fine-kernel');
    result.refined_line=LOCAL_switch_level(cells,names,density,prop,model,config,settings,settings.source_counts(end),Y,J,settings.check_order,out,'fine-line');
    result.times.integrals=toc(stage);
    last=result.levels(end);prev=result.levels(end-1);best=result.refined_line;
    result.convergence=struct('source_relative',abs(last.Q_sw/prev.Q_sw-1), ...
      'kernel_relative',abs(result.refined_kernel.Q_sw/last.Q_sw-1), ...
      'line_relative',abs(best.Q_sw/result.refined_kernel.Q_sw-1), ...
      'source_piece_relative',abs([last.pieces.integral]./[prev.pieces.integral]-1));
    result.Q_sw=best.Q_sw;result.Q_sw_separate_layers=best.Q_sw_separate_layers;
    [~,big]=max([best.pieces.integral]);result.largest_piece=best.pieces(big).piece;
    result.Q_total=settings.Q_grp+result.Q_sw;
    allow=settings.radius_target*settings.U/(2*config.k0^2+settings.radius_target);
    result.budget=struct('U',settings.U,'Q_allow',allow,'Q_grp',settings.Q_grp,'Q_sw',result.Q_sw, ...
      'Q_total',result.Q_total,'margin',allow/result.Q_total,'holds',allow>result.Q_total, ...
      'separate_layer_margin',allow/(settings.Q_grp+best.Q_sw_separate_layers));
    LOCAL_json(fullfile(out,'result.json'),result);
    assert(max([result.convergence.source_relative,result.convergence.kernel_relative,result.convergence.line_relative])<settings.settling_tolerance, ...
      'switch:Convergence','Source, kernel table or line quadrature is not settled to the declared 1 percent tolerance.');
    LOCAL_part(out,'codepath');stage=tic;result.codepath=LOCAL_codepath(center,density,q,model,settings);result.times.codepath=toc(stage);
    LOCAL_json(fullfile(out,'result.json'),result);
    assert(all([result.codepath.pass]),'switch:Codepath','Actual field jump check exceeds the declared roundoff envelope.');
    if isfield(settings,'prime')
      LOCAL_part(out,'prime');stage=tic;
      result.original_reproduction_relative=abs(result.Q_sw/settings.prime.Q_original_reference-1);
      LOCAL_json(fullfile(out,'result.json'),result);
      assert(result.original_reproduction_relative<settings.prime.reproduction_tolerance,'switch:Reproduction','Original switch budget changed.');
      result.prime=LOCAL_prime(cells,names,density,prop,model,config,settings,Y,J,out);
      result.times.prime=toc(stage);
    end
    result.frozen_unchanged=isequaln(frozen,{q,density,prop,center.i9_proxy.q,negative.i9_proxy.q,positive.i9_proxy.q});assert(result.frozen_unchanged);
    result.status='COMPLETE';result.seconds=toc(timer);result.times.other=result.seconds-sum(cell2mat(struct2cell(result.times)));
    LOCAL_json(fullfile(out,'result.json'),result);LOCAL_part(out,'complete');
  catch err
    result.status='FAILED';result.seconds=toc(timer);result.failure=struct('identifier',err.identifier,'message',err.message,'stack',err.stack);
    LOCAL_json(fullfile(out,'result.json'),result);rethrow(err)
  end
end
function v=LOCAL_coordinate(cm,model,t,axis)
  % Input: frozen curve, model, angle, coordinate index. Output: curve coordinate.
  if strcmp(cm.i9_shape,'star')
    xy=.2*cm.i9_arg*[(1.5+.3*cos(5*t))*cos(t),(1+.3*cos(5*t))*sin(t)];
  else
    r=model.R/sqrt(1+cm.i9_arg^2/2)*(1+cm.i9_arg*cos(3*t));xy=r*[cos(t),sin(t)];
  end
  v=xy(axis);
end
function [Y,r]=LOCAL_kernel_checks(cm,model,settings,maxY)
  % Input: frozen proxy and physical model. Output: exact-branch and offset tests.
  Y=linspace(-maxY,maxY,1001).';[J,L,U]=switch_jumps(Y,cm.i9_pars,cm.i9_proxy,settings.kernel_block);
  pars=cm.i9_pars;pars=rmfield(pars,'h2d_evaluator');
  r=struct('k',pars.k,'rho',1,'used_in_field',true,'Y_range',[-maxY,maxY], ...
    'jump_max',max(abs(J),[],1),'branch_max',max(abs([L;U]),[],1),'offsets',struct([]));
  for e=settings.offsets
    targets=[Y.';(model.d/2-e)*ones(1,numel(Y))];a=cell(1,6);b=a;
    [a{:}]=kernel.qpgreen_mfs_pairmat([0;0],targets,pars,cm.i9_proxy);
    targets(2,:)=model.d/2+e;[b{:}]=kernel.qpgreen_mfs_pairmat([0;0],targets,pars,cm.i9_proxy);
    A=cell2mat(a);B=cell2mat(b);raw=B-A;corrected=raw;
    he=((model.d/2+e)-(model.d/2-e))/2;
    corrected(:,1)=raw(:,1)-he*(A(:,3)+B(:,3));corrected(:,2)=raw(:,2)-he*(A(:,5)+B(:,5));corrected(:,3)=raw(:,3)-he*(A(:,6)+B(:,6));
    v=struct('offset',e,'actual_half_separation',he,'raw_max',max(abs(raw),[],1), ...
      'raw_difference_from_branch',max(abs(raw-J),[],1),'corrected_value_gradient_difference',max(abs(corrected(:,1:3)-J(:,1:3)),[],1));
    if isempty(r.offsets),r.offsets=v;else,r.offsets(end+1)=v;end
  end
end
function level=LOCAL_switch_level(cells,names,density,prop,model,config,s,N,Y,J,order,out,tag)
  % Input: one fixed field, source and line rules, kernel table. Output: source integrals.
  tt=tic;pieces=struct([]);[x,w]=LOCAL_switch_gauss(order);x=model.X_L+(x+1)*(model.X_R-model.X_L)/2;w=w*(model.X_R-model.X_L)/2;
  for t=1:3
    cm=cells{t};ns=N;if ns==0,ns=cm.i9_ntot;end
    curve=LOCAL_curve(cm.i9_shape,cm.i9_arg,ns);
    if t==1
      eta=LOCAL_interp_density_map(density,ns);
    else
      G=prop.Gminus;P=prop.Pminus;c=prop.cminus;if t==3,G=prop.Gplus;P=prop.Pplus;c=prop.cplus;end
      states=complex(zeros(size(G,1),config.evaluation.lead_cells+1));
      for n=1:size(states,2),states(:,n)=G*c;c=P*c;end
      eta=LOCAL_interp_density_map([cm.H_L,cm.H_R],ns)*states;
    end
    tau=eta(1:ns,:);zeta=eta(ns+1:end,:);coeff=zeros(ns,6);coeff=complex(coeff);
    for first=1:s.source_block:ns
      ids=first:min(first+s.source_block-1,ns);yy=x-curve.x(ids).';v=interp1(Y,J,yy(:),'spline');
      v=reshape(v,order,numel(ids),6);nx=curve.nx(ids).';ny=curve.ny(ids).';
      a0=-(v(:,:,2).*nx+v(:,:,3).*ny)/s.line_length_scale;b0=-v(:,:,1)/s.line_length_scale;
      a1=-(v(:,:,5).*nx+v(:,:,6).*ny);b1=-v(:,:,3);
      coeff(ids,:)=[sum(w.*abs(a0).^2,1).',sum(w.*abs(b0).^2,1).',sum(w.*conj(a0).*b0,1).', ...
        sum(w.*abs(a1).^2,1).',sum(w.*abs(b1).^2,1).',sum(w.*conj(a1).*b1,1).'];
    end
    V=real(coeff(:,1)).*abs(tau).^2+real(coeff(:,2)).*abs(zeta).^2+2*real(coeff(:,3).*conj(tau).*zeta);
    D=real(coeff(:,4)).*abs(tau).^2+real(coeff(:,5)).*abs(zeta).^2+2*real(coeff(:,6).*conj(tau).*zeta);
    assert(min([V(:);D(:)])>=0,'switch:Square','Negative integrated jump square.');
    [vv,vt,vr]=LOCAL_source_tail(V,t>1);[dd,dt,dr]=LOCAL_source_tail(D,t>1);
    [sl0,~,~]=LOCAL_source_tail(real(coeff(:,2)).*abs(zeta).^2,t>1);[sl1,~,~]=LOCAL_source_tail(real(coeff(:,5)).*abs(zeta).^2,t>1);
    [dl0,~,~]=LOCAL_source_tail(real(coeff(:,1)).*abs(tau).^2,t>1);[dl1,~,~]=LOCAL_source_tail(real(coeff(:,4)).*abs(tau).^2,t>1);
    es=sqrt(vv+dd);sl=sqrt(sl0+sl1);dl=sqrt(dl0+dl1);integral=sum(curve.weights.*es);
    item=struct('piece',[names{t},'_background'],'source_nodes',ns,'integral',integral, ...
      'single_layer_integral',sum(curve.weights.*sl),'double_layer_integral',sum(curve.weights.*dl), ...
      'finite_integral',sum(curve.weights.*sqrt(max(0,vv+dd-vt-dt))), ...
      'value_tail_weighted_square',sum(curve.weights.*vt),'normal_tail_weighted_square',sum(curve.weights.*dt), ...
      'value_tail_ratio_range',[min(vr),max(vr)],'normal_tail_ratio_range',[min(dr),max(dr)], ...
      'maximum_e_s',max(es),'cells',size(eta,2)-(t>1),'tail_certified',false);
    if t==1,pieces=item;else,pieces(t)=item;end
    f=fopen(fullfile(out,sprintf('%s-%s-sources.csv',tag,names{t})),'w');cl=onCleanup(@()fclose(f));
    fprintf(f,'t,x,y,weight,e_combined,e_single,e_double,value_tail_square,normal_tail_square\n');
    fprintf(f,'%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g\n',[curve.t,curve.x,curve.y,curve.weights,es,sl,dl,vt,dt].');clear cl
  end
  level=struct('source_setting',N,'line_order',order,'kernel_nodes',numel(Y),'pieces',pieces, ...
    'Q_sw',s.C_line*sum([pieces.integral]),'Q_sw_separate_layers',s.C_line*sum([pieces.single_layer_integral]+[pieces.double_layer_integral]),'seconds',toc(tt));
  fprintf('SWITCH %s Q %.17g (%.2fs)\n',tag,level.Q_sw,level.seconds);
end
function [sumv,tail,ratio]=LOCAL_source_tail(v,islead)
  % Input: each source's cell squares. Output: prefix plus observed-ratio tail.
  if ~islead,sumv=v;tail=zeros(size(v));ratio=zeros(size(v));return;end
  ratio=v(:,end)./max(realmin,v(:,end-1));
  assert(all(isfinite(ratio)&ratio>=0&ratio<1),'switch:Tail','Observed source-wise geometric tail ratio is unavailable.');
  tail=v(:,end)./(1-ratio);sumv=sum(v(:,1:end-1),2)+tail;
end
function [x,w]=LOCAL_switch_gauss(n)
  % Input: order. Output: Gauss-Legendre rule on [-1,1].
  j=(1:n-1)';b=j./sqrt(4*j.^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));[x,id]=sort(diag(D));w=2*V(1,id)'.^2;
end
function LOCAL_jump_csv(path,Y,J)
  % Input: direct branch jump table. Output: real/imaginary scalar CSV.
  f=fopen(path,'w');cl=onCleanup(@()fclose(f));fprintf(f,'Y,G_re,G_im,Gx_re,Gx_im,Gy_re,Gy_im,Hxx_re,Hxx_im,Hxy_re,Hxy_im,Hyy_re,Hyy_im\n');
  A=zeros(numel(Y),13);A(:,1)=Y;A(:,2:2:end)=real(J);A(:,3:2:end)=imag(J);fprintf(f,[repmat('%.17g,',1,12),'%.17g\n'],A.');
end
function rows=LOCAL_codepath(cm,density,q,model,s)
  % Input: fixed center field and native nodes. Output: actual full-field jump checks.
  N=cm.i9_ntot;z=LOCAL_curve('star',model.star_scale,N);rows=struct([]);
  for j=[31,87,173]
    sw=mod(z.y,model.d)-model.d/2;sep=abs(sw-sw(j));sep(j)=Inf;assert(min(sep)>1e-9,'switch:Coincident','Selected source shares a switch line.');
    tx=.45;ty=sw(j);Y=tx-z.x(j);J=switch_jumps(Y,cm.i9_pars,cm.i9_proxy,s.kernel_block);
    if z.y(j)>=0,J=exp(-1i*model.beta*model.d)*J;end
    tau=density(j);zeta=density(N+j);pred=z.weights(j)*(-tau*(z.nx(j)*J(2)+z.ny(j)*J(3))-zeta*J(1));
    pred_y=z.weights(j)*(-tau*(z.nx(j)*J(5)+z.ny(j)*J(6))-zeta*J(3));
    for method={'fmm','direct'}
      LOCAL_backend('set',struct('method',method{1},'tolerance',1e-12));
      for e=s.offsets
        target=[tx,tx;ty-e,ty+e];
        [u,g]=LOCAL_center_field(cm,density,q,cm.channels.beta_m(:),cm.channels.gamma_m(:),model,target,N);
        h=diff(target(2,:))/2;raw=u(2)-u(1);corrected=raw-h*sum(g(2,:));err=abs(corrected-pred);
        bound=s.codepath_roundoff_factor*eps*max([1,abs(u),abs(g(:).')]);
        item=struct('node',j,'method',method{1},'offset',e,'source',[z.x(j),z.y(j)],'target',[tx,ty], ...
          'nearest_other_line',min(sep),'predicted',[real(pred),imag(pred)],'raw',[real(raw),imag(raw)], ...
          'smooth_corrected',[real(corrected),imag(corrected)],'difference',err,'roundoff_envelope',bound, ...
          'predicted_y',[real(pred_y),imag(pred_y)],'raw_y',[real(g(2,2)-g(2,1)),imag(g(2,2)-g(2,1))], ...
          'pass',err<=bound);
        if isempty(rows),rows=item;else,rows(end+1)=item;end
      end
    end
  end
  LOCAL_backend('set',struct('method','fmm','tolerance',1e-12));
end
function [mat,ca]=LOCAL_budget_material(center,negative,positive,density,q,prop,model,config,N)
  ca=LOCAL_center_action(center,density,q,sqrt(model.rho_center)*model.khat,model,N);
  na=LOCAL_material_action(negative,'trilobe',model.a_negative,sqrt(model.rho_lead)*model.khat,model,N);
  pa=LOCAL_material_action(positive,'trilobe',model.a_positive,sqrt(model.rho_lead)*model.khat,model,N);
  jn=LOCAL_series(na,prop.Gminus,prop.Pminus,prop.cminus,config.evaluation.lead_cells);
  jp=LOCAL_series(pa,prop.Gplus,prop.Pplus,prop.cplus,config.evaluation.lead_cells);
  mat=struct('center',rmfield(ca.jump,{'value','normal'}),'negative',rmfield(jn,{'cells','next','next_coordinate'}), ...
    'positive',rmfield(jp,{'cells','next','next_coordinate'}));
end
function y=LOCAL_wall_sum(w)
  y=w.left.value_squared+w.left.normal_squared+w.right.value_squared+w.right.normal_squared+ ...
    w.negative.value_squared+w.negative.normal_squared+w.positive.value_squared+w.positive.normal_squared;
end
function a=LOCAL_subwalls(a,step)
  nt=a.nodes; fields=fieldnames(a);
  for j=1:numel(fields), x=a.(fields{j}); if isnumeric(x)&&size(x,1)==nt,a.(fields{j})=x(1:step:end,:);end,end
  a.nodes=nt/step;
end
function LOCAL_wall_samples(path,w,y)
  f=fopen(path,'w'); fprintf(f,'y,left_value_abs,left_normal_abs,right_value_abs,right_normal_abs\n');
  fprintf(f,'%.17g,%.17g,%.17g,%.17g,%.17g\n',[y,abs(w.left.value),abs(w.left.normal),abs(w.right.value),abs(w.right.normal)].'); fclose(f);
end
function mass=LOCAL_disks(center,negative,positive,density,q,prop,model,Nsource,out)
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
  % Add the original disk as a separate one-disk control.
  c=model.disk_center;R=model.disk_radius;
  v=LOCAL_piece_field(center,density,q,model,c,false,Nsource);
  kR=model.khat*R; original5=pi*R^2*(besselj(0,kR)^2+besselj(1,kR)^2)*abs(v)^2;
  originalquad=LOCAL_mass_diagnostic(center,density,q,center.channels.beta_m(:),center.channels.gamma_m(:),model,32,64,Nsource,.5);
  for j=1:size(selected,1)
    ci=selected(j,1);cm=cells{ci};den=[cm.H_L,cm.H_R]*states{ci};R=selected(j,4);rho=selected(j,5); c=selected(j,2:3).'; k=model.khat*sqrt(rho);r0=.8*R;
    modes=-4:4; wm=.5*R^2*(besselj(abs(modes),k*R).^2-besselj(abs(modes)-1,k*R).*besselj(abs(modes)+1,k*R));
    for nt=[64,128]
      th=(0:nt-1)*2*pi/nt;targets=c+r0*[cos(th);sin(th)];
      val=LOCAL_piece_field(cm,den,states{ci},model,targets,rho>1,Nsource);
      b=(val*exp(-1i*th.'*modes))/nt;coeff=b./besselj(abs(modes),k*r0);
      q6=2*pi*rho*sum(abs(coeff).^2.*wm);
      selected(j,8+(nt==128)+1)=q6;
    end
  end
  f=fopen(fullfile(out,'disks.csv'),'w');fprintf(f,'cell,local_x,y,R,rho,u_real,u_imag,Q5_mass,Q6_mass_64,Q6_mass_128\n');
  fprintf(f,'%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g\n',selected.');fclose(f);
  mass=struct('reference_U',.12342045035909599,'original_disk_Q5',sqrt(original5), ...
    'original_disk_quadrature',originalquad.quadrature_norm,'single_best_Q5',sqrt(max(candidates(:,8))), ...
    'multi_Q5',sqrt(sum(selected(:,8))),'multi_Q6_64',sqrt(sum(selected(:,9))), ...
    'multi_Q6_128',sqrt(sum(selected(:,10))),'disk_count',size(selected,1),'modes',modes,'selected',selected);
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

function LOCAL_part(out,name)
  f=fopen(fullfile(out,'part.txt'),'w');assert(f>=0);fprintf(f,'%s',name);fclose(f);
  fprintf('PART %s\n',name);
end
function LOCAL_json(path,data)
  f=fopen(path,'w');assert(f>=0);cleanup=onCleanup(@() fclose(f));fprintf(f,'%s\n',jsonencode(data));
end
function LOCAL_components_csv(path,c)
  names={'center','negative_material','positive_material','left_junction','right_junction','negative_walls','positive_walls'};
  f=fopen(path,'w');assert(f>=0);cleanup=onCleanup(@() fclose(f));
  fprintf(f,'component,value_squared,normal_squared,finite_value_squared,finite_normal_squared,tail_value_squared_candidate,tail_normal_squared_candidate\n');
  for j=1:7
    x=c.(names{j});v=NaN(1,4);fields={'finite_value_squared','finite_normal_squared','tail_value_squared_candidate','tail_normal_squared_candidate'};
    for k=1:4,if isfield(x,fields{k}),v(k)=x.(fields{k});end,end
    fprintf(f,'%s,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g\n',names{j},x.value_squared,x.normal_squared,v);
  end
end
%% ==================== Independent physical field ====================
% The I9.1 lead pencils and density coordinates are preserved exactly.
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
    'phase',phase,'x',x,'interpretation','horizontal seam of the evaluated fixed MFS field; squares included');
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
    [C,~]=pilot_geometry(N,arg,model.R,model); C0=C;
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

function out = LOCAL_material_action(cellmap,flag_geom,shape_arg,kint,model,N)
  if strcmp(flag_geom,'trilobe')
    config = pilot_config();
    [C,curvelen] = pilot_geometry(N,shape_arg,config.model.R,config.model);
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
    'B',B, ...
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
    'Bq',Bq,'density_scale',scale, ...
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
  config = pilot_config(); batch = config.evaluation.wall_batch;
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
  config = pilot_config(); batch = config.evaluation.mass_batch;
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

function p=LOCAL_prime(cells,names,density,prop,model,config,s,Y,J,out)
  % Input: fixed field and analytic branch-jump table. Output: S-prime budget.
  p=struct('status','STARTED');t=tic;sp=s.prime;mu=model.khat^2;
  m=(-sp.fourier_cut:sp.fourier_cut)';bm=model.beta+2*pi*m/model.d;
  S=sum(1./(4*(sp.alpha+bm.^2).^(3/2)))/model.d;
  b=abs(model.beta);a=2*pi/model.d;
  tail=1/(4*model.d*a*(a*sp.fourier_cut-b)^2);
  lambda0=min(abs(bm))^2/max([model.rho_center,model.rho_lead,model.rho_exterior]);
  factor=sp.alpha/(sqrt(model.rho_exterior)*(lambda0+mu))+sqrt(max([model.rho_center,model.rho_lead,model.rho_exterior]));
  Cpt=sqrt(S+tail)*factor;
  p.point_constant=struct('alpha',sp.alpha,'lambda0',lambda0,'mu',mu,'fourier_cut',sp.fourier_cut, ...
    'S_partial',S,'S_tail_upper',tail,'C_partial',sqrt(S)*factor,'C_pt',Cpt, ...
    'manager_value',sp.C_pt_reference,'difference',Cpt-sp.C_pt_reference);
  p.identity=LOCAL_prime_identity(cells{1},density,model,s);
  LOCAL_json(fullfile(out,'prime.json'),p);
  assert(all([p.identity.pass]),'switch:PrimeIdentity','Integration-by-parts check exceeds branch-rounding envelope.');
  [x,w]=LOCAL_switch_gauss(s.check_order);x=model.X_L+(x+1)*(model.X_R-model.X_L)/2;w=w*(model.X_R-model.X_L)/2;
  p.levels=struct([]);
  for N=s.source_counts
    items=struct([]);tt=tic;
    for it=1:3
      cm=cells{it};ns=N;if ns==0,ns=cm.i9_ntot;end
      curve=LOCAL_curve(cm.i9_shape,cm.i9_arg,ns);
      if it==1
        eta=LOCAL_interp_density_map(density,ns);
      else
        G=prop.Gminus;P=prop.Pminus;c=prop.cminus;if it==3,G=prop.Gplus;P=prop.Pplus;c=prop.cplus;end
        states=complex(zeros(size(G,1),config.evaluation.lead_cells+1));
        for n=1:size(states,2),states(:,n)=G*c;c=P*c;end
        eta=LOCAL_interp_density_map([cm.H_L,cm.H_R],ns)*states;
      end
      tau=eta(1:ns,:);zeta=eta(ns+1:end,:);coef=complex(zeros(ns,3));
      for first=1:s.source_block:ns
        ids=first:min(first+s.source_block-1,ns);yy=x-curve.x(ids).';
        v=reshape(interp1(Y,J,yy(:),'spline'),s.check_order,numel(ids),6);
        nx=curve.nx(ids).';ny=curve.ny(ids).';
        a0=ny*mu.*v(:,:,1);b0=-v(:,:,3);
        a1=nx.*v(:,:,3)-ny.*v(:,:,2);
        j0=-(nx.*v(:,:,2)+ny.*v(:,:,3));b=-v(:,:,1);
        coef(ids,:)=[sum(w.*(abs(a0).^2+abs(a1).^2+abs(j0).^2),1).', ...
          sum(w.*(abs(b0).^2+abs(b).^2),1).',sum(w.*(conj(a0).*b0+conj(j0).*b),1).'];
      end
      squares=real(coef(:,1)).*abs(tau).^2+real(coef(:,2)).*abs(zeta).^2+2*real(coef(:,3).*conj(tau).*zeta);
      assert(min(squares(:))>=0,'switch:PrimeSquare','Negative line square.');
      [ss,st,sr]=LOCAL_source_tail(squares,it>1);es=sqrt(ss);
      % Endpoints use direct branch evaluation, independent of interpolation.
      ja=switch_jumps(model.X_L-curve.x,cm.i9_pars,cm.i9_proxy,s.kernel_block);
      jb=switch_jumps(model.X_R-curve.x,cm.i9_pars,cm.i9_proxy,s.kernel_block);
      ea=curve.ny.*ja(:,2)-curve.nx.*ja(:,3);eb=curve.ny.*jb(:,2)-curve.nx.*jb(:,3);
      ends=(abs(ea)+abs(eb)).*abs(tau);
      % Endpoint estimates sum amplitudes over cells, unlike the line squares.
      [se,et,er]=LOCAL_source_tail(ends,it>1);
      il=sum(curve.weights.*es);ie=sum(curve.weights.*se);
      item=struct('piece',[names{it},'_background'],'source_nodes',ns,'line_integral',il,'endpoint_integral',ie, ...
        'Q_line',s.C_line*il,'Q_end',Cpt*ie,'Q_prime',s.C_line*il+Cpt*ie, ...
        'line_tail_weighted_square',sum(curve.weights.*st),'endpoint_tail_integral',sum(curve.weights.*et), ...
        'line_tail_ratio_range',[min(sr),max(sr)],'endpoint_tail_ratio_range',[min(er),max(er)]);
      if isempty(items),items=item;else,items(end+1)=item;end
      f=fopen(fullfile(out,sprintf('prime-n%d-%s-sources.csv',N,names{it})),'w');cl=onCleanup(@()fclose(f));
      fprintf(f,'t,weight,e_prime,endpoint_amplitude_sum,line_tail_square,endpoint_tail_amplitude\n');
      fprintf(f,'%.17g,%.17g,%.17g,%.17g,%.17g,%.17g\n',[curve.t,curve.weights,es,se,st,et].');clear cl
    end
    level=struct('source_setting',N,'pieces',items,'Q_line',sum([items.Q_line]),'Q_end',sum([items.Q_end]), ...
      'Q_prime',sum([items.Q_prime]),'seconds',toc(tt));
    if isempty(p.levels),p.levels=level;else,p.levels(end+1)=level;end
    fprintf('PRIME n%d line %.17g endpoint %.17g total %.17g\n',N,level.Q_line,level.Q_end,level.Q_prime);
    LOCAL_json(fullfile(out,'prime.json'),p);
  end
  last=p.levels(end);prev=p.levels(end-1);
  p.source_relative=abs(last.Q_prime/prev.Q_prime-1);
  p.source_piece_relative=abs([last.pieces.Q_prime]./[prev.pieces.Q_prime]-1);
  p.line_source_relative=abs(last.Q_line/prev.Q_line-1);p.endpoint_source_relative=abs(last.Q_end/prev.Q_end-1);
  allow=s.radius_target*s.U/(2*mu+s.radius_target);
  p.budget=struct('Q_grp',s.Q_grp,'Q_line',last.Q_line,'Q_end',last.Q_end,'Q_prime',last.Q_prime, ...
    'Q_total',s.Q_grp+last.Q_prime,'Q_allow',allow,'margin',allow/(s.Q_grp+last.Q_prime), ...
    'holds',allow>s.Q_grp+last.Q_prime);
  p.seconds=toc(t);p.status='COMPUTED_PENDING_REFINEMENT';LOCAL_json(fullfile(out,'prime.json'),p);
  assert(max([p.source_relative,p.source_piece_relative])<sp.source_tolerance,'switch:PrimeRefinement','S-prime source refinement did not settle.');
  p.status='COMPLETE';LOCAL_json(fullfile(out,'prime.json'),p);
end

function rows=LOCAL_prime_identity(cm,density,model,s)
  % Input: original native field. Output: branchwise and jumpwise identity checks.
  curve=LOCAL_curve(cm.i9_shape,cm.i9_arg,cm.i9_ntot);[x,w]=LOCAL_switch_gauss(s.prime.identity_order);
  x=model.X_L+(x+1)*(model.X_R-model.X_L)/2;w=w*(model.X_R-model.X_L)/2;ends=[model.X_L;model.X_R];rows=struct([]);
  for j=[31,87,173]
    tau=density(j);zeta=density(cm.i9_ntot+j);nx=curve.nx(j);ny=curve.ny(j);
    [jump,lower,upper]=switch_jumps(x-curve.x(j),cm.i9_pars,cm.i9_proxy,s.kernel_block);
    [ej,el,eu]=switch_jumps(ends-curve.x(j),cm.i9_pars,cm.i9_proxy,s.kernel_block);
    phase=1;if curve.y(j)>=0,phase=exp(-1i*model.beta*model.d);end
    h=mod(curve.y(j),model.d)-model.d/2;
    zb=exp(-1i*model.beta*h)*cos(x);zxb=-exp(-1i*model.beta*h)*sin(x);ezb=exp(-1i*model.beta*h)*cos(ends);
    tables={lower,upper,jump};endtables={el,eu,ej};terms=complex(zeros(3,4));scales=zeros(3,1);pointwise=zeros(3,1);
    for k=1:3
      v=phase*tables{k};ev=phase*endtables{k};
      j1=-tau*(nx*v(:,5)+ny*v(:,6))-zeta*v(:,3);
      a0=tau*ny*model.khat^2*v(:,1)-zeta*v(:,3);
      a1=tau*(nx*v(:,3)-ny*v(:,2));da1=tau*(nx*v(:,5)-ny*v(:,4));
      E=tau*(ny*ev(:,2)-nx*ev(:,3));edge=E.*ezb;
      terms(k,:)=[sum(w.*j1.*zb),sum(w.*a0.*zb),sum(w.*a1.*zxb),edge(2)-edge(1)];
      scales(k)=sum(w.*(abs(j1.*zb)+abs(a0.*zb)+abs(a1.*zxb)))+sum(abs(edge));
      pointwise(k)=max(abs(j1-a0+da1));
    end
    residual=terms(:,1)-sum(terms(:,2:4),2);scale=sum(scales(1:2));bound=s.prime.identity_roundoff_factor*eps*scale;
    item=struct('node',j,'test_function','exp(i beta y) cos(x)','quadrature_order',s.prime.identity_order, ...
      'term_rows_lower_upper_jump_real',real(terms),'term_rows_lower_upper_jump_imag',imag(terms), ...
      'absolute_residual_lower_upper_jump',abs(residual).','absolute_term_scale_lower_upper_jump',scales.', ...
      'jump_relative_to_jump_terms',abs(residual(3))/scales(3),'jump_relative_to_branch_terms',abs(residual(3))/scale, ...
      'pointwise_residual_lower_upper_jump',pointwise.','roundoff_envelope',bound,'pass',all(abs(residual)<bound));
    if isempty(rows),rows=item;else,rows(end+1)=item;end
  end
end
