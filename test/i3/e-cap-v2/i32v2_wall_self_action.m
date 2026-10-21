function [value,flux,kernel_flux,recombination,audit] = ...
    i32v2_wall_self_action(z,g,ys,yt,xi,xt,normal,level,variant, ...
    source_panel)
%I32V2_WALL_SELF_ACTION Apply the frozen straight quotient-wall self action.
% Purpose:
%   Provide the single production and oracle implementation of the gauged
%   wall single-layer value and cell-interior outward-normal action.
% Input:
%   z       - Frozen certificate scalars d, beta, and khat.
%   g       - Compact MFS-only GQP table return.
%   ys, yt  - Source and target physical y nodes over one quotient period.
%   xi      - Samples of one frozen wall Nystrom density.
%   xt      - Physical x coordinate of the wall.
%   normal  - Cell-interior outward x-normal, either -1 or +1.
%   level   - GQP interpolation level with include_primary=false.
%   variant - Registered MFS proxy variant identifier.
%   source_panel - Optional maximum streamed source columns; defaults to 256.
% Output:
%   value         - Rectangular Kress value action at yt.
%   flux          - Smooth MFS normal action plus the +1/2 interior jump.
%   kernel_flux   - Smooth MFS normal action without the jump.
%   recombination - Relative defect of Mtilde=A_W*Lambda+B_W off diagonal.
%   audit         - Compact split, gauge, jump, and path ledger.
% Main algorithm:
%   Use design-3-2d Section 5.2 exactly: a=d/(2*pi), the periodic wrapped
%   coordinate w, the smooth cutoff chi, q=chi(|w|)w, and
%     A_W=-(a/(4*pi))*exp(-1i*beta*a*q)*J0(k*a*abs(q)).
%   The proxy remainder is obtained only through i32v2_gqp_pair.
% Notes:
%   This function contains no image sum, Rayleigh action, modal Green
%   multiplier, density solve, or source-grid change.

  if nargin<10||isempty(source_panel), source_panel=256; end
  LOCAL_validate(z,g,ys,yt,xi,xt,normal,level,variant,source_panel);
  ns=numel(ys); nt=numel(yt); a=double(z.d)/(2*pi);
  ts=2*pi*(ys+double(z.d)/2)/double(z.d);
  tt=2*pi*(yt+double(z.d)/2)/double(z.d);
  euler_constant=0.5772156649015328606;
  free_limit=0.5*(1i/2-euler_constant/pi ...
    -1/(2*pi)*log(z.khat^2*a^2/4))*a;
  value_gauge=complex(zeros(nt,size(xi,2)));
  kernel_flux=complex(zeros(nt,size(xi,2)));
  recombination_numerator=0; recombination_scale_squared=0;
  trg=[xt*ones(1,nt);yt.']; ds=double(z.d)/ns;
  for first=1:source_panel:ns
    last=min(ns,first+source_panel-1); ids=first:last;
    src=[xt*ones(1,numel(ids));ys(ids).'];
    [regular,gx]=i32v2_gqp_pair(g,src,trg,level,variant);
    dy=yt(:)-ys(ids).'; shift=round(dy/double(z.d));
    folded=dy-shift*double(z.d); phase=exp(1i*z.beta*double(z.d)*shift);
    rho=abs(folded); coincident=rho<=64*eps(double(z.d));
    primary=complex(zeros(nt,numel(ids)));
    primary(~coincident)=1i/4*besselh(0,1,z.khat*rho(~coincident));
    complete=regular+phase.*primary;
    gauged=bsxfun(@times,exp(-1i*z.beta*yt(:)),complete);
    gauged=bsxfun(@times,gauged,exp(1i*z.beta*ys(ids).'))*a;

    [TS,TT]=meshgrid(ts(ids),tt); delta=TT-TS;
    wrapped=delta-2*pi*floor((delta+pi)/(2*pi));
    radius=abs(wrapped); cutoff=zeros(size(radius));
    cutoff(radius<=pi/4)=1;
    transition=radius>pi/4&radius<pi/2;
    left=exp(-1./(pi/2-radius(transition)));
    right=exp(-1./(radius(transition)-pi/4));
    cutoff(transition)=left./(left+right);
    q=cutoff.*wrapped;
    A=-a/(4*pi)*exp(-1i*z.beta*a*q).*besselj(0,z.khat*a*abs(q));
    logarithm=log(4*sin(delta/2).^2); logarithm(coincident)=0;
    B=gauged-A.*logarithm;
    B(coincident)=free_limit+a*regular(coincident);
    A(coincident)=-a/(4*pi);

    active=~coincident;
    defect=gauged(active)-(A(active).*logarithm(active)+B(active));
    recombination_numerator=recombination_numerator+sum(abs(defect).^2);
    recombination_scale_squared=recombination_scale_squared+ ...
      sum(abs(gauged(active)).^2);
    Rw=i32v2_rect_kress_weights(ts(ids),tt,ns,ids);
    density_gauge=bsxfun(@times,exp(-1i*z.beta*ys(ids)),xi(ids,:));
    value_gauge=value_gauge+(Rw.*A+(2*pi/ns)*B)*density_gauge;
    kernel_flux=kernel_flux+ds*normal*gx*xi(ids,:);
  end
  recombination=sqrt(recombination_numerator) ...
    /max(sqrt(recombination_scale_squared),realmin);
  value=bsxfun(@times,exp(1i*z.beta*yt(:)),value_gauge);
  xi_target=LOCAL_density_target(xi,ys,yt,z.beta,double(z.d));
  flux=kernel_flux+0.5*xi_target;

  audit=struct();
  audit.symbol_ledger=struct( ...
    'a','wall quotient scale d/(2*pi)', ...
    'wrapped','w(delta) in design-3-2d Section 5.2', ...
    'cutoff','chi(abs(w)) in design-3-2d Section 5.2', ...
    'q','smooth periodic coordinate chi(abs(w))*w', ...
    'A','registered logarithmic coefficient A_W', ...
    'B','registered smooth remainder B_W', ...
    'kernel_flux','smooth MFS target-normal action without jump');
  audit.periodic_gauge=true;
  audit.explicit_interior_jump=0.5;
  audit.recombination=recombination;
  audit.recombination_scale=max(sqrt(recombination_scale_squared),realmin);
  audit.source_count=ns; audit.target_count=nt;
  audit.source_panel_max=source_panel;
  audit.image_sum_calls=0; audit.rayleigh_trial_eval_calls=0;
end

function xi_target=LOCAL_density_target(samples,ys,yt,beta,d)
  n=numel(ys); orders=(-n/2:n/2-1).';
  gauge=bsxfun(@times,exp(-1i*beta*ys),samples);
  coefficients=fftshift(fft(gauge,[],1),1)/n;
  origin=-0.5+0.5/n;
  coefficients=bsxfun(@times,exp(-1i*2*pi*orders*origin),coefficients);
  gauge_target=complex(zeros(numel(yt),size(samples,2)));
  panel=256;
  for first=1:panel:n
    last=min(n,first+panel-1); ids=first:last;
    gauge_target=gauge_target+ ...
      exp(1i*2*pi*yt(:)/d*orders(ids).')*coefficients(ids,:);
  end
  xi_target=bsxfun(@times,exp(1i*beta*yt(:)),gauge_target);
end

function LOCAL_validate(z,g,ys,yt,xi,xt,normal,level,variant,source_panel)
  if ~isstruct(z)||~all(isfield(z,{'d','beta','khat'}))|| ...
      ~isstruct(g)||~isfield(g,'available')||~g.available|| ...
      size(xi,1)~=numel(ys)||mod(numel(ys),2)~=0|| ...
      isempty(yt)||~isscalar(xt)||~ismember(normal,[-1,1])|| ...
      ~isstruct(level)||~all(isfield(level,{'n','include_primary'}))|| ...
      logical(level.include_primary)||~isscalar(variant)||variant<0||variant>5|| ...
      ~isscalar(source_panel)||source_panel<1||source_panel~=round(source_panel)
    error('I32V2:WallSelfInterface', ...
      'The registered wall-self action interface is invalid.');
  end
  if any(~isfinite([ys(:);yt(:);xi(:);xt;normal]))
    error('I32V2:WallSelfNonfinite','Wall-self inputs must be finite.');
  end
end
