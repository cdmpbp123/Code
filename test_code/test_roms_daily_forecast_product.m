% test what type of front forecast product should be
clc
clear all
close all
warning off
platform = 'hanyh_laptop';
if strcmp(platform, 'hanyh_laptop')
    basedir = 'D:\lomf\frontal_detect\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform, 'PC_office')
    basedir = 'D:\lomf\frontal_detect\';
    toolbox_path = 'D:\matlab_function\';
elseif strcmp(platform, 'server197')
    root_path = '/work/person/rensh/';
    basedir = [root_path, '/front_detect/'];
    toolbox_path = [root_path, '/matlab_function/'];
end

% add path of toolbox we use
addpath(genpath([toolbox_path, '/export_fig/']))
addpath(genpath([toolbox_path, '/m_map/']))
addpath(genpath([toolbox_path, '/MatlabFns/']))
addpath(genpath([basedir, '/frontal_detection/']))
%data setup
lat_s=10; lat_n=25;
lon_w=105; lon_e=121;
datatype='roms';
fntype = 'avg';
depth = 1;
%
fig_path = [basedir,'\Fig\test\product\']; mkdir(fig_path)
data_path = [basedir,'\Data\roms\scs_new\']; mkdir(data_path)
result_path = [basedir,'\Result\test\']; mkdir(result_path)
% preprocess parameter
skip=1;
smooth_type = 'gaussian';
sigma = 2;
N = 2;
fill_value = 0;
% detect parameter
flen_crit=100e3;
% flen_crit=0e3;
thresh_in = [];
% postprocess parameter
logic_morph = 0;

fn_mat_test = [data_path,'roms_test.mat'];
load(fn_mat_test)
dtime_str = datestr(grd.time,'yyyymmdd');

% parameter for figure
fig_test = 0;
line_width = 1;
thresh_max = 0.1;

temp = temp_zl;
[nx, ny] = size(temp_zl);
lon = grd.lon_rho;
lat = grd.lat_rho;

[temp_zl]=variable_preprocess(temp,'gaussian',fill_value);
% test frontline
[tfrontline,bw_final,thresh_out,tgrad, tangle] = front_line(temp_zl,thresh_in,grd,flen_crit,logic_morph);
fnum = length(tfrontline);
% test frontarea
[info_area,tfrontarea] = front_area(tfrontline,tgrad,tangle,grd,thresh_out);

% dump output
dump_type = 'MAT';
result_fn = [result_path,'detected_front_',dtime_str,'.mat'];
dump_front_stats(dump_type, result_fn, bw_final, temp_zl, ...
    grd, tfrontline, tfrontarea, info_area,...
    thresh_out, skip, flen_crit, datatype, smooth_type, fntype)

% plot figures
fig_type = 'front_product';
fig_fn = [fig_path,fig_type,'_',dtime_str,'.png'];
fig_show = 'on';
plot_front_figure(lon_w,lon_e,lat_s,lat_n,fig_fn, bw_final, temp_zl,...
    grd, tfrontline, tfrontarea, info_area, datatype, fig_type, fig_show);


% product
product_test = 1;
if product_test
    %export front parameter to list
    front_length = length(tfrontline);
    frontID = zeros(front_length,1);
    frontMidLon = zeros(front_length,1);
    frontMidLat = zeros(front_length,1);
    frontMeanTgrad = zeros(front_length,1);
    frontLength = zeros(front_length,1);
    frontArea = zeros(front_length,1);
    frontMaxWidth = zeros(front_length,1);
    frontMeanWidth = zeros(front_length,1);
    frontEquivalentWidth = zeros(front_length,1);
    for ifr = 1: front_length
        frontID(ifr,1) = ifr;
        frontMidLon(ifr,1) = tfrontline{ifr}.mid_lon;
        frontMidLat(ifr,1) = tfrontline{ifr}.mid_lat;
        frontMeanTgrad(ifr,1) = tfrontline{ifr}.tgrad_mean;
        frontLength(ifr,1) = tfrontline{ifr}.flen*1e-3;
        frontArea(ifr,1) = info_area{ifr}.area*1e-6;
        frontMaxWidth(ifr,1) = info_area{ifr}.max_width*1e-3;
        frontMeanWidth(ifr,1) = info_area{ifr}.mean_width*1e-3;
        frontEquivalentWidth(ifr,1) = info_area{ifr}.equivalent_width*1e-3;
    end
    csv_output_method = 2;
    %
    ID = num2cell(frontID);
    MidLon = roundn(frontMidLon,-2);
    MidLat = roundn(frontMidLat,-2);
    MeanTgrad = roundn(frontMeanTgrad,-2);
    Length = roundn(frontLength,-1);
    Area = roundn(frontArea,-3);
    MeanWidth = roundn(frontMeanWidth,-1);
    %
    header_names_ch = {'ID' '经度' '纬度' '平均强度(C/km)' '长度(km)' '面积(km2)' '宽度(km)'};
    header_names_en = {'ID' 'Lon' 'Lat' 'Magnitude(C/km)' 'Length(km)' 'Area(km2)' 'Width(km)'};
    header_names_char = string(header_names_ch);
    if csv_output_method == 1
        % method1: use function table, Chinese charactor is unsupported in table header.
        test_csvfn = 'test.csv';
        delete(test_csvfn)
        data = table(ID, MidLon, MidLat, MeanTgrad, Length, Area, MeanWidth,'VariableNames', header_names_en);
        writetable(data, test_csvfn)
    elseif csv_output_method == 2
        % method2: use low-level write 'fprintf' to txt file
        %
        test_txtfn = 'test.txt';
        delete(test_txtfn)
        fid = fopen(test_txtfn, 'w');
        fprintf(fid, ['%s\t','%s\t','%s\t','%s\t','%s\t','%s\t','%s\n'], header_names_char);
        for i= 1:front_length
            fprintf(fid, ['%s\t','%.2f\t','%.2f\t','%.2f\t','%.1f\t','%.1f\t','%.1f\n'], ...
                num2str(frontID(i)),frontMidLon(i),frontMidLat(i),frontMeanTgrad(i),frontLength(i),frontArea(i),frontMeanWidth(i));
        end
        fclose(fid)
        clear fid
    elseif csv_output_method == 3
        % method3: xlswrite
        % rtn=xlswrite(test_csvfn,cellstr('ID'),'A1:A1');
        % rtn=xlswrite(test_csvfn,cellstr('经度'),'B1:B1');
        % rtn=xlswrite(test_csvfn,cellstr('纬度'),'C1:C1');
        % rtn=xlswrite(test_csvfn,cellstr('平均强度(\circ/km)'),'D1:D1');
        % rtn=xlswrite(test_csvfn,cellstr('长度(km)'),'E1:E1');
        % rtn=xlswrite(test_csvfn,cellstr('面积(km^2)'),'F1:F1');
        % rtn=xlswrite(test_csvfn,cellstr('宽度(km)'),'G1:G1');
        % disp('excle head output OK!');
        % % format for every column
        % num2cell(frontID)
        % cc = {num2cell(frontID), frontMidLon};
        % xlswrite(test_csvfn,cc,1,'A2');
    end
    % image product
    dtime = grd.time;
    lon = grd.lon_rho;
    lat = grd.lat_rho;
    fnum = length(tfrontline);
    % test figure product type
    % SST + frontline + frontarea with transparent shading
    figure('visible','on')
    m_proj('Miller','lat',[lat_s lat_n],'lon',[lon_w lon_e]);
    P=m_pcolor(lon,lat,temp_smooth);
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
    %  caxis([15 30])
    colorbar
    colormap(jet);
    m_gshhs_i('patch', [.8 .8 .8], 'edgecolor', 'none');
    m_grid('box','fancy','tickdir','in','linest','none','ytick',0:2:40,'xtick',90:2:140);
    % title(['sst + frontline + frontzone'])
    % m_text(lon_w+1,lat_n-1,dtime_str)
    export_fig([fig_path,'test_sst_frontline_frontzone'],'-png','-r600');
end