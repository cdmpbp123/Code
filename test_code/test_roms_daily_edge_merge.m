% edge merging test
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
basedir=pwd;
roms_path = 'E:\DATA\Model\ROMS\scs_new\';
grdfn = [roms_path,'scs_grd.nc'];
lat_s=10; lat_n=25;
lon_w=105; lon_e=121;
datatype='roms';
fntype = 'avg';
depth = 1;
%
fig_path = [basedir,'\Fig\test\edge_merge\']; mkdir(fig_path)
result_path = [basedir,'\Data\roms\scs_new\']; mkdir(result_path)
% preprocess parameter
skip=1;
smooth_type = 'gaussian';
sigma = 2;
N = 2;
fill_value = 0;
% detect parameter
flen_crit=100e3;
thresh_in = [];
thresh_max = 0.1;
% postprocess parameter
logic_morph = 0;
% daily
iy = 2015
im = 1
id = 30
fn = [roms_path,'scs_avg_',num2str(iy),'.nc'];
dnum = datenum(iy,im,id,0,0,0);
date_str = datestr(dnum,'yyyymmdd');
%
[temp,grd] = roms_preprocess(fn,fntype,grdfn,depth,lon_w,lon_e,lat_s,lat_n,fill_value,skip,date_str);
lon = grd.lon_rho;
lat = grd.lat_rho;
[temp_zl]=variable_preprocess(temp,'gaussian',fill_value);
[tgrad, tangle] = get_front_variable(temp_zl,grd);
%
disp('edge localization...')
[bw, thresh_out] = edge_localization(temp_zl,tgrad,tangle,thresh_in);
disp('edge following...')
[M,bw_new] = edge_follow(bw,tgrad,grd,tangle);
disp('test edge merge...')
[rj0, cj0, re0, ce0] = findendsjunctions(bw_new,1);
gapsize = 3;
blob = circularstruct(gapsize); % new blob extent for edge link from third-party toolbox
bsize = 2*gapsize+1;
%plot figure show blob extent
plot_binary_image_meshgrid(blob,[fig_path,'blob_map.png'],1)
% zoom out to show the effect of edge_merge
%boundary for zooming test
z_lats = 10;  z_latn = 16;
z_lonw = 108; z_lone = 112;
%figure for zooming
scatter_width = 5;
line_width = 1;
fig_merge_zoom_test = 1;
% test: choose two endpoints to be merged
re_test = [116,113]; 
ce_test = [30,30];
re_test3 = 112;
re_test3 = 7;
[test_front_idx] = locate_front(M,re_test,ce_test);
% extract these two edges and plot figure
bw_test = zeros(size(bw_new));
M_test = M(test_front_idx);
if fig_merge_zoom_test
    figure('visible','on')
    m_proj('Miller','lat',[z_lats z_latn],'lon',[z_lonw z_lone]);
    P = m_pcolor(lon,lat,tgrad);
    set(P,'LineStyle','none');
    shading interp
    hold on
    caxis([0 thresh_max])
    for ifr = 1:length(test_front_idx)
        row = M_test{ifr}.row;
        col = M_test{ifr}.col;
        for ip = 1:length(row)
            bw_test(row(ip),col(ip)) = 1;
            plon(ip) = lon(row(ip),col(ip));
            plat(ip) = lat(row(ip),col(ip));
        end
            clear row col
    hold on
    [x,y] = m_ll2xy(plon,plat);
    scatter(x,y,scatter_width,'k','fill','o')
    hold on
    clear plon plat x y
    end
    m_gshhs_i('patch',[.7 .7 .7],'edgecolor','none');
    m_grid('box','fancy','tickdir','in','linest','none','ytick',0:0.5:40,'xtick',90:0.5:140);
%     m_text(108.2,13.0,'before merge','FontSize',14)
    title('before merge','FontSize',14)
    export_fig([fig_path,'zoom_test_before_merge_',date_str,'.png'],'-png','-r200');
end
re_test1 = re_test(1);
ce_test1 = ce_test(1);
% this part from edge_merge funtion
[bw_loc0,blob_loc,row_g,col_g] = index_local_to_global(bw_test,re_test1,ce_test1,gapsize);
bw_loc = blob_loc & bw_loc0;
plot_binary_image_meshgrid(bw_loc0,[fig_path,'test_meshgrid_before_merge.png'],1)

bw_test_merge = filledgegaps(bw_test, gapsize);
[bw_loc0,blob_loc,~,~] = index_local_to_global(bw_test_merge,re_test1,ce_test1,gapsize);
bw_loc_merge = blob_loc & bw_loc0;
plot_binary_image_meshgrid(bw_loc0,[fig_path,'test_meshgrid_after_merge.png'],1)

if fig_merge_zoom_test
    % merge test
    [M_test_merge,bw_test_merge] = edge_merge(tgrad,grd,tangle,bw_test,M_test,gapsize);
    test_front_idx = 1;
    figure('visible','on')
    m_proj('Miller','lat',[z_lats z_latn],'lon',[z_lonw z_lone]);
    P = m_pcolor(lon,lat,tgrad);
    set(P,'LineStyle','none');
    shading interp
    hold on
    caxis([0 thresh_max])
    for ifr = 1:length(test_front_idx)
        row = M_test_merge{ifr}.row;
        col = M_test_merge{ifr}.col;
        for ip = 1:length(row)
            bw_test_merge(row(ip),col(ip)) = 1;
            plon(ip) = lon(row(ip),col(ip));
            plat(ip) = lat(row(ip),col(ip));
        end
        clear row col
        hold on
        [x,y] = m_ll2xy(plon,plat);
        scatter(x,y,scatter_width,'k','fill','o')
        hold on
        clear plon plat x y
    end
    m_gshhs_i('patch',[.7 .7 .7],'edgecolor','none');
    m_grid('box','fancy','tickdir','in','linest','none','ytick',0:0.5:40,'xtick',90:0.5:140);
    title('after merge','FontSize',14)
    export_fig([fig_path,'zoom_test_after_merge_',date_str,'.png'],'-png','-r200');
end

[M_merge,bw_merge] = edge_merge(tgrad,grd,tangle,bw_new,M,gapsize);
[rj1, cj1, re1, ce1] = findendsjunctions(bw_merge,1);
%
figure('visible','on')
m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
P=m_pcolor(lon,lat,temp_zl);
set(P,'LineStyle','none');
shading interp
hold on
% frontline pixel overlaid
[segment,fnum] = bwlabel(bw_merge,8);
for ifr = 1:fnum
    [row, col] = find(segment == ifr);
    for ip = 1:length(row)
        plon(ip) = lon(row(ip),col(ip));
        plat(ip) = lat(row(ip),col(ip));
    end
    [x,y] = m_ll2xy(plon,plat);
    scatter(x,y,line_width,'k','fill','o')
    hold on
    clear plon plat x y
    clear row col
end
%  caxis([15 30])
colorbar
colormap(jet);
m_gshhs_i('patch',[.7 .7 .7],'edgecolor','none');
m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:40,'xtick',90:2:140);
m_text(lon_w+1,lat_n-1,['frontline number: ',num2str(fnum)])
m_text(lon_w+1,lat_n-2,['junction pixels: ',num2str(length(rj0))])
export_fig([fig_path,'sst_frontline_edge_merge_',date_str,'.png'],'-png','-r200');



 






