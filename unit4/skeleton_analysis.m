function [feat, sk] = skeleton_analysis(bw, fov, cfg)
% SKELETON_ANALYSIS  Skeleton, end/branch points and clinical features.
%
%   [feat, sk] = skeleton_analysis(bw, fov, cfg)
%
%   Purpose : - skeletonise the vessel mask (bwskel, or bwmorph 'skel' plus
%               spur pruning when bwskel is unavailable)
%             - endpoints by hit-or-miss (bwhitmiss) with the 8 rotations
%               of the endpoint template; branch points as skeleton pixels
%               with 3 or more skeleton neighbours (neighbour count by a
%               3x3 convolution); touching branch pixels count as one point
%             - width map: 2 * distance transform - 1, read at the nearest
%               skeleton pixel, so every vessel pixel gets its vessel width
%             - clinical features: vessel density, thin/thick pixel ratio,
%               branch points, endpoints, total skeleton length (pixel
%               steps: 1 for straight, sqrt(2) for diagonal links)
%   Inputs  : bw - cleaned vessel mask; fov - logical FOV mask; cfg (cfg.skel.*)
%   Outputs : feat - struct of clinical features + table (cell) + metrics
%             sk   - struct: skel, endpoints, branchpoints, widthMap, thin
if exist('bwskel', 'file')
    skel = bwskel(bw, 'MinBranchLength', cfg.skel.min_branch);
else
    % fallback (older MATLAB / Octave): thinning gives a 1-px-wide
    % skeleton; 'spur' then prunes short side branches
    skel = bwmorph(bw, 'thin', Inf);
    skel = bwmorph(skel, 'spur', cfg.skel.min_branch);
    skel = bwmorph(skel, 'clean');
end

% endpoints by hit-or-miss: centre + exactly one neighbour on
ends = false(size(skel));
nb = [1 1; 1 2; 1 3; 2 3; 3 3; 3 2; 3 1; 2 1];
for k = 1:8
    hit = zeros(3); hit(2, 2) = 1; hit(nb(k, 1), nb(k, 2)) = 1;
    ends = ends | bwhitmiss(skel, hit, 1 - hit);
end
% branch points: crossing number >= 3, i.e. at least three separate
% skeleton runs leave the pixel. CN = 1/2 * sum |P(k+1) - P(k)| over the
% 8 neighbours in circular order (a plain neighbour count would also flag
% every corner of a staircase line).
P = padarray(double(skel), [1 1], 0);
[h, w] = size(skel);
ring = [1 1; 1 2; 1 3; 2 3; 3 3; 3 2; 3 1; 2 1];   % clockwise from top-left
nbr = zeros(h, w, 8);
for k = 1:8
    nbr(:, :, k) = P(ring(k, 1):ring(k, 1) + h - 1, ring(k, 2):ring(k, 2) + w - 1);
end
cn = 0.5 * sum(abs(nbr(:, :, [2:8 1]) - nbr), 3);
branchPix = skel & cn >= 3;
ccb = bwconncomp(branchPix, 8);
branchPts = false(size(skel));
centres = cellfun(@(p) p(ceil(end / 2)), ccb.PixelIdxList);
branchPts(centres) = true;

% width map
dt = bwdist(~bw);
widthMap = zeros(size(bw));
if any(skel(:))
    [~, nearestSkel] = bwdist(skel);
    widthMap(bw) = 2 * dt(nearestSkel(bw)) - 1;   % centre pixel counted once
else
    warning('skeleton_analysis:empty', 'Empty skeleton; widths taken from the distance transform.');
    widthMap(bw) = 2 * dt(bw) - 1;
end
thin = bw & widthMap < cfg.skel.thin_width_px;
thick = bw & ~thin;

% skeleton length: orthogonal and diagonal links counted once each
orth = nnz(skel(:, 1:end - 1) & skel(:, 2:end)) + nnz(skel(1:end - 1, :) & skel(2:end, :));
diag1 = nnz(skel(1:end - 1, 1:end - 1) & skel(2:end, 2:end));
diag2 = nnz(skel(1:end - 1, 2:end) & skel(2:end, 1:end - 1));
lenPx = orth + sqrt(2) * (diag1 + diag2);

feat.vessel_density = nnz(bw & fov) / nnz(fov);
feat.thin_pixels = nnz(thin);
feat.thick_pixels = nnz(thick);
feat.thin_thick_ratio = nnz(thin) / max(nnz(thick), 1);
feat.branch_points = ccb.NumObjects;
feat.end_points = nnz(ends);
feat.skeleton_length_px = lenPx;
feat.mean_width_px = mean(widthMap(skel & bw));
feat.max_width_px = max([widthMap(bw); 0]);
names = {'vessel_density', 'thin_pixels', 'thick_pixels', 'thin_thick_ratio', ...
         'branch_points', 'end_points', 'skeleton_length_px', 'mean_width_px', 'max_width_px'};
if ~isempty(cfg.skel.pixel_size_um)
    feat.skeleton_length_mm = lenPx * cfg.skel.pixel_size_um / 1000;
    names{end + 1} = 'skeleton_length_mm';
end
vals = cellfun(@(n) feat.(n), names);
rows = [names', num2cell(vals')];
feat.table = [{'Feature', 'Value'}; rows];
print_table(sprintf('Clinical features (thin = width < %g px)', cfg.skel.thin_width_px), ...
            {'Feature', 'Value'}, rows);
write_csv(fullfile(cfg.paths.outputs, 'clinical_features.csv'), {'Feature', 'Value'}, rows);
feat.metrics = [repmat({'clinical'}, numel(names), 1), names', num2cell(vals')];

sk = struct('skel', skel, 'endpoints', ends, 'branchpoints', branchPts, ...
            'widthMap', widthMap, 'thin', thin);

fig = new_fig('Skeleton analysis', cfg, 1, 4);
show_panel(1, 4, 1, bw, sprintf('Vessel mask (density %.3f)', feat.vessel_density));
ax = show_panel(1, 4, 2, skel, sprintf('Skeleton: %d branch, %d end points', feat.branch_points, feat.end_points));
hold(ax, 'on');
[ye, xe] = find(ends); [yb, xb] = find(branchPts);
plot(xe, ye, 'g.', 'MarkerSize', 8); plot(xb, yb, 'r.', 'MarkerSize', 10);
legend({'end points', 'branch points'}, 'Location', 'southoutside', 'Orientation', 'horizontal');
hold(ax, 'off');
show_panel(1, 4, 3, widthMap, 'Width map (px)', [0 max(feat.max_width_px, 1)]);
colormap(gca, 'jet'); colorbar;
show_panel(1, 4, 4, cat(3, double(thick), double(thin), zeros(size(bw))), ...
           {sprintf('thin (green) vs thick (red), < %g px', cfg.skel.thin_width_px), ...
            sprintf('thin/thick ratio %.2f', feat.thin_thick_ratio)});
save_fig(fig, 'u4_03_skeleton_analysis', cfg);
end
