function result = compare_mode_fields(input_file,output_dir,reuse_file,mode)
%COMPARE_MODE_FIELDS Compare saved continuous BIE and FEM approximate fields.
% Purpose: Test physical mode identity on shared, true-material volume points,
%   using one global complex phase and physical gradients at common ports.
% Input: Compact MAT produced by extract_mode_inputs; explicit output folder.
%   Optional reuse_file freezes a prior physical quadrature and both fields,
%   and only increases BIE quadrature on the nearest interface radial rows.
%   Optional mode='ports-only' evaluates both sides of the two cell ports
%   using the global normalization in the saved reuse_file; no volume work.
% Output: Numerical metrics JSON, quadrature/field MAT and diagnostic PNG.
% Main algorithm: Independent isoparametric P4 interpolation, saved BIE layer
%   evaluation, weighted overlaps, per-cell mass, multipliers and port traces.
% Based on: Saved I9.2 and I10.1 representations; the public QP Green evaluator
%   and FMM2D are explicit shared numerical dependencies. No solver is copied.
% Numerical goal: Ordinary numerical mode evidence, never a certified bound.
  timer = tic;
  maxNumCompThreads(4);
  loaded = load(input_file); bie = loaded.bie; fem = loaded.fem; clear loaded
  if ~exist(output_dir,'dir'), mkdir(output_dir); end
  cells = 12; % Four-cell and twelve-cell prefixes diagnose localization.
  [fem,bie] = LOCAL_coefficients(fem,bie,cells);
  if nargin>=4 && strcmp(mode,'ports-only')
    stored=load(reuse_file,'result'); normalization=stored.result.levels(end).prefix12;
    result=struct('status','NUMERICAL_CAUCHY_DIAGNOSTIC','ports', ...
      LOCAL_ports(fem,bie,normalization,1536),'matlab_seconds',toc(timer));
    LOCAL_json(fullfile(output_dir,'ports-complete.json'),result);
    fprintf('COMPLETE both-sided ports %.2f seconds\n',toc(timer));return
  end
  levels = [48,8;80,12]; % Angular midpoint count and radial Gauss count.
  result = struct('status','NUMERICAL_MODE_EVIDENCE_ONLY','k_B',bie.model.khat, ...
    'k_F',fem.center.k,'levels',struct([]),'dependencies', ...
    {{'saved I9.2 BIE density/proxy/propagator','saved I10.1 P4 mesh and recovery', ...
    'kernel.qpgreen_mfs_pairmat','hfmm2d'}});
  result.basis_checks = LOCAL_basis_check(fem.space.alpha);
  raw = cell(1,size(levels,1));
  refinement_only=nargin>=3 && ~isempty(reuse_file);
  if refinement_only
    stored=load(reuse_file,'raw'); oldraw=stored.raw; clear stored
    result.evaluation_stage='FROZEN_POINTS_NEAR_LAYER_6144';
  else
    result.evaluation_stage='INITIAL_LAYER_1536';
  end
  for level = 1:size(levels,1)
    ntheta = levels(level,1); nr = levels(level,2);
    nsource = 1536; % Evaluates the same trigonometric density at finer nodes.
    data = cell(1,3);
    for c = -1:1
      if refinement_only
        d=oldraw{level}{c+2};ids=[(nr-1)*ntheta+(1:ntheta),nr*ntheta+(1:ntheta)];
        fprintf('LEVEL %d cell %d: fixed-point near-layer correction at 6144 sources\n',level,c);
        [v,g,diag]=LOCAL_bie(bie,c,d.xy(ids,:),d.inside(ids),6144);
        d.B(ids,:)=v;d.gradB(ids,:,:)=g;d.bie_evaluation.near_layer=diag;
        data{c+2}=d;continue
      end
      fprintf('LEVEL %d cell %d: quadrature and independent FE evaluation\n',level,c);
      [xy,w,rho,inside] = LOCAL_quadrature(c,ntheta,nr,fem.model);
      [vf,gf,location] = LOCAL_fe(fem,c,xy);
      fprintf('LEVEL %d cell %d: BIE field at %d points\n',level,c,size(xy,1));
      [vb,gb,bie_eval] = LOCAL_bie(bie,c,xy,inside,nsource);
      data{c+2} = struct('xy',xy,'weight',w.*rho,'rho',rho,'inside',inside, ...
        'F',vf,'B',vb,'gradF',gf,'gradB',gb,'location',location,'bie_evaluation',bie_eval);
    end
    rec = struct('ntheta',ntheta,'radial_order',nr,'source_nodes',nsource, ...
      'prefix4',LOCAL_compare(data,4),'prefix12',LOCAL_compare(data,12));
    rec.cell_area = cellfun(@(d)sum(d.weight./d.rho),data);
    rec.inclusion_area = cellfun(@(d)sum(d.weight(d.inside)./d.rho(d.inside)),data);
    rec.location_max_residual = max(cellfun(@(d)d.location.max_residual,data));
    rec.location_min_barycentric = min(cellfun(@(d)d.location.min_barycentric,data));
    rec.minimum_sampled_curve_distance = cellfun(@(d)d.bie_evaluation.minimum_sampled_curve_distance,data);
    rec.symmetry = LOCAL_symmetry(data,ntheta,nr);
    safe=data;
    ids=[(nr-1)*ntheta+(1:ntheta),nr*ntheta+(1:ntheta)];
    for j=1:3,safe{j}.weight(ids)=0;end
    rec.without_nearest_radial_rows=LOCAL_compare(safe,12);
    if level==1,result.levels=rec;else,result.levels(level)=rec;end
    raw{level} = data;
    fprintf('LEVEL %d: overlap %.17g phase-field diff %.6e\n',level, ...
      rec.prefix12.overlap,rec.prefix12.phase_aligned_difference);
  end
  result.multipliers = LOCAL_multipliers(fem,bie);
  result.source_refinement = LOCAL_refinement(bie,raw{end},levels(end,1),levels(end,2),refinement_only);
  result.ports = LOCAL_ports(fem,bie,result.levels(end).prefix12,1536);
  result.quadrature_change = struct('overlap', ...
    result.levels(2).prefix12.overlap-result.levels(1).prefix12.overlap, ...
    'field_difference',result.levels(2).prefix12.phase_aligned_difference- ...
    result.levels(1).prefix12.phase_aligned_difference);
  result.matlab_seconds = toc(timer);
  save(fullfile(output_dir,'fields.mat'),'raw','result','-v7');
  LOCAL_json(fullfile(output_dir,'metrics.json'),result);
  LOCAL_plot(raw{end},result.levels(end).prefix12,output_dir);
  fprintf('COMPLETE comparison %.2f seconds\n',toc(timer));
end

%% ==================== Saved-state adapters ====================
% Convert saved extension maps into a bounded number of cell coefficient vectors.
function [fem,bie] = LOCAL_coefficients(fem,bie,cells)
  fem.center.coefficients = fem.space.center.Qqp*fem.center.u_free;
  for side = {'left','right'}
    name = side{1}; t = fem.space.(name); rec = fem.(name); n = size(rec.Pout,1);
    if strcmp(name,'left'), trace = fem.center.g(1:n);
    else, trace = fem.center.g(n+1:end); end
    values = complex(zeros(size(t.Qqp,1),cells));
    for j = 1:cells
      v = complex(zeros(numel(t.free),1));
      v(t.wall) = [trace;rec.Pout*trace];
      v(t.interior) = rec.B_interior*trace;
      values(:,j) = t.Qqp*v;
      trace = rec.Pout*trace;
    end
    fem.(name) = rmfield(rec,'B_interior');
    fem.(name).coefficients = values;
    fem.(name).tail_after12 = real(trace'*rec.X*trace);
  end
  for side = {'negative','positive'}
    name = side{1}; p = bie.propagation;
    if strcmp(name,'negative'), P=p.Pminus; G=p.Gminus; state=p.cminus;
    else, P=p.Pplus; G=p.Gplus; state=p.cplus; end
    q = complex(zeros(size(G,1),cells));
    for j=1:cells, q(:,j)=G*state; state=P*state; end
    bie.(name).q = q; bie.(name).density=bie.(name).H*q;
    bie.(name) = rmfield(bie.(name),'H');
  end
  bie.center.q = bie.q; bie.center.density = bie.center_density;
end

%% ==================== Shared physical quadrature ====================
% Homothetic analytic-curve coordinates cover inclusion and square background.
function [xy,w,rho,inside] = LOCAL_quadrature(c,nt,nr,model)
  theta = ((1:nt)'-0.5)*(2*pi/nt);
  [C,Cp] = LOCAL_curve(c,theta,model);
  outer = 0.5./max(abs(C),[],2);
  determinant = C(:,1).*Cp(:,2)-C(:,2).*Cp(:,1);
  assert(min(determinant)>0,'redteam:Geometry','Nonpositive polar Jacobian.');
  [g,gw]=LOCAL_gauss(nr); xy=[]; w=[]; inside=[];
  for region=1:2
    a=zeros(nt,1); b=ones(nt,1);
    if region==2, a=ones(nt,1); b=outer; end
    for j=1:nr
      s=a+(b-a)*g(j);
      xy=[xy;s.*C]; %#ok<AGROW>
      w=[w;determinant.*s.*(b-a)*gw(j)*(2*pi/nt)]; %#ok<AGROW>
      inside=[inside;repmat(region==1,nt,1)]; %#ok<AGROW>
    end
  end
  xy(:,1)=xy(:,1)+c;
  rho=ones(size(w)); r=17; if c==0, r=4; end
  rho(logical(inside))=r; inside=logical(inside);
end

function [C,Cp]=LOCAL_curve(c,t,model)
  if c==0
    a=1.5+0.3*cos(5*t); b=1+0.3*cos(5*t); d=-1.5*sin(5*t);
    C=0.2*model.star_scale*[a.*cos(t),b.*sin(t)];
    Cp=0.2*model.star_scale*[d.*cos(t)-a.*sin(t),d.*sin(t)+b.*cos(t)];
  else
    a=model.a_negative; if c>0,a=model.a_positive;end
    scale=model.radius/sqrt(1+a^2/2);
    r=scale*(1+a*cos(3*t)); d=-3*scale*a*sin(3*t);
    C=[r.*cos(t),r.*sin(t)]; Cp=[d.*cos(t)-r.*sin(t),d.*sin(t)+r.*cos(t)];
  end
end

function [x,w]=LOCAL_gauss(n)
  b=(1:n-1)./sqrt(4*(1:n-1).^2-1); [V,D]=eig(diag(b,1)+diag(b,-1));
  [x,id]=sort(diag(D)); w=V(1,id)'.^2; x=(x+1)/2;
end

%% ==================== Independent finite-element evaluator ====================
% Invert each P2 physical map and evaluate P4 barycentric Lagrange products.
function [value,grad,diagnostic]=LOCAL_fe(fem,c,xy)
  names={'left','center','right'}; name=names{c+2}; sp=fem.space; t=sp.(name);
  ids=fem.mesh.triangle_p2(t.element_ids,:);
  X=reshape(fem.mesh.p2_points(ids,1),size(ids));
  Y=reshape(fem.mesh.p2_points(ids,2),size(ids));
  lowx=min(X,[],2)-1e-4; highx=max(X,[],2)+1e-4;
  lowy=min(Y,[],2)-1e-4; highy=max(Y,[],2)+1e-4;
  coeff=fem.(name).coefficients; nc=size(coeff,2); np=size(xy,1);
  value=complex(zeros(np,nc)); grad=complex(zeros(np,2,nc));
  worst=0; minb=1;
  for q=1:np
    candidates=find(lowx<=xy(q,1)&highx>=xy(q,1)&lowy<=xy(q,2)&highy>=xy(q,2));
    chosen=0; best=-Inf; chosen_xi=[]; chosen_J=[];
    for e=candidates'
      V=[X(e,2)-X(e,1),X(e,3)-X(e,1);Y(e,2)-Y(e,1),Y(e,3)-Y(e,1)];
      z=V\(xy(q,:)'-[X(e,1);Y(e,1)]);
      for k=1:10
        [N,D]=LOCAL_p2(z); J=[X(e,:);Y(e,:)]*D;
        residual=[X(e,:);Y(e,:)]*N-xy(q,:)';
        z=z-J\residual;
        if norm(residual)<2e-14,break,end
      end
      bary=[1-sum(z);z];
      [N,D]=LOCAL_p2(z); residual=norm([X(e,:);Y(e,:)]*N-xy(q,:)');
      if min(bary)>=-1e-8 && residual<1e-11 && min(bary)>best
        best=min(bary);chosen=e;chosen_xi=z;chosen_J=[X(e,:);Y(e,:)]*D; rr=residual;
      end
    end
    assert(chosen>0,'redteam:Location','Point %d in cell %d not located.',q,c);
    [N,D]=LOCAL_lagrange(4,sp.alpha,chosen_xi);
    local=coeff(t.tri_dofs(chosen,:),:);
    value(q,:)=N.'*local;
    physical=chosen_J'\(D'*local);
    grad(q,:,:)=reshape(physical,1,2,nc);
    worst=max(worst,rr); minb=min(minb,best);
  end
  diagnostic=struct('max_residual',worst,'min_barycentric',minb);
end

function [N,D]=LOCAL_p2(z)
  l=[1-sum(z);z]; dl=[-1,-1;1,0;0,1];
  N=[l.*(2*l-1);4*l(1)*l(2);4*l(2)*l(3);4*l(3)*l(1)];
  D=[(4*l-1).*dl;4*(l(1)*dl(2,:)+l(2)*dl(1,:)); ...
    4*(l(2)*dl(3,:)+l(3)*dl(2,:));4*(l(3)*dl(1,:)+l(1)*dl(3,:))];
end

function [N,D]=LOCAL_lagrange(p,alpha,z)
  l=[1-sum(z);z]; dl=[-1,-1;1,0;0,1]; n=size(alpha,1);
  N=ones(n,1); D=zeros(n,2);
  for a=1:n
    f=ones(3,1); d=zeros(3,1);
    for r=1:3
      for j=0:alpha(a,r)-1
        factor=(p*l(r)-j)/(j+1);
        d(r)=d(r)*factor+f(r)*p/(j+1); f(r)=f(r)*factor;
      end
    end
    N(a)=prod(f);
    for r=1:3, D(a,:)=D(a,:)+d(r)*prod(f(setdiff(1:3,r)))*dl(r,:); end
  end
end

function check=LOCAL_basis_check(alpha)
  n=size(alpha,1); V=zeros(n,n);
  for j=1:n,V(j,:)=LOCAL_lagrange(4,alpha,alpha(j,2:3)'/4).';end
  [N,D]=LOCAL_lagrange(4,alpha,[0.23;0.37]);
  check=struct('nodal_identity',norm(V-eye(n),'inf'),'partition',abs(sum(N)-1), ...
    'gradient_partition',norm(sum(D,1)),'linear_reproduction', ...
    norm(N'*(alpha(:,2:3)/4)-[0.23,0.37]));
  assert(check.nodal_identity<1e-12 && check.partition<1e-12 && ...
    check.gradient_partition<1e-12 && check.linear_reproduction<1e-12);
end

%% ==================== Explicit BIE reconstruction ====================
% Use shared exterior QP kernels and separately written interior Hankel kernels.
function [value,grad,diagnostic]=LOCAL_bie(bie,c,xy,inside,ns)
  names={'negative','center','positive'}; b=bie.(names{c+2});
  t=(0:ns-1)'*(2*pi/ns);
  model=bie.model; model.radius=model.R;
  [C,Cp]=LOCAL_curve(c,t,model); speed=hypot(Cp(:,1),Cp(:,2));
  normal=[Cp(:,2),-Cp(:,1)]./speed; weight=speed*(2*pi/ns);
  n0=size(b.density,1)/2;
  density=[interpft(b.density(1:n0,:),ns,1);interpft(b.density(n0+1:end,:),ns,1)];
  dx=weight.*normal(:,1).*density(1:ns,:); dy=weight.*normal(:,2).*density(1:ns,:);
  charge=weight.*density(ns+1:end,:); nc=size(density,2); np=size(xy,1);
  value=complex(zeros(np,nc)); grad=complex(zeros(np,2,nc));
  pars=b.pars; pars.h2d_evaluator=@LOCAL_fmm;
  distance=Inf;
  for region=0:1
    list=find(inside==logical(region));
    for first=1:32:numel(list)
      index=list(first:min(first+31,numel(list))); trg=xy(index,:); trg(:,1)=trg(:,1)-c;
      distance=min(distance,min(hypot(trg(:,1)-C(:,1)',trg(:,2)-C(:,2)'),[],'all'));
      if region
        [P,Gx,Gy,Hxx,Hxy,Hyy]=LOCAL_free_kernel(b.kint,C,trg);
      else
        [P,Gx,Gy,Hxx,Hxy,Hyy]=kernel.qpgreen_mfs_pairmat(C',trg',pars,b.proxy);
      end
      v=-Gx*dx-Gy*dy-P*charge;
      gx=-Hxx*dx-Hxy*dy-Gx*charge; gy=-Hxy*dx-Hyy*dy-Gy*charge;
      if ~region
        [inc,igx,igy]=LOCAL_incident(b.q,bie.beta_m,bie.gamma,trg);
        v=v+inc;gx=gx+igx;gy=gy+igy;
      end
      value(index,:)=v;grad(index,1,:)=reshape(gx,numel(index),1,nc);
      grad(index,2,:)=reshape(gy,numel(index),1,nc);
    end
  end
  diagnostic=struct('minimum_sampled_curve_distance',distance,'source_nodes',ns, ...
    'semantics','ordinary quadrature of continuous layer; not a finite-source global L2 trial');
end

function [P,Gx,Gy,Hxx,Hxy,Hyy]=LOCAL_free_kernel(k,src,trg)
  x=trg(:,1)-src(:,1)';y=trg(:,2)-src(:,2)';r=hypot(x,y);
  P=1i/4*besselh(0,1,k*r);f=-1i*k/4*besselh(1,1,k*r);
  fr=f./r;second=-k^2*P-fr; a=second-fr;
  Gx=fr.*x;Gy=fr.*y;Hxx=a.*(x./r).^2+fr;
  Hxy=a.*x.*y./r.^2;Hyy=a.*(y./r).^2+fr;
end

function [v,gx,gy]=LOCAL_incident(q,beta,gamma,xy)
  K=numel(gamma); psi=exp(1i*xy(:,2)*beta(:).');
  left=psi.*exp(1i*(xy(:,1)+0.5)*gamma(:).');
  right=psi.*exp(-1i*(xy(:,1)-0.5)*gamma(:).');
  ql=q(1:K,:);qr=q(K+1:end,:);
  v=left*ql+right*qr;
  gx=left*(1i*gamma(:).*ql)-right*(1i*gamma(:).*qr);
  gy=(left.*(1i*beta(:).'))*ql+(right.*(1i*beta(:).'))*qr;
end

function [pot,grad,hess]=LOCAL_fmm(k,src,q,trg)
  [u,ier]=hfmm2d(1e-12,k,struct('sources',src,'charges',reshape(q,1,[])),0,trg,3);
  assert(ier==0,'redteam:FMM','FMM returned nonzero error flag.');
  n=size(trg,2);pot=reshape(u.pottarg,1,n);grad=reshape(u.gradtarg,2,n);hess=reshape(u.hesstarg,3,n);
end

%% ==================== Phase, mass, tail and port metrics ====================
% Compare all cells with one common phase and normalize in weighted physical L2.
function out=LOCAL_compare(data,cells)
  bf=[];ff=[];w=[];mb=[];mf=[]; labels=[];
  for c=-1:1
    d=data{c+2};count=cells;if c==0,count=1;end
    b=d.B(:,1:count);f=d.F(:,1:count);
    bf=[bf;b(:)];ff=[ff;f(:)];w=[w;repmat(d.weight,count,1)]; %#ok<AGROW>
    mb=[mb,sum(d.weight.*abs(b).^2,1)];mf=[mf,sum(d.weight.*abs(f).^2,1)]; %#ok<AGROW>
    if c<0,labels=[labels,-(1:count)];elseif c>0,labels=[labels,1:count];else,labels=[labels,0];end %#ok<AGROW>
  end
  nb=sqrt(sum(w.*abs(bf).^2));nf=sqrt(sum(w.*abs(ff).^2));
  z=sum(w.*conj(bf).*ff)/(nb*nf);phase=conj(z)/abs(z);
  difference=sqrt(sum(w.*abs(bf/nb-phase*ff/nf).^2));
  out=struct('cells_per_side',cells,'overlap',abs(z),'phase_real',real(phase), ...
    'phase_imag',imag(phase),'norm_B',nb,'norm_F',nf,'phase_aligned_difference',difference, ...
    'energy_density_L1',sum(w.*abs(abs(bf/nb).^2-abs(ff/nf).^2)), ...
    'cell_indices',labels,'mass_fraction_B',mb/nb^2,'mass_fraction_F',mf/nf^2, ...
    'cell_mass_B',mb,'cell_mass_F',mf);
  d=data{2}; b=d.B(:,1)/nb; f=d.F(:,1)/nf;
  cutoff=1e-4*max(abs(b)); maskB=abs(b)<cutoff;maskF=abs(f)<cutoff;
  out.center_low_amplitude = struct('threshold_relative_to_max_B',1e-4, ...
    'B_count',nnz(maskB),'F_count',nnz(maskF),'mask_disagreements',nnz(xor(maskB,maskF)), ...
    'min_relative_magnitude_B',min(abs(b))/max(abs(b)), ...
    'min_relative_magnitude_F',min(abs(f))/max(abs(f)));
end

function out=LOCAL_refinement(bie,data,nt,nr,refinement_only)
  nold=1536;ncheck=3072;if refinement_only,nold=6144;ncheck=12288;end
  out=repmat(struct('cell',0,'points',0,'nodes_original',1536,'nodes_check',3072, ...
    'relative_value_change',0,'relative_gradient_change',0, ...
    'max_value_change_relative_to_sample_max',0),1,3);
  % Test every angular point of the closest inside/outside radial Gauss rows.
  ids=[(nr-1)*nt+(1:nt),nr*nt+(1:nt)];
  for c=-1:1
    d=data{c+2};[v,g]=LOCAL_bie(bie,c,d.xy(ids,:),d.inside(ids),ncheck);
    old=d.B(ids,:);oldg=d.gradB(ids,:,:);
    out(c+2)=struct('cell',c,'points',numel(ids),'nodes_original',nold,'nodes_check',ncheck, ...
      'relative_value_change',norm(v-old,'fro')/norm(v,'fro'), ...
      'relative_gradient_change',norm(g(:)-oldg(:))/norm(g(:)), ...
      'max_value_change_relative_to_sample_max',max(abs(v-old),[],'all')/max(abs(v),[],'all'));
  end
end

function out=LOCAL_symmetry(data,nt,nr)
  out=repmat(struct('cell',0,'conjugate_y_reflection_B',0,'conjugate_y_reflection_F',0),1,3);
  perm=reshape(1:2*nr*nt,nt,[]);perm=flipud(perm);perm=perm(:);
  for j=1:3
    d=data{j}; vals={d.B(:,1),d.F(:,1)};def=zeros(1,2);
    for k=1:2
      v=vals{k};r=conj(v(perm));z=sum(d.weight.*conj(v).*r);
      def(k)=sqrt(sum(d.weight.*abs(v-r*conj(z)/abs(z)).^2)/sum(d.weight.*abs(v).^2));
    end
    out(j)=struct('cell',j-2,'conjugate_y_reflection_B',def(1),'conjugate_y_reflection_F',def(2));
  end
end

function out=LOCAL_multipliers(fem,bie)
  out=struct();names={'left','right'};
  for j=1:2
    name=names{j}; P=bie.propagation.Pminus;if j==2,P=bie.propagation.Pplus;end
    b=eig(P);f=fem.(name).multipliers;[~,ib]=sort(abs(b),'descend');[~,ifem]=sort(abs(f),'descend');
    count=min([8,numel(b),numel(f)]); b=b(ib(1:count));f=f(ifem(1:count));
    out.(name)=struct('B_real',real(b),'B_imag',imag(b),'B_abs',abs(b), ...
      'F_real',real(f),'F_imag',imag(f),'F_abs',abs(f),'F_tail_mass_after12',fem.(name).tail_after12, ...
      'dominant_complex_difference',abs(b(1)-f(1)));
  end
end

function out=LOCAL_ports(fem,bie,metrics,ns)
  y=((1:80)'-0.5)/80-0.5;phase=complex(metrics.phase_real,metrics.phase_imag);
  for side=1:2
    x=side-1.5; xy=[repmat(x,numel(y),1),y];
    [f,gf]=LOCAL_fe(fem,0,xy);[b,gb]=LOCAL_bie(bie,0,xy,false(size(y)),ns);
    f=f/metrics.norm_F*phase;b=b/metrics.norm_B;
    gf=gf/metrics.norm_F*phase;gb=gb/metrics.norm_B;
    item=struct('x',x,'value_relative_difference',norm(f-b)/norm(b), ...
      'global_x_derivative_relative_difference',norm(gf(:,1)-gb(:,1))/norm(gb(:,1)), ...
      'global_y_derivative_relative_difference',norm(gf(:,2)-gb(:,2))/norm(gb(:,2)));
    c=2*side-3;[fl,gfl]=LOCAL_fe(fem,c,xy);[bl,gbl]=LOCAL_bie(bie,c,xy,false(size(y)),ns);
    fl=fl(:,1)/metrics.norm_F*phase;bl=bl(:,1)/metrics.norm_B;
    gfl=gfl(:,:,1)/metrics.norm_F*phase;gbl=gbl(:,:,1)/metrics.norm_B;
    item.lead_value_relative_difference=norm(fl-bl)/norm(bl);
    item.lead_global_x_derivative_relative_difference=norm(gfl(:,1)-gbl(:,1))/norm(gbl(:,1));
    item.lead_global_y_derivative_relative_difference=norm(gfl(:,2)-gbl(:,2))/norm(gbl(:,2));
    item.F_transmission_value=norm(f-fl)/norm(f);
    item.B_transmission_value=norm(b-bl)/norm(b);
    item.F_transmission_global_x_derivative=norm(gf(:,1)-gfl(:,1))/norm(gf(:,1));
    item.B_transmission_global_x_derivative=norm(gb(:,1)-gbl(:,1))/norm(gb(:,1));
    if side==1,out=item;else,out(side)=item;end
  end
end

%% ==================== Reproducible outputs ====================
% Persist ordinary metrics and plot shared physical values without altering inputs.
function LOCAL_json(path,value)
  fid=fopen(path,'w');assert(fid>=0);clean=onCleanup(@()fclose(fid)); %#ok<NASGU>
  fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end

function LOCAL_plot(data,m,outdir)
  fig=figure('Visible','off','Position',[100,100,1300,650]);
  phase=complex(m.phase_real,m.phase_imag);
  for panel=1:3
    subplot(3,1,panel);hold on
    for c=-1:1
      d=data{c+2};count=4;if c==0,count=1;end
      for j=1:count
        x=d.xy(:,1)+c*(j-1);b=d.B(:,j)/m.norm_B;f=phase*d.F(:,j)/m.norm_F;
        if panel==1,z=d.rho.*abs(b).^2;elseif panel==2,z=d.rho.*abs(f).^2;else,z=abs(b-f);end
        scatter(x,d.xy(:,2),5,z,'filled');
      end
    end
    axis equal tight;colorbar;xlabel('x');ylabel('y');
    if panel==1,title('BIE: rho |u|^2');elseif panel==2,title('FEM: rho |u|^2');else,title('Phase-aligned |u_B-u_F|');end
  end
  exportgraphics(fig,fullfile(outdir,'field-comparison.png'),'Resolution',140);close(fig);
end
