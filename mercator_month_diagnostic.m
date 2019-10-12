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
smooth_type = 'gaussian';
sigma = 2;
N = 2;
fill_value = 0;
% detect parameter
flen_crit4diag = 20e3; % set new length criterion for diagnostic
% set upper and lower frequecy percent for histogram
LowFreq = 0.8;
HighFreq = 0.9;
%
yy1 = 2018;
yy2 = 2018;
%
daily_input_path = [basedir, './Result/mercator/',domain_name,'/daily/']; 
result_path = [basedir,'./Result/mercator/',domain_name,'/climatology/'];mkdir(result_path)
result_fn = [result_path,'/mercator_front_monthly_climatology_',smooth_type,'_',num2str(yy1),'to',num2str(yy2),'.nc'];
fig_path = [basedir,'./Fig/mercator/',domain_name,'/climatology/'];mkdir(fig_path);
if ~exist(result_fn)
    % get OSTIA grd from test filename
    iy = yy1; im = 1; id = 1;
    day_string = [num2str(iy),num2str(im,'%2.2d'),num2str(id,'%2.2d')];
    test_fn = [daily_input_path,'/',num2str(iy), '/detected_front_', day_string, '.mat'];
    if ~exist(test_fn)
        error('choose another Mat file to read grd file')
    end
    test_data = load(test_fn);
    grd0 = test_data.grd;
    clear fn0 iy im id
    %
    lon = grd0.lon_rho;
    lat = grd0.lat_rho;
    mask = grd0.mask_rho;
    [nx,ny] =size(mask);
    nt = 12;
    % monthly mean variable
    temp_mean = zeros(nx,ny,nt);
    tgrad_mean = zeros(nx,ny,nt);
    % monthly mean front parameter
    frontLength_mean = zeros(nt,1);
    frontStrength_mean = zeros(nt,1);
    frontWidth_mean = zeros(nt,1);
    frontArea_mean = zeros(nt,1);
    frontNumber_mean = zeros(nt,1);
    %begin loop
    for im = 1:nt
        iday = 0;
        temp_sum = zeros(nx,ny);
        tgrad_sum = zeros(nx,ny);
        tgrad_1d = [];
        frontNumber = 0;
        frontLength_sum = 0;
        frontStrength_sum = 0;
        frontWidth_sum = 0;
        frontArea_sum = 0;
        for iy = yy1:yy2
            for id = 1:31
                day_string = [num2str(iy),num2str(im,'%2.2d'),num2str(id,'%2.2d')]
                fn = [daily_input_path,'/',num2str(iy),'/detected_front_', day_string, '.mat'];
                if ~exist(fn)
                    continue
                else
                    iday = iday + 1;
                end
                daily_data = load(fn);
                grd = daily_data.grd;
                temp_zl = daily_data.temp_zl;
                % SST and tgrad diagnostic
                [tgrad, ~] = get_front_variable(temp_zl,grd);
                temp_sum = temp_sum + temp_zl;
                tgrad_sum = tgrad_sum + tgrad;
                tgrad_1d = cat(1,tgrad_1d,tgrad(:));
                % front parameter diagnostic
                tfrontline = daily_data.tfrontline;
                tfrontarea = daily_data.tfrontarea;
                info_area = daily_data.info_area;
                fnum = length(tfrontline);
                % diagnostic calculation
                for ifr = 1:fnum
                    fr_length = tfrontline{ifr}.flen;
                    if fr_length > flen_crit4diag
                        frontLength_sum = frontLength_sum + tfrontline{ifr}.flen;
                        frontStrength_sum = frontStrength_sum + tfrontline{ifr}.tgrad_mean;
                        frontWidth_sum = frontWidth_sum + info_area{ifr}.mean_width;
                        frontArea_sum = frontArea_sum + info_area{ifr}.area;
                        frontNumber = frontNumber + 1;
                    end
                end
            end
        end
        disp(num2str(im))
        %
        temp_mean(:,:,im) = temp_sum / iday;
        tgrad_mean(:,:,im) = tgrad_sum / iday;
        %
        frontLength_mean(im) = frontLength_sum / frontNumber;
        frontStrength_mean(im) = frontStrength_sum / frontNumber;
        frontWidth_mean(im) = frontWidth_sum / frontNumber;
        frontArea_mean(im) = frontArea_sum / frontNumber;
        frontNumber_mean(im) = frontNumber / iday;
        clear iday temp_sum tgrad_sum
        clear frontLength_sum frontStrength_sum frontWidth_sum frontArea_sum frontNumber
        % auto-threshold
        thresh_fig_name = [fig_path,'/mercator_tgrad_threshold_month_',num2str(im,'%2.2d'),'_',smooth_type,'_',num2str(yy1),'to',num2str(yy2),'.jpg'];
        [LowThresh, HighThresh] = auto_thresh_histogram(tgrad_1d, LowFreq, HighFreq, thresh_fig_name);
        close all
        low_thresh_month(im) = LowThresh;
        high_thresh_month(im) = HighThresh;
        clear LowThresh HighThresh
    end

    % create variable with defined dimension
    nccreate(result_fn,'lon','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','classic')
    nccreate(result_fn,'lat','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','classic')
    nccreate(result_fn,'mask','Dimensions',{'nx' nx 'ny' ny},'datatype','double','format','classic')
    nccreate(result_fn,'temp','Dimensions',{'nx' nx 'ny' ny 'nt' nt},'datatype','double','format','classic')
    nccreate(result_fn,'tgrad','Dimensions',{'nx' nx 'ny' ny 'nt' nt},'datatype','double','format','classic')
    nccreate(result_fn,'LowThresh','Dimensions' ,{'nt' nt},'datatype','double','format','classic')
    nccreate(result_fn,'HighThresh','Dimensions' ,{'nt' nt},'datatype','double','format','classic')
    nccreate(result_fn, 'frontLength', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'classic')
    nccreate(result_fn, 'frontStrength', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'classic')
    nccreate(result_fn, 'frontWidth', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'classic')
    nccreate(result_fn, 'frontArea', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'classic')
    nccreate(result_fn, 'frontNumber', 'Dimensions', {'nt' nt}, 'datatype', 'double', 'format', 'classic')
    nccreate(result_fn, 'frontLengthCriterion', 'Dimensions', {'1' 1}, 'datatype', 'double', 'format', 'classic')
    % write variable into files
    ncwrite(result_fn,'lon',lon)
    ncwrite(result_fn,'lat',lat)
    ncwrite(result_fn,'mask',mask)
    ncwrite(result_fn,'temp',temp_mean)
    ncwrite(result_fn,'tgrad',tgrad_mean)
    ncwrite(result_fn,'LowThresh',low_thresh_month)
    ncwrite(result_fn,'HighThresh',high_thresh_month)
    % 
    ncwrite(result_fn, 'frontLength', frontLength_mean)
    ncwrite(result_fn, 'frontStrength', frontStrength_mean)
    ncwrite(result_fn, 'frontWidth', frontWidth_mean)
    ncwrite(result_fn, 'frontArea', frontArea_mean)
    ncwrite(result_fn, 'frontNumber', frontNumber_mean)
    ncwrite(result_fn, 'frontLengthCriterion', flen_crit4diag)
    % write file global attribute
    ncwriteatt(result_fn,'/','creation_date',datestr(now))
    ncwriteatt(result_fn,'/','data_source','OSTIA 5km SST')
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
    %
    frontLength_mean = ncread(result_fn, 'frontLength');
    frontStrength_mean = ncread(result_fn, 'frontStrength');
    frontWidth_mean = ncread(result_fn, 'frontWidth' );
    frontArea_mean = ncread(result_fn, 'frontArea' );
    frontNumber_mean = ncread(result_fn, 'frontNumber');
end

%plot month climatology figure
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
    fname = [fig_path,'/monthly_temp_',num2str(im,'%2.2d'),'_',smooth_type,'_',num2str(yy1),'to',num2str(yy2),'.png'];
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
    fname = [fig_path,'/monthly_tgrad_',num2str(im,'%2.2d'),'_',smooth_type,'_',num2str(yy1),'to',num2str(yy2),'.png'];
    export_fig(fname,'-png','-r200');
    close all
end
%
%plot front parameter diagnostic figure
month_string = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
xx = cellstr(month_string);

% bar image for front length
figure
bar(frontLength_mean*1e-3,0.5)
title('climatology front length diagnostic for mercator')
ylabel('km')
set(gca,'YLim',[80 200])
set(gca,'XTickLabel',xx)
export_fig([fig_path,'front_length_climatology_diagnostic_',smooth_type,'_',num2str(yy1),'to',num2str(yy2),'.png'],'-png','-r200');

% bar image for front length
figure
bar(frontStrength_mean,0.5)
title('climatology front strength diagnostic for mercator')
ylabel('\circC/km')
set(gca,'YLim',[0.01 0.05])
set(gca,'XTickLabel',xx)
export_fig([fig_path,'front_strength_climatology_diagnostic_',smooth_type,'_',num2str(yy1),'to',num2str(yy2),'.png'],'-png','-r200');

% bar image for front width
figure
bar(frontWidth_mean*1e-3,0.5)
title('climatology front width diagnostic for mercator')
ylabel('km')
set(gca,'YLim',[30 80])
set(gca,'XTickLabel',xx)
export_fig([fig_path,'front_width_climatology_diagnostic_',smooth_type,'_',num2str(yy1),'to',num2str(yy2),'.png'],'-png','-r200');

% bar image for front area
figure
bar(frontArea_mean*1e-6,0.5)
title('climatology front area diagnostic for mercator')
ylabel('km2')
set(gca,'YLim',[3000 12000])
set(gca,'XTickLabel',xx)
export_fig([fig_path,'front_area_climatology_diagnostic_',smooth_type,'_',num2str(yy1),'to',num2str(yy2),'.png'],'-png','-r200');

% bar image for front number
figure
bar(frontNumber_mean,0.5)
title('climatology front number diagnostic for mercator')
ylabel('#')
set(gca,'YLim',[60 200])
set(gca,'XTickLabel',xx)
export_fig([fig_path,'front_number_climatology_diagnostic_',smooth_type,'_',num2str(yy1),'to',num2str(yy2),'.png'],'-png','-r200');

close all

