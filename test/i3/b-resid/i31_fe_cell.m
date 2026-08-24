function out = i31_fe_cell(action,c,node,varargin)
%I31_FE_CELL Build the I3.1 Q1 companion and RT0 majorant.
% Purpose:
%   Convert qualified BIE trace and safe-target data into one conforming Q1
%   field, then assemble the sharp-material RT0 functional majorant.
% Input:
%   action - 'level' builds one collar Q1 map; 'majorant' builds its Grams.
% Output:
%   out    - Q1 reconstruction data or one level's majorant diagnostics.
% Main algorithm:
%   Impose common circle/wall traces, restore the periodic gauge, minimize
%   the constrained RT0 flux, integrate true-circle contrast, and partition
%   correction-support N/A/B energy before full-P contraction by the entry.
% Based on:
%   test/i3/w-resid/i31_fe_cell.m and
%   research/projects/eig-apost/implementation/i3/design-3-1d.md.
% Main changes:
%   Uses qualified BIE safe data instead of a cell-extension solve.
% Numerical goal:
%   Return ordinary-double conforming-cell Grams, not a reliable enclosure.

  action=lower(char(action));
  if strcmp(action,'level')
    out=LOCAL_level(c,node,varargin{1},varargin{2},varargin{3},varargin{4});
  elseif strcmp(action,'majorant')
    out=LOCAL_majorant(c,node,varargin{1},varargin{2},varargin{3},varargin{4});
  else
    error('i31b:Execution','Unknown i31_fe_cell action.');
  end
end

%% ==================== Q1 collar maps ====================
% These helpers never call a direct layer potential inside the fixed collars.

function out=LOCAL_level(c,node,safe,prop,coords,level)
  mesh=LOCAL_mesh(level); plus=LOCAL_lead_map(c,node,safe,safe.safe.plus, ...
    prop.Dplus,prop.Dplus*prop.Pplus,mesh);
  minus=LOCAL_lead_map(c,node,safe,safe.safe.minus, ...
    prop.Dminus*prop.Pminus,prop.Dminus,mesh);
  center=LOCAL_center_map(c,node,coords,prop,mesh);
  finite=all(isfinite([plus.U(:);minus.U(:);center.U(:)]));
  nonzero=norm(center.U)>0&&norm(plus.U*coords.cplus)>0&& ...
    norm(minus.U*coords.cminus)>0;
  maps=struct('mesh',mesh,'plus',plus,'minus',minus,'center',center);
  form=LOCAL_form_defects(mesh,maps,prop,coords,c);
  info=whos;
  out=maps;
  out.record=struct('pass',finite&&nonzero&&form.pass,'finite',finite, ...
    'nonzero',nonzero,'form',form, ...
    'circle_collar',c.delta_c,'wall_collar',c.delta_w, ...
    'q1_nodes',mesh.nnode,'circle_wall_gap',0.22, ...
    'collar_nodal_amplitude_diagnostics',[plus.collar_amplitude_share, ...
    minus.collar_amplitude_share,center.collar_amplitude_share, ...
    center.wall_correction_ratio], ...
    'nodal_amplitude_diagnostics_are_energy',false);
  out.peak_local_workspace_mib=sum([info.bytes])/2^20;
end

function out=LOCAL_lead_map(c,node,root,work,dL,dR,mesh)
  x=mesh.xnode; y=mesh.ynode; r=hypot(x,y); theta=mod(atan2(y,x),2*pi);
  U=complex(zeros(mesh.nnode,c.K)); filled=false(mesh.nnode,1);
  direct=(r<=c.R-c.delta_c)|(r>=c.R+c.delta_c& ...
    abs(x)<=.5-c.delta_w);
  if any(direct)
    U(direct,:)=i31_bie_cell('sample',c,node,root,work.eta,work.incoming, ...
      [x(direct).';y(direct).']); filled(direct)=true;
  end
  inner=r>c.R-c.delta_c&r<c.R; outer=r>=c.R&r<c.R+c.delta_c;
  if any(inner)
    t=(r(inner)-(c.R-c.delta_c))/c.delta_c; h=LOCAL_smooth(t);
    a=LOCAL_trig(work.ring_inner,theta(inner)); g=LOCAL_trig(work.common,theta(inner));
    U(inner,:)=(1-h).*a+h.*g; filled(inner)=true;
  end
  if any(outer)
    t=(r(outer)-c.R)/c.delta_c; h=LOCAL_smooth(t);
    g=LOCAL_trig(work.common,theta(outer)); a=LOCAL_trig(work.ring_outer,theta(outer));
    U(outer,:)=(1-h).*g+h.*a; filled(outer)=true;
  end
  left=x<-.5+c.delta_w; right=x>.5-c.delta_w;
  if any(left)
    t=(x(left)+.5)/c.delta_w; h=LOCAL_smooth(t);
    d=LOCAL_fourier(node,dL,y(left),c); a=LOCAL_trig_y(work.wall_left,y(left));
    U(left,:)=(1-h).*d+h.*a; filled(left)=true;
  end
  if any(right)
    t=(.5-x(right))/c.delta_w; h=LOCAL_smooth(t);
    d=LOCAL_fourier(node,dR,y(right),c); a=LOCAL_trig_y(work.wall_right,y(right));
    U(right,:)=(1-h).*d+h.*a; filled(right)=true;
  end
  if ~all(filled), error('i31b:FormConformity','Some lead Q1 nodes were not assigned.'); end
  gauge=exp(-1i*c.beta*y); Ug=U.*gauge;
  collar_amplitude_share=norm(U(left|right|inner|outer),'fro')/max(1,norm(U,'fro'));
  out=struct('U',Ug,'wall_left',Ug(mesh.left,:), ...
    'wall_right',Ug(mesh.right,:),'collar_amplitude_share',collar_amplitude_share);
end

function out=LOCAL_center_map(c,node,coords,prop,mesh)
  T=[mesh.xnode.';mesh.ynode.']; raw=LOCAL_center_raw(c,node,coords.q,T);
  U=raw; left=mesh.xnode<-.5+c.delta_w; right=mesh.xnode>.5-c.delta_w;
  if any(left)
    t=(mesh.xnode(left)+.5)/c.delta_w; h=LOCAL_smooth(t);
    d=LOCAL_fourier(node,prop.Dminus*coords.cminus,mesh.ynode(left),c);
    Tsafe=[(-.5+c.delta_w)*ones(1,sum(left));mesh.ynode(left).'];
    a=LOCAL_center_raw(c,node,coords.q,Tsafe); U(left)=(1-h).*d+h.*a;
  end
  if any(right)
    t=(.5-mesh.xnode(right))/c.delta_w; h=LOCAL_smooth(t);
    d=LOCAL_fourier(node,prop.Dplus*coords.cplus,mesh.ynode(right),c);
    Tsafe=[(.5-c.delta_w)*ones(1,sum(right));mesh.ynode(right).'];
    a=LOCAL_center_raw(c,node,coords.q,Tsafe); U(right)=(1-h).*d+h.*a;
  end
  Ug=U.*exp(-1i*c.beta*mesh.ynode);
  out=struct('U',Ug,'wall_left',Ug(mesh.left), ...
    'wall_right',Ug(mesh.right),'collar_amplitude_share', ...
    norm(U(left|right))/max(1,norm(U)), ...
    'wall_correction_ratio',norm(U-raw)/max(1,norm(U)));
end

function mesh=LOCAL_mesh(level)
  y=-.5+(0:level.Ny-1)'/level.Ny; x=linspace(-.5,.5,level.Nx+1).';
  ids=reshape(1:(level.Nx+1)*level.Ny,level.Ny,level.Nx+1).';
  elem=zeros(level.Nx*level.Ny,4);
  for ex=1:level.Nx
    for ey=1:level.Ny
      row=(ex-1)*level.Ny+ey; ey2=mod(ey,level.Ny)+1;
      elem(row,:)=[ids(ex,ey),ids(ex+1,ey),ids(ex+1,ey2),ids(ex,ey2)];
    end
  end
  [xx,yy]=ndgrid(x,y); mesh=struct('Nx',level.Nx,'Ny',level.Ny, ...
    'hx',1/level.Nx,'hy',1/level.Ny,'x',x,'y',y,'ids',ids, ...
    'elem',elem,'xnode',reshape(xx.',[],1), ...
    'ynode',reshape(yy.',[],1),'nnode',numel(xx), ...
    'left',ids(1,:).','right',ids(end,:).');
end

function h=LOCAL_smooth(t)
  h=3*t.^2-2*t.^3;
end

function values=LOCAL_trig(samples,theta)
  N=size(samples,1); modes=[0:N/2-1,-N/2:-1]; coeff=fft(samples,[],1)/N;
  values=exp(1i*theta(:)*modes)*coeff;
end

function values=LOCAL_trig_y(samples,y)
  N=size(samples,1); theta=2*pi*(y(:)+.5); values=LOCAL_trig(samples,theta);
end


function value=LOCAL_center_raw(c,node,q,T)
  qL=q(1:c.K,:); qR=q(c.K+1:end,:);
  psi=exp(1i*T(2,:).'*node.beta_m(:).')/sqrt(c.d);
  er=exp(1i*(T(1,:).'-c.X_L)*node.gamma(:).');
  el=exp(-1i*(T(1,:).'-c.X_R)*node.gamma(:).');
  value=(psi.*er)*qL+(psi.*el)*qR;
end

function value=LOCAL_fourier(node,coeff,y,c)
  value=exp(1i*y(:)*node.beta_m(:).')/sqrt(c.d)*coeff;
end

function out = LOCAL_majorant(c,node,prop,coords,maps,level)
%I31_MAJORANT Assemble the Q1--RT0 functional majorant for one level.
% Purpose:
%   Convert the BIE-collar Q1 companion into sharp-material field and
%   residual Grams using one globally normal-continuous RT0 flux.
% Input:
%   c,node,prop,coords - Frozen numerical objects from check_b_resid.
%   maps              - One Q1 companion level from this helper.
%   level             - Frozen mesh and polar-quadrature dimensions.
% Output:
%   out               - Small center/first/tail objects and gate records.
% Main algorithm:
%   Assemble periodic Q1 and RT0 forms, impose exact Fourier edge-average
%   wall fluxes, minimize the fixed functional majorant over all free RT0
%   edges, and integrate the disk contrast in true polar geometry.
% Based on:
%   test/i3/w-resid/i31_fe_cell.m.
% Main changes:
%   Replaces physical Helmholtz cell solves and averaged Q1 gradients by the
%   reviewed BIE-collar field and prescribed QZ global-x wall fluxes.
% Numerical goal:
%   Return ordinary-double majorant Grams, not an outward enclosure.

  mesh=LOCAL_fe_mesh(level,c); [lead,center]=LOCAL_operators(mesh,c,level);
  lead_factor=LOCAL_flux_factor(lead,c); center_factor=LOCAL_flux_factor(center,c);
  ep=LOCAL_edge_average(prop.Gplus,node,c,mesh);
  em=LOCAL_edge_average(prop.Gminus,node,c,mesh);
  pc=LOCAL_cell_grams(center,center_factor,maps.center.U, ...
    em*coords.cminus,ep*coords.cplus,c);
  pp=LOCAL_cell_grams(lead,lead_factor,maps.plus.U,ep,ep*prop.Pplus,c);
  pm=LOCAL_cell_grams(lead,lead_factor,maps.minus.U, ...
    em*prop.Pminus,em,c);
  form=LOCAL_form_defects(mesh,maps,prop,coords,c);
  hdiv=LOCAL_hdiv_defects(pc,pp,pm,prop,coords,c);
  records=[pc.record,pp.record,pm.record]; gram_pass=all([records.pass]);
  integration_pass=lead.record.disk_object_pass&&center.record.disk_object_pass;
  finite_pass=all(isfinite([pc.N,pc.A,pc.B]))&& ...
    all(isfinite(pp.N),'all')&&all(isfinite(pp.A),'all')&& ...
    all(isfinite(pp.B),'all')&&all(isfinite(pm.N),'all')&& ...
    all(isfinite(pm.A),'all')&&all(isfinite(pm.B),'all');
  cm=coords.cminus; cp=coords.cplus;
  first=struct('minus',LOCAL_contract(pm,cm), ...
    'plus',LOCAL_contract(pp,cp));
  center_value=LOCAL_contract(pc,1);
  factor=struct('lead',lead_factor.record,'center',center_factor.record, ...
    'center_solve',pc.solve,'plus_solve',pp.solve,'minus_solve',pm.solve);
  factor.pass=all([factor.lead.pass,factor.center.pass, ...
    factor.center_solve.pass,factor.plus_solve.pass,factor.minus_solve.pass]);
  audit=LOCAL_audit(mesh,maps,pc,pp,pm,prop,coords);
  correction=struct('center',center_value.correction_support_energy, ...
    'first_minus',first.minus.correction_support_energy, ...
    'first_plus',first.plus.correction_support_energy, ...
    'all_collar_corrections_included_in_full_NAB',true, ...
    'tail_uses_full_partitioned_NAB_grams',true);
  info=whos;
  out=struct('level',level,'factor',factor, ...
    'integration',struct('lead',lead.record,'center',center.record), ...
    'form',form,'hdiv',hdiv,'integration_pass',integration_pass, ...
    'gram_pass',gram_pass, ...
    'finite_pass',finite_pass,'center',center_value, ...
    'first',first,'correction_energy',correction, ...
    'tail',struct('minus',LOCAL_gram_only(pm), ...
    'plus',LOCAL_gram_only(pp)),'audit',audit, ...
    'peak_local_workspace_mib',sum([info.bytes])/2^20);
end

%% ==================== Structured Q1--RT0 forms ====================
% One periodic mesh supplies field nodes and globally oriented RT0 edges.

function mesh=LOCAL_fe_mesh(level,c)
  Nx=level.Nx; Ny=level.Ny; hx=1/Nx; hy=1/Ny;
  y=-.5+(0:Ny-1)'*hy; x=linspace(-.5,.5,Nx+1).';
  ids=reshape(1:(Nx+1)*Ny,Ny,Nx+1).';
  elem=zeros(Nx*Ny,4); pedge=zeros(Nx*Ny,4); nv=(Nx+1)*Ny;
  for ex=1:Nx
    for ey=1:Ny
      row=(ex-1)*Ny+ey; ey2=mod(ey,Ny)+1;
      elem(row,:)=[ids(ex,ey),ids(ex+1,ey),ids(ex+1,ey2),ids(ex,ey2)];
      pedge(row,:)=[(ex-1)*Ny+ey,ex*Ny+ey, ...
        nv+(ex-1)*Ny+ey,nv+(ex-1)*Ny+ey2];
    end
  end
  [xx,yy]=ndgrid(x,y); xnode=reshape(xx.',[],1); ynode=reshape(yy.',[],1);
  circle_node=abs(hypot(xnode,ynode)-c.R)<c.delta_c;
  wall_node=xnode<c.X_L+c.delta_w|xnode>c.X_R-c.delta_w;
  circle_elem=any(circle_node(elem),2); wall_elem=any(wall_node(elem),2);
  if any(circle_elem&wall_elem)
    error('i31b:FormConformity','Circle and wall correction supports overlap.');
  end
  lead_region=3*ones(Nx*Ny,1); lead_region(circle_elem)=1;
  lead_region(wall_elem)=2;
  center_region=3*ones(Nx*Ny,1); center_region(wall_elem)=2;
  mesh=struct('Nx',Nx,'Ny',Ny,'hx',hx,'hy',hy,'y',y,'ids',ids, ...
    'elem',elem,'pedge',pedge,'nelem',Nx*Ny,'nnode',(Nx+1)*Ny, ...
    'nvedge',nv,'nedge',nv+Nx*Ny,'left',ids(1,:).','right',ids(end,:).', ...
    'lead_region',lead_region,'center_region',center_region);
end

function [lead,center]=LOCAL_operators(mesh,c,level)
  [Kloc,Mloc,Aloc,Bloc]=LOCAL_background_local(mesh,c);
  K=LOCAL_repeat_sparse(mesh.elem,Kloc,mesh.nnode);
  M0=LOCAL_repeat_sparse(mesh.elem,Mloc,mesh.nnode);
  zdofs=[mesh.elem,mesh.nnode+mesh.pedge];
  LA=LOCAL_repeat_sparse(zdofs,Aloc,mesh.nnode+mesh.nedge);
  LB0=LOCAL_repeat_sparse(zdofs,Bloc,mesh.nnode+mesh.nedge);
  K=(K+K')/2; M0=(M0+M0')/2; LA=(LA+LA')/2; LB0=(LB0+LB0')/2;
  [Mdisk,Bdisk,area,Mdisk_region,Bdisk_region]= ...
    LOCAL_disk_correction(mesh,c,level);
  M1=(M0+(c.rho_disk-1)*Mdisk); M1=(M1+M1')/2;
  LB1=LB0+Bdisk; LB1=(LB1+LB1')/2;
  area_defect=abs(area-pi*c.R^2)/max(realmin,pi*c.R^2);
  base=all(isfinite(nonzeros(K)))&&all(isfinite(nonzeros(M0)))&& ...
    all(isfinite(nonzeros(LA)))&&all(isfinite(nonzeros(LB0)));
  leadfinite=base&&all(isfinite(nonzeros(M1)))&&all(isfinite(nonzeros(LB1)));
  region_names={'circle_correction_support','wall_correction_support', ...
    'unmodified_support'};
  common_region=struct('names',{region_names},'Kloc',Kloc,'Mloc',Mloc, ...
    'Aloc',Aloc,'Bloc',Bloc);
  center_region=common_region; center_region.element_region=mesh.center_region;
  center_region.Mdisk={sparse(mesh.nnode,mesh.nnode), ...
    sparse(mesh.nnode,mesh.nnode)};
  nz=mesh.nnode+mesh.nedge;
  center_region.Bdisk={sparse(nz,nz),sparse(nz,nz)};
  lead_region=common_region; lead_region.element_region=mesh.lead_region;
  lead_region.Mdisk=Mdisk_region(1:2); lead_region.Bdisk=Bdisk_region(1:2);
  center=struct('mesh',mesh,'V',K+c.gamma*M0,'LA',LA,'LB',LB0, ...
    'region_data',center_region, ...
    'record',struct('has_disk',false,'disk_quadrature_area',0, ...
    'disk_area_relative_defect',0,'disk_object_pass',base));
  lead=struct('mesh',mesh,'V',K+c.gamma*M1,'LA',LA,'LB',LB1, ...
    'region_data',lead_region, ...
    'record',struct('has_disk',true,'disk_quadrature_area',area, ...
    'disk_area_relative_defect',area_defect, ...
    'disk_object_pass',leadfinite&&area_defect<=c.disk_area_tol));
end

function [K,M,LA,LB]=LOCAL_region_forms(mesh,take,Kloc,Mloc,Aloc,Bloc)
  K=LOCAL_repeat_sparse(mesh.elem(take,:),Kloc,mesh.nnode);
  M=LOCAL_repeat_sparse(mesh.elem(take,:),Mloc,mesh.nnode);
  zdofs=[mesh.elem(take,:),mesh.nnode+mesh.pedge(take,:)];
  LA=LOCAL_repeat_sparse(zdofs,Aloc,mesh.nnode+mesh.nedge);
  LB=LOCAL_repeat_sparse(zdofs,Bloc,mesh.nnode+mesh.nedge);
end

function [K,M,LA,LB]=LOCAL_background_local(mesh,c)
  z=[-1,1]/sqrt(3); jac=mesh.hx*mesh.hy/4;
  K=complex(zeros(4)); M=zeros(4); LA=complex(zeros(8)); LB=complex(zeros(8));
  for a=1:2
    for b=1:2
      [N,dx,dy,P,D]=LOCAL_shapes(z(a),z(b),mesh,c.beta);
      G=[dx;dy+1i*c.beta*N]; K=K+jac*(G'*G); M=M+jac*(N'*N);
      Q=[G,-P]; LA=LA+jac*(Q'*Q); T=[c.mu_h*N,D]; LB=LB+jac*(T'*T);
    end
  end
end

function S=LOCAL_repeat_sparse(dofs,L,n)
  ne=size(dofs,1); m=size(dofs,2); count=ne*m*m;
  I=zeros(count,1); J=I; V=complex(I); pos=0;
  for a=1:m
    for b=1:m
      take=pos+(1:ne); I(take)=dofs(:,a); J(take)=dofs(:,b);
      V(take)=L(a,b); pos=pos+ne;
    end
  end
  S=sparse(I,J,V,n,n);
end

function [Mdisk,Bdisk,area,Mregion,Bregion]=LOCAL_disk_correction(mesh,c,level)
  [r,wr]=LOCAL_gauss(level.Nr,0,c.R);
  theta=(0:level.Ntheta-1)*(2*pi/level.Ntheta); np=level.Nr*level.Ntheta;
  Im=zeros(16*np,1); Jm=Im; Vm=complex(Im); Rm=Im;
  Ib=zeros(64*np,1); Jb=Ib; Vb=complex(Ib); Rb=Ib;
  pm=0; pb=0; area=0;
  for ir=1:level.Nr
    for it=1:level.Ntheta
      x=r(ir)*cos(theta(it)); y=r(ir)*sin(theta(it));
      weight=wr(ir)*r(ir)*(2*pi/level.Ntheta);
      [row,xi,eta]=LOCAL_locate(mesh,x,y);
      [N,~,~,~,D]=LOCAL_shapes(xi,eta,mesh,c.beta);
      nodes=mesh.elem(row,:); zd=[nodes,mesh.nnode+mesh.pedge(row,:)];
      Lm=weight*(N'*N); Tout=[c.mu_h*N,D];
      Tin=[c.mu_h*c.rho_disk*N,D];
      Lb=weight*((Tin'*Tin)/c.rho_disk-Tout'*Tout);
      for a=1:4
        for b=1:4, pm=pm+1; Im(pm)=nodes(a); Jm(pm)=nodes(b); ...
            Vm(pm)=Lm(a,b); Rm(pm)=mesh.lead_region(row); end
      end
      for a=1:8
        for b=1:8, pb=pb+1; Ib(pb)=zd(a); Jb(pb)=zd(b); ...
            Vb(pb)=Lb(a,b); Rb(pb)=mesh.lead_region(row); end
      end
      area=area+weight;
    end
  end
  Mdisk=sparse(Im,Jm,Vm,mesh.nnode,mesh.nnode);
  n=mesh.nnode+mesh.nedge; Bdisk=sparse(Ib,Jb,Vb,n,n);
  Mregion=cell(1,3); Bregion=cell(1,3);
  for j=1:3
    m=Rm==j; b=Rb==j;
    Mregion{j}=sparse(Im(m),Jm(m),Vm(m),mesh.nnode,mesh.nnode);
    Bregion{j}=sparse(Ib(b),Jb(b),Vb(b),n,n);
  end
end

function [row,xi,eta]=LOCAL_locate(mesh,x,y)
  ex=min(mesh.Nx,max(1,floor((x+.5)/mesh.hx)+1));
  ey=min(mesh.Ny,max(1,floor((y+.5)/mesh.hy)+1));
  x0=-.5+(ex-1)*mesh.hx; y0=-.5+(ey-1)*mesh.hy;
  xi=2*(x-x0)/mesh.hx-1; eta=2*(y-y0)/mesh.hy-1;
  row=(ex-1)*mesh.Ny+ey;
end

function [N,dx,dy,P,D]=LOCAL_shapes(xi,eta,mesh,beta)
  N=.25*[(1-xi)*(1-eta),(1+xi)*(1-eta),(1+xi)*(1+eta),(1-xi)*(1+eta)];
  dxi=.25*[-(1-eta),(1-eta),(1+eta),-(1+eta)];
  deta=.25*[-(1-xi),-(1+xi),(1+xi),(1-xi)];
  dx=(2/mesh.hx)*dxi; dy=(2/mesh.hy)*deta;
  P=[.5*(1-xi),.5*(1+xi),0,0;0,0,.5*(1-eta),.5*(1+eta)];
  D=[-1/mesh.hx,1/mesh.hx,-1/mesh.hy,1/mesh.hy]+ ...
    1i*beta*[0,0,.5*(1-eta),.5*(1+eta)];
end

%% ==================== Constrained RT0 minimization ====================
% QZ wall coefficients become exact periodic-gauge RT0 edge averages.

function edge=LOCAL_edge_average(coeff,node,c,mesh)
  m=(-c.M:c.M); y0=mesh.y; y1=y0+mesh.hy;
  W=complex(zeros(mesh.Ny,c.K)); W(:,m==0)=1/sqrt(c.d);
  nz=find(m~=0);
  for j=nz
    mm=m(j);
    W(:,j)=c.d/(2*pi*1i*mm*mesh.hy*sqrt(c.d))* ...
      (exp(2*pi*1i*mm*y1/c.d)-exp(2*pi*1i*mm*y0/c.d));
  end
  edge=W*coeff;
end

function fac=LOCAL_flux_factor(fem,c)
  n=fem.mesh.nedge; L=fem.LA+fem.LB/c.gamma;
  pp=L(fem.mesh.nnode+(1:n),fem.mesh.nnode+(1:n));
  fixed=[(1:fem.mesh.Ny),fem.mesh.Nx*fem.mesh.Ny+(1:fem.mesh.Ny)];
  free=setdiff((1:n).',fixed,'stable'); Lff=pp(free,free);
  diagonal=real(diag(Lff));
  if any(~isfinite(diagonal))||any(diagonal<=0)
    error('i31b:HdivFlux','The RT0 scaling diagonal is unavailable.');
  end
  S=spdiags(1./sqrt(diagonal),0,numel(free),numel(free)); Ls=S*Lff*S;
  try, rc=1/condest(Ls); catch ME
    error('i31b:HdivFlux','RT0 condition estimate failed: %s',ME.message); end
  if ~isfinite(rc)||rc<c.flux_rcond_min
    error('i31b:HdivFlux','The constrained RT0 factor is ill-conditioned.');
  end
  try, solver=decomposition(Ls,'lu'); catch ME
    error('i31b:HdivFlux','RT0 factorization failed: %s',ME.message); end
  fac=struct('L',L,'pp',pp,'free',free,'fixed',fixed,'S',S,'Ls',Ls, ...
    'Ls_norm_one',norm(Ls,1),'solver',solver,'record',struct( ...
    'pass',true,'scaled_rcond_estimate',rc,'free_edges',numel(free), ...
    'fixed_wall_edges',numel(fixed)));
end

function out=LOCAL_cell_grams(fem,fac,U,left,right,c)
  r=size(U,2); pb=[left;right]; p=complex(zeros(fem.mesh.nedge,r));
  p(fac.fixed,:)=pb;
  Lpu=fac.L(fem.mesh.nnode+(1:fem.mesh.nedge),1:fem.mesh.nnode);
  rhs=-(Lpu(fac.free,:)*U+fac.pp(fac.free,fac.fixed)*pb);
  scaled=fac.S*rhs;
  try, y=fac.solver\scaled; catch ME
    error('i31b:HdivFlux','RT0 solve failed: %s',ME.message); end
  p(fac.free,:)=fac.S*y; residual=fac.Ls*y-scaled;
  relative=zeros(1,r); backward=relative;
  for j=1:r
    relative(j)=norm(residual(:,j),1)/max(realmin,norm(scaled(:,j),1));
    backward(j)=norm(residual(:,j),1)/max(realmin, ...
      fac.Ls_norm_one*norm(y(:,j),1)+norm(scaled(:,j),1));
  end
  solve=struct('max_rhs_relative_residual',max(relative), ...
    'max_rhs_backward_error',max(backward),'pass', ...
    all(isfinite([relative,backward]))&&max([relative,backward])<= ...
    c.flux_solve_residual_max);
  Z=[U;p]; Nraw=U'*(fem.V*U); Araw=Z'*(fem.LA*Z); Braw=Z'*(fem.LB*Z);
  record=LOCAL_gram_record(Nraw,Araw,Braw,c);
  regions=LOCAL_region_grams(fem,U,Z,Nraw,Araw,Braw,c);
  Nsum=regions{1}.N+regions{2}.N+regions{3}.N;
  Asum=regions{1}.A+regions{2}.A+regions{3}.A;
  Bsum=regions{1}.B+regions{2}.B+regions{3}.B;
  partition=[LOCAL_fe_relative(Nsum,Nraw),LOCAL_fe_relative(Asum,Araw), ...
    LOCAL_fe_relative(Bsum,Braw)];
  record.region_partition_defects=partition;
  record.region_partition_pass=all(isfinite(partition))&& ...
    max(partition)<=c.gram_hermitian_max;
  record.pass=record.pass&&record.region_partition_pass;
  continuity=LOCAL_rt0_continuity(fem.mesh,p,c.beta);
  record.rt0_internal_normal_defect=continuity.internal_defect;
  record.periodic_flux_gauge_defect=continuity.periodic_gauge_defect;
  record.periodic_flux_physical_defect=continuity.periodic_physical_defect;
  out=struct('N',(Nraw+Nraw')/2,'A',(Araw+Araw')/2, ...
    'B',(Braw+Braw')/2,'flux',struct('left',left,'right',right), ...
    'regions',{regions},'solve',solve,'record',record);
end

function regions=LOCAL_region_grams(fem,U,Z,Nall,Aall,Ball,c)
  data=fem.region_data; regions=cell(1,3);
  sums={complex(zeros(size(Nall))),complex(zeros(size(Aall))), ...
    complex(zeros(size(Ball)))};
  for j=1:2
    [K,M,LA,LB]=LOCAL_region_forms(fem.mesh,data.element_region==j, ...
      data.Kloc,data.Mloc,data.Aloc,data.Bloc);
    V=K+c.gamma*(M+(c.rho_disk-1)*data.Mdisk{j});
    LB=LB+data.Bdisk{j};
    raw={U'*(V*U),Z'*(LA*Z),Z'*(LB*Z)};
    regions{j}=struct('name',data.names{j},'N',(raw{1}+raw{1}')/2, ...
      'A',(raw{2}+raw{2}')/2,'B',(raw{3}+raw{3}')/2);
    for k=1:3, sums{k}=sums{k}+raw{k}; end
  end
  raw={Nall-sums{1},Aall-sums{2},Ball-sums{3}};
  regions{3}=struct('name',data.names{3},'N',(raw{1}+raw{1}')/2, ...
    'A',(raw{2}+raw{2}')/2,'B',(raw{3}+raw{3}')/2);
end

function record=LOCAL_gram_record(N,A,B,c)
  mats={N,A,B}; hermitian=zeros(1,3); minimum=zeros(1,3); scale=zeros(1,3);
  finite=true;
  for j=1:3
    G=mats{j};
    if any(~isfinite(G),'all')
      finite=false; hermitian(j)=Inf; minimum(j)=NaN; scale(j)=Inf;
      continue;
    end
    H=(G+G')/2; scale(j)=max(1,norm(G,2));
    hermitian(j)=norm(G-G','fro')/max(1,norm(G,'fro'));
    minimum(j)=min(real(eig(full(H))));
    finite=finite&&isfinite(minimum(j));
  end
  record=struct('names',{{'N','A','B'}},'hermitian_defects',hermitian, ...
    'minimum_eigenvalues',minimum,'matrix_scales',scale,'finite',finite, ...
    'pass',finite&&all(hermitian<=c.gram_hermitian_max)&& ...
    all(minimum>=-c.gram_psd_scale*scale));
end

%% ==================== Conformity and audit ====================
% Adjacent element traces are reconstructed independently from local maps.

function out=LOCAL_form_defects(mesh,maps,prop,coords,c)
  cp=coords.cplus; cm=coords.cminus;
  defects=[LOCAL_fe_relative(maps.center.wall_left,maps.minus.wall_right*cm), ...
    LOCAL_fe_relative(maps.center.wall_right,maps.plus.wall_left*cp), ...
    LOCAL_fe_relative(maps.plus.wall_right*cp,maps.plus.wall_left*(prop.Pplus*cp)), ...
    LOCAL_fe_relative(maps.minus.wall_left*cm,maps.minus.wall_right*(prop.Pminus*cm)), ...
    LOCAL_fe_relative(maps.plus.wall_right,maps.plus.wall_left*prop.Pplus), ...
    LOCAL_fe_relative(maps.minus.wall_left,maps.minus.wall_right*prop.Pminus)];
  periodic=[LOCAL_periodic_field(mesh,maps.center.U,c.beta), ...
    LOCAL_periodic_field(mesh,maps.plus.U,c.beta), ...
    LOCAL_periodic_field(mesh,maps.minus.U,c.beta)];
  gauge=max([periodic.gauge_defect]); physical=max([periodic.physical_defect]);
  maximum=max([defects,gauge,physical,0]);
  out=struct('wall_defects',defects,'periodic_gauge_defect',gauge, ...
    'physical_quasiperiodic_defect',physical,'maximum_defect',maximum, ...
    'pass',all(isfinite([defects,gauge,physical]))&&maximum<=c.form_defect_max);
end

function out=LOCAL_hdiv_defects(center,plus,minus,prop,coords,c)
  cp=coords.cplus; cm=coords.cminus;
  defects=[LOCAL_fe_relative(center.flux.left,minus.flux.right*cm), ...
    LOCAL_fe_relative(center.flux.right,plus.flux.left*cp), ...
    LOCAL_fe_relative(plus.flux.right*cp,plus.flux.left*(prop.Pplus*cp)), ...
    LOCAL_fe_relative(minus.flux.left*cm,minus.flux.right*(prop.Pminus*cm)), ...
    LOCAL_fe_relative(plus.flux.right,plus.flux.left*prop.Pplus), ...
    LOCAL_fe_relative(minus.flux.left,minus.flux.right*prop.Pminus)];
  records=[center.record,plus.record,minus.record];
  internal=[records.rt0_internal_normal_defect];
  periodic=[records.periodic_flux_gauge_defect];
  physical=[records.periodic_flux_physical_defect];
  maximum=max([defects,internal,periodic,physical,0]);
  out=struct('global_orientation','vertical:+x;horizontal:+y', ...
    'fourier_to_edge_map','exact periodic-gauge edge average', ...
    'interface_defects',defects,'local_rt0_internal_defects',internal, ...
    'periodic_gauge_defects',periodic,'physical_quasiperiodic_defects',physical, ...
    'maximum_defect',maximum,'pass',all(isfinite([defects,internal,periodic,physical]))&& ...
    maximum<=c.hdiv_defect_max);
end

function out=LOCAL_periodic_field(mesh,U,beta)
  top=complex(zeros(3*mesh.Nx,size(U,2))); bottom=top; p=0; xi=[-1,0,1];
  for ex=1:mesh.Nx
    rt=(ex-1)*mesh.Ny+mesh.Ny; rb=(ex-1)*mesh.Ny+1;
    for j=1:3
      p=p+1; [Nt,~,~,~,~]=LOCAL_shapes(xi(j),1,mesh,beta);
      [Nb,~,~,~,~]=LOCAL_shapes(xi(j),-1,mesh,beta);
      top(p,:)=Nt*U(mesh.elem(rt,:),:); bottom(p,:)=Nb*U(mesh.elem(rb,:),:);
    end
  end
  out=struct('gauge_defect',LOCAL_fe_relative(top,bottom), ...
    'physical_defect',LOCAL_fe_relative(exp(1i*beta/2)*top, ...
    exp(1i*beta)*exp(-1i*beta/2)*bottom));
end

function out=LOCAL_rt0_continuity(mesh,p,beta)
  [~,~,~,Pr,~]=LOCAL_shapes(1,0,mesh,beta);
  [~,~,~,Pl,~]=LOCAL_shapes(-1,0,mesh,beta);
  [~,~,~,Pt,~]=LOCAL_shapes(0,1,mesh,beta);
  [~,~,~,Pb,~]=LOCAL_shapes(0,-1,mesh,beta);
  vd=0; va=0; vb=0;
  for ex=1:mesh.Nx-1
    for ey=1:mesh.Ny
      a=Pr(1,:)*p(mesh.pedge((ex-1)*mesh.Ny+ey,:),:);
      b=Pl(1,:)*p(mesh.pedge(ex*mesh.Ny+ey,:),:);
      vd=vd+sum(abs(a-b).^2); va=va+sum(abs(a).^2); vb=vb+sum(abs(b).^2);
    end
  end
  hd=0; ha=0; hb=0;
  for ex=1:mesh.Nx
    for ey=2:mesh.Ny
      a=Pt(2,:)*p(mesh.pedge((ex-1)*mesh.Ny+ey-1,:),:);
      b=Pb(2,:)*p(mesh.pedge((ex-1)*mesh.Ny+ey,:),:);
      hd=hd+sum(abs(a-b).^2); ha=ha+sum(abs(a).^2); hb=hb+sum(abs(b).^2);
    end
  end
  st=complex(zeros(mesh.Nx,size(p,2))); sb=st;
  for ex=1:mesh.Nx
    st(ex,:)=Pt(2,:)*p(mesh.pedge((ex-1)*mesh.Ny+mesh.Ny,:),:);
    sb(ex,:)=Pb(2,:)*p(mesh.pedge((ex-1)*mesh.Ny+1,:),:);
  end
  internal=max(sqrt(vd)/max([1,sqrt(va),sqrt(vb)]), ...
    sqrt(hd)/max([1,sqrt(ha),sqrt(hb)]));
  out=struct('internal_defect',internal, ...
    'periodic_gauge_defect',LOCAL_fe_relative(st,sb), ...
    'periodic_physical_defect',LOCAL_fe_relative(exp(1i*beta/2)*st, ...
    exp(1i*beta)*exp(-1i*beta/2)*sb), ...
    'reconstructed_from_local_element_traces',true);
end

function out=LOCAL_audit(mesh,maps,center,plus,minus,prop,coords)
  take=unique(round(linspace(1,mesh.Ny,min(8,mesh.Ny))));
  out=struct('sample_indices',take,'gauge_wall_traces',struct( ...
    'center_left',maps.center.wall_left(take,:), ...
    'center_right',maps.center.wall_right(take,:), ...
    'first_minus_left',maps.minus.wall_left(take,:)*coords.cminus, ...
    'first_minus_right',maps.minus.wall_right(take,:)*coords.cminus, ...
    'first_plus_left',maps.plus.wall_left(take,:)*coords.cplus, ...
    'first_plus_right',maps.plus.wall_right(take,:)*coords.cplus, ...
    'tail_minus_next',maps.minus.wall_right(take,:)*(prop.Pminus*coords.cminus), ...
    'tail_plus_next',maps.plus.wall_left(take,:)*(prop.Pplus*coords.cplus)), ...
    'boundary_flux_samples',struct('center_left',center.flux.left(take,:), ...
    'center_right',center.flux.right(take,:), ...
    'minus_left_map',minus.flux.left(take,:), ...
    'minus_right_map',minus.flux.right(take,:), ...
    'plus_left_map',plus.flux.left(take,:), ...
    'plus_right_map',plus.flux.right(take,:)), ...
    'fixed_wall_flux_maps',struct('minus_left',minus.flux.left, ...
    'minus_right',minus.flux.right,'plus_left',plus.flux.left, ...
    'plus_right',plus.flux.right), ...
    'fixed_wall_flux_map_meaning', ...
    'em*Pminus, em, ep, ep*Pplus in global +x periodic gauge');
end

function out=LOCAL_contract(in,v)
  out=struct('N',real(v'*in.N*v),'A',real(v'*in.A*v), ...
    'B',real(v'*in.B*v),'gram_record',in.record,'solve',in.solve);
  if isfield(in,'regions')
    energy=zeros(3,3); names=cell(1,3);
    for j=1:3
      region=in.regions{j}; names{j}=region.name;
      energy(j,:)=[real(v'*region.N*v),real(v'*region.A*v), ...
        real(v'*region.B*v)];
    end
    total=[out.N,out.A,out.B];
    shares=energy./max(realmin,total);
    out.correction_support_energy=struct('region_names',{names}, ...
      'columns',{{'N','A','B'}},'contributions',energy,'shares',shares, ...
      'partition_relative_defects', ...
      abs(sum(energy,1)-total)./max([ones(1,3);abs(total)],[],1), ...
      'meaning',['Energy of the final conforming companion on elements ', ...
      'touched by frozen correction nodes; not raw-minus-companion energy.']);
  end
end

function out=LOCAL_gram_only(in)
  out=struct('N',in.N,'A',in.A,'B',in.B,'gram_record',in.record);
end

function value=LOCAL_fe_relative(a,b)
  value=norm(a-b,'fro')/max([1,norm(a,'fro'),norm(b,'fro')]);
end

%% ==================== Polar quadrature ====================
% Gauss--Legendre nodes integrate only the exact circular contrast.

function [x,w]=LOCAL_gauss(n,a,b)
  j=(1:n-1)'; q=j./sqrt(4*j.^2-1);
  [V,D]=eig(diag(q,1)+diag(q,-1)); x0=diag(D); [x0,idx]=sort(x0);
  V=V(:,idx); w0=2*(V(1,:)'.^2);
  x=(a+b)/2+(b-a)*x0/2; w=(b-a)*w0/2;
end
