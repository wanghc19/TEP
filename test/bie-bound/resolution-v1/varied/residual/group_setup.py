# Copied from test/bie-bound/pipeline-v1/residual/group_setup.py.
# Copied from test/bie-bound/grouprel-v1/group_setup.py; pipeline adaptations documented in README.
"""Shared source and actual-state setup for all residual groups.
Input: exact field and B coefficient dictionaries, maximum state count.
Output: central and two lead caches, propagation balls and tail envelopes.
"""
import eval_settings as cfg
import time
from flint import arb,acb,acb_mat,ctx
from material import Proxy,matrix,I,up
from expansion import Sources,Expansion
from real_panels import SelfCache
from tail_bound import envelope

def prepare(data,fits,nmax):
  start=time.perf_counter();ctx.prec=cfg.bits;ctx.cap=81;ctx.threads=1
  beta=matrix(data['beta'])[0,0].real;d=matrix(data['d'])[0,0].real;phase=(I*beta*d).exp();Z=matrix(fits['Z']);pars=matrix(data['curve_parameters']);charges=[(Z[1,j].real,Z[0,j].real,acb(1)) for j in range(Z.ncols())];images=[(arb(0),arb(m),phase**m) for m in [-1,1]]
  K=Proxy(data);src=Sources(K,data['pieces'][0]);near=Expansion(K,images,arb('.6'),128,src);proxy=Expansion(K,charges,arb('1.1'),144,coefficients=matrix(fits['B_center']));cache=SelfCache(data,K)
  center=dict(K=K,src=src,near=near,proxy=proxy,cache=cache,W=matrix(data['incident']),seconds=time.perf_counter()-start)
  leads=[]
  for i in [1,2]:
    t=time.perf_counter();K=Proxy(data);K.R=(pars[0,7].real,);K.b=pars[0,4+i].real;piece=data['pieces'][i];bc=matrix(fits['B_negative' if i==1 else 'B_positive']);G=matrix(piece['G']);BL,states,r,tr=envelope(K,piece,bc,Z,beta,d,nmax)
    ctx.prec=192;V=acb_mat(G.ncols(),nmax+1,[states[j][l,0] for l in range(G.ncols()) for j in range(nmax+1)]);W=G*V;Ct=matrix(piece['tau_coeff'])*W;Cz=matrix(piece['zeta_coeff'])*W;cp=dict(piece,tau_coeff=Ct,zeta_coeff=Cz);ctx.prec=cfg.bits
    src=Sources(K,cp,64,80,arb('.12'));near=Expansion(K,images,arb('.6'),72,src);proxy=Expansion(K,charges,arb('1.1'),144,coefficients=bc*V)
    leads.append(dict(K=K,piece=piece,bc=bc,src=src,near=near,proxy=proxy,W=W,V=V,states=states,r=r,BL=BL,tail=tr,seconds=time.perf_counter()-t))
  return dict(center=center,leads=leads,beta=beta,d=d,Z=Z,phase=phase,seconds=time.perf_counter()-start)
