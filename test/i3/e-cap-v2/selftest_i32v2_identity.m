function result = selftest_i32v2_identity(certificate_path)
%SELFTEST_I32V2_IDENTITY Reject a same-shape numerical certificate mutation.
% Purpose:
%   Verify that the preregistered numerical digest blocks a finite, same-shape
%   single-value change before any scientific module can consume the trial.
% Input:
%   certificate_path - Explicit frozen fbie-a1 certificate MAT file.
% Output:
%   result - Compact negative-test record.  No files are written.
% Notes:
%   This test mutates only an in-memory copy of the whitelisted certificate.

cfg = i32v2_config();
cert = i32v2_certificate_input(certificate_path, cfg);
if ~cert.available
  error('I32V2:IdentitySelftestInput', '%s', cert.first_blocker);
end

mutated = cert.data;
value = mutated.certificate.q_center(1);
mutated.certificate.q_center(1) = value + 1e-12 * max(1, abs(value));
blocked = false;
blocker = '';
try
  i32v2_trial_digest(mutated, cfg.identity.expected_trial_digest);
catch err
  blocker = err.identifier;
  blocked = strcmp(blocker, 'I32V2:CertificateNumericalIdentity');
end
if ~blocked
  error('I32V2:IdentitySelftestFailed', ...
    'A same-shape single-value certificate mutation was not typed-blocked.');
end

result = struct('status', 'PASS', 'valid_identity_match', ...
  cert.audit.expected_identity_match, 'mutation_shape_unchanged', ...
  isequal(size(mutated.certificate.q_center), ...
  size(cert.data.certificate.q_center)), 'mutation_finite', ...
  all(isfinite(mutated.certificate.q_center)), ...
  'typed_blocker', blocker, 'scientific_modules_called', 0, ...
  'formal_attempt_created', false);
end
