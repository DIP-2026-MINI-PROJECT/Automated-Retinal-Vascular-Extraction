function [denoised, res] = dct_denoise(g, fov, roi, cfg)
% DCT_DENOISE  DCT compression / denoising of the green channel.
%
%   [denoised, res] = dct_denoise(g, fov, roi, cfg)
%
%   Purpose : 2-D DCT of the green channel. For each keep-ratio in
%             cfg.dct.keep_ratios only the largest-magnitude X% of the
%             coefficients are kept and the image is rebuilt with the
%             inverse DCT. PSNR / MSE against the original are reported.
%             The same is done on a copy with Gaussian noise added
%             (sigma = cfg.dct.noise_sigma) to show that discarding small
%             coefficients removes noise.
%             selected_cutoff = lowest keep-ratio whose PSNR on the clean
%             image is >= cfg.dct.psnr_thresh; that reconstruction is the
%             denoised image passed on to Unit 3.
%   Inputs  : g   - green channel in [0,1] (outside FOV filled)
%             fov - logical mask; roi - zoom window; cfg
%   Outputs : denoised - reconstruction at selected_cutoff, in [0,1]
%             res - struct: keep, psnr, mse, psnrNoisy, mseNoisy,
%                   psnrNoisyInput, selected_cutoff, metrics
keep = sort(cfg.dct.keep_ratios(:)', 'descend');
if any(keep <= 0 | keep > 100)
    error('dct_denoise:keep', 'keep_ratios must be in (0, 100].');
end
rng(cfg.seed);
gn = g + cfg.dct.noise_sigma * randn(size(g));
C  = tf_dct2(g);
Cn = tf_dct2(gn);
[~, order]  = sort(abs(C(:)),  'descend');
[~, orderN] = sort(abs(Cn(:)), 'descend');
n = numel(keep);
recs = cell(1, n); recsN = cell(1, n);
res.keep = keep;
res.psnr = zeros(1, n);  res.mse = zeros(1, n);
res.psnrNoisy = zeros(1, n); res.mseNoisy = zeros(1, n);
[res.psnrNoisyInput, res.mseNoisyInput] = psnr_mse(g, min(max(gn, 0), 1), fov);
M = {};
for i = 1:n
    k = round(keep(i) / 100 * numel(C));
    recs{i}  = rebuild(C,  order(1:k));
    recsN{i} = rebuild(Cn, orderN(1:k));
    [res.psnr(i), res.mse(i)] = psnr_mse(g, recs{i}, fov);
    [res.psnrNoisy(i), res.mseNoisy(i)] = psnr_mse(g, recsN{i}, fov);
    tag = sprintf('keep %g%%', keep(i));
    M = add_metric(M, tag, 'PSNR clean (dB)', res.psnr(i));
    M = add_metric(M, tag, 'MSE clean', res.mse(i));
    M = add_metric(M, tag, 'PSNR noisy->rec vs clean (dB)', res.psnrNoisy(i));
    M = add_metric(M, tag, 'MSE noisy->rec vs clean', res.mseNoisy(i));
    fprintf('      keep %5.1f%%  clean PSNR %6.2f dB | noisy input %6.2f -> %6.2f dB\n', ...
            keep(i), res.psnr(i), res.psnrNoisyInput, res.psnrNoisy(i));
end
M = add_metric(M, 'noisy input', 'PSNR (dB)', res.psnrNoisyInput);
M = add_metric(M, 'noisy input', 'MSE', res.mseNoisyInput);

ok = find(res.psnr >= cfg.dct.psnr_thresh);
if isempty(ok)
    [~, sel] = max(keep);
    warning('dct_denoise:threshold', ...
        'No keep-ratio reaches %.1f dB; using the largest (%g%%).', cfg.dct.psnr_thresh, keep(sel));
else
    [~, j] = min(keep(ok));
    sel = ok(j);
end
selected_cutoff = keep(sel);
res.selected_cutoff = selected_cutoff;
denoised = recs{sel};
M = add_metric(M, 'selection', 'selected_cutoff (% kept)', selected_cutoff);
fprintf('      selected_cutoff = %g%% (PSNR %.2f dB >= %.1f dB)\n', ...
        selected_cutoff, res.psnr(sel), cfg.dct.psnr_thresh);

% ---- figure 1: clean image reconstructions
fig = new_fig('DCT compression', cfg, 3, n + 1);
show_panel(3, n + 1, 1, g .* fov, 'Original green');
L = log(1 + abs(C));
show_panel(3, n + 1, n + 2, L(1:min(end, 150), 1:min(end, 150)), ...
           'log(1+|DCT|), top-left 150x150 (low freq.)', [0 prctile_fov(L, true(size(L)), 99.9)]);
colormap(gca, 'jet');
show_panel(3, n + 1, 2 * n + 3, crop_roi(g, roi), 'Original (zoom)');
for i = 1:n
    show_panel(3, n + 1, 1 + i, recs{i} .* fov, sprintf('keep %g%%: PSNR %.2f dB, MSE %.2e', ...
               keep(i), res.psnr(i), res.mse(i)));
    d = abs(g - recs{i}) .* fov;
    show_panel(3, n + 1, n + 2 + i, d, sprintf('|difference| (x%d), keep %g%%', 10, keep(i)), [0 0.1]);
    show_panel(3, n + 1, 2 * n + 3 + i, crop_roi(recs{i}, roi), sprintf('keep %g%% (zoom)', keep(i)));
end
save_fig(fig, 'u2_02_dct_compression', cfg);

% ---- figure 2: denoising of the noisy copy
fig = new_fig('DCT denoising', cfg, 2, n + 1);
show_panel(2, n + 1, 1, min(max(gn, 0), 1) .* fov, sprintf('Noisy (sigma %.3g): PSNR %.2f dB', ...
           cfg.dct.noise_sigma, res.psnrNoisyInput));
show_panel(2, n + 1, n + 2, crop_roi(min(max(gn, 0), 1), roi), 'Noisy (zoom)');
for i = 1:n
    show_panel(2, n + 1, 1 + i, recsN{i} .* fov, sprintf('keep %g%%: PSNR %.2f dB', keep(i), res.psnrNoisy(i)));
    show_panel(2, n + 1, n + 2 + i, crop_roi(recsN{i}, roi), sprintf('keep %g%% (zoom)', keep(i)));
end
save_fig(fig, 'u2_03_dct_denoise_noisy', cfg);
res.metrics = M;
end

function r = rebuild(C, idx)
% Keep only the coefficients listed in idx, inverse DCT, clip to [0,1].
Ck = zeros(size(C));
Ck(idx) = C(idx);
r = min(max(tf_dct2(Ck, true), 0), 1);
end
