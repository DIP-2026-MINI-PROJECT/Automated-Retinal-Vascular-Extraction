clc;
clear;
clear all;

I = imread(['coins.png']);
I = imnoise (I, 'salt & pepper',0.02);
filtered_image = medfilt2(I,[3,3]);

subplot(1,2,1);
imshow(I);title('Noisy Image');

subplot(1,2,2);
imshow(filtered_image);
title('Filtered Image');

img =im2double(im2gray(imread()))

