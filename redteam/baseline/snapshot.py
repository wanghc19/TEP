#!/usr/bin/env python3
"""Record optional file-integrity provenance; never consumed by MATLAB."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

records = []
for root in ['/Users/whc/Documents/Work/TEP', '/Users/whc/Documents/Work/epost']:
  paths = subprocess.check_output(
    ['git', '-C', root, 'ls-files', '-z', '--cached', '--others', '--exclude-standard'])
  for relative in sorted(set(paths.decode().split('\0')) - {''}):
    if relative.startswith('redteam/'):
      continue
    path = Path(root) / relative
    if path.is_file():
      digest = hashlib.sha256()
      with path.open('rb') as source:
        for block in iter(lambda: source.read(1024 * 1024), b''):
          digest.update(block)
      records.append(dict(root=root, path=relative, bytes=path.stat().st_size,
                          sha256=digest.hexdigest()))
Path(sys.argv[1]).write_text(json.dumps(records, indent=2) + '\n')
print(f'Recorded {len(records)} existing files.')
