function b=border_data(k,c,fields)
  % Build the uneliminated center and the two decaying port bases.
  % Input: real frequency k, example configuration c, and field-data flag.
  % Output: center equations J, amplitude maps Y, and orthonormal bases Z.
  c.fields=fields;
  l=search_i9_physics('leads',k,'fine',c);
  assert(l.common_gap,'border:Gap','Lead classification failed at %.17g.',k);
  center=search_i9_physics('center-blocks',k,'fine',c);
  K=l.channels.K;I=eye(K);O=zeros(K);g=l.channels.gamma_m(:);
  if isfield(center,'raw')
    a=center.raw;weight=sqrt(repmat(a.far_aux.weights(:),2,1));
    J=[a.A_QP,weight.*[a.B_L,a.B_R]];
    FL=a.F_L./weight.';FR=a.F_R./weight.';E=a.E;
  else
    weight=[];J=zeros(0,2*K);FL=zeros(K,0);FR=FL;E=center.T_LR;
  end
  n=numel(weight);empty=zeros(K,n);
  b=struct('J',J,'YL',[empty,I,O;FL,O,E],'YR',[FR,E,O;empty,O,I], ...
    'ZL',l.negative.Z,'ZR',l.positive.Z,'weight',weight,'K',K,'n',n,'gamma',g);
  if fields
    b.evidence=struct('center',center,'leads',l,'model',c.model);
    b.evidence.model.khat=k;
  end
end
