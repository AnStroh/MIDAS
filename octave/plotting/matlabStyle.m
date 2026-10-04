function matlabStyle(fig)
% MATLABSTYLE  Make an Octave figure look like the MATLAB version of MIDAS
% (which uses the LaTeX interpreter): serif axis labels/panel letters/legend
% text with italic variable symbols (x, t, T, P, D), light-gray grid, and
% at most ~5 tick labels per axis so small panels don't print overlapping
% numbers. Octave has no LaTeX engine here, so this uses the built-in TeX
% interpreter + a serif font instead. Safe to call repeatedly on the same
% figure (idempotent for already-converted strings).
%
% Usage:
%   matlabStyle(gcf)
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
persistent warned
serif = 'Times New Roman';
try
axs = findall(fig,'Type','axes');
for k = 1:numel(axs)
    ax = axs(k);
    for lab = [get(ax,'XLabel'), get(ax,'YLabel')]
        set(lab,'FontName',serif,'Interpreter','tex','String',italicize(get(lab,'String')))
    end
    set(get(ax,'Title'),'FontName',serif,'Interpreter','tex')
    try, set(ax,'GridColor',[0.15 0.15 0.15],'GridAlpha',0.15,'MinorGridAlpha',0.15); catch, end
    thinTicks(ax)
end
% Panel letters, legend entries, colorbar labels, any other text
tx = findall(fig,'Type','text');
for k = 1:numel(tx)
    s = get(tx(k),'String');
    set(tx(k),'FontName',serif,'Interpreter','tex')
    if ischar(s) && isempty(regexp(s,'^\([A-Z]\)$','once'))
        set(tx(k),'String',italicize(s));            % (panel letters like '(D)' stay upright)
    end
    if ischar(s) && ~isempty(regexp(s,'^\([A-Z]\)$','once'))
        set(tx(k),'FontWeight','normal')             % MATLAB's LaTeX text renders these plain, not bold
    end
end
drawnow   % fltk does not repaint after property changes on its own
catch ME
    if isempty(warned)
        warning('matlabStyle: skipped figure styling (%s)', ME.message);
        warned = true;
    end
end
end

function s = italicize(s)
% Italic variable symbols in the TeX interpreter, e.g. 'x (mm)' ->
% '\itx\rm (mm)', 'P/D_r' -> '\itP\rm/\itD\rm_r'. Only standalone x/t/T/P/D
% (not letters inside words like 'Data', not TeX commands like '\tau').
if iscell(s) || isempty(s) || ~ischar(s) || size(s,1) > 1, return, end
s = strrep(s,'\%','%');            % MATLAB's LaTeX needs '\%'; the TeX interpreter prints it literally
if ~isempty(strfind(s,'\it')), return, end
s = regexprep(s,'(?<![A-Za-z\\])([xtTPD])(?![a-z])','\\it$1\\rm');
end

function thinTicks(ax)
% Keep at most 5 tick labels per axis (every k-th tick) so small panels
% stay readable after the figure is shrunk to fit the screen.
for dim = {'X','Y'}
    d = dim{1};
    t = get(ax,[d 'Tick']);
    if numel(t) > 5
        set(ax,[d 'Tick'], t(1:ceil(numel(t)/5):end))
    end
end
end
