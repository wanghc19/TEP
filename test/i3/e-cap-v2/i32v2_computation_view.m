function [view, audit] = i32v2_computation_view(raw, cfg)
%I32V2_COMPUTATION_VIEW Build the authenticated double computation view.
% Purpose:
%   Convert every numeric leaf of the whitelisted frozen certificate to
%   double without changing its value, shape, ordering, or container.
% Input:
%   raw - whitelisted i32v2_certificate_input return.data.
%   cfg - preregistered configuration containing the independent expected
%         canonical digest literal.
% Output:
%   view  - authenticated computation view consumed by scientific modules.
%   audit - compact raw/canonical leaf-equivalence and identity record.
% Main algorithm:
%   Recursively preserve struct/cell topology and nonnumeric leaves, apply
%   only double(raw_leaf) to numeric leaves, verify every leaf immediately,
%   then bind the canonical digest and leaf audit into the module stamp.
% Based on:
%   design-3-2d section 12.4 canonical computation-view contract.
% Notes:
%   This function reads no path, source file, documentation, or Git state.

if ~isstruct(raw) || ~isscalar(raw)
  error('I32V2:ComputationViewRawSchema', ...
    'The whitelisted raw certificate data must be a scalar struct.');
end
if ~isstruct(cfg) || ~isfield(cfg, 'identity') || ...
    ~isfield(cfg.identity, 'expected_canonical_digest')
  error('I32V2:ExpectedCanonicalDigestConfig', ...
    'The preregistered canonical digest literal is unavailable.');
end
expected_digest = cfg.identity.expected_canonical_digest;
LOCAL_validate_digest_literal(expected_digest);

raw_digest_before = i32v2_trial_digest(raw);
[canonical, leaf_audit] = LOCAL_canonicalize(raw);
raw_digest_after = i32v2_trial_digest(raw);
if ~strcmp(raw_digest_before, raw_digest_after)
  error('I32V2:RawCertificateMutation', ...
    'The raw whitelisted certificate changed during canonicalization.');
end
if ~leaf_audit.equivalent
  error('I32V2:CanonicalLeafMismatch', ...
    'A canonical leaf is not exactly double(raw) or unchanged nonnumeric data.');
end

canonical_digest = i32v2_trial_digest(canonical, expected_digest);
view_schema = 'I32V2_COMPUTATION_VIEW_V1';
authentication = struct( ...
  'schema', 'I32V2_COMPUTATION_VIEW_AUTH_V1', ...
  'view_schema', view_schema, ...
  'canonical_digest', canonical_digest, ...
  'expected_canonical_digest', expected_digest, ...
  'numeric_leaf_count', leaf_audit.numeric_leaf_count, ...
  'converted_numeric_leaf_count', leaf_audit.converted_numeric_leaf_count, ...
  'logical_leaf_count', leaf_audit.logical_leaf_count, ...
  'nonnumeric_leaf_count', leaf_audit.nonnumeric_leaf_count, ...
  'leaf_equivalence_pass', leaf_audit.equivalent, ...
  'raw_unchanged_pass', true);
authentication.stamp_digest = i32v2_trial_digest(authentication);

view = struct('schema', view_schema, 'data', canonical, ...
  'authentication', authentication);
audit = struct( ...
  'schema', 'I32V2_COMPUTATION_VIEW_AUDIT_V1', ...
  'raw_digest_before', raw_digest_before, ...
  'raw_digest_after', raw_digest_after, ...
  'raw_unchanged', true, ...
  'canonical_digest', canonical_digest, ...
  'expected_canonical_digest', expected_digest, ...
  'expected_canonical_match', true, ...
  'numeric_leaf_count', leaf_audit.numeric_leaf_count, ...
  'converted_numeric_leaf_count', leaf_audit.converted_numeric_leaf_count, ...
  'logical_leaf_count', leaf_audit.logical_leaf_count, ...
  'nonnumeric_leaf_count', leaf_audit.nonnumeric_leaf_count, ...
  'leaf_equivalence_pass', leaf_audit.equivalent, ...
  'authenticated_stamp_digest', authentication.stamp_digest, ...
  'symbol_ledger', struct( ...
  'canonical', 'recursive numeric-to-double computation data', ...
  'canonical_digest', 'independent expected identity of canonical data', ...
  'authentication', 'schema/digest/leaf-audit-bound module stamp'));
end

%% ==================== Recursive leaf conversion ====================
% The recursion performs no scientific arithmetic or semantic transformation.

function [canonical, audit] = LOCAL_canonicalize(raw)
audit = LOCAL_leaf_audit();
if isstruct(raw)
  canonical = raw;
  names = fieldnames(raw);
  for k = 1:numel(raw)
    for j = 1:numel(names)
      [canonical(k).(names{j}), child] = ...
        LOCAL_canonicalize(raw(k).(names{j}));
      audit = LOCAL_add_audit(audit, child);
    end
  end
  audit.equivalent = audit.equivalent && ...
    isequal(size(canonical), size(raw)) && ...
    isequal(fieldnames(canonical), fieldnames(raw));
elseif iscell(raw)
  canonical = raw;
  for k = 1:numel(raw)
    [canonical{k}, child] = LOCAL_canonicalize(raw{k});
    audit = LOCAL_add_audit(audit, child);
  end
  audit.equivalent = audit.equivalent && isequal(size(canonical), size(raw));
elseif isnumeric(raw)
  canonical = double(raw);
  audit.numeric_leaf_count = 1.0;
  audit.converted_numeric_leaf_count = double(~isa(raw, 'double'));
  audit.equivalent = isequal(size(canonical), size(raw)) && ...
    isequaln(canonical, double(raw));
elseif islogical(raw)
  canonical = raw;
  audit.logical_leaf_count = 1.0;
  audit.equivalent = isequaln(canonical, raw);
elseif ischar(raw) || isstring(raw)
  canonical = raw;
  audit.nonnumeric_leaf_count = 1.0;
  audit.equivalent = strcmp(class(canonical), class(raw)) && ...
    isequal(size(canonical), size(raw)) && isequaln(canonical, raw);
else
  error('I32V2:CanonicalUnsupportedClass', ...
    'Unsupported whitelisted leaf class: %s.', class(raw));
end
end

function audit = LOCAL_leaf_audit()
audit = struct('numeric_leaf_count', 0.0, ...
  'converted_numeric_leaf_count', 0.0, 'logical_leaf_count', 0.0, ...
  'nonnumeric_leaf_count', 0.0, 'equivalent', true);
end

function total = LOCAL_add_audit(total, child)
total.numeric_leaf_count = total.numeric_leaf_count + child.numeric_leaf_count;
total.converted_numeric_leaf_count = total.converted_numeric_leaf_count + ...
  child.converted_numeric_leaf_count;
total.logical_leaf_count = total.logical_leaf_count + child.logical_leaf_count;
total.nonnumeric_leaf_count = total.nonnumeric_leaf_count + ...
  child.nonnumeric_leaf_count;
total.equivalent = total.equivalent && child.equivalent;
end

function LOCAL_validate_digest_literal(value)
if ~(ischar(value) && numel(value) == 64 && ...
    ~isempty(regexp(value, '^[0-9a-f]{64}$', 'once')))
  error('I32V2:ExpectedCanonicalDigestConfig', ...
    'The expected canonical digest must be a lowercase SHA-256 literal.');
end
end
