"""One-time B2 source transformation; input: own copied sources; output: adapters."""
from pathlib import Path
B=Path(__file__).resolve().parent
def edit(f,fn):
 p=B/f;p.write_text(fn(p.read_text()))
def field(s):
 s=s.replace('data.disks=LOCAL_pack(zeros(0,3))','data.disks=LOCAL_pack([1,0,0,.2,1;1,0,.33,.12,1;1,0,-.33,.12,1])')
 a=s.index("  if nargin>=4 && ~strcmp(example.name,'reference')");b=s.index('  % Positions only:',a);s=s[:a]+s[b:]
 s=s.replace('cellmap.i9_geometry=C;',"cellmap.i9_angle=0;if isfield(model,'angle'),cellmap.i9_angle=model.angle;end;cellmap.i9_L=model.X_R-model.X_L;cellmap.i9_geometry=C;")
 return s
edit('field/field_export.m',field)
def fit(s):
 s=s.replace("    stage=tic;cm=cells{j};[src,w]=LOCAL_source(cm,maps{j},768,model);","    stage=tic;cm=cells{j};\n    if strcmp(cm.i9_shape,'none'),C{j}=zeros(nz,size(maps{j},2));continue;end\n    [src,w]=LOCAL_source(cm,maps{j},768,model);")
 s=s.replace('  H=[cm.H_L,cm.H_R]*map;',"  if isfield(cm,'i9_angle') && cm.i9_angle~=0\n    old=g;c=cos(cm.i9_angle);s=sin(cm.i9_angle);g(1:3,:)=c*old(1:3,:)-s*old(4:6,:);g(4:6,:)=s*old(1:3,:)+c*old(4:6,:);\n  end\n  H=[cm.H_L,cm.H_R]*map;")
 return s
edit('field/field_fit.m',fit)
def mat(s):
 s=s.replace('    return r*t.cos(),r*t.sin(),dr*t.cos()-r*t.sin(),dr*t.sin()+r*t.cos()', '''    vals=(r*t.cos(),r*t.sin(),dr*t.cos()-r*t.sin(),dr*t.sin()+r*t.cos())
    if len(R)==1 or R[1].is_zero():return vals
    c=R[1].cos();sn=R[1].sin();x,y,dx,dy=vals
    return c*x-sn*y,sn*x+c*y,c*dx-sn*dy,sn*dx+c*dy''')
 s=s.replace("    self.k=matrix(data['k'])[0,0].real","    self.k=matrix(data['k'])[0,0].real\n    self.L=matrix(data['cell_widths'])[0,0].real if 'cell_widths' in data else arb(1)")
 return s
edit('residual/material.py',mat)
def chord(s):
 old='    return -scale*(m.sin()+b*((4*m).sin()*u4+(2*m).sin()*u2)/2),scale*(m.cos()+b*((4*m).cos()*u4-(2*m).cos()*u2)/2)'
 new='''    x=-scale*(m.sin()+b*((4*m).sin()*u4+(2*m).sin()*u2)/2);y=scale*(m.cos()+b*((4*m).cos()*u4-(2*m).cos()*u2)/2)
    if len(R)==1 or R[1].is_zero():return x,y
    c=R[1].cos();sn=R[1].sin();return c*x-sn*y,sn*x+c*y'''
 return s.replace(old,new)
edit('residual/self_interaction.py',chord)
edit('residual/extended.py',lambda s:s.replace('wall=-arb(sign)/2','wall=-arb(sign)*K.L/2'))
edit('residual/expansion.py',lambda s:s.replace('    start=time.perf_counter();self.K=K;self.R=R;', '    start=time.perf_counter();self.zero=bool(sources and getattr(sources,"empty",False));self.K=K;self.R=R;').replace('    old=K.charges;K.charges=charges;', '''    if self.zero:
      self.nc=sources.nc;self.B=arb(0);self.record=dict(empty=True,seconds=0.);return
    old=K.charges;K.charges=charges;''').replace('    M=self.M if M is None else M;q=a/self.R;', '    if self.zero:return arb(0),arb(0)\n    M=self.M if M is None else M;q=a/self.R;').replace('    M=self.M if M is None else M;z=x-self.center[0]', '    if self.zero:return acb_mat(3,self.nc),arb(0)\n    M=self.M if M is None else M;z=x-self.center[0]').replace('    K=self.K;old=K.charges;', '    if self.zero:return acb_mat(3,self.nc)\n    K=self.K;old=K.charges;'))
def setup(s):
 old="  K=Proxy(data);src=Sources(K,data['pieces'][0]);near=Expansion(K,images,arb('.6'),128,src);proxy=Expansion(K,charges,arb('1.1'),144,coefficients=matrix(fits['B_center']));cache=SelfCache(data,K)"
 new='''  K=Proxy(data);empty=data['pieces'][0]['shape']=='none'
  if empty:
    from types import SimpleNamespace
    src=SimpleNamespace(empty=True,nc=1);near=Expansion(K,images,arb('.6'),128,src);proxy=Expansion(K,charges,arb('1.1'),144,src);cache=None
  else:
    src=Sources(K,data['pieces'][0]);near=Expansion(K,images,arb('.6'),128,src);proxy=Expansion(K,charges,arb('1.1'),144,coefficients=matrix(fits['B_center']));cache=SelfCache(data,K)'''
 s=s.replace(old,new)
 s=s.replace("K.R=(pars[0,7].real,);K.b=", "angle=arb(data.get('example',{}).get('angle_negative' if i==1 else 'angle_positive',0));K.R=(pars[0,7].real,) if angle.is_zero() else (pars[0,7].real,angle);K.L=matrix(data['cell_widths'])[0,i].real if 'cell_widths' in data else arb(1);K.b=")
 return s
edit('residual/group_setup.py',setup)
edit('residual/tail_bound.py',lambda s:s.replace("(arb(1)/2).sqrt()", "((K.L/2)**2+arb(1)/4).sqrt()").replace("arb('.5')-radius,(arb('.5')**2+arb('1.5')**2).sqrt()", "min(K.L,arb(1))/2-radius,((K.L/2)**2+arb('1.5')**2).sqrt()"))
def boundary(s):
 s=s.replace("  if kind=='seam':h=arb('.0625')", "  width=(shared['center'] if side==0 else shared['leads'][side-1])['K'].L\n  if kind=='seam':h=width*arb('.0625')")
 s=s.replace("coordinate=-arb('.5')+(idx+(sub+.5)/2**depth)*arb('.125');R=arb('.16')", "coordinate=width*(-arb('.5')+(idx+(sub+.5)/2**depth)*arb('.125'));R=width*arb('.16')")
 s=s.replace("(shared['center'],sg/2,coordinate),(first(obj),-sg/2,coordinate)","(shared['center'],sg*shared['center']['K'].L/2,coordinate),(first(obj),-sg*width/2,coordinate)")
 s=s.replace('(obj,sg/2,coordinate),(obj,-sg/2,coordinate)','(obj,sg*width/2,coordinate),(obj,-sg*width/2,coordinate)')
 s=s.replace('rn,rp=ratios(obj[\'src\'],obj[\'proxy\'])',"rn,rp=([arb(0)],[arb(0)]) if getattr(obj['src'],'empty',False) else ratios(obj['src'],obj['proxy'])")
 # proxy physical radius must include each actual x face, not .5.
 s=s.replace("ar=(arb('.5')**2+(abs(coordinate)+h)**2).sqrt();", "ar=(arb('.5')**2+(abs(coordinate)+h)**2).sqrt() if kind=='seam' else (max(abs(z[1]) for z in spec)**2+(abs(coordinate)+h)**2).sqrt();")
 return s
edit('residual/boundary_group.py',boundary)
