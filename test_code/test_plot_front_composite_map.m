% plot front occurence frequency including raw grid and binned grid
% use front frequency map NetCDF file
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

% %set global variable
% global lat_n lat_s lon_w lon_e
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
fntype = 'daily';
yy1 = 2018;
yy2 = 2018;
fig_composite = 1;
%
daily_path = [basedir, './Result/', datatype, '/', domain_name, '/daily/'];
monthly_path = [basedir, './Result/', datatype, '/', domain_name, '/monthly/']; mkdir(monthly_path)
fig_path = [basedir, './Fig/', datatype, '/', domain_name, '/monthly/']; mkdir(fig_path);
grd_fn = [basedir, './Result/', datatype, '/', domain_name, '/',datatype,'_',domain_name,'_grd.nc'];
lon = ncread(grd_fn,'lon');
lat = ncread(grd_fn,'lat');
mask = ncread(grd_fn,'mask');
[nx, ny] = size(mask);
nt = 12;

if fig_composite
    composite_fig_path = [fig_path,'/composite/']; mkdir(composite_fig_path)
end
%
% plot monthly front figure


for iy = yy1:yy2
    result_fn = [monthly_path, '/front_composite_monthly_in_',num2str(iy),'.nc'];
    if ~exist(result_fn)
        composite_map_grey = zeros(nx,ny,nt);
        composite_map_color = zeros(nx,ny,nt);
        front_mid = cell(12,1);
             month_index_end = 0;
            
        for im = 1:12
            map_grey = zeros(nx,ny);
            map_color = zeros(nx,ny);
            front_midlon = [];
            front_midlat = [];
            
            for id = 1:31
                day_string = [num2str(iy), num2str(im, '%2.2d'), num2str(id, '%2.2d')];
                daily_fn = [daily_path,num2str(iy),'/mat/detected_front_',day_string,'.mat'];
                if ~exist(daily_fn)
                    continue
                end
                daily_struct = load(daily_fn);
                bw_line = daily_struct.bw_line;
                grd = daily_struct.grd;
                temp_zl = daily_struct.temp_zl;
                [tgrad, ~] = get_front_variable(temp_zl,grd);
                mask_line = logical(bw_line);
                % mark on map each day
                map_grey(mask_line) = 1;
                map_color(mask_line) = tgrad(mask_line);
                % find mid position for each front
                front_parameter = daily_struct.front_parameter;
                fnum = length(front_parameter);
                mlon = zeros(fnum,1);
                mlat = zeros(fnum,1);
                for ifr = 1:fnum
                    mlon(ifr) = front_parameter{ifr}.line_mid_lon;
                    mlat(ifr) = front_parameter{ifr}.line_mid_lat;
                end
                front_midlon = cat(1,front_midlon,mlon);
                front_midlat = cat(1,front_midlat,mlat);

            end
            month_index_start = month_index_end +1;
            month_index_end = month_index_end + length(front_midlon);
            front_mid{im}.midlon = front_midlon;
            front_mid{im}.midlat = front_midlat;
            front_mid{im}.month_index = [month_index_start:month_index_end];
            composite_map_grey(:,:,im) = map_grey;
            composite_map_color(:,:,im) = map_color;
            
        end
        front_midlon_year = [];
        front_midlat_year = [];
        front_mid_month_index = [];
        for im = 1:12
            front_midlon_year = cat(1,front_midlon_year,front_mid{im}.midlon);
            front_midlat_year = cat(1,front_midlat_year,front_mid{im}.midlat);
            idx_tmp = front_mid{im}.month_index;
            front_mid_month_index(idx_tmp) = im;
        end
        front_mid_number = length(front_midlon_year);
        % saving into yearly netcdf file
        % create variable with defined dimension
        nccreate(result_fn,'lon','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','classic')
        nccreate(result_fn,'lat','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','classic')
        nccreate(result_fn,'mask','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','classic')
        nccreate(result_fn, 'composite_map_grey', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'classic')
        nccreate(result_fn, 'composite_map_color', 'Dimensions', {'nx' nx 'ny' ny 'nt' nt}, 'datatype', 'double', 'format', 'classic')
        nccreate(result_fn, 'front_midlon_year', 'Dimensions', {'np' front_mid_number }, 'datatype', 'double', 'format', 'classic')
        nccreate(result_fn, 'front_midlat_year', 'Dimensions', {'np' front_mid_number }, 'datatype', 'double', 'format', 'classic')
        nccreate(result_fn, 'front_mid_month_index', 'Dimensions', {'np' front_mid_number }, 'datatype', 'double', 'format', 'classic')

        % write variable into files
        ncwrite(result_fn, 'lon', lon)
        ncwrite(result_fn, 'lat', lat)
        ncwrite(result_fn, 'mask', mask)
        ncwrite(result_fn, 'composite_map_grey', composite_map_grey)
        ncwrite(result_fn, 'composite_map_color', composite_map_color)
        ncwrite(result_fn, 'front_midlon_year', front_midlon_year)
        ncwrite(result_fn, 'front_midlat_year', front_midlat_year)
        ncwrite(result_fn, 'front_mid_month_index', front_mid_month_index)
        % write file global attribute
        ncwriteatt(result_fn, '/', 'creation_date', datestr(now))
        ncwriteatt(result_fn, '/', 'description', [datatype,' monthly front composite map with mid position in ',num2str(iy)])
        ncwriteatt(result_fn, '/', 'domain', domain_name)

    else
        % read composite netcdf file
        composite_map_grey = ncread(result_fn,'composite_map_grey');
        composite_map_color = ncread(result_fn,'composite_map_color');
        front_midlon_year = ncread(result_fn,'front_midlon_year');
        front_midlat_year = ncread(result_fn,'front_midlat_year');
        front_mid_month_index = ncread(result_fn,'front_mid_month_index'); 
    end

    if fig_composite
        scatter_width = 2;
        face_alpha = 0.5;
        fig_show = 'off';
        % set min&max value
        tgrad_min = 0.01; tgrad_max = 0.1;
        % set position for text
        X0 = lon_w + 0.05*(lon_e - lon_w);
        Y0 = lat_s +0.9*(lat_n - lat_s);

        for im = 1:12
            composite_map_month = squeeze(composite_map_color(:,:,im));
            plon = front_midlon_year(front_mid_month_index == im);
            plat = front_midlat_year(front_mid_month_index == im);
            % plot figure
            figure('visible',fig_show,'color',[1 1 1])
            m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
            composite_map_month(composite_map_month == 0) = NaN;
            P1=m_pcolor(lon,lat,composite_map_month);
            set(P1,'LineStyle','none','FaceAlpha',face_alpha);
            shading interp
            hold on
            hold on
            [x,y] = m_ll2xy(plon,plat);
            scatter(x,y,scatter_width,'k','fill','o')
            clear x y
            colorbar
            colormap(jet)
            caxis([tgrad_min tgrad_max])
            m_gshhs_i('patch', [.8 .8 .8], 'edgecolor', 'none');
            m_grid('box','fancy','tickdir','in','linest','none','ytick',-10:5:40,'xtick',90:5:150);
            m_text(X0,Y0,[num2str(iy),num2str(im,'%2.2d')],'FontSize',14)
            % title(['front line composite map (length>',num2str(flen_crit4plot*1e-3),'km) in month ',num2str(im,'%2.2d')])
            export_fig([composite_fig_path,'monthly_front_line_composite_map_',num2str(iy),num2str(im,'%2.2d')],'-png','-r200');
            
            clear plon plat composite_map_month
        end
    end
end



