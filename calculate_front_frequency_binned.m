% front occurence frequency in regular binned map
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
    data_path = [root_path, '/Data/OSTIA/'];
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
datatype = 'mercator';
smooth_type = 'gaussian';

yy1 = 2008;
yy2 = 2017;

daily_path = [basedir, './Result/', datatype, '/', domain_name, '/daily/'];
monthly_path = [basedir, './Result/', datatype, '/', domain_name, '/monthly/']; mkdir(monthly_path)
clim_path = [basedir, './Result/', datatype, '/', domain_name, '/climatology/'];mkdir(clim_path)
% input file
fig_path = [basedir, './Fig/',datatype,'/', domain_name, '/climatology/']; mkdir(fig_path);
grd_fn = [basedir, './Result/', datatype, '/', domain_name, '/',datatype,'_',domain_name,'_grd.nc'];
lon = ncread(grd_fn,'lon');
lat = ncread(grd_fn,'lat');
mask = ncread(grd_fn,'mask');
[nx, ny] = size(mask);
nt = 12;

% set a new regular grid
bin_resolution = 0.5; % unit: degree
[lon_bin, lat_bin, mask_bin, mask_cell,~] = grid_to_bin(lon,lat,mask,bin_resolution,lon_w,lon_e,lat_s,lat_n);
[nx_bin,ny_bin] = size(lon_bin);

for iy = yy1:yy2
    result_fn = [monthly_path,'front_frequency_map_binned_',num2str(bin_resolution),'degree_',num2str(iy),'.nc'];
    daily_fn = [daily_path, '/concatenate_front_daily_',num2str(iy),'.nc'];
    if exist(result_fn) || ~exist(daily_fn)
        continue
    end
    datetime = ncread(daily_fn,'datetime');
    bw_line_daily = ncread(daily_fn,'bw_line_daily');
    bw_area_daily = ncread(daily_fn,'bw_area_daily');

    frontarea_freq_map = ones(nx_bin,ny_bin,nt)*NaN;
    frontline_freq_map = ones(nx_bin,ny_bin,nt)*NaN;
    counter_map = zeros(nx_bin,ny_bin,nt);

    mm_str = datestr(datetime,'mm');
    mm_num = str2num(mm_str);
    for im = 1:12
        disp([num2str(iy),'_',num2str(im)])
        % get index for each day of month im
        mm_index = find(mm_num == im);
        % high_thresh = high_thresh_month(im);
        
        for ixb = 1:nx_bin
            for iyb = 1:ny_bin
                
                if mask_bin(ixb,iyb) == 1
                    mask_tmp = mask_cell{ixb,iyb};
                    xx_ind = mask_tmp.xx;
                    yy_ind = mask_tmp.yy;
                    nonan_num = mask_tmp.nonan_num;
                    total_valid_counter = length(mm_index)*nonan_num;
                    counter_map(ixb,iyb,im) = total_valid_counter;
                    
                    % detected front area/line frequency
                    frontarea_counter_index  = find(bw_area_daily(xx_ind,yy_ind,mm_index) == 1);
                    frontarea_freq_map(ixb,iyb,im) = length(frontarea_counter_index) / total_valid_counter;
                    %
                    frontline_counter_index  = find(bw_line_daily(xx_ind,yy_ind,mm_index) == 1);
                    frontline_freq_map(ixb,iyb,im) = length(frontline_counter_index) / total_valid_counter;
                    
                    % "true" front area/line frequency with assumption in function get_detect_validation_score.m
                    % TBD: frontline is hard to deal
                    % first to get true value of frontarea for comparison
                    % thresh_local = high_thresh_daily(mm_index);
                    % mean_thresh = nanmean(thresh_local(:));
                    % true_frontarea_counter_index = find(tgrad_daily(xx_ind,yy_ind,mm_index) > mean_thresh);
                    % true_frontarea_freq_map(ixb,iyb,im) = length(true_frontarea_counter_index) / total_valid_counter;
                    
                    clear mask_tmp  xx_ind yy_ind
                    clear frontarea_counter_index frontline_counter_index total_valid_counter
                end
                
            end
        end

    end

    % saving to NetCDF file
    nccreate(result_fn,'lon','Dimensions' ,{'nx' nx_bin 'ny' ny_bin},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn,'lat','Dimensions' ,{'nx' nx_bin 'ny' ny_bin},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn,'mask','Dimensions' ,{'nx' nx_bin 'ny' ny_bin},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn, 'counter_map', 'Dimensions', {'nx' nx_bin 'ny' ny_bin 'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'frontarea_freq_map', 'Dimensions', {'nx' nx_bin 'ny' ny_bin 'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'frontline_freq_map', 'Dimensions', {'nx' nx_bin 'ny' ny_bin 'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')

    % write variable into files
    ncwrite(result_fn, 'lon', lon_bin)
    ncwrite(result_fn, 'lat', lat_bin)
    ncwrite(result_fn, 'mask', mask_bin)
    ncwrite(result_fn, 'counter_map', counter_map)
    ncwrite(result_fn, 'frontarea_freq_map', frontarea_freq_map)
    ncwrite(result_fn, 'frontline_freq_map', frontline_freq_map)
    % write file global attribute
    ncwriteatt(result_fn, '/', 'creation_date', datestr(now))
    % ncwriteatt(result_fn, '/', 'time_elapsed(s)', num2str(tt))
    ncwriteatt(result_fn, '/', 'description', [datatype,' monthly front frequency map with binned grid in ',num2str(iy)])
    ncwriteatt(result_fn, '/', 'domain', domain_name)
    ncwriteatt(result_fn, '/', 'smooth_type', smooth_type)
    ncwriteatt(result_fn, '/', 'bin_resolution:', num2str(bin_resolution))
end



