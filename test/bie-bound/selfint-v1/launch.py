"""Launch explicit self-interaction runs under the shared time/RSS monitor.
Input: run output, exact input, script settings. Output: logs and monitor records.
"""
import argparse,json,sys
from pathlib import Path
from monitor_arb import run
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--input',type=Path,required=True)
p.add_argument('--conda',required=True);p.add_argument('--forecast',type=float,required=True)
p.add_argument('--script',default='panel.py');p.add_argument('settings',nargs=argparse.REMAINDER);a=p.parse_args()
if a.output.exists():raise RuntimeError('Use a fresh output directory')
used=sum(json.loads(f.read_text())['wall_seconds'] for f in Path(__file__).parent.glob('output/run-*/*/monitor.json'))
if a.forecast>1800-used:raise RuntimeError('Forecast exceeds remaining shared soft budget')
cmd=[a.conda,'run','--no-capture-output','-n','octave','python','-I',str(Path(__file__).resolve().parent/a.script),'--input',str(a.input.resolve()),'--output',str(a.output.resolve())]+(a.settings[1:] if a.settings[:1]==['--'] else a.settings)
r=run(a.output,cmd,soft=1800-used,hard=2400-used);sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
