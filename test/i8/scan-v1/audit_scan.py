"""Independently audit current I8.5 search records and final matching matrices.

Based on: the MAT-v7 reader in pipeline-v1/skeptic_audit.py, copied locally.
Main changes: search-only audit designed by the independent I8.5 Skeptic.
Uses only standard Python and an existing NumPy installation. This post-run
review program is not a prerequisite of the MATLAB search and reads only the
explicit current-run directory supplied on the command line.
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
root=Path(sys.argv[1]); state=json.loads((root/'state.json').read_text()); cfg=state['config']; ps=state['points']; requests=state['requests']; checks=0

def ck(test,label):
  global checks
  checks+=1
  if not test: raise AssertionError(label)

def seq(x):
  return x if isinstance(x,list) else [x]

def detect(y):
  runs=[]; j=0
  while j<len(y):
    z=j
    while z+1<len(y) and y[z+1]==y[j]: z+=1
    if j>0 and z+1<len(y) and y[j]<y[j-1] and y[z]<y[z+1]: runs.append((j,z))
    j=z+1
  return runs
ck(cfg['resolutions']=={'coarse':{'center_ntot':256,'lead_ntot':128},'fine':{'center_ntot':512,'lead_ntot':256}},'resolutions')
ck(cfg['backend']['fmm_eps']==1e-12,'FMM eps')
ck(cfg['search']['candidate_rule']=='first_final_round_min','candidate rule')
seen={}; hit_count=0; bypass_count=0
for r in requests:
  p=ps[r['point_id']-1]; key=p['key']
  ck(p['status']=='SUCCESS','point success')
  ck(p['k_hex']==struct.pack('>d',p['k']).hex(),'binary64 hex')
  ck(key==state['config_key']+'|'+p['resolution_id']+'|'+p['k_hex'],'full config cache key')
  ck(p['k']==r['k'] and p['k_hex']==r['k_hex'] and p['resolution_id']==r['resolution_id'],'request identity')
  if r['action']=='CACHE_HIT':
    ck(key in seen and seen[key]==r['point_id'] and not r['bypass_cache'],'earliest exact cache hit'); hit_count+=1
  else:
    ck(r['action']=='COMPUTED','request action')
    ck(r['bypass_cache'] or key not in seen,'no duplicate uncached calculation')
    if r['bypass_cache']: bypass_count+=1
    else: seen[key]=r['point_id']
for p in ps:
  calls=p['proxy_calls']; ck(len(calls)==2,'two cell callbacks')
  ck([x['nt'] for x in calls]==([16384,65536] if p['resolution_id']=='coarse' else [65536,262144]),'actual resolution target sizes')
  for x in calls: ck(x['ns']==320 and x['method']=='fmm' and x['batches']==1 and x['ier']==0,'FMM callback')
  ck(all(math.isfinite(p[f]) and p[f]>=0 for f in ['adef_sigma','adef_ratio','aphys_sigma','aphys_ratio']),'four finite metrics')
c=state['counters'];ck(c['requested']==len(requests)==len(ps)+hit_count,'request accounting');ck(c['computed']==len(ps) and c['cache_hits']==hit_count and c['confirmation']==bypass_count,'counter accounting')
coarse=seq(state['coarse_point_ids']); x=state['coarse_grid']; y=[ps[i-1]['aphys_ratio'] for i in coarse]
ck(len(x)==33 and all(k==1.45+j*.025 for j,k in enumerate(x)),'full original coarse grid')
runs=detect(y);ck([(d['first']-1,d['last']-1) for d in state['coarse_dips']]==runs,'all coarse interior dips')
for d,(a,b) in zip(state['coarse_dips'],runs):
  t=state['intervals'][d['interval_id']-1]
  ck(t['initial_bounds']==[x[max(0,a-2)],x[min(32,b+2)]],'expanded fine entry')
  ck(d['id'] in seq(t['source_ids']) and t['resolution_id']=='fine','source lineage')
for h in state['history']:
  k=h['k']; ids=h['point_ids']; y=[ps[i-1]['aphys_ratio'] for i in ids]; winner=y.index(min(y)); runs=detect(y)
  ck(len(k)==11 and all(a<b for a,b in zip(k,k[1:])),'eleven strictly increasing actual nodes')
  ck(all(ps[i-1]['resolution_id']=='fine' and ps[i-1]['k']==z for i,z in zip(ids,k)),'fine row identity')
  ck(h['W']==k[-1]-k[0] and h['min_spacing']==min(b-a for a,b in zip(k,k[1:])) and h['max_spacing']==max(b-a for a,b in zip(k,k[1:])),'actual widths')
  ck(h['winner_index']==winner+1 and h['winner_point_id']==ids[winner] and h['interior']==(0<winner<10),'first argmin')
  dr=h['detection'];ck([(d['first']-1,d['last']-1) for d in dr['runs']]==runs,'all fine dips')
  tau=64*sys.float_info.epsilon*max([1]+[abs(z) for z in y]);ck(dr['ambiguity_threshold']==tau,'ambiguity threshold')
  groups=[]
  for j,(a,b) in enumerate(runs):
    if j==0: groups.append([1]);continue
    pa,pb=runs[j-1]; saddle=max(y[pb:a+1]); separate=saddle-y[pa]>tau and saddle-y[a]>tau
    if separate: groups.append([j+1])
    else: groups[-1].append(j+1)
  ck([seq(g) for g in dr['groups']]==groups,'all distinguishable fine groups')
  if h['decision']=='COMPLETE': ck(h['interior'] and h['W']<=2e-14 and len(groups)<=1,'width completion gate')
  if h['decision']=='REFINE_FULL_CLUSTER':
    task=state['intervals'][h['interval_id']-1]; hs=seq(task['history_ids']); pos=hs.index(h['id'])
    if pos+1<len(hs):
      nex=state['history'][hs[pos+1]-1]; a,b=runs[0][0],runs[-1][1]
      ck([nex['k'][0],nex['k'][-1]]==[k[a-1],k[b+1]],'full cluster next bracket')
for t in state['intervals']:
  ck(t['status'] not in ['PENDING','RUNNING'],'all tasks terminal')
  if t['status']=='SPLIT': ck(len(seq(t['children']))>=2,'all split children registered')
  for child in seq(t['children']): ck(state['intervals'][child-1]['parent_id']==t['id'],'child parent identity')
for cand in state['candidates']:
  p=ps[cand['point_id']-1]; q=ps[cand['confirmation_id']-1]; task=state['intervals'][cand['interval_id']-1]
  ck(p['resolution_id']==q['resolution_id']=='fine' and p['k']==q['k']==cand['k'],'own fine confirmation')
  ck(q['bypass_cache'] and q['id']!=p['id'],'confirmation bypass')
  if cand['status']=='COMPLETE':
    h=state['history'][seq(task['history_ids'])[-1]-1]
    ck(h['winner_point_id']==p['id'] and h['W']==cand['W'] and h['W']<=2e-14 and h['interior'],'final bracket candidate')
  for f in ['adef_sigma','adef_ratio','aphys_sigma','aphys_ratio']: ck(cand[f]==p[f],'candidate four-metric row identity')
resources=list(csv.DictReader((root/'resources.csv').open())); status=json.loads((root/'status.json').read_text())
peak=max(int(r['rss_bytes']) for r in resources)
ck(peak==status['peak_rss_bytes'] and peak<cfg['resources']['rss_bytes'],'sampled RSS ledger')
ck(all(r['external_matlab']=='[]' for r in resources),'serial MATLAB')
ck(status['survivors']==[] and status['exit_code']==0 and status['wall_seconds']<cfg['resources']['hard_seconds'],'exit and hard budget')
ck(all(float(a['elapsed_seconds'])<=float(b['elapsed_seconds']) for a,b in zip(resources,resources[1:])),'monotonic resource times')
for stage in ['coarse','fine','confirmation']:
  values=[p['seconds'] for p in ps if ('confirmation' if p['bypass_cache'] else p['resolution_id'])==stage]
  ck(math.isclose(sum(values),state['timing'][stage],rel_tol=1e-14,abs_tol=1e-10),'exclusive point-stage timing')
matrix_audits=[]
for cand in state['candidates']:
  data=matload(root/('candidate-evidence-%04d.mat'%cand['confirmation_id'])); e=data['evidence']; p=data['point']; m=e['matching']; center=e['center']; lead=e['lead']; gamma=np.asarray(e['gamma']); beta=np.asarray(e['beta_m']); K=len(gamma); G=np.diag(gamma); I=np.eye(K)
  ck(center['i8_geometry'].shape==(6,512) and lead['i8_geometry'].shape==(6,256),'raw fine geometry shapes')
  zp=e['Zplus']; zm=e['Zminus']; ap=zp[:K];bp=zp[K:];am=zm[:K];bm=zm[K:]
  lp=np.linalg.solve((ap+bp).T,(1j*G@(ap-bp)).T).T
  lm=np.linalg.solve((am+bm).T,(-1j*G@(am-bm)).T).T
  T=np.block([[I+center['R_L'],center['T_RL']],[center['T_LR'],I+center['R_R']]])
  N=np.block([[1j*G@(center['R_L']-I),1j*G@center['T_RL']],[1j*G@center['T_LR'],1j*G@(center['R_R']-I)]])
  A=np.block([[(1j*G-lm)@center['R_L']-(1j*G+lm),(1j*G-lm)@center['T_RL']],[(1j*G-lp)@center['T_LR'],(1j*G-lp)@center['R_R']-(1j*G+lp)]])
  b=np.sqrt(1+abs(beta)**2); rw=np.tile(np.sqrt(1/b),2);cw=np.tile(1/np.sqrt(b+abs(gamma)**2/b),2); P=rw[:,None]*A*cw[None,:]
  saved_a=np.linalg.svd(m['Adef'],compute_uv=False);saved_p=np.linalg.svd(m['Aphys'],compute_uv=False)
  diffs={f:abs(float(p[f])-float(v)) for f,v in zip(['adef_sigma','adef_ratio','aphys_sigma','aphys_ratio'],[saved_a[-1],saved_a[-1]/saved_a[0],saved_p[-1],saved_p[-1]/saved_p[0]])}
  rebuilt={'Adef_relative_frobenius':rel(A,m['Adef']),'Aphys_relative_frobenius':rel(P,m['Aphys']),'T_relative_frobenius':rel(T,m['T']),'N0_relative_frobenius':rel(N,m['N0']),'Lp_relative_frobenius':rel(lp,m['Lp']),'Lm_relative_frobenius':rel(lm,m['Lm'])}
  ck(all(v<1e-12 for v in rebuilt.values()),'independent matching formula reconstruction')
  ck(m['Adef'].shape==(194,194) and m['Aphys'].shape==(194,194),'raw matching dimensions')
  ck(float(p['k'])==cand['k'],'raw evidence candidate identity')
  raw_saved={f:float(p[f]) for f in diffs}; ck(all(raw_saved[f]==ps[cand['confirmation_id']-1][f] for f in diffs),'raw MAT/JSON metrics identity')
  q=np.asarray(e['q']); qnorm=float(np.linalg.norm(q)); residual=float(np.linalg.norm(m['Adef']@q))
  matrix_audits.append({'interval_id':cand['interval_id'],'k':cand['k'],'reconstruction':rebuilt,'independent_SVD_absolute_differences':diffs,'q_norm':qnorm,'residual_norm':residual,'MATLAB_metrics':raw_saved})
  del data,e,m,center,lead
report={'status':'PASS','checks':checks,'run_status':state['status'],'counters':state['counters'],'unique_k':{res:len({p['k_hex'] for p in ps if p['resolution_id']==res}) for res in ['coarse','fine']},'coarse_internal_dips':len(state['coarse_dips']),'coarse_edge_indices':state['coarse_detection']['edge_indices'],'interval_statuses':[{'id':t['id'],'kind':t['kind'],'status':t['status'],'round':t['round']} for t in state['intervals']],'pending_edges':state['pending_edge_count'],'candidates':state['candidates'],'matrix_audits':matrix_audits,'timing':state['timing'],'process_wall_seconds':status['wall_seconds'],'peak_rss_bytes':peak,'independence':'Python post-run reconstruction only; no MATLAB launch or new physical evaluations'}
print(json.dumps(report,indent=2,allow_nan=False))

