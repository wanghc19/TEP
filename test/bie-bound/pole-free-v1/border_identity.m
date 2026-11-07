function rows=border_identity(q,c)
  % Check the complex determinant factorization in amplitude and Cauchy data.
  % Input: example configuration and five regular frequencies.
  % Output: independent LU values, coordinate factors and relative mismatch.
  b0=border_data(mean(q.window),c,false);anchor=struct('L',b0.ZL,'R',b0.ZR);
  rows=cell(1,numel(q.values));
  for j=1:numel(q.values)
    k=q.values(j);b=border_data(k,c,false);[H,cv,ol,orr]=border_matrix(b,anchor);
    ld=search_i9_physics('leads',k,'fine',c);[~,old]=search_i9_physics('match',k,'fine',c,ld);
    K=b.K;D1=b.ZL(1:K,:)+b.ZL(K+1:end,:);D2=b.ZR(1:K,:)+b.ZR(K+1:end,:);
    center=log_det(b.J(:,1:b.n));dtn=log_det(old.matching.Adef);
    basis=log_det(ol)+log_det(orr);D=log_det(D1)+log_det(D2);
    coord=log_det(diag(4*b.gamma.^2));lhs=log_det(H);
    rhs=center+dtn+D-basis-coord+[0,pi*K];
    err=abs(expm1((lhs(1)-rhs(1))+1i*angle(exp(1i*(lhs(2)-rhs(2))))));
    rows{j}=struct('k',k,'dimension',size(H,1),'border',lhs,'rhs',rhs,'DtN',dtn, ...
      'center',center,'dirichlet',D,'overlaps',basis,'port_transform',coord,'cv',cv,'relative_error',err);
  end
end
