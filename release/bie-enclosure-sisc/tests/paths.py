"""Scan every package text file for local absolute paths.
Input: explicit package directory. Output: PASS or locations of forbidden paths.
No numerical files are modified. Binary formats are skipped after UTF-8 failure.
"""
import argparse,json,sys
from pathlib import Path
sys.dont_write_bytecode=True
p=argparse.ArgumentParser();p.add_argument('--package',required=True);p.add_argument('--output');a=p.parse_args();root=Path(a.package).resolve()
prefixes=['/'+'Users/','/'+'home/','/'+'private/','/'+'var/folders/','/'+'Applications/'];bad=[];count=0
for f in sorted(root.rglob('*')):
  if not f.is_file():continue
  try:text=f.read_text(encoding='utf-8')
  except UnicodeDecodeError:continue
  count+=1
  for n,line in enumerate(text.splitlines(),1):
    if any(x in line for x in prefixes):bad.append(dict(file=str(f.relative_to(root)),line=n))
rec=dict(passed=not bad,text_files=count,violations=bad)
if a.output:Path(a.output).write_text(json.dumps(rec,indent=2)+'\n')
print(json.dumps(rec));raise SystemExit(0 if not bad else 1)
