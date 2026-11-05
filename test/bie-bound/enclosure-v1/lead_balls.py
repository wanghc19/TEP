"""Arb (real ball arithmetic) comparison of identical right-lead jump targets.
Input: exact field, B coefficients, explicit floating CSV, output.
Output: midpoint comparisons, component scales and independent source checks.
"""
import argparse,csv,json,sys,time,resource,math
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,acb,acb_mat,ctx
from material import Proxy,matrix,I,geom,up
from expansion import Sources,Expansion,norm
from lead_self import source,kernel
from self_interaction import Radial
from extended import trace,incident

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--fits',required=True);p.add_argument('--floating',required=True);p.add_argument('--output',required=True);a=p.parse_args()
  start=time.perf_counter();ctx.prec=192;ctx.cap=81;ctx.threads=1
  out=Path(a.output);data=json.loads(Path(a.input).read_text());fits=json.loads(Path(a.fits).read_text());floats=list(csv.DictReader(open(a.floating)))
  K=Proxy(data);pars=matrix(data['curve_parameters']);K.R=(pars[0,7].real,);K.b=pars[0,6].real;piece=data['pieces'][2]
  G=matrix(piece['G']);c=matrix(piece['c']);W=G*c;Ct=matrix(piece['tau_coeff'])*W;Cz=matrix(piece['zeta_coeff'])*W
  bc=matrix(fits['B_positive'])*c;Z=matrix(fits['Z']);beta=matrix(data['beta'])[0,0].real;d=matrix(data['d'])[0,0].real;phase=(I*beta*d).exp()
  cp=dict(piece,tau_coeff=Ct,zeta_coeff=Cz);src=Sources(K,cp,64,80,arb('.12'))
  near=Expansion(K,[(arb(0),arb(m),phase**m) for m in [-1,1]],arb('.6'),72,src)
  proxy=Expansion(K,[(Z[1,j].real,Z[0,j].real,acb(1)) for j in range(Z.ncols())],arb('1.1'),144,coefficients=bc)
  grid,V=source(K,Ct,Cz,piece['modes'],1152);rad=Radial(K.k,arb(17));setup=time.perf_counter()-start
  records=[];checks=[];stats={'value':[],'normal':[]};maxparts=[0.,0.];squared=arb(0);float_squared=0.;early_squared=0.
  for index,row in enumerate(floats):
    # Match the indexed Kress node exactly; double trigonometric rounding is part of the comparison.
    tt=2*arb.pi()*int(row['index'])/1536;x,y,dx,dy=geom(tt,K.R,K.b);weight=(dx*dx+dy*dy).sqrt().sqrt()
    selfv=kernel(tt,K,rad,grid)*V;nv,ne=near.value(x,y);pv,pe=proxy.value(x,y);nv=trace(nv,x,y,K,True,t=tt);pv=trace(pv,x,y,K,True,t=tt)
    inc=trace(incident(K,beta,d,x,y)*W,x,y,K,True,t=tt)
    ff=acb_mat(1,len(piece['modes']),[(I*m*tt).exp() for m in piece['modes']]);loc=acb_mat(2,1,[weight*(ff*Ct)[0,0],weight*(ff*Cz)[0,0]])+inc
    vv=selfv+nv+pv+loc;values=[vv[0,0]/weight,-vv[1,0]/weight]
    rec={'index':int(row['index']),'theta':row['theta'],'value_ball':[str(values[0].real),str(values[0].imag)],'normal_ball':[str(values[1].real),str(values[1].imag)]}
    for j,key in enumerate(['value','normal']):
      z=complex(float(values[j].real.mid()),float(values[j].imag.mid()));f=complex(float(row[key+'_re']),float(row[key+'_im']));e=complex(float(row['early_'+key+'_re']),float(row['early_'+key+'_im']))
      diff=abs(z-f);ediff=abs(z-e);stats[key].append((abs(z),abs(f),diff,ediff));rec[key+'_mid']=[z.real,z.imag];rec[key+'_double_difference']=diff;rec[key+'_early_difference']=ediff
      maxparts[j]=max(maxparts[j],*(float(abs(v[j,0]/weight)) for v in [selfv,nv,pv,loc]))
    squared+=(abs(values[0])**2+abs(values[1])**2)*(weight**2)*2*arb.pi()/len(floats)
    float_squared+=(abs(complex(float(row['value_re']),float(row['value_im'])))**2+abs(complex(float(row['normal_re']),float(row['normal_im'])))**2)*float(weight**2)*2*math.pi/len(floats)
    early_squared+=(abs(complex(float(row['early_value_re']),float(row['early_value_im'])))**2+abs(complex(float(row['early_normal_re']),float(row['early_normal_im'])))**2)*float(weight**2)*2*math.pi/len(floats)
    if index in [0,17,73]:
      g2,V2=source(K,Ct,Cz,piece['modes'],2304);s2=kernel(tt,K,rad,g2)*V2
      checks.append({'index':index,'self_1152_vs_2304_difference':up(norm(s2-selfv)),'proxy_direct_vs_expansion':up(norm(proxy.direct(x,y)-proxy.value(x,y)[0]))})
    records.append(rec)
    if index%32==0:print('point',index,flush=True)
  summary={}
  for key,v in stats.items():
    summary[key]=dict(max_arb=max(z[0] for z in v),max_double=max(z[1] for z in v),max_difference=max(z[2] for z in v),rms_difference=math.sqrt(sum(z[2]**2 for z in v)/len(v)),max_early_difference=max(z[3] for z in v))
  result=dict(points=len(records),source_nodes=1152,precision=192,setup_seconds=setup,seconds=time.perf_counter()-start,summary=summary,
    largest_component=maxparts,first_cell_sample_arb_squared=str(squared),first_cell_sample_double_squared=float_squared,first_cell_sample_early_squared=early_squared,
    checks=checks,peak_process_rss_bytes=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss)
  (out/'points.json').write_text(json.dumps(records,indent=2));(out/'diagnostic.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
if __name__=='__main__':main()
