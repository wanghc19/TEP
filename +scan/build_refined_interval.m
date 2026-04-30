function interval = build_refined_interval(k_grid, idx_min)
% BUILD_REFINED_INTERVAL Choose the next scan interval around a grid minimum.
%
% Purpose:
%   Given a sampled k-grid and the index of the best sampled value, returns
%   the neighboring interval used for the next local refinement step.
%
% Input:
%   k_grid  - Monotone vector of sampled wavenumbers.
%   idx_min - Index of the selected minimum in k_grid.
%
% Output:
%   interval - Two-entry row vector defining the next scan interval.
%
% Notes:
%   Endpoint minima are handled by taking the first or last grid cell.

  nk = length(k_grid);
  if nk < 2
    error('Need at least two k-samples to define a refined interval.');
  end

  if idx_min <= 1
    interval = [k_grid(1), k_grid(2)];
  elseif idx_min >= nk
    interval = [k_grid(nk - 1), k_grid(nk)];
  else
    interval = [k_grid(idx_min - 1), k_grid(idx_min + 1)];
  end

end
