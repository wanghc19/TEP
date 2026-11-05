"""Audit contiguous panel norms and compare the same arc's floating samples.
Input: explicit certified panel JSON files and same-run floating CSV.
Output: audit.json with independent Gauss integrals, upper bound and comparisons.
"""
import argparse,csv,json,sys,math
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from material import dump,up
from flint import acb,arb,ctx
ctx.prec=192
p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True);p.add_argument('--panels',nargs='+',required=True);p.add_argument('--samples',required=True);args=p.parse_args()
records=[json.loads(Path(f).read_text()) for f in args.panels]
samples=list(csv.DictReader(Path(args.samples).open()));N=len(samples);rows=[];bound2=arb(0);float2=0.
assert len({v['P'] for v in records})==1 and [v['panel'] for v in records]==list(range(records[0]['panel'],records[0]['panel']+len(records)))
for rec in records:
  h=arb(rec['h']);order=rec['p']+1;idx=rec['panel'];P=rec['P'];assert N%P==0
  co=[[acb(arb(re),arb(im)) for re,im in row] for row in rec['polynomial']]
  def evaluate(row,x):
    v=acb(0)
    for c in reversed(row):v=c+x*v
    return v
  V=arb(0)
  for i in range(order):
    x,w=arb.legendre_p_root(order,i,True)
    V+=h*w*sum((abs(evaluate(row,x))**2 for row in co),arb(0))
  stored=arb(rec['V']);relative=abs(V-stored)/stored.lower()
  assert V.overlaps(stored) and relative<arb('1e-12'),'Independent polynomial norm failed'
  er=arb(str(rec['e_upper']));candidate=V.upper().sqrt()+(2*h).sqrt()*er
  # Independently rebuild the radius, using outward printed e_upper. Tiny double
  # output rounding can change its final digits; compare with a relative guard.
  upper=arb(str(rec['epsilon_panel_upper']))
  assert abs(candidate-upper)/upper<arb('1e-12')
  bound2+=upper**2
  start=idx*N//P;end=(idx+1)*N//P;q=0.;maxdiff=0.
  for i in range(start,end+1):
    s=samples[i%N];j0=complex(float(s['J0_re']),float(s['J0_im']));j1=complex(float(s['J1_re']),float(s['J1_im']))
    w=float(s['weight']);q+=w*(abs(j0)**2+abs(j1)**2)*(.5 if i in [start,end] else 1.)
    u=arb(2*(i-start))/(end-start)-1;sqrt_speed=(w*N/(2*math.pi))**.5
    diffs=[abs(complex(evaluate(row,u))-z*sqrt_speed) for row,z in zip(co,[j0,j1])]
    maxdiff=max(maxdiff,*diffs)
  assert maxdiff<1e-10,'Signed floating sample comparison failed'
  float2+=q
  rows.append(dict(panel=idx,V_GL=str(V),relative_V_check=up(relative),floating_epsilon=q**.5,reliable_epsilon=up(upper),
    max_signed_sample_difference=maxdiff,ratio=up(upper)/q**.5))
result=dict(rows=rows,partial_upper=up(bound2.sqrt()),floating_partial=float2**.5,ratio=up(bound2.sqrt())/float2**.5,
  fraction_of_parameter_period=f'{len(rows)}/{P}',full_curve_status='PARTIAL')
dump(Path(args.output)/'audit.json',result)
