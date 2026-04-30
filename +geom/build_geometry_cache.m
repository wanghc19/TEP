function geometry_cache = build_geometry_cache(ntot_list, flag_geom)
% BUILD_GEOMETRY_CACHE Precompute TEP geometry for unique discretization sizes.
%
% Purpose:
%   Builds a struct array containing one contour for each unique ntot value
%   requested by a TEP scan or convergence script.
%
% Input:
%   ntot_list - Vector of contour sample counts. Duplicate entries are
%               ignored after their first occurrence.
%   flag_geom - Geometry selector passed to geom.construct_cont.
%
% Output:
%   geometry_cache - Struct array with fields ntot, C, and curvelen.
%
% Notes:
%   The cache stores only contour data; no random interior or exterior
%   sample points are retained.

  ntot_unique = unique(ntot_list, 'stable');
  geometry_cache = struct('ntot', cell(length(ntot_unique), 1), ...
    'C', cell(length(ntot_unique), 1), ...
    'curvelen', cell(length(ntot_unique), 1));

  for j = 1:length(ntot_unique)
    [C, curvelen, ~, ~] = geom.construct_cont(ntot_unique(j), flag_geom, 0, 0);
    geometry_cache(j).ntot = ntot_unique(j);
    geometry_cache(j).C = C;
    geometry_cache(j).curvelen = curvelen;
  end

end
