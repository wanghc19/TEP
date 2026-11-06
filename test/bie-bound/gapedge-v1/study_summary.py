"""Study summary: CSV means comma-separated values, RSS resident set size.
Input: explicit accepted continuation JSON and completed cold-run directories.
Output: compact tables for intervals, tails, power checks, conditions and costs.
This postprocessor reads measurements; it performs no new scientific solve.
"""
import argparse,csv,json,math,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from summarize import read

def tail_row(t,L0,source):
  """Input: one accepted tail ledger. Output: scalar forecast/check row."""
  c=t['contraction'];d=t['power_demo']
  lo=float(t['choices'][-1]['finite_squared_lower'].lstrip('[').split()[0])
  pred=math.ceil(math.log(float(t['tail_ratio_target'])*lo/(t['B_upper']**2*c['geometric_factor_upper']*t['initial_state_norm_upper']**2))/(2*math.log(c['r_upper']**(1/c['p']))))
  return dict(L0=L0,source=source,side=t['side'],kind=t['kind'],N=t['N'],N_prediction=pred,tau=t['tail_ratio_target'],finite_squared_upper=t['finite_squared_upper'],tail_p1=t['tail_squared'],tail_ratio=t['relative_tail'],epsilon_upper=t['epsilon_upper'],N10_upper=t['N_plus_10_upper'],N10_tail=t['N_plus_10_tail_squared'],r1=c['r_upper'],r2=d['r_upper'],short_norm1=d['short_power_norm_upper'][1],factor1=c['geometric_factor_upper'],factor2=d['geometric_factor_upper'],tail_p2=d['tail_squared'],p2_N10_tail=d['tail_N_plus_10_squared'],p2_epsilon=d['epsilon_upper'],p2_N10_epsilon=d['N_plus_10_upper'],actual_state_N10_norm_ratio=t['tail_norm_ratio'],norm_P10_upper=c['norm_P10_upper'],p2_state_margin=d['state_margin_lower'],p2_checked=d['checked'],B=t['B_upper'],initial_state_norm=t['initial_state_norm_upper'])

def csv_write(path,rows):
  """Input: scalar rows. Output: one readable CSV."""
  with path.open('w') as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)

def main():
  p=argparse.ArgumentParser();p.add_argument('--accepted',required=True);p.add_argument('--runs',nargs='*',default=[]);p.add_argument('--output',required=True);a=p.parse_args();out=Path(a.output);out.mkdir(parents=True,exist_ok=True)
  acc=read(a.accepted);records=[dict(source='run-006 + run-007',boundary=acc['boundary'],L0=acc['L0'],k=acc['candidate']['k'],epsilon=acc['epsilon'],assembly=acc['assembly'],time=acc['stage_sum_seconds'],peak=acc.get('observed_process_tree_peak_RSS_GiB',acc['peak_RSS_GiB']),conditions=acc['conditions'],band=acc['band']['minima'],tails=acc['tails'],stages=acc['stages'],checks=acc['checks'])]
  for name in a.runs:
    root=Path(name);r=read(root/'result.json');assert r['status']=='COMPLETE';g=read(root/'03-residuals/groups.json');m=read(root/'end-to-end.json');d=read(root/'02-conditions/conditions.json');s=read(root/'03-residuals/summary.json');b=read(root/'07-band/result.json');au=read(root/'04-residual-audit/summary.json')
    stages=[dict(stage=x['stage'],seconds=x['driver_seconds'],peak_RSS_GiB=x['monitor']['peak_process_tree_rss_gib'],source=str(root/x['stage'])) for x in r['stages']]
    records.append(dict(source=root.name,boundary='one monitored cold-start process tree',L0=d['model']['L0'],k=r['candidate']['k'],epsilon=g['epsilon_upper'],assembly=r['assembly'],time=m['wall_seconds'],peak=m['monitor']['peak_process_tree_rss_gib'],conditions=d,band=b['minima'],tails=g['tails'],stages=stages,checks=dict(status=r['status'],band_tests=b['sign_tests'],independent_band_checks=len(b['independent']),failing_control_rejected=not b['failing_control']['check']['passed'],residual_audit=au),residual=dict(wall=s['wall_seconds'],cpu=s['cpu_seconds'],setup=s['setup']['seconds'],queue=s['queue_seconds'],workers=s['workers'],columns=s['states']),orchestration_seconds=r['orchestration_seconds'],outer_seconds=m['wall_seconds']-r['worker_seconds']))
  costs=[];tails=[];stages=[];conditions=[]
  for r in records:
    ass=r['assembly'];tt=[tail_row(t,r['L0'],r['source']) for t in r['tails']];tails.extend(tt)
    # Same computed finite fields and ten additional states give an independent
    # tighter tail-accounting diagnostic; this does not replace the delivered bound.
    eps=list(r['epsilon']);m1,m2=tt[0],tt[3]
    eps[1]=m1['N10_upper'];eps[2]=m2['N10_upper']
    for kind,group in [('interior',3),('seam',4)]:
      pair=[x for x in tt if x['kind']==kind]
      sq=eps[group]**2-sum(x['epsilon_upper']**2 for x in pair)+sum(x['N10_upper']**2 for x in pair)
      eps[group]=math.sqrt(max(0,sq))
    q10=sum(float(c)*v for c,v in zip(ass['C_upper'],eps));q=float(ass['Q_upper']);u=float(ass['U_used']);w=float(ass['width_upper']);w10=w*(q10/q)*(u-q)/(u-q10)
    r['tail_accounting_diagnostic']=dict(Q_with_N10=q10,width_with_N10=w10,width_inflation_relative=w/w10-1,status='ordinary scalar diagnostic from reliable ledgers; delivered interval unchanged')
    costs.append(dict(L0=r['L0'],source=r['source'],time_boundary=r['boundary'],k=r['k'],Q=ass['Q_upper'],U=ass['U_used'],width=ass['width_upper'],seconds=r['time'],peak_RSS_GiB=r['peak'],width_N10_diagnostic=w10,tail_width_inflation=w/w10-1))
    for st in r['stages']:stages.append(dict(L0=r['L0'],**st))
    conditions.append(dict(L0=r['L0'],source=r['source'],U_minus_Q=ass['U_minus_Q_lower'],gap_left=ass['T15_margins_lower'][0],gap_right=ass['T15_margins_lower'][1],wood=r['conditions']['wood_gamma_lower'],left_r=tt[0]['r1'],right_r=tt[3]['r1'],band_left_lower=r['band'][0]['lower'],band_left_upper=r['band'][0]['upper'],band_right_lower=r['band'][1]['lower'],band_right_upper=r['band'][1]['upper']))
    r['tails']=tt
  for name,rows in [('cost-width',costs),('tail-comparison',tails),('stage-cost',stages),('conditions',conditions)]:csv_write(out/(name+'.csv'),rows)
  (out/'study-results.json').write_text(json.dumps(records,indent=2))
  print(json.dumps(costs,indent=2))
if __name__=='__main__':main()
