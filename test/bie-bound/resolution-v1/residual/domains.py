# Copied from test/bie-bound/pipeline-v1/residual/domains.py.
# Copied from test/bie-bound/grouprel-v1/domains.py; pipeline adaptations documented in README.
"""Global physical disk and target-strip certificates for proxy aggregation.
Input: exact field and explicit radii/partition. Output: PA10--PA13 bounds.
PA denotes the equations in the proxy-acceleration design.
"""
from flint import arb,acb
from material import I,geom,matrix,up
from panel import absolute_vec,geometry_certificate

def certify(K,data,S,R,rs):
  pi=arb.pi();deriv=arb(0);mins=arb(100);vn=arb(0)
  for j in range(512):
    real=arb((2*j+1)*pi/512,(pi/512).upper())
    for l in range(8):
      t=acb(real,arb(-rs+(2*l+1)*rs/8,(rs/8).upper()))
      _,_,dx,dy=geom(t,K.R,K.b)
      deriv=max(deriv,abs(dx+I*dy).upper(),abs(dx-I*dy).upper())
      mins=min(mins,(dx*dx+dy*dy).real.lower())
      vn=max(vn,absolute_vec(dx,dy))
  assert mins>0
  speed=vn;normal=vn/mins.sqrt();delta=rs*deriv
  dmin=arb(100);dmax=arb(0)
  for j in range(S):
    x,y,_,_=geom((2*j+1)*pi/S,K.R,K.b)
    for X,Y,c in K.charges:
      d=((x+X)**2+(y+Y)**2).sqrt();dmin=min(dmin,d.lower());dmax=max(dmax,d.upper())
  radius=arb(0);real_speed=arb(0)
  for j in range(1024):
    t=arb((2*j+1)*pi/1024,(pi/1024).upper());x,y,dx,dy=geom(t,K.R,K.b)
    radius=max(radius,abs(acb(x,y)).upper());real_speed=max(real_speed,absolute_vec(dx,dy))
  assert R+delta<dmin and radius<R and real_speed<1
  lo=(dmin-R-delta)**2;Q=(dmax+R+delta)**2
  logq=max(abs((dmin*dmin).log()),abs((dmax*dmax).log()))-2*(1-(R+delta)/dmin).log()
  b0=K.k*K.k/4;base=(b0*Q).exp();C0=arb(1)/4+(abs((K.k/2).log())+arb.const_euler())/(2*pi)
  core=[b0**m*base*(logq/(4*pi)+C0+(m+b0*Q)/(2*pi)) for m in range(3)]
  g0=core[0];g1=core[1]+base/(4*pi*lo);g2=core[2]+base*(2*b0/lo+1/lo**2)/(4*pi)
  dd=dmax+R+delta;sumc=sum((abs(c).upper() for X,Y,c in K.charges),arb(0))
  major=(sumc*speed*(g0+2*(normal+1)*dd*g1+normal*(2*g1+4*dd*dd*g2))).upper()
  piece=data['pieces'][0];Ct=matrix(piece['tau_coeff']);Cz=matrix(piece['zeta_coeff'])
  D=(2*pi*sum((absolute_vec(Ct[j,0],Cz[j,0]) for j in range(Ct.nrows())),arb(0))).upper()
  B=(major*D).upper()
  # A finite rectangle cover of the full parameter strip certifies every target disk.
  rad=arb(0);tspeed=arb(100);tvn=arb(0);a=arb('.04')
  for j in range(512):
    for l in range(16):
      t=acb(arb((2*j+1)*pi/512,(pi/512).upper()),arb(-a+(2*l+1)*a/16,(a/16).upper()))
      x,y,dx,dy=geom(t,K.R,K.b)
      rad=max(rad,abs(x+I*y).upper(),abs(x-I*y).upper())
      tspeed=min(tspeed,(dx*dx+dy*dy).real.lower());tvn=max(tvn,absolute_vec(dx,dy))
  assert tspeed>0
  trace=tvn.sqrt()*max(arb(1),tvn/tspeed.sqrt())
  assert rad<R and trace<3 and radius<arb('.360004') and B<arb('1.576e11')
  rec=dict(source_speed_lower=str(mins),source_speed_upper=up(speed),source_normal_upper=up(normal),delta_upper=up(delta),dmin=str(dmin),dmax=str(dmax),separation_margin_lower=str((dmin-R-delta).lower()),real_radius_upper=up(radius),real_speed_upper=up(real_speed),M_source_upper=up(major),density_integral_upper=up(D),B_upper=up(B),target_radius_upper=up(rad),target_speed_lower=str(tspeed),target_trace_upper=up(trace),branch=geometry_certificate(K,data))
  return dict(R=R,a=radius,major=major,D=D,B=B,record=rec)
