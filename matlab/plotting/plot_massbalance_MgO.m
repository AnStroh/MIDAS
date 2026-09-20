function fig = plot_massbalance_MgO(R)
% PLOT_MASSBALANCE_MGO  Mass-balance drift for MgO only, (M(t)-M(0))/M(0)
% vs. time - a numerical-integrity check (MgO has no physical source or
% sink in this model, so a correct scheme should hold it ~constant).
%
% Usage:
%   R = MIDAS_Main(params);   % params.store_history must be 1
%   plot_massbalance_MgO(R)
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
if ~isfield(R,'dMB')
    error('plot_massbalance_MgO requires history (params.store_history = 1)')
end
FSS = R.params.FSS;
LWW = R.params.LWW;

fig = figure('Color',[1 1 1]);
plot(R.trec,R.dMB*100,'Color',[0, 0.4470, 0.7410],'LineWidth',LWW*1.5)
hold on
yline(0,'Color',[0.7 0.7 0.7])
hold off
grid on, axis square
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
xlabel('t (Myr)','interpreter','latex','FontSize',FSS)
ylabel('$(M(t)-M(0))/M(0)$ (\%)','interpreter','latex','FontSize',FSS)
title('Mass-balance drift, MgO','interpreter','latex','FontSize',FSS)
end
