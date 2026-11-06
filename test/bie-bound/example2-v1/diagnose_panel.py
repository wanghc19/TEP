"""Diagnose a material panel with explicit exact field and fit inputs.
Input: field, coefficients, output, side and panel. Output: gate operands and target record.
"""
import argparse,json,sys,time,traceback,gzip
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent/'residual'))
from flint import ctx
import groups,lead_self
from group_setup import prepare
p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--coefficients',required=True);p.add_argument('--output',required=True);p.add_argument('--side',type=int,default=2);p.add_argument('--panel',type=int,default=14);a=p.parse_args()
out=Path(a.output);out.mkdir(exist_ok=True,parents=True);start=time.perf_counter();ctx.prec=128;ctx.cap=81
lead_self.DIAGNOSTIC=out/'gate-operands.json'
def read(path):
  p=Path(path)
  obj=json.loads(gzip.decompress(p.read_bytes()) if p.suffix=='.gz' else p.read_text())
  return read(p.parent/obj['archive']) if 'archive' in obj else obj
groups.DATA=read(a.input);groups.FITS=read(a.coefficients);groups.OUT=out
groups.SHARED=prepare(groups.DATA,groups.FITS,80)
r=groups.task(('material',a.side,a.panel));(out/'diagnosis.json').write_text(json.dumps(dict(seconds=time.perf_counter()-start,result=r,q_max=str(lead_self.Q_MAX),q_count=lead_self.Q_COUNT),indent=2));assert r['passed'],r.get('error')
