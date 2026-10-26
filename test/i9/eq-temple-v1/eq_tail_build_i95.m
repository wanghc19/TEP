function [ext,info]=eq_tail_build_i95(mesh,full_field,mu_h,beta,glue_cell,tail_cells)
%EQ_TAIL_BUILD_I95 Replace both lead ends by a finite discrete Floquet tail.
% Purpose: Build the s-eq-temple Section 5 trial with a finite tail. Beyond the
%   glue walls x=+-(glue_cell+1/2) the native field is replaced by decaying
%   discrete Floquet modes of the adjacent lead cell, continued for tail_cells
%   translated cells and closed by a zero outer wall (H^1 zero extension).
% Input: native FEM mesh/field, frozen mu_h and beta, glue cell index and tail length.
% Output: ext mesh struct (same fields as the FEM mesh), ext.field on p2 nodes,
%   and info with multipliers, matching residual and closing amplitude.
% Main algorithm:
%   1. assemble the reference cell stiffness/mass with the FEM rho_h and order-8
%      Duffy quadrature, impose the y quasi-periodic phase inside the cell;
%   2. Schur-eliminate interior unknowns; solve the 24x24 quadratic pencil
%      S_RL + zeta (S_RR+S_LL) + zeta^2 S_LR and keep |zeta|<1;
%   3. match the native glue-wall trace exactly, generate tail cells, zero the
%      last outer wall, merge nodes and rebuild P2 edge numbering.
% Based on: test/i9/compare-v1/fem_i9_run.m LOCAL_assemble and LOCAL_basis.
% Numerical goal: an H^1_beta trial whose end defect is ~|zeta|^tail_cells.
  tol=1e-9;parts=struct('xy',{},'tri6',{},'cell',{},'material',{},'value',{});
  keep=abs(mesh.cell_id)<=glue_cell;
  parts(1)=LOCAL_part(mesh,find(keep),full_field,0,mesh.cell_id(keep));
  info=struct('glue_cell',glue_cell,'tail_cells',tail_cells,'sides',struct([]));
  for side=[-1,1]
    ref=side*(glue_cell+1);ids=find(mesh.cell_id==ref);
    inner=side*(glue_cell+.5);outer=side*(glue_cell+1.5);
    [nodes,~,local]=unique(mesh.triangle_p2(ids,:));tri=reshape(local,[],6);xy=mesh.p2_points(nodes,:);
    [K,M]=LOCAL_assemble(xy,tri,mesh.material(ids));
    n=size(xy,1);top=find(abs(xy(:,2)-.5)<tol);bot=find(abs(xy(:,2)+.5)<tol);
    [~,a]=sort(xy(top,1));top=top(a);[~,a]=sort(xy(bot,1));bot=bot(a);
    assert(numel(top)==numel(bot)&&max(abs(xy(top,1)-xy(bot,1)))<tol,'i95:TailQP','Cell seam pairing failed.');
    master=(1:n)';master(top)=bot;free=setdiff((1:n)',top);[~,col]=ismember(master,free);
    phase=ones(n,1);phase(top)=exp(1i*beta);P=sparse(1:n,col,phase,n,numel(free));
    A=P'*(K-mu_h*M)*P;A=(A+A')/2;fx=xy(free,1);fy=xy(free,2);
    L=find(abs(fx-inner)<tol);R=find(abs(fx-outer)<tol);
    [~,a]=sort(fy(L));L=L(a);[~,a]=sort(fy(R));R=R(a);
    assert(numel(L)==numel(R)&&max(abs(fy(L)-fy(R)))<tol,'i95:TailWall','Glue and outer walls differ.');
    I=setdiff((1:numel(free))',[L;R]);W=[L;R];
    Ainv=@(B)A(I,I)\B;S=A(W,W)-A(W,I)*Ainv(A(I,W));nw=numel(L);
    SLL=S(1:nw,1:nw);SLR=S(1:nw,nw+1:end);SRL=S(nw+1:end,1:nw);SRR=S(nw+1:end,nw+1:end);
    [X,zeta]=polyeig(full(SRL),full(SRR+SLL),full(SLR));
    decay=abs(zeta)<1;assert(nnz(decay)==nw,'i95:TailCount','Expected %d decaying multipliers, found %d.',nw,nnz(decay));
    X=X(:,decay);zeta=zeta(decay);X=X./vecnorm(X);
    % Native glue-wall trace in free-dof coordinates (bottom master values).
    gidx=LOCAL_find(mesh.p2_points,[fx(L),fy(L)],tol);g=full_field(gidx);
    c=X\g;match=norm(X*c-g)/norm(g);
    V=-Ainv(A(I,L)*X+A(I,R)*(X.*zeta.'));
    for k=0:tail_cells-1
      amp=c.*zeta.^k;y=complex(zeros(numel(free),1));
      y(L)=X*amp;y(I)=V*amp;y(R)=X*(amp.*zeta);
      if k==tail_cells-1,closing=norm(y(R))/norm(g);y(R)=0;end
      part=struct('xy',xy+[side*k,0],'tri6',tri,'cell',repmat(ref+side*k,numel(ids),1), ...
        'material',mesh.material(ids),'value',P*y);
      parts(end+1)=part; %#ok<AGROW>
    end
    item=struct('side',side,'reference_cell',ref,'wall_dofs',nw,'zeta_abs',sort(abs(zeta),'descend').', ...
      'zeta_abs_max',max(abs(zeta)),'unit_circle_gap',min(abs(abs(zeta)-1)),'match_residual',match, ...
      'closing_relative_amplitude',closing,'glue_trace_norm',norm(g),'coefficient_norm',norm(c));
    if isempty(info.sides),info.sides=item;else,info.sides(end+1)=item;end
  end
  ext=LOCAL_merge(parts,tol);
  ext.xmin=-(glue_cell+.5+tail_cells);ext.xmax=glue_cell+.5+tail_cells;ext.ymin=-.5;ext.ymax=.5;
  info.elements=size(ext.triangles,1);info.p2_nodes=size(ext.p2_points,1);
  info.merge_value_defect=ext.merge_value_defect;
end

%% ==================== Tail parts and merging ====================
% Each part keeps its own six-node elements; coincident nodes are merged once.
function part=LOCAL_part(mesh,ids,field,~,cells)
  [nodes,~,local]=unique(mesh.triangle_p2(ids,:));
  part=struct('xy',mesh.p2_points(nodes,:),'tri6',reshape(local,[],6),'cell',cells, ...
    'material',mesh.material(ids),'value',field(nodes));
end
function ext=LOCAL_merge(parts,tol)
  xy=vertcat(parts.xy);val=vertcat(parts.value);tri=[];off=0;
  for j=1:numel(parts),tri=[tri;parts(j).tri6+off];off=off+size(parts(j).xy,1);end %#ok<AGROW>
  key=round(xy/tol);[~,first,map]=unique(key,'rows','stable');
  spread=@(v)accumarray(map,v,[],@max)-accumarray(map,v,[],@min);
  defect=max(hypot(spread(real(val)),spread(imag(val))));
  xy=xy(first,:);val=val(first);tri=map(tri);
  % Rebuild FEM-style numbering: vertices first, then one midpoint per edge.
  t3=tri(:,1:3);[vid,~,vmap]=unique(t3(:));t3=reshape(vmap,[],3);nv=numel(vid);nt=size(t3,1);
  [edges,~,eid]=unique(sort([t3(:,[1,2]);t3(:,[2,3]);t3(:,[3,1])],2),'rows');eid=reshape(eid,nt,3);
  mids=zeros(size(edges,1),1);mids(eid(:))=reshape(tri(:,4:6),[],1);
  p2=[xy(vid,:);xy(mids,:)];value=[val(vid);val(mids)];
  ext=struct('points',xy(vid,:),'triangles',t3,'p2_points',p2,'triangle_p2',[t3,nv+eid], ...
    'edges',edges,'cell_id',vertcat(parts.cell),'material',vertcat(parts.material), ...
    'field',value,'merge_value_defect',defect);
  a=ext.points(t3(:,2),:)-ext.points(t3(:,1),:);b=ext.points(t3(:,3),:)-ext.points(t3(:,1),:);
  assert(all(a(:,1).*b(:,2)-a(:,2).*b(:,1)>0),'i95:TailOrientation','Merged element orientation failed.');
end
function idx=LOCAL_find(points,query,tol)
  [found,idx]=ismember(round(query/tol),round(points/tol),'rows');
  assert(all(found),'i95:TailTrace','Glue-wall node missing in native mesh.');
end

%% ==================== Reference cell FEM matrices (from I9.3) ====================
% Same isoparametric P2 basis, rho_h weights and order-8 Duffy quadrature.
function [K,M]=LOCAL_assemble(xy,tri,material)
  nt=size(tri,1);nd=size(xy,1);X=reshape(xy(tri,1),nt,6);Y=reshape(xy(tri,2),nt,6);
  [lambda,weights]=LOCAL_quadrature(8);kval=zeros(nt,36);mval=zeros(nt,36);
  for q=1:numel(weights)
    [basis,G]=LOCAL_basis(lambda(q,:));
    j11=X*G(1,:)';j12=X*G(2,:)';j21=Y*G(1,:)';j22=Y*G(2,:)';d=j11.*j22-j12.*j21;w=weights(q)*d;
    dx=(j22.*G(1,:)-j21.*G(2,:))./d;dy=(-j12.*G(1,:)+j11.*G(2,:))./d;
    for b=1:6
      for a=1:6
        v=a+6*(b-1);kval(:,v)=kval(:,v)+w.*(dx(:,a).*dx(:,b)+dy(:,a).*dy(:,b));
        mval(:,v)=mval(:,v)+material.*w*basis(a)*basis(b);
      end
    end
  end
  rows=zeros(nt,36);cols=rows;
  for b=1:6,for a=1:6,v=a+6*(b-1);rows(:,v)=tri(:,a);cols(:,v)=tri(:,b);end,end
  K=sparse(rows(:),cols(:),kval(:),nd,nd);M=sparse(rows(:),cols(:),mval(:),nd,nd);
end
function [basis,G]=LOCAL_basis(l)
  gl=[-1,1,0;-1,0,1];basis=[l.*(2*l-1),4*l(1)*l(2),4*l(2)*l(3),4*l(3)*l(1)];
  G=zeros(2,6);
  for j=1:3,G(:,j)=(4*l(j)-1)*gl(:,j);end
  G(:,4)=4*(l(1)*gl(:,2)+l(2)*gl(:,1));G(:,5)=4*(l(2)*gl(:,3)+l(3)*gl(:,2));G(:,6)=4*(l(3)*gl(:,1)+l(1)*gl(:,3));
end
function [lambda,weights]=LOCAL_quadrature(order)
  j=(1:order-1)';b=j./sqrt(4*j.^2-1);[V,D]=eig(diag(b,1)+diag(b,-1));
  [x,idx]=sort(diag(D));w=V(1,idx)'.^2;x=(x+1)/2;
  [r,s]=ndgrid(x,x);[wr,ws]=ndgrid(w,w);xi=r(:);eta=(1-xi).*s(:);
  lambda=[1-xi-eta,xi,eta];weights=wr(:).*ws(:).*(1-xi);
end
