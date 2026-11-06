# Stage C source: test/bie-bound/example2-v1/residual/group_norms.py; local adaptations only.
# B2 source: test/bie-bound/pipeline-v1/residual/group_norms.py; generalized model plumbing.
# Copied from test/bie-bound/grouprel-v1/group_norms.py; pipeline adaptations documented in README.
"""Columnwise polynomial integrals with upper/lower residual norms.
Input: deterministic coefficient matrices, column error balls, half-length.
Output: per-column CK18 finite bounds and optional independent Gauss check.
"""
from flint import arb,acb_mat,ctx
from material import up
from envelope_gate import FiniteGate
from map_models import integral,gauss_integral

def columns(cf,errors,h,check=False):
  if not all(c[i,j].is_finite() for c in cf for i in range(c.nrows()) for j in range(c.ncols())):raise FiniteGate('Nonfinite polynomial coefficient')
  ctx.prec=192;D=len(cf);nc=cf[0].ncols();nr=cf[0].nrows();v=[]
  # Flatten each column separately; the Gram form is exact for the polynomial.
  for j in range(nc):
    C=acb_mat(nr,D,[cf[l][r,j] for r in range(nr) for l in range(D)]);G=C.conjugate().transpose()*C
    q=2*h*sum((G[a,b].real/(a+b+1) for a in range(D) for b in range(a%2,D,2)),arb(0));
    if not q.is_finite():raise FiniteGate('Nonfinite polynomial integral')
    v.append(q)
  er=[(2*h).sqrt()*e for e in errors]
  upper=[(max(arb(0),x.upper()).sqrt()+e)**2 for x,e in zip(v,er)]
  lower=[max(arb(0),max(arb(0),x.lower()).sqrt()-e)**2 for x,e in zip(v,er)]
  rec=dict(V_columns=list(map(str,v)),error_columns=list(map(up,errors)),upper_squared=list(map(up,upper)),lower_squared=[str(x.lower()) for x in lower],V=str(sum(v,arb(0))),e_I=up(sum((e*e for e in errors),arb(0)).sqrt()))
  if check:
    vg=gauss_integral(cf,h);vv=sum(v,arb(0));rel=abs(vg-vv)/vv.lower();assert rel<arb('1e-12');rec.update(V_gauss=str(vg),gauss_relative=up(rel))
  return rec
