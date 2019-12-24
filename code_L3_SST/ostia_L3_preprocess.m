function [temp_zl,grd] = ostia_L3_preprocess(fn,lon_w,lon_e,lat_s,lat_n)
%preprocess of OSTIA SST data
%Input: 
%   fn: OSTIA L3 product filename with full path
%	lon_w,lon_e,lat_s,lat_n: domain boundary 
%Output:
%   temp_zl: temperature output
%   grd: struct variable of grid information 
lon1 = ncread(fn,'lon');
lat1 = ncread(fn,'lat');
mask_xi=find(lon1(:)>lon_w & lon1(:)<lon_e);
mask_eta=find(lat1(:)>lat_s & lat1(:)<lat_n);
%Set xi and eta limitation for South China Sea
eta_ind = min(mask_eta);
eta_len = length(mask_eta);
xi_ind = min(mask_xi);
xi_len =length(mask_xi);
%Read temperaturefrom OSTIA data
temp_zl = ncread(fn,'sea_surface_temperature',[xi_ind eta_ind 1],[xi_len eta_len 1]) - 273.15;
quality_level = ncread(fn,'quality_level',[xi_ind eta_ind 1],[xi_len eta_len 1]);
test_var = ncread(fn,'or_latitude',[xi_ind eta_ind 1],[xi_len eta_len 1]);
% info = ncinfo(fn);
% figure ; imagesc(test_var)
%mask of data
% Notice: no sea-land mask for OSTIA L3 data
[m,n]=size(temp_zl);
mask=ones(m,n);
mask(isnan(temp_zl))=0;
grd.mask_rho=mask;
%
temp_zl(mask==0)=0;
lon=ncread(fn,'lon',[xi_ind],[xi_len]);
lat=ncread(fn,'lat',[eta_ind],[eta_len]);
[grd.lat_rho,grd.lon_rho]=meshgrid(lat,lon);
grd.eta_ind=eta_ind;
grd.xi_ind=xi_ind;
grd.eta_len=eta_len;
grd.xi_len=xi_len;
% horizontal resolution for OSTIA L3 SST dataset : 0.1 degree
resolution=0.1;
pm=1./(cos(double(lat)*pi/180.)*111.1e3*resolution); 
pn=ones(size(lon))*1./(111.1e3*resolution);
[grd.pm,grd.pn]=meshgrid(pm,pn);
%get time stamp of ncfile: 
%'seconds since 1981-01-01 00:00:00'
ocean_time=ncread(fn,'time'); 
d0=datenum(1981,01,01,00,00,00);
d1=double(d0+ocean_time/3600/24);
% format read by datenum
grd.time=d1;
% datestr(d1,0)
end