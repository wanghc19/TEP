function wood_probe(out,mode)
% Measure threshold dependence in cell maps and matching matrices.
% Input: explicit output directory and mode: pilot, samples, controls or chebyshev.
% Output: small JSON (JavaScript Object Notation) records, with no field files.
  maxNumCompThreads(5);tm=tic;
  switch mode
    case 'pilot'
      c=LOCAL_config(128,6,.5);k=1.558437894182088;
      history=[];
      for j=1:4
        f=LOCAL_det(k,c);fm=LOCAL_det(k-1e-6,c);fp=LOCAL_det(k+1e-6,c);
        step=2e-6/(exp(fp(1)-f(1)+1i*(fp(2)-f(2)))-exp(fm(1)-f(1)+1i*(fm(2)-f(2))));
        history(end+1,:)=[k,real(step)];
        if abs(real(step))<5e-16,break;end
        k=k-real(step);
      end
      assert(abs(k-1.558437894182088)<=2e-14,'wood:Regression','Reference root failed');
      LOCAL_save(out,'regression',struct('k',k,'difference',k-1.558437894182088,'history',history));
      rows={};
      for beta=[1.95,1.98154]
        for sign=[-1,1]
          LOCAL_part(out,'pilot-cell');
          [r,~]=LOCAL_sample(128,6,beta,sign*.1);rows{end+1}=r;
        end
      end
      LOCAL_save(out,'pilot',rows);
    case 'samples'
      rows={};
      for beta=[1.95,1.98154]
        for sign=[-1,1]
          for power=1:7
            t=sign*10^(-power);levels=[128,6;192,12;192,6];previous=[];
            for lev=1:3
              N=levels(lev,1);M=levels(lev,2);LOCAL_part(out,sprintf('samples-N%d-M%d',N,M));
              [r,full]=LOCAL_sample(N,M,beta,t);
              if lev==1
                previous=full;
              else
                r.grid_difference=LOCAL_compare(previous,full);
              end
              rows{end+1}=r;
            end
            LOCAL_save(out,'samples',rows);
            fprintf('SAMPLE beta %.8f detuning %+.1e done\n',beta,t);
          end
        end
      end
    case 'controls'
      rows={};beta=1.98154;
      for sign=[-1,1]
        for t=sign*[1e-4,1e-6,1e-7]
          backends={struct('fmm_eps',1e-14,'direct',false),struct('fmm_eps',1e-12,'direct',true)};
          for j=1:2
            LOCAL_part(out,sprintf('backend-control-%d',j));
            [r,~]=LOCAL_sample(128,6,beta,t,backends{j});r.backend=backends{j};rows{end+1}=r;
            LOCAL_save(out,'controls',rows);
          end
        end
      end
      LOCAL_part(out,'cauchy-root');LOCAL_save(out,'cauchy-root',LOCAL_cauchyroot());
    case 'chebyshev'
      rows={};beta=1.98154;
      for lev=1:2
        N=128;M=6;if lev==2,N=192;M=12;end
        [~,reference]=LOCAL_sample(N,M,beta,.005);
        anchors=LOCAL_anchors(reference);
        [H,~]=LOCAL_matrices(reference,anchors);
        scales=cell(size(H));
        for j=1:numel(H)
          dr=1./vecnorm(H{j},2,2);dc=1./vecnorm(dr.*H{j},2,1);
          scales{j}=struct('row',dr,'column',dc);
        end
        % Odd polynomial degree: no Lobatto node at the exact threshold.
        degree=65;
        for node=0:degree
          x=cos(pi*node/degree);t=.01*x;
          assert(beta+t~=beta,'wood:ExactNode','The exact Wood point must be absent');
          LOCAL_part(out,sprintf('chebyshev-N%d-node%d',N,node));
          [r,full]=LOCAL_sample(N,M,beta,t);
          [H,quality]=LOCAL_matrices(full,anchors);values={};
          for j=1:numel(H)
            v=scales{j};A=v.row.*H{j}.*v.column;
            [~,U,P]=lu(A);z=diag(U);singular=svd(A);
            values{j}=struct('logabs',sum(log(abs(z))),'phase',angle(det(P)*prod(z./abs(z))), ...
              'sigma_min',singular(end),'sigma_max',singular(1));
          end
          rows{end+1}=struct('N',N,'M',M,'beta',beta,'degree',degree,'node',node,'x',x,'t',t,'k',beta+t, ...
            'values',{values},'quality',quality,'cell_rcond',[r.lead.rcond,r.center.rcond]);
          LOCAL_save(out,'chebyshev',rows);
        end
      end
    otherwise,error('wood:Mode','Unknown mode');
  end
  LOCAL_save(out,'completion',struct('mode',mode,'seconds',toc(tm),'threads',maxNumCompThreads));
end

function c=LOCAL_config(N,M,beta)
  c=probe_config(struct('model','reference','N',N,'M',M,'beta',beta));
  c.backend.threads=5;c.fields=true;
end

function f=LOCAL_det(k,c)
  l=search_i9_physics('leads',k,'fine',c);[~,e]=search_i9_physics('match',k,'fine',c,l);
  [~,U,P]=lu(e.matching.Adef);z=diag(U);
  f=[sum(log(abs(z))),angle(det(P)*prod(z./abs(z)))];
end

function [r,f]=LOCAL_sample(N,M,beta,t,backend)
  timer=tic;c=LOCAL_config(N,M,beta);k=beta+t;
  if nargin>=5
    c.backend.fmm_eps=backend.fmm_eps;c.backend.direct=backend.direct;
  end
  l=search_i9_physics('leads',k,'fine',c);
  center=search_i9_physics('center-cell',k,'fine',c);
  g=l.channels.gamma_m(:);n=numel(g);idx=find(abs((-M:M))<=6);idx=[idx,idx+n];
  [lead,Dl]=LOCAL_cell(l.negative,g,idx);
  [mid,D0]=LOCAL_cell(center,g,idx);
  [~,Dr]=LOCAL_cell(l.positive,g,idx);
  % pairmat takes source first; target-source is (-0.4,-0.17).
  G0=1i/(2*c.model.d*g(M+1))*exp(-1i*beta*.17+1i*g(M+1)*.4);
  total=kernel.qpgreen_mfs_pairmat([.4;.17],[0;0],center.pars,center.proxy);
  r=struct('N',N,'M',M,'beta',beta,'t',t,'k',k,'gamma0',LOCAL_cx(g(M+1)), ...
    'lead',lead,'center',mid,'Green0',LOCAL_cx(G0),'Green_total',LOCAL_cx(total), ...
    'common_gap',l.common_gap,'seconds',toc(timer));
  f=struct('lead',l.negative,'right',l.positive,'center',center,'Dl',Dl,'Dr',Dr,'D0',D0,'g',g,'K',n);
end

function r=LOCAL_cauchyroot()
  beta=1.98154;[~,ref]=LOCAL_sample(192,12,beta,.005);anchor=LOCAL_anchors(ref);k=beta+.0001;history=[];
  for it=1:6
    f=value(k);fm=value(k-1e-5);fp=value(k+1e-5);
    step=2e-5/(exp(fp(1)-f(1)+1i*(fp(2)-f(2)))-exp(fm(1)-f(1)+1i*(fm(2)-f(2))));
    history(end+1,:)=[k,real(step),f(3)];
    if abs(real(step))<2e-13,break;end
    k=k-real(step);
  end
  z=value(k);r=struct('k',k,'beta',beta,'detuning',k-beta,'sigma_min',z(3),'history',history);
  function v=value(q)
    [~,a]=LOCAL_sample(192,12,beta,q-beta);[matrices,~]=LOCAL_matrices(a,anchor);H=matrices{3};
    [~,U,P]=lu(H);d=diag(U);s=svd(H);
    v=[sum(log(abs(d))),angle(det(P)*prod(d./abs(d))),s(end)];
  end
end

function [r,D]=LOCAL_cell(s,g,idx)
  n=numel(g);I=eye(2*n);G=diag([g;g]);
  S=[s.R_L,s.T_RL;s.T_LR,s.R_R];T=I+S;N=1i*G*(S-I);
  D=N/T;back=(1i*G-D)\(1i*G+D);
  sv=svd(s.raw.A_QP);j0=(n+1)/2;fields=[j0,j0; j0,j0+1; j0+1,j0; j0+1,j0+1; j0+1,j0+2];
  selected=[];selectedD=[];
  for j=1:size(fields,1)
    a=fields(j,1);b=fields(j,2);
    selected(end+1)=s.R_L(a,b);selected(end+1)=s.T_LR(a,b);
    selectedD(end+1)=D(a,b);selectedD(end+1)=D(a,n+b);
  end
  r=struct('rcond',rcond(s.raw.A_QP),'singular_ratio',sv(end)/sv(1),'A_norm',sv(1),'A_sigma_min',sv(end), ...
    'trace_rcond',rcond(T),'S_norm',norm(S,2),'D_norm',norm(D,2), ...
    'roundtrip_relative',norm(S-back,'fro')/norm(S,'fro'), ...
    'D_hermitian_relative',norm(D-D','fro')/norm(D,'fro'), ...
    'selected_S',LOCAL_cx(selected),'selected_D',LOCAL_cx(selectedD), ...
    'S_common',LOCAL_cx(S(idx,idx)),'D_common',LOCAL_cx(D(idx,idx)), ...
    'proxy_norm',norm(s.proxy.q),'extract_norm',norm([s.raw.F_L;s.raw.F_R],2));
end

function r=LOCAL_compare(a,b)
  r=struct;
  for name={'lead','center'}
    key=name{1};sa=a.(key);sb=b.(key);
    na=size(sa.R_L,1);nb=size(sb.R_L,1);ma=(na-1)/2;mb=(nb-1)/2;
    ia=find(abs(-ma:ma)<=6);ia=[ia,ia+na];ib=find(abs(-mb:mb)<=6);ib=[ib,ib+nb];
    A=[sa.R_L,sa.T_RL;sa.T_LR,sa.R_R];B=[sb.R_L,sb.T_RL;sb.T_LR,sb.R_R];
    if strcmp(key,'lead'),DA=a.Dl;DB=b.Dl;else,DA=a.D0;DB=b.D0;end
    AA=A(ia,ia);BB=B(ib,ib);DDa=DA(ia,ia);DDb=DB(ib,ib);
    r.(key)=struct('S_absolute',norm(AA-BB,2),'S_relative',norm(AA-BB,2)/norm(BB,2), ...
      'D_absolute',norm(DDa-DDb,2),'D_relative',norm(DDa-DDb,2)/norm(DDb,2));
  end
end

function anchors=LOCAL_anchors(f)
  anchors=struct('amplitude',struct('L',f.lead.Z,'R',f.right.Z), ...
    'cauchy',struct('L',LOCAL_space(f.Dl,true),'R',LOCAL_space(f.Dr,false)));
end

function [all,quality]=LOCAL_matrices(f,anchors)
  n=f.K;I=eye(n);O=zeros(n);a=f.center.raw;weight=sqrt(repmat(a.far_aux.weights(:),2,1));nd=numel(weight);
  b=struct('K',n,'n',nd,'J',[a.A_QP,weight.*[a.B_L,a.B_R]], ...
    'YL',[zeros(n,nd),I,O;a.F_L./weight.',O,a.E], ...
    'YR',[a.F_R./weight.',a.E,O;zeros(n,nd),O,I], ...
    'ZL',f.lead.Z,'ZR',f.right.Z);
  [original,quality]=border_matrix(b,anchors.amplitude);
  assert(~isempty(original),'wood:AmplitudeChart','Amplitude chart failed');
  zl=f.lead.Z/(anchors.amplitude.L'*f.lead.Z);zr=f.right.Z/(anchors.amplitude.R'*f.right.Z);
  s=f.center;YL=[I,O;s.R_L,s.T_RL];YR=[s.T_LR,s.R_R;O,I];
  condensed=[YL,-zl,zeros(2*n,n);YR,zeros(2*n,n),-zr];
  cl=LOCAL_space(f.Dl,true);cr=LOCAL_space(f.Dr,false);
  ol=anchors.cauchy.L'*cl;orr=anchors.cauchy.R'*cr;
  quality=[quality,min(svd(ol)),min(svd(orr)),cond(ol),cond(orr)];
  cl=cl/ol;cr=cr/orr;
  D=f.D0;YL=[I,O;-D(1:n,:)];YR=[O,I;D(n+1:end,:)];
  cauchy=[YL,-cl,zeros(2*n,n);YR,zeros(2*n,n),-cr];
  all={original,condensed,cauchy};
end

function Z=LOCAL_space(D,reverse)
  n=size(D,1)/2;I=eye(n);O=zeros(n);
  A=[-D(1:n,1:n),-I;D(n+1:end,1:n),O];
  B=[D(1:n,n+1:end),O;-D(n+1:end,n+1:end),I];
  if reverse,[A,B]=deal(B,A);end
  scale=hypot(norm(A,'fro'),norm(B,'fro'));
  [S,T,Q,Z]=qz(A/scale,B/scale,'complex');mask=abs(diag(S))<abs(diag(T));
  assert(sum(mask)==n,'wood:CauchyCount','Cauchy pencil stable count differs from K');
  [~,~,~,Z]=ordqz(S,T,Q,Z,mask);Z=Z(:,1:n);
end

function v=LOCAL_cx(A)
  v=struct('real',real(A),'imag',imag(A));
end

function LOCAL_part(out,label)
  f=fopen(fullfile(out,'part.txt'),'w');fprintf(f,'%s',label);fclose(f);
end

function LOCAL_save(out,label,value)
  f=fopen(fullfile(out,[label,'.json']),'w');fwrite(f,jsonencode(value));fclose(f);
end
