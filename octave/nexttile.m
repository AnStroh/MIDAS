function varargout = nexttile(varargin)
% NEXTTILE  Minimal Octave-only shim for MATLAB's nexttile; pairs with
% tiledlayout.m (same folder) - see that file for why this exists.
%
% Supports both call styles used across this repo's plotting scripts:
%   nexttile      - advance to the next tile in reading order
%   nexttile(n)   - jump to tile n explicitly
% Any further MATLAB-only arguments are accepted and ignored.
%
% Like MATLAB's own nexttile, the axes handle is only returned (assigned to
% varargout) when the caller actually requests it - most calls in this repo
% are bare (e.g. "nexttile(1)" with no semicolon), and unconditionally
% returning a value would otherwise echo "ans = ..." to the console on
% every one of them.
%
% Usage:
%   nexttile
%   nexttile(n)
%   ax = nexttile(...)
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
    rows = getappdata(gcf, 'tl_rows');
    cols = getappdata(gcf, 'tl_cols');
    if isempty(rows) || isempty(cols)
        error('nexttile: call tiledlayout(rows,cols) first');
    end
    if nargin >= 1 && isnumeric(varargin{1})
        idx = varargin{1};
    else
        idx = getappdata(gcf, 'tl_idx') + 1;
    end
    setappdata(gcf, 'tl_idx', idx);
    ax_ = subplot(rows, cols, idx);
    if nargout > 0
        varargout{1} = ax_;
    end
end
