function R=core_stage(out,band_path,surface_path,left_path,right_path,interval_path)
  % CORE_STAGE Count core negative directions and close isolation (H).
  % Input
  %   Explicit upstream band, surface, two DtN matrices and independent I_1.
  % Output
  %   Core count and H verdict, with all input-matching margins.
  A=jsondecode(fem_read('text',band_path));B=jsondecode(fem_read('text',surface_path));
  L=jsondecode(fem_read('text',left_path));D=jsondecode(fem_read('text',right_path));I=jsondecode(fem_read('text',interval_path));
  assert(A.pass_all&&B.pass&&B.beta==A.beta&&isequal(B.band_k(:),[A.k_lower;A.k_upper]),'fem:BandInput','Band verdict or model/window mismatch.');
  assert(A.d==B.d&&A.L==B.L&&isequal(A.materials(:),B.materials(:))&&isequal(A.rho(:),B.rho(:)));
  assert(all(B.lower_negative_counts==0)&&all(B.upper_negative_counts==0)&&all(B.gamma>0));
  for c={L,D}
    C=c{1};assert(C.all_trace_lower_bound&&C.phase==B.beta&&C.d==B.d&&C.L==B.L&&isequal(C.rho(:),B.rho(:)));
    assert(isequal(C.alpha(:),B.alpha(:))&&isequal(C.band_k(:),B.band_k(:))&&C.lambda==B.alpha(2)&&C.K_plus==B.K_plus&&C.K_minus==B.K_minus);
  end
  assert(strcmp(L.side,'left')&&strcmp(D.side,'right')&&L.material_a==B.materials(1)&&D.material_a==B.materials(2));
  assert(L.port_x==-.5&&D.port_x==.5&&L.inward_sigma==-1&&D.inward_sigma==1);
  z=I.I_1.endpoints;assert(z(1)>B.alpha(1)&&z(2)<B.alpha(2),'fem:Intersection','Independent spectral intersection must be inside isolation window.');
  R=core_run(out,31,16,512,left_path,right_path);
  assert(all(structfun(@(x)logical(x),R.tests)),'fem:Core','Core count or integration check failed.');
  verdict=struct('H',true,'alpha',B.alpha,'negative_count',R.negative_count,'safe_margin',R.safe_margin, ...
    'I_1',z,'intersection_margins',[z(1)-B.alpha(1),B.alpha(2)-z(2)], ...
    'surface_gammas',B.gamma,'high_tail_margins',[L.A_H,D.A_H],'rounding_covered',false);
  f=fopen(fullfile(out,'isolation.json'),'w');fwrite(f,jsonencode(verdict,PrettyPrint=true));fclose(f);
end
