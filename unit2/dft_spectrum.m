function res = dft_spectrum(g, fov, cfg)
% DFT_SPECTRUM  2-D DFT of the green channel and its log-magnitude spectrum.
%
%   res = dft_spectrum(g, fov, cfg)
%
%   Purpose : F = fftshift(fft2(g - mean)) puts zero frequency in the
%             centre. log(1 + |F|) is displayed because the magnitudes span
%             many orders. The share of spectral energy inside a radius of
%             cfg.dft.lowfreq_radius shows how concentrated the image is in
%             low frequencies (the reason transform compression works).
%   Inputs  : g - green channel in [0,1] (outside FOV filled); fov; cfg
%   Outputs : res - struct: lowFreqEnergy (fraction), metrics
[H, W] = size(g);
F = fftshift(fft2(g - mean(g(fov))));
P = abs(F) .^ 2;
[u, v] = meshgrid((0:W - 1) - floor(W / 2), (0:H - 1) - floor(H / 2));
D = sqrt(u .^ 2 + v .^ 2);
res.lowFreqEnergy = sum(P(D <= cfg.dft.lowfreq_radius)) / sum(P(:));
logMag = log(1 + abs(F));
fig = new_fig('DFT spectrum', cfg, 1, 3);
show_panel(1, 3, 1, g .* fov, 'Green channel');
show_panel(1, 3, 2, logMag, 'log(1+|F|), fftshift-ed', []);
colormap(gca, 'jet'); colorbar;
c = [floor(H / 2) + 1, floor(W / 2) + 1];
r = min(64, floor(min(H, W) / 4));
show_panel(1, 3, 3, logMag(c(1) - r:c(1) + r, c(2) - r:c(2) + r), ...
           sprintf('Centre zoom; %.1f%% of energy within radius %d', ...
           100 * res.lowFreqEnergy, cfg.dft.lowfreq_radius), []);
colormap(gca, 'jet'); colorbar;
save_fig(fig, 'u2_01_dft_spectrum', cfg);
fprintf('      %.1f%% of spectral energy within radius %d\n', 100 * res.lowFreqEnergy, cfg.dft.lowfreq_radius);
res.metrics = add_metric({}, 'DFT', sprintf('energy fraction r<=%d', cfg.dft.lowfreq_radius), res.lowFreqEnergy);
end
