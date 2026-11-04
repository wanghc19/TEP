function r=reference_regression(setting,trial,c,interval)
  % REFERENCE_REGRESSION Historical numbers used only for the unchanged example.
  % Input
  %   Setting and newly computed trial, integral and interval reports.
  % Output
  %   Differences from qj-cert-v2 run-004 / accel-probe-v1 run-003.
  oldE=[11.470912271614043,11.470912271618044];
  oldM=[4.7230110180143914,4.7230110180281955];oldS=2.9475799376947328e-10;
  endpoints=[2.4287286691977914,2.4287286736601232];oldWidth=4.4623318373737675e-9;
  if strcmp(setting,'fast')
    oldM=[4.723011017937883,4.723011018104704];oldS=2.9564839129097165e-10;
    endpoints=[2.4287286691538483,2.4287286737083225];oldWidth=4.554474131168718e-9;
  end
  actual=[interval.four_corner.L,interval.four_corner.U];
  r=struct('old_E',oldE,'old_M',oldM,'old_S_upper',oldS,'old_endpoints',endpoints,'old_width',oldWidth, ...
    'E_difference',c.E-oldE,'M_difference',c.M-oldM,'S_difference',c.S_upper-oldS, ...
    'endpoint_difference',actual-endpoints,'endpoint_relative',max(abs((actual-endpoints)./endpoints)), ...
    'width_relative',abs(interval.four_corner.width/oldWidth-1), ...
    'root_relative',abs(trial.generation.frequency/1.5584378944019319-1), ...
    'q_relative',abs(trial.q/3.4287286707248672-1), ...
    'contains_reference',actual(1)<=2.428728670022710&&actual(2)>=2.428728670022710);
  r.pass=r.endpoint_relative<=1e-13&&r.root_relative<=1e-12&&r.q_relative<=1e-12&&r.contains_reference;
  if strcmp(setting,'fast'),r.pass=r.pass&&r.width_relative<=1e-6;end
end
