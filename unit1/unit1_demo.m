function [res, S] = unit1_demo(cfg, S)
% UNIT1_DEMO  Unit 1 (digital image fundamentals) on one fundus image.
%
%   [res, S] = unit1_demo()          loads everything itself
%   [res, S] = unit1_demo(cfg, S)    reuses an already loaded sample
%
%   Purpose : Show the inputs, then run channel_split, interp_compare and
%             sampling_quantization.
%   Inputs  : cfg - configuration struct (default: config())
%             S   - sample struct with fields rgb, gt, fov, fovE, g, roi
%                   (default: built with load_sample + get_fov_mask)
%   Outputs : res - struct with one field per sub-stage and res.metrics
%                   (n x 3 cell {item, metric, value})
%             S   - the sample struct (useful when it was built here)
if nargin < 1 || isempty(cfg), cfg = config(); end
if nargin < 2 || isempty(S)
    S = struct();
    [S.rgb, S.gt, fovIn] = load_sample(cfg);
    [S.fov, S.fovE, S.g] = get_fov_mask(S.rgb, fovIn, cfg);
    S.roi = pick_zoom_roi(S.g, S.fovE, cfg);
end

% ---- input overview
fig = new_fig('Inputs', cfg, 1, 3);
show_panel(1, 3, 1, S.rgb, 'Fundus image');
if isempty(S.gt)
    show_panel(1, 3, 2, false(size(S.fov)), 'Ground truth: not available');
else
    show_panel(1, 3, 2, S.gt, 'Ground-truth vessel mask');
end
ax = show_panel(1, 3, 3, S.rgb, 'Thin-vessel zoom window (yellow)');
hold(ax, 'on');
rectangle('Position', [S.roi(2) S.roi(1) S.roi(4) S.roi(3)], ...
          'EdgeColor', 'y', 'LineWidth', 2);
hold(ax, 'off');
save_fig(fig, 'u1_01_inputs', cfg);

fprintf('    [1a] channel separation\n');
res.channels = channel_split(S.rgb, S.fovE, S.gt, cfg);
fprintf('    [1b] interpolation comparison\n');
res.interp = interp_compare(S.g, S.fovE, S.roi, cfg);
fprintf('    [1c] sampling and quantisation\n');
res.sampq = sampling_quantization(S.g, S.fovE, cfg);
res.metrics = [res.channels.metrics; res.interp.metrics; res.sampq.metrics];
end
