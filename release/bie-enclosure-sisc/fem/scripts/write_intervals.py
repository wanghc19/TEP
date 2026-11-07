# Source: test/fem-goerisch/pipeline-v1/write_intervals.py. Decimal display rule retained.
"""Display outward endpoints from the new integral data; no solver inputs.
Input: fresh run directory. Output: interval.json decimal display and scalar checks.
Decimal arithmetic checks formulas; it does not certify upstream floating rounding.
"""
import json
from decimal import Decimal, localcontext, ROUND_FLOOR, ROUND_CEILING
from pathlib import Path

def process(out):
  out=Path(out)
  data=json.loads((out/'integrals.json').read_text(),parse_float=Decimal)
  result=json.loads((out/'interval.json').read_text())
  with localcontext() as ctx:
    ctx.prec=60
    E=data['E'];M=data['M'];S=data['S_upper'];s=data['s'];g=Decimal(data['gamma'])
    mu=data['alpha_minus']+g;nu=data['alpha_plus']+g
    a=g+E[0]/M[1];b=g+E[1]/M[0];delta=b*S/M[0]
    root=(delta+delta*delta/4).sqrt()
    first=[a*(1+delta/2-root)-g,b*(1+delta/2+root)-g]
    lower=[];upper=[]
    for e in E:
      for m in M:
        q=g+e/m;d=q*S/m-(q-s)**2/s**2
        def endpoint(t): return q-g+q*t*d/(q-t-t*d)
        lower.append(endpoint(nu));upper.append(endpoint(mu))
    corners=[min(lower),max(upper)]
    def display(ends,digits):
      step=Decimal(10)**(-digits)
      return [str(ends[0].quantize(step,rounding=ROUND_FLOOR)),str(ends[1].quantize(step,rounding=ROUND_CEILING))]
    result['I_1']['decimal_endpoints']=[str(x) for x in first]
    result['I_1']['printed_outward']=display(first,10)
    result['four_corner']['decimal_endpoints']=[str(x) for x in corners]
    result['four_corner']['printed_outward']=display(corners,13)
    result['four_corner']['decimal_width']=str(corners[1]-corners[0])
    result['printed_endpoints']='outward display of the decimal scalar formula; upstream rounding excluded'
  (out/'interval.json').write_text(json.dumps(result,indent=2)+'\n')
  reference_display_regression(out,result)
  c=json.loads((out/'common-certificates.json').read_text())
  f=json.loads((out/'interface-certificate.json').read_text())
  x=json.loads((out/'exact-flux.json').read_text())
  check={'E_contains_Q24':c['E_contains_Q24'],'M_common_contains_Q24':c['M_contains_Q24'],
    'mass_correction_contains_band16':c['mass_correction']['contains_band16'],
    'interface_contains_Q16':f['contains_Q16'],'interface_contains_Q24':f['contains_Q24'],
    'four_corner_signs':f['full_interval']['signs'],
    'minimum_selfmap_margin':min(t['min_selfmap_margin'] for t in f['templates']),
    'minimum_actual_branch_margin':min(t['min_actual_branch_margin'] for t in f['templates']),
    'outer_normal_moment':x['vertical_master_moment'],
    'shared_master_reconstruction_difference':x['shared_master_reconstruction_difference']}
  check['pass']=all(check[k] for k in ['E_contains_Q24','M_common_contains_Q24','mass_correction_contains_band16','interface_contains_Q16','interface_contains_Q24']) and f['full_interval']['pass'] and check['minimum_selfmap_margin']>0 and check['minimum_actual_branch_margin']>0 and check['outer_normal_moment']==0
  (out/'delivery-checks.json').write_text(json.dumps(check,indent=2)+'\n')
  if not check['pass']:raise RuntimeError('Integral delivery checks failed; see delivery-checks.json')
  return result

def reference_display_regression(out,result):
  """Input: new run and display. Output: reference-only printed-value check."""
  regression=out/'regression.json'
  if not regression.exists():return
  r=json.loads(regression.read_text());setting=json.loads((out/'config.json').read_text())['setting']
  if setting=='original':
    r['I1_paper_printed']=['2.4286785150','2.4287788272']
    r['I1_printed_match']=result['I_1']['printed_outward']==r['I1_paper_printed']
    r['pass']=r['pass'] and r['I1_printed_match']
  regression.write_text(json.dumps(r,indent=2)+'\n')
  if not r['pass']:raise RuntimeError('Reference regression failed; see regression.json')

if __name__=='__main__':
  import sys
  process(sys.argv[1])
