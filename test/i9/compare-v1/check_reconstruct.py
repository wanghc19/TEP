"""Main-agent self-check of this run's frozen BIE field and numerical scalars.
Only the MAT-v7 reader is adapted from I9.2 audit_estimate.py. Checks below
are local to I9.3; this is not an independent reviewer or a new physical solve.
Requires existing NumPy; never reads old results, calls MATLAB or changes k.
"""
import json
import math
import struct
import sys
import time
import zlib
from pathlib import Path
import numpy as np

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



def check_run(directory):
  started = time.perf_counter()
  data = matload(directory/'evidence.mat')
  r, e, cfg = data['result'], data['evidence'], data['config']
  b, p = e['base'], e['propagation']
  checks, differences, details = [], {}, {}

  def ck(value, label):
    checks.append(label)
    if not value:
      raise AssertionError(label)

  def compare(a, expected, label, atol=1e-12, rtol=1e-10):
    a, expected = np.asarray(a), np.asarray(expected)
    difference = float(np.max(abs(a-expected)))
    scale = float(np.max(abs(expected)))
    differences[label] = dict(absolute=difference, relative=difference/max(scale, 1e-300))
    ck(np.all(np.isfinite(a)) and difference <= atol+rtol*scale, label)

  k = float(cfg['k0']); model = cfg['model']; ev = cfg['evaluation']; d = cfg['discretization']
  ck(k == 1.5584630910866906, 'explicit unchanged FEM candidate')
  for name, value in {'beta':.5, 'd':1, 'L':1, 'star_scale':1, 'rho_center':4,
      'rho_lead':17, 'rho_exterior':1, 'a_negative':.12, 'a_positive':.20,
      'collar_h':.004, 'arc_band':.01, 'overlap_count':1}.items():
    ck(float(model[name]) == value, 'model '+name)
  for name, value in {'ntot_center':512, 'ntot_negative':256, 'ntot_positive':256,
      'M':48, 'K':97, 'nside':160, 'ntop':160, 'nproxy':80, 'mpw':32}.items():
    ck(int(d[name]) == value, 'discretization '+name)
  for name, value in {'material_nodes':768, 'wall_nodes':768, 'lead_cells':40,
      'wall_batch':64, 'mass_batch':32, 'disk_shift':.5}.items():
    ck(float(ev[name]) == value, 'evaluation '+name)
  ck(np.array_equal(ev['disk_grid'], [32,64]) and
    np.array_equal(model['disk_center'], [0,.375]) and model['disk_radius']==1/16, 'local mass region')
  ck(np.array_equal(model['geometry_nodes'], [4096,8192]), 'same geometry sampling')
  ck(cfg['backend']['fmm_eps']==1e-12 and cfg['backend']['threads']==11, 'FMM settings')
  q=b['q']; match=b['matching']; K=int(d['K'])
  compare(np.linalg.norm(q),1,'q normalization')
  anchor=int(r['point']['phase_anchor_index'])-1
  ck(np.argmax(abs(q))==anchor and q[anchor].real>0 and abs(q[anchor].imag)<1e-12, 'phase anchor')
  for side, n in [('center',512),('negative',256),('positive',256)]:
    cell=b[side]; H=np.column_stack([cell['H_L'],cell['H_R']])
    ck(H.shape==(2*n,2*K), 'density dimensions '+side)
    compare(cell['kext'], k, 'exterior k '+side, 0, 0)
    compare(cell['kint'], math.sqrt(4 if side=='center' else 17)*k, 'interior k '+side, 0, 0)
    scale=np.sqrt(np.tile(cell['far_aux']['weights'],2))
    rhs=np.column_stack([cell['B_L'],cell['B_R']])*scale[:,None]
    residual=np.linalg.norm(cell['A_QP']@(scale[:,None]*H)+rhs)/max(1,np.linalg.norm(rhs))
    ck(residual<1e-10, 'physical BIE solve '+side);details[side+'_BIE_residual']=float(residual)
    if side=='center': compare(H@q,e['center_density'],'one frozen center density')
    else:
      suffix='minus' if side=='negative' else 'plus'
      compare(H@p['G'+suffix],e['lead_'+suffix], 'one frozen lead density map '+side)
      A,B=cell['A'],cell['B'];Z=cell['Z'];P=p['P'+suffix]
      if side=='negative': A,B=B,A
      rec=np.linalg.norm(A@Z-B@Z@P)/max(1,np.linalg.norm(A@Z)+np.linalg.norm(B@Z@P))
      ck(rec<1e-10,'decay recurrence '+side)
      for key in (['qz','reverse_qz'] if side=='negative' else ['qz']):
        diag=cell[key]; aa=abs(diag['alpha_real']+1j*diag['alpha_imag']); bb=abs(diag['theta_real']+1j*diag['theta_imag'])
        sc=np.hypot(aa,bb); a=aa/sc; z=bb/sc; outer=float(diag['outer'])
        ck(np.isfinite(sc).all() and np.sum(a<z-outer)==K and np.sum(a>z+outer)==K and diag['status']=='GAP', 'raw decay classification '+side+' '+key)
  compare(match['Adef'],match['N0']-match['L']@match['T'],'matching assembly',1e-10)
  compare(match['Aphys'],match['row_weight'][:,None]*match['Adef']*match['column_weight'][None,:], 'physical weights')
  for name, prefix in [('Adef','adef'),('Aphys','aphys')]:
    ss=np.linalg.svd(match[name],compute_uv=False)
    compare(ss[-1],r['point'][prefix+'_sigma'],'metric sigma '+prefix)
    compare(ss[-1]/ss[0],r['point'][prefix+'_ratio'],'metric ratio '+prefix)
  v=q/match['column_weight'];v=v/np.linalg.norm(v)
  compare(np.linalg.norm(match['Aphys']@v),r['point']['aphys_sigma'],'smallest singular vector use')

  def sq(value, weight): return float(np.sum(abs(value)**2*weight).real)
  def series(action,G,P,c,saved,label):
    rows=[];c=c.copy()
    for _ in range(41):
      state=G@c
      rows.append([sq(action['signed_value_action']@state,action['weights']),
        sq(action['signed_normal_action']@state,action['weights'])])
      c=P@c
    rows=np.asarray(rows); ratio=rows[40]/np.maximum(rows[39],np.finfo(float).tiny)
    ck(np.isfinite(ratio).all() and np.all((ratio>=0)&(ratio<1)),label+' tail applicability')
    finite=rows[:40].sum(0);tail=rows[40]/(1-ratio)
    compare(rows[:40],[[a['value_squared'],a['normal_squared']] for a in saved['cells']],label+' finite prefix',1e-35)
    compare(tail,[saved['tail_value_squared_candidate'],saved['tail_normal_squared_candidate']],label+' tail',1e-90)
    details[label]=dict(finite=finite.tolist(),tail=tail.tolist(),ratio=ratio.tolist())
    return finite+tail
  ca=e['center_action'];raw=ca['A_scaled']@(ca['density_scale']*ca['density'])/ca['density_scale']+ca['Bq']
  compare(raw,ca['raw_action'],'center material raw action')
  total=np.array([sq(ca['signed_value'],ca['weights']),sq(ca['signed_normal'],ca['weights'])])
  details['center_material']=total.tolist()
  for side,suffix in [('negative','minus'),('positive','plus')]:
    total+=series(e[side+'_action'],p['G'+suffix],p['P'+suffix],p['c'+suffix],e[side+'_sum'],side+'_material')
  w=e['walls'];cm=e['center_maps'];nm=e['negative_maps'];pm=e['positive_maps']
  xm=p['Gminus']@p['cminus'];xp=p['Gplus']@p['cplus']
  pairs=[('left',nm['right_value']@xm-cm['left_value'],nm['right_dx']@xm-cm['left_dx']),
    ('right',pm['left_value']@xp-cm['right_value'],cm['right_dx']-pm['left_dx']@xp)]
  for name,value,normal in pairs:
    compare(value,w[name]['value'],name+' junction values')
    compare(normal,w[name]['normal'],name+' junction normals')
    saved=np.array([sq(w[name]['value'],1/768),sq(w[name]['normal'],1/768)])
    total+=saved;details[name+'_junction']=saved.tolist()
  for side,suffix in [('negative','minus'),('positive','plus')]:
    total+=series(w[side+'_action'],np.eye(K),p['P'+suffix],p['c'+suffix],w[side],side+'_walls')
  compare(total,[r['components']['value_squared'],r['components']['normal_squared']], 'complete jump sum',1e-35)
  ck(not e['periodic']['included_in_epsilon'], 'periodic diagnostic excluded consistently')
  details['periodic']={name:{a:float(e['periodic'][name][a]) for a in ['value_squared','normal_squared']} for name in ['center','negative','positive']}
  mu=k*k;geometry=r['geometry'];theta=min(float(geometry[s]['theta']) for s in ['center','negative','positive'])
  h=float(model['collar_h']);c0=1/(theta*h);c1=h/(2*theta)
  C=math.sqrt(c0/(mu*mu)+(c1+c0)/(4*mu)+17*c1)
  epsilon=math.sqrt(total[1]+total[0]);mass=e['mass'];U=math.sqrt(math.pi*float(mass['radius'])**2*np.mean(abs(mass['sample_values'])**2))
  Q=C*epsilon;den=U-Q
  ck(den>0,'positive denominator')
  scalars=dict(mu_num=mu,C_num=C,epsilon_num=epsilon,U_num=U,Q_num=Q,denominator=den,R_num=2*mu*Q/den)
  for name,value in scalars.items(): compare(value,r[name],'scalar '+name,0,1e-10)
  ck(bool(r['geometry']['pass']) and bool(r['audit']['pass']) and bool(r['components']['complete']), 'geometry and fixed field checks')
  ck(all(x['ier']==0 for x in r['proxy_calls']),'all FMM return codes')
  status=json.loads((directory/'status.json').read_text())
  ck(status['exit_code']==0 and not status['survivors'] and status['peak_rss_bytes']<3e9 and status['wall_seconds']<2400,'process limits and cleanup')
  import csv
  resources=list(csv.DictReader((directory/'resources.csv').open()))
  ck(max(int(x['rss_bytes']) for x in resources)==status['peak_rss_bytes'] and all(x['external_matlab']=='[]' for x in resources),'resource samples')
  return dict(status='PASS',review_type='MAIN_AGENT_SELF_CHECK_ONLY',checks=len(checks),scalars=scalars,
    differences=differences,details=details,seconds=time.perf_counter()-started,numpy=np.__version__)

if __name__=='__main__':
  print(json.dumps(check_run(Path(sys.argv[1])),indent=2,allow_nan=False))
