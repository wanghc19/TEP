"""Rounding error estimates and high-precision endpoint sensitivities.
Input: retained stage JSON and local floating diagnostics. Output: estimates JSON/CSV.
Every reported effect is an estimate, including all chosen safety factors.
"""
from pathlib import Path
import json,csv,math,argparse
import numpy as np
from scipy.io import loadmat
from flint import arb,acb,fmpq,ctx
ctx.prec=256
p=argparse.ArgumentParser();p.add_argument('--experiment',required=True);p.add_argument('--core-run',default='run-007');p.add_argument('--qj-run',default='run-009');a=p.parse_args();base=Path(a.experiment).resolve();repo=base.parents[2]
u=2.**-53
g=lambda n:n*u/(1-n*u)
jread=lambda p:json.loads(Path(p).read_text())
old=lambda exp,run,name='result.json':jread(repo/'test/numerical-directions'/exp/'output'/run/'science'/name)
rows=[];extras={};gauss=jread(base/'output/gauss-checks.json');gr={z['order']:z for z in gauss['rules']};assert max(z['max_comparator_radius'] for z in gr.values())<1e-80;gx16=2*gr[16]['max_node_absolute_error'];gw16=2*gr[16]['max_weight_relative_error'];gxC=2*max(z['max_node_absolute_error'] for n,z in gr.items() if 16<=n<=77);gwC=2*max(z['max_weight_relative_error'] for n,z in gr.items() if 16<=n<=77);duffy16=2*gw16+gx16/gr[16]['minimum_one_minus_node'];duffyC=2*gwC+gxC/min(z['minimum_one_minus_node'] for n,z in gr.items() if 16<=n<=77)
def row(stage,key,quantity,margin,estimate,formula,inputs,source,role='decision'):
  rows.append(dict(stage=stage,id=key,quantity=quantity,margin=float(margin),estimate=float(estimate),ratio=float(margin/estimate) if estimate>0 else None,formula=formula,inputs=inputs,source=source,role=role))
# A: coefficient absolute quadrature sums, matrix products, and eigensolvers.
J=2048;N=6;mn=np.array([(m,n) for m in range(-N,N+1) for n in range(-N,N+1)]);dm=mn[None,:,0]-mn[:,None,0];dn=mn[None,:,1]-mn[:,None,1];comp=[]
for aa in [.12,.20]:
  t=2*np.pi*np.arange(J)/J;r=.2/np.sqrt(1+aa*aa/2)*(1+aa*np.cos(3*t));dr=-3*.2/np.sqrt(1+aa*aa/2)*aa*np.sin(3*t);dx=dr*np.cos(t)-r*np.sin(t);dy=dr*np.sin(t)+r*np.cos(t);ca=np.empty((25,25))
  for i,mi in enumerate(range(-12,13)):
    for j,ni in enumerate(range(-12,13)):
      qx=2*np.pi*mi;qy=2*np.pi*ni;q2=qx*qx+qy*qy;ca[i,j]=np.sum(abs(qx*dy-qy*dx))*2*np.pi/J/q2 if q2 else .04*np.pi
  normAbs=float(np.linalg.norm(ca[dm+12,dn+12],1));comp.append({'a':aa,'absolute_curve_matrix_norm1':normAbs,'delta_B':g(8*J+100)*normAbs})
tab=np.loadtxt(base/'output/run-003/science/panels.csv',delimiter=',');panel_rows=[]
for r in tab:
  panel,s,theta,radius,ml,mh,nl,nh,mnorm,gnorm,low,high,den=r;s=int(s)-1;bnorm=(mnorm+1)/16;db=comp[s]['delta_B'];dM=16*db;dG=256*((1+2*bnorm)*db+g(8*169)*bnorm**2);dK=100*u*max(nl+low*mnorm,nh+high*mnorm)
  el=low*dM+dK+g(10)*(nl+2*low*mnorm)+10*169*u*nl
  eh=high*dM+high*high/den*dG+dK+g(30)*(nh+2*high*mnorm+2*high*high/den*gnorm)+10*169*u*nh
  panel_rows.extend([dict(panel=int(panel),material=comp[s]['a'],endpoint='lower',margin=ml,estimate=el,ratio=ml/el,matrix_norm1=nl,assembly=el-10*169*u*nl,solver=10*169*u*nl),dict(panel=int(panel),material=comp[s]['a'],endpoint='upper',margin=mh,estimate=eh,ratio=mh/eh,matrix_norm1=nh,assembly=eh-10*169*u*nh,solver=10*169*u*nh)])
for end in ['lower','upper']:
  rr=min((x for x in panel_rows if x['endpoint']==end),key=lambda x:x['ratio']);row('A','A-'+end,'236个'+end+'端面板符号（最小比值）',rr['margin'],rr['estimate'],'lambda*dM+[lambda^2/den*dG]+dK+gamma_ops*abs_terms+10*n*u*norm1',dict(rr,n=169,coefficient=comp),'output/run-003/science/panels.csv；band/band_estimate.m:24')
row('A','A-tail','尾分母正性',float(min(tab[:,-1])),g(100)*float(max(tab[:,-1]+17*tab[:,-2])), 'gamma_100*(tail+17*lambda)',{'min_den':float(min(tab[:,-1])),'max_scale':float(max(tab[:,-1]+17*tab[:,-2]))},'output/run-003/science/panels.csv')
extras['A_components']=comp;extras['A_panels']=panel_rows
# B: retain each case and each Schur cutoff.
Brecords=[];Bsource=jread(base/'output/B-scales.json')['records']
for run in ['run-009','run-010','run-007','run-011']:
  d=old('h-cert-v1',run);C=np.array(d['C_real'])+1j*np.array(d['C_imag']);E=np.array(d['E_real'])+1j*np.array(d['E_imag']);kap=d['gram_cancellation_ratio'];nd=d['dimension'];steps=8*nd+d['phase_panels']*d['phase_gauss_order']+8*d['curve_points'];scale=float(np.linalg.norm(C,1)+np.linalg.norm(E,1));simple_assembly=g(steps)*kap*scale
  zsrc=next(z for z in Bsource if z['a']==d['material'] and z['lambda']==d['lambda']);lamB=d['lambda'];Znorm=d['max_trial_bound'];GF=float(np.trace(np.array(d['G_real'])));EF=float(np.trace(E).real);TF=zsrc['T_L2_Frobenius'];Fnorm=(17*lamB+1)*TF;Anorm=math.sqrt(17*GF)+16*lamB*Znorm+Fnorm;Bnorm=Anorm+16*lamB*Znorm;DZnorm=Anorm+lamB*Znorm;dxeff=zsrc['delta_X_estimate']+g(8*nd)*zsrc['X_abs_norm1'];dIT=zsrc['delta_IT_F_estimate'];dTT=zsrc['delta_TT_norm1_estimate'];dF=16*lamB*dIT+(lamB+1)*g(200)*TF
  etaR=dF+16*lamB*dxeff*Znorm+g(20)*(Fnorm+DZnorm+lamB*(1+16*zsrc['X_abs_norm1'])*Znorm)
  Cabs=16*lamB*TF**2+2*Fnorm*Znorm+Znorm*(DZnorm+lamB*(1+16*zsrc['X_abs_norm1'])*Znorm);eC=16*lamB*dTT+2*Znorm*dF+16*lamB*Znorm**2*dxeff+g(8*nd+d['phase_panels']*d['phase_gauss_order'])*Cabs
  eG0=(Anorm**2+Bnorm**2)*dxeff+2*((lamB+1)*Anorm+(17*lamB+1)*Bnorm)*dIT+((lamB+1)**2+(17*lamB+1)**2)*dTT+2*Anorm*(lamB+1)*g(200)*TF+(lamB+1)**2*g(200)*TF**2+g(8*nd+d['phase_panels']*d['phase_gauss_order'])*kap*17*GF
  cache_XA=g(8*nd)*zsrc['X_abs_norm1']*d['max_residual_bound'];cache_G0=(Anorm+Bnorm)*cache_XA+16*lamB*Bnorm*g(8*nd)*zsrc['X_abs_norm1']*Znorm;eG0+=cache_G0
  dtail=(2*math.pi*(d['N']+1)-math.pi)**2+.25;poisson=d.get('bound_method')=='poisson2';HT=EF if poisson else EF/d['form_inverse'];eH=eG0/dtail+2*math.sqrt(HT)*2*etaR+(2*etaR)**2+g(d['phase_panels']*d['phase_gauss_order'])*HT
  if poisson:
    coef=17*lamB*(1+lamB/d['d_per']);VT=EF/coef;eV=eG0/dtail**2+2*math.sqrt(VT)*4*etaR+(4*etaR)**2+g(d['phase_panels']*d['phase_gauss_order'])*VT;eE=eH+coef*eV
  else:coef=0.;VT=0.;eV=0.;eE=d['form_inverse']*eH
  assembly=max(simple_assembly,eC+eE);Bdetail=dict(zsrc,Z_norm=Znorm,G_trace=GF,E_trace=EF,F_norm=Fnorm,A_norm=Anorm,B_norm=Bnorm,DZ_norm=DZnorm,delta_X_effective=dxeff,delta_F=dF,eta_residual=etaR,C_abs_scale=Cabs,eC=eC,eG0=eG0,cache_XA_estimate=cache_XA,cache_G0_effect=cache_G0,cache_source_scale=d['max_residual_bound'],d_tail=dtail,H_trace_estimate=HT,eH=eH,Poisson_coefficient=coef,V_trace_estimate=VT,eV=eV,eE=eE,simple_assembly=simple_assembly)
  for test in d['tests']:
    M=test['M'];ix=slice(10-M,11+M);Cm=C[ix,ix]-E[ix,ix]-test['tail']['penalty']*np.eye(2*M+1);norm=float(np.linalg.norm(Cm,1));estimate=assembly+10*(2*M+1)*u*norm
    row('B',f'B-{run}-M{M}',f"a={d['material']}，lambda={d['lambda']}，M={M} Schur符号",test['gamma'],estimate,'max(gamma_(8*nd+P*q+8*J)*kappa*(Cnorm+Enorm),eC+eE)+10*p*u*Cminus_norm；详细传播见B式',{'n':2*M+1,'nd':nd,'P':d['phase_panels'],'q':d['phase_gauss_order'],'J':d['curve_points'],'kappa':kap,'CplusE_norm1':scale,'Cminus_norm1':norm,'detailed_assembly':Bdetail},f'h-cert-v1/output/{run}/science/result.json')
    tail=test['tail'];row('B',f'B-tail-{run}-M{M}',f"a={d['material']} lambda={d['lambda']} M={M} 尾分母",tail['t'],g(500)*(.5+tail['h']),'gamma_500*(0.5+h)',{'h':tail['h'],'x':tail['x'],'penalty':tail['penalty']},f'h-cert-v1/output/{run}/science/result.json/tests/tail')
  Brecords.append({'run':run,'nd':nd,'cancellation':kap,'scale':scale,'assembly_estimate':assembly,'details':Bdetail})
extras['B']=Brecords
# C: coarse positive scales measured with the final field and flux.
Cdata=[]
for side,oldrun,run in [('left','run-006','run-014'),('right','run-008','run-015')]:
  d=old('h-dtn-v1',oldrun);f=jread(base/'output'/run/'science/result.json');sc=np.diag(1/np.sqrt(np.sqrt(1+(.5+2*np.pi*np.arange(-16,17))**2)));
  Q=np.array(d['Q_real'])+1j*np.array(d['Q_imag']);R=np.array(d['R_real'])+1j*np.array(d['R_imag']);Z=np.array(d['Z_real'])+1j*np.array(d['Z_imag']);qnorm=float(np.linalg.norm(sc@Q@sc,1));rnorm=float(np.linalg.norm(sc@R@sc,1));znorm=float(np.linalg.norm(sc@Z@sc,1));w=f['series_weight_bound'];gg=f['G_norm_squared'];ss=float(np.linalg.norm(sc,2)**2)
  pq=ss*(f['first']['positive_Q']+gg*w*f['bulk']['positive_Q']);zeta=ss*(f['first']['rounding_basis_terms_squared']+gg*w*f['bulk']['rounding_basis_terms_squared']);fieldterms=ss*(f['first']['field_absolute_terms_squared']+gg*w*f['bulk']['field_absolute_terms_squared']);physicalterms=ss*(f['first']['rounding_large_terms_squared']+gg*w*f['bulk']['rounding_large_terms_squared']);pz=ss*(f['first']['positive_Z']+gg*w*f['bulk']['positive_Z']);part=d['first']['parts']+d['bulk']['parts'];maxorder=d['first']['max_order'];path=8*maxorder**2+part+20*8*192
  etaU=(g(500)+100*gxC)*math.sqrt(fieldterms);eQ=(g(path)+duffyC)*pq+2*math.sqrt(pq)*etaU+etaU**2;eta=(g(1000)+100*gxC)*math.sqrt(zeta);eR=2*math.sqrt(max(rnorm,0))*eta+eta*eta+(g(path)+duffyC)*rnorm
  # z=u+K*r2 has an additional cancellation-amplified residual evaluation.
  ezfield=math.sqrt(pq)+d['K_plus']*math.sqrt(zeta);etaZ=etaU+d['K_plus']*eta;eZ=2*math.sqrt(max(pz,0))*etaZ+etaZ**2+(g(path)+duffyC)*pz
  phi=d['b_H_squared']/d['A_H'];el=eQ+d['K_plus']*eR+phi*eZ+g(100)*(qnorm+d['K_plus']*rnorm+phi*znorm)
  egap=(d['K_plus']+d['K_minus'])*eR+phi*eZ+g(30)*(2*qnorm+d['gap']);er=g(100)*d['K_plus']*d['r']+d['K_plus']*eR
  cs={'side':side,'qnorm1_scaled':qnorm,'rnorm1_scaled':rnorm,'znorm1_scaled':znorm,'positive_Q_scaled':pq,'large_terms_squared_scaled':physicalterms,'basis_terms_squared_scaled':zeta,'field_terms_squared_scaled':fieldterms,'etaU':etaU,'etaR':eta,'positive_Z_scaled':pz,'quadrature_path':path,'eval_path':1000,'node_error_working':gxC,'weight_relative_working':gwC,'Duffy_weight_effect':duffyC,'eQ':eQ,'eR':eR,'eZ':eZ,'eLambda_scaled':el,'eGap':egap,'eKr':er,'series_weight':w,'Gnorm2':gg,'source_run':run};Cdata.append(cs)
  row('C',f'C-{side}-Lambda',side+'下DtN最小特征值（trace归一）',d['min_lower'],el,'gamma_path*positive_Q+2*sqrt(positive_Q)*etaU+etaU^2+Kplus*eR+phi*eZ+gamma_100*(Qnorm+K*Rnorm+phi*Znorm)',cs,f'h-dtn-v1/output/{oldrun}/science/result.json + output/{run}/science/result.json')
  row('C',f'C-{side}-r',side+'残差范数r',d['r'],eR,'2*sqrt(norm1(Rscaled))*eta+eta^2+(gamma_path+duffy_error)*norm1(Rscaled)；eta=(gamma_1000+100*node_error)*sqrt(B_R)',cs,f'h-dtn-v1/output/{oldrun}/science/result.json')
  row('C',f'C-{side}-budget',side+' Kplus*r预算',4e-4-d['K_r'],er,'Kplus*eR+gamma_100*Kplus*r',cs,f'h-dtn-v1/output/{oldrun}/science/result.json')
  row('C',f'C-{side}-gap',side+'上下DtN间隙数值',d['gap'],egap,'(Kplus+Kminus)*eR+phi*eZ+gamma_30*(2*Qnorm+gap)',cs,f'h-dtn-v1/output/{oldrun}/science/result.json',role='printed')
  row('C',f'C-{side}-AH',side+'高频提升分母AH',d['A_H'],g(500)*(d['a_H']+d['K_plus']*d['b_H_squared']),'gamma_500*(aH+Kplus*bH2)',{'aH':d['a_H'],'bH2':d['b_H_squared'],'Kplus':d['K_plus']},f'h-dtn-v1/output/{oldrun}/science/result.json')
  for key in ['eps_Q','eps_R','eps_Z','b_H_squared','high_penalty']:
    row('C',f'C-{side}-{key}',side+' '+key+'的末位',d[key],g(10000)*abs(d[key]),'gamma_10000*abs(value)',{'value':d[key],'path_assumed':10000},f'h-dtn-v1/output/{oldrun}/science/result.json',role='printed-component')
extras['C']=Cdata
# Analytic Gram absolute envelopes, re-evaluated as norm diagnostics only.
def core_gram_envelopes(Nx=31,Ny=16):
  m=np.tile(np.arange(Nx+1),2*Ny+1);k=np.repeat(np.arange(-Ny,Ny+1),Nx+1);cm=np.full(len(m),math.sqrt(2.));cm[m==0]=1;aa=(math.pi*m)**2+(.5+2*math.pi*k)**2+1;nb=len(m);n=nb+66;V=np.zeros((nb,66));EE=np.zeros((66,66));Mr=np.zeros((66,66));P=np.eye(n);P[:nb,:nb]=np.diag(1/np.sqrt(aa));B0=np.zeros((33,n));B1=B0.copy()
  for j,pk in enumerate(range(-16,17)):
    qq=math.sqrt(1+(.5+2*math.pi*pk)**2);den=-np.expm1(-2*qq);ct=(1+math.exp(-2*qq))/den;cs=2*math.exp(-qq)/den;ids=np.flatnonzero(k==pk);rr=np.arange(2*j,2*j+2);cc=np.column_stack([cm[ids],cm[ids]*(-1.)**m[ids]]);V[np.ix_(ids,rr)]=cc;ee=np.array([[ct,cs],[cs,ct]])/qq;EE[np.ix_(rr,rr)]=ee;tail=ee-cc.T@(cc/aa[ids,None]);ri=np.linalg.inv(np.linalg.cholesky((tail+tail.T)/2).T);P[np.ix_(ids,nb+rr)]=-(cc/aa[ids,None])@ri;P[np.ix_(nb+rr,nb+rr)]=ri
    Mr[np.ix_(rr,rr)]=[[ct/(2*qq**3)+cs**2/(2*qq**2),ct*cs/(2*qq**2)+cs/(2*qq**3)],[ct*cs/(2*qq**2)+cs/(2*qq**3),ct/(2*qq**3)+cs**2/(2*qq**2)]]
    B0[j,ids]=cm[ids];B1[j,ids]=cm[ids]*(-1.)**m[ids];B0[j,nb+rr]=[ct/qq,cs/qq];B1[j,nb+rr]=[cs/qq,ct/qq]
  Hraw=np.block([[np.diag(aa),V],[V.T,EE]]);MV=V/aa[:,None];Mraw=np.block([[np.eye(nb),MV],[MV.T,Mr]]);ap=abs(P);HB=float(np.linalg.norm(ap.T@abs(Hraw)@ap,1));MB=float(np.linalg.norm(ap.T@abs(Mraw)@ap,1));BB=max(math.sqrt(np.linalg.norm(abs(B)@ap,1)*np.linalg.norm(abs(B)@ap,np.inf)) for B in [B0,B1]);return dict(H_absolute_envelope=HB,M1_absolute_envelope=MB,B_absolute_envelope=BB,Pnorm1=float(np.linalg.norm(P,1)),Pnorminf=float(np.linalg.norm(P,np.inf)))
genv=core_gram_envelopes()

# D: actual moment absolute sums plus material/boundary product envelopes.
d=jread(base/'output'/a.core_run/'science/result.json');asm=d['assembly'];n=d['dimension'];lam=5.6169;cw=d['c_W'];materr=d['material']['rounding_normalized_estimate'];emap=3*lam/cw*(materr+g(16*n)*asm['material_envelope']);ebound=g(16*n)*asm['squared_factor_envelope'];esolver=10*n*u*d['norm_center']+10*d['residual_L'];analytic_Gram=g(8*n+200)*(genv['H_absolute_envelope']+(lam+1)/cw*genv['M1_absolute_envelope'])+g(500)*2*genv['B_absolute_envelope']*max(asm['leftnorm1'],asm['rightnorm1'])*math.sqrt(asm['Bleftnorm1']*asm['Bleftnorminf']);local=emap+ebound+esolver+analytic_Gram+g(100)*(1+asm['Qnorm1']/cw+asm['Bnorm1'])
# Input DtN perturbations in trace norm: ||trace||_energy^2 <= coth(1).
incoming=1/math.tanh(1)*sum(x['eLambda_scaled'] for x in Cdata);hdef=d['H_defect']*(1+asm['Qnorm1']/cw+asm['Bnorm1']);etotal=local+incoming+hdef
Dinputs={'dimension':n,'center_norm1':d['norm_center'],'epsilon_truncation':d['epsilon'],'absolute_material_envelope':asm['material_envelope'],'absolute_boundary_envelope':asm['squared_factor_envelope'],'curve_rounding_normalized':materr,'curve_path':d['material']['rounding_path'],'local_rounding':local,'incoming_C':incoming,'H_identity_effect':hdef,'solver_estimate':esolver,'analytic_Gram_effect':analytic_Gram,'Gram_envelopes':genv,'total':etotal}
row('D','D-count','核心第二方向与负惯性1',d['safe_margin'],etotal,'3*lambda/cW*(moment_error+gamma_(16*n)*abs_material)+gamma_(16*n)*abs_boundary+10*n*u*norm1+10*resL+coth(1)*(eLambda_left+right)+Hdef_effect+analytic_Gram_effect',Dinputs,f'output/{a.core_run}/science/result.json')
row('D','D-near-shift','近贴边shift后的第二方向',d['gamma_2']-d['verified_gamma_lower'],etotal,'同D-count；margin=lambda2-shift，LDL枢轴只作诊断',dict(Dinputs,pivot=d['shifted_min_abs_pivot'],shift=d['verified_gamma_lower']),f'output/{a.core_run}/science/result.json')
row('D','D-wide-shift','0.36移位后的第二方向',d['gamma_2']-.36-d['epsilon'],etotal,'同D-count；margin=lambda2-0.36-epsilon',dict(Dinputs,wide_pivot=d['wide_pivot']),f'output/{a.core_run}/science/result.json')
row('D','D-printed-gamma','原打印第二下端0.365373688',d['gamma_2']-d['epsilon']-.365373688,etotal,'lambda2-epsilon-printed_gamma 对比同D-count估计',dict(Dinputs,printed_gamma=.365373688),f'output/{a.core_run}/science/result.json',role='printed')
row('D','D-first','核心负方向',abs(d['L_center_normalized_eigenvalues'][0]),etotal,'同D-count',Dinputs,f'output/{a.core_run}/science/result.json')
row('D','D-cW','补空间正分母cW',cw,g(500)*(1+23.4676*d['C_h']**2),'gamma_500*(1+qmax*Ch^2)',{'Ch':d['C_h'],'qmax':23.4676},f'output/{a.core_run}/science/result.json')
row('D','D-Gram','代表函数2阶余项Gram正性',d['tail_Gram_min'],g(5000)*max(1,asm['Pnorm1']*asm['Pnorminf']),'gamma_5000*max(1,norm1(P)*norminf(P))',{'Pnorm1':asm['Pnorm1'],'Pnorminf':asm['Pnorminf']},f'output/{a.core_run}/science/result.json')
row('D','D-epsilon','解析积分epsilon的末位',d['epsilon'],g(10000)*d['epsilon'],'gamma_10000*epsilon',{'epsilon':d['epsilon']},f'output/{a.core_run}/science/result.json',role='printed-component')
extras['D']=Dinputs
# qj: positive sums, polynomial absolute moments, and residual cancellation.
q=old('qj-cert-v2','run-004','interface-certificate.json');c=old('qj-cert-v2','run-004','certificates.json');f=jread(base/'output'/a.qj_run/'science/estimate-data.json');E=np.mean(q['full_interval']['E']);M=np.mean(q['M']);Sup=q['S_upper'];s=q['full_interval']['s'];ne=sum(t['triangles']*(len(t['cells']) if isinstance(t['cells'],list) else 1) for t in f['inventory']['templates']);ntmax=max(t['triangles'] for t in f['inventory']['templates']);ZE=sum(t[3] for t in f['field_coeff_scales']);ZM=sum(t[4] for t in f['field_coeff_scales']);poly=f['triangle_integrals'];sumE=g(256+ntmax+13+3)*E;sumM=g(256+ntmax+13+3)*M
absE=poly['E'][0];absSpoly=poly['S'][0];gaussE=duffy16*sum(t['E_affine'] for t in c['templates'])+20*gx16*ZE;gaussM=duffy16*M+16*gx16*ZM;roundE=sumE+2*g(500)*math.sqrt(E*ZE)+g(10000)*absE+gaussE
arcbase=repo/'test/numerical-directions/qj-cert-v2/output/run-004/science';Cabs=0;biasabs=0;geomC=0;minD0=math.inf
for name in ['left','center','right']:
  ar=list(csv.DictReader((arcbase/(name+'-mass-arcs.csv')).open()));Cabs+=sum(abs(float(x['C0'])) for x in ar);biasabs+=sum(abs(float(x['bias'])) for x in ar);jump=3 if name=='center' else 16;ed=g(200)*.4;edp=g(200)*.4*6*(2*math.pi/320);
  for x in ar:
    V=float(x['V']);L=float(x['L']);D0=float(x['D0']);D1=float(x['D1']);Q1=float(x['Q1']);minD0=min(minD0,D0);geomC+=jump*(V*V*((Q1+.5*D1)*ed+1.5*D0*edp)+2*V*L*ed*D0*(Q1+.5*D1))
roundC=g(10000+ne)*Cabs+geomC;biasround=(g(10000)+3*g(200)*.4/minD0)*q['mass_bias'];roundM=sumM+2*g(500)*math.sqrt(M*ZM)+roundC+biasround+gaussM
# A factor 10 on the four-angle sample extrapolation is explicitly heuristic.
zetaInt=f['interface_large_terms_squared']*80*10;etaInt=g(10000)*math.sqrt(zetaInt);Sint=q['S_interface_upper'];rSint=2*math.sqrt(Sint)*etaInt+etaInt**2+g(10000)*abs(f['pm_integrals'][0])*80*10
zetaCommon=4*(E/s**2+17*(1-1/s)**2*M)+f['flux_absolute_terms_squared'];etaCommon=(g(1000)+100*gx16)*math.sqrt(zetaCommon);rScommon=2*math.sqrt(c['S_smooth'][1])*etaCommon+etaCommon**2+g(10000)*absSpoly+g(256+ntmax+13+3)*c['S_smooth'][1];roundS=rScommon+rSint
obj=jread(base/'output/object-sizes.json');conversionE=2*math.sqrt(E*obj['gradient_change_squared'])+obj['gradient_change_squared'];conversionM=2*math.sqrt(M*obj['mass_change_squared'])+obj['mass_change_squared'];hgeo=math.sqrt(7.731665818420395e-6);geoE=2*E*max(z['actual_geometry_node_error'] for z in obj['field_conversion'])/hgeo;phaseE=2*math.sqrt(E*M)*obj['phase_error']/hgeo;objectE=conversionE+geoE+phaseE;objectM=conversionM+2*max(z['actual_geometry_node_error'] for z in obj['field_conversion'])*math.sqrt(E*M);object_eta=math.sqrt(obj['gradient_change_squared'])/s+math.sqrt(M)*obj['phase_error']/hgeo+math.sqrt(E)*max(z['actual_geometry_node_error'] for z in obj['field_conversion'])/hgeo/s;objectS=2*math.sqrt(Sup)*object_eta+object_eta**2;arithmetic_errors=[roundE,roundM,roundS];roundE+=objectE;roundM+=objectM;roundS+=objectS
QI={'E':E,'M':M,'S':Sup,'s':s,'n_elements':ne,'nmax':ntmax,'ZE':ZE,'ZM':ZM,'absolute_E_poly_moments':absE,'absolute_S_poly_moments':absSpoly,'absolute_C0_arcs':Cabs,'positive_sum_path':256+ntmax+13+3,'evaluation_path':500,'poly_path':10000,'interface_zeta_probe':f['interface_large_terms_squared'],'sample_expansion':80,'sample_safety':10,'interface_zeta_extrapolated':zetaInt,'common_zeta':zetaCommon,'arithmetic_errors':arithmetic_errors,'gauss_E_effect':gaussE,'gauss_M_effect':gaussM,'gauss_node_working':gx16,'gauss_weight_working':gw16,'Duffy_weight_effect':duffy16,'object_E_effect':objectE,'object_M_effect':objectM,'object_S_effect':objectS,'nodal_conversion_E_effect':conversionE,'nodal_conversion_M_effect':conversionM,'geometry_E_effect':geoE,'phase_E_effect':phaseE,'sumE':sumE,'sumM':sumM,'roundE':roundE,'roundM':roundM,'roundC0':roundC,'curve_defect_C0_effect':geomC,'curve_defect_min_D0':minD0,'mass_bias_rounding':biasround,'roundScommon':rScommon,'roundSinterface':rSint,'roundS':roundS}
for key,value,margin,estimate,formula in [('E',E,(q['full_interval']['E'][1]-q['full_interval']['E'][0])/2,roundE,'gamma_sum*E+2*gamma_500*sqrt(E*ZE)+gamma_10000*abs_E_poly+gauss_E_effect+object_E_effect'),('M',M,(q['M'][1]-q['M'][0])/2,roundM,'gamma_sum*M+2*gamma_500*sqrt(M*ZM)+gamma_(10000+n_elements)*abs_C0+curve_defect_C0_effect+mass_bias_rounding+gauss_M_effect+object_M_effect'),('Scommon',c['S_smooth'][1],c['S_smooth'][1],rScommon,'2*sqrt(Scommon)*etaCommon+etaCommon^2+gamma_10000*abs_Spoly+gamma_sum*Scommon'),('Sinterface',Sint,Sint,rSint,'2*sqrt(Sint)*etaInt+etaInt^2+gamma_10000*abs_pm*80*10'),('Splus',Sup,Sup,roundS,'eScommon+eSinterface+object_S_effect'),('C0',c['mass_correction']['C0'],abs(c['mass_correction']['C0']),roundC,'gamma_(10000+n_elements)*sum(abs(C0_arc))+curve_defect_C0_effect'),('mass-bias',q['mass_bias'],9.4e-12-q['mass_bias'],biasround,'(gamma_10000+3*gamma_200*0.4/minD0)*bias')]:
  row('qj','qj-'+key,key+'数值',margin,estimate,formula,dict(QI,value=value),'qj-cert-v2/output/run-004/science/interface-certificate.json; '+f'output/{a.qj_run}/science/estimate-data.json',role='accuracy' if key in ['E','M'] else 'printed')
qq=1+E/M;eq=roundE/M+E*roundM/M**2;jj=Sup/M+2/s-qq/s**2;ej=roundS/M+Sup*roundM/M**2+eq/s**2+g(30)*(Sup/M+2/s+qq/s**2);de0=(Sup/M-2*(qq-s)/s**2)/M;dm0=-E/M**2*(Sup/M-2*(qq-s)/s**2)-qq*Sup/M**2;ds0=qq/M;delta=qq*Sup/M-(qq-s)**2/s**2;edelta=abs(de0)*roundE+abs(dm0)*roundM+ds0*roundS+g(100)*(qq*Sup/M+(qq-s)**2/s**2)
row('qj','qj-q','q=1+E/M',qq,eq,'eE/M+E*eM/M^2',dict(QI,q=qq),'qj/four_corners.m:9',role='printed')
row('qj','qj-J','J的重组数值',jj,ej,'eS/M+S*eM/M^2+eq/s^2+gamma_30*sum(abs(terms))',dict(QI,q=qq,eq=eq),'research/explorations/numerical-directions/qj-bounds-proof.md:118',role='printed')
row('qj','qj-delta','稳定delta严格正性',delta,edelta,'abs(d_delta/dE)*eE+abs(d_delta/dM)*eM+(q/M)*eS+gamma_100*abs_terms',dict(QI,gradient=[de0,dm0,ds0]),'qj/four_corners.m:9')

# Whole-domain geometry decisions and all inverse/branch tests are summarized by minimum margins.
geodet=min(t['geometry']['native_det_min'] for t in c['templates']);h=math.sqrt(geodet);geomcond=.5/h;geomerr=g(1000)*geomcond;selfmargin=min(t['min_selfmap_margin'] for t in q['templates']);branchmargin=min(t['min_actual_branch_margin'] for t in q['templates'])
for key,margin,effect in [('Jacobian',geodet,geodet*geomerr),('native-injectivity',1-max(t['geometry']['native_eta_max'] for t in c['templates']),geomerr),('fitted-injectivity',1-max(t['geometry']['fitted_eta_max'] for t in c['templates']),geomerr),('inverse-selfmap',selfmargin,g(10000)*geomcond),('branch-coverage',branchmargin,g(10000)*geomcond)]:
  row('qj','qj-'+key,key,margin,effect,'gamma_path*(0.5/sqrt(detmin))*scale',{'detmin':geodet,'coordinate_scale':.5,'h_estimate':h,'geometry_path':1000,'inverse_path':10000,'scale':geodet if key=='Jacobian' else 1},'qj-cert-v2/output/run-004/science/certificates.json/templates.geometry; interface-certificate.json/templates')
rp=f['reciprocal_tests'];row('qj','qj-reciprocal','倒数模型已接受分支正性',min(rp[1:3]),g(10000)*(.5/hgeo),'gamma_10000*(0.5/hgeo)',{'min_d0':rp[0],'min_1_minus_k':rp[1],'min_lo_over_d0':rp[2],'accepted_calls':rp[3],'rejected_calls':rp[4],'hgeo':hgeo},f'output/{a.qj_run}/science/estimate-data.json/reciprocal_tests')
# Derivatives use exact double inputs; alpha constants are the original float expressions.
mu=arb(float(1.32**2+1));nu=arb(float(2.37**2+1));sb=arb(float(s));Sb=arb(float(Sup));corners=[]
for ie,e0 in enumerate(q['full_interval']['E']):
  for im,m0 in enumerate(q['M']):
    e=arb(float(e0));m=arb(float(m0));qq=1+e/m;delta=qq*Sb/m-(qq-sb)**2/sb**2;qe=1/m;qm=-e/m**2;de=qe*Sb/m-2*(qq-sb)*qe/sb**2;dm=qm*Sb/m-qq*Sb/m**2-2*(qq-sb)*qm/sb**2;ds=qq/m
    ci={'corner':[ie,im]}
    for key,t in [('L',nu),('U',mu)]:
      den=qq-t-t*delta;F=qq-1+qq*t*delta/den;Fq=1-t*t*delta*(1+delta)/den**2;Fd=qq*t*(qq-t)/den**2;grad=[Fq*qe+Fd*de,Fq*qm+Fd*dm,Fd*ds];effect=sum(float(abs(v).upper())*err for v,err in zip(grad,[roundE,roundM,roundS]));ci[key]={'value':F.str(45),'value_float':float(F.mid()),'gradient':[v.str(35) for v in grad],'estimated_shift':effect,'round_formula_evaluation':g(100)*float(abs(F).upper())}
    sqrtv=(delta+delta*delta/4).sqrt()
    for key,sgn in [('I1L',-1),('I1U',1)]:
      val=qq*(1+delta/2+sgn*sqrtv)-1;Fq=1+delta/2+sgn*sqrtv;Fd=qq*(arb(.5)+sgn*(1+delta/2)/(2*sqrtv));grad=[Fq*qe+Fd*de,Fq*qm+Fd*dm,Fd*ds];effect=sum(float(abs(v).upper())*err for v,err in zip(grad,[roundE,roundM,roundS]));ci[key]={'value':val.str(45),'value_float':float(val.mid()),'gradient':[v.str(35) for v in grad],'estimated_shift':effect}
    # Linear twelve signs, including input uncertainty and arithmetic evaluation.
    for key,t in [('Dmu',mu),('minusDnu',nu)]:
      coeff=[t/sb**2,1-2*t/sb+t/sb**2,-t];val=coeff[0]*e+coeff[1]*m+coeff[2]*Sb
      if key=='minusDnu':val=-val
      ef=sum(float(abs(v).upper())*er for v,er in zip(coeff,[roundE,roundM,roundS]));scale=sum(float(abs(v*z).upper()) for v,z in zip(coeff,[e,m,Sb]));ef+=g(30)*scale
      row('qj',f'qj-sign-{key}-{ie}{im}',f'角{ie}{im} {key}',float(val.mid()),ef,'sum(abs(linear_coeff)*[eE,eM,eS])+gamma_30*sum(abs(term))',{'coefficients':[str(v) for v in coeff],'error_inputs':[roundE,roundM,roundS],'absolute_term_sum':scale},'qj/four_corners.m:8')
    coeff=[mu*nu/sb**2-1,mu+nu-1-mu*nu*(2/sb-1/sb**2),-mu*nu];val=coeff[0]*e+coeff[1]*m+coeff[2]*Sb;ef=sum(float(abs(v).upper())*er for v,er in zip(coeff,[roundE,roundM,roundS]));scale=sum(float(abs(v*z).upper()) for v,z in zip(coeff,[e,m,Sb]));ef+=g(50)*scale
    row('qj',f'qj-sign-H-{ie}{im}',f'角{ie}{im} H',float(val.mid()),ef,'sum(abs(linear_coeff)*[eE,eM,eS])+gamma_50*sum(abs(term))',{'coefficients':[str(v) for v in coeff],'error_inputs':[roundE,roundM,roundS],'absolute_term_sum':scale},'qj/four_corners.m:8')
    corners.append(ci)
width=float(jread(repo/'test/numerical-directions/qj-cert-v2/output/run-004/analysis.json')['scalar_decimal']['width']);iwidth=2.4287788271067-2.4286785150759
endpoint={}
for key in ['L','U','I1L','I1U']:
  worst=max(corners,key=lambda z:z[key]['estimated_shift']);active=(min if key.endswith('L') else max)(corners,key=lambda z:z[key]['value_float']);effect=worst[key]['estimated_shift']+g(100)*abs(active[key]['value_float']);endpoint[key]=dict(active[key],estimated_shift=effect,active_corner=active['corner'],sensitivity_corner=worst['corner'],relative_to_own_width=effect/(width if key in ['L','U'] else iwidth),relative_to_main_width=effect/width)
  row('qj','qj-end-'+key,key+'端点',width if key in ['L','U'] else iwidth,effect,'abs(dF/dE)*eE+abs(dF/dM)*eM+abs(dF/dS)*eS',endpoint[key],'qj/four_corners.m:10；本次高精度敏感度',role='printed')
extras['qj']=QI;extras['corners']=corners;extras['endpoints']=endpoint
# Auxiliary printed B3 quantities: the main chain uses the monotonic K instead.
for run in ['run-010','run-011']:
  b=old('h-cert-v1',run);test=b['tests'][-1];record=next(z for z in Brecords if z['run']==run);eg=record['assembly_estimate'];rel=eg/test['gamma']+g(1000);rt=g(8*b['dimension']+b['phase_panels']*b['phase_gauss_order']+8*b['curve_points'])*b['gram_cancellation_ratio'];inputs={'gamma':test['gamma'],'gamma_effect':eg,'relative_inverse_effect':rel,'relative_Gram_effect':rt,'B_inverse':test['B_inverse'],'T_squared':test['T_squared'],'d_per':b['d_per'],'lambda':b['lambda']}
  for key in ['B_inverse','T_squared','d_half','K_half','K_coarse']:
    relative=rel if key in ['B_inverse','K_coarse'] else (rt if key=='T_squared' else rel+rt);value=test[key];row('B',f'B3-{run}-{key}',f"旧B3 a={b['material']} {key}",abs(value),abs(value)*relative,'abs(value)*(e_gamma/gamma+gamma_path*kappa)，T_squared仅用后项',dict(inputs,value=value,relative_effect=relative),f'h-cert-v1/output/{run}/science/result.json/tests[-1]',role='optional-printed')
for end,lam0 in [('lower',1.7424),('upper',5.6169)]:
  for M0 in [8,10]:
    b=old('h-cert-v1','run-009' if end=='lower' else 'run-010');v=next(t for t in b['tests'] if t['M']==M0)['tail']['penalty'];row('B',f'B-tail-penalty-{end}-{M0}',f'{end} M={M0} x²/t数值',v,g(1000)*v,'gamma_1000*x^2/t',{'value':v,'path':1000},f"h-cert-v1/output/{'run-009' if end=='lower' else 'run-010'}/science/result.json/tests/tail",role='printed-component')
for cs,side,run in zip(Cdata,['left','right'],['run-006','run-008']):
  cert=jread(repo/f'test/numerical-directions/h-dtn-v1/{side}-certificate.json');power=cert['series']['power_norm'];f0=jread(base/'output'/cs['source_run']/'science/result.json');p2=f0['transfer_norm'];row('C',f'C-{side}-contraction',side+' P^128收缩',1-power,g(8*192*128)*192*max(1,p2)**128,'gamma_(8*192*128)*192*max(1,norm2(P))^128',{'power_norm':power,'Pnorm2':p2,'dimension':192},f'h-dtn-v1/{side}-certificate.json/series')
  ge=cert['geometry'];row('C',f'C-{side}-geometry',side+' 全域几何单射',1-max(ge['max_eta'],ge['max_physical_eta']),g(1000)*.5/math.sqrt(ge['min_det']),'gamma_1000*0.5/sqrt(detmin)',ge,f'h-dtn-v1/{side}-certificate.json/geometry')
  d0=old('h-dtn-v1',run);qmax=float(max(np.sqrt(1+(.5+2*math.pi*np.arange(-16,17))**2)));row('C',f'C-{side}-raw-Lambda',side+'原坐标最小特征值',d0['min_lower_raw'],qmax*cs['eLambda_scaled'],'qmax*eLambda_scaled',{'qmax':qmax,'scaled_error':cs['eLambda_scaled'],'raw_norm1':float(np.linalg.norm(np.array(d0['lower_real'])+1j*np.array(d0['lower_imag']),1))},f'h-dtn-v1/output/{run}/science/result.json',role='printed')
# Tiny scalar guards are distinct from the accuracy budgets of E and M.
kt=1+(arb(fmpq(56169,10000))+1)/arb(fmpq(949,40000));guard=float((arb(279.899894626)-kt).mid());kmt=(arb(fmpq(56169,10000))+1)/arb(fmpq(7749,2000))-1;guardm=float((arb(.70782)-kmt).mid())
row('handoffs','handoff-Kplus-guard','Kplus相对公式值的上取余量',guard,1e-11,'1e-11：包含lambda的ulp误差及除法；见标量分析',{'stored':279.899894626,'formula_value':kt.str(35)},'h-dtn-v1/dtn_run.m:22')
row('handoffs','handoff-Kminus-guard','Kminus相对公式值的上取余量',guardm,1e-14,'1e-14：包含lambda和端点距离的ulp误差',{'stored':.70782,'formula_value':kmt.str(35)},'h-dtn-v1/dtn_run.m:22')
row('qj','qj-M-positive','M下端严格为正',q['M'][0],roundM,'同M数值估计',QI,'qj-cert-v2/output/run-004/science/interface-certificate.json/M')
row('qj','qj-I1-window','I1处于窗口内部',min(2.4286785150759-1.7424,5.6169-2.4287788271067),max(endpoint[z]['estimated_shift'] for z in ['I1L','I1U']),'max(eI1L,eI1U)',{'window':[1.7424,5.6169]},'qj-cert-v2/output/run-004/analysis.json; draft/fem-goerisch/paper.tex:300')
for key,raw in [('L',2.4287286691978),('U',2.4287286736601)]:
  exact=jread(repo/'test/numerical-directions/qj-cert-v2/output/run-004/analysis.json')['scalar_decimal'][key];display=abs(float((arb(str(raw))-arb(exact)).mid()));row('handoffs','handoff-display-'+key,key+'简写十进制显示',width,display,'abs(displayed_endpoint-high_precision_endpoint)',{'display':raw,'reference':exact},'qj-cert-v2/output/run-004/analysis.json/scalar_decimal',role='printed')

# Remaining scalar/component handoffs are measured separately.
for key,val,eps in [('Kplus',279.899894626,1e-11),('Kminus',.70782,1e-15),('a_minus',1.7424,3e-16),('a_plus',5.6169,1e-15),('beta0',.5,0),('pi',math.pi,2e-16),('C_h',d['C_h'],g(100)*d['C_h']),('epsilon_D',d['epsilon'],g(10000)*d['epsilon'])]:
  row('handoffs','handoff-'+key,key+' full-precision交接',abs(val),eps,'显式标量误差估计；I/O保持原double，函数/常量误差另列',{'value':val,'assumed_effect':eps},('h-dtn-v1/dtn_run.m:22' if key in ['Kplus','Kminus'] else ('qj/qj_run.m:9' if key in ['a_minus','a_plus'] else ('core/rounding_scalars.m:5' if key in ['beta0','pi'] else 'output/run-007/science/result.json/'+('C_h' if key=='C_h' else 'epsilon')))),role='printed-component')
hd=jread(base/'output/handoff-checks.json')
for side,oldrun in [('left','run-006'),('right','run-008')]:
  cert=jread(repo/f'test/numerical-directions/h-dtn-v1/{side}-certificate.json')
  for name,parent,rkey in [('Q_minus','Q','eps_Q'),('R_plus','R','eps_R'),('Z_plus','Z','eps_Z')]:
    maxdiag=max(abs(cert[parent]['real'][i][i]) for i in range(33));ef=u*(maxdiag+cert[rkey]);row('handoffs',f'handoff-{side}-{name}',side+' '+name+'最后加减',cert[rkey],ef,'u*(max(abs(diag(parent)))+epsilon)',{'parent_maxdiag':maxdiag,'epsilon':cert[rkey],'observed':hd[side][name]['maximum_diagonal_operation_error']},f'h-dtn-v1/{side}-certificate.json; output/handoff-checks.json',role='accuracy')
for order in [10,16,24,40,77,104]:
  rule=gr[order];en=10*order*u;ew=100*order**2*u;row('handoffs',f'Gauss-{order}',f'Gauss{order} 节点/权重工作模型',1.,max(en,ew),'max(10*n*u,100*n^2*u)，前者节点绝对、后者权重相对',dict(rule,node_estimate=en,weight_relative_estimate=ew,calibration='下游取实测差的2倍作工作输入'),f'output/gauss-checks.json/order={order}',role='printed-component')

# Observation checks use the fixed-matrix solver and positive-sum components only.
obs=jread(base/'output/run-006/observations.json');Aobs=obs['A'];ar=next(x for x in panel_rows if x['panel']==int(Aobs['panel_info'][0]) and x['material']==.2 and x['endpoint']=='lower');eA=ar['solver'];eD=esolver;observed={'A_fixed_matrix':{'observed':Aobs['observed_difference'],'estimate':eA,'pass':Aobs['observed_difference']<eA},'D_fixed_matrix':{'observed':obs['D']['observed_difference'],'vector_effect':obs['D']['Rayleigh_vector_effect_estimate'],'estimate':eD,'pass':obs['D']['observed_difference']+obs['D']['Rayleigh_vector_effect_estimate']<eD}}
for key,v in obs['sums'].items():
  estimate=g(v['count'])*v['absolute_sum'];ob=max(v['observed_errors'].values());observed[key]={'observed':ob,'estimate':estimate,'pass':ob<estimate}
for n0 in [16,77]:
  rule=gr[n0]
  for label,ob,ee in [('node',rule['max_node_absolute_error'],10*n0*u),('weight_relative',rule['max_weight_relative_error'],100*n0*n0*u)]:observed[f'Gauss{n0}_{label}']={'observed':ob,'estimate':ee,'pass':ob<ee}

ref=jread(base/'output/band-python-reference.json');repro={'A_python_relative_difference':abs(ref['min_lower_negative_margin']/1.3972238392e-4-1),'A_MATLAB_relative_difference':abs(float(min(tab[:,4]))/1.3972238392e-4-1),'D_relative_difference':abs(d['gamma_2']/0.3653736908439648-1)}
result={'description':'rounding error estimates, not reliable bounds','unit_roundoff':u,'rows':rows,'extras':extras,'observations':observed,'reproduction':repro,'smallest_ratio':min((r for r in rows if r['ratio'] is not None),key=lambda x:x['ratio'])}
(base/'output/estimates.json').write_text(json.dumps(result,ensure_ascii=False,indent=2,default=lambda z:z.item())+'\n')
with (base/'output/estimates.csv').open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows({**r,'inputs':json.dumps(r['inputs'],ensure_ascii=False)} for r in rows)
with (base/'output/A-panel-estimates.csv').open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(panel_rows[0]));w.writeheader();w.writerows(panel_rows)
print(json.dumps({'rows':len(rows),'smallest':result['smallest_ratio'],'qj':QI,'endpoints':endpoint,'observations':observed,'reproduction':repro},ensure_ascii=False,indent=2,default=lambda z:z.item()))
