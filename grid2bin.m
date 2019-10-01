function [lon_bin, lat_bin, mask_bin, var_bin, mark_bin, mark_raw] = grid2bin(lon, lat, mask_raw, var_raw, bin_size)
%
%bin_size need to be odd
%
[nx,ny] = size(lon);
%mark every bin with number
mark_raw = zeros(nx,ny);

bin_loc = zeros(bin_size);

mid = (bin_size+1)/2; 
mid1 = mid -1;

lon_idx = mid:bin_size:nx;
lat_idx = mid:bin_size:ny;

lon_bin1D = lon(lon_idx,1);
lat_bin1D = lat(1,lat_idx);

nx_bin = length(lon_idx);
ny_bin = length(lat_idx);

%{
only when number of water pixel within N*N greater than half of total
pixels, consider new binned pixel as water pixel.
%}
mask_bin = zeros(nx_bin,ny_bin);
var_bin = zeros(nx_bin,ny_bin);
mark_bin = zeros(nx_bin,ny_bin);
bin_number = 0;
for ixb = 1:nx_bin
    for iyb = 1:ny_bin
        xx = lon_idx(ixb);
        yy = lat_idx(iyb);
        xx_ind = max(1,xx-mid1) : min(nx,xx+mid1);
        yy_ind = max(1,yy-mid1) : min(ny,yy+mid1);
        mask_local = mask_raw(xx_ind,yy_ind);
        if length(find(mask_local(:)==1)) > 0.5*bin_size^2
            mask_bin(ixb,iyb) = 1;
            var_local = var_raw(xx_ind,yy_ind);
            var_bin(ixb,iyb) = nanmean(var_local(:));
            % Every bin was given a bin number,  mark N*N bin with value bin_number
            bin_number = bin_number + 1;
            mark_bin(ixb,iyb) = bin_number;
            mark_raw(xx_ind,yy_ind) = bin_number;
        end
        clear xx yy xx_ind yy_ind mask_local var_local
    end
end

[lat_bin ,lon_bin] = meshgrid(lat_bin1D, lon_bin1D);


end