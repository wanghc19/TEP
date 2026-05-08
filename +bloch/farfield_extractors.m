function [F_L, F_R, aux] = farfield_extractors(geom, rayleighchan, X_L, X_R, curvelen)
% Purpose:
%   Construct Rayleigh far-field extraction matrices for the scattered field
%   of one periodic cell.  The BIE density is
%
%     eta = [tau; -sigma] = [tau; mu],
%
%   and the outgoing Rayleigh coefficients are extracted by
%
%     s_L = F_L eta,
%     s_R = F_R eta.
%
% Inputs:
%   geom:
%     Boundary data compatible with geom.construct_cont.  The primary format
%     is the 6-by-N C matrix with x = C(1,:), x_t = C(2,:), y = C(4,:),
%     y_t = C(5,:).  For counter-clockwise parameterization the outward unit
%     normal is nx = y_t/speed, ny = -x_t/speed.
%   rayleighchan:
%     Struct containing beta_m, gamma_m, d, and K.
%   X_L, X_R:
%     x-coordinates of the left and right vertical walls of the cell.  They
%     are phase origins only.
%   curvelen:
%     Boundary parameter interval length.  With N boundary nodes,
%     h = curvelen/N and w_j = h*speed_j.
%
% Outputs:
%   F_L, F_R:
%     K-by-2N complex double matrices.  They map eta = [tau; -sigma] to the
%     scattered outgoing coefficients on the left and right walls.  They do
%     not include the direct phase contribution exp(1i*gamma_m*(X_R-X_L)).
%   aux:
%     Debug struct containing g_L, g_R, dgdn_L, dgdn_R, weights, x, y, nx, ny.
%
% Notes:
%   For z_j = (x_j,y_j), nu_j = (nu_x,j,nu_y,j),
%
%     g_L(m,j) =
%       1i/(2*sqrt(d)*gamma_m)
%       * exp(-1i*beta_m*y_j + 1i*gamma_m*(x_j - X_L)),
%
%     g_R(m,j) =
%       1i/(2*sqrt(d)*gamma_m)
%       * exp(-1i*beta_m*y_j - 1i*gamma_m*(x_j - X_R)).
%
%   The code variables dgdn_L and dgdn_R correspond to A_m^L and A_m^R in
%   note_Bloch_mode.md: they are double-layer source-normal derivative
%   coefficients, not the adjoint double-layer operator D*:
%
%     dgdn_L(m,j) =
%       1i*(gamma_m*nu_x,j - beta_m*nu_y,j)*g_L(m,j),
%
%     dgdn_R(m,j) =
%       -1i*(gamma_m*nu_x,j + beta_m*nu_y,j)*g_R(m,j).
%
%   With trapezoid weights w_j = h*speed_j,
%
%     F_L = [w*dgdn_L, -w*g_L],
%     F_R = [w*dgdn_R, -w*g_R].

  if ~(isstruct(rayleighchan) && isfield(rayleighchan, 'beta_m') && ...
      isfield(rayleighchan, 'gamma_m') && isfield(rayleighchan, 'd') && ...
      isfield(rayleighchan, 'K'))
    error('farfield_extractors:InvalidRayleighChannels', ...
      'rayleighchan must contain beta_m, gamma_m, d, and K.');
  end
  if ~(isscalar(X_L) && isfinite(X_L))
    error('farfield_extractors:InvalidLeftOrigin', ...
      'X_L must be a finite scalar.');
  end
  if ~(isscalar(X_R) && isfinite(X_R))
    error('farfield_extractors:InvalidRightOrigin', ...
      'X_R must be a finite scalar.');
  end
  if ~(isscalar(curvelen) && isfinite(curvelen) && curvelen ~= 0)
    error('farfield_extractors:InvalidCurveLength', ...
      'curvelen must be a nonzero finite scalar.');
  end
  if ~(isscalar(rayleighchan.d) && isfinite(rayleighchan.d) && rayleighchan.d ~= 0)
    error('farfield_extractors:InvalidPeriod', ...
      'rayleighchan.d must be a nonzero finite scalar.');
  end
  if ~(isscalar(rayleighchan.K) && isfinite(rayleighchan.K) && ...
      rayleighchan.K >= 0 && rayleighchan.K == floor(rayleighchan.K))
    error('farfield_extractors:InvalidChannelCount', ...
      'rayleighchan.K must be a nonnegative integer scalar.');
  end

  [x, y, nx, ny, speed] = LOCAL_extract_boundary_data(geom);
  N = length(x);
  K = rayleighchan.K;
  beta_m = rayleighchan.beta_m(:);
  gamma_m = rayleighchan.gamma_m(:);

  if length(beta_m) ~= K || length(gamma_m) ~= K
    error('farfield_extractors:ChannelSizeMismatch', ...
      'beta_m and gamma_m must have length rayleighchan.K.');
  end
  if any(~isfinite(beta_m)) || any(~isfinite(gamma_m))
    error('farfield_extractors:InvalidChannelValues', ...
      'beta_m and gamma_m must contain only finite values.');
  end
  if any(abs(gamma_m) < 1e-12)
    warning('farfield_extractors:WoodAnomaly', ...
      'At least one gamma_m is close to zero; Rayleigh extraction may be singular.');
  end

  g_scale = 1i ./ (2 * sqrt(rayleighchan.d) * gamma_m);
  g_L = bsxfun(@times, g_scale, ...
    exp(-1i * (beta_m * y.') + 1i * (gamma_m * (x - X_L).')));
  g_R = bsxfun(@times, g_scale, ...
    exp(-1i * (beta_m * y.') - 1i * (gamma_m * (x - X_R).')));

  dgdn_L = 1i * (gamma_m * nx.' - beta_m * ny.') .* g_L;
  dgdn_R = -1i * (gamma_m * nx.' + beta_m * ny.') .* g_R;

  h = curvelen / N;
  weights = h * speed;
  F_L_tau = bsxfun(@times, dgdn_L, weights.');
  F_L_mu = -bsxfun(@times, g_L, weights.');
  F_R_tau = bsxfun(@times, dgdn_R, weights.');
  F_R_mu = -bsxfun(@times, g_R, weights.');

  F_L = full(complex([F_L_tau, F_L_mu]));
  F_R = full(complex([F_R_tau, F_R_mu]));

  if ~isequal(size(F_L), [K, 2 * N]) || ~isequal(size(F_R), [K, 2 * N])
    error('farfield_extractors:OutputSizeMismatch', ...
      'F_L and F_R must have size K-by-2N.');
  end

  aux.g_L = g_L;
  aux.g_R = g_R;
  aux.dgdn_L = dgdn_L;
  aux.dgdn_R = dgdn_R;
  aux.weights = weights;
  aux.x = x;
  aux.y = y;
  aux.nx = nx;
  aux.ny = ny;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [x, y, nx, ny, speed] = LOCAL_extract_boundary_data(geom)

  if isnumeric(geom)
    if ~(ismatrix(geom) && size(geom, 1) >= 6 && size(geom, 2) >= 1)
      error('farfield_extractors:InvalidGeometryMatrix', ...
        'Numeric geom must be the 6-by-N construct_cont boundary matrix.');
    end

    x = geom(1, :).';
    y = geom(4, :).';
    dxdt = geom(2, :).';
    dydt = geom(5, :).';
    speed = sqrt(dxdt.^2 + dydt.^2);
    if any(~isfinite(speed)) || any(speed == 0)
      error('farfield_extractors:InvalidGeometrySpeed', ...
        'Boundary tangent speed must be finite and nonzero at every node.');
    end

    nx = dydt ./ speed;
    ny = -dxdt ./ speed;
  elseif isstruct(geom)
    if ~(isfield(geom, 'x') && isfield(geom, 'y'))
      error('farfield_extractors:InvalidGeometryStruct', ...
        'Struct geom must contain x and y fields.');
    end

    x = geom.x(:);
    y = geom.y(:);

    if isfield(geom, 'speed')
      speed = geom.speed(:);
    elseif isfield(geom, 's')
      speed = geom.s(:);
    elseif isfield(geom, 'dxdt') && isfield(geom, 'dydt')
      dxdt = geom.dxdt(:);
      dydt = geom.dydt(:);
      speed = sqrt(dxdt.^2 + dydt.^2);
    elseif isfield(geom, 'xt') && isfield(geom, 'yt')
      dxdt = geom.xt(:);
      dydt = geom.yt(:);
      speed = sqrt(dxdt.^2 + dydt.^2);
    else
      error('farfield_extractors:MissingGeometrySpeed', ...
        'Struct geom must provide speed/s or tangent derivative fields.');
    end

    if isfield(geom, 'nx') && isfield(geom, 'ny')
      nx = geom.nx(:);
      ny = geom.ny(:);
    elseif exist('dxdt', 'var') && exist('dydt', 'var')
      nx = dydt ./ speed;
      ny = -dxdt ./ speed;
    else
      error('farfield_extractors:MissingGeometryNormal', ...
        'Struct geom must provide nx,ny or tangent derivative fields.');
    end
  else
    error('farfield_extractors:InvalidGeometry', ...
      'geom must be a construct_cont matrix or a boundary data struct.');
  end

  N = length(x);
  if length(y) ~= N || length(nx) ~= N || length(ny) ~= N || length(speed) ~= N
    error('farfield_extractors:GeometrySizeMismatch', ...
      'x, y, nx, ny, and speed must have the same number of boundary nodes.');
  end
  if any(~isfinite(x)) || any(~isfinite(y)) || any(~isfinite(nx)) || ...
      any(~isfinite(ny)) || any(~isfinite(speed)) || any(speed == 0)
    error('farfield_extractors:InvalidGeometryValues', ...
      'Boundary coordinates, normals, and speed must be finite; speed must be nonzero.');
  end

end
