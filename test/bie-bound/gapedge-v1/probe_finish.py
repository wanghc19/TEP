"""Check repaired export/loading and the downstream chain on explicit own-run data.
Input: a completed residual run, explicit tools/package paths and new output.
Output: lossless-export comparison, mass, trace constants, assembly and band checks.
This continuation is not counted as a cold-start benchmark.
"""
import argparse,gzip,json,os,sys,time,struct
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from monitor import run
from run_pipeline import matlab_quote,archive_completed
p=argparse.ArgumentParser()
for n in ['input-run','output','package-root','fmm-root','matlab','conda']:p.add_argument('--'+n,required=True)
a=p.parse_args();root=Path(a.input_run);out=Path(a.output);here=Path(__file__).resolve().parent;t=time.perf_counter()
def read(p):
 p=Path(p);r=json.loads(gzip.decompress(p.read_bytes()) if p.suffix=='.gz' else p.read_text());return read(p.parent/r['archive']) if 'archive' in r else r
def stage(name,cmd):
 dest=out/name;dest.mkdir();rec=run(dest,cmd,soft=1800-(time.perf_counter()-t),hard=2400-(time.perf_counter()-t));assert rec['returncode']==0 and rec['reason']=='completed';return dest
D=read(root/'02-field/fixed-input.json.gz');k=struct.unpack('>d',bytes.fromhex(D['k']['real'][0]))[0];width=D['example']['L0'];f=out/'field'
expr=';'.join('addpath('+matlab_quote(x)+')' for x in [a.package_root,a.fmm_root,here,here/'field'])+";field_export("+matlab_quote(f)+','+repr(k)+",'reference',example_parameters('empty-rotated',"+repr(width)+'));'
os.environ.update(OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',VECLIB_MAXIMUM_THREADS='11')
stage('field',[a.matlab,'-batch',expr]);checks={}
for name in ['fixed-input','coefficients']:
 checks[name]=gzip.decompress((f/(name+'.json.gz')).read_bytes())==gzip.decompress((root/'02-field'/(name+'.json.gz')).read_bytes())
assert all(checks.values());(out/'export-check.json').write_text(json.dumps(checks))
# Retain byte-identical data once, with an explicit relative same-experiment link.
for name in ['fixed-input','coefficients']:
 dest=f/(name+'.json.gz');dest.unlink();dest.symlink_to(os.path.relpath(root/'02-field'/dest.name,f))
(out/'groups.json').write_text(json.dumps(read(root/'03-residuals/groups.json')))
os.environ.update(OMP_NUM_THREADS='1',VECLIB_MAXIMUM_THREADS='1',OPENBLAS_NUM_THREADS='1')
def arb(name,folder,script,args):return stage(name,[a.conda,'run','--no-capture-output','-n','octave','python','-I',str(here/folder/script),'--output',str(out/name)]+list(map(str,args)))
m=arb('mass','mass','disks.py',['--input',f/'fixed-input.json.gz','--order',30])
e=arb('enclosure','enclosure','assemble.py',['--input',f/'fixed-input.json.gz','--groups',out/'groups.json','--disks',m/'disks.json'])
b=arb('band','band','band_certificate.py',['--input',f/'fixed-input.json.gz','--enclosure',e/'result.json','--mode','full'])
(out/'result.json').write_text(json.dumps(dict(passed=True,export_checks=checks,assembly=read(e/'result.json')['assemblies'][0],band_minima=read(b/'result.json')['minima'],seconds=time.perf_counter()-t),indent=2))
for path in out.rglob('*.json'):
 if path.stat().st_size>50000:archive_completed(path)
