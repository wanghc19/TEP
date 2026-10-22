#!/usr/bin/env python3
"""Export current-run search tables without changing any scientific decisions.

Input is the completed run's state.json and monitor status.json. All outputs
remain in that same directory; there is no historical or MATLAB dependency.
"""
import argparse
import csv
import json
from pathlib import Path


def as_list(value):
  return value if isinstance(value, list) else [value]


def table(path, rows, fields):
  with path.open('w') as stream:
    writer = csv.DictWriter(stream, fieldnames=fields)
    writer.writeheader()
    writer.writerows({field: row.get(field, '') for field in fields} for row in rows)


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('run_directory')
  args = parser.parse_args()
  directory = Path(args.run_directory)
  state = json.loads((directory/'state.json').read_text())
  status = json.loads((directory/'status.json').read_text())
  points = {point['id']: point for point in state['points']}
  candidates = []
  for candidate in state['candidates']:
    row = dict(candidate)
    row['candidate_kind'] = 'FINAL' if candidate['status'] == 'COMPLETE' else 'PROVISIONAL'
    best = points[candidate['best_id']]
    row.update(cumulative_best_k=best['k'], cumulative_best_aphys_ratio=best['aphys_ratio'])
    candidates.append(row)
  table(directory/'candidates.csv', candidates,
    ['interval_id','candidate_kind','status','resolution_id','k','adef_sigma',
     'adef_ratio','aphys_sigma','aphys_ratio','W','point_id','confirmation_id',
     'cumulative_best_k','cumulative_best_aphys_ratio','stop_reason'])
  rounds = []
  for history in state['history']:
    row = dict(history)
    winner = points.get(history['winner_point_id'], {})
    row.update(first=history['k'][0], last=history['k'][-1], winner_k=winner.get('k'),
      aphys_sigma=winner.get('aphys_sigma'), aphys_ratio=winner.get('aphys_ratio'))
    rounds.append(row)
  table(directory/'rounds.csv', rounds,
    ['id','interval_id','resolution_id','round','first','last','W','min_spacing',
     'max_spacing','winner_index','winner_point_id','winner_k','aphys_sigma',
     'aphys_ratio','interior','decision'])
  table(directory/'intervals.csv', state['intervals'],
    ['id','parent_id','source_ids','kind','resolution_id','initial_bounds','bounds',
     'round','status','best_id','children','stop_reason'])
  counts = {}
  for resolution in ('coarse','fine'):
    rows = [p for p in state['points'] if p['resolution_id'] == resolution]
    requests = [r for r in state['requests'] if r['resolution_id'] == resolution]
    counts[resolution] = dict(actual_calls=len(rows),
      search_calls=sum(not p['bypass_cache'] for p in rows),
      confirmation_calls=sum(p['bypass_cache'] for p in rows),
      unique_successful_k=len({p['k_hex'] for p in rows if p['status'] == 'SUCCESS'}),
      requested=len(requests), cache_hits=sum(r['action']=='CACHE_HIT' for r in requests),
      point_seconds=sum(p['seconds'] for p in rows),
      failed=sum(p['status']!='SUCCESS' for p in rows))
  outcomes = []
  for source in state['coarse_dips']:
    descendants = [t for t in state['intervals'] if source['id'] in as_list(t['source_ids'])]
    outcomes.append(dict(coarse_dip_id=source['id'], initial_interval_id=source['interval_id'],
      coarse_bounds=source['bounds'], interval_ids=[t['id'] for t in descendants],
      terminal_intervals=[dict(id=t['id'], status=t['status']) for t in descendants if t['status']!='SPLIT']))
  summary = dict(schema='I85_SCAN_SUMMARY_V1', status=state['status'],
    config=state['config'], coarse_internal_dips=len(state['coarse_dips']),
    coarse_endpoint_indices=state['coarse_detection']['edge_indices'],
    coarse_dip_outcomes=outcomes,
    coarse_endpoint_outcomes=[dict(interval_id=t['id'], status=t['status'],stop_reason=t['stop_reason'])
      for t in state['intervals'] if t['kind']=='COARSE_ENDPOINT'],
    initial_intervals=sum(t['parent_id']==0 for t in state['intervals']),
    total_intervals=len(state['intervals']), final_candidates=sum(c['status']=='COMPLETE' for c in candidates),
    provisional_candidates=sum(c['status']!='COMPLETE' for c in candidates),
    pending_edge_count=state.get('pending_edge_count',0),
    pending_edges=[dict(e,k=points[e['point_id']]['k'],aphys_ratio=points[e['point_id']]['aphys_ratio'])
      for e in state['edge_records'] if e['status']=='NONWINNING_EDGE_PENDING'], counts=counts,
    counters=state['counters'], timing=state['timing'],
    numerical_point_seconds=sum(state['timing'].values()),
    matlab_search_seconds=state['elapsed_seconds'], process_wall_seconds=status['wall_seconds'],
    remaining_process_seconds=status['wall_seconds']-sum(state['timing'].values()),
    peak_rss_bytes=status['peak_rss_bytes'], survivors=status['survivors'],
    candidates=candidates, confirmations=state['confirmations'],
    unresolved_intervals=[t for t in state['intervals'] if t['status'] not in ('COMPLETE','SPLIT')])
  (directory/'summary.json').write_text(json.dumps(summary,indent=2,allow_nan=False)+'\n')
  print(json.dumps(summary,indent=2,allow_nan=False))


if __name__ == '__main__':
  main()
