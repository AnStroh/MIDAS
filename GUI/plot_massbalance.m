function plot_massbalance(R)
% PLOT_MASSBALANCE  Mass-balance drift vs. time, a numerical-integrity
% check: (M(t)-M(0))/M(0) for the species that have no physical source or
% sink in this model (diffusion + partitioning only), so a correct scheme
% should hold them ~constant. Lu and Hf are excluded: their totals are
% expected to change (radioactive decay/ingrowth), so drift from t=0 is not
% a numerical error for them.
%
% Usage:
%   R = MIDAS_Main(params);   % params.store_history must be 1
%   plot_massbalance(R)
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
if ~isfield(R,'dMB')
    error('plot_massbalance requires history (params.store_history = 1)')
end
FSS = R.params.FSS;
LWW = R.params.LWW;

figure('Color',[1 1 1]);
plot(R.trec,R.dMB*100,   '-', 'LineWidth',LWW*1.5,'DisplayName','MgO'), hold on
plot(R.trec,R.dMBMn*100, '--','LineWidth',LWW*1.5,'DisplayName','Mn')
plot(R.trec,R.dMBHfr*100,':', 'LineWidth',LWW*1.5,'DisplayName','Hf (ref)')
yline(0,'Color',[0.7 0.7 0.7],'HandleVisibility','off')
hold off
grid on, axis square
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
xlabel('t (Myr)','interpreter','latex','FontSize',FSS)
%ylabel('$(M(t)-M(0))/M(0)$ (\%)','interpreter','latex','FontSize',FSS)
ylabel('Normalized mass misfit (\%)','interpreter','latex','FontSize',FSS)
title('Mass-balance drift vs. $t$','interpreter','latex','FontSize',FSS)
legend('Location','best','interpreter','latex')
end
