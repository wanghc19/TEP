function result=determinant_scan(out,settings)
%DETERMINANT_SCAN Chebyshev interpolation of the finite matching determinant.
% Input
%   out: explicit fresh output directory; settings: mode and degree parameters.
% Output
%   result: scalar evaluation ledger, interpolation coefficients, and roots.
  maxNumCompThreads(5); started=tic; config=search_i9_config();
  config.backend.threads=5; points=struct([]); panels={}; checks={};
  if strcmp(settings.mode,'bracket')
    panel=study([1.525,1.5875],settings.degrees,'bracket'); panels={panel};
    root=choose(panel); polished=polish(root,panel,3);
    % Two fresh calls time the unchanged singular-value path at the same threads.
    timing=[];
    for k=[1.54,1.58]
      t=tic;ld=search_i9_physics('leads',k,'fine',config);
      [v,e]=search_i9_physics('match',k,'fine',config,ld);
      timing=[timing;[k,toc(t),ld.seconds,v.seconds,v.aphys_ratio]]; %#ok<AGROW>
      checks{end+1}=detcheck(e.matching.Adef,e.matching.row_weight,e.matching.column_weight,k);
    end
    result=struct('panels',{panels},'polished',polished,'sigma_retiming',timing,'checks',{checks});
  else
    globalpanel=study([1.451,2.249],settings.degrees,'window');panels={globalpanel};
    if globalpanel.last_tail>settings.tail_tol || globalpanel.log_span>settings.split_span
      bounds=linspace(1.451,2.249,5);
      for j=1:4
        panels{end+1}=study(bounds(j:j+1),[8,16,32,64],sprintf('sub-%d',j));
      end
    end
    roots=[];
    if numel(panels)>1, selected=2:numel(panels);else,selected=1;end
    for j=selected
      rr=panels{j}.levels{end}.roots;
      rr=rr(abs(rr(:,2))<1e-6 & rr(:,1)>panels{j}.bounds(1) & rr(:,1)<panels{j}.bounds(2),1);
      for k=rr.', roots=[roots;k,j];end %#ok<AGROW>
    end
    polished={};
    for j=1:size(roots,1),polished{end+1}=polish(roots(j,1),panels{roots(j,2)},3);end
    result=struct('panels',{panels},'candidate_roots',roots,'polished',{polished},'checks',{checks});
  end
  result.settings=settings;result.config=config;result.points=points;result.evaluations=numel(points);
  result.seconds=toc(started);result.reference_k=1.5584378941820909;
  result.minimum_positive_rcond=min([points.positive_rcond]);result.minimum_negative_rcond=min([points.negative_rcond]);
  writejson(fullfile(out,'result.json'),result);
  fprintf('COMPLETE %s evaluations %d seconds %.3f\n',settings.mode,numel(points),result.seconds);
  function p=study(ab,degrees,label)
    p=struct('bounds',ab,'levels',{{}},'label',label); center=mean(ab);half=diff(ab)/2;
    ref=evaluate(center,false);L0=ref.logabs;phase0=ref.phase;
    for n=degrees
      part(label,n);x=cos(pi*(0:n)'/n);ks=center+half*x;f=zeros(n+1,1);logs=f;
      for ii=1:n+1
        v=evaluate(ks(ii),false);f(ii)=exp(v.logabs-L0+1i*(v.phase-phase0));logs(ii)=v.logabs;
      end
      ex=[f;f(end-1:-1:2)]; c=fft(ex)/(2*n);c=c(1:n+1);c(2:n)=2*c(2:n);
      scale=max(abs(c));tail=max(abs(c(max(2,end-4):end)))/scale;
      % Trim only the roundoff plateau before constructing the colleague matrix.
      degree=find(abs(c)>1e-13*scale,1,'last')-1;
      rr=colleague(c(1:degree+1));rho=max(abs(rr+sqrt(rr.^2-1)),abs(rr-sqrt(rr.^2-1)));
      keep=rho<1.1;rk=center+half*rr(keep);
      off=[];
      for xx=[-.713,.137,.811]
        v=evaluate(center+half*xx,false);fv=exp(v.logabs-L0+1i*(v.phase-phase0));ip=chebval(c,xx);
        off=[off;[center+half*xx,real(fv),imag(fv),abs(fv-ip)/max(abs(f)),abs(fv-ip)/max(abs(fv),realmin)]]; %#ok<AGROW>
      end
      level=struct('degree',n,'used_degree',degree,'coeff_real',real(c),'coeff_imag',imag(c), ...
        'coefficient_relative',abs(c)/scale,'tail',tail,'roots',[real(rk),imag(rk)], ...
        'root_rho',rho(keep),'offgrid',off,'evaluations_so_far',numel(points));
      p.levels{end+1}=level;p.last_tail=tail;p.log_span=max(logs)-min(logs);p.log_reference=L0;p.phase_reference=phase0;
      writejson(fullfile(out,[label,'-progress.json']),p);
      fprintf('LEVEL %s n=%d tail %.3g roots %d evals %d\n',label,n,tail,numel(rk),numel(points));
      if ~strcmp(settings.mode,'bracket') && n>=16 && tail<settings.tail_tol,break;end
    end
  end
  function v=evaluate(k,fresh)
    hit=[];if ~isempty(points),hit=find([points.k]==k,1);end
    if ~isempty(hit)&&~fresh,v=points(hit);return;end
    t=tic;ld=search_i9_physics('leads',k,'fine',config);
    [m,e]=search_i9_physics('match',k,'fine',config,ld);
    A=e.matching.Adef;[la,ph]=logdet(A);d=e.matching.dtn_diagnostic;
    v=struct('k',k,'logabs',la,'phase',ph,'positive_rcond',d.positive_rcond, ...
      'negative_rcond',d.negative_rcond,'aphys_ratio',m.aphys_ratio,'seconds',toc(t), ...
      'lead_seconds',ld.seconds,'match_seconds',m.seconds,'assembly_defect',m.assembly_defect);
    points=[points,v]; %#ok<AGROW>
    writejson(fullfile(out,'points.json'),points);
    if numel(points)<=2
      checks{end+1}=detcheck(A,e.matching.row_weight,e.matching.column_weight,k);
    end
  end
  function h=polish(k,p,count)
    level=p.levels{end};c=complex(level.coeff_real,level.coeff_imag);ab=p.bounds;half=diff(ab)/2;center=mean(ab);hist=[];
    for it=1:count
      v=evaluate(k,false);fv=exp(v.logabs-p.log_reference+1i*(v.phase-p.phase_reference));x=(k-center)/half;
      der=chebval(chebder(c),x)/half;step=fv/der;
      hist=[hist;[k,real(step),imag(step),v.aphys_ratio]]; %#ok<AGROW>
      knew=k-real(step);if knew<ab(1)||knew>ab(2),break;end
      if knew==k,break;end
      k=knew;
    end
    v=evaluate(k,false);h=struct('k',k,'reference_error',k-1.5584378941820909, ...
      'aphys_ratio',v.aphys_ratio,'history',hist);fprintf('ROOT %.17g diff %.3g ratio %.3g\n',k,h.reference_error,h.aphys_ratio);
  end
  function part(label,n)
    f=fopen(fullfile(out,'part.txt'),'w');fprintf(f,'%s-%d',label,n);fclose(f);
  end
end
function k=choose(p)
  r=p.levels{end}.roots;[~,ii]=min(abs(r(:,2)));k=r(ii,1);
end
function [a,p]=logdet(A)
  [~,U,P]=lu(A);z=diag(U);a=sum(log(abs(z)));p=angle(det(P))+sum(angle(z));p=angle(exp(1i*p));
end
function c=detcheck(A,r,w,k)
  [a,p]=logdet(A);s=svd(A);sv=sum(log(s));[b,q]=logdet(r.*A.*w.');
  expected=a+sum(log(r))+sum(log(w));
  c=struct('k',k,'lu_logabs',a,'svd_logabs',sv,'log_difference',a-sv, ...
    'scaled_log_difference',b-expected,'scaled_phase_difference',angle(exp(1i*(q-p))));
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
