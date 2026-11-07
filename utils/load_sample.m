function [rgb, gt, fov, info] = load_sample(cfgOrImage, gtPath, fovPath)
% LOAD_SAMPLE  Load the fundus image, ground-truth vessel mask and FOV mask.
%
%   [rgb, gt, fov, info] = load_sample()             uses config()
%   [rgb, gt, fov, info] = load_sample(cfg)          uses cfg.paths
%   [rgb, gt, fov, info] = load_sample(imgPath, gtPath, fovPath)
%
%   Purpose : Read the three inputs, validate them and convert them to the
%             types used everywhere else. Missing masks are allowed.
%   Inputs  : cfg      - configuration struct (paths.data, paths.image,
%                        paths.gt, paths.fov; empty names are auto-detected)
%             imgPath, gtPath, fovPath - explicit file paths ('' = none)
%             ('none' for gt or fov means: do not look for that file)
%   Outputs : rgb  - H x W x 3 double image in [0,1]
%             gt   - H x W logical vessel mask, or [] if not available
%             fov  - H x W logical FOV mask, or [] if not available
%             info - struct with the file paths that were used
%
%   To loop over a folder later, call load_sample(imgPath, gtPath, fovPath)
%   once per image.
if nargin == 0
    cfgOrImage = config();
end
if isstruct(cfgOrImage)
    [imgPath, gtPath, fovPath] = resolve_paths(cfgOrImage);
else
    imgPath = cfgOrImage;
    if nargin < 2, gtPath = ''; end
    if nargin < 3, fovPath = ''; end
end
info = struct('image', imgPath, 'gt', gtPath, 'fov', fovPath);

% ---- fundus image
if isempty(imgPath) || ~exist(imgPath, 'file')
    error('load_sample:noImage', ...
        'Fundus image not found (%s). Put it in data/ or set cfg.paths.image.', imgPath);
end
rgb = im2double(imread(imgPath));
if ndims(rgb) ~= 3 || size(rgb, 3) < 3
    error('load_sample:notRGB', 'Fundus image must be RGB (H x W x 3): %s', imgPath);
end
rgb = rgb(:, :, 1:3);                        % drop an alpha channel if any
[H, W, ~] = size(rgb);
if H < 64 || W < 64
    error('load_sample:tooSmall', 'Image is too small (%d x %d).', H, W);
end

% ---- ground truth (optional)
gt = read_mask(gtPath, [H W], 'ground-truth');
% ---- FOV (optional)
fov = read_mask(fovPath, [H W], 'FOV');
end

% -------------------------------------------------------------------------
function m = read_mask(p, sz, label)
% Read a mask image, binarise it at half its maximum and check its size.
m = [];
if isempty(p)
    return;
end
if ~exist(p, 'file')
    warning('load_sample:missingMask', '%s file not found: %s', label, p);
    return;
end
a = im2double(imread(p));
if size(a, 3) > 1
    a = a(:, :, 1);
end
if ~isequal(size(a), sz)
    error('load_sample:maskSize', '%s mask is %d x %d but the image is %d x %d.', ...
          label, size(a, 1), size(a, 2), sz(1), sz(2));
end
m = a > 0.5 * max(a(:));
end

% -------------------------------------------------------------------------
function [imgPath, gtPath, fovPath] = resolve_paths(cfg)
% Use the names in cfg.paths, or auto-detect them in the data folder.
d = cfg.paths.data;
if ~exist(d, 'dir')
    error('load_sample:noData', 'Data folder not found: %s', d);
end
[names, isImg, isGt, isFov] = list_data_images(d);
if ~any(isImg) && isempty(cfg.paths.image) && isfield(cfg.paths, 'fallback_data') ...
        && exist(cfg.paths.fallback_data, 'dir')
    warning('load_sample:synthetic', ['No fundus image in %s: using the SYNTHETIC test image ' ...
            'in %s. Put your image in data/ to process it.'], d, cfg.paths.fallback_data);
    d = cfg.paths.fallback_data;
    [names, isImg, isGt, isFov] = list_data_images(d);
end

imgPath = pick(cfg.paths.image, names(isImg), d, 'fundus image');
gtPath  = pick(cfg.paths.gt,    names(isGt),  d, '');
fovPath = pick(cfg.paths.fov,   names(isFov), d, '');
end

function p = pick(given, candidates, d, required)
if strcmpi(given, 'none')                     % explicitly no file
    p = '';
elseif ~isempty(given)
    p = fullfile(d, given);
elseif ~isempty(candidates)
    p = fullfile(d, candidates{1});
    if numel(candidates) > 1
        fprintf('      note: several candidates in data/, using %s\n', candidates{1});
    end
elseif ~isempty(required)
    error('load_sample:noImage', 'No %s found in %s.', required, d);
else
    p = '';
end
end
