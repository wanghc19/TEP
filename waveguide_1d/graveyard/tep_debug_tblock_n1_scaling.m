% Purpose:
%   Check the near-diagonal mesh-refinement scaling of the Kress logarithmic
%   coefficient difference N1diff for the T-block.
%
% Main algorithm:
%   For several ntot values, build the same geometry used in the existing
%   T-block debug path, evaluate N1diff at one representative row and a few
%   fixed offsets m = j - i, then compare the raw values, their magnitudes,
%   and the normalized quantity N1diff / (m * h).
%
% Based on:
%   tep_debug_tblock.m and the Kress-style N1diff logic from tep_scan_local3.m.
%
% Main changes:
%   This file does not assemble the full T-block and does not run any scan or
%   refinement workflow.  It isolates only the N1diff scaling test.
%
% Numerical goal:
%   Check whether N1diff(i, i + m) behaves like O(h) for fixed offset m as
%   h = 2 * pi / ntot tends to zero.
format long;
clear;

% --- 1. Representative Test Setup ---
ntot_list = [80, 120, 160, 240];
m_list = [1, 2, 3];
flag_geom = 'ellipse';              % Geometry type: 'star' or 'ellipse'
er = 13;                            % Relative permittivity; nref = sqrt(er)
nref = sqrt(er);
d = 1.0;                            % Period length of the waveguide cell
beta = 0.5 * 2 * pi / d;            % Fixed Bloch phase
k_test = 2.6535097381199977;        % Representative exterior wavenumber

pars1.beta = beta;
pars1.d = d;
pars1.k = k_test;

fprintf('N1diff near-diagonal scaling diagnostic\n');
fprintf('  Geometry   : %s\n', flag_geom);
fprintf('  ntot_list  : [%s]\n', num2str(ntot_list));
fprintf('  m_list     : [%s]\n', num2str(m_list));
fprintf('  k_test     : %.16f\n', k_test);
fprintf('  beta       : %.16f\n', beta);
fprintf('  nref       : %.16f\n', nref);

results = LOCAL_run_n1_scaling_test(ntot_list, m_list, flag_geom, pars1, nref);
LOCAL_print_n1_scaling_summary(results);
LOCAL_plot_n1_scaling(results);

fprintf('\nN1diff scaling diagnostic completed successfully.\n');

%% =========================================================================
%  LOCAL HELPERS
%  =========================================================================
function results = LOCAL_run_n1_scaling_test(ntot_list, m_list, flag_geom, pars1, nref)

  ncases = length(ntot_list);
  nm = length(m_list);

  h_list = NaN(ncases, 1);
  i0_list = NaN(ncases, 1);
  N1diff_mat = NaN(ncases, nm);
  N1diff_over_mh_mat = NaN(ncases, nm);

  for kcase = 1:ncases
    ntot = ntot_list(kcase);
    h = 2 * pi / ntot;
    [C, ~, ~, ~] = LOCAL_construct_cont(ntot, flag_geom, 0, 0);
    i0 = round(ntot / 2);

    N1diff_row = LOCAL_get_n1diff_row(C, pars1, nref, i0, m_list);

    h_list(kcase) = h;
    i0_list(kcase) = i0;
    N1diff_mat(kcase, :) = N1diff_row;
    N1diff_over_mh_mat(kcase, :) = N1diff_row ./ (m_list * h);
  end

  results.ntot_list = ntot_list(:);
  results.m_list = m_list(:).';
  results.h_list = h_list;
  results.i0_list = i0_list;
  results.N1diff_mat = N1diff_mat;
  results.abs_N1diff_mat = abs(N1diff_mat);
  results.N1diff_over_mh_mat = N1diff_over_mh_mat;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function N1diff_row = LOCAL_get_n1diff_row(C, pars1, nref, i0, m_list)

  ntot = size(C, 2);
  x = C(1, :);
  y = C(4, :);
  dxdt = C(2, :);
  dydt = C(5, :);

  [jj, ii] = meshgrid(1:ntot, 1:ntot);
  L = jj - ii;
  L(L > ntot / 2) = L(L > ntot / 2) - ntot;
  L(L <= -ntot / 2) = L(L <= -ntot / 2) + ntot;
  offdiag = L ~= 0;

  xdiff = x.' - x;
  ydiff = y.' - y;
  rr = xdiff.^2 + ydiff.^2;
  rr(~offdiag) = 1;
  r = sqrt(rr);

  khint = pars1.k * nref;
  N1_int = LOCAL_kress_tblock_log_coeff(khint, xdiff, ydiff, r, dxdt, dydt, offdiag);
  N1_center = LOCAL_kress_tblock_log_coeff(pars1.k, xdiff, ydiff, r, dxdt, dydt, offdiag);
  N1diff = N1_int - N1_center;

  j_idx = LOCAL_wrap_indices(i0 + m_list, ntot);
  N1diff_row = N1diff(i0, j_idx);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_n1_scaling_summary(results)

  ntot_list = results.ntot_list;
  m_list = results.m_list;

  fprintf('\nN1diff scaling table:\n');
  for kcase = 1:length(ntot_list)
    fprintf('\nntot = %d, h = %.16e, i0 = %d\n', ...
      ntot_list(kcase), results.h_list(kcase), results.i0_list(kcase));
    fprintf('  %-6s %-28s %-18s %-28s\n', 'm', 'N1diff(i0,i0+m)', '|N1diff|', 'N1diff/(m*h)');
    for jm = 1:length(m_list)
      fprintf('  %-6d %-28s %-18.10e %-28s\n', ...
        m_list(jm), ...
        LOCAL_complex_string(results.N1diff_mat(kcase, jm)), ...
        results.abs_N1diff_mat(kcase, jm), ...
        LOCAL_complex_string(results.N1diff_over_mh_mat(kcase, jm)));
    end
  end

  fprintf('\nScaling summary:\n');
  for jm = 1:length(m_list)
    abs_vals = results.abs_N1diff_mat(:, jm);
    h_vals = results.h_list;
    ratio_raw = abs_vals(1:end-1) ./ abs_vals(2:end);
    ratio_h = h_vals(1:end-1) ./ h_vals(2:end);
    norm_vals = results.N1diff_over_mh_mat(:, jm);

    fprintf('  m = %d:\n', m_list(jm));
    fprintf('    abs(N1diff) ratios across refinements     = [%s]\n', num2str(ratio_raw.', ' %.3e'));
    fprintf('    h ratios across refinements               = [%s]\n', num2str(ratio_h.', ' %.3e'));
    fprintf('    real(N1diff/(m*h)) across refinements     = [%s]\n', num2str(real(norm_vals).', ' %.3e'));
    fprintf('    imag(N1diff/(m*h)) across refinements     = [%s]\n', num2str(imag(norm_vals).', ' %.3e'));
  end
  fprintf('  Interpretation: if abs(N1diff) tracks h and N1diff/(m*h) stays fairly stable,\n');
  fprintf('  then the observed near-diagonal scaling is consistent with O(h).\n');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_plot_n1_scaling(results)

  h_vals = results.h_list;
  m_list = results.m_list;
  cmap = lines(length(m_list));

  figure('Name', 'N1diff Scaling', 'Color', 'w');

  subplot(1, 2, 1);
  hold on;
  for jm = 1:length(m_list)
    loglog(h_vals, results.abs_N1diff_mat(:, jm), 'o-', 'LineWidth', 1.2, ...
      'Color', cmap(jm, :), 'DisplayName', sprintf('m = %d', m_list(jm)));
  end
  grid on;
  xlabel('h', 'FontSize', 11);
  ylabel('|N1diff(i0,i0+m)|', 'FontSize', 11);
  title('Near-diagonal N1diff magnitude', 'FontSize', 12);
  legend('Location', 'best');

  subplot(1, 2, 2);
  hold on;
  for jm = 1:length(m_list)
    plot(h_vals, real(results.N1diff_over_mh_mat(:, jm)), 'o-', 'LineWidth', 1.2, ...
      'Color', cmap(jm, :), 'DisplayName', sprintf('real, m = %d', m_list(jm)));
    if any(abs(imag(results.N1diff_over_mh_mat(:, jm))) > 0)
      plot(h_vals, imag(results.N1diff_over_mh_mat(:, jm)), 's--', 'LineWidth', 1.2, ...
        'Color', cmap(jm, :), 'HandleVisibility', 'off');
    end
  end
  grid on;
  xlabel('h', 'FontSize', 11);
  ylabel('real(N1diff / (m*h))', 'FontSize', 11);
  title('Normalized near-diagonal quantity', 'FontSize', 12);
  legend('Location', 'best');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function idx = LOCAL_wrap_indices(idx, ntot)

  idx = mod(idx - 1, ntot) + 1;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function text = LOCAL_complex_string(z)

  text = sprintf('%.6e%+.6ei', real(z), imag(z));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function N1 = LOCAL_kress_tblock_log_coeff(wavek, xdiff, ydiff, r, dxdt, dydt, offdiag)

  ntot = length(dxdt);
  dxdt_t = repmat(dxdt(:), 1, ntot);
  dydt_t = repmat(dydt(:), 1, ntot);

  N1 = zeros(ntot, ntot);
  zprime_dot_diff = dxdt_t .* xdiff + dydt_t .* ydiff;
  N1(offdiag) = -(wavek / (2 * pi)) * (zprime_dot_diff(offdiag) ./ r(offdiag)) .* ...
    besselj(1, wavek * r(offdiag));

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
    C = C .* 0.2;
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
