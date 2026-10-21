"""Plot saved I8 scan samples without solving or changing the frozen field.

Usage: python plot_i8.py RUN_DIR
Reads scan.csv/result.json and creates scan.png once. No historical input is
used by the numerical MATLAB entry; this is only a result-viewing utility.
"""

import csv
import json
from pathlib import Path
import subprocess
import sys


run = Path(sys.argv[1])
destination = run / "scan.png"
if destination.exists():
  raise SystemExit(f"Refusing to overwrite {destination}")
with (run / "scan.csv").open() as stream:
  rows = list(csv.DictReader(stream))
result = json.loads((run / "result.json").read_text())
good = [row for row in rows if row["valid"] == "1"]
screen = [row for row in good if row["stage"] == "screen"]
levels = sorted({int(row["level"]) for row in good if row["stage"] == "local"})
local = [row for row in good if int(row["level"]) == levels[-1]] if levels else screen
k0 = result["selected"]["k"]

wide_data = "\n".join(f"{row['k']} {row['aphys_ratio']}" for row in screen)
local_data = "\n".join(
  f"{(float(row['k'])-k0)*1e6:.17g} {row['aphys_ratio']} {row['aphys_sigma']}"
  for row in local)
script = f'''set terminal pngcairo size 1500,600 font "Helvetica,13"
set output {json.dumps(str(destination))}
$wide << EOD
{wide_data}
EOD
$local << EOD
{local_data}
EOD
set multiplot layout 1,2 title "I8 smooth star: sampled dip, not a position error bound"
set logscale y
set grid
set xlabel "k"
set ylabel "Aphys singular-value ratio"
set title "Fixed-configuration search"
set arrow from {k0},graph 0 to {k0},graph 1 nohead dt 2 lc rgb "red"
plot $wide using 1:2 with linespoints pt 7 ps 0.6 title "33-point scan"
unset arrow
set xlabel "(k - selected k) / 1e-6"
set ylabel "Value"
set title "Last completed local grid; selected k={k0:.9f}"
plot $local using 1:2 with linespoints pt 7 ps 0.6 title "ratio", \\
     $local using 1:3 with linespoints pt 5 ps 0.6 title "minimum singular value"
unset multiplot
'''
with (run / "plot.gp").open("x") as stream:
  stream.write(script)
subprocess.run(["gnuplot"], input=script, text=True, check=True)
print(destination)
