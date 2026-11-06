"""Promote a completed package reproduction to canonical data and references.
Input: explicit completed run, data directory, reference directory.
Output: exact JSON field data, dictionary manifest and compact certificate tables.
This is a release-maintenance action, not a scientific runtime prerequisite.
"""
import argparse,json,shutil,csv,struct,sys
from pathlib import Path
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).resolve().parent))

def write(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
def packed(x):
  if isinstance(x,float):return {'binary64':struct.pack('>d',x).hex()}
  if isinstance(x,dict):return {k:packed(v) for k,v in x.items()}
  if isinstance(x,list):return [packed(v) for v in x]
  return x

def main():
  p=argparse.ArgumentParser();p.add_argument('--example',choices=['ex1','ex2-L1','ex2-L1.6','ex2-L1.9','ex2-L2'],default='ex1');p.add_argument('--run',required=True);p.add_argument('--data',required=True);p.add_argument('--reference',required=True);a=p.parse_args();run=Path(a.run);data=Path(a.data);ref=Path(a.reference);data.mkdir(parents=True,exist_ok=True);ref.mkdir(parents=True,exist_ok=True)
  if a.example!='ex1':
    from promote_family import promote
    print(promote(run,data,ref,a.example));return
  final=json.loads((run/'result.json').read_text());assert final['status']=='COMPLETE'
  for name in ['fixed-input.json','coefficients.json']:shutil.copyfile(run/'02-field'/name,data/name)
  field=json.loads((data/'fixed-input.json').read_text());fit=json.loads((data/'coefficients.json').read_text());config=json.loads((run/'02-field/result.json').read_text())['config']
  write(data/'model.json',packed(config));write(data/'disks-input.json',field['disks'])
  # Exact integer panel chain, and rational scalar band inputs.
  end=([0,1024,1536,2048,2560,2816,3072,3200,3328,3392,3456,3520,3584,3616,3648,3680,3712,3744]+list(range(3760,3889,16))+list(range(3896,3953,8))+list(range(3956,4005,4))+list(range(4006,4047,2))+list(range(4047,4097)))
  write(data/'band-inputs.json',dict(fourier_halfwidth=6,quadrature_nodes=2048,phase_scale=4096,phase_endpoints=end,k_gap_rational=['659/500','19/8'],beta_rational='1/2',periods=[1,1],rho_background=1,rho_inclusion=17))
  assembly=json.loads((run/'06-enclosure/result.json').read_text());groups=json.loads((run/'03-residuals/groups.json').read_text());band=json.loads((run/'07-band/result.json').read_text());disks=json.loads((run/'05-mass/disks.json').read_text())
  reference=dict(candidate=final['candidate'],assembly=assembly['assemblies'][0],band_minima=band['minima'],band_sign_tests=band['sign_tests'],tolerances={'canonical_verify':'Exact printed scientific values; exclude timing and order of worker records.','new_reproduction':'Same candidate bits; width and each group within 1%, because SVD refits may change the represented field.'})
  write(ref/'results.json',reference);write(ref/'groups.json',groups);write(ref/'disks.json',disks);write(ref/'trace-constants.json',assembly['certificates']);write(ref/'band.json',band);write(ref/'timing.json',json.loads((run/'end-to-end.json').read_text()));write(ref/'stage-times.json',final['stages'])
  # The target data are compact numerical examples, not runtime inputs.
  for name in ['audit.json','result.json','summary.json']:
    f=run/'04-residual-audit'/name
    if f.exists():shutil.copyfile(f,ref/'residual-audit.json')
  arrays=[]
  def walk(o,path,file):
    if isinstance(o,dict):
      if {'shape','real','imag'}<=o.keys():arrays.append(dict(file=file,key=path,shape=o['shape'],encoding='column-major IEEE-754 binary64 big-endian hexadecimal words',equation='see data/README.md'))
      else:
        for k,v in o.items():walk(v,path+'.'+k,file)
    elif isinstance(o,list):
      for j,v in enumerate(o):walk(v,path+f'[{j}]',file)
  for name,obj in [('fixed-input.json',field),('coefficients.json',fit),('disks-input.json',field['disks'])]:walk(obj,'$',name)
  write(data/'manifest.json',dict(schema='BIE_EX1_CANONICAL_V1',source='package cold reproduction',files=['fixed-input.json','coefficients.json','model.json','disks-input.json','band-inputs.json'],arrays=arrays))
  with (ref/'group-budget.csv').open('w') as f:
    w=csv.writer(f);w.writerow(['group','C_upper','epsilon_upper','product_upper'])
    for name,c,e,t in zip(['center','negative','positive','walls','seams'],['2.490254','1.181583','1.233941','1.035553','1.035553'],groups['epsilon_upper'],reference['assembly']['terms_upper']):w.writerow([name,c,e,t])
  print('Promoted data from',run)
if __name__=='__main__':main()
