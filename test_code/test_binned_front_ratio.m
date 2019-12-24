% calculate daily front occurence hit-or-miss in each bin
close all
clear all
clc
%
platform = 'hanyh_laptop';
if strcmp(platform, 'hanyh_laptop')
    basedir = 'D:\lomf\frontal_detect\';
    data_path = 'E:\DATA\Model\Mercator\Extraction_PSY4V3_SCS\';
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
    data_path = [root_path, '/Mercator_data/Model/Extraction_PSY4V3_SCS/'];
    toolbox_path = [root_path, '/matlab_function/'];
end

% add path of toolbox we use
addpath(genpath([toolbox_path, '/export_fig/']))
addpath(genpath([toolbox_path, '/m_map/']))
addpath(genpath([toolbox_path, '/MatlabFns/']))
addpath(genpath([basedir, '/frontal_detection/']))

global lat_n lat_s lon_w lon_e
global fig_show
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

% preprocess parameter
datatype_mercator = 'mercator';
datatype_ostia = 'ostia';
datatype_roms = 'roms';
fntype = 'daily';

yy1 = 2017;
yy2 = 2017;
% set a new regular grid
bin_resolution = 0.5; % unit: degree

ostia_daily_path = [basedir, './Result/ostia/', domain_name, '/daily/'];
roms_daily_path = [basedir, './Result/', datatype_roms, '/', domain_name, '/daily/'];
% mercator_daily_path = [basedir, './Result/', datatype_mercator, '/', domain_name, '/daily/'];
% clim_path = [basedir, './Result/', datatype, '/', domain_name, '/climatology/'];mkdir(clim_path)
% % input file
fig_path = [basedir, './Fig/comparison/', domain_name, '/daily/']; mkdir(fig_path);

% set bin ratio threshold
bin_area_ratio_thresh = 0.5;
% TBD: need to auto-change with grid size
bin_line_ratio_thresh = 0.1;    
fig_show = 'off';
bin_ratio_test = 1; % set test for front ratio in each bin
for iy = yy1:yy2
    ostia_fn = [ostia_daily_path, '/concatenate_front_daily_binned_',num2str(bin_resolution),'degree_',num2str(iy),'.nc'];
    roms_fn = [roms_daily_path, '/concatenate_front_daily_binned_',num2str(bin_resolution),'degree_',num2str(iy),'.nc'];
    % mercator_fn = [mercator_daily_path, '/concatenate_front_daily_binned_',num2str(bin_resolution),'degree_',num2str(iy),'.nc'];
    if ~exist(ostia_fn) || ~exist(roms_fn)
        continue
    end
    if mod(iy,4) == 0
        ndays = 366;
    else
        ndays = 365;
    end
    fn = roms_fn;
    lon_bin = ncread(fn,'lon');
    lat_bin = ncread(fn,'lat');
    mask_bin = ncread(fn,'mask');
    clear fn
    [nx_bin,ny_bin] = size(lon_bin);
    % read binned daily front variable
    ostia_area_ratio = ncread(ostia_fn,'frontarea_ratio_bin');
    roms_area_ratio = ncread(roms_fn,'frontarea_ratio_bin');
    
    ostia_datetime = ncread(ostia_fn,'datetime')-datenum(iy,1,1,0,0,0)+1;
    roms_datetime = ncread(roms_fn,'datetime')-datenum(iy,1,1,0,0,0)+1;
    for iday = 1:ndays
        ostia_time_ind = find(iday == ostia_datetime);
        roms_time_ind = find(iday == roms_datetime);
        if isempty(ostia_time_ind) || isempty(roms_time_ind)
            continue
        end
        ostia_area_ratio = ncread(ostia_fn,'frontarea_ratio_bin',[1 1 ostia_time_ind],[Inf Inf 1]);
        roms_area_ratio = ncread(roms_fn,'frontarea_ratio_bin',[1 1 roms_time_ind],[Inf Inf 1]);
        % ratio to binary
        ostia_area = ratio_to_binary(ostia_area_ratio,bin_area_ratio_thresh);
        roms_area = ratio_to_binary(roms_area_ratio,bin_area_ratio_thresh);
        %
        % TBD: validation for frontline
        % ostia_line_ratio = ncread(ostia_fn,'frontline_ratio_bin',[1 1 ostia_time_ind],[Inf Inf 1]);
        % roms_line_ratio = ncread(roms_fn,'frontline_ratio_bin',[1 1 roms_time_ind],[Inf Inf 1]);
        % ostia_line = ratio_to_binary(ostia_line_ratio,bin_line_ratio_thresh);
        % roms_line = ratio_to_binary(roms_line_ratio,bin_line_ratio_thresh);
        if bin_ratio_test
            test_daily_path = [fig_path, '/test/']; mkdir(test_daily_path)

            if iday == 1
                % test
                cmin = []; cmax = [];
                plot_pcolor_map(lon_bin, lat_bin, ostia_area_ratio, cmin, cmax, 'Jan', 'OSTIA', [test_daily_path, 'ostia_bin_area_ratio_Jan.png'])
                plot_pcolor_map(lon_bin, lat_bin, roms_area_ratio, cmin, cmax, 'Jan', 'ROMS', [test_daily_path, 'roms_bin_area_ratio_Jan.png'])
            elseif iday == 200
                cmin = []; cmax = [];
                plot_pcolor_map(lon_bin, lat_bin, ostia_area_ratio, cmin, cmax, 'Jul', 'OSTIA', [test_daily_path, 'ostia_bin_area_ratio_Jul.png'])
                plot_pcolor_map(lon_bin, lat_bin, roms_area_ratio, cmin, cmax, 'Jul', 'ROMS', [test_daily_path, 'roms_bin_area_ratio_Jul.png'])
            end

        end

    end


end


function binary_var = ratio_to_binary(ratio_var,bin_ratio_thresh)
binary_var = ratio_var;
binary_var(binary_var>bin_ratio_thresh) = 1;
binary_var(binary_var<=bin_ratio_thresh) = 0;
end


function plot_pcolor_map(lon,lat,var,cmin,cmax,fig_title,fig_text,fig_name)
%
global lat_n lat_s lon_w lon_e
global fig_show

% set position for text
X0 = lon_w + 0.05*(lon_e - lon_w);
Y0 = lat_s +0.9*(lat_n - lat_s);

% plot monthly frontarea frequency figure
figure('visible',fig_show)
m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
P = m_pcolor(lon,lat,var);
set(P,'LineStyle','none');
m_gshhs_i('patch', [.8 .8 .8], 'edgecolor', 'none');
m_grid('box','fancy','tickdir','in','linest','none','ytick',-10:5:40,'xtick',90:5:150);
if ~(isempty(cmin) || isempty(cmax))
    caxis([cmin cmax])
end
colorbar
colormap(jet);
title(fig_title)
m_text(X0,Y0,fig_text,'FontSize',14)
export_fig(fig_name,'-png','-r200');
close all

end




