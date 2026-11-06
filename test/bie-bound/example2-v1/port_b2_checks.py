"""Source plumbing for B2 checks and assembly; run once on copied sources."""
from pathlib import Path
B=Path(__file__).resolve().parent
def edit(f,fn):
 p=B/f;p.write_text(fn(p.read_text()))
def groups(s):
 s=s.replace('def references():','''def references_general():
  start=time.perf_counter();o=SHARED['leads'][0];ctx.prec=128
  full,ef,_,_,rf,_=material_build(o['K'],o['piece'],o['bc'],SHARED['Z'],SHARED['beta'],SHARED['d'],OUT,'reference-left194')
  cf,e,rs=material(1,0,True);ctx.prec=192;h=arb.pi()/64
  v0=integral([a*o['V'] for a in full],h);v1=integral(cf,h);ee=ef*norm(o['V'])+e
  allow=2*h*ee**2+2*(2*h).sqrt()*ee*(v0.upper().sqrt()+v1.upper().sqrt());diff=abs(v0-v1)
  rec=dict(left=dict(V_full=str(v0),V_states=str(v1),difference=up(diff),allowance=up(allow),passed=bool(diff<allow)),seconds=time.perf_counter()-start)
  dump(OUT/'reference-checks.json',rec);assert diff<allow,'Independent state-column check';return rec

def references():
  if DATA['pieces'][0]['shape']=='none':return references_general()''')
 s=s.replace("  # Mix task types", "  empty=DATA['pieces'][0]['shape']=='none'\n  if empty:spec=[t for t in spec if t[0]!='center']\n  # Mix task types")
 s=s.replace("result=dict(pilot=a.pilot or a.repair_pilot,", "result=dict(empty_center=empty,pilot=a.pilot or a.repair_pilot,")
 # No stale mass/scan mixed width for the new model; certificates assembled separately.
 s=s.replace("  dump(OUT/'groups.json',result)","  if DATA['pieces'][0]['shape']=='none':\n    for key in ['floating','ratios','mixed_Q_upper','mixed_width_upper','mass_lower','central_reference_relative']:result.pop(key,None)\n  dump(OUT/'groups.json',result)")
 return s
edit('residual/groups.py',groups)
def boundary(s):
 s=s.replace("  start=time.perf_counter();ctx.prec=192;",'''  if kind=='seam' and side==0 and getattr(shared['center']['src'],'empty',False):
    return None,[arb(0)],dict(kind=kind,side=side,index=idx,depth=depth,sub=sub,V='0',V_gauss='0',e_I=0.,upper_squared=[0.],lower_squared=['0'],gauss_relative=0.,exact_zero_reason='empty homogeneous center: finite Rayleigh field is exactly quasi-periodic')
  start=time.perf_counter();ctx.prec=192;''')
 return s
edit('residual/boundary_group.py',boundary)
def audit(s):
 s=s.replace("keys=[(x['kind']", "if r.get('empty_center',False):expected={x for x in expected if x[0]!='center'}\nkeys=[(x['kind']")
 a=s.index('es=[v.sqrt() for v in vals];');s=s[:a]+'''es=[v.sqrt() for v in vals]
assert all(arb(str(x))>=y for x,y in zip(g['epsilon_upper'],es)), 'Readback upper bounds too small'
rec=dict(epsilon_upper=list(map(up,es)),coverage_targets=len(expected)-1,Gauss_checks=checks,max_Gauss_relative=max(x['relative'] for x in checks),all_passed=True,seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu)
dump(out/'summary.json',rec)
'''
 return s
edit('residual/audit_groups.py',audit)
def mass(s):
 s=s.replace("  assert D.nrows()==8;rows=[];", "  empty=data['pieces'][0]['shape']=='none';assert D.nrows()==(3 if empty else 8);rows=[];")
 s=s.replace('  for j in range(8):','  for j in range(D.nrows()):')
 s=s.replace('assert rho in [4,17]','assert rho in ([1] if empty else [4,17])')
 s=s.replace("    xx=x+([0,-1,1][kind]);boundary=geometry(kind,x,y,r,P)","    if empty:\n      assert kind==0;L=matrix(data['cell_widths'])[0,0].real;boundary=min(L/2-abs(x),arb('.5')-abs(y));assert boundary>r;xx=x\n    else:xx=x+([0,-1,1][kind]);boundary=geometry(kind,x,y,r,P)")
 s=s.replace('    u,e,np,sep=eval_field(kind,x,y,k,*pieces[kind],P,args.order)', '''    if empty:
      W=matrix(data['incident']);beta=matrix(data['beta'])[0,0].real;d=matrix(data['d'])[0,0].real;u=acb(0)
      for side in range(2):
        sign=1-2*side
        for l,m in enumerate(data['rayleigh_modes']):
          bm=beta+2*arb.pi()*m/d;gamma=acb(k*k-bm*bm).sqrt();u+=(I*((x+sign*L/2)*gamma*sign+y*bm)).exp()/d.sqrt()*W[side*97+l,0]
      e=arb(0);np=0;sep=boundary
    else:u,e,np,sep=eval_field(kind,x,y,k,*pieces[kind],P,args.order)''')
 return s
edit('mass/disks.py',mass)
edit('enclosure/trace_constants.py',lambda s:s.replace('def certify_curve(name,R,a,delta,K,n0):','def certify_curve(name,R,a,delta,K,n0,period=arb(1)):').replace('separation=1-2*X-2*delta','separation=min(period,arb(1))-2*X-2*delta'))
def assembly(s):
 s=s.replace('(x.upper()*scale).ceil()', '(x.upper()*scale).upper().ceil()').replace('(x.lower()*scale).floor()', '(x.lower()*scale).lower().floor()')
 a=s.index('  # Explicit model assertions,');b=s.index('  Rc=hull',a)
 s=s[:a]+'''  model=data.get('example',{});empty=model.get('empty_center',False)
  assert decode(data['beta'])[0]==arb(1)/2 and decode(data['d'])[0]==1
  widths=decode(data['cell_widths']) if 'cell_widths' in data else [arb(1)]*3
'''+s[b:]
 s=s.replace("    delta=rational_float(dd);eta=rational_float(ee);K=arb(kk)","    delta=rational_float(dd);eta=rational_float(ee);K=arb(kk)\n    if j==0 and empty:\n      rows.append(dict(name=name,published='0',geometry=dict(empty=True),trace=dict(C_upper=0.)));continue")
 s=s.replace('certify_curve(name,*shapes[j],delta,K,n0)', 'certify_curve(name,*shapes[j],delta,K,n0,widths[j])')
 s=s.replace("assert geometry['bbox_x_upper']<.5", "assert arb(str(geometry['bbox_x_upper']))<widths[j]/2")
 s=s.replace("      assert 1-2*delta>0\n      geometry={'flat_separation_lower':lower(1-2*delta)}", "      period=min(widths) if j==3 else arb(1);assert period-2*delta>0\n      geometry={'flat_separation_lower':lower(period-2*delta)}")
 s=s.replace('C,rec=trace(delta,eta,K,mu);assert C<arb(published)',"C,rec=trace(delta,eta,K,mu)\n    if empty:published=directed(C,6,True)\n    assert C<arb(published)")
 s=s.replace('def assembly(data,groups,disks,bits):','def assembly(data,groups,disks,bits,certificate):')
 a=s.index("  eps=groups['epsilon_upper'];");b=s.index('  R=2*mu*Q/den;',a)
 s=s[:a]+'''  empty=data.get('example',{}).get('empty_center',False)
  eps=groups['epsilon_upper'];assert len(eps)==5 and all(Fraction(x)>=0 for x in eps) and (not empty or Fraction(eps[0])==0)
  used=directed(arb(disks['U_lower']),6,False) if empty else '1.23587'
  U=arb(used);assert arb(disks['U_lower'])>U
  assert len(disks['rows'])==(3 if empty else 8) and arb(disks['pair_clearance_lower'])>0
  for row in disks['rows']:
    assert arb(row['rho']) in ([arb(1)] if empty else [arb(4),arb(17)]) and arb(row['boundary_distance_lower'])>arb(row['radius'])
  caps=[r['published'] for r in certificate['rows']]
  terms=[arb(c)*arb(e) for c,e in zip(caps,eps)];Q=sum(terms,arb(0));den=U-Q;assert den>0
'''+s[b:]
 s=s.replace('aa=(arb(659)/500)**2;bb=(arb(19)/8)**2',"aa=(arb(73)/50)**2 if empty else (arb(659)/500)**2;bb=(arb(237)/100)**2 if empty else (arb(19)/8)**2")
 s=s.replace("Fraction(p[4])*Fraction(e) for p,e in zip(PARAMS,eps)","Fraction(c)*Fraction(e) for c,e in zip(caps,eps)").replace("ur=Fraction('1.23587')",'ur=Fraction(used)')
 s=s.replace("U_used='1.23587',",'U_used=used,C_upper=caps,')
 s=s.replace('assembly(data,groups,disks,bits)',"assembly(data,groups,disks,bits,result['certificates'][-1])")
 s=s.replace("'eight interior disks with the unchanged interior representation'","'same-field disks with positive geometric clearances'")
 return s
edit('enclosure/assemble.py',assembly)
