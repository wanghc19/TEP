function A=dtn_integrate(C,S,order,first,certify)
% DtN means Dirichlet-to-Neumann: integrate field/residual Gram matrices.
% Input: cell data, conforming flux, order, first-cell flag, enclosure flag.
% Output: Q,R,global Z upper surrogate,E and explicit integration remainders.
  rounding_basis=0;field_absolute=0;rounding_large=0;positive_Q=0;positive_R=0;positive_Z=0;timer=tic;if first,U=S.first_field;flux=S.first_flux;ns=33;else,U=S.bulk_field;flux=S.bulk_flux;ns=size(U,2);end
  A=struct('Q',zeros(ns),'R',zeros(ns),'Z',zeros(ns),'E',zeros(ns),'eps_Q',0,'eps_R',0,'eps_Z',0,'eps_E',0);
  low=S.low;high=~low;beta=.5+2*pi*S.k;kap=sqrt(beta(high).^2-5.6169);kp=279.899894626;
  qc=order;qa=order;if certify,qc=64;if first,qa=80;else,qa=16;end,end
  Rc=C.F.rules(qc);Ra=C.F.rules(qa);cache=cell(1,110);bounds=dtn_bounds(C);maxB=zeros(1,4);parts_count=0;minorder=inf;maxorder=0;points=0;
  for type=1:7
    rule=Rc{type};if type==1,rule=Ra{1};end;if isempty(rule),continue;end
    for elem=rule.ids(:)'
      parts={struct('v',[],'row',-1)};
      if first && type==1,parts=LOCAL_parts(C,elem);end
      for ip=1:numel(parts)
        part=parts{ip};parts_count=parts_count+1;childdet=1;
        if ~isempty(part.v),Bchild=(part.v(2:3,:)-part.v(1,:))';childdet=abs(det(Bchild));end
        coeff=U(C.tri_dofs(elem,:),:);cc=flux(:,:,elem);qo=qc;if type==1,qo=qa;end
        uniform=zeros(1,4);
        if certify && (first || type>1)
          uniform=LOCAL_uniform(C,S,elem,coeff,cc,part,first,bounds,childdet);
          target=1e-14;if first,target=1e-13;end
          ratio=max([uniform([1,2,4])*16*S.G.nt/target,uniform(3)*16*S.G.nt/1e-5]);
          qo=min(104,max(24,ceil(.5*log2(max(1,32*ratio)))));
        end
        if isempty(cache{qo}),cache{qo}=C.F.rules(qo);end
        qr=cache{qo}{type};x=qr.x;y=qr.y;w=qr.w;
        if ~isempty(part.v)
          [rx,ry,rw]=dtn_tools('duffy',qo);pt=part.v(1,:)+[rx,ry]*Bchild';x=pt(:,1);y=pt(:,2);w=rw*childdet;
        end
        minorder=min(minorder,qo);maxorder=max(maxorder,qo);points=points+numel(w);
        [N,Nx,Ny]=dtn_native('basis',C.degree,C.alpha,[x,y]);
        [PX,PY,J,jac]=C.F.map(repmat(elem,numel(x),1),x,y);W=w.*jac;rho=C.T.material(elem);
        u=N*coeff;au=abs(N)*abs(coeff);agx=((abs(J(:,4)).*abs(Nx)+abs(J(:,3)).*abs(Ny))./jac)*abs(coeff);agy=((abs(J(:,2)).*abs(Nx)+abs(J(:,1)).*abs(Ny))./jac)*abs(coeff);
        gx=((J(:,4).*Nx-J(:,3).*Ny)./jac)*coeff;gy=((-J(:,2).*Nx+J(:,1).*Ny)./jac)*coeff;
        [vx,vy,dv]=dtn_tools('rt',x,y);avx=abs(vx)*abs(S.B);avy=abs(vy)*abs(S.B);adv=abs(dv)*abs(S.B);vx=vx*S.B;vy=vy*S.B;dv=dv*S.B;
        px=((J(:,1).*vx+J(:,2).*vy)./jac)*cc;
        py=((J(:,3).*vx+J(:,4).*vy)./jac)*cc;div=(dv./jac)*cc;
        apx=((abs(J(:,1)).*avx+abs(J(:,2)).*avy)./jac)*abs(cc);apy=((abs(J(:,3)).*avx+abs(J(:,4)).*avy)./jac)*abs(cc);adiv=(adv./jac)*abs(cc);
        if first
          uu=complex(zeros(numel(x),33));xx=uu;yy=uu;rrx=uu;rry=uu;rr2=uu;
          cu=zeros(size(u));cx=cu;cy=cu;
          if part.row>=0,[cu,cx,cy,cb]=LOCAL_correction(PX,PY,C,beta(low),part.row);au=au+cb.v;agx=agx+cb.x;agy=agy+cb.y;end
          u=u+cu;gx=gx+cx;gy=gy+cy;
          uu(:,low)=u;xx(:,low)=gx;yy(:,low)=gy;rrx(:,low)=gx-px;rry(:,low)=gy-py;rr2(:,low)=div+5.6169*rho*u;
          inward=C.sigma*(PX-C.near);uh=exp(-inward*kap).*exp(1i*PY*beta(high));
          uu(:,high)=uh;xx(:,high)=-C.sigma*uh.*kap;yy(:,high)=uh.*(1i*beta(high));rr2(:,high)=5.6169*(rho-1)*uh;
          au0=zeros(size(uu));agx0=au0;agy0=au0;apx0=au0;apy0=au0;ad0=au0;au0(:,low)=au;agx0(:,low)=agx;agy0(:,low)=agy;apx0(:,low)=apx;apy0(:,low)=apy;ad0(:,low)=adiv;au0(:,high)=abs(uh);agx0(:,high)=abs(xx(:,high));agy0(:,high)=abs(yy(:,high));apx0(:,high)=agx0(:,high);apy0(:,high)=agy0(:,high);ad0(:,high)=5.6169*abs(uh);au=au0;agx=agx0;agy=agy0;apx=apx0;apy=apy0;adiv=ad0;
          u=uu;gx=xx;gy=yy;r1x=rrx;r1y=rry;r2=rr2;
        else,r1x=gx-px;r1y=gy-py;r2=div+5.6169*rho*u;end
        z=u+kp*r2;
        if first
          pp1=zeros(size(gx));pp2=pp1;dd1=pp1;pp1(:,low)=px;pp2(:,low)=py;dd1(:,low)=div;pp1(:,high)=gx(:,high);pp2(:,high)=gy(:,high);
        else,pp1=px;pp2=py;dd1=div;end
        big=(abs(gx)+abs(pp1)).^2+(abs(gy)+abs(pp2)).^2+(abs(dd1)+5.6169*rho*abs(u)).^2/rho;
        rounding_basis=rounding_basis+sum(W.*((agx+apx).^2+(agy+apy).^2+(adiv+5.6169*rho*au).^2/rho),'all');field_absolute=field_absolute+sum(W.*(agx.^2+agy.^2+5.6169*rho*au.^2),'all');
        rounding_large=rounding_large+sum(W.*big,'all');positive_Q=positive_Q+sum(W.*(abs(gx).^2+abs(gy).^2+5.6169*rho*abs(u).^2),'all');
        positive_R=positive_R+sum(W.*(abs(r1x).^2+abs(r1y).^2+abs(r2).^2/rho),'all');positive_Z=positive_Z+sum(W.*abs(z).^2,'all');
        mass=u'*(W.*u);energy=gx'*(W.*gx)+gy'*(W.*gy);
        A.Q=A.Q+energy-5.6169*rho*mass;A.E=A.E+energy+rho*mass;
        A.R=A.R+r1x'*(W.*r1x)+r1y'*(W.*r1y)+r2'*((W/rho).*r2);A.Z=A.Z+z'*(W.*z);
        if certify && (first || type>1)
          error=32*2^(-2*qo)*uniform;A.eps_Q=A.eps_Q+error(1);A.eps_R=A.eps_R+error(2);A.eps_Z=A.eps_Z+error(3);A.eps_E=A.eps_E+error(4);maxB=max(maxB,uniform);
        end
      end
    end
    fprintf('integrate first=%d type=%d elapsed %.1f s\n',first,type,toc(timer));
  end
  symmetry=[norm(A.Q-A.Q','fro')/max(norm(A.Q,'fro'),realmin),norm(A.R-A.R','fro')/max(norm(A.R,'fro'),realmin),norm(A.Z-A.Z','fro')/max(norm(A.Z,'fro'),realmin)];
  A.Q=(A.Q+A.Q')/2;A.R=(A.R+A.R')/2;A.Z=(A.Z+A.Z')/2;A.E=(A.E+A.E')/2;
  A.stats=struct('parts',parts_count,'min_order',minorder,'max_order',maxorder,'points',points,'curved_order',qc,'common_order',qa,'seconds',toc(timer),'symmetry',symmetry,'max_integrand_bound',maxB, ...
    'rounding_basis_terms_squared',rounding_basis,'field_absolute_terms_squared',field_absolute,'rounding_large_terms_squared',rounding_large,'positive_Q',positive_Q,'positive_R',positive_R,'positive_Z',positive_Z,'max_eta',max(bounds.eta),'max_physical_eta',max(bounds.eta_physical),'min_det',min(bounds.det_lower),'curved_collar_clearance',bounds.collar_clearance);
end

function [c,cx,cy,cb]=LOCAL_correction(X,Y,C,beta,row)
  p=C.degree;y0=C.trace_y(row+1);h=C.trace_y(row+2)-y0;t=(Y-y0)/h;
  [L,D]=LOCAL_lagrange1(t,p);node=C.trace_values(row*p+(1:p+1),:);g=exp(1i*Y*beta);
  delta=g-L*node;dy=g.*(1i*beta)-(D*node)/h;
  inward=C.sigma*(X-C.near);v=inward/.125;chi=1-3*v.^2+2*v.^3;dc=C.sigma*(-6*v+6*v.^2)/.125;
  decay=0;if isfield(C,'lift_decay'),decay=C.lift_decay;end
  f=exp(-decay*inward);dc=f.*(dc-C.sigma*decay*chi);chi=f.*chi;
  c=chi.*delta;cx=dc.*delta;cy=chi.*dy;cb=struct('v',abs(chi).*(abs(g)+abs(L)*abs(node)),'x',abs(dc).*(abs(g)+abs(L)*abs(node)),'y',abs(chi).*(abs(g.*(1i*beta))+abs(D)*abs(node)/h));
end
function [L,D]=LOCAL_lagrange1(t,p)
  L=ones(numel(t),p+1);D=zeros(size(L));nodes=(0:p)/p;
  for j=1:p+1
    other=setdiff(1:p+1,j);
    for k=other,L(:,j)=L(:,j).*(t-nodes(k))/(nodes(j)-nodes(k));end
    for k=other
      v=ones(size(t))/(nodes(j)-nodes(k));
      for l=setdiff(other,k),v=v.*(t-nodes(l))/(nodes(j)-nodes(l));end
      D(:,j)=D(:,j)+v;
    end
  end
end
function parts=LOCAL_parts(C,e)
  verts=C.T.xy(C.T.tri6(e,1:3),:);s=str2double(C.group(2:end));d=C.sigma*(verts(:,1)-C.near);
  parts={struct('v',[],'row',-1)};if min(d)>=.125,return;end
  ref=[0,0;1,0;0,1];parts={};inside=LOCAL_clip(ref,d',.125,true);outside=LOCAL_clip(ref,d',.125,false);
  if size(outside,1)>=3,parts=[parts,LOCAL_fan(outside,-1)];end
  ymin=min(verts(:,2));ymax=max(verts(:,2));
  rows=find(C.trace_y(1:end-1)<ymax & C.trace_y(2:end)>ymin)-1;
  for row=rows(:)'
    y0=C.trace_y(row+1);y1=C.trace_y(row+2);p=LOCAL_clip(inside,verts(:,2)',y0,false);p=LOCAL_clip(p,verts(:,2)',y1,true);
    if size(p,1)>=3,parts=[parts,LOCAL_fan(p,row)];end %#ok<AGROW>
  end
end
function p=LOCAL_clip(p,value,cut,less)
  if isempty(p),return;end
  out=[];v=[1-sum(p,2),p]*value';if ~less,v=-v;cut=-cut;end
  for j=1:size(p,1)
    k=mod(j,size(p,1))+1;a=p(j,:);b=p(k,:);va=v(j)-cut;vb=v(k)-cut;
    if va<=0,out(end+1,:)=a;end %#ok<AGROW>
    if (va<0&&vb>0)||(va>0&&vb<0),out(end+1,:)=a+(b-a)*(-va)/(vb-va);end %#ok<AGROW>
  end
  p=out;
end
function c=LOCAL_fan(p,row)
  c={};for j=2:size(p,1)-1
    v=p([1,j,j+1],:);if abs(det((v(2:3,:)-v(1,:))'))>0,c{end+1}=struct('v',v,'row',row);end %#ok<AGROW>
  end
end

function B=LOCAL_uniform(C,S,e,field,flux,part,first,D,childdet)
  p=C.degree;L=2;if ~isempty(part.v),L=4;end
  un=norm(field,'fro');fn=norm(S.B*flux,'fro');nb=size(field,1);
  ub=sqrt(nb)*(p*L+p)^p*un;gr=sqrt(nb)*2*p^2*(p*L+p)^(p-1)*un;
  gg=2*D.inverse(e)*gr;pr=sqrt(24)*L^4*fn;dr=sqrt(24)*5*L^3*fn;
  pp=D.jacobian(e)/D.det_lower(e)*pr;dd=dr/D.det_lower(e);
  if first
    verts=C.T.xy(C.T.tri6(e,1:3),:);
    if ~isempty(part.v),verts=[1-sum(part.v,2),part.v]*verts;end
    span=max(verts)-min(verts);inward=C.sigma*(verts(:,1)-C.near);
    xmin=min(inward)-.6875*(max(inward)-min(inward))-D.displacement(e);yim=1.03125*span(2)+D.displacement(e);
    beta=.5+2*pi*S.k(~S.low);kap=sqrt(beta.^2-5.6169);vb=exp(-kap*xmin+abs(beta)*yim);
    ub=ub+norm(vb);gg=gg+max(norm(kap.*vb),norm(beta.*vb));
    if part.row>=0
      nl=nnz(S.low);bb=max(abs(.5+2*pi*S.k(S.low)));ex=exp(bb*yim)*sqrt(nl);
      nf=norm(C.trace_values(part.row*p+(1:p+1),:),'fro');hh=C.trace_y(part.row+2)-C.trace_y(part.row+1);
      gn=sqrt(p+1)*(p*4+p)^p*nf;gd=2*p^2*(p*4+p)^(p-1)*sqrt(p+1)*nf/hh;
      decay=0;if isfield(C,'lift_decay'),decay=C.lift_decay;end
      ef=exp(-decay*xmin);ub=ub+ef*82*(ex+gn);gg=gg+ef*((576+82*decay)*(ex+gn)+82*(bb*ex+gd));
    end
  end
  rho=C.T.material(e);jac=D.det_upper(e)*1.125*childdet;
  r1=sqrt(2)*(gg+pp);r2=dd+5.6169*rho*ub;
  B=jac*[2*gg^2+5.6169*rho*ub^2,r1^2+r2^2/rho,(ub+279.899894626*r2)^2,2*gg^2+rho*ub^2];
end
