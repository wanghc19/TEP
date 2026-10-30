function extract_mode_inputs(bie_file,fem_file,recovery_dir,output_file)
%EXTRACT_MODE_INPUTS Extract only saved numerical state for field comparison.
% Purpose: Keep the original BIE and FEM files read-only and avoid retaining
%   assembly and residual arrays during the cross-method field evaluation.
% Input: Explicit BIE/FEM MAT paths, recovery directory and output MAT path.
% Output: Compact saved physical field state, with no root or matrix rebuild.
% Based on: I9.2 evidence schema and I10.1 saved P4 recovery schema only.
% Main changes: New data adapter; no production numerical algorithm is copied.
  timer = tic;
  source = load(bie_file,'evidence');
  e = source.evidence; b = e.base;
  bie = struct('model',b.model,'q',b.q,'beta_m',b.beta_m,'gamma',b.gamma, ...
    'center_density',e.center_density,'propagation',e.propagation);
  for name = {'center','negative','positive'}
    c = b.(name{1});
    item = struct('C',c.i9_geometry,'pars',c.i9_pars,'proxy',c.i9_proxy, ...
      'rho',c.rho,'kint',c.kint,'kext',c.kext);
    if ~strcmp(name{1},'center'), item.H = [c.H_L,c.H_R]; end
    bie.(name{1}) = item;
  end
  clear source e b c
  source = load(fem_file,'evidence','config');
  fem = struct('model',source.config.model,'mesh',source.evidence.mesh, ...
    'space',source.evidence.spaces([source.evidence.spaces.p]==4));
  clear source
  for name = {'center','left','right'}
    fem.(name{1}) = load(fullfile(recovery_dir,['recovery-P4-check-',name{1},'.mat']));
  end
  save(output_file,'bie','fem','-v7');
  fprintf('Extracted k_B=%.17g k_F=%.17g in %.2f s\n',bie.model.khat,fem.center.k,toc(timer));
  disp(fieldnames(bie.propagation));
  disp(fieldnames(fem.mesh));
  disp(size(bie.negative.H));
  disp(size(fem.space.left.tri_dofs));
end
