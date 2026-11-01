function [Tfine,F]=goerisch_refined_geometry(T)
  % One uniform four-child refinement of the exact Goerisch flux geometry.
  % Input
  %   T: centered native template used by goerisch_fitted_geometry.
  % Output
  %   Tfine: conforming child topology and inherited material labels.
  %   F: exact child maps, quadrature rules, areas and native-field inverse.
  % Each child map is the existing fitted parent map composed with an
  % affine reference-triangle map. This preserves the exact interfaces.
  parent=goerisch_fitted_geometry(T);nt=size(T.tri6,1);tr=T.tri6;
  conn=[tr(:,[1,4,6]);tr(:,[4,2,5]);tr(:,[6,5,3]);tr(:,[4,5,6])];
  parent_id=repmat((1:nt)',4,1);child_id=repelem((1:4)',nt);
  origin=[0,0;.5,0;0,.5;.5,0];
  jac=[.5,0,0,.5;.5,0,0,.5;.5,0,0,.5;0,-.5,.5,.5];
  D=struct('parent',parent,'parent_id',parent_id,'child_id',child_id, ...
    'origin',origin,'jac',jac,'rho',repmat(T.material(:),4,1),'nt',4*nt,'name',T.name);
  [edges,first,edge_id]=unique(sort([conn(:,[1,2]);conn(:,[2,3]);conn(:,[3,1])],2),'rows');
  edge_id=reshape(edge_id,4*nt,3);owner=mod(first-1,4*nt)+1;side=floor((first-1)/(4*nt))+1;
  midpoint=[.5,0;.5,.5;0,.5];
  [X,Y]=LOCAL_map(D,owner,midpoint(side,1),midpoint(side,2));
  offset=size(T.xy,1);Tfine=T;Tfine.xy=[T.xy;X,Y];
  Tfine.tri6=[conn,offset+edge_id];Tfine.material=D.rho;
  Tfine.native=T;Tfine.parent_id=parent_id;
  curved=false(nt,1);curved([T.interface.inner(:);T.interface.outer(:)])=true;
  D.curved=repmat(curved,4,1);D.type=ones(4*nt,1);pairs=[2,3;3,1;1,2];
  % Only the child containing the parent's opposite vertex needs the
  % radial rule that resolves the parent's r=0 coordinate singularity.
  for e=find(curved).'
    vertices=T.tri6(e,1:3);
    for j=1:numel(T.interface.theta)
      if T.interface.inner(j)~=e&&T.interface.outer(j)~=e,continue;end
      a=T.interface.inner(j);b=T.interface.outer(j);
      common=intersect(T.tri6(a,1:3),T.tri6(b,1:3));
      vo=find(~ismember(vertices,common));assert(numel(vo)==1);
      D.type(e+(vo-1)*nt)=1+vo;break
    end
  end
  D.pairs=pairs;
  Tfine.interface.inner=find(D.curved);Tfine.interface.outer=[];
  F=struct('map',@(e,x,y)LOCAL_map(D,e,x,y),'rules',@(n)LOCAL_rules(D,n), ...
    'inverse_native',@(e,X,Y)LOCAL_inverse(D,e,X,Y),'areas',@(n)LOCAL_areas(D,n), ...
    'curved_count',nnz(D.curved),'name',T.name,'element_count',D.nt);
end
function [X,Y,J,det]=LOCAL_map(D,e,x,y)
  c=D.child_id(e);a=D.origin(c,:);b=D.jac(c,:);
  xp=a(:,1)+b(:,1).*x+b(:,2).*y;yp=a(:,2)+b(:,3).*x+b(:,4).*y;
  [X,Y,P]=D.parent.map(D.parent_id(e),xp,yp);
  J=[P(:,1).*b(:,1)+P(:,2).*b(:,3),P(:,1).*b(:,2)+P(:,2).*b(:,4), ...
    P(:,3).*b(:,1)+P(:,4).*b(:,3),P(:,3).*b(:,2)+P(:,4).*b(:,4)];
  det=J(:,1).*J(:,4)-J(:,2).*J(:,3);assert(all(det>0));
end
function [e,x,y,J,det]=LOCAL_inverse(D,e,X,Y)
  [e,x,y,J,det]=D.parent.inverse_native(D.parent_id(e),X,Y);
end
function rules=LOCAL_rules(D,n)
  [z,w]=LOCAL_gauss(n);[r,t]=ndgrid(z,z);[a,b]=ndgrid(w,w);r=r(:);t=t(:);basew=a(:).*b(:);
  rules={};
  for type=1:4
    ids=find(D.type==type);if isempty(ids),continue;end
    if type==1,x=r;y=(1-r).*t;weight=basew.*(1-r);
    else
      va=D.pairs(type-1,1);vb=D.pairs(type-1,2);vo=6-va-vb;
      lambda=zeros(numel(r),3);lambda(:,va)=r.*(1-t);lambda(:,vb)=r.*t;lambda(:,vo)=1-r;
      x=lambda(:,2);y=lambda(:,3);weight=basew.*r;
    end
    % Keep unchanged/curved groups separate for the component audit.
    for curved=[false,true]
      subset=ids(D.curved(ids)==curved);if isempty(subset),continue;end
      rules{end+1}=struct('ids',subset,'x',x,'y',y,'w',weight); %#ok<AGROW>
    end
  end
end
function result=LOCAL_areas(D,n)
  rules=LOCAL_rules(D,n);area=zeros(D.nt,1);minimum=Inf;
  for j=1:numel(rules)
    rule=rules{j};nq=numel(rule.w);
    for first=1:48:numel(rule.ids)
      ids=rule.ids(first:min(first+47,numel(rule.ids)));nb=numel(ids);
      [~,~,~,det]=LOCAL_map(D,repelem(ids,nq),repmat(rule.x,nb,1),repmat(rule.y,nb,1));
      area(ids)=sum(reshape(det,nq,nb).*rule.w,1).';minimum=min(minimum,min(det));
    end
  end
  target=pi*.2^2;if strcmp(D.name,'center'),target=target*(1.5+.3^2/2);end
  value=sum(area(D.rho>1));
  result=struct('order',n,'inclusion_area',value,'analytic_area',target, ...
    'relative_error',abs(value-target)/target,'cell_area',sum(area),'minimum_jacobian',minimum);
end
function [x,w]=LOCAL_gauss(n)
  j=(1:n-1)';b=j./sqrt(4*j.^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));
  [x,k]=sort(diag(D));x=(x+1)/2;w=V(1,k)'.^2;
end
