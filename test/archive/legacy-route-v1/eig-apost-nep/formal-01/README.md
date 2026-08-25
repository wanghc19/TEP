# Superseded formal run

This run passed every numerical gate and reproduced byte-identically, but inspection found
that `levels.csv` contained a literal `\n` between its header and first data row. The
numeric content was unaffected. These artifacts are retained for audit and are superseded
by the final `output/` run after the CSV writer was corrected.

