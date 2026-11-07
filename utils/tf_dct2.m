function C = tf_dct2(X, inverse)
% TF_DCT2  2-D orthonormal DCT-II (or its inverse) with a fallback.
%
%   C = tf_dct2(X)          forward, same as dct2(X)
%   X = tf_dct2(C, true)    inverse, same as idct2(C)
%
%   Purpose : Uses dct2/idct2 (Image Processing Toolbox) when available.
%             Otherwise builds the orthonormal DCT matrix D and computes
%             D_M * X * D_N' (forward) or D_M' * C * D_N (inverse).
%   Inputs  : X       - 2-D double array
%             inverse - (optional) true for the inverse transform
%   Outputs : C       - transformed array, same size
if nargin < 2, inverse = false; end
if ~inverse && exist('dct2', 'file')
    C = dct2(X);  return;
elseif inverse && exist('idct2', 'file')
    C = idct2(X); return;
end
[M, N] = size(X);
DM = dct_matrix(M);
DN = dct_matrix(N);
if inverse
    C = DM' * X * DN;
else
    C = DM * X * DN';
end
end

function D = dct_matrix(n)
% Orthonormal DCT-II matrix: D(k+1, i+1) = a(k) cos(pi (2i+1) k / 2n)
[i, k] = meshgrid(0:n - 1, 0:n - 1);
D = sqrt(2 / n) * cos(pi * (2 * i + 1) .* k / (2 * n));
D(1, :) = D(1, :) / sqrt(2);
end
