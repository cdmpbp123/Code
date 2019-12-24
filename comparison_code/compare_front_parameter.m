% compare diagnostic paramter of ROMS, Mercator and OSTIA in 2008-2017
% for now the length criterion is different, need to uniform
% auto-length criterion
close all
clear all
clc
%
platform = 'hanyh_laptop';
if strcmp(platform, 'hanyh_laptop')
    basedir = 'D:\lomf\frontal_detect\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform,'PC_office')
    basedir = 'D:\lomf\frontal_detect\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform,'server197')
    root_path = '/work/person/rensh/';
    basedir = [root_path,'/front_detect/'];
    toolbox_path = [root_path,'/matlab_function/'];
end

% add path of toolbox we use
addpath(genpath([toolbox_path,'/export_fig/']))
addpath(genpath([toolbox_path,'/m_map/']))
addpath(genpath([toolbox_path,'/MatlabFns/']))
addpath(genpath([basedir,'/frontal_detection/']))

domain = 2;
% choose whole model domain for SST comparison
switch domain
case 1
    % NSCS domain, specific for front area in north SCS
    domain_name = 'NSCS';
    lat_s=10; lat_n=25;
    lon_w=105; lon_e=121;
case 2
    % whole SCS domain
    domain_name = 'SCS';
    lat_s=-4; lat_n=28;
    lon_w=99; lon_e=127;
case 3
    % ROMS model domain, include part of NWP
    domain_name = 'model_domain';
    lat_s=-4; lat_n=28;
    lon_w=99; lon_e=144;
end
monthly_path = [basedir, './Result/', 'comparison', '/', domain_name, '/monthly/']; mkdir(monthly_path)
clim_path = [basedir, './Result/', 'comparison', '/', domain_name, '/climatology/']; mkdir(clim_path)
fig_parameter_climatology = 1;
fig_parameter_monthly = 0;
yy1 = 2008;
yy2 = 2017;
clim_suffix = [num2str(yy1), 'to', num2str(yy2)];
if fig_parameter_climatology
    fig_path = [basedir,'./Fig/comparison/',domain_name,'/climatology/'];mkdir(fig_path);
    parameter_fig_path = [fig_path,'/parameter/'];mkdir(parameter_fig_path)

    roms_monthly_result_fn = [basedir,'./Result/roms/',domain_name,'/climatology/','/climatology_front_',clim_suffix,'.nc'];
    ostia_monthly_result_fn = [basedir,'./Result/ostia/',domain_name,'/climatology/','/climatology_front_',clim_suffix,'.nc'];
    mercator_monthly_result_fn = [basedir,'./Result/mercator/',domain_name,'/climatology/','/climatology_front_',clim_suffix,'.nc'];

    roms_frontLength_mean = ncread(roms_monthly_result_fn, 'frontLength_mean');
    roms_frontStrength_mean = ncread(roms_monthly_result_fn, 'frontStrength_mean');
    roms_frontWidth_mean = ncread(roms_monthly_result_fn, 'frontWidth_mean' );
    roms_frontArea_mean = ncread(roms_monthly_result_fn, 'frontArea_mean' );
    roms_frontNumber_mean = ncread(roms_monthly_result_fn, 'frontNumber_mean');


    ostia_frontLength_mean = ncread(ostia_monthly_result_fn, 'frontLength_mean');
    ostia_frontStrength_mean = ncread(ostia_monthly_result_fn, 'frontStrength_mean');
    ostia_frontWidth_mean = ncread(ostia_monthly_result_fn, 'frontWidth_mean' );
    ostia_frontArea_mean = ncread(ostia_monthly_result_fn, 'frontArea_mean' );
    ostia_frontNumber_mean = ncread(ostia_monthly_result_fn, 'frontNumber_mean');

    mercator_frontLength_mean = ncread(mercator_monthly_result_fn, 'frontLength_mean');
    mercator_frontStrength_mean = ncread(mercator_monthly_result_fn, 'frontStrength_mean');
    mercator_frontWidth_mean = ncread(mercator_monthly_result_fn, 'frontWidth_mean' );
    mercator_frontArea_mean = ncread(mercator_monthly_result_fn, 'frontArea_mean' );
    mercator_frontNumber_mean = ncread(mercator_monthly_result_fn, 'frontNumber_mean');

    set(0,'DefaultAxesFontsize',12);
    set(0,'DefaultTextFontsize',12);
    %plot front parameter diagnostic figure
    month_string = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
    xx = cellstr(month_string);

    % bar image for front length
    frontLength_mean = cat(2,roms_frontLength_mean,ostia_frontLength_mean,mercator_frontLength_mean)*1e-3;
    figure
    bar(frontLength_mean)
    legend('roms','ostia','mercator','Location','best')
    title(' front length monthly climatology')
    ylabel('km')
    % set(gca,'YLim',[80 200])
    set(gca,'XTickLabel',xx)
    export_fig([parameter_fig_path,'front_length_',clim_suffix,'.png'],'-png','-r200');

    % bar image for front length
    frontStrength_mean = cat(2,roms_frontStrength_mean,ostia_frontStrength_mean,mercator_frontStrength_mean);
    figure
    bar(frontStrength_mean)
    legend('roms','ostia','mercator','Location','best')
    title(' front strength monthly climatology')
    ylabel('\circC/km')
    % set(gca,'YLim',[0.01 0.05])
    set(gca,'XTickLabel',xx)
    export_fig([parameter_fig_path,'front_strength_',clim_suffix,'.png'],'-png','-r200');

    % bar image for front width
    frontWidth_mean = cat(2,roms_frontWidth_mean,ostia_frontWidth_mean,mercator_frontWidth_mean)*1e-3;
    figure
    bar(frontWidth_mean)
    legend('roms','ostia','mercator','Location','best')
    title(' front width monthly climatology')
    ylabel('km')
    % set(gca,'YLim',[30 80])
    set(gca,'XTickLabel',xx)
    export_fig([parameter_fig_path,'front_width_',clim_suffix,'.png'],'-png','-r200');

    % bar image for front area
    frontArea_mean = cat(2, roms_frontArea_mean,ostia_frontArea_mean,mercator_frontArea_mean)*1e-6;
    figure
    bar(frontArea_mean)
    legend('roms','ostia','mercator','Location','best')
    title(' front area monthly climatology')
    ylabel('km2')
    % set(gca,'YLim',[3000 12000])
    set(gca,'XTickLabel',xx)
    export_fig([parameter_fig_path,'front_area_',clim_suffix,'.png'],'-png','-r200');

    % bar image for front number
    frontNumber_mean = cat(2,roms_frontNumber_mean,ostia_frontNumber_mean,mercator_frontNumber_mean);
    figure
    bar(frontNumber_mean)
    legend('roms','ostia','mercator','Location','best')
    title('front number monthly climatology')
    ylabel('#')
    % set(gca,'YLim',[60 200])
    set(gca,'XTickLabel',xx)
    export_fig([parameter_fig_path,'front_number_',clim_suffix,'.png'],'-png','-r200');

end

if fig_parameter_monthly
    fig_path = [basedir,'./Fig/comparison/',domain_name,'/monthly/'];mkdir(fig_path);
    parameter_fig_path = [fig_path,'/parameter/'];mkdir(parameter_fig_path)
    mat4compare_path = [monthly_path,'/mat4compare/']; mkdir(mat4compare_path)

    roms_monthly_result_fn = [basedir,'./Result/roms/',domain_name,'/monthly/mat4compare/monthly_front_parameter.mat'];
    ostia_monthly_result_fn = [basedir,'./Result/ostia/',domain_name,'/monthly/mat4compare/monthly_front_parameter.mat'];

    roms_data =load(roms_monthly_result_fn);
    ostia_data = load(ostia_monthly_result_fn);

    year_label = yy1:yy2;
    year_ticklabel = string(year_label);
    xx = 1:120;
    year_tick = 1:12:120;
    
    % average SST
    fig_name = [parameter_fig_path, 'monthly_domain_average_SST_', clim_suffix, '.png'];
    plot_time_series_with_regression(roms_data.average_sst_month,ostia_data.average_sst_month,...
        year_tick,year_ticklabel,'ROMS ','OSTIA ','SST(C)',fig_name)
    % average SST gradient
    fig_name = [parameter_fig_path, 'monthly_domain_average_SSTgrad_', clim_suffix, '.png'];
    plot_time_series_with_regression(roms_data.average_tgrad_month,ostia_data.average_tgrad_month,...
        year_tick,year_ticklabel,'ROMS ','OSTIA ','SSTgrad(C/km)',fig_name)
    % length
    fig_name = [parameter_fig_path, 'monthly_front_length_', clim_suffix, '.png'];
    plot_time_series_with_regression(roms_data.frontLength_month,ostia_data.frontLength_month,...
        year_tick,year_ticklabel,'ROMS ','OSTIA ','length (km)',fig_name)   
    % strength
    fig_name = [parameter_fig_path, 'monthly_front_strength_', clim_suffix, '.png'];
    plot_time_series_with_regression(roms_data.frontStrength_month,ostia_data.frontStrength_month,...
        year_tick,year_ticklabel,'ROMS ','OSTIA ','strength (C/km)',fig_name)   
    % width
    fig_name = [parameter_fig_path, 'monthly_front_width_', clim_suffix, '.png'];
    plot_time_series_with_regression(roms_data.frontWidth_month,ostia_data.frontWidth_month,...
        year_tick,year_ticklabel,'ROMS ','OSTIA ','width (km)',fig_name)   
    % width
    fig_name = [parameter_fig_path, 'monthly_front_area_', clim_suffix, '.png'];
    plot_time_series_with_regression(roms_data.frontArea_month,ostia_data.frontArea_month,...
        year_tick,year_ticklabel,'ROMS ','OSTIA ','area (km2)',fig_name)   
    % number
    fig_name = [parameter_fig_path, 'monthly_front_number_', clim_suffix, '.png'];
    plot_time_series_with_regression(roms_data.frontNumber_month,ostia_data.frontNumber_month,...
        year_tick,year_ticklabel,'ROMS ','OSTIA ','number (#)',fig_name)   

end

function plot_time_series_with_regression(var1,var2,xtick,xticklabel,var_name1,var_name2,unit,fig_name)
    LineWidth = 1;
    xx = 1:length(var1);
    p = polyfit(xx',var1,1);
    yy1 = p(1)*xx + p(2);
    q = polyfit(xx',var2,1);
    yy2 = q(1)*xx + q(2);
    equation_name1 = ['y=',num2str(p(1)),'x+',num2str(p(2))];
    equation_name2 = ['y=',num2str(q(1)),'x+',num2str(q(2))];
    figure
    plot(xx,var1,'b','LineWidth',LineWidth)
    hold on
    plot(xx,yy1,'b')
    hold on
    plot(xx,var2,'r','LineWidth',LineWidth)
    hold on
    plot(xx,yy2,'r')
    hold on
    legend(var_name1,equation_name1,var_name2,equation_name2,'Location','best')
    set(gca, 'XTick', xtick)
    set(gca, 'XTickLabel', xticklabel)
    title(unit)
    xlabel('year')
    ylabel(unit)
    export_fig(fig_name, '-png', '-r200');
end