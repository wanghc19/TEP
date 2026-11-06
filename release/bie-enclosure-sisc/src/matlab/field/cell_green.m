% Copied from test/bie-bound/pipeline-v1/field/cell_green.m; release R1 path/data interfaces may be adapted.
% Copied from test/bie-bound/cellfit-v1/cell_green.m.
function [v,gx,gy,hxx,hxy,hyy]=cell_green(k,T,Z)
% CELL_GREEN Free-space Helmholtz matrices in computational coordinates.
% Input
%   k: wave number; T,Z: target/source coordinates with two columns.
% Output
%   Value, two target derivatives and three target Hessian matrices.
  % Coincident entries are placeholders, replaced by the self-assembly diagonal.
  x=T(:,1)-Z(:,1).'; y=T(:,2)-Z(:,2).'; r=hypot(x,y); r(r==0)=1;
  h0=besselh(0,1,k*r);h1=besselh(1,1,k*r);
  v=1i/4*h0; c=-1i*k/4*h1./r;gx=c.*x;gy=c.*y;
  c2=1i*k/4./r.^3; h2=-k*r.*h0+2*h1;
  hxx=c2.*(h2.*x.^2-r.^2.*h1);hxy=c2.*h2.*x.*y;hyy=c2.*(h2.*y.^2-r.^2.*h1);
end
