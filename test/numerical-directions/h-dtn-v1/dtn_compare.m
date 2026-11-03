function dtn_compare(out)
% DtN means Dirichlet-to-Neumann: original-pipeline floating sanity matrices.
% Input: output directory. Output: P3/g48 nodal Fourier quadratic forms.
  maxNumCompThreads(11);if ~exist(out,'dir'),mkdir(out);end;records=struct([]);timer=tic;
  for name={'left','right'}
    side=name{1};C=dtn_native('endpoint','g48',3,side,16,false,out);
    beta=.5+2*pi*(-16:16);G=exp(1i*C.wall_y*beta);D=G'*C.D*G;D=(D+D')/2;
    r=struct('side',side,'group','g48','degree',3,'wall_count',size(C.D,1),'triangles',size(C.T.tri6,1), ...
      'D_real',real(D),'D_imag',imag(D),'qz_hermitian',C.qz.hermitian_defect);
    clear C
    C=dtn_native('endpoint','g48',4,side,16,true,out);B=dtn_bounds(C);P=C.transfer;power=P;length=1;
    k=-16:16;low=abs(k)<=5;U=C.field_map*exp(1i*C.wall_y*(.5+2*pi*k(low)));
    ids=find(abs(C.dof_xy(:,1)-C.near)<1e-11);[~,ix]=sort(C.dof_xy(ids,2));ids=ids(ix);
    C.trace_y=C.dof_xy(ids(1:C.degree:end),2);C.trace_values=U(ids,:);
    r.trace_check=dtn_trace_check(C,struct('k',k,'low',low,'first_field',U));
    for j=1:20
      if norm(power)<1e-15,break;end
      power=power*power;length=2*length;
    end
    eta=norm(power);assert(eta<1);
    r.geometry=struct('max_eta',max(B.eta),'max_physical_eta',max(B.eta_physical),'min_det',min(B.det_lower),'curved_collar_clearance',B.collar_clearance);
    r.series=struct('length',length,'power_norm',eta,'relative_tail_factor',eta^2/(1-eta^2));
    records=[records;r];clear C
    fprintf('original FE DtN %s complete %.1f s\n',side,toc(timer));
  end
  f=fopen(fullfile(out,'fe-dtn.json'),'w');fprintf(f,'%s\n',jsonencode(records));fclose(f);
end
