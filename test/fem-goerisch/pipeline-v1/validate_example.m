function check=validate_example(e)
  % VALIDATE_EXAMPLE Reject unsupported changes before search or mesh generation.
  % Input
  %   e: explicit example struct, normally returned by examples/example_ref.m.
  % Output
  %   Supported-family status and whether the reference regression is applicable.
  ref=example_ref();
  assert(isfield(e,'model')&&isfield(e.model,'rho_center'),'pipeline:Example','Missing model.rho_center.');
  rho=e.model.rho_center;
  assert(isscalar(rho)&&isreal(rho)&&isfinite(rho)&&rho>ref.model.rho_background, ...
    'pipeline:Contrast','v1 requires rho_center > rho_background: signed mass-bias bounds and inner-element classification need positive contrast.');
  e.model.rho_center=ref.model.rho_center;
  LOCAL_compare(e,ref,'example');
  check=struct('supported',true,'reference_regression',rho==ref.model.rho_center, ...
    'rho_center',rho,'support','reference geometry/leads/windows/discretization; positive center contrast only');
end
function LOCAL_compare(a,b,path)
  % Input: supplied/reference values and their path. Output: error at first mismatch.
  if isstruct(a)&&isstruct(b)&&isscalar(a)&&isscalar(b)
    assert(isequal(sort(fieldnames(a)),sort(fieldnames(b))),'pipeline:Unsupported', ...
      'Unsupported %s fields: v1 has no generalized geometry/lead/discretization handoff.',path);
    names=fieldnames(b);
    for j=1:numel(names),name=names{j};LOCAL_compare(a.(name),b.(name),[path,'.',name]);end
  else
    assert(isequaln(a,b),'pipeline:Unsupported', ...
      'Unsupported change at %s: analytic curve bounds, unit-cell coordinates, leads, windows and discretization are tied to example_ref in v1.',path);
  end
end
