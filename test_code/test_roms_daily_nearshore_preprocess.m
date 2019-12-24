% nearshore preprocess figure
clc; clear; 
close all;
warning off
opengl software
addpath(genpath('D:\lomf\frontal_detect\frontal_detection\'))
addpath(genpath('D:\matlab_function\m_map\'))
addpath(genpath('D:\matlab_function\export_fig\'))
addpath(genpath('D:\matlab_function\MatlabFns\'))
%
basedir=pwd;

region_type = 'zoom_out';
if strcmp(region_type,'whole')
    lat_s=10; lat_n=25;
    lon_w=105; lon_e=121;
elseif strcmp(region_type,'zoom_out')
    % zoom out exp
    lat_s=11; lat_n=17;
    lon_w=107; lon_e=111;
end
datatype='roms';
fntype = 'avg';
depth = 1;
%
fig_path = [basedir,'\Fig\test\nearshore_preprocess\']; mkdir(fig_path)
data_path = [basedir, '\Data\roms\scs_new\']; mkdir(data_path)
result_path = [basedir, '\Result\test\']; mkdir(result_path)
% preprocess parameter
skip=1;
smooth_type = 'gaussian';
sigma = 2;
N = 2;
fill_value = 0;
% detect parameter
flen_crit=100e3;
thresh_in = [];
% postprocess parameter
logic_morph = 0;

fn_mat_test = [data_path, 'roms_test.mat'];
load(fn_mat_test)
date_str = datestr(grd.time, 'yyyymmdd');

% parameter for figure
fig_test = 0;
line_width = 1;
thresh_max = 0.1;

temp = temp_zl;
[nx, ny] = size(temp_zl);
lon = grd.lon_rho;
lat = grd.lat_rho;
%
%% test nearshore land/ocean mask preprocessing 
% [temp,grd] = roms_preprocess(fn,fntype,grdfn,depth,lon_w,lon_e,lat_s,lat_n,fill_value,skip,date_str);
[temp_zl]=variable_preprocess(temp,'no_smooth',fill_value);
lon = grd.lon_rho;
lat = grd.lat_rho;
mask = grd.mask_rho;
temp(mask == 0) = NaN;
[tgrad, ~] = get_front_variable(temp,grd);
[tgrad_zl, ~] = get_front_variable(temp_zl,grd);
tgrad(mask == 0) = NaN;
%figure: raw SST
figure('visible', 'on')
m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w lon_e]);
P = m_pcolor(lon, lat, temp);
set(P, 'LineStyle', 'none');
shading interp
hold on
grid on
colorbar
colormap(jet);
m_gshhs_i('color','k');
m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:50,'xtick',90:5:140);
m_text(lon_w+0.5,lat_n-1,'raw','FontSize',14)
export_fig([fig_path,region_type,'_raw_sst_',date_str,'.png'], '-png', '-r200');
%
% raw tgrad
figure('visible', 'on')
m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w lon_e]);
P = m_pcolor(lon, lat, tgrad);
set(P, 'LineStyle', 'none');
shading interp
hold on
grid on
colorbar
% colormap(flipud(hot(32))); 
caxis([0 0.1])
m_gshhs_i('color','k');
m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:50,'xtick',90:5:140);
m_text(lon_w+0.5,lat_n-1,'raw','FontSize',14)
export_fig([fig_path,region_type,'_raw_tgrad_',date_str,'.png'], '-png', '-r200');


%figure: extrapolation SST
figure('visible', 'on')
m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w lon_e]);
P = m_pcolor(lon, lat, temp_zl);
set(P, 'LineStyle', 'none');
shading interp
hold on
grid on
colorbar
colormap(jet);
m_gshhs_i('color','k');
m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:50,'xtick',90:5:140);
m_text(lon_w+0.5,lat_n-1,'extrap','FontSize',14)
export_fig( [fig_path,region_type,'_extrap_sst_',date_str,'.png'], '-png', '-r200');

%figure: extrapolation tgrad
figure('visible', 'on')
m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w lon_e]);
P = m_pcolor(lon, lat, tgrad_zl);
set(P, 'LineStyle', 'none');
shading interp
hold on
caxis([0 0.1])
grid on
colorbar
% colormap(flipud(hot(32))); 
m_gshhs_i('color','k');
m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:50,'xtick',90:5:140);
m_text(lon_w+0.5,lat_n-1,'extrap','FontSize',14)
export_fig([fig_path,region_type,'_extrap_tgrad_',date_str,'.png'], '-png', '-r200');



