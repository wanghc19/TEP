function audit = audit_i7_refinement(result,evidence)
%AUDIT_I7_REFINEMENT Independently recompute saved I7.3 diagnostics.
% Purpose:
%   Check the supplied matrices and trace vectors without rebuilding physics.
% Input:
%   result, evidence - Outputs from check_i7_refinement in this experiment.
% Output:
%   audit - Maximum discrepancies, checked counts, and a consistency verdict.
% Main algorithm:
%   Recompute matrix identities, sign bands, weights, and same-k overlaps.
% Notes:
%   This checks internal consistency, not continuous spectral correctness.

  defects = zeros(1,8);
  checked = 0;
  for ic = 1:size(evidence,1)
    for ik = 1:size(evidence,2)
      e = evidence{ic,ik};
      p = result.points(ic,ik);
      if ~p.valid
        continue;
      end
      n = size(e.H,1);
      Hs = (e.H+e.H')/2;
      defects(8) = max(defects(8),norm(Hs-e.Hsym,'fro')/max(1,norm(Hs,'fro')));
      eigres = norm(Hs*e.Hsym_vectors-e.Hsym_vectors*diag(e.Hsym_eigenvalues),'fro')/max(1,norm(Hs,'fro'));
      assert(eigres<1000*n*eps);
      for direction = {'plus','minus'}
        qz = e.qz.(direction{1});
        assert(qz.stable==e.config.K && qz.unstable==e.config.K && ...
          qz.neutral==0 && qz.indeterminate==0);
      end
      s = norm(Hs,2);
      dH = norm(e.H-Hs,2);
      lambda = eig(Hs);
      assert(all(isfinite(lambda)) && max(abs(imag(lambda))) < 1000*n*eps*max(1,s));
      lambda = real(lambda);
      for c = [50,100,200]
        eta = dH+c*n*eps*max(1,s);
        count = [sum(lambda>eta),sum(lambda<-eta),sum(abs(lambda)<=eta)];
        recorded = [p.(sprintf('positive_%d',c)), ...
          p.(sprintf('negative_%d',c)),p.(sprintf('unresolved_%d',c))];
        assert(isequal(count,recorded));
        defects(1) = max(defects(1),abs(eta-p.(sprintf('eta_%d',c)))/max(1,eta));
      end
      rid = norm(e.Adef-e.N0+e.L*e.T,'fro')/ ...
        max(1,norm(e.Adef,'fro')+norm(e.N0,'fro')+norm(e.L,'fro')*norm(e.T,'fro'));
      rsolve = norm(e.H*e.T-e.Adef,'fro')/ ...
        max(1,norm(e.Adef,'fro')+norm(e.H,'fro')*norm(e.T,'fro'));
      defects(2) = max([defects(2),rid,rsolve]);
      assert(isequal(e.m(:),(-e.config.M:e.config.M).'));
      assert(norm(e.beta_m(:)-(result.beta+2*pi*e.m(:)),Inf) < 1e-12);
      if ~isempty(fieldnames(e.svd))
        b = sqrt(1+abs(e.beta_m(:)).^2);
        dr = repmat(1./sqrt(b),2,1);
        dc = repmat(1./sqrt(b+abs(e.gamma(:)).^2./b),2,1);
        Aphys = diag(dr)*e.Adef*diag(dc);
        defects(3) = max(defects(3),norm(Aphys-e.svd.Aphys,'fro')/max(1,norm(Aphys,'fro')));
        trace = e.T*diag(dc)*e.svd.aphys_right_vectors;
        defects(4) = max(defects(4),norm(trace-e.svd.physical_trace_vectors,'fro')/max(1,norm(trace,'fro')));
        U = e.svd.aphys_left_vectors; V = e.svd.aphys_right_vectors;
        S = diag(e.svd.aphys_singular_values_descending);
        svdres = max(norm(Aphys*V-U*S,'fro'),norm(Aphys'*U-V*S,'fro'))/max(1,norm(Aphys,'fro'));
        assert(svdres<1000*n*eps);
        sd = svd(e.Adef); sp = svd(Aphys);
        metrics = [sd(end),sd(end)/sd(1),sp(end),sp(end)/sp(1)];
        saved = [p.adef_sigma,p.adef_ratio,p.aphys_sigma,p.aphys_ratio];
        defects(5) = max(defects(5),max(abs(metrics-saved)));
      end
      checked = checked+1;
    end
  end

  comparisons_checked = 0;
  for j = 1:size(result.edges,1)
    for ik = 1:3
      a = evidence{result.edges(j,1),ik};
      b = evidence{result.edges(j,2),ik};
      saved = result.comparisons(j,ik);
      if ~a.valid || ~b.valid
        continue;
      end
      [Xa,ia,ca] = LOCAL_saved_trace(a,ik);
      [Xb,ib,cb] = LOCAL_saved_trace(b,ik);
      modes = unique([a.m(:);b.m(:)]);
      A = zeros(2*numel(modes),size(Xa,2));
      B = zeros(2*numel(modes),size(Xb,2));
      [~,pa] = ismember(a.m(:),modes);
      [~,pb] = ismember(b.m(:),modes);
      A([pa;numel(modes)+pa],:) = Xa;
      B([pb;numel(modes)+pb],:) = Xb;
      [Qa,~] = qr(A(:,ia),0);
      [Qb,~] = qr(B(:,ib),0);
      if numel(ia)==1 && numel(ib)==1
        rho = abs(Qa'*Qb);
        cross_ab = abs(A(:,ia)'*B(:,cb))/(norm(A(:,ia))*norm(B(:,cb)));
        cross_ba = abs(A(:,ca)'*B(:,ib))/(norm(A(:,ca))*norm(B(:,ib)));
        common = repmat(abs(modes)<=min(a.config.M,b.config.M),2,1);
        rho_common = abs(A(common,ia)'*B(common,ib))/(norm(A(common,ia))*norm(B(common,ib)));
        defects(6) = max([defects(6),abs(min(1,rho)-saved.primary_overlap), ...
          abs(cross_ab-saved.cross_a_primary_b_competitor), ...
          abs(cross_ba-saved.cross_a_competitor_b_primary), ...
          abs(max(cross_ab,cross_ba)-saved.cross_max), ...
          abs(min(1,rho_common)-saved.common_overlap)]);
        assert(saved.pass==(rho>=0.99 && max(cross_ab,cross_ba)<=0.5));
      elseif numel(ia)==numel(ib)
        rho = min(svd(Qa'*Qb));
        defects(6) = max(defects(6),abs(rho-saved.subspace_overlap));
        assert(saved.pass==(rho>=0.99));
      else
        assert(~saved.pass);
      end
      for side = 1:2
        if side==1
          Q = Qa; rows = {saved.tail_a_edge,saved.tail_a_above_48};
        else
          Q = Qb; rows = {saved.tail_b_edge,saved.tail_b_above_48};
        end
        for it = 1:2
          recorded = rows{it};
          mask = abs(modes)>recorded.cutoff;
          left = Q(1:numel(modes),:); right = Q(numel(modes)+1:end,:);
          tail = norm([left(mask,:);right(mask,:)],'fro')^2/norm(Q,'fro')^2;
          values = [tail,norm(left(mask,:),'fro')^2/max(realmin,norm(left,'fro')^2), ...
            norm(right(mask,:),'fro')^2/max(realmin,norm(right,'fro')^2),1-tail];
          defects(7) = max(defects(7),max(abs(values- ...
            [recorded.total,recorded.left,recorded.right,recorded.common])));
        end
      end
      comparisons_checked = comparisons_checked+1;
    end
  end
  assert(numel(evidence)-checked==result.invalid_point_count);
  assert(all(isfinite(defects)) && max(defects)<1e-10);
  audit = struct('pass',true,'valid_points_checked',checked, ...
    'skipped_invalid_points',numel(evidence)-checked, ...
    'comparisons_checked',comparisons_checked, ...
    'eta_relative_difference',defects(1),'identity_residual',defects(2), ...
    'Aphys_relative_difference',defects(3),'trace_relative_difference',defects(4), ...
    'four_metrics_absolute_difference',defects(5), ...
    'overlap_absolute_difference',defects(6),'tail_absolute_difference',defects(7), ...
    'Hsym_relative_difference',defects(8));
end

%% ==================== Saved physical coordinates ====================
% Select the recorded spectral cluster and reconstruct its physical trace.

function [X,index,competitor] = LOCAL_saved_trace(e,point_index)
  if point_index==2
    X = e.T*diag(e.svd.column_weight)*e.svd.aphys_right_vectors;
    sigma = e.svd.aphys_singular_values_descending;
    delta = 1000*numel(sigma)*eps*max(1,sigma(1));
    index = find(sigma<=min(sigma)+delta);
    competitor = numel(sigma)-1;
  else
    X = e.Hsym_vectors;
    lambda = e.Hsym_eigenvalues;
    delta = 1000*numel(lambda)*eps*max(1,norm(e.Hsym,2));
    index = find(abs(abs(lambda)-min(abs(lambda)))<=delta);
    [~,order] = sort(abs(lambda)); competitor = order(2);
  end
end
