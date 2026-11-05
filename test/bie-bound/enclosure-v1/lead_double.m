function result=lead_double(input_path,fit_path,out)
% LEAD_DOUBLE Floating right-lead jump using the cellfit material operator.
% Input
%   Explicit exact-input JSON, B coefficients JSON, output directory.
% Output
%   Jump values on 256 points, raw components and finite-cell square sums.
  maxNumCompThreads(11);timer=tic;data=jsondecode(fileread(input_path));fits=jsondecode(fileread(fit_path));
  piece=data.pieces{3};k=LOCAL_decode(data.k);beta=LOCAL_decode(data.beta);d=LOCAL_decode(data.d);pars0=LOCAL_decode(data.curve_parameters);
  Ct=LOCAL_decode(piece.tau_coeff);Cz=LOCAL_decode(piece.zeta_coeff);G=LOCAL_decode(piece.G);c=LOCAL_decode(piece.c);P=LOCAL_decode(piece.P);
  bc=LOCAL_decode(fits.B_positive);Z=LOCAL_decode(fits.Z);N=1536;
  model=struct('X_L',-.5,'X_R',.5,'d',d);[C,len]=pilot_geometry(N,pars0(7),pars0(8),model);
  pars=struct('k',k,'beta',beta,'d',d,'periodic_axis','y');proxy=struct('Z',Z,'q',zeros(1,size(Z,2)),'H',1.1);
  H=[LOCAL_density(Ct,piece.modes,N);LOCAL_density(Cz,piece.modes,N)];
  speed=hypot(C(2,:),C(5,:)).';weights=len/N*speed;scale=sqrt([weights;weights]);
  chans=bloch.rayleigh_channels(k,beta,d,48,1);[BL,BR]=bloch.incident_rhs(C,chans,-.5,.5);B=[BL,BR];
  t=tic;A=cell_operator(C,k,k*sqrt(17),pars,proxy,len);op_seconds=toc(t);
  raw=(A*(scale.*H)+scale.*B)./scale;rawmap=raw*G;
  [vp,gx,gy]=cell_green(k,[C(4,:).',C(1,:).'],Z.');normalx=C(5,:).'./speed;normaly=-C(2,:).'./speed;
  pm=[vp*bc;(normaly.*gx+normalx.*gy)*bc];jm=rawmap+pm;
  j0=jm*c;state=G*c;
  direct=(A*(scale.*(H*state))+scale.*(B*state))./scale+pm*c;
  value2=0;normal2=0;v=c;
  for j=1:40,z=jm*v;value2=value2+sum(weights.*abs(z(1:N)).^2);normal2=normal2+sum(weights.*abs(z(N+1:end)).^2);v=P*v;end
  idx=(1:6:N).';theta=(idx-1)*2*pi/N;
  T=table(idx-1,theta,C(1,idx).',C(4,idx).',real(j0(idx)),imag(j0(idx)),real(-j0(N+idx)),imag(-j0(N+idx)), ...
    real(direct(idx)),imag(direct(idx)),real(-direct(N+idx)),imag(-direct(N+idx)), ...
    'VariableNames',{'index','theta','x','y','value_re','value_im','normal_re','normal_im','early_value_re','early_value_im','early_normal_re','early_normal_im'});
  writetable(T,fullfile(out,'double.csv'));
  result=struct('N',N,'targets',numel(idx),'kint',num2hex(k*sqrt(17)),'value_squared40',value2,'normal_squared40',normal2, ...
    'finite_squared40',value2+normal2,'late_early_max_value',max(abs(j0(1:N)-direct(1:N))), ...
    'late_early_max_normal',max(abs(j0(N+1:end)-direct(N+1:end))), 'operator_seconds',op_seconds, ...
    'max_unsummed_operator_action',max(abs((A*(scale.*H))./scale),[],'all'), ...
    'max_unsummed_incident',max(abs(B),[],'all'),'seconds',toc(timer));
  fid=fopen(fullfile(out,'double.json'),'w');fprintf(fid,'%s',jsonencode(result,PrettyPrint=true));fclose(fid);disp(result);
end
function x=LOCAL_decode(o)
  x=reshape(hex2num(char(o.real))+1i*hex2num(char(o.imag)),o.shape.');
  if all(imag(x)==0,'all'),x=real(x);end
end
function H=LOCAL_density(C,modes,N)
  coeff=zeros(N,size(C,2));
  for j=1:numel(modes),idx=mod(modes(j),N)+1;coeff(idx,:)=coeff(idx,:)+N*C(j,:);end
  H=ifft(coeff,[],1);
end
