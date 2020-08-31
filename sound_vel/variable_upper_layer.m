% extract sound velocity in vertical layers
% Sound Velocity in sea water using UNESCO 1983 polynomial.
% SW_SVEL    from seawater function package
% % INPUT:  (all must have same dimensions)
%   S = salinity    [psu      (PSS-78)]
%   T = temperature [degree C (IPTS-68)]
%   P = pressure    [db]
%       (P may have dims 1x1, mx1, 1xn or mxn for S(mxn) )
clc; 
clear all;
close all;
warning off
opengl software
addpath(genpath('D:\lomf\frontal_detect\frontal_detection\'))
addpath(genpath('D:\matlab_function\m_map\'))
addpath(genpath('D:\matlab_function\export_fig\'))
addpath(genpath('D:\matlab_function\MatlabFns\'))
addpath('D:\matlab_function\seawater\')
%
basedir='D:\lomf\frontal_detect\';

if 0
lat_s=10; lat_n=25;
lon_w=105; lon_e=121;
datatype='roms';
fntype = 'avg';
skip = 1;
depth = [10:10:100,120:20:300];
%
ROMS_dir = 'E:\DATA\Model\ROMS\scs_new\';
fig_path = [basedir,'\Fig\sound_vel\'];
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
% get vertical grid informations
vc = fn_getvcinfo(fn);
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
%Read zeta,temperature/salinity, velocity from ROMS output
temp = ncread(fn,'temp',[xi_ind eta_ind 1 iday],[xi_len eta_len Inf 1],[skip skip 1 1]);
temp(temp>1e+9 | isnan(temp)) = 0;
salt = ncread(fn,'salt',[xi_ind eta_ind 1 iday],[xi_len eta_len Inf 1],[skip skip 1 1]);
salt(salt>1e+9 | isnan(salt)) = 0;
zeta = ncread(fn,'zeta',[xi_ind eta_ind 1],[xi_len eta_len 1],[skip skip 1]);
zeta(zeta>1e+9 | isnan(zeta)) = 0;
%
day_char = datestr(d1,'yyyymmdd');
lon = grd.lon_rho;
lat = grd.lat_rho;

for dd = 1:length(depth)
    depth_zl = depth(dd)
    temp_zl(:,:,dd) = roms3d_s2z(vc.s_rho,vc.Cs_r,vc.Tcline,zeta,grd.h,temp,depth_zl);
    salt_zl(:,:,dd) = roms3d_s2z(vc.s_rho,vc.Cs_r,vc.Tcline,zeta,grd.h,salt,depth_zl);
    pres_zl(:,:,dd) = sw_pres(depth_zl*ones(size(lat)),lat);
end
dens_zl = sw_dens(salt_zl,temp_zl,pres_zl);
svel_zl = sw_svel(salt_zl,temp_zl,pres_zl);
fn_mat_test = ['upper300m.mat'];
save(fn_mat_test)
end
fn_mat_test = ['upper300m.mat'];
load(fn_mat_test)

% read mean SSH
clim_fn = 'D:\lomf\frontal_detect\Data\roms\scs_new\scsnew_clim.nc';
mean_ssh = ncread(clim_fn,'zeta',[xi_ind eta_ind 1],[xi_len eta_len 1],[skip skip 1]);
mean_ssh(mean_ssh>1e+9 | isnan(mean_ssh)) = 0;
sla = zeta - mean_ssh;

mask = (temp_zl == 0);
temp_zl(mask) = NaN;
salt_zl(mask) = NaN;
dens_zl(mask) = NaN;
svel_zl(mask) = NaN;
sla(sla == 0) = NaN;
minT=floor(nanmin(temp_zl(:)));
maxT=ceil(nanmax(temp_zl(:)));
minS=floor(nanmin(salt_zl(:)));
maxS=ceil(nanmax(salt_zl(:)));    
minD=floor(nanmin(dens_zl(:)));
maxD=ceil(nanmax(dens_zl(:)));    
minSD=floor(nanmin(svel_zl(:)));
maxSD=ceil(nanmax(svel_zl(:)));  
minSLA=floor(nanmin(sla(:)));
maxSLA=ceil(nanmax(sla(:)));  
% front detection parameter
flen_crit = [];  
thresh_in = [];
logic_morph = 0;
temp10 = squeeze(temp_zl(:,:,1));
salt10 = squeeze(salt_zl(:,:,1));
dens10 = squeeze(dens_zl(:,:,1));
svel10 = squeeze(svel_zl(:,:,1));
% select two profiles in both side sof one front
xx = [177,178];
yy = [219,190];
tprof_p1 = squeeze(temp_zl(xx(1),yy(1),:));
tprof_p2 = squeeze(temp_zl(xx(1),yy(2),:));
tprof_average = squeeze(nanmean(nanmean(temp_zl,1),2));
sprof_p1 = squeeze(salt_zl(xx(1),yy(1),:));
sprof_p2 = squeeze(salt_zl(xx(1),yy(2),:));
sprof_average = squeeze(nanmean(nanmean(salt_zl,1),2));
dprof_p1 = squeeze(dens_zl(xx(1),yy(1),:));
dprof_p2 = squeeze(dens_zl(xx(1),yy(2),:));
dprof_average = squeeze(nanmean(nanmean(dens_zl,1),2));
svprof_p1 = squeeze(svel_zl(xx(1),yy(1),:));
svprof_p2 = squeeze(svel_zl(xx(1),yy(2),:));
svprof_average = squeeze(nanmean(nanmean(svel_zl,1),2));
% detect surface temp front
[tfrontline, bw_line_detect, thresh_out, tgrad, tangle] = front_line(temp10, thresh_in, grd, flen_crit, logic_morph);
fig_surface = 0
if fig_surface
    figure
    plot_variable_field(lon,lat,lon_w,lon_e,lat_s,lat_n,temp10,'temp',minT,maxT)
    hold on
    front_overlaid(lon,lat,tfrontline)
    hold on 
    for ip = 1:length(xx)
        plon = lon(xx(ip),yy(ip));
        plat = lat(xx(ip),yy(ip));
        [x,y] = m_ll2xy(plon,plat);
        scatter(x,y,10,'k','fill','o')
        hold on
    end
    export_fig([fig_path,'surface_temp.png'],'-png','-r300');

    % surface salinity
    figure
    plot_variable_field(lon,lat,lon_w,lon_e,lat_s,lat_n,salt10,'salinity',32,35)
    hold on
    export_fig([fig_path,'surface_salt.png'],'-png','-r300');
    % surface density
    figure
    plot_variable_field(lon,lat,lon_w,lon_e,lat_s,lat_n,dens10,'density',minD,maxD)
    hold on
    export_fig([fig_path,'surface_dens.png'],'-png','-r300');
    % surface sound_vel
    figure
    plot_variable_field(lon,lat,lon_w,lon_e,lat_s,lat_n,svel10,'sound velocity',minSD,maxSD)
    hold on
    export_fig([fig_path,'surface_svel.png'],'-png','-r300');
    figure
    plot_variable_field(lon,lat,lon_w,lon_e,lat_s,lat_n,sla,'SLA',-0.4,0.4)
    hold on
    export_fig([fig_path,'surface_sla.png'],'-png','-r300');
end


fig_profile = 0
if fig_profile
    figure 
    suptitle(['Profile'])
    subplot(2,2,1)
    plot(tprof_p1,depth,'r')
    hold on 
    plot(tprof_p2,depth,'b')
    hold on
    plot(tprof_average,depth,'k')
    axis ij
    legend('p1','p2','average','Location','best')
    xlabel('temp(degree)')
    subplot(2,2,2)
    plot(sprof_p1,depth,'r')
    hold on 
    plot(sprof_p2,depth,'b')
    hold on
    plot(sprof_average,depth,'k')
    axis ij
    xlabel('salt(psu)')
    subplot(2,2,3)
    plot(dprof_p1,depth,'r')
    hold on 
    plot(dprof_p2,depth,'b')
    hold on
    plot(dprof_average,depth,'k')
    axis ij
    xlabel('density(kg/m3)')
    subplot(2,2,4)
    plot(svprof_p1,depth,'r')
    hold on 
    plot(svprof_p2,depth,'b')
    hold on
    plot(svprof_average,depth,'k')
    axis ij
    xlabel('sound vel(m/s)')
    export_fig([fig_path,'profile.png'],'-png','-r300');
end

fig_multi_layer = 0
if fig_multi_layer
    for dd = 1:length(depth)
        depth_zl = depth(dd)
        temp = squeeze(temp_zl(:,:,dd));
        salt = squeeze(salt_zl(:,:,dd));
        dens = squeeze(dens_zl(:,:,dd));
        svel = squeeze(svel_zl(:,:,dd));
        figure('visible','off')
        suptitle(['depth = ',num2str(depth_zl,'%3.3d'),'m'])
        subplot(2,2,1) % temperature
        plot_variable_field(lon,lat,lon_w,lon_e,lat_s,lat_n,temp,'(a) temp',minT,maxT)
        subplot(2,2,2) % salinity
        plot_variable_field(lon,lat,lon_w,lon_e,lat_s,lat_n,salt,'(b) salt',32,35)
        subplot(2,2,3) % density
        plot_variable_field(lon,lat,lon_w,lon_e,lat_s,lat_n,dens,'(c) dens',minD,maxD)
        subplot(2,2,4) % sound velocity
        plot_variable_field(lon,lat,lon_w,lon_e,lat_s,lat_n,svel,'(d) svel',minSD,maxSD)
        export_fig([fig_path,'variable_depth_',num2str(depth_zl,'%3.3d'),'m_',day_char,'.png'],'-png','-r300');
        % print .fig file
    end
end

fn = 'test.nc';
[nx,ny] = size(lon);
nz = length(depth);
nccreate(fn,'lon','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','classic')
nccreate(fn,'lat','Dimensions' ,{'nx' nx 'ny' ny},'datatype','double','format','classic')
nccreate(fn,'sla','Dimensions',{'nx' nx 'ny' ny},'datatype','double','format','classic')
nccreate(fn,'temp','Dimensions',{'nx' nx 'ny' ny 'nz' nz},'datatype','double','format','classic')
nccreate(fn,'salt','Dimensions',{'nx' nx 'ny' ny 'nz' nz},'datatype','double','format','classic')
nccreate(fn,'dens','Dimensions',{'nx' nx 'ny' ny 'nz' nz},'datatype','double','format','classic')
nccreate(fn,'svel','Dimensions',{'nx' nx 'ny' ny 'nz' nz},'datatype','double','format','classic')
% write variable into files
ncwrite(fn,'lon',lon)
ncwrite(fn,'lat',lat)
ncwrite(fn,'sla',sla)
ncwrite(fn,'temp',temp_zl)
ncwrite(fn,'salt',salt_zl)
ncwrite(fn,'dens',dens_zl)
ncwrite(fn,'svel',svel_zl)
    
    
function plot_variable_field(lon,lat,lon_w,lon_e,lat_s,lat_n,var,text,cmin,cmax)
    m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]); 
    P=m_pcolor(lon,lat,var);
    set(P,'LineStyle','none');
    shading interp
    hold on
    m_gshhs_i('patch',[.7 .7 .7],'edgecolor','none');
    m_grid('box','fancy','tickdir','in','linest','none','ytick',0:5:40,'xtick',90:5:140);
    caxis([cmin cmax])
    colorbar
    colormap(jet);
    m_text(106,23,text)
end

function front_overlaid(lon,lat,tfrontline)
    % frontline pixel overlaid
    fnum = length(tfrontline);
    for ifr = 1:fnum
        for ip = 1:length(tfrontline{ifr}.row)
            plon(ip) = lon(tfrontline{ifr}.row(ip),tfrontline{ifr}.col(ip));
            plat(ip) = lat(tfrontline{ifr}.row(ip),tfrontline{ifr}.col(ip));
            % lon_left(ip) = tfrontarea{ifr}{ip}.lon(1);
            % lat_left(ip) = tfrontarea{ifr}{ip}.lat(1);
            % lon_right(ip) = tfrontarea{ifr}{ip}.lon(end);
            % lat_right(ip) = tfrontarea{ifr}{ip}.lat(end);
        end
        % poly_lon = [lon_left fliplr(lon_right)];
        % poly_lat = [lat_left fliplr(lat_right)];
        % m_patch(poly_lon,poly_lat,[.7 .7 .7],'FaceAlpha', .7,'EdgeColor','none')
        % hold on
        % clear poly_lon poly_lat
        % clear lon_left lat_left lon_right lat_right
        m_plot(plon,plat,'k','LineWidth',0.5)
        hold on
        clear plon plat
    end
end

