"""Read-only independent I9.3 raw-binary audit; NumPy only, no MATLAB.
Based on the Skeptic's executed inline reconstruction. Reassemble every curved
P2 element and constraints; do not read historical values or solve eigenpairs.
"""
import numpy as np
import json, pathlib, sys, csv, time
p=pathlib.Path(sys.argv[1]); start=time.perf_counter()
meta=json.loads((p/'raw-audit.json').read_text())
S=json.loads((p/'summary.json').read_text()); C=S['config']
D={k:np.fromfile(p/(k+'.bin'),dtype='<f8').reshape(shape,order='F') for k,shape in meta['arrays'].items()}
checks=[]; detail={}
def ck(v,label):
  if not bool(v): raise AssertionError(label)
  checks.append(label)
def rel(a,b):
  return float(np.linalg.norm(a-b)/max(np.linalg.norm(a),np.linalg.norm(b),1e-300))
def coo(name):
  x=D[name]
  return x[:,0].astype(int)-1,x[:,1].astype(int)-1,x[:,2]+1j*x[:,3]
def mv(name,x):
  r,c,v=coo(name); out=np.zeros((meta[name+'_matrix_size'][0],)+x.shape[1:],complex)
  if x.ndim==1: np.add.at(out,r,v*x[c])
  else:
    for j in range(x.shape[1]): np.add.at(out[:,j],r,v*x[c,j])
  return out
def compressed(r,c,v,n):
  key=r.astype(np.int64)*n+c; ix=np.argsort(key); key=key[ix]; v=v[ix]
  starts=np.r_[0,np.flatnonzero(np.diff(key))+1]
  return key[starts],np.add.reduceat(v,starts)
def compare_sparse(name,r,c,v):
  rr,cc,vv=coo(name); n=meta[name+'_matrix_size'][1]
  ka,va=compressed(rr,cc,vv,n); kb,vb=compressed(r,c,v,n)
  allk=np.union1d(ka,kb); a=np.zeros(len(allk),complex); b=a.copy()
  a[np.searchsorted(allk,ka)]=va; b[np.searchsorted(allk,kb)]=vb
  return rel(a,b)
ck(C['model']==dict(beta=.5,d=1,L=1,star_scale=1,rho_center=4,rho_negative=17,rho_positive=17,rho_background=1,a_negative=.12,a_positive=.2,radius=.2),'physical model')
ck([C['mesh'][k] for k in ['half_cells','subdivisions','interface_segments','quadrature_order']]==[6,12,80,8],'formal mesh')
kw=np.array([1.4509999999999998,2.2490000000000001]); ck(np.array_equal(C['window'],kw),'known window')
sh=kw[0]**2+(np.arange(3)+.5)/3*np.diff(kw**2)[0]
ck(np.max(abs(sh-C['solver']['shifts_mu']))<1e-14,'window-only mu shifts')
pts=D['points']; p2=D['p2_points']; tr=D['triangles'].astype(int)-1; t2=D['triangle_p2'].astype(int)-1
edges=D['edges'].astype(int)-1; ie=D['interface_edges'].astype(int).ravel()-1
mat=D['material'].ravel(); cells=D['cell_id'].astype(int).ravel(); nt=len(tr); nd=len(p2); nr=meta['A_matrix_size'][0]
theta=D['interface_parameters'].ravel(); ck(len(ie)==13*80,'interface inventory')
def curve(c,t):
  if c==0: return np.column_stack([.2*(1.5+.3*np.cos(5*t))*np.cos(t),.2*(1+.3*np.cos(5*t))*np.sin(t)])
  a=.12 if c<0 else .2; r=.2*(1+a*np.cos(3*t))/np.sqrt(1+a*a/2)
  return np.column_stack([c+r*np.cos(t),r*np.sin(t)])
gerr=0
for ii,c in enumerate(range(-6,7)):
  sl=slice(ii*80,(ii+1)*80); tt=theta[sl]; ee=edges[ie[sl]]
  e1=curve(c,tt); e2=curve(c,tt+2*np.pi/80)
  gerr=max(gerr,np.max(abs(p2[len(pts)+ie[sl]]-curve(c,tt+np.pi/80))))
  for j in range(80):
    a=pts[ee[j]]; b=np.array([e1[j],e2[j]])
    gerr=max(gerr,min(np.max(abs(a-b)),np.max(abs(a-b[::-1]))))
ck(gerr<2e-14,'all analytic interface positions/orientation'); detail['geometry_max_abs']=float(gerr)
inc=np.zeros(len(edges),int); owner=[[] for _ in range(len(edges))]; emap={tuple(e):i for i,e in enumerate(edges)}
for ti,row in enumerate(tr):
  for j,(a,b) in enumerate(((0,1),(1,2),(2,0))):
    ei=emap[tuple(sorted((row[a],row[b])))]; inc[ei]+=1; owner[ei].append(ti)
    ck(t2[ti,3+j]==len(pts)+ei,'P2 edge '+str(ti)+'-'+str(j))
ck(np.all(inc[ie]==2),'all material edges incidence two')
for e in ie: ck(set(mat[owner[e]]) in ({1.,4.},{1.,17.}),'opposite material '+str(e))
cent=pts[tr].mean(axis=1); expectedmat=np.ones(nt)
for c in range(-6,7):
  ids=np.flatnonzero(cells==c); pol=curve(c,2*np.pi*np.arange(80)/80); q=cent[ids]; inside=np.zeros(len(ids),bool)
  for j in range(80):
    a=pol[j]; b=pol[(j+1)%80]; cross=((a[1]>q[:,1])!=(b[1]>q[:,1]))
    if b[1]!=a[1]: inside^=cross & (q[:,0]<(b[0]-a[0])*(q[:,1]-a[1])/(b[1]-a[1])+a[0])
  expectedmat[ids[inside]]=4 if c==0 else 17
ck(np.array_equal(mat,expectedmat),'all independent element material labels')
ck(np.all(np.min(p2[t2][:,:,0],axis=1)>=cells-.5-1e-13) and np.all(np.max(p2[t2][:,:,0],axis=1)<=cells+.5+1e-13),'cell mass partitions')
n=p2[t2]; gl=np.array([[-1.,1,0],[-1,0,1]])
def reference(xi,eta):
  l=np.array([1-xi-eta,xi,eta]); basis=np.r_[l*(2*l-1),4*l[0]*l[1],4*l[1]*l[2],4*l[2]*l[0]]
  G=np.empty((2,6)); G[:,:3]=gl*(4*l-1)
  G[:,3]=4*(l[0]*gl[:,1]+l[1]*gl[:,0]); G[:,4]=4*(l[1]*gl[:,2]+l[2]*gl[:,1]); G[:,5]=4*(l[2]*gl[:,0]+l[0]*gl[:,2])
  return basis,G
z,w=np.polynomial.legendre.leggauss(8); z=(z+1)/2; w=w/2
kval=np.zeros((nt,6,6)); mval=kval.copy(); areas=np.zeros(nt)
for i,xi in enumerate(z):
  for j,s in enumerate(z):
    eta=(1-xi)*s; basis,G=reference(xi,eta)
    J=np.einsum('tai,ja->tij',n,G); det=J[:,0,0]*J[:,1,1]-J[:,0,1]*J[:,1,0]
    invT=np.empty_like(J); invT[:,0,0]=J[:,1,1]; invT[:,0,1]=-J[:,1,0]; invT[:,1,0]=-J[:,0,1]; invT[:,1,1]=J[:,0,0]; invT/=det[:,None,None]
    grad=np.einsum('tij,ja->tia',invT,G); weight=w[i]*w[j]*(1-xi)*det
    kval+=np.einsum('tia,tib->tab',grad,grad)*weight[:,None,None]
    mval+=mat[:,None,None]*weight[:,None,None]*np.outer(basis,basis); areas+=weight
rr=np.broadcast_to(t2[:,:,None],(nt,6,6)).ravel(); cc=np.broadcast_to(t2[:,None,:],(nt,6,6)).ravel()
detail['independent_K_assembly_relative']=compare_sparse('K_full',rr,cc,kval.ravel())
detail['independent_M_assembly_relative']=compare_sparse('M_full',rr,cc,mval.ravel())
ck(detail['independent_K_assembly_relative']<1e-12 and detail['independent_M_assembly_relative']<1e-12,'all independent curved P2 assembly')
em=D['element_mass'].reshape((nt,6,6),order='F'); detail['element_mass_relative']=rel(mval,em)
ck(detail['element_mass_relative']<1e-12,'all element mass forms')
ck(np.max(abs(areas-D['element_area'].ravel()))<1e-14 and abs(sum(areas)-13)<1e-10,'element areas and strip partition')
nodesref=np.array([[0,0],[1,0],[0,1],[.5,0],[.5,.5],[0,.5]])
poly=np.column_stack([np.ones(6),nodesref[:,0],nodesref[:,1],nodesref[:,0]**2,np.prod(nodesref,axis=1),nodesref[:,1]**2]); dv=[]
for xi,eta in nodesref:
  _,G=reference(xi,eta); J=np.einsum('tai,ja->tij',n,G); dv.append(np.linalg.det(J))
coef=np.linalg.solve(poly,np.array(dv)).T
ck(rel(coef,D['determinant_coefficients'])<1e-11,'independent detJ polynomial coefficients')
globalmin=np.inf
for a in coef:
  cand=[[0,0],[1,0],[0,1]]
  for j,(aa,bb) in enumerate([(a[3],a[1]),(a[5],a[2]),(a[3]-a[4]+a[5],a[1]-a[2]+a[4]-2*a[5])]):
    if abs(aa)>1e-18:
      t=-bb/(2*aa)
      if 0<t<1: cand.append(([t,0],[0,t],[t,1-t])[j])
  H=np.array([[2*a[3],a[4]],[a[4],2*a[5]]])
  if abs(np.linalg.det(H))>1e-30:
    xy=np.linalg.solve(H,-a[1:3])
    if min(xy)>0 and sum(xy)<1: cand.append(xy)
  cand=np.array(cand); xx,yy=cand.T
  globalmin=min(globalmin,np.min(a[0]+a[1]*xx+a[2]*yy+a[3]*xx**2+a[4]*xx*yy+a[5]*yy**2))
ck(globalmin>0 and abs(globalmin-S['validation']['determinant_minimum'])<1e-12,'global positive curved Jacobian')
detail['determinant_minimum_independent']=float(globalmin)
pr,pc,pv=coo('P'); ck(len(np.unique(pr))==len(pr),'one master per active full row')
masters=np.full(nd,-1,int); phase=np.zeros(nd,complex); masters[pr]=pc; phase[pr]=pv
top=D['top'].astype(int).ravel()-1; bot=D['bottom'].astype(int).ravel()-1; dirs=D['dirichlet'].astype(int).ravel()-1
ck(np.max(abs(p2[top,0]-p2[bot,0]))<1e-13 and np.array_equal(masters[top],masters[bot]),'P2 y seam coordinates and masters')
ck(np.max(abs(phase[top]-np.exp(.5j)*phase[bot]))<1e-14 and np.all(masters[dirs]==-1),'QP phase and Dirichlet all DOFs')
for full,red in [('K_full','A'),('M_full','B')]:
  r,c,v=coo(full); use=(masters[r]>=0)&(masters[c]>=0)
  defect=compare_sparse(red,masters[r[use]],masters[c[use]],np.conj(phase[r[use]])*v[use]*phase[c[use]])
  detail[red+'_projection_relative']=defect; ck(defect<1e-12,red+' original-coordinate projection')
V=D['V_real']+1j*D['V_imag']; mu=(D['mu_real']+1j*D['mu_imag']).ravel()
AV=mv('A',V); BV=mv('B',V)
res=np.linalg.norm(AV-BV*mu,axis=0)/(np.linalg.norm(AV,axis=0)+abs(mu)*np.linalg.norm(BV,axis=0))
full=mv('P',V); cellmass=np.zeros((len(mu),13))
for j in range(len(mu)):
  local=full[t2,j]; mass=np.einsum('ta,tab,tb->t',local.conj(),mval,local).real
  cellmass[j]=np.bincount(cells+6,weights=mass,minlength=13)
ov=np.abs(V.conj().T@BV)
ck(np.max(abs(ov-D['overlaps']))<1e-10,'all mass overlaps')
ck(np.max(abs(cellmass-D['cell_mass']))<1e-10,'all independent per-cell masses')
ck(np.max(abs(cellmass.sum(axis=1)-1))<1e-10,'all weighted mass normalization')
modes=S['modes']; ks=np.sqrt(mu.real); valid=[]; localized=[]; inwindow=[]
for j,m in enumerate(modes):
  ck(abs(res[j]-m['residual'])<1e-11,'original-coordinate residual '+str(j+1))
  center=cellmass[j,6]; core=sum(cellmass[j,5:8]); ends=sum(cellmass[j,:2])+sum(cellmass[j,-2:])
  vals=dict(center_mass=center,core_mass=core,end_mass=ends,negative_mass=sum(cellmass[j,:6]),positive_mass=sum(cellmass[j,7:]))
  for key,value in vals.items(): ck(abs(value-m[key])<1e-10,'mass '+key+' '+str(j+1))
  valid.append(m['solver_flag']==0 and mu[j].real>0 and abs(mu[j].imag)<1e-10 and res[j]<=1e-8)
  localized.append(center>=.15 and core>=.60 and ends<=.02); inwindow.append(kw[0]<=ks[j]<=kw[1])
reps=[]; duplicates=np.zeros(len(mu),int)
# Retain the recorded solver residual ordering for deterministic representative identity.
# Independently reconstructed residuals above verify acceptance, not new eigensolves.
for j in np.argsort([m['residual'] for m in modes],kind='stable'):
  if not valid[j]: continue
  for r in reps:
    if abs(ks[j]-ks[r])<=1e-6 and ov[j,r]>=.9: duplicates[j]=r+1; break
  if duplicates[j]==0: reps.append(j)
candidates=[]
for j,m in enumerate(modes):
  cand=valid[j] and localized[j] and inwindow[j] and duplicates[j]==0
  ck(m['duplicate_of']==int(duplicates[j]) and bool(m['candidate'])==cand,'dedup/candidate '+str(j+1))
  if cand: candidates.append(j+1)
ck(candidates==np.atleast_1d(S['candidate_ids']).tolist(),'all candidate IDs')
detail.update(full_dof=nd,reduced_dof=nr,triangles=nt,root_count=len(mu),max_residual=float(max(res)),candidate_ids=candidates,candidate=[modes[j-1] for j in candidates],cell_mass_max_absolute_difference=float(np.max(abs(cellmass-D['cell_mass']))))
status=json.loads((p/'status.json').read_text()); resources=list(csv.DictReader((p/'resources.csv').open()))
ck(status['exit_code']==0 and status['survivors']==[],'normal exit and no survivors')
ck(max(int(r['rss_bytes']) for r in resources)==status['peak_rss_bytes']<3_000_000_000,'sampled RSS maximum')
ck(all(r['external_matlab']=='[]' for r in resources),'no concurrent MATLAB')
t=S['timings']
ck(abs(sum(t[k] for k in ['mesh_seconds','assembly_constraints_seconds','eigensolve_seconds','delivery_seconds'])-t['algorithm_seconds'])<1e-10,'exclusive algorithm timing')
detail['timings']=t; detail['resource']=status; detail['audit_seconds']=time.perf_counter()-start
print(json.dumps(dict(verdict='PASS',checks=len(checks),details=detail,environment=dict(python=sys.executable,numpy=np.__version__,scipy_used=False)),indent=2))
