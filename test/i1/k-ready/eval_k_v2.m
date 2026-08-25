function varargout = eval_k_v2(action, varargin)
%EVAL_K_V2 Build the I1.4 V2 affine-proxy missing-column family.
% Purpose:
%   Freeze an affine proxy chart and QZ subspaces at the real candidate, then
%   evaluate the same branch-injected representation at prescribed nodes.
% Input:
%   action - 'seed' or 'point'.
%   seed: cfg, parent row selectors. point: k, cfg, frozen frame.
% Output:
%   seed returns node and frame; point returns node.
% Main algorithm:
%   Solve each local anchored seed proxy once with lsqminnorm, freeze
%   A0, b0, c0, U, V, and r, use an affine reduced correction at every node,
%   continue whole QZ clusters, reuse parent rows and fixed Dirichlet charts,
%   and form the unbalanced Adef D/G matrices with fail-closed factor gates.
% Based on:
%   eval_k.m, with only the V2 affine proxy representation changed.
% Numerical goal:
%   Test two sampled nodes without locator, root, derivative, or estimator work.

  action = lower(char(action));
  if strcmp(action,'seed')
    c = varargin{1}; rows = varargin{2};
    frame = LOCAL_seed_frame(c,rows);
    node = LOCAL_pair(c.kstar,c,frame,true);
    frame.seed_Z_plus = {node.coarse.plus.Z,node.fine.plus.Z};
    frame.seed_Z_minus = {node.coarse.minus.Z,node.fine.minus.Z};
    node = LOCAL_finish_pair(node,c,frame);
    varargout = {node,frame};
  elseif strcmp(action,'point')
    k = varargin{1}; c = varargin{2}; frame = varargin{3};
    node = LOCAL_pair(k,c,frame,false);
    node = LOCAL_finish_pair(node,c,frame);
    varargout = {node};
  else
    error('kreadyv2:Action','Unknown action %s.',action);
  end
end

%% ==================== Frozen representation ====================
% These helpers create branch anchors and the affine seed proxy charts once.

function frame = LOCAL_seed_frame(c,rows)
  frame.rows_plus = rows.plus(:).';
  frame.rows_minus = rows.minus(:).';
  frame.port_anchor = LOCAL_anchor(c.kstar,c.M,c,'port');
  frame.proxy_chart = cell(1,numel(c.levels));
  for j = 1:numel(c.levels)
    spec = c.levels(j);
    anchor = LOCAL_anchor(c.kstar,spec.M_pw,c,['proxy_',spec.name]);
    gamma = LOCAL_gamma(c.kstar,anchor);
    pars = LOCAL_pars(c.kstar,c);
    pspec = LOCAL_proxy_spec(spec,c);
    [~,A0,b0,~] = kproxy_v2(pars,pspec,gamma,[],'collocation');
    c0 = lsqminnorm(A0,b0);
    [U,S,V] = svd(A0,'econ'); singular = diag(S);
    rank_value = sum(singular/singular(1) >= c.proxy_rank_ratio);
    Ur = U(:,1:rank_value); Vr = V(:,1:rank_value);
    [U2,~,V2] = svd(A0,'econ');
    projector_repeat = max(LOCAL_projector(Ur,U2(:,1:rank_value)), ...
      LOCAL_projector(Vr,V2(:,1:rank_value)));
    if rank_value < numel(singular)
      gap = singular(rank_value)/max(realmin,singular(rank_value+1));
    else
      gap = Inf;
    end
    chart = struct('A0',A0,'b0',b0,'c0',c0,'U',Ur,'V',Vr, ...
      'r',rank_value,'rank',rank_value,'singular_values',singular,'anchor',anchor, ...
      'projector_repeat',projector_repeat,'gap',gap, ...
      'rank_pass',gap >= c.proxy_rank_gap_min || ...
      projector_repeat <= c.proxy_projector_repeat_tol);
    chart.frozen_complement_norm = norm(c0-Vr*(Vr'*c0),2);
    chart.frozen_complement_relative = chart.frozen_complement_norm/ ...
      max(1,norm(c0,2));
    seed_residual = b0-A0*c0;
    chart.seed_residual_complement_norm = norm(seed_residual- ...
      Ur*(Ur'*seed_residual),2)/max(1,norm(b0,2));
    chart.hash = LOCAL_fingerprint([real(A0(:));imag(A0(:)); ...
      real(b0(:));imag(b0(:));real(c0(:));imag(c0(:)); ...
      real(Ur(:));imag(Ur(:));real(Vr(:));imag(Vr(:));rank_value]);
    chart.fingerprint = chart.hash;
    frame.proxy_chart{j} = chart;
  end
end

function anchor = LOCAL_anchor(kc,M,c,label)
  anchor.kc = kc;
  anchor.orders = (-M:M).';
  anchor.beta_m = c.beta+2*pi*anchor.orders/c.d;
  anchor.gamma_seed = sqrt(complex(kc^2-anchor.beta_m.^2));
  flip = imag(anchor.gamma_seed) < 0 | ...
    (imag(anchor.gamma_seed) == 0 & real(anchor.gamma_seed) < 0);
  anchor.gamma_seed(flip) = -anchor.gamma_seed(flip);
  anchor.label = label;
  anchor.fingerprint = LOCAL_fingerprint([anchor.orders; ...
    real(anchor.gamma_seed);imag(anchor.gamma_seed)]);
end

function gamma = LOCAL_gamma(k,anchor)
  delta = k-anchor.kc;
  gamma = anchor.gamma_seed.*exp(0.5*log(1+delta./ ...
    (anchor.kc-anchor.beta_m))+0.5*log(1+delta./ ...
    (anchor.kc+anchor.beta_m)));
end

function audit = LOCAL_branch_audit(k,anchor,c)
  gamma = LOCAL_gamma(k,anchor);
  target = k^2-anchor.beta_m.^2;
  audit.algebra = max(abs(gamma.^2-target)./max(1,abs(target)));
  delta = k-anchor.kc;
  reverse = gamma.*exp(0.5*log(1-delta./(k-anchor.beta_m))+ ...
    0.5*log(1-delta./(k+anchor.beta_m)));
  audit.roundtrip = max(abs(reverse-anchor.gamma_seed)./ ...
    max(1,abs(anchor.gamma_seed)));
  audit.pass = audit.algebra <= c.branch_tol && ...
    audit.roundtrip <= c.branch_tol;
  audit.fingerprint = anchor.fingerprint;
end

%% ==================== Point and cell construction ====================
% These helpers build both levels and enforce every solve gate before use.

function node = LOCAL_pair(k,c,frame,is_seed)
  node = struct('k',k,'coarse',LOCAL_level(k,c,frame,1,is_seed), ...
    'fine',LOCAL_level(k,c,frame,2,is_seed));
end

function level = LOCAL_level(k,c,frame,index,is_seed)
  timer = tic; spec = c.levels(index); chart = frame.proxy_chart{index};
  pars = LOCAL_pars(k,c); pspec = LOCAL_proxy_spec(spec,c);
  proxy_anchor = chart.anchor;
  proxy_gamma = LOCAL_gamma(k,proxy_anchor);
  port_gamma = LOCAL_gamma(k,frame.port_anchor);
  [proxy,Aproxy,~,pinfo] = ...
    kproxy_v2(pars,pspec,proxy_gamma,chart,'collocation');
  [~,Aoff,boff,~] = kproxy_v2(pars,pspec,proxy_gamma,[],'shifted');
  off_residual = norm(Aoff*pinfo.proxy_coefficients-boff,2)/ ...
    max(1,norm(boff,2));
  proxy_hard = pinfo.available && chart.rank_pass && ...
    pinfo.proxy_projected_residual <= c.proxy_projected_tol && ...
    pinfo.proxy_projected_backward <= c.proxy_projected_tol && ...
    pinfo.proxy_full_residual <= c.proxy_full_residual_max && ...
    off_residual <= c.proxy_shifted_residual_max;
  if is_seed
    proxy_hard = proxy_hard && ...
      pinfo.proxy_seed_anchor_relative_error <= c.proxy_seed_identity_tol;
  end
  if ~proxy_hard
    error('kreadyv2:ProxyGate','Affine proxy failed a preregistered hard gate.');
  end
  channels = kchan(k,c.beta,c.d,c.M,c.X_R-c.X_L,port_gamma, ...
    frame.port_anchor.fingerprint);
  [C,curvelen] = geom.construct_cont(spec.ntot,'circle',0,0,c.R);
  kint = sqrt(1+16*c.s)*k;
  Aqp = full(complex(kbie(C,k,kint,pars,proxy,proxy_gamma,curvelen)));
  [B_L,B_R] = bloch.incident_rhs(C,channels,c.X_L,c.X_R);
  [F_L,F_R] = bloch.farfield_extractors(C,channels,c.X_L,c.X_R,curvelen);
  rhs = full(complex([B_L,B_R]));
  bie_rcond = rcond(Aqp);
  if ~isfinite(bie_rcond) || bie_rcond < c.bie_rcond_min
    error('kreadyv2:BIEFactor','A_QP failed the preregistered rcond gate.');
  end
  H = -(Aqp\rhs);
  bie_residual = norm(Aqp*H+rhs,'fro')/max(1,norm(rhs,'fro'));
  if ~all(isfinite(H(:))) || bie_residual > c.bie_residual_tol
    error('kreadyv2:BIESolve','A_QP solve failed its residual gate.');
  end
  K = c.K; E = diag(channels.phase(:));
  HL = H(:,1:K); HR = H(:,K+1:end);
  blocks = struct('R_L',full(complex(F_L*HL)), ...
    'T_RL',full(complex(E+F_L*HR)), ...
    'T_LR',full(complex(E+F_R*HL)), ...
    'R_R',full(complex(F_R*HR)));
  pair = struct('A',[-blocks.R_L,eye(K);blocks.T_LR,zeros(K)], ...
    'B',[zeros(K),blocks.T_RL;eye(K),-blocks.R_R]);
  if is_seed
    plus = LOCAL_qz_seed(pair.A,pair.B,K,c,'LEFT_CELL_WALL');
    minus = LOCAL_qz_seed(pair.B,pair.A,K,c,'RIGHT_CELL_WALL');
  else
    plus = LOCAL_qz_continue(pair.A,pair.B,frame.seed_Z_plus{index}, ...
      K,c,'LEFT_CELL_WALL');
    minus = LOCAL_qz_continue(pair.B,pair.A,frame.seed_Z_minus{index}, ...
      K,c,'RIGHT_CELL_WALL');
  end
  factors = [ ...
    LOCAL_factor('proxy_reduced',pinfo.proxy_factor_rcond, ...
      max(pinfo.proxy_projected_residual,pinfo.proxy_projected_backward), ...
      pinfo.available && chart.rank_pass,c.proxy_rcond_min,c.proxy_projected_tol); ...
    LOCAL_factor('proxy_full_collocation',pinfo.proxy_factor_rcond, ...
      pinfo.proxy_full_residual,pinfo.available,0,c.proxy_full_residual_max); ...
    LOCAL_factor('proxy_shifted',pinfo.proxy_factor_rcond,off_residual, ...
      isfinite(off_residual),0,c.proxy_shifted_residual_max); ...
    LOCAL_factor('proxy_seed_identity',pinfo.proxy_factor_rcond, ...
      pinfo.proxy_seed_anchor_relative_error, ...
      ~is_seed || isfinite(pinfo.proxy_seed_anchor_relative_error), ...
      0,LOCAL_seed_limit(is_seed,c)); ...
    LOCAL_factor('bie_A_QP',bie_rcond,bie_residual,all(isfinite(H(:))), ...
      c.bie_rcond_min,c.bie_residual_tol)];
  level = struct('name',spec.name,'k',k,'spec',spec,'gamma',port_gamma, ...
    'beta_m',channels.beta_m(:),'phase',channels.phase(:), ...
    'blocks',blocks,'pair',pair,'plus',plus,'minus',minus, ...
    'proxy_chart',chart,'proxy_shape',size(Aproxy), ...
    'Aqp_shape',size(Aqp),'branch_port', ...
    LOCAL_branch_audit(k,frame.port_anchor,c),'branch_proxy', ...
    LOCAL_branch_audit(k,proxy_anchor,c), ...
    'proxy_full_residual',pinfo.proxy_full_residual, ...
    'proxy_off_residual',off_residual, ...
    'proxy_seed_identity',pinfo.proxy_seed_anchor_relative_error, ...
    'factors',factors,'elapsed_seconds',toc(timer));
end

function limit = LOCAL_seed_limit(is_seed,c)
  if is_seed, limit = c.proxy_seed_identity_tol; else, limit = Inf; end
end

function pars = LOCAL_pars(k,c)
  pars = struct('k',k,'beta',c.beta,'d',c.d,'periodic_axis','y');
end

function out = LOCAL_proxy_spec(spec,c)
  out = struct('H',c.H,'proxy_dist',c.proxy_dist, ...
    'N_side',spec.N_side,'N_top',spec.N_top, ...
    'N_proxy_edge',spec.N_proxy_edge,'M_pw',spec.M_pw);
end

%% ==================== QZ cluster continuation ====================
% These helpers select by modulus only at the seed and continue whole clusters.

function q = LOCAL_qz_seed(A,B,K,c,plane)
  raw = LOCAL_qz_raw(A,B);
  stable = raw.an < raw.tn-raw.tau & ~raw.indeterminate & ~raw.neutral;
  selected = find(stable);
  if numel(selected) ~= K
    error('kreadyv2:SeedCount','Seed %s stable count is %d, expected %d.', ...
      plane,numel(selected),K);
  end
  q = LOCAL_ordered_qz(raw,selected,K,c,plane);
  q.score_gap = Inf;
  q.classification_gap = Inf;
  q.chordal_separation = LOCAL_cross_chord(raw,selected,find(~stable));
  q.cluster_tau = max(c.cross_cluster_margin_min, ...
    10*max(raw.residual,q.residual));
  q.match_pass = q.chordal_separation > q.cluster_tau;
  q.pass = q.pass && q.match_pass;
end

function q = LOCAL_qz_continue(A,B,Zparent,K,c,plane)
  raw = LOCAL_qz_raw(A,B);
  [Qp,~] = qr(Zparent,0);
  [vectors,eigenvalues] = eig(raw.A,raw.B,'qz');
  vector_norms = sqrt(sum(abs(vectors).^2,1)).';
  scores = sum(abs(Qp'*vectors).^2,1).'./max(realmin,vector_norms.^2);
  order = LOCAL_descending(scores);
  eig_selected = order(1:K); eig_complement = order(K+1:end);
  score_gap = scores(eig_selected(end))-scores(eig_complement(1));
  [eig_alpha,eig_theta] = LOCAL_lambda_pairs(diag(eigenvalues));
  selected_distance = LOCAL_set_distance(raw,eig_alpha(eig_selected), ...
    eig_theta(eig_selected));
  complement_distance = LOCAL_set_distance(raw,eig_alpha(eig_complement), ...
    eig_theta(eig_complement));
  classification_score = complement_distance-selected_distance;
  qz_order = LOCAL_descending(classification_score);
  selected = qz_order(1:K); complement = qz_order(K+1:end);
  classification_gap = classification_score(selected(end))- ...
    classification_score(complement(1));
  q = LOCAL_ordered_qz(raw,selected,K,c,plane);
  q.parent_scores = scores;
  q.score_gap = score_gap;
  q.classification_gap = classification_gap;
  q.chordal_separation = LOCAL_cross_chord(raw,selected,complement);
  [q.overlap,~] = LOCAL_overlap(Zparent,q.Z);
  q.cluster_tau = max(c.cross_cluster_margin_min, ...
    10*max(raw.residual,q.residual));
  q.match_pass = score_gap > q.cluster_tau && ...
    classification_gap > q.cluster_tau && ...
    q.chordal_separation > q.cluster_tau && ...
    q.overlap >= c.qz_overlap_min;
  q.pass = q.pass && q.match_pass;
end

function raw = LOCAL_qz_raw(A,B)
  rho = hypot(norm(A,'fro'),norm(B,'fro'));
  As = A/rho; Bs = B/rho;
  [S,T,Q,Z] = qz(As,Bs,'complex');
  residual = hypot(norm(As-Q'*S*Z','fro'),norm(Bs-Q'*T*Z','fro'));
  alpha = diag(S); theta = diag(T); scale = hypot(abs(alpha),abs(theta));
  tau = max(100*eps,10*residual);
  indeterminate = scale <= tau; scale(indeterminate) = 1;
  ahat = alpha./scale; that = theta./scale;
  an = abs(ahat); tn = abs(that);
  neutral = ~indeterminate & abs(an-tn) <= tau;
  infinite = ~indeterminate & tn <= tau & an > tau;
  raw = struct('A',As,'B',Bs,'S',S,'T',T,'Q',Q,'Z',Z, ...
    'residual',residual,'tau',tau,'ahat',ahat,'that',that, ...
    'an',an,'tn',tn,'indeterminate',indeterminate, ...
    'neutral',neutral,'infinite',infinite);
end

function q = LOCAL_ordered_qz(raw,selected,K,c,plane)
  mask = false(2*K,1); mask(selected) = true;
  [So,To,Qo,Zo] = ordqz(raw.S,raw.T,raw.Q,raw.Z,mask);
  Qleft = Qo'; Zs = Zo(:,1:K); Qs = Qleft(:,1:K);
  residual = max([norm(raw.A-Qleft*So*Zo','fro'), ...
    norm(raw.B-Qleft*To*Zo','fro'), ...
    norm(raw.A*Zs-Qs*So(1:K,1:K),'fro'), ...
    norm(raw.B*Zs-Qs*To(1:K,1:K),'fro')]);
  stable_diag = raw.an < raw.tn-raw.tau & ...
    ~raw.indeterminate & ~raw.neutral;
  unstable_diag = raw.infinite | (raw.an > raw.tn+raw.tau & ...
    ~raw.indeterminate & ~raw.neutral);
  finite_gap = abs(raw.an(~raw.indeterminate)-raw.tn(~raw.indeterminate));
  if isempty(finite_gap), unit_gap = 0; else, unit_gap = min(finite_gap); end
  q = struct('plane',plane,'Z',Zs,'raw_residual',raw.residual, ...
    'residual',residual,'stable_diagnostic',sum(stable_diag), ...
    'unstable_diagnostic',sum(unstable_diag), ...
    'neutral_count',sum(raw.neutral),'infinite_count',sum(raw.infinite), ...
    'indeterminate_count',sum(raw.indeterminate),'unit_gap',unit_gap, ...
    'pass',raw.residual <= c.qz_residual_tol && ...
    residual <= c.qz_residual_tol && sum(stable_diag) == K && ...
    sum(unstable_diag) == K && sum(raw.neutral) == 0 && ...
    sum(raw.indeterminate) == 0 && numel(selected) == K);
end

function value = LOCAL_cross_chord(raw,selected,complement)
  D = abs(raw.ahat(selected).*raw.that(complement).'- ...
    raw.that(selected).*raw.ahat(complement).');
  value = min(D(:));
end

function [alpha,theta] = LOCAL_lambda_pairs(lambda)
  alpha = zeros(size(lambda)); theta = zeros(size(lambda));
  finite = isfinite(lambda);
  scale = hypot(abs(lambda(finite)),1);
  alpha(finite) = lambda(finite)./scale;
  theta(finite) = 1./scale;
  alpha(~finite) = 1;
end

function distance = LOCAL_set_distance(raw,alpha,theta)
  D = abs(raw.ahat(:).*theta(:).'-raw.that(:).*alpha(:).');
  distance = min(D,[],2);
end

function order = LOCAL_descending(scores)
  [~,order] = sortrows([-scores(:),(1:numel(scores)).'],[1 2]);
end

%% ==================== Fixed chart and Adef ====================
% These helpers normalize with fixed rows and fail before unsafe backslashes.

function node = LOCAL_finish_pair(node,c,frame)
  node.coarse = LOCAL_finish(node.coarse,c,frame);
  node.fine = LOCAL_finish(node.fine,c,frame);
  node.pass = node.coarse.pass && node.fine.pass;
end

function level = LOCAL_finish(level,c,frame)
  [Zp,pmargin,pcond,pres,prcond] = ...
    LOCAL_normalize(level.plus.Z,frame.rows_plus,c,'plus');
  [Zm,mmargin,mcond,mres,mrcond] = ...
    LOCAL_normalize(level.minus.Z,frame.rows_minus,c,'minus');
  K = c.K; Gamma = diag(level.gamma); E = diag(level.phase);
  Ap = Zp(1:K,:); Bp = Zp(K+1:end,:);
  Am = Zm(1:K,:); Bm = Zm(K+1:end,:);
  Dp = Ap+Bp; Np = 1i*Gamma*(Ap-Bp);
  Dm = Am+Bm; Nm = -1i*Gamma*(Am-Bm);
  cp = LOCAL_chart(Dp,Np,level.beta_m,c,'dtn_plus');
  cm = LOCAL_chart(Dm,Nm,level.beta_m,c,'dtn_minus');
  if ~(cp.safe && cm.safe)
    error('kreadyv2:DirichletChart','A Dirichlet chart failed closed.');
  end
  Lp = cp.Lambda; Lm = cm.Lambda;
  AdefD = [-(1i*Gamma+Lm),(1i*Gamma-Lm)*E; ...
    (1i*Gamma-Lp)*E,-(1i*Gamma+Lp)];
  Z = zeros(K); I = eye(K);
  AdefG = [I,E,-Dm,Z;-1i*Gamma,1i*Gamma*E,-Nm,Z; ...
    E,I,Z,-Dp;1i*Gamma*E,-1i*Gamma,Z,-Np];
  drow = [1:K,2*K+1:3*K]; nrow = [K+1:2*K,3*K+1:4*K];
  qcol = 1:2*K; ccol = 2*K+1:4*K;
  Cfactor = AdefG(drow,ccol); C_rcond = rcond(Cfactor);
  if ~isfinite(C_rcond) || C_rcond < c.dirichlet_rcond_min
    error('kreadyv2:GraphFactor','Graph Dirichlet factor failed closed.');
  end
  reduced = AdefG(nrow,qcol)-AdefG(nrow,ccol)* ...
    (Cfactor\AdefG(drow,qcol));
  schur = norm(AdefD-reduced,'fro')/max(1,norm(AdefD,'fro'));
  factors = [level.factors; ...
    LOCAL_factor('fixed_row_plus',prcond,pres,isfinite(pres), ...
      eps/c.chart_condition_eps_tol,c.small_solve_residual_tol); ...
    LOCAL_factor('fixed_row_minus',mrcond,mres,isfinite(mres), ...
      eps/c.chart_condition_eps_tol,c.small_solve_residual_tol); ...
    cp.factor;cm.factor; ...
    LOCAL_factor('graph_schur_D_blocks',C_rcond,schur,isfinite(schur), ...
      c.dirichlet_rcond_min,c.schur_tol)];
  [~,~,Vd] = svd(AdefD,'econ'); q = Vd(:,end);
  qL = q(1:K); qR = q(K+1:end);
  cminus = Dm\([I,E]*q);
  cplus = Dp\([E,I]*q);
  lift = [q;cminus;cplus];
  level.Zp = Zp; level.Zm = Zm; level.Dp = Dp; level.Np = Np;
  level.Dm = Dm; level.Nm = Nm; level.cp = cp; level.cm = cm;
  level.AdefD = AdefD; level.AdefG = AdefG; level.schur = schur;
  level.row = struct('plus_margin',pmargin,'minus_margin',mmargin, ...
    'plus_condition',pcond,'minus_condition',mcond, ...
    'plus_residual',pres,'minus_residual',mres);
  level.factors = factors;
  level.participation = struct( ...
    'center',min(norm(qL),norm(qR))/max(realmin,norm(q)), ...
    'graph',min(norm(cminus),norm(cplus))/max(realmin,norm(lift)), ...
    'residual',norm(AdefG*lift)/max(1,norm(AdefG,'fro')*norm(lift)));
  level.pass = level.plus.pass && level.minus.pass && ...
    level.branch_port.pass && level.branch_proxy.pass && cp.safe && cm.safe && ...
    pmargin > c.chart_margin_min && mmargin > c.chart_margin_min && ...
    pcond*eps <= c.chart_condition_eps_tol && ...
    mcond*eps <= c.chart_condition_eps_tol && schur <= c.schur_tol && ...
    level.participation.center >= c.participation_min && ...
    level.participation.graph >= c.participation_min && ...
    level.participation.residual <= c.lift_residual_tol && all([factors.pass]);
  if level.pass, level.reason = 'PASS'; else, level.reason = 'SCIENTIFIC_GATE'; end
end

function [Zhat,margin,condition,residual,rcond_value] = ...
    LOCAL_normalize(Z,rows,c,side)
  H = Z(rows,:); singular = svd(H,'econ');
  margin = min(singular); condition = max(singular)/max(realmin,margin);
  rcond_value = rcond(H);
  if margin <= c.chart_margin_min || ...
      condition*eps > c.chart_condition_eps_tol || ...
      ~isfinite(rcond_value) || rcond_value < eps/c.chart_condition_eps_tol
    error('kreadyv2:FixedRows','Fixed %s row factor failed closed.',side);
  end
  Zhat = (H.'\Z.').';
  residual = norm(Zhat(rows,:)-eye(size(H)),'fro')/max(1,sqrt(size(H,1)));
  if ~isfinite(residual) || residual > c.small_solve_residual_tol
    error('kreadyv2:FixedRows','Fixed %s row solve residual failed.',side);
  end
end

function chart = LOCAL_chart(D,N,beta_m,c,name)
  b = sqrt(1+abs(beta_m(:)).^2);
  GDh = diag(sqrt(b)); GD = diag(b); GN = diag(1./b);
  gram = D'*GD*D+N'*GN*N; gram = (gram+gram')/2;
  [V,L] = eig(gram); values = max(real(diag(L)),0);
  chart = struct('margin',0,'condition',Inf,'solve_residual',Inf, ...
    'safe',false,'Lambda',[],'factor',LOCAL_factor(name,0,Inf,false, ...
    c.dirichlet_rcond_min,c.small_solve_residual_tol));
  if min(values) <= 0, return; end
  half = V*diag(sqrt(values))*V';
  Dbar = (half.'\(GDh*D).').'; singular = svd(Dbar,'econ');
  chart.margin = min(singular);
  chart.condition = max(singular)/max(realmin,chart.margin);
  D_rcond = rcond(D);
  if chart.margin <= c.chart_margin_min || ...
      chart.condition*eps > c.chart_condition_eps_tol || ...
      ~isfinite(D_rcond) || D_rcond < c.dirichlet_rcond_min
    return;
  end
  chart.Lambda = (D.'\N.').';
  chart.solve_residual = norm(N-chart.Lambda*D,'fro')/max(1,norm(N,'fro'));
  chart.safe = all(isfinite(chart.Lambda(:))) && ...
    chart.solve_residual <= c.small_solve_residual_tol;
  chart.factor = LOCAL_factor(name,D_rcond,chart.solve_residual, ...
    chart.safe,c.dirichlet_rcond_min,c.small_solve_residual_tol);
  if ~chart.safe, chart.Lambda = []; end
end

%% ==================== Diagnostics ====================
% These helpers provide factor rows, overlaps, and deterministic fingerprints.

function row = LOCAL_factor(name,rcond_value,residual,available,rmin,rmax)
  row = struct('name',name,'rcond',rcond_value,'residual',residual, ...
    'available',logical(available),'rcond_min',rmin,'residual_max',rmax, ...
    'pass',logical(available) && rcond_value >= rmin && residual <= rmax);
end

function value = LOCAL_projector(A,B)
  [Qa,~] = qr(A,0); [Qb,~] = qr(B,0);
  value = norm(Qa*Qa'-Qb*Qb',2);
end

function [overlap,distance] = LOCAL_overlap(A,B)
  [Qa,~] = qr(A,0); [Qb,~] = qr(B,0);
  values = svd(Qa'*Qb,'econ'); overlap = min(values);
  distance = sqrt(max(0,1-overlap^2));
end

function value = LOCAL_fingerprint(data)
  payload = sprintf('%.17g,',double(data(:)));
  digest = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
  digest.update(typecast(uint8(payload),'int8'));
  raw = typecast(digest.digest(),'uint8');
  value = lower(reshape(dec2hex(raw,2).',1,[]));
end
