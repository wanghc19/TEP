function varargout=poly2(action,varargin)
% Source: test/fem-goerisch/pipeline-v1/internal/poly2.m. Copied numerical algorithm.
  % POLY2 Two-dimensional polynomial plus uniform remainder arithmetic.
  % Input
  %   action and scalar models with coefficient matrix c and error e.
  %   Coefficient c(i+1,j+1) multiplies x^i*y^j on [-1,1]^2.
  % Output
  %   Models and integration bounds; all arithmetic excludes rounding.
  switch action
    case 'make',varargout{1}=LOCAL_model(varargin{:});
    case 'add'
      a=varargin{1};b=varargin{2};varargout{1}=LOCAL_model(LOCAL_add(a.c,b.c),a.e+b.e);
    case 'mul'
      a=varargin{1};b=varargin{2};varargout{1}=LOCAL_model(conv2(a.c,b.c),LOCAL_norm(a.c)*b.e+LOCAL_norm(b.c)*a.e+a.e*b.e);
    case 'truncate'
      a=varargin{1};m=varargin{2};[i,j]=ndgrid(0:size(a.c,1)-1,0:size(a.c,2)-1);drop=i+j>m;
      a.e=a.e+LOCAL_norm(a.c.*drop);a.c(drop)=0;varargout{1}=a;
    case 'reciprocal'
      a=varargin{1};L=varargin{2};d0=real(a.c(1));delta=-a.c/d0;delta(1)=delta(1)+1;k=LOCAL_norm(delta);
      lower=(1-k)*d0-a.e;assert(d0>0&&k<1&&lower>0,'poly2:Reciprocal','Unresolved reciprocal panel');
      power=1;c=0;for n=0:L,c=LOCAL_add(c,power/d0);power=conv2(power,delta);end
      varargout{1}=LOCAL_model(c,k^(L+1)/(d0*(1-k))+a.e/(lower*(1-k)*d0));
    case {'sin','cos'}
      a=varargin{1};L=varargin{2};center=real(a.c(1));delta=a.c;delta(1)=delta(1)-center;D=LOCAL_norm(delta);power=1;c=0;
      for n=0:L
        if strcmp(action,'sin'),v=sin(center+n*pi/2);else,v=cos(center+n*pi/2);end
        c=LOCAL_add(c,v/factorial(n)*power);power=conv2(power,delta);
      end
      varargout{1}=LOCAL_model(c,D^(L+1)/factorial(L+1)+a.e);
    case 'range'
      a=varargin{1};n=size(a.c,1)-1;m=size(a.c,2)-1;A=zeros(n+1);B=zeros(m+1);
      for i=0:n,for k=0:i,A(k+1,i+1)=nchoosek(i,k)*2^k*(-1)^(i-k);end,end
      for i=0:m,for k=0:i,B(k+1,i+1)=nchoosek(i,k)*2^k*(-1)^(i-k);end,end
      power=A*real(a.c)*B.';C=zeros(n+1);D=zeros(m+1);
      for i=0:n,for k=0:i,C(i+1,k+1)=nchoosek(i,k)/nchoosek(n,k);end,end
      for i=0:m,for k=0:i,D(i+1,k+1)=nchoosek(i,k)/nchoosek(m,k);end,end
      bern=C*power*D.';varargout{1}=[min(bern,[],'all')-a.e,max(bern,[],'all')+a.e];
    case 'norm',varargout{1}=LOCAL_norm(varargin{1});
    case 'triangle',varargout{1}=LOCAL_triangle(varargin{1});
    case 'square'
      a=varargin{1};[i,j]=ndgrid(0:size(a.c,1)-1,0:size(a.c,2)-1);W=4./((i+1).*(j+1));W(mod(i,2)==1|mod(j,2)==1)=0;
      v=sum(W.*a.c,'all');varargout{1}=[real(v)-4*a.e,real(v)+4*a.e];
    case 'rational_triangle'
      num=varargin{1};den=varargin{2};lo=varargin{3};hi=varargin{4};tol=varargin{5};d0=(lo+hi)/2;k=(hi-lo)/(hi+lo);
      assert(lo>0&&k<1);delta=-den/d0;delta(1)=delta(1)+1;power=1;c=0;N=LOCAL_norm(num);L=0;
      while true
        c=LOCAL_add(c,power/d0);err=.5*N*k^(L+1)/(d0*(1-k));
        if err<=tol||L==60,break,end
        power=conv2(power,delta);L=L+1;
      end
      assert(err<=tol,'poly2:Degree','Rational certificate exceeds degree cap');
      v=real(LOCAL_triangle(conv2(num,c)));varargout{1}=struct('value',v,'error',err,'degree',L,'kappa',k);
    otherwise,error('poly2:Action','Unknown operation');
  end
end
function a=LOCAL_model(c,e)
  % LOCAL_model Model.
  % Input
  %   c,e.
  % Output
  %   a.
  if nargin<2,e=0;end;a=struct('c',c,'e',e);
end
function c=LOCAL_add(a,b)
  % LOCAL_add Add.
  % Input
  %   a,b.
  % Output
  %   c.
  c=zeros(max(size(a,1),size(b,1)),max(size(a,2),size(b,2)));c(1:size(a,1),1:size(a,2))=a;c(1:size(b,1),1:size(b,2))=c(1:size(b,1),1:size(b,2))+b;
end
function v=LOCAL_norm(c)
  % LOCAL_norm Norm.
  % Input
  %   c.
  % Output
  %   v.
  v=sum(abs(real(c))+abs(imag(c)),'all');
end
function v=LOCAL_triangle(c)
  % LOCAL_triangle Triangle.
  % Input
  %   c.
  % Output
  %   v.
  persistent weights
  n=size(c,1);m=size(c,2);if isempty(weights),weights=cell(180);end
  if isempty(weights{n,m})
    W=zeros(n,m);W(1,:)=1./((1:m).*(2:m+1));
    for i=1:n-1,W(i+1,:)=W(i,:)*i./(i+(0:m-1)+2);end
    weights{n,m}=W;
  end
  v=sum(weights{n,m}.*c,'all');
end
