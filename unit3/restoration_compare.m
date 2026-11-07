function res = restoration_compare(I, fov, roi, cfg)
% RESTORATION_COMPARE  Noise models and restoration filters.
%
%   res = restoration_compare(I, fov, roi, cfg)
%
%   Purpose : Add Gaussian noise and salt-and-pepper noise to the enhanced
%             image, restore each with mean, median and adaptive Wiener
%             (wiener2) filters, and tabulate PSNR / MSE against the clean
%             image. If cfg.restore.periodic is true, also add a sinusoidal
%             (periodic) noise, find its spectral peaks automatically and
%             remove them with Gaussian notch-reject filters built by hand.
%   Inputs  : I - enhanced image in [0,1] (outside FOV filled); fov; roi
%             cfg - configuration struct (cfg.restore.*)
%   Outputs : res - struct: table (cell), psnr (2x4), mse (2x4),
%                   periodic (struct or []), metrics
p = cfg.restore;
rng(cfg.seed);
noisy = {imnoise(I, 'gaussian', 0, p.gauss_var), imnoise(I, 'salt & pepper', p.sp_density)};
noiseNames = {sprintf('Gaussian var %.3g', p.gauss_var), sprintf('salt&pepper d=%.2g', p.sp_density)};
filtNames = {'noisy (no filter)', sprintf('mean %dx%d', p.filt_size, p.filt_size), ...
             sprintf('median %dx%d', p.filt_size, p.filt_size), ...
             sprintf('wiener2 %dx%d', p.wiener_size(1), p.wiener_size(2))};
res.psnr = zeros(2, 4); res.mse = zeros(2, 4);
rows = {}; M = {};
fig = new_fig('Restoration', cfg, 2, 4);
for a = 1:2
    J = noisy{a};
    outs = {J, imfilter(J, fspecial('average', p.filt_size), 'replicate'), ...
            medfilt2(J, [p.filt_size p.filt_size], 'symmetric'), wiener2(J, p.wiener_size)};
    for b = 1:4
        [res.psnr(a, b), res.mse(a, b)] = psnr_mse(I, outs{b}, fov);
        rows(end + 1, :) = {noiseNames{a}, filtNames{b}, res.psnr(a, b), res.mse(a, b)};
        M = add_metric(M, [noiseNames{a} ' / ' filtNames{b}], 'PSNR (dB)', res.psnr(a, b));
        M = add_metric(M, [noiseNames{a} ' / ' filtNames{b}], 'MSE', res.mse(a, b));
        show_panel(2, 4, (a - 1) * 4 + b, crop_roi(outs{b}, roi), ...
                   {[noiseNames{a} ': ' filtNames{b}], sprintf('PSNR %.2f dB (zoom)', res.psnr(a, b))});
    end
end
save_fig(fig, 'u3_05_restoration', cfg);
header = {'Noise', 'Filter', 'PSNR_dB', 'MSE'};
print_table('Restoration (PSNR against the clean enhanced image)', header, rows);

res.periodic = [];
if p.periodic
    [res.periodic, rowsP, MP] = periodic_notch(I, fov, cfg);
    rows = [rows; rowsP]; M = [M; MP];
end
res.table = [header; rows];
write_csv(fullfile(cfg.paths.outputs, 'restoration.csv'), header, rows);
res.metrics = M;
end

% -------------------------------------------------------------------------
function [pr, rows, M] = periodic_notch(I, fov, cfg)
% Add a sinusoid, locate its two spectral peaks, remove with Gaussian notches.
p = cfg.restore;
[H, W] = size(I);
[x, y] = meshgrid(0:W - 1, 0:H - 1);
J = I + p.per_amp * sin(2 * pi * (p.per_freq(1) * x / W + p.per_freq(2) * y / H));
F = fftshift(fft2(J));
[u, v] = meshgrid((0:W - 1) - floor(W / 2), (0:H - 1) - floor(H / 2));
mag = abs(F);
mag(sqrt(u .^ 2 + v .^ 2) < p.notch_guard) = 0;       % ignore the DC region
[~, k] = max(mag(:));
pk = [u(k) v(k)];                                     % one peak, the other is -pk
Hn = (1 - exp(-((u - pk(1)) .^ 2 + (v - pk(2)) .^ 2) / (2 * p.notch_radius ^ 2))) .* ...
     (1 - exp(-((u + pk(1)) .^ 2 + (v + pk(2)) .^ 2) / (2 * p.notch_radius ^ 2)));
R = min(max(real(ifft2(ifftshift(Hn .* F))), 0), 1);
Jc = min(max(J, 0), 1);
[pr.psnrNoisy, pr.mseNoisy] = psnr_mse(I, Jc, fov);
[pr.psnrNotch, pr.mseNotch] = psnr_mse(I, R, fov);
pr.peak = pk;
fprintf('      periodic noise: peak found at (u,v) = (%d,%d); PSNR %.2f -> %.2f dB\n', ...
        pk(1), pk(2), pr.psnrNoisy, pr.psnrNotch);
nm = sprintf('periodic A=%.2g', p.per_amp);
rows = {nm, 'noisy (no filter)', pr.psnrNoisy, pr.mseNoisy; nm, 'Gaussian notch reject', pr.psnrNotch, pr.mseNotch};
M = {};
M = add_metric(M, [nm ' / noisy'], 'PSNR (dB)', pr.psnrNoisy);
M = add_metric(M, [nm ' / notch'], 'PSNR (dB)', pr.psnrNotch);

fig = new_fig('Periodic noise and notch filter', cfg, 1, 4);
show_panel(1, 4, 1, Jc .* fov, sprintf('Periodic noise: PSNR %.2f dB', pr.psnrNoisy));
ax = show_panel(1, 4, 2, log(1 + abs(F)), 'log|F| with detected peaks', []);
hold(ax, 'on');
c = [floor(W / 2) + 1, floor(H / 2) + 1];
plot(c(1) + [pk(1) -pk(1)], c(2) + [pk(2) -pk(2)], 'ro', 'MarkerSize', 12, 'LineWidth', 1.5);
hold(ax, 'off');
show_panel(1, 4, 3, Hn, 'Notch-reject transfer function', [0 1]);
show_panel(1, 4, 4, R .* fov, sprintf('After notch: PSNR %.2f dB', pr.psnrNotch));
save_fig(fig, 'u3_06_periodic_notch', cfg);
end
