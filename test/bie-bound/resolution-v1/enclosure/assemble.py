# Copied from test/bie-bound/pipeline-v1/enclosure/assemble.py.
# Copied from test/bie-bound/enclosure-v1/assemble.py; pipeline adaptations documented in README.
"""Assemble the final enclosure with Arb (real ball arithmetic).
Input: exact field, five-group upper bounds, eight-disk certificate, output.
Output: two curvature certificates and independently checked decimal intervals.
"""
import argparse,json,sys,time,resource
from pathlib import Path
from fractions import Fraction
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,ctx,fmpq
from trace_constants import decode,hull,rational_float,certify_curve,trace,upper,lower

PARAMS=[('center',.015070388978451253,.042231910760400934,'64.30','2.490254'),
 ('negative',.09435698376873762,.3831172882508694,'8.81','1.181583'),
 ('positive',.08145807605762904,.31177996185247553,'10.53','1.233941'),
 ('walls',.2,1.165763957080782,'0','1.035553'),('seams',.2,1.165763957080782,'0','1.035553')]

def directed(x,places,upward):
  scale=10**places
  n=int((x.upper()*scale).ceil().unique_fmpz()) if upward else int((x.lower()*scale).floor().unique_fmpz())
  value=('-' if n<0 else '')+str(abs(n)//scale)+'.'+str(abs(n)%scale).zfill(places)
  assert arb(value)>=x if upward else arb(value)<=x
  return value

def certify(data,bits,n0):
  ctx.prec=bits;ctx.threads=1;t=time.perf_counter();pars=decode(data['curve_parameters']);k=decode(data['k'])[0];mu=k*k
  # Explicit model assertions, absent from the legacy export, define this port.
  model=dict(L_left=1,L_right=1,rho=[1,4,17,17],cell_half_width='0.5',orientation='unreflected')
  assert model['rho']==[1,4,17,17] and model['L_left']==model['L_right']==1
  assert decode(data['beta'])[0]==arb(1)/2 and decode(data['d'])[0]==1
  assert pars[2]==arb(3)/2 and pars[3]==pars[4]==1
  Rc=hull(pars[0],arb(1)/5);b=hull(pars[1],arb(3)/10);Rl=hull(pars[7],arb(1)/5)
  shapes=[(Rc,b),(Rl,hull(pars[5],arb(3)/25)),(Rl,hull(pars[6],arb(1)/5))]
  rows=[]
  for j,(name,dd,ee,kk,published) in enumerate(PARAMS):
    delta=rational_float(dd);eta=rational_float(ee);K=arb(kk)
    if j<3:
      geometry=certify_curve(name,*shapes[j],delta,K,n0)
      leaves=sorted((Fraction(v['j'],v['n']),Fraction(v['j']+1,v['n'])) for v in geometry['leaves'])
      assert leaves[0][0]==0 and leaves[-1][1]==1 and all(a[1]==b[0] for a,b in zip(leaves,leaves[1:]))
      assert geometry['bbox_x_upper']<.5 and geometry['bbox_y_upper']<.5
    else:
      assert 1-2*delta>0
      geometry={'flat_separation_lower':lower(1-2*delta)}
    C,rec=trace(delta,eta,K,mu);assert C<arb(published)
    rows.append(dict(name=name,published=published,geometry=geometry,trace=rec))
  return dict(bits=bits,initial_panels=n0,model=model,rows=rows,seconds=time.perf_counter()-t)

def assembly(data,groups,disks,bits):
  ctx.prec=bits;t=time.perf_counter();k=decode(data['k'])[0];mu=k*k
  eps=groups['epsilon_upper'];assert len(eps)==5 and all(Fraction(x)>0 for x in eps)
  U=arb('1.23587');assert arb(disks['U_lower'])>U
  assert len(disks['rows'])==8 and arb(disks['pair_clearance_lower'])>0
  for row in disks['rows']:
    assert arb(row['rho']) in [arb(4),arb(17)] and arb(row['boundary_distance_lower'])>arb(row['radius'])
  terms=[arb(p[4])*arb(e) for p,e in zip(PARAMS,eps)];Q=sum(terms,arb(0));den=U-Q;assert den>0
  R=2*mu*Q/den;lo=mu-R;hi=mu+R;aa=(arb(659)/500)**2;bb=(arb(19)/8)**2
  assert lo>aa and hi<bb
  # Exact rational computation uses input decimals as rationals and the binary64 k exactly.
  import struct
  kh=data['k']['real'];kh=kh if isinstance(kh,str) else kh[0]
  kr=Fraction.from_float(struct.unpack('>d',bytes.fromhex(kh))[0]);mr=kr*kr
  qr=sum((Fraction(p[4])*Fraction(e) for p,e in zip(PARAMS,eps)),Fraction(0));ur=Fraction('1.23587');rr=2*mr*qr/(ur-qr)
  exact=arb(fmpq(rr.numerator,rr.denominator));assert R.overlaps(exact)
  return dict(bits=bits,epsilon_decimal_readback=eps,U_certificate_readback=disks['U_lower'],U_used='1.23587',
    terms_upper=[directed(v,30,True) for v in terms],mu=str(mu),Q_upper=directed(Q,30,True),
    U_minus_Q_lower=directed(den,25,False),R_upper=directed(R,25,True),
    exact_rational_R_upper=directed(exact,25,True),mu_interval=[directed(lo,25,False),directed(hi,25,True)],
    k_interval=[directed(lo.sqrt(),25,False),directed(hi.sqrt(),25,True)],width_upper=directed(2*R,25,True),
    T15_margins_lower=[directed(lo-aa,24,False),directed(bb-hi,24,False)],seconds=time.perf_counter()-t,
    conditions=['same exact-input piecewise Helmholtz B field and all five residual certificates',
    'eight interior disks with the unchanged interior representation','rounding-inclusive band certificate required from this same pipeline run'])

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--groups',required=True);p.add_argument('--disks',required=True);p.add_argument('--output',required=True);a=p.parse_args()
  start=time.perf_counter();out=Path(a.output);data=json.loads(Path(a.input).read_text());groups=json.loads(Path(a.groups).read_text(),parse_float=str);disks=json.loads(Path(a.disks).read_text())
  result={'certificates':[],'assemblies':[]}
  for bits,n0 in [(192,256),(160,512)]:
    result['certificates'].append(certify(data,bits,n0));result['assemblies'].append(assembly(data,groups,disks,bits))
  for key in ['Q_upper','R_upper','mu_interval','k_interval','width_upper','T15_margins_lower']:
    assert result['assemblies'][0][key]==result['assemblies'][1][key],key
  result['seconds']=time.perf_counter()-start;result['peak_process_rss_bytes']=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
  (out/'result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result['assemblies'][0],indent=2));print('PASS',result['seconds'])
if __name__=='__main__':main()
