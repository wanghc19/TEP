function fallback_probe(out,planfile)
  % Run a monitored search from an explicit plan.
  % Input: output directory and JSON plan.
  % Output: per-search records and regression result.
  maxNumCompThreads(5);
  q=jsondecode(fileread(planfile));
  if strcmp(q.action,'proxycheck')
    proxy_check(out);
  elseif strcmp(q.action,'strips')
    strip_batch(out,q);
  elseif strcmp(q.action,'nested')
    nested_batch(out,q);
  elseif strcmp(q.action,'accuracy')
    accuracy_probe(out,q);
  elseif strcmp(q.action,'regression')
    r=border_search(q,probe_config(q));
    f=fopen(fullfile(out,'regression.json'),'w');
    fprintf(f,'%s\n',jsonencode(r));fclose(f);
    assert(numel(r.proposals)==1 && abs(r.proposals-1.558437894182088)<=2e-14);
  else
    fallback_batch(out,q);
  end
end
