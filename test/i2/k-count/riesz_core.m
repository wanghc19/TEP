function varargout = riesz_core(action,varargin)
%RIESZ_CORE Shared Riesz-action and two-axis screen implementation.
% Purpose:
%   Qualify the fixed-H QZ section through gauge-free original/reversed
%   generalized-pencil Riesz actions without replacing the I1 AdefD object.
% Input:
%   action - 'point', 'edge', or 'oracle'; remaining inputs are action-specific.
% Output:
%   Compact projector/resolvent ledgers plus transient LU state for k edges.
% Main algorithm:
%   Apply nested 16/32 trapezoidal rules with the mandatory zeta weight,
%   test restricted idempotence and QZ parity, and reuse LU factors for the
%   sampled two-direction k-edge Neumann guards.
% Based on:
%   implementation/i2/design.md, Sections 4, 6, 8, and 9.
% Numerical goal:
%   Empirically screen chart and resolvent poles before interpreting AdefD.

  action = lower(char(action));
  switch action
    case 'point'
      [varargout{1:nargout}] = LOCAL_point(varargin{:});
    case 'edge'
      [varargout{1:nargout}] = LOCAL_edge(varargin{:});
    case 'oracle'
      [varargout{1:nargout}] = LOCAL_oracle(varargin{:});
    otherwise
      error('i21:RieszCoreAction','Unknown riesz_core action %s.',action);
  end
end

%% ==================== Physical point qualification ====================
% This group forms only projector actions and compact scalar evidence.

function out = LOCAL_point(node,frame,c,node_index)
  plus = LOCAL_side(node.pair.A,node.pair.B,frame.Z0_plus, ...
    frame.rows_plus,node.Zp,'plus',c,node_index);
  minus = LOCAL_side(node.pair.B,node.pair.A,frame.Z0_minus, ...
    frame.rows_minus,node.Zm,'minus',c,node_index);
  out = struct('plus',plus,'minus',minus, ...
    'resolvents',[plus.resolvents;minus.resolvents], ...
    'zeta_arcs',[plus.zeta_arcs;minus.zeta_arcs], ...
    'projectors',[plus.projector_rows;minus.projector_rows], ...
    'state',struct('A',node.pair.A,'B',node.pair.B, ...
    'plus_factors',{plus.factors},'minus_factors',{minus.factors}, ...
    'node_index',node_index), ...
    'resolvent_pass',plus.resolvent_pass && minus.resolvent_pass, ...
    'chart_pass',plus.chart_pass && minus.chart_pass, ...
    'pass',plus.pass && minus.pass);
end

function out = LOCAL_side(A,B,Z0,rows,Zqz,side,c,node_index)
  if strcmp(side,'plus')
    first = A; second = B;
  else
    first = A; second = B;
  end
  actions = LOCAL_actions(first,second,Z0,side,c,node_index);
  W16 = actions.W16; W32 = actions.W32;
  factors = actions.factors; operators = actions.operators;
  resolvents = actions.resolvents; zeta_arcs = actions.zeta_arcs;

  [metrics16,C16,Y16,row16,factor16] = LOCAL_section(W16,operators,Z0,rows,Zqz, ...
    side,16,c,node_index);
  [metrics32,C32,Y32,row32,factor32] = LOCAL_section(W32,operators,Z0,rows,Zqz, ...
    side,32,c,node_index);
  action_difference = norm(W32-W16,'fro')/max(1,norm(W32,'fro'));
  section_difference = norm(Y32-Y16,'fro')/max(1,norm(Y32,'fro'));
  [c_update,~,c_solve_pass] = count_core('solve',factor32,C32-C16, ...
    c.small_solve_residual_tol);
  c_difference = norm(c_update,2);
  common_pass = c_solve_pass && action_difference <= c.projector_tol && ...
    section_difference <= c.projector_tol && c_difference < c.c_quadrature_guard;
  row16.action_nested_difference = action_difference;
  row16.section_nested_difference = section_difference;
  row16.c_relative_difference = c_difference;
  row16.common_pass = common_pass;
  row16.pass = row16.pass && common_pass;
  row32.action_nested_difference = action_difference;
  row32.section_nested_difference = section_difference;
  row32.c_relative_difference = c_difference;
  row32.common_pass = common_pass;
  row32.pass = row32.pass && common_pass;
  out = struct('W16',W16,'W32',W32,'C16',C16,'C32',C32, ...
    'Y16',Y16,'Y32',Y32,'metrics16',metrics16,'metrics32',metrics32, ...
    'C16_det',row16.det,'C32_det',row32.det, ...
    'resolvents',resolvents,'zeta_arcs',zeta_arcs, ...
    'projector_rows',[LOCAL_strip_det(row16);LOCAL_strip_det(row32)], ...
    'factors',{LOCAL_strip_matrices(factors)}, ...
    'resolvent_pass',all([resolvents.available]) && all([zeta_arcs.pass]), ...
    'chart_pass',row16.pass && row32.pass,'pass', ...
    all([resolvents.available]) && all([zeta_arcs.pass]) && ...
    row16.pass && row32.pass);
end

function out = LOCAL_actions(first,second,Z0,side,c,node_index)
  count = c.Nzeta_full; W32 = zeros(size(Z0)); W16 = zeros(size(Z0));
  factors = cell(1,count); operators = cell(1,count);
  resolvents = LOCAL_empty_resolvents(); zeta_arcs = LOCAL_empty_zeta_arcs();
  for j = 1:count
    zeta = c.zeta_nodes(j); M = zeta*second-first; G = second;
    object = sprintf('resolvent_%s_zeta_%02d',side,j-1);
    [detrow,factor] = count_core('lu',M,object,node_index, ...
      c.resolvent_rcond_min,c);
    [X,residual,solve_pass] = count_core('solve',factor,G, ...
      c.resolvent_solve_residual_max);
    available = detrow.available && solve_pass;
    detrow.available = available; factor.row.available = available;
    operators{j} = X; factors{j} = factor;
    arc_value = c.zeta_half_chord*norm(X,1);
    arc_pass = available && isfinite(arc_value) && ...
      arc_value < c.zeta_arc_guard;
    resolvents(end+1) = LOCAL_resolvent_row(detrow,side,j-1,zeta, ...
      residual,c.resolvent_solve_residual_max,available); %#ok<AGROW>
    zeta_arcs(end+1) = struct('node_index',node_index,'side',side, ...
      'zeta_index',j-1,'zeta_real',real(zeta),'zeta_imag',imag(zeta), ...
      'guard_value',arc_value,'guard_max',c.zeta_arc_guard, ...
      'pass',arc_pass); %#ok<AGROW>
    if available
      contribution = zeta*(X*Z0);
      W32 = W32+contribution/c.Nzeta_full;
      if mod(j-1,2) == 0, W16 = W16+contribution/c.Nzeta_nested; end
    end
  end
  factors = LOCAL_pack_factors(factors);
  out = struct('W16',W16,'W32',W32,'factors',{factors}, ...
    'operators',{operators},'resolvents',resolvents,'zeta_arcs',zeta_arcs);
end

function [metrics,C,Y,row,c_factor] = ...
    LOCAL_section(W,operators,Z0,rows,Zqz,side,N,c,node_index)
  C = W(rows,:);
  object = sprintf('C_%s_%d',side,N);
  [detrow,c_factor] = count_core('lu',C,object,node_index, ...
    c.factor_rcond_min,c);
  if ~detrow.available
    Y = NaN(size(W));
    metrics = struct('restricted_idempotence',Inf, ...
      'section_invariance',Inf,'qz_difference',Inf, ...
      'range_difference',Inf,'fixed_row_residual',Inf);
    row = LOCAL_projector_row(node_index,side,N,metrics,false,detrow);
    return;
  end
  [Y,c_solve_residual,c_solve_pass] = count_core('right_solve', ...
    c_factor,W,c.small_solve_residual_tol);
  if ~c_solve_pass
    Y = NaN(size(W));
    metrics = struct('restricted_idempotence',Inf, ...
      'section_invariance',Inf,'qz_difference',Inf, ...
      'range_difference',Inf,'fixed_row_residual',c_solve_residual);
    row = LOCAL_projector_row(node_index,side,N,metrics,false,detrow);
    return;
  end
  use = 1:(c.Nzeta_full/N):c.Nzeta_full;
  PW = zeros(size(W)); PY = zeros(size(Y));
  for j = use
    zeta = c.zeta_nodes(j); X = operators{j};
    PW = PW+zeta*(X*W)/N;
    PY = PY+zeta*(X*Y)/N;
  end
  restricted_idempotence = norm(PW-W,'fro')/max(1,norm(W,'fro'));
  section_invariance = norm(PY-Y,'fro')/max(1,norm(Y,'fro'));
  qz_difference = norm(Y-Zqz,'fro')/max(1,norm(Zqz,'fro'));
  [Qy,~] = qr(Y,0); [Qz,~] = qr(Zqz,0);
  overlap = svd(Qy'*Qz,'econ');
  range_difference = sqrt(max(0,1-min(overlap)^2));
  fixed_row_residual = norm(Y(rows,:)-eye(numel(rows)),'fro')/sqrt(numel(rows));
  finite = all(isfinite([restricted_idempotence,section_invariance, ...
    qz_difference,range_difference,fixed_row_residual]));
  qz_pass = true;
  if N == c.Nzeta_full
    qz_pass = qz_difference <= c.projector_tol && ...
      range_difference <= c.projector_tol && ...
      fixed_row_residual <= c.small_solve_residual_tol;
  end
  pass = detrow.available && c_solve_pass && finite && ...
    restricted_idempotence <= c.projector_tol && ...
    section_invariance <= c.projector_tol && ...
    qz_pass;
  metrics = struct('restricted_idempotence',restricted_idempotence, ...
    'section_invariance',section_invariance,'qz_difference',qz_difference, ...
    'range_difference',range_difference, ...
    'fixed_row_residual',fixed_row_residual);
  row = LOCAL_projector_row(node_index,side,N,metrics,pass,detrow);
end

%% ==================== Adjacent k-edge screen ====================
% This group applies both Neumann directions using retained endpoint factors.

function rows = LOCAL_edge(left,right,c)
  rows = LOCAL_empty_k_arcs();
  sides = {'plus','minus'};
  for s = 1:2
    name = sides{s};
    if strcmp(name,'plus')
      left_factors = left.plus_factors; right_factors = right.plus_factors;
      left_first = left.A; left_second = left.B;
      right_first = right.A; right_second = right.B;
    else
      left_factors = left.minus_factors; right_factors = right.minus_factors;
      left_first = left.B; left_second = left.A;
      right_first = right.B; right_second = right.A;
    end
    for j = 1:c.Nzeta_full
      zeta = c.zeta_nodes(j);
      Ml = zeta*left_second-left_first;
      Mr = zeta*right_second-right_first;
      delta = Mr-Ml;
      left_factor = LOCAL_restore_matrix(left_factors{j},Ml);
      right_factor = LOCAL_restore_matrix(right_factors{j},Mr);
      [Xf,rf,pf] = count_core('solve',left_factor,delta, ...
        c.resolvent_solve_residual_max);
      [Xb,rb,pb] = count_core('solve',right_factor,-delta, ...
        c.resolvent_solve_residual_max);
      forward = norm(Xf,1); backward = norm(Xb,1);
      pass = pf && pb && isfinite(forward) && isfinite(backward) && ...
        forward < c.k_arc_guard && backward < c.k_arc_guard;
      rows(end+1) = struct('from_node',left.node_index, ...
        'to_node',right.node_index,'side',name,'zeta_index',j-1, ...
        'forward_ratio',forward,'backward_ratio',backward, ...
        'forward_residual',rf,'backward_residual',rb, ...
        'guard_max',c.k_arc_guard,'pass',pass); %#ok<AGROW>
    end
  end
end

%% ==================== Manufactured Riesz oracle ====================
% This group invokes the same weighted action arithmetic on an exact pencil.

function out = LOCAL_oracle(A,B,c)
  Z = eye(size(A)); eplus = Z(:,1); eminus = Z(:,end);
  plus = LOCAL_side(A,B,eplus,1,eplus,'oracle_plus',c,-1);
  minus = LOCAL_side(B,A,eminus,size(A,1),eminus, ...
    'oracle_minus',c,-1);
  full_plus = LOCAL_actions(A,B,Z,'oracle_full_plus',c,-1);
  full_minus = LOCAL_actions(B,A,Z,'oracle_full_minus',c,-1);
  noweight16 = zeros(size(A)); noweight32 = zeros(size(A));
  for j = 1:c.Nzeta_full
    X = full_plus.operators{j};
    noweight32 = noweight32+(X*Z)/c.Nzeta_full;
    if mod(j-1,2) == 0
      noweight16 = noweight16+(X*Z)/c.Nzeta_nested;
    end
  end
  out = struct('plus16',full_plus.W16,'plus32',full_plus.W32, ...
    'minus16',full_minus.W16,'minus32',full_minus.W32, ...
    'no_weight16',noweight16,'no_weight32',noweight32, ...
    'resolvents',[plus.resolvents;minus.resolvents], ...
    'zeta_arcs',[plus.zeta_arcs;minus.zeta_arcs], ...
    'plus_projectors',plus.projector_rows, ...
    'minus_projectors',minus.projector_rows, ...
    'solve_pass',all([plus.resolvents.available]) && ...
    all([minus.resolvents.available]));
end

%% ==================== Ledger constructors ====================
% These helpers keep dense factors out of persistent evidence.

function row = LOCAL_resolvent_row(detrow,side,j,zeta,residual,rmax,available)
  row = struct('node_index',detrow.node_index,'side',side,'zeta_index',j, ...
    'zeta_real',real(zeta),'zeta_imag',imag(zeta),'object',detrow.object, ...
    'order',detrow.order,'rcond',detrow.rcond,'rcond_min',detrow.rcond_min, ...
    'lu_residual',detrow.lu_residual,'solve_residual',residual, ...
    'solve_residual_max',rmax,'relative_pivot',detrow.relative_pivot, ...
    'permutation_parity',detrow.permutation_parity, ...
    'logabsdet',detrow.logabsdet,'phase',detrow.phase, ...
    'phase_uncertainty',detrow.phase_uncertainty, ...
    'finite',detrow.finite,'available',available);
end

function row = LOCAL_strip_det(row)
  row = rmfield(row,'det');
end

function row = LOCAL_projector_row(node_index,side,N,m,pass,detrow)
  row = struct('node_index',node_index,'side',side,'Nzeta',N, ...
    'restricted_idempotence',m.restricted_idempotence, ...
    'section_invariance',m.section_invariance, ...
    'qz_difference',m.qz_difference,'range_difference',m.range_difference, ...
    'fixed_row_residual',m.fixed_row_residual, ...
    'action_nested_difference',NaN,'section_nested_difference',NaN, ...
    'c_relative_difference',NaN,'common_pass',false,'pass',pass,'det',detrow);
end

function factors = LOCAL_strip_matrices(factors)
  for j = 1:numel(factors)
    factors{j}.matrix = [];
  end
end

function factors = LOCAL_pack_factors(factors)
  for j = 1:numel(factors)
    if ~isempty(factors{j}.L)
      factors{j}.LU = tril(factors{j}.L,-1)+factors{j}.U;
    else
      factors{j}.LU = [];
    end
    factors{j}.L = [];
    factors{j}.U = [];
    factors{j}.matrix = [];
  end
end

function factor = LOCAL_restore_matrix(factor,M)
  factor.matrix = M;
end

function rows = LOCAL_empty_resolvents()
  rows = struct('node_index',{},'side',{},'zeta_index',{},'zeta_real',{}, ...
    'zeta_imag',{},'object',{},'order',{},'rcond',{},'rcond_min',{}, ...
    'lu_residual',{},'solve_residual',{},'solve_residual_max',{}, ...
    'relative_pivot',{},'permutation_parity',{},'logabsdet',{},'phase',{}, ...
    'phase_uncertainty',{},'finite',{},'available',{});
end

function rows = LOCAL_empty_zeta_arcs()
  rows = struct('node_index',{},'side',{},'zeta_index',{},'zeta_real',{}, ...
    'zeta_imag',{},'guard_value',{},'guard_max',{},'pass',{});
end

function rows = LOCAL_empty_k_arcs()
  rows = struct('from_node',{},'to_node',{},'side',{},'zeta_index',{}, ...
    'forward_ratio',{},'backward_ratio',{},'forward_residual',{}, ...
    'backward_residual',{},'guard_max',{},'pass',{});
end
