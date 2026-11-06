"""Forecast the near-edge full run using explicit fresh field and target pilots.
Input: candidate k, center width, tool paths and output; no old field input.
Output: field, seven right-lead targets, per-process RSS and band-window pilot.
"""
import argparse,json,os,sys,time
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from monitor import run
from run_pipeline import matlab_quote
p=argparse.ArgumentParser()
for n in ['output','package-root','fmm-root','matlab','conda']:p.add_argument('--'+n,required=True)
p.add_argument('--k',type=float,required=True);p.add_argument('--center-width',type=float,required=True);a=p.parse_args();out=Path(a.output);here=Path(__file__).resolve().parent;t=time.perf_counter();rows=[]
def stage(name,cmd):
 dest=out/name;dest.mkdir();(out/'part.txt').write_text(name);r=run(dest,cmd,soft=max(1,1800-(time.perf_counter()-t)),hard=max(1,2400-(time.perf_counter()-t)));rows.append(dict(name=name,monitor=r));(out/'stages.json').write_text(json.dumps(rows,indent=2));assert r['returncode']==0 and r['reason']=='completed';return dest
f=out/'field';expr=';'.join('addpath('+matlab_quote(x)+')' for x in [a.package_root,a.fmm_root,here,here/'field'])+";field_export("+matlab_quote(f)+','+repr(a.k)+",'reference',example_parameters('empty-rotated',"+repr(a.center_width)+'));'
os.environ.update(OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',VECLIB_MAXIMUM_THREADS='11');stage('field',[a.matlab,'-batch',expr]);fixed=f/'fixed-input.json.gz';fits=f/'coefficients.json.gz'
os.environ.update(OMP_NUM_THREADS='1',VECLIB_MAXIMUM_THREADS='1',OPENBLAS_NUM_THREADS='1')
def arb(name,folder,script,args):return stage(name,[a.conda,'run','--no-capture-output','-n','octave','python','-I',str(here/'audit_entry.py'),'--run-root',str(out),'--entry',str(here/folder/script),'--','--output',str(out/name)]+list(map(str,args)))
arb('conditions','','conditions.py',['--input',fixed,'--coefficients',fits])
arb('targets','residual','groups.py',['--input',fixed,'--coefficients',fits,'--workers',3,'--states-left',80,'--states-right',230,'--resource-pilot','--tail-ratio','0.1'])
arb('band','band','band_certificate.py',['--input',fixed,'--mode','pilot','--k-lower','1.45','--k-upper','2.37'])
(out/'result.json').write_text(json.dumps(dict(status='PASS',purpose='resource and analytic-domain pilot, not a whole-guide enclosure',k=a.k,L0=a.center_width,seconds=time.perf_counter()-t,stages=rows),indent=2))
