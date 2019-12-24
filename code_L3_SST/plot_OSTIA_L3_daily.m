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
    data_path = 'E:\DATA\Obs\SST_GLO_L3_NRT_OBSERVATIONS_010_010\';
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
global lat_n lat_s lon_w lon_e
global fig_show
L3_fig_path = [basedir, './Fig/L3_ostia/', domain_name, '/daily/']; mkdir(L3_fig_path);
L4_fig_path = [basedir, './Fig/L4_ostia/', domain_name, '/daily/']; mkdir(L4_fig_path);
fig_show = 'off';
result_path = [basedir, './Result/L3_ostia/', domain_name, '/daily/']; mkdir(result_path)

monthly_path = [basedir, './Result/', 'ostia', '/', domain_name, '/monthly/']; mkdir(monthly_path)
% preprocess parameter
% datatype = 'L3_ostia';
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
yy1 = 2012;
yy2 = 2013;

for iy = yy1:yy2
    L3_year_fig_path = [L3_fig_path, num2str(iy), '/']; mkdir(L3_year_fig_path)
    L4_year_fig_path = [L4_fig_path, num2str(iy), '/']; mkdir(L4_year_fig_path)
    result_fn = [monthly_path, '/monthly_front_', num2str(iy), '.nc'];
    if ~exist(result_fn)
        continue
    end
    temp_mean = ncread(result_fn, 'temp_mean');

    for im = 8:8
        [tmin, tmax, mm] = set_temp_limit(im, temp_mean);
        for id = 1:31
            day_string = [num2str(iy), num2str(im, '%2.2d'), num2str(id, '%2.2d')]
            ostia_path = [data_path, num2str(iy), '/'];
            fn = [ostia_path, day_string, '-IFR-L3C_GHRSST-SSTsubskin-ODYSSEA-GLOB_010_adjusted-v2.0-fv1.0.nc'];
            if ~exist(fn) 
                continue
            end
            [temp, grd] = ostia_L3_preprocess(fn, lon_w, lon_e, lat_s, lat_n);
            temp(temp == 0) = NaN;
            lon = grd.lon_rho;
            lat = grd.lat_rho;
            mask = grd.mask_rho;
            fig_title = ['OSTIA L3'];
            fig_text = day_string;
            fig_name = [L3_year_fig_path,'OSTIA_L3_sst_',day_string,'.png'];
            cmap_type ='sst';
            plot_pcolor_map(lon, lat, temp, tmin, tmax, fig_title, fig_text, fig_name, cmap_type)
            
            ostia_result_path = [basedir, './Result/ostia/', domain_name, '/daily/',num2str(iy), '/mat/']; 
            ostiaL4_fn = [ostia_result_path, 'detected_front_',day_string, '.mat'];
            fn_data = load(ostiaL4_fn);
            lon = fn_data.grd.lon_rho;
            lat = fn_data.grd.lat_rho;
            mask = fn_data.grd.mask_rho;
            temp = fn_data.temp_zl;
            fig_title = ['OSTIA L4'];
            fig_text = day_string;
            fig_name = [L4_year_fig_path,'OSTIA_L4_sst_',day_string,'.png'];
            cmap_type ='sst';
            plot_pcolor_map(lon, lat, temp, tmin, tmax, fig_title, fig_text, fig_name, cmap_type)

        end

    end

end


function plot_pcolor_map(lon, lat, daily_variable, cmin, cmax, fig_title, fig_text, fig_name, cmap_type)

    global lat_n lat_s lon_w lon_e
    global fig_show
    % set position for text
    X0 = lon_w + 0.05 * (lon_e - lon_w);
    Y0 = lat_s + 0.9 * (lat_n - lat_s);

    % plot monthly frontarea frequency figure
    figure('visible', fig_show)
    m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w lon_e]);
    P = m_pcolor(lon, lat, daily_variable);
    set(P, 'LineStyle', 'none');
    m_gshhs_i('patch', [.8 .8 .8], 'edgecolor', 'none');
    m_grid('box', 'fancy', 'tickdir', 'in', 'linest', 'none', 'ytick', -10:5:40, 'xtick', 90:5:150);
    if ~isempty(cmin) && ~isempty(cmax)
        caxis([cmin cmax])
    end
    colorbar

    if strcmp(cmap_type, 'sst')
        colormap(jet);
    elseif strcmp(cmap_type, 'tgrad')
        colormap(flipud(m_colmap('Blues')))
    end

    title(fig_title)
    m_text(X0, Y0, fig_text, 'FontSize', 14)
    export_fig(fig_name, '-png', '-r200');
    close all

end