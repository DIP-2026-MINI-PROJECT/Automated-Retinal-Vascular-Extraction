function res = sampling_quantization(g, fov, cfg)
% SAMPLING_QUANTIZATION  Effect of spatial sampling and gray-level count.
%
%   res = sampling_quantization(g, fov, cfg)
%
%   Purpose : (a) keep every f-th pixel (f from cfg.unit1.sample_factors)
%             and show it back at full size with pixel replication;
%             (b) requantise to L gray levels (cfg.unit1.gray_levels).
%             The MSE against the original inside the FOV is reported.
%   Inputs  : g - green channel in [0,1]; fov - logical mask; cfg
%   Outputs : res - struct: factors, mseSampling, levels, mseQuant, metrics
f = cfg.unit1.sample_factors;
L = cfg.unit1.gray_levels;
if any(f < 1) || any(L < 2)
    error('sampling_quantization:params', 'factors must be >= 1 and levels >= 2.');
end
nc = max(numel(f), numel(L));
fig = new_fig('Sampling and quantisation', cfg, 2, 4);
M = {};
res.factors = f; res.levels = L;
res.mseSampling = zeros(1, numel(f));
res.mseQuant = zeros(1, numel(L));
for i = 1:numel(f)
    sub = g(1:f(i):end, 1:f(i):end);                       % sampling
    back = imresize(sub, size(g), 'nearest');              % replicate
    [~, res.mseSampling(i)] = psnr_mse(g, back, fov);
    show_panel(2, nc, i, back .* fov, sprintf('1/%d sampling (%dx%d), MSE %.2e', ...
               f(i), size(sub, 1), size(sub, 2), res.mseSampling(i)));
    M = add_metric(M, sprintf('sampling 1/%d', f(i)), 'MSE', res.mseSampling(i));
end
for i = 1:numel(L)
    q = round(g * (L(i) - 1)) / (L(i) - 1);                % quantisation
    [~, res.mseQuant(i)] = psnr_mse(g, q, fov);
    show_panel(2, nc, nc + i, q .* fov, sprintf('%d gray levels, MSE %.2e', L(i), res.mseQuant(i)));
    M = add_metric(M, sprintf('%d gray levels', L(i)), 'MSE', res.mseQuant(i));
end
fprintf('      sampling MSE: %s\n', mat2str(res.mseSampling, 3));
fprintf('      quantisation MSE: %s\n', mat2str(res.mseQuant, 3));
save_fig(fig, 'u1_05_sampling_quantization', cfg);
res.metrics = M;
end
