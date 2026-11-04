function config=direct_native_config(group,e)
  % DIRECT_NATIVE_CONFIG Direct finite element / Dirichlet-to-Neumann options.
  % Input
  %   Mesh group and validated example.
  % Output
  %   Native-field configuration with the caller's material parameters.
  config=e.discretization.native;assert(strcmp(group,config.group));
  config.model=e.model;config.resources.threads=e.resources.threads;
end
