function r=find_cut(q,c)
  % Locate a Dirichlet exceptional cut at a supplied physical frequency.
  % Input: reference frequency and lead. Output: coarse and refined cut, singular values.
  l=search_i9_physics('leads',q.start,'fine',c);s=l.(q.side);L=c.model.(['L_',q.side]);
  g=l.channels.gamma_m(:);n=numel(g);I=eye(n);O=zeros(n);
  if c.model.staggered
    safe=L/4-.2-.007;lo=-safe;hi=safe;
  else
    lo=max(s.geometry(1,:))-L/2+.007;hi=min(s.geometry(1,:))+L/2-.007;
  end
  if ~c.model.empty_center
    [C,~]=geom.construct_cont(1024,'star',0,0);
    if strcmp(q.side,'positive'),lo=max(lo,max(C(1,:))-c.model.X_R+.007);
    else,hi=min(hi,min(C(1,:))-c.model.X_L-.007);end
  end
  dx=linspace(lo,hi,151);y=arrayfun(@objective,dx);[~,i]=min(y);a=dx(max(1,i-1));b=dx(min(end,i+1));
  for j=1:80
    m=a+(b-a)/3;t=b-(b-a)/3;
    if objective(m)<objective(t),b=t;else,a=m;end
  end
  best=(a+b)/2;
  r=struct('status','MEASURED','cut',best,'sigma',objective(best),'reference_sigma',objective(0), ...
    'domain',[lo,hi],'scan',[dx(:),y(:)],'side',q.side,'frequency',q.start);
  function z=objective(x)
    u=exp(1i*g*x);v=1./u;A=[-(v.*s.R_L).*v.',I;(u.*s.T_LR).*v.',O];
    B=[O,(v.*s.T_RL).*u.';I,-(u.*s.R_R).*u.'];if strcmp(q.side,'negative'),[A,B]=deal(B,A);end
    [S,T,Q,Z]=qz(A,B,'complex');mask=abs(diag(S))<abs(diag(T));
    if sum(mask)~=n,z=Inf;return;end
    [~,~,~,Z]=ordqz(S,T,Q,Z,mask);z=min(svd(Z(1:n,1:n)+Z(n+1:end,1:n)));
  end
end
