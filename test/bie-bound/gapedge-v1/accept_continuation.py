"""Record the manager-accepted L0=1.6 chain from explicit same-experiment runs.
Input: base residual run, finishing run, confirmation run, output JSON.
Output: matched interval and source/stage ledger; no new numerical certificate.
"""
import argparse,gzip,json
from pathlib import Path
from decimal import Decimal

def read(path):
 p=Path(path);r=json.loads(gzip.decompress(p.read_bytes()) if p.suffix=='.gz' else p.read_text());return read(p.parent/r['archive']) if isinstance(r,dict) and 'archive' in r else r
p=argparse.ArgumentParser()
for k in ['base','finish','confirmation','output']:p.add_argument('--'+k,required=True)
a=p.parse_args();base=Path(a.base);finish=Path(a.finish);conf=Path(a.confirmation)
g=read(base/'03-residuals/groups.json');gc=read(conf/'03-residuals/groups.json');c=read(base/'candidate.json');cc=read(conf/'candidate.json');f=read(finish/'result.json');A=f['assembly'];checks=dict(export_exact=all(read(finish/'export-check.json').values()),confirmation_k=c['k_hex']==cc['k_hex'],confirmation_epsilon=g['epsilon_upper']==gc['epsilon_upper'],assembly_epsilon_readback=all(Decimal(str(x))==Decimal(y) for x,y in zip(g['epsilon_upper'],A['epsilon_decimal_readback'])),rational_R=A['R_upper']==A['exact_rational_R_upper'],audit=read(base/'04-residual-audit/summary.json')['all_passed'],band=read(finish/'band/result.json')['status']=='PASS')
assert all(checks.values())
rows=[]
for x in read(base/'stages.json'):
 if x['stage'] in ['01-search','02-field','02-conditions','03-residuals','04-residual-audit']:rows.append(dict(stage=x['stage'],seconds=x['driver_seconds'],peak_RSS_GiB=x['monitor']['peak_process_tree_rss_gib'],source=str(base/x['stage'])))
for n in ['mass','enclosure','band']:
 x=read(finish/n/'monitor.json');rows.append(dict(stage=n,seconds=x['wall_seconds'],peak_RSS_GiB=x['peak_process_tree_rss_gib'],source=str(finish/n)))
band_full=read(finish/'band/result.json');band={k:band_full[k] for k in ['status','sign_tests','minima','T15','independent','failing_control']}
r=dict(status='ACCEPTED_BY_MANAGER',boundary='cold search/field/residuals in base; finishing stages in a separate process on identical same-experiment field; stage sum is not uninterrupted wall time',L0=1.6,candidate=c,epsilon=g['epsilon_upper'],tails=g['tails'],assembly=A,conditions=read(base/'02-conditions/conditions.json'),band=band,stages=rows,stage_sum_seconds=sum(x['seconds'] for x in rows),peak_RSS_GiB=max(x['peak_RSS_GiB'] for x in rows),additional_export_check_seconds=read(finish/'field/monitor.json')['wall_seconds'],checks=checks)
r['observed_process_tree_peak_RSS_GiB']=max(read(base/'monitor.json')['peak_process_tree_rss_gib'],read(finish/'monitor.json')['peak_process_tree_rss_gib'])
Path(a.output).write_text(json.dumps(r,indent=2));print(json.dumps(dict(stage_sum=r['stage_sum_seconds'],peak=r['peak_RSS_GiB'],width=A['width_upper'],checks=checks),indent=2))
