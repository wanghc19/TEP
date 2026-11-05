"""Check determinant-search candidates and binary64 handoffs from explicit runs.
JSON means JavaScript Object Notation; hex means hexadecimal.
"""
import argparse,json,struct
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('runs',nargs='+');a=p.parse_args()
for item in a.runs:
  out=Path(item);r=json.loads((out/'result.json').read_text());c=json.loads((out/'candidate-list.json').read_text())
  assert len(c)==1
  k=struct.unpack('>d',bytes.fromhex(c[0]['k_hex']))[0]
  delta=k-1.5584378941820909
  assert abs(delta)<=2e-14
  assert repr(k)==c[0]['k_decimal'] and float(c[0]['k_decimal'])==k
  assert k.hex()==c[0]['k_hexfloat'] and k==c[0]['k']
  assert c[0]['aphys_ratio']<=r['settings']['confirm_ratio_max']
  assert len(r['points'])==sum(r['counts'][x] for x in ['determinant','polish','confirmation'])
  mode=r['settings']['mode']
  if mode=='production':
    assert not r['fallback_fired']
    assert r['common_gaps'][0]['bounds']==[1.4509999999999998,2.249]
    assert r['panels'][0]['levels'][-1]['degree']==32
    assert len(r['panels'])==1
    rr=r['panels'][0]['levels'][-1]['roots']
    if rr and isinstance(rr[0],(int,float)):rr=[rr]
    near=[x for x in rr if abs(x[1])<r['settings']['near_real_tol']]
    assert len(near)==1
  else:
    assert r['fallback_fired'] and len(r['fallbacks'])==1
    assert c[0]['fallback_used']
  m=json.loads((out/'monitor.json').read_text());assert m['returncode']==0 and m['reason']=='completed'
  before=json.loads((out/'preflight.json').read_text());after=json.loads((out/'launch-summary.json').read_text())
  assert before['heavy_jobs']==[] and after['heavy_jobs_after']==[]
  unresolved=[x['status'] for x in r['fallbacks'] if x['status']!='SEARCH_FINISHED']
  checks={'checks':'passed','fallback_unresolved_states':unresolved,'candidate_error':delta,'candidate_decimal':c[0]['k_decimal'], 'candidate_hex':c[0]['k_hex'],'candidate_hexfloat':c[0]['k_hexfloat'],'counts':r['counts'],'timing':r['timing'],'science_seconds':r['science_seconds'],'monitor':m,'idle_before_and_after':True}
  (out/'checks.json').write_text(json.dumps(checks,indent=2));print(item,json.dumps(checks))
