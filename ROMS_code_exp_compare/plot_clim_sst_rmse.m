% plot monthly climatology SST and RMSE from 2007-2017
% ROMS and OSTIA for now
% TBD: Mercator data 
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
    data_path = 'E:\DATA\obs\OSTIA\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform, 'server197')
    root_path = '/work/person/rensh/';
    basedir = [root_path, '/front_detect/'];
    data_path = [root_path, '/Data/OSTIA/'];
    toolbox_path = [root_path, '/matlab_function/'];
elseif strcmp(platform, 'mercator_PC')
    root_path = '/homelocal/sauvegarde/sren/';
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
fntype = 'daily';
depth = 1;
skip = 1;
smooth_type = 'no_smooth';
sigma = 2;
N = 2;
fill_value = 0;
thresh_in = [];
% postprocess parameter
logic_morph = 0;
%
yy1 = 2007;
yy2 = 2017;
exp_name = 'scs50_hindcast_nudg_new';
% exp_name = 'scs50_hindcast';
result_path = [basedir, './Result/',datatype,'/', 'model_domain', '/climatology/']; %climatology RMSE data in model_domain path
% result_path = [basedir, './Result/',datatype,'/', domain_name, '/climatology/'];
% input file
fig_path = [basedir, './Fig/',datatype,'/', domain_name, '/climatology/']; mkdir(fig_path);
roms_fig_path = [fig_path,'/',exp_name,'/'];mkdir(roms_fig_path)
ostia_fig_path = [fig_path,'/','ostia','/'];mkdir(ostia_fig_path)
result_fn = [result_path, '/',exp_name,'_sst_rmse_climatology_', smooth_type, '_', num2str(yy1), 'to', num2str(yy2), '.nc'];
% exist(result_fn)
lon = ncread(result_fn, 'lon');
lat = ncread(result_fn, 'lat');
mask = ncread(result_fn, 'mask');
temp_ostia = ncread(result_fn, 'temp_ostia');
temp_roms = ncread(result_fn, 'temp_roms');
rmse_roms_ostia = ncread(result_fn, 'rmse');

[nx, ny] = size(lon);
nt = 12;
fig_roms = 1;
fig_ostia = 1;
fig_rmse = 1;
% set position for text
X0 = lon_w + 0.05*(lon_e - lon_w);
Y0 = lat_s +0.9*(lat_n - lat_s);
for im = 1:12
    [tmin,tmax,mm] = set_temp_limit(im,temp_roms);
    disp(['month: ',num2str(im)])
    if fig_ostia 
        temp_ostia_month = squeeze(temp_ostia(:,:,im));
        figure('visible','off','color',[1 1 1])
        m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
        P=m_pcolor(lon,lat,temp_ostia_month);
        set(P,'LineStyle','none');
        shading interp
        hold on
        m_gshhs_i('patch', [.8 .8 .8], 'edgecolor', 'none');
        m_grid('box','fancy','tickdir','in','linest','none','ytick',-10:5:40,'xtick',90:5:150);
        caxis([tmin tmax])
        colorbar
        m_text(X0,Y0,mm,'FontSize',14)
        title(['climatology OSTIA SST in month ',num2str(im,'%2.2d')])
        export_fig([ostia_fig_path,'ostia_sst_month_',num2str(im,'%2.2d')],'-png','-r200');
        close all
    end
    if fig_roms
        
        temp_roms_month = squeeze(temp_roms(:,:,im));
        figure('visible','off','color',[1 1 1])
        m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
        P=m_pcolor(lon,lat,temp_roms_month);
        set(P,'LineStyle','none');
        shading interp
        hold on
        m_gshhs_i('patch', [.8 .8 .8], 'edgecolor', 'none');
        m_grid('box','fancy','tickdir','in','linest','none','ytick',-10:5:40,'xtick',90:5:150);
        caxis([tmin tmax])
        colorbar
        m_text(X0,Y0,mm,'FontSize',14)
        title(['climatology ROMS SST in month ',num2str(im,'%2.2d')])
        export_fig([roms_fig_path,'roms_sst_month_',num2str(im,'%2.2d')],'-png','-r200');
        close all
    end
    if fig_rmse
        rmse_roms_ostia_month = squeeze(rmse_roms_ostia(:,:,im));
        domain_average_rmse = nanmean(rmse_roms_ostia_month(:));
        figure('visible','off','color',[1 1 1])
        m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
        P=m_pcolor(lon,lat,rmse_roms_ostia_month);
        set(P,'LineStyle','none');
        shading interp
        hold on
        m_gshhs_i('patch', [.8 .8 .8], 'edgecolor', 'none');
        m_grid('box','fancy','tickdir','in','linest','none','ytick',-10:5:40,'xtick',90:5:150);
        caxis([0 3])
        colorbar
        m_text(X0,Y0,[mm,' RMSE: ',num2str(domain_average_rmse,'%2.2f')],'FontSize',14)
        title(['climatology rmse ROMS and OSTIA SST in month ',num2str(im,'%2.2d')])
        export_fig([roms_fig_path,'rmse_roms_ostia_sst_month_',num2str(im,'%2.2d')],'-png','-r200');
        close all
    end
end