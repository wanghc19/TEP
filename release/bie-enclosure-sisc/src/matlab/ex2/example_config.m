% Copied from test/bie-bound/gapedge-v1/example_config.m for release R2.
% Stage C source: test/bie-bound/example2-v1/example_config.m; local changes documented in README.
function c=example_config(e,c)
%EXAMPLE_CONFIG Map explicit example to the inherited search controls.
% Input: e example; c I9 search configuration. Output: c generalized.
  c.model=LOCAL_model(e,c.model);
  c.common.M=e.M;c.common.K=2*e.M+1;
  c.resolutions.fine=struct('center_ntot',e.center_nodes,'negative_ntot',e.lead_nodes,'positive_ntot',e.lead_nodes);
  c.resolutions.coarse=struct('center_ntot',e.center_nodes/2,'negative_ntot',e.lead_nodes/2,'positive_ntot',e.lead_nodes/2);
end
function m=LOCAL_model(e,m)
% Input: explicit example and old model. Output: side-aware model.
  for n={'d','beta','R','a_negative','a_positive','rho_center','rho_lead','L_negative','L_positive','angle_negative','angle_positive','empty_center'}
    m.(n{1})=e.(n{1});
  end
  m.L=e.L0;m.X_L=-e.L0/2;m.X_R=e.L0/2;
end
