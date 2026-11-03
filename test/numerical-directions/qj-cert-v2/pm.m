function varargout=pm(action,varargin)
  % PM Polynomial models on [-1,1]^2 with a uniform remainder.
  % Input
  %   action and models (c,e); total degree is capped at 12 after each product.
  % Output
  %   Models, coefficient bounds and analytic integrals; rounding is excluded.
  switch action
    case 'make'
      c=varargin{1};e=0;if numel(varargin)>1,e=varargin{2};end;varargout{1}=struct('c',c,'e',e);
    case 'strip',a=varargin{1};a.e=0;varargout{1}=a;
    case 'add'
      a=varargin{1};b=varargin{2};varargout{1}=LOCAL_make(LOCAL_add(a.c,b.c),a.e+b.e);
    case 'sub',varargout{1}=pm('add',varargin{1},pm('scale',varargin{2},-1));
    case 'scale',a=varargin{1};k=varargin{2};varargout{1}=LOCAL_make(a.c*k,a.e*abs(k));
    case 'mul'
      a=varargin{1};b=varargin{2};v=LOCAL_make(conv2(a.c,b.c),LOCAL_norm(a.c)*b.e+LOCAL_norm(b.c)*a.e+a.e*b.e);varargout{1}=LOCAL_cut(v);
    case 'conj',a=varargin{1};a.c=conj(a.c);varargout{1}=a;
    case {'real','imag'}
      a=varargin{1};if strcmp(action,'real'),a.c=real(a.c);else,a.c=imag(a.c);end;varargout{1}=a;
    case 'modulus'
      a=varargin{1};varargout{1}=hypot(sum(abs(real(a.c)),'all'),sum(abs(imag(a.c)),'all'))+a.e;
    case 'norm',a=varargin{1};varargout{1}=LOCAL_norm(a.c)+a.e;
    case 'range',varargout{1}=poly2('range',varargin{1});
    case 'reciprocal'
      a=varargin{1};L=16;d0=real(a.c(1));z=LOCAL_make(-a.c/d0,0);z.c(1)=z.c(1)+1;k=LOCAL_norm(z.c);lo=d0*(1-k)-a.e;
      assert(d0>0&&k<1&&lo>0,'pm:Reciprocal','Reciprocal panel must be subdivided');
      p=LOCAL_make(1,0);s=LOCAL_make(0,0);
      for j=0:L,s=pm('add',s,pm('scale',p,1/d0));p=pm('mul',p,z);end
      s.e=s.e+k^(L+1)/(d0*(1-k))+a.e/(lo*d0*(1-k));varargout{1}=s;
    case {'sin','cos'}
      a=varargin{1};L=16;center=real(a.c(1));z=LOCAL_make(a.c,0);z.c(1)=z.c(1)-center;D=LOCAL_norm(z.c);p=LOCAL_make(1,0);s=LOCAL_make(0,0);
      for j=0:L
        if strcmp(action,'sin'),v=sin(center+j*pi/2);else,v=cos(center+j*pi/2);end
        s=pm('add',s,pm('scale',p,v/factorial(j)));p=pm('mul',p,z);
      end
      s.e=s.e+D^(L+1)/factorial(L+1)+a.e;varargout{1}=s;
    case 'polyval'
      c=varargin{1};x=varargin{2};y=varargin{3};s=LOCAL_make(0,0);
      for i=size(c,1):-1:1
        sy=LOCAL_make(0,0);for j=size(c,2):-1:1,sy=pm('add',pm('mul',sy,y),LOCAL_make(c(i,j),0));end
        s=pm('add',pm('mul',s,x),sy);
      end
      varargout{1}=s;
    case 'integral'
      a=varargin{1};[i,j]=ndgrid(0:size(a.c,1)-1,0:size(a.c,2)-1);W=4./((i+1).*(j+1));W(mod(i,2)==1|mod(j,2)==1)=0;v=real(sum(W.*a.c,'all'));varargout{1}=struct('value',v,'error',4*a.e);
    otherwise,error('pm:Action','Unknown model operation');
  end
end
function a=LOCAL_make(c,e)
  a=struct('c',c,'e',e);
end
function c=LOCAL_add(a,b)
  c=zeros(max(size(a,1),size(b,1)),max(size(a,2),size(b,2)));c(1:size(a,1),1:size(a,2))=a;c(1:size(b,1),1:size(b,2))=c(1:size(b,1),1:size(b,2))+b;
end
function n=LOCAL_norm(c)
  n=sum(abs(real(c))+abs(imag(c)),'all');
end
function a=LOCAL_cut(a)
  [i,j]=ndgrid(0:size(a.c,1)-1,0:size(a.c,2)-1);drop=i+j>12;a.e=a.e+LOCAL_norm(a.c.*drop);a.c(drop)=0;
  a.c=a.c(1:min(13,end),1:min(13,size(a.c,2)));
end
