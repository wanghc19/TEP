function S=core_space(Nx,Ny)
% Source: test/numerical-directions/h-core-v1/core_space.m. Numerical method retained.
% Core spectral space with exact port representatives and energy normalization.
% Input: rectangular cosine/Fourier cutoffs. Output: analytic sparse Grams/maps.
  [m,k]=ndgrid(0:Nx,-Ny:Ny);m=m(:);k=k(:);cm=sqrt(2)*ones(size(m));cm(m==0)=1;
  aa=(pi*m).^2+(.5+2*pi*k).^2+1;nb=numel(m);pk=(-16:16)';np=2*numel(pk);n=nb+np;
  V=sparse(nb,np);E=zeros(np);Mr=zeros(np);B0=zeros(33,n);B1=B0;P=speye(n);P(1:nb,1:nb)=spdiags(1./sqrt(aa),0,nb,nb);tailmin=inf;
  for j=1:33
    q=sqrt(1+(.5+2*pi*pk(j))^2);den=-expm1(-2*q);ct=(1+exp(-2*q))/den;cs=2*exp(-q)/den;
    ids=find(k==pk(j));rr=2*j-1:2*j;c=[cm(ids),cm(ids).*(-1).^m(ids)];V(ids,rr)=c;
    ee=[ct,cs;cs,ct]/q;E(rr,rr)=ee;
    Mr(rr,rr)=[ct/(2*q^3)+cs^2/(2*q^2),ct*cs/(2*q^2)+cs/(2*q^3);ct*cs/(2*q^2)+cs/(2*q^3),ct/(2*q^3)+cs^2/(2*q^2)];
    tail=ee-c'*(c./aa(ids));tail=(tail+tail')/2;tailmin=min(tailmin,min(eig(tail)));assert(min(eig(tail))>0);
    R=chol(tail);ri=R\eye(2);P(ids,nb+rr)=-(c./aa(ids))*ri;P(nb+rr,nb+rr)=ri;
    B0(j,ids)=cm(ids);B1(j,ids)=cm(ids).*(-1).^m(ids);B0(j,nb+rr)=[ct,cs]/q;B1(j,nb+rr)=[cs,ct]/q;
  end
  Hraw=[spdiags(aa,0,nb,nb),V;V',sparse(E)];MV=spdiags(1./aa,0,nb,nb)*V;Mraw=[speye(nb),MV;MV',sparse(Mr)];
  H=P'*Hraw*P;M=P'*Mraw*P;B0=B0*P;B1=B1*P;
  ast=1+min(((Nx+1)*pi)^2+.25,(2*pi*(Ny+1)-.5)^2);cc=23.4676/ast;
  S=struct('Nx',Nx,'Ny',Ny,'nb',nb,'n',n,'m',m,'k',k,'cm',cm,'a',aa,'pk',pk,'P',P,'M1',full((M+M')/2),'B_left',B0,'B_right',B1, ...
    'a_star',ast,'C_h',1/sqrt(ast),'c_W',1-cc,'delta',cc/(1-cc),'H_defect',norm(H-speye(n),1),'H_min',1,'tail_Gram_min',tailmin,'P_norm_squared_bound',norm(P,1)*norm(P,inf));
end
