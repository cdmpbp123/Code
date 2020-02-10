% plot monthly climatology SST and RMSE from 2007-2017
close all
clear all
clc
%
platform = 'hanyh_laptop';
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

% domain = 2; % choose SCS domain for front diagnostic
domain = 3; % choose whole model coverage for model test
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
datatype = 'comparison';
smooth_type = 'no_smooth';
yy1 = 2007;
yy2 = 2017;
exp_name1 = 'scs50_hindcast_nudg_new';
exp_name2 = 'scs50_hindcast';
exp_name3 = 'scsnew';
result_path = [basedir, './Result/',datatype,'/', 'model_domain', '/climatology/']; %climatology RMSE data in model_domain path
% input file
fig_path = [basedir, './Fig/',datatype,'/', domain_name, '/climatology/']; mkdir(fig_path);
roms_fig_path1 = [fig_path,'/',exp_name1,'/'];mkdir(roms_fig_path1)
roms_fig_path2 = [fig_path,'/',exp_name2,'/'];mkdir(roms_fig_path2)
roms_fig_path3 = [fig_path,'/',exp_name3,'/'];mkdir(roms_fig_path3)
ostia_fig_path = [fig_path,'/','ostia','/'];mkdir(ostia_fig_path)
mercator_fig_path = [fig_path,'/','mercator','/'];mkdir(mercator_fig_path)
result_fn1 = [result_path, '/',exp_name1,'_sst_rmse_climatology_', smooth_type, '_', num2str(yy1), 'to', num2str(yy2), '.nc'];
result_fn2 = [result_path, '/',exp_name2,'_sst_rmse_climatology_', smooth_type, '_', num2str(yy1), 'to', num2str(yy2), '.nc'];
result_fn3 = [result_path, '/',exp_name3,'_sst_rmse_climatology_', smooth_type, '_', num2str(yy1), 'to', num2str(yy2), '.nc'];
% exist(result_fn)
% figure setup
tmin = 20;
tmax = 32;
rmse_min = 0;
rmse_max = 3;

% plot sst
plot_monthly_map(lon_w,lon_e,lat_s,lat_n,tmin,tmax,result_fn1,'temp_ostia','OSTIA',ostia_fig_path,'sst')
plot_monthly_map(lon_w,lon_e,lat_s,lat_n,tmin,tmax,result_fn1,'temp_roms','ROMS nudging',roms_fig_path1,'sst')
plot_monthly_map(lon_w,lon_e,lat_s,lat_n,tmin,tmax,result_fn2,'temp_roms','ROMS control',roms_fig_path2,'sst')
plot_monthly_map(lon_w,lon_e,lat_s,lat_n,tmin,tmax,result_fn3,'temp_roms','ROMS A4VH',roms_fig_path3,'sst')
plot_monthly_map(lon_w,lon_e,lat_s,lat_n,tmin,tmax,result_fn3,'temp_mercator','Mercator',mercator_fig_path,'sst')
% plot rmse
plot_monthly_map(lon_w,lon_e,lat_s,lat_n,rmse_min,rmse_max,result_fn1,'rmse','ROMS nudging',roms_fig_path1,'rmse')
plot_monthly_map(lon_w,lon_e,lat_s,lat_n,rmse_min,rmse_max,result_fn2,'rmse','ROMS control',roms_fig_path2,'rmse')
plot_monthly_map(lon_w,lon_e,lat_s,lat_n,rmse_min,rmse_max,result_fn3,'roms_rmse','ROMS A4VH',roms_fig_path3,'rmse')
plot_monthly_map(lon_w,lon_e,lat_s,lat_n,rmse_min,rmse_max,result_fn3,'mercator_rmse','Mercator',mercator_fig_path,'rmse')

function plot_monthly_map(lon_w,lon_e,lat_s,lat_n,tmin,tmax,result_fn,varname,title_text,fig_path,type)
    lon = ncread(result_fn, 'lon');
    lat = ncread(result_fn, 'lat');
    mask = ncread(result_fn, 'mask');
    temp = ncread(result_fn, varname);
    % set position for text
    X0 = lon_w + 0.05*(lon_e - lon_w);
    Y0 = lat_s +0.9*(lat_n - lat_s);
    for im = 1:12
        im
        % [tmin,tmax,mm] = set_temp_limit(im,temp_roms);
        [~,~,mm] = set_temp_limit(im);
        temp_month = squeeze(temp(:,:,im));
        figure('visible','off','color',[1 1 1])
        m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
        P=m_pcolor(lon,lat,temp_month);
        set(P,'LineStyle','none');
        shading interp
        hold on
        m_gshhs_i('patch', [.8 .8 .8], 'edgecolor', 'none');
        m_grid('box','fancy','tickdir','in','linest','none','ytick',-10:5:40,'xtick',90:5:150);
        caxis([tmin tmax])
        colorbar
        colormap(jet)
        m_text(X0,Y0,mm,'FontSize',14)
        % title(['climatology OSTIA SST in month ',num2str(im,'%2.2d')])
        title(title_text)
        if strcmp(type,'sst')
            export_fig([fig_path,'sst_month_',num2str(im,'%2.2d')],'-png','-r200');
        elseif strcmp(type,'rmse')
            export_fig([fig_path,'rmse_month_',num2str(im,'%2.2d')],'-png','-r200');
        end
        close all
    end

end