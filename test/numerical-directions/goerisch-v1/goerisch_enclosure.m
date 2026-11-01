function result=goerisch_enclosure(input_dir,output_dir,degree,trial_kind)
  % Goerisch enclosure: one-vector Lehmann-Goerisch ordinary arithmetic.
  % Input
  %   input_dir: read-only I9.6 (implementation experiment 9.6) run-03.
  %   output_dir: new directory; degree: Raviart-Thomas degree 1, 2, or 3.
  %   trial_kind: R (reconstructed) or D (direct tapered finite element field).
  % Output
  %   result: scalar Gram entries, enclosure, checks, and timings in JSON.
  % Geometry/Piola conventions follow eq_temple_i95.m; oriented material
  % strips follow refine_i102.m. Trial assembly is copied in goerisch_trial.m.
  started=tic; maxNumCompThreads(2);
  assert(ismember(degree,1:3)&&ismember(trial_kind,{'R','D'}));
  assert(~isfolder(output_dir)); mkdir(output_dir);
  cfg=struct('degree',degree,'trial',trial_kind,'K',13,'gamma',1,'beta',.5, ...
    'orders',[16,24],'band_orders',[10,16],'block',48,'theta_reference',2.428728699465642, ...
    'mu_bie',2.428728670022710,'mu0',2.428729247773311, ...
    'alpha_minus',1.3174^2,'alpha_plus',2.1875^2,'quadrature_fraction',.01);
  cfg.mu=cfg.alpha_minus+cfg.gamma; cfg.nu=cfg.alpha_plus+cfg.gamma;
  LOCAL_json(fullfile(output_dir,'config.json'),cfg);
  if strcmp(trial_kind,'R')
    [norms,trial]=goerisch_trial(input_dir,fullfile(output_dir,'normalization'),'control');
    theta_check=abs(norms.theta-cfg.theta_reference)/cfg.theta_reference;
    assert(theta_check<1e-12,'goerisch:Theta','Copied reconstruction differs from reference.');
    [tail0,tail_upper]=LOCAL_tail(trial,norms.denominator,cfg.K);
    assert(tail_upper<1e-10,'goerisch:Tail','Chosen box is too short.');
    mass=norms.denominator; energy=norms.numerator_identity;
  else
    norms=struct(); trial=[]; theta_check=NaN; tail0=0; tail_upper=0; mass=0; energy=0;
  end
  raw=load(fullfile(input_dir,'native.mat'),'native'); native=raw.native;clear raw
  native_trace=struct();
  if strcmp(trial_kind,'D')
    native_trace=LOCAL_native_trace(native,cfg);
    LOCAL_json(fullfile(output_dir,'native_trace.json'),native_trace);
    assert(native_trace.cell_relative<1e-10&&native_trace.phase_relative<1e-10, ...
      'goerisch:TrialTrace','Native direct trial has inconsistent traces.');
  end
  names={'left','center','right'}; packs=cell(1,3); info=struct([]);
  [Dinv,basischeck]=LOCAL_dual(degree);
  for t=1:3
    timer=tic; T=native.templates.(names{t}); T.xy(:,1)=T.xy(:,1)-T.cell;
    cells=-cfg.K:-1; if t==2,cells=0;elseif t==3,cells=1:cfg.K;end
    U=complex(zeros(size(T.xy,1),numel(cells)));
    for j=1:numel(cells),U(:,j)=native.cells([native.cells.index]==cells(j)).coef;end
    G=LOCAL_geometry(T,U,cells,cfg,degree);
    fprintf('ASSEMBLE %s RT%d: %d triangles, %d edge unknowns, %d cells\n',names{t},degree,G.nt,G.nedge,numel(cells));
    [H,b,scalars]=LOCAL_forms(G,T,trial,cfg,Dinv,cfg.orders(1),cfg.band_orders(1));
    assembly=toc(timer); timer=tic;
    pack=LOCAL_condense(H,b,G);
    pack.H=H;pack.b=b;pack.G=G;pack.T=T;pack.scalars=scalars;
    packs{t}=pack;
    if strcmp(trial_kind,'D'),mass=mass+sum(scalars.mass);energy=energy+sum(scalars.energy);end
    item=struct('template',names{t},'triangles',G.nt,'edge_unknowns',G.nedge, ...
      'wall_unknowns',numel(G.left),'assembly_seconds',assembly,'condense_seconds',toc(timer), ...
      'band_area',scalars.band_area,'band_absolute_area',scalars.band_absolute_area, ...
      'source_quadrature',scalars.source_quadrature,'basis_check',basischeck,'cell_solve_residual',pack.solve_residual);
    info=[info,item]; %#ok<AGROW>
    LOCAL_json(fullfile(output_dir,['template_',names{t},'.json']),item);
    fprintf('CONDENSE %s %.1fs, total %.1fs\n',names{t},item.condense_seconds,toc(started));
    clear G T U H b pack
  end
  clear native
  timer=tic; nwall=numel(packs{1}.G.left); nc=2*cfg.K+1;
  assert(all(cellfun(@(p)numel(p.G.left)==nwall,packs)));
  AG=sparse((nc+1)*nwall,(nc+1)*nwall); rhs=complex(zeros(size(AG,1),1));
  for c=-cfg.K:cfg.K
    t=1+(c==0)+2*(c>0); pack=packs{t}; j=find(pack.G.cells==c);
    ports=(c+cfg.K)*nwall+(1:2*nwall);
    AG(ports,ports)=AG(ports,ports)+pack.S;
    rhs(ports)=rhs(ports)+pack.port_rhs(:,j);
  end
  free=nwall+(1:(nc-1)*nwall); z=complex(zeros(size(rhs)));
  Af=(AG(free,free)+AG(free,free)')/2; z(free)=Af\rhs(free);
  global_residual=norm(Af*z(free)-rhs(free))/norm(rhs(free));
  assert(global_residual<1e-9,'goerisch:Solve','Global flux solve failed.');
  global_seconds=toc(timer); clear AG Af rhs
  quadratic=0; quadratic_check=0; mass_check=0;energy_check=0; trace_error=0;
  for t=1:3
    timer=tic; pack=packs{t}; G=pack.G; nb=G.nd; nt=G.nt; ncell=numel(G.cells);
    ye=complex(zeros(G.nedge,ncell));
    for j=1:ncell
      ports=(G.cells(j)+cfg.K)*nwall+(1:2*nwall);
      ye(G.port,j)=z(ports); ye(G.inner,j)=pack.response(:,j)-pack.extension*z(ports);
    end
    local=complex(zeros(nb,ncell,nt));
    for j=1:ncell
      ee=G.phase.*reshape(ye(G.map(:),j),nt,G.ne);
      ii=-reshape(pagemtimes(pack.Y,reshape(ee.',G.ne,1,nt)),G.ni,nt)-reshape(pack.r(:,j,:),G.ni,nt);
      local(:,j,:)=reshape([ee,reshape(ii,G.ni,nt).'].',nb,1,nt);
    end
    quadratic=quadratic+LOCAL_quadratic(pack.H,pack.b,local);
    trace_error=max(trace_error,LOCAL_trace(G,local,degree,Dinv));
    [HC,bc,sc]=LOCAL_forms(G,pack.T,trial,cfg,Dinv,cfg.orders(2),cfg.band_orders(2));
    quadratic_check=quadratic_check+LOCAL_quadratic(HC,bc,local);
    mass_check=mass_check+sum(sc.mass); energy_check=energy_check+sum(sc.energy);
    info(t).check_seconds=toc(timer);
    info(t).source_quadrature_check=sc.source_quadrature;
    LOCAL_json(fullfile(output_dir,['template_',names{t},'.json']),info(t));
    fprintf('CHECK %s %.1fs, total %.1fs\n',names{t},toc(timer),toc(started));
    clear HC bc sc local ye pack
    packs{t}=[];
  end
  if strcmp(trial_kind,'R'),mass_check=mass; energy_check=energy;end
  q=1+energy/mass;
  % Whole mass includes the exterior contribution for zero exterior flux.
  % Only inclusions outside the original 33-cell source box were omitted
  % from the theta mass; include their rho<=17 upper allowance here.
  tail_allowance=0;
  if strcmp(trial_kind,'R'),tail_allowance=16*norms.tail_norm;end
  J=(mass+quadratic+tail_allowance)/mass;
  Jcheck=(mass_check+quadratic_check+tail_allowance)/mass_check;
  qcheck=1+energy_check/mass_check; variance=q*J-1;
  b2=[q-2*cfg.mu+cfg.mu^2*J,q-2*cfg.nu+cfg.nu^2*J];
  kappa=[(1-cfg.mu*J)/b2(1),(1-cfg.nu*J)/b2(2)];
  lower=(q-cfg.nu)/(1-cfg.nu*J)-1;upper=(q-cfg.mu)/(1-cfg.mu*J)-1;
  width=(cfg.nu-cfg.mu)*variance/((1-cfg.mu*J)*(cfg.nu*J-1));
  quadrature_ratio=q*abs(Jcheck-J)/variance;
  checks=struct('theta_relative_difference',theta_check,'variance_positive',variance>0, ...
    'contains_reference',lower<=cfg.mu_bie&&cfg.mu_bie<=upper, ...
    'sign_conditions',all(b2>0)&&kappa(1)>1/(cfg.nu-cfg.mu)&&kappa(2)<-1/(cfg.nu-cfg.mu), ...
    'J_quadrature_change',Jcheck-J,'scaled_quadrature_fraction',quadrature_ratio, ...
    'quadrature_pass',quadrature_ratio<cfg.quadrature_fraction, ...
    'normal_trace_error',trace_error,'global_solve_residual',global_residual, ...
    'width_formula_difference',(upper-lower)-width);
  result=struct('config',cfg,'q',q,'theta',q-1,'theta_minus_mu0',q-1-cfg.mu0, ...
    'mass',mass,'energy',energy,'mass_check',mass_check,'energy_check',energy_check, ...
    'q_check',qcheck,'J',J,'J_check',Jcheck,'qJ_minus_one',variance,'kappa',kappa, ...
    'enclosure',[lower,upper],'width',width,'tail_relative_upper',tail_upper, ...
    'checks',checks,'native_trace',native_trace,'templates',info,'global_solve_seconds',global_seconds,'wall_seconds',toc(started));
  LOCAL_json(fullfile(output_dir,'result.json'),result); disp(result);
  assert(checks.variance_positive&&checks.contains_reference&&checks.sign_conditions, ...
    'goerisch:Enclosure','Invalid enclosure: inspect saved result.');
  assert(checks.quadrature_pass,'goerisch:Quadrature','Quadrature change is too large.');
end

function check=LOCAL_native_trace(native,cfg)
  names={'left','center','right'}; left=cell(1,2*cfg.K+1);right=left;
  jump=0;phase_jump=0;scale=0;
  for c=-cfg.K:cfg.K
    t=1+(c==0)+2*(c>0);T=native.templates.(names{t});
    xy=T.xy;xy(:,1)=xy(:,1)-T.cell;
    u=native.cells([native.cells.index]==c).coef;scale=max(scale,max(abs(u)));
    l=find(abs(xy(:,1)+.5)<1e-11);r=find(abs(xy(:,1)-.5)<1e-11);
    [~,s]=sort(xy(l,2));l=l(s);[~,s]=sort(xy(r,2));r=r(s);
    left{c+cfg.K+1}=u(l);right{c+cfg.K+1}=u(r);
    b=find(abs(xy(:,2)+.5)<1e-11);a=find(abs(xy(:,2)-.5)<1e-11);
    [~,s]=sort(xy(b,1));b=b(s);[~,s]=sort(xy(a,1));a=a(s);
    phase_jump=max(phase_jump,max(abs(u(a)-exp(1i*cfg.beta)*u(b))));
  end
  for j=1:numel(left)-1,jump=max(jump,max(abs(right{j}-left{j+1})));end
  check=struct('cell_absolute',jump,'phase_absolute',phase_jump,'scale',scale, ...
    'cell_relative',jump/scale,'phase_relative',phase_jump/scale);
end

function G=LOCAL_geometry(T,U,cells,cfg,k)
  tr=T.tri6(:,1:3); nt=size(tr,1); xy=T.xy;
  [edges,~,ids]=unique(sort([tr(:,[1,2]);tr(:,[2,3]);tr(:,[3,1])],2),'rows');
  ids=reshape(ids,nt,3); starts=[tr(:,1);tr(:,2);tr(:,3)]; ends=[tr(:,2);tr(:,3);tr(:,1)];
  pa=xy(starts,:);pb=xy(ends,:);signs=ones(size(starts));
  signs(pa(:,1)>pb(:,1)|(pa(:,1)==pb(:,1)&pa(:,2)>pb(:,2)))=-1;
  signs=reshape(signs,nt,3); mid=(xy(edges(:,1),:)+xy(edges(:,2),:))/2;
  top=find(abs(mid(:,2)-.5)<1e-11);bot=find(abs(mid(:,2)+.5)<1e-11);
  [~,a]=sort(mid(top,1));top=top(a);[~,a]=sort(mid(bot,1));bot=bot(a);
  assert(numel(top)==numel(bot)&&max(abs(mid(top,1)-mid(bot,1)))<1e-11);
  master=(1:size(edges,1))';master(top)=bot;ph=ones(size(master));ph(top)=exp(1i*cfg.beta);
  active=true(size(master));active(top)=false;pos=zeros(size(master));pos(active)=1:nnz(active);
  nr=k+1; ne=3*nr;nd=(k+1)*(k+3);ni=nd-ne;
  map=zeros(nt,ne);phase=complex(zeros(nt,ne));
  for e=1:3
    for m=0:k
      l=(e-1)*nr+m+1;map(:,l)=nr*(pos(master(ids(:,e)))-1)+m+1;
      phase(:,l)=signs(:,e).^(m+1).*ph(ids(:,e));
    end
  end
  left=find(abs(mid(:,1)+.5)<1e-11);right=find(abs(mid(:,1)-.5)<1e-11);
  [~,a]=sort(mid(left,2));left=left(a);[~,a]=sort(mid(right,2));right=right(a);
  assert(numel(left)==numel(right)&&max(abs(mid(left,2)-mid(right,2)))<1e-11);
  left=reshape((nr*(pos(left)-1)+(1:nr)).',[],1);right=reshape((nr*(pos(right)-1)+(1:nr)).',[],1);
  nedge=nnz(active)*nr;port=[left;right];inner=setdiff((1:nedge)',port);
  nodes=reshape(xy(T.tri6(:),:),nt,6,2);mx=LOCAL_poly(nodes(:,:,1));my=LOCAL_poly(nodes(:,:,2));
  mu=complex(zeros(nt,6,numel(cells)));
  for j=1:numel(cells),mu(:,:,j)=LOCAL_poly(reshape(U(T.tri6,j),nt,6));end
  G=struct('nt',nt,'nd',nd,'ne',ne,'ni',ni,'mx',mx,'my',my,'mu',mu,'cells',cells, ...
    'map',map,'phase',phase,'nedge',nedge,'left',left,'right',right,'port',port,'inner',inner, ...
    'edge_ids',ids,'signs',signs,'mid',mid,'top',top,'bot',bot,'edges',edges);
end

function [H,b,sc]=LOCAL_forms(G,T,trial,cfg,Dinv,order,band_order)
  [x,y,w]=LOCAL_duffy(order);[vx,vy,dv]=LOCAL_rt(x,y,cfg.degree);
  vx=vx*Dinv;vy=vy*Dinv;dv=dv*Dinv; nq=numel(w);nd=G.nd;nt=G.nt;nc=numel(G.cells);
  H=zeros(nd,nd,nt);b=complex(zeros(nd,nc,nt));mass=zeros(1,nc);energy=mass;
  for first=1:cfg.block:nt
    ids=first:min(first+cfg.block-1,nt);nb=numel(ids);
    xx=repmat(x,nb,1);yy=repmat(y,nb,1);ei=repelem(ids(:),nq);
    [PX,PY,J,det]=LOCAL_map(G.mx(ei,:),G.my(ei,:),xx,yy);
    vxx=repmat(vx,nb,1);vyy=repmat(vy,nb,1);dvv=repmat(dv,nb,1);
    px=(J(:,1).*vxx+J(:,2).*vyy)./det;py=(J(:,3).*vxx+J(:,4).*vyy)./det;
    W=repmat(w,nb,1).*det;rho=repelem(reshape(T.material(ids),[],1),nq);
    D=dvv./det;
    P=permute(reshape(px,nq,nb,nd),[3,1,2]);Q=permute(reshape(py,nq,nb,nd),[3,1,2]);
    DD=permute(reshape(D,nq,nb,nd),[3,1,2]);ww=reshape(W,1,nq,nb);
    H(:,:,ids)=pagemtimes(P.*ww,'none',P,'transpose')+pagemtimes(Q.*ww,'none',Q,'transpose') ...
      +pagemtimes(DD.*reshape(W./rho,1,nq,nb),'none',DD,'transpose');
    if strcmp(cfg.trial,'R')
      values=LOCAL_reconstructed(trial,PX,PY,G.cells);
    else
      [values,gx,gy]=LOCAL_direct(G,ei,xx,yy,PX,J,det,cfg);
      mass=mass+sum((W.*rho).*abs(values).^2,1);
      energy=energy+sum(W.*(abs(gx).^2+abs(gy).^2),1);
    end
    VV=permute(reshape(values,nq,nb,nc),[1,3,2]);
    b(:,:,ids)=pagemtimes(DD.*ww,VV);
  end
  source_info=struct();
  % Correct mesh material labels by an oriented strip to the true interface.
  band=LOCAL_band(G,T,band_order);
  for first=1:1024:numel(band.w)
    ids=first:min(first+1023,numel(band.w));ei=band.e(ids);xx=band.x(ids);yy=band.y(ids);
    [PX,~,J,det]=LOCAL_map(G.mx(ei,:),G.my(ei,:),xx,yy);
    [~,~,div]=LOCAL_rt(xx,yy,cfg.degree);div=(div*Dinv)./det;
    ww=band.w(ids)*(1/T.rho_in-1);
    for j=1:nd
      for l=j:nd
        d=accumarray(ei,ww.*div(:,j).*div(:,l),[nt,1]);
        H(j,l,:)=H(j,l,:)+reshape(d,1,1,nt);
        if l~=j,H(l,j,:)=H(l,j,:)+reshape(d,1,1,nt);end
      end
    end
    if strcmp(cfg.trial,'D')
      values=LOCAL_direct(G,ei,xx,yy,PX,J,det,cfg);
      mass=mass+sum((band.w(ids)*(T.rho_in-1)).*abs(values).^2,1);
    end
  end
  sc=struct('mass',mass,'energy',energy,'band_area',sum(band.w),'band_absolute_area',sum(abs(band.w)), ...
    'band_min_barycentric',band.min_barycentric,'source_quadrature',source_info);
end

function pack=LOCAL_condense(H,b,G)
  ne=G.ne; ni=G.ni; nt=G.nt; nc=numel(G.cells); ee=1:ne;ii=ne+(1:ni);
  Y=pagemldivide(H(ii,ii,:),H(ii,ee,:));r=pagemldivide(H(ii,ii,:),b(ii,:,:));
  S=H(ee,ee,:)-pagemtimes(H(ee,ii,:),Y);d=b(ee,:,:)-pagemtimes(H(ee,ii,:),r);
  ph=G.phase.';map=G.map.';
  V=conj(reshape(ph,ne,1,nt)).*S.*reshape(ph,1,ne,nt);
  I=repmat(reshape(map,ne,1,nt),1,ne,1);J=repmat(reshape(map,1,ne,nt),ne,1,1);
  A=sparse(I(:),J(:),V(:),G.nedge,G.nedge);A=(A+A')/2;
  rhs=complex(zeros(G.nedge,nc));
  for j=1:nc
    vals=-conj(ph).*reshape(d(:,j,:),ne,nt);
    rhs(:,j)=accumarray(map(:),vals(:),[G.nedge,1]);
  end
  ip=G.inner;pp=G.port;Aii=A(ip,ip);Api=A(pp,ip);Aip=A(ip,pp);
  dec=decomposition(Aii,'chol');response=dec\rhs(ip,:);extension=dec\full(Aip);
  solve_residual=norm(Aii*response-rhs(ip,:),'fro')/norm(rhs(ip,:),'fro');
  Sc=A(pp,pp)-Api*extension;Sc=(Sc+Sc')/2;
  rp=rhs(pp,:)-Api*response;
  pack=struct('Y',Y,'r',r,'S',Sc,'port_rhs',rp,'response',response,'extension',extension,'solve_residual',solve_residual);
end

function value=LOCAL_quadratic(H,b,c)
  Hc=pagemtimes(H,c);
  value=real(sum(conj(c).*(Hc+2*b),'all'));
end

function values=LOCAL_reconstructed(trial,x,y,cells)
  p=trial.parameters;C=trial.coefficients;N=p.N;nc=p.cells_per_side;
  m=(-p.M:p.M)';q=p.beta+2*pi*m;a=sqrt(p.s+q.^2);values=complex(zeros(numel(x),numel(cells)));
  for first=1:256:numel(x)
    ids=first:min(first+255,numel(x));xx=x(ids);yy=y(ids);
    col=min(N,max(1,floor((xx+.5)*N)+1));z=xx-(-.5+(col-1)/N);
    E=exp(1i*q*yy.');em=exp(-a*z.');ep=exp(-a*(1/N-z).');
    for j=1:numel(cells)
      gc=(cells(j)+nc)*N+col;
      modes=(C(:,gc,1)+C(:,gc,2).*z.')./a.^2+C(:,gc,3).*em+C(:,gc,4).*ep;
      values(ids,j)=sum(E.*modes,1).';
    end
  end
end

function [values,gx,gy]=LOCAL_direct(G,e,x,y,PX,J,det,cfg)
  n=numel(x);nc=numel(G.cells);values=complex(zeros(n,nc));gx=values;gy=values;
  B=[ones(n,1),x,y,x.^2,x.*y,y.^2];
  for j=1:nc
    c=G.mu(e,:,j);u=sum(B.*c,2);
    ux=c(:,2)+2*c(:,4).*x+c(:,5).*y;uy=c(:,3)+c(:,5).*x+2*c(:,6).*y;
    dx=(J(:,4).*ux-J(:,3).*uy)./det;dy=(-J(:,2).*ux+J(:,1).*uy)./det;
    X=PX+G.cells(j);t=max(0,min(1,(abs(X)-(cfg.K-1.5))/2));
    chi=(1+cos(pi*t))/2;dchi=-(pi/4)*sin(pi*t).*sign(X);
    values(:,j)=chi.*u;gx(:,j)=chi.*dx+dchi.*u;gy(:,j)=chi.*dy;
  end
end

function band=LOCAL_band(G,T,n)
  % Oriented strip formula copied in algebra from refine_i102 LOCAL_band_locate.
  [z,w]=LOCAL_gauss(n);[u,v]=ndgrid(z,z);[a,b]=ndgrid(w,w);u=u(:)';v=v(:)';wq=(a(:).*b(:))';
  th=T.interface.theta(:);dt=T.interface.dtheta;ng=numel(th);
  p0=LOCAL_curve(T,th);pm=LOCAL_curve(T,th+dt/2);p1=LOCAL_curve(T,th+dt);
  [truep,trued]=LOCAL_curve(T,reshape(th+dt*u,[],1));trued=dt*trued;
  sid=repmat((1:ng)',1,numel(u));sid=sid(:);uu=repmat(u,ng,1);uu=uu(:);vv=repmat(v,ng,1);vv=vv(:);
  base=p0(sid,:).*((1-uu).*(1-2*uu))+pm(sid,:).*(4*uu.*(1-uu))+p1(sid,:).*(uu.*(2*uu-1));
  db=p0(sid,:).*(4*uu-3)+pm(sid,:).*(4-8*uu)+p1(sid,:).*(4*uu-1);
  d=truep-base;pt=base+vv.*d;tangent=db+vv.*(trued-db);
  ww=repmat(wq,ng,1);ww=ww(:).*(d(:,1).*tangent(:,2)-d(:,2).*tangent(:,1));
  owner=[T.interface.inner(sid),T.interface.outer(sid)];
  best=-Inf(size(sid));elem=zeros(size(sid));xi=best;eta=best;
  for j=1:2
    e=owner(:,j);s=ones(numel(e),2)/3;
    for it=1:9
      [X,Y,J,det]=LOCAL_map(G.mx(e,:),G.my(e,:),s(:,1),s(:,2));
      rx=X-pt(:,1);ry=Y-pt(:,2);
      s=s-[(J(:,4).*rx-J(:,2).*ry)./det,(-J(:,3).*rx+J(:,1).*ry)./det];
    end
    bary=min([s,1-sum(s,2)],[],2);choose=bary>best;
    elem(choose)=e(choose);xi(choose)=s(choose,1);eta(choose)=s(choose,2);best(choose)=bary(choose);
  end
  assert(min(best)>-1e-7,'goerisch:Band','A true-material strip point has no adjacent owner.');
  band=struct('e',elem,'x',xi,'y',eta,'w',ww,'min_barycentric',min(best));
end

function [c,d]=LOCAL_curve(T,theta)
  theta=theta(:);
  if strcmp(T.name,'center')
    c5=cos(5*theta);s5=sin(5*theta);
    c=.2*[(1.5+.3*c5).*cos(theta),(1+.3*c5).*sin(theta)];
    d=.2*[-1.5*s5.*cos(theta)-(1.5+.3*c5).*sin(theta),-1.5*s5.*sin(theta)+(1+.3*c5).*cos(theta)];
  else
    aa=.12;if strcmp(T.name,'right'),aa=.20;end
    R=.2/sqrt(1+aa^2/2);r=R*(1+aa*cos(3*theta));dr=-3*aa*R*sin(3*theta);
    c=[r.*cos(theta),r.*sin(theta)];d=[dr.*cos(theta)-r.*sin(theta),dr.*sin(theta)+r.*cos(theta)];
  end
end

function [Dinv,err]=LOCAL_dual(k)
  nd=(k+1)*(k+3);nr=k+1;D=zeros(nd);
  [t,w]=LOCAL_gauss(k+4);L=LOCAL_legendre(t,k);
  for e=1:3
    if e==1,x=t;y=0*t;n=[0,-1];elseif e==2,x=1-t;y=t;n=[1,1];else,x=0*t;y=1-t;n=[-1,0];end
    [vx,vy]=LOCAL_rt(x,y,k);D((e-1)*nr+(1:nr),:)=L'*(w.*(n(1)*vx+n(2)*vy));
  end
  [x,y,w]=LOCAL_duffy(k+4);[vx,vy]=LOCAL_rt(x,y,k);P=LOCAL_monomials(x,y,k-1);np=size(P,2);
  D(3*nr+(1:np),:)=P'*(w.*vx);D(3*nr+np+(1:np),:)=P'*(w.*vy);
  [a,b]=rat(D,1e-12);D=a./b;Dinv=D\eye(nd);err=norm(D*Dinv-eye(nd),'inf');
  assert(err<1e-8,'goerisch:Basis','Reference duality failed.');
end

function [vx,vy,dv]=LOCAL_rt(x,y,k)
  x=x(:);y=y(:);[P,Px,Py]=LOCAL_monomials(x,y,k);z=zeros(size(P));H=zeros(numel(x),k+1);
  for j=0:k,H(:,j+1)=x.^(k-j).*y.^j;end
  vx=[P,z,x.*H];vy=[z,P,y.*H];dv=[Px,Py,(k+2)*H];
end
function [P,Px,Py]=LOCAL_monomials(x,y,k)
  x=x(:);y=y(:);n=(k+1)*(k+2)/2;P=zeros(numel(x),n);Px=P;Py=P;l=0;
  for d=0:k
    for j=0:d
      l=l+1;a=d-j;b=j;P(:,l)=x.^a.*y.^b;
      if a>0,Px(:,l)=a*x.^(a-1).*y.^b;end
      if b>0,Py(:,l)=b*x.^a.*y.^(b-1);end
    end
  end
end
function L=LOCAL_legendre(t,k)
  z=2*t-1;L=ones(numel(t),k+1);if k>0,L(:,2)=z;end
  for j=2:k,L(:,j+1)=((2*j-1)*z.*L(:,j)-(j-1)*L(:,j-1))/j;end
end
function [X,Y,J,d]=LOCAL_map(mx,my,x,y)
  B=[ones(size(x)),x,y,x.^2,x.*y,y.^2];X=sum(B.*mx,2);Y=sum(B.*my,2);
  J=[mx(:,2)+2*mx(:,4).*x+mx(:,5).*y,mx(:,3)+mx(:,5).*x+2*mx(:,6).*y, ...
    my(:,2)+2*my(:,4).*x+my(:,5).*y,my(:,3)+my(:,5).*x+2*my(:,6).*y];
  d=J(:,1).*J(:,4)-J(:,2).*J(:,3);assert(all(d>0));
end
function c=LOCAL_poly(v)
  % Verbatim coefficient convention of eq_temple_i95 LOCAL_poly.
  c=[v(:,1),-3*v(:,1)-v(:,2)+4*v(:,4),-3*v(:,1)-v(:,3)+4*v(:,6), ...
    2*v(:,1)+2*v(:,2)-4*v(:,4),4*v(:,1)-4*v(:,4)+4*v(:,5)-4*v(:,6), ...
    2*v(:,1)+2*v(:,3)-4*v(:,6)];
end
function err=LOCAL_trace(G,c,k,Dinv)
  % Moments already impose continuity; verify pointwise reference traces.
  [t,~]=LOCAL_gauss(k+3);L=LOCAL_legendre(t,k);nr=k+1;err=0;
  for e=1:3
    if e==1,x=t;y=0*t;n=[0,-1];elseif e==2,x=1-t;y=t;n=[1,1];else,x=0*t;y=1-t;n=[-1,0];end
    [vx,vy]=LOCAL_rt(x,y,k);B=(n(1)*vx+n(2)*vy)*Dinv;
    exact=zeros(size(B));exact(:,(e-1)*nr+(1:nr))=L.*(2*(0:k)+1);
    err=max(err,max(abs(B-exact),[],'all'));
  end
  % All reconstructed coefficients are finite; external moments are zero by the port solve.
  assert(all(isfinite(c),'all')&&err<1e-7,'goerisch:Trace','Normal-trace basis check failed.');
end
function [outside,upper]=LOCAL_tail(t,mass,K)
  C=t.coefficients;p=t.parameters;N=p.N;nc=p.cells_per_side;q=p.beta+2*pi*(-p.M:p.M)';a=sqrt(p.s+q.^2);
  [x,w]=LOCAL_gauss(12);outside=sum((abs(t.wl).^2+abs(t.wr).^2)./(2*a));
  cols=[1:(nc-K)*N,(nc+K+1)*N+1:size(C,2)];
  for j=1:numel(x)
    z=x(j)/N;v=(C(:,cols,1)+C(:,cols,2)*z)./a.^2+C(:,cols,3).*exp(-a*z)+C(:,cols,4).*exp(-a*(1/N-z));
    outside=outside+w(j)/N*sum(abs(v).^2,'all');
  end
  upper=17*outside/mass;
end
function [x,y,w]=LOCAL_duffy(n)
  [z,v]=LOCAL_gauss(n);[r,s]=ndgrid(z,z);[a,b]=ndgrid(v,v);x=r(:);y=(1-x).*s(:);w=a(:).*b(:).*(1-x);
end
function [x,w]=LOCAL_gauss(n)
  j=(1:n-1)';b=j./sqrt(4*j.^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));
  [x,k]=sort(diag(D));x=(x+1)/2;w=V(1,k)'.^2;
end
function LOCAL_json(file,value)
  f=fopen(file,'w');assert(f>=0);cleaner=onCleanup(@()fclose(f)); %#ok<NASGU>
  fwrite(f,jsonencode(value,PrettyPrint=true),'char');
end
