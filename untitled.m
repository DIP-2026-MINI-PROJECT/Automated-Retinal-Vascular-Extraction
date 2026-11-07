% Read the input image
I = imread("C:\Users\Samarth\Downloads\Lena.jpg");
I = im2gray(I);

% Define the size of the box filter (e.g., 3x3 or 5x5)
filter_size = 9;

% Create the average filter manually
average_filter = ones(filter_size, filter_size) / (filter_size^2);

I_filtered = imfilter(I, average_filter, 'replicate');

% Display the original and filtered images
figure;
subplot(1, 2, 1);
imshow(I); title('Original Image');
subplot(1, 2, 2);
imshow(I_filtered); title('Filtered Image with Average Filter');