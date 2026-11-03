"""Build the local Goerisch pipeline with certificate diagnostics.
Input: retained pipeline-base.txt and certificate helper source. Output: direct_pipeline.m.
"""
from pathlib import Path
h=Path(__file__).resolve().parent;s=(h/'pipeline-base.txt').read_text()
s=s.replace("case 'config',", "case 'inventory',varargout{1}=LOCAL_inventory(varargin{:});\n    case 'exact_flux',[varargout{1:nargout}]=LOCAL_exact_flux(varargin{:});\n    case 'certificates',varargout{1}=LOCAL_certificates(varargin{:});\n    case 'config',",1)
s=s.replace("'global_residual',residual,'cache_hits',hits)","'global_residual',residual,'cache_hits',hits,'master_edges',{cell(1,3)},'master_wall',z)")
s=s.replace("    clear factor Aip", "    S.master_edges{t}=ye;\n    clear factor Aip",1)
s+='\n'+(h/'qj_extensions.txt').read_text()
(h/'direct_pipeline.m').write_text(s)
