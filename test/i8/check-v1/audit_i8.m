function audit = audit_i8(result,evidence)
%AUDIT_I8 Independently audit saved I8.2 matrices and mode comparisons.
% Purpose:
%   Rebuild the matching operators, Hermitian-part sign counts, weighted
%   singular systems, and cross-configuration physical-trace comparisons
%   from one fresh check_i8 result.
% Input:
%   result, evidence - Outputs returned by check_i8 in the same MATLAB run.
% Output:
%   audit - Recomputed defects, counts, overlaps, and a strict pass flag.
% Main algorithm:
%   Reassemble T, N0, L, and Adef from saved scattering blocks; form
%   H=Adef/T and Hsym; recompute all three sign-count bands and Aphys SVDs;
%   then align the two wall-trace blocks by their actual Fourier labels.
% Notes:
%   This function evaluates saved matrices only. It does not call a kernel,
%   rebuild a scattering matrix, read historical output, or certify a
%   continuous eigenvalue.

  expected_k0 = 1.7562818500073463;
  expected_halfwidth = 1e-5;
  expected_ntot = [256,384,512,256,256];
  expected_M = [48,48,48,56,64];
  expected_ids = {'B','N384','N512','M56','M64'};
  expected_edges = [1,2;2,3;1,4;4,5];
  expected_baseline_edges = [1,2;1,3;1,4;1,5];
  multipliers = [50,100,200];
  tolerance = 1e-10;

  assert(result.k0 == expected_k0);
  assert(result.halfwidth == expected_halfwidth);
  assert(result.beta == 0.5);
  assert(isequal(result.k_values, ...
    [expected_k0-expected_halfwidth,expected_k0, ...
    expected_k0+expected_halfwidth]));
  assert(isequal(result.fixed_proxy_config,[160,160,80,32]));
  assert(result.lead_epsrel == 17 && result.center_epsrel == 2);
  assert(result.star_scale == sqrt(0.04/0.0618));
  assert(isequal(result.edges,expected_edges));
  assert(isequal(result.baseline_edges,expected_baseline_edges));
  assert(isequal(size(evidence),[5,3]));
  assert(isequal(size(result.points),[5,3]));

  defects = zeros(1,13);
  count_table = zeros(5,3,3,3);
  eta_table = zeros(5,3,3);
  views = cell(5,3);
  qz_counts = zeros(5,3,2,4);
  checked_points = 0;

  % --- stage 1: rebuild every point from saved primitive blocks ---
  for ic = 1:5
    cfg = result.configs(ic);
    assert(strcmp(cfg.id,expected_ids{ic}));
    assert(cfg.ntot == expected_ntot(ic) && cfg.M == expected_M(ic));
    assert(cfg.K == 2*cfg.M+1);
    assert(isequal([cfg.nside,cfg.ntop,cfg.nproxy,cfg.mpw], ...
      [160,160,80,32]));
    for ik = 1:3
      point = result.points(ic,ik);
      saved = evidence{ic,ik};
      assert(point.valid && saved.valid);
      assert(strcmp(point.config_id,cfg.id));
      assert(saved.k == result.k_values(ik) && point.k == saved.k);
      assert(saved.config.ntot == cfg.ntot && saved.config.M == cfg.M);
      assert(isequal(saved.m(:),(-cfg.M:cfg.M).'));
      assert(isequal(saved.beta_m(:),result.beta+2*pi*saved.m(:)));

      K = cfg.K;
      [pencil_A,pencil_B] = LOCAL_pencil(saved.lead_blocks,K);
      defects(1) = max([defects(1), ...
        LOCAL_relative(pencil_A,saved.pencil.A), ...
        LOCAL_relative(pencil_B,saved.pencil.B)]);
      [Lp,Lm] = LOCAL_dtn(saved.Zplus,saved.Zminus,saved.gamma);
      defects(2) = max([defects(2),LOCAL_relative(Lp,saved.Lp), ...
        LOCAL_relative(Lm,saved.Lm)]);
      [T,N0,L,Adef] = LOCAL_rebuild(saved,Lp,Lm);
      defects(3) = max(defects(3),LOCAL_relative(T,saved.T));
      defects(4) = max(defects(4),LOCAL_relative(N0,saved.N0));
      defects(5) = max(defects(5),LOCAL_relative(L,saved.L));
      defects(6) = max(defects(6),LOCAL_relative(Adef,saved.Adef));

      warning_state = warning;
      warning_cleanup = onCleanup(@() warning(warning_state));
      warning('on','MATLAB:singularMatrix');
      warning('on','MATLAB:nearlySingularMatrix');
      warning('on','MATLAB:illConditionedMatrix');
      warning('on','MATLAB:rankDeficientMatrix');
      lastwarn('');
      H = Adef/T;
      [warning_message,~] = lastwarn;
      clear warning_cleanup;
      assert(isempty(warning_message));
      Hsym = (H+H')/2;
      defects(7) = max(defects(7),LOCAL_relative(H,saved.H));
      defects(8) = max(defects(8),LOCAL_relative(Hsym,saved.Hsym));

      n = size(Adef,1);
      identity_tolerance = 1000*n*eps;
      assembly_error = norm(Adef-(N0-L*T),'fro')/max(1, ...
        norm(Adef,'fro')+norm(N0,'fro')+norm(L,'fro')*norm(T,'fro'));
      solve_error = norm(Adef-H*T,'fro')/max(1, ...
        norm(Adef,'fro')+norm(H,'fro')*norm(T,'fro'));
      assert(rcond(T) >= 1e-8);
      assert(assembly_error <= identity_tolerance);
      assert(solve_error <= identity_tolerance);

      [Vh,Dh] = eig(Hsym,'vector');
      lambda = real(Dh);
      eig_residual = norm(Hsym*Vh-Vh*diag(lambda),'fro')/ ...
        max(1,norm(Hsym,'fro'));
      assert(all(isfinite(lambda)) && all(isfinite(Vh(:))));
      assert(max(abs(imag(Dh))) <= 100*n*eps*max(1,norm(Hsym,2)));
      assert(eig_residual <= identity_tolerance);
      dH = norm(H-Hsym,2);
      eta = dH+multipliers*n*eps*max(1,norm(Hsym,2));
      counts = zeros(3,3);
      for ib = 1:3
        counts(ib,:) = [sum(lambda>eta(ib)),sum(lambda<-eta(ib)), ...
          sum(abs(lambda)<=eta(ib))];
      end
      assert(all(sum(counts,2) == n));
      count_table(ic,ik,:,:) = reshape(counts,1,1,3,3);
      eta_table(ic,ik,:) = reshape(eta,1,1,3);
      defects(9) = max(defects(9),max(abs(eta-saved.band_etas)));
      assert(isequal(counts,saved.band_counts));
      assert(isequal(counts,LOCAL_point_counts(point)));

      [Aphys,Uphys,Sphys,Vphys,metrics,colwt] = ...
        LOCAL_weighted_svd(Adef,saved.beta_m,saved.gamma);
      defects(10) = max(defects(10),LOCAL_relative(Aphys,saved.svd.Aphys));
      saved_metrics = [point.adef_sigma,point.adef_ratio, ...
        point.aphys_sigma,point.aphys_ratio];
      defects(11) = max(defects(11),max(abs(metrics-saved_metrics)));
      trace = T*(colwt.*Vphys);
      svd_residual = max(norm(Aphys*Vphys-Uphys*Sphys,'fro'), ...
        norm(Aphys'*Uphys-Vphys*Sphys,'fro'))/max(1,norm(Aphys,'fro'));
      assert(svd_residual <= 1000*n*eps);
      views{ic,ik} = LOCAL_view(ik,Hsym,Vh,lambda,trace,diag(Sphys),n);

      plus = LOCAL_qz_counts(pencil_A,pencil_B,cfg.K);
      minus = LOCAL_qz_counts(pencil_B,pencil_A,cfg.K);
      qz_counts(ic,ik,1,:) = reshape(plus,1,1,1,4);
      qz_counts(ic,ik,2,:) = reshape(minus,1,1,1,4);
      assert(isequal(plus,[cfg.K,cfg.K,0,0]));
      assert(isequal(minus,[cfg.K,cfg.K,0,0]));
      assert(isequal(plus,LOCAL_saved_qz(saved.qz.plus)));
      assert(isequal(minus,LOCAL_saved_qz(saved.qz.minus)));
      checked_points = checked_points+1;
    end
  end

  % --- stage 2: recompute every same-k physical-trace comparison ---
  checked_edges = 0;
  for ie = 1:size(expected_edges,1)
    for ik = 1:3
      ia = expected_edges(ie,1);
      ib = expected_edges(ie,2);
      actual = LOCAL_compare(views{ia,ik},views{ib,ik}, ...
        result.configs(ia).M,result.configs(ib).M,64);
      recorded = result.comparisons(ie,ik);
      defects(12) = max(defects(12),LOCAL_comparison_error(actual,recorded));
      assert(actual.pass == recorded.pass);
      checked_edges = checked_edges+1;
    end
  end

  checked_baselines = 0;
  for ie = 1:size(expected_baseline_edges,1)
    ia = expected_baseline_edges(ie,1);
    ib = expected_baseline_edges(ie,2);
    actual = LOCAL_compare(views{ia,2},views{ib,2}, ...
      result.configs(ia).M,result.configs(ib).M,64);
    recorded = result.baseline_comparisons(ie);
    defects(13) = max(defects(13),LOCAL_comparison_error(actual,recorded));
    assert(actual.pass == recorded.pass);
    checked_baselines = checked_baselines+1;
  end

  assert(checked_points == 15 && checked_edges == 12);
  assert(checked_baselines == 4);
  assert(all(isfinite(defects)) && max(defects) < tolerance);
  audit = struct('all_pass',true,'checked_points',checked_points, ...
    'checked_edges',checked_edges,'checked_baselines',checked_baselines, ...
    'max_defect',max(defects),'defects',defects, ...
    'defect_names',{{'pencil','dtn','T','N0','L','Adef','H','Hsym', ...
    'eta','Aphys','metrics','edge_comparison','baseline_comparison'}}, ...
    'count_table',count_table,'eta_table',eta_table, ...
    'qz_counts',qz_counts, ...
    'reported_execution_pass',result.execution_pass, ...
    'reported_object_gate_pass',result.object_gate_pass, ...
    'reported_endpoint_gate_pass',result.endpoint_gate_pass, ...
    'reported_mode_identity_pass',result.mode_identity_pass, ...
    'continuous_eigenvalue_claim',false);
end

%% ==================== Matrix reconstruction ====================
% These helpers independently rebuild saved point objects and spectra.

function [A,B] = LOCAL_pencil(lead,K)
  A = [-lead.R_L,eye(K);lead.T_LR,zeros(K)];
  B = [zeros(K),lead.T_RL;eye(K),-lead.R_R];
end

function [Lp,Lm] = LOCAL_dtn(Zp,Zm,gamma)
  K = numel(gamma);
  G = diag(gamma);
  Ap = Zp(1:K,:);
  Bp = Zp(K+1:end,:);
  Am = Zm(1:K,:);
  Bm = Zm(K+1:end,:);
  Lp = ((Ap+Bp).'\(1i*G*(Ap-Bp)).').';
  Lm = ((Am+Bm).'\(-1i*G*(Am-Bm)).').';
end

function [T,N0,L,Adef] = LOCAL_rebuild(e,Lp,Lm)
  center = e.center_blocks;
  K = numel(e.gamma);
  I = eye(K);
  G = diag(e.gamma);
  T = [I+center.R_L,center.T_RL;center.T_LR,I+center.R_R];
  N0 = [1i*G*(center.R_L-I),1i*G*center.T_RL; ...
    1i*G*center.T_LR,1i*G*(center.R_R-I)];
  L = blkdiag(Lm,Lp);
  Adef = [(1i*G-Lm)*center.R_L-(1i*G+Lm), ...
    (1i*G-Lm)*center.T_RL; ...
    (1i*G-Lp)*center.T_LR, ...
    (1i*G-Lp)*center.R_R-(1i*G+Lp)];
end

function counts = LOCAL_point_counts(point)
  counts = [point.positive_50,point.negative_50,point.unresolved_50; ...
    point.positive_100,point.negative_100,point.unresolved_100; ...
    point.positive_200,point.negative_200,point.unresolved_200];
end

function [Aphys,U,S,V,metrics,colwt] = ...
    LOCAL_weighted_svd(Adef,beta_m,gamma)
  b = sqrt(1+abs(beta_m(:)).^2);
  rowwt = repmat(1./sqrt(b),2,1);
  colwt = repmat(1./sqrt(b+abs(gamma(:)).^2./b),2,1);
  Aphys = rowwt.*Adef.*colwt.';
  [U,S,V] = svd(Aphys,'econ');
  sdef = svd(Adef,'econ');
  sphys = svd(Aphys,'econ');
  metrics = [sdef(end),sdef(end)/sdef(1), ...
    sphys(end),sphys(end)/sphys(1)];
end

function view = LOCAL_view(point_index,Hsym,Vh,lambda,trace,singular,n)
  if point_index == 2
    delta = 1000*n*eps*max(1,singular(1));
    cluster = find(abs(singular-singular(end)) <= delta);
    primary = numel(singular);
    competitor = primary-1;
    view = struct('trace',trace,'cluster',cluster,'primary',primary, ...
      'competitor',competitor);
  else
    [magnitude,order] = sort(abs(lambda),'ascend');
    delta = 1000*n*eps*max(1,norm(Hsym,2));
    cluster = find(abs(abs(lambda)-magnitude(1)) <= delta);
    view = struct('trace',Vh,'cluster',cluster,'primary',order(1), ...
      'competitor',order(2));
  end
end

function counts = LOCAL_qz_counts(A,B,K)
  rho = hypot(norm(A,'fro'),norm(B,'fro'));
  assert(isfinite(rho) && rho > 0);
  A = A/rho;
  B = B/rho;
  [S,T,Q,Z] = qz(A,B,'complex');
  residual = hypot(norm(A-Q'*S*Z','fro'),norm(B-Q'*T*Z','fro'));
  threshold = max(100*eps,10*residual);
  alpha = diag(S);
  theta = diag(T);
  scale = hypot(abs(alpha),abs(theta));
  indeterminate = scale <= threshold;
  scale(indeterminate) = 1;
  an = abs(alpha)./scale;
  tn = abs(theta)./scale;
  infinite = ~indeterminate & tn <= threshold & an > threshold;
  neutral = ~indeterminate & ~infinite & abs(an-tn) <= threshold;
  stable = ~indeterminate & ~infinite & ~neutral & an < tn-threshold;
  unstable = infinite | (~indeterminate & ~neutral & an > tn+threshold);
  counts = [sum(stable),sum(unstable),sum(neutral),sum(indeterminate)];
  assert(sum(counts) == 2*K);
end

function counts = LOCAL_saved_qz(qz)
  counts = [qz.stable,qz.unstable,qz.neutral,qz.indeterminate];
end

%% ==================== Trace comparisons ====================
% These helpers align physical traces and remove phase and scale.

function out = LOCAL_compare(a,b,Ma,Mb,Mmax)
  A = LOCAL_embed(a.trace,Ma,Mmax);
  B = LOCAL_embed(b.trace,Mb,Mmax);
  [Qa,oka] = LOCAL_basis(A(:,a.cluster));
  [Qb,okb] = LOCAL_basis(B(:,b.cluster));
  assert(oka && okb);
  out = struct('rank_a',numel(a.cluster),'rank_b',numel(b.cluster), ...
    'primary_overlap',NaN,'common_overlap',NaN, ...
    'cross_a_primary_b_competitor',NaN, ...
    'cross_a_competitor_b_primary',NaN,'cross_max',NaN, ...
    'subspace_overlap',NaN,'projection_a_to_b',NaN, ...
    'projection_b_to_a',NaN,'pass',false);
  cutoff = min(Ma,Mb);
  if out.rank_a == 1 && out.rank_b == 1
    out.primary_overlap = LOCAL_overlap(A(:,a.primary),B(:,b.primary));
    mask = LOCAL_mask(Mmax,cutoff);
    out.common_overlap = LOCAL_overlap( ...
      A(mask,a.primary),B(mask,b.primary));
    out.cross_a_primary_b_competitor = ...
      LOCAL_overlap(A(:,a.primary),B(:,b.competitor));
    out.cross_a_competitor_b_primary = ...
      LOCAL_overlap(A(:,a.competitor),B(:,b.primary));
    out.cross_max = max(out.cross_a_primary_b_competitor, ...
      out.cross_a_competitor_b_primary);
    out.pass = out.primary_overlap >= 0.99 && out.cross_max <= 0.5;
  elseif out.rank_a == out.rank_b
    out.subspace_overlap = min(svd(Qa'*Qb,'econ'));
    out.projection_a_to_b = norm(Qb'*Qa,'fro')^2/out.rank_a;
    out.projection_b_to_a = norm(Qa'*Qb,'fro')^2/out.rank_b;
    mask = LOCAL_mask(Mmax,cutoff);
    [Pa,oka] = LOCAL_basis(Qa(mask,:));
    [Pb,okb] = LOCAL_basis(Qb(mask,:));
    if oka && okb
      out.common_overlap = min(svd(Pa'*Pb,'econ'));
    end
    out.pass = isfinite(out.subspace_overlap) && ...
      out.subspace_overlap >= 0.99;
  end
end

function embedded = LOCAL_embed(trace,M,Mmax)
  K = 2*M+1;
  assert(size(trace,1) == 2*K);
  modes = (-M:M).';
  index = modes+Mmax+1;
  Kmax = 2*Mmax+1;
  embedded = zeros(2*Kmax,size(trace,2),'like',trace);
  embedded(index,:) = trace(1:K,:);
  embedded(Kmax+index,:) = trace(K+1:end,:);
end

function [Q,available] = LOCAL_basis(X)
  singular = svd(X,'econ');
  threshold = 1000*max(size(X))*eps*max(1,singular(1));
  available = ~isempty(singular) && numel(singular) == size(X,2) && ...
    all(isfinite(singular)) && all(singular > threshold);
  Q = zeros(size(X),'like',X);
  if available
    [Q,~] = qr(X,0);
  end
end

function value = LOCAL_overlap(x,y)
  nx = norm(x);
  ny = norm(y);
  assert(all(isfinite(x(:))) && all(isfinite(y(:))));
  assert(isfinite(nx) && isfinite(ny) && nx > realmin && ny > realmin);
  value = min(1,abs(x(:)'*y(:))/(nx*ny));
end

function mask = LOCAL_mask(Mmax,Mcut)
  one = abs((-Mmax:Mmax).') <= Mcut;
  mask = [one;one];
end

function error = LOCAL_comparison_error(actual,recorded)
  assert(actual.rank_a == recorded.rank_a);
  assert(actual.rank_b == recorded.rank_b);
  fields = {'primary_overlap','common_overlap', ...
    'cross_a_primary_b_competitor', ...
    'cross_a_competitor_b_primary','cross_max', ...
    'subspace_overlap','projection_a_to_b','projection_b_to_a'};
  error = 0;
  for j = 1:numel(fields)
    a = actual.(fields{j});
    b = recorded.(fields{j});
    if isnan(a) || isnan(b)
      assert(isnan(a) && isnan(b));
    else
      error = max(error,abs(a-b));
    end
  end
end

function value = LOCAL_relative(a,b)
  value = norm(a-b,'fro')/max(1,norm(a,'fro')+norm(b,'fro'));
end
