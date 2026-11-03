"""Compute high Fourier lift constants for the Dirichlet-to-Neumann certificate.
Input: output JSON path. Output: M=8,...,20 and comparison with proof section 4.7.
"""
import json,math,sys
lam=5.6169;lo=1.7424;kp=1+(lam+1)/(2.375**2-lam);km=(lam+1)/(lam-lo)-1
rows=[]
reference={8:3.96025e-4,10:1.57112e-5,12:6.38711e-7,14:2.63645e-8,16:1.09938e-9,20:1.94910e-12}
for M in range(8,21):
  beta=2*math.pi*(M+1)-.5;k=math.sqrt(beta*beta-lam)
  a=math.sqrt((beta*beta-lam)/(beta*beta+1));b=.5*(6/(.125**2*k)+3/.125)**2*math.exp(-2*.125*k)
  rows.append(dict(M=M,a_H=a,b_H_squared=b,A_H=a-kp*b,reference=reference.get(M),relative_difference=abs(b/reference[M]-1) if M in reference else None))
x=dict(lambda_value=lam,alpha_minus=lo,K_plus=kp,K_minus=km,d_plus=2.375**2-lam,d_minus=lam-lo,table=rows)
open(sys.argv[1],'w').write(json.dumps(x,indent=2)+'\n')
print('K+',kp,'K-',km)
for r in rows:print(r['M'],r['a_H'],r['b_H_squared'])
