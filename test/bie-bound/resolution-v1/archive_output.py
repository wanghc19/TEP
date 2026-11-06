"""Losslessly compress large owned output JSON after accepted checks.
Input: completed resolution-v1 run and --keep-field for the reusable reference.
Output: gzip files and an explicit recovery ledger; no external path is writable.
"""
import argparse,gzip,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--run',required=True);p.add_argument('--keep-field',action='store_true');p.add_argument('--failed',action='store_true');a=p.parse_args();run=Path(a.run).resolve();owner=Path(__file__).resolve().parent
assert run.parent==owner/'output'
assert ((run/'failure.json').exists() and (run/'end-to-end.json').exists()) if a.failed else json.loads((run/'result.json').read_text())['status']=='COMPLETE'
assert (owner/'tables/baseline-check.json').exists();rec=json.loads((run/'archive.json').read_text())['files'] if (run/'archive.json').exists() else []
for f in run.rglob('*.json'):
  if f.name=='archive.json' or f.stat().st_size<20000:continue
  if a.keep_field and f.parent.name=='07-band' and f.name=='result.json':continue
  if a.keep_field and f.parent.name=='02-field' and f.name in ['fixed-input.json','coefficients.json']:continue
  raw=f.read_bytes();dest=Path(str(f)+'.gz');assert not dest.exists()
  with gzip.open(dest,'wb',compresslevel=6) as z:z.write(raw)
  with gzip.open(dest,'rb') as z:assert z.read()==raw
  rec.append(dict(path=str(f.relative_to(run)),original_size=len(raw),compressed_size=dest.stat().st_size));f.unlink()
(run/'archive.json').write_text(json.dumps(dict(recovery='gzip -dk FILE.json.gz restores each exact original JSON; all scientific inputs/outputs preserved losslessly',files=rec),indent=2));print('compressed',len(rec))
