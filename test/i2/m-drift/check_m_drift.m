function result = check_m_drift(attempt)
%CHECK_M_DRIFT Run the frozen I2.3 Rayleigh/Fourier-cutoff experiment.
% Purpose:
%   Compare saved real-axis candidates at M = 32, 40, and 48 while ntot,
%   proxy, physics, solver, window, locator, and candidate functional stay fixed.
% Input:
%   attempt - Append-only output tag; the Revision A tag is 'm-drift-a2'.
% Output:
%   result  - Compact seed, gauge, locator, candidate, mode, repeat, and drift data.
% Main algorithm:
%   Build an independent eval_i21 seed/frame for each M, verify a frozen
%   selector-order gauge oracle, run the same bounded locator, map modes into
%   common M=48 coefficient/wall/probe spaces, and compare saved candidates.
% Based on:
%   test/i2/k-drift/check_k_drift.m and eval_i21.m.
% Main changes:
%   Fix ntot=160, vary only M with K=2M+1, and compare different dimensions
%   through zero-padded physical representations rather than raw matrices.
% Numerical goal:
%   Record direct same-mode saved-candidate drift; no minimizer, root,
%   convergence, estimator, or error-bound claim is made.

  if nargin ~= 1 || ~strcmp(char(attempt),'m-drift-a2')
    error('i23m:Attempt','The reviewed attempt name is m-drift-a2.');
  end
  here = fileparts(mfilename('fullpath'));
  output = fullfile(here,'output',char(attempt));
  if exist(output,'dir') || exist(output,'file')
    error('i23m:OutputExists','Output already exists: %s.',output);
  end

  timer = tic; c = LOCAL_config(); LOCAL_config_gate(c);
  runtime = struct(); oracle = struct();
  seeds = cell(1,3); gauges = cell(1,3); locators = cell(1,3);
  candidates = cell(1,3); repeats = cell(1,3);
  identities = cell(1,3); drifts = cell(1,3);
  common = struct();
  first_failure = LOCAL_failure('NONE','NONE',NaN,NaN,'','');
  peak_mib = 0; execution_pass = false; hierarchy_qualified = false;
  i3_may_proceed = false; trend = 'UNAVAILABLE';
  scientific_outcome = 'UNAVAILABLE'; i3_status = 'STOP_EXECUTION_UNAVAILABLE';

  try
    runtime = LOCAL_runtime(); oracle = LOCAL_identity_oracle(c);
    if ~oracle.pass
      error('i23m:IdentityOracle','The phase/scale identity oracle failed.');
    end

    % --- stage 1: independently seed, gauge, locate, and repeat each M ---
    for j = 1:3
      M = c.M_levels(j); lc = LOCAL_level_config(c,M);
      [rows,alternate] = LOCAL_selectors(M);
      [seed,frame] = eval_i21('seed',lc,rows);
      LOCAL_node_gate(seed,lc.kstar,frame,lc);
      score = LOCAL_score(seed);
      gauges{j} = LOCAL_gauge(seed,alternate,lc);
      seeds{j} = LOCAL_seed_summary(seed,score,rows,alternate,gauges{j});
      retained = {candidates,repeats,gauges};
      peak_mib = max(peak_mib,LOCAL_mib(seed,frame,retained));
      LOCAL_resource_gate(timer,peak_mib,c);
      if ~gauges{j}.pass
        scientific_outcome = 'SELECTOR_GAUGE_DRIFT';
        first_failure = LOCAL_failure('SELECTOR_GAUGE_DRIFT','SEED_GAUGE', ...
          M,lc.kstar,'The seed selector-order gauge oracle failed.','');
        break;
      end
      [locators{j},candidates{j},level_peak] = ...
        LOCAL_locate(lc,frame,seed,timer,retained);
      peak_mib = max(peak_mib,level_peak);
      if ~locators{j}.pass
        scientific_outcome = 'CANDIDATE_UNRESOLVED';
        first_failure = locators{j}.first_failure; break;
      end
      [repeats{j},repeat_peak] = ...
        LOCAL_repeat(candidates{j},lc,frame,seed,timer, ...
          {candidates,repeats,gauges});
      peak_mib = max(peak_mib,repeat_peak);
      if ~repeats{j}.pass
        scientific_outcome = 'CANDIDATE_UNRESOLVED';
        first_failure = repeats{j}.first_failure; break;
      end
      clear seed frame
    end

    % --- stage 2: verify common proxy and shared Fourier-channel values ---
    if strcmp(scientific_outcome,'UNAVAILABLE')
      common = LOCAL_common_gate(seeds,locators,c);
      if ~common.pass
        scientific_outcome = 'COMMON_REPRESENTATION_DRIFT';
        first_failure = LOCAL_failure('COMMON_REPRESENTATION_DRIFT', ...
          'COMMON_CHANNELS',NaN,NaN,common.message,'');
      end
    end

    % --- stage 3: compare common balanced-port, wall, and probe modes ---
    if strcmp(scientific_outcome,'UNAVAILABLE')
      identities{1} = LOCAL_identity(candidates{1},candidates{2},c,true);
      identities{2} = LOCAL_identity(candidates{2},candidates{3},c,true);
      identities{3} = LOCAL_identity(candidates{1},candidates{3},c,false);
      if ~(identities{1}.pass && identities{2}.pass)
        if strcmp(identities{1}.status,'MODE_SWITCH') || ...
            strcmp(identities{2}.status,'MODE_SWITCH')
          scientific_outcome = 'MODE_SWITCH'; code = 'MODE_SWITCH';
        else
          scientific_outcome = 'MODE_IDENTITY_UNRESOLVED';
          code = 'MODE_IDENTITY_UNRESOLVED';
        end
        first_failure = LOCAL_failure(code,'MODE_IDENTITY',NaN,NaN, ...
          'An adjacent common-representation identity gate failed.','');
      end
    end

    % --- stage 4: classify direct saved-candidate differences ---
    if strcmp(scientific_outcome,'UNAVAILABLE')
      drifts{1} = LOCAL_drift(candidates{1},candidates{2},c);
      drifts{2} = LOCAL_drift(candidates{2},candidates{3},c);
      drifts{3} = LOCAL_drift(candidates{1},candidates{3},c);
      trend = LOCAL_trend(drifts{1},drifts{2});
      hierarchy_qualified = true; i3_may_proceed = true;
      i3_status = 'MAY_PROCEED_WITH_CONDITIONAL_M_AXIS_HIERARCHY';
      labels = cellfun(@(x) x.classification,drifts,'UniformOutput',false);
      if all(strcmp(labels,'NO_OBSERVED_CANDIDATE_DRIFT'))
        scientific_outcome = 'NO_OBSERVED_CANDIDATE_DRIFT';
      elseif any(strcmp(labels,'OBSERVED_CANDIDATE_DRIFT_SEVERE'))
        scientific_outcome = 'OBSERVED_CANDIDATE_DRIFT_SEVERE';
      else
        scientific_outcome = 'OBSERVED_CANDIDATE_DRIFT_SUBTARGET';
      end
    end
    execution_pass = true;
  catch ME
    [code,stage] = LOCAL_exception_class(ME);
    scientific_outcome = 'EXECUTION_UNAVAILABLE';
    first_failure = LOCAL_failure(code,stage,NaN,NaN,ME.message,ME.identifier);
    hierarchy_qualified = false; i3_may_proceed = false;
    i3_status = 'STOP_EXECUTION_UNAVAILABLE'; trend = 'UNAVAILABLE';
  end

  elapsed = toc(timer);
  if execution_pass && elapsed > c.hard_seconds
    execution_pass = false; scientific_outcome = 'EXECUTION_UNAVAILABLE';
    hierarchy_qualified = false; i3_may_proceed = false;
    i3_status = 'STOP_HARD_TIME'; trend = 'UNAVAILABLE';
    first_failure = LOCAL_failure('HARD_TIME','RESOURCE',NaN,NaN, ...
      'The runner exceeded its hard wall-time limit.','i23m:HARD_TIME');
  end
  status = ['I2_3_M_',scientific_outcome];
  result = LOCAL_result(char(attempt),status,execution_pass, ...
    scientific_outcome,hierarchy_qualified,i3_may_proceed,i3_status, ...
    trend,elapsed,peak_mib,c,runtime,oracle,seeds,gauges,locators, ...
    candidates,repeats,identities,drifts,common,first_failure);

  if exist(output,'dir') || exist(output,'file')
    error('i23m:OutputExists','Output appeared during the run: %s.',output);
  end
  mkdir(output);
  save(fullfile(output,'result.mat'),'result','-v7');
  LOCAL_report(fullfile(output,'report.md'),result);
end

%% ==================== Frozen configuration ====================
% These helpers hold the sole M axis, derived dimensions, selectors, and runtime.

function c = LOCAL_config()
  c = struct('schema','TEP_I2_3_M_DRIFT_V1', ...
    'experiment_id','I2-M-DRIFT-V1','design_id','I2.3-M-DRIFT-V1', ...
    'claim_boundary','CONDITIONAL_EMPIRICAL_THREE_LEVEL_SAVED_CANDIDATE_DRIFT', ...
    'axis','PORT_RAYLEIGH_FOURIER_CUTOFF_M_AT_FIXED_NTOT160_FINE_PROXY', ...
    'beta',0.5,'d',1.0,'R',0.2,'s',1.0,'X_L',-0.5,'X_R',0.5, ...
    'H',1.1,'proxy_dist',0.2,'M_levels',[32,40,48], ...
    'K_levels',[65,81,97],'M_max',48, ...
    'kstar',1.8327703475952146,'r0',3.8146972647368216e-7, ...
    'locator_max_layer',11,'locator_spacing_max',1e-10, ...
    'score_tie_min',1e-12,'score_max',1e-3,'r12_max',0.1, ...
    'raw_backward_max',1e-8,'identity_overlap_min',0.99, ...
    'competitor_overlap_max',0.5,'participation_min',1e-3, ...
    'repeat_matrix_max',1e-12,'repeat_score_max',1e-12, ...
    'repeat_overlap_min',1-1e-10,'gauge_matrix_max',1e-12, ...
    'gauge_score_max',1e-12,'gauge_overlap_min',1-1e-10, ...
    'common_channel_tol',1e-12,'severity_scale',1e-6, ...
    'target_seconds',600,'hard_seconds',1200,'memory_mib_max',512);
  c.level = struct('name','fine','ntot',160,'N_side',160,'N_top',160, ...
    'N_proxy_edge',80,'M_pw',32);
  c.expected = struct('proxy_rank',260,'proxy_shape',[960,450], ...
    'proxy_shifted_shape',[1920,450],'Aqp_shape',[320,320]);
  [px,py] = ndgrid([-0.25,0,0.25],[-0.25,0,0.25]);
  c.probe_x = px(:); c.probe_y = py(:);
  c.proxy_rank_ratio=1e-8; c.proxy_rank_gap_min=2;
  c.proxy_projector_repeat_tol=1e-10; c.proxy_rcond_min=1e-8;
  c.proxy_projected_tol=1e-11; c.proxy_full_residual_max=1e-5;
  c.proxy_shifted_residual_max=1e-5; c.proxy_seed_identity_tol=1e-12;
  c.branch_tol=1e-12; c.qz_residual_tol=1e-10; c.qz_overlap_min=0.9;
  c.chart_condition_eps_tol=1e-9; c.bie_rcond_min=1e-8;
  c.bie_residual_tol=1e-10; c.dirichlet_rcond_min=1e-8;
  c.lift_residual_tol=1e-10;
  saved=repmat(struct('M',NaN,'K',NaN,'ntot',NaN, ...
    'cross_cluster_margin_min',NaN,'chart_margin_min',NaN, ...
    'small_solve_residual_tol',NaN,'schur_tol',NaN, ...
    'svd_residual_max',NaN),1,numel(c.M_levels));
  for j=1:numel(c.M_levels)
    lc=LOCAL_level_config(c,c.M_levels(j));
    saved(j)=struct('M',lc.M,'K',lc.K,'ntot',lc.level.ntot, ...
      'cross_cluster_margin_min',lc.cross_cluster_margin_min, ...
      'chart_margin_min',lc.chart_margin_min, ...
      'small_solve_residual_tol',lc.small_solve_residual_tol, ...
      'schur_tol',lc.schur_tol,'svd_residual_max',lc.svd_residual_max);
  end
  c.level_threshold_configs=saved;
end

function out = LOCAL_level_config(c,M)
  out = c; out.M = M; out.K = 2*M+1;
  out.cross_cluster_margin_min = 100*out.K*eps;
  out.chart_margin_min = 100*out.K*eps;
  out.small_solve_residual_tol = 1e3*out.K*eps;
  out.schur_tol = 1e3*out.K*eps;
  out.svd_residual_max = 1e3*(2*out.K)*eps;
end

function LOCAL_config_gate(c)
  ok = isequal(c.M_levels,[32,40,48]) && isequal(c.K_levels,[65,81,97]) && ...
    c.level.ntot == 160 && ...
    c.level.N_side == 160 && c.level.N_top == 160 && ...
    c.level.N_proxy_edge == 80 && c.level.M_pw == 32 && ...
    c.locator_max_layer == 11 && c.r0/2/2^11 <= 1e-10 && ...
    c.r0/2/2^10 > 1e-10 && numel(c.probe_x) == 9;
  for j=1:numel(c.M_levels)
    M=c.M_levels(j); saved=c.level_threshold_configs(j);
    [rows,alt] = LOCAL_selectors(M); K = 2*M+1;
    ok = ok && isequal(rows.plus,1:K) && isequal(rows.minus,K+1:2*K) && ...
      isequal(sort(alt.plus),1:K) && isequal(sort(alt.minus),K+1:2*K) && ...
      ~isequal(rows.plus,alt.plus) && ~isequal(rows.minus,alt.minus) && ...
      saved.M==M && saved.K==K && saved.ntot==160 && ...
      saved.cross_cluster_margin_min==100*K*eps && ...
      saved.chart_margin_min==100*K*eps && ...
      saved.small_solve_residual_tol==1e3*K*eps && ...
      saved.schur_tol==1e3*K*eps && ...
      saved.svd_residual_max==1e3*(2*K)*eps;
  end
  if ~ok, error('i23m:Config','The frozen M-axis configuration failed.'); end
end

function [rows,alternate] = LOCAL_selectors(M)
  plus48 = [89 41 35 71 92 12 16 10 66 70 93 33 9 69 79 30 36 ...
    62 64 84 95 40 18 91 94 58 61 13 85 90 24 32 42 60 28 74 21 ...
    97 22 55 77 96 38 14 17 2 20 1 67 75 37 43 72 5 80 81 82 7 ...
    68 39 25 19 78 29 6 76 86 59 8 4 65 83 23 31 3 73 57 63 56 ...
    26 88 27 11 87 15 34 54 44 53 45 52 46 51 47 50 48 49];
  minus48 = [162 132 117 174 103 124 134 140 173 194 101 172 186 ...
    120 167 168 170 178 189 100 153 180 192 110 118 121 125 169 175 ...
    176 185 119 160 164 179 108 113 114 131 165 171 183 193 111 128 ...
    133 139 159 181 190 191 106 129 157 163 135 116 127 155 177 102 ...
    104 126 130 137 156 184 109 138 187 115 136 154 161 166 158 123 ...
    98 122 105 188 112 152 99 182 107 151 141 150 142 149 143 148 ...
    144 147 145 146];
  K = 2*M+1; rows = struct('plus',1:K,'minus',K+1:2*K);
  mp = plus48-49; mp = mp(abs(mp)<=M);
  mm = minus48-146; mm = mm(abs(mm)<=M);
  alternate = struct('plus',mp+M+1,'minus',K+mm+M+1);
end

function runtime = LOCAL_runtime()
  names = {'eval_i21','i21_kproxy','kproxy','kchan','kgreen','kbie', ...
    'geom.construct_cont','bloch.incident_rhs','bloch.farfield_extractors', ...
    'kernel.h2d_directch','kernel.kress_l_splits','kernel.kress_mn_splits', ...
    'utils.triginterp','quad.quad_kress_rvec'};
  resolved = repmat(struct('name','','path',''),numel(names),1);
  for j = 1:numel(names)
    matches = which(names{j},'-all');
    if ischar(matches), matches = cellstr(matches); end
    if numel(matches) ~= 1
      error('i23m:Runtime','Exactly one %s must be on the MATLAB path.',names{j});
    end
    resolved(j) = struct('name',names{j},'path',matches{1});
  end
  solver = which('lsqminnorm');
  if exist('OCTAVE_VERSION','builtin') ~= 0 || isempty(solver) || ...
      ~startsWith(solver,matlabroot) || ~strcmp(class(1.0),'double')
    error('i23m:Runtime','Public MATLAB lsqminnorm and double are required.');
  end
  runtime = struct('kind','MATLAB','version',version,'solver','lsqminnorm', ...
    'solver_path',solver,'resolved_functions',resolved,'precision','double', ...
    'pinv_calls',0,'fallbacks',0,'silent_rank_truncations',0, ...
    'method_switches',0,'reads_git_docs_history_or_hashes',false);
end

%% ==================== Seed gauge oracle ====================
% These helpers recompute one seed object under a frozen alternate row order.

function gauge = LOCAL_gauge(seed,alternate,c)
  [Zp,fp] = LOCAL_alt_normalize(seed.plus.Z,alternate.plus,c,'alt_plus');
  [Zm,fm] = LOCAL_alt_normalize(seed.minus.Z,alternate.minus,c,'alt_minus');
  factors = [fp;fm];
  gauge = struct('pass',false,'M',c.M,'alternate_selectors',alternate, ...
    'matrix_relative_difference',Inf,'score_difference',Inf, ...
    'raw_q_overlap',NaN,'wall_overlap',NaN,'probe_overlap',NaN, ...
    'factors',factors);
  if ~(fp.pass && fm.pass), return; end
  K=c.K; Gamma=diag(seed.gamma); E=diag(seed.phase);
  Ap=Zp(1:K,:); Bp=Zp(K+1:end,:); Am=Zm(1:K,:); Bm=Zm(K+1:end,:);
  Dp=Ap+Bp; Np=1i*Gamma*(Ap-Bp); Dm=Am+Bm; Nm=-1i*Gamma*(Am-Bm);
  [Lp,cp] = LOCAL_alt_chart(Dp,Np,seed.beta_m,c,'alt_dtn_plus');
  [Lm,cm] = LOCAL_alt_chart(Dm,Nm,seed.beta_m,c,'alt_dtn_minus');
  factors = [factors;cp;cm]; gauge.factors = factors;
  if ~(cp.pass && cm.pass), return; end
  Aalt = [-(1i*Gamma+Lm),(1i*Gamma-Lm)*E; ...
    (1i*Gamma-Lp)*E,-(1i*Gamma+Lp)];
  [B0,~,wc] = LOCAL_physical_matrix(seed);
  [Ba,~,~] = LOCAL_physical_matrix_from(Aalt,seed.beta_m,seed.gamma);
  [~,S0,V0]=svd(B0,'econ'); [~,Sa,Va]=svd(Ba,'econ');
  s0=flipud(diag(S0)); sa=flipud(diag(Sa));
  q0=wc.*V0(:,end); qa=wc.*Va(:,end);
  m0=LOCAL_mode(q0,V0(:,end),seed,c); ma=LOCAL_mode(qa,Va(:,end),seed,c);
  [rq,aq]=LOCAL_overlap(q0,qa,0,0); [rt,at]=LOCAL_overlap( ...
    m0.weighted_wall_trace,ma.weighted_wall_trace,0,0);
  [rf,af]=LOCAL_overlap(m0.probe_field,ma.probe_field,0,0);
  matrix_difference=norm(Aalt-seed.AdefD,'fro')/max(1,norm(seed.AdefD,'fro'));
  score_difference=abs(sa(1)/sa(end)-s0(1)/s0(end));
  pass=all([factors.pass]) && matrix_difference<=c.gauge_matrix_max && ...
    score_difference<=c.gauge_score_max && aq && at && af && ...
    min([rq,rt,rf])>=c.gauge_overlap_min;
  gauge = struct('pass',pass,'M',c.M,'alternate_selectors',alternate, ...
    'AdefD',Aalt,'singular_values',sa,'matrix_relative_difference', ...
    matrix_difference,'score_difference',score_difference, ...
    'raw_q_overlap',rq,'wall_overlap',rt,'probe_overlap',rf,'factors',factors);
end

function [Zhat,factor] = LOCAL_alt_normalize(Z,rows,c,name)
  H=Z(rows,:); singular=svd(H,'econ'); margin=min(singular);
  condition=max(singular)/max(realmin,margin); rv=rcond(H); Zhat=[]; residual=Inf;
  pre=all(isfinite(H(:))) && margin>c.chart_margin_min && ...
    condition*eps<=c.chart_condition_eps_tol && isfinite(rv) && ...
    rv>=eps/c.chart_condition_eps_tol;
  if pre
    Zhat=(H.'\Z.').';
    residual=norm(Zhat(rows,:)-eye(c.K),'fro')/max(1,sqrt(c.K));
  end
  pass=pre && all(isfinite(Zhat(:))) && residual<=c.small_solve_residual_tol;
  factor=LOCAL_factor(name,rv,residual,pass,eps/c.chart_condition_eps_tol, ...
    c.small_solve_residual_tol,margin,condition);
end

function [Lambda,factor] = LOCAL_alt_chart(D,N,beta_m,c,name)
  b=sqrt(1+abs(beta_m(:)).^2); GDh=diag(sqrt(b));
  gram=D'*diag(b)*D+N'*diag(1./b)*N; gram=(gram+gram')/2;
  [V,L]=eig(gram); values=max(real(diag(L)),0); Lambda=[];
  margin=0; condition=Inf; rv=rcond(D); residual=Inf; pre=min(values)>0;
  if pre
    half=V*diag(sqrt(values))*V'; Dbar=(half.'\(GDh*D).').';
    singular=svd(Dbar,'econ'); margin=min(singular);
    condition=max(singular)/max(realmin,margin);
    pre=margin>c.chart_margin_min && condition*eps<=c.chart_condition_eps_tol && ...
      isfinite(rv) && rv>=c.dirichlet_rcond_min;
  end
  if pre
    Lambda=(D.'\N.').';
    residual=norm(N-Lambda*D,'fro')/max(1,norm(N,'fro'));
  end
  pass=pre && all(isfinite(Lambda(:))) && residual<=c.small_solve_residual_tol;
  factor=LOCAL_factor(name,rv,residual,pass,c.dirichlet_rcond_min, ...
    c.small_solve_residual_tol,margin,condition);
end

function f = LOCAL_factor(name,rv,residual,available,rmin,rmax,margin,condition)
  f=struct('name',name,'rcond',rv,'residual',residual, ...
    'available',logical(available),'rcond_min',rmin,'residual_max',rmax, ...
    'margin',margin,'condition',condition, ...
    'pass',logical(available)&&rv>=rmin&&residual<=rmax);
end

function oracle = LOCAL_identity_oracle(c)
  e1=[1;0]; e2=[0;1]; big=1e8*exp(1i*pi/7)*e1;
  small=1e-8*exp(-1i*pi/7)*e1;
  [rb,ab]=LOCAL_overlap(e1,big,0,0); [rs,as]=LOCAL_overlap(e1,small,0,0);
  [ro,ao]=LOCAL_overlap(e1,e2,0,0); [~,az]=LOCAL_overlap(e1,zeros(2,1),0,0);
  [~,an]=LOCAL_overlap(e1,[Inf;0],0,0);
  [~,au]=LOCAL_overlap(e1,1e-4*e1,0,c.participation_min);
  pass=ab&&as&&ao&&abs(rb-1)<=1e-14&&abs(rs-1)<=1e-14&&ro<=1e-14&& ...
    ~az&&~an&&~au;
  oracle=struct('scale_large',1e8,'theta_large',pi/7,'scale_small',1e-8, ...
    'theta_small',-pi/7,'large_overlap',rb,'small_overlap',rs, ...
    'orthogonal_overlap',ro,'zero_available',az,'nonfinite_available',an, ...
    'under_threshold_available',au,'pass',pass);
end

%% ==================== Locator and node gates ====================
% These helpers retain required node evidence while keeping five dense nodes.

function [locator,candidate,peak_mib] = LOCAL_locate(c,frame,seed,timer,retained)
  cache=struct('k',{},'node',{},'score',{}); rows=LOCAL_empty_node_rows();
  factors=LOCAL_empty_factor_rows(); layers=struct('layer',{},'interval',{}, ...
    'spacing',{},'k_values',{},'scores',{},'winner_index',{}, ...
    'runner_up_index',{},'winner_score',{},'runner_up_score',{}, ...
    'runner_up_gap',{},'state',{});
  score=LOCAL_score(seed); cache(1)=struct('k',seed.k,'node',seed,'score',score);
  rows(1)=LOCAL_node_summary(seed,score,c); factors=LOCAL_factor_rows(seed,c);
  failure=LOCAL_failure('NONE','NONE',c.M,NaN,'',''); candidate=[]; peak_mib=0;
  interval=[c.kstar-c.r0,c.kstar+c.r0];
  for layer=0:c.locator_max_layer
    LOCAL_resource_gate(timer,peak_mib,c); h=(interval(2)-interval(1))/4;
    kvals=linspace(interval(1),interval(2),5);
    entries=repmat(struct('k',NaN,'node',struct(),'score',struct()),1,5);
    for j=1:5
      index=LOCAL_cache_index(cache,kvals(j));
      if isempty(index)
        try
          node=eval_i21('point',kvals(j),c,frame);
          LOCAL_node_gate(node,kvals(j),frame,c);
        catch ME
          if LOCAL_scientific_exception(ME)
            failure=LOCAL_failure('SCIENTIFIC_NODE_GATE','LOCATOR',c.M, ...
              kvals(j),ME.message,ME.identifier);
            locator=LOCAL_locator_result(false,c,interval,h,rows,factors, ...
              layers,failure,NaN,NaN,NaN,NaN); return;
          end
          rethrow(ME);
        end
        score=LOCAL_score(node); cache(end+1)=struct('k',node.k, ...
          'node',node,'score',score); %#ok<AGROW>
        index=numel(cache); rows(end+1)=LOCAL_node_summary(node,score,c); %#ok<AGROW>
        factors=[factors;LOCAL_factor_rows(node,c)]; %#ok<AGROW>
        peak_mib=max(peak_mib,LOCAL_mib(frame,seed,cache,retained));
        LOCAL_resource_gate(timer,peak_mib,c);
      end
      entries(j)=cache(index);
    end
    values=arrayfun(@(x)x.score.s1,entries); [ordered,order]=sort(values);
    winner=order(1); runner=order(2); gap=ordered(2)-ordered(1);
    if gap<=c.score_tie_min, state='TIE';
    elseif winner==1||winner==5, state='ENDPOINT'; else, state='INTERIOR'; end
    layers(end+1)=struct('layer',layer,'interval',interval,'spacing',h, ...
      'k_values',kvals,'scores',values,'winner_index',winner, ...
      'runner_up_index',runner,'winner_score',ordered(1), ...
      'runner_up_score',ordered(2),'runner_up_gap',gap,'state',state); %#ok<AGROW>
    if ~strcmp(state,'INTERIOR')
      code=['CANDIDATE_',state]; failure=LOCAL_failure(code,'LOCATOR',c.M, ...
        entries(winner).k,'The frozen locator did not have a unique interior winner.','');
      locator=LOCAL_locator_result(false,c,interval,h,rows,factors,layers, ...
        failure,winner,runner,ordered(1),gap); return;
    end
    next=[entries(winner-1).k,entries(winner+1).k];
    if h<=c.locator_spacing_max
      [candidate,code,message]=LOCAL_candidate(entries(winner).node,c,next,h, ...
        layer,ordered(1),ordered(2),gap);
      if ~candidate.pass
        failure=LOCAL_failure(code,'CANDIDATE',c.M,candidate.k,message,'');
        locator=LOCAL_locator_result(false,c,next,h,rows,factors,layers, ...
          failure,winner,runner,ordered(1),gap); return;
      end
      if numel(rows)~=27
        failure=LOCAL_failure('CANDIDATE_UNRESOLVED','LOCATOR',c.M,candidate.k, ...
          'The locator did not evaluate exactly 27 unique nodes.','');
        locator=LOCAL_locator_result(false,c,next,h,rows,factors,layers, ...
          failure,winner,runner,ordered(1),gap); return;
      end
      locator=LOCAL_locator_result(true,c,next,h,rows,factors,layers, ...
        failure,winner,runner,ordered(1),gap); return;
    end
    interval=next; cache=entries(winner-1:winner+1);
  end
  failure=LOCAL_failure('CANDIDATE_UNRESOLVED','LOCATOR',c.M,NaN, ...
    'The locator did not reach the terminal spacing.','');
  locator=LOCAL_locator_result(false,c,interval,NaN,rows,factors,layers, ...
    failure,NaN,NaN,NaN,NaN);
end

function index=LOCAL_cache_index(cache,k)
  index=[]; if isempty(cache), return; end
  index=find(abs([cache.k]-k)<=10*eps(max(1,abs(k))),1);
end

function out=LOCAL_locator_result(pass,c,interval,h,rows,factors,layers, ...
    failure,winner,runner,winner_score,gap)
  runner_score=NaN; if ~isempty(layers), runner_score=layers(end).runner_up_score; end
  out=struct('pass',logical(pass),'M',c.M,'K',c.K, ...
    'terminal_interval',interval,'minimizer_search_halfwidth',h, ...
    'unique_node_count',numel(rows),'node_rows',rows,'factor_rows',factors, ...
    'layers',layers,'terminal_winner_index',winner, ...
    'terminal_runner_up_index',runner,'terminal_winner_score',winner_score, ...
    'terminal_runner_up_score',runner_score,'terminal_runner_up_gap',gap, ...
    'first_failure',failure);
end

function score=LOCAL_score(node)
  B=LOCAL_physical_matrix(node); values=svd(B,'econ'); values=flipud(values(:));
  if numel(values)<2||any(~isfinite(values))||values(end)<=0||values(2)<=0
    error('i23m:ScientificNodeGate','The physical singular spectrum is unavailable.');
  end
  score=struct('s1',values(1)/values(end),'r12',values(1)/values(2), ...
    'sigma1',values(1),'sigma2',values(2),'sigmamax',values(end), ...
    'singular_values',values);
end

function [B,wr,wc]=LOCAL_physical_matrix(node)
  [B,wr,wc]=LOCAL_physical_matrix_from(node.AdefD,node.beta_m,node.gamma);
end

function [B,wr,wc]=LOCAL_physical_matrix_from(A,beta_m,gamma)
  b=sqrt(1+abs(beta_m(:)).^2); wr=repmat(sqrt(1./b),2,1);
  wc=repmat(1./sqrt(b+abs(gamma(:)).^2./b),2,1); B=wr.*A.*wc.';
end

function rows=LOCAL_empty_node_rows()
  rows=struct('M',{},'K',{},'k',{},'s1',{},'r12',{}, ...
    'singular_values',{},'node_pass',{},'factor_pass',{}, ...
    'plus_overlap',{},'minus_overlap',{},'beta_m',{},'gamma',{}, ...
    'phase',{},'elapsed_seconds',{});
end

function row=LOCAL_node_summary(node,score,c)
  row=struct('M',c.M,'K',c.K,'k',node.k,'s1',score.s1,'r12',score.r12, ...
    'singular_values',score.singular_values,'node_pass',logical(node.pass), ...
    'factor_pass',all([node.factors.pass]), ...
    'plus_overlap',LOCAL_field(node.plus,'overlap',1), ...
    'minus_overlap',LOCAL_field(node.minus,'overlap',1), ...
    'beta_m',node.beta_m,'gamma',node.gamma,'phase',node.phase, ...
    'elapsed_seconds',node.elapsed_seconds);
end

function rows=LOCAL_empty_factor_rows()
  rows=struct('M',{},'K',{},'k',{},'name',{},'rcond',{},'residual',{}, ...
    'available',{},'rcond_min',{},'residual_max',{},'pass',{});
end

function rows=LOCAL_factor_rows(node,c)
  rows=LOCAL_empty_factor_rows();
  for j=1:numel(node.factors)
    f=node.factors(j); rows(end+1,1)=struct('M',c.M,'K',c.K,'k',node.k, ...
      'name',f.name,'rcond',f.rcond,'residual',f.residual, ...
      'available',f.available,'rcond_min',f.rcond_min, ...
      'residual_max',f.residual_max,'pass',f.pass); %#ok<AGROW>
  end
end

function LOCAL_node_gate(node,k,frame,c)
  K=c.K; [rows,~]=LOCAL_selectors(c.M);
  expected_beta=c.beta+2*pi*(-c.M:c.M).'/c.d;
  ok=node.k==k&&strcmp(node.name,'fine')&&node.spec.ntot==160&& ...
    node.spec.N_side==160&&node.spec.N_top==160&&node.spec.N_proxy_edge==80&& ...
    node.spec.M_pw==32&&numel(node.beta_m)==K&&node.pass&&node.plus.pass&& ...
    node.minus.pass&&node.plus.stable_diagnostic==K&& ...
    node.plus.unstable_diagnostic==K&&node.minus.stable_diagnostic==K&& ...
    node.minus.unstable_diagnostic==K&&node.plus.neutral_count==0&& ...
    node.minus.neutral_count==0&&node.plus.indeterminate_count==0&& ...
    node.minus.indeterminate_count==0&&node.branch_port.pass&& ...
    node.branch_proxy.pass&&node.cp.safe&&node.cm.safe&& ...
    all([node.factors.available])&&all([node.factors.pass])&& ...
    isequal(node.proxy_shape,c.expected.proxy_shape)&& ...
    isequal(node.proxy_shifted_shape,c.expected.proxy_shifted_shape)&& ...
    isequal(size(node.R),[260,260])&&isequal(size(node.Aqp),[320,320])&& ...
    isequal(size(node.pair.A),[2*K,2*K])&&isequal(size(node.AdefD),[2*K,2*K])&& ...
    isequal(size(node.AdefG),[4*K,4*K])&& ...
    isequal(size(frame.seed_Z_plus),[2*K,K])&& ...
    isequal(size(frame.seed_Z_minus),[2*K,K])&& ...
    isequal(size(frame.Z0_plus),[2*K,K])&&isequal(size(frame.Z0_minus),[2*K,K])&& ...
    isequal(frame.rows_plus,rows.plus)&&isequal(frame.rows_minus,rows.minus)&& ...
    isequal(node.H_plus_rows,rows.plus)&&isequal(node.H_minus_rows,rows.minus)&& ...
    isequal(node.beta_m,expected_beta)&&frame.proxy_chart.r==c.expected.proxy_rank&& ...
    strcmp(node.plus.plane,'LEFT_CELL_WALL')&& ...
    strcmp(node.minus.plane,'RIGHT_CELL_WALL')&& ...
    strcmp(node.branch_port.fingerprint,frame.port_anchor.fingerprint)&& ...
    strcmp(node.branch_proxy.fingerprint,frame.proxy_chart.anchor.fingerprint)&& ...
    strcmp(node.proxy_chart.fingerprint,frame.proxy_chart.fingerprint)&& ...
    all(isfinite(node.AdefD(:)))&&all(isfinite(node.AdefG(:)));
  if ~ok
    error('i23m:ScientificNodeGate', ...
      'The frozen node/object gate failed at M=%d, k=%.17g.',c.M,k);
  end
end

function yes=LOCAL_scientific_exception(ME)
  id=ME.identifier; yes=startsWith(id,'i21:')||startsWith(id,'kready:')|| ...
    startsWith(id,'kreadyv2:')||strcmp(id,'i23m:ScientificNodeGate');
end

%% ==================== Candidate and common mode ====================
% These helpers form raw diagnostics and embed modes into the M=48 spaces.

function [candidate,code,message]=LOCAL_candidate(node,c,interval,h,layer, ...
    winner_score,runner_score,runner_gap)
  [B,wr,wc]=LOCAL_physical_matrix(node); [U,S,V]=svd(B,'econ');
  singular=flipud(diag(S)); u1=U(:,end); p1=V(:,end); p2=V(:,end-1);
  sigma1=singular(1); sigma2=singular(2); sigmamax=singular(end);
  A=node.AdefD; q=wc.*p1; ell=wr.*u1; anorm=max(realmin,norm(A,2));
  rr=norm(A*q); lr=norm(ell'*A); rb=rr/max(realmin,anorm*norm(q));
  lb=lr/max(realmin,anorm*norm(ell)); trip=max(norm(B*p1-sigma1*u1), ...
    norm(B'*u1-sigma1*p1))/max(realmin,sigmamax);
  K=c.K; I=eye(K); E=diag(node.phase); cm=node.Dm\([I,E]*q);
  cp=node.Dp\([E,I]*q); z=[q;cm;cp];
  drow=[1:K,2*K+1:3*K]; nrow=[K+1:2*K,3*K+1:4*K];
  Gd=node.AdefG(drow,:); Gn=node.AdefG(nrow,:);
  ed=norm(Gd*z)/max(1,norm(Gd,2)*norm(z));
  en=norm(Gn*z-A*q)/max(1,norm(Gn,2)*norm(z)+anorm*norm(q));
  kernel=norm(node.AdefG*z)/max(1,norm(node.AdefG,'fro')*norm(z));
  center=min(norm(q(1:K)),norm(q(K+1:end)))/max(realmin,norm(q));
  graph=min(norm(cm),norm(cp))/max(realmin,norm(z));
  mode1=LOCAL_mode(q,p1,node,c); q2=wc.*p2; mode2=LOCAL_mode(q2,p2,node,c);
  score_pass=winner_score<=c.score_max&&sigma1/sigma2<=c.r12_max;
  raw_pass=isfinite(rb)&&isfinite(lb)&&rb<=c.raw_backward_max&&lb<=c.raw_backward_max;
  svd_pass=isfinite(trip)&&trip<=c.svd_residual_max;
  field_pass=mode1.available&&center>=c.participation_min&& ...
    graph>=c.participation_min&&ed<=c.lift_residual_tol&&en<=c.lift_residual_tol;
  pass=score_pass&&raw_pass&&svd_pass&&field_pass; code='NONE'; message='';
  if ~(score_pass&&raw_pass&&svd_pass)
    code='CANDIDATE_NEAR_NULL'; message='A score, separation, SVD, or raw gate failed.';
  elseif ~field_pass
    code='CANDIDATE_FIELD_BOUNDARY'; message='A field or graph-boundary gate failed.';
  end
  [rows,~]=LOCAL_selectors(c.M);
  candidate=struct('pass',pass,'M',c.M,'K',K,'k',node.k, ...
    'terminal_layer',layer,'terminal_interval',interval, ...
    'minimizer_search_halfwidth',h,'winner_score',winner_score, ...
    'runner_up_score',runner_score,'runner_up_gap',runner_gap, ...
    'AdefD',A,'AdefG',node.AdefG,'Aphys',B,'beta_m',node.beta_m, ...
    'gamma',node.gamma,'phase',node.phase,'row_weight',wr,'column_weight',wc, ...
    'singular_values',singular,'sigma1',sigma1,'sigma2',sigma2, ...
    'sigmamax',sigmamax,'s1',sigma1/sigmamax,'r12',sigma1/sigma2, ...
    'u1',u1,'p1',p1,'p2',p2,'q',q,'left_covector',ell, ...
    'raw_right_residual',rr,'raw_left_residual',lr, ...
    'raw_right_backward',rb,'raw_left_backward',lb, ...
    'svd_triplet_residual',trip,'cminus',cm,'cplus',cp,'lift',z, ...
    'center_participation',center,'graph_participation',graph, ...
    'dirichlet_defect',ed,'neumann_defect',en,'kernel_defect',kernel, ...
    'mode1',mode1,'mode2',mode2,'factors',node.factors,'row',node.row, ...
    'signature',LOCAL_signature(node,rows,c));
end

function mode=LOCAL_mode(q,p,node,c)
  K=c.K; qL=q(1:K); qR=q(K+1:end); b=sqrt(1+abs(node.beta_m(:)).^2);
  dL=qL+node.phase(:).*qR; dR=node.phase(:).*qL+qR;
  trace=[sqrt(b).*dL;sqrt(b).*dR]; probes=zeros(9,1);
  for j=1:9
    x=c.probe_x(j); y=c.probe_y(j); basis=exp(1i*node.beta_m(:)*y)/sqrt(c.d);
    right=exp(1i*node.gamma(:)*(x-c.X_L));
    left=exp(-1i*node.gamma(:)*(x-c.X_R));
    probes(j)=sum((qL.*right+qR.*left).*basis);
  end
  qnorm=norm(q); tr=norm(trace)/max(realmin,qnorm);
  pr=norm(probes)/max(realmin,qnorm);
  common_p=LOCAL_embed(p,c.M,c.M_max); common_q=LOCAL_embed(q,c.M,c.M_max);
  common_t=LOCAL_embed(trace,c.M,c.M_max);
  available=all(isfinite([q(:);p(:);trace(:);probes(:)]))&& ...
    norm(common_p)>realmin&&tr>=c.participation_min&&pr>=c.participation_min;
  mode=struct('available',available,'raw_q',q, ...
    'balanced_port_coordinate',common_p,'padded_raw_q',common_q, ...
    'wall_left',dL,'wall_right',dR,'weighted_wall_trace',common_t, ...
    'probe_x',c.probe_x,'probe_y',c.probe_y,'probe_field',probes, ...
    'trace_ratio',tr,'probe_ratio',pr);
end

function out=LOCAL_embed(x,M,Mmax)
  K=2*M+1; Kmax=2*Mmax+1; x=x(:);
  if numel(x)~=2*K, error('i23m:Mapping','A port vector has the wrong order.'); end
  idx=(Mmax-M+1):(Mmax+M+1); out=zeros(2*Kmax,1,'like',x);
  out(idx)=x(1:K); out(Kmax+idx)=x(K+1:end);
end

function out=LOCAL_signature(node,rows,c)
  out=struct('spec',node.spec,'M',c.M,'K',c.K,'proxy_shape',node.proxy_shape, ...
    'proxy_shifted_shape',node.proxy_shifted_shape,'Aqp_shape',node.Aqp_shape, ...
    'pair_shape',size(node.pair.A),'AdefD_shape',size(node.AdefD), ...
    'AdefG_shape',size(node.AdefG),'rows_plus',node.H_plus_rows, ...
    'rows_minus',node.H_minus_rows,'selectors_expected',rows, ...
    'port_fingerprint',node.branch_port.fingerprint, ...
    'proxy_branch_fingerprint',node.branch_proxy.fingerprint, ...
    'proxy_chart_fingerprint',node.proxy_chart.fingerprint);
end

function seed=LOCAL_seed_summary(node,score,rows,alternate,gauge)
  seed=struct('M',(numel(node.beta_m)-1)/2,'K',numel(node.beta_m), ...
    'k',node.k,'s1',score.s1,'r12',score.r12, ...
    'singular_values',score.singular_values,'node_pass',node.pass, ...
    'factor_pass',all([node.factors.pass]),'primary_selectors',rows, ...
    'alternate_selectors',alternate,'gauge_pass',gauge.pass, ...
    'fixed_rows',node.row,'dirichlet_plus',LOCAL_chart_summary(node.cp), ...
    'dirichlet_minus',LOCAL_chart_summary(node.cm), ...
    'qz_plus',LOCAL_qz_summary(node.plus), ...
    'qz_minus',LOCAL_qz_summary(node.minus), ...
    'proxy_rank',node.proxy_chart.r,'proxy_shape',node.proxy_shape, ...
    'proxy_shifted_shape',node.proxy_shifted_shape, ...
    'Aqp_shape',node.Aqp_shape,'pair_shape',size(node.pair.A), ...
    'AdefD_shape',size(node.AdefD),'AdefG_shape',size(node.AdefG), ...
    'proxy_fingerprint',node.proxy_chart.fingerprint, ...
    'port_fingerprint',node.branch_port.fingerprint);
end

function out=LOCAL_chart_summary(chart)
  out=struct('safe',chart.safe,'margin',chart.margin, ...
    'condition',chart.condition,'solve_residual',chart.solve_residual);
end

function out=LOCAL_qz_summary(q)
  out=struct('pass',q.pass,'stable',q.stable_diagnostic, ...
    'unstable',q.unstable_diagnostic,'neutral',q.neutral_count, ...
    'indeterminate',q.indeterminate_count,'residual',q.residual);
end

function common=LOCAL_common_gate(seeds,locators,c)
  pass=true; max_gamma=0; max_phase=0; shared_counts=zeros(1,2);
  for j=2:3
    pass=pass&&seeds{j}.proxy_rank==seeds{1}.proxy_rank&& ...
      isequal(seeds{j}.proxy_shape,seeds{1}.proxy_shape)&& ...
      isequal(seeds{j}.proxy_shifted_shape,seeds{1}.proxy_shifted_shape)&& ...
      strcmp(seeds{j}.proxy_fingerprint,seeds{1}.proxy_fingerprint);
  end
  for pair=1:2
    low=locators{pair}.node_rows; high=locators{pair+1}.node_rows;
    Ml=low(1).M; Mh=high(1).M; idx=(Mh-Ml+1):(Mh+Ml+1); count=0;
    for a=1:numel(low)
      b=find([high.k]==low(a).k,1);
      if isempty(b), continue; end
      count=count+1; pass=pass&&isequal(low(a).beta_m,high(b).beta_m(idx));
      max_gamma=max(max_gamma,max(abs(low(a).gamma-high(b).gamma(idx))));
      max_phase=max(max_phase,max(abs(low(a).phase-high(b).phase(idx))));
    end
    shared_counts(pair)=count; pass=pass&&count>=1;
  end
  pass=pass&&max_gamma<=c.common_channel_tol&&max_phase<=c.common_channel_tol;
  message=''; if ~pass, message='Proxy or common Fourier-channel values drifted.'; end
  common=struct('pass',pass,'shared_node_counts',shared_counts, ...
    'max_gamma_difference',max_gamma,'max_phase_difference',max_phase, ...
    'proxy_fingerprint',seeds{1}.proxy_fingerprint,'message',message);
end

function [repeat,peak_mib]=LOCAL_repeat(candidate,c,frame,seed,timer,retained)
  try
    node=eval_i21('point',candidate.k,c,frame); LOCAL_node_gate(node,candidate.k,frame,c);
  catch ME
    if LOCAL_scientific_exception(ME)
      failure=LOCAL_failure('CANDIDATE_REPEAT','REPEAT',c.M,candidate.k, ...
        ME.message,ME.identifier);
      repeat=struct('pass',false,'M',c.M,'k',candidate.k, ...
        'matrix_relative_difference',Inf,'score_difference',Inf, ...
        'balanced_port_overlap',NaN,'factor_pattern_same',false, ...
        'ranking_stability_claim',false,'first_failure',failure);
      peak_mib=0; return;
    end
    rethrow(ME);
  end
  score=LOCAL_score(node); [other,~,~]=LOCAL_candidate(node,c, ...
    candidate.terminal_interval,candidate.minimizer_search_halfwidth, ...
    candidate.terminal_layer,score.s1,candidate.runner_up_score, ...
    candidate.runner_up_gap);
  md=norm(other.AdefD-candidate.AdefD,'fro')/max(1,norm(candidate.AdefD,'fro'));
  sd=abs(other.s1-candidate.s1); [rho,available]=LOCAL_overlap( ...
    candidate.mode1.balanced_port_coordinate, ...
    other.mode1.balanced_port_coordinate,0,0);
  pattern=LOCAL_factor_pattern(candidate.factors,other.factors)&& ...
    isequal(candidate.signature,other.signature);
  pass=other.pass&&md<=c.repeat_matrix_max&&sd<=c.repeat_score_max&& ...
    available&&rho>=c.repeat_overlap_min&&pattern;
  failure=LOCAL_failure('NONE','NONE',c.M,candidate.k,'','');
  if ~pass
    failure=LOCAL_failure('CANDIDATE_REPEAT','REPEAT',c.M,candidate.k, ...
      'A fixed-candidate repeat gate failed.','');
  end
  repeat=struct('pass',pass,'M',c.M,'K',c.K,'k',candidate.k, ...
    'AdefD',other.AdefD,'matrix_relative_difference',md,'s1',other.s1, ...
    'score_difference',sd,'balanced_port_coordinate', ...
    other.mode1.balanced_port_coordinate,'balanced_port_overlap',rho, ...
    'factor_pattern_same',pattern,'factors',other.factors, ...
    'signature',other.signature,'ranking_stability_claim',false, ...
    'repeat_scope','FIXED_CANDIDATE_ONLY_NOT_RANKING_STABILITY', ...
    'first_failure',failure);
  peak_mib=LOCAL_mib(frame,seed,retained,repeat); LOCAL_resource_gate(timer,peak_mib,c);
end

function same=LOCAL_factor_pattern(a,b)
  same=numel(a)==numel(b); if ~same, return; end
  same=isequal({a.name},{b.name})&& ...
    isequal(logical([a.available]),logical([b.available]))&& ...
    isequal(logical([a.pass]),logical([b.pass]));
end

%% ==================== Cross-M identity and drift ====================
% These helpers compare common representations and direct saved candidates.

function out=LOCAL_identity(a,b,c,hard_gate)
  ma=a.mode1; mb=b.mode1; sa=a.mode2; sb=b.mode2;
  reps={'balanced_port_coordinate','weighted_wall_trace','probe_field'};
  primary=zeros(1,3); available=true;
  for j=1:3, [primary(j),ok]=LOCAL_overlap(ma.(reps{j}),mb.(reps{j}),0,0); available=available&&ok; end
  [raw_q,raw_available]=LOCAL_overlap(ma.padded_raw_q,mb.padded_raw_q,0,0);
  cross=NaN(2,3); cross_available=sa.available&&sb.available;
  if cross_available
    for j=1:3
      [cross(1,j),ok1]=LOCAL_overlap(ma.(reps{j}),sb.(reps{j}),0,0);
      [cross(2,j),ok2]=LOCAL_overlap(sa.(reps{j}),mb.(reps{j}),0,0);
      cross_available=cross_available&&ok1&&ok2;
    end
  end
  if cross_available, competitor=max(cross(:)); else, competitor=1; end
  pass=ma.available&&mb.available&&available&&all(primary>=c.identity_overlap_min)&& ...
    cross_available&&competitor<=c.competitor_overlap_max;
  inner=ma.weighted_wall_trace'*mb.weighted_wall_trace;
  if isfinite(inner)&&abs(inner)>realmin, phase=conj(inner)/abs(inner); else, phase=NaN; end
  if pass, status='SAME_MODE';
  elseif cross_available&&competitor>c.competitor_overlap_max, status='MODE_SWITCH';
  else, status='MODE_IDENTITY_UNRESOLVED'; end
  tail=struct('balanced_port',LOCAL_tail(mb.balanced_port_coordinate,a.M,c.M_max), ...
    'raw_q',LOCAL_tail(mb.padded_raw_q,a.M,c.M_max), ...
    'weighted_wall',LOCAL_tail(mb.weighted_wall_trace,a.M,c.M_max));
  out=struct('M_low',a.M,'M_high',b.M,'hard_gate',logical(hard_gate), ...
    'status',status,'pass',pass,'balanced_port_overlap',primary(1), ...
    'wall_overlap',primary(2),'probe_overlap',primary(3), ...
    'raw_q_overlap',raw_q,'raw_q_overlap_available',raw_available, ...
    'secondary_low_available',sa.available,'secondary_high_available',sb.available, ...
    'cross_overlaps',cross,'competitor_overlap',competitor, ...
    'high_tail_fractions',tail,'phase_alignment',phase, ...
    'aligned_high_balanced_port',phase*mb.balanced_port_coordinate, ...
    'aligned_high_raw_q',phase*mb.padded_raw_q, ...
    'aligned_high_wall',phase*mb.weighted_wall_trace, ...
    'aligned_high_probe',phase*mb.probe_field);
end

function fraction=LOCAL_tail(x,Mcut,Mmax)
  Kmax=2*Mmax+1; orders=(-Mmax:Mmax).'; mask=abs(orders)>Mcut;
  idx=find([mask;mask]); fraction=norm(x(idx))/max(realmin,norm(x));
end

function [rho,available]=LOCAL_overlap(x,y,min_x,min_y)
  nx=norm(x); ny=norm(y); available=all(isfinite(x(:)))&&all(isfinite(y(:)))&& ...
    isfinite(nx)&&isfinite(ny)&&nx>=max(realmin,min_x)&&ny>=max(realmin,min_y);
  if available, rho=abs(x(:)'*y(:))/(nx*ny); else, rho=NaN; end
end

function out=LOCAL_drift(a,b,c)
  delta=b.k-a.k; magnitude=abs(delta);
  if delta==0, label='NO_OBSERVED_CANDIDATE_DRIFT';
  elseif magnitude<=c.severity_scale, label='OBSERVED_CANDIDATE_DRIFT_SUBTARGET';
  else, label='OBSERVED_CANDIDATE_DRIFT_SEVERE'; end
  out=struct('M_low',a.M,'M_high',b.M,'delta',delta,'magnitude',magnitude, ...
    'classification',label,'direction',LOCAL_direction(delta), ...
    'low_minimizer_search_halfwidth',a.minimizer_search_halfwidth, ...
    'high_minimizer_search_halfwidth',b.minimizer_search_halfwidth, ...
    'halfwidth_used_in_drift',false);
end

function out=LOCAL_direction(delta)
  if delta>0, out='POSITIVE'; elseif delta<0, out='NEGATIVE'; else, out='ZERO'; end
end

function trend=LOCAL_trend(a,b)
  if a.delta==0&&b.delta==0, trend='FLAT';
  elseif a.delta==0||b.delta==0, trend='NONSTRICT';
  elseif sign(a.delta)==sign(b.delta), trend='MONOTONE'; else, trend='NONMONOTONE'; end
end

%% ==================== Result, resources, and report ====================
% These helpers publish the sole append-only MAT/report pair.

function result=LOCAL_result(attempt,status,execution,outcome,hierarchy,i3may, ...
    i3status,trend,elapsed,peak,c,runtime,oracle,seeds,gauges,locators, ...
    candidates,repeats,identities,drifts,common,failure)
  count=struct('status','NOT_ATTACHED','reason','FIXED_NTOT160_NOT_I2_1_PARENT', ...
    'all_M_levels','NOT_ESTABLISHED','transferred',false);
  prior=struct('attempt','m-drift-a1','elapsed_seconds',22.177848167, ...
    'exit_code',1,'raw_error', ...
    'Subscripted assignment between dissimilar structures.', ...
    'error_identifier','NOT_RECORDED','stack', ...
    'LOCAL_config line 199 / check_m_drift line 32', ...
    'evaluator_call_count',0,'output_created',false,'consumed',true);
  command=['matlab -batch "addpath(fullfile(pwd,''test'',''i2'',''m-drift''),' ...
    'fullfile(pwd,''test'',''i2'',''k-count'')); check_m_drift(''m-drift-a2'');"'];
  hierarchy_label='NOT_QUALIFIED';
  if hierarchy, hierarchy_label='CONDITIONAL_ALGORITHMIC_M_AXIS_HIERARCHY'; end
  result=struct('schema',c.schema,'experiment_id',c.experiment_id, ...
    'design_id',c.design_id,'attempt',attempt,'status',status, ...
    'execution_pass',logical(execution),'scientific_outcome',outcome, ...
    'hierarchy_qualified',logical(hierarchy),'hierarchy_label',hierarchy_label, ...
    'i3_may_proceed',logical(i3may), ...
    'i3_status',i3status,'trend',trend,'claim_boundary',c.claim_boundary, ...
    'axis',c.axis,'subgrid_minimizer_claim',false,'finite_root_claim',false, ...
    'continuous_mode_claim',false,'convergence_order_claim',false, ...
    'error_bound_claim',false,'elapsed_seconds',elapsed,'peak_active_mib',peak, ...
    'target_seconds',c.target_seconds,'hard_seconds',c.hard_seconds, ...
    'memory_mib_max',c.memory_mib_max,'config',c,'runtime',runtime, ...
    'identity_oracle',oracle,'count_context',count,'seeds',{seeds}, ...
    'gauges',{gauges},'locators',{locators},'candidates',{candidates}, ...
    'repeats',{repeats},'common_representation',common, ...
    'identities',{identities},'drifts',{drifts},'first_failure',failure, ...
    'prior_failed_attempt_count',1,'prior_failed_attempt',prior, ...
    'retry_count',0,'command',command,'output_files',{{'result.mat','report.md'}});
end

function [code,stage]=LOCAL_exception_class(ME)
  if LOCAL_scientific_exception(ME), code='SCIENTIFIC_NODE_GATE'; stage='SEED';
  elseif strcmp(ME.identifier,'i23m:HARD_TIME'), code='HARD_TIME'; stage='RESOURCE';
  elseif strcmp(ME.identifier,'i23m:MEMORY'), code='MEMORY'; stage='RESOURCE';
  elseif strcmp(ME.identifier,'i23m:IdentityOracle'), code='IDENTITY_ORACLE_FAIL'; stage='ORACLE';
  elseif startsWith(ME.identifier,'i23m:Runtime')||startsWith(ME.identifier,'i23m:Config')
    code='RUNTIME_OR_CONFIG_FAIL'; stage='PREFLIGHT';
  else, code='IMPLEMENTATION_ERROR'; stage='UNLISTED'; end
end

function out=LOCAL_failure(code,stage,M,k,message,identifier)
  out=struct('code',code,'stage',stage,'M',M,'k',k, ...
    'message',message,'identifier',identifier);
end

function LOCAL_resource_gate(timer,peak,c)
  if toc(timer)>c.hard_seconds, error('i23m:HARD_TIME','The 1200 s hard limit was exceeded.'); end
  if peak>c.memory_mib_max, error('i23m:MEMORY','The 512 MiB active-object limit was exceeded.'); end
end

function mib=LOCAL_mib(varargin)
  bytes=0;
  for j=1:nargin
    item=varargin{j}; %#ok<NASGU>
    info=whos('item'); bytes=bytes+info.bytes;
  end
  mib=bytes/2^20;
end

function value=LOCAL_field(s,name,fallback)
  if isstruct(s)&&isfield(s,name), value=s.(name); else, value=fallback; end
end

function LOCAL_report(path,r)
  fid=fopen(path,'w'); if fid<0, error('i23m:Report','Cannot open report.md.'); end
  cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
  fprintf(fid,'# I2.3 M-axis saved-candidate drift\n\n');
  fprintf(fid,'- Status / outcome: `%s / %s`\n',r.status,r.scientific_outcome);
  fprintf(fid,'- Execution / hierarchy / I3: `%d / %d / %d`\n', ...
    r.execution_pass,r.hierarchy_qualified,r.i3_may_proceed);
  fprintf(fid,'- I3 status / trend: `%s / %s`\n',r.i3_status,r.trend);
  fprintf(fid,'- Time / peak: `%.6g s / %.6g MiB`\n',r.elapsed_seconds,r.peak_active_mib);
  fprintf(fid,'- Prior failed attempts / a2 retries: `%d / %d`\n', ...
    r.prior_failed_attempt_count,r.retry_count);
  fprintf(fid,'- Axis: `%s`\n\n',r.axis);
  fprintf(fid,'## Levels\n\n');
  fprintf(fid,'| M | K | locator | candidate k | minimizer halfwidth | s1 | r12 | gap | repeat |\n');
  fprintf(fid,'|---:|---:|---|---:|---:|---:|---:|---:|---|\n');
  for j=1:3
    loc=r.locators{j}; cand=r.candidates{j}; rep=r.repeats{j};
    if isempty(loc), continue; end
    if isempty(cand)
      fprintf(fid,'| %d | %d | FAIL | NaN | %.6g | NaN | NaN | %.6g | -- |\n', ...
        loc.M,loc.K,loc.minimizer_search_halfwidth,loc.terminal_runner_up_gap);
    else
      rt='--'; if ~isempty(rep), rt=LOCAL_pass_text(rep.pass); end
      fprintf(fid,'| %d | %d | %s | %.17g | %.6g | %.6g | %.6g | %.6g | %s |\n', ...
        cand.M,cand.K,LOCAL_pass_text(loc.pass),cand.k, ...
        cand.minimizer_search_halfwidth,cand.s1,cand.r12,cand.runner_up_gap,rt);
    end
  end
  fprintf(fid,'\nThe halfwidth is only a sub-grid minimizer search diagnostic.\n\n');
  fprintf(fid,'## Selector gauge\n\n| M | pass | AdefD relF | score diff | q | wall | probe |\n');
  fprintf(fid,'|---:|---:|---:|---:|---:|---:|---:|\n');
  for j=1:3
    g=r.gauges{j}; if isempty(g), continue; end
    fprintf(fid,'| %d | %d | %.6g | %.6g | %.6g | %.6g | %.6g |\n', ...
      g.M,g.pass,g.matrix_relative_difference,g.score_difference, ...
      g.raw_q_overlap,g.wall_overlap,g.probe_overlap);
  end
  fprintf(fid,'\n## Candidate health\n\n');
  fprintf(fid,['| M | raw R/L residual | raw R/L backward | SVD | factors | ', ...
    'center/graph | D/N defects | kernel |\n']);
  fprintf(fid,'|---:|---:|---:|---:|---:|---:|---:|---:|\n');
  for j=1:3
    x=r.candidates{j}; if isempty(x), continue; end
    fprintf(fid,['| %d | %.3g / %.3g | %.3g / %.3g | %.3g | %d | ', ...
      '%.3g / %.3g | %.3g / %.3g | %.3g |\n'], ...
      x.M,x.raw_right_residual,x.raw_left_residual, ...
      x.raw_right_backward,x.raw_left_backward,x.svd_triplet_residual, ...
      all([x.factors.pass]), ...
      x.center_participation,x.graph_participation,x.dirichlet_defect, ...
      x.neumann_defect,x.kernel_defect);
  end
  if isfield(r.common_representation,'pass')
    fprintf(fid,['\nCommon proxy/channels: `%d`; max gamma/phase differences: ', ...
      '`%.3g / %.3g`.\n'],r.common_representation.pass, ...
      r.common_representation.max_gamma_difference, ...
      r.common_representation.max_phase_difference);
  end
  fprintf(fid,'\n## Mode identity\n\n');
  fprintf(fid,'| M pair | status | port | wall | probe | competitor | hard |\n');
  fprintf(fid,'|---|---|---:|---:|---:|---:|---:|\n');
  for j=1:3
    x=r.identities{j}; if isempty(x), continue; end
    fprintf(fid,'| %d--%d | %s | %.6g | %.6g | %.6g | %.6g | %d |\n', ...
      x.M_low,x.M_high,x.status,x.balanced_port_overlap,x.wall_overlap, ...
      x.probe_overlap,x.competitor_overlap,x.hard_gate);
  end
  fprintf(fid,'\n## Direct saved-candidate drift\n\n');
  fprintf(fid,'| M pair | signed drift | absolute drift | classification |\n');
  fprintf(fid,'|---|---:|---:|---|\n');
  for j=1:3
    x=r.drifts{j}; if isempty(x), continue; end
    fprintf(fid,'| %d--%d | %.17g | %.17g | %s |\n', ...
      x.M_low,x.M_high,x.delta,x.magnitude,x.classification);
  end
  fprintf(fid,'\n## Failure and boundary\n\n- First failure: `%s / %s`\n', ...
    r.first_failure.code,r.first_failure.stage);
  if ~isempty(r.first_failure.message)
    fprintf(fid,'- Message: `%s`\n',strrep(r.first_failure.message,'`',''''));
  end
  fprintf(fid,['\nNo I2.1 count attaches to these ntot=160 levels. This result does ', ...
    'not establish a sub-grid minimizer, finite root, continuous mode, ', ...
    'convergence order, estimator, or error bound.\n\n']);
  fprintf(fid,'Registered command:\n\n```sh\n%s\n```\n',r.command);
end

function text=LOCAL_pass_text(pass)
  if pass, text='PASS'; else, text='FAIL'; end
end
