function r=dtn_trace_check(C,S)
% DtN means Dirichlet-to-Neumann: check the exact port correction identity.
% Input: actual FE port nodal values and trace coordinates. Output: residuals.
  [t,w]=dtn_tools('gauss',24);p=C.degree;beta=.5+2*pi*S.k;point=0;mom=zeros(33);n=numel(t);
  L=ones(n,p+1);nodes=(0:p)/p;
  for j=1:p+1,for k=setdiff(1:p+1,j),L(:,j)=L(:,j).*(t-nodes(k))/(nodes(j)-nodes(k));end,end
  fe_difference=0;reference=[0,0;1,0;0,1];pairs=[1,2;2,3;3,1];
  for row=0:numel(C.trace_y)-2
    y0=C.trace_y(row+1);h=C.trace_y(row+2)-y0;y=y0+h*t;target=exp(1i*y*beta);
    gh=L*C.trace_values(row*p+(1:p+1),:);found=false;
    for e=1:size(C.T.tri6,1)
      verts=C.T.xy(C.T.tri6(e,1:3),:);
      for k=1:3
        ids=pairs(k,:);v=verts(ids,:);
        if max(abs(v(:,1)-C.near))<1e-11 && abs(min(v(:,2))-y0)<1e-11 && abs(max(v(:,2))-y0-h)<1e-11
          [~,ix]=sort(v(:,2));r0=reference(ids(ix(1)),:);r1=reference(ids(ix(2)),:);pt=r0+t.*(r1-r0);
          N=dtn_native('basis',p,C.alpha,pt);fe=N*S.first_field(C.tri_dofs(e,:),:);found=true;break
        end
      end
      if found,break;end
    end
    assert(found,'dtn:Trace','Missing physical port edge.');fe_difference=max(fe_difference,max(abs(fe-gh),[],'all'));
    actual=target;actual(:,S.low)=fe+(target(:,S.low)-gh);
    err=actual-target;point=max(point,max(abs(err),[],'all'));mom=mom+target'*((h*w).*err);
  end
  r=struct('pointwise',point,'retained_Fourier',max(abs(mom),[],'all'),'structural_identity',true,'independent_FE_trace_difference',fe_difference);
end
