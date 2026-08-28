function export_pub_fig(fig, filename)
% EXPORT_PUB_FIG  Save a figure as a publication-ready vector PDF, plus a
% lossless 300 dpi PNG for quick previewing/embedding. Saved twice: once
% as-is (filename.pdf/.png) and once with every axes/sgtitle title blanked
% out (filename_notitle.pdf/.png) - the manuscript typically supplies its
% own caption, so the no-title version is the one that actually goes in.
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
exportgraphics(fig,[filename,'.pdf'],'ContentType','vector')
exportgraphics(fig,[filename,'.png'],'Resolution',300)

titles = hideTitles(fig);
exportgraphics(fig,[filename,'_notitle.pdf'],'ContentType','vector')
exportgraphics(fig,[filename,'_notitle.png'],'Resolution',300)
restoreTitles(titles)
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

function addSoftwareStamp(fig)
% Small, unobtrusive attribution in the bottom-right margin so a figure
% pulled out of a paper/slide later can still be traced back to the
% software that made it. Tagged so re-exporting the same figure (e.g.
% Export Figures clicked twice) doesn't stack duplicate stamps.
if ~isempty(findall(fig, 'Tag', 'MIDAS_software_stamp'))
    return
end
annotation(fig, 'textbox', [0.5 0.003 0.48 0.03], ...
    'String', 'MIDAS - Stroh & Moulas (2026)', ...
    'Tag', 'MIDAS_software_stamp', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
    'FontSize', 7, 'Color', [0.55 0.55 0.55], 'FitBoxToText', 'off');
end
