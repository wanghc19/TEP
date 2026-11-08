function accuracy_probe(out,plan)
  % Estimate root shifts with an independently closed Green fit and a directional perturbation.
  % Input: branch seeds, grid and model from an explicit reference-only plan.
  % Output: local Newton histories, independent Green tests, and root sensitivity.
  for j=1:numel(plan.jobs)
    q=plan.jobs(j);k=q.seed;c=probe_config(q);t=abs(k-q.beta);
    c2=c;c2.common.nside=192;c2.common.ntop=192;c2.common.nproxy=96;
    c2.backend.fmm_eps=1e-14;c2.proxy_kind='spectral';c2.bias=0;
    h=min(1e-6,t/50);
    if isfield(plan,'check_reference') && plan.check_reference
      c3=c2;c3.common.nside=224;c3.common.ntop=224;c3.common.nproxy=112;
      [k1,hist1]=polish(k,c2,h);[k2,hist2]=polish(k,c3,h);
      r=struct('tag',q.tag,'beta',q.beta,'seed',q.seed,'changed_green_k',k1, ...
        'larger_reference_k',k2,'difference',k2-k1,'side_counts',[192,224], ...
        'proxy_edge_counts',[96,112],'histories',{{hist1,hist2}});
      f=fopen(fullfile(out,sprintf('reference-control-%03d.json',j)),'w');assert(f>=0);
      fprintf(f,'%s\n',jsonencode(r));fclose(f);
      continue
    end
    [kb,eb]=polish(k,c,h);[kr,er]=polish(k,c2,h);
    [g0,g1,gex]=green(kr,c,c2);
    % A real and an imaginary homogeneous grazing bias span possible complex phase errors.
    % Use one perturbed matrix in the reference chart for each direction.
    b0=border_data(kr,c2,false);chart=struct('L',b0.ZL,'R',b0.ZR);
    H=border_matrix(b0,chart);[u,~,v]=svd(H,'econ');u=u(:,end);v=v(:,end);
    Hp=border_matrix(border_data(kr+h,c2,false),chart);
    Hm=border_matrix(border_data(kr-h,c2,false),chart);
    df=(u'*(Hp-Hm)*v)/(2*h);dr=zeros(1,2);
    for n=1:2
      c2.bias=1e-6*1i^(n-1);
      dH=border_matrix(border_data(kr,c2,false),chart)-H;
      dr(n)=-real((u'*dH*v)/df)/1e-6;
    end
    r=struct('tag',q.tag,'N',q.N,'model',q.model,'beta',q.beta,'detuning',q.detuning, ...
      'original_local_k',kb,'reference_k',kr,'actual_t',abs(kr-q.beta), ...
      'green_background_error',abs(g0-gex),'green_reference_error',abs(g1-gex), ...
      'root_sensitivity',dr,'predicted_root_shift_scale',norm(dr)*1.3e-14/abs(kr-q.beta), ...
      'default_history',eb,'reference_history',er,'derivative_step',h);
    f=fopen(fullfile(out,sprintf('accuracy-%03d.json',j)),'w');fprintf(f,'%s\n',jsonencode(r));fclose(f);
    fprintf('reference %s k %.16g proxy errors %.3g %.3g\n',q.tag,kr,abs(g0-gex),abs(g1-gex));
  end
end
function [k,hist]=polish(k,c,h)
  % Use the local null vectors only in the reference calculation.
  hist=[];
  for it=1:4
    b=border_data(k,c,false);a=struct('L',b.ZL,'R',b.ZR);
    H=border_matrix(b,a);[u,S,v]=svd(H,'econ');u=u(:,end);v=v(:,end);
    Hp=border_matrix(border_data(k+h,c,false),a);Hm=border_matrix(border_data(k-h,c,false),a);
    df=u'*(Hp-Hm)*v/(2*h);step=(u'*H*v)/df;
    hist(end+1,:)=[k,real(step),imag(step),S(end,end)];
    k=k-real(step);
    if abs(real(step))<3e-14,break;end
  end
end
function [g0,g1,exact]=green(k,c,c2)
  % Independent spectral sum at the physical separation used in wood-probe-v1.
  pars=struct('k',k,'beta',c.model.beta,'d',c.model.d,'periodic_axis','y');
  for n=1:2
    if n==1,z=c;kind='outgoing';else,z=c2;kind='spectral';end
    spec=struct('H',z.model.H,'proxy_dist',z.model.proxy_dist,'N_side',z.common.nside, ...
      'N_top',z.common.ntop,'N_proxy_edge',z.common.nproxy,'M_pw',z.common.mpw);
    p=fast_proxy(pars,spec,kind,0);
    G=kernel.qpgreen_mfs_pairmat([.4;.17],[0;0],pars,p);
    if n==1,g0=G;else,g1=G;end
  end
  bm=pars.beta+(-80:80)*2*pi/pars.d;g=sqrt((k-abs(bm)).*(k+abs(bm)));
  exact=sum(1i./(2*pars.d*g).*exp(-1i*.17*bm+1i*.4*g));
end
