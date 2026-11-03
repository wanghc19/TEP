"""Copy the native finite element DtN helpers and add gap scanning only.
Input: retained local direct_native.m. Output: gap_scan_native.m.
"""
from pathlib import Path
here=Path(__file__).resolve().parent
s=(here/'direct_native.m').read_text().replace('function varargout=direct_native(action,varargin)','function varargout=gap_scan_native(action,varargin)',1)
s=s.replace("  assert(strcmp(action,'generate'));", "  if strcmp(action,'scan'),[varargout{1:nargout}]=LOCAL_scan(varargin{:});return,end\n  assert(strcmp(action,'generate'));",1)
s=s.replace("  info.z0_rcond = rcond(Z0);", "  info.z0_rcond = rcond(Z0);\n  singular=svd(Z0);info.z0_smin=min(singular);info.z0_smax=max(singular);",1)
s+=(here/'scan_extension.m').read_text()
(here/'gap_scan_native.m').write_text(s)
