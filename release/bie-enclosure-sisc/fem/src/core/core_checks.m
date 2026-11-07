function C=core_checks(S,J)
% Source: test/numerical-directions/h-core-v1/core_checks.m. Numerical method retained.
% Core independent area/moment quadrature and representative identities.
% Input: spectral space and boundary rule size. Output: finite check records.
  t=(0:J-1)'*2*pi/J;[x,y,dx,dy]=core_curve('curve',t);
  boundary=[sum(x.*dy),sum(x.^3.*dy)/3,-sum(y.^3.*dx)/3]*(2*pi/J);
  [g,w]=LOCAL_gauss(256);tt=2*pi*g;[x,y,dx,dy]=core_curve('curve',tt);det=x.*dy-y.*dx;
  [r,v]=LOCAL_gauss(24);area=sum(v.*r);fourth=sum(v.*r.^3);
  radial=[area*sum(w.*det),fourth*sum(w.*x.^2.*det),fourth*sum(w.*y.^2.*det)]*2*pi;
  exact_area=pi*.04*(1.5+.3^2/2);difference=abs(boundary-radial)./abs(radial);
  [z,w]=LOCAL_gauss(256);xs=z-.5;test=[];
  for k=[0,-3,16]
    q=sqrt(1+(.5+2*pi*k)^2);den=q*(-expm1(-2*q));
    r0=(exp(-q*z)+exp(-q*(2-z)))/den;r1=(exp(-q*(1-z))+exp(-q*(1+z)))/den;
    d0=q*(-exp(-q*z)+exp(-q*(2-z)))/den;d1=q*(exp(-q*(1-z))-exp(-q*(1+z)))/den;
    for m=[0,1,min(7,S.Nx),S.Nx]
      cm=sqrt(2);if m==0,cm=1;end;u=cm*cos(pi*m*z);du=-cm*pi*m*sin(pi*m*z);
      got=[sum(w.*(du.*d0+q^2*u.*r0)),sum(w.*(du.*d1+q^2*u.*r1))];target=cm*[1,(-1)^m];
      test(end+1,:)=[k,m,got,target,max(abs(got-target))]; %#ok<AGROW>
    end
  end
  rng(71);coeff=randn(20,1)+1i*randn(20,1);ms=randi([0,S.Nx],20,1);ks=randi([-16,16],20,1);random_error=0;
  for k=unique(ks)'
    q=sqrt(1+(.5+2*pi*k)^2);den=q*(-expm1(-2*q));rr=[exp(-q*z)+exp(-q*(2-z)),exp(-q*(1-z))+exp(-q*(1+z))]/den;
    dr=q*[-exp(-q*z)+exp(-q*(2-z)),exp(-q*(1-z))-exp(-q*(1+z))]/den;
    ids=find(ks==k);mm=ms(ids);cm=sqrt(2)*ones(size(mm));cm(mm==0)=1;
    u=cos(pi*z*mm')*(cm.*coeff(ids));du=-sin(pi*z*mm')*(pi*mm.*cm.*coeff(ids));
    got=sum(w.*(du.*dr+q^2*u.*rr),1);target=[sum(cm.*coeff(ids)),sum((-1).^mm.*cm.*coeff(ids))];
    random_error=max(random_error,max(abs(got-target))/max(1,norm(target)));
  end
  C=struct('boundary_moments',boundary,'independent_radial_Gauss_moments',radial,'moment_relative_difference',difference, ...
    'exact_area',exact_area,'area_relative_difference',abs(boundary(1)/exact_area-1),'representative_table',test, ...
    'representative_max_absolute',max(test(:,end)),'representative_random_relative',random_error,'moment_tolerance',1e-12,'representative_tolerance',1e-11);
end
function [x,w]=LOCAL_gauss(n)
  j=(1:n-1)';b=j./sqrt(4*j.^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));[x,k]=sort(diag(D));x=(x+1)/2;w=V(1,k)'.^2;
end
