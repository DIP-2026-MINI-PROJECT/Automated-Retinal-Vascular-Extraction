function M = add_metric(M, item, metric, value)
% ADD_METRIC  Append one row {item, metric, value} to a metric list.
%
%   Inputs  : M - n x 3 cell (may be empty {}); item, metric - char;
%             value - numeric scalar
%   Outputs : M - (n+1) x 3 cell
M(end + 1, :) = {item, metric, double(value)};
end
