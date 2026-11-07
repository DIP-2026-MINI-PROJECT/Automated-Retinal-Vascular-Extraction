function [names, isImg, isGt, isFov] = list_data_images(d)
% LIST_DATA_IMAGES  List image files in a folder and classify them.
%
%   [names, isImg, isGt, isFov] = list_data_images(d)
%
%   Purpose : Find every image file in d and tell fundus images, ground-
%             truth vessel masks and FOV masks apart by name:
%               ground truth : name contains manual, _gt, gt_, vessel, label
%               FOV mask     : name contains mask or fov (and is not gt)
%               fundus image : everything else
%   Inputs  : d - folder path
%   Outputs : names - 1 x n cellstr of file names (sorted)
%             isImg, isGt, isFov - 1 x n logical vectors
exts = {'.tif', '.tiff', '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.ppm'};
files = dir(d);
names = sort({files(~[files.isdir]).name});
[~, ~, e] = cellfun(@fileparts, names, 'UniformOutput', false);
names = names(ismember(lower(e), exts));
low = lower(names);
isGt  = ~cellfun(@isempty, regexp(low, 'manual|_gt|gt_|vessel|label', 'once'));
isFov = ~isGt & ~cellfun(@isempty, regexp(low, 'mask|fov', 'once'));
isImg = ~isGt & ~isFov;
end
