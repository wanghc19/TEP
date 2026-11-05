"""Measured-component residual-pipeline projection for state columns.
Input: explicit baseline, curve, lead and prior pilot result directories.
Output: serial and eight-worker predictions with two setup policies.
"""
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--baseline',required=True);p.add_argument('--curve',required=True);p.add_argument('--lead',required=True);p.add_argument('--prior',required=True);p.add_argument('--output',required=True);a=p.parse_args()
read=lambda root,name:json.loads((Path(root)/name).read_text())
b=read(a.baseline,'summary.json');c=read(a.curve,'summary.json');cm=read(a.curve,'monitor.json');l=read(a.lead,'summary.json');old=read(a.prior,'summary.json');s=l['states'][0];N=s['N']
unit=sum(x['wall_seconds'] for x in b['tasks'])/b['count'];central_work=192*unit;efficiency=central_work/(8*c['queue_seconds']);workers=8*efficiency
lead_unit=sum([s['self']['seconds'],s['local_seconds'],s['node_seconds'],s['algebra_seconds'],s['norm_seconds']])
center_region=sum(old['extended']['boundary_setup'][x]['seconds'] for x in ['wall_center','top','bottom'])/3
lead_region=l['interior'][1]['setup_seconds']/2
center_face=next(x for x in old['extended']['boundary'] if x['method']=='B' and x['target']=='seam');center_online=(center_face['node_seconds']+center_face['model_norm_seconds'])/2
lead_online=(l['interior'][1]['node_seconds']+l['interior'][1]['algebra_seconds'])/2
fixed=dict(center_shared_setup=c['setup']['seconds'],lead_shared_setup=2*s['setup_seconds']*(N+1)/N,lead_envelope_tail=2*l['tail']['seconds'],historical_B_fit=3.0098465416666667,historical_mass_allowance=34.7,startup_output=cm['wall_seconds']-c['wall_seconds'])
regions=dict(center=48*center_region,leads=96*lead_region)
online=dict(center_material=central_work,lead_material=128*lead_unit,center_boundaries=48*center_online,lead_boundaries=96*lead_online)
controls=14.995463127968833;serial=sum(fixed.values())+sum(regions.values())+sum(online.values())+controls
serial_setup=sum(fixed.values())+sum(regions.values())+(sum(online.values())+controls)/workers
distributed_setup=sum(fixed.values())+(sum(regions.values())+sum(online.values())+controls)/workers
r=dict(status='PREDICTION',counts=dict(material_center=192,material_leads=128,boundary_center_faces=48,boundary_lead_faces=96),N_right=N,unmeasured_left_assumption='same count and prices as right lead',one_worker_center_panel_seconds=unit,measured_center_queue_seconds=c['queue_seconds'],efficiency=efficiency,effective_workers=workers,lead_material_unit_seconds=lead_unit,lead_boundary_region_seconds=lead_region,lead_boundary_face_online_seconds=lead_online,fixed=fixed,regions=regions,online=online,controls_historical_seconds=controls,serial_seconds=serial,serial_minutes=serial/60,eight_serial_regions_seconds=serial_setup,eight_serial_regions_minutes=serial_setup/60,eight_distributed_regions_seconds=distributed_setup,eight_distributed_regions_minutes=distributed_setup/60,omitted=['reliable trace constants','band-gap certificate when eigenvalue identification is required','full lead parallel memory/distribution','unmeasured target domains and left lead depth'],boundary='Residual evaluation from saved defining field. Historical fit/mass/control allowances are listed separately; candidate search is not included.')
Path(a.output).write_text(json.dumps(r,indent=2))
