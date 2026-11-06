"""Summarize second-example B2 (reliable pipeline stage) scalar records.
Input: an explicit completed run directory and an output JSON path.
Output: compact raw scalars, checks, conditions and disjoint timings.
"""
import argparse,json
from pathlib import Path
from fractions import Fraction
p=argparse.ArgumentParser();p.add_argument('--run',required=True);p.add_argument('--output',required=True);a=p.parse_args();root=Path(a.run)
def read(name):return json.loads((root/name).read_text())
r=read('result.json');assert r['status']=='COMPLETE'
g=read('03-residuals/groups.json');aud=read('04-residual-audit/summary.json');m=read('05-mass/disks.json');c=read('06-enclosure/result.json');b=read('07-band/result.json');end=read('end-to-end.json');cond=read('02-conditions/conditions.json');asm=c['assemblies'][0]
assert aud['all_passed'] and b['status']=='PASS' and b['sign_tests']==944
k=Fraction.from_float(r['candidate']['k']);lo,hi=map(Fraction,asm['k_interval']);assert lo<k<hi
assert lo>Fraction(73,50) and hi<Fraction(237,100)
assert asm['R_upper']==asm['exact_rational_R_upper']
stages=[]
for s in r['stages']:
 stages.append(dict(stage=s['stage'],seconds=s['driver_seconds'],threads_or_workers=s['threads_or_workers'],peak_rss_gib=s['monitor']['peak_process_tree_rss_gib']))
sumstage=sum(x['seconds'] for x in stages);remaining=end['wall_seconds']-sumstage
out=dict(status='COMPLETE',run=str(root),candidate=r['candidate'],assembly=asm,epsilon_upper=g['epsilon_upper'],tails=g['tails'],mass=m,constants=c['certificates'],band=dict(sign_tests=b['sign_tests'],minima=b['minima'],independent=b['independent'],failing_control=b['failing_control'],T15=b['T15']),conditions=cond,audit=aud,stages=stages,wall_seconds=end['wall_seconds'],peak_rss_gib=end['monitor']['peak_process_tree_rss_gib'],stage_sum_seconds=sumstage,parent_io_and_orchestration_seconds=remaining,checks=dict(candidate_in_k_interval=True,k_interval_in_certified_window=True,rational_R_printed_equal=True,dual_precision_equal=all(c['assemblies'][0][key]==c['assemblies'][1][key] for key in ['Q_upper','R_upper','mu_interval','k_interval','width_upper']),empty_start=read('empty-start-check.json')))
Path(a.output).write_text(json.dumps(out,indent=2));print(json.dumps({k:out[k] for k in ['wall_seconds','peak_rss_gib','epsilon_upper','checks']},indent=2));print(json.dumps(asm,indent=2))
