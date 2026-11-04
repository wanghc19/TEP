"""Compare saved source-split runs using scalar arithmetic only.
Input: explicit pilot, full-comparison and fine-confirmation run directories.
Output: combined-summary.json in the fine run, with acceptance and cost data.
"""
import argparse,csv,json,math
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('pilot',type=Path);p.add_argument('full',type=Path);p.add_argument('fine',type=Path);a=p.parse_args()
def read(d,name):return json.loads((d/name).read_text())
f=read(a.full,'result.json');g=read(a.fine,'result.json')
assert f['status']==g['status']=='COMPLETE'
x=next(r for r in f['rows'] if r['rule']=='split' and r['source_nodes']==384 and r['targets']==768)
y=next(r for r in g['rows'] if r['targets']==768)
z=next(r for r in f['rows'] if r['rule']=='split' and r['source_nodes']==384 and r['targets']==1536)
keys=['left_normal','right_normal','junction_value','inner_normal','inner_value','wall_total']
source={k:y[k]/x[k]-1 for k in keys};target={k:z[k]/x[k]-1 for k in keys}
def samples(d,name):
  with (d/name).open() as h:return [[float(v) for v in r] for r in csv.reader(h)]
def difference(u,v):
  out={}
  for label,re,im in [('left_value',1,5),('right_value',2,6),('left_normal',3,7),('right_normal',4,8)]:
    delta=[complex(x[re]-y[re],x[im]-y[im]) for x,y in zip(u,v)]
    out[label]={'maximum':max(map(abs,delta)),'L2':math.sqrt(sum(abs(z)**2 for z in delta)/len(delta))}
  return out
coarse=samples(a.full,'split-384-direct-t768.csv');fine=samples(a.fine,'split-768-direct-t768.csv')
trap384=samples(a.full,'trap-384-direct-t768.csv');trap=samples(a.full,'trap-1536-direct-t768.csv');fmm=samples(a.full,'trap-1536-fmm-t768.csv')
monitors=[read(d,'monitor.json') for d in [a.pilot,a.full,a.fine]]
s={'source_relative_change_384_to_768':source,'target_relative_change_768_to_1536_at_source384':target,
   'source_check_pass':max(abs(source[k]) for k in ['left_normal','right_normal'])<.01,
   'field_Q5_relative_difference':g['baseline']['Q5']/f['baseline']['Q5']-1,
   'split_source_pointwise_difference':difference(coarse,fine),'trapezoid1536_minus_split768':difference(trap,fine),
   'fmm_minus_direct1536':difference(fmm,trap),'trapezoid384_minus_split768':difference(trap384,fine),'finest_row':y,'budget':g['finest_split_budget'],
   'monitored_total_seconds':sum(m['wall_seconds'] for m in monitors),'peak_process_tree_rss_gib':max(m['peak_process_tree_rss_gib'] for m in monitors),
   'monitors':monitors}
s['observed_source_error_order_384_to_1536']={k:math.log(s['trapezoid384_minus_split768'][k]['L2']/s['trapezoid1536_minus_split768'][k]['L2'])/math.log(4) for k in ['left_normal','right_normal']}
(a.fine/'combined-summary.json').write_text(json.dumps(s,indent=2)+'\n')
print(json.dumps(s,indent=2))
