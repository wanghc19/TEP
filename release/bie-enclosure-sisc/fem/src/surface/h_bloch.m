function h_bloch(out,a,lambda,N,Ntheta,Jcurve,certificate)
% Source: test/numerical-directions/h-cert-v1/h_bloch.m. Numerical method retained.
% H means hypothesis: analytic-curve moments for Bloch endpoint responses.
% Input: output directory, material, endpoint, Fourier order, phase count,
% analytic-curve trapezoid count; optional [trial degree, phase order,
% second-Poisson flag]. Output: small JSON, no saved field arrays.
  if nargin>6
    LOCAL_certificate(out,a,lambda,N,Ntheta,Jcurve,certificate);return
  end
  maxNumCompThreads(11);if ~exist(out,'dir'),mkdir(out);end;timer=tic;
  k=(-10:10)';beta=.5+2*pi*k;q=sqrt(1+beta.^2);kap=sqrt(beta.^2-lambda);kap(k==0)=q(k==0);amp=sqrt(q)./(2*kap);p=numel(k);
  [m,n]=ndgrid(-N:N,-N:N);m=m(:);n=n(:);by=.5+2*pi*n;
  [X,curve]=LOCAL_geometry(a,N,m,n,beta,kap,Jcurve);Mr=eye(numel(m))+16*X;
  d=min(lambda-1.318^2,2.375^2-lambda);K=1+(lambda+1)/d;
  C=zeros(p);G=zeros(p);H=zeros(p);U=zeros(p);sym=0;lowmax=0;minfiber=inf;cancel=0;
  for it=1:Ntheta
    theta=-pi+(it-.5)*2*pi/Ntheta;D=(2*pi*m+theta).^2+by.^2;L=diag(D)-lambda*Mr;
    [IT,TT,Tcoef,Tbg]=LOCAL_sources(theta,m,n,k,kap,q,amp,curve);
    F=16*lambda*IT;F(:,k==0)=F(:,k==0)+(lambda+1)*Tcoef(:,k==0);
    Z=L\F;delta=F-L*Z;
    [J,G0,G1,GU,cancellation]=LOCAL_grams(Z,D,X,IT,TT,Tcoef,Tbg,lambda,k);
    dtail=min((2*pi*(N+1)-abs(theta))^2+.25,theta^2+(2*pi*(N+1)-.5)^2);
    HH=G0/dtail+delta'*((1./D-1/dtail).*delta);
    C=C+(16*lambda*TT+J)/Ntheta;G=G+G1/Ntheta;H=H+HH/Ntheta;U=U+GU/Ntheta;
    sym=max(sym,norm(J-J','fro')/max(norm(J,'fro'),realmin));lowmax=max(lowmax,norm(delta,'fro')/max(norm(F,'fro'),realmin));
    cancel=max(cancel,cancellation);minfiber=min(minfiber,min(abs(eig(L))));
    if mod(it,16)==0,fprintf('analytic phase %d/%d elapsed %.1f s\n',it,Ntheta,toc(timer));end
  end
  C=C+diag(q./(2*kap));C(k==0,k==0)=C(k==0,k==0)+(lambda+1)/(4*q(k==0)^2);
  C=(C+C')/2;G=(G+G')/2;H=(H+H')/2;U=(U+U')/2;E=K*H;
  rec=struct('material',a,'lambda',lambda,'N',N,'Ntheta',Ntheta,'curve_points',Jcurve,'dimension',numel(m), ...
    'd_per',d,'time_seconds',toc(timer),'form_inverse',K,'hermitian_defect',sym,'low_residual_relative',lowmax, ...
    'fiber_min_abs',minfiber,'gram_cancellation_ratio',cancel,'error_norm',norm(E), ...
    'weighted_residual_norm',sqrt(max(eig(G))),'unweighted_dual_norm',sqrt(max(eig(H))), ...
    'original_volume_error_norm',norm(G)/d,'residual_min_eigenvalue',min(eig(G)),'dual_min_eigenvalue',min(eig(H)), ...
    'C_real',real(C),'C_imag',imag(C),'E_real',real(E),'E_imag',imag(E),'G_real',real(G),'G_imag',imag(G), ...
    'U_real',real(U),'U_imag',imag(U));
  rec.tests=h_endpoint(C,E,U,H,lambda,d);f=fopen(fullfile(out,'result.json'),'w');fprintf(f,'%s\n',jsonencode(rec));fclose(f);
  fprintf('analytic done %.2f %.7f E %.8g time %.1f\n',a,lambda,norm(E),toc(timer));disp(rec.tests);
end

function [X,c]=LOCAL_geometry(a,N,m,n,beta,kap,J)
  t=(0:J-1)'*2*pi/J;r=.2/sqrt(1+a*a/2)*(1+a*cos(3*t));dr=-.6*a/sqrt(1+a*a/2)*sin(3*t);
  x=.5+r.*cos(t);y=r.*sin(t);dx=dr.*cos(t)-r.*sin(t);dy=dr.*sin(t)+r.*cos(t);
  [dm,dn]=ndgrid(-2*N:2*N,-2*N:2*N);uv=dm(:);vv=dn(:);f=zeros(numel(uv),1);
  for start=1:256:numel(uv)
    ix=start:min(start+255,numel(uv));u=uv(ix)';v=vv(ix)';e=exp(2i*pi*(x*u+y*v));z=zeros(1,numel(ix));
    first=u~=0;z(first)=sum(dy.*e(:,first),1)./(2i*pi*u(first))*2*pi/J;
    second=~first & v~=0;z(second)=-sum(dx.*e(:,second),1)./(2i*pi*v(second))*2*pi/J;
    z(~first & ~second)=.04*pi;f(ix)=z;
  end
  ind=sub2ind(size(dm),m'-m+2*N+1,n'-n+2*N+1);X=f(ind);X=(X+X')/2;
  c=struct('x',x,'y',y,'dx',dx*2*pi/J,'dy',dy*2*pi/J,'E',exp(1i*(2*pi*x*m'+y*(.5+2*pi*n)')));
  S=[exp(-x*kap').*exp(1i*y*beta'),exp(-(1-x)*kap').*exp(1i*y*beta')];
  rates=[-kap;kap];bb=[beta;beta];sx=rates+rates';sy=1i*(bb'-bb);
  A=S'*(c.dy.*S);B=S'*(c.dx.*S);H=zeros(size(A));first=abs(sx)>1e-12;H(first)=A(first)./sx(first);
  second=~first & abs(sy)>1e-12;H(second)=-B(second)./sy(second);
  zero=~first & ~second;Scenter=[exp(-.5*kap);exp(-.5*kap)];cc=Scenter*Scenter';H(zero)=.04*pi*cc(zero);
  c.S=S;c.H=(H+H')/2;
end

function [IT,TT,coef,bg]=LOCAL_sources(theta,m,n,k,kap,q,amp,c)
  plus=amp./(1-exp(-kap-1i*theta));minus=amp*exp(1i*theta)./(1-exp(-kap+1i*theta));
  p=numel(k);Sc=[diag(plus);diag(minus)];V=c.S.*exp(-1i*theta*c.x);
  A=c.E'*(c.dy.*V);den=[-kap',kap']-1i*(2*pi*m+theta);
  IT=(A./den)*Sc;TT=Sc'*c.H*Sc;
  coef=zeros(numel(m),p);D=(2*pi*m+theta).^2;
  for j=1:p,rows=n==k(j);coef(rows,j)=sqrt(q(j))./(D(rows)+kap(j)^2);end
  diagonal=(-expm1(-2*kap))./(2*kap).*(abs(plus).^2+abs(minus).^2)+2*exp(-kap).*real(conj(plus).*minus);
  bg=diag(diagonal);TT=(TT+TT')/2;
end

function [J,G0,G1,U,ratio,defect]=LOCAL_grams(Z,D,X,IT,TT,Tcoef,Tbg,lambda,k,XZ,XA)
  p=numel(k);b0=zeros(p);b0(k==0,k==0)=lambda+1;ds=16*lambda*eye(p)+b0;
  A=-(D-lambda).*Z;B=A+16*lambda*Z;
  if nargin<10,XZ=X*Z;XA=X*A;end
  XB=XA+16*lambda*XZ;
  bg=A'*A+A'*Tcoef*b0+b0*Tcoef'*A+b0*Tbg*b0;
  i0=A'*XA+A'*IT*b0+b0*IT'*A+b0*TT*b0;
  i1=B'*XB+B'*IT*ds+ds*IT'*B+ds*TT*ds;
  G0=bg-i0+i1;G1=bg-i0+i1/17;
  F=16*lambda*IT+Tcoef*b0;
  J=F'*Z+Z'*F-Z'*(D.*Z-lambda*(Z+16*XZ));
  U=Tbg+Z'*Z+Z'*Tcoef+Tcoef'*Z+16*(TT+Z'*XZ+Z'*IT+IT'*Z);
  defect=norm(G1-G1','fro')/max(norm(G1,'fro'),realmin);
  G0=(G0+G0')/2;G1=(G1+G1')/2;U=(U+U')/2;
  ratio=(norm(bg)+norm(i0)+norm(i1))/max(norm(G0),realmin);
end

function LOCAL_certificate(out,a,lambda,N,panels,Jcurve,cfg)
  % Polynomial response trials make phase integration independently enclosable.
  maxNumCompThreads(11);if ~exist(out,'dir'),mkdir(out);end;timer=tic;
  degree=cfg(1);order=cfg(2);poisson2=numel(cfg)>2 && cfg(3)>0;k=(-10:10)';beta=.5+2*pi*k;q=sqrt(1+beta.^2);
  kap=sqrt(beta.^2-lambda);kap(k==0)=q(k==0);amp=sqrt(q)./(2*kap);p=numel(k);
  [m,n]=ndgrid(-N:N,-N:N);m=m(:);n=n(:);by=.5+2*pi*n;nd=numel(m);
  [X,curve]=LOCAL_geometry(a,N,m,n,beta,kap,Jcurve);Mr=eye(nd)+16*X;
  [Xhigh,chigh]=LOCAL_geometry(a,N,m,n,beta,kap,2*Jcurve);
  curve_check_X=norm(X-Xhigh,'fro');curve_check_IT=0;curve_check_TT=0;
  for th=[-pi,0,pi]
    [IT0,TT0]=LOCAL_sources(th,m,n,k,kap,q,amp,curve);
    [IT1,TT1]=LOCAL_sources(th,m,n,k,kap,q,amp,chigh);
    curve_check_IT=max(curve_check_IT,norm(IT0-IT1,'fro'));curve_check_TT=max(curve_check_TT,norm(TT0-TT1,'fro'));
  end
  clear Xhigh chigh IT0 IT1 TT0 TT1
  d=min(lambda-1.318^2,2.375^2-lambda);K=1+(lambda+1)/d;
  nodes=cos((0:degree)'*pi/degree);V=nodes.^(0:degree);[tq,wq]=LOCAL_gauss(order);[tcheck,wcheck]=LOCAL_gauss(max(12,order-16));
  C=zeros(p);G=zeros(p);H=zeros(p);U=zeros(p);Ccheck=C;Gcheck=G;Hcheck=H;Ucheck=U;V2=zeros(p);Vcheck=V2;epsV=0;epsC=0;epsH=0;epsU=0;epsG=0;
  symC=0;symG=0;lowmax=0;cancel=0;boundZ=0;boundR=0;curve_error=0;
  panel_table=zeros(panels,8);half=pi/panels;ellipse=2;R=(ellipse+1/ellipse)/2;strip=half*(ellipse-1/ellipse)/2;
  factor=8/(1-1/ellipse)*ellipse^(-2*order);
  Cim=.2/sqrt(1+a*a/2)*(sinh(.1)+a/2*(sinh(.4)+sinh(.2)));
  moment_error=4*pi*100*exp((8*pi*N+4*pi*10+10)*Cim)/expm1(.1*Jcurve);
  for panel=1:panels
    center=-pi+(panel-.5)*2*pi/panels;Dc=(2*pi*m+center).^2+by.^2;Dl=2*(2*pi*m+center)*half;
    zn=zeros(degree+1,nd*p);
    for j=1:degree+1
      theta=center+half*nodes(j);D=(2*pi*m+theta).^2+by.^2;
      [IT,~,Tc,~]=LOCAL_sources(theta,m,n,k,kap,q,amp,curve);
      F=16*lambda*IT;F(:,k==0)=F(:,k==0)+(lambda+1)*Tc(:,k==0);
      L=diag(D)-lambda*Mr;Z=L\F;zn(j,:)=Z(:).';lowmax=max(lowmax,norm(F-L*Z,'fro')/max(norm(F,'fro'),realmin));
    end
    coeff=V\zn;zc=reshape(coeff.',nd,p,degree+1);xc=zc;xdc=zc;xlc=zc;
    zb=0;
    for j=1:degree+1
      xc(:,:,j)=X*zc(:,:,j);xdc(:,:,j)=X*(Dc.*zc(:,:,j));xlc(:,:,j)=X*(Dl.*zc(:,:,j));
      zb=zb+norm(zc(:,:,j),'fro')*R^(j-1);
    end
    Tbound=norm(exp(strip)*amp.*(1+exp(strip))./(1-exp(-kap+strip)));
    Fbound=(17*lambda+1)*Tbound;
    Dbound=(2*pi*N+abs(center)+half*R)^2+(2*pi*N+.5)^2;
    Lbound=Dbound+17*lambda;rb=Fbound+Lbound*zb;
    dtail=min((2*pi*(N+1)-max(abs(center+[-half,half])))^2+.25, ...
      min(abs(center+[-half,half]))^2+(2*pi*(N+1)-.5)^2);
    % The second denominator is loosened at a panel containing theta=0.
    dtail=min(dtail,(2*pi*(N+1)-.5)^2);
    inverseD=1/(.25-strip^2);
    bc=16*lambda*Tbound^2+2*Fbound*zb+Lbound*zb^2;
    bh=rb^2*(inverseD+2/dtail);bv=rb^2*(inverseD^2+2/dtail^2);bu=17*(Tbound+zb)^2;bg=rb^2;
    A=(nd+p+1)*(1+Lbound+Fbound+zb);ge=moment_error*A^8*(1+inverseD);
    weight=1/panels;
    epsC=epsC+weight*(factor*bc+ge);epsH=epsH+weight*(factor*bh+ge);
    epsV=epsV+weight*(factor*bv+ge*(1+inverseD));
    epsU=epsU+weight*(factor*bu+ge);epsG=epsG+weight*(factor*bg+ge);
    boundZ=max(boundZ,zb);boundR=max(boundR,rb);curve_error=max(curve_error,ge);
    for rule=1:2
      if rule==1,qt=tq;qw=wq;else,qt=tcheck;qw=wcheck;end
    for j=1:numel(qt)
      t=qt(j);theta=center+half*t;D=(2*pi*m+theta).^2+by.^2;
      Z=LOCAL_horner(zc,t);XZ=LOCAL_horner(xc,t);XDZ=LOCAL_horner(xdc,t)+t*LOCAL_horner(xlc,t)+half^2*t^2*XZ;
      XA=-XDZ+lambda*XZ;
      [IT,TT,Tc,Tbg]=LOCAL_sources(theta,m,n,k,kap,q,amp,curve);
      F=16*lambda*IT;F(:,k==0)=F(:,k==0)+(lambda+1)*Tc(:,k==0);
      delta=F-(D.*Z-lambda*(Z+16*XZ));
      [JJ,G0,G1,GU,rr,raw_defect]=LOCAL_grams(Z,D,X,IT,TT,Tc,Tbg,lambda,k,XZ,XA);
      HH=G0/dtail+delta'*((1./D-1/dtail).*delta);
      VV=G0/dtail^2+delta'*((1./D.^2-1/dtail^2).*delta);
      ww=qw(j)/(2*panels);
      if rule==1
        C=C+ww*(16*lambda*TT+JJ);G=G+ww*G1;H=H+ww*HH;U=U+ww*GU;V2=V2+ww*VV;
      else
        Ccheck=Ccheck+ww*(16*lambda*TT+JJ);Gcheck=Gcheck+ww*G1;Hcheck=Hcheck+ww*HH;Ucheck=Ucheck+ww*GU;Vcheck=Vcheck+ww*VV;
      end
      symC=max(symC,norm(JJ-JJ','fro')/max(norm(JJ,'fro'),realmin));symG=max(symG,raw_defect);cancel=max(cancel,rr);
    end
    end
    panel_table(panel,:)=[center,zb,rb,bc,bh,bu,bg,ge];
    if mod(panel,4)==0,fprintf('certificate panel %d/%d elapsed %.1f s\n',panel,panels,toc(timer));end
  end
  C=C+diag(q./(2*kap));C(k==0,k==0)=C(k==0,k==0)+(lambda+1)/(4*q(k==0)^2);
  C=(C+C')/2;G=(G+G')/2;H=(H+H')/2;U=(U+U')/2;
  V2=(V2+V2')/2;E=K*H+(epsC+K*epsH)*eye(p);HU=H+epsH*eye(p);UU=U+epsU*eye(p);VU=V2+epsV*eye(p);
  method='form';
  if poisson2
    coefficient=17*lambda*(1+lambda/d);E=H+coefficient*V2+(epsC+epsH+coefficient*epsV)*eye(p);method='poisson2';
  end
  rec=struct('material',a,'lambda',lambda,'N',N,'phase_panels',panels,'trial_degree',degree,'phase_gauss_order',order, ...
    'curve_points',Jcurve,'curve_check_X',curve_check_X,'curve_check_IT',curve_check_IT,'curve_check_TT',curve_check_TT, ...
    'phase_check_order',numel(tcheck),'quad_difference_C',norm(C-Ccheck-diag(q./(2*kap))-diag((k==0)*(lambda+1)/(4*q(k==0)^2))), ...
    'quad_difference_H',norm(H-Hcheck),'quad_difference_G',norm(G-Gcheck),'quad_difference_U',norm(U-Ucheck),'dimension',nd,'d_per',d,'form_inverse',K,'time_seconds',toc(timer), ...
    'phase_ellipse',ellipse,'phase_strip',strip,'curve_moment_error',moment_error,'curve_propagated_error',curve_error, ...
    'bound_method',method,'eps_V2',epsV,'quad_difference_V2',norm(V2-Vcheck), ...
    'H_real',real(H),'H_imag',imag(H),'V2_real',real(V2),'V2_imag',imag(V2),'eps_C',epsC,'eps_H',epsH,'eps_U',epsU,'eps_G',epsG,'max_trial_bound',boundZ,'max_residual_bound',boundR, ...
    'hermitian_defect',symC,'gram_hermitian_defect',symG,'low_residual_relative',lowmax,'gram_cancellation_ratio',cancel, ...
    'error_norm',norm(E),'weighted_residual_norm',sqrt(max(eig(G))),'unweighted_dual_norm',sqrt(max(eig(H))), ...
    'original_volume_error_norm',norm(G)/d,'residual_min_eigenvalue',min(eig(G)),'dual_min_eigenvalue',min(eig(H)), ...
    'C_real',real(C),'C_imag',imag(C),'E_real',real(E),'E_imag',imag(E),'G_real',real(G),'G_imag',imag(G), ...
    'U_real',real(U),'U_imag',imag(U));
  if poisson2,rec.tests=h_endpoint(C,E,UU,HU,lambda,d,VU);else,rec.tests=h_endpoint(C,E,UU,HU,lambda,d);end
  writematrix(panel_table,fullfile(out,'phase-panels.csv'));
  f=fopen(fullfile(out,'result.json'),'w');fprintf(f,'%s\n',jsonencode(rec));fclose(f);
  fprintf('enclosed done %.2f %.7f E %.8g epsC %.3g epsH %.3g time %.1f\n',a,lambda,norm(E),epsC,epsH,toc(timer));disp(rec.tests);
end

function v=LOCAL_horner(c,t)
  v=c(:,:,end);for j=size(c,3)-1:-1:1,v=v*t+c(:,:,j);end
end
function [x,w]=LOCAL_gauss(n)
  b=(1:n-1)./sqrt(4*(1:n-1).^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));[x,i]=sort(diag(D));w=2*V(1,i)'.^2;
end
