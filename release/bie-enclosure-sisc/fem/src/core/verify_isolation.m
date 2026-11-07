function result=verify_isolation(data,interval_path,out)
  % VERIFY_ISOLATION Recheck the canonical isolation inputs and count.
  % Input
  %   data: canonical band/surface/DtN files; interval_path: recomputed I_1.
  % Output
  %   Core matrix rebuilt, isolation verdict, and rejected bad-input control.
  if ~isfolder(out),mkdir(out);end;start=tic;
  b=verify_surface(data,out);c=verify_dtn(data,out);
  files={fullfile(data,'band.json'),fullfile(data,'surface.json'),fullfile(data,'left-certificate.json'),fullfile(data,'right-certificate.json'),interval_path};
  d=core_stage(fullfile(out,'core'),files{:});old=jsondecode(fem_read('text',fullfile(data,'core-result.json')));
  same=isequal(d.negative_count,old.negative_count)&&isequal(d.safe_margin,old.safe_margin)&&isequal(d.epsilon,old.epsilon);
  A=jsondecode(fem_read('text',files{1}));A.pass_all=false;bad=fullfile(out,'deliberately-invalid-band.json');f=fopen(bad,'w');fwrite(f,jsonencode(A));fclose(f);
  rejected=false;identifier='';try,core_stage(fullfile(out,'rejected'),bad,files{2:end});catch err,identifier=err.identifier;rejected=strcmp(identifier,'fem:BandInput');end
  result=struct('surface',b.pass,'dtn',c.pass,'core_exact_match',same,'bad_band_rejected',rejected,'control_error_identifier',identifier,'seconds',toc(start),'pass',b.pass&&c.pass&&same&&rejected);
  f=fopen(fullfile(out,'verification.json'),'w');fwrite(f,jsonencode(result));fclose(f);assert(result.pass);
end
