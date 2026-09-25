#!/bin/bash
# Run one MATLAB command while recording and enforcing the I7 process budget.
set -u

if [ "$#" -ne 2 ]; then
  echo "usage: $0 RUN_DIR MATLAB_EXPRESSION" >&2
  exit 2
fi

run_dir="$1"
matlab_expression="$2"
# Use MATLAB from PATH unless MATLAB_BIN selects another executable.
matlab_bin="${MATLAB_BIN:-matlab}"
resource_csv="$run_dir/resources.csv"
run_log="$run_dir/run.log"
command_file="$run_dir/command.txt"
snapshot="$run_dir/ps-current.txt"
status_file="$run_dir/monitor-status.txt"
rss_limit_bytes=3000000000
wall_limit_seconds=1800
sample_seconds=0.25

mkdir -p "$run_dir"
if [ -e "$resource_csv" ] || [ -e "$run_log" ]; then
  echo "monitor output already exists in $run_dir" >&2
  exit 2
fi

printf '%q -batch %q\n' "$matlab_bin" "$matlab_expression" > "$command_file"
printf 'utc,elapsed_seconds,tree_rss_bytes,all_matlab_rss_bytes,tree_cpu_percent\n' > "$resource_csv"
start_epoch=$(date +%s)
start_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
"$matlab_bin" -batch "$matlab_expression" > "$run_log" 2>&1 &
root_pid=$!
termination="process exited"

while kill -0 "$root_pid" 2>/dev/null; do
  now_epoch=$(date +%s)
  elapsed=$((now_epoch-start_epoch))
  if ! ps -axo pid=,ppid=,rss=,%cpu=,comm= > "$snapshot"; then
    termination="process monitoring failed"
    kill -TERM "$root_pid" 2>/dev/null || true
    sleep 5
    kill -KILL "$root_pid" 2>/dev/null || true
    break
  fi
  read -r tree_kib all_matlab_kib tree_cpu tree_pids <<EOF
$(awk -v root="$root_pid" '
  { pid[NR]=$1; ppid[$1]=$2; rss[$1]=$3; cpu[$1]=$4; cmd[$1]=$5 }
  END {
    member[root]=1; changed=1;
    while (changed) {
      changed=0;
      for (i=1;i<=NR;i++) if (member[ppid[pid[i]]] && !member[pid[i]]) {
        member[pid[i]]=1; changed=1;
      }
    }
    tree=0; total=0; tcpu=0; pids="";
    for (i=1;i<=NR;i++) {
      p=pid[i];
      if (member[p]) { tree+=rss[p]; tcpu+=cpu[p]; pids=pids " " p }
      lower=tolower(cmd[p]); if (lower ~ /matlab/) total+=rss[p];
    }
    printf "%.0f %.0f %.3f %s\n",tree,total,tcpu,pids;
  }' "$snapshot")
EOF
  tree_bytes=$((tree_kib*1024))
  all_matlab_bytes=$((all_matlab_kib*1024))
  printf '%s,%d,%d,%d,%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$elapsed" "$tree_bytes" "$all_matlab_bytes" "$tree_cpu" >> "$resource_csv"
  if [ "$tree_bytes" -ge "$rss_limit_bytes" ]; then
    termination="RSS hard limit reached"
    kill -KILL $tree_pids 2>/dev/null || true
    break
  fi
  if [ "$elapsed" -ge "$wall_limit_seconds" ]; then
    termination="wall-time hard limit reached"
    kill -TERM $tree_pids 2>/dev/null || true
    sleep 5
    kill -KILL $tree_pids 2>/dev/null || true
    break
  fi
  sleep "$sample_seconds"
done

wait "$root_pid"
exit_code=$?
end_epoch=$(date +%s)
end_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
peak_tree=$(awk -F, 'NR>1 && $3>m {m=$3} END {print m+0}' "$resource_csv")
peak_all=$(awk -F, 'NR>1 && $4>m {m=$4} END {print m+0}' "$resource_csv")
{
  printf 'start_utc=%s\n' "$start_utc"
  printf 'end_utc=%s\n' "$end_utc"
  printf 'wall_seconds=%d\n' "$((end_epoch-start_epoch))"
  printf 'exit_code=%d\n' "$exit_code"
  printf 'termination=%s\n' "$termination"
  printf 'peak_tree_rss_bytes=%s\n' "$peak_tree"
  printf 'peak_all_matlab_rss_bytes=%s\n' "$peak_all"
} > "$status_file"
exit "$exit_code"
