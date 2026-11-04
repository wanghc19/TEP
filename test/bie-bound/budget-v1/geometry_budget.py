"""Floating geometry and trace constants for the fixed BIE error budget.
Input: explicit output directory, normal-intersection sample count, dense count.
Output: geometry.json and a compact center geometry CSV. No repository discovery.
"""
import argparse,json
from pathlib import Path
import numpy as np
from scipy.optimize import minimize_scalar
from scipy.signal import find_peaks
from scipy.spatial import cKDTree
MU=1.5584378941820909**2

def curve(name,t):
    if name=='center':
        x=.3*np.cos(t)+.03*(np.cos(6*t)+np.cos(4*t));y=.2*np.sin(t)+.03*(np.sin(6*t)-np.sin(4*t))
        dx=-.3*np.sin(t)-.03*(6*np.sin(6*t)+4*np.sin(4*t));dy=.2*np.cos(t)+.03*(6*np.cos(6*t)-4*np.cos(4*t))
        ddx=-.3*np.cos(t)-.03*(36*np.cos(6*t)+16*np.cos(4*t));ddy=-.2*np.sin(t)+.03*(-36*np.sin(6*t)+16*np.sin(4*t))
    else:
        a={'negative':.12,'positive':.20}[name];c=.2/np.sqrt(1+a*a/2);r=c*(1+a*np.cos(3*t));rp=-3*c*a*np.sin(3*t);rpp=-9*c*a*np.cos(3*t)
        x=r*np.cos(t);y=r*np.sin(t);dx=rp*np.cos(t)-r*np.sin(t);dy=rp*np.sin(t)+r*np.cos(t)
        ddx=(rpp-r)*np.cos(t)-2*rp*np.sin(t);ddy=(rpp-r)*np.sin(t)+2*rp*np.cos(t)
    sp=np.hypot(dx,dy);k=(dx*ddy-dy*ddx)/sp**3
    return np.c_[x,y],np.c_[dy/sp,-dx/sp],sp,k

def cross(a,b):return a[...,0]*b[...,1]-a[...,1]*b[...,0]
def normal_collision(z,n,other,m,shift=(0,0),same=False):
    best=np.inf;pair=None
    for first in range(0,len(z),32):
        dz=other[None,:,:]+shift-z[first:first+32,None,:];a=n[first:first+32,None,:];b=m[None,:,:]
        den=cross(a,b); good=np.abs(den)>1e-10
        t=np.divide(cross(dz,b),den,out=np.full_like(den,np.inf),where=good)
        u=np.divide(cross(dz,a),den,out=np.full_like(den,np.inf),where=good)
        val=np.maximum(abs(t),abs(u))
        col=(np.abs(cross(dz,a))<1e-11)&(~good)
        val[col]=np.linalg.norm(dz,axis=2)[col]/2
        if same:
            ii=np.arange(first,min(first+32,len(z)));val[np.arange(len(ii)),ii]=np.inf
        at=np.unravel_index(np.argmin(val),val.shape)
        if val[at]<best:best=float(val[at]);pair=[int(first+at[0]),int(at[1]),float(t[at]),float(u[at])]
    return best,pair

def supremum(poly,lam0):
    a,b,c=poly;xs=[lam0];den=2*c*MU-b
    if abs(den)>1e-30:
        t=(2*a-b*MU)/den
        if t>=lam0:xs.append(t)
    vals=[(a+b*x+c*x*x)/(x+MU)**2 for x in xs]+[c]
    j=int(np.argmax(vals));return float(vals[j]),float(xs[j]) if j<len(xs) else 'infinity'
def constant(delta,k,lam0=.25/17,eta=None):
    h=delta*k;tau=delta/6+delta*h*h/(40*(1-h*h))
    def calc(logeta):
        e=np.exp(logeta);d0=(1+e)/(2*delta);d1=(1+1/e)*tau;p=[d0,d1+d0,17*d1]
        f,at=supremum(p,lam0);return np.sqrt(f),dict(delta=float(delta),kappa=float(k),eta=float(e),D0=float(d0),D1=float(d1),poly=p,lambda_max=at,C=float(np.sqrt(f)))
    if eta is None:
        opt=minimize_scalar(lambda x:calc(x)[0],bounds=(-12,7),method='bounded',options={'xatol':1e-11});return calc(opt.x)[1]
    return calc(np.log(eta))[1]
def best_constant(maxdelta,k):
    opt=minimize_scalar(lambda d:constant(d,k)['C'],bounds=(maxdelta*.001,maxdelta*.999),method='bounded',options={'xatol':1e-10})
    return constant(opt.x,k)

def main():
    a=argparse.ArgumentParser();a.add_argument('--output',required=True);a.add_argument('--nodes',type=int,default=2048);a.add_argument('--dense',type=int,default=65536);args=a.parse_args();out=Path(args.output);out.mkdir(parents=True,exist_ok=True)
    t=np.arange(args.nodes)*2*np.pi/args.nodes;td=np.arange(args.dense)*2*np.pi/args.dense
    result={'mu':MU,'nodes':args.nodes,'dense':args.dense,'groups':{},'segments':[]}
    theta=1-.004*64;c0=1/(theta*.004);c1=.004/(2*theta)
    result['reproduction']={'draft':float(np.sqrt(c0/MU**2+(c1+c0)/(4*MU)+17*c1)),'jacobian_eta004':constant(.004,64,eta=.004)}
    for name in ['center','negative','positive']:
        z,n,sp,k=curve(name,t);zd,nd,spd,kd=curve(name,td);K=float(np.max(abs(kd)))
        own,pair=normal_collision(z,n,z,n,same=True);shifts=[(0,1)] if name=='center' else [(0,1),(1,0),(1,1),(1,-1)]
        copies=[]
        tree=cKDTree(zd)
        for shift in shifts:
            dist=float(tree.query(zd+shift)[0].min());nc,pa=normal_collision(z,n,z,n,shift)
            copies.append({'shift':shift,'distance':dist,'normal_collision':nc})
        reach=min(own,1/K,*[c['normal_collision'] for c in copies]);used=best_constant(.995*reach,K)
        result['groups'][name]={'kappa_max':K,'local_radius':1/K,'self_normal_collision':own,'self_pair':pair,'copies':copies,'delta_limit':reach,'used':used,'lambda0_zero':constant(used['delta'],K,lam0=0)}
        # Actual port distances, with neighboring y-translates and all three cells.
        result['groups'][name]['port_distances']={str(x):[float(np.min(abs(zd[:,0]+shift-x))) for shift in [0,-1,1]] for x in [-.5,.5]}
        if name=='center':
            peaks,_=find_peaks(np.r_[abs(kd),abs(kd),abs(kd)],prominence=5,distance=args.dense//12)
            peaks=peaks[(peaks>=args.dense)&(peaks<2*args.dense)]-args.dense
            result['curvature_peaks']=[{'t':float(td[i]),'kappa':float(kd[i])} for i in peaks]
            # Ten arc-length segments: five short intervals around the five valleys,
            # alternating with their lower-curvature complements. Boundaries are explicit.
            peakidx=np.sort(peaks[np.argsort(abs(kd[peaks]))[-5:]])
            boundaries=np.sort(np.mod(np.r_[td[peakidx]-.12,td[peakidx]+.12],2*np.pi))
            for j,lo in enumerate(boundaries):
                hi=float(boundaries[(j+1)%len(boundaries)]);hi+=2*np.pi*(hi<=lo)
                ts=np.linspace(lo,hi,max(64,int((hi-lo)/(2*np.pi)*args.nodes)),endpoint=True)
                zs,ns,sps,ks=curve(name,ts);Kseg=float(np.max(abs(curve(name,np.linspace(lo,hi,8193))[3])))
                ownseg,_=normal_collision(zs,ns,zs,ns,same=True)
                cpseg,_=normal_collision(zs,ns,zs,ns,(0,1))
                lim=min(1/Kseg,ownseg,cpseg);val=best_constant(.995*lim,Kseg)
                result['segments'].append(dict(index=j,t0=float(lo),t1=hi,arclength=float(np.trapezoid(sps,ts)),delta_limit=float(lim),**val))
            np.savetxt(out/'center-geometry.csv',np.c_[t,z,sp,k],delimiter=',',header='t,x,y,speed,kappa',comments='')
        print(name,K,reach,used['delta'],used['C'],flush=True)
    for name in ['walls','seams']:
        result['groups'][name]={'kappa_max':0,'spacing':1,'delta_limit':.5,'used':constant(.2,0),'lambda0_zero':constant(.2,0,lam0=0),'largest_near_half':constant(.499,0)}
    (out/'geometry.json').write_text(json.dumps(result,indent=2));print(result['reproduction'],flush=True)
if __name__=='__main__':main()
