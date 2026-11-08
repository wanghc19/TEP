function p=fast_proxy(pars,c,kind,bias)
  % Assemble the same MFS (method of fundamental solutions) fit with reused distances.
  % Input: kernel parameters, discretization, outgoing or reference boundary rule, bias.
  % Output: proxy coefficients and exterior plane waves. Geometry follows kernel.precomp_proxy.
  persistent geom
  key=[pars.d,c.H,c.proxy_dist,c.N_side,c.N_top,c.N_proxy_edge];
  if isempty(geom)||~isequal(geom.key,key)
    d=pars.d;H=c.H;a=d/2+c.proxy_dist;b=H+c.proxy_dist;
    X=linspace(-d/2,d/2,c.N_top).';Y=linspace(-H,H,c.N_side).';
    tx=linspace(-a,a,c.N_proxy_edge+1).';tx(end)=[];
    ty=linspace(-b,b,c.N_proxy_edge+1).';ty(end)=[];
    one=ones(size(tx));Z=[tx,-b*one;a*one,ty;flipud(tx),b*one;-a*one,flipud(ty)];
    pts=[-d/2*ones(size(Y)),Y;d/2*ones(size(Y)),Y;X,H*ones(size(X));X,-H*ones(size(X))];
    sources=[0,0;Z];dx=pts(:,1)-sources(:,1).';dy=pts(:,2)-sources(:,2).';
    rr=sqrt(dx.^2+dy.^2);[u,~,ix]=unique(rr(:));
    geom=struct('key',key,'X',X,'Z',Z,'u',u,'ix',reshape(ix,size(rr)),'cx',dx./rr,'cy',dy./rr);
  end
  k=pars.k;G=(1i/4)*besselh(0,1,k*geom.u);g=-(1i*k/4)*besselh(1,1,k*geom.u);
  V=G(geom.ix);der=g(geom.ix);dx=der.*geom.cx;dy=der.*geom.cy;
  L=1:c.N_side;R=L+c.N_side;T=(1:c.N_top)+2*c.N_side;B=T+c.N_top;
  phase=exp(1i*pars.beta*pars.d);
  D=[V(R,:)-phase*V(L,:);dx(R,:)-phase*dx(L,:);V(T,:);dy(T,:);V(B,:);dy(B,:)];
  rhs=-D(:,1);A=D(:,2:end);m=(-c.M_pw:c.M_pw).';beta=pars.beta+m*(2*pi/pars.d);
  gamma=sqrt(k^2-beta.^2);pw=exp(1i*geom.X*beta.');
  nt=c.N_top;top=2*c.N_side+(1:nt);bot=top+2*nt;
  if strcmp(kind,'outgoing')
    n=size(A,2);i=n+(1:numel(m));j=i+numel(m);A(end,j(end))=0;
    A(top,i)=-pw;A(top+nt,i)=-pw.*(1i*gamma.');
    A(bot,j)=-pw;A(bot+nt,j)=pw.*(1i*gamma.');
    co=lsqminnorm(A,rhs);up=co(i);down=co(j);charges=co(1:n);
  else
    % Prescribe the known spectral field and derivative at the remote horizontal walls.
    % This removes the near-null grazing plane-wave amplitude from the fit.
    gamma=sqrt((k-abs(beta)).*(k+abs(beta)));
    up=1i./(2*pars.d*gamma).*exp(1i*gamma*c.H);down=up;
    v=pw*up;dv=pw*(1i*gamma.*up);
    if bias~=0
      i=c.M_pw+1;v=v+bias*pw(:,i)*cos(gamma(i)*c.H);
      dv=dv-bias*pw(:,i)*gamma(i)*sin(gamma(i)*c.H);
    end
    rhs(top)=rhs(top)+v;rhs(bot)=rhs(bot)+v;
    rhs(top+nt)=rhs(top+nt)+dv;rhs(bot+nt)=rhs(bot+nt)-dv;
    charges=lsqminnorm(A,rhs);
  end
  p=struct('q',charges.','Z',geom.Z.','H',c.H,'C_up',up,'C_down',down);
end
