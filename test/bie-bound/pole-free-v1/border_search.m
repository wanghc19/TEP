function out=border_search(q,c)
  % Locate all near-real zeros of the sampled, analytically gauged determinant.
  % Input: explicit window and discretized example. Output: proposals and panel audits.
  panels={};proposals=[];evals=0;
  visit(q.window,0);
  out=struct('proposals',LOCAL_unique(proposals),'panels',{panels},'evaluations',evals);

  function visit(ab,depth)
    mid=mean(ab);half=diff(ab)/2;ref=border_data(mid,c,false);evals=evals+1;
    anchor=struct('L',ref.ZL,'R',ref.ZR);
    [base,ref_quality]=border_matrix(ref,anchor);dr=1./vecnorm(base,2,2);dc=1./vecnorm(dr.*base,2,1);
    ks=mid;logs=log_det(dr.*base.*dc);quality=ref_quality;
    localized=false;levels={};chart_ok=true;
    for degree=[8,16,32,64]
      x=cos(pi*(0:degree)'/degree);x(degree/2+1)=0;freq=mid+half*x;
      obs=zeros(degree+1,2);
      for j=1:numel(freq)
        obs(j,:)=sample(freq(j));
        if ~chart_ok,break;end
      end
      if ~chart_ok,break;end
      scale=max(obs(:,1));y=exp(obs(:,1)-scale+1i*obs(:,2));
      cf=fft([y;y(end-1:-1:2)])/(2*degree);cf=cf(1:degree+1);cf(2:end-1)=2*cf(2:end-1);
      trail=max(abs(cf(end-2:end)))/max(abs(cf));
      xx=[-.713,.811];off=0;
      for xoff=xx
        fv=value(mid+half*xoff,scale);
        off=max(off,abs(fv-LOCAL_cheb(cf,xoff)));
      end
      levels{end+1}=struct('degree',degree,'tail',trail,'offgrid',off, ...
        'span',max(obs(:,1))-min(obs(:,1)),'smallest_relative_node',min(abs(y)));
      if ~chart_ok,break;end
      localized=trail<1e-10 && off<1e-9;
      if localized,break;end
    end
    nodes={};cand=[];
    if localized
      cc=cf(1:find(abs(cf)>1e-13*max(abs(cf)),1,'last'));
      rr=LOCAL_colleague(cc);
      rr=real(rr(abs(imag(rr))<1e-6 & abs(real(rr))<=1+2e-12));
      seeds=max(ab(1),min(ab(2),mid+half*rr(:)));
      for j=find(abs(y)<1e-8).'
        t=freq(j);h=1e-3*half;
        % One-sided differences at a panel boundary stay inside the window.
        if t-h<ab(1),xp=[t,t+h,t+2*h];slot=1;
        elseif t+h>ab(2),xp=[t-2*h,t-h,t];slot=3;
        else,xp=[t-h,t,t+h];slot=2;end
        f=arrayfun(@(v)value(v,scale),xp);if ~chart_ok,break;end
        sl=diff(f)/h;
        change=abs(diff(sl))/max(realmin,max(abs(sl)));
        small=abs(f(slot))/max(realmin,h*mean(abs(sl)));
        simple=change<.02 && small<1e-5;
        nodes{end+1}=struct('k',t,'relative_value',abs(y(j)),'slope_change',change,'relative_to_slope',small,'simple',simple);
        if simple,seeds(end+1)=t;end
      end
      for seed=LOCAL_unique(seeds)
        if ~chart_ok,break;end
        t=seed;h=min(1e-5,half*.002);
        for it=1:8
          left=max(ab(1),t-h);right=min(ab(2),t+h);
          df=(value(right,scale)-value(left,scale))/(right-left);
          if ~chart_ok,break;end
          if abs(df)<realmin,error('border:Derivative','Zero derivative during polish.');end
          step=real(value(t,scale)/df);if ~chart_ok,break;end
          next=min(ab(2),max(ab(1),t-step));
          t=next;if abs(step)<2e-15,break;end
        end
        cand(end+1)=t;
      end
    end
    panels{end+1}=struct('bounds',ab,'depth',depth,'localized',localized,'chart_ok',chart_ok, ...
      'min_overlap_sigma',min(min(quality(:,1:2))),'max_overlap_cond',max(max(quality(:,3:4))), ...
      'levels',{levels},'tiny_nodes',{nodes},'roots',LOCAL_unique(cand));
    if ~localized || ~chart_ok
      assert(depth<8,'border:Panel','Unresolved interpolation or chart after eight splits.');
      visit([ab(1),mid],depth+1);visit([mid,ab(2)],depth+1);
    else
      proposals=[proposals,cand];
    end

    function a=sample(k)
      ix=find(ks==k,1);if ~isempty(ix),a=logs(ix,:);return;end
      b=border_data(k,c,false);evals=evals+1;
      [matrix,cv]=border_matrix(b,anchor);quality(end+1,:)=cv;
      if isempty(matrix),chart_ok=false;a=[NaN,NaN];return;end
      a=log_det(dr.*matrix.*dc);ks(end+1)=k;logs(end+1,:)=a;
    end
    function v=value(k,scale0)
      a=sample(k);v=exp(a(1)-scale0+1i*a(2));
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
