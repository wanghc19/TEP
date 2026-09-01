function profile_postprocess()
%PROFILE_POSTPROCESS Frozen candidate-7 scalar profile postprocess.
% Purpose:
%   Evaluate the design-section-56 four-point empirical profile after the
%   reviewed candidate-7-to-candidate-9 field identity decision.
% Input:
%   None. Every scalar and path identity is fixed in this source.
% Output:
%   One create-once profile.json in the runner-owned profile-001 leaf.
% Main algorithm:
%   Form direct drifts, ratios, prediction and late positional diagnostics;
%   then run seven fixed fminsearch starts around an economy-QR variable
%   projection for k(s)=k_inf+C*s^(-p), p=exp(x)>0.
% Notes:
%   The canonical pure-FEM winner remains candidate 3. This postprocess is
%   specific to old candidate 7 and its reviewed new candidate 9 component.

  % --- stage 1: freeze literal inputs and direct quantities ---
  s_values = [12, 18, 24, 30];
  k_values = [1.842941342508127, 1.837659912216170, ...
    1.835680010800799, 1.834721598133798];
  k30_prediction = 1.8347168036;
  k_bie_late = 1.832770289108157;
  old_distance = 0.0029097217;
  if any(~isfinite([s_values, k_values, k30_prediction, ...
      k_bie_late, old_distance]))
    error('I4P:DIRECT_ARITHMETIC_UNAVAILABLE', ...
      'A frozen scalar is nonfinite.');
  end

  signed_drifts = diff(k_values);
  absolute_drifts = abs(signed_drifts);
  if any(~isfinite([signed_drifts, absolute_drifts]))
    error('I4P:DIRECT_ARITHMETIC_UNAVAILABLE', ...
      'A direct drift is nonfinite.');
  end
  drifts = repmat(struct('from_s', 0, 'to_s', 0, ...
    'signed', 0, 'absolute', 0), 1, 3);
  for drift_index = 1:3
    drifts(drift_index).from_s = s_values(drift_index);
    drifts(drift_index).to_s = s_values(drift_index + 1);
    drifts(drift_index).signed = signed_drifts(drift_index);
    drifts(drift_index).absolute = absolute_drifts(drift_index);
  end
  ratio_1 = LOCAL_ratio_record(absolute_drifts(2), absolute_drifts(1));
  ratio_2 = LOCAL_ratio_record(absolute_drifts(3), absolute_drifts(2));
  prediction_residual = k_values(4) - k30_prediction;
  prediction_absolute_residual = abs(prediction_residual);
  late_bie_distance = abs(k_values(4) - k_bie_late);
  if any(~isfinite([prediction_residual, prediction_absolute_residual, ...
      late_bie_distance]))
    error('I4P:DIRECT_ARITHMETIC_UNAVAILABLE', ...
      'A direct comparison is nonfinite.');
  end

  % --- stage 2: run the seven fixed QR variable-projection starts ---
  start_p_values = [1 / 8, 1 / 4, 1 / 2, 1, 2, 4, 8];
  start_x_values = log(start_p_values);
  options = optimset('TolX', 1e-12, 'TolFun', 1e-24, ...
    'MaxIter', 10000, 'MaxFunEvals', 50000);
  fit_ledger = repmat(LOCAL_empty_fit_record(), 1, 7);
  for start_index = 1:7
    objective = @(x) LOCAL_objective(x, s_values, k_values);
    [endpoint_x, ~, exitflag] = fminsearch( ...
      objective, start_x_values(start_index), options);
    endpoint = LOCAL_fit_at_x(endpoint_x, s_values, k_values);
    endpoint.start_index = start_index;
    endpoint.x0 = start_x_values(start_index);
    endpoint.exitflag = exitflag;
    fit_ledger(start_index) = endpoint;
  end

  finite_indices = find([fit_ledger.finite_full_rank]);
  winner = LOCAL_empty_fit_record();
  winner_start_index = NaN;
  if isempty(finite_indices)
    fit_status = 'FIT_NUMERICALLY_UNRESOLVED';
  else
    rank_rows = [[fit_ledger(finite_indices).SSE].', ...
      [fit_ledger(finite_indices).p].', ...
      [fit_ledger(finite_indices).start_index].'];
    [~, order] = sortrows(rank_rows, [1, 2, 3]);
    winner_start_index = finite_indices(order(1));
    winner = fit_ledger(winner_start_index);
    if winner.exitflag > 0
      fit_status = 'FIT_RESOLVED';
    else
      fit_status = 'FIT_NUMERICALLY_UNRESOLVED';
    end
  end

  % --- stage 3: sanitize and publish the single RFC 8259 JSON ---
  payload = struct();
  payload.schema_version = 'i4a-candidate7-profile-v1';
  payload.profile_id = 'profile-001';
  payload.terminal = 'PROFILE_POSTPROCESS_COMPLETE';
  payload.candidate_context = struct( ...
    'old_candidate_id', 7, ...
    'new_identity_component_candidate_id', 9, ...
    'canonical_pure_fem_winner_candidate_id', 3, ...
    'identity_relation', 'CANDIDATE7_IDENTITY_COMPONENT_IS_NEW_CANDIDATE9', ...
    'canonical_selection_caveat', ...
    'CANONICAL_CANDIDATE3_DIFFERS_FROM_IDENTITY_COMPONENT_CANDIDATE9');
  payload.literal_inputs = struct('s', s_values, 'k', k_values, ...
    'k30_prediction', k30_prediction, 'k_bie_late', k_bie_late, ...
    'old_distance', old_distance);
  payload.drifts = drifts;
  payload.ratios = struct('rho_1', ratio_1, 'rho_2', ratio_2);
  payload.prediction = struct('residual', prediction_residual, ...
    'absolute_residual', prediction_absolute_residual);
  payload.fit = struct('model', 'k(s)=k_inf+C*s^(-p), p=exp(x)>0', ...
    'starts', fit_ledger, 'winner_start_index', winner_start_index, ...
    'winner', winner, 'fit_status', fit_status);
  payload.late_bie_comparison = struct( ...
    'absolute_distance', late_bie_distance, ...
    'old_distance', old_distance, ...
    'strictly_less_than_old_distance', late_bie_distance < old_distance);
  payload.certification_status = 'EMPIRICAL_NON_CERTIFIED';
  payload.effectivity_performed = false;

  encoded = jsonencode(payload, 'ConvertInfAndNaN', true);
  if contains(encoded, 'NaN') || contains(encoded, 'Infinity')
    error('I4P:JSON_SANITIZATION_FAILURE', ...
      'The JSON contains a non-RFC numeric token.');
  end
  source_dir = fileparts(mfilename('fullpath'));
  profile_path = fullfile(source_dir, 'output', 'run-008', ...
    'execution-001', 'review-audit', 'profile-001', 'profile.json');
  [file_id, message] = fopen(profile_path, 'w', 'n', 'UTF-8');
  if file_id < 0
    error('I4P:PROFILE_PUBLICATION_FAILURE', '%s', message);
  end
  try
    expected_count = numel(encoded) + 1;
    written_count = fwrite(file_id, [encoded, newline], 'char');
  catch caught
    fclose(file_id);
    rethrow(caught);
  end
  if written_count ~= expected_count || fclose(file_id) ~= 0
    error('I4P:PROFILE_PUBLICATION_FAILURE', ...
      'The profile JSON was not fully published.');
  end
end

%% ==================== Frozen scalar profile ====================
% These helpers implement design section 56.3 without acceptance thresholds.

function value = LOCAL_objective(x, s_values, k_values)
  endpoint = LOCAL_fit_at_x(x, s_values, k_values);
  if endpoint.finite_full_rank
    value = endpoint.SSE;
  else
    value = Inf;
  end
end

function record = LOCAL_fit_at_x(x, s_values, k_values)
  record = LOCAL_empty_fit_record();
  record.x = LOCAL_finite_or_nan(x);
  if ~isscalar(x) || ~isfinite(x)
    return;
  end
  p = exp(x);
  if ~isfinite(p) || p <= 0
    return;
  end
  design_matrix = [ones(numel(s_values), 1), s_values(:) .^ (-p)];
  if any(~isfinite(design_matrix), 'all')
    return;
  end
  [Q, R] = qr(design_matrix, 0);
  if any(~isfinite(R), 'all') || any(diag(R) == 0)
    return;
  end
  coefficients = R \ (Q' * k_values(:));
  residual = design_matrix * coefficients - k_values(:);
  SSE = sum(abs(residual) .^ 2);
  if any(~isfinite([coefficients; SSE]))
    return;
  end
  record.p = p;
  record.k_inf = coefficients(1);
  record.C = coefficients(2);
  record.SSE = SSE;
  record.finite_full_rank = true;
end

function record = LOCAL_empty_fit_record()
  record = struct('start_index', NaN, 'x0', NaN, 'x', NaN, ...
    'p', NaN, 'k_inf', NaN, 'C', NaN, 'SSE', NaN, ...
    'exitflag', NaN, 'finite_full_rank', false);
end

function value = LOCAL_finite_or_nan(value)
  if ~isscalar(value) || ~isfinite(value)
    value = NaN;
  end
end

function record = LOCAL_ratio_record(numerator, denominator)
  if denominator == 0
    record = struct('value', NaN, ...
      'status', 'UNDEFINED_ZERO_DENOMINATOR');
  else
    value = numerator / denominator;
    if ~isfinite(value)
      error('I4P:DIRECT_ARITHMETIC_UNAVAILABLE', ...
        'A finite ratio could not be formed.');
    end
    record = struct('value', value, 'status', 'DEFINED');
  end
end
