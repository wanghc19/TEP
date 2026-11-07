function study(out,mode)
% Measure Rayleigh truncation and flux diagnostics using explicit cases.
% Input: output directory and mode: pilot, part1, part2, cutcheck or cutpoles.
% Output: incremental JSON (JavaScript Object Notation) scalar records.
  maxNumCompThreads(5);started=tic;
  switch mode
    case 'pilot'
      c=LOCAL_config('ex1',128,6,.5,0);
      r=LOCAL_root(c,1.558437894182088,out,'regression');
      assert(abs(r.k-1.558437894182088)<=2e-14,'study:Regression','Reference root failed');
      LOCAL_save(out,'regression',r);
      l=search_i9_physics('leads',r.k,'fine',c);
      g=l.channels.gamma_m;J=LOCAL_J(g);n=numel(g);
      E=diag(exp(1i*g));O=zeros(n);
      empty=struct('R_L',O,'R_R',O,'T_LR',E,'T_RL',E);
      v=LOCAL_flux(empty,g,false);v.trace_check=LOCAL_trace_check(g,l.channels.beta_m,c.model.d);
      assert(v.flux_defect<1e-13 && v.trace_check<1e-13,'study:EmptyFlux','Empty cell flux normalization failed');
      LOCAL_save(out,'empty-flux',v);
      v=LOCAL_flux(l.positive,g,false);v.k=r.k;LOCAL_save(out,'rod-flux',v);
      q=struct('start',r.k,'side','positive');v=find_cut(q,c);LOCAL_save(out,'cut-location',v);
      v=LOCAL_geometry();LOCAL_save(out,'geometry',v);
    case 'part1'
      all={};
      jobs={'ex1',128,0;'ex1',192,0;'ex2',128,0;'w3',128,0; ...
        'ex1',128,-.04;'ex1',128,.06;'ex1',128,.16};
      for jj=1:size(jobs,1)
        name=jobs{jj,1};N=jobs{jj,2};cut=jobs{jj,3};
        beta=.5;seed=1.558437894182088;
        if strcmp(name,'ex2'),seed=1.8916961400527375;end
        if strcmp(name,'w3'),beta=1.67541;seed=2.010621021758152;end
        base=sprintf('%s-N%d-cut%+.3f',name,N,cut);
        for M=[24,1:8]
          c=LOCAL_config(name,N,M,beta,cut);
          tag=sprintf('%s-M%d',base,M);LOCAL_part(out,tag);
          try
            r=LOCAL_root(c,seed,out,tag);r.model=name;r.N=N;r.M=M;r.cut=cut;r.beta=beta;
            if M==24,ref=r.k;end
            r.reference=ref;r.error=abs(r.k-ref);r.status='MEASURED';
          catch err
            r=struct('status','ERROR','model',name,'N',N,'M',M,'cut',cut,'identifier',err.identifier,'message',err.message,'stack',err.stack);
          end
          LOCAL_save(out,tag,r);all{end+1}=r;LOCAL_save(out,'roots',all);
        end
      end
      LOCAL_part(out,'cut-window-check');LOCAL_save(out,'cut-window',LOCAL_cutwindow());
    case 'cutcheck'
      LOCAL_part(out,'full-gap-cut-check');
      LOCAL_save(out,'cut-window',LOCAL_cutwindow(linspace(1.317414080243+1e-4,2.380844148165-1e-4,81)));
    case 'cutpoles'
      LOCAL_part(out,'cut-pole-location');
      LOCAL_save(out,'cut-poles',LOCAL_cutpoles());
    case 'part2'
      rows={};
      % Common gap and each individual lead edge from failure-probe-v1.
      lo=[1.312557304887,1.317414080243];hi=[2.395219092458,2.380844148165];
      grid=linspace(lo(2)+.001,hi(2)-.001,21);jobs={};
      for k=grid,jobs(end+1,:)={'a',k,.5};end
      for ed=[lo,hi]
        direction=1;if ed>2,direction=-1;end
        for t=[1e-2,1e-3,1e-4]
          jobs(end+1,:)={'b',ed+direction*t,.5};
        end
      end
      for delta=[-.1,-.01,-.001,-.0001,.0001,.001,.01,.1]
        jobs(end+1,:)={'c',1.98154+delta,1.98154};
      end
      for k=[1.30,1.31,1.316,2.382,2.39,2.40]
        jobs(end+1,:)={'d',k,.5};
      end
      for j=1:size(jobs,1)
        c=LOCAL_config('ex1',128,6,jobs{j,3},0);k=jobs{j,2};tag=sprintf('point-%03d',j);LOCAL_part(out,tag);tm=tic;
        try
          l=search_i9_physics('leads',k,'fine',c);
          for side=1:2
            names={'negative','positive'};name=names{side};
            v=LOCAL_flux(l.(name),l.channels.gamma_m,side==1);
            v.location=jobs{j,1};v.k=k;v.beta=c.model.beta;v.side=name;
            v.qualified_status=l.([name,'_diagnostic']).status;v.seconds=toc(tm);
            rows{end+1}=v;
          end
        catch err
          rows{end+1}=struct('location',jobs{j,1},'k',k,'beta',c.model.beta,'status','ERROR','message',err.message);
        end
        LOCAL_save(out,'dimension',rows);
      end
    otherwise,error('study:Mode','Unknown mode');
  end
  LOCAL_save(out,'completion',struct('mode',mode,'seconds',toc(started),'threads',maxNumCompThreads));
end

function rows=LOCAL_cutpoles()
  rows={};cuts=[.06,.16];brackets=[1.317514080243,1.34409483194105;1.3706755836391,1.39725633533715];
  for j=1:2
    dx=cuts(j);bracket=brackets(j,:);
    opts=optimset('TolX',2e-14,'Display','off');
    [k,value,flag,info]=fminbnd(@objective,bracket(1),bracket(2),opts);
    [~,v]=objective(k);[~,vl]=objective(k-1e-6);[~,vr]=objective(k+1e-6);
    rows{end+1}=struct('cut',dx,'bracket',bracket,'k',k,'D_min',sqrt(value), ...
      'exitflag',flag,'iterations',info.iterations,'function_count',info.funcCount, ...
      'DtN_extreme_before',vl.extreme,'DtN_extreme_after',vr.extreme,'unit_distance',v.distance);
  end
  function [value,extra]=objective(k)
    c=LOCAL_config('ex1',128,6,.5,dx);n=c.common.K;
    l=search_i9_physics('leads',k,'fine',c);Z=l.positive.Z;g=l.channels.gamma_m;
    D=Z(1:n,:)+Z(n+1:end,:);N=1i*diag(g)*(Z(1:n,:)-Z(n+1:end,:));
    value=min(svd(D))^2;L=N/D;ev=eig((L+L')/2);[~,i]=max(abs(ev));
    s=l.positive;O=zeros(n);I=eye(n);
    A=[-s.R_L,I;s.T_LR,O];B=[O,s.T_RL;I,-s.R_R];w=abs(eig(A,B));
    extra=struct('extreme',real(ev(i)),'distance',min(abs(w-1)));
  end
end

function c=LOCAL_config(name,N,M,beta,cut)
  model=name;if strcmp(model,'ex1'),model='reference';end
  q=struct('model',model,'N',N,'M',M,'beta',beta,'cuts',[0,cut]);
  c=probe_config(q);c.backend.threads=5;
end

function r=LOCAL_root(c,seed,out,tag)
  tm=tic;k=seed;history=[];calls=0;
  for it=1:8
    [a,p]=sample(k);[am,pm]=sample(k-1e-6);[ap,pp]=sample(k+1e-6);
    step=2e-6/(exp(ap-a+1i*(pp-p))-exp(am-a+1i*(pm-p)));
    history(end+1,:)=[k,real(step),imag(step)];
    if abs(real(step))<5e-16 || k-real(step)==k,break;end
    assert(abs(real(step))<.04,'study:RootStep','Root step left its local neighborhood');
    k=k-real(step);
  end
  l=search_i9_physics('leads',k,'fine',c);calls=calls+1;
  [metric,e]=search_i9_physics('match',k,'fine',c,l);calls=calls+1;
  n=c.common.K;q=e.q;zL=[q(1:n);e.center.R_L*q(1:n)+e.center.T_RL*q(n+1:end)];
  zR=[e.center.T_LR*q(1:n)+e.center.R_R*q(n+1:end);q(n+1:end)];
  r=struct('k',k,'ratio',metric.aphys_ratio,'sigma',metric.aphys_sigma,'history',history,'calls',calls,'seconds',toc(tm), ...
    'D_min',[min(svd(l.negative.Z(1:n,:)+l.negative.Z(n+1:end,:))),min(svd(l.positive.Z(1:n,:)+l.positive.Z(n+1:end,:)))], ...
    'm',(-c.common.M:c.common.M).','coeff_abs',[abs(zL(1:n)),abs(zL(n+1:end)),abs(zR(1:n)),abs(zR(n+1:end))]);
  fprintf('ROOT %s k=%.17g ratio=%.3g calls=%d seconds=%.2f\n',tag,k,r.ratio,calls,r.seconds);
  function [a,p]=sample(t)
    ld=search_i9_physics('leads',t,'fine',c);calls=calls+1;
    [~,ee]=search_i9_physics('match',t,'fine',c,ld);calls=calls+1;
    [~,U,P]=lu(ee.matching.Adef);z=diag(U);a=sum(log(abs(z)));p=angle(det(P)*prod(z./abs(z)));
  end
end

function J=LOCAL_J(g)
  J=[diag(real(g)),-1i*diag(imag(g));1i*diag(imag(g)),-diag(real(g))];
end

function r=LOCAL_flux(s,g,reverse)
  n=numel(g);I=eye(n);O=zeros(n);J=LOCAL_J(g);
  G=[I,O;s.R_L,s.T_RL;s.T_LR,s.R_R;O,I];[X,~]=qr(G,0);
  defect=norm(X'*blkdiag(J,-J)*X,2)/norm(J,2);
  A=[-s.R_L,I;s.T_LR,O];B=[O,s.T_RL;I,-s.R_R];
  constraint=norm([A,-B]*X,'fro')/max(1,hypot(norm(A,'fro'),norm(B,'fro')));
  if reverse,[A,B]=deal(B,A);end
  scale=hypot(norm(A,'fro'),norm(B,'fro'));[S,T,Q,Z]=qz(A/scale,B/scale,'complex');
  alpha=diag(S);theta=diag(T);mask=abs(alpha)<abs(theta);count=sum(mask);
  w=abs(alpha)./abs(theta);finite=isfinite(w);wi=w(mask);wo=w(~mask);
  inside=0;if ~isempty(wi),inside=max(wi);end
  outside=Inf;if ~isempty(wo),outside=min(wo);end
  neutral=0;
  if count>0
    [~,~,~,Zs]=ordqz(S,T,Q,Z,mask);Zs=Zs(:,1:count);neutral=norm(Zs'*J*Zs,2)/norm(J,2);
  end
  dist=min(abs(w(finite)-1));
  r=struct('status','MEASURED','K',n,'M',(n-1)/2,'flux_defect',defect,'neutrality',neutral, ...
    'inside_count',count,'inside_qualified',sum(w<1-1e-8),'near_unit_count',sum(abs(w-1)<=1e-8), ...
    'outside_count',sum(w>1),'max_inside',inside,'min_outside',outside,'unit_distance',dist, ...
    'gamma_min',min(abs(g)),'J_norm',norm(J,2),'positive_signature',sum(eig(J)>0),'negative_signature',sum(eig(J)<0), ...
    'basis_constraint_relative',constraint,'basis_orthogonality',norm(X'*X-eye(2*n),2), ...
    'flux_defect_absolute',defect*norm(J,2),'retained_propagating_count',sum(abs(imag(g))<1e-14 & real(g)>0), ...
    'defect_below_distance',defect<dist,'count_is_K',count==n,'multipliers_abs',w);
end

function e=LOCAL_trace_check(g,beta,d)
  n=numel(g);a=sin((1:n)')+1i*cos(2*(1:n)');b=cos((1:n)')+1i*sin(3*(1:n)');
  y=((0:1023)'+.25)*d/1024-d/2;P=exp(1i*y*beta.')/sqrt(d);
  u=P*(a+b);ux=P*(1i*g.*(a-b));direct=imag(sum(conj(u).*ux)*d/1024);
  z=[a;b];formula=real(z'*LOCAL_J(g)*z);e=abs(direct-formula)/max(1,abs(formula));
end

function r=LOCAL_geometry()
  [C,~]=geom.construct_cont(65536,'star',0,0);star=[min(C(1,:)),max(C(1,:))];
  c=LOCAL_config('ex1',128,6,.5,0);[A,~]=search_i9_geometry(65536,.12,.2,c.model);[B,~]=search_i9_geometry(65536,.20,.2,c.model);
  left=[min(A(1,:)),max(A(1,:))];right=[min(B(1,:)),max(B(1,:))];
  ex1=[star(1)-(-1+left(2)),1+right(1)-star(2),1-diff(left),1-diff(right)];
  th=.13;rot=cos(th)*B(1,:)-sin(th)*B(4,:);r2=[min(rot),max(rot)];
  ex2=[(.5+.85/2+r2(1))-(-1+left(2)),1-diff(left),.85-diff(r2)];
  h=sqrt(3)/2;
  r=struct('star_x',star,'left_local_x',left,'right_local_x',right,'rotated_right_x',r2, ...
    'ex1_strips',ex1,'ex1_wmin',min(ex1),'ex2_strips',ex2,'ex2_wmin',min(ex2), ...
    'w3_h',h,'w3_lead_row_centers',[2*h,-.25;3*h,.25;4*h,-.25], ...
    'w3_strips',[4*h-.4,h-.4],'w3_wmin',h-.4, ...
    'cuts',[-.04,.06,.16],'center_delta',.5+[-.04,.06,.16]-star(2));
end

function rows=LOCAL_cutwindow(grid)
  if nargin==0,grid=linspace(1.451,2.249,41);end
  rows={};c=LOCAL_config('ex1',128,6,.5,0);n=c.common.K;I=eye(n);O=zeros(n);
  for k=grid
    l=search_i9_physics('leads',k,'fine',c);s=l.positive;g=l.channels.gamma_m(:);
    for dx=[-.04,0,.06,.16]
      u=exp(1i*g*dx);v=1./u;
      A=[-(v.*s.R_L).*v.',I;(u.*s.T_LR).*v.',O];B=[O,(v.*s.T_RL).*u.';I,-(u.*s.R_R).*u.'];
      [S,T,Q,Z]=qz(A,B,'complex');mask=abs(diag(S))<abs(diag(T));
      [~,~,~,Z]=ordqz(S,T,Q,Z,mask);D=Z(1:n,1:n)+Z(n+1:end,1:n);
      rows{end+1}=struct('k',k,'cut',dx,'D_min',min(svd(D)));
    end
  end
end

function LOCAL_part(out,label)
  fid=fopen(fullfile(out,'part.txt'),'w');fprintf(fid,'%s',label);fclose(fid);
end
function LOCAL_save(out,label,value)
  fid=fopen(fullfile(out,[label,'.json']),'w');fwrite(fid,jsonencode(value));fclose(fid);
end
