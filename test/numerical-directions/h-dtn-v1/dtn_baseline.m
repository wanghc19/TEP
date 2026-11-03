function dtn_baseline(out)
% DtN means Dirichlet-to-Neumann: reproduce copied P3 field generation.
% Input: output directory. Output: small baseline JSON and native diagnostics.
  if ~exist(out,'dir'),mkdir(out);end
  [~,r]=dtn_native('generate',1.5584630910866906,out,3);
  value=struct('k',r.frequency,'reference',1.5584378944019319, ...
    'relative_difference',abs(r.frequency/1.5584378944019319-1));
  assert(value.relative_difference<1e-12);
  f=fopen(fullfile(out,'baseline.json'),'w');fprintf(f,'%s\n',jsonencode(value));fclose(f);
end
