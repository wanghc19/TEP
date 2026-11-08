function r=original_physical_checks(e,c,job)
  % Physical mass, energy and off-node trace jumps of the actual three-cell field.
  % Input: fresh matching evidence with full cells. Output: normalized scalar checks.
  % Trace and potential formulas follow budget-v1/budget_run.m. Lengths d=1.
  K=numel(e.q)/2;
  if isfield(e,'negative_coordinates')
    [left,left2]=leadstate(e.leads.negative,e.negative_coordinates,true,true);
    [right,right2]=leadstate(e.leads.positive,e.positive_coordinates,false,true);
  else
    trace=e.matching.T*e.q;
    [left,left2]=leadstate(e.leads.negative,trace(1:K),true,false);
    [right,right2]=leadstate(e.leads.positive,trace(K+1:end),false,false);
  end
  den=[];weighted=0;
  if isfield(e.center,'raw')
    den=e.center.density;
    C=e.center.geometry;w=hypot(C(2,:),C(5,:)).'*(2*pi/size(C,2));
    weighted=sum([w;w].*abs(den).^2);
  else
    e.center.empty=true;e.center.ch=e.leads.channels;e.center.ch.L=e.model.X_R-e.model.X_L;
    e.center.xl=e.model.X_L;e.center.xr=e.model.X_R;e.center.kext=e.model.khat;
  end
  na=40;nr=4;if isfield(job,'energy_order'),nr=job.energy_order;na=10*nr;end
  a=piece(e.leads.negative,left,na,nr);b=piece(e.center,e.q,na,nr);d=piece(e.leads.positive,right,na,nr);
  aa=piece(e.leads.negative,left2,na,nr,true);dd=piece(e.leads.positive,right2,na,nr,true);
  s=norm(e.q)^2+norm(den)^2;sw=norm(e.q)^2+weighted;
  mass=[a.mass,b.mass,d.mass];en=[a.energy,b.energy,d.energy];
  joins=[a.right-b.left;b.right-d.left];junction=sqrt(sum(abs(joins(:)).^2)/(2*size(joins,2)));
  joins=[joins;aa.right-a.left;d.right-dd.left];wall=sqrt(mean(abs(joins(1:2:end,:)).^2,'all')+mean(abs(joins(2:2:end,:)).^2,'all'));
  matsq=a.material_sq+b.material_sq+d.material_sq;
  r=struct('xi_squared',s,'xi_arclength_squared',sw,'incident_squared',norm(e.q)^2, ...
    'energy_by_cell',en,'energy_per_xi',sum(en)/s,'energy_per_weighted_xi',sum(en)/sw, ...
    'mass_by_cell',mass,'mass_per_xi',sum(mass)/s,'material_L2',sqrt(matsq), ...
    'wall_rms',wall,'junction_rms',junction,'seam_rms',max([a.seam,b.seam,d.seam]),'internal_row_jump',max([a.internal,d.internal]), ...
    'area_by_cell',[a.area,b.area,d.area],'n_angle',na,'n_radial',nr);
end
function [w,next]=leadstate(s,trace,negative,coordinates)
  % Lead input amplitudes on its first physical period.
  n=size(s.R_L,1);I=eye(n);O=zeros(n);Z=s.Z;
  A=[-s.R_L,I;s.T_LR,O];B=[O,s.T_RL;I,-s.R_R];
  if negative,P=(A*Z)\(B*Z);else,P=(B*Z)\(A*Z);end
  U=Z(1:n,:);V=Z(n+1:end,:);
  if coordinates,c=trace;else,c=(U+V)\trace;end
  if negative,G=[U*P;V];else,G=[U;V*P];end;w=G*c;next=G*(P*c);
end
function r=piece(s,state,na,nr,onlywalls)
  % Assemble a two-row period or evaluate a single physical row.
  if nargin<5,onlywalls=false;end
  if isfield(s,'first')
    n=numel(state)/2;a=piece(s.first,[state(1:n);s.backward*state],na,nr,onlywalls);
    b=piece(s.second,[s.forward*state;state(n+1:end)],na,nr,onlywalls);
    r=a;r.seam=max(a.seam,b.seam);r.mass=a.mass+b.mass;r.energy=a.energy+b.energy;r.area=a.area+b.area;
    r.material_sq=a.material_sq+b.material_sq;r.right=b.right;r.internal=norm(a.right-b.left,'fro')/sqrt(size(a.right,2));return
  end
  empty=isfield(s,'empty');
  if empty
    xl=s.xl;xr=s.xr;ch=s.ch;o=[(xr+xl)/2;0];mat=0;src=[];den=[];
  else
    xl=s.raw.X_L;xr=s.raw.X_R;ch=s.raw.channels;C=s.geometry;n=size(C,2);
    if isfield(s,'density'),den=s.density;else,den=[s.raw.H_L,s.raw.H_R]*state;end
    nf=2*n;
    mat=0;
    if ~onlywalls
    cf=real(interpft(C,nf,2));eta=[interpft(den(1:n),nf);interpft(den(n+1:end),nf)];
    w=hypot(cf(2,:),cf(5,:)).'*(2*pi/nf);wt=sqrt([w;w]);
    A=op.construct_A_QP(cf,s.kext,s.kint,s.pars,s.proxy,2*pi);
    [bl,br]=bloch.incident_rhs(cf,ch,xl,xr);jump=(A*(wt.*eta))./wt+[bl,br]*state;
    off=(2:2:nf)';mat=2*sum(w(off).*(abs(jump(off)).^2+abs(jump(nf+off)).^2));
    end
    ns=max(1024,8*n);if min([min(C(1,:))-xl,xr-max(C(1,:))])<.06,ns=max(ns,2048);end
    cc=real(interpft(C,ns,2));src=cc([1,4],:);
    tau=interpft(den(1:n),ns);zeta=interpft(den(n+1:end),ns);
    den=(2*pi/ns)*[cc(5,:).'.*tau,-cc(2,:).'.*tau,hypot(cc(2,:),cc(5,:)).'.*zeta];
    o=mean(C([1,4],:),2);
  end
  if onlywalls
    mass=0;energy=0;ws=0;
  else
  [g,wg]=gauss(nr);
  if empty
    [ii,jj]=ndgrid(1:nr,1:na);
    xy=[xl+(xr-xl)*g(ii(:)).';(jj(:).'-0.63)/na-.5];ws=(xr-xl)*wg(ii(:)).'/na;inside=false(size(ws));
  else
    % Radial map from the parametric contour to the physical rectangle.
    freq=[0:n/2-1,-n/2:-1];angles=2*pi*((0:na-1)+.37)/na;
    boundary=real(fft(C,[],2)/n*exp(1i*freq.'*angles));rays=boundary([1,4],:)-o;
    J=abs(rays(1,:).*boundary(5,:)-rays(2,:).*boundary(2,:));
    tx=max((xr-o(1))./rays(1,:),(xl-o(1))./rays(1,:));ty=max((.5-o(2))./rays(2,:),(-.5-o(2))./rays(2,:));fac=min(tx,ty);
    assert(all(fac>1) && all(J>0));xy=[];ws=[];inside=[];
    for j=1:nr
      for in=[true,false]
        if in,tau=g(j)*ones(1,na);dt=ones(1,na);else,tau=1+g(j)*(fac-1);dt=fac-1;end
        xy=[xy,o+rays.*tau];ws=[ws,(2*pi/na)*wg(j)*dt.*tau.*J];inside=[inside,in*ones(1,na)];
      end
    end
    inside=logical(inside);
  end
  [u,ux,uy]=values(xy,inside);rho=ones(size(ws));if ~empty,rho(inside)=s.rho;end
  mass=sum(ws.*rho.*abs(u).^2);energy=sum(ws.*(abs(ux).^2+abs(uy).^2))+s.kext^2*mass;
  end
  y=(-.5+((0:39)+.37)/40);xwall=[xl*ones(size(y)),xr*ones(size(y))];
  [u,ux]=values([xwall;[y,y]],false(size(xwall)));nwall=numel(y);
  r=struct('mass',mass,'energy',energy,'area',sum(ws),'material_sq',mat, ...
    'left',[u(1:nwall);ux(1:nwall)],'right',[u(nwall+1:end);ux(nwall+1:end)],'internal',0);
  r.seam=0;
  if ~onlywalls
    x=xl+(xr-xl)*((0:23)+.37)/24;
    [uv,~,dv]=values([[x,x];[-.5*ones(size(x)),.5*ones(size(x))]],false(1,2*numel(x)));
    pq=exp(1i*ch.beta_m((end+1)/2));j=numel(x);
    r.seam=sqrt(mean(abs(uv(j+1:end)-pq*uv(1:j)).^2+abs(dv(j+1:end)-pq*dv(1:j)).^2));
  end
  function [u,ux,uy]=values(target,inside)
    bm=ch.beta_m(:);gm=ch.gamma_m(:);K=numel(gm);u=complex(zeros(1,size(target,2)));ux=u;uy=u;
    for in=[true,false]
      idx=find(inside==in);
      for at=1:16:numel(idx)
        ids=idx(at:min(end,at+15));xy=target(:,ids);nactual=numel(ids);if nactual==1,xy=[xy,xy];end
        if in
          X=xy(1,:).'-src(1,:);Y=xy(2,:).'-src(2,:);rr=hypot(X,Y);k=s.kint;
          P=.25i*besselh(0,1,k*rr);h=-.25i*k*besselh(1,1,k*rr)./rr;
          gx=h.*X;gy=h.*Y;v=(-k^2*P-2*h)./(rr.^2);
          xx=h+v.*X.^2;yy=h+v.*Y.^2;yx=v.*X.*Y;
        else
          fL=exp(1i*(bm*xy(2,:)+gm*(xy(1,:)-xl))).*state(1:K);
          fR=exp(1i*(bm*xy(2,:)-gm*(xy(1,:)-xr))).*state(K+1:end);
          uu=sum(fL+fR,1)/sqrt(ch.d);dx=sum(1i*gm.*(fL-fR),1)/sqrt(ch.d);dy=sum(1i*bm.*(fL+fR),1)/sqrt(ch.d);
          u(ids)=uu(1:nactual);ux(ids)=dx(1:nactual);uy(ids)=dy(1:nactual);
          if empty,continue;end
          [P,gx,gy,xx,yx,yy]=kernel.qpgreen_mfs_pairmat(src,xy,s.pars,s.proxy);
        end
        u(ids)=u(ids)-(gx(1:nactual,:)*den(:,1)+gy(1:nactual,:)*den(:,2)+P(1:nactual,:)*den(:,3)).';
        ux(ids)=ux(ids)-(xx(1:nactual,:)*den(:,1)+yx(1:nactual,:)*den(:,2)+gx(1:nactual,:)*den(:,3)).';
        uy(ids)=uy(ids)-(yx(1:nactual,:)*den(:,1)+yy(1:nactual,:)*den(:,2)+gy(1:nactual,:)*den(:,3)).';
      end
    end
  end
end
function [g,w]=gauss(n)
  j=(1:n-1)';b=j./sqrt(4*j.^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));[z,i]=sort(diag(D));g=(z+1)/2;w=V(1,i)'.^2;
end
