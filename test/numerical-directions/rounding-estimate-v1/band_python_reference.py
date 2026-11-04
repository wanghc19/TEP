"""Independent replay of the original SciPy band eigenvalue driver.
Input: copied original floating formulas. Output: the original printed margins.
"""
from pathlib import Path
import runpy,contextlib,io
here=Path(__file__).resolve().parent
with contextlib.redirect_stdout(io.StringIO()) as buf:runpy.run_path(str(here/'band/h-band-reproduce.py'))
(here/'output/band-python-reference.json').write_text(buf.getvalue());print(buf.getvalue())
