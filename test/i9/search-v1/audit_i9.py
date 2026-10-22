"""Independent post-run audit of I9.1 asymmetric-lead gap and search evidence.

Based on: the locally copied MAT-v7 reader from I8.5 audit_scan.py.
Main changes: raw two-lead classification, direction and matching reconstruction.
Uses existing NumPy; no MATLAB launch or new physical calculations. This audit
reads only an explicitly supplied current-run directory and is not a runtime
prerequisite of the numerical experiment.
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

from pathlib import Path
from collections import Counter
import csv
root=Path(sys.argv[1]); state=json.loads((root/'state.json').read_text()); cfg=state['config']; ps=state['points']; checks=0; details={}
def ck(ok,label):
  global checks
  checks+=1
  if not ok: raise AssertionError(label)
def seq(x): return x if isinstance(x,list) else [x]
def detect(y,valid=None):
  valid=[True]*len(y) if valid is None else valid; out=[]; j=0
  while j<len(y):
    if not valid[j]: j+=1; continue
    z=j
    while z+1<len(y) and valid[z+1] and y[z+1]==y[j]: z+=1
    if j>0 and z+1<len(y) and valid[j-1] and valid[z+1] and y[j]<y[j-1] and y[z]<y[z+1]: out.append((j,z))
    j=z+1
  return out
ck(cfg['model']['a_negative']==.12 and cfg['model']['a_positive']==.20 and cfg['model']['beta']==.5,'frozen independent geometry')
ck(cfg['resolutions']=={'coarse':{'center_ntot':256,'negative_ntot':128,'positive_ntot':128},'fine':{'center_ntot':512,'negative_ntot':256,'positive_ntot':256}},'independent resolution fields')
ck(cfg['backend']['fmm_eps']==1e-12,'FMM tolerance')
leadlog=state['lead_log']; leads=leadlog['records']; qcfg=cfg['qualification']; margins=[]; residuals=[]
def classify(d,label):
  alpha=np.asarray(d['alpha_real'])+1j*np.asarray(d['alpha_imag']); theta=np.asarray(d['theta_real'])+1j*np.asarray(d['theta_imag']); res=d['residual']
  scale=np.hypot(abs(alpha),abs(theta)); tol=max(qcfg['qz_eps_factor']*np.finfo(float).eps,qcfg['qz_residual_factor']*res); ind=scale<=tol; den=scale.copy(); den[ind]=1
  an=abs(alpha)/den; tn=abs(theta)/den; dist=abs(an-tn); inner=max(qcfg['inner_floor'],qcfg['inner_residual_factor']*res); outer=max(qcfg['outer_floor'],qcfg['outer_inner_factor']*inner)
  masks={'stable':~ind&(an<tn-outer),'unstable':~ind&(an>tn+outer),'near':~ind&(dist<=inner),'uncertain':~ind&(dist>inner)&(dist<=outer),'indeterminate':ind}
  for name,m in masks.items():
    ck(int(m.sum())==d[name],label+' count '+name); ck(np.array_equal(m,np.asarray(d[name+'_mask'],dtype=bool)),label+' mask '+name)
  ck(np.max(abs(dist-np.asarray(d['distance'])))<2e-15,label+' distances'); ck(inner==d['inner'] and outer==d['outer'] and tol==d['tolerance'],label+' thresholds')
  if not np.all(np.isfinite(alpha)) or not np.all(np.isfinite(theta)) or not math.isfinite(res) or res>qcfg['residual_max']: status='UNQUALIFIED'
  elif ind.any(): status='INDETERMINATE'
  elif masks['uncertain'].any(): status='UNCERTAIN'
  elif masks['near'].any(): status='NEAR_UNIT_PROPAGATING'
  elif masks['stable'].sum()==cfg['common']['K'] and masks['unstable'].sum()==cfg['common']['K']: status='GAP'
  else: status='UNBALANCED'
  ck(d['status']==status or d['status']=='UNCERTAIN_DIRECTION_CLASSIFICATION',label+' status')
  if 'reverse' in d:
    reverse=classify(d['reverse'],label+' reciprocal'); ck((d['status']=='UNCERTAIN_DIRECTION_CLASSIFICATION')==(status!=reverse),label+' direction consistency')
  margins.append(float(dist.min())); residuals.append(res); return status
for r in leads:
  ck(r['k_hex']==struct.pack('>d',r['k']).hex(),'lead exact key')
  for side in ['negative','positive']:
    classify(r[side],str(r['id'])+side); ck(r[side+'_bie_residual']<=qcfg['bie_residual_max'],'BIE qualification')
  ck(r['common_gap']==(r['negative']['status']==r['positive']['status']=='GAP'),'common classification')
  calls=r['proxy_calls']; expected=cfg['resolutions'][r['resolution_id']]
  ck(len(calls)==2 and [c['nt'] for c in calls]==[expected['negative_ntot']**2,expected['positive_ntot']**2],'two independent lead target arrays')
  ck(all(c['ier']==0 and c['ns']==320 and c['batches']==1 for c in calls),'lead FMM status')
for r in leadlog['requests']:
  p=leads[r['record_id']-1]; ck(p['k']==r['k'] and p['resolution_id']==r['resolution_id'] and p['k_hex']==r['k_hex'],'lead request identity')
  if r['bypass']: ck(r['action']=='COMPUTED' and p['bypass'],'lead bypass')
ck(leadlog['cache_peak_bytes']<=cfg['gap']['cache_bytes'],'bounded LRU')
ck(sum(r['action']=='COMPUTED' for r in leadlog['requests'])==len(leads),'lead request accounting')
x=state['gap_exploration']['k']; ck(len(x)==33 and all(k==1.45+i*.025 for i,k in enumerate(x)),'original exploration grid')
for side,segments in state['gap_sides'].items():
  for seg in segments:
    ck(seg['safe_bounds']==[seg['left']['gap_point']+cfg['gap']['buffer'],seg['right']['gap_point']-cfg['gap']['buffer']],'inward buffer')
    for e in [seg['left'],seg['right']]:
      if e['status']=='NUMERICAL_TRANSITION_BRACKET': ck(e['width']<=cfg['gap']['edge_width'],'edge bracket actual width')
      if e['status']=='WINDOW_TRUNCATED': ck(e['excluded_class']=='OUTSIDE_WINDOW','truncated edge explicitly not physical edge')
for g in state['common_gaps']:
  n=state['gap_sides']['negative'][g['negative_segment']-1]['safe_bounds']; p=state['gap_sides']['positive'][g['positive_segment']-1]['safe_bounds']
  ck(g['bounds']==[max(n[0],p[0]),min(n[1],p[1])],'safe gap intersection')
for r in state['representative_checks']:
  c=leads[r['coarse_record_id']-1]; f=leads[r['fine_record_id']-1]
  ck(c['k']==f['k']==r['k'] and c['resolution_id']=='coarse' and f['resolution_id']=='fine','representative resolution identity')
  ck(c['common_gap']==r['coarse_common_gap'] and f['common_gap']==r['fine_common_gap'],'representative raw qualification')
seen={}; hits=0; bypass=0
for r in state['requests']:
  p=ps[r['point_id']-1]; ck(p['k']==r['k'] and p['resolution_id']==r['resolution_id'],'point request identity'); ck(p['k_hex']==struct.pack('>d',p['k']).hex(),'point binary64 key')
  key=state['config_key']+'|'+p['resolution_id']+'|'+p['k_hex']; ck(p['key']==key,'full config point key')
  if r['action']=='CACHE_HIT': ck(key in seen and seen[key]==r['point_id'] and not r['bypass_cache'],'point exact successful reuse'); hits+=1
  else:
    ck(r['action']=='COMPUTED','point action')
    if r['bypass_cache']: bypass+=1
    elif p['status']=='SUCCESS': ck(key not in seen,'no repeated successful computation'); seen[key]=p['id']
  if p['status']=='SUCCESS':
    lr=leads[p['lead_record_id']-1]; ck(lr['common_gap'] and lr['k']==p['k'] and lr['resolution_id']==p['resolution_id'],'point own qualified two leads')
    ck(all(math.isfinite(p[f]) and p[f]>=0 for f in ['adef_sigma','adef_ratio','aphys_sigma','aphys_ratio']),'four finite metrics')
    cc=seq(p['proxy_calls']); ck(len(cc)==1 and cc[0]['nt']==cfg['resolutions'][p['resolution_id']]['center_ntot']**2 and cc[0]['ier']==0,'own center resolution')
c=state['counters']; ck(c['requested']==len(state['requests'])==len(ps)+hits and c['computed']==len(ps) and c['cache_hits']==hits and c['confirmation']==bypass,'point counts')
for run in state['coarse_runs']:
  x=run['k']; ids=run['point_ids']; y=[ps[i-1].get('aphys_ratio',float('nan')) for i in ids]; valid=[ps[i-1]['status']=='SUCCESS' for i in ids]; dr=detect(y,valid)
  ck(len(x)>=11 and all(0<b-a<=.025+8*np.finfo(float).eps for a,b in zip(x,x[1:])),'coarse interval spacing')
  actual=[d for d in state['coarse_dips'] if d['gap_id']==run['gap_id']]; ck([(d['first']-1,d['last']-1) for d in actual]==dr,'all visible coarse dips')
  for d,(a,b) in zip(actual,dr):
    t=state['intervals'][d['interval_id']-1]; ck(t['initial_bounds']==[x[max(0,a-2)],x[min(len(x)-1,b+2)]] and t['gap_id']==d['gap_id'],'expanded fine source')
for h in state['history']:
  x=h['k']; ids=h['point_ids']; t=state['intervals'][h['interval_id']-1]; bounds=state['common_gaps'][t['gap_id']-1]['bounds']
  ck(len(x)==11 and all(a<b for a,b in zip(x,x[1:])),'fine actual eleven'); ck(all(bounds[0]<=k<=bounds[1] for k in x),'no unresolved gap-edge crossing'); ck(h['W']==x[-1]-x[0],'actual W')
  ck(all(ps[i-1]['resolution_id']=='fine' and ps[i-1]['k']==k for i,k in zip(ids,x)),'fine identities')
  valid=[ps[i-1]['status']=='SUCCESS' for i in ids]; y=[ps[i-1].get('aphys_ratio',float('nan')) for i in ids]
  if all(valid):
    winner=y.index(min(y)); ck(h['winner_index']==winner+1 and h['winner_point_id']==ids[winner] and h['interior']==(0<winner<10),'first actual argmin')
    ck([(d['first']-1,d['last']-1) for d in h['detection']['runs']]==detect(y),'fine dips retained')
  else: ck(h['decision']=='EVALUATION_FAILURE','failed round not ordinary dip')
  if h['decision']=='COMPLETE': ck(all(valid) and h['W']<=2e-14 and h['interior'],'complete gate')
for t in state['intervals']:
  ck(t['status'] not in ['RUNNING','PENDING'],'all source branches terminal')
  for child in seq(t['children']): ck(state['intervals'][child-1]['parent_id']==t['id'] and state['intervals'][child-1]['gap_id']==t['gap_id'],'branch lineage and gap')
for cand in state['candidates']:
  p=ps[cand['point_id']-1]; f=ps[cand['confirmation_id']-1]; ck(p['k']==f['k']==cand['k'] and p['resolution_id']==f['resolution_id']=='fine','candidate own fine confirmation')
  ck(f['bypass_cache'] and leads[f['lead_record_id']-1]['bypass'],'complete bypass two layers')
  if cand['status']=='COMPLETE':
    t=state['intervals'][cand['interval_id']-1]; h=state['history'][seq(t['history_ids'])[-1]-1]; ck(h['winner_point_id']==p['id'] and h['interior'] and cand['W']==h['W']<=2e-14,'formal final-round candidate')
  for name in ['adef_sigma','adef_ratio','aphys_sigma','aphys_ratio']: ck(cand[name]==p[name],'same-row metrics')
resources=list(csv.DictReader((root/'resources.csv').open())); status=json.loads((root/'status.json').read_text()); peak=max(int(r['rss_bytes']) for r in resources)
ck(peak==status['peak_rss_bytes'] and peak<3e9 and status['wall_seconds']<2400,'resource hard budget'); ck(all(r['external_matlab']=='[]' for r in resources) and not status['survivors'] and status['exit_code']==0,'serial clean exit')
details['classification']={'pairs':len(margins),'minimum_margin':min(margins),'maximum_qz_residual':max(residuals)}
details['counters']=c; details['lead_records']=len(leads); details['lead_cache_hits']=sum(r['action']=='CACHE_HIT' for r in leadlog['requests']); details['peak_rss_bytes']=peak

def norm(x): return float(np.linalg.norm(x))
def geom_expected(n,a,R):
  t=np.arange(n)*(2*np.pi/n); c=R/np.sqrt(1+a*a/2); r=c*(1+a*np.cos(3*t)); rp=-3*c*a*np.sin(3*t); rpp=-9*c*a*np.cos(3*t)
  return np.vstack((r*np.cos(t),rp*np.cos(t)-r*np.sin(t),(rpp-r)*np.cos(t)-2*rp*np.sin(t),r*np.sin(t),rp*np.sin(t)+r*np.cos(t),(rpp-r)*np.sin(t)+2*rp*np.cos(t)))
matrix_results=[]
for path in sorted(root.glob('candidate-evidence-*.mat')):
  raw=matload(path); p=raw['point']; e=raw['evidence']; lead=e['leads']; m=e['matching']; center=e['center']; gamma=np.asarray(lead['channels']['gamma_m']).reshape(-1); beta=np.asarray(lead['channels']['beta_m']).reshape(-1); K=len(gamma); G=np.diag(gamma); I=np.eye(K); zero=np.zeros((K,K)); dtn={}; direction={}; ge={}
  ck(K==97 and np.asarray(m['Aphys']).shape==(194,194),'matching matrix dimensions')
  for side,a,sgn in [('negative',.12,-1),('positive',.20,1)]:
    s=lead[side]; Z=np.asarray(s['Z']); n=int(scalar(s['ntot'])); C=np.asarray(s['geometry']); expected=geom_expected(n,a,.2); ge[side]=float(np.max(abs(C-expected)))
    ck(n==256 and abs(scalar(s['shape_arg'])-a)<1e-16 and ge[side]<5e-14,'analytic nonmirrored fine geometry')
    A=np.block([[-s['R_L'],I],[s['T_LR'],zero]]); B=np.block([[zero,s['T_RL']],[I,-s['R_R']]])
    lhs,rhs=(A@Z,B@Z) if side=='positive' else (B@Z,A@Z)
    H,_,rank,_=np.linalg.lstsq(rhs,lhs,rcond=None); defect=norm(lhs-rhs@H)/max(1,norm(lhs),norm(rhs)*norm(H)); radius=float(max(abs(np.linalg.eigvals(H))))
    ck(norm(Z.conj().T@Z-I)<1e-10 and defect<1e-10,'correct deflating subspace')
    if rank==K: ck(radius<1+1e-6,'chosen direction decays')
    direction[side]={'rank':int(rank),'deflating_relative_residual':defect,'reduced_multiplier_radius':radius}
    D=Z[:K]+Z[K:]; N=sgn*1j*G@(Z[:K]-Z[K:]); L=np.linalg.solve(D.T,N.T).T; dtn[side]=L
    ck(norm(L@D-N)/max(1,norm(N))<1e-10,'independent DtN residual')
  Lm,Lp=dtn['negative'],dtn['positive']; L=np.block([[Lm,zero],[zero,Lp]])
  T=np.block([[I+center['R_L'],center['T_RL']],[center['T_LR'],I+center['R_R']]])
  N=np.block([[1j*G@(center['R_L']-I),1j*G@center['T_RL']],[1j*G@center['T_LR'],1j*G@(center['R_R']-I)]])
  Adef=N-L@T; b=np.sqrt(1+abs(beta)**2); row=np.tile(np.sqrt(1/b),2); col=np.tile(1/np.sqrt(b+abs(gamma)**2/b),2); Aphys=row[:,None]*Adef*col[None,:]
  ck(rel(T,m['T'])<1e-12 and rel(N,m['N0'])<1e-12 and rel(L,m['L'])<1e-12,'independent trace and DtN blocks')
  adiff=rel(Adef,m['Adef']); pdiff=rel(Aphys,m['Aphys']); ck(adiff<1e-12 and pdiff<1e-12,'independent matching reconstruction')
  # SVD the stored matrix, so algebraic reconstruction error is separate.
  sd=np.linalg.svd(m['Adef'],compute_uv=False); sp=np.linalg.svd(m['Aphys'],compute_uv=False)
  vals={'adef_sigma':float(sd[-1]),'adef_ratio':float(sd[-1]/sd[0]),'aphys_sigma':float(sp[-1]),'aphys_ratio':float(sp[-1]/sp[0])}; differences={}
  for name,value in vals.items():
    differences[name]=abs(value-scalar(p[name])); scale=sd[0] if name=='adef_sigma' else sp[0] if name=='aphys_sigma' else 1
    ck(differences[name]<=128*np.finfo(float).eps*max(1,float(scale)),'independent SVD ordinary-roundoff check')
  Sn=np.block([[lead['negative']['R_L'],lead['negative']['T_RL']],[lead['negative']['T_LR'],lead['negative']['R_R']]])
  Sp=np.block([[lead['positive']['R_L'],lead['positive']['T_RL']],[lead['positive']['T_LR'],lead['positive']['R_R']]])
  ck(norm(Sn-Sp)>1e-8,'genuinely distinct side scattering')
  ck(np.asarray(center['geometry']).shape==(6,512),'fine center size')
  matrix_results.append({'file':path.name,'k':scalar(p['k']),'geometry_max_absolute':ge,'direction_checks':direction,'Adef_relative_reassembly':adiff,'Aphys_relative_reassembly':pdiff,'SVD_values':vals,'SVD_absolute_differences':differences,'two_lead_S_absolute_difference':norm(Sn-Sp)})
ck(len(matrix_results)==len(state['confirmations']),'all confirmations have matrix evidence')
equal=matload(root/'equal-lead-validation.mat')['evidence']; ck(norm(equal['reference']['Adef']-equal['independent']['Adef'])<1e-10 and norm(equal['reference']['Aphys']-equal['independent']['Aphys'])<1e-10,'same-lead degeneration raw matrices')
details['matrices']=matrix_results; details['checks']=checks; details['status']='PASS'; details['audit_seconds']=time.perf_counter()-audit_start; details['numpy_version']=np.__version__; details['python']=sys.version.split()[0]
print(json.dumps(details,indent=2,allow_nan=False))
