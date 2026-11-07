function c = crop_roi(img, roi)
% CROP_ROI  Cut the zoom window [row col height width] out of an image.
%
%   Inputs  : img - 2-D or RGB image;  roi - [row col height width]
%   Outputs : c   - cropped image
c = img(roi(1):roi(1) + roi(3) - 1, roi(2):roi(2) + roi(4) - 1, :);
end
