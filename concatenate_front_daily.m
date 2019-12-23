% concatenate daily file into yearly file
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
% preprocess parameter
datatype = 'mercator';
smooth_type = 'gaussian';

yy1 = 2008;
yy2 = 2017;

daily_path = [basedir, './Result/', datatype, '/', domain_name, '/daily/'];
grd_fn = [basedir, './Result/', datatype, '/', domain_name, '/',datatype,'_',domain_name,'_grd.nc'];
lon = ncread(grd_fn,'lon');
lat = ncread(grd_fn,'lat');
mask = ncread(grd_fn,'mask');
[nx, ny] = size(mask);
nt = 12;

% iday = 0;

for iy = yy1:yy2
    result_fn = [daily_path, '/concatenate_front_daily_',num2str(iy),'.nc'];
    if ~exist([daily_path,'/',num2str(iy)]) || exist(result_fn)
        continue
    end
    fn = dir([daily_path,'/',num2str(iy), '/mat/detected_front*.mat']);
    nt = length(fn);
    tgrad_daily = zeros(nx,ny,nt);
    bw_line_daily = zeros(nx,ny,nt);
    bw_area_daily = zeros(nx,ny,nt);
    datetime = zeros(nt,1);
    low_thresh_daily = zeros(nt,1);
    high_thresh_daily = zeros(nt,1);
    length_thresh_daily = zeros(nt,1);
    front_num_daily = zeros(nt,1);
    iday = 0;
    for im = 1:12
        
        for id = 1:31
            day_string = [num2str(iy), num2str(im, '%2.2d'), num2str(id, '%2.2d')]
            fn = [daily_path,'/',num2str(iy), '/mat/detected_front_', day_string, '.mat'];
            
            if ~exist(fn)
                continue
            end
            iday = iday + 1;
            daily_data = load(fn);
            temp_zl = daily_data.temp_zl;
            grd = daily_data.grd;
            front_parameter = daily_data.front_parameter;
            bw_line = daily_data.bw_line;
            bw_area = daily_data.bw_area;
            [tgrad, ~] = get_front_variable(temp_zl,grd);
            %
            tgrad_daily(:,:,iday) = tgrad;
            bw_line_daily(:,:,iday) = bw_line;
            bw_area_daily(:,:,iday) = bw_area;
            datetime(iday) = grd.time;
            low_thresh_daily(iday) = daily_data.thresh_out(1);
            high_thresh_daily(iday) = daily_data.thresh_out(2);
            length_thresh_daily(iday) = daily_data.thresh_out(3);
            front_num_daily(iday) = length(front_parameter); 
            clear daily_data  grd front_parameter 
            clear tgrad temp_zl bw_line bw_area
        end

    end
    % write to NetCDF file
    % create variable with defined dimension
    nccreate(result_fn,'lon','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn,'lat','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn,'mask','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn, 'datetime', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'low_thresh_daily', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'high_thresh_daily', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'length_thresh_daily', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'front_num_daily', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'tgrad_daily', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'bw_line_daily', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'bw_area_daily', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    % write variable into files
    ncwrite(result_fn, 'lon', lon)
    ncwrite(result_fn, 'lat', lat)
    ncwrite(result_fn, 'mask', mask)
    ncwrite(result_fn, 'tgrad_daily', tgrad_daily)
    ncwrite(result_fn, 'bw_line_daily', bw_line_daily)
    ncwrite(result_fn, 'bw_area_daily', bw_area_daily)
    ncwrite(result_fn, 'datetime', datetime)
    ncwrite(result_fn, 'low_thresh_daily', low_thresh_daily)
    ncwrite(result_fn, 'high_thresh_daily', high_thresh_daily)
    ncwrite(result_fn, 'length_thresh_daily', length_thresh_daily)
    ncwrite(result_fn, 'front_num_daily', front_num_daily)
    % write file global attribute
    ncwriteatt(result_fn, '/', 'creation_date', datestr(now))
    ncwriteatt(result_fn, '/', 'description', [datatype,' concatenate front daily output in ',num2str(iy)])
    ncwriteatt(result_fn, '/', 'domain', domain_name)
    ncwriteatt(result_fn, '/', 'smooth_type', smooth_type)
    
end







