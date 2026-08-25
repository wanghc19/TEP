function varargout = full_core(action, varargin)
%FULL_CORE Provide streamed comparisons, CR checks, and compact ledgers.
% Purpose:
%   Keep run_full short while applying the frozen full-run scientific gates
%   to one V3 node or one four-shift full-matrix CR stencil.
% Input:
%   action - 'compare', 'cr', 'node_rows', 'factor_rows', 'branch_rows',
%   'qz_rows', or 'overlap'.
% Output:
%   Action-specific scalar metrics and compact rows.
% Main algorithm:
%   Compare coarse/fine objects in weighted coordinates and differentiate
%   the complete unbalanced AdefD/AdefG matrices with central differences.

  action = lower(char(action));
  switch action
    case 'compare'
      varargout = {LOCAL_compare(varargin{:})};
    case 'cr'
      varargout = {LOCAL_cr(varargin{:})};
    case 'node_rows'
      varargout = {LOCAL_node_rows(varargin{:})};
    case 'factor_rows'
      varargout = {LOCAL_factor_rows(varargin{:})};
    case 'branch_rows'
      varargout = {LOCAL_branch_rows(varargin{:})};
    case 'qz_rows'
      varargout = {LOCAL_qz_rows(varargin{:})};
    case 'overlap'
      [varargout{1:nargout}] = LOCAL_overlap(varargin{:});
    otherwise
      error('kreadyfull:Action','Unknown full_core action %s.',action);
  end
end

%% ==================== Coarse/fine comparison ====================
% These helpers apply all inherited I1 pointwise two-level gates.

function m = LOCAL_compare(node,c)
  a = node.coarse; b = node.fine;
  names = {'R_L','T_RL','T_LR','R_R'};
  m.block_abs = 0; m.block_action = 0;
  for j = 1:4
    A = a.blocks.(names{j}); B = b.blocks.(names{j});
    m.block_abs = max(m.block_abs,max(abs(A-B),[],'all'));
    m.block_action = max(m.block_action,LOCAL_weighted_block(A,B,b.beta_m));
  end
  m.pencil_action = LOCAL_weighted_pair(a.pair,b.pair,b.beta_m);
  [~,m.subspace_plus] = LOCAL_overlap(a.plus.Z,b.plus.Z);
  [~,m.subspace_minus] = LOCAL_overlap(a.minus.Z,b.minus.Z);
  [~,m.cauchy_plus] = LOCAL_overlap(LOCAL_cauchy(a.Dp,a.Np,a.beta_m), ...
    LOCAL_cauchy(b.Dp,b.Np,b.beta_m));
  [~,m.cauchy_minus] = LOCAL_overlap(LOCAL_cauchy(a.Dm,a.Nm,a.beta_m), ...
    LOCAL_cauchy(b.Dm,b.Nm,b.beta_m));
  m.dtn_plus = LOCAL_rel(a.cp.Lambda,b.cp.Lambda);
  m.dtn_minus = LOCAL_rel(a.cm.Lambda,b.cm.Lambda);
  m.adefD_action = LOCAL_rel(a.AdefD,b.AdefD);
  m.adefG_action = LOCAL_rel(a.AdefG,b.AdefG);
  m.pass = node.pass && m.block_abs <= c.block_abs_tol && ...
    m.block_action <= c.action_tol && m.pencil_action <= c.action_tol && ...
    max([m.subspace_plus,m.subspace_minus,m.cauchy_plus, ...
    m.cauchy_minus]) <= c.subspace_tol && ...
    max(m.dtn_plus,m.dtn_minus) <= c.action_tol && ...
    max(m.adefD_action,m.adefG_action) <= c.action_tol;
end

function C = LOCAL_cauchy(D,N,beta_m)
  b = sqrt(1+abs(beta_m(:)).^2);
  C = [sqrt(b).*D;(1./sqrt(b)).*N];
end

%% ==================== Full-matrix CR ====================
% This helper evaluates one node and three four-shift stencils serially.

function out = LOCAL_cr(k,frame,c,h0)
  levels = {'coarse','fine'}; objects = {'AdefD','AdefG'};
  out = struct('level',{},'object',{},'h0',{},'cr_h0',{},'cr_h1',{}, ...
    'cr_h2',{},'spread_x',{},'spread_y',{},'trend_pass',{}, ...
    'shift_compare_pass',{},'shift_compare_max',{},'pass',{});
  Dx = cell(3,2,2); Dy = cell(3,2,2);
  shift_compare_pass = true;
  shift_compare_max = 0;
  for hi = 1:3
    h = h0*c.cr_h_ratios(hi);
    points = {k+h,k-h,k+1i*h,k-1i*h};
    matrices = cell(4,2,2);
    for p = 1:4
      node = eval_k_v3('point',points{p},c,frame);
      metric = LOCAL_compare(node,c);
      shift_compare_pass = shift_compare_pass && metric.pass;
      shift_compare_max = max([shift_compare_max,metric.block_abs, ...
        metric.block_action,metric.pencil_action,metric.subspace_plus, ...
        metric.subspace_minus,metric.cauchy_plus,metric.cauchy_minus, ...
        metric.dtn_plus,metric.dtn_minus,metric.adefD_action, ...
        metric.adefG_action]);
      for l = 1:2
        for o = 1:2
          matrices{p,l,o} = node.(levels{l}).(objects{o});
        end
      end
      clear node;
    end
    for l = 1:2
      for o = 1:2
        Dx{hi,l,o} = (matrices{1,l,o}-matrices{2,l,o})/(2*h);
        Dy{hi,l,o} = (matrices{3,l,o}-matrices{4,l,o})/(2i*h);
      end
    end
    clear matrices;
  end
  for l = 1:2
    for o = 1:2
      cr = zeros(1,3);
      for hi = 1:3
        cr(hi) = norm(Dx{hi,l,o}-Dy{hi,l,o},'fro')/ ...
          max([1,norm(Dx{hi,l,o},'fro'),norm(Dy{hi,l,o},'fro')]);
      end
      sx = LOCAL_rel(Dx{3,l,o},Dx{2,l,o});
      sy = LOCAL_rel(Dy{3,l,o},Dy{2,l,o});
      floor_ok = max(cr(2:3)) <= c.cr_rounding_floor && ...
        sx <= c.cr_rounding_floor && sy <= c.cr_rounding_floor;
      trend = cr(3) <= cr(2) || floor_ok;
      pass = cr(3) <= c.cr_tol && sx <= c.cr_two_step_tol && ...
        sy <= c.cr_two_step_tol && trend && shift_compare_pass;
      out(end+1) = struct('level',levels{l},'object',objects{o}, ...
        'h0',h0,'cr_h0',cr(1),'cr_h1',cr(2),'cr_h2',cr(3), ...
        'spread_x',sx,'spread_y',sy,'trend_pass',trend, ...
        'shift_compare_pass',shift_compare_pass, ...
        'shift_compare_max',shift_compare_max,'pass',pass); %#ok<AGROW>
    end
  end
end

%% ==================== Streamed ledgers ====================
% These helpers discard dense arrays and retain all required scalar evidence.

function rows = LOCAL_node_rows(node,index,kind,m,varargin)
  if isempty(varargin), boundary_index = 0; else, boundary_index = varargin{1}; end
  nested16 = boundary_index > 0 && mod(boundary_index-1,2) == 0;
  rows = struct('node_index',{},'kind',{},'boundary_index',{}, ...
    'nested16',{},'level',{},'k_real',{}, ...
    'k_imag',{},'level_pass',{},'comparison_pass',{},'block_abs',{}, ...
    'block_action',{},'pencil_action',{},'subspace_plus',{}, ...
    'subspace_minus',{},'cauchy_plus',{},'cauchy_minus',{}, ...
    'dtn_plus',{},'dtn_minus',{},'adefD_action',{},'adefG_action',{}, ...
    'center_participation',{},'graph_participation',{}, ...
    'dirichlet_defect',{},'neumann_defect',{},'kernel_defect',{});
  levels = {'coarse','fine'};
  for l = 1:2
    x = node.(levels{l}); p = x.participation;
    rows(end+1) = struct('node_index',index,'kind',kind, ...
      'boundary_index',boundary_index,'nested16',nested16,'level',levels{l}, ...
      'k_real',real(node.k),'k_imag',imag(node.k),'level_pass',x.pass, ...
      'comparison_pass',m.pass,'block_abs',m.block_abs, ...
      'block_action',m.block_action,'pencil_action',m.pencil_action, ...
      'subspace_plus',m.subspace_plus,'subspace_minus',m.subspace_minus, ...
      'cauchy_plus',m.cauchy_plus,'cauchy_minus',m.cauchy_minus, ...
      'dtn_plus',m.dtn_plus,'dtn_minus',m.dtn_minus, ...
      'adefD_action',m.adefD_action,'adefG_action',m.adefG_action, ...
      'center_participation',p.center,'graph_participation',p.graph, ...
      'dirichlet_defect',p.dirichlet_defect, ...
      'neumann_defect',p.neumann_defect, ...
      'kernel_defect',p.kernel_defect); %#ok<AGROW>
  end
end

function rows = LOCAL_factor_rows(node,index)
  rows = struct('node_index',{},'level',{},'name',{},'rcond',{}, ...
    'residual',{},'available',{},'rcond_min',{},'residual_max',{},'pass',{});
  levels = {'coarse','fine'};
  for l = 1:2
    factors = node.(levels{l}).factors;
    for f = 1:numel(factors)
      x = factors(f);
      rows(end+1) = struct('node_index',index,'level',levels{l}, ...
        'name',x.name,'rcond',x.rcond,'residual',x.residual, ...
        'available',x.available,'rcond_min',x.rcond_min, ...
        'residual_max',x.residual_max,'pass',x.pass); %#ok<AGROW>
    end
  end
end

function rows = LOCAL_branch_rows(node,index)
  rows = struct('node_index',{},'level',{},'consumer',{},'algebra',{}, ...
    'roundtrip',{},'fingerprint',{},'pass',{});
  levels = {'coarse','fine'}; consumers = {'port','proxy'};
  for l = 1:2
    for b = 1:2
      x = node.(levels{l}).(['branch_',consumers{b}]);
      rows(end+1) = struct('node_index',index,'level',levels{l}, ...
        'consumer',consumers{b},'algebra',x.algebra, ...
        'roundtrip',x.roundtrip,'fingerprint',x.fingerprint, ...
        'pass',x.pass); %#ok<AGROW>
    end
  end
end

function rows = LOCAL_qz_rows(node,index)
  rows = struct('node_index',{},'level',{},'side',{},'raw_residual',{}, ...
    'residual',{},'stable',{},'unstable',{},'neutral',{}, ...
    'indeterminate',{},'score_gap',{},'classification_gap',{}, ...
    'chordal_separation',{},'cluster_tau',{},'overlap',{},'pass',{});
  levels = {'coarse','fine'}; sides = {'plus','minus'};
  for l = 1:2
    for s = 1:2
      x = node.(levels{l}).(sides{s});
      rows(end+1) = struct('node_index',index,'level',levels{l}, ...
        'side',sides{s},'raw_residual',x.raw_residual,'residual',x.residual, ...
        'stable',x.stable_diagnostic,'unstable',x.unstable_diagnostic, ...
        'neutral',x.neutral_count,'indeterminate',x.indeterminate_count, ...
        'score_gap',x.score_gap,'classification_gap',x.classification_gap, ...
        'chordal_separation',x.chordal_separation, ...
        'cluster_tau',x.cluster_tau,'overlap',LOCAL_field(x,'overlap',1), ...
        'pass',x.pass); %#ok<AGROW>
    end
  end
end

%% ==================== Linear-algebra utilities ====================
% These helpers use the inherited weighted-coordinate conventions.

function [overlap,distance] = LOCAL_overlap(A,B)
  [Qa,~] = qr(A,0); [Qb,~] = qr(B,0);
  values = svd(Qa'*Qb,'econ'); overlap = min(values);
  distance = sqrt(max(0,1-overlap^2));
end

function value = LOCAL_weighted_block(A,B,beta_m)
  W = diag((1+abs(beta_m(:)).^2).^(1/4));
  Aw = (W.'\(W*A).').'; Bw = (W.'\(W*B).').';
  value = norm(Aw-Bw,2)/max(1,norm(Bw,2));
end

function value = LOCAL_weighted_pair(A,B,beta_m)
  W = diag((1+abs(beta_m(:)).^2).^(1/4)); W = blkdiag(W,W);
  Aa = (W.'\(W*A.A).').'; Ab = (W.'\(W*A.B).').';
  Ba = (W.'\(W*B.A).').'; Bb = (W.'\(W*B.B).').';
  value = hypot(norm(Aa-Ba,'fro'),norm(Ab-Bb,'fro'))/ ...
    max(1,hypot(norm(Ba,'fro'),norm(Bb,'fro')));
end

function value = LOCAL_rel(A,B)
  value = norm(A-B,'fro')/max(1,norm(B,'fro'));
end

function value = LOCAL_field(s,name,fallback)
  if isfield(s,name), value = s.(name); else, value = fallback; end
end
