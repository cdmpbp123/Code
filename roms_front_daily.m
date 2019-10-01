% extract daily frontal result to MAT file (temporary way, need to dumping in NetCDF),
% plot SST front figure 
% data: 11-year ROMS daily average SST data from 2007-2017
% data path: /work/person/rensh/Data/scs50_hindcast_nudg_new/
close all
clear all
clc
%
platform = 'server197';
if strcmp(platform, 'hanyh_laptop')
    basedir = 'D:\lomf\frontal_detect\';
    data_path = 'E:\DATA\Model\ROMS\scs_new\';
    toolbox_path = 'D:\matlab_function\';
 elseif strcmp(platform,'PC_office')
    basedir = 'D:\lomf\frontal_detect\';
    data_path = 'S:\DATA\Model\ROMS\scs_new\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform,'server197')
    root_path = '/work/person/rensh/';
    basedir = [root_path,'/front_detect/'];
    data_path = [root_path,'/Data/scs50_hindcast_nudg_new/'];
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
fig_path = [basedir,'./Fig/roms/',domain_name,'/'];mkdir(fig_path);
result_path = [basedir,'./Result/roms/',domain_name,'/'];mkdir(result_path)


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
flen_crit=50e3;
thresh_in = [];
% postprocess parameter
logic_morph = 0;
%
yy1 = 2007;
yy2 = 2017;


% daily loop
for iy = yy1:yy2
    for im = 1:12
        for id = 1:31            
            fn = [data_path,'scs50_avg_',num2str(iy),'.nc'];
            day_string = [num2str(iy),num2str(im,'%2.2d'),num2str(id,'%2.2d')]
            fig_fn = [fig_path,'sst_front_',day_string,'.png'];
            result_fn = [result_path,'detected_front_',day_string,'.mat'];
            [temp,grd] = roms_preprocess(fn,'avg',grdfn,depth,lon_w,lon_e,lat_s,lat_n,fill_value,skip,day_string);
            if isempty(temp) ||  exist(result_fn)
                continue
            end
            [temp_zl]=variable_preprocess(temp,smooth_type,fill_value);
            [tfrontline,bw_final,thresh_out,tgrad,tangle] = front_line(temp_zl,thresh_in,grd,flen_crit,logic_morph);
            fnum = length(tfrontline);
            [info_area,tfrontarea] = front_area(tfrontline,tgrad,tangle,grd,thresh_out);
            % dump output
            dump_type = 'MAT';
            dump_front_stats(dump_type, result_path, bw_final, temp_zl, ...
                grd, tfrontline, tfrontarea, info_area,...
                thresh_out, skip, flen_crit, datatype, smooth_type, fntype)
            % plot figures
            fig_type = 'front_product';
            fig_show = 'off';
            plot_front_figure(lon_w,lon_e,lat_s,lat_n,fig_path,bw_final, temp_zl,...
                grd, tfrontline, tfrontarea, info_area,fig_type,fig_show);
           
        end
    end
end