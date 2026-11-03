"""Compute isolation-certificate tail constants from proof equations 3.13-3.15.
Input: output JSON path. Output: finite tail table, with no spectral solver.
"""
import json,math,sys
rows=[]
for endpoint in [1.7424,5.6169]:
 d=min(endpoint-1.318**2,2.375**2-endpoint)
 for M in [6,8,10,12]:
  data=[]
  for k in range(-M,M+1):
   beta=.5+2*math.pi*k;q=math.sqrt(1+beta*beta);kap=q if k==0 else math.sqrt(beta*beta-endpoint);nk=math.sqrt(q)/(2*kap**1.5)
   data.append(dict(k=k,beta=beta,q=q,kappa=kap,n=nk,D0=q/(2*kap)))
  b=max(z['n']*math.exp(-z['kappa']/4) for z in data);n0=data[M]['n']
  beta=.5-2*math.pi*(M+1);q=math.sqrt(1+beta*beta);kap=math.sqrt(beta*beta-endpoint);nk=math.sqrt(q)/(2*kap**1.5)
  am=nk*math.exp(-kap/4);vc=16*endpoint;vw=vc/math.sqrt(17);cp=vw*b+(endpoint+1)*n0
  h=(vc+vw*vw/d)*am*am;x=am*(vc*b+cp*vw/d);t=.5-h
  rows.append(dict(lambda_value=endpoint,d_per=d,M=M,a_M=am,b_out=b,c_P=cp,h_M=h,x_M=x,t_M=t,penalty=x*x/t,modes=data))
result=dict(table=rows,geometry=[dict(material=a,radius_max=.2*(1+a)/math.sqrt(1+a*a/2),collar_min=.5-.2*(1+a)/math.sqrt(1+a*a/2)) for a in [.12,.20]])
open(sys.argv[1],'w').write(json.dumps(result,indent=2)+'\n')
for r in rows:print(r['lambda_value'],r['M'],'%.12g'%r['penalty'])
