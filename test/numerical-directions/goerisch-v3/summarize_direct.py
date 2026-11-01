"""Summarize checked and stopped direct refinements without rerunning MATLAB.
FEM is finite element method, RT Raviart-Thomas, CSV comma-separated values.
Input: experiment directory and explicit saved R-reference scalar result.
Output: summary.json and levels.csv in this experiment; arithmetic on saved scalars.
"""
import argparse,csv,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--experiment',required=True);p.add_argument('--reconstructed-reference',required=True);a=p.parse_args()
root=Path(a.experiment).resolve();load=lambda p:json.loads(Path(p).read_text())
pilot=load(root/'output/run-001/science/result.json');prod=load(root/'output/run-002/science/production.json');gen=load(root/'output/run-002/science/generation/generation.json');ev=load(root/'output/run-002/science/evaluator.json');reference=load(a.reconstructed_reference)
cfg=pilot['config'];target=cfg['target_width'];mu,nu,gamma=cfg['mu'],cfg['nu'],cfg['gamma']
def algebra(r):
 q,J=r['q'],r['J'];lo=(q-nu)/(1-nu*J)-gamma;hi=(q-mu)/(1-mu*J)-gamma;var=q*J-1
 width=(nu-mu)*var/((1-mu*J)*(nu*J-1));b=[q-2*x+x*x*J for x in [mu,nu]];k=[(1-x*J)/y for x,y in zip([mu,nu],b)]
 out={'lower':lo,'upper':hi,'width_subtraction':hi-lo,'width_formula':width,'width_difference':abs(hi-lo-width),'stored_width_difference':abs(width-r['width']),'qJ_minus_one':var,'positive_gram_denominators':b,'kappa':k,'contains_reference':lo<=cfg['mu_bie']<=hi}
 out['pass']=out['width_difference']<=1e-13 and out['stored_width_difference']<=1e-13 and var>0 and min(b)>0 and k[0]>1/(nu-mu) and k[1]<-1/(nu-mu) and out['contains_reference']
 return out
levels=[]
for name,degree,flux,r,v,accepted in [('P2-RT3',2,3,pilot['production'],pilot['verification'],True),('P2-RT2',2,2,pilot['coarse_rt2']['production'],pilot['coarse_rt2']['verification'],True),('P3-RT2',3,2,prod,None,False)]:
 independent=algebra(r);assert independent['pass']
 if v:
  scaled=r['q']*abs(v['J24']-r['J'])/r['qJ_minus_one'];qrel=abs(v['q24']-r['q'])/r['q'];qscale=abs(v['q24']-r['q'])/r['width']
  areas=max(x['relative_error'] for x in v['areas']);assert scaled<.01 and r['gram_scaled']<.01 and qrel<1e-12 and qscale<.01 and areas<1e-12
 else:scaled=qrel=qscale=None
 u=r['flux_unknowns'];full=sum(n*(e+i) for n,e,i in zip([13,1,13],u['template_edges'],u['template_interiors']))-28*(48*(flux+1))
 levels.append({'level':name,'fem_degree':degree,'flux_degree':flux,'fem_free_dofs':pilot['generation']['free_dofs'] if degree==2 else gen['free_dofs'],'flux_global_free_dofs':full,'flux_condensed_wall_free_dofs':u['global_wall_free'],'q':r['q'],'J':r['J'],'J_check':v['J24'] if v else None,'J_gram':r['J_gram'],'qJ_minus_one':r['qJ_minus_one'],'interval':r['enclosure'],'width':r['width'],'width_over_target':r['width']/target,'raw_width_below_target':r['width']<=target,'accepted':accepted,'accepted_target':accepted and r['width']<=target,'gram_scaled':r['gram_scaled'],'quadrature_scaled':scaled,'quotient_relative_change':qrel,'quotient_change_over_width':qscale,'independent_algebra':independent,'outer_normal_moment':r['outer_normal_moment'],'normal_trace_error':r['normal_trace_error'],'global_solve_residual':r['global_solve_residual'],'cell_solve_residual':r['cell_solve_residual']})
monitors={f.parent.name:load(f) for f in (root/'output').glob('run-*/monitor.json')}
summary={'target':target,'target_reached_by_accepted_level':False,'best_checked_level':'P2-RT3','nearest_measured_coarser_same_flux_level':'P2-RT2','stopping_reason':'P3/RT2 scaled Gram-pointwise difference 0.04424404161051467 exceeds 0.01; numerical work stopped before higher-order checks','levels':levels,'pilot_timing':{'production_seconds':pilot['production_seconds'],'cold_production_seconds':pilot['cold_production_seconds'],'verification_seconds':pilot['verification_seconds'],'coarse_control_extra_seconds':pilot['coarse_rt2_extra_seconds']},'failed_refinement_timing':{'field_generation_function_seconds':gen['seconds'],'field_generation_breakdown':gen['timing'],'goerisch_preparation_seconds_from_rounded_log':11.70,'functional_seconds':prod['seconds'],'full_production_seconds':None,'extra_verification_seconds':None,'missing_timing_reason':'assertion preceded final report; no timing was reconstructed from wall-time subtraction'},'refined_evaluator_check':ev,'monitors':monitors,'cumulative_monitored_seconds':sum(m['wall_seconds'] for m in monitors.values()),'peak_rss_gib':max(m['peak_process_tree_rss_gib'] for m in monitors.values()),'saved_R':{'source':str(Path(a.reconstructed_reference).resolve()),'width':reference['production']['width'],'cold_postprocessing_seconds':reference['cold_production_seconds'],'matlab_postprocessing_seconds':reference['production_seconds'],'verification_seconds':reference['verification_seconds'],'source_generation_cost_included':False},'TODO':['Resolve the Gram versus pointwise functional check before accepting P3.','Then run withheld order-24 integration and quotient normalization checks on that flux.','Retain complete production-stage timing before the acceptance assertion; current failed-run timing is partial.']}
(root/'summary.json').write_text(json.dumps(summary,indent=2))
fields=['level','fem_degree','flux_degree','flux_global_free_dofs','flux_condensed_wall_free_dofs','q','J','J_check','J_gram','qJ_minus_one','interval','width','width_over_target','accepted','accepted_target','gram_scaled','quadrature_scaled','quotient_relative_change','quotient_change_over_width']
with (root/'levels.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=fields,extrasaction='ignore');w.writeheader();w.writerows(levels)
print(json.dumps({'target_reached':False,'levels':[{k:l[k] for k in ['level','width','width_over_target','gram_scaled','quadrature_scaled','accepted','flux_global_free_dofs']} for l in levels],'cumulative_monitored_seconds':summary['cumulative_monitored_seconds'],'peak_rss_gib':summary['peak_rss_gib']},indent=2))
