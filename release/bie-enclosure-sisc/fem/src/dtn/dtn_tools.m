function varargout=dtn_tools(action,varargin)
% Source: test/numerical-directions/h-dtn-v1/dtn_tools.m. Numerical method retained.
% DtN means Dirichlet-to-Neumann: reference quadrature and RT topology.
% Input: action and explicit numerical inputs. Output: requested local arrays.
  switch action
    case 'geometry',T=varargin{1};cfg=struct('beta',.5);varargout{1}=LOCAL_geometry(T,zeros(size(T.xy,1),1),1,cfg,3);
    case 'rt',[varargout{1:nargout}]=LOCAL_rt(varargin{:},3);
    case 'legendre',varargout{1}=LOCAL_legendre(varargin{:},3);
    case 'gauss',[varargout{1:nargout}]=LOCAL_gauss(varargin{:});
    case 'duffy',[varargout{1:nargout}]=LOCAL_duffy(varargin{:});
  end
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

function [x,y,w]=LOCAL_duffy(n)
  [z,v]=LOCAL_gauss(n);[r,s]=ndgrid(z,z);[a,b]=ndgrid(v,v);x=r(:);y=(1-x).*s(:);w=a(:).*b(:).*(1-x);
end
function [x,w]=LOCAL_gauss(n)
  j=(1:n-1)';b=j./sqrt(4*j.^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));
  [x,k]=sort(diag(D));x=(x+1)/2;w=V(1,k)'.^2;
end

function c=LOCAL_poly(v)
  % Verbatim coefficient convention of eq_temple_i95 LOCAL_poly.
  c=[v(:,1),-3*v(:,1)-v(:,2)+4*v(:,4),-3*v(:,1)-v(:,3)+4*v(:,6), ...
    2*v(:,1)+2*v(:,2)-4*v(:,4),4*v(:,1)-4*v(:,4)+4*v(:,5)-4*v(:,6), ...
    2*v(:,1)+2*v(:,3)-4*v(:,6)];
end
