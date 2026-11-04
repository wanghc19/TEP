function S=dtn_flux(C,order)
% DtN means Dirichlet-to-Neumann: construct structurally conforming RT3 fluxes.
% Input: one fitted FE lead cell and assembly quadrature order.
% Output: first-cell and recurrent-cell fields/fluxes in the integer RT basis.
  started=tic;G=dtn_tools('geometry',C.T);B0=exact_rt3_basis();
  [x,y,w]=dtn_tools('duffy',8);[vx,vy,dv]=dtn_tools('rt',x,y);
  [~,RR]=qr([sqrt(w).*(vx*B0(:,13:24));sqrt(w).*(vy*B0(:,13:24));sqrt(w).*(dv*B0(:,13:24))],0);
  change=blkdiag(eye(12),RR\eye(12));Bs=B0*change;
  k=(-16:16);low=abs(k)<=5;Gnod=exp(1i*C.wall_y*(.5+2*pi*k(low)));
  Ubase=C.field_map;Ufirst=Ubase*Gnod;Ubulk=Ubase*C.transfer;
  edge=LOCAL_wall(C,G,Ubase);near=G.left;far=G.right;if C.sigma<0,near=G.right;far=G.left;end
  en=edge(near,:);ef=edge(far,:);bulknear=(ef+en*C.transfer)/2;bulkfar=bulknear*C.transfer;
  fields=cat(2,Ubulk,Ufirst);clear Ubase edge
  ns=size(fields,2);np=size(C.transfer,1);nl=nnz(low);nt=G.nt;
  H=zeros(24,24,nt);b=zeros(24,size(C.alpha,1),nt);rules=C.F.rules(order);
  for type=1:numel(rules)
    rule=rules{type};if isempty(rule),continue;end
    [N,Nx,Ny]=dtn_native('basis',C.degree,C.alpha,[rule.x,rule.y]);
    [vx,vy,dv]=dtn_tools('rt',rule.x,rule.y);vx=vx*Bs;vy=vy*Bs;dv=dv*Bs;nq=numel(rule.w);
    for first=1:8:numel(rule.ids)
      ids=rule.ids(first:min(first+7,numel(rule.ids)));ne=numel(ids);ei=repelem(ids(:),nq);
      [~,~,J,det]=C.F.map(ei,repmat(rule.x,ne,1),repmat(rule.y,ne,1));
      jj=reshape(J,nq,ne,4);dd=reshape(det,nq,1,ne);W=reshape(repmat(rule.w,ne,1).*det,nq,1,ne);rho=reshape(C.T.material(ids),1,1,ne);
      P=(reshape(jj(:,:,1),nq,1,ne).*vx+reshape(jj(:,:,2),nq,1,ne).*vy)./dd;
      V=(reshape(jj(:,:,3),nq,1,ne).*vx+reshape(jj(:,:,4),nq,1,ne).*vy)./dd;D=dv./dd;
      X=(reshape(jj(:,:,4),nq,1,ne).*Nx-reshape(jj(:,:,3),nq,1,ne).*Ny)./dd;
      Y=(-reshape(jj(:,:,2),nq,1,ne).*Nx+reshape(jj(:,:,1),nq,1,ne).*Ny)./dd;
      H(:,:,ids)=pagemtimes(P,'transpose',W.*P,'none')+pagemtimes(V,'transpose',W.*V,'none')+pagemtimes(D,'transpose',W./rho.*D,'none');
      b(:,:,ids)=pagemtimes(P,'transpose',W.*X,'none')+pagemtimes(V,'transpose',W.*Y,'none')-5.6169*pagemtimes(D,'transpose',W.*N,'none');
    end
  end
  fprintf('flux assembly %.1f s, %d triangles %d states\n',toc(started),nt,ns);
  ii=13:24;ee=1:12;Y=pagemldivide(H(ii,ii,:),H(ii,ee,:));rr=pagemldivide(H(ii,ii,:),b(ii,:,:));
  HH=H(ee,ee,:)-pagemtimes(H(ee,ii,:),Y);bb=b(ee,:,:)-pagemtimes(H(ee,ii,:),rr);clear H b
  ph=G.phase.';map=G.map.';VV=conj(reshape(ph,12,1,nt)).*HH.*reshape(ph,1,12,nt);
  I=repmat(reshape(map,12,1,nt),1,12,1);J=repmat(reshape(map,1,12,nt),12,1,1);
  A=sparse(I(:),J(:),VV(:),G.nedge,G.nedge);A=(A+A')/2;
  nf=size(C.alpha,1);rv=repmat(reshape(map,12,1,nt),1,nf,1);cv=repmat(reshape(C.tri_dofs.',1,nf,nt),12,1,1);
  val=conj(reshape(ph,12,1,nt)).*bb;Op=sparse(rv(:),cv(:),val(:),G.nedge,size(fields,1));rhs=Op*fields;
  clear HH bb VV I J rv cv val Op fields
  fixed=[near;far];values=[bulknear;bulkfar];
  cb=LOCAL_solve(A,rhs(:,1:np),Y,rr,G,fixed,values,change,Ubulk,C.tri_dofs);
  c0=LOCAL_solve(A,rhs(:,np+(1:nl)),Y,rr,G,far,bulknear*Gnod,change,Ufirst,C.tri_dofs);
  S=struct('G',G,'B',B0,'bulk_field',Ubulk,'first_field',Ufirst,'bulk_flux',cb,'first_flux',c0, ...
    'Gnod',Gnod,'low',low,'k',k,'wall_match',norm(bulkfar-bulknear*C.transfer,'fro'), ...
    'seconds',toc(started));
end

function c=LOCAL_solve(A,rhs,Y,r,G,fixed,values,change,field,dofs)
  free=setdiff((1:G.nedge)',fixed);edge=complex(zeros(size(rhs)));edge(fixed,:)=values;
  factor=decomposition(A(free,free),'chol');edge(free,:)=factor\(rhs(free,:)-A(free,fixed)*values);clear factor
  ns=size(rhs,2);nt=G.nt;c=complex(zeros(24,ns,nt));
  for e=1:nt
    ce=G.phase(e,:).'.*edge(G.map(e,:),:);ci=r(:,:,e)*field(dofs(e,:),:)-Y(:,:,e)*ce;
    c(:,:,e)=change*[ce;ci];
  end
end

function edge=LOCAL_wall(C,G,U)
  edge=complex(zeros(G.nedge,size(U,2)));[t,w]=dtn_tools('gauss',12);L=dtn_tools('legendre',t);
  for wall={G.left,G.right}
    ww=wall{1};
    for j=1:4:numel(ww)
      id=ww(j);[e,le]=find(G.map(:,[1,5,9])==id);assert(numel(e)==1);
      if le==1,x=t;y=0*t;dr=[1,0];elseif le==2,x=1-t;y=t;dr=[-1,1];else,x=0*t;y=1-t;dr=[0,-1];end
      [N,Nx,Ny]=dtn_native('basis',C.degree,C.alpha,[x,y]);[~,~,J,det]=C.F.map(repmat(e,numel(t),1),x,y);
      gx=((J(:,4).*Nx-J(:,3).*Ny)./det)*U(C.tri_dofs(e,:),:);
      gy=((-J(:,2).*Nx+J(:,1).*Ny)./det)*U(C.tri_dofs(e,:),:);
      tx=J(:,1)*dr(1)+J(:,2)*dr(2);ty=J(:,3)*dr(1)+J(:,4)*dr(2);
      moment=L'*(w.*(ty.*gx-tx.*gy));
      edge(ww(j:j+3),:)=moment./G.phase(e,(le-1)*4+(1:4)).';
    end
  end
end
