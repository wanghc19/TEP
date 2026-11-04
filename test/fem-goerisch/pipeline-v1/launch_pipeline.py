"""Launch one explicit example through the local process-tree monitor.
Input: example function name, accuracy setting, output directory, MATLAB path.
Output: compact reports, monitor records and logs; no shared cumulative budget.
"""
import argparse,json,os,sys,time
from pathlib import Path
from monitor import run
from write_intervals import process

p=argparse.ArgumentParser()
p.add_argument('--example',required=True)
p.add_argument('--setting',choices=['original','fast'],required=True)
p.add_argument('--output',type=Path,required=True)
p.add_argument('--matlab',type=Path,required=True)
a=p.parse_args();base=Path(__file__).resolve().parent;out=a.output.resolve()
if not a.example.isidentifier() or not (base/'examples'/f'{a.example}.m').is_file():
  p.error('Example must name an explicit function in examples/.')
if out.exists():p.error('Use a fresh output/run-NNN directory; previous runs are preserved.')
if not out.is_relative_to(base/'output'):p.error('Output must lie under this pipeline output directory.')
if not a.matlab.is_absolute() or not a.matlab.is_file():p.error('Supply the explicit MATLAB executable path.')
os.environ['OMP_NUM_THREADS']='11';os.environ['OMP_DYNAMIC']='FALSE'
os.environ['VECLIB_MAXIMUM_THREADS']='11'
def quote(x):return "'"+str(x).replace("'","''")+"'"
expression="addpath("+','.join(quote(base/x) for x in ['', 'internal','examples'])+");run_pipeline("+a.example+"(),"+quote(a.setting)+","+quote(out)+");"
started=time.monotonic()
r=run(out,expression,soft=1800,hard=2400,matlab_path=str(a.matlab))
if r['returncode'] or r['reason']!='completed':sys.exit(1)
s=json.loads((out/'summary.json').read_text())
if s['status']=='COMPLETE':
  t=time.monotonic();process(out);post=time.monotonic()-t
  ledger={'monitored_wall_seconds':r['wall_seconds'],'matlab_pipeline_seconds':s['seconds'],
    'startup_and_shutdown_seconds':r['wall_seconds']-s['seconds'],'python_postprocessing_seconds':post,
    'launcher_seconds':time.monotonic()-started,'stage_sum_seconds':sum(s['times'].values()),
    'stage_sum_difference':sum(s['times'].values())-s['seconds'],'peak_process_tree_rss_gib':r['peak_process_tree_rss_gib']}
  (out/'timing.json').write_text(json.dumps(ledger,indent=2)+'\n')
  assert abs(ledger['stage_sum_difference'])<.1
print(s['status'])
