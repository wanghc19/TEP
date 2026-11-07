#!/bin/sh
# C refit and verification with one aggregate process-tree and elapsed-time budget.
# Arguments are Python, package, campaign, MATLAB, FMM2D and scratch paths.
set -eu
python=$1
package=$2
campaign=$3
matlab=$4
fmm=$5
scratch=$6
run="$campaign/output/run-013"
export BIE_STORAGE_ROOT="$campaign"
# Check the monitor's process-list permission before it starts a child.
ps -axo pid=,ppid=,rss=,comm= >/dev/null
"$python" -B -I "$package/scripts/monitor.py" "$run" \
  "$python" -B -I "$campaign/refit.py" --package "$package" --matlab "$matlab" \
  --fmm "$fmm" --driver "$campaign" --source "$campaign/data/003" \
  --data "$campaign/data/012" --run "$run" --scratch "$scratch"
