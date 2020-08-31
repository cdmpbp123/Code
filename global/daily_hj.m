% extract daily frontal result to MAT and NetCDF file
% plot SST front figure
% data: 11-year OSTIA daily SST data from 2007-2017
% data path: server197: /work/person/rensh//Data/OSTIA/
close all
clear all
clc
warning off
%
platform = 'hanyh_laptop';

if strcmp(platform, 'hanyh_laptop')
    basedir = 'D:\lomf\frontal_detect\';
    data_path = 'T:\DATA\Model\HJ_global\';
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
end

% add path of toolbox we use
addpath(genpath([toolbox_path, '/export_fig/']))
addpath(genpath([toolbox_path, '/m_map/']))
addpath(genpath([toolbox_path, '/MatlabFns/']))
addpath(genpath([basedir, '/frontal_detection/']))

domain = 3; % choose SCS domain for front diagnostic
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
        domain_name = 'global';
        lat_s = -75; lat_n = 75;
        lon_w = -180; lon_e = 180;
end

fig_path = [basedir, './Fig/global/daily/']; mkdir(fig_path);
result_path = [basedir, './Result/global/daily/']; mkdir(result_path)
% preprocess parameter
datatype = 'hj_global';
fntype = 'daily';
depth = 1;
skip = 1;
smooth_type = 'gaussian';
sigma = 2;
N = 2;
fill_value = 0;
% detect parameter
% flen_crit = 0;
flen_crit = []; % auto-thresh for length
thresh_in = [];
% postprocess parameter
logic_morph = 0;
%

fn = [data_path,'HOTEMG2020031712-000.nc'];

[temp, grd] = hj_global_preprocess(fn, lon_w, lon_e, lat_s, lat_n);
[temp_zl] = variable_preprocess(temp, smooth_type, fill_value);
[tgrad, tangle] = get_front_variable(temp_zl,grd);
lon = grd.lon_rho;
lat = grd.lat_rho;
mask = grd.mask_rho;

fig_sst = 1;
fig_tgrad = 1;
line_width = 1;
thresh_max = 0.1;
fig_show = 'on';
%plot figure
if fig_tgrad
    fig_name = [fig_path,datatype,'_tgrad.png'];
    % set position for text
    X0 = lon_w + 0.05 * (lon_e - lon_w);
    Y0 = lat_s + 0.9 * (lat_n - lat_s);
    % plot monthly frontarea frequency figure
    figure('visible', fig_show)
    m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w-100 lon_e-100]);
    P = m_pcolor(lon, lat, tgrad);
    set(P, 'LineStyle', 'none');
    m_coast('patch', [.8 .8 .8], 'edgecolor', 'none'); 
    m_grid('box', 'fancy', 'tickdir', 'in', 'linest', 'none', 'ytick', -60:30:60, 'xtick', lon_w-100:60:lon_e-100);
    caxis([0 0.1])
    colorbar
    colormap(jet);
    title('SST front of HJ global forecast 20200316')
    export_fig(fig_name, '-png', '-r200');

end

