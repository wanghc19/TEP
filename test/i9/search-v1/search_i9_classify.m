function diagnostic = search_i9_classify(alpha,theta,residual,K,config)
%SEARCH_I9_CLASSIFY Conservative homogeneous Bloch classification.
% Purpose: Classify given QZ diagonal pairs, without selecting a forced subspace.
% Based on: design-9-1a two-ring numerical unit-circle qualification.
% Output: all raw diagonal pairs, masks, counts, thresholds and status.
  q=config.qualification;
  tol=max(q.qz_eps_factor*eps,q.qz_residual_factor*residual);
  scale=hypot(abs(alpha),abs(theta)); indeterminate=scale<=tol;
  divisor=scale; divisor(indeterminate)=1;
  an=abs(alpha)./divisor; tn=abs(theta)./divisor;
  distance=abs(an-tn);
  inner=max(q.inner_floor,q.inner_residual_factor*residual);
  outer=max(q.outer_floor,q.outer_inner_factor*inner);
  near=~indeterminate & distance<=inner;
  uncertain=~indeterminate & distance>inner & distance<=outer;
  stable=~indeterminate & an<tn-outer;
  unstable=~indeterminate & an>tn+outer;
  if any(~isfinite(alpha)) || any(~isfinite(theta)) || ~isfinite(residual) || residual>q.residual_max
    status='UNQUALIFIED';
  elseif any(indeterminate), status='INDETERMINATE';
  elseif any(uncertain), status='UNCERTAIN';
  elseif any(near), status='NEAR_UNIT_PROPAGATING';
  elseif sum(stable)==K && sum(unstable)==K, status='GAP';
  else, status='UNBALANCED'; end
  diagnostic=struct('status',status,'alpha_real',real(alpha),'alpha_imag',imag(alpha), ...
    'theta_real',real(theta),'theta_imag',imag(theta),'distance',distance, ...
    'stable_mask',stable,'unstable_mask',unstable,'near_mask',near, ...
    'uncertain_mask',uncertain,'indeterminate_mask',indeterminate, ...
    'stable',sum(stable),'unstable',sum(unstable),'near',sum(near), ...
    'uncertain',sum(uncertain),'indeterminate',sum(indeterminate), ...
    'minimum_distance',min(distance),'residual',residual,'tolerance',tol, ...
    'inner',inner,'outer',outer);
end
