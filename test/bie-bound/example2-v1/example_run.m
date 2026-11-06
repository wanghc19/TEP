function result=example_run(out,mode,e)
%EXAMPLE_RUN B1 search and field export, or reference regression.
% Input: fresh output directory, mode, explicit example.
% Output: compact search, field and check records; no old outputs read.
  maxNumCompThreads(11);started=tic;
  s=search_config(11,'production');s.example=e;
  mkdir(fullfile(out,'search'));r=detsearch(fullfile(out,'search'),s);
  result.example=e;result.search_seconds=toc(started);result.candidate_count=numel(r.candidates);
  if numel(r.candidates)~=1
    result.status='CANDIDATE_COUNT';LOCAL_json(fullfile(out,'result.json'),result);return;
  end
  k=r.candidates{1}.k;result.candidate=r.candidates{1};
  c=example_config(e,search_i9_config());ld=search_i9_physics('leads',k,'fine',c);
  [~,v]=search_i9_physics('match',k,'fine',c,ld);
  result.singular_values=v.matching.singular_values(end-1:end);
  result.wood_distance=min(abs(ld.channels.gamma_m));
  probes=[];
  for h=[-1e-7,1e-7]
    l=search_i9_physics('leads',k+h,'fine',c);[~,v]=search_i9_physics('match',k+h,'fine',c,l);
    [~,U,P]=lu(v.matching.Adef);z=diag(U);probes=[probes;k+h,sum(log(abs(z))),angle(det(P)*prod(z./abs(z)))];
  end
  result.root_probes=probes;
  mkdir(fullfile(out,'field'));f=field_export(fullfile(out,'field'),k,'reference',e);result.field=f;
  if strcmp(mode,'regression')
    mkdir(fullfile(out,'reference-field'));reference_field_export(fullfile(out,'reference-field'),k,'reference');
    a=jsondecode(fileread(fullfile(out,'field','fixed-input.json')));b=jsondecode(fileread(fullfile(out,'reference-field','fixed-input.json')));
    result.regression.k_hex=num2hex(k);result.regression.expected_hex='3ff8ef5c92c5bf30';errs=[];
    for j=1:3
      for key={'tau_coeff','zeta_coeff'}
        if iscell(a.pieces),aa=a.pieces{j};else,aa=a.pieces(j);end
        if iscell(b.pieces),bb=b.pieces{j};else,bb=b.pieces(j);end
        x=LOCAL_unpack(aa.(key{1}));y=LOCAL_unpack(bb.(key{1}));errs(end+1)=norm(x-y)/norm(y);
      end
    end
    result.regression.coefficient_relative_errors=errs;
    result.regression.pass=strcmp(num2hex(k),result.regression.expected_hex)&&max(errs)<=1e-13;
  end
  result.status='COMPLETE';result.seconds=toc(started);LOCAL_json(fullfile(out,'result.json'),result);
  if strcmp(mode,'regression'),assert(result.regression.pass,'example2:Regression','Reference regression failed.');end
end
function x=LOCAL_unpack(a)
% Input: exact binary64 export. Output: complex column.
  x=complex(hex2num(char(a.real)),hex2num(char(a.imag)));
end
function LOCAL_json(path,x)
% Input: output path and record. Output: JSON file.
  f=fopen(path,'w');cl=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(x));
end
