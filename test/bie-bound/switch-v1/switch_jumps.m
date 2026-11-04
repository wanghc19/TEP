function [jump,lower,upper]=switch_jumps(Y,pars,proxy,block)
  % SWITCH_JUMPS Evaluate both analytic branches at the wrap cut, without round.
  % Input
  %   Y: physical x difference; pars: k,beta,d; frozen proxy; direct batch size.
  % Output
  %   Upper-minus-lower jump columns G,Gx,Gy,Hxx,Hxy,Hyy in physical coordinates.
  Y=Y(:);n=numel(Y);lower=complex(zeros(n,6));upper=lower;
  for first=1:block:n
    id=first:min(first+block-1,n);
    for side=[-1,1]
      target=[side*pars.d/2*ones(1,numel(id));Y(id).'];
      [p,g,h]=kernel.h2d_directch(pars.k,[0;0],1,target);
      [pp,gg,hh]=kernel.h2d_directch(pars.k,proxy.Z,proxy.q,target);
      p=p+pp;g=g+gg;h=h+hh;
      V=[p;g(2,:);g(1,:);h(3,:);h(2,:);h(1,:)].';
      if side<0,upper(id,:)=exp(1i*pars.beta*pars.d)*V;else,lower(id,:)=V;end
    end
  end
  jump=upper-lower;
end
