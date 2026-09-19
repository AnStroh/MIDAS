function export_pub_fig(fig, filename)
% EXPORT_PUB_FIG  Save a figure as a publication-ready vector PDF (any
% rasterized content within it, e.g. contourf/pcolor fills, at 300 dpi),
% plus a lossless 300 dpi PNG for quick previewing/embedding. Saved twice: once
% as-is (filename.pdf/.png) and once with every axes/sgtitle title blanked
% out (filename_notitle.pdf/.png) - the manuscript typically supplies its
% own caption, so the no-title version is the one that actually goes in.
%
% Octave port: tries exportgraphics first (supported in modern Octave);
% falls back to the older, universally-supported print() if that fails.
%
% Usage:
%   export_pub_fig(gcf, 'Fig_apparent_age')   % -> Fig_apparent_age.pdf/.png
%                                              % -> Fig_apparent_age_notitle.pdf/.png
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
set(fig,'Color',[1 1 1])
addSoftwareStamp(fig)

saveBoth(fig,[filename,'.pdf'],[filename,'.png'])

titles = hideTitles(fig);
saveBoth(fig,[filename,'_notitle.pdf'],[filename,'_notitle.png'])
restoreTitles(titles)
end

function saveBoth(fig,pdfFile,pngFile)
% Retries exportgraphics up to 3 times (0.3 s apart) before falling back
% to print() - works around an intermittent "Cannot create output file"
% error seen on a cloud-synced folder (OneDrive, etc.) briefly locking the
% previous file while it uploads, not specific to any one figure.
for attempt = 1:3
    try
        exportgraphics(fig,pdfFile,'ContentType','vector','Resolution',300)
        exportgraphics(fig,pngFile,'Resolution',300)
        return
    catch
        if attempt < 3
            pause(0.3)
        end
    end
end
print(fig,pdfFile,'-dpdf','-r300')
print(fig,pngFile,'-dpng','-r300')
end

function titles = hideTitles(fig)
% Blanks every axes title and sgtitle in fig, returning the handles/strings
% needed to put them back afterwards.
axTitles = arrayfun(@(ax) get(ax,'Title'), findall(fig,'Type','axes'));
sgTitles = [];
try
    sgTitles = findall(fig,'-isa','matlab.graphics.illustration.subplot.SubplotText');
catch
    % sgtitle's underlying class is MATLAB-specific and isn't guaranteed to
    % exist under Octave - skip it; axes titles (handled above, and the only
    % kind any current figure in this repo actually uses) are unaffected.
end
handles  = [axTitles(:); sgTitles(:)];
strings  = get(handles,'String');
if ~iscell(strings), strings = {strings}; end
set(handles,'String','')
titles = struct('handles',{handles},'strings',{strings});
end

function restoreTitles(titles)
for i = 1:numel(titles.handles)
    set(titles.handles(i),'String',titles.strings{i});
end
end
