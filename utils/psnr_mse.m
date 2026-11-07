function [p, m] = psnr_mse(ref, test, mask)
% PSNR_MSE  Peak signal-to-noise ratio and mean squared error.
%
%   [p, m] = psnr_mse(ref, test)
%   [p, m] = psnr_mse(ref, test, mask)
%
%   Purpose : Compare a test image with a reference image, optionally only
%             over the pixels inside a mask (e.g. the FOV).
%   Inputs  : ref, test - double images in [0,1], same size
%             mask      - (optional) logical mask; [] or omitted = all pixels
%   Outputs : p - PSNR in dB with peak value 1 (Inf when the images match)
%             m - mean squared error
if nargin < 3 || isempty(mask)
    mask = true(size(ref, 1), size(ref, 2));
end
if ~isequal(size(ref), size(test))
    error('psnr_mse:size', 'ref and test must have the same size.');
end
if ~isequal([size(mask, 1) size(mask, 2)], [size(ref, 1) size(ref, 2)])
    error('psnr_mse:mask', 'mask must match the image height and width.');
end
mask = repmat(logical(mask), [1 1 size(ref, 3)]);
d = double(ref(mask)) - double(test(mask));
m = mean(d .^ 2);
if m == 0
    p = Inf;
else
    p = 10 * log10(1 / m);
end
end
