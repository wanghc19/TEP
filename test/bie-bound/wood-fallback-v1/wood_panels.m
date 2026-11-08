function [pieces,lines,bands]=wood_panels(window,beta,d,rho,delta)
  % Split an explicit frequency window at all background Wood bands touching it.
  % Input: increasing positive frequency pair, phase, period, density and band radius.
  % Output: retained intervals with adjacent Wood line, all relevant lines, exclusions.
  window=window(:).';
  assert(window(1)>0 && window(1)<window(2) && delta>0 && d>0 && rho>0);
  endm=ceil((sqrt(rho)*(window(2)+delta)+abs(beta))*d/(2*pi))+1;
  all=unique(abs(beta+(-endm:endm)*2*pi/d)/sqrt(rho));
  lines=all(all+delta>=window(1) & all-delta<=window(2));
  pieces=zeros(0,3);bands=zeros(0,2);
  start=window(1);prev=NaN;
  for w=lines
    lo=w-delta;hi=w+delta;
    % Round retained band boundaries away from Wood in floating point.
    if abs(lo-w)<delta,lo=lo-eps(lo);end
    if abs(hi-w)<delta,hi=hi+eps(hi);end
    emit(start,min(lo,window(2)),prev,w);
    bands(end+1,:)=[max(lo,window(1)),min(hi,window(2))];
    start=max(start,hi);prev=w;
  end
  emit(start,window(2),prev,NaN);
  function emit(a,b,left,right)
    if b<=a,return;end
    if isfinite(left) && isfinite(right)
      mid=(a+b)/2;pieces(end+1,:)=[a,mid,left];pieces(end+1,:)=[mid,b,right];
    elseif isfinite(left),pieces(end+1,:)=[a,b,left];
    else,pieces(end+1,:)=[a,b,right];end
  end
end
