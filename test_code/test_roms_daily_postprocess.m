% test frontline postprocessing and front parameter
% front length criterion test
% greater than 3 pixels
clc
clear all
close all
warning off
addpath(genpath('D:\lomf\frontal_detect\frontal_detection\'))
addpath(genpath('D:\matlab_function\export_fig\'))
%test for linesegment toolbox
addpath(genpath('D:\matlab_function\MatlabFns\'))
basedir = pwd;
%data setup
lat_s = 10; lat_n = 25;
lon_w = 105; lon_e = 121;
fntype = 'avg';
depth = 1;
%
fig_path = [basedir, '\Fig\test\postprocess\']; mkdir(fig_path)
data_path = [basedir, '\Data\roms\scs_new\']; mkdir(data_path)
result_path = [basedir, '\Result\test\']; mkdir(result_path)
% preprocess parameter
datatype = 'roms';
skip = 1;
smooth_type = 'gaussian';
sigma = 2;
N = 2;
fill_value = 0;
% detect parameter
% flen_crit = 0e3;
flen_crit = [];
thresh_in = [];
% postprocess parameter
logic_morph = 0;
season_test ='summer';
if strcmp(season_test,'winter')
    fn_mat_test = [result_path, 'detected_front_20150130.mat'];
elseif strcmp(season_test,'summer')
    fn_mat_test = [result_path, 'detected_front_20170801.mat'];
end
test_data = load(fn_mat_test);
grd = test_data.grd;
temp_zl = test_data.temp_zl;
dtime_str = datestr(grd.time, 'yyyymmdd');

% parameter for figure
fig_test = 1;
fig_product = 1;
line_width = 1;
thresh_max = 0.1;

[nx, ny] = size(temp_zl);
lon = grd.lon_rho;
lat = grd.lat_rho;

if fig_product
    flen_crit = [];  % use length auto-threshold
    [tfrontline, bw_line_detect, thresh_out, tgrad, tangle] = front_line(temp_zl, thresh_in, grd, flen_crit, logic_morph);
    fnum = length(tfrontline);
    [tfrontarea,bw_area] = front_area(tfrontline, tgrad, tangle, grd, thresh_out);
    [front_parameter] = cal_front_parameter(tfrontline,tfrontarea,grd);
    % test NetCDF output
    dump_type = 'netcdf';
    result_fn = [result_path,'detected_front_',dtime_str,'.nc'];
    if ~exist(result_fn)
        dump_front_stats(dump_type, result_fn, ...
            bw_line_detect, bw_area, temp_zl, ...
            grd, tfrontline, tfrontarea, front_parameter,...
            thresh_out, skip, flen_crit, ...
            datatype, smooth_type, fntype)
    end
    fig_type = 'front_product';
    fig_show = 'off';
    fig_fn = [fig_path, 'front_product_length_auto_thresh_',season_test,'.png'];
    plot_front_figure(lon_w, lon_e, lat_s, lat_n, fig_fn, ...
        bw_line_detect, bw_area, temp_zl, ...
        grd, tfrontline, tfrontarea, front_parameter, ...
        datatype, fig_type, fig_show);
    
end

if fig_test
    flen_crit = 0;  % no threshold for histogram
    [tfrontline, bw_line_detect, thresh_out, tgrad, tangle] = front_line(temp_zl, thresh_in, grd, flen_crit, logic_morph);
    fnum = length(tfrontline);
    % diagnostic of front length
    flength = zeros(fnum, 1);
    for ifr = 1:fnum
        flength(ifr) = tfrontline{ifr}.flen;
    end
    auto_length_thresh = ncread(result_fn,'length_thresh')*1e-3;
    % plot histogram of front length for test data
    figure
    front_length_values = [10 50 100 150 200]*1e3;
    hh = histogram(flength * 1e-3, front_length_values * 1e-3, 'Normalization', 'probability');
    line([auto_length_thresh auto_length_thresh],[0 max(hh.Values)])
    hold on
    xlabel('front length(km)')
    ylabel('probability')
    title([dtime_str,' auto length threshold: ',num2str(auto_length_thresh),' km'])
    fname = [fig_path, season_test,'_front_length_histogram.png'];
    export_fig(fname, '-png', '-r200');
end

fig_type = 'front_product';
fig_show = 'on';
for kk = 1:length(front_length_values)
    flen_crit = front_length_values(kk);
    % plot product figure with frontline and frontarea
    [tfrontline, bw_final, thresh_out, tgrad, tangle] = front_line(temp_zl, thresh_in, grd, flen_crit, logic_morph);
    fnum = length(tfrontline);
    [tfrontarea, bw_area] = front_area(tfrontline, tgrad, tangle, grd, thresh_out);
    
    figure('visible','on')
    m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
    P=m_pcolor(lon,lat,temp_zl);
    set(P,'LineStyle','none');
    shading interp
    hold on
    % frontline pixel overlaid
    for ifr = 1:fnum
        for ip = 1:length(tfrontline{ifr}.row)
            plon(ip) = lon(tfrontline{ifr}.row(ip),tfrontline{ifr}.col(ip));
            plat(ip) = lat(tfrontline{ifr}.row(ip),tfrontline{ifr}.col(ip));
            lon_left(ip) = tfrontarea{ifr}{ip}.lon(1);
            lat_left(ip) = tfrontarea{ifr}{ip}.lat(1);
            lon_right(ip) = tfrontarea{ifr}{ip}.lon(end);
            lat_right(ip) = tfrontarea{ifr}{ip}.lat(end);
        end
        poly_lon = [lon_left fliplr(lon_right)];
        poly_lat = [lat_left fliplr(lat_right)];
        m_patch(poly_lon,poly_lat,[.7 .7 .7],'FaceAlpha', .7,'EdgeColor','none')
        hold on
        m_plot(plon,plat,'k','LineWidth',1)
        hold on
        clear poly_lon poly_lat
        clear lon_left lat_left lon_right lat_right
        clear plon plat
    end
    colorbar
    colormap(jet);
    m_gshhs_i('patch', [.8 .8 .8], 'edgecolor', 'none');
    m_grid('box','fancy','tickdir','in','linest','none','ytick',0:5:40,'xtick',90:5:140);
    flen_crit_str = num2str(flen_crit*1e-3,'%3.3d');
    title(dtime_str)
    m_text(lon_w+1,lat_n-1,['front length >',flen_crit_str,'km'],'FontSize',14)
    export_fig([fig_path, season_test,'_front_product_length_greater_', flen_crit_str, 'km.png'],'-png','-r300');
    close all
end