"""Check full-precision handoffs and measure scalar/diagonal roundings.
Input: stored JSON and local MATLAB export. Output: small handoff diagnostics.
"""
from pathlib import Path
import json
import numpy as np
from scipy.io import loadmat
from flint import arb,fmpq,ctx
ctx.prec=192;here=Path(__file__).resolve().parent;root=here.parents[2];read=lambda p:json.loads(Path(p).read_text());result={}
d=read(here/'output/run-007/science/result.json');m=loadmat(here/'output/run-007/science/core.mat',variable_names=['epsilon']);result['D_epsilon_MAT_JSON_bits_equal']=bool(np.float64(d['epsilon']).tobytes()==np.float64(m['epsilon'][0,0]).tobytes())
for side,run in [('left','run-006'),('right','run-008')]:
  c=read(root/f'test/numerical-directions/h-dtn-v1/{side}-certificate.json');r=read(root/f'test/numerical-directions/h-dtn-v1/output/{run}/science/result.json');z={}
  for key,parent,rad,sign in [('Q_minus','Q','eps_Q',-1),('R_plus','R','eps_R',1),('Z_plus','Z','eps_Z',1)]:
    e=[]
    for i in range(33):e.append(float((arb(c[key]['real'][i][i])-arb(c[parent]['real'][i][i])-sign*arb(c[rad])).mid()))
    z[key]={'maximum_diagonal_operation_error':max(abs(v) for v in e),'minimum_signed_difference':min(e),'maximum_signed_difference':max(e)}
  z['Q_entries_bit_equal']=bool(np.array_equal(np.array(c['Q']['real']),np.array(r['Q_real'])) and np.array_equal(np.array(c['Q']['imag']),np.array(r['Q_imag'])));z['Lambda_entries_bit_equal']=bool(np.array_equal(np.array(c['hat_Lambda']['real']),np.array(r['lower_real'])) and np.array_equal(np.array(c['hat_Lambda']['imag']),np.array(r['lower_imag'])));z['r_scalar_bit_equal']=bool(np.float64(c['r']).tobytes()==np.float64(r['r']).tobytes());result[side]=z
vals=loadmat(here/'output/run-007/science/scalars.mat',variable_names=['alpha'])['alpha'].ravel();result['alpha_errors']=[float((arb(float(v))-arb(fmpq(1089,625) if i%2==0 else fmpq(56169,10000))).mid()) for i,v in enumerate(vals)]
(here/'output/handoff-checks.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
