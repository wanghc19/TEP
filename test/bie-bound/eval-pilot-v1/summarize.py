"""Summarize fixed-field evaluation data; input is one explicit run directory.
Writes summary.json and evaluations.csv in that directory.
"""
import csv,json,math,sys
from pathlib import Path
out=Path(sys.argv[1]);r=json.loads((out/'result.json').read_text());m=json.loads((out/'monitor.json').read_text())
ev=r['evaluations'];ev=[ev] if isinstance(ev,dict) else ev
names=['center','negative_material','positive_material','left_junction','right_junction','negative_walls','positive_walls']
checks={};parts=[]
for e in ev:
 c=e['components'];v=sum(c[n]['value_squared'] for n in names);w=sum(c[n]['normal_squared'] for n in names)
 err=max(abs(v/c['value_squared']-1),abs(w/c['normal_squared']-1))
 checks[e['name']]={'component_sum_relative':err,'frozen_field_unchanged':e['frozen_field_unchanged'],'audit_maximum_defect':e['audit']['maximum_defect']}
 assert err<1e-13 and e['frozen_field_unchanged'] and e['audit']['pass']
 for part,seconds in e['timing'].items():
  parts.append({'evaluation':e['name'],'part':part,'seconds':seconds,'peak_rss_gib':m['peak_by_part_gib'].get(e['name']+'/'+part)})
eps=[e['epsilon'] for e in ev];width=[e['W'] for e in ev]
ratio=max(eps)/min(eps);maxW=max(width)
ledger=json.loads((out/'proxy-calls.json').read_text())
backend_checks={e['name']:all(p['method']==e['method'] for p in ledger if p['stage'].startswith(e['name']+'/')) for e in ev}
assert all(backend_checks.values())
dominant=[]
for e in ev:
 c=e['components'];q={n:c[n]['value_squared']+c[n]['normal_squared'] for n in names};n=max(q,key=q.get)
 dominant.append({'evaluation':e['name'],'component':n,'fraction_of_epsilon_squared':q[n]/e['epsilon']**2})
changes={e['name']:{'epsilon_relative_to_baseline':e['epsilon']/ev[0]['epsilon']-1,'R_relative_to_baseline':e['R']/ev[0]['R']-1,'tail_squared_candidate':sum(e['components'][n]['tail_value_squared_candidate']+e['components'][n]['tail_normal_squared_candidate'] for n in ['negative_material','positive_material','negative_walls','positive_walls']),'peak_rss_gib':max(v for k,v in m['peak_by_part_gib'].items() if k.startswith(e['name']+'/'))} for e in ev}
s={'evaluation_changes':changes,'U_span':max(e['U'] for e in ev)-min(e['U'] for e in ev),'proxy_call_count':len(ledger),'direct_proxy_call_count':sum(p['method']=='direct' for p in ledger),'maximum_ier':max(p['ier'] for p in ledger),'largest_epsilon_ratio':ratio,'max_W':maxW,'answer':'real' if ratio<3.2 and maxW<=5e-9 else 'not_real','baseline_relative_epsilon':r['baseline_relative_epsilon'],'baseline_relative_R':r['baseline_relative_R'],'checks':checks,'backend_checks':backend_checks,'dominant':dominant,'part_resources':parts,'monitor':m,'field_build_count':r['build_count'],'optional_direct1536':r['optional_direct1536']}
(out/'summary.json').write_text(json.dumps(s,indent=2)+'\n')
with (out/'evaluations.csv').open('w') as f:
 fields=['name','method','nodes','requested_tolerance','epsilon','U','C','Q','R','W','seconds'];w=csv.DictWriter(f,fields);w.writeheader();w.writerows({k:e[k] for k in fields} for e in ev)
with (out/'parts.csv').open('w') as f:
 w=csv.DictWriter(f,['evaluation','part','seconds','peak_rss_gib']);w.writeheader();w.writerows(parts)
print(json.dumps(s,indent=2))
