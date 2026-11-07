function report=verify_integrals(data,out)
  % VERIFY_INTEGRALS Reintegrate the canonical finite element field and RT3 flux.
  % Input
  %   data: explicit native.mat and flux.mat directory; out: fresh directory.
  % Output
  %   E/M/S and intervals recomputed without search, eigenpair or flux solve.
  if ~isfolder(out),mkdir(out);end;started=tic;tm=struct();
  t=tic;x=fem_read('mat',fullfile(data,'native.mat'),'native','example');y=fem_read('mat',fullfile(data,'flux.mat'),'canonical_flux');
  example=x.example;validate_example(example);
  assert(example.model.rho_center==4,'fem:Example','This package supplies isolation only for reference center density 4.');cfg=direct_pipeline('config','in-memory','D',example);
  maxNumCompThreads(example.resources.threads);opts=example.discretization.original;
  pm('configure',example.discretization.polynomial_degree,example.discretization.series_order);inverse_iteration_count(opts.inverse_iterations);
  P=direct_pipeline('prepare',cfg,x.native);clear x;N=y.canonical_flux;clear y;tm.load_prepare=toc(t);
  t=tic;trace=LOCAL_flux_trace(P,N,cfg);tm.trace=toc(t);assert(trace.pass,'fem:FluxTrace','Canonical flux is not conforming.');
  t=tic;inventory=direct_pipeline('inventory',P,N,cfg);tm.inventory=toc(t);LOCAL_json(out,'inventory.json',inventory);
  t=tic;common=direct_pipeline('certificates',P,N,cfg,out,inventory);tm.common=toc(t);LOCAL_json(out,'common-certificates.json',common);
  for j=1:3,P.templates{j}.cache={};end
  t=tic;quad=interface_quadrature(P,N,cfg,'full');tm.quadrature=toc(t);LOCAL_json(out,'interface-quadrature.json',quad);
  t=tic;iface=interface_certificate(P,N,cfg,common,inventory,out,'full',opts);tm.interface=toc(t);
  integrals=struct('E',common.E,'M',iface.M,'S_upper',iface.S_upper,'S_common',common.S_smooth, ...
    'S_interface_upper',iface.S_interface_upper,'s',P.q,'gamma',cfg.gamma,'alpha_minus',cfg.alpha_minus, ...
    'alpha_plus',cfg.alpha_plus,'signs',iface.full_interval.signs,'sign_conditions',iface.full_interval.pass, ...
    'interface_contains_Q16',iface.contains_Q16,'interface_contains_Q24',iface.contains_Q24,'rounding_covered',false);
  LOCAL_json(out,'integrals.json',integrals);
  assert(iface.contains_Q16&&iface.contains_Q24&&iface.full_interval.pass&&common.E_contains_Q24&&common.M_contains_Q24);
  a=cfg.gamma+integrals.E(1)/integrals.M(2);b=cfg.gamma+integrals.E(2)/integrals.M(1);d=b*integrals.S_upper/integrals.M(1);
  ends=[a*(1+d/2-sqrt(d+d^2/4))-cfg.gamma,b*(1+d/2+sqrt(d+d^2/4))-cfg.gamma];
  interval=struct('I_1',struct('endpoints',ends,'width',diff(ends)),'four_corner',iface.full_interval,'rounding_covered',false);
  LOCAL_json(out,'interval.json',interval);LOCAL_json(out,'exact-flux.json',struct('vertical_master_moment',trace.outer,'shared_master_reconstruction_difference',trace.shared));
  old=jsondecode(fem_read('text',fullfile(data,'integrals.json')));fields={'E','M','S_upper','s'};same=true;
  for j=1:numel(fields),same=same&&isequal(integrals.(fields{j})(:),old.(fields{j})(:));end
  wrong=example;wrong.model.beta=wrong.model.beta+.01;rejected=false;
  try,validate_example(wrong);catch err,rejected=strcmp(err.identifier,'pipeline:Unsupported');end
  report=struct('exact_integral_match',same,'deliberate_wrong_phase_rejected',rejected,'trace',trace,'seconds',toc(started),'times',tm,'pass',same&&rejected&&trace.pass);
  LOCAL_json(out,'verification.json',report);assert(report.pass,'fem:Verify','Canonical integral reproduction failed.');
end
function r=LOCAL_flux_trace(P,N,cfg)
  % Input: actual coefficients and topology. Output: shared and boundary moments.
  assert(isequal(N.B,exact_rt3_basis()));shared=0;wall=cell(1,2*cfg.K+1);
  for t=1:3
    G=P.templates{t}.G;F=N.flux{t};nt=G.nt;nc=numel(G.cells);
    assert(all(isfinite(F),'all'));map=G.map.';phase=G.phase.';
    for j=1:nc
      v=reshape(F(1:12,j,:),12,nt)./phase;means=accumarray(map(:),v(:),[G.nedge,1],@mean);
      shared=max(shared,max(abs(v-means(map)),[],'all'));
      wall{G.cells(j)+cfg.K+1}=[means(G.left),means(G.right)];
    end
  end
  between=0;for j=1:numel(wall)-1,between=max(between,max(abs(wall{j}(:,2)-wall{j+1}(:,1))));end
  outer=max([abs(wall{1}(:,1));abs(wall{end}(:,2))]);
  r=struct('shared',shared,'cell_interfaces',between,'outer',outer,'pass',shared<1e-10&&between<1e-10&&outer==0);
end
function LOCAL_json(out,name,x)
  % Input: output directory, name and value. Output: JSON document.
  f=fopen(fullfile(out,name),'w');fwrite(f,jsonencode(x,PrettyPrint=true));fclose(f);
end
