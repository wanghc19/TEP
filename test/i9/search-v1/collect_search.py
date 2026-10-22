#!/usr/bin/env python3
"""Export current I9.1 results and scientific figures without choosing parameters.

Reads only the explicitly supplied completed current-run directory. It never
runs MATLAB, selects candidates, changes classification or feeds a search.
"""
import argparse
import csv
import json
from pathlib import Path


def rows(value):
  return value if isinstance(value, list) else [value]


def table(path, data, fields):
  with path.open('w') as stream:
    writer = csv.DictWriter(stream, fieldnames=fields)
    writer.writeheader()
    writer.writerows({key: row.get(key, '') for key in fields} for row in data)


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('run_directory')
  parser.add_argument('--presentation-status', help='Current-attempt MATLAB plotting monitor status')
  args = parser.parse_args()
  directory = Path(args.run_directory)
  state = json.loads((directory/'state.json').read_text())
  status = json.loads((directory/'status.json').read_text())
  points = {point['id']: point for point in state['points']}
  lead_log = state['lead_log']
  lead_rows = []
  for record in lead_log['records']:
    row = {key: record[key] for key in ('id', 'k', 'k_hex', 'resolution_id', 'common_gap', 'seconds', 'bypass')}
    for side in ('negative', 'positive'):
      for key in ('status', 'stable', 'unstable', 'near', 'uncertain', 'indeterminate', 'minimum_distance', 'residual'):
        row[side+'_'+key] = record[side][key]
      row[side+'_bie_residual'] = record[side+'_bie_residual']
    lead_rows.append(row)
  if lead_rows:
    table(directory/'lead-points.csv', lead_rows, list(lead_rows[0]))
  table(directory/'candidates.csv', state['candidates'], ['interval_id','source_ids','point_id',
    'status','stop_reason','k','resolution_id','adef_sigma','adef_ratio','aphys_sigma','aphys_ratio','W','confirmation_id'])
  histories = []
  for history in state['history']:
    point = points.get(history['winner_point_id'], {})
    histories.append(dict(history, first=history['k'][0], last=history['k'][-1],
      winner_k=point.get('k'), aphys_sigma=point.get('aphys_sigma'), aphys_ratio=point.get('aphys_ratio')))
  table(directory/'rounds.csv', histories, ['id','interval_id','round','resolution_id','first','last','W',
    'min_spacing','max_spacing','winner_index','winner_k','aphys_sigma','aphys_ratio','interior','decision'])
  table(directory/'intervals.csv', state['intervals'], ['id','gap_id','parent_id','source_ids','kind',
    'initial_bounds','bounds','round','status','best_id','children','stop_reason'])
  counts = {}
  for resolution in ('coarse', 'fine'):
    matching = [p for p in points.values() if p['resolution_id'] == resolution]
    leads = [p for p in lead_rows if p['resolution_id'] == resolution]
    requests = [r for r in lead_log['requests'] if r['resolution_id'] == resolution]
    counts[resolution] = dict(matching_calls=len(matching), matching_unique_k=len({p['k_hex'] for p in matching}),
      matching_confirmations=sum(p['bypass_cache'] for p in matching),
      lead_pair_calls=len(leads), lead_pair_unique_k=len({p['k_hex'] for p in leads}),
      lead_requests=len(requests), lead_cache_hits=sum(r['action']=='CACHE_HIT' for r in requests))
  summary = dict(schema='I91_SEARCH_SUMMARY_V1', status=state['status'], config=state['config'],
    gap_sides=state['gap_sides'], common_gaps=state['common_gaps'],
    coarse_internal_dips=len(state['coarse_dips']), total_intervals=len(state['intervals']),
    final_candidates=sum(c['status']=='COMPLETE' for c in state['candidates']),
    provisional_candidates=sum(c['status']!='COMPLETE' for c in state['candidates']),
    candidates=state['candidates'], confirmations=state['confirmations'],
    representative_checks=state['representative_checks'], equal_validation=state.get('equal_validation'),
    counts=counts, matching_counters=state['counters'],
    lead_cache_peak_bytes=lead_log['cache_peak_bytes'], lead_cache_evictions=lead_log['evictions'],
    lead_failures=lead_log['failures'], timing=state['timing'],
    matching_and_gap_seconds=sum(state['timing'].values()),
    matlab_seconds=state['elapsed_seconds'], process_wall_seconds=status['wall_seconds'],
    remaining_process_seconds=status['wall_seconds']-sum(state['timing'].values()),
    peak_rss_bytes=status['peak_rss_bytes'], survivors=status['survivors'],
    validation_extra_constructions=dict(lead_cells=2, center_cells=1) if 'equal_validation' in state else {},
    unresolved_intervals=[t for t in state['intervals'] if t['status'] not in ('COMPLETE','SPLIT')],
    unresolved_edges=[e for e in state['edge_records'] if e['status']=='NONWINNING_EDGE_PENDING'])
  if args.presentation_status:
    presentation=json.loads(Path(args.presentation_status).read_text())
    summary['presentation_process_seconds']=presentation['wall_seconds']
    summary['complete_delivery_process_seconds']=status['wall_seconds']+presentation['wall_seconds']
    summary['shared_monitored_seconds']=presentation['shared_elapsed_seconds']
    summary['presentation_peak_rss_bytes']=presentation['peak_rss_bytes']
    summary['presentation_survivors']=presentation['survivors']
  (directory/'summary.json').write_text(json.dumps(summary,indent=2,allow_nan=False)+'\n')
  print(json.dumps({k: summary[k] for k in ('status','counts','final_candidates','timing','process_wall_seconds','peak_rss_bytes')},indent=2))


if __name__ == '__main__':
  main()
