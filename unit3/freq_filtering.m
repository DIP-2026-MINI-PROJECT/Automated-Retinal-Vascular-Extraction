function res = freq_filtering(I, fov, cfg)
% FREQ_FILTERING  Ideal, Butterworth and Gaussian filters built by hand.
%
%   res = freq_filtering(I, fov, cfg)
%
%   Purpose : Pad the image to 2H x 2W (symmetric) to limit wrap-around,
%             take F = fftshift(fft2(.)), multiply by a transfer function
%             H(u,v) built from the distance D(u,v) to the centre, and
%             return real(ifft2(ifftshift(H.*F))) cropped to H x W.
%               ideal LPF       H = D <= D0
%               Butterworth LPF H = 1 / (1 + (D/D0)^(2n))
%               Gaussian LPF    H = exp(-D^2 / (2 D0^2))
%               Gaussian HPF    H = 1 - exp(-D^2 / (2 Dh^2))  (+ mean back)
%             The Gaussian HPF with a very small Dh removes only the slow
%             illumination gradient (illumination flattening).
%             D0 is given in frequency samples of the padded image.
%   Inputs  : I - image in [0,1] (outside FOV filled); fov; cfg (cfg.freq.*)
%   Outputs : res - struct: names, psnr (LPF vs input), nonuniformity,
%                   metrics
[H, W] = size(I);
P = padarray(I, [H W], 'symmetric', 'post');
F = fftshift(fft2(P));
[u, v] = meshgrid((0:2 * W - 1) - W, (0:2 * H - 1) - H);
D = sqrt(u .^ 2 + v .^ 2);
D0 = cfg.freq.lp_cutoff; n = cfg.freq.butter_order; Dh = cfg.freq.hp_cutoff;
Hs = {double(D <= D0), 1 ./ (1 + (D / D0) .^ (2 * n)), exp(-D .^ 2 / (2 * D0 ^ 2)), ...
      1 - exp(-D .^ 2 / (2 * Dh ^ 2))};
names = {sprintf('Ideal LPF D0=%g', D0), sprintf('Butterworth LPF D0=%g n=%d', D0, n), ...
         sprintf('Gaussian LPF D0=%g', D0), sprintf('Gaussian HPF D0=%g', Dh)};
out = cell(1, 4);
for i = 1:4
    g = real(ifft2(ifftshift(Hs{i} .* F)));
    out{i} = g(1:H, 1:W);
end
out{4} = min(max(out{4} + mean(I(fov)), 0), 1);      % restore DC (flattening)
out(1:3) = cellfun(@(x) min(max(x, 0), 1), out(1:3), 'UniformOutput', false);

res.names = names;
res.psnr = cellfun(@(x) psnr_mse(I, x, fov), out);
nu = @(x) illum_nonuniformity(x, fov, cfg.unit3.bg_sigma);
res.nonuniformity = [nu(I), cellfun(nu, out)];
M = {};
for i = 1:4
    M = add_metric(M, names{i}, 'PSNR vs input (dB)', res.psnr(i));
    M = add_metric(M, names{i}, 'illumination non-uniformity', res.nonuniformity(i + 1));
end
M = add_metric(M, 'input', 'illumination non-uniformity', res.nonuniformity(1));
fprintf('      LPF PSNR vs input: ideal %.2f, Butterworth %.2f, Gaussian %.2f dB\n', res.psnr(1:3));
fprintf('      non-uniformity: input %.4f -> Gaussian HPF %.4f\n', res.nonuniformity(1), res.nonuniformity(5));

fig = new_fig('Frequency-domain filtering', cfg, 3, 4);
cy = H + 1; cx = W + 1;
win = @(r) {max(1, cy - r):min(2 * H, cy + r), max(1, cx - r):min(2 * W, cx + r)};
spans = [3 * D0, 3 * D0, 3 * D0, 8 * Dh];             % centre region per filter
for i = 1:4
    w = win(spans(i));
    show_panel(3, 4, i, Hs{i}(w{1}, w{2}), {names{i}, sprintf('H(u,v), |u|,|v| <= %d', spans(i))}, [0 1]);
    show_panel(3, 4, 4 + i, out{i} .* fov, sprintf('%s result', names{i}));
end
subplot(3, 4, 9:10);
r = 3 * D0;
prof = cellfun(@(h) h(cy, cx:min(2 * W, cx + r)), Hs, 'UniformOutput', false);
plot(0:numel(prof{1}) - 1, cat(1, prof{:})', 'LineWidth', 1.5); grid on;
xlabel('D (frequency samples)'); ylabel('H'); ylim([-0.05 1.05]);
legend(names, 'Location', 'east'); title('Radial profiles of the transfer functions', 'FontSize', 9);
show_panel(3, 4, 11, I .* fov, 'Input');
w = win(3 * D0);
show_panel(3, 4, 12, log(1 + abs(F(w{1}, w{2}))), 'log|F| of padded input (centre)', []);
save_fig(fig, 'u3_04_freq_filtering', cfg);
res.metrics = M;
end
