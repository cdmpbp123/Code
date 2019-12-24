% test frontarea and frontline algorithms validation
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
datatype = 'roms';
fntype = 'avg';
depth = 1;
%
fig_path = [basedir, '\Fig\test\validation\']; mkdir(fig_path)
data_path = [basedir, '\Data\roms\scs_new\']; mkdir(data_path)
result_path = [basedir, '\Result\test\']; mkdir(result_path)
% preprocess parameter
skip = 1;
smooth_type = 'gaussian';
sigma = 2;
N = 2;
fill_value = 0;
% detect parameter
flen_crit = 0e3;
thresh_in = [];
% postprocess parameter
logic_morph = 0;

fn_mat_test = [data_path, 'roms_test.mat'];
load(fn_mat_test)
dtime_str = datestr(grd.time, 'yyyymmdd');

% parameter for figure
fig_test = 0;
line_width = 1;
thresh_max = 0.1;

temp = temp_zl;
[nx, ny] = size(temp_zl);
lon = grd.lon_rho;
lat = grd.lat_rho;
[temp_zl] = variable_preprocess(temp, smooth_type, fill_value);

front_length_values = [10 50 100 150 200];
for kk = 1:length(front_length_values)
    flen_crit = front_length_values(kk)*1e3;
    [frontline_bias(kk), frontline_TS(kk), frontline_FAR(kk), frontline_MR(kk), frontline_FA(kk), frontline_DR(kk), frontLength_mean(kk), frontNumber(kk)] ...,
        = get_detect_validation_score(temp_zl,grd,flen_crit,thresh_in,logic_morph,'frontline');
    [frontarea_bias(kk), frontarea_TS(kk), frontarea_FAR(kk), frontarea_MR(kk), frontarea_FA(kk), frontarea_DR(kk)] ...,
        = get_detect_validation_score(temp_zl,grd,flen_crit,thresh_in,logic_morph,'frontarea');
end

% output to csv or txt file
frontarea_score_type = {'Bias';'Threat Score(TS)';'False Alarm Rate(FAR)';'Miss rate(MR)';'Forecast Accuracy(FA)';'Detectability Rate(DR)'};
frontline_score_type = cat(1,frontarea_score_type,{'Mean front length';'Front number'});
header_names_en = {'Type' 'L10km' 'L50km' 'L100km' 'L150km' 'L200km'};
% header_names_en = {'Type' 'a10km' 'a50km' 'a100km' 'a150km' 'a200km'};
header_names_char = string(header_names_en);
frontline_score = [frontline_bias; frontline_TS; frontline_FAR; frontline_MR; frontline_FA; frontline_DR; frontLength_mean; frontNumber];
frontarea_score =  [frontarea_bias; frontarea_TS; frontarea_FAR; frontarea_MR; frontarea_FA; frontarea_DR];
frontline_score = roundn(frontline_score,-2);
frontarea_score = roundn(frontarea_score,-2);

% test_csvfn = [result_path,'test_length_greater_than_',flen_crit_string,'.csv'];
frontarea_csvfn = [fig_path,'frontarea_score_table.csv'];
delete(frontarea_csvfn)
data = table(cellstr(frontarea_score_type),frontarea_score(:,1) ,frontarea_score(:,2),frontarea_score(:,3),...
               frontarea_score(:,4) ,frontarea_score(:,5), 'VariableNames', header_names_en);
writetable(data, frontarea_csvfn)

frontline_csvfn = [result_path,'frontline_score_table.csv'];
delete(frontline_csvfn)
data = table(cellstr(frontline_score_type),frontline_score(:,1) ,frontline_score(:,2),frontline_score(:,3),...
               frontline_score(:,4) ,frontline_score(:,5), 'VariableNames', header_names_en);
writetable(data, frontline_csvfn)
