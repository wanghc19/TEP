"""Summarize measured proxy aggregation and explicit historical cost assumptions.
Input: baseline and full-run directories; output JSON path.
Output: ordinary-arithmetic comparisons and cost predictions, not new certificates.
"""
import argparse
import json
from decimal import Decimal, getcontext
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('--baseline', type=Path, required=True)
p.add_argument('--full', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--old-serial-minutes', type=float, default=95.07649)
p.add_argument('--replaced-center-seconds', type=float, default=3510.823)
p.add_argument('--parallel-efficiency', type=float, default=.7751952721018845)
p.add_argument('--workers', type=int, default=8)
p.add_argument('--shared-seconds', type=float, default=183.19823729166668)
a = p.parse_args()
read = lambda path: json.loads(path.read_text())
s = read(a.full / 'summary.json')
monitor = read(a.full / 'monitor.json')
low = read(a.full / 'new-panel-0-M544.json')
getcontext().prec = 70
rows = []
for i in (0, 1):
  old = read(a.baseline / f'panel-{i}.json')
  new = read(a.full / f'new-panel-{i}-M576.json')
  x = Decimal(old['V'].split()[0][1:])
  y = Decimal(new['V'].split()[0][1:])
  rows.append(dict(panel=i, old_e_I=old['e_upper'], new_e_I=new['e_I'],
    new_to_old_error=new['e_I']/old['e_upper'], e_proxy=new['e_proxy'],
    V_old=old['V'], V_new=new['V'], V_midpoint_change=str(y-x),
    V_midpoint_relative_change=str((y-x)/x),
    epsilon_panel_upper=new['epsilon_panel_upper'],
    max_control_difference=max(z['field_difference'] for z in new['controls']),
    controls_pass=all(z['passed'] for z in new['controls']), gates=new['gates']))
remainder = s['seconds'] - s['setup_seconds'] - sum(z['seconds'] for z in s['panels']) - low['seconds']
# Charge the small enclosing remainder to setup in cost forecasts, conservatively.
setup = s['setup_seconds'] + remainder
online = sum(z['online_nonself_seconds'] for z in s['panels']) / 2
serial = 60*a.old_serial_minutes - a.replaced_center_seconds + setup + 192*online
parallel = a.shared_seconds + setup + (serial-a.shared_seconds-setup)/(a.workers*a.parallel_efficiency)
result = dict(panels=rows, measured=dict(
  setup_components_seconds=s['setup_seconds'], output_and_orchestration_remainder_seconds=remainder,
  setup_charged_in_forecast_seconds=setup, online_nonself_mean_seconds=online,
  main_panel_production_seconds=sum(z['production_seconds'] for z in s['panels']),
  control_seconds=sum(z['times']['controls'] for z in s['panels']),
  independent_norm_seconds=sum(z['times']['independent_norm'] for z in s['panels']),
  lower_order_seconds=low['seconds'], internal_seconds=s['seconds'],
  startup_monitor_final_output_seconds=monitor['wall_seconds']-s['seconds'],
  monitored_seconds=monitor['wall_seconds'], cpu_seconds=s['cpu_seconds'],
  peak_rss_gib=monitor['peak_process_tree_rss_gib']),
  reduced_order=s['reduced_order'],
  prediction=dict(old_serial_minutes=a.old_serial_minutes,
    replaced_center_seconds=a.replaced_center_seconds, targets=192,
    shared_seconds=a.shared_seconds, workers=a.workers,
    historical_parallel_efficiency=a.parallel_efficiency,
    serial_minutes=serial/60, parallel_wall_minutes=parallel/60,
    setup_parallel_policy='one serial setup; coefficient distribution unmeasured',
    status='PA21 extrapolation; only central non-self work replaced; no new parallel run'))
a.output.write_text(json.dumps(result, indent=2))
