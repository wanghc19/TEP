function [A,info]=core_material(S,J)
% Core true-star mass Gram assembled from grouped exponential moments.
% Input: analytic space, trapezoid nodes. Output: raw mass and operator error.
  started=tic;Nx=S.Nx;Ny=S.Ny;nb=S.nb;np=66;n=S.n;A=zeros(n);rows=zeros(n,1);roundrows=rows;
  [d,l]=ndgrid(0:2*Nx,0:2*Ny);[z,err,re]=core_curve('moments',1i*pi*d,2i*pi*l,zeros(size(d)),J);
  C=reshape(real(exp(1i*pi*d(:)/2).*z),size(d));Ec=reshape(err,size(d));ER=reshape(re,size(d));
  for first=1:128:nb
    ids=first:min(first+127,nb);dd=abs(S.k(ids)-S.k');a=abs(S.m(ids)-S.m');b=S.m(ids)+S.m';
    i=sub2ind(size(C),a+1,dd+1);j=sub2ind(size(C),b+1,dd+1);factor=S.cm(ids)*S.cm'/2;
    A(ids,1:nb)=factor.*(C(i)+C(j));rows(ids)=sum(factor.*(Ec(i)+Ec(j)),2);roundrows(ids)=sum(factor.*(ER(i)+ER(j)),2);
  end
  clear C Ec d l z err
  [m,l]=ndgrid(0:Nx,0:Ny+16);
  for j=1:33
    q=sqrt(1+(.5+2*pi*S.pk(j))^2);D=q*(-expm1(-2*q));
    [zm,em,rm]=core_curve('moments',-q+1i*pi*m,2i*pi*l,-q/2+zeros(size(m)),J);
    [zp,ep,rp]=core_curve('moments',q+1i*pi*m,2i*pi*l,-q/2+zeros(size(m)),J);
    zm=reshape(real(exp(1i*pi*m(:)/2).*zm),size(m));zp=reshape(real(exp(1i*pi*m(:)/2).*zp),size(m));em=reshape(em,size(m));ep=reshape(ep,size(m));rm=reshape(rm,size(m));rp=reshape(rp,size(m));
    idx=sub2ind(size(m),S.m+1,abs(S.k-S.pk(j))+1);rr=nb+(2*j-1:2*j);
    mix=S.cm.*[zm(idx)+exp(-q)*zp(idx),zp(idx)+exp(-q)*zm(idx)]/D;
    ee=S.cm.*[em(idx)+exp(-q)*ep(idx),ep(idx)+exp(-q)*em(idx)]/D;
    ere=S.cm.*[rm(idx)+exp(-q)*rp(idx),rp(idx)+exp(-q)*rm(idx)]/D;roundrows(1:nb)=roundrows(1:nb)+sum(ere,2);roundrows(rr)=roundrows(rr)+sum(ere,1)';
    A(1:nb,rr)=mix;A(rr,1:nb)=mix';rows(1:nb)=rows(1:nb)+sum(ee,2);rows(rr)=rows(rr)+sum(ee,1)';
  end
  % Four exponential products for every representative pair, one batch.
  [ii,jj,si,sj]=ndgrid(1:66,1:66,1:2,1:2);ki=S.pk(ceil(ii/2));kj=S.pk(ceil(jj/2));qi=sqrt(1+(.5+2*pi*ki).^2);qj=sqrt(1+(.5+2*pi*kj).^2);
  aa=(2*si-3).*qi+(2*sj-3).*qj;bb=2i*pi*(kj-ki);off=-(qi+qj)/2;
  wi=ones(size(ii));wj=wi;wi((mod(ii,2)==1&si==2)|(mod(ii,2)==0&si==1))=exp(-qi((mod(ii,2)==1&si==2)|(mod(ii,2)==0&si==1)));
  wj((mod(jj,2)==1&sj==2)|(mod(jj,2)==0&sj==1))=exp(-qj((mod(jj,2)==1&sj==2)|(mod(jj,2)==0&sj==1)));
  weight=wi.*wj./(qi.*(-expm1(-2*qi)).*qj.*(-expm1(-2*qj)));
  [z,err,re]=core_curve('moments',aa,bb,off,J);z=reshape(real(z),size(aa)).*weight;err=reshape(err,size(aa)).*weight;re=reshape(re,size(aa)).*weight;
  A(nb+1:end,nb+1:end)=sum(z,[3,4]);rows(nb+1:end)=rows(nb+1:end)+sum(sum(err,[3,4]),2);
  roundrows(nb+1:end)=roundrows(nb+1:end)+sum(sum(re,[3,4]),2);
  defect=norm(A-A','fro')/max(norm(A,'fro'),realmin);A=(A+A')/2;
  info=struct('rounding_raw_estimate',max(roundrows),'rounding_normalized_estimate',max(roundrows)*S.P_norm_squared_bound,'rounding_path',8*J+200,'nodes',J,'strip',.1,'raw_error_norm',max(rows),'normalized_error',max(rows)*S.P_norm_squared_bound,'symmetry',defect,'seconds',toc(started),'moment_count', (2*Nx+1)*(2*Ny+1)+2*33*(Nx+1)*(Ny+17)+numel(aa));
  fprintf('material Nx=%d Ny=%d J=%d seconds %.1f raw error %.3e normalized %.3e\n',Nx,Ny,J,toc(started),info.raw_error_norm,info.normalized_error);
end
