"""Write explicit finite element certificate handoff paths.
Input: numerical certificate paths and destination JSON; no documentation reads.
Output: the supplied absolute paths, for a run directory rather than references.
"""
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser()
for k in ['band','surface','left','right','interval']:p.add_argument('--'+k,type=Path)
p.add_argument('--output',type=Path,required=True);a=p.parse_args();d={}
for k in ['band','surface','left','right','interval']:
  x=getattr(a,k)
  if x is not None:assert x.is_file();d[k]=str(x.resolve())
a.output.write_text(json.dumps(d,indent=2)+'\n')
