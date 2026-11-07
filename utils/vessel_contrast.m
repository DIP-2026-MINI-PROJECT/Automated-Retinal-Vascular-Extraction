function c = vessel_contrast(img, vm, fov)
% VESSEL_CONTRAST  Vessel-to-background contrast inside the FOV.
%
%   c = vessel_contrast(img, vm, fov)
%
%   Purpose : (mean background - mean vessel) / std(background). Larger is
%             better: vessels stand out more clearly from the background.
%   Inputs  : img - grayscale image; vm - vessel mask; fov - FOV mask
%   Outputs : c   - scalar contrast-to-noise ratio
bg = img(fov & ~vm);
vs = img(fov & vm);
c = (mean(bg) - mean(vs)) / max(std(bg), eps);
end
