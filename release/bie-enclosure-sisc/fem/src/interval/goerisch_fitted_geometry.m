function F=goerisch_fitted_geometry(T)
% Source: test/fem-goerisch/pipeline-v1/internal/goerisch_fitted_geometry.m. Copied numerical algorithm.
  % Exact-interface geometry for the Goerisch flux mesh.
  % Input
  %   T: one centered native quadratic template, including its interface.
  % Output
  %   F: map, quadrature, native-field inverse, and area function handles.
  % On an interface triangle, barycentric coordinates give r=lambda_a+
  % lambda_b and t=lambda_b/r. Add r^3 times the difference between the
  % analytic edge and its quadratic interpolant. The other edges stay fixed.
  nt=size(T.tri6,1);nodes=reshape(T.xy(T.tri6(:),:),nt,6,2);
  D=struct('mx',LOCAL_poly(nodes(:,:,1)),'my',LOCAL_poly(nodes(:,:,2)), ...
    'name',T.name,'curve',T.curve,'background',T.background,'rho',T.material(:),'nt',nt,'a',zeros(nt,1),'b',zeros(nt,1), ...
    'theta',zeros(nt,1),'dt',T.interface.dtheta,'partner',zeros(nt,1),'type',ones(nt,1));
  pairs=[1,2;2,1;2,3;3,2;3,1;1,3];
  for j=1:numel(T.interface.theta)
    th=T.interface.theta(j);p0=LOCAL_curve(D.curve,th);p1=LOCAL_curve(D.curve,th+D.dt);
    owners=[T.interface.inner(j),T.interface.outer(j)];
    for side=1:2
      e=owners(side);verts=T.xy(T.tri6(e,1:3),:);
      [~,a]=min(sum((verts-p0).^2,2));[~,b]=min(sum((verts-p1).^2,2));
      assert(a~=b&&D.a(e)==0,'goerisch:Geometry','Ambiguous curved edge.');
      D.a(e)=a;D.b(e)=b;D.theta(e)=th;D.partner(e)=owners(3-side);
      D.type(e)=1+find(pairs(:,1)==a & pairs(:,2)==b);
    end
  end
  D.pairs=pairs;
  F=struct('map',@(e,x,y)LOCAL_map(D,e,x,y),'rules',@(n)LOCAL_rules(D,n), ...
    'inverse_native',@(e,X,Y)LOCAL_inverse(D,e,X,Y),'areas',@(n)LOCAL_areas(D,n), ...
    'curved_count',nnz(D.a),'name',D.name,'element_count',nt);
end
function [X,Y,J,det]=LOCAL_map(D,e,x,y)
  % LOCAL_map Map.
  % Input
  %   D,e,x,y.
  % Output
  %   [X,Y,J,det].
  [X,Y,J,det]=LOCAL_base(D,e,x,y);
  use=D.a(e)>0;if ~any(use),return;end
  ee=e(use);xx=x(use);yy=y(use);lambda=[1-xx-yy,xx,yy];dl=[-1,-1;1,0;0,1];
  rows=(1:numel(ee))';a=D.a(ee);b=D.b(ee);
  la=lambda(sub2ind(size(lambda),rows,a));lb=lambda(sub2ind(size(lambda),rows,b));
  r=la+lb;t=zeros(size(r));active=r>1e-14;t(active)=lb(active)./r(active);
  th=D.theta(ee);[curve,dc]=LOCAL_curve(D.curve,th+D.dt*t);dc=D.dt*dc;
  p0=LOCAL_curve(D.curve,th);pm=LOCAL_curve(D.curve,th+D.dt/2);p1=LOCAL_curve(D.curve,th+D.dt);
  base=p0.*((1-t).*(1-2*t))+pm.*(4*t.*(1-t))+p1.*(t.*(2*t-1));
  db=p0.*(4*t-3)+pm.*(4-8*t)+p1.*(4*t-1);
  delta=curve-base;dt=dc-db;dr=dl(a,:)+dl(b,:);dlb=dl(b,:);
  cx=r.^3.*delta(:,1);cy=r.^3.*delta(:,2);X(use)=X(use)+cx;Y(use)=Y(use)+cy;
  for d=1:2
    direction=dlb(:,d)-t.*dr(:,d);
    J(use,d)=J(use,d)+r.^2.*(3*delta(:,1).*dr(:,d)+dt(:,1).*direction);
    J(use,d+2)=J(use,d+2)+r.^2.*(3*delta(:,2).*dr(:,d)+dt(:,2).*direction);
  end
  det=J(:,1).*J(:,4)-J(:,2).*J(:,3);
  assert(all(det>0),'goerisch:Geometry','Nonpositive fitted Jacobian.');
end
function rules=LOCAL_rules(D,n)
  % LOCAL_rules Rules.
  % Input
  %   D,n.
  % Output
  %   rules.
  [z,w]=LOCAL_gauss(n);[r,t]=ndgrid(z,z);[a,b]=ndgrid(w,w);r=r(:);t=t(:);basew=a(:).*b(:);
  rules=cell(1,7);
  for type=1:7
    ids=find(D.type==type);if isempty(ids),continue;end
    if type==1,x=r;y=(1-r).*t;weight=basew.*(1-r);
    else
      va=D.pairs(type-1,1);vb=D.pairs(type-1,2);vo=6-va-vb;
      lambda=zeros(numel(r),3);lambda(:,va)=r.*(1-t);lambda(:,vb)=r.*t;lambda(:,vo)=1-r;
      x=lambda(:,2);y=lambda(:,3);weight=basew.*r;
    end
    rules{type}=struct('ids',ids,'x',x,'y',y,'w',weight);
  end
  rules=rules(~cellfun(@isempty,rules));
end
function result=LOCAL_areas(D,n)
  % LOCAL_areas Areas.
  % Input
  %   D,n.
  % Output
  %   result.
  rules=LOCAL_rules(D,n);area=zeros(D.nt,1);minimum=Inf;
  for j=1:numel(rules)
    rule=rules{j};nq=numel(rule.w);
    for first=1:48:numel(rule.ids)
      ids=rule.ids(first:min(first+47,numel(rule.ids)));nb=numel(ids);
      ei=repelem(ids,nq);x=repmat(rule.x,nb,1);y=repmat(rule.y,nb,1);
      [~,~,~,det]=LOCAL_map(D,ei,x,y);
      area(ids)=sum(reshape(det,nq,nb).*rule.w,1).';minimum=min(minimum,min(det));
    end
  end
  target=D.curve.area;
  value=sum(area(D.rho>D.background));
  result=struct('order',n,'inclusion_area',value,'analytic_area',target, ...
    'relative_error',abs(value-target)/target,'cell_area',sum(area),'minimum_jacobian',minimum);
end
function [e,x,y,J,det]=LOCAL_inverse(D,e,X,Y)
  % LOCAL_inverse Inverse.
  % Input
  %   D,e,X,Y.
  % Output
  %   [e,x,y,J,det].
  [x,y,J,det]=LOCAL_newton(D,e,X,Y);bary=min([x,y,1-x-y],[],2);bad=bary<-1e-10;
  if any(bad)
    replacement=D.partner(e(bad));assert(all(replacement>0),'goerisch:NativeOwner','No native neighbor for a fitted point.');
    [xn,yn,Jn,dn]=LOCAL_newton(D,replacement,X(bad),Y(bad));bn=min([xn,yn,1-xn-yn],[],2);
    assert(all(bn>-1e-8),'goerisch:NativeOwner','Fitted point is outside both native triangles.');
    e(bad)=replacement;x(bad)=xn;y(bad)=yn;J(bad,:)=Jn;det(bad)=dn;
  end
end
function [x,y,J,det]=LOCAL_newton(D,e,X,Y)
  % LOCAL_newton Newton.
  % Input
  %   D,e,X,Y.
  % Output
  %   [x,y,J,det].
  cx=D.mx(e,:);cy=D.my(e,:);A=[cx(:,2)+cx(:,4),cx(:,3)+cx(:,6),cy(:,2)+cy(:,4),cy(:,3)+cy(:,6)];
  dd=A(:,1).*A(:,4)-A(:,2).*A(:,3);rx=X-cx(:,1);ry=Y-cy(:,1);
  x=(A(:,4).*rx-A(:,2).*ry)./dd;y=(-A(:,3).*rx+A(:,1).*ry)./dd;
  for it=1:6
    [xx,yy,J,det]=LOCAL_base(D,e,x,y);rx=xx-X;ry=yy-Y;
    x=x-(J(:,4).*rx-J(:,2).*ry)./det;y=y-(-J(:,3).*rx+J(:,1).*ry)./det;
  end
  [~,~,J,det]=LOCAL_base(D,e,x,y);
end
function [X,Y,J,d]=LOCAL_base(D,e,x,y)
  % LOCAL_base Base.
  % Input
  %   D,e,x,y.
  % Output
  %   [X,Y,J,d].
  mx=D.mx(e,:);my=D.my(e,:);B=[ones(size(x)),x,y,x.^2,x.*y,y.^2];X=sum(B.*mx,2);Y=sum(B.*my,2);
  J=[mx(:,2)+2*mx(:,4).*x+mx(:,5).*y,mx(:,3)+mx(:,5).*x+2*mx(:,6).*y, ...
    my(:,2)+2*my(:,4).*x+my(:,5).*y,my(:,3)+my(:,5).*x+2*my(:,6).*y];
  d=J(:,1).*J(:,4)-J(:,2).*J(:,3);
end
function [c,d]=LOCAL_curve(curve,theta)
  % Input: explicit curve and angles. Output: position and derivative.
  [c,d]=physical_curve(curve,theta);
end

function c=LOCAL_poly(v)
  % LOCAL_poly Poly.
  % Input
  %   v.
  % Output
  %   c.
  c=[v(:,1),-3*v(:,1)-v(:,2)+4*v(:,4),-3*v(:,1)-v(:,3)+4*v(:,6), ...
    2*v(:,1)+2*v(:,2)-4*v(:,4),4*v(:,1)-4*v(:,4)+4*v(:,5)-4*v(:,6),2*v(:,1)+2*v(:,3)-4*v(:,6)];
end
function [x,w]=LOCAL_gauss(n)
  % LOCAL_gauss Gauss.
  % Input
  %   n.
  % Output
  %   [x,w].
  j=(1:n-1)';b=j./sqrt(4*j.^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));
  [x,k]=sort(diag(D));x=(x+1)/2;w=V(1,k)'.^2;
end
