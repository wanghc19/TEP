function [C, curvelen, xxint, xxext] = construct_cont(ntot, flag_geom, nint, next, varargin)
% CONSTRUCT_CONT Build the TEP contour and optional interior/exterior points.
%
% Purpose:
%   Constructs the common contour matrix used by the TEP scripts for either
%   the star-shaped or circular/ellipse geometry.
%
% Input:
%   ntot      - Number of periodic contour samples.
%   flag_geom - Geometry selector; supported values are 'star', 'ellipse',
%               and 'circle'.
%   nint      - Number of random interior sample points to generate.
%   next      - Number of random exterior sample points to generate.
%   varargin  - Optional geometry parameters. For flag_geom = 'circle',
%               varargin{1} may specify the radius a; the default is a = 1.
%               For flag_geom = 'ellipse', either varargin{1} = [a,b] or
%               varargin{1} = a, varargin{2} = b may specify the x/y
%               semi-axes. The default is a = b = 0.4.
%
% Output:
%   C        - 6-by-ntot contour array containing position and derivatives:
%              rows 1/4 are x/y, 2/5 are first derivatives, 3/6 are second
%              derivatives with respect to the periodic parameter.
%   curvelen - Parameter interval length used for trapezoid spacing.
%   xxint    - 2-by-nint random interior sample points.
%   xxext    - 2-by-next random exterior sample points.
%
% Notes:
%   This is the common TEP implementation. It intentionally does not merge
%   the CFIE-specific contour variant, which uses a different interface and
%   scaling.

  if strcmp(flag_geom, 'star')
    r = 0.3;
    k = 5;
    tt = linspace(0, 2 * pi * (1 - 1 / ntot), ntot);
    C = zeros(6, ntot);
    C(1,:) =   1.5 * cos(tt) + (r / 2) *            cos((k + 1) * tt) + (r / 2) *            cos((k - 1) * tt);
    C(2,:) = - 1.5 * sin(tt) - (r / 2) * (k + 1) * sin((k + 1) * tt) - (r / 2) * (k - 1) * sin((k - 1) * tt);
    C(3,:) = - 1.5 * cos(tt) - (r / 2) * (k + 1) * (k + 1) * cos((k + 1) * tt) - (r / 2) * (k - 1) * (k - 1) * cos((k - 1) * tt);
    C(4,:) =       sin(tt) + (r / 2) *            sin((k + 1) * tt) - (r / 2) *            sin((k - 1) * tt);
    C(5,:) =       cos(tt) + (r / 2) * (k + 1) * cos((k + 1) * tt) - (r / 2) * (k - 1) * cos((k - 1) * tt);
    C(6,:) = -     sin(tt) - (r / 2) * (k + 1) * (k + 1) * sin((k + 1) * tt) + (r / 2) * (k - 1) * (k - 1) * sin((k - 1) * tt);
    C = C .* 0.2;
    curvelen = 2 * pi;
    rmin = sqrt(min(C(1,:).^2 + C(4,:).^2));
    rmax = sqrt(max(C(1,:).^2 + C(4,:).^2));
    ttint = 2 * pi * rand(1, nint);
    xxint = 0.6 * [rmin * cos(ttint); rmin * sin(ttint)];
    ttext = 2 * pi * rand(1, next);
    xxext = 1.6 * [rmax * cos(ttext); rmax * sin(ttext)];
  elseif strcmp(flag_geom, 'ellipse')
    [a, b] = LOCAL_parse_ellipse_axes(varargin{:});
    tt = linspace(0, 2 * pi * (1 - 1 / ntot), ntot);
    C = zeros(6, ntot);
    C(1,:) =  a * cos(tt);
    C(2,:) = -a * sin(tt);
    C(3,:) = -a * cos(tt);
    C(4,:) =  b * sin(tt);
    C(5,:) =  b * cos(tt);
    C(6,:) = -b * sin(tt);
    curvelen = 2 * pi;

    rmin = sqrt(min(C(1,:).^2 + C(4,:).^2));
    rmax = sqrt(max(C(1,:).^2 + C(4,:).^2));
    ttint = 2 * pi * rand(1, nint);
    xxint = 0.6 * [rmin * cos(ttint); rmin * sin(ttint)];
    ttext = 2 * pi * rand(1, next);
    xxext = 1.4 * [rmax * cos(ttext); rmax * sin(ttext)];
  elseif strcmp(flag_geom, 'circle')
    a = 1.0;
    if ~isempty(varargin)
      a = varargin{1};
      if ~isscalar(a) || ~isnumeric(a) || ~isreal(a) || ~isfinite(a) || a <= 0
        error('geom:construct_cont:InvalidCircleRadius', ...
          'Circle radius must be a positive real scalar.');
      end
    end

    tt = linspace(0, 2 * pi * (1 - 1 / ntot), ntot);
    C = zeros(6, ntot);
    C(1,:) =  a * cos(tt);
    C(2,:) = -a * sin(tt);
    C(3,:) = -a * cos(tt);
    C(4,:) =  a * sin(tt);
    C(5,:) =  a * cos(tt);
    C(6,:) = -a * sin(tt);
    curvelen = 2 * pi;

    ttint = 2 * pi * rand(1, nint);
    xxint = 0.6 * a * [cos(ttint); sin(ttint)];
    ttext = 2 * pi * rand(1, next);
    xxext = 1.4 * a * [cos(ttext); sin(ttext)];
  else
    error('This option for the geometry is not implemented.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [a, b] = LOCAL_parse_ellipse_axes(varargin)
% LOCAL_PARSE_ELLIPSE_AXES Parse optional ellipse x/y semi-axes.

  a = 0.4;
  b = 0.4;
  if isempty(varargin)
    return;
  end

  if length(varargin) == 1
    axes_val = varargin{1};
    if isnumeric(axes_val) && isreal(axes_val) && numel(axes_val) == 2
      axes_val = axes_val(:);
      a = axes_val(1);
      b = axes_val(2);
    else
      error('geom:construct_cont:InvalidEllipseAxes', ...
        'Ellipse axes must be positive real scalars a,b or a two-entry vector [a,b].');
    end
  else
    a = varargin{1};
    b = varargin{2};
  end

  if ~isscalar(a) || ~isnumeric(a) || ~isreal(a) || ~isfinite(a) || a <= 0 || ...
      ~isscalar(b) || ~isnumeric(b) || ~isreal(b) || ~isfinite(b) || b <= 0
    error('geom:construct_cont:InvalidEllipseAxes', ...
      'Ellipse axes must be positive real scalars a and b.');
  end

end
