function varargout = count_core(action,varargin)
%COUNT_CORE Shared stable LU and winding implementation for I2.1.
% Purpose:
%   Provide the sole factorization, solve, phase, closure, and argument-
%   principle arithmetic used by manufactured oracles and physical factors.
% Input:
%   action - 'lu', 'solve', 'right_solve', or 'winding'; remaining inputs
%   are action-specific.
% Output:
%   Compact diagnostics and, only in memory, reusable LU factors.
% Main algorithm:
%   Use PF=LU with permutation parity, accumulate wrapped adjacent phase
%   increments including closure, and fail closed on every reliability gate.
% Based on:
%   implementation/i2/design.md, Sections 7--10.
% Numerical goal:
%   Count determinant zeros without forming a raw determinant.

  action = lower(char(action));
  switch action
    case 'lu'
      [varargout{1:nargout}] = LOCAL_lu(varargin{:});
    case 'solve'
      [varargout{1:nargout}] = LOCAL_solve(varargin{:});
    case 'right_solve'
      [varargout{1:nargout}] = LOCAL_right_solve(varargin{:});
    case 'winding'
      [varargout{1:nargout}] = LOCAL_winding(varargin{:});
    otherwise
      error('i21:CountCoreAction','Unknown count_core action %s.',action);
  end
end

%% ==================== Stable determinant data ====================
% This group factors one square matrix and retains exact permutation parity.

function [row,factor] = LOCAL_lu(F,object,node_index,rcond_min,c)
  if size(F,1) ~= size(F,2)
    error('i21:NonSquareFactor','%s is not square.',object);
  end
  m = size(F,1);
  finite_input = all(isfinite(F),'all');
  if finite_input
    [L,U,p] = lu(F,'vector');
    lu_residual = norm(F(p,:)-L*U,'fro')/max(1,norm(F,'fro'));
    rcond_value = rcond(F);
    diagonal = diag(U);
    relative_pivot = min(abs(diagonal))/max(realmin,norm(F,inf));
    parity = LOCAL_parity(p);
    logabs = sum(log(abs(diagonal)));
    phase = angle(complex(parity,0)*prod(diagonal./max(realmin,abs(diagonal))));
  else
    L = []; U = []; p = []; lu_residual = Inf; rcond_value = 0;
    relative_pivot = 0; parity = 0; logabs = NaN; phase = NaN;
  end
  if rcond_value > 0 && isfinite(lu_residual)
    delta = min(pi,m*max(m*eps,lu_residual)/rcond_value);
  else
    delta = pi;
  end
  available = finite_input && all(isfinite([lu_residual,rcond_value, ...
    relative_pivot,logabs,phase,delta])) && rcond_value >= rcond_min && ...
    relative_pivot > 0 && delta <= c.phase_uncertainty_max;
  row = struct('node_index',node_index,'object',object,'order',m, ...
    'rcond',rcond_value,'rcond_min',rcond_min, ...
    'lu_residual',lu_residual,'relative_pivot',relative_pivot, ...
    'permutation_parity',parity,'logabsdet',logabs,'phase',phase, ...
    'phase_uncertainty',delta,'finite',finite_input,'available',available);
  factor = struct('L',L,'U',U,'p',p,'matrix',F,'row',row);
end

function parity = LOCAL_parity(p)
  n = numel(p); visited = false(n,1); cycles = 0;
  for j = 1:n
    if visited(j), continue; end
    cycles = cycles+1; q = j;
    while ~visited(q)
      visited(q) = true; q = p(q);
    end
  end
  parity = 1-2*mod(n-cycles,2);
end

%% ==================== Reused LU solves ====================
% This group applies one retained factor and checks the frozen backward error.

function [X,residual,pass] = LOCAL_solve(factor,G,residual_max)
  has_split = isfield(factor,'L') && ~isempty(factor.L);
  has_packed = isfield(factor,'LU') && ~isempty(factor.LU);
  if ~factor.row.available || ~(has_split || has_packed)
    X = NaN(size(G)); residual = Inf; pass = false; return;
  end
  if has_split
    L = factor.L; U = factor.U;
  else
    L = tril(factor.LU,-1)+eye(size(factor.LU),class(factor.LU));
    U = triu(factor.LU);
  end
  X = U\(L\G(factor.p,:));
  M = factor.matrix;
  residual = norm(M*X-G,'fro')/max(1, ...
    norm(M,'fro')*norm(X,'fro')+norm(G,'fro'));
  pass = all(isfinite(X),'all') && isfinite(residual) && ...
    residual <= residual_max;
end

function [X,residual,pass] = LOCAL_right_solve(factor,G,residual_max)
  has_split = isfield(factor,'L') && ~isempty(factor.L);
  has_packed = isfield(factor,'LU') && ~isempty(factor.LU);
  if ~factor.row.available || ~(has_split || has_packed)
    X = NaN(size(G)); residual = Inf; pass = false; return;
  end
  if has_split
    L = factor.L; U = factor.U;
  else
    L = tril(factor.LU,-1)+eye(size(factor.LU),class(factor.LU));
    U = triu(factor.LU);
  end
  transpose_solution = L.'\(U.'\G.');
  Xtranspose = zeros(size(transpose_solution),'like',transpose_solution);
  Xtranspose(factor.p,:) = transpose_solution;
  X = Xtranspose.';
  M = factor.matrix;
  residual = norm(X*M-G,'fro')/max(1, ...
    norm(M,'fro')*norm(X,'fro')+norm(G,'fro'));
  pass = all(isfinite(X),'all') && isfinite(residual) && ...
    residual <= residual_max;
end

%% ==================== Winding and closure ====================
% This group uses only LU phases and their frozen empirical uncertainties.

function [summary,edges] = LOCAL_winding(records,indices,object,c)
  records = records(indices); records = records(:);
  count_n = numel(records);
  edges = struct('object',{},'from_node',{},'to_node',{}, ...
    'phase_increment',{},'uncertainty_sum',{},'guard_value',{}, ...
    'guard_max',{},'pass',{});
  available = count_n >= 2 && all([records.available]);
  if ~available
    summary = struct('object',object,'node_count',count_n, ...
      'raw_count',NaN,'rounded_count',NaN,'integer_residual',NaN, ...
      'integer_residual_max',c.integer_residual_max, ...
      'max_edge_guard',Inf,'edge_guard_max',c.edge_phase_guard, ...
      'available',false,'pass',false);
    return;
  end
  total = 0; edge_pass = available;
  for j = 1:count_n
    q = mod(j,count_n)+1;
    increment = angle(exp(1i*(records(q).phase-records(j).phase)));
    uncertainty = records(j).phase_uncertainty+records(q).phase_uncertainty;
    guard = abs(increment)+uncertainty;
    pass = available && isfinite(guard) && guard < c.edge_phase_guard;
    edges(end+1) = struct('object',object, ...
      'from_node',records(j).node_index,'to_node',records(q).node_index, ...
      'phase_increment',increment,'uncertainty_sum',uncertainty, ...
      'guard_value',guard,'guard_max',c.edge_phase_guard,'pass',pass); %#ok<AGROW>
    total = total+increment; edge_pass = edge_pass && pass;
  end
  raw = total/(2*pi); rounded = round(raw);
  integer_residual = abs(raw-rounded);
  pass = available && edge_pass && isfinite(raw) && ...
    integer_residual <= c.integer_residual_max;
  summary = struct('object',object,'node_count',count_n, ...
    'raw_count',raw,'rounded_count',rounded, ...
    'integer_residual',integer_residual, ...
    'integer_residual_max',c.integer_residual_max, ...
    'max_edge_guard',LOCAL_max_guard(edges), ...
    'edge_guard_max',c.edge_phase_guard,'available',available,'pass',pass);
  edges = edges(:);
end

function value = LOCAL_max_guard(rows)
  if isempty(rows), value = Inf; else, value = max([rows.guard_value]); end
end
