"""Measured-component cost projection for cell kernel field fit.
Input: floating result, primary Arb summary, extra controls, explicit output.
Output: scalar ledger; all whole-pipeline times are predictions, not runs.
"""
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--floating',required=True);p.add_argument('--primary',required=True);p.add_argument('--controls',required=True);p.add_argument('--output',required=True);a=p.parse_args()
f=json.loads(Path(a.floating).read_text());r=json.loads(Path(a.primary).read_text());c=json.loads(Path(a.controls).read_text())
e=r['extended'];v=c['extended'];mean=lambda z:sum(z)/len(z)
# Stream 48 boundary regions per template. Unmeasured left-template costs
# are represented by the measured right template; no symmetry is assumed.
counts=dict(center_material=192,lead_material=128,center_boundary_faces=48,lead_boundary_faces=96)
common=dict(source_setup=r['source_seconds']+2*e['source_seconds'],material_near_setup=r['near_setup']['seconds']+2*e['near_setup']['seconds'],boundary_near_setup=48*mean([e['boundary_setup'][x]['seconds'] for x in ['wall_center','top','bottom']])+96*e['boundary_setup']['wall_lead']['seconds'],self_cache=r['self_cache_seconds'])
result=dict(status='PREDICTION_FROM_PILOTS',counts=counts,common_setup=common,eight_worker_efficiency=0.7751952721018845,shared_mass_seconds=34.7,omitted=['trace-constant certificate','band-gap certificate if eigenvalue identification is wanted','coefficient distribution and full eight-worker memory','other target domains and left-template timings'])
for tag in ['A','B']:
  panels=[x for x in r['panels'] if x['method']==tag];lead=next(x for x in e['lead'] if x['method']==tag);bd={x['target']:x for x in e['boundary'] if x['method']==tag};vc={x['target']:x for x in v['boundary'] if x['method']==tag}
  setup=dict(common);setup['proxy']=r[tag+'_setup']['seconds']+2*e[tag+'_setup']['seconds'];setup['fit']=f['fit_'+tag]['seconds']
  center_unit=mean([x['self_seconds']+x['local_seconds'] for x in r['shared_targets']])+mean([x['times']['production_without_shared_self_local'] for x in panels])
  lead_unit=e['self']['seconds']+e['local']['seconds']+lead['nodes_seconds']+lead['model_algebra_seconds']+lead['state_and_norm_seconds']
  center_face=(bd['seam']['node_seconds']+bd['seam']['model_norm_seconds'])/2
  lead_face=max(0,bd['wall']['node_seconds']+bd['wall']['model_norm_seconds']-center_face)+lead['state_and_norm_seconds']
  online=dict(center_material=192*center_unit,lead_material=128*lead_unit,center_boundary=48*center_face,lead_boundary=96*lead_face)
  # Same audit policy: two center material panels, one wall and seam panel
  # per template, three real points each. Junction wall prices include two
  # traces; charging the whole pair to each template is conservative.
  wall3=vc['wall']['control_seconds']*3/len(vc['wall']['controls']);seam3=vc['seam']['control_seconds']*3/len(vc['seam']['controls'])
  controls=sum(x['times']['controls'] for x in panels)+3*(wall3+seam3)
  setup_total=sum(setup.values());production=setup_total+sum(online.values())+34.7;total=production+controls
  parallel=(setup_total+34.7+(sum(online.values())+controls)/(8*result['eight_worker_efficiency']))
  result[tag]=dict(setup=setup,setup_total=setup_total,unit_seconds=dict(center_material=center_unit,lead_material=lead_unit,center_boundary_face=center_face,lead_boundary_face=lead_face),online=online,control_seconds=controls,production_seconds=production,serial_seconds=total,serial_minutes=total/60,eight_worker_seconds=parallel,eight_worker_minutes=parallel/60)
Path(a.output).write_text(json.dumps(result,indent=2))
