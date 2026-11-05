"""Validate exact dyadic coverage and combine leaf bounds by RE16 in Arb.
Input: explicit completed run and floating comparison. Output: reliable group upper and statistics.
RE16 is the target-panel residual summation rule; CSV means comma-separated values.
"""
import argparse,csv,json,sys,time
from fractions import Fraction
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,acb,acb_poly,ctx
from material import dump,up

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True)
  p.add_argument('--run',type=Path,required=True);p.add_argument('--floating',default='1.2611637248633255e-12');a=p.parse_args()
  ctx.prec=192;ctx.threads=1;start=time.perf_counter();q=json.loads((a.run/'queue.json').read_text())
  assert q['all_requested_valid'] and q['first']==0 and q['count']==192
  tasks=[json.loads((a.run/f'task-{i}.json').read_text()) for i in range(192)]
  rows=[];intervals=[];all_paths=[];sum2=arb(0);nodes={};max_norm=arb(0)
  for t in tasks:
    assert t['valid'] and not t['failed']
    for leaf in t['leaves']:
      path=leaf['path'];assert path not in all_paths;all_paths.append(path)
      r=json.loads((a.run/path).read_text());idx=r['panel'];d=r['depth'];j=r['sub']
      assert idx==t['panel'] and d<=2 and 0<=j<2**d
      intervals.append((Fraction(idx)+Fraction(j,2**d),Fraction(idx)+Fraction(j+1,2**d)))
      h=arb.pi()/(192*2**d);D=r['p'];co=[[acb(arb(x),arb(y)) for x,y in row] for row in r['polynomial']]
      if D not in nodes:nodes[D]=[arb.legendre_p_root(D+1,i,True) for i in range(D+1)]
      polynomials=[acb_poly(row) for row in co]
      V=sum((h*w*sum((abs(poly(x))**2 for poly in polynomials),arb(0)) for x,w in nodes[D]),arb(0))
      oldV=arb(r['V']);rel=abs(V-oldV)/oldV.lower()
      assert V.overlaps(oldV) and rel<arb('1e-12'),'Independent polynomial norm check failed'
      max_norm=max(max_norm,rel.upper())
      # Each printed term is an outward upper endpoint. Their sum can be a
      # few ulps wider than the stored sum; use this new sum for the group bound.
      e=sum((arb(str(v)) for v in r['terms'].values()),arb(0))
      bound=V.upper().sqrt()+(2*h).sqrt()*e
      assert abs(bound-arb(str(r['epsilon_panel_upper'])))/bound<arb('1e-12')
      assert all(v['passed'] for v in r['control']['points']) and all(r['direct_radial_check'])
      assert r['geometry_certificate']['branch_integer']==0
      sum2+=bound.upper()**2
      sr=r['self_record']
      rows.append(dict(panel=idx,depth=d,sub=j,L=sr['L'],Rt=sr['Rt'],rho=sr['rho'],
        M_self=sr['M_self'],e_self=sr['e_self'],e_I=r['e_upper'],epsilon_upper=up(bound),
        large_chord_lower=sr['large_domain']['min_real_chord_square'],small_chord_lower=sr['small_domain']['min_real_chord_square'],
        large_speed_lower=sr['large_domain']['min_real_speed_square'],small_speed_lower=sr['small_domain']['min_real_speed_square'],
        working_error_flag=not sr['gates']['self_error'],production_seconds=r['seconds'],total_seconds=r['total_seconds_with_controls'],
        cpu_seconds=r['cpu_seconds'],relative_norm_check=up(rel)))
  intervals.sort();cursor=Fraction(0)
  for lo,hi in intervals:
    assert lo==cursor and hi>lo,'Panel coverage has a gap or overlap';cursor=hi
  assert cursor==192
  bound=sum2.sqrt().upper();floating=arb(a.floating)
  def stats(key):
    values=sorted(r[key] for r in rows);n=len(values)
    return dict(min=values[0],median=values[n//2],p90=values[min(n-1,int(.9*n))],max=values[-1])
  summary=dict(status='WHOLE_CURVE_BOUND',base_panels=192,leaf_panels=len(rows),epsilon_upper=up(bound),squared_bound_ball=str(sum2),
    floating_reference=a.floating,ratio_to_floating=up(bound/floating),relative_norm_check_max=up(max_norm),
    coverage='exact dyadic partition of [0,192], corresponding to [0,2*pi]',
    larger_L=[r for r in rows if r['L']>40],smaller_Rt=[r for r in rows if float(arb(r['Rt']))<.039],
    split_base_panels=sorted(set(r['panel'] for r in rows if r['depth'])),high_self_error=[r for r in rows if r['working_error_flag']],
    statistics={key:stats(key) for key in ['L','e_self','e_I','epsilon_upper','total_seconds']},
    largest_contributions=sorted(rows,key=lambda r:r['epsilon_upper'],reverse=True)[:10],seconds=time.perf_counter()-start,cpu_seconds=time.process_time())
  out=Path(a.output);dump(out/'aggregate.json',summary)
  with (out/'panels.csv').open('w') as f:
    writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
  print(json.dumps({k:summary[k] for k in ['status','leaf_panels','epsilon_upper','ratio_to_floating','seconds']}),flush=True)
if __name__=='__main__':main()
