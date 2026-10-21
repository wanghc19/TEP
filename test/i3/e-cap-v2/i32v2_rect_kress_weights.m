function R = i32v2_rect_kress_weights(source_nodes,target_nodes, ...
    source_count_total,source_indices)
%I32V2_RECT_KRESS_WEIGHTS Rectangular periodic logarithmic product weights.
% Purpose:
%   Evaluate the design-3-2d Kress weights for uniform even source nodes and
%   arbitrary periodic target nodes without requiring coincident grids.
% Input:
%   source_nodes - Equispaced nodes from the full periodic source grid.
%   target_nodes - Arbitrary target nodes, normally one streamed panel.
%   source_count_total - Optional full even source-grid size. Defaults to
%                        numel(source_nodes).
%   source_indices     - Optional one-based indices of source_nodes in that
%                        full grid. Defaults to the complete index set.
% Output:
%   R            - Nt-by-Ns product-weight matrix.
% Main algorithm:
%   Group target offsets by their fractional source-grid shift.  Construct
%   one Fourier-series row per group using an FFT, then apply exact circular
%   index shifts.  This is algebraically the registered cosine formula.

  s=source_nodes(:).'; t=target_nodes(:); nlocal=numel(s); nt=numel(t);
  if nargin<3||isempty(source_count_total)
    source_count_total=nlocal;
  end
  if nargin<4||isempty(source_indices)
    source_indices=1:nlocal;
  end
  ns=double(source_count_total); source_indices=double(source_indices(:).');
  if ns<4||mod(ns,2)~=0||nlocal<1||numel(source_indices)~=nlocal|| ...
      any(source_indices<1)||any(source_indices>ns)|| ...
      any(source_indices~=round(source_indices))|| ...
      any(~isfinite([s(:);t(:);source_indices(:)]))
    error('i32v2:KressGrid','Kress source count must be finite, even, and at least four.');
  end
  h=2*pi/ns; unwrapped=unwrap(s);
  if nlocal>1&&max(abs(diff(unwrapped)-diff(source_indices)*h)) ...
      >256*eps(max(1,max(abs(unwrapped))))
    error('i32v2:KressGrid','Kress source nodes are not a uniform 2*pi grid.');
  end
  source_origin=s(1)-(source_indices(1)-1)*h;
  q=(t-source_origin)/h; integer=floor(q); frac=q-integer;
  near_one=abs(frac-1)<=256*eps(max(1,max(abs(q))));
  integer(near_one)=integer(near_one)+1; frac(near_one)=0;
  near_zero=abs(frac)<=256*eps(max(1,max(abs(q)))); frac(near_zero)=0;
  group=zeros(nt,1); representatives=zeros(0,1);
  for i=1:nt
    hit=find(abs(representatives-frac(i))<=512*eps(max(1,abs(frac(i)))),1);
    if isempty(hit)
      representatives(end+1,1)=frac(i); %#ok<AGROW>
      hit=numel(representatives);
    end
    group(i)=hit;
  end
  bases=zeros(numel(representatives),ns);
  modes=1:ns/2-1;
  for g=1:numel(representatives)
    delta0=representatives(g)*h;
    spectrum=complex(zeros(1,ns));
    spectrum(modes+1)=exp(1i*modes*delta0)./(2*modes);
    spectrum(ns-modes+1)=exp(-1i*modes*delta0)./(2*modes);
    spectrum(ns/2+1)=cos((ns/2)*delta0)/ns;
    bases(g,:)=-4*pi/ns*real(fft(spectrum));
  end
  R=zeros(nt,nlocal); indices=source_indices-1;
  for i=1:nt
    R(i,:)=bases(group(i),mod(indices-integer(i),ns)+1);
  end
end
