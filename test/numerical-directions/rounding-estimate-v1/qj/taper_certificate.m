function r=taper_certificate(G,e,cell_index,U,px,py,rho,lo,hi,s,tol,include_S)
  % TAPER_CERTIFICATE Integrate an analytic native taper branch with remainders.
  % Input
  %   Geometry, cubic field and RT3 raw flux polynomials; positive determinant bounds.
  % Output
  %   Two-sided E/M and optional common-native-fitted residual bounds.
  mx=G.mx(e,:);my=G.my(e,:);X=[mx(1),mx(3),mx(6);mx(2),mx(5),0;mx(4),0,0];
  J={ [mx(2),mx(5);2*mx(4),0],[mx(3),2*mx(6);mx(5),0], ...
    [my(2),my(5);2*my(4),0],[my(3),2*my(6);my(5),0]};
  den=LOCAL_add(conv2(J{1},J{4}),-conv2(J{2},J{3}));
  phi=LOCAL_make(X*sign(cell_index)*pi/2);phi.c(1)=phi.c(1)+pi/2*(abs(cell_index)-11.5);
  chi=poly2('cos',phi,12);chi.c(1)=chi.c(1)+1;chi=LOCAL_scale(chi,.5);
  dchi=LOCAL_scale(poly2('sin',phi,12),-pi/4*sign(cell_index));[ux,uy]=LOCAL_grad(U);
  V=poly2('mul',chi,LOCAL_make(U));dU=poly2('mul',dchi,LOCAL_make(U));
  hx=poly2('add',poly2('mul',chi,LOCAL_make(ux)),poly2('mul',dU,LOCAL_make(J{1})));
  hy=poly2('add',poly2('mul',chi,LOCAL_make(uy)),poly2('mul',dU,LOCAL_make(J{2})));
  gx=poly2('add',poly2('mul',LOCAL_make(J{4}),hx),LOCAL_scale(poly2('mul',LOCAL_make(J{3}),hy),-1));
  gy=poly2('add',LOCAL_scale(poly2('mul',LOCAL_make(J{2}),hx),-1),poly2('mul',LOCAL_make(J{1}),hy));
  num=poly2('add',LOCAL_abs2(gx),LOCAL_abs2(gy));er=poly2('rational_triangle',num.c,den,lo,hi,tol);
  r=struct('E',er.value,'E_error',tol+.5*num.e/lo,'M',0,'M_error',0,'S',0,'S_error',0);
  mass=LOCAL_scale(poly2('mul',LOCAL_abs2(V),LOCAL_make(den)),rho);r.M=real(poly2('triangle',mass.c));r.M_error=.5*mass.e;
  if include_S
    apx=LOCAL_add(conv2(J{1},px),conv2(J{2},py));apy=LOCAL_add(conv2(J{3},px),conv2(J{4},py));
    r1=poly2('add',LOCAL_make(apx),LOCAL_scale(gx,-1/s));r2=poly2('add',LOCAL_make(apy),LOCAL_scale(gy,-1/s));
    [dx,~]=LOCAL_grad(px);[~,dy]=LOCAL_grad(py);dv=LOCAL_add(dx,dy);
    r3=poly2('add',LOCAL_make(dv),LOCAL_scale(poly2('mul',V,LOCAL_make(den)),rho*(1-1/s)));
    num=poly2('add',poly2('add',LOCAL_abs2(r1),LOCAL_abs2(r2)),LOCAL_scale(LOCAL_abs2(r3),1/rho));
    sr=poly2('rational_triangle',num.c,den,lo,hi,1e-21);r.S=sr.value;r.S_error=1e-21+.5*num.e/lo;
  end
end
function a=LOCAL_make(c)
  a=struct('c',c,'e',0);
end
function a=LOCAL_scale(a,k)
  a.c=a.c*k;a.e=a.e*abs(k);
end
function a=LOCAL_abs2(a)
  b=a;b.c=conj(b.c);a=poly2('mul',a,b);
end
function c=LOCAL_add(a,b)
  c=zeros(max(size(a,1),size(b,1)),max(size(a,2),size(b,2)));c(1:size(a,1),1:size(a,2))=a;c(1:size(b,1),1:size(b,2))=c(1:size(b,1),1:size(b,2))+b;
end
function [x,y]=LOCAL_grad(a)
  x=zeros(max(1,size(a,1)-1),size(a,2));y=zeros(size(a,1),max(1,size(a,2)-1));
  for i=2:size(a,1),x(i-1,:)=(i-1)*a(i,:);end;for j=2:size(a,2),y(:,j-1)=(j-1)*a(:,j);end
end
