"""Check the reported regression, confirmation, field coverage and monitor ledgers.
Input: explicit run and table directories and the candidate map. Output: scalar JSON.
"""
import argparse
import csv
import json
from pathlib import Path


def rows(path):
    with path.open() as f:
        return list(csv.DictReader(f))


def main(run_dir, table_dir, case_map, out):
    reg=json.loads((run_dir/'run-001/regression/summary.json').read_text())
    assert reg['status']=='COMPLETE' and len(reg['candidates'])==1
    diff=abs(reg['candidates'][0]['k']-1.558437894182088)
    assert diff<=2e-14
    comparisons=rows(table_dir/'comparison.csv')
    base=[r for r in comparisons if r['case'] in ('regression','base1','base2','base3','base4')]
    assert len(base)==5 and sum(int(r['scan_count']) for r in base)==6
    assert all(r['outcome']=='lists agree' for r in base)
    pole=rows(table_dir/'fallback-replay.csv')
    assert len(pole)==2 and all(r['confirmed']=='True' and float(r['ratio'])<1e-11 and float(r['sigma'])>.019 for r in pole)
    projected=[r for r in rows(table_dir/'counts.csv') if r['method']=='amplitude-scan']
    assert len(projected)==4 and all(r['count']=='1' for r in projected)
    root_change=max(abs(float(r['roots'])-reg['candidates'][0]['k']) for r in projected)
    fields=rows(table_dir/'candidate-checks.csv');cases=json.loads(case_map.read_text())
    assert {int(r['case']) for r in fields}==set(range(len(cases)))
    for i in range(len(cases)):
        selected=[r for r in fields if int(r['case'])==i]
        assert {int(r['N']) for r in selected}=={128,192}
    unavailable=[(r['case'],r['N'],r['status']) for r in fields if not r['E_per_xi'] or not r['walls']]
    cost=rows(table_dir/'cost.csv')
    assert all(r['other_jobs']=='0' and float(r['peak_gib'])<3 and float(r['seconds'])<1800 for r in cost)
    assert all(r['exit']=='0' or (r['exit']=='-15' and r['outcome']=='stopped after duplicate confirmations') for r in cost)
    exceptions=[r for r in comparisons if r['outcome']!='lists agree']
    report=dict(regression_hex=reg['candidates'][0]['k_hex'],regression_abs_diff=diff,
                baseline_windows=len(base),baseline_roots=6,
                max_baseline_scan_difference=max(float(r['max_nearest_difference']) for r in base),
                admitted_false_frequencies=[float(r['k']) for r in pole],
                max_projection_root_change=root_change,physical_cases=len(cases),physical_rows=len(fields),
                unavailable_fields=unavailable,compared_windows=len(comparisons),window_exceptions=exceptions,
                runs=len(cost),monitored_seconds=sum(float(r['seconds']) for r in cost),
                peak_gib=max(float(r['peak_gib']) for r in cost),
                any_other_job=any(r['other_jobs']!='0' for r in cost),
                field_mat_files=len(list(run_dir.rglob('*.mat'))))
    out.write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for k in ('runs','tables','case_map','output'):
        p.add_argument(k,type=Path)
    a=p.parse_args();main(a.runs,a.tables,a.case_map,a.output)
