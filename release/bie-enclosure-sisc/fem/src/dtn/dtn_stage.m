function result=dtn_stage(out,band_path,surface_path)
  % DTN_STAGE Dirichlet-to-Neumann all-trace lower matrix certificates.
  % Input
  %   Explicit band and surface JSON files, and a fresh output directory.
  % Output
  %   Left/right integral matrices and all-trace certificate handoffs.
  A=jsondecode(fem_read('text',band_path));B=jsondecode(fem_read('text',surface_path));
  assert(A.pass_all&&B.pass&&A.beta==B.beta&&B.beta==.5&&B.d==1&&B.L==1);
  assert(A.d==B.d&&A.L==B.L&&isequal(A.materials(:),B.materials(:))&&isequal(A.rho(:),B.rho(:)));
  assert(isequal(B.materials(:),[.12;.20])&&isequal(B.rho(:),[1;17])&&isequal(B.alpha(:),[1.7424;5.6169]));
  assert(isequal(B.band_k(:),[A.k_lower;A.k_upper])&&all(B.lower_negative_counts==0)&&all(B.upper_negative_counts==0));
  if ~isfolder(out),mkdir(out);end;start=tic;sides={'left','right'};result=struct();
  for j=1:2
    side=sides{j};folder=fullfile(out,side);r=dtn_run(folder,side,'g48',4,16,true,12,B);
    assert(r.A_H>0&&r.K_r<4e-4&&r.min_lower_raw>0&&r.alternative.overlap_min_1>0&&r.alternative.overlap_min_2>0,'fem:DtN','DtN certificate failed.');
    c=struct('side',side,'lambda',B.alpha(2),'material_a',B.materials(j),'port_x',j-1.5,'inward_sigma',2*j-3, ...
      'beta',.5+2*pi*(-16:16),'phase',.5,'d',1,'L',1,'rho',[1,17],'alpha',B.alpha,'band_k',B.band_k, ...
      'Fourier_indices',-16:16,'K_plus',B.K_plus,'K_minus',B.K_minus,'A_H',r.A_H,'r',r.r,'K_r',r.K_r, ...
      'hat_Lambda',struct('real',r.lower_real,'imag',r.lower_imag),'all_trace_lower_bound',true,'rounding_covered',false);
    f=fopen(fullfile(out,[side,'-certificate.json']),'w');fwrite(f,jsonencode(c,PrettyPrint=true));fclose(f);result.(side)=r;
  end
  result.seconds=toc(start);f=fopen(fullfile(out,'summary.json'),'w');fwrite(f,jsonencode(result,PrettyPrint=true));fclose(f);
end
