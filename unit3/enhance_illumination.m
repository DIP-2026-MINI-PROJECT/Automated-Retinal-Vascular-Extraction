function [enhanced, res] = enhance_illumination(I, fov, gt, cfg)
% ENHANCE_ILLUMINATION  Point operations, histogram methods and CLAHE.
%
%   [enhanced, res] = enhance_illumination(I, fov, gt, cfg)
%
%   Purpose : On the denoised green channel (Unit 2 output):
%             - contrast stretching between two FOV percentiles
%             - gamma correction of the stretched image
%             - global histogram equalisation (CDF of FOV pixels)
%             - CLAHE on the raw image
%             - background illumination estimate (large Gaussian blur) and
%               correction by subtraction or division
%             - CLAHE on the illumination-corrected image  <- default output
%             Vessel contrast (CNR) and the non-uniformity of the
%             background are reported for every variant.
%   Inputs  : I   - denoised green channel in [0,1] (outside FOV filled)
%             fov - logical mask; gt - vessel mask or []; cfg
%   Outputs : enhanced - CLAHE(illumination-corrected I), outside filled
%             res      - struct: names, cnr, nonuniformity, metrics
u = cfg.unit3;
% point operations
st = norm_fov(I, fov, u.stretch_prct);
ga = st .^ u.gamma;
% global histogram equalisation over FOV pixels only
h = fov_hist(I, fov, 256);
cdf = cumsum(h) / sum(h);
he = reshape(cdf(min(floor(min(max(I, 0), 1) * 256), 255) + 1), size(I));
% CLAHE on the uncorrected image
cl = clahe_safe(I, cfg);
% background estimate and correction
bg = gauss_blur(I, u.bg_sigma);
switch lower(u.bg_mode)
    case 'subtract', corr = I - bg;
    case 'divide',   corr = I ./ max(bg, 0.05);
    otherwise, error('enhance_illumination:mode', 'bg_mode must be subtract or divide.');
end
corr = fill_outside_fov(norm_fov(corr, fov, [0.5 99.5]), fov);
enhanced = fill_outside_fov(clahe_safe(corr, cfg), fov);

names = {'input', 'stretch', sprintf('gamma %.2g', u.gamma), 'hist. equalised', ...
         'CLAHE (raw)', 'bg-corrected', 'CLAHE (bg-corrected)'};
imgs  = {I, st, ga, he, cl, corr, enhanced};
vm = vessel_proxy(I, fov, gt, cfg);
res.names = names;
res.cnr = cellfun(@(x) vessel_contrast(x, vm, fov), imgs);
% non-uniformity = spread of the smoothed background inside the FOV
res.nonuniformity = cellfun(@(x) illum_nonuniformity(x, fov, u.bg_sigma), imgs);
M = {};
for i = 1:numel(names)
    M = add_metric(M, names{i}, 'vessel CNR', res.cnr(i));
    M = add_metric(M, names{i}, 'illumination non-uniformity', res.nonuniformity(i));
end
print_table('Enhancement comparison (higher CNR, lower non-uniformity = better)', ...
            {'Variant', 'vessel_CNR', 'non_uniformity'}, [names', num2cell(res.cnr'), num2cell(res.nonuniformity')]);

fig = new_fig('Enhancement', cfg, 2, 4);
for i = 1:numel(imgs)
    show_panel(2, 4, i, imgs{i} .* fov, sprintf('%s (CNR %.2f)', names{i}, res.cnr(i)));
end
show_panel(2, 4, 8, bg .* fov, sprintf('Background estimate (Gaussian sigma %g)', u.bg_sigma));
save_fig(fig, 'u3_01_enhancement', cfg);

fig = new_fig('Enhancement histograms', cfg, 1, 5);
pick = [1 2 4 5 7];
for j = 1:numel(pick)
    subplot(1, numel(pick), j);
    bar(linspace(0, 1, 256), fov_hist(imgs{pick(j)}, fov, 256), 1, ...
        'FaceColor', [0.2 0.4 0.7], 'EdgeColor', 'none');
    xlim([0 1]); xlabel('intensity'); title(names{pick(j)}, 'FontSize', 9);
end
save_fig(fig, 'u3_02_enhancement_histograms', cfg);
res.metrics = M;
end
