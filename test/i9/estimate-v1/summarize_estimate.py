"""Export small I9.2 scalar, component and timing tables from this run's JSON.

Presentation only: never chooses a scientific parameter or reruns computation.
All generated files remain in the explicitly supplied current output directory.
"""
import csv
import json
import sys
from collections import defaultdict
from pathlib import Path

def main(run):
  result=json.loads((run/'result.json').read_text())
  status=json.loads((run/'status.json').read_text())
  with (run/'scalars.csv').open('w') as f:
    w=csv.writer(f);w.writerow(['quantity','value'])
    for name in ['k0','mu_num','C_num','epsilon_num','U_num','Q_num','denominator','R_num']:
      w.writerow([name,format(result[name],'.17g')])
    for name,value in result['point'].items():w.writerow([name,format(value,'.17g')])
  with (run/'components.csv').open('w') as f:
    w=csv.writer(f);w.writerow(['component','quantity','value'])
    for component,data in result['components'].items():
      if isinstance(data,dict):
        for name,value in data.items():
          w.writerow([component,name,value if isinstance(value,bool) else format(value,'.17g')])
      else:w.writerow(['total',component,data])
  stage=result['timing']; remaining=status['wall_seconds']-sum(stage.values())-result['export_seconds']
  with (run/'timing.csv').open('w') as f:
    w=csv.writer(f);w.writerow(['exclusive_stage','seconds'])
    for name,seconds in stage.items():w.writerow([name,format(seconds,'.17g')])
    w.writerow(['save_serialization',format(result['export_seconds'],'.17g')])
    w.writerow(['startup_exit_other',format(remaining,'.17g')])
    w.writerow(['complete_process',format(status['wall_seconds'],'.17g')])
  proxy=defaultdict(lambda:dict(calls=0,seconds=0,max_pair_targets=0,target_sum=0,statuses=set()))
  for call in result['proxy_calls']:
    row=proxy[call['stage']];row['calls']+=1;row['seconds']+=call['seconds'];row['max_pair_targets']=max(row['max_pair_targets'],call['nt']);row['target_sum']+=call['nt'];row['statuses'].add(call['ier'])
  for row in proxy.values():row['statuses']=sorted(row['statuses'])
  (run/'proxy-summary.json').write_text(json.dumps(proxy,indent=2)+'\n')
  summary={name:result[name] for name in ['status','k0','mu_num','C_num','epsilon_num','U_num','Q_num','denominator','R_num','point','timing']}
  summary['monitor']=status;summary['save_seconds']=result['export_seconds'];summary['other_seconds']=remaining
  (run/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')

if __name__=='__main__':main(Path(sys.argv[1]).resolve())
