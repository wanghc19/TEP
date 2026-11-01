"""Build the initial pipeline copies; no scientific execution.
RT means Raviart-Thomas. Sources are the protected goerisch-v1 helpers.
"""
from pathlib import Path
p=Path(__file__).resolve().parent
src=p.parent/'goerisch-v1'
(p/'goerisch_fitted_geometry.m').write_text((src/'goerisch_fitted_geometry.m').read_text())
s=(src/'goerisch_flux_study.m').read_text()
helpers=s[s.index('function check=LOCAL_native_trace'):]
# The new batch engine is provided separately below.
a=helpers.index('function [H,b,sc,cache]=LOCAL_forms')
b=helpers.index('function audit=LOCAL_audit',a)
helpers=helpers[:a]+helpers[b:]
# Skip direct-field derivatives when only the value is requested.
helpers=helpers.replace('gx=values;gy=values;\n  B=', 'if nargout>1,gx=values;gy=values;end\n  B=')
helpers=helpers.replace('    ux=c(:,2)+2*c(:,4).*x+c(:,5).*y;uy=c(:,3)+c(:,5).*x+2*c(:,6).*y;\n    dx=(J(:,4).*ux-J(:,3).*uy)./det;dy=(-J(:,2).*ux+J(:,1).*uy)./det;','    if nargout>1\n      ux=c(:,2)+2*c(:,4).*x+c(:,5).*y;uy=c(:,3)+c(:,5).*x+2*c(:,6).*y;\n      dx=(J(:,4).*ux-J(:,3).*uy)./det;dy=(-J(:,2).*ux+J(:,1).*uy)./det;\n    end')
helpers=helpers.replace('values(:,j)=chi.*u;gx(:,j)=chi.*dx+dchi.*u;gy(:,j)=chi.*dy;','values(:,j)=chi.*u;\n    if nargout>1,gx(:,j)=chi.*dx+dchi.*u;gy(:,j)=chi.*dy;end')
(p/'pipeline_helpers.txt').write_text(helpers)
# Construct from the source's loading/sweep block and retain exact helper code.
s=(src/'goerisch_trial.m').read_text()
a=s.index('  p = struct(');b=s.index('  integration_start = tic;')
body=s[a:b]
body=body.replace("  LOCAL_json(fullfile(output_dir,'assembly.json'),base);\n  mode_table = table(m,q,mode_norm,mode_gradient);\n  writetable(mode_table,fullfile(output_dir,'modes.csv'));",'')
body=body.replace('  assembly_start = tic;','  assembly_start = tic; input_seconds=0; coefficient_seconds=0;')
body=body.replace("        d = load(file,key,'cols'); Fb = d.(key);","        io_timer=tic;d = load(file,key,'cols'); Fb = d.(key);")
body=body.replace("        assert(size(Fb,4)","        input_seconds=input_seconds+toc(io_timer);\n        assert(size(Fb,4)")
body=body.replace('    Y = LOCAL_build','    coefficient_timer=tic;Y = LOCAL_build')
body=body.replace('    coefficients(mi,:,:) = Y.coefficients;', '    coefficient_seconds=coefficient_seconds+toc(coefficient_timer);\n    coefficients(mi,:,:) = Y.coefficients;')
head='''function [result,trial] = pipeline_reconstruction(action,input,reference)
  % Reconstruction stages for the saved control field; I9.6 is experiment 9.6.
  % Input
  %   action: 'prepare' with input directory, or 'verify' with trial and norms.
  % Output
  %   result: scalar norms/checks; trial: in-memory coefficients, never saved.
  % Source: goerisch-v1/goerisch_trial.m; closed-form formulas unchanged.
  started=tic;
  if strcmp(action,'verify')
    trial=input;result=LOCAL_verify(trial,reference);return
  end
  assert(strcmp(action,'prepare'));input_dir=input;level='control';
'''
end='''  timer=tic;mass_fine=total_norm;inclusions=struct([]);
  for t=1:3
    cv=LOCAL_curve(p,t);geometry=LOCAL_arcs(cv);
    hi=LOCAL_inclusions(coefficients,N,nc,cv,geometry,cell_lists{t},32,[]);
    rho=17;if t==2,rho=4;end
    mass_fine=mass_fine+(rho-1)*sum(hi.mass(:,1));
    inclusions=[inclusions,struct('cells',cell_lists{t},'rho',rho,'mass_fine',hi.mass(:,1)', ...
      'relative_area_error',abs(hi.area-geometry.area)/geometry.area)]; %#ok<AGROW>
  end
  result=base;result.inclusions=inclusions;result.denominator=mass_fine;
  result.theta=gradient_identity/mass_fine;
  result.timing=struct('source_input',input_seconds,'coefficient_build',coefficient_seconds, ...
    'source_assembly_other',assembly_seconds-input_seconds-coefficient_seconds, ...
    'normalization',toc(timer));
  result.timing.other=toc(started)-sum(cell2mat(struct2cell(result.timing)));
  trial=struct('coefficients',coefficients,'wl',wl,'wr',wr,'parameters',p,'cell_lists',{cell_lists});
end
function result=LOCAL_verify(trial,norms)
  p=trial.parameters;mass16=norms.norm;mass32=norms.norm;mass_y=norms.norm*[1,1];
  for t=1:3
    cv=LOCAL_curve(p,t);geometry=LOCAL_arcs(cv);cells=trial.cell_lists{t};
    lo=LOCAL_inclusions(trial.coefficients,p.N,p.cells_per_side,cv,geometry,cells,16,[]);
    hi=LOCAL_inclusions(trial.coefficients,p.N,p.cells_per_side,cv,geometry,cells,32,[128,256]);
    rho=17;if t==2,rho=4;end
    mass16=mass16+(rho-1)*sum(lo.mass(:,1));mass32=mass32+(rho-1)*sum(hi.mass(:,1));
    mass_y=mass_y+(rho-1)*sum(hi.mass(:,2:3),1);
  end
  result=struct('mass16',mass16,'mass32',mass32,'mass_y',mass_y, ...
    'theta_change_x',norms.theta-norms.numerator_identity/mass16, ...
    'theta_change_y',diff(norms.numerator_identity./mass_y), ...
    'theta_y_fine_minus_exact',norms.numerator_identity/mass_y(2)-norms.theta, ...
    'primary_mass_relative_change',abs(mass32-norms.denominator)/norms.denominator);
  result.pass=max(abs([result.theta_change_x,result.theta_change_y,result.theta_y_fine_minus_exact]))<1e-10 ...
    &&result.primary_mass_relative_change<1e-12;
end
'''
(p/'pipeline_reconstruction.m').write_text(head+body+end+s[s.index('function Y = LOCAL_build'):])
