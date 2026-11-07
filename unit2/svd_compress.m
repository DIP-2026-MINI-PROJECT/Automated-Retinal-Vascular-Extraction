function [recs, res] = svd_compress(g, fov, roi, cfg)
% SVD_COMPRESS  Low-rank (truncated SVD) approximation of the green channel.
%
%   [recs, res] = svd_compress(g, fov, roi, cfg)
%
%   Purpose : g = U S V'. Keeping the top k singular values gives the best
%             rank-k approximation. For each k in cfg.svd.k_list report the
%             energy retained sum(s(1:k).^2)/sum(s.^2), the compression
%             ratio H*W / (k*(H+W+1)) and PSNR / MSE. Plot the cumulative
%             energy curve.
%   Inputs  : g - green channel in [0,1] (outside FOV filled); fov; roi; cfg
%   Outputs : recs - cell array of reconstructions (one per k)
%             res  - struct: k, energy, cr, psnr, mse, s, metrics
[H, W] = size(g);
kList = cfg.svd.k_list(:)';
kList = kList(kList >= 1 & kList <= min(H, W));
if isempty(kList)
    error('svd_compress:k', 'cfg.svd.k_list has no valid rank.');
end
[U, S, V] = svd(g, 'econ');
s = diag(S);
cumE = cumsum(s .^ 2) / sum(s .^ 2);
n = numel(kList);
recs = cell(1, n);
res.k = kList; res.s = s;
res.energy = cumE(kList)';
res.cr = H * W ./ (kList * (H + W + 1));
res.psnr = zeros(1, n); res.mse = zeros(1, n);
M = {};
for i = 1:n
    k = kList(i);
    recs{i} = min(max(U(:, 1:k) * S(1:k, 1:k) * V(:, 1:k)', 0), 1);
    [res.psnr(i), res.mse(i)] = psnr_mse(g, recs{i}, fov);
    tag = sprintf('k = %d', k);
    M = add_metric(M, tag, 'energy retained', res.energy(i));
    M = add_metric(M, tag, 'compression ratio', res.cr(i));
    M = add_metric(M, tag, 'PSNR (dB)', res.psnr(i));
    M = add_metric(M, tag, 'MSE', res.mse(i));
    fprintf('      k=%4d  energy %.4f  CR %6.2f  PSNR %6.2f dB\n', k, res.energy(i), res.cr(i), res.psnr(i));
end

fig = new_fig('SVD compression', cfg, 3, 6);
cols = n + 1;
show_panel(3, cols, 1, g .* fov, 'Original green');
show_panel(3, cols, cols + 1, crop_roi(g, roi), 'Original (zoom)');
for i = 1:n
    show_panel(3, cols, 1 + i, recs{i} .* fov, sprintf('k=%d: CR %.1f, PSNR %.2f dB', ...
               kList(i), res.cr(i), res.psnr(i)));
    show_panel(3, cols, cols + 1 + i, crop_roi(recs{i}, roi), sprintf('k=%d (zoom)', kList(i)));
end
subplot(3, 2, 5);
plot(1:numel(cumE), cumE, 'b-', 'LineWidth', 1.5); hold on;
plot(kList, res.energy, 'ro', 'MarkerFaceColor', 'r'); hold off;
grid on; xlabel('k (number of singular values)'); ylabel('cumulative energy');
title('Energy retained vs k', 'FontSize', 9);
xlim([1 min(numel(cumE), 2 * max(kList))]);
subplot(3, 2, 6);
semilogy(s, 'k-', 'LineWidth', 1.2); grid on;
xlabel('index'); ylabel('singular value'); title('Singular values (log scale)', 'FontSize', 9);
save_fig(fig, 'u2_04_svd_compress', cfg);
res.metrics = M;
end
