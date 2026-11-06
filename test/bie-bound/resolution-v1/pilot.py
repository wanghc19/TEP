"""Check the parameterized default residual path against the same experiment.
Input: reference run, explicit output/Conda paths. Output: monitored pilot/checks.
"""
import argparse,json,os,sys
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE/'varied'))
from run_pipeline import preflight,empty
from monitor import run
p=argparse.ArgumentParser();p.add_argument('--reference',required=True);p.add_argument('--output',required=True);p.add_argument('--conda',required=True);a=p.parse_args();ref=Path(a.reference).resolve();out=Path(a.output).resolve();empty(out);out.mkdir(parents=True);pre=preflight();(out/'preflight.json').write_text(json.dumps(pre,indent=2));assert not pre['heavy_jobs']
os.environ.update(OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1',VECLIB_MAXIMUM_THREADS='1',OMP_DYNAMIC='FALSE',PYTHONDONTWRITEBYTECODE='1')
cmd=[a.conda,'run','--no-capture-output','-n','octave','python','-I',str(HERE/'varied/audit_entry.py'),'--run-root',str(out),'--allowed-field',str(ref),'--entry',str(HERE/'varied/residual/groups.py'),'--','--input',str(ref/'02-field/fixed-input.json'),'--coefficients',str(ref/'02-field/coefficients.json'),'--output',str(out),'--pilot','--workers','8']
r=run(out,cmd);assert r['returncode']==0 and r['reason']=='completed'
s=json.loads((out/'summary.json').read_text());assert s['passed'];checks=[]
for row in s['tasks']:
 old=json.loads((ref/'03-residuals'/f"target-{row['kind']}-{row['side']}-{row['index']}.json").read_text())
 if row['kind']=='center':
  n=[l['epsilon_panel_upper'] for l in row['center']['leaves']];o=[l['epsilon_panel_upper'] for l in old['center']['leaves']]
 else:n=row['upper_squared'];o=old['upper_squared']
 diff=max(abs(x/y-1) for x,y in zip(n,o) if y);checks.append(dict(kind=row['kind'],side=row['side'],index=row['index'],max_relative=diff,exact=n==o));assert diff<1e-12
(out/'check.json').write_text(json.dumps(dict(passed=True,checks=checks,reference=str(ref),monitor=r),indent=2));print('PARAMETERIZED DEFAULT PASS',max(x['max_relative'] for x in checks))
