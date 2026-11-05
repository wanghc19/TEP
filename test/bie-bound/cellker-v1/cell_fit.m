function [proxy,stats]=cell_fit(pars,s)
% CELL_FIT Fit the three-image cell-bounded Green kernel.
% Input
%   pars: k,d,beta; s: H, margin, edge, nx, ny, top, mpw, tolerance.
% Output
%   proxy: coefficients, exterior source positions and configuration; stats.
  timer=tic;d=pars.d;k=pars.k;phase=exp(1i*pars.beta*d);H=s.H;n=s.edge;
  tx=linspace(-d-s.margin,d+s.margin,n+1).';tx(end)=[];
  ty=linspace(-H-s.margin,H+s.margin,n+1).';ty(end)=[];
  Z=[tx,(-H-s.margin)*ones(n,1);(d+s.margin)*ones(n,1),ty; ...
    flipud(tx),(H+s.margin)*ones(n,1);(-d-s.margin)*ones(n,1),flipud(ty)];
  [xx,yy]=ndgrid(linspace(0,d,s.nx),linspace(-H,H,s.ny));T=[xx(:),yy(:)];L=T-[d,0];
  [V,X]=cell_green(k,T,Z);[VL,XL]=cell_green(k,L,Z);
  [a,ax]=cell_green(k,T,[-d,0]);[b,bx]=cell_green(k,T,[2*d,0]);
  A=[V-phase*VL;X-phase*XL];rhs=-[a/phase-phase^2*b;ax/phase-phase^2*bx];
  bm=pars.beta+2*pi*(-s.mpw:s.mpw)/d;gm=sqrt(complex(k^2-bm.^2));np=numel(bm);nz=size(Z,1);
  A=[A,zeros(size(A,1),2*np)];
  for side=[1,-1]
    T=[linspace(-d,d,s.top).',side*H*ones(s.top,1)];
    [V,~,Y]=cell_green(k,T,Z); vv=0;vy=0;
    for m=-1:1,[a,~,b]=cell_green(k,T,[m*d,0]);vv=vv+phase^m*a;vy=vy+phase^m*b;end
    P=exp(1i*T(:,1)*bm);D=P.*(side*1i*gm);
    block=[V;Y];block(:,nz+1:nz+2*np)=0;
    col=nz+(1:np)+(side==-1)*np;block(:,col)=-[P;D];A=[A;block];rhs=[rhs;-vv;-vy];
  end
  scale=sqrt(sum(abs(A).^2,1));As=A./scale;
  [U,S,V]=svd(As,'econ');sv=diag(S);keep=sv>s.tolerance*sv(1);
  c=(V(:,keep)*((U(:,keep)'*rhs)./sv(keep)))./scale.';
  proxy=struct('q',c(1:nz).','Z',Z.','H',H,'settings',s,'pars',pars);
  stats=struct('seconds',toc(timer),'rank',sum(keep),'rows',size(A,1),'columns',size(A,2), ...
    'residual_max',max(abs(A*c-rhs)),'coefficient_norm',norm(c(1:nz)),'settings',s);
end
