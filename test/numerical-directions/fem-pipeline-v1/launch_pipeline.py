"""Launch the finite element method (FEM) pipeline with resident set size (RSS) monitoring.
Input: explicit frequency window and new output directory.
Output: compact monitoring and startup/exit accounting records.
"""
import argparse,json,os,runpy,time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--window',type=float,nargs=2,required=True);p.add_argument('--output',required=True)
a=p.parse_args();root=Path(__file__).resolve().parent;out=Path(a.output).resolve();assert not out.exists()
used=sum(json.loads(f.read_text())['wall_seconds'] for f in (root/'output').glob('run-*/monitor.json'))
assert used+300<1800,('Complete-run forecast exceeds shared soft budget',used)
os.environ['OMP_NUM_THREADS']='11';os.environ['OMP_DYNAMIC']='FALSE'
ns=runpy.run_path(str(root.parent/'diagnostics-v1/monitor.py'))
quote=lambda x:"'"+str(x).replace("'","''")+"'"
start=time.time();window='['+','.join(format(x,'.17g') for x in a.window)+']'
expr=f"addpath({quote(root)}); window_pipeline({window},{quote(out/'science')},{start:.9f});"
m=ns['run'](out,expr,soft=1800-used,hard=2400-used);end=time.time()
r={'forecast_seconds':300,'forecast_peak_gib':[2.2,2.7],'prior_monitored_seconds':used,'wrapper_wall_seconds':end-start,'monitor':m,'cumulative_monitored_seconds':used+m['wall_seconds'],'threads':11,'OMP_DYNAMIC':'FALSE'}
r['wrapper_minus_monitor_seconds']=end-start-m['wall_seconds']
if (out/'science/result.json').exists() and (out/'science/finish.json').exists():
 b=json.loads((out/'science/result.json').read_text());f=json.loads((out/'science/finish.json').read_text())
 r.update(status=b['status'],startup_seconds=b['startup_seconds'],function_seconds=f['function_seconds'],output_exit_seconds=end-f['finish_epoch'],stage_timing=b['timing'],final_output_seconds=f['function_seconds']-b['function_elapsed_seconds'])
 r['reconciled_monitor_seconds']=r['startup_seconds']+r['function_seconds']+r['output_exit_seconds']-r['wrapper_minus_monitor_seconds']
 r['reconciliation_error_seconds']=r['reconciled_monitor_seconds']-m['wall_seconds'];r['timing_pass']=abs(r['reconciliation_error_seconds'])<=.1
(out/'launcher.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
raise SystemExit(0 if m['returncode']==0 and m['reason']=='completed' else 1)
