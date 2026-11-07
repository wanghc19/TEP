function result=fem_search(out,g,p)
  % FEM_SEARCH Finite element method full-window seed and Dirichlet-to-Neumann refinement.
  % Input
  %   Output directory, mesh subdivisions g and local polynomial degree p.
  % Output
  %   All candidate frequencies, iteration evidence, dimensions and stage times.
  started=tic;example=example_ref();maxNumCompThreads(11);
  assert(ismember(g,[12 24 48]) && ismember(p,[3 4]));
  example.discretization.native.group=sprintf('g%d',g);
  example.discretization.native.mesh=struct('subdivisions',g,'interface_segments',g*20/3);
  w=example.windows.search_k;
  t=tic;seed=fem_i9_run(fullfile(out,'window'),w,example);seed_seconds=toc(t);
  candidates=cell(1,numel(seed.candidate_ids));
  for j=1:numel(candidates)
    k0=seed.modes(seed.candidate_ids(j)).k;
    folder=fullfile(out,sprintf('root-%02d',j));mkdir(folder);
    candidates{j}=root_cost(k0,folder,p,example);
  end
  result=struct('status','COMPLETE','window',w,'p2_seconds',seed_seconds, ...
    'p2_dof',seed.reduced_dof,'p2_solves',seed.solves,'candidate_ids',seed.candidate_ids, ...
    'candidates',{candidates},'science_seconds',toc(started),'threads',maxNumCompThreads, ...
    'version',version,'omp',getenv('OMP_NUM_THREADS'),'omp_dynamic',getenv('OMP_DYNAMIC'));
  f=fopen(fullfile(out,'result.json'),'w');fwrite(f,jsonencode(result,PrettyPrint=true));fclose(f);
end
