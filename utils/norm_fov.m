function out = norm_fov(img, fov, prct)
% NORM_FOV  Stretch an image to [0,1] using statistics inside the FOV only.
%
%   out = norm_fov(img, fov)
%   out = norm_fov(img, fov, prct)
%
%   Inputs  : img  - grayscale double image
%             fov  - logical mask
%             prct - [lo hi] percentiles (default [0 100] = min/max)
%   Outputs : out  - image clipped to [0,1]; outside pixels keep the
%                    same linear mapping (and are clipped)
if nargin < 3, prct = [0 100]; end
v = sort(img(fov));
n = numel(v);
lo = v(max(1, round(prct(1) / 100 * n)));
hi = v(max(1, round(prct(2) / 100 * n)));
if hi <= lo
    hi = lo + eps;
end
out = min(max((img - lo) / (hi - lo), 0), 1);
end
