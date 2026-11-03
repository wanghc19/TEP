function h_analyze(out,manifest)
% H means hypothesis: independently compare endpoint records and finite signs.
% Input: output directory and JSON manifest with four main/four trial paths.
% Output: analysis JSON with the six requested checks and B2/B3 summaries.
  maxNumCompThreads(11);if ~exist(out,'dir'),mkdir(out);end
  cfg=jsondecode(fileread(manifest));main=cell(4,1);trial=cell(4,1);
  space=zeros(4,4);quad=zeros(4,7);hermitian=zeros(4,5);indices=zeros(8,7);
  ii=0;
  for j=1:4
    main{j}=jsondecode(fileread(cfg.main{j}));trial{j}=jsondecode(fileread(cfg.trial{j}));
    a=main{j};b=trial{j};A=LOCAL_matrix(a,'C');B=LOCAL_matrix(b,'C');E=LOCAL_matrix(a,'E');F=LOCAL_matrix(b,'E');G=LOCAL_matrix(a,'G');
    difference=norm(A-B);budget=norm(E)+norm(F);space(j,:)=[a.material,a.lambda,difference,budget];
    qE=a.form_inverse*a.quad_difference_H;
    if isfield(a,'bound_method') && strcmp(a.bound_method,'poisson2')
      qE=a.quad_difference_H+17*a.lambda*(1+a.lambda/a.d_per)*a.quad_difference_V2;
    end
    quad(j,:)=[a.quad_difference_C,qE,a.quad_difference_G,a.quad_difference_U,a.curve_check_X,a.curve_check_IT,a.curve_check_TT];
    hermitian(j,:)=[a.hermitian_defect,a.gram_hermitian_defect,min(real(eig((G+G')/2))),norm(G),min(real(eig((E+E')/2)))];
    for z=1:2
      ii=ii+1;t=a.tests(z);indices(ii,:)=[a.material,a.lambda,t.M,t.negative_Cminus,t.negative_Cplus,t.gamma,t.E_norm];
    end
  end
  monotonic=zeros(4,4);jj=0;B2=zeros(2,4);B3=zeros(2,8);B3_components=zeros(2,5);B3_monotonic=zeros(2,4);
  for pair=1:2
    lo=main{2*pair-1};hi=main{2*pair};D=LOCAL_matrix(hi,'C')-LOCAL_matrix(lo,'C')+LOCAL_matrix(hi,'E')+LOCAL_matrix(lo,'E');
    for M=[8,10]
      ix=(11-M):(11+M);dd=(D(ix,ix)+D(ix,ix)')/2;jj=jj+1;monotonic(jj,:)=[lo.material,M,min(real(eig(dd))),norm(dd)];
    end
    B2(pair,:)=[lo.material,lo.tests(2).negative_Cminus,hi.tests(2).negative_Cminus,lo.tests(2).negative_Cminus==hi.tests(2).negative_Cminus];
    if lo.tests(2).negative_Cminus==0 && lo.tests(2).gamma>0
      dd=min(hi.lambda-lo.lambda,2.375^2-hi.lambda);kk=1+(hi.lambda+1)/dd;
      B3_monotonic(pair,:)=[hi.material,dd,kk,sqrt(4e-4/kk)];
    end
    t=hi.tests(2);B3_components(pair,:)=[hi.material,t.response_gram_max,t.response_error,t.a_low,t.a_high];B3(pair,:)=[hi.material,t.B_inverse,t.T_squared,.5*((hi.lambda+1)/hi.d_per^2+1/hi.d_per),t.d_half,t.K_half,t.K_coarse,sqrt(4e-4/t.K_half)];
  end
  tab=jsondecode(fileread(cfg.tail));expected=[1.968e-6,2.206e-9,2.744e-12,3.656e-15,8.990e-6,1.002e-8,1.241e-11,1.649e-14];tail_ok=true;
  for j=1:8,tail_ok=tail_ok && strcmp(sprintf('%.2e',tab.table(j).penalty),sprintf('%.2e',expected(j)));end
  inertias=all(indices(:,4)==indices(:,5))&&all(indices(:,6)>0);
  for j=1:4,inertias=inertias && main{j}.tests(1).negative_Cminus==main{j}.tests(2).negative_Cminus;end
  checks=struct('tail_table',tail_ok,'two_trial_spaces',all(space(:,3)<=space(:,4)), ...
    'monotonicity',all(monotonic(:,3)>=-1e-12.*monotonic(:,4)), ...
    'M8_M10',inertias,'quadrature',all(quad(:)<=1e-9), ...
    'Hermitian_PSD',all(hermitian(:,1:2)<1e-12,'all')&&all(hermitian(:,3)>=-1e-12.*hermitian(:,4))&&all(hermitian(:,5)>=0));
  tail_decay=true;for j=1:4,tail_decay=tail_decay&&main{j}.tests(2).tail.penalty<main{j}.tests(1).tail.penalty/100;end
  checks.M8_M10=checks.M8_M10&&tail_decay;
  rec=struct('checks',checks,'trial_comparison',space,'quadrature_comparison',quad,'Hermitian_and_PSD',hermitian, ...
    'B3_components',B3_components,'B3_monotonic',B3_monotonic,'indices',indices,'monotonicity',monotonic,'B2',B2,'B3',B3,'quad_tolerance',1e-9,'hermitian_tolerance',1e-12);
  f=fopen(fullfile(out,'analysis.json'),'w');fprintf(f,'%s\n',jsonencode(rec));fclose(f);disp(checks);disp(B3);
end
function A=LOCAL_matrix(s,k)
  A=s.([k,'_real'])+1i*s.([k,'_imag']);
end
