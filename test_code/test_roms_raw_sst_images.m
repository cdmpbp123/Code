% prepare example SST image for frontal detection test
% used in paper
clc; 
clear all;
close all;
warning off
opengl software
platform = 'hanyh_laptop';
basedir = 'D:\lomf\frontal_detect\';
toolbox_path = 'D:\matlab_function\';

% add path of toolbox we use
addpath(genpath([toolbox_path, '/export_fig/']))
addpath(genpath([toolbox_path, '/m_map/']))
addpath(genpath([toolbox_path, '/MatlabFns/']))
addpath(genpath([basedir, '/frontal_detection/']))

data_path = [basedir,'/Data/roms/scs_new/'];
lat_s=10; lat_n=25;
lon_w=105; lon_e=121;
datatype='roms';
fntype = 'avg';
depth = 1;
%
fig_path = [basedir,'\Fig\test\raw_image\']; mkdir(fig_path)
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

fn_mat_test = [data_path,'roms_test.mat'];
load(fn_mat_test)
dtime_str = datestr(grd.time,'yyyymmdd');

% parameter for figure
line_width = 1;
thresh_max = 0.1;

temp = temp_zl;
[nx, ny] = size(temp_zl);
lon = grd.lon_rho;
lat = grd.lat_rho;
mask = grd.mask_rho;

[temp_zl] = variable_preprocess(temp,smooth_type,fill_value);
[tgrad, tangle] = get_front_variable(temp_zl,grd);
% mask land with grd.mask_rho
temp_zl(mask==0) = NaN;
% SST 
figure('visible','on')
m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
P=m_pcolor(lon,lat,temp_zl);
set(P,'LineStyle','none');
shading interp
hold on
% caxis([15 32])
colorbar
colormap(jet);
m_gshhs_i('patch', [.8 .8 .8], 'edgecolor', 'none');
m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:40,'xtick',90:2:140);
title(['raw sst image'])
% m_text(lon_w+1,lat_n-1,dtime_str)
export_fig([fig_path,'sst_raw_image'],'-png','-r200');

% SST gradient
figure('visible','on')
m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
P=m_pcolor(lon,lat,tgrad);
set(P,'LineStyle','none');
shading interp
hold on
caxis([0 0.1])
colorbar
colormap(jet);
m_gshhs_i('patch', [.8 .8 .8], 'edgecolor', 'none');
m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:40,'xtick',90:2:140);
title(['raw SST gradient image'])
% m_text(lon_w+1,lat_n-1,dtime_str)
export_fig([fig_path,'sst_grad_raw_image'],'-eps','-r300');




