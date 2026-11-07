% MAIN_PIPELINE  Retinal vessel extraction from one fundus image, end to end.
%
%   Run from the project folder (or anywhere: paths are set up below):
%       >> main_pipeline
%
%   Purpose : load -> Unit 1 (fundamentals) -> Unit 2 (transforms) ->
%             Unit 3 (enhancement / restoration) -> Unit 4 (morphology,
%             pseudocolour) -> evaluation -> summary.
%             Set cfg.run.mode in config.m to 'unit1' ... 'unit4' or 'eval'
%             to run only one stage; it then reads the previous stage's
%             output from outputs/handoff.mat (written by a full run) or
%             falls back to the normalised green channel.
%   Inputs  : none (everything comes from config.m and data/)
%   Outputs : figures (PNG), results.mat, metrics.csv, summary.csv and
%             per-stage CSV tables in outputs/; variables R and S in the
%             workspace.
%
%   No machine learning is used anywhere: every step is a classical
%   image-processing operation.

%% ======================================================== 0. setup
clc; close all;
projectRoot = fileparts(mfilename('fullpath'));
if ~exist(fullfile(projectRoot, 'utils'), 'dir')
    error('main_pipeline:folders', ['Sub-folders (utils, unit1, ...) not found next to main_pipeline.m.\n' ...
          'Extract the whole zip first (right-click > Extract All) and run main_pipeline from the extracted folder:\n%s'], projectRoot);
end
addpath(projectRoot, fullfile(projectRoot, 'utils'), fullfile(projectRoot, 'unit1'), ...
        fullfile(projectRoot, 'unit2'), fullfile(projectRoot, 'unit3'), ...
        fullfile(projectRoot, 'unit4'), fullfile(projectRoot, 'evaluation'));
if exist('OCTAVE_VERSION', 'builtin')
    pkg load image;                      % Octave only; MATLAB has the toolbox
end
cfg = config();
% run_all_images.m sets pipelineOverride to process one image of a folder
if exist('pipelineOverride', 'var') && isstruct(pipelineOverride)
    cfg.paths.image   = pipelineOverride.image;
    cfg.paths.gt      = pipelineOverride.gt;
    cfg.paths.fov     = pipelineOverride.fov;
    cfg.paths.outputs = pipelineOverride.outputs;
    cfg.run.mode      = 'all';
end
if ~exist(cfg.paths.outputs, 'dir'), mkdir(cfg.paths.outputs); end
runMode = lower(cfg.run.mode);
validModes = {'all', 'unit1', 'unit2', 'unit3', 'unit4', 'eval'};
if ~any(strcmp(runMode, validModes))
    error('main_pipeline:mode', 'cfg.run.mode must be one of: %s', strjoin(validModes, ', '));
end
runStage = @(s) strcmp(runMode, 'all') || strcmp(runMode, s);
handoffFile = fullfile(cfg.paths.outputs, 'handoff.mat');
H = struct();
if ~strcmp(runMode, 'all') && exist(handoffFile, 'file')
    tmp = load(handoffFile); H = tmp.H;
end
R = struct();                              % every result struct
allMetrics = cell(0, 4);                   % {stage, item, metric, value}
tStart = tic;
fprintf('==============================================================\n');
fprintf(' Retinal vessel extraction pipeline   (mode: %s)\n', runMode);
fprintf('==============================================================\n');

%% ======================================================== 1. load sample
fprintf('\n[Stage 0] Loading sample and FOV mask\n');
S = struct();
[S.rgb, S.gt, fovIn, S.info] = load_sample(cfg);
fprintf('      image: %s (%d x %d)\n', S.info.image, size(S.rgb, 1), size(S.rgb, 2));
if isempty(S.gt)
    warning('main_pipeline:noGT', 'No ground-truth mask: evaluation metrics will be skipped.');
else
    fprintf('      ground truth: %s\n', S.info.gt);
end
if cfg.scale.upsample_below > 0 && size(S.rgb, 2) < cfg.scale.upsample_below
    f = cfg.scale.ref_width / size(S.rgb, 2);
    fprintf('      image is only %d px wide: upsampling x%.2f (bicubic) to %d px\n', ...
            size(S.rgb, 2), f, cfg.scale.ref_width);
    sz = round([size(S.rgb, 1) size(S.rgb, 2)] * f);
    S.rgb = min(max(imresize(S.rgb, sz, 'bicubic'), 0), 1);
    if ~isempty(S.gt),  S.gt  = imresize(S.gt, sz, 'nearest');  end
    if ~isempty(fovIn), fovIn = imresize(fovIn, sz, 'nearest'); end
end
cfg = scale_params(cfg, size(S.rgb));
[S.fov, S.fovE, S.g, R.fov] = get_fov_mask(S.rgb, fovIn, cfg);
S.roi = pick_zoom_roi(S.g, S.fovE, cfg);
fprintf('      zoom window [row col h w] = %s\n', mat2str(S.roi));
allMetrics = [allMetrics; metrics_to_rows('Foundation', R.fov.metrics)];

%% ======================================================== 2. Unit 1
if runStage('unit1')
    fprintf('\n[Unit 1] Digital image fundamentals\n');
    R.unit1 = unit1_demo(cfg, S);
    allMetrics = [allMetrics; metrics_to_rows('Unit 1', R.unit1.metrics)];
end

%% ======================================================== 3. Unit 2
if runStage('unit2')
    fprintf('\n[Unit 2] Image transforms\n');
    fprintf('    [2a] DFT spectrum\n');
    R.dft = dft_spectrum(S.g, S.fovE, cfg);
    fprintf('    [2b] DCT compression and denoising\n');
    [H.dct, R.dct] = dct_denoise(S.g, S.fovE, S.roi, cfg);
    fprintf('    [2c] SVD compression\n');
    [svdRecs, R.svd] = svd_compress(S.g, S.fovE, S.roi, cfg);
    kSel = find(R.svd.k == cfg.unit3.svd_k, 1);
    if isempty(kSel), [~, kSel] = min(abs(R.svd.k - cfg.unit3.svd_k)); end
    H.svd = svdRecs{kSel};
    fprintf('    [2d] DCT vs SVD\n');
    R.dctsvd = dct_vs_svd(S.g, S.fovE, S.roi, cfg);
    allMetrics = [allMetrics; metrics_to_rows('Unit 2 / DFT', R.dft.metrics); ...
                  metrics_to_rows('Unit 2 / DCT', R.dct.metrics); ...
                  metrics_to_rows('Unit 2 / SVD', R.svd.metrics); ...
                  metrics_to_rows('Unit 2 / DCT vs SVD', R.dctsvd.metrics)];
end
% image handed to Unit 3 and to the baseline
switch lower(cfg.unit3.input)
    case 'dct', key = 'dct';
    case 'svd', key = 'svd';
    case 'raw', key = '';
    otherwise, error('main_pipeline:input', 'cfg.unit3.input must be dct, svd or raw.');
end
if ~isempty(key) && isfield(H, key)
    denoised = fill_outside_fov(H.(key), S.fovE);
else
    if ~isempty(headline)
        warning('main_pipeline:handoff', 'No Unit 2 output available; Unit 3 uses the normalised green channel.');
    end
    denoised = S.g;
end
H.denoised = denoised;

%% ======================================================== 4. Unit 3
if runStage('unit3')
    fprintf('\n[Unit 3] Enhancement and restoration (input: %s)\n', cfg.unit3.input);
    fprintf('    [3a] illumination correction and CLAHE\n');
    [enh, R.enhance] = enhance_illumination(denoised, S.fovE, S.gt, cfg);
    fprintf('    [3b] spatial filtering\n');
    R.spatial = spatial_filtering(enh, S.fovE, S.roi, S.gt, cfg);
    fprintf('    [3c] frequency-domain filtering\n');
    R.freq = freq_filtering(enh, S.fovE, cfg);
    switch lower(cfg.unit3.final_filter)
        case 'none',     final = enh;
        case 'median',   final = medfilt2(enh, cfg.unit3.final_size * [1 1], 'symmetric');
        case 'gaussian', final = imfilter(enh, fspecial('gaussian', 2 * cfg.unit3.final_size + 1, cfg.unit3.final_size / 2), 'replicate');
        case 'wiener',   final = wiener2(enh, cfg.unit3.final_size * [1 1]);
        otherwise, error('main_pipeline:final', 'Unknown cfg.unit3.final_filter.');
    end
    H.unit3 = fill_outside_fov(min(max(final, 0), 1), S.fovE);
    fprintf('      Unit 3 output: CLAHE(illumination-corrected) + %s filter\n', cfg.unit3.final_filter);
    fprintf('    [3d] restoration (noise added to the Unit 3 output)\n');
    R.restore = restoration_compare(H.unit3, S.fovE, S.roi, cfg);
    allMetrics = [allMetrics; metrics_to_rows('Unit 3 / enhancement', R.enhance.metrics); ...
                  metrics_to_rows('Unit 3 / spatial', R.spatial.metrics); ...
                  metrics_to_rows('Unit 3 / frequency', R.freq.metrics); ...
                  metrics_to_rows('Unit 3 / restoration', R.restore.metrics)];
end

%% ======================================================== 5. Unit 4
if runStage('unit4')
    if isfield(H, 'unit3')
        u4in = H.unit3;
    else
        warning('main_pipeline:handoff', 'No Unit 3 output available; Unit 4 uses the denoised green channel.');
        u4in = denoised;
    end
    fprintf('\n[Unit 4] Morphological processing and pseudocolour\n');
    fprintf('    [4a] black top-hat vessel extraction\n');
    [bwRaw, ~, R.morph] = morph_vessel_extract(u4in, S.fovE, cfg);
    fprintf('    [4b] mask clean-up\n');
    [H.mask, R.cleanup] = mask_cleanup(bwRaw, S.fovE, cfg);
    fprintf('    [4c] skeleton analysis\n');
    [R.features, H.skel] = skeleton_analysis(H.mask, S.fovE, cfg);
    fprintf('    [4d] pseudocolour output\n');
    R.pseudo = pseudocolor_output(S.rgb, H.mask, H.skel, S.fov, cfg);
    R.pseudo = rmfield(R.pseudo, {'maskRGB', 'overlayRGB'});   % keep results.mat small
    allMetrics = [allMetrics; metrics_to_rows('Unit 4 / extraction', R.morph.metrics); ...
                  metrics_to_rows('Unit 4 / cleanup', R.cleanup.metrics); ...
                  metrics_to_rows('Unit 4 / clinical features', R.features.metrics)];
end

%% ======================================================== 6. evaluation
if runStage('eval')
    fprintf('\n[Evaluation] Pipeline vs baseline\n');
    if ~isfield(H, 'mask')
        warning('main_pipeline:handoff', 'No Unit 4 mask available; run the full pipeline first.');
    else
        [bwBase, R.baseline] = baseline_threshold(denoised, S.fovE, cfg);
        R.evalPipeline = evaluate_mask(H.mask, S.gt, S.fovE, cfg, 'pipeline');
        R.evalBaseline = evaluate_mask(bwBase, S.gt, S.fovE, cfg, 'baseline');
        if R.evalPipeline.available
            f = {'sensitivity', 'specificity', 'accuracy', 'precision', 'dice'};
            rows = cell(numel(f), 4);
            for i = 1:numel(f)
                rows(i, :) = {f{i}, R.evalBaseline.(f{i}), R.evalPipeline.(f{i}), ...
                              R.evalPipeline.(f{i}) - R.evalBaseline.(f{i})};
            end
            hdr = {'Metric', 'Baseline', 'Pipeline', 'Improvement'};
            print_table('Baseline vs full pipeline (inside FOV)', hdr, rows);
            write_csv(fullfile(cfg.paths.outputs, 'comparison.csv'), hdr, rows);
            R.comparison = [hdr; rows];
            allMetrics = [allMetrics; metrics_to_rows('Evaluation', R.evalPipeline.metrics); ...
                          metrics_to_rows('Evaluation', R.evalBaseline.metrics)];
        end
    end
end

%% ======================================================== 7. summary
fprintf('\n[Summary]\n');
hdr = {'Stage', 'Item', 'Metric', 'Value'};
print_table('All numeric results', hdr, allMetrics);
R.metrics = [hdr; allMetrics];
R.cfg = cfg;
R.info = S.info;
R.runtime_s = toc(tStart);
write_csv(fullfile(cfg.paths.outputs, 'metrics.csv'), hdr, allMetrics);
save(fullfile(cfg.paths.outputs, 'results.mat'), 'R');
fprintf('      saved %s\n', fullfile(cfg.paths.outputs, 'results.mat'));
if strcmp(runMode, 'all')
    save(handoffFile, 'H');
end

% short headline summary
headline = {};
if isfield(R, 'dct'),      headline(end + 1, :) = {'DCT selected_cutoff (% kept)', R.dct.selected_cutoff}; end
if isfield(R, 'features')
    headline(end + 1, :) = {'Vessel density', R.features.vessel_density};
    headline(end + 1, :) = {'Branch points', R.features.branch_points};
    headline(end + 1, :) = {'Thin/thick ratio', R.features.thin_thick_ratio};
    headline(end + 1, :) = {'Skeleton length (px)', R.features.skeleton_length_px};
end
if isfield(R, 'evalPipeline') && R.evalPipeline.available
    headline(end + 1, :) = {'Pipeline Dice', R.evalPipeline.dice};
    headline(end + 1, :) = {'Pipeline sensitivity', R.evalPipeline.sensitivity};
    headline(end + 1, :) = {'Pipeline specificity', R.evalPipeline.specificity};
    headline(end + 1, :) = {'Pipeline accuracy', R.evalPipeline.accuracy};
    headline(end + 1, :) = {'Baseline Dice', R.evalBaseline.dice};
end
if ~isempty(headline)
    print_table('Headline results', {'Result', 'Value'}, headline);
    write_csv(fullfile(cfg.paths.outputs, 'summary.csv'), {'Result', 'Value'}, headline);
end
fprintf('\nDone in %.1f s. Figures and tables are in %s\n', R.runtime_s, cfg.paths.outputs);
