function model=ex1()
%EX1 Example 1 physical parameters, shared by search and field construction.
% Input
%   None. Decimal literals are rounded once by MATLAB to binary64.
% Output
%   model: physical cell, curve, material, phase and proxy-box parameters.
% The analytic curves are defined in the packaged geom.construct_cont and
% pilot_geometry functions. Their common radius is model.R; the five-star's
% internal anisotropy and lobe amplitude are 1.5 and 0.3, respectively.
  model=struct('beta',0.5,'d',1,'L',1,'R',0.2, ...
    'a_negative',0.12,'a_positive',0.20,'rho_center',4, ...
    'rho_lead',17,'rho_exterior',1,'star_scale',1, ...
    'X_L',-0.5,'X_R',0.5,'H',1.1,'proxy_dist',0.2);
end
