function report=run_pipeline(example,setting,output_dir)
  % RUN_PIPELINE Search, generate a direct trial and certify its Goerisch data.
  % Input
  %   example: full scientific parameter struct; setting: original or fast.
  %   output_dir: explicit fresh run directory. No prior outputs are read.
  % Output
  %   candidates.json, trial-summary.json, integrals.json, interval.json and diagnostics.
  started=tic;active='validation';report=struct('status','STARTED','setting',setting,'times',struct());
  assert(~isfile(fullfile(output_dir,'summary.json')),'pipeline:Output','Use a fresh run directory.');
  if ~isfolder(output_dir),mkdir(output_dir);end
  try
    support=validate_example(example);assert(ismember(setting,{'original','fast'}),'pipeline:Setting','Setting must be original or fast.');
    maxNumCompThreads(example.resources.threads);
    cfg=direct_pipeline('config','in-memory','D',example);opts=example.discretization.(setting);
    pm('configure',example.discretization.polynomial_degree,example.discretization.series_order);
    inverse_iteration_count(opts.inverse_iterations);
    LOCAL_json(output_dir,'config.json',struct('example',example,'setting',setting,'config',cfg,'accuracy',opts,'support',support));
    report.pm_tests=pm_tests();report.guard_tests=LOCAL_guard_tests(example);
    report.times.validation=toc(started);
    active='search';tt=tic;search=fem_i9_run(fullfile(output_dir,'search'),example.windows.search_k,example);report.times.search=toc(tt);
    candidates=struct('window_k',example.windows.search_k,'candidate_ids',search.candidate_ids,'modes',search.modes);
    n=numel(search.candidate_ids);candidates.status='SINGLE_CANDIDATE';
    if n==0,candidates.status='NO_CANDIDATE';elseif n>1,candidates.status='MULTIPLE_CANDIDATES';end
    LOCAL_json(output_dir,'candidates.json',candidates);
    if n~=1,report.status=candidates.status;report.seconds=toc(started);LOCAL_json(output_dir,'summary.json',report);return;end
    k=search.modes(search.candidate_ids).k;
    active='trial_generation';tt=tic;
    [native,generation]=direct_native('generate',k,fullfile(output_dir,'generation'),example.discretization.trial_degree,example);
    report.times.trial_generation=toc(tt);
    active='prepare';tt=tic;P=direct_pipeline('prepare',cfg,native);clear native
    evaluator=direct_pipeline('evaluator_check',P,cfg);report.times.prepare=toc(tt);
    active='flux';tt=tic;S=direct_pipeline('solve',P,cfg,example.discretization.flux_degree);report.times.flux=toc(tt);
    active='functional';tt=tic;base=direct_pipeline('evaluate',P,S,cfg);report.times.functional=toc(tt);
    active='quadrature_check';tt=tic;verify=direct_pipeline('verify',P,S,cfg);report.times.quadrature_check=toc(tt);
    checks=LOCAL_checks(P,base,verify,evaluator,cfg);
    trial=struct('generation',generation,'q',P.q,'E',P.energy,'M',P.mass,'base',base,'verification',verify, ...
      'checks',checks,'native_trace',P.native_trace,'evaluator',evaluator,'prepare_timing',P.timing,'flux_timing',S.timing);
    LOCAL_json(output_dir,'trial-summary.json',trial);
    assert(checks.pass,'pipeline:TrialChecks','Direct-trial or same-flux quadrature check failed.');
    active='exact_flux';tt=tic;[N,exact]=direct_pipeline('exact_flux',P,S,cfg);clear S
    report.times.exact_flux=toc(tt);LOCAL_json(output_dir,'exact-flux.json',exact);
    active='inventory';tt=tic;inventory=direct_pipeline('inventory',P,N,cfg);report.times.inventory=toc(tt);
    LOCAL_json(output_dir,'inventory.json',inventory);
    active='common_certificates';tt=tic;
    common=direct_pipeline('certificates',P,N,cfg,output_dir,inventory);report.times.common_certificates=toc(tt);
    LOCAL_json(output_dir,'common-certificates.json',common);
    for j=1:3,P.templates{j}.cache={};end
    active='interface_quadrature';tt=tic;quad=interface_quadrature(P,N,cfg,'full');report.times.interface_quadrature=toc(tt);
    LOCAL_json(output_dir,'interface-quadrature.json',quad);
    active='interface_certificate';tt=tic;
    iface=interface_certificate(P,N,cfg,common,inventory,output_dir,'full',opts);report.times.interface_certificate=toc(tt);
    integrals=struct('E',common.E,'M',iface.M,'S_upper',iface.S_upper,'S_common',common.S_smooth, ...
      'S_interface_upper',iface.S_interface_upper,'s',P.q,'gamma',cfg.gamma, ...
      'alpha_minus',cfg.alpha_minus,'alpha_plus',cfg.alpha_plus,'signs',iface.full_interval.signs, ...
      'sign_conditions',iface.full_interval.pass,'interface_contains_Q16',iface.contains_Q16, ...
      'interface_contains_Q24',iface.contains_Q24,'rounding_covered',false);
    LOCAL_json(output_dir,'integrals.json',integrals);
    assert(iface.contains_Q16&&iface.contains_Q24&&iface.full_interval.pass,'pipeline:CertificateChecks','Certificate containment/sign check failed.');
    interval=LOCAL_intervals(integrals,iface.full_interval);LOCAL_json(output_dir,'interval.json',interval);
    if support.reference_regression
      active='reference_regression';report.regression=reference_regression(setting,trial,integrals,interval);
      LOCAL_json(output_dir,'regression.json',report.regression);
      assert(report.regression.pass,'pipeline:Regression','Reference regression failed.');
    end
    report.status='COMPLETE';report.seconds=toc(started);
    report.times.control_and_output=report.seconds-sum(cell2mat(struct2cell(report.times)));
    LOCAL_json(output_dir,'summary.json',report);
  catch err
    report.status='FAILED';report.active_stage=active;report.seconds=toc(started);
    report.failure=struct('identifier',err.identifier,'message',err.message,'stack',err.stack);
    report.times.control_and_output=report.seconds-sum(cell2mat(struct2cell(report.times)));
    LOCAL_json(output_dir,'summary.json',report);rethrow(err)
  end
end
function r=LOCAL_checks(P,b,v,e,cfg)
  % Input: same trial/flux scalar reports. Output: validity checks and differences.
  r=struct('functional',b.pass,'evaluator',e.pass,'J_scaled',P.q*abs(v.J24-b.J)/b.qJ_square, ...
    'q_relative',abs(v.q24/P.q-1),'q_change',abs(v.q24-P.q),'mass_relative',abs(v.mass24/P.mass-1), ...
    'energy_relative',abs(v.energy24/P.energy-1),'square_relative',abs(v.qJ_square24/b.qJ_square-1), ...
    'area_relative',max([v.areas.relative_error]), ...
    'native_cell_trace',P.native_trace.cell_relative,'native_phase_trace',P.native_trace.phase_relative);
  r.pass=r.functional&&r.evaluator&&r.J_scaled<cfg.quadrature_fraction ...
    &&r.q_relative<cfg.tolerances.quotient&&r.q_change<cfg.quadrature_fraction*b.square_interval.width ...
    &&r.mass_relative<cfg.tolerances.quotient&&r.energy_relative<cfg.tolerances.quotient ...
    &&r.area_relative<cfg.tolerances.area&&r.native_cell_trace<cfg.tolerances.trace&&r.native_phase_trace<cfg.tolerances.trace;
end
function r=LOCAL_intervals(c,four)
  % Input: certified integral box and four-corner output. Output: separate statuses.
  a=c.gamma+c.E(1)/c.M(2);b=c.gamma+c.E(2)/c.M(1);d=b*c.S_upper/c.M(1);
  root=sqrt(d+d^2/4);I=[a*(1+d/2-root)-c.gamma,b*(1+d/2+root)-c.gamma];
  r=struct('I_1',struct('endpoints',I,'width',diff(I),'q_min',a,'q_max',b,'delta_max',d, ...
    'status','meets the spectrum; no (H); point spectrum additionally needs essential-spectrum exclusion'), ...
    'four_corner',four,'status','under (H), (H) checked only in floating point: not yet', ...
    'rounding_covered',false,'printed_endpoints','pending decimal outward display postprocessing');
end
function r=LOCAL_guard_tests(e)
  % Input: supported example. Output: representative early rejection checks.
  names={'beta','rho_negative','d'};rejected=false(1,numel(names));
  for j=1:numel(names)
    x=e;x.model.(names{j})=x.model.(names{j})+.01;
    try,validate_example(x);catch err,rejected(j)=strcmp(err.identifier,'pipeline:Unsupported');end
  end
  x=e;x.model.rho_center=e.model.rho_center+.01;ok=validate_example(x);
  r=struct('changed_fields',{names},'rejected',rejected,'center_change_accepted',ok.supported,'pass',all(rejected)&&ok.supported);
  assert(r.pass,'pipeline:Guards','Support guard checks failed.');
end
function LOCAL_json(directory,name,value)
  % Input: explicit directory, filename and compact report. Output: JSON on disk.
  f=fopen(fullfile(directory,name),'w');assert(f>=0);cl=onCleanup(@()fclose(f));fwrite(f,jsonencode(value,PrettyPrint=true));
end
