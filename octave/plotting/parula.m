function map = parula(n)
% PARULA  Approximation of MATLAB's default "parula" colormap (Octave does
% not ship one), so the Octave figures use the same blue -> green -> yellow
% look as the MATLAB version. Linear interpolation between 8 anchor colors
% sampled from MATLAB's parula; n rows (default 64).
%
% Usage:
%   colormap(gca, parula(256))
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
if nargin < 1, n = 64; end
anchors = [0.2422 0.1504 0.6603
           0.2810 0.3228 0.9579
           0.1786 0.5289 0.9682
           0.0689 0.6948 0.8394
           0.2161 0.7843 0.5923
           0.6720 0.7793 0.2227
           0.9970 0.7659 0.2199
           0.9769 0.9839 0.0805];
xi  = linspace(0,1,size(anchors,1));
map = interp1(xi, anchors, linspace(0,1,n), 'linear');
end
