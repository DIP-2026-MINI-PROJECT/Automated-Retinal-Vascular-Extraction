function v = illum_nonuniformity(img, fov, sigma)
% ILLUM_NONUNIFORMITY  How uneven the illumination of an image is.
%
%   v = illum_nonuniformity(img, fov, sigma)
%
%   Purpose : Smooth heavily (Gaussian, sigma px) so only the slow
%             background remains, then return its coefficient of variation
%             inside the FOV. 0 means perfectly flat illumination.
%   Inputs  : img - grayscale image; fov - logical mask; sigma - px
%   Outputs : v   - std / mean of the smoothed image inside the FOV
b = gauss_blur(img, sigma);
b = b(fov);
v = std(b) / max(abs(mean(b)), eps);
end
