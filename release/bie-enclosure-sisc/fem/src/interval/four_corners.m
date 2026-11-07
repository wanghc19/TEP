function r=four_corners(E,M,S,s,cfg)
% Source: test/fem-goerisch/pipeline-v1/internal/four_corners.m. Copied numerical algorithm.
  % FOUR_CORNERS Apply Theorem 6.1 using its stable endpoint identity.
  % Input
  %   E,M: intervals; S: upper residual; s: fixed real parameter; cfg: endpoints.
  % Output
  %   Twelve strict sign tests and, only when they pass, L and U.
  [e,m]=ndgrid(E,M);e=e(:);m=m(:);mu=cfg.mu;nu=cfg.nu;
  D=@(t)(1-2*t/s+t/s^2)*m+t/s^2*e-t*S;
  H=(mu+nu-1-mu*nu*(2/s-1/s^2))*m+(mu*nu/s^2-1)*e-mu*nu*S;
  signs=[H,D(mu),-D(nu)];q=1+e./m;d=q*S./m-(q-s).^2/s^2;
  F=@(t)q-1+q*t.*d./(q-t-t*d);
  r=struct('E',E,'M',M,'S_upper',S,'s',s,'signs',signs,'pass',all(signs>0,'all')&&M(1)>0,'L',NaN,'U',NaN,'width',NaN);
  if r.pass,r.L=min(F(nu));r.U=max(F(mu));r.width=r.U-r.L;r.corner_lower=F(nu);r.corner_upper=F(mu);end
end
