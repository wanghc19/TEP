function a=log_det(A)
  % Compute the logarithmic modulus and unit phase of a complex determinant.
  % Input: square matrix. Output: [log modulus, phase in radians].
  if isempty(A),a=[0,0];return;end
  [~,U,p]=lu(A,'vector');z=diag(U);
  inversions=0;for j=1:numel(p),inversions=inversions+sum(p(j+1:end)<p(j));end
  a=[sum(log(abs(z))),angle(exp(1i*(pi*mod(inversions,2)+sum(angle(z)))))];
end
