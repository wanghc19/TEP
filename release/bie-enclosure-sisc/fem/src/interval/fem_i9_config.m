function config=fem_i9_config(window,e)
% Source: test/fem-goerisch/pipeline-v1/internal/fem_i9_config.m. Copied numerical algorithm.
  % FEM_I9_CONFIG Finite element method options; I9 is the source implementation identifier.
  % Input
  %   Explicit window and validated example struct.
  % Output
  %   P2 (quadratic) candidate-search configuration.
  config=e.discretization.search;config.model=e.model;config.window=window;
  n=config.solver.shift_count;mu=window.^2;
  config.solver.shifts_mu=mu(1)+((1:n)-.5)/n*diff(mu);
  config.resources.threads=e.resources.threads;
end
