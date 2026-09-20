function export_pub_fig(fig, filename)
% EXPORT_PUB_FIG  Save a figure as a publication-ready vector PDF (any
% rasterized content within it, e.g. contourf/pcolor fills, at 300 dpi),
% plus a lossless 300 dpi PNG for quick previewing/embedding. Saved twice: once
% as-is (filename.pdf/.png) and once with every axes/sgtitle title blanked
% out (filename_notitle.pdf/.png) - the manuscript typically supplies its
% own caption, so the no-title version is the one that actually goes in.
%
% Usage:
%   export_pub_fig(gcf, 'Fig_apparent_age')   % -> Fig_apparent_age.pdf/.png
%                                             % -> Fig_apparent_age_notitle.pdf/.png
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
set(fig,'Color',[1 1 1])
addSoftwareStamp(fig)
safeExportGraphics(fig,[filename,'.pdf'],'ContentType','vector','Resolution',300)
safeExportGraphics(fig,[filename,'.png'],'Resolution',300)

titles = hideTitles(fig);
safeExportGraphics(fig,[filename,'_notitle.pdf'],'ContentType','vector','Resolution',300)
safeExportGraphics(fig,[filename,'_notitle.png'],'Resolution',300)
restoreTitles(titles)
end

function safeExportGraphics(varargin)
% Retries exportgraphics up to 3 times (0.3 s apart) before giving up.
% Works around an intermittent "Cannot create output file" error seen
% writing the 3rd/4th file (the _notitle variants) of a batch right after
% the previous one - consistent with a cloud-sync client (OneDrive, etc.)
% briefly locking the just-written file while it uploads, on a folder
% under a synced path. Not figure- or content-specific: reproduced on
% otherwise-unrelated figures, always at the same point in the sequence.
for attempt = 1:3
    try
        exportgraphics(varargin{:});
        return
    catch ME
        if attempt == 3
            rethrow(ME)
        end
        pause(0.3)
    end
end
end

function titles = hideTitles(fig)
% Blanks every axes title and sgtitle in fig, returning the handles/strings
% needed to put them back afterwards.
axTitles = arrayfun(@(ax) ax.Title, findall(fig,'Type','axes'));
sgTitles = findall(fig,'-isa','matlab.graphics.illustration.subplot.SubplotText');
handles  = [axTitles(:); sgTitles(:)];
strings  = get(handles,'String');
if ~iscell(strings), strings = {strings}; end
set(handles,'String','')
titles = struct('handles',{handles},'strings',{strings});
end

function restoreTitles(titles)
for i = 1:numel(titles.handles)
    titles.handles(i).String = titles.strings{i};
end
end
