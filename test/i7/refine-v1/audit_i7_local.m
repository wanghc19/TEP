function audit = audit_i7_local(result,evidence)
%AUDIT_I7_LOCAL Check saved local scans without evaluating physical kernels.
% Purpose:
%   Independently check sampled winners, four metrics, and physical traces.
% Input:
%   result, evidence - Outputs of check_i7_refinement(...,'local').
% Output:
%   audit - Consistency residuals and phase/scale invariant trace overlaps.
% Main algorithm:
%   Recompute winner SVDs and align left/right Rayleigh coefficients by m.
% Notes:
%   Same-k overlaps test mode identity. Within-configuration overlaps across
%   k only describe continuity and are not a position error estimate.

  assert(strcmp(result.mode,'LOCAL'));
  nc = numel(result.configs);
  nk = numel(result.k_values);
  assert(isequal(size(result.points),[nc,nk]));
  assert(isequal(size(evidence.point_modes),[nc,nk]));
  metric_error = 0;
  trace_error = 0;
  weight_error = 0;
  comparison_error = 0;
  checked_winners = 0;
  checked_edges = 0;
  overlap = NaN(nc,nk);
  center_overlap = NaN(nc,nk);
  high_mode_fraction = NaN(nc,nk);
  bracket_valid = false(nc,1);
  [~,center_index] = min(abs(result.k_values-result.k0));

  % --- stage 1: verify selection and retained winner matrices ---
  for ic = 1:nc
    rows = result.points(ic,:);
    assert(isequal([rows.k],result.k_values));
    valid = [rows.valid] & isfinite([rows.aphys_ratio]);
    indices = find(valid);
    if isempty(indices)
      assert(~result.best(ic).valid);
      continue;
    end
    [~,j] = min([rows(indices).aphys_ratio]);
    ib = indices(j);
    best = result.best(ic);
    assert(best.grid_index==ib && best.k==rows(ib).k);
    assert(best.boundary_limited==(ib==1 || ib==nk));
    metrics = [rows(ib).adef_sigma,rows(ib).adef_ratio, ...
      rows(ib).aphys_sigma,rows(ib).aphys_ratio];
    saved = [best.adef_sigma,best.adef_ratio, ...
      best.aphys_sigma,best.aphys_ratio];
    assert(isequal(metrics,saved));
    if ib>1 && ib<nk && all(valid([ib-1,ib+1]))
      bracket_valid(ic) = all([rows([ib-1,ib+1]).aphys_ratio]>best.aphys_ratio);
    end
    assert(best.bracket_valid==bracket_valid(ic));
    e = evidence.best_full{ic};
    assert(e.k==best.k && e.config.M==result.configs(ic).M);
    b = sqrt(1+abs(e.beta_m(:)).^2);
    dr = repmat(1./sqrt(b),2,1);
    dc = repmat(1./sqrt(b+abs(e.gamma(:)).^2./b),2,1);
    Aphys = diag(dr)*e.Adef*diag(dc);
    weight_error = max(weight_error,norm(Aphys-e.svd.Aphys,'fro')/ ...
      max(1,norm(Aphys,'fro')));
    trace = e.T*diag(dc)*e.svd.aphys_right_vectors;
    trace_error = max(trace_error,norm(trace-e.svd.physical_trace_vectors,'fro')/ ...
      max(1,norm(trace,'fro')));
    sd = svd(e.Adef); sp = svd(Aphys);
    actual = [sd(end),sd(end)/sd(1),sp(end),sp(end)/sp(1)];
    metric_error = max(metric_error,max(abs(actual-metrics)));
    compact = evidence.point_modes{ic,ib};
    trace_error = max(trace_error,norm(compact.primary_trace-trace(:,end))/ ...
      max(1,norm(trace(:,end))));
    for side = {'plus','minus'}
      qz = e.qz.(side{1});
      assert(qz.stable==e.config.K && qz.unstable==e.config.K);
      assert(qz.neutral==0 && qz.indeterminate==0);
    end
    checked_winners = checked_winners+1;
  end

  % --- stage 2: independently compare all saved physical wall traces ---
  for ik = 1:nk
    for ic = 1:nc
      a = evidence.point_modes{1,ik};
      b = evidence.point_modes{ic,ik};
      c = evidence.point_modes{ic,center_index};
      if ~(a.valid && b.valid && c.valid)
        continue;
      end
      assert(a.k==b.k && b.k==result.k_values(ik));
      assert(isequal(b.m(:),(-b.config.M:b.config.M).'));
      A = LOCAL_embed(a,a.primary_trace);
      B = LOCAL_embed(b,b.primary_trace);
      C = LOCAL_embed(c,c.primary_trace);
      overlap(ic,ik) = LOCAL_overlap(A,B);
      center_overlap(ic,ik) = LOCAL_overlap(B,C);
      mask = repmat(abs((-64:64).')>48,2,1);
      high_mode_fraction(ic,ik) = norm(B(mask))^2/norm(B)^2;
    end
    for ie = 1:size(result.edges,1)
      a = evidence.point_modes{result.edges(ie,1),ik};
      b = evidence.point_modes{result.edges(ie,2),ik};
      if ~(a.valid && b.valid && a.comparison_available && b.comparison_available)
        continue;
      end
      A = LOCAL_embed(a,a.primary_trace); B = LOCAL_embed(b,b.primary_trace);
      Ac = LOCAL_embed(a,a.competitor_trace);
      Bc = LOCAL_embed(b,b.competitor_trace);
      rho = LOCAL_overlap(A,B);
      cross = max(LOCAL_overlap(A,Bc),LOCAL_overlap(Ac,B));
      saved = result.grid_comparisons(ie,ik);
      comparison_error = max([comparison_error, ...
        abs(rho-saved.primary_overlap),abs(cross-saved.cross_max)]);
      assert(saved.pass==(rho>=0.99 && cross<=0.5));
      checked_edges = checked_edges+1;
    end
  end
  assert(result.execution_pass && result.diagnostic_pass && ...
    result.same_k_mode_identity_pass);
  assert(all([result.points.valid]) && all([result.best.valid]));
  assert(checked_winners==nc && checked_edges==size(result.edges,1)*nk);
  assert(all(isfinite(overlap(:))) && all(isfinite(center_overlap(:))));
  defects = [metric_error,weight_error,trace_error,comparison_error];
  assert(all(isfinite(defects)) && max(defects)<1e-11);
  audit = struct('pass',true,'checked_winners',checked_winners, ...
    'checked_same_k_edges',checked_edges,'metric_max_abs_error',metric_error, ...
    'weight_relative_error',weight_error,'trace_relative_error',trace_error, ...
    'comparison_max_abs_error',comparison_error,'bracket_valid',bracket_valid, ...
    'baseline_same_k_overlap',overlap,'within_config_k0_overlap',center_overlap, ...
    'above_48_energy_fraction',high_mode_fraction, ...
    'continuous_eigenvalue_claim',false);
end

function y = LOCAL_embed(e,x)
%LOCAL_EMBED Align each wall by its actual Rayleigh index in [-64,64].

  modes = (-64:64).';
  [found,index] = ismember(e.m(:),modes);
  assert(all(found) && numel(x)==2*numel(index));
  y = zeros(2*numel(modes),1);
  y([index;numel(modes)+index]) = x;
end

function rho = LOCAL_overlap(a,b)
%LOCAL_OVERLAP Remove phase and scale without changing physical coordinates.

  assert(all(isfinite(a)) && all(isfinite(b)) && norm(a)>0 && norm(b)>0);
  rho = min(1,abs((a/norm(a))'*(b/norm(b))));
end
