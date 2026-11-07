function report=qj_certificates(P,S,cfg,output_dir,inventory)
% Source: test/fem-goerisch/pipeline-v1/internal/qj_certificates.m. Copied numerical algorithm.
  % QJ_CERTIFICATES Bound Goerisch energy, mass and smooth residual pieces.
  % QJ denotes the Goerisch quantities q and J.
  % Input
  %   In-memory field P, exact-basis flux S, cfg, output_dir and class inventory.
  % Output
  %   Exact-real-arithmetic certificates and explicitly floating interface data.
  started=tic;report=struct('polynomial_tests',test_poly2());
  LOCAL_json(fullfile(output_dir,'polynomial-tests.json'),report.polynomial_tests);
  report.allocation=struct('E_rational',cfg.tolerances.E_rational,'S_common_rational',cfg.tolerances.S_common_rational,'C0_voluntary_halfwidth',cfg.tolerances.mass_halfwidth);
  templates=struct([]);Ec=0;Ee=0;Mn=0;Mt=0;C0=0;Cerr=0;bias=0;Sc=0;Se=0;St=0;Siface=0;Srough=0;eta2=0;
  nrat=0;nsrat=0;
  for t=1:3
    [aff,~]=LOCAL_affine(P.templates{t}.T);cv=false(numel(aff),1);T=P.templates{t}.T;cv([T.interface.inner;T.interface.outer])=true;
    nrat=nrat+sum(~aff);nsrat=nsrat+sum(~aff&~cv);
  end
  for t=1:3
    G=P.templates{t}.G;T=P.templates{t}.T;F=S.flux{t};nt=G.nt;nc=numel(G.cells);tt=tic;
    geo=geometry_certificate(T,G);LOCAL_json(fullfile(output_dir,[T.name,'-geometry-summary.json']),rmfield(geo,{'det_min','det_max','inverse_norm','jacobian_norm','eta_native','eta_fitted','D0','D1','Q1'}));assert(geo.native_global_pass&&geo.fitted_global_pass,'qj:Geometry','Whole-element deformation certificate failed');
    [aff,middef]=LOCAL_affine(T);curved=false(nt,1);curved([T.interface.inner;T.interface.outer])=true;
    vals=struct('template',T.name,'geometry',rmfield(geo,{'det_min','det_max','inverse_norm','jacobian_norm','eta_native','eta_fitted','D0','D1','Q1'}), ...
      'E_affine',0,'E_rational',0,'E_error',0,'E_taper_upper',0,'M_native_exact',0,'M_taper_upper',0,'M_taper_value',0,'M_taper_error',0,'E_taper_value',0,'E_taper_error',0,'S_taper_value',0,'S_taper_error',0, ...
      'S_affine',0,'S_common_rational',0,'S_error',0,'S_taper_upper',0,'S_interface_float',0,'S_interface_coarse_upper',0, ...
      'C0',0,'C0_error',0,'mass_bias',0,'max_rational_degree',0,'max_kappa',0,'eta_s_squared',0, ...
      'inverse_extension_count',0,'inverse_extension_failures',0,'inverse_extension_refined',0,'max_inverse_kappa',0,'min_inverse_selfmap_margin',Inf);
    I=inventory.templates(t);ivn=I.native;ivf=I.fitted;
    vals.E_affine=ivn(1,1,1);vals.M_native_exact=sum(ivn(1,1:2,2));vals.S_affine=ivf(1,1,1);vals.S_interface_float=ivf(1,2,1)+ivf(1,3,2);
    % Scalar polynomial coefficient bounds cover all native branches in a cell.
    Ubound=zeros(nt,nc);Lbound=Ubound;untaper=abs(G.cells)<G.taper.first_cell;taper=~untaper;
    for e=1:nt
      for j=1:nc
        U=LOCAL_fieldpoly(G,e,j);[ux,uy]=LOCAL_grad(U);un=LOCAL_norm(U);
        Ubound(e,j)=un;Lbound(e,j)=geo.inverse_norm(e)*hypot(LOCAL_norm(ux),LOCAL_norm(uy));
        if taper(j),Lbound(e,j)=Lbound(e,j)+pi/(2*G.taper.width)*un;end
      end
    end
    for e=1:nt
      J=LOCAL_jac(G,e);den=LOCAL_det(J);
      Epoly=0;Spoly=0;
      for j=1:nc
        U=LOCAL_fieldpoly(G,e,j);[ux,uy]=LOCAL_grad(U);
        un=LOCAL_norm(U);gradn=hypot(LOCAL_norm(ux),LOCAL_norm(uy));Ubound(e,j)=un;Lbound(e,j)=geo.inverse_norm(e)*gradn;
        if taper(j),Lbound(e,j)=Lbound(e,j)+pi/(2*G.taper.width)*un;end
        [px,py]=LOCAL_raw_flux(S.B*F(:,j,e));[pdx,~]=LOCAL_grad(px);[~,pdy]=LOCAL_grad(py);div=LOCAL_add(pdx,pdy);
        if taper(j)
          tc=taper_certificate(G,e,G.cells(j),U,px,py,T.material(e),geo.det_min(e),geo.det_max(e),P.q,cfg.tolerances.E_rational/(4*nt),~curved(e));
          vals.E_taper_value=vals.E_taper_value+tc.E;vals.E_taper_error=vals.E_taper_error+tc.E_error;
          vals.M_taper_value=vals.M_taper_value+tc.M;vals.M_taper_error=vals.M_taper_error+tc.M_error;
          if ~curved(e)
            vals.S_taper_value=vals.S_taper_value+tc.S;vals.S_taper_error=vals.S_taper_error+tc.S_error;
          else
            partner=T.interface.outer(find(T.interface.inner==e,1));if isempty(partner),partner=T.interface.inner(find(T.interface.outer==e,1));end
            hf=(1+geo.eta_fitted(e))*geo.jacobian_norm(e);jf=(1+geo.eta_fitted(e))^2*geo.det_max(e);mf=(1-geo.eta_fitted(e))^2*geo.det_min(e);
            pn=hypot(LOCAL_norm(px),LOCAL_norm(py));dv=LOCAL_norm(div);ln=max(Lbound([e,partner],j));vn=max(Ubound([e,partner],j));
            vals.S_interface_coarse_upper=vals.S_interface_coarse_upper+.5/mf*((hf*pn+jf*ln/P.q)^2+(dv+T.material(e)*(1-1/P.q)*vn*jf)^2/T.material(e));
          end
        else
          if ~aff(e)
            ax=LOCAL_add(conv2(J{4},ux),-conv2(J{3},uy));ay=LOCAL_add(-conv2(J{2},ux),conv2(J{1},uy));
            Epoly=LOCAL_add(Epoly,LOCAL_add(LOCAL_abs2(ax),LOCAL_abs2(ay)));
          end
          if ~aff(e)&&~curved(e)
            ax=LOCAL_add(conv2(J{1},px),conv2(J{2},py));ay=LOCAL_add(conv2(J{3},px),conv2(J{4},py));
            gx=LOCAL_add(conv2(J{4},ux),-conv2(J{3},uy));gy=LOCAL_add(-conv2(J{2},ux),conv2(J{1},uy));
            r1=LOCAL_add(ax,-gx/P.q);r2=LOCAL_add(ay,-gy/P.q);
            r3=LOCAL_add(div,T.material(e)*(1-1/P.q)*conv2(U,den));
            Spoly=LOCAL_add(Spoly,LOCAL_add(LOCAL_add(LOCAL_abs2(r1),LOCAL_abs2(r2)),LOCAL_abs2(r3)/T.material(e)));
          end
        end
      end
      if ~aff(e)
        rr=poly2('rational_triangle',Epoly,den,geo.det_min(e),geo.det_max(e),cfg.tolerances.E_rational/nrat);
        vals.E_rational=vals.E_rational+rr.value;vals.E_error=vals.E_error+cfg.tolerances.E_rational/nrat;
        vals.max_rational_degree=max(vals.max_rational_degree,rr.degree);vals.max_kappa=max(vals.max_kappa,rr.kappa);
      end
      if ~aff(e)&&~curved(e)
        rr=poly2('rational_triangle',Spoly,den,geo.det_min(e),geo.det_max(e),cfg.tolerances.S_common_rational/nsrat);
        vals.S_common_rational=vals.S_common_rational+rr.value;vals.S_error=vals.S_error+cfg.tolerances.S_common_rational/nsrat;
      end
    end
    % All possible swept-segment native branches are covered by the full cell.
    Lglobal=max(Lbound,[],1);arcrows=struct([]);ar=0;
    for k=1:numel(T.interface.theta)
      cm=curve_model(T.curve,T.interface.theta(k),T.interface.dtheta,T.curve_order);
      e=T.interface.inner(k);ep=T.interface.outer(k);verts=T.xy(T.tri6(e,1:3),:);
      [~,a]=min(sum((verts-cm.p0).^2,2));[~,b]=min(sum((verts-cm.p1).^2,2));
      lam=cell(1,3);lam(:)={0};lam{a}=[.5;-.5];lam{b}=[.5;.5];xx=lam{2};yy=lam{3};
      detmodel=LOCAL_imag_model(poly2('add',poly2('mul',LOCAL_conj(cm.dq),cm.d),LOCAL_scale(poly2('mul',LOCAL_conj(cm.dd),cm.d),.5)));
      for j=1:nc
        Uedge=LOCAL_compose(LOCAL_fieldpoly(G,e,j),xx,yy);Ve=LOCAL_norm(Uedge);L=max(Lbound([e,ep],j));
        f0=poly2('make',LOCAL_abs2(Uedge),0);
        if taper(j)
          qx=poly2('make',real(cm.q.c),0);qx.c(1)=qx.c(1)+G.cells(j);sgn=sign(G.cells(j));phi=LOCAL_scale(qx,sgn*pi/G.taper.width);phi.c(1)=phi.c(1)-G.taper.start*pi/G.taper.width;
          chi=poly2('cos',phi,18);chi.c(1)=chi.c(1)+1;chi=LOCAL_scale(chi,.5);f0=poly2('mul',f0,poly2('mul',chi,chi));
        end
        cmass=LOCAL_scale(poly2('mul',f0,detmodel),-(T.rho_in-T.background));v=LOCAL_line_integral(cmass.c);ce=cmass.e;
        be=(T.rho_in-T.background)*(2*Ve*L*geo.D0(k)^2*(geo.Q1(k)/2+geo.D1(k)/3)+L^2*geo.D0(k)^3*(geo.Q1(k)/3+geo.D1(k)/4));
        vals.C0=vals.C0+real(v);vals.C0_error=vals.C0_error+ce;vals.mass_bias=vals.mass_bias+be;
        ar=ar+1;row=struct('arc',k,'cell',G.cells(j),'C0',real(v),'C0_error',ce,'bias',be,'V',Ve,'L',L,'D0',geo.D0(k),'D1',geo.D1(k),'Q1',geo.Q1(k));
        if ar==1,arcrows=row;else,arcrows(ar)=row;end
      end
      % Pair-union preservation follows from the valid shared-edge deformation.
      % A common inverse extension is tested on a cube around the reference centroid.
      for e=[T.interface.inner(k),T.interface.outer(k)]
        partner=ep;if e==ep,partner=T.interface.inner(k);end
        ext=LOCAL_inverse_extension(G,T,e,cm);vals.inverse_extension_refined=vals.inverse_extension_refined+ext.refined;vals.max_inverse_kappa=max(vals.max_inverse_kappa,ext.kappa);
        vals.min_inverse_selfmap_margin=min(vals.min_inverse_selfmap_margin,ext.margin);
        if ext.pass,vals.inverse_extension_count=vals.inverse_extension_count+1;else,vals.inverse_extension_failures=vals.inverse_extension_failures+1;end
        for j=find(untaper)
          U=LOCAL_fieldpoly(G,e,j);[ux,uy]=LOCAL_grad(U);scale=4/3;
          Ve=LOCAL_weight_norm(U,scale);Le=ext.inverse_norm*hypot(LOCAL_weight_norm(ux,scale),LOCAL_weight_norm(uy,scale));
          La=max(Lbound([e,partner],j));Ga=La+Le;Ua=Ga*geo.D0(k);
          area=geo.D0(k)*(geo.Q1(k)+geo.D1(k)/2);
          vals.eta_s_squared=vals.eta_s_squared+area*(Ga^2/P.q^2+max(T.material([e,partner]))*(1-1/P.q)^2*Ua^2);
          [px,py]=LOCAL_raw_flux(S.B*F(:,j,e));[pdx,~]=LOCAL_grad(px);[~,pdy]=LOCAL_grad(py);div=LOCAL_add(pdx,pdy);
          hf=(1+geo.eta_fitted(e))*geo.jacobian_norm(e);jf=(1+geo.eta_fitted(e))^2*geo.det_max(e);mf=(1-geo.eta_fitted(e))^2*geo.det_min(e);
          vn=max(Ubound([e,partner],j));ln=max(Lbound([e,partner],j));pn=hypot(LOCAL_norm(px),LOCAL_norm(py));
          vals.S_interface_coarse_upper=vals.S_interface_coarse_upper+.5/mf*((hf*pn+jf*ln/P.q)^2+(LOCAL_norm(div)+T.material(e)*(1-1/P.q)*vn*jf)^2/T.material(e));
        end
      end
    end
    writetable(struct2table(arcrows),fullfile(output_dir,[T.name,'-mass-arcs.csv']));
    writetable(table((1:nt).',geo.det_min,geo.det_max,geo.eta_native,geo.eta_fitted,aff,middef, ...
      'VariableNames',{'element','det_min','det_max','eta_native','eta_fitted','literal_affine','midpoint_defect'}),fullfile(output_dir,[T.name,'-geometry.csv']));
    vals.seconds=toc(tt);if t==1,templates=vals;else,templates(t)=vals;end
    Ec=Ec+vals.E_affine+vals.E_rational+vals.E_taper_value;Ee=Ee+vals.E_error+vals.E_taper_error;Mn=Mn+vals.M_native_exact+vals.M_taper_value;Mt=Mt+vals.M_taper_error;
    C0=C0+vals.C0;Cerr=Cerr+vals.C0_error;bias=bias+vals.mass_bias;
    Sc=Sc+vals.S_affine+vals.S_common_rational+vals.S_taper_value;Se=Se+vals.S_error+vals.S_taper_error;Siface=Siface+vals.S_interface_float;Srough=Srough+vals.S_interface_coarse_upper;eta2=eta2+vals.eta_s_squared;
    fprintf('CERT %s: eta native %.3g fitted %.3g Eerr %.3g M_bias %.3g Srough %.3g eta_s %.3g extfail %d (%.2fs)\n',T.name,geo.native_eta_max,geo.fitted_eta_max,vals.E_error,vals.mass_bias,vals.S_interface_coarse_upper,sqrt(vals.eta_s_squared),vals.inverse_extension_failures,vals.seconds);
    LOCAL_json(fullfile(output_dir,'certificate-progress.json'),struct('templates',templates));
  end
  Etop=0;report.templates=templates;
  report.E=[Ec-Ee,Ec+Ee+Etop];report.M=[Mn-Mt+C0-Cerr-bias-cfg.tolerances.mass_halfwidth,Mn+Mt+C0+Cerr+bias+cfg.tolerances.mass_halfwidth];
  report.S_smooth=[max(0,Sc-Se),Sc+Se+St];report.S_interface_floating=Siface;report.S_upper_coarse=Sc+Se+St+Srough;
  report.mass_correction=struct('C0',C0,'integration_error',Cerr,'voluntary_halfwidth',cfg.tolerances.mass_halfwidth,'bias',bias,...
    'band16',inventory.totals(1,3),'difference',C0-inventory.totals(1,3),'contains_band16',abs(C0-inventory.totals(1,3))<=bias+Cerr+cfg.tolerances.mass_halfwidth);
  report.S_extension=struct('eta_squared',eta2,'eta',sqrt(eta2),'allowed_eta',sqrt(inventory.totals(1,4))*(sqrt(1.005)-1), ...
    'inflation_if_S0_equals_float',(sqrt(inventory.totals(1,4))+sqrt(eta2))^2-inventory.totals(1,4), ...
    'inverse_extension_failures',sum([templates.inverse_extension_failures]),'S0_floating',true);
  report.corners_coarse=four_corners(report.E,report.M,report.S_upper_coarse,P.q,cfg);
  report.corners_partial=four_corners(report.E,report.M,report.S_smooth(2)+Siface,P.q,cfg);
  report.nominal=four_corners([P.energy,P.energy],[P.mass,P.mass],inventory.totals(1,4),P.q,cfg);
  report.E_contains_Q24=report.E(1)<=inventory.totals(2,1)&&report.E(2)>=inventory.totals(2,1);
  report.M_contains_Q24=report.M(1)<=sum(inventory.totals(2,2:3))&&report.M(2)>=sum(inventory.totals(2,2:3));
  report.seconds=toc(started);report.status='PARTIAL_INTERFACE_RESIDUAL';
  LOCAL_json(fullfile(output_dir,'certificates.json'),report);
end
function [affine,defect]=LOCAL_affine(T)
  % LOCAL_affine Affine.
  % Input
  %   T.
  % Output
  %   [affine,defect].
  nt=size(T.tri6,1);nodes=reshape(T.xy(T.tri6(:),:),nt,6,2);delta=nodes(:,4:6,:)-(nodes(:,[1,2,3],:)+nodes(:,[2,3,1],:))/2;defect=max(abs(delta),[],[2,3]);affine=defect==0;
end
function J=LOCAL_jac(G,e)
  % LOCAL_jac Jac.
  % Input
  %   G,e.
  % Output
  %   J.
  x=G.mx(e,:);y=G.my(e,:);J={ [x(2),x(5);2*x(4),0],[x(3),2*x(6);x(5),0], ...
    [y(2),y(5);2*y(4),0],[y(3),2*y(6);y(5),0]};
end
function d=LOCAL_det(J)
  % LOCAL_det Det.
  % Input
  %   J.
  % Output
  %   d.
  d=LOCAL_add(conv2(J{1},J{4}),-conv2(J{2},J{3}));
end
function U=LOCAL_fieldpoly(G,e,j)
  % LOCAL_fieldpoly Fieldpoly.
  % Input
  %   G,e,j.
  % Output
  %   U.
  c=G.field_coefficients(e,:,j);U=zeros(4);n=0;for d=0:3,for k=0:d,n=n+1;U(d-k+1,k+1)=c(n);end,end
end
function [x,y]=LOCAL_raw_flux(c)
  % LOCAL_raw_flux Raw flux.
  % Input
  %   c.
  % Output
  %   [x,y].
  x=zeros(5);y=x;n=0;for d=0:3,for k=0:d,n=n+1;x(d-k+1,k+1)=c(n);y(d-k+1,k+1)=c(10+n);end,end
  for k=0:3,x(5-k,k+1)=c(21+k);y(4-k,k+2)=c(21+k);end
end
function [x,y]=LOCAL_grad(a)
  % LOCAL_grad Grad.
  % Input
  %   a.
  % Output
  %   [x,y].
  x=zeros(max(1,size(a,1)-1),size(a,2));y=zeros(size(a,1),max(1,size(a,2)-1));
  for i=2:size(a,1),x(i-1,:)=(i-1)*a(i,:);end;for j=2:size(a,2),y(:,j-1)=(j-1)*a(:,j);end
end
function c=LOCAL_add(a,b)
  % LOCAL_add Add.
  % Input
  %   a,b.
  % Output
  %   c.
  c=zeros(max(size(a,1),size(b,1)),max(size(a,2),size(b,2)));c(1:size(a,1),1:size(a,2))=a;c(1:size(b,1),1:size(b,2))=c(1:size(b,1),1:size(b,2))+b;
end
function c=LOCAL_abs2(a)
  % LOCAL_abs2 Abs2.
  % Input
  %   a.
  % Output
  %   c.
  c=conv2(a,conj(a));
end
function n=LOCAL_norm(a)
  % LOCAL_norm Norm.
  % Input
  %   a.
  % Output
  %   n.
  n=sum(abs(real(a))+abs(imag(a)),'all');
end
function n=LOCAL_weight_norm(a,r)
  % LOCAL_weight_norm Weight norm.
  % Input
  %   a,r.
  % Output
  %   n.
  [i,j]=ndgrid(0:size(a,1)-1,0:size(a,2)-1);n=sum((abs(real(a))+abs(imag(a))).*r.^(i+j),'all');
end
function c=LOCAL_compose(a,x,y)
  % LOCAL_compose Compose.
  % Input
  %   a,x,y.
  % Output
  %   c.
  c=0;xp=1;
  for i=1:size(a,1)
    yp=1;for j=1:size(a,2),c=LOCAL_add(c,a(i,j)*conv2(xp,yp));yp=conv2(yp,y);end;xp=conv2(xp,x);
  end
end
function a=LOCAL_conj(a)
  % LOCAL_conj Conj.
  % Input
  %   a.
  % Output
  %   a.
  a.c=conj(a.c);
end
function a=LOCAL_scale(a,k)
  % LOCAL_scale Scale.
  % Input
  %   a,k.
  % Output
  %   a.
  a.c=a.c*k;a.e=a.e*abs(k);
end
function a=LOCAL_imag_model(a)
  % LOCAL_imag_model Imag model.
  % Input
  %   a.
  % Output
  %   a.
  a.c=imag(a.c);
end
function v=LOCAL_line_integral(c)
  % LOCAL_line_integral Line integral.
  % Input
  %   c.
  % Output
  %   v.
  w=1./(1:size(c,1));w(2:2:end)=0;v=w*c;
end
function ext=LOCAL_inverse_extension(G,T,e,cm)
  % LOCAL_inverse_extension Inverse extension.
  % Input
  %   G,T,e,cm.
  % Output
  %   ext.
  dl=[-1,-1;1,0;0,1];verts=T.xy(T.tri6(e,1:3),:);[~,a]=min(sum((verts-cm.p0).^2,2));[~,b]=min(sum((verts-cm.p1).^2,2));o=6-a-b;
  r=[.5;.5];t=[.5,.5];lambda=cell(1,3);lambda(:)={0};lambda{a}=conv2(r,[.5,-.5]);lambda{b}=conv2(r,t);lambda{o}=[.5;-.5];x=lambda{2};y=lambda{3};
  mx=G.mx(e,:);my=G.my(e,:);xcoef=[mx(1),mx(3),mx(6);mx(2),mx(5),0;mx(4),0,0];ycoef=[my(1),my(3),my(6);my(2),my(5),0;my(4),0,0];
  r3=conv2(conv2(r,r),r);gp=LOCAL_add(LOCAL_compose(xcoef+1i*ycoef,x,y),conv2(r3,cm.d.c.'));
  ext=LOCAL_inverse_box(mx,my,gp,cm.d.e,[1/3;1/3],1);ext.refined=false;
  if ~ext.pass
    % Finite cover of the parameter square; each small image has its own cube.
    % The original large cube has kappa<1, so overlapping roots are identical.
    global_unique=ext.kappa<1;ext.refined=true;ext.pass=global_unique;ext.margin=Inf;ext.kappa=0;ext.inverse_norm=0;
    for cr=-.75:.5:.75
      for ct=-.75:.5:.75
        zp=[cr;.25];zt=[ct,.25];xp=LOCAL_compose(x,zp,zt);yp=LOCAL_compose(y,zp,zt);gp2=LOCAL_compose(gp,zp,zt);
        bx=poly2('range',poly2('make',xp,0));by=poly2('range',poly2('make',yp,0));y0=[mean(bx);mean(by)];R=1.5*max([diff(bx),diff(by)])/2+.005;
        box=LOCAL_inverse_box(mx,my,gp2,cm.d.e,y0,R);
        inside=all(y0-R>=-2/3)&&all(y0+R<=4/3);
        ext.pass=ext.pass&&box.pass&&inside;ext.margin=min(ext.margin,box.margin);ext.kappa=max(ext.kappa,box.kappa);ext.inverse_norm=max(ext.inverse_norm,box.inverse_norm);
      end
    end
  end
end
function box=LOCAL_inverse_box(mx,my,gp,err,y0,R)
  % LOCAL_inverse_box Inverse box.
  % Input
  %   mx,my,gp,err,y0,R.
  % Output
  %   box.
  x=y0(1);y=y0(2);J0=[mx(2)+2*mx(4)*x+mx(5)*y,mx(3)+mx(5)*x+2*mx(6)*y;my(2)+2*my(4)*x+my(5)*y,my(3)+my(5)*x+2*my(6)*y];B=inv(J0);kappa=0;
  for z=[-1,-1;-1,1;1,-1;1,1].'
    q=y0+R*z;J=[mx(2)+2*mx(4)*q(1)+mx(5)*q(2),mx(3)+mx(5)*q(1)+2*mx(6)*q(2);my(2)+2*my(4)*q(1)+my(5)*q(2),my(3)+my(5)*q(1)+2*my(6)*q(2)];kappa=max(kappa,norm(eye(2)-B*J,Inf));
  end
  f0=[sum([1,x,y,x*x,x*y,y*y].*mx);sum([1,x,y,x*x,x*y,y*y].*my)];rhs=0;
  for j=1:2
    q=-B(j,1)*real(gp)-B(j,2)*imag(gp);q(1)=q(1)+B(j,:)*f0;
    rg=poly2('range',poly2('make',q,norm(B(j,:),1)*err));rhs=max(rhs,max(abs(rg)));
  end
  margin=(1-kappa)*R-rhs;box=struct('kappa',kappa,'margin',margin,'pass',kappa<1&&margin>=0,'inverse_norm',sqrt(2)*norm(B,Inf)/max(1-kappa,realmin));
end
function LOCAL_json(path,x)
  % LOCAL_json Json.
  % Input
  %   path,x.
  % Output
  %   No returned value; performs the stated check or output operation..
  f=fopen(path,'w');assert(f>=0);clean=onCleanup(@()fclose(f));fwrite(f,jsonencode(x,PrettyPrint=true));
end
