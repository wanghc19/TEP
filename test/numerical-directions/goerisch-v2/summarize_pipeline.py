"""Summarize scalar Goerisch records and independently check interval algebra.
R means reconstructed trial; D direct trial; RSS resident set size.
Input: successful D and R run directories, and an explicit output directory.
Output: summary.json, benchmark.csv, timings.csv; no numerical field computation.
"""
import argparse,csv,json,math
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--direct',required=True);p.add_argument('--reconstructed',required=True);p.add_argument('--output',required=True)
a=p.parse_args();out=Path(a.output);out.mkdir(parents=True,exist_ok=True)
rows=[];records={}
for kind,folder in [('D',a.direct),('R',a.reconstructed)]:
    folder=Path(folder);r=json.loads((folder/'science/result.json').read_text());m=json.loads((folder/'monitor.json').read_text());l=json.loads((folder/'launcher.json').read_text());v=r['production'];c=r['config']
    q,J=v['q'],v['J'];mu,nu=c['mu'],c['nu'];gamma=c['gamma']
    low=(q-nu)/(1-nu*J)-gamma;high=(q-mu)/(1-mu*J)-gamma
    width=(nu-mu)*(q*J-1)/((1-mu*J)*(nu*J-1))
    b2=[q-2*t+t*t*J for t in [mu,nu]];kappa=[(1-t*J)/b for t,b in zip([mu,nu],b2)]
    independent={'lower':low,'upper':high,'width_formula':width,'width_endpoints':high-low,'endpoint_formula_error':abs(high-low-width),'record_width_error':abs(width-v['width']),'record_endpoint_error':max(abs(low-v['enclosure'][0]),abs(high-v['enclosure'][1])),'qJ_minus_one':q*J-1,'gram_denominators':b2,'kappa':kappa,'contains_reference':low<=c['mu_bie']<=high}
    independent['pass']=(max(independent[k] for k in ['endpoint_formula_error','record_width_error','record_endpoint_error'])<=1e-13 and q*J-1>0 and min(b2)>0 and kappa[0]>1/(nu-mu) and kappa[1]<-1/(nu-mu) and independent['contains_reference'])
    assert independent['pass'] and v['pass'] and r['verification']['pass'] and r['cache_check']['pass'] and all(r['unchanged'].values()) and r['timing_pass'] and l['reconciliation_pass']
    row={'trial':kind,'run':str(folder),'cold_production_seconds':r['cold_production_seconds'],'matlab_production_seconds':r['production_seconds'],'additional_verification_seconds':r['verification_seconds'],'cold_production_plus_verification_seconds':r['cold_plus_verification_seconds'],'monitored_wall_seconds':m['wall_seconds'],'peak_rss_gib':m['peak_process_tree_rss_gib'],'q':q,'J':J,'J24':r['verification']['J24'],'J_gram':v['J_gram'],'qJ_minus_one':v['qJ_minus_one'],'lower':low,'upper':high,'width':v['width']}
    rows.append(row);records[kind]={'benchmark':row,'independent_algebra':independent,'production_timing':r['production_timing'],'verification_timing':r['verification_timing'],'counts':r['counts'],'cache_check':r['cache_check'],'unchanged':r['unchanged'],'baseline_q_relative':v['baseline_q_relative'],'baseline_width_relative':v['baseline_width_relative'],'baseline_J_scaled':v['baseline_J_scaled'],'quadrature_scaled':r['verification']['scaled_quadrature'],'gram_scaled':v['gram_scaled'],'startup_seconds':r['startup_to_entry_seconds'],'wall_reconciliation':l}
D,R=rows
ratios={'width_D_over_R':D['width']/R['width'],'cold_production_R_over_D':R['cold_production_seconds']/D['cold_production_seconds'],'matlab_production_R_over_D':R['matlab_production_seconds']/D['matlab_production_seconds'],'verification_R_over_D':R['additional_verification_seconds']/D['additional_verification_seconds'],'cold_plus_verification_R_over_D':R['cold_production_plus_verification_seconds']/D['cold_production_plus_verification_seconds'],'monitored_wall_R_over_D':R['monitored_wall_seconds']/D['monitored_wall_seconds']}
root=Path(__file__).resolve().parent
monitors={str(f.parent.relative_to(root)):json.loads(f.read_text()) for f in (root/'output').glob('run-*/monitor.json')}
summary={'measurement_boundary':'fresh MATLAB process; native FEM input and saved source blocks already exist; no filesystem cache flush','records':records,'ratios':ratios,'total_monitored_compute_seconds':sum(m['wall_seconds'] for m in monitors.values()),'maximum_peak_rss_gib':max(m['peak_process_tree_rss_gib'] for m in monitors.values()),'monitors':monitors}
(out/'summary.json').write_text(json.dumps(summary,indent=2))
with (out/'benchmark.csv').open('w') as f:
    w=csv.DictWriter(f,fieldnames=list(D));w.writeheader();w.writerows(rows)
with (out/'timings.csv').open('w') as f:
    w=csv.writer(f);w.writerow(['trial','stage','component','seconds'])
    for kind,r in records.items():
        for stage in ['production_timing','verification_timing']:
            for k,v in r[stage].items():w.writerow([kind,stage,k,v])
print(json.dumps({'ratios':ratios,'total_monitored_compute_seconds':summary['total_monitored_compute_seconds'],'maximum_peak_rss_gib':summary['maximum_peak_rss_gib']},indent=2))
