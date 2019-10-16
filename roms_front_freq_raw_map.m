% front occurence frequency in raw grid for ROMS daily average data
% read yearly concatenated daily data of 2017
close all
clear all
clc
%
platform = 'server197';
if strcmp(platform, 'hanyh_laptop')
    basedir = 'D:\lomf\frontal_detect\';
    data_path = 'E:\DATA\Model\Mercator\Extraction_PSY4V3_SCS\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform, 'PC_office')
    basedir = 'D:\lomf\frontal_detect\';
    data_path = 'E:\DATA\obs\OSTIA\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform, 'server197')
    root_path = '/work/person/rensh/';
    basedir = [root_path, '/front_detect/'];
    data_path = [root_path, '/Data/OSTIA/'];
    toolbox_path = [root_path, '/matlab_function/'];
elseif strcmp(platform, 'mercator_PC')
    root_path = '/homelocal/sauvegarde/sren/';
    basedir = [root_path, '/front_detect/'];
    data_path = [root_path, '/Mercator_data/Model/Extraction_PSY4V3_SCS/'];
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

% preprocess parameter
datatype = 'roms';
fntype = 'daily';
depth = 1;
skip = 1;
smooth_type = 'gaussian';
sigma = 2;
N = 2;
fill_value = 0;
thresh_in = [];
% postprocess parameter
logic_morph = 0;
%
yy1 = 2017;
yy2 = 2017;

result_path = [basedir, './Result/roms/', domain_name, '/climatology/'];
% input file
clim_result_fn = [result_path, '/roms_front_monthly_climatology_', smooth_type, '_', num2str(yy1), 'to', num2str(yy2), '.nc'];
fig_path = [basedir, './Fig/roms/', domain_name, '/climatology/']; mkdir(fig_path);
result_fn = [result_path, '/roms_front_frequency_map_', smooth_type, '_', num2str(yy1), 'to', num2str(yy2), '.nc'];
%
% concat daily data
tgrad_daily = [];
bw_daily =[];
datetime_daily = [];
low_thresh_daily = [];
high_thresh_daily = [];
for yy = yy1:yy2
    daily_result_fn = [result_path, '/roms_tgrad_daily_',smooth_type, '_year',num2str(yy),'.nc'];
    tmp = ncread(daily_result_fn,'tgrad_daily');
    tgrad_daily = cat(3,tgrad_daily,tmp);
    clear tmp
    tmp = ncread(daily_result_fn,'bw_daily');
    bw_daily = cat(3,bw_daily,tmp);
    clear tmp
    tmp = ncread(daily_result_fn,'datetime');
    datetime_daily = cat(3,datetime_daily,tmp);
    clear tmp
    tmp = ncread(daily_result_fn,'low_thresh_daily');
    low_thresh_daily = cat(3,low_thresh_daily,tmp);
    clear tmp
    tmp = ncread(daily_result_fn,'high_thresh_daily');
    high_thresh_daily = cat(3,high_thresh_daily,tmp);
    clear tmp
end
ndays = length(high_thresh_daily);

lon = ncread(clim_result_fn, 'lon');
lat = ncread(clim_result_fn, 'lat');
mask = ncread(clim_result_fn, 'mask');
temp_mean = ncread(clim_result_fn, 'temp');
tgrad_mean = ncread(clim_result_fn, 'tgrad');
low_thresh_month = ncread(clim_result_fn, 'LowThresh');
high_thresh_month = ncread(clim_result_fn, 'HighThresh');

[nx, ny] = size(lon);
nt = 12;
% valida_pixel = length(find(mask(:)==1));
frontarea_freq_map = ones(nx,ny,nt)*NaN;
frontline_freq_map = ones(nx,ny,nt)*NaN;
tic
for im = 1:12
    % get index for each day of month im
    mm_str = datestr(datetime_daily,'mm');
    mm_num = str2num(mm_str);
    mm_index = find(mm_num == im);
    high_thresh = high_thresh_month(im);
    
    for i = 1:nx
        for j = 1:ny
            
            if mask(i,j) == 1
                frontarea_counter_index  = find(tgrad_daily(i,j,mm_index)>high_thresh);
                frontarea_freq_map(i,j,im) = length(frontarea_counter_index) / length(mm_index);
                frontline_counter_index  = find(bw_daily(i,j,mm_index)==1);
                frontline_freq_map(i,j,im) = length(frontline_counter_index) / length(mm_index);

            end
            
        end
    end
    
    frontarea_freq_month = squeeze(frontarea_freq_map(:,:,im));
    % plot monthly frontarea frequency figure
    figure('visible','off','color',[1 1 1])
    m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
    P=m_pcolor(lon,lat,frontarea_freq_month);
    set(P,'LineStyle','none');
    shading interp
    hold on
    m_gshhs_i('patch', [.8 .8 .8], 'edgecolor', 'none');
    m_grid('box','fancy','tickdir','in','linest','none','ytick',-10:5:40,'xtick',90:5:150);
    caxis([0.3 1])
    colorbar
    title(['frontzone frequency map in month ',num2str(im,'%2.2d')])
    export_fig([fig_path,'frontarea_freq_map_month_',num2str(im,'%2.2d')],'-png','-r200');
    close all

    frontline_freq_month = squeeze(frontline_freq_map(:,:,im));
    % plot monthly frontarea frequency figure
    figure('visible','off','color',[1 1 1])
    m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
    P=m_pcolor(lon,lat,frontline_freq_month);
    set(P,'LineStyle','none');
    shading interp
    hold on
    m_gshhs_i('patch', [.8 .8 .8], 'edgecolor', 'none');
    m_grid('box','fancy','tickdir','in','linest','none','ytick',-10:5:40,'xtick',90:5:150);
    caxis([0.1 0.6])
    colorbar
    title(['frontline frequency map in month ',num2str(im,'%2.2d')])
    export_fig([fig_path,'frontline_freq_map_month_',num2str(im,'%2.2d')],'-png','-r200');
    close all
    
end
tt = toc;
save('roms_front_freq_map.mat','frontarea_freq_map','frontline_freq_map')
if 1 == 1
    delete(result_fn)
    % create variable with defined dimension
    nccreate(result_fn, 'frontarea_freq_map', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'classic')
    nccreate(result_fn, 'frontline_freq_map', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'classic')
    % write variable into files
    ncwrite(result_fn, 'frontarea_freq_map', frontarea_freq_map)
    ncwrite(result_fn, 'frontline_freq_map', frontline_freq_map)
    % write file global attribute
    ncwriteatt(result_fn, '/', 'creation_date', datestr(now))
    ncwriteatt(result_fn, '/', 'time_elapsed(s)', num2str(tt))
    ncwriteatt(result_fn, '/', 'data_source', 'roms daily output')
    ncwriteatt(result_fn, '/', 'description', 'front frequency map in raw grid')
    ncwriteatt(result_fn, '/', 'domain', domain_name)
    ncwriteatt(result_fn, '/', 'smooth_type', smooth_type)
    ncwriteatt(result_fn, '/', 'average time span', ['from ', num2str(yy1), ' to ', num2str(yy2)])
end