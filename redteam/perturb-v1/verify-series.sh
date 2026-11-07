#!/bin/sh
# Run the supplied, pre-generated data sets in order through the package monitor.
# Arguments are Python, package, campaign, worker count, then run:data pairs.
set -eu
python=$1
package=$2
campaign=$3
workers=$4
shift 4
export BIE_STORAGE_ROOT="$campaign"
mkdir -p "$campaign/output"
for pair in "$@"; do
  id=${pair%:*}
  data=${pair#*:}
  run="$campaign/output/run-$id"
  log="$campaign/output/driver-$id.log"
  echo "Starting run-$id"
  if "$python" -B -I "$package/scripts/verify.py" --example ex1 \
      --workers "$workers" --data "$campaign/data/$data" --output "$run" >> "$log" 2>&1; then
    echo "Completed run-$id"
  else
    # A verifier assertion is a case outcome. Infrastructure or budget failures
    # must be inspected before another run can start.
    if [ -f "$run/failure.json" ] && [ -f "$run/end-to-end.json" ] && \
       "$python" -B -I - "$run" <<'PY'
import json
from pathlib import Path
import sys

run = Path(sys.argv[1])
monitors = [json.loads(p.read_text()) for p in run.rglob('monitor.json')]
assert monitors and all(m['reason'] == 'completed' for m in monitors)
errors = (run / 'failure.json').read_text()
for log in run.glob('*/run.log'):
  errors += log.read_text()
assert (any(s in errors for s in ['AssertionError', 'ArithmeticError', 'FiniteGate'])
        or ('unique_fmpz()' in errors and 'NoneType' in errors and 'TypeError' in errors))
PY
    then
      echo "Verifier stopped in run-$id"
    else
      tail -n 28 "$log"
      exit 1
    fi
  fi
done
