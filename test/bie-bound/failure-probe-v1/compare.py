"""Compare the determinant and uniform singular-value scans on matched windows.
Input: the extracted counts.csv. Output: one CSV row per pair, including refusals.
"""
import argparse
import csv
import json
from pathlib import Path


def main(src, dest, cases_file=None):
    with src.open() as f:
        cases=list(csv.DictReader(f))
    scans=[v for v in cases if v['method'] in ('scan','scan_subset')]
    classes=json.loads(cases_file.read_text()) if cases_file else []
    def same(a,b):
        return (all(a[k]==b[k] for k in ('model','beta','cut','small','L0','N','M'))
                and abs(float(a['lo'])-float(b['lo']))<1e-14
                and abs(float(a['hi'])-float(b['hi']))<1e-14)
    def vals(s):
        return list(map(float,s.split()))
    with dest.open('w',newline='') as f:
        cols=['det_run','scan_run','case','status','scan_count','det_count','det_k','scan_k','max_nearest_difference','outcome','physical_case_ids','other_branch_ids_in_window']
        writer=csv.DictWriter(f,fieldnames=cols);writer.writeheader()
        for det in cases:
            if det['method']!='search':
                continue
            found=next((scan for scan in scans if same(det,scan)),None)
            if not found:
                continue
            d,s=vals(det['roots']),vals(found['roots'])
            diff=max((min(abs(x-y) for y in d) for x in s),default=0) if d and s else None
            if det['status'] not in ('COMPLETE','CANDIDATES_COMPLETE_WITH_UNRESOLVED_FALLBACK'):
                outcome=det['status'].lower()
            elif len(d)!=len(s):
                outcome='count differs'
            elif diff is not None and diff>1e-8:
                outcome='locations differ'
            else:
                outcome='lists agree'
            direct=[];context=[]
            for i,b in enumerate(classes):
                cfg=b['case']
                if any((r[3],r[4]) in [(det['run'],det['case']),(found['run'],found['case'])] for r in b['values']):
                    direct.append(i)
                elif (cfg['model']==det['model'] and cfg['beta']==float(det['beta'])
                      and cfg.get('cuts',[0,0])[1]==float(det['cut'])
                      and cfg.get('small',False)==(det['small']=='True')
                      and (cfg['model']!='edge' or cfg['L0']==float(det['L0']))
                      and float(det['lo'])<=b['start']<=float(det['hi'])):
                    context.append(i)
            writer.writerow(dict(zip(cols,[det['run'],found['run'],det['case'],det['status'],len(s),
                                           len(d) if det['status'] in ('COMPLETE','CANDIDATES_COMPLETE_WITH_UNRESOLVED_FALLBACK') else '',det['roots'],found['roots'],diff,outcome,' '.join(map(str,direct)),' '.join(map(str,context))])))


if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('counts',type=Path);ap.add_argument('output',type=Path)
    ap.add_argument('--case-map',type=Path)
    q=ap.parse_args();main(q.counts,q.output,q.case_map)
