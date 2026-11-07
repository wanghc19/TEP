function result = exact_mechanisms(output_dir)
%EXACT_MECHANISMS Test exact failure mechanisms behind spectral inference.
% Purpose: Check Dirichlet graph poles, shared boundary bias, saturation,
%   band-edge conditioning, nonnormal tails and subspace identity.
% Input: output_dir is an explicit writable directory for JSON and MAT data.
% Output: result contains all parameters, observations and assertions.
% Based on: Independent analytic laminate and finite-dimensional examples.
% Main changes: No production BIE, FEM, DtN, geometry or kernel is reused.
% Numerical goal: Reproduce counterexamples to overstrong inferences, not
%   refute the current star/trilobe physical candidate.
  if ~exist(output_dir,'dir'), mkdir(output_dir); end
  result = struct('schema','REDTEAM_EXACT_MECHANISMS_V1','matlab',version);
  % --- stage 1: exact laminate pole and a changed Cauchy chart ---
  mu = 1; rho = [4,1]; lengths = [pi/4,pi/2];
  T = LOCAL_layer(mu,rho(2),lengths(2))*LOCAL_layer(mu,rho(1),lengths(1));
  [V,D] = eig(T); [~,j] = min(abs(diag(D))); stable = V(:,j);
  shift = pi/8; moved = LOCAL_layer(mu,rho(1),shift)*[0;1];
  result.pole = struct('mu',mu,'rho',rho,'lengths',lengths,'transfer',T, ...
    'determinant',det(T),'trace',trace(T),'multipliers',diag(D).', ...
    'stable_dirichlet_ratio',abs(stable(1))/norm(stable), ...
    'shift',shift,'shifted_log_derivative',moved(2)/moved(1), ...
    'right_half_outward_dtn',-moved(2)/moved(1), ...
    'other_fourier_lower_bound',(2*pi)^2/max(rho), ...
    'diagonal_error',norm(T-diag([-2,-.5]),'fro'));
  assert(result.pole.diagonal_error<1e-14);
  assert(result.pole.stable_dirichlet_ratio<1e-14);
  assert(abs(result.pole.shifted_log_derivative-2)<1e-14);
  % --- stage 2: nested Ritz spaces with a blind enrichment ---
  A = diag([1,2,10,20]); v = [1;0;.1;.2]; E = eye(4);
  bases = {v,[v,E(:,4)],[v,E(:,4),E(:,2)]}; values = zeros(1,3);
  projected = zeros(1,3); full_residual = zeros(1,3);
  for n = 1:3
    [Q,~] = qr(bases{n},0); B = Q'*A*Q;
    [Z,L] = eig((B+B')/2); [values(n),idx] = min(diag(L)); u = Q*Z(:,idx);
    r = A*u-values(n)*u;
    projected(n) = norm(Q'*r); full_residual(n) = norm(r);
  end
  delta = abs(diff(values));
  result.saturation = struct('ritz',values,'true_eigenvalue',1, ...
    'projected_residual',projected,'full_residual',full_residual, ...
    'increments',delta,'observed_ratio',delta(2)/delta(1), ...
    'actual_error',abs(values(3)-1),'conditional_formula',delta(2)+3e-10);
  assert(delta(2)<1e-13 && projected(3)<1e-13);
  assert(full_residual(3)>.8 && values(3)-1>.08);
  % --- stage 3: two roots of the same intentionally wrong boundary model ---
  bracket = [1+1e-8,1+(pi/2-1e-5)^2/4]; bias = 1e-3;
  exactfun = @(x) sqrt(4*x-4).*tan(sqrt(4*x-4))-sqrt(4-x);
  wrongfun = @(x) exactfun(x)-bias;
  exactroot = LOCAL_bisect(exactfun,bracket);
  wrongroot = LOCAL_bisect(wrongfun,bracket);
  otherroot = fzero(wrongfun,bracket,optimset('TolX',eps));
  result.shared_boundary = struct('bracket',bracket,'dtn_bias',bias, ...
    'exact_mu',exactroot,'wrong_bisection_mu',wrongroot,'wrong_fzero_mu',otherroot, ...
    'solver_agreement',abs(wrongroot-otherroot),'true_mu_error',abs(wrongroot-exactroot), ...
    'true_k_error',abs(sqrt(wrongroot)-sqrt(exactroot)));
  assert(abs(wrongroot-otherroot)<1e-12 && abs(wrongroot-exactroot)>1e-5);
  % --- stage 4: band edges, Jordan tails and mode/subspace comparisons ---
  deltas = [1e-2,1e-6,1e-10]; edge = repmat(struct(),1,numel(deltas));
  for n = 1:numel(deltas)
    matrix = [2+deltas(n),-1;1,0]; [V,D] = eig(matrix);
    edge(n).delta = deltas(n); edge(n).multipliers = diag(D).';
    edge(n).unit_distance = min(abs(abs(diag(D))-1));
    edge(n).eigenvector_condition = cond(V);
    edge(n).residual = norm(matrix*V-V*D,'fro');
  end
  P = [.5,10;0,.5]; X = zeros(2); power = eye(2);
  for n = 0:100
    X = X+power'*power; power = power*P;
  end
  r = .5; analytic22 = 1/(1-r^2)+100*(1+r^2)/(1-r^2)^3;
  result.band_edge = edge;
  result.nonnormal = struct('P',P,'rho',max(abs(eig(P))),'operator_norm',norm(P), ...
    'sum_101_terms',X,'analytic_22',analytic22,'naive_rho_only_bound',1/(1-r^2), ...
    'stein_residual',norm(X-P'*X*P-eye(2),'fro'));
  assert(abs(X(2,2)-analytic22)<1e-10 && X(2,2)>200);
  Q = eye(2); angle = pi/3; rotated = [cos(angle),-sin(angle);sin(angle),cos(angle)];
  result.identity = struct('near_eigenvalues',[2,2+1e-12], ...
    'orthogonal_overlap',abs(Q(:,1)'*Q(:,2)), ...
    'rotated_single_overlap',abs(Q(:,1)'*rotated(:,1)), ...
    'subspace_singular_values',svd(Q'*rotated).');
  assert(result.identity.orthogonal_overlap==0);
  assert(max(abs(result.identity.subspace_singular_values-1))<1e-14);
  result.assertions_passed = true;
  save(fullfile(output_dir,'evidence.mat'),'result','-v7');
  fid = fopen(fullfile(output_dir,'result.json'),'w');
  fprintf(fid,'%s\n',jsonencode(result,'PrettyPrint',true)); fclose(fid);
  disp(jsonencode(result,'PrettyPrint',true));
end

%% ==================== Exact model helpers ====================
% Evaluate elementary transfer matrices and bounded scalar roots.
function T = LOCAL_layer(mu,rho,length)
  q = sqrt(mu*rho); phase = q*length;
  T = [cos(phase),sin(phase)/q;-q*sin(phase),cos(phase)];
end

function root = LOCAL_bisect(fun,bracket)
  lo = bracket(1); hi = bracket(2); flo = fun(lo);
  assert(flo*fun(hi)<0);
  for n = 1:100
    mid = (lo+hi)/2;
    if mid==lo || mid==hi, break; end
    fm = fun(mid);
    if fm==0, lo=mid; hi=mid; break; end
    if flo*fm<0, hi=mid; else, lo=mid; flo=fm; end
  end
  root = (lo+hi)/2;
end
