format long;
clear;
close all;

% Band structure plot from full k-scan at each beta.
% External functions required from the existing code base:
%   1. precomp_proxy
%   2. qpgreen_mfs

% ------------------------------
% Main parameters
% ------------------------------
ntot = 60;
flag_geom = 'ellipse';
iprec = 10;

er = 13;
nref = sqrt(er);
d = 1.0;

beta_min = 0.30;
beta_max = pi;
num_beta = 28;
beta_list = linspace(beta_min, beta_max, num_beta);

k_floor = 0.05;
k_upper_factor = 0.99;
num_k_scan = 180;

sigma_tol = 6.0e-3;
prom_tol = 4.0;
root_merge_tol = 0.06;
match_jump_tol = 0.12;
min_branch_points = 3;

pars2.H = 0.5 * d;
pars2.proxy_dist = 0.2 * d;
pars2.N_side = 50;
pars2.N_top = 50;
pars2.N_proxy_edge = 30;
pars2.M_pw = 10;

% ------------------------------
% Geometry
% ------------------------------
[C, curvelen, ~, ~] = LOCAL_construct_cont(ntot, flag_geom, 0, 0);

% ------------------------------
% Scan all beta values
% ------------------------------
all_cands = cell(num_beta, 1);

fprintf('Scanning all beta values...\n');
for ib = 1:num_beta
  beta = beta_list(ib);
  fprintf('  beta %3d / %3d : %.12f\n', ib, num_beta, beta);
  all_cands{ib} = LOCAL_scan_candidates_for_beta(beta, nref, C, iprec, ...
    curvelen, d, pars2, k_floor, k_upper_factor, num_k_scan, ...
    sigma_tol, prom_tol, root_merge_tol);
  fprintf('    accepted candidates = %d\n', numel(all_cands{ib}));
end

% ------------------------------
% Build branches by nearest predicted k
% ------------------------------
[bands_k, bands_sigma] = LOCAL_build_branches(beta_list, all_cands, ...
  match_jump_tol);

% ------------------------------
% Remove very short branches
% ------------------------------
keep = false(size(bands_k, 1), 1);
for m = 1:size(bands_k, 1)
  if nnz(~isnan(bands_k(m, :))) >= min_branch_points
    keep(m) = true;
  end
end
bands_k = bands_k(keep, :);
bands_sigma = bands_sigma(keep, :);

fprintf('Final number of plotted branches = %d\n', size(bands_k, 1));

% ------------------------------
% Plot
% ------------------------------
k_plot_max = k_upper_factor * beta_max * 1.05;

figure('Color', 'w', 'Position', [100, 100, 1000, 760]);
hold on;
box on;

% Light cone region: k >= beta.
patch([0, beta_max, beta_max, 0], ...
      [k_plot_max, k_plot_max, beta_max, 0], ...
      [0.75, 0.85, 1.00], ...
      'EdgeColor', 'none', 'FaceAlpha', 0.35);

plot([0, beta_max], [0, beta_max], 'b--', 'LineWidth', 1.2);

for m = 1:size(bands_k, 1)
  plot(beta_list, bands_k(m, :), '-o', 'LineWidth', 1.5, ...
    'MarkerSize', 5);
end

xlabel('\beta', 'FontSize', 14);
ylabel('k', 'FontSize', 14);
title('Band curve plot from full k-scan at each \beta', 'FontSize', 16);
xlim([0, beta_max]);
ylim([0, k_plot_max]);
grid on;
set(gca, 'FontSize', 12);

%% =========================================================================
function cands = LOCAL_scan_candidates_for_beta(beta, nref, C, iprec, ...
  curvelen, d, pars2, k_floor, k_upper_factor, num_k_scan, sigma_tol, ...
  prom_tol, root_merge_tol)
% LOCAL_scan_candidates_for_beta scans the full k-interval for one beta and
% returns accepted local minima of sigma_min.

  kmin = max(k_floor, 0.01 * beta);
  kmax = k_upper_factor * beta;

  if kmax <= kmin
    cands = struct('k', {}, 'sigma', {}, 'prominence', {});
    return;
  end

  k_samples = linspace(kmin, kmax, num_k_scan);
  sigma_samples = zeros(size(k_samples));

  for j = 1:num_k_scan
    sigma_samples(j) = LOCAL_sigma_only(beta, k_samples(j), nref, C, ...
      iprec, curvelen, d, pars2);
  end

  idx_list = LOCAL_find_local_minima(sigma_samples);
  raw = struct('k', {}, 'sigma', {}, 'prominence', {});

  for t = 1:numel(idx_list)
    j = idx_list(t);
    a = k_samples(max(j - 1, 1));
    b = k_samples(min(j + 1, num_k_scan));

    if b <= a
      continue;
    end

    obj = @(k) LOCAL_sigma_only(beta, k, nref, C, iprec, curvelen, d, pars2);
    kstar = fminbnd(obj, a, b);
    sstar = obj(kstar);

    left_max = sigma_samples(max(1, j - 2));
    right_max = sigma_samples(min(num_k_scan, j + 2));
    local_bg = max([left_max, sigma_samples(j - 1), sigma_samples(j + 1), right_max]);
    prominence = local_bg / max(sstar, 1.0e-14);

    if sstar < sigma_tol && prominence > prom_tol
      item.k = kstar;
      item.sigma = sstar;
      item.prominence = prominence;
      raw(end + 1) = item; %#ok<AGROW>
    end
  end

  cands = LOCAL_merge_candidates(raw, root_merge_tol);
end

%% =========================================================================
function idx_list = LOCAL_find_local_minima(vals)
% LOCAL_find_local_minima returns indices of strict local minima.

  idx_list = [];
  for j = 2:(numel(vals) - 1)
    if vals(j) < vals(j - 1) && vals(j) < vals(j + 1)
      idx_list(end + 1) = j; %#ok<AGROW>
    end
  end
end

%% =========================================================================
function cands_out = LOCAL_merge_candidates(cands_in, tol)
% LOCAL_merge_candidates merges nearby candidates and keeps the deeper one.

  if isempty(cands_in)
    cands_out = cands_in;
    return;
  end

  [~, order] = sort([cands_in.k]);
  cands = cands_in(order);

  cands_out = cands(1);
  for j = 2:numel(cands)
    last = cands_out(end);
    curr = cands(j);
    if abs(curr.k - last.k) < tol
      if curr.sigma < last.sigma
        cands_out(end) = curr;
      end
    else
      cands_out(end + 1) = curr; %#ok<AGROW>
    end
  end
end

%% =========================================================================
function [bands_k, bands_sigma] = LOCAL_build_branches(beta_list, all_cands, ...
  match_jump_tol)
% LOCAL_build_branches connects candidate roots across beta by nearest
% predicted k and starts new branches for unmatched candidates.

  num_beta = numel(beta_list);

  first = all_cands{1};
  nb0 = numel(first);

  if nb0 == 0
    bands_k = NaN(0, num_beta);
    bands_sigma = NaN(0, num_beta);
    return;
  end

  bands_k = NaN(nb0, num_beta);
  bands_sigma = NaN(nb0, num_beta);

  for j = 1:nb0
    bands_k(j, 1) = first(j).k;
    bands_sigma(j, 1) = first(j).sigma;
  end

  for ib = 2:num_beta
    cands = all_cands{ib};
    nc = numel(cands);
    used = false(1, nc);

    nband = size(bands_k, 1);
    pred = NaN(nband, 1);
    active = false(nband, 1);

    for m = 1:nband
      pred(m) = LOCAL_predict_k(bands_k(m, :), ib);
      active(m) = ~isnan(pred(m));
    end

    while true
      best_band = 0;
      best_cand = 0;
      best_cost = inf;

      for m = 1:nband
        if ~active(m)
          continue;
        end
        for j = 1:nc
          if used(j)
            continue;
          end
          cost = abs(cands(j).k - pred(m));
          if cost < best_cost && cost < match_jump_tol
            best_cost = cost;
            best_band = m;
            best_cand = j;
          end
        end
      end

      if best_band == 0
        break;
      end

      bands_k(best_band, ib) = cands(best_cand).k;
      bands_sigma(best_band, ib) = cands(best_cand).sigma;
      used(best_cand) = true;
      active(best_band) = false;
    end

    for j = 1:nc
      if ~used(j)
        nold = size(bands_k, 1);
        bands_k(nold + 1, :) = NaN;
        bands_sigma(nold + 1, :) = NaN;
        bands_k(nold + 1, ib) = cands(j).k;
        bands_sigma(nold + 1, ib) = cands(j).sigma;
      end
    end
  end
end

%% =========================================================================
function kpred = LOCAL_predict_k(band_row, ib)
% LOCAL_predict_k predicts the next k-value from the previous one or two
% valid points of a branch.

  prev_idx = find(~isnan(band_row(1:(ib - 1))));

  if isempty(prev_idx)
    kpred = NaN;
    return;
  end

  if prev_idx(end) ~= ib - 1
    kpred = NaN;
    return;
  end

  if numel(prev_idx) == 1
    kpred = band_row(prev_idx(end));
    return;
  end

  i2 = prev_idx(end);
  i1 = prev_idx(end - 1);
  k2 = band_row(i2);
  k1 = band_row(i1);
  kpred = k2 + (k2 - k1);
end

%% =========================================================================
function sigma = LOCAL_sigma_only(beta, k, nref, C, iprec, curvelen, d, pars2)
% LOCAL_sigma_only assembles the matrix for one (beta, k) pair and returns
% its smallest singular value.

  pars1.beta = beta;
  pars1.d = d;
  pars1.k = k;

  proxy = precomp_proxy(pars1, pars2);
  A = LOCAL_construct_A(C, iprec, k * nref, pars1, proxy, curvelen);

  opts.tol = 1.0e-8;
  opts.maxit = 300;

  try
    sigma = svds(A, 1, 'smallest', opts);
  catch
    s = svd(A);
    sigma = s(end);
  end
end

%% =========================================================================
function [C, curvelen, xxint, xxext] = LOCAL_construct_cont(ntot, flag_geom, nint, next)
% LOCAL_construct_cont builds the boundary discretization of the inclusion.

  if strcmp(flag_geom, 'star')
    r = 0.3;
    k = 5;
    tt = linspace(0, 2 * pi * (1 - 1 / ntot), ntot);
    C = zeros(6, ntot);
    C(1, :) = 1.5 * cos(tt) + (r / 2) * cos((k + 1) * tt) + (r / 2) * cos((k - 1) * tt);
    C(2, :) = -1.5 * sin(tt) - (r / 2) * (k + 1) * sin((k + 1) * tt) - (r / 2) * (k - 1) * sin((k - 1) * tt);
    C(3, :) = -1.5 * cos(tt) - (r / 2) * (k + 1) * (k + 1) * cos((k + 1) * tt) - (r / 2) * (k - 1) * (k - 1) * cos((k - 1) * tt);
    C(4, :) = sin(tt) + (r / 2) * sin((k + 1) * tt) - (r / 2) * sin((k - 1) * tt);
    C(5, :) = cos(tt) + (r / 2) * (k + 1) * cos((k + 1) * tt) - (r / 2) * (k - 1) * cos((k - 1) * tt);
    C(6, :) = -sin(tt) - (r / 2) * (k + 1) * (k + 1) * sin((k + 1) * tt) + (r / 2) * (k - 1) * (k - 1) * sin((k - 1) * tt);
    curvelen = 2 * pi;
    rmin = sqrt(min(C(1, :) .^ 2 + C(4, :) .^ 2));
    rmax = sqrt(max(C(1, :) .^ 2 + C(4, :) .^ 2));
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

    rmin = sqrt(min(C(1, :) .^ 2 + C(4, :) .^ 2));
    rmax = sqrt(max(C(1, :) .^ 2 + C(4, :) .^ 2));
    ttint = 2 * pi * rand(1, nint);
    xxint = 0.6 * [rmin * cos(ttint); rmin * sin(ttint)];
    ttext = 2 * pi * rand(1, next);
    xxext = 1.4 * [rmax * cos(ttext); rmax * sin(ttext)];
  else
    error('This option for the geometry is not implemented.');
  end
end

%% =========================================================================
function A = LOCAL_construct_A(C, iprec, khint, pars1, proxy, curvelen)
% LOCAL_construct_A assembles the weighted boundary integral matrix.

  ntot = size(C, 2);
  A = eye(2 * ntot, 2 * ntot);
  h = curvelen / ntot;
  [jj, ii] = meshgrid(1:ntot, 1:ntot);
  L = jj - ii;
  L(L > ntot / 2) = L(L > ntot / 2) - ntot;
  L(L <= -ntot / 2) = L(L <= -ntot / 2) + ntot;

  if iprec == 2
    MU = [0.7518812338640025 + 0.1073866830872157e1; ...
      -0.7225370982867850 - 0.6032109664493744];
    width = 2;
  elseif iprec == 6
    MU = [0.2051970990601250e1 + 0.2915391987686505e1; ...
      -0.7407035584542865e1 - 0.8797979464048396e1; ...
      0.1219590847580216e2 + 0.1365562914252423e2; ...
      -0.1064623987147282e2 - 0.1157975479644601e2; ...
      0.4799117710681772e1 + 0.5130987287355766e1; ...
      -0.8837770983721025 - 0.9342187797694916];
    width = 6;
  elseif iprec == 10
    MU = [0.3256353919777872D+01 + 0.4576078100790908D+01; ...
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

      speedx = sqrt(C(2, ix) ^ 2 + C(5, ix) ^ 2);
      speedy = sqrt(C(2, iy) ^ 2 + C(5, iy) ^ 2);
      nx1 = C(5, ix) / speedx;
      nx2 = -C(2, ix) / speedx;
      ny1 = C(5, iy) / speedy;
      ny2 = -C(2, iy) / speedy;

      [pot, grad, hess] = LOCAL_h2d_directch(khint, C([1, 4], iy), 1, C([1, 4], ix));
      A(ix, iy) = (ny1 * grad(1) + ny2 * grad(2)) * h * speedy;
      A(ix, iy + ntot) = pot * h * speedy;
      A(ix + ntot, iy) = (nx1 * ny1 * hess(1) + (nx1 * ny2 + nx2 * ny1) * hess(2) + nx2 * ny2 * hess(3)) * h * speedy;
      A(ix + ntot, iy + ntot) = (nx1 * grad(1) + nx2 * grad(2)) * h * speedy;

      u = qpgreen_mfs(C([1, 4], iy), C([1, 4], ix), pars1, proxy);
      pot = u.pot;
      grad = u.grad;
      hess = u.hess;
      A(ix, iy) = A(ix, iy) - (ny1 * grad(1) + ny2 * grad(2)) * h * speedy;
      A(ix, iy + ntot) = A(ix, iy + ntot) - pot * h * speedy;
      A(ix + ntot, iy) = A(ix + ntot, iy) - (nx1 * ny1 * hess(1) + (nx1 * ny2 + nx2 * ny1) * hess(2) + nx2 * ny2 * hess(3)) * h * speedy;
      A(ix + ntot, iy + ntot) = A(ix + ntot, iy + ntot) - (nx1 * grad(1) + nx2 * grad(2)) * h * speedy;

      if abs(l) <= width
        A(ix, iy) = A(ix, iy) * (1 + MU(abs(l)));
        A(ix, iy + ntot) = A(ix, iy + ntot) * (1 + MU(abs(l)));
        A(ix + ntot, iy) = A(ix + ntot, iy) * (1 + MU(abs(l)));
        A(ix + ntot, iy + ntot) = A(ix + ntot, iy + ntot) * (1 + MU(abs(l)));
      end
    end
  end

  speed = sqrt(C(2, :) .^ 2 + C(5, :) .^ 2);
  W = sqrt(h * diag([speed, speed]));
  Winv = sqrt((1 / h) * diag(1 ./ [speed, speed]));
  A = W * A * Winv;
end

%% =========================================================================
function [pot, grad, hess] = LOCAL_h2d_directch(wavek, sources, charge, targ)
% LOCAL_h2d_directch evaluates the 2D Helmholtz single-source potential,
% gradient, and Hessian.

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
