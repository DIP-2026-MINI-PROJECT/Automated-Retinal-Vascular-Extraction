function res = dct_vs_svd(g, fov, roi, cfg)
% DCT_VS_SVD  Compare DCT and SVD compression at matched compression ratios.
%
%   res = dct_vs_svd(g, fov, roi, cfg)
%
%   Purpose : For each target ratio CR in cfg.compare.cr_list choose the
%             SVD rank k = round(H*W / (CR*(H+W+1))) and keep exactly the
%             same number of stored values, k*(H+W+1), as largest DCT
%             coefficients. (Coefficient positions are not counted for
%             either method.) Report PSNR / MSE in a table and plot PSNR
%             vs CR; show reconstructions at cfg.compare.cr_show.
%   Inputs  : g - green channel in [0,1] (outside FOV filled); fov; roi; cfg
%   Outputs : res - struct: cr, k, psnrDct, psnrSvd, mseDct, mseSvd,
%                   table (cell), metrics
[H, W] = size(g);
crs = cfg.compare.cr_list(:)';
[U, S, V] = svd(g, 'econ');
C = tf_dct2(g);
[~, order] = sort(abs(C(:)), 'descend');
n = numel(crs);
res.cr = zeros(1, n); res.k = zeros(1, n);
res.psnrDct = zeros(1, n); res.psnrSvd = zeros(1, n);
res.mseDct = zeros(1, n);  res.mseSvd = zeros(1, n);
rows = {};
M = {};
show = [];
for i = 1:n
    k = max(1, min(min(H, W), round(H * W / (crs(i) * (H + W + 1)))));
    nStore = k * (H + W + 1);
    res.k(i) = k;
    res.cr(i) = H * W / nStore;                       % actual matched ratio
    rs = min(max(U(:, 1:k) * S(1:k, 1:k) * V(:, 1:k)', 0), 1);
    Ck = zeros(size(C)); Ck(order(1:nStore)) = C(order(1:nStore));
    rd = min(max(tf_dct2(Ck, true), 0), 1);
    [res.psnrDct(i), res.mseDct(i)] = psnr_mse(g, rd, fov);
    [res.psnrSvd(i), res.mseSvd(i)] = psnr_mse(g, rs, fov);
    rows(end + 1, :) = {sprintf('%.2f', res.cr(i)), 'DCT', sprintf('%d coeffs (%.2f%%)', nStore, 100 * nStore / (H * W)), res.psnrDct(i), res.mseDct(i)};
    rows(end + 1, :) = {sprintf('%.2f', res.cr(i)), 'SVD', sprintf('k = %d', k), res.psnrSvd(i), res.mseSvd(i)};
    tag = sprintf('CR %.1f', res.cr(i));
    M = add_metric(M, [tag ' DCT'], 'PSNR (dB)', res.psnrDct(i));
    M = add_metric(M, [tag ' DCT'], 'MSE', res.mseDct(i));
    M = add_metric(M, [tag ' SVD'], 'PSNR (dB)', res.psnrSvd(i));
    M = add_metric(M, [tag ' SVD'], 'MSE', res.mseSvd(i));
    if crs(i) == cfg.compare.cr_show || (isempty(show) && i == n)
        show = struct('rd', rd, 'rs', rs, 'i', i);
    end
end
header = {'CR', 'Method', 'Parameter', 'PSNR_dB', 'MSE'};
res.table = [header; rows];
print_table('DCT vs SVD at matched compression ratio', header, rows);
write_csv(fullfile(cfg.paths.outputs, 'dct_vs_svd.csv'), header, rows);

i = show.i;
fig = new_fig('DCT vs SVD', cfg, 2, 4);
show_panel(2, 4, 1, g .* fov, 'Original green');
show_panel(2, 4, 2, show.rd .* fov, sprintf('DCT, CR %.1f: PSNR %.2f dB', res.cr(i), res.psnrDct(i)));
show_panel(2, 4, 3, show.rs .* fov, sprintf('SVD k=%d, CR %.1f: PSNR %.2f dB', res.k(i), res.cr(i), res.psnrSvd(i)));
subplot(2, 4, 4);
plot(res.cr, res.psnrDct, 'b-o', res.cr, res.psnrSvd, 'r-s', 'LineWidth', 1.5);
set(gca, 'XScale', 'log'); grid on; xlabel('compression ratio'); ylabel('PSNR (dB)');
legend('DCT', 'SVD', 'Location', 'northeast'); title('PSNR vs compression ratio', 'FontSize', 9);
show_panel(2, 4, 5, crop_roi(g, roi), 'Original (zoom)');
show_panel(2, 4, 6, crop_roi(show.rd, roi), 'DCT (zoom)');
show_panel(2, 4, 7, crop_roi(show.rs, roi), 'SVD (zoom)');
show_panel(2, 4, 8, abs(show.rd - show.rs) .* fov, '|DCT - SVD|', [0 0.1]);
save_fig(fig, 'u2_05_dct_vs_svd', cfg);
res.metrics = M;
end
