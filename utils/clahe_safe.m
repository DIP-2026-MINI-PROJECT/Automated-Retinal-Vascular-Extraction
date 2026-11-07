function out = clahe_safe(img, cfg)
% CLAHE_SAFE  CLAHE via adapthisteq, with a plain-MATLAB fallback.
%
%   out = clahe_safe(img, cfg)
%
%   Purpose : Contrast-limited adaptive histogram equalisation. Uses
%             adapthisteq when the Image Processing Toolbox provides it.
%             The fallback splits the image into tiles, clips each tile
%             histogram at cfg.unit3.clahe_clip, redistributes the excess,
%             builds a CDF per tile and bilinearly interpolates between
%             tile mappings (the same algorithm, less polished).
%   Inputs  : img - double image in [0,1]
%             cfg - uses cfg.unit3.clahe_tiles, clahe_clip, clahe_bins
%   Outputs : out - equalised image in [0,1]
tiles = cfg.unit3.clahe_tiles;
clip  = cfg.unit3.clahe_clip;
nb    = cfg.unit3.clahe_bins;
if exist('adapthisteq', 'file')
    out = adapthisteq(img, 'NumTiles', tiles, 'ClipLimit', clip, 'NBins', nb);
    return;
end
img = min(max(img, 0), 1);
[H, W] = size(img);
ty = tiles(1); tx = tiles(2);
ys = round(linspace(1, H + 1, ty + 1));
xs = round(linspace(1, W + 1, tx + 1));
maps = zeros(nb, ty, tx);
bins = min(floor(img * nb), nb - 1) + 1;
for i = 1:ty
    for j = 1:tx
        b = bins(ys(i):ys(i + 1) - 1, xs(j):xs(j + 1) - 1);
        h = accumarray(b(:), 1, [nb 1]);
        n = numel(b);
        minClip = ceil(n / nb);                      % same rule as adapthisteq
        limit = minClip + round(clip * (n - minClip));
        excess = sum(max(h - limit, 0));
        h = min(h, limit) + excess / nb;
        maps(:, i, j) = cumsum(h) / sum(h);
    end
end
% bilinear interpolation between tile centres
cy = (ys(1:end - 1) + ys(2:end) - 1) / 2;
cx = (xs(1:end - 1) + xs(2:end) - 1) / 2;
[X, Y] = meshgrid(1:W, 1:H);
fy = interp1(cy, 1:ty, min(max(Y, cy(1)), cy(end)));
fx = interp1(cx, 1:tx, min(max(X, cx(1)), cx(end)));
if ty == 1, fy = ones(H, W); end
if tx == 1, fx = ones(H, W); end
i0 = floor(fy); i1 = min(i0 + 1, ty); wy = fy - i0;
j0 = floor(fx); j1 = min(j0 + 1, tx); wx = fx - j0;
lut = @(ii, jj) maps(sub2ind(size(maps), bins, ii, jj));
out = (1 - wy) .* ((1 - wx) .* lut(i0, j0) + wx .* lut(i0, j1)) + ...
      wy .* ((1 - wx) .* lut(i1, j0) + wx .* lut(i1, j1));
end
