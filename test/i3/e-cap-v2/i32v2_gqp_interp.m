function [values,audit] = i32v2_gqp_interp(table,xgrid,ygrid,xquery,yquery)
%I32V2_GQP_INTERP Interpolate MFS remainder tables on the folded strip.
% Purpose:
%   Apply the design-3-2d one-sided 4-by-4 tensor cubic interpolant to the
%   six computational MFS remainder fields.
% Input:
%   table   - ny-by-nx-by-6 complex table, indexed as (Y,X,field).
%   xgrid   - Periodic computational difference nodes X0.
%   ygrid   - Nonperiodic computational difference nodes Y.
%   xquery  - Query X0 values of any common shape.
%   yquery  - Query Y values with the same shape as xquery.
% Output:
%   values  - numel(xquery)-by-6 interpolated computational fields.
%   audit   - Compact interpolation and operation-count record.
% Main algorithm:
%   Select four inward consecutive nodes independently in X0 and Y, form
%   cubic Lagrange weights, and contract the 4-by-4 tensor stencil.
% Notes:
%   No endpoint wrapping or endpoint averaging is performed.  The caller
%   owns the exact MATLAB round/fold rule and the Bloch phase.

  LOCAL_validate(table,xgrid,ygrid,xquery,yquery);
  shape=size(xquery); xquery=xquery(:); yquery=yquery(:);
  nq=numel(xquery); values=complex(zeros(nq,6));
  hx=xgrid(2)-xgrid(1); hy=ygrid(2)-ygrid(1);
  tol=128*eps(max([1,abs(xgrid(:).'),abs(ygrid(:).')]));
  if any(xquery<xgrid(1)-tol|xquery>xgrid(end)+tol| ...
      yquery<ygrid(1)-tol|yquery>ygrid(end)+tol)
    error('i32v2:GQPInterpolationDomain', ...
      'A folded MFS interpolation query lies outside the registered table.');
  end
  xquery=min(max(xquery,xgrid(1)),xgrid(end));
  yquery=min(max(yquery,ygrid(1)),ygrid(end));
  ix=LOCAL_start(xquery,xgrid(1),hx,numel(xgrid));
  iy=LOCAL_start(yquery,ygrid(1),hy,numel(ygrid));
  wx=LOCAL_weights(xquery,xgrid,ix);
  wy=LOCAL_weights(yquery,ygrid,iy);
  ny=size(table,1);
  for row=0:3
    for column=0:3
      linear=(iy+row)+(ix+column-1)*ny;
      weight=wy(:,row+1).*wx(:,column+1);
      for f=1:6
        layer=table(:,:,f);
        values(:,f)=values(:,f)+weight.*layer(linear);
      end
    end
  end
  audit=struct('query_shape',shape,'query_count',nq, ...
    'one_field_complex_operation_count',31*nq, ...
    'all_field_complex_operation_count',31*nq*6, ...
    'stencil',[4 4],'endpoint_wrap_count',0, ...
    'endpoint_average_count',0,'finite',all(isfinite(values),'all'));
end

function LOCAL_validate(table,xgrid,ygrid,xquery,yquery)
  if ndims(table)~=3||size(table,3)~=6||size(table,1)~=numel(ygrid)|| ...
      size(table,2)~=numel(xgrid)||~isequal(size(xquery),size(yquery))
    error('i32v2:GQPInterpolationShape','Invalid MFS table or query shape.');
  end
  if numel(xgrid)<4||numel(ygrid)<4||any(diff(xgrid)<=0)||any(diff(ygrid)<=0)
    error('i32v2:GQPInterpolationGrid','Interpolation grids must increase.');
  end
  if any(~isfinite([table(:);xgrid(:);ygrid(:);xquery(:);yquery(:)]))
    error('i32v2:GQPInterpolationFinite','Interpolation data are nonfinite.');
  end
end

function first=LOCAL_start(x,xmin,h,n)
  zero_based=min(max(floor((x-xmin)/h)-1,0),n-4);
  first=zero_based+1;
end

function w=LOCAL_weights(x,grid,first)
  count=numel(x); nodes=zeros(count,4);
  for j=1:4
    nodes(:,j)=grid(first+j-1);
  end
  w=ones(count,4);
  for j=1:4
    for k=1:4
      if k~=j
        w(:,j)=w(:,j).*(x-nodes(:,k))./(nodes(:,j)-nodes(:,k));
      end
    end
  end
end
