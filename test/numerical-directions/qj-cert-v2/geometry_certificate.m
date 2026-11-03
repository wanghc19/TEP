function C=geometry_certificate(T,G)
  % GEOMETRY_CERTIFICATE Bound native and fitted deformations on whole elements.
  % Input
  %   T: native quadratic template; G: centered polynomial geometry.
  % Output
  %   Element determinant minima, inverse bounds and global deformation margins.
  nt=G.nt;mn=zeros(nt,1);mx=mn;invnorm=mn;eta=mn;adjmax=mn;
  for e=1:nt
    x=G.mx(e,:);y=G.my(e,:);a=[x(2),x(3);y(2),y(3)];d=[x(4);y(4)];f=[x(6);y(6)];b=[x(5);y(5)];
    cross=@(u,v)u(1)*v(2)-u(2)*v(1);
    j=[det(a),cross(2*d,a(:,2))+cross(a(:,1),b),cross(b,a(:,2))+cross(a(:,1),2*f),cross(2*d,b),4*cross(d,f),cross(b,2*f)];
    [mn(e),mx(e)]=LOCAL_extrema(j);B=[x(2)+x(4),x(3)+x(6);y(2)+y(4),y(3)+y(6)];assert(det(B)>0);
    for v=[0,0;1,0;0,1].'
      J=a+[2*d*v(1)+b*v(2),b*v(1)+2*f*v(2)];eta(e)=max(eta(e),norm((J-B)/B,'fro'));adjmax(e)=max(adjmax(e),norm(J,'fro'));
    end
    invnorm(e)=adjmax(e)/mn(e);
  end
  dt=T.interface.dtheta;ng=numel(T.interface.theta);D0=zeros(ng,1);D1=D0;Q1=D0;feta=zeros(nt,1);
  for j=1:ng
    curve=curve_model(T.name,T.interface.theta(j),dt,18);if strcmp(T.name,'center'),C3=8.7;else,a=.12;if strcmp(T.name,'right'),a=.20;end;C3=.2/sqrt(1+a^2/2)*(1+a/2*(4^3+2^3));end
    D0(j)=min(curve.D0,dt^3*C3/(72*sqrt(3)));D1(j)=curve.D1;
    dq=curve.dq.c;Q1(j)=max(abs(dq(1)-dq(2)),abs(dq(1)+dq(2)));
    for e=[T.interface.inner(j),T.interface.outer(j)]
      verts=T.xy(T.tri6(e,1:3),:);[~,a]=min(sum((verts-curve.p0).^2,2));[~,b]=min(sum((verts-curve.p1).^2,2));
      dl=[-1,-1;1,0;0,1];R=dl(a,:)+dl(b,:);L=dl(b,:);
      feta(e)=(3*D0(j)*norm(R)+D1(j)*max(norm(L),norm(L-R)))*invnorm(e);
    end
  end
  C=struct('native_eta_max',max(eta),'fitted_eta_max',max(feta),'native_det_min',min(mn), ...
    'fitted_det_min',min((1-feta).^2.*mn),'native_global_pass',all(eta<1)&&all(mn>0), ...
    'fitted_global_pass',all(feta<1)&&all(mn>0),'det_min',mn,'det_max',mx,'inverse_norm',invnorm, ...
    'jacobian_norm',adjmax,'eta_native',eta,'eta_fitted',feta,'D0',D0,'D1',D1,'Q1',Q1);
end
function [lo,hi]=LOCAL_extrema(c)
  q=@(x,y)c(1)+c(2)*x+c(3)*y+c(4)*x.^2+c(5)*x.*y+c(6)*y.^2;
  pts=[0,0;1,0;0,1];E=[c(4),c(2);c(6),c(3);c(4)-c(5)+c(6),c(2)-c(3)+c(5)-2*c(6)];
  for k=1:3
    if E(k,1)~=0
      t=-E(k,2)/(2*E(k,1));if t>0&&t<1
        if k==1,p=[t,0];elseif k==2,p=[0,t];else,p=[t,1-t];end;pts(end+1,:)=p;
      end
    end
  end
  H=[2*c(4),c(5);c(5),2*c(6)];if det(H)~=0,p=-H\c(2:3).';if all(p>0)&&sum(p)<1,pts(end+1,:)=p.';end,end
  v=q(pts(:,1),pts(:,2));lo=min(v);hi=max(v);
end
