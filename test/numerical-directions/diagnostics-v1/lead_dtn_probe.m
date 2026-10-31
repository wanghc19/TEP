function lead_dtn_probe(output_dir,reference_dir)
%LEAD_DTN_PROBE Frequency interpolation of the periodic-lead Dirichlet-to-Neumann map.
% Input: output_dir is new; reference_dir is a directory of I10.2 g24 P4
%   comparison files, or a retained reference-D.mat containing their compact arrays.
% Output: interpolation.csv, evaluations.csv, equivalence.json, bands.json, matrices.mat.
% LOCAL_* blocks below are copied verbatim from test/i10/refine-v1/refine_i102.m
% at commit b06db99382d10915a4991490c71c608c77803445. The entry and PROBE_* functions are new diagnostic code.
  config = refine_i102_config('g24'); config.orders = 4;
  if ~isfolder(output_dir), mkdir(output_dir); end
  maxNumCompThreads(config.resources.threads); LOCAL_ledger('reset');
  started = tic; ctx = struct('config',config,'output_dir',output_dir,'started',started, ...
    'progress_path',fullfile(output_dir,'progress.json'));
  LOCAL_json(fullfile(output_dir,'config.json'),config);
  [mesh,geometry] = LOCAL_mesh(config); assert(strcmp(geometry.status,'PASS'));
  sp = LOCAL_space(config,mesh,4); spaces = cell(1,4); spaces{4} = sp;
  rule = config.rules(2); band = LOCAL_band_locate(config,mesh,rule,spaces);
  ops = LOCAL_operators(ctx,sp,band,rule,false,false); clear mesh spaces band
  kstar = 1.5584378942105757;
  [D0,info0,seconds0] = PROBE_response(config,ops,kstar);
  compare = struct([]); reference = struct(); names = {'left','right'};
  if isfile(reference_dir), saved_reference = load(reference_dir,'reference'); end
  for j = 1:2
    name = names{j};
    if isfolder(reference_dir)
      old = load(fullfile(reference_dir,['recovery-P4-check-',name,'.mat']),'D','S','k');
    else
      old = saved_reference.reference.(name);
    end
    assert(abs(old.k-kstar)<5e-14,'Probe:ReferenceFrequency','Reference frequency mismatch.');
    row = struct('lead',name,'k',old.k,'D_absolute_fro',norm(D0{j}-old.D,'fro'), ...
      'D_relative_fro',norm(D0{j}-old.D,'fro')/norm(old.D,'fro'), ...
      'D_norm_fro',norm(old.D,'fro'),'unit_gap',info0(j).unit_gap_min);
    assert(row.D_relative_fro<1e-10,'Probe:Equivalence','Copied kernels disagree with I10.2.');
    if isempty(compare), compare = row; else, compare(end+1) = row; end
    reference.(name) = old;
  end
  LOCAL_json(fullfile(output_dir,'equivalence.json'),compare);
  save(fullfile(output_dir,'reference-D.mat'),'reference','-v7');
  fprintf('EQUIVALENCE left %.3e right %.3e relative Frobenius\n',compare.D_relative_fro);
  rows = struct([]); evals = struct([]); sets = struct([]);
  for h = [1e-4,1e-3,1e-2]
    nodes = cos(pi*(0:16)/16); tests = cos(pi*((0:8)+0.37)/9);
    values = cell(1,17); truths = cell(1,numel(tests));
    for a = 1:17
      k = kstar+h*nodes(a);
      if a==9, D = D0; inf = info0; sec = seconds0;
      else, [D,inf,sec] = PROBE_response(config,ops,k); end
      values{a} = D;
      evals = PROBE_evalrow(evals,h,k,'Chebyshev',sec,inf);
    end
    for a = 1:numel(tests)
      k = kstar+h*tests(a); [D,inf,sec] = PROBE_response(config,ops,k);
      truths{a} = D; evals = PROBE_evalrow(evals,h,k,'off-grid',sec,inf);
    end
    for n = [2,4,8,16]
      ids = 1:16/n:17; z = nodes(ids); weights = (-1).^(0:n); weights([1,end]) = weights([1,end])/2;
      for j = 1:2
        V = zeros(numel(D0{j}),n+1);
        for a = 1:n+1, V(:,a) = reshape(values{ids(a)}{j},[],1); end
        ef = zeros(size(tests)); e2 = ef;
        for a = 1:numel(tests)
          P = reshape(PROBE_interp(z,weights,V,tests(a)),size(D0{j}));
          E = truths{a}{j}-P;
          ef(a) = norm(E,'fro')/norm(truths{a}{j},'fro');
          e2(a) = norm(E,2)/norm(truths{a}{j},2);
        end
        timer = tic;
        for rep = 1:1000, unused = PROBE_interp(z,weights,V,tests(mod(rep-1,numel(tests))+1)); end %#ok<NASGU>
        cost = toc(timer)/1000;
        row = struct('h',h,'degree',n,'lead',names{j},'max_relative_fro',max(ef), ...
          'max_relative_2',max(e2),'interpolant_seconds',cost,'test_points',numel(tests));
        if isempty(rows), rows = row; else, rows(end+1) = row; end
        fprintf('INTERP h %.0e n %d %s relF %.3e rel2 %.3e eval %.3e s\n',h,n,names{j},max(ef),max(e2),cost);
      end
    end
    item = struct('h',h,'nodes',nodes,'tests',tests,'values',{values},'truths',{truths});
    if isempty(sets), sets = item; else, sets(end+1) = item; end
    writetable(struct2table(rows),fullfile(output_dir,'interpolation.csv'));
    writetable(struct2table(evals),fullfile(output_dir,'evaluations.csv'));
  end
  bands = PROBE_bands(config,ops,kstar); LOCAL_json(fullfile(output_dir,'bands.json'),bands);
  save(fullfile(output_dir,'matrices.mat'),'sets','D0','kstar','-v7');
  LOCAL_json(fullfile(output_dir,'summary.json'),struct('p',4,'wall_dofs',ops.n, ...
    'matlab_seconds',toc(started),'response_pair_seconds_at_root',seconds0,'rows',rows,'bands',bands));
end

function [D,infos,seconds] = PROBE_response(config,ops,k)
  timer = tic; D = cell(1,2); infos = struct([]); names = {'left','right'};
  for j = 1:2
    [S,cellinfo] = LOCAL_eliminate(config,ops.(names{j}),k^2,'lu');
    assert(cellinfo.valid,'Probe:Cell','%s',cellinfo.reason);
    [D{j},~,info] = LOCAL_dtn(config,S,ops.n);
    assert(info.valid,'Probe:DtN','%s',info.reason);
    if isempty(infos), infos = info; else, infos(end+1) = info; end
  end
  seconds = toc(timer);
end

function rows = PROBE_evalrow(rows,h,k,kind,seconds,info)
  row = struct('h',h,'k',k,'kind',kind,'pair_seconds',seconds, ...
    'left_unit_gap',info(1).unit_gap_min,'right_unit_gap',info(2).unit_gap_min, ...
    'left_spectral_radius',info(1).spectral_radius,'right_spectral_radius',info(2).spectral_radius);
  if isempty(rows), rows = row; else, rows(end+1) = row; end
end

function v = PROBE_interp(nodes,weights,V,x)
  hit = find(abs(x-nodes)<1e-15,1);
  if ~isempty(hit), v = V(:,hit); return, end
  w = weights./(x-nodes); v = V*w.'/sum(w);
end

function bands = PROBE_bands(config,ops,kstar)
  bands = struct([]); names = {'left','right'}; qgrid = linspace(-pi,pi,17);
  for j = 1:2
    t = ops.(names{j}); low = zeros(size(qgrid)); high = low;
    for a = 1:numel(qgrid), [low(a),high(a)] = PROBE_bandpair(t,ops.n,qgrid(a),kstar^2); end
    [lo,il] = max(low); [hi,ih] = min(high);
    options = optimset('TolX',1e-5,'Display','off');
    if il>1 && il<numel(qgrid)
      [qlo,val] = fminbnd(@(q)PROBE_objective(t,ops.n,q,kstar^2,-1),qgrid(il-1),qgrid(il+1),options); lo = -val;
    else, qlo = qgrid(il); end
    if ih>1 && ih<numel(qgrid)
      [qhi,hi] = fminbnd(@(q)PROBE_objective(t,ops.n,q,kstar^2,1),qgrid(ih-1),qgrid(ih+1),options);
    else, qhi = qgrid(ih); end
    row = struct('lead',names{j},'lower_edge_k',sqrt(lo),'upper_edge_k',sqrt(hi), ...
      'lower_q',qlo,'upper_q',qhi,'nearest_distance_k',min(kstar-sqrt(lo),sqrt(hi)-kstar), ...
      'q_grid',qgrid,'lower_grid_mu',low,'upper_grid_mu',high, ...
      'scope','sampled discrete-cell band extrema with local refinement; no global or continuous enclosure');
    if isempty(bands), bands = row; else, bands(end+1) = row; end
    fprintf('BAND %s lower %.12g upper %.12g distance %.3e\n',names{j},sqrt(lo),sqrt(hi),row.nearest_distance_k);
  end
end

function value = PROBE_objective(t,n,q,mu,sign)
  [lo,hi] = PROBE_bandpair(t,n,q,mu);
  if sign<0, value = -lo; else, value = hi; end
end

function [lo,hi] = PROBE_bandpair(t,n,q,mu)
  nd = size(t.K,1); I = t.interior; W = t.wall;
  Q = sparse([I;W(1:n);W(n+1:end)],[1:numel(I),numel(I)+(1:n),numel(I)+(1:n)], ...
    [ones(numel(I)+n,1);exp(1i*q)*ones(n,1)],nd,numel(I)+n);
  K = Q'*t.K*Q; M = Q'*t.M*Q;
  options = struct('tol',1e-10,'maxit',300,'disp',0);
  lambda = real(eigs(K,M,8,mu,options));
  lo = max(lambda(lambda<mu)); hi = min(lambda(lambda>mu));
  assert(~isempty(lo) && ~isempty(hi),'Probe:Bands','Missing adjacent bands.');
end

function list = LOCAL_append(list,item)
  if isempty(item), return, end
  if isempty(list), list = item; else, list = [list,item]; end %#ok<AGROW>
end

%% ==================== Layer orchestration ====================
% One field order: primary root, check root (+ prediction at P3), conditional extra, recovery.

function xy = LOCAL_curve(config,cell_index,theta)
  theta = theta(:);
  if cell_index == 0
    xy = config.model.star_scale*0.2*[(1.5+0.3*cos(5*theta)).*cos(theta), ...
      (1+0.3*cos(5*theta)).*sin(theta)];
  else
    a = config.model.a_negative;
    if cell_index>0, a = config.model.a_positive; end
    radius = config.model.radius*(1+a*cos(3*theta))/sqrt(1+a^2/2);
    xy = [radius.*cos(theta),radius.*sin(theta)];
  end
  xy(:,1) = xy(:,1)+cell_index*config.model.L;
end


function dxy = LOCAL_curve_derivative(config,cell_index,theta)
  % Analytic d/dtheta of LOCAL_curve (same formulas, CCW orientation).
  theta = theta(:);
  if cell_index == 0
    c = config.model.star_scale*0.2;
    dxy = c*[-1.5*sin(5*theta).*cos(theta)-(1.5+0.3*cos(5*theta)).*sin(theta), ...
      -1.5*sin(5*theta).*sin(theta)+(1+0.3*cos(5*theta)).*cos(theta)];
  else
    a = config.model.a_negative;
    if cell_index>0, a = config.model.a_positive; end
    scale = config.model.radius/sqrt(1+a^2/2);
    r = scale*(1+a*cos(3*theta)); dr = -3*a*scale*sin(3*theta);
    dxy = [dr.*cos(theta)-r.*sin(theta),dr.*sin(theta)+r.*cos(theta)];
  end
end


function [mesh,geometry] = LOCAL_mesh(config)
  % Ported unchanged from I9.5b (fem_dtn_i95b.m::LOCAL_mesh, D2) for design-10-2a 2.2;
  % cfg is the explicit group mesh configuration.
  cfg = config.mesh;
  % Design 5 steps 1-5: clearance deletion, constrained Delaunay with fixed
  % curve/ring/wall nodes, up to 3 deletion rounds, then (D2) bounded local
  % edge flips of interface-adjacent bad elements and the final full-mesh gates.
  % geometry.failure_kind is NONE, JACOBIAN_QUALITY_UNRESOLVED,
  % LOCAL_REPAIR_LIMIT or STRUCTURAL_CHECK_FAILED; mesh_structural_checks_pass
  % reports the completed constraint/material/incidence/pairing/coverage checks.
  rules = config.mesh_rules; s = cfg.subdivisions; ng = cfg.interface_segments; h = 1/s;
  tol = rules.coordinate_tolerance;
  [ix,iy] = ndgrid(0:3*s,0:s);
  grid = [-1.5+ix(:)*h,-0.5+iy(:)*h];
  fixed = mod(ix(:),s)==0 | iy(:)==0 | iy(:)==s;      % walls, top, bottom
  theta = 2*pi*(0:ng-1)'/ng;
  curves = cell(3,1); rings = cell(3,2); clearance = false(size(grid,1),1);
  for c = -1:1
    curve = LOCAL_curve(config,c,theta); curves{c+2} = curve;
    relative = curve-[c,0];
    rings{c+2,1} = [c,0]+(1-rules.ring_scale)*relative;
    rings{c+2,2} = [c,0]+(1+rules.ring_scale)*relative;
    clearance = clearance | LOCAL_polyline_distance(grid,curve) < rules.interface_clearance_fraction*h;
    for r = 1:2
      clearance = clearance | LOCAL_polyline_distance(grid,rings{c+2,r}) < rules.ring_clearance_fraction*h;
    end
  end
  background = grid(~clearance | fixed,:);
  deletable = ~fixed(~clearance | fixed);
  rounds = struct('round',{},'deleted',{},'deleted_points',{},'bad_elements',{}, ...
    'worst_ratio',{},'worst_det_min',{},'seconds',{});
  geometry = struct('status','PASS','reason','','failure_kind','NONE', ...
    'mesh_structural_checks_pass',false,'structural_checks_completed',false, ...
    'initial_clearance_deleted',nnz(clearance & ~fixed),'deletion_outcome','', ...
    'flip_stage_entered',false,'flip',struct(),'repair_seconds',0, ...
    'repair_seconds_limit',rules.repair_seconds);
  repair_timer = [];                                  % starts at the first bad element
  for round = 0:rules.repair_rounds
    timer = tic;
    [mesh,checks,base] = LOCAL_triangulate(config,cfg,background,deletable,curves,rings,theta);
    bad = LOCAL_bad(checks,rules);
    [worst_ratio,worst] = max(checks.det_ratio);
    record = struct('round',round,'deleted',0,'deleted_points',zeros(0,2), ...
      'bad_elements',numel(bad),'worst_ratio',worst_ratio,'worst_det_min',checks.det_min(worst), ...
      'seconds',0);
    if isempty(bad)
      geometry.deletion_outcome = sprintf('no bad elements after %d deletion rounds',round);
      record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
      break
    end
    if isempty(repair_timer), repair_timer = timer; end
    if round == rules.repair_rounds
      geometry.deletion_outcome = sprintf('%d bad elements after %d deletion rounds',numel(bad),round);
      record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
      break
    end
    % delete all deletable free background vertices of the bad elements
    vertices = unique(mesh.triangles(bad,:));
    remove = vertices(vertices<=size(background,1));
    remove = remove(deletable(remove));
    if isempty(remove)
      geometry.deletion_outcome = sprintf('%d bad elements without deletable background vertices', ...
        numel(bad));
      record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
      break
    end
    record.deleted = numel(remove); record.deleted_points = background(remove,:);
    keep = true(size(background,1),1); keep(remove) = false;
    background = background(keep,:); deletable = deletable(keep);
    record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
  end
  geometry.repair_rounds = rounds;
  % --- D2 step 4: bounded local edge flips when deletion left bad elements ---
  if ~isempty(bad)
    geometry.flip_stage_entered = true;
    [mesh,checks,geometry.flip] = LOCAL_flip_repair(config,cfg,base,mesh,checks,repair_timer);
    bad = LOCAL_bad(checks,rules);
  end
  if ~isempty(repair_timer), geometry.repair_seconds = toc(repair_timer); end
  % --- step 5: final full-mesh gates on the last rebuilt mesh ---
  geometry.structural_checks_completed = true;
  geometry.mesh_structural_checks_pass = checks.pass;
  geometry.bad_elements = numel(bad);
  geometry.checks = rmfield(checks,{'det_min','det_max','det_ratio','quality','min_angle'});
  geometry.det_min = min(checks.det_min); geometry.det_ratio_max = max(checks.det_ratio);
  geometry.curved_elements = nnz(checks.det_ratio>1+1e-12);
  q = sort(checks.quality); a = sort(checks.min_angle);
  pick = @(v,p)v(max(1,ceil(p*numel(v))));
  geometry.shape_quality = struct('min',q(1),'p01',pick(q,0.01),'p05',pick(q,0.05), ...
    'median',pick(q,0.5),'histogram_edges',0:0.1:1,'histogram',histcounts(q,0:0.1:1));
  geometry.min_angle_degrees = struct('min',a(1),'p01',pick(a,0.01),'p05',pick(a,0.05), ...
    'median',pick(a,0.5));
  if ~checks.pass
    geometry.status = 'GEOMETRY_FAILED'; geometry.failure_kind = 'STRUCTURAL_CHECK_FAILED';
    geometry.reason = ['structural checks: ',checks.reason];
  elseif ~isempty(bad) || geometry.repair_seconds>rules.repair_seconds
    geometry.status = 'GEOMETRY_FAILED';
    flip_limit = geometry.flip_stage_entered && geometry.flip.limit_hit;
    if flip_limit || geometry.repair_seconds>rules.repair_seconds
      geometry.failure_kind = 'LOCAL_REPAIR_LIMIT';
    else
      geometry.failure_kind = 'JACOBIAN_QUALITY_UNRESOLVED';
    end
    geometry.reason = sprintf('%d bad elements; deletion: %s',numel(bad),geometry.deletion_outcome);
    if geometry.flip_stage_entered
      geometry.reason = sprintf('%s; flip: %s',geometry.reason,geometry.flip.outcome);
    end
    if geometry.repair_seconds>rules.repair_seconds
      geometry.reason = sprintf('%s; repair %.2fs > %.0fs',geometry.reason, ...
        geometry.repair_seconds,rules.repair_seconds);
    end
  end
  mesh.det_min = checks.det_min; mesh.det_ratio = checks.det_ratio;
  mesh.quality = checks.quality; mesh.min_angle = checks.min_angle;
  mesh.subdivisions = s; mesh.interface_segments = ng; mesh.h = h;
  mesh.curves = curves; mesh.rings = rings;
  assert(all(abs(mesh.points(:))<2) && tol>0,'i102:Mesh','Mesh points escaped the three-cell box.');
end


function bad = LOCAL_bad(checks,rules)
  bad = find(checks.det_min<=0 | checks.det_ratio>rules.det_ratio_max);
end


function distance = LOCAL_polyline_distance(points,poly)
  a = poly; b = poly([2:end,1],:); distance = inf(size(points,1),1);
  block = 256;
  for j = 1:block:size(a,1)
    J = j:min(j+block-1,size(a,1));
    ax = a(J,1)'; ay = a(J,2)'; dx = b(J,1)'-ax; dy = b(J,2)'-ay;
    t = ((points(:,1)-ax).*dx+(points(:,2)-ay).*dy)./(dx.^2+dy.^2);
    t = min(max(t,0),1);
    d = hypot(points(:,1)-ax-t.*dx,points(:,2)-ay-t.*dy);
    distance = min(distance,min(d,[],2));
  end
end


function [mesh,checks,base] = LOCAL_triangulate(config,cfg,background,deletable,curves,rings,theta)
  % Constrained Delaunay of background + analytic curve/ring nodes, centroid
  % material/cell labels, then the shared P2/check build (LOCAL_mesh_build).
  tol = config.mesh_rules.coordinate_tolerance; ng = cfg.interface_segments;
  points = background; constraints = []; raw_interfaces = []; midpoint_values = [];
  for c = -1:1
    ids = size(points,1)+(1:ng)';
    points = [points;curves{c+2}]; %#ok<AGROW>
    edge = [ids,ids([2:end,1])]; constraints = [constraints;edge]; %#ok<AGROW>
    raw_interfaces = [raw_interfaces;edge]; %#ok<AGROW>
    midpoint_values = [midpoint_values;LOCAL_curve(config,c,theta+pi/ng)]; %#ok<AGROW>
    points = [points;rings{c+2,1};rings{c+2,2}]; %#ok<AGROW>
  end
  [~,first,map] = unique(round(points/tol),'rows','stable');
  assert(numel(first)==size(points,1),'i102:Duplicate','Mesh input contains duplicate points.');
  points = points(first,:); constraints = map(constraints); raw_interfaces = map(raw_interfaces);
  for x = -1.5:1:1.5
    ids = find(abs(points(:,1)-x)<tol);
    [~,order] = sort(points(ids,2)); ids = ids(order);
    constraints = [constraints;[ids(1:end-1),ids(2:end)]]; %#ok<AGROW>
  end
  for y = [-0.5,0.5]
    ids = find(abs(points(:,2)-y)<tol);
    [~,order] = sort(points(ids,1)); ids = ids(order);
    constraints = [constraints;[ids(1:end-1),ids(2:end)]]; %#ok<AGROW>
  end
  constraints = unique(sort(constraints,2),'rows');
  dt = delaunayTriangulation(points,constraints);
  assert(size(dt.Points,1)==size(points,1),'i102:Steiner','Triangulation inserted points.');
  points = dt.Points; triangles = dt.ConnectivityList;
  a = points(triangles(:,2),:)-points(triangles(:,1),:);
  b = points(triangles(:,3),:)-points(triangles(:,1),:);
  orientation = a(:,1).*b(:,2)-a(:,2).*b(:,1);
  triangles(orientation<0,[2,3]) = triangles(orientation<0,[3,2]);
  nt = size(triangles,1);
  centroids = (points(triangles(:,1),:)+points(triangles(:,2),:)+points(triangles(:,3),:))/3;
  cell_id = floor(centroids(:,1)+0.5); material = ones(nt,1)*config.model.rho_background;
  for c = -1:1
    curve = curves{c+2}; inside = inpolygon(centroids(:,1),centroids(:,2),curve(:,1),curve(:,2));
    rho = config.model.rho_center;
    if c<0, rho = config.model.rho_negative; elseif c>0, rho = config.model.rho_positive; end
    material(inside) = rho;
  end
  on_boundary = any(abs(points(:,1)-(-1.5:1:1.5))<tol,2) | abs(abs(points(:,2))-0.5)<tol;
  base = struct('points',points,'constraints',constraints,'raw_interfaces',raw_interfaces, ...
    'midpoint_values',midpoint_values,'theta',theta,'on_boundary',on_boundary, ...
    'background_points',size(background,1),'deletable_points',nnz(deletable));
  [mesh,checks] = LOCAL_mesh_build(config,cfg,base,triangles,material,cell_id);
end


function [mesh,checks] = LOCAL_mesh_build(config,cfg,base,triangles,material,cell_id)
  % Edges and shared P2 numbering: interface-edge midpoints take the analytic
  % curve values, all other edges the arithmetic midpoint; structural checks
  % and curved Jacobian determinant extrema (I9.5b, unchanged).
  tol = config.mesh_rules.coordinate_tolerance; points = base.points;
  constraints = base.constraints; raw_interfaces = base.raw_interfaces;
  nt = size(triangles,1); nv = size(points,1);
  a = points(triangles(:,2),:)-points(triangles(:,1),:);
  b = points(triangles(:,3),:)-points(triangles(:,1),:);
  orientation = a(:,1).*b(:,2)-a(:,2).*b(:,1);
  [edges,~,edge_ids] = unique(sort([triangles(:,[1,2]);triangles(:,[2,3]);triangles(:,[3,1])],2),'rows');
  [found,interface_edges] = ismember(sort(raw_interfaces,2),edges,'rows');
  checks = struct('pass',true,'reason','');
  checks.interface_edges_found = all(found);
  checks.constraints_found = all(ismember(constraints,edges,'rows'));
  incidence = accumarray(edge_ids,1);
  checks.interface_incidence_two = all(found) && all(incidence(interface_edges(found))==2);
  outer = @(p)abs(abs(p(:,1))-1.5)<tol | abs(abs(p(:,2))-0.5)<tol;
  single = incidence==1; e1 = points(edges(single,1),:); e2 = points(edges(single,2),:);
  checks.edge_incidence = all(incidence<=2) && all(outer(e1) & outer(e2) & ...
    (abs(e1(:,1)-e2(:,1))<tol | abs(e1(:,2)-e2(:,2))<tol));
  cell_area = accumarray(cell_id+2,orientation/2,[3,1]);
  checks.positive_orientation = all(orientation>0);
  checks.cell_coverage = all(abs(cell_area-1)<1e-10) && all(ismember(cell_id,-1:1));
  checks.cell_affine_area = cell_area';
  midpoints = (points(edges(:,1),:)+points(edges(:,2),:))/2;
  midpoints(interface_edges(found),:) = base.midpoint_values(found,:);
  p2_points = [points;midpoints]; triangle_p2 = [triangles,nv+reshape(edge_ids,nt,3)];
  occurrence = repmat((1:nt)',3,1); sides_ok = true; owner_cells_ok = true;
  for e = interface_edges(found)'
    owners = occurrence(edge_ids==e);
    sides_ok = sides_ok && numel(owners)==2 && material(owners(1))~=material(owners(2));
    owner_cells_ok = owner_cells_ok && numel(owners)==2 && cell_id(owners(1))==cell_id(owners(2));
  end
  checks.material_sides = sides_ok; checks.interface_single_cell = owner_cells_ok;
  det_min = zeros(nt,1); det_max = zeros(nt,1);
  for t = 1:nt
    coefficients = LOCAL_det_coefficients(LOCAL_map_coefficients(p2_points(triangle_p2(t,:),:)));
    [det_min(t),det_max(t)] = LOCAL_quadratic_triangle_extrema(coefficients);
  end
  det_ratio = det_max./det_min; det_ratio(det_min<=0) = Inf;
  P1 = points(triangles(:,1),:); P2 = points(triangles(:,2),:); P3 = points(triangles(:,3),:);
  l1 = sum((P2-P3).^2,2); l2 = sum((P3-P1).^2,2); l3 = sum((P1-P2).^2,2);
  area = abs(orientation)/2;
  quality = 4*sqrt(3)*area./(l1+l2+l3);
  angle = @(opp,u,v)acosd(min(1,max(-1,(u+v-opp)./(2*sqrt(u.*v)))));
  min_angle = min([angle(l1,l2,l3),angle(l2,l3,l1),angle(l3,l1,l2)],[],2);
  top = find(abs(p2_points(:,2)-0.5)<tol); bottom = find(abs(p2_points(:,2)+0.5)<tol);
  checks.top_bottom_pairing = numel(top)==numel(bottom) && ...
    max(abs(sort(p2_points(top,1))-sort(p2_points(bottom,1))))<tol;
  wall_ok = true;
  for w = 1:4
    ids = abs(p2_points(:,1)-(w-2.5))<tol; values = sort(p2_points(ids,2));
    wall_ok = wall_ok && numel(values)==2*cfg.subdivisions+1 && ...
      max(abs(values-(-0.5+(0:2*cfg.subdivisions)'/(2*cfg.subdivisions))))<1e-12;
  end
  checks.wall_translation_pairing = wall_ok;
  checks.vertices = nv; checks.triangles = nt; checks.p2_nodes = size(p2_points,1);
  checks.background_points = base.background_points; checks.deletable_points = base.deletable_points;
  fields = {'interface_edges_found','constraints_found','interface_incidence_two', ...
    'edge_incidence','positive_orientation','cell_coverage', ...
    'material_sides','interface_single_cell','top_bottom_pairing','wall_translation_pairing'};
  for f = fields
    if ~checks.(f{1})
      checks.pass = false; checks.reason = [checks.reason,f{1},' failed; '];
    end
  end
  checks.det_min = det_min; checks.det_max = det_max; checks.det_ratio = det_ratio;
  checks.quality = quality; checks.min_angle = min_angle;
  mesh = struct('points',points,'triangles',triangles,'p2_points',p2_points, ...
    'triangle_p2',triangle_p2,'edges',edges,'interface_edges',interface_edges, ...
    'interface_theta',repmat(base.theta,3,1), ...
    'interface_cell',kron((-1:1)',ones(cfg.interface_segments,1)), ...
    'material',material,'cell_id',cell_id);
end

%% ==================== Bounded local edge flip (ported from I9.5b D2) ====================
% Design 5 step 4: flip one straight chord of an interface-adjacent bad element.

function [mesh,checks,flip] = LOCAL_flip_repair(config,cfg,base,mesh,checks,repair_timer)
  % For a bad element abc containing an interface edge and a non-constrained
  % interior edge ac shared with acd (same material and cell, patch off the
  % walls/top/bottom), replace abc, acd by abd, bcd if abcd is strictly convex,
  % the straight new edge bd meets no actual P2 patch edge except at shared
  % endpoints, and both new curved elements satisfy det_min > 0 and
  % det_max/det_min <= 20. Vertices and outer P2 midpoints are kept; bd gets
  % the arithmetic midpoint. Limits: 32 candidate checks, 16 accepted flips,
  % 30 s for all deletion/flip repair and re-checks of the level.
  rules = config.mesh_rules; L = rules.flip;
  flip = struct('checked',0,'accepted',0,'limit_hit',false,'outcome','', ...
    'trials',struct([]),'recheck_seconds',[]);
  constraint_keys = sort(base.constraints,2); interface_keys = sort(base.raw_interfaces,2);
  recheck_cost = 0; trial_cost = 0; stop = false;
  while ~stop
    bad = LOCAL_bad(checks,rules);
    if isempty(bad), flip.outcome = 'all bad elements removed'; break, end
    [~,order] = sortrows([mesh.cell_id(bad),bad]); bad = bad(order);
    progressed = false;
    for t = bad'
      tri = mesh.triangles(t,:); keys = sort([tri([1,2]);tri([2,3]);tri([3,1])],2);
      if ~any(ismember(keys,interface_keys,'rows')), continue, end
      candidates = find(~ismember(keys,constraint_keys,'rows'));
      [~,order] = sortrows(keys(candidates,:)); candidates = candidates(order)';
      for e = candidates
        % limits are checked before every operation (design 5, D2)
        elapsed = toc(repair_timer);
        if flip.checked>=L.max_checks || flip.accepted>=L.max_flips || ...
            elapsed+trial_cost+recheck_cost>rules.repair_seconds
          flip.limit_hit = true; stop = true;
          flip.outcome = sprintf(['limit reached before the next operation: %d checks, ', ...
            '%d flips, %.2fs elapsed (+%.2fs predicted)'],flip.checked,flip.accepted, ...
            elapsed,trial_cost+recheck_cost);
          break
        end
        timer = tic; flip.checked = flip.checked+1;
        [trial,new] = LOCAL_flip_trial(config,base,mesh,checks,t,e);
        if trial.accepted
          triangles = mesh.triangles; triangles(t,:) = new.tri(1,:); triangles(new.neighbor,:) = new.tri(2,:);
          rebuild = tic;
          [mesh_new,checks_new] = LOCAL_mesh_build(config,cfg,base,triangles,mesh.material,mesh.cell_id);
          recheck_cost = toc(rebuild); flip.recheck_seconds(end+1) = recheck_cost;
          bad_new = LOCAL_bad(checks_new,rules);
          patch_ok = ~any(ismember([t;new.neighbor],bad_new)) && isempty(setdiff(bad_new,bad));
          trial.gates.post_rebuild_structural = checks_new.pass;
          trial.gates.post_rebuild_no_new_bad = patch_ok;
          if checks_new.pass && patch_ok
            trial.after_p2 = mesh_new.p2_points(mesh_new.triangle_p2([t,new.neighbor],:),:);
            trial.bad_after = numel(bad_new);
            mesh = mesh_new; checks = checks_new; flip.accepted = flip.accepted+1; progressed = true;
          else
            trial.accepted = false;
            trial.reason = ['post-rebuild check failed: ',checks_new.reason];
          end
        end
        trial.seconds = toc(timer);
        trial_cost = max(trial_cost,trial.seconds-trial.accepted*recheck_cost);
        flip.trials = LOCAL_append(flip.trials,trial);
        fprintf('  FLIP check %d element %d edge [%d %d]: %s %s (%.3fs)\n',flip.checked,t, ...
          trial.edge,LOCAL_tf(trial.accepted),trial.reason,trial.seconds);
        if trial.accepted, break, end
      end
      if progressed || stop, break, end
    end
    if ~progressed && ~stop
      flip.outcome = sprintf('no admissible flip for %d remaining bad elements',numel(bad)); break
    end
  end
end


function [trial,new] = LOCAL_flip_trial(config,base,mesh,checks,t,e)
  % One candidate patch: bad element t = (a,b,c) counter-clockwise with the
  % candidate chord e = ac opposite b, neighbour (a,c,d); proposal abd, bcd.
  rules = config.mesh_rules; L = rules.flip; pts = base.points; nv = size(pts,1);
  tri = mesh.triangles(t,:); k = mod(e+1,3)+1;        % position of b (opposite edge e)
  b = tri(k); c = tri(mod(k,3)+1); a = tri(mod(k+1,3)+1);
  new = struct('tri',[],'neighbor',NaN);
  gates = struct('interior_two_owners',false,'not_constraint',true,'distinct_vertices',false, ...
    'same_material',false,'same_cell',false,'off_walls_top_bottom',false,'strictly_convex',false, ...
    'new_edge_absent',false,'no_curved_crossing',false,'new_det_positive',false, ...
    'new_det_ratio',false);
  trial = struct('element',t,'neighbor',NaN,'edge',sort([a,c]),'vertices',[a,b,c,NaN], ...
    'coordinates',[],'old_p2',[],'new_p2',[],'after_p2',[],'material',mesh.material(t), ...
    'cell',mesh.cell_id(t),'old_det',[checks.det_min(t),checks.det_max(t),checks.det_ratio(t)], ...
    'new_det',[],'gates',gates,'accepted',false,'reason','','bad_after',NaN,'seconds',0, ...
    'crossing',struct([]));
  owners = find(any(mesh.triangles==a,2) & any(mesh.triangles==c,2));
  gates.interior_two_owners = numel(owners)==2;
  if ~gates.interior_two_owners
    trial.gates = gates; trial.reason = 'chord is not shared by exactly two elements'; return
  end
  m = setdiff(owners,t); d = setdiff(mesh.triangles(m,:),[a,c]);
  trial.neighbor = m; trial.vertices = [a,b,c,d];
  gates.distinct_vertices = numel(d)==1 && numel(unique([a,b,c,d]))==4;
  gates.same_material = mesh.material(m)==mesh.material(t);
  gates.same_cell = mesh.cell_id(m)==mesh.cell_id(t);
  if gates.distinct_vertices, gates.off_walls_top_bottom = ~any(base.on_boundary([a,b,c,d])); end
  if ~(gates.distinct_vertices && gates.same_material && gates.same_cell && gates.off_walls_top_bottom)
    trial.gates = gates; trial.reason = 'patch not same-material/same-cell interior'; return
  end
  P = pts([a,b,c,d],:); trial.coordinates = P;
  edge_mid = @(u,v)mesh.p2_points(nv+find(ismember(mesh.edges,sort([u,v]),'rows')),:);
  trial.old_p2 = [mesh.p2_points(mesh.triangle_p2(t,:),:);mesh.p2_points(mesh.triangle_p2(m,:),:)];
  % strict convexity of abcd (either orientation), relative to the patch diameter
  pairs = nchoosek(1:4,2); ell = max(vecnorm(P(pairs(:,1),:)-P(pairs(:,2),:),2,2)); turn = zeros(4,1);
  for i = 1:4
    u = P(i,:)-P(mod(i-2,4)+1,:); v = P(mod(i,4)+1,:)-P(i,:); turn(i) = u(1)*v(2)-u(2)*v(1);
  end
  gates.strictly_convex = all(turn>L.convex_factor*ell^2) || all(turn<-L.convex_factor*ell^2);
  gates.new_edge_absent = ~ismember(sort([b,d]),mesh.edges,'rows');
  if ~(gates.strictly_convex && gates.new_edge_absent)
    trial.gates = gates; trial.reason = 'patch not strictly convex or bd already exists'; return
  end
  % the straight new edge bd against the actual P2 outer patch edges
  outer = [a,b;b,c;c,d;d,a]; clear_all = true; crossing = struct([]);
  for i = 1:4
    u = outer(i,1); v = outer(i,2); shared = u; other = v;
    if ~any(u==[b,d]), shared = v; other = u; end
    [ok,why] = LOCAL_segment_curve_clear(pts(shared,:),edge_mid(u,v),pts(other,:), ...
      pts(b,:),pts(d,:),L.crossing_tolerance);
    crossing = LOCAL_append(crossing,struct('edge',[u,v],'clear',ok,'why',why));
    clear_all = clear_all && ok;
  end
  trial.crossing = crossing; gates.no_curved_crossing = clear_all;
  if ~clear_all
    trial.gates = gates; trial.reason = 'new edge meets a curved patch edge or is undecidable'; return
  end
  % proposal abd, bcd (positively reoriented) and their full-element det extrema
  T = [a,b,d;b,c,d]; nodes = cell(2,1); new_det = zeros(2,3);
  bd_mid = (pts(b,:)+pts(d,:))/2;
  for j = 1:2
    r = T(j,:); o = pts(r,:); s = (o(2,1)-o(1,1))*(o(3,2)-o(1,2))-(o(2,2)-o(1,2))*(o(3,1)-o(1,1));
    if s<0, r = r([1,3,2]); T(j,:) = r; end
    mids = zeros(3,2);
    for q = 1:3
      u = r(q); v = r(mod(q,3)+1);
      if isequal(sort([u,v]),sort([b,d])), mids(q,:) = bd_mid; else, mids(q,:) = edge_mid(u,v); end
    end
    nodes{j} = [pts(r,:);mids];
    [dmin,dmax] = LOCAL_quadratic_triangle_extrema(LOCAL_det_coefficients(LOCAL_map_coefficients(nodes{j})));
    new_det(j,:) = [dmin,dmax,dmax/dmin];
  end
  trial.new_p2 = [nodes{1};nodes{2}]; trial.new_det = new_det;
  gates.new_det_positive = all(new_det(:,1)>0);
  gates.new_det_ratio = gates.new_det_positive && all(new_det(:,3)<=rules.det_ratio_max);
  trial.gates = gates;
  if ~(gates.new_det_positive && gates.new_det_ratio)
    trial.reason = sprintf('new elements det ratio [%.4g %.4g]',new_det(1,3),new_det(2,3)); return
  end
  trial.accepted = true; trial.reason = sprintf('new elements det ratio [%.4g %.4g]', ...
    new_det(1,3),new_det(2,3));
  new = struct('tri',T,'neighbor',m);
end


function [clear,why] = LOCAL_segment_curve_clear(P,M,Q,b,d,tol)
  % Curved P2 edge q(t) = P + t v1 + t^2 v2, t in [0,1], with P in {b,d}:
  % v1 = 4M-3P-Q, v2 = 2P+2Q-4M. Its meetings with the line through b,d solve
  % f(t) = det(q(t)-b, d-b) = t (c1 + c2 t); t = 0 is the shared endpoint and
  % the only other root is t* = -c1/c2. Near-double roots, collinearity or a
  % meeting within tolerance of the segment ends are rejected as undecidable.
  v1 = 4*M-3*P-Q; v2 = 2*P+2*Q-4*M; w = d-b;
  cr = @(u,v)u(1)*v(2)-u(2)*v(1);
  c1 = cr(v1,w); c2 = cr(v2,w); scale = norm(w)*(norm(v1)+norm(v2));
  clear = false;
  if abs(c1)<=tol*scale, why = 'tangent or collinear at the shared endpoint'; return, end
  if abs(c2)<=tol*scale, clear = true; why = 'no second root'; return, end
  ts = -c1/c2;
  if ts<-tol || ts>1+tol, clear = true; why = sprintf('second root t=%.6g outside [0,1]',ts); return, end
  if abs(ts)<=tol || abs(ts-1)<=tol, why = sprintf('second root t=%.6g at an edge end',ts); return, end
  q = P+ts*v1+ts^2*v2; sd = dot(q-b,w)/dot(w,w);
  if sd<-tol || sd>1+tol
    clear = true; why = sprintf('meets the line at s=%.6g outside segment bd',sd); return
  end
  if abs(sd)<=tol || abs(sd-1)<=tol, why = sprintf('meeting at s=%.6g undecidable',sd); return, end
  why = sprintf('curved edge crosses bd at t=%.6g, s=%.6g',ts,sd);
end


function text = LOCAL_tf(value)
  if value, text = 'ACCEPT'; else, text = 'reject'; end
end



function alpha = LOCAL_lattice(p)
  % Local node order: v1 v2 v3, edge12 (p-j,j,0), edge23 (0,p-j,j),
  % edge31 (j,0,p-j) for j = 1..p-1, then interior nodes (P2: I9.5b order).
  j = (1:p-1)'; z = 0*j;
  alpha = [p,0,0;0,p,0;0,0,p;p-j,j,z;z,p-j,j;j,z,p-j];
  for a2 = 1:p-2
    for a3 = 1:p-1-a2
      alpha(end+1,:) = [p-a2-a3,a2,a3]; %#ok<AGROW>
    end
  end
end


function [N,Nxi,Neta] = LOCAL_lagrange(p,alpha,pts)
  % N_alpha(lambda) = prod_i (1/alpha_i!) prod_{j<alpha_i} (p lambda_i - j),
  % lambda = (1-xi-eta, xi, eta); d/dxi = d/dl2 - d/dl1, d/deta = d/dl3 - d/dl1.
  xi = pts(:,1); eta = pts(:,2); L = [1-xi-eta,xi,eta]; np = numel(xi);
  F = cell(p+1,1); dF = cell(p+1,1);
  for m = 0:p
    f = ones(np,3); df = zeros(np,3);
    for j = 0:m-1
      df = df.*(p*L-j)+f*p; f = f.*(p*L-j);
    end
    F{m+1} = f/factorial(m); dF{m+1} = df/factorial(m);
  end
  nb = size(alpha,1); N = zeros(np,nb); Nxi = N; Neta = N;
  for a = 1:nb
    f1 = F{alpha(a,1)+1}(:,1); f2 = F{alpha(a,2)+1}(:,2); f3 = F{alpha(a,3)+1}(:,3);
    d1 = dF{alpha(a,1)+1}(:,1); d2 = dF{alpha(a,2)+1}(:,2); d3 = dF{alpha(a,3)+1}(:,3);
    N(:,a) = f1.*f2.*f3;
    g1 = d1.*f2.*f3;
    Nxi(:,a) = f1.*d2.*f3-g1; Neta(:,a) = f1.*f2.*d3-g1;
  end
end


function sp = LOCAL_space(config,mesh,p)
  % Template dofs: template vertices, then (p-1) nodes per template edge
  % ordered from the smaller global vertex id, then (p-1)(p-2)/2 interior
  % nodes per element. Top (y=+1/2) dofs are QP slaves u_+ = e^{i beta} u_-.
  tol = config.mesh_rules.coordinate_tolerance; beta = config.model.beta*config.model.d;
  s = mesh.subdivisions; n = s*p; alpha = LOCAL_lattice(p); nb = size(alpha,1);
  sp = struct('p',p,'s',s,'n',n,'beta',beta,'alpha',alpha,'nb',nb);
  names = {'left','center','right'}; walls_x = {[-0.5,-1.5],[-0.5,0.5],[0.5,1.5]};
  nv_global = size(mesh.points,1);
  lat = alpha(:,2:3)/p; Ng = zeros(nb,6);
  for a = 1:nb, Ng(a,:) = LOCAL_basis([1-lat(a,1)-lat(a,2),lat(a,1),lat(a,2)]); end
  pairs = [1,2;2,3;3,1]; nint = (p-1)*(p-2)/2;
  for c = -1:1
    ids = find(mesh.cell_id==c); nt = numel(ids);
    tri = mesh.triangles(ids,:); eg = mesh.triangle_p2(ids,4:6)-nv_global;
    [verts,~,vloc] = unique(tri); vloc = reshape(vloc,nt,3); nV = numel(verts);
    [edges,~,eloc] = unique(eg); eloc = reshape(eloc,nt,3); nE = numel(edges);
    tri_dofs = zeros(nt,nb); tri_dofs(:,1:3) = vloc;
    for le = 1:3
      forward = tri(:,pairs(le,1)) < tri(:,pairs(le,2));
      for j = 1:p-1
        jj = j*forward+(p-j)*(~forward);
        tri_dofs(:,3+(le-1)*(p-1)+j) = nV+(eloc(:,le)-1)*(p-1)+jj;
      end
    end
    if nint > 0
      tri_dofs(:,3+3*(p-1)+(1:nint)) = nV+nE*(p-1)+(0:nt-1)'*nint+(1:nint);
    end
    nd = nV+nE*(p-1)+nt*nint;
    X = reshape(mesh.p2_points(mesh.triangle_p2(ids,:),1),nt,6);
    Y = reshape(mesh.p2_points(mesh.triangle_p2(ids,:),2),nt,6);
    PX = X*Ng'; PY = Y*Ng';
    dof_xy = zeros(nd,2); dof_xy(tri_dofs(:),1) = PX(:); dof_xy(tri_dofs(:),2) = PY(:);
    consistency = max([abs(dof_xy(tri_dofs,1)-PX(:));abs(dof_xy(tri_dofs,2)-PY(:))]);
    top = find(abs(dof_xy(:,2)-0.5)<tol); bottom = find(abs(dof_xy(:,2)+0.5)<tol);
    [~,a] = sort(dof_xy(top,1)); top = top(a); [~,a] = sort(dof_xy(bottom,1)); bottom = bottom(a);
    pairing = numel(top)==numel(bottom) && max(abs(dof_xy(top,1)-dof_xy(bottom,1)))<tol;
    assert(pairing,'i102:Pairing','Top/bottom P%d dofs do not pair in cell %d.',p,c);
    master = (1:nd)'; master(top) = bottom; free = setdiff((1:nd)',top);
    [~,col] = ismember(master,free); phase = ones(nd,1); phase(top) = exp(1i*beta);
    Qqp = sparse(1:nd,col,phase,nd,numel(free));
    qp_defect = norm(Qqp(top,:)-exp(1i*beta)*Qqp(bottom,:),'fro');
    fx = dof_xy(free,1); fy = dof_xy(free,2); wall = cell(1,2);
    for w = 1:2
      list = find(abs(fx-walls_x{c+2}(w))<tol); [~,a] = sort(fy(list)); wall{w} = list(a);
    end
    expected = -0.5+(0:n-1)'/n;
    wall_ok = numel(wall{1})==n && numel(wall{2})==n && ...
      max(abs([fy(wall{1});fy(wall{2})]-[expected;expected]))<1e-12;
    W = [wall{1};wall{2}]; I = setdiff((1:numel(free))',W);
    sp.(names{c+2}) = struct('name',names{c+2},'cell',c,'element_ids',ids,'X',X,'Y',Y, ...
      'material',mesh.material(ids),'tri_dofs',tri_dofs,'ndof',nd,'dof_xy',dof_xy, ...
      'Qqp',Qqp,'free',free,'top',top,'bottom',bottom,'wall',W,'interior',I, ...
      'wall_y',expected,'counts',[nV,nE,nt], ...
      'checks',struct('dof_formula',nd==nV+(p-1)*nE+nint*nt,'shared_node_coordinate_defect', ...
      consistency,'top_bottom_pairing',pairing,'qp_defect',qp_defect,'wall_pairing',wall_ok, ...
      'pass',wall_ok && pairing && consistency<1e-12 && qp_defect<=config.gates.qp_defect));
  end
  sp.wall_mass_single = LOCAL_wall_mass(s,p,beta);
end


function W = LOCAL_wall_mass(s,p,beta)
  % Exact 1D P_p mass (p+2 Gauss points per segment), then the QP closure.
  n = s*p; h = 1/s; [x,w] = LOCAL_gauss1d(p+2);
  B = LOCAL_lagrange_1d(p,x); local = h*(B'*(w.*B));
  rows = zeros((p+1)^2*s,1); cols = rows; values = rows; q = 0;
  for m = 0:s-1
    ids = m*p+(0:p)+1;
    for a = 1:p+1
      for b = 1:p+1
        q = q+1; rows(q) = ids(a); cols(q) = ids(b); values(q) = local(a,b);
      end
    end
  end
  Mfull = sparse(rows,cols,values,n+1,n+1);
  Qw = sparse([1:n,n+1],[1:n,1],[ones(1,n),exp(1i*beta)],n+1,n);
  W = full(Qw'*Mfull*Qw); W = (W+W')/2;
end


function B = LOCAL_lagrange_1d(p,t)
  t = t(:); nodes = (0:p)/p; B = ones(numel(t),p+1);
  for j = 1:p+1
    for m = 1:p+1
      if m ~= j, B(:,j) = B(:,j).*(t-nodes(m))/(nodes(j)-nodes(m)); end
    end
  end
end


function [x,w] = LOCAL_gauss1d(m)
  j = (1:m-1)'; b = j./sqrt(4*j.^2-1); [V,D] = eig(diag(b,1)+diag(b,-1));
  [x,idx] = sort(diag(D)); w = V(1,idx)'.^2; x = (x+1)/2;
end


function band = LOCAL_band_locate(config,mesh,rule,spaces)
  loc = config.location; ng = mesh.interface_segments; dtheta = 2*pi/ng;
  timer = tic;
  [tg,tw] = LOCAL_gauss1d(rule.band_points); m = rule.band_subsegments;
  t = reshape(tg+(0:m-1),[],1)/m; wt = repmat(tw,m,1)/m;     % t in [0,1], equal subsegments
  [T,TAU] = ndgrid(t,tg); [WT,WTAU] = ndgrid(wt,tw);
  T = T(:)'; TAU = TAU(:)'; WQ = WT(:)'.*WTAU(:)'; nps = numel(T);
  % element geometry: P2 map coefficients, scales, adjacency and AABB
  nt = size(mesh.triangles,1); nv = size(mesh.points,1);
  nodes = cell(1,6);
  for a = 1:6, nodes{a} = mesh.p2_points(mesh.triangle_p2(:,a),:); end
  Cx = LOCAL_map_rows(nodes,1); Cy = LOCAL_map_rows(nodes,2);
  V = mesh.points;
  scale = max([vecnorm(V(mesh.triangles(:,1),:)-V(mesh.triangles(:,2),:),2,2), ...
    vecnorm(V(mesh.triangles(:,2),:)-V(mesh.triangles(:,3),:),2,2), ...
    vecnorm(V(mesh.triangles(:,3),:)-V(mesh.triangles(:,1),:),2,2)],[],2);
  control = [nodes{1};nodes{2};nodes{3};2*nodes{4}-(nodes{1}+nodes{2})/2; ...
    2*nodes{5}-(nodes{2}+nodes{3})/2;2*nodes{6}-(nodes{3}+nodes{1})/2];
  cx = reshape(control(:,1),nt,6); cy = reshape(control(:,2),nt,6);
  box = [min(cx,[],2)-loc.aabb_pad,max(cx,[],2)+loc.aabb_pad, ...
    min(cy,[],2)-loc.aabb_pad,max(cy,[],2)+loc.aabb_pad];
  edge_of_tri = mesh.triangle_p2(:,4:6)-nv;
  E2T = sparse(edge_of_tri(:),repmat((1:nt)',3,1),1,size(mesh.edges,1),nt);
  V2T = sparse(mesh.triangles(:),repmat((1:nt)',3,1),1,nv,nt);
  names = {'left','center','right'}; rho = [config.model.rho_negative,config.model.rho_center, ...
    config.model.rho_positive];
  band = struct('rule',rule.name,'points_per_segment',nps,'total_points',0,'total_failures',0, ...
    'total_dual',0,'total_tolerance_owner',0,'seconds',0,'failures',struct([]));
  for c = -1:1
    name = names{c+2}; seg = (c+1)*ng+(1:ng)';
    theta0 = mesh.interface_theta(seg); theta1 = theta0([2:end,1]);
    P0 = LOCAL_curve(config,c,theta0); Pm = LOCAL_curve(config,c,theta0+pi/ng);
    P1 = LOCAL_curve(config,c,theta1);
    th = theta0+dtheta*T;                                     % ng x nps
    G = LOCAL_curve(config,c,th(:)); dG = dtheta*LOCAL_curve_derivative(config,c,th(:));
    t1 = repmat(T,ng,1); t1 = t1(:); tau = repmat(TAU,ng,1); tau = tau(:);
    sid = repmat((1:ng)',1,nps); sid = sid(:);
    b0 = (1-t1).*(1-2*t1); bm = 4*t1.*(1-t1); b1 = t1.*(2*t1-1);
    Gh = P0(sid,:).*b0+Pm(sid,:).*bm+P1(sid,:).*b1;
    dGh = P0(sid,:).*(4*t1-3)+Pm(sid,:).*(4-8*t1)+P1(sid,:).*(4*t1-1);
    Htau = G-Gh; Ht = dGh+tau.*(dG-dGh); H = Gh+tau.*Htau;
    JH = Htau(:,1).*Ht(:,2)-Htau(:,2).*Ht(:,1);              % signed, never abs
    weight = repmat(WQ,ng,1); weight = weight(:).*JH;
    np = size(H,1);
    % --- D2 owner state: lexicographic (-b_K, r_K/h_K, global element id) ---
    S = LOCAL_owner_init(np);
    owners = zeros(ng,2);
    for j = 1:ng, owners(j,:) = find(E2T(mesh.interface_edges(seg(j)),:)); end
    % --- stage A: the two owners of the interface edge ---
    S = LOCAL_try(config,spaces,Cx,Cy,scale,H,(1:np)',owners(sid,:),S,1);
    % --- stage B: vertex neighbours, once, for points without owner or with best b_K < 0 ---
    todo = find(S.element==0 | S.b<0); neighbours = cell(ng,1);
    for j = unique(sid(todo))'
      list = find(any(V2T(mesh.triangles(owners(j,:),:),:),1));
      neighbours{j} = setdiff(list,owners(j,:));
    end
    if ~isempty(todo)
      S = LOCAL_try(config,spaces,Cx,Cy,scale,H,todo,LOCAL_pad(neighbours(sid(todo))),S,2);
    end
    % --- stage C: Bernstein-box candidates not tried before, once ---
    todo = find(S.element==0 | S.b<0);
    if ~isempty(todo)
      lists = cell(numel(todo),1);
      for i = 1:numel(todo)
        x = H(todo(i),:); j = sid(todo(i));
        list = find(box(:,1)<=x(1) & box(:,2)>=x(1) & box(:,3)<=x(2) & box(:,4)>=x(2))';
        lists{i} = setdiff(list,[owners(j,:),neighbours{j}]);
      end
      S = LOCAL_try(config,spaces,Cx,Cy,scale,H,todo,LOCAL_pad(lists),S,3);
    end
    element = S.element; xi = S.xi; eta = S.eta;
    failed = find(element==0);
    for i = failed'
      band.failures = LOCAL_append(band.failures,struct('cell',c,'segment',sid(i), ...
        't',t1(i),'tau',tau(i),'x',H(i,1),'y',H(i,2), ...
        'reason','POINT_LOCATION_FAILED: NO_ACCEPTED_INVERSE'));
    end
    % up to 20 largest recorded dual differences (diagnostic only, never a veto)
    dual = S.nacc>1; dlist = find(dual & ~isnan(S.defect));
    [~,o] = sort(S.defect(dlist),'descend'); dlist = dlist(o(1:min(20,end)));
    samples = struct([]);
    for i = dlist'
      samples = LOCAL_append(samples,struct('point',i,'segment',sid(i),'t',t1(i),'tau',tau(i), ...
        'x',H(i,1),'y',H(i,2),'weight',weight(i),'defect',S.defect(i), ...
        'owner_element',S.element(i),'owner_b',S.b(i),'owner_r_over_h',S.rh(i), ...
        'alt_element',S.alt_element(i),'alt_b',S.alt_b(i),'alt_r_over_h',S.alt_rh(i)));
    end
    % template-local element index (same element_ids for every order)
    local = zeros(nt,1); ids = spaces{config.orders(1)}.(name).element_ids;
    local(ids) = 1:numel(ids);
    in_cell = element>0; wrong_cell = nnz(in_cell & local(max(element,1))==0);
    template_element = zeros(np,1); template_element(in_cell) = local(element(in_cell));
    band.(name) = struct('element',template_element,'xi',xi,'eta',eta,'weight',weight, ...
      'rho_minus_one',rho(c+2)-1,'signed_area',sum(weight),'points',np, ...
      'failures',numel(failed),'dual',nnz(dual),'tolerance_owner',nnz(element>0 & S.b<0), ...
      'dual_defect_max',max([0;S.defect(dual & ~isnan(S.defect))]), ...
      'owner_r_over_h_max',max([0;S.rh(element>0)]),'owner_b_min',min([Inf;S.b(element>0)]), ...
      'dual_samples',samples, ...
      'wrong_cell',wrong_cell,'stage_counts',[nnz(S.stage==1),nnz(S.stage==2),nnz(S.stage==3)], ...
      'negative_J',nnz(JH<0),'J_min',min(JH),'J_max',max(JH), ...
      'max_offset',max(vecnorm(Htau,2,2)));
    band.total_points = band.total_points+np; band.total_failures = band.total_failures+numel(failed);
    band.total_dual = band.total_dual+nnz(dual);
    band.total_tolerance_owner = band.total_tolerance_owner+nnz(element>0 & S.b<0);
    if wrong_cell > 0
      band.total_failures = band.total_failures+wrong_cell;
      band.(name).element(template_element==0 & in_cell) = 0;
    end
  end
  band.seconds = toc(timer);
end


function C = LOCAL_map_rows(nodes,k)
  % Rows of P2 map coefficients c1..c6 (I9.5b LOCAL_map_coefficients), coordinate k.
  n = cellfun(@(v)v(:,k),nodes,'UniformOutput',false);
  C = [n{1},-3*n{1}-n{2}+4*n{4},-3*n{1}-n{3}+4*n{6},2*n{1}+2*n{2}-4*n{4}, ...
    4*n{1}-4*n{4}+4*n{5}-4*n{6},2*n{1}+2*n{3}-4*n{6}];
end


function S = LOCAL_owner_init(np)
  S = struct('element',zeros(np,1),'xi',NaN(np,1),'eta',NaN(np,1),'b',-Inf(np,1), ...
    'rh',Inf(np,1),'stage',zeros(np,1),'nacc',zeros(np,1),'defect',NaN(np,1), ...
    'alt_element',zeros(np,1),'alt_b',NaN(np,1),'alt_rh',NaN(np,1));
end


function cand = LOCAL_pad(lists)
  width = max(1,max(cellfun(@numel,lists))); cand = zeros(numel(lists),width);
  for i = 1:numel(lists), cand(i,1:numel(lists{i})) = lists{i}; end
end


function S = LOCAL_try(config,spaces,Cx,Cy,scale,H,points,cand,S,stage_id)
  % Inverse-map every (point, candidate) pair inside the acceptance window
  % r_K/h_K <= 1e-12, b_K >= -1e-10 and keep one owner per point by the D2
  % lexicographic order (-b_K, r_K/h_K, global element id), merged with an
  % owner from an earlier stage. Several accepted inverses are a recorded
  % dual: the largest global-basis difference (all orders) to the owner is
  % stored as a diagnostic only; it never clears the owner.
  loc = config.location; nc = size(cand,2);
  P = repelem(points,nc); E = reshape(cand',[],1); keep = E>0; P = P(keep); E = E(keep);
  if isempty(P), return, end
  [s,r,ok,bmin] = LOCAL_inverse_map(Cx(E,:),Cy(E,:),H(P,:),scale(E),loc);
  rh = r./scale(E); acc = find(ok);
  if isempty(acc), return, end
  [~,order] = sortrows([P(acc),-bmin(acc),rh(acc),E(acc)]); acc = acc(order);
  starts = find([true;diff(P(acc))~=0]); lengths = diff([starts;numel(acc)+1]);
  best = acc(starts); k = P(best); had = S.element(k)>0;
  % single new acceptance and no earlier owner: assign directly
  direct = ~had & lengths==1; kd = k(direct); bd = best(direct);
  S.element(kd) = E(bd); S.xi(kd) = s(bd,1); S.eta(kd) = s(bd,2); S.b(kd) = bmin(bd);
  S.rh(kd) = rh(bd); S.stage(kd) = stage_id; S.nacc(kd) = 1;
  % several acceptances (this stage and/or an earlier owner): order, assign, record
  for j = find(~direct)'
    rows = acc(starts(j)+(0:lengths(j)-1)); kk = P(rows(1));
    el = E(rows); ss = s(rows,:); bs = bmin(rows); rs = rh(rows); st = repmat(stage_id,numel(rows),1);
    if S.element(kk)>0
      el = [S.element(kk);el]; ss = [S.xi(kk),S.eta(kk);ss]; bs = [S.b(kk);bs]; %#ok<AGROW>
      rs = [S.rh(kk);rs]; st = [S.stage(kk);st]; %#ok<AGROW>
    end
    [~,o] = sortrows([-bs,rs,el]); el = el(o); ss = ss(o,:); bs = bs(o); rs = rs(o); st = st(o);
    S.element(kk) = el(1); S.xi(kk) = ss(1,1); S.eta(kk) = ss(1,2); S.b(kk) = bs(1);
    S.rh(kk) = rs(1); S.stage(kk) = st(1); S.nacc(kk) = S.nacc(kk)+numel(rows);
    if numel(el)>1
      d = LOCAL_dual_mismatch(config,spaces,el,ss);
      S.defect(kk) = max([S.defect(kk),d],[],'omitnan');
      S.alt_element(kk) = el(2); S.alt_b(kk) = bs(2); S.alt_rh(kk) = rs(2);
    end
  end
end


function [s,r,ok,bmin] = LOCAL_inverse_map(Cx,Cy,X,scale,loc)
  % Newton with backtracking for the P2 map F(xi,eta) = X: at most
  % newton_steps steps, at most `halvings` step halvings per step.
  n = size(X,1); s = ones(n,2)/3;
  f = @(C,s)C(:,1)+C(:,2).*s(:,1)+C(:,3).*s(:,2)+C(:,4).*s(:,1).^2+ ...
    C(:,5).*s(:,1).*s(:,2)+C(:,6).*s(:,2).^2;
  rx = f(Cx,s)-X(:,1); ry = f(Cy,s)-X(:,2); r = hypot(rx,ry);
  active = r > 1e-3*loc.residual*scale;
  for step = 1:loc.newton_steps
    A = find(active);
    if isempty(A), break, end
    a = s(A,:); cx = Cx(A,:); cy = Cy(A,:);
    j11 = cx(:,2)+2*cx(:,4).*a(:,1)+cx(:,5).*a(:,2); j12 = cx(:,3)+cx(:,5).*a(:,1)+2*cx(:,6).*a(:,2);
    j21 = cy(:,2)+2*cy(:,4).*a(:,1)+cy(:,5).*a(:,2); j22 = cy(:,3)+cy(:,5).*a(:,1)+2*cy(:,6).*a(:,2);
    d = j11.*j22-j12.*j21;
    ds = -[(j22.*rx(A)-j12.*ry(A))./d,(-j21.*rx(A)+j11.*ry(A))./d];
    lam = ones(numel(A),1); done = false(numel(A),1);
    trial = a; trx = rx(A); try_ = ry(A); tr = r(A);
    for h = 0:loc.halvings
      J = find(~done);
      if isempty(J), break, end
      cand = a(J,:)+lam(J).*ds(J,:);
      cr_x = f(cx(J,:),cand)-X(A(J),1); cr_y = f(cy(J,:),cand)-X(A(J),2); cr = hypot(cr_x,cr_y);
      good = isfinite(cr) & cr < r(A(J));
      trial(J(good),:) = cand(good,:); trx(J(good)) = cr_x(good); try_(J(good)) = cr_y(good);
      tr(J(good)) = cr(good); done(J(good)) = true; lam(J(~good)) = lam(J(~good))/2;
    end
    s(A,:) = trial; rx(A) = trx; ry(A) = try_; r(A) = tr;
    active(A(~done)) = false;                                   % stalled
    active(A) = active(A) & r(A) > 1e-3*loc.residual*scale(A);
    if any(~isfinite(d)), active(A(~isfinite(d))) = false; end
  end
  bmin = min([1-s(:,1)-s(:,2),s],[],2);
  ok = r <= loc.residual*scale & bmin >= loc.barycentric_min;
end


function defect = LOCAL_dual_mismatch(config,spaces,elements,s)
  % Diagnostic only (D2): largest difference of the global basis values
  % reached from the owner and the other accepted inverses (all orders); Inf
  % if the candidates belong to different templates. Never a veto.
  defect = 0;
  for p = config.orders
    sp = spaces{p};
    for name = {'left','center','right'}
      t = sp.(name{1}); [in,local] = ismember(elements,t.element_ids);
      if ~all(in)
        if any(in), defect = Inf; return, end
        continue
      end
      N = LOCAL_lagrange(p,sp.alpha,s);
      base = sparse(1,t.tri_dofs(local(1),:),N(1,:),1,t.ndof);
      for j = 2:numel(elements)
        other = sparse(1,t.tri_dofs(local(j),:),N(j,:),1,t.ndof);
        defect = max(defect,full(max(abs(base-other))));
      end
    end
  end
end

%% ==================== Volume and band assembly, operators and nested checks ====================
% K, M_{p,h} by Gauss-Duffy; dM_p by the oriented band; Qqp constraint; checks.

function [K,M,area,inclusion_area] = LOCAL_assemble_p(t,p,alpha,order)
  nt = size(t.tri_dofs,1); nb = size(alpha,1); X = t.X; Y = t.Y; material = t.material;
  [lambda,weights] = LOCAL_quadrature(order);
  [Nq,Nxq,Neq] = LOCAL_lagrange(p,alpha,lambda(:,2:3));
  ia = repmat(1:nb,1,nb); ib = repelem(1:nb,nb);
  kval = zeros(nt,nb*nb); mval = kval; areas = zeros(nt,1);
  for q = 1:numel(weights)
    [~,G] = LOCAL_basis(lambda(q,:));
    j11 = X*G(1,:)'; j12 = X*G(2,:)'; j21 = Y*G(1,:)'; j22 = Y*G(2,:)';
    d = j11.*j22-j12.*j21; w = weights(q)*d;
    dx = (j22.*Nxq(q,:)-j21.*Neq(q,:))./d; dy = (-j12.*Nxq(q,:)+j11.*Neq(q,:))./d;
    wdx = w.*dx; wdy = w.*dy;
    kval = kval+wdx(:,ia).*dx(:,ib)+wdy(:,ia).*dy(:,ib);
    mval = mval+(material.*w).*(Nq(q,ia).*Nq(q,ib));
    areas = areas+w;
  end
  rows = t.tri_dofs(:,ia); cols = t.tri_dofs(:,ib);
  K = sparse(rows(:),cols(:),kval(:),t.ndof,t.ndof);
  M = sparse(rows(:),cols(:),mval(:),t.ndof,t.ndof);
  area = sum(areas); inclusion_area = sum(areas(material~=1));
end


function dM = LOCAL_band_matrix(t,b,p,alpha,batch)
  % dM = (rho_in-1) sum_points w J_H Psi(H) Psi(H)^T, at most nb^2 local
  % entries per point, accumulated in batches (no dense dof x point array).
  nb = size(alpha,1); ia = repmat((1:nb)',nb,1); ib = repelem((1:nb)',nb);
  dM = sparse(t.ndof,t.ndof); n = numel(b.xi);
  for j = 1:batch:n
    J = j:min(j+batch-1,n);
    N = LOCAL_lagrange(p,alpha,[b.xi(J),b.eta(J)]);
    dofs = t.tri_dofs(b.element(J),:);
    vals = (b.rho_minus_one*b.weight(J)).*N(:,ia).*N(:,ib);
    rows = dofs(:,ia); cols = dofs(:,ib);
    dM = dM+sparse(rows(:),cols(:),vals(:),t.ndof,t.ndof);
  end
end


function ops = LOCAL_operators(ctx,sp,band,rule,want_raw,want_nominal)
  config = ctx.config; p = sp.p; names = {'left','center','right'};
  LOCAL_progress(ctx,'assembly',struct('p',p,'rule',rule.name));
  ops = struct('p',p,'rule',rule.name,'n',sp.n,'beta',sp.beta,'raw',[]);
  checks = struct('pass',true,'reason','','rule',rule.name,'p',p,'seconds_volume',0, ...
    'seconds_band',0,'seconds_checks',0);
  exact = LOCAL_exact_areas(config);
  rho = [config.model.rho_negative,config.model.rho_center,config.model.rho_positive];
  for j = 1:3
    name = names{j}; t = sp.(name); nt = size(t.tri_dofs,1);
    LOCAL_memory_gate(config,['assembly ',name],8*nt*sp.nb^2*10);
    timer = tic;
    [Kf,Mhf,area,inclusion] = LOCAL_assemble_p(t,p,sp.alpha,rule.volume_order);
    dt = toc(timer); checks.seconds_volume = checks.seconds_volume+dt;
    LOCAL_ledger('add',['assembly_volume_',rule.name],dt);
    timer = tic;
    dMf = LOCAL_band_matrix(t,band.(name),p,sp.alpha,config.location.batch);
    dt = toc(timer); checks.seconds_band = checks.seconds_band+dt;
    LOCAL_ledger('add',['assembly_band_',rule.name],dt);
    timer = tic;
    constant = full(sum(dMf(:))); expected = (rho(j)-1)*(exact(j)-inclusion);
    Q = t.Qqp;
    Kraw = Q'*Kf*Q; Mhraw = Q'*Mhf*Q; dMraw = Q'*dMf*Q;
    herm = @(A)norm(A-A','fro')/max(norm(A,'fro'),realmin);
    kdef = herm(Kraw); mdef = herm(Mhraw); ddef = herm(dMraw);
    K = (Kraw+Kraw')/2; Mh = (Mhraw+Mhraw')/2; dM = (dMraw+dMraw')/2; M = Mh+dM;
    order = symamd(M); [~,mflag] = chol(M(order,order));
    I = t.interior;
    pattern = spones(K(I,I))+spones(M(I,I));
    tmpl = struct('name',name,'K',K,'M',M,'wall',t.wall,'interior',I,'free',t.free, ...
      'Qqp',Q,'top',t.top,'bottom',t.bottom,'tri_dofs',t.tri_dofs,'dof_xy',t.dof_xy, ...
      'amd',amd(pattern),'symbolic_nnz',NaN,'M_nominal',[]);
    tmpl.symbolic_nnz = sum(symbfact(pattern(tmpl.amd,tmpl.amd)));
    if want_nominal, tmpl.M_nominal = Mh; end
    if want_raw
      ops.raw.(name) = struct('K_full',Kf,'M_h_full',Mhf,'dM_full',dMf);
    end
    ops.(name) = tmpl;
    check = struct('area',area,'area_defect',abs(area-1),'inclusion_area_h',inclusion, ...
      'inclusion_area_exact',exact(j),'inclusion_area_defect',inclusion-exact(j), ...
      'band_constant',constant,'band_constant_expected',expected, ...
      'band_constant_defect',constant-expected,'band_signed_area',band.(name).signed_area, ...
      'dM_fro',norm(dM,'fro'),'dM_relative_to_Mh',norm(dM,'fro')/norm(Mh,'fro'), ...
      'stiffness_hermitian_defect',kdef,'mass_h_hermitian_defect',mdef, ...
      'band_hermitian_defect',ddef,'mass_chol_flag',mflag,'nnz_K',nnz(K), ...
      'free_dofs',numel(t.free),'interior_dofs',numel(I),'symbolic_chol_nnz',tmpl.symbolic_nnz);
    pass = kdef<=config.gates.matrix_hermitian && mdef<=config.gates.matrix_hermitian && ...
      ddef<=config.gates.matrix_hermitian && mflag==0 && abs(area-1)<1e-10;
    check.pass = pass; checks.(name) = check;
    if ~pass, checks.pass = false; checks.reason = [checks.reason,name,' matrix check failed; ']; end
    checks.seconds_checks = checks.seconds_checks+toc(timer);
    LOCAL_ledger('add',['assembly_checks_',rule.name],toc(timer));
    clear Kf Mhf dMf Kraw Mhraw dMraw
  end
  ops.wall_mass = blkdiag(sp.wall_mass_single,sp.wall_mass_single);
  ops.wall_chol = chol(ops.wall_mass);
  checks.wall_mass_hermitian_defect = norm(sp.wall_mass_single-sp.wall_mass_single','fro');
  ops.checks = checks;
  fprintf('STAGE assembly P%d %s: volume %.2fs band %.2fs checks %.2fs pass %d\n',p,rule.name, ...
    checks.seconds_volume,checks.seconds_band,checks.seconds_checks,checks.pass);
  if ~checks.pass && ~strcmp(ctx.config.mode,'sizing')
    error('i102:MatrixCheck','P%d %s matrix checks failed: %s',p,rule.name,checks.reason);
  end
end


function exact = LOCAL_exact_areas(config)
  theta = 2*pi*(0:8191)'/8192; exact = zeros(1,3);
  for c = -1:1
    xy = LOCAL_curve(config,c,theta); xy(:,1) = xy(:,1)-c*config.model.L;
    d = 2*pi/8192; dx = LOCAL_spectral_derivative(xy(:,1))/d; dy = LOCAL_spectral_derivative(xy(:,2))/d;
    exact(c+2) = 0.5*sum(xy(:,1).*dy-xy(:,2).*dx)*d;
  end
end


function dv = LOCAL_spectral_derivative(v)
  n = numel(v); k = [0:n/2-1,0,-n/2+1:-1]'*2*pi/n;
  dv = real(ifft(1i*k.*fft(v)));
end

%% ==================== Cell elimination, discrete DtN and near-wall extension ====================
% Weak outward wall load S = A_WW + A_WI A_II^{-1}(-A_IW), assembled in 32-column
% blocks without storing the full extension E; ordered complex QZ stable subspace.

function [S,info,fac] = LOCAL_eliminate(config,t,mu,method)
  A = t.K-mu*t.M; I = t.interior; W = t.wall;
  AII = A(I,I); AIW = A(I,W); AWI = A(W,I); nI = numel(I); nW = numel(W);
  info = struct('valid',true,'reason','','method',method,'backward',NaN,'backward_num',NaN, ...
    'backward_den',NaN,'condest',NaN,'chol_flag',NaN);
  fac = struct('apply',[]); S = [];
  rs = full(sum(abs(AII),2));
  if any(rs==0), info.valid = false; info.reason = 'ZERO_ROW'; return, end
  T = spdiags(1./sqrt(rs),0,nI,nI); B = T*AII*T;
  try
    if strcmp(method,'chol')
      p = t.amd; [Rc,flag] = chol(B(p,p)); info.chol_flag = flag;
      if flag ~= 0, info.valid = false; info.reason = 'CENTER_CHOLESKY_FAILED'; return, end
      solve = @(c)LOCAL_chol_solve(Rc,p,c); solve_h = solve;
    else
      [L,U,P,Q,R] = lu(B);
      solve = @(c)Q*(U\(L\(P*(R\c))));
      solve_h = @(c)R\(P'*(L'\(U'\(Q'*c))));
    end
  catch error_object
    info.valid = false; info.reason = ['FACTORIZATION_EXCEPTION: ',error_object.message]; return
  end
  apply = @(rhs)T*solve(T*rhs);
  block = config.solver.rhs_block; S = full(A(W,W));
  norm_A = norm(AII,1); worst = 0; worst_num = 0; worst_den = 1;
  for j = 1:block:nW
    J = j:min(j+block-1,nW);
    rhs = full(-AIW(:,J)); X = apply(rhs);
    r = AII*X-rhs;
    num = sum(abs(r),1); den = norm_A*sum(abs(X),1)+sum(abs(rhs),1);
    [value,at] = max(num./max(den,realmin));
    if value>worst, worst = value; worst_num = num(at); worst_den = den(at); end
    S(:,J) = S(:,J)+AWI*X;
  end
  info.backward = worst; info.backward_num = worst_num; info.backward_den = worst_den;
  afun = @(flag,X)LOCAL_normest_handle(flag,X,nI,solve,solve_h);
  info.condest = norm(B,1)*normest1(afun);
  if ~(info.backward<=config.gates.cell_backward)
    info.valid = false; info.reason = sprintf('CELL_BACKWARD %.3e',info.backward);
  elseif ~(info.condest<=config.gates.cell_condest)
    info.valid = false; info.reason = sprintf('CELL_CONDEST %.3e',info.condest);
  end
  fac = struct('apply',apply,'AII',AII,'norm_A',norm_A);
end


function x = LOCAL_chol_solve(Rc,p,c)
  x = zeros(size(c),'like',complex(c)); x(p,:) = Rc\(Rc'\c(p,:));
end


function y = LOCAL_normest_handle(flag,X,n,solve,solve_h)
  switch flag
    case 'dim', y = n;
    case 'real', y = false;
    case 'notransp', y = solve(X);
    case 'transp', y = solve_h(X);
  end
end


function [D,Pout,info] = LOCAL_dtn(config,S,n)
  % Copied from I9.5b: ordered complex QZ, Pout = Z1/Z0, D = S00 + S01 Pout.
  g = config.gates;
  S00 = S(1:n,1:n); S01 = S(1:n,n+1:end); S10 = S(n+1:end,1:n); S11 = S(n+1:end,n+1:end);
  Acal = [-(S11+S00),-S10;eye(n),zeros(n)]; Bcal = [S01,zeros(n);zeros(n),eye(n)];
  [AA,BB,Qz,Zz] = qz(Acal,Bcal,'complex');
  alpha = diag(AA); gamma = diag(BB);
  scale = norm(Acal,'fro')+norm(Bcal,'fro');
  magnitude = abs(alpha)+abs(gamma);
  degenerate = magnitude <= g.qz_degenerate_factor*2*n*eps*scale;
  gap = abs(abs(alpha)-abs(gamma))./magnitude;
  stable = abs(alpha)<abs(gamma);
  info = struct('valid',true,'reason','','stable_count',nnz(stable), ...
    'degenerate_count',nnz(degenerate),'min_magnitude_relative',min(magnitude)/scale, ...
    'unit_gap_min',min(gap),'z0_rcond',NaN,'invariance',NaN,'lower_block',NaN, ...
    'riccati',NaN,'riccati_num',NaN,'riccati_den',NaN,'hermitian_defect',NaN, ...
    'consistency',NaN,'consistency_rcond',NaN,'pairing_max',NaN,'pairing_count',0, ...
    'spectral_radius',NaN,'stable_multipliers',[]);
  D = []; Pout = [];
  reasons = {};
  if any(degenerate), reasons{end+1} = sprintf('QZ_DEGENERATE %d',nnz(degenerate)); end
  if any(gap<=g.unit_gap), reasons{end+1} = sprintf('UNIT_CIRCLE_GAP %.3e',min(gap)); end
  if nnz(stable)~=n, reasons{end+1} = sprintf('STABLE_COUNT %d~=%d',nnz(stable),n); end
  finite = abs(alpha)>eps*scale & abs(gamma)>eps*scale;
  zeta = alpha(finite)./gamma(finite);
  band = abs(zeta)<g.pairing_band & abs(zeta)>1/g.pairing_band; zb = zeta(band);
  if ~isempty(zb)
    mismatch = zeros(numel(zb),1);
    for j = 1:numel(zb)
      target = 1/conj(zb(j)); mismatch(j) = min(abs(zeta-target))/abs(target);
    end
    info.pairing_max = max(mismatch); info.pairing_count = numel(zb);
  end
  if ~isempty(reasons)
    info.valid = false; info.reason = strjoin(reasons,'; '); return
  end
  [AAs,BBs,Qs,Zs] = ordqz(AA,BB,Qz,Zz,stable);
  Z = Zs(:,1:n); Z1 = Z(1:n,:); Z0 = Z(n+1:end,:); Y = Qs(1:n,:)';
  info.z0_rcond = rcond(Z0);
  normA = norm(Acal,'fro'); normB = norm(Bcal,'fro');
  info.invariance = (norm(Acal*Z-Y*AAs(1:n,1:n),'fro')+norm(Bcal*Z-Y*BBs(1:n,1:n),'fro'))/ ...
    ((normA+normB)*norm(Z,'fro'));
  Ts = BBs(1:n,1:n)\AAs(1:n,1:n);
  info.lower_block = norm(Z1-Z0*Ts,'fro')/max(norm(Z1,'fro'),norm(Z0*Ts,'fro'));
  alpha_s = diag(AAs(1:n,1:n)); gamma_s = diag(BBs(1:n,1:n));
  info.stable_multipliers = alpha_s./gamma_s;
  info.spectral_radius = max(abs(info.stable_multipliers));
  if ~(info.z0_rcond>g.z0_rcond)
    info.valid = false; info.reason = sprintf('Z0_RCOND %.3e',info.z0_rcond); return
  end
  Pout = Z1/Z0;
  residual = S01*Pout^2+(S11+S00)*Pout+S10;
  info.riccati_num = norm(residual,'fro');
  info.riccati_den = norm(S01,'fro')*norm(Pout,'fro')^2+norm(S11+S00,'fro')*norm(Pout,'fro')+norm(S10,'fro');
  info.riccati = info.riccati_num/info.riccati_den;
  D = S00+S01*Pout;
  info.hermitian_defect = norm(D-D','fro')/max(1,norm(D,'fro'));
  info.consistency_rcond = rcond(S11+D);
  if info.consistency_rcond>g.consistency_rcond
    Dc = S00-S01*((S11+D)\S10);
    info.consistency = norm(D-Dc,'fro')/max(norm(D,'fro'),realmin);
  end
  reasons = {};
  if ~(info.invariance<=g.invariance), reasons{end+1} = sprintf('INVARIANCE %.3e',info.invariance); end
  if ~(info.riccati<=g.riccati), reasons{end+1} = sprintf('RICCATI %.3e',info.riccati); end
  if ~(info.hermitian_defect<=g.dtn_hermitian), reasons{end+1} = sprintf('DTN_HERMITIAN %.3e',info.hermitian_defect); end
  if ~isnan(info.consistency) && ~(info.consistency<=g.dtn_consistency)
    reasons{end+1} = sprintf('DTN_CONSISTENCY %.3e',info.consistency);
  end
  if ~isempty(reasons), info.valid = false; info.reason = strjoin(reasons,'; '); end
end


function out = LOCAL_ledger(action,name,value)
  persistent ledger total
  if isempty(ledger), ledger = struct(); total = 0; end
  out = [];
  switch action
    case 'reset'
      ledger = struct(); total = 0;
    case 'add'
      if ~isfield(ledger,name), ledger.(name) = 0; end
      ledger.(name) = ledger.(name)+value; total = total+value;
    case 'total'
      out = total;
    case 'snapshot'
      out = ledger;
    case 'close'
      out = struct('categories',ledger,'attributed_seconds',total, ...
        'matlab_function_seconds',name,'matlab_unattributed_seconds',name-total);
  end
end


function LOCAL_progress(ctx,phase,extra)
  value = struct('utc',LOCAL_utc(),'matlab_elapsed',toc(ctx.started),'phase',phase,'chain','', ...
    'p',NaN,'rule','','bracket_width',NaN,'slowest_eval_seconds',NaN,'frequency_count',NaN, ...
    'all_roots_done',false,'save_estimate_seconds',ctx.config.resources.save_estimate_seconds);
  for f = fieldnames(extra)', value.(f{1}) = extra.(f{1}); end
  if isempty(value.chain) && ~isnan(value.p), value.chain = sprintf('P%d',value.p); end
  token = regexp(value.chain,'^P(\d)-([a-z]+)$','tokens','once');
  if ~isempty(token), value.p = str2double(token{1}); value.rule = token{2}; end
  temporary = [ctx.progress_path,'.tmp'];
  LOCAL_json(temporary,value); movefile(temporary,ctx.progress_path,'f');
end


function rss = LOCAL_rss()
  [flag,text] = system(sprintf('ps -o rss= -p %d',feature('getpid')));
  rss = NaN;
  if flag==0, rss = 1024*str2double(strtrim(text)); end
end


function LOCAL_memory_gate(config,label,bytes,rss)
  if nargin<4, rss = LOCAL_rss(); end
  if rss+bytes>config.resources.internal_gate_bytes
    error('i102:ResourceStop','Predicted %s memory %.0f + RSS %.0f exceeds %.0f bytes.', ...
      label,bytes,rss,config.resources.internal_gate_bytes);
  end
end


function text = LOCAL_utc()
  text = char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSSSSSXXX'));
end


function LOCAL_json(path,value)
  text = jsonencode(LOCAL_jsonable(value),'PrettyPrint',true);
  fid = fopen(path,'w'); assert(fid>=0,'i102:IO','Cannot open JSON output.');
  cleanup = onCleanup(@()fclose(fid)); fprintf(fid,'%s\n',text);
end


function value = LOCAL_jsonable(value)
  % complex arrays become {real, imag}; structs and cells are visited recursively
  if isstruct(value)
    fields = fieldnames(value);
    for j = 1:numel(value)
      for f = 1:numel(fields), value(j).(fields{f}) = LOCAL_jsonable(value(j).(fields{f})); end
    end
  elseif iscell(value)
    value = cellfun(@LOCAL_jsonable,value,'UniformOutput',false);
  elseif issparse(value)
    value = LOCAL_jsonable(full(value));
  elseif isnumeric(value) && ~isreal(value)
    value = struct('real',real(value),'imag',imag(value));
  end
end

%% ==================== P2 geometry algebra (from I9.5b) ====================
% Geometry basis, Gauss-Duffy quadrature and Jacobian determinant extrema.

function [basis,G] = LOCAL_basis(l)
  gl = [-1,1,0;-1,0,1]; basis = [l.*(2*l-1),4*l(1)*l(2),4*l(2)*l(3),4*l(3)*l(1)];
  G = zeros(2,6);
  for j = 1:3, G(:,j) = (4*l(j)-1)*gl(:,j); end
  G(:,4) = 4*(l(1)*gl(:,2)+l(2)*gl(:,1));
  G(:,5) = 4*(l(2)*gl(:,3)+l(3)*gl(:,2));
  G(:,6) = 4*(l(3)*gl(:,1)+l(1)*gl(:,3));
end


function [lambda,weights] = LOCAL_quadrature(order)
  j = (1:order-1)'; b = j./sqrt(4*j.^2-1); [V,D] = eig(diag(b,1)+diag(b,-1));
  [x,idx] = sort(diag(D)); w = V(1,idx)'.^2; x = (x+1)/2;
  [r,s] = ndgrid(x,x); [wr,ws] = ndgrid(w,w); xi = r(:); eta = (1-xi).*s(:);
  lambda = [1-xi-eta,xi,eta]; weights = wr(:).*ws(:).*(1-xi);
end


function coefficients = LOCAL_map_coefficients(nodes)
  coefficients = [nodes(1,:);-3*nodes(1,:)-nodes(2,:)+4*nodes(4,:); ...
    -3*nodes(1,:)-nodes(3,:)+4*nodes(6,:);2*nodes(1,:)+2*nodes(2,:)-4*nodes(4,:); ...
    4*nodes(1,:)-4*nodes(4,:)+4*nodes(5,:)-4*nodes(6,:);2*nodes(1,:)+2*nodes(3,:)-4*nodes(6,:)];
end


function c = LOCAL_det_coefficients(map)
  a = map(2,:); b = map(3,:); d = map(4,:); e = map(5,:); f = map(6,:);
  cross2 = @(x,y)x(1)*y(2)-x(2)*y(1);
  c = [cross2(a,b),cross2(2*d,b)+cross2(a,e),cross2(e,b)+cross2(a,2*f), ...
    cross2(2*d,e),4*cross2(d,f),cross2(e,2*f)];
end


function value = LOCAL_q(c,x,y)
  value = c(1)+c(2)*x+c(3)*y+c(4)*x.^2+c(5)*x.*y+c(6)*y.^2;
end


function [minimum,maximum] = LOCAL_quadratic_triangle_extrema(c)
  % vertices, edge stationary points and the interior stationary point
  candidates = [0,0;1,0;0,1]; edges = [c(4),c(2);c(6),c(3);c(4)-c(5)+c(6),c(2)-c(3)+c(5)-2*c(6)];
  for j = 1:3
    if abs(edges(j,1))>eps*max(1,norm(edges(j,:),1))
      t = -edges(j,2)/(2*edges(j,1));
      if t>0 && t<1
        if j==1, p = [t,0]; elseif j==2, p = [0,t]; else, p = [t,1-t]; end
        candidates(end+1,:) = p; %#ok<AGROW>
      end
    end
  end
  H = [2*c(4),c(5);c(5),2*c(6)];
  if rcond(H)>64*eps
    p = -H\c(2:3)';
    if all(p>0) && sum(p)<1, candidates(end+1,:) = p'; end
  end
  values = LOCAL_q(c,candidates(:,1),candidates(:,2));
  minimum = min(values); maximum = max(values);
end
