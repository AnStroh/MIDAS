function fitFigure(fig, w, h)
% FITFIGURE  Apply the MATLAB look (see matlabStyle.m) to a figure and scale
% its text to the window's actual size. The window itself is left alone:
% Octave opens it at its own default size/position, which is always fully
% on screen. w x h is the size the figure's font sizes were designed for
% (pixels); in a smaller window all text shrinks proportionally (floored at
% 40%) so the panels don't overlap.
%
% Safe to call after every redraw of a live-updating figure: fresh
% axes/text get rescaled each call.
%
% Usage:
%   fitFigure(gcf, 1400, 1800)
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
% Cosmetic only: any failure here must never stop a run, so everything is
% guarded and reported as a one-time warning instead of an error.
persistent warned
try
    matlabStyle(fig)                               % serif/italic labels, light grid, sparse ticks (MATLAB look)
    p = get(fig,'position');                       % actual window size (pixels)
    s = min([1, p(3)/w, p(4)/h]);
    if s < 1
        fs = max(s,0.4);
        % Setting an axes' FontSize also resizes its label/title children, so
        % read every size first, then write axes before text (each text gets
        % exactly original*fs, never scaled twice).
        hT   = findall(fig,'-property','FontSize');
        orig = cell2mat(arrayfun(@(h) get(h,'FontSize'), hT(:), 'UniformOutput', false));
        isAx = arrayfun(@(h) strcmp(get(h,'Type'),'axes'), hT(:));
        for k = [find(isAx); find(~isAx)]'
            set(hT(k),'FontSize',max(4,orig(k)*fs))
        end
    end
    drawnow   % fltk does not repaint after property changes on its own
catch ME
    if isempty(warned)
        warning('fitFigure: skipped figure styling (%s)', ME.message);
        warned = true;
    end
end
end
