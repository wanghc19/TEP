"""Promote a completed empty-center cold run to portable canonical release data.
Input: completed run and explicit data/reference directories and example name.
Output: exact-input JSON data, scalar tables and reference certificates.
"""
import json,gzip,csv,struct,shutil
from pathlib import Path
from portable import clean

def read(path):
  path=Path(path);x=json.loads(gzip.decompress(path.read_bytes()) if path.suffix=='.gz' else path.read_text())
  return read(path.parent/x['archive']) if isinstance(x,dict) and 'archive' in x else x

def promote(run,data,ref,example):
  run=Path(run).resolve();data=Path(data);ref=Path(ref);data.mkdir(parents=True,exist_ok=True);ref.mkdir(parents=True,exist_ok=True)
  final=read(run/'result.json');assert final['status']=='COMPLETE' and final['example']==example
  case=read(run/'example-settings.json');assert case['example']==example
  root=Path(__file__).resolve().parent.parent;roots=[(root,'<PKG>'),(run,'<RUN>')]
  env=read(run/'environment.json')
  roots += [(env['matlab'],'<MATLAB>'),(env['fmm_source'],'<FMM_ROOT>')]
  for row in final['stages']:
    if row['stage']=='03-residuals':roots.append((row['command'][0],'<PYTHON>'))
  def write(path,x):path.write_text(json.dumps(clean(x,roots),indent=2)+'\n')
  for name in ['fixed-input.json','coefficients.json']:
    raw=gzip.decompress((run/'02-field'/(name+'.gz')).read_bytes());(data/name).write_bytes(raw)
  field=read(data/'fixed-input.json');assert field['example']==case['model']
  write(data/'example-settings.json',case);write(data/'disks-input.json',field['disks'])
  groups=read(run/'03-residuals/groups.json');assembly=read(run/'06-enclosure/result.json');band=read(run/'07-band/result.json');disks=read(run/'05-mass/disks.json');timing=read(run/'end-to-end.json');a=assembly['assemblies'][0]
  write(data/'band-inputs.json',dict(fourier_halfwidth=6,quadrature_nodes=2048,phase_scale=4096,phase_integer_endpoints=band['full_phase_integer_endpoints'],k_lower=case['evaluation']['k_lower'],k_upper=case['evaluation']['k_upper'],cell_widths=field['cell_widths'],angles=field['angles'] if 'angles' in field else [0,0,.13]))
  reference=dict(example=example,candidate=final['candidate'],assembly=a,band_minima=band['minima'],band_sign_tests=band['sign_tests'],settings=case,tolerances={'canonical_verify':'Identical printed scientific values on the tested environment, excluding timing and worker order.','new_reproduction':'Same candidate bits; interval width and nonzero epsilon/U/R within 1%; zero center group remains exactly zero.'})
  for name,x in [('results',reference),('groups',groups),('disks',disks),('trace-constants',assembly['certificates']),('band',band),('timing',timing),('stage-times',final['stages']),('conditions',read(run/'02-conditions/conditions.json')),('residual-audit',read(run/'04-residual-audit/summary.json'))]:write(ref/(name+'.json'),x)
  c=[r['published'] for r in assembly['certificates'][0]['rows']]
  with (ref/'group-budget.csv').open('w') as f:
    w=csv.writer(f);w.writerow(['group','C_upper','epsilon_upper','product_upper'])
    for row in zip(['center','left-material','right-material','walls','seams'],c,groups['epsilon_upper'],a['terms_upper']):w.writerow(row)
  tails=groups['tails'];right=[t for t in tails if t['side']==2]
  summary=dict(example=example,k=final['candidate']['k'],k_hex=final['candidate']['k_hex'],mu_interval=a['mu_interval'],k_interval=a['k_interval'],Q=a['Q_upper'],U=a['U_used'],R=a['R_upper'],width=a['width_upper'],delta_to_floating_edge=float(final['candidate']['k'])-float(case['floating_band_edge']),floating_edge=case['floating_band_edge'],right_norm_upper=right[0]['contraction']['norm_P_upper'],tails=[{k:t[k] for k in ['side','kind','N','N_check','p','tail_ratio_target','r_upper','relative_tail','B_upper']} for t in tails],band_minima=band['minima'],wall_seconds=timing['wall_seconds'],peak_rss_gib=max([timing['monitor']['peak_process_tree_rss_gib']]+[s['monitor']['peak_process_tree_rss_gib'] for s in final['stages']]))
  write(ref/'summary.json',summary)
  with (ref/'lead-tails.csv').open('w') as f:
    keys=['side','kind','N','N_check','p','tail_ratio_target','r_upper','relative_tail','B_upper','epsilon_upper'];w=csv.DictWriter(f,fieldnames=keys);w.writeheader();w.writerows({k:t[k] for k in keys} for t in tails)
  arrays=[]
  def walk(o,key,file):
    if isinstance(o,dict):
      if {'shape','real','imag'}<=o.keys():arrays.append(dict(file=file,key=key,shape=o['shape'],encoding='column-major binary64 hexadecimal words'))
      else:
        for k,v in o.items():walk(v,key+'.'+k,file)
    elif isinstance(o,list):
      for j,v in enumerate(o):walk(v,key+f'[{j}]',file)
  for name in ['fixed-input.json','coefficients.json']:walk(read(data/name),'$',name)
  write(data/'manifest.json',dict(schema='BIE_EMPTY_CENTER_V1',example=example,source='package cold reproduction',files=['fixed-input.json','coefficients.json','example-settings.json','disks-input.json','band-inputs.json'],arrays=arrays))
  return summary
