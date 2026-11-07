function out = gauss_blur(img, sigma)
% GAUSS_BLUR  Separable Gaussian smoothing with replicate padding.
%
%   out = gauss_blur(img, sigma)
%
%   Purpose : Fast large-sigma blur (used for background illumination and
%             unsharp masking). Equivalent to imgaussfilt but also works
%             without it.
%   Inputs  : img   - grayscale double image
%             sigma - standard deviation in pixels (> 0)
%   Outputs : out   - smoothed image, same size
if sigma <= 0
    out = img;
    return;
end
r = ceil(3 * sigma);
x = -r:r;
h = exp(-x .^ 2 / (2 * sigma ^ 2));
h = h / sum(h);
p = padarray(img, [r r], 'replicate');
p = conv2(h, h, p, 'same');          % columns with h, then rows with h
out = p(r + 1:end - r, r + 1:end - r);
end
