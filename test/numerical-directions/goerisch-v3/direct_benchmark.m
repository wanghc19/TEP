function report=direct_benchmark(input_dir,output_dir,degree,launch_epoch,flux_degrees)
  % Direct FEM/Goerisch benchmark. FEM means finite element method.
  % Input
  %   Explicit scientific input/output directories, FEM degree, launcher clock,
  %   and optional Raviart-Thomas degrees (for example [2,3]).
  % Output
  %   Scalar checkpoints and per-degree results; one shared field stays in memory.
  entry_epoch=posixtime(datetime('now','TimeZone','UTC'));started=tic;maxNumCompThreads(2);
  if nargin<5,flux_degrees=2;if degree==2,flux_degrees=[3,2];end;end
  assert(~isfolder(output_dir));mkdir(output_dir);
  cfg=direct_pipeline('config',input_dir,'D');cfg.fem_degree=degree;cfg.baseline_check=degree==2;cfg.level=sprintf('native-P%d',degree);
  report=struct('config',cfg,'flux_degrees',flux_degrees,'entry_epoch',entry_epoch,'launch_epoch',launch_epoch, ...
    'startup_seconds',entry_epoch-launch_epoch,'levels',{{}},'status','STARTED');
  timing=struct('field_generation',0,'preparation',0,'evaluator_check',0,'cache_check',0,'output',0);
  active_stage='field_generation';stage_clock=tic;
  try
    generation=struct('seconds',0,'degree',2,'frequency',1.558438079544167,'free_dofs',[12916,12756,12880], ...
      'triangles',[6410,6330,6392],'status','supplied_coarse_field');
    if degree>2
      [native,generation]=direct_native('generate',input_dir,fullfile(output_dir,'generation'),degree);
      timing.field_generation=toc(stage_clock);
    end
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
      if degree==3&&fd==2
        old=struct('q',3.4287286707248676,'J',.29165329089884617,'width',9.1335672800431646e-9);
        level.reproduction=struct('reference',old,'q_relative',abs(production.q-old.q)/old.q, ...
          'J_relative',abs(production.J-old.J)/old.J,'width_relative',abs(production.width-old.width)/old.width, ...
          'q_absolute',production.q-old.q,'J_absolute',production.J-old.J,'width_absolute',production.width-old.width);
        level.reproduction.all_relative_below_1e12=max([level.reproduction.q_relative,level.reproduction.J_relative,level.reproduction.width_relative])<=1e-12;
      end
      level.production=production;level.production_ready_seconds=toc(started);report.levels{j}=level;
      tt=tic;LOCAL_json(fullfile(output_dir,sprintf('rt%d-production.json',fd)),level);timing.output=timing.output+toc(tt);checkpoint();
      fprintf('PRODUCTION P%d/RT%d: q %.17g J %.17g width %.17g square %.17g Gram %.6g\n',degree,fd,production.q,production.J,production.width,production.qJ_square,production.gram_scaled);
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
