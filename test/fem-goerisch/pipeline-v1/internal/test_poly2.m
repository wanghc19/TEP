function r=test_poly2()
  % TEST_POLY2 Check polynomial-model rules on known reference integrals.
  % poly2 means a polynomial in two variables.
  % Input
  %   None.
  % Output
  %   Numerical diagnostic values with explicit remainder bounds.
  a=poly2('make',[1,0;0,.2],.001);b=poly2('make',[2;.1],.002);
  m=poly2('mul',a,b);assert(m.e>=1.2*.002+2.1*.001+.001*.002-1e-15);
  tr=poly2('truncate',m,1);assert(tr.e>=m.e);
  a=poly2('make',[1; .1]);rec=poly2('reciprocal',a,12);I=poly2('square',rec);exact=2*log(1.1/.9)/.1;
  r.reciprocal=struct('interval',I,'known',exact,'difference',mean(I)-exact,'remainder',4*rec.e);
  a=poly2('make',[0,.1;.2,0]);co=poly2('cos',a,12);si=poly2('sin',a,12);C=poly2('square',co);Z=poly2('square',si);known=4*sin(.2)/.2*sin(.1)/.1;
  r.cosine=struct('interval',C,'known',known,'difference',mean(C)-known);r.sine=struct('interval',Z,'known',0);
  rr=poly2('rational_triangle',1,[1;.1],1,1.1,1e-14);known=((1.1)*log(1.1)-.1)/.01;
  r.triangle=struct('certificate',rr,'known',known,'difference',rr.value-known);
  p=zeros(4);p(3,2)=1;moment=poly2('triangle',p);assert(abs(moment-1/60)<1e-16);
  r.pass=abs(mean(I)-exact)<max(1e-12,4*rec.e)&&abs(mean(C)-known_cos())<1e-12&&abs(mean(Z))<1e-12&&abs(rr.value-known)<1e-12;
  assert(r.pass,'poly2:Test','Known-integral check failed');
end
function v=known_cos()
  % known_cos Known cos.
  % Input
  %   None.
  % Output
  %   v.
  v=4*sin(.2)/.2*sin(.1)/.1;
end
