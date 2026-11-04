function r=rounding_qj_run(out,do_cert)
% Rounding estimate: reproduce fields and collect positive sum and model scales.
% Input: fresh output directory. Output: small term MATs and diagnostics JSON.
  if nargin<2,do_cert=false;end;mkdir(out);maxNumCompThreads(11);global ROUNDING_OUT ROUNDING_ZETA ROUNDING_PM ROUNDING_POLY ROUNDING_RECIPROCAL ROUNDING_FLUX_ZETA
  ROUNDING_OUT=out;ROUNDING_ZETA=0;ROUNDING_PM=[];ROUNDING_POLY=[];ROUNDING_RECIPROCAL=[];ROUNDING_FLUX_ZETA=0;started=tic;
  cfg=direct_pipeline('config','in-memory','D');cfg.fem_degree=3;cfg.baseline_check=false;cfg.level='native-P3';cfg.alpha_minus=1.32^2;cfg.alpha_plus=2.37^2;cfg.mu=cfg.alpha_minus+1;cfg.nu=cfg.alpha_plus+1;
  search=fem_i9_run(fullfile(out,'search'),[1.4509999999999998,2.2490000000000001]);k=search.modes(search.candidate_ids).k;
  [native,generation]=direct_native('generate',k,fullfile(out,'generation'),3);P=direct_pipeline('prepare',cfg,native);clear native
  S=direct_pipeline('solve',P,cfg,3);[N,exact]=direct_pipeline('exact_flux',P,S,cfg);clear S
  inv=direct_pipeline('inventory',P,N,cfg);ROUNDING_OUT=[];
  fieldcond=zeros(3,5);field_probe=cell(1,3);
  for t=1:3
    G=P.templates{t}.G;T=P.templates{t}.T;c=abs(G.field_coefficients);ub=sum(c,2);dx=[];dy=[];for dd=0:3,for jj=0:dd,dx(end+1)=dd-jj;dy(end+1)=jj;end,end;ux=sum(c.*reshape(dx,1,10,1),2);uy=sum(c.*reshape(dy,1,10,1),2);
    a=G.mx(:,2)+2*G.mx(:,4)/3+G.mx(:,5)/3;b=G.mx(:,3)+G.mx(:,5)/3+2*G.mx(:,6)/3;cc=G.my(:,2)+2*G.my(:,4)/3+G.my(:,5)/3;d=G.my(:,3)+G.my(:,5)/3+2*G.my(:,6)/3;det=a.*d-b.*cc;
    ex=(abs(d).*ux+abs(cc).*uy)./det;ey=(abs(b).*ux+abs(a).*uy)./det;tap=reshape(abs(G.cells)>=12,1,1,[]);ex=ex+tap.*(pi/4).*ub;
    [~,imax]=max(reshape(sum(abs(G.field_coefficients),2),G.nt,[]),[],1);ii=unique([round(linspace(1,G.nt,31)),imax]);field_probe{t}=struct('alpha',G.field_alpha,'coefficients',G.field_coefficients(ii,:,:),'nodal_values',G.field_values(ii,:,:),'element_ids',ii);
    ZE=sum(det/2.*(ex.^2+ey.^2),'all');ZM=sum(det/2.*T.material.*ub.^2,'all');fieldcond(t,:)=[max(ub,[],'all'),sum(c,'all'),max(abs(G.mx),[],'all'),ZE,ZM];
  end
  save(fullfile(out,'field-probe.mat'),'field_probe','-v7');
  cert=struct();if do_cert,cert=direct_pipeline('certificates',P,N,cfg,out,inv);end
  probe=interface_certificate(P,N,cfg,struct(),inv,out,'probe');
  r=struct('q',P.q,'E',P.energy,'M',P.mass,'root',generation.frequency,'inventory',inv,'exact_flux',exact,'field_coeff_scales',fieldcond,'certificates',cert,'interface_probe',probe,'interface_large_terms_squared',ROUNDING_ZETA,'flux_absolute_terms_squared',ROUNDING_FLUX_ZETA,'reciprocal_tests',ROUNDING_RECIPROCAL,'pm_integrals',ROUNDING_PM,'triangle_integrals',ROUNDING_POLY,'seconds',toc(started));
  f=fopen(fullfile(out,'estimate-data.json'),'w');fprintf(f,'%s\n',jsonencode(r));fclose(f);
end
