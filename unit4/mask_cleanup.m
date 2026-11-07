function [bw2, res] = mask_cleanup(bw, fov, cfg)
% MASK_CLEANUP  Morphological clean-up of the raw vessel mask.
%
%   [bw2, res] = mask_cleanup(bw, fov, cfg)
%
%   Purpose : 1) opening (optional, radius 0 skips it because it erases
%                thin vessels), 2) closing to bridge one-pixel gaps,
%             3) bwareaopen to drop components smaller than min_area,
%             4) fill only holes smaller than max_hole_area (filling all
%                holes would fill the loops between vessels),
%             5) connected-component count before and after.
%   Inputs  : bw - raw logical mask; fov - logical mask; cfg (cfg.cleanup.*)
%   Outputs : bw2 - cleaned mask
%             res - struct: componentsBefore, componentsAfter, removed,
%                   pixelsRemoved, metrics
c = cfg.cleanup;
cc0 = bwconncomp(bw, 8);
s1 = bw;
if c.open_radius > 0,  s1 = imopen(s1, strel('disk', c.open_radius, 0));  end
if c.close_radius > 0, s1 = imclose(s1, strel('disk', c.close_radius, 0)); end
s2 = bwareaopen(s1, c.min_area, 8);
holes = imfill(s2, 'holes') & ~s2;
smallHoles = holes & ~bwareaopen(holes, c.max_hole_area + 1, 4);
bw2 = (s2 | smallHoles) & fov;
cc1 = bwconncomp(bw2, 8);
res.componentsBefore = cc0.NumObjects;
res.componentsAfter  = cc1.NumObjects;
res.removed          = cc0.NumObjects - cc1.NumObjects;
res.pixelsRemoved    = nnz(bw & ~bw2);
res.pixelsAdded      = nnz(bw2 & ~bw);
areas = cellfun(@numel, cc1.PixelIdxList);
res.largestComponentShare = max([areas 0]) / max(nnz(bw2), 1);
fprintf('      components %d -> %d (removed %d), pixels removed %d, added %d\n', ...
        res.componentsBefore, res.componentsAfter, res.removed, res.pixelsRemoved, res.pixelsAdded);
M = {};
M = add_metric(M, 'cleanup', 'components before', res.componentsBefore);
M = add_metric(M, 'cleanup', 'components after', res.componentsAfter);
M = add_metric(M, 'cleanup', 'components removed', res.removed);
M = add_metric(M, 'cleanup', 'pixels removed', res.pixelsRemoved);
M = add_metric(M, 'cleanup', 'pixels added (closing + holes)', res.pixelsAdded);
M = add_metric(M, 'cleanup', 'largest component share', res.largestComponentShare);

diffRGB = cat(3, double(bw & ~bw2), double(bw2), double(bw2 & ~bw));
fig = new_fig('Mask clean-up', cfg, 1, 4);
show_panel(1, 4, 1, bw, sprintf('Before: %d components', res.componentsBefore));
show_panel(1, 4, 2, s1, sprintf('Opening r=%d / closing r=%d', c.open_radius, c.close_radius));
show_panel(1, 4, 3, bw2, sprintf('After: %d components (removed %d)', res.componentsAfter, res.removed));
show_panel(1, 4, 4, diffRGB, {'Kept (green), removed (red),', 'added (cyan)'});
save_fig(fig, 'u4_02_mask_cleanup', cfg);
res.metrics = M;
end
