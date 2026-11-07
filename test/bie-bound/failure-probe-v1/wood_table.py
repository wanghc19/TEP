"""Pair fixed-phase root refinements and window searches with the Wood continuation.
Input: monitored runs. Output: one row per signed detuning and physical model.
"""
import argparse
import csv
from pathlib import Path

from plan_followups import measured


def main(runs, dest):
    cases=list(measured(runs))
    with dest.open('w',newline='') as f:
        writer=None
        for run,q,trace in cases:
            if q['action']!='woodtrace' or int(run[4:])<17:
                continue
            for z in trace['targets']:
                v=z['last'];beta=v['beta'];model=q['model']
                row=dict(model=model,delta=z['offset'],beta=beta,initial_k=v['k'],
                         port_condition=v['port_cond'],center_rcond=v.get('center_A_rcond'),
                         left_rcond=v.get('lead_A_rcond',[None,None])[0],
                         right_rcond=v.get('lead_A_rcond',[None,None])[1])
                for n in [128,192]:
                    name=str(n)
                    for key in ['k','ratio','imaginary_newton_step','status','official_roots','scan_roots']:
                        row[key+name]=''
                    for _,p,r in cases:
                        if p['model']!=model or p['N']!=n or p['beta']!=beta or 'cross' in p['label']:
                            continue
                        if p['action']=='local' and p['label'].endswith('-polish'):
                            root=r['roots'][0];row['k'+name]=root['k'];row['ratio'+name]=root.get('ratio')
                            if r['rows']:
                                row['imaginary_newton_step'+name]=r['rows'][-1]['step'][1]
                        if p['action']=='search':
                            row['status'+name]=r['status']
                            row['official_roots'+name]=' '.join(format(x['k'],'.17g') for x in r.get('candidates',[]))
                        if p['action']=='scan':
                            row['scan_roots'+name]=' '.join(format(x['k'],'.17g') for x in r.get('roots',[]))
                row['absolute_refinement_change']=abs(row['k128']-row['k192']) if row['k128'] and row['k192'] else ''
                if writer is None:
                    writer=csv.DictWriter(f,fieldnames=list(row));writer.writeheader()
                writer.writerow(row)


if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('runs',type=Path);ap.add_argument('csv',type=Path)
    a=ap.parse_args();main(a.runs,a.csv)
