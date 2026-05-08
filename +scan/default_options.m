function opts = default_options(varargin)
% DEFAULT_OPTIONS Build default options for scalar scan and refinement.
%
% Purpose:
%   Return a default option struct for one-dimensional scalar objective
%   sampling, dip selection, and interval refinement.
%
% Input:
%   varargin:
%     Optional name-value overrides, or one scalar struct whose fields
%     override the defaults.
%
% Output:
%   opts:
%     Struct containing scan and refinement options.
%
% Notes:
%   This routine is intentionally generic.  It does not know what the
%   objective represents; it only configures how real scalar x values are
%   sampled and refined.

  opts.min_refine_level = 1;
  opts.max_refine_level = 3;
  opts.num_initial_points = 21;
  opts.num_refine_points = 21;

  opts.dip_select = 'global_min';
  opts.dip_index = 1;
  opts.target_x = [];

  opts.include_endpoint_dips = true;
  opts.endpoint_interval_points = 2;

  opts.ignore_nan = true;
  opts.verbose = true;

  opts.stop_interval_width = [];
  opts.stop_rel_improvement = [];

  if nargin == 0
    return;
  end

  if nargin == 1 && isstruct(varargin{1})
    override = varargin{1};
    names = fieldnames(override);
    for j = 1:length(names)
      opts.(names{j}) = override.(names{j});
    end
    return;
  end

  if mod(nargin, 2) ~= 0
    error('scan:default_options:InvalidOverrides', ...
      'Overrides must be provided as name-value pairs or one struct.');
  end

  for j = 1:2:nargin
    name = varargin{j};
    value = varargin{j + 1};
    if isstring(name)
      if ~isscalar(name)
        error('scan:default_options:InvalidOptionName', ...
          'Option names must be character vectors or string scalars.');
      end
      name = char(name);
    end
    if ~(ischar(name) && isrow(name) && ~isempty(name))
      error('scan:default_options:InvalidOptionName', ...
        'Option names must be character vectors or string scalars.');
    end
    opts.(name) = value;
  end

end
