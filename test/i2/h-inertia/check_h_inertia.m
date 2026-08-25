function result = check_h_inertia(attempt)
%CHECK_H_INERTIA Compute the I2.2 Hermitian-part endpoint sign count.
% Purpose:
%   Evaluate the two frozen shoulders with the fine-M48 I2.1 object, measure
%   the raw H departure from its Hermitian part, and count endpoint signs.
% Input:
%   attempt - New output tag; the reviewed tag is 'inertia-a1'.
% Output:
%   result  - Endpoint spectra, sign counts, and corroborative jump status.
% Notes:
%   This is not raw-H inertia, a root locator, or an eigenvalue proof.

  if nargin ~= 1 || ~strcmp(char(attempt),'inertia-a1')
    error('i22:Attempt','The reviewed attempt name is inertia-a1.');
  end
  here = fileparts(mfilename('fullpath'));
  output = fullfile(here,'output',char(attempt));
  if exist(output,'dir') || exist(output,'file')
    error('i22:OutputExists','Output already exists: %s.',output);
  end
  LOCAL_runtime();

  timer = tic; c = LOCAL_config(); rows = LOCAL_selectors(); peak = 0;
  [seed,frame] = eval_i21('seed',c,rows);
  LOCAL_seed_gate(seed,frame,c);
  peak = max(peak,LOCAL_bytes({seed,frame})/2^20);
  labels = {'L','R'}; kvals = [c.k_left,c.k_right];
  endpoints = repmat(LOCAL_empty_endpoint(),2,1);
  for j = 1:2
    node = eval_i21('point',kvals(j),c,frame);
    LOCAL_node_gate(node,kvals(j),frame,c);
    endpoints(j) = LOCAL_endpoint(node,labels{j},c);
    peak = max(peak,LOCAL_bytes({seed,frame,node,endpoints})/2^20);
  end
  oracle = LOCAL_oracle();
  if ~oracle.pass, error('i22:Oracle','The interpretation oracle failed.'); end

  delta_neg = endpoints(2).n_negative-endpoints(1).n_negative;
  delta_pos = endpoints(2).n_positive-endpoints(1).n_positive;
  stable = all(strcmp({endpoints.band_sensitivity},'STABLE'));
  if ~stable || any([endpoints.n_unresolved] > 0)
    outcome = 'UNRESOLVED'; jump_kind = 'UNRESOLVED';
  elseif delta_neg == 0
    outcome = 'NO_JUMP'; jump_kind = 'NO_JUMP';
  elseif abs(delta_neg) == 1
    outcome = 'JUMP'; jump_kind = 'SINGLE_JUMP';
  else
    outcome = 'JUMP'; jump_kind = 'MULTIPLE_JUMP';
  end
  elapsed = toc(timer);
  peak = max(peak,LOCAL_bytes({seed,frame,endpoints})/2^20);
  if elapsed > c.hard_seconds || peak > c.memory_mib_max
    error('i22:Resource','The time or active-object memory gate failed.');
  end
  result = struct( ...
    'experiment_id','I2-H-INERTIA-SURROGATE-V1', ...
    'attempt',char(attempt),'status','I2_2_ENDPOINT_SIGN_COUNT_COMPLETE', ...
    'execution_pass',true,'scientific_outcome',outcome, ...
    'jump_kind',jump_kind,'delta_negative',delta_neg, ...
    'delta_positive',delta_pos,'band_sensitivity', ...
    LOCAL_overall_sensitivity(endpoints), ...
    'raw_inertia_available',false, ...
    'raw_inertia_status','UNAVAILABLE_NON_HERMITIAN', ...
    'surrogate_sign_count_available',true, ...
    'surrogate_method','HERMITIAN_PART_SIGN_COUNT', ...
    'raw_H_definition','AdefD/T', ...
    'Hsym_definition','(H+H'')/2', ...
    'uncertainty_band_definition', ...
    'distance_2+100*n*eps*max(1,scale_2)', ...
    'raw_real_zero_claim',false,'continuous_eigenvalue_claim',false, ...
    'i23_may_proceed',true, ...
    'i23_status','MAY_PROCEED_TO_SEPARATELY_DESIGNED_I2_3', ...
    'claim_boundary','NUMERICAL_CORROBORATION_FINE_M48_ENDPOINTS_ONLY', ...
    'elapsed_seconds',elapsed,'peak_active_mib',peak, ...
    'command',['matlab -batch "addpath(fullfile(pwd,''test'',''i2'',' ...
      '''h-inertia''),fullfile(pwd,''test'',''i2'',''k-count'')); ' ...
      'check_h_inertia(''inertia-a1'');"'], ...
    'retry_history','NONE','endpoints',endpoints, ...
    'interpretation_oracle',oracle);

  if exist(output,'dir') || exist(output,'file')
    error('i22:OutputExists','Output appeared during the run: %s.',output);
  end
  mkdir(output);
  save(fullfile(output,'result.mat'),'result','-v7');
  LOCAL_report(fullfile(output,'report.md'),result);
end

%% ==================== Frozen evaluator inputs ====================
% These values are the reviewed fine-M48 I2.1 inputs and L14 shoulders.

function c = LOCAL_config()
  c = struct('beta',0.5,'d',1.0,'R',0.2,'s',1.0,'X_L',-0.5, ...
    'X_R',0.5,'H',1.1,'proxy_dist',0.2,'M',48,'K',97, ...
    'kstar',1.8327703475952146,'k_left',1.8327701568603514, ...
    'k_right',1.8327705383300779,'hard_seconds',180, ...
    'memory_mib_max',512,'T_rcond_min',1e-8, ...
    'phase_square_separation_min',1e-8, ...
    'identity_residual_max',1e3*194*eps);
  c.level = struct('name','fine','ntot',256,'N_side',160, ...
    'N_top',160,'N_proxy_edge',80,'M_pw',32);
  c.expected = struct('proxy_rows',960,'proxy_columns',450, ...
    'proxy_shifted_rows',1920,'proxy_shifted_columns',450, ...
    'proxy_rank',260,'bie_order',512,'pencil_order',194, ...
    'chart_order',97,'adef_order',194,'graph_order',388);
  c.proxy_rank_ratio=1e-8; c.proxy_rank_gap_min=2;
  c.proxy_projector_repeat_tol=1e-10; c.proxy_rcond_min=1e-8;
  c.proxy_projected_tol=1e-11; c.proxy_full_residual_max=1e-5;
  c.proxy_shifted_residual_max=1e-5; c.proxy_seed_identity_tol=1e-12;
  c.branch_tol=1e-12; c.qz_residual_tol=1e-10; c.qz_overlap_min=0.9;
  c.cross_cluster_margin_min=100*c.K*eps; c.chart_margin_min=100*c.K*eps;
  c.chart_condition_eps_tol=1e-9; c.small_solve_residual_tol=1e3*c.K*eps;
  c.bie_rcond_min=1e-8; c.bie_residual_tol=1e-10;
  c.schur_tol=1e3*c.K*eps; c.dirichlet_rcond_min=1e-8;
  c.participation_min=1e-3; c.lift_residual_tol=1e-10;
end

function rows = LOCAL_selectors()
  rows.plus = [89 41 35 71 92 12 16 10 66 70 93 33 9 69 79 30 36 ...
    62 64 84 95 40 18 91 94 58 61 13 85 90 24 32 42 60 28 74 21 ...
    97 22 55 77 96 38 14 17 2 20 1 67 75 37 43 72 5 80 81 82 7 ...
    68 39 25 19 78 29 6 76 86 59 8 4 65 83 23 31 3 73 57 63 56 ...
    26 88 27 11 87 15 34 54 44 53 45 52 46 51 47 50 48 49];
  rows.minus = [162 132 117 174 103 124 134 140 173 194 101 172 186 ...
    120 167 168 170 178 189 100 153 180 192 110 118 121 125 169 175 ...
    176 185 119 160 164 179 108 113 114 131 165 171 183 193 111 128 ...
    133 139 159 181 190 191 106 129 157 163 135 116 127 155 177 102 ...
    104 126 130 137 156 184 109 138 187 115 136 154 161 166 158 123 ...
    98 122 105 188 112 152 99 182 107 151 141 150 142 149 143 148 ...
    144 147 145 146];
end

%% ==================== Object and sign-count checks ====================
% The following helpers contain the complete numerical acceptance logic.

function LOCAL_runtime()
  names = {'eval_i21','i21_kproxy','kproxy','kchan','kgreen','kbie'};
  for j = 1:numel(names)
    matches = which(names{j},'-all');
    if ischar(matches), matches = cellstr(matches); end
    if numel(matches) ~= 1
      error('i22:MATLABPath','Exactly one %s must be on the path.',names{j});
    end
  end
  solver = which('lsqminnorm');
  if exist('OCTAVE_VERSION','builtin') ~= 0 || isempty(solver) || ...
      ~startsWith(solver,matlabroot)
    error('i22:MATLABRequired','Public MATLAB lsqminnorm is required.');
  end
end

function LOCAL_seed_gate(seed,frame,c)
  ok = seed.k == c.kstar && seed.pass && all([seed.factors.pass]) && ...
    isequal(size(seed.R),[260,260]) && isequal(seed.proxy_shape,[960,450]) && ...
    isequal(seed.proxy_shifted_shape,[1920,450]) && ...
    isequal(size(seed.Aqp),[512,512]) && isequal(size(seed.AdefD),[194,194]) && ...
    isequal(size(frame.Z0_plus),[194,97]) && ...
    isequal(size(frame.Z0_minus),[194,97]) && frame.proxy_chart.r == 260;
  if ~ok, error('i22:SeedGate','The frozen seed/frame gate failed.'); end
end

function LOCAL_node_gate(node,k,frame,c)
  ok = node.k == k && strcmp(node.name,'fine') && node.pass && ...
    node.plus.pass && node.minus.pass && node.branch_port.pass && ...
    node.branch_proxy.pass && node.cp.safe && node.cm.safe && ...
    all([node.factors.pass]) && ...
    strcmp(node.branch_port.fingerprint,frame.port_anchor.fingerprint) && ...
    strcmp(node.branch_proxy.fingerprint,frame.proxy_chart.anchor.fingerprint) && ...
    strcmp(node.proxy_chart.fingerprint,frame.proxy_chart.fingerprint) && ...
    isequal(node.H_plus_rows,frame.rows_plus) && ...
    isequal(node.H_minus_rows,frame.rows_minus) && ...
    isequal(size(node.AdefD),[194,194]) && isequal(size(node.AdefG),[388,388]);
  if ~ok, error('i22:EndpointGate','An endpoint inherited gate failed.'); end
end

function out = LOCAL_endpoint(node,label,c)
  K=c.K; I=eye(K); Gamma=diag(node.gamma(:)); E=diag(node.phase(:));
  T=[I,E;E,I]; N0=[-1i*Gamma,1i*Gamma*E;1i*Gamma*E,-1i*Gamma];
  L=blkdiag(node.cm.Lambda,node.cp.Lambda); A=node.AdefD; H=A/T;
  sum_def=norm(A-(N0-L*T),'fro')/max(1,norm(A,'fro')+ ...
    norm(N0,'fro')+norm(L,'fro')*norm(T,'fro'));
  product_def=norm(A-H*T,'fro')/max(1,norm(A,'fro')+norm(H,'fro')*norm(T,'fro'));
  if rcond(T)<c.T_rcond_min || min(abs(1-node.phase(:).^2))< ...
      c.phase_square_separation_min || max(sum_def,product_def)> ...
      c.identity_residual_max
    error('i22:ObjectGate','A T or A/H equivalence gate failed.');
  end
  out = LOCAL_count(H,label,node.k);
  out.T_rcond=rcond(T); out.min_abs_1_minus_E2=min(abs(1-node.phase(:).^2));
  out.block_identity_defect=sum_def; out.A_HT_defect=product_def;
end

function out = LOCAL_count(H,label,k)
  Hsym=(H+H')/2; n=size(H,1); scale=norm(Hsym,2);
  distance=norm(H-Hsym,2); unit=n*eps*max(1,scale);
  multipliers=[50,100,200]; triples=zeros(3,3); eta=zeros(3,1);
  lambda=eig(Hsym,'vector'); leak=max(abs(imag(lambda)));
  if any(~isfinite(lambda)) || leak>100*unit
    error('i22:SurrogateSpectrum','The Hermitian-part spectrum is unavailable.');
  end
  lambda=real(lambda);
  for q=1:3
    eta(q)=distance+multipliers(q)*unit;
    triples(q,:)=[sum(lambda>eta(q)),sum(lambda<-eta(q)), ...
      sum(abs(lambda)<=eta(q))];
  end
  if any(sum(triples,2) ~= n), error('i22:Count','Count partition failed.'); end
  out=LOCAL_empty_endpoint(); out.label=label; out.k=k; out.dimension=n;
  out.H=H;
  out.scale_2=scale; out.distance_2=distance;
  out.relative_distance_2=distance/max(1,scale);
  out.roundoff_allowance=100*unit; out.eta=eta(2);
  out.relative_eta=eta(2)/max(1,scale); out.imaginary_leakage=leak;
  out.n_positive=triples(2,1); out.n_negative=triples(2,2);
  out.n_unresolved=triples(2,3); out.min_eigenvalue=min(lambda);
  out.max_eigenvalue=max(lambda); out.min_abs_eigenvalue=min(abs(lambda));
  out.eigenvalues=lambda; out.Hsym=Hsym; out.band_multipliers=multipliers;
  out.band_etas=eta; out.band_counts=triples;
  if isequal(triples(1,:),triples(2,:)) && isequal(triples(2,:),triples(3,:))
    out.band_sensitivity='STABLE';
  else
    out.band_sensitivity='UNSTABLE';
  end
end

function out = LOCAL_empty_endpoint()
  out=struct('label','','k',NaN,'dimension',0,'scale_2',NaN, ...
    'distance_2',NaN,'relative_distance_2',NaN, ...
    'roundoff_allowance',NaN,'eta',NaN,'relative_eta',NaN, ...
    'imaginary_leakage',NaN,'n_positive',0,'n_negative',0, ...
    'n_unresolved',0,'min_eigenvalue',NaN,'max_eigenvalue',NaN, ...
    'min_abs_eigenvalue',NaN,'eigenvalues',[],'H',[],'Hsym',[], ...
    'band_multipliers',[],'band_etas',[],'band_counts',[], ...
    'band_sensitivity','','T_rcond',NaN,'min_abs_1_minus_E2',NaN, ...
    'block_identity_defect',NaN,'A_HT_defect',NaN);
end

function out = LOCAL_oracle()
  epsilon=1e-8;
  left=LOCAL_count(-1+1i*epsilon,'oracle-L',-1);
  right=LOCAL_count(1+1i*epsilon,'oracle-R',1);
  delta=right.n_negative-left.n_negative;
  raw_real_zero_claim=false;
  pass=epsilon>0 && imag(-1+1i*epsilon)~=0 && ...
    imag(1+1i*epsilon)~=0 && delta~=0 && ~raw_real_zero_claim;
  out=struct('epsilon',epsilon,'surrogate_jump',delta~=0, ...
    'raw_family','h(k)=k+i*epsilon','delta_negative',delta, ...
    'raw_real_zero_claim',raw_real_zero_claim,'pass',pass);
end

function text = LOCAL_overall_sensitivity(endpoints)
  if all(strcmp({endpoints.band_sensitivity},'STABLE'))
    text='STABLE';
  else
    text='UNSTABLE';
  end
end

function bytes = LOCAL_bytes(values)
  info=whos('values'); bytes=sum([info.bytes]);
end

%% ==================== Compact output ====================
% Only the final result and a short human-readable report are published.

function LOCAL_report(path,r)
  fid=fopen(path,'w');
  if fid<0, error('i22:Report','Cannot create report.md.'); end
  cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid,'# I2.2 Hermitian-part endpoint sign count\n\n');
  fprintf(fid,'- Attempt: `%s`\n',r.attempt);
  fprintf(fid,'- Execution: `PASS`; outcome: `%s` (`%s`)\n', ...
    r.scientific_outcome,r.jump_kind);
  fprintf(fid,'- Band sensitivity (50/100/200): `%s`\n',r.band_sensitivity);
  fprintf(fid,'- Raw-H inertia / real-zero claim: `UNAVAILABLE` / `false`\n');
  fprintf(fid,'- Raw H / Hermitian part: `%s`; `%s`\n', ...
    r.raw_H_definition,r.Hsym_definition);
  fprintf(fid,'- Main unresolved band: `%s`\n',r.uncertainty_band_definition);
  fprintf(fid,'- Delta negative / positive: `%d` / `%d`\n', ...
    r.delta_negative,r.delta_positive);
  fprintf(fid,'- Runtime / active-object peak: `%.3f s` / `%.3f MiB`\n\n', ...
    r.elapsed_seconds,r.peak_active_mib);
  fprintf(fid,['| endpoint | k | s | dH | eta | dH/max(1,s) | ' ...
    'eta/max(1,s) | min eig | max eig | min abs eig | + | - | ? |\n']);
  fprintf(fid,'|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
  for j=1:2
    x=r.endpoints(j);
    fprintf(fid,['| %s | %.17g | %.6e | %.6e | %.6e | %.6e | %.6e | ' ...
      '%.6e | %.6e | %.6e | %d | %d | %d |\n'],x.label,x.k,x.scale_2, ...
      x.distance_2,x.eta,x.relative_distance_2,x.relative_eta, ...
      x.min_eigenvalue,x.max_eigenvalue,x.min_abs_eigenvalue, ...
      x.n_positive,x.n_negative,x.n_unresolved);
  end
  fprintf(fid,['\nCounts apply only to Hsym=(H+H*)/2 and corroborate the ' ...
    'frozen candidate numerically. They do not prove raw-H inertia, a raw ' ...
    'real zero, a continuous eigenvalue, or an error estimate.\n']);
end
