function result=goerisch_fit_check(input_dir,output_dir)
  % Check exact-interface fitted geometry for the Goerisch experiment.
  % Input
  %   input_dir: explicit read-only I9.6 (implementation 9.6) run directory.
  %   output_dir: fresh directory for the small geometry result.
  % Output
  %   result: both area orders, exact analytic areas, Jacobians and timing.
  started=tic;maxNumCompThreads(2);assert(~isfolder(output_dir));mkdir(output_dir);
  raw=load(fullfile(input_dir,'native.mat'),'native');names={'left','center','right'};
  result=struct();passed=true;
  for j=1:3
    T=raw.native.templates.(names{j});T.xy(:,1)=T.xy(:,1)-T.cell;
    F=goerisch_fitted_geometry(T);low=F.areas(16);high=F.areas(24);
    item=struct('curved_elements',F.curved_count,'low',low,'high',high);
    item.pass=max([low.relative_error,high.relative_error,abs(low.cell_area-1),abs(high.cell_area-1)])<1e-12;
    passed=passed&&item.pass;result.(names{j})=item;
    fprintf('%s area %.16g, relative error %.3e / %.3e\n',names{j},high.inclusion_area,low.relative_error,high.relative_error);
  end
  result.passed=passed;result.wall_seconds=toc(started);
  f=fopen(fullfile(output_dir,'result.json'),'w');assert(f>=0);cleaner=onCleanup(@()fclose(f)); %#ok<NASGU>
  fwrite(f,jsonencode(result,PrettyPrint=true),'char');
  assert(passed,'goerisch:Area','Fitted inclusion or cell area check failed.');
end
