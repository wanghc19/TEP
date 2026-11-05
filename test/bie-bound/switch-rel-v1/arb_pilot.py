"""Measure Arb Bessel J/Y cost and inspect supported series operations.
Input: output directory. Output: pilot.json.
"""
import sys,time,json
from pathlib import Path
from flint import arb,acb,acb_series,ctx
ctx.prec=128
start=time.perf_counter();n=2000
for j in range(n):
 z=acb(arb(1)+arb(j)/n,arb(1)/100)
 h=z.bessel_j(0)+acb(0,1)*z.bessel_y(0)
 h1=z.bessel_j(1)+acb(0,1)*z.bessel_y(1)
elapsed=time.perf_counter()-start
out={'seconds':elapsed,'JY_pairs':2*n,'seconds_per_Hankel':elapsed/(2*n),'precision':ctx.prec,
 'series_methods':[x for x in dir(acb_series) if any(y in x for y in ['bessel','sqrt','sin','exp'])],
 'arb_methods':[x for x in dir(arb) if any(y in x for y in ['upper','lower','mid','rad','union'])]}
Path(sys.argv[1],'pilot.json').write_text(json.dumps(out,indent=2));print(out)
