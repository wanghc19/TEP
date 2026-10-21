#!/bin/zsh
# Launch one create-once v6 builder/evaluator run with hard wall/RSS monitors.
# Usage: run_residual_numerator_v6.sh REPO_ROOT EXP_DIR ARTIFACT CURVE INPUT RESULT LOG RESOURCE AUDIT
set -eu

if [[ $# -ne 9 ]]; then
  print -u2 'Expected 9 explicit path arguments.'
  exit 64
fi
repo_root=$1
experiment_dir=$2
artifact_path=$3
curve_path=$4
input_path=$5
result_path=$6
run_log=$7
resource_log=$8
audit_log=$9
for target in "$input_path" "$result_path" "$run_log" "$resource_log" "$audit_log"; do
  if [[ -e "$target" ]]; then
    print -u2 "Create-once target exists: $target"
    exit 65
  fi
done

quote_matlab() {
  print -r -- "$1" | sed "s/'/''/g"
}
repo_q=$(quote_matlab "$repo_root")
experiment_q=$(quote_matlab "$experiment_dir")
artifact_q=$(quote_matlab "$artifact_path")
curve_q=$(quote_matlab "$curve_path")
input_q=$(quote_matlab "$input_path")
result_q=$(quote_matlab "$result_path")
audit_q=$(quote_matlab "$audit_log")
batch="addpath('$repo_q'); addpath('$experiment_q'); diary('$audit_q'); \
fprintf('MATLAB=%s\\n',version); \
disp(checkcode(fullfile('$experiment_q','build_residual_numerator_input_v6.m'),'-id')); \
disp(checkcode(fullfile('$experiment_q','signed_local_center_v6.m'),'-id')); \
disp(checkcode(fullfile('$experiment_q','signed_regular_image_v6.m'),'-id')); \
disp(checkcode(fullfile('$experiment_q','signed_off_surface_v6.m'),'-id')); \
disp(checkcode(fullfile('$experiment_q','signed_wall_center_v6.m'),'-id')); \
disp(checkcode(fullfile('$experiment_q','residual_numerator_v6.m'),'-id')); \
build_residual_numerator_input_v6('$artifact_q','$curve_q','$input_q'); \
load('$input_q','experiment_input'); \
fprintf('SELECT L=%d high=%.17g pass=%d N=%d local=%.17g pass=%d\\n', \
experiment_input.configuration.residual_mode_cutoff, \
experiment_input.cutoff_selection.numerator_contribution(experiment_input.cutoff_selection.selected_index), \
experiment_input.cutoff_selection.tightness_pass, \
experiment_input.configuration.evaluation_node_count, \
experiment_input.evaluation_selection.numerator_contribution(experiment_input.evaluation_selection.selected_index), \
experiment_input.evaluation_selection.tightness_pass); clear experiment_input; \
result=residual_numerator_v6('$input_q','$result_q'); \
fprintf('Bwall=%.17g Bmat=%.17g Blift=%.17g Mideal=%.17g phase=%s\\n', \
result.B_Gamma_pm_ideal,result.B_Upsilon_ideal,result.B_lift_ideal, \
result.M_ideal,result.phase_gate.decision); diary off"

start_epoch=$(date +%s)
hard_seconds=2695
hard_rss_kib=3145728
maximum_tree_rss_kib=0
(
  /usr/bin/time -l /Applications/MATLAB_R2023b.app/bin/matlab -batch "$batch"
) >"$run_log" 2>"$resource_log" &
launch_pid=$!

tree_pids() {
  local parent=$1
  print -- "$parent"
  local child
  for child in $(pgrep -P "$parent" 2>/dev/null || true); do
    tree_pids "$child"
  done
}

while kill -0 "$launch_pid" 2>/dev/null; do
  now_epoch=$(date +%s)
  elapsed=$((now_epoch - start_epoch))
  rss_kib=0
  for pid in $(tree_pids "$launch_pid"); do
    value=$(ps -o rss= -p "$pid" 2>/dev/null | tr -d ' ' || true)
    if [[ -n "$value" ]]; then
      rss_kib=$((rss_kib + value))
    fi
  done
  if (( rss_kib > maximum_tree_rss_kib )); then
    maximum_tree_rss_kib=$rss_kib
  fi
  if (( elapsed >= hard_seconds || rss_kib >= hard_rss_kib )); then
    print -u2 "HARD_STOP elapsed_seconds=$elapsed tree_rss_kib=$rss_kib"
    process_snapshot=($(tree_pids "$launch_pid" | sort -rn))
    for pid in "${process_snapshot[@]}"; do
      kill -TERM "$pid" 2>/dev/null || true
    done
    sleep 2
    for pid in "${process_snapshot[@]}"; do
      kill -KILL "$pid" 2>/dev/null || true
    done
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
elapsed=$(($(date +%s) - start_epoch))
print -- "watchdog_status=COMPLETE exit_status=$run_exit_code elapsed_seconds=$elapsed maximum_tree_rss_kib=$maximum_tree_rss_kib" >>"$resource_log"
exit "$run_exit_code"
