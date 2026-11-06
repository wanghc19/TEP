function e=example_parameters(input)
%EXAMPLE_PARAMETERS Read one explicit release example model.
% Input: JSON scientific-settings path supplied by the driver.
% Output: model struct, with JSON decimal values rounded to binary64.
  c=jsondecode(fileread(input));e=c.model;
  assert(e.empty_center && e.d==1 && e.beta==.5);
  assert(e.L_negative==1 && e.L_positive==.85 && e.angle_positive==.13);
end
