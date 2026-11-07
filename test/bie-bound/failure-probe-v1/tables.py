"""Extract scalar tables from explicit experiment run directories.
Inputs are monitor and case JSON files; outputs are CSV tables with one header row.
These summaries never feed a scientific calculation.
"""
import argparse
import csv
import json
from pathlib import Path

from plan_followups import measured


def make(runs, dest):
    tables={}
    def row(table, **values):
        tables.setdefault(table,[]).append(values)
    def pair(v, field, i):
        val=v.get(field)
        return val[i] if val and len(val)>i else None
    for run, job, result in measured(runs):
        key=dict(run=run,case=job['label'],model=job['model'],N=job['N'],M=job['M'],beta=job['beta'],
                 L0=job.get('L0') if job['model']=='edge' else None,cut=job.get('cuts',[0,0])[1],
                 small=bool(job.get('small')))
        action=job['action']
        def point(table,v,**kwargs):
            dat=dict(key,beta=v.get('beta',key['beta']),**kwargs)
            dat.update({f:v.get(f) for f in ('status','stage','identifier','message','k','ratio','sigma','sigma_max','gamma_min','port_cond','center_A_rcond')})
            for f in ('D_min','D_rcond','lead_A_rcond','extract_norm','lead_status'):
                for i, side in enumerate(('left','right')):
                    dat[f+'_'+side]=pair(v,f,i)
            for f in ('ratio','sigma','next'):
                dat['amplitude_'+f]=v.get('amplitude',{}).get(f)
            row(table,**dat)
        if action in ('search','scan','amplitude-scan'):
            candidates=result.get('candidates' if action=='search' else 'roots') or []
            observed_status=result['status']
            if (result.get('identifier')=='MATLAB:UndefinedFunction'
                    and any(e['name']=='LOCAL_schedule' and e['line']==68 for e in result.get('stack',[]))):
                observed_status='OBSERVATION_LIMIT_REPORTER_ERROR'
            provisional=result.get('provisional',[])
            if isinstance(provisional,dict):provisional=[provisional]
            row('counts',**key,provisional=' '.join(format(v['k'],'.17g') for v in provisional),method=action,lo=job['window'][0],hi=job['window'][1],samples=job.get('count') if action!='search' else result.get('counts',{}).get('determinant'),status=observed_status,count=len(candidates) if action!='search' or observed_status in ('COMPLETE','CANDIDATES_COMPLETE_WITH_UNRESOLVED_FALLBACK') else '',roots=' '.join(format(v['k'],'.17g') for v in candidates),ratios=' '.join('%.5g'%v.get('aphys_ratio',v.get('ratio')) for v in candidates),message=result.get('message'),seconds=result['seconds'])
            if 'subset_evidence' in job:
                link=job['subset_evidence']
                parent=json.loads((runs/link['run']/link['case']/'summary.json').read_text())
                seq=parent['rows'][link['first']:link['last']+1]
                assert seq[0]['k']==job['window'][0] and seq[-1]['k']==job['window'][1]
                roots=[v for v in parent['roots'] if seq[0]['k']<v['k']<seq[-1]['k']]
                assert all(seq[0]['k']<v['bracket'][0] and v['bracket'][1]<seq[-1]['k'] for v in roots)
                row('counts',**dict(key,run=link['run'],case=link['case']),method='scan_subset',
                    lo=seq[0]['k'],hi=seq[-1]['k'],samples=len(seq),status='REUSED_GRID_AND_MINIMA',
                    count=len(roots),roots=' '.join(format(v['k'],'.17g') for v in roots),
                    ratios=' '.join('%.5g'%v['ratio'] for v in roots),seconds=0)
            if action!='search':
                for v in result['minimums']:
                    point('scan-minima',v,accepted=v.get('ratio') is not None and v['ratio']<=1e-11)
                if 'cut_grid' in job:
                    for v in result['rows']:
                        point('window-grid',v)
        if action=='fallback-check':
            for iv in result.get('intervals',[]):
                row('fallback-replay',**key,global_status=result['status'],branch_status=iv['status'],
                    k=iv['k'],ratio=iv['aphys_ratio'],sigma=iv['aphys_sigma'],width=iv['W'],
                    confirmed=any(abs(v['k']-iv['k'])<3e-15 for v in result['candidates']))
        if action=='findcut':
            row('cuts',**key,side=job['side'],frequency=result['frequency'],mincut=result['domain'][0],maxcut=result['domain'][1],selected=result['cut'],sigma=result['sigma'],reference=result['reference_sigma'])
        if action=='points':
            for v in result['rows']:
                point('point-checks',v,detuning=v['k']-v['beta'])
                for j,sub in enumerate(v.get('subspace',[])):
                    row('stable-distances',**key,side=('left','right')[j],k=v['k'],**sub)
        if action=='woodtrace':
            for target in result['targets']:
                point('wood-branches',target['last'],detuning=target['offset'],finished=target['finished'])
        if action=='edge':
            for v in result['samples']:
                for j,sub in enumerate(v['point'].get('subspace',[])):
                    row('edge-subspaces',**key,side=('left','right')[j],edge=result['gap_side'],delta=v['offset'],k=v['point']['k'],**sub)
        if action in ('local','vectors'):
            for v in result['roots']:
                point('root-routes',v,route=action)
                for j,sub in enumerate(v.get('subspace',[])):
                    row('root-subspaces',**key,side=('left','right')[j],route=action,k=v['k'],**sub)
        if action=='edge-mode':
            if 'qz' in result:
                for route in ('qz','vectors'):
                    point('edge-roots',result[route],width=result['width'],route=route)
        if action in ('field','field-at','amplitude-field'):
            for v in result['roots']:
                dat=dict(key,action=action,k=v['k'],ratio=v.get('ratio'),status=v['status'],error=v.get('field_error',{}).get('message'),seconds=result['seconds'])
                field=v.get('field',{})
                for name in ('mass_by_cell','energy_by_cell'):
                    for j,cell in enumerate(('left','center','right')):
                        dat[name+'_'+cell]=pair(field,name,j)
                for name in ('xi_squared','energy_per_xi','energy_per_weighted_xi','mass_per_xi','material_L2','junction_rms','wall_rms','seam_rms','internal_row_jump','n_angle','n_radial'):
                    dat[name]=field.get(name)
                if field and sum(field['energy_by_cell'])>0 and field.get('wall_rms') is not None:
                    import math
                    scale=math.sqrt(sum(field['energy_by_cell']))
                    dat['material_per_energy_norm']=field['material_L2']/scale
                    dat['walls_per_energy_norm']=field['wall_rms']/scale
                dat['amplitude_ratio']=v.get('amplitude',{}).get('ratio')
                row('fields',**dat)
    for f in sorted(runs.glob('*/monitor.json')):
        r=json.loads(f.read_text());p=json.loads((f.parent/'preflight.json').read_text())
        row('cost',run=f.parent.name,seconds=r['wall_seconds'],peak_gib=r['peak_process_tree_rss_gib'],reason=r['reason'],outcome='stopped after duplicate confirmations' if r['returncode']==-15 and (f.parent/'cut192-near-det/accepted-so-far.json').exists() else r['reason'],exit=r['returncode'],other_jobs=len(p['numerical_jobs']))
    for name,records in tables.items():
        with (dest/(name+'.csv')).open('w', newline='') as f:
            w=csv.DictWriter(f,fieldnames=list(dict.fromkeys(k for record in records for k in record)));w.writeheader();w.writerows(records)


if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('runs',type=Path);ap.add_argument('table_directory',type=Path)
    a=ap.parse_args();a.table_directory.mkdir(exist_ok=True)
    make(a.runs,a.table_directory)
