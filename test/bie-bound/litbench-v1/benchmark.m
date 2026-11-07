function result=benchmark(out,mode,n,M)
  % Literature benchmark for the electric-field line-defect mode.
  % Input: fresh output directory, mode, rod density nodes and Rayleigh half-width.
  % Output: candidates in the supplied frequency window, with lead diagnostics.
  s=search_config(11,'production');e=example_parameters('empty');
  if startsWith(mode,'regression')
    s.window=[1.85,1.93]; e.staggered=false;
  else
    h=sqrt(3)/2;e.staggered=true;e.L0=3*h;
    e.L_negative=2*h;e.L_positive=2*h;e.angle_positive=0;e.angle_negative=0;
    e.rho_lead=9;e.a_positive=0;e.a_negative=0;e.R=.2;
    if strcmp(mode,'fundamental')
      e.beta=1.67541;s.window=2*pi*[.314,.326];
    else
      assert(strcmp(mode,'second'));e.beta=.2;s.window=2*pi*[.331,.335];
    end
  end
  e.join_rows=~strcmp(mode,'regression-single');e.lead_nodes=n;e.M=M;s.example=e;r=detsearch(out,s);
  result=struct('mode',mode,'nodes',n,'M',M,'beta',e.beta,'k_window',s.window, ...
    'status',r.status,'candidates',{{}},'gap_samples',r.gap_lead_log,'seconds',r.science_seconds);
  for j=1:numel(r.candidates)
    c=r.candidates{j};idx=find([r.points.k]==c.k & strcmp({r.points.stage},'confirmation'),1,'last');
    if isempty(idx)
      cfg=example_config(e,search_i9_config());ld=search_i9_physics('leads',c.k,'fine',cfg);
      a=ld.negative_diagnostic.reverse;b=ld.positive_diagnostic;
      dist=@(v) min(abs(abs(complex(v.alpha_real,v.alpha_imag)./complex(v.theta_real,v.theta_imag))-1),[],'omitnan');
      distances=[dist(a),dist(b)];
    else
      distances=[r.points(idx).left_unit_distance,r.points(idx).right_unit_distance];
    end
    result.candidates{j}=struct('k',c.k,'normalized_frequency',c.k/(2*pi), ...
      'ratio',c.aphys_ratio,'unit_distance',distances,'fallback',c.fallback_used);
  end
  f=fopen(fullfile(out,'benchmark.json'),'w');fwrite(f,jsonencode(result,PrettyPrint=true));fclose(f);
  if startsWith(mode,'regression')
    assert(numel(r.candidates)==1 && abs(r.candidates{1}.k-1.8916961400527375)<=2e-14,'litbench:Regression','Example 2 candidate differs.');
  end
end
