"""Independent NumPy colleague-root checks for determinant interpolation outputs.
Input: explicit current-run directories. Output: root-audit.json in each run.
"""
import argparse,json
from pathlib import Path
import numpy as np
from numpy.polynomial.chebyshev import chebroots
p=argparse.ArgumentParser();p.add_argument('runs',nargs='+');a=p.parse_args()
for path in a.runs:
  run=Path(path);r=json.loads((run/'result.json').read_text());audit=[]
  for panel in r['panels']:
    lev=panel['levels'][-1];c=np.array(lev['coeff_real'])+1j*np.array(lev['coeff_imag']);z=chebroots(c)
    rho=np.maximum(abs(z+np.sqrt(z*z-1)),abs(z-np.sqrt(z*z-1)));z=z[rho<1.1];rho=rho[rho<1.1]
    roots=np.mean(panel['bounds'])+np.diff(panel['bounds'])[0]/2*z
    trimmed=np.array(lev['roots']).reshape(-1,2);tr=trimmed[:,0]+1j*trimmed[:,1]
    distances=[float(min(abs(x-tr))) for x in roots]
    audit.append(dict(panel=panel['label'],degree=lev['degree'],untrimmed_roots=[[float(x.real),float(x.imag)] for x in roots],rho=rho.tolist(),distance_to_trimmed=distances))
  (run/'root-audit.json').write_text(json.dumps(audit,indent=2));print(path,audit)
