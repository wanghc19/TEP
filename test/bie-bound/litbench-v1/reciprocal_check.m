function report=reciprocal_check(out,parameter_file,second_file)
  % Check the more precisely printed coordinate of the same dispersion point.
  % Input: output directory and explicit same-experiment fine-search configuration.
  % Output: propagation constant at the paper's prescribed d/lambda=0.32, and SVD check.
  source=jsondecode(fileread(parameter_file));cfg=source.config;
  maxNumCompThreads(11);k=.32*2*pi;center=1.67541;
  left=center-5e-5;right=center+5e-5;timer=tic;
  [logref,phase,~]=LOCAL_eval(cfg,k,left);
  history=[];
  [beta,~,flag]=fzero(@scalar,[left,right],optimset('TolX',2e-14,'Display','off'));
  [~,~,ratio]=LOCAL_eval(cfg,k,beta);
  report=struct('beta',beta,'fixed_k',k,'frequency',.32,'printed_beta',center,'bracket',[left,right], ...
    'rounded_beta',sprintf('%.5f',beta),'ratio',ratio,'fzero_flag',flag, ...
    'evaluations',numel(history)/2+2,'history',history,'seconds',toc(timer));
  second=jsondecode(fileread(second_file));
  report.polish_fundamental=LOCAL_polish(source);
  report.polish_second=LOCAL_polish(second);
  fid=fopen(fullfile(out,'reciprocal.json'),'w');fwrite(fid,jsonencode(report,PrettyPrint=true));fclose(fid);
  assert(flag>0 && ratio<=1e-11,'litbench:Reciprocal','Reciprocal solve failed confirmation.');
  function v=scalar(b)
    [amp,angle_det,~]=LOCAL_eval(cfg,k,b);
    v=exp(amp-logref)*cos(angle_det-phase);history(end+1,:)=[b,v];
  end
end
function [logabs,phase,ratio]=LOCAL_eval(cfg,k,beta)
  % Input: fixed geometry, frequency and propagation constant. Output: determinant polar data.
  cfg.model.beta=beta;l=search_i9_physics('leads',k,'fine',cfg);
  [s,v]=search_i9_physics('match',k,'fine',cfg,l);
  [~,U,P]=lu(v.matching.Adef);z=diag(U);
  logabs=sum(log(abs(z)));phase=angle(det(P)*prod(z./abs(z)));ratio=s.aphys_ratio;
end

function v=LOCAL_polish(search)
  % Input: recorded fine candidate/configuration. Output: independent local correction.
  cfg=search.config;k=search.candidates(1).k;beta=cfg.model.beta;h=1e-6;
  [lm,pm,~]=LOCAL_eval(cfg,k-h,beta);[lp,pp,~]=LOCAL_eval(cfg,k+h,beta);
  [l0,p0,r0]=LOCAL_eval(cfg,k,beta);
  step=2*h*exp(l0-lm+1i*(p0-pm))/(exp(lp-lm+1i*(pp-pm))-1);
  kp=k-real(step);[~,~,r1]=LOCAL_eval(cfg,kp,beta);
  v=struct('k_input',k,'k_polished',kp,'normalized',kp/(2*pi),'h',h, ...
    'real_step',real(step),'imaginary_step',imag(step),'original_ratio',r0,'new_ratio',r1);
end
