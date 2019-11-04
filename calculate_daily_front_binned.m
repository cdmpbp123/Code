% calculate daily front occurence number in each bin
close all
clear all
clc
%
platform = 'server197';
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
datatype = 'ostia';
fntype = 'daily';
depth = 1;
skip = 1;
smooth_type = 'gaussian';
sigma = 2;
N = 2;
fill_value = 0;
thresh_in = [];
% postprocess parameter
logic_morph = 0;

yy1 = 2018;
yy2 = 2018;

daily_path = [basedir, './Result/', datatype, '/', domain_name, '/daily/'];
clim_path = [basedir, './Result/', datatype, '/', domain_name, '/climatology/'];mkdir(clim_path)
% input file
fig_path = [basedir, './Fig/',datatype,'/', domain_name, '/climatology/']; mkdir(fig_path);
grd_fn = [basedir, './Result/', datatype, '/', domain_name, '/',datatype,'_',domain_name,'_grd.nc'];
lon = ncread(grd_fn,'lon');
lat = ncread(grd_fn,'lat');
mask = ncread(grd_fn,'mask');
[nx, ny] = size(mask);
nt = 12;
% set a new regular grid
bin_resolution = 0.5; % unit: degree
[lon_bin, lat_bin, mask_bin, mask_cell,~] = grid_to_bin(lon,lat,mask,bin_resolution,lon_w,lon_e,lat_s,lat_n);
[nx_bin,ny_bin] = size(lon_bin);
for iy = yy1:yy2
    fn = [daily_path, '/concatenate_front_daily_',num2str(iy),'.nc'];
    result_fn = [daily_path, '/concatenate_front_daily_binned_',num2str(bin_resolution),'degree_',num2str(iy),'.nc'];
    if -exist(fn) || exist(result_fn)
        continue
    end
    datetime = ncread(fn,'datetime');
    ndays = length(datetime);
    frontarea_counter_bin = zeros(nx_bin,ny_bin,ndays);
    frontline_counter_bin = zeros(nx_bin,ny_bin,ndays);
    for iday = 1:ndays
        bw_line = ncread(fn,'bw_line_daily',[1 1 iday],[Inf Inf 1]);
        bw_area = ncread(fn,'bw_area_daily',[1 1 iday],[Inf Inf 1]);
        [frontarea_counter_bin(:,:,iday),total_counter_bin] = interpolate_daily_front_bin(bw_area,lon_bin, lat_bin, mask_bin, mask_cell);
        [frontline_counter_bin(:,:,iday),~] = interpolate_daily_front_bin(bw_line,lon_bin, lat_bin, mask_bin, mask_cell);
    end
    total_counter_bin_ndays = repmat(total_counter_bin,1,1,ndays);
    frontarea_ratio_bin = frontarea_counter_bin./total_counter_bin_ndays;
    frontline_ratio_bin = frontline_counter_bin./total_counter_bin_ndays;
    % write to NetCDF file
    % create variable with defined dimension
    nccreate(result_fn,'lon','Dimensions' ,{'nx' nx_bin 'ny' ny_bin},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn,'lat','Dimensions' ,{'nx' nx_bin 'ny' ny_bin},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn,'mask','Dimensions' ,{'nx' nx_bin 'ny' ny_bin},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn,'total_counter_bin','Dimensions' ,{'nx' nx_bin 'ny' ny_bin},'datatype','double','format','netcdf4_classic')
    nccreate(result_fn, 'datetime', 'Dimensions', {'nt' ndays}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'frontarea_counter_bin', 'Dimensions', {'nx' nx_bin 'ny' ny_bin 'nt' ndays}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'frontline_counter_bin', 'Dimensions', {'nx' nx_bin 'ny' ny_bin 'nt' ndays}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'frontarea_ratio_bin', 'Dimensions', {'nx' nx_bin 'ny' ny_bin 'nt' ndays}, 'datatype', 'double', 'format', 'netcdf4_classic')
    nccreate(result_fn, 'frontline_ratio_bin', 'Dimensions', {'nx' nx_bin 'ny' ny_bin 'nt' ndays}, 'datatype', 'double', 'format', 'netcdf4_classic')
    % write variable into files
    ncwrite(result_fn, 'lon', lon_bin)
    ncwrite(result_fn, 'lat', lat_bin)
    ncwrite(result_fn, 'mask', mask_bin)
    ncwrite(result_fn, 'total_counter_bin', total_counter_bin)
    ncwrite(result_fn, 'datetime', datetime)
    ncwrite(result_fn, 'frontarea_counter_bin', frontarea_counter_bin)
    ncwrite(result_fn, 'frontline_counter_bin', frontline_counter_bin)
    ncwrite(result_fn, 'frontarea_ratio_bin', frontarea_ratio_bin)
    ncwrite(result_fn, 'frontline_ratio_bin', frontline_ratio_bin)
    % write file global attribute
    ncwriteatt(result_fn, '/', 'creation_date', datestr(now))
    ncwriteatt(result_fn, '/', 'description', [datatype,' concatenate front daily output in ',num2str(iy),'with bin grid'])
    ncwriteatt(result_fn, '/', 'domain', domain_name)
    ncwriteatt(result_fn, '/', 'smooth_type', smooth_type)
end


function  [front_counter_bin,total_counter_bin] = interpolate_daily_front_bin(front_raw_grid,lon_bin, lat_bin, mask_bin, mask_cell)
% interpolate frontal area/line binary map to regular binned map
% use front counter divided by total bin counter as front strength
[nx_bin,ny_bin] = size(lon_bin);
total_counter_bin = zeros(nx_bin,ny_bin);
front_counter_bin = zeros(nx_bin,ny_bin);

for ixb = 1:nx_bin
    for iyb = 1:ny_bin
        
        if mask_bin(ixb,iyb) == 1
            mask_tmp = mask_cell{ixb,iyb};
            xx_ind = mask_tmp.xx;
            yy_ind = mask_tmp.yy;
            nonan_num = mask_tmp.nonan_num;
            total_counter_bin(ixb,iyb) = nonan_num;
            
            % detected front area/line counter
            front_counter_index  = find(front_raw_grid(xx_ind,yy_ind) == 1);
            front_counter_bin(ixb,iyb) = length(front_counter_index);
            
            clear mask_tmp  xx_ind yy_ind
            clear  frontline_counter_index
        end
        
    end
end
total_counter_bin(mask_bin == 0) = NaN;
front_counter_bin(mask_bin == 0) = NaN;

end







