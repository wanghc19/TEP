function rounding_scalars(out)
% Scalar comparison samples for rounding error estimates.
% Input: output directory. Output: MATLAB values of phases, constants, curves.
  k=(-16:16)';beta=.5+2*pi*k;kappa=sqrt(1+beta.^2);phase=exp(.5i);alpha=[1.32^2,2.37^2,1.7424,5.6169];
  ng=320;theta=(0:2*ng-1)'*pi/ng;curves=zeros(2*ng,6);
  for j=1:3
    if j==2
      x=.2*(1.5+.3*cos(5*theta)).*cos(theta);y=.2*(1+.3*cos(5*theta)).*sin(theta);
    else
      aa=.12;if j==3,aa=.20;end;r=.2/sqrt(1+aa^2/2)*(1+aa*cos(3*theta));x=r.*cos(theta);y=r.*sin(theta);
    end
    cell_index=j-2;x=(x+cell_index)-cell_index;curves(:,2*j-1:2*j)=[x,y];
  end
  save(fullfile(out,'scalars.mat'),'phase','alpha','beta','kappa','curves','theta','-v7');
end
