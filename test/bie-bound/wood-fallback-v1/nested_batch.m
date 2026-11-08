function nested_batch(out,plan)
  % Extend the same covered intervals as the Wood exclusion shrinks.
  % Input: model/phase jobs and a common logical search cap in seconds.
  % Output: per-strip measurements plus the exact same-route cumulative ledger.
  serial=0;
  for j=1:numel(plan.jobs)
    q=plan.jobs(j);c=probe_config(q);W=q.window(:).';w=q.beta;
    for route={'plain','sqrt'}
      seconds=0;evals=0;panels=0;covered=true;fields={};ks=[];paths={};
      if strcmp(route{1},'plain'),ds=[.01,.001,.0001];else,ds=[.001,.0001,.00001];end
      if strcmp(route{1},'sqrt')
        seconds=outer.seconds;evals=outer.evaluations;panels=outer.panels;
        covered=outer.complete;fields=outer.fields;ks=outer.frequencies(:).';paths={outer.file};previous=.01;
      else,previous=NaN;end
      for delta=ds
        serial=serial+1;name=sprintf('nested-%03d.json',serial);
        q.delta=delta;q.route=route{1};q.window=W;
        if isfinite(previous)
          [~,~,cut]=wood_panels(W,w,c.model.d,c.model.rho_exterior,previous);
          assert(size(cut,1)==1);q.window=cut;
        end
        q.cap=max(0,plan.cap-seconds);
        if q.cap>0 && covered
          r=split_search(q,c);
        else
          r=struct('status','outer_incomplete','message','Outer search incomplete or 150 s cumulative allowance exhausted.', ...
            'complete',false,'N',q.N,'M',q.M,'beta',q.beta,'route',q.route,'delta',delta, ...
            'window',q.window,'excluded',[],'retained',[],'finished_intervals',[], ...
            'proposals',[],'seconds',0,'panels',0,'evaluations',0,'cell_calls',0, ...
            'closest_distance',[],'closest_k',[],'frequencies',[],'panel_log',{{}});
        end
        timer=tic;r.fields={};
        for k=r.proposals
          assert(abs(k-w)>=delta);
          r.fields{end+1}=border_field(k,c,q);
        end
        r.field_seconds=toc(timer);r.model=q.model;r.tag=q.tag;r.control=false;r.detuning=q.detuning;
        r.file=name;r.reused_files=paths;r.budget_remaining_at_start=q.cap;r.original_window=W;
        seconds=seconds+r.seconds;panels=panels+r.panels;evals=evals+r.evaluations;
        covered=covered && r.complete;fields=[fields,r.fields];ks=[ks,r.frequencies(:).'];
        r.total_seconds=seconds;r.total_panels=panels;r.total_evaluations=evals;r.total_complete=covered;
        r.total_fields=fields;[r.total_closest_distance,idx]=min(abs(ks-w));r.total_closest_k=ks(idx);
        f=fopen(fullfile(out,name),'w');assert(f>=0);fprintf(f,'%s\n',jsonencode(r));fclose(f);
        if delta==.01,outer=r;end
        fprintf('%s %d %s %.0e %s %.2f s new %.2f s total\n',q.tag,q.N,q.route,delta,r.status,r.seconds,seconds);
        previous=delta;paths{end+1}=name;
      end
    end
  end
end
