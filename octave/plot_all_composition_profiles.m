function fig = plot_all_composition_profiles(R)
% PLOT_ALL_COMPOSITION_PROFILES  Every tracked element/isotope's final-state
% composition profile, phase A (crystal, e.g. Grt) in the left column and
% phase B (matrix, e.g. Bt) in the right column, one row per element:
% MgO, MnO, Lu, Hf (top to bottom) - a single-figure summary of everything
% plot_them_3.m's panels C-F show split across two phases, without the two
% phases sharing a y-axis.
%
% Usage:
%   R = MIDAS_Main(params);
%   plot_all_composition_profiles(R)
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
FSS = R.params.FSS;
LWW = R.params.LWW;
blueA = [0, 0.4470, 0.7410];
blackB = [0 0 0];

rows = {
    'MgO',  R.CA_final,   R.CB_final,   'MgO (wt.\%)'
    'MnO',  R.CAMn_final, R.CBMn_final, 'MnO (wt.\%)'
    'Lu',   R.CALu_final, R.CBLu_final, '$^{176}$Lu (ppm)'
    'Hf',   R.CAHf_final, R.CBHf_final, '$^{176}$Hf (ppm)'
};
letters = {'A','B','C','D','E','F','G','H'};

fig = figure('Color',[1 1 1],'Units','pixels','Position',[100 100 900 1600]);
tiledlayout(size(rows,1),2,'TileSpacing','compact','Padding','compact')

li = 0;
for k = 1:size(rows,1)
    [name, CA, CB, ylab] = rows{k,:};

    li = li+1;
    nexttile
    plot(R.xA_final,CA,'Color',blueA,'LineWidth',LWW*1.5)
    grid on, axis square
    set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
    xlabel('$x$ (mm)','interpreter','latex','FontSize',FSS)
    ylabel(ylab,'interpreter','latex','FontSize',FSS)
    title([name ', Phase $A$'],'interpreter','latex','FontSize',FSS)
    ylim([0.95*min(CA) 1.05*max(CA)])
    [tx,ty,ha,va] = panelLabelPos(letters{li});
    text(tx,ty,['(' letters{li} ')'],'Units','normalized','HorizontalAlignment',ha,'FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment',va,'interpreter','latex','BackgroundColor',[1 1 1],'Margin',1)

    li = li+1;
    nexttile
    plot(R.xB_final,CB,'Color',blackB,'LineWidth',LWW*1.5)
    grid on, axis square
    set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
    xlabel('$x$ (mm)','interpreter','latex','FontSize',FSS)
    ylabel(ylab,'interpreter','latex','FontSize',FSS)
    title([name ', Phase $B$'],'interpreter','latex','FontSize',FSS)
    ylim([0.95*min(CB) 1.05*max(CB)])
    [tx,ty,ha,va] = panelLabelPos(letters{li});
    text(tx,ty,['(' letters{li} ')'],'Units','normalized','HorizontalAlignment',ha,'FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment',va,'interpreter','latex','BackgroundColor',[1 1 1],'Margin',1)
end
end
function [tx,ty,ha,va] = panelLabelPos(letter)
% Default label position is the upper-left corner; a few panels' curves
% sit there instead (see plot_all_composition_profiles.m), so those get
% an explicit override.
switch letter
    case {'F','H'}
        tx = 0.95; ty = 0.95; ha = 'right'; va = 'top';
    case 'G'
        tx = 0.05; ty = 0.05; ha = 'left';  va = 'bottom';
    otherwise
        tx = 0.05; ty = 0.95; ha = 'left';  va = 'top';
end
end
