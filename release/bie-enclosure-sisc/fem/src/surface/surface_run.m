function result=surface_run(out,band_path)
  % SURFACE_RUN Half-line surface counts and form-resolvent constants.
  % Input
  %   out: new output directory; band_path: matching band certificate JSON.
  % Output
  %   Four endpoint certificates and their explicit constants and conditions.
  band=jsondecode(fileread(band_path));
  assert(band.pass_all&&band.beta==.5&&band.d==1&&band.L==1&&isequal(band.materials(:),[.12;.20])&&isequal(band.rho(:),[1;17]));
  assert(band.k_lower==1.318&&band.k_upper==2.375,'fem:BandInput','Band window does not match the analytic response bounds.');
  if ~isfolder(out),mkdir(out);end;start=tic;alpha=[1.7424,5.6169];sides={'left','right'};a=[.12,.20];records=cell(2,2);
  for side=1:2
    for endpoint=1:2
      folder=fullfile(out,sprintf('%s-%d',sides{side},endpoint));
      h_bloch(folder,a(side),alpha(endpoint),26,64,2560,[5,40,endpoint==2]);
      r=jsondecode(fileread(fullfile(folder,'result.json')));
      for j=1:2
        z=r.tests(j);assert(z.negative_Cminus==z.negative_Cplus&&z.negative_Cminus==0&&z.gamma>0&&z.tail.t>0,'fem:Surface','Surface count failed.');
      end
      assert(max([r.curve_check_X,r.curve_check_IT,r.curve_check_TT,r.quad_difference_C,r.quad_difference_H,r.quad_difference_G,r.quad_difference_U])<1e-9);
      records{side,endpoint}=r;
    end
  end
  dp=min(alpha(2)-alpha(1),band.k_upper^2-alpha(2));dm=alpha(2)-alpha(1);
  kp=ceil((1+(alpha(2)+1)/dp)*1e9)/1e9;
  % Preserve the original deliberate extra 1e-5 slack, now derived from inputs.
  km=(ceil(((alpha(2)+1)/dm-1)*1e5)+1)/1e5;
  result=struct('beta',.5,'d',1,'L',1,'rho',[1,17],'materials',a,'alpha',alpha, ...
    'band_k',[band.k_lower,band.k_upper],'K_plus',kp,'K_minus',km,'d_plus',dp,'d_minus',dm, ...
    'lower_negative_counts',[records{1,1}.tests(2).negative_Cminus,records{2,1}.tests(2).negative_Cminus], ...
    'upper_negative_counts',[records{1,2}.tests(2).negative_Cminus,records{2,2}.tests(2).negative_Cminus], ...
    'gamma',[records{1,1}.tests(2).gamma,records{1,2}.tests(2).gamma,records{2,1}.tests(2).gamma,records{2,2}.tests(2).gamma], ...
    'pass',true,'rounding_covered',false,'seconds',toc(start));
  fid=fopen(fullfile(out,'surface.json'),'w');fwrite(fid,jsonencode(result,PrettyPrint=true));fclose(fid);
end
