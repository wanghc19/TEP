function F=interface_fields(C,G,e,cell_id,s)
  % INTERFACE_FIELDS Evaluate one native branch model at a physical chart.
  % Input
  %   Certified inverse chart C, cubic field data G, element/cell and fixed s.
  % Output
  %   v, gradient models including the original physical taper.
  add=@(a,b)pm('add',a,b);sub=@(a,b)pm('sub',a,b);mul=@(a,b)pm('mul',a,b);sc=@(a,b)pm('scale',a,b);
  U=LOCAL_U(G,e,cell_id);[ux,uy]=LOCAL_grad(U);
  v=pm('polyval',U,C.native_x,C.native_y);ux=pm('polyval',ux,C.native_x,C.native_y);uy=pm('polyval',uy,C.native_x,C.native_y);
  gx=mul(sub(mul(C.J{4},ux),mul(C.J{3},uy)),C.native_invdet);
  gy=mul(add(sc(mul(C.J{2},ux),-1),mul(C.J{1},uy)),C.native_invdet);
  if abs(G.cells(cell_id))>=12
    phi=sc(C.X,sign(G.cells(cell_id))*pi/2);phi.c(1)=phi.c(1)+pi/2*(abs(G.cells(cell_id))-11.5);
    chi=pm('cos',phi);chi.c(1)=chi.c(1)+1;chi=sc(chi,.5);dchi=sc(pm('sin',phi),-pi/4*sign(G.cells(cell_id)));
    gx=add(mul(chi,gx),mul(dchi,v));gy=mul(chi,gy);v=mul(chi,v);
  end
  F=struct('v',v,'gx',gx,'gy',gy);
end
function U=LOCAL_U(G,e,j)
  c=G.field_coefficients(e,:,j);U=zeros(4);n=0;for d=0:3,for k=0:d,n=n+1;U(d-k+1,k+1)=c(n);end,end
end
function [x,y]=LOCAL_grad(a)
  x=zeros(max(1,size(a,1)-1),size(a,2));y=zeros(size(a,1),max(1,size(a,2)-1));for i=2:size(a,1),x(i-1,:)=(i-1)*a(i,:);end;for j=2:size(a,2),y(:,j-1)=(j-1)*a(:,j);end
end
