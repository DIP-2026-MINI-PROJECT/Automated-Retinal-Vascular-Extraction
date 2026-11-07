function rows = metrics_to_rows(stage, M)
% METRICS_TO_ROWS  Prefix a metric list {item, metric, value} with a stage.
%
%   Inputs  : stage - char, e.g. 'Unit 2 / DCT'; M - n x 3 cell
%   Outputs : rows  - n x 4 cell {stage, item, metric, value}
rows = [repmat({stage}, size(M, 1), 1), M];
end
