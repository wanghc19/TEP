"""Small smoke check of exact inputs, field shapes and reference interval algebra.
Input: canonical data and reference directories. Output: a compact PASS table.
No field, spectral or residual assertion is replaced by this smoke test.
"""
import argparse,json,struct,sys
from pathlib import Path
sys.dont_write_bytecode=True
from fractions import Fraction
p=argparse.ArgumentParser();p.add_argument('--data',required=True);p.add_argument('--reference',required=True);a=p.parse_args()
data=Path(a.data);field=json.loads((data/'fixed-input.json').read_text());fit=json.loads((data/'coefficients.json').read_text());ref=json.loads((Path(a.reference)/'results.json').read_text())
def numbers(o):
  if isinstance(o,dict):
    if set(['shape','real','imag'])<=o.keys():
      n=o['shape'][0]*o['shape'][1]
      for k in ['real','imag']:
        v=o[k] if isinstance(o[k],list) else [o[k]]
        if n==0:
          assert v in [[],['']], 'Invalid empty-array encoding'
          continue
        assert len(v)==n
        for s in v:
          x=struct.unpack('>d',bytes.fromhex(s))[0];assert x==x and abs(x)!=float('inf')
    else:
      for v in o.values():numbers(v)
  elif isinstance(o,list):
    for v in o:numbers(v)
numbers(field);numbers(fit);print('PASS exact finite binary64 arrays')
kh=field['k']['real'];kh=kh if isinstance(kh,str) else kh[0];assert kh==ref['candidate']['k_hex'];assert len(field['pieces'])==3
assert fit['Z']['shape']==[2,480];assert fit['B_center']['shape']==[480,1];assert fit['B_negative']['shape']==fit['B_positive']['shape']==[480,97]
print('PASS candidate and field dimensions')
if field.get('example',{}).get('empty_center',False):
  settings=json.loads((data/'example-settings.json').read_text());band=json.loads((data/'band-inputs.json').read_text())
  assert settings['model']==field['example'] and band['cell_widths']==field['cell_widths']
  assert band['angles']==[0,field['example']['angle_negative'],field['example']['angle_positive']]
  assert band['k_lower']==settings['evaluation']['k_lower'] and band['k_upper']==settings['evaluation']['k_upper']
  assert field['pieces'][0]['shape']=='none' and field['pieces'][0]['tau_coeff']['shape']==[0,1]
  print('PASS empty center, periods, rotation and band metadata')
constants=json.loads((Path(a.reference)/'trace-constants.json').read_text());C=[x['published'] for x in constants[0]['rows']]
r=ref['assembly'];k=Fraction.from_float(struct.unpack('>d',bytes.fromhex(kh))[0]);Q=sum((Fraction(c)*Fraction(e) for c,e in zip(C,r['epsilon_decimal_readback'])),Fraction());U=Fraction(r['U_used']);R=2*k*k*Q/(U-Q)
assert Fraction(r['R_upper'])>=R;assert Fraction(r['mu_interval'][0])<=k*k-R and Fraction(r['mu_interval'][1])>=k*k+R
print('PASS exact rational outward interval')
