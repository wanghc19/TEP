function fallback_batch(out,plan)
  % Evaluate the split searches in an explicit list and keep each completed row.
  % Input: run directory and a plan with jobs.
  % Output: one JSON result per search, including incomplete coverage and proposals.
  measured={};
  for j=1:numel(plan.jobs)
    q=plan.jobs(j);
    q.cache_proxy=startsWith(q.tag,'scan');c=probe_config(q);
    [~,before]=shared_proxy('counts',[],[]);r=split_search(q,c);
    [~,after]=shared_proxy('counts',[],[]);r.proxy_cache_hits_and_builds=after-before;
    r.model=q.model;r.tag=q.tag;r.control=q.control;r.detuning=q.detuning;
    r.fields={};field_timer=tic;
    for k=r.proposals
      assert(abs(k-q.beta)>=q.delta);v=border_field(k,c,q);
      r.fields{end+1}=v;
    end
    r.field_seconds=toc(field_timer);
    f=fopen(fullfile(out,sprintf('search-%03d.json',j)),'w');assert(f>=0);
    fprintf(f,'%s\n',jsonencode(r));fclose(f);
    fprintf('%s %d %s %g %s %d calls %.2f s\n',q.tag,q.N,q.route,q.delta,r.status,r.cell_calls,r.seconds);
    measured{j}=r;
  end
  refs={};
  for j=1:numel(measured)
    a=measured{j};q=plan.jobs(j);
    if q.N~=192 || ~startsWith(q.tag,'scan'),continue;end
    b=measured{j-1};assert(b.beta==a.beta && b.N==128);
    for v=a.fields
      z=v{1};
      for u=b.fields
        y=u{1};g=jump_pair(y.field,z.field);
        if abs(y.k-z.k)<1e-8 && g.pass
          q.seed=z.k;
          % An independent derivative stencil must also clear this search's exclusion.
          if abs(q.seed-q.beta)>q.delta+2e-6,refs{end+1}=q;end
        end
      end
    end
  end
  if ~isempty(refs),accuracy_probe(out,struct('jobs',[refs{:}]));end
end
