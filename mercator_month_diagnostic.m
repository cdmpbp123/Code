% calculate monthly temperature and auto-threshold,
% then save output for Mercator product Extraction_PSY4V3_SCS
close all
clear all
clc
%
platform = 'hanyh_laptop';
if strcmp(platform, 'hanyh_laptop')
    basedir = 'D:\lomf\frontal_detect\';
    data_path ='E:\DATA\Model\Mercator\Extraction_PSY4V3_SCS\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform,'PC_office')
    basedir = 'D:\lomf\frontal_detect\';
    ostia_path = 'S:\DATA\obs\OSTIA\';
    roms_path = 'S:\DATA\Model\ROMS\scs_new\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform,'server197')
    root_path = '/work/person/rensh/';
    basedir = [root_path,'/front_detect/'];
    ostia_path = [root_path,'/Data/OSTIA/'];
    roms_path = [root_path,'/Data/OSTIA/'];
    toolbox_path = [root_path,'/matlab_function/'];
elseif strcmp(platform,'mercator_PC')
    root_path = '/homelocal/sauvegarde/sren/';
    basedir = [root_path,'/front_detect/'];
    data_path = [root_path,'/Mercator_data/Model/Extraction_PSY4V3_SCS/'];
    toolbox_path = [root_path,'/matlab_function/'];   
end

% add path of toolbox we use
addpath(genpath([toolbox_path,'/export_fig/']))
addpath(genpath([toolbox_path,'/m_map/']))
addpath(genpath([toolbox_path,'/MatlabFns/']))
addpath(genpath([basedir,'/frontal_detection/']))

domain = 2; % choose SCS domain for front diagnostic
% domain select
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
% preprocess parameter
depth = 1;
skip=1;
smooth_type = 'no_smooth';
sigma = 2;
N = 2;
fill_value = 0;
% set upper and lower frequecy percent for histogram
LowFreq = 0.8;
HighFreq = 0.9;
%
yy1 = 2018;
yy2 = 2018;
fig_path = [basedir,'./Fig/mercator/climatology/',domain_name,'/'];mkdir(fig_path);
result_path = [basedir,'./Result/mercator/climatology/',domain_name,'/'];mkdir(result_path)
result_fn = [result_path,'/mercator_front_monthly_climatology_',smooth_type,'_',num2str(yy1),'to',num2str(yy2),'.nc'];

if ~exist(result_fn)
    % get Mercator grd from test filename
    iy = 2018; im = 1; id = 1;
    day_string = [num2str(iy),num2str(im,'%2.2d'),num2str(id,'%2.2d')];
    filename = ls([data_path,'/ext-PSY4V3R1_1dAV_',day_string,'*gridT*.nc']);
    fn0 = [data_path,filename];
    [~,grd0] = mercator_preprocess(fn0,depth,lon_w,lon_e,lat_s,lat_n,skip);
    clear fn0 iy im id
    %
    lon = grd0.lon_rho;
    lat = grd0.lat_rho;
    mask = grd0.mask_rho;
    [nx,ny] =size(mask);
    nt = 12;
    temp_mean = zeros(nx,ny,nt);
    tgrad_mean = zeros(nx,ny,nt);
    %begin loop
    for im = 1:nt
        iday = 0;
        temp_sum = zeros(nx,ny);
        tgrad_sum = zeros(nx,ny);
        tgrad_1d = [];
        for iy = yy1:yy2
            for id = 1:31
                day_string = [num2str(iy),num2str(im,'%2.2d'),num2str(id,'%2.2d')];
                filename = ls([data_path,'/ext-PSY4V3R1_1dAV_',day_string,'*gridT*.nc']);
                if isempty(filename)
                    continue
                else
                    iday = iday + 1;
                    fn = [data_path,filename];
                end
                [temp,grd] = mercator_preprocess(fn,depth,lon_w,lon_e,lat_s,lat_n,skip);
                [temp_zl] = variable_preprocess(temp,smooth_type,fill_value);
                [tgrad, tangle] = get_front_variable(temp_zl,grd);
                %
                temp_sum = temp_sum +temp_zl;
                tgrad_sum = tgrad_sum +tgrad;
                tgrad_1d = cat(1,tgrad_1d,tgrad(:));
            end
        end
        disp(num2str(im))
        iday
        temp_mean(:,:,im) = temp_sum / iday;
        tgrad_mean(:,:,im) = tgrad_sum / iday;
        clear iday temp_sum tgrad_sum
        % auto-threshold
        thresh_fig_name = [fig_path,'/mercator_tgrad_threshold_month_',num2str(im,'%2.2d'),'_',smooth_type,'_',num2str(yy1),'to',num2str(yy2),'.jpg'];
        [LowThresh, HighThresh] = auto_thresh_histogram(tgrad_1d, LowFreq, HighFreq, thresh_fig_name);
        low_thresh_month(im) = LowThresh;
        high_thresh_month(im) = HighThresh;
        clear LowThresh HighThresh
    end
    
    % result_fn = [result_path,'/mercator_front_monthly_climatology_',smooth_type,'_',num2str(yy1),'to',num2str(yy2),'.nc'];
    % create variable with defined dimension
    nccreate(result_fn,'lon','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','classic')
    nccreate(result_fn,'lat','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','classic')
    nccreate(result_fn,'mask','Dimensions',{'nx' nx 'ny' ny},'datatype','double','format','classic')
    nccreate(result_fn,'temp','Dimensions',{'nx' nx 'ny' ny 'nt' nt},'datatype','double','format','classic')
    nccreate(result_fn,'tgrad','Dimensions',{'nx' nx 'ny' ny 'nt' nt},'datatype','double','format','classic')
    nccreate(result_fn,'LowThresh','Dimensions' ,{'nt' nt},'datatype','double','format','classic')
    nccreate(result_fn,'HighThresh','Dimensions' ,{'nt' nt},'datatype','double','format','classic')
    % write variable into files
    ncwrite(result_fn,'lon',lon)
    ncwrite(result_fn,'lat',lat)
    ncwrite(result_fn,'mask',mask)
    ncwrite(result_fn,'temp',temp_mean)
    ncwrite(result_fn,'tgrad',tgrad_mean)
    ncwrite(result_fn,'LowThresh',low_thresh_month)
    ncwrite(result_fn,'HighThresh',high_thresh_month)
    % write file global attribute
    ncwriteatt(result_fn,'/','creation_date',datestr(now))
    ncwriteatt(result_fn,'/','data_source','Mercator daily output: PSY4V3R1')
    ncwriteatt(result_fn,'/','description','climatology monthly front diagnostic')
    ncwriteatt(result_fn,'/','domain',domain_name)
    ncwriteatt(result_fn,'/','grid skip number',num2str(skip))
    ncwriteatt(result_fn,'/','smooth_type',smooth_type)
    ncwriteatt(result_fn,'/','lower frequency percent',LowFreq)
    ncwriteatt(result_fn,'/','upper frequency percent',HighFreq)
    ncwriteatt(result_fn,'/','average time span',['from ',num2str(yy1),' to ',num2str(yy2)])
    
else
    lon = ncread(result_fn,'lon');
    lat = ncread(result_fn,'lat');
    mask = ncread(result_fn,'mask');
    temp_mean = ncread(result_fn,'temp');
    tgrad_mean = ncread(result_fn,'tgrad');
    low_thresh_month = ncread(result_fn,'LowThresh');
    high_thresh_month = ncread(result_fn,'HighThresh');
end

%plot figure
% set min&max value for Mercator tgrad
tgrad_min = 0.01;   tgrad_max = 0.1;
% set position for text
X0 = lon_w + 0.05*(lon_e - lon_w);
Y0 = lat_s +0.9*(lat_n - lat_s);
for im=1:12
    T = squeeze(temp_mean(:,:,im));
    tgrad = squeeze(tgrad_mean(:,:,im));
    % set min and max value of SST and tgrad colorbar
    [tmin,tmax,mm] = set_temp_limit(im,temp_mean);
    % SST
    figure('visible','on')
    m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
    P=m_pcolor(lon,lat,T);
    set(P,'LineStyle','none');
    shading interp
    hold on
    m_gshhs_i('patch',[.7 .7 .7],'edgecolor','none');
    m_grid('box','fancy','tickdir','in','linest','none','ytick',-10:5:40,'xtick',90:5:140);
    m_text(X0,Y0,mm,'FontSize',14)
    title(['climatology SST in month ',num2str(im,'%2.2d'),' Unit: \circC'])
    colorbar
    colormap(jet);
    caxis([tmin tmax])
    fname = [fig_path,'monthly_temp_',num2str(im,'%2.2d'),'.png'];
    export_fig(fname,'-png','-r200');
    close all
    
    % SST gradient
    figure('visible','on')
    m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
    P=m_pcolor(lon,lat,tgrad);
    set(P,'LineStyle','none');
    shading interp
    hold on
    m_gshhs_i('patch',[.7 .7 .7],'edgecolor','none');
    m_grid('box','fancy','tickdir','in','linest','none','ytick',-10:5:40,'xtick',90:5:140);
    colorbar
    colormap(flipud(m_colmap('Blues')))
    caxis([tgrad_min tgrad_max])
    m_text(X0,Y0,mm,'FontSize',14)
    title(['climatology SST gradient in month ',num2str(im,'%2.2d'),' Unit: \circC/km'])
    fname = [fig_path,'monthly_tgrad_',num2str(im,'%2.2d'),'.png'];
    export_fig(fname,'-png','-r200');
    close all
end




