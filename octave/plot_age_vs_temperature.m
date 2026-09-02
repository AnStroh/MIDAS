function fig = plot_age_vs_temperature(R, nDiv)
% PLOT_AGE_VS_TEMPERATURE  Closure-temperature diagnostic: apparent age vs.
% temperature (instead of vs. time, cf. plot_age_at_fixed_positions.m),
% tracked at the same nDiv+1 fixed positions spanning [0, min(S)] - the
% smallest crystal size reached at any point in the run.
%
% As the system cools, diffusion slows and each position's apparent age
% eventually stops changing (the curve flattens) - the temperature where
% that happens is this system's approximate closure temperature at that
% position. If the P-T path has a prograde leg too, the curve can show a
% loop (different T on heating vs. cooling for the same apparent age) -
% that's real path history, not a plotting artifact.
%
% Usage:
%   R = MIDAS_Main(params);        % params.store_history must be 1
%   plot_age_vs_temperature(R)         % default: every 10th of min(S)
%   plot_age_vs_temperature(R,20)      % every 20th instead
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
if ~isfield(R,'Srec')
    error('plot_age_vs_temperature requires history (params.store_history = 1)')
end
if nargin < 2 || isempty(nDiv)
    nDiv = 10;
end
FSS   = R.params.FSS;
LWW   = R.params.LWW;
Trec  = R.Trec-273;   % K -> deg C
Srec  = R.Srec;
xArec = R.xArec;
tA1   = R.tA1;

Smin     = min(Srec);
fixedPos = linspace(0,Smin,nDiv+1);   % 0, Smin/nDiv, ..., Smin

nT       = numel(Trec);
ageAtPos = nan(nT,numel(fixedPos));
for it = 1:nT
    ageAtPos(it,:) = interp1(xArec(it,:),tA1(it,:),fixedPos,'pchip');
end

fig  = figure('Color',[1 1 1],'Units','pixels','Position',[100 100 950 650]);
cmap = viridis(numel(fixedPos));   % NOT parula: doesn't exist in Octave ("not yet implemented"); viridis is Octave's own closest perceptually-uniform equivalent
hold on
for k = 1:numel(fixedPos)
    plot(Trec,ageAtPos(:,k),'-','LineWidth',LWW*1.5,'Color',cmap(k,:), ...
        'DisplayName',sprintf('x=%.4g mm',fixedPos(k)))
end
hold off
grid on, axis square
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
xlabel('T (^oC)','FontSize',FSS)
ylabel('\tau (Myr)','FontSize',FSS)
%title(sprintf('\\tau vs. temperature (\\min S = %.4g mm)',Smin),'FontSize',FSS)
title(sprintf('\\tau vs. T',Smin),'FontSize',FSS)
legend('Location','eastoutside')
xlim([0.995*min(Trec) 1.005*max(Trec)])
%text(0.03,0.97,'(A)','Units','normalized','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)
end
