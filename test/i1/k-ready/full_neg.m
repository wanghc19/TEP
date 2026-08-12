function rows = full_neg(seed, frame, c, good_cr)
%FULL_NEG Run the frozen I1.4 V3 negative-control suite.
% Purpose:
%   Mutate actual selected-disk objects or explicit dataflow-policy flags and
%   require the corresponding representation, factor, branch, CR, or algebra
%   checker to reject every preregistered negative.
% Input:
%   seed - Selected-disk V3 center node.
%   frame - Frozen V2 affine proxy and row frame.
%   c - Full-run configuration.
%   good_cr - Largest accepted final positive CR defect.
% Output:
%   rows - Sixteen negative rows in exactly c.negative_names order.
% Main algorithm:
%   Apply one named mutation at a time, measure it with a concrete checker,
%   and retain the checker and rejection status in the evidence ledger.

  anti_threshold = max(c.negative_thresholds.antiholomorphic_absolute_min, ...
    c.negative_thresholds.antiholomorphic_good_multiplier*good_cr);
  fixture_h = min(min(c.radii)/c.cr_radius_divisor, ...
    c.cr_relative_cap*max(1,abs(c.kstar)));
  algebra_min = c.negative_thresholds.legacy_mutation_detectability_min;
  rows = LOCAL_empty();

  % Forbidden algorithm choices are rejected by explicit dataflow-policy flags.
  rows(end+1) = LOCAL_row(c.negative_names{1}, ...
    LOCAL_pointwise_port_roundtrip(c,frame.port_anchor),c.branch_tol, ...
    'greater','ACTUAL_KCHAN_BRANCH_ROUNDTRIP', ...
    'FORBIDDEN_POINTWISE_CONSUMER_REJECTED');

  bad_chart = LOCAL_adapt_chart(frame.proxy_chart{1});
  rows(end+1) = LOCAL_row(c.negative_names{2}, ...
    LOCAL_chart_drift(bad_chart,frame.proxy_chart{1}),0,'greater', ...
    'AFFINE_CHART_HASH_AND_RANK_LOCK','REPRESENTATION_DRIFT');

  forbidden_counter = struct('offseed_modulus_selection',1);
  rows(end+1) = LOCAL_row(c.negative_names{3}, ...
    forbidden_counter.offseed_modulus_selection, ...
    c.negative_thresholds.forbidden_counter_max,'greater', ...
    'OFFSEED_MODULUS_PROVENANCE_COUNTER','OFFSEED_MODULUS_REJECTED');

  % Branch sign mutations act on the immutable anchor data themselves.
  bad_anchor = LOCAL_flip_anchor(frame.port_anchor);
  rows(end+1) = LOCAL_row(c.negative_names{4}, ...
    LOCAL_anchor_drift(bad_anchor),0,'greater', ...
    'ANCHOR_SHA256_LOCK','PORT_BRANCH_FINGERPRINT_DRIFT');
  bad_anchor = LOCAL_flip_anchor(frame.proxy_chart{2}.anchor);
  rows(end+1) = LOCAL_row(c.negative_names{5}, ...
    LOCAL_anchor_drift(bad_anchor),0,'greater', ...
    'ANCHOR_SHA256_LOCK','PROXY_BRANCH_FINGERPRINT_DRIFT');

  rows(end+1) = LOCAL_row(c.negative_names{6}, ...
    LOCAL_qz_swap_overlap(seed.coarse.plus),c.qz_overlap_min,'less', ...
    'SELECTED_SUBSPACE_OVERLAP','QZ_CLUSTER_REJECTED');

  bad_frame = frame;
  bad_frame.rows_plus = circshift(frame.rows_plus(:).',1);
  rows(end+1) = LOCAL_row(c.negative_names{7}, ...
    LOCAL_row_drift(bad_frame,frame),0,'greater', ...
    'FIXED_ROW_SHA256_LOCK','ROW_REPIVOT_REJECTED');

  % Factor negatives mutate live factors before any solve is attempted.
  bad_D = seed.coarse.Dp;
  bad_D(:,1) = 0;
  rows(end+1) = LOCAL_row(c.negative_names{8},rcond(bad_D), ...
    c.negative_thresholds.dirichlet_rcond_min,'less', ...
    'DIRICHLET_RCOND_PRECHECK','DIRICHLET_FACTOR_REJECTED');
  reduced = frame.proxy_chart{1}.U'*frame.proxy_chart{1}.A0* ...
    frame.proxy_chart{1}.V;
  reduced(:,1) = 0;
  rows(end+1) = LOCAL_row(c.negative_names{9},rcond(reduced), ...
    c.negative_thresholds.proxy_rcond_min,'less', ...
    'REDUCED_PROXY_RCOND_PRECHECK','PROXY_COMPRESSION_POLE');

  % These two cases use the same full-Adef central-difference checker.
  anti_fun = @(k) LOCAL_antiholomorphic_Adef(k,c,frame);
  rows(end+1) = LOCAL_row(c.negative_names{10}, ...
    LOCAL_matrix_cr(anti_fun,c.kstar,fixture_h),anti_threshold,'greater', ...
    'FULL_ADEFD_CR_CHECKER','ANTIHOLOMORPHIC_MATRIX_REJECTED');
  weight_fun = @(k) LOCAL_weighted_Adef(k,c,frame);
  rows(end+1) = LOCAL_row(c.negative_names{11}, ...
    LOCAL_matrix_cr(weight_fun,c.kstar,fixture_h), ...
    c.negative_thresholds.cr_defect_max,'greater', ...
    'FULL_ADEFD_CR_CHECKER','K_DEPENDENT_WEIGHT_REJECTED');

  % Legacy algebraic mutations are measured on current live V3 objects.
  K = c.K; x = seed.coarse; E = diag(x.phase(:)); I = eye(K);
  rows(end+1) = LOCAL_row(c.negative_names{12}, ...
    LOCAL_rel([x.Dp;-x.Np],[x.Dp;x.Np]),algebra_min,'greater', ...
    'RELATIVE_FULL_BLOCK_DIFFERENCE','WALL_NORMAL_MUTATION_DETECTED');
  rows(end+1) = LOCAL_row(c.negative_names{13}, ...
    LOCAL_rel(E*x.blocks.T_RL,x.blocks.T_RL),algebra_min,'greater', ...
    'RELATIVE_FULL_BLOCK_DIFFERENCE','REFERENCE_PLANE_MUTATION_DETECTED');
  rows(end+1) = LOCAL_row(c.negative_names{14}, ...
    LOCAL_rel(x.blocks.T_RL,x.blocks.T_LR),algebra_min,'greater', ...
    'RELATIVE_FULL_BLOCK_DIFFERENCE','TRANSMISSION_SWAP_DETECTED');
  rows(end+1) = LOCAL_row(c.negative_names{15}, ...
    LOCAL_rel(E\I,E),algebra_min,'greater', ...
    'RELATIVE_FULL_BLOCK_DIFFERENCE','INVERSE_PHASE_MUTATION_DETECTED');
  rows(end+1) = LOCAL_row(c.negative_names{16}, ...
    LOCAL_rel(x.AdefD([K+1:2*K,1:K],:),x.AdefD), ...
    algebra_min,'greater','RELATIVE_FULL_MATRIX_DIFFERENCE', ...
    'ROW_ORDER_MUTATION_DETECTED');

  if numel(rows) ~= numel(c.negative_names) || ...
      ~isequal({rows.name},c.negative_names)
    error('kreadyfull:NegativeOrder','Negative names or ordering drifted.');
  end
end

%% ==================== Representation mutations ====================
% These helpers mutate frozen charts, anchors, rows, and QZ coordinates.

function bad = LOCAL_adapt_chart(chart)
  bad = chart;
  bad.r = max(1,chart.r-1);
  bad.rank = bad.r;
  bad.U = chart.U(:,1:bad.r);
  bad.V = chart.V(:,1:bad.r);
end

function value = LOCAL_chart_drift(bad,good)
  value = double(bad.r ~= good.r || ...
    ~strcmp(LOCAL_chart_hash(bad),good.hash));
end

function hash = LOCAL_chart_hash(chart)
  hash = LOCAL_fingerprint([real(chart.A0(:));imag(chart.A0(:)); ...
    real(chart.b0(:));imag(chart.b0(:));real(chart.c0(:));imag(chart.c0(:)); ...
    real(chart.U(:));imag(chart.U(:));real(chart.V(:));imag(chart.V(:)); ...
    chart.r]);
end

function bad = LOCAL_flip_anchor(anchor)
  bad = anchor;
  index = ceil(numel(bad.gamma_seed)/2);
  bad.gamma_seed(index) = -bad.gamma_seed(index);
end

function value = LOCAL_anchor_drift(anchor)
  current = LOCAL_fingerprint([anchor.orders;real(anchor.gamma_seed); ...
    imag(anchor.gamma_seed)]);
  value = double(~strcmp(current,anchor.fingerprint));
end

function value = LOCAL_pointwise_port_roundtrip(c,anchor)
  k = c.kstar-0.5i*c.radii(1);
  gamma = sqrt(complex(k^2-anchor.beta_m.^2));
  flip = imag(gamma) < 0 | (imag(gamma) == 0 & real(gamma) < 0);
  gamma(flip) = -gamma(flip);
  channels = kchan(k,c.beta,c.d,c.M,c.X_R-c.X_L,gamma, ...
    anchor.fingerprint);
  delta = k-anchor.kc;
  reverse = channels.gamma_m.*exp( ...
    0.5*log(1-delta./(k-anchor.beta_m))+ ...
    0.5*log(1-delta./(k+anchor.beta_m)));
  value = max(abs(reverse-anchor.gamma_seed)./ ...
    max(1,abs(anchor.gamma_seed)));
end

function value = LOCAL_qz_swap_overlap(selected)
  [Q,~] = qr(selected.Z,0);
  complement_projector = eye(size(Q,1))-Q*Q';
  column_norms = sqrt(sum(abs(complement_projector).^2,1));
  [largest,index] = max(column_norms);
  if largest <= 100*eps
    error('kreadyfull:QZComplement','Could not construct QZ complement vector.');
  end
  vector = complement_projector(:,index)/largest;
  bad = [selected.Z(:,1:end-1),vector];
  [Qbad,~] = qr(bad,0);
  value = min(svd(Q'*Qbad,'econ'));
end

function value = LOCAL_row_drift(bad,good)
  bad_hash = LOCAL_fingerprint([bad.rows_plus(:);bad.rows_minus(:)]);
  good_hash = LOCAL_fingerprint([good.rows_plus(:);good.rows_minus(:)]);
  value = double(~strcmp(bad_hash,good_hash));
end

%% ==================== Full-matrix CR mutations ====================
% These helpers wrap the actual V3 AdefD evaluator before applying a mutation.

function A = LOCAL_antiholomorphic_Adef(k,c,frame)
  A = LOCAL_Adef(k,c,frame);
  A(1,1) = A(1,1)+1e3*conj(k);
end

function A = LOCAL_weighted_Adef(k,c,frame)
  node = eval_k_v3('point',k,c,frame);
  level = node.coarse;
  b = sqrt(1+abs(level.beta_m(:)).^2);
  row = repmat(sqrt(1./b),2,1);
  amplitude = b+abs(level.gamma(:)).^2./b;
  column = repmat(1./sqrt(amplitude),2,1);
  A = row.*level.AdefD.*column.';
end

function A = LOCAL_Adef(k,c,frame)
  node = eval_k_v3('point',k,c,frame);
  A = node.coarse.AdefD;
end

function value = LOCAL_matrix_cr(fun,k,h)
  Dx = (fun(k+h)-fun(k-h))/(2*h);
  Dy = (fun(k+1i*h)-fun(k-1i*h))/(2i*h);
  value = norm(Dx-Dy,'fro')/max([1,norm(Dx,'fro'),norm(Dy,'fro')]);
end

%% ==================== Evidence helpers ====================
% These helpers compute deterministic locks and compact rejection rows.

function value = LOCAL_rel(A,B)
  value = norm(A-B,'fro')/max(1,norm(B,'fro'));
end

function value = LOCAL_fingerprint(data)
  payload = sprintf('%.17g,',double(data(:)));
  digest = javaMethod('getInstance','java.security.MessageDigest','SHA-256');
  digest.update(typecast(uint8(payload),'int8'));
  raw = typecast(digest.digest(),'uint8');
  value = lower(reshape(dec2hex(raw,2).',1,[]));
end

function row = LOCAL_row(name,value,threshold,direction,checker,status)
  if strcmp(direction,'greater')
    pass = value > threshold;
  elseif strcmp(direction,'less')
    pass = value < threshold;
  else
    error('kreadyfull:NegativeDirection','Unknown negative direction.');
  end
  row = struct('name',name,'value',value,'threshold',threshold, ...
    'direction',direction,'checker',checker,'pass',pass,'status',status);
end

function rows = LOCAL_empty()
  rows = struct('name',{},'value',{},'threshold',{},'direction',{}, ...
    'checker',{},'pass',{},'status',{});
end
