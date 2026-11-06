"""Build the B1 source-assumption CSV (comma-separated values).
Input: explicit source root, output CSV. Output: source lines and B2 actions.
This is source inventory, not a scientific runtime dependency.
"""
import argparse,csv
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--source-root',required=True);p.add_argument('--output',required=True);a=p.parse_args();root=Path(a.source_root)
rows=[]
def add(stage,path,needles,assumption,status,action):
 lines=(root/path).read_text().splitlines()
 for needle in needles:
  matches=[(i+1,s.strip()) for i,s in enumerate(lines) if needle in s]
  if not matches:raise ValueError((path,needle))
  for line,source in matches:rows.append([stage,path,line,source,assumption,status,action])
P='test/bie-bound/pipeline-v1/'
add('driver',P+'run_pipeline.py',['assert len(candidates)==1','field_export(','--states','--order',"bands['sign_tests']==472"],'fixed reference orchestration','B2','Parameterize stages; no central material; new mass and full-phase band count')
add('search','test/i9/search-v1/search_i9_config.m',["'L',1","'rho_center',4","'X_L',-0.5"],'equal widths and nonempty star','done','example_config and side-specific local coordinates')
add('search','test/i9/search-v1/search_i9_physics.m',['model.rho_lead,model,','center = LOCAL_cellmap','model.X_R-model.X_L','equal_config.model.a_positive'],'same model for all cells; star center','done','LOCAL_side; exact empty scattering; equal-lead regression also copies width and rotation')
add('geometry','test/i9/search-v1/search_i9_geometry.m',['r=c*(1+a*cos(3*t))'],'unrotated trilobe','done','Rotate position and both derivatives in experiment-local cellmap')
add('search','test/i9/search-v1/search_i9_run.m',['[center','center=','x*model.L'],'old drawing/geometry checks','inactive in adapter','Replaced by explicit geometry CSV; adapter gap path does not call LOCAL_geometry')
add('export',P+'field/pilot_config.m',["'L',1","'rho_center',4","'X_L',-0.5"],'equal widths and star','done','example_field_config')
add('export',P+'field/field_export.m',['negative=LOCAL_cellmap','positive=LOCAL_cellmap','center=LOCAL_cellmap','disk_geometry()','data.curve_parameters','cells={center','model.X_R-model.X_L','n=120;margin=.35;H=1.1'],'three nonempty cells, unit widths, fixed proxy box','partly done','Side widths/angles and empty density supported; export cell_widths/example; B fit and disks explicitly TODO_B2')
add('fit',P+'field/field_fit.m',['T=[.5','Ta=[linspace(-.5','bm=model.beta+2*pi','for j=1:3','sum(stats.rhs_columns)==195','pilot_geometry(n','src+[shifts(m),0]'],'unrotated source and nonempty center; fit-box constants are computational y-period and H, not lead length','B2','Rotate source geometry; handle zero center density explicitly. d=1 and H=1.1 may stay after box exclusion check; 195 RHS is valid with zero center column')
add('residual',P+'residual/material.py',['def geom','scale=R[0]','self.R=params'],'only unrotated star/trilobe','B2','Add rotation to geometry and derivatives; no central source object for empty cell')
add('residual',P+'residual/self_interaction.py',['def divided_chord','return -scale','x=-R*'],'unrotated chord formula','B2','Rotate divided chord consistently; invariant squared chord/curvature can retain proof with checked coordinates')
for f in ['group_setup.py','cached.py','real_panels.py','domains.py']:
 needles={'group_setup.py':["src=Sources(K,data['pieces'][0])","center=dict(","K.R=(pars[0,7].real,)","V=acb_mat(97"], 'cached.py':["piece=data['pieces'][0]"], 'real_panels.py':["piece=data['pieces'][0]"], 'domains.py':["piece=data['pieces'][0]","radius<arb('.360004')"]}[f]
 add('residual',P+'residual/'+f,needles,'mandatory center curve/cache; geometry conventions','B2','Skip central source/self caches and center material targets; retain empty homogeneous field for walls/seams')
add('residual',P+'residual/extended.py',['wall=-arb(sign)/2','modes=range(-48,49)','for j in range(194)','for j in range(40)'],'unit port anchoring and fixed channel dimensions','B2','Pass own cell half-width; M=48 retained but derived dimensions; actual state depth independent per lead')
add('residual',P+'residual/panel.py',['wall=-arb(sign)/2','maxy<arb(\'.5\')','sep=min('],'unit center ports and zero-wrap/proxy geometry test','B2','No center-material calls; explicitly recheck zero-wrap/proxy separation for rotated leads')
add('residual',P+'residual/boundary_group.py',["if kind=='seam':h=",'coordinate=-arb',"sg/2","ar=(arb('.5')"],'unit cell walls and seam lengths','B2','Junction local coordinates use L0/2 and Ls/2 separately; seam length Ls; d remains 1; recompute radii/envelopes')
add('residual',P+'residual/wall_columns.py',["arb('-.5')","arb('.5')"],'unit-cell pilot wall positions','B2','Update diagnostic/reference wall code with same side widths')
add('residual',P+'residual/tail_bound.py',["arb('.5')-radius","(arb(1)/2).sqrt()","Radial(K.k,arb(17))","for m in range(-48,49)"],'unit square envelope; fixed material/channels','B2','Use actual rectangle radius and min distance; rho17 and M48 unchanged; certify new contraction and choose N')
add('residual',P+'residual/groups.py',["SHARED['center']", "range(192)", "vals=[central", "for side in [1,2]", "h=arb.pi()/(192", "U=arb('1.23587')"],'five positive groups and central tasks; old mixed assembly','B2','Four nonzero groups, center epsilon exactly zero; dynamic coverage; remove old mass/caps from general path')
add('audit',P+'residual/audit_groups.py',['expected={','vals[0]'],'fixed central coverage','B2','Independent coverage generated from explicit empty-center geometry; zero central sum valid')
add('audit',P+'residual/audit_curve.py',["r['count']==192",'coverage[-1][1]==192'],'mandatory central curve','inactive for new example','Omit central-curve audit; retain audits of all nonempty groups')
add('mass',P+'field/disk_geometry.m',["h={"],'eight reference disks, six in center material','B2','Select new disks; central background Rayleigh field admits disks but requires rho1 path')
add('mass',P+'mass/disks.py',['if kind==0','abs(x)+r<','D.nrows()==8','range(8)','rho in [4,17]','[0,-1,1]'],'old shapes, positions and mass layout','B2','Rotate lead geometry; centers +/- (L0+Ls)/2; allow background disks; choose new U instead of reusing 1.23587')
add('mass',P+'mass/material.py',['def geom'],'duplicate unrotated geometry','B2','Same geometry plumbing as residual geometry')
add('constants',P+'enclosure/trace_constants.py',['separation=1-2','X=Y=scale','settings=[','lo=(arb(659)'],'unit copy separation and old published caps/endpoints','B2','Retain rotation-invariant curvature/support formulas; prove copy/collar separation using Ls,d; recompute C at new mu')
add('assembly',P+'enclosure/assemble.py',['PARAMS=','model=dict(L_left','L_left\']==','if j<3','bbox_x_upper','assert 1-2','all(Fraction(x)>0','U=arb(\'1.23587\')','len(disks[\'rows\'])==8','rho\']) in','aa=(arb(659)','Fraction(\'1.23587\')'],'unit geometry, 5 positive groups, old mass/caps/gap','B2','Accept zero absent group; explicit model, C/U/gap handoffs; preserve outward and rational assembly')
for f in ['floating.py','original_reference.py']:
 add('band',P+'band/'+f,['KLOW, KHIGH','END =','[0, pi]','2 * np.pi * m','2*np.pi*MN[:,0]','for a in (.12','(.5+'] if f=='floating.py' else ['KLOW, KHIGH','END =','[0, pi]','2 * np.pi * m','for a in (.12','(.5 +','symmetry'],'unit reciprocal lattice/normalization and half-phase cover','B2','Full [-pi/Ls,pi/Ls] cover; Fourier coefficients/(Ls*d); rotated curve; new endpoint pair')
add('band',P+'band/band_certificate.py',['48*pi*Cim','I*2*pi*m*x','coeff[m,n]','l,h=END','2*pi*int(m)+theta','14*pi-theta','panels=118','L=1','range(118)'],'unit lattice, half-phase integer panels, unrotated analytic envelope','B2','Reprove coefficient envelope with rotated curve and scaled x frequencies; full-phase panels; tail uses abs(theta); keep Arb sign tests')
add('figures',P+'paper_records.py',['if cell==0:','rr=pars[7]',"cell*model['L']"],'old star/unit translations','done for B1','bands.py writes actual rotated, unequally translated curves; no center curve')
add('residual',P+'residual/curve_queue.py',["DATA['pieces'][0]","192*2**depth"],'mandatory central-curve queue','B2','Do not enqueue central targets or construct their cache; preserve worker initialization and other groups')
add('residual',P+'residual/aggregation.py',["piece=data['pieces'][0]"],'old central proxy-aggregation entry','inactive for new center','Empty center has no source aggregation; general B point-source lead expansions remain')
add('mass',P+'mass/self_interaction.py',['x=-R*'],'unused central divided-chord helper','inactive in disks entry','Mass imports only box and fourier_bound from this file; no central Kress call is needed')
unique={}
for row in rows:unique.setdefault((row[1],row[2]),row)
rows=list(unique.values())
with Path(a.output).open('w') as f:
 w=csv.writer(f);w.writerow(['stage','file','line','source','assumption','status','action']);w.writerows(rows)
print(len(rows),'inventory entries')
