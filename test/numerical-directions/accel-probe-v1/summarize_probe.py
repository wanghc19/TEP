"""Summarize existing probe JSON (JavaScript Object Notation) without MATLAB.

Input: run directory. Output: scalar summary and CSV (comma-separated values).
Only writes inside the supplied experiment run directory.
"""
import argparse
import csv
import json
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument("run", type=Path)
a = p.parse_args()
r = json.loads((a.run / "science/probe.json").read_text())
rows = r.get("rows", [])
if isinstance(rows, dict):
    rows = [rows]
columns = ["template", "name", "profiled", "seconds", "smooth_seconds",
           "sliver_seconds", "smooth_panels", "sliver_panels", "upper", "Q16",
           "excess", "excess_percent", "accuracy_pass", "internal_checks_pass"]
with (a.run / "sweep.csv").open("w") as f:
    w = csv.DictWriter(f, fieldnames=columns, extrasaction="ignore")
    w.writeheader()
    w.writerows(rows)
s = {"status": r["status"], "setup": r.get("setup"),
     "center_reproduction": r.get("center_reproduction"),
     "failure": r.get("failure"), "rows": rows}
if (a.run / "monitor.json").exists():
    s["monitor"] = json.loads((a.run / "monitor.json").read_text())
if "best" in r:
    best = r["best"]
    selected = [x for x in rows if x["name"] == best["name"] and not x["profiled"]]
    if {x["template"] for x in selected} == {"left", "center", "right"}:
        historical = {"left": 160.52566095833333, "center": 119.36791008333333,
                      "right": 181.412800625}
        st = sum(x["seconds"] for x in selected)
        su = sum(x["upper"] for x in selected)
        sq = sum(x["Q16"] for x in selected)
        s["three_templates"] = {
            "options": best["options"], "interface_seconds": st,
            "historical_speed_ratios": {x["template"]: historical[x["template"]]/x["seconds"] for x in selected},
            "upper": su, "Q16": sq, "excess": su-sq,
            "excess_percent": 100*(su-sq)/sq,
            "estimated_pipeline_seconds": 698.1347080833333-461.38779195833331+st,
            "S_only_width_excess_vs_Q16": 9.95*(su-sq),
            "S_only_width_change_vs_old_certificate": 9.95*(su-3.4977344096766215e-11),
            "S_only_relative_widening_vs_Q16": 9.95*(su-sq)/4.4623318373737675e-9,
            "S_only_relative_change_vs_old_certificate": 9.95*(su-3.4977344096766215e-11)/4.4623318373737675e-9,
        }
        cert = r["certificates"]
        mass_center = sum(cert["M"])/2
        mass_radius = (sum(x["mass_bias"] for x in selected)
                       + cert["mass_correction"]["integration_error"]
                       + cert["mass_correction"]["voluntary_halfwidth"]
                       + sum(x["M_taper_error"] for x in cert["templates"]))
        mass = [mass_center-mass_radius, mass_center+mass_radius]
        shift = r["baseline"]["q"]
        lo, hi = 1.32**2+1, 2.37**2+1
        total_residual = cert["S_smooth"][1]+su
        lower, upper, signs = [], [], []
        for e in cert["E"]:
            for m in mass:
                q = 1+e/m
                d = q*total_residual/m-(q-shift)**2/shift**2
                def F(t):
                    return q-1+q*t*d/(q-t-t*d)
                def D(t):
                    return (1-2*t/shift+t/shift**2)*m+t/shift**2*e-t*total_residual
                H = ((lo+hi-1-lo*hi*(2/shift-1/shift**2))*m
                     +(lo*hi/shift**2-1)*e-lo*hi*total_residual)
                lower.append(F(hi)); upper.append(F(lo))
                signs.append([H, D(lo), -D(hi)])
        s["three_templates"]["scalar_reassembly_with_new_mass_bias"] = {
            "M": mass, "S_upper": total_residual, "E": cert["E"],
            "s": shift, "mu": lo, "nu": hi, "signs": signs,
            "lower": min(lower), "upper": max(upper),
            "width": max(upper)-min(lower),
            "relative_width_change_vs_old": (max(upper)-min(lower))/4.4623318373737675e-9-1,
            "scope": "scalar postprocessing of existing certificates, rounding excluded",
        }
(a.run / "summary.json").write_text(json.dumps(s, indent=2))
print(json.dumps({k: v for k, v in s.items() if k != "rows"}, indent=2))
