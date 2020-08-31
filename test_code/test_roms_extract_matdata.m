% extract roms test data 
clc
clear all
close all
warning off
addpath(genpath('D:\lomf\frontal_detect\frontal_detection\'))
addpath(genpath('D:\matlab_function\m_map1.4d\'))
addpath(genpath('D:\matlab_function\mexcdf.r4053\'))
addpath(genpath('D:\matlab_function\export_fig\'))
%
basedir=pwd;
%data setup
lat_s=10; lat_n=25;
lon_w=105; lon_e=121;
datatype='roms';
fntype = 'avg';
skip=1;
depth=1;
%
ROMS_dir = 'S:\DATA\Model\ROMS\scs_new\';
fig_path = [basedir,'\Fig\roms\scs_new\'];
result_path = [basedir,'\Data\roms\scs_new\'];
mkdir(fig_path)
mkdir(result_path)
grdfn = [ROMS_dir,'scs_grd.nc'];
%Get horizontal grid informations
[grd] = fn_getgrdinfo(grdfn,lon_w,lon_e,lat_s,lat_n,skip);
eta_ind=grd.eta_ind;
xi_ind=grd.xi_ind;
eta_len=grd.eta_len;
xi_len=grd.xi_len;
%
iy = 2015;
fn = [ROMS_dir,'scs_avg_',num2str(iy),'.nc'];
ocean_time = ncread(fn,'ocean_time');
day_number = length(ocean_time);
%
date_start = ncreadatt(fn,'ocean_time','units');
S = regexp(date_start, '\s+', 'split');
date_string = [S{end-1},' ',S{end}];
d0 = datenum(date_string,31);
%set day
iday = 30 ;
seconds = ncread(fn,'ocean_time',[iday],[1]);
d1=d0+seconds/3600/24;
grd.time=d1;
temp_info = ncinfo(fn,'temp');
nz = temp_info.Size(3);
temp = ncread(fn,'temp',[xi_ind eta_ind nz iday],[xi_len eta_len 1 1],[skip skip 1 1]);
temp(temp>1e+9 | isnan(temp)) = 0;
temp_zl = temp;
%
day_char = datestr(d1,'yyyymmdd');
fn_mat_test = [result_path,'roms_test.mat'];
save(fn_mat_test,'temp_zl','grd')