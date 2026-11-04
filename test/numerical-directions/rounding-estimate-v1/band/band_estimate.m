function band_estimate(out)
% MATLAB port of Appendix A of h-cert-proof.md (periodic lead band certificate).
% Plane waves |m|,|n|<=6, 2048-point trapezoid, 118 phase panels on [0,pi].
N = 6; J = 2048; SCALE = 4096; KLOW = 1.318; KHIGH = 2.375;
[mm,nn] = ndgrid(-N:N,-N:N); MN = [mm(:) nn(:)];
% Python ordering is m outer, n inner; reorder to match (irrelevant for eigs).
MN = sortrows(MN,[1 2]); DIM = size(MN,1);
END = [0 1024 1536 2048 2560 2816 3072 3200 3328 3392 3456 3520 3584 3616 3648 3680 3712 3744, ...
  3760:16:3888, 3896:8:3952, 3956:4:4004, 4006:2:4046, 4047:4096];
assert(END(1)==0 && END(end)==SCALE && all(diff(END)>0) && numel(END)-1==118);
EPS_B_ENTRY = 32*pi/expm1(.1*J); EPS_B = DIM*EPS_B_ENTRY;
EPS_M = 16*EPS_B; EPS_G = 256*EPS_B*(3+EPS_B);
avals = [.12 .20]; T = cell(2,2);
for s = 1:2
  B = LOCAL_B(avals(s),N,J,MN);
  T{s,1} = eye(DIM)+16*B; T{s,2} = 256*(B-B*B);
end
rows=[];worst=inf;
lower_min = inf; upper_min = inf; den_min = inf; lam_max = 0; err_max = 0;
for p = 1:numel(END)-1
  l = END(p); h = END(p+1);
  theta = pi*(l+h)/(2*SCALE); r = pi*(h-l)/(2*SCALE);
  assert(theta>=0 && theta<=pi && KLOW>r);
  low = (KLOW-r)^2; high = (KHIGH+r)^2;
  K = diag((2*pi*MN(:,1)+theta).^2+(.5+2*pi*MN(:,2)).^2);
  tail = min((2*pi*(N+1)-abs(theta))^2+.25,(2*pi*(N+1)-.5)^2+theta^2);
  den = tail-17*high; assert(den>0);
  uerr = high*EPS_M+high^2/den*EPS_G;
  for s = 1:2
    M = T{s,1}; G = T{s,2};
    Alo=LOCAL_h(K-low*M);Ahi=LOCAL_h(K-high*M-high^2/den*G);
    e1=eig(Alo);e2=eig(Ahi);
    e1 = sort(e1); e2 = sort(e2);
    neg = -e1(1)-low*EPS_M; pos = e2(2)-uerr;
    assert(neg>0 && pos>0, 'panel %d lead %d failed: %g %g',p,s,neg,pos);
    [Vv,Dv]=eig(Alo);[~,iv]=min(real(diag(Dv)));
    if neg<worst,worst=neg;panel_matrix=Alo;panel_vector=Vv(:,iv);panel_value=e1(1);panel_info=[p,s,theta,r,low];end
    rows=[rows;[p,s,theta,r,neg,pos,norm(Alo,1),norm(Ahi,1),norm(M,1),norm(G,1),low,high,den]]; %#ok<AGROW>
    lower_min = min(lower_min,neg); upper_min = min(upper_min,pos);
  end
  den_min = min(den_min,den); lam_max = max(lam_max,high); err_max = max(err_max,uerr);
end
if ~exist(out,'dir'),mkdir(out);end
save(fullfile(out,'panel.mat'),'panel_matrix','panel_vector','panel_value','panel_info','-v7');
writematrix(rows,fullfile(out,'panels.csv'));
info=struct('lower_min',lower_min,'upper_min',upper_min,'den_min',den_min,'dimension',DIM,'panels',118,'columns',{{'panel','material_index','theta','radius','lower_margin','upper_margin','lower_norm1','upper_norm1','M_norm1','G_norm1','low','high','den'}});
f=fopen(fullfile(out,'result.json'),'w');fprintf(f,'%s\n',jsonencode(info));fclose(f);
for s=1:2
  K = diag((2*pi*MN(:,1)+pi).^2+(.5+2*pi*MN(:,2)).^2); e = sort(real(eig(LOCAL_h(T{s,1})\LOCAL_h(K))));
  fprintf('lead a=%.2f: Ritz sqrt(lambda_1(pi))=%.6f sqrt(lambda_2(pi))=%.6f\n',avals(s),sqrt(e(1)),sqrt(e(2)));
end
fprintf('panels %d, min lower margin %.10e, min upper margin %.10e\n',numel(END)-1,lower_min,upper_min);
fprintf('min tail denominator %.4f, max high %.6f, max matrix error %.3e\n',den_min,lam_max,err_max);
end

function A = LOCAL_h(A)
  A = (A+A')/2;
end

function B = LOCAL_B(a,N,J,MN)
  t = 2*pi*(0:J-1)/J; R = .2/sqrt(1+a*a/2);
  r = R*(1+a*cos(3*t)); dr = -3*R*a*sin(3*t);
  x = r.*cos(t); y = r.*sin(t);
  dx = dr.*cos(t)-r.*sin(t); dy = dr.*sin(t)+r.*cos(t);
  ints = -2*N:2*N; coeff = complex(zeros(4*N+1));
  for i = 1:numel(ints)
    for j = 1:numel(ints)
      qx = 2*pi*ints(i); qy = 2*pi*ints(j); q2 = qx^2+qy^2;
      if q2==0
        coeff(i,j) = .04*pi;
      else
        coeff(i,j) = -1i*sum(exp(1i*(qx*x+qy*y)).*(qx*dy-qy*dx))*(2*pi/J)/q2;
      end
    end
  end
  dm = MN(:,1)'-MN(:,1); dn = MN(:,2)'-MN(:,2);
  B = coeff(sub2ind(size(coeff),dm+2*N+1,dn+2*N+1));
  B = (B+B')/2;
end
