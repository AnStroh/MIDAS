function plot_Lu_profile(R)
% PLOT_LU_PROFILE  Distance vs. Lu concentration in phase A (crystal),
% final state - a clean, unobstructed view of just the garnet's own Lu
% profile (companion to panel D of the main tiled figure, which shares its
% y-axis with phase B and can be harder to read for phase A alone).
%
% Usage:
%   R = MIDAS_Main(params);
%   plot_Lu_profile(R)
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
FSS = R.params.FSS;
LWW = R.params.LWW;

figure('Color',[1 1 1]);
plot(R.xA_final,R.CALu_final,'Color',[0, 0.4470, 0.7410],'LineWidth',LWW*1.5)
grid on, axis square
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
xlabel('$x$ (mm)','interpreter','latex','FontSize',FSS)
ylabel('$^{176}$Lu (ppm)','interpreter','latex','FontSize',FSS)
title('$^{176}$Lu profile, Phase $A$','interpreter','latex','FontSize',FSS)
ylim([0.95*min(R.CALu_final) 1.05*max(R.CALu_final)])
end
