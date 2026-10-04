function plotAB(xA,xB,CA,CB,CA0,CB0,t,t_tot,FSS,LWW,v,yMax)
% PLOTAB  Composition profile, phase A (crystal) vs. phase B (matrix),
% against distance - the shared building block behind every element/isotope
% panel in the main tiled figure (plot_them_1/2/3.m) and in
% plot_all_composition_profiles.m. Caller supplies the axis labels/title;
% this only draws the two curves + interface marker.
%
% Usage:
%   plotAB(xA,xB,CA,CB,CA0,CB0,t,t_tot,FSS,LWW,v,yMax)
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
blueA = [0, 0.4470, 0.7410];   % Same default blue used for the apparent-age curve (panel F)
plot(xA,CA,'Color',blueA,'linewidth',LWW*1.5)
hold on
plot(xB,CB,'k','linewidth',LWW*1.5)
xlim([0,max(xB)])
ylim([0,yMax])
plot(xA(end)*[1 1],ylim,'--','Color',[0.7 0.7 0.7],'linewidth',LWW)   % interface marker (plot() instead of xline: absent in older Octave); after ylim so it spans the final range
hold off
grid on,axis square
xlabel(['x', ' (mm)'],'FontSize',FSS)
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
end
