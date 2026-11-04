function R=core_validate(out,left_path,right_path)
% Core independent positive-volume checks for mixed analytic basis products.
% Input: output directory and fixed left/right lower DtN matrices.
% Output: random mass identities and a direct generalized-eigenvalue check.
  maxNumCompThreads(11);if ~exist(out,'dir'),mkdir(out);end;timer=tic;records=struct([]);
  for Nx=[15,31]
    Ny=(Nx+1)/2;S=core_space(Nx,Ny);J=8*(Nx+33);[A,~]=core_material(S,J);
    rng(121+Nx);v=randn(S.n,3)+1i*randn(S.n,3);v(:,1)=v(:,1)/norm(v(:,1));v(:,2:3)=0;
    ids=[1,min(S.nb,round(S.nb/3)),S.nb,S.nb+1,S.nb+2,S.n-1,S.n];v(ids,2)=randn(numel(ids),1)+1i*randn(numel(ids),1);
    v(S.nb+1:S.n,3)=randn(66,1)+1i*randn(66,1);
    v=v./sqrt(sum(abs(v).^2,1));raw=S.P*v;quadratic=real(sum(conj(raw).*(A*raw),1));
    [r,wr]=LOCAL_gauss(80);[theta,wt]=LOCAL_gauss(384);theta=theta*2*pi;wt=wt*2*pi;volume=zeros(1,3);
    for first=1:32:numel(theta)
      ids=first:min(first+31,numel(theta));[cx,cy,dx,dy]=core_curve('curve',theta(ids));det=cx.*dy-cy.*dx;
      X=r*cx';Y=r*cy';weight=(wr.*r)*(wt(ids).*det)';X=X(:);Y=Y(:);weight=weight(:);u=complex(zeros(numel(X),3));
      for k=-max(Ny,16):max(Ny,16)
        rows=find(S.k==k);a=zeros(numel(X),3);
        if ~isempty(rows),a=cos(pi*(X+.5)*S.m(rows)')*(S.cm(rows).*raw(rows,:));end
        if abs(k)<=16
          j=k+17;q=sqrt(1+(.5+2*pi*k)^2);den=q*(-expm1(-2*q));z=X+.5;
          rep=[exp(-q*z)+exp(-q*(2-z)),exp(-q*(1-z))+exp(-q*(1+z))]/den;a=a+rep*raw(S.nb+(2*j-1:2*j),:);
        end
        u=u+exp(1i*(.5+2*pi*k)*Y).*a;
      end
      volume=volume+sum(weight.*abs(u).^2,1);
    end
    relative=abs(volume-quadratic)./max(abs(volume),realmin);
    % Direct quadrature for all analytic unweighted mass entries, block by k.
    [x,w]=LOCAL_gauss(256);mass_error=0;rep_error=0;
    for k=[0,-3,16]
      rows=find(S.k==k);q=sqrt(1+(.5+2*pi*k)^2);den=q*(-expm1(-2*q));z=x;
      re=[exp(-q*z)+exp(-q*(2-z)),exp(-q*(1-z))+exp(-q*(1+z))]/den;
      dr=q*[-exp(-q*z)+exp(-q*(2-z)),exp(-q*(1-z))-exp(-q*(1+z))]/den;
      cm=S.cm(rows);m=S.m(rows);basis=[cos(pi*z*m').*cm',re];derivative=[-sin(pi*z*m').*(pi*m.*cm)',dr];
      gram=basis'*(w.*basis);energy=derivative'*(w.*derivative)+q^2*gram;
      ri=S.nb+(2*(k+17)-1:2*(k+17));coeff=raw([rows;ri'],:);got=real(sum(conj(coeff).*(gram*coeff),1));
      target=real(sum(conj(v).*(S.M1*v),1)); %#ok<NASGU>
      id=[rows;ri'];Pblock=S.P(id,id);trans=Pblock'*gram*Pblock;mass_error=max(mass_error,norm(trans-S.M1(id,id),'fro'));
      endpoint=[basis(1,:);basis(end,:)]; %#ok<NASGU>
      ct=(1+exp(-2*q))/(-expm1(-2*q));cs=2*exp(-q)/(-expm1(-2*q));
      port=[cm,cm.*(-1).^m;[ct,cs;cs,ct]/q];rep_error=max(rep_error,norm(energy(:,end-1:end)-port,'fro'));
    end
    direct=[];if Nx==15
      left=jsondecode(fileread(left_path));right=jsondecode(fileread(right_path));L=left.hat_Lambda.real+1i*left.hat_Lambda.imag;Rr=right.hat_Lambda.real+1i*right.hat_Lambda.imag;
      Q=6.6169*S.M1+3*5.6169*full(S.P'*A*S.P);B=S.B_left'*L*S.B_left+S.B_right'*Rr*S.B_right;
      T=eye(S.n)-Q+B;direct=sort(real(eig((T+T')/2,(Q+Q')/2)));direct=direct(1:4);
    end
    record=struct('Nx',Nx,'Ny',Ny,'volume_mass',volume,'boundary_mass',quadratic,'mass_relative_difference',relative,'analytic_M1_max_Frobenius_difference',mass_error,'representative_with_representative_error',rep_error,'direct_pencil_eigenvalues',direct);
    record.pass=all(relative<1e-10)&&mass_error<1e-10&&rep_error<1e-10;records=[records;record];fprintf('independent (%d,%d) relative %.3e mass %.3e representative %.3e\n',Nx,Ny,max(relative),mass_error,rep_error);
  end
  R=struct('cases',records,'seconds',toc(timer),'relative_tolerance',1e-10,'absolute_tolerance',1e-10);
  f=fopen(fullfile(out,'validation.json'),'w');fprintf(f,'%s\n',jsonencode(R));fclose(f);
end
function [x,w]=LOCAL_gauss(n)
  j=(1:n-1)';b=j./sqrt(4*j.^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));[x,k]=sort(diag(D));x=(x+1)/2;w=V(1,k)'.^2;
end
