function roi = pick_zoom_roi(g, fov, cfg)
% PICK_ZOOM_ROI  Choose a window that contains many thin vessels.
%
%   roi = pick_zoom_roi(g, fov, cfg)
%
%   Purpose : Every unit shows a zoom on thin vessels. If cfg.zoom.roi is
%             set it is used as is. Otherwise the window (inside the FOV)
%             with the highest small-scale black top-hat response is used,
%             i.e. where thin dark lines are densest.
%   Inputs  : g   - normalised green channel (outside FOV already filled)
%             fov - logical FOV mask
%             cfg - configuration struct
%   Outputs : roi - [row col height width]
[H, W] = size(g);
if ~isempty(cfg.zoom.roi)
    roi = cfg.zoom.roi;
    if roi(1) < 1 || roi(2) < 1 || roi(1) + roi(3) - 1 > H || roi(2) + roi(4) - 1 > W
        error('pick_zoom_roi:range', 'cfg.zoom.roi lies outside the image.');
    end
    return;
end
s = min([cfg.zoom.size, floor(H / 3), floor(W / 3)]);
resp = imbothat(g, strel('disk', 2, 0)) .* fov;        % thin dark lines only
box = ones(s, 1) / s;
score  = conv2(box, box, resp, 'valid');            % mean response per window
inside = conv2(box, box, double(fov), 'valid') > 0.999;
score(~inside) = -Inf;
[~, k] = max(score(:));
[r, c] = ind2sub(size(score), k);
roi = [r c s s];
end
