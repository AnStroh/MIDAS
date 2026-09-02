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
%                                              % -> Fig_apparent_age_notitle.pdf/.png
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
set(fig,'Color',[1 1 1])
addSoftwareStamp(fig)
exportgraphics(fig,[filename,'.pdf'],'ContentType','vector','Resolution',300)
exportgraphics(fig,[filename,'.png'],'Resolution',300)

titles = hideTitles(fig);
exportgraphics(fig,[filename,'_notitle.pdf'],'ContentType','vector','Resolution',300)
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
