% test frontal direction 
clc; 
clear all;
close all;
warning off
opengl software
addpath(genpath('D:\lomf\frontal_detect\frontal_detection\'))
addpath(genpath('D:\matlab_function\m_map\'))
addpath(genpath('D:\matlab_function\export_fig\'))
addpath(genpath('D:\matlab_function\MatlabFns\'))
%
basedir=pwd;
% global fn fntype grdfn depth date_str datatype
% global fig_path result_path
% global fill_value flen_crit thresh_in logic_morph
% global lon_w lon_e lat_s lat_n
roms_path = 'E:\DATA\Model\ROMS\scs_new\';
grdfn = [roms_path,'scs_grd.nc'];
lat_s=10; lat_n=25;
lon_w=105; lon_e=121;
datatype='roms';
fntype = 'avg';
depth = 1;
%
fig_path = [basedir,'\Fig\test\grad_direction\']; mkdir(fig_path)
% preprocess parameter
skip=1;
smooth_type = 'gaussian';
sigma = 2;
N = 2;
fill_value = 0;
% detect parameter
flen_crit=100e3;
thresh_in = [];
thresh_max = 0.1;
% postprocess parameter
logic_morph = 0;
% daily
iy = 2015
im = 1
id = 30
fn = [roms_path,'scs_avg_',num2str(iy),'.nc'];
dnum = datenum(iy,im,id,0,0,0);
date_str = datestr(dnum,'yyyymmdd');
%
[temp,grd] = roms_preprocess(fn,fntype,grdfn,depth,lon_w,lon_e,lat_s,lat_n,fill_value,skip,date_str);
lon = grd.lon_rho;
lat = grd.lat_rho;
[temp_zl] = variable_preprocess(temp,'gaussian',fill_value);
[tgrad, tangle] = get_front_variable(temp_zl,grd);
tgrad(tgrad>thresh_max) = thresh_max;
%calculate component of along-front direction
txgrad = tgrad .* cosd(tangle+90);
tygrad = tgrad .* sind(tangle+90);
%figure parameter for gradient magnitude and front direction
uv_interval = 5;
vecscl = 0.5;
headlength = 2;
shaftwidth = 0.3;
% set data skip for figure
lon1 = lon(1:uv_interval:end,1:uv_interval:end);
lat1 = lat(1:uv_interval:end,1:uv_interval:end);
txgrad1 = txgrad(1:uv_interval:end,1:uv_interval:end);
tygrad1 = tygrad(1:uv_interval:end,1:uv_interval:end);
tgrad1 = tgrad(1:uv_interval:end,1:uv_interval:end);
% front direction + magnitude
figure('visible','on')
m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
P = m_pcolor(lon,lat,tgrad);
set(P,'LineStyle','none');
shading interp
hold on
colorbar
% colormap(flipud(hot(32)));
colormap(flipud(m_colmap('Blues')))
caxis([0 thresh_max])
m_gshhs_i('patch',[.7 .7 .7],'edgecolor','none');
m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:40,'xtick',90:2:140);
hpv4 = m_vec(vecscl,lon1,lat1,txgrad1,tygrad1, ...
    'shaftwidth',shaftwidth,...
    'headlength', headlength,...
    'edgeclip','on');
[hpv5, htv5] = m_vec(vecscl,lon_w+1,lat_n-1,0.05,0,'k',...
    'key', '0.05\circC/km',...
    'shaftwidth',shaftwidth,...
    'headlength', headlength,...
    'edgeclip','on');
set(htv5,'FontSize',12);
export_fig([fig_path,'gradient_direction_',date_str,'.png'],'-png','-r200');
% zoom figure
figure('visible','on')
m_proj('Miller','lat',[10 22],'lon',[105 112]);
P = m_pcolor(lon,lat,tgrad);
set(P,'LineStyle','none');
shading interp
hold on
colorbar
% colormap(flipud(hot(32)));
colormap(flipud(m_colmap('Blues')))
caxis([0 thresh_max])
m_gshhs_i('patch',[.7 .7 .7],'edgecolor','none');
m_grid('box','fancy','tickdir','in','linest','none','ytick',0:1:40,'xtick',90:1:140);
hpv4 = m_vec(vecscl,lon1,lat1,txgrad1,tygrad1, ...
    'shaftwidth',shaftwidth,...
    'headlength', headlength,...
    'edgeclip','on');
[hpv5, htv5] = m_vec(vecscl,lon_w+0.3,lat_s+2,0.05,0,'k',...
    'key', '0.05\circC/km',...
    'shaftwidth',shaftwidth,...
    'headlength', headlength,...
    'edgeclip','on');
set(htv5,'FontSize',12);
export_fig([fig_path,'west_zoom_gradient_direction_',date_str,'.png'],'-png','-r200');




