function result = preflight_i32v2_oracles(certificate_path)
%PREFLIGHT_I32V2_ORACLES Run the mandatory manufactured e-cap-v2 oracles.
% Purpose:
%   Qualify the production rectangular Kress, interpolated MFS circle
%   regular action, and public wall-self action before any formal attempt.
% Input:
%   certificate_path - explicit frozen certificate used to authorize the
%                      production MFS module and physical parameters.
% Output:
%   result - Compact oracle defects, gates, resources, and forbidden-path
%            counters.  This function writes no files.
% Main algorithm:
%   (1) Compare square N=256 S,D,D*,T_out-T_in matrices with the active
%       package Kress assembly.
%   (2) At circle Ns=512/1024 and Nt=1024, compare the actual 257-table
%       interpolated regular T action for modes -8:8 with an independent
%       analytic contraction of the production MFS proxy sources.
%   (3) At wall Ns=512 and 4096, Nt=1024, compare the public production
%       value/normal action for modes -4:4 and test all registered gauge,
%       phase, midpoint, Nyquist, jump, and recombination identities.
% Notes:
%   No image sum, Rayleigh field, output directory, or density solve is used.
%   The actual certificate is identity/type input only; analytic test
%   densities remain independent manufactured oracle data.

  timer=tic;
  result=struct('schema','I32V2_MANDATORY_PREFLIGHT_V1', ...
    'status','INITIALIZED','available',false,'pass',false, ...
    'first_blocker','','warnings',{{}},'square',struct(), ...
    'circle',struct(),'wall',struct(),'audit',struct(),'resources',struct());
  try
    cfg=i32v2_config();
    raw=i32v2_certificate_input(certificate_path,cfg);
    if ~raw.available
      error('I32V2:PreflightCertificate','%s',raw.first_blocker);
    end
    [view,view_audit]=i32v2_computation_view(raw.data,cfg);
    z=view.data.certificate;
    resource=struct('start_tic',tic,'soft_s',cfg.resource.soft_s, ...
      'hard_s',cfg.resource.hard_s,'memory_mib_max',cfg.resource.memory_mib_max, ...
      'retained_mib',0,'cow_mib',0,'publication_mib',0);

    % --- stage 1: package square-grid Kress oracle ---
    square_tic=tic;
    result.square=LOCAL_square_oracle(z);
    result.square.elapsed_s=toc(square_tic);

    % --- stage 2: production MFS tables and independent proxy ---
    gqp_tic=tic;
    g=i32v2_gqp_module(view,cfg,resource);
    if ~g.available
      error('I32V2:PreflightGQP','Production GQP tables are unavailable: %s.', ...
        g.first_blocker);
    end
    pars=struct('d',z.d,'beta',z.beta,'k',z.khat);
    tuple=cfg.gqp_production;
    spec=struct('H',cfg.gqp_H,'proxy_dist',cfg.gqp_proxy_dist, ...
      'N_side',tuple(1),'N_top',tuple(2), ...
      'N_proxy_edge',tuple(3),'M_pw',tuple(4));
    proxy=kernel.precomp_proxy(pars,spec);
    result.resources.gqp_setup_s=toc(gqp_tic);
    result.resources.gqp_retained_mib=g.memory.retained_mib;

    % --- stage 3: mismatched circle actual/direct MFS oracle ---
    circle_tic=tic;
    result.circle=LOCAL_circle_oracle(g,proxy,z);
    result.circle.elapsed_s=toc(circle_tic);

    % --- stage 4: wall source-refinement and convention oracles ---
    wall_tic=tic;
    result.wall=LOCAL_wall_oracle(g,z);
    result.wall.elapsed_s=toc(wall_tic);

    result.audit.symbol_ledger=struct( ...
      'square_maximum','maximum package/v2 square Kress matrix defect', ...
      'circle_action_defect','constituent-scaled interpolated/direct MFS T defect', ...
      'circle_source_change','same-target Ns=512 to Ns=1024 action change', ...
      'wall_source_change','same-target Ns=512 to Ns=4096 value/normal change', ...
      'negative_nyquist_defect','physical-gauge -Ns/2 interpolation defect');
    result.audit.formal_attempt_calls=0;
    result.audit.image_sum_calls=0;
    result.audit.rayleigh_trial_eval_calls=0;
    result.audit.old_ecap_calls=0;
    result.audit.gqp_gateway='i32v2_gqp_pair';
    result.audit.computation_view=view_audit;
    result.audit.direct_circle_reference= ...
      'analytic contraction of production MFS proxy sources; no table interpolation';
    result.pass=result.square.pass&&result.circle.pass&&result.wall.pass;
    result.available=true;
    if result.pass
      result.status='PASS';
    else
      result.status='SCIENTIFIC_GATE_FAILED';
      if ~result.square.pass, result.warnings{end+1}='SQUARE_KRESS_ORACLE_FAILED'; end
      if ~result.circle.pass, result.warnings{end+1}='CIRCLE_MFS_ORACLE_FAILED'; end
      if ~result.wall.pass, result.warnings{end+1}='WALL_ACTION_ORACLE_FAILED'; end
    end
  catch err
    result.status='BLOCKED'; result.available=false;
    result.first_blocker=LOCAL_identifier(err);
    result.audit.exception_message=err.message;
  end
  result.resources.elapsed_s=toc(timer);
end

%% ==================== Square free-space Kress oracle ====================
% The v2 transcription and active package use independently formed splits.

function out=LOCAL_square_oracle(z)
  N=256; R=z.R; ko=z.khat; ki=z.khat*sqrt(z.rho_disk);
  [t,D]=utils.triginterp(N); h=2*pi/N;
  geometry=struct('z',[R*cos(t),R*sin(t)], ...
    'zp',[-R*sin(t),R*cos(t)],'zpp',[-R*cos(t),-R*sin(t)], ...
    'speed',R*ones(N,1));
  Rw=i32v2_rect_kress_weights(t,t);
  [L1,L2,Ls1,Ls2]=kernel.kress_l_splits(ko,t,geometry);
  [M1,M2,N1,N2]=kernel.kress_mn_splits(ko,t,geometry);
  package.S=Rw.*M1+h*M2;
  package.D=Rw.*L1+h*L2;
  package.Dstar=Rw.*Ls1+h*Ls2;
  [Mi1,Mi2,Ni1,Ni2]=kernel.kress_mn_splits(ki,t,geometry);
  tangent=(geometry.zp*geometry.zp.')/(R^2);
  package.Tdiff=(Rw.*(ko^2*M1-ki^2*Mi1)+ ...
    h*(ko^2*M2-ki^2*Mi2)).*tangent ...
    +(Rw.*(N1-Ni1)+h*(N2-Ni2))/R*D;

  identity=eye(N); zero=complex(zeros(N,N));
  [~,~,~,blocks]=i32v2_circle_free_action( ...
    ko,ki,R,t,t,Rw,identity,zero,D);
  literal=struct('S',blocks.S_out,'D',blocks.D_out, ...
    'Dstar',blocks.Dstar_out,'Tdiff',blocks.Tdiff);
  names={'S','D','Dstar','Tdiff'}; defects=struct(); maximum=0;
  for j=1:numel(names)
    name=names{j};
    defects.(name)=LOCAL_relative(literal.(name),package.(name));
    maximum=max(maximum,defects.(name));
  end
  out=struct('N',N,'defects',defects,'maximum_relative',maximum, ...
    'threshold',1e-12,'pass',maximum<=1e-12);
end

%% ==================== Mismatched circle MFS oracle ====================
% The direct reference contracts proxy sources analytically outside the circle.

function out=LOCAL_circle_oracle(g,proxy,z)
  modes=-8:8; Nt=1024;
  actual512=LOCAL_circle_interp_action(g,z,512,Nt,modes);
  actual1024=LOCAL_circle_interp_action(g,z,1024,Nt,modes);
  regular_direct=LOCAL_circle_proxy_action(proxy,z,Nt,modes);
  theta=2*pi*((0:Nt-1)'+0.5)/Nt;
  free=complex(zeros(Nt,numel(modes)));
  for j=1:numel(modes)
    ell=modes(j);
    free(:,j)=(LOCAL_tmode(ell,z.khat,z.R) ...
      -LOCAL_tmode(ell,z.khat*sqrt(z.rho_disk),z.R))*exp(1i*ell*theta);
  end
  reference=free+regular_direct;
  full512=free+actual512; full1024=free+actual1024;
  defects=zeros(numel(modes),1); changes=defects;
  for j=1:numel(modes)
    scale=norm(free(:,j))+norm(regular_direct(:,j));
    defects(j)=norm(full512(:,j)-reference(:,j))/max(scale,realmin);
    changes(j)=norm(full1024(:,j)-full512(:,j))/max(scale,realmin);
  end
  out=struct('source_nodes',[512 1024],'target_nodes',Nt,'modes',modes, ...
    'constituent_scaled_defects',defects, ...
    'source_512_to_1024_changes',changes, ...
    'maximum_action_defect',max(defects), ...
    'maximum_source_change',max(changes),'threshold',0.20, ...
    'pass',max([defects;changes])<=0.20, ...
    'direct_reference','analytic production-proxy contraction');
end

function action=LOCAL_circle_interp_action(g,z,Ns,Nt,modes)
  theta_s=2*pi*((0:Ns-1)'+0.5)/Ns;
  theta_t=2*pi*((0:Nt-1)'+0.5)/Nt;
  src=z.R*[cos(theta_s).';sin(theta_s).'];
  trg=z.R*[cos(theta_t).';sin(theta_t).'];
  source_normal=[cos(theta_s).';sin(theta_s).'];
  target_normal=[cos(theta_t).';sin(theta_t).'];
  density=exp(1i*theta_s*modes); ds=2*pi*z.R/Ns;
  action=complex(zeros(Nt,numel(modes)));
  level=struct('n',257,'include_primary',false);
  for target_first=1:128:Nt
    target_last=min(Nt,target_first+127); targets=target_first:target_last;
    for source_first=1:128:Ns
      source_last=min(Ns,source_first+127); sources=source_first:source_last;
      [~,normal]=i32v2_circle_proxy_action(g,src(:,sources), ...
        trg(:,targets),source_normal(:,sources),target_normal(:,targets), ...
        density(sources,:),complex(zeros(numel(sources),numel(modes))), ...
        ds,level,0,numel(sources));
      action(targets,:)=action(targets,:)+normal;
    end
  end
end

function action=LOCAL_circle_proxy_action(proxy,z,Nt,modes)
  theta=2*pi*((0:Nt-1)'+0.5)/Nt;
  target_comp=[z.R*sin(theta),z.R*cos(theta)];
  normal_comp=[sin(theta),cos(theta)];
  q=proxy.q(:).'; Z=proxy.Z; action=complex(zeros(Nt,numel(modes)));
  x=target_comp(:,1)-Z(1,:); y=target_comp(:,2)-Z(2,:);
  radius=hypot(x,y); angle=atan2(y,x);
  radial_dot=(x.*normal_comp(:,1)+y.*normal_comp(:,2))./radius;
  angular_dot=(-y.*normal_comp(:,1)+x.*normal_comp(:,2))./radius;
  for j=1:numel(modes)
    ell=modes(j); m=-ell; argument=z.khat*radius;
    jp=(besselj(m-1,z.khat*z.R)-besselj(m+1,z.khat*z.R))/2;
    hp=(besselh(m-1,1,argument)-besselh(m+1,1,argument))/2;
    h=besselh(m,1,argument); angular=exp(1i*m*angle);
    derivative=(z.khat*hp.*radial_dot ...
      +(1i*m./radius).*h.*angular_dot).*angular;
    coefficient=exp(1i*ell*pi/2)*1i*pi*z.khat*z.R*jp/2;
    action(:,j)=coefficient*(derivative*q.');
  end
end

function value=LOCAL_tmode(ell,k,R)
  argument=k*R;
  jp=(besselj(ell-1,argument)-besselj(ell+1,argument))/2;
  hp=(besselh(ell-1,1,argument)-besselh(ell+1,1,argument))/2;
  value=1i*pi*k^2*R*jp*hp/2;
end

%% ==================== Wall action and convention oracles ====================
% The reference changes only source quadrature of the same density interpolant.

function out=LOCAL_wall_oracle(g,z)
  modes=-4:4; Nt=1024;
  ytarget=-z.d/2+z.d*((0:Nt-1)'+0.5)/Nt;
  coarse=LOCAL_wall_modes(g,z,512,ytarget,modes);
  reference=LOCAL_wall_modes(g,z,4096,ytarget,modes);
  value_change=LOCAL_column_relative(coarse.value,reference.value);
  normal_change=LOCAL_column_relative(coarse.flux,reference.flux);

  ysmall=-0.47+0.94*((0:32)'+1/3)/33;
  base=LOCAL_wall_modes(g,z,512,ysmall,modes);
  shifted=LOCAL_wall_modes(g,z,512,ysmall+z.d,modes);
  phase=exp(1i*z.beta*z.d);
  phase_defect=max(LOCAL_column_relative(shifted.value,phase*base.value));
  phase_defect=max(phase_defect, ...
    max(LOCAL_column_relative(shifted.flux,phase*base.flux)));
  gauge_defect=max(LOCAL_column_relative( ...
    bsxfun(@times,exp(-1i*z.beta*(ysmall+z.d)),shifted.value), ...
    bsxfun(@times,exp(-1i*z.beta*ysmall),base.value)));

  expected=exp(1i*ysmall*(z.beta+2*pi*modes/z.d))/sqrt(z.d);
  recovered=2*(base.flux-base.kernel_flux);
  midpoint_origin=max(LOCAL_column_relative(recovered,expected));
  jump=max(LOCAL_column_relative(base.flux-base.kernel_flux,0.5*expected));

  nyquist=-256; negative=LOCAL_wall_modes(g,z,512,ysmall,nyquist);
  expected_nyquist=exp(1i*(z.beta+2*pi*nyquist/z.d)*ysmall)/sqrt(z.d);
  negative_nyquist=max(LOCAL_column_relative( ...
    2*(negative.flux-negative.kernel_flux),expected_nyquist));
  recombination=max([coarse.recombination,reference.recombination, ...
    base.recombination,shifted.recombination,negative.recombination]);
  convention=[phase_defect,gauge_defect,midpoint_origin,jump,negative_nyquist];
  out=struct('source_nodes',[512 4096],'target_nodes',Nt,'modes',modes, ...
    'value_source_changes',value_change,'normal_source_changes',normal_change, ...
    'maximum_value_change',max(value_change), ...
    'maximum_normal_change',max(normal_change), ...
    'phase_seam_defect',phase_defect,'gauge_seam_defect',gauge_defect, ...
    'midpoint_origin_defect',midpoint_origin,'jump_defect',jump, ...
    'negative_nyquist_defect',negative_nyquist, ...
    'recombination_defect',recombination, ...
    'refinement_threshold',0.20,'convention_threshold',1e-10, ...
    'recombination_threshold',1e-12, ...
    'pass',max([value_change;normal_change])<=0.20 ...
      &&max(convention)<=1e-10&&recombination<=1e-12);
end

function out=LOCAL_wall_modes(g,z,Ns,ytarget,modes)
  ysource=-z.d/2+z.d*((0:Ns-1)'+0.5)/Ns;
  density=exp(1i*ysource*(z.beta+2*pi*modes/z.d))/sqrt(z.d);
  Nt=numel(ytarget); columns=numel(modes);
  out.value=complex(zeros(Nt,columns)); out.flux=out.value;
  out.kernel_flux=out.value; out.recombination=0;
  level=struct('n',257,'include_primary',false);
  for first=1:128:Nt
    last=min(Nt,first+127); targets=first:last;
    [value,flux,kernel_flux,recombination]=i32v2_wall_self_action( ...
      z,g,ysource,ytarget(targets),density,0,1,level,0);
    out.value(targets,:)=value; out.flux(targets,:)=flux;
    out.kernel_flux(targets,:)=kernel_flux;
    out.recombination=max(out.recombination,recombination);
  end
end

function values=LOCAL_column_relative(actual,reference)
  columns=size(actual,2); values=zeros(columns,1);
  for j=1:columns
    values(j)=norm(actual(:,j)-reference(:,j)) ...
      /max([norm(actual(:,j)),norm(reference(:,j)),realmin]);
  end
end

%% ==================== Shared inputs and scalar diagnostics ====================
% Scalar diagnostics use only the authenticated frozen physical parameters.

function value=LOCAL_relative(actual,reference)
  value=norm(actual-reference,'fro') ...
    /max([norm(actual,'fro'),norm(reference,'fro'),realmin]);
end

function id=LOCAL_identifier(err)
  id=err.identifier;
  if isempty(id), id='I32V2:UNIDENTIFIED_BLOCKER'; end
end
