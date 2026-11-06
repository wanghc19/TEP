"""Deliberately invalid upper-band threshold: the checker must reject it.
Input: canonical field and explicit output directory. Output: rejected control.
The same control runs inside every full verification; this is a small entry.
"""
import argparse,json,sys
from pathlib import Path
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).resolve().parent.parent/'src/python/band'))
from flint import arb,ctx
from band_certificate import decode,hull,assemble_B,failed_control
from floating import indicator_matrix
p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True);a=p.parse_args();ctx.prec=128;ctx.threads=1
f=json.loads(Path(a.input).read_text());v=decode(f['curve_parameters']);R=hull(v[7],arb(1)/5);aa=hull(v[6],arb(1)/5)
B,M,G,record=assemble_B(R,aa,indicator_matrix(.2));result=failed_control(M,G);assert not result['check']['passed'] and result['two_negative_directions_upper']<0
out=Path(a.output);out.mkdir(parents=True,exist_ok=True);(out/'result.json').write_text(json.dumps(result,indent=2));print('PASS: deliberately invalid band threshold rejected')
