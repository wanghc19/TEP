function report=window_pipeline(window,output_dir,launch_epoch)
  % Direct FEM/Goerisch benchmark. FEM means finite element method.
  % Input
  %   window: given frequency interval; output_dir: new scalar-output directory.
  %   launch_epoch: launcher clock for startup accounting.
  % Output
  %   Scalar checkpoints and per-degree results; one shared field stays in memory.
  entry_epoch=posixtime(datetime('now','TimeZone','UTC'));started=tic;maxNumCompThreads(11); degree=3;flux_degrees=3;input_dir='in-memory';

  assert(~isfolder(output_dir));mkdir(output_dir);
  cfg=direct_pipeline('config',input_dir,'D');cfg.fem_degree=degree;cfg.baseline_check=degree==2;cfg.level=sprintf('native-P%d',degree);
  report=struct('config',cfg,'flux_degrees',flux_degrees,'entry_epoch',entry_epoch,'launch_epoch',launch_epoch, ...
    'startup_seconds',entry_epoch-launch_epoch,'levels',{{}},'status','STARTED');
  timing=struct('wide_search',0,'field_generation',0,'preparation',0,'evaluator_check',0,'cache_check',0,'output',0);
  active_stage='wide_search';stage_clock=tic;
  try
    search=fem_i9_run(fullfile(output_dir,'search'),window);timing.wide_search=toc(stage_clock);
    report.search=search;checkpoint();assert(numel(search.candidate_ids)==1,'pipeline:Candidates','Multiple or zero candidates: stop before continuation.');
    k_start=search.modes(search.candidate_ids).k;
    report.p2_frequency=k_start;report.p2_relative_difference=abs(k_start-validation_values('p2'))/validation_values('p2');checkpoint();
    active_stage='field_generation';
    assert(abs(k_start-validation_values('p2'))/validation_values('p2')<=1e-12,'pipeline:P2','Copied P2 result mismatch.');
    stage_clock=tic;
    [native,generation]=direct_native('generate',k_start,fullfile(output_dir,'generation'),degree);
    timing.field_generation=toc(stage_clock);
    report.generation=generation;report.p3_relative_difference=abs(generation.frequency-validation_values('p3'))/validation_values('p3');checkpoint();
    assert(abs(generation.frequency-validation_values('p3'))/validation_values('p3')<=1e-12,'pipeline:P3','P3 result mismatch.');
    report.generation=generation;checkpoint();
    active_stage='preparation';stage_clock=tic;
    if degree>2,P=direct_pipeline('prepare',cfg,native);clear native;else,P=direct_pipeline('prepare',cfg);end
    timing.preparation=toc(stage_clock);report.preparation_timing=P.timing;report.native_trace=P.native_trace;
    report.primary_areas=cellfun(@(x)x.area,P.templates,'UniformOutput',false);report.counts=P.counts;
    aa=[report.primary_areas{:}];report.preparation_pass=P.native_trace.cell_relative<1e-10&&P.native_trace.phase_relative<1e-10 ...
      &&max([aa.relative_error])<1e-12&&max(abs([aa.cell_area]-1))<1e-12;
    checkpoint();assert(report.preparation_pass,'direct:Preparation','Native traces or fitted areas failed.');
    active_stage='evaluator_check';stage_clock=tic;evaluator=direct_pipeline('evaluator_check',P,cfg);timing.evaluator_check=toc(stage_clock);
    report.evaluator=evaluator;checkpoint();assert(evaluator.pass,'direct:Evaluator','Independent native evaluation failed.');
    active_stage='cache_check';stage_clock=tic;report.cache=direct_pipeline('cache_check',P,cfg);timing.cache_check=toc(stage_clock);
    checkpoint();assert(report.cache.pass,'direct:Cache','Cache equality or key rejection failed.');
    for j=1:numel(flux_degrees)
      fd=flux_degrees(j);level=struct('degree',fd,'timing',struct('solve',0,'functional',0,'verification',0));
      active_stage=sprintf('RT%d_solve',fd);stage_clock=tic;
      S=direct_pipeline('solve',P,cfg,fd);level.timing.solve=toc(stage_clock);level.solve_timing=S.timing;
      level.solver=struct('global_residual',S.global_residual,'cell_residual',S.cell_residual,'trace_error',S.trace_error,'outer_normal_moment',S.outer_normal_moment);
      report.levels{j}=level;checkpoint();
      active_stage=sprintf('RT%d_functional',fd);stage_clock=tic;production=direct_pipeline('evaluate',P,S,cfg);level.timing.functional=toc(stage_clock);
      level.production=production;level.production_ready_seconds=toc(started);report.levels{j}=level;
      tt=tic;LOCAL_json(fullfile(output_dir,sprintf('rt%d-production.json',fd)),level);timing.output=timing.output+toc(tt);checkpoint();
      fprintf('PRODUCTION P%d/RT%d: q %.17g J %.17g width %.17g square %.17g Gram %.6g\n',degree,fd,production.q,production.J,production.width,production.qJ_square,production.gram_scaled);
      production.reference_width_relative=abs(production.square_interval.width-validation_values('width'))/validation_values('width');
      production.reference_contained=production.square_interval.enclosure(1)<=validation_values('mu')&&production.square_interval.enclosure(2)>=validation_values('mu');
      level.production=production;report.levels{j}=level;checkpoint();
      assert(production.reference_width_relative<=.005&&production.reference_contained,'pipeline:Reference','Interval reference check failed.');
      assert(production.pass,'direct:ProductionCheck','Required production check failed; timing and results saved.');
      % Verification only reads this S. Snapshot shares storage until a write.
      snapshot=S.flux;active_stage=sprintf('RT%d_verification',fd);stage_clock=tic;
      verification=direct_pipeline('verify',P,S,cfg);level.timing.verification=toc(stage_clock);
      verification.scaled_quadrature=P.q*abs(verification.J24-production.J)/production.qJ_minus_one;
      verification.square_scaled_quadrature=abs(verification.qJ_square24-production.qJ_square)/production.qJ_square;
      verification.square24_relative_difference=abs(P.q*verification.J24-1-verification.qJ_square24)/production.qJ_minus_one;
      verification.gram_scaled=production.gram_scaled;
      verification.quotient_relative_change=abs(verification.q24-P.q)/P.q;
      verification.quotient_change_over_width=abs(verification.q24-P.q)/production.width;
      verification.mass_relative_change=abs(verification.mass24-P.mass)/P.mass;
      verification.energy_relative_change=abs(verification.energy24-P.energy)/P.energy;
      verification.area_relative_max=max([verification.areas.relative_error]);verification.cell_area_max=max(abs([verification.areas.cell_area]-1));
      verification.unchanged=isequaln(snapshot,S.flux)&&isequal(P.q,production.q)&&isequal(P.mass,production.mass)&&isequal(P.energy,production.energy);
      verification.pass=verification.scaled_quadrature<.01&&verification.square_scaled_quadrature<.01 ...
        &&verification.square24_relative_difference<.01&&verification.quotient_relative_change<1e-12 ...
        &&verification.quotient_change_over_width<.01&&verification.mass_relative_change<1e-12&&verification.energy_relative_change<1e-12 ...
        &&verification.area_relative_max<1e-12&&verification.cell_area_max<1e-12&&verification.unchanged;
      level.verification=verification;level.pass=production.pass&&verification.pass;level.target_reached=level.pass&&production.width<=cfg.target_width;
      report.levels{j}=level;tt=tic;LOCAL_json(fullfile(output_dir,sprintf('rt%d-verification.json',fd)),level);timing.output=timing.output+toc(tt);checkpoint();
      fprintf('VERIFY RT%d: J24 %.17g quad %.6g square_quad %.6g qchange %.6g PASS %d\n',fd,verification.J24,verification.scaled_quadrature,verification.square_scaled_quadrature,verification.quotient_relative_change,verification.pass);
      assert(verification.pass,'direct:Verification','Required integration check failed; timing and results saved.');
      clear snapshot S
    end
    report.endpoint_cases=direct_pipeline('endpoints',P.q,production.qJ_square,[1.3174^2,2.1875^2;1.32^2,2.1875^2;1.32^2,2.37^2],validation_values('mu'));
    cc=report.endpoint_cases;report.C_ratio_error=abs((cc(2).width/cc(1).width)/(cc(2).C/cc(1).C)-1);
    assert(report.C_ratio_error<.001&&all([cc.contains_mu_BIE])&&all([cc.sign_conditions]),'gap:Endpoints','Endpoint comparison failed.');
    report.status='COMPLETE';report.pass=all(cellfun(@(x)x.pass,report.levels));checkpoint();
    finish=struct('function_seconds',toc(started),'finish_epoch',posixtime(datetime('now','TimeZone','UTC')));
    LOCAL_json(fullfile(output_dir,'finish.json'),finish);
  catch err
    report.status='FAILED';report.failure=struct('identifier',err.identifier,'message',err.message,'stage',active_stage,'stage_elapsed_seconds',toc(stage_clock));
    checkpoint();LOCAL_json(fullfile(output_dir,'finish.json'),struct('function_seconds',toc(started),'finish_epoch',posixtime(datetime('now','TimeZone','UTC'))));rethrow(err)
  end
  function checkpoint()
    elapsed=toc(started);known=sum(cell2mat(struct2cell(timing)));level_seconds=0;
    for jj=1:numel(report.levels),level_seconds=level_seconds+sum(cell2mat(struct2cell(report.levels{jj}.timing)));end
    report.timing=timing;report.timing.levels_total=level_seconds;report.timing.orchestration=elapsed-known-level_seconds;
    report.function_elapsed_seconds=elapsed;report.timing_sum_error=sum(cell2mat(struct2cell(report.timing)))-elapsed;
    report.active_stage=active_stage;
    tt=tic;LOCAL_json(fullfile(output_dir,'result.json'),report);LOCAL_json(fullfile(output_dir,'timing.json'),struct('stage',active_stage,'timing',report.timing,'enclosing_seconds',elapsed,'difference_seconds',report.timing_sum_error));timing.output=timing.output+toc(tt);
  end
end
function LOCAL_json(file,x)
  f=fopen(file,'w');assert(f>=0);cleanup=onCleanup(@()fclose(f)); %#ok<NASGU>
  fwrite(f,jsonencode(x,PrettyPrint=true),'char');
end
