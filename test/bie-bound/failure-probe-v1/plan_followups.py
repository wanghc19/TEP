"""Make explicit follow-up plans from this experiment's measured candidate lists.
Input: source run directory and destination plan directory, passed on the command line.
Output: small plans only. The MATLAB solver reads the chosen plan as a scientific input.
"""
import argparse
import json
from pathlib import Path


def write(path, data):
    path.write_text(json.dumps(data, indent=2) + '\n')


def measured(src):
    for run in sorted(src.glob('run-*')):
        if not (run / 'plan.json').exists():
            continue
        for q in json.loads((run / 'plan.json').read_text()):
            if 'label' not in q:
                continue
            summary = run / q['label'] / 'summary.json'
            if summary.is_file():
                yield run.name, q, json.loads(summary.read_text())


def wood(src, dest):
    for run, q, data in measured(src):
        if q['action'] != 'woodtrace' or int(run[4:]) < 17:
            continue
        one = []
        cross = []
        fine = []
        for row in data['targets']:
            v = row['last']
            if not row['finished']:
                continue
            beta, k, delta = v['beta'], v['k'], row['offset']
            h = min(0.0025, 0.45 * abs(delta))
            for n, m in [(128, 6), (192, 12)]:
                base = dict(model=q['model'], N=n, M=m, beta=beta)
                tag = f"{q['model']}{delta:+g}-{n}"
                fine.append(dict(base, action='local',start=k,step=min(5e-7,h/20),label=tag+'-polish'))
                for action in (['search','scan'] if abs(delta)==.0001 or (delta==.01 and n==128) else []):
                    one.append(dict(base, window=[k-.83*h,k+1.17*h], action=action, label=tag+'-'+action, count=27))
                if delta == .0001:
                    for j, offsets in enumerate([[-.001,.001],[-.00131,.00191]]):
                        if q['model']=='w3' and j==1:
                            continue
                        # A centered window has an exact Wood evaluation. A skew
                        # window is more expensive; use one phase per guide.
                        for action in ['search','scan']:
                            cross.append(dict(base, window=[beta+x for x in offsets], action=action,
                                              label=f'{tag}-cross{j}-{action}', count=41))
        # Narrow one-sided searches normally finish on one Chebyshev panel.
        # Crossings can trigger the whole fallback tree; keep them separate.
        write(dest / f'polish-{q["model"]}.json',fine)
        for start in range(0,len(one),16):
            write(dest / f'follow-{q["model"]}-{start//16}.json', one[start:start+16])
        for start in range(0,len(cross),4):
            write(dest / f'cross-{q["model"]}-{start//4}.json', cross[start:start+4])


def matching_geometry(x,y):
    defaults={'small':False,'cuts':[0,0]}
    keys=['model','beta','N','M','small','cuts']
    if x['model']=='edge':
        keys.append('L0')
    return all(x.get(k,defaults.get(k))==y.get(k,defaults.get(k)) for k in keys)


def fields(src, dest):
    requests = {}
    cases = []
    existing=[]
    for run,q,data in measured(src):
        if q['action']=='field-at' or (run=='run-019' and q['action']=='field'):
            existing.append((q,data['roots'][0],run))
    for run, q, z in measured(src):
        action=q['action']
        if action in ('search','fallback-check'):
            cand=z.get('candidates',[]) or z.get('provisional',[])
            if isinstance(cand,dict):cand=[cand]
        elif action in ('scan','amplitude-scan','vectors','local'):
            cand=[v for v in z.get('roots',[]) if v.get('ratio') is not None and (v['ratio']<=1.e-11 or q['label'].endswith('-polish'))]
        elif action=='edge-mode' and z['status']=='MEASURED':
            q=dict(q,L0=z['width'])
            cand=[z[route] for route in ('qz','vectors') if z[route].get('ratio') is not None and z[route]['ratio']<=1.e-11]
        else:
            continue
        for v in cand:
            cfg={f:q[f] for f in ('model','beta','cuts','small') if f in q}
            if q['model']=='edge':
                cfg['L0']=q['L0']
            k=v['k']
            # Group candidates by geometry and frequency up to 1e-12. Within each
            # class use the actually returned production frequency at each grid.
            key=tuple(str(cfg.get(x,'')) for x in ('model','beta','cuts','small','L0'))
            found=next((b for b in cases if b['geom']==key and abs(k-b['start'])<=1e-12),None)
            if found is None:
                found=dict(geom=key,start=k,case=cfg,values=[])
                cases.append(found)
            found['values'].append((q['N'],q['M'],k,run,q['label'],action))
    for i,b in enumerate(cases):
        for n,m in [(128,6),(192,12)]:
            opts=sorted(b['values'], key=lambda r:(r[0]!=n,r[5]!='search',abs(r[1]-m)))
            k=opts[0][2]
            req=dict(b['case'], label=f'field-{i:03d}-{n}', action='field-at',N=n,M=m,start=k,amplitude=True)
            already=next(((old,run) for old,v,run in existing if matching_geometry(old,req)
                          and abs(v['k']-k)<=2e-14 and v.get('field')),None)
            if already:
                old,run=already
                b.setdefault('physical_records',[]).append([run,old['label']])
            else:
                requests[req['label']]=req
                b.setdefault('physical_records',[]).append(['followup',req['label']])
        b.pop('geom')
    write(dest/'candidate-map.json',cases)
    entries=list(requests.values())
    for start in range(0,len(entries),16):
        write(dest/f'fields-{start//16:02d}.json',entries[start:start+16])


if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('mode',choices=('wood','fields'))
    ap.add_argument('runs',type=Path)
    ap.add_argument('plans',type=Path)
    args=ap.parse_args()
    {'wood':wood,'fields':fields}[args.mode](args.runs,args.plans)
