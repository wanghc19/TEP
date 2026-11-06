"""Evaluation settings, independent of the exact field coefficients.
Input: CLI parameters at groups.py. Output: shared numerical choices.
"""
bits=128
nodes=48
panel_factor=1
center_panels=192
material_panels=64
wall_panels=16
seam_panels=8

def configure(precision=128,chebyshev=48,panels=1):
  global bits,nodes,panel_factor,center_panels,material_panels,wall_panels,seam_panels
  assert precision in [128,192] and chebyshev in [48,64] and panels in [1,2]
  bits=precision;nodes=chebyshev;panel_factor=panels
  center_panels=192*panels;material_panels=64*panels;wall_panels=16*panels;seam_panels=8*panels

def record():
  return dict(bits=bits,nodes=nodes,panel_factor=panel_factor,center_panels=center_panels,material_panels=material_panels,wall_panels=wall_panels,seam_panels=seam_panels,conversion_bits=192,local_degree=52,smooth_degree=nodes-1)
