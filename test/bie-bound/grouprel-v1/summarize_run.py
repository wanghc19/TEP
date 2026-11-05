"""Scalar summary of a completed five-group run and its explicit audits.
Input: full, audit, diagnostic, repair run paths and output directory.
Output: compact JSON and target CSV for independent manager checks.
"""
import argparse,json,csv,collections,statistics
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--full',required=True);p.add_argument('--audit',required=True);p.add_argument('--diagnostic',required=True);p.add_argument('--repair',required=True);p.add_argument('--output',required=True);p.add_argument('--other-full');a=p.parse_args();read=lambda p,n:json.loads((Path(p)/n).read_text());r=read(a.full,'summary.json');audit=read(a.audit,'summary.json');assert r['passed'] and audit['all_passed'];out=Path(a.output);stats={};exceptions=[];workers={}
for t in r['tasks']:
  key=t['kind'];q=stats.setdefault(key,dict(count=0,task_wall_sum=0.,task_cpu_sum=0.,region_setup_sum=0.,node_sum=0.,local_sum=0.,self_sum=0.));q['count']+=1;q['task_wall_sum']+=t['task_wall_seconds'];q['task_cpu_sum']+=t['task_cpu_seconds'];w=workers.setdefault(str(t['pid']),dict(count=0,task_wall_sum=0.,task_cpu_sum=0.));w['count']+=1;w['task_wall_sum']+=t['task_wall_seconds'];w['task_cpu_sum']+=t['task_cpu_seconds']
  leaves=t.get('leaves',[t])
  for z in leaves:
    q['region_setup_sum']+=z.get('setup_seconds',0.);q['node_sum']+=z.get('node_seconds',0.);q['local_sum']+=z.get('local_seconds',0.);q['self_sum']+=z.get('self',{}).get('seconds',0.)
    gate=z.get('local',{}).get('envelope_gate')
    if gate and gate['splits']:exceptions.append(dict(kind=key,side=t.get('side'),index=t.get('index'),local_envelope=gate))
  if t.get('fallbacks'):exceptions.append(dict(kind=key,side=t.get('side'),index=t.get('index'),target_fallback=t['fallbacks']))
  if key=='center':
    for z in t['center']['leaves']:
      if z['self']['L']>40 or z['depth'] or z['self_flag']:exceptions.append(dict(kind=key,index=t['index'],L=z['self']['L'],depth=z['depth'],self_flag=z['self_flag']))
monitors={k:read(getattr(a,k),'monitor.json') for k in ['full','audit','diagnostic','repair']};
if a.other_full:monitors['other_full']=read(a.other_full,'monitor.json')
m=monitors['full'];result=dict(status='PASS',bounds=audit,tail_depths=r['groups']['tails'],references=read(a.full,'reference-checks.json'),full_monitored_wall_seconds=m['wall_seconds'],full_cpu_seconds=r['cpu_seconds'],full_peak_rss_gib=m['peak_process_tree_rss_gib'],shared_setup_seconds=r['setup']['seconds'],queue_seconds=r['queue_seconds'],internal_total_seconds=r['wall_seconds'],aggregation_output_seconds=r['wall_seconds']-r['setup']['seconds']-r['queue_seconds'],startup_monitor_output_seconds=m['wall_seconds']-r['wall_seconds'],task_stats=stats,workers=workers,exceptions=exceptions,load_before=r['load_before'],load_after=r['load_after'],monitors=monitors,fresh_result_monitored_seconds=sum(x['wall_seconds'] for x in monitors.values()),comparison_boundary='Residual groups from exact defining field inputs, including same-run reproduction/independent checks. No refit, candidate search, reliable trace constants or band-gap computation.')
(out/'final-summary.json').write_text(json.dumps(result,indent=2))
with (out/'targets.csv').open('w',newline='') as f:
 w=csv.writer(f);w.writerow(['kind','side','index','passed','wall_seconds','cpu_seconds','e_I','V','gauss_relative','target_splits'])
 for t in r['tasks']:w.writerow([t['kind'],t.get('side'),t.get('index'),t['passed'],t['task_wall_seconds'],t['task_cpu_seconds'],t.get('e_I'),t.get('V'),t.get('gauss_relative'),len(t.get('fallbacks',[]))])
