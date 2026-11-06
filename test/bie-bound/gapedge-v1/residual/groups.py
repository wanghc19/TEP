import gzip
# Stage C source: test/bie-bound/example2-v1/residual/groups.py; local adaptations only.
# B2 source: test/bie-bound/pipeline-v1/residual/groups.py; generalized model plumbing.
# Copied from test/bie-bound/grouprel-v1/groups.py; pipeline adaptations documented in README.
"""One monitored five-group residual computation with distributed regions.
Input: exact field/fit paths, worker count and pilot/full selection.
Output: target ledgers, reliable group sums, tail depths and mixed budget.
"""
import argparse,json,sys,time,os,resource,multiprocessing,traceback,copy
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor,as_completed
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,acb_mat,ctx
from material import matrix,up,dump
from expansion import norm
from group_setup import prepare
from group_norms import columns
from material_group import build as material_build
from boundary_group import compute as boundary
from map_models import integral
import curve_queue as center_queue
from envelope_gate import FiniteGate
SHARED=DATA=FITS=OUT=None

def initialize():
  ctx.threads=1;ctx.prec=128;center_queue.initialize()

def material(side,idx,check,depth=0,sub=0):
  o=SHARED['leads'][side-1];K=o['K'];name=f'material-{side}-{idx}-d{depth}-s{sub}'
  cf,e,src,p,rec,errs=material_build(K,o['piece'],o['bc'],SHARED['Z'],SHARED['beta'],SHARED['d'],OUT,name,(o['W'],o['V']),(o['src'],o['near'],o['proxy'],o['W'],o['V']),idx,depth,sub)
  t=time.perf_counter();rec.update(columns(cf,errs,arb.pi()/(64*2**depth),check));rec.update(column_norm_seconds=time.perf_counter()-t,kind='material',side=side,index=idx)
  return cf,e,rec

def references_general():
  start=time.perf_counter();o=SHARED['leads'][0];ctx.prec=128
  full,ef,_,_,rf,_=material_build(o['K'],o['piece'],o['bc'],SHARED['Z'],SHARED['beta'],SHARED['d'],OUT,'reference-left194')
  cf,e,rs=material(1,0,True);ctx.prec=192;h=arb.pi()/64
  v0=integral([a*o['V'] for a in full],h);v1=integral(cf,h);ee=ef*norm(o['V'])+e
  allow=2*h*ee**2+2*(2*h).sqrt()*ee*(v0.upper().sqrt()+v1.upper().sqrt());diff=abs(v0-v1)
  rec=dict(left=dict(V_full=str(v0),V_states=str(v1),difference=up(diff),allowance=up(allow),passed=bool(diff<allow)),seconds=time.perf_counter()-start)
  dump(OUT/'reference-checks.json',rec);assert diff<allow,'Independent state-column check';return rec

def references():
  if DATA['pieces'][0]['shape']=='none':return references_general()
  start=time.perf_counter();o=SHARED['leads'][1];ctx.prec=192;n=59;V=acb_mat(97,n,[o['states'][j][i,0] for i in range(97) for j in range(n)]);W=matrix(o['piece']['G'])*V
  from lead_pilot import build
  cf,e,ss,pp,rec=build(o['K'],o['piece'],o['bc'],SHARED['Z'],SHARED['beta'],SHARED['d'],OUT,'reference-right59',(W,V));h=arb.pi()/64;vv=integral(cf,h);tail=o['BL'][0]**2/64*norm(o['states'][n])**2*o['contraction']['factor'];upper=((vv.upper().sqrt()+(2*h).sqrt()*e)**2+tail).sqrt();ref=arb('7.888336094596e-15');difference=abs(upper-ref)/ref
  out=dict(right_material_upper=up(upper),right_material_relative=up(difference),seconds=time.perf_counter()-start)
  # Reproduce the earlier wall pilots with the same physical segments and
  # exact first state / first 60 states. These are checks, not reused targets.
  from wall_columns import compute as oldwall
  from boundary_group import first
  from expansion import Expansion,Sources
  from material import I
  from flint import acb
  t=time.perf_counter();ctx.prec=128;c0=SHARED['center'];phase=(I*SHARED['beta']*SHARED['d']).exp();three=[(arb(0),arb(m),phase**m) for m in [-1,0,1]];reg0=Expansion(c0['K'],three,arb('.08'),80,c0['src'],(arb('.5'),arb('.03125')));center=(c0['K'],c0['src'],c0['proxy'],c0['W'],reg0)
  v0=o['states'][0];w0=matrix(o['piece']['G'])*v0;cp=dict(o['piece'],tau_coeff=matrix(o['piece']['tau_coeff'])*w0,zeta_coeff=matrix(o['piece']['zeta_coeff'])*w0);s1=Sources(o['K'],cp,64,80,arb('.12'));Z=SHARED['Z'];charges=[(Z[1,j].real,Z[0,j].real,acb(1)) for j in range(Z.ncols())];p1=Expansion(o['K'],charges,arb('1.1'),144,coefficients=o['bc']*v0)
  _,_,jr=oldwall(o['K'],s1,p1,w0,v0,SHARED['beta'],SHARED['d'],'junction',center,False)
  cut=lambda A:acb_mat(A.nrows(),60,[A[i,j] for i in range(A.nrows()) for j in range(60)])
  sx=copy.copy(o['src']);sx.nc=60;sx.Ct=cut(sx.Ct);sx.Cz=cut(sx.Cz);sx.rows=[(x,y,cut(b)) for x,y,b in sx.rows];px=copy.copy(o['proxy']);px.nc=60;px.coefficients=cut(px.coefficients);px.plus=[cut(a) for a in px.plus];px.minus=[cut(a) for a in px.minus]
  cf,ee,ir=oldwall(o['K'],sx,px,cut(o['W']),cut(o['V']),SHARED['beta'],SHARED['d'],'interior',None,False);tv=o['BL'][1]**2*norm(o['states'][59])**2/(16*(1-o['r']**2));vi=integral(cf,arb('.03125'));iu=((vi.upper().sqrt()+arb('.0625').sqrt()*ee)**2+tv).sqrt()
  jdiff=abs(arb(str(jr['finite_upper']))/arb('4.044824800008e-14')-1);idiff=abs(iu/arb('7.393821691540e-15')-1);out['walls']=dict(junction_upper=jr['finite_upper'],interior_upper=up(iu),junction_relative=up(jdiff),interior_relative=up(idiff),seconds=time.perf_counter()-t)
  # Historical numbers are diagnostics only for the newly rebuilt field.
  # Independently form a full 194-port model for the left target, then apply
  # exactly the same actual states as the reduced-column calculation.
  o=SHARED['leads'][0];ctx.prec=128;t=time.perf_counter();full,ef,_,_,rf,_=material_build(o['K'],o['piece'],o['bc'],SHARED['Z'],SHARED['beta'],SHARED['d'],OUT,'reference-left194');cf,e,rs=material(1,0,True);ctx.prec=192;v0=integral([a*o['V'] for a in full],h);v1=integral(cf,h);ee=ef*norm(o['V'])+e;allow=2*h*ee**2+2*(2*h).sqrt()*ee*(v0.upper().sqrt()+v1.upper().sqrt());diff=abs(v0-v1);out['left']=dict(V_full=str(v0),V_states=str(v1),difference=up(diff),allowance=up(allow),passed=bool(diff<allow),seconds=time.perf_counter()-t);assert diff<allow,'Left finite-map check failed'
  out['seconds']=time.perf_counter()-start;dump(OUT/'reference-checks.json',out);return out

def target(kind,side,idx):
  leaves=[];fallback=[]
  def part(depth,sub):
    try:
      if kind=='material':_,_,row=material(side,idx,idx==0,depth,sub)
      else:_,_,row=boundary(SHARED,kind,side,idx,idx in [0,4,8],depth,sub)
      leaves.append(row)
    except FiniteGate as err:
      fallback.append(dict(depth=depth,sub=sub,error=str(err)))
      if depth>=2:raise FiniteGate('Target still failed after two split levels: '+str(err))
      part(depth+1,2*sub);part(depth+1,2*sub+1)
  part(0,0)
  if len(leaves)==1:row=leaves[0];row['fallbacks']=fallback;return row
  ctx.prec=192;nc=len(leaves[0]['upper_squared']);row=dict(kind=kind,side=side,index=idx,leaves=leaves,fallbacks=fallback,upper_squared=[up(sum((arb(str(l['upper_squared'][j])) for l in leaves),arb(0))) for j in range(nc)],lower_squared=[str(sum((arb(l['lower_squared'][j]) for l in leaves),arb(0)).lower()) for j in range(nc)],V=str(sum((arb(l['V']) for l in leaves),arb(0))),e_I=max(l['e_I'] for l in leaves))
  if all('gauss_relative' in l for l in leaves):row['gauss_relative']=max(l['gauss_relative'] for l in leaves)
  return row

def task(spec):
  start=time.perf_counter();cpu=time.process_time();kind,side,idx=spec;ctx.prec=128
  try:
    if kind=='center':rec=center_queue.task(idx);assert not rec['failed'];rec=dict(kind=kind,side=0,index=idx,center=rec)
    elif kind=='references':rec=dict(kind=kind,side=side,index=idx,result=references())
    else:rec=target(kind,side,idx)
    rec.update(task_wall_seconds=time.perf_counter()-start,task_cpu_seconds=time.process_time()-cpu,pid=os.getpid(),passed=True)
  except Exception as e:rec=dict(kind=kind,side=side,index=idx,passed=False,error=str(e),traceback=traceback.format_exc(),task_wall_seconds=time.perf_counter()-start,task_cpu_seconds=time.process_time()-cpu)
  dump(OUT/f'target-{kind}-{side}-{idx}.json',rec);print(json.dumps({k:rec[k] for k in ['kind','passed','task_wall_seconds']}),flush=True);return rec

def tail_select(rows,side,kind,o,nmax):
  factor=o["contraction"]["factor"];target=arb(TAIL_TARGET)
  rs=[x for x in rows if x.get('kind')==kind and x.get('side')==side];assert rs
  upcols=[sum((arb(str(x['upper_squared'][j])) for x in rs),arb(0)) for j in range(nmax)]
  lowcols=[sum((arb(x['lower_squared'][j]) for x in rs),arb(0)) for j in range(nmax)]
  B=o['BL'][{'material':0,'interior':1,'seam':2}[kind]];choices=[]
  for n in range(1,nmax-9):
    finite=sum(upcols[:n],arb(0));lower=sum(lowcols[:n],arb(0));tail=B**2*norm(o['states'][n])**2*factor;choices.append(dict(N=n,finite_squared_upper=up(finite),finite_squared_lower=str(lower.lower()),tail_squared=up(tail)))
    if tail<=target*lower:break
  else:raise ArithmeticError('Prepared states insufficient for relative tail rule and N+10')
  nn=n+10;f2=sum(upcols[:nn],arb(0));l2=sum(lowcols[:nn],arb(0));t2=B**2*norm(o['states'][nn])**2*factor;eps=(finite+tail).sqrt();eps2=(f2+t2).sqrt();lo=lower.sqrt();lo2=l2.sqrt();overlap=min(eps,eps2)-max(lo,lo2);ratio=(t2/tail).sqrt();contraction=o['contraction']['norm10']
  rec=dict(side=side,kind=kind,initial_state_norm_upper=up(norm(o["states"][0])),selected_state_norm_upper=up(norm(o["states"][n])),N=n,N_check=nn,B_upper=up(B),p=o['contraction']['p'],tail_ratio_target=TAIL_TARGET,contraction=o['contraction']['record'],r_upper=up(o['r']),finite_squared_upper=up(finite),tail_squared=up(tail),relative_tail=up(tail/lower.lower()),epsilon_upper=up(eps),epsilon_lower=str(lo.lower()),N_plus_10_upper=up(eps2),N_plus_10_lower=str(lo2.lower()),N_plus_10_tail_squared=up(t2),tail_norm_ratio=up(ratio),norm_P10_upper=up(contraction),overlap_lower=str(overlap.lower()),choices=choices)
  assert ratio<=contraction and overlap>0,'N+10 tail/contribution check failed'
  demo=o['power_demo'];td=B**2*norm(o['states'][n])**2*demo['factor'];td2=B**2*norm(o['states'][nn])**2*demo['factor'];ed=(finite+td).sqrt();ed2=(f2+td2).sqrt();od=min(ed,ed2)-max(lo,lo2)
  assert od>0 and (td2/td).sqrt()<=demo['norm10']
  state10=sum((norm(o['states'][j])**2 for j in range(n,nn)),arb(0));state_bound=demo['factor']*norm(o['states'][n])**2;state_refined=state10+demo['factor']*norm(o['states'][nn])**2
  if 10 % demo['p']==0:assert state_refined<=state_bound,'General-p actual state tail check'
  rec['power_demo']=dict(state_tail_bound=up(state_bound),state_next_10_squared=up(state10),state_tail_N_plus_10=up(demo['factor']*norm(o['states'][nn])**2),refined_state_tail_upper=up(state_refined),state_margin_lower=str((state_bound-state_refined).lower()),**demo['record'],N=n,N_check=nn,tail_squared=up(td),tail_N_plus_10_squared=up(td2),epsilon_upper=up(ed),N_plus_10_upper=up(ed2),overlap_lower=str(od.lower()),tail_norm_ratio=up((td2/td).sqrt()),checked=True)
  return finite+tail,rec

def summarize(rows,nmax):
  ctx.prec=192;central=arb(0)
  for row in rows:
    if row['kind']=='center':
      for l in row['center']['leaves']:
        h=arb.pi()/(192*2**l['depth']);v=arb(l['V']);e=sum((arb(str(l[k])) for k in ['e_self','local_tail','e_smooth','combination_error']),arb(0));central+=(v.upper().sqrt()+(2*h).sqrt()*e)**2
  vals=[central,arb(0),arb(0),arb(0),arb(0)];tails=[]
  for side in [1,2]:
    for kind in ['material','interior','seam']:
      value,rec=tail_select(rows,side,kind,SHARED['leads'][side-1],SHARED['leads'][side-1]['nstates']);tails.append(rec);slot=side if kind=='material' else 3 if kind=='interior' else 4;vals[slot]+=value
  for x in rows:
    if x['kind']=='junction':vals[3]+=arb(str(x['upper_squared'][0]))
    elif x['kind']=='seam' and x['side']==0:vals[4]+=arb(str(x['upper_squared'][0]))
  eps=[v.sqrt() for v in vals];floats=list(map(arb,['1.2610675455e-12','6.0997763730e-14','6.3616652364e-14','2.1561016159e-13','7.0953614059e-15']));ratios=[x/y for x,y in zip(eps,floats)];cg=list(map(arb,['2.490','1.181','1.234','1.036','1.036']));Q=sum((a*b for a,b in zip(cg,eps)),arb(0));mu=matrix(DATA['k'])[0,0].real**2;U=arb('1.23587');width=4*mu*Q/(U-Q)
  result=dict(epsilon_upper=list(map(up,eps)),floating=list(map(str,floats)),ratios=list(map(up,ratios)),tails=tails,mixed_Q_upper=up(Q),mixed_width_upper=up(width),mass_lower=str(U),mu=str(mu),scan_constants=list(map(str,cg)),central_reference_relative=up(abs(eps[0]-arb('1.261590321446559e-12'))/arb('1.261590321446559e-12')))
  if DATA['pieces'][0]['shape']=='none':
    for key in ['floating','ratios','mixed_Q_upper','mixed_width_upper','mass_lower','central_reference_relative']:result.pop(key,None)
  dump(OUT/'groups.json',result)
  # Whole-curve comparison is reported after this new-frequency run.
  # Old floating ratios do not enter the reliability proof.
  return result

def main():
  global DATA,FITS,SHARED,OUT,TAIL_TARGET
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--coefficients',required=True);p.add_argument('--output',required=True);p.add_argument('--workers',type=int,default=8);p.add_argument('--states',type=int,default=80);p.add_argument('--tail-ratio',default='1e-6');p.add_argument('--states-left',type=int);p.add_argument('--states-right',type=int);p.add_argument('--pilot',action='store_true');p.add_argument('--repair-pilot',action='store_true');p.add_argument('--resource-pilot',action='store_true');a=p.parse_args();OUT=Path(a.output);DATA=json.loads((gzip.decompress(Path(a.input).read_bytes()).decode() if str(a.input).endswith(".gz") else Path(a.input).read_text()));FITS=json.loads((gzip.decompress(Path(a.coefficients).read_bytes()).decode() if str(a.coefficients).endswith(".gz") else Path(a.coefficients).read_text()));assert a.workers<=11
  TAIL_TARGET=a.tail_ratio;assert 0<arb(TAIL_TARGET)<1
  start=time.perf_counter();cpu=time.process_time();load=os.getloadavg();SHARED=prepare(DATA,FITS,[a.states_left or a.states,a.states_right or a.states]);c=SHARED['center'];center_queue.DATA=DATA;center_queue.K=c['K'];center_queue.CACHE=c['cache'];center_queue.NEAR=c['near'];center_queue.PROXY=c['proxy'];center_queue.OUT=OUT
  setup=dict(seconds=SHARED['seconds'],center_seconds=c['seconds'],leads=[dict(seconds=o['seconds'],tail=o['tail'],source_seconds=o['src'].seconds,source=o['src'].times,near=o['near'].record,proxy=o['proxy'].record) for o in SHARED['leads']]);dump(OUT/'setup.json',setup)
  if a.resource_pilot:spec=[('interior',2,i) for i in [0,1,2]]+[('seam',2,i) for i in [3,4,5]]+[('material',2,0)]
  elif a.repair_pilot:spec=[('material',2,i) for i in [7,8]]
  elif a.pilot:spec=[('center',0,i) for i in [0,1]]+[('material',s,i) for s in [1,2] for i in [0,16]]+[(k,s,8 if k!='seam' else 4) for k in ['junction','interior','seam'] for s in [1,2]]+[('seam',0,4)]
  else:spec=[('center',0,i) for i in range(192)]+[('material',s,i) for s in [1,2] for i in range(64)]+[(k,s,i) for k in ['junction','interior'] for s in [1,2] for i in range(16)]+[('seam',s,i) for s in [0,1,2] for i in range(8)]+[('references',0,0)]
  empty=DATA['pieces'][0]['shape']=='none'
  if empty:spec=[t for t in spec if t[0]!='center']
  # Mix task types so expensive independent region setups are distributed.
  if not (a.pilot or a.repair_pilot or a.resource_pilot):spec.sort(key=lambda x:(x[2],x[0],x[1]))
  rows=[];t=time.perf_counter()
  with ProcessPoolExecutor(max_workers=a.workers,mp_context=multiprocessing.get_context('fork'),initializer=initialize) as pool:
    fs=[pool.submit(task,s) for s in spec]
    for f in as_completed(fs):
      r=f.result();rows.append(r)
      if not r['passed']:
        for ff in fs:ff.cancel()
        break
  queue=time.perf_counter()-t;valid=len(rows)==len(spec) and all(x['passed'] for x in rows);result=dict(empty_center=empty,pilot=a.pilot or a.repair_pilot or a.resource_pilot,setup=setup,queue_seconds=queue,workers=a.workers,states=[a.states_left or a.states,a.states_right or a.states],targets_expected=len(spec),targets_returned=len(rows),passed=valid,load_before=load,load_after=os.getloadavg(),tasks=rows)
  if valid and not (a.pilot or a.repair_pilot or a.resource_pilot):result['groups']=summarize(rows,a.states)
  usage=resource.getrusage(resource.RUSAGE_CHILDREN);result.update(wall_seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu+usage.ru_utime+usage.ru_stime);dump(OUT/'summary.json',result)
  if valid:
    saved=json.loads(gzip.decompress((OUT/'summary.json.gz').read_bytes()))
    assert saved['tasks']==rows
    dump(OUT/'target-records.json',dict(archive='summary.json.gz',location='tasks',exact_readback_equal=True,count=len(rows)))
  assert valid,'Incomplete or failed target queue'
if __name__=='__main__':main()
