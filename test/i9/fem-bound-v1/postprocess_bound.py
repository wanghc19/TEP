"""Read-only scalar and local material checks for one completed I9.4 output.

Uses saved current-run arrays; never solves FEM, constructs flux or reintegrates
its residual. Requires an already available NumPy installation, no installation.
All generated output is saved alongside the input run, below output/.
"""
import json
from pathlib import Path
import sys
import time
import numpy as np

start = time.perf_counter()
p = Path(sys.argv[1])
s = json.loads((p / 'result.json').read_text())
meta = json.loads((p / 'arrays.json').read_text())

def read(name):
  a = np.fromfile(p / (name + '_real.bin'), dtype='<f8').reshape(meta[name], order='F')
  return a

v = s['values']
u = read('unknown_check')
a = read('element_check')
checks = {}
checks['scalar_mass_abs'] = abs(a[:, 0].sum() - v['mass_squared'])
checks['scalar_gradient_abs'] = abs(a[:, 1].sum() - v['gradient_difference_squared'])
checks['scalar_body_abs'] = abs(a[:, 2].sum() - v['body_defect_weighted_squared'])
mu = v['mu_h']
C = v['C_end']
end = C * sum(v['end_norms'])
M = np.sqrt(v['M_squared'])
eta = M + end
tau = eta / np.sqrt(v['mass_squared'])
R = tau / 2 * (tau + np.sqrt(tau*tau + 8*mu))
checks['R_recomposition_abs'] = abs(R-v['R'])
mwidth = (u[:, 2] - u[:, 0]).sum()
bwidth = (u[:, 3] - u[:, 1]).sum()
# Each actual unknown-node material is one member of the full discrete set.
# The widths therefore bound its deviation from either quadrature envelope.
# This is still a quadrature diagnostic, not an exact integral enclosure.
mrange = [max(0, v['mass_squared']-mwidth), v['mass_squared']+mwidth]
brange = [max(0, v['body_defect_weighted_squared']-bwidth), v['body_defect_weighted_squared']+bwidth]
def radius(m,b):
  e = np.sqrt(v['gradient_difference_squared']+b/mu) + end
  t = e/np.sqrt(m)
  return t/2*(t+np.sqrt(t*t+8*mu))
rrange = [radius(mrange[1],brange[0]),radius(mrange[0],brange[1])]
mx = read('mapx'); my = read('mapy'); leaves = read('leaves')
ref = np.array([[0,0],[1,0],[0,1],[.5,0],[.5,.5],[0,.5]])
b = np.column_stack([np.ones(6),ref[:,0],ref[:,1],ref[:,0]**2,ref[:,0]*ref[:,1],ref[:,1]**2])
x = mx @ b.T; y = my @ b.T
bx = np.column_stack([x[:,:3], 2*x[:,3]-(x[:,0]+x[:,1])/2, 2*x[:,4]-(x[:,1]+x[:,2])/2, 2*x[:,5]-(x[:,2]+x[:,0])/2])
by = np.column_stack([y[:,:3], 2*y[:,3]-(y[:,0]+y[:,1])/2, 2*y[:,4]-(y[:,1]+y[:,2])/2, 2*y[:,5]-(y[:,2]+y[:,0])/2])
# Cell identity follows preserved x-cell subdivision; no historical JSON needed.
cells = np.floor(x[:,:3].mean(axis=1)+.5).astype(int)
checks['own_cell_bernstein_x_violation'] = float(max(0,np.max(cells-.5-bx.min(axis=1)),np.max(bx.max(axis=1)-cells-.5)))
checks['strip_bernstein_y_violation'] = float(max(0,np.max(-.5-by.min(axis=1)),np.max(by.max(axis=1)-.5)))
# The widest center curve box is .36 in x; all lead radii are below .24.
checks['curve_tube_cell_clearance'] = .5-.36-max(s['classification']['curve_tube_radii'])

sel = cells[leaves[:,0].astype(int)-1] == 0
L = leaves[sel]
tidx = L[:,0].astype(int)-1
z,w = np.polynomial.legendre.leggauss(10);z=(z+1)/2
max_cross=0.; min_dot=1.; count=0; min_cross_derivative=1.
def star(t):
  return (.3*np.cos(t)+.03*np.cos(6*t)+.03*np.cos(4*t),
    .2*np.sin(t)+.03*np.sin(6*t)-.03*np.sin(4*t),
    -.3*np.sin(t)-.18*np.sin(6*t)-.12*np.sin(4*t),
    .2*np.cos(t)+.18*np.cos(6*t)-.12*np.cos(4*t))
# Check every actual Q10 point on unresolved star leaves, plus the centroids
# used for classifying all resolved center leaves.
for unknown in (False,True):
  LL=L[(L[:,7]==0)==unknown]; ids=LL[:,0].astype(int)-1
  rules=[(1/3,1/3)] if not unknown else [(r,(1-r)*t) for r in z for t in z]
  for qx,qy in rules:
    xx=LL[:,1]+qx*(LL[:,3]-LL[:,1])+qy*(LL[:,5]-LL[:,1])
    yy=LL[:,2]+qx*(LL[:,4]-LL[:,2])+qy*(LL[:,6]-LL[:,2])
    bb=np.column_stack([np.ones(len(xx)),xx,yy,xx*xx,xx*yy,yy*yy])
    xp=np.sum(bb*mx[ids],axis=1);yp=np.sum(bb*my[ids],axis=1)
    t=np.arctan2(yp/.2,xp/.3)
    for it in range(12):
      cx,cy,dx,dy=star(t); f=cx*yp-cy*xp; df=dx*yp-dy*xp
      step=np.divide(f,df,out=np.zeros_like(t),where=abs(df)>1e-30)
      t-=np.clip(step,-.2,.2)
    cx,cy,dx,dy=star(t); scale=np.hypot(cx,cy)*np.hypot(xp,yp)
    nz=scale>1e-25
    max_cross=max(max_cross,float(np.max(abs(cx[nz]*yp[nz]-cy[nz]*xp[nz])/scale[nz],initial=0)))
    min_dot=min(min_dot,float(np.min((cx[nz]*xp[nz]+cy[nz]*yp[nz])/scale[nz],initial=1)))
    min_cross_derivative=min(min_cross_derivative,float(np.min(cx*dy-cy*dx,initial=1)))
    count+=len(xx)
checks['star_classification_points'] = count
checks['star_final_normalized_cross_max'] = max_cross
checks['star_final_normalized_dot_min'] = min_dot
checks['star_polar_monotonic_sample_min'] = min_cross_derivative
assert max_cross<1e-12 and min_dot>0.9999999999
assert checks['own_cell_bernstein_x_violation']<1e-13 and checks['strip_bernstein_y_violation']<1e-13
assert checks['R_recomposition_abs']<1e-12
out = dict(identity='POSTPROCESS_NUMERICAL_DIAGNOSTIC_NOT_CERTIFICATE',checks=checks,
  direct_gradient_eta_component=float(np.sqrt(v['gradient_difference_squared'])),
  direct_body_eta_component=float(np.sqrt(v['body_defect_weighted_squared']/mu)),
  bulk_eta_component=float(M),end_eta_component=float(end),
  material_mass_quadrature_range=mrange,material_body_quadrature_range=brange,
  material_R_quadrature_range=rrange,
  formal_Q10_seconds=s['timings'].get('Q10_formal_seconds',s['timings'].get('integral_diagnostic_seconds')),
  diagnostic_Q8_seconds=s['timings'].get('Q8_diagnostic_seconds',s['timings'].get('primary_integrals_seconds')),
  note='Raw timing labels precede their corrected source names; actual order is Q8 then Q10. No science rerun.',
  elapsed_seconds=time.perf_counter()-start)
(p/'postprocess.json').write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps(out,indent=2))
