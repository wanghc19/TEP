"""Independently check scalar gap-end results and write a compact JSON handoff.
Input: successful baseline and scan output directories. Output: analysis.json.
"""
import argparse,csv,json,math
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--baseline',required=True);p.add_argument('--scan',required=True)
a=p.parse_args();b=Path(a.baseline);s=Path(a.scan)
bb=json.loads((b/'science/summary.json').read_text());base=bb['baseline'];high=bb['high_search']
rows={d:list(csv.DictReader((s/f'science/p{d}/scan.csv').open())) for d in [2,3]}
for rr in rows.values():
 for r in rr:
  for key,val in list(r.items()):
   if key!='reason':r[key]=float(val) if val else math.nan
near=lambda rr,k:next(r for r in rr if abs(r['k']-k)<1e-11)
cases=base['endpoint_cases'];q=base['levels'][0]['production']['q'];delta=base['levels'][0]['production']['qJ_square'];ref=2.428728670022710
independent=[]
for c in cases:
 m=c['alpha_minus']+1;n=c['alpha_plus']+1
 lo=q-1+q*n*delta/(q-n-n*delta);hi=q-1+q*m*delta/(q-m-m*delta)
 w=(n-m)*delta*q*q/((q-m-m*delta)*(n+n*delta-q))
 independent.append({'lower':lo,'upper':hi,'width':w,'width_relative_difference':abs(w/c['width']-1)})
final=[r for r in rows[3] if 1.32-1e-12<=r['k']<=2.37+1e-12]
highrows=[r for r in rows[3] if r['k']>=2.1875-1e-12]
variation={}
for name in ['left','right']:
 key=name+'_Z0_smin';kn=name+'_D_norm2';scale=[];drel=[];zrel=[]
 for r,t in zip(final,final[1:]):
  step=t['k']-r['k'];dz=abs(t[key]-r[key]);dn=abs(t[kn]-r[kn]);
  if step>1e-10 and dz>1e-14:scale.append(min(r[key],t[key])*step/dz)
  if step>1e-10:
   drel.append(dn/min(t[kn],r[kn]));zrel.append(dz/min(t[key],r[key]))
 closest=min(final,key=lambda r:r[key]);variation[name]={'min_Z0_smin':closest[key],'at_k':closest['k'],'at_mu':closest['mu'],
  'min_Z0_rcond':min(r[name+'_Z0_rcond'] for r in final),'max_D_norm2':max(r[kn] for r in final),
  'min_unit_gap':min(r[name+'_unit_gap'] for r in final),'min_observed_Z0_variation_scale_k':min(scale),'max_adjacent_relative_D_norm_change':max(drel),'max_adjacent_relative_Z0_change':max(zrel)}
reference_upper_edge=2.380844148165;reference_lower_edge=1.317414080243
scan_summary=json.loads((s/'science/summary.json').read_text());roots=scan_summary['p3']['roots'];roots=[roots] if isinstance(roots,dict) else roots
checks={
 'scan_root_matches_baseline':len(roots)==1 and roots[0]['resolved'] and roots[0]['center_residual']<1e-9 and abs(roots[0]['k']/base['generation']['frequency']-1)<1e-12,
 'reference_p2':base['p2_relative_difference']<=1e-12,'reference_p3':base['p3_relative_difference']<=1e-12,
 'reference_width':base['levels'][0]['production']['reference_width_relative']<=.005,
 'old_quadrature':base['levels'][0]['verification']['pass'],
 'high_solver_flags':all(x['flag']==0 for x in high['solves']),
 'high_candidate_count_zero':len(high['candidate_ids'])==0,
 'high_index_constant':len({r['negative_index'] for r in highrows})==1,
 'all_scan_points_valid':all(r['valid']==1 for rr in rows.values() for r in rr),
 'C_ratio':base['C_ratio_error']<.001,
 'contains_mu_BIE':all(c['contains_mu_BIE'] for c in cases),
 'independent_formula':all(c['width_relative_difference']<1e-12 for c in independent),
 'level_index_equal':all(near(rows[2],k)['negative_index']==near(rows[3],k)['negative_index'] for k in [1.32,2.1875,2.37,2.38]),
 'full_core_matches_schur':all(r['full_ldl_index']==r['negative_index'] for rr in rows.values() for r in rr if math.isfinite(r['full_ldl_index'])),
 'final_index_difference_one':near(rows[3],2.37)['negative_index']-near(rows[3],1.32)['negative_index']==1,
}
report={'checks':checks,'scan_roots':roots,'p2_frequency':base['p2_frequency'],'p3_frequency':base['generation']['frequency'],
 'p2_relative_difference':base['p2_relative_difference'],'p3_relative_difference':base['p3_relative_difference'],
 'reference_width_relative_difference':base['levels'][0]['production']['reference_width_relative'],
 'endpoint_cases':cases,'independent':independent,'C_ratio_relative_error':base['C_ratio_error'],
 'width_i_relative_increase':cases[1]['width']/cases[0]['width']-1,'candidate_count':len(high['candidate_ids']),
 'ritz_count':len(high['modes']),'in_window_ritz_count':sum(m['in_window'] for m in high['modes']),
 'high_index_min':min(r['negative_index'] for r in highrows),'high_index_max':max(r['negative_index'] for r in highrows),'high_grid_points':len(highrows),
 'endpoint_rows':[r for d in [2,3] for r in rows[d] if any(abs(r['k']-k)<1e-11 for k in [1.32,2.1875,2.37,2.38])],
 'final_scan_points':len(final),'all_p3_scan_points':len(rows[3]),'max_final_step_k':max(t['k']-r['k'] for r,t in zip(final,final[1:])),'max_final_step_mu':max(t['mu']-r['mu'] for r,t in zip(final,final[1:])),
 'lead_scan':variation,'recommended_alpha_plus':2.37**2,'sampled_upper_band_edge_k':reference_upper_edge,
 'upper_margin_k':reference_upper_edge-2.37,'upper_margin_mu':reference_upper_edge**2-2.37**2,
 'lower_margin_k':1.32-reference_lower_edge,'lower_margin_mu':1.32**2-reference_lower_edge**2,
 'reference_mu_BIE':ref,'cost':{f'run-{i:03}':json.loads((s.parent/f'run-{i:03}/monitor.json').read_text()) for i in sorted(int(f.parent.name.split('-')[-1]) for f in s.parent.glob('run-*/monitor.json') if int(f.parent.name.split('-')[-1])<=int(s.name.split('-')[-1]))}}
(s/'analysis.json').write_text(json.dumps(report,indent=2,allow_nan=False));print(json.dumps(report,indent=2,allow_nan=False))
raise SystemExit(0 if all(checks.values()) else 1)
