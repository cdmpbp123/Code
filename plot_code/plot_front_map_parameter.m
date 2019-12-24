% plot monthly and climatology SST, gradient and front parameter
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

%set global variable
global lat_n lat_s lon_w lon_e
global fig_show
% global lineFreq_min lineFreq_max areaFreq_min areaFreq_max

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

% % parameter
datatype = 'mercator';
% plot_type = 'monthly';
plot_type = 'climatology';
yy1 = 2008;
yy2 = 2017;
fig_sst_tgrad = 1;
fig_parameter = 0;
%
daily_path = [basedir, './Result/', datatype, '/', domain_name, '/daily/'];
monthly_path = [basedir, './Result/', datatype, '/', domain_name, '/monthly/']; mkdir(monthly_path)
clim_path = [basedir, './Result/', datatype, '/', domain_name, '/climatology/']; mkdir(clim_path)
mat4compare_path = [monthly_path,'/mat4compare/']; mkdir(mat4compare_path)

fig_path = [basedir, './Fig/', datatype, '/', domain_name, '/', plot_type, '/']; mkdir(fig_path);

sst_fig_path = [fig_path, '/sst/']; mkdir(sst_fig_path)
tgrad_fig_path = [fig_path, '/tgrad/']; mkdir(tgrad_fig_path)
parameter_fig_path = [fig_path, '/parameter/']; mkdir(parameter_fig_path)

% plot monthly front figure
% set min&max value
tgrad_min = 0.01; tgrad_max = 0.1;
fig_show = 'off';

if strcmp(plot_type, 'climatology')
    clim_suffix = [num2str(yy1), 'to', num2str(yy2)];
    result_fn = [clim_path, 'climatology_front_', clim_suffix, '.nc'];
    lon = ncread(result_fn, 'lon');
    lat = ncread(result_fn, 'lat');
    mask = ncread(result_fn, 'mask');

    if fig_parameter
        % plot 5 parameter together
        frontLength_mean = ncread(result_fn, 'frontLength_mean') * 1e-3;
        frontStrength_mean = ncread(result_fn, 'frontStrength_mean');
        frontWidth_mean = ncread(result_fn, 'frontWidth_mean') * 1e-3;
        frontMaxWidth_mean = ncread(result_fn, 'frontMaxWidth_mean') * 1e-3;
        frontEquivalentWidth_mean = ncread(result_fn, 'frontEquivalentWidth_mean') * 1e-3;
        frontArea_mean = ncread(result_fn, 'frontArea_mean') * 1e-6;
        frontNumber_mean = ncread(result_fn, 'frontNumber_mean');
        dayOfMonth = ncread(result_fn, 'dayOfMonth');
        % Normalized
        length_normalize = parameter_normalize(frontLength_mean);
        strength_normalize = parameter_normalize(frontStrength_mean);
        width_normalize = parameter_normalize(frontWidth_mean);
        area_normalize = parameter_normalize(frontArea_mean);
        number_normalize = parameter_normalize(frontNumber_mean);
        %
        front_parameter_month = cat(2, length_normalize, strength_normalize, width_normalize, area_normalize, number_normalize);

        month_string = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
        xx = cellstr(month_string);
        bar_width = 0.7;
        % bar image of combined paramters
        figure
        bar(front_parameter_month, 1)
        legend('Length', 'Strength', 'Width', 'Area', 'Number')
        title(['climatology monthly front parameter'])
        ylabel('Normalized value')
        set(gca, 'XTickLabel', xx)
        set(gca, 'YLim', [0 1.3])
        export_fig([parameter_fig_path, 'climatology_front_parameter_bar_image_', clim_suffix, '.png'], '-png', '-r200');
        close all
        % line images
        figure
        plot(front_parameter_month,'LineWidth',2)
        legend('Length', 'Strength', 'Width', 'Area', 'Number','Location','Best')
        title(['climatology monthly front parameter'])
        ylabel('Normalized value')
        set(gca, 'XTick', 1:12)
        set(gca, 'XTickLabel', xx)
        set(gca, 'YLim', [0 1.3])
        export_fig([parameter_fig_path, 'climatology_front_parameter_line_image_', clim_suffix, '.png'], '-png', '-r200');
        close all
        %
        if 0
            % bar image for each parameter
            figure
            bar(frontLength_mean, bar_width)
            title(['climatology front length diagnostic ', clim_suffix])
            ylabel('km')
            % set(gca,'YLim',[80 200])
            set(gca, 'XTickLabel', xx)
            export_fig([parameter_fig_path, 'front_length_climatology_diagnostic_', clim_suffix, '.png'], '-png', '-r200');

            % bar image for each parameter
            figure
            bar(frontStrength_mean, bar_width)
            title(['climatology front strength diagnostic', clim_suffix])
            ylabel('\circC/km')
            set(gca, 'XTickLabel', xx)
            export_fig([parameter_fig_path, 'front_strength_climatology_diagnostic_', clim_suffix, '.png'], '-png', '-r200');

            % bar image for front width
            figure
            bar(frontWidth_mean, bar_width)
            title(['climatology front width diagnostic ', clim_suffix])
            ylabel('km')
            set(gca, 'XTickLabel', xx)
            export_fig([parameter_fig_path, 'front_width_climatology_diagnostic_', clim_suffix, '.png'], '-png', '-r200');

            % bar image for front area
            figure
            bar(frontArea_mean, bar_width)
            title(['climatology front area diagnostic ', clim_suffix])
            ylabel('km2')
            set(gca, 'XTickLabel', xx)
            export_fig([parameter_fig_path, 'front_area_climatology_diagnostic_', clim_suffix, '.png'], '-png', '-r200');

            % bar image for front number
            figure
            bar(frontNumber_mean, bar_width)
            title(['climatology front number diagnostic ', clim_suffix])
            ylabel('#')
            set(gca, 'XTickLabel', xx)
            export_fig([parameter_fig_path, 'front_number_climatology_diagnostic_', clim_suffix, '.png'], '-png', '-r200');
        end

        close all
    end

    if fig_sst_tgrad
        %
        temp_mean = ncread(result_fn, 'temp_mean');
        tgrad_mean = ncread(result_fn, 'tgrad_mean');
        % set SST colorbar uniform
        tmin = 20;
        tmax = 32;
        % climatology seasonal SST and SST gradient
        for season_index = 1:5

            switch (season_index)
                case 1
                    season_name = 'DJF';
                    month_index = [1, 2, 12];
                    % tmin = 15;  tmax = 30;
                case 2
                    season_name = 'MAM';
                    month_index = [3, 4, 5];
                    % tmin = 20;  tmax = 32;
                case 3
                    season_name = 'JJA';
                    month_index = [6, 7, 8];
                    % tmin = 24;  tmax = 34;
                case 4
                    season_name = 'SON';
                    month_index = [9, 10, 11];
                    % tmin = 20;  tmax = 32;
                case 5
                    season_name = 'Annual';
                    month_index = [1:12];
                    % tmin = 15;  tmax = 30;
            end
            disp(season_name)
            temp_season = nanmean(temp_mean(:, :, month_index),3);
            tgrad_season = nanmean(tgrad_mean(:, :, month_index),3);
            
            % SST
            fig_title = ['climatology SST in ', season_name, ' Unit: \circC'];
            fig_name = [sst_fig_path, '/climatology_sst_in_', season_name, '_', clim_suffix, '.png'];
            % tmin = nanmin(temp_season(:)); tmax = nanmax(temp_season(:));
            plot_pcolor_map(lon, lat, temp_season, tmin, tmax, fig_title, season_name, fig_name, 'sst')
            % tgrad
            fig_title = ['climatology tgrad in ', season_name, ' Unit: \circC/km'];
            fig_name = [tgrad_fig_path, '/climatology_tgrad_in_', season_name, '_' ,clim_suffix, '.png'];
            plot_pcolor_map(lon, lat, tgrad_season, tgrad_min, tgrad_max, fig_title, season_name, fig_name, 'tgrad')

        end
        % climatology monthly
        for im = 1:12
            disp(['month_',num2str(im)])
            % [tmin, tmax, mm] = set_temp_limit(im, temp_mean);
            [~, ~, mm] = set_temp_limit(im);
            % SST
            fig_title = ['climatology SST in ', mm, '. Unit: \circC'];
            fig_name = [sst_fig_path, '/climatology_sst_month_', num2str(im, '%2.2d'), '_' ,clim_suffix, '.png'];
            plot_pcolor_map(lon, lat, squeeze(temp_mean(:, :, im)), tmin, tmax, fig_title, mm, fig_name, 'sst')
            % tgrad
            fig_title = ['climatology tgrad in ', mm, '. Unit: \circC/km'];
            fig_name = [tgrad_fig_path, '/climatology_tgrad_month_', num2str(im, '%2.2d'),'_' ,clim_suffix, '.png'];
            plot_pcolor_map(lon, lat, squeeze(tgrad_mean(:, :, im)), tgrad_min, tgrad_max, fig_title, mm, fig_name, 'tgrad')
        end

    end
elseif strcmp(plot_type, 'monthly')
    % read climatology front file
    clim_suffix = [num2str(yy1), 'to', num2str(yy2)];
    clim_result_fn = [clim_path, 'climatology_front_', clim_suffix, '.nc'];
    clim_temp_mean = ncread(clim_result_fn,'temp_mean');
    lon = ncread(clim_result_fn, 'lon');
    lat = ncread(clim_result_fn, 'lat');
    mask = ncread(clim_result_fn, 'mask');
    %
    frontLength_month = [];
    frontStrength_month = [];
    frontWidth_month = [];
    frontMaxWidth_month = [];
    frontEquivalentWidth_month = [];
    frontArea_month = [];
    frontNumber_month = [];
    average_tgrad_month = [];
    average_sst_month = [];
    for iy = yy1:yy2
        result_fn = [monthly_path, '/monthly_front_', num2str(iy), '.nc'];
        if ~exist(result_fn)
            continue
        end
        temp_mean = ncread(result_fn, 'temp_mean');
        tgrad_mean = ncread(result_fn, 'tgrad_mean');

        % plot monthly mean SST and SST gradient
        
        for im = 1:12
            [tmin, tmax, mm] = set_temp_limit(im, clim_temp_mean);
            disp(num2str(iy))
            disp(num2str(im))
            tgrad_month = squeeze(tgrad_mean(:,:,im));
            sst_month = squeeze(temp_mean(:,:,im));
            average_tgrad = nanmean(tgrad_month(:));
            average_sst = nanmean(sst_month(:));
            average_tgrad_month = cat(1,average_tgrad_month,average_tgrad);
            average_sst_month = cat(1,average_sst_month,average_sst);
            if fig_sst_tgrad
                % SST
                fig_title = ['monthly SST, Unit: \circC'];
                fig_name = [sst_fig_path, '/monthly_sst_', num2str(iy), num2str(im, '%2.2d'), '.png'];
                plot_pcolor_map(lon, lat, squeeze(temp_mean(:, :, im)), tmin, tmax, fig_title, [num2str(iy), num2str(im, '%2.2d')], fig_name, 'sst')
                % tgrad
                fig_title = ['monthly SST gradient, Unit: \circC/km'];
                fig_name = [tgrad_fig_path, '/monthly_tgrad_', num2str(iy), num2str(im, '%2.2d'), '.png'];
                plot_pcolor_map(lon, lat, squeeze(tgrad_mean(:, :, im)), tgrad_min, tgrad_max, fig_title, [num2str(iy), num2str(im, '%2.2d')], fig_name, 'tgrad')
            end
        end

        % concatenate front parameter in each month
        % plot line and see interannual varibility 
        if fig_parameter
            
            frontLength_mean = ncread(result_fn, 'frontLength_mean') * 1e-3;
            frontStrength_mean = ncread(result_fn, 'frontStrength_mean');
            frontWidth_mean = ncread(result_fn, 'frontWidth_mean') * 1e-3;
            frontMaxWidth_mean = ncread(result_fn, 'frontMaxWidth_mean') * 1e-3;
            frontEquivalentWidth_mean = ncread(result_fn, 'frontEquivalentWidth_mean') * 1e-3;
            frontArea_mean = ncread(result_fn, 'frontArea_mean') * 1e-6;
            frontNumber_mean = ncread(result_fn, 'frontNumber_mean');
            %
            frontLength_month = cat(1,frontLength_month,frontLength_mean);
            frontStrength_month = cat(1,frontStrength_month,frontStrength_mean);
            frontWidth_month = cat(1,frontWidth_month,frontWidth_mean);
            frontMaxWidth_month = cat(1,frontMaxWidth_month,frontMaxWidth_mean);
            frontEquivalentWidth_month = cat(1,frontEquivalentWidth_month,frontEquivalentWidth_mean);
            frontArea_month = cat(1,frontArea_month,frontArea_mean);
            frontNumber_month = cat(1,frontNumber_month,frontNumber_mean);

        end
        
    end
    
    month_parameter_matfn = [mat4compare_path,'monthly_front_parameter.mat'];
    save(month_parameter_matfn, ...
        'frontLength_month', ...
        'frontStrength_month', ...
        'frontWidth_month', ...
        'frontArea_month', ...
        'frontNumber_month', ...
        'average_tgrad_month', ...
        'average_sst_month')
    year_label = yy1:yy2;
    year_ticklabel = string(year_label);
    xx = 1:length(frontLength_month);
    year_tick = 1:12:120;

    % average SST
    fig_name = [parameter_fig_path, 'monthly_domain_average_SST_', clim_suffix, '.png'];
    plot_time_series_with_regression(average_sst_month,year_tick,year_ticklabel,'SST (C)',fig_name)
    % average SST gradient
    fig_name = [parameter_fig_path, 'monthly_domain_average_SSTgrad_', clim_suffix, '.png'];
    plot_time_series_with_regression(average_tgrad_month,year_tick,year_ticklabel,'SSTgrad (C/km)',fig_name)

    if fig_parameter
        % 
        % front length  
        fig_name = [parameter_fig_path, 'front_length_monthly_diagnostic_', clim_suffix, '.png'];
        plot_time_series_with_regression(frontLength_month,year_tick,year_ticklabel,'length (km)',fig_name)
        % front strength  
        fig_name = [parameter_fig_path, 'front_strenth_monthly_diagnostic_', clim_suffix, '.png'];
        plot_time_series_with_regression(frontStrength_month,year_tick,year_ticklabel,'strength (C/km)',fig_name)
        % front width  
        fig_name = [parameter_fig_path, 'front_width_monthly_diagnostic_', clim_suffix, '.png'];
        plot_time_series_with_regression(frontWidth_month,year_tick,year_ticklabel,'width (km)',fig_name)
        % front area 
        fig_name = [parameter_fig_path, 'front_area_monthly_diagnostic_', clim_suffix, '.png'];
        plot_time_series_with_regression(frontArea_month,year_tick,year_ticklabel,'Area (km2)',fig_name)
        % front number  
        fig_name = [parameter_fig_path, 'front_number_monthly_diagnostic_', clim_suffix, '.png'];
        plot_time_series_with_regression(frontNumber_month,year_tick,year_ticklabel,'number (#)',fig_name)

        % front width  
        figure
        plot(frontWidth_month,'LineWidth',2,'color','k')
        hold on 
        plot(frontMaxWidth_month,'LineWidth',2,'color','r')
        hold on 
        plot(frontEquivalentWidth_month,'LineWidth',2,'color','b')
        hold on 
        legend('Mean','Max','Equivalent')
        set(gca, 'XTick', year_tick)
        set(gca, 'XTickLabel', year_ticklabel)
        title(['monthly front width diagnostic ', clim_suffix])
        xlabel('year')
        ylabel('km')
        export_fig([parameter_fig_path, 'front_width_monthly_diagnostic_', clim_suffix, '.png'], '-png', '-r200');


        % Normalized
        length_normalize = parameter_normalize(frontLength_month);
        strength_normalize = parameter_normalize(frontStrength_month);
        width_normalize = parameter_normalize(frontWidth_month);
        area_normalize = parameter_normalize(frontArea_month);
        number_normalize = parameter_normalize(frontNumber_month);
        %
        front_parameter_month = cat(2, length_normalize, strength_normalize, width_normalize, area_normalize, number_normalize);
        % combine normalized_parameter into 1 image
        figure
        plot(front_parameter_month,'LineWidth',2)
        legend('Length', 'Strength', 'Width', 'Area', 'Number')
        title([' monthly front parameter'])
        ylabel('Normalized value')
        set(gca, 'XTick', year_tick)
        set(gca, 'XTickLabel', year_ticklabel)
        set(gca, 'YLim', [0 1.3])
        export_fig([parameter_fig_path, 'monthly_front_parameter_', clim_suffix, '.png'], '-png', '-r200');

        close all
        %
    end 

end


function [normalized_var] = parameter_normalize(raw_var)
    % nt = length(raw_var);
    max_value = max(raw_var);
    normalized_var = raw_var / max_value;
end

function plot_pcolor_map(lon, lat, monthly_variable, cmin, cmax, fig_title, fig_text, fig_name, cmap_type)

    global lat_n lat_s lon_w lon_e
    global fig_show
    % set position for text
    X0 = lon_w + 0.05 * (lon_e - lon_w);
    Y0 = lat_s + 0.9 * (lat_n - lat_s);

    % plot monthly frontarea frequency figure
    figure('visible', fig_show)
    m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w lon_e]);
    P = m_pcolor(lon, lat, monthly_variable);
    set(P, 'LineStyle', 'none');
    m_gshhs_i('patch', [.8 .8 .8], 'edgecolor', 'none');
    m_grid('box', 'fancy', 'tickdir', 'in', 'linest', 'none', 'ytick', -10:5:40, 'xtick', 90:5:150);
    if ~isempty(cmin) && ~isempty(cmax)
        caxis([cmin cmax])
    end
    colorbar

    if strcmp(cmap_type, 'sst')
        colormap(jet);
    elseif strcmp(cmap_type, 'tgrad')
        colormap(flipud(m_colmap('Blues')))
    end

    title(fig_title)
    m_text(X0, Y0, fig_text, 'FontSize', 14)
    export_fig(fig_name, '-png', '-r200');
    close all

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
