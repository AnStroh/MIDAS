function fig = plot_age_at_fixed_positions(R, nDiv)
% PLOT_AGE_AT_FIXED_POSITIONS  Apparent age vs. time, tracked at nDiv+1
% fixed positions spanning [0, min(S)] - the SMALLEST crystal size reached
% at any point in the run (i.e. after any resorption). Using min(S) instead
% of the current/final size means every tracked position is guaranteed to
% have existed inside the crystal at every single recorded time - no gaps
% to interpolate over or mask out, unlike tracking positions up to the
% largest/final size (cf. plot_velocity_age.m's fixedLengths, which needs
% NaN-masking for exactly this reason).
%
% Usage:
%   R = MIDAS_Main(params);              % params.store_history must be 1
%   plot_age_at_fixed_positions(R)       % default: every 10th of min(S)
%   plot_age_at_fixed_positions(R,20)    % every 20th instead
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
if ~isfield(R,'Srec')
    error('plot_age_at_fixed_positions requires history (params.store_history = 1)')
end
if nargin < 2 || isempty(nDiv)
    nDiv = 10;
end
FSS   = R.params.FSS;
LWW   = R.params.LWW;
trec  = R.trec;
Srec  = R.Srec;
xArec = R.xArec;
tA1   = R.tA1;

Smin     = min(Srec);
fixedPos = linspace(0,Smin,nDiv+1);   % 0, Smin/nDiv, ..., Smin

nT       = numel(trec);
ageAtPos = nan(nT,numel(fixedPos));
for it = 1:nT
    ageAtPos(it,:) = interp1(xArec(it,:),tA1(it,:),fixedPos,'pchip');
end

fig  = figure('Color',[1 1 1],'Units','pixels','Position',[100 100 950 650]);
cmap = parula(numel(fixedPos));   % parula.m (this folder) approximates MATLAB's parula, which Octave lacks
hold on
for k = 1:numel(fixedPos)
    plot(trec,ageAtPos(:,k),'-','LineWidth',LWW*1.5,'Color',cmap(k,:), ...
        'DisplayName',sprintf('x=%.4g mm',fixedPos(k)))
end
hold off
grid on, axis square
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
xlabel('t (Myr)','FontSize',FSS)
ylabel('\tau (Myr)','FontSize',FSS)
title(sprintf('\\tau evolution',Smin),'FontSize',FSS)
legend('Location','eastoutside')
matlabStyle(fig)
end
