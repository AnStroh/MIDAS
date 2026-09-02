tiledlayout(4,2,'TileSpacing','compact','Padding','compact')
L_tot = Lx0(1)+Lx0(2);

%Phase diagram + P-T path: garnet
nexttile(1)
contourf(T2-273,P2,CA2,10),shading flat
cb = colorbar; set(get(cb,'Label'),'String','MgO (wt.\%)');
hold on
plot(Tt-273,Pt,'k','LineWidth',LWW*1.8)
plot(T-273,P,'r.','MarkerSize',24)
grid on, axis square, hold off
xlabel(['T (^oC)'],'FontSize',FSS)
ylabel(['P (GPa)'],'FontSize',FSS)
axis([Trange(1)-273 Trange(2)-273 Prange(1) Prange(2)])
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
text(0.95,0.95,'(A)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

%Phase diagram + P-T path: biotite
nexttile(2)
contourf(T2-273,P2,CB2,10),shading flat
cb = colorbar; set(get(cb,'Label'),'String','MgO (wt.\%)');
hold on
plot(Tt-273,Pt,'k','LineWidth',LWW*1.8)
plot(T-273,P,'r.','MarkerSize',24)
grid on, axis square, hold off
xlabel(['T (^oC)'],'FontSize',FSS)
ylabel(['P (GPa)'],'FontSize',FSS)
axis([Trange(1)-273 Trange(2)-273 Prange(1) Prange(2)])
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
text(0.95,0.95,'(B)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

% Compositional profile
nexttile(3)
plotAB(xA,xB,CA,CB,CA0,CB0,t,t_tot,FSS,LWW,v,yMaxCA)
ylabel(['MgO',' (wt.\%)'],'FontSize',FSS)
title(['t (Myr): ',num2str(round(t*1000)/1000)],'FontSize',FSS,'FontWeight','normal')
xlim([0.0 L_tot])
%ylim([2.0 18])
text(0.95,0.95,'(C)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

nexttile(4)
plotAB(xA,xB,CAMn,CBMn,CAMn0,CBMn0,t,t_tot,FSS,LWW,v,yMaxCAMn)
ylabel(['MnO',' (wt.\%)'],'FontSize',FSS)
xlim([0.0 L_tot])
%ylim([0.0 1.5])
text(0.95,0.95,'(D)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

nexttile(5)
plotAB(xA,xB,CALu,CBLu,CALu0,CBLu0,t,t_tot,FSS,LWW,v,yMaxCALu)
ylabel(['^{176}Lu',' (ppm)'],'FontSize',FSS)
xlim([0.0 L_tot])
%ylim([0.0 140])
text(0.95,0.95,'(E)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

nexttile(6)
plotAB(xA,xB,CAHf,CBHf,CAHf0,CBHf0,t,t_tot,FSS,LWW,v,yMaxCAHf)
ylabel(['^{176}Hf',' (ppm)'],'FontSize',FSS)
xlim([0.0 L_tot])
ylim([0.0,max(CBHf)*1.2])          % Zoom to phase B's range (much smaller than A's, KDHf << 1) so it's visible
text(0.95,0.95,'(F)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

% Isotope age
nexttile(7)
plot(xA,tALuHf1,'linewidth',LWW*1.5,'DisplayName','\tau'),hold on
plot([0,S],[t t],'k --','linewidth',LWW*1.5,'DisplayName','Sim. t'),grid on,hold off
xlabel(['x', ' (mm)'],'FontSize',FSS)
ylabel(['t',' (Myr)'],'FontSize',FSS)
xlim([0.0 L_tot])
ylim([min([0,tALuHf1]), max([t,tALuHf1])*1.1])   % adapt to tau's actual range, not just t*1.1 - a disturbed profile can exceed it
axis square
legend('Location','eastoutside')
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
text(0.95,0.95,'(G)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

%Isochron ages phase A: core, rim, bulk, and max age are always shown;
% the isoNskip-th profile points/lines (light gray) are optional (isoShowProfile)
nexttile(8)
hold on
if isoShowProfile
    plot(XfitA,YfitProf,'Color',[0.75 0.75 0.75],'LineWidth',0.75*LWW,'HandleVisibility','off')
    plot(Xprof,Yprof,'o','Color',[0.6 0.6 0.6],'MarkerFaceColor',[0.85 0.85 0.85],'HandleVisibility','off')
end
plot(XdatA,YdatA,'k d ','MarkerFaceColor','k','DisplayName','Data')
plot(XfitA,YfitRimA, 'Color',[0.12 0.56 1.00],'LineWidth',LWW*1.5,'DisplayName',sprintf('Rim: %.3g Myr',t_rimA))
plot(XfitA,YfitCoreA,'Color',[0.98 0.50 0.45],'LineWidth',LWW*1.5,'DisplayName',sprintf('Core: %.3g Myr',t_coreA))
plot(XfitA,YfitBulkA,'Color',[0.4 0.4 0.4], 'LineWidth',LWW*1.5,'DisplayName',sprintf('Bulk: %.3g Myr',t_bulkA))
plot(XfitA,YfitMaxA,'Color',[0.71 0.49 0.86],'LineWidth',LWW*1.5,'DisplayName',sprintf('Max: %.3g Myr',t_maxA))
plot(XmaxA,YmaxA,'o','MarkerFaceColor',[0.71 0.49 0.86],'MarkerEdgeColor','k','HandleVisibility','off')
hold off
grid on,axis square
xlabel('P/D_r','FontSize',FSS)
ylabel('D/D_r','FontSize',FSS)
lgd8 = legend('Location','eastoutside');
set(lgd8,'FontSize',FSS*0.8);
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
text(0.05,0.95,'(H)','Units','normalized','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

drawnow
