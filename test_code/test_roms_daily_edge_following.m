% edge following test
clc; 
clear all;
close all;
warning off
opengl software
addpath(genpath('D:\lomf\frontal_detect\frontal_detection\'))
addpath(genpath('D:\matlab_function\m_map\'))
addpath(genpath('D:\matlab_function\export_fig\'))
addpath(genpath('D:\matlab_function\MatlabFns\'))
%
basedir='D:\lomf\frontal_detect\';

lat_s=10; lat_n=25;
lon_w=105; lon_e=121;
datatype='roms';
fntype = 'avg';
depth = 1;
%
data_path = [basedir, '\Data\roms\scs_new\']; mkdir(data_path)
fig_path = [basedir,'\Fig\test\edge_following\']; mkdir(fig_path)
result_path = [basedir,'\Data\roms\scs_new\']; mkdir(result_path)
% preprocess parameter
skip=1;
smooth_type = 'gaussian';
sigma = 2;
N = 2;
fill_value = 0;
% detect parameter
thresh_in = [];
% postprocess parameter
logic_morph = 0;

fn_mat_test = [data_path, 'roms_test.mat'];
mat_test = load(fn_mat_test);
temp = mat_test.temp_zl;
grd = mat_test.grd;
date_str = datestr(grd.time, 'yyyymmdd');

% parameter for figure
fig_test = 0;
line_width = 1;
thresh_max = 0.1;

[nx, ny] = size(temp);
lon = grd.lon_rho;
lat = grd.lat_rho;

[temp_zl]=variable_preprocess(temp,'gaussian',fill_value);
[tgrad, tangle] = get_front_variable(temp_zl,grd);
%
disp('edge localization...')
[bw, thresh_out] = edge_localization(temp_zl,tgrad,tangle,thresh_in);
disp('morphlogical processing')
bw = bwmorph(bw,'clean'); %remove isolated frontal pixels
bw = bwmorph(bw,'hbreak'); % remove H-connect pixels
bw = bwmorph(bw,'thin', Inf); %Make sure that edges are thinned or nearly thinned

[rj0, cj0, re0, ce0] = findendsjunctions(bw,0);
tgrad(tgrad>thresh_max) = thresh_max;
tgrad_bw = tgrad .* bw; tgrad_bw(tgrad_bw == 0) = NaN;
tangle_bw = tangle .* bw; tangle_bw(tangle_bw == 0) = NaN;
%calculate component of along-front direction
txgrad = tgrad_bw .* cosd(tangle_bw+90);
tygrad = tgrad_bw .* sind(tangle_bw+90);
txgrad1 = ones(size(txgrad))*NaN;
tygrad1 = ones(size(tygrad))*NaN;
% set skip
uv_interval = 4;
[segment,fnum] = bwlabel(bw,8);
for ifr = 1:fnum
    [row, col] = find(segment == ifr);
    for ip = 1:uv_interval:length(row)
        txgrad1(row(ip),col(ip)) = txgrad(row(ip),col(ip));
        tygrad1(row(ip),col(ip)) = tygrad(row(ip),col(ip));
    end
    clear row col
end
%figure parameter for gradient magnitude and front direction
vecscl = 0.8;
headlength = 2;
shaftwidth = 0.2;
fig_direction_whole = 0;
fig_direction_sample = 1;
% front direction + magnitude
if fig_direction_whole
    figure('visible','on')
    m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
    P = m_pcolor(lon,lat,tgrad);
    set(P,'LineStyle','none');
    shading interp
    hold on
    colorbar
    colormap(flipud(m_colmap('Blues')))
    caxis([0 thresh_max])
    m_gshhs_i('patch',[.7 .7 .7],'edgecolor','none');
    m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:40,'xtick',90:2:140);
    hpv4 = m_vec(vecscl,lon,lat,txgrad1,tygrad1, ...
        'shaftwidth',shaftwidth,...
        'headlength', headlength,...
        'edgeclip','on');
    [hpv5, htv5] = m_vec(vecscl,lon_w+1,lat_n-1,0.05,0,'k',...
        'key', '0.05\circC/km',...
        'shaftwidth',shaftwidth,...
        'headlength', headlength,...
        'edgeclip','on');
    set(htv5,'FontSize',12);
    export_fig([fig_path,'front_direction_before_edge_following_',date_str,'.png'],'-png','-r600');
end

% choose front located east of Hainan Island as a sample 
% to show how edge following module work
idx = 2; % manually seeking: rj =156, cj =278
rj = rj0(idx);
cj = cj0(idx);
txgrad1 = ones(size(txgrad))*NaN;
tygrad1 = ones(size(tygrad))*NaN;
% locate front index of branch pixels
for ifr = 1:fnum
    [row, col] = find(segment == ifr);
    [ip_idx] = find(row(:) == rj & col(:) == cj);
    if ~isempty(ip_idx)
        bw_ifr = bwselect(bw, col, row, 8);
        ifr_ind = ifr;
        break
    end
end
clear row col
% zoom out and only plot sample front figure
%boundary for zooming test
z_lats = 18.5;  z_latn = 20;
z_lonw = 110; z_lone = 111.5;
%figure for zooming
vecscl_z = 0.3;
shaftwidth_z = 0.5;
headlength_z = 3;
scatter_width = 10;
line_width = 1;
if fig_direction_sample
    figure('visible','on')
    m_proj('Miller','lat',[z_lats z_latn],'lon',[z_lonw z_lone]);
    [row, col] = find(segment == ifr_ind);
    for ip = 1:length(row)
        txgrad1(row(ip),col(ip)) = txgrad(row(ip),col(ip));
        tygrad1(row(ip),col(ip)) = tygrad(row(ip),col(ip));
        plon(ip) = lon(row(ip),col(ip));
        plat(ip) = lat(row(ip),col(ip));
    end
    clear row col
    hold on
    [x,y] = m_ll2xy(plon,plat);
    scatter(x,y,10,'k','fill','o')
    hold on
    clear plon plat x y
    plon = lon(rj,cj);
    plat = lat(rj,cj);
    [x,y] = m_ll2xy(plon,plat);
    scatter(x,y,20,'r','fill','o')
    hold on
    clear plon plat x y
    m_gshhs_i('patch',[.7 .7 .7],'edgecolor','none');
    m_grid('box','fancy','tickdir','in','linest','none','ytick',0:0.5:40,'xtick',90:0.5:140);
    m_text(110.1,19.9,'(a)','FontSize',14)
    hpv4 = m_vec(vecscl_z,lon,lat,txgrad1,tygrad1,'b',...
        'shaftwidth',shaftwidth_z,...
        'headlength', headlength_z,...
        'edgeclip','on');
    % [hpv5, htv5] = m_vec(vecscl_z,109.5,19.5,0.05,0,'r',...
    %     'key', '0.05\circC/km',...
    %     'shaftwidth',shaftwidth_z,...
    %     'headlength', headlength_z,...
    %     'edgeclip','on');
    % set(htv5,'FontSize',12);
    export_fig([fig_path,'zoom_front_direction_before_edge_following_',date_str,'.png'],'-png','-r200');
end
%implement function 'edge_follow' on specific front
[~,bw_follow] = edge_follow(bw_ifr,tgrad,grd,tangle);
txgrad1 = ones(size(txgrad))*NaN;
tygrad1 = ones(size(tygrad))*NaN;
if fig_direction_sample
    figure('visible', 'on')
    m_proj('Miller', 'lat', [z_lats z_latn], 'lon', [z_lonw z_lone]);
    [segment, fnum] = bwlabel(bw_follow, 8);

    for ifr = 1:fnum
        [row, col] = find(segment == ifr);

        for ip = 1:length(row)
            txgrad1(row(ip), col(ip)) = txgrad(row(ip), col(ip));
            tygrad1(row(ip), col(ip)) = tygrad(row(ip), col(ip));
            plon(ip) = lon(row(ip), col(ip));
            plat(ip) = lat(row(ip), col(ip));
        end

        % uniform mask with bw_follow
        txgrad1 = txgrad1 .* bw_follow;
        tygrad1 = tygrad1 .* bw_follow;
        [x, y] = m_ll2xy(plon, plat);
        scatter(x, y, scatter_width, 'k', 'fill', 'o')
        hold on
        clear plon plat x y
        clear row col
    end

    m_gshhs_i('patch', [.7 .7 .7], 'edgecolor', 'none');
    m_grid('box', 'fancy', 'tickdir', 'in', 'linest', 'none', 'ytick', 0:0.5:40, 'xtick', 90:0.5:140);
    m_text(110.1, 19.9, '(b)', 'FontSize', 14)
    m_text(110.7, 19.55, 'Seg. A', 'FontSize', 14)
    m_text(111.2, 19.75, 'Seg. B', 'FontSize', 14)
    hpv4 = m_vec(vecscl_z, lon, lat, txgrad1, tygrad1, 'b', ...
        'shaftwidth', shaftwidth_z, ...
        'headlength', headlength_z, ...
        'edgeclip', 'on');
    export_fig([fig_path, 'zoom_front_direction_after_edge_following_', date_str, '.png'], '-png', '-r200');
end

if fig_direction_whole
    disp('edge following...')
    [M, bw_new] = edge_follow(bw, tgrad, grd, tangle);
    [ri0, ci0] = findisolatedpixels(bw_new);
    [rj0, cj0, re0, ce0] = findendsjunctions(bw_new);
    %
    figure('visible', 'on')
    m_proj('Miller', 'lat', [lat_s lat_n], 'lon', [lon_w lon_e]);
    P = m_pcolor(lon, lat, temp_zl);
    set(P, 'LineStyle', 'none');
    shading interp
    hold on
    % frontline pixel overlaid
    [segment, fnum] = bwlabel(bw_new, 8);

    for ifr = 1:fnum
        [row, col] = find(segment == ifr);

        for ip = 1:length(row)
            plon(ip) = lon(row(ip), col(ip));
            plat(ip) = lat(row(ip), col(ip));
        end

        [x, y] = m_ll2xy(plon, plat);
        scatter(x, y, line_width, 'k', 'fill', 'o')
        hold on
        clear plon plat x y
        clear row col
    end

    hold on

    if ~isempty(rj0)
        % with branch points marker
        for ibr = 1:length(rj0)
            plon(ibr) = lon(rj0(ibr), cj0(ibr));
            plat(ibr) = lat(rj0(ibr), cj0(ibr));
        end

        [x, y] = m_ll2xy(plon, plat);
        scatter(x, y, 10, 'r', 'fill', 'o')
    end

    %  caxis([15 30])
    colorbar
    colormap(jet);
    m_gshhs_i('patch', [.7 .7 .7], 'edgecolor', 'none');
    m_grid('box', 'fancy', 'tickdir', 'in', 'linest', 'none', 'ytick', 0:2:40, 'xtick', 90:2:140);
    m_text(lon_w + 1, lat_n - 1, ['frontline number: ', num2str(fnum)])
    m_text(lon_w + 1, lat_n - 2, ['junction pixels: ', num2str(length(rj0))])
    export_fig([fig_path, 'sst_frontline_edge_follow_', date_str, '.png'], '-png', '-r200');

end






