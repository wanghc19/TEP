# Copied from test/bie-bound/gapedge-v1/enclosure/trace_constants.py for release R2.
# Stage C source: test/bie-bound/example2-v1/enclosure/trace_constants.py; local adaptations only.
# B2 source: test/bie-bound/pipeline-v1/enclosure/trace_constants.py; generalized model plumbing.
# Copied from test/bie-bound/enclosure-v1/trace_constants.py; pipeline adaptations documented in README.
"""CG certificate: interval curvature, star-shaped collars, trace constants.
Inputs are read-only. Arb/FLINT is the only numerical arithmetic in proofs.
Human-readable float outputs are rounded outward and are never used as input
to a certificate assertion. All scientific parameters are explicit below.
"""
import argparse, json, math, struct, time, resource
from pathlib import Path
from flint import arb, fmpq, ctx

def rational_float(x):
    p,q=x.as_integer_ratio()
    return arb(fmpq(p,q))

def decode(o):
    n=math.prod(o['shape'])
    def item(a,j): return a if isinstance(a,str) else a[j]
    assert all(int(item(o['imag'],j),16) in (0,1<<63) for j in range(n))
    return [rational_float(struct.unpack('>d',bytes.fromhex(item(o['real'],j)))[0]) for j in range(n)]

def upper(x):
    u=x.upper();f=float(u)
    while not arb(str(f))>u: f=math.nextafter(f,math.inf)
    return f

def lower(x):
    u=x.lower();f=float(u)
    while not arb(str(f))<u: f=math.nextafter(f,-math.inf)
    return f

def hull(x,y): return arb((x+y)/2,(abs(x-y)/2).upper())

def derivatives(t,R,a,center):
    m=5 if center else 3
    scale=R if center else R/(1+a*a/2).sqrt()
    w=a*(m*t).cos();wp=-m*a*(m*t).sin()
    wpp=-m*m*w;wppp=-m*m*wp
    A=scale*((arb(3)/2 if center else 1)+w)
    B=scale*(1+w);Ap=scale*wp;App=scale*wpp;Appp=scale*wppp
    c=t.cos();s=t.sin()
    dx=Ap*c-A*s;dy=Ap*s+B*c
    ddx=(App-A)*c-2*Ap*s;ddy=(App-B)*s+2*Ap*c
    dddx=(Appp-3*Ap)*c-(3*App-A)*s
    dddy=(Appp-3*Ap)*s+(3*App-B)*c
    return dx,dy,ddx,ddy,dddx,dddy

def curvature(t,R,a,center):
    x,y,xx,yy,xxx,yyy=derivatives(t,R,a,center)
    v2=x*x+y*y
    if not v2>0: return None
    v=v2.sqrt();det=x*yy-y*xx
    k=det/(v2*v)
    kp=(x*yyy-y*xxx)/(v2*v)-3*det*(x*xx+y*yy)/(v2*v2*v)
    return k,kp,v

def certify_curve(name,R,a,delta,K,n0,period=arb(1)):
    center=name=='center';stack=[(n0,j) for j in range(n0)];leaves=[]
    speedlo=arb(100);maxbound=arb(0);evaluated=0
    while stack:
        n,j=stack.pop();h=arb.pi()/n;m=(2*j+1)*h
        I=arb(m,h.upper()); ci=curvature(I,R,a,center)
        evaluated+=1
        if ci is not None:
            cm=curvature(m,R,a,center)
            bound=min(abs(ci[0]).upper(),(abs(cm[0])+h*abs(ci[1])).upper())
            if bound<K:
                speedlo=min(speedlo,ci[2].lower());maxbound=max(maxbound,bound)
                leaves.append({'n':n,'j':j,'curvature_upper':upper(bound),'speed_lower':lower(ci[2])})
                continue
        if n>=n0*2**16: raise RuntimeError(f'Unresolved curvature panel {name}, {n}, {j}')
        stack.extend([(2*n,2*j),(2*n,2*j+1)])
    if center:
        crossfactor=(arb(3)/2-a)*(1-a)-arb(5)*a/4
        H=R*crossfactor/(((arb(3)/2+6*a)**2+(1+6*a)**2).sqrt())
        X=R*(arb(3)/2+a);Y=R*(1+a)
        assert crossfactor>0
        separation=1-2*Y-2*delta
    else:
        scale=R/(1+a*a/2).sqrt()
        H=scale*(1-a)**2/((1+a)**2+9*a*a).sqrt()
        X=Y=scale*(1+a)
        separation=min(period,arb(1))-2*X-2*delta
    assert H>delta and delta*K<1 and separation>0
    return dict(kappa_cap=str(K),proved_kappa_upper=upper(maxbound),speed_lower=lower(speedlo),
                support_lower=lower(H),support_margin_lower=lower(H-delta),
                jacobian_factor_lower=lower(1-delta*K),copy_separation_margin_lower=lower(separation),
                bbox_x_upper=upper(X),bbox_y_upper=upper(Y),leaf_count=len(leaves),
                evaluations=evaluated,max_n=max(l['n'] for l in leaves),leaves=leaves)

def trace(delta,eta,K,mu):
    h=delta*K
    assert h<1 and eta>0 and delta>0
    tau=delta/6+delta*h*h/(40*(1-h*h))
    D0=(1+eta)/(2*delta);D1=(1+1/eta)*tau
    aa=D0;bb=D1+D0;cc=17*D1;lam0=arb(1)/68
    def F(lam): return (aa+bb*lam+cc*lam*lam)/(lam+mu)**2
    den=2*cc*mu-bb
    assert den<0 or den>0
    crit=(2*aa-bb*mu)/den
    vals=[F(lam0),cc]
    if crit>lam0: vals.append(F(crit))
    elif not crit<lam0: raise RuntimeError('Stationary point membership unresolved')
    C=max(v.upper() for v in vals).sqrt()
    return C,dict(delta=str(delta),eta=str(eta),kappa=str(K),tau=str(tau),
                  D0=str(D0),D1=str(D1),polynomial=[str(aa),str(bb),str(cc)],
                  derivative_denominator=str(den),stationary_point=str(crit),
                  F_lambda0=str(vals[0]),F_infinity=str(vals[1]),
                  F_stationary=str(vals[2]) if len(vals)>2 else None,C_upper=upper(C))

def main():
    p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--scan',required=True)
    p.add_argument('--output',required=True);p.add_argument('--bits',type=int,default=192)
    p.add_argument('--initial-panels',type=int,default=256);a=p.parse_args()
    ctx.prec=a.bits;ctx.threads=1;started=time.process_time()
    out=Path(a.output);data=json.loads(Path(a.input).read_text());scan=json.loads(Path(a.scan).read_text())
    pars=decode(data['curve_parameters']);k=decode(data['k'])[0];beta=decode(data['beta'])[0];d=decode(data['d'])[0]
    assert beta==arb(1)/2 and d==1 and pars[2]==arb(3)/2 and pars[3]==1 and pars[4]==1
    mu=k*k
    # Geometry bounds cover both ideal decimal parameters and saved binary64 parameters.
    Rc=hull(pars[0],arb(1)/5);b=hull(pars[1],arb(3)/10);Rl=hull(pars[7],arb(1)/5)
    left=hull(pars[5],arb(3)/25);right=hull(pars[6],arb(1)/5)
    settings=[('center',Rc,b,'64.30','2.490254'),('negative',Rl,left,'8.81','1.181583'),
              ('positive',Rl,right,'10.53','1.233941'),('walls',None,None,'0','1.035553'),('seams',None,None,'0','1.035553')]
    result={'input_schema':data['schema'],'input_keys':sorted(data),'precision_bits':a.bits,
            'curve_parameters':[str(x) for x in pars],'mu_exact_square':str(mu),'k_exact':str(k),
            'beta':str(beta),'d':str(d),'rho_min':1,'rho_max':17,'ell':1,'N':1,'lambda0':str(arb(1)/68),
            'geometry_parameter_hulls':{'Rc':str(Rc),'b':str(b),'Rl':str(Rl),'a_left':str(left),'a_right':str(right)},'groups':{}}
    for name,R,beta_shape,kcap,advertised in settings:
        s=scan['groups'][name]['used'];delta=rational_float(s['delta']);eta=rational_float(s['eta']);K=arb(kcap)
        geom=certify_curve(name,R,beta_shape,delta,K,a.initial_panels) if R is not None else {'flat_separation_margin_lower':lower(1-2*delta)}
        C,t=trace(delta,eta,K,mu)
        assert C<arb(advertised),(name,C,advertised)
        base,brec=trace(delta,eta,rational_float(s['kappa']),mu)
        relative=abs(base-rational_float(s['C']))/rational_float(s['C'])
        assert relative<arb('2e-14')
        row=dict(geometry=geom,trace=t,published_reliable_C=advertised,scan_C=s['C'],
                 relative_inflation_upper=upper(C/rational_float(s['C'])-1),
                 baseline_reproduction_relative_difference_upper=upper(relative))
        result['groups'][name]=row
        (out/'result.json').write_text(json.dumps(result,indent=2))
        print(name,'C <=',t['C_upper'],'panels',geom.get('leaf_count',0),flush=True)
    lo=(arb(659)/500)**2;hi=(arb(19)/8)**2;radius=arb(1)/10**9
    result['band_margins']={'a_star':str(lo),'b_star':str(hi),'R_max':str(radius),
                            'lower_margin':str(mu-radius-lo),'upper_margin':str(hi-mu-radius),
                            'lower_margin_reliable_lower':lower(mu-radius-lo),'upper_margin_reliable_lower':lower(hi-mu-radius)}
    result['cpu_seconds']=time.process_time()-started
    result['process_max_rss_bytes']=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    (out/'result.json').write_text(json.dumps(result,indent=2))
    print('PASS all five groups; CPU seconds',result['cpu_seconds'],flush=True)

if __name__=='__main__':main()
