"""Run ledger: CSV means comma-separated values, RSS resident set size.
Input: explicit experiment output tree and destination CSV.
Output: one outer-monitor cost per run, with its recorded scientific role.
"""
import argparse,csv,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True);a=p.parse_args()
roles={1:'floating continuation',2:'floating continuation',3:'regression interface failure',4:'regression passed',5:'stopped for local-radius correction',6:'accepted cold search field residual audit; mass reader failure',7:'accepted finishing stages and export equality',8:'confirmation stopped by old disk guard',9:'manager stopped repeat; not numerical failure',10:'near-edge resource pilot',11:'cold L0=2.0',12:'cold L0=1.9'}
rows=[]
for r in sorted(Path(a.input).glob('run-*')):
 m=r/'monitor.json'
 if not m.exists():continue
 d=json.loads(m.read_text());rows.append(dict(run=r.name,role=roles.get(int(r.name.split('-')[-1]),'see run record'),wall_seconds=d['wall_seconds'],peak_RSS_GiB=d['peak_process_tree_rss_gib'],monitor_reason=d['reason'],returncode=d['returncode'],source=str(m)))
with Path(a.output).open('w') as f:
 w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
print('Monitored sum (includes repeats, failures and pilots):',sum(r['wall_seconds'] for r in rows))
