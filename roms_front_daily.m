% extract daily frontal result to MAT and NetCDF file
% plot SST front figure 
% data: 11-year ROMS daily average SST data from 2007-2017
% data path: /work/person/rensh/Data/scs50_hindcast_nudg_new/
close all
clear all
warning off
clc
exp_name = 'scs50_hindcast';
% exp_name = 'scs50_hindcast_nudg_new';
%
platform = 'server197';
if strcmp(platform, 'hanyh_laptop')
    basedir = 'D:\lomf\frontal_detect\';
    % data_path = 'E:\DATA\Model\ROMS\scs_new\';
    toolbox_path = 'D:\matlab_function\';
 elseif strcmp(platform,'PC_office')
    basedir = 'D:\lomf\frontal_detect\';
    % data_path = 'S:\DATA\Model\ROMS\scs_new\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform,'server197')
    root_path = '/work/person/rensh/';
    basedir = [root_path,'/front_detect/'];
    data_path = [root_path,'/Data/',exp_name,'/'];
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

grdfn = [data_path,'scs50_grd.nc'];
fig_path = [basedir,'./Fig/roms/',domain_name,'/daily/'];mkdir(fig_path);
result_path = [basedir,'./Result/roms/',domain_name,'/daily/'];mkdir(result_path)

% front parameter setup
% preprocess parameter
datatype='roms';
fntype='avg';
depth = 1;
skip=1;
smooth_type = 'gaussian';
sigma = 2;
N = 2;
fill_value = 0;
% detect parameter
% flen_crit=0e3; % 20191018 experiment
flen_crit=[]; % 20191025 experiment
thresh_in = [];
% postprocess parameter
logic_morph = 0;
%
yy1 = 2017;
yy2 = 2017;

% daily loop
for iy = yy1:yy2
    year_mat_path = [result_path, num2str(iy), '/mat/']; mkdir(year_mat_path)
    year_netcdf_path = [result_path, num2str(iy), '/netcdf/']; mkdir(year_netcdf_path)
    year_fig_path = [fig_path, num2str(iy), '/']; mkdir(year_fig_path)
    for im = 1:12
        for id = 1:31            
            fn = [data_path,'scs50_avg_',num2str(iy),'.nc'];
            day_string = [num2str(iy),num2str(im,'%2.2d'),num2str(id,'%2.2d')]
            mat_fn = [year_mat_path, 'detected_front_', day_string, '.mat'];
            nc_fn = [year_netcdf_path,'detected_front_',day_string,'.nc'];
            [temp,grd] = roms_preprocess(fn,fntype,grdfn,depth,lon_w,lon_e,lat_s,lat_n,fill_value,skip,day_string);
            if isempty(temp) ||  exist(nc_fn) || exist(mat_fn)
                continue
            end
            
            [temp_zl]=variable_preprocess(temp,smooth_type,fill_value);
            [tfrontline,bw_line,thresh_out,tgrad,tangle] = front_line(temp_zl,thresh_in,grd,flen_crit,logic_morph);
            fnum = length(tfrontline);
            [tfrontarea, bw_area] = front_area(tfrontline, tgrad, tangle, grd, thresh_out);
            [front_parameter] = cal_front_parameter(tfrontline, tfrontarea, grd);
            % dump output
            dump_front_stats('MAT', mat_fn, ...
                bw_line, bw_area, temp_zl, ...
                grd, tfrontline, tfrontarea, front_parameter, ...
                thresh_out, skip, flen_crit, ...
                datatype, smooth_type, fntype)
            % NetCDF output
            dump_front_stats('netcdf', nc_fn, ...
                bw_line, bw_area, temp_zl, ...
                grd, tfrontline, tfrontarea, front_parameter, ...
                thresh_out, skip, flen_crit, ...
                datatype, smooth_type, fntype)
            % plot figures
            fig_type = 'front_product';
            fig_show = 'off';
            fig_fn = [year_fig_path, 'roms_front_product_', day_string, '.png'];
            plot_front_figure(lon_w, lon_e, lat_s, lat_n, fig_fn, ...
                bw_line, bw_area, temp_zl, ...
                grd, tfrontline, tfrontarea, front_parameter, ...
                datatype, fig_type, fig_show);
            close all
           
        end
    end
end