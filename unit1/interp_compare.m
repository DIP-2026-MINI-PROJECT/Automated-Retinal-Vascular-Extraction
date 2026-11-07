function res = interp_compare(g, fov, roi, cfg)
% INTERP_COMPARE  Compare nearest, bilinear and bicubic interpolation.
%
%   res = interp_compare(g, fov, roi, cfg)
%
%   Purpose : Downscale the green channel by cfg.unit1.interp_scale, scale
%             it back up to the original size with each method, and measure
%             PSNR / MSE against the original inside the FOV. Zoomed crops
%             of a thin-vessel region show the visual difference.
%   Inputs  : g   - normalised green channel in [0,1]
%             fov - logical mask;  roi - [row col h w] zoom window
%             cfg - configuration struct (cfg.unit1.*)
%   Outputs : res - struct: methods, psnr, mse, metrics
s = cfg.unit1.interp_scale;
if s <= 0 || s >= 1
    error('interp_compare:scale', 'cfg.unit1.interp_scale must be in (0,1).');
end
mth = cfg.unit1.interp_methods;
small = imresize(g, s, 'bilinear');              % one common low-res image
n = numel(mth);
res.methods = mth;
res.psnr = zeros(1, n);
res.mse  = zeros(1, n);
M = {};
fig = new_fig('Interpolation', cfg, 2, 4);
show_panel(2, n + 1, 1, g .* fov, 'Original green');
show_panel(2, n + 1, n + 2, crop_roi(g, roi), 'Original (zoom)');
for i = 1:n
    up = imresize(small, size(g), mth{i});
    up = min(max(up, 0), 1);
    [res.psnr(i), res.mse(i)] = psnr_mse(g, up, fov);
    show_panel(2, n + 1, 1 + i, up .* fov, sprintf('%s x%.2g -> x%.2g', mth{i}, s, 1 / s));
    show_panel(2, n + 1, n + 2 + i, crop_roi(up, roi), ...
               sprintf('%s zoom: PSNR %.2f dB, MSE %.2e', mth{i}, res.psnr(i), res.mse(i)));
    M = add_metric(M, mth{i}, 'PSNR (dB)', res.psnr(i));
    M = add_metric(M, mth{i}, 'MSE', res.mse(i));
    fprintf('      %-9s PSNR %6.2f dB  MSE %.3e\n', mth{i}, res.psnr(i), res.mse(i));
end
save_fig(fig, 'u1_04_interp_compare', cfg);
res.metrics = M;
end
