function [lon_bin, lat_bin, mask_bin, mask_cell,var_bin] = grid_to_bin(lon,lat,mask,bin_resolution,lon_w,lon_e,lat_s,lat_n,var_grid);
%
%
effect_mask_ratio = 0.5; % ratio to determine valid mask_bin
mid = 0.5*bin_resolution;
% build grid between the raw grid
ln = ceil(lon_w):bin_resolution:floor(lon_e);
lt = ceil(lat_s):bin_resolution:floor(lat_n);
ln_mid = ceil(lon_w)+mid:bin_resolution:floor(lon_e)-mid;
lt_mid = ceil(lat_s)+mid:bin_resolution:floor(lat_n)-mid;
[lat_bin, lon_bin] = meshgrid(lt_mid,ln_mid);
%
nx_bin = length(ln_mid);
ny_bin = length(lt_mid);

% using cell struct to mark all global index for every bin
mask_cell = cell(nx_bin,ny_bin);
for ixb = 1:nx_bin
    for iyb = 1:ny_bin
        brdyN = lt(iyb+1);
        brdyS = lt(iyb);
        brdyW = ln(ixb);
        brdyE = ln(ixb+1);
        xx = find(lon(:,1)>=brdyW & lon(:,1)<brdyE);
        yy = find(lat(1,:)>=brdyS & lat(1,:)<brdyN);
        mask_local  = mask(xx,yy);
        nonan_num = length(find(mask_local(:)==1));
        mask_cell{ixb,iyb}.xx = xx;
        mask_cell{ixb,iyb}.yy = yy;
        mask_cell{ixb,iyb}.nonan_num = nonan_num;
        clear brdyN brdyS brdyW brdyE
        clear xx yy
    end
end
% mask and variable for binned grid
mask_bin = zeros(nx_bin,ny_bin);
var_bin = zeros(nx_bin,ny_bin);
for ixb = 1:nx_bin
    for iyb = 1:ny_bin
        
        mask_tmp = mask_cell{ixb,iyb};
        xx_ind = mask_tmp.xx;
        yy_ind = mask_tmp.yy;
        mask_local  = mask(xx_ind,yy_ind);
        [nx_loc,ny_loc] = size(mask_local);
        
        if length(find(mask_local(:)==1)) > effect_mask_ratio*nx_loc*ny_loc
            mask_bin(ixb,iyb) = 1;
            if nargin == 9
                var_local = var_grid(xx_ind,yy_ind);
                var_bin(ixb,iyb) = nanmean(var_local(:));
            else
                var_grid = [];
                var_bin = [];
            end
        end
        
    end
end


end