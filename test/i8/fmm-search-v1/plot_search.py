#!/usr/bin/env python3
"""Render dependency-free SVG summaries from one completed I8.4 search."""

import csv
import html
import math
from pathlib import Path
import sys


def svg_text(x, y, value, size=11, anchor="start"):
  return (f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" '
          f'text-anchor="{anchor}" font-family="sans-serif">'
          f'{html.escape(value)}</text>')


def map_value(value, source_first, source_last, target_first, target_last):
  if source_last == source_first:
    return (target_first + target_last) / 2
  fraction = (value - source_first) / (source_last - source_first)
  return target_first + fraction * (target_last - target_first)


def write_curves(run_dir, evaluations, rounds):
  columns, rows_count = 4, math.ceil(len(rounds) / 4)
  panel_w, panel_h = 330, 225
  width, height = columns * panel_w, rows_count * panel_h
  body = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" '
          f'height="{height}" viewBox="0 0 {width} {height}">',
          '<rect width="100%" height="100%" fill="white"/>']
  for panel, round_row in enumerate(rounds):
    column, row = panel % columns, panel // columns
    x0, y0 = column * panel_w, row * panel_h
    left, right = x0 + 48, x0 + panel_w - 15
    top, bottom = y0 + 36, y0 + panel_h - 35
    points = [item for item in evaluations
              if item["round_index"] == round_row["round_index"]]
    logs = [math.log10(float(item["aphys_ratio"])) for item in points]
    low, high = min(logs), max(logs)
    pad = max(0.05, 0.08 * (high - low))
    low, high = low - pad, high + pad
    coords = []
    for index, score in enumerate(logs):
      x = map_value(index, 0, len(points) - 1, left, right)
      y = map_value(score, low, high, bottom, top)
      coords.append((x, y))
    path = " ".join(("M" if index == 0 else "L") +
                    f" {x:.2f} {y:.2f}"
                    for index, (x, y) in enumerate(coords))
    body.append(f'<path d="{path}" fill="none" stroke="#2457a7" '
                'stroke-width="1.5"/>')
    for x, y in coords:
      body.append(f'<circle cx="{x:.2f}" cy="{y:.2f}" r="2.2" '
                  'fill="#2457a7"/>')
    winner = int(round_row["winner_index"]) - 1
    wx, wy = coords[winner]
    body.append(f'<circle cx="{wx:.2f}" cy="{wy:.2f}" r="4" '
                'fill="none" stroke="#c92127" stroke-width="1.8"/>')
    body.append(f'<rect x="{left}" y="{top}" width="{right-left}" '
                f'height="{bottom-top}" fill="none" stroke="#777"/>')
    title = (f'r{round_row["round_index"]} {round_row["round_kind"]}; '
             f'W={float(round_row["actual_W"]):.3e}')
    body.append(svg_text(x0 + panel_w / 2, y0 + 18, title, 11, "middle"))
    body.append(svg_text(x0 + panel_w / 2, y0 + 31,
                         f'k*={float(round_row["winner_k"]):.17g}',
                         9, "middle"))
    body.append(svg_text(left - 5, top + 4, f'{high:.2f}', 9, "end"))
    body.append(svg_text(left - 5, bottom + 4, f'{low:.2f}', 9, "end"))
    label_x, label_y = x0 + 11, (top + bottom) / 2
    body.append(f'<text x="{label_x:.1f}" y="{label_y:.1f}" font-size="9" '
                f'text-anchor="middle" font-family="sans-serif" '
                f'transform="rotate(-90 {label_x:.1f} {label_y:.1f})">'
                'log10(aphys ratio)</text>')
    body.append(svg_text((left + right) / 2, bottom + 19,
                         'node index', 9, "middle"))
  body.append('</svg>')
  (run_dir / "curves-all.svg").write_text("\n".join(body) + "\n")


def write_trends(run_dir, rounds):
  width, height = 900, 650
  body = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" '
          f'height="{height}" viewBox="0 0 {width} {height}">',
          '<rect width="100%" height="100%" fill="white"/>']
  series = [
      ("actual full-grid width W", [float(r["actual_W"]) for r in rounds],
       [(2e-14, "target 2e-14")]),
      ("aphys ratio", [float(r["round_best"]) for r in rounds], []),
  ]
  for panel, (title, values, references) in enumerate(series):
    left, right = 85, width - 35
    top = 55 + panel * 305
    bottom = top + 225
    logs = [math.log10(value) for value in values]
    reference_logs = [math.log10(value) for value, _ in references]
    low = min(logs + reference_logs)
    high = max(logs + reference_logs)
    pad = max(0.1, 0.08 * (high - low))
    low, high = low - pad, high + pad
    coords = []
    for index, value in enumerate(logs):
      x = map_value(index, 0, len(values) - 1, left, right)
      y = map_value(value, low, high, bottom, top)
      coords.append((x, y))
    path = " ".join(("M" if index == 0 else "L") +
                    f" {x:.2f} {y:.2f}"
                    for index, (x, y) in enumerate(coords))
    body.append(f'<path d="{path}" fill="none" stroke="#2457a7" '
                'stroke-width="2"/>')
    for x, y in coords:
      body.append(f'<circle cx="{x:.2f}" cy="{y:.2f}" r="3" '
                  'fill="#2457a7"/>')
    for value, label in references:
      y = map_value(math.log10(value), low, high, bottom, top)
      body.append(f'<line x1="{left}" x2="{right}" y1="{y:.2f}" '
                  f'y2="{y:.2f}" stroke="#c92127" stroke-dasharray="6 4"/>')
      body.append(svg_text(right - 4, y - 5, label, 10, "end"))
    body.append(f'<rect x="{left}" y="{top}" width="{right-left}" '
                f'height="{bottom-top}" fill="none" stroke="#777"/>')
    body.append(svg_text((left + right) / 2, top - 18, title, 15, "middle"))
    body.append(svg_text((left + right) / 2, bottom + 27,
                         'round index', 11, "middle"))
    body.append(svg_text(left - 8, top + 4, f'{high:.2f}', 10, "end"))
    body.append(svg_text(left - 8, bottom + 4, f'{low:.2f}', 10, "end"))
    label_x, label_y = 24, (top + bottom) / 2
    body.append(f'<text x="{label_x:.1f}" y="{label_y:.1f}" font-size="10" '
                f'text-anchor="middle" font-family="sans-serif" '
                f'transform="rotate(-90 {label_x:.1f} {label_y:.1f})">'
                f'log10({html.escape(title)})</text>')
  body.append('</svg>')
  (run_dir / "trends.svg").write_text("\n".join(body) + "\n")


def main():
  if len(sys.argv) != 2:
    raise SystemExit("usage: plot_search.py RUN_DIR")
  run_dir = Path(sys.argv[1])
  with (run_dir / "evaluations.csv").open(newline="") as stream:
    evaluations = list(csv.DictReader(stream))
  with (run_dir / "rounds.csv").open(newline="") as stream:
    rounds = list(csv.DictReader(stream))
  write_curves(run_dir, evaluations, rounds)
  write_trends(run_dir, rounds)


if __name__ == "__main__":
  main()
