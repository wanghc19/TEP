function result=verify_surface(data,out)
  % VERIFY_SURFACE Recheck surface inertias from canonical integral matrices.
  % Input
  %   data: endpoint integral matrices and their analytic remainder bounds.
  % Output
  %   Recomputed error matrices, counts, resolvent constants and comparisons.
  if ~isfolder(out),mkdir(out);end;sides={'left','right'};rows=cell(2,2);equal=true;start=tic;
  band=jsondecode(fem_read('text',fullfile(data,'band.json')));assert(band.pass_all&&band.beta==.5&&band.k_lower==1.318&&band.k_upper==2.375);
  assert(band.d==1&&band.L==1&&isequal(band.materials(:),[.12;.20])&&isequal(band.rho(:),[1;17]));
  for side=1:2
    for ep=1:2
      folder=fullfile(data,sprintf('%s-%d',sides{side},ep));r=jsondecode(fem_read('text',fullfile(folder,'result.json')));
      a=[.12,.20];lambda=[1.7424,5.6169];assert(r.material==a(side)&&r.lambda==lambda(ep));
      C=LOCAL_matrix(r,'C');H=LOCAL_matrix(r,'H');V=LOCAL_matrix(r,'V2');U=LOCAL_matrix(r,'U');p=size(C,1);K=r.form_inverse;
      E=K*H+(r.eps_C+K*r.eps_H)*eye(p);HU=H+r.eps_H*eye(p);UU=U+r.eps_U*eye(p);VU=V+r.eps_V2*eye(p);
      if ep==2
        coefficient=17*r.lambda*(1+r.lambda/r.d_per);E=H+coefficient*V+(r.eps_C+r.eps_H+coefficient*r.eps_V2)*eye(p);
        t=h_endpoint(C,E,UU,HU,r.lambda,r.d_per,VU);
      else,t=h_endpoint(C,E,UU,HU,r.lambda,r.d_per);end
      equal=equal&&isequal(E,LOCAL_matrix(r,'E'))&&isequaln(t,r.tests);
      assert(all([t.negative_Cminus]==0)&&all([t.negative_Cplus]==0)&&all([t.gamma]>0));rows{side,ep}=t;
    end
  end
  old=jsondecode(fem_read('text',fullfile(data,'surface.json')));dp=min(diff(old.alpha),band.k_upper^2-old.alpha(2));
  kp=ceil((1+(old.alpha(2)+1)/dp)*1e9)/1e9;km=(ceil(((old.alpha(2)+1)/diff(old.alpha)-1)*1e5)+1)/1e5;
  result=struct('exact_matrix_and_count_match',equal,'K_plus',kp,'K_minus',km,'gammas',[rows{1,1}(2).gamma,rows{1,2}(2).gamma,rows{2,1}(2).gamma,rows{2,2}(2).gamma], ...
    'pass',equal&&kp==old.K_plus&&km==old.K_minus,'seconds',toc(start));
  fid=fopen(fullfile(out,'surface-verify.json'),'w');fwrite(fid,jsonencode(result));fclose(fid);assert(result.pass);
end
function x=LOCAL_matrix(r,name)
  % Input: real and imaginary JSON arrays. Output: their complex matrix.
  x=r.([name,'_real'])+1i*r.([name,'_imag']);
end
