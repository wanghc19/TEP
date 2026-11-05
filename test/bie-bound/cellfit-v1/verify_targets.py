"""Independent real controls for cell-kernel field-fit targets.
Input: exact field JSON, same-run fit JSON, explicit output directory.
Output: repeated pilot ledgers plus independent full-residual controls.
"""
import argparse,json,sys,time
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,ctx
from material import Proxy,matrix,I,dump,up
from expansion import Sources,Expansion
from extended import run
p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--coefficients',required=True);p.add_argument('--output',required=True);a=p.parse_args()
out=Path(a.output);data=json.loads(Path(a.input).read_text());fits=json.loads(Path(a.coefficients).read_text());ctx.prec=128;ctx.cap=81;ctx.threads=1
start=time.perf_counter();cpu=time.process_time();K=Proxy(data);Z=matrix(fits['Z']);A=matrix(fits['A']);B=matrix(fits['B_center']);charges=[(Z[1,j].real,Z[0,j].real,A[0,j]) for j in range(Z.ncols())]
(out/'part.txt').write_text('shared-source');src=Sources(K,data['pieces'][0]);phase=(I*matrix(data['beta'])[0,0]*matrix(data['d'])[0,0]).exp()
near=Expansion(K,[(arb(0),arb(m),phase**m) for m in [-1,1]],arb('.6'),128,src)
ea=Expansion(K,charges,arb('.9'),288,src);eb=Expansion(K,charges,arb('1.1'),144,coefficients=B)
# Closed-cell and target-complex-image checks on the actual binary64 inputs.
cellradius=(arb(1)/2).sqrt();moving=min(max(abs(X)-arb('.5')-arb('.360001'),abs(Y)-arb('.5')-arb('.260001')) for X,Y,c in charges)
fixed=min(max(abs(X)-arb('.5'),abs(Y)-arb('.5')) for X,Y,c in charges)
assert moving>0 and fixed>0
assert src.g['radius']+src.g['delta']<near.R
record=dict(moving_proxy_clearance=up(moving.lower()),fixed_proxy_clearance=up(fixed.lower()),complex_image_upper=up(src.g['radius']+src.g['delta']),setup_seconds=time.perf_counter()-start)
dump(out/'summary.json',record)
record['extended']=run(data,fits,K,src,near,ea,eb,out,True)
record.update(seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu);dump(out/'summary.json',record)
