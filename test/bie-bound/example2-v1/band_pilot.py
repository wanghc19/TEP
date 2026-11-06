"""B2 band feasibility pilot. Input: new output path; output: model and tests."""
import sys,os,json,struct,subprocess
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from monitor import run
out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=False)
def pack(a):return dict(shape=[1,len(a)],real=[struct.pack('>d',x).hex() for x in a],imag=['0000000000000000']*len(a))
data=dict(curve_parameters=pack([.2,.3,1.5,1.,1.,.12,.2,.2]),beta=pack([.5]),d=pack([1.]),cell_widths=pack([1.,1.,.85]),example=dict(empty_center=True,angle_negative=0.,angle_positive=.13))
(out/'model.json').write_text(json.dumps(data));raw=subprocess.check_output(['ps','-axo','pid=,%cpu=,rss=,comm='],text=True);(out/'preflight.txt').write_text(raw)
os.environ.update(OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1',VECLIB_MAXIMUM_THREADS='1',OMP_DYNAMIC='FALSE')
r=run(out,['/Users/whc/opt/miniconda3/condabin/conda','run','--no-capture-output','-n','octave','python','-I',str(Path(__file__).resolve().parent/'band/band_certificate.py'),'--input',str(out/'model.json'),'--output',str(out),'--mode','pilot'])
sys.exit(r['returncode'])
