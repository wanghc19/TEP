function R=core_run(out,Nx,Ny,J,left_path,right_path)
% Core count for the isolation hypothesis at lambda=5.6169.
% Input: fresh output directory, cutoffs, curve nodes, two lower DtN JSON files.
% Output: small scalar certificate/check records; no MAT or dense matrix files.
  maxNumCompThreads(11);if ~exist(out,'dir'),mkdir(out);end;started=tic;lambda=5.6169;
  S=core_space(Nx,Ny);check=core_checks(S,J);assert(check.area_relative_difference<1e-12,'core:Baseline','Copied curve area failed baseline.');
  left=jsondecode(fileread(left_path));right=jsondecode(fileread(right_path));
  assert(all(left.Fourier_indices(:)==(-16:16)')&&all(right.Fourier_indices(:)==(-16:16)'));
  assert(max(abs(left.beta(:)-(.5+2*pi*(-16:16)')))<1e-13&&left.port_x==-.5&&right.port_x==.5);
  L=left.hat_Lambda.real+1i*left.hat_Lambda.imag;Rr=right.hat_Lambda.real+1i*right.hat_Lambda.imag;
  U=[chol(L)*S.B_left;chol(Rr)*S.B_right];B=U'*U;symB=norm(B-B','fro')/max(norm(B,'fro'),realmin);
  [A,material]=core_material(S,J);[Ah,higher]=core_material(S,2*J);
  diff=norm(A-Ah,'fro');normalized_change=norm(S.P'*(A-Ah)*S.P,'fro');clear Ah
  material.doubled_raw_difference=diff;material.doubled_normalized_difference=normalized_change;material.doubled_bound=material.normalized_error+higher.normalized_error;
  material.doubled_contained=normalized_change<=material.doubled_bound;material.higher=higher;
  Q=(lambda+1)*S.M1+3*lambda*full(S.P'*A*S.P);clear A
  symQ=norm(Q-Q','fro')/norm(Q,'fro');Q=(Q+Q')/2;n=S.n;
  T=eye(n)-Q+B;T=(T+T')/2;opts=struct('issym',true,'isreal',false,'tol',1e-11,'maxit',2000,'p',32,'v0',sin((1:n)')+1i*cos(sqrt(2)*(1:n)'));
  [vt,dt,ft]=eigs(T,4,'smallestreal',opts);evT=sort(real(diag(dt)));resT=norm(T*vt-vt*dt,'fro');clear T
  [V,D,~]=svd(U','econ');gain=(1+diag(D).^2).^(-.5)-1;
  apply=@(v)LOCAL_scale(V,gain,Q*LOCAL_scale(V,gain,v));
  [vm,dm,fm]=eigs(apply,n,4,'largestreal',opts);nu=sort(real(diag(dm)),'descend');mu=1./nu-1;resMu=norm(apply(vm)-vm*dm,'fro');clear vm V D
  center=eye(n)-Q/S.c_W+B;center=(center+center')/2;clear B Q U
  [ve,de,fl]=eigs(center,4,'smallestreal',opts);evL=sort(real(diag(de)));resL=norm(center*ve-ve*de,'fro');clear ve
  epsilon=3*lambda*material.normalized_error/S.c_W;safe_gamma=evL(2)-max(10*resL,1e-10);
  [count,pivot]=LOCAL_inertia(center-epsilon*eye(n));shift_count=NaN;shift_pivot=NaN;
  if safe_gamma>0,[shift_count,shift_pivot]=LOCAL_inertia(center-safe_gamma*eye(n));end
  R=struct('Nx',Nx,'Ny',Ny,'base_dimension',S.nb,'dimension',n,'curve_nodes',J,'a_star',S.a_star,'C_h',S.C_h,'c_W',S.c_W,'delta',S.delta, ...
    'H_min',S.H_min,'H_defect',S.H_defect,'tail_Gram_min',S.tail_Gram_min,'P_norm_squared_bound',S.P_norm_squared_bound, ...
    'mu',mu,'T_low_normalized_eigenvalues',evT,'L_center_normalized_eigenvalues',evL,'gamma_2',evL(2),'verified_gamma_lower',safe_gamma,'epsilon',epsilon,'safe_margin',safe_gamma-epsilon, ...
    'negative_count',count,'min_abs_pivot',pivot,'shifted_count',shift_count,'shifted_min_abs_pivot',shift_pivot,'residual_T',resT,'residual_mu',resMu,'residual_L',resL,'eigs_flags',[ft,fm,fl], ...
    'symmetry_H',0,'symmetry_Mq',symQ,'symmetry_boundary',symB,'material',material,'checks',check,'seconds',toc(started));
  R.tests=struct('moments',all(check.moment_relative_difference<1e-12),'representatives',check.representative_max_absolute<1e-11&&check.representative_random_relative<1e-11, ...
    'Hermitian_H',symQ<1e-12&&symB<1e-12&&S.H_defect<1e-11&&S.tail_Gram_min>0, ...
    'doubling',material.doubled_contained,'solvers',all([ft,fm,fl]==0),'one_negative',count==1,'positive_second_certified',safe_gamma>epsilon&&shift_count==1);
  f=fopen(fullfile(out,'result.json'),'w');fprintf(f,'%s\n',jsonencode(R));fclose(f);
  fprintf('CORE (%d,%d) n=%d mu2 %.12g delta %.12g gamma2 %.12g epsilon %.3e negative %d seconds %.1f\n',Nx,Ny,n,mu(2),S.delta,evL(2),epsilon,count,toc(started));disp(R.tests);
end
function y=LOCAL_scale(V,gain,x)
  y=x+V*(gain.*(V'*x));
end
function [count,pivot]=LOCAL_inertia(A)
  [~,D]=ldl(A);n=size(D,1);count=0;pivot=inf;i=1;
  while i<=n
    if i<n&&D(i+1,i)~=0,d=real(eig(D(i:i+1,i:i+1)));i=i+2;else,d=real(D(i,i));i=i+1;end
    count=count+nnz(d<0);pivot=min(pivot,min(abs(d)));
  end
  assert(pivot>0,'core:Pivot','Singular finite pivot block.');
end
