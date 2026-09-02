function fig = plot_initial_conditions(R)
% PLOT_INITIAL_CONDITIONS  Every tracked element/isotope's initial (t=0)
% composition profile, phase A (crystal) in the left column and phase B
% (matrix) in the right column, one row per element: MgO, MnO, Lu, Hf (top
% to bottom). Same layout as plot_all_composition_profiles.m (final state)
% - the two are meant to be read as a before/after pair, e.g. for a
% publication's setup figure.
%
% Usage:
%   R = MIDAS_Main(params);
%   plot_initial_conditions(R)
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
FSS = R.params.FSS;
LWW = R.params.LWW;
blueA = [0, 0.4470, 0.7410];
blackB = [0 0 0];

rows = {
    'MgO',  R.CA_initial,   R.CB_initial,   'MgO (wt.\%)'
    'MnO',  R.CAMn_initial, R.CBMn_initial, 'MnO (wt.\%)'
    'Lu',   R.CALu_initial, R.CBLu_initial, '^{176}Lu (ppm)'
    'Hf',   R.CAHf_initial, R.CBHf_initial, '^{176}Hf (ppm)'
};
letters = {'A','B','C','D','E','F','G','H'};

fig = figure('Color',[1 1 1],'Units','pixels','Position',[100 100 900 1600]);
tiledlayout(size(rows,1),2,'TileSpacing','compact','Padding','compact')
% sgtitle doesn't exist in Octave at all ("undefined") - fall back to an
% annotation spanning the top of the figure, which looks close enough and
% needs no layout information beyond the figure itself.
if exist('sgtitle','file') || exist('sgtitle','builtin')
    sgtitle('Initial conditions (t=0)','FontSize',FSS*1.2)
else
    annotation(fig,'textbox',[0 0.96 1 0.04],'String','Initial conditions (t=0)', ...
        'FontSize',FSS*1.2,'EdgeColor','none','HorizontalAlignment','center','FitBoxToText','off')
end

li = 0;
for k = 1:size(rows,1)
    [name, CA, CB, ylab] = rows{k,:};

    li = li+1;
    nexttile
    plot(R.xA_initial,CA,'Color',blueA,'LineWidth',LWW*1.5)
    grid on, axis square
    set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
    xlabel('x (mm)','FontSize',FSS)
    ylabel(ylab,'FontSize',FSS)
    title([name ', Phase A'],'FontSize',FSS)
    ylim([0.95*min(CA) 1.05*max(CA)+eps])
    xlim([0 1.05*R.xA_initial(end)])
    [tx,ty,ha,va] = panelLabelPos(letters{li});
    text(tx,ty,['(' letters{li} ')'],'Units','normalized','HorizontalAlignment',ha,'FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment',va,'BackgroundColor',[1 1 1],'Margin',1)

    li = li+1;
    nexttile
    plot(R.xB_initial,CB,'Color',blackB,'LineWidth',LWW*1.5)
    grid on, axis square
    set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
    xlabel('x (mm)','FontSize',FSS)
    ylabel(ylab,'FontSize',FSS)
    title([name ', Phase B'],'FontSize',FSS)
    ylim([0.95*min(CB) 1.05*max(CB)+eps])
    [tx,ty,ha,va] = panelLabelPos(letters{li});
    text(tx,ty,['(' letters{li} ')'],'Units','normalized','HorizontalAlignment',ha,'FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment',va,'BackgroundColor',[1 1 1],'Margin',1)
end
end
function [tx,ty,ha,va] = panelLabelPos(letter)
% Same convention as plot_all_composition_profiles.m's panelLabelPos.
switch letter
    case {'F','H'}
        tx = 0.95; ty = 0.95; ha = 'right'; va = 'top';
    case 'G'
        tx = 0.05; ty = 0.05; ha = 'left';  va = 'bottom';
    otherwise
        tx = 0.05; ty = 0.95; ha = 'left';  va = 'top';
end
end
