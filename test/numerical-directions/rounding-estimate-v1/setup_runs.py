"""Prepare local copies used to measure floating rounding sensitivities.
Input: existing read-only experiments. Output: copied and instrumented sources.
"""
from pathlib import Path
import shutil
root=Path.cwd();base=root/'test/numerical-directions/rounding-estimate-v1'
assert not (base/'band/band_estimate.m').exists(), 'Initial copy helper only; use launch.py for reproduction.'
for sub in ['band','core','qj']:(base/sub).mkdir(exist_ok=True)
# Retain the original formulas; add only exports and norm diagnostics.
s=(root/'tmp/h-cert-check/band_reproduce.m').read_text().replace('function band_reproduce()','function band_estimate(out)')
s=s.replace('lower_min = inf;',"rows=[];worst=inf;\nlower_min = inf;")
s=s.replace('e1 = eig(LOCAL_h(K-low*M)); e2 = eig(LOCAL_h(K-high*M-high^2/den*G));',"Alo=LOCAL_h(K-low*M);Ahi=LOCAL_h(K-high*M-high^2/den*G);\n    [V,D]=eig(Alo);[e1,ix]=sort(real(diag(D)));v=V(:,ix(1));e2=eig(Ahi);")
s=s.replace('lower_min = min(lower_min,neg);',"if neg<worst,worst=neg;panel_matrix=Alo;panel_vector=v;panel_value=e1(1);panel_info=[p,s,theta,r,low];end\n    rows=[rows;[p,s,theta,r,neg,pos,norm(Alo,1),norm(Ahi,1),norm(M,1),norm(G,1),low,high,den]]; %#ok<AGROW>\n    lower_min = min(lower_min,neg);")
s=s.replace("for s=1:2\n  K =", "if ~exist(out,'dir'),mkdir(out);end\nsave(fullfile(out,'panel.mat'),'panel_matrix','panel_vector','panel_value','panel_info','-v7');\nwritematrix(rows,fullfile(out,'panels.csv'));\ninfo=struct('lower_min',lower_min,'upper_min',upper_min,'den_min',den_min,'dimension',DIM,'panels',118,'columns',{{'panel','material_index','theta','radius','lower_margin','upper_margin','lower_norm1','upper_norm1','M_norm1','G_norm1','low','high','den'}});\nf=fopen(fullfile(out,'result.json'),'w');fprintf(f,'%s\\n',jsonencode(info));fclose(f);\nfor s=1:2\n  K =")
s=s.replace('B = coeff(sub2ind',"B = coeff(sub2ind")
(base/'band/band_estimate.m').write_text(s)
for p in (root/'test/numerical-directions/h-core-v1').glob('*.m'):shutil.copy2(p,base/'core'/p.name)
s=(base/'core/core_run.m').read_text().replace('function R=core_run','function R=core_estimate')
s=s.replace("Q=(lambda+1)*S.M1", "asm=struct('Pnorm1',norm(S.P,1),'Pnorminf',norm(S.P,inf),'M1norm1',norm(S.M1,1),'Astar_norm1',norm(A,1),'Bnorm1',norm(B,1),'Unorm1',norm(U,1),'Unorminf',norm(U,inf),'leftnorm1',norm(L,1),'rightnorm1',norm(Rr,1),'Bleftnorm1',norm(S.B_left,1),'Bleftnorminf',norm(S.B_left,inf),'Brightnorm1',norm(S.B_right,1),'Brightnorminf',norm(S.B_right,inf));\n  Q=(lambda+1)*S.M1")
s=s.replace('center=eye(n)-Q/S.c_W+B;',"asm.Qnorm1=norm(Q,1);asm.squared_factor_envelope=norm(abs(U)'*abs(U),1);asm.material_envelope=norm(abs(S.P)'*abs(A)*abs(S.P),1);\n  center=eye(n)-Q/S.c_W+B;") if False else s
# A is cleared before this location; its absolute-transform envelope is recorded earlier.
s=s.replace("Q=(lambda+1)*S.M1+3*lambda*full(S.P'*A*S.P);", "asm.material_envelope=norm(abs(S.P)'*abs(A)*abs(S.P),1);asm.squared_factor_envelope=norm(abs(U)'*abs(U),1);\n  Q=(lambda+1)*S.M1+3*lambda*full(S.P'*A*S.P);")
s=s.replace('center=eye(n)-Q/S.c_W+B;',"asm.Qnorm1=norm(Q,1);center=eye(n)-Q/S.c_W+B;")
s=s.replace('resL=norm(center*ve-ve*de,\'fro\');clear ve',"resL=norm(center*ve-ve*de,'fro');[~,ix]=sort(real(diag(de)));eigenvectors=ve(:,ix);clear ve")
s=s.replace('[count,pivot]=LOCAL_inertia(center-epsilon*eye(n));',"L_fixed=center-epsilon*eye(n);norm_center=norm(center,1);norm_fixed=norm(L_fixed,1);\n  save(fullfile(out,'core.mat'),'L_fixed','eigenvectors','evL','epsilon','asm','norm_center','norm_fixed','-v7');\n  [wide_count,wide_pivot]=LOCAL_inertia(L_fixed-.36*eye(n));\n  [count,pivot]=LOCAL_inertia(L_fixed);")
s=s.replace("'symmetry_H',0,", "'wide_count',wide_count,'wide_pivot',wide_pivot,'norm_center',norm_center,'norm_fixed',norm_fixed,'assembly',asm,'symmetry_H',0,")
(base/'core/core_estimate.m').write_text(s)
for p in (root/'test/numerical-directions/qj-cert-v2').glob('*.m'):shutil.copy2(p,base/'qj'/p.name)
