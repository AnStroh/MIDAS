function plot_Mn_profile(R)
% PLOT_MN_PROFILE  Distance vs. Mn concentration in phase A (crystal),
% final state - a clean, unobstructed view of just the garnet's own Mn
% profile (companion to panel D of the main tiled figure, which shares its
% y-axis with phase B and can be harder to read for phase A alone).
%
% Usage:
%   R = MIDAS_Main(params);
%   plot_Mn_profile(R)
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
FSS = R.params.FSS;
LWW = R.params.LWW;

figure('Color',[1 1 1]);
plot(R.xA_final,R.CAMn_final,'Color',[0, 0.4470, 0.7410],'LineWidth',LWW*1.5)
grid on, axis square
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
xlabel('$x$ (mm)','interpreter','latex','FontSize',FSS)
ylabel('MnO (wt.\%)','interpreter','latex','FontSize',FSS)
title('MnO profile, Phase $A$','interpreter','latex','FontSize',FSS)
ylim([0.95*min(R.CAMn_final) 1.05*max(R.CAMn_final)])
end
