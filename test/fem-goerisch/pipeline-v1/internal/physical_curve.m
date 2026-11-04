function [c,d]=physical_curve(curve,theta,native_order)
  % PHYSICAL_CURVE Evaluate the supported analytic inclusion in local coordinates.
  % Input
  %   Curve definition and angle column.
  % Output
  %   Position and angle derivative; arithmetic copied from the native geometry.
  if nargin<3,native_order=false;end
  theta=theta(:);
  if strcmp(curve.kind,'star')
    h=curve.lobes;a=curve.amplitude;b=curve.axes;r=curve.scale*curve.radius;
    ch=cos(h*theta);sh=sin(h*theta);
    c=r*[(b(1)+a*ch).*cos(theta),(b(2)+a*ch).*sin(theta)];
    d=r*[-(a*h)*sh.*cos(theta)-(b(1)+a*ch).*sin(theta), ...
      -(a*h)*sh.*sin(theta)+(b(2)+a*ch).*cos(theta)];
  else
    a=curve.a;h=curve.lobes;R=curve.radius/sqrt(1+a^2/2);
    r=R*(1+a*cos(h*theta));dr=-h*a*R*sin(h*theta);
    if native_order,rpos=curve.radius*(1+a*cos(h*theta))/sqrt(1+a^2/2);else,rpos=r;end
    c=[rpos.*cos(theta),rpos.*sin(theta)];
    d=[dr.*cos(theta)-r.*sin(theta),dr.*sin(theta)+r.*cos(theta)];
  end
end
