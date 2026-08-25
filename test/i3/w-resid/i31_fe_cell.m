function out = i31_fe_cell(c,node,coords,prop,level,scale)
%I31_FE_CELL Build the I3.1 Q1 trial and RT0 majorant cell data.
% Purpose:
%   Map frozen Fourier wall traces to periodic-gauge Q1 cell fields, build
%   one globally normal-continuous RT0 flux, and return center, first-cell,
%   and repeated-tail Gram matrices for the continuous weak residual.
% Input:
%   c       - Frozen physical parameters and numerical gates.
%   node    - Saved-candidate evaluator output.
%   coords  - Near-null and left/right stable-subspace coordinates.
%   prop    - Frozen whole-subspace actions and Dirichlet trace maps.
%   level   - One preregistered Q1 and disk-quadrature level.
%   scale   - Global complex phase/scale multiplier applied to the field.
% Output:
%   out     - Small Gram matrices and implementation diagnostics. Dense Q1
%             solution and RT0 maps are deliberately not returned.
% Main algorithm:
%   Assemble structured periodic Q1 operators, add the sharp material disk
%   by true-circle polar contrast quadrature, solve the physical Helmholtz
%   Dirichlet cell problems, average Q1 one-sided fluxes into global RT0
%   edge degrees of freedom, and contract sparse quadratic forms.
% Based on:
%   research/projects/eig-apost/implementation/i3/design-3-1b.md.
% Main changes:
%   Replaces the failed BIE close-evaluation fit by a conforming Q1 field
%   and an H(div)-conforming RT0 functional majorant.
% Numerical goal:
%   Produce ordinary-double weak-residual data, not a certified enclosure.

  if nargin ~= 6 || ~isscalar(scale) || ~isfinite(scale)
    error('i31w:Execution','Invalid finite-element module input.');
  end
  mu = c.mu_h;
  mesh = LOCAL_mesh(level.Nx,level.Ny);
  [lead,center] = LOCAL_operators(mesh,c,level);
  lead_factor = LOCAL_factor_system(lead,mu,c);
  center_factor = LOCAL_factor_system(center,mu,c);

  gauge = exp(1i*mesh.y(:)*(node.beta_m(:).'-c.beta));
  Up = LOCAL_apply_factor(lead_factor,gauge*prop.Dplus, ...
    gauge*(prop.Dplus*prop.Pplus),c);
  Um = LOCAL_apply_factor(lead_factor,gauge*(prop.Dminus*prop.Pminus), ...
    gauge*prop.Dminus,c);
  cm = scale*coords.cminus;
  cp = scale*coords.cplus;
  Uc = LOCAL_apply_factor(center_factor,gauge*(prop.Dminus*cm), ...
    gauge*(prop.Dplus*cp),c);

  up0 = Up.U*cp;
  up1 = Up.U*(prop.Pplus*cp);
  um0 = Um.U*cm;
  um1 = Um.U*(prop.Pminus*cm);
  center_gram = LOCAL_cell_grams(center,Uc.U,um0,up0,c);
  first_plus = LOCAL_cell_grams(lead,up0,Uc.U,up1,c);
  first_minus = LOCAL_cell_grams(lead,um0,um1,Uc.U,c);

  Pp2 = prop.Pplus*prop.Pplus;
  Pm2 = prop.Pminus*prop.Pminus;
  tail_plus = LOCAL_cell_grams(lead,Up.U*prop.Pplus,Up.U,Up.U*Pp2,c);
  tail_minus = LOCAL_cell_grams(lead,Um.U*prop.Pminus,Um.U*Pm2,Um.U,c);

  form = LOCAL_form_defects(mesh,Uc.U,Up.U,Um.U,prop,cm,cp,c);
  hdiv = LOCAL_hdiv_defects(center_gram,first_plus,first_minus, ...
    tail_plus,tail_minus,prop,cm,cp,c);
  audit = LOCAL_audit(mesh,Uc.U,Up.U,Um.U,center_gram,first_plus, ...
    first_minus,tail_plus,tail_minus,prop,cm,cp);
  grams = [center_gram.record,first_minus.record,first_plus.record, ...
    tail_minus.record,tail_plus.record];
  gram_pass = all([grams.pass]);
  finite_pass = all(isfinite([center_gram.N,center_gram.A,center_gram.B, ...
    first_minus.N,first_minus.A,first_minus.B, ...
    first_plus.N,first_plus.A,first_plus.B])) && ...
    all(isfinite(tail_minus.N),'all') && all(isfinite(tail_minus.A),'all') && ...
    all(isfinite(tail_minus.B),'all') && all(isfinite(tail_plus.N),'all') && ...
    all(isfinite(tail_plus.A),'all') && all(isfinite(tail_plus.B),'all');
  info = whos;
  out = struct('level',level,'scale',scale, ...
    'map_dimensions',struct('q1_nodes',mesh.nnode,'rt0_edges',mesh.nedge, ...
    'state_dimension',c.K,'lead_solution_map',[mesh.nnode,c.K]), ...
    'factor',struct('lead',lead_factor.record,'center',center_factor.record, ...
    'plus_solve',Up.record,'minus_solve',Um.record,'center_solve',Uc.record), ...
    'integration',struct('lead',lead.record,'center',center.record), ...
    'form',form,'hdiv',hdiv,'audit',audit, ...
    'gram_pass',gram_pass,'finite_pass',finite_pass, ...
    'center',LOCAL_small(center_gram),'first',struct( ...
    'minus',LOCAL_small(first_minus),'plus',LOCAL_small(first_plus)), ...
    'tail',struct('minus',LOCAL_small(tail_minus), ...
    'plus',LOCAL_small(tail_plus)), ...
    'peak_local_workspace_mib',sum([info.bytes])/2^20);
end

%% ==================== Structured finite elements ====================
% These helpers define the periodic Q1 mesh and sparse quadratic forms.

function mesh = LOCAL_mesh(Nx,Ny)
  hx = 1/Nx; hy = 1/Ny;
  y = -0.5+(0:Ny-1)'*hy;
  ids = reshape(1:(Nx+1)*Ny,Ny,Nx+1).';
  elem = zeros(Nx*Ny,4); pedge = zeros(Nx*Ny,4);
  nv = (Nx+1)*Ny;
  for ex = 1:Nx
    for ey = 1:Ny
      row = (ex-1)*Ny+ey;
      ey2 = mod(ey,Ny)+1;
      elem(row,:) = [ids(ex,ey),ids(ex+1,ey), ...
        ids(ex+1,ey2),ids(ex,ey2)];
      vleft = (ex-1)*Ny+ey;
      vright = ex*Ny+ey;
      hbottom = nv+(ex-1)*Ny+ey;
      htop = nv+(ex-1)*Ny+ey2;
      pedge(row,:) = [vleft,vright,hbottom,htop];
    end
  end
  mesh = struct('Nx',Nx,'Ny',Ny,'hx',hx,'hy',hy,'y',y, ...
    'ids',ids,'elem',elem,'pedge',pedge,'nelem',Nx*Ny, ...
    'nnode',(Nx+1)*Ny,'nvedge',nv,'nedge',nv+Nx*Ny, ...
    'left',ids(1,:).','right',ids(end,:).');
end

function [lead,center] = LOCAL_operators(mesh,c,level)
  [Kloc,Mloc,Aloc,Bloc] = LOCAL_background_local(mesh,c);
  K = LOCAL_repeat_sparse(mesh.elem,Kloc,mesh.nnode);
  M0 = LOCAL_repeat_sparse(mesh.elem,Mloc,mesh.nnode);
  zdofs = [mesh.elem,mesh.nnode+mesh.pedge];
  LA = LOCAL_repeat_sparse(zdofs,Aloc,mesh.nnode+mesh.nedge);
  LB0 = LOCAL_repeat_sparse(zdofs,Bloc,mesh.nnode+mesh.nedge);
  K = (K+K')/2; M0 = (M0+M0')/2;
  LA = (LA+LA')/2; LB0 = (LB0+LB0')/2;
  [Mdisk,Bdisk,area] = LOCAL_disk_correction(mesh,c,level);
  M1 = M0+(c.rho_disk-1)*Mdisk; LB1 = LB0+Bdisk;
  M1 = (M1+M1')/2; LB1 = (LB1+LB1')/2;
  base_finite = all(isfinite(nonzeros(K))) && all(isfinite(nonzeros(M0))) && ...
    all(isfinite(nonzeros(LA))) && all(isfinite(nonzeros(LB0)));
  lead_finite = base_finite && all(isfinite(nonzeros(M1))) && ...
    all(isfinite(nonzeros(LB1)));
  area_defect = abs(area-pi*c.R^2)/max(realmin,pi*c.R^2);
  center_record = struct('has_disk',false,'disk_quadrature_area',0, ...
    'disk_area_relative_defect',0,'finite',base_finite, ...
    'disk_object_pass',base_finite,'K_nnz',nnz(K),'M_nnz',nnz(M0), ...
    'majorant_A_nnz',nnz(LA),'majorant_B_nnz',nnz(LB0));
  lead_record = struct('has_disk',true,'disk_quadrature_area',area, ...
    'disk_area_relative_defect',area_defect,'finite',lead_finite, ...
    'disk_object_pass',lead_finite&&area_defect<=c.disk_area_tol, ...
    'K_nnz',nnz(K),'M_nnz',nnz(M1),'majorant_A_nnz',nnz(LA), ...
    'majorant_B_nnz',nnz(LB1));
  center = struct('mesh',mesh,'K',K,'M',M0,'V',K+c.gamma*M0, ...
    'LA',LA,'LB',LB0,'record',center_record);
  lead = struct('mesh',mesh,'K',K,'M',M1,'V',K+c.gamma*M1, ...
    'LA',LA,'LB',LB1,'record',lead_record);
end

function [K,M,LA,LB] = LOCAL_background_local(mesh,c)
  z = [-1,1]/sqrt(3); jac = mesh.hx*mesh.hy/4;
  K = complex(zeros(4)); M = zeros(4);
  LA = complex(zeros(8)); LB = complex(zeros(8));
  for a = 1:2
    for b = 1:2
      [N,dx,dy,P,D] = LOCAL_shapes(z(a),z(b),mesh,c.beta);
      G = [dx;dy+1i*c.beta*N];
      K = K+jac*(G'*G);
      M = M+jac*(N'*N);
      Q = [G,-P];
      LA = LA+jac*(Q'*Q);
      T = [c.mu_h*N,D];
      LB = LB+jac*(T'*T);
    end
  end
end

function S = LOCAL_repeat_sparse(dofs,L,n)
  ne = size(dofs,1); m = size(dofs,2); count = ne*m*m;
  I = zeros(count,1); J = zeros(count,1); V = complex(zeros(count,1));
  pos = 0;
  for a = 1:m
    for b = 1:m
      take = pos+(1:ne);
      I(take) = dofs(:,a); J(take) = dofs(:,b); V(take) = L(a,b);
      pos = pos+ne;
    end
  end
  S = sparse(I,J,V,n,n);
end

function [Mdisk,Bdisk,area] = LOCAL_disk_correction(mesh,c,level)
  [r,wr] = LOCAL_gauss(level.Nr,0,c.R);
  theta = (0:level.Ntheta-1)*(2*pi/level.Ntheta);
  np = level.Nr*level.Ntheta;
  Im = zeros(16*np,1); Jm = Im; Vm = complex(Im);
  Ib = zeros(64*np,1); Jb = Ib; Vb = complex(Ib);
  pm = 0; pb = 0; area = 0;
  for ir = 1:level.Nr
    for it = 1:level.Ntheta
      x = r(ir)*cos(theta(it)); y = r(ir)*sin(theta(it));
      weight = wr(ir)*r(ir)*(2*pi/level.Ntheta);
      [row,xi,eta] = LOCAL_locate(mesh,x,y);
      [N,~,~,~,D] = LOCAL_shapes(xi,eta,mesh,c.beta);
      nodes = mesh.elem(row,:); z = [nodes,mesh.nnode+mesh.pedge(row,:)];
      Lm = weight*(N'*N);
      Tout = [c.mu_h*N,D];
      Tin = [c.mu_h*c.rho_disk*N,D];
      Lb = weight*((Tin'*Tin)/c.rho_disk-Tout'*Tout);
      for a = 1:4
        for b = 1:4
          pm = pm+1; Im(pm)=nodes(a); Jm(pm)=nodes(b); Vm(pm)=Lm(a,b);
        end
      end
      for a = 1:8
        for b = 1:8
          pb = pb+1; Ib(pb)=z(a); Jb(pb)=z(b); Vb(pb)=Lb(a,b);
        end
      end
      area = area+weight;
    end
  end
  Mdisk = sparse(Im,Jm,Vm,mesh.nnode,mesh.nnode);
  n = mesh.nnode+mesh.nedge;
  Bdisk = sparse(Ib,Jb,Vb,n,n);
end

function [row,xi,eta] = LOCAL_locate(mesh,x,y)
  ex = min(mesh.Nx,max(1,floor((x+0.5)/mesh.hx)+1));
  ey = min(mesh.Ny,max(1,floor((y+0.5)/mesh.hy)+1));
  x0 = -0.5+(ex-1)*mesh.hx;
  y0 = -0.5+(ey-1)*mesh.hy;
  xi = 2*(x-x0)/mesh.hx-1;
  eta = 2*(y-y0)/mesh.hy-1;
  row = (ex-1)*mesh.Ny+ey;
end

function [N,dx,dy,P,D] = LOCAL_shapes(xi,eta,mesh,beta)
  N = 0.25*[(1-xi)*(1-eta),(1+xi)*(1-eta), ...
    (1+xi)*(1+eta),(1-xi)*(1+eta)];
  dxi = 0.25*[-(1-eta),(1-eta),(1+eta),-(1+eta)];
  deta = 0.25*[-(1-xi),-(1+xi),(1+xi),(1-xi)];
  dx = (2/mesh.hx)*dxi; dy = (2/mesh.hy)*deta;
  P = [0.5*(1-xi),0.5*(1+xi),0,0; ...
    0,0,0.5*(1-eta),0.5*(1+eta)];
  D = [-1/mesh.hx,1/mesh.hx,-1/mesh.hy,1/mesh.hy]+ ...
    1i*beta*[0,0,0.5*(1-eta),0.5*(1+eta)];
end

%% ==================== Physical cell solves ====================
% These helpers apply one scaled sparse factorization to fixed wall data.

function fac = LOCAL_factor_system(fem,mu,c)
  mesh = fem.mesh;
  boundary = [mesh.left;mesh.right];
  interior = setdiff((1:mesh.nnode).',boundary,'stable');
  C = fem.K-mu*fem.M; Cplus = fem.K+mu*fem.M;
  Cii = C(interior,interior); Cib = C(interior,boundary);
  diagonal = real(diag(Cplus(interior,interior)));
  if any(~isfinite(diagonal)) || any(diagonal<=0)
    error('i31w:CellExtension','The positive scaling diagonal is unavailable.');
  end
  S = spdiags(1./sqrt(diagonal),0,numel(interior),numel(interior));
  Cs = S*Cii*S;
  try
    rc = 1/condest(Cs);
  catch ME
    error('i31w:CellExtension','Scaled cell condition estimate failed: %s',ME.message);
  end
  if ~isfinite(rc) || rc<c.cell_rcond_min
    error('i31w:CellExtension', ...
      'Scaled cell reciprocal condition estimate %.17g failed.',rc);
  end
  try
    solver = decomposition(Cs,'lu');
  catch ME
    error('i31w:CellExtension','Scaled cell factorization failed: %s',ME.message);
  end
  fac = struct('mesh',mesh,'Cs',Cs,'Cs_norm_one',norm(Cs,1), ...
    'Cii',Cii,'Cib',Cib,'S',S,'solver',solver, ...
    'interior',interior,'boundary',boundary,'record',struct( ...
    'scaled_rcond_estimate',rc,'pass',true,'interior_order',numel(interior), ...
    'boundary_order',numel(boundary)));
end

function out = LOCAL_apply_factor(fac,left,right,c)
  if size(left,1)~=fac.mesh.Ny || size(right,1)~=fac.mesh.Ny || ...
      size(left,2)~=size(right,2)
    error('i31w:CellExtension','Wall data have the wrong dimensions.');
  end
  ub = [left;right]; rhs = -fac.Cib*ub; scaled_rhs = fac.S*rhs;
  try
    y = fac.solver\scaled_rhs;
  catch ME
    error('i31w:CellExtension','Scaled cell solve failed: %s',ME.message);
  end
  ui = fac.S*y;
  residual = fac.Cs*y-scaled_rhs;
  matrix_norm = fac.Cs_norm_one;
  relative = zeros(1,size(ub,2)); backward = relative;
  for j = 1:size(ub,2)
    relative(j) = norm(residual(:,j),1)/ ...
      max(realmin,norm(scaled_rhs(:,j),1));
    backward(j) = norm(residual(:,j),1)/max(realmin, ...
      matrix_norm*norm(y(:,j),1)+norm(scaled_rhs(:,j),1));
  end
  U = complex(zeros(fac.mesh.nnode,size(ub,2)));
  U(fac.boundary,:) = ub; U(fac.interior,:) = ui;
  finite = all(isfinite(U),'all') && all(isfinite([relative,backward]));
  max_relative = max(relative); max_backward = max(backward);
  out = struct('U',U,'record',struct('rhs_relative_residuals',relative, ...
    'rhs_backward_errors',backward,'max_rhs_relative_residual',max_relative, ...
    'max_rhs_backward_error',max_backward, ...
    'finite',finite,'pass',finite && max(max_relative,max_backward)<= ...
    c.cell_solve_residual_max, ...
    'right_hand_sides',size(ub,2)));
end

%% ==================== RT0 reconstruction and Gram matrices ====================
% A unique global edge orientation makes every returned flux H(div)-conforming.

function out = LOCAL_cell_grams(fem,U,Uleft,Uright,c)
  p = LOCAL_flux(fem.mesh,U,Uleft,Uright,c.beta);
  Z = [U;p.map];
  Nraw = U'*(fem.V*U);
  Araw = Z'*(fem.LA*Z);
  Braw = Z'*(fem.LB*Z);
  record = LOCAL_gram_record(Nraw,Araw,Braw,c);
  record.rt0_internal_normal_defect = p.continuity.internal_defect;
  record.periodic_flux_gauge_defect = p.continuity.periodic_gauge_defect;
  record.periodic_flux_physical_defect = p.continuity.periodic_physical_defect;
  out = struct('N',(Nraw+Nraw')/2,'A',(Araw+Araw')/2, ...
    'B',(Braw+Braw')/2,'flux',p.boundary,'record',record);
end

function out = LOCAL_flux(mesh,U,Uleft,Uright,beta)
  r = size(U,2); vertical = complex(zeros(mesh.nvedge,r));
  horizontal = complex(zeros(mesh.Nx*mesh.Ny,r));
  left_target = LOCAL_vertical_edge(mesh,U,1,-1,beta);
  right_target = LOCAL_vertical_edge(mesh,U,mesh.Nx,1,beta);
  left_neighbor = LOCAL_vertical_edge(mesh,Uleft,mesh.Nx,1,beta);
  right_neighbor = LOCAL_vertical_edge(mesh,Uright,1,-1,beta);
  vertical(1:mesh.Ny,:) = 0.5*(left_neighbor+left_target);
  vertical(mesh.Nx*mesh.Ny+(1:mesh.Ny),:) = ...
    0.5*(right_target+right_neighbor);
  for ix = 2:mesh.Nx
    a = LOCAL_vertical_edge(mesh,U,ix-1,1,beta);
    b = LOCAL_vertical_edge(mesh,U,ix,-1,beta);
    rows = (ix-1)*mesh.Ny+(1:mesh.Ny);
    vertical(rows,:) = 0.5*(a+b);
  end
  for ex = 1:mesh.Nx
    for ey = 1:mesh.Ny
      below = mod(ey-2,mesh.Ny)+1;
      top = LOCAL_horizontal_edge(mesh,U,ex,below,1,beta);
      bottom = LOCAL_horizontal_edge(mesh,U,ex,ey,-1,beta);
      row = (ex-1)*mesh.Ny+ey;
      horizontal(row,:) = 0.5*(top+bottom);
    end
  end
  map = [vertical;horizontal];
  continuity = LOCAL_rt0_continuity(mesh,map,beta);
  out = struct('map',map,'continuity',continuity, ...
    'boundary',struct('left',vertical(1:mesh.Ny,:), ...
    'right',vertical(mesh.Nx*mesh.Ny+(1:mesh.Ny),:)));
end

function values = LOCAL_vertical_edge(mesh,U,ex,xi,beta)
  values = complex(zeros(mesh.Ny,size(U,2)));
  for ey = 1:mesh.Ny
    row = (ex-1)*mesh.Ny+ey;
    [~,dx,~,~,~] = LOCAL_shapes(xi,0,mesh,beta);
    values(ey,:) = dx*U(mesh.elem(row,:),:);
  end
end

function value = LOCAL_horizontal_edge(mesh,U,ex,ey,eta,beta)
  row = (ex-1)*mesh.Ny+ey;
  [N,~,dy,~,~] = LOCAL_shapes(0,eta,mesh,beta);
  value = (dy+1i*beta*N)*U(mesh.elem(row,:),:);
end

function record = LOCAL_gram_record(N,A,B,c)
  names = {'N','A','B'}; values = {N,A,B};
  hermitian = zeros(1,3); minimum = zeros(1,3); scale = zeros(1,3);
  finite = true;
  for j = 1:3
    G = values{j}; H = (G+G')/2;
    scale(j) = max(1,norm(G,2));
    hermitian(j) = norm(G-G','fro')/max(1,norm(G,'fro'));
    minimum(j) = min(real(eig(full(H))));
    finite = finite && all(isfinite(G),'all') && isfinite(minimum(j));
  end
  pass = finite && all(hermitian<=c.gram_hermitian_max) && ...
    all(minimum>=-c.gram_psd_scale*scale);
  record = struct('names',{names},'hermitian_defects',hermitian, ...
    'minimum_eigenvalues',minimum,'matrix_scales',scale, ...
    'finite',finite,'pass',pass);
end

%% ==================== Conformity diagnostics ====================
% These checks compare independently assembled neighboring cell objects.

function out = LOCAL_form_defects(mesh,Uc,Up,Um,prop,cm,cp,c)
  wc = LOCAL_walls(mesh,Uc);
  up0 = LOCAL_walls(mesh,Up*cp); up1 = LOCAL_walls(mesh,Up*(prop.Pplus*cp));
  um0 = LOCAL_walls(mesh,Um*cm); um1 = LOCAL_walls(mesh,Um*(prop.Pminus*cm));
  upt = LOCAL_walls(mesh,Up*prop.Pplus);
  upt_next = LOCAL_walls(mesh,Up*(prop.Pplus*prop.Pplus));
  umt = LOCAL_walls(mesh,Um*prop.Pminus);
  umt_next = LOCAL_walls(mesh,Um*(prop.Pminus*prop.Pminus));
  defects = [LOCAL_relative(wc.left,um0.right), ...
    LOCAL_relative(wc.right,up0.left),LOCAL_relative(up0.right,up1.left), ...
    LOCAL_relative(um0.left,um1.right), ...
    LOCAL_relative(upt.right,upt_next.left), ...
    LOCAL_relative(umt.left,umt_next.right)];
  periodic = [LOCAL_periodic_field(mesh,Uc,c.beta), ...
    LOCAL_periodic_field(mesh,Up,c.beta),LOCAL_periodic_field(mesh,Um,c.beta)];
  gauge_defect = max([periodic.gauge_defect]);
  physical_defect = max([periodic.physical_defect]);
  maximum = max([defects,gauge_defect,physical_defect,0]);
  out = struct('wall_defects',defects,'periodic_gauge_defect',gauge_defect, ...
    'physical_quasiperiodic_defect',physical_defect, ...
    'trace_norms',[norm(wc.left,'fro'),norm(wc.right,'fro'), ...
    norm(up0.right,'fro'),norm(um0.left,'fro')], ...
    'maximum_defect',maximum,'pass',all(isfinite(defects)) && ...
    isfinite(gauge_defect)&&isfinite(physical_defect)&& ...
    maximum<=c.form_defect_max);
end

function out = LOCAL_hdiv_defects(center,fp,fm,tp,tm,prop,cm,cp,c)
  defects = [LOCAL_relative(center.flux.left,fm.flux.right), ...
    LOCAL_relative(center.flux.right,fp.flux.left), ...
    LOCAL_relative(fp.flux.right,tp.flux.left*cp), ...
    LOCAL_relative(fm.flux.left,tm.flux.right*cm), ...
    LOCAL_relative(tp.flux.right,tp.flux.left*prop.Pplus), ...
    LOCAL_relative(tm.flux.left,tm.flux.right*prop.Pminus)];
  periodic = [center.record.periodic_flux_gauge_defect, ...
    fp.record.periodic_flux_gauge_defect,fm.record.periodic_flux_gauge_defect, ...
    tp.record.periodic_flux_gauge_defect,tm.record.periodic_flux_gauge_defect];
  physical = [center.record.periodic_flux_physical_defect, ...
    fp.record.periodic_flux_physical_defect,fm.record.periodic_flux_physical_defect, ...
    tp.record.periodic_flux_physical_defect,tm.record.periodic_flux_physical_defect];
  internal = [center.record.rt0_internal_normal_defect, ...
    fp.record.rt0_internal_normal_defect,fm.record.rt0_internal_normal_defect, ...
    tp.record.rt0_internal_normal_defect,tm.record.rt0_internal_normal_defect];
  seam = max([periodic,physical]); maximum = max([defects,internal,seam,0]);
  out = struct('global_orientation','vertical:+x;horizontal:+y', ...
    'interface_defects',defects,'periodic_seam_defect',seam, ...
    'local_rt0_internal_defects',internal, ...
    'periodic_gauge_defects',periodic,'physical_quasiperiodic_defects',physical, ...
    'maximum_defect',maximum, ...
    'pass',all(isfinite([defects,internal,periodic,physical])) && ...
    maximum<=c.hdiv_defect_max);
end

function out = LOCAL_audit(mesh,Uc,Up,Um,center,fp,fm,tp,tm,prop,cm,cp)
  up0 = Up*cp; um0 = Um*cm;
  upt = Up*(prop.Pplus*cp); umt = Um*(prop.Pminus*cm);
  out = struct('gauge_wall_traces',struct( ...
    'center',LOCAL_walls(mesh,Uc), ...
    'first_minus',LOCAL_walls(mesh,um0), ...
    'first_plus',LOCAL_walls(mesh,up0), ...
    'tail_one_step_minus',LOCAL_walls(mesh,umt), ...
    'tail_one_step_plus',LOCAL_walls(mesh,upt)), ...
    'boundary_flux_values',struct('center',center.flux, ...
    'first_minus',fm.flux,'first_plus',fp.flux, ...
    'tail_one_step_minus',struct('left',tm.flux.left*cm, ...
    'right',tm.flux.right*cm), ...
    'tail_one_step_plus',struct('left',tp.flux.left*cp, ...
    'right',tp.flux.right*cp)), ...
    'tail_boundary_flux_maps',struct('minus',tm.flux,'plus',tp.flux));
end

function out = LOCAL_periodic_field(mesh,U,beta)
  gauge_top = complex(zeros(3*mesh.Nx,size(U,2)));
  gauge_bottom = gauge_top; p = 0; xi = [-1,0,1];
  for ex = 1:mesh.Nx
    top_row = (ex-1)*mesh.Ny+mesh.Ny;
    bottom_row = (ex-1)*mesh.Ny+1;
    for j = 1:3
      p = p+1;
      [Nt,~,~,~,~] = LOCAL_shapes(xi(j),1,mesh,beta);
      [Nb,~,~,~,~] = LOCAL_shapes(xi(j),-1,mesh,beta);
      gauge_top(p,:) = Nt*U(mesh.elem(top_row,:),:);
      gauge_bottom(p,:) = Nb*U(mesh.elem(bottom_row,:),:);
    end
  end
  gauge = LOCAL_relative(gauge_top,gauge_bottom);
  physical_top = exp(1i*beta/2)*gauge_top;
  physical_bottom = exp(-1i*beta/2)*gauge_bottom;
  physical = LOCAL_relative(physical_top,exp(1i*beta)*physical_bottom);
  out = struct('gauge_defect',gauge,'physical_defect',physical);
end

function out = LOCAL_rt0_continuity(mesh,p,beta)
  [~,~,~,Pr,~] = LOCAL_shapes(1,0,mesh,beta);
  [~,~,~,Pl,~] = LOCAL_shapes(-1,0,mesh,beta);
  [~,~,~,Pt,~] = LOCAL_shapes(0,1,mesh,beta);
  [~,~,~,Pb,~] = LOCAL_shapes(0,-1,mesh,beta);
  vdiff2 = 0; vleft2 = 0; vright2 = 0;
  for ex = 1:mesh.Nx-1
    for ey = 1:mesh.Ny
      left_row = (ex-1)*mesh.Ny+ey;
      right_row = ex*mesh.Ny+ey;
      a = Pr(1,:)*p(mesh.pedge(left_row,:),:);
      b = Pl(1,:)*p(mesh.pedge(right_row,:),:);
      vdiff2 = vdiff2+sum(abs(a-b).^2);
      vleft2 = vleft2+sum(abs(a).^2); vright2 = vright2+sum(abs(b).^2);
    end
  end
  hdiff2 = 0; hbelow2 = 0; habove2 = 0;
  for ex = 1:mesh.Nx
    for ey = 2:mesh.Ny
      below_row = (ex-1)*mesh.Ny+ey-1;
      above_row = (ex-1)*mesh.Ny+ey;
      a = Pt(2,:)*p(mesh.pedge(below_row,:),:);
      b = Pb(2,:)*p(mesh.pedge(above_row,:),:);
      hdiff2 = hdiff2+sum(abs(a-b).^2);
      hbelow2 = hbelow2+sum(abs(a).^2); habove2 = habove2+sum(abs(b).^2);
    end
  end
  seam_top = complex(zeros(mesh.Nx,size(p,2)));
  seam_bottom = seam_top;
  for ex = 1:mesh.Nx
    top_row = (ex-1)*mesh.Ny+mesh.Ny;
    bottom_row = (ex-1)*mesh.Ny+1;
    seam_top(ex,:) = Pt(2,:)*p(mesh.pedge(top_row,:),:);
    seam_bottom(ex,:) = Pb(2,:)*p(mesh.pedge(bottom_row,:),:);
  end
  vertical = sqrt(vdiff2)/max([1,sqrt(vleft2),sqrt(vright2)]);
  horizontal = sqrt(hdiff2)/max([1,sqrt(hbelow2),sqrt(habove2)]);
  internal = max(vertical,horizontal);
  periodic_gauge = LOCAL_relative(seam_top,seam_bottom);
  periodic_physical = LOCAL_relative(exp(1i*beta/2)*seam_top, ...
    exp(1i*beta)*exp(-1i*beta/2)*seam_bottom);
  out = struct('internal_defect',internal, ...
    'periodic_gauge_defect',periodic_gauge, ...
    'periodic_physical_defect',periodic_physical, ...
    'reconstructed_from_local_element_traces',true);
end

function out = LOCAL_walls(mesh,U)
  out = struct('left',U(mesh.left,:),'right',U(mesh.right,:));
end

function value = LOCAL_relative(a,b)
  value = norm(a-b,'fro')/max([1,norm(a,'fro'),norm(b,'fro')]);
end

function out = LOCAL_small(in)
  out = rmfield(in,'flux');
end

%% ==================== Quadrature ====================
% Gauss--Legendre nodes are used only for the fixed true-circle contrast.

function [x,w] = LOCAL_gauss(n,a,b)
  j = (1:n-1)'; beta = j./sqrt(4*j.^2-1);
  [V,D] = eig(diag(beta,1)+diag(beta,-1));
  x0 = diag(D); [x0,order] = sort(x0); V = V(:,order);
  w0 = 2*(V(1,:).^2).';
  x = (a+b)/2+(b-a)*x0/2; w = (b-a)*w0/2;
end
