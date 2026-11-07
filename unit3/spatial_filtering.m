function res = spatial_filtering(I, fov, roi, gt, cfg)
% SPATIAL_FILTERING  Smoothing and sharpening in the spatial domain.
%
%   res = spatial_filtering(I, fov, roi, gt, cfg)
%
%   Purpose : Averaging and Gaussian smoothing, Laplacian sharpening
%             (I - w*Laplacian) and unsharp masking (I + a*(I - blur)).
%             The effect on vessels is measured with the vessel CNR and
%             the mean gradient magnitude (edge sharpness) inside the FOV.
%   Inputs  : I - enhanced image in [0,1] (outside FOV filled); fov; roi
%             gt - vessel mask or []; cfg (cfg.spatial.*)
%   Outputs : res - struct: names, cnr, sharpness, metrics
p = cfg.spatial;
avg = imfilter(I, fspecial('average', p.avg_size), 'replicate');
gau = imfilter(I, fspecial('gaussian', p.gauss_size, p.gauss_sigma), 'replicate');
lap = imfilter(I, fspecial('laplacian', p.lap_alpha), 'replicate');
shp = min(max(I - p.lap_weight * lap, 0), 1);       % centre of kernel is negative
uns = min(max(I + p.unsharp_amount * (I - gauss_blur(I, p.unsharp_sigma)), 0), 1);

names = {'input', sprintf('average %dx%d', p.avg_size, p.avg_size), ...
         sprintf('Gaussian s=%.1f', p.gauss_sigma), 'Laplacian sharpen', 'unsharp mask'};
imgs = {I, avg, gau, shp, uns};
vm = vessel_proxy(I, fov, gt, cfg);
res.names = names;
res.cnr = cellfun(@(x) vessel_contrast(x, vm, fov), imgs);
res.sharpness = cellfun(@(x) grad_mean(x, fov), imgs);
M = {};
for i = 1:numel(names)
    M = add_metric(M, names{i}, 'vessel CNR', res.cnr(i));
    M = add_metric(M, names{i}, 'mean gradient', res.sharpness(i));
end
print_table('Spatial filtering', {'Filter', 'vessel_CNR', 'mean_gradient'}, ...
            [names', num2cell(res.cnr'), num2cell(res.sharpness')]);
fig = new_fig('Spatial filtering', cfg, 2, 5);
for i = 1:numel(imgs)
    show_panel(2, 5, i, imgs{i} .* fov, sprintf('%s: CNR %.2f', names{i}, res.cnr(i)));
    show_panel(2, 5, 5 + i, crop_roi(imgs{i}, roi), sprintf('zoom, gradient %.3f', res.sharpness(i)));
end
save_fig(fig, 'u3_03_spatial_filtering', cfg);
res.metrics = M;
end

function m = grad_mean(x, fov)
% Mean Sobel gradient magnitude inside the FOV.
gx = imfilter(x, fspecial('sobel')', 'replicate');
gy = imfilter(x, fspecial('sobel'), 'replicate');
m = mean(sqrt(gx(fov) .^ 2 + gy(fov) .^ 2));
end
