#!/bin/zsh
# Launch one create-once I5 v8 run with the 40-minute/2-GiB hard contract.
# Usage: script REPO EXP ARTIFACT CURVE INPUT RESULT LOG RESOURCE AUDIT
set -eu
if [[ $# -ne 9 ]]; then
  print -u2 'Expected 9 explicit path arguments.'
  exit 64
fi
repo_root=$1; experiment_dir=$2; artifact_path=$3; curve_path=$4
input_path=$5; result_path=$6; run_log=$7; resource_log=$8; audit_log=$9
for source_path in "$artifact_path" "$curve_path"; do
  [[ -f "$source_path" ]] || { print -u2 "Missing input: $source_path"; exit 66; }
done
for target in "$input_path" "$result_path" "$run_log" "$resource_log" "$audit_log"; do
  [[ ! -e "$target" ]] || { print -u2 "Create-once target exists: $target"; exit 65; }
  [[ -d "${target:h}" ]] || { print -u2 "Missing target directory: ${target:h}"; exit 67; }
done

quote_matlab() { print -r -- "$1" | sed "s/'/''/g"; }
repo_q=$(quote_matlab "$repo_root"); experiment_q=$(quote_matlab "$experiment_dir")
artifact_q=$(quote_matlab "$artifact_path"); curve_q=$(quote_matlab "$curve_path")
input_q=$(quote_matlab "$input_path"); result_q=$(quote_matlab "$result_path")
audit_q=$(quote_matlab "$audit_log")
batch="addpath('$repo_q'); addpath('$experiment_q'); diary('$audit_q'); \
fprintf('MATLAB=%s\\n',version); \
disp(checkcode(fullfile('$experiment_q','build_residual_numerator_input_v8.m'),'-id')); \
disp(checkcode(fullfile('$experiment_q','signed_local_center_v8.m'),'-id')); \
disp(checkcode(fullfile('$experiment_q','signed_regular_image_v8.m'),'-id')); \
disp(checkcode(fullfile('$experiment_q','signed_off_surface_v8.m'),'-id')); \
disp(checkcode(fullfile('$experiment_q','residual_numerator_v8.m'),'-id')); \
build_residual_numerator_input_v8('$artifact_q','$curve_q','$input_q'); \
load('$input_q','experiment_input'); \
fprintf('SELECT N=%d radius=%.17g tight=%d noCandidateCenters=%d\\n', \
experiment_input.source_selection.selected_N, \
experiment_input.source_selection.selected_radius, \
experiment_input.source_selection.tightness_pass, \
~experiment_input.source_selection.candidate_centers_evaluated); \
clear experiment_input; \
result=residual_numerator_v8('$input_q','$result_q'); \
fprintf('BGamma=%.17g BUpsilon=%.17g Blift=%.17g Mideal=%.17g gates=%d\\n', \
result.B_Gamma_pm_ideal,result.B_Upsilon_ideal,result.B_lift_ideal, \
result.M_ideal,result.gate_audit.pass); diary off"

start_epoch=$(date +%s)
hard_seconds=2395
hard_rss_kib=2097152
maximum_tree_rss_kib=0
(
  /usr/bin/time -l /Applications/MATLAB_R2023b.app/bin/matlab -batch "$batch"
) >"$run_log" 2>"$resource_log" &
launch_pid=$!

tree_pids() {
  local parent=$1 child
  print -- "$parent"
  for child in $(pgrep -P "$parent" 2>/dev/null || true); do
    tree_pids "$child"
  done
}

while kill -0 "$launch_pid" 2>/dev/null; do
  elapsed=$(($(date +%s)-start_epoch))
  rss_kib=0
  for pid in $(tree_pids "$launch_pid"); do
    value=$(ps -o rss= -p "$pid" 2>/dev/null | tr -d ' ' || true)
    [[ -z "$value" ]] || rss_kib=$((rss_kib+value))
  done
  (( rss_kib>maximum_tree_rss_kib )) && maximum_tree_rss_kib=$rss_kib
  if (( elapsed>=hard_seconds || rss_kib>=hard_rss_kib )); then
    snapshot=($(tree_pids "$launch_pid" | sort -rn))
    for pid in "${snapshot[@]}"; do kill -TERM "$pid" 2>/dev/null || true; done
    sleep 2
    for pid in "${snapshot[@]}"; do kill -KILL "$pid" 2>/dev/null || true; done
    wait "$launch_pid" || true
    print -- "watchdog_status=HARD_STOP elapsed_seconds=$elapsed maximum_tree_rss_kib=$maximum_tree_rss_kib" >>"$resource_log"
    exit 124
  fi
  sleep 2
done

set +e
wait "$launch_pid"
run_exit_code=$?
set -e
elapsed=$(($(date +%s)-start_epoch))
print -- "watchdog_status=COMPLETE exit_status=$run_exit_code elapsed_seconds=$elapsed maximum_tree_rss_kib=$maximum_tree_rss_kib" >>"$resource_log"
exit "$run_exit_code"
