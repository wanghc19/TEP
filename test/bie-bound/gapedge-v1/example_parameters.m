% Stage C source: test/bie-bound/example2-v1/example_parameters.m; local changes documented in README.
function e=example_parameters(name,L0,Lp,angle)
%EXAMPLE_PARAMETERS Explicit binary64 model and search discretization.
% Input: name, optional center width, positive lead width and rotation.
% Output: e, source of all B1 geometry changes.
  e=struct('name',name,'d',1,'beta',.5,'L0',1,'L_negative',1,'L_positive',1, ...
    'R',.2,'a_negative',.12,'a_positive',.20,'angle_negative',0,'angle_positive',0, ...
    'rho_center',4,'rho_lead',17,'empty_center',false,'center_nodes',512,'lead_nodes',256,'M',48);
  if strcmp(name,'reference'),return;end
  e.empty_center=true;e.rho_center=1;e.center_nodes=0;e.L_positive=.85;e.angle_positive=.13;
  if nargin>=2,e.L0=L0;end
  if nargin>=3,e.L_positive=Lp;end
  if nargin>=4,e.angle_positive=angle;end
end
