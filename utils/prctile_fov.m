function t = prctile_fov(img, mask, p)
% PRCTILE_FOV  Percentile of the pixel values inside a mask.
%
%   Inputs  : img - image; mask - logical mask; p - percentile in [0,100]
%   Outputs : t   - value such that p% of masked pixels are <= t
v = sort(img(mask));
t = v(min(numel(v), max(1, round(p / 100 * numel(v)))));
end
