"""General-power propagation certificate, using ball Frobenius upper bounds.
Input: exact-input ball matrix P; optional prescribed positive block length.
Output: r >= ||P^p||_2, short-power bounds, geometric factor and P^10 bound.
The identity norm is exactly one. For other powers ||A||_2 <= ||A||_F.
"""
from flint import arb,acb_mat
from expansion import norm
from material import up

def certify(P,prescribed=0):
  powers=[acb_mat([[int(i==j) for j in range(P.nrows())] for i in range(P.nrows())])];bounds=[arb(1)]
  chosen=None
  for j in range(1,201):
    powers.append(powers[-1]*P);bounds.append(norm(powers[-1]))
    if (j==prescribed if prescribed else bounds[j]<1):
      assert bounds[j]<1,'Specified propagation block is not contracting'
      chosen=j;break
  assert chosen is not None,'No certified contracting power up to 200'
  p=chosen;r=bounds[p];factor=sum((b*b for b in bounds[:p]),arb(0))/(1-r*r)
  while len(powers)<=10:powers.append(powers[-1]*P)
  n10=norm(powers[10]);r1=bounds[1]
  rec=dict(p=p,r_upper=up(r),short_power_norm_upper=[up(x) for x in bounds[:p]],norm_P_upper=up(r1),norm_P10_upper=up(n10),geometric_factor_upper=up(factor),norm_method='Arb Frobenius bounds on powers; identity spectral norm exactly 1')
  return dict(p=p,r=r,factor=factor,norm1=r1,norm10=n10,record=rec)
