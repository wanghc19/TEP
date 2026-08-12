function out = core_v4(k,frame,c)
%CORE_V4 Evaluate one complete V4 full-matrix CR ladder.
% Purpose:
%   Apply the frozen 4r0, 2r0, r0 CR ladder at one complex center.
% Input:
%   k, frame, c - Evaluation center, frozen V3 frame, and V4 configuration.
% Output:
%   out - Four rows for two levels and AdefD/AdefG.
% Main algorithm:
%   Stream twelve shifted points, gate each point and coarse/fine comparison,
%   then retain only full-matrix derivatives and scalar diagnostics.

  levels = {'coarse','fine'}; objects = {'AdefD','AdefG'};
  Dx = cell(3,2,2); Dy = cell(3,2,2);
  shift_pass = true; compare_max = 0;
  for hi = 1:3
    h = c.v4_cr_h(hi);
    points = {k+h,k-h,k+1i*h,k-1i*h};
    matrices = cell(4,2,2);
    for p = 1:4
      node = eval_k_v3('point',points{p},c,frame);
      metric = full_core('compare',node,c);
      shift_pass = shift_pass && metric.pass;
      compare_max = max(compare_max,LOCAL_metric_max(metric));
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
  out = struct('level',{},'object',{},'h4',{},'h2',{},'h1',{}, ...
    'cr4',{},'cr2',{},'cr1',{},'dx42',{},'dx21',{},'dy42',{}, ...
    'dy21',{},'shift_pass',{},'compare_max',{},'domain_pass',{},'pass',{});
  for l = 1:2
    for o = 1:2
      cr = zeros(1,3);
      for hi = 1:3
        cr(hi) = norm(Dx{hi,l,o}-Dy{hi,l,o},'fro')/ ...
          max([1,norm(Dx{hi,l,o},'fro'),norm(Dy{hi,l,o},'fro')]);
      end
      changes = [LOCAL_rel(Dx{2,l,o},Dx{1,l,o}), ...
        LOCAL_rel(Dx{3,l,o},Dx{2,l,o}), ...
        LOCAL_rel(Dy{2,l,o},Dy{1,l,o}), ...
        LOCAL_rel(Dy{3,l,o},Dy{2,l,o})];
      pass = shift_pass && c.v4_branch_domain_pass && ...
        all(cr <= c.cr_tol) && all(changes <= c.v4_cr_change_tol);
      out(end+1) = struct('level',levels{l},'object',objects{o}, ...
        'h4',c.v4_cr_h(1),'h2',c.v4_cr_h(2),'h1',c.v4_cr_h(3), ...
        'cr4',cr(1),'cr2',cr(2),'cr1',cr(3),'dx42',changes(1), ...
        'dx21',changes(2),'dy42',changes(3),'dy21',changes(4), ...
        'shift_pass',shift_pass,'compare_max',compare_max, ...
        'domain_pass',c.v4_branch_domain_pass,'pass',pass); %#ok<AGROW>
    end
  end
end

%% ==================== V4 metrics ====================
% These helpers use the already frozen full-run normalizations.

function value = LOCAL_metric_max(m)
  value = max([m.block_abs,m.block_action,m.pencil_action, ...
    m.subspace_plus,m.subspace_minus,m.cauchy_plus,m.cauchy_minus, ...
    m.dtn_plus,m.dtn_minus,m.adefD_action,m.adefG_action]);
end

function value = LOCAL_rel(A,B)
  value = norm(A-B,'fro')/max(1,norm(B,'fro'));
end
