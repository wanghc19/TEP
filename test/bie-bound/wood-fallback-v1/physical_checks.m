function r=physical_checks(e,c,job)
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
  a=piece(e.leads.negative,left);b=piece(e.center,e.q);d=piece(e.leads.positive,right);
  aa=piece(e.leads.negative,left2,true);dd=piece(e.leads.positive,right2,true);
  joins=[a.right-b.left;b.right-d.left;aa.right-a.left;d.right-dd.left];
  wall=sqrt(mean(abs(joins(1:2:end,:)).^2,'all')+mean(abs(joins(2:2:end,:)).^2,'all'));
  r=struct('material_L2',sqrt(a.material_sq+b.material_sq+d.material_sq),'wall_rms',wall);
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
function r=piece(s,state,onlywalls)
  % Assemble a two-row period or evaluate a single physical row.
  if nargin<3,onlywalls=false;end
  if isfield(s,'first')
    n=numel(state)/2;a=piece(s.first,[state(1:n);s.backward*state],onlywalls);
    b=piece(s.second,[s.forward*state;state(n+1:end)],onlywalls);
    r=a;
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
  y=(-.5+((0:39)+.37)/40);xwall=[xl*ones(size(y)),xr*ones(size(y))];
  [u,ux]=values([xwall;[y,y]],false(size(xwall)));nwall=numel(y);
  r=struct('material_sq',mat,'left',[u(1:nwall);ux(1:nwall)], ...
    'right',[u(nwall+1:end);ux(nwall+1:end)],'internal',0);
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
