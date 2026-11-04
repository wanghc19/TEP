function r=field_export(out)
% Export the independent nodal field and its monomial evaluation cache.
% Input: fresh output directory. Output: three compressed template MAT files.
  mkdir(out);maxNumCompThreads(11);started=tic;
  cfg=direct_pipeline('config','in-memory','D');cfg.fem_degree=3;cfg.baseline_check=false;cfg.level='native-P3';
  search=fem_i9_run(fullfile(out,'search'),[1.4509999999999998,2.2490000000000001]);k=search.modes(search.candidate_ids).k;
  [native,generation]=direct_native('generate',k,fullfile(out,'generation'),3);P=direct_pipeline('prepare',cfg,native);clear native
  for t=1:3
    G=P.templates{t}.G;T=P.templates{t}.T;U=P.templates{t}.U;
    coefficients=G.field_coefficients;dofs=T.field_dofs;alpha=G.field_alpha;mx=G.mx;my=G.my;rho=T.material;cells=G.cells;
    save(fullfile(out,[T.name,'-field.mat']),'coefficients','U','dofs','alpha','mx','my','rho','cells','-v7');
  end
  r=struct('E',P.energy,'M',P.mass,'q',P.q,'root',generation.frequency,'seconds',toc(started));
  f=fopen(fullfile(out,'field-export.json'),'w');fprintf(f,'%s\n',jsonencode(r));fclose(f);
end
