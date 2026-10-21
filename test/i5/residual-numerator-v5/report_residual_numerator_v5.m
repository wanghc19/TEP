function report_residual_numerator_v5(result_path)
%REPORT_RESIDUAL_NUMERATOR_V5 Print a read-only scalar audit of a saved result.
% Purpose:
%   Expose module, analytic-radius, cutoff, gate, and oracle-call diagnostics.
% Input:
%   result_path - Explicit completed v5 result MAT path.
% Output:
%   Text only. No MAT file is created or changed and no action is reevaluated.
% Main algorithm:
%   Read persisted scalars; take diagnostic square roots and print ledgers.

loaded = load(result_path, 'result');
r = loaded.result;
fprintf('MATLAB=%s\nSTATUS=%s\n', version, r.status);
fprintf('Bwall=%.17g Bmaterial=%.17g Blift=%.17g Mideal=%.17g\n', ...
  r.B_Gamma_pm_ideal, r.B_Upsilon_ideal, r.B_lift_ideal, r.M_ideal);
fprintf('LABEL=%s DELTA_SF=%s DELTA_FP=%s\n', ...
  r.condition_label, r.delta_sf, r.delta_fp);
for field = {'normal', 'lifting'}
  name = field{1};
  w = r.wall.(name);
  fprintf('WALL_%s finite=%.17g center=%.17g radius=%.17g cell=%.17g high=%.17g bound=%.17g cancellation=%.17g\n', ...
    name, sqrt(w.finite_squared), w.signed_center_norm, ...
    w.non_special_function_radius_norm, sqrt(w.propagation_tail_squared), ...
    sqrt(w.high_mode_tail_squared), sqrt(w.bound_squared), w.cancellation_ratio);
end
m = r.material;
for field = {'normal', 'lifting'}
  name = field{1};
  fprintf('MATERIAL_%s finite=%.17g center=%.17g radius=%.17g cell=%.17g high=%.17g\n', ...
    name, sqrt(m.finite.([name, '_squared'])), ...
    sqrt(m.finite.(['center_', name, '_squared'])), ...
    sqrt(m.finite.(['radius_', name, '_squared'])), ...
    sqrt(m.cell_tail.([name, '_squared'])), ...
    sqrt(m.high_tail.([name, '_squared'])));
end
fields = {'cutoff_selection', 'evaluation_selection', 'tightness', ...
  'analytic_radius_ownership', 'phase_gate', 'gate_audit', 'theorem_gate', ...
  'sf_ledger', 'provenance'};
for j = 1:numel(fields)
  fprintf('%s=%s\n', upper(fields{j}), jsonencode(r.(fields{j})));
end
fprintf('MATERIAL_FINITE=%s\n', jsonencode(m.finite));
fprintf('MATERIAL_HIGH=%s\n', jsonencode(m.high_tail));
fprintf('MATERIAL_CELL=%s\n', jsonencode(m.cell_tail));
end
