function B=dtn_bounds(C)
% Source: test/numerical-directions/h-dtn-v1/dtn_bounds.m. Numerical method retained.
% DtN means Dirichlet-to-Neumann: complex fitted-map geometry bounds.
% Input: fitted cell. Output: Jacobian bounds on product Bernstein ellipses 2.
  D=C.F.data;nt=D.nt;B=struct('eta',zeros(nt,1),'eta_physical',zeros(nt,1),'det_lower',zeros(nt,1),'det_upper',zeros(nt,1),'inverse',zeros(nt,1),'jacobian',zeros(nt,1),'displacement',zeros(nt,1),'collar_clearance',inf);
  dl=[-1,-1;1,0;0,1];rm=1.125;tm=1.125;zm=.625;aa=.12;if strcmp(C.side,'right'),aa=.20;end
  R=.2/sqrt(1+aa^2/2);freq=[1,2,4];amp=R*[1,aa/2,aa/2];delta=0;derivative=0;
  for j=1:3
    z=freq(j)*D.dt;delta=delta+amp(j)*(LOCAL_tail(z*zm,3)+4*zm*tm*LOCAL_tail(z*.5,3));
    derivative=derivative+amp(j)*(z*LOCAL_tail(z*zm,2)+(8*zm+2)*LOCAL_tail(z*.5,3));
  end
  for e=1:nt
    v=C.T.xy(C.T.tri6(e,1:3),:);A=(v(2:3,:)-v(1,:))';detA=det(A);assert(detA>0);invA=inv(A);eta=0;phys=0;disp=0;
    if D.a(e)>0
      a=D.a(e);b=D.b(e);t=D.theta(e)+D.dt/2;r=R*(1+aa*cos(3*t));mid=r*[cos(t),sin(t)];off=mid-(v(a,:)+v(b,:))/2;
      da=dl(a,:);db=dl(b,:);ds=da+db;
      eta=4*norm(invA*off',inf)*rm*tm*(norm(da,1)+norm(db,1))+rm^2*norm(invA,inf)*(3*delta*norm(ds,1)+derivative*(norm(db,1)+tm*norm(ds,1)));
      phys=4*norm(off,inf)*rm*tm*(norm(da*invA,1)+norm(db*invA,1))+rm^2*(3*delta*norm(ds*invA,1)+derivative*(norm(db*invA,1)+tm*norm(ds*invA,1)));
      disp=4*(rm*tm)^2*norm(off,inf)+rm^3*delta;
      clearance=min(C.sigma*(v(:,1)-C.near))-disp-.125;B.collar_clearance=min(B.collar_clearance,clearance);
      assert(clearance>0,'dtn:Collar','Curved cells intersect the trace-correction strip.');
    end
    assert(max(eta,phys)<1,'dtn:Geometry','Complex geometry deformation is too large.');
    B.eta(e)=eta;B.eta_physical(e)=phys;B.det_lower(e)=detA*(1-eta)^2;B.det_upper(e)=detA*(1+eta)^2;B.inverse(e)=norm(invA,inf)/(1-eta);B.jacobian(e)=norm(A,inf)*(1+eta);B.displacement(e)=disp;
  end
end
function v=LOCAL_tail(z,start)
  term=1;v=0;
  for j=1:40,term=term*z/j;if j>=start,v=v+term;end,end
  next=term*z/41;v=v+next/(1-z/42);
end
