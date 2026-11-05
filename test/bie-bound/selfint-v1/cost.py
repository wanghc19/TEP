"""Report the partial D1 batch and conditional single-process cost projections.
Input: explicit completed/partial runs and old group-cost record.
Output: measured scalars and labelled extrapolations, never uncomputed bounds.
"""
import argparse,json,statistics
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--serial',type=Path,required=True);p.add_argument('--decisive',type=Path,required=True)
p.add_argument('--old-cost',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
def load(p):return json.loads(p.read_text())
rows=[load(p) for p in sorted(a.serial.rglob('panel-*.json'))];warm=rows[1:];mon=load(a.serial/'monitor.json')
failed=load(a.serial/'worker-0/self-6.json');old=load(a.old_cost)
mean=lambda f:statistics.mean(f(r) for r in warm)
# The failed batch did not flush its cache timer. This residual includes cache
# build, process startup, input validation, output and the failure path.
unassigned=mon['wall_seconds']-sum(r['total_seconds_with_controls'] for r in rows)-failed['self_seconds']
prices={k:mean(lambda r:r['times'][k])/160 for k in ['mixed','envelopes','contraction']}
self=mean(lambda r:r['self_record']['self_seconds']);control=mean(lambda r:r['control']['seconds'])
other=mean(lambda r:r['total_seconds_with_controls']-r['self_record']['self_seconds']-r['control']['seconds']-sum(r['times'][k] for k in prices))
shared=old['scenarios']['measured_center_counts']['shared']
def group(name,P,S,material=True,curves=1):
 d=dict(name=name,targets=P,sources=S,pairs=P*S,setup_allowance=curves*unassigned,
   mixed=P*S*prices['mixed'],envelopes=P*S*prices['envelopes'],contraction=P*S*prices['contraction'],
   self_interaction=P*self if material else 0.,controls=P*control if material else 0.,other_target_work=P*other)
 d['serial_seconds']=sum(d[k] for k in ['setup_allowance','mixed','envelopes','contraction','self_interaction','controls','other_target_work'])
 return d
checks=[]
for r in rows[:2]:
 oldr=load(a.decisive/f"panel-{r['panel']}.json")
 fields=['polynomial','V','terms','e_upper','epsilon_panel_upper','scaled_coefficient_radii']
 checks.append(dict(panel=r['panel'],exact_fields_equal={k:r[k]==oldr[k] for k in fields}))
assert all(v for r in checks for v in r['exact_fields_equal'].values())
out=dict(accepted_panels=[r['panel'] for r in rows],cache_reuse_counts=[r['reuse_counts'] for r in rows],cache_vs_uncached=checks,
 warm_production_seconds=mean(lambda r:r['seconds']),warm_with_controls_seconds=mean(lambda r:r['total_seconds_with_controls']),
 completed_panel_cpu_seconds=sum(r['cpu_seconds'] for r in rows),failed_panel=failed,
 unassigned_cache_startup_io_failure_seconds=unassigned,measured_monitor=mon,
 prices=dict(per_pair=prices,self_per_target=self,controls_per_target=control,other_per_target=other),shared=shared,scenarios={},
 parallel_status='NOT RUN: panel 6 exceeded the required SI8 error gate; experiment stopped',
 cache_build_time_status='Timer was not flushed before the assertion; only cache+startup+IO+failure remainder is available',
 validity='Conditional cost extrapolation only: remaining panels and other geometries must satisfy their own error/domain gates. Current fixed setting fails panel 6. Wall subdivision, lead-state algebra, group tails, trace constants and gap certification are unmeasured.')
for name,P,S in [('historical_design_counts',64,64),('measured_center_counts',192,160)]:
 g=[group('center',P,S),group('left material',64,64),group('right material',64,64),group('six walls',96,32,False,6)]
 out['scenarios'][name]=dict(groups=g,serial_minutes=(sum(r['serial_seconds'] for r in g)+sum(shared.values()))/60)
out['center_192']=group('center',192,160)
a.output.write_text(json.dumps(out,indent=2));print(json.dumps({k:v['serial_minutes'] for k,v in out['scenarios'].items()}))
