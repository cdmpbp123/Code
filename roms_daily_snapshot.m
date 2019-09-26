% extract frontal result and figure from ROMS avg data
close all
clear all
clc
%
opengl software
platform = 'hanyh_laptop';
if strcmp(platform, 'hanyh_laptop')
    basedir = 'D:\lomf\frontal_detect\';
    data_path = 'E:\DATA\Model\ROMS\scs_new\';
    toolbox_path = 'D:\matlab_function\';
 elseif strcmp(platform,'PC_office')
    basedir = 'D:\lomf\frontal_detect\';
    data_path = 'E:\DATA\obs\OSTIA\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform,'server197')
    root_path = '/work/person/rensh/';
    basedir = [root_path,'/front_detect/'];
    data_path = [root_path,'/Data/OSTIA/'];
    toolbox_path = [root_path,'/matlab_function/'];
end
grdfn = [data_path,'scs_grd.nc'];
fig_path = [basedir,'Fig\roms\daily\']; mkdir(fig_path)
result_path = [basedir,'Result\roms\daily\']; mkdir(result_path)

% %test ROMS SCS boundary
% lon_rho = ncread(grdfn,'lon_rho');
% lat_rho = ncread(grdfn,'lat_rho');
% lat_s = min(lat_rho(:));
% lat_n = max(lat_rho(:));
% lon_w = min(lon_rho(:));
% lon_e = max(lon_rho(:));
% figure('visible', 'on')
% m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w lon_e]);
% m_gshhs_i('patch', [.7 .7 .7], 'edgecolor', 'none');
% m_grid('box','fancy','tickdir','in','linest','none','ytick',-10:5:50,'xtick',90:5:140);


% domain setup
lat_s=-4; lat_n=28;
lon_w=99; lon_e=127;
% front parameter setup
fntype='avg';
flen_crit=100e3;
thresh_in = [];
logic_morph = 0;
depth = 1;
skip = 1;
smooth_type = 'gaussian';
fill_value = 0;
% daily loop
for iy = 2015:2015
    for im = 1:1
        for id = 1:1
% for iy = 2015:2017;
%     for im = 1:12
%         for id = 1:31            
            fn = [data_path,'scs_avg_',num2str(iy),'.nc'];
            dnum = datenum(iy,im,id,0,0,0);
            date_str = datestr(dnum,'yyyymmdd');
            [temp,grd] = roms_preprocess(fn,fntype,grdfn,depth,lon_w,lon_e,lat_s,lat_n,fill_value,skip,date_str);
            if isempty(temp)
                continue
            end
            [temp_zl]=variable_preprocess(temp,'gaussian',fill_value);
            [tfrontline,thresh_out] = front_line(temp_zl,thresh_in,grd,flen_crit,logic_morph);
            [tgrad, tangle] = get_front_variable(temp_zl,grd);
            fnum = length(tfrontline);
            % figure setup
            line_width = 1;
            lon = grd.lon_rho;
            lat = grd.lat_rho;
            % figure : sst + frontline
            fig_fn = [fig_path,'roms_sst_frontline_',date_str,'.png'];
            temp_zl(grd.mask_rho == 0) = NaN;
            figure('visible', 'on')
            m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w lon_e]);
            P = m_pcolor(lon, lat, temp_zl);
            set(P, 'LineStyle', 'none');
            shading interp
            hold on
            % frontline pixel overlaid
            for ifr = 1:fnum
                for ip = 1:length(tfrontline{ifr}.row)
                    plon(ip) = tfrontline{ifr}.lon(ip);
                    plat(ip) = tfrontline{ifr}.lat(ip);
                end
                m_plot(plon,plat,'k','LineWidth',line_width)
                hold on
                clear plon plat
            end
            %  caxis([15 30])
            grid on
            colorbar
            colormap(jet);
            m_gshhs_i('patch', [.7 .7 .7], 'edgecolor', 'none');
            m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:50,'xtick',90:5:140);
            m_text(lon_w+1,lat_n-1,[num2str(iy),num2str(im,'%2.2d'),num2str(id,'%2.2d')],'FontSize',14)
            export_fig(fig_fn, '-png', '-r200');
            close all
            % figure : tgrad + frontline
            fig_fn = [fig_path,'roms_tgrad_frontline_',date_str,'.png'];
            temp_zl(grd.mask_rho == 0) = NaN;
            figure('visible', 'on')
            m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w lon_e]);
            P = m_pcolor(lon, lat, tgrad);
            set(P, 'LineStyle', 'none');
            shading interp
            hold on
            % frontline pixel overlaid
            for ifr = 1:fnum
                for ip = 1:length(tfrontline{ifr}.row)
                    plon(ip) = tfrontline{ifr}.lon(ip);
                    plat(ip) = tfrontline{ifr}.lat(ip);
                end
                m_plot(plon,plat,'k','LineWidth',line_width)
                hold on
                clear plon plat
            end
            caxis([0 0.1])
            grid on
            colorbar
            colormap(flipud(m_colmap('Blues')))
            m_gshhs_i('patch', [.7 .7 .7], 'edgecolor', 'none');
            m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:50,'xtick',90:5:140);
            m_text(lon_w+1,lat_n-1,[num2str(iy),num2str(im,'%2.2d'),num2str(id,'%2.2d')],'FontSize',14)
            export_fig(fig_fn, '-png', '-r200');
            close all
        end
    end
end