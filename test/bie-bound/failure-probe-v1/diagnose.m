function r=diagnose(q,c,out)
  % Diagnostic frequency, phase, cut and subspace probes.
  % Input: job parameters, configured model and output directory. Output: scalar records.
  rows={};roots={};minimums={};
  if ismember(q.action,{'scan','diagonal','amplitude-scan'})
    grid=linspace(q.window(1),q.window(2),q.count);
    for j=1:numel(grid)
      v=sample(grid(j));rows{end+1}=v;
      if isfield(q,'cut_grid') && strcmp(v.status,'GAP')
        l=lead_at(grid(j));rows{end}.cuts=cut_scan(l,c,q.cut_grid);
      end
    end
    metric=cellfun(@(x)x.ratio,rows);
    for j=2:numel(grid)-1
      if metric(j)<=metric(j-1) && metric(j)<metric(j+1) && isfinite(metric(j))
        bracket=grid([j-1 j+1]);t=fminbnd(@ratio,bracket(1),bracket(2),optimset('TolX',1e-11,'Display','off'));
        steps=[1e-5,1e-6,1e-7,1e-8];
        if isfield(q,'local_scale') && q.local_scale
          steps=min(steps,diff(bracket)*[.24,.08,.025,.008]);
        end
        for h=steps
          y=[ratio(t-h),ratio(t),ratio(t+h)].^2;den=y(1)+y(3)-2*y(2);
          if den>0
            d=h*(y(1)-y(3))/(2*den);
            if abs(d)<h && t+d>=bracket(1) && t+d<=bracket(2),t=t+d;end
          end
        end
        v=sample(t);v.bracket=bracket;minimums{end+1}=v;
        if v.ratio<=1e-11,roots{end+1}=v;end
      end
    end
  elseif ismember(q.action,{'field-at','amplitude-field'})
    t=q.start;v=sample(t);
    if strcmp(v.status,'GAP')
      try
        cf=c;cf.fields=true;[kk,cf]=coordinates(t,cf);l=search_i9_physics('leads',kk,'fine',cf);
        route='match';if strcmp(q.action,'amplitude-field'),route='amplitude_check';end
        [~,e]=search_i9_physics(route,kk,'fine',cf,l);v.field=physical_checks(e,cf,q);
      catch err
        v.field_error=struct('identifier',err.identifier,'message',err.message,'stack',err.stack);
      end
    end
    roots={v};
  elseif strcmp(q.action,'points')
    for t=q.values(:).',rows{end+1}=sample(t);end
  elseif strcmp(q.action,'local') || strcmp(q.action,'field') || strcmp(q.action,'vectors')
    t=q.start;
    for it=1:10
      h=1e-6;if isfield(q,'step'),h=q.step;end
      v=sample(t);if ~strcmp(v.status,'GAP'),break;end
      m=sample(t-h);p=sample(t+h);
      if ~strcmp(m.status,'GAP')||~strcmp(p.status,'GAP'),break;end
      step=2*h/(exp(p.logabs-v.logabs+1i*(p.phase-v.phase))-exp(m.logabs-v.logabs+1i*(m.phase-v.phase)));
      v.step=[real(step),imag(step)];rows{end+1}=v;
      if abs(real(step))<=2e-14,break;end
      if abs(real(step))>.05,break;end
      t=t-real(step);
    end
    v=sample(t);v.iterations=it;roots={v};
    if strcmp(q.action,'field') && strcmp(v.status,'GAP')
      cf=c;cf.fields=true;[kk,cf]=coordinates(t,cf);l=search_i9_physics('leads',kk,'fine',cf);
      [~,e]=search_i9_physics('match',kk,'fine',cf,l);v.field=physical_checks(e,cf,q);roots={v};
    end
  else,error('probe:Action','Unknown diagnostic action');end
  r=struct('status','MEASURED','rows',{rows},'roots',{roots},'minimums',{minimums});
  function [k,cf]=coordinates(t,cf)
    if strcmp(q.action,'diagonal') || isfield(q,'diagonal')
      cf.model.beta=t;k=t+q.offset;
    else,k=t;end
    if strcmp(q.action,'vectors') || (isfield(q,'vector_field') && q.vector_field),cf.vector_route=true;end
  end
  function l=lead_at(t)
    [k,cf]=coordinates(t,c);l=search_i9_physics('leads',k,'fine',cf);
  end
  function s=ratio(t)
    a=sample(t);s=a.ratio;
  end
  function v=sample(t)
    [k,cf]=coordinates(t,c);v=struct('k',k,'beta',cf.model.beta,'ratio',Inf,'status','ERROR','stage','lead');
    gm=sqrt(complex(k^2-(cf.model.beta+2*pi*(-cf.common.M:cf.common.M)).^2));
    v.gamma_min=min(abs(gm));v.port_cond=max([1,abs(gm)])/min([1,abs(gm)]);
    try
      l=search_i9_physics('leads',k,'fine',cf);v.status='BAND';v.lead_status={l.negative_diagnostic.status,l.positive_diagnostic.status};
      v.gamma_min=min(abs(l.channels.gamma_m));g=l.channels.gamma_m;v.port_cond=max([1;abs(g(:))])/min([1;abs(g(:))]);
      v.lead_A_rcond=[l.negative.A_rcond,l.positive.A_rcond];v.extract_norm=[l.negative.extract_norm,l.positive.extract_norm];
      if ~l.common_gap,return;end
      if isfield(q,'amplitude') && q.amplitude
        v.amplitude=search_i9_physics('amplitude_check',k,'fine',cf,l);
      end
      if ismember(q.action,{'amplitude-scan','amplitude-field'})
        av=search_i9_physics('amplitude_check',k,'fine',cf,l);
        v.ratio=av.ratio;v.sigma=av.sigma;v.status='GAP';v.stage='amplitude';return
      end
      v.stage='match';v.status='ERROR';[pointMetric,pointEvidence]=search_i9_physics('match',k,'fine',cf,l);v.status='GAP';v.ratio=pointMetric.aphys_ratio;v.sigma=pointMetric.aphys_sigma;v.sigma_max=pointEvidence.matching.singular_values(1);
      [~,U,P]=lu(pointEvidence.matching.Adef);z=diag(U);v.logabs=sum(log(abs(z)));v.phase=angle(det(P)*prod(z./abs(z)));
      v.center_A_rcond=1;if isfield(pointEvidence.center,'A_rcond'),v.center_A_rcond=pointEvidence.center.A_rcond;end
      v.D_min=[dmin(l.negative.Z),dmin(l.positive.Z)];v.D_rcond=[pointEvidence.matching.dtn_diagnostic.negative_rcond,pointEvidence.matching.dtn_diagnostic.positive_rcond];
      if isfield(q,'eigen') || strcmp(q.action,'vectors')
        v.subspace={sub(l.negative,true),sub(l.positive,false)};
      end
    catch err
      v.identifier=err.identifier;v.message=err.message;v.stack=err.stack;
    end
  end
end
function d=dmin(Z)
  % Minimum singular value of the Dirichlet trace on an orthonormal basis.
  n=size(Z,1)/2;d=min(svd(Z(1:n,:)+Z(n+1:end,:)));
end
function v=sub(s,reverse)
  % Compare orthonormal stable QZ and normalized generalized eigenvectors.
  n=size(s.R_L,1);I=eye(n);O=zeros(n);
  A=[-s.R_L,I;s.T_LR,O];B=[O,s.T_RL;I,-s.R_R];if reverse,[A,B]=deal(B,A);end
  [V,w]=eig(A,B,'vector');mask=abs(w)<1;Vs=V(:,mask);Vs=Vs./vecnorm(Vs);
  [Q,~]=qr(Vs,0);cross=norm(Q-s.Z*(s.Z'*Q),2);outside=w(~mask & isfinite(w));inside=w(mask);
  separation=min(abs(inside(:)-outside(:).'),[],'all');
  v=struct('count',sum(mask),'unit_distance',min(abs(abs(w(isfinite(w)))-1)), ...
    'stable_unit_distance',1-max(abs(inside)),'separation',separation,'eigen_condition',cond(Vs),'rank',rank(Vs),'K',n,'sin_angle',cross,'angle',asin(min(1,cross)));
end
function tab=cut_scan(l,c,fractions)
  % Reanchor each lead scattering matrix in the same empty inter-row strip.
  sides={'negative','positive'};tab=cell(1,2);
  for side=1:2
    name=sides{side};s=l.(name);L=c.model.(['L_',name]);step=L;
    if c.model.staggered,step=L/2;end
    n=size(s.R_L,1);I=eye(n);O=zeros(n);vals=[];
    for f=fractions(:).'
      dx=f*step;
      if c.model.staggered,clearance=step/2-.2-abs(dx);
      else,clearance=min([min(s.geometry(1,:))-(-L/2+dx),L/2+dx-max(s.geometry(1,:))]);end
      if clearance<.005,continue;end
      u=exp(1i*l.channels.gamma_m(:)*dx);v=1./u;
      A=[-(v.*s.R_L).*v.',I;(u.*s.T_LR).*v.',O];B=[O,(v.*s.T_RL).*u.';I,-(u.*s.R_R).*u.'];
      if side==1,[A,B]=deal(B,A);end
      [S,T,~,Z]=qz(A,B,'complex');mask=abs(diag(S))<abs(diag(T));
      if sum(mask)~=n,continue;end
      [~,~,~,Z]=ordqz(S,T,eye(2*n),Z,mask);D=Z(1:n,1:n)+Z(n+1:end,1:n);
      vals(end+1,:)=[dx,min(svd(D)),rcond(D)];
    end
    tab{side}=vals;
  end
end
