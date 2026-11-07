function out = fill_outside_fov(img, fov)
% FILL_OUTSIDE_FOV  Replace pixels outside the FOV by the nearest FOV pixel.
%
%   out = fill_outside_fov(img, fov)
%
%   Purpose : Filters, transforms and morphology react strongly to the
%             black border around the retina. Copying the nearest inside
%             value outwards removes that artificial edge. Vectorised via
%             the index output of bwdist.
%   Inputs  : img - grayscale double image
%             fov - logical field-of-view mask, same size
%   Outputs : out - image with the outside filled in
[~, idx] = bwdist(fov);
out = img(idx);
out = reshape(out, size(img));
end
