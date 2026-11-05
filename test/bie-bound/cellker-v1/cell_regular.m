function [p,g,h]=cell_regular(pars,proxy,T)
% CELL_REGULAR Smooth remainder: two adjacent images plus remote proxies.
% Input
%   pars: physical parameters; proxy: fitted remote sources; T: computational points.
% Output
%   Potential, gradient and Hessian in computational coordinates.
  if isfield(pars,'h2d_evaluator')
    [p,g,h]=pars.h2d_evaluator(pars.k,proxy.Z,proxy.q,T);
  else
    [p,g,h]=kernel.h2d_directch(pars.k,proxy.Z,proxy.q,T);
  end
  q=exp(1i*pars.beta*pars.d);
  for m=[-1,1]
    [a,b,c,xx,xy,yy]=cell_green(pars.k,T.',[m*pars.d,0]);
    p=p+q^m*a.';g=g+q^m*[b.';c.'];h=h+q^m*[xx.';xy.';yy.'];
  end
end
