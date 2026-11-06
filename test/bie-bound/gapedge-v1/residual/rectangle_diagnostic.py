# Stage C source: test/bie-bound/example2-v1/residual/rectangle_diagnostic.py; local adaptations only.
# B2 source: test/bie-bound/pipeline-v1/residual/rectangle_diagnostic.py; generalized model plumbing.
# Copied from test/bie-bound/grouprel-v1/rectangle_diagnostic.py; pipeline adaptations documented in README.
"""Complex local-term rectangle diagnostic in Arb ball arithmetic.
Input: exact field path, output directory, subdivision count.
Output: operation-by-operation finite tests and whole-rectangle nonzero bounds.
"""
import argparse,json,sys,time
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,acb,ctx
from material import Proxy,matrix,geom,up,dump

def operations(K,z):
  x,y,dx,dy=geom(z,K.R,K.b);a=dx*dx+dy*dy;v=a.sqrt();nx=dy/v;ny=-dx/v;w=v.sqrt()
  vals=dict(x=x,y=y,dx=dx,dy=dy,speed_squared=a,speed=v,normal_x=nx,normal_y=ny,weight=w)
  return dict(values={k:str(v) for k,v in vals.items()},finite={k:bool(v.is_finite()) for k,v in vals.items()},speed_squared_real_lower=str(a.real.lower()),speed_squared_abs_lower=str(abs(a).lower()))

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True);p.add_argument('--tiles',type=int,default=16);a=p.parse_args();ctx.prec=192;start=time.perf_counter();cpu=time.process_time();data=json.loads(Path(a.input).read_text());pars=matrix(data['curve_parameters']);rows=[];n=a.tiles;rt=arb('.12')
  for side in [1,2]:
    K=Proxy(data);K.R=(pars[0,7].real,);K.b=pars[0,4+side].real
    for j in range(64):
      ct=(2*j+1)*arb.pi()/64;whole=operations(K,acb(arb(ct,rt),arb(0,rt)));lo=arb(100);ab=arb(100);good=True
      for u in range(n):
        for v in range(n):
          z=acb(arb(ct-rt+(2*u+1)*rt/n,(rt/n).upper()),arb(-rt+(2*v+1)*rt/n,(rt/n).upper()));x,y,dx,dy=geom(z,K.R,K.b);s=dx*dx+dy*dy;lo=min(lo,s.real.lower());ab=min(ab,abs(s).lower());good=good and bool(s.real>0)
      rows.append(dict(side=side,panel=j,whole=whole,tiles=n*n,real_speed_squared_lower=str(lo),abs_speed_squared_lower=str(ab),all_tiles_positive=good))
  result=dict(rows=rows,all_rectangles_certified=all(x['all_tiles_positive'] for x in rows),seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu);dump(Path(a.output)/'summary.json',result);assert result['all_rectangles_certified'],'A rectangle needs a smaller-domain or panel-split repair'
if __name__=='__main__':main()
