format long;
clear;
close all;

% Simple band plotting script for the 1D periodic waveguide eigenvalue problem.
% External dependencies:
%   1. precomp_proxy
%   2. qpgreen_mfs
%
% This script keeps the workflow intentionally simple:
%   1. At the first beta, do a global scan in k and detect candidate roots.
%   2. For each later beta, continue each existing branch in a small k window.
%   3. Also do a coarse global scan to detect newly born branches.
%
% The matrix assembly below is the same as your current code, except that the
% extra identity at the end has been removed.

% ----------------------------
% User parameters
% ----------------------------
flag_geom = 'ellipse';
iprec = 10;
ntot = 60;

er = 13;
nref = sqrt(er);
d = 1.0;

beta_min = 0.10 * pi / d;
beta_max = 0.99 * pi / d;
num_beta = 28;
beta_list = linspace(beta_min, beta_max, num_beta);

k_floor = 5.0e-2;
k_upper_factor = 0.99;

num_k_init = 220;
num_k_birth = 60;
num_k_local = 31;

window_halfwidth = 0.18;
sigma_tol = 5.0e-3;
prom_tol = 5.0;
root_merge_tol = 0.08;
track_jump_tol = 0.18;

birth_stride = 3;

pars2.H = 0.5 * d;
pars2.proxy_dist = 0.2 * d;
pars2.N_side = 50;
pars2.N_top = 50;
pars2.N_proxy_edge = 30;
pars2.M_pw = 10;

% ----------------------------
% Precompute geometry
% ----------------------------
[C, curvelen, ~, ~] = LOCAL_construct_cont(ntot, flag_geom, 0, 0);

% ----------------------------
% Initialize storage
% ----------------------------
bands_k = NaN(0, num_beta);
bands_sigma = NaN(0, num_beta);

fprintf('Simple band scan with ntot = %d\n', ntot);
fprintf('Number of beta samples = %d\n', num_beta);

% ----------------------------
% First beta: global scan
% ----------------------------
beta = beta_list(1);
fprintf('Initial global scan at beta = %.8f\n', beta);

cands = LOCAL_global_candidates(beta, num_k_init, nref, C, iprec, curvelen, ...
  d, pars2, k_floor, k_upper_factor, sigma_tol, prom_tol, root_merge_tol);

if ~isempty(cands)
  nb = numel(cands);
  bands_k = NaN(nb, num_beta);
  bands_sigma = NaN(nb, num_beta);
  for j = 1:nb
    bands_k(j, 1) = cands(j).k;
    bands_sigma(j, 1) = cands(j).sigma;
  end
end

% ----------------------------
% March in beta
% ----------------------------
for ib = 2:num_beta
  beta = beta_list(ib);
  fprintf('Processing beta = %.8f (%d / %d)\n', beta, ib, num_beta);

  % Continue existing bands.
  for m = 1:size(bands_k, 1)
    k_pred = LOCAL_predict_k(bands_k(m, 1:ib-1), beta_list(1:ib-1), beta);

    if isnan(k_pred)
      continue;
    end

    [is_ok, k_star, sigma_star] = LOCAL_track_one_band(beta, k_pred, ...
      num_k_local, nref, C, iprec, curvelen, d, pars2, ...
      k_floor, k_upper_factor, window_halfwidth, sigma_tol, track_jump_tol);

    if is_ok
      bands_k(m, ib) = k_star;
      bands_sigma(m, ib) = sigma_star;
    end
  end

  % Birth scan for new branches.
  if mod(ib - 1, birth_stride) == 0
    existing_k = bands_k(:, ib);
    existing_k = existing_k(~isnan(existing_k));

    cands_birth = LOCAL_global_candidates(beta, num_k_birth, nref, C, iprec, ...
      curvelen, d, pars2, k_floor, k_upper_factor, sigma_tol, ...
      prom_tol, root_merge_tol);

    cands_birth = LOCAL_remove_near_existing(cands_birth, existing_k, root_merge_tol);

    if ~isempty(cands_birth)
      nold = size(bands_k, 1);
      nnew = numel(cands_birth);

      bands_k(nold + nnew, num_beta) = NaN;
      bands_sigma(nold + nnew, num_beta) = NaN;

      for j = 1:nnew
        bands_k(nold + j, ib) = cands_birth(j).k;
        bands_sigma(nold + j, ib) = cands_birth(j).sigma;
      end
    end
  end
end

% ----------------------------
% Plot band curves
% ----------------------------
figure('Color', 'w');
hold on;

for m = 1:size(bands_k, 1)
  idx = find(~isnan(bands_k(m, :)));
  if numel(idx) >= 2
    plot(beta_list(idx), bands_k(m, idx), 'o-', 'LineWidth', 1.2, 'MarkerSize', 4);
  elseif numel(idx) == 1
    plot(beta_list(idx), bands_k(m, idx), 'x', 'LineWidth', 1.2, 'MarkerSize', 8);
  end
end

grid on;
xlabel('\beta');
ylabel('k');
title('Simple band curve plot from \sigma_{min} continuation');

fprintf('\nDetected branches: %d\n', size(bands_k, 1));
for m = 1:size(bands_k, 1)
  idx = find(~isnan(bands_k(m, :)));
  fprintf('Band %d: %d points\n', m, numel(idx));
end

% =========================================================================
function cands = LOCAL_global_candidates(beta, num_k, nref, C, iprec, curvelen, ...
  d, pars2, k_floor, k_upper_factor, sigma_tol, prom_tol, root_merge_tol)

  kmin = max(k_floor, 0.01 * beta);
  kmax = k_upper_factor * beta;

  cands = struct('k', {}, 'sigma', {}, 'prominence', {});

  if kmax <= kmin
    return;
  end

  k_grid = linspace(kmin, kmax, num_k);
  sigma_grid = zeros(size(k_grid));

  for j = 1:num_k
    sigma_grid(j) = LOCAL_sigma_only(beta, k_grid(j), nref, C, iprec, curvelen, d, pars2);
  end

  idx_list = LOCAL_find_local_minima(sigma_grid);

  for t = 1:numel(idx_list)
    j = idx_list(t);

    if j <= 1 || j >= num_k
      continue;
    end

    left = k_grid(j - 1);
    right = k_grid(j + 1);

    obj = @(k) LOCAL_sigma_only(beta, k, nref, C, iprec, curvelen, d, pars2);
    k_star = fminbnd(obj, left, right);
    sigma_star = obj(k_star);

    bg = min(sigma_grid(j - 1), sigma_grid(j + 1));
    prominence = bg / max(sigma_star, eps);

    if sigma_star < sigma_tol && prominence > prom_tol
      cand.k = k_star;
      cand.sigma = sigma_star;
      cand.prominence = prominence;
      cands(end + 1) = cand; %#ok<AGROW>
    end
  end

  cands = LOCAL_merge_candidates(cands, root_merge_tol);
end

% =========================================================================
function idx_list = LOCAL_find_local_minima(sigma_grid)

  idx_list = [];

  for j = 2:(numel(sigma_grid) - 1)
    if sigma_grid(j) < sigma_grid(j - 1) && sigma_grid(j) < sigma_grid(j + 1)
      idx_list(end + 1) = j; %#ok<AGROW>
    end
  end
end

% =========================================================================
function cands_out = LOCAL_merge_candidates(cands_in, tol)

  cands_out = struct('k', {}, 'sigma', {}, 'prominence', {});

  if isempty(cands_in)
    return;
  end

  [~, order] = sort([cands_in.k]);
  cands_in = cands_in(order);

  keep = true(1, numel(cands_in));

  for j = 2:numel(cands_in)
    if abs(cands_in(j).k - cands_in(j - 1).k) < tol
      if cands_in(j).sigma < cands_in(j - 1).sigma
        keep(j - 1) = false;
      else
        keep(j) = false;
      end
    end
  end

  cands_out = cands_in(keep);
end

% =========================================================================
function cands_out = LOCAL_remove_near_existing(cands_in, existing_k, tol)

  cands_out = struct('k', {}, 'sigma', {}, 'prominence', {});

  if isempty(cands_in)
    return;
  end

  for j = 1:numel(cands_in)
    if isempty(existing_k)
      cands_out(end + 1) = cands_in(j); %#ok<AGROW>
      continue;
    end

    if min(abs(cands_in(j).k - existing_k(:).')) > tol
      cands_out(end + 1) = cands_in(j); %#ok<AGROW>
    end
  end
end

% =========================================================================
function k_pred = LOCAL_predict_k(k_hist, beta_hist, beta_new)

  idx = find(~isnan(k_hist));

  if isempty(idx)
    k_pred = NaN;
    return;
  end

  if numel(idx) == 1
    k_pred = k_hist(idx(end));
    return;
  end

  i1 = idx(end - 1);
  i2 = idx(end);

  beta1 = beta_hist(i1);
  beta2 = beta_hist(i2);
  k1 = k_hist(i1);
  k2 = k_hist(i2);

  slope = (k2 - k1) / (beta2 - beta1);
  k_pred = k2 + slope * (beta_new - beta2);
end

% =========================================================================
function [is_ok, k_star, sigma_star] = LOCAL_track_one_band(beta, k_pred, ...
  num_k_local, nref, C, iprec, curvelen, d, pars2, ...
  k_floor, k_upper_factor, window_halfwidth, sigma_tol, track_jump_tol)

  is_ok = false;
  k_star = NaN;
  sigma_star = NaN;

  kmin = max(k_floor, 0.01 * beta);
  kmax = k_upper_factor * beta;

  left = max(kmin, k_pred - window_halfwidth);
  right = min(kmax, k_pred + window_halfwidth);

  if right <= left
    return;
  end

  k_grid = linspace(left, right, num_k_local);
  sigma_grid = zeros(size(k_grid));

  for j = 1:num_k_local
    sigma_grid(j) = LOCAL_sigma_only(beta, k_grid(j), nref, C, iprec, curvelen, d, pars2);
  end

  [~, jmin] = min(sigma_grid);

  if jmin == 1 || jmin == num_k_local
    return;
  end

  obj = @(k) LOCAL_sigma_only(beta, k, nref, C, iprec, curvelen, d, pars2);
  k_star = fminbnd(obj, k_grid(jmin - 1), k_grid(jmin + 1));
  sigma_star = obj(k_star);

  if sigma_star < sigma_tol && abs(k_star - k_pred) < track_jump_tol
    is_ok = true;
  end
end

% =========================================================================
function sigma = LOCAL_sigma_only(beta, k, nref, C, iprec, curvelen, d, pars2)

  pars1.beta = beta;
  pars1.d = d;
  pars1.k = k;

  proxy = precomp_proxy(pars1, pars2);
  A = LOCAL_construct_A(C, iprec, k * nref, pars1, proxy, curvelen);

  opts.tol = 1.0e-8;
  opts.maxit = 300;

  try
    [~, S, ~] = svds(A, 1, 'smallest', opts);
    sigma = S(1, 1);
  catch
    s = svd(A);
    sigma = s(end);
  end
end

% =========================================================================
function [C, curvelen, xxint, xxext] = LOCAL_construct_cont(ntot, flag_geom, nint, next)

  if strcmp(flag_geom, 'star')
    r = 0.3;
    k = 5;
    tt = linspace(0, 2 * pi * (1 - 1 / ntot), ntot);
    C = zeros(6, ntot);
    C(1, :) = 1.5 * cos(tt) + (r / 2) * cos((k + 1) * tt) + (r / 2) * cos((k - 1) * tt);
    C(2, :) = -1.5 * sin(tt) - (r / 2) * (k + 1) * sin((k + 1) * tt) ...
      - (r / 2) * (k - 1) * sin((k - 1) * tt);
    C(3, :) = -1.5 * cos(tt) - (r / 2) * (k + 1)^2 * cos((k + 1) * tt) ...
      - (r / 2) * (k - 1)^2 * cos((k - 1) * tt);
    C(4, :) = sin(tt) + (r / 2) * sin((k + 1) * tt) - (r / 2) * sin((k - 1) * tt);
    C(5, :) = cos(tt) + (r / 2) * (k + 1) * cos((k + 1) * tt) ...
      - (r / 2) * (k - 1) * cos((k - 1) * tt);
    C(6, :) = -sin(tt) - (r / 2) * (k + 1)^2 * sin((k + 1) * tt) ...
      + (r / 2) * (k - 1)^2 * sin((k - 1) * tt);
    curvelen = 2 * pi;
    rmin = sqrt(min(C(1, :).^2 + C(4, :).^2));
    rmax = sqrt(max(C(1, :).^2 + C(4, :).^2));
    ttint = 2 * pi * rand(1, nint);
    xxint = 0.6 * [rmin * cos(ttint); rmin * sin(ttint)];
    ttext = 2 * pi * rand(1, next);
    xxext = 1.6 * [rmax * cos(ttext); rmax * sin(ttext)];
  elseif strcmp(flag_geom, 'ellipse')
    a = 0.4;
    b = 0.4;
    tt = linspace(0, 2 * pi * (1 - 1 / ntot), ntot);
    C = zeros(6, ntot);
    C(1, :) = a * cos(tt);
    C(2, :) = -a * sin(tt);
    C(3, :) = -a * cos(tt);
    C(4, :) = b * sin(tt);
    C(5, :) = b * cos(tt);
    C(6, :) = -b * sin(tt);
    curvelen = 2 * pi;

    rmin = sqrt(min(C(1, :).^2 + C(4, :).^2));
    rmax = sqrt(max(C(1, :).^2 + C(4, :).^2));
    ttint = 2 * pi * rand(1, nint);
    xxint = 0.6 * [rmin * cos(ttint); rmin * sin(ttint)];
    ttext = 2 * pi * rand(1, next);
    xxext = 1.4 * [rmax * cos(ttext); rmax * sin(ttext)];
  else
    error('This option for the geometry is not implemented.');
  end
end

% =========================================================================
function A = LOCAL_construct_A(C, iprec, khint, pars1, proxy, curvelen)

  ntot = size(C, 2);
  A = eye(2 * ntot, 2 * ntot);
  h = curvelen / ntot;

  [jj, ii] = meshgrid(1:ntot, 1:ntot);
  L = jj - ii;
  L(L > ntot / 2) = L(L > ntot / 2) - ntot;
  L(L <= -ntot / 2) = L(L <= -ntot / 2) + ntot;

  if iprec == 2
    MU = [ ...
      0.7518812338640025 + 0.1073866830872157e1; ...
      -0.7225370982867850 - 0.6032109664493744];
    width = 2;
  elseif iprec == 6
    MU = [ ...
      0.2051970990601250e1 + 0.2915391987686505e1; ...
      -0.7407035584542865e1 - 0.8797979464048396e1; ...
      0.1219590847580216e2 + 0.1365562914252423e2; ...
      -0.1064623987147282e2 - 0.1157975479644601e2; ...
      0.4799117710681772e1 + 0.5130987287355766e1; ...
      -0.8837770983721025 - 0.9342187797694916];
    width = 6;
  elseif iprec == 10
    MU = [ ...
      0.3256353919777872D+01 + 0.4576078100790908D+01; ...
      -0.2096116396850468D+02 - 0.2469045273524281D+02; ...
      0.6872858265408605D+02 + 0.7648830198138171D+02; ...
      -0.1393153744796911D+03 - 0.1508194558089468D+03; ...
      0.1874446431742073D+03 + 0.1996415730837827D+03; ...
      -0.1715855846429547D+03 - 0.1807965537141134D+03; ...
      0.1061953812152787D+03 + 0.1110467735366555D+03; ...
      -0.4269031893958787D+02 - 0.4438764193424203D+02; ...
      0.1009036069527147D+02 + 0.1044548196545488D+02; ...
      -0.1066655310499552D+01 - 0.1100328792904271D+01];
    width = 10;
  else
    error('Unsupported iprec.');
  end

  for ix = 1:ntot
    for iy = 1:ntot
      l = L(ix, iy);

      if l == 0
        continue;
      end

      speedx = sqrt(C(2, ix)^2 + C(5, ix)^2);
      speedy = sqrt(C(2, iy)^2 + C(5, iy)^2);
      nx1 = C(5, ix) / speedx;
      nx2 = -C(2, ix) / speedx;
      ny1 = C(5, iy) / speedy;
      ny2 = -C(2, iy) / speedy;

      [pot, grad, hess] = LOCAL_h2d_directch(khint, C([1, 4], iy), 1, C([1, 4], ix));
      A(ix, iy) = (ny1 * grad(1) + ny2 * grad(2)) * h * speedy;
      A(ix, iy + ntot) = pot * h * speedy;
      A(ix + ntot, iy) = (nx1 * ny1 * hess(1) + (nx1 * ny2 + nx2 * ny1) * hess(2) ...
        + nx2 * ny2 * hess(3)) * h * speedy;
      A(ix + ntot, iy + ntot) = (nx1 * grad(1) + nx2 * grad(2)) * h * speedy;

      u = qpgreen_mfs(C([1, 4], iy), C([1, 4], ix), pars1, proxy);
      pot = u.pot;
      grad = u.grad;
      hess = u.hess;

      A(ix, iy) = A(ix, iy) - (ny1 * grad(1) + ny2 * grad(2)) * h * speedy;
      A(ix, iy + ntot) = A(ix, iy + ntot) - pot * h * speedy;
      A(ix + ntot, iy) = A(ix + ntot, iy) - (nx1 * ny1 * hess(1) ...
        + (nx1 * ny2 + nx2 * ny1) * hess(2) + nx2 * ny2 * hess(3)) * h * speedy;
      A(ix + ntot, iy + ntot) = A(ix + ntot, iy + ntot) ...
        - (nx1 * grad(1) + nx2 * grad(2)) * h * speedy;

      if abs(l) <= width
        A(ix, iy) = A(ix, iy) * (1 + MU(abs(l)));
        A(ix, iy + ntot) = A(ix, iy + ntot) * (1 + MU(abs(l)));
        A(ix + ntot, iy) = A(ix + ntot, iy) * (1 + MU(abs(l)));
        A(ix + ntot, iy + ntot) = A(ix + ntot, iy + ntot) * (1 + MU(abs(l)));
      end
    end
  end

  speed = sqrt(C(2, :).^2 + C(5, :).^2);
  W = sqrt(h * diag([speed, speed]));
  Winv = sqrt((1 / h) * diag(1 ./ [speed, speed]));
  A = W * A * Winv;
end

% =========================================================================
function [pot, grad, hess] = LOCAL_h2d_directch(wavek, sources, charge, targ)

  ns = size(sources, 2);
  nt = size(targ, 2);
  pot = zeros(1, nt);
  grad = zeros(2, nt);
  hess = zeros(3, nt);

  ima4inv = 1i / 4;

  for j = 1:nt
    for i = 1:ns
      xdiff = targ(1, j) - sources(1, i);
      ydiff = targ(2, j) - sources(2, i);
      rr = xdiff * xdiff + ydiff * ydiff;
      r = sqrt(rr);
      z = wavek * r;

      h0 = besselh(0, z);
      h1 = besselh(1, z);
      cdd = -h1 * (wavek * ima4inv / r);
      cdd2 = (wavek * ima4inv / r) / rr;
      h2z = (-z * h0 + 2 * h1);
      hf1 = (h2z * xdiff * xdiff - rr * h1);
      hf2 = (h2z * xdiff * ydiff);
      hf3 = (h2z * ydiff * ydiff - rr * h1);

      pot(j) = pot(j) + h0 * ima4inv * charge(i);

      cd = cdd * charge(i);
      grad(1, j) = grad(1, j) + cd * xdiff;
      grad(2, j) = grad(2, j) + cd * ydiff;

      cd = cdd2 * charge(i);
      hess(1, j) = hess(1, j) + cd * hf1;
      hess(2, j) = hess(2, j) + cd * hf2;
      hess(3, j) = hess(3, j) + cd * hf3;
    end
  end
end
