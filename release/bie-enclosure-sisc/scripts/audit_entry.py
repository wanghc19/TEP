# Copied from test/bie-bound/pipeline-v1/audit_entry.py; release R1 path/data interfaces may be adapted.
"""Run a numerical entry point with a same-run scientific input guard.
Input: run root, entry script and its explicit arguments.
Output: per-process file-read ledger; reject earlier experiment data reads.
"""
import argparse,json,os,sys,runpy
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--run-root',required=True);p.add_argument('--entry',required=True);p.add_argument('--allowed-data',action='append',default=[]);p.add_argument('--forbid-root');p.add_argument('args',nargs=argparse.REMAINDER);a=p.parse_args()
root=Path(a.run_root).resolve();entry=Path(a.entry).resolve();seen=set();busy=False

def audit(event,args):
  global busy
  if event!='open' or busy or not isinstance(args[0],(str,bytes,os.PathLike)):return
  path=Path(os.fsdecode(args[0])).absolute();mode=args[1];flags=args[2]
  writing=(isinstance(mode,str) and any(c in mode for c in 'wax+')) or (isinstance(flags,int) and bool(flags & (os.O_WRONLY|os.O_RDWR|os.O_CREAT)))
  if writing:return
  s=str(path);key=(os.getpid(),s)
  if key in seen:return
  seen.add(key);busy=True
  try:
    numerical=path.suffix.lower() in ['.json','.csv','.mat','.npz','.npy','.h5']
    prior_output=('/test/' in s and '/output/' in s and not path.is_relative_to(root))
    allowed=any(path.resolve().is_relative_to(Path(r).resolve()) for r in a.allowed_data)
    if a.forbid_root and path.resolve().is_relative_to(Path(a.forbid_root).resolve()):raise RuntimeError('Forbidden repository read: '+s)
    if prior_output and numerical and not allowed:raise RuntimeError('Prior experiment data read forbidden: '+s)
    with (root/'opened-files.jsonl').open('a') as f:f.write(json.dumps(dict(pid=os.getpid(),path=s,numerical=numerical))+'\n')
  finally:busy=False

sys.addaudithook(audit)
sys.path.insert(0,str(entry.parent));sys.argv=[str(entry)]+(a.args[1:] if a.args[:1]==['--'] else a.args)
runpy.run_path(str(entry),run_name='__main__')
