function interval = build_refined_interval(x_grid, idx_min)
% BUILD_REFINED_INTERVAL Choose the next scan interval around a grid minimum.
%
% Purpose:
%   Given a sampled x-grid and the index of the best sampled value, returns
%   the neighboring interval used for the next local refinement step.
%
% Input:
%   x_grid  - Monotone vector of sampled scalar coordinates.
%   idx_min - Index of the selected minimum in x_grid.
%
% Output:
%   interval - Two-entry row vector defining the next scan interval.
%
% Notes:
%   Endpoint minima are handled by taking the first or last grid cell.

  nk = length(x_grid);
  if nk < 2
    error('Need at least two k-samples to define a refined interval.');
  end

  if idx_min <= 1
    interval = [x_grid(1), x_grid(2)];
  elseif idx_min >= nk
    interval = [x_grid(nk - 1), x_grid(nk)];
  else
    interval = [x_grid(idx_min - 1), x_grid(idx_min + 1)];
  end

end
