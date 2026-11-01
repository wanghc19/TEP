"""Launch through the unchanged monitor. RSS means resident set size.
Input: explicit input, output, and monitor paths, and R/D trial.
Output: compact run records. No field arrays are saved.
"""
import argparse,json,subprocess,time
from pathlib import Path
p=argparse.ArgumentParser()
p.add_argument('--input',required=True);p.add_argument('--output',required=True)
p.add_argument('--monitor',required=True);p.add_argument('--trial',choices=['R','D'],required=True)
a=p.parse_args();out=Path(a.output).resolve();assert not out.exists(),out
root=Path(__file__).resolve().parent
# The entire comparison shares one budget, even if a development run failed.
used=sum(json.loads(f.read_text())['wall_seconds'] for f in (root/'output').glob('run-*/monitor.json'))
forecast=180 if a.trial=='D' else 600
assert used+forecast<1800,('Shared soft budget would be exceeded',used,forecast)
quote=lambda s:"'"+str(s).replace("'","''")+"'"
start=time.time()
expr=f"addpath({quote(root)}); pipeline_benchmark({quote(Path(a.input).resolve())},{quote(out/'science')},{quote(a.trial)},{start:.9f});"
driver="import runpy,sys; ns=runpy.run_path(sys.argv[1]); r=ns['run'](sys.argv[2],sys.argv[3],soft=float(sys.argv[4]),hard=float(sys.argv[5])); sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)"
command=['python3','-c',driver,str(Path(a.monitor).resolve()),str(out),expr,str(1800-used),str(2400-used)]
code=subprocess.call(command);end=time.time()
record={'returncode':code,'wrapper_wall_seconds':end-start,'prior_monitored_seconds':used,'forecast_seconds':forecast}
if (out/'monitor.json').exists():
    mon=json.loads((out/'monitor.json').read_text());record['monitor']=mon
    record['wrapper_minus_monitor_seconds']=end-start-mon['wall_seconds']
    record['cumulative_monitored_seconds']=used+mon['wall_seconds']
if (out/'science/result.json').exists():
    r=json.loads((out/'science/result.json').read_text());f=json.loads((out/'science/finish.json').read_text())
    record['cold_production_seconds']=r['cold_production_seconds'];record['additional_verification_seconds']=r['verification_seconds']
    record['matlab_finalization_output_seconds']=f['function_seconds']-r['function_before_final_output_seconds']
    record['function_postverification_orchestration_seconds']=r['function_before_final_output_seconds']-r['production_seconds']-r['verification_seconds']
    record['startup_clock_timer_difference_seconds']=(r['ready_epoch']-r['entry_epoch'])-r['production_seconds']
    record['shutdown_and_monitor_tail_seconds']=end-f['finish_epoch']
    record['reconciled_wrapper_seconds']=r['startup_to_entry_seconds']+f['function_seconds']+record['shutdown_and_monitor_tail_seconds']
    record['reconciliation_error_seconds']=record['reconciled_wrapper_seconds']-record['wrapper_wall_seconds']
    record['reconciliation_pass']=abs(record['reconciliation_error_seconds'])<=max(.1,.01*record['wrapper_wall_seconds'])
(out/'launcher.json').write_text(json.dumps(record,indent=2))
print(json.dumps(record,indent=2));raise SystemExit(code)
