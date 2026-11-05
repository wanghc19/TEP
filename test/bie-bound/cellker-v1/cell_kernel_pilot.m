function result=cell_kernel_pilot(out,study)
% CELL_KERNEL_PILOT Compare seam fits for the active exterior wave number.
% Input
%   out: explicit output directory; study: cell_settings structure.
% Output
%   kernel.json: sweep diagnostics; selected setting is recorded explicitly.
  if nargin<2,study=cell_settings();end
  maxNumCompThreads(11);timer=tic;c=pilot_config();p=struct('k',c.k0,'d',1,'beta',.5);
  old=kernel.precomp_proxy(p,struct('H',1.1,'proxy_dist',.2,'N_side',160,'N_top',160,'N_proxy_edge',80,'M_pw',32));
  phase=exp(1i*.5);settings=study.kernel_sweep;
  rows=struct([]);
  for it=1:size(settings,1)
    s=struct('H',1.1,'edge',settings(it,1),'margin',settings(it,2),'tolerance',settings(it,3),'nx',13,'ny',81,'top',240,'mpw',32);
    [pr,st]=cell_fit(p,s);
    [x,y]=ndgrid(linspace(.003,.997,31),linspace(-1.097,1.097,161));T=[x(:),y(:)];L=T-[1,0];
    [a,ax]=cell_green(p.k,T,[-1,0]);[b,bx]=cell_green(p.k,T,[2,0]);
    [v,gx]=cell_green(p.k,T,pr.Z.');[vl,gxl]=cell_green(p.k,L,pr.Z.');
    st.seam_value=max(abs(a/phase-phase^2*b+(v-phase*vl)*pr.q.'));
    st.seam_derivative=max(abs(ax/phase-phase^2*bx+(gx-phase*gxl)*pr.q.'));
    [x,y]=ndgrid(linspace(-.499,.499,23),linspace(-1.09,1.09,81));T=[x(:),y(:)];
    [vo,gxo,gyo]=cell_green(p.k,T,old.Z.');[vn,gxn,gyn]=cell_green(p.k,T,pr.Z.');
    delta=[(vn*pr.q.'-vo*old.q.'),(gxn*pr.q.'-gxo*old.q.'),(gyn*pr.q.'-gyo*old.q.')];
    for m=[-1,1],[v,gx,gy]=cell_green(p.k,T,[m,0]);delta=delta+phase^m*[v,gx,gy];end
    st.inner_difference=max(abs(delta),[],1);
    st.proxy_cell_clearance=min(max(abs(pr.Z(1,:))-.76,abs(pr.Z(2,:))-.86));
    if isempty(rows),rows=st;else,rows(end+1)=st;end; fprintf('FIT %d seam %.4g %.4g diff %.4g\n',it,st.seam_value,st.seam_derivative,max(st.inner_difference));
    result=struct('rows',rows,'seconds',toc(timer));LOCAL_json(fullfile(out,'kernel.json'),result);
  end
  T=[.5*ones(801,1),linspace(-1.1,1.1,801).'];L=T-[1,0];
  [a,ax,ay]=cell_green(p.k,T,[0,0]);[b,bx,by]=cell_green(p.k,L,[0,0]);
  [v,vx,vy]=cell_green(p.k,T,old.Z.');[w,wx,wy]=cell_green(p.k,L,old.Z.');
  result.old_switch=max(abs([a-phase*b+(v-phase*w)*old.q.',ax-phase*bx+(vx-phase*wx)*old.q.',ay-phase*by+(vy-phase*wy)*old.q.']),[],1);
  result.seconds=toc(timer);LOCAL_json(fullfile(out,'kernel.json'),result);
end
function LOCAL_json(path,data)
  f=fopen(path,'w');fprintf(f,'%s',jsonencode(data,PrettyPrint=true));fclose(f);
end
