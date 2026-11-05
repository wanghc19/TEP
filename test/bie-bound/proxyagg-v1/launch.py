"""Launch an explicit proxy-aggregation run with process-tree monitoring.
Input: scientific input/output, numerical settings and forecast. Output: monitor records.
"""
import argparse,json,sys
from pathlib import Path
from monitor_arb import run
p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',type=Path,required=True)
p.add_argument('--conda',required=True);p.add_argument('--forecast',type=float,required=True);p.add_argument('--script',default='run_full.py')
p.add_argument('--soft',type=float,default=1800);p.add_argument('--hard',type=float,default=2400);p.add_argument('settings',nargs=argparse.REMAINDER);a=p.parse_args()
if a.output.exists():raise RuntimeError('Use a fresh output directory')
assert a.forecast<a.soft<=1800 and a.soft<a.hard<=2400
settings=a.settings[1:] if a.settings[:1]==['--'] else a.settings
cmd=[a.conda,'run','--no-capture-output','-n','octave','python','-I',str(Path(__file__).resolve().parent/a.script),'--input',str(Path(a.input).resolve()),'--output',str(a.output.resolve())]+settings
r=run(a.output,cmd,soft=a.soft,hard=a.hard);sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
