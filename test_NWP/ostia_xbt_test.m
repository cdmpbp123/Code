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
    data_path = 'D:\lomf\frontal_detect\Data\ostia\';
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

domain = 4; % choose North Western Pacific
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
    case 4
        % ROMS model domain, include part of NWP
        domain_name = 'NWP';
        lat_s = -5; lat_n = 50;
        lon_w = 99; lon_e = 160;
end

data_path = 'D:\lomf\frontal_detect\Data\ostia\2017\';
fig_path = ['D:\lomf\frontal_detect\Code\test_xbt\']; mkdir(fig_path);
result_path = fig_path; mkdir(result_path)
% preprocess parameter
datatype = 'ostia';
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


iy = 2017;
im = 2;
id = 13;

day_string = [num2str(iy), num2str(im, '%2.2d'), num2str(id, '%2.2d')]
fn = [data_path, day_string, '-UKMO-L4HRfnd-GLOB-v01-fv02-OSTIA.nc'];
mat_fn = [result_path, 'detected_front_', day_string, '.mat'];
nc_fn = [result_path,'detected_front_',day_string,'.nc'];
% if ~exist(fn) ||  exist(nc_fn) || exist(mat_fn)
%     continue
% end

[temp, grd] = ostia_preprocess(fn, lon_w, lon_e, lat_s, lat_n);
[temp_zl] = variable_preprocess(temp, smooth_type, fill_value);
[tfrontline, bw_line, thresh_out, tgrad, tangle] = front_line(temp_zl, thresh_in, grd, flen_crit, logic_morph);
fnum = length(tfrontline);
[tfrontarea, bw_area] = front_area(tfrontline, tgrad, tangle, grd, thresh_out);
[front_parameter] = cal_front_parameter(tfrontline, tfrontarea, grd);
% dump output
dump_front_stats('MAT', mat_fn, ...
    bw_line, bw_area, temp_zl, ...
    grd, tfrontline, tfrontarea, front_parameter, ...
    thresh_out, skip, flen_crit, ...
    datatype, smooth_type, fntype)
% NetCDF output
dump_front_stats('netcdf', nc_fn, ...
    bw_line, bw_area, temp_zl, ...
    grd, tfrontline, tfrontarea, front_parameter, ...
    thresh_out, skip, flen_crit, ...
    datatype, smooth_type, fntype)
% % plot figures
% fig_type = 'front_product';
% fig_show = 'off';

% plot_front_figure(lon_w, lon_e, lat_s, lat_n, fig_fn, ...
%     bw_line, bw_area, temp_zl, ...
%     grd, tfrontline, tfrontarea, front_parameter, ...
%     datatype, fig_type, fig_show);
% close all

% flen_crit = front_length_values(kk);
% plot product figure with frontline and frontarea
% [tfrontline, bw_final, thresh_out, tgrad, tangle] = front_line(temp_zl, thresh_in, grd, flen_crit, logic_morph);
% fnum = length(tfrontline);
% [tfrontarea, bw_area] = front_area(tfrontline, tgrad, tangle, grd, thresh_out);

high_thresh = thresh_out(2);
[nx, ny] = size(temp_zl);
lon = grd.lon_rho;
lat = grd.lat_rho;

fig_fn = [fig_path, 'ostia_front_product_', day_string, '.png'];
% sst+ line + zones
figure('visible', 'on')
m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w lon_e]);
P = m_pcolor(lon, lat, temp_zl);
set(P, 'LineStyle', 'none');
shading interp
hold on
% frontline pixel overlaid
for ifr = 1:fnum

    for ip = 1:length(tfrontline{ifr}.row)
        plon(ip) = lon(tfrontline{ifr}.row(ip), tfrontline{ifr}.col(ip));
        plat(ip) = lat(tfrontline{ifr}.row(ip), tfrontline{ifr}.col(ip));
        lon_left(ip) = tfrontarea{ifr}{ip}.lon(1);
        lat_left(ip) = tfrontarea{ifr}{ip}.lat(1);
        lon_right(ip) = tfrontarea{ifr}{ip}.lon(end);
        lat_right(ip) = tfrontarea{ifr}{ip}.lat(end);
    end

    poly_lon = [lon_left fliplr(lon_right)];
    poly_lat = [lat_left fliplr(lat_right)];
    m_patch(poly_lon, poly_lat, [.7 .7 .7], 'FaceAlpha', .7, 'EdgeColor', 'none')
    hold on
    m_plot(plon, plat, 'k', 'LineWidth', 1)
    hold on
    clear poly_lon poly_lat
    clear lon_left lat_left lon_right lat_right
    clear plon plat
end

colorbar
colormap(jet);
caxis([10 30])
m_gshhs_i('patch', [1 1 1], 'edgecolor', 'none');
m_grid('box', 'fancy', 'tickdir', 'in', 'linest', 'none', 'ytick', 0:5:60, 'xtick', 90:10:180);
% flen_crit_str = num2str(flen_crit * 1e-3, '%3.3d');
% title(['length threshold = ', num2str(flen_crit * 1e-3), ' km'])
% m_text(lon_w + 1, lat_n - 1, text_mark_fig{kk}, 'FontSize', 14)
export_fig(fig_fn, '-png', '-r300');

% tgrad + line 
tgrad_new = tgrad;
tgrad_new(tgrad_new<high_thresh) = NaN;
fig_fn = [fig_path, 'ostia_tgrad_line_', day_string, '.png'];
figure('visible', 'on')
m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w lon_e]);
P = m_pcolor(lon, lat, tgrad_new);
set(P, 'LineStyle', 'none');
shading interp
hold on
% frontline pixel overlaid
for ifr = 1:fnum

    for ip = 1:length(tfrontline{ifr}.row)
        plon(ip) = lon(tfrontline{ifr}.row(ip), tfrontline{ifr}.col(ip));
        plat(ip) = lat(tfrontline{ifr}.row(ip), tfrontline{ifr}.col(ip));
        lon_left(ip) = tfrontarea{ifr}{ip}.lon(1);
        lat_left(ip) = tfrontarea{ifr}{ip}.lat(1);
        lon_right(ip) = tfrontarea{ifr}{ip}.lon(end);
        lat_right(ip) = tfrontarea{ifr}{ip}.lat(end);
    end

    % poly_lon = [lon_left fliplr(lon_right)];
    % poly_lat = [lat_left fliplr(lat_right)];
    % m_patch(poly_lon, poly_lat, [.7 .7 .7], 'FaceAlpha', .7, 'EdgeColor', 'none')
    hold on
    m_plot(plon, plat, 'k', 'LineWidth', 1)
    hold on
    % clear poly_lon poly_lat
    % clear lon_left lat_left lon_right lat_right
    clear plon plat
end

colorbar
colormap(jet);
caxis([high_thresh 0.1])
m_gshhs_i('patch', [0.8 0.8 0.8], 'edgecolor', 'none');
m_grid('box', 'fancy', 'tickdir', 'in', 'linest', 'none', 'ytick', 0:5:60, 'xtick', 90:10:180);
% flen_crit_str = num2str(flen_crit * 1e-3, '%3.3d');
% title(['length threshold = ', num2str(flen_crit * 1e-3), ' km'])
% m_text(lon_w + 1, lat_n - 1, text_mark_fig{kk}, 'FontSize', 14)
export_fig(fig_fn, '-png', '-r300');