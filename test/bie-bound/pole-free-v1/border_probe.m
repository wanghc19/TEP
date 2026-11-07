function border_probe(out,planfile)
  % Run the bordered search and the independent checks on explicit examples.
  % Input: fresh output directory and JSON experiment plan. Output: scalar JSON records.
  maxNumCompThreads(5);q=jsondecode(fileread(planfile));timer=tic;
  if strcmp(q.action,'identity')
    c=probe_config(q);rows=border_identity(q,c);LOCAL_write('identity',rows);
    assert(max(cellfun(@(r)r.relative_error,rows))<1e-10,'border:Identity','Complex determinant identity failed.');
    return
  end
  grids=[128,6;192,12];levels=cell(1,2);
  if strcmp(q.action,'control')
    for i=1:2
      q.N=grids(i,1);q.M=grids(i,2);c=probe_config(q);k=q.frequencies(i);
      v=border_field(k,c,q);c.fields=true;ld=search_i9_physics('leads',k,'fine',c);
      [~,e]=search_i9_physics('match',k,'fine',c,ld);
      if isfield(e.center,'raw'),e.center.density=[e.center.raw.H_L,e.center.raw.H_R]*e.q;end
      v.old_field=physical_checks(e,c,q);
      % Change both raw bases without changing the physical spaces or the anchor.
      c.fields=false;b=border_data(k,c,false);ref=border_data(k+.001,c,false);
      anchor=struct('L',ref.ZL,'R',ref.ZR);H=border_matrix(b,anchor);
      U=fliplr(eye(b.K)).*exp(1i*(1:b.K));b.ZL=b.ZL*U;b.ZR=b.ZR*U';
      v.frame_change_relative=norm(border_matrix(b,anchor)-H,'fro')/norm(H,'fro');
      levels{i}=v;
    end
    LOCAL_write('control',levels);
    gates=struct('bordered',jump_pair(levels{1}.field,levels{2}.field), ...
      'old',jump_pair(levels{1}.old_field,levels{2}.old_field));
    LOCAL_write('control-rules',gates);return
  end
  for i=1:2
    q.N=grids(i,1);q.M=grids(i,2);c=probe_config(q);
    a=border_search(q,c);LOCAL_write(sprintf('search-%d',q.N),a);
    scan=border_scan(q,c);LOCAL_write(sprintf('scan-%d',q.N),scan);
    evidence={};
    for k=a.proposals,evidence{end+1}=border_field(k,c,q);end
    extra={};
    for k=scan.roots
      if ~any(abs(a.proposals-k)<1e-8),extra{end+1}=border_field(k,c,q);end
    end
    levels{i}=struct('N',q.N,'M',q.M,'search',a.proposals,'scan',scan.roots,'fields',{evidence},'scan_extra',{extra});
    LOCAL_write(sprintf('fields-%d',q.N),levels{i});
  end
  roots=[];coarse_roots=[];checks={};co=levels{1};fi=levels{2};
  agree=true;
  for i=1:2
    v=levels{i};agree=agree && numel(v.search)==numel(v.scan) && all(abs(sort(v.search(:))-sort(v.scan(:)))<1e-8);
  end
  for j=1:numel(co.fields)
    a=co.fields{j};idx=find(abs(fi.search-a.k)<1e-8);
    if numel(idx)~=1,checks{end+1}=struct('k',a.k,'pass',false,'reason','unpaired');continue;end
    b=fi.fields{idx};gate=jump_pair(a.field,b.field);
    gate.k=a.k;gate.fine_k=b.k;checks{end+1}=gate;
    if gate.pass,coarse_roots(end+1)=a.k;roots(end+1)=b.k;end
  end
  for j=1:numel(fi.fields)
    if ~any(abs(co.search-fi.fields{j}.k)<1e-8)
      checks{end+1}=struct('fine_k',fi.fields{j}.k,'pass',false,'reason','fine-only proposal');
    end
  end
  accepted_agree=LOCAL_same(coarse_roots,co.scan) && LOCAL_same(roots,fi.scan);
  r=struct('label',q.label,'accepted',roots,'coarse_accepted',coarse_roots,'checks',{checks}, ...
    'proposals_agree',agree,'agrees_with_scan',accepted_agree,'coverage',numel(coarse_roots)==numel(roots), ...
    'seconds',toc(timer));
  LOCAL_write('result',r);
  if strcmp(q.label,'reference')
    assert(numel(co.search)==1 && abs(co.search-1.558437894182088)<=2e-14,'border:Regression','Reference root differs.');
  end
  assert(r.coverage && accepted_agree,'border:Checks','The physical accepted list differs from the independent scan.');
  function LOCAL_write(name,x)
    f=fopen(fullfile(out,[name,'.json']),'w');assert(f>=0);
    cleanup=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(x));
    fprintf('saved %s %.2fs\n',name,toc(timer));
  end
end

function yes=LOCAL_same(a,b)
  % Compare two frequency lists including multiplicity.
  yes=numel(a)==numel(b) && all(abs(sort(a(:))-sort(b(:)))<1e-8);
end
