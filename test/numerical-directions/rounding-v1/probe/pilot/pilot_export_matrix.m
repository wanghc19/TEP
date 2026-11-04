function pilot_export_matrix(out,center,epsilon)
% Pilot export of the fixed floating core matrix and a real Cholesky witness.
% Input: floating center, floating scalar penalty. Output: compressed v7 data.
  n=size(center,1);target=center-epsilon*eye(n);assert(isequal(target,target'));
  T_real=real(target);imag_max=max(abs(imag(target)),[],'all');assert(all(isfinite(target),'all'));
  opts=struct('tol',1e-12,'maxit',2000,'v0',sin((1:n)'));[v_negative,~,flag]=eigs(T_real,1,'smallestreal',opts);assert(flag==0);v_negative=real(v_negative);
  gamma_target=.36537;tau=8;A=T_real-gamma_target*eye(n)+tau*(v_negative*v_negative');A=(A+A')/2;
  R_factor=chol(A);assert(all(diag(R_factor)>0));
  save(fullfile(out,'pilot.mat'),'T_real','R_factor','v_negative','imag_max','gamma_target','tau','epsilon','-v7');
  info=dir(fullfile(out,'pilot.mat'));assert(info.bytes<18e6,'pilot:Disk','Pilot MAT exceeds its reserved budget.');
  f=fopen(fullfile(out,'pilot-export.json'),'w');fprintf(f,'%s\n',jsonencode(struct('dimension',n,'imag_max',imag_max,'mat_bytes',info.bytes,'target','Frozen Hermitian double L_cert; exact real part plus exact max-absolute imaginary entry','gamma_target',gamma_target,'tau',tau)));fclose(f);
end
