function enrich_i101(output_dir,mode)
%ENRICH_I101 I10.1: true-material P2/P3/P4 enrichment and conditional eigenvalue error estimate.
% Purpose: Implement design-10-1a (D1). On the fixed I9.5b fine three-cell
%   curved-P2 geometry, raise the field order p = 2,3,4 on all three cell
%   templates, assemble the true-material mass by the oriented thin-band
%   homotopy identity, close the centre cell by the complete discrete
%   stable-subspace DtN of both leads, and find independent bracketed roots
%   (primary and check rules, at most one extra rule per layer). Save a signed
%   P3 Newton prediction at the old candidate before any P3 root, compute the
%   complete infinite FE mass (centre + two Stein lead masses), and form the
%   conditional estimate B4, R0, RN under the declared S_{1/2} and E.
% Input: output_dir is a new run directory; mode is 'formal', 'smoke' or
%   'sizing' (assembly, symbolic fill and one timed evaluation per order).
% Output: config.json, result.json, prediction-*.json, iterations.csv,
%   timing.json, progress.json, evidence.mat, layer/recovery/prediction MAT
%   files and figures/*.png. The BIE reference never enters this code.
% Main algorithm:
%   1. deterministic rebuild of the s48-n320 joint mesh (I9.5b rules);
%   2. P_p dofs on each template (shared-edge orientation j -> p-j, interior
%      dofs owned by one element), top/bottom QP map Qqp, walls with n_p = s*p
%      dofs; P_p -> P_{p+1} embeddings with basis/wall/QP checks;
%   3. per rule: volume K, M_{p,h} by Gauss-Duffy quadrature and the oriented
%      thin-band correction
%        dM_p = (rho_in-1) sum_seg int_0^1 int_0^1 Psi(H) Psi(H)^T J_H dtau dt,
%        H = gamma_h + tau (gamma - gamma_h),  J_H = det(H_tau, H_t)  (signed),
%      with every band point located in the curved FE mesh;
%   4. per frequency: lead LU/multi-RHS Schur S, ordered QZ -> Pout,
%      D = S00 + S01 Pout; centre Cholesky -> S_c; F = S_c + diag(D-,D+);
%      branch theta of F g = theta W g; bracket + Brent on the fixed branch;
%   5. prediction mu_N = mu_0 + theta_3(mu_0) / m_inf,3(mu_0) with
%      m_inf = u_c^* M_c u_c + g_-^* X^- g_- + g_+^* X^+ g_+,
%      X - P^* X P = G = B^* M B by Frobenius-tail doubling (no Kronecker);
%   6. conditional estimate (q = 1/2):
%      B4 = |nu4-nu3| + eps3 + 2 eps4, R0 = |mu0-nu4| + B4, RN = |muN-nu4| + B4.
% Based on: test/i9/fem-dtn-v1/fem_dtn_i95b.m (mesh, QP templates, Schur/QZ
%   DtN, branch tracking, Brent, delivery checks, ledger and I/O).
% Main changes: general P_p Lagrange fields on the fixed P2 geometry, true
%   material thin-band mass, three integration rules, no full E storage
%   (block Schur, near-wall extension B only at recovery/prediction), Stein
%   infinite mass, Newton prediction saved before the P3 roots, derivative
%   diagnostic, conditional estimate with fixed labels S_verified=false and
%   E_certified=false.
%   Design D2: one thin-band owner per point by (-b_K, r_K/h_K, element id)
%   with dual differences recorded only; two-sided shared-edge trace check;
%   root qualification independent of Stein/derivative diagnostics; strict
%   brackets (a floating-point zero is never a zero-width bracket); usable
%   unresolved roots kept as ROOT_CANDIDATE_UNRESOLVED; B4/R0 need only the
%   P3/P4 roots, RN additionally a finite mu_N.
% Numerical goal: qualified roots with k bracket <= 2e-12, mu bracket <=
%   eps_p/8, |theta| <= 1e-10, uncondensed residual <= 1e-9; ordinary
%   floating-point evidence only, never an unconditional bound.
  if nargin < 2, mode = 'formal'; end
  entry_utc = LOCAL_utc();
  started = tic;
  config = enrich_i101_config(mode);
  if ~isfolder(output_dir), mkdir(output_dir); end
  if ~isfolder(fullfile(output_dir,'figures')), mkdir(fullfile(output_dir,'figures')); end
  maxNumCompThreads(config.resources.threads);
  LOCAL_ledger('reset');
  ctx = struct('output_dir',output_dir,'started',started,'config',config, ...
    'iterations_path',fullfile(output_dir,'iterations.csv'), ...
    'progress_path',fullfile(output_dir,'progress.json'));
  LOCAL_json(fullfile(output_dir,'config.json'),config);
  environment = struct('matlab_version',version,'platform',computer, ...
    'max_threads',maxNumCompThreads,'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS'), ...
    'entry_utc',entry_utc,'pid',feature('getpid'));
  LOCAL_iteration_header(ctx.iterations_path);
  fprintf('ENTRY %s mode=%s threads=%d\n',entry_utc,mode,maxNumCompThreads);
  stage = 'mesh';
  result = LOCAL_result_stub(config,environment);
  chains = struct([]); layers = struct([]); predictions = struct([]);
  try
    % --- stage 1: deterministic fine mesh rebuild and identity record ---
    LOCAL_progress(ctx,'mesh',struct());
    timer = tic; [mesh,geometry] = LOCAL_mesh(config);
    LOCAL_ledger('add','mesh',toc(timer));
    result.geometry = rmfield(geometry,{'repair_rounds'});
    result.mesh_identity = LOCAL_mesh_identity(config,mesh);
    fprintf('STAGE mesh: %d triangles, %d P2 nodes, status %s\n',size(mesh.triangles,1), ...
      size(mesh.p2_points,1),geometry.status);
    if ~strcmp(geometry.status,'PASS')
      result.final_status = 'GEOMETRY_FAILED'; result.final_reason = geometry.reason;
      LOCAL_finish(ctx,result,chains,layers,predictions,mesh,struct(),struct()); return
    end
    % --- stage 2: P_p spaces, QP/wall maps, embeddings and basis checks ---
    stage = 'spaces'; LOCAL_progress(ctx,'spaces',struct());
    timer = tic; spaces = cell(1,max(config.orders));
    for p = config.orders, spaces{p} = LOCAL_space(config,mesh,p); end
    LOCAL_ledger('add','dofs',toc(timer));
    timer = tic;
    result.basis_checks = LOCAL_basis_checks(config.orders);
    embeddings = cell(1,max(config.orders));
    for p = config.orders(1:end-1)
      embeddings{p} = LOCAL_embedding(config,spaces{p},spaces{p+1});
    end
    LOCAL_ledger('add','basis_embedding_checks',toc(timer));
    result.spaces = LOCAL_space_summary(spaces,embeddings,config);
    timer = tic; result.edge_traces = LOCAL_edge_traces(config,mesh,spaces);
    LOCAL_ledger('add','basis_embedding_checks',toc(timer));
    fprintf('STAGE shared-edge traces: pass %d geometry %.2e traces %s\n',result.edge_traces.pass, ...
      max([result.edge_traces.templates.geometry_defect]), ...
      mat2str(max(vertcat(result.edge_traces.templates.trace_defect),[],1),3));
    if ~result.edge_traces.pass
      result.final_status = 'SHARED_EDGE_TRACE_FAILED';
      result.final_reason = 'two-sided P2 geometry or P_p trace differs on a shared edge';
      LOCAL_finish(ctx,result,chains,layers,predictions,mesh,spaces,embeddings); return
    end
    for p = config.orders
      d = result.spaces(p-1);
      fprintf('STAGE space P%d: dofs [%d %d %d], free [%d %d %d], wall n=%d\n',p, ...
        d.dofs,d.free_dofs,d.wall_dofs);
    end
    if strcmp(mode,'sizing')
      stage = 'sizing';
      result.sizing = LOCAL_sizing(ctx,mesh,spaces);
      result.final_status = 'SIZING_ONLY';
      LOCAL_finish(ctx,result,chains,layers,predictions,mesh,spaces,embeddings); return
    end
    % --- stage 3: thin-band point location for the primary and check rules ---
    stage = 'location'; LOCAL_progress(ctx,'location',struct());
    bands = struct();
    for r = 1:2
      rule = config.rules(r); timer = tic;
      bands.(rule.name) = LOCAL_band_locate(config,mesh,rule,spaces);
      LOCAL_ledger('add','location',toc(timer));
      fprintf('STAGE location %s: %d points, failures %d, dual %d, tolerance owners %d, %.2fs\n', ...
        rule.name,bands.(rule.name).total_points,bands.(rule.name).total_failures, ...
        bands.(rule.name).total_dual,bands.(rule.name).total_tolerance_owner,toc(timer));
      if bands.(rule.name).total_failures > 0
        result.final_status = 'POINT_LOCATION_FAILED';
        result.final_reason = sprintf('%s rule: %d band points not located', ...
          rule.name,bands.(rule.name).total_failures);
        result.bands = LOCAL_band_summary(bands);
        LOCAL_finish(ctx,result,chains,layers,predictions,mesh,spaces,embeddings,bands); return
      end
    end
    result.bands = LOCAL_band_summary(bands);
    % --- stage 4: layers p = 2,3,4 (primary, check, conditional extra) ---
    previous = []; raw_previous = [];
    for p = config.orders
      stage = sprintf('layer:P%d',p);
      [layer,new_chains,new_predictions,raw_previous,previous,bands] = LOCAL_layer(ctx, ...
        p,spaces,embeddings,bands,mesh,previous,raw_previous);
      chains = LOCAL_append(chains,new_chains);
      predictions = LOCAL_append(predictions,new_predictions);
      layers = LOCAL_append(layers,layer);
      LOCAL_partial(ctx,chains,layers,predictions);
      fprintf('LAYER P%d status %s final %s mu=%.17g\n',p,layer.status,layer.final_rule,layer.nu);
    end
    clear raw_previous
    result.bands = LOCAL_band_summary(bands);
    % --- stage 5: same-mode evidence and conditional estimate ---
    stage = 'estimate'; LOCAL_progress(ctx,'estimate',struct('all_roots_done',true));
    timer = tic;
    result.same_mode = LOCAL_same_mode(config,chains,layers,spaces);
    result.estimate = LOCAL_estimate(config,layers,predictions,result.same_mode);
    LOCAL_ledger('add','estimate',toc(timer));
    result.final_status = result.estimate.final_status;
    result.final_reason = result.estimate.final_reason;
    result.matlab_elapsed_at_final_candidate = result.estimate.matlab_elapsed_at_final_candidate;
    LOCAL_finish(ctx,result,chains,layers,predictions,mesh,spaces,embeddings,bands);
  catch error_object
    status = 'IMPLEMENTATION_OR_DTN_EXCEPTION';
    if strcmp(error_object.identifier,'i101:ResourceStop'), status = 'RESOURCE_STOP'; end
    failure = struct('stage',stage,'status',status,'identifier',error_object.identifier, ...
      'message',error_object.message,'report',getReport(error_object,'extended','hyperlinks','off'), ...
      'elapsed_seconds',toc(started),'timing',LOCAL_ledger('close',toc(started)));
    failure.stack = error_object.stack;
    LOCAL_json(fullfile(output_dir,'failure.json'),failure);
    LOCAL_partial(ctx,chains,layers,predictions);
    rethrow(error_object);
  end
end

function result = LOCAL_result_stub(config,environment)
  result = struct('schema',config.schema,'mode',config.mode,'final_status','', ...
    'final_reason','','k0',config.k0,'mu0',config.mu0,'environment',environment, ...
    'geometry',struct(),'mesh_identity',struct(),'basis_checks',struct(),'spaces',struct([]), ...
    'edge_traces',struct(),'same_mode',struct(),'estimate',struct(), ...
    'matlab_elapsed_at_final_candidate',NaN);
end

function LOCAL_finish(ctx,result,chains,layers,predictions,mesh,spaces,embeddings,bands)
  % Figures, machine outputs and the timing ledger (always attempted).
  if nargin < 9, bands = struct(); end
  config = ctx.config; started = ctx.started;
  LOCAL_progress(ctx,'figures',struct('all_roots_done',true));
  timer = tic;
  try
    result.figures = LOCAL_figures(ctx,result,chains,layers,predictions);
  catch error_object
    result.figures = struct('status','FIGURE_ERROR','message',error_object.message);
  end
  LOCAL_ledger('add','figures',toc(timer));
  LOCAL_progress(ctx,'save',struct('all_roots_done',true));
  timer = tic;
  result.chains = LOCAL_slim_chains(chains); result.layers = layers;
  result.predictions = predictions;
  evidence = LOCAL_evidence(mesh,spaces,embeddings,bands);
  info = whos('evidence'); LOCAL_memory_gate(config,'export',2*info.bytes);
  save(fullfile(ctx.output_dir,'evidence.mat'),'config','evidence','chains','layers', ...
    'predictions','-v7');
  LOCAL_ledger('add','save',toc(timer));
  result.timing = LOCAL_ledger('close',toc(started));
  LOCAL_json(fullfile(ctx.output_dir,'timing.json'),result.timing);
  LOCAL_json(fullfile(ctx.output_dir,'result.json'),result);
  LOCAL_progress(ctx,'done',struct('all_roots_done',true));
  fprintf('COMPLETE %s matlab %.2fs\n',result.final_status,toc(started));
end

function list = LOCAL_append(list,item)
  if isempty(item), return, end
  if isempty(list), list = item; else, list = [list,item]; end %#ok<AGROW>
end

%% ==================== Layer orchestration ====================
% One field order: primary root, check root (+ prediction at P3), conditional extra, recovery.
function [layer,chains,preds,raw_check,final_chain,bands] = LOCAL_layer(ctx,p,spaces,embeddings, ...
    bands,mesh,previous,raw_previous)
  config = ctx.config; sp = spaces{p}; eps_p = config.epsilon(p-1);
  layer = LOCAL_layer_stub(p,eps_p); chains = struct([]); preds = struct([]);
  raw_check = raw_previous; final_chain = [];
  if p > config.orders(1) && (isempty(previous) || ~previous.qualified)
    layer.status = 'NOT_RUN'; layer.reason = 'previous layer has no qualified final root';
    return
  end
  if isempty(previous)
    k_start = config.k0;
    reference = struct('type','smallest','g',[],'p',NaN,'s',NaN,'source','K0_SMALLEST_ABS_THETA');
  else
    k_start = previous.k;
    reference = struct('type','transfer','g',previous.g,'p',previous.p,'s',sp.s, ...
      'source',['ROOT:',previous.name]);
  end
  % --- primary rule root ---
  ops = LOCAL_operators(ctx,sp,bands.primary,config.rules(1),false,p==config.orders(1));
  layer.matrix_checks.primary = ops.checks;
  if p == config.orders(1)
    layer.identity_diagnostic = LOCAL_identity_diagnostic(ctx,ops);
  end
  ops = LOCAL_drop_nominal(ops);
  primary = LOCAL_chain_run(ctx,ops,sp,'primary',k_start,reference,eps_p);
  chains = LOCAL_append(chains,primary);
  clear ops
  % --- check rule (default final): nested checks, saved matrices, prediction ---
  ops = LOCAL_operators(ctx,sp,bands.check,config.rules(2),true,false);
  layer.matrix_checks.check = ops.checks;
  if ~isempty(raw_previous) && p > config.orders(1)
    timer = tic;
    layer.nested = LOCAL_nested(config,raw_previous,LOCAL_nested_input(ops),embeddings{p-1});
    LOCAL_ledger('add','basis_embedding_checks',toc(timer));
  end
  LOCAL_save_raw(ctx,ops,'check'); raw_check = LOCAL_nested_input(ops); ops.raw = [];
  if p == 3
    pred = LOCAL_predict(ctx,ops,sp,previous,'check');
    preds = LOCAL_append(preds,pred);
  end
  if primary.qualified
    k_check = primary.k;
    ref_check = struct('type','transfer','g',primary.g,'p',p,'s',sp.s,'source',['ROOT:',primary.name]);
  else
    k_check = k_start; ref_check = reference;
  end
  check = LOCAL_chain_run(ctx,ops,sp,'check',k_check,ref_check,eps_p);
  chains = LOCAL_append(chains,check);
  final = check; layer.final_rule = 'check';
  % --- conditional extra rule (at most once, only for this layer) ---
  trigger = eps_p*config.extra_trigger_factor;
  if primary.qualified && check.qualified
    layer.rule_difference_primary_check = abs(primary.mu-check.mu);
    if layer.rule_difference_primary_check > trigger
      layer.extra_triggered = true;
      clear ops
      if ~isfield(bands,'extra')
        timer = tic; bands.extra = LOCAL_band_locate(config,mesh,config.rules(3),spaces);
        LOCAL_ledger('add','location',toc(timer));
      end
      if bands.extra.total_failures > 0
        error('i101:PointLocation','POINT_LOCATION_FAILED: extra rule, %d band points', ...
          bands.extra.total_failures);
      end
      ops = LOCAL_operators(ctx,sp,bands.extra,config.rules(3),true,false);
      layer.matrix_checks.extra = ops.checks;
      LOCAL_save_raw(ctx,ops,'extra'); ops.raw = [];
      if p == 3
        pred = LOCAL_predict(ctx,ops,sp,previous,'extra');
        preds = LOCAL_append(preds,pred);
      end
      ref_extra = struct('type','transfer','g',check.g,'p',p,'s',sp.s,'source',['ROOT:',check.name]);
      extra = LOCAL_chain_run(ctx,ops,sp,'extra',check.k,ref_extra,eps_p);
      chains = LOCAL_append(chains,extra);
      if extra.qualified
        layer.rule_difference_check_extra = abs(check.mu-extra.mu);
        final = extra; layer.final_rule = 'extra';
        if layer.rule_difference_check_extra <= trigger
          layer.evaluation_status = 'RESOLVED_BY_EXTRA';
        else
          layer.evaluation_status = 'EVALUATION_UNRESOLVED';
        end
      else
        % extra root failed: keep the check root numerically, mark unresolved
        layer.evaluation_status = 'EVALUATION_UNRESOLVED';
        layer.reason = ['extra root failed: ',extra.status,' ',extra.reason];
        clear ops
        ops = LOCAL_operators(ctx,sp,bands.check,config.rules(2),false,false);
      end
    else
      layer.evaluation_status = 'RESOLVED';
    end
  else
    layer.evaluation_status = 'UNAVAILABLE';
    layer.reason = sprintf('primary %s / check %s',primary.status,check.status);
  end
  % D2 5.1: an unresolved but usable final root keeps its value; label only
  layer.root_resolved = final.resolved;
  if final.qualified && ~final.resolved
    layer.evaluation_status = 'EVALUATION_UNRESOLVED';
    layer.reason = strtrim([layer.reason,' final root resolution targets not met: ',final.reason]);
  end
  % --- recovery, delivery checks and complete infinite mass at the final root ---
  layer.chain_names = {chains.name};
  if final.qualified
    stage_timer = tic; inner = LOCAL_ledger('total');
    LOCAL_progress(ctx,'recovery',struct('chain',final.name,'slowest_eval_seconds',final.slowest_eval_seconds));
    record = LOCAL_recover(ctx,ops,sp,final);
    LOCAL_ledger('add','recovery_delivery',toc(stage_timer)-(LOCAL_ledger('total')-inner));
    layer.recovery = record; layer.recovery_seconds = toc(stage_timer);
    layer.qualified = record.pass; layer.mass_status = record.mass_status;
    layer.nu = final.mu; layer.k = final.k; layer.final_chain = final.name;
    layer.theta = final.theta; layer.bracket_mu_width = final.bracket_mu_width;
    layer.status = 'ROOT_QUALIFIED';
    if ~record.pass
      layer.status = 'CELL_OR_DTN_EXCEPTION';
      layer.reason = strtrim([layer.reason,' delivery gates failed: ',record.failed_gates]);
    end
  else
    layer.status = final.status; layer.reason = strtrim([layer.reason,' final root ',final.status,' ',final.reason]);
    layer.final_chain = final.name;
  end
  layer.matlab_elapsed_at_completion = toc(ctx.started);
  final_chain = final; final_chain.qualified = layer.qualified;
  clear ops
end

function layer = LOCAL_layer_stub(p,eps_p)
  layer = struct('p',p,'epsilon',eps_p,'status','PENDING','reason','','final_rule','', ...
    'final_chain','','nu',NaN,'k',NaN,'theta',NaN,'bracket_mu_width',NaN,'qualified',false, ...
    'evaluation_status','NOT_EVALUATED','extra_triggered',false, ...
    'rule_difference_primary_check',NaN,'rule_difference_check_extra',NaN, ...
    'matrix_checks',struct(),'nested',struct(),'identity_diagnostic',struct(), ...
    'recovery',struct(),'recovery_seconds',NaN,'chain_names',{{}}, ...
    'root_resolved',false,'mass_status','NOT_COMPUTED','matlab_elapsed_at_completion',NaN);
end

function item = LOCAL_chain_run(ctx,ops,sp,rule,k_start,reference,eps_p)
  % Wraps one independent bracketed root chain (fixed rule, fixed order).
  name = sprintf('P%d-%s',sp.p,rule);
  item = LOCAL_chain_stub(name,sp.p,rule,eps_p);
  item.initialization_source = reference.source;
  selector = struct('type',reference.type,'index',NaN,'y',[]);
  if strcmp(reference.type,'transfer')
    g = LOCAL_transfer(reference.g,reference.s,reference.p,sp.center.wall_y,sp.beta);
    y = ops.wall_chol*g; selector.y = y/norm(y);
  end
  timer = tic; inner = LOCAL_ledger('total');
  LOCAL_progress(ctx,'root',struct('chain',name));
  item = LOCAL_chain(ctx,ops,item,k_start,selector);
  total = toc(timer);
  LOCAL_ledger('add','root_control',total-(LOCAL_ledger('total')-inner));
  item.root_seconds = total;
  item.matlab_elapsed_at_completion = toc(ctx.started);
  fprintf('CHAIN %s %s k=%.16g mu=%.17g theta=%.2e evals=%d %.1fs %s\n',name,item.status, ...
    item.k,item.mu,item.theta,item.frequency_count,total,item.reason);
end

function item = LOCAL_chain_stub(name,p,rule,eps_p)
  item = struct('name',name,'p',p,'rule',rule,'epsilon',eps_p,'status','PENDING', ...
    'substatus','','reason','','initialization_source','','k_init',NaN,'k',NaN,'mu',NaN, ...
    'bracket_low',NaN,'bracket_high',NaN,'bracket_k_width',NaN,'bracket_mu_width',NaN, ...
    'theta',NaN,'theta_scaled',NaN,'branch_index',NaN,'qualified',false, ...
    'center_residual',NaN,'center_recovery_residual',NaN,'frequency_count',0,'cache_hits',0, ...
    'halvings',0,'slowest_eval_seconds',0,'root_seconds',0,'matlab_elapsed_at_completion',NaN, ...
    'selection',struct(),'root',struct(),'g',[],'y',[],'resolved',false, ...
    'root_zero_start',false,'resolution',struct());
end

%% ==================== Prediction and derivative diagnostic ====================
% Signed one-step prediction at the old candidate, saved before any P3 root.
function pred = LOCAL_predict(ctx,ops,sp,previous,label)
  config = ctx.config; eps3 = config.epsilon(2);
  pred = struct('label',label,'p',sp.p,'rule',ops.rule,'status','PENDING','reason','', ...
    'k0',config.k0,'mu0',config.mu0,'reference_source',['ROOT:',previous.name], ...
    'selection',struct(),'smallest_abs_index',NaN,'index',NaN,'theta',NaN, ...
    'mass',struct(),'m_inf',NaN,'delta_mu',NaN,'mu_N',NaN,'k_N',NaN,'k_N_status','', ...
    'outside_window',false,'truncation_cost',NaN,'truncation_target',eps3*config.stein.prediction_factor, ...
    'truncation_resolved',false,'saved_utc','','matlab_elapsed_saved',NaN, ...
    'derivative_check',struct(),'seconds',NaN,'derivative_seconds',NaN);
  timer = tic; inner = LOCAL_ledger('total');
  LOCAL_progress(ctx,'prediction',struct('chain',['prediction-',label]));
  g = LOCAL_transfer(previous.g,sp.s,previous.p,sp.center.wall_y,sp.beta);
  y = ops.wall_chol*g;
  selector = struct('type','transfer','index',NaN,'y',y/norm(y));
  [res,ext] = LOCAL_evaluate(ctx,ops,config.k0,config.mu0, ...
    struct('selector',selector,'extension',true,'want_F',true));
  LOCAL_iteration_row(ctx,['prediction-',label],struct('count',0,'index',res.index),res, ...
    'prediction',false,res.times.total);
  pred.selection = res.selection;
  if res.valid && ~isempty(res.lambda)
    [~,pred.smallest_abs_index] = min(abs(res.lambda));
  end
  if ~res.valid
    pred.status = 'PREDICTION_FAILED';
    pred.reason = sprintf('invalid response at mu0: L[%s] R[%s] C[%s]',res.reason_left, ...
      res.reason_right,res.reason_center);
  elseif isnan(res.index)
    pred.status = 'PREDICTION_FAILED'; pred.reason = ['branch: ',res.selection.reason];
  else
    pred.index = res.index; pred.theta = res.theta;
    mass = LOCAL_masses(config,ops,ext,res,pred.truncation_target);
    pred.mass = rmfield(mass,{'X_left','X_right','G_left','G_right'});
    pred.m_inf = mass.m_inf;
    pred.truncation_cost = mass.truncation_cost;
    pred.truncation_resolved = mass.truncation_cost <= pred.truncation_target;
    pred.delta_mu = res.theta/mass.m_inf;
    pred.mu_N = config.mu0+pred.delta_mu;
    if pred.mu_N > 0
      pred.k_N = sqrt(pred.mu_N); pred.k_N_status = 'OK';
      pred.outside_window = pred.k_N < config.window(1) || pred.k_N > config.window(2);
      if pred.outside_window, pred.k_N_status = 'EXTRAPOLATED_OUTSIDE_WINDOW'; end
    else
      pred.k_N = NaN; pred.k_N_status = 'MU_N_NONPOSITIVE';
    end
    pred.status = 'PREDICTION_SAVED';
    if ~pred.truncation_resolved, pred.status = 'PREDICTION_MASS_UNRESOLVED'; end
    pred.saved_utc = LOCAL_utc(); pred.matlab_elapsed_saved = toc(ctx.started);
    payload = struct('F',ext.center.F,'W',ops.wall_mass,'g',res.g,'theta',res.theta, ...
      'lambda_all',res.lambda,'u_center',ext.center.u,'G_left',mass.G_left,'G_right',mass.G_right, ...
      'X_left',mass.X_left,'X_right',mass.X_right,'P_left',ext.left.Pout,'P_right',ext.right.Pout, ...
      'D_left',ext.left.D,'D_right',ext.right.D,'mass',pred.mass,'k0',config.k0,'mu0',config.mu0);
    save(fullfile(ctx.output_dir,sprintf('prediction-P3-%s.mat',label)),'-struct','payload','-v7');
  end
  if isempty(pred.saved_utc), pred.saved_utc = LOCAL_utc(); pred.matlab_elapsed_saved = toc(ctx.started); end
  pred.seconds = toc(timer);
  % saved before any independent P3 root of this rule
  LOCAL_json(fullfile(ctx.output_dir,sprintf('prediction-P3-%s.json',label)),pred);
  fprintf('PREDICTION %s %s theta=%.6e m_inf=%.6e delta_mu=%.6e mu_N=%.17g\n',label, ...
    pred.status,pred.theta,pred.m_inf,pred.delta_mu,pred.mu_N);
  clear ext
  LOCAL_ledger('add','prediction_mass',toc(timer)-(LOCAL_ledger('total')-inner));
  % --- derivative diagnostic (check rule only), after the prediction is saved ---
  if strcmp(label,'check') && strcmp(pred.status(1:min(10,end)),'PREDICTION')  && ~isnan(pred.m_inf)
    timer = tic; inner = LOCAL_ledger('total');
    pred.derivative_check = LOCAL_derivative_check(ctx,ops,res.g,pred.m_inf);
    pred.derivative_seconds = toc(timer);
    LOCAL_ledger('add','derivative_check',toc(timer)-(LOCAL_ledger('total')-inner));
    LOCAL_json(fullfile(ctx.output_dir,'derivative-check.json'),pred.derivative_check);
  end
end

function check = LOCAL_derivative_check(ctx,ops,g,m_inf)
  % Central difference of g^* F(mu) g at mu0 with the same fixed g, compared
  % with -m_inf; one retry with dmu/2. Implementation diagnostic only.
  config = ctx.config; dmu = config.derivative.dmu;
  check = struct('status','DERIVATIVE_CHECK_FAILED','attempts',struct([]),'m_inf',m_inf, ...
    'rel_tol',config.derivative.rel_tol);
  for attempt = 1:2
    values = zeros(1,2); valid = true;
    for side = [-1,1]
      mu = config.mu0+side*dmu;
      res = LOCAL_evaluate(ctx,ops,sqrt(mu),mu,struct('selector',struct('type','none'), ...
        'extension',false,'want_F',true));
      LOCAL_iteration_row(ctx,'derivative-check',struct('count',attempt,'index',NaN),res, ...
        'derivative',false,res.times.total);
      if ~res.valid, valid = false; break, end
      values((side+3)/2) = real(g'*res.F*g);
    end
    entry = struct('dmu',dmu,'valid',valid,'value_minus',values(1),'value_plus',values(2), ...
      'central_difference',NaN,'relative_difference',NaN);
    if valid
      entry.central_difference = (values(2)-values(1))/(2*dmu);
      entry.relative_difference = abs(entry.central_difference+m_inf)/abs(m_inf);
    end
    check.attempts = LOCAL_append(check.attempts,entry);
    if valid && entry.relative_difference <= config.derivative.rel_tol
      check.status = 'PASS'; break
    end
    dmu = dmu/2;
  end
end

function diag = LOCAL_identity_diagnostic(ctx,ops)
  % Identity of the rebuilt mesh/assembly: nominal-material P2 with the
  % primary (Q12) volume rule evaluated at k0, which was the I9.5b fine-q12
  % root. Recorded only; never a gate or a selection input.
  timer = tic; inner = LOCAL_ledger('total');
  nominal = ops;
  for name = {'left','center','right'}
    nominal.(name{1}).M = nominal.(name{1}).M_nominal;
  end
  nominal = LOCAL_drop_nominal(nominal);
  res = LOCAL_evaluate(ctx,nominal,ctx.config.k0,ctx.config.mu0, ...
    struct('selector',struct('type','smallest'),'extension',false,'want_F',false));
  LOCAL_iteration_row(ctx,'identity-P2-nominal-Q12',struct('count',1,'index',res.index),res, ...
    'identity',false,res.times.total);
  diag = struct('description','nominal material P2, volume Gauss-Duffy 12, at k0', ...
    'valid',res.valid,'theta_smallest',res.theta,'theta_scaled',abs(res.theta)/max(1,res.H_norm), ...
    'gap',res.gap,'center_residual',res.center_residual,'nearest',res.selection);
  fprintf('IDENTITY nominal P2/Q12 at k0: theta=%.3e residual=%.3e\n',res.theta,res.center_residual);
  LOCAL_ledger('add','identity_diagnostic',toc(timer)-(LOCAL_ledger('total')-inner));
end

function ops = LOCAL_drop_nominal(ops)
  for name = {'left','center','right'}
    if isfield(ops.(name{1}),'M_nominal'), ops.(name{1}).M_nominal = []; end
  end
end

%% ==================== Recovery, delivery checks and infinite mass ====================
% Final-rule root: near-wall extensions B, display cells, Stein masses, saved arrays.
function record = LOCAL_recover(ctx,ops,sp,chain)
  config = ctx.config; dl = config.delivery; n = ops.n; mu = chain.mu;
  selector = struct('type','fixed','index',chain.branch_index,'y',[]);
  [res,ext] = LOCAL_evaluate(ctx,ops,chain.k,mu,struct('selector',selector,'extension',true,'want_F',true));
  LOCAL_iteration_row(ctx,[chain.name,'-recovery'],struct('count',chain.frequency_count,'index',res.index), ...
    res,'recovery',false,res.times.total);
  record = struct('pass',false,'failed_gates','','valid',res.valid,'overlap_with_root',NaN, ...
    'theta',res.theta,'center_residual',res.center_residual, ...
    'center_recovery_residual',res.center_recovery_residual,'mass',struct(),'sides',struct([]), ...
    'gates',[],'gate_names',{{}},'center_qp',NaN,'center_mass_normalized',NaN, ...
    'g',[],'wall_l2',NaN,'center_centroid_values',[],'nearest_theta',[],'target_gap',NaN, ...
    'saved_files',{{}},'mass_status','NOT_COMPUTED');
  if ~res.valid
    record.failed_gates = 'recovery response invalid'; return
  end
  record.overlap_with_root = abs(res.y'*chain.y);
  record.nearest_theta = res.selection.nearest_lambda; record.target_gap = res.gap;
  % --- complete infinite mass (centre + Stein masses of both leads) ---
  timer = tic;
  mass = LOCAL_masses(config,ops,ext,res,Inf);
  LOCAL_ledger('add','stein_mass',toc(timer));
  record.mass = rmfield(mass,{'X_left','X_right','G_left','G_right'});
  % --- centre field, QP and centroid samples ---
  c = ops.center; u = ext.center.u; g = res.g;
  full_u = c.Qqp*u;
  record.center_qp = norm(full_u(c.top)-exp(1i*ops.beta)*full_u(c.bottom))/norm(full_u);
  record.g = g; record.wall_l2 = sqrt(real(g'*ops.wall_mass*g));
  record.center_mass_normalized = real(u'*c.M*u);
  Nc = LOCAL_lagrange(sp.p,sp.alpha,[1/3,1/3]);
  record.center_centroid_values = full_u(c.tri_dofs)*Nc.';
  % --- lead display cells, recovery residual, value continuity, weak-load balance ---
  Ac = c.K-mu*c.M; center_load = Ac(c.wall,:)*u;
  sides = struct([]); gl = g(1:n); gr = g(n+1:end);
  for side = {'left','right'}
    name = side{1}; t = ops.(name); L = ext.(name);
    if strcmp(name,'left'), g0 = gl; wall_load = center_load(1:n); x0 = -0.5;
    else, g0 = gr; wall_load = center_load(n+1:end); x0 = 0.5; end
    At = t.K-mu*t.M; S00 = L.S(1:n,1:n); S01 = L.S(1:n,n+1:end);
    S10 = L.S(n+1:end,1:n); S11 = L.S(n+1:end,n+1:end);
    cells = dl.display_cells; traces = zeros(n,cells+1); traces(:,1) = g0;
    for j = 1:cells, traces(:,j+1) = L.Pout*traces(:,j); end
    massj = zeros(1,cells); recovery = zeros(1,cells); balance = zeros(1,cells);
    continuity = zeros(1,cells); qp = 0; fields = cell(1,cells);
    W0 = t.wall(1:n); W1 = t.wall(n+1:end);
    x1 = x0+(2*strcmp(name,'right')-1);
    for j = 1:cells
      v = complex(zeros(numel(t.free),1)); v(W0) = traces(:,j); v(W1) = traces(:,j+1);
      v(t.interior) = L.B*traces(:,j);
      massj(j) = real(v'*t.M*v);
      recovery(j) = norm(At(t.interior,:)*v)/(norm(At(t.interior,t.interior)*v(t.interior))+ ...
        norm(At(t.interior,t.wall)*v(t.wall)));
      fields{j} = t.Qqp*v;
      qp = max(qp,norm(fields{j}(t.top)-exp(1i*ops.beta)*fields{j}(t.bottom))/max(norm(fields{j}),realmin));
      if j == 1
        lead_load = S00*traces(:,1)+S01*traces(:,2);
        balance(j) = norm(wall_load+lead_load)/(norm(wall_load)+norm(lead_load));
        cw = find(abs(c.dof_xy(:,1)-x0)<1e-11); tw = find(abs(t.dof_xy(:,1)-x0)<1e-11);
        [~,a] = sort(c.dof_xy(cw,2)); [~,b] = sort(t.dof_xy(tw,2));
        continuity(j) = norm(full_u(cw(a))-fields{1}(tw(b)))/max(norm(full_u(cw(a))),realmin);
      else
        prev = S10*traces(:,j-1)+S11*traces(:,j); next = S00*traces(:,j)+S01*traces(:,j+1);
        balance(j) = norm(prev+next)/(norm(prev)+norm(next));
        q1 = find(abs(t.dof_xy(:,1)-x1)<1e-11); q0 = find(abs(t.dof_xy(:,1)-x0)<1e-11);
        [~,a] = sort(t.dof_xy(q1,2)); [~,b] = sort(t.dof_xy(q0,2));
        continuity(j) = norm(fields{j-1}(q1(a))-fields{j}(q0(b)))/max(norm(fields{j-1}(q1(a))),realmin);
      end
    end
    wall_norms = zeros(1,cells+1);
    for j = 1:cells+1
      wall_norms(j) = sqrt(real(traces(:,j)'*ops.wall_mass(1:n,1:n)*traces(:,j)));
    end
    item = struct('side',name,'cell_mass',massj,'wall_l2_norms',wall_norms, ...
      'recovery_residual',recovery,'load_balance',balance,'value_continuity',continuity, ...
      'qp_defect',qp,'spectral_radius',max(abs(L.multipliers)), ...
      'multipliers_abs',sort(abs(L.multipliers),'descend').', ...
      'extension_backward',L.extension_backward,'dtn',res.dtn.(name),'cell',res.cell.(name));
    sides = LOCAL_append(sides,item);
  end
  record.sides = sides;
  gates = [res.center_residual<=config.root.center_residual, ...
    res.center_recovery_residual<=dl.recovery_residual, record.center_qp<=dl.qp];
  for j = 1:2
    s = sides(j);
    gates = [gates,max(s.recovery_residual)<=dl.recovery_residual, ...
      max(s.value_continuity)<=dl.continuity,s.qp_defect<=dl.qp, ...
      max(s.load_balance)<=dl.load_balance]; %#ok<AGROW>
  end
  record.gates = gates;
  record.gate_names = {'center_residual','center_recovery','center_qp', ...
    'left_recovery','left_continuity','left_qp','left_balance', ...
    'right_recovery','right_continuity','right_qp','right_balance'};
  overlap_ok = record.overlap_with_root >= config.root.overlap_min;
  % D2 5.1: root/recovery identity only; the complete mass is a prediction /
  % derivative diagnostic and never enters root qualification
  record.pass = all(gates) && overlap_ok;
  bad = record.gate_names(~gates);
  if ~overlap_ok, bad{end+1} = 'overlap_with_root'; end
  record.failed_gates = strjoin(bad,',');
  if ~isfinite(mass.m_inf)
    record.mass_status = 'MASS_NONFINITE';
  elseif mass.m_inf <= 0
    record.mass_status = 'MASS_NONPOSITIVE';
  elseif ~mass.stein_resolved
    record.mass_status = 'STEIN_TAIL_UNRESOLVED';
  else
    record.mass_status = 'STEIN_RESOLVED';
  end
  % --- save recovery representation per template (large arrays to disk) ---
  timer = tic;
  for side = {'left','right'}
    L = ext.(side{1});
    payload = struct('B_interior',L.B,'Pout',L.Pout,'S',L.S,'D',L.D,'multipliers',L.multipliers, ...
      'G',mass.(['G_',side{1}]),'X',mass.(['X_',side{1}]),'k',chain.k,'mu',mu);
    file = sprintf('recovery-P%d-%s-%s.mat',sp.p,ops.rule,side{1});
    save(fullfile(ctx.output_dir,file),'-struct','payload','-v6');
    record.saved_files{end+1} = file;
  end
  payload = struct('u_free',u,'g',g,'F',ext.center.F,'H',ext.center.H,'S',ext.center.S, ...
    'lambda_all',res.lambda,'centroid_values',record.center_centroid_values,'k',chain.k,'mu',mu);
  file = sprintf('recovery-P%d-%s-center.mat',sp.p,ops.rule);
  save(fullfile(ctx.output_dir,file),'-struct','payload','-v6');
  record.saved_files{end+1} = file;
  LOCAL_ledger('add','save',toc(timer));
  fprintf('RECOVERY %s pass=%d mass %s m_inf=%.6e (c %.4e, L %.4e, R %.4e) residual=%.2e\n',chain.name, ...
    record.pass,record.mass_status,mass.m_inf,mass.m_center,mass.m_left,mass.m_right,res.center_residual);
end

function mass = LOCAL_masses(config,ops,ext,res,cost_target)
  % m_inf = u_c^* M_c u_c + g_-^* X^- g_- + g_+^* X^+ g_+ with the Stein
  % solutions X - P^* X P = G by joint doubling (E6) and Frobenius tails (E7):
  %   t_j = a/(1-a) ||X^(j)||_F,  a = ||P^(2^j)||_F^2 < 1,
  % stop when t <= tail_rel*max(||X||_F,1) on both sides and the prediction
  % truncation cost |theta| t_M / m_j^2 <= cost_target (Inf: no cost gate).
  n = ops.n; g = res.g; gl = g(1:n); gr = g(n+1:end); theta = res.theta;
  u = ext.center.u; m_center = real(u'*ops.center.M*u);
  st = config.stein;
  G = {ext.left.G,ext.right.G}; P = {ext.left.Pout,ext.right.Pout};
  X = G; Q = P; tails = [Inf,Inf]; a = [NaN,NaN]; rounds = 0; resolved = false; cost = Inf;
  history = zeros(0,6);
  for round = 0:st.max_rounds
    for s = 1:2
      a(s) = norm(Q{s},'fro')^2;
      if a(s) < 1, tails(s) = a(s)/(1-a(s))*norm(X{s},'fro'); else, tails(s) = Inf; end
    end
    m_j = m_center+real(gl'*X{1}*gl)+real(gr'*X{2}*gr);
    t_M = tails(1)*norm(gl)^2+tails(2)*norm(gr)^2;
    cost = abs(theta)*t_M/m_j^2;
    history(end+1,:) = [round,a,tails,cost]; %#ok<AGROW>
    rel_ok = all(tails <= st.tail_rel*max([norm(X{1},'fro'),norm(X{2},'fro')],1));
    rounds = round;
    if rel_ok && (cost <= cost_target || isinf(cost_target))
      resolved = true; break
    end
    if round == st.max_rounds, break, end
    for s = 1:2
      X{s} = X{s}+Q{s}'*X{s}*Q{s}; Q{s} = Q{s}*Q{s};
    end
  end
  stein_residual = zeros(1,2); herm = zeros(1,2); gmin = zeros(1,2);
  for s = 1:2
    stein_residual(s) = norm(X{s}-P{s}'*X{s}*P{s}-G{s},'fro')/max(norm(G{s},'fro'),realmin);
    herm(s) = norm(X{s}-X{s}','fro')/max(norm(X{s},'fro'),realmin);
    gmin(s) = min(eig((G{s}+G{s}')/2));
  end
  m_left = real(gl'*X{1}*gl); m_right = real(gr'*X{2}*gr);
  mass = struct('m_center',m_center,'m_left',m_left,'m_right',m_right, ...
    'm_inf',m_center+m_left+m_right,'stein_rounds',rounds,'stein_resolved',resolved, ...
    'tail_left',tails(1),'tail_right',tails(2),'a_left',a(1),'a_right',a(2), ...
    'stein_residual_left',stein_residual(1),'stein_residual_right',stein_residual(2), ...
    'X_hermitian_defect',herm,'G_min_eig',gmin,'truncation_cost',cost, ...
    'cost_target',cost_target,'history',history,'g_left_norm2',norm(gl)^2, ...
    'g_right_norm2',norm(gr)^2,'theta',theta, ...
    'X_left',X{1},'X_right',X{2},'G_left',G{1},'G_right',G{2});
end

%% ==================== Geometry: deterministic fine mesh rebuild (from I9.5b) ====================
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

function dxy = LOCAL_curve_derivative(config,cell_index,theta)
  % Analytic d/dtheta of LOCAL_curve (same formulas, CCW orientation).
  theta = theta(:);
  if cell_index == 0
    c = config.model.star_scale*0.2;
    dxy = c*[-1.5*sin(5*theta).*cos(theta)-(1.5+0.3*cos(5*theta)).*sin(theta), ...
      -1.5*sin(5*theta).*sin(theta)+(1+0.3*cos(5*theta)).*cos(theta)];
  else
    a = config.model.a_negative;
    if cell_index>0, a = config.model.a_positive; end
    scale = config.model.radius/sqrt(1+a^2/2);
    r = scale*(1+a*cos(3*theta)); dr = -3*a*scale*sin(3*theta);
    dxy = [dr.*cos(theta)-r.*sin(theta),dr.*sin(theta)+r.*cos(theta)];
  end
end

function [mesh,geometry] = LOCAL_mesh(config)
  % I9.5b design 5 steps 1-3 and 5: clearance deletion, constrained Delaunay
  % with fixed curve/ring/wall nodes, up to 3 deletion rounds, final gates.
  % The D2 flip stage is not copied (the formal fine level needed none); a
  % remaining bad element is GEOMETRY_FAILED.
  cfg = config.mesh; rules = config.mesh_rules; s = cfg.subdivisions;
  ng = cfg.interface_segments; h = 1/s;
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
  rounds = struct('round',{},'deleted',{},'bad_elements',{},'worst_ratio',{},'seconds',{});
  geometry = struct('status','PASS','reason','','failure_kind','NONE', ...
    'initial_clearance_deleted',nnz(clearance & ~fixed),'deletion_outcome','');
  for round = 0:rules.repair_rounds
    timer = tic;
    [mesh,checks] = LOCAL_triangulate(config,cfg,background,deletable,curves,rings,theta);
    bad = LOCAL_bad(checks,rules);
    record = struct('round',round,'deleted',0,'bad_elements',numel(bad), ...
      'worst_ratio',max(checks.det_ratio),'seconds',0);
    if isempty(bad)
      geometry.deletion_outcome = sprintf('no bad elements after %d deletion rounds',round);
      record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
      break
    end
    if round == rules.repair_rounds
      geometry.deletion_outcome = sprintf('%d bad elements after %d deletion rounds',numel(bad),round);
      record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
      break
    end
    vertices = unique(mesh.triangles(bad,:));
    remove = vertices(vertices<=size(background,1));
    remove = remove(deletable(remove));
    if isempty(remove)
      geometry.deletion_outcome = sprintf('%d bad elements without deletable background vertices', ...
        numel(bad));
      record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
      break
    end
    record.deleted = numel(remove);
    keep = true(size(background,1),1); keep(remove) = false;
    background = background(keep,:); deletable = deletable(keep);
    record.seconds = toc(timer); rounds(end+1) = record; %#ok<AGROW>
  end
  geometry.repair_rounds = rounds;
  geometry.bad_elements = numel(bad);
  geometry.checks = rmfield(checks,{'det_min','det_max','det_ratio','quality','min_angle'});
  geometry.det_min = min(checks.det_min); geometry.det_ratio_max = max(checks.det_ratio);
  geometry.curved_elements = nnz(checks.det_ratio>1+1e-12);
  if ~checks.pass
    geometry.status = 'GEOMETRY_FAILED'; geometry.failure_kind = 'STRUCTURAL_CHECK_FAILED';
    geometry.reason = ['structural checks: ',checks.reason];
  elseif ~isempty(bad)
    geometry.status = 'GEOMETRY_FAILED'; geometry.failure_kind = 'JACOBIAN_QUALITY_UNRESOLVED';
    geometry.reason = sprintf('%d bad elements; deletion: %s (no flip stage in I10.1)', ...
      numel(bad),geometry.deletion_outcome);
  end
  mesh.det_min = checks.det_min; mesh.det_ratio = checks.det_ratio;
  mesh.subdivisions = s; mesh.interface_segments = ng; mesh.h = h;
  mesh.curves = curves;
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

function [mesh,checks] = LOCAL_triangulate(config,cfg,background,deletable,curves,rings,theta)
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
  assert(numel(first)==size(points,1),'i101:Duplicate','Mesh input contains duplicate points.');
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
  assert(size(dt.Points,1)==size(points,1),'i101:Steiner','Triangulation inserted points.');
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
  base = struct('points',points,'constraints',constraints,'raw_interfaces',raw_interfaces, ...
    'midpoint_values',midpoint_values,'theta',theta, ...
    'background_points',size(background,1),'deletable_points',nnz(deletable));
  [mesh,checks] = LOCAL_mesh_build(config,cfg,base,triangles,material,cell_id);
end

function [mesh,checks] = LOCAL_mesh_build(config,cfg,base,triangles,material,cell_id)
  % Edges and shared P2 numbering: interface-edge midpoints take the analytic
  % curve values, all other edges the arithmetic midpoint; structural checks
  % and curved Jacobian determinant extrema (I9.5b, unchanged).
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
  outer = @(p)abs(abs(p(:,1))-1.5)<tol | abs(abs(p(:,2))-0.5)<tol;
  single = incidence==1; e1 = points(edges(single,1),:); e2 = points(edges(single,2),:);
  checks.edge_incidence = all(incidence<=2) && all(outer(e1) & outer(e2) & ...
    (abs(e1(:,1)-e2(:,1))<tol | abs(e1(:,2)-e2(:,2))<tol));
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
  det_min = zeros(nt,1); det_max = zeros(nt,1);
  for t = 1:nt
    coefficients = LOCAL_det_coefficients(LOCAL_map_coefficients(p2_points(triangle_p2(t,:),:)));
    [det_min(t),det_max(t)] = LOCAL_quadratic_triangle_extrema(coefficients);
  end
  det_ratio = det_max./det_min; det_ratio(det_min<=0) = Inf;
  P1 = points(triangles(:,1),:); P2 = points(triangles(:,2),:); P3 = points(triangles(:,3),:);
  l1 = sum((P2-P3).^2,2); l2 = sum((P3-P1).^2,2); l3 = sum((P1-P2).^2,2);
  area = abs(orientation)/2;
  quality = 4*sqrt(3)*area./(l1+l2+l3);
  angle = @(opp,u,v)acosd(min(1,max(-1,(u+v-opp)./(2*sqrt(u.*v)))));
  min_angle = min([angle(l1,l2,l3),angle(l2,l3,l1),angle(l3,l1,l2)],[],2);
  top = find(abs(p2_points(:,2)-0.5)<tol); bottom = find(abs(p2_points(:,2)+0.5)<tol);
  checks.top_bottom_pairing = numel(top)==numel(bottom) && ...
    max(abs(sort(p2_points(top,1))-sort(p2_points(bottom,1))))<tol;
  wall_ok = true;
  for w = 1:4
    ids = abs(p2_points(:,1)-(w-2.5))<tol; values = sort(p2_points(ids,2));
    wall_ok = wall_ok && numel(values)==2*cfg.subdivisions+1 && ...
      max(abs(values-(-0.5+(0:2*cfg.subdivisions)'/(2*cfg.subdivisions))))<1e-12;
  end
  checks.wall_translation_pairing = wall_ok;
  checks.vertices = nv; checks.triangles = nt; checks.p2_nodes = size(p2_points,1);
  checks.background_points = base.background_points; checks.deletable_points = base.deletable_points;
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

function identity = LOCAL_mesh_identity(config,mesh)
  % Recorded comparison with the I9.5b run-02 fine level counts (explicit
  % numbers in the config); plus coordinate checksums for the summarizer.
  e = config.expected_mesh;
  identity = struct('triangles',size(mesh.triangles,1),'p2_nodes',size(mesh.p2_points,1), ...
    'vertices',size(mesh.points,1),'expected_triangles',e.triangles, ...
    'expected_p2_nodes',e.p2_nodes,'counts_match',size(mesh.triangles,1)==e.triangles && ...
    size(mesh.p2_points,1)==e.p2_nodes,'material_counts',[nnz(mesh.material==1), ...
    nnz(mesh.material==config.model.rho_center),nnz(mesh.material==config.model.rho_negative)], ...
    'p2_coordinate_sum',sum(mesh.p2_points,1),'p2_coordinate_abs_sum',sum(abs(mesh.p2_points),1), ...
    'det_min',min(mesh.det_min),'det_ratio_max',max(mesh.det_ratio), ...
    'note','free P2 dofs are compared in spaces(1).free_dofs_match');
  if strcmp(config.mode,'smoke'), identity.note = 'smoke mesh: no identity comparison'; end
end

%% ==================== P_p field spaces on the fixed P2 geometry ====================
% Equispaced barycentric Lagrange nodes alpha/p, shared-edge orientation j -> p-j.
function alpha = LOCAL_lattice(p)
  % Local node order: v1 v2 v3, edge12 (p-j,j,0), edge23 (0,p-j,j),
  % edge31 (j,0,p-j) for j = 1..p-1, then interior nodes (P2: I9.5b order).
  j = (1:p-1)'; z = 0*j;
  alpha = [p,0,0;0,p,0;0,0,p;p-j,j,z;z,p-j,j;j,z,p-j];
  for a2 = 1:p-2
    for a3 = 1:p-1-a2
      alpha(end+1,:) = [p-a2-a3,a2,a3]; %#ok<AGROW>
    end
  end
end

function [N,Nxi,Neta] = LOCAL_lagrange(p,alpha,pts)
  % N_alpha(lambda) = prod_i (1/alpha_i!) prod_{j<alpha_i} (p lambda_i - j),
  % lambda = (1-xi-eta, xi, eta); d/dxi = d/dl2 - d/dl1, d/deta = d/dl3 - d/dl1.
  xi = pts(:,1); eta = pts(:,2); L = [1-xi-eta,xi,eta]; np = numel(xi);
  F = cell(p+1,1); dF = cell(p+1,1);
  for m = 0:p
    f = ones(np,3); df = zeros(np,3);
    for j = 0:m-1
      df = df.*(p*L-j)+f*p; f = f.*(p*L-j);
    end
    F{m+1} = f/factorial(m); dF{m+1} = df/factorial(m);
  end
  nb = size(alpha,1); N = zeros(np,nb); Nxi = N; Neta = N;
  for a = 1:nb
    f1 = F{alpha(a,1)+1}(:,1); f2 = F{alpha(a,2)+1}(:,2); f3 = F{alpha(a,3)+1}(:,3);
    d1 = dF{alpha(a,1)+1}(:,1); d2 = dF{alpha(a,2)+1}(:,2); d3 = dF{alpha(a,3)+1}(:,3);
    N(:,a) = f1.*f2.*f3;
    g1 = d1.*f2.*f3;
    Nxi(:,a) = f1.*d2.*f3-g1; Neta(:,a) = f1.*f2.*d3-g1;
  end
end

function sp = LOCAL_space(config,mesh,p)
  % Template dofs: template vertices, then (p-1) nodes per template edge
  % ordered from the smaller global vertex id, then (p-1)(p-2)/2 interior
  % nodes per element. Top (y=+1/2) dofs are QP slaves u_+ = e^{i beta} u_-.
  tol = config.mesh_rules.coordinate_tolerance; beta = config.model.beta*config.model.d;
  s = mesh.subdivisions; n = s*p; alpha = LOCAL_lattice(p); nb = size(alpha,1);
  sp = struct('p',p,'s',s,'n',n,'beta',beta,'alpha',alpha,'nb',nb);
  names = {'left','center','right'}; walls_x = {[-0.5,-1.5],[-0.5,0.5],[0.5,1.5]};
  nv_global = size(mesh.points,1);
  lat = alpha(:,2:3)/p; Ng = zeros(nb,6);
  for a = 1:nb, Ng(a,:) = LOCAL_basis([1-lat(a,1)-lat(a,2),lat(a,1),lat(a,2)]); end
  pairs = [1,2;2,3;3,1]; nint = (p-1)*(p-2)/2;
  for c = -1:1
    ids = find(mesh.cell_id==c); nt = numel(ids);
    tri = mesh.triangles(ids,:); eg = mesh.triangle_p2(ids,4:6)-nv_global;
    [verts,~,vloc] = unique(tri); vloc = reshape(vloc,nt,3); nV = numel(verts);
    [edges,~,eloc] = unique(eg); eloc = reshape(eloc,nt,3); nE = numel(edges);
    tri_dofs = zeros(nt,nb); tri_dofs(:,1:3) = vloc;
    for le = 1:3
      forward = tri(:,pairs(le,1)) < tri(:,pairs(le,2));
      for j = 1:p-1
        jj = j*forward+(p-j)*(~forward);
        tri_dofs(:,3+(le-1)*(p-1)+j) = nV+(eloc(:,le)-1)*(p-1)+jj;
      end
    end
    if nint > 0
      tri_dofs(:,3+3*(p-1)+(1:nint)) = nV+nE*(p-1)+(0:nt-1)'*nint+(1:nint);
    end
    nd = nV+nE*(p-1)+nt*nint;
    X = reshape(mesh.p2_points(mesh.triangle_p2(ids,:),1),nt,6);
    Y = reshape(mesh.p2_points(mesh.triangle_p2(ids,:),2),nt,6);
    PX = X*Ng'; PY = Y*Ng';
    dof_xy = zeros(nd,2); dof_xy(tri_dofs(:),1) = PX(:); dof_xy(tri_dofs(:),2) = PY(:);
    consistency = max([abs(dof_xy(tri_dofs,1)-PX(:));abs(dof_xy(tri_dofs,2)-PY(:))]);
    top = find(abs(dof_xy(:,2)-0.5)<tol); bottom = find(abs(dof_xy(:,2)+0.5)<tol);
    [~,a] = sort(dof_xy(top,1)); top = top(a); [~,a] = sort(dof_xy(bottom,1)); bottom = bottom(a);
    pairing = numel(top)==numel(bottom) && max(abs(dof_xy(top,1)-dof_xy(bottom,1)))<tol;
    assert(pairing,'i101:Pairing','Top/bottom P%d dofs do not pair in cell %d.',p,c);
    master = (1:nd)'; master(top) = bottom; free = setdiff((1:nd)',top);
    [~,col] = ismember(master,free); phase = ones(nd,1); phase(top) = exp(1i*beta);
    Qqp = sparse(1:nd,col,phase,nd,numel(free));
    qp_defect = norm(Qqp(top,:)-exp(1i*beta)*Qqp(bottom,:),'fro');
    fx = dof_xy(free,1); fy = dof_xy(free,2); wall = cell(1,2);
    for w = 1:2
      list = find(abs(fx-walls_x{c+2}(w))<tol); [~,a] = sort(fy(list)); wall{w} = list(a);
    end
    expected = -0.5+(0:n-1)'/n;
    wall_ok = numel(wall{1})==n && numel(wall{2})==n && ...
      max(abs([fy(wall{1});fy(wall{2})]-[expected;expected]))<1e-12;
    W = [wall{1};wall{2}]; I = setdiff((1:numel(free))',W);
    sp.(names{c+2}) = struct('name',names{c+2},'cell',c,'element_ids',ids,'X',X,'Y',Y, ...
      'material',mesh.material(ids),'tri_dofs',tri_dofs,'ndof',nd,'dof_xy',dof_xy, ...
      'Qqp',Qqp,'free',free,'top',top,'bottom',bottom,'wall',W,'interior',I, ...
      'wall_y',expected,'counts',[nV,nE,nt], ...
      'checks',struct('dof_formula',nd==nV+(p-1)*nE+nint*nt,'shared_node_coordinate_defect', ...
      consistency,'top_bottom_pairing',pairing,'qp_defect',qp_defect,'wall_pairing',wall_ok, ...
      'pass',wall_ok && pairing && consistency<1e-12 && qp_defect<=config.gates.qp_defect));
  end
  sp.wall_mass_single = LOCAL_wall_mass(s,p,beta);
end

function checks = LOCAL_basis_checks(orders)
  % Reference-element checks: nodal Kronecker property, partition of unity,
  % gradient sums, degree-p reproduction, analytic vs central-difference
  % derivative and local P_p -> P_{p+1} embedding at interior test points.
  k = (1:64)'; u = mod(k*0.6180339887498949,1); v = mod(k*0.4142135623730951,1);
  flip = u+v>1; u(flip) = 1-u(flip); v(flip) = 1-v(flip);
  pts = 0.02+0.96*[u,v]; pts = pts.*(sum(pts,2)<0.98)+0.49*pts.*(sum(pts,2)>=0.98);
  checks = struct([]);
  for p = orders
    alpha = LOCAL_lattice(p); nb = size(alpha,1);
    Nn = LOCAL_lagrange(p,alpha,alpha(:,2:3)/p);
    [N,Nx,Ne] = LOCAL_lagrange(p,alpha,pts);
    repro = 0;
    for a = 0:p
      for b = 0:p-a
        f = @(x)x(:,1).^a.*x(:,2).^b;
        repro = max(repro,max(abs(N*f(alpha(:,2:3)/p)-f(pts))));
      end
    end
    h = 1e-6;
    Np = LOCAL_lagrange(p,alpha,pts+[h,0]); Nm = LOCAL_lagrange(p,alpha,pts-[h,0]);
    fd = max(max(abs((Np-Nm)/(2*h)-Nx)))/max(max(abs(Nx)));
    embed = NaN;
    if p < max(orders)
      alpha2 = LOCAL_lattice(p+1);
      Jloc = LOCAL_lagrange(p,alpha,alpha2(:,2:3)/(p+1));
      N2 = LOCAL_lagrange(p+1,alpha2,pts);
      embed = max(max(abs(N2*Jloc-N)));
    end
    item = struct('p',p,'local_dofs',nb,'kronecker',max(max(abs(Nn-eye(nb)))), ...
      'partition_of_unity',max(abs(sum(N,2)-1)),'gradient_sum', ...
      max([abs(sum(Nx,2));abs(sum(Ne,2))]),'reproduction',repro, ...
      'derivative_fd_relative',fd,'local_embedding',embed);
    item.pass = item.kronecker<1e-12 && item.partition_of_unity<1e-12 && ...
      item.gradient_sum<1e-10 && item.reproduction<1e-12 && item.derivative_fd_relative<1e-7 && ...
      (isnan(embed) || embed<1e-12);
    checks = LOCAL_append(checks,item);
  end
end

function emb = LOCAL_embedding(config,lo,hi)
  % J maps P_p free (QP-reduced) coefficients to P_{p+1} free coefficients:
  % J_raw = old basis at the new nodes, J_free = J_raw(free_hi,:) Qqp_lo.
  % Checks: shared-node consistency, QP compatibility Qqp_hi J_free = J_raw Qqp_lo,
  % wall-trace embedding against the 1D transfer, and pointwise field identity.
  p = lo.p; q = hi.p; Jloc = LOCAL_lagrange(p,lo.alpha,hi.alpha(:,2:3)/q);
  nbp = lo.nb; nbq = hi.nb;
  ri = repmat((1:nbq)',nbp,1); cj = repelem((1:nbp)',nbq);
  vals = Jloc(sub2ind([nbq,nbp],ri,cj))';
  emb = struct('p_from',p,'p_to',q);
  k = (1:5)'; tp = [mod(k*0.618034,0.5)+0.05,mod(k*0.414214,0.4)+0.05];
  Nlo = LOCAL_lagrange(p,lo.alpha,tp); Nhi = LOCAL_lagrange(q,hi.alpha,tp);
  T1 = zeros(hi.n,lo.n);
  for j = 1:lo.n
    e = zeros(lo.n,1); e(j) = 1; T1(:,j) = LOCAL_wall_eval(e,lo.s,p,lo.beta,hi.center.wall_y);
  end
  T = blkdiag(T1,T1);
  for name = {'left','center','right'}
    a = lo.(name{1}); b = hi.(name{1}); nt = size(a.tri_dofs,1);
    R = b.tri_dofs(:,ri); C = a.tri_dofs(:,cj); V = repmat(vals,nt,1);
    [rc,~,ic] = unique([R(:),C(:)],'rows');
    vmax = accumarray(ic,V(:),[],@max); vmin = accumarray(ic,V(:),[],@min);
    Jraw = sparse(rc(:,1),rc(:,2),vmax,b.ndof,a.ndof);
    J = Jraw(b.free,:)*a.Qqp;
    ref = Jraw*a.Qqp;
    u = cos(0.37*(1:numel(a.free))')+1i*sin(0.73*(1:numel(a.free))');
    ulo = a.Qqp*u; uhi = b.Qqp*(J*u);
    vlo = zeros(nt,size(tp,1)); vhi = vlo;
    for t = 1:size(tp,1)
      vlo(:,t) = ulo(a.tri_dofs)*Nlo(t,:).'; vhi(:,t) = uhi(b.tri_dofs)*Nhi(t,:).';
    end
    emb.(name{1}) = struct('J_free',J);
    emb.checks.(name{1}) = struct('shared_value_spread',full(max(vmax-vmin)), ...
      'qp_compatibility',norm(b.Qqp*J-ref,'fro')/norm(ref,'fro'), ...
      'wall_from_interior',norm(J(b.wall,a.interior),'fro'), ...
      'wall_trace_vs_1d',norm(J(b.wall,a.wall)-T,'fro')/norm(T,'fro'), ...
      'field_identity',max(abs(vlo(:)-vhi(:)))/max(abs(vlo(:))));
    ch = emb.checks.(name{1});
    emb.checks.(name{1}).pass = ch.shared_value_spread<1e-13 && ch.qp_compatibility<1e-13 && ...
      ch.wall_from_interior<1e-13 && ch.wall_trace_vs_1d<1e-13 && ch.field_identity<1e-12;
  end
  emb.checks.pass = emb.checks.left.pass && emb.checks.center.pass && emb.checks.right.pass;
end

function out = LOCAL_edge_traces(config,mesh,spaces)
  % D2 3.2 shared-edge check: on every P2 edge shared by two elements of one
  % template, at edge parameters 0,1/4,1/2,3/4,1 measured from the smaller
  % global vertex, map to each element's own reference coordinates and compare
  % the P2 geometry position and the full global P_p basis rows (p = 2,3,4).
  % A difference above edge_tol is a real structural (DOF/orientation) error.
  tol = config.edge_tol; spar = [0,0.25,0.5,0.75,1]; nsp = numel(spar);
  nv = size(mesh.points,1); pairs = [1,2;2,3;3,1];
  a2 = LOCAL_lattice(2);
  out = struct('parameters',spar,'tolerance',tol,'pass',true,'templates',struct([]));
  for name = {'left','center','right'}
    t2 = spaces{config.orders(1)}.(name{1}); ids = t2.element_ids; nt = numel(ids);
    tri = mesh.triangles(ids,:); eg = mesh.triangle_p2(ids,4:6)-nv;
    list = [eg(:),repmat((1:nt)',3,1),repelem((1:3)',nt)];
    list = sortrows(list,[1,2]); dup = find(list(1:end-1,1)==list(2:end,1));
    A = list(dup,2:3); B = list(dup+1,2:3); ne = numel(dup);
    item = struct('template',name{1},'shared_edges',ne,'geometry_defect',0, ...
      'trace_defect',zeros(1,numel(config.orders)),'pass',true);
    refA = LOCAL_edge_reference(tri,A,pairs,spar); refB = LOCAL_edge_reference(tri,B,pairs,spar);
    rows = repmat((1:ne)',nsp,1); eA = repmat(A(:,1),nsp,1); eB = repmat(B(:,1),nsp,1);
    G = LOCAL_lagrange(2,a2,refA); xA = [sum(t2.X(eA,:).*G,2),sum(t2.Y(eA,:).*G,2)];
    G = LOCAL_lagrange(2,a2,refB); xB = [sum(t2.X(eB,:).*G,2),sum(t2.Y(eB,:).*G,2)];
    item.geometry_defect = max([0;vecnorm(xA-xB,2,2)]);
    for q = 1:numel(config.orders)
      sp = spaces{config.orders(q)}; t = sp.(name{1});
      NA = LOCAL_lagrange(sp.p,sp.alpha,refA); NB = LOCAL_lagrange(sp.p,sp.alpha,refB);
      r = repmat((1:ne*nsp)',1,sp.nb);
      SA = sparse(r(:),reshape(t.tri_dofs(eA,:),[],1),NA(:),ne*nsp,t.ndof);
      SB = sparse(r(:),reshape(t.tri_dofs(eB,:),[],1),NB(:),ne*nsp,t.ndof);
      item.trace_defect(q) = full(max([0;max(abs(SA-SB),[],2)]));
    end
    assert(numel(rows)==ne*nsp);
    item.pass = item.geometry_defect<=tol && all(item.trace_defect<=tol);
    out.pass = out.pass && item.pass;
    out.templates = LOCAL_append(out.templates,item);
  end
end

function ref = LOCAL_edge_reference(tri,side,pairs,spar)
  % Reference (xi,eta) of edge parameter s (from the smaller global vertex)
  % on local edge le: e12 -> (t,0), e23 -> (1-t,t), e31 -> (0,1-t).
  ne = size(side,1); e = side(:,1); le = side(:,2);
  v1 = tri(sub2ind(size(tri),e,pairs(le,1))); v2 = tri(sub2ind(size(tri),e,pairs(le,2)));
  forward = v1<v2; ref = zeros(ne*numel(spar),2);
  for j = 1:numel(spar)
    t = spar(j)*forward+(1-spar(j))*(~forward); xi = zeros(ne,1); eta = xi;
    xi(le==1) = t(le==1); eta(le==1) = 0;
    xi(le==2) = 1-t(le==2); eta(le==2) = t(le==2);
    xi(le==3) = 0; eta(le==3) = 1-t(le==3);
    ref((j-1)*ne+(1:ne),:) = [xi,eta];
  end
end

function summary = LOCAL_space_summary(spaces,embeddings,config)
  summary = struct([]);
  for p = config.orders
    sp = spaces{p}; names = {'left','center','right'};
    dofs = zeros(1,3); free = dofs; interior = dofs; counts = zeros(3,3); pass = true;
    for j = 1:3
      t = sp.(names{j}); dofs(j) = t.ndof; free(j) = numel(t.free);
      interior(j) = numel(t.interior); counts(j,:) = t.counts; pass = pass && t.checks.pass;
    end
    item = struct('p',p,'local_dofs',sp.nb,'dofs',dofs,'free_dofs',free,'wall_dofs',sp.n, ...
      'interior_dofs',interior,'vertices_edges_triangles',counts,'template_checks_pass',pass, ...
      'template_checks',struct('left',sp.left.checks,'center',sp.center.checks, ...
      'right',sp.right.checks),'free_dofs_match',NaN,'embedding_to_next',struct());
    if p == 2 && ~strcmp(config.mode,'smoke')
      item.free_dofs_match = isequal(free,config.expected_mesh.free_dofs_p2);
    end
    if p < max(config.orders) && ~isempty(embeddings{p})
      item.embedding_to_next = embeddings{p}.checks;
    end
    summary = LOCAL_append(summary,item);
  end
end

%% ==================== 1D wall traces: mass, evaluation and transfer ====================
% Physical 1D P_p wall traces on s*p uniform nodes with the quasi-periodic closure.
function W = LOCAL_wall_mass(s,p,beta)
  % Exact 1D P_p mass (p+2 Gauss points per segment), then the QP closure.
  n = s*p; h = 1/s; [x,w] = LOCAL_gauss1d(p+2);
  B = LOCAL_lagrange_1d(p,x); local = h*(B'*(w.*B));
  rows = zeros((p+1)^2*s,1); cols = rows; values = rows; q = 0;
  for m = 0:s-1
    ids = m*p+(0:p)+1;
    for a = 1:p+1
      for b = 1:p+1
        q = q+1; rows(q) = ids(a); cols(q) = ids(b); values(q) = local(a,b);
      end
    end
  end
  Mfull = sparse(rows,cols,values,n+1,n+1);
  Qw = sparse([1:n,n+1],[1:n,1],[ones(1,n),exp(1i*beta)],n+1,n);
  W = full(Qw'*Mfull*Qw); W = (W+W')/2;
end

function B = LOCAL_lagrange_1d(p,t)
  t = t(:); nodes = (0:p)/p; B = ones(numel(t),p+1);
  for j = 1:p+1
    for m = 1:p+1
      if m ~= j, B(:,j) = B(:,j).*(t-nodes(m))/(nodes(j)-nodes(m)); end
    end
  end
end

function [x,w] = LOCAL_gauss1d(m)
  j = (1:m-1)'; b = j./sqrt(4*j.^2-1); [V,D] = eig(diag(b,1)+diag(b,-1));
  [x,idx] = sort(diag(D)); w = V(1,idx)'.^2; x = (x+1)/2;
end

function values = LOCAL_wall_eval(g,s,p,beta,yq)
  n = s*p; yq = yq(:); assert(numel(g)==n,'i101:Wall','Wall trace length mismatch.');
  m = max(min(floor((yq+0.5)*s),s-1),0); t = (yq+0.5)*s-m;
  ext = [g(:);exp(1i*beta)*g(1)]; B = LOCAL_lagrange_1d(p,t);
  values = zeros(numel(yq),1);
  for j = 0:p, values = values+ext(m*p+j+1).*B(:,j+1); end
end

function g = LOCAL_transfer(g_parent,s,p_parent,y_target,beta)
  n = numel(g_parent)/2; nt = numel(y_target); g = zeros(2*nt,1);
  for w = 1:2
    g((w-1)*nt+(1:nt)) = LOCAL_wall_eval(g_parent((w-1)*n+(1:n)),s,p_parent,beta,y_target);
  end
end

%% ==================== Oriented thin band: points and location ====================
% H = gamma_h + tau (gamma - gamma_h) on each CCW interface segment, every point
% located in the curved FE mesh (owners -> vertex neighbours -> Bernstein AABB).
function band = LOCAL_band_locate(config,mesh,rule,spaces)
  loc = config.location; ng = mesh.interface_segments; dtheta = 2*pi/ng;
  timer = tic;
  [tg,tw] = LOCAL_gauss1d(rule.band_points); m = rule.band_subsegments;
  t = reshape(tg+(0:m-1),[],1)/m; wt = repmat(tw,m,1)/m;     % t in [0,1], equal subsegments
  [T,TAU] = ndgrid(t,tg); [WT,WTAU] = ndgrid(wt,tw);
  T = T(:)'; TAU = TAU(:)'; WQ = WT(:)'.*WTAU(:)'; nps = numel(T);
  % element geometry: P2 map coefficients, scales, adjacency and AABB
  nt = size(mesh.triangles,1); nv = size(mesh.points,1);
  nodes = cell(1,6);
  for a = 1:6, nodes{a} = mesh.p2_points(mesh.triangle_p2(:,a),:); end
  Cx = LOCAL_map_rows(nodes,1); Cy = LOCAL_map_rows(nodes,2);
  V = mesh.points;
  scale = max([vecnorm(V(mesh.triangles(:,1),:)-V(mesh.triangles(:,2),:),2,2), ...
    vecnorm(V(mesh.triangles(:,2),:)-V(mesh.triangles(:,3),:),2,2), ...
    vecnorm(V(mesh.triangles(:,3),:)-V(mesh.triangles(:,1),:),2,2)],[],2);
  control = [nodes{1};nodes{2};nodes{3};2*nodes{4}-(nodes{1}+nodes{2})/2; ...
    2*nodes{5}-(nodes{2}+nodes{3})/2;2*nodes{6}-(nodes{3}+nodes{1})/2];
  cx = reshape(control(:,1),nt,6); cy = reshape(control(:,2),nt,6);
  box = [min(cx,[],2)-loc.aabb_pad,max(cx,[],2)+loc.aabb_pad, ...
    min(cy,[],2)-loc.aabb_pad,max(cy,[],2)+loc.aabb_pad];
  edge_of_tri = mesh.triangle_p2(:,4:6)-nv;
  E2T = sparse(edge_of_tri(:),repmat((1:nt)',3,1),1,size(mesh.edges,1),nt);
  V2T = sparse(mesh.triangles(:),repmat((1:nt)',3,1),1,nv,nt);
  names = {'left','center','right'}; rho = [config.model.rho_negative,config.model.rho_center, ...
    config.model.rho_positive];
  band = struct('rule',rule.name,'points_per_segment',nps,'total_points',0,'total_failures',0, ...
    'total_dual',0,'total_tolerance_owner',0,'seconds',0,'failures',struct([]));
  for c = -1:1
    name = names{c+2}; seg = (c+1)*ng+(1:ng)';
    theta0 = mesh.interface_theta(seg); theta1 = theta0([2:end,1]);
    P0 = LOCAL_curve(config,c,theta0); Pm = LOCAL_curve(config,c,theta0+pi/ng);
    P1 = LOCAL_curve(config,c,theta1);
    th = theta0+dtheta*T;                                     % ng x nps
    G = LOCAL_curve(config,c,th(:)); dG = dtheta*LOCAL_curve_derivative(config,c,th(:));
    t1 = repmat(T,ng,1); t1 = t1(:); tau = repmat(TAU,ng,1); tau = tau(:);
    sid = repmat((1:ng)',1,nps); sid = sid(:);
    b0 = (1-t1).*(1-2*t1); bm = 4*t1.*(1-t1); b1 = t1.*(2*t1-1);
    Gh = P0(sid,:).*b0+Pm(sid,:).*bm+P1(sid,:).*b1;
    dGh = P0(sid,:).*(4*t1-3)+Pm(sid,:).*(4-8*t1)+P1(sid,:).*(4*t1-1);
    Htau = G-Gh; Ht = dGh+tau.*(dG-dGh); H = Gh+tau.*Htau;
    JH = Htau(:,1).*Ht(:,2)-Htau(:,2).*Ht(:,1);              % signed, never abs
    weight = repmat(WQ,ng,1); weight = weight(:).*JH;
    np = size(H,1);
    % --- D2 owner state: lexicographic (-b_K, r_K/h_K, global element id) ---
    S = LOCAL_owner_init(np);
    owners = zeros(ng,2);
    for j = 1:ng, owners(j,:) = find(E2T(mesh.interface_edges(seg(j)),:)); end
    % --- stage A: the two owners of the interface edge ---
    S = LOCAL_try(config,spaces,Cx,Cy,scale,H,(1:np)',owners(sid,:),S,1);
    % --- stage B: vertex neighbours, once, for points without owner or with best b_K < 0 ---
    todo = find(S.element==0 | S.b<0); neighbours = cell(ng,1);
    for j = unique(sid(todo))'
      list = find(any(V2T(mesh.triangles(owners(j,:),:),:),1));
      neighbours{j} = setdiff(list,owners(j,:));
    end
    if ~isempty(todo)
      S = LOCAL_try(config,spaces,Cx,Cy,scale,H,todo,LOCAL_pad(neighbours(sid(todo))),S,2);
    end
    % --- stage C: Bernstein-box candidates not tried before, once ---
    todo = find(S.element==0 | S.b<0);
    if ~isempty(todo)
      lists = cell(numel(todo),1);
      for i = 1:numel(todo)
        x = H(todo(i),:); j = sid(todo(i));
        list = find(box(:,1)<=x(1) & box(:,2)>=x(1) & box(:,3)<=x(2) & box(:,4)>=x(2))';
        lists{i} = setdiff(list,[owners(j,:),neighbours{j}]);
      end
      S = LOCAL_try(config,spaces,Cx,Cy,scale,H,todo,LOCAL_pad(lists),S,3);
    end
    element = S.element; xi = S.xi; eta = S.eta;
    failed = find(element==0);
    for i = failed'
      band.failures = LOCAL_append(band.failures,struct('cell',c,'segment',sid(i), ...
        't',t1(i),'tau',tau(i),'x',H(i,1),'y',H(i,2), ...
        'reason','POINT_LOCATION_FAILED: NO_ACCEPTED_INVERSE'));
    end
    % up to 20 largest recorded dual differences (diagnostic only, never a veto)
    dual = S.nacc>1; dlist = find(dual & ~isnan(S.defect));
    [~,o] = sort(S.defect(dlist),'descend'); dlist = dlist(o(1:min(20,end)));
    samples = struct([]);
    for i = dlist'
      samples = LOCAL_append(samples,struct('point',i,'segment',sid(i),'t',t1(i),'tau',tau(i), ...
        'x',H(i,1),'y',H(i,2),'weight',weight(i),'defect',S.defect(i), ...
        'owner_element',S.element(i),'owner_b',S.b(i),'owner_r_over_h',S.rh(i), ...
        'alt_element',S.alt_element(i),'alt_b',S.alt_b(i),'alt_r_over_h',S.alt_rh(i)));
    end
    % template-local element index (same element_ids for every order)
    local = zeros(nt,1); ids = spaces{config.orders(1)}.(name).element_ids;
    local(ids) = 1:numel(ids);
    in_cell = element>0; wrong_cell = nnz(in_cell & local(max(element,1))==0);
    template_element = zeros(np,1); template_element(in_cell) = local(element(in_cell));
    band.(name) = struct('element',template_element,'xi',xi,'eta',eta,'weight',weight, ...
      'rho_minus_one',rho(c+2)-1,'signed_area',sum(weight),'points',np, ...
      'failures',numel(failed),'dual',nnz(dual),'tolerance_owner',nnz(element>0 & S.b<0), ...
      'dual_defect_max',max([0;S.defect(dual & ~isnan(S.defect))]), ...
      'owner_r_over_h_max',max([0;S.rh(element>0)]),'owner_b_min',min([Inf;S.b(element>0)]), ...
      'dual_samples',samples, ...
      'wrong_cell',wrong_cell,'stage_counts',[nnz(S.stage==1),nnz(S.stage==2),nnz(S.stage==3)], ...
      'negative_J',nnz(JH<0),'J_min',min(JH),'J_max',max(JH), ...
      'max_offset',max(vecnorm(Htau,2,2)));
    band.total_points = band.total_points+np; band.total_failures = band.total_failures+numel(failed);
    band.total_dual = band.total_dual+nnz(dual);
    band.total_tolerance_owner = band.total_tolerance_owner+nnz(element>0 & S.b<0);
    if wrong_cell > 0
      band.total_failures = band.total_failures+wrong_cell;
      band.(name).element(template_element==0 & in_cell) = 0;
    end
  end
  band.seconds = toc(timer);
end

function C = LOCAL_map_rows(nodes,k)
  % Rows of P2 map coefficients c1..c6 (I9.5b LOCAL_map_coefficients), coordinate k.
  n = cellfun(@(v)v(:,k),nodes,'UniformOutput',false);
  C = [n{1},-3*n{1}-n{2}+4*n{4},-3*n{1}-n{3}+4*n{6},2*n{1}+2*n{2}-4*n{4}, ...
    4*n{1}-4*n{4}+4*n{5}-4*n{6},2*n{1}+2*n{3}-4*n{6}];
end

function S = LOCAL_owner_init(np)
  S = struct('element',zeros(np,1),'xi',NaN(np,1),'eta',NaN(np,1),'b',-Inf(np,1), ...
    'rh',Inf(np,1),'stage',zeros(np,1),'nacc',zeros(np,1),'defect',NaN(np,1), ...
    'alt_element',zeros(np,1),'alt_b',NaN(np,1),'alt_rh',NaN(np,1));
end

function cand = LOCAL_pad(lists)
  width = max(1,max(cellfun(@numel,lists))); cand = zeros(numel(lists),width);
  for i = 1:numel(lists), cand(i,1:numel(lists{i})) = lists{i}; end
end

function S = LOCAL_try(config,spaces,Cx,Cy,scale,H,points,cand,S,stage_id)
  % Inverse-map every (point, candidate) pair inside the acceptance window
  % r_K/h_K <= 1e-12, b_K >= -1e-10 and keep one owner per point by the D2
  % lexicographic order (-b_K, r_K/h_K, global element id), merged with an
  % owner from an earlier stage. Several accepted inverses are a recorded
  % dual: the largest global-basis difference (all orders) to the owner is
  % stored as a diagnostic only; it never clears the owner.
  loc = config.location; nc = size(cand,2);
  P = repelem(points,nc); E = reshape(cand',[],1); keep = E>0; P = P(keep); E = E(keep);
  if isempty(P), return, end
  [s,r,ok,bmin] = LOCAL_inverse_map(Cx(E,:),Cy(E,:),H(P,:),scale(E),loc);
  rh = r./scale(E); acc = find(ok);
  if isempty(acc), return, end
  [~,order] = sortrows([P(acc),-bmin(acc),rh(acc),E(acc)]); acc = acc(order);
  starts = find([true;diff(P(acc))~=0]); lengths = diff([starts;numel(acc)+1]);
  best = acc(starts); k = P(best); had = S.element(k)>0;
  % single new acceptance and no earlier owner: assign directly
  direct = ~had & lengths==1; kd = k(direct); bd = best(direct);
  S.element(kd) = E(bd); S.xi(kd) = s(bd,1); S.eta(kd) = s(bd,2); S.b(kd) = bmin(bd);
  S.rh(kd) = rh(bd); S.stage(kd) = stage_id; S.nacc(kd) = 1;
  % several acceptances (this stage and/or an earlier owner): order, assign, record
  for j = find(~direct)'
    rows = acc(starts(j)+(0:lengths(j)-1)); kk = P(rows(1));
    el = E(rows); ss = s(rows,:); bs = bmin(rows); rs = rh(rows); st = repmat(stage_id,numel(rows),1);
    if S.element(kk)>0
      el = [S.element(kk);el]; ss = [S.xi(kk),S.eta(kk);ss]; bs = [S.b(kk);bs]; %#ok<AGROW>
      rs = [S.rh(kk);rs]; st = [S.stage(kk);st]; %#ok<AGROW>
    end
    [~,o] = sortrows([-bs,rs,el]); el = el(o); ss = ss(o,:); bs = bs(o); rs = rs(o); st = st(o);
    S.element(kk) = el(1); S.xi(kk) = ss(1,1); S.eta(kk) = ss(1,2); S.b(kk) = bs(1);
    S.rh(kk) = rs(1); S.stage(kk) = st(1); S.nacc(kk) = S.nacc(kk)+numel(rows);
    if numel(el)>1
      d = LOCAL_dual_mismatch(config,spaces,el,ss);
      S.defect(kk) = max([S.defect(kk),d],[],'omitnan');
      S.alt_element(kk) = el(2); S.alt_b(kk) = bs(2); S.alt_rh(kk) = rs(2);
    end
  end
end

function [s,r,ok,bmin] = LOCAL_inverse_map(Cx,Cy,X,scale,loc)
  % Newton with backtracking for the P2 map F(xi,eta) = X: at most
  % newton_steps steps, at most `halvings` step halvings per step.
  n = size(X,1); s = ones(n,2)/3;
  f = @(C,s)C(:,1)+C(:,2).*s(:,1)+C(:,3).*s(:,2)+C(:,4).*s(:,1).^2+ ...
    C(:,5).*s(:,1).*s(:,2)+C(:,6).*s(:,2).^2;
  rx = f(Cx,s)-X(:,1); ry = f(Cy,s)-X(:,2); r = hypot(rx,ry);
  active = r > 1e-3*loc.residual*scale;
  for step = 1:loc.newton_steps
    A = find(active);
    if isempty(A), break, end
    a = s(A,:); cx = Cx(A,:); cy = Cy(A,:);
    j11 = cx(:,2)+2*cx(:,4).*a(:,1)+cx(:,5).*a(:,2); j12 = cx(:,3)+cx(:,5).*a(:,1)+2*cx(:,6).*a(:,2);
    j21 = cy(:,2)+2*cy(:,4).*a(:,1)+cy(:,5).*a(:,2); j22 = cy(:,3)+cy(:,5).*a(:,1)+2*cy(:,6).*a(:,2);
    d = j11.*j22-j12.*j21;
    ds = -[(j22.*rx(A)-j12.*ry(A))./d,(-j21.*rx(A)+j11.*ry(A))./d];
    lam = ones(numel(A),1); done = false(numel(A),1);
    trial = a; trx = rx(A); try_ = ry(A); tr = r(A);
    for h = 0:loc.halvings
      J = find(~done);
      if isempty(J), break, end
      cand = a(J,:)+lam(J).*ds(J,:);
      cr_x = f(cx(J,:),cand)-X(A(J),1); cr_y = f(cy(J,:),cand)-X(A(J),2); cr = hypot(cr_x,cr_y);
      good = isfinite(cr) & cr < r(A(J));
      trial(J(good),:) = cand(good,:); trx(J(good)) = cr_x(good); try_(J(good)) = cr_y(good);
      tr(J(good)) = cr(good); done(J(good)) = true; lam(J(~good)) = lam(J(~good))/2;
    end
    s(A,:) = trial; rx(A) = trx; ry(A) = try_; r(A) = tr;
    active(A(~done)) = false;                                   % stalled
    active(A) = active(A) & r(A) > 1e-3*loc.residual*scale(A);
    if any(~isfinite(d)), active(A(~isfinite(d))) = false; end
  end
  bmin = min([1-s(:,1)-s(:,2),s],[],2);
  ok = r <= loc.residual*scale & bmin >= loc.barycentric_min;
end

function defect = LOCAL_dual_mismatch(config,spaces,elements,s)
  % Diagnostic only (D2): largest difference of the global basis values
  % reached from the owner and the other accepted inverses (all orders); Inf
  % if the candidates belong to different templates. Never a veto.
  defect = 0;
  for p = config.orders
    sp = spaces{p};
    for name = {'left','center','right'}
      t = sp.(name{1}); [in,local] = ismember(elements,t.element_ids);
      if ~all(in)
        if any(in), defect = Inf; return, end
        continue
      end
      N = LOCAL_lagrange(p,sp.alpha,s);
      base = sparse(1,t.tri_dofs(local(1),:),N(1,:),1,t.ndof);
      for j = 2:numel(elements)
        other = sparse(1,t.tri_dofs(local(j),:),N(j,:),1,t.ndof);
        defect = max(defect,full(max(abs(base-other))));
      end
    end
  end
end

%% ==================== Volume and band assembly, operators and nested checks ====================
% K, M_{p,h} by Gauss-Duffy; dM_p by the oriented band; Qqp constraint; checks.
function [K,M,area,inclusion_area] = LOCAL_assemble_p(t,p,alpha,order)
  nt = size(t.tri_dofs,1); nb = size(alpha,1); X = t.X; Y = t.Y; material = t.material;
  [lambda,weights] = LOCAL_quadrature(order);
  [Nq,Nxq,Neq] = LOCAL_lagrange(p,alpha,lambda(:,2:3));
  ia = repmat(1:nb,1,nb); ib = repelem(1:nb,nb);
  kval = zeros(nt,nb*nb); mval = kval; areas = zeros(nt,1);
  for q = 1:numel(weights)
    [~,G] = LOCAL_basis(lambda(q,:));
    j11 = X*G(1,:)'; j12 = X*G(2,:)'; j21 = Y*G(1,:)'; j22 = Y*G(2,:)';
    d = j11.*j22-j12.*j21; w = weights(q)*d;
    dx = (j22.*Nxq(q,:)-j21.*Neq(q,:))./d; dy = (-j12.*Nxq(q,:)+j11.*Neq(q,:))./d;
    wdx = w.*dx; wdy = w.*dy;
    kval = kval+wdx(:,ia).*dx(:,ib)+wdy(:,ia).*dy(:,ib);
    mval = mval+(material.*w).*(Nq(q,ia).*Nq(q,ib));
    areas = areas+w;
  end
  rows = t.tri_dofs(:,ia); cols = t.tri_dofs(:,ib);
  K = sparse(rows(:),cols(:),kval(:),t.ndof,t.ndof);
  M = sparse(rows(:),cols(:),mval(:),t.ndof,t.ndof);
  area = sum(areas); inclusion_area = sum(areas(material~=1));
end

function dM = LOCAL_band_matrix(t,b,p,alpha,batch)
  % dM = (rho_in-1) sum_points w J_H Psi(H) Psi(H)^T, at most nb^2 local
  % entries per point, accumulated in batches (no dense dof x point array).
  nb = size(alpha,1); ia = repmat((1:nb)',nb,1); ib = repelem((1:nb)',nb);
  dM = sparse(t.ndof,t.ndof); n = numel(b.xi);
  for j = 1:batch:n
    J = j:min(j+batch-1,n);
    N = LOCAL_lagrange(p,alpha,[b.xi(J),b.eta(J)]);
    dofs = t.tri_dofs(b.element(J),:);
    vals = (b.rho_minus_one*b.weight(J)).*N(:,ia).*N(:,ib);
    rows = dofs(:,ia); cols = dofs(:,ib);
    dM = dM+sparse(rows(:),cols(:),vals(:),t.ndof,t.ndof);
  end
end

function ops = LOCAL_operators(ctx,sp,band,rule,want_raw,want_nominal)
  config = ctx.config; p = sp.p; names = {'left','center','right'};
  LOCAL_progress(ctx,'assembly',struct('p',p,'rule',rule.name));
  ops = struct('p',p,'rule',rule.name,'n',sp.n,'beta',sp.beta,'raw',[]);
  checks = struct('pass',true,'reason','','rule',rule.name,'p',p,'seconds_volume',0, ...
    'seconds_band',0,'seconds_checks',0);
  exact = LOCAL_exact_areas(config);
  rho = [config.model.rho_negative,config.model.rho_center,config.model.rho_positive];
  for j = 1:3
    name = names{j}; t = sp.(name); nt = size(t.tri_dofs,1);
    LOCAL_memory_gate(config,['assembly ',name],8*nt*sp.nb^2*10);
    timer = tic;
    [Kf,Mhf,area,inclusion] = LOCAL_assemble_p(t,p,sp.alpha,rule.volume_order);
    dt = toc(timer); checks.seconds_volume = checks.seconds_volume+dt;
    LOCAL_ledger('add',['assembly_volume_',rule.name],dt);
    timer = tic;
    dMf = LOCAL_band_matrix(t,band.(name),p,sp.alpha,config.location.batch);
    dt = toc(timer); checks.seconds_band = checks.seconds_band+dt;
    LOCAL_ledger('add',['assembly_band_',rule.name],dt);
    timer = tic;
    constant = full(sum(dMf(:))); expected = (rho(j)-1)*(exact(j)-inclusion);
    Q = t.Qqp;
    Kraw = Q'*Kf*Q; Mhraw = Q'*Mhf*Q; dMraw = Q'*dMf*Q;
    herm = @(A)norm(A-A','fro')/max(norm(A,'fro'),realmin);
    kdef = herm(Kraw); mdef = herm(Mhraw); ddef = herm(dMraw);
    K = (Kraw+Kraw')/2; Mh = (Mhraw+Mhraw')/2; dM = (dMraw+dMraw')/2; M = Mh+dM;
    order = symamd(M); [~,mflag] = chol(M(order,order));
    I = t.interior;
    pattern = spones(K(I,I))+spones(M(I,I));
    tmpl = struct('name',name,'K',K,'M',M,'wall',t.wall,'interior',I,'free',t.free, ...
      'Qqp',Q,'top',t.top,'bottom',t.bottom,'tri_dofs',t.tri_dofs,'dof_xy',t.dof_xy, ...
      'amd',amd(pattern),'symbolic_nnz',NaN,'M_nominal',[]);
    tmpl.symbolic_nnz = sum(symbfact(pattern(tmpl.amd,tmpl.amd)));
    if want_nominal, tmpl.M_nominal = Mh; end
    if want_raw
      ops.raw.(name) = struct('K_full',Kf,'M_h_full',Mhf,'dM_full',dMf);
    end
    ops.(name) = tmpl;
    check = struct('area',area,'area_defect',abs(area-1),'inclusion_area_h',inclusion, ...
      'inclusion_area_exact',exact(j),'inclusion_area_defect',inclusion-exact(j), ...
      'band_constant',constant,'band_constant_expected',expected, ...
      'band_constant_defect',constant-expected,'band_signed_area',band.(name).signed_area, ...
      'dM_fro',norm(dM,'fro'),'dM_relative_to_Mh',norm(dM,'fro')/norm(Mh,'fro'), ...
      'stiffness_hermitian_defect',kdef,'mass_h_hermitian_defect',mdef, ...
      'band_hermitian_defect',ddef,'mass_chol_flag',mflag,'nnz_K',nnz(K), ...
      'free_dofs',numel(t.free),'interior_dofs',numel(I),'symbolic_chol_nnz',tmpl.symbolic_nnz);
    pass = kdef<=config.gates.matrix_hermitian && mdef<=config.gates.matrix_hermitian && ...
      ddef<=config.gates.matrix_hermitian && mflag==0 && abs(area-1)<1e-10;
    check.pass = pass; checks.(name) = check;
    if ~pass, checks.pass = false; checks.reason = [checks.reason,name,' matrix check failed; ']; end
    checks.seconds_checks = checks.seconds_checks+toc(timer);
    LOCAL_ledger('add',['assembly_checks_',rule.name],toc(timer));
    clear Kf Mhf dMf Kraw Mhraw dMraw
  end
  ops.wall_mass = blkdiag(sp.wall_mass_single,sp.wall_mass_single);
  ops.wall_chol = chol(ops.wall_mass);
  checks.wall_mass_hermitian_defect = norm(sp.wall_mass_single-sp.wall_mass_single','fro');
  ops.checks = checks;
  fprintf('STAGE assembly P%d %s: volume %.2fs band %.2fs checks %.2fs pass %d\n',p,rule.name, ...
    checks.seconds_volume,checks.seconds_band,checks.seconds_checks,checks.pass);
  if ~checks.pass && ~strcmp(ctx.config.mode,'sizing')
    error('i101:MatrixCheck','P%d %s matrix checks failed: %s',p,rule.name,checks.reason);
  end
end

function input = LOCAL_nested_input(ops)
  input = struct();
  for name = {'left','center','right'}
    input.(name{1}) = struct('K',ops.(name{1}).K,'M',ops.(name{1}).M);
  end
end

function nested = LOCAL_nested(config,lower,upper,embedding)
  % ||J^* A_{p+1} J - A_p||_F / ||A_p||_F for A = K and true-material M,
  % both assembled with the check rule.
  nested = struct('pass',true,'tolerance',config.nested_tol);
  for name = {'left','center','right'}
    J = embedding.(name{1}).J_free; a = lower.(name{1}); b = upper.(name{1});
    k = norm(J'*b.K*J-a.K,'fro')/norm(a.K,'fro');
    m = norm(J'*b.M*J-a.M,'fro')/norm(a.M,'fro');
    nested.(name{1}) = struct('K_relative',k,'M_relative',m);
    nested.pass = nested.pass && k<=config.nested_tol && m<=config.nested_tol;
  end
  fprintf('NESTED P%d->P%d pass %d\n',embedding.p_from,embedding.p_to,nested.pass);
end

function LOCAL_save_raw(ctx,ops,label)
  % Final-rule matrices per template: unconstrained real K, M_{p,h}, dM_p and Qqp.
  timer = tic; payload = struct('p',ops.p,'rule',ops.rule,'label',label);
  for name = {'left','center','right'}
    r = ops.raw.(name{1}); t = ops.(name{1});
    payload.(name{1}) = struct('K_full',r.K_full,'M_h_full',r.M_h_full,'dM_full',r.dM_full, ...
      'Qqp',t.Qqp,'free',t.free,'wall',t.wall,'interior',t.interior);
  end
  save(fullfile(ctx.output_dir,sprintf('layer-P%d-%s-matrices.mat',ops.p,label)), ...
    '-struct','payload','-v6');
  LOCAL_ledger('add','save',toc(timer));
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

%% ==================== Cell elimination, discrete DtN and near-wall extension ====================
% Weak outward wall load S = A_WW + A_WI A_II^{-1}(-A_IW), assembled in 32-column
% blocks without storing the full extension E; ordered complex QZ stable subspace.
function [S,info,fac] = LOCAL_eliminate(config,t,mu,method)
  A = t.K-mu*t.M; I = t.interior; W = t.wall;
  AII = A(I,I); AIW = A(I,W); AWI = A(W,I); nI = numel(I); nW = numel(W);
  info = struct('valid',true,'reason','','method',method,'backward',NaN,'backward_num',NaN, ...
    'backward_den',NaN,'condest',NaN,'chol_flag',NaN);
  fac = struct('apply',[]); S = [];
  rs = full(sum(abs(AII),2));
  if any(rs==0), info.valid = false; info.reason = 'ZERO_ROW'; return, end
  T = spdiags(1./sqrt(rs),0,nI,nI); B = T*AII*T;
  try
    if strcmp(method,'chol')
      p = t.amd; [Rc,flag] = chol(B(p,p)); info.chol_flag = flag;
      if flag ~= 0, info.valid = false; info.reason = 'CENTER_CHOLESKY_FAILED'; return, end
      solve = @(c)LOCAL_chol_solve(Rc,p,c); solve_h = solve;
    else
      [L,U,P,Q,R] = lu(B);
      solve = @(c)Q*(U\(L\(P*(R\c))));
      solve_h = @(c)R\(P'*(L'\(U'\(Q'*c))));
    end
  catch error_object
    info.valid = false; info.reason = ['FACTORIZATION_EXCEPTION: ',error_object.message]; return
  end
  apply = @(rhs)T*solve(T*rhs);
  block = config.solver.rhs_block; S = full(A(W,W));
  norm_A = norm(AII,1); worst = 0; worst_num = 0; worst_den = 1;
  for j = 1:block:nW
    J = j:min(j+block-1,nW);
    rhs = full(-AIW(:,J)); X = apply(rhs);
    r = AII*X-rhs;
    num = sum(abs(r),1); den = norm_A*sum(abs(X),1)+sum(abs(rhs),1);
    [value,at] = max(num./max(den,realmin));
    if value>worst, worst = value; worst_num = num(at); worst_den = den(at); end
    S(:,J) = S(:,J)+AWI*X;
  end
  info.backward = worst; info.backward_num = worst_num; info.backward_den = worst_den;
  afun = @(flag,X)LOCAL_normest_handle(flag,X,nI,solve,solve_h);
  info.condest = norm(B,1)*normest1(afun);
  if ~(info.backward<=config.gates.cell_backward)
    info.valid = false; info.reason = sprintf('CELL_BACKWARD %.3e',info.backward);
  elseif ~(info.condest<=config.gates.cell_condest)
    info.valid = false; info.reason = sprintf('CELL_CONDEST %.3e',info.condest);
  end
  fac = struct('apply',apply,'AII',AII,'norm_A',norm_A);
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

function [D,Pout,info] = LOCAL_dtn(config,S,n)
  % Copied from I9.5b: ordered complex QZ, Pout = Z1/Z0, D = S00 + S01 Pout.
  g = config.gates;
  S00 = S(1:n,1:n); S01 = S(1:n,n+1:end); S10 = S(n+1:end,1:n); S11 = S(n+1:end,n+1:end);
  Acal = [-(S11+S00),-S10;eye(n),zeros(n)]; Bcal = [S01,zeros(n);zeros(n),eye(n)];
  [AA,BB,Qz,Zz] = qz(Acal,Bcal,'complex');
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
    'spectral_radius',NaN,'stable_multipliers',[]);
  D = []; Pout = [];
  reasons = {};
  if any(degenerate), reasons{end+1} = sprintf('QZ_DEGENERATE %d',nnz(degenerate)); end
  if any(gap<=g.unit_gap), reasons{end+1} = sprintf('UNIT_CIRCLE_GAP %.3e',min(gap)); end
  if nnz(stable)~=n, reasons{end+1} = sprintf('STABLE_COUNT %d~=%d',nnz(stable),n); end
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
  Z = Zs(:,1:n); Z1 = Z(1:n,:); Z0 = Z(n+1:end,:); Y = Qs(1:n,:)';
  info.z0_rcond = rcond(Z0);
  normA = norm(Acal,'fro'); normB = norm(Bcal,'fro');
  info.invariance = (norm(Acal*Z-Y*AAs(1:n,1:n),'fro')+norm(Bcal*Z-Y*BBs(1:n,1:n),'fro'))/ ...
    ((normA+normB)*norm(Z,'fro'));
  Ts = BBs(1:n,1:n)\AAs(1:n,1:n);
  info.lower_block = norm(Z1-Z0*Ts,'fro')/max(norm(Z1,'fro'),norm(Z0*Ts,'fro'));
  alpha_s = diag(AAs(1:n,1:n)); gamma_s = diag(BBs(1:n,1:n));
  info.stable_multipliers = alpha_s./gamma_s;
  info.spectral_radius = max(abs(info.stable_multipliers));
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

function [B,G,backward,herm] = LOCAL_extend(config,t,mu,fac,Pout,n)
  % Near-wall one-cell map: trace g -> cell coefficients [g; Pout g; B g] with
  % B = A_II^{-1}(-A_IW0 - A_IW1 Pout), and G = cal(B)^* M cal(B), in 32-column blocks.
  A = t.K-mu*t.M; I = t.interior; W0 = t.wall(1:n); W1 = t.wall(n+1:end);
  AI0 = A(I,W0); AI1 = A(I,W1); M = t.M;
  block = config.solver.rhs_block; nI = numel(I); B = complex(zeros(nI,n)); backward = 0;
  for j = 1:block:n
    J = j:min(j+block-1,n);
    rhs = -(full(AI0(:,J))+AI1*Pout(:,J)); X = fac.apply(rhs);
    r = fac.AII*X-rhs;
    backward = max(backward,max(sum(abs(r),1)./max(fac.norm_A*sum(abs(X),1)+sum(abs(rhs),1),realmin)));
    B(:,J) = X;
  end
  G = complex(zeros(n));
  MI = M(:,I); M0 = M(:,W0); M1 = M(:,W1);
  for j = 1:block:n
    J = j:min(j+block-1,n);
    MB = full(M0(:,J))+M1*Pout(:,J)+MI*B(:,J);
    G(:,J) = MB(W0,:)+Pout'*MB(W1,:)+B'*MB(I,:);
  end
  herm = norm(G-G','fro')/max(norm(G,'fro'),realmin);
  G = (G+G')/2;
end

function bytes = LOCAL_cell_bytes(config,t,want_extension,n)
  nI = numel(t.interior); nfree = numel(t.free);
  bytes = config.solver.lu_fill_allowance*2*16*t.symbolic_nnz+16*nI*config.solver.rhs_block*4 + ...
    3*24*nnz(t.K)+want_extension*(2*16*nI*n+16*nfree*config.solver.rhs_block);
end

%% ==================== One frequency response ====================
% Both leads, then the centre; selection, wall trace g (g^* W g = 1), centre field.
function [res,ext] = LOCAL_evaluate(ctx,ops,k,mu,opts)
  config = ctx.config; n = ops.n; overall = tic; R = config.root;
  res = struct('k',k,'mu',mu,'valid',true,'reason_left','','reason_right','', ...
    'reason_center','','times',struct('lead_elimination',0,'qz_dtn',0,'extension',0, ...
    'center_small',0,'total',0),'cell',struct(),'dtn',struct(),'lambda',[],'H_norm',NaN, ...
    'H_hermitian_defect',NaN,'F_hermitian_defect',NaN,'index',NaN,'theta',NaN,'gap',NaN, ...
    'y',[],'g',[],'center_residual',NaN,'center_recovery_residual',NaN, ...
    'selection',struct('type','none','nearest_indices',[],'nearest_lambda',[], ...
    'correlations',[],'index',NaN,'gap',NaN,'gap_threshold',NaN,'reason',''), ...
    'rss_bytes',NaN,'F',[]);
  ext = struct(); res.rss_bytes = LOCAL_rss();
  D = cell(1,2); names = {'left','right'};
  for j = 1:2
    name = names{j}; t = ops.(name);
    LOCAL_memory_gate(config,['lead ',name],LOCAL_cell_bytes(config,t,opts.extension,n));
    timer = tic;
    [S,info,fac] = LOCAL_eliminate(config,t,mu,'lu');
    dt = toc(timer); res.times.lead_elimination = res.times.lead_elimination+dt;
    LOCAL_ledger('add','lead_elimination',dt);
    res.cell.(name) = info;
    if ~info.valid
      res.valid = false; res.(['reason_',name]) = info.reason; res.dtn.(name) = struct(); continue
    end
    timer = tic;
    [Dj,Pout,dinfo] = LOCAL_dtn(config,S,n);
    dt = toc(timer); res.times.qz_dtn = res.times.qz_dtn+dt; LOCAL_ledger('add','qz_dtn',dt);
    res.dtn.(name) = rmfield(dinfo,{'stable_multipliers'});
    if ~dinfo.valid
      res.valid = false; res.(['reason_',name]) = dinfo.reason; continue
    end
    D{j} = Dj;
    if opts.extension
      timer = tic;
      [B,G,backward,herm] = LOCAL_extend(config,t,mu,fac,Pout,n);
      dt = toc(timer); res.times.extension = res.times.extension+dt;
      LOCAL_ledger('add','extension',dt);
      ext.(name) = struct('S',S,'D',Dj,'Pout',Pout,'B',B,'G',G, ...
        'multipliers',dinfo.stable_multipliers,'extension_backward',backward,'G_hermitian_defect',herm);
      clear B G
    end
    clear fac
  end
  if ~res.valid, res.times.total = toc(overall); return, end
  t = ops.center;
  LOCAL_memory_gate(config,'center',LOCAL_cell_bytes(config,t,false,n));
  timer = tic;
  [Sc,info,fac] = LOCAL_eliminate(config,t,mu,'chol');
  if ~info.valid && strcmp(info.reason,'CENTER_CHOLESKY_FAILED')
    [Sc,info,fac] = LOCAL_eliminate(config,t,mu,'lu');   % the one allowed pivoted-LU fallback
    info.method = 'lu_after_cholesky_failure';
  end
  res.cell.center = info;
  if ~info.valid
    res.valid = false; res.reason_center = info.reason;
    dt = toc(timer); res.times.center_small = dt; LOCAL_ledger('add','center_small',dt);
    res.times.total = toc(overall); return
  end
  F = Sc+blkdiag(D{1},D{2});
  Rw = ops.wall_chol;
  H = (Rw')\F/Rw;
  res.F_hermitian_defect = norm(F-F','fro')/max(1,norm(F,'fro'));
  res.H_hermitian_defect = norm(H-H','fro')/max(1,norm(H,'fro'));
  if ~(res.H_hermitian_defect<=config.gates.h_hermitian)
    res.valid = false; res.reason_center = sprintf('H_HERMITIAN %.3e',res.H_hermitian_defect);
    dt = toc(timer); res.times.center_small = dt; LOCAL_ledger('add','center_small',dt);
    res.times.total = toc(overall); return
  end
  [V,L] = eig((H+H')/2); [lambda,order] = sort(real(diag(L))); V = V(:,order);
  res.lambda = lambda; res.H_norm = max(abs(lambda));
  if opts.want_F, res.F = F; end
  % --- branch selection (smallest |theta|, transferred wall trace, or fixed index) ---
  sel = opts.selector;
  [~,near] = sort(abs(lambda)); near = near(1:min(R.nearest_count,numel(near)));
  selection = struct('type',sel.type,'nearest_indices',near','nearest_lambda',lambda(near)', ...
    'correlations',[],'index',NaN,'gap',NaN,'gap_threshold',R.gap_factor*max(1,res.H_norm), ...
    'reason','');
  index = NaN;
  switch sel.type
    case 'smallest'
      index = near(1);
    case 'transfer'
      corr = abs(V(:,near)'*sel.y)'; selection.correlations = corr;
      hits = find(corr>=R.select_corr_min);
      if numel(hits)==1
        index = near(hits);
      else
        selection.reason = sprintf('%d of %d nearest eigenvectors reach correlation %.2f (max %.4f)', ...
          numel(hits),numel(near),R.select_corr_min,max(corr));
      end
    case 'fixed'
      index = sel.index;
  end
  if ~isnan(index)
    selection.gap = LOCAL_gap(lambda,index);
    if ~strcmp(sel.type,'fixed') && ~(selection.gap>=selection.gap_threshold)
      selection.reason = sprintf('target gap %.3e below %.3e',selection.gap,selection.gap_threshold);
      index = NaN;
    end
  end
  selection.index = index; res.selection = selection;
  if ~isnan(index)
    y = V(:,index); g = Rw\y; [~,at] = max(abs(g)); phase = conj(g(at))/abs(g(at));
    g = g*phase; y = y*phase;
    res.index = index; res.theta = lambda(index); res.gap = LOCAL_gap(lambda,index);
    res.y = y; res.g = g;
    % centre field from the same factorization and the uncondensed residual
    A = t.K-mu*t.M; I = t.interior; W = t.wall;
    u = complex(zeros(numel(t.free),1)); u(W) = g; u(I) = fac.apply(-(A(I,W)*g));
    Ku = t.K*u; Mu = t.M*u; gl = g(1:n); gr = g(n+1:end);
    r = Ku-mu*Mu; r(W) = r(W)+[D{1}*gl;D{2}*gr];
    res.center_residual = norm(r)/(norm(Ku)+abs(mu)*norm(Mu)+norm(D{1}*gl)+norm(D{2}*gr));
    res.center_recovery_residual = norm(A(I,:)*u)/(norm(A(I,I)*u(I))+norm(A(I,W)*g));
    if opts.extension, ext.center = struct('S',Sc,'F',F,'H',H,'u',u); end
  end
  clear fac
  dt = toc(timer); res.times.center_small = dt; LOCAL_ledger('add','center_small',dt);
  res.times.total = toc(overall);
end

%% ==================== Branch tracking and bracketed root ====================
% Fixed algebraic index, half-width bracketing around the chain start, Brent.
function item = LOCAL_chain(ctx,ops,item,k_init,selector)
  config = ctx.config; R = config.root; mu_tol = item.epsilon*R.mu_width_factor;
  item.k_init = k_init;
  state = struct('name',item.name,'ks',[],'results',{{}},'count',0,'hits',0,'slowest',0, ...
    'index',NaN,'accepted_k',[],'accepted_y',{{}},'halvings',0);
  [r0,state] = LOCAL_eval_cached(ctx,ops,state,k_init,'init',selector);
  if ~r0.valid
    item.status = 'CELL_OR_DTN_EXCEPTION';
    item.reason = sprintf('invalid initial point: L[%s] R[%s] C[%s]',r0.reason_left, ...
      r0.reason_right,r0.reason_center);
    for side = [-1,1]
      [~,state] = LOCAL_eval_cached(ctx,ops,state, ...
        LOCAL_clip(config,k_init+side*R.half_widths(1)),'diagnostic',struct('type','smallest'));
    end
    item = LOCAL_chain_close(item,state); return
  end
  item.selection = r0.selection;
  if isnan(r0.index)
    item.status = 'ROOT_OR_BRANCH_UNRESOLVED'; item.substatus = 'MODE_AMBIGUOUS';
    item.reason = r0.selection.reason; item = LOCAL_chain_close(item,state); return
  end
  state.index = r0.index; item.branch_index = r0.index;
  start = LOCAL_point(r0); state = LOCAL_accept(state,start);
  fprintf('  chain %s start k=%.16g index %d theta %.3e gap %.3e\n',item.name,k_init, ...
    r0.index,start.theta,start.gap);
  % --- fixed half-width bracketing around the chain start ---
  % D2: a floating-point zero at the start is not a bracket; brackets need
  % strictly opposite signs (a zero start is enclosed by its two sides)
  last = {start,start}; blocked = [false,false]; bracket = [];
  item.root_zero_start = start.theta==0;
  for hw = R.half_widths
    if ~isempty(bracket), break, end
    for side = 1:2
      if blocked(side) || ~isempty(bracket), continue, end
      target = LOCAL_clip(config,k_init+(2*side-3)*hw);
      if target==last{side}.k, continue, end
      [state,path,ok,why] = LOCAL_advance(ctx,ops,state,last{side},target);
      bracket = LOCAL_strict_bracket(path);
      if ~isempty(path), last{side} = path(end); end
      if isempty(bracket) && start.theta==0 && last{1}.theta*last{2}.theta<0
        bracket = [last{1},last{2}];
      end
      if ~ok
        if strcmp(why,'BRANCH_UNRESOLVED')
          item.status = 'ROOT_OR_BRANCH_UNRESOLVED'; item.substatus = 'MODE_AMBIGUOUS';
          item.reason = 'branch overlap/gap unresolved after 8 step halvings';
          item = LOCAL_chain_close(item,state); return
        elseif strcmp(why,'FREQUENCY_LIMIT')
          item.status = 'ROOT_OR_BRANCH_UNRESOLVED'; item.substatus = 'NO_LOCAL_BRACKET';
          item.reason = 'frequency limit before bracket';
          item = LOCAL_chain_close(item,state); return
        end
        blocked(side) = true;
        item.reason = [item.reason,sprintf('side %d blocked: %s; ',side,why)];
      end
    end
  end
  if isempty(bracket)
    item.status = 'ROOT_OR_BRANCH_UNRESOLVED'; item.substatus = 'NO_LOCAL_BRACKET';
    item.reason = [item.reason,'no valid same-branch sign change within the fixed window'];
    item = LOCAL_chain_close(item,state); return
  end
  [item,state] = LOCAL_brent(ctx,ops,state,item,bracket,mu_tol);
  item = LOCAL_chain_close(item,state);
end

function item = LOCAL_chain_close(item,state)
  % qualified: a usable numerical root (valid operators, real strict bracket,
  % uncondensed residual gate); resolved: all resolution targets also met.
  item.frequency_count = state.count; item.cache_hits = state.hits;
  item.slowest_eval_seconds = state.slowest; item.halvings = state.halvings;
  item.resolved = strcmp(item.status,'ROOT_FOUND');
  item.qualified = item.resolved || strcmp(item.status,'ROOT_CANDIDATE_UNRESOLVED');
end

function bracket = LOCAL_strict_bracket(path)
  % First pair of consecutive nonzero-theta path points with opposite signs.
  bracket = []; th = [path.theta]; nz = find(th~=0);
  for j = 1:numel(nz)-1
    if th(nz(j))*th(nz(j+1))<0, bracket = path([nz(j),nz(j+1)]); return, end
  end
end

function k = LOCAL_clip(config,k)
  k = min(max(k,config.window(1)),config.window(2));
end

function gap = LOCAL_gap(lambda,index)
  others = lambda; others(index) = []; gap = min(abs(others-lambda(index)));
end

function point = LOCAL_point(res)
  point = struct('k',res.k,'theta',res.theta,'y',res.y,'g',res.g,'gap',res.gap, ...
    'H_norm',res.H_norm,'center_residual',res.center_residual, ...
    'center_recovery_residual',res.center_recovery_residual);
end

function [state,path,ok,why] = LOCAL_advance(ctx,ops,state,from,target)
  % Continue the fixed branch from an accepted point to target with step halving.
  R = ctx.config.root; path = from; ok = true; why = ''; current = from; pending = target;
  halvings = 0;
  while current.k ~= target
    if state.count>=R.max_frequencies && ~LOCAL_cached(state,pending)
      ok = false; why = 'FREQUENCY_LIMIT'; return
    end
    [res,state] = LOCAL_eval_cached(ctx,ops,state,pending,'bracket');
    if ~res.valid
      ok = false; why = sprintf('invalid at k=%.16g: L[%s] R[%s] C[%s]',pending, ...
        res.reason_left,res.reason_right,res.reason_center); return
    end
    point = LOCAL_point(res);
    overlap = abs(current.y'*point.y);
    if overlap>=R.overlap_min && point.gap>=R.gap_factor*max(1,point.H_norm)
      path(end+1) = point; current = point; pending = target; %#ok<AGROW>
      state = LOCAL_accept(state,point);
      if path(end-1).theta*point.theta<0, return, end
    else
      halvings = halvings+1; state.halvings = state.halvings+1;
      if halvings>R.max_halvings, ok = false; why = 'BRANCH_UNRESOLVED'; return, end
      pending = (current.k+pending)/2;
    end
  end
end

function state = LOCAL_accept(state,point)
  state.accepted_k(end+1) = point.k; state.accepted_y{end+1} = point.y;
end

function [item,state] = LOCAL_brent(ctx,ops,state,item,bracket,mu_tol)
  % Brent on the signed branch eigenvalue theta(k). Stop: k bracket <= 2e-12,
  % mu bracket <= eps_p/8, |theta| <= 1e-10, uncondensed residual <= 1e-9.
  config = ctx.config; R = config.root; tol = R.k_width/4;
  pa = bracket(1); pb = bracket(2);
  a = pa.k; fa = pa.theta; b = pb.k; fb = pb.theta;
  c = a; fc = fa; pc = pa; d = b-a; e = d; converged = false; reason = '';
  item.root = struct('initial_bracket',sort([a,b]),'iterations',0,'bisections',0, ...
    'branch_fallbacks',0,'theta_b',NaN,'theta_c',NaN,'k_b',NaN,'k_c',NaN,'zero_hits',[]);
  bisect_only = false;
  while true
    if sign(fb)==sign(fc) && fb~=0, c = a; fc = fa; pc = pa; d = b-a; e = d; end
    if abs(fc)<abs(fb)
      a = b; b = c; c = a; fa = fb; fb = fc; fc = fa; pa = pb; pb = pc; pc = pa;
    end
    tol1 = 2*eps*abs(b)+0.5*tol; xm = 0.5*(c-b);
    LOCAL_progress(ctx,'root',struct('chain',item.name,'bracket_width',abs(c-b), ...
      'slowest_eval_seconds',state.slowest,'frequency_count',state.count));
    widths_ok = abs(c-b)<=R.k_width && abs(c^2-b^2)<=mu_tol;
    if widths_ok && abs(fb)<=R.theta_abs && pb.center_residual<=R.center_residual
      converged = true; break
    end
    if widths_ok, bisect_only = true; end
    if abs(c-b)<=8*eps*abs(b)
      reason = 'bracket reached floating-point resolution before the |theta|/residual gates'; break
    end
    if ~bisect_only && abs(e)>=tol1 && abs(fa)>abs(fb)
      s = fb/fa;
      if a==c
        p = 2*xm*s; q = 1-s;
      else
        q = fa/fc; r = fb/fc;
        p = s*(2*xm*q*(q-r)-(b-a)*(r-1)); q = (q-1)*(r-1)*(s-1);
      end
      if p>0, q = -q; else, p = -p; end
      if 2*p<min(3*xm*q-abs(tol1*q),abs(e*q))
        e = d; d = p/q;
      else
        d = xm; e = d; item.root.bisections = item.root.bisections+1;
      end
    else
      d = xm; e = d; item.root.bisections = item.root.bisections+1;
    end
    if bisect_only, d = xm; end
    a = b; fa = fb; pa = pb;
    if abs(d)>tol1, trial = b+d; else, trial = b+sign(xm)*tol1; end
    fallback = 0; zero_nudges = 0;
    while true
      if state.count>=R.max_frequencies && ~LOCAL_cached(state,trial)
        reason = 'frequency limit reached'; break
      end
      [res,state] = LOCAL_eval_cached(ctx,ops,state,trial,'root');
      item.root.iterations = item.root.iterations+1;
      if ~res.valid
        item.status = 'CELL_OR_DTN_EXCEPTION';
        item.reason = sprintf('invalid point inside bracket k=%.16g: L[%s] R[%s] C[%s]', ...
          trial,res.reason_left,res.reason_right,res.reason_center);
        return
      end
      point = LOCAL_point(res);
      [~,nearest] = min(abs(state.accepted_k-trial));
      overlap = abs(state.accepted_y{nearest}'*point.y);
      if overlap>=R.overlap_min && point.gap>=R.gap_factor*max(1,point.H_norm)
        state = LOCAL_accept(state,point);
        if point.theta~=0, break, end
        % D2: a floating-point zero is never a bracket end or a convergence
        % proof; nudge towards the far end c to keep a strict bracket
        item.root.zero_hits(end+1) = trial; zero_nudges = zero_nudges+1;
        if zero_nudges>2
          reason = 'repeated exact-zero evaluations; strict bracket kept'; break
        end
        step = max(tol1,4*eps*abs(trial));
        if abs(c-trial)<=step, trial = (trial+c)/2; else, trial = trial+sign(c-trial)*step; end
        continue
      end
      fallback = fallback+1; state.halvings = state.halvings+1;
      item.root.branch_fallbacks = item.root.branch_fallbacks+1;
      if fallback>R.max_halvings
        item.status = 'ROOT_OR_BRANCH_UNRESOLVED'; item.substatus = 'MODE_AMBIGUOUS';
        item.reason = 'branch overlap/gap unresolved inside root bracket'; return
      end
      trial = (trial+a)/2;
    end
    if ~isempty(reason), break, end
    b = trial; fb = point.theta; pb = point;
  end
  item.k = b; item.mu = b^2; item.theta = fb;
  item.bracket_low = min(b,c); item.bracket_high = max(b,c);
  item.bracket_k_width = abs(c-b); item.bracket_mu_width = abs(c^2-b^2);
  item.theta_scaled = abs(fb)/max(1,pb.H_norm);
  item.center_residual = pb.center_residual; item.center_recovery_residual = pb.center_recovery_residual;
  item.g = pb.g; item.y = pb.y;
  item.root.theta_b = fb; item.root.theta_c = fc; item.root.k_b = b; item.root.k_c = c;
  item.resolution = struct('k_width_ok',abs(c-b)<=R.k_width,'mu_width_ok',abs(c^2-b^2)<=mu_tol, ...
    'theta_ok',abs(fb)<=R.theta_abs,'residual_ok',pb.center_residual<=R.center_residual, ...
    'strict_bracket',fb*fc<0);
  if converged
    item.status = 'ROOT_FOUND';
  elseif item.resolution.residual_ok && item.resolution.strict_bracket
    % usable numerical candidate with its real bracket; evaluation resolution not met
    item.status = 'ROOT_CANDIDATE_UNRESOLVED'; item.substatus = 'RESOLUTION_TARGETS_NOT_MET';
    item.reason = reason;
  else
    item.status = 'ROOT_OR_BRANCH_UNRESOLVED'; item.substatus = 'ROOT_NOT_CONVERGED';
    item.reason = reason;
  end
end

function hit = LOCAL_cached(state,k)
  hit = any(state.ks==k);
end

function [res,state] = LOCAL_eval_cached(ctx,ops,state,k,purpose,selector)
  j = find(state.ks==k,1);
  if ~isempty(j)
    res = state.results{j}; state.hits = state.hits+1;
    LOCAL_iteration_row(ctx,state.name,state,res,purpose,true,0);
    return
  end
  if nargin<6 || isempty(selector)
    selector = struct('type','fixed','index',state.index,'y',[]);
  end
  timer = tic;
  res = LOCAL_evaluate(ctx,ops,k,k^2,struct('selector',selector,'extension',false,'want_F',false));
  elapsed = toc(timer);
  state.count = state.count+1; state.slowest = max(state.slowest,elapsed);
  state.ks(end+1) = k; state.results{end+1} = res;
  LOCAL_iteration_row(ctx,state.name,state,res,purpose,false,elapsed);
  if ~strcmp(purpose,'root')
    LOCAL_progress(ctx,purpose,struct('chain',state.name,'slowest_eval_seconds',state.slowest, ...
      'frequency_count',state.count));
  end
end

%% ==================== Same-mode evidence and conditional estimate ====================
% Cross-layer wall correlations (201 physical samples per wall) and the fixed
% conditional formulas B4, R0, RN under S_{1/2} and E (never certified here).
function out = LOCAL_same_mode(config,chains,layers,spaces)
  yq = -0.5+(0:config.same_mode.trace_points-1)'/(config.same_mode.trace_points-1);
  samples = cell(1,4); centroid = cell(1,4);
  for j = 1:numel(layers)
    L = layers(j);
    if L.qualified && isfield(L.recovery,'g') && ~isempty(L.recovery.g)
      sp = spaces{L.p};
      samples{L.p} = LOCAL_transfer(L.recovery.g,sp.s,L.p,yq,sp.beta);
      centroid{L.p} = L.recovery.center_centroid_values;
    end
  end
  pairs = [2,3;3,4;2,4]; out = struct('trace_points',numel(yq),'corr_min',config.same_mode.corr_min, ...
    'pairs',struct([]),'within_layer',struct([]),'all_pass',false,'pass_23',false,'pass_34',false);
  pass = true;
  for j = 1:3
    a = pairs(j,1); b = pairs(j,2);
    item = struct('from',a,'to',b,'wall_correlation',NaN,'center_centroid_correlation',NaN, ...
      'pass',false,'status','UNAVAILABLE');
    if ~isempty(samples{a}) && ~isempty(samples{b})
      item.wall_correlation = abs(samples{a}'*samples{b})/(norm(samples{a})*norm(samples{b}));
      item.center_centroid_correlation = abs(centroid{a}'*centroid{b})/ ...
        (norm(centroid{a})*norm(centroid{b}));
      item.pass = item.wall_correlation >= config.same_mode.corr_min;
      item.status = 'PASS'; if ~item.pass, item.status = 'BELOW_THRESHOLD'; end
    end
    if j <= 2, pass = pass && item.pass; end
    if j == 1, out.pass_23 = item.pass; elseif j == 2, out.pass_34 = item.pass; end
    out.pairs = LOCAL_append(out.pairs,item);
  end
  out.all_pass = pass;
  % primary/check/extra roots of one order: wall-trace correlation (diagnostic)
  for p = config.orders
    list = chains([chains.p]==p & [chains.qualified]);
    for i = 1:numel(list)
      for j = i+1:numel(list)
        sp = spaces{p};
        a = LOCAL_transfer(list(i).g,sp.s,p,yq,sp.beta); b = LOCAL_transfer(list(j).g,sp.s,p,yq,sp.beta);
        out.within_layer = LOCAL_append(out.within_layer,struct('p',p,'from',list(i).name, ...
          'to',list(j).name,'wall_correlation',abs(a'*b)/(norm(a)*norm(b)), ...
          'mu_difference',list(j).mu-list(i).mu));
      end
    end
  end
end

function est = LOCAL_estimate(config,layers,predictions,same_mode)
  e = config.epsilon; nu = NaN(1,3); k = NaN(1,3); status = repmat({'NOT_RUN'},1,3);
  evaluation = repmat({'NOT_EVALUATED'},1,3); elapsed = NaN; numeric = NaN(1,3);
  for j = 1:numel(layers)
    L = layers(j); i = L.p-1; status{i} = L.status; evaluation{i} = L.evaluation_status;
    numeric(i) = L.nu;
    if L.qualified, nu(i) = L.nu; k(i) = L.k; end
    if L.p == 4, elapsed = L.matlab_elapsed_at_completion; end
  end
  est = struct('label','CONDITIONAL_ON_SATURATION_AND_EVALUATION','S_verified',false, ...
    'E_certified',false,'q',config.q,'epsilon',e,'evaluation_floor',e(2)+2*e(3), ...
    'mu0',config.mu0,'k0',config.k0,'nu_tilde',nu,'k_tilde',k,'layer_status',{status}, ...
    'layer_evaluation_status',{evaluation},'prediction_label','','mu_N',NaN,'k_N',NaN, ...
    'prediction_status','NOT_AVAILABLE','d23',NaN,'d34',NaN,'signed_increment_23',NaN, ...
    'signed_increment_34',NaN,'sign_flip',NaN,'q_obs',NaN,'q_obs_status','UNRESOLVED', ...
    'saturation_diagnostic','UNRESOLVED','B4',NaN,'R0',NaN,'RN',NaN, ...
    'k_interval_nu4',struct(),'k_interval_mu0',struct(),'k_interval_muN',struct(), ...
    'move_old_to_P2',NaN,'prediction_verification_nu3_minus_muN',NaN, ...
    'signed_estimate_nu4_minus_mu0',NaN,'prediction_assessment',struct(), ...
    'final_candidate_mu',nu(3),'final_candidate_k',k(3),'same_mode_pass',same_mode.all_pass, ...
    'evaluation_resolved',all(ismember(evaluation,{'RESOLVED','RESOLVED_BY_EXTRA'})), ...
    'evaluation_resolved_P34',false,'evaluation_resolved_P2',false,'B4_over_floor',NaN, ...
    'R0_over_floor',NaN,'layer_numeric_mu',numeric, ...
    'final_status','','final_reason','','null_reasons',struct(), ...
    'matlab_elapsed_at_final_candidate',elapsed);
  % prediction on the final P3 evaluation rule (check unless extra replaced it)
  rule3 = '';
  for j = 1:numel(layers), if layers(j).p == 3, rule3 = layers(j).final_rule; end, end
  pick = [];
  for j = 1:numel(predictions)
    if strcmp(predictions(j).label,rule3), pick = predictions(j); end
  end
  if isempty(pick) && ~isempty(predictions)
    pick = predictions(strcmp({predictions.label},'check'));
  end
  if ~isempty(pick)
    est.prediction_label = pick.label; est.prediction_status = pick.status;
    est.mu_N = pick.mu_N; est.k_N = pick.k_N;
  else
    est.null_reasons.mu_N = 'no P3 prediction was produced';
  end
  if ~isnan(nu(1)), est.move_old_to_P2 = nu(1)-config.mu0; end
  if ~isnan(nu(2)) && ~isnan(est.mu_N), est.prediction_verification_nu3_minus_muN = nu(2)-est.mu_N; end
  if ~isnan(nu(3)), est.signed_estimate_nu4_minus_mu0 = nu(3)-config.mu0; end
  if ~isnan(nu(2)) && ~isnan(est.mu_N)
    actual = nu(2)-config.mu0; predicted = est.mu_N-config.mu0;
    est.prediction_assessment = struct('predicted_delta',predicted,'actual_delta_P3',actual, ...
      'sign_agrees',sign(actual)==sign(predicted),'actual_resolved_above_eps3',abs(actual)>e(2), ...
      'relative_deviation',abs(actual-predicted)/abs(actual), ...
      'note','diagnostic only; mu0 is a given scalar, nu3 carries the declared budget eps3');
  end
  % D2 5.1: B4 and R0 need only the P3/P4 roots; RN also needs a finite mu_N;
  % P2 enters d23 / q_obs only. Missing P2 or prediction never clears B4, R0.
  if isnan(nu(2)) || isnan(nu(3))
    bad = 1+find(isnan(nu(2:3)),1);
    est.final_status = status{bad};
    if any(strcmp(est.final_status,{'ROOT_QUALIFIED','PENDING'}))
      est.final_status = 'ROOT_OR_BRANCH_UNRESOLVED';
    end
    est.final_reason = sprintf('P%d has no usable final root; B4/R0/RN not formed',bad+1);
    est.null_reasons.B4 = est.final_reason; est.null_reasons.R0 = est.final_reason;
    est.null_reasons.RN = est.final_reason;
    return
  end
  est.signed_increment_34 = nu(3)-nu(2); est.d34 = abs(est.signed_increment_34);
  if ~isnan(nu(1))
    est.signed_increment_23 = nu(2)-nu(1); est.d23 = abs(est.signed_increment_23);
    est.sign_flip = sign(est.signed_increment_23)~=sign(est.signed_increment_34);
    if est.d23 > config.ratio_floor_factor*(e(1)+e(2))
      est.q_obs = est.d34/est.d23; est.q_obs_status = 'RESOLVED';
      if est.q_obs <= config.q
        est.saturation_diagnostic = 'SATURATION_DIAGNOSTIC_SUPPORTED';
      else
        est.saturation_diagnostic = 'NOT_SUPPORTED';
      end
    else
      est.null_reasons.q_obs = sprintf('d23 = %.3e <= %g (eps2+eps3)',est.d23,config.ratio_floor_factor);
    end
  else
    est.null_reasons.d23 = 'P2 has no usable final root'; est.null_reasons.q_obs = est.null_reasons.d23;
  end
  est.B4 = est.d34+e(2)+2*e(3);
  est.R0 = abs(config.mu0-nu(3))+est.B4;
  est.k_interval_nu4 = LOCAL_k_interval(nu(3),est.B4);
  est.k_interval_mu0 = LOCAL_k_interval(config.mu0,est.R0);
  if ~isnan(est.mu_N) && isfinite(est.mu_N)
    est.RN = abs(est.mu_N-nu(3))+est.B4;
    est.k_interval_muN = LOCAL_k_interval(est.mu_N,est.RN);
  else
    est.null_reasons.RN = 'mu_N unavailable';
  end
  est.B4_over_floor = est.B4/est.evaluation_floor; est.R0_over_floor = est.R0/est.evaluation_floor;
  est.evaluation_resolved_P34 = all(ismember(evaluation(2:3),{'RESOLVED','RESOLVED_BY_EXTRA'}));
  est.evaluation_resolved_P2 = ismember(evaluation{1},{'RESOLVED','RESOLVED_BY_EXTRA'});
  notes = {};
  if ~same_mode.pass_23, notes{end+1} = 'P2-P3 same-mode correlation not supported'; end
  if ~est.evaluation_resolved_P2, notes{end+1} = ['P2 evaluation ',evaluation{1}]; end
  if ~strcmp(est.saturation_diagnostic,'SATURATION_DIAGNOSTIC_SUPPORTED')
    notes{end+1} = ['saturation diagnostic ',est.saturation_diagnostic, ...
      ': condition S_1/2 lacks numerical support in this run'];
  end
  if ~strcmp(est.prediction_status,'PREDICTION_SAVED')
    notes{end+1} = ['prediction ',est.prediction_status];
  end
  if ~same_mode.pass_34
    est.final_status = 'CONDITIONAL_ESTIMATE_SAME_MODE_UNRESOLVED';
    est.final_reason = 'P3-P4 wall correlation below 0.99 or unavailable: same continuous target not supported';
  elseif ~est.evaluation_resolved_P34
    est.final_status = 'CONDITIONAL_ESTIMATE_EVALUATION_UNRESOLVED';
    est.final_reason = ['P3/P4 evaluation status: ',strjoin(evaluation(2:3),', ')];
  else
    est.final_status = 'CONDITIONAL_ESTIMATE_DELIVERED';
    est.final_reason = 'conditional on S_1/2 and E (not verified/certified)';
  end
  if ~isempty(notes), est.final_reason = [est.final_reason,'; ',strjoin(notes,'; ')]; end
end

function out = LOCAL_k_interval(m,R)
  if m > 0 && R < m
    out = struct('center_mu',m,'radius_mu',R,'k_low',sqrt(m-R),'k_high',sqrt(m+R), ...
      'k_radius_max',R/(sqrt(m)+sqrt(m-R)),'status','OK');
  else
    out = struct('center_mu',m,'radius_mu',R,'k_low',sqrt(max(0,m-R)),'k_high',sqrt(m+R), ...
      'k_radius_max',NaN,'status','RESOLUTION_INSUFFICIENT');
  end
end

%% ==================== Sizing probe (no root chain) ====================
% Formal mesh: location, check-rule assembly and one timed evaluation with
% extension and Stein mass per order; feeds the pre-launch budget estimate.
function out = LOCAL_sizing(ctx,mesh,spaces)
  config = ctx.config; out = struct('location',struct([]),'orders',struct([]),'bands',struct(), ...
    'sizing_zero_weight_points',0);
  bands = struct();
  for r = 1:2
    rule = config.rules(r); timer = tic;
    bands.(rule.name) = LOCAL_band_locate(config,mesh,rule,spaces);
    out.location = LOCAL_append(out.location,struct('rule',rule.name,'seconds',toc(timer), ...
      'points',bands.(rule.name).total_points,'failures',bands.(rule.name).total_failures, ...
      'dual',bands.(rule.name).total_dual));
    fprintf('SIZING location %s %.2fs points %d failures %d\n',rule.name,toc(timer), ...
      bands.(rule.name).total_points,bands.(rule.name).total_failures);
  end
  out.bands = LOCAL_band_summary(bands);
  % timing only: failed points get zero weight on an arbitrary element (sizing is
  % never a scientific result; the formal run stops at POINT_LOCATION_FAILED)
  for name = {'left','center','right'}
    b = bands.check.(name{1}); bad = b.element==0;
    b.element(bad) = 1; b.xi(bad) = 1/3; b.eta(bad) = 1/3; b.weight(bad) = 0;
    bands.check.(name{1}) = b;
  end
  out.sizing_zero_weight_points = bands.check.total_failures;
  for p = config.orders
    sp = spaces{p}; rss0 = LOCAL_rss();
    timer = tic; ops = LOCAL_operators(ctx,sp,bands.check,config.rules(2),false,false);
    assembly = toc(timer);
    timer = tic;
    res = LOCAL_evaluate(ctx,ops,config.k0,config.mu0,struct('selector',struct('type','smallest'), ...
      'extension',false,'want_F',false));
    plain = toc(timer);
    timer = tic;
    [res2,ext] = LOCAL_evaluate(ctx,ops,config.k0,config.mu0,struct('selector', ...
      struct('type','smallest'),'extension',true,'want_F',false));
    extended = toc(timer); rss1 = LOCAL_rss();
    timer = tic; mass = struct('m_inf',NaN,'stein_rounds',NaN);
    if res2.valid && ~isnan(res2.index)
      mass = LOCAL_masses(config,ops,ext,res2,Inf);
    end
    stein = toc(timer);
    item = struct('p',p,'matrix_checks_pass',ops.checks.pass,'matrix_checks_reason',ops.checks.reason, ...
      'wall_dofs',sp.n,'free_dofs',[numel(ops.left.free),numel(ops.center.free), ...
      numel(ops.right.free)],'symbolic_nnz',[ops.left.symbolic_nnz,ops.center.symbolic_nnz, ...
      ops.right.symbolic_nnz],'assembly_check_seconds',assembly,'evaluation_seconds',plain, ...
      'evaluation_extension_seconds',extended,'stein_seconds',stein,'rss_before',rss0, ...
      'rss_after_extension',rss1,'valid',res.valid,'theta_smallest',res.theta, ...
      'center_residual',res.center_residual,'times',res.times,'times_extension',res2.times, ...
      'm_inf',mass.m_inf,'stein_rounds',mass.stein_rounds);
    out.orders = LOCAL_append(out.orders,item);
    fprintf(['SIZING P%d assembly %.2fs eval %.2fs eval+ext %.2fs stein %.2fs rss %.2e/%.2e ', ...
      'theta %.3e valid %d\n'],p,assembly,plain,extended,stein,rss0,rss1,res.theta,res.valid);
    clear ops ext res res2
  end
end

%% ==================== Figures (MATLAB native export) ====================
function status = LOCAL_figures(ctx,result,chains,layers,predictions) %#ok<INUSD>
  status = struct('status','OK','files',{{}});
  dir = fullfile(ctx.output_dir,'figures');
  est = struct(); if isfield(result,'estimate'), est = result.estimate; end
  if ~isempty(layers)
    f = figure('Visible','off','Position',[100,100,720,460]);
    p = [layers.p]; nu = [layers.nu]; ok = ~isnan(nu);
    plot(p(ok),nu(ok)-ctx.config.mu0,'o-','LineWidth',1.2); hold on
    yline(0,'k:','\mu_0');
    if isfield(est,'mu_N') && ~isnan(est.mu_N)
      yline(est.mu_N-ctx.config.mu0,'r--','\mu_N (P3 prediction)');
    end
    if isfield(est,'B4') && ~isnan(est.B4) && ok(end)
      errorbar(p(end),nu(end)-ctx.config.mu0,est.B4,'s','Color',[0.2,0.6,0.2]);
    end
    xlabel('field order p'); ylabel('\nu_p - \mu_0'); xticks(2:4); grid on
    title('I10.1 roots per layer (final rule); missing layers not drawn');
    file = 'layers.png'; exportgraphics(f,fullfile(dir,file),'Resolution',150); close(f);
    status.files{end+1} = file;
  end
  if isfield(est,'B4') && ~isnan(est.B4)
    f = figure('Visible','off','Position',[100,100,720,460]);
    values = [est.B4,est.R0,est.RN,est.evaluation_floor];
    labels = {'B_4','R_0','R_N','eval floor 3e-10'};
    keep = ~isnan(values);
    bar(categorical(labels(keep),labels(keep)),values(keep)); set(gca,'YScale','log'); grid on
    ylabel('\mu units'); title('Conditional radii (S_{1/2} and E not verified)');
    file = 'radii.png'; exportgraphics(f,fullfile(dir,file),'Resolution',150); close(f);
    status.files{end+1} = file;
  end
  ledger = LOCAL_ledger('snapshot'); names = fieldnames(ledger);
  if ~isempty(names)
    f = figure('Visible','off','Position',[100,100,860,460]);
    values = cellfun(@(n)ledger.(n),names);
    barh(categorical(strrep(names,'_',' '),strrep(names,'_',' ')),values); grid on
    xlabel('MATLAB seconds (mutually exclusive ledger, before figures/save)');
    title('Time composition');
    file = 'timing.png'; exportgraphics(f,fullfile(dir,file),'Resolution',150); close(f);
    status.files{end+1} = file;
  end
end

%% ==================== Ledger, progress, memory and I/O ====================
% Mutually exclusive MATLAB timers; the launcher reads progress.json for grace decisions.
function out = LOCAL_ledger(action,name,value)
  persistent ledger total
  if isempty(ledger), ledger = struct(); total = 0; end
  out = [];
  switch action
    case 'reset'
      ledger = struct(); total = 0;
    case 'add'
      if ~isfield(ledger,name), ledger.(name) = 0; end
      ledger.(name) = ledger.(name)+value; total = total+value;
    case 'total'
      out = total;
    case 'snapshot'
      out = ledger;
    case 'close'
      out = struct('categories',ledger,'attributed_seconds',total, ...
        'matlab_function_seconds',name,'matlab_unattributed_seconds',name-total);
  end
end

function LOCAL_progress(ctx,phase,extra)
  value = struct('utc',LOCAL_utc(),'matlab_elapsed',toc(ctx.started),'phase',phase,'chain','', ...
    'p',NaN,'rule','','bracket_width',NaN,'slowest_eval_seconds',NaN,'frequency_count',NaN, ...
    'all_roots_done',false,'save_estimate_seconds',ctx.config.resources.save_estimate_seconds);
  for f = fieldnames(extra)', value.(f{1}) = extra.(f{1}); end
  if isempty(value.chain) && ~isnan(value.p), value.chain = sprintf('P%d',value.p); end
  token = regexp(value.chain,'^P(\d)-([a-z]+)$','tokens','once');
  if ~isempty(token), value.p = str2double(token{1}); value.rule = token{2}; end
  temporary = [ctx.progress_path,'.tmp'];
  LOCAL_json(temporary,value); movefile(temporary,ctx.progress_path,'f');
end

function LOCAL_partial(ctx,chains,layers,predictions)
  LOCAL_json(fullfile(ctx.output_dir,'partial-result.json'),struct('chains',LOCAL_slim_chains(chains), ...
    'layers',layers,'predictions',predictions,'ledger',LOCAL_ledger('snapshot'), ...
    'matlab_elapsed',toc(ctx.started)));
end

function chains = LOCAL_slim_chains(chains)
  if isempty(chains), return, end
  chains = rmfield(chains,{'g','y'});
end

function rss = LOCAL_rss()
  [flag,text] = system(sprintf('ps -o rss= -p %d',feature('getpid')));
  rss = NaN;
  if flag==0, rss = 1024*str2double(strtrim(text)); end
end

function LOCAL_memory_gate(config,label,bytes,rss)
  if nargin<4, rss = LOCAL_rss(); end
  if rss+bytes>config.resources.internal_gate_bytes
    error('i101:ResourceStop','Predicted %s memory %.0f + RSS %.0f exceeds %.0f bytes.', ...
      label,bytes,rss,config.resources.internal_gate_bytes);
  end
end

function LOCAL_iteration_header(path)
  fid = fopen(path,'w'); assert(fid>=0,'i101:IO','Cannot create iterations.csv.');
  fprintf(fid,['chain,eval_count,k,mu,purpose,cache_hit,valid,reason_left,reason_right,', ...
    'reason_center,branch_index,theta_target,theta_scaled,target_gap,nearest5,center_residual,', ...
    'left_backward,right_backward,center_backward,left_condest,right_condest,center_condest,', ...
    'left_unit_gap,right_unit_gap,left_z0_rcond,right_z0_rcond,left_riccati,right_riccati,', ...
    'left_dtn_herm,right_dtn_herm,left_consistency,right_consistency,H_herm,H_norm,', ...
    'lead_elimination_s,qz_dtn_s,extension_s,center_small_s,response_s,rss_bytes,utc\n']);
  fclose(fid);
end

function LOCAL_iteration_row(ctx,name,state,res,purpose,hit,elapsed)
  get = @(s,a,b)LOCAL_field(s,a,b);
  index = state.index; if isnan(index), index = res.index; end
  if ~isnan(index) && ~isempty(res.lambda)
    lam = res.lambda(index); gap = LOCAL_gap(res.lambda,index);
  else
    lam = NaN; gap = NaN;
  end
  if ~isempty(res.lambda)
    [~,near] = sort(abs(res.lambda)); near5 = strjoin(arrayfun(@(v)sprintf('%.6e',v), ...
      res.lambda(near(1:min(5,end))),'UniformOutput',false),' ');
  else
    near5 = '';
  end
  clean = @(t)strrep(strrep(t,',',';'),newline,' ');
  fid = fopen(ctx.iterations_path,'a');
  fprintf(fid,'%s,%d,%.17g,%.17g,%s,%d,%d,"%s","%s","%s",%g,%.17g,%.6e,%.6e,%s,%.6e,', ...
    name,state.count,res.k,res.mu,purpose,hit,res.valid,clean(res.reason_left), ...
    clean(res.reason_right),clean(res.reason_center),index,lam, ...
    abs(lam)/max(1,res.H_norm),gap,near5,res.center_residual);
  fprintf(fid,'%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,', ...
    get(res.cell,'left','backward'),get(res.cell,'right','backward'),get(res.cell,'center','backward'), ...
    get(res.cell,'left','condest'),get(res.cell,'right','condest'),get(res.cell,'center','condest'), ...
    get(res.dtn,'left','unit_gap_min'),get(res.dtn,'right','unit_gap_min'), ...
    get(res.dtn,'left','z0_rcond'),get(res.dtn,'right','z0_rcond'), ...
    get(res.dtn,'left','riccati'),get(res.dtn,'right','riccati'), ...
    get(res.dtn,'left','hermitian_defect'),get(res.dtn,'right','hermitian_defect'), ...
    get(res.dtn,'left','consistency'),get(res.dtn,'right','consistency'), ...
    res.H_hermitian_defect,res.H_norm);
  if hit, times = [0,0,0,0]; else
    times = [res.times.lead_elimination,res.times.qz_dtn,res.times.extension,res.times.center_small];
  end
  fprintf(fid,'%.6f,%.6f,%.6f,%.6f,%.6f,%.0f,%s\n',times,elapsed,res.rss_bytes,LOCAL_utc());
  fclose(fid);
end

function value = LOCAL_field(s,a,b)
  value = NaN;
  if isfield(s,a) && isfield(s.(a),b) && ~isempty(s.(a).(b)), value = double(s.(a).(b)); end
end

function text = LOCAL_utc()
  text = char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSSSSSXXX'));
end

function summary = LOCAL_band_summary(bands)
  summary = struct();
  for rule = fieldnames(bands)'
    b = bands.(rule{1});
    item = struct('rule',b.rule,'points_per_segment',b.points_per_segment, ...
      'total_points',b.total_points,'total_failures',b.total_failures,'total_dual',b.total_dual, ...
      'total_tolerance_owner',b.total_tolerance_owner,'seconds',b.seconds,'failures',b.failures);
    for name = {'left','center','right'}
      item.(name{1}) = rmfield(b.(name{1}),{'element','xi','eta','weight'});
    end
    summary.(rule{1}) = item;
  end
end

function evidence = LOCAL_evidence(mesh,spaces,embeddings,bands)
  % Fixed geometry, dof/QP/wall maps, embeddings and located band points.
  evidence = struct('mesh',struct(),'spaces',struct([]),'embeddings',struct([]),'bands',struct());
  if isstruct(mesh) && isfield(mesh,'p2_points')
    evidence.mesh = struct('points',mesh.points,'triangles',mesh.triangles, ...
      'p2_points',mesh.p2_points,'triangle_p2',mesh.triangle_p2,'edges',mesh.edges, ...
      'interface_edges',mesh.interface_edges,'interface_theta',mesh.interface_theta, ...
      'interface_cell',mesh.interface_cell,'material',mesh.material,'cell_id',mesh.cell_id, ...
      'det_min',mesh.det_min,'det_ratio',mesh.det_ratio);
  end
  if iscell(spaces)
    for p = 1:numel(spaces)
      if isempty(spaces{p}), continue, end
      sp = spaces{p}; item = struct('p',p,'alpha',sp.alpha,'wall_mass_single',sp.wall_mass_single);
      for name = {'left','center','right'}
        t = sp.(name{1});
        item.(name{1}) = struct('element_ids',t.element_ids,'tri_dofs',t.tri_dofs, ...
          'dof_xy',t.dof_xy,'Qqp',t.Qqp,'free',t.free,'top',t.top,'bottom',t.bottom, ...
          'wall',t.wall,'interior',t.interior);
      end
      evidence.spaces = LOCAL_append(evidence.spaces,item);
    end
  end
  if iscell(embeddings)
    for p = 1:numel(embeddings)
      if isempty(embeddings{p}), continue, end
      evidence.embeddings = LOCAL_append(evidence.embeddings,embeddings{p});
    end
  end
  if isstruct(bands), evidence.bands = bands; end
end

function LOCAL_json(path,value)
  text = jsonencode(LOCAL_jsonable(value),'PrettyPrint',true);
  fid = fopen(path,'w'); assert(fid>=0,'i101:IO','Cannot open JSON output.');
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
  elseif issparse(value)
    value = LOCAL_jsonable(full(value));
  elseif isnumeric(value) && ~isreal(value)
    value = struct('real',real(value),'imag',imag(value));
  end
end

%% ==================== P2 geometry algebra (from I9.5b) ====================
% Geometry basis, Gauss-Duffy quadrature and Jacobian determinant extrema.
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
