function s=srcsplit_settings(mode)
  % SRCSPLIT_SETTINGS Source-split quadrature settings and fixed budget data.
  % Input
  %   mode: pilot or full.
  % Output
  %   Scientific quadratures and explicit saved scalar budget inputs.
  s=struct('mode',mode,'target_count',1536,'order',12,'base_panels',8,'refinements',[1,2,4], ...
    'trap_counts',[96,192,384],'pair_block',8192,'target_block',4,'identity_tolerance',2e-13, ...
    'Q5_reference',.12339611507515838,'C_wall',1.0355521263049683,'Q_switch',4.268e-11, ...
    'Q_allow',[6.352111900092406e-11,6.986448419732437e-10]);
  if strcmp(mode,'fine'),s.refinements=8;s.target_count=768;end
  % budget-v1/budget.json: only the wall group is replaced in this experiment.
  s.other_value=[3.4944351435328047e-29,8.757292088080117e-31,9.551737870482597e-31,1.6299620283978306e-28];
  s.other_normal=[1.5904989965597023e-24,2.4890689242951895e-28,2.6740928460387916e-28,1.2656160748257938e-27];
  s.other_C=[2.4899964875494045,1.181300292100912,1.2336397935832015,1.0355521263049683];
end
