"""Independent post-run reconstruction of the I9.2 MAT-v7 fixed-field evidence.
Based on: the I8 pipeline audit MAT-v7 reader; no old-script runtime import.
Uses existing NumPy only; never launches MATLAB or recomputes a physical field.
"""
import struct
import zlib
import numpy as np
import json
import sys
import math
import platform
import resource
import time

audit_start = time.perf_counter()


def elems(buf):
  p = 0
  while p + 8 <= len(buf):
    tag, n = struct.unpack_from('<II', buf, p)
    if tag >> 16:
      typ = tag & 65535
      n = tag >> 16
      data = buf[p + 4:p + 4 + n]
      p += 8
    else:
      typ = tag
      data = buf[p + 8:p + 8 + n]
      p += 8 + n + (0 if typ == 15 else (-n) % 8)
    yield typ, data


def numeric(t, b):
  dt = {1: 'i1', 2: 'u1', 3: '<i2', 4: '<u2', 5: '<i4', 6: '<u4',
        7: '<f4', 9: '<f8', 12: '<i8', 13: '<u8', 16: 'u1',
        17: '<u2', 18: '<u4'}[t]
  return np.frombuffer(b, dtype=dt).copy()


def matrix(b):
  e = list(elems(b))
  flags = numeric(*e[0])
  cls = int(flags[0]) & 255
  dims = tuple(numeric(*e[1]).astype(int))
  name = e[2][1].decode(errors='replace')
  tail = e[3:]
  if cls == 1:
    return name, [matrix(x[1])[1] for x in tail]
  if cls in (2, 3):
    off = 1 if cls == 3 else 0
    width = int(numeric(*tail[off])[0])
    raw = tail[off + 1][1]
    fields = [raw[i:i + width].split(b'\0')[0].decode()
              for i in range(0, len(raw), width)]
    payload = tail[off + 2:]
    records = []
    for j in range(int(np.prod(dims))):
      records.append({k: matrix(payload[j * len(fields) + i][1])[1]
                      for i, k in enumerate(fields)})
    return name, records[0] if len(records) == 1 else records
  if cls == 4:
    return name, ''.join(chr(int(x)) for x in (numeric(*tail[0]) if tail else []))
  if cls in (16, 17, 18):
    return name, None
  if not tail:
    return name, np.empty(dims)
  val = numeric(*tail[0])
  if int(flags[0]) & 2048:
    val = val + 1j * numeric(*tail[1])
  return name, val.reshape(dims, order='F').squeeze()


def matload(path):
  data = open(path, 'rb').read()
  out = {}
  for typ, b in elems(data[128:]):
    if typ == 15:
      for t, c in elems(zlib.decompress(b)):
        if t == 14:
          k, v = matrix(c)
          out[k] = v
    elif typ == 14:
      k, v = matrix(b)
      out[k] = v
  return out


def scalar(x):
  return float(np.asarray(x))


def rel(a, b):
  return float(np.linalg.norm(np.asarray(a) - np.asarray(b)) /
               max(np.linalg.norm(np.asarray(a)), np.linalg.norm(np.asarray(b)), 1e-300))


def sq(v, w):
  return float(np.sum(w * np.abs(v)**2).real)


from pathlib import Path

def interpft(a,m):
  n=a.shape[0]; j=n//2; F=np.fft.fft(a,axis=0)
  Z=np.zeros((m,)+a.shape[1:],complex)
  Z[:j]=F[:j]; Z[-j+1:]=F[j+1:]; Z[j]=F[j]/2; Z[m-j]=F[j]/2
  return np.fft.ifft(Z,axis=0)*(m/n)

def audit(directory):
  checks=[]; details={}
  def ck(ok,label):
    checks.append(label)
    if not ok: raise AssertionError(label)
  D=matload(str(directory/'evidence.mat')); r=D['result']; e=D['evidence']; cfg=D['config']
  b=e['base']; p=e['propagation']; model=b['model']; K=int(scalar(cfg['discretization']['K'])); N=768
  ck(scalar(cfg['k0'])==1.5584378941820909,'fixed literal candidate')
  ck(scalar(model['rho_center'])==4 and scalar(model['star_scale'])==1,'native star material4')
  ck(scalar(model['beta'])==.5 and scalar(model['rho_lead'])==17 and scalar(model['rho_exterior'])==1,'materials beta')
  ck(scalar(model['a_negative'])==.12 and scalar(model['a_positive'])==.20,'different unmirrored trilobes')
  ck(scalar(cfg['backend']['fmm_eps'])==1e-12,'FMM tolerance')
  ck(np.array_equal(model['disk_center'],[0,.375]) and scalar(model['disk_radius'])==.0625,'relocated disk')
  ck(np.array_equal(cfg['evaluation']['disk_grid'],[32,64]),'single mass grid')
  ck(scalar(cfg['evaluation']['material_nodes'])==768 and scalar(cfg['evaluation']['wall_nodes'])==768,'single evaluation grid')
  for side,n in [('center',512),('negative',256),('positive',256)]:
    cell=b[side]; rho=4 if side=='center' else 17
    ck(cell['i9_geometry'].shape==(6,n) and cell['H_L'].shape==(2*n,K),'field dimensions '+side)
    ck(scalar(cell['rho'])==rho and scalar(cell['kint'])==math.sqrt(rho)*scalar(cfg['k0']),'wave number '+side)
    sc=np.sqrt(np.tile(cell['far_aux']['weights'],2)); H=np.column_stack([cell['H_L'],cell['H_R']]); B=np.column_stack([cell['B_L'],cell['B_R']])
    defect=np.linalg.norm(cell['A_QP']@(sc[:,None]*H)+sc[:,None]*B)/max(1,np.linalg.norm(sc[:,None]*B))
    ck(defect<1e-10,'physical density solve '+side);details[side+'_BIE']=float(defect)
  center=b['center']; positive=b['positive']; negative=b['negative']; q=b['q']; gamma=b['gamma']; beta=b['beta_m']
  Zp=positive['Z']; Zm=negative['Z']; Ap=Zp[:K]; Bp=Zp[K:]; Am=Zm[:K]; Bm=Zm[K:]; G=np.diag(gamma); I=np.eye(K)
  Lp=np.linalg.solve((Ap+Bp).T,(1j*G@(Ap-Bp)).T).T
  Lm=np.linalg.solve((Am+Bm).T,(-1j*G@(Am-Bm)).T).T
  T=np.block([[I+center['R_L'],center['T_RL']],[center['T_LR'],I+center['R_R']]])
  Ad=np.block([[(1j*G-Lm)@center['R_L']-(1j*G+Lm),(1j*G-Lm)@center['T_RL']],[(1j*G-Lp)@center['T_LR'],(1j*G-Lp)@center['R_R']-(1j*G+Lp)]])
  bb=np.sqrt(1+abs(beta)**2); rw=np.tile(1/np.sqrt(bb),2); cw=np.tile(1/np.sqrt(bb+abs(gamma)**2/bb),2)
  Aph=rw[:,None]*Ad*cw[None,:]; matrix={}
  for name,a in [('T',T),('Adef',Ad),('Aphys',Aph)]:
    matrix[name]=rel(a,b['matching'][name]);ck(matrix[name]<1e-12,'matching rebuild '+name)
  details['matrix_relative']=matrix; details['metric_absolute_differences']={}
  for name,prefix in [('Adef','adef'),('Aphys','aphys')]:
    ss=np.linalg.svd(b['matching'][name],compute_uv=False)
    details['metric_absolute_differences'][prefix]=[abs(float(ss[-1])-scalar(r['point'][prefix+'_sigma'])),abs(float(ss[-1]/ss[0])-scalar(r['point'][prefix+'_ratio']))]
  ck(abs(np.linalg.norm(q)-1)<1e-12,'q normalization')
  density=np.column_stack([center['H_L'],center['H_R']])@q
  ck(rel(density,e['center_density'])<1e-12,'frozen density identity')
  def classification(d,label):
    alpha=d['alpha_real']+1j*d['alpha_imag']; theta=d['theta_real']+1j*d['theta_imag']; res=scalar(d['residual']); qc=cfg['qualification']
    scale=np.hypot(abs(alpha),abs(theta)); tol=max(scalar(qc['qz_eps_factor'])*np.finfo(float).eps,scalar(qc['qz_residual_factor'])*res)
    ind=scale<=tol; den=scale.copy();den[ind]=1; an=abs(alpha)/den;tn=abs(theta)/den
    inner=max(scalar(qc['inner_floor']),scalar(qc['inner_residual_factor'])*res);outer=max(scalar(qc['outer_floor']),scalar(qc['outer_inner_factor'])*inner)
    stable=~ind&(an<tn-outer);unstable=~ind&(an>tn+outer)
    ck(np.sum(stable)==K and np.sum(unstable)==K and not np.any(ind) and res<1e-10,'raw classification '+label)
    return {'minimum_margin':float(np.min(abs(an-tn))),'stable':int(sum(stable)),'unstable':int(sum(unstable)),'residual':res}
  details['classification']={name:classification(b[name]['qz'],name) for name in ['negative','positive']}
  details['classification']['negative_reverse']=classification(negative['reverse_qz'],'negative_reverse')
  for side,P,Z,A,B,Gexpected in [('positive',p['Pplus'],Zp,positive['A'],positive['B'],np.vstack([Ap,Bp@p['Pplus']])),('negative',p['Pminus'],Zm,negative['B'],negative['A'],np.vstack([Am@p['Pminus'],Bm]))]:
    recurrence=np.linalg.norm(A@Z-B@Z@P)/max(1,np.linalg.norm(A@Z)+np.linalg.norm(B@Z@P));ck(recurrence<1e-10,'decay direction '+side)
    saved=p['Gplus' if side=='positive' else 'Gminus'];ck(rel(saved,Gexpected)<1e-12,'port state '+side)
  def series(action,G,P,c,saved,label):
    rows=[];c=c.copy()
    for i in range(41):
      state=G@c; rows.append([sq(action['signed_value_action']@state,action['weights']),sq(action['signed_normal_action']@state,action['weights'])]);c=P@c
    rows=np.asarray(rows); savedrows=np.array([[scalar(x['value_squared']),scalar(x['normal_squared'])] for x in saved['cells']])
    ratios=rows[40]/np.maximum(np.finfo(float).tiny,rows[39]);tail=rows[40]/(1-ratios)
    ck(np.all(np.isfinite(ratios)) and np.all((ratios>=0)&(ratios<1)),'tail applicability '+label)
    ck(rel(rows[:40],savedrows)<1e-10,'finite rows '+label)
    ck(rel(tail,[scalar(saved['tail_value_squared_candidate']),scalar(saved['tail_normal_squared_candidate'])])<1e-10,'tail rows '+label)
    details[label]={'finite':rows[:40].sum(0).tolist(),'ratio':ratios.tolist(),'tail':tail.tolist(),'rows_relative':rel(rows[:40],savedrows)}
    return rows[:40].sum(0)+tail
  ca=e['center_action']; sc=ca['density_scale']; eta=ca['density']; raw=ca['A_scaled']@(sc*eta)/sc+ca['Bq']
  details['center_raw_absolute']=float(np.max(abs(raw-ca['raw_action'])))
  ck(details['center_raw_absolute']<1e-10,'raw center action')
  expected_eta=np.r_[interpft(e['center_density'][:512],768),interpft(e['center_density'][512:],768)]
  ck(rel(expected_eta,eta)<1e-12,'same center density interpolation')
  totals=np.array([sq(ca['signed_value'],ca['weights']),sq(ca['signed_normal'],ca['weights'])])
  details['center_jump']=totals.tolist()
  for side,suffix in [('negative','minus'),('positive','plus')]:
    a=e[side+'_action']; sc=a['density_scale']; H=a['density_map']; raw=a['A_scaled']@(sc[:,None]*H)/sc[:,None]+a['B']
    defect=max(np.max(abs(raw[:N]-a['signed_value_action'])),np.max(abs(raw[N:]+a['signed_normal_action'])))
    ck(defect<1e-10,'raw material action '+side); details[side+'_raw_absolute']=float(defect)
    totals+=series(a,p['G'+suffix],p['P'+suffix],p['c'+suffix],e[side+'_sum'],side+'_material')
  walls=e['walls']; cm=e['center_maps']; nm=e['negative_maps'];pm=e['positive_maps'];weight=1/768
  xm=p['Gminus']@p['cminus'];xp=p['Gplus']@p['cplus']
  for side,v,n in [('left',nm['right_value']@xm-cm['left_value'],nm['right_dx']@xm-cm['left_dx']),('right',pm['left_value']@xp-cm['right_value'],cm['right_dx']-pm['left_dx']@xp)]:
    ck(np.max(abs(v-walls[side]['value']))<1e-10 and np.max(abs(n-walls[side]['normal']))<1e-10,'junction '+side)
    totals+=np.array([sq(walls[side]['value'],weight),sq(walls[side]['normal'],weight)])
  for side,suffix in [('negative','minus'),('positive','plus')]:
    totals+=series(walls[side+'_action'],I,p['P'+suffix],p['c'+suffix],walls[side],side+'_walls')
  mass=e['mass'];U=math.sqrt(math.pi*scalar(mass['radius'])**2*np.mean(abs(mass['sample_values'])**2));eps=math.sqrt(totals[1]+totals[0]/scalar(model['d'])**2)
  theta=min(scalar(r['geometry'][s]['theta']) for s in ['center','negative','positive']);h=scalar(model['collar_h']);mu=scalar(cfg['k0'])**2;c0=1/(theta*h);c1=h/(2*theta)
  C=math.sqrt(c0/(mu*mu)+(c1+c0)/(4*mu)+c1*17);Q=C*eps;den=U-Q;R=2*mu*Q/den
  ck(den>0,'positive denominator'); scalars={'mu_num':mu,'C_num':C,'epsilon_num':eps,'U_num':U,'Q_num':Q,'denominator':den,'R_num':R}
  for name,value in scalars.items():ck(rel(value,r[name])<1e-10,'scalar rebuild '+name)
  details['scalars']=scalars;details['scalar_relative_differences']={name:rel(value,r[name]) for name,value in scalars.items()}
  for name in ['center','negative','positive']:
    for level in r['geometry'][name]['levels']:
      expected=.0618*np.pi if name=='center' else .04*np.pi
      ck(abs(scalar(level['area'])-expected)<1e-12,'actual area '+name)
      ck(scalar(level['theta'])>0 and scalar(level['local_factor'])<1 and scalar(level['far_chord_min'])>2*h and scalar(level['offset_pair_min'])>0,'sampled collar '+name)
  ck(scalar(r['geometry']['disk_conservative_vertical_clearance'])>2*h and scalar(r['geometry']['disk_wall_clearance'])>2*h,'background disk clearance')
  ck(not bool(scalar(e['periodic']['included_in_epsilon'])),'periodic identity separately diagnosed')
  details['periodic']={name: {'value_squared':scalar(e['periodic'][name]['value_squared']),'normal_squared':scalar(e['periodic'][name]['normal_squared'])} for name in ['center','negative','positive']}
  return {'status':'PASS','checks':len(checks),'details':details,'seconds':time.perf_counter()-audit_start,'python':sys.version,'numpy':np.__version__}

if __name__=='__main__':
  print(json.dumps(audit(Path(sys.argv[1])),indent=2,allow_nan=False))
