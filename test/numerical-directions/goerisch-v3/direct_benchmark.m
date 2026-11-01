function report=direct_benchmark(input_dir,output_dir,degree,launch_epoch)
  % Direct FEM/Goerisch refinement benchmark. FEM means finite element method.
  % Input
  %   input_dir: explicit coarse native input; output_dir: new output directory.
  %   degree: 2 for the saved-field pilot, or 3/4 for new FEM/DtN root solves.
  %   launch_epoch: launcher clock, used only for accounting.
  % Output
  %   Compact results, checks and timings. Native fields and flux stay in memory.
  entry_epoch=posixtime(datetime('now','TimeZone','UTC'));started=tic;maxNumCompThreads(2);
  assert(~isfolder(output_dir));mkdir(output_dir);cfg=direct_pipeline('config',input_dir,'D');
  cfg.fem_degree=degree;cfg.baseline_check=degree==2;cfg.level=sprintf('native-P%d',degree);
  generation=struct('seconds',0,'degree',2,'frequency',1.558438079544167,'free_dofs',[12916,12756,12880], ...
    'triangles',[6410,6330,6392],'status','supplied_coarse_field');
  field_timer=tic;
  if degree>2
    [native,generation]=direct_native('generate',input_dir,fullfile(output_dir,'generation'),degree);
    field_seconds=toc(field_timer);P=direct_pipeline('prepare',cfg,native);clear native
  else,field_seconds=0;P=direct_pipeline('prepare',cfg);end
  tt=tic;evaluator=direct_pipeline('evaluator_check',P,cfg);evaluator_seconds=toc(tt);
  LOCAL_json(fullfile(output_dir,'evaluator.json'),evaluator);assert(evaluator.pass,'direct:Evaluator','Independent native evaluation failed.');
  % Baseline RT3 reproduces v2. Refined trials use stable RT2 to avoid
  % unnecessary RT3 Gram cancellation once the trial residual is much smaller.
  flux_degree=2;if degree==2,flux_degree=3;end
  S=direct_pipeline('solve',P,cfg,flux_degree);production=direct_pipeline('evaluate',P,S,cfg);
  tt=tic;LOCAL_json(fullfile(output_dir,'production.json'),production);production_output=toc(tt);
  production_seconds=toc(started);ready_epoch=posixtime(datetime('now','TimeZone','UTC'));
  fprintf('PRODUCTION P%d/RT%d: q %.17g J %.17g width %.17g ratio %.8g\n',degree,flux_degree,production.q,production.J,production.width,production.width/cfg.target_width);
  assert(production.pass,'direct:ProductionCheck','Required production check failed; saved production.json.');
  snapshot=S.flux;verification_start=tic;verification=direct_pipeline('verify',P,S,cfg);
  verification.scaled_quadrature=P.q*abs(verification.J24-production.J)/production.qJ_minus_one;
  verification.gram_scaled=production.gram_scaled;
  verification.quotient_relative_change=abs(verification.q24-P.q)/P.q;
  verification.quotient_change_over_width=abs(verification.q24-P.q)/production.width;
  verification.area_relative_max=max([verification.areas.relative_error]);verification.cell_area_max=max(abs([verification.areas.cell_area]-1));
  verification.pass=verification.scaled_quadrature<.01&&verification.gram_scaled<.01 ...
    &&verification.quotient_relative_change<1e-12&&verification.quotient_change_over_width<.01 ...
    &&verification.area_relative_max<1e-12&&verification.cell_area_max<1e-12;
  LOCAL_json(fullfile(output_dir,'verification.json'),verification);assert(verification.pass,'direct:Verification','Required integration check failed.');
  tt=tic;after=direct_pipeline('evaluate',P,S,cfg);unchanged=isequaln(snapshot,S.flux)&&isequal(production.q,after.q)&&isequal(production.J,after.J)&&isequal(production.enclosure,after.enclosure);recheck_seconds=toc(tt);
  assert(unchanged,'direct:Unchanged','Verification changed the trial/flux output.');verification_seconds=toc(verification_start);
  % One targeted coarse RT2 control supplies the nearest measured coarser row
  % using the same prepared P2 trial, after the copied RT3 check has passed.
  control=struct();control_seconds=0;
  if degree==2
    control_start=tic;S2=direct_pipeline('solve',P,cfg,2);r2=direct_pipeline('evaluate',P,S2,cfg);v2=direct_pipeline('verify',P,S2,cfg);
    control=struct('production',r2,'verification',v2,'scaled_quadrature',P.q*abs(v2.J24-r2.J)/r2.qJ_minus_one,'solve_seconds',S2.seconds);
    control.pass=r2.pass&&control.scaled_quadrature<.01&&abs(v2.q24-P.q)/P.q<1e-12;
    LOCAL_json(fullfile(output_dir,'coarse-rt2.json'),control);assert(control.pass,'direct:Control','Coarse RT2 control failed.');control_seconds=toc(control_start);clear S2
  end
  timing=struct('field_generation',field_seconds,'preparation',P.seconds,'evaluator_check',evaluator_seconds, ...
    'flux_solve',S.seconds,'functional',production.seconds,'production_output',production_output);
  timing.production_orchestration=production_seconds-sum(cell2mat(struct2cell(timing)));
  report=struct('config',cfg,'generation',generation,'field_generation_seconds',field_seconds, ...
    'production',production,'verification',verification,'evaluator',evaluator,'native_trace',P.native_trace, ...
    'primary_areas',{cellfun(@(x)x.area,P.templates,'UniformOutput',false)},'counts',P.counts, ...
    'unchanged',unchanged,'target_reached',production.width<=cfg.target_width,'width_over_target',production.width/cfg.target_width, ...
    'coarse_rt2',control,'coarse_rt2_extra_seconds',control_seconds,'production_seconds',production_seconds, ...
    'goerisch_production_seconds',production_seconds-field_seconds,'verification_seconds',verification_seconds, ...
    'preparation_timing',P.timing,'solve_timing',S.timing,'production_timing',timing, ...
    'verification_recheck_seconds',recheck_seconds,'verification_output_other_seconds',verification_seconds-verification.seconds-recheck_seconds, ...
    'entry_epoch',entry_epoch,'launch_epoch',launch_epoch,'ready_epoch',ready_epoch, ...
    'startup_seconds',entry_epoch-launch_epoch,'cold_production_seconds',ready_epoch-launch_epoch, ...
    'cold_plus_verification_seconds',ready_epoch-launch_epoch+verification_seconds);
  report.timing_sum_error=sum(cell2mat(struct2cell(timing)))-production_seconds;
  report.function_before_output_seconds=toc(started);tt=tic;LOCAL_json(fullfile(output_dir,'result.json'),report);
  finish=struct('output_seconds',toc(tt),'function_seconds',toc(started),'finish_epoch',posixtime(datetime('now','TimeZone','UTC')));
  LOCAL_json(fullfile(output_dir,'finish.json'),finish);
  fprintf('COMPLETE P%d: production %.3fs, field %.3fs, verification %.3fs, target %d\n',degree,production_seconds,field_seconds,verification_seconds,report.target_reached);
end
function LOCAL_json(file,x)
  f=fopen(file,'w');assert(f>=0);cleanup=onCleanup(@()fclose(f)); %#ok<NASGU>
  fwrite(f,jsonencode(x,PrettyPrint=true),'char');
end
