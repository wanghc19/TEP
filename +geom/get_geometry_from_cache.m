function [C, curvelen] = get_geometry_from_cache(ntot, geometry_cache)
% GET_GEOMETRY_FROM_CACHE Retrieve one TEP contour from a geometry cache.
%
% Purpose:
%   Looks up precomputed contour data for a requested ntot value.
%
% Input:
%   ntot           - Number of contour samples to retrieve.
%   geometry_cache - Struct array produced by geom.build_geometry_cache.
%
% Output:
%   C        - Cached 6-by-ntot contour array.
%   curvelen - Cached parameter interval length.
%
% Notes:
%   The function raises an error if the requested ntot is absent, matching
%   the behavior of the former local helper.

  idx = find([geometry_cache.ntot] == ntot, 1, 'first');
  if isempty(idx)
    error('Geometry for ntot = %d was not found in the cache.', ntot);
  end

  C = geometry_cache(idx).C;
  curvelen = geometry_cache(idx).curvelen;

end
