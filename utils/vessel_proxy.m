function vm = vessel_proxy(img, fov, gt, cfg)
% VESSEL_PROXY  Vessel mask used only to measure vessel contrast.
%
%   vm = vessel_proxy(img, fov, gt, cfg)
%
%   Purpose : Contrast measures in Units 1 and 3 need to know which pixels
%             are vessels. The ground truth is used when it exists;
%             otherwise the strongest (100 - cfg.unit3.proxy_prct)% black
%             top-hat responses inside the FOV are used as a stand-in.
%   Inputs  : img - grayscale image in [0,1]; fov - logical mask
%             gt  - ground-truth mask or []; cfg - configuration struct
%   Outputs : vm  - logical vessel mask inside the FOV
if ~isempty(gt)
    vm = gt & fov;
    return;
end
r = imbothat(img, strel('disk', cfg.morph.disk_radius, 0));
t = prctile_fov(r, fov, cfg.unit3.proxy_prct);
vm = (r > t) & fov;
end
