function fem_i9_run(output_dir,mode)
%FEM_I9_RUN Deliver all screened FEM candidates for the fixed I9.3 window.
% Purpose: Assemble curved interface-fitted P2 FEM for -Delta u=mu*rho*u.
% Input: output_dir is a new run directory; mode is formal or preflight.
% Output: JSON summary and raw mesh, forms, constraints and all Ritz vectors.
% Main algorithm: mesh -> assemble/reduce -> fixed shifts -> dedup/filter.
% Based on: test/i4/femref-a3/run_i4_1c_core.m P2 basis, Duffy quadrature,
%   curved determinant minimum, weak forms and mass-normalized eigenpairs.
% Main changes: two different global-oriented trilobe leads, native star,
%   Dirichlet x ends, beta-periodic y, one frozen mesh, no reference matching.
% Numerical goal: candidate delivery timing, without an error comparison.
  config = fem_i9_config(mode);
  if ~isfolder(output_dir), mkdir(output_dir); end
  maxNumCompThreads(config.resources.threads);
  started = tic; stage = 'configuration';
  LOCAL_json(fullfile(output_dir,'config.json'),config);
  environment = struct('matlab_version',version,'platform',computer, ...
    'max_threads',maxNumCompThreads,'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS'));
  try
    stage = 'mesh'; timer = tic;
    mesh = LOCAL_mesh(config);
    timings.mesh_seconds = toc(timer);
    fprintf('STAGE mesh complete: %d triangles, %d P2 nodes\n', ...
      size(mesh.triangle_p2,1),size(mesh.p2_points,1));
    stage = 'assembly_constraints'; timer = tic;
    [forms,validation] = LOCAL_assemble(config,mesh);
    constraint = LOCAL_constraint(config,mesh);
    P = constraint.prolongation;
    Araw = P'*forms.stiffness_full*P; Braw = P'*forms.mass_full*P;
    validation.stiffness_hermitian_defect = norm(Araw-Araw','fro')/norm(Araw,'fro');
    validation.mass_hermitian_defect = norm(Braw-Braw','fro')/norm(Braw,'fro');
    assert(max(validation.stiffness_hermitian_defect,validation.mass_hermitian_defect)<1e-12, ...
      'i93:Hermitian','Reduced forms failed Hermitian check.');
    A = (Araw+Araw')/2; B = (Braw+Braw')/2;
    solve_permutation = symamd(A+B);
    A_solve = A(solve_permutation,solve_permutation);
    B_solve = B(solve_permutation,solve_permutation);
    fprintf('STAGE sparse AMD ordering complete; SPD check starts\n');
    [~,positive_flag,~] = chol(B_solve,'vector');
    assert(positive_flag==0,'i93:Mass','Reduced weighted mass must be positive definite.');
    validation.mass_cholesky_flag = positive_flag;
    timings.assembly_constraints_seconds = toc(timer);
    fprintf('STAGE assembly complete: %d reduced DOFs\n',size(A,1));
    stage = 'eigensolve'; timer = tic;
    rng(config.solver.seed,'twister');
    options = struct('tol',config.solver.tolerance,'maxit',config.solver.max_iterations, ...
      'p',config.solver.subspace,'disp',0,'isreal',false);
    options.v0 = randn(size(A,1),1)+1i*randn(size(A,1),1);
    options.v0 = options.v0(solve_permutation);
    eigenvectors = []; eigenvalues = []; source_shift = []; solver_flags = [];
    solve_records = struct([]);
    for j = 1:numel(config.solver.shifts_mu)
      call_timer = tic;
      [V_ordered,D,flag] = eigs(A_solve,B_solve,config.solver.requested,config.solver.shifts_mu(j),options);
      V=zeros(size(V_ordered));V(solve_permutation,:)=V_ordered;
      item = struct('shift_mu',config.solver.shifts_mu(j), ...
        'requested',config.solver.requested,'flag',flag,'seconds',toc(call_timer));
      if j==1,solve_records=item;else,solve_records(j)=item;end
      eigenvectors = [eigenvectors,V]; %#ok<AGROW>
      eigenvalues = [eigenvalues;diag(D)]; %#ok<AGROW>
      source_shift = [source_shift;repmat(j,size(V,2),1)]; %#ok<AGROW>
      solver_flags = [solver_flags;repmat(flag,size(V,2),1)]; %#ok<AGROW>
      fprintf('STAGE eigs %d complete flag=%d\n',j,flag);
    end
    timings.eigensolve_seconds = toc(timer);
    stage = 'delivery_checks'; timer = tic;
    [modes,eigenvectors,cell_mass,overlaps] = LOCAL_modes(config,mesh,forms, ...
      constraint,A,B,eigenvalues,eigenvectors,source_shift,solver_flags);
    timings.delivery_seconds = toc(timer);
    timings.algorithm_seconds = timings.mesh_seconds+timings.assembly_constraints_seconds+ ...
      timings.eigensolve_seconds+timings.delivery_seconds;
    summary = struct('status','FEM_CANDIDATES_DELIVERED','config',config, ...
      'environment',environment,'mesh',rmfield(mesh,{'points','triangles','p2_points', ...
      'triangle_p2','edges','interface_edges','interface_parameters','material','cell_id'}), ...
      'full_dof',size(P,1),'reduced_dof',size(P,2),'triangles',size(mesh.triangles,1), ...
      'validation',validation,'constraint',rmfield(constraint,{'prolongation','top','bottom','dirichlet'}), ...
      'solves',solve_records,'modes',modes,'candidate_ids',find([modes.candidate]),'timings',timings);
    if strcmp(mode,'preflight'), summary.status='IMPLEMENTATION_PREFLIGHT_ONLY'; end
    stage = 'save_export'; timer = tic;
    save(fullfile(output_dir,'evidence.mat'),'config','mesh','forms','constraint','A','B', ...
      'eigenvectors','eigenvalues','source_shift','solver_flags','solve_records', ...
      'cell_mass','overlaps','modes','validation','solve_permutation','-v7');
    LOCAL_export(output_dir,mesh,forms,constraint,A,B,eigenvectors,eigenvalues,cell_mass,overlaps);
    writetable(struct2table(modes),fullfile(output_dir,'modes.csv'));
    summary.timings.save_export_seconds = toc(timer);
    summary.timings.matlab_function_seconds = toc(started);
    LOCAL_json(fullfile(output_dir,'summary.json'),summary);
    fprintf('COMPLETE %s: %d candidates; algorithm %.3fs\n',summary.status, ...
      numel(summary.candidate_ids),timings.algorithm_seconds);
  catch error_object
    failure = struct('stage',stage,'identifier',error_object.identifier, ...
      'message',error_object.message,'stack',error_object.stack, ...
      'report',getReport(error_object,'extended','hyperlinks','off'), ...
      'config',config,'elapsed_seconds',toc(started));
    LOCAL_json(fullfile(output_dir,'failure.json'),failure);
    rethrow(error_object);
  end
end

%% ==================== Geometry and conforming topology ====================
% Curved interface nodes are shared by both materials; all cells keep orientation.
function xy = LOCAL_curve(config,cell_index,theta)
  theta = theta(:);
  if cell_index == 0
    xy = config.model.star_scale*0.2*[(1.5+0.3*cos(5*theta)).*cos(theta), ...
      (1+0.3*cos(5*theta)).*sin(theta)];
  else
    a = config.model.a_negative;
    if cell_index>0, a=config.model.a_positive; end
    radius = config.model.radius*(1+a*cos(3*theta))/sqrt(1+a^2/2);
    xy = [radius.*cos(theta),radius.*sin(theta)];
  end
  xy(:,1)=xy(:,1)+cell_index*config.model.L;
end

function mesh = LOCAL_mesh(config)
  N=config.mesh.half_cells; s=config.mesh.subdivisions; ng=config.mesh.interface_segments;
  xmin=-N-0.5; xmax=N+0.5; ymin=-0.5; ymax=0.5; h=1/s;
  [gx,gy]=ndgrid(linspace(xmin,xmax,(2*N+1)*s+1),linspace(ymin,ymax,s+1));
  grid=[gx(:),gy(:)]; keep=true(size(gx(:)));
  polygons=cell(2*N+1,1); theta=2*pi*(0:ng-1)'/ng;
  for c=-N:N
    curve=LOCAL_curve(config,c,theta); polygons{c+N+1}=curve;
    for j=1:ng
      keep=keep & sum((grid-curve(j,:)).^2,2)>(config.mesh.grid_clearance_fraction*h)^2;
    end
  end
  boundary=abs(grid(:,2))==0.5 | mod((grid(:,1)+0.5)*s,s)==0;
  points=grid(keep|boundary,:); constraints=[]; raw_interfaces=[]; midpoint_values=[];
  for c=-N:N
    curve=polygons{c+N+1}; ids=size(points,1)+(1:ng)';
    points=[points;curve]; %#ok<AGROW>
    edge=[ids,ids([2:end,1])]; constraints=[constraints;edge]; %#ok<AGROW>
    raw_interfaces=[raw_interfaces;edge]; %#ok<AGROW>
    midpoint_values=[midpoint_values;LOCAL_curve(config,c,theta+pi/ng)]; %#ok<AGROW>
    relative=curve-[c,0];
    points=[points;[c,0]+(1-config.mesh.ring_scale)*relative; ...
      [c,0]+(1+config.mesh.ring_scale)*relative]; %#ok<AGROW>
  end
  [~,first,map]=unique(round(points/config.mesh.coordinate_tolerance),'rows');
  points=points(first,:); constraints=map(constraints); raw_interfaces=map(raw_interfaces);
  for x=xmin:1:xmax
    ids=find(abs(points(:,1)-x)<config.mesh.coordinate_tolerance);
    [~,order]=sort(points(ids,2)); ids=ids(order);
    constraints=[constraints;[ids(1:end-1),ids(2:end)]]; %#ok<AGROW>
  end
  for y=[ymin,ymax]
    ids=find(abs(points(:,2)-y)<config.mesh.coordinate_tolerance);
    [~,order]=sort(points(ids,1)); ids=ids(order);
    constraints=[constraints;[ids(1:end-1),ids(2:end)]]; %#ok<AGROW>
  end
  constraints=unique(sort(constraints,2),'rows');
  dt=delaunayTriangulation(points,constraints); points=dt.Points; triangles=dt.ConnectivityList;
  a=points(triangles(:,2),:)-points(triangles(:,1),:);
  b=points(triangles(:,3),:)-points(triangles(:,1),:);
  orientation=a(:,1).*b(:,2)-a(:,2).*b(:,1);
  triangles(orientation<0,[2,3])=triangles(orientation<0,[3,2]);
  nt=size(triangles,1); nv=size(points,1);
  [edges,~,edge_ids]=unique(sort([triangles(:,[1,2]);triangles(:,[2,3]);triangles(:,[3,1])],2),'rows');
  [found,interface_edges]=ismember(sort(raw_interfaces,2),edges,'rows');
  assert(all(found),'i93:Interface','A frozen material interface edge is missing.');
  assert(all(ismember(constraints,edges,'rows')),'i93:Constraints','A constraint edge is missing.');
  incidence=accumarray(edge_ids,1); assert(all(incidence(interface_edges)==2), ...
    'i93:InterfaceIncidence','Material interfaces must have two incident elements.');
  midpoints=(points(edges(:,1),:)+points(edges(:,2),:))/2;
  midpoints(interface_edges,:)=midpoint_values;
  p2_points=[points;midpoints]; triangle_p2=[triangles,nv+reshape(edge_ids,nt,3)];
  centroids=(points(triangles(:,1),:)+points(triangles(:,2),:)+points(triangles(:,3),:))/3;
  cell_id=floor(centroids(:,1)+0.5); material=ones(nt,1)*config.model.rho_background;
  for c=-N:N
    curve=polygons{c+N+1}; inside=inpolygon(centroids(:,1),centroids(:,2),curve(:,1),curve(:,2));
    rho=config.model.rho_center;
    if c<0, rho=config.model.rho_negative; elseif c>0, rho=config.model.rho_positive; end
    material(inside)=rho;
  end
  triangle_occurrence=repmat((1:nt)',3,1);
  for e=interface_edges'
    owners=triangle_occurrence(edge_ids==e);
    assert(material(owners(1))~=material(owners(2)),'i93:Material', ...
      'Shared interface must separate different materials.');
  end
  mesh=struct('points',points,'triangles',triangles,'p2_points',p2_points, ...
    'triangle_p2',triangle_p2,'edges',edges,'interface_edges',interface_edges, ...
    'interface_parameters',repmat(theta,N*2+1,1),'material',material,'cell_id',cell_id, ...
    'xmin',xmin,'xmax',xmax,'ymin',ymin,'ymax',ymax,'interface_edge_count',numel(interface_edges), ...
    'material_interface_status','SHARED_CURVED_P2','geometry_order',2);
end

%% ==================== Curved forms and boundary constraints ====================
% Integrate isoparametric K and rho-weighted M, then impose only y quasi-periodicity.
function [forms,validation]=LOCAL_assemble(config,mesh)
  nt=size(mesh.triangle_p2,1); nd=size(mesh.p2_points,1);
  nodes=zeros(nt,6,2);
  for j=1:6, nodes(:,j,:)=reshape(mesh.p2_points(mesh.triangle_p2(:,j),:),nt,1,2); end
  [lambda,weights]=LOCAL_quadrature(config.mesh.quadrature_order);
  nv=numel(weights); basis=zeros(nv,6); gr=zeros(2,6,nv);
  for q=1:nv, [basis(q,:),gr(:,:,q)]=LOCAL_basis(lambda(q,:)); end
  determinant_minimum=Inf; coefficients=zeros(nt,6);
  for t=1:nt
    coefficients(t,:)=LOCAL_det_coefficients(LOCAL_map_coefficients(squeeze(nodes(t,:,:))));
    determinant_minimum=min(determinant_minimum,LOCAL_quadratic_triangle_minimum(coefficients(t,:)));
  end
  assert(determinant_minimum>512*eps,'i93:Mapping','Nonpositive global curved Jacobian minimum.');
  kval=zeros(nt,36); mval=zeros(nt,36); areas=zeros(nt,1);
  for q=1:nv
    G=gr(:,:,q); X=nodes(:,:,1); Y=nodes(:,:,2);
    j11=X*G(1,:)'; j12=X*G(2,:)'; j21=Y*G(1,:)'; j22=Y*G(2,:)';
    determinant=j11.*j22-j12.*j21; w=weights(q)*determinant;
    dx=(j22.*G(1,:)-j21.*G(2,:))./determinant;
    dy=(-j12.*G(1,:)+j11.*G(2,:))./determinant;
    for b=1:6
      for a=1:6
        v=a+6*(b-1);
        kval(:,v)=kval(:,v)+w.*(dx(:,a).*dx(:,b)+dy(:,a).*dy(:,b));
        mval(:,v)=mval(:,v)+mesh.material.*w*basis(q,a)*basis(q,b);
      end
    end
    areas=areas+w;
  end
  rows=zeros(nt,36); cols=rows;
  for b=1:6
    for a=1:6, v=a+6*(b-1); rows(:,v)=mesh.triangle_p2(:,a);cols(:,v)=mesh.triangle_p2(:,b);end
  end
  forms=struct('stiffness_full',sparse(rows(:),cols(:),kval(:),nd,nd), ...
    'mass_full',sparse(rows(:),cols(:),mval(:),nd,nd),'mass_cells',{cell(2*config.mesh.half_cells+1,1)}, ...
    'element_mass',mval,'element_area',areas,'determinant_coefficients',coefficients);
  for c=-config.mesh.half_cells:config.mesh.half_cells
    ids=mesh.cell_id==c;
    forms.mass_cells{c+config.mesh.half_cells+1}=sparse(reshape(rows(ids,:),[],1), ...
      reshape(cols(ids,:),[],1),reshape(mval(ids,:),[],1),nd,nd);
  end
  validation=struct('determinant_minimum',determinant_minimum,'domain_area',sum(areas), ...
    'expected_domain_area',2*config.mesh.half_cells+1,'quadrature_weight_sum',sum(weights), ...
    'inclusion_areas',[sum(areas(mesh.material==4)),sum(areas(mesh.cell_id<0&mesh.material==17)), ...
    sum(areas(mesh.cell_id>0&mesh.material==17))]);
  assert(abs(sum(areas)-(2*config.mesh.half_cells+1))<1e-9,'i93:Area','Curved mesh does not partition the strip.');
end

function constraint=LOCAL_constraint(config,mesh)
  p=mesh.p2_points; n=size(p,1); tol=config.mesh.coordinate_tolerance;
  dirichlet=find(abs(p(:,1)-mesh.xmin)<tol|abs(p(:,1)-mesh.xmax)<tol);
  top=find(abs(p(:,2)-0.5)<tol);bottom=find(abs(p(:,2)+0.5)<tol);
  [~,a]=sort(p(top,1));top=top(a);[~,b]=sort(p(bottom,1));bottom=bottom(b);
  assert(numel(top)==numel(bottom)&&max(abs(p(top,1)-p(bottom,1)))<tol, ...
    'i93:Periodic','Top/bottom P2 seam nodes do not pair.');
  master=(1:n)';master(top)=bottom;
  active=true(n,1);active(dirichlet)=false;
  masters=unique(master(active)); [found,index]=ismember(master,masters);
  phase=ones(n,1);phase(top)=exp(1i*config.model.beta*config.model.d);
  ids=find(active&found);P=sparse(ids,index(ids),phase(ids),n,numel(masters));
  qp_defect=norm(P(top,:)-exp(1i*config.model.beta*config.model.d)*P(bottom,:),'fro');
  dirichlet_defect=norm(P(dirichlet,:),'fro');
  assert(qp_defect<1e-12&&dirichlet_defect==0,'i93:Boundary','Boundary constraints failed.');
  constraint=struct('prolongation',P,'top',top,'bottom',bottom,'dirichlet',dirichlet, ...
    'qp_defect',qp_defect,'dirichlet_defect',dirichlet_defect, ...
    'phase_real',cos(config.model.beta*config.model.d),'phase_imag',sin(config.model.beta*config.model.d));
end

%% ==================== Eigenpair delivery ====================
% All requested Ritz modes are retained; only prespecified validity/locality gates select.
function [modes,V,cell_mass,overlaps]=LOCAL_modes(config,mesh,forms,constraint,A,B,mu,V,shift,flags)
  nm=numel(mu);N=config.mesh.half_cells;cell_mass=zeros(nm,2*N+1);modes=struct([]);
  for j=1:nm
    V(:,j)=V(:,j)/sqrt(real(V(:,j)'*B*V(:,j)));
    Av=A*V(:,j);Bv=B*V(:,j);r=norm(Av-mu(j)*Bv)/(norm(Av)+abs(mu(j))*norm(Bv));
    full=constraint.prolongation*V(:,j);
    for c=1:2*N+1, cell_mass(j,c)=real(full'*forms.mass_cells{c}*full);end
    center=cell_mass(j,N+1);core=sum(cell_mass(j,max(1,N):min(2*N+1,N+2)));
    nend=min(config.selection.end_cells,N);ends=sum(cell_mass(j,[1:nend,(2*N+2-nend):(2*N+1)]));
    k=sqrt(max(0,real(mu(j)))); real_positive=real(mu(j))>0&&abs(imag(mu(j)))<config.solver.imaginary_tolerance;
    valid=flags(j)==0&&r<=config.selection.residual_max&&real_positive;
    inwindow=k>=config.window(1)&&k<=config.window(2);
    localized=center>=config.selection.center_mass_min&&core>=config.selection.core_mass_min&&ends<=config.selection.end_mass_max;
    status='OUTSIDE_WINDOW';
    if ~valid,status='SOLVER_INVALID';elseif inwindow&&~localized,status='NOT_LOCALIZED';elseif inwindow,status='LOCALIZED';end
    if strcmp(config.mode,'preflight'),status='PREFLIGHT_ONLY';end
    item=struct('id',j,'shift_id',shift(j),'mu_real',real(mu(j)),'mu_imag',imag(mu(j)), ...
      'k',k,'solver_flag',flags(j),'residual',r,'center_mass',center,'core_mass',core, ...
      'negative_mass',sum(cell_mass(j,1:N)),'positive_mass',sum(cell_mass(j,N+2:end)), ...
      'negative_end_mass',sum(cell_mass(j,1:nend)),'positive_end_mass',sum(cell_mass(j,end-nend+1:end)), ...
      'end_mass',ends,'valid',valid,'in_window',inwindow,'localized',localized, ...
      'duplicate_of',0,'candidate',false,'status',status);
    if j==1,modes=item;else,modes(j)=item;end
  end
  overlaps=abs(V'*B*V);
  [~,order]=sort([modes.residual]); representatives=[];
  for j=order
    if ~modes(j).valid,continue;end
    duplicate=0;
    for r=representatives
      if abs(modes(j).k-modes(r).k)<=config.selection.dedup_k&&overlaps(j,r)>=config.selection.dedup_overlap
        duplicate=r;break;
      end
    end
    modes(j).duplicate_of=duplicate;
    if duplicate==0,representatives(end+1)=j;else,modes(j).status='DUPLICATE';end %#ok<AGROW>
  end
  for j=1:nm
    modes(j).candidate=strcmp(config.mode,'formal')&&modes(j).valid&&modes(j).in_window&& ...
      modes(j).localized&&modes(j).duplicate_of==0;
    if modes(j).candidate,modes(j).status='CANDIDATE';end
  end
end

%% ==================== P2 reference algebra ====================
% These formulas are extracted from I4.1c; no old runtime controller is used.
function [basis,G]=LOCAL_basis(l)
  gl=[-1,1,0;-1,0,1];basis=[l.*(2*l-1),4*l(1)*l(2),4*l(2)*l(3),4*l(3)*l(1)];
  G=zeros(2,6);
  for j=1:3,G(:,j)=(4*l(j)-1)*gl(:,j);end
  G(:,4)=4*(l(1)*gl(:,2)+l(2)*gl(:,1));
  G(:,5)=4*(l(2)*gl(:,3)+l(3)*gl(:,2));
  G(:,6)=4*(l(3)*gl(:,1)+l(1)*gl(:,3));
end

function [lambda,weights]=LOCAL_quadrature(order)
  j=(1:order-1)';b=j./sqrt(4*j.^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));
  [x,idx]=sort(diag(D));w=V(1,idx)'.^2;x=(x+1)/2;
  [r,s]=ndgrid(x,x);[wr,ws]=ndgrid(w,w);xi=r(:);eta=(1-xi).*s(:);
  lambda=[1-xi-eta,xi,eta];weights=wr(:).*ws(:).*(1-xi);
end

function coefficients=LOCAL_map_coefficients(nodes)
  coefficients=[nodes(1,:);-3*nodes(1,:)-nodes(2,:)+4*nodes(4,:); ...
    -3*nodes(1,:)-nodes(3,:)+4*nodes(6,:);2*nodes(1,:)+2*nodes(2,:)-4*nodes(4,:); ...
    4*nodes(1,:)-4*nodes(4,:)+4*nodes(5,:)-4*nodes(6,:);2*nodes(1,:)+2*nodes(3,:)-4*nodes(6,:)];
end

function c=LOCAL_det_coefficients(map)
  a=map(2,:);b=map(3,:);d=map(4,:);e=map(5,:);f=map(6,:);
  cross2=@(x,y)x(1)*y(2)-x(2)*y(1);
  c=[cross2(a,b),cross2(2*d,b)+cross2(a,e),cross2(e,b)+cross2(a,2*f), ...
    cross2(2*d,e),4*cross2(d,f),cross2(e,2*f)];
end

function value=LOCAL_q(c,x,y)
  value=c(1)+c(2)*x+c(3)*y+c(4)*x.^2+c(5)*x.*y+c(6)*y.^2;
end

function minimum=LOCAL_quadratic_triangle_minimum(c)
  candidates=[0,0;1,0;0,1];edges=[c(4),c(2);c(6),c(3);c(4)-c(5)+c(6),c(2)-c(3)+c(5)-2*c(6)];
  for j=1:3
    if abs(edges(j,1))>eps*max(1,norm(edges(j,:),1))
      t=-edges(j,2)/(2*edges(j,1));
      if t>0&&t<1
        if j==1,p=[t,0];elseif j==2,p=[0,t];else,p=[t,1-t];end
        candidates(end+1,:)=p; %#ok<AGROW>
      end
    end
  end
  H=[2*c(4),c(5);c(5),2*c(6)];
  if rcond(H)>64*eps
    p=-H\c(2:3)';
    if all(p>0)&&sum(p)<1,candidates(end+1,:)=p';end
  end
  minimum=min(LOCAL_q(c,candidates(:,1),candidates(:,2)));
end

function LOCAL_json(path,value)
  fid=fopen(path,'w');assert(fid>=0,'i93:IO','Cannot open JSON output.');
  cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end


%% ==================== Portable raw audit export ====================
% Doubles use column-major little-endian order; complex parts are separate columns.
function LOCAL_export(output_dir,mesh,forms,constraint,A,B,V,mu,cell_mass,overlaps)
  data=struct('points',mesh.points,'p2_points',mesh.p2_points,'triangles',mesh.triangles, ...
    'triangle_p2',mesh.triangle_p2,'edges',mesh.edges,'interface_edges',mesh.interface_edges, ...
    'interface_parameters',mesh.interface_parameters,'material',mesh.material,'cell_id',mesh.cell_id, ...
    'element_mass',forms.element_mass,'element_area',forms.element_area, ...
    'determinant_coefficients',forms.determinant_coefficients,'V_real',real(V),'V_imag',imag(V), ...
    'mu_real',real(mu),'mu_imag',imag(mu),'cell_mass',cell_mass,'overlaps',overlaps, ...
    'top',constraint.top,'bottom',constraint.bottom,'dirichlet',constraint.dirichlet);
  matrices={A,B,constraint.prolongation,forms.stiffness_full,forms.mass_full};
  names={'A','B','P','K_full','M_full'};metadata=struct();
  for j=1:numel(names)
    [r,c,v]=find(matrices{j});data.(names{j})=[r,c,real(v),imag(v)];
    metadata.([names{j},'_matrix_size'])=size(matrices{j});
  end
  fields=fieldnames(data);metadata.arrays=struct();
  for j=1:numel(fields)
    name=fields{j};value=double(data.(name));
    fid=fopen(fullfile(output_dir,[name,'.bin']),'w','ieee-le');
    assert(fid>=0,'i93:Export','Cannot create audit binary.');
    fwrite(fid,value,'double');fclose(fid);metadata.arrays.(name)=size(value);
  end
  metadata.storage='float64 little-endian column-major';
  LOCAL_json(fullfile(output_dir,'raw-audit.json'),metadata);
end
