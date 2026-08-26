function audit = i32v2_return_audit(value, allowed_paths)
%I32V2_RETURN_AUDIT Recursively audit compact module ownership.
% Purpose:
%   Record returned struct/cell fields and detect forbidden retained dense
%   maps after each declared module death point.
% Input:
%   value         - module return or collection of live module returns.
%   allowed_paths - exact field paths exempted by the design registry.
% Output:
%   audit - compact entries, retained bytes, forbidden paths, and pass flag.

if nargin < 2
  allowed_paths = {};
end
entries = struct('path', {}, 'class', {}, 'size', {}, 'bytes', {});
forbidden = {};
[entries, forbidden] = LOCAL_walk(value, 'root', entries, forbidden, allowed_paths);
if isempty(entries)
  retained_bytes = 0;
else
  retained_bytes = sum([entries.bytes]);
end
audit.entries = entries;
audit.retained_bytes = retained_bytes;
audit.forbidden_paths = forbidden;
audit.pass = isempty(forbidden);
end

%% ==================== Recursive ownership walk ====================
% The walk records leaf values and rejects unregistered dense-map names.

function [entries, forbidden] = LOCAL_walk(value, path, entries, forbidden, allowed)
if isstruct(value)
  names = fieldnames(value);
  for k = 1:numel(value)
    for j = 1:numel(names)
      child_path = sprintf('%s.%s', path, names{j});
      if numel(value) > 1
        child_path = sprintf('%s(%d).%s', path, k, names{j});
      end
      [entries, forbidden] = LOCAL_walk(value(k).(names{j}), child_path, ...
        entries, forbidden, allowed);
    end
  end
elseif iscell(value)
  for k = 1:numel(value)
    child_path = sprintf('%s{%d}', path, k);
    [entries, forbidden] = LOCAL_walk(value{k}, child_path, entries, ...
      forbidden, allowed);
  end
else
  leaf = value; %#ok<NASGU>
  info = whos('leaf');
  row.path = path;
  row.class = class(value);
  row.size = size(value);
  row.bytes = info.bytes;
  entries(end + 1) = row;
  lower_path = lower(path);
  bad_tokens = {'pair', 'kernel_matrix', 'raw_samples', 'coarse', ...
    'workspace', 'raw_maps'};
  is_bad = false;
  for j = 1:numel(bad_tokens)
    is_bad = is_bad || contains(lower_path, bad_tokens{j});
  end
  if is_bad && ~any(strcmp(path, allowed))
    forbidden{end + 1} = path;
  end
  if isnumeric(value) && LOCAL_shape_exceeds_registry(path, size(value)) && ...
      ~any(strcmp(path, allowed))
    forbidden{end + 1} = [path, ':SHAPE'];
  end
end
end

function exceeds = LOCAL_shape_exceeds_registry(path, shape)
% The registry mirrors the literal maximum retained shapes in design-3-2d.
lower_path = lower(path);
limits = [];
if contains(lower_path, 'production_n65')
  limits = [65, 65, 6];
elseif contains(lower_path, 'production_n129')
  limits = [129, 129, 6];
elseif contains(lower_path, 'production_n257')
  limits = [257, 257, 6];
elseif contains(lower_path, 'variant_delta_n129')
  limits = [129, 129, 6, 5];
elseif contains(lower_path, 'circle') && contains(lower_path, '.finest.') && ...
    (contains(lower_path, 'normal_') || contains(lower_path, 'value_'))
  limits = [2048, 97];
elseif contains(lower_path, 'wall') && contains(lower_path, '.finest.') && ...
    (contains(lower_path, 'internal_') || contains(lower_path, 'value_'))
  limits = [4096, 97];
elseif contains(lower_path, 'wall') && contains(lower_path, ...
    'center_first_')
  limits = [4096, 1];
elseif contains(lower_path, 'lifting') && contains(lower_path, '.finest.') && ...
    contains(lower_path, 'volume_')
  limits = [10240, 97];
elseif contains(lower_path, 'lifting') && contains(lower_path, '.finest.') && ...
    contains(lower_path, 'singleton')
  limits = [16384, 1];
end
if isempty(limits)
  exceeds = false;
  return
end
shape = double(shape(:).');
limits = [limits, ones(1, max(0, numel(shape) - numel(limits)))];
shape = [shape, ones(1, max(0, numel(limits) - numel(shape)))];
exceeds = any(shape > limits);
end
