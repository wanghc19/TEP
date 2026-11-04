function result=dtn_estimate(out,side,group,degree,order,certify,liftFactor)
% DtN means Dirichlet-to-Neumann: one all-trace endpoint certificate.
% Input: output directory, physical side, mesh group, field degree, order, flag.
% Output: small endpoint matrices and scalar diagnostics; no MAT files.
  maxNumCompThreads(11);if ~exist(out,'dir'),mkdir(out);end;started=tic;
  if nargin<7,liftFactor=0;end
  C=dtn_native('endpoint',group,degree,side,16,true,out);fprintf('fitted field built %.1f s\n',toc(started));
  C.lift_decay=liftFactor*str2double(group(2:end));
  S=dtn_flux(C,16);C=rmfield(C,'field_map');
  ids=find(abs(C.dof_xy(:,1)-C.near)<1e-11);[~,ix]=sort(C.dof_xy(ids,2));ids=ids(ix);
  C.trace_y=C.dof_xy(ids(1:C.degree:end),2);C.trace_values=S.first_field(ids,:);
  tracecheck=dtn_trace_check(C,S);
  ni=find(abs(C.dof_xy(:,1)-C.near)<1e-11);fi=find(abs(C.dof_xy(:,1)-(C.near+C.sigma))<1e-11);[~,ix]=sort(C.dof_xy(ni,2));ni=ni(ix);[~,ix]=sort(C.dof_xy(fi,2));fi=fi(ix);
  tracecheck.bulk_wall_actual=norm(S.bulk_field(fi,:)-S.bulk_field(ni,:)*C.transfer,'fro');tracecheck.first_wall_actual=norm(S.first_field(fi,:)-S.bulk_field(ni,:)*S.Gnod,'fro');tracecheck.bulk_field_norm=norm(S.bulk_field,'fro');tracecheck.first_field_norm=norm(S.first_field,'fro');
   fprintf('flux built %.1f s\n',toc(started));
  A=dtn_integrate(C,S,order,true,certify);Aalt=[];
  if certify && liftFactor==12
    C.lift_decay=8*str2double(group(2:end));Aalt=dtn_integrate(C,S,order,true,certify);C.lift_decay=liftFactor*str2double(group(2:end));
  end
  B=dtn_integrate(C,S,order,false,certify);
  tr=C.transfer;G=S.Gnod;lp=find(S.low);hp=find(~S.low);beta=.5+2*pi*S.k;q=sqrt(1+beta.^2);scale=diag(1./sqrt(q));
  Q=A.Q;R=A.R;Z=A.Z;
  [qq,eq,wbound]=LOCAL_sum(B.Q,tr);[rr,er]=LOCAL_sum(B.R,tr);[zz,ez]=LOCAL_sum(B.Z,tr);[en,eEn]=LOCAL_sum(B.E,tr);
  Q(lp,lp)=Q(lp,lp)+G'*qq*G;R(lp,lp)=R(lp,lp)+G'*rr*G;Z(lp,lp)=Z(lp,lp)+G'*zz*G;
  kp=279.899894626;km=.70782;kap=sqrt(beta(hp).^2-5.6169);eh=max(exp(-2*kap).*(kap.^2+beta(hp).^2+17)./(2*kap));
  rh=(16*5.6169)^2/17*max(exp(-2*kap)./(2*kap));zh=(1+kp*16*5.6169)^2*max(exp(-2*kap)./(2*kap));
  et=norm(G'*en*G)+norm(G)^2*(eEn+B.eps_E*wbound);rt=norm(G'*rr*G)+norm(G)^2*(er+B.eps_R*wbound);zt=norm(G'*zz*G)+norm(G)^2*(ez+B.eps_Z*wbound);
  eQ=A.eps_Q+norm(G)^2*(eq+B.eps_Q*wbound)+5.6169*(2*sqrt(et*eh)+eh);
  eR=A.eps_R+norm(G)^2*(er+B.eps_R*wbound)+2*sqrt(rt*rh)+rh;
  eZ=A.eps_Z+norm(G)^2*(ez+B.eps_Z*wbound)+2*sqrt(zt*zh)+zh;
  Q=(Q+Q')/2;R=(R+R')/2;Z=(Z+Z')/2;
  M=16;bst=2*pi*(M+1)-.5;ks=sqrt(bst^2-5.6169);ah=sqrt((bst^2-5.6169)/(bst^2+1));bh=.5*(6/(.125^2*ks)+3/.125)^2*exp(-.25*ks);AH=ah-kp*bh;
  Qminus=Q-eQ*eye(33);Rplus=R+eR*eye(33);Zplus=Z+eZ*eye(33);
  lower=Qminus-kp*Rplus-(bh/AH)*Zplus;upper=Q+eQ*eye(33)+km*Rplus;
  r=norm(scale*Rplus*scale);gap=norm(scale*(upper-lower)*scale);
  U=exp(1i*C.wall_y*beta);Dfe=U'*C.D*U;
  result=struct('side',side,'group',group,'degree',degree,'quadrature',order,'certify',certify,'lift_factor',liftFactor,'wall_count',size(tr,1),'triangles',S.G.nt, ...
    'trace_check',tracecheck,'r',r,'K_r',kp*r,'gap',gap,'high_penalty',norm(scale*((bh/AH)*Zplus)*scale),'K_plus',kp,'K_minus',km,'a_H',ah,'b_H_squared',bh,'A_H',AH, ...
    'eps_Q',eQ,'eps_R',eR,'eps_Z',eZ,'first',A.stats,'bulk',B.stats,'series_weight_bound',wbound,'G_norm_squared',norm(G)^2,'transfer_norm',norm(tr),'transfer_norm1',norm(tr,1), ...
    'Q_real',real(Q),'Q_imag',imag(Q),'R_real',real(R),'R_imag',imag(R),'Z_real',real(Z),'Z_imag',imag(Z), ...
    'lower_real',real(lower),'lower_imag',imag(lower),'upper_real',real(upper),'upper_imag',imag(upper), ...
    'fitted_nodal_D_real',real(Dfe),'fitted_nodal_D_imag',imag(Dfe), ...
    'min_Q',LOCAL_min(scale*Q*scale),'min_lower',LOCAL_min(scale*lower*scale), ...
    'min_Q_raw',LOCAL_min(Q),'min_lower_raw',LOCAL_min(lower), ...
    'min_R',LOCAL_min(R),'min_Z',LOCAL_min(Z),'wall_match',S.wall_match,'seconds',toc(started));
  if ~isempty(Aalt)
    Qa=Q+Aalt.Q-A.Q;Ra=R+Aalt.R-A.R;Za=Z+Aalt.Z-A.Z;
    eqa=eQ+Aalt.eps_Q-A.eps_Q;era=eR+Aalt.eps_R-A.eps_R;eza=eZ+Aalt.eps_Z-A.eps_Z;
    La=Qa-eqa*eye(33)-kp*(Ra+era*eye(33))-(bh/AH)*(Za+eza*eye(33));
    Ua=Qa+eqa*eye(33)+km*(Ra+era*eye(33));
    result.alternative=struct('lift_factor',8,'r',norm(scale*(Ra+era*eye(33))*scale), ...
      'gap',norm(scale*(Ua-La)*scale),'lower_difference',norm(scale*(La-lower)*scale), ...
      'overlap_min_1',LOCAL_min(scale*(Ua-lower)*scale),'overlap_min_2',LOCAL_min(scale*(upper-La)*scale), ...
      'lower_real',real(La),'lower_imag',imag(La),'upper_real',real(Ua),'upper_imag',imag(Ua),'first',Aalt.stats);
  end
  fprintf('RESULT before export %s %s r %.9g K*r %.9g gap %.9g\n',side,group,r,kp*r,gap);
  f=fopen(fullfile(out,'result.json'),'w');fprintf(f,'%s\n',jsonencode(result));fclose(f);
  fprintf('RESULT %s %s P%d r %.9g K*r %.9g gap %.9g time %.1f\n',side,group,degree,r,kp*r,gap,toc(started));
end
function [S,error,wbound]=LOCAL_sum(A,P)
  S=(A+A')/2;W=eye(size(P));D=P;
  for j=1:20
    eta=norm(D);if eta<1e-15,break;end
    S=S+D'*S*D;W=W+D'*W*D;D=D*D;
  end
  eta=norm(D);assert(eta<1,'dtn:Transfer','Transfer powers do not contract.');
  error=eta^2/(1-eta^2)*norm(S);wbound=norm(W)/(1-eta^2);
end

function v=LOCAL_min(A)
  v=min(real(eig((A+A')/2)));
end
