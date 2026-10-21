function export_frozen_binary64_v3(candidate_path, curve_path, export_dir)
%EXPORT_FROZEN_BINARY64_V3 Export exact binary64 inputs for Arb certification.
% Purpose:
%   Load the two explicit frozen MAT inputs and write selected doubles as raw
%   IEEE-754 binary64 payloads. No numerical transformation is performed.
% Input:
%   candidate_path - Explicit frozen I3 certificate MAT file.
%   curve_path - Explicit frozen circle-contract MAT file.
%   export_dir - New run-local directory for manifest.json and *.bin files.
% Output:
%   A JSON manifest and one little-endian real/complex payload per field.
% Main algorithm:
%   Validate the frozen schemas, preserve MATLAB column-major order, and write
%   real and imaginary arrays separately with fwrite(...,'double','ieee-le').
% Based on:
%   I6 v3 exact-input contract: each stored binary64 value is lifted by Arb as
%   an exact dyadic singleton before any certified operation.

assert(~isfolder(export_dir) && ~isfile(export_dir), ...
  'I6v3:CreateOnce', 'The export directory must be new.');
mkdir(export_dir);
candidate = load(candidate_path, 'staged');
curve_data = load(curve_path, 'curve_contract');
assert(isfield(candidate, 'staged') && ...
  isfield(candidate.staged, 'certificate'));
assert(isfield(curve_data, 'curve_contract'));
z = candidate.staged.certificate;
contract = curve_data.curve_contract;
% The frozen physical model has unit exterior density; export it as an
% explicit binary64 scientific input rather than leaving an implicit default.
z.rho_exterior = double(1);
required = {'khat','mu_h','beta','d','R','rho_disk','delta_c','delta_w', ...
  'X_L','X_R','L','M','K','q_center','Dplus','Dminus','Gplus','Gminus', ...
  'Pplus','Pminus','cplus','cminus','eta_unit_256','density_coordinate', ...
  'xi_left_unit_512','xi_right_unit_512','wall_input_unit_512', ...
  'wall_orders_512'};
assert(all(isfield(z, required)));
assert(strcmp(strtrim(char(z.density_coordinate)), ...
  '[tau;zeta], zeta=-sigma'));
assert(strcmp(char(contract.schema), 'TEP_I5_WALL_CURVE_CONTRACT_V1'));
assert(strcmp(char(contract.orientation), ...
  'counter-clockwise; outward normal=(dy_dt,-dx_dt)/speed'));
assert(strcmp(char(contract.node_rule), ...
  't_j=2*pi*j/N, j=0,...,N-1; no midpoint shift'));
assert(isequal(double(contract.adapter_metadata.center(:).'), [0, 0]));
assert(isequal(double(contract.adapter_metadata.radius), double(z.R)));
assert(isequal(double(contract.wall_left_x), double(z.X_L)) && ...
  isequal(double(contract.wall_right_x), double(z.X_R)));
names = {'khat','mu_h','beta','d','R','rho_disk','rho_exterior','delta_c','delta_w', ...
  'X_L','X_R','L','M','K','q_center','Dplus','Dminus','Gplus','Gminus', ...
  'Pplus','Pminus','cplus','cminus','eta_unit_256','xi_left_unit_512', ...
  'xi_right_unit_512','wall_input_unit_512','wall_orders_512'};
fields = struct;
for index = 1:numel(names)
  name = names{index};
  stored_value = z.(name);
  assert(isnumeric(stored_value) && ~issparse(stored_value), ...
    'I6v3:StoredType', 'Every exported scientific field must be dense numeric.');
  value = double(stored_value);
  if ~isa(stored_value, 'double')
    assert(isinteger(stored_value) && all(abs(value(:)) <= flintmax) && ...
      isequal(stored_value, cast(value, 'like', stored_value)), ...
      'I6v3:ExactIntegerLift', ...
      'The stored integer field must convert to binary64 without value loss.');
  end
  file_name = [name, '.bin'];
  file_path = fullfile(export_dir, file_name);
  fid = fopen(file_path, 'w', 'ieee-le');
  assert(fid >= 0);
  cleanup = onCleanup(@() fclose(fid));
  count_real = fwrite(fid, real(value(:)), 'double');
  assert(count_real == numel(value));
  if ~isreal(value)
    count_imag = fwrite(fid, imag(value(:)), 'double');
    assert(count_imag == numel(value));
  end
  clear cleanup;
  fields.(name) = struct('file', file_name, 'shape', size(value), ...
    'count', numel(value), 'complex', ~isreal(value), ...
    'stored_class', class(stored_value), ...
    'storage_order', 'MATLAB_COLUMN_MAJOR', ...
    'encoding', 'IEEE754_BINARY64_LITTLE_ENDIAN');
end
manifest = struct('schema', 'EPOST_I6_RESOLVENT_V3_BINARY64_INPUT', ...
  'fields', fields, 'curve_contract_pass', true, ...
  'density_coordinate', char(z.density_coordinate), ...
  'candidate_path_runtime', char(candidate_path), ...
  'curve_path_runtime', char(curve_path));
manifest_path = fullfile(export_dir, 'manifest.json');
fid = fopen(manifest_path, 'w');
assert(fid >= 0);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', jsonencode(manifest, 'PrettyPrint', true));
end
