% RUN_ALL_IMAGES  Run the full pipeline on every fundus image in data/.
%
%   >> run_all_images
%
%   Purpose : Loops over all fundus images in data/ and runs
%             main_pipeline once per image. Each image gets its own folder
%             outputs/<image name>/ so results never overwrite each other.
%             A ground-truth or FOV mask is paired with an image when its
%             file name starts with the same first token as the image
%             (DRIVE style: 21_training.tif <-> 21_manual1.gif,
%             21_training_mask.gif). Unpaired images run without them.
%             At the end one table compares all images:
%             outputs/all_images_summary.csv.
%   Inputs  : none (images in data/, settings in config.m)
%   Outputs : outputs/<image>/...  and  outputs/all_images_summary.csv

batchRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(batchRoot, 'utils'));
batchCfg = config();
[batchNames, batchIsImg, batchIsGt, batchIsFov] = list_data_images(batchCfg.paths.data);
batchImages = batchNames(batchIsImg);
if isempty(batchImages)
    error('run_all_images:none', 'No fundus images found in %s', batchCfg.paths.data);
end
batchHdr = {'Image', 'GT', 'Vessel_density', 'Branch_points', 'Thin_thick_ratio', ...
            'Skeleton_length_px', 'DCT_cutoff_pct', 'Dice', 'Sensitivity', 'Specificity', 'Accuracy'};
batchRows = cell(0, numel(batchHdr));
for batchIdx = 1:numel(batchImages)
    batchImg = batchImages{batchIdx};
    [~, batchStem] = fileparts(batchImg);
    batchTok = regexp(batchStem, '^[^_\-\s.]+', 'match', 'once');
    batchGt = 'none'; batchFov = 'none';
    batchPairs = batchNames(batchIsGt & strncmpi(batchNames, batchTok, numel(batchTok)));
    if ~isempty(batchPairs), batchGt = batchPairs{1}; end
    batchPairs = batchNames(batchIsFov & strncmpi(batchNames, batchTok, numel(batchTok)));
    if ~isempty(batchPairs), batchFov = batchPairs{1}; end
    fprintf('\n##### Image %d of %d: %s  (gt: %s, fov: %s)\n', batchIdx, numel(batchImages), ...
            batchImg, batchGt, batchFov);
    pipelineOverride = struct('image', batchImg, 'gt', batchGt, 'fov', batchFov, ...
                              'outputs', fullfile(batchCfg.paths.outputs, batchStem));
    try
        main_pipeline;
        batchEv = {NaN, NaN, NaN, NaN};
        if isfield(R, 'evalPipeline') && R.evalPipeline.available
            batchEv = {R.evalPipeline.dice, R.evalPipeline.sensitivity, ...
                       R.evalPipeline.specificity, R.evalPipeline.accuracy};
        end
        batchRows(end + 1, :) = [{batchImg, batchGt, R.features.vessel_density, ...
            R.features.branch_points, R.features.thin_thick_ratio, ...
            R.features.skeleton_length_px, R.dct.selected_cutoff}, batchEv];
    catch batchErr
        fprintf(2, 'Image %s failed: %s\n', batchImg, batchErr.message);
        batchRows(end + 1, :) = [{batchImg, batchGt}, num2cell(NaN(1, numel(batchHdr) - 2))];
    end
end
clear pipelineOverride;
print_table('All images', batchHdr, batchRows);
write_csv(fullfile(batchCfg.paths.outputs, 'all_images_summary.csv'), batchHdr, batchRows);
