function [fov, fovE, gNorm, res] = get_fov_mask(rgb, fovIn, cfg)
% GET_FOV_MASK  Load or build the field-of-view mask and normalise green.
%
%   [fov, fovE, gNorm, res] = get_fov_mask(rgb, fovIn, cfg)
%
%   Purpose : 1) Use the supplied FOV mask, or generate one by thresholding
%                the red channel (brightest channel, so the retina is
%                clearly separated from the black surround) and cleaning
%                it with opening, hole filling and keeping the largest
%                component.
%             2) Erode it slightly so the bright rim at the FOV border is
%                excluded from every later measurement.
%             3) Normalise the green channel to [0,1] using statistics from
%                inside the eroded FOV only, and fill the outside with the
%                nearest FOV values so filters see no artificial edge.
%   Inputs  : rgb   - H x W x 3 double image in [0,1]
%             fovIn - logical FOV mask or [] to generate one
%             cfg   - configuration struct (cfg.fov.*)
%   Outputs : fov   - FOV mask (logical)
%             fovE  - eroded FOV mask used for all statistics
%             gNorm - normalised green channel, outside of fovE filled
%             res   - struct: generated (true/false), metrics list
if isempty(fovIn)
    fprintf('      FOV mask not supplied: generating it from the red channel.\n');
    red = rgb(:, :, 1);
    bw  = red > cfg.fov.red_thresh * max(red(:));
    bw  = imopen(bw, strel('disk', cfg.fov.open_radius, 0));
    bw  = imfill(bw, 'holes');
    cc  = bwconncomp(bw, 8);
    if cc.NumObjects == 0
        error('get_fov_mask:empty', 'Could not find a FOV; lower cfg.fov.red_thresh.');
    end
    [~, k] = max(cellfun(@numel, cc.PixelIdxList));
    fov = false(size(bw));
    fov(cc.PixelIdxList{k}) = true;
    res.generated = true;
else
    fov = logical(fovIn);
    res.generated = false;
end
fovE = imerode(fov, strel('disk', cfg.fov.erode_radius, 0));
if nnz(fovE) < 0.05 * numel(fovE)
    error('get_fov_mask:small', 'FOV covers under 5%% of the image; check the mask.');
end

g = rgb(:, :, 2);
gNorm = norm_fov(g, fovE, cfg.fov.norm_prct);
gNorm = fill_outside_fov(gNorm, fovE);

M = {};
M = add_metric(M, 'FOV', 'generated (1=yes)', res.generated);
M = add_metric(M, 'FOV', 'FOV pixels', nnz(fov));
M = add_metric(M, 'FOV', 'eroded FOV pixels', nnz(fovE));
M = add_metric(M, 'FOV', 'FOV fraction of image', nnz(fov) / numel(fov));
res.metrics = M;

fig = new_fig('FOV mask', cfg, 1, 4);
show_panel(1, 4, 1, rgb, 'Fundus image (RGB)');
src = 'loaded'; if res.generated, src = 'generated from red channel'; end
show_panel(1, 4, 2, fov, {'FOV mask', ['(' src ')']});
show_panel(1, 4, 3, fovE, sprintf('Eroded FOV (disk r=%d)', cfg.fov.erode_radius));
show_panel(1, 4, 4, gNorm .* fovE, 'Green, normalised inside FOV');
save_fig(fig, 'u1_02_fov_mask', cfg);
end
