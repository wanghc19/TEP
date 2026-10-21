function digest = i32v2_trial_digest(data, expected)
%I32V2_TRIAL_DIGEST Compute a deterministic digest of frozen trial data.
% Purpose:
%   Detect accidental mutation of the numerical certificate between modules.
% Input:
%   data     - compact whitelisted certificate data.
%   expected - optional preregistered numerical digest.  A mismatch raises
%              a typed certificate-identity blocker.
% Output:
%   digest - lowercase hexadecimal numerical identity digest.
% Notes:
%   This function hashes only the explicit numerical input object. It never
%   reads source files, repository metadata, documentation, or manifests.

bytes = LOCAL_bytes(data);
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(bytes);
raw = typecast(md.digest(), 'uint8');
digest = lower(reshape(dec2hex(raw, 2).', 1, []));
if nargin >= 2
  if ~(ischar(expected) && numel(expected) == 64 && ...
      ~isempty(regexp(expected, '^[0-9a-f]{64}$', 'once')))
    error('I32V2:ExpectedDigestConfig', ...
      'The preregistered numerical trial digest is invalid.');
  end
  if ~strcmp(digest, expected)
    error('I32V2:CertificateNumericalIdentity', ...
      'The certificate numerical trial digest differs from the frozen identity.');
  end
end
end

%% ==================== Deterministic serialization ====================
% These helpers serialize supported MATLAB values without external files.

function bytes = LOCAL_bytes(value)
tag = uint8([class(value), '|']);
shape = typecast(uint64(size(value)), 'uint8');
if isstruct(value)
  names = sort(fieldnames(value));
  bytes = [tag(:); shape(:)];
  for k = 1:numel(value)
    for j = 1:numel(names)
      name_bytes = unicode2native(names{j}, 'UTF-8').';
      child = LOCAL_bytes(value(k).(names{j}));
      bytes = [bytes; typecast(uint64(numel(name_bytes)), 'uint8').'; ...
        name_bytes(:); typecast(uint64(numel(child)), 'uint8').'; child(:)]; %#ok<AGROW>
    end
  end
elseif iscell(value)
  bytes = [tag(:); shape(:)];
  for k = 1:numel(value)
    child = LOCAL_bytes(value{k});
    bytes = [bytes; typecast(uint64(numel(child)), 'uint8').'; child(:)]; %#ok<AGROW>
  end
elseif ischar(value)
  payload = typecast(uint16(value(:)), 'uint8');
  bytes = [tag(:); shape(:); payload(:)];
elseif isstring(value)
  bytes = LOCAL_bytes(cellstr(value));
elseif isnumeric(value) || islogical(value)
  if islogical(value)
    payload = uint8(value(:));
  else
    payload = [LOCAL_numeric_bytes(real(value)); LOCAL_numeric_bytes(imag(value))];
  end
  bytes = [tag(:); shape(:); payload(:)];
else
  error('I32V2:DigestUnsupportedClass', ...
    'Unsupported class in frozen trial digest: %s.', class(value));
end
bytes = uint8(bytes(:));
end

function bytes = LOCAL_numeric_bytes(value)
if isempty(value)
  bytes = uint8([]);
else
  bytes = typecast(value(:), 'uint8');
  bytes = bytes(:);
end
end
