function [H,cv,ol,orr]=border_matrix(b,anchor)
  % Assemble the square matrix in an anchored chart or the raw unitary basis.
  % Input: center/lead data b and an optional pair of reference bases.
  % Output: bordered matrix H, overlap diagnostics, and basis changes.
  K=b.K;
  if nargin<2
    ol=eye(K);orr=ol;cv=[1,1,1,1];zl=b.ZL;zr=b.ZR;
  else
    ol=anchor.L'*b.ZL;orr=anchor.R'*b.ZR;
    a=svd(ol);d=svd(orr);cv=[a(end),d(end),a(1)/a(end),d(1)/d(end)];
    if min(cv(1:2))<.05 || max(cv(3:4))>20,H=[];return;end
    zl=b.ZL/ol;zr=b.ZR/orr;
  end
  H=[b.J,zeros(b.n,2*K);b.YL,-zl,zeros(2*K,K);b.YR,zeros(2*K,K),-zr];
end
