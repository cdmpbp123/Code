function [temp_zl,grd] = hj_global_preprocess(fn,lon_w,lon_e,lat_s,lat_n)
    %preprocess of Mercator Reanalysis data:
    % 
    % data description: 
    %Input: 
    %   fn - Name of Mercator data file (file paths included)
    %   depth - depth that you want to extract
    %	lon_w,lon_e,lat_s,lat_n - domain boundary 
    %   skip - grid interval number of field 'temp_zl'
    %Output:
    %   temp_zl: temperature output
    %   grd: struct variable of grid information 
    %
    nctype = 1;
    if nctype == 1
        lon_vname = 'XT_OCEAN';
        lat_vname = 'YT_OCEAN';
        temp_vname = 'TEM';
        time_vname = 'TIME';
    elseif nctype == 2
        % for netCDF file format: ext-PSY4V3R1_1dAV_20171228_20171229_gridT_R20180110.nc 
        lon_vname = 'nav_lon';
        lat_vname = 'nav_lat';
        temp_vname = 'votemper';
        time_vname = 'time_counter';
    end
    
    lon1=ncread(fn,lon_vname);
    lat1=ncread(fn,lat_vname);
%     mask_xi=find(lon1(:)>lon_w & lon1(:)<lon_e);
%     mask_eta=find(lat1(:)>lat_s & lat1(:)<lat_n);
%     %Set xi and eta limitation for South China Sea
%     eta_ind = min(mask_eta);
%     eta_len = length(mask_eta);
%     xi_ind = min(mask_xi);
%     xi_len =length(mask_xi);
    %Read SST
    temp_zl = ncread(fn,temp_vname,[1 1 1 1],[Inf Inf 1 1]);
%     lon = ncread(fn,lon_vname,[xi_ind],[xi_len])  + 100;
%     lat = ncread(fn,lat_vname,[eta_ind],[eta_len]);
    [grd.lat_rho,grd.lon_rho] = meshgrid(lat1,lon1);
%     grd.eta_ind=eta_ind;
%     grd.xi_ind=xi_ind;
%     grd.eta_len=eta_len;
%     grd.xi_len=xi_len;
    % 0.1 is horizontal resolution for HJ global forecast
    resolution=0.1;
    pm=double(1./(cos(grd.lat_rho*pi/180.)*111.1e3*resolution)); 
    pn=double(ones(size(grd.lon_rho))*1./(111.1e3*resolution));
    grd.pm=pm;
    grd.pn=pn;
    %get time stamp of ncfile based on netCDF variable attribute 
    ocean_time=ncread(fn,time_vname); 
    date_start = ncreadatt(fn,time_vname,'units');
    S = regexp(date_start, '\s+', 'split');
    type = [S{1}];
    date_string = [S{end-1},' ',S{end}];
    d0 = datenum(date_string,31);
    % format read by datenum
    if strcmp(type,'hours')
        d1=double(d0+ocean_time/24);
    elseif strcmp(type,'seconds')
        d1=double(d0+ocean_time/24/3600);
    else
        d1 = double(d0+ocean_time);
    end
    grd.time=d1;
    %mask of data
    [m,n]=size(temp_zl);
    mask=ones(m,n);
    mask(isnan(temp_zl))=0;
    grd.mask_rho=mask;
    %
        
    end