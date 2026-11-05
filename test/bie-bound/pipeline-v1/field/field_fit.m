% Copied from test/bie-bound/cellfit-v1/field_fit.m.
function [C,stats]=field_fit(cells,maps,model,Z)
% FIELD_FIT Fit 195 field right-hand sides with one scaled SVD.
% Input
%   cells: native templates; maps: center state and two stable-state maps.
%   model: physical parameters; Z: computational proxy coordinates.
% Output
%   C: three fixed proxy coefficient matrices; stats: costs and residuals.
  timer=tic;k=model.khat;q=exp(1i*model.beta*model.d);n=240;nz=size(Z,2);
  T=[.5*ones(n,1),linspace(-1.1,1.1,n).'];L=T-[1,0];
  [v,x]=cell_green(k,T,Z.');[vl,xl]=cell_green(k,L,Z.');
  bm=model.beta+2*pi*(-32:32);gm=sqrt(complex(k*k-bm.^2));np=numel(bm);
  A=[v-q*vl,zeros(n,2*np);x-q*xl,zeros(n,2*np)];aux=cell(1,2);
  for j=1:2
    side=3-2*j;Ta=[linspace(-.5,.5,n).',side*1.1*ones(n,1)];aux{j}=Ta;
    [v,~,y]=cell_green(k,Ta,Z.');P=exp(1i*Ta(:,1)*bm);D=P.*(side*1i*gm);
    B=[v;y];B(:,nz+1:nz+2*np)=0;B(:,nz+(j-1)*np+(1:np))=-[P;D];A=[A;B];
  end
  stats.matrix_seconds=toc(timer);stage=tic;scale=sqrt(sum(abs(A).^2));
  [U,S,V]=svd(A./scale,'econ');sv=diag(S);keep=sv>1e-14*sv(1);
  stats.svd_seconds=toc(stage);stats.rank=sum(keep);stats.rows=size(A,1);stats.columns=size(A,2);
  C=cell(1,3);stats.rhs_seconds=zeros(1,3);stats.apply_seconds=zeros(1,3);stats.fit_max=zeros(1,3);
  for j=1:3
    stage=tic;cm=cells{j};[src,w]=LOCAL_source(cm,maps{j},768,model);
    f=LOCAL_layer(T,src,w,k,[-1,2],[q^-1,-q^2]);rhs=-[f{1};f{2}];
    for h=1:2,f=LOCAL_layer(aux{h},src,w,k,-1:1,q.^(-1:1));rhs=[rhs;-f{1};-f{3}];end
    stats.rhs_seconds(j)=toc(stage);stage=tic;
    sol=(V(:,keep)*((U(:,keep)'*rhs)./sv(keep)))./scale.';
    C{j}=sol(1:nz,:);stats.apply_seconds(j)=toc(stage);stats.fit_max(j)=max(abs(A*sol-rhs),[],'all');
  end
  stats.rhs_columns=cellfun(@(x)size(x,2),C);stats.row_norm_sums=cellfun(@(x)sum(sqrt(sum(abs(x).^2,2))),C);
  stats.seconds=toc(timer);assert(sum(stats.rhs_columns)==195);
end
function [src,w]=LOCAL_source(cm,map,n,model)
  if strcmp(cm.i9_shape,'star'),[g,~]=geom.construct_cont(n,'star',0,0);g=cm.i9_arg*g;
  else,[g,~]=pilot_geometry(n,cm.i9_arg,model.R,model);end
  H=[cm.H_L,cm.H_R]*map;n0=size(H,1)/2;
  tau=interpft(H(1:n0,:),n,1);zeta=interpft(H(n0+1:end,:),n,1);wt=2*pi/n;
  src=[g(4,:).',g(1,:).'];w={-g(2,:).'.*tau*wt,g(5,:).'.*tau*wt,hypot(g(2,:),g(5,:)).'.*zeta*wt};
end
function f=LOCAL_layer(T,src,w,k,shifts,weights)
  f={zeros(size(T,1),size(w{1},2)),zeros(size(T,1),size(w{1},2)),zeros(size(T,1),size(w{1},2))};
  for m=1:numel(shifts)
    for a=1:64:size(T,1)
      ii=a:min(a+63,size(T,1));[v,x,y,xx,xy,yy]=cell_green(k,T(ii,:),src+[shifts(m),0]);
      f{1}(ii,:)=f{1}(ii,:)-weights(m)*(x*w{1}+y*w{2}+v*w{3});
      f{2}(ii,:)=f{2}(ii,:)-weights(m)*(xx*w{1}+xy*w{2}+x*w{3});
      f{3}(ii,:)=f{3}(ii,:)-weights(m)*(xy*w{1}+yy*w{2}+y*w{3});
    end
  end
end
