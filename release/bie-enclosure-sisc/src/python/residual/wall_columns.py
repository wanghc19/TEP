# Copied from test/bie-bound/pipeline-v1/residual/wall_columns.py; release R1 path/data interfaces may be adapted.
# Copied from test/bie-bound/grouprel-v1/wall_columns.py; pipeline adaptations documented in README.
"""Junction and interior wall models from full or actual-state columns.
Input: shared source coefficients, actual stable/port states, center field.
Output: wall polynomials, column error bounds and disjoint costs.
"""
import time
from flint import arb,acb,acb_mat,ctx
from material import I,up
from expansion import Expansion,norm
from extended import incident
from column_models import models,column_norm
from map_models import integral

def ratios(src,proxy):
  nc=src.nc;D=[2*arb.pi()*sum((norm([src.Ct[i,j],src.Cz[i,j]]) for i in range(src.Ct.nrows())),arb(0)) for j in range(nc)]
  b=proxy.coefficients;ch=sum((norm([b[i,j] for j in range(nc)]) for i in range(b.nrows())),arb(0))
  return [v/src.D.lower() for v in D],[sum((abs(b[i,j]).upper() for i in range(b.nrows())),arb(0))/ch.lower() for j in range(nc)]

def compute(K,src,proxy,W,V,beta,d,kind,center=None,full=False):
  ctx.prec=192;start=time.perf_counter();phase=(I*beta*d).exp();three=[(arb(0),arb(m),phase**m) for m in [-1,0,1]];y0=arb('.03125');h=arb('.03125');nc=W.ncols();nout=1 if kind=='junction' else nc-1
  left=Expansion(K,three,arb('.08'),80,src,(arb('-.5'),y0));right=None if kind=='junction' else Expansion(K,three,arb('.08'),80,src,(arb('.5'),y0));setup=time.perf_counter()-start
  if full:rn=[column_norm(W,j) for j in range(nc)];rp=[column_norm(V,j) for j in range(nc)]
  else:rn,rp=ratios(src,proxy)
  ar=(arb('.5')**2+(2*h)**2).sqrt();nt=[sum(ex.tails(h),arb(0)) for ex in ([left] if right is None else [left,right])];pt=sum(proxy.tails(ar),arb(0));yp=acb(y0,arb(0,arb('.08')))
  il=incident(K,beta,d,arb('-.5'),yp)*W;ir=None if right is None else incident(K,beta,d,arb('.5'),yp)*W
  if kind=='junction':
    K0,src0,p0,q,reg0=center;cenB=reg0.B+p0.B+norm(incident(K0,beta,d,arb('.5'),yp)*q);centail=sum(reg0.tails(h),arb(0))+sum(p0.tails(ar),arb(0));anal=[nt[0]*rn[0]+pt*rp[0]+centail];env=[left.B*rn[0]+proxy.B*rp[0]+column_norm(il,0)+cenB]
  else:
    anal=[nt[1]*rn[j]+nt[0]*rn[j+1]+pt*(rp[j]+rp[j+1]) for j in range(nout)]
    env=[right.B*rn[j]+left.B*rn[j+1]+proxy.B*(rp[j]+rp[j+1])+column_norm(ir,j)+column_norm(il,j+1) for j in range(nout)]
  ctx.prec=128;t=time.perf_counter();nodes=[];basis=[arb(0)]*nout
  def field(ex,x,y):
    v,e=ex.value(x,y);pv,pe=proxy.value(x,y)
    if full:v=v*W;pv=pv*V
    return v+pv+incident(K,beta,d,x,y)*W,e,pe
  for l in range(48):
    y=y0+h*(arb.pi()*(2*l+1)/96).cos();lv,le,lp=field(left,arb('-.5'),y)
    if kind=='junction':
      cv,ce=reg0.value(arb('.5'),y);pp,pe=p0.value(arb('.5'),y);cv+=pp+incident(K0,beta,d,arb('.5'),y)*q
      nodes.append(acb_mat(2,1,[lv[0,0]-cv[0,0],cv[1,0]-lv[1,0]]));basis[0]=max(basis[0],le*(rn[0] if full else 1)+lp*(rp[0] if full else 1)+ce+pe)
    else:
      rv,re,rp0=field(right,arb('.5'),y);nodes.append(acb_mat(2,nout,[z for rr in range(2) for j in range(nout) for z in [[lv[0,j+1]-rv[0,j],rv[1,j]-lv[1,j+1]][rr]]]))
      for j in range(nout):basis[j]=max(basis[j],le*(rn[j+1] if full else 1)+re*(rn[j] if full else 1)+lp*(rp[j+1] if full else 1)+rp0*(rp[j] if full else 1))
  nodetime=time.perf_counter()-t;t=time.perf_counter();cf,errors,rec=models(nodes,[x+y for x,y in zip(anal,basis)],env);v=integral(cf,h);error=norm(errors);upper=v.upper().sqrt()+(2*h).sqrt()*error
  record=dict(kind=kind,columns=src.nc,output_columns=nout,full_port_map=full,setup_seconds=setup,region_left=left.record,region_right=None if right is None else right.record,node_seconds=nodetime,algebra_seconds=time.perf_counter()-t,e_I=up(error),column_errors=list(map(up,errors)),V=str(v),finite_upper=up(upper),ledger=rec,seconds=time.perf_counter()-start)
  return cf,error,record
