format long;
clear;

% Diagnostic Script: Refined Singular Value Dip Search for Fixed Beta

% --- 1. Parameter Setup ---
ntot = 60;                        % Single boundary point count for dip refinement
flag_geom = 'ellipse';
iprec = 10;
er = 13;
nref = sqrt(er);
d = 1.0;
beta = 0.5 * 2 * pi / d;          % Fixed Bloch phase

pars1.beta = beta;
pars1.d = d;

pars2.H = 0.5 * pars1.d;          % Height of the fundamental domain [-H, H]
pars2.proxy_dist = 0.2 * pars1.d; % Distance of proxy boundary from the domain
pars2.N_side = 50;                % Number of collocation points on Left/Right walls
pars2.N_top = 50;                 % Number of collocation points on Top/Bottom walls
pars2.N_proxy_edge = 30;          % Number of proxy sources per edge
pars2.M_pw = 10;                  % Truncation order for plane waves (-M_pw to M_pw)

num_k_coarse = 50;
num_k_fine = 100;
k_samples = linspace(0.01 * beta, 0.99 * beta, num_k_coarse);
refine_drop_tol_rel = 1e-2;
refine_drop_tol_abs = 1e-12;
flag_run_kernel_check = false;

fprintf('Running refined singular value scan (beta = %.8f, ntot = %d)\n', beta, ntot);

if flag_run_kernel_check
  LOCAL_check_h2d_vectorization();
end

% --- 2. Geometry Setup ---
[C, curvelen, ~, ~] = LOCAL_construct_cont(ntot, flag_geom, 0, 0);

% --- 3. Coarse Scan ---
fprintf('Starting coarse k scan with %d samples...\n', num_k_coarse);
s_vals_coarse = zeros(size(k_samples));
for j = 1:length(k_samples)
  s_vals_coarse(j) = LOCAL_get_sigma_min(k_samples(j), nref, C, iprec, pars1, pars2, curvelen);
end

[sigma_min_coarse, idx_min] = min(s_vals_coarse);
k_min_coarse = k_samples(idx_min);
[k_ref_left, k_ref_right] = LOCAL_get_refine_interval(k_samples, idx_min);
k_samples_fine = linspace(k_ref_left, k_ref_right, num_k_fine);

fprintf('Starting refined local k scan on [%.8f, %.8f] with %d samples...\n', ...
  k_ref_left, k_ref_right, num_k_fine);
s_vals_fine = zeros(size(k_samples_fine));
for j = 1:length(k_samples_fine)
  s_vals_fine(j) = LOCAL_get_sigma_min(k_samples_fine(j), nref, C, iprec, pars1, pars2, curvelen);
end

[sigma_min_fine, idx_min_fine] = min(s_vals_fine);
k_min_fine = k_samples_fine(idx_min_fine);
drop_in_min = sigma_min_coarse - sigma_min_fine;
significant_drop = drop_in_min > max(refine_drop_tol_abs, refine_drop_tol_rel * sigma_min_coarse);

fprintf('\nCoarse minimum : sigma_min = %.16e at k = %.16f\n', sigma_min_coarse, k_min_coarse);
fprintf('Refined minimum: sigma_min = %.16e at k = %.16f\n', sigma_min_fine, k_min_fine);
fprintf('Absolute drop  : %.16e\n', drop_in_min);
if significant_drop
  fprintf('Refinement lowered the minimum significantly.\n');
else
  fprintf('Refinement did not lower the minimum significantly.\n');
end

% --- 4. Plot Coarse and Refined Scans ---
figure('Name', 'Refined Singular Value Dip Diagnosis', ...
  'Position', [120, 120, 950, 700], 'Color', 'w');
semilogy(k_samples, s_vals_coarse, 'o-', 'LineWidth', 1.2, 'MarkerSize', 4, ...
  'DisplayName', 'Coarse scan');
hold on;
semilogy(k_samples_fine, s_vals_fine, 'r-', 'LineWidth', 1.8, ...
  'DisplayName', 'Refined local scan');
semilogy(k_min_coarse, sigma_min_coarse, 'ko', 'MarkerFaceColor', 'k', ...
  'DisplayName', 'Coarse minimum');
semilogy(k_min_fine, sigma_min_fine, 'rs', 'MarkerFaceColor', 'r', ...
  'DisplayName', 'Refined minimum');
grid on;
xlabel('Wavenumber k', 'FontSize', 11);
ylabel('\sigma_{min}', 'FontSize', 11);
title(sprintf('Dip refinement for ntot = %d', ntot), 'FontSize', 12);
legend('Location', 'best');
xlim([min(k_samples), max(k_samples)]);

fprintf('\nFinished refined dip scan successfully.\n');

%% =========================================================================
%  LOCAL HELPERS
%  =========================================================================
function smin = LOCAL_get_sigma_min(kh, nref, C, iprec, pars1, pars2, curvelen)
  pars1.k = kh;
  proxy = precomp_proxy(pars1, pars2);
  A = LOCAL_construct_A(C, iprec, kh * nref, pars1, proxy, curvelen);
  s = svd(A);
  smin = s(end);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [k_left, k_right] = LOCAL_get_refine_interval(k_samples, idx_min)
  nk = length(k_samples);
  if nk < 2
    error('Need at least two k-samples to define a refinement interval.');
  end

  if idx_min <= 1
    k_left = k_samples(1);
    k_right = k_samples(2);
  elseif idx_min >= nk
    k_left = k_samples(nk - 1);
    k_right = k_samples(nk);
  else
    k_left = k_samples(idx_min - 1);
    k_right = k_samples(idx_min + 1);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [C, curvelen, xxint, xxext] = LOCAL_construct_cont(ntot, flag_geom, nint, next)

  if strcmp(flag_geom, 'star')
    r = 0.3;
    k = 5;
    tt = linspace(0, 2 * pi * (1 - 1 / ntot), ntot);
    C = zeros(6, ntot);
    C(1,:) =   1.5 * cos(tt) + (r / 2) *            cos((k + 1) * tt) + (r / 2) *            cos((k - 1) * tt);
    C(2,:) = - 1.5 * sin(tt) - (r / 2) * (k + 1) * sin((k + 1) * tt) - (r / 2) * (k - 1) * sin((k - 1) * tt);
    C(3,:) = - 1.5 * cos(tt) - (r / 2) * (k + 1) * (k + 1) * cos((k + 1) * tt) - (r / 2) * (k - 1) * (k - 1) * cos((k - 1) * tt);
    C(4,:) =       sin(tt) + (r / 2) *            sin((k + 1) * tt) - (r / 2) *            sin((k - 1) * tt);
    C(5,:) =       cos(tt) + (r / 2) * (k + 1) * cos((k + 1) * tt) - (r / 2) * (k - 1) * cos((k - 1) * tt);
    C(6,:) = -     sin(tt) - (r / 2) * (k + 1) * (k + 1) * sin((k + 1) * tt) + (r / 2) * (k - 1) * (k - 1) * sin((k - 1) * tt);
    curvelen = 2 * pi;
    rmin = sqrt(min(C(1,:).^2 + C(4,:).^2));
    rmax = sqrt(max(C(1,:).^2 + C(4,:).^2));
    ttint = 2 * pi * rand(1, nint);
    xxint = 0.6 * [rmin * cos(ttint); rmin * sin(ttint)];
    ttext = 2 * pi * rand(1, next);
    xxext = 1.6 * [rmax * cos(ttext); rmax * sin(ttext)];
  elseif strcmp(flag_geom, 'ellipse')
    a = 0.4;
    b = 0.4;
    tt = linspace(0, 2 * pi * (1 - 1 / ntot), ntot);
    C = zeros(6, ntot);
    C(1,:) =  a * cos(tt);
    C(2,:) = -a * sin(tt);
    C(3,:) = -a * cos(tt);
    C(4,:) =  b * sin(tt);
    C(5,:) =  b * cos(tt);
    C(6,:) = -b * sin(tt);
    curvelen = 2 * pi;

    rmin = sqrt(min(C(1,:).^2 + C(4,:).^2));
    rmax = sqrt(max(C(1,:).^2 + C(4,:).^2));
    ttint = 2 * pi * rand(1, nint);
    xxint = 0.6 * [rmin * cos(ttint); rmin * sin(ttint)];
    ttext = 2 * pi * rand(1, next);
    xxext = 1.4 * [rmax * cos(ttext); rmax * sin(ttext)];
  else
    error('This option for the geometry is not implemented.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A = LOCAL_construct_A(C, iprec, khint, pars1, proxy, curvelen)

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
      -0.8837770983721025   - 0.9342187797694916];
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
    error('Unsupported iprec value.');
  end

  for ix = 1:ntot
    for iy = 1:ntot
      l = L(ix, iy);
      if l == 0
        continue;
      end

      speedx = sqrt(C(2, ix)^2 + C(5, ix)^2);
      speedy = sqrt(C(2, iy)^2 + C(5, iy)^2);
      nx1 =  C(5, ix) / speedx;
      nx2 = -C(2, ix) / speedx;
      ny1 =  C(5, iy) / speedy;
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
      A(ix + ntot, iy) = A(ix + ntot, iy) - ...
        (nx1 * ny1 * hess(1) + (nx1 * ny2 + nx2 * ny1) * hess(2) + nx2 * ny2 * hess(3)) * h * speedy;
      A(ix + ntot, iy + ntot) = A(ix + ntot, iy + ntot) - (nx1 * grad(1) + nx2 * grad(2)) * h * speedy;

      if abs(l) <= width
        A(ix, iy) = A(ix, iy) * (1 + MU(abs(l)));
        A(ix, iy + ntot) = A(ix, iy + ntot) * (1 + MU(abs(l)));
        A(ix + ntot, iy) = A(ix + ntot, iy) * (1 + MU(abs(l)));
        A(ix + ntot, iy + ntot) = A(ix + ntot, iy + ntot) * (1 + MU(abs(l)));
      end
    end
  end

  speed = sqrt(C(2,:).^2 + C(5,:).^2);
  W = sqrt(h * diag([speed, speed]));
  Winv = sqrt((1 / h) * diag(1 ./ [speed, speed]));
  A = W * A * Winv;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [pot, grad, hess] = LOCAL_h2d_directch(wavek, sources, charge, targ)

  ns = size(sources, 2);
  nt = size(targ, 2);
  charge = reshape(charge, 1, []);
  if length(charge) ~= ns
    error('charge must have one entry per source.');
  end

  ima4inv = 1i / 4;
  xdiff = bsxfun(@minus, targ(1, :).', sources(1, :));
  ydiff = bsxfun(@minus, targ(2, :).', sources(2, :));
  rr = xdiff.^2 + ydiff.^2;
  r = sqrt(rr);
  z = wavek * r;

  h0 = besselh(0, z);
  h1 = besselh(1, z);
  cdd = -h1 .* (wavek * ima4inv ./ r);
  cdd2 = (wavek * ima4inv ./ r) ./ rr;
  h2z = -z .* h0 + 2 * h1;
  hf1 = h2z .* xdiff .* xdiff - rr .* h1;
  hf2 = h2z .* xdiff .* ydiff;
  hf3 = h2z .* ydiff .* ydiff - rr .* h1;

  weighted_h0 = bsxfun(@times, h0, charge);
  weighted_cdd = bsxfun(@times, cdd, charge);
  weighted_cdd2 = bsxfun(@times, cdd2, charge);

  pot = ima4inv * sum(weighted_h0, 2).';
  grad = zeros(2, nt);
  grad(1, :) = sum(weighted_cdd .* xdiff, 2).';
  grad(2, :) = sum(weighted_cdd .* ydiff, 2).';

  hess = zeros(3, nt);
  hess(1, :) = sum(weighted_cdd2 .* hf1, 2).';
  hess(2, :) = sum(weighted_cdd2 .* hf2, 2).';
  hess(3, :) = sum(weighted_cdd2 .* hf3, 2).';

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [pot, grad, hess] = LOCAL_h2d_directch_loop(wavek, sources, charge, targ)

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
      h2z = -z * h0 + 2 * h1;
      hf1 = h2z * xdiff * xdiff - rr * h1;
      hf2 = h2z * xdiff * ydiff;
      hf3 = h2z * ydiff * ydiff - rr * h1;

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_check_h2d_vectorization()

  rng(1);
  wavek = 1.7;
  sources = randn(2, 4);
  targ = randn(2, 5) + 0.3;
  charge = randn(1, 4);

  [pot_vec, grad_vec, hess_vec] = LOCAL_h2d_directch(wavek, sources, charge, targ);
  [pot_loop, grad_loop, hess_loop] = LOCAL_h2d_directch_loop(wavek, sources, charge, targ);

  pot_diff = max(abs(pot_vec(:) - pot_loop(:)));
  grad_diff = max(abs(grad_vec(:) - grad_loop(:)));
  hess_diff = max(abs(hess_vec(:) - hess_loop(:)));

  fprintf('Vectorization check for LOCAL_h2d_directch:\n');
  fprintf('  max |pot_vec  - pot_loop | = %.3e\n', pot_diff);
  fprintf('  max |grad_vec - grad_loop| = %.3e\n', grad_diff);
  fprintf('  max |hess_vec - hess_loop| = %.3e\n', hess_diff);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
