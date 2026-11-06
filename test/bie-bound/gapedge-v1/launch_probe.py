"""Run an explicit command under the copied process-tree monitor.
Input: new output path and command after --. Output: preflight and monitor files.
"""
import argparse,json,os,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from run_pipeline import preflight
from monitor import run
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('command',nargs=argparse.REMAINDER);a=p.parse_args();out=Path(a.output)
assert not out.exists() or not any(out.iterdir());out.mkdir(parents=True,exist_ok=True)
r=preflight();(out/'preflight.json').write_text(json.dumps(r));assert not r['heavy_jobs'],r['heavy_jobs']
os.environ.update(PYTHONDONTWRITEBYTECODE='1',OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',OPENBLAS_NUM_THREADS='1',VECLIB_MAXIMUM_THREADS='1')
cmd=a.command[1:] if a.command[:1]==['--'] else a.command
r=run(out,cmd);sys.exit(bool(r['returncode'] or r['reason']!='completed'))
