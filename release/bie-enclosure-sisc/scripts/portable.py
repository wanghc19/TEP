"""Make release metadata portable without changing scientific numbers.
Input: metadata object and explicit path substitutions. Output: portable object.
Only string values are rewritten; coefficient words and numeric values are kept.
"""
import re
from pathlib import Path

def clean(value, roots=()):
  if isinstance(value,dict):return {k:clean(v,roots) for k,v in value.items()}
  if isinstance(value,list):return [clean(v,roots) for v in value]
  if not isinstance(value,str):return value
  for path,label in sorted(roots,key=lambda x:len(str(x[0])),reverse=True):value=value.replace(str(path),label)
  # Catch historical machine paths in optional command records, never scientific numbers.
  prefixes=['/'+'Users/','/'+'home/','/'+'private/','/'+'var/folders/','/'+'Applications/']
  pattern='(?:'+'|'.join(re.escape(x) for x in prefixes)+r''')[^\s'";,\]\)<>]+'''
  return re.sub(pattern,'<EXTERNAL_PATH>',value)
