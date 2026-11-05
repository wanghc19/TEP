"""Compare two exact binary64 field exports after production has completed.
Input: explicit old/new field, B-fit and fit-summary paths, and output file.
Output: floating coefficient differences explaining sensitivity of small residuals.
This diagnostic never supplies values to the reliable pipeline.
"""
import argparse,json,struct
from pathlib import Path

def values(p):
  def seq(s):return [s] if isinstance(s,str) else s
  return [complex(struct.unpack('>d',bytes.fromhex(x))[0],struct.unpack('>d',bytes.fromhex(y))[0]) for x,y in zip(seq(p['real']),seq(p['imag']))]

def main():
  p=argparse.ArgumentParser()
  for key in ['old-field','new-field','old-fit','new-fit','old-summary','new-summary','output']:p.add_argument('--'+key,required=True)
  a=p.parse_args();args=vars(a);data={k:json.loads(Path(v).read_text()) for k,v in args.items() if k!='output'}
  old,new=data['old_field'],data['new_field'];fit0,fit1=data['old_fit'],data['new_fit'];rec=dict(inputs=args,used_after_production_only=True,proxy_positions_identical=fit0['Z']==fit1['Z'])
  for name,x,y in [('incident',old['incident'],new['incident']),('central_tau',old['pieces'][0]['tau_coeff'],new['pieces'][0]['tau_coeff']),('central_zeta',old['pieces'][0]['zeta_coeff'],new['pieces'][0]['zeta_coeff']),('B_center',fit0['B_center'],fit1['B_center'])]:
    v,w=values(x),values(y);assert len(v)==len(w)
    rec[name]=dict(max_absolute_change=max(abs(c-d) for c,d in zip(v,w)),sum_absolute_change=sum(abs(c-d) for c,d in zip(v,w)),old_max=max(map(abs,v)),old_sum=sum(map(abs,v)))
  rec['old_fit_max']=data['old_summary']['fit_B']['fit_max'];rec['new_fit_max']=data['new_summary']['fit']['fit_max'];rec['old_rank']=data['old_summary']['fit_B']['rank'];rec['new_rank']=data['new_summary']['fit']['rank']
  Path(a.output).write_text(json.dumps(rec,indent=2));print(json.dumps(rec,indent=2))
if __name__=='__main__':main()
