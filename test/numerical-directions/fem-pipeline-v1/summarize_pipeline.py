"""Summarize the finite element method pipeline's scalar records.
Input: a completed monitored run directory. Output: summary.json and stages.csv.
JSON means JavaScript Object Notation; CSV means comma-separated values.
No scientific solver is called. Reference numbers are used only for checks.
"""
import argparse,csv,json,math,re
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('run');a=p.parse_args();out=Path(a.run);s=out/'science'
r=json.loads((s/'result.json').read_text());l=json.loads((out/'launcher.json').read_text());m=json.loads((out/'monitor.json').read_text());f=json.loads((s/'finish.json').read_text())
x=r['levels'][0];v=x['production'];c=x['verification'];t=r['timing'];q=v['q'];e=v['qJ_square'];mu=r['config']['mu'];nu=r['config']['nu'];ref=2.428728670022710
lo=q-1+q*nu*e/(q-nu-nu*e);hi=q-1+q*mu*e/(q-mu-mu*e)
w=(nu-mu)*e*q*q/((q-mu-mu*e)*(nu+nu*e-q))
rows=[('startup',l['startup_seconds']),('P2_search',t['wide_search']),('P3_generation',t['field_generation']),('prepare',t['preparation']),('evaluator_check',t['evaluator_check']),('cache_check',t['cache_check']),('RT3_assembly_solve',x['timing']['solve']),('RT3_functional',x['timing']['functional']),('checks_24',x['timing']['verification']),('checkpoint_output',t['output']),('orchestration',t['orchestration']),('final_output',l['final_output_seconds']),('output_exit',l['output_exit_seconds']),('monitor_wrapper_adjustment',-l['wrapper_minus_monitor_seconds'])]
checks={'P2_relative':abs(r['p2_frequency']-1.5584630910866906)/1.5584630910866906,'P3_relative':abs(r['generation']['frequency']-1.5584378944019319)/1.5584378944019319,'width_relative':abs(w-4.69595266302784e-9)/4.69595266302784e-9,'contains_mu_BIE':lo<=ref<=hi,'endpoint_width_difference':hi-lo-w,'stored_endpoints_difference':max(abs(lo-v['square_interval']['enclosure'][0]),abs(hi-v['square_interval']['enclosure'][1])),'timing_difference':sum(y for _,y in rows)-m['wall_seconds'],'production_pass':v['pass'],'verification_pass':c['pass'],'preparation_pass':r['preparation_pass'],'evaluator_pass':r['evaluator']['pass'],'cache_pass':r['cache']['pass']}
checks['all_pass']=all(checks[k] for k in ['contains_mu_BIE','production_pass','verification_pass','preparation_pass','evaluator_pass','cache_pass']) and checks['P2_relative']<=1e-12 and checks['P3_relative']<=1e-12 and checks['width_relative']<=.005 and abs(checks['endpoint_width_difference'])<=1e-13 and abs(checks['timing_difference'])<=.1
root=Path(__file__).resolve().parent;hits=[];forbidden=[]
pattern=re.compile(r'1\.558|2\.428|native\.mat|/epost/|output/|load\(')
for path in sorted(root.glob('*.m')):
 for n,line in enumerate(path.read_text().splitlines(),1):
  if pattern.search(line):
   row={'file':path.name,'line':n,'text':line};hits.append(row)
   if path.name!='validation_values.m':forbidden.append(row)
provenance={'matches':hits,'unexpected_matches':forbidden,'pass':not forbidden,'P2_to_P3_same_value':r['p2_frequency']==r['generation']['initial_frequency'],'P3_initial_frequency':r['generation']['initial_frequency'],'P2_candidates':[z for z in r['search']['modes'] if z['candidate']]}
checked_total=m['wall_seconds'];checkseconds=x['timing']['verification'];core=t['wide_search']+t['field_generation']+t['preparation']+x['timing']['solve']+x['timing']['functional']
bie=39.87983062500001+508.24273658333317+5.739799666666666+19.932650792+96.0841365
summary={'status':r['status'],'P2_candidates':provenance['P2_candidates'],'P3_root':r['generation']['frequency'],'q':q,'J':v['J'],'J_check':c['J24'],'J_gram':v['J_gram'],'qJ_minus_one':v['qJ_minus_one'],'qJ_square':e,'interval':[lo,hi],'width':w,'checks':checks,'provenance':provenance,'monitor':m,'timings':dict(rows),'scientific_production_seconds':core,'additional_quadrature_checks_seconds':checkseconds,'checked_total_seconds':checked_total,'startup_to_primary_interval_seconds':r['startup_seconds']+x['production_ready_seconds'],'BIE_historical_stage_sum_seconds':bie,'BIE_stage_sum_over_checked_FEM_process':bie/checked_total,'stage_sum_seconds':sum(y for _,y in rows)}
(out/'summary.json').write_text(json.dumps(summary,indent=2));(out/'provenance.json').write_text(json.dumps(provenance,indent=2))
with (out/'stages.csv').open('w') as f:
 writer=csv.writer(f);writer.writerow(['stage','seconds']);writer.writerows(rows)
print(json.dumps(summary,indent=2));assert checks['all_pass'] and provenance['pass'] and provenance['P2_to_P3_same_value']
