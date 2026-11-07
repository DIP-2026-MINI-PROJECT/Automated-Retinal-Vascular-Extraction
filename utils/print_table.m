function print_table(titleText, header, rows)
% PRINT_TABLE  Print a cell table to the console with aligned columns.
%
%   print_table(titleText, header, rows)
%
%   Inputs  : titleText - heading printed above the table
%             header    - 1 x c cellstr
%             rows      - r x c cell of char / numeric entries
%   Outputs : none
txt = cell(size(rows));
for k = 1:numel(rows)
    v = rows{k};
    if ischar(v), txt{k} = v; else, txt{k} = sprintf('%.4g', v); end
end
tbl = [header; txt];
w = max(cellfun(@length, tbl), [], 1) + 2;
fprintf('\n  %s\n', titleText);
sep = repmat('-', 1, sum(w) + 2);
fprintf('  %s\n', sep);
for i = 1:size(tbl, 1)
    fprintf('  ');
    for j = 1:size(tbl, 2)
        fprintf('%-*s', w(j), tbl{i, j});
    end
    fprintf('\n');
    if i == 1, fprintf('  %s\n', sep); end
end
fprintf('  %s\n', sep);
end
