"""Copy required helpers into this experiment. FEM is finite element method.
No protected file is changed. This development script performs no numerical run.
"""
from pathlib import Path
import re
p=Path(__file__).resolve().parent
v2=p.parent/'goerisch-v2'
(p/'goerisch_fitted_geometry.m').write_text((v2/'goerisch_fitted_geometry.m').read_text())
s=(v2/'goerisch_pipeline.m').read_text().replace('function varargout=goerisch_pipeline(', 'function varargout=direct_pipeline(')
s=s.replace("assert(ismember(kind,{'R','D'}));", "assert(strcmp(kind,'D'),'direct:Trial','Only D is enabled.');")
s=s.replace("'threads',2,'basis','stable','compact_condensation',true);", "'threads',2,'basis','stable','compact_condensation',true,'fem_degree',2,'baseline_check',true,'target_width',1.8863227554484077e-7);")
s=s.replace('function P=LOCAL_prepare(cfg)','function P=LOCAL_prepare(cfg,native)')
s=s.replace("  tt=tic;inventory=whos('-file',fullfile(cfg.input_dir,'native.mat'));raw=load(fullfile(cfg.input_dir,'native.mat'),'native');native=raw.native;clear raw", "  tt=tic;inventory=struct('name','native');\n  if nargin<2,inventory=whos('-file',fullfile(cfg.input_dir,'native.mat'));raw=load(fullfile(cfg.input_dir,'native.mat'),'native');native=raw.native;clear raw;end")
s=s.replace('    G=LOCAL_geometry(T,U,cells,cfg,3);G.fitted=', "    if isfield(T,'field_degree')\n      G=LOCAL_geometry(T,zeros(size(T.xy,1),numel(cells)),cells,cfg,3);\n      G=LOCAL_field_coefficients(G,T,U);\n    else,G=LOCAL_geometry(T,U,cells,cfg,3);end\n    G.fitted=")
s=s.replace('    U=complex(zeros(size(T.xy,1),numel(cells)));', "    nd=size(T.xy,1);if isfield(T,'field_degree'),nd=size(T.dof_xy,1);end\n    U=complex(zeros(nd,numel(cells)));")
s=s.replace('    if degree~=3,G=LOCAL_geometry(T,P.templates{t}.U,G.cells,cfg,degree);G.fitted=P.templates{t}.G.fitted;end', "    if degree~=3\n      old=G;G=LOCAL_geometry(T,zeros(size(T.xy,1),numel(G.cells)),G.cells,cfg,degree);G.fitted=old.fitted;\n      if isfield(old,'field_degree'),G.field_degree=old.field_degree;G.field_coefficients=old.field_coefficients;G.field_values=old.field_values;G.field_alpha=old.field_alpha;else,G.mu=old.mu;end\n    end")
s=s.replace('  if S.degree==3\n', '  if cfg.baseline_check && S.degree==3\n')
s=s.replace("    xy=T.xy;xy(:,1)=xy(:,1)-T.cell;", "    xy=T.xy;if isfield(T,'field_degree'),xy=T.dof_xy;end;xy(:,1)=xy(:,1)-T.cell;")
s=s.replace("    case 'cache_check',varargout{1}=LOCAL_cache_check(varargin{:});", "    case 'cache_check',varargout{1}=LOCAL_cache_check(varargin{:});\n    case 'evaluator_check',varargout{1}=LOCAL_evaluator_check(varargin{:});")
s=s.replace("function [values,gx,gy]=LOCAL_direct(G,e,x,y,PX,J,det,cfg)\n", "function [values,gx,gy]=LOCAL_direct(G,e,x,y,PX,J,det,cfg)\n  if isfield(G,'field_degree')\n    [values,gx,gy]=LOCAL_direct_high(G,e,x,y,PX,J,det,cfg);return\n  end\n")
s=s.replace("  S.cell_residual=zeros(1,3);", "  S.cell_residual=zeros(1,3);S.outer_normal_moment=max(abs(z([1:nwall,end-nwall+1:end])));\n  S.unknowns=struct('degree',degree,'global_wall_free',numel(free),'template_edges',cellfun(@(x)x.G.nedge,packs),'template_interiors',cellfun(@(x)x.G.ni*x.G.nt,packs));\n  assert(S.outer_normal_moment==0,'direct:OuterFlux','Outer normal moments are nonzero.');")
s=s.replace('  result.normal_trace_error=S.trace_error;', '  result.outer_normal_moment=S.outer_normal_moment;result.flux_unknowns=S.unknowns;\n  result.normal_trace_error=S.trace_error;')
(p/'direct_pipeline.m').write_text(s)
# Copy only reachable I10.2 local functions needed by generation and independent basis checks.
s=(p.parents[1]/'i10/refine-v1/refine_i102.m').read_text()
starts=list(re.finditer(r'^function .*$',s,re.M));func={}
for i,m in enumerate(starts):
 line=m.group();q=re.search(r'(LOCAL_\w+)\(',line)
 if q:func[q.group(1)]=s[m.start():starts[i+1].start() if i+1<len(starts) else len(s)]
need={'LOCAL_mesh','LOCAL_space','LOCAL_basis_checks','LOCAL_edge_traces','LOCAL_band_locate','LOCAL_operators','LOCAL_chain_stub','LOCAL_chain','LOCAL_evaluate','LOCAL_iteration_header','LOCAL_iteration_row','LOCAL_ledger','LOCAL_lattice','LOCAL_lagrange'}
while True:
 more=set(need)
 for n in need:more.update(x for x in re.findall(r'\bLOCAL_\w+(?=\()',func[n]) if x in func)
 if more==need:break
 need=more
text=''.join(func[n] for n in func if n in need)
text=text.replace("  temporary = [ctx.progress_path,'.tmp'];\n  LOCAL_json(temporary,value); movefile(temporary,ctx.progress_path,'f');", "  LOCAL_json(ctx.progress_path,value);")
(p/'native_helpers.txt').write_text(text)
s=(p.parents[1]/'i10/refine-v1/refine_i102_config.m').read_text().replace('function config = refine_i102_config(', 'function config = direct_native_config(')
(p/'direct_native_config.m').write_text(s)
print('Copied native functions:',len(need))
