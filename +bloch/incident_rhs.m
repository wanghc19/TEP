function [B_L, B_R] = incident_rhs(geom, rayleighchan, X_L, X_R)
% Purpose:
%   Construct Cauchy data right-hand sides for left- and right-incident
%   Rayleigh channels on the dielectric inclusion boundary.  The matrices
%   are intended for the scattering BIE problem A_QP * eta = -B_inc.
%   This routine only evaluates explicit incident-field formulas; it does
%   not call BIE assembly, construct A_QP, or solve a linear system.
%
% Inputs:
%   geom:
%     Boundary geometry in the format returned by geom.construct_cont, namely
%     a 6-by-N matrix with x = geom(1,:), y = geom(4,:), dx/dt = geom(2,:),
%     and dy/dt = geom(5,:).  The outward unit normal is computed as
%     nu = (dy/dt, -dx/dt)/sqrt((dx/dt)^2 + (dy/dt)^2), matching the
%     existing Muller assembly convention.  A struct with fields x, y, nx,
%     and ny is also accepted, in which case nx,ny are used as unit normals.
%   rayleighchan:
%     Struct from bloch.rayleigh_channels containing beta_m, gamma_m, d, K.
%   X_L, X_R:
%     x-coordinates of the left and right vertical walls of one cell.  They
%     are used only as phase origins and do not identify left/right lead type.
%
% Outputs:
%   B_L, B_R:
%     Full complex double matrices of size 2N-by-K.  The first N rows are
%     Dirichlet traces and the last N rows are outward Neumann traces.
%
% Formulas:
%   For psi_m(y) = 1/sqrt(d) * exp(1i*beta_m*y),
%
%     u_m^{L,inc}(x,y) = exp( 1i*gamma_m*(x - X_L)) * psi_m(y),
%     u_m^{R,inc}(x,y) = exp(-1i*gamma_m*(x - X_R)) * psi_m(y),
%
%   and, with outward unit normal nu = (nu_x, nu_y),
%
%     d_nu u_m^{L,inc}
%       = 1i*( gamma_m*nu_x + beta_m*nu_y) * u_m^{L,inc},
%     d_nu u_m^{R,inc}
%       = 1i*(-gamma_m*nu_x + beta_m*nu_y) * u_m^{R,inc}.

  if ~(isstruct(rayleighchan) && isfield(rayleighchan, 'beta_m') && ...
      isfield(rayleighchan, 'gamma_m') && isfield(rayleighchan, 'd') && ...
      isfield(rayleighchan, 'K'))
    error('incident_rhs:InvalidRayleighChannels', ...
      'rayleighchan must contain beta_m, gamma_m, d, and K.');
  end
  if ~(isscalar(X_L) && isfinite(X_L))
    error('incident_rhs:InvalidLeftOrigin', ...
      'X_L must be a finite scalar.');
  end
  if ~(isscalar(X_R) && isfinite(X_R))
    error('incident_rhs:InvalidRightOrigin', ...
      'X_R must be a finite scalar.');
  end
  if ~(isscalar(rayleighchan.d) && isfinite(rayleighchan.d) && rayleighchan.d ~= 0)
    error('incident_rhs:InvalidPeriod', ...
      'rayleighchan.d must be a nonzero finite scalar.');
  end
  if ~(isscalar(rayleighchan.K) && isfinite(rayleighchan.K) && ...
      rayleighchan.K >= 0 && rayleighchan.K == floor(rayleighchan.K))
    error('incident_rhs:InvalidChannelCount', ...
      'rayleighchan.K must be a nonnegative integer scalar.');
  end

  [x, y, nx, ny] = LOCAL_extract_boundary_data(geom);

  beta_m = rayleighchan.beta_m(:);
  gamma_m = rayleighchan.gamma_m(:);
  K = rayleighchan.K;
  if length(beta_m) ~= K || length(gamma_m) ~= K
    error('incident_rhs:ChannelSizeMismatch', ...
      'beta_m and gamma_m must have length rayleighchan.K.');
  end

  psi = exp(1i * y * beta_m.') / sqrt(rayleighchan.d);
  U_L = exp(1i * (x - X_L) * gamma_m.') .* psi;
  U_R = exp(-1i * (x - X_R) * gamma_m.') .* psi;

  dU_L = 1i * (nx * gamma_m.' + ny * beta_m.') .* U_L;
  dU_R = 1i * (-nx * gamma_m.' + ny * beta_m.') .* U_R;

  B_L = full(complex([U_L; dU_L]));
  B_R = full(complex([U_R; dU_R]));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [x, y, nx, ny] = LOCAL_extract_boundary_data(geom)

  if isnumeric(geom)
    if ~(ismatrix(geom) && size(geom, 1) >= 6 && size(geom, 2) >= 1)
      error('incident_rhs:InvalidGeometryMatrix', ...
        'Numeric geom must be the 6-by-N construct_cont boundary matrix.');
    end

    x = geom(1, :).';
    y = geom(4, :).';
    dxdt = geom(2, :).';
    dydt = geom(5, :).';
    speed = sqrt(dxdt.^2 + dydt.^2);
    if any(~isfinite(speed)) || any(speed == 0)
      error('incident_rhs:InvalidGeometrySpeed', ...
        'Boundary tangent speed must be finite and nonzero at every node.');
    end

    nx = dydt ./ speed;
    ny = -dxdt ./ speed;
  elseif isstruct(geom)
    if ~(isfield(geom, 'x') && isfield(geom, 'y') && ...
        isfield(geom, 'nx') && isfield(geom, 'ny'))
      error('incident_rhs:InvalidGeometryStruct', ...
        'Struct geom must contain x, y, nx, and ny fields.');
    end

    x = geom.x(:);
    y = geom.y(:);
    nx = geom.nx(:);
    ny = geom.ny(:);
  else
    error('incident_rhs:InvalidGeometry', ...
      'geom must be a construct_cont matrix or a boundary data struct.');
  end

  N = length(x);
  if length(y) ~= N || length(nx) ~= N || length(ny) ~= N
    error('incident_rhs:GeometrySizeMismatch', ...
      'x, y, nx, and ny must have the same number of boundary nodes.');
  end
  if any(~isfinite(x)) || any(~isfinite(y)) || ...
      any(~isfinite(nx)) || any(~isfinite(ny))
    error('incident_rhs:InvalidGeometryValues', ...
      'Boundary coordinates and normals must be finite.');
  end

end
