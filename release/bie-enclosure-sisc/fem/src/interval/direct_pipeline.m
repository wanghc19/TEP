function varargout=direct_pipeline(action,varargin)
% Source: test/fem-goerisch/pipeline-v1/internal/direct_pipeline.m. Copied numerical algorithm.
  % Direct-only Goerisch pipeline. RT means Raviart-Thomas; D direct trial.
  % Input
  %   action: config, prepare, solve, evaluate, verify, audit, or cache_check.
  %   config(input_dir,kind,example); prepare(cfg); solve(prepared,cfg,degree);
  %   evaluate/verify/audit(prepared,solution,cfg); cache_check(prepared,cfg).
  % Output
  %   Prepared data and flux remain in memory. Reports contain only scalars.
  %   All formulas/helpers copied from goerisch-v1/goerisch_flux_study.m.
  switch action
    case 'transport_float',varargout{1}=LOCAL_transport_float(varargin{:});
    case 'inventory',varargout{1}=LOCAL_inventory(varargin{:});
    case 'exact_flux',[varargout{1:nargout}]=LOCAL_exact_flux(varargin{:});
    case 'certificates',varargout{1}=LOCAL_certificates(varargin{:});
    case 'config',varargout{1}=LOCAL_config(varargin{:});
    case 'prepare',varargout{1}=LOCAL_prepare(varargin{:});
    case 'solve',varargout{1}=LOCAL_solve(varargin{:});
    case 'evaluate',varargout{1}=LOCAL_evaluate(varargin{:});
    case 'verify',varargout{1}=LOCAL_verify(varargin{:});
    case 'audit',varargout{1}=LOCAL_component_audit(varargin{:});
    case 'cache_check',varargout{1}=LOCAL_cache_check(varargin{:});
    case 'evaluator_check',varargout{1}=LOCAL_evaluator_check(varargin{:});
    otherwise,error('pipeline:Action','Unknown stage.');
  end
end
function cfg=LOCAL_config(input_dir,kind,e)
  % Input: in-memory label, direct trial kind, example. Output: numerical configuration.
  assert(strcmp(kind,'D'),'direct:Trial','Only the direct trial is supported.');
  cfg=struct('input_dir',char(input_dir),'trial',kind,'level','native-P3', ...
    'K',e.model.taper.lead_cells,'gamma',e.model.gamma,'beta',e.model.beta, ...
    'orders',e.discretization.orders,'band_orders',e.discretization.band_orders, ...
    'block',e.discretization.block,'alpha_minus',e.windows.alpha_minus, ...
    'alpha_plus',e.windows.alpha_plus,'quadrature_fraction',e.tolerances.quadrature_fraction, ...
    'geometry','analytic_blend_r3_v1','threads',e.resources.threads,'basis','stable', ...
    'compact_condensation',true,'fem_degree',e.discretization.trial_degree, ...
    'flux_degree',e.discretization.flux_degree,'model',e.model,'tolerances',e.tolerances);
  cfg.mu=cfg.alpha_minus+cfg.gamma;cfg.nu=cfg.alpha_plus+cfg.gamma;
end

function LOCAL_key(P,cfg)
  % LOCAL_key Key.
  % Input
  %   P,cfg.
  % Output
  %   No returned value; performs the stated check or output operation..
  assert(isequaln(P.key,cfg),'pipeline:CacheKey','Prepared geometry/phase/source/level/quadrature/trial key mismatch.');
end
function P=LOCAL_prepare(cfg,native)
  % LOCAL_prepare Prepare.
  % Input
  %   cfg,native.
  % Output
  %   P.
  started=tic;maxNumCompThreads(cfg.threads);P=struct('key',cfg,'trial',[],'norms',struct(),'tail_allowance',0);
  tt=tic;inventory=struct('name','native');
  assert(nargin==2,'pipeline:Input','Native field must be supplied in memory.');
  tm=struct('native_input',toc(tt),'source_input',0,'coefficient_build',0,'source_assembly_other',0, ...
    'normalization',0,'geometry',0,'primary_field',0,'prepare_other',0);
  P.input_inventory=struct('native_variables',{{inventory.name}},'loaded_native_variable','native','native_fields',{fieldnames(native)});
    P.mass=0;P.energy=0;P.tail_relative_upper=0;P.native_trace=LOCAL_native_trace(native,cfg);
  names={'left','center','right'};P.templates=cell(1,3);P.counts=struct('primary_evaluated_batches',0,'primary_values',0);
  for t=1:3
    tt=tic;T=native.templates.(names{t});T.xy(:,1)=T.xy(:,1)-T.cell;
    cells=-cfg.K:-1;if t==2,cells=0;elseif t==3,cells=1:cfg.K;end
    nd=size(T.xy,1);if isfield(T,'field_degree'),nd=size(T.dof_xy,1);end
    U=complex(zeros(nd,numel(cells)));
    for j=1:numel(cells),U(:,j)=native.cells([native.cells.index]==cells(j)).coef;end
    if isfield(T,'field_degree')
      G=LOCAL_geometry(T,zeros(size(T.xy,1),numel(cells)),cells,cfg,3);
      G=LOCAL_field_coefficients(G,T,U);
    else,G=LOCAL_geometry(T,U,cells,cfg,3);end
    G.fitted=goerisch_fitted_geometry(T);area=G.fitted.areas(16);
    tm.geometry=tm.geometry+toc(tt);
    if strcmp(cfg.trial,'D')
      tt=tic;ns=LOCAL_direct_norms(G,T,cfg,cfg.orders(1),cfg.band_orders(1));P.mass=P.mass+sum(ns.mass);P.energy=P.energy+sum(ns.energy);tm.normalization=tm.normalization+toc(tt);
    end
    cc=cfg;cc.degree=cfg.flux_degree;[~,~,sc,cache]=LOCAL_batches(G,T,P.trial,cc,[],cfg.orders(1),[],{},'prepare');
    tm.primary_field=tm.primary_field+sc.field_seconds;tm.geometry=tm.geometry+sc.other_seconds;
    P.templates{t}=struct('G',G,'T',T,'U',U,'cache',{cache},'area',area);
    P.counts.primary_evaluated_batches=P.counts.primary_evaluated_batches+sc.evaluated_batches;
    P.counts.primary_values=P.counts.primary_values+sc.value_count;
    fprintf('PREPARE %s: %d field batches, %.2fs\n',names{t},sc.evaluated_batches,toc(started));
  end
  P.q=cfg.gamma+P.energy/P.mass;P.seconds=toc(started);tm.prepare_other=P.seconds-sum(cell2mat(struct2cell(tm)));P.timing=tm;
end
function S=LOCAL_solve(P,cfg,degree)
  % LOCAL_solve Solve.
  % Input
  %   P,cfg,degree.
  % Output
  %   S.
  LOCAL_key(P,cfg);assert(ismember(degree,1:4));started=tic;cc=cfg;cc.degree=degree;
  tt=tic;[B,~,basis]=LOCAL_study_basis(degree,'stable');tm=struct('basis',toc(tt),'assembly',0,'solve',0,'other',0);
  packs=cell(1,3);hits=0;
  for t=1:3
    T=P.templates{t}.T;G=P.templates{t}.G;
    if degree~=3
      old=G;G=LOCAL_geometry(T,zeros(size(T.xy,1),numel(G.cells)),G.cells,cfg,degree);G.fitted=old.fitted;
      if isfield(old,'field_degree'),G.field_degree=old.field_degree;G.field_coefficients=old.field_coefficients;G.field_values=old.field_values;G.field_alpha=old.field_alpha;else,G.mu=old.mu;end
    end
    tt=tic;[H,b,sc]=LOCAL_batches(G,T,P.trial,cc,B,cfg.orders(1),[],P.templates{t}.cache,'assemble');tm.assembly=tm.assembly+toc(tt);hits=hits+sc.cache_hits;
    tt=tic;pack=LOCAL_condense(H,b,G,true);tm.solve=tm.solve+toc(tt);
    pack.H=H;pack.b=b;pack.G=G;packs{t}=pack;clear H b pack
  end
  tt=tic;nwall=numel(packs{1}.G.left);nc=2*cfg.K+1;AG=sparse((nc+1)*nwall,(nc+1)*nwall);rhs=complex(zeros(size(AG,1),1));
  for c=-cfg.K:cfg.K
    t=1+(c==0)+2*(c>0);pack=packs{t};j=find(pack.G.cells==c);ports=(c+cfg.K)*nwall+(1:2*nwall);
    AG(ports,ports)=AG(ports,ports)+pack.S;rhs(ports)=rhs(ports)+pack.port_rhs(:,j);
  end
  free=nwall+(1:(nc-1)*nwall);z=complex(zeros(size(rhs)));Af=(AG(free,free)+AG(free,free)')/2;z(free)=Af\rhs(free);
  residual=norm(Af*z(free)-rhs(free))/norm(rhs(free));clear AG Af rhs
  S=struct('key',cfg,'degree',degree,'basis',basis,'B',B,'flux',{cell(1,3)},'G',{cell(1,3)},'gram_quadratic',0,'trace_error',0,'global_residual',residual,'cache_hits',hits,'master_edges',{cell(1,3)},'master_wall',z);
  S.cell_residual=zeros(1,3);S.outer_normal_moment=max(abs(z([1:nwall,end-nwall+1:end])));
  S.unknowns=struct('degree',degree,'global_wall_free',numel(free),'template_edges',cellfun(@(x)x.G.nedge,packs),'template_interiors',cellfun(@(x)x.G.ni*x.G.nt,packs));
  for t=1:3
    pack=packs{t};G=pack.G;nt=G.nt;ncell=numel(G.cells);ye=complex(zeros(G.nedge,ncell));[factor,Aip]=LOCAL_refactor(pack.H,G,pack.Y);
    for j=1:ncell
      ports=(G.cells(j)+cfg.K)*nwall+(1:2*nwall);ye(G.port,j)=z(ports);ye(G.inner,j)=pack.response(:,j)-factor\(Aip*z(ports));
    end
    S.master_edges{t}=ye;
    clear factor Aip
    local=complex(zeros(G.nd,ncell,nt));
    for j=1:ncell
      ee=G.phase.*reshape(ye(G.map(:),j),nt,G.ne);
      ii=-reshape(pagemtimes(pack.Y,reshape(ee.',G.ne,1,nt)),G.ni,nt)-reshape(pack.r(:,j,:),G.ni,nt);
      local(:,j,:)=reshape([ee,reshape(ii,G.ni,nt).'].',G.nd,1,nt);
    end
    S.gram_quadratic=S.gram_quadratic+LOCAL_quadratic(pack.H,pack.b,local);
    S.trace_error=max(S.trace_error,LOCAL_trace(G,local,degree,B));S.flux{t}=local;S.G{t}=G;S.cell_residual(t)=pack.solve_residual;
    packs{t}=[];clear local pack ye
  end
  tm.solve=tm.solve+toc(tt);S.seconds=toc(started);tm.other=S.seconds-sum(cell2mat(struct2cell(tm)));S.timing=tm;
end
function result=LOCAL_evaluate(P,S,cfg)
  % LOCAL_evaluate Evaluate.
  % Input
  %   P,S,cfg.
  % Output
  %   result.
  LOCAL_key(P,cfg);LOCAL_key(S,cfg);started=tic;cc=cfg;cc.degree=S.degree;cc.square_q=P.q;quadratic=0;hits=0;
  squares=zeros(1,2);components=zeros(1,3);gradient_seconds=0;
  for t=1:3
    [~,~,sc]=LOCAL_batches(S.G{t},P.templates{t}.T,P.trial,cc,S.B,cfg.orders(1),S.flux{t},P.templates{t}.cache,'evaluate');
    quadratic=quadratic+sc.point_quadratic;hits=hits+sc.cache_hits;
    squares=squares+sc.square_components;components=components+sc.functional_components;gradient_seconds=gradient_seconds+sc.gradient_seconds;
  end
  J=(P.mass+quadratic+P.tail_allowance)/P.mass;Jgram=(P.mass+S.gram_quadratic+P.tail_allowance)/P.mass;
  result=LOCAL_interval(P.q,J,cfg);result.J_gram=Jgram;result.mass=P.mass;result.energy=P.energy;
  result.gram_scaled=P.q*abs(Jgram-J)/(P.q*J-1);result.cache_hits=hits;
  result.qJ_square=P.q*(sum(squares)+P.tail_allowance)/P.mass;
  result.square_components=P.q*squares/P.mass;result.square_tail=P.q*P.tail_allowance/P.mass;
  result.square_relative_difference=abs(result.qJ_square-result.qJ_minus_one)/result.qJ_minus_one;
  result.functional_components=components/P.mass;result.gram_absolute_difference=abs(Jgram-J);
  result.gradient_seconds=gradient_seconds;
  result.square_interval=LOCAL_square_interval(P.q,result.qJ_square,cfg);
  result.pass=result.algebra_pass&&result.square_relative_difference<.01&&result.qJ_square>0 ...
    &&abs(result.square_interval.width_formula_difference)<=1e-13 ...
    &&S.trace_error<1e-7&&S.global_residual<1e-9&&max(S.cell_residual)<1e-8&&S.outer_normal_moment==0;
  result.outer_normal_moment=S.outer_normal_moment;result.flux_unknowns=S.unknowns;
  result.normal_trace_error=S.trace_error;result.global_solve_residual=S.global_residual;result.cell_solve_residual=S.cell_residual;
  result.seconds=toc(started);
end
function r=LOCAL_square_interval(q,variance,cfg)
  % LOCAL_square_interval Square interval.
  % Input
  %   q,variance,cfg.
  % Output
  %   r.
  % Stable endpoint shifts use the nonnegative-square value of qJ-1.
  lo=q-cfg.gamma+q*cfg.nu*variance/(q-cfg.nu-cfg.nu*variance);
  hi=q-cfg.gamma+q*cfg.mu*variance/(q-cfg.mu-cfg.mu*variance);
  width=(cfg.nu-cfg.mu)*variance*q^2/((q-cfg.mu-cfg.mu*variance)*(cfg.nu+cfg.nu*variance-q));
  r=struct('enclosure',[lo,hi],'width',width,'width_endpoints',hi-lo,'width_formula_difference',hi-lo-width);
end
function r=LOCAL_interval(q,J,cfg)
  % LOCAL_interval Interval.
  % Input
  %   q,J,cfg.
  % Output
  %   r.
  variance=q*J-1;b2=[q-2*cfg.mu+cfg.mu^2*J,q-2*cfg.nu+cfg.nu^2*J];
  kappa=[(1-cfg.mu*J)/b2(1),(1-cfg.nu*J)/b2(2)];
  lower=(q-cfg.nu)/(1-cfg.nu*J)-cfg.gamma;upper=(q-cfg.mu)/(1-cfg.mu*J)-cfg.gamma;
  width=(cfg.nu-cfg.mu)*variance/((1-cfg.mu*J)*(cfg.nu*J-1));
  r=struct('q',q,'J',J,'qJ_minus_one',variance,'gram_denominators',b2,'kappa',kappa, ...
    'enclosure',[lower,upper],'width',width,'width_endpoints',upper-lower,'width_formula_difference',upper-lower-width, ...
    'sign_conditions',all(b2>0)&&kappa(1)>1/(cfg.nu-cfg.mu)&&kappa(2)<-1/(cfg.nu-cfg.mu));
  r.algebra_pass=variance>0&&r.sign_conditions&&abs(r.width_formula_difference)<=1e-13;
end
function r=LOCAL_verify(P,S,cfg)
  % LOCAL_verify Verify.
  % Input
  %   P,S,cfg.
  % Output
  %   r.
  LOCAL_key(P,cfg);LOCAL_key(S,cfg);started=tic;cc=cfg;cc.degree=S.degree;cc.square_q=P.q;
  squares=zeros(1,2);gradient_seconds=0;
  tm=struct('field24',0,'functional24',0,'normalization',0,'areas',0,'other',0);quadratic=0;mass=0;energy=0;batches=0;values=0;areas=struct([]);
  for t=1:3
    G=S.G{t};T=P.templates{t}.T;
    [~,~,sc]=LOCAL_batches(G,T,P.trial,cc,S.B,cfg.orders(2),S.flux{t},{},'evaluate');
    quadratic=quadratic+sc.point_quadratic;tm.field24=tm.field24+sc.field_seconds;tm.functional24=tm.functional24+sc.other_seconds;
    squares=squares+sc.square_components;gradient_seconds=gradient_seconds+sc.gradient_seconds;
    batches=batches+sc.evaluated_batches;values=values+sc.value_count;
    tt=tic;area=G.fitted.areas(24);areas=[areas,area];tm.areas=tm.areas+toc(tt); %#ok<AGROW>
    if strcmp(cfg.trial,'D'),tt=tic;ns=LOCAL_direct_norms(G,T,cfg,cfg.orders(2),cfg.band_orders(2));mass=mass+sum(ns.mass);energy=energy+sum(ns.energy);tm.normalization=tm.normalization+toc(tt);end
  end
  normcheck=struct('pass',true);
  J=(mass+quadratic+P.tail_allowance)/mass;
  r=struct('J24',J,'q24',cfg.gamma+energy/mass,'mass24',mass,'energy24',energy,'areas',areas,'normalization',normcheck, ...
    'evaluated_batches',batches,'evaluated_values',values,'seconds',toc(started));
  r.qJ_square24=P.q*(sum(squares)+P.tail_allowance)/P.mass;
  r.square_components24=P.q*squares/P.mass;r.gradient_seconds=gradient_seconds;
  tm.other=r.seconds-sum(cell2mat(struct2cell(tm)));r.timing=tm;
end
function r=LOCAL_component_audit(P,S,cfg)
  % LOCAL_component_audit Component audit.
  % Input
  %   P,S,cfg.
  % Output
  %   r.
  LOCAL_key(P,cfg);LOCAL_key(S,cfg);started=tic;cc=cfg;cc.degree=S.degree;items=cell(1,3);hits=0;
  for t=1:3
    [~,~,sc]=LOCAL_batches(S.G{t},P.templates{t}.T,P.trial,cc,S.B,cfg.orders(1),S.flux{t},P.templates{t}.cache,'audit');
    items{t}=struct('point',sc.point_components,'gram',sc.gram_components,'difference',sc.gram_components-sc.point_components);hits=hits+sc.cache_hits;
  end
  r=struct('components',{items},'cache_hits',hits,'seconds',toc(started));
end
function r=LOCAL_cache_check(P,cfg)
  % LOCAL_cache_check Cache check.
  % Input
  %   P,cfg.
  % Output
  %   r.
  LOCAL_key(P,cfg);T=P.templates{1};rule=T.G.fitted.rules(16);rule=rule{1};ids=rule.ids(1:min(cfg.block,numel(rule.ids)));nq=numel(rule.w);
  ei=repelem(ids(:),nq);x=repmat(rule.x,numel(ids),1);y=repmat(rule.y,numel(ids),1);keep=1:min(32,numel(x));
  [PX,PY]=T.G.fitted.map(ei(keep),x(keep),y(keep));fresh=LOCAL_field(T.G,P.trial,cfg,ei(keep),PX,PY);
  old=T.cache{1}(keep,:);relative=norm(fresh-old,'fro')/norm(old,'fro');
  variants={cfg,cfg,cfg,cfg,cfg,cfg};variants{1}.beta=.6;variants{2}.orders=[18,24];variants{3}.trial='invalid';
  variants{4}.geometry='invalid';variants{5}.level='main';variants{6}.input_dir=[cfg.input_dir,'/changed'];rejected=false(1,numel(variants));
  for j=1:numel(variants)
    try,LOCAL_key(P,variants{j});catch err,rejected(j)=strcmp(err.identifier,'pipeline:CacheKey');end
  end
  r=struct('fresh_points',numel(keep),'fresh_values',numel(fresh),'relative_difference',relative,'mismatch_rejected',rejected,'pass',relative<=1e-12&&all(rejected));
end
function [values,gx,gy]=LOCAL_field(G,trial,cfg,ei,PX,PY)
  % LOCAL_field Field.
  % Input
  %   G,trial,cfg,ei,PX,PY.
  % Output
  %   [values,gx,gy].
  [e,x,y,J,det]=G.fitted.inverse_native(ei,PX,PY);
  if nargout==1,values=LOCAL_direct(G,e,x,y,PX,J,det,cfg);
  else,[values,gx,gy]=LOCAL_direct(G,e,x,y,PX,J,det,cfg);end
end
function [H,b,sc,cache]=LOCAL_batches(G,T,trial,cfg,B,order,flux,cache,action)
  % LOCAL_batches Batches.
  % Input
  %   G,T,trial,cfg,B,order,flux,cache,action.
  % Output
  %   [H,b,sc,cache].
  started=tic;field_seconds=0;nd=G.nd;nt=G.nt;nc=numel(G.cells);rules=G.fitted.rules(order);
  assemble=ismember(action,{'assemble','audit'});evaluate=ismember(action,{'evaluate','audit'});prepare=strcmp(action,'prepare');
  if assemble,H=zeros(nd,nd,nt);b=complex(zeros(nd,nc,nt));else,H=[];b=[];end
  reuse=~isempty(cache);ci=0;hits=0;misses=0;count=0;point_quadratic=0;point=zeros(2,3);gram=point;
  squares=zeros(1,2);components=zeros(1,3);gradient_seconds=0;
  for ri=1:numel(rules)
    rule=rules{ri};x=rule.x;y=rule.y;w=rule.w;nq=numel(w);
    if ~prepare,[vx,vy,dv]=LOCAL_rt(x,y,cfg.degree);vx=vx*B;vy=vy*B;dv=dv*B;end
    for first=1:cfg.block:numel(rule.ids)
      ci=ci+1;ids=rule.ids(first:min(first+cfg.block-1,numel(rule.ids)));nb=numel(ids);
      xx=repmat(x,nb,1);yy=repmat(y,nb,1);ei=repelem(ids(:),nq);[PX,PY,J,det]=G.fitted.map(ei,xx,yy);
      if reuse,values=cache{ci};hits=hits+1;
      else,tt=tic;values=LOCAL_field(G,trial,cfg,ei,PX,PY);field_seconds=field_seconds+toc(tt);misses=misses+1;count=count+numel(values);end
      if prepare,cache{ci}=values;continue;end
      vxx=repmat(vx,nb,1);vyy=repmat(vy,nb,1);dvv=repmat(dv,nb,1);
      px=(J(:,1).*vxx+J(:,2).*vyy)./det;py=(J(:,3).*vxx+J(:,4).*vyy)./det;
      W=repmat(w,nb,1).*det;rho=repelem(reshape(T.material(ids),[],1),nq,1);D=dvv./det;
      P=permute(reshape(px,nq,nb,nd),[3,1,2]);Q=permute(reshape(py,nq,nb,nd),[3,1,2]);DD=permute(reshape(D,nq,nb,nd),[3,1,2]);ww=reshape(W,1,nq,nb);
      if assemble
        HM=pagemtimes(P.*ww,'none',P,'transpose')+pagemtimes(Q.*ww,'none',Q,'transpose');
        HD=pagemtimes(DD.*reshape(W./rho,1,nq,nb),'none',DD,'transpose');H(:,:,ids)=HM+HD;
        VV=permute(reshape(values,nq,nb,nc),[1,3,2]);bb=pagemtimes(DD.*ww,VV);b(:,:,ids)=bb;
      end
      if evaluate
        cc=flux(:,:,ids);fx=LOCAL_flux_values(P,cc);fy=LOCAL_flux_values(Q,cc);fd=LOCAL_flux_values(DD,cc);
        point_quadratic=point_quadratic+sum(W.*(abs(fx).^2+abs(fy).^2+abs(fd).^2./rho+2*real(conj(fd).*values)),'all');
        components=components+[sum(W.*(abs(fx).^2+abs(fy).^2),'all'),sum((W./rho).*abs(fd).^2,'all'),2*real(sum(W.*conj(fd).*values,'all'))];
        if isfield(cfg,'square_q')
          % Coefficients already represent the physical quasi-periodic field.
          % Therefore gx,gy and fd are physical gradient and divergence;
          % no additional i*beta term is applied. The direct taper has zero tail.
          tt=tic;[~,gx,gy]=LOCAL_field(G,trial,cfg,ei,PX,PY);gradient_seconds=gradient_seconds+toc(tt);
          qs=cfg.square_q;
          squares=squares+[sum(W.*(abs(fx-gx/qs).^2+abs(fy-gy/qs).^2),'all'), ...
            sum((W./rho).*abs(fd+rho.*((1-1/qs)*values)).^2,'all')];
        end
        if strcmp(action,'audit')
          group=1+any(ismember(ids,[T.interface.inner(:);T.interface.outer(:)]));
          pm=sum(W.*(abs(fx).^2+abs(fy).^2),'all');pd=sum((W./rho).*abs(fd).^2,'all');pl=2*real(sum(W.*conj(fd).*values,'all'));
          gm=real(sum(conj(cc).*pagemtimes(HM,cc),'all'));gd=real(sum(conj(cc).*pagemtimes(HD,cc),'all'));gl=2*real(sum(conj(cc).*bb,'all'));
          point(group,:)=point(group,:)+[pm,pd,pl];gram(group,:)=gram(group,:)+[gm,gd,gl];
        end
      end
    end
  end
  sc=struct('point_quadratic',point_quadratic,'point_components',point,'gram_components',gram,'field_seconds',field_seconds, ...
    'other_seconds',toc(started)-field_seconds,'cache_hits',hits,'evaluated_batches',misses,'value_count',count);
  sc.square_components=squares;sc.functional_components=components;sc.gradient_seconds=gradient_seconds;
end
function check=LOCAL_native_trace(native,cfg)
  % LOCAL_native_trace Native trace.
  % Input
  %   native,cfg.
  % Output
  %   check.
  names={'left','center','right'}; left=cell(1,2*cfg.K+1);right=left;
  jump=0;phase_jump=0;scale=0;
  for c=-cfg.K:cfg.K
    t=1+(c==0)+2*(c>0);T=native.templates.(names{t});
    xy=T.xy;if isfield(T,'field_degree'),xy=T.dof_xy;end;xy(:,1)=xy(:,1)-T.cell;
    u=native.cells([native.cells.index]==c).coef;scale=max(scale,max(abs(u)));
    l=find(abs(xy(:,1)+.5)<1e-11);r=find(abs(xy(:,1)-.5)<1e-11);
    [~,s]=sort(xy(l,2));l=l(s);[~,s]=sort(xy(r,2));r=r(s);
    left{c+cfg.K+1}=u(l);right{c+cfg.K+1}=u(r);
    b=find(abs(xy(:,2)+.5)<1e-11);a=find(abs(xy(:,2)-.5)<1e-11);
    [~,s]=sort(xy(b,1));b=b(s);[~,s]=sort(xy(a,1));a=a(s);
    phase_jump=max(phase_jump,max(abs(u(a)-exp(1i*cfg.beta)*u(b))));
  end
  for j=1:numel(left)-1,jump=max(jump,max(abs(right{j}-left{j+1})));end
  check=struct('cell_absolute',jump,'phase_absolute',phase_jump,'scale',scale, ...
    'cell_relative',jump/scale,'phase_relative',phase_jump/scale);
end

function G=LOCAL_geometry(T,U,cells,cfg,k)
  % LOCAL_geometry Geometry.
  % Input
  %   T,U,cells,cfg,k.
  % Output
  %   G.
  tr=T.tri6(:,1:3); nt=size(tr,1); xy=T.xy;
  [edges,~,ids]=unique(sort([tr(:,[1,2]);tr(:,[2,3]);tr(:,[3,1])],2),'rows');
  ids=reshape(ids,nt,3); starts=[tr(:,1);tr(:,2);tr(:,3)]; ends=[tr(:,2);tr(:,3);tr(:,1)];
  pa=xy(starts,:);pb=xy(ends,:);signs=ones(size(starts));
  signs(pa(:,1)>pb(:,1)|(pa(:,1)==pb(:,1)&pa(:,2)>pb(:,2)))=-1;
  signs=reshape(signs,nt,3); mid=(xy(edges(:,1),:)+xy(edges(:,2),:))/2;
  top=find(abs(mid(:,2)-.5)<1e-11);bot=find(abs(mid(:,2)+.5)<1e-11);
  [~,a]=sort(mid(top,1));top=top(a);[~,a]=sort(mid(bot,1));bot=bot(a);
  assert(numel(top)==numel(bot)&&max(abs(mid(top,1)-mid(bot,1)))<1e-11);
  master=(1:size(edges,1))';master(top)=bot;ph=ones(size(master));ph(top)=exp(1i*cfg.beta);
  active=true(size(master));active(top)=false;pos=zeros(size(master));pos(active)=1:nnz(active);
  nr=k+1; ne=3*nr;nd=(k+1)*(k+3);ni=nd-ne;
  map=zeros(nt,ne);phase=complex(zeros(nt,ne));
  for e=1:3
    for m=0:k
      l=(e-1)*nr+m+1;map(:,l)=nr*(pos(master(ids(:,e)))-1)+m+1;
      phase(:,l)=signs(:,e).^(m+1).*ph(ids(:,e));
    end
  end
  left=find(abs(mid(:,1)+.5)<1e-11);right=find(abs(mid(:,1)-.5)<1e-11);
  [~,a]=sort(mid(left,2));left=left(a);[~,a]=sort(mid(right,2));right=right(a);
  assert(numel(left)==numel(right)&&max(abs(mid(left,2)-mid(right,2)))<1e-11);
  left=reshape((nr*(pos(left)-1)+(1:nr)).',[],1);right=reshape((nr*(pos(right)-1)+(1:nr)).',[],1);
  nedge=nnz(active)*nr;port=[left;right];inner=setdiff((1:nedge)',port);
  nodes=reshape(xy(T.tri6(:),:),nt,6,2);mx=LOCAL_poly(nodes(:,:,1));my=LOCAL_poly(nodes(:,:,2));
  mu=complex(zeros(nt,6,numel(cells)));
  for j=1:numel(cells),mu(:,:,j)=LOCAL_poly(reshape(U(T.tri6,j),nt,6));end
  G=struct('nt',nt,'nd',nd,'ne',ne,'ni',ni,'mx',mx,'my',my,'mu',mu,'cells',cells, ...
    'map',map,'phase',phase,'nedge',nedge,'left',left,'right',right,'port',port,'inner',inner, ...
    'edge_ids',ids,'signs',signs,'mid',mid,'top',top,'bot',bot,'edges',edges, ...
    'taper',cfg.model.taper,'background',cfg.model.rho_background,'tolerances',cfg.tolerances);
end

function audit=LOCAL_audit(H,b,HC,bc,c,low,high,G,T)
  % LOCAL_audit Audit.
  % Input
  %   H,b,HC,bc,c,low,high,G,T.
  % Output
  %   audit.
  curved=false(G.nt,1);curved([T.interface.inner(:);T.interface.outer(:)])=true;
  change=struct([]);
  for j=1:2
    ids=find(curved==(j==2));h=H(:,:,ids);hc=HC(:,:,ids);bb=b(:,:,ids);cc=c(:,:,ids);
    dh=hc-h;db=bc(:,:,ids)-bb;
    change=[change,struct('matrix_relative_frobenius',norm(dh(:))/norm(h(:)), ...
      'load_relative_frobenius',norm(db(:))/norm(bb(:)), ...
      'matrix_quadratic_change',real(sum(conj(cc).*pagemtimes(dh,cc),'all')), ...
      'load_functional_change',2*real(sum(conj(cc).*db,'all')))]; %#ok<AGROW>
  end
  residual=pagemtimes(H,c)+b;ii=G.ne+1:G.nd;
  interior=residual(ii,:,:);rhs=b(ii,:,:);
  audit=struct('row_labels',{{'unchanged_elements','curved_elements'}}, ...
    'column_labels',{{'flux_mass','div_div','twice_load'}}, ...
    'low_point',low.point_components,'low_gram',low.gram_components, ...
    'high_point',high.point_components,'high_gram',high.gram_components, ...
    'gram_minus_point_low',low.gram_components-low.point_components, ...
    'gram_minus_point_high',high.gram_components-high.point_components, ...
    'orders_comparison',change,'local_gradient_low',sqrt(low.gradient_square), ...
    'local_gradient_high',sqrt(high.gradient_square), ...
    'interior_equation_relative_residual',norm(interior(:))/norm(rhs(:)));
end

function sc=LOCAL_direct_norms(G,T,cfg,order,band_order)
  % LOCAL_direct_norms Direct norms.
  % Input
  %   G,T,cfg,order,band_order.
  % Output
  %   sc.
  [x,y,w]=LOCAL_duffy(order);nq=numel(w);mass=zeros(1,numel(G.cells));energy=mass;
  for first=1:cfg.block:G.nt
    ids=first:min(first+cfg.block-1,G.nt);nb=numel(ids);ei=repelem(ids(:),nq);
    xx=repmat(x,nb,1);yy=repmat(y,nb,1);
    [PX,~,J,det]=LOCAL_map(G.mx(ei,:),G.my(ei,:),xx,yy);
    [v,gx,gy]=LOCAL_direct(G,ei,xx,yy,PX,J,det,cfg);W=repmat(w,nb,1).*det;
    rho=repelem(reshape(T.material(ids),[],1),nq,1);
    mass=mass+sum((W.*rho).*abs(v).^2,1);energy=energy+sum(W.*(abs(gx).^2+abs(gy).^2),1);
  end
  band=LOCAL_band(G,T,band_order);
  for first=1:1024:numel(band.w)
    ids=first:min(first+1023,numel(band.w));ei=band.e(ids);xx=band.x(ids);yy=band.y(ids);
    [PX,~,J,det]=LOCAL_map(G.mx(ei,:),G.my(ei,:),xx,yy);
    v=LOCAL_direct(G,ei,xx,yy,PX,J,det,cfg);
    mass=mass+sum((band.w(ids)*(T.rho_in-T.background)).*abs(v).^2,1);
  end
  sc=struct('mass',mass,'energy',energy);
end

function v=LOCAL_flux_values(P,c)
  % LOCAL_flux_values Flux values.
  % Input
  %   P,c.
  % Output
  %   v.
  V=pagemtimes(P,'transpose',c,'none');v=reshape(permute(V,[1,3,2]),[],size(c,2));
end
function v=LOCAL_point_flux(P,c,ei)
  % LOCAL_point_flux Point flux.
  % Input
  %   P,c,ei.
  % Output
  %   v.
  v=complex(zeros(numel(ei),size(c,2)));
  for j=1:size(c,2),v(:,j)=sum(P.*reshape(c(:,j,ei),size(c,1),[]).',2);end
end

function pack=LOCAL_condense(H,b,G,compact)
  % LOCAL_condense Condense.
  % Input
  %   H,b,G,compact.
  % Output
  %   pack.
  ne=G.ne; ni=G.ni; nt=G.nt; nc=numel(G.cells); ee=1:ne;ii=ne+(1:ni);
  Y=pagemldivide(H(ii,ii,:),H(ii,ee,:));r=pagemldivide(H(ii,ii,:),b(ii,:,:));
  S=H(ee,ee,:)-pagemtimes(H(ee,ii,:),Y);d=b(ee,:,:)-pagemtimes(H(ee,ii,:),r);
  ph=G.phase.';map=G.map.';
  V=conj(reshape(ph,ne,1,nt)).*S.*reshape(ph,1,ne,nt);
  I=repmat(reshape(map,ne,1,nt),1,ne,1);J=repmat(reshape(map,1,ne,nt),ne,1,1);
  A=sparse(I(:),J(:),V(:),G.nedge,G.nedge);A=(A+A')/2;
  rhs=complex(zeros(G.nedge,nc));
  for j=1:nc
    vals=-conj(ph).*reshape(d(:,j,:),ne,nt);
    rhs(:,j)=accumarray(map(:),vals(:),[G.nedge,1]);
  end
  ip=G.inner;pp=G.port;Aii=A(ip,ip);Api=A(pp,ip);Aip=A(ip,pp);
  dec=decomposition(Aii,'chol');response=dec\rhs(ip,:);
  if compact
    Sc=full(A(pp,pp));
    for first=1:24:numel(pp)
      cols=first:min(first+23,numel(pp));extension_block=dec\full(Aip(:,cols));
      Sc(:,cols)=Sc(:,cols)-Api*extension_block;
    end
    extension=[];
  else
    extension=dec\full(Aip);Sc=A(pp,pp)-Api*extension;
  end
  solve_residual=norm(Aii*response-rhs(ip,:),'fro')/norm(rhs(ip,:),'fro');
  Sc=(Sc+Sc')/2;
  rp=rhs(pp,:)-Api*response;
  pack=struct('Y',Y,'r',r,'S',Sc,'port_rhs',rp,'response',response,'extension',extension,'solve_residual',solve_residual);
  % The compact case refactors one template at recovery, avoiding three
  % retained factors and all dense cell-interior extension matrices.
end

function [factor,Aip]=LOCAL_refactor(H,G,Y)
  % LOCAL_refactor Refactor.
  % Input
  %   H,G,Y.
  % Output
  %   [factor,Aip].
  ne=G.ne;nt=G.nt;ee=1:ne;ii=ne+1:G.nd;
  S=H(ee,ee,:)-pagemtimes(H(ee,ii,:),Y);ph=G.phase.';map=G.map.';
  V=conj(reshape(ph,ne,1,nt)).*S.*reshape(ph,1,ne,nt);
  I=repmat(reshape(map,ne,1,nt),1,ne,1);J=repmat(reshape(map,1,ne,nt),ne,1,1);
  A=sparse(I(:),J(:),V(:),G.nedge,G.nedge);A=(A+A')/2;
  factor=decomposition(A(G.inner,G.inner),'chol');Aip=A(G.inner,G.port);
end

function value=LOCAL_quadratic(H,b,c)
  % LOCAL_quadratic Quadratic.
  % Input
  %   H,b,c.
  % Output
  %   value.
  Hc=pagemtimes(H,c);
  value=real(sum(conj(c).*(Hc+2*b),'all'));
end

function [values,gx,gy]=LOCAL_direct(G,e,x,y,PX,J,det,cfg)
  % LOCAL_direct Direct.
  % Input
  %   G,e,x,y,PX,J,det,cfg.
  % Output
  %   [values,gx,gy].
  if isfield(G,'field_degree')
    if nargout==1,values=LOCAL_direct_high(G,e,x,y,PX,J,det,cfg);else,[values,gx,gy]=LOCAL_direct_high(G,e,x,y,PX,J,det,cfg);end;return
  end
  n=numel(x);nc=numel(G.cells);values=complex(zeros(n,nc));if nargout>1,gx=values;gy=values;end
  B=[ones(n,1),x,y,x.^2,x.*y,y.^2];
  for j=1:nc
    c=G.mu(e,:,j);u=sum(B.*c,2);
    if nargout>1
      ux=c(:,2)+2*c(:,4).*x+c(:,5).*y;uy=c(:,3)+c(:,5).*x+2*c(:,6).*y;
      dx=(J(:,4).*ux-J(:,3).*uy)./det;dy=(-J(:,2).*ux+J(:,1).*uy)./det;
    end
    X=PX+G.cells(j);t=max(0,min(1,(abs(X)-cfg.model.taper.start)/cfg.model.taper.width));
    chi=(1+cos(pi*t))/2;dchi=-(pi/(2*cfg.model.taper.width))*sin(pi*t).*sign(X);
    values(:,j)=chi.*u;
    if nargout>1,gx(:,j)=chi.*dx+dchi.*u;gy(:,j)=chi.*dy;end
  end
end

function band=LOCAL_band(G,T,n)
  % LOCAL_band Band.
  % Input
  %   G,T,n.
  % Output
  %   band.
  % Oriented strip formula copied in algebra from refine_i102 LOCAL_band_locate.
  [z,w]=LOCAL_gauss(n);[u,v]=ndgrid(z,z);[a,b]=ndgrid(w,w);u=u(:)';v=v(:)';wq=(a(:).*b(:))';
  th=T.interface.theta(:);dt=T.interface.dtheta;ng=numel(th);
  p0=LOCAL_curve(T,th);pm=LOCAL_curve(T,th+dt/2);p1=LOCAL_curve(T,th+dt);
  [truep,trued]=LOCAL_curve(T,reshape(th+dt*u,[],1));trued=dt*trued;
  sid=repmat((1:ng)',1,numel(u));sid=sid(:);uu=repmat(u,ng,1);uu=uu(:);vv=repmat(v,ng,1);vv=vv(:);
  base=p0(sid,:).*((1-uu).*(1-2*uu))+pm(sid,:).*(4*uu.*(1-uu))+p1(sid,:).*(uu.*(2*uu-1));
  db=p0(sid,:).*(4*uu-3)+pm(sid,:).*(4-8*uu)+p1(sid,:).*(4*uu-1);
  d=truep-base;pt=base+vv.*d;tangent=db+vv.*(trued-db);
  ww=repmat(wq,ng,1);ww=ww(:).*(d(:,1).*tangent(:,2)-d(:,2).*tangent(:,1));
  owner=[T.interface.inner(sid),T.interface.outer(sid)];
  best=-Inf(size(sid));elem=zeros(size(sid));xi=best;eta=best;
  for j=1:2
    e=owner(:,j);s=ones(numel(e),2)/3;
    for it=1:9
      [X,Y,J,det]=LOCAL_map(G.mx(e,:),G.my(e,:),s(:,1),s(:,2));
      rx=X-pt(:,1);ry=Y-pt(:,2);
      s=s-[(J(:,4).*rx-J(:,2).*ry)./det,(-J(:,3).*rx+J(:,1).*ry)./det];
    end
    bary=min([s,1-sum(s,2)],[],2);choose=bary>best;
    elem(choose)=e(choose);xi(choose)=s(choose,1);eta(choose)=s(choose,2);best(choose)=bary(choose);
  end
  assert(min(best)>-1e-7,'goerisch:Band','A true-material strip point has no adjacent owner.');
  band=struct('e',elem,'x',xi,'y',eta,'w',ww,'min_barycentric',min(best));
end

function [c,d]=LOCAL_curve(T,theta)
  % Input: template and angles. Output: curve position and derivative.
  [c,d]=physical_curve(T.curve,theta);
end

function [B,err,info]=LOCAL_study_basis(k,study)
  % LOCAL_study_basis Study basis.
  % Input
  %   k,study.
  % Output
  %   [B,err,info].
  if k<=3||strcmp(study,'audit')
    [old,err]=LOCAL_dual(k);B=old;old_norm=norm(old,'fro');
  else,old_norm=NaN;end
  info=struct('kind','moment_dual','moment_basis_coefficient_norm',old_norm);
  if strcmp(study,'audit'),return;end
  % Reference vector L2 orthogonalization followed by a minimum-norm
  % right inverse of the edge moments. Interior columns span their kernel.
  % Edge moments, the RT space and Piola mapping remain unchanged.
  nd=(k+1)*(k+3);ne=3*(k+1);[x,y,w]=LOCAL_duffy(k+5);[vx,vy]=LOCAL_rt(x,y,k);
  [~,R]=qr([sqrt(w).*vx;sqrt(w).*vy],0);C=R\eye(nd);
  [t,ww]=LOCAL_gauss(k+5);L=LOCAL_legendre(t,k);E=zeros(ne,nd);
  for e=1:3
    if e==1,x=t;y=0*t;n=[0,-1];elseif e==2,x=1-t;y=t;n=[1,1];else,x=0*t;y=1-t;n=[-1,0];end
    [vx,vy]=LOCAL_rt(x,y,k);E((e-1)*(k+1)+(1:k+1),:)=L'*(ww.*(n(1)*vx+n(2)*vy));
  end
  [U,S,V]=svd(E*C);Z=[V(:,1:ne)*(diag(1./diag(S(:,1:ne)))*U'),V(:,ne+1:end)];B=C*Z;
  err=norm(E*B-[eye(ne),zeros(ne,nd-ne)],'inf');assert(err<1e-8,'goerisch:Basis','Stable edge moments failed.');
  info.kind='reference_L2_orthogonal';info.stable_coefficient_norm=norm(B,'fro');
  info.edge_moment_error=err;info.reference_raw_condition=cond(R);info.edge_operator_condition=cond(E*C);
end

function [Dinv,err]=LOCAL_dual(k)
  % LOCAL_dual Dual.
  % Input
  %   k.
  % Output
  %   [Dinv,err].
  nd=(k+1)*(k+3);nr=k+1;D=zeros(nd);
  [t,w]=LOCAL_gauss(k+4);L=LOCAL_legendre(t,k);
  for e=1:3
    if e==1,x=t;y=0*t;n=[0,-1];elseif e==2,x=1-t;y=t;n=[1,1];else,x=0*t;y=1-t;n=[-1,0];end
    [vx,vy]=LOCAL_rt(x,y,k);D((e-1)*nr+(1:nr),:)=L'*(w.*(n(1)*vx+n(2)*vy));
  end
  [x,y,w]=LOCAL_duffy(k+4);[vx,vy]=LOCAL_rt(x,y,k);P=LOCAL_monomials(x,y,k-1);np=size(P,2);
  D(3*nr+(1:np),:)=P'*(w.*vx);D(3*nr+np+(1:np),:)=P'*(w.*vy);
  [a,b]=rat(D,1e-12);D=a./b;Dinv=D\eye(nd);err=norm(D*Dinv-eye(nd),'inf');
  assert(err<1e-8,'goerisch:Basis','Reference duality failed.');
end

function [vx,vy,dv]=LOCAL_rt(x,y,k)
  % LOCAL_rt Rt.
  % Input
  %   x,y,k.
  % Output
  %   [vx,vy,dv].
  x=x(:);y=y(:);[P,Px,Py]=LOCAL_monomials(x,y,k);z=zeros(size(P));H=zeros(numel(x),k+1);
  for j=0:k,H(:,j+1)=x.^(k-j).*y.^j;end
  vx=[P,z,x.*H];vy=[z,P,y.*H];dv=[Px,Py,(k+2)*H];
end
function [P,Px,Py]=LOCAL_monomials(x,y,k)
  % LOCAL_monomials Monomials.
  % Input
  %   x,y,k.
  % Output
  %   [P,Px,Py].
  x=x(:);y=y(:);n=(k+1)*(k+2)/2;P=zeros(numel(x),n);Px=P;Py=P;l=0;
  for d=0:k
    for j=0:d
      l=l+1;a=d-j;b=j;P(:,l)=x.^a.*y.^b;
      if a>0,Px(:,l)=a*x.^(a-1).*y.^b;end
      if b>0,Py(:,l)=b*x.^a.*y.^(b-1);end
    end
  end
end
function L=LOCAL_legendre(t,k)
  % LOCAL_legendre Legendre.
  % Input
  %   t,k.
  % Output
  %   L.
  z=2*t-1;L=ones(numel(t),k+1);if k>0,L(:,2)=z;end
  for j=2:k,L(:,j+1)=((2*j-1)*z.*L(:,j)-(j-1)*L(:,j-1))/j;end
end
function [X,Y,J,d]=LOCAL_map(mx,my,x,y)
  % LOCAL_map Map.
  % Input
  %   mx,my,x,y.
  % Output
  %   [X,Y,J,d].
  B=[ones(size(x)),x,y,x.^2,x.*y,y.^2];X=sum(B.*mx,2);Y=sum(B.*my,2);
  J=[mx(:,2)+2*mx(:,4).*x+mx(:,5).*y,mx(:,3)+mx(:,5).*x+2*mx(:,6).*y, ...
    my(:,2)+2*my(:,4).*x+my(:,5).*y,my(:,3)+my(:,5).*x+2*my(:,6).*y];
  d=J(:,1).*J(:,4)-J(:,2).*J(:,3);assert(all(d>0));
end
function c=LOCAL_poly(v)
  % LOCAL_poly Poly.
  % Input
  %   v.
  % Output
  %   c.
  % Verbatim coefficient convention of eq_temple_i95 LOCAL_poly.
  c=[v(:,1),-3*v(:,1)-v(:,2)+4*v(:,4),-3*v(:,1)-v(:,3)+4*v(:,6), ...
    2*v(:,1)+2*v(:,2)-4*v(:,4),4*v(:,1)-4*v(:,4)+4*v(:,5)-4*v(:,6), ...
    2*v(:,1)+2*v(:,3)-4*v(:,6)];
end
function err=LOCAL_trace(G,c,k,Dinv)
  % LOCAL_trace Trace.
  % Input
  %   G,c,k,Dinv.
  % Output
  %   err.
  % Moments already impose continuity; verify pointwise reference traces.
  [t,~]=LOCAL_gauss(k+3);L=LOCAL_legendre(t,k);nr=k+1;err=0;
  for e=1:3
    if e==1,x=t;y=0*t;n=[0,-1];elseif e==2,x=1-t;y=t;n=[1,1];else,x=0*t;y=1-t;n=[-1,0];end
    [vx,vy]=LOCAL_rt(x,y,k);B=(n(1)*vx+n(2)*vy)*Dinv;
    exact=zeros(size(B));exact(:,(e-1)*nr+(1:nr))=L.*(2*(0:k)+1);
    err=max(err,max(abs(B-exact),[],'all'));
  end
  % All reconstructed coefficients are finite; external moments are zero by the port solve.
  assert(all(isfinite(c),'all')&&err<1e-7,'goerisch:Trace','Normal-trace basis check failed.');
end
function [x,y,w]=LOCAL_duffy(n)
  % LOCAL_duffy Duffy.
  % Input
  %   n.
  % Output
  %   [x,y,w].
  [z,v]=LOCAL_gauss(n);[r,s]=ndgrid(z,z);[a,b]=ndgrid(v,v);x=r(:);y=(1-x).*s(:);w=a(:).*b(:).*(1-x);
end
function [x,w]=LOCAL_gauss(n)
  % LOCAL_gauss Gauss.
  % Input
  %   n.
  % Output
  %   [x,w].
  j=(1:n-1)';b=j./sqrt(4*j.^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));
  [x,k]=sort(diag(D));x=(x+1)/2;w=V(1,k)'.^2;
end
function LOCAL_json(file,value)
  % LOCAL_json Json.
  % Input
  %   file,value.
  % Output
  %   No returned value; performs the stated check or output operation..
  f=fopen(file,'w');assert(f>=0);cleaner=onCleanup(@()fclose(f)); %#ok<NASGU>
  fwrite(f,jsonencode(value,PrettyPrint=true),'char');
end

function G=LOCAL_field_coefficients(G,T,U)
  % LOCAL_field_coefficients Field coefficients.
  % Input
  %   G,T,U.
  % Output
  %   G.
  G.field_degree=T.field_degree;G.field_alpha=T.field_alpha;nb=size(T.field_dofs,2);nc=size(U,2);
  points=T.field_alpha(:,2:3)/T.field_degree;V=LOCAL_monomials(points(:,1),points(:,2),T.field_degree);
  G.field_coefficients=complex(zeros(G.nt,nb,nc));G.field_values=G.field_coefficients;
  for j=1:nc
    nodal=reshape(U(T.field_dofs,j),G.nt,nb);G.field_values(:,:,j)=nodal;G.field_coefficients(:,:,j)=nodal/V.';
  end
end
function [values,gx,gy]=LOCAL_direct_high(G,e,x,y,PX,J,det,cfg)
  % LOCAL_direct_high Direct high.
  % Input
  %   G,e,x,y,PX,J,det,cfg.
  % Output
  %   [values,gx,gy].
  [B,Bx,By]=LOCAL_monomials(x,y,G.field_degree);n=numel(x);nc=numel(G.cells);
  values=complex(zeros(n,nc));if nargout>1,gx=values;gy=values;end
  for j=1:nc
    c=G.field_coefficients(e,:,j);u=sum(B.*c,2);X=PX+G.cells(j);t=max(0,min(1,(abs(X)-cfg.model.taper.start)/cfg.model.taper.width));chi=(1+cos(pi*t))/2;
    values(:,j)=chi.*u;
    if nargout>1
      ux=sum(Bx.*c,2);uy=sum(By.*c,2);dx=(J(:,4).*ux-J(:,3).*uy)./det;dy=(-J(:,2).*ux+J(:,1).*uy)./det;
      dchi=-(pi/(2*cfg.model.taper.width))*sin(pi*t).*sign(X);gx(:,j)=chi.*dx+dchi.*u;gy(:,j)=chi.*dy;
    end
  end
end
function check=LOCAL_evaluator_check(P,cfg)
  % LOCAL_evaluator_check Evaluator check.
  % Input
  %   P,cfg.
  % Output
  %   check.
  LOCAL_key(P,cfg);values=zeros(1,3);gradients=values;degrees=values;
  for t=1:3
    G=P.templates{t}.G;if ~isfield(G,'field_degree'),degrees(t)=2;continue;end
    degrees(t)=G.field_degree;ids=unique(round(linspace(1,G.nt,31)))';n=numel(ids);
    x=.13+.003*(1:n)';y=.27-.002*(1:n)';[PX,~,J,det]=LOCAL_map(G.mx(ids,:),G.my(ids,:),x,y);
    [v,gx,gy]=LOCAL_direct_high(G,ids,x,y,PX,J,det,cfg);
    [N,Nx,Ny]=direct_native('basis',G.field_degree,G.field_alpha,[x,y]);vv=v;xx=v;yy=v;
    for j=1:numel(G.cells)
      c=G.field_values(ids,:,j);u=sum(N.*c,2);ux=sum(Nx.*c,2);uy=sum(Ny.*c,2);
      X=PX+G.cells(j);tau=max(0,min(1,(abs(X)-cfg.model.taper.start)/cfg.model.taper.width));chi=(1+cos(pi*tau))/2;dchi=-(pi/(2*cfg.model.taper.width))*sin(pi*tau).*sign(X);
      vv(:,j)=chi.*u;xx(:,j)=chi.*(J(:,4).*ux-J(:,3).*uy)./det+dchi.*u;
      yy(:,j)=chi.*(-J(:,2).*ux+J(:,1).*uy)./det;
    end
    values(t)=norm(v-vv,'fro')/norm(vv,'fro');gradients(t)=norm([gx-xx,gy-yy],'fro')/norm([xx,yy],'fro');
  end
  check=struct('degrees',degrees,'points_per_template',31,'value_relative',values,'gradient_relative',gradients,'tolerance',1e-10,'pass',max([values,gradients])<1e-10);
end

function report=LOCAL_inventory(P,S,cfg)
  % LOCAL_inventory Inventory.
  % Input
  %   P,S,cfg.
  % Output
  %   report.
  started=tic;items=struct([]);totals=zeros(2,4);
  for t=1:3
    G=P.templates{t}.G;T=P.templates{t}.T;nc=numel(G.cells);nt=G.nt;
    [affine,defect]=LOCAL_affine(T);curved=false(nt,1);curved([T.interface.inner;T.interface.outer])=true;
    native_class=1+~affine;fitted_class=ones(nt,1);fitted_class(~affine&~curved)=4;fitted_class(curved)=2;
    item=struct('template',T.name,'triangles',nt,'cells',G.cells,'affine_count',sum(affine), ...
      'interface_count',sum(curved),'noninterface_nonaffine',sum(~affine&~curved),'midpoint_defect_max',max(defect(~curved)), ...
      'native',zeros(2,3,4),'fitted',zeros(2,4,2),'counts_native',zeros(1,3),'counts_fitted',zeros(1,4));
    for j=1:nc
      taper=abs(G.cells(j))>=G.taper.first_cell;cn=native_class;if taper,cn(:)=3;end
      cf=fitted_class;if taper,cf(:)=3;end
      for cl=1:3,item.counts_native(cl)=item.counts_native(cl)+sum(cn==cl);end
      for cl=1:4,item.counts_fitted(cl)=item.counts_fitted(cl)+sum(cf==cl);end
    end
    for io=1:2
      order=cfg.orders(io);[x,y,w]=LOCAL_duffy(order);nq=numel(w);
      ee=zeros(nt,nc);mm=ee;ss=ee;mg=ee;
      for first=1:cfg.block:nt
        ids=first:min(first+cfg.block-1,nt);nb=numel(ids);ei=repelem(ids(:),nq);xx=repmat(x,nb,1);yy=repmat(y,nb,1);
        [PX,~,J,d]=LOCAL_map(G.mx(ei,:),G.my(ei,:),xx,yy);[v,gx,gy]=LOCAL_direct(G,ei,xx,yy,PX,J,d,cfg);
        W=repmat(w,nb,1).*d;rho=repelem(reshape(T.material(ids),[],1),nq,1);
        ee(ids,:)=reshape(sum(reshape(W.*(abs(gx).^2+abs(gy).^2),nq,nb,nc),1),nb,nc);
        mm(ids,:)=reshape(sum(reshape(W.*rho.*abs(v).^2,nq,nb,nc),1),nb,nc);
      end
      bo=cfg.band_orders;band=LOCAL_band(G,T,bo(io));
      for first=1:1024:numel(band.w)
        ids=first:min(first+1023,numel(band.w));ei=band.e(ids);xx=band.x(ids);yy=band.y(ids);
        [PX,~,J,d]=LOCAL_map(G.mx(ei,:),G.my(ei,:),xx,yy);v=LOCAL_direct(G,ei,xx,yy,PX,J,d,cfg);
        for j=1:nc,mg(:,j)=mg(:,j)+accumarray(ei,band.w(ids)*(T.rho_in-T.background).*abs(v(:,j)).^2,[nt,1]);end
      end
      rules=G.fitted.rules(order);
      for ri=1:numel(rules)
        r=rules{ri};nq=numel(r.w);[vx,vy,dv]=LOCAL_rt(r.x,r.y,3);vx=vx*S.B;vy=vy*S.B;dv=dv*S.B;
        for first=1:cfg.block:numel(r.ids)
          ids=r.ids(first:min(first+cfg.block-1,numel(r.ids)));nb=numel(ids);ei=repelem(ids(:),nq);
          [PX,PY,J,d]=G.fitted.map(ei,repmat(r.x,nb,1),repmat(r.y,nb,1));[v,gx,gy]=LOCAL_field(G,[],cfg,ei,PX,PY);
          W=repmat(r.w,nb,1).*d;rho=repelem(reshape(T.material(ids),[],1),nq,1);px=repmat(vx,nb,1);py=repmat(vy,nb,1);dd=repmat(dv,nb,1);
          fx=LOCAL_point_flux((J(:,1).*px+J(:,2).*py)./d,S.flux{t},ei);
          fy=LOCAL_point_flux((J(:,3).*px+J(:,4).*py)./d,S.flux{t},ei);fd=LOCAL_point_flux(dd./d,S.flux{t},ei);
          val=W.*(abs(fx-gx/P.q).^2+abs(fy-gy/P.q).^2+abs(fd+rho*(1-1/P.q).*v).^2./rho);
          ss(ids,:)=reshape(sum(reshape(val,nq,nb,nc),1),nb,nc);
        end
      end
      for j=1:nc
        cn=native_class;cf=fitted_class;if abs(G.cells(j))>=G.taper.first_cell,cn(:)=3;cf(:)=3;end
        for cl=1:3
          use=cn==cl;item.native(io,cl,:)=reshape(squeeze(item.native(io,cl,:)).'+[sum(ee(use,j)),sum(mm(use,j)),sum(mg(use,j)),0],1,1,4);
        end
        for cl=1:4
          use=cf==cl;item.fitted(io,cl,1)=item.fitted(io,cl,1)+sum(ss(use,j));
          if cl==3,item.fitted(io,cl,2)=item.fitted(io,cl,2)+sum(ss(use&curved,j));end
        end
      end
      totals(io,:)=totals(io,:)+[sum(ee,'all'),sum(mm,'all'),sum(mg,'all'),sum(ss,'all')];
    end
    if t==1,items=item;else,items(t)=item;end
    fprintf('INVENTORY %s: affine %d noninterface-nonaffine %d max_mid %.3e\n',T.name,sum(affine),item.noninterface_nonaffine,item.midpoint_defect_max);
  end
  report=struct('templates',items,'columns',{{'E','M_native','mass_correction','S'}},'totals',totals, ...
    'mass16',sum(totals(1,2:3)),'mass24',sum(totals(2,2:3)),'seconds',toc(started));
  report.energy_sum_relative=abs(totals(1,1)-P.energy)/P.energy;report.mass_sum_relative=abs(report.mass16-P.mass)/P.mass;
  report.pass=max([report.energy_sum_relative,report.mass_sum_relative])<1e-13;
  assert(report.pass,'qj:Inventory','Class totals disagree with baseline.');
end
function [affine,defect]=LOCAL_affine(T)
  % LOCAL_affine Affine.
  % Input
  %   T.
  % Output
  %   [affine,defect].
  nt=size(T.tri6,1);nodes=reshape(T.xy(T.tri6(:),:),nt,6,2);
  delta=nodes(:,4:6,:)-(nodes(:,[1,2,3],:)+nodes(:,[2,3,1],:))/2;
  defect=max(abs(delta),[],[2,3]);affine=defect==0;
end
function [N,report]=LOCAL_exact_flux(P,S,cfg)
  % LOCAL_exact_flux Exact flux.
  % Input
  %   P,S,cfg.
  % Output
  %   [N,report].
  started=tic;N=S;B=exact_rt3_basis();N.B=B;Bchange=B\S.B;maxedge=0;
  for t=1:3
    G=S.G{t};nt=G.nt;nc=numel(G.cells);old=S.flux{t};local=reshape(Bchange*reshape(old,24,[]),size(old));
    master=S.master_edges{t};ph=G.phase.';map=G.map.';
    for j=1:nc
      edge=ph.*reshape(master(map(:),j),12,nt);maxedge=max(maxedge,max(abs(edge-reshape(old(1:12,j,:),12,nt)),[],'all'));
      local(1:12,j,:)=reshape(edge,12,1,nt);
    end
    N.flux{t}=local;
  end
  after=LOCAL_evaluate(P,N,cfg);before=LOCAL_evaluate(P,S,cfg);
  % cfg adds square_q only internally, so preserve the stored cache key.
  report=struct('S_before',before.qJ_square*P.mass/P.q,'S_after',after.qJ_square*P.mass/P.q, ...
    'S_change',(after.qJ_square-before.qJ_square)*P.mass/P.q,'width_before',before.square_interval.width, ...
    'width_after',after.square_interval.width,'width_relative_change',after.square_interval.width/before.square_interval.width-1, ...
    'shared_master_reconstruction_difference',maxedge,'integer_basis_max',max(abs(B),[],'all'), ...
    'vertical_master_moment',max(abs(S.master_wall([1:numel(S.G{1}.left),end-numel(S.G{1}.right)+1:end]))), ...
    'top_bottom_symbolic_phase',true,'cell_wall_common_master',true,'seconds',toc(started));
end
function report=LOCAL_certificates(P,S,cfg,output_dir,inventory)
  % LOCAL_certificates Certificates.
  % Input
  %   P,S,cfg,output_dir,inventory.
  % Output
  %   report.
  report=qj_certificates(P,S,cfg,output_dir,inventory);
end

function r=LOCAL_transport_float(P,S,cfg,inventory)
  % LOCAL_transport_float Transport float.
  % Input
  %   P,S,cfg,inventory.
  % Output
  %   r.
  started=tic;rows=struct([]);total=zeros(2,5);
  for t=1:3
    G=P.templates{t}.G;T=P.templates{t}.T;cv=false(G.nt,1);cv([T.interface.inner;T.interface.outer])=true;nc=numel(G.cells);
    row=struct('template',T.name,'values',zeros(2,5));
    for io=1:2
      order=cfg.orders(io);nativeE=0;nativeM=0;newE=0;newM=0;newS=0;
      [x,y,w]=LOCAL_duffy(order);nq=numel(w);idsall=find(cv);
      for first=1:cfg.block:numel(idsall)
        ids=idsall(first:min(first+cfg.block-1,numel(idsall)));nb=numel(ids);ei=repelem(ids(:),nq);xx=repmat(x,nb,1);yy=repmat(y,nb,1);
        [PX,~,J,d]=LOCAL_map(G.mx(ei,:),G.my(ei,:),xx,yy);[v,gx,gy]=LOCAL_direct(G,ei,xx,yy,PX,J,d,cfg);W=repmat(w,nb,1).*d;rho=repelem(reshape(T.material(ids),[],1),nq,1);
        nativeE=nativeE+sum(W.*(abs(gx).^2+abs(gy).^2),'all');nativeM=nativeM+sum(W.*rho.*abs(v).^2,'all');
      end
      rules=G.fitted.rules(order);
      for ri=1:numel(rules)
        rule=rules{ri};idsall=rule.ids(cv(rule.ids));if isempty(idsall),continue,end;nq=numel(rule.w);
        [vx,vy,dv]=LOCAL_rt(rule.x,rule.y,3);vx=vx*S.B;vy=vy*S.B;dv=dv*S.B;
        for first=1:cfg.block:numel(idsall)
          ids=idsall(first:min(first+cfg.block-1,numel(idsall)));nb=numel(ids);ei=repelem(ids(:),nq);xx=repmat(rule.x,nb,1);yy=repmat(rule.y,nb,1);
          [PX,~,J,d]=G.fitted.map(ei,xx,yy);[v,gx,gy]=LOCAL_direct(G,ei,xx,yy,PX,J,d,cfg);
          W=repmat(rule.w,nb,1).*d;rho=repelem(reshape(T.material(ids),[],1),nq,1);px=repmat(vx,nb,1);py=repmat(vy,nb,1);dd=repmat(dv,nb,1);
          fx=LOCAL_point_flux((J(:,1).*px+J(:,2).*py)./d,S.flux{t},ei);fy=LOCAL_point_flux((J(:,3).*px+J(:,4).*py)./d,S.flux{t},ei);fd=LOCAL_point_flux(dd./d,S.flux{t},ei);
          newE=newE+sum(W.*(abs(gx).^2+abs(gy).^2),'all');newM=newM+sum(W.*rho.*abs(v).^2,'all');
          newS=newS+sum(W.*(abs(fx-gx/P.q).^2+abs(fy-gy/P.q).^2+abs(fd+rho*(1-1/P.q).*v).^2./rho),'all');
        end
      end
      row.values(io,:)=[nativeE,nativeM,newE,newM,newS];total(io,:)=total(io,:)+row.values(io,:);
    end
    if t==1,rows=row;else,rows(t)=row;end
  end
  r=struct('templates',rows,'columns',{{'native_interface_E','native_interface_M','transported_interface_E','transported_interface_M','transported_interface_S'}},'values',total,'cases',struct([]),'seconds',toc(started));
  for io=1:2
    E=inventory.totals(io,1)-total(io,1)+total(io,3);M=sum(inventory.totals(io,2:3))-total(io,2)-inventory.totals(io,3)+total(io,4);
    oldint=sum(arrayfun(@(t)t.fitted(io,2,1)+t.fitted(io,3,2),inventory.templates));oldS=inventory.totals(io,4);newS=oldS-oldint+total(io,5);
    c=four_corners([E,E],[M,M],newS,P.q,cfg);case0=struct('E',E,'M',M,'q',1+E/M,'S',newS,'S_interface',total(io,5), ...
      'E_change',total(io,3)-total(io,1),'M_change',total(io,4)-total(io,2)-inventory.totals(io,3),'S_change',total(io,5)-oldint, ...
      'S_relative_increase',newS/oldS-1,'interval',c,'width_penalty',c.width/4.453737393984524e-9-1);
    if io==1,r.cases=case0;else,r.cases(io)=case0;end
  end
  r.route_T_numerically_acceptable=r.cases(1).S_relative_increase<=.003&&r.cases(1).width_penalty<.01;
end
