% plot front occurence frequency including raw grid and binned grid
% use front frequency map NetCDF file
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

%set global variable
global lat_n lat_s lon_w lon_e
% global lineFreq_min lineFreq_max areaFreq_min areaFreq_max

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

% % parameter
datatype = 'mercator';
yy1 = 2008;
yy2 = 2017;
bin_resolution = 0.5;
freq_type = 'raw';
% freq_type = 'binned';

clim_path = [basedir, './Result/', datatype, '/', domain_name, '/climatology/'];mkdir(clim_path)
fig_path = [basedir, './Fig/',datatype,'/', domain_name, '/climatology/']; mkdir(fig_path);
clim_suffix = [num2str(yy1), 'to', num2str(yy2)];
%
if strcmp(freq_type,'raw')
    result_fn = [clim_path,'front_frequency_map_raw_',clim_suffix,'.nc'];
    freq_fig_path = [fig_path,'/freq_raw/'];mkdir(freq_fig_path)
elseif strcmp(freq_type,'binned')
    result_fn = [clim_path,'front_frequency_map_binned_',num2str(bin_resolution),'degree_',clim_suffix,'.nc'];
    freq_fig_path  = [fig_path,'/freq_bin_',num2str(bin_resolution),'/']; mkdir(freq_fig_path)
end

lon = ncread(result_fn,'lon');
lat = ncread(result_fn,'lat');
mask = ncread(result_fn,'mask');
counter_map = ncread(result_fn,'counter_map');
frontarea_freq_map = ncread(result_fn,'frontarea_freq_map');
frontline_freq_map = ncread(result_fn,'frontline_freq_map');
% true_frontarea_freq_map = ncread(result_fn,'true_frontarea_freq_map');
[nx, ny] = size(lon);
nt = 12;
lineFreq_min = 0.0;   lineFreq_max = 0.2;
areaFreq_min = 0.0;   areaFreq_max = 0.9;
% frontarea_freq_map(frontarea_freq_map<areaFreq_min) = NaN;
% frontarea_freq_map(frontarea_freq_map>areaFreq_max) = areaFreq_max;
% frontline_freq_map(frontline_freq_map<lineFreq_min) = NaN;
% frontline_freq_map(frontline_freq_map>lineFreq_max) = lineFreq_max;

% seasonal frontal frequency
for season_index = 1:5
    switch(season_index)
    case 1
        season_name = 'DJF';
        month_index = [1,2,12];
    case 2
        season_name = 'MAM';
        month_index = [3,4,5];
    case 3
        season_name = 'JJA';
        month_index = [6,7,8];
    case 4
        season_name = 'SON';
        month_index = [9,10,11];
    case 5
        season_name = 'Annual';
        month_index = [1:12];  
    end
    areafreq = freq_multiple_month(frontarea_freq_map,counter_map,month_index);
    linefreq = freq_multiple_month(frontline_freq_map,counter_map,month_index);
    areafreq_season(:,:,season_index) = areafreq;
    linefreq_season(:,:,season_index) = linefreq;
    frontarea_fig_name = [freq_fig_path,'frontarea_freq_map_in_',season_name];
    frontline_fig_name = [freq_fig_path,'frontline_freq_map_in_',season_name];
    plot_freq_map(freq_type,lon,lat,areafreq,areaFreq_min,areaFreq_max,season_name,frontarea_fig_name)
    plot_freq_map(freq_type,lon,lat,linefreq,lineFreq_min,lineFreq_max,season_name,frontline_fig_name)

end

% monthly frontal frequency
for im = 1:12
    [~,~,mm] = set_temp_limit(im);
    disp(['month: ',num2str(im)])
    
    frontarea_freq_month = squeeze(frontarea_freq_map(:,:,im));
    frontarea_fig_name = [freq_fig_path,'frontarea_freq_map_month_',num2str(im,'%2.2d')];
    plot_freq_map(freq_type,lon,lat,frontarea_freq_month,areaFreq_min,areaFreq_max,mm,frontarea_fig_name)
    frontline_freq_month = squeeze(frontline_freq_map(:,:,im));
    frontline_fig_name = [freq_fig_path,'frontline_freq_map_month_',num2str(im,'%2.2d')];
    plot_freq_map(freq_type,lon,lat,frontline_freq_month,lineFreq_min,lineFreq_max,mm,frontline_fig_name)
    
end




function plot_freq_map(freq_type,lon,lat,front_freq,freq_min,freq_max,fig_text,fig_name)

[nx,ny] = size(lon);
global lat_n lat_s lon_w lon_e
% set position for text
X0 = lon_w + 0.05*(lon_e - lon_w);
Y0 = lat_s +0.9*(lat_n - lat_s);
% process freq with extreme little and large
minmax_mask = 0;
if minmax_mask
    front_freq(front_freq<freq_min) = NaN;
    front_freq(front_freq>freq_max) = freq_max;
end
% plot monthly frontarea frequency figure
figure('visible','off','color',[1 1 1])
m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
P=m_pcolor(lon,lat,front_freq);
set(P,'LineStyle','none');
if strcmp(freq_type,'binned')
    hold on
    for j = 1:ny
        m_plot(lon(:,j),lat(:,j),'k')
        hold on
    end
    for  i = 1:nx
        m_plot(lon(i,:),lat(i,:),'k')
        hold on
    end
    hold on
elseif strcmp(freq_type,'raw')
    shading interp
end
m_gshhs_i('patch', [.8 .8 .8], 'edgecolor', 'none');
m_grid('box','fancy','tickdir','in','linest','none','ytick',-10:5:40,'xtick',90:5:150);
caxis([freq_min freq_max])
colorbar
% title(['frontzone frequency map ',fig_text])
m_text(X0,Y0,fig_text,'FontSize',14)
export_fig(fig_name,'-png','-r200');
close all



end

function freq_mean = freq_multiple_month(freq_month_map,counter_map,month_index)
    freq_sum = 0;
    for i = month_index
        freq_counter = squeeze(freq_month_map(:,:,i)).* squeeze(counter_map(:,:,i));
        freq_sum = freq_sum + freq_counter;
    end
    total_counter = sum(counter_map(:,:,month_index),3);  
    total_counter(total_counter == 0) = NaN;
    freq_mean = freq_sum./total_counter;
end

