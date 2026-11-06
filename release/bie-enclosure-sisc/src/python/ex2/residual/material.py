# Copied from test/bie-bound/gapedge-v1/residual/material.py for release R2.
# Stage C source: test/bie-bound/example2-v1/residual/material.py; local adaptations only.
# B2 source: test/bie-bound/pipeline-v1/residual/material.py; generalized model plumbing.
# Copied from test/bie-bound/grouprel-v1/material.py; pipeline adaptations documented in README.
"""Arb material-pilot arithmetic. CM denotes compressed source moments.
Input: fixed binary64 field, explicit output and numerical settings.
Output: coefficients, error enclosures and single-thread cost ledger.
"""
import argparse, json, math, struct, time
from pathlib import Path
from flint import acb, arb, acb_mat, acb_series, ctx
ctx.prec=128
ctx.cap=64
I=acb(0,1)
TAU=0.02409875

def matrix(o):
  nr,nc=o['shape']
  def read(x,i):
    return arb(struct.unpack('>d',bytes.fromhex(x if isinstance(x,str) else x[i]))[0])
  return acb_mat(nr,nc,[acb(read(o['real'],i+j*nr),read(o['imag'],i+j*nr)) for i in range(nr) for j in range(nc)])

from envelope_gate import FiniteGate

def up(x):
  x=x.upper()
  if not x.is_finite():raise FiniteGate(f'nonfinite requested output: {x}')
  if x.is_zero():return 0.
  f=float(x)
  while not arb(str(f))>x:f=math.nextafter(f,math.inf)
  return f

def dump(path,data):
  raw=json.dumps(data,separators=(",",":"))
  if path.name.startswith(("target-","material-")) or path.name=="summary.json":
    import gzip
    with gzip.open(str(path)+".gz","wt") as f:f.write(raw)
    if path.name=="summary.json":path.write_text(json.dumps(dict(archive=path.name+".gz",encoding="gzip",original_format="JSON")))
  else:path.write_text(raw)

def geom(t,R,b):
  if isinstance(R,tuple):
    scale=R[0]/(1+b*b/2).sqrt();r=scale*(1+b*(3*t).cos());dr=-3*scale*b*(3*t).sin()
    vals=(r*t.cos(),r*t.sin(),dr*t.cos()-r*t.sin(),dr*t.sin()+r*t.cos())
    if len(R)==1 or R[1].is_zero():return vals
    c=R[1].cos();sn=R[1].sin();x,y,dx,dy=vals
    return c*x-sn*y,sn*x+c*y,c*dx-sn*dy,sn*dx+c*dy
  c,s=t.cos(),t.sin()
  a=(5*t).cos()*b;da=-(5*t).sin()*5*b
  return (R*(arb('1.5')+a)*c,R*(1+a)*s,
          R*(da*c-(arb('1.5')+a)*s),R*(da*s+(1+a)*c))

def block_rows(jets,degree):
  """Rows are scaled parameter powers; columns are Laurent symbols U^m."""
  low=-degree-1;high=degree+1
  return acb_mat(degree+1,high-low+1,[jets[m][j] if m in jets else acb(0)
      for j in range(degree+1) for m in range(low,high+1)])

def translate(c,h,degree,k,R,b,source):
  """Taylor jet of a translated Helmholtz kernel in its Laurent derivative basis."""
  t=acb_series([c,h],degree+1)
  x,y,dx,dy=geom(t,R,b)
  speed=(dx*dx+dy*dy).sqrt()
  z=x+y*I;w=x-y*I
  direction=-1 if source else 1
  az=[z[j]*direction*k/2 for j in range(degree+1)]
  aw=[-w[j]*direction*k/2 for j in range(degree+1)]
  rows=[{0:acb(1)}]
  for n in range(1,degree+1):
    row={m:acb(0) for m in range(-n,n+1)}
    for j in range(1,n+1):
      for m,v in rows[n-j].items():
        row[m+1]+=j*az[j]*v;row[m-1]+=j*aw[j]*v
    rows.append({m:v/n for m,v in row.items()})
  base={m:acb_series([row.get(m,0) for row in rows],degree+1) for m in range(-degree,degree+1)}
  if source:
    value_weight=-speed
    normal_x=-dy;normal_y=dx
  else:
    value_weight=speed.sqrt()
    normal_x=dy/speed*value_weight;normal_y=-dx/speed*value_weight
  plus=(normal_x+normal_y*I)*k/2;minus=(-normal_x+normal_y*I)*k/2
  val={m:v*value_weight for m,v in base.items()};normal={}
  for m,v in base.items():
    normal[m+1]=normal.get(m+1,0)+v*plus
    normal[m-1]=normal.get(m-1,0)+v*minus
  return block_rows(val,degree),block_rows(normal,degree),x[0],y[0]

class Proxy:
  def __init__(self,data):
    self.k=matrix(data['k'])[0,0].real
    self.L=matrix(data['cell_widths'])[0,0].real if 'cell_widths' in data else arb(1)
    Z=matrix(data['proxy_Z']);C=matrix(data['proxy_c'])
    self.charges=[(Z[1,j].real,Z[0,j].real,C[0,j]) for j in range(Z.ncols())]
    params=matrix(data['curve_parameters'])
    self.R=params[0,0].real;self.b=params[0,1].real
  def harmonics(self,dx,dy,degree):
    """Use H0,H1 and the order recurrence for all pure spatial derivatives."""
    k=self.k;out=[acb(0)]*(2*degree+1)
    for X,Y,c in self.charges:
      x=dx-X;y=dy-Y;r=(x*x+y*y).sqrt();arg=k*r
      h0=arg.bessel_j(0)+I*arg.bessel_y(0)
      h1=arg.bessel_j(1)+I*arg.bessel_y(1)
      factor=c*I/4;out[degree]+=factor*h0
      minus=-(x-I*y)/r;plus=(x+I*y)/r
      vm=acb(1);vp=acb(1)
      for m in range(1,degree+1):
        vm*=minus;vp*=plus
        out[degree+m]+=factor*h1*vm;out[degree-m]+=factor*h1*vp
        h0,h1=h1,2*m/arg*h1-h0
    return out
  def pair(self,T,S,p,n):
    tv,tn,x,y=T;sv,sn,sx,sy=S
    order=p+n+2;v=self.harmonics(x-sx,y-sy,order)
    H=acb_mat(2*p+3,2*n+3,[v[i+j] for i in range(2*p+3) for j in range(2*n+3)])
    val=tv*H;normal=tn*H
    return [val*sn.transpose(),val*sv.transpose(),normal*sn.transpose(),normal*sv.transpose()]

def benchmark(data,out,p,n,P=64,S_count=64):
  K=Proxy(data); pi=arb.pi();ht=pi/P;hs=pi/S_count
  # Midpoints of real panels; times include summing all 320 charges.
  times=[];checks=[]
  for it,js in [(0,0),(0,S_count//4),(1,S_count//2-1)]:
    ct=(2*it+1)*ht;cs=(2*js+1)*hs;t=time.perf_counter()
    T=translate(ct,ht,p,K.k,K.R,K.b,False)
    target_setup=time.perf_counter()-t;t1=time.perf_counter()
    S=translate(cs,hs,n,K.k,K.R,K.b,True)
    source_setup=time.perf_counter()-t1;t1=time.perf_counter()
    S0=translate(cs,hs,0,K.k,K.R,K.b,True)
    source_zero_setup=time.perf_counter()-t1
    setup=time.perf_counter()-t;t=time.perf_counter()
    short=K.pair(T,S0,p,0);ts=time.perf_counter()-t;t=time.perf_counter()
    mixed=K.pair(T,S,p,n);tt=time.perf_counter()-t
    # These independent degrees must agree in the entire zeroth source column.
    overlap=all(short[l][r,0].overlaps(mixed[l][r,0]) for l in range(4) for r in range(p+1))
    times.append(dict(target=it,source=js,setup=setup,target_setup=target_setup,source_setup=source_setup,source_zero_setup=source_zero_setup,target_kernel=ts,mixed_kernel=tt))
    checks.append(overlap)
  chi_t=sum(x['target_kernel'] for x in times)/len(times)/TAU
  chi_ts=sum(x['mixed_kernel'] for x in times)/len(times)/TAU
  result=dict(p=p,n=n,target_panels=P,source_panels=S_count,times=times,chi_t=chi_t,chi_ts=chi_ts,zeroth_column_overlap=checks,
    kernel_only_RE31_seconds=15360*chi_ts*TAU,design_center_kernel_seconds=4096*chi_ts*TAU,configured_center_kernel_seconds=P*S_count*chi_ts*TAU,
    cold_chi_t=sum(x['target_kernel']+x['target_setup']+x['source_zero_setup'] for x in times)/len(times)/TAU,
    cold_chi_ts=sum(x['mixed_kernel']+x['target_setup']+x['source_setup'] for x in times)/len(times)/TAU)
  dump(out/'timing.json',result)
  assert all(checks),'Zeroth source column failed'
  return result

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True)
  p.add_argument('--stage',choices=['timing'],required=True);p.add_argument('--target-degree',type=int,default=24);p.add_argument('--source-degree',type=int,default=16)
  p.add_argument('--target-panels',type=int,default=64);p.add_argument('--source-panels',type=int,default=64)
  a=p.parse_args();out=Path(a.output);data=json.loads(Path(a.input).read_text())
  if a.stage=='timing':benchmark(data,out,a.target_degree,a.source_degree,a.target_panels,a.source_panels)

if __name__=='__main__':main()
