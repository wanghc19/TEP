"""Probe real-ball integer square evaluation at a coincident source point.
Input: explicit output directory. Output: scalar operation comparison.
"""
import sys,json
from pathlib import Path
from flint import arb,ctx
ctx.prec=128
x=arb(0,arb('9.93e-39'));y=arb(0,arb('1.93e-38'))
r=dict(precision=ctx.prec,x=str(x),power=str(x**2),product=str(x*x),sum_power=str(x**2+y**2),sum_product=str(x*x+y*y))
Path(sys.argv[1],'scalar.json').write_text(json.dumps(r,indent=2));print(r)
