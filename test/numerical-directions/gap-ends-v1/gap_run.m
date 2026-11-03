function report=gap_run(stage,output_dir)
  % GAP_RUN Evaluate the spectral gap endpoints using finite elements and DtN.
  % Input
  %   stage: baseline or scan; output_dir: new directory for compact records.
  % Output
  %   JSON and CSV records; no field or matrix binary output is saved.
  maxNumCompThreads(11);mkdir(output_dir);started=tic;
  if strcmp(stage,'baseline')
    epoch=posixtime(datetime('now','TimeZone','UTC'));
    report.baseline=window_pipeline([1.4509999999999998,2.2490000000000001],fullfile(output_dir,'baseline'),epoch);
    override=struct('shifts_mu',linspace(2.1875^2,2.38^2,9),'requested',24,'subspace',64);
    report.high_search=fem_i9_run(fullfile(output_dir,'high-search'),[2.1875,2.38],override);
  else
    report.p3=gap_scan_native('scan',3,'g48',unique([linspace(1.32,2.37,106),linspace(2.1875,2.38,40),1.32:.001:1.34,2.36:.001:2.38,2.1875,2.37,2.38]),fullfile(output_dir,'p3'));
    report.p2=gap_scan_native('scan',2,'g48',[1.32,2.1875,2.37,2.38],fullfile(output_dir,'p2'));
  end
  report.seconds=toc(started);f=fopen(fullfile(output_dir,'summary.json'),'w');fwrite(f,jsonencode(report,PrettyPrint=true));fclose(f);
end
