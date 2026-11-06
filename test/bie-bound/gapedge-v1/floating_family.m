function result=floating_family(out,widths,kstart)
%FLOATING_FAMILY Track an empty-center guided mode and lead contractions.
% Input: explicit output directory and center widths; fixed binary64 model.
% Output: scalar root histories and propagation norm tables, no field dumps.
  if nargin<3,kstart=1.8916961400527375;end
  maxNumCompThreads(11);started=tic;rows={};k=kstart;
  for iw=1:numel(widths)
    e=example_parameters('empty-rotated',widths(iw),.85,.13);c=example_config(e,search_i9_config());hist=[];ok=false;t=tic;
    if iw>=3,k=rows{iw-1}.k+(widths(iw)-widths(iw-1))*(rows{iw-1}.k-rows{iw-2}.k)/(widths(iw-1)-widths(iw-2));end
    try
      for it=1:20
        [l,p,v,ld]=LOCAL_eval(k,c);sv=v.matching.singular_values;
        if sv(end)/sv(1)<2e-14,ok=true;break;end
        h=1e-6;[lm,pm]=LOCAL_eval(k-h,c);[lp,pp]=LOCAL_eval(k+h,c);
        step=1/((exp(lp-l+1i*(pp-p))-exp(lm-l+1i*(pm-p)))/(2*h));hist=[hist;k,real(step),imag(step)];
        dk=max(-.08,min(.08,real(step)));kn=k-dk;
        if kn<=1.442 || kn>=2.395,error('gapedge:Window','Continuation left floating common gap at k=%.17g',kn);end
        if abs(dk)<1e-14,k=kn;[l,p,v,ld]=LOCAL_eval(k,c);ok=true;break;end
        k=kn;
      end
      sv=v.matching.singular_values;rr=struct('L0',e.L0,'k',k,'k_hex',num2hex(k),'sigma_min',sv(end),'sigma_second',sv(end-1),'sigma_ratio',sv(end)/sv(1),'history',hist,'seconds',toc(t),'passed',ok && sv(end)/sv(1)<1e-11);
      for side={'negative','positive'}
        z=ld.(side{1});K=size(z.Z,2);A=[-z.R_L,eye(K);z.T_LR,zeros(K)];B=[zeros(K),z.T_RL;eye(K),-z.R_R];
        if strcmp(side{1},'negative'),P=(A*z.Z)\(B*z.Z);else,P=(B*z.Z)\(A*z.Z);end
        ppow=eye(K);norms=[];pfirst=0;
        for power=1:200
          ppow=ppow*P;norms(end+1)=norm(ppow,2);
          if norms(end)<1,pfirst=power;break;end
        end
        rr.(side{1})=struct('spectral_radius',max(abs(eig(P))),'norm2',norm(P,2),'normfro',norm(P,'fro'),'p',pfirst,'r',norms(end),'power_norms',norms);
      end
      rows{end+1}=rr;fprintf('L0 %.4g k %.17g norms %.6g %.6g\n',e.L0,k,rr.negative.norm2,rr.positive.norm2);
      if ~rr.passed,break;end
    catch err
      rows{end+1}=struct('L0',e.L0,'k',k,'passed',false,'error',err.message,'history',hist,'seconds',toc(t));
      break;
    end
    LOCAL_write(out,rows,toc(started));
  end
  result=LOCAL_write(out,rows,toc(started));
end
function [l,p,v,ld]=LOCAL_eval(k,c)
% Input: frequency and model. Output: normalized determinant and matching data.
  ld=search_i9_physics('leads',k,'fine',c);[~,v]=search_i9_physics('match',k,'fine',c,ld);
  [~,U,P]=lu(v.matching.Adef);z=diag(U);l=sum(log(abs(z)));p=angle(det(P)*prod(z./abs(z)));
end
function r=LOCAL_write(out,rows,seconds)
% Input: scalar rows. Output: saved JSON result.
  r=struct('rows',{rows},'seconds',seconds);f=fopen(fullfile(out,'series.json'),'w');cl=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(r));
end
