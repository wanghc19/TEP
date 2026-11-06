# B2 source: test/bie-bound/pipeline-v1/enclosure/assemble.py; generalized model plumbing.
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
  n=int((x.upper()*scale).upper().ceil().unique_fmpz()) if upward else int((x.lower()*scale).lower().floor().unique_fmpz())
  value=('-' if n<0 else '')+str(abs(n)//scale)+'.'+str(abs(n)%scale).zfill(places)
  assert arb(value)>=x if upward else arb(value)<=x
  return value

def certify(data,bits,n0):
  ctx.prec=bits;ctx.threads=1;t=time.perf_counter();pars=decode(data['curve_parameters']);k=decode(data['k'])[0];mu=k*k
  model=data.get('example',{});empty=model.get('empty_center',False)
  assert decode(data['beta'])[0]==arb(1)/2 and decode(data['d'])[0]==1
  widths=decode(data['cell_widths']) if 'cell_widths' in data else [arb(1)]*3
  Rc=hull(pars[0],arb(1)/5);b=hull(pars[1],arb(3)/10);Rl=hull(pars[7],arb(1)/5)
  shapes=[(Rc,b),(Rl,hull(pars[5],arb(3)/25)),(Rl,hull(pars[6],arb(1)/5))]
  rows=[]
  for j,(name,dd,ee,kk,published) in enumerate(PARAMS):
    delta=rational_float(dd);eta=rational_float(ee);K=arb(kk)
    if j==0 and empty:
      rows.append(dict(name=name,published='0',geometry=dict(empty=True),trace=dict(C_upper=0.)));continue
    if j<3:
      geometry=certify_curve(name,*shapes[j],delta,K,n0,widths[j])
      leaves=sorted((Fraction(v['j'],v['n']),Fraction(v['j']+1,v['n'])) for v in geometry['leaves'])
      assert leaves[0][0]==0 and leaves[-1][1]==1 and all(a[1]==b[0] for a,b in zip(leaves,leaves[1:]))
      assert arb(str(geometry['bbox_x_upper']))<widths[j]/2 and geometry['bbox_y_upper']<.5
    else:
      period=min(widths) if j==3 else arb(1);assert period-2*delta>0
      geometry={'flat_separation_lower':lower(period-2*delta)}
    C,rec=trace(delta,eta,K,mu)
    if empty:published=directed(C,6,True)
    assert C<arb(published)
    rows.append(dict(name=name,published=published,geometry=geometry,trace=rec))
  return dict(bits=bits,initial_panels=n0,model=model,rows=rows,seconds=time.perf_counter()-t)

def assembly(data,groups,disks,bits,certificate):
  ctx.prec=bits;t=time.perf_counter();k=decode(data['k'])[0];mu=k*k
  empty=data.get('example',{}).get('empty_center',False)
  eps=groups['epsilon_upper'];assert len(eps)==5 and all(Fraction(x)>=0 for x in eps) and (not empty or Fraction(eps[0])==0)
  used=directed(arb(disks['U_lower']),6,False) if empty else '1.23587'
  U=arb(used);assert arb(disks['U_lower'])>U
  assert len(disks['rows'])==(3 if empty else 8) and arb(disks['pair_clearance_lower'])>0
  for row in disks['rows']:
    assert arb(row['rho']) in ([arb(1)] if empty else [arb(4),arb(17)]) and arb(row['boundary_distance_lower'])>arb(row['radius'])
  caps=[r['published'] for r in certificate['rows']]
  terms=[arb(c)*arb(e) for c,e in zip(caps,eps)];Q=sum(terms,arb(0));den=U-Q;assert den>0
  R=2*mu*Q/den;lo=mu-R;hi=mu+R;aa=(arb(73)/50)**2 if empty else (arb(659)/500)**2;bb=(arb(237)/100)**2 if empty else (arb(19)/8)**2
  assert lo>aa and hi<bb
  # Exact rational computation uses input decimals as rationals and the binary64 k exactly.
  import struct
  kh=data['k']['real'];kh=kh if isinstance(kh,str) else kh[0]
  kr=Fraction.from_float(struct.unpack('>d',bytes.fromhex(kh))[0]);mr=kr*kr
  qr=sum((Fraction(c)*Fraction(e) for c,e in zip(caps,eps)),Fraction(0));ur=Fraction(used);rr=2*mr*qr/(ur-qr)
  exact=arb(fmpq(rr.numerator,rr.denominator));assert R.overlaps(exact)
  return dict(bits=bits,epsilon_decimal_readback=eps,U_certificate_readback=disks['U_lower'],U_used=used,C_upper=caps,
    terms_upper=[directed(v,30,True) for v in terms],mu=str(mu),Q_upper=directed(Q,30,True),
    U_minus_Q_lower=directed(den,25,False),R_upper=directed(R,25,True),
    exact_rational_R_upper=directed(exact,25,True),mu_interval=[directed(lo,25,False),directed(hi,25,True)],
    k_interval=[directed(lo.sqrt(),25,False),directed(hi.sqrt(),25,True)],width_upper=directed(2*R,25,True),
    T15_margins_lower=[directed(lo-aa,24,False),directed(bb-hi,24,False)],seconds=time.perf_counter()-t,
    conditions=['same exact-input piecewise Helmholtz B field and all five residual certificates',
    'same-field disks with positive geometric clearances','rounding-inclusive band certificate required from this same pipeline run'])

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--groups',required=True);p.add_argument('--disks',required=True);p.add_argument('--output',required=True);a=p.parse_args()
  start=time.perf_counter();out=Path(a.output);data=json.loads(Path(a.input).read_text());groups=json.loads(Path(a.groups).read_text(),parse_float=str);disks=json.loads(Path(a.disks).read_text())
  result={'certificates':[],'assemblies':[]}
  for bits,n0 in [(192,256),(160,512)]:
    result['certificates'].append(certify(data,bits,n0));result['assemblies'].append(assembly(data,groups,disks,bits,result['certificates'][-1]))
  for key in ['Q_upper','R_upper','mu_interval','k_interval','width_upper','T15_margins_lower']:
    assert result['assemblies'][0][key]==result['assemblies'][1][key],key
  result['seconds']=time.perf_counter()-start;result['peak_process_rss_bytes']=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
  (out/'result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result['assemblies'][0],indent=2));print('PASS',result['seconds'])
if __name__=='__main__':main()
