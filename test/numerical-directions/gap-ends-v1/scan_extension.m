function report=LOCAL_scan(p,group,ks,output_dir)
  % Scan the full reduced core form and the stable lead trace projection.
  started=tic;mkdir(output_dir);maxNumCompThreads(11);
  config=direct_native_config(group);config.orders=p;config.window=[min(ks),max(ks)];
  ctx=struct('config',config,'started',started,'output_dir',output_dir, ...
    'iterations_path',fullfile(output_dir,'iterations.csv'),'progress_path',fullfile(output_dir,'progress.json'));
  LOCAL_iteration_header(ctx.iterations_path);LOCAL_ledger('reset');
  [mesh,geometry]=LOCAL_mesh(config);assert(strcmp(geometry.status,'PASS'));
  sp=LOCAL_space(config,mesh,p);spaces=cell(1,p);spaces{p}=sp;
  basis=LOCAL_basis_checks(p);edges=LOCAL_edge_traces(config,mesh,spaces);
  assert(all([basis.pass])&&edges.pass);
  band=LOCAL_band_locate(config,mesh,config.rules(1),spaces);assert(band.total_failures==0);
  ops=LOCAL_operators(ctx,sp,band,config.rules(1),false,false);clear band spaces mesh sp
  rows=struct([]);root_records=struct([]);
  for j=1:numel(ks)
    k=ks(j);mu=k^2;tt=tic;D=cell(1,2);names={'left','right'};
    row=struct('p',p,'k',k,'mu',mu,'valid',true,'reason','','negative_index',NaN, ...
      'interior_index',NaN,'wall_index',NaN,'T_min_abs',NaN,'T_norm1',NaN,'T_relative_margin',NaN, ...
      'T_nearest_eigenvalue',NaN,'T_eigs_residual',NaN,'full_ldl_index',NaN,'F_min_abs',NaN,'F_norm2',NaN, ...
      'left_D_norm2',NaN,'right_D_norm2',NaN,'left_D_min',NaN,'right_D_min',NaN, ...
      'left_D_max',NaN,'right_D_max',NaN,'left_Z0_smin',NaN,'right_Z0_smin',NaN, ...
      'left_Z0_rcond',NaN,'right_Z0_rcond',NaN,'left_unit_gap',NaN,'right_unit_gap',NaN, ...
      'left_cell_condest',NaN,'right_cell_condest',NaN,'seconds',0);
    for side=1:2
      name=names{side};[Sl,ci]=LOCAL_eliminate(config,ops.(name),mu,'lu');
      if ~ci.valid,row.valid=false;row.reason=[name,': ',ci.reason];break,end
      [D{side},~,di]=LOCAL_dtn(config,Sl,ops.n);
      if ~di.valid,row.valid=false;row.reason=[name,': ',di.reason];break,end
      d=real(eig((D{side}+D{side}')/2));row.([name,'_D_norm2'])=max(abs(d));
      row.([name,'_D_min'])=min(d);row.([name,'_D_max'])=max(d);
      row.([name,'_Z0_smin'])=di.z0_smin;row.([name,'_Z0_rcond'])=di.z0_rcond;
      row.([name,'_unit_gap'])=di.unit_gap_min;row.([name,'_cell_condest'])=ci.condest;
    end
    if row.valid
      t=ops.center;A=t.K-mu*t.M;I=t.interior;W=t.wall;
      [Sc,ci]=LOCAL_eliminate(config,t,mu,'lu');assert(ci.valid,ci.reason);
      row.interior_index=LOCAL_inertia(A(I,I));F=Sc+blkdiag(D{1},D{2});F=(F+F')/2;
      ev=real(eig(F));row.wall_index=sum(ev<0);row.negative_index=row.interior_index+row.wall_index;
      row.F_min_abs=min(abs(ev));row.F_norm2=max(abs(ev));
      if any(abs(k-[1.32,2.1875,2.37,2.38])<1e-12)
        T=A;T(W,W)=T(W,W)+blkdiag(D{1},D{2});T=(T+T')/2;
        row.full_ldl_index=LOCAL_inertia(T);assert(row.full_ldl_index==row.negative_index);
        rng(513);opt=struct('tol',1e-10,'maxit',500,'disp',0,'v0',ones(size(T,1),1));
        [v,dd,flag]=eigs(T,1,0,opt);assert(flag==0);e=real(dd(1));row.T_nearest_eigenvalue=e;
        row.T_min_abs=abs(e);row.T_norm1=norm(T,1);row.T_relative_margin=abs(e)/row.T_norm1;
        row.T_eigs_residual=norm(T*v-e*v)/(row.T_norm1*norm(v));clear T v
      end
    end
    row.seconds=toc(tt);if j==1,rows=row;else,rows(j)=row;end;writetable(struct2table(rows,'AsArray',true),fullfile(output_dir,'scan.csv'));
    fprintf('SCAN P%d %d/%d k %.10f index %g Zmin %.4g %.4g normD %.4g %.4g valid %d (%.2fs)\n', ...
      p,j,numel(ks),k,row.negative_index,row.left_Z0_smin,row.right_Z0_smin,row.left_D_norm2,row.right_D_norm2,row.valid,row.seconds);
  end
  % A positive index jump away from a pole supplies the local DtN root bracket.
  for j=2:numel(ks)
    if rows(j).valid&&rows(j-1).valid&&rows(j).negative_index>rows(j-1).negative_index
      mid=(ks(j)+ks(j-1))/2;ctx.config.k0=mid;ctx.config.mu0=mid^2;
      ctx.config.window=[ks(j-1),ks(j)];ctx.config.root.half_widths=unique([ctx.config.root.half_widths,diff(ctx.config.window)/2]);
      item=LOCAL_chain_stub(sprintf('P%d-scan-%d',p,j),p,'primary',1e-10);
      item=LOCAL_chain(ctx,ops,item,mid,struct('type','smallest'));item=rmfield(item,{'g','y'});
      if isempty(root_records),root_records=item;else,root_records(end+1)=item;end
      LOCAL_json(fullfile(output_dir,'roots.json'),root_records);
    end
  end
  report=struct('p',p,'group',group,'matrix_checks',ops.checks,'rows',rows,'roots',root_records,'seconds',toc(started));
  LOCAL_json(fullfile(output_dir,'summary.json'),report);
end
function n=LOCAL_inertia(A)
  % Hermitian pivoted LDL: count both eigenvalues of each 2 by 2 pivot.
  A=(A+A')/2;perm=symamd(A);[~,flag]=chol(A(perm,perm));
  if flag==0,n=0;return,end
  % R2023b sparse LDL accepts real symmetric input. Realification repeats
  % every Hermitian eigenvalue twice and therefore doubles its inertia.
  B=[real(A),-imag(A);imag(A),real(A)];
  [~,D,~]=ldl(B,'vector');d=real(diag(D));off=diag(D,-1);n=0;j=1;
  while j<=numel(d)
    if j<numel(d)&&off(j)~=0
      ee=eig(full(D(j:j+1,j:j+1)));n=n+sum(real(ee)<0);j=j+2;
    else
      n=n+(d(j)<0);j=j+1;
    end
  end
  assert(mod(n,2)==0,'gap:Inertia','Realified inertia must be even.');n=n/2;
end
