function results = run_aug_bie_experiment()
% Purpose:
%   Run the frozen Stage 2 augmented BIE experiment from a stable entry point.
%
% Output:
%   results - Complete algebra, gate, provenance, and reproducibility bundle.

  here = fileparts(mfilename('fullpath'));
  addpath(here);
  results = aug_bie_experiment();
end
