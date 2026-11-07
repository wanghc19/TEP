function e=example_mesh(n)
  % EXAMPLE_MESH Reference FEM (finite element method) model at one mesh size.
  % Input
  %   n: subdivisions per unit cell, 24, 36, or 48.
  % Output
  %   Reference parameter structure with P3/RT3 and original tolerances.
  e=example_ref();assert(ismember(n,[24,36,48]));
  e.discretization.native.group=sprintf('g%d',n);
  e.discretization.native.mesh=struct('subdivisions',n,'interface_segments',round(n*320/48));
end
