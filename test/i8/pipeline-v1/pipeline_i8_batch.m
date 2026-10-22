function pipeline_i8_batch(request_path)
%PIPELINE_I8_BATCH Execute one current-attempt batch without historical state.
% Purpose: Export the sole config, evaluate new points, or build a fresh estimate.
% Input: JSON request with action, output_dir, backend and explicit new k_values.
% Output: Per-point JSON records or scientific.mat and exact scalar CSV.
  request = jsondecode(fileread(request_path));
  config = pipeline_i8_config();
  maxNumCompThreads(config.backend.threads);
  if ~isfolder(request.output_dir), mkdir(request.output_dir); end
  environment = struct('matlab_version',version,'release',version('-release'), ...
    'computer',computer,'matlab_threads',maxNumCompThreads, ...
    'omp_num_threads',getenv('OMP_NUM_THREADS'),'omp_dynamic',getenv('OMP_DYNAMIC'), ...
    'entry_path',which('pipeline_i8_numeric'),'hfmm2d_path',which('hfmm2d'), ...
    'fmm2d_path',which('fmm2d'),'construct_S_path',which('bloch.construct_S'));
  LOCAL_json(fullfile(request.output_dir,'environment.json'),environment);
  if strcmp(request.action,'config')
    LOCAL_json(fullfile(request.output_dir,'config.json'),config);
    issues = checkcode(which('pipeline_i8_numeric'),'-id');
    LOCAL_json(fullfile(request.output_dir,'checkcode.json'),issues);
    return;
  end
  assert(strcmp(request.schema,'I84_PIPELINE_BATCH_V1'));
  requested_config = rmfield(request.config,'resources');
  science_config = rmfield(jsondecode(jsonencode(config)),'resources');
  assert(isequaln(requested_config,science_config));
  if strcmp(request.action,'points')
    if isfield(request,'linspace_bounds')
      request.k_values = linspace(request.linspace_bounds(1), ...
        request.linspace_bounds(2),config.search.refine_count);
    end
    actual_nodes = request.k_values(:).';
    assert(all(isfinite(actual_nodes)) && all(diff(actual_nodes)>0));
    assert(numel(unique(actual_nodes))==numel(actual_nodes));
    if isfield(request,'previous_selected_k')
      assert(actual_nodes(1)<request.previous_selected_k && ...
        request.previous_selected_k<actual_nodes(end));
    end
    if isfield(request,'grid_history')
      for h = 1:numel(request.grid_history)
        assert(~isequal(actual_nodes,request.grid_history(h).nodes(:).'));
      end
    end
    rows = cell(numel(request.k_values),1); batch_timer = tic;
    point_seconds = 0; export_seconds = 0;
    for j = 1:numel(request.k_values)
      [point,~] = pipeline_i8_numeric('point',request.k_values(j),request.backend);
      assert(all(isfinite([point.adef_sigma,point.adef_ratio, ...
        point.aphys_sigma,point.aphys_ratio])));
      rows{j} = point; point_seconds = point_seconds+point.seconds;
      export_timer = tic;
      LOCAL_json(fullfile(request.output_dir,sprintf('point-%03d.json',j)),point);
      LOCAL_json(fullfile(request.output_dir,'progress.json'), ...
        struct('done',j,'total',numel(rows),'elapsed',toc(batch_timer)));
      export_seconds = export_seconds+toc(export_timer);
      fprintf(1,'%s node=%d/%d k=%.17g ratio=%.17g seconds=%.6f\n', ...
        request.backend,j,numel(rows),point.k,point.aphys_ratio,point.seconds);
    end
    export_timer = tic;
    LOCAL_json(fullfile(request.output_dir,'points.json'),rows);
    export_seconds = export_seconds+toc(export_timer);
    LOCAL_json(fullfile(request.output_dir,'batch-timing.json'), ...
      struct('search_point',point_seconds,'save_export',export_seconds, ...
      'matlab_batch',toc(batch_timer)));
  elseif strcmp(request.action,'estimate')
    [result,evidence] = pipeline_i8_numeric('estimate',request.k_values,request.backend);
    stage_timer = tic;
    save(fullfile(request.output_dir,'scientific.mat'),'result','evidence','-v7');
    LOCAL_json(fullfile(request.output_dir,'result.json'),result);
    fid = fopen(fullfile(request.output_dir,'scalars.csv'),'w');
    fprintf(fid,'backend,k0,mu_num,Cnum,epsilon_num,U_num,Q,denominator,Rnum\n');
    fprintf(fid,'%s,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g\n', ...
      request.backend,result.k0,result.mu_num,result.Cnum,result.epsilon_num, ...
      result.U_num,result.Q,result.denominator,result.Rnum);
    fclose(fid);
    LOCAL_json(fullfile(request.output_dir,'save-timing.json'),struct('save_export',toc(stage_timer)));
    assert(strcmp(result.status,'UNCERTIFIED_RNUM'));
    fprintf(1,'%s estimate k=%.17g Rnum=%.17g\n',request.backend,result.k0,result.Rnum);
  else
    error('pipeline:Action','Unknown batch action.');
  end
end

function LOCAL_json(filename,value)
  fid = fopen(filename,'w'); assert(fid>=0);
  closer = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end
