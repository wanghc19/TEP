function [P,Gx,Gy,Hxx,Hxy,Hyy]=cell_pairmat(src,trg,pars,proxy)
% CELL_PAIRMAT Three-image, unwrapped cell kernel in physical coordinates.
% Input
%   src,trg: physical 2-by-count coordinates; pars and fitted proxy.
% Output
%   Pair value, physical target gradient and Hessian matrices.
  X=trg(2,:).'-src(2,:);Y=trg(1,:).'-src(1,:);sz=size(X);T=[X(:).';Y(:).'];
  assert(max(abs(X),[],'all')<pars.d+1e-14 && max(abs(Y),[],'all')<=proxy.H+1e-14,'cellker:Box','Pair outside the fitted box.');
  [p,g,h]=cell_regular(pars,proxy,T);
  [a,b,c,xx,xy,yy]=cell_green(pars.k,T.',[0,0]);
  p=p+a.';g=g+[b.';c.'];h=h+[xx.';xy.';yy.'];
  P=reshape(p,sz);Gx=reshape(g(2,:),sz);Gy=reshape(g(1,:),sz);
  Hxx=reshape(h(3,:),sz);Hxy=reshape(h(2,:),sz);Hyy=reshape(h(1,:),sz);
end
