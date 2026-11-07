function out=border_scan(q,c)
  % Locate minima of the absolute smallest raw bordered singular value.
  % Input: model, interval and uniform sample count.
  % Output: full grid, locally minimized dips and proposed real frequencies.
  grid=linspace(q.window(1),q.window(2),q.samples);ss=arrayfun(@sigma,grid);
  minima={};roots=[];
  for j=1:numel(grid)
    lo=max(1,j-1);hi=min(numel(grid),j+1);
    if j>1 && ss(j)>ss(lo),continue;end
    if j<numel(grid) && ss(j)>=ss(hi),continue;end
    ab=grid([lo,hi]);t=fminbnd(@sigma,ab(1),ab(2),optimset('TolX',1e-14,'Display','off'));
    for target=min([1e-5,1e-6,1e-7,1e-8],diff(ab)*[.23,.08,.025,.008])
      h=min(target,.9*min(t-ab(1),ab(2)-t));
      if h<=eps(t),break;end
      yy=[sigma(t-h),sigma(t),sigma(t+h)].^2;den=yy(1)+yy(3)-2*yy(2);
      if den>0
        dk=h*(yy(1)-yy(3))/(2*den);
        if abs(dk)<h,t=t+dk;end
      end
    end
    sv=sigma(t);
    if ss(j)<sv,t=grid(j);sv=ss(j);end
    minima{end+1}=struct('k',t,'sigma',sv,'bracket',ab);
    if sv<1e-8,roots(end+1)=t;end
  end
  roots=sort(roots);if ~isempty(roots),roots=roots([true,diff(roots)>2e-12]);end
  out=struct('grid',[grid(:),ss(:)],'minimums',{minima},'roots',roots);
  function v=sigma(k)
    b=border_data(k,c,false);s=svd(border_matrix(b));v=s(end);
  end
end
