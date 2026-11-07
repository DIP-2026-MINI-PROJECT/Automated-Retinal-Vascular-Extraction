img = imread('cameraman.tif');
if size(img, 3) == 3
    img = rgb2gray(img);
end

img_rotated = imrotate(img, 180);

figure;
subplot(1, 2, 1); imshow(img); title('Original Image');
subplot(1, 2, 2); imshow(img_rotated); title('Rotated 180°');

img_bright = imadd(img, 50);
img_negative = imcomplement(img);

figure;
subplot(1, 3, 1); imshow(img_bright); title('Brightened (+50)');
subplot(1, 3, 2); imshow(img_negative); title('Negative Image');
subplot(1, 3, 3); imhist(img); title('Histogram of Original');

F = fft2(double(img));
F_mag = log(1 + abs(fftshift(F)));

D = dct2(img);
D_trunc = zeros(size(D));
D_trunc(1:50, 1:50) = D(1:50, 1:50);
img_dct_recon = idct2(D_trunc);

figure;
subplot(1, 2, 1); imshow(F_mag, []); title('DFT Magnitude Spectrum');
subplot(1, 2, 2); imshow(img_dct_recon, []); title('DCT Reconstruction (50x50)');

[LL, LH, HL, HH] = dwt2(double(img), 'haar');

figure;
subplot(2, 2, 1); imshow(LL, []); title('Haar LL Subband');
subplot(2, 2, 2); imshow(LH, []); title('Haar LH Subband');
subplot(2, 2, 3); imshow(HL, []); title('Haar HL Subband');
subplot(2, 2, 4); imshow(HH, []); title('Haar HH Subband');

[U, S, V] = svd(double(img));
k = 50;
img_svd = U(:, 1:k) * S(1:k, 1:k) * V(:, 1:k)';

figure;
imshow(img_svd, []); title('SVD Reconstruction (Top 50 Singular Values)');

disp('Reducing the number of singular values increases image compression by storing only a fraction of the matrices (U, S, V). However, it degrades image quality because the discarded smaller singular values contain the high-frequency details and fine textures, leading to a blurred or blocky reconstruction.');













