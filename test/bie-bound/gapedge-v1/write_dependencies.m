% Stage C source: test/bie-bound/example2-v1/write_dependencies.m; local changes documented in README.
function write_dependencies(out)
% WRITE_DEPENDENCIES Record code loaded during the current MATLAB stage.
% Input
%   out: explicit same-run output directory.
% Output
%   dependencies.json: MATLAB and MEX code paths; no scientific data input.
  [m,mex]=inmem('-completenames');
  f=fopen(fullfile(out,'dependencies.json'),'w');assert(f>=0);
  c=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(struct('matlab',{m},'mex',{mex})));
end
