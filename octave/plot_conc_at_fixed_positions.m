function fig = plot_conc_at_fixed_positions(R, nDiv)
% PLOT_CONC_AT_FIXED_POSITIONS  Companion to plot_age_at_fixed_positions.m:
% the raw Lu and Hf concentrations (not the derived apparent age) vs. time,
% tracked at the same nDiv+1 fixed positions spanning [0, min(S)] - the
% smallest crystal size reached at any point in the run, so every tracked
% position is guaranteed to exist inside the crystal at every recorded time.
%
% Lets you see directly what plot_age_at_fixed_positions.m's age curves are
% built from: whether a position's radiogenic Hf signal (CAHf minus the
% dashed core@t=0 reference) is genuinely small there, versus its Lu is
% still large - the combination that makes the apparent-age formula most
% sensitive to any diffusive disturbance.
%
% Usage:
%   R = MIDAS_Main(params);           % params.store_history must be 1
%   plot_conc_at_fixed_positions(R)       % default: every 10th of min(S)
%   plot_conc_at_fixed_positions(R,20)    % every 20th instead
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
if ~isfield(R,'Srec')
    error('plot_conc_at_fixed_positions requires history (params.store_history = 1)')
end
if nargin < 2 || isempty(nDiv)
    nDiv = 10;
end
FSS   = R.params.FSS;
LWW   = R.params.LWW;
trec  = R.trec;
Srec  = R.Srec;
xArec = R.xArec;

Smin     = min(Srec);
fixedPos = linspace(0,Smin,nDiv+1);   % 0, Smin/nDiv, ..., Smin

nT        = numel(trec);
LuAtPos   = nan(nT,numel(fixedPos));
HfAtPos   = nan(nT,numel(fixedPos));
for it = 1:nT
    LuAtPos(it,:) = interp1(xArec(it,:),R.CALurec(it,:),fixedPos,'pchip');
    HfAtPos(it,:) = interp1(xArec(it,:),R.CAHfrec(it,:),fixedPos,'pchip');
end
CAHf0_core = R.params.HfiB*R.params.KDHf;   % initial (t=0) core Hf - the reference the age formula subtracts everywhere

fig  = figure('Color',[1 1 1],'Units','pixels','Position',[100 100 1300 650]);
tiledlayout(1,2,'TileSpacing','loose','Padding','compact');
cmap = viridis(numel(fixedPos));   % NOT parula: doesn't exist in Octave ("not yet implemented"); viridis is Octave's own closest perceptually-uniform equivalent

nexttile
hold on
for k = 1:numel(fixedPos)
    plot(trec,LuAtPos(:,k),'-','LineWidth',LWW*1.5,'Color',cmap(k,:), ...
        'DisplayName',sprintf('x=%.4g mm',fixedPos(k)))
end
hold off
grid on, axis square
ylim([min(LuAtPos(:))*0.8, max(LuAtPos(:))*1.2])
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
xlabel('t (Myr)','FontSize',FSS)
ylabel('^{176}Lu (ppm)','FontSize',FSS)
title('^{176}Lu evolution','FontSize',FSS)
text(0.03,0.97,'(A)','Units','normalized','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

nexttile
hold on
for k = 1:numel(fixedPos)
    plot(trec,HfAtPos(:,k),'-','LineWidth',LWW*1.5,'Color',cmap(k,:), ...
        'DisplayName',sprintf('x=%.4g mm',fixedPos(k)))
end
yline(CAHf0_core,'k--','LineWidth',LWW,'DisplayName','Core @ t=0 (ref)')
ylim([min(HfAtPos(:))*0.8, max(HfAtPos(:))*1.2])
hold off
grid on, axis square
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
xlabel('t (Myr)','FontSize',FSS)
ylabel('^{176}Hf (ppm)','FontSize',FSS)
title('^{176}Hf evolution','FontSize',FSS)
legend('Location','eastoutside')
text(0.03,0.97,'(B)','Units','normalized','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)
end
