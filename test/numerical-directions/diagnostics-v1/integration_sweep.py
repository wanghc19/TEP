"""Run the serial integration-rate sweep; RSS is resident set size.
Input: none; execute from the repository root.
Output: run-002 case records, block-cleanup.json and sweep-resources.json.
"""
import json,time
from pathlib import Path
from monitor import run,disk_size

base=Path('test/numerical-directions/diagnostics-v1/output/run-002')
prior=sum(json.loads(p.read_text())['wall_seconds'] for p in base.glob('cap-*/monitor.json'))
start=time.monotonic(); results=[]
for cap in [100000,200000,400000,800000,1600000]:
  out=base/f'cap-{cap}'
  expr=f"addpath('test/i9/dtn-bound-v1','test/numerical-directions/diagnostics-v1'); integration_rate('{out.as_posix()}',{cap})"
  elapsed=prior+time.monotonic()-start
  status=run(out,expr,1800-elapsed,2400-elapsed)
  if status['returncode'] or status['reason']!='completed': break
  rows=json.loads((out/'template-rate.json').read_text())
  print('CAP',cap,[(x['level'],x['template'],x['terminal_pieces'],x['stop_reason']) for x in rows],flush=True)
  before=disk_size(out); blocks=list((out/'blocks').glob('**/*.mat'))
  deleted=sum(p.stat().st_size for p in blocks)
  for p in blocks: p.unlink()
  cleanup={'disposable_block_files_removed':len(blocks),'removed_mb':deleted/1e6,'before_mb':before/1e6,'retained_mb':disk_size(out)/1e6,'recipe':'integration_rate(output_dir,piece_limit) regenerates the original blocks before extraction'}
  (out/'block-cleanup.json').write_text(json.dumps(cleanup,indent=2))
  results.append({'piece_limit':cap,**status,**cleanup})
(base/'sweep-resources.json').write_text(json.dumps(results,indent=2))
