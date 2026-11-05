"""Postprocess RE31 operation counts and observed single-thread stage times.
Input: explicit run directory. Output: cost.json, a projection rather than a benchmark of other groups.
"""
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--run',required=True);args=p.parse_args();root=Path(args.run)
def load(path):return json.loads((root/path).read_text())
rows=[load('central-final/panel-0.json'),load('adjacent/panel-1.json')]
def avg(f):return sum(map(f,rows))/len(rows)
S=160;A=.02409875
mix=avg(lambda v:v['times']['mixed'])/S;env=avg(lambda v:v['times']['envelopes'])/S
alg=avg(lambda v:sum(v['times'][k] for k in ['geometry','moments','contraction']))/S
free=avg(lambda v:v['self_record']['evaluation_seconds']+v['self_record']['grid_seconds'])
domain=avg(lambda v:v['self_record']['domain_seconds'])
other=avg(lambda v:v['seconds']-sum(v['times'].values())-v['self_record']['evaluation_seconds']-v['self_record']['domain_seconds']-v['self_record']['grid_seconds'])
def project(name,targets,sources,is_material):
  count=targets*sources
  d=dict(name=name,targets=targets,pairs=count,mixed=count*mix,kress=targets*free if is_material else 0.,
    envelopes=count*env+(targets*domain if is_material else 0.),algebra=count*alg+targets*other)
  d['seconds']=sum(d[k] for k in ['mixed','kress','envelopes','algebra']);return d
export=load('export/export-summary.json')
# Stage 6 already counted its field, Q5 check and ordinary export: use only
# the estimated incremental disk-selection/export time in this projection.
extra_export=export['total_seconds']-export['field_seconds']-export['floating']['seconds']-.761662
shared=dict(switch_once=148.463619,mass=load('mass-refined/monitor.json')['wall_seconds'],extra_disk_selection_and_export=extra_export)
scenarios={}
for scenario,pc,sc in [('design_counts',64,64),('measured_center_counts',192,160)]:
  groups=[project('center',pc,sc,True),project('left material',64,64,True),project('right material',64,64,True),project('six walls',6*16,32,False)]
  scenarios[scenario]=dict(groups=groups,shared=shared,pairs=sum(v['pairs'] for v in groups),
    minutes=(sum(v['seconds'] for v in groups)+sum(shared.values()))/60)
mon=[json.loads(p.read_text()) for p in root.parent.glob('run-*/*/monitor.json')]
result=dict(scenarios=scenarios,accepted_panels=[v['seconds'] for v in rows],whole_center_minutes=192*avg(lambda v:v['seconds'])/60,
  accepted_pair_chi_ts=mix/A,observed_pair_kernel_seconds=mix,observed_Kress_seconds_per_target=free,
  observed_alg_seconds_per_pair=alg,observed_envelope_seconds_per_pair=env,
  additional_unmeasured='wall root subdivision and moving-cut error, 97-dimensional lead action, group tail and trace-constant certificates; other templates use central proxy and Kress prices',
  all_monitored_seconds=sum(v['wall_seconds'] for v in mon),highest_rss_gib=max(v['peak_process_tree_rss_gib'] for v in mon),
  final_timing=load('timing-final/timing.json'),accepted_arc=load('audit/audit.json'))
(root/'cost.json').write_text(json.dumps(result,indent=2))
summary={'result_run':root.name,'floating_full':export['floating'],'partial':result['accepted_arc'], 'unit_seconds':A,'chi_t':result['final_timing']['chi_t'],'chi_ts_isolated':result['final_timing']['chi_ts'],'chi_ts_all_accepted_pairs':result['accepted_pair_chi_ts'],'U_lower':load('mass-refined/disks.json')['U_lower'],'scenarios_minutes':{k:v['minutes'] for k,v in scenarios.items()},'whole_center_minutes':result['whole_center_minutes'],'total_monitored_seconds':result['all_monitored_seconds'],'maximum_rss_gib':result['highest_rss_gib']}
(root.parent.parent/'summary.json').write_text(json.dumps(summary,indent=2))
