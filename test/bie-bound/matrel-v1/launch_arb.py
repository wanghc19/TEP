"""Run an Arb pilot or certificate within the shared time/RSS limit.
Input: run directory, stage name, Conda executable, explicit calculation arguments.
Output: one fresh monitored stage directory inside the selected run.
"""
import argparse,json,sys
from pathlib import Path
from monitor_arb import run
p=argparse.ArgumentParser();p.add_argument('--run',type=Path,required=True);p.add_argument('--name',required=True);p.add_argument('--conda',required=True);p.add_argument('--script',choices=['material.py','panel.py','disks.py','moment_check.py','audit.py','envelope_check.py'],required=True);p.add_argument('--forecast',type=float,required=True);p.add_argument('settings',nargs=argparse.REMAINDER);a=p.parse_args()
root=a.run.resolve();out=root/a.name
if out.exists():raise RuntimeError('Use a fresh stage directory')
used=sum(json.loads(p.read_text())['wall_seconds'] for p in root.glob('*/monitor.json'));remaining=1800-used
if a.forecast>remaining:raise RuntimeError('Forecast exceeds shared soft budget')
cmd=[a.conda,'run','--no-capture-output','-n','octave','python','-I',str(Path(__file__).resolve().parent/a.script),'--input',str(root/'export/fixed-input.json'),'--output',str(out)]+(a.settings[1:] if a.settings[:1]==['--'] else a.settings)
r=run(out,cmd,soft=remaining,hard=2400-used);sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
