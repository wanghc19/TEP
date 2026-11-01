function [result,trial] = pipeline_reconstruction(action,input,reference)
  % Reconstruction stages for the saved control field; I9.6 is experiment 9.6.
  % Input
  %   action: 'prepare' with input directory, or 'verify' with trial and norms.
  % Output
  %   result: scalar norms/checks; trial: in-memory coefficients, never saved.
  % Source: goerisch-v1/goerisch_trial.m; closed-form formulas unchanged.
  started=tic;
  if strcmp(action,'verify')
    trial=input;result=LOCAL_verify(trial,reference);return
  end
  assert(strcmp(action,'prepare'));input_dir=input;level='control';
  p = struct('beta',0.5,'k0',1.558438079544167,'k_bie',1.5584378941820909, ...
    'cells_per_side',16,'batch_modes',32,'norm_order',12,'x_orders',[16,32], ...
    'y_orders',[128,256],'radius',0.2,'star_scale',1,'a_left',0.12,'a_right',0.20);
  p.s = p.k0^2; p.mu0 = p.s; p.mu_bie = p.k_bie^2;
  N = 256; M = 128;
  if strcmp(level,'main'), N = 512; M = 256; p.y_orders = [256,512]; end
  p.N = N; p.M = M; h = 1/N; nc = p.cells_per_side;
  saved = jsondecode(fileread(fullfile(input_dir,'result.json')));
  assert(saved.k==p.k0 && saved.constants.s==p.s,'theta:Input','Unexpected candidate or shift.');
  reference = saved.levels(strcmp({saved.levels.name},level));
  assert(reference.N==N && reference.M==M,'theta:Input','Unexpected resolution.');
  names = {'left','center','right'}; cell_lists = cell(1,3);
  indices = saved.native.cell_index(:)';
  cell_lists{1} = indices(indices<0); cell_lists{2} = indices(indices==0); cell_lists{3} = indices(indices>0);
  assert(isequal(sort(indices),-nc:nc),'theta:Input','Unexpected cell indices.');
  m = (-M:M)'; q = p.beta+2*pi*m; nm = numel(m); ncols = (2*nc+1)*N;
  coefficients = complex(zeros(nm,ncols,4));
  wl = complex(zeros(nm,1)); wr = wl;
  box_norm = 0; tail_norm = 0; source_pairing = 0; gradient_direct = 0;
  mode_norm = zeros(nm,1); mode_gradient = mode_norm;
  assembly_start = tic; input_seconds=0; coefficient_seconds=0;
  for b = 1:ceil(nm/p.batch_modes)
    mi = (b-1)*p.batch_modes+1:min(b*p.batch_modes,nm);
    F = complex(zeros(numel(mi),ncols,2));
    for t = 1:3
      files = dir(fullfile(input_dir,'blocks',level,[names{t},'_s*.mat']));
      files = files(~contains({files.name},'_corr'));
      assert(numel(files)==N/32,'theta:Input','Missing source strips.');
      for j = 1:numel(files)
        file = fullfile(files(j).folder,files(j).name); key = sprintf('F_b%03d',b);
        io_timer=tic;d = load(file,key,'cols'); Fb = d.(key);
        cf = [file(1:end-4),'_corr.mat'];
        if isfile(cf)
          dk = sprintf('dF_b%03d',b); delta = load(cf,dk); Fb = Fb+delta.(dk);
        end
        input_seconds=input_seconds+toc(io_timer);
        assert(size(Fb,4)==numel(cell_lists{t}),'theta:Input','Cell dimension mismatch.');
        for c = 1:numel(cell_lists{t})
          gc = (cell_lists{t}(c)+nc)*N+d.cols+1;
          F(:,gc,:) = Fb(:,:,:,c);
        end
      end
    end
    coefficient_timer=tic;Y = LOCAL_build(h,q(mi),p.s,F,p.norm_order);
    coefficient_seconds=coefficient_seconds+toc(coefficient_timer);
    coefficients(mi,:,:) = Y.coefficients; wl(mi) = Y.wl; wr(mi) = Y.wr;
    box_norm = box_norm+sum(Y.box_norm); tail_norm = tail_norm+sum(Y.tail_norm);
    source_pairing = source_pairing+sum(Y.source_pairing);
    gradient_direct = gradient_direct+sum(Y.gradient);
    mode_norm(mi) = Y.box_norm+Y.tail_norm; mode_gradient(mi) = Y.gradient;
    fprintf('%s assembly batch %d/%d, elapsed %.1f s\n',level,b,ceil(nm/p.batch_modes),toc(started));
  end
  clear F Y d Fb delta
  assembly_seconds = toc(assembly_start);
  total_norm = box_norm+tail_norm;
  gradient_identity = source_pairing-p.s*total_norm;
  expected_norm = reference.norms.ordinary.w2_in_box+reference.norms.ordinary.Td2;
  norm_relative_difference = abs(total_norm-expected_norm)/expected_norm;
  numerator_relative_difference = abs(gradient_identity-gradient_direct)/abs(gradient_identity);
  fprintf('norm relative difference %.3e; numerator relative difference %.3e\n',norm_relative_difference,numerator_relative_difference);
  assert(norm_relative_difference<1e-12,'theta:Assembly','Saved norm was not reproduced.');
  assert(numerator_relative_difference<1e-11,'theta:Energy','Numerator checks disagree.');
  base = struct('level',level,'parameters',p,'norm',total_norm,'box_norm',box_norm, ...
    'tail_norm',tail_norm,'expected_norm',expected_norm,'norm_relative_difference',norm_relative_difference, ...
    'source_pairing',source_pairing,'numerator_identity',gradient_identity, ...
    'numerator_direct',gradient_direct,'numerator_relative_difference',numerator_relative_difference, ...
    'assembly_seconds',assembly_seconds);

  timer=tic;mass_fine=total_norm;inclusions=struct([]);
  for t=1:3
    cv=LOCAL_curve(p,t);geometry=LOCAL_arcs(cv);
    hi=LOCAL_inclusions(coefficients,N,nc,cv,geometry,cell_lists{t},32,[]);
    rho=17;if t==2,rho=4;end
    mass_fine=mass_fine+(rho-1)*sum(hi.mass(:,1));
    inclusions=[inclusions,struct('cells',cell_lists{t},'rho',rho,'mass_fine',hi.mass(:,1)', ...
      'relative_area_error',abs(hi.area-geometry.area)/geometry.area)]; %#ok<AGROW>
  end
  result=base;result.inclusions=inclusions;result.denominator=mass_fine;
  result.theta=gradient_identity/mass_fine;
  result.timing=struct('source_input',input_seconds,'coefficient_build',coefficient_seconds, ...
    'source_assembly_other',assembly_seconds-input_seconds-coefficient_seconds, ...
    'normalization',toc(timer));
  result.timing.other=toc(started)-sum(cell2mat(struct2cell(result.timing)));
  trial=struct('coefficients',coefficients,'wl',wl,'wr',wr,'parameters',p,'cell_lists',{cell_lists});
end
function result=LOCAL_verify(trial,norms)
  p=trial.parameters;mass16=norms.norm;mass32=norms.norm;mass_y=norms.norm*[1,1];
  for t=1:3
    cv=LOCAL_curve(p,t);geometry=LOCAL_arcs(cv);cells=trial.cell_lists{t};
    lo=LOCAL_inclusions(trial.coefficients,p.N,p.cells_per_side,cv,geometry,cells,16,[]);
    hi=LOCAL_inclusions(trial.coefficients,p.N,p.cells_per_side,cv,geometry,cells,32,[128,256]);
    rho=17;if t==2,rho=4;end
    mass16=mass16+(rho-1)*sum(lo.mass(:,1));mass32=mass32+(rho-1)*sum(hi.mass(:,1));
    mass_y=mass_y+(rho-1)*sum(hi.mass(:,2:3),1);
  end
  result=struct('mass16',mass16,'mass32',mass32,'mass_y',mass_y, ...
    'theta_change_x',norms.theta-norms.numerator_identity/mass16, ...
    'theta_change_y',diff(norms.numerator_identity./mass_y), ...
    'theta_y_fine_minus_exact',norms.numerator_identity/mass_y(2)-norms.theta, ...
    'primary_mass_relative_change',abs(mass32-norms.denominator)/norms.denominator);
  result.pass=max(abs([result.theta_change_x,result.theta_change_y,result.theta_y_fine_minus_exact]))<1e-10 ...
    &&result.primary_mass_relative_change<1e-12;
end
function Y = LOCAL_build(h,q,s,F,order)
  % Same closed form and sweeps as I9.6 LOCAL_yukawa_batch; ordinary values.
  [nm,ncols,~] = size(F); a = sqrt(s+q.^2); E = exp(-a*h);
  [g0,g1] = LOCAL_gamma01(a*h);
  A = (F(:,:,1)-sqrt(3)*F(:,:,2))/sqrt(h); B = 2*sqrt(3)*F(:,:,2)/h^1.5;
  incL = (A+B*h)*h.*g0-B*h^2.*g1; incR = A*h.*g0+B*h^2.*g1;
  L = complex(zeros(nm,ncols+1)); R = L;
  for j=1:ncols, L(:,j+1)=E.*L(:,j)+incL(:,j); end
  for j=ncols:-1:1, R(:,j)=E.*R(:,j+1)+incR(:,j); end
  zm = (L(:,1:ncols)-A./a+B./a.^2)./(2*a);
  zp = (R(:,2:ncols+1)-(A+B*h)./a-B./a.^2)./(2*a);
  wl = R(:,1)./(2*a); wr = L(:,end)./(2*a);
  [x,wg] = LOCAL_gauss01(order); norm_box=zeros(nm,1); pair=norm_box; energy=norm_box;
  for g=1:order
    t=h*x(g); em=exp(-a*t); ep=exp(-a*(h-t));
    v=(A+B*t)./a.^2+zm.*em+zp.*ep;
    dv=B./a.^2-a.*zm.*em+a.*zp.*ep;
    norm_box=norm_box+h*wg(g)*sum(abs(v).^2,2);
    pair=pair+h*wg(g)*sum(real(conj(A+B*t).*v),2);
    energy=energy+h*wg(g)*sum(abs(dv).^2+q.^2.*abs(v).^2,2);
  end
  tails=(abs(wl).^2+abs(wr).^2)./(2*a);
  energy=energy+(a.^2+q.^2).*tails;
  Y=struct('coefficients',cat(3,A,B,zm,zp),'wl',wl,'wr',wr, ...
    'box_norm',norm_box,'tail_norm',tails,'source_pairing',pair,'gradient',energy);
end

function out = LOCAL_inclusions(C,N,nc,cv,geo,cells,nx,ny)
  started=tic; nm=size(C,1); M=(nm-1)/2; q=0.5+2*pi*(-M:M)'; a=sqrt(1.558438079544167^2+q.^2);
  ell=(1:nm-1)'; nf=2^nextpow2(2*nm-1);
  [gx,wx]=LOCAL_gauss01(nx); yg=cell(1,numel(ny)); yw=yg;
  for j=1:numel(ny), [yg{j},yw{j}]=LOCAL_gauss01(ny(j)); end
  grid=(-N/2:N/2)'/N; cuts=unique([geo.critical_x(:);grid(grid>min(geo.critical_x) & grid<max(geo.critical_x))]);
  left=cuts(1:end-1); width=diff(cuts);
  X=left+width.*sin(pi*gx'/2).^2;
  W=width.*(pi/2*sin(pi*gx')).*wx';
  X=X(:); W=W(:); crosses=LOCAL_crossings(cv,geo,X);
  count=sum(isfinite(crosses),1); assert(all(mod(count,2)==0),'theta:Curve','Odd crossing count.');
  area=0; mass=zeros(numel(cells),1+numel(ny)); maximum_crossings=max(count);
  for j=1:numel(X)
    col=floor((X(j)+0.5)*N)+1; t=X(j)-(-0.5+(col-1)/N);
    gc=(cells+nc)*N+col;
    A=reshape(C(:,gc,1),nm,[]); B=reshape(C(:,gc,2),nm,[]);
    zm=reshape(C(:,gc,3),nm,[]); zp=reshape(C(:,gc,4),nm,[]);
    v=(A+B*t)./a.^2+zm.*exp(-a*t)+zp.*exp(-a*(1/N-t));
    corr=ifft(abs(fft(v,nf,1)).^2,[],1); cp=corr(2:nm,:); c0=real(corr(1,:));
    for r=1:2:count(j)
      ya=crosses(r,j); yb=crosses(r+1,j); len=yb-ya; mid=(ya+yb)/2;
      phase=exp(2i*pi*ell*mid); kernel=phase.*sin(pi*ell*len)./(pi*ell);
      mass(:,1)=mass(:,1)+W(j)*(c0*len+2*real(kernel.'*cp))';
      for k=1:numel(ny)
        moment=cos(2*pi*ell*(len*(yg{k}-0.5))')*yw{k};
        kg=len*phase.*moment;
        mass(:,1+k)=mass(:,1+k)+W(j)*(c0*len+2*real(kg.'*cp))';
      end
      area=area+W(j)*len;
    end
  end
  out=struct('mass',mass,'area',area,'maximum_crossings',maximum_crossings,'seconds',toc(started));
end

function geo = LOCAL_arcs(cv)
  t=linspace(0,2*pi,8193)'; d=LOCAL_cderiv(cv,t); roots=t(abs(d(:,1))<1e-13);
  for j=find(d(1:end-1,1).*d(2:end,1)<0)'
    roots(end+1,1)=fzero(@(z)LOCAL_dx(cv,z),[t(j),t(j+1)]); %#ok<AGROW>
  end
  roots=sort([0;roots;2*pi]); roots=roots([true;diff(roots)>1e-10]);
  if roots(end)<2*pi-1e-10, roots(end+1)=2*pi; else, roots(end)=2*pi; end
  points=LOCAL_cpoint(cv,roots);
  [g,w]=LOCAL_gauss01(128); theta=2*pi*g; c=LOCAL_cpoint(cv,theta); dc=LOCAL_cderiv(cv,theta);
  area=pi*sum(w.*(c(:,1).*dc(:,2)-c(:,2).*dc(:,1)));
  geo=struct('theta',roots,'x',points(:,1),'critical_x',uniquetol(points(:,1),1e-12), 'area',area);
end

function z = LOCAL_dx(cv,t)
  d=LOCAL_cderiv(cv,t); z=d(:,1);
end

function crosses = LOCAL_crossings(cv,geo,x)
  crosses=inf(numel(geo.theta)-1,numel(x));
  for j=1:numel(geo.theta)-1
    loX=min(geo.x(j:j+1)); hiX=max(geo.x(j:j+1)); sel=find(x>loX & x<hiX);
    lo=ones(size(sel))*geo.theta(j); hi=ones(size(sel))*geo.theta(j+1);
    rising=geo.x(j+1)>geo.x(j);
    for it=1:49
      mid=(lo+hi)/2; p=LOCAL_cpoint(cv,mid); right=(p(:,1)<x(sel))==rising;
      lo(right)=mid(right); hi(~right)=mid(~right);
    end
    p=LOCAL_cpoint(cv,(lo+hi)/2); crosses(j,sel)=p(:,2);
  end
  crosses=sort(crosses,1);
end

function cv = LOCAL_curve(p,t)
  cv=struct('type','lead','cx',0,'cy',0,'scale',p.star_scale,'a',p.a_left,'R',0);
  if t==2, cv.type='center'; end
  if t==3, cv.a=p.a_right; end
  cv.R=p.radius/sqrt(1+cv.a^2/2);
end

function c = LOCAL_cpoint(cv,theta)
  % True interface point (template coordinates).
  theta = theta(:);
  if strcmp(cv.type,'center')
    sc = cv.scale*0.2; c5 = cos(5*theta);
    c = [sc*(1.5+0.3*c5).*cos(theta),sc*(1+0.3*c5).*sin(theta)];
  else
    r = cv.R*(1+cv.a*cos(3*theta)); c = [cv.cx+r.*cos(theta),r.*sin(theta)];
  end
end

function d = LOCAL_cderiv(cv,theta)
  theta = theta(:);
  if strcmp(cv.type,'center')
    sc = cv.scale*0.2; c5 = cos(5*theta); s5 = sin(5*theta);
    d = sc*[-1.5*s5.*cos(theta)-(1.5+0.3*c5).*sin(theta),-1.5*s5.*sin(theta)+(1+0.3*c5).*cos(theta)];
  else
    r = cv.R*(1+cv.a*cos(3*theta)); dr = -3*cv.a*cv.R*sin(3*theta);
    d = [dr.*cos(theta)-r.*sin(theta),dr.*sin(theta)+r.*cos(theta)];
  end
end

function [g0,g1] = LOCAL_gamma01(z)
  % Same small-argument series and closed form as I9.6 LOCAL_gamma01.
  g0=zeros(size(z)); g1=g0; small=z<0.5; zs=z(small);
  term=ones(size(zs)); s0=zeros(size(zs)); s1=s0;
  for k=0:24
    s0=s0+term/(k+1); s1=s1+term/(k+2); term=term.*(-zs)/(k+1);
  end
  g0(small)=s0; g1(small)=s1; zl=z(~small);
  g0(~small)=-expm1(-zl)./zl; g1(~small)=(1-exp(-zl).*(1+zl))./zl.^2;
end

function [x,w] = LOCAL_gauss01(n)
  j=(1:n-1)'; b=j./sqrt(4*j.^2-1); [V,D]=eig(diag(b,1)+diag(b,-1));
  [x,idx]=sort(diag(D)); w=V(1,idx)'.^2; x=(x+1)/2;
end

function LOCAL_json(file,value)
  f=fopen(file,'w'); assert(f>=0,'theta:Output','Cannot open output.');
  closer=onCleanup(@()fclose(f)); %#ok<NASGU>
  fwrite(f,jsonencode(value,PrettyPrint=true),'char');
end
