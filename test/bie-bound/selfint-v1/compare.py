"""Compare same scientific outputs across cache and process schedules.
Input: explicit serial, parallel and decisive output directories.
Output: scalar exact-equality checks; timing comparisons are separate.
"""
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--serial',type=Path,required=True);p.add_argument('--parallel',type=Path,required=True);p.add_argument('--decisive',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
def rows(root):return {r['panel']:r for f in root.rglob('panel-*.json') for r in [json.loads(f.read_text())]}
s=rows(a.serial);p=rows(a.parallel);d=rows(a.decisive)
fields=['polynomial','terms','V','e_upper','epsilon_panel_upper','M_local_upper','M_proxy_upper','scaled_coefficient_radii']
out={}
for name,rhs,ids in [('cache_vs_uncached',d,list(d)),('parallel_vs_serial',p,list(s))]:
 out[name]=[{"panel":j,"fields_equal":{k:s[j][k]==rhs[j][k] for k in fields}} for j in ids]
out['all_passed']=all(ok for rows0 in out.values() for row in rows0 for ok in row['fields_equal'].values())
a.output.write_text(json.dumps(out,indent=2));print(json.dumps(out));assert out['all_passed']
