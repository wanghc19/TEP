"""Reproduce the two accepted incident-wave bounds using the final selection rule.
Input: same-run field, explicitly selected panel metadata. Output: envelope-check.json.
"""
import argparse,json,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from material import Proxy,matrix,up,dump
from panel import incident
from flint import arb
p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True);p.add_argument('--panels',nargs='+',required=True);a=p.parse_args()
data=json.loads(Path(a.input).read_text());K=Proxy(data);piece=data['pieces'][0]
T=matrix(piece['tau_coeff']);Z=matrix(piece['zeta_coeff']);rows=[]
for f in a.panels:
 d=json.loads(Path(f).read_text());h=arb.pi()/d['P'];c=(2*d['panel']+1)*h
 _,M=incident(data,c,h,d['p'],arb('.04'),K,T,Z,piece['modes'])
 rows.append(dict(panel=d['panel'],computed=up(M),recorded=d['M_local_upper']))
dump(Path(a.output)/'envelope-check.json',rows)
assert all(v['computed']==v['recorded'] for v in rows)
