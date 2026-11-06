# Copied from test/bie-bound/pipeline-v1/residual/boundary_group.py.
# Copied from test/bie-bound/grouprel-v1/boundary_group.py; pipeline adaptations documented in README.
"""Junction, interior-wall and seam residuals on actual state columns.
Input: shared field caches, side and segment index. Output: polynomial/error ledger.
"""
import eval_settings as cfg
import time,copy
from flint import arb,acb,acb_mat,ctx
from material import I,up
from expansion import Expansion,norm
from extended import incident
from column_models import models,column_norm
from wall_columns import ratios
from group_norms import columns
from envelope_gate import rectangle

def first(obj):
  """Restrict shared coefficient objects to their first actual state."""
  a=copy.copy(obj);a['src']=copy.copy(obj['src']);s=a['src'];cut=lambda A:acb_mat(A.nrows(),1,[A[i,0] for i in range(A.nrows())]);s.nc=1;s.Ct=cut(s.Ct);s.Cz=cut(s.Cz);s.rows=[(x,y,cut(b)) for x,y,b in s.rows]
  p=copy.copy(obj['proxy']);p.nc=1;p.coefficients=cut(p.coefficients);p.plus=[cut(x) for x in p.plus];p.minus=[cut(x) for x in p.minus];a['proxy']=p;a['W']=cut(obj['W']);a['V']=cut(obj['V']);return a

def compute(shared,kind,side,idx,check=False,depth=0,sub=0):
  start=time.perf_counter();ctx.prec=192;beta=shared['beta'];d=shared['d'];phase=(I*beta*d).exp();three=[(arb(0),arb(m),phase**m) for m in [-1,0,1]]
  if kind=='seam':h=arb('.0625')/(cfg.panel_factor*2**depth);coordinate=-arb('.5')+(idx+(sub+.5)/2**depth)*(arb('.125')/cfg.panel_factor);R=arb('.16')/(cfg.panel_factor*2**depth);obj=shared['center'] if side==0 else shared['leads'][side-1];spec=[(obj,coordinate,arb('.5')),(obj,coordinate,arb('-.5'))]
  else:
    h=arb('.03125')/(cfg.panel_factor*2**depth);coordinate=-arb('.5')+(idx+(sub+.5)/2**depth)*(arb('.0625')/cfg.panel_factor);R=arb('.08')/(cfg.panel_factor*2**depth);obj=shared['leads'][side-1];sg=arb(1 if side==2 else -1)
    if kind=='junction':spec=[(shared['center'],sg/2,coordinate),(first(obj),-sg/2,coordinate)]
    else:spec=[(obj,sg/2,coordinate),(obj,-sg/2,coordinate)]
  regions=[]
  for obj,x,y in spec:
    reg=Expansion(obj['K'],three,R,80,obj['src'],(x,y));rn,rp=ratios(obj['src'],obj['proxy']);regions.append((obj,reg,rn,rp))
  setup=time.perf_counter()-start;t=time.perf_counter();nc=regions[0][0]['src'].nc;nout=1 if kind=='junction' else (nc-1 if kind=='interior' else nc)
  ar=(arb('.5')**2+(abs(coordinate)+h)**2).sqrt();anal=[arb(0)]*nout;env=[arb(0)]*nout;extra=[arb(0)]*nout;gates=[]
  for i,(obj,reg,rn,rp) in enumerate(regions):
    nt=sum(reg.tails(h),arb(0));pt=sum(obj['proxy'].tails(ar),arb(0));K=obj['K'];W=obj['W']
    if kind!='seam':
      x=spec[i][1];ib,_,gr=rectangle(lambda z:incident(K,beta,d,x,z)*W,coordinate,R,R);gates.append(gr)
    for j in range(nout):
      jj=j+1 if kind=='interior' and i==1 else j
      anal[j]+=nt*rn[jj]+pt*rp[jj];env[j]+=reg.B*rn[jj]+obj['proxy'].B*rp[jj]
      if kind!='seam':env[j]+=ib[jj]
  envelopetime=time.perf_counter()-t;ctx.prec=cfg.bits;t=time.perf_counter();nodes=[]
  for l in range(cfg.nodes):
    vcoord=coordinate+h*(arb.pi()*(2*l+1)/(2*cfg.nodes)).cos();fields=[];basis=[]
    for i,(obj,reg,rn,rp) in enumerate(regions):
      x,y=(vcoord,spec[i][2]) if kind=='seam' else (spec[i][1],vcoord)
      v,e=reg.value(x,y);p,ep=obj['proxy'].value(x,y);v+=p
      if kind!='seam':v+=incident(obj['K'],beta,d,x,y)*obj['W']
      fields.append(v);basis.append(e+ep)
    a,b=fields
    if kind=='seam':v=acb_mat(2,nout,[z for rr in range(2) for j in range(nout) for z in [[phase*b[0,j]-a[0,j],a[2,j]-phase*b[2,j]][rr]]])
    else:v=acb_mat(2,nout,[z for rr in range(2) for j in range(nout) for jj in [j+1 if kind=='interior' else j] for z in [[b[0,jj]-a[0,j],a[1,j]-b[1,jj]][rr]]])
    nodes.append(v)
    for j in range(nout):extra[j]=max(extra[j],sum(basis,arb(0)))
  nodetime=time.perf_counter()-t;t=time.perf_counter();cf,errors,ledger=models(nodes,[a+b for a,b in zip(anal,extra)],env);rec=columns(cf,errors,h,check);rec.update(depth=depth,sub=sub,envelope_gates=gates,kind=kind,side=side,index=idx,coordinate=str(coordinate),setup_seconds=setup,envelope_seconds=envelopetime,node_seconds=nodetime,algebra_seconds=time.perf_counter()-t,ledger=ledger,seconds=time.perf_counter()-start)
  return cf,errors,rec
