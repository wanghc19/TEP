"""Promote a completed FEM comparison run to canonical arrays and references.
Input: explicit interval run, isolation runs, data and reference paths.
Output: NPZ/JSON arrays and compact numeric certificates; portable metadata.
"""
import argparse,json,sys,shutil
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from arrays import export,materialize,equal_mat
p=argparse.ArgumentParser();p.add_argument('--interval',type=Path,required=True);p.add_argument('--band',type=Path,required=True);p.add_argument('--surface',type=Path,required=True);p.add_argument('--dtn',type=Path,required=True);p.add_argument('--core',type=Path,required=True);p.add_argument('--data',type=Path,required=True);p.add_argument('--reference',type=Path,required=True);a=p.parse_args()
assert json.loads((a.interval/'science/summary.json').read_text())['status']=='COMPLETE'
mesh=json.loads((a.interval/'science/config.json').read_text())['example']['discretization']['native']['mesh']['subdivisions']
assert json.loads((a.core/'science/isolation.json').read_text())['H']
data=a.data;ref=a.reference
assert not data.exists() or not any(data.iterdir()),'Canonical destination must be empty'
assert not ref.exists() or not any(ref.iterdir()),'Reference destination must be empty'
data.mkdir(parents=True,exist_ok=True);ref.mkdir(parents=True,exist_ok=True)
for name in ['native','flux']:
  export(a.interval/'science'/f'{name}.mat',data/name)
  check=a.interval/'canonical-roundtrip';check.mkdir(exist_ok=True);materialize(data/name,check/f'{name}.mat')
  assert equal_mat(a.interval/'science'/f'{name}.mat',check/f'{name}.mat'),'Array roundtrip changed a numeric value'
for fn in ['integrals.json','interval.json','trial-summary.json','summary.json','regression.json','delivery-checks.json','config.json']:
  if (a.interval/'science'/fn).exists():shutil.copy2(a.interval/'science'/fn,ref/fn)
shutil.copy2(a.interval/'science/integrals.json',data/'integrals.json')
for folder,filename in [(a.band,'band.json'),(a.surface,'surface.json')]:shutil.copy2(folder/'science'/filename,data/filename)
for side in ['left','right']:
  for ep in [1,2]:
    folder=data/f'{side}-{ep}';folder.mkdir(exist_ok=True);shutil.copy2(a.surface/'science'/folder.name/'result.json',folder/'result.json')
  folder=data/side;folder.mkdir(exist_ok=True);shutil.copy2(a.dtn/'science'/side/'result.json',folder/'result.json');shutil.copy2(a.dtn/'science'/f'{side}-certificate.json',data/f'{side}-certificate.json')
shutil.copy2(a.core/'science/result.json',data/'core-result.json');shutil.copy2(a.core/'science/isolation.json',ref/'isolation.json')
for name,path in [('interval',a.interval),('band',a.band),('surface',a.surface),('dtn',a.dtn),('core',a.core)]:
  shutil.copy2(path/'monitor/monitor.json',ref/f'{name}-monitor.json')
interval=json.loads((ref/'interval.json').read_text());isolation=json.loads((ref/'isolation.json').read_text())
result={'example':'ex1','mesh_subdivisions':mesh,'I_1':interval['I_1'],'four_corner':interval['four_corner'],'isolation':isolation,'status':'Isolation follows from the band, surface, DtN and core certificates; analytic truncation errors are bounded and finite rounding is estimated only.','rounding_covered':False}
(ref/'results.json').write_text(json.dumps(result,indent=2)+'\n')
manifest={'format':'numpy-struct-v1','example':'ex1','mesh':mesh,'rounding_covered':False,'array_roundtrip_exact':True,'matlab_class_preserved':True,'data_files':[str(x.relative_to(data)) for x in data.rglob('*') if x.is_file()]}
(data/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');print('PROMOTED')
