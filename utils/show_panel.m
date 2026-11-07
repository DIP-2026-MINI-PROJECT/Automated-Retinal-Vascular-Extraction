function ax = show_panel(rows, cols, idx, img, ttl, range)
% SHOW_PANEL  Show one image in a subplot with a title and the axis off.
%
%   ax = show_panel(rows, cols, idx, img, ttl)
%   ax = show_panel(rows, cols, idx, img, ttl, range)
%
%   Inputs  : rows, cols, idx - subplot grid and position
%             img   - grayscale, RGB or logical image
%             ttl   - title text (char or cellstr for several lines)
%             range - (optional) display range [lo hi]; [] = auto scale.
%                     Default for grayscale double images is [0 1].
%   Outputs : ax - axes handle
ax = subplot(rows, cols, idx);
if nargin < 6
    if islogical(img) || size(img, 3) == 3
        range = [];
        imshow(img);
    else
        range = [0 1];
    end
end
if ~islogical(img) && size(img, 3) == 1
    imshow(img, range);
end
title(ttl, 'FontSize', 9, 'Interpreter', 'none');
axis off;
end
