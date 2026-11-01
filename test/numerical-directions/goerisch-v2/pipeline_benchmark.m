function report=pipeline_benchmark(input_dir,output_dir,kind,launch_epoch)
  % Benchmark the reusable Goerisch pipeline. R is reconstructed; D is direct.
  % Input
  %   input_dir: explicit saved I9.6 inputs; output_dir: new scalar-output folder.
  %   kind: R or D; launch_epoch: launcher clock for startup accounting only.
  % Output
  %   report and production.json/result.json; large states remain in memory.
  entry_epoch=posixtime(datetime('now','TimeZone','UTC'));started=tic;
  assert(~isfolder(output_dir),'pipeline:Output','Output folder already exists.');mkdir(output_dir);
  cfg=goerisch_pipeline('config',input_dir,kind);maxNumCompThreads(2);
  P=goerisch_pipeline('prepare',cfg);S=goerisch_pipeline('solve',P,cfg,3);production=goerisch_pipeline('evaluate',P,S,cfg);
  tt=tic;LOCAL_json(fullfile(output_dir,'production.json'),production);production_output=toc(tt);
  production_seconds=toc(started);ready_epoch=posixtime(datetime('now','TimeZone','UTC'));
  fprintf('PRODUCTION q %.17g J %.17g width %.17g; baseline differences %.4g %.4g %.4g\n',production.q,production.J,production.width,production.baseline_q_relative,production.baseline_width_relative,production.baseline_J_scaled);
  assert(production.pass,'pipeline:ProductionChecks','Required production check failed; saved production.json.');
  production_snapshot=production;flux_snapshot=S.flux;trial_snapshot=P.trial;
  verification_started=tic;verification=goerisch_pipeline('verify',P,S,cfg);
  verification.scaled_quadrature=P.q*abs(verification.J24-production.J)/(production.qJ_minus_one);
  verification.gram_scaled=production.gram_scaled;
  verification.area_relative_max=max([verification.areas.relative_error]);
  verification.cell_area_error_max=max(abs([verification.areas.cell_area]-1));
  verification.pass=verification.scaled_quadrature<.01&&verification.gram_scaled<.01 ...
    &&verification.area_relative_max<1e-12&&verification.cell_area_error_max<1e-12&&verification.normalization.pass;
  LOCAL_json(fullfile(output_dir,'verification.json'),verification);
  assert(verification.pass,'pipeline:VerificationChecks','Required quadrature/area check failed; saved verification.json.');
  audit=goerisch_pipeline('audit',P,S,cfg);tt=tic;cache=goerisch_pipeline('cache_check',P,cfg);cache_seconds=toc(tt);
  tt=tic;after=goerisch_pipeline('evaluate',P,S,cfg);recheck_seconds=toc(tt);
  tt=tic;unchanged=struct('q',isequal(production.q,after.q),'J',isequal(production.J,after.J), ...
    'interval',isequal(production.enclosure,after.enclosure),'flux',isequaln(flux_snapshot,S.flux), ...
    'trial',isequaln(trial_snapshot,P.trial),'production_record',isequaln(production_snapshot,production));
  comparison_seconds=toc(tt);
  assert(cache.pass&&all(cell2mat(struct2cell(unchanged))),'pipeline:Reuse','Required cache/immutability check failed.');
  verification_seconds=toc(verification_started);
  prodtime=P.timing;prodtime.basis=S.timing.basis;prodtime.assembly=S.timing.assembly;prodtime.solve=S.timing.solve;
  prodtime.solve_other=S.timing.other;prodtime.functional=production.seconds;prodtime.production_output=production_output;
  prodtime.orchestration=production_seconds-sum(cell2mat(struct2cell(prodtime)));
  vertime=verification.timing;vertime.component_audit=audit.seconds;vertime.cache_check=cache_seconds;
  vertime.recheck_functional=recheck_seconds;vertime.immutability_comparison=comparison_seconds;
  vertime.verification_output_and_orchestration=verification_seconds-sum(cell2mat(struct2cell(vertime)));
  counts=P.counts;counts.assembly_cache_hits=S.cache_hits;counts.functional_cache_hits=production.cache_hits;
  counts.audit_cache_hits=audit.cache_hits;counts.recheck_cache_hits=after.cache_hits;counts.higher_evaluated_batches=verification.evaluated_batches;counts.higher_values=verification.evaluated_values;
  report=struct('config',cfg,'production',production,'verification',verification,'audit',audit,'cache_check',cache, ...
    'unchanged',unchanged,'primary_areas',{cellfun(@(x)x.area,P.templates,'UniformOutput',false)}, ...
    'tail_relative_upper',P.tail_relative_upper,'tail_allowance',P.tail_allowance,'input_inventory',P.input_inventory,'normalization',P.norms,'counts',counts, ...
    'prepare_seconds',P.seconds,'solve_seconds',S.seconds,'production_seconds',production_seconds, ...
    'verification_seconds',verification_seconds,'production_timing',prodtime,'verification_timing',vertime, ...
    'launch_epoch',launch_epoch,'entry_epoch',entry_epoch,'ready_epoch',ready_epoch, ...
    'startup_to_entry_seconds',entry_epoch-launch_epoch,'cold_production_seconds',ready_epoch-launch_epoch, ...
    'cold_plus_verification_seconds',ready_epoch-launch_epoch+verification_seconds);
  report.production_timing_sum_error=sum(cell2mat(struct2cell(prodtime)))-production_seconds;
  report.verification_timing_sum_error=sum(cell2mat(struct2cell(vertime)))-verification_seconds;
  report.timing_pass=abs(report.production_timing_sum_error)<=max(.1,.01*production_seconds) ...
    &&abs(report.verification_timing_sum_error)<=max(.1,.01*verification_seconds);
  assert(report.timing_pass);
  report.function_before_final_output_seconds=toc(started);tt=tic;LOCAL_json(fullfile(output_dir,'result.json'),report);
  finish=struct('final_result_output_seconds',toc(tt),'function_seconds',toc(started),'finish_epoch',posixtime(datetime('now','TimeZone','UTC')));
  LOCAL_json(fullfile(output_dir,'finish.json'),finish);
  fprintf('COMPLETE %s cold production %.3f s, verification %.3f s, width %.17g\n',kind,report.cold_production_seconds,verification_seconds,production.width);
end
function LOCAL_json(path,value)
  f=fopen(path,'w');assert(f>=0);c=onCleanup(@()fclose(f)); %#ok<NASGU>
  fwrite(f,jsonencode(value,PrettyPrint=true),'char');
end
