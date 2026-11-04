function R=interface_residual(C,F,raw,rho,s)
  % INTERFACE_RESIDUAL Form small residual numerators before squaring.
  % Input
  %   Fitted chart C, one native branch F, raw RT3 flux coefficients, rho, s.
  % Output
  %   Residual density model and physical residual component suprema.
  add=@(a,b)pm('add',a,b);sub=@(a,b)pm('sub',a,b);mul=@(a,b)pm('mul',a,b);sc=@(a,b)pm('scale',a,b);
  [px,py,dv]=LOCAL_flux(raw);px=pm('polyval',px,C.x,C.y);py=pm('polyval',py,C.x,C.y);dv=pm('polyval',dv,C.x,C.y);
  a=sub(add(mul(C.A{1},px),mul(C.A{2},py)),sc(mul(C.det,F.gx),1/s));
  b=sub(add(mul(C.A{3},px),mul(C.A{4},py)),sc(mul(C.det,F.gy),1/s));
  c=add(dv,sc(mul(C.det,F.v),rho*(1-1/s)));
  global ROUNDING_ZETA;
  big1=pm('norm',mul(C.A{1},px))+pm('norm',mul(C.A{2},py))+pm('norm',sc(mul(C.det,F.gx),1/s));
  big2=pm('norm',mul(C.A{3},px))+pm('norm',mul(C.A{4},py))+pm('norm',sc(mul(C.det,F.gy),1/s));
  big3=(pm('norm',dv)+pm('norm',sc(mul(C.det,F.v),rho*(1-1/s))))/sqrt(rho);
  ROUNDING_ZETA=ROUNDING_ZETA+4*C.scale*pm('norm',C.r)*pm('norm',C.invdet)^2*(big1^2+big2^2+big3^2);
  square=@(x)mul(x,pm('conj',x));num=add(add(square(a),square(b)),sc(square(c),1/rho));
  density=mul(mul(C.r,C.invdet),num);it=pm('integral',density);it.value=it.value*C.scale;it.error=it.error*C.scale;
  bounds=[pm('norm',mul(a,C.invdet)),pm('norm',mul(b,C.invdet)),pm('norm',mul(sc(c,1/sqrt(rho)),C.invdet))];
  R=struct('integral',it,'bounds',bounds);
end
function [x,y,dv]=LOCAL_flux(c)
  x=zeros(5);y=x;n=0;for d=0:3,for k=0:d,n=n+1;x(d-k+1,k+1)=c(n);y(d-k+1,k+1)=c(10+n);end,end
  for k=0:3,x(5-k,k+1)=c(21+k);y(4-k,k+2)=c(21+k);end
  dx=zeros(4,5);dy=zeros(5,4);for i=2:5,dx(i-1,:)=(i-1)*x(i,:);end;for j=2:5,dy(:,j-1)=(j-1)*y(:,j);end
  dv=zeros(5);dv(1:4,:)=dx;dv(:,1:4)=dv(:,1:4)+dy;
end
