% PLOT_THEM_1  Script fragment for MIDAS_Main.m's live/checkpoint figure(1)
% when params.plot_kind = 1: a 2x2 layout - (A) compositional profile
% (MgO), (B) P-T path on the major-element phase diagram, (C) apparent age
% vs. distance, and (D) isochron ages (core/rim/bulk/max) for phase A.
%
% Not a function: runs in MIDAS_Main's own workspace (it uses xA, CA, T,
% FSS, etc. straight from the caller) via a bare `plot_them_1;` statement,
% not a call with arguments. See plot_them_2.m/plot_them_3.m for the other
% plot_kind layouts.
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
tiledlayout(2,2)

% Compositional profile
nexttile
plotAB(xA,xB,CA,CB,CA0,CB0,t,t_tot,FSS,LWW,v,yMaxCA)
ylabel(['MgO',' (wt.\%)'],'FontSize',FSS)
title(['t (Myr): ',num2str(t)],'FontSize',FSS,'FontWeight','normal')
ylim([1.0 18])
text(0.95,0.95,'(A)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)


% Phase diagram
nexttile
pcolor(T2-273,P2,CA2),shading flat,colormap(gca,parula(64))
cb = colorbar; set(get(cb,'Label'),'String','MgO (wt.\%)');
hold on,plot(Tt-273,Pt,'k',T-273,P,'.','linewidth',LWW,'MarkerSize',16),grid on,axis square,hold off
xlabel(['T (^oC)'],'FontSize',FSS)
ylabel(['P (GPa)'],'FontSize',FSS)
axis([Trange(1)-273 Trange(2)-273 Prange(1) Prange(2)])
set(gca,'XTick',ceil((Trange(1)-273)/100)*100:100:Trange(2)-273)   % round degC ticks (500, 600, ...) as in MATLAB
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
text(0.95,0.95,'(B)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

% Isotope age
nexttile
plot(xA,tALuHf1,'linewidth',LWW*1.5,'DisplayName','\tau'),hold on
plot([0,S],[t t],'k --','linewidth',LWW,'DisplayName','Sim. t'),grid on,hold off
xlabel(['x', ' (mm)'],'FontSize',FSS)
ylabel(['t',' (Myr)'],'FontSize',FSS)
ylim([0 t*1.1])
axis square
legend('Location','best')
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
text(0.95,0.95,'(C)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top')

% Isochron ages phase A: core, rim, bulk, and max age are always shown;
% the isoNskip-th profile points/lines (light gray) are optional (isoShowProfile)
nexttile
hold on
if isoShowProfile
    plot(XfitA,YfitProf,'Color',[0.75 0.75 0.75],'LineWidth',0.75*LWW,'HandleVisibility','off')
    plot(Xprof,Yprof,'o','Color',[0.6 0.6 0.6],'MarkerFaceColor',[0.85 0.85 0.85],'HandleVisibility','off')
end
plot(XdatA,YdatA,'k d ','MarkerFaceColor','k','DisplayName','Data')
plot(XfitA,YfitRimA, 'Color',[0.12 0.56 1.00],'LineWidth',LWW*1.5,'DisplayName','Rim')
plot(XfitA,YfitCoreA,'Color',[0.98 0.50 0.45],'LineWidth',LWW*1.5,'DisplayName','Core')
plot(XfitA,YfitBulkA,'Color',[0.4 0.4 0.4], 'LineWidth',LWW*1.5,'DisplayName','Bulk')
plot(XfitA,YfitMaxA,'Color',[0.71 0.49 0.86],'LineWidth',LWW*1.5,'DisplayName','Max')
plot(XmaxA,YmaxA,'o','MarkerFaceColor',[0.71 0.49 0.86],'MarkerEdgeColor','k','HandleVisibility','off')
hold off
grid on,axis square
xlabel('P/D_r','FontSize',FSS)
ylabel('D/D_r','FontSize',FSS)
legend('Location','best')
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
text(0.95,0.95,'(D)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top')
text(1.05,0.5,{sprintf('t_{rim} = %.4g',t_rimA),sprintf('t_{core} = %.4g',t_coreA), ...
    sprintf('t_{bulk} = %.4g',t_bulkA),sprintf('t_{max} = %.4g',t_maxA)}, ...
    'Units','normalized','HorizontalAlignment','right','FontSize',FSS,'VerticalAlignment','middle')

drawnow
