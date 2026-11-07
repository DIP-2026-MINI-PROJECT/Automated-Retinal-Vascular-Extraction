function [bw, resp, res] = morph_vessel_extract(I, fov, cfg)
% MORPH_VESSEL_EXTRACT  Vessel response by black top-hat, then threshold.
%
%   [bw, resp, res] = morph_vessel_extract(I, fov, cfg)
%
%   Purpose : Vessels are thin dark lines on a brighter background, so the
%             black top-hat  closing(I, disk) - I  (imbothat) is large on
%             them and near zero elsewhere. The disk radius must exceed
%             half the widest vessel (cfg.morph.disk_radius).
%             Optional line bank (cfg.morph.use_line_bank): before the
%             top-hat, small dark blobs (noise, haemorrhage-like spots)
%             are removed with the supremum of openings of the inverted
%             image by line SEs at cfg.morph.line_angles. A long thin
%             vessel survives at least the opening along its own
%             direction; a short blob survives none of them.
%             The response is normalised inside the FOV and binarised with
%             Otsu (graythresh), a fixed value, or a percentile.
%   Inputs  : I - enhanced green channel in [0,1] (outside FOV filled)
%             fov - logical (eroded) FOV mask; cfg (cfg.morph.*)
%   Outputs : bw   - logical vessel mask (inside FOV)
%             resp - normalised top-hat response in [0,1]
%             res  - struct: threshold, vesselFraction, metrics
m = cfg.morph;
J = I;
if m.use_line_bank
    neg = 1 - I;
    op = zeros(size(I));
    for a = m.line_angles                            % one SE per angle
        op = max(op, imopen(neg, strel('line', m.line_length, a)));
    end
    J = 1 - op;
end
raw = imbothat(J, strel('disk', m.disk_radius, 0));
resp = norm_fov(raw, fov, [0 99.5]) .* fov;
switch lower(m.thresh_method)
    case 'otsu',       t = graythresh(resp(fov)');   % row vector: works in MATLAB and Octave
    case 'fixed',      t = m.fixed_thresh;
    case 'percentile', t = prctile_fov(resp, fov, m.percentile);
    otherwise, error('morph_vessel_extract:method', 'Unknown thresh_method %s', m.thresh_method);
end
bw = (resp > t) & fov;
res.threshold = t;
res.vesselFraction = nnz(bw) / nnz(fov);
fprintf('      threshold (%s) = %.3f, raw vessel fraction = %.3f\n', m.thresh_method, t, res.vesselFraction);
M = {};
M = add_metric(M, 'top-hat', ['threshold (' m.thresh_method ')'], t);
M = add_metric(M, 'top-hat', 'raw vessel fraction', res.vesselFraction);

fig = new_fig('Morphological vessel extraction', cfg, 2, 3);
show_panel(2, 3, 1, I .* fov, 'Unit 3 output (input here)');
if m.use_line_bank
    show_panel(2, 3, 2, J .* fov, sprintf('Line-bank filtered (L=%d, %d angles)', m.line_length, numel(m.line_angles)));
else
    show_panel(2, 3, 2, J .* fov, 'No line bank');
end
show_panel(2, 3, 3, resp, sprintf('Black top-hat response (disk r=%d)', m.disk_radius));
show_panel(2, 3, 4, bw, sprintf('Binarised (%s, t=%.3f)', m.thresh_method, t));
subplot(2, 3, 5:6);
bar(linspace(0, 1, 128), log10(1 + fov_hist(resp, fov, 128)), 1, 'FaceColor', [0.3 0.3 0.3], 'EdgeColor', 'none');
hold on; yl = ylim; plot([t t], yl, 'r-', 'LineWidth', 2); hold off;
xlim([0 1]); xlabel('top-hat response'); ylabel('log_{10}(1 + pixels)');
legend('histogram (FOV)', 'threshold'); title('Response histogram', 'FontSize', 9);
save_fig(fig, 'u4_01_morph_extract', cfg);
res.metrics = M;
end
