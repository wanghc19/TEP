"""Audit comparison records for finite element and isolation computations.
Input: explicit completed run directories; output: small comparison tables.
This postprocessor is not a prerequisite of any numerical stage.
"""
import argparse,json,struct
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--new',type=Path,required=True);p.add_argument('--old',type=Path,required=True);p.add_argument('--kind',choices=['interval','surface','dtn','core'],required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
read=lambda p:json.loads(p.read_text());x=read(a.new);y=read(a.old)
fields={'interval':['E','M','S_upper','s'],'surface':['material','lambda','d_per','error_norm','eps_C','eps_H','eps_U','eps_G','C_real','C_imag','E_real','E_imag'],'dtn':['K_plus','K_minus','r','K_r','A_H','eps_Q','eps_R','eps_Z','lower_real','lower_imag'],'core':['negative_count','safe_margin','epsilon','c_W','C_h']}[a.kind]
def flat(v):
  if isinstance(v,list):return [u for z in v for u in flat(z)]
  return [v]
rows={}
for f in fields:
  u=flat(x[f]);v=flat(y[f]);assert len(u)==len(v)
  rows[f]={'bitwise':all(struct.pack('d',s)==struct.pack('d',t) for s,t in zip(u,v)), 'max_absolute_difference':max(abs(s-t) for s,t in zip(u,v)),'max_relative_difference':max(abs(s-t)/max(abs(t),1e-300) for s,t in zip(u,v))}
a.output.write_text(json.dumps({'kind':a.kind,'fields':rows},indent=2)+'\n');print(json.dumps(rows,indent=2))
