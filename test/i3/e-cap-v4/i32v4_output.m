function i32v4_output(output_dir, result)
%I32V4_OUTPUT Write compact complete or partial e-cap-v4 artifacts.
% Purpose:
%   Replace only the exact attempt's result.mat and report.md with the
%   latest compact checkpoint or final EMPIRICAL / UNQUALIFIED result.
% Input:
%   output_dir - Exact ecap-v4-a1 output directory.
%   result     - Serializable compact result struct.
% Output:
%   `result.mat` and `report.md` in output_dir.
% Main algorithm:
%   Save the result, then render only fields already computed by scientific
%   modules; partial artifacts omit unavailable sections without inventing
%   zeros or replacing unresolved values.
% Based on:
%   design-3-2e Section 10.

if ~(ischar(output_dir) || (isstring(output_dir) && isscalar(output_dir)))
  error('I32V4:OutputPath', 'output_dir must be a scalar path.');
end
output_dir = char(output_dir);
if ~isfolder(output_dir)
  mkdir(output_dir);
end
save(fullfile(output_dir, 'result.mat'), 'result', '-v7.3');
fid = fopen(fullfile(output_dir, 'report.md'), 'w');
if fid < 0
  error('I32V4:ReportOpen', 'Cannot open report.md.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# I3.2 e-cap-v4 empirical experiment\n\n');
fprintf(fid, '- Claim: `%s`\n', LOCAL_text(result, {'claim_label'}, ...
  'EMPIRICAL / UNQUALIFIED'));
fprintf(fid, '- Attempt: `%s`\n', LOCAL_text(result, {'attempt'}, 'unknown'));
LOCAL_metric(fid, result, {'retry_ordinal'}, 'retry ordinal');
fprintf(fid, '- Status: `%s`\n', LOCAL_text(result, {'status'}, 'UNKNOWN'));
fprintf(fid, '- State: `%s`\n', LOCAL_text(result, {'state'}, 'UNKNOWN'));
LOCAL_metric(fid, result, {'elapsed_s'}, 'elapsed seconds');
fprintf(fid, '- First blocker: `%s`\n\n', ...
  LOCAL_text(result, {'first_blocker'}, ''));

fprintf(fid, '## Frozen calculation\n\n');
fprintf(fid, '- M=48 role: artificial-wall prescribed Dirichlet trace only.\n');
fprintf(fid, '- Density/BIE/QZ/propagation solves: 0.\n');
fprintf(fid, '- Image-sum, Rayleigh-field, cubic and Gauss lifting calls: 0.\n');
fprintf(fid, '- MFS parameters: `(1.1,0.2,160,160,80,32)`.\n');
fprintf(fid, '- Fixed GQP empirical relative uncertainty: `1e-10`.\n');
fprintf(fid, '- All flags remain false.\n\n');

LOCAL_sequence_section(fid, result);
LOCAL_hhalf_section(fid, result);
LOCAL_fit_section(fid, result);
LOCAL_cap_section(fid, result);
LOCAL_field_section(fid, result);
LOCAL_boundary_section(fid, result);
LOCAL_resource_section(fid, result);

fprintf(fid, '\n## Warnings and unresolved rows\n\n');
fprintf(fid, 'Warnings:\n\n');
LOCAL_cells(fid, LOCAL_field(result, {'warnings'}, {}));
fprintf(fid, '\nUnresolved:\n\n');
LOCAL_cells(fid, LOCAL_field(result, {'unresolved'}, {}));

fprintf(fid, '\n## Reliability flags\n\n');
flags = LOCAL_field(result, {'flags'}, struct());
names = fieldnames(flags);
for flag_idx = 1:numel(names)
  fprintf(fid, '- %s: `%s`\n', names{flag_idx}, ...
    char(string(logical(flags.(names{flag_idx})))));
end
fprintf(fid, '\nNo interval in this artifact is reliable, certified, or an existence claim.\n');
end

%% ==================== Report sections ====================
% Sections are independent so a partial artifact remains readable.

function LOCAL_sequence_section(fid, result)
sequence = LOCAL_field(result, {'sequence'}, struct());
if ~isstruct(sequence) || ~all(isfield(sequence, ...
    {'N', 'N_wall', 'B_W', 'B_Gamma', 'L', 'B_V_Hhalf', 'M'}))
  return
end
fprintf(fid, '## Coupled residual sequences\n\n');
fprintf(fid, '| N_Gamma | N_W | B_W | B_Gamma | L | B_V,Hhalf | M |\n');
fprintf(fid, '|---:|---:|---:|---:|---:|---:|---:|\n');
for level_idx = 1:numel(sequence.N)
  fprintf(fid, '| %.0f | %.0f | %.17g | %.17g | %.17g | %.17g | %.17g |\n', ...
    sequence.N(level_idx), sequence.N_wall(level_idx), ...
    sequence.B_W(level_idx), sequence.B_Gamma(level_idx), ...
    sequence.L(level_idx), sequence.B_V_Hhalf(level_idx), ...
    sequence.M(level_idx));
end
fprintf(fid, '\nAdjacent differences are diagnostic only.\n\n');
end

function LOCAL_hhalf_section(fid, result)
data = LOCAL_field(result, {'modules', 'hhalf', 'data'}, struct());
if isempty(fieldnames(data))
  return
end
fprintf(fid, '## Shifted H1/2 trace lifting\n\n');
LOCAL_metric(fid, data, {'C_A'}, 'C_A');
LOCAL_metric(fid, data, {'C_E_wall'}, 'C_E,W');
LOCAL_metric(fid, data, {'C_E_circle'}, 'C_E,Gamma finite-mode');
LOCAL_metric(fid, data, {'C_E_wall_squared'}, 'C_E,W squared');
LOCAL_metric(fid, data, {'C_E_circle_squared'}, 'C_E,Gamma squared');
LOCAL_metric(fid, data, {'lambda_wall_min'}, 'minimum wall lambda');
LOCAL_metric(fid, data, {'oracle', 'maximum_defect'}, ...
  'single-mode oracle maximum defect');
LOCAL_boolean(fid, data, {'oracle', 'pass'}, 'single-mode oracle pass');
levels = LOCAL_field(data, {'levels'}, {});
if iscell(levels)
  fprintf(fid, '\n| level | wall-left map | wall-right map | circle map | factor Frobenius |\n');
  fprintf(fid, '|---:|---:|---:|---:|---:|\n');
  for level_idx = 1:numel(levels)
    entry = levels{level_idx};
    fprintf(fid, '| %d | %.17g | %.17g | %.17g | %.17g |\n', ...
      level_idx, LOCAL_number(entry, {'wall_left_weighted_map_norm'}), ...
      LOCAL_number(entry, {'wall_right_weighted_map_norm'}), ...
      LOCAL_number(entry, {'circle_weighted_map_norm'}), ...
      LOCAL_number(entry, {'volume_factor_fro'}));
  end
end
fprintf(fid, '\n- Circle constant is finite-mode empirical; no infinite angular-tail enclosure.\n');
fprintf(fid, '- Global L is contracted once in the fit module with complete P powers.\n\n');
sequence = LOCAL_field(result, {'sequence'}, struct());
if isstruct(sequence) && all(isfield(sequence, ...
    {'N', 'N_wall', 'wall_Hhalf_norm', 'circle_Hhalf_norm'}))
  fprintf(fid, '| N_Gamma | N_W | combined wall H1/2 norm | circle H1/2 norm |\n');
  fprintf(fid, '|---:|---:|---:|---:|\n');
  for level_idx = 1:numel(sequence.N)
    fprintf(fid, '| %.0f | %.0f | %.17g | %.17g |\n', ...
      sequence.N(level_idx), sequence.N_wall(level_idx), ...
      sequence.wall_Hhalf_norm(level_idx), ...
      sequence.circle_Hhalf_norm(level_idx));
  end
  fprintf(fid, '\nThese component norms use the same complete P powers and frozen tail formula as L.\n\n');
end
end

function LOCAL_fit_section(fid, result)
fits = LOCAL_field(result, {'fit'}, struct());
if isempty(fieldnames(fits))
  return
end
fprintf(fid, '## Scalar B_inf + C N^(-p) fits\n\n');
names = {'wall', 'circle', 'volume', 'majorant'};
labels = {'W', 'Gamma', 'V', 'M'};
for name_idx = 1:numel(names)
  if ~isfield(fits, names{name_idx})
    continue
  end
  fit = fits.(names{name_idx});
  fprintf(fid, '### %s\n\n', labels{name_idx});
  fprintf(fid, '- status: `%s`\n', LOCAL_text(fit, {'status'}, 'UNKNOWN'));
  LOCAL_boolean(fid, fit, {'resolved'}, 'resolved');
  LOCAL_boolean(fid, fit, {'plateau'}, 'plateau');
  LOCAL_metric(fid, fit, {'full_p'}, 'full-fit p');
  LOCAL_metric(fid, fit, {'full_B_inf'}, 'full-fit B_inf');
  LOCAL_metric(fid, fit, {'full_residual'}, 'full-fit maximum residual');
  LOCAL_metric(fid, fit, {'max_asymptote_distance'}, ...
    'maximum valid asymptote distance');
  LOCAL_metric(fid, fit, {'max_prediction_residual'}, ...
    'maximum valid all-level prediction residual');
  LOCAL_metric(fid, fit, {'leave_one_out_B_inf_spread'}, ...
    'leave-one-out B_inf spread');
  LOCAL_metric(fid, fit, {'remainder'}, 'fit empirical cap');
  records = LOCAL_field(fit, {'records'}, []);
  if isstruct(records) && ~isempty(records)
    fprintf(fid, '- valid fit mask: `');
    for record_idx = 1:numel(records)
      fprintf(fid, '%d', logical(records(record_idx).valid));
    end
    fprintf(fid, '`\n\n');
    fprintf(fid, '| fit | retained levels | valid | p | B_inf | max residual | reason |\n');
    fprintf(fid, '|---|---|---:|---:|---:|---:|---|\n');
    for record_idx = 1:numel(records)
      record = records(record_idx);
      if record_idx == 1
        fit_label = 'full';
      else
        fit_label = sprintf('LOO-%d', record_idx - 1);
      end
      retained = strtrim(sprintf('%.0f ', record.indices));
      fprintf(fid, '| %s | %s | %d | %.17g | %.17g | %.17g | `%s` |\n', ...
        fit_label, retained, logical(record.valid), record.p, ...
        record.B_inf, record.max_prediction_residual, record.reason);
    end
  end
  fprintf(fid, '\n');
end
end

function LOCAL_cap_section(fid, result)
caps = LOCAL_field(result, {'caps'}, struct());
if isempty(fieldnames(caps))
  return
end
fprintf(fid, '## Empirical cap rows\n\n');
names = {'wall', 'circle', 'volume'};
labels = {'W', 'Gamma', 'V'};
fprintf(fid, '| component | fit | GQP | roundoff | full-P | total |\n');
fprintf(fid, '|---|---:|---:|---:|---:|---:|\n');
for name_idx = 1:numel(names)
  if ~isfield(caps, names{name_idx})
    continue
  end
  row = caps.(names{name_idx});
  fprintf(fid, '| %s | %.17g | %.17g | %.17g | %.17g | %.17g |\n', ...
    labels{name_idx}, LOCAL_number(row, {'fit'}), ...
    LOCAL_number(row, {'gqp'}), LOCAL_number(row, {'roundoff'}), ...
    LOCAL_number(row, {'fullp'}), LOCAL_number(row, {'total'}));
end
fprintf(fid, '\n');
LOCAL_metric(fid, caps, {'majorant', 'fit'}, 'M fit cap');
LOCAL_metric(fid, caps, {'majorant', 'gqp'}, 'M GQP component sum');
LOCAL_metric(fid, caps, {'majorant', 'roundoff'}, 'M roundoff');
LOCAL_metric(fid, caps, {'majorant', 'roundoff_scalar_sum'}, ...
  'M two-addition roundoff');
LOCAL_metric(fid, caps, {'majorant', 'fullp'}, 'M full-P cap');
LOCAL_metric(fid, caps, {'epsilon_M_emp'}, 'epsilon_M empirical');
LOCAL_metric(fid, caps, {'epsilon_N_emp'}, 'epsilon_N empirical');
LOCAL_metric(fid, caps, {'epsilon_N_GQP_emp'}, 'epsilon_N GQP');
fprintf(fid, '\n');
end

function LOCAL_field_section(fid, result)
field = LOCAL_field(result, {'field'}, struct());
estimator = LOCAL_field(result, {'estimator'}, struct());
if isempty(fieldnames(field)) && isempty(fieldnames(estimator))
  return
end
fprintf(fid, '## Field candidate and nominal interval\n\n');
LOCAL_metric(fid, field, {'N_tilde'}, 'ordinary field anchor');
LOCAL_metric(fid, field, {'epsilon_N_emp'}, 'epsilon_N');
LOCAL_metric(fid, field, {'r_N'}, 'N_old,lower empirical');
LOCAL_metric(fid, field, {'L_finest'}, 'finest L');
LOCAL_metric(fid, field, {'N_comp_lower'}, 'companion field-lower candidate');
LOCAL_metric(fid, estimator, {'M_finest'}, 'finest M');
LOCAL_metric(fid, estimator, {'q_emp'}, 'q_emp');
LOCAL_metric(fid, estimator, {'k_interval', 'lower'}, 'nominal k lower');
LOCAL_metric(fid, estimator, {'k_interval', 'upper'}, 'nominal k upper');
LOCAL_metric(fid, estimator, {'k_interval', 'width'}, 'nominal k width');
LOCAL_boolean(fid, estimator, {'k_interval', 'width_below_1e6'}, ...
  'width below 1e-6');
fprintf(fid, '- epsilon_N subtraction count: 1\n');
fprintf(fid, '- field quantity is an empirical candidate, not an enclosure.\n\n');
end

function LOCAL_boundary_section(fid, result)
data = LOCAL_field(result, {'modules', 'boundary', 'data'}, struct());
if isempty(fieldnames(data))
  return
end
fprintf(fid, '## Boundary-action diagnostics\n\n');
LOCAL_metric(fid, data, {'action_counts', 'logical_coupled'}, ...
  'logical coupled actions');
LOCAL_metric(fid, data, {'action_counts', 'physical_total'}, ...
  'physical family actions');
LOCAL_metric(fid, data, {'gqp', 'table_n'}, 'MFS table order');
LOCAL_metric(fid, data, {'gqp', 'relative_uncertainty'}, ...
  'fixed GQP relative uncertainty');
fprintf(fid, '- image-sum calls: 0\n');
levels = LOCAL_field(data, {'level_metrics'}, []);
if isstruct(levels)
  for level_idx = 1:numel(levels)
    entry = levels(level_idx);
    fprintf(fid, '### Boundary level %d\n\n', level_idx);
    LOCAL_metric(fid, entry, {'N_circle'}, 'N_Gamma');
    LOCAL_metric(fid, entry, {'N_wall'}, 'N_W');
    LOCAL_metric(fid, entry, {'circle_recombination'}, ...
      'circle recombination defect');
    LOCAL_metric(fid, entry, {'wall_recombination'}, ...
      'wall recombination defect');
    LOCAL_metric(fid, entry, {'wall_self_split_recombination'}, ...
      'wall Kress split recombination');
    fprintf(fid, '\n');
  end
end
end

function LOCAL_resource_section(fid, result)
fprintf(fid, '## Resource diagnostics\n\n');
LOCAL_metric(fid, result, {'resource', 'memory_mib_max'}, ...
  'hard memory gate MiB');
LOCAL_metric(fid, result, {'resource', 'hard_s'}, 'hard time gate seconds');
LOCAL_metric(fid, result, {'modules', 'boundary', 'memory', ...
  'local_peak_mib'}, 'boundary/MFS memory proxy MiB');
LOCAL_metric(fid, result, {'modules', 'hhalf', 'memory', ...
  'local_peak_mib'}, 'H1/2 memory proxy MiB');
LOCAL_metric(fid, result, {'modules', 'cap', 'memory', ...
  'local_peak_mib'}, 'fit/cap memory proxy MiB');
fprintf(fid, '- OS RSS peak: not measured; module values are MATLAB object proxies.\n');
end

%% ==================== Safe field rendering ====================
% Missing partial-stage fields are rendered as NaN or omitted, never zeroed.

function LOCAL_metric(fid, root, path, label)
value = LOCAL_field(root, path, NaN);
if isnumeric(value) && isscalar(value)
  fprintf(fid, '- %s: %.17g\n', label, value);
end
end

function LOCAL_boolean(fid, root, path, label)
value = LOCAL_field(root, path, false);
fprintf(fid, '- %s: `%s`\n', label, char(string(logical(value))));
end

function LOCAL_cells(fid, values)
if isempty(values)
  fprintf(fid, '- none recorded\n');
  return
end
for value_idx = 1:numel(values)
  fprintf(fid, '- `%s`\n', char(string(values{value_idx})));
end
end

function value = LOCAL_number(root, path)
value = LOCAL_field(root, path, NaN);
if ~(isnumeric(value) && isscalar(value))
  value = NaN;
end
end

function value = LOCAL_text(root, path, fallback)
value = LOCAL_field(root, path, fallback);
value = char(string(value));
end

function value = LOCAL_field(root, path, fallback)
value = root;
for path_idx = 1:numel(path)
  if ~isstruct(value) || ~isfield(value, path{path_idx})
    value = fallback;
    return
  end
  value = value.(path{path_idx});
end
end
