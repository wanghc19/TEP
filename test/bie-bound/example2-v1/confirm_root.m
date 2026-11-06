function result=confirm_root(out,e,seed)
%CONFIRM_ROOT Local determinant Newton check on a finer native mesh.
% Input: output directory, explicit example and same-experiment seed.
% Output: root, fresh singular values, determinant phases and field export.
  maxNumCompThreads(11);started=tic;c=example_config(e,search_i9_config());
  k=seed;[lr,pr]=LOCAL_eval(k,c);hist=[];
  for it=1:8
    [l,p]=LOCAL_eval(k,c);h=1e-6;
    [lm,pm]=LOCAL_eval(k-h,c);[lp,pp]=LOCAL_eval(k+h,c);
    f=exp(l-lr+1i*(p-pr));df=(exp(lp-lr+1i*(pp-pr))-exp(lm-lr+1i*(pm-pr)))/(2*h);
    step=f/df;hist=[hist;k,real(step),imag(step)];
    if abs(step)<2e-14,break;end
    k=k-real(step);assert(abs(k-seed)<1e-3,'example2:LocalRoot','Root left local bracket.');
  end
  [~,~,v]=LOCAL_eval(k,c);sv=v.matching.singular_values;
  result=struct('example',e,'seed',seed,'k',k,'k_hex',num2hex(k),'root_history',hist,'sigma_min',sv(end),'sigma_second',sv(end-1),'sigma_ratio',sv(end)/sv(1),'root_seconds',toc(started),'seed_difference',k-seed);
  probes=[];
  for h=[-1e-7,1e-7]
    [l,p]=LOCAL_eval(k+h,c);probes=[probes;k+h,l,p];
  end
  result.root_probes=probes;mkdir(fullfile(out,'field'));result.field=field_export(fullfile(out,'field'),k,'reference',e);
  result.wood_distance=min(abs(v.leads.channels.gamma_m));result.passed=abs(k-seed)<1e-12 && result.sigma_ratio<1e-11 && sv(end-1)>1e6*sv(end);
  result.seconds=toc(started);f=fopen(fullfile(out,'result.json'),'w');cl=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(result));
  assert(result.passed,'example2:Refinement','Root refinement check failed');
end
function [l,p,v]=LOCAL_eval(k,c)
% Input: frequency/configuration. Output: log determinant, phase, match.
  ld=search_i9_physics('leads',k,'fine',c);[~,v]=search_i9_physics('match',k,'fine',c,ld);
  [~,U,P]=lu(v.matching.Adef);z=diag(U);l=sum(log(abs(z)));p=angle(det(P)*prod(z./abs(z)));
end
