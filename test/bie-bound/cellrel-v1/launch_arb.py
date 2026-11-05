"""Launch an explicit Arb (real ball arithmetic) or Acb computation.
Input: output, script, Conda path and arguments. Output: monitored artifacts.
"""
import argparse,sys,os
from pathlib import Path
from monitor_arb import run
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--conda',required=True);p.add_argument('--script',required=True);p.add_argument('--forecast',type=float,required=True);p.add_argument('settings',nargs=argparse.REMAINDER);a=p.parse_args()
if a.output.exists():raise RuntimeError('Use a fresh output directory')
assert a.forecast<1800
os.environ.update(OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',OMP_DYNAMIC='FALSE',PYTHONDONTWRITEBYTECODE='1')
extra=a.settings[1:] if a.settings[:1]==['--'] else a.settings
cmd=[a.conda,'run','--no-capture-output','-n','octave','python','-I',str(Path(__file__).resolve().parent/a.script),'--output',str(a.output.resolve())]+extra
r=run(a.output,cmd);sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
