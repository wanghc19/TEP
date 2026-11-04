function report=accel_probe(output_dir)
  % ACCEL_PROBE Acceleration feasibility probe for interface residual bounds.
  % Input: new output directory. Output: scalar certificates and profiler records.
  mkdir(output_dir);started=tic;maxNumCompThreads(11);report=struct('rows',struct([]),'setup',struct(),'status','STARTED');active='setup';
  cfg=direct_pipeline('config','in-memory','D');cfg.fem_degree=3;cfg.baseline_check=false;cfg.level='native-P3';
  cfg.alpha_minus=1.32^2;cfg.alpha_plus=2.37^2;cfg.mu=cfg.alpha_minus+1;cfg.nu=cfg.alpha_plus+1;
  try
    setup_clock=tic;pm('configure',12,16);report.pm_tests=pm_tests();save_report('pm-tests.json',report.pm_tests);
    st=tic;search=fem_i9_run(fullfile(output_dir,'search'),[1.4509999999999998,2.2490000000000001]);
    report.setup.search=toc(st);st=tic;assert(numel(search.candidate_ids)==1);k=search.modes(search.candidate_ids).k;
    [native,generation]=direct_native('generate',k,fullfile(output_dir,'generation'),3);
    report.setup.field_generation=toc(st);st=tic;P=direct_pipeline('prepare',cfg,native);clear native
    report.setup.prepare=toc(st);st=tic;S=direct_pipeline('solve',P,cfg,3);base=direct_pipeline('evaluate',P,S,cfg);verify=direct_pipeline('verify',P,S,cfg);
    report.setup.flux_and_float_checks=toc(st);st=tic;report.baseline=struct('generation',generation,'q',P.q,'J',base.J,'E',P.energy,'M',P.mass,'S',base.qJ_square*P.mass/P.q, ...
      'delta',base.qJ_square,'width',base.square_interval.width,'interval',base.square_interval.enclosure,'verification',verify, ...
      'root_relative',abs(generation.frequency/1.5584378944019319-1),'q_relative',abs(P.q/3.4287286707248672-1), ...
      'J_relative',abs(base.J/0.29165329083988201-1),'width_relative',abs(base.square_interval.width/4.453737393984524e-9-1));
    save_report('baseline.json',report.baseline);
    assert(report.baseline.root_relative<1e-12&&max([report.baseline.q_relative,report.baseline.J_relative])<1e-12&&report.baseline.width_relative<.001,'qj:Baseline','Baseline mismatch');
    if false
      active='inventory';report.inventory=direct_pipeline('inventory',P,S,cfg);save_report('inventory-old.json',report.inventory);
      assert(abs(report.inventory.totals(1,4)/report.baseline.S-1)<1e-13,'qj:Inventory','Residual class sum mismatch');
    end
    active='exact_basis';[N,report.exact_basis]=direct_pipeline('exact_flux',P,S,cfg);save_report('exact-flux.json',report.exact_basis);
    clear S
    active='inventory_exact';report.inventory_exact=direct_pipeline('inventory',P,N,cfg);save_report('inventory-exact.json',report.inventory_exact);
    if true
      report.setup.exact_flux_inventory=toc(st);st=tic;active='certificates';report.certificates=direct_pipeline('certificates',P,N,cfg,output_dir,report.inventory_exact);save_report('certificates.json',report.certificates);
    end
    report.reproduction=struct('E_end_maxdiff',max(abs(report.certificates.E-[11.470912271614043,11.470912271618044])), ...
      'M_end_maxdiff',max(abs(report.certificates.M-[4.723011017995318,4.723011018047269])), ...
      'S_common_relative',max(abs(report.certificates.S_smooth./[2.5978040358470705e-10,2.597806496727071e-10]-1)), ...
      'S_interface_relative',abs(report.certificates.S_interface_floating/3.4934538091093334e-11-1), ...
      'partial_width_relative',abs(report.certificates.corners_partial.width/4.481301107972513e-9-1));
    save_report('reproduction.json',report.reproduction);
    assert(max([report.reproduction.E_end_maxdiff,report.reproduction.M_end_maxdiff])<1e-13&& ...
      max([report.reproduction.S_common_relative,report.reproduction.S_interface_relative])<1e-11&&report.reproduction.partial_width_relative<1e-6,'qj2:Baseline','v1 baseline mismatch');
    report.setup.v1_certificate=toc(st);report.setup.total=toc(setup_clock);
    for ii=1:3,P.templates{ii}.cache={};end
    baseopt=struct('name','baseline','tol',1e-13/(3*640),'degree',12,'series',16,'sliver_panels',4);
    active='baseline_center';b=run_case(baseopt,'center',false);
    report.center_reproduction=abs(b.upper/1.9323414727573126e-11-1);save_report('probe.json',report);
    assert(report.center_reproduction<=1e-12,'probe:Baseline','Center bound did not reproduce');
    active='profile_center';run_case(baseopt,'center',true);
    % Start with accuracy/panel controls. Test one knob at a time.
    for factor=[10,100,1000]
      o=baseopt;o.name=sprintf('tol_x%d',factor);o.tol=baseopt.tol*factor;run_case(o,'center',false);
    end
    o=baseopt;o.name='tol_budget';o.tol=1.9e-12/640;run_case(o,'center',false);
    o=baseopt;o.name='sliver_1';o.sliver_panels=1;run_case(o,'center',false);
    good=report.rows([report.rows.accuracy_pass]&~[report.rows.profiled]);[~,ix]=min([good.seconds]);best=good(ix).options;
    o=best;o.name='combined_panels';o.sliver_panels=1;c=run_case(o,'center',false);
    % Reduce polynomial/series work only when the cheap controls miss 3x.
    if b.seconds/c.seconds<3 || ~c.accuracy_pass
      for degree=[10,8,6]
        o=baseopt;o.name=sprintf('degree_%d',degree);o.degree=degree;run_case(o,'center',false);
      end
      for order=[12,8]
        o=baseopt;o.name=sprintf('series_%d',order);o.series=order;run_case(o,'center',false);
      end
      good=report.rows([report.rows.accuracy_pass]&~[report.rows.profiled]);
      o=baseopt;o.name='combined_all';o.tol=1.9e-12/640;o.sliver_panels=1;
      gd=good(arrayfun(@(z)startsWith(z.name,'degree_'),good));if ~isempty(gd),[~,ix]=min([gd.seconds]);o.degree=gd(ix).options.degree;end
      gs=good(arrayfun(@(z)startsWith(z.name,'series_'),good));if ~isempty(gs),[~,ix]=min([gs.seconds]);o.series=gs(ix).options.series;end
      run_case(o,'center',false);
    end
    good=report.rows([report.rows.accuracy_pass]&~[report.rows.profiled]);[~,ix]=min([good.seconds]);report.best=good(ix);save_report('probe.json',report);
    o=report.best.options;run_case(o,'left',false);run_case(o,'right',false);
    report.status='COMPLETE';report.seconds=toc(started);save_report('probe.json',report);
  catch err
    profile off
    report.status='FAILED';report.active=active;report.seconds=toc(started);report.failure=struct('identifier',err.identifier,'message',err.message,'stack',err.stack);save_report('probe.json',report);rethrow(err)
  end
  function row=run_case(o,name,profiled)
    active=[o.name,'-',name];assert(toc(started)<1650,'probe:TimeBudget','Shared soft budget nearly used; save partial work');
    sub=fullfile(output_dir,[active,iff(profiled,'-profile','')]);mkdir(sub);pm('configure',o.degree,o.series);tests=pm_tests();
    if profiled,profile clear;profile on;end
    tt=tic;r=interface_certificate(P,N,cfg,report.certificates,report.inventory_exact,sub,['full-',name],o);elapsed=toc(tt);
    if profiled
      profile off;pr=profile('info');ft=pr.FunctionTable;items=struct([]);
      for z=1:numel(ft)
        item=struct('function',ft(z).FunctionName,'total',ft(z).TotalTime,'calls',ft(z).NumCalls,'children',ft(z).Children,'lines',ft(z).ExecutedLines);
        if isempty(items),items=item;else,items(end+1)=item;end
      end
      save_report('profile-functions.json',items);clear pr ft items
    end
    ti=find(strcmp({'left','center','right'},name));iv=report.inventory_exact.templates(ti).fitted;ref=iv(1,2,1)+iv(1,3,2);ref24=iv(2,2,1)+iv(2,3,2);
    row=r.templates;row.name=o.name;row.options=o;row.profiled=profiled;row.wall_seconds=elapsed;row.Q16=ref;row.Q24=ref24;row.excess=row.upper-ref;row.excess_percent=100*row.excess/ref;row.accuracy_pass=row.excess>=0&&row.excess<=.1*ref;
    row.contains_Q16=row.lower<=ref&&ref<=row.upper;row.contains_Q24=row.lower<=ref24&&ref24<=row.upper;row.internal_checks_pass=true;row.pm_tests=tests;
    if isempty(report.rows),report.rows=row;else,report.rows(end+1)=row;end
    report.seconds=toc(started);save_report('probe.json',report);save_report([active,iff(profiled,'-profile',''),'.json'],row);
    fprintf('PROBE %s %s profile=%d %.3fs upper %.17g excess %.5f%% panels %d/%d\n',o.name,name,profiled,row.seconds,row.upper,row.excess_percent,row.smooth_panels,row.sliver_panels);
    assert(row.contains_Q16&&row.contains_Q24,'probe:Containment','Reference quadratures outside enclosure');
  end
  function save_report(name,x)
    f=fopen(fullfile(output_dir,name),'w');assert(f>=0);clean=onCleanup(@()fclose(f));fwrite(f,jsonencode(x,PrettyPrint=true));
  end
end
function s=iff(c,a,b)
  if c,s=a;else,s=b;end
end
