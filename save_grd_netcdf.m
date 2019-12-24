% get NetCDF file for grd
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
fntype = 'daily';


yy1 = 2017;


daily_path = [basedir, './Result/', datatype, '/', domain_name, '/daily/'];
result_path = [basedir, './Result/', datatype, '/', domain_name, '/'];


iy = yy1; im = 1; id = 1;
day_string = [num2str(iy), num2str(im, '%2.2d'), num2str(id, '%2.2d')];
test_fn = [daily_path, '/', num2str(iy), '/mat/detected_front_', day_string, '.mat'];

test_data = load(test_fn);
grd0 = test_data.grd;
%
lon = grd0.lon_rho;
lat = grd0.lat_rho;
mask = grd0.mask_rho;
lon = double(lon);
lat = double(lat);
mask = double(mask);

[nx,ny] = size(mask);

% write to NetCDF file
result_fn = [result_path, '/',datatype,'_',domain_name,'_grd.nc'];
delete(result_fn)
% create variable with defined dimension
nccreate(result_fn,'lon','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','classic')
nccreate(result_fn,'lat','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','classic')
nccreate(result_fn,'mask','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','classic')
% write variable into files
ncwrite(result_fn, 'lon', lon)
ncwrite(result_fn, 'lat', lat)
ncwrite(result_fn, 'mask', mask)
% write file global attribute
ncwriteatt(result_fn, '/', 'creation_date', datestr(now))
ncwriteatt(result_fn, '/', 'domain', domain_name)
ncwriteatt(result_fn, '/', 'data_source', datatype)


