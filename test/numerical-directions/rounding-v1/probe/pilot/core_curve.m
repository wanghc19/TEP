function varargout=core_curve(action,varargin)
% Core true analytic star and its divergence-theorem moment enclosures.
% Input: 'curve', theta; or 'moments',a,b,offset,node count.
% Output: physical curve/derivatives, or exponential moments and error bounds.
  if strcmp(action,'curve'),[varargout{1:nargout}]=LOCAL_curve(varargin{:});return;end
  assert(strcmp(action,'moments'));[varargout{1:nargout}]=LOCAL_moments(varargin{:});
end
function [x,y,dx,dy]=LOCAL_curve(t)
  % Same orientation and scale as FEM cell_index=0, star_scale=1.
  c=cos(5*t);s=sin(5*t);x=.2*(1.5+.3*c).*cos(t);y=.2*(1+.3*c).*sin(t);
  dx=.2*(-1.5*s.*cos(t)-(1.5+.3*c).*sin(t));dy=.2*(-1.5*s.*sin(t)+(1+.3*c).*cos(t));
end
function [v,error]=LOCAL_moments(a,b,offset,J)
  a=a(:);b=b(:);offset=offset(:);assert(numel(a)==numel(b)&&numel(a)==numel(offset));
  t=(0:J-1)'*(2*pi/J);[x,y,dx,dy]=LOCAL_curve(t);v=complex(zeros(size(a)));error=zeros(size(a));h=.1;
  xr=.3*cosh(h)+.03*(cosh(6*h)+cosh(4*h));xi=.3*sinh(h)+.03*(sinh(6*h)+sinh(4*h));
  yr=.2*cosh(h)+.03*(cosh(6*h)+cosh(4*h));yi=.2*sinh(h)+.03*(sinh(6*h)+sinh(4*h));
  xd=.3*cosh(h)+.03*(6*cosh(6*h)+4*cosh(4*h));yd=.2*cosh(h)+.03*(6*cosh(6*h)+4*cosh(4*h));
  for first=1:128:numel(a)
    ids=first:min(first+127,numel(a));aa=a(ids).';bb=b(ids).';off=offset(ids).';
    f=exp(x*aa+y*bb+off);z=zeros(size(aa));g=zeros(size(aa));usea=abs(aa)>=abs(bb)&aa~=0;useb=~usea&bb~=0;zero=aa==0&bb==0;
    z(usea)=(dy'*f(:,usea))./aa(usea)*(2*pi/J);g(usea)=yd./abs(aa(usea));
    z(useb)=-(dx'*f(:,useb))./bb(useb)*(2*pi/J);g(useb)=xd./abs(bb(useb));
    z(zero)=pi*.04*(1.5+.3^2/2)*exp(off(zero));
    growth=abs(real(aa))*xr+abs(imag(aa))*xi+abs(real(bb))*yr+abs(imag(bb))*yi+off;
    v(ids)=z;error(ids)=4*pi*g.*exp(growth)/expm1(h*J);
  end
end
