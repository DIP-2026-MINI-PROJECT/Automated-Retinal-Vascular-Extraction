function write_csv(path, header, rows)
% WRITE_CSV  Write a cell table to a CSV file (works without writetable).
%
%   write_csv(path, header, rows)
%
%   Inputs  : path   - output file
%             header - 1 x c cellstr of column names
%             rows   - r x c cell; char or numeric entries
%   Outputs : none (file written)
fid = fopen(path, 'w');
if fid < 0
    error('write_csv:open', 'Cannot write %s', path);
end
cleaner = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', strjoin(header, ','));
for i = 1:size(rows, 1)
    cells = cellfun(@cell2str, rows(i, :), 'UniformOutput', false);
    fprintf(fid, '%s\n', strjoin(cells, ','));
end
fprintf('      saved %s\n', path);
end

function s = cell2str(v)
if ischar(v)
    s = v;
    if any(v == ',') || any(v == '"')
        s = ['"' strrep(v, '"', '""') '"'];
    end
elseif isempty(v)
    s = '';
else
    s = sprintf('%.6g', v);
end
end
