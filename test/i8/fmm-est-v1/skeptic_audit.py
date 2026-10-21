"""Read raw MATLAB v7 evidence and independently reassemble I8.4b quantities.

Purpose: reproduce the Skeptic's raw-matrix and scalar audit without MATLAB.
Uses only the standard library and an already available NumPy installation.
The numerical experiment does not depend on this post-run review program.
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


def lvl_audit(ca, la, ls, cm, lm, wl, mass, prop, model, saved):
  n = int(scalar(ca['source_nodes']))
  w = ca['weights']; sc = ca['density_scale']; eta = ca['density']
  raw = (ca['A_scaled'] @ (sc * eta)) / sc + ca['Bq']
  cv = sq(ca['signed_value'], w); cn = sq(ca['signed_normal'], w)
  lraw = (la['A_scaled'] @ (la['density_scale'][:, None] * la['density_map'])) / la['density_scale'][:, None] + la['B']
  av = la['signed_value_action']; an = la['signed_normal_action']; lw = la['weights']
  pp, pm = prop['Pplus'], prop['Pminus']
  gp, gm = prop['Gplus'], prop['Gminus']
  cp = prop['cplus'].copy(); cnc = prop['cminus'].copy()
  lr = []; wr = []; wgt = scalar(model['d']) / n
  for i in range(41):
    xp = gp @ cp; xm = gm @ cnc
    lr.append([sq(av @ xp, lw) + sq(av @ xm, lw), sq(an @ xp, lw) + sq(an @ xm, lw)])
    cpn = pp @ cp; cmn = pm @ cnc; xpn = gp @ cpn; xmn = gm @ cmn
    vp = lm['left_value'] @ xpn - lm['right_value'] @ xp
    np_ = lm['right_dx'] @ xp - lm['left_dx'] @ xpn
    vm = lm['right_value'] @ xmn - lm['left_value'] @ xm
    nm = lm['right_dx'] @ xmn - lm['left_dx'] @ xm
    wr.append([wgt * (np.vdot(vp, vp).real + np.vdot(vm, vm).real),
               wgt * (np.vdot(np_, np_).real + np.vdot(nm, nm).real)])
    cp = cpn; cnc = cmn
  lr = np.array(lr); wr = np.array(wr)
  lratio = lr[40] / lr[39]; wratio = wr[40] / wr[39]
  ltail = lr[40] / (1 - lratio); wtail = wr[40] / (1 - wratio)
  wc = np.array([
      wgt * (np.vdot(wl['center_lead_value_left'], wl['center_lead_value_left']).real + np.vdot(wl['center_lead_value_right'], wl['center_lead_value_right']).real),
      wgt * (np.vdot(wl['center_lead_dx_left'], wl['center_lead_dx_left']).real + np.vdot(wl['center_lead_dx_right'], wl['center_lead_dx_right']).real)])
  lsave = np.array([[scalar(x['value_squared']), scalar(x['normal_squared'])] for x in ls['cells']])
  wsave = np.array([[scalar(x['value_squared']), scalar(x['normal_squared'])] for x in wl['internal_rows']])
  lsave_tail = np.array([scalar(ls['tail_value_squared_candidate']), scalar(ls['tail_normal_squared_candidate'])])
  wsave_tail = np.array([scalar(wl['tail_value_squared_candidate']), scalar(wl['tail_normal_squared_candidate'])])
  totals = np.array([cv, cn]) + lsave.sum(0) + lsave_tail + wc + wsave.sum(0) + wsave_tail
  u = math.sqrt(math.pi * scalar(mass['radius'])**2 * np.mean(abs(mass['sample_values'])**2))
  ep = math.sqrt(totals[1] + totals[0] / scalar(model['d'])**2)
  return {
      'center_value_sq': cv, 'center_normal_sq': cn, 'Ev': totals[0], 'En': totals[1], 'epsilon': ep, 'U': u,
      'center_raw_rel': rel(raw, ca['raw_action']), 'center_raw_absmax': float(np.max(abs(raw - ca['raw_action']))),
      'center_raw_norm_sq': sq(raw[n:], w), 'lead_raw_absmax': float(max(np.max(abs(lraw[:n] - av)), np.max(abs(lraw[n:] + an)))),
      'lead_rows_rel': rel(lr[:40], lsave), 'wall_rows_rel': rel(wr[:40], wsave),
      'lead_tail_ratios': lratio.tolist(), 'wall_tail_ratios': wratio.tolist(),
      'lead_tail_rel': rel(ltail, lsave_tail), 'wall_tail_rel': rel(wtail, wsave_tail),
      'components_Ev_rel': rel(totals[0], saved['components']['value_squared']),
      'components_En_rel': rel(totals[1], saved['components']['normal_squared'])}


path = sys.argv[1]
D = matload(path); r = D['result']; e = D['evidence']
b = e['base']; p = e['propagation']; mod = r['model']; out = {}
K = 97; Zp = b['Zplus']; Zm = b['Zminus']
Ap = Zp[:K]; Bp = Zp[K:]; Am = Zm[:K]; Bm = Zm[K:]
G = np.diag(b['gamma']); I = np.eye(K); c = b['center']
Lp = np.linalg.solve((Ap + Bp).T, (1j * G @ (Ap - Bp)).T).T
Lm = np.linalg.solve((Am + Bm).T, (-1j * G @ (Am - Bm)).T).T
T = np.block([[I + c['R_L'], c['T_RL']], [c['T_LR'], I + c['R_R']]])
N0 = np.block([[1j * G @ (c['R_L'] - I), 1j * G @ c['T_RL']],
               [1j * G @ c['T_LR'], 1j * G @ (c['R_R'] - I)]])
Ad = np.block([[(1j * G - Lm) @ c['R_L'] - (1j * G + Lm), (1j * G - Lm) @ c['T_RL']],
               [(1j * G - Lp) @ c['T_LR'], (1j * G - Lp) @ c['R_R'] - (1j * G + Lp)]])
bb = np.sqrt(1 + abs(b['beta_m'])**2)
rw = np.tile(1 / np.sqrt(bb), 2)
cw = np.tile(1 / np.sqrt(bb + abs(b['gamma'])**2 / bb), 2)
Aph = rw[:, None] * Ad * cw[None, :]; saved = b['matching']
out['matrix_rebuild'] = {x: rel(a, saved[x]) for x, a in [('T', T), ('N0', N0), ('Adef', Ad), ('Aphys', Aph)]}
out['metrics'] = {}
for name in ['Adef', 'Aphys']:
  ss = np.linalg.svd(saved[name], compute_uv=False)
  out['metrics'][name] = {'sigma': float(ss[-1]), 'ratio': float(ss[-1] / ss[0]), 'norm': float(ss[0])}
_, _, vh = np.linalg.svd(saved['Aphys'], full_matrices=False)
qa = cw * vh[-1].conj(); qa /= np.linalg.norm(qa)
out['q_subspace_defect'] = float(abs(1 - abs(np.vdot(qa, b['q'])) / np.linalg.norm(b['q'])))


def interpft(a, m):
  if m == a.shape[0]:
    return a.copy()
  n = a.shape[0]; F = np.fft.fft(a, axis=0); j = n // 2
  Z = np.zeros((m,) + a.shape[1:], complex)
  Z[:j] = F[:j]; Z[-j + 1:] = F[j + 1:]; Z[j] = F[j] / 2; Z[m - j] = F[j] / 2
  return np.fft.ifft(Z, axis=0) * (m / n)


def interp_density(a, m):
  n = a.shape[0] // 2
  return np.concatenate([interpft(a[:n], m), interpft(a[n:], m)])


out['interp_density'] = {str(i): rel(interp_density(e['center_density'], int(r['levels'][i]['nodes'])), e['center_actions'][i]['density']) for i in range(2)}
out['normalization'] = {'qnorm': float(np.linalg.norm(b['q'])), 'density_rel': rel(c['H_L'] @ b['q'][:K] + c['H_R'] @ b['q'][K:], e['center_density'])}
mu = scalar(mod['khat'])**2; theta = scalar(r['geometry']['theta']); h = scalar(mod['collar_h'])
c0 = 1 / (theta * h); c1 = h / (2 * theta)
C = math.sqrt(c0 / (scalar(mod['rho_exterior']) * mu**2) + (c1 + c0) / (4 * mu) + c1 * scalar(mod['rho_lead']))
out['mu'] = mu; out['C'] = C
for i in range(2):
  a = lvl_audit(e['center_actions'][i], e['lead_actions'][i], e['lead_sums'][i], e['center_maps'][i], e['lead_maps'][i], e['wall_levels'][i], e['mass'][i], p, mod, r['levels'][i])
  a['Q'] = C * a['epsilon']; a['D'] = a['U'] - a['Q']; a['R'] = 2 * mu * a['Q'] / a['D']
  out['fmm' + str(int(r['levels'][i]['nodes']))] = a
dd = e['direct']
a = lvl_audit(dd['center_action'], dd['lead_action'], dd['lead_sum'], dd['center_maps'], dd['lead_maps'], dd['wall'], dd['mass'], p, mod, r['direct'])
a['Q'] = C * a['epsilon']; a['D'] = a['U'] - a['Q']; a['R'] = 2 * mu * a['Q'] / a['D']; out['direct768'] = a
out['frozen_arrays'] = {key: bool(np.array_equal(e['center_actions'][1][key], dd['center_action'][key])) for key in ['density', 'density_scale', 'Bq', 'weights']}
out['frozen_lead'] = {key: bool(np.array_equal(e['lead_actions'][1][key], dd['lead_action'][key])) for key in ['density_map', 'density_scale', 'B', 'weights']}
out['comparison'] = {key: {'abs': abs(out['fmm768'][key] - out['direct768'][key]), 'relative': rel(out['fmm768'][key], out['direct768'][key])} for key in ['epsilon', 'U', 'Q', 'D', 'R']}
usage = resource.getrusage(resource.RUSAGE_SELF)
out['audit_runtime'] = {
    'python': sys.version, 'executable': sys.executable, 'numpy': np.__version__,
    'platform': platform.platform(), 'wall_seconds': time.perf_counter() - audit_start,
    'user_seconds': usage.ru_utime, 'system_seconds': usage.ru_stime,
    'peak_rss_raw': usage.ru_maxrss,
    'peak_rss_units': 'bytes' if sys.platform == 'darwin' else 'KiB',
    'scope': 'post-run Python process, not MATLAB process-tree monitoring'}
print(json.dumps(out, indent=2))
