"""Reassemble current raw matrices to diagnose operation-order sensitivity.

Purpose: audit cancellation in the two saved independent fields without MATLAB.
Based on: this directory's MAT reader and independent raw-ledger audit helpers.
Main changes: recompute material actions and every finite/tail wall contraction.
Saved C and U are retained. This is not a replacement estimator or certification.
"""
from pathlib import Path
import sys, json, gc, time, resource

start = time.perf_counter()
ns = {}
source = (Path(__file__).parent/'skeptic_audit.py').read_text()
exec(compile(source.split('\nroot = Path(sys.argv[1])')[0], '<current-audit-definitions>', 'exec'), ns)
np = ns['np']; scalar = ns['scalar']; sq = ns['sq']; rel = ns['rel']
root = Path(sys.argv[1]); outputs = {}


def one(backend):
  D = ns['matload'](root/backend/'estimate/scientific.mat'); e = D['evidence']; r = D['result']
  ca = e['center_actions'][0]; la = e['lead_actions'][0]; lm = e['lead_maps']; cm = e['center_maps']; prop = e['propagation']
  n = int(scalar(ca['source_nodes'])); w = ca['weights']; wt = scalar(e['base']['model']['d'])/n
  cr = (ca['A_scaled']@(ca['density_scale']*ca['density']))/ca['density_scale']+ca['Bq']
  lr = (la['A_scaled']@(la['density_scale'][:, None]*la['density_map']))/la['density_scale'][:, None]+la['B']; av = lr[:n]; an = -lr[n:]
  pp = prop['Pplus']; pm = prop['Pminus']; gp = prop['Gplus']; gm = prop['Gminus']; cp = prop['cplus'].copy(); cn = prop['cminus'].copy(); lead = []; wall = []
  vp = lm['right_value']@(gm@cn)-cm['left_value']; vm = lm['left_value']@(gp@cp)-cm['right_value']
  dp = lm['right_dx']@(gm@cn)-cm['left_dx']; dm = cm['right_dx']-lm['left_dx']@(gp@cp)
  interfaces = np.array([wt*(np.vdot(vp, vp).real+np.vdot(vm, vm).real), wt*(np.vdot(dp, dp).real+np.vdot(dm, dm).real)])
  cells = int(scalar(r['config']['evaluation']['lead_cells']))
  for j in range(cells+1):
    xp = gp@cp; xm = gm@cn; cpn = pp@cp; cnn = pm@cn; xpn = gp@cpn; xmn = gm@cnn
    lead.append([sq(av@xp, la['weights'])+sq(av@xm, la['weights']), sq(an@xp, la['weights'])+sq(an@xm, la['weights'])])
    vp = lm['left_value']@xpn-lm['right_value']@xp; vm = lm['right_value']@xmn-lm['left_value']@xm
    dp = lm['right_dx']@xp-lm['left_dx']@xpn; dm = lm['right_dx']@xmn-lm['left_dx']@xm
    wall.append([wt*(np.vdot(vp, vp).real+np.vdot(vm, vm).real), wt*(np.vdot(dp, dp).real+np.vdot(dm, dm).real)])
    cp = cpn; cn = cnn
  lead = np.array(lead); wall = np.array(wall)
  lratio = lead[cells]/lead[cells-1]; wratio = wall[cells]/wall[cells-1]
  lt = lead[cells]/(1-lratio); wtail = wall[cells]/(1-wratio)
  center = np.array([sq(cr[:n], w), sq(cr[n:], w)])
  groups = {'center': center, 'lead_finite': lead[:cells].sum(0), 'lead_tail': lt, 'wall_center': interfaces, 'wall_internal': wall[:cells].sum(0), 'wall_tail': wtail}
  comparisons = {}
  for key, v in groups.items():
    old = np.array([scalar(r['components'][key+'_value_squared']), scalar(r['components'][key+'_normal_squared'])])
    comparisons[key] = {'matrix_value_normal': v.tolist(), 'saved_value_normal': old.tolist(), 'abs': abs(v-old).tolist(), 'component_relative': [rel(v[i], old[i]) for i in range(2)]}
  total = sum(groups.values()); d = scalar(e['base']['model']['d']); ep = float(np.sqrt(total[1]+total[0]/d**2))
  C = scalar(r['Cnum']); U = scalar(r['U_num']); Q = C*ep; R = 2*scalar(r['mu_num'])*Q/(U-Q)
  return {'backend': backend, 'matrix_order_sensitivity': comparisons, 'matrix_epsilon': ep, 'matrix_R': R, 'R_relative_to_saved': R/scalar(r['Rnum'])-1, 'lead_raw_relative': rel(lr, np.concatenate([la['signed_value_action'], -la['signed_normal_action']])), 'tail_ratios_lead': lratio.tolist(), 'tail_ratios_wall': wratio.tolist()}


for backend in ['direct', 'fmm']:
  outputs[backend] = one(backend); gc.collect()
outputs['interpretation'] = 'Operation-order diagnostic only; saved C and U retained; matrix-derived material actions and wall contractions reassembled; no high-precision reference and no new scientific run.'
outputs['runtime'] = {'wall_seconds': time.perf_counter()-start, 'peak_rss_bytes': resource.getrusage(resource.RUSAGE_SELF).ru_maxrss}
print(json.dumps(outputs, indent=2))
