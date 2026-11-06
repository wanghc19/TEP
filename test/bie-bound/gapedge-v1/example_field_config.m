% Stage C source: test/bie-bound/example2-v1/example_field_config.m; local changes documented in README.
function c=example_field_config(e,c)
%EXAMPLE_FIELD_CONFIG Parameter handoff to fresh field construction.
% Input: example e and original configuration c. Output: generalized c.
  for n={'d','beta','R','a_negative','a_positive','rho_center','rho_lead','L_negative','L_positive','angle_negative','angle_positive','empty_center'}
    c.model.(n{1})=e.(n{1});
  end
  c.model.L=e.L0;c.model.X_L=-e.L0/2;c.model.X_R=e.L0/2;
  c.discretization.ntot_center=e.center_nodes;c.discretization.ntot_negative=e.lead_nodes;c.discretization.ntot_positive=e.lead_nodes;
  c.discretization.M=e.M;c.discretization.K=2*e.M+1;
end
