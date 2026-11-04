function n=inverse_iteration_count(value)
  % INVERSE_ITERATION_COUNT Number of polynomial inverse-guess iterations.
  % Input: optional positive integer; default 18 reproduces qj-cert-v2.
  % Output: iteration budget. Final defect and domain checks remain unchanged.
  persistent count
  if isempty(count),count=18;end
  if nargin>0,assert(isscalar(value)&&value>=1&&value==floor(value));count=value;end
  n=count;
end
