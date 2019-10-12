% concatenate daily file into yearly file
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

yy1 = 2018;
yy2 = 2018;

daily_input_path = [basedir, './Result/mercator/',domain_name,'/daily/'];
result_path = [basedir,'./Result/mercator/',domain_name,'/climatology/'];mkdir(result_path)
clim_result_fn = [result_path,'/mercator_front_monthly_climatology_',smooth_type,'_',num2str(yy1),'to',num2str(yy2),'.nc'];

% read
lon = ncread(clim_result_fn, 'lon');
lat = ncread(clim_result_fn, 'lat');
mask = ncread(clim_result_fn, 'mask');
temp_mean = ncread(clim_result_fn, 'temp');
tgrad_mean = ncread(clim_result_fn, 'tgrad');
low_thresh_month = ncread(clim_result_fn, 'LowThresh');
high_thresh_month = ncread(clim_result_fn, 'HighThresh');

[nx, ny] = size(lon);
% tgrad_daily = zeros()
iday = 0;
tic
for iy = yy1:yy2
    
    fn = dir([daily_input_path,'/',num2str(iy), '/detected_front*.mat']);
    nt = length(fn);
    tgrad_daily = zeros(nx,ny,nt);
    bw_daily = zeros(nx,ny,nt);
    datetime = zeros(nt,1);
    low_thresh_daily = zeros(nt,1);
    high_thresh_daily = zeros(nt,1);
    for im = 1:12
        
        for id = 1:31
            day_string = [num2str(iy), num2str(im, '%2.2d'), num2str(id, '%2.2d')];
            fn = [daily_input_path,'/',num2str(iy), '/detected_front_', day_string, '.mat'];
            
            if ~exist(fn)
                continue
            end
            iday = iday +1;
            daily_data = load(fn);
            temp_zl = daily_data.temp_zl;
            grd = daily_data.grd;
            bw = daily_data.bw;
            [tgrad, ~] = get_front_variable(temp_zl,grd);
            tgrad_daily(:,:,iday) = tgrad;
            bw_daily(:,:,iday) = bw;
            datetime(iday) = grd.time;
            low_thresh_daily(iday) = daily_data.thresh_out(1);
            high_thresh_daily(iday) = daily_data.thresh_out(2);
  
        end
        
    end
    % write to NetCDF file
    result_fn = [result_path, '/mercator_tgrad_daily_',smooth_type, '_year',num2str(iy),'.nc'];
    delete(result_fn)
    % create variable with defined dimension
    nccreate(result_fn, 'tgrad_daily', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'classic')
    nccreate(result_fn, 'bw_daily', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'classic')
    nccreate(result_fn, 'datetime', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'classic')
    nccreate(result_fn, 'low_thresh_daily', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'classic')
    nccreate(result_fn, 'high_thresh_daily', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'classic')
    % write variable into files
    ncwrite(result_fn, 'tgrad_daily', tgrad_daily)
    ncwrite(result_fn, 'bw_daily', bw_daily)
    ncwrite(result_fn, 'datetime', datetime)
    ncwrite(result_fn, 'low_thresh_daily', low_thresh_daily)
    ncwrite(result_fn, 'high_thresh_daily', high_thresh_daily)
    % write file global attribute
    ncwriteatt(result_fn, '/', 'creation_date', datestr(now))
    ncwriteatt(result_fn, '/', 'data_source', 'Mercator daily output: PSY4V3R1')
    ncwriteatt(result_fn, '/', 'description', ['daily output of year ',num2str(iy)])
    ncwriteatt(result_fn, '/', 'domain', domain_name)
    ncwriteatt(result_fn, '/', 'smooth_type', smooth_type)
    
end








