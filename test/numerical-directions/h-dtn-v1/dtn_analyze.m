function dtn_analyze(out,input)
% DtN means Dirichlet-to-Neumann: compare the retained endpoint enclosures.
% Input: output directory and JSON of explicit numerical record paths.
% Output: six checks and matrix comparison tables in analysis JSON.
  maxNumCompThreads(11);if ~exist(out,'dir'),mkdir(out);end
  cfg=jsondecode(fileread(input));constants=jsondecode(fileread(cfg.constants));fe=jsondecode(fileread(cfg.fe));
  compare=zeros(2,12);sym=zeros(2,5);trace=zeros(2,2);budget=zeros(2,3);lift=zeros(2,5);
  for j=1:2
    a=jsondecode(fileread(cfg.coarse{j}));b=jsondecode(fileread(cfg.fine{j}));
    lowA=LOCAL_matrix(a,'lower');upA=LOCAL_matrix(a,'upper');lowB=LOCAL_matrix(b,'lower');upB=LOCAL_matrix(b,'upper');Q=LOCAL_matrix(b,'Q');
    D=fe(j).D_real+1i*fe(j).D_imag;q=sqrt(1+(.5+2*pi*(-16:16)).^2);S=diag(1./sqrt(q));idx=abs(-16:16)<=5;
    e1=LOCAL_min(S*(upB-lowA)*S);e2=LOCAL_min(S*(upA-lowB)*S);change=norm(S*(lowB-lowA)*S);
    sane=norm(S*(D-Q)*S);sanelow=norm(S(idx,idx)*(D(idx,idx)-Q(idx,idx))*S(idx,idx));
    Dfit=LOCAL_matrix(b,'fitted_nodal_D');fitdiff=norm(S*(Dfit-Q)*S);
    compare(j,:)=[a.r,b.r,a.gap,b.gap,e1,e2,change,change/a.gap,change/b.gap,sane,sanelow,fitdiff];
    trace(j,:)=[fe(j).trace_check.pointwise,fe(j).trace_check.retained_Fourier];
    sym(j,:)=[max([b.first.symmetry,b.bulk.symmetry],[],'all'),b.min_R,b.min_Z,norm(LOCAL_matrix(b,'R')),b.wall_match];
    budget(j,:)=[b.r,b.K_r,b.gap];
    t=b.alternative;lift(j,:)=[t.r,b.r,t.lower_difference,t.lower_difference/b.gap,min(t.overlap_min_1,t.overlap_min_2)];
  end
  references=[8,.9989466,3.96025e-4;10,.9992972,1.57112e-5;12,.9994979,6.38711e-7;14,.9996235,2.63645e-8;16,.9997073,1.09938e-9;20,.9998085,1.94910e-12];tail=true;tailmax=0;
  for row=1:size(references,1)
    z=constants.table([constants.table.M]==references(row,1));d=max(abs([z.a_H,z.b_H_squared]./references(row,2:3)-1));tailmax=max(tailmax,d);tail=tail&&d<5e-6;
  end
  checks=struct('tail_table',tail,'exact_trace',all(trace(:)<1e-12), ...
    'overlap',all(compare(:,5:6)>-1e-11,'all')&&all(lift(:,5)>-1e-11), ...
    'FE_sanity',all(compare(:,10)<.05)&&all(compare(:,11)<.005), ...
    'convergence',all(compare(:,2)<compare(:,1))&&all(lift(:,2)<lift(:,1))&&all(lift(:,3)<budget(:,3)), ...
    'Hermitian_PSD',all(sym(:,1)<1e-12)&&all(sym(:,2)>=-1e-12.*sym(:,4))&&all(sym(:,3)>0)&&all(sym(:,5)<1e-10));
  r=struct('checks',checks,'tail_max_relative',tailmax,'matrix_comparison',compare,'symmetry_PSD',sym, ...
    'trace',trace,'budget',budget,'lift_refinement',lift,'overlap_rounding_tolerance',1e-11,'FE_full_tolerance',.05,'FE_low_tolerance',.005);
  f=fopen(fullfile(out,'analysis.json'),'w');fprintf(f,'%s\n',jsonencode(r));fclose(f);disp(checks);disp(compare);disp(lift);
end
function A=LOCAL_matrix(s,k)
  A=s.([k,'_real'])+1i*s.([k,'_imag']);
end
function x=LOCAL_min(A)
  x=min(real(eig((A+A')/2)));
end
