"""Construct an exact Raviart-Thomas order-three moment dual basis.
Input: integer monomials and exact reference moments. Output: MATLAB integer basis and JSON checks.
"""
from fractions import Fraction as F
from math import factorial
from pathlib import Path
import json
here=Path(__file__).resolve().parent
mono=[(d-j,j) for d in range(4) for j in range(d+1)]
raw=[]
for side in range(2):
 for ij in mono:raw.append(({ij:F(1)} if side==0 else {},{ij:F(1)} if side==1 else {}))
for j in range(4):raw.append(({(4-j,j):F(1)},{(3-j,j+1):F(1)}))
leg=[[1],[-1,2],[1,-6,6],[-1,12,-30,20]]
def trace(p,e):
 out=[F(0)]*5
 for component,sgn in ([(1,-1)] if e==0 else [(0,1),(1,1)] if e==1 else [(0,-1)]):
  for (i,j),v in p[component].items():
   if e==0:
    if j==0:out[i]+=sgn*v
   elif e==2:
    if i==0:
     from math import comb
     for n in range(j+1):out[n]+=sgn*v*comb(j,n)*(-1)**n
   else:
    from math import comb
    for n in range(i+1):out[n+j]+=sgn*v*comb(i,n)*(-1)**n
 return out
D=[]
for e in range(3):
 for L in leg:D.append([sum(t*F(l,i+j+1) for i,t in enumerate(trace(p,e)) for j,l in enumerate(L)) for p in raw])
for side in range(2):
 for ij in [(d-j,j) for d in range(3) for j in range(d+1)]:
  D.append([sum(v*F(factorial(i+ij[0])*factorial(j+ij[1]),factorial(i+j+sum(ij)+2)) for (i,j),v in p[side].items()) for p in raw])
A=[r[:]+[F(int(i==j)) for j in range(24)] for i,r in enumerate(D)]
for j in range(24):
 i=next(i for i in range(j,24) if A[i][j]);A[j],A[i]=A[i],A[j];scale=A[j][j];A[j]=[v/scale for v in A[j]]
 for i in range(24):
  if i!=j:
   scale=A[i][j]
   if scale:A[i]=[a-scale*b for a,b in zip(A[i],A[j])]
B=[r[24:] for r in A]
# Keep the integer interior dual columns and replace rational edge duals
# by the exact polynomial lifts (3.16), which preserve edge moments.
def mul(a,b):
 out={}
 for (i,j),u in a.items():
  for (k,l),v in b.items():out[i+k,j+l]=out.get((i+k,j+l),F(0))+u*v
 return {ij:v for ij,v in out.items() if v}
for e in range(3):
 a=[(0,1),(0,0),(1,0)][e]
 c=[{(1,0):F(1)},{(0,1):F(1)},{(0,0):F(1),(1,0):F(-1),(0,1):F(-1)}][e]
 for m,L in enumerate(leg):
  poly={};power={(0,0):F(1)}
  for coef in L:
   for ij,v in power.items():poly[ij]=poly.get(ij,F(0))+coef*v*(2*m+1)
   power=mul(power,c)
  px=mul(poly,{(1,0):F(1),(0,0):F(-a[0])})
  py=mul(poly,{(0,1):F(1),(0,0):F(-a[1])})
  h=[px.get((4-j,j),F(0)) for j in range(4)]
  for j,v in enumerate(h):
   px[4-j,j]=px.get((4-j,j),F(0))-v
   py[3-j,j+1]=py.get((3-j,j+1),F(0))-v
  col=[px.get(ij,F(0)) for ij in mono]+[py.get(ij,F(0)) for ij in mono]+h
  for i,v in enumerate(col):B[i][4*e+m]=v
assert all(v.denominator==1 for r in B for v in r)
for col in range(24):
 for e in range(3):
  actual=[sum(B[k][col]*trace(raw[k],e)[i] for k in range(24)) for i in range(5)]
  expect=[F(0)]*5
  if col//4==e and col<12:
   for i,v in enumerate(leg[col%4]):expect[i]=F((2*(col%4)+1)*v)
  assert actual==expect,(col,e,actual,expect)
assert all(sum(D[i][k]*B[k][j] for k in range(24))==int(i==j) for i in range(12) for j in range(24))
assert all(sum(D[i][k]*B[k][j] for k in range(24))==int(i==j) for i in range(12,24) for j in range(12,24))
s='function B=exact_rt3_basis()\n  % Exact RT3 (Raviart-Thomas order three) moment dual in raw monomials.\n  % Input\n  %   None. Integer coefficients are verified by exact_basis.py.\n  % Output\n  %   B: 24 by 24 integer raw-basis coefficients.\n  B=[ ...\n'
s+='; ...\n'.join('    '+' '.join(str(int(v)) for v in r) for r in B)+'\n  ];\nend\n'
(here/'exact_rt3_basis.m').write_text(s)
(here/'exact-basis-check.json').write_text(json.dumps({'dimension':24,'integer_coefficients':True,'maximum_coefficient':max(abs(int(v)) for r in B for v in r),'trace_polynomial_checks':24*3,'duality_entries_checked':12*24+12*12,'pass':True},indent=2))
print((here/'exact-basis-check.json').read_text())
