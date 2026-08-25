function [rows,details] = neg_v4(seed,frame,c,good_cr)
%NEG_V4 Run V3 negatives and the complete V4 CR-negative ladder.
% Purpose:
%   Preserve all 16 live-object negatives while routing both CR mutations
%   through every V4 step.
% Output:
%   rows - The unchanged ordered 16-row rejection ledger.
%   details - Six V4 ladder rows for both CR mutations.

  rows = full_neg(seed,frame,c,good_cr);
  threshold = max(1e-3,100*good_cr);
  details = struct('name',{},'h',{},'defect',{},'threshold',{}, ...
    'base_pass',{},'compare_max',{},'pass',{});
  anti = zeros(1,3); weight = zeros(1,3);
  base_pass = true(1,3); compare_max = zeros(1,3);
  for hi = 1:3
    h = c.v4_cr_h(hi); points = {c.kstar+h,c.kstar-h, ...
      c.kstar+1i*h,c.kstar-1i*h};
    A = cell(1,4); W = cell(1,4);
    for p = 1:4
      node = eval_k_v3('point',points{p},c,frame);
      metric = full_core('compare',node,c);
      base_pass(hi) = base_pass(hi) && metric.pass;
      compare_max(hi) = max(compare_max(hi),LOCAL_metric_max(metric));
      level = node.coarse; A{p} = level.AdefD;
      A{p}(1,1) = A{p}(1,1)+1e3*conj(points{p});
      b = sqrt(1+abs(level.beta_m(:)).^2);
      rw = repmat(sqrt(1./b),2,1);
      amp = b+abs(level.gamma(:)).^2./b;
      cw = repmat(1./sqrt(amp),2,1);
      W{p} = rw.*level.AdefD.*cw.';
      clear node;
    end
    anti(hi) = LOCAL_cr(A,h);
    weight(hi) = LOCAL_cr(W,h);
    details(end+1) = LOCAL_row('antiholomorphic_contamination',h, ...
      anti(hi),threshold,base_pass(hi),compare_max(hi)); %#ok<AGROW>
    details(end+1) = LOCAL_row('k_dependent_physical_weighting',h, ...
      weight(hi),c.cr_tol,base_pass(hi),compare_max(hi)); %#ok<AGROW>
  end
  rows(10).value = min(anti); rows(10).threshold = threshold;
  rows(10).pass = all(base_pass) && rows(10).value > rows(10).threshold;
  rows(10).checker = 'V4_FULL_LADDER_MIN_CR';
  rows(11).value = min(weight); rows(11).threshold = c.cr_tol;
  rows(11).pass = all(base_pass) && rows(11).value > rows(11).threshold;
  rows(11).checker = 'V4_FULL_LADDER_MIN_CR';
end

%% ==================== V4 negative metrics ====================
% These helpers evaluate central CR rejection signals.

function value = LOCAL_cr(A,h)
  Dx = (A{1}-A{2})/(2*h); Dy = (A{3}-A{4})/(2i*h);
  value = norm(Dx-Dy,'fro')/max([1,norm(Dx,'fro'),norm(Dy,'fro')]);
end

function row = LOCAL_row(name,h,defect,threshold,base_pass,compare_max)
  row = struct('name',name,'h',h,'defect',defect, ...
    'threshold',threshold,'base_pass',base_pass, ...
    'compare_max',compare_max,'pass',base_pass && defect > threshold);
end

function value = LOCAL_metric_max(m)
  value = max([m.block_abs,m.block_action,m.pencil_action, ...
    m.subspace_plus,m.subspace_minus,m.cauchy_plus,m.cauchy_minus, ...
    m.dtn_plus,m.dtn_minus,m.adefD_action,m.adefG_action]);
end
