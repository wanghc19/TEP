function gauss_export(out)
% Export the Golub-Welsch rules used by the copied FEM and certificate codes.
% Input: fresh output directory. Output: small MATLAB-v7 nodes and weights.
  mkdir(out);maxNumCompThreads(11);orders=2:104;X=cell(1,numel(orders));W=X;
  for i=1:numel(orders)
    n=orders(i);j=(1:n-1)';b=j./sqrt(4*j.^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));[x,k]=sort(diag(D));X{i}=(x+1)/2;W{i}=V(1,k)'.^2;
  end
  save(fullfile(out,'gauss.mat'),'orders','X','W','-v7');
end
