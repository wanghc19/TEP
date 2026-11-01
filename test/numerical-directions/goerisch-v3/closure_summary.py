"""Summarize the direct P3 closure using saved scalar outputs only.
P3 means cubic finite elements; RT means Raviart-Thomas; CSV is comma-separated values.
Input: explicit experiment, closure run and saved reconstructed-reference paths.
Output: closure-summary.json and closure-levels.csv; no numerical solver is launched.
"""
import argparse,csv,json
from pathlib import Path
p=argparse.ArgumentParser()
p.add_argument('--experiment',required=True);p.add_argument('--run',required=True);p.add_argument('--reconstructed-reference',required=True)
a=p.parse_args();root=Path(a.experiment);run=Path(a.run);load=lambda f:json.loads(Path(f).read_text())
b=load(run/'science/result.json');pilot=load(root/'output/run-001/science/result.json');ref=load(a.reconstructed_reference)
c=b['config'];mu,nu=c['mu'],c['nu'];lam=c['mu_bie'];target=c['target_width']
C=(lam+1)*(nu-mu)/((lam+1-mu)*(nu-lam-1))
def algebra(r):
 q,J=r['q'],r['J'];v=q*J-1;lo=(q-nu)/(1-nu*J)-1;hi=(q-mu)/(1-mu*J)-1
 w=(nu-mu)*v/((1-mu*J)*(nu*J-1));den=[q-2*t+t*t*J for t in [mu,nu]];kap=[(1-t*J)/d for t,d in zip([mu,nu],den)]
 out={'variance':v,'endpoints':[lo,hi],'endpoint_width':hi-lo,'scalar_width':w,'width_difference':abs(hi-lo-w),'record_width_difference':abs(w-r['width']),'denominators':den,'kappa':kap,'contains_reference':lo<=lam<=hi}
 out['pass']=v>0 and min(den)>0 and kap[0]>1/(nu-mu) and kap[1]<-1/(nu-mu) and out['contains_reference'] and out['width_difference']<=1e-13 and out['record_width_difference']<=1e-13
 if 'qJ_square' in r:
  z=r['qJ_square'];wl=(nu-mu)*z*q*q/((q-mu-mu*z)*(nu+nu*z-q));sl=q-1+q*nu*z/(q-nu-nu*z);su=q-1+q*mu*z/(q-mu-mu*z)
  sd=[((q-t)**2+t*t*z)/q for t in [mu,nu]];sk=[(q-t-t*z)/((q-t)**2+t*t*z) for t in [mu,nu]]
  out['square']={'variance':z,'width':wl,'endpoints':[sl,su],'width_difference':abs(su-sl-wl),'relative_variance_difference':abs(z-v)/v,'denominators':sd,'kappa':sk,'floor_ratio':wl/(C*(q-1-lam))}
  out['pass']=out['pass'] and min(sd)>0 and sk[0]>1/(nu-mu) and sk[1]<-1/(nu-mu) and wl/(C*(q-1-lam))>=.98
  out['pass']=out['pass'] and sl<=lam<=su and abs(su-sl-wl)<=1e-13 and abs(z-v)/v<.01
 return out
rows=[]
def add(name,r,status,source,verify=None):
 check=algebra(r);assert check['pass'],(name,check)
 floor=C*(r['q']-1-lam)
 row={'level':name,'source':source,'q':r['q'],'J':r['J'],'qJ_minus_one':r['qJ_minus_one'],'qJ_square':r.get('qJ_square'),'enclosure':r['enclosure'],'width':r['width'],'square_width':r.get('square_interval',{}).get('width'),'width_over_R':r['width']/target,'floor_prediction':floor,'width_over_floor':r['width']/floor,'accepted':status,'J_gram':r['J_gram'],'gram_absolute_difference':abs(r['J_gram']-r['J']),'gram_scaled':r['gram_scaled'],'independent_algebra':check}
 if verify:
  row.update({'J24':verify['J24'],'q24':verify['q24'],'quadrature_scaled':r['q']*abs(verify['J24']-r['J'])/r['qJ_minus_one'],'quotient_relative_change':abs(verify['q24']-r['q'])/r['q'],'quotient_change_over_width':abs(verify['q24']-r['q'])/r['width']})
  assert row['quadrature_scaled']<.01 and row['quotient_relative_change']<1e-12 and row['quotient_change_over_width']<.01
 rows.append(row)
add('P2/RT3',pilot['production'],True,'run-001/science/result.json',pilot['verification'])
add('P2/RT2',pilot['coarse_rt2']['production'],True,'run-001/science/result.json',pilot['coarse_rt2']['verification'])
for lev in b['levels']:
 add('P3/RT'+str(lev['degree']),lev['production'],lev.get('pass',False),str(run/'science/result.json'),lev.get('verification'))
add('R/RT3',ref['production'],True,str(a.reconstructed_reference))
monitors={f.parent.name:load(f) for f in (root/'output').glob('run-*/monitor.json')}
l=load(run/'launcher.json');f=load(run/'science/finish.json');first=b['levels'][0]
firstprod=b['startup_seconds']+first['production_ready_seconds'];firstcheck=first['timing']['verification']
totalprod=b['timing']['field_generation']+b['timing']['preparation']+b['timing']['evaluator_check']+b['timing']['cache_check']+sum(x['timing']['solve']+x['timing']['functional'] for x in b['levels'])
checks=sum(x['timing']['verification'] for x in b['levels'])
s={'status':b['status'],'all_checks_pass':b.get('pass',False),'fixed_R_width':target,'floor_constant':C,'levels':rows,'monitors':monitors,'closure_monitored_seconds':monitors[run.name]['wall_seconds'],'cumulative_monitored_seconds':sum(x['wall_seconds'] for x in monitors.values()),'closure_peak_rss_gib':monitors[run.name]['peak_process_tree_rss_gib'],'generation':b['generation'],'shared_timing':b['timing'],'preparation_timing':b['preparation_timing'],'per_degree_timing':[{k:x[k] for k in ['degree','timing','solve_timing','production_ready_seconds']} for x in b['levels']],'startup_seconds':b['startup_seconds'],'shutdown_seconds':l['shutdown_seconds'],'final_output_seconds':l['final_output_seconds'],'function_seconds':f['function_seconds'],'production_core_seconds_both_degrees':totalprod,'verification_seconds_both_degrees':checks,'first_P3_RT2_cold_production_seconds':firstprod,'first_P3_RT2_extra_checks_seconds':firstcheck,'first_P3_RT2_sum_seconds':firstprod+firstcheck,'first_RT2_cost_note':'Measured prefix production plus timed verification in the shared launch; output/orchestration is separately tabulated. RT3 is a warm continuation, not a standalone cold benchmark.','saved_R':{'cold_postprocessing_seconds':ref['cold_production_seconds'],'matlab_postprocessing_seconds':ref['production_seconds'],'verification_seconds':ref['verification_seconds'],'source_moment_generation_included':False},'cold_R_over_first_D_production':ref['cold_production_seconds']/firstprod,'timing_sum_error':b['timing_sum_error'],'launcher_reconciliation_error':l['reconciliation_error_seconds'],'evaluator':b['evaluator'],'native_trace':b['native_trace'],'cache':b['cache'],'primary_areas':b['primary_areas']}
assert abs(s['timing_sum_error'])<=max(.1,.01*f['function_seconds']) and l['timing_pass']
(root/'closure-summary.json').write_text(json.dumps(s,indent=2))
with (root/'closure-levels.csv').open('w') as f:
 fields=['level','q','J','qJ_minus_one','qJ_square','enclosure','width','square_width','width_over_R','width_over_floor','accepted','J_gram','gram_scaled']
 writer=csv.DictWriter(f,fieldnames=fields,extrasaction='ignore');writer.writeheader();writer.writerows(rows)
print(json.dumps({k:s[k] for k in ['status','all_checks_pass','closure_monitored_seconds','closure_peak_rss_gib','first_P3_RT2_cold_production_seconds','first_P3_RT2_extra_checks_seconds','cold_R_over_first_D_production']},indent=2))
for row in rows:print(json.dumps({k:row[k] for k in ['level','width','square_width','width_over_R','width_over_floor','gram_scaled']},indent=2))
