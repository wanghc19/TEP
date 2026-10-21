function audit = audit_i8(result,evidence)
%AUDIT_I8 Independently recompose fresh I8 matrices and numerical components.
% Purpose:
%   Check the physical port coordinates, new matrices, scan selection, and
%   frozen-field component ledger without another BIE solve.
% Input:
%   result, evidence - Fresh in-memory outputs of run_i8.
% Output:
%   audit - Recomposition defects and a finite numerical consistency verdict.
% Based on:
%   I7 matching and I7.4 signed-jump conventions, independently assembled here.
% Main algorithm:
%   Rebuild DtN, T, N0, Aphys, SVD traces, endpoint counts, propagation, and
%   component sums from saved matrices and sampled fields.
% Notes:
%   This is an arithmetic audit, not a quadrature or spectral certificate.

  defects = struct;
  rows = evidence.screen;
  for j = 1:numel(evidence.levels)
    rows = [rows;evidence.levels{j}(:)]; %#ok<AGROW>
  end
  good = rows([rows.valid]);
  [best,jbest] = min([good.aphys_ratio]);
  defects.scan_k = abs(result.selected.k-good(jbest).k);
  defects.scan_ratio = abs(result.selected.aphys_ratio-best);
  defects.model_k = abs(result.model.khat-result.selected.k);
  points = {evidence.base_ev,evidence.ntot_ev,evidence.mord_ev};
  names = {'B','N','M'};
  summaries = {evidence.base,evidence.ntot,evidence.mord};
  if ~isempty(evidence.left_ev)
    points = [points,{evidence.left_ev,evidence.right_ev}];
    names = [names,{'L','R'}];
    summaries = [summaries,{evidence.left,evidence.right}];
    separation = [result.selected.k-result.shoulders(1), ...
      result.shoulders(2)-result.selected.k];
    defects.shoulder_spacing = double(any(separation <= ...
      64*eps*max(1,abs(result.selected.k))));
  end
  traces = cell(size(points));
  counts = cell(size(points));
  point_summary = cell(size(points));
  for j = 1:numel(points)
    ev = points{j}; cellmap = ev.center;
    gamma = ev.gamma; bm = ev.beta_m; K = numel(gamma);
    Ap = ev.Zplus(1:K,:); Bp = ev.Zplus(K+1:end,:);
    Am = ev.Zminus(1:K,:); Bm = ev.Zminus(K+1:end,:);
    Lp = (1i*diag(gamma)*(Ap-Bp))/(Ap+Bp);
    Lm = (-1i*diag(gamma)*(Am-Bm))/(Am+Bm);
    T = [eye(K)+cellmap.R_L,cellmap.T_RL; ...
      cellmap.T_LR,eye(K)+cellmap.R_R];
    N0 = 1i*blkdiag(diag(gamma),diag(gamma))* ...
      [cellmap.R_L-eye(K),cellmap.T_RL; ...
       cellmap.T_LR,cellmap.R_R-eye(K)];
    Adef = N0-blkdiag(Lm,Lp)*T;
    b = sqrt(1+abs(bm).^2);
    dr = repmat(1./sqrt(b),2,1);
    dc = repmat(1./sqrt(b+abs(gamma).^2./b),2,1);
    Aphys = dr.*Adef.*dc.';
    [~,S,V] = svd(Aphys,'econ'); s = diag(S); a = svd(Adef);
    q = dc.*V(:,end); q = q/norm(q);
    id = names{j};
    defects.([id '_T']) = LOCAL_diff(T,ev.matching.T);
    defects.([id '_Adef']) = LOCAL_diff(Adef,ev.matching.Adef);
    defects.([id '_Aphys']) = LOCAL_diff(Aphys,ev.matching.Aphys);
    defects.([id '_q']) = abs(1-LOCAL_overlap(q,ev.q));
    defects.([id '_trace']) = LOCAL_diff(T*ev.q, ...
      ev.matching.trace_primary);
    p = summaries{j};
    metrics = [a(end),a(end)/a(1),s(end),s(end)/s(1)];
    saved = [p.adef_sigma,p.adef_ratio,p.aphys_sigma,p.aphys_ratio];
    defects.([id '_metrics']) = max(abs(metrics-saved));
    traces{j} = T*q;
    H = Adef/T; Hsym = (H+H')/2;
    lam = eig(Hsym); dH = norm(H-Hsym,2); scale = norm(Hsym,2);
    eta = dH+[50,100,200]*size(H,1)*eps*max(1,scale);
    counts{j} = [arrayfun(@(t)sum(real(lam)<-t),eta); ...
      arrayfun(@(t)sum(abs(real(lam))<=t),eta); ...
      arrayfun(@(t)sum(real(lam)>t),eta)];
    defects.([id '_rightsolve']) = LOCAL_diff(H*T,Adef);
    [~,near] = sort(abs(real(lam)));
    near_lambda = real(lam(near));
    point_summary{j} = struct('id',id,'k',ev.model.khat, ...
      'ntot',ev.config.ntot,'M',ev.config.M, ...
      'adef_sigma',metrics(1),'adef_ratio',metrics(2), ...
      'aphys_sigma',metrics(3),'aphys_ratio',metrics(4), ...
      'rcond_T',rcond(T),'scale',scale,'dH',dH,'eta',eta, ...
      'near_zero',near_lambda(1:min(3,numel(near_lambda))), ...
      'min_abs_lambda',min(abs(lam)), ...
      'sign_margin',min(abs(lam))-eta, ...
      'negative',counts{j}(1,:),'unresolved',counts{j}(2,:), ...
      'positive',counts{j}(3,:), ...
      'assembly_error',ev.matching.assembly_defect, ...
      'right_error',defects.([id '_rightsolve']));
    if j >= 4
      if j == 4, saved_count = result.inertia.left;
      else, saved_count = result.inertia.right; end
      expected = [saved_count.negative;saved_count.unresolved; ...
        saved_count.positive];
      defects.([id '_counts']) = max(abs(counts{j}(:)-expected(:)));
      defects.([id '_dH']) = abs(dH-saved_count.dH);
    end
  end
  for j = 2:3
    common = max(points{1}.config.M,points{j}.config.M);
    x = LOCAL_embed(traces{1},points{1}.config.M,common);
    y = LOCAL_embed(traces{j},points{j}.config.M,common);
    if j == 2, saved_overlap = result.modes.B_N.primary_overlap;
    else, saved_overlap = result.modes.B_M.primary_overlap; end
    defects.(['mode_' names{j}]) = ...
      abs(LOCAL_overlap(x,y)-saved_overlap);
  end

  ev = evidence.base_ev; prop = evidence.propagation;
  K = ev.config.K; q = ev.q;
  defects.center_density = LOCAL_diff(evidence.center_density, ...
    [ev.center.H_L,ev.center.H_R]*q);
  Ap = ev.Zplus(1:K,:); Bp = ev.Zplus(K+1:end,:);
  Am = ev.Zminus(1:K,:); Bm = ev.Zminus(K+1:end,:);
  defects.Gplus = LOCAL_diff(prop.Gplus,[Ap;Bp*prop.Pplus]);
  defects.Gminus = LOCAL_diff(prop.Gminus,[Am*prop.Pminus;Bm]);
  trace = ev.matching.T*q;
  defects.trace_plus = LOCAL_diff((Ap+Bp)*prop.cplus,trace(K+1:end));
  defects.trace_minus = LOCAL_diff((Am+Bm)*prop.cminus,trace(1:K));
  defects.Pplus = LOCAL_diff(ev.pencil.A*ev.Zplus, ...
    ev.pencil.B*ev.Zplus*prop.Pplus);
  defects.Pminus = LOCAL_diff(ev.pencil.B*ev.Zminus, ...
    ev.pencil.A*ev.Zminus*prop.Pminus);

  reconstructed = zeros(2,4);
  evaluation_summary = cell(2,1);
  for level = 1:2
    center = evidence.center_jumps{level};
    weights = evidence.center_actions{level}.weights;
    cv = real(sum(weights.*abs(center.value).^2));
    cn = real(sum(weights.*abs(center.normal).^2));
    lead = evidence.lead_sums{level};
    lv = sum([lead.cells.value_squared])+lead.tail_value_squared_candidate;
    ln = sum([lead.cells.normal_squared])+lead.tail_normal_squared_candidate;
    wall = evidence.wall_levels{level};
    weight = result.model.d/wall.nodes;
    wv = weight*(sum(abs(wall.center_lead_value_left).^2)+ ...
      sum(abs(wall.center_lead_value_right).^2));
    wn = weight*(sum(abs(wall.center_lead_dx_left).^2)+ ...
      sum(abs(wall.center_lead_dx_right).^2));
    wv = wv+sum([wall.internal_rows.value_squared])+ ...
      wall.tail_value_squared_candidate;
    wn = wn+sum([wall.internal_rows.normal_squared])+ ...
      wall.tail_normal_squared_candidate;
    mass = evidence.mass{level};
    U = sqrt(pi*mass.radius^2*mean(abs(mass.sample_values).^2));
    reconstructed(level,:) = [cv+lv+wv,cn+ln+wn,U, ...
      sqrt(cn+ln+wn+(cv+lv+wv)/result.model.d^2)];
    defects.(sprintf('center%d',level)) = max(abs([ ...
      cv-center.value_squared,cn-center.normal_squared]));
    defects.(sprintf('lead%d',level)) = ...
      max(abs([lv-lead.value_squared,ln-lead.normal_squared]));
    defects.(sprintf('wall%d',level)) = ...
      max(abs([wv-wall.value_squared,wn-wall.normal_squared]));
    defects.(sprintf('mass%d',level)) = abs(U-mass.quadrature_norm);
    evaluation_summary{level} = struct('nodes',wall.nodes, ...
      'center_value_squared',cv,'center_normal_squared',cn, ...
      'lead_value_squared',lv,'lead_normal_squared',ln, ...
      'wall_value_squared',wv,'wall_normal_squared',wn,'U_num',U, ...
      'epsilon_num',reconstructed(level,4));
  end
  U = reconstructed(2,3); epsilon_num = reconstructed(2,4);
  h = result.model.collar_h;
  theta = 1-h*result.geometry.curvature_max;
  c0 = 1/(theta*h); c1 = h/(2*theta);
  mu = result.selected.k^2;
  C = sqrt(c0/(result.model.rho_exterior*mu^2)+ ...
    (c1+c0)/(4*mu)+c1*result.model.rho_lead);
  denominator = U-C*epsilon_num;
  for level = 1:2
    value = evaluation_summary{level};
    value.denominator = value.U_num-C*value.epsilon_num;
    value.Rnum = NaN;
    if value.denominator > 0
      value.Rnum = 2*mu*C*value.epsilon_num/value.denominator;
    end
    evaluation_summary{level} = value;
  end
  defects.Cnum = abs(C-result.Cnum);
  defects.mass_total = abs(U-result.U_num);
  defects.epsilon = abs(epsilon_num-result.epsilon_num);
  defects.mu = abs(mu-result.mu);
  defects.denominator = abs(denominator-result.denominator);
  if isfinite(result.Rnum)
    defects.finite_R_gate = double(~(result.geometry.pass && ...
      result.components.complete && denominator>0));
    R = 2*mu*C*epsilon_num/denominator;
    defects.Rnum = abs(R-result.Rnum);
  end
  values = cell2mat(struct2cell(defects));
  tolerance = 1e-9;
  audit = struct('schema','I8_FRESH_AUDIT','defects',defects, ...
    'maximum_defect',max(values),'tolerance',tolerance, ...
    'pass',all(isfinite(values)) && all(values<=tolerance), ...
    'reconstructed',reconstructed,'counts',{counts}, ...
    'point_summary',{point_summary}, ...
    'evaluation_summary',{evaluation_summary}, ...
    'propagation_radius',[max(abs(eig(prop.Pplus))), ...
      max(abs(eig(prop.Pminus)))], ...
    'continuous_certificate',false);
end

%% ==================== Coordinate comparison ====================
% Compare physical traces after separate left/right mode-label alignment.

function y = LOCAL_embed(x,M,common)
  K = 2*M+1; N = 2*common+1; labels = (-M:M)+common+1;
  y = complex(zeros(2*N,1));
  y(labels) = x(1:K); y(N+labels) = x(K+1:end);
end

function value = LOCAL_overlap(a,b)
  value = abs(a'*b)/(norm(a)*norm(b));
end

function value = LOCAL_diff(a,b)
  value = norm(a-b,'fro')/max(1,norm(b,'fro'));
end
