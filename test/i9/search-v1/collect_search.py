#!/usr/bin/env python3
"""Export current I9.1 results and scientific figures without choosing parameters.

Reads only the explicitly supplied completed current-run directory. It never
runs MATLAB, selects candidates, changes classification or feeds a search.
"""
import argparse
import csv
import json
import datetime as dt
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
  parser.add_argument('--baseline-run', help='Optional explicit completed baseline for post-run reporting only')
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
  def round_vs_best(run_state):
    records=[]
    for candidate in run_state['candidates']:
      best=run_state['points'][candidate['best_id']-1]
      records.append(dict(interval_id=candidate['interval_id'],formal_point_id=candidate['point_id'],
        cumulative_best_point_id=candidate['best_id'],formal_k=candidate['k'],cumulative_best_k=best['k'],
        formal_aphys_ratio=candidate['aphys_ratio'],cumulative_best_aphys_ratio=best['aphys_ratio'],
        signed_ratio_difference=candidate['aphys_ratio']-best['aphys_ratio'],
        relative_ratio_increase=(candidate['aphys_ratio']/best['aphys_ratio']-1) if best['aphys_ratio'] else None,
        cumulative_best_four_metrics={key:best[key] for key in ('adef_sigma','adef_ratio','aphys_sigma','aphys_ratio')}))
    return records
  summary['final_round_vs_cumulative_best']=round_vs_best(state)
  if args.presentation_status:
    presentation=json.loads(Path(args.presentation_status).read_text())
    summary['presentation_process_seconds']=presentation['wall_seconds']
    summary['complete_delivery_process_seconds']=status['wall_seconds']+presentation['wall_seconds']
    summary['shared_monitored_seconds']=presentation['shared_elapsed_seconds']
    summary['presentation_peak_rss_bytes']=presentation['peak_rss_bytes']
    summary['presentation_survivors']=presentation['survivors']
    science_command=json.loads((directory/'command.json').read_text())
    span=(dt.datetime.fromisoformat(presentation['finished_utc'])-dt.datetime.fromisoformat(science_command['started_utc'])).total_seconds()
    summary['complete_delivery_elapsed_wall_seconds']=span
    summary['interprocess_and_reporting_gap_seconds']=span-summary['complete_delivery_process_seconds']
  (directory/'summary.json').write_text(json.dumps(summary,indent=2,allow_nan=False)+'\n')
  if args.baseline_run:
    baseline_directory=Path(args.baseline_run)
    baseline=json.loads((baseline_directory/'summary.json').read_text())
    baseline_state=json.loads((baseline_directory/'state.json').read_text())
    baseline_plot_status=baseline_directory.parent/'plot-01'/'status.json'
    if baseline_plot_status.exists():
      baseline_start=json.loads((baseline_directory/'command.json').read_text())['started_utc']
      baseline_finish=json.loads(baseline_plot_status.read_text())['finished_utc']
      baseline['complete_delivery_elapsed_wall_seconds']=(dt.datetime.fromisoformat(baseline_finish)-dt.datetime.fromisoformat(baseline_start)).total_seconds()
    differences=[]
    def compare_config(old,new,path=''):
      if isinstance(old,dict) and isinstance(new,dict):
        for key in sorted(set(old)|set(new)):
          compare_config(old.get(key),new.get(key),path+'.'+key if path else key)
      elif old!=new:
        differences.append(dict(path=path,baseline=old,current=new))
    compare_config(baseline['config'],summary['config'])
    metric_fields=['k','adef_sigma','adef_ratio','aphys_sigma','aphys_ratio','W','status']
    candidate_rows=[]
    for label,data in [('scaled_baseline',baseline),('native_center',summary)]:
      for candidate in data['candidates']:
        candidate_rows.append(dict(experiment=label,interval_id=candidate['interval_id'],
          **{key:candidate[key] for key in metric_fields}))
    formal_old=[c for c in baseline['candidates'] if c['status']=='COMPLETE']
    formal_new=[c for c in summary['candidates'] if c['status']=='COMPLETE']
    candidate_change=None
    if len(formal_old)==len(formal_new)==1:
      old,new=formal_old[0],formal_new[0]
      delta=new['k']-old['k']
      candidate_change=dict(signed_k_difference=delta,absolute_k_difference=abs(delta),
        relative_k_difference=abs(delta)/abs(old['k']),
        four_metric_absolute_differences={key:abs(new[key]-old[key]) for key in metric_fields[1:5]},
        interpretation='comparison of the sole observed candidate in each model, not a mode-identity or eigenvalue-error claim')
    comparison=dict(config_differences=differences,candidates=candidate_rows,candidate_change=candidate_change,
      baseline_final_round_vs_cumulative_best=round_vs_best(baseline_state),
      current_final_round_vs_cumulative_best=round_vs_best(state),
      baseline_geometry=baseline_state['geometry'],current_geometry=state['geometry'],
      baseline_initial_classification=baseline_state['gap_exploration'],current_initial_classification=state['gap_exploration'],
      baseline_common_gaps=baseline['common_gaps'],current_common_gaps=summary['common_gaps'],
      baseline_unresolved_intervals=baseline['unresolved_intervals'],current_unresolved_intervals=summary['unresolved_intervals'],
      baseline_unresolved_edges=baseline['unresolved_edges'],current_unresolved_edges=summary['unresolved_edges'],
      baseline_counts=baseline['counts'],current_counts=summary['counts'],
      baseline_timing=baseline['timing'],current_timing=summary['timing'],
      baseline_process_seconds=baseline['process_wall_seconds'],current_process_seconds=summary['process_wall_seconds'],
      baseline_complete_delivery_seconds=baseline.get('complete_delivery_process_seconds'),
      current_complete_delivery_seconds=summary.get('complete_delivery_process_seconds'),
      baseline_complete_delivery_elapsed_wall_seconds=baseline.get('complete_delivery_elapsed_wall_seconds'),
      current_complete_delivery_elapsed_wall_seconds=summary.get('complete_delivery_elapsed_wall_seconds'),
      baseline_peak_rss_bytes=baseline['peak_rss_bytes'],current_peak_rss_bytes=summary['peak_rss_bytes'])
    (directory/'comparison.json').write_text(json.dumps(comparison,indent=2,allow_nan=False)+'\n')
    table(directory/'comparison.csv',candidate_rows,['experiment','interval_id']+metric_fields)
  print(json.dumps({k: summary[k] for k in ('status','counts','final_candidates','timing','process_wall_seconds','peak_rss_bytes')},indent=2))


if __name__ == '__main__':
  main()
