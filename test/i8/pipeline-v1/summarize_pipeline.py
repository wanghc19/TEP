#!/usr/bin/env python3
"""Produce small reviewable summaries from this attempt's completed pipeline output.

This is postprocessing only: it cannot launch MATLAB or alter scientific results.
The output separates successful process walls, common setup, and failed runs.
"""
import argparse
import csv
import datetime as dt
import json
import statistics
from pathlib import Path


def read(path):
  return json.loads(path.read_text())


def write_csv(path, rows):
  with path.open('w',newline='') as stream:
    writer=csv.DictWriter(stream,fieldnames=list(rows[0]))
    writer.writeheader()
    for row in rows:
      writer.writerow({key:format(value,'.17g') if isinstance(value,float) else value
        for key,value in row.items()})


def main():
  parser=argparse.ArgumentParser()
  parser.add_argument('run_dir')
  parser.add_argument('--summary-dir',help='Summary output directory (default: run_dir)')
  args=parser.parse_args()
  run_dir=Path(args.run_dir).resolve()
  summary_dir=Path(args.summary_dir).resolve() if args.summary_dir else run_dir
  combined=read(run_dir/'result.json'); rows=[]; callbacks=[]; rounds=[]
  for backend in combined['config']['backend']['order']:
    pipeline=combined['pipelines'][backend]; estimate=pipeline['estimate']
    points=read(run_dir/backend/'points.json')
    save_export=sum(read(path)['save_export'] for path in (run_dir/backend).glob('round-*/batch-timing.json'))
    save_export+=read(run_dir/backend/'estimate/save-timing.json')['save_export']
    numerical=pipeline['search_point_seconds']+sum(estimate['timing'].values())
    row=dict(backend=backend,status=estimate['status'],certified=estimate['certified'],
      k0=estimate['k0'],mu_num=estimate['mu_num'],candidate_ratio=pipeline['candidate']['aphys_ratio'],
      final_round_k=pipeline['final_round_winner']['k'],final_actual_W=pipeline['final_round']['actual_W'],
      point_count=pipeline['point_count'],round_count=pipeline['round_count'],
      search_point_seconds=pipeline['search_point_seconds'],**estimate['timing'],
      save_export=save_export,search_process_wall=pipeline['search_process_wall'],
      estimate_process_wall=pipeline['estimate_process_wall'],
      pipeline_process_wall=pipeline['pipeline_process_wall'],
      pipeline_elapsed_wall=pipeline['pipeline_elapsed_wall'],
      unclassified_process_overhead=pipeline['pipeline_process_wall']-numerical-save_export,
      peak_rss_bytes=pipeline['peak_rss_bytes'],Cnum=estimate['Cnum'],
      epsilon_num=estimate['epsilon_num'],U_num=estimate['U_num'],Q=estimate['Q'],
      denominator=estimate['denominator'],Rnum=estimate['Rnum'])
    for metric in ['adef_sigma','adef_ratio','aphys_sigma','aphys_ratio']:
      row['candidate_'+metric]=pipeline['candidate'][metric]
      row['fresh_'+metric]=estimate['point'][metric]
    point_seconds=[point['seconds'] for point in points]
    row.update(search_point_min=min(point_seconds),search_point_median=statistics.median(point_seconds),
      search_point_max=max(point_seconds),candidate_round=pipeline['candidate']['round_index'],
      candidate_evaluation_index=pipeline['candidate']['evaluation_index'],
      candidate_node=pipeline['candidate']['node_index'],
      final_winner_round=pipeline['final_round_winner']['round_index'],
      final_winner_evaluation_index=pipeline['final_round_winner']['evaluation_index'],
      final_winner_node=pipeline['final_round_winner']['node_index'])
    rows.append(row)
    for record in read(run_dir/backend/'rounds.json'):
      rounds.append(dict(backend=backend,**{key:record[key] for key in [
        'round_index','kind','count','first','last','actual_W','requested_step',
        'selected_index','selected_k','selected_ratio','interior','left_neighbor',
        'right_neighbor','cumulative_k','cumulative_ratio']}))
    for stage,records in [('search',[call for point in points for call in point['proxy_calls']]),
      ('estimate',estimate['proxy_calls'])]:
      callbacks.append(dict(backend=backend,stage=stage,calls=len(records),
        callback_seconds=sum(call['seconds'] for call in records),
        semantics='subset of numerical stage timers; never add to total'))
  direct,fmm=rows
  differences={name:dict(signed=fmm[name]-direct[name],absolute=abs(fmm[name]-direct[name]),
    relative_to_direct=(abs(fmm[name]-direct[name])/abs(direct[name]) if direct[name]
      else (0 if fmm[name]==0 else None)))
    for name in ['k0','mu_num','Cnum','epsilon_num','U_num','Q','denominator','Rnum']}
  failed=[]
  for path in sorted(run_dir.parent.glob('run-*/**/status.json')):
    status=read(path)
    if status.get('exit_code',0)!=0:
      failed.append(dict(path=str(path.relative_to(run_dir.parent)),**status))
  summary=dict(schema='I84_PIPELINE_SUMMARY_V1',created_utc=dt.datetime.now(dt.timezone.utc).isoformat(),
    run_dir=str(run_dir),config=combined['config'],pipelines=rows,differences=differences,
    stage_speedups={name:direct[name]/fmm[name] for name in [
      'search_point_seconds','final_field','jumps','mass','geometry_assembly',
      'save_export','unclassified_process_overhead'] if fmm[name]},
    successful_process_speedup=direct['pipeline_process_wall']/fmm['pipeline_process_wall'],
    elapsed_pipeline_speedup=direct['pipeline_elapsed_wall']/fmm['pipeline_elapsed_wall'],
    setup_wall=combined['setup']['wall_seconds'],failed_runs=failed,
    failed_wall=sum(item['wall_seconds'] for item in failed),
    launcher_wall=combined['launcher_wall'],
    launcher_unassigned_overhead=combined['launcher_wall']-combined['setup']['wall_seconds']-sum(row['pipeline_elapsed_wall'] for row in rows),
    timing_semantics='Mutually exclusive construction/jumps/mass/geometry/save stages; callbacks are subsets. Remaining monitored process-batch wall is startup/shutdown/preflight/cleanup/wrapper overhead. Pipeline elapsed also includes controller overhead. Setup and failures are separate.',
    claim='UNCERTIFIED_RNUM: independent own-field estimates, no certified error bound or eigenvalue enclosure')
  (summary_dir/'summary.json').write_text(json.dumps(summary,indent=2,allow_nan=False)+'\n')
  write_csv(summary_dir/'summary.csv',rows); write_csv(summary_dir/'rounds.csv',rounds); write_csv(summary_dir/'callbacks.csv',callbacks)
  components=[]
  for name,value in combined['pipelines']['direct']['estimate']['components'].items():
    if isinstance(value,bool):
      continue
    other=combined['pipelines']['fmm']['estimate']['components'][name]
    components.append(dict(component=name,direct=value,fmm=other,signed=other-value,
      absolute=abs(other-value),
      relative_to_direct=(abs(other-value)/abs(value) if value else (0 if other==0 else ''))))
  write_csv(summary_dir/'components.csv',components)
  print(json.dumps(dict(successful_process_speedup=summary['successful_process_speedup'],
    k0_difference=differences['k0'],Rnum_difference=differences['Rnum']),indent=2))


if __name__=='__main__':
  main()
