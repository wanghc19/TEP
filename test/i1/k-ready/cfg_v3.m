function out = cfg_v3()
%CFG_V3 Return the frozen I1.4 V3 lift-gate pilot settings.
% Purpose:
%   Inherit V2 verbatim except for V3 identity labels; the numerical change
%   is confined to eval_k_v3's replacement graph-lift residual gate.
% Output:
%   out - Immutable settings for eval_k_v3 and run_pilot_v3.

  out = cfg_v2();
  out.schema = 'TEP_I1_K_READY_PILOT_V3';
  out.experiment_id = 'I1-K-READY-PILOT-V3';
end
