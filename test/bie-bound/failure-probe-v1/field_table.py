"""Join physical measurements to the distinct frequencies in the candidate map.
Inputs: finalized case map and fields.csv. Output: paired checks for every candidate.
"""
import argparse
import csv
import json
from pathlib import Path


def main(casefile, fieldfile, out):
    cases=json.loads(casefile.read_text())
    with fieldfile.open() as f:
        records=list(csv.DictReader(f))
    with out.open('w', newline='') as f:
        writer=csv.writer(f)
        writer.writerow(['case','model','beta','L0','cut','small','min_k','max_k','origin',
                         'N','M','k_checked','status','mass_per_xi','E_per_xi','E_per_weighted_xi',
                         'material','walls','seams','internal','relative_material','relative_walls','source'])
        for i,b in enumerate(cases):
            cfg=b['case'];klist=[x[2] for x in b['values']]
            source=' '.join(x[3]+'/'+x[4] for x in b['values'])
            for run,tag in b['physical_records']:
                matches=[v for v in records if v['case']==tag and (run=='followup' or v['run']==run)]
                if not matches:
                    raise ValueError('Missing physical check: '+tag)
                v=matches[-1]; status=v['status'] if not v['error'] else v['error']
                writer.writerow([i,cfg['model'],cfg['beta'],cfg.get('L0',''),cfg.get('cuts',[0,0])[1],
                                 cfg.get('small',False),min(klist),max(klist),source,v['N'],v['M'],v['k'],status,
                                 *[v[k] for k in ('mass_per_xi','energy_per_xi','energy_per_weighted_xi',
                                                'material_L2','wall_rms','seam_rms','internal_row_jump',
                                                'material_per_energy_norm','walls_per_energy_norm')],v['run']+'/'+tag])


if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__)
    for k in ('cases','fields','table'):
        ap.add_argument(k,type=Path)
    a=ap.parse_args();main(a.cases,a.fields,a.table)
