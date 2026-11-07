function refit(package, fmm, output, kword)
% Rebuild the package field at one specified binary64 wavenumber.
% Input
%   package, fmm: release and FMM2D (fast multipole method) MATLAB paths.
%   output: new field directory. kword: 16 hexadecimal binary64 digits.
% Output
%   Field, source coefficients and dependency list produced by the package.
  addpath(fullfile(package, 'src', 'matlab'));
  addpath(fullfile(package, 'src', 'matlab', 'field'));
  addpath(fullfile(package, 'examples'));
  addpath(fmm);
  result = field_export(output, hex2num(kword), 'reference');
  assert(strcmp(result.k_hex, kword), 'Wavenumber changed in the field solve.');
  write_dependencies(output);
end
