"""Validate the example-1 scientific data contract before numerical work.
Input: data directory. Output: checked model, disk and band settings.
The manifest is documentation; it is deliberately not a runtime prerequisite.
"""
import json,struct
from pathlib import Path

def validate(data):
  data=Path(data);f=json.loads((data/'fixed-input.json').read_text());m=json.loads((data/'model.json').read_text());b=json.loads((data/'band-inputs.json').read_text());d=json.loads((data/'disks-input.json').read_text())
  def decode(x):
    if isinstance(x,dict) and set(x)=={'binary64'}:return struct.unpack('>d',bytes.fromhex(x['binary64']))[0]
    if isinstance(x,dict):return {k:decode(v) for k,v in x.items()}
    if isinstance(x,list):return [decode(v) for v in x]
    return x
  model=decode(m)['model']
  expected=dict(beta=.5,d=1,L=1,R=.2,a_negative=.12,a_positive=.20,rho_center=4,rho_lead=17,rho_exterior=1,star_scale=1,X_L=-.5,X_R=.5,H=1.1,proxy_dist=.2)
  for k,v in expected.items():assert model[k]==v,('Unsupported example-1 model',k,model[k],v)
  assert d==f['disks'],'Conflicting disk geometry'
  assert b['fourier_halfwidth']==6 and b['quadrature_nodes']==2048 and b['phase_scale']==4096
  assert b['k_gap_rational']==['659/500','19/8'] and b['beta_rational']=='1/2' and b['periods']==[1,1] and b['rho_inclusion']==17 and b['rho_background']==1
  ends=([0,1024,1536,2048,2560,2816,3072,3200,3328,3392,3456,3520,3584,3616,3648,3680,3712,3744]+list(range(3760,3889,16))+list(range(3896,3953,8))+list(range(3956,4005,4))+list(range(4006,4047,2))+list(range(4047,4097)))
  assert b['phase_endpoints']==ends
  for key,v in [('beta',.5),('d',1),('H',1.1)]:
    h=f[key]['real'];h=h if isinstance(h,str) else h[0];assert struct.unpack('>d',bytes.fromhex(h))[0]==v
  pars=f['curve_parameters']['real'];assert [struct.unpack('>d',bytes.fromhex(x))[0] for x in pars]==[.2,.3,1.5,1,1,.12,.20,.2]
  return {'model':True,'disks':True,'band_inputs':True,'example':'ex1'}
