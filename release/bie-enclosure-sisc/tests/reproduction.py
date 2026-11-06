"""Compare a fresh cold result with an explicitly supplied reference.
Input: completed run, reference JSON and output JSON paths.
Output: candidate-bit check, relative scientific differences and width gate.
These comparisons are postprocessing; they never select a search candidate.
"""
import argparse,json,gzip
from pathlib import Path
from decimal import Decimal

def read(path):
  path=Path(path);x=json.loads(gzip.decompress(path.read_bytes()) if path.suffix=='.gz' else path.read_text())
  return read(path.parent/x['archive']) if isinstance(x,dict) and 'archive' in x else x

def compare(run,reference):
  new=read(Path(run)/'result.json');old=read(reference);a=new['assembly'];b=old['assembly']
  def relative(x,y):
    x=Decimal(str(x));y=Decimal(str(y))
    return float(abs(x/y-1)) if y else (0.0 if not x else None)
  eps=[relative(x,y) for x,y in zip(a['epsilon_decimal_readback'],b['epsilon_decimal_readback'])]
  changes={k:relative(a[k],b[k]) for k in ['Q_upper','U_used','R_upper','width_upper']}
  checks=dict(candidate_bits=new['candidate']['k_hex']==old['candidate']['k_hex'],width_within_one_percent=changes['width_upper']<=.01,zero_group_preserved=all(v is not None for v in eps))
  return dict(passed=all(checks.values()),checks=checks,k_hex=new['candidate']['k_hex'],epsilon_relative_changes=eps,relative_changes=changes,U_certificate_identical=a['U_certificate_readback']==b['U_certificate_readback'],exact_scientific_values=all(a[k]==b[k] for k in ['epsilon_decimal_readback','U_certificate_readback','Q_upper','R_upper','mu_interval','k_interval','width_upper']),current={k:a[k] for k in ['epsilon_decimal_readback','U_used','Q_upper','R_upper','mu_interval','k_interval','width_upper']})
if __name__=='__main__':
  p=argparse.ArgumentParser();p.add_argument('--run',required=True);p.add_argument('--reference',required=True);p.add_argument('--output',required=True);a=p.parse_args();r=compare(a.run,a.reference);Path(a.output).write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r));raise SystemExit(0 if r['passed'] else 1)
