#!/usr/bin/env python3
"""Collect I9.5 eq-temple result.json files into one comparison table.

Purpose: read-only post-processing of finished runs; no scientific decisions.
Usage: python3 summarize_eq.py RUN_DIR [RUN_DIR ...] --output summary.json
Each flux row reports Theorem B eta, the B.1 (9) eta, the bulk/end split,
the linear bound at mu_h and the conditional Temple radii for every lambda_plus.
"""
import argparse
import json
from pathlib import Path


def rows(run):
  result = json.loads((run / 'result.json').read_text())
  tail = result.get('tail') or {}
  label = run.name
  if tail.get('glue_cell') is not None:
    label += ' (glue %d, tail %d)' % (tail['glue_cell'], tail['tail_cells'])
  fluxes = result['fluxes']
  if isinstance(fluxes, dict):
    fluxes = [fluxes]
  for flux in fluxes:
    t, s = flux['totals'], flux['scalars']
    x_t = s['x_T'] if isinstance(s['x_T'], list) else [s['x_T']]
    yield dict(run=label, flux=flux['name'], s=flux['s'], eta_B=t['etaB'], eta_9=t['eta9'],
      bulk_B=t['bulkB'], end=t['end_contribution'], eps=t['eps2_total'] ** .5,
      tau_R=s['tau_R'], R_linear=s['R_linear_mu_h'], x_T=x_t, lambda_plus=s['lambda_plus'],
      dist_conditional=s['dist_mu_h_conditional'], mu_R=result['mu_R'], U=result['U'])


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('runs', nargs='+')
  parser.add_argument('--output', required=True)
  args = parser.parse_args()
  table = [row for run in args.runs for row in rows(Path(run))]
  Path(args.output).write_text(json.dumps(table, indent=2) + '\n')
  print('| run | flux | s | eta_B | eta_9 | bulk_B | end | R_lin(mu_h) | x_T(4.785) | x_T(4) | x_T(3) |')
  print('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|')
  for r in table:
    print('| %s | %s | %.4f | %.5f | %.5f | %.5f | %.5f | %.5f | %.3e | %.3e | %.3e |' % (
      r['run'], r['flux'], r['s'], r['eta_B'], r['eta_9'], r['bulk_B'], r['end'], r['R_linear'],
      *r['x_T'][:3]))
  best = min((r for r in table if r['flux'] != 'i94_average_witness'), key=lambda r: r['x_T'][0])
  lin = min((r for r in table if r['flux'] != 'i94_average_witness'), key=lambda r: r['R_linear'])
  print('\nbest conditional x_T(4.785): %.6e (%s, %s)' % (best['x_T'][0], best['run'], best['flux']))
  print('best unconditional R_linear: %.6e (%s, %s)' % (lin['R_linear'], lin['run'], lin['flux']))


if __name__ == '__main__':
  main()
