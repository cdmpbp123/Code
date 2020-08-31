% plot histogram of snapshot
if isempty(figname)~=1
    ymin = 50;
    ymax = 100;
    LowFreqPercent = LowFreq*100;
    HighFreqPercent = HighFreq*100;
    figure;
    plot(x,cum_freq*100,'LineWidth',2)
    set(gca,'YLim',[ymin ymax])
    xlabel('gradient (\circC/km)','FontSize',12)
    ylabel('Percent','FontSize',12)
    hold on
    plot([lowThresh lowThresh],[ymin LowFreqPercent],'LineStyle','-','Color','k','LineWidth',1)
    plot([0 lowThresh],[LowFreqPercent LowFreqPercent],'LineStyle','-','Color','k','LineWidth',1)
    hold on
    plot([highThresh highThresh],[ymin HighFreqPercent],'LineStyle','-','Color','r','LineWidth',1)
    plot([0 highThresh],[HighFreqPercent HighFreqPercent],'LineStyle','-','Color','r','LineWidth',1)
    t_string = ['lower thresh = ',num2str(lowThresh,'%4.3f'),', upper thresh =',num2str(highThresh,'%4.3f')];
    title(t_string,'FontSize',14)
    print ('-djpeg95','-r300',figname);
    close all
end