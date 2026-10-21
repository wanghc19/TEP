#!/bin/bash
# Launch one complete I8.4b result from the package root with existing FMM2D.
set -eu
if [ "$#" -ne 1 ]; then
  echo "usage: bash test/i8/fmm-est-v1/launch.sh RUN_DIR" >&2
  exit 2
fi
run_dir="$1"
mkdir -p "$run_dir"
cp test/i8/fmm-est-v1/fmm_est_i8.m "$run_dir/source.m"
cp test/i8/fmm-est-v1/monitor.sh "$run_dir/monitor-source.sh"
cp test/i8/fmm-est-v1/launch.sh "$run_dir/launch-source.sh"
git -C test/i8/fmm-v1/vendor/fmm2d rev-parse HEAD > "$run_dir/fmm-commit.txt"
export MATLAB_BIN="${MATLAB_BIN:-/Applications/MATLAB_R2023b.app/bin/matlab}"
export OMP_NUM_THREADS=11
export OMP_DYNAMIC=FALSE
exec bash test/i8/fmm-est-v1/monitor.sh "$run_dir" "addpath(pwd); addpath('test/i8/fmm-est-v1'); addpath('test/i8/fmm-v1/vendor/fmm2d/matlab'); issues=checkcode(which('fmm_est_i8'),'-id'); save('$run_dir/checkcode.mat','issues','-v7'); fid=fopen('$run_dir/checkcode.json','w'); fprintf(fid,'%s\\n',jsonencode(issues,'PrettyPrint',true)); fclose(fid); [result,evidence]=fmm_est_i8(1.7562818500073423,'$run_dir');"
