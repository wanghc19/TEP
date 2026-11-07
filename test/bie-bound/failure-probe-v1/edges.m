function r=edges(q,c,out)
  % Bisect the observed common-gap transition, then compare stable bases from inside.
  % Input: bracketing band and gap frequencies. Output: edge samples and rank/separation.
  a=q.bad;b=q.good;tab={};sa=classify(a);sb=classify(b);
  assert(~sa && sb,'probe:EdgeBracket','Endpoints must straddle the observed gap boundary.');
  for it=1:37
    k=(a+b)/2;if classify(k),b=k;else,a=k;end
  end
  for epsk=[1e-2,1e-4,1e-6,1e-8,1e-10,1e-12]
    z=q;z.action='points';z.values=b+sign(q.good-q.bad)*epsk;z.eigen=true;
    x=diagnose(z,c,out);tab{end+1}=struct('offset',epsk,'point',x.rows{1});
  end
  r=struct('status','MEASURED','band_side',a,'gap_side',b,'samples',{tab});
  function ok=classify(k)
    l=search_i9_physics('leads',k,'fine',c);ok=l.common_gap;
  end
end
