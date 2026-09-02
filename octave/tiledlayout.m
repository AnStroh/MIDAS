function tiledlayout(rows, cols, varargin)
% TILEDLAYOUT  Minimal Octave-only shim for MATLAB's tiledlayout.
%
% Octave (checked: 11.3.0) has no tiledlayout/nexttile at all, unlike
% MATLAB. This sets up a rows-by-cols subplot grid on the current figure;
% nexttile() (see nexttile.m, same folder) advances through it exactly like
% MATLAB's version. Only grid size is implemented - trailing name-value
% options such as 'TileSpacing'/'Padding' (MATLAB-only, purely cosmetic
% spacing) are accepted here and silently ignored.
%
% Usage:
%   tiledlayout(rows,cols)
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
    % MATLAB's tiledlayout wholesale-replaces any existing layout on the
    % figure with a fresh, empty one every time it's called. Octave's
    % subplot() (which nexttile.m uses) instead reuses the existing axes
    % at a given grid position across calls, silently carrying over all of
    % its prior content/hold state/legend - across repeated frames of a
    % live-updating plot, that accumulates lines and legend entries
    % instead of replacing them. Deleting old axes here first restores the
    % MATLAB behavior.
    delete(findall(gcf, 'type', 'axes'));
    setappdata(gcf, 'tl_rows', rows);
    setappdata(gcf, 'tl_cols', cols);
    setappdata(gcf, 'tl_idx', 0);
end
