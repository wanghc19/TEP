"""Assemble the floating B0 budget from this run's explicit numerical outputs.
Input: --run directory. Output: budget.json and compact tables in that directory.
All theory inequalities are proposals, and all arithmetic here is floating point.
"""
import argparse,csv,importlib.util,json
from pathlib import Path
import numpy as np
from scipy.optimize import minimize
from scipy.spatial import cKDTree
spec=importlib.util.spec_from_file_location('geo',Path(__file__).with_name('geometry_budget.py'));geo=importlib.util.module_from_spec(spec);spec.loader.exec_module(geo)

def weighted(eps,polys,cs,lam0):
    e=np.asarray(eps)/1e-12;p=np.asarray(polys);w0=e/np.asarray(cs);w0/=np.exp(np.mean(np.log(w0)))
    def objective(logw):
        w=np.exp(np.r_[logw,0]);v,at=geo.supremum(w@p,lam0)
        return v*np.sum(e*e/w)
    x0=np.log(w0[:-1]/w0[-1]);op=minimize(objective,x0,method='Nelder-Mead',options={'maxiter':20000,'xatol':1e-10,'fatol':1e-12})
    ws=np.exp(np.r_[op.x,0]);v,at=geo.supremum(ws@p,lam0)
    initial=np.sqrt(objective(x0))*1e-12
    return dict(Q=float(np.sqrt(v*np.sum(e*e/ws))*1e-12),weights=ws.tolist(),lambda_max=at,initial=initial,optimizer_success=bool(op.success))

def main():
    pa=argparse.ArgumentParser();pa.add_argument('--run',required=True);a=pa.parse_args();out=Path(a.run)
    r=json.loads((out/'result.json').read_text());g=json.loads((out/'geometry.json').read_text());assert r['frozen_unchanged']
    wallrows=[]
    for x in r['wall_grid']:
        d={k:x[k] for k in ['source_center','source_negative','source_positive','target']}
        for k in ['left','right','negative','positive']:
            for v in ['value_squared','normal_squared']:d[k+'_'+v]=x[k][v]
        wallrows.append(d)
    with (out/'wall-grid.csv').open('w') as f:
        writer=csv.DictWriter(f,fieldnames=list(wallrows[0]));writer.writeheader();writer.writerows(wallrows)
    def wall(ns,nt):return next(x for x in r['wall_grid'] if x['source_center']==ns and x['target']==nt)
    x=wall(768,768);y=wall(1536,768);z=wall(768,1536);y1=wall(1536,1536);y2=wall(3072,1536)
    wa={'source_doubling_at_target768':{k:y[k]['normal_squared']/x[k]['normal_squared']-1 for k in ['left','right']},'target_doubling_at_source768':{k:z[k]['normal_squared']/x[k]['normal_squared']-1 for k in ['left','right']},'last_source_doubling_at_target1536':{k:y2[k]['normal_squared']/y1[k]['normal_squared']-1 for k in ['left','right']},'junction_distances':{}}
    for wallx in ['-0.5','0.5']:
        wa['junction_distances'][wallx]={name:g['groups'][name]['port_distances'][wallx][j] for name,j in [('center',0),('negative',1),('positive',2)]}
    (out/'wall-analysis.json').write_text(json.dumps(wa,indent=2))
    groups=[]
    for name,key in [('center','center'),('negative','negative'),('positive','positive')]:
        x=r['material'][key];groups.append(dict(name=name,value=x['value_squared'],normal=x['normal_squared'],**g['groups'][name]['used']))
    w=r['walls_selected'];v=sum(w[k]['value_squared'] for k in ['left','right','negative','positive']);n=sum(w[k]['normal_squared'] for k in ['left','right','negative','positive'])
    groups.append(dict(name='walls',value=v,normal=n,**g['groups']['walls']['used']))
    seam=r['seams'];v=sum(seam[k]['value_squared'] for k in ['center','negative','positive']);n=sum(seam[k]['normal_squared'] for k in ['center','negative','positive'])
    groups.append(dict(name='seams',value=v,normal=n,**g['groups']['seams']['used']))
    for x in groups:x['eps']=float(np.sqrt(x['value']+x['normal']));x['Q']=x['C']*x['eps']
    total=sum(x['eps']**2 for x in groups);Qsingle=9.578*np.sqrt(total);Qgrp=sum(x['Q'] for x in groups)
    qw=weighted([x['eps'] for x in groups],[x['poly'] for x in groups],[x['C'] for x in groups],.25/17)
    qwzero=weighted([x['eps'] for x in groups],[x['poly'] for x in groups],[x['C'] for x in groups],0)
    assert qw['Q']<=Qgrp*(1+1e-10)
    samples=np.genfromtxt(out/'center-jump-samples.csv',delimiter=',',names=True)
    segments=[]
    for x in g['segments']:
        mask=np.mod(samples['t']-x['t0'],2*np.pi)<(x['t1']-x['t0'])
        y=x.copy();y['value']=float(np.sum(samples['weight'][mask]*samples['value_squared_density'][mask]));y['normal']=float(np.sum(samples['weight'][mask]*samples['normal_squared_density'][mask]));y['eps']=np.sqrt(y['value']+y['normal']);y['Q']=y['C']*y['eps'];segments.append(y)
    assert abs(sum(x['value'] for x in segments)/groups[0]['value']-1)<1e-13
    assert abs(sum(x['normal'] for x in segments)/groups[0]['normal']-1)<1e-13
    Qseg=sum(x['Q'] for x in segments);Qgrpseg=Qgrp-groups[0]['Q']+Qseg
    mass=r['mass'];sel=np.asarray(mass['selected']);centers=sel[:,1:3].copy();centers[:,0]+=np.array([0,-1,1])[sel[:,0].astype(int)-1]
    pairs=np.linalg.norm(centers[:,None]-centers[None,:],axis=2)-sel[:,3,None]-sel[None,:,3];np.fill_diagonal(pairs,np.inf)
    geomclear=[]
    for ci,name in enumerate(['center','negative','positive'],1):
        mask=sel[:,0]==ci
        zz=geo.curve(name,np.arange(65536)*2*np.pi/65536)[0]
        geomclear.extend((cKDTree(zz).query(sel[mask,1:3])[0]-sel[mask,3]).tolist())
    mass['checks']={'minimum_pair_gap':float(pairs.min()),'minimum_material_clearance':min(geomclear),'minimum_cell_clearance':float(np.min(.5-np.abs(sel[:,1:3])-sel[:,3,None])),'Q6_64_128_relative':abs(mass['multi_Q6_64']/mass['multi_Q6_128']-1),'Q6_Q5_min_relative':float(np.min(sel[:,9]/sel[:,7]-1))}
    assert min(mass['checks'][k] for k in ['minimum_pair_gap','minimum_material_clearance','minimum_cell_clearance'])>0
    Us={'U_reference':mass['reference_U'],'Q5_best':mass['multi_Q5'],'Q6_best':mass['multi_Q6_128']}
    budget=[]
    for un,u in Us.items():
        allow=2.5e-9*u/(2*geo.MU+2.5e-9)
        for qn,q in [('Q_single',Qsingle),('Q_grp',Qgrp),('Q_w',qw['Q'])]:
            budget.append(dict(U_name=un,U=u,Q_name=qn,Q=q,Q_allow=allow,margin=allow/q,W=4*geo.MU*q/(u-q)))
    result=dict(groups=groups,segments=segments,eps=float(np.sqrt(total)),seam_share=groups[-1]['eps']**2/total,Q_single=float(Qsingle),Q_grp=float(Qgrp),Q_w=qw,Q_w_lambda0_zero=qwzero,center_segment_Q=float(Qseg),center_segment_effective_C=float(Qseg/groups[0]['eps']),Q_grp_segmented=float(Qgrpseg),budget=budget,mass=mass,baseline=r['baseline'],settings=r['settings'])
    (out/'budget.json').write_text(json.dumps(result,indent=2))
    for filename,rows,fields in [('groups.csv',groups,['name','value','normal','eps','delta','kappa','eta','C','Q']),('segments.csv',segments,['index','t0','t1','arclength','kappa','delta_limit','delta','C','value','normal','eps','Q']),('budget.csv',budget,['U_name','U','Q_name','Q','Q_allow','margin','W'])]:
        with (out/filename).open('w') as f:
            wr=csv.DictWriter(f,fieldnames=fields,extrasaction='ignore');wr.writeheader();wr.writerows(rows)
    print(json.dumps({k:result[k] for k in ['eps','seam_share','Q_single','Q_grp','Q_w','center_segment_Q','center_segment_effective_C','Q_grp_segmented']},indent=2))
    print('mass:', {k:mass[k] for k in ['single_best_Q5','multi_Q5','multi_Q6_64','multi_Q6_128','original_disk_Q5','original_disk_quadrature']})
    print('budget:',budget)
if __name__=='__main__':main()
