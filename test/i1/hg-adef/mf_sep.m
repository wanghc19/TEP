function out = mf_sep(Ss,Ts,Sc,Tc,cfg,do_exact)
%MF_SEP Estimate one generalized-Sylvester separation matrix-free.
% Purpose:
%   Apply the operator and its exact Frobenius adjoint, compare four fixed
%   normal-operator routes, and optionally calibrate against a dense oracle.
% Notes:
%   The safety-scaled result is a numerical indicator, never a proven lower
%   bound. Failure of any route is returned explicitly.

  if nargin < 6
    do_exact = false;
  end
  K = size(Ss,1);
  n = 2*K*K;
  apply = @(x) LOCAL_apply(x,Ss,Ts,Sc,Tc,K);
  adjoint = @(y) LOCAL_adjoint(y,Ss,Ts,Sc,Tc,K);

  x = LOCAL_start(n,101);
  y = LOCAL_start(n,103);
  lhs = y'*apply(x);
  rhs = adjoint(y)'*x;
  out.adjoint_error = abs(lhs-rhs) / ...
    max([1,abs(lhs),abs(rhs),norm(x)*norm(y)]);

  out.exact = NaN;
  if do_exact
    I = eye(K);
    L = [kron(I,Ss),-kron(Sc.',I); ...
      kron(I,Ts),-kron(Tc.',I)];
    values = svd(L,'econ');
    out.exact = min(values);
  end

  routes = repmat(struct('name','','sigma',NaN,'flag',-1, ...
    'residual',Inf,'message','NOT_RUN'),4,1);
  routes(1) = LOCAL_route('right-a',apply,adjoint,n,cfg.seeds(1),cfg,false);
  routes(2) = LOCAL_route('right-b',apply,adjoint,n,cfg.seeds(2),cfg,false);
  routes(3) = LOCAL_route('left-a',apply,adjoint,n,cfg.seeds(3),cfg,true);
  routes(4) = LOCAL_route('left-b',apply,adjoint,n,cfg.seeds(4),cfg,true);
  out.routes = routes;
  sigma = [routes.sigma];
  valid = isfinite(sigma) & sigma > 0;
  if all(valid)
    out.raw = median(sigma);
    out.spread = (max(sigma)-min(sigma))/max(sigma);
    out.indicator = min(sigma)/cfg.safety;
  else
    out.raw = NaN;
    out.spread = Inf;
    out.indicator = 0;
  end
  if isfinite(out.exact) && isfinite(out.raw)
    out.exact_error = abs(out.raw-out.exact)/max(out.exact,realmin);
  else
    out.exact_error = NaN;
  end
  exact_ok = ~do_exact || (out.exact_error <= cfg.exact_tol && ...
    out.indicator <= out.exact*(1+100*eps));
  out.pass = out.adjoint_error <= cfg.adjoint_tol && ...
    all([routes.flag] == 0) && ...
    max([routes.residual]) <= cfg.residual_tol && ...
    out.spread <= cfg.spread_tol && exact_ok && ...
    out.indicator > 100*K*eps;
  out.label = cfg.label;
end

%% ==================== Matrix-free operator ====================
% These helpers implement the operator, adjoint, and four deterministic routes.

function y = LOCAL_apply(x,Ss,Ts,Sc,Tc,K)
  R = reshape(x(1:K*K),K,K);
  L = reshape(x(K*K+1:end),K,K);
  Y1 = Ss*R-L*Sc;
  Y2 = Ts*R-L*Tc;
  y = [Y1(:);Y2(:)];
end

function x = LOCAL_adjoint(y,Ss,Ts,Sc,Tc,K)
  Y1 = reshape(y(1:K*K),K,K);
  Y2 = reshape(y(K*K+1:end),K,K);
  R = Ss'*Y1+Ts'*Y2;
  L = -(Y1*Sc'+Y2*Tc');
  x = [R(:);L(:)];
end

function route = LOCAL_route(name,apply,adjoint,n,seed,cfg,use_left)
  route = struct('name',name,'sigma',NaN,'flag',-1, ...
    'residual',Inf,'message','NOT_RUN');
  opts = struct('tol',cfg.tol,'maxit',cfg.maxit,'p',min(cfg.p,n), ...
    'disp',0,'v0',LOCAL_start(n,seed),'issym',true,'isreal',false);
  try
    if use_left
      normal = @(u) apply(adjoint(u));
      [u,d,flag] = eigs(normal,n,1,'smallestreal',opts);
      sigma = sqrt(max(real(d),0));
      if sigma > 0
        v = adjoint(u)/sigma;
      else
        v = zeros(n,1);
      end
    else
      normal = @(v) adjoint(apply(v));
      [v,d,flag] = eigs(normal,n,1,'smallestreal',opts);
      sigma = sqrt(max(real(d),0));
      if sigma > 0
        u = apply(v)/sigma;
      else
        u = zeros(n,1);
      end
    end
    u = u/max(norm(u),realmin);
    v = v/max(norm(v),realmin);
    r1 = norm(apply(v)-sigma*u);
    r2 = norm(adjoint(u)-sigma*v);
    route.sigma = sigma;
    route.flag = flag;
    route.residual = max(r1,r2)/max(1,sigma);
    route.message = 'EIGS_NORMAL_OPERATOR';
  catch ME
    route.message = ['FAIL:',ME.identifier];
  end
end

function x = LOCAL_start(n,seed)
  j = (1:n).';
  x = sin((seed+1)*j)+1i*cos((seed+3)*j);
  x = x/norm(x);
end
