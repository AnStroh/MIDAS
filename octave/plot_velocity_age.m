function [figAB, figErr, figRelErr, figErrLog, figRelErrLog, figABOnly] = plot_velocity_age(R, fixedLengths)
% PLOT_VELOCITY_AGE  Post-run figures for phase A (crystal). The first five
% share the same two-panel layout - (A) length of A vs time, colored by a
% different quantity each time; (B) interface velocity vs time, identical
% in all five - built on the same length-vs-time grid (fixedLengths x
% trec), with the apparent-age profile (tALuHf1) interpolated onto it
% since the node grid itself resamples as the crystal grows/resorbs:
%   figAB          (A) colored by apparent age tau (Myr)
%   figErr         (A) colored by tau - t (apparent age minus true model time, Myr)
%   figRelErr      (A) colored by (tau-t)/t (%)
%   figErrLog      (A) same as figErr, signed-log color scale - the core
%                      (near-zero misfit) and the actively-growing rim
%                      (near-maximum misfit) are both large, structured
%                      fractions of the data (not a few outliers), so a
%                      linear scale still looks mostly flat inside the rim;
%                      sign(Z)*log10(1+|Z|) spreads that region out instead.
%   figRelErrLog   (A) same as figRelErr, signed-log color scale
%   figABOnly      Same data/colors as figAB (apparent age tau), but
%                      standalone: just the heatmap, no panel (B), no
%                      "(A)" letter tag (unambiguous with only one panel).
%
% Usage:
%   R = MIDAS_Main(params);            % params.store_history must be 1
%   plot_velocity_age(R)                   % default fixed lengths
%   plot_velocity_age(R, linspace(0,0.05,50))  % your own fixed lengths (mm)
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
if ~isfield(R,'Vrec')
    error('plot_velocity_age requires history (params.store_history = 1)')
end
trec  = R.trec;
Vrec  = R.Vrec;
Srec  = R.Srec;
xArec = R.xArec;
tA1   = R.tA1;
FSS   = R.params.FSS;
LWW   = R.params.LWW;

if nargin < 2 || isempty(fixedLengths)
    fixedLengths = linspace(0,max(Srec),100);         % Default fixed lengths (mm)
end

% Interpolate the apparent-age profile onto fixedLengths at every recorded
% time step; lengths beyond the current crystal size are left as NaN.
nT      = numel(trec);
AgeGrid = nan(nT,numel(fixedLengths));
for it = 1:nT
    valid = fixedLengths <= Srec(it);
    AgeGrid(it,valid) = interp1(xArec(it,:),tA1(it,:),fixedLengths(valid),'pchip');
end
errGrid    = AgeGrid - trec(:);            % tau - t
relErrGrid = errGrid./trec(:);
relErrGrid(trec==0,:) = NaN;               % avoid division by zero at t=0

% Diverging colormap (blue = too young, red = too old), for the two misfit
% figures - centered on zero. Smooth linear ramp (no plateau/clipping), so
% the full color gradient is used to distinguish values all the way out to
% the true data extremes instead of flattening past some threshold.
nc     = 256;
divmap = interp1([1 nc/2 nc], [0.20 0.33 0.64; 1 1 1; 0.70 0.09 0.17], 1:nc);

figAB         = buildVelAgeFig(fixedLengths,trec,Srec,Vrec,AgeGrid,        '\tau (Myr)',      [],     FSS,LWW);
figErr        = buildVelAgeFig(fixedLengths,trec,Srec,Vrec,errGrid,        '\tau - t (Myr)',  divmap, FSS,LWW);
figRelErr     = buildVelAgeFig(fixedLengths,trec,Srec,Vrec,relErrGrid*100, '(\tau-t)/t (\%)', divmap, FSS,LWW);
figErrLog     = buildVelAgeFigLog(fixedLengths,trec,Srec,Vrec,errGrid,        '\tau - t (Myr)',  divmap, FSS,LWW);
figRelErrLog  = buildVelAgeFigLog(fixedLengths,trec,Srec,Vrec,relErrGrid*100, '(\tau-t)/t (\%)', divmap, FSS,LWW);
figABOnly     = buildVelAgeFigPanelAOnly(fixedLengths,trec,Srec,AgeGrid,'\tau (Myr)',[],FSS,LWW);
end
function fig = buildVelAgeFigPanelAOnly(fixedLengths,trec,Srec,Grid,cbLabel,divmap,FSS,LWW)
% Standalone version of buildVelAgeFig's panel (A) only - the length-vs-time
% heatmap, no panel (B), no "(A)" letter tag (nothing to disambiguate from
% with just one panel).
fig = figure('Color',[1 1 1],'Units','pixels','Position',[100 100 700 600]);
pcolor(fixedLengths,trec,Grid), shading flat
hold on
plot(Srec,trec,'k-','LineWidth',LWW)                  % Crystal boundary S(t)
hold off
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on','Layer','top')
xlabel('x (mm)','FontSize',FSS)
ylabel('t (Myr)','FontSize',FSS)
title('Age distribution','FontSize',FSS)
cb = colorbar; set(get(cb,'Label'),'String',cbLabel);
if ~isempty(divmap)
    colormap(gca,divmap)
    setRobustDivergingCaxis(gca,Grid,100)
end
xlim([0 1.05*max(fixedLengths)])
grid on, axis square
end
function fig = buildVelAgeFig(fixedLengths,trec,Srec,Vrec,Grid,cbLabel,divmap,FSS,LWW)
% One (A)+(B) figure: (A) length of A vs time, colored by Grid; (B)
% velocity vs time (always the same, duplicated into every figure this is
% called for). divmap: [] for the plain sequential colormap (apparent age
% itself), or a diverging colormap for the signed/relative misfit grids -
% color limit is the raw symmetric max, so nothing clips (see setRobustDivergingCaxis).
fig = figure('Color',[1 1 1],'Units','pixels','Position',[100 100 1300 600]);
tiledlayout(1,2,'TileSpacing','loose','Padding','compact');

% (A) Length of A vs time, colored by Grid ----------------------------------
nexttile
pcolor(fixedLengths,trec,Grid), shading flat
hold on
plot(Srec,trec,'k-','LineWidth',LWW)                  % Crystal boundary S(t)
hold off
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on','Layer','top')
xlabel('x (mm)','FontSize',FSS)
ylabel('t (Myr)','FontSize',FSS)
title('Age distribution','FontSize',FSS)
cb = colorbar; set(get(cb,'Label'),'String',cbLabel);
if ~isempty(divmap)
    colormap(gca,divmap)
    setRobustDivergingCaxis(gca,Grid,100)  % 100 = raw max, no clipping - keeps the full color range usable right out to the true extremes
end
xlim([0 1.05*max(fixedLengths)])
grid on, axis square
text(0.005,0.995,'(A)','Units','normalized','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

% (B) Velocity vs time -------------------------------------------------------
nexttile
plot(trec,Vrec,'k-','LineWidth',LWW)
hold on
yline(0,'--')
hold off
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
xlabel('t (Myr)','FontSize',FSS)
ylabel('Interface velocity (mm/Myr)','FontSize',FSS)
title('Interface velocity vs. t','FontSize',FSS)
grid on, axis square
text(0.005,0.995,'(B)','Units','normalized','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)
end
function fig = buildVelAgeFigLog(fixedLengths,trec,Srec,Vrec,Grid,cbLabel,divmap,FSS,LWW)
% Same as buildVelAgeFig, but panel A is colored by the signed-log transform
% sign(Grid)*log10(1+|Grid|) instead of Grid itself - spreads out a
% near-zero-heavy, near-max-heavy bimodal distribution (e.g. an
% equilibrated core next to a rim that hasn't recorded age yet) that a
% linear scale renders as two flat blocks either side of a thin transition.
% Colorbar ticks are placed at "nice" real (untransformed) values so it
% still reads directly in the plotted units, not in log-transformed ones.
GridLog = sign(Grid).*log10(1+abs(Grid));

fig = figure('Color',[1 1 1],'Units','pixels','Position',[100 100 1300 600]);
tiledlayout(1,2,'TileSpacing','loose','Padding','compact');

nexttile
pcolor(fixedLengths,trec,GridLog), shading flat
hold on
plot(Srec,trec,'k-','LineWidth',LWW)
hold off
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on','Layer','top')
xlabel('x (mm)','FontSize',FSS)
ylabel('t (Myr)','FontSize',FSS)
title('Age distribution (signed-log scale)','FontSize',FSS)
colormap(gca,divmap)
M = max(abs(GridLog(:)),[],'omitnan');
if M > 0, caxis(gca,[-M M]); end
cb = colorbar;
if M > 0
    nTicksHalf = 4;
    posLog = linspace(0,M,nTicksHalf+1);          % evenly spaced in the transformed (plotted) space, so labels never crowd near zero
    tickLog = [-fliplr(posLog(2:end)), posLog];
    realVal = sign(tickLog).*(10.^abs(tickLog) - 1);   % back-transform to the actual data units for the labels
    set(cb,'Ticks',tickLog,'TickLabels',arrayfun(@(v) sprintf('%.3g',v), realVal, 'UniformOutput', false));
end
set(get(cb,'Label'),'String',cbLabel);
xlim([0 1.05*max(fixedLengths)])
grid on, axis square
text(0.005,0.995,'(A)','Units','normalized','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

nexttile
plot(trec,Vrec,'k-','LineWidth',LWW)
hold on
yline(0,'--')
hold off
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
xlabel('t (Myr)','FontSize',FSS)
ylabel('Interface velocity (mm/Myr)','FontSize',FSS)
title('Interface velocity vs. t','FontSize',FSS)
grid on, axis square
text(0.005,0.995,'(B)','Units','normalized','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)
end
function setRobustDivergingCaxis(ax,Z,pct)
% Symmetric color limit at the pct-th percentile of |Z|, not the raw max -
% a few extreme outliers otherwise stretch the whole diverging colormap so
% far that everything else collapses to near-white. Values beyond the
% limit simply clip to the fully-saturated end color.
v = abs(Z(:));
v = v(~isnan(v));
if isempty(v), return; end
v = sort(v);
idx = min(max(ceil(pct/100*numel(v)),1),numel(v));
M = v(idx);
if M > 0, caxis(ax,[-M M]); end
end
