# Stage C source: test/bie-bound/example2-v1/residual/envelope_gate.py; local adaptations only.
# B2 source: test/bie-bound/pipeline-v1/residual/envelope_gate.py; generalized model plumbing.
# Copied from test/bie-bound/grouprel-v1/envelope_gate.py; pipeline adaptations documented in README.
"""Finite analytic envelope gate with covering rectangle subdivision.
Input: matrix-valued analytic evaluator, rectangle, optional branch test.
Output: column/whole norm sup bounds and covering subdivision ledger.
"""
from flint import arb,acb
class FiniteGate(ArithmeticError):
  """A nonfinite or unresolved analytic enclosure requires target fallback."""

def rectangle(evaluate,center,rx,ry,branch=None,max_depth=6):
  from expansion import norm
  counts=dict(leaves=0,splits=0,max_depth=0);bounds=None;whole=arb(0);low=None
  def box(x,y,hx,hy,depth):
    nonlocal bounds,whole,low
    z=acb(arb(x,hx.upper()),arb(y,hy.upper()));good=True;b=None
    if branch is not None:b=branch(z);good=bool(b.is_finite() and b>0)
    if good:
      v=evaluate(z);good=all(v[i,j].is_finite() for i in range(v.nrows()) for j in range(v.ncols()))
    if not good:
      if depth>=max_depth:raise FiniteGate('Nonfinite/branch envelope after covering subdivision')
      counts['splits']+=1
      if hx>=hy:
        for s in [-1,1]:box(x+s*hx/2,y,hx/2,hy,depth+1)
      else:
        for s in [-1,1]:box(x,y+s*hy/2,hx,hy/2,depth+1)
      return
    cols=[norm([v[i,j] for i in range(v.nrows())]) for j in range(v.ncols())]
    if bounds is None:bounds=cols
    else:bounds=[max(a,b) for a,b in zip(bounds,cols)]
    whole=max(whole,norm(v));counts['leaves']+=1;counts['max_depth']=max(counts['max_depth'],depth)
    if b is not None:low=b.lower() if low is None else min(low,b.lower())
  box(center,arb(0),rx,ry,0)
  if bounds is None:raise FiniteGate('Empty envelope cover')
  counts['branch_lower']=None if low is None else str(low)
  return bounds,whole,counts
