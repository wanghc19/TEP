function results = run_i4_rayleigh_budget_hi_reference()
% RUN_I4_RAYLEIGH_BUDGET_HI_REFERENCE Run the refined smoke reference.
%
% Purpose:
%   Re-evaluate the frozen delta=0.30, k=1.8603695988 smoke point with
%   ntot=160, Ny_wall=2048, and a refined proxy representation to determine
%   whether the direct-wall extractor error reaches the unchanged 1e-8 gate.
%
% Output:
%   results - The standard Rayleigh-budget result bundle written beneath
%             output/smoke-hi-reference-160-2048/.
%
% Main algorithm:
%   Apply only the frozen high-reference discretization overrides, then call
%   run_i4_rayleigh_budget so the master rectangular solve, M=0:8 projective
%   QZ restrictions, and doubling diagnostics use the same workflow as the
%   low smoke run.
%
% Numerical goal:
%   Measure the high-reference extractor error without relaxing the 1e-8
%   tolerance.  The missing cross-ntot comparison still keeps M_stable
%   inconclusive.

  overrides.ntot = 160;
  overrides.Ny_wall = 2048;
  overrides.expected_runtime_seconds = [90, 300];
  overrides.proxy.N_side = 120;
  overrides.proxy.N_top = 120;
  overrides.proxy.N_proxy_edge = 64;
  overrides.proxy.M_pw = 24;
  overrides.command = [ ...
    'perl -e ''alarm shift; exec @ARGV'' 5400 conda run -n octave ', ...
    'octave --quiet --no-gui --eval "addpath(''%s''); ', ...
    'results=run_i4_rayleigh_budget_hi_reference();"'];
  results = run_i4_rayleigh_budget('smoke', overrides, ...
    'smoke-hi-reference-160-2048');
end
