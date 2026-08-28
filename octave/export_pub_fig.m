function export_pub_fig(fig, filename)
% EXPORT_PUB_FIG  Save a figure as a publication-ready vector PDF, plus a
% lossless 300 dpi PNG for quick previewing/embedding. Saved twice: once
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
try
    exportgraphics(fig,pdfFile,'ContentType','vector')
    exportgraphics(fig,pngFile,'Resolution',300)
catch
    print(fig,pdfFile,'-dpdf')
    print(fig,pngFile,'-dpng','-r300')
end
end

function titles = hideTitles(fig)
% Blanks every axes title and sgtitle in fig, returning the handles/strings
% needed to put them back afterwards.
axTitles = arrayfun(@(ax) ax.Title, findall(fig,'Type','axes'));
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
    titles.handles(i).String = titles.strings{i};
end
end

function addSoftwareStamp(fig)
% Small, unobtrusive attribution in the bottom-right margin so a figure
% pulled out of a paper/slide later can still be traced back to the
% software that made it. Tagged so re-exporting the same figure (e.g.
% Export Figures clicked twice) doesn't stack duplicate stamps.
% Wrapped in try/catch: annotation() property support varies across
% Octave versions, and a missing stamp is a cosmetic issue, not worth
% failing the whole figure export over.
try
    if ~isempty(findall(fig, 'Tag', 'MIDAS_software_stamp'))
        return
    end
    annotation(fig, 'textbox', [0.5 0.003 0.48 0.03], ...
        'String', 'MIDAS - Stroh & Moulas (2026)', ...
        'Tag', 'MIDAS_software_stamp', ...
        'EdgeColor', 'none', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
        'FontSize', 7, 'Color', [0.55 0.55 0.55], 'FitBoxToText', 'off');
catch
    % Cosmetic only - skip silently if this Octave version's annotation()
    % doesn't support one of the properties above.
end
end
