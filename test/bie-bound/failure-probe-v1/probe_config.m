function c=probe_config(q)
  % Build the physical model and the common solver discretization.
  % Input: explicit job parameters. Output: configuration for lead and center solves.
  e=example_parameters('reference');
  if ismember(q.model,{'ex2','edge'}),e=example_parameters('empty');end
  if strcmp(q.model,'edge'),e.L0=q.L0;end
  e.staggered=strcmp(q.model,'w3');e.join_rows=false;
  if e.staggered
    h=sqrt(3)/2;e.empty_center=true;e.rho_center=1;e.rho_lead=9;
    e.L0=3*h;e.L_positive=2*h;e.L_negative=2*h;e.angle_positive=0;
    e.a_negative=0;e.a_positive=0;
  end
  e.beta=q.beta;e.M=q.M;e.lead_nodes=q.N/2;e.center_nodes=q.N;
  c=example_config(e,search_i9_config());c.fields=false;c.vector_route=false;
  c.center_shift=0;c.model.cut_negative=0;c.model.cut_positive=0;
  if isfield(q,'small') && q.small
    c.model.star_scale=.25;c.center_shift=.4;
  end
  if isfield(q,'cuts')
    c.model.cut_negative=q.cuts(1);c.model.cut_positive=q.cuts(2);
    c.model.X_L=c.model.X_L+q.cuts(1);c.model.X_R=c.model.X_R+q.cuts(2);
  end
end
