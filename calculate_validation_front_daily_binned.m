% calculate daily front occurence hit-or-miss validation score in each bin with observation OSTIA SST
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

global lat_n lat_s lon_w lon_e
global fig_show
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
yy1 = 2008;
yy2 = 2017;
bin_resolution = 0.5; % unit: degree

ostia_daily_path = [basedir, './Result/ostia/', domain_name, '/daily/'];
daily_path = [basedir, './Result/', datatype, '/', domain_name, '/daily/'];
% clim_path = [basedir, './Result/', datatype, '/', domain_name, '/climatology/'];mkdir(clim_path)
% monthly_path = [basedir, './Result/', datatype, '/', domain_name, '/climatology/'];mkdir(monthly_path)

fig_path = [basedir, './Fig/',datatype,'/', domain_name, '/daily/']; mkdir(fig_path);
fig_show = 'off';
% scores_fig_path = [fig_path,'/scores/']; mkdir(scores_fig_path)
% set bin ratio threshold
bin_area_ratio_thresh = 0.5;
bin_line_ratio_thresh = 0.1;    % TBD: need to auto-change with grid size

for iy = yy1:yy2
    ostia_fn = [ostia_daily_path, '/concatenate_front_daily_binned_',num2str(bin_resolution),'degree_',num2str(iy),'.nc'];
    fn = [daily_path, '/concatenate_front_daily_binned_',num2str(bin_resolution),'degree_',num2str(iy),'.nc'];
    disp(num2str(iy))
    if ~exist(ostia_fn) || ~exist(fn)
        continue
    end
    if mod(iy,4) == 0
        ndays = 366;
    else
        ndays = 365;
    end
    lon_bin = ncread(fn,'lon');
    lat_bin = ncread(fn,'lat');
    mask_bin = ncread(fn,'mask');
    datetime = ncread(fn,'datetime');
    [nx_bin,ny_bin] = size(lon_bin);
    % read binned daily front variable
    ostia_area_ratio = ncread(ostia_fn,'frontarea_ratio_bin');
    model_area_ratio = ncread(fn,'frontarea_ratio_bin');
    
    ostia_datetime = ncread(ostia_fn,'datetime')-datenum(iy,1,1,0,0,0)+1;
    model_datetime = floor(ncread(fn,'datetime'))-datenum(iy,1,1,0,0,0)+1;
    % initial scores timeseries
    area_bias = ones(ndays,1)*NaN;
    area_TS = ones(ndays,1)*NaN;
    area_FAR = ones(ndays,1)*NaN;
    area_MR = ones(ndays,1)*NaN;
    area_FA = ones(ndays,1)*NaN;
    area_DR = ones(ndays,1)*NaN;
    for iday = 1:ndays
        ostia_time_ind = find(iday == ostia_datetime);
        model_time_ind = find(iday == model_datetime);
        if isempty(ostia_time_ind) || isempty(model_time_ind)
            continue
        end
        ostia_area_ratio = ncread(ostia_fn,'frontarea_ratio_bin',[1 1 ostia_time_ind],[Inf Inf 1]);
        model_area_ratio = ncread(fn,'frontarea_ratio_bin',[1 1 model_time_ind],[Inf Inf 1]);
        % ratio to binary
        ostia_area = ratio_to_binary(ostia_area_ratio,bin_area_ratio_thresh);
        model_area = ratio_to_binary(model_area_ratio,bin_area_ratio_thresh);
        %
        [area_bias(iday), area_TS(iday), area_FAR(iday), area_MR(iday), area_FA(iday), area_DR(iday)] = front_skill_score(model_area, ostia_area);
        clear model_area ostia_area
    end

    result_fn = [daily_path,'/validation_score_front_daily_binned_',num2str(bin_resolution),'degree_',num2str(iy),'.nc'];
    delete(result_fn)
    if exist(result_fn)
        continue
    end
    % saving to NetCDF file
    nccreate(result_fn,'lon','Dimensions' ,{'nx' nx_bin 'ny' ny_bin},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn,'lat','Dimensions' ,{'nx' nx_bin 'ny' ny_bin},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn,'mask','Dimensions' ,{'nx' nx_bin 'ny' ny_bin},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn, 'datetime', 'Dimensions', {'nt' ndays}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'area_bias', 'Dimensions', {'nt' ndays}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'area_TS', 'Dimensions', {'nt' ndays}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'area_FAR', 'Dimensions', {'nt' ndays}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'area_MR', 'Dimensions', {'nt' ndays}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'area_FA', 'Dimensions', {'nt' ndays}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'area_DR', 'Dimensions', {'nt' ndays}, 'datatype', 'double', 'format', 'netcdf4_classic')
    % write variable into files
    ncwrite(result_fn, 'lon', lon_bin)
    ncwrite(result_fn, 'lat', lat_bin)
    ncwrite(result_fn, 'mask', mask_bin)
    ncwrite(result_fn, 'datetime', datetime)
    ncwrite(result_fn, 'area_bias', area_bias)
    ncwrite(result_fn, 'area_TS', area_TS)
    ncwrite(result_fn, 'area_FAR', area_FAR)
    ncwrite(result_fn, 'area_MR', area_MR)
    ncwrite(result_fn, 'area_FA', area_FA)
    ncwrite(result_fn, 'area_DR', area_DR)
    % write file global attribute
    ncwriteatt(result_fn, '/', 'creation_date', datestr(now))
    ncwriteatt(result_fn, '/', 'description', [datatype,' validation score daily front with binned grid in ',num2str(iy)])
    ncwriteatt(result_fn, '/', 'domain', domain_name)
    ncwriteatt(result_fn, '/', 'bin_resolution:', num2str(bin_resolution))
end


function binary_var = ratio_to_binary(ratio_var,bin_ratio_thresh)
    binary_var = ratio_var;
    binary_var(binary_var>bin_ratio_thresh) = 1;
    binary_var(binary_var<=bin_ratio_thresh) = 0;
end





