"""Load supported release examples from explicit scientific parameter files.
Input: example name. Output: supported parameters and evaluation controls.
"""
import json
from pathlib import Path
NAMES=('ex1','ex2-L1','ex2-L1.6','ex2-L1.9','ex2-L2')
def load_case(name):
  if name not in NAMES:raise ValueError('Unsupported example: '+name)
  if name=='ex1':return dict(example=name)
  case=json.loads((Path(__file__).resolve().parent.parent/'examples'/(name+'.json')).read_text())
  assert case['example']==name
  return case
