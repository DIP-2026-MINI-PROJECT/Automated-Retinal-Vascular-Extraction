function ev = evaluate_mask(pred, gt, fov, cfg, name)
% EVALUATE_MASK  Pixel-wise scores of a vessel mask against ground truth.
%
%   ev = evaluate_mask(pred, gt, fov, cfg, name)
%
%   Purpose : Count TP, FP, FN, TN inside the FOV only and compute
%             sensitivity TP/(TP+FN), specificity TN/(TN+FP), accuracy,
%             precision TP/(TP+FP) and Dice 2TP/(2TP+FP+FN). Save a
%             colour-coded error map: TP white, FP red, FN blue, TN black.
%             If gt is empty, warn and return NaN scores (no crash).
%   Inputs  : pred - predicted logical mask; gt - ground truth or []
%             fov  - logical FOV mask; cfg; name - label used in titles
%             and file names (e.g. 'pipeline', 'baseline')
%   Outputs : ev - struct: available, sensitivity, specificity, accuracy,
%                  precision, dice, TP, FP, FN, TN, metrics
fields = {'sensitivity', 'specificity', 'accuracy', 'precision', 'dice'};
ev.available = ~isempty(gt);
if ~ev.available
    warning('evaluate_mask:noGT', ...
        'No ground-truth mask found: skipping evaluation metrics for "%s".', name);
    for f = fields, ev.(f{1}) = NaN; end
    ev.TP = NaN; ev.FP = NaN; ev.FN = NaN; ev.TN = NaN;
    ev.metrics = {};
    return;
end
if ~isequal(size(pred), size(gt), size(fov))
    error('evaluate_mask:size', 'pred, gt and fov must have the same size.');
end
p = pred(fov); g = gt(fov);
ev.TP = nnz(p & g);  ev.FP = nnz(p & ~g);
ev.FN = nnz(~p & g); ev.TN = nnz(~p & ~g);
ev.sensitivity = ev.TP / max(ev.TP + ev.FN, 1);
ev.specificity = ev.TN / max(ev.TN + ev.FP, 1);
ev.accuracy    = (ev.TP + ev.TN) / numel(p);
ev.precision   = ev.TP / max(ev.TP + ev.FP, 1);
ev.dice        = 2 * ev.TP / max(2 * ev.TP + ev.FP + ev.FN, 1);
M = {};
for f = fields
    M = add_metric(M, name, f{1}, ev.(f{1}));
end
ev.metrics = M;
fprintf('      %-9s Se %.4f  Sp %.4f  Acc %.4f  Pr %.4f  Dice %.4f\n', name, ...
        ev.sensitivity, ev.specificity, ev.accuracy, ev.precision, ev.dice);

TP = pred & gt & fov; FP = pred & ~gt & fov; FN = ~pred & gt & fov;
err = cat(3, double(TP | FP), double(TP), double(TP | FN));
imwrite(err, fullfile(cfg.paths.outputs, sprintf('error_map_%s.png', name)));
fig = new_fig(['Error map ' name], cfg, 1, 3);
show_panel(1, 3, 1, pred, sprintf('%s prediction', name));
show_panel(1, 3, 2, gt & fov, 'Ground truth (inside FOV)');
ax = show_panel(1, 3, 3, err, {sprintf('Errors: TP white, FP red, FN blue, TN black'), ...
    sprintf('Se %.3f  Sp %.3f  Acc %.3f  Dice %.3f', ev.sensitivity, ev.specificity, ev.accuracy, ev.dice)});
save_fig(fig, sprintf('eval_error_map_%s', name), cfg);
end
