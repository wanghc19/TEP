"""B2 model/representation conditions with ball arithmetic.
Input: explicit field/fit files; output: numeric clearances and Wood margins.
"""
import argparse,json,sys,time
from pathlib import Path
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).resolve().parent/'residual'))
from flint import arb,acb,ctx
from material import matrix,up

def main():
 p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--coefficients',required=True);p.add_argument('--output',required=True);a=p.parse_args();ctx.prec=192
 d=json.loads(Path(a.input).read_text());f=json.loads(Path(a.coefficients).read_text());widths=matrix(d['cell_widths']);pars=matrix(d['curve_parameters']);k=matrix(d['k'])[0,0].real;beta=matrix(d['beta'])[0,0].real;period=matrix(d['d'])[0,0].real;Z=matrix(f['Z']);rows=[]
 assert period==1 and beta==arb(1)/2
 assert d['example']['rho_lead']==17 and d['example']['rho_center']==(1 if d['example']['empty_center'] else 4)
 assert d['example']['L0']==1 and d['example']['L_negative']==1 and d['example']['L_positive'] in [1,.85]
 assert pars[0,7].real==arb(.2) and pars[0,5].real==arb(.12) and pars[0,6].real==arb(.2)
 for j in range(3):
  L=widths[0,j].real;assert L>0;empty=d['pieces'][j]['shape']=='none'
  if empty:
   assert matrix(d['pieces'][j]['tau_coeff']).nrows()==0 and matrix(d['pieces'][j]['zeta_coeff']).nrows()==0
   assert all(matrix(f['B_center'])[i,0].is_zero() for i in range(Z.ncols()))
   radius=arb(0);curve_margin=None;image_margin=None
  else:
   if j==0:radius=None;curve_margin=min(L/2-pars[0,0].real*(arb('1.5')+pars[0,1].real),period/2-pars[0,0].real*(1+pars[0,1].real))
   else:
    R=pars[0,7].real;aa=pars[0,4+j].real;radius=R*(1+aa)/(1+aa*aa/2).sqrt();curve_margin=min(L,period)/2-radius
   assert curve_margin>0;image_margin=curve_margin
  distances=[]
  for l in range(Z.ncols()):
   X=Z[1,l].real;Y=Z[0,l].real
   dd=(max(arb(0),abs(X)-L/2)**2+max(arb(0),abs(Y)-period/2)**2).sqrt();assert dd>0;distances.append(dd.lower())
  rows.append(dict(piece=j,empty_material=empty,L=str(L),curve_wall_clearance_lower=None if empty else str(curve_margin.lower()),near_image_clearance_lower=None if empty else str(image_margin.lower()),proxy_clearance_lower=str(min(distances))))
 gammas=[abs(acb(k*k-(beta+2*arb.pi()*int(m)/period)**2).sqrt()) for m in d['rayleigh_modes']];wood=min(g.lower() for g in gammas);assert wood>0
 result=dict(model=d['example'],pieces=rows,wood_gamma_lower=str(wood),empty_center_material_exact_zero=rows[0]['empty_material'],status='PASS',representation='continuous trigonometric layer densities; three near images; fixed point sources; finite Rayleigh incident field; no wrap')
 Path(a.output).mkdir(exist_ok=True);(Path(a.output)/'conditions.json').write_text(json.dumps(result,indent=2))
if __name__=='__main__':main()
