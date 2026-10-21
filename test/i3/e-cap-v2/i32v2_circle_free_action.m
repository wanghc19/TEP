function [value, normal, piece, blocks] = i32v2_circle_free_action( ...
    k_out, k_in, R, theta_source, theta_target, log_weights, ...
    tau, zeta, tau_derivative, source_count_total)
%I32V2_CIRCLE_FREE_ACTION Apply rectangular free-space Muller differences.
% Purpose:
%   Provide the single circle-primary implementation used by the v2 circle
%   module and its package square/mismatched-grid preflight oracles.
% Input:
%   k_out, k_in             - exterior and interior wavenumbers.
%   R                       - circle radius.
%   theta_source/target     - periodic source and target parameters.
%   log_weights             - rectangular Kress logarithmic weights.
%   tau, zeta               - frozen density coordinates at source nodes.
%   tau_derivative          - parameter derivative of tau at source nodes.
%   source_count_total      - optional full source-grid size when the input
%                             columns are one streamed source panel.
% Output:
%   value, normal - value and exterior-minus-interior normal actions.
%   piece         - separated exterior double/single actions for GQP scale.
%   blocks        - literal free difference blocks for oracle inspection.

if nargin < 10 || isempty(source_count_total)
  source_count_total = numel(theta_source);
end
h = 2 * pi / double(source_count_total);
out = LOCAL_splits(k_out, R, theta_source, theta_target);
in = LOCAL_splits(k_in, R, theta_source, theta_target);
D = log_weights .* (out.L1 - in.L1) + h * (out.L2 - in.L2);
S = log_weights .* (in.M1 - out.M1) + h * (in.M2 - out.M2);
Ds = log_weights .* (in.Ls1 - out.Ls1) + h * (in.Ls2 - out.Ls2);
[TS, TT] = meshgrid(theta_source, theta_target);
geom = cos(TT - TS);
A = (log_weights .* (k_out^2 * out.M1 - k_in^2 * in.M1) + ...
  h * (k_out^2 * out.M2 - k_in^2 * in.M2)) .* geom;
B = (log_weights .* (out.N1 - in.N1) + h * (out.N2 - in.N2)) / R;
value = D * tau + S * zeta;
normal = (A * tau + B * tau_derivative) + Ds * zeta;

Dout = log_weights .* out.L1 + h * out.L2;
Sout = log_weights .* out.M1 + h * out.M2;
Aout = (log_weights .* (k_out^2 * out.M1) + h * (k_out^2 * out.M2)) .* geom;
Bout = (log_weights .* out.N1 + h * out.N2) / R;
piece = struct('value_double', Dout * tau, 'value_single', -Sout * zeta, ...
  'normal_double', Aout * tau + Bout * tau_derivative, ...
  'normal_single', -(log_weights .* out.Ls1 + h * out.Ls2) * zeta);
if nargout >= 4
  blocks = struct('D_difference', D, 'S_in_minus_out', S, ...
    'Dstar_in_minus_out', Ds, 'T_A_difference', A, ...
    'T_B_difference', B, 'S_out', Sout, 'D_out', Dout, ...
    'Dstar_out',log_weights.*out.Ls1+h*out.Ls2, ...
    'Tdiff',A*tau+B*tau_derivative);
else
  blocks = struct();
end
end

%% ==================== Literal circle Kress splits ====================
% The formulas are independent of the package square-grid assembly.

function s = LOCAL_splits(k, R, ts, tt)
[TS, TT] = meshgrid(ts, tt);
dx = R * (cos(TT) - cos(TS));
dy = R * (sin(TT) - sin(TS));
rho = hypot(dx, dy);
diagonal = rho <= 64 * eps(R);
safe = rho;
safe(diagonal) = 1;
nusx = R * cos(TS);
nusy = R * sin(TS);
ntx = cos(TT);
nty = sin(TT);
dot_source = dx .* nusx + dy .* nusy;
dot_target = dx .* ntx + dy .* nty;
zptx = -R * sin(TT);
zpty = R * cos(TT);
dot_tangent = zptx .* dx + zpty .* dy;
logterm = log(4 * sin((TT - TS) / 2).^2);
cotterm = cot((TT - TS) / 2);

M = 1i / 4 * besselh(0, 1, k * safe) * R;
s.M1 = -1 / (4 * pi) * besselj(0, k * safe) * R;
L = 1i * k / 4 * (dot_source ./ safe) .* besselh(1, 1, k * safe);
s.L1 = -k / (4 * pi) * (dot_source ./ safe) .* besselj(1, k * safe);
Ls = -1i * k / 4 * (dot_target ./ safe) .* besselh(1, 1, k * safe) * R;
s.Ls1 = k / (4 * pi) * (dot_target ./ safe) .* besselj(1, k * safe) * R;
N = -1i * k / 4 * (dot_tangent ./ safe) .* besselh(1, 1, k * safe);
s.N1 = k / (4 * pi) * (dot_tangent ./ safe) .* besselj(1, k * safe);
s.M2 = M - s.M1 .* logterm;
s.L2 = L - s.L1 .* logterm;
s.Ls2 = Ls - s.Ls1 .* logterm;
s.N2 = N - 1 / (4 * pi) * cotterm - s.N1 .* logterm;

euler = 0.5772156649015328606;
s.M1(diagonal) = -R / (4 * pi);
s.M2(diagonal) = 0.5 * (1i / 2 - euler / pi - ...
  1 / (2 * pi) * log(k^2 * R^2 / 4)) * R;
s.L1(diagonal) = 0;
s.Ls1(diagonal) = 0;
s.N1(diagonal) = 0;
s.L2(diagonal) = -1 / (4 * pi);
s.Ls2(diagonal) = -1 / (4 * pi);
s.N2(diagonal) = 0;
end
