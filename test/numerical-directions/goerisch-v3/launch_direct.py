"""Launch direct-only benchmarks through the unchanged monitor.
FEM means finite element method; RSS means resident set size.
Input: explicit scientific input, output, monitor paths and FEM degree.
Output: small command, timing, log and monitoring records.
"""
import argparse,json,subprocess,time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True);p.add_argument('--monitor',required=True);p.add_argument('--degree',type=int,choices=[2,3,4],required=True);p.add_argument('--forecast',type=float,required=True)
p.add_argument('--flux-degrees',type=int,nargs='+',choices=[1,2,3,4],default=None)
a=p.parse_args();root=Path(__file__).resolve().parent;out=Path(a.output).resolve();assert not out.exists()
used=sum(json.loads(f.read_text())['wall_seconds'] for f in (root/'output').glob('run-*/monitor.json'))
assert used+a.forecast<1800,('Complete-run forecast exceeds shared soft budget',used,a.forecast)
quote=lambda x:"'"+str(x).replace("'","''")+"'"
flux=a.flux_degrees or ([3,2] if a.degree==2 else [2]);flux_literal='['+','.join(map(str,flux))+']'
start=time.time();expr=f"addpath({quote(root)}); direct_benchmark({quote(Path(a.input).resolve())},{quote(out/'science')},{a.degree},{start:.9f},{flux_literal});"
driver="import runpy,sys; ns=runpy.run_path(sys.argv[1]); r=ns['run'](sys.argv[2],sys.argv[3],soft=float(sys.argv[4]),hard=float(sys.argv[5])); sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)"
code=subprocess.call(['python3','-c',driver,str(Path(a.monitor).resolve()),str(out),expr,str(1800-used),str(2400-used)]);end=time.time()
r={'returncode':code,'forecast_seconds':a.forecast,'prior_monitored_seconds':used,'wrapper_wall_seconds':end-start}
if (out/'monitor.json').exists():
    m=json.loads((out/'monitor.json').read_text());r['monitor']=m;r['cumulative_monitored_seconds']=used+m['wall_seconds'];r['wrapper_minus_monitor_seconds']=end-start-m['wall_seconds']
if (out/'science/result.json').exists() and (out/'science/finish.json').exists():
    b=json.loads((out/'science/result.json').read_text());f=json.loads((out/'science/finish.json').read_text())
    r.update({'status':b['status'],'startup_seconds':b['startup_seconds'],'function_seconds':f['function_seconds'],'shutdown_seconds':end-f['finish_epoch'],'stage_timing':b['timing'],'final_output_seconds':f['function_seconds']-b['function_elapsed_seconds']})
    r['reconciled_wrapper_seconds']=b['startup_seconds']+f['function_seconds']+r['shutdown_seconds'];r['reconciliation_error_seconds']=r['reconciled_wrapper_seconds']-(end-start);r['timing_pass']=abs(r['reconciliation_error_seconds'])<=max(.1,.01*(end-start))
(out/'launcher.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2));raise SystemExit(code)
