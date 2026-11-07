function r=edge_mode(q,c,out)
  % Choose an empty-center width from the actual two cladding subspaces at fixed k.
  % Input: k safely inside the measured edge; L0 scan. Output: tuned physical NEP and both root estimates.
  k=q.start;
  l=search_i9_physics('leads',k,'fine',c);g=linspace(1.8,2.5,101);s=arrayfun(@cost,g);
  [~,i]=min(s);
  if i==1||i==numel(g),r=struct('status','NO_INTERIOR_MINIMUM','grid',[g(:),s(:)]);return;end
  a=g(i-1);b=g(i+1);
  for it=1:75
    m=a+(b-a)/3;t=b-(b-a)/3;if cost(m)<cost(t),b=t;else,a=m;end
  end
  L=(a+b)/2;q.L0=L;q.action='local';q.eigen=true;cc=probe_config(q);
  % Give the two root solves different seeds, staying on the gap side.
  delta=min(2e-5,2*q.step);
  q.start=k+delta;primary=diagnose(q,cc,out);
  q.action='vectors';q.start=k+delta/2;alternate=diagnose(q,cc,out);
  r=struct('status','MEASURED','width',L,'qz_seed',k+delta,'vector_seed',k+delta/2,'grid',[g(:),s(:)],'qz',primary.roots{1},'vectors',alternate.roots{1});
  function s=cost(L)
    cm=c;cm.model.X_L=-L/2;cm.model.X_R=L/2;v=search_i9_physics('match',k,'fine',cm,l);s=v.aphys_ratio;
  end
end
