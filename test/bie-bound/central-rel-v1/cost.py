"""Measured central-curve cost and explicit RE31 wall-time extrapolation.
Input: full parallel run, old shared-stage costs and an output path.
Output: cost.json with observed worker-seconds, queue efficiency and group forecasts.
"""
import argparse,json,statistics
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--run',type=Path,required=True);p.add_argument('--old-cost',type=Path,required=True);p.add_argument('--aggregate',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
def load(p):return json.loads(p.read_text())
q=load(a.run/'queue.json');m=load(a.run/'monitor.json');am=load(a.aggregate/'monitor.json');ar=load(a.aggregate/'aggregate.json');assert q['all_requested_valid']
rows=[load(p) for p in a.run.glob('panel-*.json')];workers=q['worker_records'];W=q['workers']
assert len(rows)==192,'Split-panel cost model needs explicit revised counts'
avg=lambda f:statistics.mean(f(r) for r in rows)
cache=statistics.mean(w['cache']['seconds'] for w in workers)
# Wall duration of a worker task includes its actual scheduling conditions.
# Calibration maps the observed sum of worker durations to monitored wall;
# it is not an assumed ideal W-fold speedup.
base=sum(load(a.run/f'task-{i}.json')['wall_seconds'] for i in range(192))+sum(w['cache']['seconds'] for w in workers)
scale=m['wall_seconds']/base
pair={k:avg(lambda r:r['times'][k])/160 for k in ['mixed','envelopes','contraction']}
selfprice=avg(lambda r:r['self_record']['self_seconds']);control=avg(lambda r:r['control']['seconds'])
other=avg(lambda r:r['total_seconds_with_controls']-r['self_record']['self_seconds']-r['control']['seconds']-sum(r['times'][k] for k in pair))
# Include validation/output outside the individual compute timer exactly once.
other+=(sum(load(a.run/f'task-{i}.json')['wall_seconds'] for i in range(192))-sum(r['total_seconds_with_controls'] for r in rows))/192
shared=load(a.old_cost)['scenarios']['measured_center_counts']['shared']
def project(name,P,S,material=True,curves=1):
 d=dict(name=name,targets=P,sources=S,mixed_worker_seconds=P*S*pair['mixed'],
  envelope_worker_seconds=P*S*pair['envelopes'],contraction_worker_seconds=P*S*pair['contraction'],
  self_worker_seconds=P*selfprice if material else 0.,control_worker_seconds=P*control if material else 0.,
  other_worker_seconds=P*other,cache_worker_seconds=W*cache*S/160*curves)
 d['worker_seconds']=sum(v for k,v in d.items() if k.endswith('_worker_seconds'))
 d['wall_prediction_seconds']=d['worker_seconds']*scale
 return d
leads=[project(side,64,64) for side in ['left material','right material']];walls=project('six walls',96,32,False,6)
result=dict(W=W,monitor_wall_seconds=m['wall_seconds'],python_queue_wall_seconds=q['wall_seconds'],
 total_python_cpu_seconds=q['total_python_cpu_seconds'],summed_worker_cpu_seconds=q['summed_worker_cpu_seconds'],
 baseline_192_times_19_8_over_W=192*19.8/W,reference_parallel_efficiency=(192*19.8)/(W*m['wall_seconds']),
 cpu_utilization=q['total_python_cpu_seconds']/(W*m['wall_seconds']),worker_seconds_to_wall=scale,
 worker_distribution=[dict(pid=w['pid'],panels=len(w['completed']),cache_seconds=w['cache']['seconds'],
   process_seconds=w['process_wall_seconds'],cpu_seconds=w['process_cpu_seconds'],self_peak_rss_gib=w['self_peak_rss_gib'],
   panels_per_active_second=len(w['completed'])/(w['process_wall_seconds']-w['cache']['seconds'])) for w in workers],
 observed_cache_seconds_mean=cache,center_measured_wall=m['wall_seconds']+am['wall_seconds'],aggregation_wall_seconds=am['wall_seconds'],aggregation_cpu_seconds=ar['cpu_seconds'],center_model=project('center',192,160),
 extrapolated_other_groups=leads+[walls],shared_serial_seconds=shared,
 full_pipeline_wall_minutes=(m['wall_seconds']+am['wall_seconds']*(192+128+96)/192+sum(g['wall_prediction_seconds'] for g in leads+[walls])+sum(shared.values()))/60,
 unmeasured='Other-template domain feasibility and local prices, lead-state algebra, wall subdivisions, grouped tails, C_g and band-gap certificate. The full pipeline has not been run.',
 historical_design_counts_status='64 central targets have no certified domain; they are not used for the main projection')
a.output.write_text(json.dumps(result,indent=2));print(json.dumps({k:result[k] for k in ['monitor_wall_seconds','total_python_cpu_seconds','reference_parallel_efficiency','full_pipeline_wall_minutes']}))
