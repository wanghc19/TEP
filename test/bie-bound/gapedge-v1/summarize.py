"""Summarize explicit completed near-edge runs; CSV is comma-separated values.
Input: one or more run directories and an explicit summary destination.
Output: compact scalar JSON/CSV with stage costs, intervals and tail forecasts.
"""
import argparse,csv,gzip,json,math
from pathlib import Path

def read(path):
  p=Path(path);d=json.loads(gzip.decompress(p.read_bytes()) if p.suffix=='.gz' else p.read_text())
  return read(p.parent/d['archive']) if isinstance(d,dict) and 'archive' in d else d

def main():
  p=argparse.ArgumentParser();p.add_argument('--runs',nargs='+',required=True);p.add_argument('--output',required=True);a=p.parse_args();out=Path(a.output);out.mkdir(exist_ok=True,parents=True);runs=[];tailrows=[]
  for name in a.runs:
    root=Path(name);f=read(root/'result.json');g=read(root/'03-residuals/groups.json');s=read(root/'03-residuals/summary.json');e=read(root/'end-to-end.json');d=read(root/'02-conditions/conditions.json');b=read(root/'07-band/result.json');ass=f['assembly'];rows=[]
    for tr in g['tails']:
      factor=tr['contraction']['geometric_factor_upper'];r=tr['r_upper'];power=tr['p'];c=tr['initial_state_norm_upper'];B=tr['B_upper'];tau=float(tr['tail_ratio_target']);lo=float(tr['choices'][-1]['finite_squared_lower'].lstrip('[').split()[0])
      pred=math.ceil(math.log(tau*lo/(B*B*factor*c*c))/(2*math.log(r**(1/power))))
      x=dict(run=root.name,L0=d['model']['L0'],side=tr['side'],kind=tr['kind'],N=tr['N'],N_pred=pred,p=power,r=r,tail_ratio=tr['relative_tail'],epsilon_upper=tr['epsilon_upper'],B=B,c_norm=c,factor=factor,finite_squared_lower=lo,tail_squared=tr['tail_squared'],N10_upper=tr['N_plus_10_upper'],p2_r=tr['power_demo']['r_upper'],p2_tail=tr['power_demo']['tail_squared'],p2_upper=tr['power_demo']['epsilon_upper'],p2_state_margin=tr['power_demo']['state_margin_lower']);rows.append(x);tailrows.append(x)
    runs.append(dict(run=root.name,L0=d['model']['L0'],k=f['candidate']['k'],k_hex=f['candidate']['k_hex'],epsilon=g['epsilon_upper'],assembly=ass,wall=e['wall_seconds'],peak_RSS_GiB=e['monitor']['peak_process_tree_rss_gib'],workers=s['workers'],states=s['states'],residual_wall=s['wall_seconds'],residual_cpu=s['cpu_seconds'],residual_queue=s['queue_seconds'],setup=s['setup'],tails=rows,conditions=d,band_minima=b['minima'],band_tests=b['sign_tests'],stages=[dict(name=x['stage'],seconds=x['driver_seconds'],peak_RSS_GiB=x['monitor']['peak_process_tree_rss_gib']) for x in f['stages']]))
  (out/'reference-results.json').write_text(json.dumps(runs,indent=2))
  with (out/'tails.csv').open('w') as f:
    w=csv.DictWriter(f,fieldnames=list(tailrows[0]));w.writeheader();w.writerows(tailrows)
  with (out/'cost-width.csv').open('w') as f:
    cols=['run','L0','k','width','Q','U','wall','peak_RSS_GiB','workers','states'];w=csv.DictWriter(f,fieldnames=cols);w.writeheader()
    for r in runs:w.writerow({**{k:r[k] for k in cols if k in r},'width':r['assembly']['width_upper'],'Q':r['assembly']['Q_upper'],'U':r['assembly']['U_used']})
  print(json.dumps([dict(run=r['run'],L0=r['L0'],width=r['assembly']['width_upper'],wall=r['wall'],peak=r['peak_RSS_GiB']) for r in runs],indent=2))
if __name__=='__main__':main()
