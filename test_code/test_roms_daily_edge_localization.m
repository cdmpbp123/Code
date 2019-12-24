% edge localization parameter test
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
region_type = 'whole';
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
fig_path = [basedir,'\Fig\test\edge_localization\']; mkdir(fig_path)
result_path = [basedir,'\Data\roms\scs_new\']; mkdir(result_path)
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
[temp_zl]=variable_preprocess(temp,'gaussian',fill_value);
[tgrad, tangle] = get_front_variable(temp_zl,grd);
disp('edge localization...')
global test_morph
test_morph = 1; % set figure test in edge_localization.m
[bw, thresh_out] = edge_localization(temp_zl,tgrad,tangle,thresh_in);
[rj0, cj0, re0, ce0] = findendsjunctions(bw);
%figure setup 
line_width = 1;
fig_test_fn = [fig_path,'sst_frontline_after_localization_',date_str,'.png'];
figure('visible','on')
m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
P=m_pcolor(lon,lat,temp_zl);
set(P,'LineStyle','none');
shading interp
hold on
% frontline pixel overlaid
[segment,fnum] = bwlabel(bw,8);
for ifr = 1:fnum
    [row, col] = find(segment == ifr);
    for ip = 1:length(row)
        plon(ip) = lon(row(ip),col(ip));
        plat(ip) = lat(row(ip),col(ip));
    end
    [x,y] = m_ll2xy(plon,plat);
    scatter(x,y,line_width,'k','fill','o')
    hold on
    clear plon plat x y
    clear row col
end
% with branch points marker
hold on
for ibr = 1: length(rj0)
    plon(ibr) = lon(rj0(ibr),cj0(ibr));
    plat(ibr) = lat(rj0(ibr),cj0(ibr));
end
[x,y] = m_ll2xy(plon,plat);
scatter(x,y,10,'r','fill','o')
%  caxis([15 30])
colorbar
colormap(jet);
m_gshhs_i('patch',[.7 .7 .7],'edgecolor','none');
m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:40,'xtick',90:2:140);
m_text(lon_w+1,lat_n-1,['frontline number: ',num2str(fnum)])
m_text(lon_w+1,lat_n-2,['junction pixels: ',num2str(length(rj0))])
export_fig(fig_test_fn,'-png','-r200');




