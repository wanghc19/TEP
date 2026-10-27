function result = dtn_bound_i96(config,native,output_dir)
%DTN_BOUND_I96 I9.6a D2 positive-definite source-reconstruction spectral-distance bound.
% Purpose: For the frozen I9.5b fine-Q12 FEM+DtN candidate k, evaluate the
%   design-9-6a D2 bound dist(mu,sigma(A(beta))) <= R_mu (mu = k^2, shift
%   s = mu, s-dtn-bound Theorem 2) on the control and main rectangle/Fourier
%   levels with every non-rounding error term enclosed, and deliver R_mu, R_k,
%   all error terms, the budgets, the status and the complete cost.
% Input: config = dtn_bound_i96_config(mode); native = [] (fixed-frequency
%   reconstruction by the adapter, identity FIXED_FREQUENCY_RECONSTRUCTION) or
%   an explicit native struct of the same schema (EXPLICIT_SAVED_FIELD);
%   output_dir = new run directory.
% Output: result.json, integration.json, native.mat, blocks/<level>/*.mat with
%   blocks/index (in integration.json), modes.csv, cells.csv, levels.csv,
%   pilot.csv, progress.json, figures/*.png and the result struct.
% Main algorithm (design D2 Section 6, serial):
%   0. self-tests of the reliable path (Duffy exactness to degree 18, engine
%      grid cut/tube/coverage, correction update, Fourier phase, Taylor norm
%      enclosure, D2.8, status rejection branches, Q attribution);
%   1. native field (adapter, I9.5b qualification gates, raw QZ/E/P blocks);
%   2. main-level pilot: centre-template strip, formal engine rounds, measured
%      tightening and mandatory-flow prediction (cost gate);
%   3. per level: stage A (prediction Q1/Q2 coefficients with the Q fix, exact
%      bulk sums of non-special elements, chunked coefficient and Fourier
%      files), reference-domain engine of the special elements (L_T slabs with
%      eta bands, chord tubes of the true curve, exact Duffy integration of
%      certain pieces, Bernstein bounds of uncertain records), source-moment
%      boxes and the one-time correction, Fourier correction, 32-mode Yukawa
%      batches with Taylor norms and explicit remainders, Parseval tails;
%   4. assembly eps0, R_mu, R_k, budgets and the status machine per level.
% Based on: test/i9/dtn-bound-v1 D1 (adapter, ordinary projection, Fourier
%   factors, Yukawa sweeps) and test/i9/fem-dtn-v1/fem_dtn_i95b.m (curve, mesh,
%   templates, cell elimination, QZ/DtN, recovery checks, P2/JSON/RSS helpers).
% Main changes: D1 proxy gate removed; reliable evaluation success path
%   (reference engine, moment boxes, correction, remainder-carrying norms),
%   pilot cost gate, disk-chunked strip storage, D2 status machine.
% Numerical goal: EXACT_ARITHMETIC_UPPER_BOUND R_mu, R_k (floating-point
%   rounding not certified) and the ORDINARY_ESTIMATE column per level.
  if nargin < 2, native = []; end
  entry_utc = char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSSSSSXXX'));
  started = tic;
  if ~isfolder(output_dir), mkdir(output_dir); end
  if ~isfolder(fullfile(output_dir,'figures')), mkdir(fullfile(output_dir,'figures')); end
  maxNumCompThreads(config.resources.threads);
  ctx = struct('output_dir',output_dir,'started',started,'config',config, ...
    'progress_path',fullfile(output_dir,'progress.json'));
  ledger = LOCAL_ledger();
  LOCAL_json(fullfile(output_dir,'config.json'),config);
  environment = struct('matlab_version',version,'platform',computer, ...
    'max_threads',maxNumCompThreads,'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS'), ...
    'entry_utc',entry_utc,'pid',feature('getpid'));
  fprintf('ENTRY %s mode=%s threads=%d\n',entry_utc,config.mode,maxNumCompThreads);
  result = struct('schema',config.schema,'mode',config.mode,'k',config.k,'mu',config.k^2, ...
    'final_status','','final_reason','','input_identity','','native',struct(), ...
    'constants',struct(),'selftest',struct(),'pilot',struct(),'levels',struct([]), ...
    'environment',environment);
  stage = 'selftest'; levels = struct([]); infos = struct([]); pilot = struct(); resource_stop = '';
  try
    % --- stage 0: self-tests of the reliable evaluation path ---
    timer = tic;
    result.selftest = LOCAL_selftest_d2(config);
    ledger.selftest = toc(timer);
    fprintf('STAGE selftest pass=%d %s (%.2fs)\n',result.selftest.pass,result.selftest.reason,ledger.selftest);
    LOCAL_json(fullfile(output_dir,'selftest.json'),result.selftest);
    assert(result.selftest.pass,'i96:SelfTest','Self-test failed: %s',result.selftest.reason);
    % --- stage 1: native field (fixed-frequency adapter or explicit input) ---
    stage = 'native'; LOCAL_progress(ctx,'native',NaN);
    timer = tic;
    if isempty(native)
      native = LOCAL_adapter(config);
    else
      native = LOCAL_explicit_native(config,native);
    end
    ledger.native_adapter = toc(timer);
    result.native = native.summary; result.input_identity = native.identity;
    fprintf('STAGE native %s qualified=%d lambda=%.3e centre_residual=%.3e cells=%d (%.2fs)\n', ...
      native.identity,native.qualified,native.summary.lambda,native.summary.center_residual, ...
      numel(native.cells),ledger.native_adapter);
    timer = tic; LOCAL_save_native(output_dir,native); ledger.save = ledger.save+toc(timer);
    native.recovery = struct(); native.qz = struct();      % saved; released before the levels
    if ~native.qualified && ~config.continue_on_mismatch
      result.final_status = 'NATIVE_FIELD_MISMATCH'; result.final_reason = native.summary.reason;
      result.timing = LOCAL_ledger_close(ledger,toc(started));
      LOCAL_json(fullfile(output_dir,'result.json'),result);
      LOCAL_progress(ctx,'done',0);
      fprintf('COMPLETE %s: %s\n',result.final_status,result.final_reason);
      return
    end
    common = LOCAL_constants(config,native);
    result.constants = common;
    % --- stage 2: main-level pilot and cost gate ---
    stage = 'pilot'; LOCAL_progress(ctx,stage,NaN);
    timer = tic;
    pilot = LOCAL_pilot(ctx,native,config.levels(end),common);
    ledger.pilot = toc(timer); result.pilot = pilot;
    LOCAL_json(fullfile(output_dir,'pilot.json'),pilot);
    % --- stage 3+4: the two evaluation levels ---
    plan = config.plan; nL = numel(config.levels);
    for L = 1:nL
      lev = config.levels(L);
      if ~pilot.pass
        levels = LOCAL_append_union(levels,LOCAL_skipped_level_d2(lev,common,['pilot gate failed: ',pilot.reason]));
        continue
      end
      stage = ['level:',lev.name];
      reserve = sum(plan.stageA_reserve(L:nL))+sum(plan.norms_reserve(L:nL))+plan.save_reserve;
      window = config.resources.soft_seconds-toc(started)-reserve;
      if L<nL, window = config.engine.control_engine_share*window; end
      engine_deadline = toc(started)+plan.stageA_reserve(L)+max(window,0);
      LOCAL_progress(ctx,stage,config.resources.soft_seconds-toc(started));
      fprintf('STAGE level %s: engine deadline %.0fs (elapsed %.0fs)\n',lev.name,engine_deadline,toc(started));
      try
        [LV,info] = LOCAL_level_d2(ctx,native,lev,common,engine_deadline);
      catch level_error
        if ~strcmp(level_error.identifier,'i96:ResourceStop'), rethrow(level_error); end
        resource_stop = sprintf('%s at level %s',level_error.message,lev.name);
        levels = LOCAL_append_union(levels,LOCAL_skipped_level_d2(lev,common,['RESOURCE_STOP: ',level_error.message]));
        fprintf('RESOURCE_STOP %s\n',resource_stop);
        break
      end
      f = {'stageA','engine','aggregate','correction','norms','save'};
      for j = 1:numel(f), ledger.(['level_',f{j}]) = ledger.(['level_',f{j}])+LV.seconds.(f{j}); end
      levels = LOCAL_append_union(levels,LV);
      infos = LOCAL_append(infos,struct('level',lev.name,'modes',info.mode_table,'cells',info.cell_table));
      x = LV.exact;
      fprintf(['LEVEL %s: D0=[%.9f,%.9f] delta_u=%.3e E_v=%.6e eps0=%.3e (cR*ER=%.3e mom=%.3e Ey/bM=%.3e) ', ...
        'R_mu=%.6e R_k=%.6e [%s] %s\n'],lev.name,x.D0(1),x.D0(2),x.delta_u(2),x.E_v(2),x.eps0, ...
        x.c_R_E_R,x.moment_term,x.E_y_over_b_M,x.R_mu,x.R_k,x.status,x.reason);
      timer = tic; LOCAL_partial(ctx,levels,pilot,ledger); ledger.save = ledger.save+toc(timer);
    end
    if isempty(levels), levels = LOCAL_append_union(levels,LOCAL_skipped_level_d2(config.levels(1),common,'no level')); end
    % --- stage 5: final status ---
    stage = 'final_status';
    result.levels = levels;
    [result.final_status,result.final_reason,result.status_detail,result.acceptance] = ...
      LOCAL_final_d2(config,native,common,levels,pilot,resource_stop);
    % --- stage 6: figures (MATLAB native export) ---
    stage = 'figures'; LOCAL_progress(ctx,stage,config.resources.save_estimate_seconds);
    timer = tic;
    result.figures = LOCAL_figures_d2(ctx,native,levels,infos,pilot);
    ledger.figures = toc(timer);
    % --- stage 7: machine outputs ---
    stage = 'save'; timer = tic;
    LOCAL_write_modes_d2(fullfile(output_dir,'modes.csv'),infos);
    LOCAL_write_cells_d2(fullfile(output_dir,'cells.csv'),infos);
    LOCAL_write_levels_d2(fullfile(output_dir,'levels.csv'),levels);
    LOCAL_write_pilot(fullfile(output_dir,'pilot.csv'),pilot);
    integration = struct('budget_relative',config.budget_relative,'U0',common.U0,'b',common.b, ...
      'pilot',pilot,'levels',struct([]));
    for L = 1:numel(levels)
      l = levels(L);
      if ~l.completed
        integration.levels = LOCAL_append(integration.levels,struct('name',l.name,'completed',false, ...
          'skip_reason',l.skip_reason,'engine',[],'stageA',[],'checks',[],'correction',[], ...
          'integrals_per_template',[],'block_index',[],'block_bytes',0)); continue
      end
      integration.levels = LOCAL_append(integration.levels,struct('name',l.name,'completed',true, ...
        'skip_reason','','engine',l.engine,'stageA',l.stageA,'checks',l.checks,'correction',l.correction, ...
        'integrals_per_template',l.integrals_per_template,'block_index',l.block_index,'block_bytes',l.block_bytes));
    end
    LOCAL_json(fullfile(output_dir,'integration.json'),integration);
    ledger.save = ledger.save+toc(timer);
    % result.json keeps the summaries; the bulky per-round data are in integration.json
    for L = 1:numel(result.levels)
      if result.levels(L).completed
        result.levels(L).engine = rmfield(result.levels(L).engine,'rounds');
        result.levels(L).block_index = numel(result.levels(L).block_index);
      end
    end
    result.timing = LOCAL_ledger_close(ledger,toc(started));
    result.peak_rss_matlab_bytes = LOCAL_rss();
    LOCAL_json(fullfile(output_dir,'result.json'),result);
    LOCAL_progress(ctx,'done',0);
    fprintf('COMPLETE %s matlab %.2fs: %s\n',result.final_status,toc(started),result.final_reason);
  catch error_object
    status = 'EXCEPTION';
    if strcmp(error_object.identifier,'i96:ResourceStop'), status = 'RESOURCE_STOP'; end
    failure = struct('stage',stage,'status',status,'identifier',error_object.identifier, ...
      'message',error_object.message,'report',getReport(error_object,'extended','hyperlinks','off'), ...
      'elapsed_seconds',toc(started),'timing',LOCAL_ledger_close(ledger,toc(started)));
    failure.stack = error_object.stack;
    LOCAL_json(fullfile(output_dir,'failure.json'),failure);
    LOCAL_partial(ctx,levels,pilot,ledger);
    rethrow(error_object);
  end
end

%% ==================== D2 constants ====================
% C_rho, C_G (K = 32 finite sum plus tail, squared first), shift floor, budget b.
function common = LOCAL_constants(config,native)
  k = native.k; mu = k^2; s = mu; beta = config.model.beta;
  rho = [config.model.rho_background,config.model.rho_center,config.model.rho_negative, ...
    config.model.rho_positive];
  C_rho = max((mu*rho+s)./sqrt(rho));
  K = 32; b_beta = abs(beta)/(2*pi); m = (-K:K)'; a = sqrt(s+(beta+2*pi*m).^2);
  CG2 = sum(1./(4*a.^3))+1/(4*(2*pi)^3*(K-b_beta)^2);
  q_star = min(abs(beta+2*pi*(-2:2)));
  common = struct('k',k,'mu',mu,'s',s,'beta',beta,'C_rho',C_rho,'CG_squared',CG2, ...
    'CG',sqrt(CG2),'shift_floor',s+q_star^2,'U0',native.U0, ...
    'b',config.budget_relative*native.U0,'rho_max',max(rho),'rho_background', ...
    config.model.rho_background,'resolution_target_k',config.resolution_target_k);
end

%% ==================== Tables, figures, progress and ledger ====================
% Machine tables (CSV, full precision for small terms), figures, timers.
function LOCAL_write_modes_d2(path,infos)
  fid = fopen(path,'w'); assert(fid>=0,'i96:IO','Cannot create modes.csv.');
  fprintf(fid,['level,m,q,a,source_energy,field_energy,w2_lo,w2_hi,w2_mid,vw2_lo,vw2_hi,vw2_mid,', ...
    'Td2_lo,Td2_hi,Td2_mid\n']);
  for L = 1:numel(infos)
    T = infos(L).modes;
    for j = 1:numel(T.m)
      fprintf(fid,'%s,%d,%.17g,%.17g,%.17e,%.17e,%.17e,%.17e,%.17e,%.17e,%.17e,%.17e,%.17e,%.17e,%.17e\n', ...
        infos(L).level,T.m(j),T.q(j),T.a(j),T.source_energy(j),T.field_energy(j),T.w2_lo(j),T.w2_hi(j), ...
        T.w2_mid(j),T.vw2_lo(j),T.vw2_hi(j),T.vw2_mid(j),T.Td2_lo(j),T.Td2_hi(j),T.Td2_mid(j));
    end
  end
  fclose(fid);
end

function LOCAL_write_cells_d2(path,infos)
  fid = fopen(path,'w'); assert(fid>=0,'i96:IO','Cannot create cells.csv.');
  f = {'mass','mass_matrix','If_lo','If_hi','Iu_lo','Iu_hi','If_unc','Iu_unc','ER2_ordinary', ...
    'du2_ordinary','w2_box_hi','vw2_box_hi','tailF_mid','tailV_mid','dns_max'};
  fprintf(fid,'level,cell,template,%s\n',strjoin(f,','));
  for L = 1:numel(infos)
    T = infos(L).cells;
    for j = 1:numel(T)
      r = T(j); v = cellfun(@(n)sprintf('%.17e',r.(n)),f,'UniformOutput',false);
      fprintf(fid,'%s,%d,%s,%s\n',r.level,r.cell,r.template,strjoin(v,','));
    end
  end
  fclose(fid);
end

function LOCAL_write_levels_d2(path,levels)
  fid = fopen(path,'w'); assert(fid>=0,'i96:IO','Cannot create levels.csv.');
  fprintf(fid,['level,N,M,completed,status,R_mu,R_k,D0_lo,D0_hi,eps0,delta_u_lo,delta_u_hi,E_v_lo,E_v_hi,', ...
    'E_R_lo,E_R_hi,c_R_E_R,delta_c,delta_1,moment_term,E_y_lo,E_y_hi,E_y_over_b_M,T_v_hi,lower_defect,', ...
    'budgets_all_pass,ordinary_R_mu,ordinary_R_k,seconds\n']);
  for L = 1:numel(levels)
    l = levels(L); x = l.exact;
    if ~l.completed
      fprintf(fid,'%s,%d,%d,0,%s%s\n',l.name,l.N,l.M,x.status,repmat(',',1,25)); continue
    end
    fprintf(fid,['%s,%d,%d,1,%s,%.17e,%.17e,%.17e,%.17e,%.17e,%.17e,%.17e,%.17e,%.17e,%.17e,%.17e,', ...
      '%.17e,%.17e,%.17e,%.17e,%.17e,%.17e,%.17e,%.17e,%.17e,%d,%.17e,%.17e,%.3f\n'], ...
      l.name,l.N,l.M,x.status,x.R_mu,x.R_k,x.D0(1),x.D0(2),x.eps0,x.delta_u(1),x.delta_u(2), ...
      x.E_v(1),x.E_v(2),x.E_R(1),x.E_R(2),x.c_R_E_R,x.delta_c,x.delta_1,x.moment_term,x.E_y(1),x.E_y(2), ...
      x.E_y_over_b_M,x.T_v(2),x.lower_reconstruction_defect,x.budgets_all_pass,l.ordinary.R_mu, ...
      l.ordinary.R_k,l.seconds.total);
  end
  fclose(fid);
end

function LOCAL_write_pilot(path,pilot)
  fid = fopen(path,'w'); assert(fid>=0,'i96:IO','Cannot create pilot.csv.');
  fprintf(fid,'round,active,active_level_max,pending,degenerate,score,pieces_done,pending_pieces,seconds,clock\n');
  if isfield(pilot,'engine')
    for r = pilot.engine.rounds(:)'
      fprintf(fid,'%d,%d,%d,%d,%d,%.17e,%d,%d,%.4f,%.4f\n',r.round,r.active,r.active_level_max, ...
        r.pending,r.degenerate,r.score,r.pieces_done,r.pending_pieces,r.seconds,r.clock);
    end
  end
  fclose(fid);
end

function status = LOCAL_figures_d2(ctx,native,levels,infos,pilot)
  status = struct('files',{{}},'errors',{{}});
  dir = fullfile(ctx.output_dir,'figures');
  % 1. cell masses
  try
    f = figure('Visible','off','Position',[100,100,600,380]);
    idx = native.summary.cell_index; m = native.summary.cell_mass; [idx,o] = sort(idx);
    semilogy(idx,max(m(o),realmin),'o-'); grid on; xlabel('cell index'); ylabel('unweighted cell mass');
    title('normalised source-field cell masses');
    LOCAL_export(f,fullfile(dir,'cells.png')); status.files{end+1} = 'cells.png';
  catch e, status.errors{end+1} = ['cells: ',e.message]; end
  % 2. mode contributions (upper ends)
  try
    f = figure('Visible','off','Position',[100,100,900,380]);
    for L = 1:numel(infos)
      subplot(1,numel(infos),L); T = infos(L).modes;
      semilogy(T.m,max(T.source_energy,realmin),'.',T.m,max(T.w2_hi,realmin),'.', ...
        T.m,max(T.vw2_hi,realmin),'.',T.m,max(T.Td2_hi,realmin),'.');
      grid on; xlabel('m'); title(sprintf('%s level',infos(L).level));
      legend('source |f_m|^2','||w_m||^2 upper','||v_m-w_m||^2 upper','T_d^2 upper','Location','southoutside');
    end
    LOCAL_export(f,fullfile(dir,'modes.png')); status.files{end+1} = 'modes.png';
  catch e, status.errors{end+1} = ['modes: ',e.message]; end
  % 3. engine scores per round (pilot and levels)
  try
    f = figure('Visible','off','Position',[100,100,900,380]); hold on;
    if isfield(pilot,'engine')
      semilogy([pilot.engine.rounds.round],max([pilot.engine.rounds.score],realmin),'ko-','DisplayName','pilot');
    end
    for L = 1:numel(levels)
      if ~levels(L).completed, continue, end
      for E = levels(L).engine(:)'
        semilogy([E.rounds.round],max([E.rounds.score],realmin),'o-','DisplayName',[levels(L).name,' ',E.template]);
      end
    end
    set(gca,'YScale','log'); grid on; xlabel('round'); ylabel('pending moment score');
    legend('Location','eastoutside'); title('reference engine tightening');
    LOCAL_export(f,fullfile(dir,'engine.png')); status.files{end+1} = 'engine.png';
  catch e, status.errors{end+1} = ['engine: ',e.message]; end
  % 4. bound terms per level (exact column)
  try
    f = figure('Visible','off','Position',[100,100,800,380]);
    labels = {'\delta_u','E_v','c_R E_R','moment','E_y/b_M','\epsilon_0','R_\mu','R_k'};
    vals = nan(numel(levels),numel(labels));
    for L = 1:numel(levels)
      if ~levels(L).completed, continue, end
      x = levels(L).exact;
      vals(L,:) = [x.delta_u(2),x.E_v(2),x.c_R_E_R,x.moment_term,x.E_y_over_b_M,x.eps0,x.R_mu,x.R_k];
    end
    bar(max(vals',realmin)); set(gca,'YScale','log','XTickLabel',labels); grid on;
    legend({levels.name},'Location','northwest'); title('EXACT\_ARITHMETIC\_UPPER\_BOUND terms');
    LOCAL_export(f,fullfile(dir,'terms.png')); status.files{end+1} = 'terms.png';
  catch e, status.errors{end+1} = ['terms: ',e.message]; end
end

function LOCAL_export(f,path)
  exportgraphics(f,path,'Resolution',150); close(f);
end

function ledger = LOCAL_ledger()
  ledger = struct('selftest',0,'native_adapter',0,'pilot',0,'level_stageA',0,'level_engine',0, ...
    'level_aggregate',0,'level_correction',0,'level_norms',0,'level_save',0,'figures',0,'save',0);
end

function timing = LOCAL_ledger_close(ledger,total)
  timing = ledger; values = struct2cell(ledger);
  timing.attributed_seconds = sum([values{:}]);
  timing.matlab_function_seconds = total;
  timing.matlab_unattributed_seconds = total-timing.attributed_seconds;
end

function LOCAL_progress(ctx,phase,predicted)
  value = struct('matlab_elapsed',toc(ctx.started),'phase',phase, ...
    'predicted_remaining_seconds',predicted, ...
    'save_estimate_seconds',ctx.config.resources.save_estimate_seconds,'rss_bytes',LOCAL_rss());
  temporary = [ctx.progress_path,'.tmp'];
  LOCAL_json(temporary,value); movefile(temporary,ctx.progress_path,'f');
end

function LOCAL_partial(ctx,levels,pilot,ledger)
  short = levels;
  for L = 1:numel(short)
    if isfield(short,'engine') && short(L).completed
      short(L).engine = rmfield(short(L).engine,'rounds');
    end
  end
  LOCAL_json(fullfile(ctx.output_dir,'partial-result.json'),struct('levels',short, ...
    'pilot',pilot,'timing',LOCAL_ledger_close(ledger,toc(ctx.started))));
end

function list = LOCAL_append_union(list,item)
  % Append a struct whose field set may differ (skipped vs completed levels):
  % missing fields are filled with [] on both sides, order unified.
  if isempty(list), list = item; return, end
  fl = fieldnames(list); fi = fieldnames(item);
  for f = setdiff(fi,fl)', [list.(f{1})] = deal([]); end
  for f = setdiff(fl,fi)', item.(f{1}) = []; end
  list = orderfields(list); item = orderfields(item); list(end+1) = item;
end

%% ==================== D2 level driver: stage A, engine, correction, norms, assembly ====================
% One evaluation level: prediction/bulk pass of the three templates, reference
% engine with deadlines, source-moment enclosure and the one-time correction,
% Fourier correction, Yukawa norms and the level status machine.
function [LV,info] = LOCAL_level_d2(ctx,native,lev,common,engine_deadline)
  config = ctx.config; clock = @()toc(ctx.started); N = lev.N;
  names = {'left','center','right'};
  block_dir = fullfile(ctx.output_dir,'blocks',lev.name);
  if ~isfolder(block_dir), mkdir(block_dir); end
  t_level = tic; sec = struct('stageA',0,'engine',0,'aggregate',0,'correction',0,'norms',0,'save',0);
  % --- stage A: prediction pass, bulk sums, coefficient/Fourier files ---
  opt = struct('strips',0:lev.strip_columns:N-1,'block_dir',block_dir, ...
    'batch_modes',config.norms.batch_modes,'S0',config.engine.S0);
  SAs = struct([]);
  for k = 1:3
    ts = tic; SA = LOCAL_stageA(ctx,native,lev,common,names{k},opt);
    sec.stageA = sec.stageA+toc(ts);
    fprintf(['  STAGEA %s %s: %d special (%d curved, %d tube-hit affine), %d special rects, %d points, ', ...
      'mismatch %d, %.1f MB files, %.2fs\n'],lev.name,names{k},SA.census.n_special,SA.census.n_curved, ...
      SA.census.n_tube_hit_affine,SA.nsr,SA.stats.points,SA.material_mismatch_nonspecial, ...
      SA.stats.bytes/1e6,toc(ts));
    SAs = LOCAL_append(SAs,SA);
    LOCAL_memory_gate(config,'after stage A',0);
  end
  % --- reference engine per template (deadline shared by special count) ---
  BG = struct('b2',LOCAL_bern_inv(2),'b4',LOCAL_bern_inv(4),'b8',LOCAL_bern_inv(8));
  nspec = arrayfun(@(S)S.census.n_special,SAs); Es = cell(1,3); As = cell(1,3);
  for k = 1:3
    share = nspec(k)/max(sum(nspec(k:3)),1);             % unused time carries over
    eopt = LOCAL_engine_opt(config,common,clock,clock()+share*max(engine_deadline-clock(),0), ...
      nspec(k)/max(sum(nspec),1));
    te = tic; Es{k} = LOCAL_engine(SAs(k).TL,SAs(k).CT,BG,eopt); sec.engine = sec.engine+toc(te);
    ta = tic; As{k} = LOCAL_eng_aggregate(SAs(k).TL,Es{k},SAs(k).CT,SAs(k).VT,BG,true);
    sec.aggregate = sec.aggregate+toc(ta);
    fprintf(['  ENGINE %s %s: stop %s, %d rounds, level<=%d, terminal %d, records F %d P %d, ', ...
      'coverage F %.2e P %.2e, %.2fs (+%.2fs aggregate)\n'],lev.name,names{k},Es{k}.stop, ...
      numel(Es{k}.rounds),Es{k}.counts.level_max,Es{k}.counts.terminal_pieces,Es{k}.counts.records_F, ...
      Es{k}.counts.records_P,Es{k}.coverage.F_max_relative_defect,Es{k}.coverage.P_max_relative_defect, ...
      toc(te)-toc(ta),toc(ta));
    LOCAL_memory_gate(config,'after engine',0);
  end
  % --- source-moment enclosure (complex boxes D +- rad on special rects) ---
  D = cell(1,3); RAD = cell(1,3);
  for k = 1:3, D{k} = SAs(k).DB+As{k}.dcert; RAD{k} = As{k}.rad; end
  M0 = LOCAL_moments(SAs,D,RAD,common,false);
  M1 = LOCAL_moments(SAs,D,RAD,common,true);
  corr = struct('T0',M0.term,'T1',M1.term,'b',common.b,'decision','','applied',false, ...
    'delta_max',0,'delta_l2',0);
  if M0.term<=common.b
    corr.decision = 'NOT_NEEDED_T0_WITHIN_BUDGET';
  elseif M1.term<=common.b
    corr.decision = 'REGULAR_T1_WITHIN_BUDGET'; corr.applied = true;
  elseif M1.term<M0.term
    corr.decision = 'FINAL_INTERVAL_T1_ABOVE_BUDGET'; corr.applied = true;
  else
    corr.decision = 'NOT_APPLIED_NO_REDUCTION';
  end
  fprintf('  MOMENTS %s: T0=%.3e T1=%.3e b=%.1e -> %s\n',lev.name,M0.term,M1.term,common.b,corr.decision);
  % reliable squared integrals per template and cell (uncorrected coefficients)
  Ir = LOCAL_integrals(SAs,As,[]);
  if corr.applied
    tc = tic; Ir0 = Ir; Delta = D; As2 = cell(1,3);
    if ~isfield(SAs,'corr_files'), [SAs.corr_files] = deal({}); end
    for k = 1:3
      CTc = SAs(k).CT+Delta{k};
      As2{k} = LOCAL_eng_aggregate(SAs(k).TL,Es{k},CTc,SAs(k).VT,BG,false);
      Gb = LOCAL_sym_full(SAs(k).Gb,4); nc = SAs(k).TL.ncell;
      for c = 1:nc
        dl = Delta{k}(:,:,c);
        GD = reshape(sum(Gb.*reshape(dl,[],1,4),3),[],4);
        SAs(k).IfbR(:,c) = SAs(k).IfbR(:,c)-2*real(sum(conj(dl).*SAs(k).DB(:,:,c),2)) ...
          +real(sum(conj(dl).*GD,2));
      end
      SAs(k) = LOCAL_fourier_correction(SAs(k),Delta{k},lev,common,block_dir,config.norms.batch_modes);
      SAs(k).CT = CTc; D{k} = D{k}-Delta{k};
      corr.delta_max = max(corr.delta_max,max(abs(Delta{k}),[],'all'));
      corr.delta_l2 = sqrt(corr.delta_l2^2+sum(abs(Delta{k}).^2,'all'));
    end
    Ir = LOCAL_integrals(SAs,As2,As);
    corr.If_before = Ir0.If; corr.If_after = Ir.If;
    sec.correction = toc(tc);
    Mf = LOCAL_moments(SAs,D,RAD,common,false);
  else
    Mf = M0; Delta = cell(1,3);
  end
  corr.moments_before = M0; corr.moments_centered_prediction = M1; corr.moments_final = Mf;
  % --- mode-batched Fourier/Yukawa norms with explicit remainders ---
  tn = tic;
  NR = LOCAL_norms_level(ctx,SAs,lev,common,block_dir,config.norms.batch_modes,config.norms.taylor_n);
  tay_w = LOCAL_taylor_width(NR);
  if tay_w>config.norms.taylor_budget_fraction*common.b
    fprintf('  NORMS %s: Taylor width %.3e > %.2f b, degree %d\n',lev.name,tay_w, ...
      config.norms.taylor_budget_fraction,config.norms.taylor_n_max);
    NR = LOCAL_norms_level(ctx,SAs,lev,common,block_dir,config.norms.batch_modes,config.norms.taylor_n_max);
    tay_w = LOCAL_taylor_width(NR);
  end
  NR.taylor_width_estimate = tay_w;
  NR.ordinary_ER2 = sum(arrayfun(@(S)sum(S.cs.ER2_ord),SAs));
  NR.ordinary_du2 = sum(arrayfun(@(S)sum(S.cs.du2_ord),SAs));
  sec.norms = toc(tn);
  fprintf('  NORMS %s: %d batches, n=%d, %.2fs (io %.2fs), negative column tails F %d V %d\n', ...
    lev.name,NR.batches,NR.taylor_n,NR.seconds,NR.io_seconds,NR.negative_column_tail_upper);
  % --- level assembly and status ---
  checks = LOCAL_level_checks(config,SAs,Es,common);
  LV = LOCAL_combine_d2(config,lev,common,Ir,Mf,NR,checks,corr);
  LV.engine = struct([]); LV.stageA = struct([]);
  for k = 1:3
    E = Es{k}; S = SAs(k);
    LV.engine = LOCAL_append(LV.engine,struct('template',E.template,'stop',E.stop,'counts',E.counts, ...
      'seconds',E.seconds,'coverage',E.coverage,'rounds',E.rounds));
    LV.stageA = LOCAL_append(LV.stageA,struct('template',S.name, ...
      'census',rmfield(S.census,{'special','inside','curved'}),'nsr',S.nsr, ...
      'stats',rmfield(S.stats,'files'),'geo_checks',S.geo_checks, ...
      'material_mismatch_nonspecial',S.material_mismatch_nonspecial,'seconds',S.seconds, ...
      'geometry_seconds',S.geometry_seconds));
  end
  % --- audit storage: special rectangles, intervals, correction, records ---
  tsv = tic; index = struct([]);
  for k = 1:3
    S = SAs(k); E = Es{k};
    sp = struct('template',S.name,'cells',S.cells,'srect_col',S.TL.srect_col,'srect_row',S.TL.srect_row, ...
      'CT_final',S.CT,'VT',S.VT,'DB',S.DB,'Gb',S.Gb,'IfbR_final',S.IfbR,'D_center_final',D{k}, ...
      'D_radius',RAD{k},'Delta',LOCAL_empty_if(Delta{k}),'special',find(S.TL.special), ...
      'nodes_e',E.nodes.e,'nodes_R',E.nodes.R,'Jhi',E.Jhi,'Snode',E.Snode,'recF',E.recF,'recP',E.recP, ...
      'accF_key',E.accF.key,'accF_val',E.accF.val,'accF_rkey',E.accF.rkey,'accF_rval',E.accF.rval, ...
      'accP_key',E.accP.key,'accP_val',E.accP.val,'accP_rkey',E.accP.rkey,'accP_rval',E.accP.rval, ...
      'cs',S.cs,'colEF',S.colEF,'colEV',S.colEV,'n1F',S.n1F,'n1V',S.n1V,'rJ',S.rJ,'J',S.J);
    file = fullfile(block_dir,sprintf('special_%s.mat',S.name));
    save(file,'-struct','sp','-v7.3');
    for f = 1:numel(S.stats.files)
      cf = [S.stats.files{f}(1:end-4),'_corr.mat'];
      index = LOCAL_append(index,struct('level',lev.name,'template',S.name,'kind','strip', ...
        'file',LOCAL_relpath(ctx,S.stats.files{f}),'correction_file',LOCAL_relpath(ctx,cf,isfile(cf)), ...
        'cells',S.cells,'first_column',(f-1)*lev.strip_columns));
    end
    index = LOCAL_append(index,struct('level',lev.name,'template',S.name,'kind','special', ...
      'file',LOCAL_relpath(ctx,file),'correction_file','','cells',S.cells,'first_column',NaN));
  end
  sec.save = toc(tsv);
  LV.block_index = index;
  LV.block_bytes = LOCAL_dir_bytes(block_dir);
  sec.total = toc(t_level); LV.seconds = sec;
  info = struct('mode_table',NR.modes,'cell_table',LOCAL_cell_table_d2(SAs,Ir,NR,lev));
end

function eopt = LOCAL_engine_opt(config,common,clock,deadline,target_share)
  E = config.engine;
  eopt = struct('start_level',E.start_level,'level_limit',E.level_limit,'piece_limit',E.piece_limit, ...
    'target',E.target_fraction*common.b*target_share,'refine_fraction',E.refine_fraction, ...
    'fallback_every',E.fallback_every,'clock',clock,'deadline',deadline,'CG',common.CG, ...
    'chunk_items',E.chunk_items,'config',config,'duffy_F',E.duffy_F,'duffy_P',E.duffy_P, ...
    'post_factor',3,'elements',[]);
end

function M = LOCAL_moments(SAs,D,RAD,common,centered)
  % delta_c = (sum e^2)^(1/2), delta_1 = sum e ||phi||_1 over all rectangles
  % and cells; e = max modulus of the complex box (Re D +- rad, Im D +- rad).
  % Non-special rectangles: exact point values (bulk sums). centered: the box
  % after the shift by its own centre (e = sqrt(2) rad).
  h = 1/SAs(1).TL.N; phi_l1 = h*[1,sqrt(3)/2,sqrt(3)/2,3/4];
  sq = 0; l1 = 0; emax = 0; sq_ns = 0; l1_ns = 0;
  for k = 1:numel(SAs)
    sq_ns = sq_ns+sum(SAs(k).cs.dns_sq); l1_ns = l1_ns+sum(SAs(k).cs.dns_l1);
    if centered, c = 0*D{k}; else, c = D{k}; end
    e = sqrt((abs(real(c))+RAD{k}).^2+(abs(imag(c))+RAD{k}).^2);
    sq = sq+sum(e.^2,'all'); l1 = l1+sum(e.*phi_l1,'all'); emax = max([emax;e(:)]);
  end
  dc = sqrt(sq+sq_ns); d1 = l1+l1_ns;
  M = struct('delta_c',dc,'delta_1',d1,'term_c',dc/common.shift_floor,'term_1',common.CG*d1, ...
    'term',min(dc/common.shift_floor,common.CG*d1),'e_max_special',emax, ...
    'nonspecial_delta_c',sqrt(sq_ns),'nonspecial_delta_1',l1_ns,'centered',centered);
end

function Ir = LOCAL_integrals(SAs,As,Ap)
  % [I-, I+] of int |f - f~_R|^2 and int |u - v_R|^2 over all templates and
  % cells. As: F aggregates (current coefficients); Ap: optional earlier
  % aggregates carrying the P (field) parts (unchanged by the correction).
  If = [0,0]; Iu = [0,0]; per = struct([]);
  for k = 1:numel(SAs)
    S = SAs(k); A = As{k}; if isempty(Ap), P = A; else, P = Ap{k}; end
    fl = S.cs.If_bulk_ns+sum(S.IfbR,1)+A.If_cert; fu = fl+A.If_unc;
    ul = S.cs.Iu_affine+P.Iu_cert; uu = ul+P.Iu_unc;
    If = If+[sum(fl),sum(fu)]; Iu = Iu+[sum(ul),sum(uu)];
    per = LOCAL_append(per,struct('template',S.name,'cells',S.cells,'If_lo',fl,'If_hi',fu, ...
      'Iu_lo',ul,'Iu_hi',uu,'If_unc',A.If_unc,'Iu_unc',P.Iu_unc,'If_cert_special',A.If_cert, ...
      'If_bulk',S.cs.If_bulk_ns+sum(S.IfbR,1),'Iu_affine',S.cs.Iu_affine,'Iu_cert_curved',P.Iu_cert));
  end
  Ir = struct('If',If,'Iu',Iu,'per_template',per);
end

function w = LOCAL_taylor_width(NR)
  % Taylor-remainder part of the w-norm widths (relative to the D0 scale).
  w = NR.acc_scalars.taylor_part_w2/max(2*sqrt(max(NR.Iw_box(1),eps)),eps);
end

function checks = LOCAL_level_checks(config,SAs,Es,common)
  % Coverage and consistency checks that qualify the enclosure as complete.
  tol = config.engine.coverage_tolerance; Q = LOCAL_duffy(3);
  covF = max(cellfun(@(E)E.coverage.F_max_relative_defect,Es));
  covP = max(cellfun(@(E)E.coverage.P_max_relative_defect,Es));
  area_def = zeros(1,3); dropped = zeros(1,3); mism = zeros(1,3);
  for k = 1:3
    TL = SAs(k).TL; sp = find(TL.special);
    [~,~,J] = LOCAL_p2_points(TL,repmat(sp,1,numel(Q.w)),repmat(Q.x,numel(sp),1),repmat(Q.y,numel(sp),1));
    area_sp = sum(J*Q.w');
    % the non-special base-point area is accumulated over strips (one rect
    % column range per strip): every point once
    area_def(k) = SAs(k).stats.area_nonspecial+area_sp-1;
    dropped(k) = SAs(k).stats.dropped_area; mism(k) = SAs(k).material_mismatch_nonspecial;
  end
  missing = {};
  if covF>tol, missing{end+1} = sprintf('F coverage defect %.3e',covF); end
  if covP>tol, missing{end+1} = sprintf('P coverage defect %.3e',covP); end
  if any(abs(area_def)>tol), missing{end+1} = sprintf('template area defect %.3e',max(abs(area_def))); end
  if any(dropped>tol), missing{end+1} = sprintf('dropped bulk area %.3e',max(dropped)); end
  checks = struct('coverage_F_max_relative',covF,'coverage_P_max_relative',covP, ...
    'template_area_defect',area_def,'dropped_bulk_area',dropped,'material_mismatch_nonspecial',mism, ...
    'complete',isempty(missing),'missing',{missing},'tolerance',tol, ...
    'engine_stops',{cellfun(@(E)E.stop,Es,'UniformOutput',false)});
end

function LV = LOCAL_combine_d2(config,lev,common,Ir,Mf,NR,checks,corr)
  % Design D2 Sections 3 and 6: exact-arithmetic enclosure column, budgets,
  % status machine; ordinary column from the prediction quadrature.
  h = 1/lev.N; M = lev.M; c_R = sqrt(h^4+h^4)/pi^2; b_M = common.s+(2*pi*(M+1)-abs(common.beta))^2;
  b = common.b; sq = @(I)sqrt(max(I,0));
  E_R = sq(Ir.If); delta_u = sq(Ir.Iu);
  Ey2 = NR.Ey2_interval_raw; Tv2 = NR.Tv2_interval_raw;
  inconsistent = Ey2(2)<0 || Tv2(2)<0;
  Ey2c = [max(Ey2(1),0),max(Ey2(2),0)]; Tv2c = [max(Tv2(1),0),max(Tv2(2),0)];
  E_y = sq(Ey2c);
  Ev2 = [NR.Ivw_box(1)+NR.Td2(1)+Tv2c(1),NR.Ivw_box(2)+NR.Td2(2)+Tv2c(2)];
  D02 = [NR.Iw_box(1)+NR.Td2(1),NR.Iw_box(2)+NR.Td2(2)];
  E_v = sq(Ev2); D0 = sq(D02);
  eps_alg = 0;
  eps0 = c_R*E_R(2)+Mf.term+E_y(2)/b_M+eps_alg;
  den = D0(1)-eps0;
  x = struct('identity','EXACT_ARITHMETIC_UPPER_BOUND', ...
    'rounding_note','floating-point rounding is not certified; all non-rounding errors enter the intervals', ...
    'E_R',E_R,'If',Ir.If,'delta_u',delta_u,'Iu',Ir.Iu,'E_y',E_y,'E_y_squared_interval_raw',Ey2, ...
    'T_v',sq(Tv2c),'T_v_squared_interval_raw',Tv2,'E_v',E_v,'D0',D0,'T_d_squared',NR.Td2, ...
    'w2_in_box',NR.Iw_box,'vw2_in_box',NR.Ivw_box,'delta_c',Mf.delta_c,'delta_1',Mf.delta_1, ...
    'moment_term_c',Mf.term_c,'moment_term_1',Mf.term_1,'moment_term',Mf.term,'CG',common.CG, ...
    'shift_floor',common.shift_floor,'c_R',c_R,'b_M',b_M,'c_R_E_R',c_R*E_R(2),'E_y_over_b_M',E_y(2)/b_M, ...
    'eps_alg',eps_alg,'eps_alg_attribution',['all series/Taylor remainders (sph. Bessel factors, ', ...
    'gamma01, Taylor exponentials) are propagated into the F/V radii and the norm intervals; eps_alg = 0'], ...
    'eps0',eps0,'denominator',den,'denominator_positive',den>0,'R_mu',NaN,'R_k',NaN, ...
    'lower_reconstruction_defect',max(0,E_v(1)-delta_u(2)-eps0), ...
    'lower_note','max{0, E_v^- - delta_u^+ - eps0^+} <= ||u - w||_0 (fixed-field reconstruction defect, not a spectral lower bound)', ...
    'status','','reason','','contributions',struct());
  wid = @(v)v(2)-v(1);
  budgets = struct('moment_term_plus_eps_alg',[Mf.term+eps_alg,b],'width_delta_u',[wid(delta_u),b], ...
    'width_E_v',[wid(E_v),b],'width_D0',[wid(D0),b],'c_R_width_E_R',[c_R*wid(E_R),b], ...
    'width_E_y_over_b_M',[wid(E_y)/b_M,b]);
  bn = fieldnames(budgets); bp = cellfun(@(f)budgets.(f)(1)<=budgets.(f)(2),bn);
  x.budgets = budgets; x.budget_pass = cell2struct(num2cell(bp),bn,1); x.budgets_all_pass = all(bp);
  x.failed_budgets = bn(~bp)';
  if ~checks.complete || any(~isfinite([E_R,delta_u,E_v,D0,Mf.term]))
    x.status = 'INTEGRATION_CONTROL_UNRESOLVED'; x.reason = strjoin(checks.missing,'; ');
  elseif inconsistent
    x.status = 'EVALUATION_INCONSISTENCY';
    x.reason = sprintf('Parseval interval wholly negative: E_y^2 %s, T_v^2 %s',mat2str(Ey2,4),mat2str(Tv2,4));
  elseif den<=0
    x.status = 'DENOMINATOR_NOT_POSITIVE'; x.reason = sprintf('D0^- = %.6e <= eps0^+ = %.6e',D0(1),eps0);
  else
    x.R_mu = common.C_rho*(delta_u(2)+E_v(2)+eps0)/den;
    x.R_k = LOCAL_rk(common.k,common.mu,x.R_mu);
    scale = common.C_rho/den;
    x.contributions = struct('E_v',scale*E_v(2),'delta_u',scale*delta_u(2),'c_R_E_R',scale*c_R*E_R(2), ...
      'moment_term',scale*Mf.term,'E_y_over_b_M',scale*E_y(2)/b_M,'eps_alg',scale*eps_alg);
    if ~x.budgets_all_pass
      x.status = 'VALID_BOUND_EVALUATION_NOT_RESOLVED';
      x.reason = ['evaluation budgets not met: ',strjoin(x.failed_budgets,', ')];
    elseif x.R_k>common.resolution_target_k
      x.status = 'VALID_BOUND_RESOLUTION_NOT_MET'; x.reason = sprintf('R_k = %.3e > %.0e',x.R_k,common.resolution_target_k);
    else
      x.status = 'VALID_BOUND_RESOLUTION_TARGET_MET'; x.reason = sprintf('R_k = %.3e <= %.0e',x.R_k,common.resolution_target_k);
    end
  end
  % ordinary column: prediction quadrature (uncorrected coefficients for
  % E_R, delta_u), corrected Fourier data, mid values without radii
  o = LOCAL_ordinary_d2(lev,common,NR,c_R,b_M);
  LV = struct('name',lev.name,'N',lev.N,'M',M,'h',h,'modes',2*M+1,'mu',common.mu,'k',common.k, ...
    's',common.s,'C_rho',common.C_rho,'U0',common.U0,'b',b,'exact',x,'ordinary',o, ...
    'correction',corr,'checks',checks,'integrals_per_template',Ir.per_template, ...
    'norms',rmfield(NR,{'modes','cell'}),'completed',true,'skip_reason','');
end

function o = LOCAL_ordinary_d2(lev,common,NR,c_R,b_M)
  o = struct('identity','ORDINARY_ESTIMATE','E_R',sqrt(max(NR.ordinary_ER2,0)), ...
    'delta_u',sqrt(max(NR.ordinary_du2,0)),'E_y',sqrt(max(NR.Ey2_raw,0)),'E_y_squared_raw',NR.Ey2_raw, ...
    'T_v_squared_raw',NR.Tv2_raw,'E_v',sqrt(NR.ordinary.vw2_in_box+NR.ordinary.Td2+max(NR.Tv2_raw,0)), ...
    'D0',sqrt(NR.ordinary.w2_in_box+NR.ordinary.Td2),'check_w2_12',NR.ordinary.check_w2_12, ...
    'check_vw2_12',NR.ordinary.check_vw2_12, ...
    'note','prediction quadrature without moment-error term (not an upper bound)');
  o.eps0 = c_R*o.E_R+o.E_y/b_M; den = o.D0-o.eps0; o.R_mu = NaN; o.R_k = NaN;
  if den>0
    o.R_mu = common.C_rho*(o.delta_u+o.E_v+o.eps0)/den; o.R_k = LOCAL_rk(common.k,common.mu,o.R_mu);
  end
  o.N = lev.N;
end

function LV = LOCAL_skipped_level_d2(lev,common,reason)
  LV = struct('name',lev.name,'N',lev.N,'M',lev.M,'h',1/lev.N,'modes',2*lev.M+1,'mu',common.mu, ...
    'k',common.k,'s',common.s,'C_rho',common.C_rho,'U0',common.U0,'b',common.b, ...
    'exact',struct('identity','EXACT_ARITHMETIC_UPPER_BOUND','status','NOT_EVALUATED','reason',reason, ...
    'R_mu',NaN,'R_k',NaN),'ordinary',struct('identity','ORDINARY_ESTIMATE','R_mu',NaN,'R_k',NaN), ...
    'completed',false,'skip_reason',reason);
end

function T = LOCAL_cell_table_d2(SAs,Ir,NR,lev)
  % Per cell: reliable squared-defect intervals, prediction diagnostics,
  % w/v-w box contributions (upper) and Parseval tails (mid).
  T = struct([]);
  for k = 1:numel(SAs)
    S = SAs(k); P = Ir.per_template(k);
    for c = 1:numel(S.cells)
      j = find(NR.cell.index==S.cells(c));
      T = LOCAL_append(T,struct('level',lev.name,'cell',S.cells(c),'template',S.name, ...
        'mass',S.cs.mass(c),'mass_matrix',S.cs.mass_matrix(c),'If_lo',P.If_lo(c),'If_hi',P.If_hi(c), ...
        'Iu_lo',P.Iu_lo(c),'Iu_hi',P.Iu_hi(c),'If_unc',P.If_unc(c),'Iu_unc',P.Iu_unc(c), ...
        'ER2_ordinary',S.cs.ER2_ord(c),'du2_ordinary',S.cs.du2_ord(c), ...
        'w2_box_hi',NR.cell.w2_hi(j),'vw2_box_hi',NR.cell.vw2_hi(j), ...
        'tailF_mid',NR.cell.tailF_mid(j),'tailV_mid',NR.cell.tailV_mid(j), ...
        'dns_max',S.cs.dns_max(c)));
    end
  end
end

function x = LOCAL_empty_if(x)
  if isempty(x), x = zeros(0,1); end
end

function r = LOCAL_relpath(ctx,file,exists)
  if nargin>2 && ~exists, r = ''; return, end
  r = strrep(file,[ctx.output_dir,filesep],'');
end

function bytes = LOCAL_dir_bytes(d)
  f = dir(fullfile(d,'*.mat')); bytes = sum([f.bytes]);
end

%% ==================== D2 stage A: prediction pass, census and reliable bulk ====================
% One strip pass per template: predicted Q1/Q2 coefficients (ordinary), exact bulk
% defects of non-special elements, Fourier moments and chunked storage.
function geo = LOCAL_template_geometry(config,t,common,lev)
  % Element data, curved-edge chord->arc slivers and true-material slivers
  % (ordinary prediction only). D2 fix (design 4.1.1): the rectangle of every
  % true-sliver point is that of the actual point Q = p + tau (c - p), not of
  % the sub-interval midpoint pm; the number of differing points is recorded.
  I = config.integration; h = 1/lev.N; x0 = t.cell-0.5; mu = common.mu; s = common.s;
  nt = size(t.tri6,1);
  X6 = reshape(t.xy(t.tri6,1),nt,6); Y6 = reshape(t.xy(t.tri6,2),nt,6);
  P1 = [X6(:,1),Y6(:,1)]; E1 = [X6(:,2),Y6(:,2)]-P1; E2 = [X6(:,3),Y6(:,3)]-P1;
  detJ = E1(:,1).*E2(:,2)-E1(:,2).*E2(:,1);
  inv = [E2(:,2),-E2(:,1),-E1(:,2),E1(:,1)]./detJ;     % [xi;eta] = [i1 i2; i3 i4]*(x-P1)
  mids = [(X6(:,1)+X6(:,2))/2,(X6(:,2)+X6(:,3))/2,(X6(:,3)+X6(:,1))/2];
  midy = [(Y6(:,1)+Y6(:,2))/2,(Y6(:,2)+Y6(:,3))/2,(Y6(:,3)+Y6(:,1))/2];
  bend = hypot(X6(:,4:6)-mids,Y6(:,4:6)-midy);
  curved_edge = bend>1e-14;
  geo = struct('nt',nt,'X6',X6,'Y6',Y6,'P1',P1,'inv',inv,'detJ',detJ, ...
    'xmin',min(X6(:,1:3),[],2),'xmax',max(X6(:,1:3),[],2), ...
    'ymin',min(Y6(:,1:3),[],2),'ymax',max(Y6(:,1:3),[],2), ...
    'curved',any(curved_edge,2),'material',t.material,'alpha',mu*t.material+s,'x0',x0,'h',h);
  % --- chord->arc slivers: P(t,tau) = A + t(B-A) + tau*D*t(1-t), det = cr*t(1-t) ---
  [tg,wg] = LOCAL_gauss01(I.sliver_t); [sg,ws] = LOCAL_gauss01(I.sliver_tau);
  [ee,qq] = find(curved_edge); chunks = cell(numel(ee),1);
  for k = 1:numel(ee)
    e = ee(k); q = qq(k); i1 = q; i2 = mod(q,3)+1;
    A = [X6(e,i1),Y6(e,i1)]; B = [X6(e,i2),Y6(e,i2)]; Mid = [X6(e,3+q),Y6(e,3+q)];
    D = 4*Mid-2*(A+B); cr = (B(1)-A(1))*D(2)-(B(2)-A(2))*D(1);
    rows = cell(numel(sg),1);
    for j = 1:numel(sg)
      tau = sg(j); c0 = A; c1 = (B-A)+tau*D; c2 = -tau*D;
      brk = LOCAL_quadratic_breaks(c0,c1,c2,x0,h);
      [tt,wt,tm,seg] = LOCAL_split_rule(brk,tg,wg);
      P = c0+c1.*tt+c2.*tt.^2; Pm = c0+c1.*tm(seg)+c2.*tm(seg).^2;
      w = -cr*tt.*(1-tt).*wt*ws(j);
      rows{j} = [P,w,Pm];
    end
    data = vertcat(rows{:});
    chunks{k} = [data(:,1:3),repmat(e,size(data,1),1),data(:,4:5)];
  end
  sl = vertcat(chunks{:});
  if isempty(sl), sl = zeros(0,6); end
  [col,row] = LOCAL_rect_of(sl(:,5),sl(:,6),x0,h,lev.N);
  a1 = geo.alpha(sl(:,4));
  geo.sliver = struct('x',sl(:,1),'y',sl(:,2),'w',sl(:,3),'elem',sl(:,4),'col',col,'row',row, ...
    'a1',a1,'a0',zeros(size(a1)),'z',zeros(size(a1)),'wu',sl(:,3),'wf',sl(:,3),'we',sl(:,3));
  % --- true-material slivers: Q = p(t) + tau(c(theta(t)) - p(t)) ---
  ifc = t.interface; [tg,wg] = LOCAL_gauss01(I.true_t); [sg,ws] = LOCAL_gauss01(I.true_tau);
  rho_in = t.rho_in; rho_out = common.rho_background; chunks = cell(numel(ifc.mid),1);
  side_change = 0;
  for k = 1:numel(ifc.mid)
    th = ifc.theta(k); dth = ifc.dtheta;
    A = LOCAL_curve(config,t.cell,th); B = LOCAL_curve(config,t.cell,th+dth); Mid = t.xy(ifc.mid(k),:);
    p1 = -3*A-B+4*Mid; p2 = 2*A+2*B-4*Mid;
    brk = unique([LOCAL_quadratic_breaks(A,p1,p2,x0,h);0.5]);
    [tt,wt,tm,seg] = LOCAL_split_rule(brk,tg,wg);
    % side of each sub-interval: c to the left of p' => region inside p => inner element
    pm = A+p1.*tm+p2.*tm.^2; dpm = p1+2*p2.*tm; cm = LOCAL_curve(config,t.cell,th+tm*dth);
    left = dpm(:,1).*(cm(:,2)-pm(:,2))-dpm(:,2).*(cm(:,1)-pm(:,1))>0;
    side_change = side_change+nnz(diff(left));
    p = A+p1.*tt+p2.*tt.^2; dp = p1+2*p2.*tt;
    c = LOCAL_curve(config,t.cell,th+tt*dth); dc = LOCAL_curve_derivative(config,t.cell,th+tt*dth)*dth;
    rows = cell(numel(sg),1);
    for j = 1:numel(sg)
      tau = sg(j); Q = p+tau*(c-p); Qt = dp+tau*(dc-dp); Qs = c-p;
      det = Qt(:,1).*Qs(:,2)-Qt(:,2).*Qs(:,1);
      w = -det.*wt*ws(j);
      el = ifc.outer(k)*ones(numel(tt),1); el(left(seg)) = ifc.inner(k);
      rows{j} = [Q,w,el,pm(seg,:)];
    end
    chunks{k} = vertcat(rows{:});
  end
  ts = vertcat(chunks{:});
  [col,row] = LOCAL_rect_of(ts(:,1),ts(:,2),x0,h,lev.N);           % actual Q (D2 fix)
  [colm,rowm] = LOCAL_rect_of(ts(:,5),ts(:,6),x0,h,lev.N);         % old D1 midpoint rule
  n = size(ts,1);
  geo.true_sliver = struct('x',ts(:,1),'y',ts(:,2),'w',ts(:,3),'elem',ts(:,4),'col',col,'row',row, ...
    'a1',(mu*rho_in+s)*ones(n,1),'a0',(mu*rho_out+s)*ones(n,1),'z',ones(n,1), ...
    'wu',zeros(n,1),'wf',ts(:,3),'we',ts(:,3));
  geo.true_sliver_side_changes = side_change;
  geo.true_sliver_rect_changed_by_Q = nnz(col~=colm | row~=rowm);
  % a Q point on a grid line (within 1e-14 h) is an ambiguous boundary point
  geo.true_sliver_boundary_ambiguous = nnz(abs(mod(ts(:,1)-x0+h/2,h)-h/2)<=1e-14*h | ...
    abs(mod(ts(:,2)+0.5+h/2,h)-h/2)<=1e-14*h);
end

function cen = LOCAL_census(TL,cv)
  % Special elements (design 4.1): curved, or quadratic control net not
  % rejected by every chord rectangle of the level-0 polyline (n_c = S0,
  % thickness delta0; the control net hull contains the element image).
  % Material of a non-special element: radial test against the curve's
  % radial range, otherwise chord-side test of the control-net centroid.
  nt = size(TL.X6,1); X6 = TL.X6; Y6 = TL.Y6;
  CX = [X6(:,1:3),2*X6(:,4:6)-(X6(:,[1,2,3])+X6(:,[2,3,1]))/2];
  CY = [Y6(:,1:3),2*Y6(:,4:6)-(Y6(:,[1,2,3])+Y6(:,[2,3,1]))/2];
  r = hypot(CX-cv.cx,CY-cv.cy);
  inside_far = max(r,[],2)<cv.rho_lo; outside_far = min(r,[],2)>cv.rho_hi;
  cand = find(~inside_far & ~outside_far);
  nc = cv.S0; dth = 2*pi/nc; delta = cv.M2*dth^2/8;
  hit = false(numel(cand),1);
  [ilo,ns] = LOCAL_curve_candidates(cv,CX(cand,:),CY(cand,:),2*sqrt(2)*delta/cv.rmin+1e-12,nc);
  for k = 0:max([ns;0])-1
    act = find(ns>k & ~hit);
    if isempty(act), continue, end
    seg = mod(ilo(act)+k,nc);
    Pa = LOCAL_cpoint(cv,seg*dth); Pb = LOCAL_cpoint(cv,(seg+1)*dth);
    ex = Pb(:,1)-Pa(:,1); ey = Pb(:,2)-Pa(:,2); len = hypot(ex,ey); ex = ex./len; ey = ey./len;
    nx = -ey; ny = ex; px = CX(cand(act),:)-Pa(:,1); py = CY(cand(act),:)-Pa(:,2);
    te = ex.*px+ey.*py; tn = nx.*px+ny.*py;
    rejected = all(te<-delta,2) | all(te>len+delta,2) | all(tn>delta,2) | all(tn<-delta,2);
    hit(act(~rejected)) = true;
  end
  special = TL.curved; special(cand(hit)) = true;
  inside = inside_far;
  q = cand(~hit); inside(q) = LOCAL_curve_side(cv,mean(CX(q,:),2),mean(CY(q,:),2),0);
  cen = struct('special',special,'inside',inside,'curved',TL.curved, ...
    'n_special',nnz(special),'n_curved',nnz(TL.curved),'n_tube_hit_affine',nnz(special & ~TL.curved), ...
    'n_radial_inside',nnz(inside_far),'n_radial_outside',nnz(outside_far), ...
    'n_tube_candidates',numel(cand),'level0_chords',nc,'level0_delta',delta, ...
    'CX',CX,'CY',CY);
end

function pts = LOCAL_strip_points(config,geo,lev,cols,duf)
  % Exact clipping of the straight (vertex) triangles by the rectangles of the
  % strip columns; full rectangles get 3x3 Gauss, other pieces a fan with the
  % 5x5 Duffy rule (exact to total degree 8 on affine pieces).
  h = geo.h; x0 = geo.x0; N = lev.N; j0 = cols(1); j1 = cols(end)+1; ncs = numel(cols);
  xa = x0+j0*h; xb = x0+j1*h;
  sel = find(geo.xmax>xa & geo.xmin<xb);
  clo = max(floor((geo.xmin(sel)-x0)/h),j0); chi = min(ceil((geo.xmax(sel)-x0)/h)-1,j1-1);
  cnt = max(chi-clo+1,0);
  tri = LOCAL_rep(sel,cnt); col = LOCAL_rep(clo,cnt)+((1:sum(cnt))'-LOCAL_rep(cumsum(cnt)-cnt,cnt)-1);
  PX = [geo.X6(tri,1:3),nan(numel(tri),6)]; PY = [geo.Y6(tri,1:3),nan(numel(tri),6)];
  pn = 3*ones(numel(tri),1);
  [PX,PY,pn] = LOCAL_clip(PX,PY,pn,1,x0+col*h,1);
  [PX,PY,pn] = LOCAL_clip(PX,PY,pn,1,x0+(col+1)*h,-1);
  keep = pn>=3; PX = PX(keep,:); PY = PY(keep,:); pn = pn(keep); tri = tri(keep); col = col(keep);
  ymin = min(PY,[],2); ymax = max(PY,[],2);
  rlo = max(floor((ymin+0.5)/h),0); rhi = min(ceil((ymax+0.5)/h)-1,N-1);
  cnt = max(rhi-rlo+1,0);
  own = LOCAL_rep((1:numel(tri))',cnt); row = LOCAL_rep(rlo,cnt)+((1:sum(cnt))'-LOCAL_rep(cumsum(cnt)-cnt,cnt)-1);
  PX = PX(own,:); PY = PY(own,:); pn = pn(own); tri = tri(own); col = col(own);
  [PX,PY,pn] = LOCAL_clip(PX,PY,pn,2,-0.5+row*h,1);
  [PX,PY,pn] = LOCAL_clip(PX,PY,pn,2,-0.5+(row+1)*h,-1);
  area = LOCAL_poly_area(PX,PY,pn);
  keep = pn>=3 & area>config.integration.min_piece_area_fraction*h^2;
  dropped_area = sum(abs(area(~keep & pn>=3)));
  PX = PX(keep,:); PY = PY(keep,:); pn = pn(keep); tri = tri(keep); col = col(keep);
  row = row(keep); area = area(keep);
  full = pn==4 & abs(area-h^2)<=1e-12*h^2;
  % full rectangles: 3x3 Gauss-Legendre
  g = [-sqrt(3/5),0,sqrt(3/5)]; gw = [5,8,5]/9; [gx,gy] = ndgrid(g,g); gww = gw'*gw;
  xc = x0+(col(full)+0.5)*h; yc = -0.5+(row(full)+0.5)*h;
  fx = xc+h/2*gx(:)'; fy = yc+h/2*gy(:)'; fw = repmat(h^2/4*gww(:)',numel(xc),1);
  ft = repmat(tri(full),1,9); fr = repmat(row(full)+N*(col(full)-j0)+1,1,9);
  % cut pieces: fan triangles with the Duffy rule
  cut = find(~full); ox = {}; oy = {}; ow = {}; ot = {}; orr = {}; min_fan = Inf;
  for k = 2:max([pn(cut);2])-1
    s = cut(pn(cut)>=k+1);
    if isempty(s), continue, end
    v1x = PX(s,1); v1y = PY(s,1); ax = PX(s,k)-v1x; ay = PY(s,k)-v1y; bx = PX(s,k+1)-v1x; by = PY(s,k+1)-v1y;
    dt = ax.*by-ay.*bx; min_fan = min([min_fan;dt]);
    ox{end+1} = v1x+ax.*duf.x+bx.*duf.y; %#ok<AGROW>
    oy{end+1} = v1y+ay.*duf.x+by.*duf.y; %#ok<AGROW>
    ow{end+1} = dt.*duf.w; %#ok<AGROW>
    ot{end+1} = repmat(tri(s),1,numel(duf.w)); %#ok<AGROW>
    orr{end+1} = repmat(row(s)+N*(col(s)-j0)+1,1,numel(duf.w)); %#ok<AGROW>
  end
  cat1 = @(a,b)[a(:);cell2mat(cellfun(@(c)c(:),b(:),'UniformOutput',false))];
  x = cat1(fx,ox); y = cat1(fy,oy); w = cat1(fw,ow); elem = cat1(ft,ot); rect = cat1(fr,orr);
  n = numel(x); alpha = geo.alpha(elem);
  pts = struct('x',x,'y',y,'w',w,'elem',elem,'rect',rect,'a1',alpha,'a0',zeros(n,1), ...
    'z',zeros(n,1),'wu',w,'wf',w,'we',w,'base',true(n,1));
  pts.stats = struct('pieces',numel(pn),'full',nnz(full),'cut',nnz(~full), ...
    'area',sum(area),'ncs',ncs,'dropped_area',dropped_area,'min_fan_det',min_fan);
end

function pts = LOCAL_add_slivers(pts,geo,cols,N)
  % Append the chord->arc and true-material sliver points of the strip columns
  % (ordinary prediction only; never used by the reliable sums).
  j0 = cols(1); j1 = cols(end);
  for name = {'sliver','true_sliver'}
    S = geo.(name{1}); k = S.col>=j0 & S.col<=j1;
    pts.x = [pts.x;S.x(k)]; pts.y = [pts.y;S.y(k)]; pts.w = [pts.w;S.w(k)];
    pts.elem = [pts.elem;S.elem(k)]; pts.rect = [pts.rect;S.row(k)+N*(S.col(k)-j0)+1];
    pts.a1 = [pts.a1;S.a1(k)]; pts.a0 = [pts.a0;S.a0(k)]; pts.z = [pts.z;S.z(k)];
    pts.wu = [pts.wu;S.wu(k)]; pts.wf = [pts.wf;S.wf(k)]; pts.we = [pts.we;S.we(k)];
    pts.base = [pts.base;false(nnz(k),1)];
  end
end

function SA = LOCAL_stageA(ctx,native,lev,common,name,opt)
  % Per template: geometry, census, special rectangles; per x-strip the
  % ordinary prediction (D1 projection with the Q fix), the exact bulk sums
  % of non-special elements, the chunked coefficient files and the analytic
  % y-Fourier moments with their series radii (design 4.1, 5.1, 7.1).
  %   opt.strips: list of strip start columns; opt.block_dir: '' = no files;
  %   opt.batch_modes: Fourier batch size of the files.
  config = ctx.config; N = lev.N; M = lev.M; h = 1/N; ncs0 = lev.strip_columns;
  t = native.templates.(name); sel = find(strcmp({native.cells.template},name));
  ncell = numel(sel); Coef = [native.cells(sel).coef]; cidx = [native.cells(sel).index];
  nc = config.field.cells_per_side;
  tt0 = tic;
  geo = LOCAL_template_geometry(config,t,common,lev);
  TL = LOCAL_template_level(config,native,t,lev,common,sel,geo,opt.S0);
  cen = LOCAL_census(TL,TL.curve);
  TL.special = cen.special;
  alpha_true = reshape(TL.alpha(1+cen.inside),[],1);   % valid for non-special elements
  mismatch = nnz(~cen.special & alpha_true~=geo.alpha);
  % special rectangles: grid cells meeting the control-net bbox widened by eta0
  e = find(cen.special); G0 = LOCAL_eng_items(TL,struct('e',e,'R',repmat([0,0,1,0,0,1],numel(e),1)));
  pad = max(G0.eta_x,G0.eta_y)+1e-14;
  c1 = max(floor((min(cen.CX(e,:),[],2)-pad-TL.x0)/h),0); c2 = min(floor((max(cen.CX(e,:),[],2)+pad-TL.x0)/h),N-1);
  r1 = max(floor((min(cen.CY(e,:),[],2)-pad-TL.y0)/h),0); r2 = min(floor((max(cen.CY(e,:),[],2)+pad-TL.y0)/h),N-1);
  mark = false(N,N);                                     % mark(row+1,col+1)
  for q = 1:numel(e), mark(r1(q)+1:r2(q)+1,c1(q)+1:c2(q)+1) = true; end
  srect_lin = find(mark)-1;                              % rect = row + N col
  TL.srect = zeros(N*N,1); TL.srect(srect_lin+1) = 1:numel(srect_lin); nsr = numel(srect_lin);
  scol = floor(srect_lin/N); srow = srect_lin-N*scol;
  TL.srect_col = scol; TL.srect_row = srow;
  geo_seconds = toc(tt0);
  % storage of the special rectangles (all cells of the template)
  CT = zeros(nsr,4,ncell,'like',1i); VT = zeros(nsr,9,ncell,'like',1i); DB = CT;
  Gb = zeros(nsr,10); IfbR = zeros(nsr,ncell);
  cs = struct('If_bulk_ns',zeros(1,ncell),'Iu_affine',zeros(1,ncell),'dns_sq',zeros(1,ncell), ...
    'dns_l1',zeros(1,ncell),'dns_max',zeros(1,ncell),'ER2_ord',zeros(1,ncell),'du2_ord',zeros(1,ncell), ...
    'mass',zeros(1,ncell),'mass_matrix',zeros(1,ncell),'source_energy',zeros(1,ncell), ...
    'field_energy',zeros(1,ncell));
  for q2 = 1:ncell, cs.mass_matrix(q2) = real(Coef(:,q2)'*t.M1*Coef(:,q2)); end
  % y-Fourier factors with series radii (sph_bessel; closed form for |x| >= 1)
  mvec = (-M:M)'; nm = numel(mvec); q = common.beta+2*pi*mvec; kappa = q*h/2;
  J = zeros(nm,3); rJ = zeros(nm,3);
  for b = 0:2
    [jb,rb] = LOCAL_sph_bessel(b,kappa);
    J(:,b+1) = sqrt(h)*sqrt(2*b+1)*(-1i)^b*jb; rJ(:,b+1) = sqrt(h)*sqrt(2*b+1)*rb;
  end
  shift = exp(1i*pi*mvec*(1-h)); fidx = mod(mvec,N)+1;
  yj = -0.5+((0:N-1)'+0.5)*h; ybeta = exp(-1i*common.beta*yj);
  nbatch = ceil(nm/opt.batch_modes);
  % column data (template-local columns 0..N-1, per cell)
  colEF = zeros(N,ncell); colEV = colEF; n1F = zeros(N,4,ncell); n1V = zeros(N,9,ncell);
  duf = LOCAL_duffy(5);
  phi_l1 = h*[1,sqrt(3)/2,sqrt(3)/2,3/4];
  stats = struct('points',0,'pieces',0,'full',0,'dropped_area',0,'min_fan_det',Inf, ...
    'newton_max',0,'sliver_ref_outside',0,'area_base',0,'area_nonspecial',0,'files',{{}}, ...
    'bytes',0,'write_seconds',0,'fourier_seconds',0,'strips',numel(opt.strips));
  chunk = 4;
  for j0 = opt.strips(:)'
    cols = j0:min(j0+ncs0,N)-1; ncs = numel(cols); nr = N*ncs;
    pts = LOCAL_strip_points(config,geo,lev,cols,duf);
    stats.pieces = stats.pieces+pts.stats.pieces; stats.full = stats.full+pts.stats.full;
    stats.dropped_area = stats.dropped_area+pts.stats.dropped_area;
    stats.min_fan_det = min(stats.min_fan_det,pts.stats.min_fan_det);
    pts = LOCAL_add_slivers(pts,geo,cols,N);
    [xi,eta,res] = LOCAL_reference_coordinates(config,geo,pts);
    stats.newton_max = max(stats.newton_max,res);
    tsl = pts.z==1; tol = 1e-12;
    stats.sliver_ref_outside = stats.sliver_ref_outside+nnz(tsl & (xi<-tol | eta<-tol | xi+eta>1+tol));
    np = numel(pts.w); stats.points = stats.points+np;
    [Nb,~,~] = LOCAL_p2_basis(xi,eta);
    Phi = sparse(repmat((1:np)',1,6),t.tri6(pts.elem,:),[Nb{:}],np,size(t.xy,1));
    lc = floor((pts.rect-1)/N); lr = pts.rect-1-N*lc;
    sx = 2*(pts.x-(geo.x0+(cols(1)+lc+0.5)*h))/h; sy = 2*(pts.y-(-0.5+(lr+0.5)*h))/h;
    Px = [ones(np,1),sx,(3*sx.^2-1)/2]; Py = [ones(np,1),sy,(3*sy.^2-1)/2];
    bi = zeros(np,13); bv = bi; kk = 0;
    for b = 0:1
      for a = 0:1
        kk = kk+1; bi(:,kk) = pts.rect+(kk-1)*nr; bv(:,kk) = sqrt((2*a+1)*(2*b+1))/h*Px(:,a+1).*Py(:,b+1);
      end
    end
    for b = 0:2
      for a = 0:2
        kk = kk+1; bi(:,kk) = pts.rect+(kk-1)*nr; bv(:,kk) = sqrt((2*a+1)*(2*b+1))/h*Px(:,a+1).*Py(:,b+1);
      end
    end
    Bf = sparse(repmat((1:np)',1,4),bi(:,1:4),bv(:,1:4),np,4*nr);
    Bv = sparse(repmat((1:np)',1,9),bi(:,5:13)-4*nr,bv(:,5:13),np,9*nr);
    Bft = Bf.'; Bvt = Bv.';
    cf = pts.wf.*(pts.a1-pts.z.*pts.a0);
    % reliable masks: base points of non-special elements (bulk source), of
    % affine elements (direct field defect)
    ns = pts.base & ~cen.special(pts.elem); af = pts.base & ~geo.curved(pts.elem);
    wns = pts.w.*ns; waf = pts.w.*af; atrue = reshape(alpha_true(pts.elem),[],1);
    stats.area_base = stats.area_base+sum(pts.w(pts.base));
    stats.area_nonspecial = stats.area_nonspecial+sum(wns);
    rect_lin = lr+N*(cols(1)+lc);                         % template rect index
    rsp = TL.srect(rect_lin+1);                           % special index or 0
    % bulk Gram of the special rectangles (cell independent)
    kp = ns & rsp>0;
    if any(kp)
      [ii,jj] = find(triu(ones(4)));
      for qq = 1:10
        Gb(:,qq) = Gb(:,qq)+accumarray(rsp(kp),wns(kp).*bv(kp,ii(qq)).*bv(kp,jj(qq)),[nsr,1]);
      end
    end
    Cs = zeros(N,ncs,4,ncell,'like',1i); Vs = zeros(N,ncs,9,ncell,'like',1i);
    rl = (0:nr-1)'; rsq = TL.srect(mod(rl,N)+N*(cols(1)+floor(rl/N))+1); isn = rsq==0;
    for c0 = 1:chunk:ncell
      cc = c0:min(c0+chunk-1,ncell); nch = numel(cc);
      U = Phi*Coef(:,cc);
      % prediction (ordinary): moments and D1 diagnostics
      Fm = Bft*(cf.*U); Vm = Bvt*(pts.wu.*U);
      ft = Bf*Fm; vt = Bv*Vm;
      cs.ER2_ord(cc) = cs.ER2_ord(cc)+sum(pts.we.*(abs(pts.a1.*U-ft).^2-pts.z.*abs(pts.a0.*U-ft).^2),1);
      cs.du2_ord(cc) = cs.du2_ord(cc)+sum(pts.wu.*abs(U-vt).^2,1);
      cs.mass(cc) = cs.mass(cc)+sum(pts.wu.*abs(U).^2,1);
      cs.source_energy(cc) = cs.source_energy(cc)+sum(abs(Fm).^2,1);
      cs.field_energy(cc) = cs.field_energy(cc)+sum(abs(Vm).^2,1);
      % reliable bulk: exact rules on affine pieces with certain rect/material
      g = atrue.*U-ft;
      cs.Iu_affine(cc) = cs.Iu_affine(cc)+sum(waf.*abs(U-vt).^2,1);
      gw2 = wns.*abs(g).^2;
      for q2 = 1:nch
        IfbR(:,cc(q2)) = IfbR(:,cc(q2))+accumarray(rsp(kp),gw2(kp,q2),[nsr,1]);
      end
      cs.If_bulk_ns(cc) = cs.If_bulk_ns(cc)+sum(gw2(ns & rsp==0,:),1);
      d = reshape(Bft*(wns.*g),nr,4,nch);                % exact defect moments of the bulk part
      Fm = reshape(Fm,N,ncs,4,nch); Vm = reshape(Vm,N,ncs,9,nch);
      Cs(:,:,:,cc) = Fm; Vs(:,:,:,cc) = Vm;
      for q2 = 1:nch
        dq = d(:,:,q2);
        cs.dns_sq(cc(q2)) = cs.dns_sq(cc(q2))+sum(abs(dq(isn,:)).^2,'all');
        cs.dns_l1(cc(q2)) = cs.dns_l1(cc(q2))+sum(abs(dq(isn,:)).*phi_l1,'all');
        cs.dns_max(cc(q2)) = max(cs.dns_max(cc(q2)),max(abs(dq(isn,:)),[],'all'));
        DB(rsq(~isn),:,cc(q2)) = dq(~isn,:);
        Fq = reshape(Fm(:,:,:,q2),nr,4); Vq = reshape(Vm(:,:,:,q2),nr,9);
        CT(rsq(~isn),:,cc(q2)) = Fq(~isn,:); VT(rsq(~isn),:,cc(q2)) = Vq(~isn,:);
      end
    end
    clear Phi Bf Bv Bft Bvt U ft vt g d pts
    % y-Fourier moments of the strip (uncorrected source), column energies
    tf = tic;
    gc = cols+1;
    colEF(gc,:) = colEF(gc,:)+reshape(sum(sum(abs(Cs).^2,1),3),ncs,ncell);
    colEV(gc,:) = colEV(gc,:)+reshape(sum(sum(abs(Vs).^2,1),3),ncs,ncell);
    n1F(gc,:,:) = reshape(sum(abs(Cs),1),ncs,4,ncell); n1V(gc,:,:) = reshape(sum(abs(Vs),1),ncs,9,ncell);
    [FF,VV] = LOCAL_fourier_strip(Cs,Vs,J,ybeta,fidx,shift);
    stats.fourier_seconds = stats.fourier_seconds+toc(tf);
    if ~isempty(opt.block_dir)
      tw = tic;
      blk = struct('C',Cs,'V',Vs,'cols',cols,'cells',cidx,'N',N,'M',M, ...
        'mode_batches',nbatch,'batch_modes',opt.batch_modes);
      for b = 1:nbatch
        mi = (b-1)*opt.batch_modes+1:min(b*opt.batch_modes,nm);
        blk.(sprintf('F_b%03d',b)) = FF(mi,:,:,:); blk.(sprintf('V_b%03d',b)) = VV(mi,:,:,:);
      end
      file = fullfile(opt.block_dir,sprintf('%s_s%04d.mat',name,j0));
      save(file,'-struct','blk','-v7.3','-nocompression');
      fi = dir(file); stats.bytes = stats.bytes+fi.bytes; stats.files{end+1} = file;
      stats.write_seconds = stats.write_seconds+toc(tw);
    end
    clear Cs Vs FF VV blk
  end
  SA = struct('name',name,'TL',TL,'census',rmfield(cen,{'CX','CY'}),'CT',CT,'VT',VT,'DB',DB, ...
    'Gb',Gb,'IfbR',IfbR,'cs',cs,'colEF',colEF,'colEV',colEV,'n1F',n1F,'n1V',n1V,'J',J,'rJ',rJ, ...
    'mvec',mvec,'cells',cidx,'gcol0',(cidx+nc)*N,'nsr',nsr,'stats',stats, ...
    'material_mismatch_nonspecial',mismatch,'geometry_seconds',geo_seconds,'seconds',toc(tt0));
  SA.geo_checks = struct('true_sliver_rect_changed_by_Q',geo.true_sliver_rect_changed_by_Q, ...
    'true_sliver_boundary_ambiguous',geo.true_sliver_boundary_ambiguous, ...
    'true_sliver_side_changes',geo.true_sliver_side_changes, ...
    'true_sliver_points',numel(geo.true_sliver.w),'sliver_points',numel(geo.sliver.w));
end

function [tt,wt,tm,seg] = LOCAL_split_rule(brk,tg,wg)
  % Gauss rule (tg,wg on [0,1]) on every sub-interval of the break list.
  a = brk(1:end-1); b = brk(2:end); keep = b-a>0; a = a(keep); b = b(keep);
  tt = a+(b-a).*tg'; wt = (b-a).*wg'; tm = (a+b)/2;
  seg = repmat((1:numel(a))',1,numel(tg));
  tt = reshape(tt',[],1); wt = reshape(wt',[],1); seg = reshape(seg',[],1);
end

function [j,r] = LOCAL_sph_bessel(n,x)
  % Spherical Bessel j_n, n = 0..2: power series for |x| < 1 (16 terms after
  % the leading one; alternating with decreasing terms, so the first omitted
  % term bounds the remainder r), closed form (exact primitive, r = 0) else.
  j = zeros(size(x)); r = j; small = abs(x)<1; xs = x(small); xl = x(~small);
  term = xs.^n/prod(1:2:2*n+1); acc = term;
  for k = 1:16
    term = term.*(-xs.^2/2)/(k*(2*n+2*k+1)); acc = acc+term;
  end
  j(small) = acc; r(small) = abs(term.*(xs.^2/2)/(17*(2*n+35)));
  s = sin(xl); c = cos(xl);
  switch n
    case 0, j(~small) = s./xl;
    case 1, j(~small) = s./xl.^2-c./xl;
    case 2, j(~small) = (3./xl.^2-1).*s./xl-3*c./xl.^2;
  end
end

function [FF,VV] = LOCAL_fourier_strip(Cs,Vs,J,ybeta,fidx,shift)
  % Exact finite y-Fourier sums of the rectangle coefficients (FFT as the
  % summation): F_a(m) = J_0 GF(1+a) + J_1 GF(3+a), V_a = sum_b J_b GV(1+a+3b).
  [N,ncs,~,ncell] = size(Cs); nm = numel(fidx);
  GF = fft(Cs.*ybeta,[],1); GF = GF(fidx,:,:,:).*shift;
  GV = fft(Vs.*ybeta,[],1); GV = GV(fidx,:,:,:).*shift;
  FF = zeros(nm,ncs,2,ncell,'like',1i); VV = zeros(nm,ncs,3,ncell,'like',1i);
  for a = 0:1, FF(:,:,a+1,:) = J(:,1).*GF(:,:,1+a,:)+J(:,2).*GF(:,:,3+a,:); end
  for a = 0:2, VV(:,:,a+1,:) = J(:,1).*GV(:,:,1+a,:)+J(:,2).*GV(:,:,4+a,:)+J(:,3).*GV(:,:,7+a,:); end
  assert(size(Cs,1)==N);
end

function TL = LOCAL_template_level(config,native,t,lev,common,sel,geo,S0)
  % Template/level data of the reference engine.
  nt = size(t.tri6,1); Jmin = zeros(nt,1);
  for e = 1:nt
    map = LOCAL_map_coefficients([geo.X6(e,:)',geo.Y6(e,:)']);
    Jmin(e) = LOCAL_quadratic_triangle_extrema(LOCAL_det_coefficients(map));
  end
  assert(all(Jmin>0),'i96:Jacobian','Non-positive P2 Jacobian in template %s.',t.name);
  TL = struct('name',t.name,'cell',t.cell,'X6',geo.X6,'Y6',geo.Y6,'tri6',t.tri6, ...
    'curved',geo.curved,'Jmin',Jmin,'det_tol',1e-3,'N',lev.N,'h',1/lev.N,'x0',t.cell-0.5, ...
    'y0',-0.5,'alpha',common.mu*[common.rho_background,t.rho_in]+common.s, ...
    'Coef',[native.cells(sel).coef],'ncell',numel(sel),'cells',[native.cells(sel).index], ...
    'curve',LOCAL_curve_info(config,t.cell,S0),'special',[],'srect',[]);
end

%% ==================== D2 reference-domain engine: geometry primitives ====================
% Half-plane clipping, slab labels (D2.2), chord tubes (D2.3), winding test, pull-back.
function [QX,QY,qn] = LOCAL_hclip(PX,PY,pn,a,b,c)
  % Clip NaN-padded convex polygons (rows) to the closed half-plane
  % a*x+b*y <= c (one a,b,c per row; c = Inf keeps the row unchanged).
  % A convex polygon gains at most one vertex per clip.
  np = size(PX,1); width = size(PX,2);
  QX = nan(np,width+1); QY = QX; qn = zeros(np,1);
  if np==0, return, end
  a = a(:).*ones(np,1); b = b(:).*ones(np,1); c = c(:).*ones(np,1);
  D = a.*PX+b.*PY-c; rows = (1:np)';
  for i = 1:max(pn)
    act = pn>=i; nxt = (i+1)*ones(np,1); nxt(pn==i) = 1; nxt = min(nxt,width);
    ci = rows+np*(i-1); cj = rows+np*(nxt-1);
    xi = PX(ci); yi = PY(ci); di = D(ci); xj = PX(cj); yj = PY(cj); dj = D(cj);
    k = find(act & di<=0);
    qn(k) = qn(k)+1; idx = k+np*(qn(k)-1); QX(idx) = xi(k); QY(idx) = yi(k);
    k = find(act & ((di<=0)~=(dj<=0)));
    tt = di(k)./(di(k)-dj(k));
    qn(k) = qn(k)+1; idx = k+np*(qn(k)-1);
    QX(idx) = xi(k)+tt.*(xj(k)-xi(k)); QY(idx) = yi(k)+tt.*(yj(k)-yi(k));
  end
  w = max([qn;3]); QX = QX(:,1:w); QY = QY(:,1:w);
end

function P = LOCAL_piece_select(P,keep)
  % Row selection of a piece struct (all fields have one row per piece).
  f = fieldnames(P);
  for j = 1:numel(f), P.(f{j}) = P.(f{j})(keep,:); end
end

function P = LOCAL_piece_cat(P,Q)
  % Row concatenation of two piece structs with NaN-padded polygon widths.
  if isempty(P.pn), P = Q; return, end
  if isempty(Q.pn), return, end
  w = max(size(P.PX,2),size(Q.PX,2));
  P.PX(:,end+1:w) = NaN; P.PY(:,end+1:w) = NaN; Q.PX(:,end+1:w) = NaN; Q.PY(:,end+1:w) = NaN;
  f = fieldnames(P);
  for j = 1:numel(f), P.(f{j}) = [P.(f{j});Q.(f{j})]; end
end

function [P,dropped] = LOCAL_piece_clean(P,G)
  % Remove clipping remnants with fewer than three vertices or with area at
  % rounding level (<= 1e-15 of the item's L_T area). A removed remnant of
  % positive area is never discarded: it is returned (owner, reference area)
  % and the caller keeps it as a fully uncertain record (all node rectangles,
  % both materials).
  area = abs(LOCAL_poly_area(P.PX,P.PY,P.pn));
  tiny = P.pn<3 | area<=1e-15*G.area_lt(P.own);
  pos = tiny & P.pn>=3 & area>0;
  dropped = struct('own',P.own(pos),'area',area(pos).*G.ref_per_lt(P.own(pos)));
  P = LOCAL_piece_select(P,~tiny);
  w = max([P.pn;3]); P.PX = P.PX(:,1:w); P.PY = P.PY(:,1:w);
end

function G = LOCAL_eng_items(TL,I)
  % Per item T: images of the vertices/edge midpoints under F_K, affine
  % interpolant L_T, Bernstein error vectors c_e = 2(F(m_e)-(F(a)+F(b))/2)
  % (|F-L_T| <= max_e |c_e| componentwise and along any unit direction,
  % D2.1), the inverse pull-back xi = R1 + M (z - F1), the L_T orientation
  % check and the reference/L_T area ratio.
  e = I.e; R = I.R;
  rx = [R(:,1),R(:,3),R(:,5),(R(:,1)+R(:,3))/2,(R(:,3)+R(:,5))/2,(R(:,5)+R(:,1))/2];
  ry = [R(:,2),R(:,4),R(:,6),(R(:,2)+R(:,4))/2,(R(:,4)+R(:,6))/2,(R(:,6)+R(:,2))/2];
  [X,Y] = LOCAL_eval_map(TL.X6(e,:),TL.Y6(e,:),rx,ry);
  cx = 2*X(:,4:6)-(X(:,[1,2,3])+X(:,[2,3,1])); cy = 2*Y(:,4:6)-(Y(:,[1,2,3])+Y(:,[2,3,1]));
  affine = ~TL.curved(e); cx(affine,:) = 0; cy(affine,:) = 0;   % exactly affine maps: eta = 0
  a11 = X(:,2)-X(:,1); a12 = X(:,3)-X(:,1); a21 = Y(:,2)-Y(:,1); a22 = Y(:,3)-Y(:,1);
  b11 = R(:,3)-R(:,1); b12 = R(:,5)-R(:,1); b21 = R(:,4)-R(:,2); b22 = R(:,6)-R(:,2);
  detF = a11.*a22-a12.*a21; detX = b11.*b22-b12.*b21;
  G = struct('vx',X(:,1:3),'vy',Y(:,1:3),'cx',cx,'cy',cy, ...
    'eta_x',max(abs(cx),[],2),'eta_y',max(abs(cy),[],2), ...
    'M11',(b11.*a22-b12.*a21)./detF,'M12',(-b11.*a12+b12.*a11)./detF, ...
    'M21',(b21.*a22-b22.*a21)./detF,'M22',(-b21.*a12+b22.*a11)./detF, ...
    'area_lt',abs(detF)/2,'ref_per_lt',abs(detX./detF),'R1x',R(:,1),'R1y',R(:,2));
  G.eta = hypot(G.eta_x,G.eta_y);
  % L_T must be orientation-consistent with the (positive-Jacobian) element and
  % not degenerate; the eta bands of neighbouring grid lines must not overlap.
  G.ok = detF./detX>TL.det_tol*TL.Jmin(e) & 2*max(G.eta_x,G.eta_y)<TL.h;
end

function P = LOCAL_eng_initial_pieces(G,idx)
  % The L_T images of items idx as pieces (one triangle each).
  n = numel(idx);
  P = struct('PX',[G.vx(idx,:),nan(n,1)],'PY',[G.vy(idx,:),nan(n,1)],'pn',3*ones(n,1), ...
    'own',idx(:),'c1',zeros(n,1),'c2',zeros(n,1),'r1',zeros(n,1),'r2',zeros(n,1),'mat',zeros(n,1));
end

function [P,dropped] = LOCAL_eng_slabs(P,G,dim,origin,h,N)
  % D2.2 slab split along one coordinate in the L_T plane: cut at the grid
  % lines x_j +- eta (x_j itself when eta = 0). Interval labels are assigned
  % combinatorially: a band |x - x_j| <= eta keeps both columns {j-1, j}, an
  % interior interval (x_j+eta, x_{j+1}-eta) the single column j.
  if dim==1, C = P.PX; eta = G.eta_x(P.own); else, C = P.PY; eta = G.eta_y(P.own); end
  np = numel(P.pn);
  lo = min(C,[],2,'omitnan'); hi = max(C,[],2,'omitnan');
  jl = ceil((lo-eta-origin)/h); jh = floor((hi+eta-origin)/h);
  nL = max(jh-jl+1,0); nI = 2*nL+1;
  rep = LOCAL_rep((1:np)',nI); k = (0:sum(nI)-1)'-LOCAL_rep(cumsum(nI)-nI,nI);
  nLr = nL(rep); jlr = jl(rep); er = eta(rep);
  q = floor(k/2); odd = mod(k,2)==1;
  lower = -inf(numel(k),1); upper = inf(numel(k),1);
  ev = ~odd & q>0; lower(ev) = origin+(jlr(ev)+q(ev)-1)*h+er(ev);
  ev = ~odd & q<nLr; upper(ev) = origin+(jlr(ev)+q(ev))*h-er(ev);
  lower(odd) = origin+(jlr(odd)+q(odd))*h-er(odd); upper(odd) = origin+(jlr(odd)+q(odd))*h+er(odd);
  l1 = jlr+q-1; l2 = l1; l2(odd) = l1(odd)+1;
  keep = ~(odd & er==0);                               % zero-width bands do not exist
  rep = rep(keep); lower = lower(keep); upper = upper(keep); l1 = l1(keep); l2 = l2(keep);
  Q = LOCAL_piece_select(P,rep);
  if dim==1
    [Q.PX,Q.PY,Q.pn] = LOCAL_hclip(Q.PX,Q.PY,Q.pn,-1,0,-lower);
    [Q.PX,Q.PY,Q.pn] = LOCAL_hclip(Q.PX,Q.PY,Q.pn,1,0,upper);
    Q.c1 = min(max(l1,0),N-1); Q.c2 = min(max(l2,0),N-1);
  else
    [Q.PX,Q.PY,Q.pn] = LOCAL_hclip(Q.PX,Q.PY,Q.pn,0,-1,-lower);
    [Q.PX,Q.PY,Q.pn] = LOCAL_hclip(Q.PX,Q.PY,Q.pn,0,1,upper);
    Q.r1 = min(max(l1,0),N-1); Q.r2 = min(max(l2,0),N-1);
  end
  [P,dropped] = LOCAL_piece_clean(Q,G);
end

function [P,U,stats,dropped] = LOCAL_eng_tubes(TL,G,P,clev)
  % D2.3 chord tubes of the closed true curve at parameter level clev
  % (n_c = S0*2^clev chords, delta = M2*(2*pi/n_c)^2/8). For the item's
  % error vectors c_e the oriented rectangle of chord i is thickened to
  % eps_n = delta + max_e|n.c_e| (normal) and eps_e = delta + max_e|e.c_e|
  % (tangent, end caps). Candidate chords come from the angular range of the
  % piece about the curve centre (padding 2*sqrt(2)*eps/r_min); every piece is
  % split by the candidate rectangles in turn: the part inside a rectangle is
  % material-uncertain (U), the parts outside (up to four convex pieces) go on.
  % Outside pieces then get their material from the chord-side test.
  cv = TL.curve; nc = cv.S0*2^clev; dth = 2*pi/nc; delta = cv.M2*dth^2/8;
  stats = struct('chords',nc,'delta',delta,'candidate_pairs',0,'split_pairs',0, ...
    'max_candidates',0);
  dropped = struct('own',zeros(0,1),'area',zeros(0,1));
  U = LOCAL_piece_select(P,false(numel(P.pn),1));
  if isempty(P.pn), return, end
  pad = 2*sqrt(2)*(delta+G.eta(P.own))/cv.rmin+1e-12;
  [ilo,ns] = LOCAL_curve_candidates(cv,P.PX,P.PY,pad,nc);
  stats.max_candidates = max(ns); stats.candidate_pairs = sum(ns);
  P.ilo = ilo; P.ns = ns; U.ilo = zeros(0,1); U.ns = zeros(0,1);
  for k = 0:max(ns)-1
    act = find(P.ns>k);
    if isempty(act), break, end
    A = LOCAL_piece_select(P,act); seg = mod(A.ilo+k,nc);
    Pa = LOCAL_cpoint(cv,seg*dth); Pb = LOCAL_cpoint(cv,(seg+1)*dth);
    ex = Pb(:,1)-Pa(:,1); ey = Pb(:,2)-Pa(:,2); len = hypot(ex,ey); ex = ex./len; ey = ey./len;
    nx = -ey; ny = ex; o = A.own;
    en = max(abs(nx.*G.cx(o,:)+ny.*G.cy(o,:)),[],2); ee = max(abs(ex.*G.cx(o,:)+ey.*G.cy(o,:)),[],2);
    eps_n = delta+en; eps_e = delta+ee;
    eP = ex.*Pa(:,1)+ey.*Pa(:,2); nP = nx.*Pa(:,1)+ny.*Pa(:,2);
    % half-planes H1..H4 (a x + b y <= c): -e.z <= eps_e - e.P, e.z <= len + eps_e + e.P,
    % n.z <= eps_n + n.P, -n.z <= eps_n - n.P
    ha = [-ex,ex,nx,-nx]; hb = [-ey,ey,ny,-ny];
    hc = [eps_e-eP,len+eps_e+eP,eps_n+nP,eps_n-nP];
    outside_one = false(numel(act),1); inside_all = true(numel(act),1);
    for q = 1:4
      Dq = ha(:,q).*A.PX+hb(:,q).*A.PY-hc(:,q);
      outside_one = outside_one | all(Dq>0 | isnan(Dq),2);
      inside_all = inside_all & all(Dq<=0 | isnan(Dq),2);
    end
    split = ~outside_one & ~inside_all; whole_in = ~outside_one & inside_all;
    stats.split_pairs = stats.split_pairs+nnz(split);
    % untouched pieces stay; whole-inside pieces move to U
    keep_rows = true(numel(P.pn),1); keep_rows(act(~outside_one)) = false;
    Uin = LOCAL_piece_select(A,whole_in);
    S = LOCAL_piece_select(A,split); sa = ha(split,:); sb = hb(split,:); sc = hc(split,:);
    outs = LOCAL_piece_select(S,false(numel(S.pn),1));
    for q = 1:4
      O = S; [O.PX,O.PY,O.pn] = LOCAL_hclip(S.PX,S.PY,S.pn,-sa(:,q),-sb(:,q),-sc(:,q));
      [S.PX,S.PY,S.pn] = LOCAL_hclip(S.PX,S.PY,S.pn,sa(:,q),sb(:,q),sc(:,q));
      outs = LOCAL_piece_cat(outs,O);
    end
    [outs,d1] = LOCAL_piece_clean(outs,G); [S,d2] = LOCAL_piece_clean(S,G);
    dropped = struct('own',[dropped.own;d1.own;d2.own],'area',[dropped.area;d1.area;d2.area]);
    U = LOCAL_piece_cat(U,LOCAL_piece_cat(Uin,S));
    P = LOCAL_piece_cat(LOCAL_piece_select(P,keep_rows),outs);
  end
  % material of the pieces outside all tubes (one winding per piece)
  zx = mean(P.PX,2,'omitnan'); zy = mean(P.PY,2,'omitnan');
  inside = LOCAL_curve_side(cv,zx,zy,clev);
  P.mat = 1+double(inside); U.mat = 3*ones(numel(U.pn),1);
  P = rmfield(P,{'ilo','ns'}); U = rmfield(U,{'ilo','ns'});
end

function [ilo,ns] = LOCAL_curve_candidates(cv,PX,PY,pad,nc)
  % Index range of the chords whose padded angular span meets the angular
  % range of each polygon about the curve centre (pieces never contain the
  % centre: special elements lie near the curve, r >= r_min/2 is asserted).
  dx = PX-cv.cx; dy = PY-cv.cy;
  assert(min(hypot(dx(:),dy(:)),[],'omitnan')>cv.rmin/2,'i96:Tube','Piece too close to the curve centre.');
  ang = atan2(dy,dx); ref = ang(:,1);
  d = mod(ang-ref+pi,2*pi)-pi;
  plo = ref+min(d,[],2,'omitnan')-pad; phi = ref+max(d,[],2,'omitnan')+pad;
  shift = 2*pi*floor(plo/(2*pi)); plo = plo-shift; phi = phi-shift;
  thlo = LOCAL_curve_theta(cv,plo)-1e-12; thhi = LOCAL_curve_theta(cv,phi)+1e-12;
  dth = 2*pi/nc;
  ilo = floor(thlo/dth); ihi = floor(thhi/dth); ns = ihi-ilo+1; ilo = mod(ilo,nc);
end

function theta = LOCAL_curve_theta(cv,phi)
  % Parameter of the curve point with polar angle phi about the centre
  % (phi(theta) is strictly increasing, phi(theta+2pi) = phi(theta)+2pi).
  if strcmp(cv.type,'lead'), theta = phi; return, end
  base = floor(phi/(2*pi)); r = phi-2*pi*base;
  theta = interp1(cv.phi_tab,cv.theta_tab,r,'linear');
  for it = 1:4
    [p,dp] = LOCAL_curve_phi(cv,theta);
    theta = theta-(p-r)./dp;
  end
  p = LOCAL_curve_phi(cv,theta);
  assert(max(abs(p-r))<1e-12,'i96:Tube','Polar-angle inversion did not converge.');
  theta = theta+2*pi*base;
end

function [p,dp] = LOCAL_curve_phi(cv,theta)
  % Continuous polar angle about the centre and its derivative.
  c = LOCAL_cpoint(cv,theta); x = c(:,1)-cv.cx; y = c(:,2)-cv.cy;
  p = theta+mod(atan2(y,x)-theta+pi,2*pi)-pi;
  if nargout>1
    d = LOCAL_cderiv(cv,theta); dp = (x.*d(:,2)-y.*d(:,1))./(x.^2+y.^2);
  end
end

function inside = LOCAL_curve_side(cv,zx,zy,clev)
  % Winding number of the chord polygon (star-shaped about the centre, CCW):
  % z is inside iff it lies to the left of the chord whose angular span
  % contains arg(z - centre). Valid for points outside all chord tubes.
  inside = false(size(zx));
  if isempty(zx), return, end
  nc = cv.S0*2^clev; dth = 2*pi/nc;
  ang = mod(atan2(zy-cv.cy,zx-cv.cx),2*pi);
  i = floor(LOCAL_curve_theta(cv,ang)/dth); i = min(max(i,0),nc-1);
  for it = 1:3
    plo = LOCAL_curve_phi(cv,i*dth); phi = LOCAL_curve_phi(cv,(i+1)*dth);
    i(ang<plo) = i(ang<plo)-1; i(ang>=phi) = i(ang>=phi)+1;
  end
  plo = LOCAL_curve_phi(cv,i*dth); phi = LOCAL_curve_phi(cv,(i+1)*dth);
  assert(all(ang>=plo-1e-12 & ang<=phi+1e-12),'i96:Tube','Chord search failed.');
  A = LOCAL_cpoint(cv,i*dth); B = LOCAL_cpoint(cv,(i+1)*dth);
  inside = (B(:,1)-A(:,1)).*(zy-A(:,2))-(B(:,2)-A(:,2)).*(zx-A(:,1))>0;
end

function c = LOCAL_cpoint(cv,theta)
  % True interface point (template coordinates).
  theta = theta(:);
  if strcmp(cv.type,'center')
    sc = cv.scale*0.2; c5 = cos(5*theta);
    c = [sc*(1.5+0.3*c5).*cos(theta),sc*(1+0.3*c5).*sin(theta)];
  else
    r = cv.R*(1+cv.a*cos(3*theta)); c = [cv.cx+r.*cos(theta),r.*sin(theta)];
  end
end

function d = LOCAL_cderiv(cv,theta)
  theta = theta(:);
  if strcmp(cv.type,'center')
    sc = cv.scale*0.2; c5 = cos(5*theta); s5 = sin(5*theta);
    d = sc*[-1.5*s5.*cos(theta)-(1.5+0.3*c5).*sin(theta),-1.5*s5.*sin(theta)+(1+0.3*c5).*cos(theta)];
  else
    r = cv.R*(1+cv.a*cos(3*theta)); dr = -3*cv.a*cv.R*sin(3*theta);
    d = [dr.*cos(theta)-r.*sin(theta),dr.*sin(theta)+r.*cos(theta)];
  end
end

function cv = LOCAL_curve_info(config,cell_index,S0)
  % Curve data of one template: centre, M2 >= max|c''| (theory 7.1),
  % monotone polar-angle table (centre curve), r_min and checks.
  m = config.model;
  if cell_index==0
    cv = struct('type','center','cx',0,'cy',0,'scale',m.star_scale,'a',NaN,'R',NaN, ...
      'M2',hypot(1.86,1.76)*m.star_scale);
  else
    a = m.a_negative; if cell_index>0, a = m.a_positive; end
    R = m.radius/sqrt(1+a^2/2);
    cv = struct('type','lead','cx',cell_index*m.L,'cy',0,'scale',1,'a',a,'R',R, ...
      'M2',sqrt(2)*R*(1+10*a));
  end
  cv.S0 = S0;
  th = 2*pi*(0:65536)'/65536;
  if strcmp(cv.type,'center')
    cv.theta_tab = th; cv.phi_tab = th;           % placeholder before the table exists
    cv.phi_tab = LOCAL_curve_phi(cv,th); cv.phi_tab(1) = 0; cv.phi_tab(end) = 2*pi;
    dphi = diff(cv.phi_tab);
    [~,dp] = LOCAL_curve_phi(cv,th);
    cv.phi_monotone_min_derivative = min(dp);
    assert(all(dphi>0) && min(dp)>0,'i96:Curve','Centre polar angle is not monotone.');
  else
    cv.theta_tab = th; cv.phi_tab = th; cv.phi_monotone_min_derivative = 1;
  end
  pts = LOCAL_cpoint(cv,th);
  rr = hypot(pts(:,1)-cv.cx,pts(:,2)-cv.cy);
  cv.rmin = 0.9*min(rr);
  % radial range used by the census: r < rho_lo is inside, r > rho_hi outside
  cv.rho_lo = cv.rmin; cv.rho_hi = 1.1*max(rr);
  % numerical check of M2 against sampled |c''| (central differences)
  dd = diff(LOCAL_cderiv(cv,[th;th(2)]))/(th(2)-th(1));
  cv.M2_sampled = max(hypot(dd(:,1),dd(:,2)));
  assert(cv.M2_sampled<=cv.M2,'i96:Curve','Sampled |c''''| exceeds M2.');
end

function [X,Y] = LOCAL_eval_map(X6,Y6,xi,eta)
  % P2 map at reference points (rows = elements).
  l1 = 1-xi-eta; l2 = xi; l3 = eta;
  N = {l1.*(2*l1-1),l2.*(2*l2-1),l3.*(2*l3-1),4*l1.*l2,4*l2.*l3,4*l3.*l1};
  X = 0; Y = 0;
  for i = 1:6, X = X+N{i}.*X6(:,i); Y = Y+N{i}.*Y6(:,i); end
end

function [RX,RY] = LOCAL_pull_back(G,P)
  % Reference coordinates of the piece vertices by the exact inverse of L_T.
  o = P.own; dx = P.PX-G.vx(o,1); dy = P.PY-G.vy(o,1);
  RX = G.R1x(o)+G.M11(o).*dx+G.M12(o).*dy; RY = G.R1y(o)+G.M21(o).*dx+G.M22(o).*dy;
end

function I = LOCAL_quadrisect(I,sel)
  % Midpoint quadrisection of the reference sub-triangles sel (shape-regular).
  R = I.R(sel,:); n = numel(sel);
  a = R(:,1:2); b = R(:,3:4); c = R(:,5:6); ab = (a+b)/2; bc = (b+c)/2; ca = (c+a)/2;
  RR = [a,ab,ca;ab,b,bc;ca,bc,c;ab,bc,ca];
  rep = repmat(sel(:),4,1);
  I = struct('e',I.e(rep),'R',RR,'lev',I.lev(rep)+1,'node',I.node(rep));
  assert(size(I.R,1)==4*n);
end

%% ==================== D2 reference-domain engine: exact rules and group integrals ====================
% Duffy rules, Bernstein inverses, certain-piece group integrals (F and P type).
function Q = LOCAL_duffy(n)
  % n x n Duffy-Gauss rule on the unit triangle (weights sum to 1/2), exact
  % for total degree 2n-2 (theory D2 / design 4.2: n = 10 for degree 18).
  [lambda,w] = LOCAL_quadrature(n);
  Q = struct('x',lambda(:,2)','y',lambda(:,3)','w',w','n',n,'degree',2*n-2);
end

function B = LOCAL_bern_inv(d)
  % Lattice of degree d on a triangle (barycentric l1,l2,l3, L = (d+1)(d+2)/2
  % points) and the inverse collocation matrix: Bernstein coefficients =
  % Binv * lattice values. sup|p| over the triangle <= max |coefficient|.
  [i,j] = ndgrid(0:d,0:d); keep = i+j<=d; i = i(keep); j = j(keep); k = d-i-j;
  l2 = i/d; l3 = j/d; l1 = 1-l2-l3; L = numel(i);
  C = zeros(L,L);
  for q = 1:L
    C(:,q) = factorial(d)/(factorial(k(q))*factorial(i(q))*factorial(j(q)))* ...
      l1.^k(q).*l2.^i(q).*l3.^j(q);
  end
  B = struct('d',d,'l1',l1,'l2',l2,'l3',l3,'Binv',inv(C),'L',L, ...
    'cond',cond(C));
end

function [x,y,J,N] = LOCAL_p2_points(TL,e,xi,eta)
  % P2 map, Jacobian determinant and basis values at reference points
  % (e, xi, eta same size; N is a cell array of six arrays).
  [N,Nx,Ny] = LOCAL_p2_basis(xi,eta);
  x = 0; y = 0; xx = 0; xy = 0; yx = 0; yy = 0;
  for i = 1:6
    Xi = TL.X6(e,i); Yi = TL.Y6(e,i);
    if ~isequal(size(Xi),size(xi)), Xi = reshape(Xi,size(xi)); Yi = reshape(Yi,size(xi)); end
    x = x+N{i}.*Xi; y = y+N{i}.*Yi;
    xx = xx+Nx{i}.*Xi; xy = xy+Ny{i}.*Xi; yx = yx+Nx{i}.*Yi; yy = yy+Ny{i}.*Yi;
  end
  J = xx.*yy-xy.*yx;
end

function Phi = LOCAL_rect_basis(TL,x,y,col,row,order)
  % Orthonormal Legendre tensor basis of rectangle (col,row): order 1 gives
  % the 4 Q1 functions (index 1+a+2b), order 2 the 9 Q2 functions (1+a+3b).
  h = TL.h;
  sx = 2*(x-(TL.x0+(col+0.5)*h))/h; sy = 2*(y-(TL.y0+(row+0.5)*h))/h;
  Px = {ones(size(sx)),sx,(3*sx.^2-1)/2}; Py = {ones(size(sy)),sy,(3*sy.^2-1)/2};
  Phi = cell(1,(order+1)^2); kk = 0;
  for b = 0:order
    for a = 0:order
      kk = kk+1; Phi{kk} = sqrt((2*a+1)*(2*b+1))/h*Px{a+1}.*Py{b+1};
    end
  end
end

function out = LOCAL_eng_integrate(TL,G,P,kind,Q)
  % Exact group integrals of the certain pieces P (single rectangle, single
  % material for kind 'F'; single rectangle for kind 'P'). Pieces are pulled
  % back to the reference triangle by the exact inverse of L_T, fan
  % triangulated and integrated with the Duffy rule Q:
  %   F: A_f = int N_i phi_ab J (6x4), G_NN (21), per rectangle G_phiphi (10);
  %   P: A_v = int N_i psi_ab J (6x9), G_NN (21), per rectangle G_psipsi (45).
  % Keys: F ((e-1)NR+rect)*2+mat-1, P (e-1)NR+rect, rectangle key rect.
  NR = TL.N^2; order = 1+strcmp(kind,'P'); nb = (order+1)^2;
  [ii,jj] = find(triu(ones(6))); [kk,ll] = find(triu(ones(nb)));
  out = struct('key',zeros(0,1),'val',zeros(0,6*nb+21),'rkey',zeros(0,1), ...
    'rval',zeros(0,numel(kk)),'area_e',zeros(0,1),'area_v',zeros(0,1),'pieces',0,'points',0);
  if isempty(P.pn), return, end
  [RX,RY] = LOCAL_pull_back(G,P);
  out.pieces = numel(P.pn);
  area = zeros(numel(P.pn),1);
  keys = {}; vals = {}; rkeys = {}; rvals = {};
  for k = 2:max(P.pn)-1
    s = find(P.pn>=k+1);
    v1x = RX(s,1); v1y = RY(s,1); ax = RX(s,k)-v1x; ay = RY(s,k)-v1y; bx = RX(s,k+1)-v1x; by = RY(s,k+1)-v1y;
    dt = abs(ax.*by-ay.*bx); area(s) = area(s)+dt/2;
    chunk = max(1,floor(4e5/numel(Q.w)));
    for c0 = 1:chunk:numel(s)
      c = c0:min(c0+chunk-1,numel(s)); sc = s(c);
      xi = v1x(c)+ax(c).*Q.x+bx(c).*Q.y; eta = v1y(c)+ay(c).*Q.x+by(c).*Q.y;
      w = dt(c).*Q.w; e = repmat(G.e(P.own(sc)),1,numel(Q.w));
      [x,y,J,N] = LOCAL_p2_points(TL,e,xi,eta);
      col = repmat(P.c1(sc),1,numel(Q.w)); row = repmat(P.r1(sc),1,numel(Q.w));
      Phi = LOCAL_rect_basis(TL,x,y,col,row,order);
      rect = row+TL.N*col; wJ = w.*J;
      if strcmp(kind,'F')
        key = ((e-1)*NR+rect)*2+repmat(P.mat(sc),1,numel(Q.w))-1;
      else
        key = (e-1)*NR+rect;
      end
      [uk,~,ik] = unique(key(:)); nk = numel(uk); V = zeros(nk,6*nb+21);
      for b = 1:nb
        for i = 1:6, V(:,i+6*(b-1)) = accumarray(ik,reshape(wJ.*N{i}.*Phi{b},[],1),[nk,1]); end
      end
      for q = 1:21, V(:,6*nb+q) = accumarray(ik,reshape(wJ.*N{ii(q)}.*N{jj(q)},[],1),[nk,1]); end
      [ur,~,ir] = unique(rect(:)); nr = numel(ur); W = zeros(nr,numel(kk));
      for q = 1:numel(kk), W(:,q) = accumarray(ir,reshape(wJ.*Phi{kk(q)}.*Phi{ll(q)},[],1),[nr,1]); end
      keys{end+1} = uk; vals{end+1} = V; rkeys{end+1} = ur; rvals{end+1} = W; %#ok<AGROW>
      out.points = out.points+numel(w);
    end
  end
  out.key = vertcat(keys{:}); out.val = vertcat(vals{:});
  out.rkey = vertcat(rkeys{:}); out.rval = vertcat(rvals{:});
  [ue,~,ie] = unique(G.e(P.own)); out.area_e = ue; out.area_v = accumarray(ie,area);
  out = LOCAL_acc_merge(out);
end

function A = LOCAL_acc_merge(A,B)
  % Merge (and consolidate) key/value tables of group integrals.
  if nargin>1
    A.key = [A.key;B.key]; A.val = [A.val;B.val]; A.rkey = [A.rkey;B.rkey]; A.rval = [A.rval;B.rval];
    A.area_e = [A.area_e;B.area_e]; A.area_v = [A.area_v;B.area_v];
    A.pieces = A.pieces+B.pieces; A.points = A.points+B.points;
  end
  [u,~,i] = unique(A.key); V = zeros(numel(u),size(A.val,2));
  for q = 1:size(A.val,2), V(:,q) = accumarray(i,A.val(:,q),[numel(u),1]); end
  A.key = u; A.val = V;
  [u,~,i] = unique(A.rkey); V = zeros(numel(u),size(A.rval,2));
  for q = 1:size(A.rval,2), V(:,q) = accumarray(i,A.rval(:,q),[numel(u),1]); end
  A.rkey = u; A.rval = V;
  [u,~,i] = unique(A.area_e); A.area_e = u; A.area_v = accumarray(i,A.area_v,[numel(u),1]);
end

function A = LOCAL_acc_empty(kind)
  nb = 4; if strcmp(kind,'P'), nb = 9; end
  A = struct('key',zeros(0,1),'val',zeros(0,6*nb+21),'rkey',zeros(0,1), ...
    'rval',zeros(0,nb*(nb+1)/2),'area_e',zeros(0,1),'area_v',zeros(0,1),'pieces',0,'points',0);
end

%% ==================== D2 reference-domain engine: node Bernstein bounds ====================
% sup|g_{R,r}|, sup|p_R| and sup J over level-3 nodes by Bernstein coefficients.
function nb = LOCAL_node_rects(TL,nodes)
  % Candidate rectangles of every node: the grid cells meeting the bounding
  % box of the node's quadratic control net widened by its eta (contains the
  % images and all L_T bands of every descendant item).
  G = LOCAL_eng_items(TL,nodes);
  R = nodes.R; e = nodes.e;
  rx = [R(:,1),R(:,3),R(:,5),(R(:,1)+R(:,3))/2,(R(:,3)+R(:,5))/2,(R(:,5)+R(:,1))/2];
  ry = [R(:,2),R(:,4),R(:,6),(R(:,2)+R(:,4))/2,(R(:,4)+R(:,6))/2,(R(:,6)+R(:,2))/2];
  [X,Y] = LOCAL_eval_map(TL.X6(e,:),TL.Y6(e,:),rx,ry);
  CX = [X(:,1:3),2*X(:,4:6)-(X(:,[1,2,3])+X(:,[2,3,1]))/2];
  CY = [Y(:,1:3),2*Y(:,4:6)-(Y(:,[1,2,3])+Y(:,[2,3,1]))/2];
  pad = max(G.eta_x,G.eta_y)+1e-14;
  c1 = floor((min(CX,[],2)-pad-TL.x0)/TL.h); c2 = floor((max(CX,[],2)+pad-TL.x0)/TL.h);
  r1 = floor((min(CY,[],2)-pad-TL.y0)/TL.h); r2 = floor((max(CY,[],2)+pad-TL.y0)/TL.h);
  nb = struct('c1',max(c1,0),'c2',min(c2,TL.N-1),'r1',max(r1,0),'r2',min(r2,TL.N-1));
end

function [pn,col,row] = LOCAL_node_pairs(nr,sel)
  % Expand the node rectangle ranges of nodes sel into (node, col, row) pairs.
  sel = sel(:); nc = nr.c2(sel)-nr.c1(sel)+1; nrw = nr.r2(sel)-nr.r1(sel)+1; cnt = nc.*nrw;
  pn = LOCAL_rep(sel,cnt); k = (0:sum(cnt)-1)'-LOCAL_rep(cumsum(cnt)-cnt,cnt);
  ncr = LOCAL_rep(nrw,cnt);
  col = LOCAL_rep(nr.c1(sel),cnt)+floor(k./ncr); row = LOCAL_rep(nr.r1(sel),cnt)+mod(k,ncr);
end

function S = LOCAL_node_sup(TL,nodes,pn,col,row,kind,CT,BG)
  % For (node, rect) pairs: sup over the node of |g_{R,r}| (kind 'F', r =
  % background and inclusion; degree-4 Bernstein) or |p_R| (kind 'P';
  % degree 8), for every cell of the template (columns). CT = coefficient
  % table of the special rectangles (nsr x nb x ncell); BG.(lattice).
  % Returns S.out, S.in (F) or S.p (P) as npairs x ncell arrays.
  rect = row+TL.N*col; ridx = TL.srect(rect+1);
  assert(all(ridx>0),'i96:SpecialRect','Node rectangle outside the special-rectangle set.');
  if strcmp(kind,'F'), B = BG.b4; order = 1; else, B = BG.b8; order = 2; end
  np = numel(pn); nc = TL.ncell; L = B.L;
  if strcmp(kind,'F'), S = struct('out',zeros(np,nc),'in',zeros(np,nc)); else, S = struct('p',zeros(np,nc)); end
  chunk = max(1,floor(2e6/(L*nc)));
  for c0 = 1:chunk:np
    c = (c0:min(c0+chunk-1,np))'; nn = pn(c); R = nodes.R(nn,:); e = nodes.e(nn);
    xi = R(:,1).*B.l1'+R(:,3).*B.l2'+R(:,5).*B.l3'; eta = R(:,2).*B.l1'+R(:,4).*B.l2'+R(:,6).*B.l3';
    E = repmat(e,1,L);
    [x,y,~,N] = LOCAL_p2_points(TL,E,xi,eta);
    Phi = LOCAL_rect_basis(TL,x,y,repmat(col(c),1,L),repmat(row(c),1,L),order);
    % u at lattice points for all cells: (pairs*L) x ncell
    U = 0;
    for i = 1:6, U = U+N{i}(:).*TL.Coef(TL.tri6(E(:),i),:); end
    Fv = 0; ri = repmat(ridx(c),1,L);
    for b = 1:numel(Phi), Fv = Fv+Phi{b}(:).*reshape(CT(ri(:),b,:),[],nc); end
    nq = numel(c);
    if strcmp(kind,'F')
      for r = 1:2
        g = TL.alpha(r)*U-Fv;                          % (nq*L) x nc
        g = reshape(permute(reshape(g,nq,L,nc),[2,1,3]),L,[]);
        bc = reshape(max(abs(B.Binv*g),[],1),nq,nc);
        if r==1, S.out(c,:) = bc; else, S.in(c,:) = bc; end
      end
    else
      g = reshape(permute(reshape(U-Fv,nq,L,nc),[2,1,3]),L,[]);
      S.p(c,:) = reshape(max(abs(B.Binv*g),[],1),nq,nc);
    end
  end
end

function Jhi = LOCAL_node_jhi(TL,nodes,BG)
  % Upper bound of det DF_K over each node (degree-2 Bernstein coefficients).
  B = BG.b2; R = nodes.R;
  xi = R(:,1).*B.l1'+R(:,3).*B.l2'+R(:,5).*B.l3'; eta = R(:,2).*B.l1'+R(:,4).*B.l2'+R(:,6).*B.l3';
  [~,~,J] = LOCAL_p2_points(TL,repmat(nodes.e,1,B.L),xi,eta);
  Jhi = max(B.Binv*J',[],1)';
end

%% ==================== D2 reference-domain engine: rounds, final pass, aggregation ====================
% Score-driven refinement of the material/rectangle-uncertain items, exact
% integration of the certain pieces, records of the uncertain ones and the
% per-cell enclosures of source moments, E_R^2 and delta_u^2.
function E = LOCAL_engine(TL,CT,BG,opt)
  % opt: start_level, level_limit, piece_limit, target, refine_fraction,
  %   fallback_every, clock (function handle, seconds), deadline, CG,
  %   chunk_items, config (memory gate), post_factor, elements (optional subset).
  t0 = tic; config = opt.config;
  sp = find(TL.special);
  if isfield(opt,'elements') && ~isempty(opt.elements), sp = intersect(sp,opt.elements(:)); end
  I = struct('e',sp(:),'R',repmat([0,0,1,0,0,1],numel(sp),1),'lev',zeros(numel(sp),1),'node',zeros(numel(sp),1));
  for l = 1:opt.start_level, I = LOCAL_quadrisect(I,(1:numel(I.e))'); end
  nn = numel(I.e); I.node = (1:nn)';
  nodes = struct('e',I.e,'R',I.R,'lev',I.lev,'node',I.node);
  nr = LOCAL_node_rects(TL,nodes);
  Jhi = LOCAL_node_jhi(TL,nodes,BG);
  QF = LOCAL_duffy(opt.duffy_F); QP = LOCAL_duffy(opt.duffy_P);
  % --- node scores with the prediction coefficients (design 4.1.6) ---
  ts = tic;
  [pn,col,row] = LOCAL_node_pairs(nr,(1:nn)');
  S = LOCAL_node_sup(TL,nodes,pn,col,row,'F',CT,BG);
  Sn = zeros(nn,3);
  for c = 1:TL.ncell
    mo = accumarray(pn,S.out(:,c),[nn,1],@max); mi = accumarray(pn,S.in(:,c),[nn,1],@max);
    Sn = Sn+[mo,mi,max(mo,mi)];
  end
  Sn = 6.25*Jhi.*Sn; sf = sqrt(2)*opt.CG;
  score_seconds = toc(ts); clear S pn col row
  E = struct('template',TL.name,'nodes',nodes,'nr',nr,'Jhi',Jhi,'Snode',Sn, ...
    'accF',LOCAL_acc_empty('F'),'accP',LOCAL_acc_empty('P'),'recF',zeros(0,7),'recP',zeros(0,7), ...
    'rounds',struct([]),'stop','','seconds',struct(),'counts',struct());
  % --- P type (curved elements, fixed level = node level; rectangles only) ---
  tp = tic; pc = find(TL.curved(nodes.e));
  for c0 = 1:opt.chunk_items:numel(pc)
    s = pc(c0:min(c0+opt.chunk_items-1,numel(pc)));
    R = LOCAL_eng_clip(TL,I,s,false);
    E.accP = LOCAL_acc_merge(E.accP,LOCAL_eng_integrate(TL,R.G,R.Pc,'P',QP));
    E.recP = [E.recP;LOCAL_records(R,I,s,nr,false)];
  end
  E.recP = LOCAL_merge_records(E.recP);
  p_seconds = toc(tp);
  % --- F type rounds ---
  pend = LOCAL_items_empty(); pscore = zeros(0,1); pdeg = false(0,1); ppieces = zeros(0,1);
  active = I; pieces_done = 0; processed = 0; peak_active = numel(I.e); round = 0; stop = '';
  last_rate = NaN;
  while true
    round = round+1; tr = tic;
    for c0 = 1:opt.chunk_items:numel(active.e)
      s = (c0:min(c0+opt.chunk_items-1,numel(active.e)))';
      LOCAL_memory_gate(config,'engine chunk',numel(s)*4000);
      R = LOCAL_eng_clip(TL,active,s,true);
      ni = numel(s); hasu = accumarray(R.Pu.own,1,[ni,1])>0;
      fin = R.ok & ~hasu;
      E.accF = LOCAL_acc_merge(E.accF,LOCAL_eng_integrate(TL,R.G, ...
        LOCAL_piece_select(R.Pc,fin(R.Pc.own)),'F',QF));
      pieces_done = pieces_done+nnz(fin(R.Pc.own));
      dr = LOCAL_dropped_records(R,active,s,nr,~fin);     % retired items only
      E.recF = [E.recF;dr];
      au = abs(LOCAL_poly_area(R.Pu.PX,R.Pu.PY,R.Pu.pn)).*R.G.ref_per_lt(R.Pu.own);
      nR = (R.Pu.c2-R.Pu.c1+1).*(R.Pu.r2-R.Pu.r1+1);
      sc = accumarray(R.Pu.own,sf*au.*nR.*Sn(sub2ind(size(Sn),active.node(s(R.Pu.own)),R.Pu.mat)),[ni,1]);
      sc(~R.ok) = Inf;
      np_item = accumarray(R.Pc.own,1,[ni,1])+accumarray(R.Pu.own,1,[ni,1]);
      keep = ~fin;
      pend = LOCAL_items_cat(pend,LOCAL_items_select(active,s(keep)));
      pscore = [pscore;sc(keep)]; pdeg = [pdeg;~R.ok(keep)]; ppieces = [ppieces;max(np_item(keep),1)]; %#ok<AGROW>
      processed = processed+numel(R.Pc.pn)+numel(R.Pu.pn);
    end
    rs = toc(tr); last_rate = rs/max(numel(active.e),1);
    finite = pscore(~pdeg); total = sum(finite);
    rec = struct('round',round,'active',numel(active.e),'active_level_max',max([active.lev;0]), ...
      'pending',numel(pend.e),'degenerate',nnz(pdeg),'score',total,'pieces_done',pieces_done, ...
      'pending_pieces',sum(ppieces),'seconds',rs,'clock',opt.clock());
    E.rounds = LOCAL_append(E.rounds,rec);
    if ~(isfield(opt,'quiet') && opt.quiet), fprintf('    ENGINE %s r%d: active %d (lev<=%d) pending %d deg %d score %.3e done %d %.2fs\n', ...
      TL.name,round,rec.active,rec.active_level_max,rec.pending,rec.degenerate,total,pieces_done,rs); end
    if isempty(pend.e), stop = 'COMPLETE'; break, end
    if ~any(pdeg) && total<=opt.target, stop = 'TARGET'; break, end
    % refinement selection: top refine_fraction of the score, degenerate
    % items, and every fallback_every-th round all items of the coarsest level
    [~,ord] = sort(pscore,'descend'); ord = ord(~pdeg(ord));
    k = find(cumsum(pscore(ord))>=opt.refine_fraction*total,1); if isempty(k), k = numel(ord); end
    sel = false(numel(pend.e),1); sel(ord(1:k)) = true; sel(pdeg) = true;
    if mod(round,opt.fallback_every)==0, sel(pend.lev==min(pend.lev)) = true; end
    sel(pend.lev+1>opt.level_limit) = false;
    if ~any(sel), stop = 'LEVEL_LIMIT'; break, end
    est = pieces_done+sum(ppieces)+3*sum(ppieces(sel));
    if est>opt.piece_limit, stop = 'PIECE_LIMIT'; break, end
    % next round + final pass must fit before the deadline (measured rate)
    % (aggregation and correction re-aggregation cost ~ post_factor score passes)
    pred = last_rate*(4*nnz(sel)+numel(pend.e))+opt.post_factor*score_seconds;
    if opt.clock()+pred>opt.deadline, stop = 'DEADLINE'; break, end
    active = LOCAL_quadrisect(pend,find(sel));
    peak_active = max(peak_active,numel(active.e));
    pend = LOCAL_items_select(pend,find(~sel)); pscore = pscore(~sel); pdeg = pdeg(~sel); ppieces = ppieces(~sel);
  end
  % --- final pass: integrate certain pieces of pending items, records of the rest ---
  tf = tic;
  for c0 = 1:opt.chunk_items:numel(pend.e)
    s = (c0:min(c0+opt.chunk_items-1,numel(pend.e)))';
    R = LOCAL_eng_clip(TL,pend,s,true);
    E.accF = LOCAL_acc_merge(E.accF,LOCAL_eng_integrate(TL,R.G,R.Pc,'F',QF));
    pieces_done = pieces_done+numel(R.Pc.pn)+numel(R.Pu.pn);
    E.recF = [E.recF;LOCAL_records(R,pend,s,nr,true)];
  end
  E.recF = LOCAL_merge_records(E.recF);
  E.stop = stop;
  E.counts = struct('nodes',nn,'special_elements',numel(sp),'curved_nodes',numel(pc), ...
    'terminal_pieces',pieces_done,'processed_pieces',processed,'peak_active',peak_active, ...
    'pending_final',numel(pend.e),'level_max',max([pend.lev;active.lev;0]), ...
    'records_F',size(E.recF,1),'records_P',size(E.recP,1),'groups_F',numel(E.accF.key), ...
    'groups_P',numel(E.accP.key),'chords_level_max',TL.curve.S0*2^max([pend.lev;active.lev;0]));
  E.seconds = struct('score',score_seconds,'p_type',p_seconds,'final_pass',toc(tf),'total',toc(t0));
  E.coverage = LOCAL_coverage(E,nodes,sp);
end

function I = LOCAL_items_empty()
  I = struct('e',zeros(0,1),'R',zeros(0,6),'lev',zeros(0,1),'node',zeros(0,1));
end

function I = LOCAL_items_select(I,s)
  I = struct('e',I.e(s),'R',I.R(s,:),'lev',I.lev(s),'node',I.node(s));
end

function I = LOCAL_items_cat(I,J)
  I = struct('e',[I.e;J.e],'R',[I.R;J.R],'lev',[I.lev;J.lev],'node',[I.node;J.node]);
end

function R = LOCAL_eng_clip(TL,I,s,tubes)
  % Clip items I(s): L_T geometry, slab split in x and y, and (F type) chord
  % tubes at parameter level = item level. Certain pieces (single rectangle,
  % and for F a single material) in R.Pc, the others in R.Pu.
  Is = LOCAL_items_select(I,s);
  G = LOCAL_eng_items(TL,Is); G.e = Is.e;
  P = LOCAL_eng_initial_pieces(G,find(G.ok));
  [P,d1] = LOCAL_eng_slabs(P,G,1,TL.x0,TL.h,TL.N);
  [P,d2] = LOCAL_eng_slabs(P,G,2,TL.y0,TL.h,TL.N);
  drop = struct('own',[d1.own;d2.own],'area',[d1.area;d2.area]);
  U = LOCAL_piece_select(P,false(numel(P.pn),1));
  if tubes
    lv = Is.lev(P.own); Q = LOCAL_piece_select(P,false(numel(P.pn),1));
    for l = unique(lv)'
      [Pl,Ul,~,d3] = LOCAL_eng_tubes(TL,G,LOCAL_piece_select(P,lv==l),l);
      Q = LOCAL_piece_cat(Q,Pl); U = LOCAL_piece_cat(U,Ul);
      drop = struct('own',[drop.own;d3.own],'area',[drop.area;d3.area]);
    end
    P = Q;
  end
  cert = P.c1==P.c2 & P.r1==P.r2;
  R = struct('G',G,'ok',G.ok,'Pc',LOCAL_piece_select(P,cert), ...
    'Pu',LOCAL_piece_cat(U,LOCAL_piece_select(P,~cert)),'drop',drop);
end

function rec = LOCAL_records(R,I,s,nr,material)
  % Uncertain pieces -> records [node c1 c2 r1 r2 matcode area_ref]; removed
  % remnants and items with a degenerate L_T -> records with the full node
  % rectangle range and both materials (matcode 3).
  o = R.Pu.own; area = abs(LOCAL_poly_area(R.Pu.PX,R.Pu.PY,R.Pu.pn)).*R.G.ref_per_lt(o);
  m = R.Pu.mat; if ~material, m = 0*m; end
  rec = [I.node(s(o)),R.Pu.c1,R.Pu.c2,R.Pu.r1,R.Pu.r2,m,area];
  rec = [rec;LOCAL_dropped_records(R,I,s,nr,false(numel(s),1))];
  bad = find(~R.ok);
  if ~isempty(bad)
    nd = I.node(s(bad)); Rb = I.R(s(bad),:);
    ab = abs((Rb(:,3)-Rb(:,1)).*(Rb(:,6)-Rb(:,2))-(Rb(:,5)-Rb(:,1)).*(Rb(:,4)-Rb(:,2)))/2;
    rec = [rec;nd,nr.c1(nd),nr.c2(nd),nr.r1(nd),nr.r2(nd),3*ones(numel(nd),1),ab];
  end
  if ~material, rec(rec(:,6)==3,6) = 0; end
end

function rec = LOCAL_dropped_records(R,I,s,nr,skip)
  % Removed positive-area remnants (never discarded) of items not in skip.
  k = ~skip(R.drop.own); nd = I.node(s(R.drop.own(k)));
  rec = [nd,nr.c1(nd),nr.c2(nd),nr.r1(nd),nr.r2(nd),3*ones(numel(nd),1),R.drop.area(k)];
end

function rec = LOCAL_merge_records(rec)
  if isempty(rec), rec = zeros(0,7); return, end
  [u,~,i] = unique(rec(:,1:6),'rows'); rec = [u,accumarray(i,rec(:,7))];
end

function cov = LOCAL_coverage(E,nodes,sp)
  % Reference-area coverage per special element: integrated certain pieces
  % (F type) + F records must equal 1/2 (likewise P type for curved elements).
  ae = zeros(max([sp;1]),1); ap = ae; ne = numel(ae);
  if ~isempty(E.accF.area_e), ae = ae+accumarray(E.accF.area_e,E.accF.area_v,[ne,1]); end
  if ~isempty(E.recF), ae = ae+accumarray(nodes.e(E.recF(:,1)),E.recF(:,7),[ne,1]); end
  if ~isempty(E.accP.area_e), ap = ap+accumarray(E.accP.area_e,E.accP.area_v,[ne,1]); end
  if ~isempty(E.recP), ap = ap+accumarray(nodes.e(E.recP(:,1)),E.recP(:,7),[ne,1]); end
  dF = abs(ae(sp)-0.5)/0.5; pe = unique([E.accP.area_e;nodes.e(E.recP(:,1))]);
  dP = abs(ap(pe)-0.5)/0.5;
  cov = struct('F_max_relative_defect',max([dF;0]),'P_max_relative_defect',max([dP;0]), ...
    'F_elements',numel(sp),'P_elements',numel(pe), ...
    'F_record_area',sum(E.recF(:,7)),'P_record_area',sum(E.recP(:,7)));
end

function A = LOCAL_eng_aggregate(TL,E,CT,VT,BG,with_p)
  % Per cell of the template: certain part of the source defect moments
  % (complex, per special rectangle), radii of the uncertain records, the
  % certain/uncertain parts of int |g|^2 J and (with_p) of int |p|^2 J.
  NR = TL.N^2; nc = TL.ncell; nsr = size(CT,1); h = TL.h;
  [ii,jj] = find(triu(ones(6)));
  dcert = zeros(nsr,4,nc,'like',1i); rad = zeros(nsr,4,nc);
  A = struct('If_cert',zeros(1,nc),'If_unc',zeros(1,nc),'Iu_cert',zeros(1,nc),'Iu_unc',zeros(1,nc));
  % --- certain F groups: alpha A_f' u - G c ---
  key = E.accF.key; nk = numel(key);
  if nk>0
    mat = mod(key,2)+1; rest = (key-mat+1)/2; e = floor(rest/NR)+1; rect = rest-(e-1)*NR;
    ri = TL.srect(rect+1); assert(all(ri>0),'i96:SpecialRect','F group outside the special rectangles.');
    V = E.accF.val; Af = reshape(V(:,1:24),nk,6,4); Gv = V(:,25:45);
    U = LOCAL_group_u(TL,e); al = reshape(TL.alpha(mat),[],1);
    AU = zeros(nk,4,nc,'like',1i);
    for b = 1:4, AU(:,b,:) = sum(Af(:,:,b).*U,2); end
    C = CT(ri,:,:); quad = LOCAL_qform(Gv,U,ii,jj);
    A.If_cert = A.If_cert+sum(al.^2.*quad,1)-2*reshape(sum(al.*real(sum(conj(C).*AU,2)),1),1,nc);
    for c = 1:nc
      for b = 1:4
        dcert(:,b,c) = dcert(:,b,c)+complex(accumarray(ri,al.*real(AU(:,b,c)),[nsr,1]), ...
          accumarray(ri,al.*imag(AU(:,b,c)),[nsr,1]));
      end
    end
  end
  rk = E.accF.rkey;
  if ~isempty(rk)
    rri = TL.srect(rk+1); assert(all(rri>0),'i96:SpecialRect','F rectangle Gram outside the special set.');
    Gr = LOCAL_sym_full(E.accF.rval,4);
    for c = 1:nc
      Cr = CT(rri,:,c); GC = reshape(sum(Gr.*reshape(Cr,[],1,4),3),[],4);
      dcert(rri,:,c) = dcert(rri,:,c)-GC;
      A.If_cert(c) = A.If_cert(c)+sum(real(conj(Cr).*GC),'all');
    end
  end
  % --- uncertain F records: radii and upper bounds ---
  rec = E.recF;
  if ~isempty(rec)
    [xr,xc,xw] = LOCAL_expand_records(rec);
    [up,~,iu] = unique([rec(xr,1),xc,xw],'rows');
    S = LOCAL_node_sup(TL,E.nodes,up(:,1),up(:,2),up(:,3),'F',CT,BG);
    m = rec(xr,6); sO = S.out(iu,:); sI = S.in(iu,:);
    s = sO; s(m==2,:) = sI(m==2,:); s(m==3,:) = max(sO(m==3,:),sI(m==3,:));
    jh = E.Jhi(rec(xr,1)); ar = rec(xr,7);
    phimax = [1,sqrt(3),sqrt(3),3]/h;
    ri = TL.srect(xw+TL.N*xc+1); assert(all(ri>0),'i96:SpecialRect','Record rectangle outside the special set.');
    for c = 1:nc
      for b = 1:4, rad(:,b,c) = rad(:,b,c)+accumarray(ri,ar.*jh.*s(:,c)*phimax(b),[nsr,1]); end
      A.If_unc(c) = A.If_unc(c)+sum(rec(:,7).*E.Jhi(rec(:,1)).*accumarray(xr,s(:,c).^2,[size(rec,1),1],@max));
    end
  end
  A.dcert = dcert; A.rad = rad;
  if ~with_p, return, end
  % --- P type: curved elements ---
  key = E.accP.key; nk = numel(key);
  if nk>0
    e = floor(key/NR)+1; rect = key-(e-1)*NR; ri = TL.srect(rect+1);
    assert(all(ri>0),'i96:SpecialRect','P group outside the special rectangles.');
    V = E.accP.val; Av = reshape(V(:,1:54),nk,6,9); Gv = V(:,55:75);
    U = LOCAL_group_u(TL,e); quad = LOCAL_qform(Gv,U,ii,jj);
    AU = zeros(nk,9,nc,'like',1i);
    for b = 1:9, AU(:,b,:) = sum(Av(:,:,b).*U,2); end
    Vk = VT(ri,:,:);
    A.Iu_cert = A.Iu_cert+sum(quad,1)-2*reshape(sum(real(sum(conj(Vk).*AU,2)),1),1,nc);
  end
  rk = E.accP.rkey;
  if ~isempty(rk)
    rri = TL.srect(rk+1); Gr = LOCAL_sym_full(E.accP.rval,9);
    for c = 1:nc
      Vr = VT(rri,:,c); GV = reshape(sum(Gr.*reshape(Vr,[],1,9),3),[],9);
      A.Iu_cert(c) = A.Iu_cert(c)+sum(real(conj(Vr).*GV),'all');
    end
  end
  rec = E.recP;
  if ~isempty(rec)
    [xr,xc,xw] = LOCAL_expand_records(rec);
    [up,~,iu] = unique([rec(xr,1),xc,xw],'rows');
    S = LOCAL_node_sup(TL,E.nodes,up(:,1),up(:,2),up(:,3),'P',VT,BG);
    s = S.p(iu,:);
    for c = 1:nc
      A.Iu_unc(c) = A.Iu_unc(c)+sum(rec(:,7).*E.Jhi(rec(:,1)).*accumarray(xr,s(:,c).^2,[size(rec,1),1],@max));
    end
  end
end

function [xr,xc,xw] = LOCAL_expand_records(rec)
  % (record, col, row) triples of every rectangle in each record's range.
  nc = rec(:,3)-rec(:,2)+1; nw = rec(:,5)-rec(:,4)+1; cnt = nc.*nw;
  xr = LOCAL_rep((1:size(rec,1))',cnt); k = (0:sum(cnt)-1)'-LOCAL_rep(cumsum(cnt)-cnt,cnt);
  nwr = nw(xr); xc = rec(xr,2)+floor(k./nwr); xw = rec(xr,4)+mod(k,nwr);
end

function U = LOCAL_group_u(TL,e)
  % Element P2 coefficients of every cell: nk x 6 x ncell.
  nk = numel(e); U = zeros(nk,6,TL.ncell,'like',1i);
  for i = 1:6, U(:,i,:) = reshape(TL.Coef(TL.tri6(e,i),:),nk,1,TL.ncell); end
end

function q = LOCAL_qform(Gv,U,ii,jj)
  % u^H G u for symmetric real G stored as upper-triangle entries (nk x 21).
  nk = size(U,1); q = 0;
  for k = 1:numel(ii)
    ui = reshape(U(:,ii(k),:),nk,[]);
    if ii(k)==jj(k)
      q = q+Gv(:,k).*abs(ui).^2;
    else
      q = q+2*Gv(:,k).*real(conj(ui).*reshape(U(:,jj(k),:),nk,[]));
    end
  end
end

function G = LOCAL_sym_full(W,n)
  % Upper-triangle columns (find(triu(ones(n))) order) -> nr x n x n.
  [ii,jj] = find(triu(ones(n))); G = zeros(size(W,1),n,n);
  for k = 1:numel(ii), G(:,ii(k),jj(k)) = W(:,k); G(:,jj(k),ii(k)) = W(:,k); end
end

%% ==================== D2 Fourier correction, Yukawa norms with remainders ====================
% Source correction moments, per-batch Yukawa sweeps with coefficient radii,
% Taylor-polynomial norms (exact Gauss) with explicit exponential remainders.
function SA = LOCAL_fourier_correction(SA,Delta,lev,common,block_dir,batch_modes)
  % Fourier moments of the one-time source correction Delta (special
  % rectangles only; linear, so F' = F + dF), corrected column energies and
  % l1 column norms (series radii use |c~ + Delta| <= |c~| + |Delta|).
  N = lev.N; ncs0 = lev.strip_columns; TL = SA.TL; ncell = TL.ncell;
  mvec = SA.mvec; nm = numel(mvec); h = 1/N;
  shift = exp(1i*pi*mvec*(1-h)); fidx = mod(mvec,N)+1;
  yj = -0.5+((0:N-1)'+0.5)*h; ybeta = exp(-1i*common.beta*yj);
  nbatch = ceil(nm/batch_modes); SA.corr_files = {};
  scols = unique(TL.srect_col);
  for j0 = unique(floor(scols/ncs0)*ncs0)'
    cols = j0:min(j0+ncs0,N)-1; ncs = numel(cols);
    in = find(TL.srect_col>=cols(1) & TL.srect_col<=cols(end));
    dC = zeros(N,ncs,4,ncell,'like',1i); C0 = dC;
    lin = TL.srect_row(in)+1+N*(TL.srect_col(in)-cols(1));
    for b = 1:4
      for c = 1:ncell
        slab = zeros(N*ncs,1,'like',1i); slab(lin) = Delta(in,b,c); dC(:,:,b,c) = reshape(slab,N,ncs);
        slab(lin) = SA.CT(in,b,c); C0(:,:,b,c) = reshape(slab,N,ncs);
      end
    end
    gc = cols+1;
    % column energy update: sum |c~+D|^2 - |c~|^2 over the special rectangles
    SA.colEF(gc,:) = SA.colEF(gc,:)+reshape(sum(sum(abs(C0+dC).^2-abs(C0).^2,1),3),ncs,ncell);
    SA.n1F(gc,:,:) = SA.n1F(gc,:,:)+reshape(sum(abs(dC),1),ncs,4,ncell);
    [dF,~] = LOCAL_fourier_strip(dC,zeros(N,ncs,9,ncell),SA.J,ybeta,fidx,shift);
    if ~isempty(block_dir)
      blk = struct('cols',cols);
      for b = 1:nbatch
        mi = (b-1)*batch_modes+1:min(b*batch_modes,nm);
        blk.(sprintf('dF_b%03d',b)) = dF(mi,:,:,:);
      end
      file = fullfile(block_dir,sprintf('%s_s%04d_corr.mat',SA.name,j0));
      save(file,'-struct','blk','-v7.3','-nocompression'); SA.corr_files{end+1} = file;
    end
  end
end

function [g0,g1,r0,r1] = LOCAL_gamma01(z)
  % gamma_r(z) = int_0^1 s^r exp(-z s) ds, r = 0,1: series for z < 1/2 (25
  % terms, alternating and decreasing: first omitted term bounds the
  % remainder r0, r1), closed form with expm1 (exact primitive) otherwise.
  g0 = zeros(size(z)); g1 = g0; r0 = g0; r1 = g0; small = z<0.5; zs = z(small);
  term = ones(size(zs)); s0 = zeros(size(zs)); s1 = s0;
  for k = 0:24
    s0 = s0+term/(k+1); s1 = s1+term/(k+2); term = term.*(-zs)/(k+1);
  end
  g0(small) = s0; g1(small) = s1; r0(small) = abs(term)/26; r1(small) = abs(term)/27;
  zl = z(~small);
  g0(~small) = -expm1(-zl)./zl; g1(~small) = (1-exp(-zl).*(1+zl))./zl.^2;
end

function Y = LOCAL_yukawa_batch(h,q,s,F,V,rF,rV,taylor_n)
  % Modes q (column), x-columns of F (nm x nc x 2 Legendre source) and V
  % (nm x nc x 3 Legendre field) with radii rF, rV. On interval i, t in
  % [0,h], f = A + B t and (design 5.2)
  %   w = (A+Bt)/a^2 + z- e^{-at} + z+ e^{-a(h-t)},
  %   z- = (L_i - A/a + B/a^2)/(2a), z+ = (R_{i+1} - (A+Bh)/a - B/a^2)/(2a),
  % L_{i+1} = E L_i + h((A+Bh) g0 - B h g1), R_i = E R_{i+1} + h(A g0 + B h g1).
  % Norms: with c = ah/2 and s = 2t/h-1, e^{-at} = e^{-c} e^{-cs}; the Taylor
  % polynomial of degree n of e^{-+cs} gives a polynomial r_n of degree n,
  % integrated exactly by (n+1)-point Gauss. |e^{-c}(e^{-+cs}-T_n)| <= c^{n+1}/(n+1)!,
  % coefficient radii propagate linearly; sup|r - r_n| <= xi, so
  % ||r|| in [max(0,||r_n|| - sqrt(h) xi), ||r_n|| + sqrt(h) xi].
  [nm,nc,~] = size(F); a = sqrt(s+q.^2); z = a*h; E = exp(-z);
  [g0,g1,rg0,rg1] = LOCAL_gamma01(z); sh = sqrt(h); r3 = sqrt(3); r5 = sqrt(5);
  A = (F(:,:,1)-r3*F(:,:,2))/sh; B = 2*r3*F(:,:,2)/h^1.5;
  rA = (rF(:,:,1)+r3*rF(:,:,2))/sh; rB = 2*r3*rF(:,:,2)/h^1.5;
  incL = (A+B*h)*h.*g0-B*h^2.*g1; incR = A*h.*g0+B*h^2.*g1;
  eincL = (rA+rB*h)*h.*g0+rB*h^2.*g1+abs(A+B*h)*h.*rg0+abs(B)*h^2.*rg1;
  eincR = rA*h.*g0+rB*h^2.*g1+abs(A)*h.*rg0+abs(B)*h^2.*rg1;
  L = zeros(nm,nc+1,'like',1i); Rn = L; eL = zeros(nm,nc+1); eR = eL;
  for i = 1:nc
    L(:,i+1) = E.*L(:,i)+incL(:,i); eL(:,i+1) = E.*eL(:,i)+eincL(:,i);
  end
  for i = nc:-1:1
    Rn(:,i) = E.*Rn(:,i+1)+incR(:,i); eR(:,i) = E.*eR(:,i+1)+eincR(:,i);
  end
  zm = (L(:,1:nc)-A./a+B./a.^2)./(2*a); zp = (Rn(:,2:nc+1)-(A+B*h)./a-B./a.^2)./(2*a);
  ezm = (eL(:,1:nc)+rA./a+rB./a.^2)./(2*a); ezp = (eR(:,2:nc+1)+(rA+rB*h)./a+rB./a.^2)./(2*a);
  c = z/2; tay = exp((taylor_n+1)*log(c)-gammaln(taylor_n+2));
  xi_w = (abs(zm)+abs(zp)+ezm+ezp).*tay+(rA+rB*h)./a.^2+ezm+ezp;
  xi_vw = xi_w+(rV(:,:,1)+r3*rV(:,:,2)+r5*rV(:,:,3))/sh;
  % (n+1)-point Gauss on s in [-1,1]
  [xg,wg] = LOCAL_gauss01(taylor_n+1); sg = 2*xg'-1; wg = wg';
  kfac = exp(-gammaln((0:taylor_n)+1));
  Em = zeros(nm,numel(sg)); Ep = Em;
  for g = 1:numel(sg)
    Em(:,g) = exp(-c).*(((-c*sg(g)).^(0:taylor_n))*kfac');
    Ep(:,g) = exp(-c).*(((c*sg(g)).^(0:taylor_n))*kfac');
  end
  nw2 = zeros(nm,nc); nd2 = nw2;
  for g = 1:numel(sg)
    t = h*(1+sg(g))/2; s1 = sg(g);
    w = (A+B*t)./a.^2+zm.*Em(:,g)+zp.*Ep(:,g);
    v = (V(:,:,1)+r3*V(:,:,2)*s1+r5*V(:,:,3)*(3*s1^2-1)/2)/sh;
    nw2 = nw2+h*wg(g)*abs(w).^2; nd2 = nd2+h*wg(g)*abs(v-w).^2;   % wg sums to 1 on [0,1]
  end
  % low-cost check (design 5.4): old-style 12-point Gauss with exact exponentials
  [xc,wc] = LOCAL_gauss01(12); cw2 = zeros(nm,nc); cd2 = cw2;
  for g = 1:12
    t = h*xc(g); s1 = 2*xc(g)-1;
    w = (A+B*t)./a.^2+zm.*exp(-a*t)+zp.*exp(-a*(h-t));
    v = (V(:,:,1)+r3*V(:,:,2)*s1+r5*V(:,:,3)*(3*s1^2-1)/2)/sh;
    cw2 = cw2+h*wc(g)*abs(w).^2; cd2 = cd2+h*wc(g)*abs(v-w).^2;
  end
  nw = sqrt(nw2); nd = sqrt(nd2); dw = sh*xi_w; dd = sh*xi_vw;
  Y = struct('w2_lo',sum(max(0,nw-dw).^2,1),'w2_hi',sum((nw+dw).^2,1), ...
    'vw2_lo',sum(max(0,nd-dd).^2,1),'vw2_hi',sum((nd+dd).^2,1), ...
    'w2_mode_lo',sum(max(0,nw-dw).^2,2),'w2_mode_hi',sum((nw+dw).^2,2), ...
    'vw2_mode_lo',sum(max(0,nd-dd).^2,2),'vw2_mode_hi',sum((nd+dd).^2,2), ...
    'w2_mid',sum(nw2,1),'vw2_mid',sum(nd2,1),'check_w2_12',sum(cw2,'all'),'check_vw2_12',sum(cd2,'all'), ...
    'taylor_max',max(tay),'xi_w_max',max(xi_w,[],'all'),'xi_vw_max',max(xi_vw,[],'all'), ...
    'taylor_part_w2',sum(2*nw.*sh.*(abs(zm)+abs(zp)+ezm+ezp).*tay,'all'));
  % exterior exponential tails of w_d (f_d = 0 outside the box)
  wl = Rn(:,1)./(2*a); rl = eR(:,1)./(2*a); wr = L(:,end)./(2*a); rr = eL(:,end)./(2*a);
  Y.Td2_mode_lo = (max(0,abs(wl)-rl).^2+max(0,abs(wr)-rr).^2)./(2*a);
  Y.Td2_mode_hi = ((abs(wl)+rl).^2+(abs(wr)+rr).^2)./(2*a);
  Y.w2_mode_mid = sum(nw2,2); Y.vw2_mode_mid = sum(nd2,2);
  Y.Td2_mode_mid = (abs(wl).^2+abs(wr).^2)./(2*a);
  % Parseval mode sums with radii (E_y^2, T_v^2 intervals per column)
  Y.F2_hi = sum((abs(F)+rF).^2,[1,3]); Y.F2_lo = sum(max(0,abs(F)-rF).^2,[1,3]);
  Y.F2_mid = sum(abs(F).^2,[1,3]);
  Y.V2_hi = sum((abs(V)+rV).^2,[1,3]); Y.V2_lo = sum(max(0,abs(V)-rV).^2,[1,3]);
  Y.V2_mid = sum(abs(V).^2,[1,3]);
  Y.source_energy_mode = sum(abs(F).^2,[2,3]); Y.field_energy_mode = sum(abs(V).^2,[2,3]);
end

function NR = LOCAL_norms_level(ctx,SAs,lev,common,block_dir,batch_modes,taylor_n)
  % All 32-mode batches: read the strip files of every template (plus the
  % correction moments), assemble the global columns, run the Yukawa batch.
  config = ctx.config; N = lev.N; M = lev.M; h = 1/N; nc = config.field.cells_per_side;
  ncols = (2*nc+1)*N; mvec = (-M:M)'; nm = numel(mvec); q = common.beta+2*pi*mvec;
  nbatch = ceil(nm/batch_modes); t0 = tic; io = 0;
  acc = struct('w2_lo',zeros(1,ncols),'w2_hi',zeros(1,ncols),'vw2_lo',zeros(1,ncols), ...
    'vw2_hi',zeros(1,ncols),'w2_mid',zeros(1,ncols),'vw2_mid',zeros(1,ncols), ...
    'F2_hi',zeros(1,ncols),'F2_lo',zeros(1,ncols),'F2_mid',zeros(1,ncols), ...
    'V2_hi',zeros(1,ncols),'V2_lo',zeros(1,ncols),'V2_mid',zeros(1,ncols), ...
    'check_w2_12',0,'check_vw2_12',0,'taylor_max',0,'xi_w_max',0,'xi_vw_max',0,'taylor_part_w2',0);
  modes = struct('m',mvec,'q',q,'a',sqrt(common.s+q.^2),'w2_lo',zeros(nm,1),'w2_hi',zeros(nm,1), ...
    'vw2_lo',zeros(nm,1),'vw2_hi',zeros(nm,1),'Td2_lo',zeros(nm,1),'Td2_hi',zeros(nm,1), ...
    'w2_mid',zeros(nm,1),'vw2_mid',zeros(nm,1),'Td2_mid',zeros(nm,1), ...
    'source_energy',zeros(nm,1),'field_energy',zeros(nm,1));
  % radii of the global columns: rF_a(m,col) = sum_b rJ_b(m) n1(col, 1+a+2b)
  n1F = zeros(ncols,4); n1V = zeros(ncols,9); colEF = zeros(ncols,1); colEV = colEF;
  for k = 1:numel(SAs)
    for c = 1:SAs(k).TL.ncell
      gc = SAs(k).gcol0(c)+(1:N);
      n1F(gc,:) = SAs(k).n1F(:,:,c); n1V(gc,:) = SAs(k).n1V(:,:,c);
      colEF(gc) = SAs(k).colEF(:,c); colEV(gc) = SAs(k).colEV(:,c);
    end
  end
  rJ = SAs(1).rJ;
  for b = 1:nbatch
    mi = (b-1)*batch_modes+1:min(b*batch_modes,nm); nb = numel(mi);
    LOCAL_memory_gate(config,'mode batch',nb*ncols*10*16*3);
    F = zeros(nb,ncols,2,'like',1i); V = zeros(nb,ncols,3,'like',1i);
    ti = tic;
    for k = 1:numel(SAs)
      files = SAs(k).stats.files;
      for f = 1:numel(files)
        d = load(files{f},sprintf('F_b%03d',b),sprintf('V_b%03d',b),'cols');
        Fb = d.(sprintf('F_b%03d',b)); Vb = d.(sprintf('V_b%03d',b));
        cf = [files{f}(1:end-4),'_corr.mat'];
        if isfile(cf)
          dc = load(cf,sprintf('dF_b%03d',b)); Fb = Fb+dc.(sprintf('dF_b%03d',b));
        end
        for c = 1:SAs(k).TL.ncell
          gc = SAs(k).gcol0(c)+d.cols+1;
          F(:,gc,:) = Fb(:,:,:,c); V(:,gc,:) = Vb(:,:,:,c);
        end
      end
    end
    io = io+toc(ti);
    rF = zeros(nb,ncols,2); rV = zeros(nb,ncols,3);
    for a = 0:1, rF(:,:,a+1) = rJ(mi,1).*n1F(:,1+a)'+rJ(mi,2).*n1F(:,3+a)'; end
    for a = 0:2, rV(:,:,a+1) = rJ(mi,1).*n1V(:,1+a)'+rJ(mi,2).*n1V(:,4+a)'+rJ(mi,3).*n1V(:,7+a)'; end
    Y = LOCAL_yukawa_batch(h,q(mi),common.s,F,V,rF,rV,taylor_n);
    for f = {'w2_lo','w2_hi','vw2_lo','vw2_hi','w2_mid','vw2_mid','F2_hi','F2_lo','F2_mid', ...
        'V2_hi','V2_lo','V2_mid','check_w2_12','check_vw2_12','taylor_part_w2'}
      acc.(f{1}) = acc.(f{1})+Y.(f{1});
    end
    for f = {'taylor_max','xi_w_max','xi_vw_max'}, acc.(f{1}) = max(acc.(f{1}),Y.(f{1})); end
    modes.w2_lo(mi) = Y.w2_mode_lo; modes.w2_hi(mi) = Y.w2_mode_hi;
    modes.vw2_lo(mi) = Y.vw2_mode_lo; modes.vw2_hi(mi) = Y.vw2_mode_hi;
    modes.Td2_lo(mi) = Y.Td2_mode_lo; modes.Td2_hi(mi) = Y.Td2_mode_hi;
    modes.w2_mid(mi) = Y.w2_mode_mid; modes.vw2_mid(mi) = Y.vw2_mode_mid; modes.Td2_mid(mi) = Y.Td2_mode_mid;
    modes.source_energy(mi) = Y.source_energy_mode; modes.field_energy(mi) = Y.field_energy_mode;
  end
  % Parseval tails (exact finite sums): column energy minus retained modes
  tailF_hi = colEF'-acc.F2_lo; tailF_lo = colEF'-acc.F2_hi; tailF_mid = colEF'-acc.F2_mid;
  tailV_hi = colEV'-acc.V2_lo; tailV_lo = colEV'-acc.V2_hi; tailV_mid = colEV'-acc.V2_mid;
  NR = struct('taylor_n',taylor_n,'batches',nbatch,'batch_modes',batch_modes,'io_seconds',io, ...
    'seconds',toc(t0),'modes',modes,'acc_scalars',rmfield(acc,{'w2_lo','w2_hi','vw2_lo','vw2_hi', ...
    'w2_mid','vw2_mid','F2_hi','F2_lo','F2_mid','V2_hi','V2_lo','V2_mid'}));
  NR.Iw_box = [sum(acc.w2_lo),sum(acc.w2_hi)]; NR.Ivw_box = [sum(acc.vw2_lo),sum(acc.vw2_hi)];
  NR.Td2 = [sum(modes.Td2_lo),sum(modes.Td2_hi)];
  NR.Ey2_raw = sum(tailF_mid); NR.Tv2_raw = sum(tailV_mid);
  NR.Ey2_interval_raw = [sum(tailF_lo),sum(tailF_hi)]; NR.Tv2_interval_raw = [sum(tailV_lo),sum(tailV_hi)];
  NR.negative_column_tail_upper = [nnz(tailF_hi<0),nnz(tailV_hi<0)];
  NR.ordinary = struct('w2_in_box',sum(acc.w2_mid),'vw2_in_box',sum(acc.vw2_mid), ...
    'Td2',sum(modes.Td2_mid),'check_w2_12',acc.check_w2_12,'check_vw2_12',acc.check_vw2_12);
  owner = floor((0:ncols-1)'/N)+1;
  NR.cell = struct('index',-nc:nc,'w2_hi',accumarray(owner,acc.w2_hi',[2*nc+1,1])', ...
    'vw2_hi',accumarray(owner,acc.vw2_hi',[2*nc+1,1])','tailF_mid',accumarray(owner,tailF_mid',[2*nc+1,1])', ...
    'tailV_mid',accumarray(owner,tailV_mid',[2*nc+1,1])');
end

%% ==================== D2 main-level pilot and cost gate ====================
% Design 6.3 / 7.2: one centre-template strip with the formal algorithm, actual
% tightening per round, class throughputs and the mandatory-flow prediction.
function P = LOCAL_pilot(ctx,native,lev,common)
  config = ctx.config; clock = @()toc(ctx.started); t0 = clock(); N = lev.N; ncs = lev.strip_columns;
  h = 1/N; names = {'left','center','right'};
  P = struct('level',lev.name,'seconds_limit',config.pilot.seconds,'templates',struct([]), ...
    'pass',false,'reason','','closure_prediction','','seconds',NaN);
  % --- census of the three templates (geometry only, no strips) ---
  opt0 = struct('strips',zeros(1,0),'block_dir','','batch_modes',config.norms.batch_modes,'S0',config.engine.S0);
  nspec = zeros(1,3); ncurv = nspec; ncell = nspec; tgeo = nspec;
  for k = 1:3
    tg = tic; S = LOCAL_stageA(ctx,native,lev,common,names{k},opt0); tgeo(k) = toc(tg);
    nspec(k) = S.census.n_special; ncurv(k) = S.census.n_curved; ncell(k) = S.TL.ncell;
    P.templates = LOCAL_append(P.templates,struct('template',names{k},'census', ...
      rmfield(S.census,{'special','inside','curved'}),'ncell',ncell(k),'geometry_seconds',tgeo(k)));
    if k==2, SC = S; end
  end
  % --- strip choice: special count x field amplitude (centre template) ---
  TL = SC.TL; sp = find(TL.special);
  xmin = min(TL.X6(sp,:),[],2); xmax = max(TL.X6(sp,:),[],2);
  amp = max(reshape(abs(TL.Coef(TL.tri6(sp,:),1)),numel(sp),6),[],2);
  best = -1; j0 = 0;
  for j = 0:ncs:N-1
    in = xmax>TL.x0+j*h & xmin<TL.x0+(j+ncs)*h;
    sc = nnz(in)*max([amp(in);0]);
    if sc>best, best = sc; j0 = j; end
  end
  in = xmax>TL.x0+j0*h & xmin<TL.x0+(j0+ncs)*h; el = sp(in);
  c_lo = max(floor((min(xmin(in))-TL.x0)/h)-1,0); c_hi = min(floor((max(xmax(in))-TL.x0)/h)+1,N-1);
  strips = unique(floor((c_lo:c_hi)/ncs)*ncs);
  % --- formal prediction/bulk pass on the strips, engine on the elements ---
  ts = tic;
  opt = struct('strips',strips,'block_dir','','batch_modes',config.norms.batch_modes,'S0',config.engine.S0);
  S = LOCAL_stageA(ctx,native,lev,common,'center',opt);
  stageA_seconds = toc(ts); strip_seconds = (S.seconds-S.geometry_seconds)/numel(strips);
  BG = struct('b2',LOCAL_bern_inv(2),'b4',LOCAL_bern_inv(4),'b8',LOCAL_bern_inv(8));
  eopt = LOCAL_engine_opt(config,common,clock,t0+config.pilot.seconds,numel(el)/sum(nspec));
  eopt.elements = el;
  te = tic; E = LOCAL_engine(S.TL,S.CT,BG,eopt); engine_seconds = toc(te);
  ta = tic; A = LOCAL_eng_aggregate(S.TL,E,S.CT,S.VT,BG,true); agg_seconds = toc(ta);
  % pilot enclosure of the moment term of these elements (uncorrected and centred)
  phi_l1 = h*[1,sqrt(3)/2,sqrt(3)/2,3/4]; Dc = S.DB+A.dcert;
  e0 = sqrt((abs(real(Dc))+A.rad).^2+(abs(imag(Dc))+A.rad).^2); e1 = sqrt(2)*A.rad;
  % complete moments: rectangles of the core strip (one column margin), whose
  % special elements all intersect the core strip and are engine elements
  sel = S.TL.srect_col>=j0+1 & S.TL.srect_col<=j0+ncs-2;
  T0 = common.CG*sum(e0(sel,:,:).*phi_l1,'all'); T1 = common.CG*sum(e1(sel,:,:).*phi_l1,'all');
  rounds = E.rounds; sc = [rounds.score];
  tight = numel(sc)>=2 && sc(end)<sc(1);
  complete = E.coverage.F_max_relative_defect<=config.engine.coverage_tolerance && ...
    E.coverage.P_max_relative_defect<=config.engine.coverage_tolerance && all(isfinite([T0,T1]));
  % --- mandatory-flow prediction (measured rates, safety factor) ---
  nn = E.counts.nodes; r1 = rounds(1);
  rate_score = E.seconds.score/max(nn,1); rate_F1 = r1.seconds/max(r1.active,1);
  rate_P = E.seconds.p_type/max(E.counts.curved_nodes,1);
  frac_curved = E.counts.curved_nodes/max(nn,1);
  node_cost = (1+eopt.post_factor)*rate_score+2*rate_F1+frac_curved*rate_P;
  nodes_total = 4^config.engine.start_level*sum(nspec);
  sf = config.pilot.safety; Ls = numel(config.levels);
  % stage A per template scales at most linearly with the cell count
  stageA_main = sum((N/ncs)*strip_seconds*ncell/ncell(2)+tgeo);
  stageA_all = stageA_main*(1+(Ls>1)*0.5);
  engine_all = Ls*nodes_total*node_cost;
  plan = config.plan;
  predicted = clock()+sf*(stageA_all+engine_all)+sum(plan.norms_reserve)+plan.save_reserve;
  within = predicted<=config.resources.soft_seconds;
  % --- closure prediction (at most max_future_rounds future rounds) ---
  target = config.engine.target_fraction*common.b*numel(el)/sum(nspec);
  if any(strcmp(E.stop,{'TARGET','COMPLETE'}))
    P.closure_prediction = 'CLOSED_IN_PILOT';
  elseif numel(sc)>=2 && sc(end)<sc(end-1) && sc(end)>0
    ratio = sc(end)/sc(end-1); need = ceil(log(target/sc(end))/log(ratio));
    if need<=config.pilot.max_future_rounds
      P.closure_prediction = sprintf('CLOSURE_PREDICTED_IN_%d_ROUNDS',need);
    else
      P.closure_prediction = sprintf('PREDICTION_EVIDENCE_INSUFFICIENT (needs %d > %d future rounds at ratio %.3f)', ...
        need,config.pilot.max_future_rounds,ratio);
    end
  else
    P.closure_prediction = 'PREDICTION_EVIDENCE_INSUFFICIENT (no decreasing score pair)';
  end
  P.strip_first_column = j0; P.strips = strips; P.columns = [c_lo,c_hi]; P.elements = numel(el);
  P.engine = struct('stop',E.stop,'counts',E.counts,'seconds',E.seconds,'coverage',E.coverage,'rounds',rounds);
  P.measured = struct('stageA_seconds',stageA_seconds,'strip_seconds',strip_seconds, ...
    'engine_seconds',engine_seconds,'aggregate_seconds',agg_seconds,'rate_score_per_node',rate_score, ...
    'rate_F_round1_per_item',rate_F1,'rate_P_per_curved_node',rate_P,'node_cost',node_cost, ...
    'moment_term_uncorrected',T0,'moment_term_centered',T1,'pilot_target',target, ...
    'If_unc',A.If_unc,'Iu_unc',A.Iu_unc,'score_per_round',sc);
  P.prediction = struct('note',['prediction of the mandatory finite-enclosure flow (stage A, level-', ...
    num2str(config.engine.start_level),' rounds, final pass, aggregation, norms, save) from measured ', ...
    'rates x safety; not an error bound and not a lower bound of the necessary cost'], ...
    'nodes_total',nodes_total,'stageA_all',stageA_all,'engine_all',engine_all,'safety',sf, ...
    'predicted_finish',predicted,'soft_seconds',config.resources.soft_seconds,'within_soft',within);
  P.pass = complete && (tight || any(strcmp(E.stop,{'TARGET','COMPLETE'}))) && within;
  if P.pass
    P.reason = 'finite complete enclosure of the pilot strip with measured tightening; mandatory flow predicted within the soft limit';
  else
    why = {};
    if ~complete, why{end+1} = 'pilot enclosure incomplete'; end
    if ~(tight || any(strcmp(E.stop,{'TARGET','COMPLETE'}))), why{end+1} = 'no measured tightening'; end
    if ~within, why{end+1} = sprintf('predicted finish %.0fs > soft %.0fs',predicted,config.resources.soft_seconds); end
    P.reason = strjoin(why,'; ');
  end
  P.seconds = clock()-t0;
  fprintf(['  PILOT %s: strip %d (%d elements), %d rounds, score %.3e -> %.3e, T0 %.3e T1 %.3e, ', ...
    'predicted finish %.0fs, %s; %s (%.1fs)\n'],lev.name,j0,numel(el),numel(sc),sc(1),sc(end),T0,T1, ...
    predicted,P.closure_prediction,P.reason,P.seconds);
end

%% ==================== D2 final status ====================
% Main-level status, both-level contract, resource stop and the four answers.
function [status,reason,detail,acc] = LOCAL_final_d2(config,native,common,levels,pilot,resource_stop)
  st = arrayfun(@(l)l.exact.status,levels,'UniformOutput',false);
  done = arrayfun(@(l)l.completed,levels);
  detail = struct('input_identity',native.identity,'native_qualified',native.qualified, ...
    'pilot_pass',pilot.pass,'pilot_reason',pilot.reason,'closure_prediction',pilot.closure_prediction, ...
    'level_names',{arrayfun(@(l)l.name,levels,'UniformOutput',false)},'level_status',{st}, ...
    'two_level_contract_complete',all(done) && numel(done)==numel(config.levels), ...
    'resource_stop',resource_stop);
  if ~native.qualified
    status = 'NATIVE_FIELD_MISMATCH'; reason = native.summary.reason;
    if config.continue_on_mismatch, reason = [reason,' (smoke probe continued)']; end
  elseif ~isempty(resource_stop)
    status = 'RESOURCE_STOP'; reason = resource_stop;
  elseif ~pilot.pass
    status = 'INTEGRATION_CONTROL_UNRESOLVED'; reason = ['pilot gate: ',pilot.reason];
  elseif ~done(end)
    status = 'INTEGRATION_CONTROL_UNRESOLVED'; reason = levels(end).skip_reason;
  else
    status = levels(end).exact.status; reason = levels(end).exact.reason;
  end
  last = levels(find(done,1,'last'));
  acc = struct();
  if isempty(last)
    acc.main_formula_and_input = sprintf('input %s qualified=%d; no completed level',native.identity,native.qualified);
    acc.non_rounding_error_exits = 'no completed level';
    acc.resolution_target_1e6 = 'not evaluated';
  else
    x = last.exact;
    acc.main_formula_and_input = sprintf(['input %s qualified=%d; level %s: D0^-=%.9f eps0^+=%.3e ', ...
      'denominator positive=%d; R_mu=%.6e R_k=%.6e (%s)'],native.identity,native.qualified,last.name, ...
      x.D0(1),x.eps0,x.denominator_positive,x.R_mu,x.R_k,x.identity);
    acc.non_rounding_error_exits = sprintf('%s; enclosure complete=%d; budgets all pass=%d (failed: %s)', ...
      x.status,last.checks.complete,x.budgets_all_pass,strjoin(x.failed_budgets,', '));
    acc.resolution_target_1e6 = sprintf('R_k=%.6e target %.0e met=%d',x.R_k,common.resolution_target_k, ...
      x.R_k<=common.resolution_target_k);
  end
  acc.resources = 'see timing, peak_rss_matlab_bytes, block_bytes and the launcher resources.csv';
end

%% ==================== D2 self-tests ====================
% Exact rules, engine geometry, correction algebra, Fourier phase, Taylor
% remainders, D2.8, status rejection branches and Q attribution (design 6.1).
function st = LOCAL_selftest_d2(config)
  st = struct('pass',true,'reason','','checks',struct());
  c = struct();
  % 1. Duffy exactness to degree 18 (n = 10) and 10 (n = 6)
  for n = [6,10]
    Q = LOCAL_duffy(n); err = 0; d = 2*n-2;
    for i = 0:d
      for j = 0:d-i
        exact = factorial(i)*factorial(j)/factorial(i+j+2);
        err = max(err,abs(sum(Q.w.*Q.x.^i.*Q.y.^j)-exact)/exact);
      end
    end
    c.(sprintf('duffy%d_degree%d',n,d)) = err;
  end
  % 2-4. synthetic template: affine element, curved element across the
  % trilobe curve of cell 1 and an exactly affine "curved"-flag element
  TL = LOCAL_selftest_template(config); N = TL.N; nsr = N^2;
  rng(5); CT = complex(randn(nsr,4,2),randn(nsr,4,2)); VT = complex(randn(nsr,9,2),randn(nsr,9,2));
  BG = struct('b2',LOCAL_bern_inv(2),'b4',LOCAL_bern_inv(4),'b8',LOCAL_bern_inv(8));
  eopt = LOCAL_engine_opt(config,struct('b',0,'CG',0.25),@()0,Inf,1);
  eopt.level_limit = 6; eopt.start_level = 2; eopt.chunk_items = 5000;
  eopt.quiet = true; E = LOCAL_engine(TL,CT,BG,eopt);
  A = LOCAL_eng_aggregate(TL,E,CT,VT,BG,true);
  c.engine_coverage_F = E.coverage.F_max_relative_defect; c.engine_coverage_P = E.coverage.P_max_relative_defect;
  % exact reference (physical clipping, affine elements 1 and 3 only)
  [Ifx,dx,~] = LOCAL_selftest_exact(config,TL,CT,VT,[1,3]);
  [~,~,Iux] = LOCAL_selftest_exact(config,TL,CT,VT,3);   % P type covers curved-flag elements only
  [Ifx2,dx2,~] = LOCAL_selftest_exact(config,TL,CT,VT,2);  % rough (chord) value, curved element
  % engine contribution of elements 1,3 via a separate run on them alone
  eopt.elements = [1;3]; E13 = LOCAL_engine(TL,CT,BG,eopt);
  A13 = LOCAL_eng_aggregate(TL,E13,CT,VT,BG,true);
  c.affine_If_relative = max(abs(A13.If_cert-Ifx)./abs(Ifx))+max(A13.If_unc./abs(Ifx));
  c.affine_moment_relative = max(abs(A13.dcert-dx),[],'all')/max(abs(dx),[],'all')+max(A13.rad,[],'all');
  c.affine_Iu_relative = max(abs(A13.Iu_cert-Iux)./abs(Iux))+max(A13.Iu_unc./abs(Iux));
  % enclosure sanity for the curved element (chord value lies near the
  % interval; reported only, not a pass criterion)
  c.curved_If_interval = [A.If_cert-A13.If_cert;A.If_cert-A13.If_cert+A.If_unc-A13.If_unc]';
  c.curved_If_chord_value = Ifx2; c.curved_moment_chord_scale = max(abs(dx2),[],'all');
  % independent brute-force reference for the curved element (fine uniform
  % reference subdivision, pointwise exact material and rectangle): the
  % engine enclosures must contain it up to its own discretization change
  [bI1,bd1,bU1] = LOCAL_selftest_brute(TL,CT,VT,2,400); [bI2,bd2,bU2] = LOCAL_selftest_brute(TL,CT,VT,2,800);
  Iu2 = [A.Iu_cert-A13.Iu_cert;A.Iu_cert-A13.Iu_cert+A.Iu_unc-A13.Iu_unc]';
  d2 = A.dcert-A13.dcert; r2 = A.rad-A13.rad;
  tolI = max(1e-4*abs(bI2),4*abs(bI2-bI1)); tolU = max(1e-4*abs(bU2),4*abs(bU2-bU1));
  tolD = max(1e-4*max(abs(bd2),[],'all'),4*max(abs(bd2-bd1),[],'all'));
  c.curved_If_brute = bI2; c.curved_Iu_interval = Iu2; c.curved_Iu_brute = bU2;
  c.curved_If_outside = max(max(c.curved_If_interval(:,1)'-bI2,bI2-c.curved_If_interval(:,2)'),0)./tolI;
  c.curved_Iu_outside = max(max(Iu2(:,1)'-bU2,bU2-Iu2(:,2)'),0)./tolU;
  c.curved_moment_outside = max(max(abs(d2-bd2)-r2,0),[],'all')/tolD;
  c.curved_brute_change = [max(abs(bI2-bI1)./abs(bI2)),max(abs(bU2-bU1)./abs(bU2))];
  % 3. tube caps / cross-grid: certified rect and material of certain pieces
  I = struct('e',2,'R',[0,0,1,0,0,1],'lev',0,'node',1);
  for l = 1:3, I = LOCAL_quadrisect(I,(1:numel(I.e))'); end
  R = LOCAL_eng_clip(TL,I,(1:numel(I.e))',true);
  aC = LOCAL_poly_area(R.Pc.PX,R.Pc.PY,R.Pc.pn).*R.G.ref_per_lt(R.Pc.own);
  aU = LOCAL_poly_area(R.Pu.PX,R.Pu.PY,R.Pu.pn).*R.G.ref_per_lt(R.Pu.own);
  c.tube_area_defect = abs(sum(abs(aC))+sum(abs(aU))+sum(R.drop.area)-0.5)/0.5;
  c.tube_pieces = [numel(R.Pc.pn),numel(R.Pu.pn)]; c.tube_material_both = [nnz(R.Pc.mat==1),nnz(R.Pc.mat==2)];
  [RX,RY] = LOCAL_pull_back(R.G,R.Pc);
  cxr = sum(RX,2,'omitnan')./R.Pc.pn; cyr = sum(RY,2,'omitnan')./R.Pc.pn;
  RX = [RX,cxr]; RY = [RY,cyr]; ok = ~isnan(RX);
  [X,Y] = LOCAL_eval_map(repmat(TL.X6(2,:),size(RX,1),1),repmat(TL.Y6(2,:),size(RX,1),1),RX,RY);
  % exact side for the polar trilobe of cell 1 and exact rectangle
  cv = TL.curve; ph = atan2(Y-cv.cy,X-cv.cx); rr = hypot(X-cv.cx,Y-cv.cy);
  rt = cv.R*(1+cv.a*cos(3*ph)); inside = rr<rt; onc = abs(rr-rt)<=1e-12;
  matok = (R.Pc.mat==2)==inside | onc | ~ok;
  col = floor((X-TL.x0)/TL.h); row = floor((Y-TL.y0)/TL.h);
  onl = abs(X-TL.x0-round((X-TL.x0)/TL.h)*TL.h)<=1e-12 | abs(Y-TL.y0-round((Y-TL.y0)/TL.h)*TL.h)<=1e-12;
  rectok = (col==R.Pc.c1 & row==R.Pc.r1) | onl | ~ok;
  c.tube_material_violations = nnz(~matok); c.tube_rect_violations = nnz(~rectok);
  % 5. known correction: int |g - Delta phi|^2 by the update formula
  np = 400; w = rand(np,1)/np; g = complex(randn(np,1),randn(np,1)); ph4 = randn(np,4);
  DB = (w.*g).'*ph4; Gb = ph4.'*(w.*ph4); Dl = complex(randn(1,4),randn(1,4));
  direct = sum(w.*abs(g-ph4*Dl.').^2); I0 = sum(w.*abs(g).^2);
  upd = I0-2*real(sum(conj(Dl).*DB))+real(Dl*Gb*Dl');
  c.correction_update_relative = abs(upd-direct)/direct;
  % 6. complex-phase y-Fourier factors vs direct quadrature (one column)
  c.fourier_relative = LOCAL_selftest_fourier();
  % 7. Yukawa: D2.8 vs Green formula, Taylor/Gauss norm enclosure vs adaptive quadrature
  [c.yukawa_D28_relative,c.taylor_norm_outside,c.taylor_vw_outside] = LOCAL_selftest_yukawa();
  % 8. rejection branches of the status machine
  c.status_branches = LOCAL_selftest_status(config);
  % 9. Q attribution across rectangle edges and corners
  h = 1/8; x0 = 0.5; e = 1e-12;
  qx = x0+[3*h-e,3*h+e,3*h-e,3*h+e]; qy = -0.5+[2*h-e,2*h-e,2*h+e,2*h+e];
  [qc,qr] = LOCAL_rect_of(qx,qy,x0,h,8);
  c.q_attribution_errors = nnz(qc~=[2,3,2,3])+nnz(qr~=[1,1,2,2]);
  c.bern_cond = [BG.b4.cond,BG.b8.cond];
  st.checks = c;
  tests = {'duffy6_degree10',c.duffy6_degree10<1e-12;'duffy10_degree18',c.duffy10_degree18<1e-12; ...
    'engine_coverage',max(c.engine_coverage_F,c.engine_coverage_P)<1e-12; ...
    'affine_If',c.affine_If_relative<1e-10;'affine_moment',c.affine_moment_relative<1e-10; ...
    'affine_Iu',c.affine_Iu_relative<1e-10;'tube_area',c.tube_area_defect<1e-12; ...
    'curved_enclosure',max([c.curved_If_outside,c.curved_Iu_outside,c.curved_moment_outside])<=1; ...
    'tube_material',c.tube_material_violations==0 && all(c.tube_material_both>0); ...
    'tube_rect',c.tube_rect_violations==0;'correction',c.correction_update_relative<1e-12; ...
    'fourier',c.fourier_relative<1e-10;'yukawa_D28',c.yukawa_D28_relative<1e-10; ...
    'taylor_norm',c.taylor_norm_outside==0 && c.taylor_vw_outside==0; ...
    'status',c.status_branches.pass;'q_attribution',c.q_attribution_errors==0};
  okv = [tests{:,2}]; st.pass = all(okv);
  if ~st.pass, st.reason = strjoin(tests(~okv,1)',','); end
end

function TL = LOCAL_selftest_template(config)
  % Three P2 elements in cell 1 (x0 = 0.5), N = 32, two "cells" of random
  % coefficients. Element 2 straddles the trilobe near theta = 0.
  N = 32; mu = config.k^2;
  V = {[0.62,-0.20;0.71,-0.17;0.65,-0.09],[1.20,-0.03;1.28,-0.02;1.23,0.05],[0.80,0.20;0.88,0.22;0.82,0.29]};
  X6 = zeros(3,6); Y6 = X6;
  for k = 1:3
    P = V{k}; M = [(P(1,:)+P(2,:))/2;(P(2,:)+P(3,:))/2;(P(3,:)+P(1,:))/2];
    if k==2, M = M+[0,-0.004;0.003,0.002;-0.003,0]; end
    X6(k,:) = [P(:,1);M(:,1)]'; Y6(k,:) = [P(:,2);M(:,2)]';
  end
  Jmin = zeros(3,1);
  for e = 1:3
    Jmin(e) = LOCAL_quadratic_triangle_extrema(LOCAL_det_coefficients( ...
      LOCAL_map_coefficients([X6(e,:)',Y6(e,:)'])));
  end
  rng(3); Coef = complex(randn(18,2),randn(18,2));
  lin = (0:N^2-1)'; scol = floor(lin/N);
  TL = struct('name','selftest','cell',1,'X6',X6,'Y6',Y6,'tri6',reshape(1:18,6,3)', ...
    'curved',[false;true;true],'Jmin',Jmin,'det_tol',1e-3,'N',N,'h',1/N,'x0',0.5,'y0',-0.5, ...
    'alpha',mu*[1,17]+mu,'Coef',Coef,'ncell',2,'cells',[1,2], ...
    'curve',LOCAL_curve_info(config,1,config.engine.S0),'special',true(3,1), ...
    'srect',(1:N^2)','srect_col',scol,'srect_row',lin-N*scol);
end

function [If,d,Iu] = LOCAL_selftest_exact(config,TL,CT,VT,elems)
  % Physical exact clipping of the straight triangles of elems (D1/D2 bulk
  % rule) with the background material: int |alpha u - f~|^2, the moments
  % int (alpha u - f~) phi per rectangle and int |u - v|^2, per cell.
  N = TL.N; h = TL.h; duf = LOCAL_duffy(5);
  geo = struct('X6',TL.X6(elems,:),'Y6',TL.Y6(elems,:),'xmin',min(TL.X6(elems,1:3),[],2), ...
    'xmax',max(TL.X6(elems,1:3),[],2),'h',h,'x0',TL.x0,'alpha',TL.alpha(1)*ones(numel(elems),1));
  pts = LOCAL_strip_points(config,geo,struct('N',N),0:N-1,duf);
  e = elems(pts.elem); np = numel(pts.w);
  % reference coordinates by the affine vertex map (exact for affine maps)
  P1x = TL.X6(e,1); P1y = TL.Y6(e,1);
  a11 = TL.X6(e,2)-P1x; a12 = TL.X6(e,3)-P1x; a21 = TL.Y6(e,2)-P1y; a22 = TL.Y6(e,3)-P1y;
  dt = a11.*a22-a12.*a21; dx = pts.x-P1x; dy = pts.y-P1y;
  xi = (a22.*dx-a12.*dy)./dt; eta = (-a21.*dx+a11.*dy)./dt;
  [Nb,~,~] = LOCAL_p2_basis(xi,eta); U = 0;
  for i = 1:6, U = U+Nb{i}.*TL.Coef(TL.tri6(e,i),:); end
  col = floor((pts.rect-1)/N); row = pts.rect-1-N*col; rect = row+N*col+1;
  Phi = LOCAL_rect_basis(TL,pts.x,pts.y,col,row,1); Psi = LOCAL_rect_basis(TL,pts.x,pts.y,col,row,2);
  If = zeros(1,2); Iu = If; d = zeros(N^2,4,2,'like',1i);
  for c = 1:2
    f = 0; for b = 1:4, f = f+Phi{b}.*CT(rect,b,c); end
    v = 0; for b = 1:9, v = v+Psi{b}.*VT(rect,b,c); end
    g = TL.alpha(1)*U(:,c)-f;
    If(c) = sum(pts.w.*abs(g).^2); Iu(c) = sum(pts.w.*abs(U(:,c)-v).^2);
    for b = 1:4
      d(:,b,c) = complex(accumarray(rect,pts.w.*real(g).*Phi{b},[N^2,1]),accumarray(rect,pts.w.*imag(g).*Phi{b},[N^2,1]));
    end
  end
  assert(np>0);
end

function [If,d,Iu] = LOCAL_selftest_brute(TL,CT,VT,e,m)
  % Uniform m^2 subdivision of the reference triangle of element e with the
  % 3-point edge-midpoint rule per subtriangle; P2 map, |det J|, material by
  % the exact polar trilobe side and rectangle by floor at every point.
  [I,J] = ndgrid(0:m-1,0:m-1); I = I(:); J = J(:);
  up = I+J<=m-1; dn = I+J<=m-2;
  V1 = [[I(up),J(up)];[I(dn)+1,J(dn)]]; V2 = [[I(up)+1,J(up)];[I(dn)+1,J(dn)+1]];
  V3 = [[I(up),J(up)+1];[I(dn),J(dn)+1]];
  xi = [(V1(:,1)+V2(:,1))/2;(V2(:,1)+V3(:,1))/2;(V3(:,1)+V1(:,1))/2]/m;
  eta = [(V1(:,2)+V2(:,2))/2;(V2(:,2)+V3(:,2))/2;(V3(:,2)+V1(:,2))/2]/m;
  w = ones(size(xi))/(6*m^2);
  [Nb,Nx,Ny] = LOCAL_p2_basis(xi,eta);
  X = 0; Y = 0; Xx = 0; Xy = 0; Yx = 0; Yy = 0; U = 0;
  for i = 1:6
    X = X+Nb{i}*TL.X6(e,i); Y = Y+Nb{i}*TL.Y6(e,i);
    Xx = Xx+Nx{i}*TL.X6(e,i); Xy = Xy+Ny{i}*TL.X6(e,i); Yx = Yx+Nx{i}*TL.Y6(e,i); Yy = Yy+Ny{i}*TL.Y6(e,i);
    U = U+Nb{i}.*TL.Coef(TL.tri6(e,i),:);
  end
  w = w.*abs(Xx.*Yy-Xy.*Yx);
  cv = TL.curve; ph = atan2(Y-cv.cy,X-cv.cx);
  inside = hypot(X-cv.cx,Y-cv.cy)<cv.R*(1+cv.a*cos(3*ph));
  al = TL.alpha(1+inside)'; N = TL.N;
  [col,row] = LOCAL_rect_of(X,Y,TL.x0,TL.h,N); rect = row+N*col+1;
  Phi = LOCAL_rect_basis(TL,X,Y,col,row,1); Psi = LOCAL_rect_basis(TL,X,Y,col,row,2);
  If = zeros(1,2); Iu = If; d = zeros(N^2,4,2,'like',1i);
  for c = 1:2
    f = 0; for b = 1:4, f = f+Phi{b}.*CT(rect,b,c); end
    v = 0; for b = 1:9, v = v+Psi{b}.*VT(rect,b,c); end
    g = al.*U(:,c)-f;
    If(c) = sum(w.*abs(g).^2); Iu(c) = sum(w.*abs(U(:,c)-v).^2);
    for b = 1:4
      d(:,b,c) = complex(accumarray(rect,w.*real(g).*Phi{b},[N^2,1]),accumarray(rect,w.*imag(g).*Phi{b},[N^2,1]));
    end
  end
end

function err = LOCAL_selftest_fourier()
  N = 16; h = 1/N; M = 8; beta = 0.5; mvec = (-M:M)'; q = beta+2*pi*mvec; kappa = q*h/2;
  J = zeros(numel(q),3);
  for b = 0:2, J(:,b+1) = sqrt(h)*sqrt(2*b+1)*(-1i)^b*LOCAL_sph_bessel(b,kappa); end
  rng(9); Cs = complex(randn(N,1,4,1),randn(N,1,4,1)); Vs = complex(randn(N,1,9,1),randn(N,1,9,1));
  yj = -0.5+((0:N-1)'+0.5)*h;
  [FF,~] = LOCAL_fourier_strip(Cs,Vs,J,exp(-1i*beta*yj),mod(mvec,N)+1,exp(1i*pi*mvec*(1-h)));
  [tg,wg] = LOCAL_gauss01(24); F2 = zeros(numel(q),2);
  for r = 0:N-1
    y = -0.5+(r+tg)*h; sy = 2*tg-1; Py = [ones(size(sy)),sy,(3*sy.^2-1)/2];
    for a = 0:1
      for b = 0:1
        % y factor of the orthonormal basis: sqrt(2b+1)/sqrt(h) P_b (the x
        % factor is the column basis of F_a)
        fy = Cs(r+1,1,1+a+2*b)*sqrt(2*b+1)/sqrt(h)*Py(:,b+1);
        F2(:,a+1) = F2(:,a+1)+(exp(-1i*q*y')*(h*wg.*fy));
      end
    end
  end
  err = max(abs(FF(:,1,:)-reshape(F2,[],1,2)),[],'all')/max(abs(F2),[],'all');
end

function [e28,out_w,out_vw] = LOCAL_selftest_yukawa()
  % One mode, n intervals of random affine sources; D2.8 against the D1
  % Green formula; Taylor/Gauss norm intervals against adaptive quadrature.
  a = 2.3; s = 1.1; q = sqrt(a^2-s); h = 0.05; n = 30; rng(11);
  A = complex(randn(1,n),randn(1,n)); B = randn(1,n)/h;
  F = zeros(1,n,2,'like',1i); F(1,:,2) = B*h^1.5/(2*sqrt(3)); F(1,:,1) = A*sqrt(h)+sqrt(3)*F(1,:,2);
  V = complex(randn(1,n,3),randn(1,n,3))*1e-2;
  Y = LOCAL_yukawa_batch(h,q,s,F,V,zeros(1,n,2),zeros(1,n,3),24);
  z = a*h; E = exp(-z); [g0,g1] = LOCAL_gamma01(z); L = zeros(1,n+1); R = L;
  for i = 1:n, L(i+1) = E*L(i)+(A(i)+B(i)*h)*h*g0-B(i)*h^2*g1; end
  for i = n:-1:1, R(i) = E*R(i+1)+A(i)*h*g0+B(i)*h^2*g1; end
  e28 = 0; nw2 = zeros(1,n); nd2 = nw2;
  for i = 1:n
    zm = (L(i)-A(i)/a+B(i)/a^2)/(2*a); zp = (R(i+1)-(A(i)+B(i)*h)/a-B(i)/a^2)/(2*a);
    wfun = @(t)(A(i)+B(i)*t)/a^2+zm*exp(-a*t)+zp*exp(-a*(h-t));
    t = 0.37*h; [gL0,gL1] = LOCAL_gamma01(a*t); [gR0,gR1] = LOCAL_gamma01(a*(h-t));
    IL = t*((A(i)+B(i)*t)*gL0-B(i)*t*gL1); IR = (h-t)*((A(i)+B(i)*t)*gR0+B(i)*(h-t)*gR1);
    d1 = (exp(-a*t)*L(i)+IL+exp(-a*(h-t))*R(i+1)+IR)/(2*a);
    e28 = max(e28,abs(wfun(t)-d1)/abs(d1));
    vfun = @(t)(V(1,i,1)+sqrt(3)*V(1,i,2)*(2*t/h-1)+sqrt(5)*V(1,i,3)*(3*(2*t/h-1).^2-1)/2)/sqrt(h);
    nw2(i) = integral(@(t)abs(wfun(t)).^2,0,h,'AbsTol',1e-18,'RelTol',1e-13);
    nd2(i) = integral(@(t)abs(vfun(t)-wfun(t)).^2,0,h,'AbsTol',1e-18,'RelTol',1e-13);
  end
  tol = 1e-10;                                         % adaptive-quadrature accuracy
  out_w = nnz(nw2<Y.w2_lo*(1-tol) | nw2>Y.w2_hi*(1+tol));
  out_vw = nnz(nd2<Y.vw2_lo*(1-tol) | nd2>Y.vw2_hi*(1+tol));
end

function r = LOCAL_selftest_status(config)
  % Synthetic level data: valid, denominator and inconsistency branches,
  % and an incomplete enclosure.
  common = struct('k',1.5,'mu',2.25,'s',2.25,'beta',0.5,'C_rho',10,'CG',0.25,'shift_floor',2.5, ...
    'U0',1,'b',1e-8,'resolution_target_k',1e-6);
  lev = struct('name','t','N',64,'M',32);
  Ir = struct('If',[0.01,0.0100001],'Iu',[1e-14,1.1e-14],'per_template',struct([]));
  Mf = struct('delta_c',1e-10,'delta_1',1e-10,'term_c',1e-11,'term_1',1e-11,'term',1e-11);
  NR = struct('Ey2_interval_raw',[1e-4,1.1e-4],'Tv2_interval_raw',[0,1e-16],'Ivw_box',[1e-12,1.1e-12], ...
    'Td2',[1e-14,1e-14],'Iw_box',[1,1],'Ey2_raw',1e-4,'Tv2_raw',1e-17,'ordinary_ER2',0.01, ...
    'ordinary_du2',1e-14,'ordinary',struct('vw2_in_box',1e-12,'Td2',1e-14,'w2_in_box',1, ...
    'check_w2_12',1,'check_vw2_12',1e-12),'modes',[],'cell',[]);
  checks = struct('complete',true,'missing',{{}});
  corr = struct();
  L1 = LOCAL_combine_d2(config,lev,common,Ir,Mf,NR,checks,corr);
  NR2 = NR; NR2.Ey2_interval_raw = [-2e-4,-1e-4]; L2 = LOCAL_combine_d2(config,lev,common,Ir,Mf,NR2,checks,corr);
  NR3 = NR; NR3.Iw_box = [1e-12,1e-12]; NR3.Td2 = [0,0]; L3 = LOCAL_combine_d2(config,lev,common,Ir,Mf,NR3,checks,corr);
  ch2 = checks; ch2.complete = false; ch2.missing = {'synthetic'};
  L4 = LOCAL_combine_d2(config,lev,common,Ir,Mf,NR,ch2,corr);
  r = struct('valid',L1.exact.status,'inconsistent',L2.exact.status,'denominator',L3.exact.status, ...
    'incomplete',L4.exact.status);
  r.pass = strncmp(r.valid,'VALID_BOUND',11) && strcmp(r.inconsistent,'EVALUATION_INCONSISTENCY') && ...
    strcmp(r.denominator,'DENOMINATOR_NOT_POSITIVE') && strcmp(r.incomplete,'INTEGRATION_CONTROL_UNRESOLVED');
end

function native = LOCAL_adapter(config)
  cfg = config.native; k = config.k; mu = k^2; nc = config.field.cells_per_side;
  native = struct('identity','FIXED_FREQUENCY_RECONSTRUCTION','k',k,'mu',mu, ...
    'qualified',false,'templates',struct(),'cells',struct([]),'summary',struct(), ...
    'U0',NaN,'scale',NaN,'phase',NaN,'recovery',struct(),'qz',struct(),'tails',struct(), ...
    'curve_deviation',struct(),'times',struct());
  summary = struct('reason','','geometry_status','','lambda',NaN,'center_residual',NaN);
  timer = tic;
  [mesh,geometry] = LOCAL_mesh(config,cfg);
  native.times.mesh = toc(timer);
  summary.geometry_status = geometry.status; summary.triangles = size(mesh.triangles,1);
  summary.p2_nodes = size(mesh.p2_points,1); summary.det_min = geometry.det_min;
  summary.det_ratio_max = geometry.det_ratio_max; summary.curved_elements = geometry.curved_elements;
  summary.mesh_structural_checks_pass = geometry.mesh_structural_checks_pass;
  if ~strcmp(geometry.status,'PASS')
    summary.reason = ['GEOMETRY: ',geometry.reason]; native.summary = summary; return
  end
  timer = tic;
  templates = LOCAL_templates(config,cfg,mesh);
  native.times.assembly = toc(timer);
  summary.matrix_checks_pass = templates.checks.pass;
  summary.dimensions = templates.dimensions;
  % --- one complete response at the frozen k (raw QZ blocks kept) ---
  timer = tic;
  [res,ext] = LOCAL_evaluate(config,templates,k,true);
  native.times.response = toc(timer);
  summary.response_valid = res.valid;
  summary.reasons = {res.reason_left,res.reason_right,res.reason_center};
  if ~res.valid
    summary.reason = ['RESPONSE: ',strjoin(summary.reasons,' | ')]; native.summary = summary; return
  end
  [~,index] = min(abs(res.lambda));
  summary.branch_index = index; summary.lambda = res.lambda(index);
  summary.target_gap = LOCAL_gap(res.lambda,index); summary.H_norm = res.H_norm;
  [~,near] = sort(abs(res.lambda)); summary.nearest_lambda = res.lambda(near(1:min(5,end)))';
  summary.dtn = struct('left',res.dtn.left,'right',res.dtn.right);
  summary.cell = res.cell;
  % --- recovery: centre, then 16 lead cells per side (I9.5b LOCAL_recover) ---
  timer = tic;
  n = templates.n; beta = templates.beta; dl = config.delivery;
  y = res.V(:,index); g = templates.wall_chol\y;
  c = templates.center; Ec = ext.center.E;
  u = complex(zeros(numel(c.free),1)); u(c.wall) = g; u(c.interior) = Ec*g;
  Ac = c.K-mu*c.M; Ku = c.K*u; Mu = c.M*u; gl = g(1:n); gr = g(n+1:end);
  DL = ext.left.D; DR = ext.right.D;
  r = Ku-mu*Mu; r(c.wall) = r(c.wall)+[DL*gl;DR*gr];
  denominator = norm(Ku)+abs(mu)*norm(Mu)+norm(DL*gl)+norm(DR*gr);
  summary.center_residual = norm(r)/denominator;
  summary.center_recovery_residual = norm(Ac(c.interior,:)*u)/(norm(Ac(c.interior,c.interior)* ...
    u(c.interior))+norm(Ac(c.interior,c.wall)*g));
  full_c = c.Qqp*u;
  summary.center_qp = norm(full_c(c.top)-exp(1i*beta)*full_c(c.bottom))/norm(full_c);
  center_load = Ac(c.wall,:)*u;
  cells = struct('index',0,'template','center','offset',0,'coef',full_c);
  sides = struct([]); traces_all = struct();
  for side = {'left','right'}
    name = side{1}; t = templates.(name); Lx = ext.(name);
    if strcmp(name,'left'), g0 = gl; wall_load = center_load(1:n); sgn = -1;
    else, g0 = gr; wall_load = center_load(n+1:end); sgn = 1; end
    At = t.K-mu*t.M; S00 = Lx.S(1:n,1:n); S01 = Lx.S(1:n,n+1:end);
    S10 = Lx.S(n+1:end,1:n); S11 = Lx.S(n+1:end,n+1:end);
    traces = complex(zeros(n,nc+1)); traces(:,1) = g0;
    for j = 1:nc, traces(:,j+1) = Lx.Pout*traces(:,j); end
    recovery = zeros(1,nc); balance = zeros(1,nc); continuity = zeros(1,nc); qp = zeros(1,nc);
    fields = cell(1,nc);
    x1 = t.xy(:,1); wall0 = sgn*0.5; wall1 = wall0+sgn;
    p = find(abs(x1-wall1)<1e-11); q = find(abs(x1-wall0)<1e-11);
    [~,ap] = sort(t.xy(p,2)); [~,aq] = sort(t.xy(q,2));
    cw_nodes = find(abs(c.xy(:,1)-wall0)<1e-11); [~,acw] = sort(c.xy(cw_nodes,2));
    for j = 1:nc
      v = complex(zeros(numel(t.free),1)); v(t.wall) = [traces(:,j);traces(:,j+1)];
      v(t.interior) = Lx.E*[traces(:,j);traces(:,j+1)];
      recovery(j) = norm(At(t.interior,:)*v)/(norm(At(t.interior,t.interior)*v(t.interior))+ ...
        norm(At(t.interior,t.wall)*v(t.wall)));
      fields{j} = t.Qqp*v;
      qp(j) = norm(fields{j}(t.top)-exp(1i*beta)*fields{j}(t.bottom))/max(norm(fields{j}),realmin);
      if j==1
        lead_load = S00*traces(:,1)+S01*traces(:,2);
        balance(j) = norm(wall_load+lead_load)/(norm(wall_load)+norm(lead_load));
        continuity(j) = norm(full_c(cw_nodes(acw))-fields{1}(q(aq)))/max(norm(full_c(cw_nodes(acw))),realmin);
      else
        prev = S10*traces(:,j-1)+S11*traces(:,j); next = S00*traces(:,j)+S01*traces(:,j+1);
        balance(j) = norm(prev+next)/(norm(prev)+norm(next));
        continuity(j) = norm(fields{j-1}(p(ap))-fields{j}(q(aq)))/max(norm(fields{j-1}(p(ap))),realmin);
      end
      cells(end+1) = struct('index',sgn*j,'template',name,'offset',sgn*(j-1), ...
        'coef',fields{j}); %#ok<AGROW>
    end
    sides = LOCAL_append(sides,struct('side',name,'recovery_residual',recovery, ...
      'load_balance',balance,'value_continuity',continuity,'qp_defect',qp, ...
      'spectral_radius',max(abs(Lx.multipliers)),'unit_gap_min',res.dtn.(name).unit_gap_min, ...
      'stable_count',res.dtn.(name).stable_count,'z0_rcond',res.dtn.(name).z0_rcond, ...
      'riccati',res.dtn.(name).riccati,'invariance',res.dtn.(name).invariance, ...
      'dtn_hermitian_defect',res.dtn.(name).hermitian_defect));
    traces_all.(name) = traces;
  end
  summary.sides = sides;
  % --- unweighted L2 normalisation over the (2N+1)-cell box and phase ---
  names = {'left','center','right'}; M1 = struct(); inclusion = struct();
  for j = 1:3
    t = templates.(names{j});
    [~,M1.(names{j})] = LOCAL_assemble(t.xy,t.tri6,ones(size(t.tri6,1),1),templates.quadrature_order);
  end
  mass = zeros(1,numel(cells));
  for j = 1:numel(cells)
    mass(j) = real(cells(j).coef'*M1.(cells(j).template)*cells(j).coef);
  end
  scale = 1/sqrt(sum(mass));
  [~,at] = max(abs(full_c)); phase = conj(full_c(at))/abs(full_c(at));
  for j = 1:numel(cells), cells(j).coef = cells(j).coef*scale*phase; end
  mass = mass*scale^2;
  native.scale = scale; native.phase = phase; native.cells = cells;
  % U0 (theory 11.2): every cell mass is coef'*M1*coef, M1 integrated by the
  % 12x12 Duffy rule, exact for the degree-6 integrand |u_K|^2 J_K; hence the
  % total I0 is exact in exact arithmetic (I0- = I0+, rounding not certified)
  % and U0 = sqrt(I0) is the reliable positive lower bound; no safety factor.
  native.U0 = sqrt(sum(mass));
  summary.cell_index = [cells.index]; summary.cell_mass = mass;
  % --- qualification (I9.5b root/delivery gates, all 16 cells per side) ---
  gates = struct('dtn_valid',res.valid, ...
    'stable_count_complete',sides(1).stable_count==n && sides(2).stable_count==n, ...
    'eig_abs',abs(summary.lambda)<=config.root.eig_abs, ...
    'isolated_gap',summary.target_gap>=config.root.gap_factor*max(1,res.H_norm), ...
    'center_residual',summary.center_residual<=config.root.center_residual, ...
    'center_recovery',summary.center_recovery_residual<=dl.recovery_residual, ...
    'center_qp',summary.center_qp<=dl.qp, ...
    'wall_order',templates.checks.left.wall_pairing && templates.checks.center.wall_pairing && ...
      templates.checks.right.wall_pairing, ...
    'matrix_checks',templates.checks.pass);
  for j = 1:2
    s = sides(j);
    gates.([s.side,'_recovery']) = max(s.recovery_residual)<=dl.recovery_residual;
    gates.([s.side,'_continuity']) = max(s.value_continuity)<=dl.continuity;
    gates.([s.side,'_qp']) = max(s.qp_defect)<=dl.qp;
    gates.([s.side,'_balance']) = max(s.load_balance)<=dl.load_balance;
  end
  ref = config.native_reference;
  summary.identity_diagnostics = struct('lambda_reference',ref.lambda, ...
    'lambda_difference',summary.lambda-ref.lambda, ...
    'dims_match_reference',isequal(templates.dimensions.free_dofs,ref.free_dofs) && ...
      templates.n==ref.wall_dofs && summary.triangles==ref.triangles && summary.p2_nodes==ref.p2_nodes);
  summary.gates = gates;
  values = struct2cell(gates); native.qualified = all([values{:}]);
  if ~native.qualified
    f = fieldnames(gates); summary.reason = ['QUALIFICATION: ',strjoin(f(~[values{:}])',',')];
  end
  % --- tails: P^j g norms, cell masses, eq. (27) with Euclidean 2-norms ---
  for j = 1:2
    name = sides(j).side; t = templates.(name); Lx = ext.(name);
    traces = traces_all.(name)*scale*phase;
    nI = numel(t.interior); Bc = complex(zeros(numel(t.free),2*n));
    Bc(t.wall,:) = eye(2*n); Bc(t.interior,:) = Lx.E;
    Bfull = t.Qqp*Bc; Gcell = Bfull'*(M1.(name)*Bfull); Gcell = (Gcell+Gcell')/2;
    Pn = Lx.Pout; Gs = [eye(n);Pn]'*Gcell*[eye(n);Pn]; Gs = (Gs+Gs')/2;
    power = eye(n); norms_r = zeros(1,config.field.tail_power_max+1); gamma = NaN; np = NaN;
    for r = 0:config.field.tail_power_max
      norms_r(r+1) = norm(power);
      if r>0 && norms_r(r+1)<1, gamma = norms_r(r+1); np = r; break, end
      power = Pn*power;
    end
    tail27 = NaN;
    if ~isnan(gamma)
      tail27 = norm(Gs)*sum(norms_r(1:np).^2)/(1-gamma^2)*norm(traces(:,nc+1))^2;
    end
    side_mass = mass([cells.index]==0 | sign([cells.index])==2*j-3);
    idx = abs([cells.index]); sel = sign([cells.index])==2*j-3;
    [~,order] = sort(idx(sel)); lead_mass = mass(sel); lead_mass = lead_mass(order);
    native.tails.(name) = struct('trace_norms',vecnorm(traces),'cell_mass',lead_mass, ...
      'last_two_mass',sum(lead_mass(end-1:end)),'power_norms',norms_r(1:max(1,min(end,np+1))), ...
      'gamma',gamma,'n_power',np,'G_norm',norm(Gs),'eq27_bound',tail27, ...
      'spectral_radius',max(abs(Lx.multipliers)),'side_mass_with_center',sum(side_mass));
  end
  summary.tails = native.tails;
  % --- templates for integration (geometry, material, interface edges) ---
  nv = size(mesh.points,1); exact = LOCAL_exact_areas(config);
  for j = 1:3
    name = names{j}; t = templates.(name); cc = j-2;
    kk = find(mesh.interface_cell==cc); gid = nv+mesh.interface_edges(kk);
    [ok,loc] = ismember(gid,t.nodes);
    assert(all(ok),'i96:Interface','Interface midpoint missing in template %s.',name);
    nt = size(t.tri6,1); nn = size(t.xy,1);
    Inc = sparse(t.tri6(:,4:6),repmat((1:nt)',1,3),repmat(1:3,nt,1),nn,nt);
    inner = zeros(numel(loc),1); outer = inner; qin = inner; qout = inner;
    for e = 1:numel(loc)
      [~,els,qq] = find(Inc(loc(e),:));
      assert(numel(els)==2,'i96:Interface','Interface edge without two owners.');
      if t.material(els(1))~=config.model.rho_background, a = 1; b = 2; else, a = 2; b = 1; end
      inner(e) = els(a); outer(e) = els(b); qin(e) = qq(a); qout(e) = qq(b);
    end
    interface = struct('mid',loc,'theta',mesh.interface_theta(kk), ...
      'dtheta',2*pi/cfg.interface_segments,'inner',inner,'outer',outer,'q_inner',qin,'q_outer',qout);
    native.templates.(name) = struct('name',name,'cell',cc,'xy',t.xy,'tri6',t.tri6, ...
      'material',t.material,'M1',M1.(name),'Qqp',t.Qqp,'K',t.K,'M',t.M,'free',t.free, ...
      'wall',t.wall,'interior',t.interior,'top',t.top,'bottom',t.bottom, ...
      'inclusion_area',t.inclusion_area,'exact_area',exact(j),'interface',interface, ...
      'rho_in',max(t.material));
  end
  % --- 33-point curve deviation of every interface segment (diagnostic) ---
  native.curve_deviation = LOCAL_curve_deviation(config,mesh,cfg);
  summary.curve_deviation = rmfield(native.curve_deviation,'per_segment');
  % --- raw recovery data and QZ blocks for read-only audit ---
  native.recovery = struct('g',g*scale*phase,'traces_left',traces_all.left*scale*phase, ...
    'traces_right',traces_all.right*scale*phase,'E_center',Ec,'E_left',ext.left.E, ...
    'E_right',ext.right.E,'S_left',ext.left.S,'S_right',ext.right.S,'S_center',ext.center.S, ...
    'D_left',ext.left.D,'D_right',ext.right.D,'Pout_left',ext.left.Pout, ...
    'Pout_right',ext.right.Pout,'H',ext.center.H,'lambda_all',res.lambda,'y',y, ...
    'wall_mass',templates.wall_mass);
  native.qz = struct('left',ext.left.qz,'right',ext.right.qz);
  native.times.recovery = toc(timer);
  summary.scale = scale; summary.phase = phase; summary.U0 = native.U0;
  summary.times = native.times;
  native.summary = summary;
end

function native = LOCAL_explicit_native(config,native)
  % Explicit numeric input of the adapter schema; loading/validation is the
  % caller's, this only checks the fields and records the identity.
  required = {'k','templates','cells','U0','qualified','summary'};
  for f = required
    assert(isfield(native,f{1}),'i96:Native','Explicit native input lacks field %s.',f{1});
  end
  native.identity = 'EXPLICIT_SAVED_FIELD';
  if native.k~=config.k
    native.qualified = false; native.summary.reason = 'EXPLICIT_K_DIFFERS_FROM_CONFIG';
  end
end

function dev = LOCAL_curve_deviation(config,mesh,cfg)
  % p(t) (P2 interface edge, theta increasing) against c(theta_k+t*dtheta)
  % at curve_samples points; the parameter-matched distance bounds the
  % geometric deviation. Diagnostic only, not a material classification.
  ns = config.delivery.curve_samples; ng = cfg.interface_segments; t = linspace(0,1,ns)';
  nv = size(mesh.points,1); per = zeros(numel(mesh.interface_edges),1); endpoint = per;
  for e = 1:numel(mesh.interface_edges)
    c = mesh.interface_cell(e); th = mesh.interface_theta(e);
    A = LOCAL_curve(config,c,th); B = LOCAL_curve(config,c,th+2*pi/ng);
    Mid = mesh.p2_points(nv+mesh.interface_edges(e),:);
    ends = mesh.points(mesh.edges(mesh.interface_edges(e),:),:);
    endpoint(e) = min(norm(ends(1,:)-A)+norm(ends(2,:)-B),norm(ends(1,:)-B)+norm(ends(2,:)-A));
    p = A.*(1-t).*(1-2*t)+Mid.*4.*t.*(1-t)+B.*t.*(2*t-1);
    per(e) = max(vecnorm(p-LOCAL_curve(config,c,th+t*2*pi/ng),2,2));
  end
  dev = struct('samples',ns,'max',max(per),'mean',mean(per), ...
    'max_by_cell',[max(per(mesh.interface_cell==-1)),max(per(mesh.interface_cell==0)), ...
    max(per(mesh.interface_cell==1))],'endpoint_mismatch_max',max(endpoint),'per_segment',per);
end

function LOCAL_save_native(output_dir,native)
  % native.mat: templates, cells (normalised full P2 coefficients), E, P, S,
  % D, wall values, QZ blocks, curve deviations (read-only audit input).
  save(fullfile(output_dir,'native.mat'),'native','-v7');
end

function [QX,QY,qn] = LOCAL_clip(PX,PY,pn,dim,value,sgn)
  % Sutherland-Hodgman clip of NaN-padded convex polygons (rows) to the
  % half-plane sgn*(coordinate - value) >= 0; value is one number per row.
  np = size(PX,1); width = size(PX,2); QX = nan(np,width+2); QY = QX; qn = zeros(np,1);
  if np==0, QX = QX(:,1:width); QY = QY(:,1:width); return, end
  value = value(:).*ones(np,1);
  if dim==1, C = PX; else, C = PY; end
  D = sgn*(C-value); rows = (1:np)';
  for i = 1:max(pn)
    act = pn>=i; nxt = (i+1)*ones(np,1); nxt(pn==i) = 1; nxt = min(nxt,width);
    ci = rows+np*(i-1); cj = rows+np*(nxt-1);
    xi = PX(ci); yi = PY(ci); di = D(ci); xj = PX(cj); yj = PY(cj); dj = D(cj);
    k = find(act & di>=0);
    qn(k) = qn(k)+1; idx = k+np*(qn(k)-1); QX(idx) = xi(k); QY(idx) = yi(k);
    k = find(act & ((di>=0)~=(dj>=0)));
    tt = di(k)./(di(k)-dj(k));
    nx = xi(k)+tt.*(xj(k)-xi(k)); ny = yi(k)+tt.*(yj(k)-yi(k));
    if dim==1, nx = value(k); else, ny = value(k); end
    qn(k) = qn(k)+1; idx = k+np*(qn(k)-1); QX(idx) = nx; QY(idx) = ny;
  end
  used = max([qn;3]); QX = QX(:,1:max(used,width)); QY = QY(:,1:max(used,width));
end

function area = LOCAL_poly_area(PX,PY,pn)
  np = size(PX,1); area = zeros(np,1); rows = (1:np)';
  for i = 1:max([pn;0])
    act = pn>=i; nxt = (i+1)*ones(np,1); nxt(pn==i) = 1; nxt = min(nxt,size(PX,2));
    ci = rows+np*(i-1); cj = rows+np*(nxt-1);
    term = PX(ci).*PY(cj)-PX(cj).*PY(ci); area(act) = area(act)+term(act);
  end
  area = area/2;
end

function [xi,eta,residual] = LOCAL_reference_coordinates(config,geo,pts)
  % Affine inverse for straight elements; Newton on the P2 map for curved ones
  % (points of the chord/arc and true slivers may lie just outside T-hat).
  e = pts.elem; dx = pts.x-geo.P1(e,1); dy = pts.y-geo.P1(e,2);
  xi = geo.inv(e,1).*dx+geo.inv(e,2).*dy; eta = geo.inv(e,3).*dx+geo.inv(e,4).*dy;
  residual = 0;
  c = find(geo.curved(e));
  if isempty(c), return, end
  X6 = geo.X6(e(c),:); Y6 = geo.Y6(e(c),:); a = xi(c); b = eta(c);
  for it = 1:config.integration.newton_iterations
    [N,Nx,Ny] = LOCAL_p2_basis(a,b);
    Fx = -pts.x(c); Fy = -pts.y(c); Jxx = 0; Jxy = 0; Jyx = 0; Jyy = 0;
    for i = 1:6
      Fx = Fx+N{i}.*X6(:,i); Fy = Fy+N{i}.*Y6(:,i);
      Jxx = Jxx+Nx{i}.*X6(:,i); Jxy = Jxy+Ny{i}.*X6(:,i);
      Jyx = Jyx+Nx{i}.*Y6(:,i); Jyy = Jyy+Ny{i}.*Y6(:,i);
    end
    dd = Jxx.*Jyy-Jxy.*Jyx;
    a = a-(Jyy.*Fx-Jxy.*Fy)./dd; b = b-(-Jyx.*Fx+Jxx.*Fy)./dd;
    residual = max(hypot(Fx,Fy));
    if residual<=config.integration.newton_tolerance, break, end
  end
  [N,~,~] = LOCAL_p2_basis(a,b); Fx = -pts.x(c); Fy = -pts.y(c);
  for i = 1:6, Fx = Fx+N{i}.*X6(:,i); Fy = Fy+N{i}.*Y6(:,i); end
  residual = max(hypot(Fx,Fy));
  xi(c) = a; eta(c) = b;
end

%% ==================== Ordinary integration: projections and Fourier moments ====================

function [X,Y,U,D] = LOCAL_eval_p2(X6,Y6,U6,xi,eta)
  % P2 map, field and Jacobian determinant at reference points (rows = elements).
  [N,Nx,Ny] = LOCAL_p2_basis(xi,eta);
  X = 0; Y = 0; U = 0; Xx = 0; Xy = 0; Yx = 0; Yy = 0;
  for i = 1:6
    X = X+N{i}.*X6(:,i); Y = Y+N{i}.*Y6(:,i); U = U+N{i}.*U6(:,i);
    Xx = Xx+Nx{i}.*X6(:,i); Xy = Xy+Ny{i}.*X6(:,i);
    Yx = Yx+Nx{i}.*Y6(:,i); Yy = Yy+Ny{i}.*Y6(:,i);
  end
  D = Xx.*Yy-Xy.*Yx;
end

function [N,Nx,Ny] = LOCAL_p2_basis(xi,eta)
  % P2 Lagrange basis (vertices 1-3, midpoints 4: 1-2, 5: 2-3, 6: 3-1) and
  % reference derivatives, element-wise on arrays.
  l1 = 1-xi-eta; l2 = xi; l3 = eta;
  N = {l1.*(2*l1-1),l2.*(2*l2-1),l3.*(2*l3-1),4*l1.*l2,4*l2.*l3,4*l3.*l1};
  z = zeros(size(xi));
  Nx = {-(4*l1-1),4*l2-1,z,4*(l1-l2),4*l3,-4*l3};
  Ny = {-(4*l1-1),z,4*l3-1,-4*l2,4*l2,4*(l1-l3)};
end

%% ==================== Ordinary integration: geometry decomposition ====================

function [col,row] = LOCAL_rect_of(x,y,x0,h,N)
  col = min(max(floor((x-x0)/h),0),N-1); row = min(max(floor((y+0.5)/h),0),N-1);
end

function brk = LOCAL_quadratic_breaks(c0,c1,c2,x0,h)
  % Parameters t in (0,1) where c0+c1 t+c2 t^2 crosses grid lines x0+k h
  % (first component) or -1/2+k h (second); returns [0; sorted roots; 1].
  brk = [0;1];
  origin = [x0,-0.5];
  for d = 1:2
    tt = linspace(0,1,9)'; vals = c0(d)+c1(d)*tt+c2(d)*tt.^2;
    lo = ceil((min(vals)-origin(d))/h-1); hi = floor((max(vals)-origin(d))/h+1);
    for kk = lo:hi
      g = origin(d)+kk*h; a = c2(d); b = c1(d); c = c0(d)-g;
      if abs(a)<=1e-14*(abs(b)+abs(c))
        if b~=0, r = -c/b; else, r = []; end
      else
        disc = b^2-4*a*c;
        if disc<0, r = []; else
          sq = sqrt(disc); qv = -0.5*(b+sign(b+(b==0))*sq);
          r = [qv/a;c/qv]; r = r(isfinite(r));
        end
      end
      brk = [brk;r(r>0 & r<1)]; %#ok<AGROW>
    end
  end
  brk = unique(brk);
end

function [x,w] = LOCAL_gauss01(n)
  j = (1:n-1)'; b = j./sqrt(4*j.^2-1); [Vv,D] = eig(diag(b,1)+diag(b,-1));
  [x,idx] = sort(diag(D)); w = Vv(1,idx)'.^2; x = (x+1)/2;
end

function dc = LOCAL_curve_derivative(config,cell_index,theta)
  theta = theta(:);
  if cell_index==0
    sc = config.model.star_scale*0.2; c5 = cos(5*theta); s5 = sin(5*theta);
    dc = sc*[-1.5*s5.*cos(theta)-(1.5+0.3*c5).*sin(theta),-1.5*s5.*sin(theta)+(1+0.3*c5).*cos(theta)];
  else
    a = config.model.a_negative; if cell_index>0, a = config.model.a_positive; end
    R = config.model.radius/sqrt(1+a^2/2);
    r = R*(1+a*cos(3*theta)); dr = -3*a*R*sin(3*theta);
    dc = [dr.*cos(theta)-r.*sin(theta),dr.*sin(theta)+r.*cos(theta)];
  end
end

function rk = LOCAL_rk(k,mu,R)
  % Largest distance from k to sqrt of the interval [max(0,mu-R), mu+R].
  rk = max(k-sqrt(max(0,mu-R)),sqrt(mu+R)-k);
end

%% ==================== Copied I9.5b helpers (test/i9/fem-dtn-v1/fem_dtn_i95b.m) ====================
% Verbatim copies except: LOCAL_dtn/LOCAL_evaluate also return the raw ordered
% QZ blocks; LOCAL_memory_gate raises i96:ResourceStop.
function list = LOCAL_append(list,item)
  if isempty(list), list = item; else, list(end+1) = item; end
end

%% ==================== Geometry, joint mesh and deterministic repair ====================
% One three-cell mesh on (-3/2,3/2)x(-1/2,1/2); walls/top/bottom/curves/rings fixed.
function xy = LOCAL_curve(config,cell_index,theta)
  theta = theta(:);
  if cell_index == 0
    xy = config.model.star_scale*0.2*[(1.5+0.3*cos(5*theta)).*cos(theta), ...
      (1+0.3*cos(5*theta)).*sin(theta)];
  else
    a = config.model.a_negative;
    if cell_index>0, a = config.model.a_positive; end
    radius = config.model.radius*(1+a*cos(3*theta))/sqrt(1+a^2/2);
    xy = [radius.*cos(theta),radius.*sin(theta)];
  end
  xy(:,1) = xy(:,1)+cell_index*config.model.L;
end

function [mesh,geometry] = LOCAL_mesh(config,cfg)
  % Design 5 steps 1-5: clearance deletion, constrained Delaunay with fixed
  % curve/ring/wall nodes, up to 3 deletion rounds, then (D2) bounded local
  % edge flips of interface-adjacent bad elements and the final full-mesh gates.
  % geometry.failure_kind is NONE, JACOBIAN_QUALITY_UNRESOLVED,
  % LOCAL_REPAIR_LIMIT or STRUCTURAL_CHECK_FAILED; mesh_structural_checks_pass
  % reports the completed constraint/material/incidence/pairing/coverage checks.
  rules = config.mesh_rules; s = cfg.subdivisions; ng = cfg.interface_segments; h = 1/s;
  tol = rules.coordinate_tolerance;
  [ix,iy] = ndgrid(0:3*s,0:s);
  grid = [-1.5+ix(:)*h,-0.5+iy(:)*h];
  fixed = mod(ix(:),s)==0 | iy(:)==0 | iy(:)==s;      % walls, top, bottom
  theta = 2*pi*(0:ng-1)'/ng;
  curves = cell(3,1); rings = cell(3,2); clearance = false(size(grid,1),1);
  for c = -1:1
    curve = LOCAL_curve(config,c,theta); curves{c+2} = curve;
    relative = curve-[c,0];
    rings{c+2,1} = [c,0]+(1-rules.ring_scale)*relative;
    rings{c+2,2} = [c,0]+(1+rules.ring_scale)*relative;
    clearance = clearance | LOCAL_polyline_distance(grid,curve) < rules.interface_clearance_fraction*h;
    for r = 1:2
      clearance = clearance | LOCAL_polyline_distance(grid,rings{c+2,r}) < rules.ring_clearance_fraction*h;
    end
  end
  background = grid(~clearance | fixed,:);
  deletable = ~fixed(~clearance | fixed);
  rounds = struct('round',{},'deleted',{},'deleted_points',{},'bad_elements',{}, ...
    'worst_ratio',{},'worst_det_min',{},'seconds',{});
  geometry = struct('status','PASS','reason','','failure_kind','NONE', ...
    'mesh_structural_checks_pass',false,'structural_checks_completed',false, ...
    'initial_clearance_deleted',nnz(clearance & ~fixed),'deletion_outcome','', ...
    'flip_stage_entered',false,'flip',struct(),'repair_seconds',0, ...
    'repair_seconds_limit',rules.repair_seconds);
  repair_timer = [];                                  % starts at the first bad element
  for round = 0:rules.repair_rounds
    timer = tic;
    [mesh,checks,base] = LOCAL_triangulate(config,cfg,background,deletable,curves,rings,theta);
    bad = LOCAL_bad(checks,rules);
    [worst_ratio,worst] = max(checks.det_ratio);
    record = struct('round',round,'deleted',0,'deleted_points',zeros(0,2), ...
      'bad_elements',numel(bad),'worst_ratio',worst_ratio,'worst_det_min',checks.det_min(worst), ...
      'seconds',0);
    if isempty(bad)
      geometry.deletion_outcome = sprintf('no bad elements after %d deletion rounds',round);
      record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
      break
    end
    if isempty(repair_timer), repair_timer = timer; end
    if round == rules.repair_rounds
      geometry.deletion_outcome = sprintf('%d bad elements after %d deletion rounds',numel(bad),round);
      record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
      break
    end
    % delete all deletable free background vertices of the bad elements
    vertices = unique(mesh.triangles(bad,:));
    remove = vertices(vertices<=size(background,1));
    remove = remove(deletable(remove));
    if isempty(remove)
      geometry.deletion_outcome = sprintf('%d bad elements without deletable background vertices', ...
        numel(bad));
      record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
      break
    end
    record.deleted = numel(remove); record.deleted_points = background(remove,:);
    keep = true(size(background,1),1); keep(remove) = false;
    background = background(keep,:); deletable = deletable(keep);
    record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
  end
  geometry.repair_rounds = rounds;
  % --- D2 step 4: bounded local edge flips when deletion left bad elements ---
  if ~isempty(bad)
    geometry.flip_stage_entered = true;
    [mesh,checks,geometry.flip] = LOCAL_flip_repair(config,cfg,base,mesh,checks,repair_timer);
    bad = LOCAL_bad(checks,rules);
  end
  if ~isempty(repair_timer), geometry.repair_seconds = toc(repair_timer); end
  % --- step 5: final full-mesh gates on the last rebuilt mesh ---
  geometry.structural_checks_completed = true;
  geometry.mesh_structural_checks_pass = checks.pass;
  geometry.bad_elements = numel(bad);
  geometry.checks = rmfield(checks,{'det_min','det_max','det_ratio','quality','min_angle'});
  geometry.det_min = min(checks.det_min); geometry.det_ratio_max = max(checks.det_ratio);
  geometry.curved_elements = nnz(checks.det_ratio>1+1e-12);
  q = sort(checks.quality); a = sort(checks.min_angle);
  pick = @(v,p)v(max(1,ceil(p*numel(v))));
  geometry.shape_quality = struct('min',q(1),'p01',pick(q,0.01),'p05',pick(q,0.05), ...
    'median',pick(q,0.5),'histogram_edges',0:0.1:1,'histogram',histcounts(q,0:0.1:1));
  geometry.min_angle_degrees = struct('min',a(1),'p01',pick(a,0.01),'p05',pick(a,0.05), ...
    'median',pick(a,0.5));
  if ~checks.pass
    geometry.status = 'GEOMETRY_FAILED'; geometry.failure_kind = 'STRUCTURAL_CHECK_FAILED';
    geometry.reason = ['structural checks: ',checks.reason];
  elseif ~isempty(bad) || geometry.repair_seconds>rules.repair_seconds
    geometry.status = 'GEOMETRY_FAILED';
    flip_limit = geometry.flip_stage_entered && geometry.flip.limit_hit;
    if flip_limit || geometry.repair_seconds>rules.repair_seconds
      geometry.failure_kind = 'LOCAL_REPAIR_LIMIT';
    else
      geometry.failure_kind = 'JACOBIAN_QUALITY_UNRESOLVED';
    end
    geometry.reason = sprintf('%d bad elements; deletion: %s',numel(bad),geometry.deletion_outcome);
    if geometry.flip_stage_entered
      geometry.reason = sprintf('%s; flip: %s',geometry.reason,geometry.flip.outcome);
    end
    if geometry.repair_seconds>rules.repair_seconds
      geometry.reason = sprintf('%s; repair %.2fs > %.0fs',geometry.reason, ...
        geometry.repair_seconds,rules.repair_seconds);
    end
  end
  mesh.det_min = checks.det_min; mesh.det_ratio = checks.det_ratio;
  mesh.quality = checks.quality; mesh.min_angle = checks.min_angle;
  mesh.subdivisions = s; mesh.interface_segments = ng; mesh.h = h;
  mesh.curves = curves; mesh.rings = rings;
  assert(all(abs(mesh.points(:))<2) && tol>0,'i96:Mesh','Mesh points escaped the three-cell box.');
end

function bad = LOCAL_bad(checks,rules)
  bad = find(checks.det_min<=0 | checks.det_ratio>rules.det_ratio_max);
end

function distance = LOCAL_polyline_distance(points,poly)
  a = poly; b = poly([2:end,1],:); distance = inf(size(points,1),1);
  block = 256;
  for j = 1:block:size(a,1)
    J = j:min(j+block-1,size(a,1));
    ax = a(J,1)'; ay = a(J,2)'; dx = b(J,1)'-ax; dy = b(J,2)'-ay;
    t = ((points(:,1)-ax).*dx+(points(:,2)-ay).*dy)./(dx.^2+dy.^2);
    t = min(max(t,0),1);
    d = hypot(points(:,1)-ax-t.*dx,points(:,2)-ay-t.*dy);
    distance = min(distance,min(d,[],2));
  end
end

function [mesh,checks,base] = LOCAL_triangulate(config,cfg,background,deletable,curves,rings,theta)
  % Constrained Delaunay of background + analytic curve/ring nodes, centroid
  % material/cell labels, then the shared P2/check build (LOCAL_mesh_build).
  tol = config.mesh_rules.coordinate_tolerance; ng = cfg.interface_segments;
  points = background; constraints = []; raw_interfaces = []; midpoint_values = [];
  for c = -1:1
    ids = size(points,1)+(1:ng)';
    points = [points;curves{c+2}]; %#ok<AGROW>
    edge = [ids,ids([2:end,1])]; constraints = [constraints;edge]; %#ok<AGROW>
    raw_interfaces = [raw_interfaces;edge]; %#ok<AGROW>
    midpoint_values = [midpoint_values;LOCAL_curve(config,c,theta+pi/ng)]; %#ok<AGROW>
    points = [points;rings{c+2,1};rings{c+2,2}]; %#ok<AGROW>
  end
  [~,first,map] = unique(round(points/tol),'rows','stable');
  assert(numel(first)==size(points,1),'i96:Duplicate','Mesh input contains duplicate points.');
  points = points(first,:); constraints = map(constraints); raw_interfaces = map(raw_interfaces);
  for x = -1.5:1:1.5
    ids = find(abs(points(:,1)-x)<tol);
    [~,order] = sort(points(ids,2)); ids = ids(order);
    constraints = [constraints;[ids(1:end-1),ids(2:end)]]; %#ok<AGROW>
  end
  for y = [-0.5,0.5]
    ids = find(abs(points(:,2)-y)<tol);
    [~,order] = sort(points(ids,1)); ids = ids(order);
    constraints = [constraints;[ids(1:end-1),ids(2:end)]]; %#ok<AGROW>
  end
  constraints = unique(sort(constraints,2),'rows');
  dt = delaunayTriangulation(points,constraints);
  assert(size(dt.Points,1)==size(points,1),'i96:Steiner','Triangulation inserted points.');
  points = dt.Points; triangles = dt.ConnectivityList;
  a = points(triangles(:,2),:)-points(triangles(:,1),:);
  b = points(triangles(:,3),:)-points(triangles(:,1),:);
  orientation = a(:,1).*b(:,2)-a(:,2).*b(:,1);
  triangles(orientation<0,[2,3]) = triangles(orientation<0,[3,2]);
  nt = size(triangles,1);
  centroids = (points(triangles(:,1),:)+points(triangles(:,2),:)+points(triangles(:,3),:))/3;
  cell_id = floor(centroids(:,1)+0.5); material = ones(nt,1)*config.model.rho_background;
  for c = -1:1
    curve = curves{c+2}; inside = inpolygon(centroids(:,1),centroids(:,2),curve(:,1),curve(:,2));
    rho = config.model.rho_center;
    if c<0, rho = config.model.rho_negative; elseif c>0, rho = config.model.rho_positive; end
    material(inside) = rho;
  end
  on_boundary = any(abs(points(:,1)-(-1.5:1:1.5))<tol,2) | abs(abs(points(:,2))-0.5)<tol;
  base = struct('points',points,'constraints',constraints,'raw_interfaces',raw_interfaces, ...
    'midpoint_values',midpoint_values,'theta',theta,'on_boundary',on_boundary, ...
    'background_points',size(background,1),'deletable_points',nnz(deletable));
  [mesh,checks] = LOCAL_mesh_build(config,cfg,base,triangles,material,cell_id);
end

function [mesh,checks] = LOCAL_mesh_build(config,cfg,base,triangles,material,cell_id)
  % Rebuild edges and shared P2 numbering from a connectivity (no Delaunay):
  % interface-edge midpoints take the analytic curve values, all other edges
  % the arithmetic midpoint; then structural checks and curved det extrema.
  tol = config.mesh_rules.coordinate_tolerance; points = base.points;
  constraints = base.constraints; raw_interfaces = base.raw_interfaces;
  nt = size(triangles,1); nv = size(points,1);
  a = points(triangles(:,2),:)-points(triangles(:,1),:);
  b = points(triangles(:,3),:)-points(triangles(:,1),:);
  orientation = a(:,1).*b(:,2)-a(:,2).*b(:,1);
  [edges,~,edge_ids] = unique(sort([triangles(:,[1,2]);triangles(:,[2,3]);triangles(:,[3,1])],2),'rows');
  [found,interface_edges] = ismember(sort(raw_interfaces,2),edges,'rows');
  checks = struct('pass',true,'reason','');
  checks.interface_edges_found = all(found);
  checks.constraints_found = all(ismember(constraints,edges,'rows'));
  incidence = accumarray(edge_ids,1);
  checks.interface_incidence_two = all(found) && all(incidence(interface_edges(found))==2);
  % every edge has one or two owners; one-owner edges lie on the outer box
  outer = @(p)abs(abs(p(:,1))-1.5)<tol | abs(abs(p(:,2))-0.5)<tol;
  single = incidence==1; e1 = points(edges(single,1),:); e2 = points(edges(single,2),:);
  checks.edge_incidence = all(incidence<=2) && all(outer(e1) & outer(e2) & ...
    (abs(e1(:,1)-e2(:,1))<tol | abs(e1(:,2)-e2(:,2))<tol));
  % positive orientation and per-cell coverage of the unit cell area
  cell_area = accumarray(cell_id+2,orientation/2,[3,1]);
  checks.positive_orientation = all(orientation>0);
  checks.cell_coverage = all(abs(cell_area-1)<1e-10) && all(ismember(cell_id,-1:1));
  checks.cell_affine_area = cell_area';
  midpoints = (points(edges(:,1),:)+points(edges(:,2),:))/2;
  midpoints(interface_edges(found),:) = base.midpoint_values(found,:);
  p2_points = [points;midpoints]; triangle_p2 = [triangles,nv+reshape(edge_ids,nt,3)];
  occurrence = repmat((1:nt)',3,1); sides_ok = true; owner_cells_ok = true;
  for e = interface_edges(found)'
    owners = occurrence(edge_ids==e);
    sides_ok = sides_ok && numel(owners)==2 && material(owners(1))~=material(owners(2));
    owner_cells_ok = owner_cells_ok && numel(owners)==2 && cell_id(owners(1))==cell_id(owners(2));
  end
  checks.material_sides = sides_ok; checks.interface_single_cell = owner_cells_ok;
  % element Jacobian determinant extrema on the full reference triangle
  det_min = zeros(nt,1); det_max = zeros(nt,1);
  for t = 1:nt
    coefficients = LOCAL_det_coefficients(LOCAL_map_coefficients(p2_points(triangle_p2(t,:),:)));
    [det_min(t),det_max(t)] = LOCAL_quadratic_triangle_extrema(coefficients);
  end
  det_ratio = det_max./det_min; det_ratio(det_min<=0) = Inf;
  % affine shape quality 4*sqrt(3)*A/sum(l^2) and minimum angle
  P1 = points(triangles(:,1),:); P2 = points(triangles(:,2),:); P3 = points(triangles(:,3),:);
  l1 = sum((P2-P3).^2,2); l2 = sum((P3-P1).^2,2); l3 = sum((P1-P2).^2,2);
  area = abs(orientation)/2;
  quality = 4*sqrt(3)*area./(l1+l2+l3);
  angle = @(opp,u,v)acosd(min(1,max(-1,(u+v-opp)./(2*sqrt(u.*v)))));
  min_angle = min([angle(l1,l2,l3),angle(l2,l3,l1),angle(l3,l1,l2)],[],2);
  % top/bottom pairing and wall translation pairing on P2 nodes
  top = find(abs(p2_points(:,2)-0.5)<tol); bottom = find(abs(p2_points(:,2)+0.5)<tol);
  checks.top_bottom_pairing = numel(top)==numel(bottom) && ...
    max(abs(sort(p2_points(top,1))-sort(p2_points(bottom,1))))<tol;
  walls = cell(4,1); wall_ok = true;
  for w = 1:4
    ids = abs(p2_points(:,1)-(w-2.5))<tol; walls{w} = sort(p2_points(ids,2));
    wall_ok = wall_ok && numel(walls{w})==2*cfg.subdivisions+1 && ...
      max(abs(walls{w}-(-0.5+(0:2*cfg.subdivisions)'/(2*cfg.subdivisions))))<1e-12;
  end
  checks.wall_translation_pairing = wall_ok;
  checks.only_grid_vertices_on_walls = wall_ok;
  checks.background_points = base.background_points; checks.deletable_points = base.deletable_points;
  checks.vertices = nv; checks.triangles = nt; checks.p2_nodes = size(p2_points,1);
  fields = {'interface_edges_found','constraints_found','interface_incidence_two', ...
    'edge_incidence','positive_orientation','cell_coverage', ...
    'material_sides','interface_single_cell','top_bottom_pairing','wall_translation_pairing'};
  for f = fields
    if ~checks.(f{1})
      checks.pass = false; checks.reason = [checks.reason,f{1},' failed; '];
    end
  end
  checks.det_min = det_min; checks.det_max = det_max; checks.det_ratio = det_ratio;
  checks.quality = quality; checks.min_angle = min_angle;
  mesh = struct('points',points,'triangles',triangles,'p2_points',p2_points, ...
    'triangle_p2',triangle_p2,'edges',edges,'interface_edges',interface_edges, ...
    'interface_theta',repmat(base.theta,3,1), ...
    'interface_cell',kron((-1:1)',ones(cfg.interface_segments,1)), ...
    'material',material,'cell_id',cell_id);
end

%% ==================== D2 bounded local edge flip ====================
% Design 5 step 4: flip one straight chord of an interface-adjacent bad element.
function [mesh,checks,flip] = LOCAL_flip_repair(config,cfg,base,mesh,checks,repair_timer)
  % For a bad element abc containing an interface edge and a non-constrained
  % interior edge ac shared with acd (same material and cell, patch off the
  % walls/top/bottom), replace abc, acd by abd, bcd if abcd is strictly convex,
  % the straight new edge bd meets no actual P2 patch edge except at shared
  % endpoints, and both new curved elements satisfy det_min > 0 and
  % det_max/det_min <= 20. Vertices and outer P2 midpoints are kept; bd gets
  % the arithmetic midpoint. Limits: 32 candidate checks, 16 accepted flips,
  % 30 s for all deletion/flip repair and re-checks of the level.
  rules = config.mesh_rules; L = rules.flip;
  flip = struct('checked',0,'accepted',0,'limit_hit',false,'outcome','', ...
    'trials',struct([]),'recheck_seconds',[]);
  constraint_keys = sort(base.constraints,2); interface_keys = sort(base.raw_interfaces,2);
  recheck_cost = 0; trial_cost = 0; stop = false;
  while ~stop
    bad = LOCAL_bad(checks,rules);
    if isempty(bad), flip.outcome = 'all bad elements removed'; break, end
    [~,order] = sortrows([mesh.cell_id(bad),bad]); bad = bad(order);
    progressed = false;
    for t = bad'
      tri = mesh.triangles(t,:); keys = sort([tri([1,2]);tri([2,3]);tri([3,1])],2);
      if ~any(ismember(keys,interface_keys,'rows')), continue, end
      candidates = find(~ismember(keys,constraint_keys,'rows'));
      [~,order] = sortrows(keys(candidates,:)); candidates = candidates(order)';
      for e = candidates
        % limits are checked before every operation (design 5, D2)
        elapsed = toc(repair_timer);
        if flip.checked>=L.max_checks || flip.accepted>=L.max_flips || ...
            elapsed+trial_cost+recheck_cost>rules.repair_seconds
          flip.limit_hit = true; stop = true;
          flip.outcome = sprintf(['limit reached before the next operation: %d checks, ', ...
            '%d flips, %.2fs elapsed (+%.2fs predicted)'],flip.checked,flip.accepted, ...
            elapsed,trial_cost+recheck_cost);
          break
        end
        timer = tic; flip.checked = flip.checked+1;
        [trial,new] = LOCAL_flip_trial(config,base,mesh,checks,t,e);
        if trial.accepted
          triangles = mesh.triangles; triangles(t,:) = new.tri(1,:); triangles(new.neighbor,:) = new.tri(2,:);
          rebuild = tic;
          [mesh_new,checks_new] = LOCAL_mesh_build(config,cfg,base,triangles,mesh.material,mesh.cell_id);
          recheck_cost = toc(rebuild); flip.recheck_seconds(end+1) = recheck_cost;
          bad_new = LOCAL_bad(checks_new,rules);
          patch_ok = ~any(ismember([t;new.neighbor],bad_new)) && isempty(setdiff(bad_new,bad));
          trial.gates.post_rebuild_structural = checks_new.pass;
          trial.gates.post_rebuild_no_new_bad = patch_ok;
          if checks_new.pass && patch_ok
            trial.after_p2 = mesh_new.p2_points(mesh_new.triangle_p2([t,new.neighbor],:),:);
            trial.bad_after = numel(bad_new);
            mesh = mesh_new; checks = checks_new; flip.accepted = flip.accepted+1; progressed = true;
          else
            trial.accepted = false;
            trial.reason = ['post-rebuild check failed: ',checks_new.reason];
          end
        end
        trial.seconds = toc(timer);
        trial_cost = max(trial_cost,trial.seconds-trial.accepted*recheck_cost);
        flip.trials = LOCAL_append(flip.trials,trial);
        fprintf('  FLIP check %d element %d edge [%d %d]: %s %s (%.3fs)\n',flip.checked,t, ...
          trial.edge,LOCAL_tf(trial.accepted),trial.reason,trial.seconds);
        if trial.accepted, break, end
      end
      if progressed || stop, break, end
    end
    if ~progressed && ~stop
      flip.outcome = sprintf('no admissible flip for %d remaining bad elements',numel(bad)); break
    end
  end
end

function [trial,new] = LOCAL_flip_trial(config,base,mesh,checks,t,e)
  % One candidate patch: bad element t = (a,b,c) counter-clockwise with the
  % candidate chord e = ac opposite b, neighbour (a,c,d); proposal abd, bcd.
  rules = config.mesh_rules; L = rules.flip; pts = base.points; nv = size(pts,1);
  tri = mesh.triangles(t,:); k = mod(e+1,3)+1;        % position of b (opposite edge e)
  b = tri(k); c = tri(mod(k,3)+1); a = tri(mod(k+1,3)+1);
  new = struct('tri',[],'neighbor',NaN);
  gates = struct('interior_two_owners',false,'not_constraint',true,'distinct_vertices',false, ...
    'same_material',false,'same_cell',false,'off_walls_top_bottom',false,'strictly_convex',false, ...
    'new_edge_absent',false,'no_curved_crossing',false,'new_det_positive',false, ...
    'new_det_ratio',false);
  trial = struct('element',t,'neighbor',NaN,'edge',sort([a,c]),'vertices',[a,b,c,NaN], ...
    'coordinates',[],'old_p2',[],'new_p2',[],'after_p2',[],'material',mesh.material(t), ...
    'cell',mesh.cell_id(t),'old_det',[checks.det_min(t),checks.det_max(t),checks.det_ratio(t)], ...
    'new_det',[],'gates',gates,'accepted',false,'reason','','bad_after',NaN,'seconds',0, ...
    'crossing',struct([]));
  owners = find(any(mesh.triangles==a,2) & any(mesh.triangles==c,2));
  gates.interior_two_owners = numel(owners)==2;
  if ~gates.interior_two_owners
    trial.gates = gates; trial.reason = 'chord is not shared by exactly two elements'; return
  end
  m = setdiff(owners,t); d = setdiff(mesh.triangles(m,:),[a,c]);
  trial.neighbor = m; trial.vertices = [a,b,c,d];
  gates.distinct_vertices = numel(d)==1 && numel(unique([a,b,c,d]))==4;
  gates.same_material = mesh.material(m)==mesh.material(t);
  gates.same_cell = mesh.cell_id(m)==mesh.cell_id(t);
  if gates.distinct_vertices, gates.off_walls_top_bottom = ~any(base.on_boundary([a,b,c,d])); end
  if ~(gates.distinct_vertices && gates.same_material && gates.same_cell && gates.off_walls_top_bottom)
    trial.gates = gates; trial.reason = 'patch not same-material/same-cell interior'; return
  end
  P = pts([a,b,c,d],:); trial.coordinates = P;
  edge_mid = @(u,v)mesh.p2_points(nv+find(ismember(mesh.edges,sort([u,v]),'rows')),:);
  trial.old_p2 = [mesh.p2_points(mesh.triangle_p2(t,:),:);mesh.p2_points(mesh.triangle_p2(m,:),:)];
  % strict convexity of abcd (either orientation), relative to the patch diameter
  pairs = nchoosek(1:4,2); ell = max(vecnorm(P(pairs(:,1),:)-P(pairs(:,2),:),2,2)); turn = zeros(4,1);
  for i = 1:4
    u = P(i,:)-P(mod(i-2,4)+1,:); v = P(mod(i,4)+1,:)-P(i,:); turn(i) = u(1)*v(2)-u(2)*v(1);
  end
  gates.strictly_convex = all(turn>L.convex_factor*ell^2) || all(turn<-L.convex_factor*ell^2);
  gates.new_edge_absent = ~ismember(sort([b,d]),mesh.edges,'rows');
  if ~(gates.strictly_convex && gates.new_edge_absent)
    trial.gates = gates; trial.reason = 'patch not strictly convex or bd already exists'; return
  end
  % the straight new edge bd against the actual P2 outer patch edges
  outer = [a,b;b,c;c,d;d,a]; clear_all = true; crossing = struct([]);
  for i = 1:4
    u = outer(i,1); v = outer(i,2); shared = u; other = v;
    if ~any(u==[b,d]), shared = v; other = u; end
    [ok,why] = LOCAL_segment_curve_clear(pts(shared,:),edge_mid(u,v),pts(other,:), ...
      pts(b,:),pts(d,:),L.crossing_tolerance);
    crossing = LOCAL_append(crossing,struct('edge',[u,v],'clear',ok,'why',why));
    clear_all = clear_all && ok;
  end
  trial.crossing = crossing; gates.no_curved_crossing = clear_all;
  if ~clear_all
    trial.gates = gates; trial.reason = 'new edge meets a curved patch edge or is undecidable'; return
  end
  % proposal abd, bcd (positively reoriented) and their full-element det extrema
  T = [a,b,d;b,c,d]; nodes = cell(2,1); new_det = zeros(2,3);
  bd_mid = (pts(b,:)+pts(d,:))/2;
  for j = 1:2
    r = T(j,:); o = pts(r,:); s = (o(2,1)-o(1,1))*(o(3,2)-o(1,2))-(o(2,2)-o(1,2))*(o(3,1)-o(1,1));
    if s<0, r = r([1,3,2]); T(j,:) = r; end
    mids = zeros(3,2);
    for q = 1:3
      u = r(q); v = r(mod(q,3)+1);
      if isequal(sort([u,v]),sort([b,d])), mids(q,:) = bd_mid; else, mids(q,:) = edge_mid(u,v); end
    end
    nodes{j} = [pts(r,:);mids];
    [dmin,dmax] = LOCAL_quadratic_triangle_extrema(LOCAL_det_coefficients(LOCAL_map_coefficients(nodes{j})));
    new_det(j,:) = [dmin,dmax,dmax/dmin];
  end
  trial.new_p2 = [nodes{1};nodes{2}]; trial.new_det = new_det;
  gates.new_det_positive = all(new_det(:,1)>0);
  gates.new_det_ratio = gates.new_det_positive && all(new_det(:,3)<=rules.det_ratio_max);
  trial.gates = gates;
  if ~(gates.new_det_positive && gates.new_det_ratio)
    trial.reason = sprintf('new elements det ratio [%.4g %.4g]',new_det(1,3),new_det(2,3)); return
  end
  trial.accepted = true; trial.reason = sprintf('new elements det ratio [%.4g %.4g]', ...
    new_det(1,3),new_det(2,3));
  new = struct('tri',T,'neighbor',m);
end

function [clear,why] = LOCAL_segment_curve_clear(P,M,Q,b,d,tol)
  % Curved P2 edge q(t) = P + t v1 + t^2 v2, t in [0,1], with P in {b,d}:
  % v1 = 4M-3P-Q, v2 = 2P+2Q-4M. Its meetings with the line through b,d solve
  % f(t) = det(q(t)-b, d-b) = t (c1 + c2 t); t = 0 is the shared endpoint and
  % the only other root is t* = -c1/c2. Near-double roots, collinearity or a
  % meeting within tolerance of the segment ends are rejected as undecidable.
  v1 = 4*M-3*P-Q; v2 = 2*P+2*Q-4*M; w = d-b;
  cr = @(u,v)u(1)*v(2)-u(2)*v(1);
  c1 = cr(v1,w); c2 = cr(v2,w); scale = norm(w)*(norm(v1)+norm(v2));
  clear = false;
  if abs(c1)<=tol*scale, why = 'tangent or collinear at the shared endpoint'; return, end
  if abs(c2)<=tol*scale, clear = true; why = 'no second root'; return, end
  ts = -c1/c2;
  if ts<-tol || ts>1+tol, clear = true; why = sprintf('second root t=%.6g outside [0,1]',ts); return, end
  if abs(ts)<=tol || abs(ts-1)<=tol, why = sprintf('second root t=%.6g at an edge end',ts); return, end
  q = P+ts*v1+ts^2*v2; sd = dot(q-b,w)/dot(w,w);
  if sd<-tol || sd>1+tol
    clear = true; why = sprintf('meets the line at s=%.6g outside segment bd',sd); return
  end
  if abs(sd)<=tol || abs(sd-1)<=tol, why = sprintf('meeting at s=%.6g undecidable',sd); return, end
  why = sprintf('curved edge crosses bd at t=%.6g, s=%.6g',ts,sd);
end

function text = LOCAL_tf(value)
  if value, text = 'ACCEPT'; else, text = 'reject'; end
end


function templates = LOCAL_templates(config,cfg,mesh)
  tol = config.mesh_rules.coordinate_tolerance; beta = config.model.beta*config.model.d;
  s = cfg.subdivisions; n = 2*s; checks = struct('pass',true,'reason','');
  names = {'left','center','right'}; walls_x = {[-0.5,-1.5],[-0.5,0.5],[0.5,1.5]};
  templates = struct('n',n,'beta',beta,'quadrature_order',cfg.quadrature_order);
  free_dofs = zeros(1,3);
  for c = -1:1
    name = names{c+2}; ids = find(mesh.cell_id==c);
    [nodes,~,local] = unique(mesh.triangle_p2(ids,:)); tri = reshape(local,[],6);
    xy = mesh.p2_points(nodes,:); material = mesh.material(ids);
    [K_full,M_full,area,inclusion_area] = LOCAL_assemble(xy,tri,material,cfg.quadrature_order);
    nn = size(xy,1);
    top = find(abs(xy(:,2)-0.5)<tol); bottom = find(abs(xy(:,2)+0.5)<tol);
    [~,a] = sort(xy(top,1)); top = top(a); [~,a] = sort(xy(bottom,1)); bottom = bottom(a);
    pairing = numel(top)==numel(bottom) && max(abs(xy(top,1)-xy(bottom,1)))<tol;
    master = (1:nn)'; master(top) = bottom; free = setdiff((1:nn)',top);
    [~,col] = ismember(master,free); phase = ones(nn,1); phase(top) = exp(1i*beta);
    Qqp = sparse(1:nn,col,phase,nn,numel(free));
    qp_defect = norm(Qqp(top,:)-exp(1i*beta)*Qqp(bottom,:),'fro');
    Kraw = Qqp'*K_full*Qqp; Mraw = Qqp'*M_full*Qqp;
    kdef = norm(Kraw-Kraw','fro')/norm(Kraw,'fro'); mdef = norm(Mraw-Mraw','fro')/norm(Mraw,'fro');
    K = (Kraw+Kraw')/2; M = (Mraw+Mraw')/2;
    [~,mflag] = chol(M(symamd(M),symamd(M)));
    fx = xy(free,1); fy = xy(free,2); wall = cell(1,2);
    for w = 1:2
      list = find(abs(fx-walls_x{c+2}(w))<tol); [~,a] = sort(fy(list)); wall{w} = list(a);
    end
    wall_y = [fy(wall{1}),fy(wall{2})];
    expected = -0.5+(0:n-1)'/n;
    wall_ok = numel(wall{1})==n && numel(wall{2})==n && max(abs(wall_y(:)-[expected;expected]))<1e-12;
    W = [wall{1};wall{2}]; I = setdiff((1:numel(free))',W);
    template = struct('name',name,'cell',c,'xy',xy,'tri6',tri,'material',material, ...
      'nodes',nodes,'element_ids',ids,'K_full',K_full,'M_full',M_full,'Qqp',Qqp,'K',K,'M',M, ...
      'free',free,'wall',W,'interior',I,'wall_y',expected,'top',top,'bottom',bottom, ...
      'area',area,'inclusion_area',inclusion_area);
    % fixed sparsity: AMD order for the centre Cholesky and symbolic fill for memory estimate
    pattern = spones(K(I,I))+spones(M(I,I));
    template.amd = amd(pattern);
    template.symbolic_nnz = sum(symbfact(pattern(template.amd,template.amd)));
    templates.(name) = template;
    free_dofs(c+2) = numel(free);
    check = struct('cell',c,'stiffness_hermitian_defect',kdef,'mass_hermitian_defect',mdef, ...
      'mass_chol_flag',mflag,'qp_defect',qp_defect,'top_bottom_pairing',pairing, ...
      'wall_pairing',wall_ok,'area',area,'area_defect',abs(area-1), ...
      'inclusion_area',inclusion_area,'interior_dofs',numel(I),'free_dofs',numel(free), ...
      'symbolic_chol_nnz',template.symbolic_nnz);
    pass = kdef<=config.gates.matrix_hermitian && mdef<=config.gates.matrix_hermitian && ...
      mflag==0 && qp_defect<=config.gates.qp_defect && pairing && wall_ok && abs(area-1)<1e-10;
    check.pass = pass; checks.(name) = check;
    if ~pass, checks.pass = false; checks.reason = [checks.reason,name,' matrix check failed; ']; end
  end
  % exact inclusion areas versus the curved-P2 approximation
  exact = LOCAL_exact_areas(config);
  checks.inclusion_area_exact = exact;
  checks.inclusion_area_defect = [templates.left.inclusion_area-exact(1), ...
    templates.center.inclusion_area-exact(2),templates.right.inclusion_area-exact(3)];
  % wall trace mass: 1D P2 mass with the quasi-periodic closure, per wall
  Wwall = LOCAL_wall_mass(s,beta);
  templates.wall_mass_single = Wwall;
  templates.wall_mass = blkdiag(Wwall,Wwall);
  templates.wall_chol = chol(templates.wall_mass);
  checks.wall_mass_hermitian_defect = norm(Wwall-Wwall','fro')/norm(Wwall,'fro');
  templates.checks = checks;
  templates.dimensions = struct('wall_dofs',n,'small_order',2*n,'free_dofs',free_dofs, ...
    'interior_dofs',[numel(templates.left.interior),numel(templates.center.interior), ...
    numel(templates.right.interior)],'p2_nodes',[size(templates.left.xy,1), ...
    size(templates.center.xy,1),size(templates.right.xy,1)]);
end

function W = LOCAL_wall_mass(s,beta)
  n = 2*s; h = 1/s; local = h/30*[4,2,-1;2,16,2;-1,2,4];
  rows = zeros(9*s,1); cols = rows; vals = rows; q = 0;
  for m = 0:s-1
    ids = [2*m,2*m+1,2*m+2];
    for a = 1:3
      for b = 1:3
        q = q+1; rows(q) = ids(a)+1; cols(q) = ids(b)+1; vals(q) = local(a,b);
      end
    end
  end
  Mfull = sparse(rows,cols,vals,n+1,n+1);
  Qw = sparse([1:n,n+1],[1:n,1],[ones(1,n),exp(1i*beta)],n+1,n);
  W = full(Qw'*Mfull*Qw); W = (W+W')/2;
end

function exact = LOCAL_exact_areas(config)
  theta = 2*pi*(0:8191)'/8192; exact = zeros(1,3);
  for c = -1:1
    xy = LOCAL_curve(config,c,theta); xy(:,1) = xy(:,1)-c*config.model.L;
    d = 2*pi/8192; dx = LOCAL_spectral_derivative(xy(:,1))/d; dy = LOCAL_spectral_derivative(xy(:,2))/d;
    exact(c+2) = 0.5*sum(xy(:,1).*dy-xy(:,2).*dx)*d;
  end
end

function dv = LOCAL_spectral_derivative(v)
  n = numel(v); k = [0:n/2-1,0,-n/2+1:-1]'*2*pi/n;
  dv = real(ifft(1i*k.*fft(v)));
end

function [K,M,area,inclusion_area] = LOCAL_assemble(xy,tri,material,order)
  nt = size(tri,1); nd = size(xy,1); X = reshape(xy(tri,1),nt,6); Y = reshape(xy(tri,2),nt,6);
  [lambda,weights] = LOCAL_quadrature(order); kval = zeros(nt,36); mval = zeros(nt,36);
  areas = zeros(nt,1);
  for q = 1:numel(weights)
    [basis,G] = LOCAL_basis(lambda(q,:));
    j11 = X*G(1,:)'; j12 = X*G(2,:)'; j21 = Y*G(1,:)'; j22 = Y*G(2,:)';
    d = j11.*j22-j12.*j21; w = weights(q)*d;
    dx = (j22.*G(1,:)-j21.*G(2,:))./d; dy = (-j12.*G(1,:)+j11.*G(2,:))./d;
    for b = 1:6
      for a = 1:6
        v = a+6*(b-1); kval(:,v) = kval(:,v)+w.*(dx(:,a).*dx(:,b)+dy(:,a).*dy(:,b));
        mval(:,v) = mval(:,v)+material.*w*basis(a)*basis(b);
      end
    end
    areas = areas+w;
  end
  rows = zeros(nt,36); cols = rows;
  for b = 1:6, for a = 1:6, v = a+6*(b-1); rows(:,v) = tri(:,a); cols(:,v) = tri(:,b); end, end
  K = sparse(rows(:),cols(:),kval(:),nd,nd); M = sparse(rows(:),cols(:),mval(:),nd,nd);
  area = sum(areas); inclusion_area = sum(areas(material~=1));
end


function [S,E,info] = LOCAL_eliminate(config,template,mu,method,want_extension)
  A = template.K-mu*template.M; I = template.interior; W = template.wall;
  AII = A(I,I); AIW = A(I,W); nI = numel(I); nW = numel(W);
  info = struct('valid',true,'reason','','backward',NaN,'backward_num',NaN, ...
    'backward_den',NaN,'condest',NaN,'chol_flag',NaN);
  E = [];
  rs = full(sum(abs(AII),2));
  if any(rs==0), info.valid = false; info.reason = 'ZERO_ROW'; S = []; return, end
  T = spdiags(1./sqrt(rs),0,nI,nI); B = T*AII*T;
  try
    if strcmp(method,'chol')
      p = template.amd; [Rc,flag] = chol(B(p,p)); info.chol_flag = flag;
      if flag ~= 0, info.valid = false; info.reason = 'CENTER_CHOLESKY_FAILED'; S = []; return, end
      solve = @(c)LOCAL_chol_solve(Rc,p,c); solve_h = solve;
    else
      [L,U,P,Q,R] = lu(B);
      solve = @(c)Q*(U\(L\(P*(R\c))));
      solve_h = @(c)R\(P'*(L'\(U'\(Q'*c))));
    end
  catch error_object
    info.valid = false; info.reason = ['FACTORIZATION_EXCEPTION: ',error_object.message]; S = []; return
  end
  block = config.solver.rhs_block; E = complex(zeros(nI,nW));
  norm_A = norm(AII,1); worst = 0; worst_num = 0; worst_den = 1;
  for j = 1:block:nW
    J = j:min(j+block-1,nW);
    rhs = full(-AIW(:,J)); X = T*solve(T*rhs);
    r = AII*X-rhs;
    num = sum(abs(r),1); den = norm_A*sum(abs(X),1)+sum(abs(rhs),1);
    [value,at] = max(num./max(den,realmin));
    if value>worst, worst = value; worst_num = num(at); worst_den = den(at); end
    E(:,J) = X;
  end
  info.backward = worst; info.backward_num = worst_num; info.backward_den = worst_den;
  afun = @(flag,X)LOCAL_normest_handle(flag,X,nI,solve,solve_h);
  info.condest = norm(B,1)*normest1(afun);
  S = full(A(W,W)+A(W,I)*E);
  if ~(info.backward<=config.gates.cell_backward)
    info.valid = false; info.reason = sprintf('CELL_BACKWARD %.3e',info.backward);
  elseif ~(info.condest<=config.gates.cell_condest)
    info.valid = false; info.reason = sprintf('CELL_CONDEST %.3e',info.condest);
  end
  if ~want_extension, E = []; end
end

function x = LOCAL_chol_solve(Rc,p,c)
  x = zeros(size(c),'like',complex(c)); x(p,:) = Rc\(Rc'\c(p,:));
end

function y = LOCAL_normest_handle(flag,X,n,solve,solve_h)
  switch flag
    case 'dim', y = n;
    case 'real', y = false;
    case 'notransp', y = solve(X);
    case 'transp', y = solve_h(X);
  end
end

function [D,Pout,info,qzb] = LOCAL_dtn(config,S,n)
  % I9.6 change: qzb returns the raw pencil, the complex QZ factors and the
  % ordered (stable-first) blocks for read-only audit.
  g = config.gates;
  S00 = S(1:n,1:n); S01 = S(1:n,n+1:end); S10 = S(n+1:end,1:n); S11 = S(n+1:end,n+1:end);
  Acal = [-(S11+S00),-S10;eye(n),zeros(n)]; Bcal = [S01,zeros(n);zeros(n),eye(n)];
  [AA,BB,Qz,Zz] = qz(Acal,Bcal,'complex');
  qzb = struct('Acal',Acal,'Bcal',Bcal,'AA',AA,'BB',BB,'AAs',[],'BBs',[],'Zs',[]);
  alpha = diag(AA); gamma = diag(BB);
  scale = norm(Acal,'fro')+norm(Bcal,'fro');
  magnitude = abs(alpha)+abs(gamma);
  degenerate = magnitude <= g.qz_degenerate_factor*2*n*eps*scale;
  gap = abs(abs(alpha)-abs(gamma))./magnitude;
  stable = abs(alpha)<abs(gamma);
  info = struct('valid',true,'reason','','stable_count',nnz(stable), ...
    'degenerate_count',nnz(degenerate),'min_magnitude_relative',min(magnitude)/scale, ...
    'unit_gap_min',min(gap),'z0_rcond',NaN,'invariance',NaN,'lower_block',NaN, ...
    'riccati',NaN,'riccati_num',NaN,'riccati_den',NaN,'hermitian_defect',NaN, ...
    'consistency',NaN,'consistency_rcond',NaN,'pairing_max',NaN,'pairing_count',0, ...
    'spectral_radius',NaN,'stable_abs',[],'stable_multipliers',[]);
  D = []; Pout = [];
  reasons = {};
  if any(degenerate), reasons{end+1} = sprintf('QZ_DEGENERATE %d',nnz(degenerate)); end
  if any(gap<=g.unit_gap), reasons{end+1} = sprintf('UNIT_CIRCLE_GAP %.3e',min(gap)); end
  if nnz(stable)~=n, reasons{end+1} = sprintf('STABLE_COUNT %d~=%d',nnz(stable),n); end
  % reciprocal-conjugate pairing diagnostic of finite nonzero multipliers
  finite = abs(alpha)>eps*scale & abs(gamma)>eps*scale;
  zeta = alpha(finite)./gamma(finite);
  band = abs(zeta)<g.pairing_band & abs(zeta)>1/g.pairing_band; zb = zeta(band);
  if ~isempty(zb)
    mismatch = zeros(numel(zb),1);
    for j = 1:numel(zb)
      target = 1/conj(zb(j)); mismatch(j) = min(abs(zeta-target))/abs(target);
    end
    info.pairing_max = max(mismatch); info.pairing_count = numel(zb);
  end
  if ~isempty(reasons)
    info.valid = false; info.reason = strjoin(reasons,'; '); return
  end
  [AAs,BBs,Qs,Zs] = ordqz(AA,BB,Qz,Zz,stable);
  qzb.AAs = AAs; qzb.BBs = BBs; qzb.Zs = Zs;
  Z = Zs(:,1:n); Z1 = Z(1:n,:); Z0 = Z(n+1:end,:); Y = Qs(1:n,:)';
  info.z0_rcond = rcond(Z0);
  normA = norm(Acal,'fro'); normB = norm(Bcal,'fro');
  info.invariance = (norm(Acal*Z-Y*AAs(1:n,1:n),'fro')+norm(Bcal*Z-Y*BBs(1:n,1:n),'fro'))/ ...
    ((normA+normB)*norm(Z,'fro'));
  Ts = BBs(1:n,1:n)\AAs(1:n,1:n);
  info.lower_block = norm(Z1-Z0*Ts,'fro')/max(norm(Z1,'fro'),norm(Z0*Ts,'fro'));
  alpha_s = diag(AAs(1:n,1:n)); gamma_s = diag(BBs(1:n,1:n));
  info.stable_multipliers = alpha_s./gamma_s; info.stable_abs = sort(abs(info.stable_multipliers),'descend');
  info.spectral_radius = info.stable_abs(1);
  if ~(info.z0_rcond>g.z0_rcond)
    info.valid = false; info.reason = sprintf('Z0_RCOND %.3e',info.z0_rcond); return
  end
  Pout = Z1/Z0;
  residual = S01*Pout^2+(S11+S00)*Pout+S10;
  info.riccati_num = norm(residual,'fro');
  info.riccati_den = norm(S01,'fro')*norm(Pout,'fro')^2+norm(S11+S00,'fro')*norm(Pout,'fro')+norm(S10,'fro');
  info.riccati = info.riccati_num/info.riccati_den;
  D = S00+S01*Pout;
  info.hermitian_defect = norm(D-D','fro')/max(1,norm(D,'fro'));
  info.consistency_rcond = rcond(S11+D);
  if info.consistency_rcond>g.consistency_rcond
    Dc = S00-S01*((S11+D)\S10);
    info.consistency = norm(D-Dc,'fro')/max(norm(D,'fro'),realmin);
  end
  reasons = {};
  if ~(info.invariance<=g.invariance), reasons{end+1} = sprintf('INVARIANCE %.3e',info.invariance); end
  if ~(info.riccati<=g.riccati), reasons{end+1} = sprintf('RICCATI %.3e',info.riccati); end
  if ~(info.hermitian_defect<=g.dtn_hermitian), reasons{end+1} = sprintf('DTN_HERMITIAN %.3e',info.hermitian_defect); end
  if ~isnan(info.consistency) && ~(info.consistency<=g.dtn_consistency)
    reasons{end+1} = sprintf('DTN_CONSISTENCY %.3e',info.consistency);
  end
  if ~isempty(reasons), info.valid = false; info.reason = strjoin(reasons,'; '); end
end

%% ==================== One frequency response ====================
% Both leads, then the centre; every frequency rebuilds the DtN from scratch.
function [res,ext] = LOCAL_evaluate(config,templates,k,want_extension)
  mu = k^2; n = templates.n;
  res = struct('k',k,'mu',mu,'valid',true,'reason_left','','reason_right','', ...
    'reason_center','','times',struct('lead_elimination',0,'qz_dtn',0,'center_small',0), ...
    'cell',struct(),'dtn',struct(),'lambda',[],'V',[],'H_norm',NaN, ...
    'H_hermitian_defect',NaN,'F_hermitian_defect',NaN,'rss_bytes',NaN);
  ext = struct();
  res.rss_bytes = LOCAL_rss();
  for side = {'left','right'}
    name = side{1}; t = templates.(name);
    LOCAL_memory_gate(config,['lead ',name],LOCAL_cell_bytes(config,t,want_extension),res.rss_bytes);
    timer = tic;
    [S,E,info] = LOCAL_eliminate(config,t,mu,'lu',want_extension);
    res.times.lead_elimination = res.times.lead_elimination+toc(timer);
    res.cell.(name) = info;
    if ~info.valid
      res.valid = false; res.(['reason_',name]) = info.reason;
      res.dtn.(name) = struct(); continue
    end
    timer = tic;
    [D,Pout,dinfo,qzb] = LOCAL_dtn(config,S,n);
    res.times.qz_dtn = res.times.qz_dtn+toc(timer);
    res.dtn.(name) = rmfield(dinfo,{'stable_multipliers'});
    if ~dinfo.valid
      res.valid = false; res.(['reason_',name]) = dinfo.reason; continue
    end
    res.(['D_',name]) = D;
    if want_extension
      ext.(name) = struct('S',S,'E',E,'D',D,'Pout',Pout,'multipliers',dinfo.stable_multipliers, ...
        'qz',qzb);
    end
  end
  if ~res.valid, return, end
  t = templates.center;
  LOCAL_memory_gate(config,'center',LOCAL_cell_bytes(config,t,want_extension),res.rss_bytes);
  timer = tic;
  [Sc,Ec,info] = LOCAL_eliminate(config,t,mu,'chol',want_extension);
  res.cell.center = info;
  if ~info.valid
    res.valid = false; res.reason_center = info.reason;
    res.times.center_small = res.times.center_small+toc(timer); return
  end
  F = Sc+blkdiag(res.D_left,res.D_right);
  Rw = templates.wall_chol;
  H = (Rw')\F/Rw;
  res.F_hermitian_defect = norm(F-F','fro')/max(1,norm(F,'fro'));
  res.H_hermitian_defect = norm(H-H','fro')/max(1,norm(H,'fro'));
  if ~(res.H_hermitian_defect<=config.gates.h_hermitian)
    res.valid = false; res.reason_center = sprintf('H_HERMITIAN %.3e',res.H_hermitian_defect);
    res.times.center_small = res.times.center_small+toc(timer); return
  end
  Hs = (H+H')/2;
  [V,L] = eig(Hs); [lambda,order] = sort(real(diag(L))); V = V(:,order);
  res.lambda = lambda; res.V = V; res.H_norm = max(abs(lambda));
  res.times.center_small = res.times.center_small+toc(timer);
  if want_extension
    ext.center = struct('S',Sc,'E',Ec,'F',F,'H',H);
  end
  res = rmfield(res,intersect(fieldnames(res),{'D_left','D_right'}));
end

function bytes = LOCAL_cell_bytes(config,t,want_extension)
  nI = numel(t.interior); nW = numel(t.wall);
  factor = config.solver.lu_fill_allowance*2*16*t.symbolic_nnz;   % L and U, complex
  bytes = factor+16*nI*nW*(1+want_extension)+3*16*nnz(t.K);
end


function gap = LOCAL_gap(lambda,index)
  others = lambda; others(index) = []; gap = min(abs(others-lambda(index)));
end


function rss = LOCAL_rss()
  [flag,text] = system(sprintf('ps -o rss= -p %d',feature('getpid')));
  rss = NaN;
  if flag==0, rss = 1024*str2double(strtrim(text)); end
end

function LOCAL_memory_gate(config,label,bytes,rss)
  if nargin<4, rss = LOCAL_rss(); end
  if rss+bytes>config.resources.internal_gate_bytes
    error('i96:ResourceStop','Predicted %s memory %.0f + RSS %.0f exceeds %.0f bytes.', ...
      label,bytes,rss,config.resources.internal_gate_bytes);
  end
end


function LOCAL_json(path,value)
  text = jsonencode(LOCAL_jsonable(value),'PrettyPrint',true);
  fid = fopen(path,'w'); assert(fid>=0,'i96:IO','Cannot open JSON output.');
  cleanup = onCleanup(@()fclose(fid)); fprintf(fid,'%s\n',text);
end

function value = LOCAL_jsonable(value)
  % complex arrays become {real, imag}; structs and cells are visited recursively
  if isstruct(value)
    fields = fieldnames(value);
    for j = 1:numel(value)
      for f = 1:numel(fields), value(j).(fields{f}) = LOCAL_jsonable(value(j).(fields{f})); end
    end
  elseif iscell(value)
    value = cellfun(@LOCAL_jsonable,value,'UniformOutput',false);
  elseif isnumeric(value) && ~isreal(value)
    value = struct('real',real(value),'imag',imag(value));
  elseif issparse(value)
    value = full(value);
  end
end

%% ==================== P2 reference algebra (from I9.3/I4.1c) ====================
% Basis, Duffy quadrature and full-triangle Jacobian determinant extrema.
function [basis,G] = LOCAL_basis(l)
  gl = [-1,1,0;-1,0,1]; basis = [l.*(2*l-1),4*l(1)*l(2),4*l(2)*l(3),4*l(3)*l(1)];
  G = zeros(2,6);
  for j = 1:3, G(:,j) = (4*l(j)-1)*gl(:,j); end
  G(:,4) = 4*(l(1)*gl(:,2)+l(2)*gl(:,1));
  G(:,5) = 4*(l(2)*gl(:,3)+l(3)*gl(:,2));
  G(:,6) = 4*(l(3)*gl(:,1)+l(1)*gl(:,3));
end

function [lambda,weights] = LOCAL_quadrature(order)
  j = (1:order-1)'; b = j./sqrt(4*j.^2-1); [V,D] = eig(diag(b,1)+diag(b,-1));
  [x,idx] = sort(diag(D)); w = V(1,idx)'.^2; x = (x+1)/2;
  [r,s] = ndgrid(x,x); [wr,ws] = ndgrid(w,w); xi = r(:); eta = (1-xi).*s(:);
  lambda = [1-xi-eta,xi,eta]; weights = wr(:).*ws(:).*(1-xi);
end

function coefficients = LOCAL_map_coefficients(nodes)
  coefficients = [nodes(1,:);-3*nodes(1,:)-nodes(2,:)+4*nodes(4,:); ...
    -3*nodes(1,:)-nodes(3,:)+4*nodes(6,:);2*nodes(1,:)+2*nodes(2,:)-4*nodes(4,:); ...
    4*nodes(1,:)-4*nodes(4,:)+4*nodes(5,:)-4*nodes(6,:);2*nodes(1,:)+2*nodes(3,:)-4*nodes(6,:)];
end

function c = LOCAL_det_coefficients(map)
  a = map(2,:); b = map(3,:); d = map(4,:); e = map(5,:); f = map(6,:);
  cross2 = @(x,y)x(1)*y(2)-x(2)*y(1);
  c = [cross2(a,b),cross2(2*d,b)+cross2(a,e),cross2(e,b)+cross2(a,2*f), ...
    cross2(2*d,e),4*cross2(d,f),cross2(e,2*f)];
end

function value = LOCAL_q(c,x,y)
  value = c(1)+c(2)*x+c(3)*y+c(4)*x.^2+c(5)*x.*y+c(6)*y.^2;
end

function [minimum,maximum] = LOCAL_quadratic_triangle_extrema(c)
  % vertices, edge stationary points and the interior stationary point
  candidates = [0,0;1,0;0,1]; edges = [c(4),c(2);c(6),c(3);c(4)-c(5)+c(6),c(2)-c(3)+c(5)-2*c(6)];
  for j = 1:3
    if abs(edges(j,1))>eps*max(1,norm(edges(j,:),1))
      t = -edges(j,2)/(2*edges(j,1));
      if t>0 && t<1
        if j==1, p = [t,0]; elseif j==2, p = [0,t]; else, p = [t,1-t]; end
        candidates(end+1,:) = p; %#ok<AGROW>
      end
    end
  end
  H = [2*c(4),c(5);c(5),2*c(6)];
  if rcond(H)>64*eps
    p = -H\c(2:3)';
    if all(p>0) && sum(p)<1, candidates(end+1,:) = p'; end
  end
  values = LOCAL_q(c,candidates(:,1),candidates(:,2));
  minimum = min(values); maximum = max(values);
end

function y = LOCAL_rep(x,counts)
  % Column-vector repelem (MATLAB returns a row for a scalar input).
  y = reshape(repelem(x(:),counts(:)),[],1);
end
