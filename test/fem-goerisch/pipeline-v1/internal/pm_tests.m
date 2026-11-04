function r=pm_tests()
  % PM_TESTS Check capped polynomial model arithmetic against known integrals.
  % Input
  %   None.
  % Output
  %   Scalar diagnostic checks. Comparison tolerance excludes rounding claims.
  a=pm('make',[0,.1;.2,0]);co=pm('cos',a);z=pm('integral',co);known=4*sin(.2)/.2*sin(.1)/.1;
  b=pm('make',[1,.1;.2,0]);re=pm('reciprocal',b);[x,w]=LOCAL_gauss(32);[X,Y]=ndgrid(x,x);W=w*w.';q=sum(W./(1+.2*X+.1*Y),'all');v=pm('integral',re);
  c=zeros(9,1);c(9)=1;d=zeros(1,7);d(7)=1;mul=pm('mul',pm('make',c),pm('make',d));it=pm('integral',mul);
  r=struct('cosine_value',z.value,'cosine_error',z.error,'cosine_known',known,'reciprocal_value',v.value,'reciprocal_error',v.error,'reciprocal_Q32',q, ...
    'truncation_value',it.value,'truncation_error',it.error,'truncation_known',4/63,'pass',abs(z.value-known)<=z.error+1e-12&&abs(v.value-q)<=v.error+1e-12&&abs(it.value-4/63)<=it.error);
  z=pm('make',[1+1i,1-1i],.1);bound=pm('modulus',z);r.modulus_bound=bound;r.pass=r.pass&&bound<=pm('norm',z)&&bound>=2.1;
  assert(r.pass,'pm:Tests','Capped polynomial model test failed');
end
function [x,w]=LOCAL_gauss(n)
  % LOCAL_gauss Gauss.
  % Input
  %   n.
  % Output
  %   [x,w].
  j=(1:n-1)';b=j./sqrt(4*j.^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));[x,k]=sort(diag(D));w=2*V(1,k)'.^2;
end
