function C=curve_model(curve,theta,dt,L)
% Source: test/fem-goerisch/pipeline-v1/internal/curve_model.m. Copied numerical algorithm.
  % CURVE_MODEL Polynomial in z=2u-1 plus a uniform complex curve remainder.
  % Input
  %   curve: explicit finite Fourier definition; theta,dt: arc; L: Taylor order.
  % Output
  %   Exact-input Taylor models for c, c_u, the quadratic edge and its defect.
  omega=curve.omega;amp=curve.amp;
  mid=theta+dt/2;c=zeros(L+1,1);dc=c;
  for n=0:L
    c(n+1)=sum(amp.*exp(1i*omega*mid).*(1i*omega*dt/2).^n)/factorial(n);
    dc(n+1)=sum(amp.*exp(1i*omega*mid).*(1i*omega*dt).*(1i*omega*dt/2).^n)/factorial(n);
  end
  err=sum(abs(amp).*(abs(omega)*dt/2).^(L+1))/factorial(L+1);
  derr=sum(abs(amp.*omega)*dt.*(abs(omega)*dt/2).^(L+1))/factorial(L+1);
  eval=@(th)sum(amp.*exp(1i*omega*th));p0=eval(theta);pm=eval(mid);p1=eval(theta+dt);
  q=[pm;(p1-p0)/2;(p0+p1)/2-pm];dq=[p1-p0;2*(p0+p1-2*pm)];
  d=c;d(1:3)=d(1:3)-q;dd=dc;dd(1:2)=dd(1:2)-dq;
  C=struct('c',poly2('make',c,err),'dc',poly2('make',dc,derr),'q',poly2('make',q,0),'dq',poly2('make',dq,0), ...
    'd',poly2('make',d,err),'dd',poly2('make',dd,derr),'D0',sum(abs(real(d))+abs(imag(d)))+err, ...
    'D1',sum(abs(real(dd))+abs(imag(dd)))+derr,'Q1',sum(abs(real(dq))+abs(imag(dq))), ...
    'p0',[real(p0),imag(p0)],'p1',[real(p1),imag(p1)]);
end
