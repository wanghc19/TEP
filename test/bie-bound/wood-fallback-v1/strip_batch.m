function strip_batch(out,p)
  % Reuse explicit outer-panel records as a Wood band shrinks.
  % Input: output directory, handoff root and a list of requested search rows.
  % Output: incremental and cumulative coverage, timing and physical proposals.
  length_errors=audit_windows();
  for j=1:numel(p.jobs)
    q=p.jobs(j);c=probe_config(q);full=q.window(:).';base=[];
    prior_time=0;prior_panels=0;prior_evals=0;prior_fields={};prior_d=Inf;prior_k=NaN;prior_ok=true;
    if ~isempty(q.parent_file)
      if startsWith(q.parent_file,'this/')
        parent=fullfile(out,extractAfter(q.parent_file,'this/'));
      else
        parent=fullfile(p.handoff_root,q.parent_file);
      end
      base=jsondecode(fileread(parent));
      assert(strcmp(base.model,q.model) && base.beta==q.beta && base.N==q.N && base.M==q.M);
      assert(base.delta>q.delta && (strcmp(base.route,q.route) || (base.delta==.01 && strcmp(base.route,'plain'))));
      if isfield(base,'original_window'),bwin=base.original_window;else,bwin=base.window;end
      assert(isequal(bwin(:),full(:)));
      [~,~,cut]=wood_panels(full,q.beta,c.model.d,c.model.rho_exterior,base.delta);
      assert(size(cut,1)==1);q.window=cut;
      if isfield(base,'total_fields')
        prior_time=base.total_seconds;prior_evals=base.total_evaluations;prior_panels=base.total_panels;
        prior_fields=LOCAL_cells(base.total_fields);prior_ok=base.total_complete;
        prior_k=base.total_closest_k;prior_d=base.total_closest_distance;
      else
        prior_time=base.seconds;prior_evals=base.evaluations;prior_panels=base.panels;
        prior_fields=LOCAL_cells(base.fields);prior_ok=base.complete;
        prior_k=base.closest_k;prior_d=base.closest_distance;
      end
    end
    q.cap=max(0,150-prior_time);
    if prior_ok && q.cap>0
      r=split_search(q,c);
    else
      r=struct('status','outer_incomplete','message','Incomplete outer coverage or cumulative cap.', ...
        'complete',false,'N',q.N,'M',q.M,'beta',q.beta,'route',q.route,'delta',q.delta, ...
        'window',q.window,'excluded',[],'retained',[],'finished_intervals',[], ...
        'proposals',[],'seconds',0,'panels',0,'evaluations',0,'cell_calls',0, ...
        'closest_distance',[],'closest_k',[],'frequencies',[],'panel_log',{{}});
    end
    timer=tic;r.fields={};
    for k=r.proposals
      assert(abs(k-q.beta)>=q.delta);r.fields{end+1}=border_field(k,c,q);
    end
    r.partition_length_errors=length_errors;r.field_seconds=toc(timer);r.original_window=full;r.excluded_status='unsearched';
    r.model=q.model;r.tag=q.tag;r.control=false;r.detuning=q.detuning;r.parent_file=q.parent_file;
    r.budget_remaining_at_start=q.cap;r.total_seconds=prior_time+r.seconds;
    r.total_complete=r.complete && prior_ok;r.total_panels=prior_panels+r.panels;
    r.total_evaluations=prior_evals+r.evaluations;r.total_fields=[prior_fields,r.fields];
    if isempty(r.closest_distance) || prior_d<r.closest_distance
      r.total_closest_distance=prior_d;r.total_closest_k=prior_k;
    else,r.total_closest_distance=r.closest_distance;r.total_closest_k=r.closest_k;end
    f=fopen(fullfile(out,sprintf('strip-%03d.json',j)),'w');assert(f>=0);
    fprintf(f,'%s\n',jsonencode(r));fclose(f);
    fprintf('%s %d %s %.0e %s %.2f s new %.2f s total\n',q.tag,q.N,q.route,q.delta,r.status,r.seconds,r.total_seconds);
  end
  if isfield(p,'secondary_parent')
    parent=jsondecode(fileread(fullfile(p.handoff_root,p.secondary_parent)));
    q=p.secondary_config;
    assert(parent.beta==q.beta && parent.N==q.N && strcmp(q.model,parent.model));
    other=parent.proposals(abs(parent.proposals-q.beta-q.detuning)>1e-6);
    assert(isscalar(other),'fallback:Reference','Expected one additional W3 proposal.');
    q.seed=other;q.detuning=other-q.beta;q.tag='w3-secondary';
    accuracy_probe(out,struct('jobs',q));
  end
end
function z=LOCAL_cells(a)
  % Normalize MATLAB JSON decoding of homogeneous arrays of field records.
  if isempty(a),z={};elseif iscell(a),z=a(:).';else,z=num2cell(a(:).');end
end
