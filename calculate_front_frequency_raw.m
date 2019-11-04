% front occurence frequency in raw grid from yearly concatenated daily data 
close all
clear all
clc
%
platform = 'hanyh_laptop';
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
datatype = 'mercator';
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
yy1 = 2018;
yy2 = 2018;

daily_path = [basedir, './Result/', datatype, '/', domain_name, '/daily/'];
clim_path = [basedir, './Result/', datatype, '/', domain_name, '/climatology/'];mkdir(clim_path)
fig_path = [basedir, './Fig/',datatype,'/', domain_name, '/climatology/']; mkdir(fig_path);
grd_fn = [basedir, './Result/', datatype, '/', domain_name, '/',datatype,'_',domain_name,'_grd.nc'];
lon = ncread(grd_fn,'lon');
lat = ncread(grd_fn,'lat');
mask = ncread(grd_fn,'mask');
[nx, ny] = size(mask);
nt = 12;

tgrad_daily = concatenate_front_multipe_years(daily_path, 'tgrad_daily',yy1,yy2);
bw_line_daily = concatenate_front_multipe_years(daily_path, 'bw_line_daily',yy1,yy2);
bw_area_daily = concatenate_front_multipe_years(daily_path, 'bw_area_daily',yy1,yy2);
datetime_daily = concatenate_front_multipe_years(daily_path, 'datetime',yy1,yy2);
low_thresh_daily = concatenate_front_multipe_years(daily_path, 'low_thresh_daily',yy1,yy2);
high_thresh_daily = concatenate_front_multipe_years(daily_path, 'high_thresh_daily',yy1,yy2);
length_thresh_daily = concatenate_front_multipe_years(daily_path, 'length_thresh_daily',yy1,yy2);
%
ndays = length(tgrad_daily);

frontarea_freq_map = ones(nx,ny,nt)*NaN;
frontline_freq_map = ones(nx,ny,nt)*NaN;
true_frontarea_freq_map = ones(nx,ny,nt)*NaN;
counter_map = zeros(nx,ny,nt);
tic
mm_str = datestr(datetime_daily,'mm');
mm_num = str2num(mm_str);
for im = 1:12
    % get index for each day of month im
    mm_index = find(mm_num == im);
    
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
                thresh_local = high_thresh_daily(mm_index);
                mean_thresh = nanmean(thresh_local(:));
                true_frontarea_counter_index = find(tgrad_daily(i,j,mm_index) > mean_thresh);
                true_frontarea_freq_map(i,j,im) = length(true_frontarea_counter_index) / length(mm_index);

                clear frontarea_counter_index frontline_counter_index true_frontarea_counter_index mean_thresh

            end
            
        end
    end
    
end
tt = toc;

result_fn = [clim_path,'front_frequency_map_raw_',num2str(yy1),'to',num2str(yy2),'.nc'];
delete(result_fn)
% create variable with defined dimension
nccreate(result_fn,'lon','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','netcdf4_classic')
nccreate(result_fn,'lat','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','netcdf4_classic')
nccreate(result_fn,'mask','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','netcdf4_classic')
nccreate(result_fn, 'counter_map', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
nccreate(result_fn, 'frontarea_freq_map', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
nccreate(result_fn, 'frontline_freq_map', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
nccreate(result_fn, 'true_frontarea_freq_map', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
% write variable into files
ncwrite(result_fn, 'lon', lon)
ncwrite(result_fn, 'lat', lat)
ncwrite(result_fn, 'mask', mask)
ncwrite(result_fn, 'counter_map', counter_map)
ncwrite(result_fn, 'frontarea_freq_map', frontarea_freq_map)
ncwrite(result_fn, 'frontline_freq_map', frontline_freq_map)
ncwrite(result_fn, 'true_frontarea_freq_map', true_frontarea_freq_map)
% write file global attribute
ncwriteatt(result_fn, '/', 'creation_date', datestr(now))
% ncwriteatt(result_fn, '/', 'time_elapsed(s)', num2str(tt))
ncwriteatt(result_fn, '/', 'description', [datatype,' climatology front frequency map with raw grid'])
ncwriteatt(result_fn, '/', 'domain', domain_name)
ncwriteatt(result_fn, '/', 'smooth_type', smooth_type)
ncwriteatt(result_fn, '/', 'average_time:', ['from ', num2str(yy1), ' to ', num2str(yy2)])