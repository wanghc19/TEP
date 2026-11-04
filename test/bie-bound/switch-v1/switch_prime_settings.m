function s=switch_prime_settings()
  % SWITCH_PRIME_SETTINGS Settings for one tangential integration by parts.
  % Input
  %   None.
  % Output
  %   Original settings with explicit Proposition S-prime checks and constants.
  s=switch_settings();
  s.prime=struct('alpha',14.183,'fourier_cut',10000,'C_pt_reference',.7834823942, ...
    'Q_original_reference',1.4057100467689607e-9,'reproduction_tolerance',1e-9, ...
    'source_tolerance',1e-6,'identity_roundoff_factor',4096,'identity_order',256);
end
