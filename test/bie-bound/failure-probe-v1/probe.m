function probe(out,planfile)
  % Run explicit solver stress tests and save scalars after every case.
  % Input: fresh output directory and JSON plan. Output: compact per-job records.
  tasks=jsondecode(fileread(planfile));maxNumCompThreads(11);
  if ~iscell(tasks),tasks=num2cell(tasks);end
  for j=1:numel(tasks)
    q=tasks{j};c=probe_config(q);folder=fullfile(out,q.label);mkdir(folder);tm=tic;
    if strcmp(q.action,'search')
      s=search_config(11,'production');s.config=c;s.window=q.window;
      if isfield(q,'observe_seconds'),s.observe_seconds=q.observe_seconds;end
      s.rayleigh_M=q.M;s.center_nodes=q.N;s.lead_nodes=q.N/2;
      try
        z=detsearch(folder,s);r=struct('status',z.status,'candidates',{z.candidates},'counts',z.counts);
      catch err
        r=struct('status','REFUSED','identifier',err.identifier,'message',err.message,'stack',err.stack);
        if strcmp(err.identifier,'probe:ObservationLimit'),r.status='OBSERVATION_LIMIT';end
        partial=fullfile(folder,'accepted-so-far.json');
        if isfile(partial),r.provisional=jsondecode(fileread(partial));end
      end
    else
      switch q.action
        case 'fallback-check'
          % Replay the production fallback's complete-candidate and fresh ratio gates.
          i9_adapter('reset','',c);
          st=i9_adapter('fallback',folder,c,struct('bounds',q.window,'domain',q.window));
          yes={};
          for jj=1:numel(st.candidates)
            cc=st.candidates{jj};fresh=st.points{cc.confirmation_id};
            if strcmp(cc.status,'COMPLETE') && fresh.aphys_ratio<=1e-11
              yes{end+1}=struct('k',cc.k,'ratio',fresh.aphys_ratio,'sigma',fresh.aphys_sigma);
            end
          end
          r=struct('status',st.status,'candidates',{yes},'intervals',{st.candidates},'counts',st.counters);
        case 'findcut',r=find_cut(q,c);
        case 'woodtrace',r=wood_trace(q,c,folder);
        case 'edge',r=edges(q,c,folder);
        case 'edge-mode',r=edge_mode(q,c,folder);
        otherwise,r=diagnose(q,c,folder);
      end
    end
    r.seconds=toc(tm);fid=fopen(fullfile(folder,'summary.json'),'w');
    fwrite(fid,jsonencode(r));fclose(fid);fprintf('DONE %s %.2fs\n',q.label,r.seconds);
    if strcmp(q.label,'regression')
      assert(strcmp(r.status,'COMPLETE') && numel(r.candidates)==1 && abs(r.candidates{1}.k-1.558437894182088)<=2e-14);
    end
  end
end
