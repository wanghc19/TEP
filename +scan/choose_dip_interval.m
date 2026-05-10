function [dip, dip_idx] = choose_dip_interval(dips, opts)
% CHOOSE_DIP_INTERVAL Choose one dip candidate for refinement.
%
% Purpose:
%   Select a single dip from the candidates returned by
%   scan.find_dip_intervals according to the configured selection rule.
%
% Input:
%   dips:
%     Struct array of dip candidates.
%   opts:
%     Optional scan options.  Supported selection fields are dip_select,
%     dip_index, and target_x.
%
% Output:
%   dip:
%     The selected dip struct.
%   dip_idx:
%     Index of the selected dip inside dips.
%
% Notes:
%   This function only chooses among candidate intervals.  It does not sample
%   new points and does not perform refinement.

  if nargin < 2 || isempty(opts)
    opts = scan.default_options();
  end
  if isempty(dips)
    error('scan:choose_dip_interval:NoDips', ...
      'No dip candidates are available.');
  end

  mode = 'global_min';
  if isfield(opts, 'dip_select') && ~isempty(opts.dip_select)
    mode = opts.dip_select;
  end
  if isstring(mode)
    if ~isscalar(mode)
      error('scan:choose_dip_interval:InvalidDipSelect', ...
        'opts.dip_select must be a character vector or string scalar.');
    end
    mode = char(mode);
  end

  switch mode
    case 'global_min'
      values = [dips.value_center];
      [~, dip_idx] = min(values);
    case 'index'
      dip_idx = opts.dip_index;
      if isempty(dip_idx) || dip_idx ~= floor(dip_idx) || dip_idx < 1 || ...
          dip_idx > length(dips)
        error('scan:choose_dip_interval:InvalidDipIndex', ...
          'opts.dip_index must be a valid dip index.');
      end
    case 'nearest'
      if ~isfield(opts, 'target_x') || isempty(opts.target_x) || ...
          ~isscalar(opts.target_x) || ~isfinite(opts.target_x)
        error('scan:choose_dip_interval:InvalidTargetX', ...
          'opts.target_x must be a finite scalar for nearest dip selection.');
      end
      distances = abs([dips.x_center] - opts.target_x);
      [~, dip_idx] = min(distances);
    otherwise
      error('scan:choose_dip_interval:InvalidDipSelect', ...
        'Unsupported opts.dip_select value: %s.', mode);
  end

  dip = dips(dip_idx);

end
