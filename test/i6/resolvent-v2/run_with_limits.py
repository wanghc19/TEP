#!/usr/bin/env python3
"""Run one direct non-Fourier MATLAB evaluation under hard resource limits."""

import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time


WALL_LIMIT_SECONDS = 45 * 60
RSS_LIMIT_BYTES = 3_000_000_000
SAMPLE_SECONDS = 0.25


def matlab_quote(value):
    return str(value).replace("'", "''")


def process_tree_rss(root_pid):
    table = subprocess.run(
        ["ps", "-axo", "pid=,ppid=,rss="],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.splitlines()
    children = {}
    rss_kib = {}
    for line in table:
        fields = line.split()
        if len(fields) != 3:
            continue
        pid, parent, rss = map(int, fields)
        children.setdefault(parent, []).append(pid)
        rss_kib[pid] = rss
    pending = [root_pid]
    descendants = set()
    while pending:
        pid = pending.pop()
        if pid in descendants:
            continue
        descendants.add(pid)
        pending.extend(children.get(pid, []))
    return 1024 * sum(rss_kib.get(pid, 0) for pid in descendants), sorted(descendants)


def stop_group(process):
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        return
    process.wait()


def main():
    if len(sys.argv) != 7:
        raise SystemExit(
            "usage: run_with_limits.py MATLAB SOURCE_DIR REPO_ROOT CANDIDATE CURVE RUN_DIR"
        )
    matlab, source_dir, repo_root, candidate, curve, run_dir = map(
        Path, sys.argv[1:]
    )
    matlab = matlab.resolve()
    source_dir = source_dir.resolve()
    repo_root = repo_root.resolve()
    candidate = candidate.resolve()
    curve = curve.resolve()
    run_dir = run_dir.resolve()
    run_dir.mkdir(parents=True, exist_ok=True)
    source_snapshot = run_dir / "source"
    source_snapshot.mkdir()
    for name in (
        "resolvent_nonfourier_v1.m",
        "signed_local_center_nonfourier_v1.m",
        "signed_regular_image_nonfourier_v1.m",
        "signed_off_surface_nonfourier_v1.m",
        "signed_wall_l2_nonfourier_v1.m",
        "run_with_limits.py",
    ):
        shutil.copy2(source_dir / name, source_snapshot / name)
    prefs = run_dir / "prefs"
    task_tmp = run_dir / "tmp"
    prefs.mkdir(exist_ok=True)
    task_tmp.mkdir(exist_ok=True)
    paths = {
        "input_snapshot": run_dir / "input-snapshot.mat",
        "result": run_dir / "result.mat",
        "summary": run_dir / "summary.json",
        "log": run_dir / "run.log",
        "resource": run_dir / "resource.json",
        "samples": run_dir / "resource-samples.jsonl",
        "config": run_dir / "run-config.json",
    }
    for path in paths.values():
        if path.exists():
            raise SystemExit(f"create-once path exists: {path}")
    expression = (
        f"addpath('{matlab_quote(repo_root)}');"
        f"addpath('{matlab_quote(source_snapshot)}');"
        f"resolvent_nonfourier_v1('{matlab_quote(candidate)}',"
        f"'{matlab_quote(curve)}','{matlab_quote(paths['input_snapshot'])}',"
        f"'{matlab_quote(paths['result'])}','{matlab_quote(paths['summary'])}');"
    )
    command = [str(matlab), "-batch", expression]
    config = {
        "matlab": str(matlab),
        "source_snapshot": str(source_snapshot),
        "repository_dependency_root": str(repo_root),
        "candidate": str(candidate),
        "circle_contract": str(curve),
        "scientific_method": (
            "direct signed physical material rows with continuous source-tail balls "
            "and periodic analytic-trapezoid target remainder"
        ),
        "material_target_fourier_expansion": False,
        "material_evaluation_node_count": 1026,
        "material_parameter_strip_width": 0.2,
        "kernel_series_cutoff": 32,
        "cell_cutoff": 16,
        "wall_mode_cutoff": 256,
        "propagation_block_length": 32,
        "wall_limit_seconds": WALL_LIMIT_SECONDS,
        "rss_limit_bytes": RSS_LIMIT_BYTES,
        "rss_sample_seconds": SAMPLE_SECONDS,
        "command": command,
    }
    paths["config"].write_text(json.dumps(config, indent=2) + "\n")
    environment = os.environ.copy()
    environment["MATLAB_PREFDIR"] = str(prefs)
    environment["TMPDIR"] = str(task_tmp)
    start_wall = time.time()
    start_monotonic = time.monotonic()
    peak_rss = 0
    peak_pids = []
    termination = "completed"
    samples = 0
    with paths["log"].open("x") as log_file, paths["samples"].open("x") as sample_file:
        process = subprocess.Popen(
            command,
            cwd=source_snapshot,
            env=environment,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            start_new_session=True,
        )
        while process.poll() is None:
            elapsed = time.monotonic() - start_monotonic
            try:
                rss, pids = process_tree_rss(process.pid)
            except subprocess.SubprocessError:
                rss, pids = 0, []
            samples += 1
            sample_file.write(
                json.dumps(
                    {
                        "elapsed_seconds": elapsed,
                        "process_tree_rss_bytes": rss,
                        "process_ids": pids,
                    }
                )
                + "\n"
            )
            sample_file.flush()
            if rss > peak_rss:
                peak_rss, peak_pids = rss, pids
            if rss >= RSS_LIMIT_BYTES:
                termination = "rss_limit"
                stop_group(process)
                break
            if elapsed >= WALL_LIMIT_SECONDS:
                termination = "wall_limit"
                stop_group(process)
                break
            remaining = WALL_LIMIT_SECONDS - (time.monotonic() - start_monotonic)
            time.sleep(max(0, min(SAMPLE_SECONDS, remaining)))
        return_code = process.wait()
        if termination == "completed" and return_code != 0:
            termination = "process_error"
    finish_wall = time.time()
    resource = {
        "start_unix_seconds": start_wall,
        "finish_unix_seconds": finish_wall,
        "elapsed_seconds": time.monotonic() - start_monotonic,
        "return_code": return_code,
        "termination": termination,
        "process_tree_peak_sampled_rss_bytes": peak_rss,
        "peak_sample_process_ids": peak_pids,
        "sample_interval_seconds": SAMPLE_SECONDS,
        "sample_count": samples,
        "rss_measurement_note": "sampled process-tree RSS; not an exact continuous OS peak",
        "wall_limit_seconds": WALL_LIMIT_SECONDS,
        "rss_limit_bytes": RSS_LIMIT_BYTES,
    }
    paths["resource"].write_text(json.dumps(resource, indent=2) + "\n")
    print(json.dumps(resource, indent=2))
    if termination != "completed" or return_code != 0:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
