function C=interface_model(G,T,e,box,kind)
% Source: test/fem-goerisch/pipeline-v1/internal/interface_model.m. Copied numerical algorithm.
  % INTERFACE_MODEL Certify a native inverse on a fitted or homotopy chart.
  % Input
  %   box=[r0 r1 t0 t1]; kind='fitted' or 'sliver' (r is sliver w).
  % Output
  %   Polynomial geometry, native inverse, and contraction/defect certificates.
  k=find(T.interface.inner==e,1);if isempty(k),k=find(T.interface.outer==e,1);end
  theta=T.interface.theta(k);dt=T.interface.dtheta;curve=curve_model(T.curve,theta,dt,T.curve_order);
  verts=T.xy(T.tri6(e,1:3),:);[~,a]=min(sum((verts-curve.p0).^2,2));[~,b]=min(sum((verts-curve.p1).^2,2));o=6-a-b;
  make=@(x)pm('make',x,0);add=@(x,y)pm('add',x,y);sub=@(x,y)pm('sub',x,y);mul=@(x,y)pm('mul',x,y);sc=@(x,z)pm('scale',x,z);
  r=make([mean(box(1:2));diff(box(1:2))/2]);t=make([mean(box(3:4)),diff(box(3:4))/2]);one=make(1);
  l=cell(1,3);l(:)={make(0)};
  if strcmp(kind,'fitted'),l{a}=mul(r,sub(one,t));l{b}=mul(r,t);l{o}=sub(one,r);
  else,l{a}=sub(one,t);l{b}=t;l{o}=make(0);end
  x=l{2};y=l{3};z=sc(t,2);z.c(1)=z.c(1)-1;
  dc=pm('polyval',curve.d.c, z,make(0));dc.e=dc.e+curve.d.e;
  ddc=pm('polyval',curve.dd.c,z,make(0));ddc.e=ddc.e+curve.dd.e;
  mx=G.mx(e,:);my=G.my(e,:);fx=LOCAL_geom_poly(mx);fy=LOCAL_geom_poly(my);
  X0=pm('polyval',fx,x,y);Y0=pm('polyval',fy,x,y);power=r;if strcmp(kind,'fitted'),power=mul(mul(r,r),r);end
  DX=mul(power,pm('real',dc));DY=mul(power,pm('imag',dc));X=add(X0,DX);Y=add(Y0,DY);
  % Constant-centered cube certificate from Lemma 4.3.
  y0=[x.c(1);y.c(1)];bx=pm('range',x);by=pm('range',y);R=1.4*max(abs([bx-y0(1),by-y0(2)]))+.002;
  J0=LOCAL_J(mx,my,y0(1),y0(2));B=inv(J0);kappa=0;
  for v=[-1,-1;-1,1;1,-1;1,1].',u=y0+R*v;kappa=max(kappa,norm(eye(2)-B*LOCAL_J(mx,my,u(1),u(2)),Inf));end
  f0=[LOCAL_eval(mx,y0);LOCAL_eval(my,y0)];rhs=0;
  for j=1:2
    v=add(sc(X,-B(j,1)),sc(Y,-B(j,2)));v.c(1)=v.c(1)+B(j,:)*f0;rg=pm('range',v);rhs=max(rhs,max(abs(rg)));
  end
  assert(kappa<1&&(1-kappa)*R>=rhs,'iface:Contraction','Parameter panel needs subdivision');
  % Polynomial guesses are truncated freely; the final defect certifies them.
  xx=x;yy=y;
  for n=1:inverse_iteration_count()
    rx=sub(pm('polyval',fx,xx,yy),X);ry=sub(pm('polyval',fy,xx,yy),Y);
    xx=pm('strip',sub(xx,add(sc(rx,B(1,1)),sc(ry,B(1,2)))));
    yy=pm('strip',sub(yy,add(sc(rx,B(2,1)),sc(ry,B(2,2)))));
  end
  rx=sub(pm('polyval',fx,xx,yy),X);ry=sub(pm('polyval',fy,xx,yy),Y);er=0;
  for j=1:2,v=add(sc(rx,B(j,1)),sc(ry,B(j,2)));er=max(er,pm('norm',v));end
  er=er/(1-kappa);bx=pm('range',xx);by=pm('range',yy);
  assert(all([bx(1),by(1)]-er>=y0.'-R)&&all([bx(2),by(2)]+er<=y0.'+R),'iface:Guess','Inverse polynomial leaves its cube');
  Bglobal=inv(LOCAL_J(mx,my,1/3,1/3));kg=0;
  for v=[-2/3,-2/3;-2/3,4/3;4/3,-2/3;4/3,4/3].',kg=max(kg,norm(eye(2)-Bglobal*LOCAL_J(mx,my,v(1),v(2)),Inf));end
  assert(kg<1&&all([bx(1),by(1)]-er>=-2/3)&&all([bx(2),by(2)]+er<=4/3),'iface:Unique','Inverse charts lack a common injective domain');
  actual_margin=NaN;
  if strcmp(kind,'sliver')
    kh=0;for v=[0,0;1,0;0,1].',kh=max(kh,norm(eye(2)-B*LOCAL_J(mx,my,v(1),v(2)),Inf));end
    bx0=pm('range',x);by0=pm('range',y);edge_margin=min([bx0(1)-y0(1)+R,by0(1)-y0(2)+R,y0(1)+R-bx0(2),y0(2)+R-by0(2)]);
    C3=T.curve.C3;
    D0=min(curve.D0,dt^3*C3/(72*sqrt(3)));actual_margin=edge_margin-norm(B,Inf)*D0/(1-kh);
    assert(kh<1&&actual_margin>0,'iface:ActualRoot','Actual native inverse may be outside the retained cube');
  end
  xx.e=er;yy.e=er;A=LOCAL_Jmodels(mx,my,x,y);
  if strcmp(kind,'fitted')
    dl=[-1,-1;1,0;0,1];RR=dl(a,:)+dl(b,:);LL=dl(b,:);r2=mul(r,r);
    for j=1:2
      dir=sub(make(LL(j)),sc(t,RR(j)));v=mul(r2,add(sc(dc,3*RR(j)),mul(ddc,dir)));
      A{j}=add(A{j},pm('real',v));A{j+2}=add(A{j+2},pm('imag',v));
    end
  end
  det=LOCAL_det(A);invdet=pm('reciprocal',det);J=LOCAL_Jmodels(mx,my,xx,yy);ndet=LOCAL_det(J);ninv=pm('reciprocal',ndet);
  C=struct('x',x,'y',y,'r',r,'t',t,'X',X,'Y',Y,'native_x',xx,'native_y',yy,'A',{A},'det',det,'invdet',invdet,'J',{J},'native_invdet',ninv, ...
    'kappa',kappa,'margin',(1-kappa)*R-rhs,'inverse_error',er,'global_unique_kappa',kg,'actual_branch_margin',actual_margin,'scale',diff(box(1:2))*diff(box(3:4))/4,'kind',kind,'arc',k);
end
function c=LOCAL_geom_poly(a)
  % LOCAL_geom_poly Geom poly.
  % Input
  %   a.
  % Output
  %   c.
  c=[a(1),a(3),a(6);a(2),a(5),0;a(4),0,0];
end
function J=LOCAL_J(mx,my,x,y)
  % LOCAL_J J.
  % Input
  %   mx,my,x,y.
  % Output
  %   J.
  J=[mx(2)+2*mx(4)*x+mx(5)*y,mx(3)+mx(5)*x+2*mx(6)*y;my(2)+2*my(4)*x+my(5)*y,my(3)+my(5)*x+2*my(6)*y];
end
function v=LOCAL_eval(a,x)
  % LOCAL_eval Eval.
  % Input
  %   a,x.
  % Output
  %   v.
  v=[1,x(1),x(2),x(1)^2,x(1)*x(2),x(2)^2]*a.';
end
function J=LOCAL_Jmodels(mx,my,x,y)
  % LOCAL_Jmodels Jmodels.
  % Input
  %   mx,my,x,y.
  % Output
  %   J.
  J=cell(1,4);n=0;
  for a={mx,my}
    c=a{1};n=n+1;J{2*n-1}=pm('add',pm('make',c(2)),pm('add',pm('scale',x,2*c(4)),pm('scale',y,c(5))));
    J{2*n}=pm('add',pm('make',c(3)),pm('add',pm('scale',x,c(5)),pm('scale',y,2*c(6))));
  end
end
function d=LOCAL_det(J)
  % LOCAL_det Det.
  % Input
  %   J.
  % Output
  %   d.
  d=pm('sub',pm('mul',J{1},J{4}),pm('mul',J{2},J{3}));
end
