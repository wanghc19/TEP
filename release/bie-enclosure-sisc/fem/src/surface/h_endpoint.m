function tests=h_endpoint(C,E,U,H,lambda,d,V2)
% Source: test/numerical-directions/h-cert-v1/h_endpoint.m. Numerical method retained.
% H means hypothesis: form Schur inertia and half-resolvent bounds.
% Input: low block, error matrix, upper response and dual Grams, endpoint;
% optional upper Gram of the squared Poisson inverse residual.
% Output: endpoint diagnostics for retained boundary orders 8 and 10.
  tests=struct([]);
  for M=[8,10]
    ix=(11-M):(11+M); tails=LOCAL_tail(lambda,d,M);Cm=C(ix,ix)-E(ix,ix)-tails.penalty*eye(2*M+1);Cp=C(ix,ix)+E(ix,ix);
    lo=sort(real(eig((Cm+Cm')/2)));hi=sort(real(eig((Cp+Cp')/2)));nm=sum(lo<0);np=sum(hi<0);gamma=0;
    if nm==np
      g=[];if nm>0,g(end+1)=-hi(nm);end
      if nm<2*M+1,g(end+1)=lo(nm+1);end
      gamma=min(g);
    end
    inverse=inf;Tbound=inf;distance=0;Khalf=inf;Kcoarse=inf;response_error=inf;alow=inf;ahigh=inf;
    if gamma>0
      inverse=(1+tails.x/tails.t)^2/min(tails.t,gamma);
      response_error=sqrt((1+(lambda+1)/d)/d)*sqrt(max(eig(H(ix,ix))));
      if nargin>=7,response_error=sqrt(17)*(1+lambda/d)*sqrt(max(eig(V2(ix,ix))));end
      alow=sqrt(max(eig(U(ix,ix))))+response_error;
      ahigh=tails.brho+tails.vw*tails.aM/d;Tbound=alow^2+ahigh^2;
      distance=1/(1/d+Tbound*inverse);Khalf=1+(lambda+1)/distance;
      coarse=.5*((lambda+1)/d^2+1/d);Kcoarse=1+(lambda+1)*(1/d+coarse*inverse);
    end
    z=struct('M',M,'negative_Cminus',nm,'negative_Cplus',np,'gamma',gamma, ...
      'C_min_abs',min(abs(eig(C(ix,ix)))),'E_norm',norm(E(ix,ix)), ...
      'tail',tails,'B_inverse',inverse,'T_squared',Tbound,'d_half',distance,'K_half',Khalf,'K_coarse',Kcoarse,'response_gram_max',max(real(eig(U(ix,ix)))), ...
      'response_error',response_error,'a_low',alow,'a_high',ahigh);
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

