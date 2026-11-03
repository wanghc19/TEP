"""Verify integer Raviart-Thomas order-three normal traces.
Input: experiment directory. Output: exact-trace JSON; integer arithmetic only.
"""
import re,math,json,sys
from pathlib import Path
root=Path(sys.argv[1]);s=(root/'exact_rt3_basis.m').read_text().split('B=[ ...',1)[1].split('];',1)[0]
B=[[int(x) for x in re.findall(r'-?\d+',row)] for row in s.split(';') if re.search(r'\d',row)]
assert len(B)==24 and all(len(x)==24 for x in B)
mon=[(d-j,j) for d in range(4) for j in range(d+1)]
vx=[{z:1} for z in mon]+[{} for z in mon]+[{(4-j,j):1} for j in range(4)]
vy=[{} for z in mon]+[{z:1} for z in mon]+[{(3-j,j+1):1} for j in range(4)]
def mul(a,b):
 c=[0]*(len(a)+len(b)-1)
 for i,x in enumerate(a):
  for j,y in enumerate(b):c[i+j]+=x*y
 return c
def power(a,n):
 c=[1]
 for _ in range(n):c=mul(c,a)
 return c
def subst(poly,x,y):
 c=[0]*5
 for (a,b),v in poly.items():
  p=mul(power(x,a),power(y,b))
  for j,z in enumerate(p):c[j]+=v*z
 return c
legs=[[1],[-1,2],[1,-6,6],[-1,12,-30,20]];checks=0
for edge,(x,y,nx,ny) in enumerate([([0,1],[0],0,-1),([1,-1],[0,1],1,1),([0],[1,-1],-1,0)]):
 raw=[[nx*a+ny*b for a,b in zip(subst(vx[j],x,y),subst(vy[j],x,y))] for j in range(24)]
 for col in range(24):
  trace=[sum(raw[j][d]*B[j][col] for j in range(24)) for d in range(5)]
  target=[0]*5
  if col//4==edge and col<12:
   m=col%4
   for d,v in enumerate(legs[m]):target[d]=(2*m+1)*v
  assert trace==target,(edge,col,trace,target)
  checks+=1
out={'passes':checks,'integer_trace_check':True,'interior_columns_zero_on_every_edge':True}
(root/'exact-trace-check.json').write_text(json.dumps(out,indent=2)+'\n');print(out)
