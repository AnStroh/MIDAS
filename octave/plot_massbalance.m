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
xlZero = xlim; plot(xlZero,[0 0],'Color',[0.7 0.7 0.7],'HandleVisibility','off'); xlim(xlZero);   % NOT yline(...,'HandleVisibility','off'): crashes legend() under Octave/fltk when combined (confirmed - see CHANGELOG.md)
hold off
grid on, axis square
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
xlabel('t (Myr)','FontSize',FSS)
%ylabel('(M(t)-M(0))/M(0) (\%)','FontSize',FSS)
ylabel('Normalized mass misfit (\%)','FontSize',FSS)
title('Mass-balance drift vs. t','FontSize',FSS)
legend('Location','northeast')   % NOT 'best': crashes outright under Octave/fltk (confirmed - see CHANGELOG.md)
end
