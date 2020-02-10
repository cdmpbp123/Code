% compare SST rmse of long-term ROMS experiment and Mercator with OSTIA  
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
%
yy1 = 2007;
yy2 = 2017;
exp_name1 = 'scs50_hindcast_nudg_new';
exp_name2 = 'scs50_hindcast';
exp_name3 = 'scsnew';

result_path = [basedir, './Result/',datatype,'/', 'model_domain', '/climatology/']; %climatology RMSE data in model_domain path
% input file
fig_path = [basedir, './Fig/',datatype,'/', domain_name, '/climatology/']; mkdir(fig_path);
% diagnostic_fig_path = [fig_path,'/exp_comparison/'];mkdir(diagnostic_fig_path)

result_fn1 = [result_path, '/',exp_name1,'_sst_rmse_climatology_', smooth_type, '_', num2str(yy1), 'to', num2str(yy2), '.nc'];
result_fn2 = [result_path, '/',exp_name2,'_sst_rmse_climatology_', smooth_type, '_', num2str(yy1), 'to', num2str(yy2), '.nc'];
result_fn3 = [result_path, '/',exp_name3,'_sst_rmse_climatology_', smooth_type, '_', num2str(yy1), 'to', num2str(yy2), '.nc'];

area_rmse_roms1 = get_monthly_rmse(result_fn1,'rmse');
area_rmse_roms2 = get_monthly_rmse(result_fn2,'rmse');
area_rmse_roms3 = get_monthly_rmse(result_fn3,'roms_rmse');
area_rmse_mercator = get_monthly_rmse(result_fn3,'mercator_rmse');

%plot monthly front threshold figure
month_string = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
xx = cellstr(month_string);
xlabel = 1:12;

figure
plot(xlabel,area_rmse_roms1,'-b','LineWidth',2)
hold on
plot(xlabel,area_rmse_roms2,'-r','LineWidth',2)
hold on
plot(xlabel,area_rmse_roms3,'-g','LineWidth',2)
hold on
plot(xlabel,area_rmse_mercator,'-k','LineWidth',2)
hold on
legend('nudging','no nudging','scsnew','mercator','Location','north')
% title(' nudging experiment RMSE comparison')
ylabel('\circC')
grid on
set(gca,'XTick',xlabel)
set(gca,'XTickLabel',xx)
% % set position for text
% X0 = lon_w + 0.05*(lon_e - lon_w);
% Y0 = lat_s +0.9*(lat_n - lat_s);
export_fig([fig_path,'sst_rmse_compare_',num2str(yy1),'to',num2str(yy2),'.png'],'-png','-r200');



function monthly_area_rmse = get_monthly_rmse(result_fn,varname)
    lon = ncread(result_fn, 'lon');
    lat = ncread(result_fn, 'lat');
    mask = ncread(result_fn, 'mask');
    % temp_ostia = ncread(result_fn, 'temp_ostia');
    % temp_roms1 = ncread(result_fn, 'temp_roms');
    rmse = ncread(result_fn, varname);
    
    [nx, ny] = size(lon);
    nt = 12;
    monthly_area_rmse = zeros(nt,1);
    for im = 1:nt
        monthly_rmse = squeeze(rmse(:,:,im));
        monthly_area_rmse(im) = nanmean(monthly_rmse(:));
    end
end