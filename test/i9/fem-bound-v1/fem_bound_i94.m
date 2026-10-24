function fem_bound_i94(input_path,output_dir)
%FEM_BOUND_I94 Evaluate an explicit nonzero Piola RT2 flux for a frozen FEM field.
% Purpose: Reuse explicit I9.3 MAT input and evaluate theory B.1 (9),(15).
% Input: input_path names the original FEM evidence.mat, never BIE evidence.
% Output: frozen field, RT2 moments/coefficient/edge evidence and direct norms.
% Based on: fem_i9_run.m P2 conventions; fem-bound/theory.md Revision B.1.
% Main changes: no eigenproblem; inverse Piola interpolation, shared-edge average,
%   local true-material classification and direct residual evaluation.
% Numerical goal: ordinary-arithmetic estimate, not a certified upper bound.
  config=fem_bound_i94_config(); maxNumCompThreads(config.threads);
  if ~isfolder(output_dir),mkdir(output_dir);end
  started=tic;stage='input';timings=struct();
  try
    timer=tic;data=load(input_path);mesh=data.mesh;source_config=data.config;
    assert(isequal(source_config.model,struct('beta',.5,'d',1,'L',1,'star_scale',1, ...
      'rho_center',4,'rho_negative',17,'rho_positive',17,'rho_background',1, ...
      'a_negative',.12,'a_positive',.20,'radius',.2)), ...
      'i94:Model','Input must be the frozen native FEM material-4 model.');
    assert(source_config.mesh.half_cells==6&&source_config.mesh.subdivisions==12&& ...
      source_config.mesh.interface_segments==80,'i94:Mesh','Frozen FEM mesh mismatch.');
    id=config.candidate_index;assert(data.modes(id).candidate, ...
      'i94:Candidate','Requested native representative was not delivered.');
    assert(data.modes(id).k==config.k_h,'i94:Frequency','Input candidate differs.');
    reduced=data.eigenvectors(:,id);P=LOCAL_constraint(mesh,config.beta);
    full_field=P*reduced;input_checks=LOCAL_input(mesh,P,full_field,data);
    nt=size(mesh.triangles,1);nodes=reshape(mesh.p2_points(mesh.triangle_p2(:),:),nt,6,2);
    field_nodes=reshape(full_field(mesh.triangle_p2),nt,6);
    mapx=LOCAL_poly(nodes(:,:,1));mapy=LOCAL_poly(nodes(:,:,2));mapu=LOCAL_poly(field_nodes);
    timings.input_checks_seconds=toc(timer);clear data P;
    fprintf('STAGE input: %d cells, fixed native field, k=%.17g\n',nt,config.k_h);
    stage='reference_and_moments';timer=tic;
    [D,basis_checks]=LOCAL_dual();
    moments0=LOCAL_moments(mapx,mapy,mapu,config.edge_moment_order,config.volume_moment_order);
    coeff0=moments0/D.';
    [moments,edge_data]=LOCAL_average(mesh,moments0,config.beta);
    coeff=moments/D.';
    flux_checks=LOCAL_flux_check(mesh,mapx,mapy,coeff,moments,moments0,edge_data,D);
    timings.flux_construction_seconds=toc(timer);
    fprintf('STAGE RT2: nonzero coefficient norm %.8g; moment continuity %.3g\n',norm(coeff,'fro'),flux_checks.moment_mismatch);
    stage='material_classification';timer=tic;
    [leaves,classification,curves]=LOCAL_partition(mesh,mapx,mapy,config);
    timings.classification_seconds=toc(timer);
    fprintf('STAGE material: %d leaves, %d unresolved at depth %d\n',size(leaves,1),sum(leaves(:,8)==0),config.maximum_subdivision);
    stage='direct_norms';timer=tic;
    [element_values,unknown_values]=LOCAL_integrate(leaves,mesh,mapx,mapy,mapu,coeff0,coeff,curves,config,config.evaluation_orders(1));
    timings.Q8_diagnostic_seconds=toc(timer);
    stage='integral_diagnostic';timer=tic;
    [element_check,unknown_check]=LOCAL_integrate(leaves,mesh,mapx,mapy,mapu,coeff0,coeff,curves,config,config.evaluation_orders(2));
    timings.Q10_formal_seconds=toc(timer);
    stage='end_trace';timer=tic;
    [end_squared,end_native_squared]=LOCAL_ends(mesh,mapx,mapy,mapu,coeff,edge_data,16);
    end_check=LOCAL_ends(mesh,mapx,mapy,mapu,coeff,edge_data,20);
    timings.end_trace_seconds=toc(timer);
    stage='scalar_assembly';timer=tic;
    totals=sum(element_check,1);lower=sum(unknown_check(:,1:2),1);upper=sum(unknown_check(:,3:4),1);
    C_end=(2*sqrt(config.s*config.rho_min))^(-.5);
    mass=totals(1);gradient_squared=totals(2);body_weighted_squared=totals(3);
    M_squared=gradient_squared+body_weighted_squared/config.s;
    end_norms=sqrt(end_check);eta=sqrt(M_squared)+C_end*sum(end_norms);
    U=sqrt(mass);tau=eta/U;R=tau/2*(tau+sqrt(tau^2+4*(config.mu_h+config.s)));
    a=sqrt(element_check(:,4));b=sqrt(element_check(:,5));r=sqrt(element_check(:,6));
    l0=sqrt(element_check(:,7));l1=sqrt(element_check(:,8));
    gamma=2*C_end^2;W_squared=sum((a+l0).^2)+sum((r+b+l1).^2)/config.s+gamma*sum(end_check);
    diagnostic=struct('quadrature_absolute_change',abs(sum(element_check-element_values,1)), ...
      'end_squared_absolute_change',abs(end_check-end_squared), ...
      'unresolved_material_mass_range',lower(1)+[0,upper(1)-lower(1)], ...
      'unresolved_material_body_range',lower(2)+[0,upper(2)-lower(2)], ...
      'unresolved_material_bulk_width',(upper(2)-lower(2))/config.s, ...
      'unknown_semantics','Quadrature-based discrete-material envelope, not interval arithmetic', ...
      'W_squared',W_squared,'W_eta',sqrt(2*W_squared),'gamma',gamma, ...
      'native_end_squared',end_native_squared,'material_mismatch_squared',totals(9), ...
      'unresolved_primary_area',sum(unknown_check(:,5)));
    values=struct('k_h',config.k_h,'mu_h',config.mu_h,'s',config.s,'mass_squared',mass, ...
      'U',U,'gradient_difference_squared',gradient_squared,'body_defect_weighted_squared',body_weighted_squared, ...
      'M_squared',M_squared,'C_end',C_end,'end_squared',end_check,'end_norms',end_norms, ...
      'eta',eta,'tau',tau,'R',R,'radius_reference_ratio',R/config.radius_reference, ...
      'radius_fine_ratio',R/config.radius_fine_reference,'flux_norm_squared',totals(10), ...
      'representation_gradient_squared',totals(4),'representation_divergence_squared',totals(5), ...
      'native_body_squared',totals(6),'lifting_gradient_squared',totals(7),'lifting_divergence_squared',totals(8));
    assert(all(isfinite(struct2array(values)))&&mass>0&&totals(10)>0, ...
      'i94:Finite','Result must be finite with nonzero native field and flux.');
    timings.scalar_seconds=toc(timer);
    result=struct('status',config.status,'config',config,'source_config',source_config, ...
      'input',input_checks,'basis_checks',basis_checks,'flux_checks',flux_checks, ...
      'classification',classification,'values',values,'diagnostic',diagnostic,'timings',timings, ...
      'environment',struct('version',version,'platform',computer,'threads',maxNumCompThreads, ...
      'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS')));
    stage='save_export';timer=tic;
    save(fullfile(output_dir,'evidence.mat'),'config','source_config','mesh','reduced','full_field', ...
      'mapx','mapy','mapu','D','moments0','moments','coeff0','coeff','edge_data','leaves', ...
      'element_values','element_check','unknown_values','unknown_check','end_squared','end_check','result','-v7');
    LOCAL_export(output_dir,struct('D',D,'moments0',moments0,'moments',moments, ...
      'coeff0',coeff0,'coeff',coeff,'element_values',element_values,'element_check',element_check, ...
      'unknown_check',unknown_check,'full_field',full_field,'reduced',reduced, ...
      'mapx',mapx,'mapy',mapy,'mapu',mapu,'leaves',leaves, ...
      'edge_ids',edge_data.ids,'edge_signs',edge_data.signs,'edge_epsilon',edge_data.epsilon, ...
      'edge_kappa',edge_data.kappa,'periodic_edges',edge_data.periodic,'global_moments',edge_data.global_moments));
    result.timings.save_export_seconds=toc(timer);result.timings.matlab_function_seconds=toc(started);
    LOCAL_json(fullfile(output_dir,'result.json'),result);
    fprintf('COMPLETE R=%.17g eta=%.17g U=%.17g time=%.3fs\n',R,eta,U,toc(started));
  catch err
    LOCAL_json(fullfile(output_dir,'failure.json'),struct('stage',stage,'identifier',err.identifier, ...
      'message',err.message,'stack',err.stack,'report',getReport(err,'extended','hyperlinks','off'), ...
      'config',config,'elapsed_seconds',toc(started)));
    rethrow(err);
  end
end

%% ==================== Frozen native input ====================
% Restore exactly the saved reduced coordinates with the declared beta phase.
function P=LOCAL_constraint(mesh,beta)
  p=mesh.p2_points;n=size(p,1);tol=1e-11;
  top=find(abs(p(:,2)-.5)<tol);bot=find(abs(p(:,2)+.5)<tol);
  [~,a]=sort(p(top,1));top=top(a);[~,a]=sort(p(bot,1));bot=bot(a);
  dir=find(abs(p(:,1)-mesh.xmin)<tol|abs(p(:,1)-mesh.xmax)<tol);
  master=(1:n)';master(top)=bot;active=true(n,1);active(dir)=false;
  masters=unique(master(active));[found,index]=ismember(master,masters);
  phase=ones(n,1);phase(top)=exp(1i*beta);ids=find(active&found);
  P=sparse(ids,index(ids),phase(ids),n,numel(masters));
end
function check=LOCAL_input(mesh,P,u,data)
  tr=mesh.triangles;nt=size(tr,1);nv=size(mesh.points,1);ne=size(mesh.edges,1);
  [edges,~,ix]=unique(sort([tr(:,[1,2]);tr(:,[2,3]);tr(:,[3,1])],2),'rows');
  incidence=accumarray(ix,1);assert(isequal(edges,mesh.edges)&&all(incidence<=2), ...
    'i94:Topology','Shared edge topology is inconsistent.');
  assert(isequal(mesh.triangle_p2(:,4:6),nv+reshape(ix,nt,3)), ...
    'i94:P2','Six-node geometry is not edge-shared.');
  boundary=edges(incidence==1,:);b1=mesh.points(boundary(:,1),:);b2=mesh.points(boundary(:,2),:);
  exterior=(b1(:,1)==mesh.xmin&b2(:,1)==mesh.xmin)|(b1(:,1)==mesh.xmax&b2(:,1)==mesh.xmax)| ...
    (b1(:,2)==-.5&b2(:,2)==-.5)|(b1(:,2)==.5&b2(:,2)==.5);
  assert(all(exterior)&&nv-ne+nt==1,'i94:Coverage','Boundary or disk topology failed.');
  connected=max(conncomp(graph(edges(:,1),edges(:,2),[],nv)))==1;
  bnodes=unique(boundary(:));[~,bi]=ismember(boundary,bnodes);
  bgraph=graph(bi(:,1),bi(:,2),[],numel(bnodes));
  boundary_cycle=all(degree(bgraph)==2)&&max(conncomp(bgraph))==1;
  assert(connected&&boundary_cycle,'i94:Connectivity','Mesh or boundary has multiple components.');
  bmid=mesh.p2_points(nv+find(incidence==1),:);
  midpoint_error=max(abs(bmid-(b1+b2)/2),[],'all');
  assert(midpoint_error<2e-15,'i94:BoundaryMidpoint','Exterior quadratic edge is not numerically straight and monotone.');
  nodes=reshape(mesh.p2_points(mesh.triangle_p2(:),:),nt,6,2);
  ax=LOCAL_poly(nodes(:,:,1));ay=LOCAL_poly(nodes(:,:,2));
  dc=[ax(:,2).*ay(:,3)-ax(:,3).*ay(:,2), ...
    2*ax(:,4).*ay(:,3)+ax(:,2).*ay(:,5)-ax(:,5).*ay(:,2)-2*ax(:,3).*ay(:,4), ...
    ax(:,5).*ay(:,3)+2*ax(:,2).*ay(:,6)-2*ax(:,6).*ay(:,2)-ax(:,3).*ay(:,5), ...
    2*ax(:,4).*ay(:,5)-2*ax(:,5).*ay(:,4), ...
    4*(ax(:,4).*ay(:,6)-ax(:,6).*ay(:,4)),2*ax(:,5).*ay(:,6)-2*ax(:,6).*ay(:,5)];
  determinant_saved_difference=max(abs(dc-data.forms.determinant_coefficients),[],'all');
  assert(determinant_saved_difference<1e-14,'i94:JacobianIdentity','Saved and current geometry Jacobian differ.');
  detmin=Inf;
  for j=1:nt,detmin=min(detmin,LOCAL_detmin(dc(j,:)));end
  assert(detmin>0,'i94:Jacobian','Nonpositive full-reference Jacobian.');
  phase=exp(.5i);ct=data.constraint;
  check=struct('triangles',nt,'vertices',nv,'edges',ne,'boundary_edges',sum(incidence==1), ...
    'connected',connected,'single_boundary_cycle',boundary_cycle,'boundary_midpoint_error',midpoint_error, ...
    'determinant_saved_difference',determinant_saved_difference,'candidate_index',1,'candidate_k',data.modes(1).k,'jacobian_minimum',detmin, ...
    'restored_P_difference',norm(P-ct.prolongation,'fro'), ...
    'qp_field_defect',max(abs(u(ct.top)-phase*u(ct.bottom))), ...
    'end_value_defect',max(abs(u(ct.dirichlet))),'full_field_norm',norm(u), ...
    'original_weighted_mass',real(u'*data.forms.mass_full*u), ...
    'coverage_identity','Shared quadratic edges, positive whole-cell Jacobian, disk topology, exact rectangle boundary');
  assert(check.restored_P_difference<1e-13&&check.qp_field_defect<1e-13&&check.end_value_defect==0, ...
    'i94:Field','Native phase or Dirichlet identity failed.');
end
function c=LOCAL_poly(v)
  c=[v(:,1),-3*v(:,1)-v(:,2)+4*v(:,4),-3*v(:,1)-v(:,3)+4*v(:,6), ...
    2*v(:,1)+2*v(:,2)-4*v(:,4),4*v(:,1)-4*v(:,4)+4*v(:,5)-4*v(:,6), ...
    2*v(:,1)+2*v(:,3)-4*v(:,6)];
end
function minimum=LOCAL_detmin(c)
  pts=[0,0;1,0;0,1];e=[c(4),c(2);c(6),c(3);c(4)-c(5)+c(6),c(2)-c(3)+c(5)-2*c(6)];
  for j=1:3
    if abs(e(j,1))>eps*max(1,norm(e(j,:),1))
      t=-e(j,2)/(2*e(j,1));
      if t>0&&t<1
        if j==1,pts(end+1,:)=[t,0];elseif j==2,pts(end+1,:)=[0,t];else,pts(end+1,:)=[t,1-t];end %#ok<AGROW>
      end
    end
  end
  H=[2*c(4),c(5);c(5),2*c(6)];
  if rcond(H)>64*eps,p=-H\c(2:3)';if all(p>0)&&sum(p)<1,pts(end+1,:)=p';end,end
  x=pts(:,1);y=pts(:,2);minimum=min(c(1)+c(2)*x+c(3)*y+c(4)*x.^2+c(5)*x.*y+c(6)*y.^2);
end

%% ==================== RT2 interpolation and conforming edge average ====================
% Reference moments use CCW edges and shifted Legendre polynomials, theory (23)-(26).
function [D,checks]=LOCAL_dual()
  [z,w]=LOCAL_gauss(6);D=zeros(15);
  for e=1:3
    [x,y,n]=LOCAL_edge(e,z);[vx,vy]=LOCAL_rt(x,y);L=[ones(size(z)),2*z-1,6*z.^2-6*z+1];
    D((e-1)*3+(1:3),:)=L'*(w.*(n(1)*vx+n(2)*vy));
  end
  [x,y,w]=LOCAL_duffy(5);[vx,vy]=LOCAL_rt(x,y);q=[ones(size(x)),x,y];
  D(10:12,:)=q'*(w.*vx);D(13:15,:)=q'*(w.*vy);
  % All exact entries are rational with small factorial denominators.
  [num,den]=rat(D,1e-13);D=num./den;
  invD=D\eye(15);err=norm(D*invD-eye(15),'inf');
  checks=struct('dual_identity',err,'condition_number',cond(D),'rank',rank(D), ...
    'generator_order','P2 e_x, P2 e_y, (x,y)x^2, (x,y)xy, (x,y)y^2');
  assert(err<1e-10&&rank(D)==15,'i94:RTBasis','RT2 reference dual basis failed.');
  % Reproduce an affine physical P2 field: grad(x^2+xy+2y^2+x).
  mx=[0,2,.3,0,0,0];my=[0,.2,1.5,0,0,0];
  % Compose u=x_phys^2+x_phys*y_phys+2*y_phys^2+x_phys.
  u=[0,2,.3,4+.4+.08,1.2+3.06+1.2,.09+.45+4.5];
  m=LOCAL_moments(mx,my,u,12,8);a=m/D';
  [xp,yp]=ndgrid([.12,.25,.4],[.1,.2]);xp=xp(:);yp=yp(:);
  [~,gx,gy,lap,J,d]=LOCAL_field(repmat(mx,numel(xp),1),repmat(my,numel(xp),1),repmat(u,numel(xp),1),xp,yp);
  [rx,ry,rd]=LOCAL_rt(xp,yp);px=(J(:,1).*(rx*a')+J(:,2).*(ry*a'))./d;
  py=(J(:,3).*(rx*a')+J(:,4).*(ry*a'))./d;
  checks.affine_gradient_reproduction=max(abs([px-gx;py-gy]));
  checks.affine_divergence_reproduction=max(abs((rd*a')./d-lap));
  assert(max(checks.affine_gradient_reproduction,checks.affine_divergence_reproduction)<1e-9, ...
    'i94:AffineRT','Affine P2 RT2 reproduction failed.');
end
function [vx,vy,div]=LOCAL_rt(x,y)
  x=x(:);y=y(:);o=ones(size(x));z=zeros(numel(x),6);p=[o,x,y,x.^2,x.*y,y.^2];
  vx=[p,z,x.^3,x.^2.*y,x.*y.^2];vy=[z,p,x.^2.*y,x.*y.^2,y.^3];
  div=[0*x,o,0*x,2*x,y,0*x,0*x,0*x,o,0*x,x,2*y,4*x.^2,4*x.*y,4*y.^2];
end
function m=LOCAL_moments(mx,my,mu,ne,nv)
  nt=size(mx,1);m=complex(zeros(nt,15));[z,w]=LOCAL_gauss(ne);
  for e=1:3
    [x,y,n]=LOCAL_edge(e,z);L=[ones(size(z)),2*z-1,6*z.^2-6*z+1];
    for q=1:numel(z)
      [~,gx,gy,~,J]=LOCAL_field(mx,my,mu,x(q),y(q));
      qx=J(:,4).*gx-J(:,2).*gy;qy=-J(:,3).*gx+J(:,1).*gy;
      m(:,(e-1)*3+(1:3))=m(:,(e-1)*3+(1:3))+w(q)*(qx*n(1)+qy*n(2))*L(q,:);
    end
  end
  [x,y,w]=LOCAL_duffy(nv);
  for q=1:numel(w)
    [~,gx,gy,~,J]=LOCAL_field(mx,my,mu,x(q),y(q));
    qx=J(:,4).*gx-J(:,2).*gy;qy=-J(:,3).*gx+J(:,1).*gy;
    m(:,10:12)=m(:,10:12)+w(q)*qx*[1,x(q),y(q)];
    m(:,13:15)=m(:,13:15)+w(q)*qy*[1,x(q),y(q)];
  end
end
function [moments,E]=LOCAL_average(mesh,m0,beta)
  tr=mesh.triangles;nt=size(tr,1);ne=size(mesh.edges,1);
  starts=[tr(:,1);tr(:,2);tr(:,3)];ends=[tr(:,2);tr(:,3);tr(:,1)];
  [~,eid]=ismember(sort([starts,ends],2),mesh.edges,'rows');ids=reshape(eid,nt,3);
  pa=mesh.points(starts,:);pb=mesh.points(ends,:);
  kappa=ones(3*nt,1);kappa(pa(:,1)>pb(:,1)|(pa(:,1)==pb(:,1)&pa(:,2)>pb(:,2)))=-1;
  % Interior canonical normal is right of lexicographic tangent. On the y
  % seams use +e_y; at the two artificial ends use the actual exterior normal.
  epsilon=kappa;mid=(pa+pb)/2;
  epsilon(abs(mid(:,2)-.5)<1e-12|abs(mid(:,2)+.5)<1e-12)=-epsilon(abs(mid(:,2)-.5)<1e-12|abs(mid(:,2)+.5)<1e-12);
  epsilon(abs(mid(:,1)-mesh.xmin)<1e-12)=-epsilon(abs(mid(:,1)-mesh.xmin)<1e-12);
  signs=epsilon.*kappa.^(0:2);raw=reshape(permute(reshape(m0(:,1:9),nt,3,3),[1,3,2]),3*nt,3);
  canonical=raw.*signs;inc=accumarray(eid,1);global_moments=complex(zeros(ne,3));
  for m=1:3,global_moments(:,m)=accumarray(eid,canonical(:,m))./inc;end
  emid=(mesh.points(mesh.edges(:,1),:)+mesh.points(mesh.edges(:,2),:))/2;
  top=find(abs(emid(:,2)-.5)<1e-12);bottom=find(abs(emid(:,2)+.5)<1e-12);
  [~,a]=sort(emid(top,1));top=top(a);[~,a]=sort(emid(bottom,1));bottom=bottom(a);
  assert(numel(top)==numel(bottom)&&max(abs(emid(top,1)-emid(bottom,1)))<1e-12, ...
    'i94:QPEdge','Periodic edge pairing failed.');
  phase=exp(1i*beta);average=(global_moments(bottom,:)+conj(phase)*global_moments(top,:))/2;
  global_moments(bottom,:)=average;global_moments(top,:)=phase*average;
  local=global_moments(eid,:).*signs;moments=m0;
  moments(:,1:9)=reshape(permute(reshape(local,nt,3,3),[1,3,2]),nt,9);
  E=struct('ids',ids,'epsilon',reshape(epsilon,nt,3),'kappa',reshape(kappa,nt,3), ...
    'signs',reshape(signs,nt,3,3),'global_moments',global_moments,'periodic',[bottom,top], ...
    'incidence',inc,'midpoints',emid);
end
function checks=LOCAL_flux_check(mesh,mx,my,c,m,m0,E,D)
  nt=size(c,1);raw=reshape(permute(reshape(m(:,1:9),nt,3,3),[1,3,2]),3*nt,3);
  signs=reshape(E.signs,3*nt,3);g=E.global_moments(E.ids(:),:);
  defect=max(abs(raw.*signs-g),[],'all');
  ends=find(abs(E.midpoints(:,1)-mesh.xmin)<1e-12|abs(E.midpoints(:,1)-mesh.xmax)<1e-12);
  [ti,le]=find(ismember(E.ids,ends));enddiff=0;
  for j=1:numel(ti),ix=(le(j)-1)*3+(1:3);enddiff=max(enddiff,max(abs(m(ti(j),ix)-m0(ti(j),ix))));end
  checks=struct('moment_mismatch',defect,'end_moment_change',enddiff, ...
    'internal_moment_change',max(abs(m(:,10:15)-m0(:,10:15)),[],'all'), ...
    'dual_recovery',max(abs(c*D'-m),[],'all'),'coefficient_norm',norm(c,'fro'), ...
    'periodic_moment_defect',max(abs(E.global_moments(E.periodic(:,2),:)- ...
    exp(.5i)*E.global_moments(E.periodic(:,1),:)),[],'all'));
  assert(defect<1e-12&&enddiff<1e-12&&checks.dual_recovery<1e-10, ...
    'i94:FluxConstraints','RT2 edge or end identity failed.');
  % Physical trace matching, including reversal and Piola speed, at 5 points.
  [z,~]=LOCAL_gauss(5);trace=complex(zeros(size(E.global_moments,1),5));seen=zeros(size(trace));jump=0;
  for e=1:3
    [x,y,n]=LOCAL_edge(e,z);k=E.kappa(:,e);sg=E.epsilon(:,e);
    for q=1:5
      [vx,vy]=LOCAL_rt(x(q),y(q));[~,~,~,~,J]=LOCAL_field(mx,my,zeros(size(mx)),x(q),y(q));
      if e==1,tx=J(:,1);ty=J(:,3);elseif e==2,tx=-J(:,1)+J(:,2);ty=-J(:,3)+J(:,4);else,tx=-J(:,2);ty=-J(:,4);end
      val=((c*vx')*n(1)+(c*vy')*n(2))./hypot(tx,ty).*sg;
      for t=1:nt
        qq=q;if k(t)<0,qq=6-q;end
        edge=E.ids(t,e);
        if seen(edge,qq)>0,jump=max(jump,abs(trace(edge,qq)-val(t)));else,trace(edge,qq)=val(t);end
        seen(edge,qq)=seen(edge,qq)+1;
      end
    end
  end
  qp=max(abs(trace(E.periodic(:,2),:)-exp(.5i)*trace(E.periodic(:,1),:)),[],'all');
  checks.physical_internal_normal_jump=jump;checks.physical_qp_normal_jump=qp;
  assert(max(jump,qp)<1e-8,'i94:PiolaTrace','Physical Piola normal continuity failed.');
end
function [x,y,n]=LOCAL_edge(e,t)
  if e==1,x=t;y=0*t;n=[0,-1];elseif e==2,x=1-t;y=t;n=[1,1];else,x=0*t;y=1-t;n=[-1,0];end
end

%% ==================== Local true-material subdivision ====================
% Bernstein image boxes and analytic second-derivative tubes classify each leaf.
function [leaves,info,curves]=LOCAL_partition(mesh,mx,my,config)
  ng=config.curve_segments;t=(0:ng)'*2*pi/ng;curves=cell(13,1);
  for cell_id=-6:6
    if cell_id==0
      x=.3*cos(t)+.03*cos(6*t)+.03*cos(4*t);y=.2*sin(t)+.03*sin(6*t)-.03*sin(4*t);
      M2=hypot(1.86,1.76);
    else
      a=.12;if cell_id>0,a=.20;end
      R=.2/sqrt(1+a*a/2);r=R*(1+a*cos(3*t));x=r.*cos(t);y=r.*sin(t);M2=sqrt(2)*R*(1+10*a);
    end
    radius=M2*(2*pi/ng)^2/8+64*eps;
    curves{cell_id+7}=struct('x',x+cell_id,'y',y,'radius',radius,'M2',M2, ...
      'box',[min(x(1:end-1),x(2:end))+cell_id-radius,max(x(1:end-1),x(2:end))+cell_id+radius, ...
      min(y(1:end-1),y(2:end))-radius,max(y(1:end-1),y(2:end))+radius]);
  end
  nt=size(mx,1);parts=cell(nt,1);
  for k=1:nt
    c=mesh.cell_id(k);curve=curves{c+7};
    parts{k}=LOCAL_split(k,[0,0;1,0;0,1],0,(1:ng)',mx(k,:),my(k,:),c,curve,config.maximum_subdivision);
  end
  leaves=vertcat(parts{:});info=struct('leaves',size(leaves,1),'unresolved_leaves',sum(leaves(:,8)==0), ...
    'max_depth',max(leaves(:,9)),'curve_segments',ng,'curve_tube_radii',cellfun(@(v)v.radius,curves)', ...
    'candidate_set',[1,4,17],'classification','Local Bernstein image bbox versus analytic curve tubes; unresolved retained');
end
function rows=LOCAL_split(k,v,level,candidates,mx,my,c,curve,maxdepth)
  ref=[v;(v(1,:)+v(2,:))/2;(v(2,:)+v(3,:))/2;(v(3,:)+v(1,:))/2];
  b=LOCAL_monomial(ref(:,1),ref(:,2));xy=[b*mx',b*my'];
  bern=[xy(1:3,:);2*xy(4,:)-(xy(1,:)+xy(2,:))/2; ...
    2*xy(5,:)-(xy(2,:)+xy(3,:))/2;2*xy(6,:)-(xy(3,:)+xy(1,:))/2];
  lo=min(bern,[],1)-64*eps;hi=max(bern,[],1)+64*eps;box=curve.box(candidates,:);
  keep=box(:,1)<=hi(1)&box(:,2)>=lo(1)&box(:,3)<=hi(2)&box(:,4)>=lo(2);candidates=candidates(keep);
  if isempty(candidates)
    p=mean(v,1);b=LOCAL_monomial(p(1),p(2));rho=LOCAL_rho(b*mx',b*my',c);
    rows=[k,reshape(v',1,6),rho,level];return
  end
  if level==maxdepth,rows=[k,reshape(v',1,6),0,level];return,end
  a=(v(1,:)+v(2,:))/2;b=(v(2,:)+v(3,:))/2;d=(v(3,:)+v(1,:))/2;
  child={ [v(1,:);a;d], [a;v(2,:);b], [d;b;v(3,:)], [a;b;d]};out=cell(4,1);
  for j=1:4,out{j}=LOCAL_split(k,child{j},level+1,candidates,mx,my,c,curve,maxdepth);end
  rows=vertcat(out{:});
end
function rho=LOCAL_rho(x,y,c)
  x=x(:);y=y(:);if isscalar(c),c=repmat(c,size(x));end
  xx=x-c;rho=ones(size(x));lead=c~=0;
  a=.12*ones(size(x));a(c>0)=.2;theta=atan2(y,xx);r=.2*(1+a.*cos(3*theta))./sqrt(1+a.^2/2);
  rho(lead&hypot(xx,y)<r)=17;
  ids=find(~lead);
  if ~isempty(ids)
    xp=xx(ids);yp=y(ids);t=atan2(yp/.2,xp/.3);
    for it=1:12
      [cx,cy,dx,dy]=LOCAL_star(t);f=cx.*yp-cy.*xp;df=dx.*yp-dy.*xp;
      step=zeros(size(t));nz=abs(df)>1e-30;step(nz)=f(nz)./df(nz);t=t-max(-.2,min(.2,step));
    end
    [cx,cy]=LOCAL_star(t);inside=hypot(xp,yp)<hypot(cx,cy);rho(ids(inside))=4;
  end
end
function [x,y,dx,dy]=LOCAL_star(t)
  x=.3*cos(t)+.03*cos(6*t)+.03*cos(4*t);y=.2*sin(t)+.03*sin(6*t)-.03*sin(4*t);
  dx=-.3*sin(t)-.18*sin(6*t)-.12*sin(4*t);dy=.2*cos(t)+.18*cos(6*t)-.12*cos(4*t);
end

%% ==================== Direct norms and witness decomposition ====================
% Form complex differences before squaring; rho_h is diagnostic only.
function [element,unknown]=LOCAL_integrate(leaves,mesh,mx,my,mu,c0,c,curves,config,order) %#ok<INUSD>
  nt=size(mx,1);element=zeros(nt,10);unknown=zeros(nt,5);[qx,qy,qw]=LOCAL_duffy(order);
  for start=1:config.batch_size:size(leaves,1)
    ids=start:min(start+config.batch_size-1,size(leaves,1));leaf=leaves(ids,:);t=leaf(:,1);
    va=leaf(:,2:3);vb=leaf(:,4:5);vc=leaf(:,6:7);ab=vb-va;ac=vc-va;
    scale=ab(:,1).*ac(:,2)-ab(:,2).*ac(:,1);assert(all(scale>0),'i94:Leaf','Reference leaf orientation failed.');
    sumv=zeros(numel(ids),10);sumunknown=zeros(numel(ids),5);un=leaf(:,8)==0;
    for q=1:numel(qw)
      xx=va(:,1)+qx(q)*ab(:,1)+qy(q)*ac(:,1);yy=va(:,2)+qx(q)*ab(:,2)+qy(q)*ac(:,2);
      [u,gx,gy,lap,J,d,pxy]=LOCAL_field(mx(t,:),my(t,:),mu(t,:),xx,yy);
      [vx,vy,div]=LOCAL_rt(xx,yy);hx=sum(vx.*c(t,:),2);hy=sum(vy.*c(t,:),2);dh=sum(div.*c(t,:),2);
      h0x=sum(vx.*c0(t,:),2);h0y=sum(vy.*c0(t,:),2);dh0=sum(div.*c0(t,:),2);
      px=(J(:,1).*hx+J(:,2).*hy)./d;py=(J(:,3).*hx+J(:,4).*hy)./d;dp=dh./d;
      p0x=(J(:,1).*h0x+J(:,2).*h0y)./d;p0y=(J(:,3).*h0x+J(:,4).*h0y)./d;dp0=dh0./d;
      rho=leaf(:,8);rho(un)=LOCAL_rho(pxy(un,1),pxy(un,2),mesh.cell_id(t(un)));
      w=qw(q)*scale.*d;
      v=[rho.*abs(u).^2,abs(gx-px).^2+abs(gy-py).^2,abs(dp+config.mu_h*rho.*u).^2./rho, ...
        abs(gx-p0x).^2+abs(gy-p0y).^2,abs(dp0-lap).^2./rho,abs(lap+config.mu_h*rho.*u).^2./rho, ...
        abs(px-p0x).^2+abs(py-p0y).^2,abs(dp-dp0).^2./rho, ...
        config.mu_h^2*(rho-mesh.material(t)).^2.*abs(u).^2./rho,abs(px).^2+abs(py).^2];
      sumv=sumv+w.*v;
      if any(un)
        ru=config.material_candidates;mass=abs(u(un)).^2.*ru;body=abs(dp(un)+config.mu_h*u(un).*ru).^2./ru;
        sumunknown(un,:)=sumunknown(un,:)+w(un).*[min(mass,[],2),min(body,[],2),max(mass,[],2),max(body,[],2),ones(sum(un),1)];
      end
    end
    for j=1:10,element(:,j)=element(:,j)+accumarray(t,sumv(:,j),[nt,1]);end
    for j=1:5,unknown(:,j)=unknown(:,j)+accumarray(t,sumunknown(:,j),[nt,1]);end
  end
end
function [squared,native]=LOCAL_ends(mesh,mx,my,mu,c,E,order)
  [z,w]=LOCAL_gauss(order);squared=[0,0];native=[0,0];
  for side=1:2
    loc=mesh.xmin;if side==2,loc=mesh.xmax;end
    edges=find(abs(E.midpoints(:,1)-loc)<1e-12);[ti,le]=find(ismember(E.ids,edges));
    for j=1:numel(ti)
      t=ti(j);e=le(j);[x,y,n]=LOCAL_edge(e,z);[vx,vy]=LOCAL_rt(x,y);
      [~,gx,gy,~,J]=LOCAL_field(repmat(mx(t,:),order,1),repmat(my(t,:),order,1),repmat(mu(t,:),order,1),x,y);
      if e==1,tx=J(:,1);ty=J(:,3);elseif e==2,tx=-J(:,1)+J(:,2);ty=-J(:,3)+J(:,4);else,tx=-J(:,2);ty=-J(:,4);end
      speed=hypot(tx,ty);hn=(vx*c(t,:)')*n(1)+(vy*c(t,:)')*n(2);
      squared(side)=squared(side)+sum(w.*abs(hn).^2./speed);
      native(side)=native(side)+sum(w.*abs(gx.*ty-gy.*tx).^2./speed);
    end
  end
end
function [u,gx,gy,lap,J,d,physical]=LOCAL_field(mx,my,mu,x,y)
  n=size(mx,1);if isscalar(x),x=repmat(x,n,1);y=repmat(y,n,1);end
  x=x(:);y=y(:);b=LOCAL_monomial(x,y);u=sum(b.*mu,2);
  ux=mu(:,2)+2*mu(:,4).*x+mu(:,5).*y;uy=mu(:,3)+mu(:,5).*x+2*mu(:,6).*y;
  j11=mx(:,2)+2*mx(:,4).*x+mx(:,5).*y;j12=mx(:,3)+mx(:,5).*x+2*mx(:,6).*y;
  j21=my(:,2)+2*my(:,4).*x+my(:,5).*y;j22=my(:,3)+my(:,5).*x+2*my(:,6).*y;
  d=j11.*j22-j12.*j21;J=[j11,j12,j21,j22];
  gx=(j22.*ux-j21.*uy)./d;gy=(-j12.*ux+j11.*uy)./d;
  h11=2*(mu(:,4)-gx.*mx(:,4)-gy.*my(:,4));h12=mu(:,5)-gx.*mx(:,5)-gy.*my(:,5);
  h22=2*(mu(:,6)-gx.*mx(:,6)-gy.*my(:,6));
  lap=(h11.*(j22.^2+j12.^2)-2*h12.*(j22.*j21+j12.*j11)+h22.*(j21.^2+j11.^2))./d.^2;
  if nargout>6,physical=[sum(b.*mx,2),sum(b.*my,2)];end
end
function b=LOCAL_monomial(x,y)
  b=[ones(size(x)),x,y,x.^2,x.*y,y.^2];
end
function [x,w]=LOCAL_gauss(n)
  j=(1:n-1)';b=j./sqrt(4*j.^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));
  [x,ix]=sort(diag(D));x=(x+1)/2;w=V(1,ix)'.^2;
end
function [x,y,w]=LOCAL_duffy(n)
  [z,v]=LOCAL_gauss(n);[r,s]=ndgrid(z,z);[a,b]=ndgrid(v,v);x=r(:);y=(1-x).*s(:);w=a(:).*b(:).*(1-x);
end

%% ==================== Portable output ====================
% Raw arrays allow independent read-only recombination without MATLAB.
function LOCAL_export(folder,arrays)
  names=fieldnames(arrays);meta=struct();
  for j=1:numel(names)
    name=names{j};a=arrays.(name);meta.(name)=size(a);
    fid=fopen(fullfile(folder,[name,'_real.bin']),'w','ieee-le');fwrite(fid,real(a),'double');fclose(fid);
    if ~isreal(a),fid=fopen(fullfile(folder,[name,'_imag.bin']),'w','ieee-le');fwrite(fid,imag(a),'double');fclose(fid);end
  end
  LOCAL_json(fullfile(folder,'arrays.json'),meta);
end
function LOCAL_json(path,value)
  fid=fopen(path,'w');assert(fid>=0,'i94:Export','Cannot write %s.',path);clean=onCleanup(@()fclose(fid));
  fwrite(fid,jsonencode(value,PrettyPrint=true),'char');
end
