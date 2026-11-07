function r=jump_pair(a,b)
  % Test two independently reconstructed fields by their off-node jumps.
  % Input: coarse and fine physical checks with unit incident norm.
  % Output: measured jumps, absolute and refinement gates, and joint verdict.
  coarse=[a.wall_rms,a.material_L2];fine=[b.wall_rms,b.material_L2];
  absolute=all(isfinite([coarse,fine])) && all([coarse,fine]<.005);
  decreasing=all(fine<=max(.8*coarse,1e-11));
  r=struct('coarse_jumps',coarse,'fine_jumps',fine,'absolute_pass',absolute, ...
    'refinement_pass',decreasing,'pass',absolute && decreasing);
end
