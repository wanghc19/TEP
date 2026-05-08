function [D_out, N_out, selected] = select_port_traces(modes, traces, portSign, opts)
% SELECT_PORT_TRACES Select outgoing Bloch traces for one center port.
%
% Purpose:
%   Select outgoing or decaying Bloch mode trace matrices from one lead
%   cell for matching against a center-region port.
%
% Inputs:
%   modes:
%     Struct containing modes.lambda, the Floquet multipliers for one lead
%     cell.  The multiplier is measured from the cell left wall to the cell
%     right wall in the positive x direction.
%   traces:
%     Struct containing D_L, N_L, D_R, and N_R.  The L/R subscripts denote
%     only the left/right walls of one lead cell.
%   portSign:
%     Character or string scalar, either '+' or '-'.  The '+' port is the
%     center right port connected to the positive half-axis lead; the '-'
%     port is the center left port connected to the negative half-axis lead.
%   opts:
%     Optional struct.  opts.lambda_tol sets the selection tolerance.  The
%     default is opts.lambda_tol = 1e-8.
%
% Outputs:
%   D_out, N_out:
%     K-by-nout Dirichlet and outward-normal trace matrices for the selected
%     outgoing modes at the requested center port.
%   selected:
%     Struct with fields idx, portSign, lambda, numSelected, and tol.
%
% Notes:
%   N_L and N_R are x-derivative trace coefficients, not outward-normal
%   derivative coefficients for a center port.  For portSign = '+', the
%   center port outward normal is +e_x, so N_out = N_L(:,idx).  For
%   portSign = '-', the center port outward normal is -e_x, so the selected
%   cell right-wall trace is converted by N_out = -N_R(:,idx).

  if nargin < 3
    error('select_port_traces:InvalidPortSign', ...
      'portSign must be either ''+'' or ''-''.');
  end
  if nargin < 4 || isempty(opts)
    opts = struct();
  end
  if ~isfield(opts, 'lambda_tol') || isempty(opts.lambda_tol)
    opts.lambda_tol = 1e-8;
  end
  if ~(isscalar(opts.lambda_tol) && isfinite(opts.lambda_tol) && ...
      opts.lambda_tol >= 0)
    error('select_port_traces:InvalidLambdaTol', ...
      'opts.lambda_tol must be a nonnegative finite scalar.');
  end

  portSign = LOCAL_normalize_port_sign(portSign);

  if ~(isstruct(modes) && isfield(modes, 'lambda'))
    error('select_port_traces:MissingLambda', ...
      'modes.lambda is required.');
  end
  if ~(isvector(modes.lambda) && isnumeric(modes.lambda))
    error('select_port_traces:InvalidLambda', ...
      'modes.lambda must be a numeric vector.');
  end
  lambda = full(complex(modes.lambda(:)));
  if any(~isfinite(lambda))
    error('select_port_traces:InvalidLambda', ...
      'modes.lambda must contain only finite values.');
  end

  required_traces = {'D_L', 'N_L', 'D_R', 'N_R'};
  for j = 1:length(required_traces)
    field_name = required_traces{j};
    if ~(isstruct(traces) && isfield(traces, field_name))
      error('select_port_traces:MissingTraceField', ...
        'traces.%s is required.', field_name);
    end
    if ~(ismatrix(traces.(field_name)) && isnumeric(traces.(field_name)))
      error('select_port_traces:InvalidTraceField', ...
        'traces.%s must be a numeric matrix.', field_name);
    end
  end

  D_L = full(complex(traces.D_L));
  N_L = full(complex(traces.N_L));
  D_R = full(complex(traces.D_R));
  N_R = full(complex(traces.N_R));
  num_modes = length(lambda);

  if size(D_L, 2) ~= num_modes || size(N_L, 2) ~= num_modes || ...
      size(D_R, 2) ~= num_modes || size(N_R, 2) ~= num_modes
    error('select_port_traces:TraceModeCountMismatch', ...
      'Trace column counts must agree with length(modes.lambda).');
  end
  if ~isequal(size(D_L), size(N_L), size(D_R), size(N_R))
    error('select_port_traces:TraceSizeMismatch', ...
      'traces.D_L, traces.N_L, traces.D_R, and traces.N_R must have the same size.');
  end
  if any(~isfinite(D_L(:))) || any(~isfinite(N_L(:))) || ...
      any(~isfinite(D_R(:))) || any(~isfinite(N_R(:)))
    error('select_port_traces:InvalidTraceValues', ...
      'Trace matrices must contain only finite values.');
  end

  tol = opts.lambda_tol;
  switch portSign
    case '+'
      idx = abs(lambda) < 1 - tol;
      D_out = D_L(:, idx);
      N_out = N_L(:, idx);
    case '-'
      idx = abs(lambda) > 1 + tol;
      D_out = D_R(:, idx);
      N_out = -N_R(:, idx);
  end

  selected.idx = idx;
  selected.portSign = portSign;
  selected.lambda = lambda(idx);
  selected.numSelected = nnz(idx);
  selected.tol = tol;

end

function portSign = LOCAL_normalize_port_sign(portSign)
% LOCAL_NORMALIZE_PORT_SIGN Convert a character/string scalar to '+' or '-'.

  if isstring(portSign)
    if ~isscalar(portSign)
      error('select_port_traces:InvalidPortSign', ...
        'portSign must be either ''+'' or ''-''.');
    end
    portSign = char(portSign);
  end
  if ~(ischar(portSign) && isrow(portSign) && length(portSign) == 1 && ...
      (strcmp(portSign, '+') || strcmp(portSign, '-')))
    error('select_port_traces:InvalidPortSign', ...
      'portSign must be either ''+'' or ''-''.');
  end

end
