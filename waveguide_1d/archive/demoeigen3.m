format long;
clear;

% Diagnostic Script: Singular Value Landscape for Fixed Beta
format long;
clear;

% --- 1. Parameter Setup ---
ntot_list = [60, 80, 100, 120]; % 4 different boundary point counts
flag_geom = 'ellipse';
iprec = 10;
% pars2.M = 200; % High M to ensure Sl precision
% pars2.L = 12;  
er = 13;
nref = sqrt(er);
d = 1.0;
beta = 0.5 * 2 * pi / d; % Fixed Bloch phase

pars1.beta = beta;
pars1.d = d;

pars2.H = 0.5 * pars1.d;              % Height of the fundamental domain[-H, H]
pars2.proxy_dist = 0.2 * pars1.d;     % Distance of proxy boundary from the domain
pars2.N_side = 50;                   % Number of collocation points on Left/Right walls
pars2.N_top = 50;                    % Number of collocation points on Top/Bottom walls
pars2.N_proxy_edge = 30;              % Number of proxy sources per edge (Total = 320)
pars2.M_pw = 10;                      % Truncation order for plane waves (-M_pw to M_pw)

% Define dense k sweep range (below the light line k < beta)
num_k = 200; % High resolution to catch sharp dips and noise
k_samples = linspace(0.01 * beta, 0.99 * beta, num_k); 

fprintf('Generating Singular Value Landscape (beta = %.4f)\n', beta);

% --- 2. Prepare Figure ---
figure('Name', 'Singular Value Landscape Diagnosis', 'Position',[100, 100, 1000, 800], 'Color', 'w');

% --- 3. Loop Over ntot and Plot ---
for idx = 1:length(ntot_list)
  ntot = ntot_list(idx);
  fprintf('Scanning ntot = %d... ', ntot);
  
  [C, curvelen, ~, ~] = LOCAL_construct_cont(ntot, flag_geom, 0, 0);
  s_vals = zeros(size(k_samples));
  
  for j = 1:length(k_samples)
    kh = k_samples(j);
    pars1.k = kh;
    
    % Precompute MFS proxy parameters for current k
    proxy = precomp_proxy(pars1, pars2);
    
    % Construct BIE Matrix
    A = LOCAL_construct_A(C, iprec, kh*nref, pars1, proxy, curvelen);
    
    % Calculate smallest singular value
    s = svd(A);
    s_vals(j) = s(end);
  end
  fprintf('Done.\n');
  
  % Plotting in subplot (using log scale for Y-axis to highlight deep roots)
  subplot(2, 2, idx);
  semilogy(k_samples, s_vals, 'b-', 'LineWidth', 1.5);
  grid on;
  
  title(sprintf('ntot = %d', ntot), 'FontSize', 12);
  xlabel('Wavenumber k', 'FontSize', 11);
  ylabel('\sigma_{min}', 'FontSize', 11);
  xlim([min(k_samples), max(k_samples)]);
  
  % Optional: Set y-limits fixed to easily compare across subplots
  % ylim([1e-10, 1e2]); 
end

fprintf('\nAll plots generated successfully. Please inspect the curves.\n');

%% =========================================================================
%  LOCAL HELPER: Matrix assembly and SVD
%  =========================================================================
function smin = LOCAL_get_min_sv(kh, nref, C, iprec, pars1, pars2, curvelen)
  pars1.k = kh;
  % Recalculate Lattice Sums for each k
  Sl = comp_lattice_sums(pars1, pars2);
  % Construct Muller/BIE Matrix
  A = LOCAL_construct_A(C, iprec, kh*nref, pars1, Sl, curvelen);
  % Return smallest singular value
  s = svd(A);
  smin = s(end);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
  curvelen = 2*pi;
  rmin     = sqrt(min(C(1,:).^2 + C(4,:).^2));
  rmax     = sqrt(max(C(1,:).^2 + C(4,:).^2));
  ttint    = 2*pi*rand(1,nint);
  xxint    = 0.6*[rmin*cos(ttint);rmin*sin(ttint)];
  ttext    = 2*pi*rand(1,next);
  xxext    = 1.6*[rmax*cos(ttext);rmax*sin(ttext)];
elseif strcmp(flag_geom,'ellipse')
  a = 0.4;
  b = 0.4;
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A = LOCAL_construct_A(C,iprec,khint,pars1,proxy,curvelen)

ntot = size(C,2);
A    = eye(2*ntot,2*ntot);
h    = curvelen/ntot;
[jj,ii] = meshgrid(1:ntot,1:ntot);
L = jj - ii;
L(L > ntot/2) = L(L > ntot/2) - ntot;
L(L <= -ntot/2) = L(L <= -ntot/2) + ntot;

if (iprec == 2)
  MU  = [ 0.7518812338640025 + 0.1073866830872157e1; ...
         -0.7225370982867850 - 0.6032109664493744];
  width = 2;
elseif (iprec == 6)
  MU  = [ 0.2051970990601250e1 + 0.2915391987686505e1;...
         -0.7407035584542865e1 - 0.8797979464048396e1;...
          0.1219590847580216e2 + 0.1365562914252423e2;...
         -0.1064623987147282e2 - 0.1157975479644601e2;...
          0.4799117710681772e1 + 0.5130987287355766e1;...
         -0.8837770983721025   - 0.9342187797694916];
  width = 6;
elseif (iprec == 10)
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
for ix = 1:ntot
  for iy = 1:ntot
    l = L(ix,iy);
    if (l == 0)
      continue;
    else
      speedx = sqrt(C(2,ix)^2 + C(5,ix)^2);
      speedy = sqrt(C(2,iy)^2 + C(5,iy)^2);
      nx1   =  C(5,ix)/speedx;
      nx2   = -C(2,ix)/speedx;
      ny1   =  C(5,iy)/speedy;
      ny2   = -C(2,iy)/speedy;

      [pot,grad,hess] = LOCAL_h2d_directch(khint, C([1,4],iy), 1, C([1,4],ix));
      A(ix     ,iy     ) = (ny1*grad(1) + ny2*grad(2))*h*speedy;  % -D^{(k_int)}
      A(ix     ,iy+ntot) = pot*h*speedy; % S^{(k_int)}
      A(ix+ntot,iy     ) = (nx1*ny1*hess(1) + (nx1*ny2+nx2*ny1)*hess(2) + nx2*ny2*hess(3))*h*speedy;  % -D'^{(k_int)}
      A(ix+ntot,iy+ntot) = (nx1*grad(1) + nx2*grad(2))*h*speedy; % S'^{(k_int)}

      % [pot,grad,hess] = LOCAL_h2d_directch(khext, C([1,4],iy), 1, C([1,4],ix));
      % u = qpgreen(C([1,4],iy), C([1,4],ix), pars1, Sl);
      u = qpgreen_mfs(C([1,4],iy), C([1,4],ix), pars1, proxy);
      pot = u.pot;
      grad = u.grad;
      hess = u.hess;
      A(ix     ,iy     ) = A(ix     ,iy     ) - (ny1*grad(1) + ny2*grad(2))*h*speedy;  % +D^{(k_ext)}
      A(ix     ,iy+ntot) = A(ix     ,iy+ntot) - pot*h*speedy; % -S^{(k_ext)}
      A(ix+ntot,iy     ) = A(ix+ntot,iy     ) - ...
            (nx1*ny1*hess(1) + (nx1*ny2+nx2*ny1)*hess(2) + nx2*ny2*hess(3))*h*speedy;  % +D'^{(k_ext)}
      A(ix+ntot,iy+ntot) = A(ix+ntot,iy+ntot) - (nx1*grad(1) + nx2*grad(2))*h*speedy; % -S'^{(k_ext)}

      if abs(l) <= width
        A(ix     , iy     ) = A(ix, iy) * (1 + MU(abs(l)));
        A(ix     , iy+ntot) = A(ix, iy+ntot) * (1 + MU(abs(l)));
        A(ix+ntot, iy     ) = A(ix+ntot, iy) * (1 + MU(abs(l)));
        A(ix+ntot, iy+ntot) = A(ix+ntot, iy+ntot) * (1 + MU(abs(l)));
      end
    end
  end
end

speed = sqrt(C(2,:).^2 + C(5,:).^2);
W = sqrt(h*diag([speed, speed]));
Winv = sqrt((1/h)*diag(1./[speed, speed]));
A = W*A*Winv;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [pot,grad,hess] = LOCAL_h2d_directch(wavek,sources,charge,targ)

ns   = size(sources,2);
nt   = size(targ,2);
pot  = zeros(1,nt);
grad = zeros(2,nt);
hess = zeros(3,nt);

ima4inv = 1i/4;

for j = 1:nt
  for i = 1:ns
    xdiff = targ(1,j)-sources(1,i);
    ydiff = targ(2,j)-sources(2,i);
    rr    = xdiff*xdiff + ydiff*ydiff;
    r     = sqrt(rr);
    z     = wavek*r;

    h0 = besselh(0,z);
    h1 = besselh(1,z);
    cdd  = -h1*(wavek*ima4inv/r);
    cdd2 = (wavek*ima4inv/r)/rr;
    h2z = (-z*h0+2*h1);
    hf1 = (h2z*xdiff*xdiff-rr*h1);
    hf2 = (h2z*xdiff*ydiff      );
    hf3 = (h2z*ydiff*ydiff-rr*h1);

    pot(j) = pot(j) + h0*ima4inv*charge(i);

    cd = cdd*charge(i);
    grad(1,j) = grad(1,j) + cd*xdiff;
    grad(2,j) = grad(2,j) + cd*ydiff;

    cd = cdd2*charge(i);
    hess(1,j) = hess(1,j) + cd*hf1;
    hess(2,j) = hess(2,j) + cd*hf2;
    hess(3,j) = hess(3,j) + cd*hf3;
  end
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%