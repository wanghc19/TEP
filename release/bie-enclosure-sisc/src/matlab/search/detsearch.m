% Copied from test/bie-bound/pipeline-v1/search/detsearch.m; release R1 path/data interfaces may be adapted.
% Copied from test/bie-bound/detsearch-v1/detsearch.m; pipeline adaptations documented in README.
function result=detsearch(out,settings)
%DETSEARCH Determinant root search with I9 gap classification and fallback.
% Input
%   out: explicit output directory; settings: search_config output.
% Output
%   result: candidates, binary64 representations, stages, coefficients, ledger.
% BIE means boundary integral equation; LU means lower-upper factorization;
% DtN means Dirichlet-to-Neumann; SVD means singular value decomposition.
  maxNumCompThreads(settings.threads);timer=tic;config=search_i9_config();
  if isfield(settings,'resolution') && strcmp(settings.resolution,'coarse')
    config.resolutions.fine=config.resolutions.coarse;
  end
  config.backend.threads=settings.threads;config.resources.soft_seconds=1800;
  config.resources.hard_seconds=2400; points=struct([]);panels={};candidates={};fallbacks={};
  times=struct('gap',0,'validation',0,'determinant',0,'polish',0,'confirmation',0,'fallback',0);
  counts=struct('determinant',0,'polish',0,'confirmation',0,'fallback',0);
  if strcmp(settings.mode,'forced-fallback')
    i9_adapter('reset','',config);domain=[1.451,2.249];
    ab=settings.forced_test_center+[-1,1]*settings.forced_test_halfwidth;
    fallback(ab,domain,{'FORCED_TEST'});
    gaps={struct('bounds',domain,'status','TEST_ONLY')};gaplog=struct();
  else
    part('gap');gapdir=fullfile(out,'gap');mkdir(gapdir);
    state=i9_adapter('gap',gapdir,config);gaps=state.common_gaps;gaplog=state.lead_log;
    times.gap=state.timing.gap;times.validation=state.timing.validation;
    assert(~isempty(gaps) && any(cellfun(@(x)strcmp(x.status,'USABLE'),gaps)),'detsearch:NoGap','No usable common gap returned.');
    for j=1:numel(gaps)
      if strcmp(gaps{j}.status,'USABLE'), study(gaps{j}.bounds,gaps{j}.bounds,0);end
    end
  end
  % Deduplicate shared panel endpoints only after confirming all root paths.
  if ~isempty(candidates)
    ks=cellfun(@(x)x.k,candidates);[~,ord]=sort(ks);candidates=candidates(ord);
    keep=true(size(candidates));for j=2:numel(candidates)
      if abs(candidates{j}.k-candidates{j-1}.k)<settings.duplicate_tol,keep(j)=false;end
    end;candidates=candidates(keep);
  end
  status='COMPLETE';
  if any(cellfun(@(x)~strcmp(x.status,'SEARCH_FINISHED'),fallbacks))
    status='CANDIDATES_COMPLETE_WITH_UNRESOLVED_FALLBACK';
  end
  result=struct('status',status,'settings',settings,'config',config, ...
    'common_gaps',{gaps},'candidates',{candidates},'panels',{panels}, ...
    'fallbacks',{fallbacks},'fallback_fired',~isempty(fallbacks),'counts',counts, ...
    'timing',times,'science_seconds',toc(timer),'points',points,'gap_lead_log',gaplog, ...
    'environment',struct('threads',maxNumCompThreads,'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS'), ...
      'OMP_DYNAMIC',getenv('OMP_DYNAMIC'),'version',version));
  writejson(fullfile(out,'result.json'),result);writejson(fullfile(out,'candidates.json'),candidates);
  part('complete');fprintf('COMPLETE %s candidates %d seconds %.3f\n',settings.mode,numel(candidates),result.science_seconds);
  function study(ab,domain,depth)
    part(sprintf('determinant-depth-%d',depth));started=tic;mid=mean(ab);half=diff(ab)/2;
    ref=evaluate(mid,'determinant',false);levels={};lowcond=false;localized=false;
    for n=settings.degrees
      ks=mid+half*cos(pi*(0:n)'/n);f=zeros(n+1,1);logs=f;
      for ii=1:n+1
        v=evaluate(ks(ii),'determinant',false);
        f(ii)=exp(v.logabs-ref.logabs+1i*(v.phase-ref.phase));logs(ii)=v.logabs;
        lowcond=lowcond||min(v.positive_rcond,v.negative_rcond)<settings.rcond_min;
      end
      cc=fft([f;f(end-1:-1:2)])/(2*n);cc=cc(1:n+1);cc(2:n)=2*cc(2:n);
      tail=max(abs(cc(end-settings.tail_count+1:end)))/max(abs(cc));
      off=[];
      if tail<settings.localization_tol || n==settings.degrees(end)
        for x=settings.offgrid_x
          v=evaluate(mid+half*x,'determinant',false);
          lowcond=lowcond||min(v.positive_rcond,v.negative_rcond)<settings.rcond_min;fv=exp(v.logabs-ref.logabs+1i*(v.phase-ref.phase));
          off=[off;[mid+half*x,abs(fv-chebval(cc,x))/max(abs(f))]]; %#ok<AGROW>
        end
      end
      degree=find(abs(cc)>settings.coefficient_floor*max(abs(cc)),1,'last')-1;
      z=colleague(cc(1:degree+1));rho=max(abs(z+sqrt(z.^2-1)),abs(z-sqrt(z.^2-1)));
      roots=mid+half*z(rho<settings.ellipse_rho);
      level=struct('degree',n,'used_degree',degree,'tail',tail,'coeff_real',real(cc), ...
        'coeff_imag',imag(cc),'relative_coefficients',abs(cc)/max(abs(cc)), ...
        'roots',[real(roots),imag(roots)],'offgrid',off,'log_span',max(logs)-min(logs));
      levels{end+1}=level;
      localized=tail<settings.localization_tol && ~isempty(off) && max(off(:,2))<settings.offgrid_tol && level.log_span<settings.max_log_span;
      fprintf('LEVEL [%g,%g] n=%d tail %.3g localized %d\n',ab,n,tail,localized);
      if localized,break;end
    end
    panel=struct('bounds',ab,'depth',depth,'levels',{levels},'localized',localized, ...
      'low_rcond',lowcond,'log_reference',ref.logabs,'phase_reference',ref.phase);
    panels{end+1}=panel;writejson(fullfile(out,'panels.json'),panels);
    times.determinant=times.determinant+toc(started);
    if ~localized && depth<settings.max_depth
      study([ab(1),mid],domain,depth+1);study([mid,ab(2)],domain,depth+1);return;
    end
    rr=roots(abs(imag(roots))<settings.near_real_tol & real(roots)>=ab(1) & real(roots)<=ab(2));
    reasons={};if ~localized,reasons{end+1}='COEFFICIENT_OR_OFFGRID_CAP';end
    if lowcond,reasons{end+1}='DTN_RCOND';end
    close=false;if numel(rr)>1,close=any(diff(sort(real(rr)))<settings.root_separation);end
    if close,reasons{end+1}='CLOSE_ROOTS';end
    if isempty(rr)
      if ~isempty(reasons),fallback(ab,domain,reasons);end;return;
    end
    if close,fallback([max(ab(1),min(real(rr))-settings.fallback_halfwidth),min(ab(2),max(real(rr))+settings.fallback_halfwidth)],domain,reasons);return;end
    for k=real(rr).'
      if ~isempty(reasons)
        fallback([max(domain(1),k-settings.fallback_halfwidth),min(domain(2),k+settings.fallback_halfwidth)],domain,reasons);
      else
        [kp,hist,good]=polish(k,panel);
        if good
          part('confirmation');t=tic;v=evaluate(kp,'confirmation',true);times.confirmation=times.confirmation+toc(t);
          if v.aphys_ratio<=settings.confirm_ratio_max && min(v.positive_rcond,v.negative_rcond)>=settings.rcond_min
            candidates{end+1}=candidate(kp,v.aphys_ratio,hist,false,[]);
          else,good=false;end
        end
        if ~good,fallback([max(domain(1),k-settings.fallback_halfwidth),min(domain(2),k+settings.fallback_halfwidth)],domain,{'POLISH_OR_CONFIRMATION'});end
      end
    end
  end
  function [k,hist,good]=polish(k,panel)
    part('polish');t=tic;ab=panel.bounds;mid=mean(ab);half=diff(ab)/2;
    l=panel.levels{end};cc=complex(l.coeff_real,l.coeff_imag);dd=chebder(cc);hist=[];good=false;
    for it=1:settings.polish_limit
      v=evaluate(k,'polish',false);fv=exp(v.logabs-panel.log_reference+1i*(v.phase-panel.phase_reference));
      derivative=chebval(dd,(k-mid)/half)/half;step=fv/derivative;
      hist=[hist;[k,real(step),imag(step),v.aphys_ratio]]; %#ok<AGROW>
      if ~isfinite(step)||derivative==0||min(v.positive_rcond,v.negative_rcond)<settings.rcond_min,break;end
      if abs(step)<settings.polish_tol,good=true;break;end
      knew=k-real(step);if knew<ab(1)||knew>ab(2),break;end
      if knew==k,good=true;break;end;k=knew;
    end
    times.polish=times.polish+toc(t);
  end
  function v=evaluate(k,stage,fresh)
    idx=[];if ~isempty(points),idx=find([points.k]==k,1);end
    if ~fresh && ~isempty(idx),v=points(idx);return;end
    t=tic;
    if fresh,ld=search_i9_physics('leads',k,'fine',config);else,ld=i9_adapter('lead','',config,k);end
    [m,e]=search_i9_physics('match',k,'fine',config,ld);[la,ph]=logdet(e.matching.Adef);d=e.matching.dtn_diagnostic;
    v=struct('k',k,'k_hex',num2hex(k),'stage',stage,'logabs',la,'phase',ph, ...
      'positive_rcond',d.positive_rcond,'negative_rcond',d.negative_rcond, ...
      'aphys_ratio',m.aphys_ratio,'seconds',toc(t));points=[points,v];counts.(stage)=counts.(stage)+1;
    writejson(fullfile(out,'points.json'),points);
  end
  function fallback(ab,domain,reasons)
    part('fallback');t=tic;fd=fullfile(out,sprintf('fallback-%03d',numel(fallbacks)+1));mkdir(fd);
    fs=i9_adapter('fallback',fd,config,struct('bounds',ab,'domain',domain));
    accepted={};for jj=1:numel(fs.candidates)
      c=fs.candidates{jj};if ~strcmp(c.status,'COMPLETE'),continue;end
      confirmed=fs.points{c.confirmation_id};
      assert(confirmed.aphys_ratio<=settings.confirm_ratio_max,'detsearch:FallbackRatio','Fallback confirmation is not small.');
      c2=candidate(c.k,confirmed.aphys_ratio,[],true,struct('history',{fs.history},'final_width',c.W));
      candidates{end+1}=c2;accepted{end+1}=c2;
    end
    assert(~isempty(accepted),'detsearch:UnresolvedFallback','I9 fallback returned no complete candidate.');
    counts.fallback=counts.fallback+fs.counters.computed;
    fallbacks{end+1}=struct('bounds',ab,'reasons',{reasons},'status',fs.status, ...
      'evaluations',fs.counters.computed,'pending_edge_count',fs.pending_edge_count,'seconds',toc(t),'candidates',{accepted});
    times.fallback=times.fallback+toc(t);
  end
  function c=candidate(k,ratio,history,usedfallback,detail)
    dec='';for digits=1:17
      dec=sprintf('%.*g',digits,k);if strcmp(num2hex(str2double(dec)),num2hex(k)),break;end
    end
    c=struct('k',k,'k_decimal',dec,'k_hex',num2hex(k),'aphys_ratio',ratio, ...
      'polish_history',history,'fallback_used',usedfallback,'fallback_detail',detail);
    fprintf('CANDIDATE %s hex=%s ratio=%.3g fallback=%d\n',dec,c.k_hex,ratio,usedfallback);
  end
  function part(name)
    f=fopen(fullfile(out,'part.txt'),'w');fprintf(f,'%s',name);fclose(f);
  end
end
function [a,p]=logdet(A)
  [~,U,P]=lu(A);z=diag(U);a=sum(log(abs(z)));p=angle(exp(1i*(angle(det(P))+sum(angle(z)))));
end
function y=chebval(c,x)
  b1=0;b2=0;for j=numel(c):-1:2,b0=2*x*b1-b2+c(j);b2=b1;b1=b0;end;y=x*b1-b2+c(1);
end
function d=chebder(c)
  n=numel(c)-1;d=zeros(n,1);if n==0,d=0;return;end
  d(n)=2*n*c(n+1);if n>1,d(n-1)=2*(n-1)*c(n);end
  for j=n-2:-1:1,d(j)=d(j+2)+2*j*c(j+1);end;d(1)=d(1)/2;
end
function r=colleague(c)
  n=numel(c)-1;if n==0,r=[];return;elseif n==1,r=-c(1)/c(2);return;end
  C=zeros(n);C(2,1)=1;for j=2:n,C(j-1,j)=.5;if j<n,C(j+1,j)=.5;end;end
  C(:,n)=C(:,n)-c(1:n)/(2*c(n+1));r=eig(C);
end
function writejson(path,x)
  f=fopen(path,'w');assert(f>0);cl=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(x));
end
