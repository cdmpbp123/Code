% test script for pre-preprocess: morphological processing
clc; clear; 
close all;
warning off
opengl software
addpath(genpath('D:\lomf\frontal_detect\frontal_detection\'))
addpath(genpath('D:\matlab_function\m_map\'))
addpath(genpath('D:\matlab_function\export_fig\'))
addpath(genpath('D:\matlab_function\MatlabFns\'))
%
basedir='D:\lomf\frontal_detect\';

region_type = 'whole';
if strcmp(region_type,'whole')
    lat_s=10; lat_n=25;
    lon_w=105; lon_e=121;
elseif strcmp(region_type,'zoom_out')
    % zoom out exp
    lat_s=11; lat_n=17;
    lon_w=107; lon_e=111;
end
datatype='roms';
fntype = 'avg';
depth = 1;
%
fig_path = [basedir,'\Fig\test\preprocess\morph\']; mkdir(fig_path)
data_path = [basedir, '\Data\roms\scs_new\']; mkdir(data_path)
result_path = [basedir, '\Result\test\']; mkdir(result_path)
% preprocess parameter
skip = 1;
smooth_type = 'gaussian';
sigma = 2;
N = 2;
fill_value = 0;
% % detect parameter
% flen_crit = 100e3;
thresh_in = [];
% postprocess parameter
logic_morph = 1;

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

% gaussian filter
[temp_zl] = variable_preprocess(temp,smooth_type,fill_value);
%% test morphological processing result
[tgrad, tangle] = get_front_variable(temp_zl,grd);
%% edge localization
[bw, thresh_out] = edge_localization(temp_zl,tgrad,tangle,thresh_in);

[ri0, ci0] = findisolatedpixels(bw);
[rj0, cj0, re0, ce0] = findendsjunctions(bw);
% length(find(bw(:) == 1))
disp('raw')
disp(['isolate pixels= ',num2str(length(ri0))])
disp(['junction pixels= ',num2str(length(rj0))])
disp(['endpoint= ',num2str(length(re0))])
disp(['edge pixels = ',num2str(length(find(bw(:) == 1)))])

%necessary morphological processing to detect frontal line
%remove isolated frontal pixels
bw1 = bwmorph(bw,'clean'); 
[ri1, ci1] = findisolatedpixels(bw1);
[rj1, cj1, re1, ce1] = findendsjunctions(bw1);
disp('after cleaning')
disp(['isolate pixels= ',num2str(length(ri1))])
disp(['junction pixels= ',num2str(length(rj1))])
disp(['endpoint= ',num2str(length(re1))])
disp(['edge pixels = ',num2str(length(find(bw1(:) == 1)))])
% remove H-connect pixels
bw2 = bwmorph(bw1,'hbreak'); 
[ri2, ci2] = findisolatedpixels(bw2);
[rj2, cj2, re2, ce2] = findendsjunctions(bw2);
disp('after H-break')
disp(['isolate pixels= ',num2str(length(ri2))])
disp(['junction pixels= ',num2str(length(rj2))])
disp(['endpoint= ',num2str(length(re2))])
disp(['edge pixels = ',num2str(length(find(bw2(:) == 1)))])
%Make sure that edges are thinned or nearly thinned
bw3 = bwmorph(bw2,'thin', Inf); 
[ri3, ci3] = findisolatedpixels(bw3);
[rj3, cj3, re3, ce3] = findendsjunctions(bw3);
disp('after thinning')
disp(['isolate pixels= ',num2str(length(ri3))])
disp(['junction pixels= ',num2str(length(rj3))])
disp(['endpoint= ',num2str(length(re3))])
disp(['edge pixels = ',num2str(length(find(bw3(:) == 1)))])

return
figure;
imshow(rot90(bw))
title(['isolate pixels= ',num2str(length(ri0)),' ',...
    'junction pixels= ',num2str(length(rj0))])
export_fig([fig_path,'raw_image.png'],'-png','-r200');

figure;
imshow(rot90(eout))
title(['isolate pixels= ',num2str(length(ri0)),' ',...
    'junction pixels= ',num2str(length(rj0))])
export_fig([fig_path,'cleaning.png'],'-png','-r200')
%
    
figure;
imshow(rot90(eout))
title(['isolate pixels= ',num2str(length(ri0)),' ',...
    'junction pixels= ',num2str(length(rj0))])
export_fig([fig_path,'thinning.png'],'-png','-r200')
