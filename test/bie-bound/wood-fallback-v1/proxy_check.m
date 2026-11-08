function proxy_check(out)
  % Check exact reuse of Hankel distances and run the search regression.
  % Input: output directory. Output: proxy differences and the search regression.
  c=struct('H',1.1,'proxy_dist',.2,'N_side',160,'N_top',160,'N_proxy_edge',80,'M_pw',32);
  rows={};
  for k=[1.5584,1.98154+.0001,1.98154-.0001]
    pars=struct('k',k,'d',1,'beta',1.98154);
    tm=tic;p=kernel.precomp_proxy(pars,c);t1=toc(tm);
    tm=tic;b=fast_proxy(pars,c,'outgoing',0);t2=toc(tm);
    rows{end+1}=struct('k',k,'difference',norm(p.q-b.q,inf),'time',[t1,t2]);
  end
  q=struct('model','ex1','N',128,'M',6,'beta',.5,'window',[1.4509999999999998,2.249], ...
    'delta',.0001,'route','plain','cap',150,'control',false);
  profile on
  t=probe_config(q);border_data(1.56,t,false);
  t.resolutions.fine=struct('center_ntot',192,'negative_ntot',96,'positive_ntot',96);
  border_data(1.56,t,false);profile off
  prof=profile('info');[~,ord]=sort([prof.FunctionTable.TotalTime],'descend');
  profrows={};
  for j=ord(1:min(50,numel(ord)))
    x=prof.FunctionTable(j);profrows{end+1}=struct('name',x.FunctionName,'time',x.TotalTime);
  end
  r=split_search(q,probe_config(q));
  f=fopen(fullfile(out,'check.json'),'w');fprintf(f,'%s\n',jsonencode(struct('proxy',{rows},'profile',{profrows},'search',r)));fclose(f);
  assert(numel(r.proposals)==1 && abs(r.proposals-1.558437894182088)<=2e-14);
end
