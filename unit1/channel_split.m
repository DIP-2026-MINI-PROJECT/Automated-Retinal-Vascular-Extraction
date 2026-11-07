function res = channel_split(rgb, fov, gt, cfg)
% CHANNEL_SPLIT  Separate R, G, B and justify using the green channel.
%
%   res = channel_split(rgb, fov, gt, cfg)
%
%   Purpose : Show each colour channel with its FOV histogram and compute
%             (a) the standard deviation inside the FOV (global contrast)
%             and (b) the vessel-to-background contrast after removing the
%             slow illumination (uses the ground
%             truth, or a luminance top-hat vessel proxy if there is none). The
%             channel with the highest vessel contrast is reported; for
%             fundus images this is normally green.
%   Inputs  : rgb - H x W x 3 double in [0,1]; fov - logical mask
%             gt  - vessel mask or []; cfg - configuration struct
%   Outputs : res - struct: std (1x3), vesselContrast (1x3), best (char),
%                   metrics (n x 3 cell)
names = {'Red', 'Green', 'Blue'};
fig = new_fig('Channel split', cfg, 2, 3);
res.std = zeros(1, 3);
res.vesselContrast = zeros(1, 3);
M = {};
% one vessel mask for all three channels (ground truth, or a top-hat proxy
% computed on the luminance image) so the comparison is fair
vm = vessel_proxy(norm_fov(rgb2gray(rgb), fov), fov, gt, cfg);
for c = 1:3
    ch = rgb(:, :, c);
    res.std(c) = std(ch(fov));
    % local contrast: remove the slow illumination first, so a bright
    % optic disc or dark periphery does not count as vessel contrast
    flat = ch - gauss_blur(fill_outside_fov(ch, fov), cfg.unit3.bg_sigma);
    res.vesselContrast(c) = vessel_contrast(flat, vm, fov);
    show_panel(2, 3, c, ch .* fov, {sprintf('%s channel', names{c}), ...
               sprintf('std in FOV %.3f, vessel CNR %.2f', res.std(c), res.vesselContrast(c))});
    subplot(2, 3, 3 + c);
    h = fov_hist(ch, fov, 256);
    bar(linspace(0, 1, 256), h, 1, 'FaceColor', [0.3 0.3 0.3], 'EdgeColor', 'none');
    xlim([0 1]); xlabel('intensity'); ylabel('pixels in FOV');
    title(sprintf('%s histogram', names{c}), 'FontSize', 9);
    M = add_metric(M, names{c}, 'std in FOV', res.std(c));
    M = add_metric(M, names{c}, 'vessel contrast (CNR)', res.vesselContrast(c));
end
[~, b] = max(res.vesselContrast);
res.best = names{b};
fprintf('      vessel CNR R/G/B = %.2f / %.2f / %.2f  -> best: %s\n', ...
        res.vesselContrast, res.best);
save_fig(fig, 'u1_03_channel_split', cfg);
res.metrics = M;
end
