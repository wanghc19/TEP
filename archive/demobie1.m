% This script solves a quasi-periodic Helmholtz boundary value problem using the double layer potential formulation.

format long;
% clear;
close all;

%%% Set some parameters.
ntot = 200;
flag_geom = 'star';
nsrc = 3;
ntrg = 20;
iprec = 10; % order of Kapur-Rokhlin quadrature
kh = 2;
d = 1.0;
beta = sqrt(2)/d;

pars1.k = kh;
pars1.beta = beta;
pars1.d = d;
pars3.H = 0.5 * pars1.d;              % Height of the fundamental domain[-H, H]
pars3.proxy_dist = 0.2 * pars1.d;     % Distance of proxy boundary from the domain
pars3.N_side = 120;                   % Number of collocation points on Left/Right walls
pars3.N_top = 120;                    % Number of collocation points on Top/Bottom walls
pars3.N_proxy_edge = 80;              % Number of proxy sources per edge (Total = 320)
pars3.M_pw = 25;                      % Truncation order for plane waves (-M_pw to M_pw)



%%% Set the geometry.
[C,curvelen,xxsrc,xxtrg] = LOCAL_construct_cont(ntot,flag_geom,nsrc,ntrg);
qqsrc  = randn(nsrc,1);
params = [curvelen,kh];
hold on
plot(C(1,[1:ntot,1]), C(4,[1:ntot,1]),'k.-',...
     xxsrc(1,:), xxsrc(2,:),'r.',...
     xxtrg(1,:), xxtrg(2,:),'b.')
legend('Contour C','Source points xxt','Target points xxs')
axis equal

boundary_x = (-1:0) * pars1.d + pars1.d/2; % 假设原点在中心，边界在 d/2, 3d/2...
for bx = boundary_x
    xline(bx, 'k--', 'LineWidth', 1.5, 'Alpha', 0.7, 'HandleVisibility', 'off');
end
xline(0, 'k-', 'LineWidth', 1, 'Alpha', 0.5, 'HandleVisibility', 'off'); % 源点位置

hold off


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
itype = 1; % Helmholtz double layer potential
tic;
pars2 = precomp_proxy(pars1, pars3);
uu_dir = LOCAL_ref_field(C([1,4],:),xxsrc,qqsrc,pars1,pars2);
uu_ref = LOCAL_ref_field(xxtrg,     xxsrc,qqsrc,pars1,pars2);
A = LOCAL_construct_A_diag(C,iprec,itype,params,pars1,pars2);
A = A + eye(ntot)*0.5;
qq = A\uu_dir;
uu     = LOCAL_evalpot(xxtrg,C,curvelen,qq,itype,pars1,pars2);
t_cost = toc;
errmax = max(abs(uu - uu_ref));
errmsq = sqrt(sum((abs(uu - uu_ref).^2))/length(uu));

fprintf(1,'Maximum error (dlp field) = %3.5e \n',errmax);
fprintf(1,'RMS     error (dlp field) = %3.5e \n',errmsq);
fprintf(1,'Elapsed time              = %3.5e s\n',t_cost);

%  =========================================================================
%  LOCAL HELPER FUNCTIONS
%  =========================================================================

function [C,curvelen,xxint,xxext] = LOCAL_construct_cont(ntot,flag_geom,nint,next)

if strcmp(flag_geom,'star')
  r        = 0.3;
  k        = 5;
  tt       = linspace(0,2*pi*(1 - 1/ntot),ntot);
  C        = zeros(6,ntot );
  C(1,:)   =   1.5*cos(tt) + (r/2)*            cos((k+1)*tt) + (r/2)*            cos((k-1)*tt);
  C(2,:)   = - 1.5*sin(tt) - (r/2)*(k+1)*      sin((k+1)*tt) - (r/2)*(k-1)*      sin((k-1)*tt);
  C(3,:)   = - 1.5*cos(tt) - (r/2)*(k+1)*(k+1)*cos((k+1)*tt) - (r/2)*(k-1)*(k-1)*cos((k-1)*tt);
  C(4,:)   =       sin(tt) + (r/2)*            sin((k+1)*tt) - (r/2)*            sin((k-1)*tt);
  C(5,:)   =       cos(tt) + (r/2)*(k+1)*      cos((k+1)*tt) - (r/2)*(k-1)*      cos((k-1)*tt);
  C(6,:)   = -     sin(tt) - (r/2)*(k+1)*(k+1)*sin((k+1)*tt) + (r/2)*(k-1)*(k-1)*sin((k-1)*tt);
  scale = 0.15;
  C = C * scale;
  curvelen = 2*pi;
  rmin     = sqrt(min(C(1,:).^2 + C(4,:).^2));
  rmax     = sqrt(max(C(1,:).^2 + C(4,:).^2));
  ttint    = 2*pi*rand(1,nint);
  xxint    = 0.6*[rmin*cos(ttint);rmin*sin(ttint)];
  ttext    = 2*pi*rand(1,next);
  xxext    = 1.5*[rmax*cos(ttext);rmax*sin(ttext)];
elseif strcmp(flag_geom,'ellipse')
  a = 0.2;
  b = 0.1;
  tt       = linspace(0,2*pi*(1 - 1/ntot),ntot);
  C        = zeros(6,ntot);
  C(1,:)   =  a*cos(tt);  % x
  C(2,:)   = -a*sin(tt);  % x'
  C(3,:)   = -a*cos(tt);  % x''
  C(4,:)   =  b*sin(tt);  % y
  C(5,:)   =  b*cos(tt);  % y'
  C(6,:)   = -b*sin(tt);  % y''
  curvelen = 2*pi;

  rmin     = sqrt(min(C(1,:).^2 + C(4,:).^2));
  rmax     = sqrt(max(C(1,:).^2 + C(4,:).^2));
  ttint    = 2*pi*rand(1,nint);
  xxint    = 0.6*[rmin*cos(ttint);rmin*sin(ttint)];
  ttext    = 2*pi*rand(1,next);
  xxext    = 1.4*[rmax*cos(ttext);rmax*sin(ttext)];
else
fprintf(1,'This option for the geometry is not implemented.\n')
end
end

function uu = LOCAL_ref_field(xxtrg, xxsrc, qq, pars1, pars2)

nsrc = size(xxsrc,2);
ntrg = size(xxtrg,2);
uu   = zeros(ntrg,1);
for j = 1:ntrg
    for i = 1:nsrc
        src = xxsrc(:,i);
        trg = xxtrg(:,j);
        u = qpgreen_mfs(src, trg, pars1, pars2);
        uu(j) = uu(j) + u.pot * qq(i);
    end
end
end

function A = LOCAL_construct_A_diag(C,iprec,itype,params,pars1,pars2)
% Compute the diagonal submatrix
% iprec: 2, 6, 10 - order of K-R quadrature
% itype: 1 - Helmholtz double layer potential
%        2 - Helmholtz single layer potential
%        3 - normal derivative of Helmholtz double layer potential
%        4 - normal derivative of Helmholtz single layer potential


curvelen = params(1);
% kh       = params(2);
ntot     = size(C,2);
h        = curvelen/ntot;
A = zeros(ntot,ntot);
[JJ, II] = meshgrid(1:ntot, 1:ntot);
L = JJ - II;
L(L > ntot/2) = L(L > ntot/2) - ntot;
L(L <= -ntot/2) = L(L <= -ntot/2) + ntot;

if iprec == 2
  MU  = [ 0.7518812338640025 + 0.1073866830872157e1; ...
         -0.7225370982867850 - 0.6032109664493744];
  width = 2;
elseif iprec == 6
  MU  = [ 0.2051970990601250e1 + 0.2915391987686505e1;...
         -0.7407035584542865e1 - 0.8797979464048396e1;...
          0.1219590847580216e2 + 0.1365562914252423e2;...
         -0.1064623987147282e2 - 0.1157975479644601e2;...
          0.4799117710681772e1 + 0.5130987287355766e1;...
         -0.8837770983721025   - 0.9342187797694916];
  width = 6;
elseif iprec == 10
  MU   = [ 0.3256353919777872D+01 + 0.4576078100790908D+01;...
          -0.2096116396850468D+02 - 0.2469045273524281D+02;...
           0.6872858265408605D+02 + 0.7648830198138171D+02;...
          -0.1393153744796911D+03 - 0.1508194558089468D+03;...
           0.1874446431742073D+03 + 0.1996415730837827D+03;...
          -0.1715855846429547D+03 - 0.1807965537141134D+03;...
           0.1061953812152787D+03 + 0.1110467735366555D+03;...
          -0.4269031893958787D+02 - 0.4438764193424203D+02;...
           0.1009036069527147D+02 + 0.1044548196545488D+02;...
          -0.1066655310499552D+01 - 0.1100328792904271D+01];
  width = 10;
end

if itype == 1 % D operator
  for ix = 1:ntot
    for iy = 1:ntot
      l = L(ix,iy);
      if l == 0
        A(ix,iy) = 0;
      else
        speed = sqrt(C(2,iy)^2 + C(5,iy)^2);
        ny1   =  C(5,iy)/speed;
        ny2   = -C(2,iy)/speed;
        grad = qpgreen_mfs(C([1,4],iy), C([1,4],ix), pars1, pars2).grad;
        A(ix,iy) = -(ny1*grad(1) + ny2*grad(2))*h*speed; % \nabla_y G(x,y) = - \nabla_x G(x,y)
        if abs(l) <= width
          A(ix, iy) = A(ix, iy) * (1 + MU(abs(l)));
        end
      end
    end
  end
elseif itype == 2 % S operator
elseif itype == 3 % T operator
elseif itype == 4 % D^* operator
end

end

function vv = LOCAL_evalpot(xx,C,curvelen,qq,itype,pars1,pars2)
% Evaluate the potential at xx due to sources qq on the contour C.
ns = size(C,2);
nt = size(xx,2);
h  = curvelen/ns;
vv = zeros(nt,1);
if itype == 1 % D operator
  for j = 1:nt
    for i = 1:ns
      src = C([1,4],i);
      trg = xx(:,j);
      grad = qpgreen_mfs(src, trg, pars1, pars2).grad;
      speed = sqrt(C(2,i)^2 + C(5,i)^2);
      ny1   =  C(5,i)/speed;
      ny2   = -C(2,i)/speed;
      % The minus sign is because \nabla_y G(x,y) = - \nabla_x G(x,y)
      vv(j) = vv(j) - qq(i) * (ny1*grad(1) + ny2*grad(2)) * h * speed;
    end
  end
elseif itype == 2 % S operator
end
end