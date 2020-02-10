% compare binned frequency bias 
close all
clear all
clc
%
platform = 'hanyh_laptop';
if strcmp(platform, 'hanyh_laptop')
    basedir = 'D:\lomf\frontal_detect\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform,'PC_office')
    basedir = 'D:\lomf\frontal_detect\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform,'server197')
    root_path = '/work/person/rensh/';
    basedir = [root_path,'/front_detect/'];
    toolbox_path = [root_path,'/matlab_function/'];
end

% add path of toolbox we use
addpath(genpath([toolbox_path,'/export_fig/']))
addpath(genpath([toolbox_path,'/m_map/']))
addpath(genpath([toolbox_path,'/MatlabFns/']))
addpath(genpath([basedir,'/frontal_detection/']))

%set global variable
global lat_n lat_s lon_w lon_e
domain = 2;
% choose whole model domain for SST comparison
switch domain
case 1
    % NSCS domain, specific for front area in north SCS
    domain_name = 'NSCS';
    lat_s=10; lat_n=25;
    lon_w=105; lon_e=121;
case 2
    % whole SCS domain
    domain_name = 'SCS';
    lat_s=-4; lat_n=28;
    lon_w=99; lon_e=127;
case 3
    % ROMS model domain, include part of NWP
    domain_name = 'model_domain';
    lat_s=-4; lat_n=28;
    lon_w=99; lon_e=144;
end

yy1 = 2008;
yy2 = 2017;
% set a new regular grid
freq_type = 'binned';
bin_resolution = 0.5; % unit: degree
clim_suffix = [num2str(yy1), 'to', num2str(yy2)];
fig_path = [basedir,'./Fig/comparison/',domain_name,'/climatology/'];mkdir(fig_path);
freq_fig_path  = [fig_path,'/freq_bin_',num2str(bin_resolution),'/']; mkdir(freq_fig_path)

roms_result_fn = [basedir,'./Result/roms/',domain_name,'/climatology/front_frequency_map_binned_',num2str(bin_resolution),'degree_',clim_suffix,'.nc'];
ostia_result_fn = [basedir,'./Result/ostia/',domain_name,'/climatology/front_frequency_map_binned_',num2str(bin_resolution),'degree_',clim_suffix,'.nc'];
mercator_result_fn = [basedir,'./Result/mercator/',domain_name,'/climatology/front_frequency_map_binned_',num2str(bin_resolution),'degree_',clim_suffix,'.nc'];

lon = ncread(roms_result_fn,'lon');
lat = ncread(roms_result_fn,'lat');
mask = ncread(roms_result_fn,'mask');

roms_counter_map = ncread(roms_result_fn,'counter_map');
roms_frontarea_freq_map = ncread(roms_result_fn,'frontarea_freq_map');
roms_frontline_freq_map = ncread(roms_result_fn,'frontline_freq_map');

ostia_counter_map = ncread(ostia_result_fn,'counter_map');
ostia_frontarea_freq_map = ncread(ostia_result_fn,'frontarea_freq_map');
ostia_frontline_freq_map = ncread(ostia_result_fn,'frontline_freq_map');

mercator_counter_map = ncread(mercator_result_fn,'counter_map');
mercator_frontarea_freq_map = ncread(mercator_result_fn,'frontarea_freq_map');
mercator_frontline_freq_map = ncread(mercator_result_fn,'frontline_freq_map');

[nx, ny] = size(lon);
nt = 12;
lineFreq_min = -0.05;   lineFreq_max = 0.05;
areaFreq_min = -0.2;   areaFreq_max = 0.2;


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
    roms_areafreq = freq_multiple_month(roms_frontarea_freq_map,roms_counter_map,month_index);
    ostia_areafreq = freq_multiple_month(ostia_frontarea_freq_map,ostia_counter_map,month_index);
    mercator_areafreq = freq_multiple_month(mercator_frontarea_freq_map,mercator_counter_map,month_index);

    roms_linefreq = freq_multiple_month(roms_frontline_freq_map,roms_counter_map,month_index);
    ostia_linefreq = freq_multiple_month(ostia_frontline_freq_map,ostia_counter_map,month_index);
    mercator_linefreq = freq_multiple_month(mercator_frontline_freq_map,mercator_counter_map,month_index);

    frontarea_fig_name0 = [freq_fig_path,'roms_bias_frontarea_freq_map_in_',season_name];
    frontline_fig_name0 = [freq_fig_path,'roms_bias_frontline_freq_map_in_',season_name];
    frontarea_fig_name1 = [freq_fig_path,'mercator_bias_frontarea_freq_map_in_',season_name];
    frontline_fig_name1 = [freq_fig_path,'mercator_bias_frontline_freq_map_in_',season_name];

    plot_freq_map(freq_type,lon,lat,roms_areafreq-ostia_areafreq,areaFreq_min,areaFreq_max,season_name,frontarea_fig_name0)
    plot_freq_map(freq_type,lon,lat,roms_linefreq-ostia_linefreq,lineFreq_min,lineFreq_max,season_name,frontline_fig_name0)

    plot_freq_map(freq_type,lon,lat,mercator_areafreq-ostia_areafreq,areaFreq_min,areaFreq_max,season_name,frontarea_fig_name1)
    plot_freq_map(freq_type,lon,lat,mercator_linefreq-ostia_linefreq,lineFreq_min,lineFreq_max,season_name,frontline_fig_name1)

    clear roms_areafreq ostia_areafreq mercator_areafreq
    clear roms_linefreq ostia_linefreq mercator_linefreq

end

% monthly frontal frequency
for im = 1:12
    [~,~,mm] = set_temp_limit(im);
    disp(['month: ',num2str(im)])
    roms_frontarea_freq_month = squeeze(roms_frontarea_freq_map(:,:,im));
    ostia_frontarea_freq_month = squeeze(ostia_frontarea_freq_map(:,:,im));
    mercator_frontarea_freq_month = squeeze(mercator_frontarea_freq_map(:,:,im));
    roms_frontarea_fig_name = [freq_fig_path,'roms_bias_frontarea_freq_map_month_',num2str(im,'%2.2d')];
    mercator_frontarea_fig_name = [freq_fig_path,'mercator_bias_frontarea_freq_map_month_',num2str(im,'%2.2d')];
    plot_freq_map(freq_type,lon,lat,roms_frontarea_freq_month-ostia_frontarea_freq_month,areaFreq_min,areaFreq_max,mm,roms_frontarea_fig_name)
    plot_freq_map(freq_type,lon,lat,mercator_frontarea_freq_month-ostia_frontarea_freq_month,areaFreq_min,areaFreq_max,mm,mercator_frontarea_fig_name)

    roms_frontline_freq_month = squeeze(roms_frontline_freq_map(:,:,im));
    ostia_frontline_freq_month = squeeze(ostia_frontline_freq_map(:,:,im));
    mercator_frontline_freq_month = squeeze(mercator_frontline_freq_map(:,:,im));
    roms_frontline_fig_name = [freq_fig_path,'roms_bias_frontline_freq_map_month_',num2str(im,'%2.2d')];
    mercator_frontline_fig_name = [freq_fig_path,'mercator_bias_frontline_freq_map_month_',num2str(im,'%2.2d')];
    plot_freq_map(freq_type,lon,lat,roms_frontline_freq_month-ostia_frontline_freq_month,lineFreq_min,lineFreq_max,mm,roms_frontline_fig_name)
    plot_freq_map(freq_type,lon,lat,mercator_frontline_freq_month-ostia_frontline_freq_month,lineFreq_min,lineFreq_max,mm,mercator_frontline_fig_name)
    
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