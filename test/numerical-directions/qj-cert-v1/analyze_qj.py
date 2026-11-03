"""Check retained Goerisch q/J certificate scalars without rerunning a solver.
Input: a completed certificate run. Output: analysis.json and class CSV tables.
"""
import argparse,csv,json,math
from decimal import Decimal,localcontext
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('run');a=p.parse_args();run=Path(a.run);sd=run/'science'
x=json.loads((sd/'certificates.json').read_text());inv=json.loads((sd/'inventory-exact.json').read_text());b=json.loads((sd/'baseline.json').read_text());f=json.loads((sd/'exact-flux.json').read_text())
rows=[]
for k,name in enumerate(['affine_untapered','quadratic_untapered','taper']):
 q16=[sum(t['native'][0][k][j] for t in inv['templates']) for j in range(3)];q24=[sum(t['native'][1][k][j] for t in inv['templates']) for j in range(3)]
 rows.append({'mesh':'native','class':name,'count':sum(t['counts_native'][k] for t in inv['templates']),**dict(zip(['E16','Mnative16','C16'],q16)),**dict(zip(['E24','Mnative24','C24'],q24)),**dict(zip(['E_difference','Mnative_difference','C_difference'],[abs(v-w) for v,w in zip(q16,q24)]))})
with (sd/'native-classes.csv').open('w') as o:w=csv.DictWriter(o,fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
srows=[]
for k,name in enumerate(['common_affine_untapered','interface_untapered','taper','common_quadratic_untapered']):
 v=sum(t['fitted'][0][k][0] for t in inv['templates']);w=sum(t['fitted'][1][k][0] for t in inv['templates']);srows.append({'class':name,'count':sum(t['counts_fitted'][k] for t in inv['templates']),'S16':v,'S24':w,'difference':abs(v-w)})
with (sd/'residual-classes.csv').open('w') as o:w=csv.DictWriter(o,fieldnames=srows[0].keys());w.writeheader();w.writerows(srows)
checks={'baseline':b['root_relative']<1e-12 and b['q_relative']<1e-12 and b['J_relative']<1e-12 and b['width_relative']<.001,
 'E_class_sum':abs(sum(r['E16'] for r in rows)/b['E']-1)<1e-13,'M_class_sum':abs(sum(r['Mnative16']+r['C16'] for r in rows)/b['M']-1)<1e-13,
 'S_class_sum':abs(sum(r['S16'] for r in srows)/f['S_after']-1)<1e-13,'exact_basis_change_expected':abs(f['S_change'])<1e-16,
 'polynomial_unit_diagnostics':x['polynomial_tests']['pass'],'global_E_contains_Q24':x['E_contains_Q24'],'global_M_contains_Q24':x['M_contains_Q24'],
 'mass_correction_contains_band16':x['mass_correction']['contains_band16'],'partial_corner_containment':x['corners_partial']['contains_mu_BIE']}
failed_literal=[];class_checks=[]
for v,t in zip(x['templates'],inv['templates']):
 for label,lo,hi,target in [
  ('E_quadratic',v['E_rational']-v['E_error'],v['E_rational']+v['E_error'],t['native'][1][1][0]),
  ('E_taper',v['E_taper_value']-v['E_taper_error'],v['E_taper_value']+v['E_taper_error'],t['native'][1][2][0]),
  ('M_taper',v['M_taper_value']-v['M_taper_error'],v['M_taper_value']+v['M_taper_error'],t['native'][1][2][1]),
  ('S_common_quadratic',v['S_common_rational']-v['S_error'],v['S_common_rational']+v['S_error'],t['fitted'][1][3][0]),
  ('S_taper_common',v['S_taper_value']-v['S_taper_error'],v['S_taper_value']+v['S_taper_error'],t['fitted'][1][2][0]-t['fitted'][1][2][1])]:
  r={'template':v['template'],'class':label,'interval':[lo,hi],'Q24':target,'literal_contains':lo<=target<=hi,'difference_from_midpoint':(lo+hi)/2-target}
  class_checks.append(r)
  if not r['literal_contains']:failed_literal.append(r)
# Independent check of the explicit per-arc bias formula and its global sum.
bias=0;bias_formula_error=0;correction_classes={name:{'C0':0.,'bias':0.,'integration_error':0.} for name in ['untapered','taper']}
for name in ['left','center','right']:
 for r in csv.DictReader((sd/f'{name}-mass-arcs.csv').open()):
  r={k:float(v) for k,v in r.items()};drho=3 if name=='center' else 16;V=r['V'];L=r['L'];d=r['D0'];d1=r['D1'];q1=r['Q1']
  z=drho*(2*V*L*d*d*(q1/2+d1/3)+L*L*d**3*(q1/3+d1/4));bias+=z
  c=correction_classes['taper' if abs(r['cell'])>=12 else 'untapered'];c['C0']+=r['C0'];c['bias']+=z;c['integration_error']+=r['C0_error']
  bias_formula_error=max(bias_formula_error,abs(z-r['bias']))
checks['bias_independent_sum']=abs(bias/x['mass_correction']['bias']-1)<1e-12
# Decimal is only an independent scalar evaluation, not rounding certification.
with localcontext() as ctx:
 ctx.prec=60;D=lambda z:Decimal.from_float(z);E=list(map(D,x['E']));M=list(map(D,x['M']));S=D(x['corners_partial']['S_upper']);s=D(x['corners_partial']['s']);lower=[];upper=[]
 for e in E:
  for m in M:
   q=1+e/m;d=q*S/m-(q-s)**2/s**2
   for t,out in [(D(1.32**2+1),upper),(D(2.37**2+1),lower)]:out.append(q-1+q*t*d/(q-t-t*d))
 lo=min(lower);hi=max(upper);width=hi-lo;penalty=width/D(b['width'])-1
 decimal_corner={'L':str(lo),'U':str(hi),'width':str(width),'penalty':str(penalty)}
Siface=x['S_interface_floating'];Stotal=inv['totals'][0][3]
r={'checks':checks,'correction_classes':correction_classes,'native_classes':rows,'residual_classes':srows,'nonzero_interval_Q24_checks':class_checks,'failed_literal_Q24':failed_literal,
 'decimal_partial_corners':decimal_corner,'printed_partial_width_penalty':x['corners_partial']['width']/b['width']-1,
 'E_certified_value':b['E'],'M_certified_value':b['M'],'S_smooth_value':Stotal-Siface,'S_interface_float_value':Siface,'S_smooth_share':1-Siface/Stotal,
 'coarse_signs_passed':sum(z>0 for row in x['corners_coarse']['signs'] for z in row),'partial_signs_passed':sum(z>0 for row in x['corners_partial']['signs'] for z in row),
 'eta_budget_ratio':x['S_extension']['eta']/x['S_extension']['allowed_eta'],'eta_squared_ratio_to_residual_budget':x['S_extension']['eta_squared']/(.005*Stotal),
 'bias_independent_sum':bias,'bias_formula_max_difference':bias_formula_error,
 'numerical_runs':{p.parent.name:json.loads(p.read_text()) for p in sorted(run.parent.glob('run-*/monitor.json'))},
 'extension_value_difference_status':'NOT_CERTIFIED_SWEEP_PATH_EXTENSION_COVERAGE_NOT_CHECKED','status':'PARTIAL_Q24_LITERAL_CHECK_AND_INTERFACE_S'}
(run/'analysis.json').write_text(json.dumps(r,indent=2));print(json.dumps({'checks':checks,'failed_literal_Q24':failed_literal,'decimal_partial_corners':decimal_corner,'S_smooth_share':r['S_smooth_share'],'eta_budget_ratio':r['eta_budget_ratio']},indent=2))
