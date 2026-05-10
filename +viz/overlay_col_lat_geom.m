function overlay_col_lat_geom(ax, plot_geom, opts)
% OVERLAY_COL_LAT_GEOM Overlay column-lattice geometry on axes.
%
% Purpose:
%   Draw obstacle boundaries and vertical cell lines from an existing
%   plot_geom struct returned by viz.build_col_lat_geom.  This function does
%   not construct geometry, mask field values, or draw field values.
%
% Input:
%   ax:
%     Target axes handle.  If [], the current axes gca is used.
%
%   plot_geom:
%     Struct returned by viz.build_col_lat_geom.  It must contain
%       plot_geom.window.xlim
%       plot_geom.window.ylim
%       plot_geom.cells
%       plot_geom.cell_lines.x.
%     Each nonempty cell instance is expected to contain
%       cells(k).instance.xy = [x_boundary(:), y_boundary(:)].
%
%   opts:
%     Optional drawing options:
%       opts.contour_line_spec   - Obstacle boundary line spec, default 'k-'.
%       opts.contour_line_width  - Obstacle boundary line width, default 0.75.
%       opts.cell_line_spec      - Cell boundary line spec, default 'k--'.
%       opts.cell_line_width     - Cell boundary line width, default 0.5.
%       opts.apply_axis_format   - Apply axis equal, limits, labels, and box.
%
% Output:
%   None.
%
% Notes:
%   The original hold state of ax is restored before returning.

  if nargin < 1 || isempty(ax)
    ax = gca;
  end
  if nargin < 3 || isempty(opts)
    opts = struct();
  end
  opts = LOCAL_default_opts(opts);
  LOCAL_validate_plot_geom(plot_geom);

  hold_was_on = ishold(ax);
  hold(ax, 'on');

  [cell_color, cell_style] = LOCAL_line_style_from_spec(opts.cell_line_spec);
  for j = 1:length(plot_geom.cell_lines.x)
    x = plot_geom.cell_lines.x(j);
    line(ax, [x, x], plot_geom.window.ylim, 'Color', cell_color, ...
      'LineStyle', cell_style, 'LineWidth', opts.cell_line_width);
  end

  [contour_color, contour_style] = LOCAL_line_style_from_spec( ...
    opts.contour_line_spec);
  for k = 1:length(plot_geom.cells)
    inst = plot_geom.cells(k).instance;
    if isempty(inst)
      continue;
    end
    line(ax, inst.xy(:, 1), inst.xy(:, 2), 'Color', contour_color, ...
      'LineStyle', contour_style, 'LineWidth', opts.contour_line_width);
  end

  if opts.apply_axis_format
    axis(ax, 'equal');
    xlim(ax, plot_geom.window.xlim);
    ylim(ax, plot_geom.window.ylim);
    xlabel(ax, 'x');
    ylabel(ax, 'y');
    box(ax, 'on');
  end

  if ~hold_was_on
    hold(ax, 'off');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function opts = LOCAL_default_opts(opts)
% LOCAL_DEFAULT_OPTS Fill missing overlay options.

  if ~isfield(opts, 'contour_line_spec') || isempty(opts.contour_line_spec)
    opts.contour_line_spec = 'k-';
  end
  if ~isfield(opts, 'contour_line_width') || isempty(opts.contour_line_width)
    opts.contour_line_width = 0.75;
  end
  if ~isfield(opts, 'cell_line_spec') || isempty(opts.cell_line_spec)
    opts.cell_line_spec = 'k--';
  end
  if ~isfield(opts, 'cell_line_width') || isempty(opts.cell_line_width)
    opts.cell_line_width = 0.5;
  end
  if ~isfield(opts, 'apply_axis_format') || isempty(opts.apply_axis_format)
    opts.apply_axis_format = true;
  end

  if ~(isscalar(opts.contour_line_width) && ...
      isfinite(opts.contour_line_width) && opts.contour_line_width >= 0)
    error('viz:overlay_col_lat_geom:InvalidLineWidth', ...
      'opts.contour_line_width must be a nonnegative finite scalar.');
  end
  if ~(isscalar(opts.cell_line_width) && ...
      isfinite(opts.cell_line_width) && opts.cell_line_width >= 0)
    error('viz:overlay_col_lat_geom:InvalidLineWidth', ...
      'opts.cell_line_width must be a nonnegative finite scalar.');
  end
  opts.apply_axis_format = logical(opts.apply_axis_format);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_validate_plot_geom(plot_geom)
% LOCAL_VALIDATE_PLOT_GEOM Check required plot_geom fields.

  if ~isstruct(plot_geom) || ~isfield(plot_geom, 'window') || ...
      ~isfield(plot_geom, 'cells') || ~isfield(plot_geom, 'cell_lines')
    error('viz:overlay_col_lat_geom:InvalidPlotGeom', ...
      'plot_geom must be returned by viz.build_col_lat_geom.');
  end
  if ~isfield(plot_geom.window, 'xlim') || ...
      ~isfield(plot_geom.window, 'ylim')
    error('viz:overlay_col_lat_geom:InvalidPlotGeom', ...
      'plot_geom.window must contain xlim and ylim.');
  end
  if ~isfield(plot_geom.cell_lines, 'x')
    error('viz:overlay_col_lat_geom:InvalidPlotGeom', ...
      'plot_geom.cell_lines.x is required.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [color, line_style] = LOCAL_line_style_from_spec(line_spec)
% LOCAL_LINE_STYLE_FROM_SPEC Parse a simple MATLAB line specification.

  if isstring(line_spec)
    line_spec = char(line_spec);
  end
  if ~(ischar(line_spec) && isrow(line_spec))
    error('viz:overlay_col_lat_geom:InvalidLineSpec', ...
      'Line specifications must be character vectors or strings.');
  end

  color = 'k';
  colors = 'ymcrgbwk';
  for j = 1:length(colors)
    if ~isempty(strfind(line_spec, colors(j))) %#ok<STREMP>
      color = colors(j);
      break;
    end
  end

  if ~isempty(strfind(line_spec, '--')) %#ok<STREMP>
    line_style = '--';
  elseif ~isempty(strfind(line_spec, '-.')) %#ok<STREMP>
    line_style = '-.';
  elseif ~isempty(strfind(line_spec, ':')) %#ok<STREMP>
    line_style = ':';
  elseif ~isempty(strfind(line_spec, '-')) %#ok<STREMP>
    line_style = '-';
  else
    line_style = '-';
  end

end
