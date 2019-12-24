% front occurence frequency in raw grid from yearly concatenated daily data 
close all
clear all
clc
%
platform = 'server197';
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
datatype = 'mercator';
%
yy1 = 2008;
yy2 = 2017;

daily_path = [basedir, './Result/', datatype, '/', domain_name, '/daily/'];
monthly_path = [basedir, './Result/', datatype, '/', domain_name, '/monthly/']; mkdir(monthly_path)
clim_path = [basedir, './Result/', datatype, '/', domain_name, '/climatology/'];mkdir(clim_path)
%
fig_path = [basedir, './Fig/',datatype,'/', domain_name, '/climatology/']; mkdir(fig_path);
grd_fn = [basedir, './Result/', datatype, '/', domain_name, '/',datatype,'_',domain_name,'_grd.nc'];
lon = ncread(grd_fn,'lon');
lat = ncread(grd_fn,'lat');
mask = ncread(grd_fn,'mask');
[nx, ny] = size(mask);
nt = 12;

for iy = yy1:yy2
    result_fn = [monthly_path, '/front_frequency_map_raw_', num2str(iy),'.nc'];
    daily_fn = [daily_path, '/concatenate_front_daily_',num2str(iy),'.nc'];
    if exist(result_fn) || ~exist(daily_fn)
        continue
    end
    datetime = ncread(daily_fn,'datetime');
    bw_line_daily = ncread(daily_fn,'bw_line_daily');
    bw_area_daily = ncread(daily_fn,'bw_area_daily');

    frontarea_freq_map = ones(nx,ny,nt)*NaN;
    frontline_freq_map = ones(nx,ny,nt)*NaN;
    true_frontarea_freq_map = ones(nx,ny,nt)*NaN;
    counter_map = zeros(nx,ny,nt);

    mm_str = datestr(datetime,'mm');
    mm_num = str2num(mm_str);
    for im = 1:12
        % get index for each day of month im
        mm_index = find(mm_num == im);
        disp(num2str(im))
        
        for i = 1:nx
            for j = 1:ny
                
                if mask(i,j) == 1

                    counter_map(i,j,im) = length(mm_index);

                    frontarea_counter_index  = find(bw_area_daily(i,j,mm_index) == 1);
                    frontarea_freq_map(i,j,im) = length(frontarea_counter_index) / length(mm_index);

                    frontline_counter_index  = find(bw_line_daily(i,j,mm_index)==1);
                    frontline_freq_map(i,j,im) = length(frontline_counter_index) / length(mm_index);

                    % "true" front area/line frequency with assumption in function get_detect_validation_score.m
                    % TBD: frontline is hard to deal
                    % first to get true value of frontarea for comparison
                    % thresh_local = high_thresh_daily(mm_index);
                    % mean_thresh = nanmean(thresh_local(:));
                    % true_frontarea_counter_index = find(tgrad_daily(i,j,mm_index) > mean_thresh);
                    % true_frontarea_freq_map(i,j,im) = length(true_frontarea_counter_index) / length(mm_index);

                    clear frontarea_counter_index frontline_counter_index  

                end
                
            end
        end

    end
    % create variable with defined dimension
    nccreate(result_fn,'lon','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn,'lat','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn,'mask','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn, 'counter_map', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'frontarea_freq_map', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'frontline_freq_map', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    % write variable into files
    ncwrite(result_fn, 'lon', lon)
    ncwrite(result_fn, 'lat', lat)
    ncwrite(result_fn, 'mask', mask)
    ncwrite(result_fn, 'counter_map', counter_map)
    ncwrite(result_fn, 'frontarea_freq_map', frontarea_freq_map)
    ncwrite(result_fn, 'frontline_freq_map', frontline_freq_map)
    % write file global attribute
    ncwriteatt(result_fn, '/', 'creation_date', datestr(now))
    ncwriteatt(result_fn, '/', 'description', [datatype,' monthly front frequency map with raw grid in ',num2str(iy)])
    ncwriteatt(result_fn, '/', 'domain', domain_name)
end

