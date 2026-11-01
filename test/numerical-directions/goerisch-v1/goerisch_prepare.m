function result = goerisch_prepare(input_dir, output_dir)
  % Goerisch preparation: reproduce the reconstructed trial and inspect input.
  % Input
  %   input_dir: read-only I9.6 (implementation experiment 9.6) run-03 folder.
  %   output_dir: new folder for scalar outputs only.
  % Output
  %   result: quotient check, tail estimates and native template dimensions.
  started=tic;
  [r,t]=goerisch_trial(input_dir,output_dir,'control');
  reference=2.428728699465642;
  result=struct('theta',r.theta,'theta_reference',reference, ...
    'theta_relative_difference',abs(r.theta-reference)/reference);
  assert(result.theta_relative_difference<1e-12,'goerisch:Theta', ...
    'Copied trial did not reproduce theta-v1.');
  result.full_box_tail_mass_upper=17*r.tail_norm/r.denominator;
  result.tail_by_box=LOCAL_tails(t,r.denominator);
  clear t
  data=load(fullfile(input_dir,'native.mat'),'native');
  native=data.native; clear data
  names={'left','center','right'}; result.templates=struct();
  for j=1:3
    T=native.templates.(names{j});
    result.templates.(names{j})=struct('nodes',size(T.xy,1), ...
      'triangles',size(T.tri6,1),'bounds',[min(T.xy);max(T.xy)], ...
      'fields',{fieldnames(T)});
  end
  result.cell_indices=[native.cells.index];
  result.wall_seconds=toc(started);
  f=fopen(fullfile(output_dir,'prepare.json'),'w');
  assert(f>=0); closer=onCleanup(@()fclose(f)); %#ok<NASGU>
  fwrite(f,jsonencode(result,PrettyPrint=true),'char');
  disp(result);
end

function rows=LOCAL_tails(t,mass)
  % Unweighted mass outside each integer-cell box, multiplied by rho_max.
  C=t.coefficients; p=t.parameters; N=p.N; nc=p.cells_per_side;
  q=p.beta+2*pi*(-p.M:p.M)'; a=sqrt(p.s+q.^2); h=1/N;
  [x,w]=LOCAL_gauss(12); columns=zeros(1,size(C,2));
  for j=1:numel(x)
    z=h*x(j);
    v=(C(:,:,1)+C(:,:,2)*z)./a.^2+C(:,:,3).*exp(-a*z)+C(:,:,4).*exp(-a*(h-z));
    columns=columns+h*w(j)*sum(abs(v).^2,1);
  end
  outside=sum((abs(t.wl).^2+abs(t.wr).^2)./(2*a));
  rows=zeros(nc,2);
  for K=1:nc
    kept=(nc-K)*N+(1:(2*K+1)*N);
    rows(K,:)=[K,17*(sum(columns(1:kept(1)-1))+sum(columns(kept(end)+1:end))+outside)/mass];
  end
end

function [x,w]=LOCAL_gauss(n)
  j=(1:n-1)'; b=j./sqrt(4*j.^2-1); [V,D]=eig(diag(b,1)+diag(b,-1));
  [x,k]=sort(diag(D)); x=(x+1)/2; w=V(1,k)'.^2;
end
