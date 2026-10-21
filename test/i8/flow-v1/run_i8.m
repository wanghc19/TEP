function [result,evidence] = run_i8(output_dir)
%RUN_I8 Execute the bounded I8 star-center numerical flow.
% Purpose:
%   Locate one equal-area star-center candidate, check finite-dimensional
%   inertia and two single-axis same-mode refinements, then estimate the
%   complete raw-field material, wall, tail, and local-mass components.
% Input:
%   output_dir - Existing monitored-run directory for create-once artifacts.
% Output:
%   result   - Compact scan, stability, and raw-field numerical summary.
%   evidence - Frozen matrices, densities, signed jumps, and diagnostics.
% Main algorithm:
%   Scan one fixed B discretization, refine one valid basin on bounded
%   11-point grids, qualify the selected shoulders and single-axis variants,
%   and evaluate the same frozen physical density on independent 512/768
%   boundary grids and two shifted disk quadratures.
% Based on:
%   test/i7/scan-v1/scan_i7.m, test/i7/refine-v1/check_i7_refinement.m,
%   and test/i7/resolvent-v1/estimate_i7_resolvent.m.
% Main changes:
%   Replace the ellipse by the equal-area six-row-scaled public star contour;
%   keep the corrected public density coordinates; use no historical input.
% Numerical goal:
%   Deliver one reproducible finite-grid I8 candidate and a complete ordinary-
%   double raw-field diagnostic. No spectral or continuous certification is
%   claimed.

  if nargin ~= 1 || ~(ischar(output_dir) || ...
      (isstring(output_dir) && isscalar(output_dir)))
    error('i8:Arguments','Pass one explicit monitored output directory.');
  end
  output_dir = char(output_dir);
  if ~isfolder(output_dir)
    error('i8:Output','The monitored output directory must exist.');
  end
  artifacts = {'chkpt.mat','result.mat','evidence.mat','result.json', ...
    'audit.json','scan.csv','parts.csv'};
  for j = 1:numel(artifacts)
    if exist(fullfile(output_dir,artifacts{j}),'file') || ...
        exist(fullfile(output_dir,artifacts{j}),'dir')
      error('i8:OutputExists','Refusing to overwrite %s.',artifacts{j});
    end
  end

  timer = tic;
  model = struct('khat',NaN,'beta',0.5,'d',1,'L',1,'R',0.2, ...
    'rho_center',2,'rho_lead',17,'rho_exterior',1, ...
    'star_scale',sqrt(0.04/0.0618),'X_L',-0.5,'X_R',0.5, ...
    'H',1.1,'proxy_dist',0.2,'collar_h',0.004,'arc_band',0.01, ...
    'port_M',48);
  cfgB = struct('id','B','ntot',256,'nside',160,'ntop',160, ...
    'nproxy',80,'mpw',32,'M',48,'K',97);
  cfgN = cfgB; cfgN.id = 'N'; cfgN.ntot = 384;
  cfgM = cfgB; cfgM.id = 'M'; cfgM.M = 64; cfgM.K = 129;
  scan_cfg = struct('range',[1.45,2.25],'step',0.025, ...
    'local_nodes',11,'max_levels',5,'width_stop',1e-5);
  eval_cfg = struct('material_nodes',[512,768],'wall_nodes',[512,768], ...
    'disk_grid',[16,32;32,64],'disk_shift',[0,0.5], ...
    'lead_cells',40);

  fprintf(1,'I8 stage 0: geometry and density-coordinate controls\n');
  geometry = LOCAL_geometry(model);
  density_check = LOCAL_density_check(1.75,model,cfgB);
  if ~(geometry.pass && density_check.pass)
    error('i8:Preflight','Geometry or physical-density control failed.');
  end

  fprintf(1,'I8 stage 1: 33-point B-configuration scan\n');
  screen_k = scan_cfg.range(1):scan_cfg.step:scan_cfg.range(2);
  screen = repmat(LOCAL_empty_row(),numel(screen_k),1);
  for j = 1:numel(screen_k)
    screen(j) = LOCAL_safe_point('screen',0,j,screen_k(j),model,cfgB);
    LOCAL_print_row(screen(j));
  end
  [screen_best,screen_index] = LOCAL_best(screen);
  if isempty(screen_best)
    error('i8:NoCandidate','The B scan has no valid point.');
  end
  save(fullfile(output_dir,'chkpt.mat'),'model','cfgB','scan_cfg', ...
    'geometry','density_check','screen','-v7.3');

  fprintf(1,'I8 stage 2: bounded 11-point local refinement\n');
  levels = cell(0,1);
  screen_bracket = screen_index>1 && screen_index<numel(screen) && ...
    screen(screen_index-1).valid && screen(screen_index+1).valid;
  if ~screen_bracket
    stop_reason = 'screen winner lacks a valid strict interior bracket';
  else
    interval = LOCAL_initial_interval(screen,screen_index);
    stop_reason = 'maximum local levels reached';
    levels = cell(scan_cfg.max_levels,1);
    for level = 1:scan_cfg.max_levels
      level_k = linspace(interval(1),interval(2),scan_cfg.local_nodes);
      rows = repmat(LOCAL_empty_row(),numel(level_k),1);
      for j = 1:numel(level_k)
        rows(j) = LOCAL_safe_point('local',level,j,level_k(j),model,cfgB);
        LOCAL_print_row(rows(j));
      end
      levels{level} = rows;
      [winner,winner_index] = LOCAL_best(rows);
      if isempty(winner)
        stop_reason = sprintf('level %d has no valid point',level);
        levels = levels(1:level);
        break;
      end
      if winner_index == 1 || winner_index == numel(rows)
        stop_reason = sprintf('level %d winner is boundary-limited',level);
        levels = levels(1:level);
        break;
      end
      if ~(rows(winner_index-1).valid && rows(winner_index+1).valid)
        stop_reason = sprintf('level %d invalid neighbor blocks bracket',level);
        levels = levels(1:level);
        break;
      end
      next_interval = [rows(winner_index-1).k,rows(winner_index+1).k];
      if diff(next_interval) <= scan_cfg.width_stop
        interval = next_interval;
        stop_reason = sprintf('valid neighbor width %.6g reached',diff(interval));
        levels = levels(1:level);
        break;
      end
      interval = next_interval;
    end
  end
  all_rows = screen;
  for level = 1:numel(levels)
    all_rows = [all_rows;levels{level}(:)]; %#ok<AGROW>
  end
  [selected,~] = LOCAL_best(all_rows);
  model.khat=selected.k;
  valid_rows = all_rows([all_rows.valid]);
  shoulder_k_tolerance=64*eps*max(1,abs(selected.k));
  lower = valid_rows([valid_rows.k] < selected.k-shoulder_k_tolerance);
  upper = valid_rows([valid_rows.k] > selected.k+shoulder_k_tolerance);
  shoulder_available=~isempty(lower) && ~isempty(upper);
  if shoulder_available
    [~,jl] = max([lower.k]); [~,jr] = min([upper.k]);
    shoulders = [lower(jl).k,upper(jr).k];
  else
    shoulders = [NaN,NaN];
  end
  shoulder_delta=shoulders-selected.k;

  fprintf(1,'I8 stage 3: shoulders and single-axis mode checks\n');
  [base,base_ev] = LOCAL_full_point(selected.k,model,cfgB);
  assert(model.khat==base_ev.model.khat);
  if shoulder_available
    [left,left_ev] = LOCAL_full_point(shoulders(1),model,cfgB);
    [right,right_ev] = LOCAL_full_point(shoulders(2),model,cfgB);
    inertia = LOCAL_inertia(left_ev.matching,right_ev.matching);
  else
    left=[]; right=[]; left_ev=[]; right_ev=[];
    inertia=struct('status','UNRESOLVED_NO_TWO_SIDED_SHOULDERS', ...
      'stable',false);
  end
  [ntot,ntot_ev] = LOCAL_full_point(selected.k,model,cfgN);
  [mord,mord_ev] = LOCAL_full_point(selected.k,model,cfgM);
  modes = struct('B_N',LOCAL_mode_check(base_ev,ntot_ev), ...
    'B_M',LOCAL_mode_check(base_ev,mord_ev));

  fprintf(1,'I8 stage 4: freeze raw field and propagation\n');
  K = cfgB.K; q = base_ev.q;
  propagation = LOCAL_propagation(base_ev.pencil,base_ev.Zplus, ...
    base_ev.Zminus,q,base_ev.matching.T,K);
  center = base_ev.center; lead = base_ev.lead;
  center_density = center.H_L*q(1:K)+center.H_R*q(K+1:end);
  lead_plus = [lead.H_L,lead.H_R]*propagation.Gplus;
  lead_minus = [lead.H_L,lead.H_R]*propagation.Gminus;

  fprintf(1,'I8 stage 5: independent-grid raw material and wall terms\n');
  center_actions = cell(2,1); lead_actions = cell(2,1);
  center_jumps = cell(2,1); lead_sums = cell(2,1);
  wall_levels = cell(2,1);
  for level = 1:2
    N = eval_cfg.material_nodes(level);
    center_actions{level} = LOCAL_center_action(center,center_density,q, ...
      sqrt(model.rho_center)*selected.k,model,N);
    lead_actions{level} = LOCAL_material_action(lead,'circle', ...
      model.R,sqrt(model.rho_lead)*selected.k,model,N);
    center_jumps{level} = center_actions{level}.jump;
    lead_sums{level} = LOCAL_lead_jump_sum(lead_actions{level}, ...
      propagation,eval_cfg.lead_cells);
    center_maps = LOCAL_center_wall( ...
      center,center_density,q,model,N,N);
    lead_maps = LOCAL_cell_wall_maps(lead,model,N,N);
    wall_levels{level} = LOCAL_wall_level(center_maps,lead_maps,q, ...
      propagation,model,eval_cfg.lead_cells);
  end

  fprintf(1,'I8 stage 6: same-field shifted disk mass\n');
  mass = cell(2,1);
  beta_m = base_ev.beta_m; gamma = base_ev.gamma;
  for level = 1:2
    mass{level} = LOCAL_mass_diagnostic(center,center_density,q, ...
      beta_m,gamma,model,eval_cfg.disk_grid(level,1), ...
      eval_cfg.disk_grid(level,2),eval_cfg.material_nodes(level), ...
      eval_cfg.disk_shift(level));
  end

  fine_center = center_jumps{2}; fine_lead = lead_sums{2};
  fine_wall = wall_levels{2}; fine_mass = mass{2};
  components = LOCAL_components(fine_center,fine_lead,fine_wall,fine_mass);
  if components.complete
    epsilon_num = sqrt(max(0,components.normal_squared+ ...
      components.value_squared/model.d^2));
  else
    epsilon_num = NaN;
  end
  U_num = fine_mass.quadrature_norm;
  mu = selected.k^2;
  Cnum = LOCAL_Cnum(mu,geometry,model);
  denominator = U_num-Cnum*epsilon_num;

  refinement = struct( ...
    'material_center_value',LOCAL_rel(center_jumps{1}.value_squared, ...
      center_jumps{2}.value_squared), ...
    'material_center_normal',LOCAL_rel(center_jumps{1}.normal_squared, ...
      center_jumps{2}.normal_squared), ...
    'material_lead_value',LOCAL_rel(lead_sums{1}.value_squared, ...
      lead_sums{2}.value_squared), ...
    'material_lead_normal',LOCAL_rel(lead_sums{1}.normal_squared, ...
      lead_sums{2}.normal_squared), ...
    'wall_value',LOCAL_rel(wall_levels{1}.value_squared, ...
      wall_levels{2}.value_squared), ...
    'wall_normal',LOCAL_rel(wall_levels{1}.normal_squared, ...
      wall_levels{2}.normal_squared), ...
    'mass',LOCAL_rel(mass{1}.quadrature_norm,mass{2}.quadrature_norm));
  audit = LOCAL_audit(model,cfgB,selected,base,base_ev,propagation, ...
    center_density,lead_plus,lead_minus,center_actions,lead_actions, ...
    center_jumps,lead_sums,wall_levels,mass,components,epsilon_num);

  Rnum = NaN;
  if ~components.complete
    status = 'FINITE_PREFIX_DIAGNOSTIC';
  elseif ~audit.all_pass
    status = 'PARTIAL_AUDIT_FAILED';
  elseif geometry.pass && denominator > 0
    Rnum = 2*mu*Cnum*epsilon_num/denominator;
    status = 'UNCERTIFIED_RNUM';
  elseif geometry.pass
    status = 'NO_FINITE_RNUM';
  else
    status = 'PARTIAL_GEOMETRY_FAILED';
  end
  result = struct('schema','EPOST_I8_FLOW_V1_RESULT','status',status, ...
    'model',model,'config_B',cfgB,'config_N',cfgN,'config_M',cfgM, ...
    'scan',scan_cfg,'screen_best',screen_best,'selected',selected, ...
    'stop_reason',stop_reason,'shoulders',shoulders, ...
    'shoulder_k_tolerance',shoulder_k_tolerance, ...
    'shoulder_delta',shoulder_delta, ...
    'inertia',inertia,'modes',modes,'geometry',geometry, ...
    'density_check',density_check,'evaluation',eval_cfg, ...
    'components',components,'refinement',refinement, ...
    'epsilon_num',epsilon_num,'U_num',U_num,'mu',mu,'Cnum',Cnum, ...
    'denominator',denominator,'Rnum',Rnum, ...
    'certified',false,'runtime',toc(timer));
  evidence = struct('screen',screen,'levels',{levels},'base',base, ...
    'left',left,'right',right,'ntot',ntot,'mord',mord, ...
    'base_ev',base_ev,'left_ev',left_ev,'right_ev',right_ev, ...
    'ntot_ev',ntot_ev,'mord_ev',mord_ev,'propagation',propagation, ...
    'center_density',center_density,'lead_plus',lead_plus, ...
    'lead_minus',lead_minus, ...
    'center_actions',{cellfun(@LOCAL_compact_action,center_actions, ...
      'UniformOutput',false)}, ...
    'lead_actions',{cellfun(@LOCAL_compact_action,lead_actions, ...
      'UniformOutput',false)}, ...
    'center_jumps',{center_jumps},'lead_sums',{lead_sums}, ...
    'wall_levels',{wall_levels},'mass',{mass},'audit',audit);

  save(fullfile(output_dir,'result.mat'),'result','-v7.3');
  save(fullfile(output_dir,'evidence.mat'),'evidence','-v7.3');
  LOCAL_json(fullfile(output_dir,'result.json'),result);
  LOCAL_json(fullfile(output_dir,'audit.json'),audit);
  LOCAL_scan_csv(fullfile(output_dir,'scan.csv'),all_rows);
  LOCAL_parts_csv(fullfile(output_dir,'parts.csv'),components);
  fprintf(1,['I8 complete k=%.17g ratio=%.6e epsilon=%.6e U=%.6e ' ...
    'Rnum=%.6e seconds=%.3f\n'],selected.k,selected.aphys_ratio, ...
    epsilon_num,U_num,Rnum,result.runtime);
end

%% ==================== Scan and stability ====================
% These helpers keep the bounded scan and finite-dimensional checks compact.

function row = LOCAL_empty_row()
  row = struct('stage','','level',0,'index',0,'k',NaN,'valid',false, ...
    'reason','','adef_sigma',NaN,'adef_ratio',NaN, ...
    'aphys_sigma',NaN,'aphys_ratio',NaN,'seconds',NaN);
end

function row = LOCAL_safe_point(stage,level,index,k,model,cfg)
  row = LOCAL_empty_row(); row.stage=stage; row.level=level;
  row.index=index; row.k=k; timer=tic;
  try
    [point,~] = LOCAL_full_point(k,model,cfg);
    row.valid=true;
    row.adef_sigma=point.adef_sigma; row.adef_ratio=point.adef_ratio;
    row.aphys_sigma=point.aphys_sigma; row.aphys_ratio=point.aphys_ratio;
  catch ME
    if ~LOCAL_expected(ME), rethrow(ME); end
    row.reason=sprintf('%s: %s',ME.identifier,ME.message);
  end
  row.seconds=toc(timer);
end

function yes = LOCAL_expected(ME)
  id=ME.identifier;
  yes=startsWith(id,'i8:QZ') || startsWith(id,'i8:Propagation') || ...
    startsWith(id,'MATLAB:singular') || startsWith(id,'MATLAB:nearly') || ...
    startsWith(id,'MATLAB:illConditioned') || ...
    startsWith(id,'MATLAB:rankDeficient');
end

function [point,evidence] = LOCAL_full_point(k,model,cfg)
  model.khat=k; cfg.K=2*cfg.M+1; timer=tic;
  guard=LOCAL_solver_warning_guard(); %#ok<NASGU>
  [lead,Zplus,Zminus,pencil,beta_m,gamma,phase,qz] = ...
    LOCAL_lead(model,cfg);
  center=LOCAL_center(model,cfg);
  [matching,q]=LOCAL_matching(center,Zplus,Zminus,beta_m,gamma);
  clear guard;
  point=matching.summary; point.k=k; point.config=cfg.id;
  point.seconds=toc(timer); point.valid=true;
  evidence=struct('model',model,'config',cfg,'lead',lead,'center',center, ...
    'Zplus',Zplus,'Zminus',Zminus,'pencil',pencil,'beta_m',beta_m, ...
    'gamma',gamma,'phase',phase,'qz',qz,'matching',matching,'q',q);
end

function [best,index] = LOCAL_best(rows)
  valid=find([rows.valid]); best=[]; index=[];
  if isempty(valid), return; end
  [~,j]=min([rows(valid).aphys_ratio]); index=valid(j); best=rows(index);
end

function interval = LOCAL_initial_interval(rows,index)
  if index==1
    interval=[rows(1).k,rows(2).k];
  elseif index==numel(rows)
    interval=[rows(end-1).k,rows(end).k];
  else
    interval=[rows(index-1).k,rows(index+1).k];
  end
end

function LOCAL_print_row(row)
  if row.valid
    fprintf(1,'%s L%d k=%.17g ratio=%.6e sigma=%.6e sec=%.3f\n', ...
      row.stage,row.level,row.k,row.aphys_ratio,row.aphys_sigma,row.seconds);
  else
    fprintf(1,'%s L%d k=%.17g INVALID %s sec=%.3f\n', ...
      row.stage,row.level,row.k,row.reason,row.seconds);
  end
end

function out = LOCAL_inertia(left,right)
  c=[50,100,200];
  L=LOCAL_counts(left,c); R=LOCAL_counts(right,c);
  out=struct('c',c,'left',L,'right',R, ...
    'negative_difference',R.negative-L.negative, ...
    'stable',L.pass && R.pass && ...
      LOCAL_count_stable(L) && LOCAL_count_stable(R));
end

function yes = LOCAL_count_stable(counts)
  triples=[counts.negative;counts.unresolved;counts.positive];
  yes=all(all(triples==triples(:,1)));
end

function out = LOCAL_counts(match,c)
  n=size(match.Adef,1); rc=rcond(match.T);
  guard=LOCAL_solver_warning_guard(); %#ok<NASGU>
  H=match.Adef/match.T;
  clear guard;
  assembly=norm(match.Adef-(H*match.T),'fro')/max(1, ...
    norm(match.Adef,'fro')+norm(H,'fro')*norm(match.T,'fro'));
  Hsym=(H+H')/2; lambda_all=eig(Hsym);
  imag_leak=max(abs(imag(lambda_all))); lambda=real(lambda_all);
  s=norm(Hsym,2); dH=norm(H-Hsym,2);
  eta=dH+c*n*eps*max(1,s);
  negative=arrayfun(@(x)sum(lambda < -x),eta);
  unresolved=arrayfun(@(x)sum(abs(lambda)<=x),eta);
  positive=arrayfun(@(x)sum(lambda > x),eta);
  tol=1000*n*eps;
  finite=all(isfinite(H(:))) && all(isfinite(lambda_all));
  partition=negative+unresolved+positive;
  pass=finite && rc>=1e-8 && match.assembly_defect<=tol && ...
    assembly<=tol && imag_leak<=tol && ...
    all(partition==n);
  out=struct('n',n,'scale',s,'dH',dH,'eta',eta, ...
    'negative',negative,'unresolved',unresolved,'positive',positive, ...
    'partition',partition,'T_rcond',rc,'solve_residual',assembly, ...
    'assembly_defect',match.assembly_defect, ...
    'imaginary_leakage',imag_leak,'tolerance',tol,'finite',finite, ...
    'pass',pass,'status',LOCAL_choice(pass,'QUALIFIED','UNRESOLVED'));
end

function out = LOCAL_mode_check(a,b)
  Mmax=max(a.config.M,b.config.M);
  xa=LOCAL_embed(a.matching.trace_primary,a.matching.m,Mmax);
  xb=LOCAL_embed(b.matching.trace_primary,b.matching.m,Mmax);
  ca=LOCAL_embed(a.matching.trace_competitor,a.matching.m,Mmax);
  cb=LOCAL_embed(b.matching.trace_competitor,b.matching.m,Mmax);
  primary=LOCAL_overlap(xa,xb);
  cross=max(LOCAL_overlap(xa,cb),LOCAL_overlap(ca,xb));
  delta_a=1000*size(a.matching.Aphys,1)*eps* ...
    max(1,norm(a.matching.Aphys,2));
  delta_b=1000*size(b.matching.Aphys,1)*eps* ...
    max(1,norm(b.matching.Aphys,2));
  simple=a.matching.target_gap>delta_a && b.matching.target_gap>delta_b;
  common=min(a.config.M,b.config.M);
  tail_a=LOCAL_trace_tail(xa,Mmax,common);
  tail_b=LOCAL_trace_tail(xb,Mmax,common);
  out=struct('config_a',a.config.id,'config_b',b.config.id, ...
    'k',a.model.khat,'primary_overlap',primary,'cross_overlap',cross, ...
    'gap_a',a.matching.target_gap,'gap_b',b.matching.target_gap, ...
    'sigma1_a',a.matching.singular_values(end), ...
    'sigma2_a',a.matching.singular_values(end-1), ...
    'sigma1_b',b.matching.singular_values(end), ...
    'sigma2_b',b.matching.singular_values(end-1), ...
    'tail_a_above_common',tail_a,'tail_b_above_common',tail_b, ...
    'delta_a',delta_a,'delta_b',delta_b,'simple',simple, ...
    'pass',simple && primary>=0.99 && cross<=0.5, ...
    'status',LOCAL_choice(simple,'SIMPLE_MODE','UNRESOLVED_NEAR_DEGENERATE'));
end

function y = LOCAL_embed(x,m,Mmax)
  target=(-Mmax:Mmax).'; K=numel(target); y=zeros(2*K,size(x,2));
  [found,where]=ismember(m,target); assert(all(found));
  n=numel(m); y(where,:)=x(1:n,:); y(K+where,:)=x(n+1:end,:);
end

function value = LOCAL_overlap(x,y)
  value=abs(x(:)'*y(:))/(norm(x(:))*norm(y(:)));
end

function value = LOCAL_trace_tail(x,Mmax,Mcut)
  m=(-Mmax:Mmax).'; mask=abs(m)>Mcut;
  K=numel(m); mask=[mask;mask];
  value=sum(abs(x(mask)).^2)/max(realmin,sum(abs(x).^2));
end

%% ==================== Frozen matching objects ====================
% These helpers preserve the reviewed I7 port, QZ, and density conventions.

function [lead,Zp,Zm,pencil,beta_m,gamma,phase,diagnostic] = ...
    LOCAL_lead(model,cfg)
  [lead,~,chans] = LOCAL_cellmap('circle',model.R, ...
    model.rho_lead,model,cfg);
  K = chans.K;
  A = [-lead.R_L,eye(K);lead.T_LR,zeros(K)];
  B = [zeros(K),lead.T_RL;eye(K),-lead.R_R];
  [Zp,plus] = LOCAL_qzsub(A,B,K);
  [Zm,minus] = LOCAL_qzsub(B,A,K);
  pencil = struct('A',A,'B',B);
  beta_m = chans.beta_m(:);
  gamma = chans.gamma_m(:);
  phase = chans.phase(:);
  diagnostic = struct('plus',plus,'minus',minus);
end

function center = LOCAL_center(model,cfg)
  center = LOCAL_cellmap('star',model.star_scale, ...
    model.rho_center,model,cfg);
end

function [cellmap,C,chans,pars,proxy] = ...
    LOCAL_cellmap(flag_geom,shape_arg,rho,model,cfg)
  pars = struct('k',model.khat,'beta',model.beta,'d',model.d, ...
    'periodic_axis','y','h2d_evaluator',@LOCAL_h2d_chunked_public);
  chans = bloch.rayleigh_channels(model.khat,model.beta,model.d, ...
    cfg.M,model.X_R-model.X_L);
  if strcmp(flag_geom,'circle')
    [C,curvelen] = geom.construct_cont( ...
      cfg.ntot,'circle',0,0,shape_arg);
  elseif strcmp(flag_geom,'star')
    [C,curvelen] = geom.construct_cont(cfg.ntot,'star',0,0);
    C = shape_arg*C;
  else
    error('i8:Shape','Unsupported shape %s.',flag_geom);
  end
  mfscfg = struct('H',model.H,'proxy_dist',model.proxy_dist, ...
    'N_side',cfg.nside,'N_top',cfg.ntop, ...
    'N_proxy_edge',cfg.nproxy,'M_pw',cfg.mpw);
  proxy = kernel.precomp_proxy(pars,mfscfg);
  cellmap = bloch.construct_S(C,model.khat,sqrt(rho)*model.khat, ...
    pars,proxy,curvelen,chans,model.X_L,model.X_R);
  cellmap.i8_geometry = C;
  cellmap.i8_pars = pars;
  cellmap.i8_proxy = proxy;
  cellmap.i8_shape = flag_geom;
  cellmap.i8_arg = shape_arg;
end

function [out,q] = LOCAL_matching(cellmap,Zp,Zm,beta_m,gamma)
  K = numel(gamma); G = diag(gamma); I = eye(K);
  [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma);
  T = [I+cellmap.R_L,cellmap.T_RL;cellmap.T_LR,I+cellmap.R_R];
  N0 = [1i*G*(cellmap.R_L-I),1i*G*cellmap.T_RL; ...
    1i*G*cellmap.T_LR,1i*G*(cellmap.R_R-I)];
  L = blkdiag(Lm,Lp);
  Adef = [(1i*G-Lm)*cellmap.R_L-(1i*G+Lm), ...
    (1i*G-Lm)*cellmap.T_RL; ...
    (1i*G-Lp)*cellmap.T_LR, ...
    (1i*G-Lp)*cellmap.R_R-(1i*G+Lp)];
  b = sqrt(1+abs(beta_m).^2);
  rowwt = repmat(sqrt(1./b),2,1);
  ampwt = b+abs(gamma).^2./b;
  colwt = repmat(1./sqrt(ampwt),2,1);
  Aphys = rowwt.*Adef.*colwt.';
  [~,S,V] = svd(Aphys,'econ'); singular = diag(S);
  q = colwt.*V(:,end); q = q/norm(q);
  [~,phase_anchor] = max(abs(q));
  q = q*exp(-1i*angle(q(phase_anchor)));
  if real(q(phase_anchor)) < 0, q = -q; end
  residual = Adef*q;
  q2 = colwt.*V(:,end-1); q2 = q2/norm(q2);
  m = (-(numel(gamma)-1)/2:(numel(gamma)-1)/2).';
  assembly_defect=norm(Adef-(N0-L*T),'fro')/max(1, ...
    norm(Adef,'fro')+norm(N0,'fro')+norm(L,'fro')*norm(T,'fro'));
  summary = struct('adef_sigma',min(svd(Adef,'econ')), ...
    'adef_ratio',min(svd(Adef,'econ'))/max(svd(Adef,'econ')), ...
    'aphys_sigma',singular(end),'aphys_ratio',singular(end)/singular(1), ...
    'q_norm',norm(q),'phase_anchor_index',phase_anchor, ...
    'phase_anchor_value',real(q(phase_anchor)), ...
    'residual_norm',norm(residual));
  out = struct('Adef',Adef,'Aphys',Aphys,'T',T,'Lp',Lp,'Lm',Lm, ...
    'N0',N0,'L',L,'assembly_defect',assembly_defect, ...
    'row_weight',rowwt,'column_weight',colwt,'singular_values',singular, ...
    'residual',residual,'summary',summary,'m',m, ...
    'trace_primary',T*q,'trace_competitor',T*q2, ...
    'target_gap',singular(end-1)-singular(end));
end

function out = LOCAL_propagation(pencil,Zp,Zm,q,center_trace,K)
  plus = LOCAL_action(pencil.A,pencil.B,Zp,false,K);
  minus = LOCAL_action(pencil.A,pencil.B,Zm,true,K);
  Ap = Zp(1:K,:); Bp = Zp(K+1:end,:);
  Am = Zm(1:K,:); Bm = Zm(K+1:end,:);
  Dplus = Ap+Bp; Dminus = Am+Bm;
  trace = center_trace*q;
  left_trace = trace(1:K); right_trace = trace(K+1:end);
  cplus = Dplus\right_trace;
  cminus = Dminus\left_trace;
  plus_coordinate_residual = norm(Dplus*cplus-right_trace)/ ...
    max(1,norm(right_trace));
  minus_coordinate_residual = norm(Dminus*cminus-left_trace)/ ...
    max(1,norm(left_trace));
  Gplus = [Ap;Bp*plus.P];
  Gminus = [Am*minus.P;Bm];
  plus_recurrence_residual = norm( ...
    pencil.A*Zp-pencil.B*Zp*plus.P,'fro')/ ...
    max(1,norm(pencil.A*Zp,'fro')+norm(pencil.B*Zp*plus.P,'fro'));
  minus_recurrence_residual = norm( ...
    pencil.B*Zm-pencil.A*Zm*minus.P,'fro')/ ...
    max(1,norm(pencil.B*Zm,'fro')+norm(pencil.A*Zm*minus.P,'fro'));
  out = struct('Pplus',plus.P,'Pminus',minus.P, ...
    'Dplus',Dplus,'Dminus',Dminus, ...
    'Gplus',Gplus,'Gminus',Gminus, ...
    'cplus',cplus,'cminus',cminus, ...
    'plus_coordinate_residual',plus_coordinate_residual, ...
    'minus_coordinate_residual',minus_coordinate_residual, ...
    'plus_recurrence_residual',plus_recurrence_residual, ...
    'minus_recurrence_residual',minus_recurrence_residual, ...
    'plus_diagnostic',rmfield(plus,'P'), ...
    'minus_diagnostic',rmfield(minus,'P'));
end

function out = LOCAL_action(A,B,Z,reversed,K)
  if reversed, C=A*Z; rhs=B*Z; else, C=B*Z; rhs=A*Z; end
  [~,R] = qr(C,0); rc = rcond(R); P = C\rhs;
  residual = norm(C*P-rhs,'fro')/max(1, ...
    norm(C,'fro')*norm(P,2)+norm(rhs,'fro'));
  if rank(R) ~= K || rc < 1e-8 || residual > 1e-10
    error('i8:Propagation','A lead propagation map failed qualification.');
  end
  out = struct('P',P,'thin_qr_rcond',rc,'solve_residual',residual, ...
    'frobenius_norm',norm(P,'fro'),'spectral_norm',norm(P,2));
end

function [Zs,diagnostic] = LOCAL_qzsub(A,B,K)
  rho = hypot(norm(A,'fro'),norm(B,'fro'));
  if ~isfinite(rho) || rho == 0
    error('i8:QZScale','The QZ pencil scale is zero or nonfinite.');
  end
  A = A/rho; B = B/rho;
  [S,T,Q,Z] = qz(A,B,'complex');
  res = hypot(norm(A-Q'*S*Z','fro'),norm(B-Q'*T*Z','fro'));
  tol = max(100*eps,10*res);
  alpha = diag(S); theta = diag(T); scale = hypot(abs(alpha),abs(theta));
  indet = scale <= tol; scale(indet) = 1;
  an = abs(alpha)./scale; tn = abs(theta)./scale;
  infinite = ~indet & tn <= tol & an > tol;
  neutral = ~indet & ~infinite & abs(an-tn) <= tol;
  stable = ~indet & ~infinite & ~neutral & an < tn-tol;
  unstable = infinite | (~indet & ~neutral & an > tn+tol);
  if sum(stable) ~= K || sum(unstable) ~= K || any(indet) || any(neutral)
    error('i8:QZClassification', ...
      'stable=%d unstable=%d neutral=%d indet=%d expected=%d.', ...
      sum(stable),sum(unstable),sum(neutral),sum(indet),K);
  end
  [~,~,~,Zo] = ordqz(S,T,Q,Z,stable); Zs = Zo(:,1:K);
  diagnostic = struct('stable',sum(stable),'unstable',sum(unstable), ...
    'neutral',sum(neutral),'indeterminate',sum(indet), ...
    'residual',res,'tolerance',tol);
end

function [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma)
  K = numel(gamma); G = diag(gamma);
  Ap = Zp(1:K,:); Bp = Zp(K+1:end,:);
  Am = Zm(1:K,:); Bm = Zm(K+1:end,:);
  Dp = Ap+Bp; Np = 1i*G*(Ap-Bp);
  Dm = Am+Bm; Nm = -1i*G*(Am-Bm);
  Lp = (Dp.'\Np.').'; Lm = (Dm.'\Nm.').';
end

%% ==================== Physical material jumps ====================
% Signed value and ordinary-normal jumps are evaluated before their moduli.

function out = LOCAL_material_action(cellmap,flag_geom,shape_arg,kint,model,N)
  if strcmp(flag_geom,'circle')
    [C,curvelen] = geom.construct_cont(N,'circle',0,0,shape_arg);
  elseif strcmp(flag_geom,'star')
    [C,curvelen] = geom.construct_cont(N,'star',0,0);
    C = shape_arg*C;
  else
    error('i8:Shape','Unsupported shape %s.',flag_geom);
  end
  curve = LOCAL_curve(flag_geom,shape_arg,N);
  boundary_speed = hypot(C(2,:),C(5,:)).';
  boundary_weights = (curvelen/N)*boundary_speed;
  original_density_map = [cellmap.H_L,cellmap.H_R];
  density_map = LOCAL_interp_density_map(original_density_map,N);
  A_scaled = op.construct_A_QP(C,model.khat,kint, ...
    cellmap.i8_pars,cellmap.i8_proxy,curvelen);
  [B_L,B_R] = bloch.incident_rhs(C,cellmap.channels, ...
    model.X_L,model.X_R);
  B = [B_L,B_R];
  density_scale = sqrt(repmat(boundary_weights,2,1));
  scaled_density_map = density_scale.*density_map;
  scaled_residual_action = A_scaled*scaled_density_map+density_scale.*B;
  raw_residual_action = scaled_residual_action./density_scale;
  A_raw = (A_scaled.*density_scale.')./density_scale;
  raw_from_matrix = A_raw*density_map+B;
  signed_value_action = raw_residual_action(1:N,:);
  signed_normal_action = -raw_residual_action(N+1:end,:);
  out = struct('shape',flag_geom,'shape_arg',shape_arg,'source_nodes',N, ...
    'target_nodes',N,'weights',boundary_weights, ...
    'signed_value_action',signed_value_action, ...
    'signed_normal_action',signed_normal_action, ...
    'density_map',density_map,'density_scale',density_scale, ...
    'A_scaled',A_scaled,'B',B, ...
    'scale_roundtrip_defect',norm( ...
      scaled_density_map./density_scale-density_map,'fro')/ ...
      max(1,norm(density_map,'fro')), ...
    'raw_matrix_identity_defect',norm( ...
      raw_from_matrix-raw_residual_action,'fro')/ ...
      max(1,norm(raw_residual_action,'fro')), ...
    'normalized_action_frobenius',norm(raw_residual_action,'fro')/ ...
      max(1,norm(B,'fro')+norm(A_raw,'fro')*norm(density_map,'fro')), ...
    'interpolation_roundtrip_defect',norm( ...
      LOCAL_interp_density_map(density_map,size(original_density_map,1)/2)- ...
      original_density_map,'fro')/max(1,norm(original_density_map,'fro')), ...
    'physical_arclength_sum',sum(boundary_weights), ...
    'normal_unit_defect',max(abs(hypot(curve.nx,curve.ny)-1)));
end

function out = LOCAL_center_action(cellmap,density,q,kint,model,N)
%LOCAL_CENTER_ACTION Apply the raw operator to the frozen stored density.

  [C,curvelen] = geom.construct_cont(N,'star',0,0);
  C = model.star_scale*C;
  curve = LOCAL_curve('star',model.star_scale,N);
  weights = (curvelen/N)*hypot(C(2,:),C(5,:)).';
  eta = LOCAL_interp_density_map(density,N);
  A_scaled = op.construct_A_QP(C,model.khat,kint, ...
    cellmap.i8_pars,cellmap.i8_proxy,curvelen);
  [B_L,B_R] = bloch.incident_rhs(C,cellmap.channels, ...
    model.X_L,model.X_R);
  Bq = [B_L,B_R]*q;
  scale = sqrt(repmat(weights,2,1));
  raw = (A_scaled*(scale.*eta))./scale+Bq;
  value = raw(1:N); normal = -raw(N+1:end);
  jump = struct('value',value,'normal',normal, ...
    'value_squared',real(sum(weights.*abs(value).^2)), ...
    'normal_squared',real(sum(weights.*abs(normal).^2)));
  out = struct('shape','star','source_nodes',N,'weights',weights, ...
    'signed_value',value,'signed_normal',normal,'jump',jump, ...
    'density',eta,'scale_roundtrip_defect',norm((scale.*eta)./scale-eta)/ ...
      max(1,norm(eta)), ...
    'normal_unit_defect',max(abs(hypot(curve.nx,curve.ny)-1)));
end

function out = LOCAL_apply_jump(action,state)
  value = action.signed_value_action*state;
  normal = action.signed_normal_action*state;
  out = struct('value',value,'normal',normal, ...
    'value_squared',real(sum(action.weights.*abs(value).^2)), ...
    'normal_squared',real(sum(action.weights.*abs(normal).^2)));
end

function out = LOCAL_lead_jump_sum(action,propagation,max_cells)
  plus = propagation.cplus; minus = propagation.cminus;
  rows = repmat(struct('index',0,'plus_state_norm',0, ...
    'minus_state_norm',0,'value_squared',0,'normal_squared',0), ...
    max_cells,1);
  value_squared = 0; normal_squared = 0;
  for n = 0:max_cells-1
    xp = propagation.Gplus*plus; xm = propagation.Gminus*minus;
    jp = LOCAL_apply_jump(action,xp); jm = LOCAL_apply_jump(action,xm);
    rows(n+1) = struct('index',n,'plus_state_norm',norm(xp), ...
      'minus_state_norm',norm(xm), ...
      'value_squared',jp.value_squared+jm.value_squared, ...
      'normal_squared',jp.normal_squared+jm.normal_squared);
    value_squared = value_squared+rows(n+1).value_squared;
    normal_squared = normal_squared+rows(n+1).normal_squared;
    plus = propagation.Pplus*plus;
    minus = propagation.Pminus*minus;
  end
  xp = propagation.Gplus*plus; xm = propagation.Gminus*minus;
  next_plus = LOCAL_apply_jump(action,xp);
  next_minus = LOCAL_apply_jump(action,xm);
  next_value = next_plus.value_squared+next_minus.value_squared;
  next_normal = next_plus.normal_squared+next_minus.normal_squared;
  value_ratio = next_value/max(realmin,rows(end).value_squared);
  normal_ratio = next_normal/max(realmin,rows(end).normal_squared);
  [value_tail,value_tail_available] = ...
    LOCAL_geometric_tail(next_value,value_ratio);
  [normal_tail,normal_tail_available] = ...
    LOCAL_geometric_tail(next_normal,normal_ratio);
  tail_candidate_available = value_tail_available && normal_tail_available;
  out = struct('value_squared',value_squared+value_tail, ...
    'normal_squared',normal_squared+normal_tail, ...
    'finite_value_squared',value_squared, ...
    'finite_normal_squared',normal_squared, ...
    'tail_value_squared_candidate',value_tail, ...
    'tail_normal_squared_candidate',normal_tail, ...
    'tail_value_ratio',value_ratio,'tail_normal_ratio',normal_ratio, ...
    'cells',rows, ...
    'next_plus_coordinate_norm',norm(plus), ...
    'next_minus_coordinate_norm',norm(minus), ...
    'finite_cell_count_each_side',max_cells, ...
    'tail_candidate_available',tail_candidate_available, ...
    'omitted_tail_certified',false);
end

function [value,available] = LOCAL_geometric_tail(next_term,ratio)
  if isfinite(next_term) && isfinite(ratio) && ratio >= 0 && ratio < 1
    value = next_term/(1-ratio);
    available = true;
  else
    value = NaN;
    available = false;
  end
end

function layer = LOCAL_qp_layer(source,target,pars,proxy)
  nt = numel(target.x); ns = numel(source.x);
  value = zeros(nt,2*ns); normal = zeros(nt,2*ns);
  batch = 64;
  src = [source.x.';source.y.'];
  for first = 1:batch:nt
    index = first:min(first+batch-1,nt);
    trg = [target.x(index).';target.y(index).'];
    [P,Gx,Gy,Hxx,Hxy,Hyy] = ...
      kernel.qpgreen_mfs_pairmat(src,trg,pars,proxy);
    wt = source.weights.'; sx = source.nx.'; sy = source.ny.';
    D = -(LOCAL_row_scale(Gx,sx)+LOCAL_row_scale(Gy,sy)).*wt;
    S = -P.*wt;
    nx = target.nx(index); ny = target.ny(index);
    Ttau = -(nx.*(Hxx.*sx+Hxy.*sy)+ ...
      ny.*(Hxy.*sx+Hyy.*sy)).*wt;
    Nzeta = -(nx.*Gx+ny.*Gy).*wt;
    value(index,:) = [D,S];
    normal(index,:) = [Ttau,Nzeta];
  end
  layer = struct('value',value,'normal',normal);
end

function out = LOCAL_row_scale(matrix,row)
  out = matrix.*row;
end

function curve = LOCAL_curve(flag_geom,shape_arg,N)
  if strcmp(flag_geom,'circle')
    [C,~] = geom.construct_cont(N,'circle',0,0,shape_arg);
  elseif strcmp(flag_geom,'star')
    [C,~] = geom.construct_cont(N,'star',0,0);
    C = shape_arg*C;
  else
    error('i8:Shape','Unsupported shape %s.',flag_geom);
  end
  t = (0:N-1)'*2*pi/N;
  x=C(1,:).'; y=C(4,:).'; xt=C(2,:).'; yt=C(5,:).';
  speed = hypot(xt,yt);
  nx = yt./speed; ny = -xt./speed;
  weights = (2*pi/N)*speed;
  curve = struct('t',t,'x',x,'y',y,'xt',xt,'yt',yt, ...
    'speed',speed,'nx',nx,'ny',ny,'weights',weights);
end

function H = LOCAL_interp_density_map(H0,N)
  n0 = size(H0,1)/2;
  H = [interpft(H0(1:n0,:),N,1);interpft(H0(n0+1:end,:),N,1)];
end

%% ==================== Walls and local mass ====================
% These helpers use physical samples rather than a target Fourier norm.

function out = LOCAL_cell_wall_maps(cellmap,model,Nsource,Ntarget)
  shape = cellmap.i8_shape; shape_arg = cellmap.i8_arg;
  source = LOCAL_curve(shape,shape_arg,Nsource);
  H = LOCAL_interp_density_map([cellmap.H_L,cellmap.H_R],Nsource);
  y = -model.d/2+(0:Ntarget-1)'*model.d/Ntarget;
  left = struct('x',model.X_L*ones(Ntarget,1),'y',y, ...
    'nx',ones(Ntarget,1),'ny',zeros(Ntarget,1));
  right = struct('x',model.X_R*ones(Ntarget,1),'y',y, ...
    'nx',ones(Ntarget,1),'ny',zeros(Ntarget,1));
  layer_left = LOCAL_qp_layer(source,left,cellmap.i8_pars,cellmap.i8_proxy);
  layer_right = LOCAL_qp_layer(source,right,cellmap.i8_pars,cellmap.i8_proxy);
  geometry_left = struct('x',left.x,'y',left.y,'nx',left.nx,'ny',left.ny);
  geometry_right = struct('x',right.x,'y',right.y, ...
    'nx',right.nx,'ny',right.ny);
  [BLL,BLR] = bloch.incident_rhs(geometry_left,cellmap.channels, ...
    model.X_L,model.X_R);
  [BRL,BRR] = bloch.incident_rhs(geometry_right,cellmap.channels, ...
    model.X_L,model.X_R);
  Bleft = [BLL,BLR]; Bright = [BRL,BRR];
  out = struct('nodes',Ntarget,'y',y, ...
    'left_value',Bleft(1:Ntarget,:)+layer_left.value*H, ...
    'left_dx',Bleft(Ntarget+1:end,:)+layer_left.normal*H, ...
    'right_value',Bright(1:Ntarget,:)+layer_right.value*H, ...
    'right_dx',Bright(Ntarget+1:end,:)+layer_right.normal*H);
end

function out = LOCAL_center_wall(cellmap,density,q,model,Nsource,Ntarget)
%LOCAL_CENTER_WALL Evaluate the same stored center density on both walls.

  source = LOCAL_curve('star',model.star_scale,Nsource);
  eta = LOCAL_interp_density_map(density,Nsource);
  y = -model.d/2+(0:Ntarget-1)'*model.d/Ntarget;
  left = struct('x',model.X_L*ones(Ntarget,1),'y',y, ...
    'nx',ones(Ntarget,1),'ny',zeros(Ntarget,1));
  right = struct('x',model.X_R*ones(Ntarget,1),'y',y, ...
    'nx',ones(Ntarget,1),'ny',zeros(Ntarget,1));
  layer_left = LOCAL_qp_layer(source,left,cellmap.i8_pars,cellmap.i8_proxy);
  layer_right = LOCAL_qp_layer(source,right,cellmap.i8_pars,cellmap.i8_proxy);
  [BLL,BLR] = bloch.incident_rhs(left,cellmap.channels,model.X_L,model.X_R);
  [BRL,BRR] = bloch.incident_rhs(right,cellmap.channels,model.X_L,model.X_R);
  Bleft=[BLL,BLR]*q; Bright=[BRL,BRR]*q;
  out=struct('nodes',Ntarget,'y',y, ...
    'left_value',Bleft(1:Ntarget)+layer_left.value*eta, ...
    'left_dx',Bleft(Ntarget+1:end)+layer_left.normal*eta, ...
    'right_value',Bright(1:Ntarget)+layer_right.value*eta, ...
    'right_dx',Bright(Ntarget+1:end)+layer_right.normal*eta);
end

function out = LOCAL_wall_level(center,lead,q,propagation,model,max_cells)
  weight = model.d/center.nodes;
  input_plus = propagation.Gplus*propagation.cplus;
  input_minus = propagation.Gminus*propagation.cminus;
  value_left = lead.right_value*input_minus-center.left_value;
  value_right = lead.left_value*input_plus-center.right_value;
  normal_left = lead.right_dx*input_minus-center.left_dx;
  normal_right = center.right_dx-lead.left_dx*input_plus;
  interface_value = weight*(sum(abs(value_left).^2)+sum(abs(value_right).^2));
  interface_normal = weight*(sum(abs(normal_left).^2)+sum(abs(normal_right).^2));
  plus = propagation.cplus; minus = propagation.cminus;
  rows = repmat(struct('index',0,'value_squared',0,'normal_squared',0), ...
    max_cells,1);
  internal_value = 0; internal_normal = 0;
  for n = 0:max_cells-1
    plus_next = propagation.Pplus*plus;
    minus_next = propagation.Pminus*minus;
    current_plus = propagation.Gplus*plus;
    next_plus = propagation.Gplus*plus_next;
    current_minus = propagation.Gminus*minus;
    next_minus = propagation.Gminus*minus_next;
    vp = lead.left_value*next_plus-lead.right_value*current_plus;
    np = lead.right_dx*current_plus-lead.left_dx*next_plus;
    vm = lead.right_value*next_minus-lead.left_value*current_minus;
    nm = lead.right_dx*next_minus-lead.left_dx*current_minus;
    rows(n+1) = struct('index',n, ...
      'value_squared',real(weight*(sum(abs(vp).^2)+sum(abs(vm).^2))), ...
      'normal_squared',real(weight*(sum(abs(np).^2)+sum(abs(nm).^2))));
    internal_value = internal_value+rows(n+1).value_squared;
    internal_normal = internal_normal+rows(n+1).normal_squared;
    plus = plus_next; minus = minus_next;
  end
  plus_next = propagation.Pplus*plus;
  minus_next = propagation.Pminus*minus;
  vp = lead.left_value*(propagation.Gplus*plus_next)- ...
    lead.right_value*(propagation.Gplus*plus);
  np = lead.right_dx*(propagation.Gplus*plus)- ...
    lead.left_dx*(propagation.Gplus*plus_next);
  vm = lead.right_value*(propagation.Gminus*minus_next)- ...
    lead.left_value*(propagation.Gminus*minus);
  nm = lead.right_dx*(propagation.Gminus*minus_next)- ...
    lead.left_dx*(propagation.Gminus*minus);
  next_value = real(weight*(sum(abs(vp).^2)+sum(abs(vm).^2)));
  next_normal = real(weight*(sum(abs(np).^2)+sum(abs(nm).^2)));
  value_ratio = next_value/max(realmin,rows(end).value_squared);
  normal_ratio = next_normal/max(realmin,rows(end).normal_squared);
  [tail_value,value_tail_available] = ...
    LOCAL_geometric_tail(next_value,value_ratio);
  [tail_normal,normal_tail_available] = ...
    LOCAL_geometric_tail(next_normal,normal_ratio);
  out = struct('nodes',center.nodes,'y',center.y, ...
    'center_lead_value_left',value_left, ...
    'center_lead_value_right',value_right, ...
    'center_lead_dx_left',normal_left, ...
    'center_lead_dx_right',normal_right, ...
    'center_lead_value_squared',real(interface_value), ...
    'center_lead_normal_squared',real(interface_normal), ...
    'internal_rows',rows,'internal_value_squared',internal_value, ...
    'internal_normal_squared',internal_normal, ...
    'tail_value_squared_candidate',tail_value, ...
    'tail_normal_squared_candidate',tail_normal, ...
    'tail_value_ratio',value_ratio,'tail_normal_ratio',normal_ratio, ...
    'value_squared',real(interface_value)+internal_value+tail_value, ...
    'normal_squared',real(interface_normal)+internal_normal+tail_normal, ...
    'tail_candidate_available', ...
      value_tail_available && normal_tail_available, ...
    'tail_certified',false);
end

function out = LOCAL_mass_diagnostic(center,density,q,beta_m,gamma, ...
    model,Nr,Ntheta,Nsource,theta_shift)
  disk_center = [3/8;0]; radius = 1/16;
  radial = radius*sqrt(((1:Nr)-0.5)/Nr);
  theta = ((0:Ntheta-1)+theta_shift)*2*pi/Ntheta;
  [rr,tt] = ndgrid(radial,theta);
  targets = disk_center+[rr(:).'.*cos(tt(:).');rr(:).'.*sin(tt(:).')];
  [value,grad] = LOCAL_center_field(center,density,q,beta_m,gamma, ...
    model,targets,Nsource);
  area = pi*radius^2;
  quadrature_norm = sqrt(area*mean(abs(value).^2));
  center_target = disk_center;
  [value_center,~] = LOCAL_center_field(center,density,q,beta_m,gamma, ...
    model,center_target,Nsource);
  gradient_samples = sqrt(sum(abs(grad).^2,1));
  sampled_gradient_max = max(gradient_samples);
  cone_point_margin = max(abs(value_center)-radius*sampled_gradient_max,0);
  cone_candidate = sqrt(pi)*radius*cone_point_margin;
  out = struct('center',disk_center,'radius',radius, ...
    'radial_nodes',Nr,'angular_nodes',Ntheta, ...
    'angular_shift',theta_shift, ...
    'quadrature_norm',quadrature_norm, ...
    'center_value_abs',abs(value_center), ...
    'sampled_gradient_max',sampled_gradient_max, ...
    'cone_point_margin',cone_point_margin, ...
    'cone_candidate',cone_candidate, ...
    'one_sided_certified',false,'sample_values',value, ...
    'sample_gradient',grad);
end

function [value,grad] = LOCAL_center_field(center,density,q,beta_m,gamma, ...
    model,targets,Nsource)
  source = LOCAL_curve('star',model.star_scale,Nsource);
  n0 = numel(density)/2;
  eta = [interpft(density(1:n0),Nsource); ...
    interpft(density(n0+1:end),Nsource)];
  tau = eta(1:Nsource); zeta = eta(Nsource+1:end);
  value = zeros(1,size(targets,2)); grad = zeros(2,size(targets,2));
  batch = 32;
  src = [source.x.';source.y.'];
  for first = 1:batch:size(targets,2)
    index = first:min(first+batch-1,size(targets,2));
    trg = targets(:,index);
    [P,Gx,Gy,Hxx,Hxy,Hyy] = ...
      kernel.qpgreen_mfs_pairmat(src,trg,center.i8_pars,center.i8_proxy);
    wt = source.weights; nx = source.nx; ny = source.ny;
    charge_x = nx.*wt.*tau; charge_y = ny.*wt.*tau;
    charge_z = wt.*zeta;
    layer_value = -(Gx*charge_x+Gy*charge_y)-P*charge_z;
    layer_x = -(Hxx*charge_x+Hxy*charge_y)-Gx*charge_z;
    layer_y = -(Hxy*charge_x+Hyy*charge_y)-Gy*charge_z;
    [incident,incident_grad] = LOCAL_incident(q,beta_m,gamma,model,trg);
    value(index) = incident+layer_value.';
    grad(:,index) = incident_grad+[layer_x.';layer_y.'];
  end
end

function [value,grad] = LOCAL_incident(q,beta_m,gamma,model,target)
  K = numel(gamma); qL = q(1:K); qR = q(K+1:end);
  x = target(1,:).'; y = target(2,:).';
  psi = exp(1i*y*beta_m.')/sqrt(model.d);
  left = exp(1i*(x-model.X_L)*gamma.').*psi;
  right = exp(-1i*(x-model.X_R)*gamma.').*psi;
  value = (left*qL+right*qR).';
  gradx = (left*(1i*gamma.*qL)+right*(-1i*gamma.*qR)).';
  grady = ((left+0).* (1i*beta_m.'))*qL+ ...
    ((right+0).* (1i*beta_m.'))*qR;
  grad = [gradx;grady.'];
end

%% ==================== I8 diagnostics and outputs ====================
% These helpers close the star geometry, control, ledger, and audit records.

function out = LOCAL_geometry(model)
  nodes=[4096,8192];
  levels(1)=LOCAL_geom_level(model,nodes(1));
  levels(2)=LOCAL_geom_level(model,nodes(2));
  pass=all([levels.pass]);
  out=struct('sample_nodes',nodes,'scale',model.star_scale, ...
    'area_target',0.04*pi,'levels',levels, ...
    'curvature_max',max([levels.curvature_max]), ...
    'theta',min([levels.theta]), ...
    'area_relative_drift',LOCAL_rel(levels(1).area,levels(2).area), ...
    'curvature_relative_drift',LOCAL_rel( ...
      levels(1).curvature_max,levels(2).curvature_max), ...
    'far_chord_relative_drift',LOCAL_rel( ...
      levels(1).far_chord_min,levels(2).far_chord_min), ...
    'pass',pass,'certified',false);
end

function out = LOCAL_geom_level(model,N)
  [C0,~]=geom.construct_cont(N,'star',0,0); C=model.star_scale*C0;
  dt=2*pi/N; speed=hypot(C(2,:),C(5,:));
  curvature=(C(2,:).*C(6,:)-C(5,:).*C(3,:))./speed.^3;
  segment=dt*speed; total=sum(segment); doubled=[segment,segment];
  cs=[0,cumsum(doubled)]; z=C(1,:)+1i*C(4,:);
  n=(C(5,:)-1i*C(2,:))./speed;
  zp=z+model.collar_h*n; zm=z-model.collar_h*n;
  far_min=inf; offset_min=inf;
  for offset=1:floor(N/2)
    index=1:N; forward=cs(index+offset)-cs(index);
    mask=min(forward,total-forward)>=model.arc_band;
    if any(mask)
      other=mod(index+offset-1,N)+1;
      distance=abs(z(other)-z(index));
      far_min=min(far_min,min(distance(mask)));
      offset_distance=min([abs(zp(other)-zp(index)); ...
        abs(zp(other)-zm(index));abs(zm(other)-zp(index)); ...
        abs(zm(other)-zm(index))],[],1);
      offset_min=min(offset_min,min(offset_distance(mask)));
    end
  end
  K=max(abs(curvature)); theta=1-model.collar_h*K;
  local_factor=K*(model.arc_band/2+model.collar_h);
  wall_clear=min(model.X_R-max(C(1,:)),min(C(1,:))-model.X_L);
  copy_y=model.d-(max(C(4,:))-min(C(4,:)));
  lead_wall_clear=model.X_R-model.R;
  lead_copy_clear=model.d-2*model.R;
  lead_gap=min([min(hypot(C(1,:)-1,C(4,:))), ...
    min(hypot(C(1,:)+1,C(4,:)))])-model.R;
  disk_gap=min(hypot(C(1,:)-3/8,C(4,:)))-1/16;
  area=0.5*dt*sum(C(1,:).*C(5,:)-C(4,:).*C(2,:));
  area_defect=abs(area-0.04*pi);
  scale_defect=norm(C-model.star_scale*C0,'fro');
  area_tolerance=1e-12;
  scale_tolerance=100*eps*max(1,norm(C,'fro'));
  pass=min(speed)>0 && theta>0 && local_factor<1 && ...
    far_min>2*model.collar_h && offset_min>0 && ...
    wall_clear>2*model.collar_h && ...
    copy_y>2*model.collar_h && ...
    lead_wall_clear>2*model.collar_h && ...
    lead_copy_clear>2*model.collar_h && ...
    lead_gap>2*model.collar_h && ...
    disk_gap>2*model.collar_h && area_defect<=area_tolerance && ...
    scale_defect<=scale_tolerance;
  out=struct('sample_nodes',N,'area',area, ...
    'area_defect',area_defect,'area_tolerance',area_tolerance, ...
    'six_row_scale_defect',scale_defect, ...
    'six_row_scale_tolerance',scale_tolerance, ...
    'xmin',min(C(1,:)),'xmax',max(C(1,:)), ...
    'ymin',min(C(4,:)),'ymax',max(C(4,:)), ...
    'speed_min',min(speed),'speed_max',max(speed), ...
    'curvature_max',K,'collar_h',model.collar_h, ...
    'arc_band',model.arc_band,'theta',theta, ...
    'local_factor',local_factor,'far_chord_min',far_min, ...
    'offset_pair_min',offset_min, ...
    'wall_clearance',wall_clear,'periodic_y_clearance',copy_y, ...
    'lead_wall_clearance',lead_wall_clear, ...
    'lead_periodic_clearance',lead_copy_clear, ...
    'lead_clearance',lead_gap,'mass_disk_clearance',disk_gap, ...
    'pass',pass,'certified',false);
end

function out = LOCAL_density_check(k,model,cfg)
  model.khat=k; shapes={'circle','star'}; values=cell(2,1);
  for j=1:2
    if strcmp(shapes{j},'circle')
      cellmap=LOCAL_cellmap('circle',model.R,model.rho_lead,model,cfg);
    else
      cellmap=LOCAL_cellmap('star',model.star_scale, ...
        model.rho_center,model,cfg);
    end
    D=sqrt(repmat(cellmap.far_aux.weights(:),2,1));
    B=[cellmap.B_L,cellmap.B_R]; H=[cellmap.H_L,cellmap.H_R];
    Araw=(cellmap.A_QP.*D.')./D;
    Hind=-(Araw\B); K=cellmap.K; E=cellmap.E;
    HL=Hind(:,1:K); HR=Hind(:,K+1:end);
    Sind=[cellmap.F_L*HL,E+cellmap.F_L*HR; ...
      E+cellmap.F_R*HL,cellmap.F_R*HR];
    public_wall=[cellmap.F_L*H;cellmap.F_R*H];
    independent_wall=[cellmap.F_L*Hind;cellmap.F_R*Hind];
    scaled_res=norm(cellmap.A_QP*(D.*H)+D.*B,'fro')/ ...
      max(1,norm(D.*B,'fro'));
    values{j}=struct('shape',shapes{j}, ...
      'density_defect',LOCAL_relative(H,Hind), ...
      'scattering_defect',LOCAL_relative(cellmap.S,Sind), ...
      'wall_defect',LOCAL_relative(public_wall,independent_wall), ...
      'scaled_residual',scaled_res,'scale_ratio',max(D)/min(D));
  end
  maximum=max([values{1}.density_defect,values{1}.scattering_defect, ...
    values{1}.wall_defect,values{1}.scaled_residual, ...
    values{2}.density_defect,values{2}.scattering_defect, ...
    values{2}.wall_defect,values{2}.scaled_residual]);
  out=struct('k',k,'circle',values{1},'star',values{2}, ...
    'maximum_defect',maximum,'tolerance',1e-11,'pass',maximum<=1e-11);
end

function c = LOCAL_components(center,lead,wall,mass)
  c=struct( ...
    'center_value_squared',center.value_squared, ...
    'center_normal_squared',center.normal_squared, ...
    'lead_finite_value_squared',lead.finite_value_squared, ...
    'lead_finite_normal_squared',lead.finite_normal_squared, ...
    'lead_tail_value_squared',lead.tail_value_squared_candidate, ...
    'lead_tail_normal_squared',lead.tail_normal_squared_candidate, ...
    'lead_tail_value_ratio',lead.tail_value_ratio, ...
    'lead_tail_normal_ratio',lead.tail_normal_ratio, ...
    'wall_center_value_squared',wall.center_lead_value_squared, ...
    'wall_center_normal_squared',wall.center_lead_normal_squared, ...
    'wall_internal_value_squared',wall.internal_value_squared, ...
    'wall_internal_normal_squared',wall.internal_normal_squared, ...
    'wall_tail_value_squared',wall.tail_value_squared_candidate, ...
    'wall_tail_normal_squared',wall.tail_normal_squared_candidate, ...
    'wall_tail_value_ratio',wall.tail_value_ratio, ...
    'wall_tail_normal_ratio',wall.tail_normal_ratio, ...
    'material_value_squared',center.value_squared+lead.value_squared, ...
    'material_normal_squared',center.normal_squared+lead.normal_squared, ...
    'wall_value_squared',wall.value_squared, ...
    'wall_normal_squared',wall.normal_squared, ...
    'value_squared',center.value_squared+lead.value_squared+wall.value_squared, ...
    'normal_squared',center.normal_squared+lead.normal_squared+ ...
      wall.normal_squared,'mass_squared',mass.quadrature_norm^2, ...
    'complete',lead.tail_candidate_available && wall.tail_candidate_available);
end

function value = LOCAL_Cnum(mu,geometry,model)
  theta=geometry.theta; h=model.collar_h; Nover=1;
  c0=Nover/(theta*h); c1=Nover*h/(2*theta);
  value=sqrt(c0/(model.rho_exterior*mu^2)+(c1+c0)/(4*mu)+ ...
    c1*model.rho_lead);
end

function out = LOCAL_audit(model,cfg,selected,base,ev,prop,density, ...
    lead_plus,lead_minus,center_actions,lead_actions,center_jumps, ...
    lead_sums,walls,mass,components,epsilon_num)
  K=cfg.K; q=ev.q;
  q_density=ev.center.H_L*q(1:K)+ev.center.H_R*q(K+1:end);
  defects=struct( ...
    'selected_metric',max(abs([base.adef_sigma-selected.adef_sigma, ...
      base.adef_ratio-selected.adef_ratio, ...
      base.aphys_sigma-selected.aphys_sigma, ...
      base.aphys_ratio-selected.aphys_ratio])), ...
    'q_norm',abs(norm(q)-1), ...
    'center_density',norm(density-q_density)/max(1,norm(density)), ...
    'lead_plus',norm(lead_plus-[ev.lead.H_L,ev.lead.H_R]*prop.Gplus,'fro')/ ...
      max(1,norm(lead_plus,'fro')), ...
    'lead_minus',norm(lead_minus-[ev.lead.H_L,ev.lead.H_R]*prop.Gminus,'fro')/ ...
      max(1,norm(lead_minus,'fro')), ...
    'plus_trace',prop.plus_coordinate_residual, ...
    'minus_trace',prop.minus_coordinate_residual, ...
    'plus_recurrence',prop.plus_recurrence_residual, ...
    'minus_recurrence',prop.minus_recurrence_residual, ...
    'center_scale',max([center_actions{1}.scale_roundtrip_defect, ...
      center_actions{2}.scale_roundtrip_defect]), ...
    'lead_scale',max([lead_actions{1}.scale_roundtrip_defect, ...
      lead_actions{2}.scale_roundtrip_defect]), ...
    'lead_raw',max([lead_actions{1}.raw_matrix_identity_defect, ...
      lead_actions{2}.raw_matrix_identity_defect]), ...
    'epsilon_identity',abs(epsilon_num^2-(components.normal_squared+ ...
      components.value_squared/model.d^2)), ...
    'mass_positive',double(mass{2}.quadrature_norm>0), ...
    'finite_components',double(all(cellfun(@(x) ...
      (isnumeric(x) || islogical(x)) && isscalar(x) && ...
      isfinite(double(x)),struct2cell(components)))));
  numeric=cell2mat(struct2cell( ...
    rmfield(defects,{'mass_positive','finite_components'}))).';
  out=struct('schema','EPOST_I8_FLOW_V1_AUDIT','defects',defects, ...
    'maximum_defect',max(numeric),'tolerance',1e-10, ...
    'all_pass',max(numeric)<=1e-10 && defects.mass_positive==1 && ...
      defects.finite_components==1, ...
    'material_nodes',[center_actions{1}.source_nodes, ...
      center_actions{2}.source_nodes], ...
    'wall_nodes',[walls{1}.nodes,walls{2}.nodes], ...
    'disk_nodes',[mass{1}.radial_nodes,mass{1}.angular_nodes; ...
      mass{2}.radial_nodes,mass{2}.angular_nodes]);
end

function out = LOCAL_compact_action(in)
  out=in;
  remove=intersect(fieldnames(out), ...
    {'A_scaled','B','density_scale','density_map','density'});
  if ~isempty(remove), out=rmfield(out,remove); end
end

function text = LOCAL_choice(test,yes,no)
  if test, text=yes; else, text=no; end
end

function value = LOCAL_relative(a,b)
  value=norm(a-b,'fro')/max(1,norm(b,'fro'));
end

function value = LOCAL_rel(a,b)
  value=abs(a-b)/max([realmin,abs(a),abs(b)]);
end

function LOCAL_json(path,value)
  LOCAL_write_json(path,value);
end

function LOCAL_scan_csv(path,rows)
  fid=fopen(path,'w');
  if fid<0, error('i8:OutputWrite','Cannot create %s.',path); end
  cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
  fprintf(fid,'stage,level,index,k,valid,adef_sigma,adef_ratio,aphys_sigma,aphys_ratio,seconds,reason\n');
  for j=1:numel(rows)
    reason=strrep(rows(j).reason,'"','''');
    fprintf(fid,'%s,%d,%d,%.17g,%d,%.17g,%.17g,%.17g,%.17g,%.9g,"%s"\n', ...
      rows(j).stage,rows(j).level,rows(j).index,rows(j).k,rows(j).valid, ...
      rows(j).adef_sigma,rows(j).adef_ratio,rows(j).aphys_sigma, ...
      rows(j).aphys_ratio,rows(j).seconds,reason);
  end
end

function LOCAL_parts_csv(path,c)
  LOCAL_write_components(path,c);
end

%% ==================== Output and resource-safe kernel helpers ====================
% These helpers keep the entry portable and the proxy allocation bounded.

function LOCAL_write_json(path,value)
  text = jsonencode(value,'PrettyPrint',true);
  fid = fopen(path,'w');
  if fid < 0, error('i8:OutputWrite','Cannot create %s.',path); end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'%s\n',text);
  clear cleanup;
end

function LOCAL_write_components(path,c)
  names = fieldnames(c); fid = fopen(path,'w');
  if fid < 0, error('i8:OutputWrite','Cannot create %s.',path); end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid,'name,value\n');
  for j = 1:numel(names)
    value = c.(names{j});
    if isnumeric(value) && isscalar(value)
      fprintf(fid,'%s,%.17g\n',names{j},value);
    end
  end
  clear cleanup;
end

function [pot,grad,hess] = LOCAL_h2d_chunked_public( ...
    wavek,sources,charge,targ)
  nt = size(targ,2); pot = zeros(1,nt); grad = zeros(2,nt); hess = zeros(3,nt);
  target_batch = 512;
  for first = 1:target_batch:nt
    index = first:min(first+target_batch-1,nt);
    [pot(:,index),grad(:,index),hess(:,index)] = ...
      kernel.h2d_directch(wavek,sources,charge,targ(:,index));
  end
end

function cleanup = LOCAL_solver_warning_guard()
  state = warning; cleanup = onCleanup(@() warning(state));
  warning('error','MATLAB:singularMatrix');
  warning('error','MATLAB:nearlySingularMatrix');
  warning('error','MATLAB:illConditionedMatrix');
  warning('error','MATLAB:rankDeficientMatrix');
end
