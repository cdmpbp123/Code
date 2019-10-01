% front occurence frequency in binned map
% data: 20180101-20181231 for mercator reanalysis data
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
datatype = 'mercator';
fntype = 'daily';
depth = 1;
skip = 1;
% smooth_type = 'gaussian';
smooth_type = 'no_smooth';
sigma = 2;
N = 2;
fill_value = 0;
% detect parameter
flen_crit4diag = 20e3; % set new length criterion for diagnostic
thresh_in = [];
% postprocess parameter
logic_morph = 0;

yy1 = 2018;
yy2 = 2018;

% daily input path
result_path = [basedir, './Result/mercator/daily/', domain_name, '/']; mkdir(result_path)
% read climatology result
clim_result_path = [basedir, './Result/mercator/climatology/', domain_name, '/'];
% input file
clim_result_fn = [clim_result_path, '/mercator_front_monthly_climatology_', smooth_type, '_', num2str(yy1), 'to', num2str(yy2), '.nc'];
% output file
fig_path = [basedir, './Fig/mercator/climatology/', domain_name, '/']; mkdir(fig_path);
result_fn = [clim_result_path, '/mercator_front_frequency_map_', smooth_type, '_', num2str(yy1), 'to', num2str(yy2), '.nc'];

lon = ncread(clim_result_fn, 'lon');
lat = ncread(clim_result_fn, 'lat');
mask = ncread(clim_result_fn, 'mask');
temp_mean = ncread(clim_result_fn, 'temp');
tgrad_mean = ncread(clim_result_fn, 'tgrad');
low_thresh_month = ncread(clim_result_fn, 'LowThresh');
high_thresh_month = ncread(clim_result_fn, 'HighThresh');

[nx, ny] = size(lon);
nt = 12;
% bin size
bin_size = 9;
[lon_bin, lat_bin, mask_bin, var_bin, mark_bin, mark] = grid2bin(lon,lat,mask,mask,bin_size);
[nx_bin, ny_bin] = size(mask_bin);

front_freq_map = zeros(nx_bin,ny_bin,nt);
for im = 1:12
low_thresh = low_thresh_month(im);
high_thresh = high_thresh_month(im);

for ixb = 1:nx_bin
    for iyb = 1:ny_bin
%         tic
        if mask_bin(ixb,iyb) == 1
            front_freq_counter = 0;
            iday = 0;
            bin_index = find(mark == mark_bin(ixb,iyb));
            % loop of month and day 
            for iy = yy1:yy2
                for id = 1:1
                    day_string = [num2str(iy), num2str(im, '%2.2d'), num2str(id, '%2.2d')];
                    data_fn = [result_path, 'detected_front_', day_string, '.mat'];
                    if ~exist(data_fn)
                        continue
                    end
                    daily_struct = load(data_fn);
                    grd = daily_struct.grd;
                    temp_zl = daily_struct.temp_zl;
                    [tgrad, ~] = get_front_variable(temp_zl,grd);
                    
                    nn = find(tgrad(bin_index)> high_thresh);
                    front_freq_counter = front_freq_counter + length(nn);
                    iday = iday + 1;
                end
            end
            % end loop of month and day 
            front_freq_map(ixb,iyb,im) = front_freq_counter / (iday*bin_size*bin_size) ;
%             clear front_freq_counter iday
        end
%         toc
    end
end


end
