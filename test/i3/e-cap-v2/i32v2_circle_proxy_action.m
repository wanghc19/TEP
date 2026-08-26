function [value, normal, piece] = i32v2_circle_proxy_action(g, src, trg, ...
    source_normals, target_normals, tau, zeta, ds, field_level, ...
    variant_id, source_panel)
%I32V2_CIRCLE_PROXY_ACTION Apply the MFS smooth remainder on circle data.
% Purpose:
%   Provide one actual interpolated proxy-action path shared by the circle
%   module and the mismatched-grid direct-MFS preflight oracle.
% Input/Output:
%   Geometry, densities, GQP table selection, and outputs follow the circle
%   action notation in design-3-2d. No free primary is included here.

nt = size(trg, 2);
value = complex(zeros(nt, size(tau, 2)));
normal = complex(zeros(nt, size(tau, 2)));
piece = struct('value_double', value, 'value_single', value, ...
  'normal_double', value, 'normal_single', value);
interpolation_cma = 0;
kernel_phase_multiply = 0;
boundary_factor_cma = 0;
for first = 1:source_panel:size(src, 2)
  last = min(size(src, 2), first + source_panel - 1);
  ids = first:last;
  [p, gx, gy, hxx, hxy, hyy, pair_audit] = i32v2_gqp_pair( ...
    g, src(:, ids), trg, field_level, variant_id);
  sx = source_normals(1, ids);
  sy = source_normals(2, ids);
  D = -bsxfun(@times, gx, sx) - bsxfun(@times, gy, sy);
  Dt = -bsxfun(@times, hxx, target_normals(1, :).'*sx) ...
    - bsxfun(@times, hxy, target_normals(1, :).'*sy + ...
    target_normals(2, :).'*sx) ...
    - bsxfun(@times, hyy, target_normals(2, :).'*sy);
  Sn = bsxfun(@times, gx, target_normals(1, :).') + ...
    bsxfun(@times, gy, target_normals(2, :).');
  vd = ds * D * tau(ids, :);
  vs = -ds * p * zeta(ids, :);
  nd = ds * Dt * tau(ids, :);
  ns = -ds * Sn * zeta(ids, :);
  value = value + vd + vs;
  normal = normal + nd + ns;
  piece.value_double = piece.value_double + vd;
  piece.value_single = piece.value_single + vs;
  piece.normal_double = piece.normal_double + nd;
  piece.normal_single = piece.normal_single + ns;
  interpolation_cma = interpolation_cma + ...
    pair_audit.interpolation.all_field_complex_operation_count;
  kernel_phase_multiply=kernel_phase_multiply+ ...
    pair_audit.bloch_phase_multiply_count;
  boundary_factor_cma = boundary_factor_cma + ...
    4 * nt * numel(ids) * size(tau, 2);
end
piece.audit.operation_ledger = struct( ...
  'interpolation_cma', interpolation_cma, ...
  'kernel_phase_multiply',kernel_phase_multiply, ...
  'boundary_factor_cma', boundary_factor_cma, ...
  'factor_comparison', 0, 'scalar_arithmetic', 0, ...
  'total', interpolation_cma+kernel_phase_multiply+boundary_factor_cma);
end
