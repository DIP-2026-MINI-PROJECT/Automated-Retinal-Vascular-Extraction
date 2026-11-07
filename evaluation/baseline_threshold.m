function [bw, res] = baseline_threshold(I, fov, cfg)
% BASELINE_THRESHOLD  Simple baseline: one global threshold, no morphology.
%
%   [bw, res] = baseline_threshold(I, fov, cfg)
%
%   Purpose : Vessels are darker than the background, so the baseline
%             marks every FOV pixel below one global threshold (Otsu over
%             the FOV, or cfg.baseline.fixed_thresh) as vessel. It ignores
%             uneven illumination and vessel shape, which is what the full
%             pipeline adds.
%   Inputs  : I - denoised green channel (Unit 2 output) in [0,1]
%             fov - logical mask; cfg (cfg.baseline.*)
%   Outputs : bw - logical baseline mask; res - struct: threshold
switch lower(cfg.baseline.method)
    case 'otsu',  t = graythresh(I(fov)');
    case 'fixed', t = cfg.baseline.fixed_thresh;
    otherwise, error('baseline_threshold:method', 'Unknown baseline method.');
end
bw = (I < t) & fov;
res.threshold = t;
fprintf('      baseline global threshold = %.3f, vessel fraction %.3f\n', t, nnz(bw) / nnz(fov));
fig = new_fig('Baseline', cfg, 1, 2);
show_panel(1, 2, 1, I .* fov, 'Denoised green (Unit 2)');
show_panel(1, 2, 2, bw, sprintf('Baseline: global %s threshold t = %.3f', cfg.baseline.method, t));
save_fig(fig, 'eval_baseline', cfg);
end
