"""Summarize monitored switch-line runs. RSS means resident set size.
Input: experiment directory and the final self-contained run directory.
Output: summary.json containing scalar costs and historical comparisons.
This reporting tool reads explicitly named outputs; it is not a scientific runtime prerequisite.
"""
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--experiment',required=True);p.add_argument('--final',required=True);a=p.parse_args();root=Path(a.experiment);final=Path(a.final)
b=json.loads((final/'arb'/'bounds.json').read_text());k=json.loads((final/'arb'/'kernel.json').read_text());f=json.loads((final/'matlab'/'export-summary.json').read_text());pipe=json.loads((final/'pipeline.json').read_text())
records=[]
for path in sorted((root/'output').glob('run-*/**/monitor.json')):
 v=json.loads(path.read_text());records.append({'path':str(path.relative_to(root)),**v})
result={'final_run':str(final),'final_bounds':{x:b[x] for x in ['Q_line_upper','Q_end_upper','Q_switch_upper','crude_switch_upper','ratio_to_floating_upper','mixed_Q_upper','mixed_margin_lower']},'pipeline':pipe,'all_monitors':records,'total_monitored_seconds':sum(x['wall_seconds'] for x in records),'all_runs_peak_rss_gib':max(x['peak_process_tree_rss_gib'] for x in records),'unit_two_branch_kernel_seconds':k['unit_kernel_seconds'],'unit_one_branch_kernel_mean_seconds':k['unit_kernel_seconds']/2,'field_build_seconds':f['field_seconds'],'export_total_seconds':f['total_seconds'],'kernel_seconds':k['seconds'],'kernel_hankels':k['hankel_evaluations'],'source_and_checks_seconds':b['seconds']-k['seconds'],'all_arb_hankels':b['hankel_evaluations'],'finite_prefix_and_contraction_prepare_seconds':sum(v['seconds'] for v in b['pieces']),'source_integral_seconds':sum(v['source_seconds'] for v in b['pieces'])}
(root/'summary.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
