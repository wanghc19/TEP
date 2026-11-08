function r=border_field(k,c,q)
  % Evaluate the field specified by the uneliminated bordered null vector.
  % Input: frequency, model configuration and quadrature settings.
  % Output: singular values and three-cell field and off-node jump diagnostics.
  if isfield(q,'full_diagnostics') && q.full_diagnostics,r=original_border_field(k,c,q);return;end
  b=border_data(k,c,true);H=border_matrix(b);[~,S,V]=svd(H,'econ');v=V(:,end);
  n=b.n;K=b.K;v=v/norm(v(n+(1:2*K)));e=b.evidence;
  e.q=v(n+(1:2*K));e.negative_coordinates=v(n+2*K+(1:K));e.positive_coordinates=v(n+3*K+(1:K));
  if n>0,e.center.density=v(1:n)./b.weight;end
  f=physical_checks(e,c,q);
  r=struct('k',k,'sigma',S(end,end),'next_sigma',S(end-1,end-1),'max_sigma',S(1,1), ...
    'field',f,'residual_norm',norm(H*v));
end
