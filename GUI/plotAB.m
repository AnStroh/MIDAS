function plotAB(xA,xB,CA,CB,CA0,CB0,t,t_tot,FSS,LWW,v,yMax)
    % Plots composition profile
    blueA = [0, 0.4470, 0.7410];   % Same default blue used for the apparent-age curve (panel F)
    plot(xA,CA,'Color',blueA,'linewidth',LWW*1.5)
    hold on
    plot(xB,CB,'k','linewidth',LWW*1.5)
    xline(xA(end),'--','Color', [0.7 0.7 0.7],'linewidth',LWW)
    hold off
    xlim([0,max(xB)])
    ylim([0,yMax])
    %title([num2str(t/t_tot*100),' %'])
    %if v>0
    %    title('growth','FontSize',FSS)
    %elseif v<0
    %    title('resorption','FontSize',FSS)
    %else
    %    title('equilibrium','FontSize',FSS)
    %end
    grid on,axis square
    xlabel(['$x$', ' (mm)'],'interpreter','latex','FontSize',FSS)
    set(gca,'FontSize',FSS,'LineWidth',LWW,'Box','on')
    %drawnow
end
