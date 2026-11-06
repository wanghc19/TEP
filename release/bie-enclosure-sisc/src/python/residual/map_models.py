# Copied from test/bie-bound/pipeline-v1/residual/map_models.py; release R1 path/data interfaces may be adapted.
# Copied from test/bie-bound/grouprel-v1/map_models.py; pipeline adaptations documented in README.
"""Matrix polynomial interpolation and norm integration for full lead states.
Input: ball-valued node matrices. Output: fixed polynomial matrices and errors.
"""
from flint import arb,acb,acb_mat,acb_poly
from expansion import norm

def interpolate(nodes):
  L=len(nodes);nr=nodes[0].nrows();nc=nodes[0].ncols();angles=[arb.pi()*(2*l+1)/(2*L) for l in range(L)]
  T=acb_mat(L,L,[(1 if j==0 else 2)*(j*angles[l]).cos()/L for j in range(L) for l in range(L)])
  P=[acb_poly([1]),acb_poly([0,1])]
  for j in range(2,L):P.append(acb_poly([0,2])*P[-1]-P[-2])
  W=acb_mat(L,L,[P[j][i] for i in range(L) for j in range(L)])
  B=W*T*acb_mat(L,nr*nc,[nodes[l][i,j] for l in range(L) for i in range(nr) for j in range(nc)])
  cf=[];error=arb(0)
  for l in range(L):
    ball=acb_mat(nr,nc,[B[l,i*nc+j] for i in range(nr) for j in range(nc)]);mid=acb_mat(nr,nc,[ball[i,j].mid() for i in range(nr) for j in range(nc)]);error+=norm(ball-mid);cf.append(mid)
  return cf,error.upper()

def integral(cf,h):
  nr=cf[0].nrows();nc=cf[0].ncols();D=len(cf)
  C=acb_mat(nr*nc,D,[cf[j][r,c] for r in range(nr) for c in range(nc) for j in range(D)])
  gram=C.conjugate().transpose()*C
  return 2*h*sum((gram[i,j].real/(i+j+1) for i in range(D) for j in range(i%2,D,2)),arb(0))

def evaluate(cf,x):
  v=acb_mat(cf[0].nrows(),cf[0].ncols())
  for c in reversed(cf):v=v*x+c
  return v

def gauss_integral(cf,h):
  D=len(cf)
  return h*sum((w*norm(evaluate(cf,x))**2 for x,w in [arb.legendre_p_root(D,j,True) for j in range(D)]),arb(0))
