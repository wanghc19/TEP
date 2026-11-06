# Stage C source: test/bie-bound/example2-v1/residual/column_models.py; local adaptations only.
# B2 source: test/bie-bound/pipeline-v1/residual/column_models.py; generalized model plumbing.
# Copied from test/bie-bound/grouprel-v1/column_models.py; pipeline adaptations documented in README.
"""Actual-state matrix interpolation with separate column error ledgers.
Input: node matrices, analytic errors and envelopes per column.
Output: deterministic coefficients and one norm error for each column.
"""
from flint import arb,acb_mat,ctx
from expansion import norm
from map_models import interpolate
from material import up
from envelope_gate import FiniteGate

def column_norm(A,j):return norm([A[i,j] for i in range(A.nrows())])
def models(nodes,anal,envelope):
  if not all(x.is_finite() for x in anal+envelope):raise FiniteGate('Nonfinite analytic node or envelope input')
  if not all(v[i,j].is_finite() for v in nodes for i in range(v.nrows()) for j in range(v.ncols())):raise FiniteGate('Nonfinite interpolation node')
  nc=nodes[0].ncols();nr=nodes[0].nrows();finite=[arb(0)]*nc;mids=[]
  for v in nodes:
    mid=acb_mat(nr,nc,[v[i,j].mid() for i in range(nr) for j in range(nc)])
    for j in range(nc):finite[j]=max(finite[j],column_norm(v-mid,j))
    mids.append(mid)
  ctx.prec=192;cf,conv=interpolate(mids);L=len(nodes);rho=arb('4.5');tail=[4*x*rho**(1-L)/(rho-1) for x in envelope]
  # A common conversion bound dominates every column, and is tiny here.
  e=[tail[j]+(2*arb(L)-1).sqrt()*(anal[j]+finite[j])+conv for j in range(nc)]
  return cf,e,dict(analytic_node_errors=list(map(up,anal)),finite_node_radii=list(map(up,finite)),interpolation_tails=list(map(up,tail)),conversion_common=up(conv))

def combine(parts):
  D=max(len(cf) for cf in parts);nr=parts[0][0].nrows();nc=parts[0][0].ncols();errors=[arb(0)]*nc;out=[]
  for l in range(D):
    v=acb_mat(nr,nc)
    for cf in parts:
      if l<len(cf):v+=cf[l]
    mid=acb_mat(nr,nc,[v[i,j].mid() for i in range(nr) for j in range(nc)])
    for j in range(nc):errors[j]+=column_norm(v-mid,j)
    out.append(mid)
  return out,errors
