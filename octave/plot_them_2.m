tiledlayout(3,2)
% Compositional profile
nexttile
plotAB(xA,xB,CA,CB,CA0,CB0,t,t_tot,FSS,LWW,v,yMaxCA)
ylabel(['MgO',' (wt.\%)'],'FontSize',FSS)
title(['t (Myr): ',num2str(round(t*1000)/1000)],'FontSize',FSS,'FontWeight','normal')
xlim([0.0 Lx0(1)*2])
ylim([2.0 18])
text(0.95,0.95,'(A)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

nexttile
plotAB(xA,xB,CAMn,CBMn,CAMn0,CBMn0,t,t_tot,FSS,LWW,v,yMaxCAMn)
ylabel(['MnO',' (wt.\%)'],'FontSize',FSS)
%xlim([0.0 Lx0(1)*2])
%ylim([0.0 1.5])
text(0.95,0.95,'(B)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

nexttile
plotAB(xA,xB,CALu,CBLu,CALu0,CBLu0,t,t_tot,FSS,LWW,v,yMaxCALu)
ylabel(['^{176}Lu',' (ppm)'],'FontSize',FSS)
%xlim([0.0 Lx0(1)*2])
%ylim([0.0 140])
text(0.95,0.95,'(C)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

nexttile
plotAB(xA,xB,CAHf,CBHf,CAHf0,CBHf0,t,t_tot,FSS,LWW,v,yMaxCAHf)
ylabel(['^{176}Hf',' (ppm)'],'FontSize',FSS)
%xlim([0.0 Lx0(1)*2])
%ylim([0.0 0.05])
text(0.95,0.95,'(D)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top','BackgroundColor',[1 1 1],'Margin',1)

% Isotope age
nexttile
%plotAB(xA,xB,CALu,CBLu,CALu0,CBLu0,t,t_tot,FSS,LWW,v)
%ylabel(['Lu',' (ppm)'],'FontSize',FSS)
%ylim([90 110])
plot(xA,tALuHf1,'linewidth',LWW*1.5,'DisplayName','\tau'),hold on
plot([0,S],[t t],'k --','linewidth',LWW,'DisplayName','Sim. t'),grid on,hold off
xlabel(['x', ' (mm)'],'FontSize',FSS)
ylabel(['t',' (Myr)'],'FontSize',FSS)
xlim([0.0 Lx0(1)*2])
ylim([0 t*1.1])
axis square
legend('Location','best')
%ylim([17 23])
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
text(0.95,0.95,'(E)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top')

%Isochron ages phase A: core, rim, bulk, and max age are always shown;
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
%axis([0 10 0 4])
xlabel('P/D_r','FontSize',FSS)
ylabel('D/D_r','FontSize',FSS)
legend('Location','best')
set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
text(0.95,0.95,'(F)','Units','normalized','HorizontalAlignment','right','FontSize',FSS*1.3,'FontWeight','bold','VerticalAlignment','top')
text(1.05,0.5,{sprintf('t_{rim} = %.4g',t_rimA),sprintf('t_{core} = %.4g',t_coreA), ...
    sprintf('t_{bulk} = %.4g',t_bulkA),sprintf('t_{max} = %.4g',t_maxA)}, ...
    'Units','normalized','HorizontalAlignment','right','FontSize',FSS,'VerticalAlignment','middle')

drawnow