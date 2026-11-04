function smoke_export(out)
% Smoke export of real/complex IEEE double data in MATLAB v7 format.
% Input: probe output directory. Output: tiny MAT file with independent bits.
  maxNumCompThreads(11);if ~exist(out,'dir'),mkdir(out);end
  real_data=[pi,eps,-0;realmin,realmax,2^-1074];
  complex_data=complex([1,-3;pi,realmin],[eps,2;-sqrt(2),-0]);
  real_bits=reshape(typecast(real_data(:),'uint64'),size(real_data));
  complex_real_bits=reshape(typecast(real(complex_data(:)),'uint64'),size(complex_data));
  complex_imag_bits=reshape(typecast(imag(complex_data(:)),'uint64'),size(complex_data));
  save(fullfile(out,'smoke.mat'),'real_data','complex_data','real_bits','complex_real_bits','complex_imag_bits','-v7');
end
