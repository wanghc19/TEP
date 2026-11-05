function s=cell_settings()
% CELL_SETTINGS Fixed model and source-resolution settings.
% Input
%   None.
% Output
%   Split-source wall settings, reference scalar check and grouped constants.
  s=struct('target_count',768,'order',12,'base_panels',8,'pair_block',8192,'target_block',4, ...
    'Q5_reference',.12339611507515838,'k0',1.5584378941820909,'U',1.23587);
  s.C=[2.4899964875494045,1.181300292100912,1.2336397935832015,1.0355521263049683,1.0355521263049683];
  s.kernel_sweep=[80,.2,1e-14;120,.2,1e-14;120,.35,1e-14;160,.35,1e-14;120,.35,1e-12;160,.5,1e-14];
  s.fit=struct('H',1.1,'edge',120,'margin',.35,'tolerance',1e-14,'nx',13,'ny',81,'top',240,'mpw',32);
end
