function out = signed_regular_image_v7(z,g,cfg,density)
%SIGNED_REGULAR_IMAGE_V7 Signed exact-QP regular-image action with analytic radii.
% Purpose:
%   Evaluate raw value/normal Ewald centers and separate source, target and
%   M-R/M-I/M-T/M-L radii. No local singular action or identity is included.
% Input:
%   Explicit frozen z, general geometry certificate g, numerical cfg, and
%   density.orders/tau_coeff/zeta_coeff. evaluate_centers=false skips centers.
% Main algorithm:
%   Stream reciprocal, nonzero-image and branch-free canonical terms through
%   coordinate order two; contract source/target normals before state action.
% Based on:
%   v3 signed Ewald helper and v2 analytic Ewald finite-plus-tail bounds.
% Main changes:
%   Adds raw value centers, uses real density masses for target strips and
%   grown coefficients for source strips, and records actual oracle calls.
% Numerical goal:
%   CONDITIONAL_ON_EXACT_SPECIAL_FUNCTION_EVALUATION. Delta sf/fp UNRESOLVED.

LOCAL_oracle('__reset__',[]);
if ~isfield(cfg,'local_cauchy_radius_factor')
  cfg.local_cauchy_radius_factor=cfg.cauchy_factor;
end
N=numel(g.parameter_nodes); L=cfg.residual_mode_cutoff;
ell=(-(L-1):L-1).'; P=g.boundary_length;
assert(g.strip_certificate_pass && g.source_strip_certificate_pass && ...
  g.target_strip_certificate_pass && g.outward_normal_contract_pass && ...
  g.parameter_strip_width>0 && g.strip_speed_upper>0);
greal=g;
greal.displacement_abs_upper=g.real_displacement_abs_upper;
greal.displacement_real_upper=g.real_displacement_abs_upper;
greal.displacement_imag_upper=[0,0];
greal.target_normal_component_upper=[1,1];
greal.source_normal_component_upper=[1,1];
real_certificate=LOCAL_ewald_coordinate_bound(z,greal,cfg);
strip_certificate=LOCAL_ewald_coordinate_bound(z,g,cfg);
% The supplied box covers the union of (real target, strip source) and
% (strip target, real source). No simultaneous complex displacement is used.
strip_certificate.domain='union of two separately certified one-variable strips';
[m_t,mt_gate]=LOCAL_retained_image_taylor_tail(z,g,cfg,cfg.ewald_local_cutoff);
branch=LOCAL_reciprocal_ledger(z,cfg);
assert(real_certificate.gate.pass && strip_certificate.gate.pass && ...
  mt_gate.pass && branch.pass,'I5v7Regular:EwaldGate','Ewald analytic gate failed.');
coordinate_tails={real_certificate.reciprocal_tail, ...
  real_certificate.omitted_image_tail,m_t,real_certificate.local_factorial_tail};
names={'M_R','M_I','M_T','M_L'};
real_mass=2*pi*g.speed_upper* ...
  [sum(vecnorm(density.tau_coeff,2,2)),sum(vecnorm(density.zeta_coeff,2,2))];
a=g.parameter_strip_width;
growth=LOCAL_oracle('exp',a*abs(density.orders));
source_density=[sum(growth.*vecnorm(density.tau_coeff,2,2)), ...
  sum(growth.*vecnorm(density.zeta_coeff,2,2))];
KQ=LOCAL_contract_coordinate(strip_certificate.finite, ...
  g.target_normal_component_upper,g.source_normal_component_upper);
Kfull=LOCAL_contract_coordinate(strip_certificate.finite+strip_certificate.tail, ...
  g.target_normal_component_upper,g.source_normal_component_upper);
% KQ is a supremum for retained sums; its image bound safely sums all orders.
% Kfull adds reciprocal/image/local omissions and is used only for high modes.
target_action=[KQ(2)*real_mass(1)+KQ(1)*real_mass(2), ...
  KQ(4)*real_mass(1)+KQ(3)*real_mass(2)];
source_integrand=g.strip_speed_upper* ...
  [KQ(2)*source_density(1)+KQ(1)*source_density(2), ...
   KQ(4)*source_density(1)+KQ(3)*source_density(2)];
high_action=[Kfull(2)*real_mass(1)+Kfull(1)*real_mass(2), ...
  Kfull(4)*real_mass(1)+Kfull(3)*real_mass(2)];
log_den=a*N+LOCAL_oracle('log1p',-LOCAL_oracle('exp',-a*N));
source_scale=4*pi*(2*pi/N*sum(g.speed_nodes))/LOCAL_oracle('sqrt',P);
log_target_scale=LOCAL_oracle('log',4*pi*g.strip_speed_upper/LOCAL_oracle('sqrt',P))+ ...
  abs(2*pi*ell/P)*g.arclength_strip_width-log_den;
radii=cell(1,2);
for action=1:2
  r=struct;
  r.source=repmat(LOCAL_oracle('exp',max(LOCAL_oracle('log',realmin), ...
    LOCAL_oracle('log',source_scale*source_integrand(action))-log_den)),numel(ell),1);
  r.target=LOCAL_oracle('exp',max(LOCAL_oracle('log',realmin),log_target_scale+LOCAL_oracle('log',target_action(action))));
  for j=1:4
    Ktail=LOCAL_contract_coordinate(coordinate_tails{j},[1,1],[1,1]);
    if action==1
      value=LOCAL_oracle('sqrt',P)*(Ktail(2)*real_mass(1)+Ktail(1)*real_mass(2));
    else
      value=LOCAL_oracle('sqrt',P)*(Ktail(4)*real_mass(1)+Ktail(3)*real_mass(2));
    end
    r.(names{j})=repmat(value,numel(ell),1);
  end
  r.total=r.source+r.target+r.M_R+r.M_I+r.M_T+r.M_L;
  radii{action}=r;
end

do_centers=~isfield(cfg,'evaluate_centers') || cfg.evaluate_centers;
rows_val=[]; rows_nor=[];
if do_centers
  density_phase=LOCAL_oracle('exp',1i*g.parameter_nodes(:)*density.orders(:).');
  weighted_tau=(density_phase*density.tau_coeff).*(g.speed_nodes(:)*2*pi/N);
  weighted_zeta=(density_phase*density.zeta_coeff).*(g.speed_nodes(:)*2*pi/N);
  samples_val=complex(zeros(N,size(density.tau_coeff,2)));
  samples_nor=samples_val;
  nsx=g.normal(:,1).'; nsy=g.normal(:,2).';
  block=double(cfg.target_block_size);
  for first=1:block:N
    ids=first:min(first+block-1,N);
    coordinate=LOCAL_ewald_signed_coordinates(g.position(ids,:),g.position, ...
      double(z.khat),double(z.beta),double(z.d),cfg,cfg.ewald_local_cutoff);
    ntx=g.normal(ids,1); nty=g.normal(ids,2);
    source_normal=-(coordinate.dx.*nsx+coordinate.dy.*nsy);
    target_normal=coordinate.dx.*ntx+coordinate.dy.*nty;
    mixed_normal=-(coordinate.dxx.*(ntx*nsx)+ ...
      coordinate.dxy.*(ntx*nsy+nty*nsx)+coordinate.dyy.*(nty*nsy));
    samples_val(ids,:)=source_normal*weighted_tau-coordinate.value*weighted_zeta;
    samples_nor(ids,:)=mixed_normal*weighted_tau-target_normal*weighted_zeta;
  end
  rows_val=LOCAL_target_rows_stream( ...
    samples_val,g.speed_nodes,g.arclength_nodes,ell,P,N,block);
  rows_nor=LOCAL_target_rows_stream( ...
    samples_nor,g.speed_nodes,g.arclength_nodes,ell,P,N,block);
end
all_radii=[];
for action=1:2
  component_names=fieldnames(radii{action});
  for j=1:numel(component_names)
    all_radii=[all_radii;radii{action}.(component_names{j})(:)]; %#ok<AGROW>
  end
end
gates=struct('ewald_real',real_certificate.gate.pass, ...
  'ewald_strip',strip_certificate.gate.pass,'M_T',mt_gate.pass, ...
  'nonwood_branch',branch.pass,'source_density_strip_growth_included', ...
    all(source_density>=real_mass/(2*pi*g.speed_upper)), ...
  'source_strip_certificate',g.source_strip_certificate_pass, ...
  'target_strip_certificate',g.target_strip_certificate_pass, ...
  'one_variable_strip_union_only',true, ...
  'outward_normal_contract',g.outward_normal_contract_pass, ...
  'parameter_grid_contract',g.parameter_grid_contract_pass, ...
  'source_jacobian_once',true,'target_real_source_mass',true, ...
  'target_dft_streamed',double(cfg.target_block_size)==16, ...
  'raw_signs_deferred',true,'identity_included',false, ...
  'centers_evaluated',do_centers, ...
  'finite',isreal(all_radii) && all(isfinite(all_radii)) && ...
    all(all_radii>=0) && isreal(high_action) && all(high_action>=0) && ...
    all(isfinite([high_action,rows_val(:).',rows_nor(:).'])));
gates.pass=gates.ewald_real && gates.ewald_strip && gates.M_T && ...
  gates.nonwood_branch && gates.source_density_strip_growth_included && gates.finite && ...
  gates.source_strip_certificate && gates.target_strip_certificate && ...
  gates.one_variable_strip_union_only && gates.outward_normal_contract && ...
  gates.parameter_grid_contract && gates.source_jacobian_once && ...
  gates.target_real_source_mass && gates.target_dft_streamed && ...
  gates.raw_signs_deferred && ~gates.identity_included;
out=struct('raw_center',struct('val',rows_val,'nor',rows_nor), ...
  'radius',struct('val',radii{1},'nor',radii{2}), ...
  'value_strip_upper',high_action(1),'normal_strip_upper',high_action(2), ...
  'mode_orders',ell,'real_certificate',real_certificate, ...
  'strip_certificate',strip_certificate,'M_T_certificate',mt_gate, ...
  'real_density_L1',real_mass,'source_strip_density_upper',source_density, ...
  'source_strip_integrand_upper',source_integrand, ...
  'target_strip_action_upper',target_action,'branch',branch, ...
  'gates',gates,'delta_sf','UNRESOLVED','delta_fp','UNRESOLVED', ...
  'sf_ledger',LOCAL_oracle('__report__',[]));
assert(gates.pass,'I5v7Regular:Gate','Regular-image certificate failed.');
end

function rows=LOCAL_target_rows_stream(samples,speed,arclength,ell,P,N,block)
rows=complex(zeros(numel(ell),size(samples,2)));
weighted_samples=samples.*speed(:);
scale=2*pi/N/LOCAL_oracle('sqrt',P);
for first=1:block:numel(ell)
  ids=first:min(first+block-1,numel(ell));
  target_phase=LOCAL_oracle( ...
    'exp',-1i*(2*pi*ell(ids)/P)*arclength(:).');
  rows(ids,:)=target_phase*weighted_samples*scale;
end
end

%% ==================== Reused Ewald analytic certificates ====================
% The following finite sums and explicit tails retain their v2 formulas.
function kernel = LOCAL_contract_coordinate(coordinate, Nt, Ns)
kernel = [ ...
  coordinate(1), ...
  Ns(1) * coordinate(2) + Ns(2) * coordinate(3), ...
  Nt(1) * coordinate(2) + Nt(2) * coordinate(3), ...
  Nt(1) * Ns(1) * coordinate(4) + ...
    (Nt(1) * Ns(2) + Nt(2) * Ns(1)) * coordinate(5) + ...
    Nt(2) * Ns(2) * coordinate(6)];
end

function out = LOCAL_ewald_coordinate_bound(z, geometry, configuration)
kappa = double(z.khat);
d = double(z.d);
beta = double(z.beta);
h = configuration.ewald_split / d;
chi_E = (kappa * d / (2.0 * configuration.ewald_split))^2;
RX = geometry.displacement_abs_upper(1);
RY = geometry.displacement_abs_upper(2);
IX = geometry.displacement_imag_upper(1);
IY = geometry.displacement_imag_upper(2);
UX = geometry.displacement_real_upper(1);
UY = geometry.displacement_real_upper(2);
finite_images_and_reciprocal = LOCAL_ewald_finite_upper( ...
  kappa, beta, d, h, chi_E, RX, RY, IX, IY, UX, UY, configuration);
[reciprocal_tail, reciprocal_gate] = LOCAL_reciprocal_tail( ...
  kappa, beta, d, h, RX, IX, IY, UX, configuration.reciprocal_cutoff);
[image_tail, image_gate] = LOCAL_image_tail( ...
  d, h, chi_E, RX, RY, IX, IY, UY, configuration.image_cutoff);
[local_finite, local_tail, local_gate] = LOCAL_local_ewald_bound( ...
  h, chi_E, RX, RY, configuration);
finite = finite_images_and_reciprocal + local_finite;
tail = reciprocal_tail + image_tail + local_tail;
out = struct( ...
  'coordinate_order', {{'00', '10', '01', '20', '11', '02'}}, ...
  'finite', finite, ...
  'reciprocal_tail', reciprocal_tail, ...
  'omitted_image_tail', image_tail, ...
  'local_factorial_tail', local_tail, ...
  'tail', tail, ...
  'gate', struct( ...
    'reciprocal', reciprocal_gate, ...
    'image', image_gate, ...
    'local', local_gate, ...
    'image_supremum_includes_all_taylor_orders', true, ...
    'pass', reciprocal_gate.pass && image_gate.pass && ...
      local_gate.pass && all(isfinite([finite, tail]))));
end

function upper = LOCAL_ewald_finite_upper( ...
    kappa, beta, d, h, chi_E, RX, RY, IX, IY, UX, UY, configuration)
upper = zeros(1, 6);
moments = [LOCAL_oracle('sqrt',pi) / 2.0, 0.5, LOCAL_oracle('sqrt',pi) / 4.0];
radial = [moments(1), ...
  2.0 * h^2 * RX * moments(1) + 2.0 * h * moments(2), ...
  (4.0 * h^4 * RX^2 + 2.0 * h^2) * moments(1) + ...
  8.0 * h^3 * RX * moments(2) + 4.0 * h^2 * moments(3)];
derivative_orders = [0, 0; 1, 0; 0, 1; 2, 0; 1, 1; 0, 2];
for mode = -(configuration.reciprocal_cutoff - 1.0): ...
    configuration.reciprocal_cutoff - 1.0
  transverse = beta + 2.0 * pi * mode / d;
  q_mode = LOCAL_oracle('sqrt',complex(transverse^2 - kappa^2));
  if real(q_mode) < 0.0 || ...
      (real(q_mode) == 0.0 && imag(q_mode) > 0.0)
    q_mode = -q_mode;
  end
  q_abs = abs(q_mode);
  if q_abs == 0.0
    upper(:) = Inf;
    return;
  end
  if isreal(q_mode) && q_mode >= 2.0 * h^2 * UX
    for index = 1:6
      r = derivative_orders(index, 1);
      s = derivative_orders(index, 2);
      upper(index) = upper(index) + radial(r + 1.0) / ...
        (d * LOCAL_oracle('sqrt',pi)) * abs(transverse)^s / q_mode * ...
        LOCAL_oracle('exp',-q_mode^2 / (4.0 * h^2) + ...
        h^2 * IX^2 + abs(transverse) * IY);
    end
  else
    u = q_abs / (2.0 * h) + h * RX;
    exp_u = LOCAL_oracle('exp',u^2);
    E0 = 1.0 + 2.0 * u * exp_u / LOCAL_oracle('sqrt',pi);
    E1 = 2.0 * exp_u / LOCAL_oracle('sqrt',pi);
    E2 = 4.0 * u * exp_u / LOCAL_oracle('sqrt',pi);
    exponential = LOCAL_oracle('exp',q_abs * RX + abs(transverse) * IY) / ...
      (2.0 * d * q_abs);
    F0 = exponential * E0;
    F1 = exponential * (q_abs * E0 + h * E1);
    F2 = exponential * (q_abs^2 * E0 + ...
      2.0 * q_abs * h * E1 + h^2 * E2);
    upper = upper + [F0, F1, abs(transverse) * F0, F2, ...
      abs(transverse) * F1, transverse^2 * F0];
  end
end
for image = [-(configuration.image_cutoff - 1.0):-1.0, ...
    1.0:configuration.image_cutoff - 1.0]
  u = h^2 * ((abs(image) * d - UY)^2 - IX^2 - IY^2);
  if u <= 0.0
    upper(:) = Inf;
    return;
  end
  H01 = LOCAL_oracle('exp',chi_E - u) / u;
  H2 = LOCAL_oracle('exp',chi_E - u) * (1.0 / u + 1.0 / u^2);
  zx = 2.0 * h^2 * RX;
  zy = 2.0 * h^2 * (abs(image) * d + RY);
  upper = upper + [H01, zx * H01, zy * H01, ...
    zx^2 * H2 + 2.0 * h^2 * H01, zx * zy * H2, ...
    zy^2 * H2 + 2.0 * h^2 * H01] / (4.0 * pi);
end
end

function [tail, gate] = LOCAL_reciprocal_tail( ...
    kappa, beta, d, h, RX, IX, IY, UX, reciprocal_cutoff)
step = 2.0 * pi / d;
moments = [LOCAL_oracle('sqrt',pi) / 2.0, 0.5, LOCAL_oracle('sqrt',pi) / 4.0];
radial = [moments(1), ...
  2.0 * h^2 * RX * moments(1) + 2.0 * h * moments(2), ...
  (4.0 * h^4 * RX^2 + 2.0 * h^2) * moments(1) + ...
  8.0 * h^3 * RX * moments(2) + 4.0 * h^2 * moments(3)];
tail = zeros(1, 6);
orders = [0, 0; 1, 0; 0, 1; 2, 0; 1, 1; 0, 2];
ratios = zeros(2, 3);
positive_gate = true;
side_sign = [-1.0, 1.0];
for side_index = 1:2
  transverse = step * reciprocal_cutoff + side_sign(side_index) * beta;
  q_first = LOCAL_oracle('sqrt',transverse^2 - kappa^2);
  positive_gate = positive_gate && transverse > kappa && ...
    q_first >= 2.0 * h^2 * UX;
  for s = 0:2
    ratios(side_index, s + 1.0) = ...
      (1.0 + step / transverse)^s * ...
      LOCAL_oracle('exp',-step * (2.0 * transverse + step) / ...
      (4.0 * h^2) + step * IY);
  end
  for index = 1:6
    r = orders(index, 1);
    s = orders(index, 2);
    first = transverse^s / q_first * ...
      LOCAL_oracle('exp',-q_first^2 / (4.0 * h^2) + transverse * IY);
    tail(index) = tail(index) + radial(r + 1.0) * ...
      LOCAL_oracle('exp',h^2 * IX^2) / (d * LOCAL_oracle('sqrt',pi)) * first / ...
      (1.0 - ratios(side_index, s + 1.0));
  end
end
gate = struct( ...
  'positive_first_omitted', positive_gate, ...
  'ratios', ratios, ...
  'pass', positive_gate && all(ratios(:) < 1.0));
end

function [tail, gate] = LOCAL_image_tail( ...
    d, h, chi_E, RX, RY, IX, IY, UY, image_cutoff)
u = h^2 * ((image_cutoff * d - UY)^2 - IX^2 - IY^2);
distance_upper = image_cutoff * d + RY;
ratios = zeros(1, 3);
S1 = zeros(1, 3);
S2 = zeros(1, 3);
for alpha = 0:2
  ratios(alpha + 1.0) = (1.0 + d / distance_upper)^alpha * ...
    LOCAL_oracle('exp',-h^2 * d * (2.0 * (image_cutoff * d - UY) + d));
  S1(alpha + 1.0) = 2.0 * distance_upper^alpha * LOCAL_oracle('exp',-u) / ...
    (u * (1.0 - ratios(alpha + 1.0)));
  S2(alpha + 1.0) = 2.0 * distance_upper^alpha * LOCAL_oracle('exp',-u) / ...
    (u^2 * (1.0 - ratios(alpha + 1.0)));
end
scale = LOCAL_oracle('exp',chi_E) / (4.0 * pi);
zx = 2.0 * h^2 * RX;
tail = scale * [S1(1), zx * S1(1), 2.0 * h^2 * S1(2), ...
  zx^2 * (S1(1) + S2(1)) + 2.0 * h^2 * S1(1), ...
  zx * 2.0 * h^2 * (S1(2) + S2(2)), ...
  (2.0 * h^2)^2 * (S1(3) + S2(3)) + ...
  2.0 * h^2 * S1(1)];
gate = struct( ...
  'first_u', u, 'ratios', ratios, ...
  'pass', image_cutoff * d > UY && u > 0.0 && all(ratios < 1.0));
end

function [finite, tail, gate] = LOCAL_local_ewald_bound( ...
    h, chi_E, RX, RY, configuration)
R0 = h^2 * (RX^2 + RY^2);
B = configuration.local_cauchy_radius_factor * R0;
cutoff = configuration.ewald_local_cutoff;
if B <= R0
  finite = Inf(1, 6);
  tail = finite;
  gate = struct('pass', false);
  return;
end
x = chi_E * B;
xQ = chi_E * (1.0 + B);
ratios = [x / (cutoff + 2.0)^2, ...
  B * (cutoff + 1.0) / (cutoff + 2.0)^2, ...
  x / (cutoff + 2.0)^2 * (1.0 + 1.0 / (cutoff + 2.0)), ...
  xQ * (cutoff + 1.0) / (cutoff + 2.0)^2];
harmonic = sum(1.0 ./ (1.0:cutoff + 1.0));
tau_J = x^(cutoff + 1.0) / ...
  (LOCAL_oracle('exp',2.0 * LOCAL_oracle('gammaln',cutoff + 2.0)) * (1.0 - ratios(1)));
tau_S = B^(cutoff + 1.0) / ((cutoff + 1.0) * ...
  LOCAL_oracle('exp',LOCAL_oracle('gammaln',cutoff + 2.0)) * (1.0 - ratios(2)));
tau_D = harmonic * x^(cutoff + 1.0) / ...
  (LOCAL_oracle('exp',2.0 * LOCAL_oracle('gammaln',cutoff + 2.0)) * (1.0 - ratios(3)));
tau_Q = xQ^(cutoff + 1.0) / ((1.0 + B) * ...
  (cutoff + 1.0) * LOCAL_oracle('exp',LOCAL_oracle('gammaln',cutoff + 2.0)) * ...
  (1.0 - ratios(4)));
c_eta = abs(LOCAL_oracle('log',chi_E) + 0.57721566490153286060 - 1i * pi);
tau_C = (tau_J * (LOCAL_oracle('exp',B) - 1.0 + c_eta) + ...
  LOCAL_oracle('exp',chi_E * B) * tau_S + LOCAL_oracle('exp',B) * tau_Q) / (4.0 * pi) + ...
  tau_D / (2.0 * pi);
L_derivative = [tau_C, tau_C / (B - R0), ...
  2.0 * tau_C / (B - R0)^2];
tail = LOCAL_radial_to_coordinate(L_derivative, h, RX, RY);

indices = 0:cutoff;
J_finite = sum((chi_E * B).^indices ./ ...
  LOCAL_oracle('exp',2.0 * LOCAL_oracle('gammaln',indices + 1.0)));
positive = 1:cutoff;
S_finite = sum(B.^positive ./ ...
  (positive .* LOCAL_oracle('exp',LOCAL_oracle('gammaln',positive + 1.0))));
harmonic_values = cumsum(1.0 ./ positive);
D_finite = sum(harmonic_values .* (chi_E * B).^positive ./ ...
  LOCAL_oracle('exp',2.0 * LOCAL_oracle('gammaln',positive + 1.0)));
Q_finite = 0.0;
for n = 1:cutoff
  inner = sum(LOCAL_oracle('exp',LOCAL_oracle('gammaln',n - (0:n - 1.0))) .* B.^(0:n - 1.0));
  Q_finite = Q_finite + chi_E^n / ...
    LOCAL_oracle('exp',2.0 * LOCAL_oracle('gammaln',n + 1.0)) * inner;
end
M_finite = J_finite * (S_finite + c_eta) / (4.0 * pi) + ...
  LOCAL_oracle('exp',B) * Q_finite / (4.0 * pi) + D_finite / (2.0 * pi);
finite_derivative = [M_finite, M_finite / (B - R0), ...
  2.0 * M_finite / (B - R0)^2];
finite = LOCAL_radial_to_coordinate( ...
  finite_derivative, h, RX, RY);
gate = struct( ...
  'local_z_radius', R0, ...
  'local_cauchy_radius', B, ...
  'ratios', ratios, ...
  'pass', all(ratios < 1.0) && all(isfinite([finite, tail])));
end

function coordinate = LOCAL_radial_to_coordinate(radial, h, RX, RY)
coordinate = [radial(1), ...
  2.0 * h^2 * RX * radial(2), ...
  2.0 * h^2 * RY * radial(2), ...
  4.0 * h^4 * RX^2 * radial(3) + 2.0 * h^2 * radial(2), ...
  4.0 * h^4 * RX * RY * radial(3), ...
  4.0 * h^4 * RY^2 * radial(3) + 2.0 * h^2 * radial(2)];
end


%% ==================== Reused signed Ewald sums ====================
% Retained sums follow v3; normal/value contractions are in the main routine.
function ledger = LOCAL_reciprocal_ledger(z, configuration)
kappa = double(z.khat);
beta = double(z.beta);
d = double(z.d);
modes = (-(configuration.reciprocal_cutoff - 1.0): ...
  configuration.reciprocal_cutoff - 1.0).';
transverse = beta + 2.0 * pi * modes / d;
radicand = transverse.^2 - kappa^2;
q_mode = LOCAL_oracle('sqrt',complex(radicand));
flip = real(q_mode) < 0.0 | ...
  (real(q_mode) == 0.0 & imag(q_mode) > 0.0);
q_mode(flip) = -q_mode(flip);
nonwood = all(q_mode ~= 0.0);
branch = all(real(q_mode(radicand > 0.0)) > 0.0) && ...
  all(imag(q_mode(radicand < 0.0)) < 0.0);
ledger = struct( ...
  'mode_orders', modes, ...
  'transverse_wavenumber', transverse, ...
  'linton_q', q_mode, ...
  'minimum_denominator_magnitude', min(abs(q_mode)), ...
  'nonwood', nonwood, ...
  'outgoing_decaying_branch', branch, ...
  'pass', nonwood && branch && all(isfinite(q_mode)));
end

function coordinate = LOCAL_ewald_signed_coordinates( ...
    target, source, kappa, beta, d, configuration, taylor_cutoff)
X = target(:, 1) - source(:, 1).';
Y = target(:, 2) - source(:, 2).';
h = configuration.ewald_split / d;
chi_E = (kappa * d / (2.0 * configuration.ewald_split))^2;
value = complex(zeros(size(X)));
dx = value;
dy = value;
dxx = value;
dxy = value;
dyy = value;
for mode = -(configuration.reciprocal_cutoff - 1.0): ...
    configuration.reciprocal_cutoff - 1.0
  transverse = beta + 2.0 * pi * mode / d;
  q_mode = LOCAL_oracle('sqrt',complex(transverse^2 - kappa^2));
  if real(q_mode) < 0.0 || ...
      (real(q_mode) == 0.0 && imag(q_mode) > 0.0)
    q_mode = -q_mode;
  end
  if q_mode == 0.0
    error('I51dInput:ExactWood', ...
      'A retained reciprocal Ewald denominator is zero.');
  end
  phase = LOCAL_oracle('exp',1i * transverse * Y) / (4.0 * d * q_mode);
  F0 = complex(zeros(size(X)));
  F1 = F0;
  F2 = F0;
  for epsilon = [-1.0, 1.0]
    argument = q_mode / (2.0 * h) + epsilon * h * X;
    exponential = LOCAL_oracle('exp',epsilon * q_mode * X);
    erfc_value = LOCAL_oracle('Faddeeva_erfc',argument);
    erfc_first = -2.0 / LOCAL_oracle('sqrt',pi) * LOCAL_oracle('exp',-argument.^2);
    erfc_second = 4.0 / LOCAL_oracle('sqrt',pi) * argument .* LOCAL_oracle('exp',-argument.^2);
    F0 = F0 + exponential .* erfc_value;
    F1 = F1 + epsilon * exponential .* ...
      (q_mode * erfc_value + h * erfc_first);
    F2 = F2 + exponential .* (q_mode^2 * erfc_value + ...
      2.0 * q_mode * h * erfc_first + h^2 * erfc_second);
  end
  value = value + phase .* F0;
  dx = dx + phase .* F1;
  dy = dy + 1i * transverse * phase .* F0;
  dxx = dxx + phase .* F2;
  dxy = dxy + 1i * transverse * phase .* F1;
  dyy = dyy - transverse^2 * phase .* F0;
end
for image_index = [-(configuration.image_cutoff - 1.0):-1.0, ...
    1.0:configuration.image_cutoff - 1.0]
  shifted_y = Y - image_index * d;
  zeta = h^2 * (X.^2 + shifted_y.^2);
  [H0, H1, H2] = LOCAL_H_chi_finite(zeta, chi_E, taylor_cutoff);
  phase = LOCAL_oracle('exp',1i * beta * image_index * d) / (4.0 * pi);
  zx = 2.0 * h^2 * X;
  zy = 2.0 * h^2 * shifted_y;
  value = value + phase * H0;
  dx = dx + phase * (H1 .* zx);
  dy = dy + phase * (H1 .* zy);
  dxx = dxx + phase * (H2 .* zx.^2 + 2.0 * h^2 * H1);
  dxy = dxy + phase * (H2 .* zx .* zy);
  dyy = dyy + phase * (H2 .* zy.^2 + 2.0 * h^2 * H1);
end
zeta = h^2 * (X.^2 + Y.^2);
[C0, C1, C2] = LOCAL_C_chi_finite(zeta, chi_E, taylor_cutoff);
zx = 2.0 * h^2 * X;
zy = 2.0 * h^2 * Y;
value = value - C0;
dx = dx - C1 .* zx;
dy = dy - C1 .* zy;
dxx = dxx - (C2 .* zx.^2 + 2.0 * h^2 * C1);
dxy = dxy - C2 .* zx .* zy;
dyy = dyy - (C2 .* zy.^2 + 2.0 * h^2 * C1);
coordinate = struct('value', value, 'dx', dx, 'dy', dy, ...
  'dxx', dxx, 'dxy', dxy, 'dyy', dyy);
end

function [H0, H1, H2] = LOCAL_H_chi_finite(zeta, chi_E, cutoff)
exp_minus = LOCAL_oracle('exp',-zeta);
Eminus = exp_minus .* (1.0 ./ zeta + 1.0 ./ zeta.^2);
Ezero = exp_minus ./ zeta;
Eplus = LOCAL_oracle('expint',zeta);
H0 = complex(zeros(size(zeta)));
H1 = H0;
H2 = H0;
coefficient = 1.0;
for order = 0:cutoff
  H0 = H0 + coefficient * Eplus;
  H1 = H1 - coefficient * Ezero;
  H2 = H2 + coefficient * Eminus;
  if order < cutoff
    Enext = (exp_minus - zeta .* Eplus) / (order + 1.0);
    Eminus = Ezero;
    Ezero = Eplus;
    Eplus = Enext;
    coefficient = coefficient * chi_E / (order + 1.0);
  end
end
end

function [C0, C1, C2] = LOCAL_C_chi_finite(zeta, chi_E, cutoff)
gamma_E = 0.57721566490153286060;
J = zeros(1, cutoff + 1.0);
S = J;
D = J;
Q = J;
harmonic = 0.0;
for order = 0:cutoff
  J(order + 1.0) = (-chi_E)^order / ...
    LOCAL_oracle('exp',2.0 * LOCAL_oracle('gammaln',order + 1.0));
  if order >= 1.0
    harmonic = harmonic + 1.0 / order;
    S(order + 1.0) = (-1.0)^order / ...
      (order * LOCAL_oracle('exp',LOCAL_oracle('gammaln',order + 1.0)));
    D(order + 1.0) = (-1.0)^order * harmonic * chi_E^order / ...
      LOCAL_oracle('exp',2.0 * LOCAL_oracle('gammaln',order + 1.0));
    for degree = 0:order - 1.0
      Q(degree + 1.0) = Q(degree + 1.0) + chi_E^order / ...
        LOCAL_oracle('exp',2.0 * LOCAL_oracle('gammaln',order + 1.0)) * ...
        LOCAL_oracle('exp',LOCAL_oracle('gammaln',order - degree)) * (-1.0)^degree;
    end
  end
end
c_chi = LOCAL_oracle('log',chi_E) + gamma_E - 1i * pi;
polynomial = conv(J, S);
polynomial(1:numel(J)) = polynomial(1:numel(J)) - c_chi * J;
polynomial(1:numel(D)) = polynomial(1:numel(D)) + 2.0 * D;
polynomial = polynomial / (4.0 * pi);
[P0, P1, P2] = LOCAL_polynomial_012(polynomial, zeta);
[Q0, Q1, Q2] = LOCAL_polynomial_012(Q, zeta);
exp_factor = LOCAL_oracle('exp',-zeta) / (4.0 * pi);
C0 = P0 - exp_factor .* Q0;
C1 = P1 - exp_factor .* (Q1 - Q0);
C2 = P2 - exp_factor .* (Q2 - 2.0 * Q1 + Q0);
end

function [v0, v1, v2] = LOCAL_polynomial_012(coefficients, zeta)
degrees = 0:numel(coefficients) - 1.0;
v0 = polyval(fliplr(coefficients), zeta);
if numel(coefficients) > 1.0
  first = coefficients(2:end) .* degrees(2:end);
  v1 = polyval(fliplr(first), zeta);
else
  v1 = zeros(size(zeta));
end
if numel(coefficients) > 2.0
  second = coefficients(3:end) .* degrees(3:end) .* ...
    (degrees(3:end) - 1.0);
  v2 = polyval(fliplr(second), zeta);
else
  v2 = zeros(size(zeta));
end
end

function [tail, gate] = LOCAL_retained_image_taylor_tail( ...
    z, geometry, configuration, cutoff)
kappa = double(z.khat);
d = double(z.d);
h = configuration.ewald_split / d;
chi_E = (kappa * d / (2.0 * configuration.ewald_split))^2;
RX = geometry.real_displacement_abs_upper(1);
RY = geometry.real_displacement_abs_upper(2);
UY = geometry.real_displacement_abs_upper(2);
ratio = chi_E / (cutoff + 2.0);
first = LOCAL_oracle('exp',(cutoff + 1.0) * LOCAL_oracle('log',chi_E) - ...
  LOCAL_oracle('gammaln',cutoff + 2.0));
poisson_tail = first / (1.0 - ratio);
tail = zeros(1, 6);
u_values = zeros(1, 2.0 * (configuration.image_cutoff - 1.0));
counter = 0.0;
for image_index = [-(configuration.image_cutoff - 1.0):-1.0, ...
    1.0:configuration.image_cutoff - 1.0]
  counter = counter + 1.0;
  u = h^2 * (abs(image_index) * d - UY)^2;
  u_values(counter) = u;
  theta = poisson_tail * LOCAL_oracle('exp',-u) / u;
  zx = 2.0 * h^2 * RX;
  zy = 2.0 * h^2 * (abs(image_index) * d + RY);
  tail = tail + theta / (4.0 * pi) * [1.0, zx, zy, ...
    zx^2 + 2.0 * h^2, zx * zy, zy^2 + 2.0 * h^2];
end
gate = struct( ...
  'taylor_cutoff', cutoff, ...
  'first_omitted_order', cutoff + 1.0, ...
  'poisson_ratio', ratio, ...
  'poisson_tail_upper', poisson_tail, ...
  'retained_image_real_lower', u_values, ...
  'pass', ratio < 1.0 && all(u_values > 0.0) && ...
    all(isfinite([poisson_tail, tail])) && all(tail >= 0.0));
end

%% ==================== Exact-oracle call ledger ====================
% Parameter extrema describe actual calls only; they are not proof bounds.
function y=LOCAL_oracle(name,varargin)
persistent entries
if strcmp(name,'__reset__')
  entries=struct;
  y=[];
  return;
end
if strcmp(name,'__report__')
  y=struct('scope','one helper invocation including analytic certificates', ...
    'calls',entries,'Bessel_calls',0,'Hankel_calls',0,'qpgreen_calls',0, ...
    'finite_evaluation','UNRESOLVED','roundoff','UNRESOLVED');
  return;
end
x=varargin{1};
key=matlab.lang.makeValidName(name);
if ~isfield(entries,key)
  entries.(key)=struct('function_name',name,'vectorized_calls',0, ...
    'scalar_arguments',0,'real_min',Inf,'real_max',-Inf, ...
    'imag_min',Inf,'imag_max',-Inf,'abs_min',Inf,'abs_max',-Inf);
end
e=entries.(key);
e.vectorized_calls=e.vectorized_calls+1;
e.scalar_arguments=e.scalar_arguments+numel(x);
if ~isempty(x)
  e.real_min=min(e.real_min,min(real(x(:))));
  e.real_max=max(e.real_max,max(real(x(:))));
  e.imag_min=min(e.imag_min,min(imag(x(:))));
  e.imag_max=max(e.imag_max,max(imag(x(:))));
  e.abs_min=min(e.abs_min,min(abs(x(:))));
  e.abs_max=max(e.abs_max,max(abs(x(:))));
end
entries.(key)=e;
y=feval(name,varargin{:});
end
