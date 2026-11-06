"""Serial resolution-study launches with per-result forecasts and monitoring.
Input: explicit scientific-code/library paths and output parent.
Output: one empty-start run per setting, tables and recoverable output archives.
"""
import argparse,subprocess,sys,json,os,time
from pathlib import Path
HERE=Path(__file__).resolve().parent
p=argparse.ArgumentParser();p.add_argument('--output-parent',required=True);p.add_argument('--package-root',required=True);p.add_argument('--search-path',required=True);p.add_argument('--fmm-root',required=True);p.add_argument('--matlab',required=True);p.add_argument('--conda',required=True);a=p.parse_args();out=Path(a.output_parent).resolve();assert out==HERE/'output'
# Forecasts use run-001: full918.65s, residual574.33s, setup103.24s,
# queue469.05s, total peak1.67GiB. Conservative allowances include all checks.
jobs=[
 ('run-010','fixed field, twice all target panels',1250,2.6,['--field-source',str(out/'run-001'),'--panels','2']),
 ('run-011','fixed field, 64 smooth Chebyshev nodes',1150,2.6,['--field-source',str(out/'run-001'),'--chebyshev','64']),
 ('run-012','fixed field, 192-bit main arithmetic',1300,2.7,['--field-source',str(out/'run-001'),'--precision','192'])]
results=['run-001','run-003','run-006','run-007','run-008'];records=[];start=time.perf_counter()
for name,title,seconds,rss,options in jobs:
  assert seconds<1800 and rss<3
  # The numerical driver records its own ps preflight; the idle controller is
  # an ancestor, not a competing scientific process.
  with (HERE/'README.md').open('a') as f:f.write(f'\nBefore {name}: {title}; complete forecast {seconds}s, peak {rss}GiB. All stages/checks included; 30/40min and 3GiB enforced.\n')
  cmd=[sys.executable,str(HERE/'varied/run_pipeline.py'),'--output',str(out/name)]
  for key in ['package_root','search_path','fmm_root','matlab','conda']:cmd+=['--'+key.replace('_','-'),getattr(a,key)]
  cmd+=options;t=time.perf_counter();print('START',name,title,flush=True);r=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True);(out/name/'controller.log').write_text(r.stdout)
  rec=dict(run=name,title=title,forecast_seconds=seconds,forecast_peak_gib=rss,controller_seconds=time.perf_counter()-t,returncode=r.returncode);records.append(rec);(HERE/'queue-evaluation-summary.json').write_text(json.dumps(dict(runs=records,wall_seconds=time.perf_counter()-start),indent=2))
  if r.returncode:print('STOP',name,r.stdout[-2000:],flush=True);sys.exit(r.returncode)
  results.append(name)
  post=[sys.executable,str(HERE/'summarize.py'),'--runs']+[str(out/n) for n in results]+['--output',str(HERE/'tables')]
  subprocess.run(post,check=True)
  subprocess.run([sys.executable,str(HERE/'archive_output.py'),'--run',str(out/name)],check=True)
  print('DONE',name,rec['controller_seconds'],flush=True)
print('ALL REQUESTED ROWS COMPLETE',flush=True)
