function counts = fov_hist(img, mask, nbins)
% FOV_HIST  Histogram of the pixels inside a mask (vectorised).
%
%   counts = fov_hist(img, mask, nbins)
%
%   Inputs  : img   - double image in [0,1]
%             mask  - logical mask; only these pixels are counted
%             nbins - number of bins (default 256)
%   Outputs : counts - nbins x 1 vector of pixel counts
if nargin < 3, nbins = 256; end
v = img(mask);
v = min(max(v, 0), 1);
bins = min(floor(v * nbins), nbins - 1) + 1;
counts = accumarray(bins(:), 1, [nbins 1]);
end
