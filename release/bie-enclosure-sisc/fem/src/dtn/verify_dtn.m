function result=verify_dtn(data,out)
  % VERIFY_DTN Reassemble Dirichlet-to-Neumann bounds from canonical Grams.
  % Input
  %   data: Q/R/Z matrices, integral/series errors and surface constants.
  % Output
  %   Recomputed lower matrices and a finite-form equality check.
  if ~isfolder(out),mkdir(out);end;B=jsondecode(fem_read('text',fullfile(data,'surface.json')));sides={'left','right'};rows=struct([]);
  for j=1:2
    r=jsondecode(fem_read('text',fullfile(data,sides{j},'result.json')));C=jsondecode(fem_read('text',fullfile(data,[sides{j},'-certificate.json'])));
    assert(strcmp(C.side,sides{j})&&C.port_x==j-1.5&&C.inward_sigma==2*j-3&&isequal(C.Fourier_indices(:),(-16:16)'));
    assert(C.K_plus==B.K_plus&&C.K_minus==B.K_minus&&C.lambda==B.alpha(2)&&C.material_a==B.materials(j)&&C.phase==B.beta);
    beta=.5+2*pi*(-16:16);bst=2*pi*17-.5;ks=sqrt(bst^2-B.alpha(2));ah=sqrt((bst^2-B.alpha(2))/(bst^2+1));bh=.5*(6/(.125^2*ks)+3/.125)^2*exp(-.25*ks);AH=ah-B.K_plus*bh;
    Q=r.Q_real+1i*r.Q_imag;R=r.R_real+1i*r.R_imag;Z=r.Z_real+1i*r.Z_imag;
    low=Q-r.eps_Q*eye(33)-B.K_plus*(R+r.eps_R*eye(33))-(bh/AH)*(Z+r.eps_Z*eye(33));
    high=Q+r.eps_Q*eye(33)+B.K_minus*(R+r.eps_R*eye(33));
    old=r.lower_real+1i*r.lower_imag;scale=diag(1./sqrt(sqrt(1+beta.^2)));
    gap=norm(scale*(high-low)*scale);delta=norm(low-old,'fro');
    z=struct('side',sides{j},'lower_difference',delta,'exact_match',isequal(low,old)&&isequal(high,r.upper_real+1i*r.upper_imag),'A_H',AH,'normalized_gap',gap,'pass',AH>0&&delta==0&&r.K_r<4e-4);
    rows=[rows,z]; %#ok<AGROW>
  end
  result=struct('rows',rows,'pass',all([rows.pass])&&all([rows.exact_match]));
  f=fopen(fullfile(out,'dtn-verify.json'),'w');fwrite(f,jsonencode(result));fclose(f);assert(result.pass);
end
