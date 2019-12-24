% calculate daily SST rmse between ROMS and OSTIA from 2007-2017
% interpolate ROMS data to OSTIA grid
% TBD: add mercator for intercomparison, all data need to interpolated to _ostia grid 
close all
clear all
clc
% exp name:  scs50_hindcast_nudg_new, scsnew, scs50_hindcast
roms_exp_name = 'scsnew'; 
platform = 'server197';
if strcmp(platform, 'hanyh_laptop')
    basedir = 'D:\lomf\frontal_detect\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform,'PC_office')
    basedir = 'D:\lomf\frontal_detect\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform,'server197')
    root_path = '/work/person/rensh/';
    basedir = [root_path,'/front_detect/'];
    ostia_path = [root_path,'/Data/OSTIA/'];
    roms_path = [root_path,'/Data/ROMS/',roms_exp_name,'/'];
    mercator_path = [root_path,'/Data/Mercator/global-analysis-forecast-phy-001-024/'];
    toolbox_path = [root_path,'/matlab_function/'];
end

% add path of toolbox we use
addpath(genpath([toolbox_path,'/export_fig/']))
addpath(genpath([toolbox_path,'/m_map/']))
addpath(genpath([toolbox_path,'/MatlabFns/']))
addpath(genpath([basedir,'/frontal_detection/']))

domain = 3;
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

% preprocess parameter
depth = 1;
skip = 1;
smooth_type = 'no_smooth';
% sigma = 2;
% N = 2;
fill_value = 0;
%
yy1 = 2007;
yy2 = 2017;
%
fig_path = [basedir,'./Fig/comparison/',domain_name,'/climatology/'];mkdir(fig_path);
result_path = [basedir,'./Result/comparison/',domain_name,'/climatology/'];mkdir(result_path)
% get OSTIA grd from test filename
iy = 2017; im = 1; id = 1;
day_string = [num2str(iy),num2str(im,'%2.2d'),num2str(id,'%2.2d')];
ostia_data_path = [ostia_path,num2str(iy),'/'];
ostia_test = [ostia_data_path,day_string,'-UKMO-L4HRfnd-GLOB-v01-fv02-OSTIA.nc'];
%set margin to make sure ROMS grid is larger than OSTIA grid
margin = 0.2;
[~,ostia_grd] = ostia_preprocess(ostia_test,lon_w+margin ,lon_e-margin, lat_s+margin ,lat_n-margin);
% ROMS grd
grdfilename = dir([roms_path,'*_grd.nc']);
roms_grdfn = [grdfilename.folder,'/',grdfilename.name];
roms_filename = dir([roms_path,'scs*_avg_',num2str(iy),'.nc']);
roms_fn = [roms_filename.folder,'/',roms_filename.name];
[~,roms_grd] = roms_preprocess(roms_fn,'avg',roms_grdfn,depth,lon_w,lon_e,lat_s,lat_n,fill_value,skip,day_string);
% Mercator grid
mercator_filename = dir([mercator_path,'mercatorpsy4v3r1_gl12_mean_',day_string,'*.nc']);
mercator_fn = [mercator_filename.folder,'/',mercator_filename.name];
[~, mercator_grd] = mercator_preprocess(mercator_fn, depth, lon_w, lon_e, lat_s, lat_n, skip);
clear iy im id
%
Olon = double(ostia_grd.lon_rho);
Olat = double(ostia_grd.lat_rho);
Omask = double(ostia_grd.mask_rho);
Mlon = double(roms_grd.lon_rho);
Mlat  = double(roms_grd.lat_rho);
Mmask = double(roms_grd.mask_rho);
Rlon = double(mercator_grd.lon_rho);
Rlat  = double(mercator_grd.lat_rho);
Rmask = double(mercator_grd.mask_rho);

[nx,ny] = size(Omask);
nt = 12;
temp_ostia_mean = zeros(nx,ny,nt);
temp_roms_mean = zeros(nx,ny,nt);
temp_mercator_mean = zeros(nx,ny,nt);
roms_rmse_mean = zeros(nx,ny,nt);
mercator_rmse_mean = zeros(nx,ny,nt);
total_days_monthly = zeros(nt,1);
%begin loop
for im = 1:nt
    iday = 0;
    temp_ostia_sum = zeros(size(Olon));
    temp_roms_sum = zeros(size(Olon));
    temp_mercator_sum = zeros(size(Olon));
    rmse_roms_num = zeros(size(Olon));
    rmse_mercator_num = zeros(size(Olon));
    disp(['month: ',num2str(im)]);
    for iy = yy1:yy2
        for id = 1:31
            day_string = [num2str(iy),num2str(im,'%2.2d'),num2str(id,'%2.2d')];
            ostia_data_path = [ostia_path,num2str(iy),'/'];
            ostia_fn = [ostia_data_path,day_string,'-UKMO-L4HRfnd-GLOB-v01-fv02-OSTIA.nc'];
            if ~exist(ostia_fn)
                continue
            else
                iday = iday + 1;
            end
            disp(['day ',num2str(iday)]);
            [temp,~] = ostia_preprocess(ostia_fn,lon_w+margin ,lon_e-margin, lat_s+margin ,lat_n-margin);
            [ostia_temp] = variable_preprocess(temp,smooth_type,fill_value);
            ostia_temp(Omask == 0) = NaN;
            clear temp
            % ROMS
            roms_filename = dir([roms_path,'scs*_avg_',num2str(iy),'.nc']);
            roms_fn  = [roms_filename.folder,'/',roms_filename.name];
            [temp,~] = roms_preprocess(roms_fn,'avg',roms_grdfn,depth,lon_w,lon_e,lat_s,lat_n,fill_value,skip,day_string);
            if isempty(temp)
                continue
            end
            [roms_temp]=variable_preprocess(temp,smooth_type,fill_value);
            roms_temp(Mmask == 0) = NaN;
            clear temp
            roms_temp_interp = griddata(Mlon,Mlat,roms_temp,Olon,Olat,'linear');
            % Mercator
            mercator_filename = dir([mercator_path,'mercatorpsy4v3r1_gl12_mean_',day_string,'*.nc']);
            mercator_fn = [mercator_filename.folder,'/',mercator_filename.name];
            [temp, ~] = mercator_preprocess(mercator_fn, depth, lon_w, lon_e, lat_s, lat_n, skip);
            [mercator_temp] = variable_preprocess(temp,smooth_type,fill_value);
            mercator_temp(Rmask == 0) = NaN;
            clear temp
            mercator_temp_interp = griddata(Rlon,Rlat,mercator_temp,Olon,Olat,'linear');
            % initial mask for both _ostia and _roms
            maskOM = zeros(size(Omask));
            maskOM(isnan(roms_temp_interp)~=1 & isnan(ostia_temp)~=1 & isnan(mercator_temp_interp)~=1) = 1;
            ostia_temp(maskOM == 0) = NaN;
            roms_temp_interp(maskOM == 0) = NaN;
            mercator_temp_interp(maskOM == 0) = NaN;

            temp_ostia_sum = temp_ostia_sum + ostia_temp;
            temp_roms_sum = temp_roms_sum + roms_temp_interp;
            temp_mercator_sum = temp_mercator_sum + mercator_temp_interp;
            rmse_roms_num = rmse_roms_num + (ostia_temp - roms_temp_interp).^2;
            rmse_mercator_num = rmse_mercator_num + (ostia_temp - mercator_temp_interp).^2;
            
        end
    end
    disp(['month ',num2str(im),': total days: ',num2str(iday)])
    temp_ostia_mean(:,:,im) = temp_ostia_sum / iday;
    temp_roms_mean(:,:,im) = temp_roms_sum / iday;
    temp_mercator_mean(:,:,im) = temp_mercator_sum / iday;
    roms_rmse_mean(:,:,im) = sqrt(rmse_roms_num / iday);
    mercator_rmse_mean(:,:,im) = sqrt(rmse_mercator_num / iday);
    total_days_monthly(im) = iday;
    % clear iday temp_ostia_sum temp_roms_sum rmse_num
end
save('sst_rmse_test_20191223.mat', ...
    'temp_ostia_mean', ...
    'temp_roms_mean', ...
    'temp_mercator_mean', ...
    'roms_rmse_mean', ...
    'mercator_rmse_mean', ...
    'total_days_monthly')
result_fn = [result_path,'sst_rmse_climatology_',smooth_type,'_',num2str(yy1),'to',num2str(yy2),'.nc'];
% create variable with defined dimension
nccreate(result_fn,'lon','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','classic')
nccreate(result_fn,'lat','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','classic')
nccreate(result_fn,'mask','Dimensions',{'nx' nx 'ny' ny},'datatype','double','format','classic')
nccreate(result_fn,'temp_ostia','Dimensions',{'nx' nx 'ny' ny 'nt' nt},'datatype','double','format','classic')
nccreate(result_fn,'temp_roms','Dimensions',{'nx' nx 'ny' ny 'nt' nt},'datatype','double','format','classic')
nccreate(result_fn,'temp_mercator','Dimensions',{'nx' nx 'ny' ny 'nt' nt},'datatype','double','format','classic')
nccreate(result_fn,'roms_rmse','Dimensions',{'nx' nx 'ny' ny 'nt' nt},'datatype','double','format','classic')
nccreate(result_fn,'mercator_rmse','Dimensions',{'nx' nx 'ny' ny 'nt' nt},'datatype','double','format','classic')
nccreate(result_fn,'total_days_monthly','Dimensions',{'nt' nt},'datatype','double','format','classic')
% write variable into files
ncwrite(result_fn,'lon',Olon)
ncwrite(result_fn,'lat',Olat)
ncwrite(result_fn,'mask',maskOM)
ncwrite(result_fn,'temp_ostia',temp_ostia_mean)
ncwrite(result_fn,'temp_roms',temp_roms_mean)
ncwrite(result_fn,'temp_mercator',temp_mercator_mean)
ncwrite(result_fn,'roms_rmse',roms_rmse_mean)
ncwrite(result_fn,'mercator_rmse',mercator_rmse_mean)
ncwrite(result_fn,'total_days_monthly',total_days_monthly)
% write file global attribute 
ncwriteatt(result_fn,'/','creation_date',datestr(now))
ncwriteatt(result_fn,'/','platform',platform)
ncwriteatt(result_fn,'/','description','climatology monthly SST RMSE')
ncwriteatt(result_fn,'/','roms_path',roms_path)
ncwriteatt(result_fn,'/','ostia_path',ostia_path)
ncwriteatt(result_fn,'/','mercator_path',mercator_path)
ncwriteatt(result_fn,'/','domain',domain_name)
ncwriteatt(result_fn,'/','grid_skip_number',num2str(skip))
ncwriteatt(result_fn,'/','smooth_type',smooth_type)