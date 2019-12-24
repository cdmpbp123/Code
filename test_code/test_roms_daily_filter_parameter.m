% filter parameter test for ROMS daily data
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
global fntype depth datatype date_str
global fig_path result_path
global fill_value flen_crit thresh_in logic_morph
global lon_w lon_e lat_s lat_n

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
fig_path = [basedir,'\Fig\test\preprocess\']; mkdir(fig_path)
data_path = [basedir, '\Data\roms\scs_new\']; mkdir(data_path)
result_path = [basedir, '\Result\test\']; mkdir(result_path)
% preprocess parameter
skip=1;
smooth_type = 'gaussian';
sigma = 2;
N = 2;
fill_value = 0;
% detect parameter
% flen_crit=100e3;
 flen_crit=0e3;  % close flen_crit 

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

% filter parmater experiment list:
% exp_name  smooth_type   parameter   front_pixel_number   continuity_index   mean_frontline_length
%   exp0    no_smooth       --       
%   exp1    gaussian      sigma=2       
%   exp2    gaussian      sigma=4
%   exp3    gaussian      sigma=8  
%   exp4    average       3*3
%   exp5    average       5*5     
%   
% function [front_pixel, fnum, mean_frontline_length, continuity_index] = preprocess_test(temp,grd,exp_name,smooth_type,sigma,N)
[front_pixel, front_num, mean_frontline_length, continuity_index] = preprocess_test(temp,grd,'exp0','no_smooth',2,2);
row_exp0 = [front_pixel, front_num, mean_frontline_length, continuity_index];
clear front_pixel front_num mean_frontline_length continuity_index
[front_pixel, front_num, mean_frontline_length, continuity_index] = preprocess_test(temp,grd,'exp1','gaussian',2,2);
row_exp1 = [front_pixel, front_num, mean_frontline_length, continuity_index];
clear front_pixel front_num mean_frontline_length continuity_index
[front_pixel, front_num, mean_frontline_length, continuity_index] = preprocess_test(temp,grd,'exp2','gaussian',4,2);
row_exp2 = [front_pixel, front_num, mean_frontline_length, continuity_index];
clear front_pixel front_num mean_frontline_length continuity_index
[front_pixel, front_num, mean_frontline_length, continuity_index] = preprocess_test(temp,grd,'exp3','gaussian',8,2);
row_exp3 = [front_pixel, front_num, mean_frontline_length, continuity_index];
clear front_pixel front_num mean_frontline_length continuity_index
[front_pixel, front_num, mean_frontline_length, continuity_index] = preprocess_test(temp,grd,'exp4','average',2,1);
row_exp4 = [front_pixel, front_num, mean_frontline_length, continuity_index];
clear front_pixel front_num mean_frontline_length continuity_index
[front_pixel, front_num, mean_frontline_length, continuity_index] = preprocess_test(temp,grd,'exp5','average',2,2);
row_exp5 = [front_pixel, front_num, mean_frontline_length, continuity_index];
clear front_pixel front_num mean_frontline_length continuity_index


disp('test')

function [front_pixel, fnum, mean_frontline_length, continuity_index] = preprocess_test(temp,grd,exp_name,smooth_type,sigma,N)

%set global variable
global fntype depth datatype date_str
global fig_path result_path
global fill_value flen_crit thresh_in logic_morph
global lon_w lon_e lat_s lat_n
%

[temp_zl] = variable_preprocess(temp,smooth_type,fill_value,sigma,N);  
[tfrontline,bw_final,thresh_out,tgrad,tangle] = front_line(temp_zl,thresh_in,grd,flen_crit,logic_morph);

[info_area,tfrontarea] = front_area(tfrontline,tgrad,tangle,grd,thresh_out);

low_thresh = thresh_out(1);
high_thresh = thresh_out(2);
% figure setup
fig_sst_frontline = 1;
fig_tgrad_frontarea = 1;
fig_sst_contour = 1;
line_width = 1;
lon = grd.lon_rho;
lat = grd.lat_rho;


fnum = length(tfrontline);
front_pixel = length(find(bw_final(:)==1));
frontLength = zeros(fnum,1);
for ifr = 1:fnum
    frontLength(ifr,1) = tfrontline{ifr}.flen*1e-3;
end
mean_frontline_length = mean(frontLength);
continuity_index = 0;


fig_test_path = [fig_path,'/',exp_name,'/']; mkdir(fig_test_path)
minT=floor(nanmin(temp_zl(:)));
maxT=ceil(nanmax(temp_zl(:)));
L=minT:0.5:maxT;
LL=minT:2:maxT;
if fig_sst_contour
    % figure : sst_with_contour
    temp_zl(grd.mask_rho == 0) = NaN;
    figure('visible', 'off')
    m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w lon_e]);
    P = m_pcolor(lon, lat, temp_zl);
    set(P, 'LineStyle', 'none');
    shading interp
    hold on
    [C1,h1]=m_contour(lon, lat, temp_zl, L,'k');
    clabel(C1,h1,LL,'fontsize',10,'color','w','Rotation',0,'LabelSpacing',200,'LineWidth',0.5)
    hold on
    grid on
    colorbar
    colormap(jet)
    m_gshhs_i('patch', [.7 .7 .7], 'edgecolor', 'none');
    m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:50,'xtick',90:5:140);
    caxis([minT maxT])
    m_text(lon_w+0.5,lat_s+2,date_str,'FontSize',12)
    m_text(lon_w+1,lat_n-1,exp_name,'FontSize',14)
    export_fig([fig_test_path,'sst_contour_',date_str,'.png'], '-png', '-r200');
end

if fig_sst_frontline
    % figure : sst + frontline
    temp_zl(grd.mask_rho == 0) = NaN;
    figure('visible', 'off')
    m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w lon_e]);
    P = m_pcolor(lon, lat, temp_zl);
    set(P, 'LineStyle', 'none');
    shading interp
    hold on
    % frontline pixel overlaid
    for ifr = 1:fnum
        for ip = 1:length(tfrontline{ifr}.row)
            plon(ip) = tfrontline{ifr}.lon(ip);
            plat(ip) = tfrontline{ifr}.lat(ip);
        end
        m_plot(plon,plat,'k','LineWidth',line_width)
        hold on
        clear plon plat
    end
    %  caxis([15 30])
    grid on
    colorbar
    colormap(jet);
    m_gshhs_i('patch', [.7 .7 .7], 'edgecolor', 'none');
    m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:50,'xtick',90:5:140);
    m_text(lon_w+0.5,lat_s+2,date_str,'FontSize',12)
    m_text(lon_w+1,lat_n-1,exp_name,'FontSize',14)
    export_fig([fig_test_path,'roms_sst_frontline_',date_str,'.png'], '-png', '-r200');
end

if fig_tgrad_frontarea
    % figure : tgrad + frontarea
    tgrad(grd.mask_rho == 0) = NaN;
    figure('visible', 'off')
    m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w lon_e]);
    P = m_pcolor(lon, lat, tgrad);
    set(P, 'LineStyle', 'none');
    shading interp
    hold on
    % frontline pixel overlaid
    for ifr = 1:fnum
        for ip = 1:length(tfrontline{ifr}.row)
            plon(ip) = tfrontline{ifr}.lon(ip);
            plat(ip) = tfrontline{ifr}.lat(ip);
            lon_left(ip) = tfrontarea{ifr}{ip}.lon(1);
            lat_left(ip) = tfrontarea{ifr}{ip}.lat(1);
            lon_right(ip) = tfrontarea{ifr}{ip}.lon(end);
            lat_right(ip) = tfrontarea{ifr}{ip}.lat(end);
        end
        m_plot(plon,plat,'k','LineWidth',line_width)
        hold on
        clear plon plat
        [x,y] = m_ll2xy(lon_left,lat_left);
        scatter(x,y,2,'b','fill','o')
        clear x y
        hold on
        [x,y] = m_ll2xy(lon_right,lat_right);
        scatter(x,y,2,'b','fill','o')
        hold on
    end
    grid on
    colorbar
    caxis([0.01 0.1])
    colormap(flipud(hot(32)));   
    m_gshhs_i('patch', [.7 .7 .7], 'edgecolor', 'none');
    m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:50,'xtick',90:5:140);
    m_text(lon_w+0.5,lat_s+2,date_str,'FontSize',12)
    m_text(lon_w+1,lat_n-1,exp_name,'FontSize',14)
    export_fig([fig_test_path,'roms_tgrad_frontline_',date_str,'.png'], '-png', '-r200');
end
close all


end


