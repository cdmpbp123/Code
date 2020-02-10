% plot validation scores of monthly/daily/climatology front in binned grid from concateneted yearly NetCDF file
close all
clear all
clc
%
platform = 'hanyh_laptop';
if strcmp(platform, 'hanyh_laptop')
    basedir = 'D:\lomf\frontal_detect\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform, 'PC_office')
    basedir = 'D:\lomf\frontal_detect\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform, 'server197')
    root_path = '/work/person/rensh/';
    basedir = [root_path, '/front_detect/'];
    toolbox_path = [root_path, '/matlab_function/'];
end

% add path of toolbox we use
addpath(genpath([toolbox_path, '/export_fig/']))
addpath(genpath([toolbox_path, '/m_map/']))
addpath(genpath([toolbox_path, '/MatlabFns/']))
addpath(genpath([basedir, '/frontal_detection/']))


domain = 2; % choose SCS domain for front diagnostic
% domain select
switch domain
    case 1
        % NSCS domain, specific for front area in north SCS
        domain_name = 'NSCS';
        lat_s = 10; lat_n = 25;
        lon_w = 105; lon_e = 121;
    case 2
        % whole SCS domain
        domain_name = 'SCS';
        lat_s = -4; lat_n = 28;
        lon_w = 99; lon_e = 127;
    case 3
        % ROMS model domain, include part of NWP
        domain_name = 'model_domain';
        lat_s = -4; lat_n = 28;
        lon_w = 99; lon_e = 144;
end

% global lat_n lat_s lon_w lon_e
% global fig_show
datatype = 'mercator';
yy1 = 2008;
yy2 = 2017;
% set a new regular grid
bin_resolution = 0.5; % unit: degree
clim_suffix = [num2str(yy1), 'to', num2str(yy2)];

daily_path = [basedir, './Result/', datatype, '/', domain_name, '/daily/'];
% clim_path = [basedir, './Result/', datatype, '/', domain_name, '/climatology/'];mkdir(clim_path)
% monthly_path = [basedir, './Result/', datatype, '/', domain_name, '/climatology/'];mkdir(monthly_path)
fig_score_daily = 0;
fig_path = [basedir, './Fig/',datatype,'/', domain_name, '/','daily','/']; mkdir(fig_path);
scores_fig_path = [fig_path,'/scores/']; mkdir(scores_fig_path)
fig_show = 'off';
LineWidth = 1;

% if strcmp(fig_score_type,'daily')
if fig_score_daily
    % concatenate 10-years data 
    fn_prefix = ['validation_score_front_daily_binned_',num2str(bin_resolution),'degree_'];
    datetime_daily_multi_year = concatenate_front_multipe_years(daily_path, fn_prefix, 'datetime',1,yy1,yy2);
    area_bias_daily_multi_year = concatenate_front_multipe_years(daily_path, fn_prefix, 'area_bias',1,yy1,yy2);
    area_TS_daily_multi_year = concatenate_front_multipe_years(daily_path, fn_prefix, 'area_TS',1,yy1,yy2);
    area_FAR_daily_multi_year = concatenate_front_multipe_years(daily_path, fn_prefix, 'area_FAR',1,yy1,yy2);
    area_MR_daily_multi_year = concatenate_front_multipe_years(daily_path, fn_prefix, 'area_MR',1,yy1,yy2);
    area_FA_daily_multi_year = concatenate_front_multipe_years(daily_path, fn_prefix, 'area_FA',1,yy1,yy2);
    area_DR_daily_multi_year = concatenate_front_multipe_years(daily_path, fn_prefix, 'area_DR',1,yy1,yy2);
    % plot 10y daily result
    daily_length = length(datetime_daily_multi_year);
    year_label = yy1:yy2;
    year_ticklabel = string(year_label);
    year_tick = 1:365:daily_length;
    LineWidth = 1;
    figure
    plot(area_bias_daily_multi_year,'b','LineWidth',LineWidth)
    hold on
    plot(area_TS_daily_multi_year,'r','LineWidth',LineWidth)
    hold on
    plot(area_FA_daily_multi_year,'k','LineWidth',LineWidth)
    hold on
    legend('bias','TS','Forecast Accuracy','Location','best')
    set(gca, 'XTick', year_tick)
    set(gca, 'XTickLabel', year_ticklabel)
    title(['bias'])
    xlabel('year')
    ylabel('km')
    export_fig([scores_fig_path, 'validation_scores_daily_', clim_suffix, '.png'], '-png', '-r200');
end

area_bias_month = [];
area_TS_month = [];
area_FAR_month = [];
area_MR_month = [];
area_FA_month = [];
area_DR_month = [];
for iy = yy1:yy2
    result_fn = [daily_path,'/validation_score_front_daily_binned_',num2str(bin_resolution),'degree_',num2str(iy),'.nc'];
    if ~exist(result_fn)
        continue
    end
    area_bias = ncread(result_fn,'area_bias');
    area_TS = ncread(result_fn,'area_TS');
    area_FAR = ncread(result_fn,'area_FAR');
    area_MR = ncread(result_fn,'area_MR');
    area_FA = ncread(result_fn,'area_FA');
    area_DR = ncread(result_fn,'area_DR');
    if fig_score_daily
        % plot line each year
        month_string = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
        xx = cellstr(month_string);
        xtick = 15:30:ndays;
        xlabel = 1:ndays;
        
        figure
        plot(xlabel,area_bias,'b','LineWidth',LineWidth)
        hold on
        plot(xlabel,area_TS,'r','LineWidth',LineWidth)
        hold on
        plot(xlabel,area_FA,'m','LineWidth',LineWidth)
        hold on
        legend('bias','TS','Forecast Accuracy','Location','best')
        title(num2str(iy))
        ylabel('scores')
        grid on
        set(gca,'XTick',xtick)
        set(gca,'XTickLabel',xx)

        export_fig([scores_fig_path,'validation_scores_daily_',num2str(iy),'.png'],'-png','-r200');
        close all
    end
    
    datetime = datenum(iy,1,1,0,0,0):1:datenum(iy,12,31,0,0,0);
    for im = 1:12
        mm = str2num(datestr(datetime,'mm'));
        month_index = find(mm == im);
        area_bias_month  = cat(1,area_bias_month,nanmean(area_bias(month_index)));
        area_TS_month    = cat(1,area_TS_month,nanmean(area_TS(month_index)));
        area_FAR_month  = cat(1,area_FAR_month, nanmean(area_FAR(month_index)));
        area_MR_month  = cat(1,area_MR_month,nanmean(area_MR(month_index)));
        area_FA_month  = cat(1,area_FA_month,nanmean(area_FA(month_index)));
        area_DR_month  = cat(1,area_DR_month,nanmean(area_DR(month_index)));
    end
end

% plot monthly front validation score overlayed with front parameter statistic
fig_path = [basedir, './Fig/',datatype,'/', domain_name, '/','monthly','/']; mkdir(fig_path);
scores_fig_path = [fig_path,'/scores/']; mkdir(scores_fig_path)

year_label = yy1:yy2;
year_ticklabel = string(year_label);
xx = 1:length(area_bias_month);
year_tick = 1:12:120;
plot_time_series_with_regression(area_bias_month,year_tick,year_ticklabel,'bias',[scores_fig_path, 'monthly_bias_', clim_suffix, '.png'])
plot_time_series_with_regression(area_TS_month,year_tick,year_ticklabel,'TS',[scores_fig_path, 'monthly_TS_', clim_suffix, '.png'])
plot_time_series_with_regression(area_FA_month,year_tick,year_ticklabel,'FA',[scores_fig_path, 'monthly_FA_', clim_suffix, '.png'])

% plot climatology
fig_path = [basedir, './Fig/',datatype,'/', domain_name, '/','climatology','/']; mkdir(fig_path);
scores_fig_path = [fig_path,'/scores/']; mkdir(scores_fig_path)

area_bias_clim = zeros(12,1);
area_TS_clim = zeros(12,1);
area_FA_clim = zeros(12,1);
for im = 1:12
    area_bias_clim(im) = nanmean(area_bias_month(im:12:end));
    area_TS_clim(im) = nanmean(area_TS_month(im:12:end));
    area_FA_clim(im) = nanmean(area_FA_month(im:12:end));
end
% plot line each year
month_string = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
xx = cellstr(month_string);
xtick = 1:12;
xlabel = xtick;

figure
plot(xlabel,area_bias_clim,'b','LineWidth',LineWidth)
hold on
plot(xlabel,area_TS_clim,'r','LineWidth',LineWidth)
hold on
plot(xlabel,area_FA_clim,'m','LineWidth',LineWidth)
hold on
legend('bias','TS','Forecast Accuracy','Location','best')
title('monthly climatology')
ylabel('scores')
grid on
set(gca,'XTick',xtick)
set(gca,'XTickLabel',xx)

export_fig([scores_fig_path,'validation_scores_monthly_climatology_',num2str(im,'%2.2d'),'.png'],'-png','-r200');
close all

function [normalized_var] = monthly_normalized(var)
    len = length(var);
    minvar = nanmin(var);
    maxvar = nanmax(var);
    if minvar ~= maxvar
        normalized_var = (var - minvar) / (maxvar - minvar);
    else
        normalized_var = ones(len,1)*minvar;
    end
end

function plot_time_series_with_regression(var,xtick,xticklabel,var_name,fig_name)
    LineWidth = 1;
    xx = 1:length(var);
    p = polyfit(xx',var,1);
    yy = p(1)*xx + p(2);
    equation_name = ['y=',num2str(p(1)),'x+',num2str(p(2))];
    figure
    plot(xx,var,'b','LineWidth',LineWidth)
    hold on
    plot(xx,yy)
    hold on
    legend(var_name,equation_name,'Location','best')
    set(gca, 'XTick', xtick)
    set(gca, 'XTickLabel', xticklabel)
    xlabel('year')
    ylabel(var_name)
    export_fig(fig_name, '-png', '-r200');
end





