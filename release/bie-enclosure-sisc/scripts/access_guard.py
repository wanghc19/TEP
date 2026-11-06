"""Record Python file reads and optionally reject a forbidden source tree.
Input: output ledger directory and forbidden root. Output: JSON-lines ledger.
Installed before canonical data, reference data and scientific modules are read.
CPython open/import audit events cover Python-managed file access; this is not
an operating-system tracing facility for internal C-library file operations.
"""
import json,os,sys
from pathlib import Path

def install(out,forbidden=None):
  out=Path(out).resolve();root=Path(forbidden).resolve() if forbidden else None
  seen=set();busy=False
  def hook(event,args):
    nonlocal busy
    if busy:return
    if event=='open':
      path=args[0];mode=args[1];flags=args[2]
      if not isinstance(path,(str,bytes,os.PathLike)):return
      if (isinstance(mode,str) and any(c in mode for c in 'wax+')) or (isinstance(flags,int) and flags&(os.O_WRONLY|os.O_RDWR|os.O_CREAT)):return
    elif event=='import' and len(args)>1 and isinstance(args[1],str):path=args[1]
    else:return
    path=Path(os.fsdecode(path)).absolute();key=(os.getpid(),str(path))
    if key in seen:return
    seen.add(key);busy=True
    try:
      if root and path.resolve().is_relative_to(root):raise RuntimeError('Forbidden repository read: '+str(path))
      with (out/'driver-opened-files.jsonl').open('a') as f:f.write(json.dumps(dict(pid=os.getpid(),event=event,path=str(path)))+'\n')
    finally:busy=False
  sys.addaudithook(hook)
