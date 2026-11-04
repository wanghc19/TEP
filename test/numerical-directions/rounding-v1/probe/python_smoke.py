"""Python ball arithmetic and MATLAB-v7 exact-double interchange smoke check.
Input: tiny MAT path and JSON result path. Output: tool versions and bit checks.
"""
import sys,json,math,time
import numpy as np,scipy,flint
from scipy.io import loadmat
from flint import arb,acb,arb_mat,fmpq,ctx
ctx.prec=128;d=loadmat(sys.argv[1]);checks={}
checks['real_bits']=bool(np.array_equal(d['real_data'].ravel(order='F').view(np.uint64),d['real_bits'].ravel(order='F')))
checks['complex_real_bits']=bool(np.array_equal(np.ascontiguousarray(d['complex_data'].real.ravel(order='F')).view(np.uint64),d['complex_real_bits'].ravel(order='F')))
checks['complex_imag_bits']=bool(np.array_equal(np.ascontiguousarray(d['complex_data'].imag.ravel(order='F')).view(np.uint64),d['complex_imag_bits'].ravel(order='F')))
n,p=math.pi.as_integer_ratio();checks['float_to_arb_exact']=bool(arb(math.pi)==arb(fmpq(n,p)) and arb(math.pi).is_exact())
checks['transcendental_enclosure']=bool(arb(1).sin().contains(arb(1).sin()))
t=time.perf_counter();A=arb_mat(20,20,[arb((i%13)-6)/7 for i in range(400)]);B=A*A;seconds=time.perf_counter()-t
r={'versions':{'python_flint':flint.__version__,'numpy':np.__version__,'scipy':scipy.__version__},'checks':checks,'precision_bits':ctx.prec,'matrix_20_product_seconds':seconds,'arb_methods':[x for x in dir(arb_mat) if any(y in x for y in ['chol','ldl','eig','solve','inv'])]}
open(sys.argv[2],'w').write(json.dumps(r,indent=2)+'\n');print(json.dumps(r,indent=2));assert all(checks.values())
