% calculate monthly front-related variable
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
datatype = 'roms';
fntype = 'daily';
depth = 1;
skip = 1;
smooth_type = 'gaussian';
sigma = 2;
N = 2;
fill_value = 0;
%
yy1 = 2008;
yy2 = 2017;
%
daily_path = [basedir, './Result/', datatype, '/', domain_name, '/daily/'];
monthly_path = [basedir, './Result/', datatype, '/', domain_name, '/monthly/']; mkdir(monthly_path)
fig_path = [basedir, './Fig/', datatype, '/', domain_name, '/monthly/']; mkdir(fig_path);
grd_fn = [basedir, './Result/', datatype, '/', domain_name, '/',datatype,'_',domain_name,'_grd.nc'];
lon = ncread(grd_fn,'lon');
lat = ncread(grd_fn,'lat');
mask = ncread(grd_fn,'mask');
[nx, ny] = size(mask);
nt = 12;

for iy = yy1:yy2
    result_fn = [monthly_path, '/monthly_front_', num2str(iy),'.nc'];
    if exist(result_fn)
        continue
    end
    temp_mean = zeros(nx, ny, nt);
    tgrad_mean = zeros(nx, ny, nt);
    % monthly mean front parameter
    frontLength_mean = zeros(nt,1);
    frontStrength_mean = zeros(nt,1);
    frontWidth_mean = zeros(nt,1);
    frontMaxWidth_mean = zeros(nt,1);
    frontEquivalentWidth_mean = zeros(nt,1);
    frontArea_mean = zeros(nt,1);
    frontNumber_mean = zeros(nt,1);
    dayOfMonth = zeros(nt,1);
    for im = 1:nt
        disp([num2str(iy), num2str(im, '%2.2d')])
        iday = 0;
        temp_sum = zeros(nx, ny);
        tgrad_sum = zeros(nx, ny);
        frontNumber = 0;
        frontLength_sum = 0;
        frontStrength_sum = 0;
        frontWidth_sum = 0;
        frontArea_sum = 0;
        frontMaxWidth_sum = 0;
        frontEquivalentWidth_sum = 0;

        for id = 1:31
            day_string = [num2str(iy), num2str(im, '%2.2d'), num2str(id, '%2.2d')];
            fn = [daily_path, '/', num2str(iy), '/mat/detected_front_', day_string, '.mat'];
            if ~exist(fn)
                continue
            else
                iday = iday + 1;
            end

            daily_data = load(fn);
            grd = daily_data.grd;
            temp_zl = daily_data.temp_zl;
            front_parameter = daily_data.front_parameter;
            fnum = length(front_parameter);
            % SST and tgrad diagnostic
            [tgrad, ~] = get_front_variable(temp_zl, grd);
            temp_sum = temp_sum + temp_zl;
            tgrad_sum = tgrad_sum + tgrad;
            % monthly front parameter diagnostic
            for ifr = 1:fnum
                frontLength_sum = frontLength_sum + front_parameter{ifr}.length;
                frontStrength_sum = frontStrength_sum + front_parameter{ifr}.line_tgrad_mean;
                frontWidth_sum = frontWidth_sum + front_parameter{ifr}.mean_width;
                frontMaxWidth_sum = frontMaxWidth_sum + front_parameter{ifr}.max_width;
                frontEquivalentWidth_sum = frontEquivalentWidth_sum + front_parameter{ifr}.equivalent_width;
                frontArea_sum = frontArea_sum + front_parameter{ifr}.area;
            end
            frontNumber = frontNumber + fnum;
        end

        temp_month = temp_sum / iday;
        temp_month(mask == 0 ) = NaN;
        temp_mean(:,:,im) = temp_month;
        tgrad_mean(:,:,im) = tgrad_sum / iday;
        frontNumber_mean(im) = frontNumber / iday;
        dayOfMonth(im) = iday;
        frontLength_mean(im) = frontLength_sum / frontNumber;
        frontStrength_mean(im) = frontStrength_sum / frontNumber;
        frontWidth_mean(im) = frontWidth_sum / frontNumber;
        frontMaxWidth_mean(im) = frontMaxWidth_sum / frontNumber;
        frontEquivalentWidth_mean(im) = frontEquivalentWidth_sum / frontNumber;
        frontArea_mean(im) = frontArea_sum / frontNumber;
        clear iday temp_sum temp_month tgrad_sum frontNumber
        clear frontLength_sum frontStrength_sum frontWidth_sum frontArea_sum frontMaxWidth_sum frontEquivalentWidth_sum
        
    end

    % create variable with defined dimension
    nccreate(result_fn, 'lon', 'Dimensions', {'nx' nx 'ny' ny}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'lat', 'Dimensions', {'nx' nx 'ny' ny}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'mask', 'Dimensions', {'nx' nx 'ny' ny}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'temp_mean', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'tgrad_mean', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'frontNumber_mean', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'dayOfMonth', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'frontLength_mean', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'frontStrength_mean', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'frontWidth_mean', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'frontMaxWidth_mean', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'frontEquivalentWidth_mean', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'frontArea_mean', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'netcdf4_classic')
    % write variable into files
    ncwrite(result_fn, 'lon', lon)
    ncwrite(result_fn, 'lat', lat)
    ncwrite(result_fn, 'mask', mask)
    ncwrite(result_fn, 'temp_mean', temp_mean)
    ncwrite(result_fn, 'tgrad_mean', tgrad_mean)
    ncwrite(result_fn, 'frontLength_mean', frontLength_mean)
    ncwrite(result_fn, 'frontStrength_mean', frontStrength_mean)
    ncwrite(result_fn, 'frontWidth_mean', frontWidth_mean)
    ncwrite(result_fn, 'frontEquivalentWidth_mean', frontEquivalentWidth_mean)
    ncwrite(result_fn, 'frontMaxWidth_mean', frontMaxWidth_mean)
    ncwrite(result_fn, 'frontArea_mean', frontArea_mean)
    ncwrite(result_fn, 'frontNumber_mean', frontNumber_mean)
    ncwrite(result_fn, 'dayOfMonth', dayOfMonth)
    % write file global attribute
    ncwriteatt(result_fn, '/', 'creation_date', datestr(now))
    ncwriteatt(result_fn, '/', 'description', [datatype,' monthly front parameter in ',num2str(iy)])
    ncwriteatt(result_fn, '/', 'domain', domain_name)
    ncwriteatt(result_fn, '/', 'grid_skip_pixels', num2str(skip))
    ncwriteatt(result_fn, '/', 'smooth_type', smooth_type)

end

