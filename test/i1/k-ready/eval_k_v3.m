function varargout = eval_k_v3(action, varargin)
%EVAL_K_V3 Evaluate the I1.4 V3 family with the corrected lift gate.
% Purpose:
%   Reuse the complete V2 evaluator, then replace only its graph-lift
%   residual gate by separate Dirichlet and Neumann consistency defects.
% Input:
%   action - 'seed' or 'point', with the same arguments as eval_k_v2.
% Output:
%   seed returns a requalified node and V2 frame; point returns a requalified
%   node.  Each participation struct records eD, eN, and kernel_defect.
% Main algorithm:
%   Recompute the minimum direction and graph lift from AdefD, Dm, and Dp;
%   evaluate the fixed-row defects; then recompute every level pass from the
%   unchanged V2 gates and the replacement lift gate.
% Based on:
%   eval_k_v2.m.
% Numerical goal:
%   Correct the lift consistency test without changing any other V2 result.

  action = lower(char(action));
  if strcmp(action,'seed')
    c = varargin{1};
    [node,frame] = eval_k_v2(action,varargin{:});
    node = LOCAL_requalify_pair(node,c);
    varargout = {node,frame};
  elseif strcmp(action,'point')
    c = varargin{2};
    node = eval_k_v2(action,varargin{:});
    node = LOCAL_requalify_pair(node,c);
    varargout = {node};
  else
    error('kreadyv3:Action','Unknown action %s.',action);
  end
end

%% ==================== V3 lift requalification ====================
% These helpers replace only the old aggregate lift residual gate.

function node = LOCAL_requalify_pair(node,c)
  node.coarse = LOCAL_requalify(node.coarse,c);
  node.fine = LOCAL_requalify(node.fine,c);
  node.pass = node.coarse.pass && node.fine.pass;
end

function level = LOCAL_requalify(level,c)
  K = c.K;
  [~,~,Vd] = svd(level.AdefD,'econ');
  q = Vd(:,end);
  I = eye(K); E = diag(level.phase(:));
  cminus = level.Dm\([I,E]*q);
  cplus = level.Dp\([E,I]*q);
  z = [q;cminus;cplus];
  drow = [1:K,2*K+1:3*K];
  nrow = [K+1:2*K,3*K+1:4*K];
  Gd = level.AdefG(drow,:);
  Gn = level.AdefG(nrow,:);
  eD = norm(Gd*z,2)/max(1,norm(Gd,2)*norm(z,2));
  eN = norm(Gn*z-level.AdefD*q,2)/max(1, ...
    norm(Gn,2)*norm(z,2)+norm(level.AdefD,2)*norm(q,2));
  kernel_defect = norm(level.AdefG*z,2)/max(1, ...
    norm(level.AdefG,'fro')*norm(z,2));
  level.participation.dirichlet_defect = eD;
  level.participation.neumann_defect = eN;
  level.participation.residual = max(eD,eN);
  level.participation.kernel_defect = kernel_defect;
  level.pass = level.plus.pass && level.minus.pass && ...
    level.branch_port.pass && level.branch_proxy.pass && ...
    level.cp.safe && level.cm.safe && ...
    level.row.plus_margin > c.chart_margin_min && ...
    level.row.minus_margin > c.chart_margin_min && ...
    level.row.plus_condition*eps <= c.chart_condition_eps_tol && ...
    level.row.minus_condition*eps <= c.chart_condition_eps_tol && ...
    level.schur <= c.schur_tol && ...
    level.participation.center >= c.participation_min && ...
    level.participation.graph >= c.participation_min && ...
    level.participation.residual <= c.lift_residual_tol && ...
    all([level.factors.pass]);
  if level.pass
    level.reason = 'PASS';
  else
    level.reason = 'SCIENTIFIC_GATE';
  end
end
