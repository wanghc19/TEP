# Stage C source: test/bie-bound/example2-v1/residual/group_setup.py; local adaptations only.
# B2 source: test/bie-bound/pipeline-v1/residual/group_setup.py; generalized model plumbing.
# Copied from test/bie-bound/grouprel-v1/group_setup.py; pipeline adaptations documented in README.
"""Shared source and actual-state setup for all residual groups.
Input: exact field and B coefficient dictionaries, maximum state count.
Output: central and two lead caches, propagation balls and tail envelopes.
"""
import time
from flint import arb,acb,acb_mat,ctx
from material import Proxy,matrix,I,up
from expansion import Sources,Expansion
from real_panels import SelfCache
from tail_bound import envelope

def prepare(data,fits,nmax):
  start=time.perf_counter();ctx.prec=128;ctx.cap=81;ctx.threads=1
  beta=matrix(data['beta'])[0,0].real;d=matrix(data['d'])[0,0].real;phase=(I*beta*d).exp();Z=matrix(fits['Z']);pars=matrix(data['curve_parameters']);charges=[(Z[1,j].real,Z[0,j].real,acb(1)) for j in range(Z.ncols())];images=[(arb(0),arb(m),phase**m) for m in [-1,1]]
  K=Proxy(data);empty=data['pieces'][0]['shape']=='none'
  if empty:
    from types import SimpleNamespace
    src=SimpleNamespace(empty=True,nc=1);near=Expansion(K,images,arb('.6'),128,src);proxy=Expansion(K,charges,arb('1.1'),144,src);cache=None
  else:
    src=Sources(K,data['pieces'][0]);near=Expansion(K,images,arb('.6'),128,src);proxy=Expansion(K,charges,arb('1.1'),144,coefficients=matrix(fits['B_center']));cache=SelfCache(data,K)
  center=dict(K=K,src=src,near=near,proxy=proxy,cache=cache,W=matrix(data['incident']),seconds=time.perf_counter()-start)
  leads=[]
  for i in [1,2]:
    count=nmax[i-1] if isinstance(nmax,(list,tuple)) else nmax
    t=time.perf_counter();K=Proxy(data);angle=arb(data.get('example',{}).get('angle_negative' if i==1 else 'angle_positive',0));K.R=(pars[0,7].real,) if angle.is_zero() else (pars[0,7].real,angle);K.L=matrix(data['cell_widths'])[0,i].real if 'cell_widths' in data else arb(1);K.b=pars[0,4+i].real;piece=data['pieces'][i];bc=matrix(fits['B_negative' if i==1 else 'B_positive']);G=matrix(piece['G']);BL,states,r,tr,con,demo=envelope(K,piece,bc,Z,beta,d,count)
    ctx.prec=192;V=acb_mat(97,count+1,[states[j][l,0] for l in range(97) for j in range(count+1)]);W=G*V;Ct=matrix(piece['tau_coeff'])*W;Cz=matrix(piece['zeta_coeff'])*W;cp=dict(piece,tau_coeff=Ct,zeta_coeff=Cz);ctx.prec=128
    src=Sources(K,cp,64,80,arb('.12'));near=Expansion(K,images,arb('.6'),72,src);proxy=Expansion(K,charges,arb('1.1'),144,coefficients=bc*V)
    leads.append(dict(nstates=count,K=K,piece=piece,bc=bc,src=src,near=near,proxy=proxy,W=W,V=V,states=states,r=r,BL=BL,tail=tr,contraction=con,power_demo=demo,seconds=time.perf_counter()-t))
  return dict(center=center,leads=leads,beta=beta,d=d,Z=Z,phase=phase,seconds=time.perf_counter()-start)
