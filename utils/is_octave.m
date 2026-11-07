function tf = is_octave()
% IS_OCTAVE  True when running in GNU Octave instead of MATLAB.
%
%   Purpose : Lets the code pick a fallback for functions that only exist
%             in MATLAB (adapthisteq, bwskel, exportgraphics, ...).
%   Inputs  : none
%   Outputs : tf - logical
tf = exist('OCTAVE_VERSION', 'builtin') > 0;
end
