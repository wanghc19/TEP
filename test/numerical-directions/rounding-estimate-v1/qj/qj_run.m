function report=qj_run(output_dir,stage)
  % QJ_RUN Compute Goerisch q and J certificate diagnostics in one process.
  % Input
  %   output_dir: new directory; stage: inventory or certificates.
  % Output
  %   Scalar JSON and CSV only. The field and flux stay in process memory.
  mkdir(output_dir);started=tic;maxNumCompThreads(11);report=struct();active='baseline';
  cfg=direct_pipeline('config','in-memory','D');cfg.fem_degree=3;cfg.baseline_check=false;cfg.level='native-P3';
  cfg.alpha_minus=1.32^2;cfg.alpha_plus=2.37^2;cfg.mu=cfg.alpha_minus+1;cfg.nu=cfg.alpha_plus+1;
  try
    report.pm_tests=pm_tests();save_report('pm-tests.json',report.pm_tests);
    search=fem_i9_run(fullfile(output_dir,'search'),[1.4509999999999998,2.2490000000000001]);
    assert(numel(search.candidate_ids)==1);k=search.modes(search.candidate_ids).k;
    [native,generation]=direct_native('generate',k,fullfile(output_dir,'generation'),3);
    P=direct_pipeline('prepare',cfg,native);clear native
    S=direct_pipeline('solve',P,cfg,3);base=direct_pipeline('evaluate',P,S,cfg);verify=direct_pipeline('verify',P,S,cfg);
    report.baseline=struct('generation',generation,'q',P.q,'J',base.J,'E',P.energy,'M',P.mass,'S',base.qJ_square*P.mass/P.q, ...
      'delta',base.qJ_square,'width',base.square_interval.width,'interval',base.square_interval.enclosure,'verification',verify, ...
      'root_relative',abs(generation.frequency/1.5584378944019319-1),'q_relative',abs(P.q/3.4287286707248672-1), ...
      'J_relative',abs(base.J/0.29165329083988201-1),'width_relative',abs(base.square_interval.width/4.453737393984524e-9-1));
    save_report('baseline.json',report.baseline);
    assert(report.baseline.root_relative<1e-12&&max([report.baseline.q_relative,report.baseline.J_relative])<1e-12&&report.baseline.width_relative<.001,'qj:Baseline','Baseline mismatch');
    if strcmp(stage,'inventory')
      active='inventory';report.inventory=direct_pipeline('inventory',P,S,cfg);save_report('inventory-old.json',report.inventory);
      assert(abs(report.inventory.totals(1,4)/report.baseline.S-1)<1e-13,'qj:Inventory','Residual class sum mismatch');
    end
    active='exact_basis';[N,report.exact_basis]=direct_pipeline('exact_flux',P,S,cfg);save_report('exact-flux.json',report.exact_basis);
    clear S
    active='inventory_exact';report.inventory_exact=direct_pipeline('inventory',P,N,cfg);save_report('inventory-exact.json',report.inventory_exact);
    if ~strcmp(stage,'inventory')
      active='certificates';report.certificates=direct_pipeline('certificates',P,N,cfg,output_dir,report.inventory_exact);save_report('certificates.json',report.certificates);
    end
    report.reproduction=struct('E_end_maxdiff',max(abs(report.certificates.E-[11.470912271614043,11.470912271618044])), ...
      'M_end_maxdiff',max(abs(report.certificates.M-[4.723011017995318,4.723011018047269])), ...
      'S_common_relative',max(abs(report.certificates.S_smooth./[2.5978040358470705e-10,2.597806496727071e-10]-1)), ...
      'S_interface_relative',abs(report.certificates.S_interface_floating/3.4934538091093334e-11-1), ...
      'partial_width_relative',abs(report.certificates.corners_partial.width/4.481301107972513e-9-1));
    save_report('reproduction.json',report.reproduction);
    assert(max([report.reproduction.E_end_maxdiff,report.reproduction.M_end_maxdiff])<1e-13&& ...
      max([report.reproduction.S_common_relative,report.reproduction.S_interface_relative])<1e-11&&report.reproduction.partial_width_relative<1e-6,'qj2:Baseline','v1 baseline mismatch');
    active='transport_float';report.transport=direct_pipeline('transport_float',P,N,cfg,report.inventory_exact);save_report('transport.json',report.transport);
    if ~strcmp(stage,'certificates')&&~strcmp(stage,'inventory')
      for ii=1:3,P.templates{ii}.cache={};end
      active='interface_quadrature';report.interface_quadrature=interface_quadrature(P,N,cfg,stage);save_report('interface-quadrature.json',report.interface_quadrature);
      active='interface_certificate';report.interface=interface_certificate(P,N,cfg,report.certificates,report.inventory_exact,output_dir,stage);save_report('interface-certificate.json',report.interface);
    end
    report.status='COMPLETE';report.seconds=toc(started);save_report('summary.json',report);
  catch err
    report.status='FAILED';report.active_stage=active;report.seconds=toc(started);report.failure=struct('identifier',err.identifier,'message',err.message,'stack',err.stack);
    save_report('summary.json',report);rethrow(err)
  end
  function save_report(name,x)
    f=fopen(fullfile(output_dir,name),'w');assert(f>=0);clean=onCleanup(@()fclose(f));fwrite(f,jsonencode(x,PrettyPrint=true));
  end
end
