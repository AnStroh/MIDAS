function plot_misfit(R)
% PLOT_MISFIT  Apparent-age and isochron-age misfit vs. time for phase A
% (crystal): misfit = max(abs(age - t)), the largest deviation between an
% age estimate and the true elapsed model time t, evaluated at every
% recorded step.
%   - Apparent-age misfit:  max(abs(tALuHf1(x) - t)) over the crystal profile
%   - Isochron-age misfit:  max(abs([rim,core,bulk,max] - t)) over the four
%                            isochron reference ages
%
% Usage:
%   R = MIDAS_Main(params);   % params.store_history must be 1
%   plot_misfit(R)
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
if ~isfield(R,'misfitApparentH')
    error('plot_misfit requires history (params.store_history = 1)')
end
FSS = R.params.FSS;
LWW = R.params.LWW;

figure('Color',[1 1 1]);
plot(R.trec,R.misfitApparentH,'-','LineWidth',LWW*1.5,'DisplayName','$\max|\tau-t|$'), hold on
plot(R.trec,R.misfitIsochronH,'--','LineWidth',LWW*1.5,'DisplayName',sprintf('$\\max|\\tau_{iso}-t|$ (ref: %s)',R.params.isoRefMode))
hold off
grid on, axis square
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
xlabel('t (Myr)','interpreter','latex','FontSize',FSS)
ylabel('$\max|\tau-t|$ (Myr)','interpreter','latex','FontSize',FSS)
title('Worst-case age misfit (anywhere in the profile)','interpreter','latex','FontSize',FSS)
legend('Location','best','interpreter','latex')
end
