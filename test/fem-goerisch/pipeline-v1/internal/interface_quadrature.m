function r=interface_quadrature(P,S,cfg,scope)
  % INTERFACE_QUADRATURE Independently sample the original interface field.
  % Input
  %   Rebuilt field/flux, configuration and full/probe scope.
  % Output
  %   Q16/Q24 per-template values, with taper retained.
  rows=struct([]);orders=cfg.orders;
  for ti=1:3
    name=P.templates{ti}.T.name;if startsWith(scope,'full-')&&~strcmp(scope,['full-',name]),continue,end
    G=P.templates{ti}.G;T=P.templates{ti}.T;arcs=1:numel(T.interface.theta);if strcmp(scope,'probe'),arcs=[1,81,161,241];end
    use=false(G.nt,1);use([T.interface.inner(arcs);T.interface.outer(arcs)])=true;vals=zeros(1,2);taper=vals;
    for io=1:2
      rules=G.fitted.rules(orders(io));
      for ri=1:numel(rules)
        rule=rules{ri};idsall=rule.ids(use(rule.ids));if isempty(idsall),continue,end;nq=numel(rule.w);[vx,vy,dv]=LOCAL_rt(rule.x,rule.y);vx=vx*S.B;vy=vy*S.B;dv=dv*S.B;
        for first=1:cfg.block:numel(idsall)
          ids=idsall(first:min(first+cfg.block-1,numel(idsall)));nb=numel(ids);ei=repelem(ids(:),nq);x=repmat(rule.x,nb,1);y=repmat(rule.y,nb,1);
          [X,Y,J,d]=G.fitted.map(ei,x,y);[ee,xx,yy,JN,dn]=G.fitted.inverse_native(ei,X,Y);[v,gx,gy]=LOCAL_field(G,ee,xx,yy,X,JN,dn,cfg);
          px=repmat(vx,nb,1);py=repmat(vy,nb,1);dd=repmat(dv,nb,1);fx=LOCAL_flux((J(:,1).*px+J(:,2).*py)./d,S.flux{ti},ei);fy=LOCAL_flux((J(:,3).*px+J(:,4).*py)./d,S.flux{ti},ei);fd=LOCAL_flux(dd./d,S.flux{ti},ei);
          W=repmat(rule.w,nb,1).*d;rho=repelem(T.material(ids),nq);s=P.q;vv=W.*(abs(fx-gx/s).^2+abs(fy-gy/s).^2+abs(fd+rho*(1-1/s).*v).^2./rho);
          vals(io)=vals(io)+sum(vv,'all');taper(io)=taper(io)+sum(vv(:,abs(G.cells)>=G.taper.first_cell),'all');
        end
      end
    end
    item=struct('template',name,'Q16',vals(1),'Q24',vals(2),'taper_Q16',taper(1),'taper_Q24',taper(2));if isempty(rows),rows=item;else,rows(end+1)=item;end
  end
  r=struct('templates',rows,'Q16',sum([rows.Q16]),'Q24',sum([rows.Q24]),'taper_Q16',sum([rows.taper_Q16]),'taper_Q24',sum([rows.taper_Q24]));
end
function [P,Px,Py]=LOCAL_mono(x,y,k)
  % LOCAL_mono Mono.
  % Input
  %   x,y,k.
  % Output
  %   [P,Px,Py].
  P=zeros(numel(x),(k+1)*(k+2)/2);Px=P;Py=P;n=0;
  for d=0:k,for j=0:d,n=n+1;a=d-j;b=j;P(:,n)=x.^a.*y.^b;if a>0,Px(:,n)=a*x.^(a-1).*y.^b;end;if b>0,Py(:,n)=b*x.^a.*y.^(b-1);end,end,end
end
function [x,y,d]=LOCAL_rt(a,b)
  % LOCAL_rt Rt.
  % Input
  %   a,b.
  % Output
  %   [x,y,d].
  [P,Px,Py]=LOCAL_mono(a,b,3);H=zeros(numel(a),4);for j=0:3,H(:,j+1)=a.^(3-j).*b.^j;end;z=zeros(size(P));x=[P,z,a.*H];y=[z,P,b.*H];d=[Px,Py,5*H];
end
function v=LOCAL_flux(P,c,ei)
  % LOCAL_flux Flux.
  % Input
  %   P,c,ei.
  % Output
  %   v.
  v=complex(zeros(numel(ei),size(c,2)));for j=1:size(c,2),v(:,j)=sum(P.*reshape(c(:,j,ei),size(c,1),[]).',2);end
end
function [v,gx,gy]=LOCAL_field(G,e,x,y,X,J,d,cfg)
  % LOCAL_field Field.
  % Input
  %   G,e,x,y,X,J,d,cfg.
  % Output
  %   [v,gx,gy].
  [B,Bx,By]=LOCAL_mono(x,y,3);n=numel(x);nc=numel(G.cells);v=complex(zeros(n,nc));gx=v;gy=v;
  for j=1:nc
    c=G.field_coefficients(e,:,j);u=sum(B.*c,2);ux=sum(Bx.*c,2);uy=sum(By.*c,2);dx=(J(:,4).*ux-J(:,3).*uy)./d;dy=(-J(:,2).*ux+J(:,1).*uy)./d;
    xx=X+G.cells(j);t=max(0,min(1,(abs(xx)-cfg.model.taper.start)/cfg.model.taper.width));chi=(1+cos(pi*t))/2;dchi=-(pi/(2*cfg.model.taper.width))*sin(pi*t).*sign(xx);v(:,j)=chi.*u;gx(:,j)=chi.*dx+dchi.*u;gy(:,j)=chi.*dy;
  end
end
