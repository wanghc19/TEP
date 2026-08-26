function i32v3_output(output_dir, result)
%I32V3_OUTPUT Write compact complete or partial v3 artifacts.
% Purpose:
%   Atomically replace the exact ecap-v3-a1 result and report after each
%   checkpoint so a hard scientific blocker still leaves readable evidence.
% Input:
%   output_dir - Exact attempt directory created by the thin entry.
%   result     - Compact serializable result struct.
% Based on:
%   design-3-2d Section 13 partial-artifact and false-claim contract.

if ~(ischar(output_dir) || (isstring(output_dir) && isscalar(output_dir)))
  error('I32V3:OutputPath', 'output_dir must be a scalar path.');
end
output_dir = char(output_dir);
if ~isfolder(output_dir)
  mkdir(output_dir);
end
result_path = fullfile(output_dir, 'result.mat');
report_path = fullfile(output_dir, 'report.md');
save(result_path, 'result', '-v7.3');
fid = fopen(report_path, 'w');
if fid < 0
  error('I32V3:ReportOpen', 'Cannot open report.md for writing.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# I3.2 e-cap-v3 empirical experiment\n\n');
fprintf(fid, '- Claim: `%s`\n', LOCAL_text(result, 'claim_label', ...
  'EMPIRICAL / UNQUALIFIED'));
fprintf(fid, '- Attempt: `%s`\n', LOCAL_text(result, 'attempt', 'unknown'));
fprintf(fid, '- Retry ordinal: %.0f\n', LOCAL_number(result, 'retry_ordinal'));
fprintf(fid, '- Status: `%s`\n', LOCAL_text(result, 'status', 'UNKNOWN'));
fprintf(fid, '- State: `%s`\n', LOCAL_text(result, 'state', 'UNKNOWN'));
fprintf(fid, '- Elapsed: %.17g s\n', LOCAL_number(result, 'elapsed_s'));
fprintf(fid, '- First blocker: `%s`\n\n', ...
  LOCAL_text(result, 'first_blocker', ''));

fprintf(fid, '## Frozen object\n\n');
fprintf(fid, '- M=48 role: artificial-wall total Dirichlet trace only.\n');
fprintf(fid, '- Density/QZ/BIE resolve count: 0.\n');
fprintf(fid, '- Image-sum and Rayleigh-field paths: 0.\n');
fprintf(fid, '- Trial refinement changes evaluation only.\n\n');

fprintf(fid, '## Fixed MFS GQP evaluator\n\n');
LOCAL_metric_line(fid, result, ...
  {'modules', 'gqp', 'data', 'table_n'}, 'table order');
LOCAL_metric_line(fid, result, ...
  {'modules', 'gqp', 'data', 'relative_uncertainty'}, ...
  'fixed empirical relative uncertainty');
LOCAL_metric_line(fid, result, ...
  {'modules', 'gqp', 'data', 'spot_oracle', 'maximum_relative'}, ...
  'maximum direct-pair spot relative defect');
LOCAL_boolean_line(fid, result, ...
  {'modules', 'gqp', 'data', 'supported'}, ...
  'fixed 1e-10 assumption supported');
LOCAL_metric_line(fid, result, ...
  {'modules', 'gqp', 'data', 'parameters', 'H'}, 'MFS H');
LOCAL_metric_line(fid, result, ...
  {'modules', 'gqp', 'data', 'parameters', 'proxy_dist'}, ...
  'MFS proxy distance');
LOCAL_metric_line(fid, result, ...
  {'modules', 'gqp', 'data', 'parameters', 'N_side'}, 'MFS N_side');
LOCAL_metric_line(fid, result, ...
  {'modules', 'gqp', 'data', 'parameters', 'N_top'}, 'MFS N_top');
LOCAL_metric_line(fid, result, ...
  {'modules', 'gqp', 'data', 'parameters', 'N_proxy_edge'}, ...
  'MFS N_proxy_edge');
LOCAL_metric_line(fid, result, ...
  {'modules', 'gqp', 'data', 'parameters', 'M_pw'}, 'MFS M_pw');
fprintf(fid, '- Image-sum code path: 0\n');
fprintf(fid, '- Direct-pair spots are compatibility checks, not global bounds.\n\n');

fprintf(fid, '## Empirical components\n\n');
LOCAL_metric_line(fid, result, {'estimator', 'B_wall'}, 'B_W');
LOCAL_metric_line(fid, result, {'estimator', 'B_circle'}, 'B_Gamma');
LOCAL_metric_line(fid, result, {'estimator', 'B_volume'}, 'B_V');
LOCAL_metric_line(fid, result, {'estimator', 'M_h'}, 'M_h');
LOCAL_metric_line(fid, result, {'caps', 'wall', 'total'}, 'epsilon_W');
LOCAL_metric_line(fid, result, {'caps', 'circle', 'total'}, 'epsilon_Gamma');
LOCAL_metric_line(fid, result, {'caps', 'volume', 'total'}, 'epsilon_V');
LOCAL_metric_line(fid, result, {'caps', 'epsilon_M_emp'}, 'epsilon_M');
LOCAL_metric_line(fid, result, {'estimator', 'field_lower'}, 'field lower');
LOCAL_metric_line(fid, result, {'caps', 'epsilon_N_emp'}, 'epsilon_N');
LOCAL_metric_line(fid, result, {'estimator', 'q_emp'}, 'q_emp');
LOCAL_metric_line(fid, result, {'estimator', 'k_interval', 'lower'}, 'k lower');
LOCAL_metric_line(fid, result, {'estimator', 'k_interval', 'upper'}, 'k upper');
LOCAL_metric_line(fid, result, {'estimator', 'k_interval', 'width'}, 'k width');
LOCAL_boolean_line(fid, result, ...
  {'estimator', 'k_interval', 'width_below_1e6'}, ...
  'k width below 1e-6');

fprintf(fid, '\n## Empirical cap breakdown\n\n');
LOCAL_cap_lines(fid, result, 'wall', 'W');
LOCAL_cap_lines(fid, result, 'circle', 'Gamma');
LOCAL_cap_lines(fid, result, 'volume', 'V');
LOCAL_metric_line(fid, result, {'caps', 'epsilon_N_emp'}, ...
  'epsilon_N empirical');
LOCAL_metric_line(fid, result, {'caps', 'epsilon_N_GQP_emp'}, ...
  'epsilon_N GQP component');

fprintf(fid, '\n## Wall cross diagnostics\n\n');
LOCAL_metric_line(fid, result, ...
  {'modules', 'boundary', 'data', 'wall', 'piece_norms', 'prescribed'}, ...
  'prescribed wall map norm');
LOCAL_metric_line(fid, result, ...
  {'modules', 'boundary', 'data', 'wall', 'piece_norms', 'self'}, ...
  'same-wall self map norm');
LOCAL_metric_line(fid, result, ...
  {'modules', 'boundary', 'data', 'wall', 'piece_norms', 'opposite_cross'}, ...
  'opposite-wall cross map norm');
LOCAL_metric_line(fid, result, ...
  {'modules', 'boundary', 'data', 'wall', 'piece_norms', 'circle_cross'}, ...
  'circle-to-wall cross map norm');
LOCAL_metric_line(fid, result, ...
  {'modules', 'boundary', 'data', 'wall', 'recombination_defect'}, ...
  'prescribed+self+opposite+circle recombination defect');
LOCAL_metric_line(fid, result, ...
  {'modules', 'boundary', 'data', 'wall', 'self_split_recombination'}, ...
  'same-wall Kress split recombination defect');
LOCAL_pair_line(fid, result, ...
  {'modules', 'boundary', 'data', 'wall', 'bands', 'pieces', 'total', ...
  'common_factor_difference'}, 'wall total common-band changes');
LOCAL_pair_line(fid, result, ...
  {'modules', 'boundary', 'data', 'wall', 'bands', 'pieces', 'total', ...
  'new_shell_factor_norm'}, 'wall total new-shell norms');

fprintf(fid, '\n## Circle boundary diagnostics\n\n');
LOCAL_metric_line(fid, result, ...
  {'modules', 'boundary', 'data', 'circle', 'piece_norms', 'prescribed'}, ...
  'circle target/jump norm');
LOCAL_metric_line(fid, result, ...
  {'modules', 'boundary', 'data', 'circle', 'piece_norms', 'self'}, ...
  'circle self norm');
LOCAL_metric_line(fid, result, ...
  {'modules', 'boundary', 'data', 'circle', 'piece_norms', 'cross'}, ...
  'wall-to-circle cross norm');
LOCAL_metric_line(fid, result, ...
  {'modules', 'boundary', 'data', 'circle', 'piece_norms', 'total'}, ...
  'circle total residual norm');
LOCAL_metric_line(fid, result, ...
  {'modules', 'boundary', 'data', 'circle', 'recombination_defect'}, ...
  'circle recombination defect');
LOCAL_pair_line(fid, result, ...
  {'modules', 'boundary', 'data', 'circle', 'bands', 'pieces', 'total', ...
  'common_factor_difference'}, 'circle total common-band changes');
LOCAL_pair_line(fid, result, ...
  {'modules', 'boundary', 'data', 'circle', 'bands', 'pieces', 'total', ...
  'new_shell_factor_norm'}, 'circle total new-shell norms');

fprintf(fid, '\n## Volume lift block diagnostics\n\n');
LOCAL_metric_line(fid, result, ...
  {'modules', 'lifting', 'data', 'block_norms', 'circle_collar'}, ...
  'circle collar');
LOCAL_metric_line(fid, result, ...
  {'modules', 'lifting', 'data', 'block_norms', 'left_wall_strip'}, ...
  'left wall strip');
LOCAL_metric_line(fid, result, ...
  {'modules', 'lifting', 'data', 'block_norms', 'right_wall_strip'}, ...
  'right wall strip');
LOCAL_metric_line(fid, result, ...
  {'modules', 'lifting', 'data', 'block_norms', 'center_left'}, ...
  'center-left singleton');
LOCAL_metric_line(fid, result, ...
  {'modules', 'lifting', 'data', 'block_norms', 'center_right'}, ...
  'center-right singleton');
LOCAL_metric_line(fid, result, ...
  {'modules', 'lifting', 'data', 'block_norms', 'first_plus'}, ...
  'first-plus singleton');
LOCAL_metric_line(fid, result, ...
  {'modules', 'lifting', 'data', 'block_norms', 'first_minus'}, ...
  'first-minus singleton');
LOCAL_metric_line(fid, result, ...
  {'modules', 'lifting', 'data', 'block_norms', ...
  'direct_sum_identity_defect'}, 'direct-sum identity defect');
fprintf(fid, '- block diagnostic cap contribution: 0\n');

fprintf(fid, '\n## Full-P tail diagnostics\n\n');
LOCAL_tail_lines(fid, result, 'wall', 'W');
LOCAL_tail_lines(fid, result, 'circle', 'Gamma');
LOCAL_tail_lines(fid, result, 'volume', 'V');
fprintf(fid, '- tail diagnostic cap contribution: 0; tails are already in the augmented full-P row\n');

fprintf(fid, '\n## Resource diagnostics\n\n');
LOCAL_metric_line(fid, result, {'resource', 'memory_mib_max'}, ...
  'hard memory gate MiB');
LOCAL_metric_line(fid, result, ...
  {'modules', 'gqp', 'memory', 'local_peak_mib'}, 'GQP memory proxy MiB');
LOCAL_metric_line(fid, result, ...
  {'modules', 'boundary', 'memory', 'local_peak_mib'}, ...
  'boundary retained/proxy MiB');
LOCAL_metric_line(fid, result, ...
  {'modules', 'lifting', 'memory', 'local_peak_mib'}, ...
  'lifting retained/proxy MiB');
LOCAL_metric_line(fid, result, ...
  {'modules', 'cap', 'memory', 'local_peak_mib'}, ...
  'cap retained/proxy MiB');
fprintf(fid, '- OS RSS peak: not measured; module values are MATLAB object proxies.\n');

fprintf(fid, '\n## Warnings and unresolved rows\n\n');
fprintf(fid, 'Warnings:\n\n');
LOCAL_cell_lines(fid, LOCAL_field(result, {'warnings'}, {}));
fprintf(fid, '\nUnresolved:\n\n');
LOCAL_cell_lines(fid, LOCAL_field(result, {'unresolved'}, {}));

fprintf(fid, '\n## Reliability flags\n\n');
flags = LOCAL_field(result, {'flags'}, struct());
names = fieldnames(flags);
for flag_idx = 1:numel(names)
  fprintf(fid, '- %s: `%s`\n', names{flag_idx}, ...
    string(logical(flags.(names{flag_idx}))));
end

function LOCAL_cap_lines(fid, result, component, label)
fprintf(fid, '### %s\n\n', label);
names = {'target', 'source', 'weight', 'fullp', 'gqp', 'roundoff'};
for cap_idx = 1:numel(names)
  name = names{cap_idx};
  LOCAL_metric_line(fid, result, {'caps', component, name, 'remainder'}, ...
    [name, ' remainder']);
  if ismember(name, {'target', 'source', 'weight', 'fullp'})
    LOCAL_metric_line(fid, result, ...
      {'caps', component, name, 'candidate'}, [name, ' finite candidate']);
    LOCAL_boolean_line(fid, result, ...
      {'caps', component, name, 'resolved'}, [name, ' resolved']);
    LOCAL_boolean_line(fid, result, ...
      {'caps', component, name, 'absolute_plateau'}, ...
      [name, ' absolute plateau']);
  elseif strcmp(name, 'gqp')
    LOCAL_metric_line(fid, result, ...
      {'caps', component, name, 'scale'}, 'GQP non-cancelling scale');
    LOCAL_boolean_line(fid, result, ...
      {'caps', component, name, 'supported'}, 'GQP row supported');
  end
end
LOCAL_metric_line(fid, result, {'caps', component, 'total'}, 'total');
fprintf(fid, '\n');
end

function LOCAL_boolean_line(fid, root, path, label)
value = LOCAL_field(root, path, false);
fprintf(fid, '- %s: `%s`\n', label, char(string(logical(value))));
end

function LOCAL_pair_line(fid, root, path, label)
value = LOCAL_field(root, path, [NaN, NaN]);
if isnumeric(value) && numel(value) == 2
  fprintf(fid, '- %s: [%.17g, %.17g]\n', label, value(1), value(2));
end
end
fprintf(fid, '\nNo interval in this artifact is reliable, certified, or an existence claim.\n');
end

function LOCAL_metric_line(fid, root, path, label)
value = LOCAL_field(root, path, NaN);
if isnumeric(value) && isscalar(value)
  fprintf(fid, '- %s: %.17g\n', label, value);
end
end

function LOCAL_cell_lines(fid, values)
if isempty(values)
  fprintf(fid, '- none recorded\n');
  return
end
for j = 1:numel(values)
  fprintf(fid, '- `%s`\n', char(string(values{j})));
end
end

function LOCAL_tail_lines(fid, result, component, label)
base = {'component', component, 'tail'};
LOCAL_metric_line(fid, result, [base, {'finest_plus_squared'}], ...
  [label, ' finest plus tail squared']);
LOCAL_metric_line(fid, result, [base, {'finest_minus_squared'}], ...
  [label, ' finest minus tail squared']);
LOCAL_metric_line(fid, result, [base, {'finest_combined_norm'}], ...
  [label, ' finest combined tail norm']);
LOCAL_metric_line(fid, result, [base, {'nested_change_8_16_norm'}], ...
  [label, ' tail change 8-to-16']);
LOCAL_metric_line(fid, result, [base, {'nested_change_16_32_norm'}], ...
  [label, ' tail change 16-to-32']);
available = LOCAL_field(result, [base, {'finite_available'}], false);
fprintf(fid, '- %s tail finite available: `%s`\n', label, ...
  char(string(logical(available))));
end

function value = LOCAL_field(root, path, fallback)
value = root;
for j = 1:numel(path)
  if ~isstruct(value) || ~isfield(value, path{j})
    value = fallback;
    return
  end
  value = value.(path{j});
end
end

function value = LOCAL_text(root, name, fallback)
value = LOCAL_field(root, {name}, fallback);
value = char(string(value));
end

function value = LOCAL_number(root, name)
value = LOCAL_field(root, {name}, NaN);
if ~(isnumeric(value) && isscalar(value))
  value = NaN;
end
end
