function r=split_search(q,c)
  % Interpolate the anchored bordered determinant outside explicit Wood exclusions.
  % Input: configuration and search parameters including route, time cap and window.
  % Output: proposals, coverage, measured calls, first-failure and panel diagnostics.
  [parts,lines,bands]=wood_panels(q.window,q.beta,c.model.d,c.model.rho_exterior,q.delta);
  guardlines=unique([lines(:);abs(q.beta)]); % Also audit detuned control windows.
  timer=tic;logs={};ks=[];roots=[];status='complete';message='';detcalls=0;done=zeros(0,2);
  try
    for ip=1:size(parts,1)
      branch=parts(ip,3);
      if isfield(q,'control') && q.control,branch=abs(q.beta);end
      visit(parts(ip,1:2),0,branch);
    end
  catch err
    if strcmp(err.identifier,'fallback:Time'),status='timed_out';
    elseif strcmp(err.identifier,'fallback:Depth'),status='unresolved';
    elseif strcmp(err.identifier,'border:Gap'),status='outside_common_gap';
    else,rethrow(err);end
    message=err.message;
  end
  [closest,idx]=min(min(abs(ks(:)-guardlines.'),[],2));
  r=struct('status',status,'message',message,'complete',strcmp(status,'complete'), ...
    'N',q.N,'M',q.M,'beta',q.beta,'route',q.route,'delta',q.delta,'window',q.window, ...
    'excluded',bands,'retained',parts,'finished_intervals',done,'proposals',LOCAL_unique(roots), ...
    'seconds',toc(timer),'panels',numel(logs),'evaluations',detcalls,'cell_calls',numel(ks), ...
    'closest_distance',closest,'closest_k',ks(idx),'frequencies',ks,'panel_log',{logs});
  function record(k)
    if toc(timer)>=q.cap,error('fallback:Time','Search reached its %.0f s cap.',q.cap);end
    assert(all(abs(k-guardlines)>=q.delta),'fallback:Guard','Forbidden frequency %.17g',k);
    ks(end+1)=k;
  end
  function visit(ab,depth,w)
    lo=ab(1);hi=ab(2);sgn=1;
    square=strcmp(q.route,'sqrt') && isfinite(w);
    if square
      sgn=sign(mean(ab)-w);coords=sgn*sqrt(abs(ab-w));
    else,coords=ab;end
    mid=mean(coords);half=diff(coords)/2;
    pidx=numel(logs)+1;
    logs{pidx}=struct('bounds',ab,'depth',depth,'degree',0,'tail',[],'offgrid',[], ...
      'chart_ok',true,'localized',false,'n_eval',0);
    kref=convert(mid);record(kref);
    ref=border_data(kref,c,false);anchor=struct('L',ref.ZL,'R',ref.ZR);
    [H,~]=border_matrix(ref,anchor);
    dr=1./vecnorm(H,2,2);dc=1./vecnorm(dr.*H,2,1);
    key=kref;obs=log_det(dr.*H.*dc);detcalls=detcalls+1;
    chart=true;localized=false;seeds=[];
    for deg=[8,16,32,64]
      x=cos(pi*(0:deg)'/deg);x(deg/2+1)=0;
      freq=convert(mid+half*x);freq(1)=hi;freq(end)=lo;
      values=zeros(deg+1,2);
      for j=1:numel(freq)
        values(j,:)=sample(freq(j));if ~chart,break;end
      end
      if ~chart,break;end
      scale=max(values(:,1));y=exp(values(:,1)-scale+1i*values(:,2));
      cc=fft([y;y(end-1:-1:2)])/(2*deg);cc=cc(1:deg+1);cc(2:end-1)=2*cc(2:end-1);
      tail=max(abs(cc(end-2:end)))/max(abs(cc));off=0;
      for xoff=[-.713,.811]
        off=max(off,abs(value(convert(mid+half*xoff))-LOCAL_cheb(cc,xoff)));
      end
      logs{pidx}.degree=deg;logs{pidx}.tail=tail;logs{pidx}.offgrid=off;
      localized=chart && tail<1e-10 && off<1e-9;
      if localized || ~chart,break;end
    end
    if localized
      cc=cc(1:find(abs(cc)>1e-13*max(abs(cc)),1,'last'));rr=LOCAL_colleague(cc);
      rr=real(rr(abs(imag(rr))<1e-6 & abs(real(rr))<=1+2e-12));
      seeds=convert(mid+half*rr(:));
      hk=.5*(hi-lo)*1e-3;
      for j=find(abs(y)<1e-8).'
        k=freq(j);
        if k-hk<lo,xp=[k,k+hk,k+2*hk];slot=1;
        elseif k+hk>hi,xp=[k-2*hk,k-hk,k];slot=3;
        else,xp=[k-hk,k,k+hk];slot=2;end
        f=arrayfun(@value,xp);sl=diff(f)/hk;
        if abs(diff(sl))<.02*max(realmin,max(abs(sl))) && ...
            abs(f(slot))<1e-5*max(realmin,hk*mean(abs(sl)))
          seeds(end+1)=k;
        end
      end
      polished=[];h=min(1e-5,(hi-lo)*.001);
      for k=LOCAL_unique(seeds)
        for it=1:8
          left=max(lo,k-h);right=min(hi,k+h);df=(value(right)-value(left))/(right-left);
          if ~chart,break;end
          step=real(value(k)/df);k=max(lo,min(hi,k-step));
          if abs(step)<2e-15,break;end
        end
        polished(end+1)=k;
      end
    end
    logs{pidx}.chart_ok=chart;logs{pidx}.localized=localized && chart;
    if localized && chart
      roots=[roots,polished];done(end+1,:)=ab;
    else
      if depth>=8,error('fallback:Depth','Eight subdivision levels exhausted.');end
      cut=convert(mid);visit([lo,cut],depth+1,w);visit([cut,hi],depth+1,w);
    end
    function k=convert(u)
      if square,k=w+sgn*u.^2;else,k=u;end
      k=max(lo,min(hi,k));
    end
    function a=sample(k)
      j0=find(key==k,1);if ~isempty(j0),a=obs(j0,:);return;end
      record(k);b=border_data(k,c,false);mat=border_matrix(b,anchor);
      if isempty(mat),chart=false;a=[NaN,NaN];return;end
      a=log_det(dr.*mat.*dc);detcalls=detcalls+1;key(end+1)=k;obs(end+1,:)=a;
      logs{pidx}.n_eval=numel(key);
    end
    function v=value(k)
      a=sample(k);v=exp(a(1)-scale+1i*a(2));
    end
  end
end
function r=LOCAL_unique(v)
  % Deduplicate overlapping panel and node proposals after polishing.
  r=sort(v(:).');if ~isempty(r),r=r([true,diff(r)>2e-12]);end
end
function v=LOCAL_cheb(cc,x)
  % Clenshaw evaluation in the Chebyshev basis.
  t=0;u=0;for j=numel(cc):-1:2,z=2*x*t-u+cc(j);u=t;t=z;end
  v=x*t-u+cc(1);
end
function r=LOCAL_colleague(c)
  % Chebyshev colleague matrix used in the reference determinant search.
  n=numel(c)-1;if n==0,r=[];return;elseif n==1,r=-c(1)/c(2);return;end
  A=zeros(n);A(2,1)=1;for j=2:n,A(j-1,j)=.5;if j<n,A(j+1,j)=.5;end;end
  A(:,n)=A(:,n)-c(1:n)/(2*c(end));r=eig(A);
end
