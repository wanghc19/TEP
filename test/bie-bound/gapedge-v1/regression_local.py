# Stage C source: test/bie-bound/example2-v1/regression_local.py; local changes documented in README.
"""Local reference regression plus complete two-configuration assembly.
Input: explicit field, fit, panel reference, group, disk and assembly files.
Output: repaired panel check and reproduced enclosure; no hidden data paths.
"""
import argparse,gzip,json,runpy,sys,time
from pathlib import Path
p=argparse.ArgumentParser()
for k in ['input','coefficients','output','panel-reference','groups','disks','assembly-reference']:p.add_argument('--'+k,required=True)
a=p.parse_args();start=time.perf_counter();here=Path(__file__).resolve().parent;out=Path(a.output)
def read(x):
  p=Path(x);obj=json.loads(gzip.decompress(p.read_bytes()) if p.suffix=='.gz' else p.read_text())
  if 'archive' in obj:return read(p.parent/obj['archive'])
  return obj
sys.argv=[str(here/'diagnose_panel.py'),'--input',a.input,'--coefficients',a.coefficients,'--output',str(out),'--side','2','--panel','14']
runpy.run_path(str(here/'diagnose_panel.py'),run_name='__main__')
new=read(out/'diagnosis.json');old=read(a.panel_reference)
diff=abs(new['result']['finite_upper']/old['finite_upper']-1)
assert diff<=1e-6
sys.path.insert(0,str(here/'enclosure'));import assemble
D=read(a.input);G=read(a.groups);G['epsilon_upper']=list(map(str,G['epsilon_upper']));M=read(a.disks);B=read(a.assembly_reference)
certs=[];assemblies=[]
for bits,n in [(192,256),(160,512)]:
 c=assemble.certify(D,bits,n);certs.append(c);assemblies.append(assemble.assembly(D,G,M,bits,c))
keys=['Q_upper','R_upper','mu_interval','k_interval','width_upper','T15_margins_lower']
checks={k:assemblies[0][k]==assemblies[1][k]==B['assemblies'][0][k] for k in keys}
r=dict(panel_relative_difference=diff,panel_old=old['finite_upper'],panel_new=new['result']['finite_upper'],q_max=new['q_max'],q_count=new['q_count'],assembly_checks=checks,certificates=certs,assemblies=assemblies,seconds=time.perf_counter()-start)
(out/'regression.json').write_text(json.dumps(r,indent=2));assert all(checks.values());print('LOCAL REGRESSION PASS',diff,flush=True)
