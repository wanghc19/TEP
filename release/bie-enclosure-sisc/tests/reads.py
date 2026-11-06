"""Check project file-read ledgers against explicit package and run boundaries.
Input: package, completed run, optional canonical data and project root paths.
Output: unique outside-project runtime dependencies and any forbidden project reads.
This checks recorded Python opens and MATLAB dependency lists, not C-library syscalls.
"""
import argparse,json,gzip
from pathlib import Path

def read(p):
  return json.loads(gzip.decompress(p.read_bytes()) if p.suffix=='.gz' else p.read_text())
def check(package,run,project,data=None):
  package,run,project=map(lambda p:Path(p).resolve(),[package,run,project]);allowed=[package,run]
  if data:allowed.append(Path(data).resolve())
  paths=set();ledgers=[]
  for p in run.rglob('*opened-files.jsonl'):
    ledgers.append(str(p.relative_to(run)))
    for line in p.read_text().splitlines():paths.add(str(Path(json.loads(line)['path']).resolve()))
  violations=[s for s in paths if Path(s).is_relative_to(project) and not any(Path(s).is_relative_to(a) for a in allowed)]
  return dict(passed=not violations,recorded_unique_reads=len(paths),ledgers=ledgers,forbidden_project_reads=violations,external_runtime_reads=sorted(s for s in paths if not Path(s).is_relative_to(project)))
if __name__=='__main__':
  p=argparse.ArgumentParser();p.add_argument('--package',required=True);p.add_argument('--run',required=True);p.add_argument('--project',required=True);p.add_argument('--data');p.add_argument('--output',required=True);a=p.parse_args();r=check(a.package,a.run,a.project,a.data);Path(a.output).write_text(json.dumps(r,indent=2)+'\n');print(json.dumps({k:v for k,v in r.items() if k!='external_runtime_reads'}));raise SystemExit(0 if r['passed'] else 1)
