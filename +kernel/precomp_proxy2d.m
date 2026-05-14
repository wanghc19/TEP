function proxy2d = precomp_proxy2d(pars2d, opts)
% PRECOMP_PROXY2D Precompute a doubly-quasiperiodic 2D MFS proxy system.
%
% Purpose:
%   Builds the source-independent proxy-source matrix used to approximate
%   the two-direction quasiperiodic Green function in a perfect periodic
%   crystal cell.
%
% Main algorithm:
%   For the cell U = [X_-,X_+] x [Y_-,Y_+], with
%     L = X_+ - X_-,  d = Y_+ - Y_-,
%   place proxy sources z_l on a circle enclosing U and enforce the four
%   coordinate-discrepancy equations
%     u(X_+,y) - lambda u(X_-,y) = 0,
%     u_x(X_+,y) - lambda u_x(X_-,y) = 0,
%     u(x,Y_+) - exp(1i beta d) u(x,Y_-) = 0,
%     u_y(x,Y_+) - exp(1i beta d) u_y(x,Y_-) = 0.
%   The resulting matrix A_proxy is factored once and reused for all
%   physical source points y through A_proxy q(y) = -d_free(y).
%
% Based on:
%   The one-directional kernel.precomp_proxy MFS idea and the construction
%   described in notes/implementation/mfs2d.md.
%
% Main changes:
%   This routine uses only free-space singular kernels plus proxy sources.
%   It does not build Rayleigh plane waves and does not use the open-strip
%   logic from the one-dimensional quasiperiodic Green implementation.
%
% Numerical goal:
%   Provide a reusable, deterministic proxy geometry and factorization for
%   evaluating G_QP^{(omega)} in a two-dimensional perfect periodic crystal.
%
% Input:
%   pars2d - Struct with fields k, beta, lambda, X_minus, X_plus,
%            Y_minus, and Y_plus.  The geometry may also be supplied in
%            pars2d.cell with the same four cell-boundary fields.
%   opts   - Optional struct controlling N_proxy, N_check_x, N_check_y,
%            proxy_radius_factor, solver, and svd_tol.
%
% Output:
%   proxy2d - Struct containing proxy sources, check points, A_proxy,
%             reusable factorization data, cell geometry, phases, and
%             diagnostic information.

  if nargin < 2 || isempty(opts)
    opts = struct();
  end

  cell_data = LOCAL_parse_cell(pars2d);
  k = pars2d.k;
  beta = pars2d.beta;
  lambda = pars2d.lambda;
  L = cell_data.X_plus - cell_data.X_minus;
  d = cell_data.Y_plus - cell_data.Y_minus;
  phase_y = exp(1i * beta * d);

  opts = LOCAL_fill_opts(opts);

  center = [0.5 * (cell_data.X_minus + cell_data.X_plus); ...
            0.5 * (cell_data.Y_minus + cell_data.Y_plus)];
  half_diag = sqrt((0.5 * L)^2 + (0.5 * d)^2);
  proxy_radius = opts.proxy_radius_factor * half_diag;
  t_proxy = 2 * pi * (0:opts.N_proxy - 1) / opts.N_proxy;
  Z = center + proxy_radius * [cos(t_proxy); sin(t_proxy)];

  y_check = cell_data.Y_minus + ((0:opts.N_check_y - 1) + 0.5) * d / opts.N_check_y;
  x_check = cell_data.X_minus + ((0:opts.N_check_x - 1) + 0.5) * L / opts.N_check_x;

  check_L = [cell_data.X_minus * ones(1, opts.N_check_y); y_check];
  check_R = [cell_data.X_plus  * ones(1, opts.N_check_y); y_check];
  check_B = [x_check; cell_data.Y_minus * ones(1, opts.N_check_x)];
  check_T = [x_check; cell_data.Y_plus  * ones(1, opts.N_check_x)];

  [G_L, grad_L] = LOCAL_free_pair(k, check_L, Z);
  [G_R, grad_R] = LOCAL_free_pair(k, check_R, Z);
  [G_B, grad_B] = LOCAL_free_pair(k, check_B, Z);
  [G_T, grad_T] = LOCAL_free_pair(k, check_T, Z);

  A_proxy = [G_R - lambda * G_L; ...
             grad_R.x - lambda * grad_L.x; ...
             G_T - phase_y * G_B; ...
             grad_T.y - phase_y * grad_B.y];

  factorization = LOCAL_factor_proxy(A_proxy, opts);

  proxy2d = struct();
  proxy2d.Z = Z;
  proxy2d.A_proxy = A_proxy;
  proxy2d.factorization = factorization;
  proxy2d.check_L = check_L;
  proxy2d.check_R = check_R;
  proxy2d.check_B = check_B;
  proxy2d.check_T = check_T;
  proxy2d.cell = cell_data;
  proxy2d.L = L;
  proxy2d.d = d;
  proxy2d.k = k;
  proxy2d.beta = beta;
  proxy2d.lambda = lambda;
  proxy2d.phase_x = lambda;
  proxy2d.phase_y = phase_y;
  proxy2d.opts = opts;
  proxy2d.debug = struct();
  proxy2d.debug.proxy_radius = proxy_radius;
  proxy2d.debug.center = center;
  proxy2d.debug.N_proxy = opts.N_proxy;
  proxy2d.debug.N_check_x = opts.N_check_x;
  proxy2d.debug.N_check_y = opts.N_check_y;
  proxy2d.debug.A_proxy_size = size(A_proxy);
  proxy2d.debug.A_proxy_rank = factorization.rank;
  proxy2d.debug.A_proxy_cond_est = factorization.cond_est;

end

%% ==================== Parameter parsing helper ====================
% These helpers normalize user inputs and deterministic discretization options.

function cell_data = LOCAL_parse_cell(pars2d)

  if isfield(pars2d, 'cell')
    cell_data = pars2d.cell;
  else
    cell_data = struct();
    cell_data.X_minus = pars2d.X_minus;
    cell_data.X_plus = pars2d.X_plus;
    cell_data.Y_minus = pars2d.Y_minus;
    cell_data.Y_plus = pars2d.Y_plus;
  end

  required = {'X_minus', 'X_plus', 'Y_minus', 'Y_plus'};
  for j = 1:numel(required)
    name = required{j};
    if ~isfield(cell_data, name) || ~isscalar(cell_data.(name)) || ...
        ~isnumeric(cell_data.(name)) || ~isfinite(cell_data.(name))
      error('kernel:precomp_proxy2d:InvalidCell', ...
        'Cell field %s must be a finite numeric scalar.', name);
    end
  end

  if cell_data.X_plus <= cell_data.X_minus || cell_data.Y_plus <= cell_data.Y_minus
    error('kernel:precomp_proxy2d:InvalidCell', ...
      'Cell widths L and d must be positive.');
  end

end

function opts = LOCAL_fill_opts(opts)

  opts.N_proxy = LOCAL_get_opt(opts, 'N_proxy', 96);
  opts.N_check_x = LOCAL_get_opt(opts, 'N_check_x', 48);
  opts.N_check_y = LOCAL_get_opt(opts, 'N_check_y', 48);
  opts.proxy_radius_factor = LOCAL_get_opt(opts, 'proxy_radius_factor', 1.7);
  opts.solver = LOCAL_get_opt(opts, 'solver', 'svd');
  opts.svd_tol = LOCAL_get_opt(opts, 'svd_tol', []);

  if opts.N_proxy <= 0 || opts.N_proxy ~= fix(opts.N_proxy) || ...
      opts.N_check_x <= 0 || opts.N_check_x ~= fix(opts.N_check_x) || ...
      opts.N_check_y <= 0 || opts.N_check_y ~= fix(opts.N_check_y)
    error('kernel:precomp_proxy2d:InvalidOptions', ...
      'N_proxy, N_check_x, and N_check_y must be positive integers.');
  end

  if opts.proxy_radius_factor <= 1
    error('kernel:precomp_proxy2d:InvalidOptions', ...
      'proxy_radius_factor must be larger than 1 so that the proxy circle encloses the cell.');
  end

  if isstring(opts.solver)
    opts.solver = char(opts.solver);
  end
  opts.solver = lower(strtrim(opts.solver));
  if ~strcmp(opts.solver, 'svd') && ~strcmp(opts.solver, 'qr') && ...
      ~strcmp(opts.solver, 'backslash')
    error('kernel:precomp_proxy2d:InvalidOptions', ...
      'opts.solver must be ''svd'', ''qr'', or ''backslash''.');
  end

end

function val = LOCAL_get_opt(opts, name, default_val)

  if isfield(opts, name) && ~isempty(opts.(name))
    val = opts.(name);
  else
    val = default_val;
  end

end

%% ==================== Matrix assembly helper ====================
% This helper evaluates the free-space Helmholtz kernel on check/proxy pairs.

function [pot, grad] = LOCAL_free_pair(k, trg, src)

  xdiff = bsxfun(@minus, trg(1, :).', src(1, :));
  ydiff = bsxfun(@minus, trg(2, :).', src(2, :));
  r = sqrt(xdiff.^2 + ydiff.^2);

  pot = 1i / 4 * besselh(0, 1, k * r);
  coeff = -1i * k / 4 * besselh(1, 1, k * r) ./ r;
  grad = struct();
  grad.x = coeff .* xdiff;
  grad.y = coeff .* ydiff;

end

%% ==================== Factorization helper ====================
% This helper stores reusable least-squares factors for source RHS solves.

function factorization = LOCAL_factor_proxy(A_proxy, opts)

  factorization = struct();
  factorization.solver = opts.solver;

  if strcmp(opts.solver, 'svd')
    [U, S, V] = svd(A_proxy, 'econ');
    s = diag(S);
    if isempty(opts.svd_tol)
      if isempty(s)
        tol = 0;
      else
        tol = max(size(A_proxy)) * eps(max(s)) * max(s);
      end
    else
      tol = opts.svd_tol;
    end
    keep = s > tol;
    factorization.U = U;
    factorization.S = S;
    factorization.V = V;
    factorization.singular_values = s;
    factorization.tol = tol;
    factorization.keep = keep;
    factorization.rank = sum(keep);
    if isempty(s) || min(s) == 0
      factorization.cond_est = Inf;
    else
      factorization.cond_est = max(s) / min(s);
    end
  elseif strcmp(opts.solver, 'qr')
    [Q, R] = qr(A_proxy, 0);
    factorization.Q = Q;
    factorization.R = R;
    factorization.rank = rank(R);
    factorization.cond_est = cond(R);
  else
    factorization.rank = rank(A_proxy);
    factorization.cond_est = cond(A_proxy);
  end

end
