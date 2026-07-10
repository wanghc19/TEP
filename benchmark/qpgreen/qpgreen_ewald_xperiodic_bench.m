function [u, aux] = qpgreen_ewald_xperiodic_bench(src, trg, pars1, pars2)
% QPGREEN_EWALD_XPERIODIC_BENCH Evaluate x-periodic qpgreen by Ewald sums.
%
% Purpose:
%   Computes the function value of the two-dimensional quasi-periodic Green
%   function for an x-periodic Helmholtz problem using Linton's Ewald
%   representation.
%
% Main algorithm:
%   Uses the Ewald split
%     G = G_spectral + G_spatial,
%   where the spectral part sums modes
%     beta_m = beta + 2*pi*m/d,
%     gamma_m = sqrt(beta_m^2 - k^2),
%   and the spatial part sums periodic source images with exponential
%   integral terms E_n(z).  For propagating modes the branch is
%     gamma_m = -i*sqrt(k^2 - beta_m^2),
%   matching the outgoing convention used in waveguide_1d/archive/qpgreen_ewald.m.
%
% Based on:
%   waveguide_1d/archive/qpgreen_ewald.m and Linton (1998), especially the
%   Ewald formula in Section 2.  Linton periodicizes the Y coordinate; this
%   benchmark helper is written directly for the project convention where x
%   is periodic and y is transverse.
%
% Main changes:
%   This benchmark-only version computes values only, accepts many target
%   points in one call, uses the repository Faddeeva_erfc MEX for complex
%   complementary error functions, and
%   returns NaN at singular source-image points instead of a misleading
%   finite value.
%
% Numerical goal:
%   Provide a stable reference implementation for comparing the augmented
%   MFS quasi-periodic Green function on Linton table points and on cell
%   grids.

  if size(src, 1) ~= 2 || size(src, 2) ~= 1
    error('qpgreen_ewald_xperiodic_bench:InvalidSource', ...
      'src must be a 2-by-1 source point.');
  end
  if size(trg, 1) ~= 2
    error('qpgreen_ewald_xperiodic_bench:InvalidTarget', ...
      'trg must be a 2-by-nt target array.');
  end

  k = pars1.k;
  beta = pars1.beta;
  d = pars1.d;
  a = pars2.a;
  M1 = pars2.M1;
  M2 = pars2.M2;
  N = pars2.N;
  if isfield(pars2, 'grazing_tol')
    grazing_tol = pars2.grazing_tol;
  else
    grazing_tol = 1e-12;
  end

  nt = size(trg, 2);
  u = NaN(1, nt);

  p = 2*pi/d;
  m_spec = -M1:M1;
  beta_m = beta + m_spec * p;
  gamma_m = LOCAL_ewald_gamma(k, beta_m);

  min_abs_gamma = min(abs(gamma_m));
  cutoff_warning = min_abs_gamma < grazing_tol;
  if cutoff_warning
    warning('qpgreen_ewald_xperiodic_bench:GrazingMode', ...
      'A Rayleigh gamma_m is close to zero; Ewald values may be ill-conditioned.');
  end

  m_spatial = -M2:M2;
  singular_tol = max(10*eps(max(1, abs(d))), 1e-14);

  for it = 1:nt
    dx_periodic = trg(1, it) - src(1);
    dy_transverse = trg(2, it) - src(2);
    image_dx = dx_periodic - m_spatial * d;
    image_r = sqrt(image_dx.^2 + dy_transverse.^2);

    if min(image_r) <= singular_tol
      u(it) = NaN;
      continue;
    end

    spectral_value = LOCAL_spectral_sum(dx_periodic, dy_transverse, d, a, ...
      beta_m, gamma_m);
    spatial_value = LOCAL_spatial_sum(dx_periodic, dy_transverse, k, beta, ...
      d, a, m_spatial, N);
    u(it) = spectral_value + spatial_value;
  end

  aux = struct();
  aux.min_abs_gamma = min_abs_gamma;
  aux.cutoff_warning = cutoff_warning;
  aux.branch_note = 'gamma_m = sqrt(beta_m^2-k^2), propagating branch gamma_m = -1i*sqrt(k^2-beta_m^2)';
  aux.erfc_note = 'Uses Faddeeva_erfc for complex complementary error functions.';
end

%% ==================== Ewald matrix helper ====================
% This helper assembles the two split sums for each target point.

function spectral_value = LOCAL_spectral_sum(dx_periodic, dy_transverse, d, a, ...
    beta_m, gamma_m)
  arg_plus = gamma_m * (d/(2*a)) + (a * dy_transverse / d);
  arg_minus = gamma_m * (d/(2*a)) - (a * dy_transverse / d);

  exp_plus = exp(gamma_m * dy_transverse);
  exp_minus = exp(-gamma_m * dy_transverse);
  erfc_plus = LOCAL_erfc(arg_plus);
  erfc_minus = LOCAL_erfc(arg_minus);

  phase = exp(1i * beta_m * dx_periodic);
  spectral_value = 0.25 * sum(phase .* (exp_plus .* erfc_plus + ...
    exp_minus .* erfc_minus) ./ (gamma_m * d));
end

function spatial_value = LOCAL_spatial_sum(dx_periodic, dy_transverse, k, beta, ...
    d, a, m_spatial, N)
  image_dx = dx_periodic - m_spatial * d;
  image_r = sqrt(image_dx.^2 + dy_transverse.^2);
  z = (image_r * a / d).^2;
  exp_neg_z = exp(-z);

  En_curr = exp_neg_z ./ z;
  En_next = expint(z);
  spatial_terms = zeros(size(m_spatial));

  for n = 0:N
    coeff = (k*d/(2*a))^(2*n) / factorial(n);
    spatial_terms = spatial_terms + coeff * En_next;
    if n < N
      En_curr = En_next;
      En_next = (exp_neg_z - z .* En_curr) / (n + 1);
    end
  end

  phase = exp(1i * beta * m_spatial * d);
  spatial_value = (1/(4*pi)) * sum(phase .* spatial_terms);
end

%% ==================== Rayleigh branch helper ====================
% This helper chooses the outgoing/decaying Ewald square-root branch.

function gamma_m = LOCAL_ewald_gamma(k, beta_m)
  gamma_m = zeros(size(beta_m));
  diff_sq = beta_m.^2 - k^2;
  idx_evanescent = diff_sq >= 0;
  idx_propagating = diff_sq < 0;
  gamma_m(idx_evanescent) = sqrt(diff_sq(idx_evanescent));
  gamma_m(idx_propagating) = -1i * sqrt(-diff_sq(idx_propagating));
end

%% ==================== Complex erfc helper ====================
% This helper uses the repository MEX wrapper for complex arguments.

function val = LOCAL_erfc(z)
  val = Faddeeva_erfc(z);
end
