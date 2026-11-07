function res = pseudocolor_output(rgb, bw, sk, fov, cfg)
% PSEUDOCOLOR_OUTPUT  Pseudocoloured diagnostic vessel mask and overlay.
%
%   res = pseudocolor_output(rgb, bw, sk, fov, cfg)
%
%   Purpose : Colour every vessel pixel by its local width (from the
%             skeleton analysis) through a colormap (turbo, or jet when
%             turbo is unavailable): blue = thin capillaries, red = thick
%             main vessels. Produce (1) the pseudocoloured mask on black
%             and (2) an overlay on the original fundus image, each with a
%             colorbar and a legend, and save both figures and the raw
%             images as PNG.
%   Inputs  : rgb - original fundus image; bw - vessel mask
%             sk  - struct from skeleton_analysis (widthMap, endpoints,
%                   branchpoints); fov - FOV mask; cfg (cfg.pseudo.*)
%   Outputs : res - struct: maskRGB, overlayRGB, widthRange, files
nC = 256;
if exist(cfg.pseudo.colormap, 'file') || exist(cfg.pseudo.colormap, 'builtin')
    cmap = feval(cfg.pseudo.colormap, nC);
else
    cmap = jet(nC);
end
w = sk.widthMap;
wv = w(bw);
if isempty(wv)
    warning('pseudocolor_output:empty', 'Vessel mask is empty; nothing to colour.');
    wv = 1;
end
wr = [min(wv) max(max(wv), min(wv) + 1)];
idx = round((w - wr(1)) / (wr(2) - wr(1)) * (nC - 1)) + 1;
idx = min(max(idx, 1), nC);
colRGB = reshape(cmap(idx(:), :), [size(w) 3]);
bw3 = repmat(bw, [1 1 3]);
maskRGB = colRGB .* bw3;
a = cfg.pseudo.alpha;
overlay = rgb .* repmat(fov, [1 1 3]);
overlay(bw3) = a * colRGB(bw3) + (1 - a) * overlay(bw3);

res.maskRGB = maskRGB;
res.overlayRGB = overlay;
res.widthRange = wr;
res.files = {fullfile(cfg.paths.outputs, 'pseudocolor_mask.png'), fullfile(cfg.paths.outputs, 'pseudocolor_overlay.png')};
imwrite(maskRGB, res.files{1});
imwrite(overlay, res.files{2});
fprintf('      saved %s\n      saved %s\n', res.files{:});

titles = {'Pseudocoloured vessel mask (colour = width)', 'Overlay on fundus image'};
imgs = {maskRGB, overlay};
names = {'u4_04_pseudocolor_mask', 'u4_05_pseudocolor_overlay'};
for i = 1:2
    fig = new_fig(titles{i}, cfg, 2, 2);
    imshow(imgs{i}); axis off; hold on;
    title(sprintf('%s; thin < %g px <= thick', titles{i}, cfg.skel.thin_width_px), 'FontSize', 11);
    colormap(gca, cmap); caxis(wr);
    cb = colorbar; ylabel(cb, 'vessel width (px)');
    [ye, xe] = find(sk.endpoints); [yb, xb] = find(sk.branchpoints);
    h1 = plot(xb, yb, 'o', 'MarkerSize', 4, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'w');
    h2 = plot(xe, ye, 's', 'MarkerSize', 3, 'MarkerEdgeColor', 'm', 'MarkerFaceColor', 'm');
    h3 = patch(NaN, NaN, cmap(round(0.1 * nC), :));
    h4 = patch(NaN, NaN, cmap(round(0.9 * nC), :));
    legend([h3 h4 h1 h2], {'thin vessels', 'thick vessels', 'branch points', 'end points'}, ...
           'Location', 'southoutside', 'Orientation', 'horizontal');
    hold off;
    save_fig(fig, names{i}, cfg);
end
end
