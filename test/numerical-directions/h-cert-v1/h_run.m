function h_run(out,a,lambda,N,Ntheta,qorder)
% H means hypothesis: compute one surface endpoint with Bloch Fourier trials.
% Input: output directory, trefoil parameter, endpoint, Fourier half-order,
% phase-panel count, and angular/radial Gauss order on analytic polar panels.
% Output: small JSON matrices and endpoint diagnostics; no field files.
  maxNumCompThreads(11); if ~exist(out,'dir'),mkdir(out);end
  timer=tic; M=10; modes=(-M:M)'; p=numel(modes); beta=.5+2*pi*modes;
  q=sqrt(1+beta.^2);kap=sqrt(beta.^2-lambda);kap(modes==0)=q(modes==0);
  amplitude=sqrt(q)./(2*kap); D0=q./(2*kap);
  [m,n]=ndgrid(-N:N,-N:N);m=m(:);n=n(:);byn=.5+2*pi*n;
  [x,y,w,rho]=LOCAL_rule(a,qorder); E0=exp(1i*(2*pi*x*m'+y*byn'));
  inside=rho>1; Wi=w(inside); Ei=E0(inside,:);
  X=LOCAL_inclusion(a,m,n,2048); Mrho=eye(numel(m))+16*X;
  ey=exp(1i*y*beta'); F0=0; Ch=zeros(p); Gr=zeros(p); Gdual=zeros(p); Ug=zeros(p);
  maximum_hermitian=0;maximum_low=0; phase_min=inf;
  d=min(lambda-1.318^2,2.375^2-lambda); K=1+(lambda+1)/d;
  for it=1:Ntheta
    theta=-pi+(it-.5)*2*pi/Ntheta; xi=2*pi*m+theta; D=xi.^2+byn.^2;
    L=diag(D)-lambda*Mrho;
    t=exp(-x*kap')./(1-exp(-kap'-1i*theta))+ ...
      exp(-(1-x)*kap'+1i*theta)./(1-exp(-kap'+1i*theta));
    T=t.*amplitude'.*ey.*exp(-1i*theta*x);
    Ti=T(inside,:); IT=Ei'*(Wi.*Ti);
    Tcoef=zeros(numel(m),p);
    for j=1:p
      rows=n==modes(j);Tcoef(rows,j)=sqrt(q(j))./(xi(rows).^2+kap(j)^2);
    end
    F=16*lambda*IT; F(:,modes==0)=F(:,modes==0)+(lambda+1)*Tcoef(:,modes==0);
    Z=L\F; low=F-L*Z;
    value=E0*Z; Dz=E0*(D.*Z);
    source=16*lambda*(inside.*T);source(:,modes==0)=source(:,modes==0)+(lambda+1)*T(:,modes==0);
    residual=source-Dz+lambda*rho.*value;
    G0=residual'*(w.*residual); G1=residual'*((w./rho).*residual);
    dtail=min((2*pi*(N+1)-abs(theta))^2+.25,theta^2+(2*pi*(N+1)-.5)^2);
    H=G0/dtail+low'*( (1./D-1/dtail).*low );
    J=F'*Z+Z'*F-Z'*L*Z;
    Ch=Ch+(16*lambda*(Ti'*(Wi.*Ti))+J)/Ntheta;
    Gr=Gr+G1/Ntheta; Gdual=Gdual+H/Ntheta;
    U=T+value;Ug=Ug+U'*((w.*rho).*U)/Ntheta;
    maximum_hermitian=max(maximum_hermitian,norm(J-J','fro')/max(norm(J,'fro'),realmin));
    maximum_low=max(maximum_low,norm(low,'fro')/max(norm(F,'fro'),realmin));
    phase_min=min(phase_min,min(abs(eig(L))));
    if mod(it,16)==0,fprintf('phase %d/%d elapsed %.1f s\n',it,Ntheta,toc(timer));end
  end
  Ch=Ch+diag(D0); Ch(modes==0,modes==0)=Ch(modes==0,modes==0)+(lambda+1)/(4*q(modes==0)^2);
  Ch=(Ch+Ch')/2;Gr=(Gr+Gr')/2;Gdual=(Gdual+Gdual')/2;Ug=(Ug+Ug')/2;
  error=K*Gdual;
  rec=struct('material',a,'lambda',lambda,'N',N,'Ntheta',Ntheta,'quadrature_order',qorder, ...
    'dimension',numel(m),'points',numel(w),'d_per',d,'form_inverse',K,'time_seconds',toc(timer), ...
    'hermitian_defect',maximum_hermitian,'low_residual_relative',maximum_low,'fiber_min_abs',phase_min, ...
    'weighted_residual_norm',sqrt(max(eig(Gr))),'unweighted_dual_norm',sqrt(max(eig(Gdual))), ...
    'error_norm',norm(error),'original_volume_error_norm',norm(Gr)/d, ...
    'residual_min_eigenvalue',min(eig(Gr)),'dual_min_eigenvalue',min(eig(Gdual)), ...
    'C_real',real(Ch),'C_imag',imag(Ch),'E_real',real(error),'E_imag',imag(error), ...
    'G_real',real(Gr),'G_imag',imag(Gr),'U_real',real(Ug),'U_imag',imag(Ug));
  rec.tests=LOCAL_endpoint(Ch,error,Ug,Gdual,lambda,d);
  LOCAL_json(fullfile(out,'result.json'),rec);
  fprintf('endpoint material %.2f lambda %.7f E %.6g residual %.6g time %.1f\n',a,lambda,rec.error_norm,rec.weighted_residual_norm,toc(timer));
  disp(rec.tests);
end

function tests=LOCAL_endpoint(C,E,U,H,lambda,d)
  tests=struct([]);
  for M=[8,10]
    ix=(11-M):(11+M); tails=LOCAL_tail(lambda,d,M);Cm=C(ix,ix)-E(ix,ix)-tails.penalty*eye(2*M+1);Cp=C(ix,ix)+E(ix,ix);
    lo=eig((Cm+Cm')/2);hi=eig((Cp+Cp')/2);nm=sum(lo<0);np=sum(hi<0);gamma=0;
    if nm==np
      g=[];if nm>0,g(end+1)=-hi(nm);end
      if nm<2*M+1,g(end+1)=lo(nm+1);end
      gamma=min(g);
    end
    inverse=inf;Tbound=inf;distance=0;Khalf=inf;Kcoarse=inf;
    if gamma>0
      inverse=(1+tails.x/tails.t)^2/min(tails.t,gamma);
      alow=sqrt(max(eig(U(ix,ix))))+sqrt((1+(lambda+1)/d)/d)*sqrt(max(eig(H(ix,ix))));
      ahigh=tails.brho+tails.vw*tails.aM/d;Tbound=alow^2+ahigh^2;
      distance=1/(1/d+Tbound*inverse);Khalf=1+(lambda+1)/distance;
      coarse=.5*((lambda+1)/d^2+1/d);Kcoarse=1+(lambda+1)*(1/d+coarse*inverse);
    end
    z=struct('M',M,'negative_Cminus',nm,'negative_Cplus',np,'gamma',gamma, ...
      'C_min_abs',min(abs(eig(C(ix,ix)))),'E_norm',norm(E(ix,ix)), ...
      'tail',tails,'B_inverse',inverse,'T_squared',Tbound,'d_half',distance,'K_half',Khalf,'K_coarse',Kcoarse);
    tests=[tests;z]; %#ok<AGROW>
  end
end

function z=LOCAL_tail(lambda,d,M)
  k=(-M:M)';beta=.5+2*pi*k;q=sqrt(1+beta.^2);kap=sqrt(beta.^2-lambda);kap(k==0)=q(k==0);
  nk=sqrt(q)./(2*kap.^1.5);b=max(nk.*exp(-kap/4));
  bq=abs(.5-2*pi*(M+1));qq=sqrt(1+bq^2);kk=sqrt(bq^2-lambda);nn=sqrt(qq)/(2*kk^1.5);
  aM=nn*exp(-kk/4);vc=16*lambda;vw=vc/sqrt(17);cp=vw*b+(lambda+1)*nk(k==0);
  h=(vc+vw^2/d)*aM^2;x=aM*(vc*b+cp*vw/d);t=.5-h;
  z=struct('aM',aM,'b_out',b,'cP',cp,'h',h,'x',x,'t',t,'penalty',x^2/t,'brho',nn*sqrt(1+16*exp(-kk/2)),'vw',vw);
end

function X=LOCAL_inclusion(a,m,n,J)
  % Analytic-curve divergence integral for every unique Fourier difference.
  N=max(abs(m)); [dm,dn]=ndgrid(-2*N:2*N,-2*N:2*N);u=dm(:);v=dn(:);
  t=(0:J-1)'*2*pi/J;r=.2/sqrt(1+a*a/2)*(1+a*cos(3*t));dr=-.6*a/sqrt(1+a*a/2)*sin(3*t);
  x=.5+r.*cos(t);y=r.*sin(t);dx=dr.*cos(t)-r.*sin(t);dy=dr.*sin(t)+r.*cos(t);
  f=zeros(numel(u),1);
  for b=1:256:numel(u)
    ix=b:min(b+255,numel(u));u1=u(ix)';v1=v(ix)';e=exp(2i*pi*(x*u1+y*v1));
    use=u1~=0;z=zeros(1,numel(ix));z(use)=sum(e(:,use).*dy,1)./(2i*pi*u1(use))*2*pi/J;
    alt=~use & v1~=0;z(alt)=-sum(e(:,alt).*dx,1)./(2i*pi*v1(alt))*2*pi/J;
    zero=~use & v1==0;z(zero)=pi*.2^2;f(ix)=z;
  end
  ind=sub2ind(size(dm),m'-m+2*N+1,n'-n+2*N+1);X=f(ind);X=(X+X')/2;
end

function [x,y,w,rho]=LOCAL_rule(a,Q)
  % Positive polar Gauss rule of the exact square and analytic radial curve.
  [z,g]=LOCAL_gauss(Q);x=[];y=[];w=[];rho=[];
  for panel=0:7
    th=(panel+(z+1)/2)*pi/4;wt=g*pi/8;
    rin=.2/sqrt(1+a*a/2)*(1+a*cos(3*th));rout=.5./max(abs(cos(th)),abs(sin(th)));
    for domain=1:2
      lo=zeros(size(rin));hi=rin;if domain==2,lo=rin;hi=rout;end
      rr=lo+(hi-lo).*(z'+1)/2;ww=wt.*(hi-lo).*g'/2.*rr;
      x=[x;.5+reshape(rr.*cos(th),[],1)];y=[y;reshape(rr.*sin(th),[],1)];w=[w;ww(:)];rho=[rho;ones(numel(rr),1)*(1+16*(domain==1))]; %#ok<AGROW>
    end
  end
end

function [x,w]=LOCAL_gauss(n)
  b=(1:n-1)./sqrt(4*(1:n-1).^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));[x,i]=sort(diag(D));w=2*V(1,i)'.^2;
end
function LOCAL_json(path,value)
  f=fopen(path,'w');fprintf(f,'%s\n',jsonencode(value));fclose(f);
end
